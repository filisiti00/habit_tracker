import 'package:flutter/material.dart';

enum Mood {
  great('Отлично', '😊', Colors.green),
  good('Хорошо', '🙂', Colors.lightGreen),
  neutral('Нормально', '😐', Colors.orange),
  bad('Плохо', '😟', Colors.deepOrange),
  terrible('Ужасно', '😫', Colors.red),
  excited('Восторг', '🤩', Colors.purple),
  tired('Устал', '😴', Colors.blueGrey),
  loved('Любовь', '🥰', Colors.pink),
  angry('Злость', '😠', Colors.red),
  sad('Грусть', '😢', Colors.indigo);

  final String label;
  final String emoji;
  final Color color;
  
  const Mood(this.label, this.emoji, this.color);
}

class CalendarNote {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final Mood mood; // Заменяем color на mood
  final DateTime createdAt;

  CalendarNote({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.mood,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'mood': mood.index, // Сохраняем индекс настроения
    'createdAt': createdAt.toIso8601String(),
  };

  factory CalendarNote.fromJson(Map<String, dynamic> json) => CalendarNote(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    date: DateTime.parse(json['date']),
    mood: Mood.values[json['mood']],
    createdAt: DateTime.parse(json['createdAt']),
  );
}