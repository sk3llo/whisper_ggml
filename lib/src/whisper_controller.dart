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
  Future<WhisperLiveSession> transcribeLive({
    required WhisperModel model,
    required Stream<Uint8List> pcm16Stream,
    String lang = 'en',
    String? initialPrompt,
  }) async {
    await initModel(model);

    final WhisperLiveSession session = await startWhisperLiveSession(
      modelPath: _modelPath,
      lang: lang,
      initialPrompt: initialPrompt,
    );

    pcm16Stream.listen(
      session.feed,
      onDone: session.stop,
      onError: (Object _) => session.stop(),
    );

    return session;
  }

  Future<TranscribeResult?> transcribe({
    required WhisperModel model,
    required String audioPath,
    String lang = 'en',
    bool diarize = false,
    String? initialPrompt,
    bool noContext = false,
  }) async {
    await initModel(model);

    final Whisper whisper = Whisper(model: model);
    final DateTime start = DateTime.now();
    const bool translate = false;
    const bool withSegments = false;
    const bool splitWords = false;

    try {
      final WhisperTranscribeResponse transcription = await whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: lang,
          isTranslate: translate,
          isNoTimestamps: !withSegments,
          splitOnWord: splitWords,
          isRealtime: true,
          diarize: diarize,
          initialPrompt: initialPrompt,
          noContext: noContext,
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
    final Directory libraryDirectory = Platform.isAndroid
        ? await getApplicationSupportDirectory()
        : await getLibraryDirectory();
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
