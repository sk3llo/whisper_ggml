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

    /// Keep the model resident in native memory after this request.
    ///
    /// By default every transcription loads the model file from disk
    /// (seconds for the small models and up) and frees it when the request
    /// completes. With [keepModelLoaded] set, the loaded model is parked in
    /// the native layer instead, and the next transcription with the same
    /// model file skips the load entirely — for push-to-talk dictation and
    /// other short repeated requests this removes most of the per-request
    /// latency.
    ///
    /// A reused model transcribes exactly like a freshly loaded one: no
    /// text or decoder state carries over between requests, and
    /// [initialPrompt] and the other parameters apply per request as
    /// before.
    ///
    /// The parked model keeps its full weights in RAM (from ~100 MB for
    /// `tiny` up to several GB for the large models) until released. Free
    /// it with `Whisper.releaseModel`, or by running one transcription with
    /// the same model and [keepModelLoaded] back to `false`. Only one model
    /// stays resident per process: parking a different model replaces (and
    /// frees) the previous one.
    ///
    /// Default `false` preserves the load-per-request behaviour of every
    /// previous version.
    @Default(false) bool keepModelLoaded,

    /// Path to a Silero VAD model (e.g. `ggml-silero-v5.1.2.bin`),
    /// enabling whisper.cpp's built-in voice-activity detection for this
    /// request.
    ///
    /// VAD trims non-speech from the audio before decoding — the standard
    /// defence against whisper hallucinating or looping over the leading
    /// and trailing silence of push-to-talk recordings. The VAD models are
    /// small (~1 MB) and add little latency relative to the decode they
    /// shorten.
    ///
    /// Null (default) leaves VAD off, matching the behaviour of every
    /// previous version.
    @Default(null) String? vadModelPath,

    /// Padding in milliseconds kept around each detected speech segment
    /// when [vadModelPath] is set, so clipped first and last words stay
    /// intact. Null keeps whisper.cpp's default, and negative values are
    /// treated the same as null. Values around 100 ms work well for
    /// push-to-talk; much larger values can garble segment boundaries.
    /// Ignored when [vadModelPath] is null.
    @Default(null) int? vadSpeechPadMs,
  }) = _TranscribeRequest;
  const TranscribeRequest._();
}
