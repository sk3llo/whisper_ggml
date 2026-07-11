import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:universal_io/io.dart';

/// Native streaming bindings.
typedef _StreamStartNative = Pointer<Utf8> Function(Pointer<Utf8> body);
typedef _StreamFeedNative = Pointer<Utf8> Function(
    Pointer<Float> pcm, Int32 nSamples);
typedef _StreamFeedDart = Pointer<Utf8> Function(Pointer<Float> pcm, int n);
typedef _StreamStopNative = Pointer<Utf8> Function();

/// A running live transcription session.
///
/// Obtain one from `WhisperController.transcribeLive`. Listen to [partials]
/// for progressively refined transcripts while audio is being fed, and call
/// [stop] to get the final text and release the native context.
class WhisperLiveSession {
  WhisperLiveSession._(this._worker, this._toWorker, this._partials);

  final Isolate _worker;
  final SendPort _toWorker;
  final StreamController<String> _partials;
  final Completer<String> _final = Completer<String>();
  bool _stopped = false;

  /// Progressively refined transcripts of the audio fed so far. Each event
  /// replaces the previous one (it is the full text, not a delta).
  Stream<String> get partials => _partials.stream;

  /// Feed 16 kHz mono PCM16 (little-endian) audio bytes.
  void feed(Uint8List pcm16Bytes) {
    if (_stopped) return;
    _toWorker.send(['feed', pcm16Bytes]);
  }

  /// Finish the session: transcribe any remaining audio, release the native
  /// context, and return the final transcript.
  Future<String> stop() {
    if (!_stopped) {
      _stopped = true;
      _toWorker.send(const ['stop']);
    }
    return _final.future;
  }
}

/// Spawns the worker isolate and starts a native stream. Internal API used by
/// `WhisperController.transcribeLive`.
Future<WhisperLiveSession> startWhisperLiveSession({
  required String modelPath,
  String lang = 'en',
  bool translate = false,
  String? initialPrompt,
  bool suppressNonSpeechTokens = false,
  int threads = 4,
  double gateRmsMin = 0.0015,
  double gateVoiceRatio = 2.5,
  double gateNoiseFloorCap = 0.01,
}) async {
  final ReceivePort fromWorker = ReceivePort();
  final Isolate worker =
      await Isolate.spawn(_liveWorker, fromWorker.sendPort);

  final StreamController<String> partials = StreamController<String>();
  final Completer<SendPort> ready = Completer<SendPort>();
  final Completer<void> started = Completer<void>();
  late final WhisperLiveSession session;

  String lastText = '';

  fromWorker.listen((dynamic message) {
    final List<dynamic> msg = message as List<dynamic>;
    switch (msg[0] as String) {
      case 'ready':
        ready.complete(msg[1] as SendPort);
      case 'started':
        started.complete();
      case 'partial':
        lastText = msg[1] as String;
        if (!partials.isClosed) partials.add(lastText);
      case 'final':
        if (!partials.isClosed) partials.close();
        session._final.complete(msg[1] as String);
        fromWorker.close();
        session._worker.kill();
      case 'error':
        final error = Exception(msg[1] as String);
        if (!started.isCompleted) {
          started.completeError(error);
        } else if (!session._final.isCompleted) {
          // A mid-session native error is fatal: surface it on [partials],
          // then finalize with the last known text so stop() never hangs.
          if (!partials.isClosed) {
            partials
              ..addError(error)
              ..close();
          }
          session._final.complete(lastText);
          fromWorker.close();
          session._worker.kill();
        }
    }
  });

  final SendPort toWorker = await ready.future;
  session = WhisperLiveSession._(worker, toWorker, partials);

  toWorker.send([
    'start',
    json.encode({
      'model': modelPath,
      'language': lang,
      'is_translate': translate,
      'threads': threads,
      'suppress_non_speech_tokens': suppressNonSpeechTokens,
      'gate_rms_min': gateRmsMin,
      'gate_voice_ratio': gateVoiceRatio,
      'gate_floor_cap': gateNoiseFloorCap,
      if (initialPrompt != null && initialPrompt.isNotEmpty)
        'initial_prompt': initialPrompt,
    }),
  ]);

  try {
    await started.future;
  } catch (_) {
    worker.kill(priority: Isolate.immediate);
    fromWorker.close();
    await partials.close();
    rethrow;
  }
  return session;
}

