
import 'package:flutter/material.dart';
import 'audio_engine.dart';

void main() => runApp(const ShairERasoolApp());

const deepGreen = Color(0xFF064D25);
const brightGreen = Color(0xFF168A36);
const gold = Color(0xFFFFD54F);

class ShairERasoolApp extends StatelessWidget {
  const ShairERasoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SHAIR-E-RASOOL DD-8',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brightGreen,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: deepGreen,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioEngine audioEngine = AudioEngine();

  double eLevel = 5;
  double feedback = 4;
  double delayTime = 5;

  bool delayOn = false;
  bool pingPong = false;
  bool fxOn = true;
  bool lock = false;
  bool busy = false;

  String mode = 'MODULATE';
  int delayMs = 200;

  void notice(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> toggleAudio() async {
    if (busy || lock) return;

    if (delayOn) {
      setState(() => busy = true);
      await audioEngine.stop();

      if (!mounted) return;

      setState(() {
        delayOn = false;
        busy = false;
      });

      notice('Digital Delay OFF');
      return;
    }

    setState(() => busy = true);
    notice('Microphone start ho raha hai...');

    final success = await audioEngine.start();

    if (!mounted) return;

    if (success) {
      await audioEngine.setDelay(delayMs);
      await audioEngine.setFeedback(feedback / 10);
      await audioEngine.setEffectLevel(eLevel / 10);

      if (!mounted) return;

      setState(() {
        delayOn = true;
        busy = false;
      });

      notice('Digital Delay ON');
    } else {
      setState(() => busy = false);
      notice('Audio start nahi hua. Permission aur Android setup check karein.');
    }
  }

  void updateDelay(int value) {
    setState(() => delayMs = value);
    if (delayOn) {
      audioEngine.setDelay(value);
    }
  }

  Widget menuButton(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF08752D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 18,
            ),
            side: const BorderSide(color: gold, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 25),
          label: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget knob(
    String label,
    double value,
    ValueChanged<double> change,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 100,
            onChanged: lock ? null : change,
          ),
          Text(value.toStringAsFixed(1)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    audioEngine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/madinah_screen_background.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(color: deepGreen);
            },
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.42),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                const Text(
                  'SHAIR-E-RASOOL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'DD-8 DIGITAL DELAY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 16),

                menuButton(
                  Icons.mic,
                  delayOn ? 'STOP LIVE MIC' : 'LIVE MIC',
                  toggleAudio,
                ),

                menuButton(
                  Icons.music_note,
                  'FILE ECHO',
                  () => notice('File Echo module abhi banana baaki hai.'),
                ),

                menuButton(
                  Icons.tune,
                  'PRESETS',
                  () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Wrap(
                          children: ['Naat Soft', 'Mehfil', 'Masjid', 'Studio']
                              .map(
                                (s) => ListTile(
                                  title: Text(s),
                                  onTap: () {
                                    Navigator.pop(context);
                                    notice('$s preset selected');
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                ),

                menuButton(
                  Icons.library_music,
                  'NAAT LYRICS',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LyricsPage(),
                      ),
                    );
                  },
                ),

                menuButton(
                  Icons.settings,
                  'SETTINGS',
                  () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'SHAIR-E-RASOOL DD-8',
                      applicationVersion: '1.0.0',
                      children: const [
                        Text('Developer: IDRISH'),
                        Text('Native Audio Engine'),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                Card(
                  color: const Color(0xE6003015),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: gold),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        const Text(
                          'DIGITAL DELAY CONSOLE',
                          style: TextStyle(
                            color: gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            Meter(label: 'IN'),
                            Meter(label: 'OUT'),
                            Meter(label: 'CHECK'),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            knob('E.LEVEL', eLevel, (v) {
                              setState(() => eLevel = v);
                              if (delayOn) {
                                audioEngine.setEffectLevel(v / 10);
                              }
                            }),
                            knob('F.BACK', feedback, (v) {
                              setState(() => feedback = v);
                              if (delayOn) {
                                audioEngine.setFeedback(v / 10);
                              }
                            }),
                            knob('D.TIME', delayTime, (v) {
                              setState(() => delayTime = v);
                              if (delayOn) {
                                updateDelay(
                                  (50 + v * 315).round(),
                                );
                              }
                            }),
                          ],
                        ),

                        Wrap(
                          spacing: 8,
                          children: [50, 200, 800, 3200].map((v) {
                            return ChoiceChip(
                              label: Text('${v}ms'),
                              selected: delayMs == v,
                              onSelected: lock
                                  ? null
                                  : (_) => updateDelay(v),
                              selectedColor: brightGreen,
                              backgroundColor: const Color(0xFF174A2B),
                              labelStyle: const TextStyle(
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 8),

                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'MODULATE',
                              label: Text('MODULATE'),
                            ),
                            ButtonSegment(
                              value: 'ANALOG',
                              label: Text('ANALOG'),
                            ),
                          ],
                          selected: {mode},
                          onSelectionChanged: lock
                              ? null
                              : (s) => setState(() => mode = s.first),
                        ),

                        SwitchListTile(
                          title: const Text('PING-PONG'),
                          value: pingPong,
                          onChanged: lock
                              ? null
                              : (v) => setState(() => pingPong = v),
                        ),

                        SwitchListTile(
                          title: const Text('FX'),
                          value: fxOn,
                          onChanged: lock
                              ? null
                              : (v) => setState(() => fxOn = v),
                        ),

                        Text(
                          'DELAY: $delayMs ms   •   BPM: ${(60000 / delayMs).round()}',
                          style: const TextStyle(
                            color: gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: lock
                                    ? null
                                    : () {
                                        setState(() {
                                          eLevel = 5;
                                          feedback = 4;
                                          delayTime = 5;
                                          pingPong = false;
                                          fxOn = true;
                                        });
                                        updateDelay(200);
                                        if (delayOn) {
                                          audioEngine.setFeedback(0.4);
                                          audioEngine.setEffectLevel(0.5);
                                        }
                                      },
                                child: const Text('RESET'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() => lock = !lock);
                                },
                                child: Text(lock ? 'UNLOCK' : 'LOCK'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: delayOn
                                  ? Colors.red.shade800
                                  : brightGreen,
                              padding: const EdgeInsets.all(18),
                            ),
                            onPressed: busy || lock ? null : toggleAudio,
                            child: Text(
                              busy
                                  ? 'PLEASE WAIT...'
                                  : delayOn
                                      ? 'DIGITAL DELAY ON'
                                      : 'DIGITAL DELAY OFF',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Developer: IDRISH',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Meter extends StatelessWidget {
  final String label;

  const Meter({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          width: 58,
          height: 13,
          decoration: BoxDecoration(
            color: Colors.greenAccent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: Colors.green, blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}

class LyricsPage extends StatelessWidget {
  const LyricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NAAT LYRICS')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Yahan apni Naat lyrics add karne ke liye section tayyar hai.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
