import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controles
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Estado de la UI
  bool _loading = false;
  bool _passwordVisible = false;
  String? _mensajeError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _procesarFormulario() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _mensajeError = 'Introduce correo y contraseña.');
      return;
    }

    setState(() {
      _loading = true;
      _mensajeError = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

      if (mounted) context.go('/resumen');
    } on FirebaseAuthException catch (e) {
      setState(() => _mensajeError = e.message ?? 'Error de autenticación.');
    } catch (e) {
      setState(() => _mensajeError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.grey),
      floatingLabelStyle: const TextStyle(color: Colors.deepPurpleAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.grey, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TÍTULO (Estilo Kotlin: Black, 32.sp)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      "EL VESTUARIO",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withValues(alpha: 0.95),
                        letterSpacing: -0.8,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0.7, 0),
                      child: Text(
                        "EL VESTUARIO",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.black.withValues(alpha: 0.95),
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                OutlinedTextField(
                  controller: _emailCtrl,
                  label: "Correo electrónico",
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration("Correo electrónico"),
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 8),

                // PASSWORD FIELD con Visibility Toggle
                TextField(
                  controller: _passwordCtrl,
                  obscureText: !_passwordVisible,
                  style: const TextStyle(letterSpacing: 2, color: Colors.black),
                  decoration: _buildInputDecoration(
                    "Contraseña",
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (_mensajeError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_mensajeError!, style: const TextStyle(color: Colors.red)),
                  ),

                // BOTÓN PRINCIPAL (Estilo Kotlin: 56.dp height, 16.dp shape)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _loading ? null : _procesarFormulario,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.deepPurpleAccent, 
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SALTAR AL CAMPO",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // TEXT BUTTON PARA CAMBIAR MODO
                TextButton(
                  onPressed: () => context.go('/registro'),
                  child: Text(
                    "¿Eres nuevo? Ficha por la peña",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para mantener los OutlinedTextField limpios
class OutlinedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumber;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final TextStyle? style;

  const OutlinedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isNumber = false,
    this.keyboardType,
    this.decoration,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : keyboardType,
      style: style,
      decoration: decoration ?? InputDecoration(labelText: label),
    );
  }
}