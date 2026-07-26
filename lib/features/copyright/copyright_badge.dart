import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/media_asset.dart';

class CopyrightBadge extends StatelessWidget {
  const CopyrightBadge({super.key, required this.status, this.compact = false});

  final CopyrightStatus status;
  final bool compact;

  Color get _color => switch (status) {
        CopyrightStatus.restricted => AppColors.copyrightRed,
        CopyrightStatus.caution => AppColors.copyrightYellow,
        CopyrightStatus.clear => AppColors.copyrightGreen,
      };

  String get _emoji => switch (status) {
        CopyrightStatus.restricted => '🔴',
        CopyrightStatus.caution => '🟡',
        CopyrightStatus.clear => '🟢',
      };

  @override
  Widget build(BuildContext context) {
    final fg = status == CopyrightStatus.caution
        ? AppColors.onAccent
        : Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_emoji, style: TextStyle(fontSize: compact ? 11 : 12)),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: fg == Colors.white ? _color : fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
