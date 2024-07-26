import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/animation.dart';
import 'package:watchsteroids/game/game.dart';

class ShipContainer extends PositionComponent
    with
        FlameBlocListenable<RotationCubit, RotationState>,
        HasGameRef<WatchsteroidsGame> {
  ShipContainer(this.gameCubit)
      : super(
          anchor: Anchor.center,
          position: Vector2.zero(),
          priority: 5,
        );

  final GameCubit gameCubit;
  late final side = 40.0;
  late final xhz = XhzSprite();
  @override
  Future<void> onLoad() async {
    await add(xhz);
    await xhz.add(ShipGlow());
    await xhz.add(Cannon());
    await xhz.add(
      CameraSpot(gameCubit)..position = Vector2(side / 2, side / 2 - 50),
    );
  }

  /// 开启新游戏
  @override
  void onNewState(RotationState state) {
    final from = xhz.angle;
    final to = state.shipAngle;

    final delta = (to - from).abs();

    xhz.effectController.duration = ((delta / math.pi) / 1.1) + 0.1;
    xhz.go(to: state.shipAngle);
  }

  /// 碰撞到急游戏结束
  void hitAsteroid(Set<Vector2> intersectionPoints) {
    gameCubit.gameOver();
    gameRef.flameMultiBlocProvider.add(
      AsteroidExplosion(position: absolutePositionOfAnchor(Anchor.center)),
    );
    gameRef.cameraSubject.go(to: intersectionPoints.first, calm: true);
  }
}

class XhzSprite extends SpriteComponent
  with
      HasGameRef<WatchsteroidsGame>,
      ParentIsA<ShipContainer>,
      CollisionCallbacks {
  XhzSprite({super.position}): super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite(
      'xhz.png',
      srcSize: Vector2(474, 474),
    );
    await add(rotateShipEffect);
    size = Vector2(parent.side, parent.side);
    await add(
      RectangleHitbox(
        size: size,
        anchor: Anchor.center,
        position: size / 2,
      ),
      // PolygonHitbox(
      //   isSolid: true,
      //   [
      //     Vector2(0, 0),
      //     Vector2(size.x, 0),
      //     Vector2(size.x, size.y),
      //     Vector2(0, size.y),
      //   ],
      // ),
    );
  }
  final effectController = CurvedEffectController(0.1, Curves.easeOutQuint)
    ..setToEnd();

  late final rotateShipEffect = RotateShipEffect(0, effectController);

  bool canShoot = true;

  void go({required double to}) {
    canShoot = false;
    rotateShipEffect
      ..go(to: to)
      ..onComplete = () {
        canShoot = true;
      };
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints,
      PositionComponent other,
      ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is AsteroidSprite) {
      parent.hitAsteroid(intersectionPoints);
    }
  }
}


class RotateShipEffect extends Effect with EffectTarget<PositionComponent> {
  RotateShipEffect(this._to, super.controller);

  @override
  void onMount() {
    super.onMount();
    _from = target.angle;
  }

  double _to;
  late double _from;

  void go({required double to}) {
    reset();
    _to = to;
    _from = target.angle;
  }

  @override
  void apply(double progress) {
    final delta = _to - _from;
    final angle = _from + delta * progress;
    target.angle = angle;
  }

  @override
  bool get removeOnFinish => false;
}

class ShipGlow extends SpriteComponent
    with
        HasGameRef<WatchsteroidsGame>,
        ParentIsA<XhzSprite>,
        FlameBlocListenable<GameCubit, GameState> {
  ShipGlow() : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    size = Vector2(270, 270) * 2.2;
    position = parent.size.clone()
      ..x *= 0.5
      ..y *= -0.9;
    opacity = 0.0;

    sprite = await gameRef.loadSprite('shipglow.png');

    angle = math.pi;
  }

  @override
  void onNewState(GameState state) {
    switch (state) {
      case GameState.playing:
        position.y = (parent.y / 2) - 20;
        opacity = 1.0;
      case GameState.initial:
        parent.parent.xhz.angle = 0;
        opacity = 0.0;
      case GameState.gameOver:
        position.y = parent.y / 2;
    }
  }
}

/// 相机跟随
class CameraSpot extends PositionComponent with HasGameRef<WatchsteroidsGame> {
  CameraSpot(this.gameCubit)
      : super(
          anchor: Anchor.center,
        );

  final timerInitial = 0.1;
  final GameCubit gameCubit;

  late double timer = timerInitial;

  @override
  void update(double dt) {
    if (!gameCubit.isPlaying) {
      return;
    }

    if (timer <= 0) {
      gameRef.cameraSubject.go(to: absolutePosition);
      timer = timerInitial;
    }
    timer -= dt;
  }
}
