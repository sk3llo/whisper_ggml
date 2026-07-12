<div align="center">

# Whisper GGML

_On-device speech-to-text for Flutter, powered by [whisper.cpp](https://github.com/ggml-org/whisper.cpp) v1.9.1._

<p align="center">
  <a href="https://pub.dev/packages/whisper_ggml">
     <img src="https://img.shields.io/badge/pub-2.1.0-blue?logo=dart" alt="pub">
  </a>
  <a href="https://github.com/ggml-org/whisper.cpp">
     <img src="https://img.shields.io/badge/whisper.cpp-v1.9.1-green" alt="whisper.cpp">
  </a>
  <a href="https://buymeacoffee.com/sk3llo" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="21" width="114"></a>
</p>

Transcribe audio files or **transcribe live while the user speaks** — fully
on-device, no server, no API keys.

</div>

## Highlights

- 🎙 **Live transcription** — partial transcripts stream in while recording,
  refined as more audio arrives. The model loads once per session and an
  adaptive energy gate keeps silence from producing hallucinated text.
- 📄 **File transcription** — one call to transcribe a recording.
- 📦 **Offline-first** — models download once and are cached, or ship them
  in your app's assets for fully offline use (see the example app).
- 🌍 **99 languages** — pick one (`'en'`, `'fr'`, `'de'`, …) or use
  `'auto'` to detect.
- 🎛 **Decoding controls** — vocabulary biasing, context conditioning, and
  non-speech token suppression exposed from whisper.cpp.
- ⚡ **Fast** — whisper.cpp v1.9.1 with Accelerate on Apple platforms;
  an 11-second clip transcribes in ~0.4 s with the `base` model on an
  Apple Silicon Mac.

## Supported platforms

| Platform | Minimum version |
|----------|-----------------|
| Android  | API 21          |
| iOS      | 15.6            |
| macOS    | 10.15           |
| Windows  | 10 (x64)        |

## Installation

```yaml
dependencies:
  whisper_ggml: ^2.1.0
```

## Quick start

```dart
import 'package:whisper_ggml/whisper_ggml.dart';

final controller = WhisperController();

final result = await controller.transcribe(
  model: WhisperModel.tiny,
  audioPath: '/path/to/audio.wav',
  lang: 'en',
);

print(result?.transcription.text);
```

The model is downloaded automatically on first use. Non-WAV input is
converted with the bundled FFmpeg — except on Windows, where FFmpeg is not
bundled: an `ffmpeg` executable on `PATH` is used when present, otherwise
the input must already be a 16 kHz mono WAV (the format the `record`
package produces with `AudioEncoder.wav`, `sampleRate: 16000`,
`numChannels: 1`).

## Live (streaming) transcription

`transcribeLive` accepts any stream of **16 kHz mono little-endian PCM16**
audio and emits progressively refined transcripts while the audio flows.
With the [`record`](https://pub.dev/packages/record) package:

```dart
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
  print(text); // full transcript so far, not a delta
});

// Later — stop recording, finalize, and free the model:
await recorder.stop();
final finalText = await session.stop();
```

Good to know:

- The model stays loaded for the whole session; inference runs on a
  background isolate and never blocks the UI.
- An **adaptive energy gate** keeps silence away from the decoder, which
  otherwise hallucinates on silent audio. For unusually loud rooms or quiet
  speakers, tune `gateNoiseFloorCap`, `gateVoiceRatio`, and `gateRmsMin`.
- Only one live session can run at a time.
- Real non-speech sounds (knocks, clicks) may transcribe as bracketed
  annotations like `[door slams]`.

## Models

| Model | Multilingual | English-only |
|-------|--------------|--------------|
| tiny   | `WhisperModel.tiny`   | `WhisperModel.tinyEn`   |
| base   | `WhisperModel.base`   | `WhisperModel.baseEn`   |
| small  | `WhisperModel.small`  | `WhisperModel.smallEn`  |
| medium | `WhisperModel.medium` | `WhisperModel.mediumEn` |
| large-v3 | `WhisperModel.large` | —                      |

Smaller models are faster; larger models are more accurate. `tiny` and
`base` are good defaults for live transcription; `small` is a strong
accuracy/speed balance for file transcription on modern phones.

## Decoding options

Available on both `transcribe` and `transcribeLive`:

| Option | Default | What it does |
|--------|---------|--------------|
| `initialPrompt` | `null` | Biases decoding toward the vocabulary, names, and punctuation it contains — useful for domain-specific terms that otherwise get misrecognised. Decoding also mimics the prompt's *style*: an unpunctuated prompt tends to produce unpunctuated output. |
| `noContext` | `false` | Stops whisper from conditioning on prior-segment transcripts (like Python whisper's `condition_on_previous_text=False`). Helps against hallucinated repetition on short, independent utterances. |
| `suppressNonSpeechTokens` | `false` | Suppresses bracketed annotations such as `[BLANK_AUDIO]` or `[music]`. Side effect: real sounds may decode as plausible-looking words instead, which is why the example keeps it off. |

## Performance notes

- The native engine is compiled with `-O3` on all platforms, including
  debug builds on iOS/macOS and Windows (`/O2`) — transcription speed there
  is close to release.
- Windows builds target **AVX2** by default, like upstream whisper.cpp's
  standard x64 binaries (supported by virtually every x64 CPU since ~2013).
  For very old CPUs, build with `-DWHISPER_GGML_AVX2=OFF`.
- Android debug builds run the Dart layer in JIT mode; use `--release` for
  representative performance.
- The bundled whisper.cpp v1.9.1 is roughly **15× faster** than the engine
  in versions before 2.0.0.
