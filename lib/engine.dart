import 'dart:ui';
import 'dart:math' as math;

enum SceneType { horizontal, incline, water, hanging, pulley }
enum BlockShape { square, ball }

class BlockModel {
  String name;
  double mass;
  double size;
  double density;
  BlockShape shape;
  Color color;
  Offset position;
  double initialVelocity;

  BlockModel({
    required this.name,
    this.mass = 2,
    this.size = 1,
    this.density = 2000,
    this.shape = BlockShape.square,
    this.color = const Color(0xFF3B82F6),
    this.position = const Offset(4, 0.5),
    this.initialVelocity = 0,
  });

  BlockModel copy() => BlockModel(
        name: name, mass: mass, size: size, density: density,
        shape: shape, color: color, position: position,
        initialVelocity: initialVelocity,
      );

  double get volume => shape == BlockShape.square
      ? size * size * size
      : (4 / 3) * math.pi * (size / 2) * (size / 2) * (size / 2);
}

class SceneModel {
  SceneType type;
  double inclineAngle;
  double staticFriction;
  double dynamicFriction;
  double liquidDensity;
  double gravity;
  bool showComponents;
  bool showValues;
  bool hasWall;
  double wallX;
  double externalForce;

  SceneModel({
    this.type = SceneType.horizontal,
    this.inclineAngle = 30,
    this.staticFriction = 0.4,
    this.dynamicFriction = 0.3,
    this.liquidDensity = 1000,
    this.gravity = 10,
    this.showComponents = false,
    this.showValues = true,
    this.hasWall = false,
    this.wallX = 10,
    this.externalForce = 0,
  });

  SceneModel copy() => SceneModel(
        type: type, inclineAngle: inclineAngle,
        staticFriction: staticFriction, dynamicFriction: dynamicFriction,
        liquidDensity: liquidDensity, gravity: gravity,
        showComponents: showComponents, showValues: showValues,
        hasWall: hasWall, wallX: wallX,
        externalForce: externalForce,
      );
}

class TemplateModel {
  final String title;
  final String description;
  final SceneModel Function() scene;
  final List<BlockModel> Function() blocks;

  TemplateModel({
    required this.title,
    required this.description,
    required this.scene,
    required this.blocks,
  });
}

class ForceInfo {
  final String name;
  final double magnitude;
  final Offset direction;
  final Color color;

  ForceInfo(this.name, this.magnitude, this.direction, this.color);
}

class BlockResult {
  final BlockModel block;
  final List<ForceInfo> forces;
  final Offset acceleration;
  final String state;
  final String derivation;

  BlockResult({
    required this.block,
    required this.forces,
    required this.acceleration,
    required this.state,
    required this.derivation,
  });
}

String f1(double v) => v.toStringAsFixed(1);

