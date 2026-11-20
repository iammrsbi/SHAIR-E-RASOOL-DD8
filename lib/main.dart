
import 'package:flutter/material.dart';
import 'audio_engine.dart';

void main() {
  runApp(const SayarApp());
}

class SayarApp extends StatelessWidget {
  const SayarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SAYAR-E-RASOOL DD-8',
      theme: ThemeData.dark(),
      home: const DelayScreen(),
    );
  }
}

class DelayScreen extends StatefulWidget {
  const DelayScreen({super.key});

  @override
  State<DelayScreen> createState() => _DelayScreenState();
}

class _DelayScreenState extends State<DelayScreen> {
  final AudioEngine audio = AudioEngine();

  bool delayOn = false;
  bool busy = false;
  bool ancOn = false;
  bool pingPong = false;
  bool fxOn = false;
  bool holdOn = false;
  bool modulate = true;

  double effectLevel = 5;
  double feedback = 4;
  double delayTime = 200;
  double ancLevel = 7;

  String selectedMode = 'MODULATE';

  int get delayMilliseconds => delayTime.round();

  Future<void> toggleDelay() async {
    if (busy) return;

    setState(() => busy = true);

    try {
      if (!delayOn) {
        await audio.setDelay(delayMilliseconds);
        await audio.setFeedback(feedback / 10);
        await audio.setEffectLevel(effectLevel / 10);

        final started = await audio.start();

        if (!mounted) return;
        setState(() => delayOn = started);

        if (!started) {
          showMessage('Mic start nahi hua. Permission check karein.');
        }
      } else {
        await audio.stop();
        if (!mounted) return;
        setState(() => delayOn = false);
      }
    } catch (e) {
      showMessage('Audio error: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> updateDelay(double value) async {
    setState(() => delayTime = value);
    if (delayOn) {
      await audio.setDelay(delayMilliseconds);
    }
  }

  Future<void> updateFeedback(double value) async {
    setState(() => feedback = value);
    if (delayOn) {
      await audio.setFeedback(value / 10);
    }
  }

  Future<void> updateEffect(double value) async {
    setState(() => effectLevel = value);
    if (delayOn) {
      await audio.setEffectLevel(value / 10);
    }
  }

  void resetControls() {
    setState(() {
      effectLevel = 5;
      feedback = 4;
      delayTime = 200;
      ancLevel = 7;
      ancOn = false;
      pingPong = false;
      fxOn = false;
      holdOn = false;
      modulate = true;
      selectedMode = 'MODULATE';
    });

    if (delayOn) {
      audio.setDelay(200);
      audio.setFeedback(0.4);
      audio.setEffectLevel(0.5);
    }
  }

  Widget panel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xEE101511),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFB99A42),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget heading(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget knobControl(
    String label,
    double value,
    double min,
    double max,
    String display,
    ValueChanged<double> onChanged,
  ) {
    return Expanded(
      child: panel(
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 12,
        ),
        child: Column(
          children: [
            heading(label),
            const SizedBox(height: 8),
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF777777),
                    Color(0xFF111111),
                    Color(0xFF555555),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFF39FF14),
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.green,
                    blurRadius: 9,
                  ),
                ],
              ),
              child: const Icon(
                Icons.circle,
                color: Colors.white,
                size: 10,
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF39FF14),
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.green.withOpacity(0.2),
                trackHeight: 3,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
            Text(
              display,
              style: const TextStyle(
                color: Color(0xFF39FF14),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget ledMeter(String label) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 5),
        ...List.generate(6, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            width: 15,
            height: 12,
            decoration: BoxDecoration(
              color: index < 2
                  ? Colors.orange
                  : index < 4
                      ? Colors.yellow
                      : const Color(0xFF39FF14),
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(color: Colors.green, blurRadius: 4),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget actionButton(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF164D19)
                : const Color(0xFF101512),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? const Color(0xFF39FF14)
                  : const Color(0xFFB99A42),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF39FF14), size: 25),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget ancPanel() {
    return Expanded(
      child: panel(
        child: Column(
          children: [
            heading('ANC LEVEL'),
            const SizedBox(height: 8),
            Text(
              ancLevel.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFF39FF14),
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: ancLevel,
              min: 0,
              max: 10,
              activeColor: const Color(0xFF39FF14),
              onChanged: (v) => setState(() => ancLevel = v),
            ),
            heading('ANC MODE'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => ancOn = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          ancOn ? Colors.green : Colors.grey.shade800,
                    ),
                    child: const Text('ON'),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => ancOn = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !ancOn ? Colors.red.shade900 : Colors.grey.shade800,
                    ),
                    child: const Text('OFF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06140D),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/madinah_screen_background.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0x99000000),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Text(
                  'SAYAR-E-RASOOL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFD76A),
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 8),
                    ],
                  ),
                ),
                const Text(
                  'DD-8 DIGITAL DELAY',
                  style: TextStyle(
                    color: Color(0xFFFFD76A),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),

                panel(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ledMeter('IN'),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade900),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'DELAY TIME',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$delayMilliseconds',
                                style: const TextStyle(
                                  color: Color(0xFF39FF14),
                                  fontSize: 43,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.green,
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                'milliseconds',
                                style: TextStyle(color: Colors.greenAccent),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ledMeter('OUT'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    knobControl(
                      'E.LEVEL',
                      effectLevel,
                      0,
                      10,
                      effectLevel.toStringAsFixed(1),
                      updateEffect,
                    ),
                    const SizedBox(width: 5),
                    knobControl(
                      'F.BACK',
                      feedback,
                      0,
                      10,
                      feedback.toStringAsFixed(1),
                      updateFeedback,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    knobControl(
                      'D.TIME',
                      delayTime,
                      50,
                      3200,
                      '${delayMilliseconds}ms',
                      updateDelay,
                    ),
                    const SizedBox(width: 5),
                    ancPanel(),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    actionButton(
                      'TAP TEMPO',
                      Icons.music_note,
                      () => showMessage('Tap Tempo selected'),
                    ),
                    actionButton(
                      'HOLD',
                      Icons.pause,
                      () => setState(() => holdOn = !holdOn),
                      active: holdOn,
                    ),
                    actionButton(
                      'PING-PONG',
                      Icons.sync,
                      () => setState(() => pingPong = !pingPong),
                      active: pingPong,
                    ),
                    actionButton(
                      'FX',
                      Icons.graphic_eq,
                      () => setState(() => fxOn = !fxOn),
                      active: fxOn,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                panel(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'MODE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('MODULATE'),
                        selected: selectedMode == 'MODULATE',
                        selectedColor: Colors.green,
                        onSelected: (_) => setState(() {
                          selectedMode = 'MODULATE';
                          modulate = true;
                        }),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('ANALOG'),
                        selected: selectedMode == 'ANALOG',
                        selectedColor: Colors.green,
                        onSelected: (_) => setState(() {
                          selectedMode = 'ANALOG';
                          modulate = false;
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: toggleDelay,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 19),
                    decoration: BoxDecoration(
                      color: delayOn
                          ? const Color(0xFF174F18)
                          : const Color(0xFF101510),
                      borderRadius: BorderRadius.circular(45),
                      border: Border.all(
                        color: const Color(0xFF39FF14),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.green,
                          blurRadius: 13,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          delayOn ? Icons.power_settings_new : Icons.power,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          busy
                              ? 'PLEASE WAIT...'
                              : delayOn
                                  ? 'DIGITAL DELAY ON'
                                  : 'DIGITAL DELAY OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    actionButton(
                      'LIVE MIC',
                      Icons.mic,
                      toggleDelay,
                      active: delayOn,
                    ),
                    actionButton(
                      'FILE ECHO',
                      Icons.music_note,
                      () => showMessage('File Echo abhi implement karna hai'),
                    ),
                    actionButton(
                      'PRESETS',
                      Icons.tune,
                      () => showMessage('Presets section'),
                    ),
                    actionButton(
                      'NAAT LYRICS',
                      Icons.menu_book,
                      () => showMessage('Naat Lyrics section'),
                    ),
                    actionButton(
                      'SETTINGS',
                      Icons.settings,
                      () => showMessage('Settings section'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                TextButton.icon(
                  onPressed: resetControls,
                  icon: const Icon(Icons.restart_alt, color: Colors.amber),
                  label: const Text(
                    'RESET CONTROLS',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),

                const Text(
                  'MADE FOR NAAT & ISLAMIC AUDIO',
                  style: TextStyle(
                    color: Color(0xFFFFD76A),
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
