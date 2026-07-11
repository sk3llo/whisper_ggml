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

    /// Sets `whisper_full_params.no_context` on the native side. Equivalent
    /// to Python whisper's `condition_on_previous_text=False`.
    ///
    /// When `true`, whisper.cpp does NOT feed prior-segment transcripts
    /// into the decoder as context. Useful for short single-utterance
    /// transcription (e.g. verse recitation) where carry-over context
    /// can bias the decoder toward hallucinated repetition or "tail of
    /// utterance" attractors.
    ///
    /// Default `false` matches whisper.cpp's default and the behaviour
    /// of every previous version of this package.
    @Default(false) bool noContext,

    /// Sets `whisper_full_params.suppress_non_speech_tokens` on the
    /// native side.
    ///
    /// When `true`, whisper does not emit non-speech annotation tokens
    /// such as `[BLANK_AUDIO]`, `[Music]`, or bracketed sound effects,
    /// which it otherwise produces for silence and background noise.
    /// Recommended for live transcription, where trailing silence is
    /// common. Side effect: legitimate brackets and parentheses in
    /// dictated text are suppressed too.
    ///
    /// Default `false` matches whisper.cpp's default.
    @Default(false) bool suppressNonSpeechTokens,
  }) = _TranscribeRequest;
  const TranscribeRequest._();
}
