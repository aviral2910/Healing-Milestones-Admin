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
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Desktop Split Layout
            return Row(
              children: [
                // Left Panel - Branding
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0F0F0F),
                          theme.colorScheme.primary.withAlpha(40),
                          const Color(0xFF000000),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 180,
                            width: 180,
                            child: HealingMilestonesLogo(showText: false, logoSize: 150),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            'Healing Milestones',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Secure Administration Portal',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              letterSpacing: 3.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right Panel - Login Form
                Expanded(
                  flex: 4,
                  child: Container(
                    color: const Color(0xFF1A1A1A), // Solid dark gray
                    child: const Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                        child: _LoginForm(isDesktop: true),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile/Tablet Centered Layout
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
              ),
              child: const Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(32),
                  child: _LoginForm(isDesktop: false),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final bool isDesktop;
  const _LoginForm({required this.isDesktop});

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
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isDesktop) ...[
            const Center(
              child: SizedBox(
                height: 80,
                width: 80,
                child: HealingMilestonesLogo(showText: false, logoSize: 70),
              ),
            ),
            const SizedBox(height: 32),
          ],
          Text(
            'Welcome back',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please enter your details to sign in.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 48),
          
          // Custom Minimalist TextFields
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
            onSubmitted: (_) => _login(),
          ),
          
          const SizedBox(height: 40),
          
          // Primary Login Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading 
                  ? const SizedBox(
                      height: 24, width: 24, 
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                    ) 
                  : const Text(
                      'Sign in',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[800])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or continue with',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[800])),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Google Button
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _loginWithGoogle,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.grey[800]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('G', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    Function(String)? onSubmitted,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[300], fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: 'Enter your ${label.toLowerCase()}',
            hintStyle: TextStyle(color: Colors.grey[700]),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF0A0A0A), // Very dark inside the field
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
