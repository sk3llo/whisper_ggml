import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:whisper_ggml/src/models/whisper_model.dart';
import 'package:whisper_ggml/src/whisper_audio_convert.dart';

import 'models/requests/transcribe_request.dart';
import 'models/requests/transcribe_request_dto.dart';
import 'models/requests/version_request.dart';
import 'models/responses/whisper_transcribe_response.dart';
import 'models/responses/whisper_version_response.dart';
import 'models/whisper_dto.dart';

export 'models/_models.dart';
export 'whisper_audio_convert.dart';

/// Native request type
typedef WReqNative = Pointer<Utf8> Function(Pointer<Utf8> body);

/// Entry point
class Whisper {
  /// [model] is required
  /// [modelDir] is path where downloaded model will be stored.
  /// Default to library directory
  const Whisper({required this.model, this.modelDir});

  /// model used for transcription
  final WhisperModel model;

  /// override of model storage path
  final String? modelDir;

  DynamicLibrary _openLib() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libwhisper.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('whisper_ggml.dll');
    } else {
      return DynamicLibrary.process();
    }
  }

  Future<Map<String, dynamic>> _request({
    required WhisperRequestDto whisperRequest,
  }) async {
    return Isolate.run(() async {
      final Pointer<Utf8> data =
          whisperRequest.toRequestString().toNativeUtf8();
      final Pointer<Utf8> res = _openLib()
          .lookupFunction<WReqNative, WReqNative>('request')
          .call(data);

      final Map<String, dynamic> result =
          json.decode(res.toDartString()) as Map<String, dynamic>;

      malloc.free(data);
      // Native responses are malloc'd specifically so this free is valid.
      malloc.free(res);
      return result;
    });
  }

  /// Transcribe audio file to text
  Future<WhisperTranscribeResponse> transcribe({
    required TranscribeRequest transcribeRequest,
    required String modelPath,
  }) async {
    try {
      final WhisperAudioConvert converter = WhisperAudioConvert(
        audioInput: File(transcribeRequest.audio),
        audioOutput: File('${transcribeRequest.audio}.wav'),
      );

      final File? convertedFile = await converter.convert();

      final TranscribeRequest req = transcribeRequest.copyWith(
        audio: convertedFile?.path ?? transcribeRequest.audio,
      );

      final Map<String, dynamic> result = await _request(
        whisperRequest: TranscribeRequestDto.fromTranscribeRequest(
          req,
          modelPath,
        ),
      );

      if (result['text'] == null) {
        throw Exception(result['message']);
      }
      return WhisperTranscribeResponse.fromJson(result);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  /// Get whisper version
  Future<String?> getVersion() async {
    final Map<String, dynamic> result = await _request(
      whisperRequest: const VersionRequest(),
    );

    final WhisperVersionResponse response = WhisperVersionResponse.fromJson(
      result,
    );
    return response.message;
  }
}
