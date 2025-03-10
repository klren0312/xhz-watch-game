import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:watchsteroids/game/game.dart';

class InitialOverlay extends StatefulWidget {
  const InitialOverlay({super.key});

  @override
  State<InitialOverlay> createState() => _InitialOverlayState();
}

class _InitialOverlayState extends State<InitialOverlay> {
  bool showingCredits = false;

  @override
  Widget build(BuildContext context) {
    final mainMenu = Column(
      children: [
        const Text('小黑子，点击开始练习'),
        const Spacer(),
        BlocBuilder<ScoreCubit, ScoreState>(
          builder: (context, state) {
            if (state.highScore == 0) {
              return const SizedBox.shrink();
            }

            return Text(
              '练习得分: ${state.highScore}',
              style: const TextStyle(
                color: Color(0xC0FBE294),
                fontSize: 10,
              ),
            );
          },
        ),
        const Text(
          '练习时长两年半',
          style: TextStyle(
            color: Color(0xC0FBE294),
            fontSize: 9,
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (showingCredits) {
          setState(() {
            showingCredits = false;
          });
          return;
        }
        final gameCubit = context.read<GameCubit>();
        if (gameCubit.isPlaying) {
          return;
        }
        context.read<GameCubit>().startGame();
      },
      onLongPress: () {
        setState(() {
          showingCredits = !showingCredits;
        });
      },
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              mainMenu,
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: showingCredits ? 1 : 0),
                duration: const Duration(milliseconds: 250),
                builder: (context, value, _) {
                  return CreditsOverlay(
                    progress: value,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreditsOverlay extends StatelessWidget {
  const CreditsOverlay({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(
        sigmaX: 10 * progress,
        sigmaY: 20 * progress,
      ),
      child: Opacity(
        opacity: progress,
        child: const Column(
          children: [
            Spacer(),
            Text(
              '制作： 治娱治乐',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                height: 1.5,
              ),
            ),
            Text(
              '治电ZCDC',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        final gameCubit = context.read<GameCubit>();
        if (gameCubit.state != GameState.gameOver) {
          return;
        }
        context.read<ScoreCubit>().reset();
        context.read<GameCubit>().setInitial();
      },
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              const Text(
                '浪费！再练两年半',
              ),
              BlocBuilder<ScoreCubit, ScoreState>(
                builder: (context, state) {
                  if (state.currentScore == 0) {
                    return const SizedBox.shrink();
                  }

                  return Text(
                    '得分: ${state.currentScore}',
                  );
                },
              ),
              const Spacer(),
              const Text(
                '点击继续啊',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScoreOverlay extends StatelessWidget {
  const ScoreOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScoreCubit, ScoreState>(
      builder: (context, state) {
        return SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  '${state.currentScore}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
