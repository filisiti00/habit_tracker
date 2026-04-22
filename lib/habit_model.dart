import 'package:flutter/material.dart';

enum HabitType { good, bad }

class Relapse {
  final DateTime date;
  final String reason;
  final int streakLost; // сколько дней серии было на момент срыва

  Relapse({
    required this.date,
    required this.reason,
    required this.streakLost,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'reason': reason,
    'streakLost': streakLost,
  };

  factory Relapse.fromJson(Map<String, dynamic> json) => Relapse(
    date: DateTime.parse(json['date']),
    reason: json['reason'],
    streakLost: json['streakLost'],
  );
}

class Habit {
  final String id;
  final String name;
  final String icon;
  final int colorValue;
  final HabitType type;
  List<DateTime> completedDates;
  final DateTime createdAt;
  bool hasReminder;
  TimeOfDay? reminderTime;
  List<Relapse> relapses; // Добавляем список срывов

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.type,
    required this.completedDates,
    required this.createdAt,
    this.hasReminder = false,
    this.reminderTime,
    this.relapses = const [],
  });

  Color get color => Color(colorValue);
  
  String get reminderTimeString {
    if (reminderTime == null) return '';
    return '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}';
  }

  bool isCompletedOn(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return completedDates.any((d) => 
      d.year == normalized.year && 
      d.month == normalized.month && 
      d.day == normalized.day
    );
  }

  void completeOn(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (!isCompletedOn(normalized)) {
      completedDates.add(normalized);
    }
  }

  void uncompleteOn(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    completedDates.removeWhere((d) => 
      d.year == normalized.year && 
      d.month == normalized.month && 
      d.day == normalized.day
    );
  }

  // Для вредных привычек - добавить срыв
  void addRelapse(DateTime date, String reason) {
    final currentStreak = getStreak();
    relapses.add(Relapse(
      date: date,
      reason: reason,
      streakLost: currentStreak,
    ));
    // Обнуляем серию, удаляя все completion за последние дни
    // Для вредных привычек серия - это дни без срыва
    _resetStreak();
  }

  void _resetStreak() {
    // Очищаем completedDates, так как для вредных привычек 
    // completedDates означают дни без срыва
    final today = DateTime.now();
    completedDates = completedDates.where((date) => 
      date.isAfter(DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1)))
    ).toList();
  }

  int getStreak() {
    if (type == HabitType.good) {
      return _calculateGoodStreak();
    } else {
      return _calculateBadStreak();
    }
  }

  int _calculateGoodStreak() {
    if (completedDates.isEmpty) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sorted = List<DateTime>.from(completedDates)..sort();
    final lastDate = sorted.last;
    
    if (lastDate.isBefore(today)) return 0;
    
    int streak = 1;
    DateTime current = lastDate;
    
    while (true) {
      final previous = current.subtract(const Duration(days: 1));
      if (completedDates.any((d) => 
        d.year == previous.year && 
        d.month == previous.month && 
        d.day == previous.day
      )) {
        streak++;
        current = previous;
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateBadStreak() {
    // Для вредных привычек серия - это дни без срыва
    if (relapses.isEmpty) {
      // Если нет срывов, считаем дни с момента создания
      final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
      return daysSinceCreated;
    }
    
    final lastRelapse = relapses.map((r) => r.date).reduce((a, b) => a.isAfter(b) ? a : b);
    final daysSinceLastRelapse = DateTime.now().difference(lastRelapse).inDays;
    return daysSinceLastRelapse;
  }

  double getCompletionRate() {
    if (type == HabitType.good) {
      if (completedDates.isEmpty) return 0.0;
      
      final now = DateTime.now();
      final firstDate = completedDates.isNotEmpty 
          ? completedDates.reduce((a, b) => a.isBefore(b) ? a : b)
          : now;
      
      final totalDays = now.difference(firstDate).inDays + 1;
      if (totalDays <= 0) return 0.0;
      
      return completedDates.length / totalDays;
    } else {
      // Для вредных - процент дней без срыва
      final daysSinceCreated = DateTime.now().difference(createdAt).inDays + 1;
      if (daysSinceCreated <= 0) return 0.0;
      
      final relapseDays = relapses.map((r) => 
        DateTime(r.date.year, r.date.month, r.date.day)
      ).toSet();
      
      final successDays = daysSinceCreated - relapseDays.length;
      return successDays / daysSinceCreated;
    }
  }

  // Получить список срывов за период
  List<Relapse> getRelapsesForPeriod(DateTime start, DateTime end) {
    return relapses.where((r) => 
      r.date.isAfter(start) && r.date.isBefore(end)
    ).toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'colorValue': colorValue,
    'type': type.toString(),
    'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'hasReminder': hasReminder,
    'reminderTime': reminderTime != null ? '${reminderTime!.hour}:${reminderTime!.minute}' : null,
    'relapses': relapses.map((r) => r.toJson()).toList(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) {
    TimeOfDay? reminderTime;
    if (json['reminderTime'] != null) {
      final parts = json['reminderTime'].split(':');
      reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    
    return Habit(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      colorValue: json['colorValue'],
      type: json['type'] == 'HabitType.good' ? HabitType.good : HabitType.bad,
      completedDates: (json['completedDates'] as List)
          .map((d) => DateTime.parse(d))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      hasReminder: json['hasReminder'] ?? false,
      reminderTime: reminderTime,
      relapses: json['relapses'] != null 
          ? (json['relapses'] as List).map((r) => Relapse.fromJson(r)).toList()
          : [],
    );
  }
}