import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlowingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool enabled;

  const GlowingButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.4 * _glowController.value),
                blurRadius: 20 * _glowController.value,
                offset: Offset(0, 8 * _glowController.value),
                spreadRadius: 4 * _glowController.value,
              ),
            ],
          ),
          child: FilledButton(
            onPressed: widget.enabled
                ? () {
                    if (!_isPressed) {
                      _isPressed = true;
                      _glowController.forward().then((_) {
                        if (mounted) {
                          setState(() => _isPressed = false);
                          _glowController.reverse();
                        }
                      });
                    }
                    widget.onPressed();
                  }
                : null,
            child: Opacity(
              opacity: 1.0 - (0.2 * _glowController.value),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
