import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/firestore_service.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _service = FirestoreService();

  final _equipo1 = TextEditingController();
  final _equipo2 = TextEditingController();
  final _fecha = TextEditingController();
  final _hora = TextEditingController();
  final _ubicacion = TextEditingController();

  String _color1 = 'Rojo';
  String _color2 = 'Azul';
  bool _loading = false;

  static const _colors = <String>[
    'Rojo',
    'Azul',
    'Verde',
    'Amarillo',
    'Blanco',
    'Negro',
    'Morado',
    'Naranja',
  ];

  @override
  void dispose() {
    _equipo1.dispose();
    _equipo2.dispose();
    _fecha.dispose();
    _hora.dispose();
    _ubicacion.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_equipo1.text.trim().isEmpty || _equipo2.text.trim().isEmpty || _fecha.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rellena al menos equipos y fecha.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _service.createMatch(
        equipo1: _equipo1.text.trim(),
        color1: _color1,
        equipo2: _equipo2.text.trim(),
        color2: _color2,
        fecha: _fecha.text.trim(),
        hora: _hora.text.trim(),
        ubicacion: _ubicacion.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partido creado')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CREAR PARTIDO')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _equipo1, decoration: const InputDecoration(labelText: 'Equipo local')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _color1,
            items: _colors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _color1 = v ?? _color1),
            decoration: const InputDecoration(labelText: 'Color local'),
          ),
          const SizedBox(height: 16),
          TextField(controller: _equipo2, decoration: const InputDecoration(labelText: 'Equipo visitante')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _color2,
            items: _colors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _color2 = v ?? _color2),
            decoration: const InputDecoration(labelText: 'Color visitante'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(controller: _fecha, decoration: const InputDecoration(labelText: 'Fecha (DD/MM)'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _hora, decoration: const InputDecoration(labelText: 'Hora (HH:MM)'))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(controller: _ubicacion, decoration: const InputDecoration(labelText: 'Ubicacion')),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: _loading ? null : _create,
            child: _loading ? const CircularProgressIndicator() : const Text('Publicar partido'),
          ),
        ],
      ),
    );
  }
}
