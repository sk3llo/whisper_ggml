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

  /// Optional initial prompt that biases Whisper decoding toward specific
  /// vocabulary, names, and punctuation. Useful for domain-specific
  /// transcription. Empty string disables biasing (matches whisper.cpp's
  /// default of nullptr). Edit this string to experiment.
  static const String _initialPrompt =
      'Ask not what your country can do for you';

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

  Future<void> record() async {
    if (await audioRecorder.hasPermission()) {
      if (await audioRecorder.isRecording()) {
        final audioPath = await audioRecorder.stop();

        if (audioPath != null) {
          debugPrint('Stopped listening.');

          setState(() {
            isListening = false;
            isProcessing = true;
          });

          final result = await whisperController.transcribe(
            model: model,
            audioPath: audioPath,
            lang: 'en',
            initialPrompt: _initialPrompt.isEmpty ? null : _initialPrompt,
          );

          if (mounted) {
            setState(() {
              isProcessing = false;
            });
          }

          if (result?.transcription.text != null) {
            setState(() {
              transcribedText = result!.transcription.text;
            });
          }
        } else {
          debugPrint('No recording exists.');
        }
      } else {
        debugPrint('Started listening.');

        setState(() {
          isListening = true;
        });

        final Directory appDirectory = await getTemporaryDirectory();
        await audioRecorder.start(const RecordConfig(),
            path: '${appDirectory.path}/test.m4a');
      }
    }
  }

  Future<void> transcribeJfk() async {
    final Directory tempDir = await getTemporaryDirectory();
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
