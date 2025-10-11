import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/services/auth_services.dart';
import 'package:trackai/features/auth/views/login_page.dart';
import 'package:trackai/core/wrappers/authwrapper.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeToTerms = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

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
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignup() async {
    if (!_formKey.currentState!.validate() || !agreeToTerms) {
      if (!agreeToTerms) {
        _showErrorSnackBar(
          'Please agree to the Terms of Service and Privacy Policy',
        );
      }
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = await FirebaseService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
      );

      if (user != null && mounted) {
        // Let AuthWrapper handle navigation to onboarding or home
        print('Signup successful for user: ${user.email}');
        // Give more time for Firebase auth state to propagate
        await Future.delayed(const Duration(milliseconds: 500));
        print('Signup: Auth state should now be updated');

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
        // Let AuthWrapper handle navigation to onboarding or home
        print('Google sign-in successful for user: ${user.email}');
        // Give more time for Firebase auth state to propagate
        await Future.delayed(const Duration(milliseconds: 500));
        print('Google signup: Auth state should now be updated');

        // Force a rebuild of the entire widget tree
        if (mounted) {
          // Clear the navigation stack and restart from AuthWrapper
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false,
          );
        }
      } else if (mounted) {
        // User cancelled the sign-in
        setState(() {
          isGoogleLoading = false;
        });
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });

        // Only show error if it's not a user cancellation
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (!errorMessage.toLowerCase().contains('cancel') &&
            !errorMessage.toLowerCase().contains('aborted') &&
            !errorMessage.toLowerCase().contains('sign_in_canceled')) {
          _showErrorSnackBar('Google Sign-In failed. Please try again.');
        }
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isDark = false; // Force light theme

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB), // Light background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 1.0],
            colors: [
              Color(0xFFF8FAFB), // Very light gray
              Color(0xFFEDF5F3), // Very light mint
            ],
          ),
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
                        horizontal: isTablet ? screenWidth * 0.2 : 24.0,
                        vertical: 24.0,
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
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildHeader(),
                            const SizedBox(height: 40),
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
        const Text(
          'Create account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937), // Dark gray
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join TrackAI to start your wellness journey',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280), // Medium gray
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: const Text(
                'Sign up',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Create your account to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // First Name and Last Name Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'First name',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _firstNameController,
                        hintText: 'First name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last name',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _lastNameController,
                        hintText: 'Last name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email Field
            const Text(
              'Email',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
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
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password Field
            const Text(
              'Password',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _passwordController,
              hintText: 'Create a password',
              icon: Icons.lock_outline,
              obscureText: obscurePassword,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a password';
                }
                if (value!.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Password Field
            const Text(
              'Confirm password',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm your password',
              icon: Icons.lock_outline,
              obscureText: obscureConfirmPassword,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    obscureConfirmPassword = !obscureConfirmPassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Terms and Conditions Checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      agreeToTerms = value ?? false;
                    });
                  },
                  activeColor: AppColors.darkPrimary,
                  checkColor: Colors.white,
                  side: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: AppColors.darkPrimary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.darkPrimary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Create Account Button
            _buildSubmitButton(),
            const SizedBox(height: 20),

            // OR Divider
            _buildDivider(),
            const SizedBox(height: 20),

            // Google Sign In Button
            _buildGoogleSignInButton(),
            const SizedBox(height: 24),

            // Sign In Link
            _buildSignInLink(),
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

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: const Color(0xFF1F2937),
        fontSize: screenWidth * 0.04,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFF9CA3AF),
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF9CA3AF),
          size: screenWidth * 0.05,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.03,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
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
          fontSize: screenWidth * 0.03,
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
            color: AppColors.darkPrimary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleEmailSignup,
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
                'Create account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
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
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
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
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
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

  Widget _buildSignInLink() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
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
              const TextSpan(text: "Already have an account? "),
              TextSpan(
                text: 'Sign in',
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
