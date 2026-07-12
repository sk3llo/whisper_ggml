import 'dart:async';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

/// Class used to convert any audio file to wav
class WhisperAudioConvert {
  ///
  const WhisperAudioConvert({
    required this.audioInput,
    required this.audioOutput,
  });

  /// Input audio file
  final File audioInput;

  /// Output audio file
  /// Overwriten if already exist
  final File audioOutput;

  /// convert [audioInput] to wav file
  Future<File?> convert() async {
    if (Platform.isWindows) {
      return _convertWithFfmpegCli();
    }

    final FFmpegSession session = await FFmpegKit.execute(
      [
        '-y',
        '-i',
        audioInput.path,
        '-ar',
        '16000',
        '-ac',
        '1',
        '-c:a',
        'pcm_s16le',
        audioOutput.path,
      ].join(' '),
    );

    final ReturnCode? returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return audioOutput;
    } else if (ReturnCode.isCancel(returnCode)) {
      debugPrint('File convertion canceled');
    } else {
      debugPrint(
        'File convertion error with returnCode ${returnCode?.getValue()}',
      );
    }

    return null;
  }

  /// ffmpeg_kit has no Windows implementation, so Windows uses an `ffmpeg`
  /// executable from PATH instead. Returns null when ffmpeg is missing or
  /// fails; callers then transcribe the original file, which works as long
  /// as it is already a 16 kHz mono WAV.
  Future<File?> _convertWithFfmpegCli() async {
    try {
      final ProcessResult result = await Process.run('ffmpeg', [
        '-y',
        '-i',
        audioInput.path,
        '-ar',
        '16000',
        '-ac',
        '1',
        '-c:a',
        'pcm_s16le',
        audioOutput.path,
      ]);
      if (result.exitCode == 0) {
        return audioOutput;
      }
      debugPrint(
        'File convertion error with exitCode ${result.exitCode}: '
        '${result.stderr}',
      );
    } on ProcessException {
      debugPrint(
        'ffmpeg not found on PATH; passing audio through unconverted. '
        'Input must be a 16 kHz mono WAV.',
      );
    }
    return null;
  }
}
