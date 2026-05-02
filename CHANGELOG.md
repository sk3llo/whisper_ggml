## Unreleased

* Added `initialPrompt` parameter to `TranscribeRequest` and `WhisperController.transcribe`
* Wired `initial_prompt` through to `whisper_full_params.initial_prompt` on Android, iOS, and macOS to bias decoding toward domain-specific vocabulary, names, and punctuation
* Empty / null prompt leaves the parameter at whisper.cpp's default (`nullptr`), so existing callers see no behaviour change

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

