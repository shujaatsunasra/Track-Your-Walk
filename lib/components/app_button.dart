import 'package:flutter/material.dart';
import '../theme/global_theme.dart';

enum AppButtonType { primary, secondary, ghost }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.padding,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.padding,
  }) : type = AppButtonType.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.padding,
  }) : type = AppButtonType.secondary;

  const AppButton.ghost({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.padding,
  }) : type = AppButtonType.ghost;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? _onTapDown
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading ? _onTapUp : null,
      onTapCancel: widget.onPressed != null && !widget.isLoading
          ? _onTapCancel
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              padding:
                  widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                gradient: _getGradient(),
                borderRadius: BorderRadius.circular(16),
                border: _getBorder(),
                boxShadow: _getBoxShadow(),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: _getTextColor(), size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _getTextColor(),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Color? _getBackgroundColor() {
    switch (widget.type) {
      case AppButtonType.primary:
        return null; // Use gradient
      case AppButtonType.secondary:
        return GlobalTheme.surfaceCard;
      case AppButtonType.ghost:
        return Colors.transparent;
    }
  }

  Gradient? _getGradient() {
    switch (widget.type) {
      case AppButtonType.primary:
        return const LinearGradient(
          colors: [GlobalTheme.primaryNeon, Color(0xFFB8E830)],
        );
      case AppButtonType.secondary:
      case AppButtonType.ghost:
        return null;
    }
  }

  Border? _getBorder() {
    switch (widget.type) {
      case AppButtonType.primary:
      case AppButtonType.secondary:
        return null;
      case AppButtonType.ghost:
        return Border.all(color: GlobalTheme.surfaceCard, width: 1);
    }
  }

  List<BoxShadow>? _getBoxShadow() {
    switch (widget.type) {
      case AppButtonType.primary:
        return [
          BoxShadow(
            color: GlobalTheme.primaryNeon.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: GlobalTheme.primaryNeon.withOpacity(0.2 * _glowAnimation.value),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ];
      case AppButtonType.secondary:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      case AppButtonType.ghost:
        return null;
    }
  }

  Color _getTextColor() {
    switch (widget.type) {
      case AppButtonType.primary:
        return Colors.black;
      case AppButtonType.secondary:
      case AppButtonType.ghost:
        return GlobalTheme.textPrimary;
    }
  }
}
