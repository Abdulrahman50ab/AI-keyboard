import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class KeyboardKey extends StatefulWidget {
  final String label;
  final String? sublabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int flex;
  final Color backgroundColor;
  final Color textColor;

  const KeyboardKey({
    super.key,
    required this.label,
    this.sublabel,
    required this.onTap,
    this.onLongPress,
    this.flex = 1,
    this.backgroundColor = const Color(0xFF3C4043),
    this.textColor = Colors.white,
  });

  @override
  State<KeyboardKey> createState() => _KeyboardKeyState();
}

class _KeyboardKeyState extends State<KeyboardKey> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
    _hidePopup();
    _controller.dispose();
    super.dispose();
  }

  void _showPopup() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 65,
        height: 90,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-10, -85), 
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: 60,
                height: 85,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B1E).withOpacity(0.98),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 34,
                        color: widget.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 4,
                      width: 20,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hidePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onTapDown(PointerDownEvent _) {
    setState(() => _isPressed = true);
    _controller.forward();
    _showPopup();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(PointerUpEvent _) {
    _handleRelease();
  }

  void _onTapCancel(PointerCancelEvent _) {
    _handleRelease();
  }

  void _handleRelease() {
    if (!mounted) return;
    setState(() => _isPressed = false);
    _controller.reverse();
    // Keep popup visible for a tiny bit longer to ensure it's seen on fast taps
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && !_isPressed) {
        _hidePopup();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.flex,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Listener(
          onPointerDown: _onTapDown,
          onPointerUp: _onTapUp,
          onPointerCancel: _onTapCancel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _isPressed 
                          ? widget.backgroundColor.withOpacity(0.85)
                          : widget.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        if (_isPressed)
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        BoxShadow(
                          color: Colors.black.withOpacity(_isPressed ? 0.4 : 0.2),
                          blurRadius: _isPressed ? 2 : 1,
                          offset: Offset(0, _isPressed ? 0.5 : 1),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        if (widget.sublabel != null)
                          Positioned(
                            top: 2,
                            right: 4,
                            child: Text(
                              widget.sublabel!,
                              style: TextStyle(
                                fontSize: 10, 
                                color: widget.textColor.withOpacity(0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Center(
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 24,
                              color: widget.textColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
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

class SpecialKey extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final int flex;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool autoRepeat;

  const SpecialKey({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.onLongPress,
    this.flex = 1,
    this.backgroundColor,
    this.iconColor,
    this.autoRepeat = false,
  });

  @override
  State<SpecialKey> createState() => _SpecialKeyState();
}

class _SpecialKeyState extends State<SpecialKey> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  Timer? _repeatTimer;
  Timer? _initialDelayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 60));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _initialDelayTimer?.cancel();
    _repeatTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(PointerDownEvent _) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
    
    // Start repeat logic if enabled
    if (widget.autoRepeat) {
      _initialDelayTimer = Timer(const Duration(milliseconds: 400), () {
        _repeatTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
          widget.onPressed();
          HapticFeedback.lightImpact();
        });
      });
    }
  }

  void _onTapUp(PointerUpEvent _) {
    _handleRelease();
  }

  void _onTapCancel(PointerCancelEvent _) {
    _handleRelease();
  }

  void _handleRelease() {
    if (!mounted) return;
    setState(() => _isPressed = false);
    _controller.reverse();
    _initialDelayTimer?.cancel();
    _repeatTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? const Color(0xFF3C4043).withOpacity(0.5);
    
    return Expanded(
      flex: widget.flex,
      child: Listener(
        onPointerDown: _onTapDown,
        onPointerUp: _onTapUp,
        onPointerCancel: _onTapCancel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  height: 46,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _isPressed ? bgColor.withOpacity(0.7) : bgColor,
                    borderRadius: BorderRadius.circular(widget.backgroundColor != null ? 27 : 8),
                    boxShadow: [
                      if (_isPressed)
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Center(
                    child: widget.icon != null
                        ? Icon(widget.icon, size: 22, color: widget.iconColor ?? Colors.white)
                        : Text(
                            widget.label!,
                            style: TextStyle(
                              fontSize: widget.label!.length > 3 ? 15 : 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
