import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../provider/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController emailController;
  late TextEditingController usernameController;
  late TextEditingController fullNameController;
  late TextEditingController passwordController;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    usernameController = TextEditingController();
    fullNameController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    fullNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (emailController.text.isEmpty ||
        usernameController.text.isEmpty ||
        fullNameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() => _isLoading = true);
    
    final success = await authProvider.register(
      email: emailController.text,
      username: usernameController.text,
      fullName: fullNameController.text,
      password: passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        context.go('/login');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'Registration failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Join MotivAI',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your motivation journey today',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomInput(
                    controller: emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    isDark: true,
                  ),
                  const SizedBox(height: 12),
                  CustomInput(
                    controller: usernameController,
                    hint: 'Username',
                    icon: Icons.person_outline,
                    isDark: true,
                  ),
                  const SizedBox(height: 12),
                  CustomInput(
                    controller: fullNameController,
                    hint: 'Full Name',
                    icon: Icons.badge_outlined,
                    isDark: true,
                  ),
                  const SizedBox(height: 12),
                  CustomInput(
                    controller: passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outlined,
                    isDark: true,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onPasswordToggle: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: _isLoading ? 'Creating Account...' : 'Register',
                    onPressed: _isLoading ? null : _handleRegister,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Login',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
