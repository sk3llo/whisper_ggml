// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transcribe_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TranscribeRequest {

 String get audio; bool get isTranslate; int get threads; bool get isVerbose; String get language; bool get isSpecialTokens; bool get isNoTimestamps; bool get isRealtime; int get nProcessors; bool get splitOnWord; bool get noFallback; bool get diarize; bool get speedUp; Stream<String>? get realtimeStream;/// Optional text passed to whisper.cpp as `whisper_full_params.initial_prompt`.
///
/// Whisper uses this to bias decoding toward vocabulary, names, and
/// punctuation that appear in the prompt — useful for domain-specific
/// transcription (e.g. medical, legal, scripture, product names) where
/// the same words otherwise get misrecognised. Empty / null disables
/// biasing (matches whisper.cpp's default of `nullptr`).
///
/// See OpenAI's transcription docs for guidance on prompt content.
 String? get initialPrompt;/// Sets `whisper_full_params.no_context` on the native side. Equivalent
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
 bool get noContext;/// Sets `whisper_full_params.suppress_non_speech_tokens` on the
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
 bool get suppressNonSpeechTokens;/// Keep the model resident in native memory after this request.
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
 bool get keepModelLoaded;/// Path to a Silero VAD model (e.g. `ggml-silero-v5.1.2.bin`),
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
 String? get vadModelPath;/// Padding in milliseconds kept around each detected speech segment
/// when [vadModelPath] is set, so clipped first and last words stay
/// intact. Null keeps whisper.cpp's default, and negative values are
/// treated the same as null. Values around 100 ms work well for
/// push-to-talk; much larger values can garble segment boundaries.
/// Ignored when [vadModelPath] is null.
 int? get vadSpeechPadMs;
/// Create a copy of TranscribeRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranscribeRequestCopyWith<TranscribeRequest> get copyWith => _$TranscribeRequestCopyWithImpl<TranscribeRequest>(this as TranscribeRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranscribeRequest&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.isTranslate, isTranslate) || other.isTranslate == isTranslate)&&(identical(other.threads, threads) || other.threads == threads)&&(identical(other.isVerbose, isVerbose) || other.isVerbose == isVerbose)&&(identical(other.language, language) || other.language == language)&&(identical(other.isSpecialTokens, isSpecialTokens) || other.isSpecialTokens == isSpecialTokens)&&(identical(other.isNoTimestamps, isNoTimestamps) || other.isNoTimestamps == isNoTimestamps)&&(identical(other.isRealtime, isRealtime) || other.isRealtime == isRealtime)&&(identical(other.nProcessors, nProcessors) || other.nProcessors == nProcessors)&&(identical(other.splitOnWord, splitOnWord) || other.splitOnWord == splitOnWord)&&(identical(other.noFallback, noFallback) || other.noFallback == noFallback)&&(identical(other.diarize, diarize) || other.diarize == diarize)&&(identical(other.speedUp, speedUp) || other.speedUp == speedUp)&&(identical(other.realtimeStream, realtimeStream) || other.realtimeStream == realtimeStream)&&(identical(other.initialPrompt, initialPrompt) || other.initialPrompt == initialPrompt)&&(identical(other.noContext, noContext) || other.noContext == noContext)&&(identical(other.suppressNonSpeechTokens, suppressNonSpeechTokens) || other.suppressNonSpeechTokens == suppressNonSpeechTokens)&&(identical(other.keepModelLoaded, keepModelLoaded) || other.keepModelLoaded == keepModelLoaded)&&(identical(other.vadModelPath, vadModelPath) || other.vadModelPath == vadModelPath)&&(identical(other.vadSpeechPadMs, vadSpeechPadMs) || other.vadSpeechPadMs == vadSpeechPadMs));
}


@override
int get hashCode => Object.hashAll([runtimeType,audio,isTranslate,threads,isVerbose,language,isSpecialTokens,isNoTimestamps,isRealtime,nProcessors,splitOnWord,noFallback,diarize,speedUp,realtimeStream,initialPrompt,noContext,suppressNonSpeechTokens,keepModelLoaded,vadModelPath,vadSpeechPadMs]);

