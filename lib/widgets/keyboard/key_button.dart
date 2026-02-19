import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSpecial;
  final Color? backgroundColor;
  final double flex;
  final IconData? icon;

  const KeyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isSpecial = false,
    this.backgroundColor,
    this.flex = 1.0,
    this.icon,
  });

  @override
  State<KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<KeyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(PointerDownEvent _) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(PointerUpEvent _) {
    _handleRelease();
  }

  void _onTapCancel(PointerCancelEvent _) {
    _handleRelease();
  }

  void _handleRelease() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (widget.flex * 10).toInt(),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Listener(
          onPointerDown: _onTapDown,
          onPointerUp: _onTapUp,
          onPointerCancel: _onTapCancel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ??
                          (widget.isSpecial
                              ? const Color(0xFF30363D)
                              : const Color(0xFF161B22)),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        if (_isPressed)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                      ],
                    ),
                    child: widget.icon != null
                        ? Icon(widget.icon, color: Colors.white, size: 20)
                        : Text(
                            widget.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.isSpecial ? 14 : 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
