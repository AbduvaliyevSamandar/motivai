import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../provider/auth_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barcha maydonlarni to\'ldiring')),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parollar mos kelmadi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await Provider.of<AuthProvider>(context, listen: false)
          .register(
            email: emailController.text,
            username: emailController.text.split('@')[0],
            fullName: nameController.text,
            password: passwordController.text,
          );

      if (result) {
        context.go('/home');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ro\'yxatdan o\'tish muvaffaq bo\'lmadi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2563EB)),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2563EB),
              Colors.white,
            ],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yangi Akkaunt',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ozingizni ro\'yxatdan o\'tkazish',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 30),
                // Name field
                _buildTextField(nameController, 'To\'liq Ism', Icons.person),
                SizedBox(height: 16),
                // Email field
                _buildTextField(emailController, 'Email', Icons.email),
                SizedBox(height: 16),
                // Password field
                _buildPasswordField(
                  passwordController,
                  'Parol',
                  _obscurePassword,
                  () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                SizedBox(height: 16),
                // Confirm password field
                _buildPasswordField(
                  confirmPasswordController,
                  'Parolni Tasdiqlang',
                  _obscureConfirmPassword,
                  () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                SizedBox(height: 24),
                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 10,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Ro\'yxatdan O\'tish',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16),
                // Login link
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'Allaqachon akkauntingiz bormi? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Kirish',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Color(0xFF2563EB)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String hint,
    bool obscure,
    VoidCallback toggleObscure,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(Icons.lock, color: Color(0xFF2563EB)),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFF2563EB),
            ),
            onPressed: toggleObscure,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