final List<TemplateModel> kTemplates = [
  TemplateModel(
    title: '水平面加速滑动',
    description: '质量 2kg 的物块在粗糙水平面上，μ=0.3，用 10N 水平力拉动，求受力与加速度。',
    scene: () => SceneModel(type: SceneType.horizontal, staticFriction: 0.4, dynamicFriction: 0.3, externalForce: 10),
    blocks: () => [BlockModel(name: '物块A', mass: 2, size: 1, position: const Offset(3, 0.5))],
  ),
  TemplateModel(
    title: '墙面靠物块',
    description: '质量 2kg 的物块被 20N 水平力压在竖直墙面上，μs=0.4, μk=0.3，判断运动状态。',
    scene: () => SceneModel(type: SceneType.horizontal, hasWall: true, wallX: 8, staticFriction: 0.4, dynamicFriction: 0.3, externalForce: 20),
    blocks: () => [BlockModel(name: '物块A', mass: 2, size: 1, position: const Offset(7.5, 1.5))],
  ),
  TemplateModel(
    title: '两物块叠放运动',
    description: 'A(3kg)叠在B(2kg)上，用 10N 推B。地面μ=0.1，AB间μ=0.5，判断是否一起运动。',
    scene: () => SceneModel(type: SceneType.horizontal, staticFriction: 0.5, dynamicFriction: 0.1, externalForce: 10),
    blocks: () => [
      BlockModel(name: '物块A', mass: 3, size: 1, position: const Offset(4, 1.5), color: const Color(0xFFF59E0B)),
      BlockModel(name: '物块B', mass: 2, size: 1.2, position: const Offset(4, 0.6), color: const Color(0xFF3B82F6)),
    ],
  ),
  TemplateModel(
    title: '斜面加速下滑',
    description: '质量 2kg 的物块从 30° 粗糙斜面下滑，μ=0.2，求支持力、摩擦力与加速度。',
    scene: () => SceneModel(type: SceneType.incline, inclineAngle: 30, staticFriction: 0.2, dynamicFriction: 0.2),
    blocks: () => [BlockModel(name: '物块A', mass: 2, size: 1, position: const Offset(4, 2.5))],
  ),
  TemplateModel(
    title: '斜面静止（静摩擦）',
    description: '质量 2kg 的物块放在 30° 粗糙斜面上，μs=0.8，判断是否静止。',
    scene: () => SceneModel(type: SceneType.incline, inclineAngle: 30, staticFriction: 0.8, dynamicFriction: 0.5),
    blocks: () => [BlockModel(name: '物块A', mass: 2, size: 1, position: const Offset(5, 1))],
  ),
  TemplateModel(
    title: '测力计悬挂物块',
    description: '质量 2kg 的物块挂在测力计下静止，求测力计读数。',
    scene: () => SceneModel(type: SceneType.hanging, gravity: 10),
    blocks: () => [BlockModel(name: '物块A', mass: 2, size: 1, position: const Offset(5, 2))],
  ),
  TemplateModel(
    title: '定滑轮连接两物块',
    description: 'A(3kg)在水平桌面，通过定滑轮与悬挂的B(2kg)相连，桌面μ=0.2，求加速度和张力。',
    scene: () => SceneModel(type: SceneType.pulley, dynamicFriction: 0.2, staticFriction: 0.2),
    blocks: () => [
      BlockModel(name: '物块A', mass: 3, size: 1, position: const Offset(4, 0.5)),
      BlockModel(name: '物块B', mass: 2, size: 1, position: const Offset(9, 2), color: const Color(0xFFF59E0B)),
    ],
  ),
  TemplateModel(
    title: '水中物块漂浮',
    description: '边长 1m、质量 500kg 的立方体放入水中，判断状态并求浮力。',
    scene: () => SceneModel(type: SceneType.water, liquidDensity: 1000),
    blocks: () => [BlockModel(name: '物块A', mass: 500, size: 1, density: 500, position: const Offset(5, 2))],
  ),
  TemplateModel(
    title: '水中物块沉底',
    description: '边长 1m、质量 2000kg 的立方体放入水中，求浮力和底部支持力。',
    scene: () => SceneModel(type: SceneType.water, liquidDensity: 1000),
    blocks: () => [BlockModel(name: '物块A', mass: 2000, size: 1, density: 2000, position: const Offset(5, 1))],
  ),
  TemplateModel(
    title: '粗糙面减速停止',
    description: '质量 2kg 的物块以 6m/s 初速度在粗糙水平面滑行，μ=0.3，求多久停下。',
    scene: () => SceneModel(type: SceneType.horizontal, staticFriction: 0.3, dynamicFriction: 0.3, externalForce: 0),
    blocks: () => [BlockModel(name: '物块A', mass: 2, size: 1, position: const Offset(2, 0.5), initialVelocity: 6)],
  ),
];

class PhysicsEngine {
  final SceneModel scene;
  PhysicsEngine(this.scene);
  double get g => scene.gravity;

  List<BlockResult> computeAll(List<BlockModel> blocks, List<Offset> velocities) {
    switch (scene.type) {
      case SceneType.horizontal: return _horizontal(blocks, velocities);
      case SceneType.incline: return [_incline(blocks.first, velocities.first)];
      case SceneType.water: return [_water(blocks.first)];
      case SceneType.hanging: return [_hanging(blocks.first)];
      case SceneType.pulley: return _pulley(blocks);
    }
  }

