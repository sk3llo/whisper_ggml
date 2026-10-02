## Unreleased

* Opt-in Silero voice-activity detection for `transcribe` ([#29](https://github.com/sk3llo/whisper_ggml/issues/29)): pass `vadModelPath` (controller and low-level API) to run whisper.cpp's built-in VAD before decoding, so only detected speech is transcribed — the standard defence against whisper hallucinating or looping over the leading/trailing silence of push-to-talk recordings. `vadSpeechPadMs` optionally overrides the padding kept around speech. Off by default; implemented in all three native shims. Contributed by @Ranjan-Bhagat
* Segment timestamps keep referring to the original recording; speech-free audio returns an empty transcript; a VAD model path that cannot be opened fails the request with `failed to open VAD model …` instead of a generic error
* Composes with `keepModelLoaded`: whisper.cpp keeps VAD state on the model context and only resets it when VAD runs again, so a parked model that has run VAD is only reused by requests with the same VAD model. Without that guard, a non-VAD request on such a context got its timestamps remapped through the previous request's speech map, and a request with a different VAD model silently used the first one
* Fixed `keepModelLoaded` / `releaseModel` being silently ignored on **macOS**: the 2.6.0 resident-model support never reached the macOS shim, so macOS callers still reloaded the model on every request and live sessions never borrowed a parked model. The macOS shim now matches the iOS one
* Verified on host builds of all three native shims (21 scenarios each: VAD, resident model, live sessions borrowing a VAD-used model, concurrent requests) with zero leaked bytes under `leaks --atExit`, plus an end-to-end run of the macOS example app through the public Dart API

## 2.6.0

* Opt-in resident model between transcriptions ([#26](https://github.com/sk3llo/whisper_ggml/issues/26)): pass `keepModelLoaded: true` to `transcribe` (controller and low-level API) and the loaded `whisper_context` is parked in the native layer instead of freed, so the next request with the same model file skips the multi-second load — the difference between usable and not for push-to-talk dictation. Free it with the new `releaseModel()` (controller and `Whisper`), or by transcribing once more with the flag off. Implemented on all five platforms (the Android/Windows/Linux shim and the iOS/macOS shim)
* Warm requests are guaranteed independent: a reused context force-clears whisper's rolling text history (`no_context`) before decoding, so a warm transcription is byte-identical to a cold one and one request's output can never condition (or leak a hallucination into) the next. `initialPrompt` still applies per request
* The cache uses checkout semantics — the parked context is *taken* while in use and parked again afterwards — so the lock is never held during a decode and concurrent transcriptions keep running in parallel, each on its own context, exactly as before. Error paths (bad WAV, failed inference) park the model too: a bad recording doesn't cost the next request a reload
* Live sessions join the same scheme: `transcribeLive` / `startWhisperLiveSession` accept `keepModelLoaded`, which parks the session's model on `stop()` so session-per-utterance callers skip the per-session load too. A session also *borrows* an already-parked model automatically when the path matches — and always returns it on stop, so a one-shot caller that parked a model never silently loses it to a live session. Cross-session independence needs nothing extra: every stream decode already runs with `no_context`
* Verified on a host build of the native layer: warm requests skip the load with byte-identical output, the parked model survives failed requests, `releaseModel` frees it (and is a safe no-op when nothing is parked), and 3 rounds of concurrent transcriptions pass `leaks --atExit` with zero leaked bytes

## 2.5.0

* Live transcription now works with locally provided model files ([#25](https://github.com/sk3llo/whisper_ggml/issues/25)): `WhisperController.transcribeLive` accepts `modelPath` as an alternative to `model`, and `startWhisperLiveSession` is now part of the public API — it takes a `modelPath` and leaves audio delivery to the caller via `WhisperLiveSession.feed`
* Raised the declared SDK floor to what the package already required in practice: `sdk: '>=3.7.0 <4.0.0'` and `flutter: '>=3.29.0'`. Since 2.4.0, `ffi ^2.1.4` has needed Dart 3.7, but the stale `>=3.1.0` constraint made `pub get` fail with a version-solving error on older SDKs instead of a clear SDK-requirement message. Verified on the floor (Flutter 3.29.3 / Dart 3.7.2) and on current stable (3.44.8)

## 2.4.0

* Added transcription progress reporting ([#6](https://github.com/sk3llo/whisper_ggml/issues/6)): `transcribe` (controller and low-level API) takes an optional `onProgress` callback invoked with whisper.cpp's inference progress as a 0–100 percentage (coarse steps). Implemented via a `NativeCallable.listener` handed to `whisper_full_params.progress_callback`, so events arrive on the calling isolate without blocking inference

## 2.3.0

* `WhisperController.transcribe` now exposes `withSegments` and `splitOnWord` ([#14](https://github.com/sk3llo/whisper_ggml/issues/14)): pass `withSegments: true` to get per-segment timestamps in `result.transcription.segments` (`fromTs`/`toTs` as `Duration`), and add `splitOnWord: true` for one segment per word. Previously segments were only reachable through the low-level `Whisper.transcribe` API
* The `diarize` parameter now actually does something ([#13](https://github.com/sk3llo/whisper_ggml/issues/13)): it enables whisper.cpp's tinydiarize speaker-turn detection. Use the new `WhisperModel.smallEnTdrz` model (English only) together with `diarize: true` and `withSegments: true` — segments after which the speaker changes carry `speakerTurnNext == true`. With regular (non-tdrz) models the flag remains a no-op, as it silently was since 1.7.0

## 2.2.0

* Added **Linux support** (x64): the vendored whisper.cpp v1.9.1 builds into `libwhisper_ggml.so` through the standard Flutter Linux CMake toolchain — both one-shot (`transcribe`) and live (`transcribeLive`) transcription work
* Removed the stale prebuilt `libggml*.so` binaries from `linux/` — leftovers that never constituted a working implementation (no whisper code, wrong bundling variable) and only inflated the package
* Like Windows, Linux x64 targets AVX2 by default (`-DWHISPER_GGML_AVX2=OFF` for baseline SSE2) and uses an `ffmpeg` executable from `PATH` for non-WAV input
* Example app: added the Linux runner; the Record button captures 16 kHz WAV directly on Linux
* Fixed a native crash (SIGSEGV) on **all platforms** when the model file is missing or corrupt: `transcribe` called `whisper_full` with a null context instead of returning an error response (found by the new Linux test suite)
* Fixed a native memory leak on all platforms: error paths in `transcribe` (unreadable/wrong-format WAV, failed inference) returned without freeing the loaded model — ~150 MB leaked per failed call with the `base` model

## 2.1.0

* Added **Windows support** (x64): the vendored whisper.cpp v1.9.1 now also builds into `whisper_ggml.dll` through the standard Flutter Windows CMake toolchain — both one-shot (`transcribe`) and live (`transcribeLive`) transcription work
* Windows builds target AVX2 by default (matching upstream whisper.cpp's standard x64 binaries); pass `-DWHISPER_GGML_AVX2=OFF` to the plugin CMake for a baseline SSE2 build
* Audio conversion on Windows uses an `ffmpeg` executable from `PATH` when available (ffmpeg_kit has no Windows implementation); without it, input must already be 16 kHz mono WAV
* Native inference stays optimized (`/O2`) in Windows debug builds, matching the iOS/macOS behaviour
* Example app: added the Windows runner; the Record button captures 16 kHz WAV directly on Windows so no ffmpeg is needed

## 2.0.0

* Upgraded the vendored whisper.cpp from a 2023-era snapshot to **v1.9.1** — roughly **15× faster** transcription (an 11-second clip takes ~0.4 s with the `base` model on Apple Silicon), with Accelerate enabled on iOS/macOS
* The model-loading code that crashed on some physical iPhones was rewritten upstream ([#22](https://github.com/sk3llo/whisper_ggml/issues/22)); verified working on the iOS simulator
* Removed the `-march=armv8.2-a+fp16` Android compile flags that caused SIGILL crashes on armv8.0 devices ([#15](https://github.com/sk3llo/whisper_ggml/issues/15))
* Native code now compiles with `-O3` in debug builds on iOS/macOS, so development-time transcription is no longer unusably slow
* Rewrote the README
* Note: while the Dart API is unchanged, the native engine swap is significant — hence the major version bump

## 1.9.2

* Removed the `windows` and `linux` platform declarations — neither has a native whisper implementation, and pub.dev advertised support that failed at runtime. Unsupported platforms now throw a clear `UnsupportedError` ([#20](https://github.com/sk3llo/whisper_ggml/issues/20))
* Ship consumer ProGuard rules so Android release builds no longer strip the bundled ffmpeg-kit classes, which broke plugin registration and surfaced as `channel-error` on unrelated plugins like path_provider ([#16](https://github.com/sk3llo/whisper_ggml/issues/16))

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

