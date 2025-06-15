import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cutmate/services/auth_service.dart';
import 'package:cutmate/services/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final userProvider = context.read<UserProvider>();
      
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Sync user data after successful login
      await userProvider.syncUserDataAfterLogin();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anmelden'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo oder App-Name
              Text(
                'CutMate',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // E-Mail Feld
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie Ihre E-Mail ein';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Bitte geben Sie eine gültige E-Mail ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Passwort Feld
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte geben Sie Ihr Passwort ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Anmelden Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Anmelden'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Registrieren Link
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/register'),
                child: const Text('Noch kein Konto? Registrieren'),
              ),
              
              // Passwort vergessen Link
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/forgot-password'),
                child: const Text('Passwort vergessen?'),
              ),
              
              const SizedBox(height: 32),
              
              // Offline weiter Button
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/main'),
                child: const Text('Offline fortfahren'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
