import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'habit_model.dart';
import 'app_theme.dart';
import 'notification_service.dart';
import 'calendar_note_model.dart';
import 'add_note_dialog.dart';
import 'relapse_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService().init();
  await NotificationService().requestPermissions();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Habit> _habits = [];
  List<CalendarNote> _calendarNotes = [];
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadHabits();
    _loadCalendarNotes();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? habitStrings = prefs.getStringList('habits');
    
    if (habitStrings != null && habitStrings.isNotEmpty) {
      try {
        final loadedHabits = <Habit>[];
        for (String habitStr in habitStrings) {
          final Map<String, dynamic> json = jsonDecode(habitStr);
          loadedHabits.add(Habit.fromJson(json));
        }
        setState(() {
          _habits = loadedHabits;
        });
        
        for (var habit in _habits) {
          if (habit.hasReminder) {
            await NotificationService().scheduleNotification(habit);
          }
        }
      } catch (e) {
        print('Ошибка загрузки: $e');
        _createSampleHabits();
      }
    } else {
      _createSampleHabits();
    }
  }

  Future<void> _loadCalendarNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? notesStrings = prefs.getStringList('calendar_notes');
    
    if (notesStrings != null && notesStrings.isNotEmpty) {
      try {
        final loadedNotes = <CalendarNote>[];
        for (String noteStr in notesStrings) {
          final Map<String, dynamic> json = jsonDecode(noteStr);
          loadedNotes.add(CalendarNote.fromJson(json));
        }
        setState(() {
          _calendarNotes = loadedNotes;
        });
      } catch (e) {
        print('Ошибка загрузки заметок: $e');
      }
    }
  }

  void _createSampleHabits() {
    setState(() {
      _habits = [
        Habit(id: '1', name: 'Выпить воду', icon: '💧', colorValue: Colors.blue.value, type: HabitType.good, completedDates: [], createdAt: DateTime.now()),
        Habit(id: '2', name: 'Зарядка', icon: '🏃', colorValue: Colors.green.value, type: HabitType.good, completedDates: [], createdAt: DateTime.now()),
        Habit(id: '3', name: 'Почитать книгу', icon: '📚', colorValue: Colors.orange.value, type: HabitType.good, completedDates: [], createdAt: DateTime.now()),
        Habit(id: '4', name: 'Не курить', icon: '🚭', colorValue: Colors.red.value, type: HabitType.bad, completedDates: [], createdAt: DateTime.now()),
        Habit(id: '5', name: 'Не есть сладкое', icon: '🍬', colorValue: Colors.red.value, type: HabitType.bad, completedDates: [], createdAt: DateTime.now()),
      ];
    });
    _saveHabits();
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitStrings = _habits.map((habit) => jsonEncode(habit.toJson())).toList();
    await prefs.setStringList('habits', habitStrings);
  }

  Future<void> _saveCalendarNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesStrings = _calendarNotes.map((note) => jsonEncode(note.toJson())).toList();
    await prefs.setStringList('calendar_notes', notesStrings);
  }

  void _addHabit(Habit habit) {
    setState(() {
      _habits.add(habit);
    });
    _saveHabits();
  }

  void _deleteHabit(Habit habit) {
    setState(() {
      _habits.removeWhere((h) => h.id == habit.id);
    });
    _saveHabits();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.name} удалена'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _addCalendarNote(CalendarNote note) {
    setState(() {
      _calendarNotes.add(note);
    });
    _saveCalendarNotes();
  }

  void _deleteCalendarNote(CalendarNote note) {
    setState(() {
      _calendarNotes.removeWhere((n) => n.id == note.id);
    });
    _saveCalendarNotes();
  }

  void _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Трекер привычек',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: HabitTrackerScreen(
        habits: _habits,
        calendarNotes: _calendarNotes,
        onAddHabit: _addHabit,
        onDeleteHabit: _deleteHabit,
        onSaveHabits: _saveHabits,
        onToggleTheme: _toggleTheme,
        onAddCalendarNote: _addCalendarNote,
        onDeleteCalendarNote: _deleteCalendarNote,
      ),
    );
  }
}

