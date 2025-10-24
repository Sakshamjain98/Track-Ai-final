import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/onboarding/service/observices.dart';
import 'package:trackai/features/settings/adjustgoals.dart';
import 'package:trackai/features/settings/healthandfeedback.dart';
import 'package:trackai/features/settings/privacy_policy.dart';
import 'package:trackai/features/settings/terms_and_service.dart';

class Settingsscreen extends StatefulWidget {
  const Settingsscreen({
    Key? key,
    this.onPatternBackgroundChanged,
    this.patternBackgroundEnabled = false,
  }) : super(key: key);

  final Function(bool)? onPatternBackgroundChanged;
  final bool patternBackgroundEnabled;

  @override
  State<Settingsscreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<Settingsscreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _onboardingData;
  bool _isLoading = true;
  bool _burnedCaloriesEnabled = false;
  bool _patternBackgroundEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _patternBackgroundEnabled = widget.patternBackgroundEnabled;
  }

  Future<void> _loadUserData() async {
    try {
      final data = await OnboardingService.getOnboardingData();
      setState(() {
        _onboardingData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _navigateToPersonalDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalDetailsScreen(
          onboardingData: _onboardingData,
          onDataUpdated: _loadUserData,
        ),
      ),
    );
  }

  void _navigateToAdjustGoals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdjustGoalsPage()),
    );
  }

  void _navigateToHelpFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HealthFeedbackPage()),
    );
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  void _navigateToTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
    );
  }

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      gradient: AppColors.cardLinearGradient(isDarkTheme),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.black,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withOpacity(0.08),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.cardLinearGradient(isDarkTheme),
          ),
        ),
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppColors.textPrimary(isDarkTheme),
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            _buildProfileSummaryCard(isDarkTheme),
            SizedBox(height: screenHeight * 0.02),
            _buildCustomizationCard(isDarkTheme),
            SizedBox(height: screenHeight * 0.02),
            _buildPreferencesCard(isDarkTheme, themeProvider),
            SizedBox(height: screenHeight * 0.02),
            _buildSupportLegalCard(isDarkTheme),
            SizedBox(height: screenHeight * 0.02),
            _buildAccountCard(isDarkTheme),
            SizedBox(height: screenHeight * 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard(bool isDarkTheme) {
    final age = _onboardingData?['dateOfBirth'] != null
        ? OnboardingService.calculateAge(_onboardingData!['dateOfBirth'])
        : null;
    final isMetric = _onboardingData?['isMetric'] ?? false;
    final height = isMetric
        ? '${_onboardingData?['heightCm'] ?? 0} cm'
        : '${_onboardingData?['heightFeet'] ?? 0} ft ${_onboardingData?['heightInches'] ?? 0} in';

    // --- FIX HERE: Format weight to 2 decimal places ---
    final double weightKg =
        (_onboardingData?['weightKg'] as num?)?.toDouble() ?? 0.0;
    final double weightLbs =
        (_onboardingData?['weightLbs'] as num?)?.toDouble() ?? 0.0;

    final weight = isMetric
        ? '${weightKg.toStringAsFixed(2)} kg'
        : '${weightLbs.toStringAsFixed(2)} lbs';
    // --- END FIX ---

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Summary',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildProfileRow('Age', age?.toString() ?? 'N/A', isDarkTheme),
          const SizedBox(height: 12),
          _buildProfileRow('Height', height, isDarkTheme),
          const SizedBox(height: 12),
          _buildProfileRowWithUnit(
            'Current Weight',
            weight,
            isMetric,
            isDarkTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, bool isDarkTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(isDarkTheme),
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRowWithUnit(
      String label,
      String value,
      bool isMetric,
      bool isDarkTheme,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(isDarkTheme),
            fontSize: 16,
          ),
        ),
        Row(
          children: [
            Text(
              value.split(' ')[0], // This will now be the formatted string e.g., "70.50"
              style: TextStyle(
                color: AppColors.textPrimary(isDarkTheme),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent(isDarkTheme),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value.split(' ')[1], // This will be "kg" or "lbs"
                style: TextStyle(
                  color: AppColors.textPrimary(isDarkTheme),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomizationCard(bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customization',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'Personal details',
            onTap: _navigateToPersonalDetails,
            isDarkTheme: isDarkTheme,
          ),
          const SizedBox(height: 4),
          _buildSettingsItem(
            icon: Icons.track_changes_outlined,
            title: 'Adjust goals',
            subtitle: 'Calories, carbs, fats, and protein',
            onTap: _navigateToAdjustGoals,
            isDarkTheme: isDarkTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(bool isDarkTheme, ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildToggleItem(
            title: 'Burned Calories',
            subtitle: 'Add burned calories to daily goal',
            value: _burnedCaloriesEnabled,
            onChanged: (value) {
              setState(() {
                _burnedCaloriesEnabled = value;
              });
            },
            isDarkTheme: isDarkTheme,
          ),
          const SizedBox(height: 16),
          _buildToggleItem(
            title: 'Pattern Background',
            subtitle: 'Toggle decorative background pattern',
            value: _patternBackgroundEnabled,
            onChanged: (value) {
              setState(() {
                _patternBackgroundEnabled = value;
              });
              widget.onPatternBackgroundChanged?.call(value);
            },
            isDarkTheme: isDarkTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportLegalCard(bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support & Legal',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Help & Feedback',
            subtitle: 'Find answers and share your thoughts',
            onTap: _navigateToHelpFeedback,
            isDarkTheme: isDarkTheme,
          ),
          const SizedBox(height: 4),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: _navigateToPrivacyPolicy,
            isDarkTheme: isDarkTheme,
          ),
          const SizedBox(height: 4),
          _buildSettingsItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: _navigateToTermsOfService,
            isDarkTheme: isDarkTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(bool isDarkTheme) {
    final user = _auth.currentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Signed in as',
            style: TextStyle(
              color: AppColors.textSecondary(isDarkTheme),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'No email',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          // Enhanced Sign Out Button with Red Background
          Container(
            width: 180,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.red,
                  Colors.red.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _signOut,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Warning text
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will be logged out and returned to the login screen.',
                    style: TextStyle(
                      color: Colors.red.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isDarkTheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary(isDarkTheme),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary(isDarkTheme),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary(isDarkTheme),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textDisabled(isDarkTheme),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkTheme,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary(isDarkTheme),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary(isDarkTheme),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.black,
          activeTrackColor: AppColors.black.withOpacity(0.3),
          inactiveThumbColor: AppColors.textDisabled(isDarkTheme),
          inactiveTrackColor: AppColors.inputFill(isDarkTheme),
        ),
      ],
    );
  }
}

class PersonalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? onboardingData;
  final VoidCallback onDataUpdated;

  const PersonalDetailsScreen({
    Key? key,
    required this.onboardingData,
    required this.onDataUpdated,
  }) : super(key: key);

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;
  late TextEditingController _heightCmController;
  late TextEditingController _weightLbsController;
  late TextEditingController _weightKgController;
  late TextEditingController _goalWeightController;

  String _selectedGender = '';
  DateTime? _selectedDateOfBirth;
  bool _isMetric = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCurrentData();
  }

  void _initializeControllers() {
    _heightFeetController = TextEditingController();
    _heightInchesController = TextEditingController();
    _heightCmController = TextEditingController();
    _weightLbsController = TextEditingController();
    _weightKgController = TextEditingController();
    _goalWeightController = TextEditingController();
  }

  void _loadCurrentData() {
    if (widget.onboardingData != null) {
      final data = widget.onboardingData!;
      _selectedGender = data['gender'] ?? '';
      _selectedDateOfBirth = data['dateOfBirth'];
      _isMetric = data['isMetric'] ?? false;
      _heightFeetController.text = (data['heightFeet'] ?? 0).toString();
      _heightInchesController.text = (data['heightInches'] ?? 0).toString();
      _heightCmController.text = (data['heightCm'] ?? 0).toString();

      // --- FIX HERE: Format weight controllers to 2 decimal places ---
      _weightLbsController.text =
          ((data['weightLbs'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2);
      _weightKgController.text =
          ((data['weightKg'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2);
      _goalWeightController.text =
          ((data['desiredWeight'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2);
      // --- END FIX ---
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final updates = <String, dynamic>{
        'gender': _selectedGender,
        'dateOfBirth': _selectedDateOfBirth,
        'isMetric': _isMetric,
        'heightFeet': int.tryParse(_heightFeetController.text) ?? 0,
        'heightInches': int.tryParse(_heightInchesController.text) ?? 0,
        'heightCm': int.tryParse(_heightCmController.text) ?? 0,
        'weightLbs': double.tryParse(_weightLbsController.text) ?? 0.0,
        'weightKg': double.tryParse(_weightKgController.text) ?? 0.0,
        'desiredWeight': double.tryParse(_goalWeightController.text) ?? 0.0,
      };
      await OnboardingService.updateOnboardingData(updates);
      widget.onDataUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personal details updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      gradient: AppColors.cardLinearGradient(isDarkTheme),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.black,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withOpacity(0.08),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.isDarkMode;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.cardLinearGradient(isDarkTheme),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary(isDarkTheme),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Personal Details',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary(isDarkTheme),
                ),
              )
                  : Text(
                'Save',
                style: TextStyle(
                  color: AppColors.textPrimary(isDarkTheme),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            _buildGenderCard(isDarkTheme),
            SizedBox(height: screenHeight * 0.02),
            _buildDateOfBirthCard(isDarkTheme),
            SizedBox(height: screenHeight * 0.02),
            _buildUnitToggleCard(isDarkTheme),
            SizedBox(height: screenHeight * 0.02),
            _buildHeightCard(isDarkTheme),
            SizedBox(height: screenHeight * 0.02),
            _buildWeightCard(isDarkTheme),
            SizedBox(height: screenHeight * 0.02),
            _buildGoalWeightCard(isDarkTheme),
            SizedBox(height: screenHeight * 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard(bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildGenderOption('Male', isDarkTheme)),
              const SizedBox(width: 12),
              Expanded(child: _buildGenderOption('Female', isDarkTheme)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender, bool isDarkTheme) {
    final isSelected = _selectedGender == gender;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent(isDarkTheme).withOpacity(0.2)
              : AppColors.inputFill(isDarkTheme),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.accent(isDarkTheme)
                : AppColors.inputBorder,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            gender,
            style: TextStyle(
              color: isSelected
                  ? AppColors.accent(isDarkTheme)
                  : AppColors.textSecondary(isDarkTheme),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthCard(bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date of Birth',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDateOfBirth ?? DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.accent(isDarkTheme),
                        onPrimary: AppColors.textPrimary(isDarkTheme),
                        surface: AppColors.inputFill(isDarkTheme),
                        onSurface: AppColors.textPrimary(isDarkTheme),
                      ),
                      dialogBackgroundColor: AppColors.inputFill(isDarkTheme),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() {
                  _selectedDateOfBirth = date;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputFill(isDarkTheme),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.inputBorder,
                  width: 1,
                ),
              ),
              child: Text(
                _selectedDateOfBirth != null
                    ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                    : 'Select Date of Birth',
                style: TextStyle(
                  color: _selectedDateOfBirth != null
                      ? AppColors.textPrimary(isDarkTheme)
                      : AppColors.textSecondary(isDarkTheme),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggleCard(bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use Metric Units',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDarkTheme),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toggle between metric and imperial units',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDarkTheme),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isMetric,
            onChanged: (value) {
              setState(() {
                _isMetric = value;
              });
            },
            activeColor: AppColors.black,
            activeTrackColor: AppColors.black.withOpacity(0.3),
            inactiveThumbColor: AppColors.textDisabled(isDarkTheme),
            inactiveTrackColor: AppColors.inputFill(isDarkTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightCard(bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Height',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (_isMetric) ...[
            _buildTextField(
              controller: _heightCmController,
              label: 'Height (cm)',
              keyboardType: TextInputType.number,
              isDarkTheme: isDarkTheme,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _heightFeetController,
                    label: 'Feet',
                    keyboardType: TextInputType.number,
                    isDarkTheme: isDarkTheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _heightInchesController,
                    label: 'Inches',
                    keyboardType: TextInputType.number,
                    isDarkTheme: isDarkTheme,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightCard(bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Weight',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _isMetric ? _weightKgController : _weightLbsController,
            label: _isMetric ? 'Weight (kg)' : 'Weight (lbs)',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            isDarkTheme: isDarkTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalWeightCard(bool isDarkTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal Weight',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _goalWeightController,
            label: _isMetric ? 'Goal Weight (kg)' : 'Goal Weight (lbs)',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            isDarkTheme: isDarkTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    required bool isDarkTheme,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: AppColors.textPrimary(isDarkTheme),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.textSecondary(isDarkTheme),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.inputFill(isDarkTheme),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.inputBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.inputBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.inputFocusedBorder,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _heightCmController.dispose();
    _weightLbsController.dispose();
    _weightKgController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }
}