<div align="center">

# Whisper GGML

_OpenAI Whisper ASR (Automatic Speech Recognition) for Flutter using [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)._

<p align="center">
  <a href="https://pub.dev/packages/whisper_ggml">
     <img src="https://img.shields.io/badge/pub-1.9.2-blue?logo=dart" alt="pub">
  </a>
  <a href="https://buymeacoffee.com/sk3llo" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="21" width="114"></a>
</p>
</div>


## Supported platforms


| Platform  | Supported |
|-----------|-----------|
| Android   | ✅        |
| iOS       | ✅        |
| MacOS     | ✅        |


## Features



- Automatic Speech Recognition integration for Flutter apps.

- Supports automatic model downloading and initialization. Can be configured to work fully offline by using `assets` models (see example folder).

- Seamless iOS and Android support with optimized performance.

- Can be configured to use specific language ("en", "fr", "de", etc) or auto-detect ("auto").

- Utilizes [CORE ML](https://github.com/ggml-org/whisper.cpp/tree/master?tab=readme-ov-file#core-ml-support) for enhanced processing on iOS devices.



## Installation



To use this library in your Flutter project, follow these steps:



1. Add the library to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  whisper_ggml: ^1.9.2
```

2. Run `flutter pub get` to install the package.



## Usage



To integrate Whisper ASR in your Flutter app:



1. Import the package:

```dart
import 'package:whisper_ggml/whisper_ggml.dart';
```



2. Pick your model. Smaller models are more performant, but the accuracy may be lower. Recommended models are `tiny` and `small`.

```dart
final model = WhisperModel.tiny;
```

3. Declare `WhisperController` and use it for transcription:

```dart
final controller = WhisperController();

final result = await controller.transcribe(
    model: model, /// Selected WhisperModel
    audioPath: audioPath, /// Path to .wav file
    lang: 'en', /// Language to transcribe
    initialPrompt: 'Optional text to bias decoding', /// See note below
);
```

The optional `initialPrompt` is passed to whisper.cpp as
`whisper_full_params.initial_prompt`. Whisper uses it to bias decoding toward
the vocabulary, proper nouns, and punctuation it contains — useful for
domain-specific transcription (medical, legal, product names, etc.) where
those words otherwise get misrecognised. Leave it `null` (the default) to
disable biasing. Note that decoding also mimics the prompt's style, so an
unpunctuated prompt tends to produce unpunctuated output.

The optional `noContext` flag sets `whisper_full_params.no_context`
(equivalent to Python whisper's `condition_on_previous_text=False`). When
`true`, whisper.cpp does not feed prior-segment transcripts into the decoder
as context — useful for short, independent utterances where carry-over
context can cause hallucinated repetition. Defaults to `false`, matching
whisper.cpp's default.

4. Use the `result` variable to access the transcription result:

```dart
if (result?.transcription.text != null) {
    /// Do something with the transcription
    print(result!.transcription.text);
}
```

## Live (streaming) transcription

`transcribeLive` transcribes audio while it is being recorded: partial
transcripts arrive on a stream and refine as more audio comes in. The model
is loaded once for the whole session.

```dart
final controller = WhisperController();

/// Any stream of 16 kHz mono little-endian PCM16 audio works. With the
/// `record` package:
final pcmStream = await recorder.startStream(const RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 16000,
  numChannels: 1,
));

final session = await controller.transcribeLive(
  model: WhisperModel.base,
  pcm16Stream: pcmStream,
  lang: 'en',
);

session.partials.listen((text) {
  /// Each event is the full transcript so far, not a delta
  print(text);
});

/// Later — stops the recorder stream, finalizes, and frees the model:
await recorder.stop();
final finalText = await session.stop();
```

An adaptive energy gate keeps silence away from the decoder (whisper
hallucinates on silent audio). If your environment is unusually loud or your
speakers unusually quiet, tune it with `gateNoiseFloorCap`, `gateVoiceRatio`,
and `gateRmsMin` on `transcribeLive`. Only one live session can run at a
time. Real non-speech sounds (knocks, clicks) may still transcribe as
bracketed annotations like `[door slams]`.



## Notes



Transcription processing time is about `5x` times faster when running in release mode.