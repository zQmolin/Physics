import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(const PhysicsApp());
}

class PhysicsApp extends StatelessWidget {
  const PhysicsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(primary: Colors.blueAccent),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), elevation: 0),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('高中物理 · 力学实验室')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: kTemplates.length,
        itemBuilder: (context, i) {
          final t = kTemplates[i];
          return Card(
            color: const Color(0xFF1E1E1E),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blueAccent.shade100, child: Text('${i + 1}', style: const TextStyle(color: Colors.black))),
              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SandboxPage(template: t))),
            ),
          );
        },
      ),
    );
  }
}

class SandboxPage extends StatefulWidget {
  final TemplateModel template;
  const SandboxPage({super.key, required this.template});
  @override
  State<SandboxPage> createState() => _SandboxPageState();
}

class _SandboxPageState extends State<SandboxPage> with SingleTickerProviderStateMixin {
  late SceneModel scene;
  late List<BlockModel> blocks;
  late List<BlockModel> initialBlocks;
  late List<Offset> velocities;
  late AnimationController controller;
  bool running = false;
  List<BlockResult> results = [];

  static const double sceneW = 12;
  static const double sceneH = 7;

  @override
  void initState() {
    super.initState();
    scene = widget.template.scene();
    blocks = widget.template.blocks();
    initialBlocks = blocks.map((b) => b.copy()).toList();
    velocities = blocks.map((b) => Offset(b.initialVelocity, 0)).toList();
    
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addListener(_tick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            running = false;
            blocks = initialBlocks.map((b) => b.copy()).toList();
            velocities = blocks.map((b) => Offset(b.initialVelocity, 0)).toList();
            _compute();
          });
        }
      });
    _compute();
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  void _compute() {
    results = PhysicsEngine(scene).computeAll(blocks, velocities);
  }

  void _tick() {
    final dt = 1 / 60;
    final res = PhysicsEngine(scene).computeAll(blocks, velocities);
    for (int i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final a = res[i].acceleration;
      var v = velocities[i] + a * dt;
      if (scene.type == SceneType.horizontal && v.dx.abs() < 0.05 && scene.externalForce == 0) v = Offset.zero;
      if (scene.type == SceneType.incline && v.dx.abs() < 0.02 && res[i].state.contains('静止')) v = Offset.zero;
      
      final pos = b.position + v * dt;
      b.position = Offset(pos.dx.clamp(0.2, sceneW - 0.2), pos.dy.clamp(0.2, sceneH - 0.2));
      velocities[i] = v;
    }
    setState(() => results = res);
  }

  void _run() {
    if (running) return;
    setState(() {
      running = true;
      blocks = initialBlocks.map((b) => b.copy()).toList();
      velocities = blocks.map((b) => Offset(b.initialVelocity, 0)).toList();
    });
    controller.forward(from: 0);
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('显示力的分解'),
                value: scene.showComponents,
                onChanged: (v) { setD(() {}); setState(() { scene.showComponents = v; _compute(); }); },
              ),
              SwitchListTile(
                title: const Text('g = 10（关闭为 9.8）'),
                value: scene.gravity == 10,
                onChanged: (v) { setD(() {}); setState(() { scene.gravity = v ? 10 : 9.8; _compute(); }); },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.title),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings)],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: SandboxPainter(scene: scene, blocks: blocks, results: results),
                  ),
                ),
                Positioned(
                  left: 10, top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Text(widget.template.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                )
              ],
            ),
          ),
          Container(
            width: 280,
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      const Text('受力与推导', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
                      const SizedBox(height: 8),
                      for (final r in results) _buildResultCard(r),
                    ],
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BlockResult r) {
    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.block.name} · ${r.state}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
            const Divider(color: Colors.white24),
            for (final f in r.forces)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, color: f.color),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${f.name} = ${f.magnitude.toStringAsFixed(1)} N', style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text('计算过程：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
            Text(r.derivation, style: const TextStyle(fontSize: 11, height: 1.4, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white12))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _slider('质量', blocks.first.mass, 0.5, 10, (v) { setState(() { blocks.first.mass = v; initialBlocks.first.mass = v; _compute(); }); }),
          if (scene.type == SceneType.incline)
            _slider('角度', scene.inclineAngle, 5, 60, (v) { setState(() { scene.inclineAngle = v; _compute(); }); }),
          if (scene.type != SceneType.water && scene.type != SceneType.hanging && scene.type != SceneType.pulley)
            _slider('外力', scene.externalForce, 0, 50, (v) { setState(() { scene.externalForce = v; _compute(); }); }),
          _slider('摩擦μ', scene.dynamicFriction, 0, 1, (v) { setState(() { scene.dynamicFriction = v; scene.staticFriction = v; _compute(); }); }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity, height: 40,
            child: ElevatedButton.icon(
              onPressed: running ? null : _run,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text(running ? '演示中…' : '运行实验（3秒）'),
            ),
          )
        ],
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 45, child: Text(label, style: const TextStyle(fontSize: 11))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
            child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(width: 30, child: Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: Colors.blueAccent))),
      ],
    );
  }
}

