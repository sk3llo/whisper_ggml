import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'package:record/record.dart';

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

class MyHomePage extends StatefulWidget {
  /// Modify this model based on your needs

  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final model = WhisperModel.base;
  final AudioRecorder audioRecorder = AudioRecorder();
  final WhisperController whisperController = WhisperController();
  String transcribedText = 'Transcribed text will be displayed here';
  bool isProcessing = false;
  bool isProcessingFile = false;
  bool isListening = false;
  WhisperLiveSession? liveSession;

  /// Optional initial prompt that biases Whisper decoding toward specific
  /// vocabulary, names, and punctuation. Useful for domain-specific
  /// transcription. Empty string disables biasing (matches whisper.cpp's
  /// default of nullptr). Set to e.g. 'Ask not what your country can do
  /// for you' to experiment. Note that decoding also mimics the prompt's
  /// style: an unpunctuated prompt tends to produce unpunctuated output.
  static const String _initialPrompt = '';

  @override
  void initState() {
    initModel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Whisper ggml example'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(
                  transcribedText,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                child: Tooltip(
                  message: 'Transcribe jfk.wav asset file',
                  child: CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    maxRadius: 25,
                    child: isProcessingFile
                        ? const CircularProgressIndicator()
                        : IconButton(
                            onPressed: transcribeJfk,
                            icon: Icon(
                              Icons.folder,
                            ),
                          ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: record,
        tooltip: 'Start listening',
        child: isProcessing
            ? const CircularProgressIndicator()
            : Icon(
                isListening ? Icons.mic_off : Icons.mic,
                color: isListening ? Colors.red : null,
              ),
      ),
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
  Future<void> record() async {
    if (!await audioRecorder.hasPermission()) return;

    if (isListening) {
      debugPrint('Stopping live transcription.');
      await audioRecorder.stop();

      setState(() {
        isListening = false;
        isProcessing = true;
      });

      final String finalText = await liveSession?.stop() ?? '';
      liveSession = null;

      if (mounted) {
        setState(() {
          isProcessing = false;
          if (finalText.isNotEmpty) transcribedText = finalText;
        });
      }
    } else {
      debugPrint('Starting live transcription.');

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
      );
      liveSession = session;

      session.partials.listen((text) {
        if (mounted && text.isNotEmpty) {
          setState(() => transcribedText = text);
        }
      });

      setState(() {
        isListening = true;
      });
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

    setState(() {
      isProcessingFile = true;
    });

    final result = await whisperController.transcribe(
      model: model,
      audioPath: convertedFile.path,
      lang: 'auto',
      initialPrompt: _initialPrompt.isEmpty ? null : _initialPrompt,
    );

    setState(() {
      isProcessingFile = false;
    });

    if (result?.transcription.text != null) {
      setState(() {
        transcribedText = result!.transcription.text;
      });
    }
  }
}
