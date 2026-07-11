## 1.9.1

* Fixed a native crash (SIGABRT) when whisper emits text containing invalid UTF-8 — e.g. a token boundary splitting a multi-byte character, common with non-English audio. Invalid bytes are now replaced with U+FFFD instead of aborting the app ([#21](https://github.com/sk3llo/whisper_ggml/issues/21))

## 1.9.0

* Added live (streaming) transcription: `WhisperController.transcribeLive` takes a stream of 16 kHz mono PCM16 audio and returns a `WhisperLiveSession` that emits progressively refined partial transcripts while the user speaks; `stop()` returns the final text
* Live sessions load the model once and keep it in memory (new native `stream_start` / `stream_feed` / `stream_stop` API on Android, iOS, and macOS); inference runs on a dedicated isolate and never blocks the UI
* Adaptive energy gate keeps silence — digital or room tone — away from the decoder, preventing `[BLANK_AUDIO]` markers and hallucinated repetition; tunable per session via `gateRmsMin`, `gateVoiceRatio`, and `gateNoiseFloorCap`
* Added `suppressNonSpeechTokens` parameter (`whisper_full_params.suppress_non_speech_tokens`) to `TranscribeRequest`, `transcribe`, and `transcribeLive`
* Fixed a native memory leak: FFI response buffers were never freed — one small leak per one-shot transcription, unbounded growth for streaming
* Example app: redesigned UI with dedicated Live and Record microphone buttons and a JFK sample button; live transcripts update on screen while speaking
* Fixed macOS example: added the missing microphone entitlement

## 1.8.0

* Added `initialPrompt` parameter to `TranscribeRequest` and `WhisperController.transcribe`
* Wired `initial_prompt` through to `whisper_full_params.initial_prompt` on Android, iOS, and macOS to bias decoding toward domain-specific vocabulary, names, and punctuation
* Added `noContext` parameter (`whisper_full_params.no_context`, equivalent to Python whisper's `condition_on_previous_text=False`) on Android, iOS, and macOS to disable cross-segment text conditioning — helps against hallucinated repetition on short utterances
* Empty / null prompt and `noContext: false` leave whisper.cpp defaults, so existing callers see no behaviour change
* Removed unused `flutter_riverpod` dependency, which was constraining consumers to riverpod 2.x even though the package never imported it
* Fixed example app crash on macOS when transcribing the bundled jfk.wav (temporary directory did not exist)

## 1.7.0

* Connected `diarize` transcribe parameter to the underlying whisper C++ code
* Added `diarize` parameter to the `transcribe` method

## 1.6.0

* Fixed iOS issues
* Added `auto` language support for iOS
* Fixed `example` project
* Increased NDK version in order to support Google 16 KB requirement

## 1.5.0

* Switched main FFmpeg from **heavy** `ffmpeg_kit_flutter_new: ^1.6.1` to **lightweight** `ffmpeg_kit_flutter_new_min: ^2.1.0`
* Upgraded `recorder` dependency for `example` project from `v5.2.1` to `v6.0.0`
* Updated main code files

## 1.4.0

* Added ability to use "auto" [language detection](https://github.com/ggml-org/whisper.cpp/blob/b175baa665bc35f97a2ca774174f07dfffb84e19/examples/cli/README.md?plain=1#L51)
* Upgraded `pubspec.yaml` dependencies

## 1.3.0

* Upgraded Android bindings to work with Flutter 3.29
* Added new FFmpeg kit dependency

## 1.2.0

* Fixed Android v1 embedding issue by adding override for ffmpeg_kit_flutter_full_gpl 
* Upgraded dependencies 

## 1.1.1

* Cleaned up code

## 1.1.0

* Added support for MacOS

## 1.0.0

* Added support for Android and iOS

