import 'package:flutter/material.dart';
import '../theme/theme.dart';

class VianCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const VianCard({
    Key? key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
  }) : super(key: key);

  @override
  State<VianCard> createState() => _VianCardState();
}

class _VianCardState extends State<VianCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget cardContent = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: VianTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? VianTheme.primaryGold.withOpacity(0.4) : VianTheme.goldBorder,
            width: 1.0,
          ),
          gradient: _isHovered
              ? const LinearGradient(
                  colors: [Colors.white, Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: _isHovered 
                  ? Colors.black.withOpacity(0.06) 
                  : Colors.black.withOpacity(0.02),
              blurRadius: _isHovered ? 20 : 12,
              offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
            )
          ],
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedOpacity(
            opacity: _isPressed ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}

class VianMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;

  const VianMetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VianCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Slate-100 container for icon
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
            ),
            child: Icon(icon, color: iconColor ?? VianTheme.primaryGold, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: VianTheme.lightText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: VianTheme.whiteText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: VianTheme.primaryGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VianButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;
  final Color? color;
  final Color? textColor;

  const VianButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.color,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = isSecondary
        ? OutlinedButton.styleFrom(
            foregroundColor: color ?? VianTheme.headerBlack,
            side: BorderSide(color: color ?? VianTheme.headerBlack, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color ?? VianTheme.headerBlack,
            foregroundColor: textColor ?? Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(text),
      ],
    );

    if (isSecondary) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }
}

class VianProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const VianProgressIndicator({
    Key? key,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();
    final Color progressColor;
    if (percent >= 90) {
      progressColor = VianTheme.success;
    } else if (percent >= 60) {
      progressColor = VianTheme.warning;
    } else {
      progressColor = VianTheme.danger;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontSize: 11, color: VianTheme.lightText),
            ),
            Text(
              '$percent%',
              style: TextStyle(fontSize: 12, color: progressColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
