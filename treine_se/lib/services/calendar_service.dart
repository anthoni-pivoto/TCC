import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class CalendarService {
  static final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  // Distribui os dias de treino na semana de forma otimizada (não consecutivos)
  static const Map<int, List<int>> _distribuicao = {
    1: [DateTime.monday],
    2: [DateTime.monday, DateTime.thursday],
    3: [DateTime.monday, DateTime.wednesday, DateTime.friday],
    4: [DateTime.monday, DateTime.tuesday, DateTime.thursday, DateTime.friday],
    5: [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday],
    6: [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday, DateTime.saturday],
    7: [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday, DateTime.saturday, DateTime.sunday],
  };

  static const Map<int, String> _nomeDia = {
    1: 'Segunda',
    2: 'Terça',
    3: 'Quarta',
    4: 'Quinta',
    5: 'Sexta',
    6: 'Sábado',
    7: 'Domingo',
  };

  static Future<bool> solicitarPermissoes() async {
    final result = await _plugin.requestPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  static Future<String?> _obterCalendario() async {
    final result = await _plugin.retrieveCalendars();
    if (!result.isSuccess || result.data == null || result.data!.isEmpty) {
      return null;
    }
    final gravaveis = result.data!.where((c) => !(c.isReadOnly ?? true)).toList();
    return gravaveis.isNotEmpty ? gravaveis.first.id : result.data!.first.id;
  }

  /// Retorna os nomes dos dias da semana para a quantidade de treinos informada.
  static String nomeDosDias(List<Map<String, dynamic>> treinos) {
    final n = treinos.length.clamp(1, 7);
    final dias = _distribuicao[n] ?? [DateTime.monday];
    return dias.map((d) => _nomeDia[d] ?? '').join(', ');
  }

  /// Cria eventos recorrentes semanais no calendário do dispositivo para cada treino.
  static Future<bool> agendarTreinos({
    required List<Map<String, dynamic>> treinos,
    required TimeOfDay horario,
    required int duracaoMinutos,
  }) async {
    final temPermissao = await solicitarPermissoes();
    if (!temPermissao) return false;

    final calendarId = await _obterCalendario();
    if (calendarId == null) return false;

    final diasDaSemana = _distribuicao[treinos.length.clamp(1, 7)] ?? [DateTime.monday];
    final local = tz.local;
    final agora = DateTime.now();

    // Calcula a próxima segunda-feira
    final diasAteSegunda = (DateTime.monday - agora.weekday + 7) % 7;
    final proximaSegunda = agora.add(Duration(days: diasAteSegunda == 0 ? 7 : diasAteSegunda));

    for (int i = 0; i < treinos.length; i++) {
      final treino = treinos[i];
      final diaSemana = diasDaSemana[i < diasDaSemana.length ? i : 0];
      final exercicios = (treino['exercicios'] as List?) ?? [];
      final grupos = exercicios
          .map((e) => e['grupo_muscular'] as String)
          .toSet()
          .join(', ');
      final dia = treino['dia_treino'] as int;

      final diasAte = (diaSemana - DateTime.monday + 7) % 7;
      final dataEvento = proximaSegunda.add(Duration(days: diasAte));

      final inicio = tz.TZDateTime(
        local,
        dataEvento.year,
        dataEvento.month,
        dataEvento.day,
        horario.hour,
        horario.minute,
      );
      final fim = inicio.add(Duration(minutes: duracaoMinutos));

      final evento = Event(calendarId);
      evento.title = 'Treino Dia $dia — ${_nomeDia[diaSemana] ?? ''}';
      evento.description =
          '${exercicios.length} exercício(s)\nGrupos: $grupos\n\nAbra o app Treine-se para iniciar.';
      evento.start = inicio;
      evento.end = fim;
      evento.recurrenceRule = RecurrenceRule(
        RecurrenceFrequency.Weekly,
        interval: 1,
        totalOccurrences: 52,
      );

      final resultado = await _plugin.createOrUpdateEvent(evento);
      if (resultado == null || !resultado.isSuccess) return false;
    }

    return true;
  }
}
