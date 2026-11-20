import 'package:flutter/material.dart';

void main() => runApp(const ShairERasoolApp());

const gold = Color(0xFFFFC857);
const blue = Color(0xFF38A7FF);
const panel = Color(0xFF172438);

class ShairERasoolApp extends StatelessWidget {
  const ShairERasoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'शायर-ए-रसूल',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07111F),
        colorScheme: const ColorScheme.dark(
          primary: blue,
          secondary: gold,
          surface: panel,
        ),
      ),
      home: const DelayHome(),
    );
  }
}

class DelayHome extends StatefulWidget {
  const DelayHome({super.key});

  @override
  State<DelayHome> createState() => _DelayHomeState();
}

class _DelayHomeState extends State<DelayHome> {
  int tab = 0;
  double echo = 7, feedback = 4, time = 6;
  double range = 2;
  bool delayOn = false, hold = false, pingPong = false;
  bool compressor = false, noiseCut = false, loop = false;
  String language = 'हिंदी';
  String themeColor = 'Blue';

  String get rangeText => ['50 ms', '200 ms', '800 ms', '3200 ms'][range.round()];

  @override
  Widget build(BuildContext context) {
    final accent = themeColor == 'Blue' ? blue : const Color(0xFFFF8A32);
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF17334C), Color(0xFF07111F), Color(0xFF050A12)],
            ),
          ),
          child: Column(
            children: [
              _header(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Column(
                    children: [
                      _tabs(accent),
                      const SizedBox(height: 12),
                      _meters(),
                      const SizedBox(height: 12),
                      _knobs(accent),
                      const SizedBox(height: 12),
                      _rangePanel(accent),
                      const SizedBox(height: 12),
                      _actions(accent),
                      const SizedBox(height: 12),
                      _footswitch(accent),
                      const SizedBox(height: 10),
                      Text('NAAT • AUDIO • EFFECTS     |     Developer: IDRISH',
                        style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 10, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF164B50), Color(0xFF142B45), Color(0xFF172438)]),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
    ),
    child: Column(children: [
      const Icon(Icons.mosque_rounded, color: gold, size: 42),
      const SizedBox(height: 5),
      const Text('शायर-ए-रसूल', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white)),
      const Text('DIGITAL DELAY  •  DD-8 STYLE', style: TextStyle(color: gold, fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 4),
      Text('मदीना शरीफ की याद में', style: TextStyle(color: Colors.white.withOpacity(.75), fontSize: 11)),
    ]),
  );

  Widget _tabs(Color accent) {
    final labels = ['Live Mic', 'File Echo', 'Presets', 'Theme', 'Settings'];
    final icons = [Icons.mic, Icons.audio_file, Icons.tune, Icons.palette, Icons.settings];
    return Row(children: List.generate(labels.length, (i) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() => tab = i);
            if (i == 2) _message('Presets: Naat, Speech, Soft Echo');
            if (i == 3) _themeDialog();
            if (i == 4) _settingsDialog();
            if (i == 0) _message('Live Mic UI ready — audio engine will be connected next.');
            if (i == 1) _fileDialog();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 1),
            decoration: BoxDecoration(color: tab == i ? accent.withOpacity(.22) : panel,
              border: Border.all(color: tab == i ? accent : Colors.white12),
              borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Icon(icons[i], size: 18, color: tab == i ? accent : Colors.white70),
              const SizedBox(height: 4),
              FittedBox(child: Text(labels[i], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
            ]),
          ),
        ),
      ),
    )));
  }

  Widget _meters() => Row(children: [
    Expanded(child: _meter('IN LEVEL', 6)),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: const Color(0xFF153C2D), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF36D889))),
      child: const Column(children: [
        Icon(Icons.check_circle, color: Color(0xFF36D889), size: 20),
        Text('CHECK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8CF2B8))),
      ]),
    ),
    const SizedBox(width: 8),
    Expanded(child: _meter('OUT LEVEL', 5)),
  ]);

  Widget _meter(String label, int count) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold)),
      const SizedBox(height: 7),
      Row(children: List.generate(8, (i) => Expanded(child: Container(
        height: 13, margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(color: i < count ? (i > 5 ? Colors.orange : const Color(0xFF39D98A)) : Colors.white12,
          borderRadius: BorderRadius.circular(2)),
      )))),
    ]),
  );

  Widget _knobs(Color accent) => Row(children: [
    Expanded(child: _knob('E.LEVEL', echo, (v) => setState(() => echo = v), accent)),
    const SizedBox(width: 8),
    Expanded(child: _knob('F.BACK', feedback, (v) => setState(() => feedback = v), accent)),
    const SizedBox(width: 8),
    Expanded(child: _knob('D.TIME', time, (v) => setState(() => time = v), accent)),
  ]);

  Widget _knob(String name, double value, ValueChanged<double> onChanged, Color accent) => Container(
    padding: const EdgeInsets.fromLTRB(7, 10, 7, 8),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white10)),
    child: Column(children: [
      Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
      const SizedBox(height: 3),
      SizedBox(height: 66, child: RotatedBox(
        quarterTurns: 3,
        child: Slider(value: value, min: 0, max: 10, onChanged: onChanged, activeColor: accent, inactiveColor: Colors.white12),
      )),
      Text(value.toStringAsFixed(1), style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 16)),
    ]),
  );

  Widget _rangePanel(Color accent) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: accent.withOpacity(.55))),
    child: Column(children: [
      const Text('DELAY RANGE', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 2)),
      Text(rangeText, style: TextStyle(fontSize: 30, color: accent, fontWeight: FontWeight.w900)),
      Slider(value: range, min: 0, max: 3, divisions: 3, activeColor: accent, onChanged: (v) => setState(() => range = v)),
      const Text('800 ms  |  81 BPM  (sample display)', style: TextStyle(color: gold, fontSize: 11)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _chip('MODULATE', true, accent),
        const SizedBox(width: 8),
        _chip('ANALOG', false, accent),
      ]),
    ]),
  );

  Widget _actions(Color accent) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 7, runSpacing: 7,
    children: [
      _action('TAP', Icons.touch_app, accent, () => _message('Tap tempo control UI ready.')),
      _action(hold ? 'HOLD ON' : 'HOLD', Icons.pause, accent, () => setState(() => hold = !hold)),
      _action(pingPong ? 'PING-PONG ON' : 'PING-PONG', Icons.swap_horiz, pingPong ? Colors.orange : accent, () => setState(() => pingPong = !pingPong)),
      _action('FX', Icons.auto_awesome, accent, _fxDialog),
      _action('RESET', Icons.refresh, accent, () => setState(() { echo=7; feedback=4; time=6; range=2; })),
      _action('LOCK', Icons.lock_outline, accent, () => _message('Control lock will be connected in the next build.')),
    ],
  );

  Widget _footswitch(Color accent) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => setState(() => delayOn = !delayOn),
    child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: delayOn ? [const Color(0xFF176B49), const Color(0xFF123E35)] : [const Color(0xFF174D8C), const Color(0xFF102A4D)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: delayOn ? Colors.greenAccent : accent, width: 1.5),
        boxShadow: [BoxShadow(color: accent.withOpacity(.18), blurRadius: 16)],
      ),
      child: Column(children: [
        Icon(Icons.power_settings_new, color: Colors.white, size: 25),
        const SizedBox(height: 4),
        Text(delayOn ? 'DIGITAL DELAY ON' : 'DIGITAL DELAY OFF',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
      ]),
    ),
  );

  Widget _chip(String text, bool selected, Color accent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(color: selected ? accent.withOpacity(.2) : Colors.black26,
      borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? accent : Colors.white24)),
    child: Text(text, style: TextStyle(color: selected ? accent : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _action(String label, IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(.6))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color), const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
      ]),
    ),
  );

  void _message(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _fxDialog() => showDialog(context: context, builder: (_) => StatefulBuilder(builder: (context, refresh) => AlertDialog(
    backgroundColor: panel,
    title: const Text('FX • EFFECTS'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      SwitchListTile(title: const Text('Compressor'), value: compressor, onChanged: (v) { setState(() => compressor=v); refresh((){}); }),
      const Text('Amount', style: TextStyle(color: Colors.white70)), const Slider(value: .5, onChanged: null),
      const Text('Reverb Level / Size', style: TextStyle(color: Colors.white70)), const Slider(value: .35, onChanged: null),
      SwitchListTile(title: const Text('Noise Cut'), value: noiseCut, onChanged: (v) { setState(() => noiseCut=v); refresh((){}); }),
      const Text('Ping-Pong sends repeats left and right.', style: TextStyle(fontSize: 11, color: Colors.white60)),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))],
  )));

  void _fileDialog() => showDialog(context: context, builder: (_) => StatefulBuilder(builder: (context, refresh) => AlertDialog(
    backgroundColor: panel,
    title: const Text('FILE ECHO'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.audio_file, size: 42, color: gold),
      const Text('Choose File / Play / Stop / Save Echo File'),
      SwitchListTile(title: const Text('Repeat / Loop'), value: loop, onChanged: (v) { setState(() => loop=v); refresh((){}); }),
      const Text('Before / After • WhatsApp Share', style: TextStyle(color: Colors.white70, fontSize: 12)),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))],
  )));

  void _themeDialog() => showDialog(context: context, builder: (_) => AlertDialog(
    backgroundColor: panel, title: const Text('THEME'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      RadioListTile<String>(value: 'Blue', groupValue: themeColor, title: const Text('Blue knobs'), onChanged: (v) => setState(() { themeColor=v!; Navigator.pop(context); })),
      RadioListTile<String>(value: 'Orange', groupValue: themeColor, title: const Text('Orange knobs'), onChanged: (v) => setState(() { themeColor=v!; Navigator.pop(context); })),
    ]),
  ));

  void _settingsDialog() => showDialog(context: context, builder: (_) => AlertDialog(
    backgroundColor: panel, title: const Text('SETTINGS'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<String>(value: language, decoration: const InputDecoration(labelText: 'Language'),
        items: ['हिंदी','English','Roman Urdu'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => language=v!)),
      const SizedBox(height: 10),
      const Text('शायर-ए-रसूल • Developer: IDRISH'),
      const Text('Guide / About', style: TextStyle(color: Colors.white60)),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))],
  ));
}
