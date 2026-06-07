import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'habit_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Инициализируем временные зоны
    tz_data.initializeTimeZones();
    
    // Настройки для Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Настройки для iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
  }

  // Запросить разрешение на уведомления
  Future<void> requestPermissions() async {
    // Для Android
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    // Для iOS
    await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions();
  }


Future<void> scheduleNotification(Habit habit) async {
  if (!habit.hasReminder || habit.reminderTime == null) return;
  
  await cancelNotification(habit.id);
  
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'habit_channel',
    'Напоминания о привычках',
    channelDescription: 'Напоминания о привычках',
    importance: Importance.high,
    priority: Priority.high,
  );
  
  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );
  
  // Ежедневное повторяющееся уведомление
  await _notifications.periodicallyShow(
    int.parse(habit.id),
    'Напоминание о привычке',
    'Не забудьте: ${habit.name} ${habit.type == HabitType.good ? "✅" : "🚫"}',
    RepeatInterval.daily,
    details,
  );
}

  // Отменить уведомление
  Future<void> cancelNotification(String habitId) async {
    try {
      await _notifications.cancel(int.parse(habitId));
    } catch (e) {
      print('Ошибка отмены уведомления: $e');
    }
  }

  // Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Показать тестовое уведомление
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'habit_channel',
      'Напоминания о привычках',
      channelDescription: 'Напоминания о привычках',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    await _notifications.show(
      999,
      'Трекер привычек',
      'Уведомления работают! 🎉',
      details,
    );
  }
}