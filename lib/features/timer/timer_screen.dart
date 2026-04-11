import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/firestore_service.dart';

class Usuario {
  const Usuario({required this.id, required this.nombre});

  final int id;
  final String nombre;
}

enum FaseTurno {
  seleccionarDeporte,
  seleccionarEquipos,
  jugando,
}

enum Deporte {
  futsal(5, 'FUT', 'SAL'),
  fut7(7, 'FUT', '7'),
  fut11(11, 'FUT', '11');

  const Deporte(this.requeridasPorEquipo, this.deporteNombre, this.numeroNombre);

  final int requeridasPorEquipo;
  final String deporteNombre;
  final String numeroNombre;
}

const List<Usuario> _usuariosHardcode = [
  Usuario(id: 1, nombre: 'JUAN'),
  Usuario(id: 2, nombre: 'PEDRO'),
  Usuario(id: 3, nombre: 'LUIS'),
  Usuario(id: 4, nombre: 'MARIO'),
  Usuario(id: 5, nombre: 'DIEGO'),
  Usuario(id: 6, nombre: 'RUBEN'),
  Usuario(id: 7, nombre: 'NICO'),
  Usuario(id: 8, nombre: 'TONI'),
  Usuario(id: 9, nombre: 'SERGIO'),
  Usuario(id: 10, nombre: 'ANDRES'),
  Usuario(id: 11, nombre: 'ISRA'),
  Usuario(id: 12, nombre: 'JOSE ROMERO'),
  Usuario(id: 13, nombre: 'FRAN R.'),
  Usuario(id: 14, nombre: 'BB'),
  Usuario(id: 15, nombre: 'AA'),
  Usuario(id: 16, nombre: 'KK'),
];

const Color _colorEquipoOscuro = Color(0xFF1E1E1E);
const Color _colorError = Color(0xFFEF4444);

class TimerTurnosScreen extends StatefulWidget {
  const TimerTurnosScreen({super.key});

  @override
  State<TimerTurnosScreen> createState() => _TimerTurnosScreenState();
}

class _TimerTurnosScreenState extends State<TimerTurnosScreen> {
  final _service = FirestoreService();
  Deporte? _deporte;
  FaseTurno _fase = FaseTurno.seleccionarDeporte;
  List<Usuario> _equipoOscuro = [];
  List<Usuario> _equipoClaro = [];
  Usuario? _jugadorActual;

  int _indiceTurno = 0;
  int _segundos = 360;
  bool _timerActivo = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reiniciar() {
    _timer?.cancel();
    setState(() {
      _deporte = null;
      _fase = FaseTurno.seleccionarDeporte;
      _equipoOscuro = [];
      _equipoClaro = [];
      _jugadorActual = null;
      _indiceTurno = 0;
      _segundos = 360;
      _timerActivo = false;
    });
  }

  void _iniciarJuego() {
    final deporte = _deporte;
    if (deporte == null) {
      return;
    }

    if (_equipoOscuro.length == deporte.requeridasPorEquipo &&
        _equipoClaro.length == deporte.requeridasPorEquipo) {
      setState(() {
        _fase = FaseTurno.jugando;
        _timerActivo = true;
        _segundos = 360;
        _indiceTurno = 0;
      });
      _ensureTimerState();
    }
  }

  void _ensureTimerState() {
    _timer?.cancel();
    if (!(_fase == FaseTurno.jugando && _timerActivo && _segundos > 0)) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!(_fase == FaseTurno.jugando && _timerActivo && _segundos > 0)) {
        timer.cancel();
        return;
      }

