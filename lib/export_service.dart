import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'habit_model.dart';
import 'calendar_note_model.dart';

class ExportService {
  static Future<String?> exportToText({
    required List<Habit> habits,
    required List<CalendarNote> notes,
  }) async {
    try {
      final buffer = StringBuffer();
      
      buffer.writeln('=========================================');
      buffer.writeln('        ТРЕКЕР ПРИВЫЧЕК - ЭКСПОРТ');
      buffer.writeln('=========================================');
      buffer.writeln('Дата экспорта: ${DateFormat('dd.MM.yyyy HH:mm:ss').format(DateTime.now())}');
      buffer.writeln();
      
      buffer.writeln('📋 ПРИВЫЧКИ');
      buffer.writeln('-----------------------------------------');
      
      final goodHabits = habits.where((h) => h.type == HabitType.good).toList();
      final badHabits = habits.where((h) => h.type == HabitType.bad).toList();
      
      if (goodHabits.isNotEmpty) {
        buffer.writeln('\n✅ ПОЛЕЗНЫЕ ПРИВЫЧКИ:');
        for (var habit in goodHabits) {
          buffer.writeln('  ${habit.icon} ${habit.name}');
          buffer.writeln('    Серия: ${habit.getStreak()} дней');
          buffer.writeln('    Выполнение: ${(habit.getCompletionRate() * 100).toInt()}%');
          buffer.writeln('    Всего выполнено: ${habit.completedDates.length} дней');
          buffer.writeln();
        }
      }
      
      if (badHabits.isNotEmpty) {
        buffer.writeln('\n🚫 ВРЕДНЫЕ ПРИВЫЧКИ:');
        for (var habit in badHabits) {
          buffer.writeln('  ${habit.icon} ${habit.name}');
          buffer.writeln('    Без срыва: ${habit.getStreak()} дней');
          buffer.writeln('    Успех: ${(habit.getCompletionRate() * 100).toInt()}%');
          buffer.writeln();
          
          if (habit.relapses.isNotEmpty) {
            buffer.writeln('    Срывы:');
            for (var relapse in habit.relapses) {
              buffer.writeln('      - ${DateFormat('dd.MM.yyyy').format(relapse.date)}: ${relapse.reason}');
            }
            buffer.writeln();
          }
        }
      }
      
      buffer.writeln('\n\n📝 ЗАМЕТКИ И НАСТРОЕНИЯ');
      buffer.writeln('-----------------------------------------');
      
      if (notes.isEmpty) {
        buffer.writeln('Нет заметок');
      } else {
        final sortedNotes = List<CalendarNote>.from(notes)
          ..sort((a, b) => b.date.compareTo(a.date));
        
        for (var note in sortedNotes) {
          buffer.writeln('\n${DateFormat('dd.MM.yyyy').format(note.date)} ${note.mood.emoji} ${note.mood.label}');
          buffer.writeln('  📌 ${note.title}');
          if (note.description.isNotEmpty) {
            buffer.writeln('  📝 ${note.description}');
          }
        }
      }
      
      buffer.writeln('\n\n📊 СТАТИСТИКА НАСТРОЕНИЙ');
      buffer.writeln('-----------------------------------------');
      
      final Map<Mood, int> moodCount = {};
      for (var note in notes) {
        moodCount[note.mood] = (moodCount[note.mood] ?? 0) + 1;
      }
      
      for (var mood in Mood.values) {
        final count = moodCount[mood] ?? 0;
        if (count > 0) {
          buffer.writeln('${mood.emoji} ${mood.label}: $count раз');
        }
      }
      
      buffer.writeln('\n=========================================');
      buffer.writeln('Конец экспорта');
      buffer.writeln('=========================================');
      
      final downloadsPath = _getDownloadsPath();
      final fileName = 'habit_tracker_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
      final file = File('$downloadsPath/$fileName');
      await file.writeAsString(buffer.toString());
      
      return file.path;
    } catch (e) {
      debugPrint('Ошибка экспорта: $e');
      return null;
    }
  }
  
  static String _getDownloadsPath() {
    if (Platform.isWindows) {
      return '${Platform.environment['USERPROFILE']}\\Downloads';
    } else if (Platform.isAndroid) {
      return '/storage/emulated/0/Download';
    } else {
      return '.';
    }
  }
}