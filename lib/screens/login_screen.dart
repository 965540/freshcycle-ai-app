import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final auth = AuthService();

  String error = "";
  bool loading = false;

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!email.contains("@")) {
      setState(() => error = "Enter valid email");
      return;
    }

    setState(() {
      error = "";
      loading = true;
    });

    final result = await auth.login(email, password);

    if (!mounted) return;

    setState(() => loading = false);

    if (result == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => error = result);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (!email.contains("@")) {
      setState(() => error = "Enter email first");
      return;
    }

    final result = await auth.resetPassword(email);

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reset email sent")),
      );
    } else {
      setState(() => error = result);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF43A047),
              Color(0xFFA5D6A7),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [

                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [

                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(hintText: "Email"),
                      ),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(hintText: "Password"),
                      ),

                      if (error.isNotEmpty)
                        Text(error, style: const TextStyle(color: Colors.red)),

                      TextButton(
                        onPressed: resetPassword,
                        child: const Text("Forgot Password?"),
                      ),

                      ElevatedButton(
                        onPressed: loading ? null : loginUser,
                        child: loading
                            ? const CircularProgressIndicator()
                            : const Text("Login"),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text("Create Account"),
                      ),
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
}