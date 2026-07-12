import 'package:flutter_test/flutter_test.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

void main() {
  group('WhisperModel.modelUri', () {
    test('regular models download from ggerganov/whisper.cpp', () {
      expect(
        WhisperModel.base.modelUri.toString(),
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
      );
    });

    test('tdrz models download from akashmjn/tinydiarize-whisper.cpp', () {
      expect(
        WhisperModel.smallEnTdrz.modelUri.toString(),
        'https://huggingface.co/akashmjn/tinydiarize-whisper.cpp/resolve/main/ggml-small.en-tdrz.bin',
      );
    });
  });

  group('WhisperTranscribeSegment.speakerTurnNext', () {
    test('parses speaker_turn_next from native response', () {
      final WhisperTranscribeSegment segment =
          WhisperTranscribeSegment.fromJson(const <String, dynamic>{
        'from_ts': 0,
        'to_ts': 1100,
        'text': 'hello',
        'speaker_turn_next': true,
      });
      expect(segment.speakerTurnNext, isTrue);
    });

    test('defaults to false when key is absent (older native layer)', () {
      final WhisperTranscribeSegment segment =
          WhisperTranscribeSegment.fromJson(const <String, dynamic>{
        'from_ts': 0,
        'to_ts': 1100,
        'text': 'hello',
      });
      expect(segment.speakerTurnNext, isFalse);
    });
  });
}
