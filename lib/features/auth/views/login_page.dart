import 'package:flutter/material.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/services/auth_services.dart';
import 'package:trackai/features/auth/views/signup_page.dart';
import 'package:trackai/core/wrappers/authwrapper.dart';
import 'package:trackai/features/admin/services/admin_service.dart';
import 'package:trackai/features/admin/admin_panel_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Check for admin credentials first (bypass Firebase for admin)
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      if (AdminService.validateAdminCredentials(email, password)) {
        print('Admin login detected, navigating to admin panel');
        if (mounted) {
          // Navigate directly to admin panel
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
            (route) => false,
          );
        }
        return;
      }

      // For non-admin users, proceed with Firebase authentication
      final user = await FirebaseService.signInWithEmailPassword(
        email,
        password,
      );

      if (user != null && mounted) {
        // Let AuthWrapper handle navigation to home or onboarding
        print('Login successful for user: ${user.email}');
        // Give time for Firebase auth state to propagate
        await Future.delayed(const Duration(milliseconds: 500));

        // Force a rebuild of the entire widget tree
        if (mounted) {
          // Clear the navigation stack and restart from AuthWrapper
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (isGoogleLoading) return; // Prevent multiple calls

    setState(() {
      isGoogleLoading = true;
    });

    try {
      final user = await FirebaseService.signInWithGoogle();

      if (user != null && mounted) {
        // Let AuthWrapper handle navigation to home or onboarding
        print('Google sign-in successful for user: ${user.email}');
        // Give time for Firebase auth state to propagate
        await Future.delayed(const Duration(milliseconds: 500));

        // Force a rebuild of the entire widget tree
        if (mounted) {
          // Clear the navigation stack and restart from AuthWrapper
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false,
          );
        }
      }
      // If user is null, it means user cancelled - no error message needed
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  void _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email address first');
      return;
    }

    try {
      await FirebaseService.resetPassword(_emailController.text.trim());
      if (mounted) {
        _showSuccessSnackBar('Password reset email sent. Check your inbox.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isDark = false; // Force light theme

    return Scaffold(
      backgroundColor: Colors.grey[50], // Clean light background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white, // Clean white background
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet
                            ? screenWidth * 0.2
                            : screenWidth * 0.06,
                        vertical: screenHeight * 0.03,
                      ),

                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              screenHeight -
                              MediaQuery.of(context).padding.top -
                              48,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHeader(),
                            SizedBox(height: screenHeight * 0.05),

                            _buildForm(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // TrackAI Logo/Title
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.darkPrimary,
              AppColors.darkPrimary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'TrackAI',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1a1a1a), // Dark text for light theme
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to your TrackAI account',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280), // Light grey text
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.06), // responsive padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Sign in',
                style: TextStyle(
                  fontSize: screenWidth * 0.06, // responsive font
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1a1a1a),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Center(
              child: Text(
                'Enter your credentials to access your account',
                style: TextStyle(
                  fontSize: screenWidth * 0.035, // responsive font
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),

            // Email Field
            Text(
              'Email',
              style: TextStyle(
                color: const Color(0xFF374151),
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            _buildTextField(
              controller: _emailController,
              hintText: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                ).hasMatch(value!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: screenHeight * 0.025),

            // Password Field
            Text(
              'Password',
              style: TextStyle(
                color: const Color(0xFF374151),
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            _buildTextField(
              controller: _passwordController,
              hintText: 'Enter your password',
              icon: Icons.lock_outline,
              obscureText: obscurePassword,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your password';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
            ),
            SizedBox(height: screenHeight * 0.025),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AppColors.darkPrimary,
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Sign In Button
            _buildSubmitButton(),
            SizedBox(height: screenHeight * 0.025),

            // OR Divider
            _buildDivider(),
            SizedBox(height: screenHeight * 0.025),

            // Google Sign In Button
            _buildGoogleSignInButton(),
            SizedBox(height: screenHeight * 0.03),

            // Sign Up Link
            _buildSignUpLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: const Color(0xFF1a1a1a),
        fontSize: screenWidth * 0.04, // responsive text size
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFF9CA3AF),
          fontSize: screenWidth * 0.04, // responsive hint size
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF9CA3AF),
          size: screenWidth * 0.05, // responsive icon size
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, // responsive horizontal padding
          vertical: screenHeight * 0.018, // responsive vertical padding
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.errorColor, width: 2),
        ),
        errorStyle: TextStyle(
          fontSize: screenWidth * 0.03, // responsive error font size
          color: AppColors.errorColor,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.065,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkPrimary,
            AppColors.darkPrimary.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkPrimary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleEmailLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? SizedBox(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Sign in',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Text(
            'OR',
            style: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.065,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
        color: Colors.white,
      ),
      child: OutlinedButton.icon(
        onPressed: isGoogleLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: isGoogleLoading
            ? SizedBox(
                width: screenWidth * 0.045,
                height: screenWidth * 0.045,
                child: CircularProgressIndicator(
                  color: AppColors.darkPrimary,
                  strokeWidth: 2,
                ),
              )
            : SizedBox(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                child: Image.asset(
                  'assets/images/google.png',
                  width: screenWidth * 0.06,
                  height: screenWidth * 0.06,
                ),
              ),
        label: Text(
          'Continue with Google',
          style: TextStyle(
            color: const Color(0xFF374151),
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignupPage()),
          );
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.02,
            horizontal: screenWidth * 0.04,
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: const Color(0xFF6B7280),
            ),
            children: [
              const TextSpan(text: "Don't have an account? "),
              TextSpan(
                text: 'Sign up',
                style: TextStyle(
                  color: AppColors.darkPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
