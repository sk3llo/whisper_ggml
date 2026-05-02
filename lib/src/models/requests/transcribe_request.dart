import 'package:freezed_annotation/freezed_annotation.dart';

part 'transcribe_request.freezed.dart';

/// Transcription request parameters
@freezed
abstract class TranscribeRequest with _$TranscribeRequest {
  const factory TranscribeRequest({
    required String audio,
    @Default(false) bool isTranslate,
    @Default(6) int threads,
    @Default(false) bool isVerbose,
    @Default('en') String language,
    @Default(false) bool isSpecialTokens,
    @Default(false) bool isNoTimestamps,
    @Default(false) bool isRealtime,
    @Default(1) int nProcessors,
    @Default(false) bool splitOnWord,
    @Default(false) bool noFallback,
    @Default(false) bool diarize,
    @Default(false) bool speedUp,
    @Default(null) Stream<String>? realtimeStream,

    /// Optional text passed to whisper.cpp as `whisper_full_params.initial_prompt`.
    ///
    /// Whisper uses this to bias decoding toward vocabulary, names, and
    /// punctuation that appear in the prompt — useful for domain-specific
    /// transcription (e.g. medical, legal, scripture, product names) where
    /// the same words otherwise get misrecognised. Empty / null disables
    /// biasing (matches whisper.cpp's default of `nullptr`).
    ///
    /// See OpenAI's transcription docs for guidance on prompt content.
    @Default(null) String? initialPrompt,
  }) = _TranscribeRequest;
  const TranscribeRequest._();
}
