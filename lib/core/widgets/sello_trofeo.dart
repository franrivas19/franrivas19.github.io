import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

String? _imagenSello(String titulo) {
  final t = titulo.toLowerCase();
  if (t.contains('killer')) return 'assets/images/sellos/sello_killer.png';
  if (t.contains('mete tú')) {
    return 'assets/images/sellos/sello_asistencias.png';
  }
  if (t.contains('asistencia')) {
    return 'assets/images/sellos/sello_asistencia.png';
  }
  if (t.contains('inofensivo')) {
    return 'assets/images/sellos/sello_inofensivo.png';
  }
  if (t.contains('tibú') || t.contains('tibu')) {
    return 'assets/images/sellos/tibu.png';
  }
  if (t.contains('lamentaciones')) return 'assets/images/sellos/sello_muro.png';
  if (t.contains('memoria')) return 'assets/images/sellos/sello_memoria.png';
  return null;
}

class SelloTrofeo extends StatelessWidget {
  const SelloTrofeo({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final imagen = _imagenSello(titulo);
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _mostrarVineta(context, imagen),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child:
                imagen != null
                    ? Image.asset(imagen, fit: BoxFit.contain)
                    : Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        titulo.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.oswald,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey.withValues(alpha: 0.8),
                          height: 1,
                        ),
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  void _mostrarVineta(BuildContext context, String? imagen) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            title: const Text(
              'SELLO DE LA PEÑA',
              style: TextStyle(
                fontFamily: AppTheme.oswald,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 1.5,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child:
                      imagen != null
                          ? Image.asset(imagen, fit: BoxFit.contain)
                          : DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text('🏆', style: TextStyle(fontSize: 52)),
                            ),
                          ),
                ),
                const SizedBox(height: 20),
                Text(
                  titulo.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.oswald,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Color(0xFF1A1A1A),
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Galardón Oficial · Temporada 2026',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

class HuecoVacioSello extends StatelessWidget {
  const HuecoVacioSello({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            '•',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.4),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
