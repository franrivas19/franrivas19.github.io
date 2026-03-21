import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _passwordVisible = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _birthDateCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final nombre = _nameCtrl.text.trim();
    final apellidos = _lastNameCtrl.text.trim();
    final fechaNacimiento = _birthDateCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (nombre.isEmpty ||
        apellidos.isEmpty ||
        fechaNacimiento.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      setState(() => _error = 'Completa todos los campos.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user?.uid;
      if (uid == null || uid.isEmpty) {
        throw Exception('No se pudo obtener el uid del usuario.');
      }

      final fullName = '$nombre $apellidos';

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': fullName,
        'correo': email,
        'fechaNacimiento': fechaNacimiento,
        'pj': 0,
        'goles': 0,
        'asistencias': 0,
        'valoracion': 0.0,
        'posicion': 'Sin definir',
        'fotoUrl': '',
        'totalEstrellas': 0.0,
        'votosRecibidos': 0,
      });

      await credential.user?.updateDisplayName(fullName);

      if (!mounted) {
        return;
      }
      context.go('/resumen');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'No se pudo completar el registro.');
    } on FirebaseException catch (e) {
      setState(() => _error = e.message ?? 'No se pudo guardar el perfil.');
    } catch (_) {
      setState(() => _error = 'Error inesperado registrando usuario.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de usuario')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'FICHAJE',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Apellidos'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _birthDateCtrl,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Fecha Nacimiento (DD/MM/AAAA)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Contrasena',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
                    icon: Icon(
                      _passwordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrarme'),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Ya tengo cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}