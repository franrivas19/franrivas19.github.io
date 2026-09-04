import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/sello_trofeo.dart';
import '../common/app_bottom_nav.dart';

const _colorFondoBeige = Color(0xFFF1D28A);
const _colorAcentoBeige = Color(0xFFE0A136);

const _temporadaActualLabel = '26/27 (Actual)';

class PlayerDetailScreen extends StatefulWidget {
  const PlayerDetailScreen({super.key, required this.playerId});

  final String playerId;

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  final _service = FirestoreService();
  String _temporadaSeleccionada = _temporadaActualLabel;
  Map<String, Map<String, dynamic>> _historico = {};
  bool _historicoCargado = false;

  @override
  void initState() {
    super.initState();
    _service.pastSeasons(widget.playerId).then((data) {
      if (mounted) {
        setState(() {
          _historico = data;
          _historicoCargado = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: _service.allUsers(),
      builder: (context, userSnapshot) {
        AppUser? user;
        for (final candidate in (userSnapshot.data ?? <AppUser>[])) {
          if (candidate.id == widget.playerId) {
            user = candidate;
            break;
          }
        }
        if (user == null || !_historicoCargado) {
          return const Scaffold(
            backgroundColor: _colorFondoBeige,
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }
        final u = user;

        return FutureBuilder<int>(
          future: _service.totalFinishedMatches(),
          builder: (context, totalSnap) {
            final total = totalSnap.data ?? 0;
            final esActual = _temporadaSeleccionada == _temporadaActualLabel;
            final datosTemporada = _historico[_temporadaSeleccionada];
            final pjMostrar =
                esActual
                    ? u.pj
                    : (datosTemporada?['pj'] as num?)?.toInt() ?? 0;
            final golesMostrar =
                esActual
                    ? u.goles
                    : (datosTemporada?['goles'] as num?)?.toInt() ?? 0;
            final asistMostrar =
                esActual
                    ? u.asistencias
                    : (datosTemporada?['asistencias'] as num?)?.toInt() ?? 0;
            final valMostrar =
                esActual
                    ? u.valoracion
                    : (datosTemporada?['valoracion'] as num?)?.toDouble() ??
                        0.0;
            final titulosMostrar =
                esActual
                    ? u.listaTitulos
                    : ((datosTemporada?['listaTitulos'] as List<dynamic>?)
                            ?.whereType<String>()
                            .toList() ??
                        const <String>[]);
            final totalTemporada =
                esActual
                    ? total
                    : (datosTemporada?['totalPartidosPenaAnual'] as num?)
                            ?.toInt() ??
                        0;
            final asistencia =
                totalTemporada > 0
                    ? ((pjMostrar / totalTemporada) * 100).round().clamp(
                      0,
                      100,
                    )
                    : 0;
            final particip = golesMostrar + asistMostrar;
            final age =
                u.fechaNacimiento.isNotEmpty
                    ? calculateAge(u.fechaNacimiento)
                    : 0;
            final temporadas = [_temporadaActualLabel, ..._historico.keys];

            return Scaffold(
              backgroundColor: _colorFondoBeige,
              appBar: AppBar(
                backgroundColor: _colorFondoBeige,
                foregroundColor: Colors.black,
                elevation: 0,
                title: Text(
                  u.nombre.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppTheme.oswald,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              bottomNavigationBar: const AppBottomNavBar(selectedIndex: -1),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Container(
                      width: 220,
                      height: 320,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFC2A679),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child:
                          u.fotoUrl.trim().isNotEmpty
                              ? Image.network(
                                u.fotoUrl.trim(),
                                fit: BoxFit.cover,
                              )
                              : const Icon(
                                Icons.person,
                                size: 90,
                                color: Colors.grey,
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (temporadas.length > 1) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _temporadaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Temporada',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          temporadas
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (v) => setState(
                            () =>
                                _temporadaSeleccionada =
                                    v ?? _temporadaActualLabel,
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Tag(text: u.posicion.toUpperCase(), dark: false),
                      const SizedBox(width: 10),
                      _Tag(
                        text: '⭐ ${valMostrar.toStringAsFixed(1)}',
                        dark: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _StatsGrid(
                    items: [
                      _Item('Edad', '$age'),
                      _Item('Partidos', '$pjMostrar'),
                      _Item('Asisten. peña', '$asistencia%'),
                      _Item('Goles', '$golesMostrar'),
                      _Item('Asist.', '$asistMostrar'),
                      _Item('Particip.', '$particip'),
                    ],
                  ),
                  if (titulosMostrar.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 28, bottom: 12, left: 4),
                      child: Text(
                        'PASAPORTE DE SELLOS',
                        style: TextStyle(
                          fontFamily: AppTheme.oswald,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    _PasaporteSellos(titulos: titulosMostrar),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PasaporteSellos extends StatelessWidget {
  const _PasaporteSellos({required this.titulos});

  final List<String> titulos;

  @override
  Widget build(BuildContext context) {
    const columnas = 3;
    const filasMinimas = 2;
    final totalCasillas =
        (filasMinimas * columnas) >
                ((titulos.length + columnas - 1) ~/ columnas) * columnas
            ? filasMinimas * columnas
            : ((titulos.length + columnas - 1) ~/ columnas) * columnas;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnas,
      ),
      itemCount: totalCasillas,
      itemBuilder: (context, i) {
        if (i < titulos.length) {
          return SelloTrofeo(titulo: titulos[i]);
        }
        return const HuecoVacioSello();
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.dark});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: dark ? null : Colors.white,
        gradient:
            dark
                ? const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFFDE08B)],
                )
                : null,
        border: Border.all(
          color: dark ? Colors.black : _colorAcentoBeige,
        ),
        boxShadow:
            dark
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.oswald,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.black : Colors.black87,
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.35,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _colorAcentoBeige.withValues(alpha: 0.6)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  it.value,
                  style: const TextStyle(
                    fontFamily: AppTheme.oswald,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  it.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Item {
  _Item(this.label, this.value);

  final String label;
  final String value;
}