/// Worker isolate: owns all FFI calls so whisper_full never blocks the UI
/// isolate. Messages arriving while inference runs simply queue in the
/// mailbox; the native side only re-runs inference once enough new audio
/// has accumulated, so queued chunks drain quickly.
///
/// Note: backpressure is bounded only by decode speed. On devices where the
/// model decodes slower than real time, the mailbox and the native window
/// grow and partial latency drifts behind the audio. If that becomes a
/// target, cap the window or surface an "audio seconds behind" metric.
void _liveWorker(SendPort toMain) {
  final DynamicLibrary lib = Platform.isAndroid
      ? DynamicLibrary.open('libwhisper.so')
      : DynamicLibrary.process();

  final start =
      lib.lookupFunction<_StreamStartNative, _StreamStartNative>('stream_start');
  final feed = lib.lookupFunction<_StreamFeedNative, _StreamFeedDart>('stream_feed');
  final stopFn =
      lib.lookupFunction<_StreamStopNative, _StreamStopNative>('stream_stop');

  final ReceivePort inbox = ReceivePort();
  toMain.send(['ready', inbox.sendPort]);

  String lastPartial = '';
  int pendingByte = -1; // odd trailing byte carried into the next chunk

  Map<String, dynamic> parse(Pointer<Utf8> res) {
    final Map<String, dynamic> result =
        json.decode(res.toDartString()) as Map<String, dynamic>;
    // The native side allocates responses with malloc for exactly this free.
    malloc.free(res);
    return result;
  }

  inbox.listen((dynamic message) {
    final List<dynamic> msg = message as List<dynamic>;
    switch (msg[0] as String) {
      case 'start':
        final Pointer<Utf8> body = (msg[1] as String).toNativeUtf8();
        final Map<String, dynamic> result = parse(start(body));
        malloc.free(body);
        if (result['@type'] == 'error') {
          toMain.send(['error', result['message']]);
        } else {
          toMain.send(const ['started']);
        }
      case 'feed':
        Uint8List bytes = msg[1] as Uint8List;
        // Normalize the chunk: asInt16List needs an even byte offset, and an
        // odd-length chunk would shift every following sample by one byte
        // (silent corruption), so the trailing byte is carried into the next
        // chunk instead.
        if (pendingByte >= 0 ||
            bytes.offsetInBytes.isOdd ||
            bytes.length.isOdd) {
          final Uint8List merged =
              Uint8List(bytes.length + (pendingByte >= 0 ? 1 : 0));
          int offset = 0;
          if (pendingByte >= 0) merged[offset++] = pendingByte;
          merged.setRange(offset, offset + bytes.length, bytes);
          if (merged.length.isOdd) {
            pendingByte = merged.last;
            bytes = Uint8List.sublistView(merged, 0, merged.length - 1);
          } else {
            pendingByte = -1;
            bytes = merged;
          }
        }
        if (bytes.isEmpty) return;
        final Int16List samples =
            bytes.buffer.asInt16List(bytes.offsetInBytes, bytes.length ~/ 2);
        final Pointer<Float> pcm = malloc.allocate<Float>(
          samples.length * sizeOf<Float>(),
        );
        final Float32List dest = pcm.asTypedList(samples.length);
        for (int i = 0; i < samples.length; i++) {
          dest[i] = samples[i] / 32768.0;
        }
        final Map<String, dynamic> result = parse(feed(pcm, samples.length));
        malloc.free(pcm);
        if (result['@type'] == 'error') {
          toMain.send(['error', result['message']]);
        } else {
          final String text = result['text'] as String? ?? '';
          if (text != lastPartial) {
            lastPartial = text;
            toMain.send(['partial', text]);
          }
        }
      case 'stop':
        final Map<String, dynamic> result = parse(stopFn());
        toMain.send([
          'final',
          result['@type'] == 'error' ? lastPartial : result['text'] as String,
        ]);
        inbox.close();
    }
  });
}
