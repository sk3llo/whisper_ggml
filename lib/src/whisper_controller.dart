import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:whisper_ggml/src/models/whisper_model.dart';

import 'models/whisper_result.dart';
import 'whisper.dart';
import 'whisper_live.dart';

class WhisperController {
  String _modelPath = '';
  String? _dir;

  Future<void> initModel(WhisperModel model) async {
    _dir ??= await getModelDir();
    _modelPath = '$_dir/ggml-${model.modelName}.bin';
  }

  /// Start a live transcription session.
  ///
  /// [pcm16Stream] must produce 16 kHz mono little-endian PCM16 audio (e.g.
  /// the `record` package's `startStream` with
  /// `RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000,
  /// numChannels: 1)`). Partial transcripts are emitted on
  /// [WhisperLiveSession.partials] while audio flows; when [pcm16Stream]
  /// closes (or [WhisperLiveSession.stop] is called) the session finalizes
  /// and `stop()` returns the full transcript.
  ///
  /// Unlike [transcribe], the model is loaded once for the whole session.
  /// The `gate*` parameters tune the native energy gate that keeps silence
  /// away from the decoder: a chunk counts as voiced when its RMS exceeds
  /// `max(gateVoiceRatio * noiseFloor, gateRmsMin)`, where the adaptive
  /// noise floor is capped at [gateNoiseFloorCap]. Raise the cap for loud
  /// environments; lower [gateRmsMin] for very quiet speakers.
  Future<WhisperLiveSession> transcribeLive({
    required WhisperModel model,
    required Stream<Uint8List> pcm16Stream,
    String lang = 'en',
    String? initialPrompt,
    bool suppressNonSpeechTokens = false,
    double gateRmsMin = 0.0015,
    double gateVoiceRatio = 2.5,
    double gateNoiseFloorCap = 0.01,
  }) async {
    await initModel(model);

    final WhisperLiveSession session = await startWhisperLiveSession(
      modelPath: _modelPath,
      lang: lang,
      initialPrompt: initialPrompt,
      suppressNonSpeechTokens: suppressNonSpeechTokens,
      gateRmsMin: gateRmsMin,
      gateVoiceRatio: gateVoiceRatio,
      gateNoiseFloorCap: gateNoiseFloorCap,
    );

    pcm16Stream.listen(
      session.feed,
      onDone: session.stop,
      onError: (Object e) {
        debugPrint('transcribeLive: audio stream error: $e');
        session.stop();
      },
    );

    return session;
  }

  /// Transcribe [audioPath] with [model].
  ///
  /// When [withSegments] is `true`, the result's
  /// [WhisperTranscribeResponse.segments] carries per-segment timestamps
  /// (`fromTs`/`toTs`) alongside the text; combine with [splitOnWord] to
  /// get one segment per word instead of per phrase.
  Future<TranscribeResult?> transcribe({
    required WhisperModel model,
    required String audioPath,
    String lang = 'en',
    bool diarize = false,
    String? initialPrompt,
    bool noContext = false,
    bool suppressNonSpeechTokens = false,
    bool withSegments = false,
    bool splitOnWord = false,
  }) async {
    await initModel(model);

    final Whisper whisper = Whisper(model: model);
    final DateTime start = DateTime.now();
    const bool translate = false;

    try {
      final WhisperTranscribeResponse transcription = await whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: lang,
          isTranslate: translate,
          isNoTimestamps: !withSegments,
          splitOnWord: splitOnWord,
          isRealtime: true,
          diarize: diarize,
          initialPrompt: initialPrompt,
          noContext: noContext,
          suppressNonSpeechTokens: suppressNonSpeechTokens,
        ),
        modelPath: _modelPath,
      );

      final Duration transcriptionDuration = DateTime.now().difference(start);

      return TranscribeResult(
        time: transcriptionDuration,
        transcription: transcription,
      );
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  static Future<String> getModelDir() async {
    if (!Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.isMacOS &&
        !Platform.isWindows &&
        !Platform.isLinux) {
      throw UnsupportedError(
        'whisper_ggml supports Android, iOS, macOS, Windows, and Linux. '
        '${Platform.operatingSystem} has no native whisper implementation.',
      );
    }
    // getLibraryDirectory only exists on Apple platforms.
    final Directory libraryDirectory = Platform.isIOS || Platform.isMacOS
        ? await getLibraryDirectory()
        : await getApplicationSupportDirectory();
    return libraryDirectory.path;
  }

  /// Get local path of model file
  Future<String> getPath(WhisperModel model) async {
    _dir ??= await getModelDir();
    return '$_dir/ggml-${model.modelName}.bin';
  }

  /// Download [model] to [destinationPath]
  Future<String> downloadModel(WhisperModel model) async {
    if (!File(await getPath(model)).existsSync()) {
      final request = await HttpClient().getUrl(model.modelUri);

      final response = await request.close();

      final bytes = await consolidateHttpClientResponseBytes(response);

      final File file = File(await getPath(model));
      await file.writeAsBytes(bytes);

      return file.path;
    } else {
      return await getPath(model);
    }
  }
}