@override
String toString() {
  return 'TranscribeRequest(audio: $audio, isTranslate: $isTranslate, threads: $threads, isVerbose: $isVerbose, language: $language, isSpecialTokens: $isSpecialTokens, isNoTimestamps: $isNoTimestamps, isRealtime: $isRealtime, nProcessors: $nProcessors, splitOnWord: $splitOnWord, noFallback: $noFallback, diarize: $diarize, speedUp: $speedUp, realtimeStream: $realtimeStream, initialPrompt: $initialPrompt, noContext: $noContext, suppressNonSpeechTokens: $suppressNonSpeechTokens, keepModelLoaded: $keepModelLoaded, vadModelPath: $vadModelPath, vadSpeechPadMs: $vadSpeechPadMs)';
}


}

/// @nodoc
abstract mixin class $TranscribeRequestCopyWith<$Res>  {
  factory $TranscribeRequestCopyWith(TranscribeRequest value, $Res Function(TranscribeRequest) _then) = _$TranscribeRequestCopyWithImpl;
@useResult
$Res call({
 String audio, bool isTranslate, int threads, bool isVerbose, String language, bool isSpecialTokens, bool isNoTimestamps, bool isRealtime, int nProcessors, bool splitOnWord, bool noFallback, bool diarize, bool speedUp, Stream<String>? realtimeStream, String? initialPrompt, bool noContext, bool suppressNonSpeechTokens, bool keepModelLoaded, String? vadModelPath, int? vadSpeechPadMs
});




}
/// @nodoc
class _$TranscribeRequestCopyWithImpl<$Res>
    implements $TranscribeRequestCopyWith<$Res> {
  _$TranscribeRequestCopyWithImpl(this._self, this._then);

  final TranscribeRequest _self;
  final $Res Function(TranscribeRequest) _then;

/// Create a copy of TranscribeRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? audio = null,Object? isTranslate = null,Object? threads = null,Object? isVerbose = null,Object? language = null,Object? isSpecialTokens = null,Object? isNoTimestamps = null,Object? isRealtime = null,Object? nProcessors = null,Object? splitOnWord = null,Object? noFallback = null,Object? diarize = null,Object? speedUp = null,Object? realtimeStream = freezed,Object? initialPrompt = freezed,Object? noContext = null,Object? suppressNonSpeechTokens = null,Object? keepModelLoaded = null,Object? vadModelPath = freezed,Object? vadSpeechPadMs = freezed,}) {
  return _then(_self.copyWith(
audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as String,isTranslate: null == isTranslate ? _self.isTranslate : isTranslate // ignore: cast_nullable_to_non_nullable
as bool,threads: null == threads ? _self.threads : threads // ignore: cast_nullable_to_non_nullable
as int,isVerbose: null == isVerbose ? _self.isVerbose : isVerbose // ignore: cast_nullable_to_non_nullable
as bool,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,isSpecialTokens: null == isSpecialTokens ? _self.isSpecialTokens : isSpecialTokens // ignore: cast_nullable_to_non_nullable
as bool,isNoTimestamps: null == isNoTimestamps ? _self.isNoTimestamps : isNoTimestamps // ignore: cast_nullable_to_non_nullable
as bool,isRealtime: null == isRealtime ? _self.isRealtime : isRealtime // ignore: cast_nullable_to_non_nullable
as bool,nProcessors: null == nProcessors ? _self.nProcessors : nProcessors // ignore: cast_nullable_to_non_nullable
as int,splitOnWord: null == splitOnWord ? _self.splitOnWord : splitOnWord // ignore: cast_nullable_to_non_nullable
as bool,noFallback: null == noFallback ? _self.noFallback : noFallback // ignore: cast_nullable_to_non_nullable
as bool,diarize: null == diarize ? _self.diarize : diarize // ignore: cast_nullable_to_non_nullable
as bool,speedUp: null == speedUp ? _self.speedUp : speedUp // ignore: cast_nullable_to_non_nullable
as bool,realtimeStream: freezed == realtimeStream ? _self.realtimeStream : realtimeStream // ignore: cast_nullable_to_non_nullable
as Stream<String>?,initialPrompt: freezed == initialPrompt ? _self.initialPrompt : initialPrompt // ignore: cast_nullable_to_non_nullable
as String?,noContext: null == noContext ? _self.noContext : noContext // ignore: cast_nullable_to_non_nullable
as bool,suppressNonSpeechTokens: null == suppressNonSpeechTokens ? _self.suppressNonSpeechTokens : suppressNonSpeechTokens // ignore: cast_nullable_to_non_nullable
as bool,keepModelLoaded: null == keepModelLoaded ? _self.keepModelLoaded : keepModelLoaded // ignore: cast_nullable_to_non_nullable
as bool,vadModelPath: freezed == vadModelPath ? _self.vadModelPath : vadModelPath // ignore: cast_nullable_to_non_nullable
as String?,vadSpeechPadMs: freezed == vadSpeechPadMs ? _self.vadSpeechPadMs : vadSpeechPadMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TranscribeRequest].
extension TranscribeRequestPatterns on TranscribeRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranscribeRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranscribeRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranscribeRequest value)  $default,){
final _that = this;
switch (_that) {
case _TranscribeRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranscribeRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TranscribeRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String audio,  bool isTranslate,  int threads,  bool isVerbose,  String language,  bool isSpecialTokens,  bool isNoTimestamps,  bool isRealtime,  int nProcessors,  bool splitOnWord,  bool noFallback,  bool diarize,  bool speedUp,  Stream<String>? realtimeStream,  String? initialPrompt,  bool noContext,  bool suppressNonSpeechTokens,  bool keepModelLoaded,  String? vadModelPath,  int? vadSpeechPadMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranscribeRequest() when $default != null:
return $default(_that.audio,_that.isTranslate,_that.threads,_that.isVerbose,_that.language,_that.isSpecialTokens,_that.isNoTimestamps,_that.isRealtime,_that.nProcessors,_that.splitOnWord,_that.noFallback,_that.diarize,_that.speedUp,_that.realtimeStream,_that.initialPrompt,_that.noContext,_that.suppressNonSpeechTokens,_that.keepModelLoaded,_that.vadModelPath,_that.vadSpeechPadMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String audio,  bool isTranslate,  int threads,  bool isVerbose,  String language,  bool isSpecialTokens,  bool isNoTimestamps,  bool isRealtime,  int nProcessors,  bool splitOnWord,  bool noFallback,  bool diarize,  bool speedUp,  Stream<String>? realtimeStream,  String? initialPrompt,  bool noContext,  bool suppressNonSpeechTokens,  bool keepModelLoaded,  String? vadModelPath,  int? vadSpeechPadMs)  $default,) {final _that = this;
switch (_that) {
case _TranscribeRequest():
return $default(_that.audio,_that.isTranslate,_that.threads,_that.isVerbose,_that.language,_that.isSpecialTokens,_that.isNoTimestamps,_that.isRealtime,_that.nProcessors,_that.splitOnWord,_that.noFallback,_that.diarize,_that.speedUp,_that.realtimeStream,_that.initialPrompt,_that.noContext,_that.suppressNonSpeechTokens,_that.keepModelLoaded,_that.vadModelPath,_that.vadSpeechPadMs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String audio,  bool isTranslate,  int threads,  bool isVerbose,  String language,  bool isSpecialTokens,  bool isNoTimestamps,  bool isRealtime,  int nProcessors,  bool splitOnWord,  bool noFallback,  bool diarize,  bool speedUp,  Stream<String>? realtimeStream,  String? initialPrompt,  bool noContext,  bool suppressNonSpeechTokens,  bool keepModelLoaded,  String? vadModelPath,  int? vadSpeechPadMs)?  $default,) {final _that = this;
switch (_that) {
case _TranscribeRequest() when $default != null:
return $default(_that.audio,_that.isTranslate,_that.threads,_that.isVerbose,_that.language,_that.isSpecialTokens,_that.isNoTimestamps,_that.isRealtime,_that.nProcessors,_that.splitOnWord,_that.noFallback,_that.diarize,_that.speedUp,_that.realtimeStream,_that.initialPrompt,_that.noContext,_that.suppressNonSpeechTokens,_that.keepModelLoaded,_that.vadModelPath,_that.vadSpeechPadMs);case _:
  return null;

}
}

}

/// @nodoc


class _TranscribeRequest extends TranscribeRequest {
  const _TranscribeRequest({required this.audio, this.isTranslate = false, this.threads = 6, this.isVerbose = false, this.language = 'en', this.isSpecialTokens = false, this.isNoTimestamps = false, this.isRealtime = false, this.nProcessors = 1, this.splitOnWord = false, this.noFallback = false, this.diarize = false, this.speedUp = false, this.realtimeStream = null, this.initialPrompt = null, this.noContext = false, this.suppressNonSpeechTokens = false, this.keepModelLoaded = false, this.vadModelPath = null, this.vadSpeechPadMs = null}): super._();
  

@override final  String audio;
@override@JsonKey() final  bool isTranslate;
@override@JsonKey() final  int threads;
@override@JsonKey() final  bool isVerbose;
@override@JsonKey() final  String language;
@override@JsonKey() final  bool isSpecialTokens;
@override@JsonKey() final  bool isNoTimestamps;
@override@JsonKey() final  bool isRealtime;
@override@JsonKey() final  int nProcessors;
@override@JsonKey() final  bool splitOnWord;
@override@JsonKey() final  bool noFallback;
@override@JsonKey() final  bool diarize;
@override@JsonKey() final  bool speedUp;
@override@JsonKey() final  Stream<String>? realtimeStream;
/// Optional text passed to whisper.cpp as `whisper_full_params.initial_prompt`.
///
/// Whisper uses this to bias decoding toward vocabulary, names, and
/// punctuation that appear in the prompt — useful for domain-specific
/// transcription (e.g. medical, legal, scripture, product names) where
/// the same words otherwise get misrecognised. Empty / null disables
/// biasing (matches whisper.cpp's default of `nullptr`).
///
/// See OpenAI's transcription docs for guidance on prompt content.
@override@JsonKey() final  String? initialPrompt;
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
@override@JsonKey() final  bool noContext;
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
@override@JsonKey() final  bool suppressNonSpeechTokens;
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
@override@JsonKey() final  bool keepModelLoaded;
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
@override@JsonKey() final  String? vadModelPath;
/// Padding in milliseconds kept around each detected speech segment
/// when [vadModelPath] is set, so clipped first and last words stay
/// intact. Null keeps whisper.cpp's default, and negative values are
/// treated the same as null. Values around 100 ms work well for
/// push-to-talk; much larger values can garble segment boundaries.
/// Ignored when [vadModelPath] is null.
@override@JsonKey() final  int? vadSpeechPadMs;

/// Create a copy of TranscribeRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranscribeRequestCopyWith<_TranscribeRequest> get copyWith => __$TranscribeRequestCopyWithImpl<_TranscribeRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranscribeRequest&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.isTranslate, isTranslate) || other.isTranslate == isTranslate)&&(identical(other.threads, threads) || other.threads == threads)&&(identical(other.isVerbose, isVerbose) || other.isVerbose == isVerbose)&&(identical(other.language, language) || other.language == language)&&(identical(other.isSpecialTokens, isSpecialTokens) || other.isSpecialTokens == isSpecialTokens)&&(identical(other.isNoTimestamps, isNoTimestamps) || other.isNoTimestamps == isNoTimestamps)&&(identical(other.isRealtime, isRealtime) || other.isRealtime == isRealtime)&&(identical(other.nProcessors, nProcessors) || other.nProcessors == nProcessors)&&(identical(other.splitOnWord, splitOnWord) || other.splitOnWord == splitOnWord)&&(identical(other.noFallback, noFallback) || other.noFallback == noFallback)&&(identical(other.diarize, diarize) || other.diarize == diarize)&&(identical(other.speedUp, speedUp) || other.speedUp == speedUp)&&(identical(other.realtimeStream, realtimeStream) || other.realtimeStream == realtimeStream)&&(identical(other.initialPrompt, initialPrompt) || other.initialPrompt == initialPrompt)&&(identical(other.noContext, noContext) || other.noContext == noContext)&&(identical(other.suppressNonSpeechTokens, suppressNonSpeechTokens) || other.suppressNonSpeechTokens == suppressNonSpeechTokens)&&(identical(other.keepModelLoaded, keepModelLoaded) || other.keepModelLoaded == keepModelLoaded)&&(identical(other.vadModelPath, vadModelPath) || other.vadModelPath == vadModelPath)&&(identical(other.vadSpeechPadMs, vadSpeechPadMs) || other.vadSpeechPadMs == vadSpeechPadMs));
}


@override
int get hashCode => Object.hashAll([runtimeType,audio,isTranslate,threads,isVerbose,language,isSpecialTokens,isNoTimestamps,isRealtime,nProcessors,splitOnWord,noFallback,diarize,speedUp,realtimeStream,initialPrompt,noContext,suppressNonSpeechTokens,keepModelLoaded,vadModelPath,vadSpeechPadMs]);

@override
String toString() {
  return 'TranscribeRequest(audio: $audio, isTranslate: $isTranslate, threads: $threads, isVerbose: $isVerbose, language: $language, isSpecialTokens: $isSpecialTokens, isNoTimestamps: $isNoTimestamps, isRealtime: $isRealtime, nProcessors: $nProcessors, splitOnWord: $splitOnWord, noFallback: $noFallback, diarize: $diarize, speedUp: $speedUp, realtimeStream: $realtimeStream, initialPrompt: $initialPrompt, noContext: $noContext, suppressNonSpeechTokens: $suppressNonSpeechTokens, keepModelLoaded: $keepModelLoaded, vadModelPath: $vadModelPath, vadSpeechPadMs: $vadSpeechPadMs)';
}


}

