
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:share_plus/share_plus.dart';

class FileEchoScreen extends StatefulWidget {
  const FileEchoScreen({super.key});

  @override
  State<FileEchoScreen> createState() => _FileEchoScreenState();
}

class _FileEchoScreenState extends State<FileEchoScreen> {
  final AudioPlayer player = AudioPlayer();

  String? inputPath;
  String? outputPath;
  String fileName = 'No file selected';

  double delayTime = 200;
  double feedback = 4;
  double effectLevel = 5;

  bool processing = false;
  bool playing = false;

  Future<void> chooseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'mp4'],
      );

      if (result == null || result.files.isEmpty) return;

      final selected = result.files.single;

      if (selected.path == null) {
        showMessage('File path nahi mila. Dobara select karein.');
        return;
      }

      await player.stop();

      setState(() {
        inputPath = selected.path;
        fileName = selected.name;
        outputPath = null;
        playing = false;
      });

      showMessage('File selected successfully');
    } catch (e) {
      showMessage('File error: $e');
    }
  }

  Future<void> playPause() async {
    if (inputPath == null && outputPath == null) {
      showMessage('Pehle audio file select karein');
      return;
    }

    try {
      if (player.playing) {
        await player.pause();
        setState(() => playing = false);
      } else {
        if (player.processingState == ProcessingState.idle ||
            player.processingState == ProcessingState.completed) {
          await player.setFilePath(outputPath ?? inputPath!);
        }

        setState(() => playing = true);
        player.play();
      }
    } catch (e) {
      showMessage('Playback error: $e');
    }
  }

  Future<void> stopAudio() async {
    await player.stop();
    setState(() => playing = false);
  }

  Future<void> processEcho() async {
    if (inputPath == null) {
      showMessage('Pehle MP3, WAV ya MP4 select karein');
      return;
    }

    if (processing) return;

    setState(() => processing = true);

    try {
      await player.stop();
      setState(() => playing = false);

      final directory = await getApplicationDocumentsDirectory();

      final output = 
          '${directory.path}/SHAIR_E_RASOOL_ECHO_${DateTime.now().millisecondsSinceEpoch}.mp3';

      final delay = delayTime.round();
      final fb = (feedback / 10).clamp(0.1, 0.8);
      final level = (effectLevel / 10).clamp(0.1, 1.0);

      final filter =
          'aecho=$level:0.9:$delay|${delay * 2}|${delay * 3}:$fb|${fb * 0.65}|${fb * 0.4}';

      final session = await FFmpegKit.executeWithArguments([
        '-y',
        '-i',
        inputPath!,
        '-vn',
        '-af',
        filter,
        '-codec:a',
        'libmp3lame',
        '-q:a',
        '2',
        output,
      ]);

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode) &&
          await File(output).exists()) {
        setState(() => outputPath = output);
        await player.setFilePath(output);

        showMessage('Echo MP3 successfully ready!');
      } else {
        final logs = await session.getLogs();
        final errorText = logs
            .map((log) => log.getMessage())
            .take(4)
            .join('\n');

        showMessage('Echo processing failed: $errorText');
      }
    } catch (e) {
      showMessage('Processing error: $e');
    } finally {
      if (mounted) {
        setState(() => processing = false);
      }
    }
  }

  Future<void> shareAudio() async {
    if (outputPath == null) {
      showMessage('Pehle Echo MP3 banayein');
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(outputPath!)],
          text: 'SHAIR-E-RASOOL DD-8 Echo Audio',
        ),
      );
    } catch (e) {
      showMessage('Share error: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget controlSlider(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ${value.toStringAsFixed(1)}',
          style: const TextStyle(
            color: Color(0xFFFFD76A),
            fontWeight: FontWeight.bold,
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: const Color(0xFF39FF14),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget actionButton(
    String title,
    IconData icon,
    VoidCallback? action,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: action,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF164D19),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 5),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06140D),
      appBar: AppBar(
        title: const Text(
          'FILE ECHO',
          style: TextStyle(color: Color(0xFFFFD76A)),
        ),
        backgroundColor: const Color(0xFF101512),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF06140D),
              Color(0xFF102C20),
              Color(0xFF06140D),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.graphic_eq,
                  color: Color(0xFF39FF14),
                  size: 75,
                ),
                const SizedBox(height: 15),
                const Text(
                  'SHAIR-E-RASOOL DD-8',
                  style: TextStyle(
                    color: Color(0xFFFFD76A),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xEE101511),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFB99A42),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.audio_file,
                        color: Colors.greenAccent,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        fileName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: chooseFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('SELECT MP3 / WAV / MP4'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xEE101511),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFB99A42),
                    ),
                  ),
                  child: Column(
                    children: [
                      controlSlider(
                        'E.LEVEL',
                        effectLevel,
                        0,
                        10,
                        (v) => setState(() => effectLevel = v),
                      ),
                      controlSlider(
                        'F.BACK',
                        feedback,
                        0,
                        10,
                        (v) => setState(() => feedback = v),
                      ),
                      controlSlider(
                        'D.TIME (ms)',
                        delayTime,
                        50,
                        3200,
                        (v) => setState(() => delayTime = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    actionButton(
                      'PLAY',
                      Icons.play_arrow,
                      playPause,
                    ),
                    actionButton(
                      'PAUSE',
                      Icons.pause,
                      player.playing ? playPause : null,
                    ),
                    actionButton(
                      'STOP',
                      Icons.stop,
                      stopAudio,
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: processing || inputPath == null
                        ? null
                        : processEcho,
                    icon: processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.graphic_eq),
                    label: Text(
                      processing
                          ? 'PROCESSING ECHO...'
                          : 'APPLY ECHO & SAVE MP3',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176522),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(18),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: outputPath == null ? null : shareAudio,
                    icon: const Icon(Icons.share),
                    label: const Text('SHARE ECHO MP3'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF173D75),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Developer: IDRISH',
                  style: TextStyle(
                    color: Color(0xFFFFD76A),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
