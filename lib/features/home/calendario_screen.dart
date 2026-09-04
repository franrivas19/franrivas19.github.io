import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/date_utils.dart';
import '../common/app_bottom_nav.dart';

enum _CalendarView { semana, mes, ano }

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  static const _gold = Color(0xFFC2A679);
  static const _black = Color(0xFF111111);

  final _service = FirestoreService();
  DateTime _selectedDay = _dayOnly(DateTime.now());
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  _CalendarView _view = _CalendarView.mes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      appBar: AppBar(
        title: const Text(
          'CALENDARIO',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: _black,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: -1),
      body: StreamBuilder<List<MatchModel>>(
        stream: _service.allMatchesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _gold));
          }

          final matches = snapshot.data ?? const <MatchModel>[];
          final byDay = _matchesByDay(matches);
          final selectedMatches =
              (byDay[_selectedDay] ?? const <MatchModel>[]).toList()
                ..sort(_compareMatches);

          return Column(
            children: [
              _Tabs(
                selected: _view,
                onChanged: (value) => setState(() => _view = value),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: switch (_view) {
                  _CalendarView.ano => _YearAgenda(
                    matches: matches,
                    onOpen: _openMatch,
                  ),
                  _CalendarView.mes => _buildMonthView(byDay, selectedMatches),
                  _CalendarView.semana => _buildWeekView(
                    byDay,
                    selectedMatches,
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthView(
    Map<DateTime, List<MatchModel>> byDay,
    List<MatchModel> selectedMatches,
  ) {
    return Column(
      children: [
        _MonthHeader(
          month: _focusedMonth,
          onPrev:
              () => setState(
                () =>
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    ),
              ),
          onNext:
              () => setState(
                () =>
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    ),
              ),
        ),
        const SizedBox(height: 12),
        const _WeekdayRow(),
        const SizedBox(height: 8),
        _MonthGrid(
          month: _focusedMonth,
          selectedDay: _selectedDay,
          markers: byDay,
          onSelect:
              (day) => setState(() {
                _selectedDay = day;
                _focusedMonth = DateTime(day.year, day.month);
              }),
        ),
        const SizedBox(height: 18),
        const Divider(color: Colors.white24),
        _AgendaList(
          title: 'AGENDA - ${_formatDate(_selectedDay)}',
          matches: selectedMatches,
          onOpen: _openMatch,
        ),
      ],
    );
  }

  Widget _buildWeekView(
    Map<DateTime, List<MatchModel>> byDay,
    List<MatchModel> selectedMatches,
  ) {
    final monday = _selectedDay.subtract(
      Duration(days: _selectedDay.weekday - 1),
    );
    final week = List.generate(
      7,
      (i) => _dayOnly(monday.add(Duration(days: i))),
    );

    return Column(
      children: [
        _MonthHeader(
          month: DateTime(_selectedDay.year, _selectedDay.month),
          onPrev:
              () => setState(
                () =>
                    _selectedDay = _selectedDay.subtract(
                      const Duration(days: 7),
                    ),
              ),
          onNext:
              () => setState(
                () => _selectedDay = _selectedDay.add(const Duration(days: 7)),
              ),
          prevIcon: Icons.chevron_left,
          nextIcon: Icons.chevron_right,
        ),
        const SizedBox(height: 12),
        const _WeekdayRow(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children:
                week.map((day) {
                  return Expanded(
                    child: _DayCell(
                      day: day,
                      selected: day == _selectedDay,
                      today: day == _dayOnly(DateTime.now()),
                      hasMatches: byDay[day]?.isNotEmpty ?? false,
                      onTap:
                          () => setState(() {
                            _selectedDay = day;
                            _focusedMonth = DateTime(day.year, day.month);
                          }),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 22),
        const Divider(color: Colors.white24),
        _AgendaList(
          title: 'AGENDA - ${_formatDate(_selectedDay)}',
          matches: selectedMatches,
          onOpen: _openMatch,
        ),
      ],
    );
  }

  Map<DateTime, List<MatchModel>> _matchesByDay(List<MatchModel> matches) {
    final grouped = <DateTime, List<MatchModel>>{};
    for (final match in matches) {
      final date = parseMatchDateTime(match.fecha, match.hora);
      if (date == null) {
        continue;
      }
      final day = _dayOnly(date);
      grouped.putIfAbsent(day, () => <MatchModel>[]).add(match);
    }
    return grouped;
  }

  int _compareMatches(MatchModel a, MatchModel b) {
    final aDate = parseMatchDateTime(a.fecha, a.hora);
    final bDate = parseMatchDateTime(b.fecha, b.hora);
    if (aDate != null && bDate != null) {
      return aDate.compareTo(bDate);
    }
    return a.hora.compareTo(b.hora);
  }

  void _openMatch(MatchModel match) {
    if (match.estado == 'Finalizado') {
      context.push('/ver-acta/${match.id}');
    } else if (match.estado == 'En Juego') {
      context.push('/live-score/${match.id}');
    }
  }

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onChanged});

  final _CalendarView selected;
  final ValueChanged<_CalendarView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _CalendarioScreenState._black,
      child: Row(
        children:
            _CalendarView.values.map((view) {
              final isSelected = selected == view;
              final label = switch (view) {
                _CalendarView.semana => 'SEMANA',
                _CalendarView.mes => 'MES',
                _CalendarView.ano => 'AÑO',
              };

              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(view),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              isSelected
                                  ? _CalendarioScreenState._gold
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            isSelected
                                ? _CalendarioScreenState._gold
                                : Colors.grey,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    this.prevIcon = Icons.chevron_left,
    this.nextIcon = Icons.chevron_right,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final IconData prevIcon;
  final IconData nextIcon;

  @override
  Widget build(BuildContext context) {
    const months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: Icon(prevIcon, color: Colors.white),
        ),
        Expanded(
          child: Text(
            '${months[month.month - 1]} ${month.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(nextIcon, color: Colors.white),
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children:
            const ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.markers,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selectedDay;
  final Map<DateTime, List<MatchModel>> markers;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = <Widget>[];

    for (var i = 1; i < first.weekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      cells.add(
        _DayCell(
          day: date,
          selected: date == selectedDay,
          today: date == _CalendarioScreenState._dayOnly(DateTime.now()),
          hasMatches: markers[date]?.isNotEmpty ?? false,
          onTap: () => onSelect(date),
        ),
      );
    }
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: cells,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.hasMatches,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final bool hasMatches;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg =
        selected
            ? _CalendarioScreenState._gold
            : (today ? Colors.grey.shade800 : Colors.transparent);
    final fg = selected ? Colors.black : Colors.white;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  color: fg,
                  fontWeight:
                      selected || today ? FontWeight.w900 : FontWeight.w500,
                ),
              ),
              if (hasMatches)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : const Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({
    required this.title,
    required this.matches,
    required this.onOpen,
  });

  final String title;
  final List<MatchModel> matches;
  final ValueChanged<MatchModel> onOpen;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child:
                matches.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No hay partidos programados para este día.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: matches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder:
                          (context, index) => _MatchAgendaCard(
                            match: matches[index],
                            onTap: () => onOpen(matches[index]),
                          ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _YearAgenda extends StatelessWidget {
  const _YearAgenda({required this.matches, required this.onOpen});

  final List<MatchModel> matches;
  final ValueChanged<MatchModel> onOpen;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(
        child: Text(
          'Aún no hay partidos en el registro.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final groups = <String, List<MatchModel>>{};
    for (final match in matches) {
      final dt = parseMatchDateTime(match.fecha, match.hora);
      if (dt == null) {
        continue;
      }
      final key = '${_monthName(dt.month)} ${dt.year}';
      groups.putIfAbsent(key, () => <MatchModel>[]).add(match);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children:
          groups.entries.expand((entry) {
            return [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: _CalendarioScreenState._gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ...entry.value.map(
                (match) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MatchAgendaCard(
                    match: match,
                    onTap: () => onOpen(match),
                  ),
                ),
              ),
            ];
          }).toList(),
    );
  }

  String _monthName(int month) {
    const names = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return names[month - 1];
  }
}

class _MatchAgendaCard extends StatelessWidget {
  const _MatchAgendaCard({required this.match, required this.onTap});

  final MatchModel match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final clickable =
        match.estado == 'Finalizado' || match.estado == 'En Juego';
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: clickable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.hora,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _StatusPill(status: match.estado),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _abbr(match.equipo1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (match.estado == 'Finalizado' ||
                        match.estado == 'En Juego')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${match.goles1} - ${match.goles2}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      )
                    else
                      const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      _abbr(match.equipo2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _abbr(String value) {
    final trimmed = value.trim();
    return trimmed.length <= 3
        ? trimmed.toUpperCase()
        : trimmed.substring(0, 3).toUpperCase();
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final finished = status == 'Finalizado';
    final live = status == 'En Juego';
    final color =
        finished
            ? const Color(0xFF43A047)
            : (live ? const Color(0xFFE53935) : _CalendarioScreenState._gold);
    final label = finished ? 'FINAL' : (live ? 'LIVE' : 'PROX.');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
