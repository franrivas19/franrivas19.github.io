import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/match_model.dart';
import '../../core/models/player_stat.dart';
import '../../core/services/firestore_service.dart';

class ActaScreen extends StatefulWidget {
  const ActaScreen({super.key});

  @override
  State<ActaScreen> createState() => _ActaScreenState();
}

class _ActaScreenState extends State<ActaScreen> {
  final _service = FirestoreService();
  final _db = FirebaseFirestore.instance;

  bool _loading = true;
  bool _saving = false;

  MatchModel? _match;
  List<PlayerStat> _stats = [];
  int _goles1 = 0;
  int _goles2 = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final matchQuery = await _db
          .collection('partidos')
          .where('estado', whereIn: ['Pendiente', 'En Juego'])
          .limit(1)
          .get();

      if (matchQuery.docs.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final doc = matchQuery.docs.first;
      final match = MatchModel.fromMap(doc.id, doc.data());

      final eventosSnap = await doc.reference.collection('eventos_live').get();
      final recuentoGoles = <String, int>{};
      final recuentoAsistencias = <String, int>{};

      for (final ev in eventosSnap.docs) {
        final data = ev.data();
        final idGoleador = data['idGoleador'] as String?;
        final idAsistente = data['idAsistente'] as String?;

        if (idGoleador != null) {
          recuentoGoles[idGoleador] = (recuentoGoles[idGoleador] ?? 0) + 1;
        }
        if (idAsistente != null) {
          recuentoAsistencias[idAsistente] = (recuentoAsistencias[idAsistente] ?? 0) + 1;
        }
      }

      final usersSnap = await _db.collection('usuarios').get();
      final conv1 = match.convocatoria1;
      final conv2 = match.convocatoria2;

      final listaStats = usersSnap.docs
          .mapNotNull((d) {
            final uid = d.id;
            if (conv1.contains(uid) || conv2.contains(uid)) {
              return PlayerStat(
                id: uid,
                nombre: (d.data()['nombre'] as String?) ?? 'Jugador',
                goles: recuentoGoles[uid] ?? 0,
                asistencias: recuentoAsistencias[uid] ?? 0,
                haJugado: true,
                equipo: conv1.contains(uid) ? 1 : 2,
              );
            }
            return null;
          })
          .toList()
        ..sort((a, b) => a.equipo.compareTo(b.equipo));

      setState(() {
        _match = match;
        _goles1 = match.goles1;
        _goles2 = match.goles2;
        _stats = listaStats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando acta: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveActa() async {
    setState(() => _saving = true);
    try {
      await _service.closeActa(
        matchId: _match!.id,
        goles1: _goles1,
        goles2: _goles2,
        stats: _stats.where((s) => s.haJugado).toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Acta cerrada y estadísticas actualizadas!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cerrar Acta')),
        body: const Center(child: Text('No hay ningún partido pendiente.')),
      );
    }

    if (_match!.convocatoria1.isEmpty && _match!.convocatoria2.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E7),
      appBar: AppBar(
        title: const Text('Cerrar Acta Oficial', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF5F1E7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildScoreboard(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Text(
              'RENDIMIENTO DE JUGADORES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ..._stats.asMap().entries.map((entry) => _buildPlayerCard(entry.key, entry.value)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFFF5F1E7), elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('⚠️', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text('¡Alineaciones vacías!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              SizedBox(height: 8),
              Text(
                'Debes configurar la convocatoria pulsando en la tarjeta del próximo partido antes de rellenar el acta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreboard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'RESULTADO FINAL',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _teamControl(
                  _match!.equipo1,
                  _goles1,
                  (v) => setState(() => _goles1 = v),
                  const Color(0xFF1E88E5),
                ),
                const Text('VS', style: TextStyle(color: Color(0xFFC2A679), fontWeight: FontWeight.bold, fontSize: 24)),
                _teamControl(
                  _match!.equipo2,
                  _goles2,
                  (v) => setState(() => _goles2 = v),
                  const Color(0xFFE53935),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamControl(String name, int score, Function(int) onUpdate, Color color) {
    final abbr = name.substring(0, name.length.clamp(0, 3)).toUpperCase();
    return Column(
      children: [
        Text(abbr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        Row(
          children: [
            IconButton(onPressed: score > 0 ? () => onUpdate(score - 1) : null, icon: const Icon(Icons.remove)),
            Text('$score', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => onUpdate(score + 1), icon: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerCard(int index, PlayerStat player) {
    final teamColor = player.equipo == 1 ? const Color(0xFF1E88E5) : const Color(0xFFE53935);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: player.haJugado
            ? BorderSide(color: teamColor.withValues(alpha: 0.5), width: 2)
            : BorderSide.none,
      ),
      color: player.haJugado ? Colors.white : const Color(0xFFE0E0E0),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: player.haJugado,
                  activeColor: teamColor,
                  onChanged: (val) {
                    setState(() => _stats[index] = player.copyWith(haJugado: val ?? true));
                  },
                ),
                Text(
                  player.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: player.haJugado ? Colors.black : Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  player.equipo == 1 ? 'LOC' : 'VIS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: teamColor),
                ),
              ],
            ),
            if (player.haJugado)
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statStepper(
                      '⚽ Goles:',
                      player.goles,
                      (v) => setState(() => _stats[index] = player.copyWith(goles: v)),
                      teamColor,
                    ),
                    _statStepper(
                      '👟 Asist:',
                      player.asistencias,
                      (v) => setState(() => _stats[index] = player.copyWith(asistencias: v)),
                      Colors.black,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statStepper(String label, int value, Function(int) onUpdate, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: value > 0 ? () => onUpdate(value - 1) : null,
          icon: const Icon(Icons.remove, size: 16),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
        Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        IconButton(
          onPressed: () => onUpdate(value + 1),
          icon: const Icon(Icons.add, size: 16),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: _saving ? null : _saveActa,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _saving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'GUARDAR ACTA',
                style: TextStyle(
                  color: Color(0xFFC2A679),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }
}

extension MapNotNull<T> on Iterable<T> {
  Iterable<R> mapNotNull<R>(R? Function(T) transform) sync* {
    for (final element in this) {
      final transformed = transform(element);
      if (transformed != null) {
        yield transformed;
      }
    }
  }
}