class HabitTrackerScreen extends StatefulWidget {
  final List<Habit> habits;
  final List<CalendarNote> calendarNotes;
  final Function(Habit) onAddHabit;
  final Function(Habit) onDeleteHabit;
  final Function() onSaveHabits;
  final Function(bool) onToggleTheme;
  final Function(CalendarNote) onAddCalendarNote;
  final Function(CalendarNote) onDeleteCalendarNote;

  const HabitTrackerScreen({
    super.key,
    required this.habits,
    required this.calendarNotes,
    required this.onAddHabit,
    required this.onDeleteHabit,
    required this.onSaveHabits,
    required this.onToggleTheme,
    required this.onAddCalendarNote,
    required this.onDeleteCalendarNote,
  });

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  int _selectedHabitTab = 0;
  late TabController _tabController;

  List<Habit> get _goodHabits => widget.habits.where((h) => h.type == HabitType.good).toList();
  List<Habit> get _badHabits => widget.habits.where((h) => h.type == HabitType.bad).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleHabit(Habit habit, DateTime date) {
    setState(() {
      if (habit.isCompletedOn(date)) {
        habit.uncompleteOn(date);
      } else {
        habit.completeOn(date);
      }
    });
    widget.onSaveHabits();
  }

  void _confirmDelete(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить привычку?'),
        content: Text('Вы уверены, что хотите удалить "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteHabit(habit);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Трекер привычек'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onSaveHabits();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Сохранено!')),
              );
            },
            tooltip: 'Сохранить',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () async {
              await NotificationService().showTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Тестовое уведомление отправлено!')),
              );
            },
            tooltip: 'Тест уведомления',
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              widget.onToggleTheme(!isDark);
            },
            tooltip: isDark ? 'Светлая тема' : 'Темная тема',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Список'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Календарь'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Статистика'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHabitList(),
          _buildCalendarView(),
          _buildStatisticsView(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showAddHabitDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHabitList() {
    final today = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Пока нет привычек', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Нажмите + чтобы добавить', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedHabitTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedHabitTab == 0 ? AppTheme.primaryGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        '✅ Полезные',
                        style: TextStyle(
                          color: _selectedHabitTab == 0 ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedHabitTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedHabitTab == 1 ? Colors.red : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        '🚫 Отказ от вредных',
                        style: TextStyle(
                          color: _selectedHabitTab == 1 ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _selectedHabitTab == 0
              ? (_goodHabits.isEmpty
                  ? Center(child: Text('Нет полезных привычек\nНажмите + чтобы добавить', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _goodHabits.length,
                      itemBuilder: (context, index) {
                        final habit = _goodHabits[index];
                        final isCompleted = habit.isCompletedOn(today);
                        return _buildGoodHabitCard(habit, isCompleted);
                      },
                    ))
              : (_badHabits.isEmpty
                  ? Center(child: Text('Нет вредных привычек\nНажмите + чтобы добавить', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _badHabits.length,
                      itemBuilder: (context, index) {
                        final habit = _badHabits[index];
                        return _buildBadHabitCard(habit);
                      },
                    )),
        ),
      ],
    );
  }

  Widget _buildGoodHabitCard(Habit habit, bool isCompleted) {
    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _confirmDelete(habit);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(habit.icon, style: const TextStyle(fontSize: 24))),
          ),
          title: Row(
            children: [
              Expanded(child: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (habit.hasReminder)
                Icon(Icons.notifications_active, size: 16, color: AppTheme.primaryGreen),
            ],
          ),
          subtitle: Row(
            children: [
              Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Text('Серия: ${habit.getStreak()} дней', style: const TextStyle(fontSize: 12)),
              if (habit.hasReminder && habit.reminderTime != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 2),
                Text(habit.reminderTimeString, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              isCompleted ? Icons.check_circle : Icons.check_circle_outline,
              color: isCompleted ? AppTheme.primaryGreen : Colors.grey,
              size: 32,
            ),
            onPressed: () => _toggleHabit(habit, DateTime.now()),
          ),
        ),
      ),
    );
  }

  Widget _buildBadHabitCard(Habit habit) {
    final streak = habit.getStreak();
    final maxStreak = 30;
    final progress = (streak / maxStreak).clamp(0.0, 1.0);
    
    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _confirmDelete(habit);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(habit.icon, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (habit.hasReminder)
                          Icon(Icons.notifications_active, size: 16, color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.warning, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          'Без срыва: $streak дней',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[300],
                              color: Colors.red,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      'Цель: $maxStreak дней без срыва',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              ElevatedButton.icon(
                onPressed: () => _showRelapseDialog(habit),
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: const Text('Срыв'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRelapseDialog(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => RelapseDialog(
        habitName: habit.name,
        habitIcon: habit.icon,
        onConfirm: (reason) {
          setState(() {
            habit.addRelapse(DateTime.now(), reason);
            widget.onSaveHabits();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Срыв привычки "${habit.name}" зафиксирован'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarView() {
    final notesForDay = widget.calendarNotes.where((note) => 
      note.date.year == _selectedDay.year &&
      note.date.month == _selectedDay.month &&
      note.date.day == _selectedDay.day
    ).toList();
    
    final currentMonthNotes = widget.calendarNotes.where((note) =>
      note.date.year == _focusedDay.year &&
      note.date.month == _focusedDay.month
    ).toList();
    
    final Map<Mood, int> moodStats = {};
    for (var note in currentMonthNotes) {
      moodStats[note.mood] = (moodStats[note.mood] ?? 0) + 1;
    }
    
    return Column(
      children: [
        if (currentMonthNotes.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[800] 
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: Mood.values.map((mood) {
                final count = moodStats[mood] ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Column(
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 16)),
                    Text('$count', style: const TextStyle(fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ),
        
        TableCalendar(
          firstDay: DateTime(2024, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              CalendarNote? noteForDay;
              for (var note in widget.calendarNotes) {
                if (note.date.year == day.year &&
                    note.date.month == day.month &&
                    note.date.day == day.day) {
                  noteForDay = note;
                  break;
                }
              }
              
              if (noteForDay != null) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Text('${day.day}'),
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: noteForDay.mood.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return null;
            },
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
          ),
        ),
        const SizedBox(height: 16),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📝 Заметки на ${DateFormat('dd.MM.yyyy').format(_selectedDay)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
                onPressed: () => _showAddNoteDialog(),
                tooltip: 'Добавить заметку',
              ),
            ],
          ),
        ),
        const Divider(),
        
        Expanded(
          child: notesForDay.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notes_rounded, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Нет заметок на этот день',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showAddNoteDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить заметку'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notesForDay.length,
                  itemBuilder: (context, index) {
                    final note = notesForDay[index];
                    return Dismissible(
                      key: Key(note.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        widget.onDeleteCalendarNote(note);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Заметка "${note.title}" удалена'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: note.mood.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                note.mood.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          title: Text(
                            note.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (note.description.isNotEmpty)
                                Text(note.description),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.mood, size: 14, color: note.mood.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    note.mood.label,
                                    style: TextStyle(fontSize: 12, color: note.mood.color),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Удалить заметку?'),
                                  content: Text('Удалить "${note.title}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        widget.onDeleteCalendarNote(note);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Заметка "${note.title}" удалена'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Удалить'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        selectedDate: _selectedDay,
        onAddNote: (note) {
          widget.onAddCalendarNote(note);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заметка "${note.title}" добавлена'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsView() {
    if (widget.habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Добавьте привычки для статистики', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    final totalGoodHabits = _goodHabits.length;
    final totalBadHabits = _badHabits.length;
    final maxStreakGood = _goodHabits.isEmpty ? 0 : _goodHabits.map((h) => h.getStreak()).reduce((a, b) => a > b ? a : b);
    final maxStreakBad = _badHabits.isEmpty ? 0 : _badHabits.map((h) => h.getStreak()).reduce((a, b) => a > b ? a : b);
    final completedTodayGood = _goodHabits.where((h) => h.isCompletedOn(DateTime.now())).length;
    final avgProgressGood = _goodHabits.isEmpty ? 0 : _goodHabits.map((h) => h.getCompletionRate()).reduce((a, b) => a + b) / totalGoodHabits * 100;
    final avgProgressBad = _badHabits.isEmpty ? 0 : _badHabits.map((h) => h.getCompletionRate()).reduce((a, b) => a + b) / totalBadHabits * 100;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Общая статистика', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('✅ Полезные', '$totalGoodHabits', Icons.favorite, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('🚫 Контроль', '$totalBadHabits', Icons.warning, Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('🔥 Лучшая серия', '$maxStreakGood дн.', Icons.local_fire_department, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('⚠️ Лучший контроль', '$maxStreakBad дн.', Icons.verified, Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('✅ Выполнено сегодня', '$completedTodayGood/$totalGoodHabits', Icons.today, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('🚫 Вредных привычек', '$totalBadHabits', Icons.warning, Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('📊 Прогресс', '${avgProgressGood.toStringAsFixed(0)}%', Icons.analytics, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('📊 Успех', '${avgProgressBad.toStringAsFixed(0)}%', Icons.analytics, Colors.red)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Детальная статистика', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_goodHabits.isNotEmpty) ...[
            const Text('✅ Полезные привычки', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green)),
            const SizedBox(height: 8),
            ..._goodHabits.map((habit) => _buildHabitStatCard(habit)),
          ],
          if (_badHabits.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('🚫 Отказ от вредных привычек', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red)),
            const SizedBox(height: 8),
            ..._badHabits.map((habit) => _buildHabitStatCard(habit)),
          ],
          
          const SizedBox(height: 24),
          const Text('📊 Статистика настроений', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMoodStats(),
          const SizedBox(height: 16),
          _buildRecentMoods(),
        ],
      ),
    );
  }

  Widget _buildMoodStats() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    final monthNotes = widget.calendarNotes.where((note) =>
      note.date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) && 
      note.date.isBefore(lastDayOfMonth.add(const Duration(days: 1)))
    ).toList();
    
    if (monthNotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Нет заметок за этот месяц',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }
    
    final Map<Mood, int> moodCount = {};
    for (var note in monthNotes) {
      moodCount[note.mood] = (moodCount[note.mood] ?? 0) + 1;
    }
    
    final totalNotes = monthNotes.length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(now),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: Mood.values.map((mood) {
                final count = moodCount[mood] ?? 0;
                if (count == 0) return const SizedBox.shrink();
                final percentage = (count / totalNotes * 100).toInt();
                return Container(
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mood.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: mood.color.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                      Text(mood.label, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: count / totalNotes,
                        backgroundColor: Colors.grey[300],
                        color: mood.color,
                        minHeight: 6,
                      ),
                      Text(
                        '$percentage% ($count)',
                        style: TextStyle(fontSize: 11, color: mood.color),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMoods() {
    final sortedNotes = List<CalendarNote>.from(widget.calendarNotes)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final recentNotes = sortedNotes.take(10).toList();
    
    if (recentNotes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🕐 Последние настроения',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...recentNotes.map((note) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: note.mood.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(note.mood.emoji, style: const TextStyle(fontSize: 20))),
              ),
              title: Text(note.title),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(note.date)),
              trailing: Text(
                note.mood.label,
                style: TextStyle(color: note.mood.color, fontWeight: FontWeight.w500),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHabitStatCard(Habit habit) {
    final streak = habit.getStreak();
    final rate = habit.getCompletionRate();
    final isGoodType = habit.type == HabitType.good;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isGoodType ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(habit.icon, style: const TextStyle(fontSize: 22))),
        ),
        title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildMiniStat('Серия', '$streak дн.', isGoodType ? Colors.green : Colors.red),
                const SizedBox(width: 16),
                _buildMiniStat('Выполнение', '${(rate * 100).toStringAsFixed(0)}%', isGoodType ? Colors.green : Colors.red),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: rate,
              backgroundColor: Colors.grey[300],
              color: isGoodType ? Colors.green : Colors.red,
            ),
          ],
        ),
        children: [
          if (!isGoodType && habit.relapses.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(12),
              child: Divider(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '📋 История срывов:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            ...habit.relapses.reversed.map((relapse) => ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
              title: Text(
                DateFormat('dd.MM.yyyy').format(relapse.date),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text('Причина: ${relapse.reason}'),
              trailing: Text(
                'Серия была: ${relapse.streakLost} дн.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )),
          ],
          if (isGoodType && habit.completedDates.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(12),
              child: Divider(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '📅 Последние выполнения:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: habit.completedDates.reversed.take(7).map((date) => Chip(
                label: Text(DateFormat('dd.MM').format(date)),
                avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
              )).toList(),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  void _showAddHabitDialog() {
    final nameController = TextEditingController();
    String selectedIcon = '💧';
    Color selectedColor = Colors.blue;
    HabitType selectedType = HabitType.good;
    bool hasReminder = false;
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Новая привычка',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Название привычки',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      
                      const Text('Тип привычки:'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setStateDialog(() => selectedType = HabitType.good),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedType == HabitType.good ? Colors.green : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    '✅ Полезная',
                                    style: TextStyle(
                                      color: selectedType == HabitType.good ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setStateDialog(() => selectedType = HabitType.bad),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedType == HabitType.bad ? Colors.red : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    '🚫 Вредная',
                                    style: TextStyle(
                                      color: selectedType == HabitType.bad ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      const Divider(),
                      const Text('🔔 Напоминание', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Включить напоминание'),
                        value: hasReminder,
                        onChanged: (value) {
                          setStateDialog(() {
                            hasReminder = value;
                          });
                        },
                        activeColor: AppTheme.primaryGreen,
                      ),
                      if (hasReminder) ...[
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: const Text('Время напоминания'),
                          subtitle: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                          trailing: const Icon(Icons.edit),
                          onTap: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setStateDialog(() {
                                selectedTime = time;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Вы будете получать уведомление в это время каждый день',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      const Text('Выберите иконку:'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['💧', '🏃', '📚', '💪', '🧘', '🍎', '😴', '🎯', '🚭', '🍬', '📱', '🍺']
                            .map((icon) => ChoiceChip(
                                  label: Text(icon, style: const TextStyle(fontSize: 20)),
                                  selected: selectedIcon == icon,
                                  onSelected: (selected) {
                                    setStateDialog(() {
                                      selectedIcon = icon;
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      const Text('Выберите цвет:'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Colors.blue, Colors.green, Colors.orange, Colors.purple, 
                          Colors.red, Colors.teal, Colors.pink,
                        ].map((color) => ChoiceChip(
                              label: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              selected: selectedColor == color,
                              onSelected: (selected) {
                                setStateDialog(() {
                                  selectedColor = color;
                                });
                              },
                            )).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Отмена'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.isNotEmpty) {
                                  final newHabit = Habit(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    name: nameController.text,
                                    icon: selectedIcon,
                                    colorValue: selectedColor.value,
                                    type: selectedType,
                                    completedDates: [],
                                    createdAt: DateTime.now(),
                                    hasReminder: hasReminder,
                                    reminderTime: hasReminder ? selectedTime : null,
                                  );
                                  
                                  widget.onAddHabit(newHabit);
                                  
                                  if (hasReminder) {
                                    await NotificationService().scheduleNotification(newHabit);
                                  }
                                  
                                  Navigator.pop(context);
                                }
                              },
                              style: ButtonStyles.primaryButton,
                              child: const Text('Добавить'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}