import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 强制横屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(primary: Colors.blueAccent),
      ),
      home: const LabPage(),
    );
  }
}

class LabPage extends StatefulWidget {
  const LabPage({super.key});
  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  double mass = 2.0;
  double mu = 0.3;
  double force = 10.0;
  double posX = 3.0;
  double velocity = 0.0;

  void runSim() {
    velocity = 0;
    posX = 3.0;
    for (int i = 0; i < 180; i++) {
      double dt = 1 / 60;
      double g = 10.0;
      double weight = mass * g;
      double fMax = mu * weight;
      double friction = 0;
      if (velocity.abs() < 0.01 && force.abs() <= fMax) {
        friction = -force;
      } else {
        friction = -velocity.sign * mu * weight;
      }
      double accel = (force + friction) / mass;
      velocity += accel * dt;
      posX += velocity * dt;
      if (posX < 0.5) { posX = 0.5; velocity = 0; }
      if (posX > 11.5) { posX = 11.5; velocity = 0; }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('力学实验室 · 深色版', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Row(
        children: [
          // 左侧：绘图区域
          Expanded(
            flex: 3,
            child: CustomPaint(
              painter: LabPainter(posX: posX, mass: mass, force: force, mu: mu, velocity: velocity),
              size: Size.infinite,
            ),
          ),
          // 右侧：数据面板和控制器
          Container(
            width: 260,
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('参数控制', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 10),
                _buildSlider('质量 (kg)', mass, 0.5, 10, (v) => setState(() => mass = v)),
                _buildSlider('摩擦系数 (μ)', mu, 0, 1, (v) => setState(() => mu = v)),
                _buildSlider('外力 (N)', force, 0, 50, (v) => setState(() => force = v)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: runSim,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('运行 3 秒演示'),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

class LabPainter extends CustomPainter {
  final double posX, mass, force, mu, velocity;
  LabPainter({required this.posX, required this.mass, required this.force, required this.mu, required this.velocity});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 12;
    final groundY = size.height * 0.8;
    final cx = posX * scale;
    final cy = groundY - 25;

    // 深色背景（暗夜天空）
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, groundY),
        Paint()..shader = const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, groundY))
    );

    // 深色地面
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY), Paint()..color = const Color(0xFF334155));
    // 地面网格线
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, groundY), Offset(i - 20, size.height), Paint()..color = const Color(0xFF1E293B)..strokeWidth = 2);
    }

    // 物块（带点光泽）
    final blockRect = Rect.fromCenter(center: Offset(cx, cy), width: 50, height: 50);
    canvas.drawRect(blockRect, Paint()..color = Colors.blueAccent);
    canvas.drawRect(blockRect, Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 2);

    double weight = mass * 10;
    double fMax = mu * weight;
    bool isStatic = velocity.abs() < 0.01 && force.abs() <= fMax;
    double fric = isStatic ? force.abs() : mu * weight;

    // 画受力箭头
    drawArrow(canvas, Offset(cx, cy), const Offset(0, 1), 40 + weight * 0.5, Colors.purpleAccent, 'G');
    drawArrow(canvas, Offset(cx, cy), const Offset(0, -1), 40 + weight * 0.5, Colors.greenAccent, 'N');
    
    if (force > 0) {
      drawArrow(canvas, Offset(cx, cy), const Offset(1, 0), 30 + force * 0.8, Colors.blue, 'F');
    }
    if (fric > 0) {
      drawArrow(canvas, Offset(cx, cy), const Offset(-1, 0), 30 + fric * 0.8, Colors.orangeAccent, 'f');
    }
  }

  void drawArrow(Canvas canvas, Offset from, Offset dir, double len, Color color, String label) {
    final end = from + dir * len;
    canvas.drawLine(from, end, Paint()..color = color..strokeWidth = 3);
    
    // 箭头三角形
    final p = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - dir.dx * 10 + dir.dy * 5, end.dy - dir.dy * 10 - dir.dx * 5)
      ..lineTo(end.dx - dir.dx * 10 - dir.dy * 5, end.dy - dir.dy * 10 + dir.dx * 5)
      ..close();
    canvas.drawPath(p, Paint()..color = color);

    // 箭头旁边的字母标签
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, end + dir * 5 - Offset(textPainter.width/2, textPainter.height/2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
