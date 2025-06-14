import 'package:flutter/material.dart';
import 'dart:math';

/// A circular progress indicator that animates smoothly between progress values
class SmoothCircularProgress extends StatefulWidget {
  /// Current progress value (0.0 to 1.0)
  final double? value;
  
  /// Color of the progress indicator
  final Color? color;
  
  /// Background color of the progress track
  final Color? backgroundColor;
  
  /// Thickness of the progress indicator stroke
  final double strokeWidth;
  
  /// Whether to show a pulsing animation effect
  final bool pulsing;
  
  /// Duration for the progress animation
  final Duration animationDuration;
  
  const SmoothCircularProgress({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 4.0,
    this.pulsing = true,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<SmoothCircularProgress> createState() => _SmoothCircularProgressState();
}

class _SmoothCircularProgressState extends State<SmoothCircularProgress> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double _previousValue = 0.0;
  double _currentValue = 0.0;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    if (widget.value != null) {
      _currentValue = widget.value!;
    }
  }
    @override
  void didUpdateWidget(SmoothCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != null) {
      _previousValue = _currentValue;
      _currentValue = widget.value!;
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    final Color progressColor = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = widget.pulsing && widget.value != null
            ? 0.95 + (_pulseController.value * 0.1) // Pulse between 95% and 105%
            : 1.0;
        
        // Wave effect for progress color
        final waveColor = widget.pulsing && widget.value != null
            ? HSVColor.fromColor(progressColor)
                .withSaturation(min(1.0, HSVColor.fromColor(progressColor).saturation + (0.15 * _pulseController.value)))
                .withValue(min(1.0, HSVColor.fromColor(progressColor).value + (0.1 * sin(_pulseController.value * 3.14))))
                .toColor()
            : progressColor;
            
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,            boxShadow: widget.pulsing && widget.value != null ? [
              BoxShadow(
                color: progressColor.withAlpha(((0.3 * _pulseController.value) * 255).round()),
                blurRadius: 12 * _pulseController.value,
                spreadRadius: 2 * _pulseController.value,
              ),
            ] : null,
          ),
          child: SizedBox(
            width: 48 * pulseValue,
            height: 48 * pulseValue,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: _previousValue, end: _currentValue),
              duration: widget.animationDuration,
              curve: Curves.easeInOut,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: widget.value != null ? value : null,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: widget.backgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(waveColor),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// A widget that displays a percentage value with animation
class AnimatedPercentageText extends StatelessWidget {
  /// The percentage value to display
  final double percentage;
  
  /// Style for the text
  final TextStyle? style;
  
  /// Whether to include the % symbol
  final bool includeSymbol;
  
  /// Animation duration
  final Duration animationDuration;
  
  const AnimatedPercentageText({
    super.key,
    required this.percentage,
    this.style,
    this.includeSymbol = true,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: percentage),
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          includeSymbol ? '${value.round()}%' : '${value.round()}',
          style: style ?? const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
      },
    );
  }
}
