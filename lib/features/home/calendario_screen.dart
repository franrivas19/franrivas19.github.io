import 'package:flutter/material.dart';

import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/date_utils.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final _service = FirestoreService();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CALENDARIO')),
      body: StreamBuilder<List<MatchModel>>(
        stream: _service.allMatchesStream(),
        builder: (context, snapshot) {
          final allMatches = snapshot.data ?? const <MatchModel>[];
          final byDay = <DateTime, List<MatchModel>>{};
          for (final m in allMatches) {
            final dt = parseMatchDateTime(m.fecha, m.hora);
            if (dt == null) {
              continue;
            }
            final key = DateTime(dt.year, dt.month, dt.day);
            byDay.putIfAbsent(key, () => <MatchModel>[]).add(m);
          }

          final selectedKey = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
          final agenda = (byDay[selectedKey] ?? const <MatchModel>[]).toList()
            ..sort((a, b) {
              final adt = parseMatchDateTime(a.fecha, a.hora);
              final bdt = parseMatchDateTime(b.fecha, b.hora);
              if (adt == null || bdt == null) {
                return a.hora.compareTo(b.hora);
              }
              return adt.compareTo(bdt);
            });

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _CalendarHeader(
                  month: _focusedMonth,
                  onPrev: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                  onNext: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
                const SizedBox(height: 8),
                _CalendarGrid(
                  focusedMonth: _focusedMonth,
                  selectedDay: _selectedDay,
                  markers: byDay,
                  onSelectDay: (day) {
                    setState(() {
                      _selectedDay = day;
                      _focusedMonth = DateTime(day.year, day.month);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Agenda ${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: agenda.isEmpty
                      ? const Center(child: Text('Sin partidos para el dia seleccionado.'))
                      : ListView.separated(
                          itemCount: agenda.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final m = agenda[i];
                            return Card(
                              child: ListTile(
                                title: Text('${m.equipo1} vs ${m.equipo2}'),
                                subtitle: Text('${m.hora} · ${m.fecha}'),
                                trailing: _StatusChip(status: m.estado),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const names = <String>[
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            '${names[month.month - 1]} ${month.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.markers,
    required this.onSelectDay,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final Map<DateTime, List<MatchModel>> markers;
  final void Function(DateTime day) onSelectDay;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final firstWeekday = firstDay.weekday;
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    final cells = <Widget>[];
    const week = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    for (final dayName in week) {
      cells.add(Center(
        child: Text(dayName, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white70)),
      ));
    }

    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final current = DateTime(focusedMonth.year, focusedMonth.month, d);
      final key = DateTime(current.year, current.month, current.day);
      final selected = selectedDay.year == current.year && selectedDay.month == current.month && selectedDay.day == current.day;
      final hasMatches = markers[key]?.isNotEmpty ?? false;

      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelectDay(current),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFC2A679) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$d',
                  style: TextStyle(
                    color: selected ? const Color(0xFF111111) : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hasMatches)
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF111111) : const Color(0xFFC2A679),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childAspectRatio: 1.55,
      children: cells,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'En Juego':
        color = const Color(0xFF7CB342);
      case 'Finalizado':
        color = const Color(0xFFC2A679);
      default:
        color = const Color(0xFF42A5F5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
