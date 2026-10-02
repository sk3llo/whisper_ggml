<div align="center">

# Whisper GGML

_On-device speech-to-text for Flutter, powered by [whisper.cpp](https://github.com/ggml-org/whisper.cpp) v1.9.1._

<p align="center">
  <a href="https://pub.dev/packages/whisper_ggml">
     <img src="https://img.shields.io/pub/v/whisper_ggml?logo=dart&color=blue" alt="pub">
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
| Android  | API 24          |
| iOS      | 15.6            |
| macOS    | 10.15           |
| Windows  | 10 (x64)        |
| Linux    | x64             |

## Installation

```yaml
dependencies:
  whisper_ggml: ^2.7.0
```

Requires Dart 3.7+ (Flutter 3.29+).

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

Pass `onProgress: (percent) => ...` to receive transcription progress
as a 0–100 percentage (coarse steps) while inference runs.

Pass `withSegments: true` to also get per-segment timestamps in
`result.transcription.segments` (each segment has `fromTs`/`toTs`
`Duration`s and its `text`); add `splitOnWord: true` for one segment
per word instead of per phrase.

### Speaker-turn detection (diarization)

With the tinydiarize model (`WhisperModel.smallEnTdrz`, English only),
`diarize: true` marks the segments after which the speaker changes:

```dart
final result = await controller.transcribe(
  model: WhisperModel.smallEnTdrz,
  audioPath: '/path/to/audio.wav',
  lang: 'en',
  diarize: true,
  withSegments: true,
);

for (final segment in result?.transcription.segments ?? []) {
  print('${segment.text}${segment.speakerTurnNext ? ' [speaker turn]' : ''}');
}
```

This detects turn boundaries; it does not label or count speakers. With
regular models `diarize` has no effect.

The model is downloaded automatically on first use. Non-WAV input is
converted with the bundled FFmpeg — except on Windows and Linux, where
FFmpeg is not bundled: an `ffmpeg` executable on `PATH` is used when
present (on Linux, `apt install ffmpeg` or equivalent), otherwise the
input must already be a 16 kHz mono WAV (the format the `record` package
produces with `AudioEncoder.wav`, `sampleRate: 16000`, `numChannels: 1`).

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
- **Bring your own model:** pass `modelPath:` instead of `model:` to run
  the session against any local ggml model file. For full manual control,
  `startWhisperLiveSession(modelPath: ...)` is exported too — no audio
  stream wiring, you call `session.feed(pcm16Bytes)` yourself.
- **Session-per-utterance?** Pass `keepModelLoaded: true` and the model is
  parked in native memory when the session stops, so the next session (or
  one-shot `transcribe`) with the same model starts without the
  multi-second load. See "Keeping the model loaded between transcriptions"
  below — the same cache, memory trade-off, and `releaseModel()` apply.

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

## Trimming silence with voice-activity detection (VAD)

Push-to-talk and hold-to-record clips carry silence at the head and tail,
and whisper tends to hallucinate over it or repeat the previous sentence.
`transcribe` can run whisper.cpp's built-in [Silero VAD](https://github.com/snakers4/silero-vad)
first, so only the detected speech is decoded. Download a Silero ggml model
(~1 MB, e.g. `ggml-silero-v5.1.2.bin` from
[ggml-org/whisper-vad](https://huggingface.co/ggml-org/whisper-vad)), ship
or download it like the whisper model, and pass its path:

```dart
final result = await controller.transcribe(
  model: WhisperModel.base,
  audioPath: audioPath,
  vadModelPath: '/path/to/ggml-silero-v5.1.2.bin',
  vadSpeechPadMs: 100, // optional; keeps clipped first/last words intact
);
```

Good to know:

- VAD is off unless `vadModelPath` is set. Segment timestamps still refer
  to the original recording.
- Audio with no detected speech returns an empty transcript.
- A `vadModelPath` that cannot be opened fails the request with an error.
- `vadSpeechPadMs` overrides the padding around each speech segment;
  around 100 ms works well for dictation, much larger values can garble
  segment boundaries.
- Applies to `transcribe` only; live sessions have their own energy gate.
- With `keepModelLoaded`, keep the VAD setting the same across requests: a
  parked model that ran VAD is only reused by requests with the same VAD
  model, anything else loads the model fresh.

## Keeping the model loaded between transcriptions

By default every `transcribe` call loads the model from disk (seconds for
the small models and up) and frees it when the request completes. For
push-to-talk dictation, voice notes, and other short repeated requests
against the same model, that load dominates the per-utterance latency.
Pass `keepModelLoaded: true` to park the loaded model in native memory
instead — the next transcription with the same model skips the load:

```dart
final result = await controller.transcribe(
  model: WhisperModel.base,
  audioPath: audioPath,
  keepModelLoaded: true, // model stays resident for the next request
);

// When dictation is over, free the parked model:
await controller.releaseModel();
```

Good to know:

- A reused model transcribes **exactly like a freshly loaded one** — no
  text or decoder state carries over between requests.
- The parked model keeps its weights in RAM (from ~100 MB for `tiny` up to
  several GB for the large models) until you release it. On phones,
  release it when dictation ends rather than keeping it forever.
- One model stays resident per process; parking a different model
  replaces and frees the previous one. A request for a *different* model
  with `keepModelLoaded: false` leaves the parked one alone.
- Requests stay fully concurrent: a second transcription that arrives
  while the parked model is in use simply loads its own copy, exactly as
  before.

- The native engine is compiled with `-O3` on all platforms, including
  debug builds on iOS/macOS, Windows (`/O2`), and Linux — transcription
  speed there is close to release.
- Windows and Linux x64 builds target **AVX2** by default, like upstream
  whisper.cpp's standard x64 binaries (supported by virtually every x64 CPU
  since ~2013). For very old CPUs, build with `-DWHISPER_GGML_AVX2=OFF`.
- Android debug builds run the Dart layer in JIT mode; use `--release` for
  representative performance.
- The bundled whisper.cpp v1.9.1 is roughly **15× faster** than the engine
  in versions before 2.0.0.
