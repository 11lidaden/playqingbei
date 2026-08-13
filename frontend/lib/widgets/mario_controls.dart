import 'package:flutter/material.dart';

/// 玛丽游戏虚拟按键：左侧 ◀ ▶ 方向键 + 右侧 🦘 跳跃键
///
/// 通过回调通知游戏：onLeftDown/onLeftUp/onRightDown/onRightUp/onJump
/// 使用 Listener 接收指针事件（不参与手势 arena，100% 触发）
class MarioControls extends StatelessWidget {
  final VoidCallback onLeftDown;
  final VoidCallback onLeftUp;
  final VoidCallback onRightDown;
  final VoidCallback onRightUp;
  final VoidCallback onJump;

  const MarioControls({
    super.key,
    required this.onLeftDown,
    required this.onLeftUp,
    required this.onRightDown,
    required this.onRightUp,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // 左侧方向键
          Positioned(
            left: 20,
            bottom: 20,
            child: Row(
              children: [
                _ControlButton(
                  emoji: '◀',
                  onDown: onLeftDown,
                  onUp: onLeftUp,
                ),
                const SizedBox(width: 16),
                _ControlButton(
                  emoji: '▶',
                  onDown: onRightDown,
                  onUp: onRightUp,
                ),
              ],
            ),
          ),
          // 右侧跳跃键
          Positioned(
            right: 24,
            bottom: 20,
            child: _ControlButton(
              emoji: '🦘',
              size: 84,
              onDown: onJump,
              onUp: () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个按键：按下/抬起回调
class _ControlButton extends StatelessWidget {
  final String emoji;
  final double size;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _ControlButton({
    required this.emoji,
    required this.onDown,
    required this.onUp,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: size * 0.45),
          ),
        ),
      ),
    );
  }
}
