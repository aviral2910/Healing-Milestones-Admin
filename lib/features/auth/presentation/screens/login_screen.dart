import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../../../logo/healing_milestone_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Very dark premium background
      body: Stack(
        children: [
          // Background decorative glow (Top Left)
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withAlpha(40),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(20),
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          // Background decorative glow (Bottom Right)
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withAlpha(30),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withAlpha(20),
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and Title
                    const SizedBox(
                      height: 100,
                      width: 100,
                      child: HealingMilestonesLogo(showText: false, logoSize: 90),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Healing Milestones',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin Portal',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Glassmorphic Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withAlpha(30),
                              width: 1.5,
                            ),
                          ),
                          child: const _LoginForm(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login failed: ${e.toString().split(']').last.trim()}'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      try {
        await GoogleSignIn.instance.initialize();
      } catch (_) {}
      
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        // User canceled the sign-in flow
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Google Login failed: ${e.toString().split(']').last.trim()}'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to manage the platform',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 32),
        
        // Email Field
        TextFormField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
            filled: true,
            fillColor: Colors.black.withAlpha(50),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[400],
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: Colors.black.withAlpha(50),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
          ),
          onFieldSubmitted: (_) => _login(),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 32),
        
        // Login Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading 
                ? const SizedBox(
                    height: 24, 
                    width: 24, 
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                  ) 
                : const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withAlpha(50))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withAlpha(50))),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Google Button
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _loginWithGoogle,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withAlpha(50), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white.withAlpha(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                else ...[
                  // Simple Google "G" representation
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}
