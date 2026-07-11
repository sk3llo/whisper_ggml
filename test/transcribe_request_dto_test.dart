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
    });
  });
}
