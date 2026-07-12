// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whisper_ggml/src/models/requests/transcribe_request.dart';
import 'package:whisper_ggml/src/models/whisper_dto.dart';

part 'transcribe_request_dto.freezed.dart';
part 'transcribe_request_dto.g.dart';

/// Transcribe request sent to whisper.cpp
@freezed
abstract class TranscribeRequestDto
    with _$TranscribeRequestDto
    implements WhisperRequestDto {
  ///
  const factory TranscribeRequestDto({
    required String audio,
    required String model,
    @JsonKey(name: 'is_translate') required bool isTranslate,
    required int threads,
    @JsonKey(name: 'is_verbose') required bool isVerbose,
    required String language,
    @JsonKey(name: 'is_special_tokens') required bool isSpecialTokens,
    @JsonKey(name: 'is_no_timestamps') required bool isNoTimestamps,
    @JsonKey(name: 'n_processors') required int nProcessors,
    @JsonKey(name: 'split_on_word') required bool splitOnWord,
    @JsonKey(name: 'no_fallback') required bool noFallback,
    @JsonKey(name: 'is_realtime') required bool isRealtime,
    required bool diarize,
    @JsonKey(name: 'speed_up') required bool speedUp,
    @JsonKey(name: 'initial_prompt') String? initialPrompt,
    @JsonKey(name: 'no_context') @Default(false) bool noContext,
    @JsonKey(name: 'suppress_non_speech_tokens')
    @Default(false)
    bool suppressNonSpeechTokens,

    /// Address of a `NativeCallable<Void Function(Int32)>` the native layer
    /// invokes with transcription progress (0–100); null disables it.
    @JsonKey(name: 'progress_callback') int? progressCallback,
  }) = _TranscribeRequestDto;

  /// Convert [request] to TranscribeRequestDto with specified [modelPath]
  factory TranscribeRequestDto.fromTranscribeRequest(
    TranscribeRequest request,
    String modelPath, {
    int? progressCallbackAddress,
  }) {
    return TranscribeRequestDto(
      audio: request.audio,
      model: modelPath,
      isTranslate: request.isTranslate,
      threads: request.threads,
      isVerbose: request.isVerbose,
      language: request.language,
      isSpecialTokens: request.isSpecialTokens,
      isNoTimestamps: request.isNoTimestamps,
      nProcessors: request.nProcessors,
      splitOnWord: request.splitOnWord,
      noFallback: request.noFallback,
      diarize: request.diarize,
      speedUp: request.speedUp,
      isRealtime: request.isRealtime,
      initialPrompt: request.initialPrompt,
      noContext: request.noContext,
      suppressNonSpeechTokens: request.suppressNonSpeechTokens,
      progressCallback: progressCallbackAddress,
    );
  }
  const TranscribeRequestDto._();

  /// Create request json
  factory TranscribeRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TranscribeRequestDtoFromJson(json);

  @override
  String get specialType => 'getTextFromWavFile';

  @override
  String toRequestString() {
    return json.encode({'@type': specialType, ...toJson()});
  }
}
