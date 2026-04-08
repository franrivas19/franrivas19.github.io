import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/match_model.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/date_utils.dart';

class ProximoPartidoCard extends StatefulWidget {
  const ProximoPartidoCard({
    super.key,
    required this.match,
    this.onTap,
  });

  final MatchModel match;
  final VoidCallback? onTap;

  @override
  State<ProximoPartidoCard> createState() => _ProximoPartidoCardState();
}

class _ProximoPartidoCardState extends State<ProximoPartidoCard> {
  Timer? _timer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final target = parseMatchDateTime(widget.match.fecha, widget.match.hora);
    if (target == null) {
      return;
    }
    final now = DateTime.now();

    setState(() {
      _remaining = target.difference(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final started = remaining != null && remaining.isNegative;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onTap,
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF222222), Colors.black],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.dorado.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'PROXIMO ENCUENTRO',
                  style: TextStyle(
                    color: AppColors.dorado,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _TeamBlock(name: widget.match.equipo1, color: widget.match.color1)),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.dorado,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('VS', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  Expanded(child: _TeamBlock(name: widget.match.equipo2, color: widget.match.color2)),
                ],
              ),
              const SizedBox(height: 18),
              if (started)
                const Text(
                  'EL PARTIDO ESTA EN JUEGO',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900),
                )
              else
                _Countdown(remaining: remaining ?? Duration.zero),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📍 ${widget.match.ubicacion}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('📅 ${widget.match.fecha} - ⏰ ${widget.match.hora}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UltimoPartidoCard extends StatelessWidget {
  const UltimoPartidoCard({
    super.key,
    required this.match,
    this.onTap,
  });

  final MatchModel match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ULTIMO RESULTADO', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey)),
                  Text(match.fecha, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _SmallTeam(name: match.equipo1, colorName: match.color1)),
                  Text('${match.goles1}', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('VS', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey)),
                  ),
                  Text('${match.goles2}', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                  Expanded(child: _SmallTeam(name: match.equipo2, colorName: match.color2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({required this.name, required this.color});

  final String name;
  final String color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.fromColorName(color);
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.dorado, width: 2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SmallTeam extends StatelessWidget {
  const _SmallTeam({required this.name, required this.colorName});

  final String name;
  final String colorName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.shield, color: AppColors.fromColorName(colorName), size: 28),
        Text(name.substring(0, name.length.clamp(0, 3)).toUpperCase()),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final mins = remaining.inMinutes % 60;
    final secs = remaining.inSeconds % 60;

    Widget unit(int v, String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.dorado.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(v.toString().padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        unit(days, 'DIAS'),
        const SizedBox(width: 6),
        unit(hours, 'HRS'),
        const SizedBox(width: 6),
        unit(mins, 'MIN'),
        const SizedBox(width: 6),
        unit(secs, 'SEG'),
      ],
    );
  }
}
