import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/phosphor_icons.dart';
import '../models/car.dart';
import '../models/maintenance_summary.dart';
import '../models/reminder.dart';
import '../theme/app_colors.dart';

/// Display helpers that turn the API's maintenance data into the prototype's
/// statuses, colors, icons and labels. Presentation only — nothing here
/// changes what is fetched or sent.

final kmFormat = NumberFormat('#,##0');
final moneyFormat = NumberFormat('#,##0');

enum MStatus { overdue, due, soon, ok }

extension MStatusStyle on MStatus {
  Color get color {
    switch (this) {
      case MStatus.overdue:
        return AppColors.danger;
      case MStatus.due:
        return AppColors.warn;
      case MStatus.soon:
        return AppColors.accent400;
      case MStatus.ok:
        return AppColors.textMuted;
    }
  }

  Color get tint => color.withValues(alpha: 0.16);
  Color get edge => color.withValues(alpha: 0.4);

  String get label {
    switch (this) {
      case MStatus.overdue:
        return 'Overdue';
      case MStatus.due:
        return 'Due';
      case MStatus.soon:
        return 'Soon';
      case MStatus.ok:
        return 'OK';
    }
  }

  int get rank => index;
}

MStatus statusFromApi(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'OVERDUE':
      return MStatus.overdue;
    case 'DUE':
      return MStatus.due;
    case 'UPCOMING':
      return MStatus.soon;
    default:
      return MStatus.ok;
  }
}

/// Overall status of a car from its maintenance summary.
MStatus summaryStatus(MaintenanceSummary? s) {
  if (s == null) return MStatus.ok;
  if (s.overdue.isNotEmpty) return MStatus.overdue;
  if (s.due.isNotEmpty) return MStatus.due;
  if (s.upcoming.isNotEmpty) return MStatus.soon;
  return MStatus.ok;
}

/// Health score (0–100) shown on the ring: each tracked item counts fully
/// when OK and less the closer it is to being overdue.
int healthScore(MaintenanceSummary? s) {
  if (s == null) return 100;
  final total = s.ok.length + s.upcoming.length + s.due.length + s.overdue.length;
  if (total == 0) return 100;
  final v = (s.ok.length * 1.0 + s.upcoming.length * 0.85 + s.due.length * 0.5 + s.overdue.length * 0.15) / total;
  return (v * 100).round();
}

String healthLabel(MaintenanceSummary? s) {
  switch (summaryStatus(s)) {
    case MStatus.overdue:
      return 'Service overdue';
    case MStatus.due:
      return 'Needs attention';
    case MStatus.soon:
      return 'Good shape';
    case MStatus.ok:
      return 'Excellent';
  }
}

String typeLabel(String type) {
  final words = type.toLowerCase().split('_').where((w) => w.isNotEmpty);
  final out = words.map((w) => w == 'ac' ? 'AC' : w[0].toUpperCase() + w.substring(1)).join(' ');
  return out.isEmpty ? 'Service' : out;
}

IconData typeIcon(String type) {
  switch (type.toUpperCase()) {
    case 'ENGINE_OIL':
      return PhosphorIconsRegular.drop;
    case 'BRAKE_OIL':
      return PhosphorIconsRegular.disc;
    case 'GEAR_OIL':
      return PhosphorIconsRegular.gearSix;
    case 'ENGINE_BELT':
      return PhosphorIconsRegular.circleNotch;
    case 'AIR_FILTER':
      return PhosphorIconsRegular.wind;
    case 'AC_FILTER':
    case 'AC_REFRIGERANT_SERVICE':
      return PhosphorIconsRegular.snowflake;
    case 'BATTERY':
      return PhosphorIconsRegular.carBattery;
    case 'ENGINE_COOLANT':
      return PhosphorIconsRegular.thermometerSimple;
    case 'SPARK_PLUGS':
      return PhosphorIconsRegular.lightning;
    case 'TIRE_REPLACEMENT':
    case 'TIRE_ROTATION':
      return PhosphorIconsRegular.arrowsClockwise;
    default:
      return PhosphorIconsRegular.wrench;
  }
}

/// Category palette for the spending donut (accent + neutral ramps).
const categoryColors = [
  AppColors.accent300,
  AppColors.accent500,
  AppColors.accent700,
  AppColors.textSecondary,
  AppColors.textFaint,
  AppColors.neutral700,
];

/// A reminder resolved against its car for display.
class ReminderView {
  final Reminder reminder;
  final MStatus status;
  final int? kmLeft;
  ReminderView(this.reminder, Car? car)
      : status = statusFromApi(reminder.status),
        kmLeft = (reminder.dueMileage != null && car != null) ? reminder.dueMileage! - car.currentMileage : null;

  String get name => typeLabel(reminder.maintenanceType);
  IconData get icon => typeIcon(reminder.maintenanceType);

  /// "770 km" / "3,100 km over" / due date / status.
  String get leftLabel {
    if (kmLeft != null) {
      if (kmLeft! < 0) return '${kmFormat.format(-kmLeft!)} km over';
      return '${kmFormat.format(kmLeft)} km';
    }
    if (reminder.dueDate != null) return _date(reminder.dueDate!);
    return status.label;
  }

  String get dueAt {
    if (reminder.dueMileage != null) return 'At ${kmFormat.format(reminder.dueMileage)} km';
    if (reminder.dueDate != null) return 'On ${_date(reminder.dueDate!)}';
    return 'No due point set';
  }

  String get secondary {
    if (reminder.dueDate != null && reminder.dueMileage != null) return _date(reminder.dueDate!);
    return status.label;
  }

  /// How far along the interval the item is (bar fill).
  double get progress {
    if (kmLeft != null) {
      if (kmLeft! <= 0) return 1;
      return (1 - kmLeft! / 10000).clamp(0.08, 0.98);
    }
    switch (status) {
      case MStatus.overdue:
        return 1;
      case MStatus.due:
        return 0.9;
      case MStatus.soon:
        return 0.72;
      case MStatus.ok:
        return 0.3;
    }
  }

  static String _date(String raw) {
    final d = DateTime.tryParse(raw);
    return d == null ? raw : DateFormat('MMM d, yyyy').format(d.toLocal());
  }
}

List<ReminderView> sortedReminders(List<Reminder> list, Car? car) {
  final views = list.map((r) => ReminderView(r, car)).toList();
  views.sort((a, b) {
    final r = a.status.rank.compareTo(b.status.rank);
    if (r != 0) return r;
    return (a.kmLeft ?? 1 << 30).compareTo(b.kmLeft ?? 1 << 30);
  });
  return views;
}

/// Selected bottom tab of the main scaffold (0 Home, 1 Garage, 2 Centers, 3 Spending).
final ValueNotifier<int> mainTab = ValueNotifier<int>(0);

/// Which car Home, the quick-add sheet and the odometer sheet act on.
final ValueNotifier<String?> activeCarId = ValueNotifier<String?>(null);

Car? resolveActiveCar(List<Car> cars) {
  if (cars.isEmpty) return null;
  return cars.where((c) => c.id == activeCarId.value).firstOrNull ?? cars.first;
}
