/// Available whisper models
enum WhisperModel {
  /// tiny model for all languages
  tiny('tiny'),

  /// base model for all languages
  base('base'),

  /// small model for all languages
  small('small'),

  /// medium model for all languages
  medium('medium'),

  /// large model for all languages
  large('large-v3'),

  /// tiny model for english only
  tinyEn('tiny.en'),

  /// base model for english only
  baseEn('base.en'),

  /// small model for english only
  smallEn('small.en'),

  /// medium model for english only
  mediumEn('medium.en'),

  /// small english-only model with tinydiarize speaker-turn detection;
  /// use together with `diarize: true` to get
  /// `WhisperTranscribeSegment.speakerTurnNext`
  smallEnTdrz('small.en-tdrz');

  const WhisperModel(this.modelName);

  /// Public name of model
  final String modelName;

  /// Huggingface url to download model
  Uri get modelUri {
    // tinydiarize models live in a different HF repo; same special case
    // as upstream whisper.cpp's download-ggml-model script.
    final String repo = modelName.contains('tdrz')
        ? 'akashmjn/tinydiarize-whisper.cpp'
        : 'ggerganov/whisper.cpp';
    return Uri.parse(
      'https://huggingface.co/$repo/resolve/main/ggml-$modelName.bin',
    );
  }
}
