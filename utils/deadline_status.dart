import 'package:flutter/material.dart';

enum DeadlineUiStatus {
  allDone,
  overdueOrUrgent,
  inProgress,
  noDeadline,
}

class DeadlineStatus {
  static const int urgentWithinDays = 2;

  static DeadlineUiStatus itemStatus({
    required bool isDone,
    DateTime? deadline,
  }) {
    if (isDone) return DeadlineUiStatus.allDone;
    if (deadline == null) return DeadlineUiStatus.noDeadline;
    final now = DateTime.now();
    final endOfDeadlineDay = DateTime(
      deadline.year,
      deadline.month,
      deadline.day,
      23,
      59,
      59,
    );
    if (endOfDeadlineDay.isBefore(now)) {
      return DeadlineUiStatus.overdueOrUrgent;
    }
    final days = deadline.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days <= urgentWithinDays) {
      return DeadlineUiStatus.overdueOrUrgent;
    }
    return DeadlineUiStatus.inProgress;
  }

  static Color accentFor(DeadlineUiStatus s, ColorScheme scheme) {
    switch (s) {
      case DeadlineUiStatus.allDone:
        return Colors.green.shade600;
      case DeadlineUiStatus.overdueOrUrgent:
        return Colors.red.shade600;
      case DeadlineUiStatus.inProgress:
        return Colors.orange.shade700;
      case DeadlineUiStatus.noDeadline:
        return scheme.primary;
    }
  }

  static Color tintFor(DeadlineUiStatus s, ThemeData theme) {
    final base = accentFor(s, theme.colorScheme);
    return base.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.12);
  }
}