class SandboxPainter extends CustomPainter {
  final SceneModel scene;
  final List<BlockModel> blocks;
  final List<BlockResult> results;

  SandboxPainter({required this.scene, required this.blocks, required this.results});

  static const double sceneW = 12;
  static const double sceneH = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / sceneW, size.height / sceneH);
    final offsetX = (size.width - sceneW * scale) / 2;
    final groundH = sceneH / 7 * scale;
    final baseY = size.height - groundH;

    Offset toScreen(double x, double y) => Offset(offsetX + x * scale, baseY - y * scale);

    // 背景
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, baseY), Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, baseY)));

    // 场景绘制
    if (scene.type == SceneType.water) {
      final wY = baseY - 2.5 * scale; // 水面高度
      canvas.drawRect(Rect.fromLTWH(0, wY, size.width, size.height - wY), Paint()..color = const Color(0xFF0EA5E9).withOpacity(0.4));
      canvas.drawLine(Offset(0, wY), Offset(size.width, wY), Paint()..color = Colors.cyanAccent..strokeWidth = 2);
    } else if (scene.type == SceneType.incline) {
      final angle = scene.inclineAngle * math.pi / 180;
      final p = Path()
        ..moveTo(offsetX, baseY)
        ..lineTo(offsetX + 1 * scale, baseY - 1 * scale)
        ..lineTo(offsetX + (1 + 10 * math.cos(angle)) * scale, baseY - (1 + 10 * math.sin(angle)) * scale)
        ..close();
      canvas.drawPath(p, Paint()..color = const Color(0xFF334155));
    } else {
      canvas.drawRect(Rect.fromLTWH(0, baseY, size.width, groundH), Paint()..color = const Color(0xFF334155));
      for (double i = 0; i < size.width; i += 40) {
        canvas.drawLine(Offset(i, baseY), Offset(i - 20, size.height), Paint()..color = const Color(0xFF1E293B)..strokeWidth = 2);
      }
    }

    // 墙面
    if (scene.hasWall && scene.type == SceneType.horizontal) {
      final wx = offsetX + scene.wallX * scale;
      canvas.drawRect(Rect.fromLTWH(wx, 0, 10, baseY), Paint()..color = const Color(0xFF475569));
    }

    // 滑轮
    if (scene.type == SceneType.pulley) {
      final c = toScreen(8.5, 5);
      canvas.drawCircle(c, 15, Paint()..color = Colors.grey.shade700);
      canvas.drawCircle(c, 5, Paint()..color = Colors.white);
    }

    // 悬挂
    if (scene.type == SceneType.hanging) {
      final b = blocks.first;
      final top = toScreen(b.position.dx, 6);
      final bottom = toScreen(b.position.dx, b.position.dy + b.size / 2);
      canvas.drawLine(top, bottom, Paint()..color = Colors.white..strokeWidth = 2);
      canvas.drawRect(Rect.fromCenter(center: toScreen(b.position.dx, 5.2), width: 30, height: 50), Paint()..color = Colors.white10);
    }

    // 物块
    for (final b in blocks) {
      final c = toScreen(b.position.dx, b.position.dy);
      final s = b.size * scale;
      final paint = Paint()..color = b.color;
      if (b.shape == BlockShape.square) {
        canvas.drawRect(Rect.fromCenter(center: c, width: s, height: s), paint);
        canvas.drawRect(Rect.fromCenter(center: c, width: s, height: s), Paint()..color = Colors.white54..style = PaintingStyle.stroke..strokeWidth = 1.5);
      } else {
        canvas.drawCircle(c, s / 2, paint);
        canvas.drawCircle(c, s / 2, Paint()..color = Colors.white54..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }

    // 力箭头
    double maxMag = 1;
    for (final r in results) {
      for (final f in r.forces) { if (f.magnitude > maxMag) maxMag = f.magnitude; }
    }
    
    for (final r in results) {
      final c = toScreen(r.block.position.dx, r.block.position.dy);
      for (final f in r.forces) {
        if (f.magnitude < 0.01) continue;
        final len = 20 + (f.magnitude / maxMag) * 70;
        final dir = Offset(f.direction.dx, -f.direction.dy);
        _drawArrow(canvas, c, dir, len, f.color, scene.showValues ? '${f.name} ${f.magnitude.toStringAsFixed(0)}N' : '');
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset dir, double len, Color color, String label) {
    final end = from + dir * len;
    canvas.drawLine(from, end, Paint()..color = color..strokeWidth = 3..strokeCap = StrokeCap.round);
    final head = 10.0;
    final perp = Offset(-dir.dy, dir.dx);
    final p = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - dir.dx * head + perp.dx * head * 0.5, end.dy - dir.dy * head + perp.dy * head * 0.5)
      ..lineTo(end.dx - dir.dx * head - perp.dx * head * 0.5, end.dy - dir.dy * head - perp.dy * head * 0.5)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    
    if (label.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, end + dir * 8 - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