      setState(() {
        _segundos--;
        if (_segundos == 0) {
          _timerActivo = false;
          timer.cancel();
        }
      });
    });
  }

  void _siguienteTurno() {
    final deporte = _deporte;
    if (deporte == null) {
      return;
    }

    setState(() {
      _indiceTurno = (_indiceTurno + 1) % deporte.requeridasPorEquipo;
      _segundos = 360;
      _timerActivo = true;
    });
    _ensureTimerState();
  }

  List<Usuario> get _usuariosDisponibles {
    final deporte = _deporte;
    if (deporte == null) {
      return [];
    }

    return _usuariosHardcode
        .take(deporte.requeridasPorEquipo * 2)
        .where((u) => !_equipoOscuro.contains(u) && !_equipoClaro.contains(u))
        .toList();
  }

  Usuario? _nextJugadorActual(Usuario? actual, List<Usuario> disponibles) {
    if (disponibles.isEmpty) {
      return null;
    }

    if (actual == null) {
      return disponibles.first;
    }

    final index = disponibles.indexWhere((u) => u.id == actual.id);
    if (index == -1) {
      return disponibles.first;
    }
    return disponibles[(index + 1) % disponibles.length];
  }

  void _seleccionarDeporte(Deporte deporte) {
    setState(() {
      _deporte = deporte;
      _fase = FaseTurno.seleccionarEquipos;
      _equipoOscuro = [];
      _equipoClaro = [];
      _indiceTurno = 0;
      _segundos = 360;
      _timerActivo = false;
      _jugadorActual = _usuariosHardcode.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('TURNOS'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: StreamBuilder(
        stream: _service.inGameMatch(),
        builder: (context, snapshot) {
          final inGame = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (inGame == null) {
            return _buildBallonParado();
          }
          return SafeArea(
            child: switch (_fase) {
              FaseTurno.seleccionarDeporte => _buildSeleccionDeporte(),
              FaseTurno.seleccionarEquipos => _buildSeleccionEquipos(),
              FaseTurno.jugando => _buildJugando(),
            },
          );
        },
      ),
      );
  }

  Widget _buildBallonParado() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0x66C2A679), Color(0x00111111)],
                radius: 0.95,
              ),
              border: Border.all(color: const Color(0x88C2A679)),
            ),
            alignment: Alignment.center,
            child: const Text(
              '⚽',
              style: TextStyle(fontSize: 54),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'EL BALON ESTA PARADO',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF1A1A1A),
            ),
            child: CustomPaint(
              painter: _TacticalBoardPainter(),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No hay partidos en juego ahora mismo.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Si eres administrador, crea o inicia un partido. Si eres jugador, toca descansar hasta el siguiente pitido.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeleccionDeporte() {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Selecciona el formato del partido',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...Deporte.values.map(_sportButton),
      ],
    );
  }

  Widget _buildSectionTitle(Deporte deporte) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Turnos ${deporte.deporteNombre}${deporte.numeroNombre}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${deporte.requeridasPorEquipo}x${deporte.requeridasPorEquipo}',
                style: TextStyle(
                  color: scheme.tertiary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sportButton(Deporte deporte) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colorFondo = switch (deporte) {
      Deporte.futsal => scheme.secondary,
      Deporte.fut7 => scheme.primary,
      Deporte.fut11 => scheme.tertiary,
    };

    final imageAsset = switch (deporte) {
      Deporte.fut11 => 'assets/fut_11.png',
      Deporte.fut7 => 'assets/fut_7.png',
      Deporte.futsal => 'assets/fut_sala.png',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _seleccionarDeporte(deporte),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: SizedBox(
            height: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: colorFondo.withValues(alpha: 0.85),
                  ),
                ),
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.32),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${deporte.deporteNombre}${deporte.numeroNombre}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.surface, size: 28),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeleccionEquipos() {
    final deporte = _deporte!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disponibles = _usuariosDisponibles;
    final equiposCompletos = _equipoOscuro.length == deporte.requeridasPorEquipo &&
        _equipoClaro.length == deporte.requeridasPorEquipo;

    if (_jugadorActual == null && disponibles.isNotEmpty) {
      _jugadorActual = disponibles.first;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle(deporte),
        const SizedBox(height: 12),
        Row(
          children: [
            if (equiposCompletos) ...[
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _iniciarJuego,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('INICIAR'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _colorError),
                    ),
                    onPressed: _reiniciar,
                    icon: const Icon(Icons.restart_alt, color: _colorError),
                    label: const Text(
                      'REINICIAR',
                      style: TextStyle(color: _colorError),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: _cajaSeleccion(
                  titulo: 'CLARO',
                  nombre: _jugadorActual?.nombre ?? '---',
                  colorFondo: scheme.surface,
                  colorTexto: scheme.tertiary,
                  onTap: () {
                    final actual = _jugadorActual;
                    if (actual == null) {
                      return;
                    }
                    setState(() {
                      if (_equipoClaro.length < deporte.requeridasPorEquipo) {
                        _equipoClaro = [..._equipoClaro, actual];
                      }
                      _jugadorActual = _nextJugadorActual(actual, _usuariosDisponibles);
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _cajaSeleccion(
                  titulo: 'OSCURO',
                  nombre: _jugadorActual?.nombre ?? '---',
                  colorFondo: _colorEquipoOscuro,
                  colorTexto: Colors.white,
                  onTap: () {
                    final actual = _jugadorActual;
                    if (actual == null) {
                      return;
                    }
                    setState(() {
                      if (_equipoOscuro.length < deporte.requeridasPorEquipo) {
                        _equipoOscuro = [..._equipoOscuro, actual];
                      }
                      _jugadorActual = _nextJugadorActual(actual, _usuariosDisponibles);
                    });
                  },
                ),
              ),
            ],
          ],
        ),
        if (disponibles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Jugadores disponibles',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: disponibles.map((usuario) {
                final isSelected = _jugadorActual?.id == usuario.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selectedColor: scheme.primary.withValues(alpha: 0.18),
                    side: BorderSide(color: isSelected ? scheme.primary : Colors.transparent),
                    label: Text(usuario.nombre),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _jugadorActual = usuario),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _contenedorEquipo(
          titulo: 'OSCURO',
          colorCabecera: _colorEquipoOscuro,
          colorTextoCabecera: Colors.white,
          jugadores: _equipoOscuro,
          capacidad: deporte.requeridasPorEquipo,
          onQuitar: (usuario) => setState(() => _equipoOscuro = _equipoOscuro.where((u) => u.id != usuario.id).toList()),
        ),
        const SizedBox(height: 12),
        _contenedorEquipo(
          titulo: 'CLARO',
          colorCabecera: scheme.primary.withValues(alpha: 0.15),
          colorTextoCabecera: scheme.tertiary,
          jugadores: _equipoClaro,
          capacidad: deporte.requeridasPorEquipo,
          onQuitar: (usuario) => setState(() => _equipoClaro = _equipoClaro.where((u) => u.id != usuario.id).toList()),
        ),
      ],
    );
  }

  Widget _cajaSeleccion({
    required String titulo,
    required String nombre,
    required Color colorFondo,
    required Color colorTexto,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorFondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 110,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: colorTexto.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  nombre,
                  maxLines: 2,
                  style: TextStyle(
                    color: colorTexto,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenedorEquipo({
    required String titulo,
    required Color colorCabecera,
    required Color colorTextoCabecera,
    required List<Usuario> jugadores,
    required int capacidad,
    required void Function(Usuario) onQuitar,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: colorCabecera,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      color: colorTextoCabecera,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Text(
                  '${jugadores.length}/$capacidad',
                  style: TextStyle(
                    color: colorTextoCabecera.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(capacidad, (index) {
                final jugador = jugadores.length > index ? jugadores[index] : null;

                return _celdaJugador(
                  jugador: jugador,
                  index: index + 1,
                  colorFondo: colorCabecera,
                  onTap: () {
                    if (jugador != null) {
                      onQuitar(jugador);
                    }
                  },
                  placeholderColor: theme.colorScheme.surfaceContainerHighest,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _celdaJugador({
    required Usuario? jugador,
    required int index,
    required Color colorFondo,
    required Color placeholderColor,
    required VoidCallback onTap,
  }) {
    final tieneJugador = jugador != null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: tieneJugador ? onTap : null,
      child: Container(
        height: 62,
        width: 86,
        decoration: BoxDecoration(
          color: tieneJugador ? colorFondo : placeholderColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: tieneJugador
            ? Text(
                jugador.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorFondo.computeLuminance() < 0.4 ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              )
            : Text(
                '$index',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.28),
                ),
              ),
            ),
          );
  }

  Widget _buildJugando() {
    final deporte = _deporte!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final jugadorOscuro = _equipoOscuro.length > _indiceTurno ? _equipoOscuro[_indiceTurno] : null;
    final jugadorClaro = _equipoClaro.length > _indiceTurno ? _equipoClaro[_indiceTurno] : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle(deporte),
        const SizedBox(height: 12),
        Card(
          color: scheme.tertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  'Tiempo restante',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatearTiempo(_segundos),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _jugadorTurnoCard(
                etiqueta: 'CLARO',
                nombre: jugadorClaro?.nombre ?? '-',
                colorFondo: scheme.surface,
                colorTexto: scheme.tertiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _jugadorTurnoCard(
                etiqueta: 'OSCURO',
                nombre: jugadorOscuro?.nombre ?? '-',
                colorFondo: _colorEquipoOscuro,
                colorTexto: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_segundos == 0) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: scheme.primary),
              onPressed: _siguienteTurno,
              icon: const Icon(Icons.skip_next),
              label: const Text('SIGUIENTE TURNO'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _colorError),
            ),
            onPressed: _reiniciar,
            icon: const Icon(Icons.restart_alt, color: _colorError),
            label: const Text(
              'REINICIAR',
              style: TextStyle(color: _colorError),
            ),
          ),
        ),
      ],
    );
  }

  Widget _jugadorTurnoCard({
    required String etiqueta,
    required String nombre,
    required Color colorFondo,
    required Color colorTexto,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: colorFondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 108,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: TextStyle(
                  color: colorTexto.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                nombre,
                maxLines: 2,
                style: TextStyle(
                  color: colorTexto,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }
}

class _TacticalBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      p,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      p,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 22, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
