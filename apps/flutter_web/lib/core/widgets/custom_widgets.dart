import 'package:flutter/material.dart';
import '../theme/theme.dart';

class VianCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: VianTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF26262F), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0x11F5A623),
        highlightColor: const Color(0x08F5A623),
        child: cardContent,
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
              color: const Color(0xFF1E1E26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x15F5A623), width: 1),
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
            foregroundColor: color ?? VianTheme.primaryGold,
            side: BorderSide(color: color ?? VianTheme.primaryGold, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color ?? VianTheme.primaryGold,
            foregroundColor: textColor ?? VianTheme.headerBlack,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontSize: 12, color: VianTheme.lightText),
            ),
            Text(
              '$percent%',
              style: const TextStyle(fontSize: 12, color: VianTheme.primaryGold, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF1E1E26),
            valueColor: const AlwaysStoppedAnimation<Color>(VianTheme.primaryGold),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