  List<BlockResult> _horizontal(List<BlockModel> blocks, List<Offset> vels) {
    final results = <BlockResult>[];
    final isStack = blocks.length == 2;
    
    if (isStack) {
      final top = blocks[0];
      final bottom = blocks[1];
      final mT = top.mass, mB = bottom.mass;
      final fExt = scene.externalForce;
      final nGround = (mT + mB) * g;
      final fMaxGround = scene.staticFriction * nGround;
      final fKGround = scene.dynamicFriction * nGround;
      
      bool together = false;
      double a = 0;
      double fBetween = 0;
      
      if (fExt.abs() <= fMaxGround && vels[1].dx.abs() < 1e-4) {
        together = true;
      } else {
        a = (fExt - fExt.sign * fKGround) / (mT + mB);
        fBetween = mT * a;
        final fMaxBetween = scene.staticFriction * mT * g;
        if (fBetween.abs() <= fMaxBetween) together = true;
      }

      if (together) {
        results.add(BlockResult(
          block: top, acceleration: const Offset(0, 0),
          forces: [
            ForceInfo('重力 G', mT * g, const Offset(0, -1), Colors.purple),
            ForceInfo('支持力 N₁', mT * g, const Offset(0, 1), Colors.green),
            ForceInfo('静摩擦 f₁', fBetween.abs(), Offset(fBetween.sign, 0), Colors.orange),
          ],
          state: '随下物块一起运动',
          derivation: '整体：F−μ地(m₁+m₂)g=(m₁+m₂)a\na=($fExt−${f1(fKGround)})/${mT+mB}=${f1(a)}m/s²\nA所需摩擦 f₁=m₁a=${f1(fBetween.abs())}N ≤ μ间m₁g=${f1(scene.staticFriction * mT * g)}N，故一起运动。',
        ));
        final fBottom = fExt - fBetween;
        results.add(BlockResult(
          block: bottom, acceleration: Offset(a, 0),
          forces: [
            ForceInfo('重力 G', mB * g, const Offset(0, -1), Colors.purple),
            ForceInfo('支持力 N地', nGround, const Offset(0, 1), Colors.green),
            ForceInfo('A对B压力', mT * g, const Offset(0, -1), Colors.teal),
            ForceInfo('A对B摩擦', fBetween.abs(), Offset(-fBetween.sign, 0), Colors.orange),
            ForceInfo('滑动摩擦 f地', fKGround, Offset(-fExt.sign, 0), Colors.red),
          ],
          state: '整体加速',
          derivation: 'B受力：F − f₁ − f地 = m₂a\nf地=${f1(fKGround)}N\na=($fExt−${f1(fBetween.abs())}−${f1(fKGround)})/$mB=${f1(a)}m/s²',
        ));
      } else {
        results.add(BlockResult(
          block: top, acceleration: Offset(0, 0),
          forces: [
            ForceInfo('重力 G', mT * g, const Offset(0, -1), Colors.purple),
            ForceInfo('支持力 N₁', mT * g, const Offset(0, 1), Colors.green),
            ForceInfo('滑动摩擦 f₁', scene.dynamicFriction * mT * g, Offset(fExt.sign, 0), Colors.orange),
          ],
          state: 'A相对B打滑',
          derivation: '所需摩擦超过最大静摩擦，A相对B滑动。',
        ));
        results.add(BlockResult(
          block: bottom, acceleration: Offset((fExt - scene.dynamicFriction * mT * g - fExt.sign * fKGround) / mB, 0),
          forces: [
            ForceInfo('重力 G', mB * g, const Offset(0, -1), Colors.purple),
            ForceInfo('支持力 N地', nGround, const Offset(0, 1), Colors.green),
            ForceInfo('滑动摩擦 f地', fKGround, Offset(-fExt.sign, 0), Colors.red),
            ForceInfo('A对B摩擦 f₁', scene.dynamicFriction * mT * g, Offset(-fExt.sign, 0), Colors.orange),
          ],
          state: 'B加速，A打滑',
          derivation: 'B：F−f₁−f地=m₂a，f₁=μ间m₁g。',
        ));
      }
      return results;
    }

    final b = blocks.first;
    final v = vels.first;
    final weight = b.mass * g;
    final forces = <ForceInfo>[];
    forces.add(ForceInfo('重力 G', weight, const Offset(0, -1), Colors.purple));

    double normal = weight;
    double wallFriction = 0;
    
    if (scene.hasWall && b.position.dx + b.size / 2 >= scene.wallX - 0.05) {
      final wallNormal = scene.externalForce;
      normal = wallNormal;
      final fMaxWall = scene.staticFriction * wallNormal;
      final fKWall = scene.dynamicFriction * wallNormal;
      forces.add(ForceInfo('墙支持力', wallNormal, const Offset(-1, 0), Colors.green));
      
      if (weight <= fMaxWall) {
        forces.add(ForceInfo('墙静摩擦', weight, const Offset(0, 1), Colors.orange));
        return BlockResult(
          block: b, forces: forces, acceleration: const Offset(0, 0),
          state: '静止在墙面',
          derivation: 'N=${f1(wallNormal)}N，fmax=μsN=${f1(fMaxWall)}N。\nG=${f1(weight)}N ≤ fmax，静止，f=G=${f1(weight)}N。',
        );
      } else {
        forces.add(ForceInfo('墙滑动摩擦', fKWall, const Offset(0, 1), Colors.orange));
        return BlockResult(
          block: b, forces: forces, acceleration: Offset(0, (weight - fKWall) / b.mass),
          state: '沿墙下滑',
          derivation: 'G=${f1(weight)}N > fmax=${f1(fMaxWall)}N，下滑。\nf=μkN=${f1(fKWall)}N。\na=(G−f)/m=${f1((weight - fKWall) / b.mass)}m/s²。',
        );
      }
    }

    final fMax = scene.staticFriction * normal;
    final fK = scene.dynamicFriction * normal;
    final fExt = scene.externalForce;

    if (v.dx.abs() < 1e-4 && fExt.abs() <= fMax) {
      forces.add(ForceInfo('支持力 N', normal, const Offset(0, 1), Colors.green));
      if (fExt != 0) {
        forces.add(ForceInfo('静摩擦 f', fExt.abs(), Offset(-fExt.sign, 0), Colors.orange));
        forces.add(ForceInfo('外力 F', fExt.abs(), Offset(fExt.sign, 0), Colors.blue));
      }
      return BlockResult(
        block: b, forces: forces, acceleration: const Offset(0, 0), state: '静止',
        derivation: 'fmax=${f1(fMax)}N\n${fExt == 0 ? '无外力' : 'F=${f1(fExt.abs())}N ≤ fmax'}，物块静止，f=${f1(fExt.abs())}N。',
      );
    }

    final dir = v.dx.abs() > 1e-4 ? v.dx.sign : fExt.sign;
    final friction = -dir * fK;
    final a = (fExt + friction) / b.mass;
    forces.add(ForceInfo('支持力 N', normal, const Offset(0, 1), Colors.green));
    forces.add(ForceInfo('滑动摩擦 f', fK, Offset(friction.sign, 0), Colors.red));
    if (fExt != 0) forces.add(ForceInfo('外力 F', fExt.abs(), Offset(fExt.sign, 0), Colors.blue));
    
    return BlockResult(
      block: b, forces: forces, acceleration: Offset(a, 0),
      state: a.abs() < 1e-3 ? '匀速滑动' : (a * dir > 0 ? '加速滑动' : '减速滑动'),
      derivation: '滑动摩擦 f=μkN=${f1(fK)}N\n合力=${f1(fExt)}+(${f1(friction)})=${f1(fExt + friction)}N\na=合力/m=${f1(a)}m/s²',
    );
  }

