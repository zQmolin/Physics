import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const PhysicsApp());

class PhysicsApp extends StatelessWidget {
  const PhysicsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '力学实验室',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const LabPage(),
    );
  }
}

class LabPage extends StatefulWidget {
  const LabPage({super.key});
  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> with SingleTickerProviderStateMixin {
  double mass = 2.0;
  double mu = 0.3;
  double force = 10.0;
  double posX = 3.0;
  double velocity = 0.0;
  bool running = false;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addListener(_tick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() { running = false; posX = 3.0; velocity = 0; });
        }
      });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _tick() {
    final dt = 1 / 60;
    final g = 10.0;
    final weight = mass * g;
    final normal = weight;
    final fMax = mu * normal;
    double friction = 0;
    if (velocity.abs() < 0.01 && force.abs() <= fMax) {
      friction = -force;
    } else {
      friction = -velocity.sign * mu * normal;
    }
    final accel = (force + friction) / mass;
    velocity += accel * dt;
    posX += velocity * dt;
    if (posX < 0.5) { posX = 0.5; velocity = 0; }
    if (posX > 10.5) { posX = 10.5; velocity = 0; }
    setState(() {});
  }

  void _run() {
    if (running) return;
    setState(() { running = true; posX = 3.0; velocity = 0; });
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final g = 10.0;
    final weight = mass * g;
    final normal = weight;
    final fMax = mu * normal;
    final isStatic = velocity.abs() < 0.01 && force.abs() <= fMax;
    final frictionMag = isStatic ? force.abs() : mu * normal;
    final state = isStatic ? '静止' : (velocity.abs() < 0.05 ? '匀速' : (velocity * force > 0 ? '加速' : '减速'));

    return Scaffold(
      appBar: AppBar(title: const Text('水平面受力实验')),
      body: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: CustomPaint(
                painter: LabPainter(posX: posX, mass: mass, force: force, friction: frictionMag, isStatic: isStatic, running: running),
                size: Size.infinite,
              ),
            ),
          ),
          Container(
            width: 160,
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('物块A · $state', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                _item('重力 G', '${weight.toStringAsFixed(1)} N', Colors.purple),
                _item('支持力 N', '${normal.toStringAsFixed(1)} N', Colors.green),
                _item(isStatic ? '静摩擦 f' : '滑动摩擦 f', '${frictionMag.toStringAsFixed(1)} N', Colors.orange),
                _item('外力 F', '${force.toStringAsFixed(1)} N', Colors.blue),
                const Spacer(),
                Text('速度: ${velocity.toStringAsFixed(2)} m/s', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(child: _slider('质量', mass, 0.5, 10, (v) => setState(() => mass = v))),
              Expanded(child: _slider('摩擦μ', mu, 0, 1, (v) => setState(() => mu = v))),
              Expanded(child: _slider('外力F', force, 0, 50, (v) => setState(() => force = v))),
            ]),
            ElevatedButton.icon(
              onPressed: running ? null : _run,
              icon: const Icon(Icons.play_arrow),
              label: Text(running ? '演示中…' : '运行实验（3秒）'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String n, String v, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Container(width: 10, height: 10, color: c),
      const SizedBox(width: 4),
      Expanded(child: Text('$n = $v', style: const TextStyle(fontSize: 11))),
    ]),
  );

  Widget _slider(String label, double v, double min, double max, ValueChanged<double> cb) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label ${v.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11)),
      Slider(value: v.clamp(min, max), min: min, max: max, onChanged: cb),
    ],
  );
}

class LabPainter extends CustomPainter {
  final double posX, mass, force, friction;
  final bool isStatic, running;
  LabPainter({required this.posX, required this.mass, required this.force, required this.friction, required this.isStatic, required this.running});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 12;
    final groundY = size.height * 0.85;
    final cx = posX * scale;
    final cy = groundY - 30;

    // 天空
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, groundY), Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, groundY)));

    // 地面
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY), Paint()..color = const Color(0xFF78716C));

    // 物块
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 40), Paint()..color = Colors.blue);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 40), Paint()..color = Colors.black54..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // 箭头缩放
    final maxMag = math.max(force.abs(), math.max(mass * 10, friction)) + 0.1;
    double len(double m) => 15 + (m / maxMag) * 60;

    // 重力
    _arrow(canvas, Offset(cx, cy + 20), const Offset(0, 1), len(mass * 10), Colors.purple);
    // 支持力
    _arrow(canvas, Offset(cx, cy + 20), const Offset(0, -1), len(mass * 10), Colors.green);
    // 摩擦力
    if (friction > 0.01) {
      final dir = isStatic ? -force.sign : -1.0;
      _arrow(canvas, Offset(cx, cy + 20), Offset(dir, 0), len(friction), Colors.orange);
    }
    // 外力
    if (force.abs() > 0.01) {
      _arrow(canvas, Offset(cx, cy - 20), Offset(force.sign, 0), len(force), Colors.blue);
    }
  }

  void _arrow(Canvas canvas, Offset from, Offset dir, double len, Color color) {
    final end = from + dir * len;
    final paint = Paint()..color = color..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(from, end, paint);
    final head = 8.0;
    final perp = Offset(-dir.dy, dir.dx);
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - dir.dx * head + perp.dx * head * 0.6, end.dy - dir.dy * head + perp.dy * head * 0.6)
      ..lineTo(end.dx - dir.dx * head - perp.dx * head * 0.6, end.dy - dir.dy * head - perp.dy * head * 0.6)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant LabPainter old) => true;
}
