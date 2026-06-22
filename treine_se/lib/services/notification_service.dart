import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const int _idDescanso    = 0;
  static const int _idInatividade = 1;
  static const int _idLembreteBase = 100; // 100–106 para cada dia de treino

  // Mesma distribuição do CalendarService
  static const Map<int, List<int>> _distribuicaoDias = {
    1: [DateTime.monday],
    2: [DateTime.monday, DateTime.thursday],
    3: [DateTime.monday, DateTime.wednesday, DateTime.friday],
    4: [DateTime.monday, DateTime.tuesday, DateTime.thursday, DateTime.friday],
    5: [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday],
    6: [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday, DateTime.saturday],
    7: [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday, DateTime.saturday, DateTime.sunday],
  };

  static Future<void> inicializar() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'descanso_channel',
      'Descanso entre séries',
      description: 'Avisa quando o tempo de descanso terminar',
      importance: Importance.high,
      playSound: true,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'treino_channel',
      'Lembretes de Treino',
      description: 'Lembretes semanais e alertas de inatividade',
      importance: Importance.high,
      playSound: true,
    ));

    _initialized = true;
  }

  // Notificação imediata: fim do descanso entre séries
  static Future<void> notificarDescansoEncerrado(String nomeExercicio) async {
    await _plugin.show(
      _idDescanso,
      'Descansou! 💪',
      'Hora da próxima série — $nomeExercicio',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'descanso_channel',
          'Descanso entre séries',
          channelDescription: 'Avisa quando o tempo de descanso terminar',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }

  // Agenda notificação para daqui 2 dias sem treinar
  static Future<void> agendarInatividade() async {
    await _plugin.cancel(_idInatividade);
    await _plugin.zonedSchedule(
      _idInatividade,
      'Hora de treinar! 💪',
      'Você está há 2 dias sem treinar. Que tal uma sessão hoje?',
      tz.TZDateTime.now(tz.local).add(const Duration(days: 2)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'treino_channel',
          'Lembretes de Treino',
          channelDescription: 'Lembretes semanais e alertas de inatividade',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancela o lembrete de inatividade (chamado ao abrir a tela de treino)
  static Future<void> cancelarInatividade() async {
    await _plugin.cancel(_idInatividade);
  }

  // Agenda lembretes semanais repetidos para cada dia de treino (ligado ao calendário)
  static Future<void> agendarLembretesTreino({
    required List<Map<String, dynamic>> treinos,
    required TimeOfDay horario,
  }) async {
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(_idLembreteBase + i);
    }

    final n = treinos.length.clamp(1, 7);
    final dias = _distribuicaoDias[n] ?? [DateTime.monday];

    for (int i = 0; i < treinos.length && i < dias.length; i++) {
      final diaSemana = dias[i];
      final dia = treinos[i]['dia_treino'] as int;

      await _plugin.zonedSchedule(
        _idLembreteBase + i,
        'Dia de treinar! 💪',
        'O Dia $dia do seu treino está esperando por você.',
        _proximoDiaDaSemana(diaSemana, horario),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'treino_channel',
            'Lembretes de Treino',
            channelDescription: 'Lembretes semanais e alertas de inatividade',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelarLembretesTreino() async {
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(_idLembreteBase + i);
    }
  }

  // Calcula o próximo DateTime para um dia da semana e horário específicos
  static tz.TZDateTime _proximoDiaDaSemana(int weekday, TimeOfDay horario) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, horario.hour, horario.minute,
    );
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