  BlockResult _incline(BlockModel b, Offset v) {
    final theta = scene.inclineAngle * math.pi / 180;
    final weight = b.mass * g;
    final n = weight * math.cos(theta);
    final gAlong = weight * math.sin(theta);
    final fMax = scene.staticFriction * n;
    final fK = scene.dynamicFriction * n;
    final forces = <ForceInfo>[
      ForceInfo('重力 G', weight, const Offset(0, -1), Colors.purple),
      ForceInfo('支持力 N', n, const Offset(-math.sin(theta), math.cos(theta)), Colors.green),
    ];
    
    if (scene.showComponents) {
      forces.add(ForceInfo('G沿斜面', gAlong, const Offset(math.cos(theta), -math.sin(theta)), Colors.purple.shade300));
      forces.add(ForceInfo('G垂直', weight * math.cos(theta), const Offset(-math.sin(theta), -math.cos(theta)), Colors.purple.shade300));
    }
    
    if (gAlong <= fMax && v.dx.abs() < 1e-4) {
      forces.add(ForceInfo('静摩擦 f', gAlong, const Offset(-math.cos(theta), math.sin(theta)), Colors.orange));
      return BlockResult(
        block: b, forces: forces, acceleration: const Offset(0, 0), state: '静止在斜面',
        derivation: 'G∥=mgsinθ=${f1(gAlong)}N\nfmax=μsN=${f1(fMax)}N\nG∥ ≤ fmax，静止。f=G∥=${f1(gAlong)}N。',
      );
    }
    final a = g * (math.sin(theta) - scene.dynamicFriction * math.cos(theta));
    forces.add(ForceInfo('滑动摩擦 f', fK, const Offset(-math.cos(theta), math.sin(theta)), Colors.red));
    return BlockResult(
      block: b, forces: forces, acceleration: Offset(a, 0), state: a > 0 ? '加速下滑' : '减速',
      derivation: 'G∥=${f1(gAlong)}N > fmax=${f1(fMax)}N，下滑。\nf=μkN=${f1(fK)}N\na=g(sinθ−μcosθ)=${f1(a)}m/s²',
    );
  }

