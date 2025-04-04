import 'package:flutter/material.dart';
import '../../core/supabase_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();

  Future<void> _register() async {
    try {
      await _supabaseService.signUp(
        _emailController.text,
        _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro exitoso, revisa tu correo')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registro")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Correo')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Contraseña'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: Text('Registrar')),
          ],
        ),
      ),
    );
  }
}