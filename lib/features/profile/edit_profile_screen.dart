import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/firestore_service.dart';
import '../common/avatar_jugador.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _service = FirestoreService();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _fotoCtrl = TextEditingController();

  String _posicion = 'Sin definir';
  bool _loading = false;
  bool _inited = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _fechaCtrl.dispose();
    _fotoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = _service.currentUid;
    if (uid.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      await _service.updateProfile(
        uid: uid,
        nombre: _nombreCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        fechaNacimiento: _fechaCtrl.text.trim(),
        posicion: _posicion,
        fotoUrl: _fotoCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
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
      appBar: AppBar(title: const Text('EDITAR PERFIL')),
      body: StreamBuilder(
        stream: _service.currentUserProfile(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user != null && !_inited) {
            _inited = true;
            _nombreCtrl.text = user.nombre;
            _correoCtrl.text = user.correo.isNotEmpty
                ? user.correo
                : (FirebaseAuth.instance.currentUser?.email ?? '');
            _fechaCtrl.text = user.fechaNacimiento;
            _fotoCtrl.text = user.fotoUrl;
            _posicion = user.posicion;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: AvatarJugador(
                  nombre: _nombreCtrl.text,
                  fotoUrl: _fotoCtrl.text,
                  size: 120,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre y Apellidos'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fotoCtrl,
                decoration: const InputDecoration(labelText: 'Enlace de foto (URL)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _correoCtrl,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fechaCtrl,
                decoration: const InputDecoration(labelText: 'Fecha nacimiento (DD/MM/AAAA)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _posicion,
                items: const [
                  DropdownMenuItem(value: 'Portero', child: Text('Portero')),
                  DropdownMenuItem(value: 'Cierre', child: Text('Cierre')),
                  DropdownMenuItem(value: 'Ala', child: Text('Ala')),
                  DropdownMenuItem(value: 'Pívot', child: Text('Pivot')),
                  DropdownMenuItem(value: 'Comodín', child: Text('Comodin')),
                  DropdownMenuItem(value: 'Sin definir', child: Text('Sin definir')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _posicion = v);
                  }
                },
                decoration: const InputDecoration(labelText: 'Posicion preferida'),
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading ? const CircularProgressIndicator() : const Text('Guardar cambios'),
              ),
            ],
          );
        },
      ),
    );
  }
}
