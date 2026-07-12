import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whisper ggml example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

/// Which microphone flow is currently running.
enum MicMode { none, live, classic }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final model = WhisperModel.base;
  final AudioRecorder audioRecorder = AudioRecorder();
  final WhisperController whisperController = WhisperController();

  String? transcript;
  MicMode activeMode = MicMode.none;
  bool isTranscribing = false;
  bool _actionInFlight = false;
  WhisperLiveSession? liveSession;

  /// Optional initial prompt that biases Whisper decoding toward specific
  /// vocabulary, names, and punctuation. Useful for domain-specific
  /// transcription. Empty string disables biasing (matches whisper.cpp's
  /// default of nullptr). Set to e.g. 'Ask not what your country can do
  /// for you' to experiment. Note that decoding also mimics the prompt's
  /// style: an unpunctuated prompt tends to produce unpunctuated output.
  static const String _initialPrompt = '';

  bool get _isBusy => isTranscribing || activeMode != MicMode.none;

  @override
  void initState() {
    initModel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.inversePrimary,
        title: const Text('Whisper ggml example'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _transcriptCard(colors)),
              const SizedBox(height: 12),
              _statusBar(colors),
              const SizedBox(height: 12),
              _actionBar(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transcriptCard(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: transcript == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.subtitles_outlined, size: 48, color: colors.outline),
                const SizedBox(height: 12),
                Text(
                  'Transcribed text will appear here',
                  style: TextStyle(color: colors.outline),
                ),
              ],
            )
          : SingleChildScrollView(
              child: SelectableText(
                transcript!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
    );
  }

  Widget _statusBar(ColorScheme colors) {
    final (IconData, String)? status = switch ((activeMode, isTranscribing)) {
      (MicMode.live, _) => (
          Icons.graphic_eq,
          'Listening — text updates as you speak',
        ),
      (MicMode.classic, _) => (
          Icons.fiber_manual_record,
          'Recording — transcribes when you stop',
        ),
      (MicMode.none, true) => (Icons.hourglass_top, 'Transcribing…'),
      _ => null,
    };

    if (status == null) return const SizedBox(height: 20);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          status.$1,
          size: 16,
          color: activeMode != MicMode.none ? colors.error : colors.primary,
        ),
        const SizedBox(width: 8),
        Text(status.$2, style: TextStyle(color: colors.onSurfaceVariant)),
      ],
    );
  }

  Widget _actionBar(ColorScheme colors) {
    final bool liveActive = activeMode == MicMode.live;
    final bool classicActive = activeMode == MicMode.classic;
    const Size buttonSize = Size.fromHeight(48);

    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: 'Transcribe live while you speak',
            child: FilledButton.icon(
              onPressed: isTranscribing || classicActive ? null : toggleLive,
              style: FilledButton.styleFrom(
                minimumSize: buttonSize,
                backgroundColor: liveActive ? colors.error : null,
                foregroundColor: liveActive ? colors.onError : null,
              ),
              icon: Icon(liveActive ? Icons.stop : Icons.graphic_eq),
              label: Text(liveActive ? 'Stop' : 'Live mic'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Tooltip(
            message: 'Record first, transcribe after you stop',
            child: FilledButton.tonalIcon(
              onPressed: isTranscribing || liveActive ? null : toggleClassic,
              style: FilledButton.styleFrom(
                minimumSize: buttonSize,
                backgroundColor: classicActive ? colors.error : null,
                foregroundColor: classicActive ? colors.onError : null,
              ),
              icon: Icon(classicActive ? Icons.stop : Icons.mic),
              label: Text(classicActive ? 'Stop' : 'Record'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Tooltip(
            message: 'Transcribe the bundled JFK sample clip',
            child: OutlinedButton.icon(
              onPressed: _isBusy ? null : transcribeJfk,
              style: OutlinedButton.styleFrom(minimumSize: buttonSize),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('JFK sample'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> initModel() async {
    try {
      /// Try initializing the model from assets
      final bytesBase =
          await rootBundle.load('assets/ggml-${model.modelName}.bin');
      final modelPathBase = await whisperController.getPath(model);
      final fileBase = File(modelPathBase);
      await fileBase.writeAsBytes(bytesBase.buffer
          .asUint8List(bytesBase.offsetInBytes, bytesBase.lengthInBytes));
    } catch (e) {
      /// On error try downloading the model
      await whisperController.downloadModel(model);
    }
  }

  /// Live transcription: transcripts appear while you speak instead of
  /// after recording stops.
  Future<void> toggleLive() async {
    // The button stays enabled across the awaits below; without this guard
    // a double-tap would start two recorder streams against the single
    // native session.
    if (_actionInFlight) return;
    _actionInFlight = true;
    try {
      await _toggleLive();
    } finally {
      _actionInFlight = false;
    }
  }

  Future<void> _toggleLive() async {
    if (!await audioRecorder.hasPermission()) return;

    if (activeMode == MicMode.live) {
      await audioRecorder.stop();

      setState(() {
        activeMode = MicMode.none;
        isTranscribing = true;
      });

      final String finalText = await liveSession?.stop() ?? '';
      liveSession = null;

      if (mounted) {
        setState(() {
          isTranscribing = false;
          if (finalText.isNotEmpty) transcript = finalText;
        });
      }
    } else {
      final Stream<Uint8List> pcmStream = await audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      final session = await whisperController.transcribeLive(
        model: model,
        pcm16Stream: pcmStream,
        lang: 'en',
        initialPrompt: _initialPrompt.isEmpty ? null : _initialPrompt,
        // Left false: with it, real non-speech sounds (knocks, clicks)
        // decode as plausible-looking fake words instead of honest
        // annotations like [gun shots]. Silence itself never reaches the
        // decoder thanks to the native energy gate.
        suppressNonSpeechTokens: false,
      );
      liveSession = session;

      session.partials.listen(
        (text) {
          if (mounted && text.isNotEmpty) {
            setState(() => transcript = text);
          }
        },
        // A fatal native error mid-session; the session finalizes itself
        // and stop() still returns the last partial.
        onError: (Object e) => debugPrint('Live transcription error: $e'),
      );

      setState(() => activeMode = MicMode.live);
    }
  }

  /// Classic transcription: records to a file, then transcribes it once
  /// recording stops.
  Future<void> toggleClassic() async {
    if (_actionInFlight) return;
    _actionInFlight = true;
    try {
      await _toggleClassic();
    } finally {
      _actionInFlight = false;
    }
  }

  Future<void> _toggleClassic() async {
    if (!await audioRecorder.hasPermission()) return;

    if (activeMode == MicMode.classic) {
      final audioPath = await audioRecorder.stop();

      setState(() {
        activeMode = MicMode.none;
        isTranscribing = audioPath != null;
      });

      if (audioPath == null) {
        debugPrint('No recording exists.');
        return;
      }

      final result = await whisperController.transcribe(
        model: model,
        audioPath: audioPath,
        lang: 'en',
        initialPrompt: _initialPrompt.isEmpty ? null : _initialPrompt,
      );

      if (mounted) {
        setState(() {
          isTranscribing = false;
          if (result?.transcription.text != null) {
            transcript = result!.transcription.text;
          }
        });
      }
    } else {
      final Directory appDirectory = await getTemporaryDirectory();
      await appDirectory.create(recursive: true);
      // Windows and Linux have no bundled ffmpeg to convert compressed
      // recordings, so record straight to the 16 kHz mono WAV whisper
      // expects.
      if (Platform.isWindows || Platform.isLinux) {
        await audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: '${appDirectory.path}/test.wav',
        );
      } else {
        await audioRecorder.start(const RecordConfig(),
            path: '${appDirectory.path}/test.m4a');
      }

      setState(() => activeMode = MicMode.classic);
    }
  }

  Future<void> transcribeJfk() async {
    final Directory tempDir = await getTemporaryDirectory();
    // On macOS the sandboxed Caches directory may not exist yet.
    await tempDir.create(recursive: true);
    final asset = await rootBundle.load('assets/jfk.wav');
    final String jfkPath = "${tempDir.path}/jfk.wav";
    final File convertedFile = await File(jfkPath).writeAsBytes(
      asset.buffer.asUint8List(),
    );

    setState(() => isTranscribing = true);

    final result = await whisperController.transcribe(
      model: model,
      audioPath: convertedFile.path,
      lang: 'auto',
      initialPrompt: _initialPrompt.isEmpty ? null : _initialPrompt,
    );

    if (mounted) {
      setState(() {
        isTranscribing = false;
        if (result?.transcription.text != null) {
          transcript = result!.transcription.text;
        }
      });
    }
  }
}