/// @nodoc
abstract mixin class _$TranscribeRequestCopyWith<$Res> implements $TranscribeRequestCopyWith<$Res> {
  factory _$TranscribeRequestCopyWith(_TranscribeRequest value, $Res Function(_TranscribeRequest) _then) = __$TranscribeRequestCopyWithImpl;
@override @useResult
$Res call({
 String audio, bool isTranslate, int threads, bool isVerbose, String language, bool isSpecialTokens, bool isNoTimestamps, bool isRealtime, int nProcessors, bool splitOnWord, bool noFallback, bool diarize, bool speedUp, Stream<String>? realtimeStream, String? initialPrompt, bool noContext, bool suppressNonSpeechTokens, bool keepModelLoaded, String? vadModelPath, int? vadSpeechPadMs
});




}
/// @nodoc
class __$TranscribeRequestCopyWithImpl<$Res>
    implements _$TranscribeRequestCopyWith<$Res> {
  __$TranscribeRequestCopyWithImpl(this._self, this._then);

  final _TranscribeRequest _self;
  final $Res Function(_TranscribeRequest) _then;

/// Create a copy of TranscribeRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? audio = null,Object? isTranslate = null,Object? threads = null,Object? isVerbose = null,Object? language = null,Object? isSpecialTokens = null,Object? isNoTimestamps = null,Object? isRealtime = null,Object? nProcessors = null,Object? splitOnWord = null,Object? noFallback = null,Object? diarize = null,Object? speedUp = null,Object? realtimeStream = freezed,Object? initialPrompt = freezed,Object? noContext = null,Object? suppressNonSpeechTokens = null,Object? keepModelLoaded = null,Object? vadModelPath = freezed,Object? vadSpeechPadMs = freezed,}) {
  return _then(_TranscribeRequest(
audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as String,isTranslate: null == isTranslate ? _self.isTranslate : isTranslate // ignore: cast_nullable_to_non_nullable
as bool,threads: null == threads ? _self.threads : threads // ignore: cast_nullable_to_non_nullable
as int,isVerbose: null == isVerbose ? _self.isVerbose : isVerbose // ignore: cast_nullable_to_non_nullable
as bool,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,isSpecialTokens: null == isSpecialTokens ? _self.isSpecialTokens : isSpecialTokens // ignore: cast_nullable_to_non_nullable
as bool,isNoTimestamps: null == isNoTimestamps ? _self.isNoTimestamps : isNoTimestamps // ignore: cast_nullable_to_non_nullable
as bool,isRealtime: null == isRealtime ? _self.isRealtime : isRealtime // ignore: cast_nullable_to_non_nullable
as bool,nProcessors: null == nProcessors ? _self.nProcessors : nProcessors // ignore: cast_nullable_to_non_nullable
as int,splitOnWord: null == splitOnWord ? _self.splitOnWord : splitOnWord // ignore: cast_nullable_to_non_nullable
as bool,noFallback: null == noFallback ? _self.noFallback : noFallback // ignore: cast_nullable_to_non_nullable
as bool,diarize: null == diarize ? _self.diarize : diarize // ignore: cast_nullable_to_non_nullable
as bool,speedUp: null == speedUp ? _self.speedUp : speedUp // ignore: cast_nullable_to_non_nullable
as bool,realtimeStream: freezed == realtimeStream ? _self.realtimeStream : realtimeStream // ignore: cast_nullable_to_non_nullable
as Stream<String>?,initialPrompt: freezed == initialPrompt ? _self.initialPrompt : initialPrompt // ignore: cast_nullable_to_non_nullable
as String?,noContext: null == noContext ? _self.noContext : noContext // ignore: cast_nullable_to_non_nullable
as bool,suppressNonSpeechTokens: null == suppressNonSpeechTokens ? _self.suppressNonSpeechTokens : suppressNonSpeechTokens // ignore: cast_nullable_to_non_nullable
as bool,keepModelLoaded: null == keepModelLoaded ? _self.keepModelLoaded : keepModelLoaded // ignore: cast_nullable_to_non_nullable
as bool,vadModelPath: freezed == vadModelPath ? _self.vadModelPath : vadModelPath // ignore: cast_nullable_to_non_nullable
as String?,vadSpeechPadMs: freezed == vadSpeechPadMs ? _self.vadSpeechPadMs : vadSpeechPadMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
