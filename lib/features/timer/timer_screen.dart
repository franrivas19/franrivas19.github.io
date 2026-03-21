import 'dart:async';

import 'package:flutter/material.dart';

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

const Color _colorOscuro = Color(0xFF2B2B2B);
const Color _colorClaro = Color(0xFF9FE7F5);
const Color _colorFondoApp = Color(0xFFF8F8F8);
const Color _colorRojo = Color(0xFFFF3B5C);
const Color _colorRosa = Color(0xFFFF6B9D);
const Color _colorTituloGris = Color(0xFF2B2B2B);
const Color _colorTimerFondo = Color(0xFFFAD5C8);
const Color _colorTimerTexto = Color(0xFF2F5156);

class TimerTurnosScreen extends StatefulWidget {
  const TimerTurnosScreen({super.key});

  @override
  State<TimerTurnosScreen> createState() => _TimerTurnosScreenState();
}

class _TimerTurnosScreenState extends State<TimerTurnosScreen> {
  static const String _fontFamily = 'Oswald';

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
    return Scaffold(
      backgroundColor: _colorFondoApp,
      body: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: _fontFamily, color: _colorTituloGris),
          child: switch (_fase) {
            FaseTurno.seleccionarDeporte => _buildSeleccionDeporte(),
            FaseTurno.seleccionarEquipos => _buildSeleccionEquipos(),
            FaseTurno.jugando => _buildJugando(),
          },
        ),
      ),
    );
  }

  Widget _buildSeleccionDeporte() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: _colorClaro,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: const Text(
              'TURNOS',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontFamily: _fontFamily,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...Deporte.values.map(_sportButton),
        ],
      ),
    );
  }

  Widget _sportButton(Deporte deporte) {
    final colorFondo = switch (deporte) {
      Deporte.futsal => const Color(0xFFC5BEE6),
      Deporte.fut7 => const Color(0xFF00FF00),
      Deporte.fut11 => const Color(0xFF8FB89F),
    };

    final alphaValue = switch (deporte) {
      Deporte.futsal => 0.9,
      Deporte.fut7 => 0.6,
      Deporte.fut11 => 0.9,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _seleccionarDeporte(deporte),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 130,
                color: colorFondo.withValues(alpha: alphaValue),
                alignment: Alignment.center,
                child: switch (deporte) {
                  Deporte.fut11 => Opacity(
                      opacity: alphaValue,
                      child: Image.asset(
                        'assets/fut_11.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'ADD assets/fut_11.png',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  _ => const Text(
                      'IMAGE PLACEHOLDER',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                },
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: deporte.deporteNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontFamily: _fontFamily,
                        shadows: [
                          Shadow(
                            color: Color.fromRGBO(0, 0, 0, 0.25),
                            offset: Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: deporte.numeroNombre,
                      style: const TextStyle(
                        color: _colorRosa,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontFamily: _fontFamily,
                        shadows: [
                          Shadow(
                            color: Color.fromRGBO(0, 0, 0, 0.25),
                            offset: Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
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

  Widget _buildSeleccionEquipos() {
    final deporte = _deporte!;
    final disponibles = _usuariosDisponibles;
    final equiposCompletos = _equipoOscuro.length == deporte.requeridasPorEquipo &&
        _equipoClaro.length == deporte.requeridasPorEquipo;

    if (_jugadorActual == null && disponibles.isNotEmpty) {
      _jugadorActual = disponibles.first;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _colorClaro,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: _colorTituloGris,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: _fontFamily,
                  shadows: [
                    Shadow(
                      color: Color.fromRGBO(0, 0, 0, 0.3),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                children: [
                  const TextSpan(text: 'TURNOS '),
                  TextSpan(text: deporte.deporteNombre, style: const TextStyle(color: Colors.white)),
                  TextSpan(text: deporte.numeroNombre, style: const TextStyle(color: _colorRosa)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (equiposCompletos) ...[
                Expanded(
                  child: SizedBox(
                    height: 100,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: _iniciarJuego,
                      child: const Text(
                        'INICIAR',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: _fontFamily,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 100,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colorRojo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: _reiniciar,
                      child: const Text(
                        'REINICIAR',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: _fontFamily,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: _cajaSeleccionGigante(
                    nombre: _jugadorActual?.nombre ?? '---',
                    colorFondo: Colors.white,
                    colorTexto: Colors.black,
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
                const SizedBox(width: 16),
                Expanded(
                  child: _cajaSeleccionGigante(
                    nombre: _jugadorActual?.nombre ?? '---',
                    colorFondo: _colorOscuro,
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
            const SizedBox(height: 20),
            const Text(
              'JUGADORES',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: _fontFamily),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: disponibles
                    .map(
                      (usuario) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _jugadorActual = usuario),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              usuario.nombre,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: _fontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _contenedorEquipo(
            titulo: 'OSCURO',
            colorCabecera: _colorOscuro,
            colorTextoCabecera: Colors.white,
            jugadores: _equipoOscuro,
            capacidad: deporte.requeridasPorEquipo,
            colorCelda: const Color(0xFF3D3D3D),
            onQuitar: (usuario) => setState(() => _equipoOscuro = _equipoOscuro.where((u) => u.id != usuario.id).toList()),
          ),
          const SizedBox(height: 20),
          _contenedorEquipo(
            titulo: 'CLARO',
            colorCabecera: _colorClaro,
            colorTextoCabecera: Colors.black,
            jugadores: _equipoClaro,
            capacidad: deporte.requeridasPorEquipo,
            colorCelda: const Color(0xFFB2EBF2),
            onQuitar: (usuario) => setState(() => _equipoClaro = _equipoClaro.where((u) => u.id != usuario.id).toList()),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _cajaSeleccionGigante({
    required String nombre,
    required Color colorFondo,
    required Color colorTexto,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: 100,
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.22),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              nombre,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorTexto,
                fontFamily: _fontFamily,
                shadows: const [
                  Shadow(
                    color: Color.fromRGBO(0, 0, 0, 0.25),
                    offset: Offset(0, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
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
    required Color colorCelda,
    required void Function(Usuario) onQuitar,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorCelda.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorCabecera,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              titulo,
              style: TextStyle(
                color: colorTextoCabecera,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 2,
                fontFamily: _fontFamily,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(capacidad, (index) {
                final jugador = jugadores.length > index ? jugadores[index] : null;
                return _celdaEstiloFigma(
                  jugador: jugador,
                  index: index + 1,
                  colorFondo: colorCabecera,
                  onTap: () {
                    if (jugador != null) {
                      onQuitar(jugador);
                    }
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _celdaEstiloFigma({
    required Usuario? jugador,
    required int index,
    required Color colorFondo,
    required VoidCallback onTap,
  }) {
    final tieneJugador = jugador != null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: tieneJugador ? onTap : null,
      child: Container(
        height: 65,
        width: 85,
        decoration: BoxDecoration(
          color: tieneJugador ? colorFondo : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: tieneJugador
            ? Text(
                jugador.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorFondo == _colorOscuro ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: _fontFamily,
                ),
              )
            : Text(
                '$index',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorFondo.withValues(alpha: 0.2),
                  fontFamily: _fontFamily,
                ),
              ),
      ),
    );
  }

  Widget _buildJugando() {
    final deporte = _deporte!;
    final jugadorOscuro = _equipoOscuro.length > _indiceTurno ? _equipoOscuro[_indiceTurno] : null;
    final jugadorClaro = _equipoClaro.length > _indiceTurno ? _equipoClaro[_indiceTurno] : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _colorClaro,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: _colorTituloGris,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: _fontFamily,
                ),
                children: [
                  const TextSpan(text: 'TURNOS '),
                  TextSpan(text: deporte.deporteNombre),
                  TextSpan(
                    text: deporte.numeroNombre,
                    style: const TextStyle(color: _colorRosa, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: _colorTimerFondo,
              borderRadius: BorderRadius.circular(40),
            ),
            alignment: Alignment.center,
            child: Text(
              _formatearTiempo(_segundos),
              style: const TextStyle(
                fontSize: 88,
                fontWeight: FontWeight.bold,
                color: _colorTimerTexto,
                letterSpacing: 2,
                fontFamily: _fontFamily,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    jugadorClaro?.nombre ?? '-',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _colorTituloGris,
                      fontFamily: _fontFamily,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: _colorOscuro,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    jugadorOscuro?.nombre ?? '-',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: _fontFamily,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_segundos == 0)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorRojo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: _siguienteTurno,
                child: const Text(
                  'SIGUIENTE TURNO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: _fontFamily,
                  ),
                ),
              ),
            ),
          if (_segundos == 0) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _colorRojo),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _reiniciar,
              child: const Text(
                'REINICIAR',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _colorRojo,
                  fontFamily: _fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }
}
