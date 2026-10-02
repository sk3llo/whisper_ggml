import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'package:whisper_ggml/src/models/requests/transcribe_request_dto.dart';

void main() {
  TranscribeRequest request({String? initialPrompt, bool noContext = false}) {
    return TranscribeRequest(
      audio: '/tmp/audio.wav',
      initialPrompt: initialPrompt,
      noContext: noContext,
    );
  }

  group('TranscribeRequestDto serialization', () {
    test('defaults: initial_prompt is null and no_context is false', () {
      final dto = TranscribeRequestDto.fromTranscribeRequest(
        request(),
        '/tmp/model.bin',
      );

      final body = json.decode(dto.toRequestString()) as Map<String, dynamic>;
      expect(body['@type'], 'getTextFromWavFile');
      expect(body.containsKey('initial_prompt'), isTrue);
      expect(body['initial_prompt'], isNull);
      expect(body['no_context'], isFalse);
    });

    test('initialPrompt and noContext are forwarded with snake_case keys', () {
      final dto = TranscribeRequestDto.fromTranscribeRequest(
        request(initialPrompt: 'Apoquel, pruritus', noContext: true),
        '/tmp/model.bin',
      );

      final body = json.decode(dto.toRequestString()) as Map<String, dynamic>;
      expect(body['initial_prompt'], 'Apoquel, pruritus');
      expect(body['no_context'], isTrue);
    });

    test('suppressNonSpeechTokens defaults to false and forwards true', () {
      final defaultDto = TranscribeRequestDto.fromTranscribeRequest(
        request(),
        '/tmp/model.bin',
      );
      final defaultBody =
          json.decode(defaultDto.toRequestString()) as Map<String, dynamic>;
      expect(defaultBody['suppress_non_speech_tokens'], isFalse);

      final dto = TranscribeRequestDto.fromTranscribeRequest(
        const TranscribeRequest(
          audio: '/tmp/audio.wav',
          suppressNonSpeechTokens: true,
        ),
        '/tmp/model.bin',
      );
      final body = json.decode(dto.toRequestString()) as Map<String, dynamic>;
      expect(body['suppress_non_speech_tokens'], isTrue);
    });

    test('progress_callback is null by default and forwards an address', () {
      final defaultDto = TranscribeRequestDto.fromTranscribeRequest(
        request(),
        '/tmp/model.bin',
      );
      final defaultBody =
          json.decode(defaultDto.toRequestString()) as Map<String, dynamic>;
      expect(defaultBody['progress_callback'], isNull);

      final dto = TranscribeRequestDto.fromTranscribeRequest(
        request(),
        '/tmp/model.bin',
        progressCallbackAddress: 0x7fff12345678,
      );
      final body = json.decode(dto.toRequestString()) as Map<String, dynamic>;
      expect(body['progress_callback'], 0x7fff12345678);
    });

    test('fromJson defaults no_context to false when key is absent', () {
      final dto = TranscribeRequestDto.fromJson(const {
        'audio': '/tmp/audio.wav',
        'model': '/tmp/model.bin',
        'is_translate': false,
        'threads': 4,
        'is_verbose': false,
        'language': 'en',
        'is_special_tokens': false,
        'is_no_timestamps': true,
        'n_processors': 1,
        'split_on_word': false,
        'no_fallback': false,
        'is_realtime': false,
        'diarize': false,
        'speed_up': false,
      });

      expect(dto.initialPrompt, isNull);
      expect(dto.noContext, isFalse);
      expect(dto.keepModelLoaded, isFalse);
    });

    test('keepModelLoaded defaults to false and forwards true', () {
      final defaultDto = TranscribeRequestDto.fromTranscribeRequest(
        request(),
        '/tmp/model.bin',
      );
      final defaultBody =
          json.decode(defaultDto.toRequestString()) as Map<String, dynamic>;
      expect(defaultBody['keep_model_loaded'], isFalse);

      final dto = TranscribeRequestDto.fromTranscribeRequest(
        const TranscribeRequest(
          audio: '/tmp/audio.wav',
          keepModelLoaded: true,
        ),
        '/tmp/model.bin',
      );
      final body = json.decode(dto.toRequestString()) as Map<String, dynamic>;
      expect(body['keep_model_loaded'], isTrue);
    });

    test('VAD stays off by default and forwards model path and padding', () {
      final defaultDto = TranscribeRequestDto.fromTranscribeRequest(
        request(),
        '/tmp/model.bin',
      );
      final defaultBody =
          json.decode(defaultDto.toRequestString()) as Map<String, dynamic>;
      // Null on the wire: the native side only enables VAD for a string.
      expect(defaultBody['vad_model'], isNull);
      expect(defaultBody['vad_speech_pad_ms'], isNull);

      final dto = TranscribeRequestDto.fromTranscribeRequest(
        const TranscribeRequest(
          audio: '/tmp/audio.wav',
          vadModelPath: '/tmp/ggml-silero-v5.1.2.bin',
          vadSpeechPadMs: 100,
        ),
        '/tmp/model.bin',
      );
      final body = json.decode(dto.toRequestString()) as Map<String, dynamic>;
      expect(body['vad_model'], '/tmp/ggml-silero-v5.1.2.bin');
      expect(body['vad_speech_pad_ms'], 100);
    });

    test('a VAD padding override without a model path stays inert', () {
      final dto = TranscribeRequestDto.fromTranscribeRequest(
        const TranscribeRequest(audio: '/tmp/audio.wav', vadSpeechPadMs: 250),
        '/tmp/model.bin',
      );
      final body = json.decode(dto.toRequestString()) as Map<String, dynamic>;
      expect(body['vad_model'], isNull);
      expect(body['vad_speech_pad_ms'], 250);
    });
  });
}