  BlockResult _water(BlockModel b) {
    final weight = b.mass * g;
    final volume = b.volume;
    final densityBlock = b.mass / volume;
    final forces = <ForceInfo>[ForceInfo('重力 G', weight, const Offset(0, -1), Colors.purple)];
    
    if (densityBlock < scene.liquidDensity) {
      forces.add(ForceInfo('浮力 F浮', weight, const Offset(0, 1), Colors.cyan));
      return BlockResult(
        block: b, forces: forces, acceleration: const Offset(0, 0), state: '漂浮',
        derivation: 'ρ物=${f1(densityBlock)} < ρ液=${scene.liquidDensity}，漂浮。\nF浮=G=${f1(weight)}N。',
      );
    } else if (densityBlock == scene.liquidDensity) {
      forces.add(ForceInfo('浮力 F浮', weight, const Offset(0, 1), Colors.cyan));
      return BlockResult(
        block: b, forces: forces, acceleration: const Offset(0, 0), state: '悬浮',
        derivation: 'ρ物=ρ液，完全浸没且悬浮，F浮=G=${f1(weight)}N。',
      );
    } else {
      final buoyancy = scene.liquidDensity * g * volume;
      final n = weight - buoyancy;
      forces.add(ForceInfo('浮力 F浮', buoyancy, const Offset(0, 1), Colors.cyan));
      forces.add(ForceInfo('支持力 N', n, const Offset(0, 1), Colors.green));
      return BlockResult(
        block: b, forces: forces, acceleration: const Offset(0, 0), state: '沉底',
        derivation: 'ρ物 > ρ液，沉底。\nF浮=${f1(buoyancy)}N\n支持力 N=G−F浮=${f1(n)}N。',
      );
    }
  }

  BlockResult _hanging(BlockModel b) {
    final weight = b.mass * g;
    return BlockResult(
      block: b, acceleration: const Offset(0, 0), state: '静止悬挂',
      forces: [
        ForceInfo('重力 G', weight, const Offset(0, -1), Colors.purple),
        ForceInfo('拉力 T', weight, const Offset(0, 1), Colors.blue),
      ],
      derivation: '二力平衡：T=G=mg=${f1(weight)}N。',
    );
  }

  List<BlockResult> _pulley(List<BlockModel> blocks) {
    final aB = blocks[0];
    final bB = blocks[1];
    final mA = aB.mass, mB = bB.mass;
    final n = mA * g;
    final fMax = scene.staticFriction * n;
    final fK = scene.dynamicFriction * n;
    final driving = mB * g;
    
    if (driving <= fMax) {
      return [
        BlockResult(block: aB, acceleration: const Offset(0, 0), state: '静止',
          forces: [
            ForceInfo('重力 G', mA * g, const Offset(0, -1), Colors.purple),
            ForceInfo('支持力 N', n, const Offset(0, 1), Colors.green),
            ForceInfo('绳张力 T', driving, const Offset(1, 0), Colors.blue),
            ForceInfo('静摩擦 f', driving, const Offset(-1, 0), Colors.orange),
          ],
          derivation: 'T=mBg=${f1(driving)}N，fmax=${f1(fMax)}N。T≤fmax，系统静止。'),
        BlockResult(block: bB, acceleration: const Offset(0, 0), state: '静止',
          forces: [
            ForceInfo('重力 G', mB * g, const Offset(0, -1), Colors.purple),
            ForceInfo('绳张力 T', driving, const Offset(0, 1), Colors.blue),
          ],
          derivation: '二力平衡：T=mBg=${f1(driving)}N。'),
      ];
    }
    
    final a = (driving - fK) / (mA + mB);
    final t = mA * a + fK;
    return [
      BlockResult(block: aB, acceleration: Offset(a, 0), state: '向右加速',
        forces: [
          ForceInfo('重力 G', mA * g, const Offset(0, -1), Colors.purple),
          ForceInfo('支持力 N', n, const Offset(0, 1), Colors.green),
          ForceInfo('绳张力 T', t, const Offset(1, 0), Colors.blue),
          ForceInfo('滑动摩擦 f', fK, const Offset(-1, 0), Colors.red),
        ],
        derivation: 'a=(mBg−μkN)/(mA+mB)=(${f1(driving)}−${f1(fK)})/${mA+mB}=${f1(a)}m/s²\nT=mAa+f=${f1(t)}N'),
      BlockResult(block: bB, acceleration: Offset(0, -a), state: '向下加速',
        forces: [
          ForceInfo('重力 G', mB * g, const Offset(0, -1), Colors.purple),
          ForceInfo('绳张力 T', t, const Offset(0, 1), Colors.blue),
        ],
        derivation: 'mBg−T=mBa\nT=mBg−mBa=${f1(t)}N'),
    ];
  }
}
