
import 'dart:async';
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
  String fileName = 'कोई ऑडियो फाइल नहीं चुनी गई';

  double effectLevel = 0.70;
  double feedback = 0.45;
  double delayTime = 250;

  bool isPlaying = false;
  bool isProcessing = false;

  StreamSubscription<PlayerState>? playerSubscription;

  @override
  void initState() {
    super.initState();

    playerSubscription = player.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        isPlaying = state.playing;
      });
    });
  }

  Future<void> pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'mp4'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;

      if (path == null || !File(path).existsSync()) {
        showMessage('यह फाइल नहीं खुल सकी। दूसरी फाइल चुनें।');
        return;
      }

      await player.stop();

      setState(() {
        inputPath = path;
        outputPath = null;
        fileName = result.files.single.name;
        isPlaying = false;
      });

      await player.setFilePath(path);

      showMessage('फाइल सफलतापूर्वक चुनी गई');
    } catch (e) {
      showMessage('फाइल खोलने में समस्या: $e');
    }
  }

  Future<void> playPause() async {
    if (inputPath == null && outputPath == null) {
      showMessage('पहले ऑडियो फाइल चुनें');
      return;
    }

    try {
      if (player.playing) {
        await player.pause();
      } else {
        if (player.processingState == ProcessingState.completed) {
          await player.seek(Duration.zero);
        }
        unawaited(player.play());
      }
    } catch (e) {
      showMessage('Playback में समस्या: $e');
    }
  }

  Future<void> stopAudio() async {
    await player.stop();
    if (!mounted) return;

    setState(() {
      isPlaying = false;
    });
  }

  Future<void> makeEcho() async {
    if (inputPath == null) {
      showMessage('पहले MP3, WAV या MP4 फाइल चुनें');
      return;
    }

    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      await player.stop();

      final directory = await getApplicationDocumentsDirectory();

      final outputFile =
          '${directory.path}/echo_${DateTime.now().millisecondsSinceEpoch}.mp3';

      final delay = delayTime.round();
      final decay = feedback.clamp(0.0, 0.90);
      final inputGain = effectLevel.clamp(0.0, 1.0);

      final secondDelay = delay * 2;
      final secondDecay = decay * 0.70;

      final echoFilter =
          'aecho=$inputGain:0.9:$delay|$secondDelay:$decay|$secondDecay';

      final arguments = [
        '-y',
        '-i',
        inputPath!,
        '-vn',
        '-af',
        echoFilter,
        '-codec:a',
        'libmp3lame',
        '-q:a',
        '2',
        outputFile,
      ];

      final session =
          await FFmpegKit.executeWithArguments(arguments);

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode) &&
          File(outputFile).existsSync()) {
        setState(() {
          outputPath = outputFile;
        });

        await player.setFilePath(outputFile);

        showMessage('Echo तैयार हो गया!');
      } else {
        final logs = await session.getOutput();
        showMessage('Echo नहीं बन पाया। फाइल या फॉर्मेट जाँचें।');
        debugPrint('FFmpeg error: $logs');
      }
    } catch (e) {
      showMessage('Echo बनाने में समस्या: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> shareEcho() async {
    if (outputPath == null || !File(outputPath!).existsSync()) {
      showMessage('पहले Echo तैयार करें');
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'SHAIR-E-RASOOL DD-8 - Echo Audio',
          files: [XFile(outputPath!)],
        ),
      );
    } catch (e) {
      showMessage('Share करने में समस्या: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF174B35),
      ),
    );
  }

  Widget controlSlider({
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Colors.amber,
          inactiveColor: Colors.white24,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget actionButton({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    Color color = const Color(0xFF17633F),
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 8,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    playerSubscription?.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071D18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C3828),
        foregroundColor: Colors.white,
        title: const Text(
          'SHAIR-E-RASOOL DD-8',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              const Icon(
                Icons.graphic_eq,
                color: Colors.amber,
                size: 65,
              ),

              const SizedBox(height: 8),

              const Text(
                'FILE ECHO',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF103B2B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.audio_file,
                      color: Colors.amber,
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
                      onPressed:
                          isProcessing ? null : pickAudioFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('SELECT AUDIO / VIDEO'),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Supported: MP3 • WAV • MP4',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF103B2B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ECHO CONTROL',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),

                    controlSlider(
                      title: 'E.LEVEL',
                      valueText:
                          '${(effectLevel * 100).round()}%',
                      value: effectLevel,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        setState(() => effectLevel = value);
                      },
                    ),

                    const SizedBox(height: 12),

                    controlSlider(
                      title: 'F.BACK',
                      valueText:
                          '${(feedback * 100).round()}%',
                      value: feedback,
                      min: 0,
                      max: 0.90,
                      onChanged: (value) {
                        setState(() => feedback = value);
                      },
                    ),

                    const SizedBox(height: 12),

                    controlSlider(
                      title: 'D.TIME',
                      valueText: '${delayTime.round()} ms',
                      value: delayTime,
                      min: 50,
                      max: 1000,
                      onChanged: (value) {
                        setState(() => delayTime = value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  actionButton(
                    title: isPlaying ? 'PAUSE' : 'PLAY',
                    icon: isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    onTap: playPause,
                  ),
                  const SizedBox(width: 10),
                  actionButton(
                    title: 'STOP',
                    icon: Icons.stop,
                    color: const Color(0xFF8B2929),
                    onTap: stopAudio,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : makeEcho,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.graphic_eq),
                  label: Text(
                    isProcessing
                        ? 'PLEASE WAIT...'
                        : 'CREATE ECHO MP3',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 17,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: outputPath == null ? null : shareEcho,
                  icon: const Icon(Icons.share),
                  label: const Text('SHARE ECHO MP3'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17633F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'NAAT • AUDIO • DIGITAL DELAY',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Developer: IDRISH',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
