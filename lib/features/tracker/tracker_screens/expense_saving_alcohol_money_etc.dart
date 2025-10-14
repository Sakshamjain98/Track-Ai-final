import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

// Enhanced Expense Tracker Screen
class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  int _currentStep = 0;
  final int _totalSteps = 6;

  // Controllers
  final _valueController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;
  String? _selectedPaymentMethod;
  String? _selectedNecessity;

  // Enhanced payment methods with icons and colors
  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Cash', 'icon': Icons.money, 'color': Color(0xFF4CAF50), 'description': 'Physical money'},
    {'name': 'Credit Card', 'icon': Icons.credit_card, 'color': Color(0xFF2196F3), 'description': 'Credit payment'},
    {'name': 'Debit Card', 'icon': Icons.payment, 'color': Color(0xFF9C27B0), 'description': 'Direct bank payment'},
    {'name': 'Digital Wallet', 'icon': Icons.account_balance_wallet, 'color': Color(0xFFFF9800), 'description': 'UPI, PayPal, etc.'},
    {'name': 'Bank Transfer', 'icon': Icons.account_balance, 'color': Color(0xFF607D8B), 'description': 'Wire transfer'},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Color(0xFF795548), 'description': 'Other methods'},
  ];

  // Enhanced categories with icons and colors
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Color(0xFFE91E63), 'description': 'Meals & groceries'},
    {'name': 'Transportation', 'icon': Icons.directions_car, 'color': Color(0xFF3F51B5), 'description': 'Travel & commute'},
    {'name': 'Housing', 'icon': Icons.home, 'color': Color(0xFF009688), 'description': 'Rent & utilities'},
    {'name': 'Healthcare', 'icon': Icons.medical_services, 'color': Color(0xFFF44336), 'description': 'Medical expenses'},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Color(0xFFFF5722), 'description': 'Fun & leisure'},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Color(0xFF673AB7), 'description': 'Purchases & items'},
    {'name': 'Bills', 'icon': Icons.receipt_long, 'color': Color(0xFFFF9800), 'description': 'Utilities & services'},
    {'name': 'Other', 'icon': Icons.category, 'color': Color(0xFF9E9E9E), 'description': 'Miscellaneous'},
  ];

  // Necessity levels
  final List<Map<String, dynamic>> _necessityLevels = [
    {'name': 'Essential', 'description': 'Must have', 'color': Color(0xFFE53935), 'priority': 4},
    {'name': 'Important', 'description': 'Should have', 'color': Color(0xFFFF9800), 'priority': 3},
    {'name': 'Optional', 'description': 'Nice to have', 'color': Color(0xFFFFC107), 'priority': 2},
    {'name': 'Luxury', 'description': 'Want to have', 'color': Color(0xFF4CAF50), 'priority': 1},
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _valueController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();

    for (var field in _customFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _restartAnimations();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _restartAnimations();
    }
  }

  void _restartAnimations() {
    _slideController.reset();
    _scaleController.reset();
    _slideController.forward();
    _scaleController.forward();
  }

  void _addCustomField() {
    HapticFeedback.selectionClick();
    setState(() {
      _customFields.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeCustomField(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _customFields[index]['key']?.dispose();
      _customFields[index]['value']?.dispose();
      _customFields.removeAt(index);
    });
  }

  Future<void> _saveEntry() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customData = <String, dynamic>{};
      for (var field in _customFields) {
        final key = field['key']?.text ?? '';
        final value = field['value']?.text ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          customData[key] = value;
        }
      }

      final entryData = {
        'value': double.tryParse(_valueController.text) ?? 0.0,
        'category': _selectedCategory ?? _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'paymentMethod': _selectedPaymentMethod ?? '',
        'necessity': _selectedNecessity ?? '',
        'customData': customData,
        'trackerType': 'expense',
      };

      await TrackerService.saveTrackerEntry('expense', entryData);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Expense entry saved successfully! 💸'),
              ],
            ),
            backgroundColor: _getCurrentExpenseColor(),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        Navigator.pop(context);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error saving entry: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _selectedCategory;

  Color _getCurrentExpenseColor() {
    if (_selectedCategory != null) {
      final category = _categories.firstWhere(
            (cat) => cat['name'] == _selectedCategory,
        orElse: () => _categories[0],
      );
      return category['color'];
    }
    return const Color(0xFFE91E63);
  }

  IconData _getCurrentExpenseIcon() {
    if (_selectedCategory != null) {
      final category = _categories.firstWhere(
            (cat) => cat['name'] == _selectedCategory,
        orElse: () => _categories[0],
      );
      return category['icon'];
    }
    return Icons.attach_money;
  }

  Color _getCurrentNecessityColor() {
    if (_selectedNecessity != null) {
      final necessity = _necessityLevels.firstWhere(
            (level) => level['name'] == _selectedNecessity,
        orElse: () => _necessityLevels[0],
      );
      return necessity['color'];
    }
    return const Color(0xFFFF9800);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: _getGradientBackground(isDark),
          body: Container(
            decoration: BoxDecoration(
              gradient: _getBackgroundGradient(isDark),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Enhanced Progress Header - Fixed height
                    SizedBox(
                      height: 140,
                      child: _buildEnhancedProgressHeader(isDark),
                    ),

                    // Page View with proper constraints
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(isDark), // Amount
                          _buildStep2(isDark), // Category
                          _buildStep3(isDark), // Payment Method
                          _buildStep4(isDark), // Necessity & Description
                          _buildStep5(isDark), // Custom Fields
                          _buildStep6(isDark), // Review & Save
                        ],
                      ),
                    ),

                    // Enhanced Navigation Buttons - Fixed height
                    SizedBox(
                      height: 120,
                      child: _buildEnhancedNavigationButtons(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getGradientBackground(bool isDark) {
    return isDark
        ? const Color(0xFF0A0A0F)
        : const Color(0xFFF8FAFF);
  }

  Gradient _getBackgroundGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
        const Color(0xFF0A0A0F),
        const Color(0xFF1A1A2E),
        const Color(0xFF16213E),
      ]
          : [
        const Color(0xFFF8FAFF),
        const Color(0xFFE8F4FD),
        const Color(0xFFDDF4FF),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  Widget _buildEnhancedProgressHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.9),
            const Color(0xFF16213E).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF8FAFF).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              // Back Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white : Colors.black,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title Section
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCurrentExpenseColor(),
                            _getCurrentExpenseColor().withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          _getCurrentExpenseIcon(),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Expense Tracker',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_getStepTitle(_currentStep)}',
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // **🔧 FIXED PROGRESS CIRCLE - PROPERLY CENTERED**
              Container(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center, // ✅ This centers everything
                  children: [
                    // Background Circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    // Progress Circle - ✅ Properly sized and centered
                    SizedBox(
                      width: 46, // ✅ Slightly smaller than container
                      height: 46,
                      child: CircularProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                        strokeWidth: 3,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCurrentExpenseColor(),
                        ),
                      ),
                    ),
                    // Center Text - ✅ Perfectly centered
                    Container(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: Text(
                          '${_currentStep + 1}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Enhanced Progress Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getCurrentExpenseColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Amount';
      case 1: return 'Category';
      case 2: return 'Payment Method';
      case 3: return 'Details';
      case 4: return 'Custom Data';
      case 5: return 'Review';
      default: return '';
    }
  }

  // Step 1: Amount
  Widget _buildStep1(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '💸 Expense Amount',
          subtitle: 'How much did you spend?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Animated Money Icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE91E63).withValues(alpha: 0.3),
                              const Color(0xFFF48FB1).withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFE91E63),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.attach_money,
                            size: 50,
                            color: const Color(0xFFE91E63),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _valueController,
                  label: 'Amount',
                  hint: '₹ 0.00',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  autofocus: true,
                  prefixIcon: Icons.currency_rupee,
                  helpText: 'Enter the total amount spent',
                ),

                const SizedBox(height: 20),

                // Amount Suggestions
                _buildAmountSuggestions(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountSuggestions(bool isDark) {
    final suggestions = [50, 100, 200, 500, 1000, 2000];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick amounts:',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions.map((amount) => GestureDetector(
              onTap: () {
                _valueController.text = amount.toString();
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '₹$amount',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Step 2: Category
  Widget _buildStep2(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '📂 Expense Category',
          subtitle: 'What type of expense is this?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Categories Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category['name'];
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [
                              category['color'].withValues(alpha: 0.2),
                              category['color'].withValues(alpha: 0.1),
                            ],
                          )
                              : LinearGradient(
                            colors: [
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? category['color']
                                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? category['color']
                                    : category['color'].withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                category['icon'],
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category['name'],
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              category['description'],
                              style: TextStyle(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 3: Payment Method
  Widget _buildStep3(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '💳 Payment Method',
          subtitle: 'How did you pay for this expense?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Payment Methods List
                ...(_paymentMethods.map((method) {
                  final isSelected = _selectedPaymentMethod == method['name'];

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = method['name'];
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [
                              method['color'].withValues(alpha: 0.2),
                              method['color'].withValues(alpha: 0.1),
                            ],
                          )
                              : LinearGradient(
                            colors: [
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? method['color']
                                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? method['color']
                                    : method['color'].withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                method['icon'],
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    method['name'],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    method['description'],
                                    style: TextStyle(
                                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: method['color'],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                })),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 4: Necessity & Description
  Widget _buildStep4(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '📝 Expense Details',
          subtitle: 'How necessary was this expense?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Necessity Level
                Text(
                  'Necessity Level',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                // Necessity Cards
                ..._necessityLevels.map((level) {
                  final isSelected = _selectedNecessity == level['name'];

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedNecessity = level['name'];
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [
                              level['color'].withValues(alpha: 0.2),
                              level['color'].withValues(alpha: 0.1),
                            ],
                          )
                              : LinearGradient(
                            colors: [
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? level['color']
                                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 30,
                              decoration: BoxDecoration(
                                color: level['color'],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    level['name'],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    level['description'],
                                    style: TextStyle(
                                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: level['color'],
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // Description Field
                _buildEnhancedTextField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  hint: 'Add a note about this expense...',
                  isDark: isDark,
                  maxLines: 3,
                  prefixIcon: Icons.note_add,
                  helpText: 'Any additional details or context',
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 5: Custom Fields
  Widget _buildStep5(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🔧 Custom Data',
          subtitle: 'Add personalized expense tracking',
          child: _customFields.isEmpty
              ? _buildEmptyCustomFields(isDark)
              : SingleChildScrollView(
            child: Column(
              children: [
                // Custom Fields List
                ..._customFields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                        colors: [
                          const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                          const Color(0xFF16213E).withValues(alpha: 0.4),
                        ],
                      )
                          : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.8),
                          const Color(0xFFF8FAFF).withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactTextField(
                                controller: field['key']!,
                                label: 'Field Name',
                                hint: 'e.g., Store Name',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _removeCustomField(index),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCompactTextField(
                          controller: field['value']!,
                          label: 'Field Value',
                          hint: 'e.g., Target Store',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                _buildAddCustomFieldButton(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCustomFields(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BCD4).withValues(alpha: 0.2),
                  const Color(0xFF009688).withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_circle_outline,
              size: 40,
              color: const Color(0xFF00BCD4),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'No custom fields yet',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Add custom metrics like store name,\ntax amount, or receipt number',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          _buildAddCustomFieldButton(isDark),
        ],
      ),
    );
  }

  Widget _buildAddCustomFieldButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addCustomField,
        icon: Icon(Icons.add, color: Colors.white, size: 18),
        label: Text(
          'Add Custom Field',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  // Step 6: Review & Save
  Widget _buildStep6(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '✅ Review Your Expense',
          subtitle: 'Confirm your expense data before saving',
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Review Cards
                _buildReviewCard('Amount', '₹${_valueController.text}', Icons.currency_rupee, _getCurrentExpenseColor(), isDark),
                _buildReviewCard('Category', _selectedCategory ?? 'Not selected', _getCurrentExpenseIcon(), _getCurrentExpenseColor(), isDark),

                if (_selectedPaymentMethod != null)
                  _buildReviewCard('Payment Method', _selectedPaymentMethod!, Icons.payment, Colors.blue, isDark),

                if (_selectedNecessity != null)
                  _buildReviewCard('Necessity', _selectedNecessity!, Icons.priority_high, _getCurrentNecessityColor(), isDark),

                if (_descriptionController.text.isNotEmpty)
                  _buildReviewCard('Description', _descriptionController.text, Icons.note, Colors.grey, isDark),

                // Custom Fields Review
                if (_customFields.isNotEmpty) ...[
                  ..._customFields.map((field) {
                    final key = field['key']?.text ?? '';
                    final value = field['value']?.text ?? '';
                    if (key.isNotEmpty && value.isNotEmpty) {
                      return _buildReviewCard(key, value, Icons.settings, Colors.teal, isDark);
                    }
                    return const SizedBox.shrink();
                  }),
                ],

                const SizedBox(height: 24),

                // Enhanced Save Button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCurrentExpenseColor(),
                        _getCurrentExpenseColor().withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getCurrentExpenseColor().withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _saveEntry,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: _isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCurrentExpenseIcon(),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Save Expense Entry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.6),
            const Color(0xFF16213E).withValues(alpha: 0.4),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFF8FAFF).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Content - Use Expanded to prevent overflow
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool autofocus = false,
    IconData? prefixIcon,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                const Color(0xFF16213E).withValues(alpha: 0.4),
              ],
            )
                : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.9),
                const Color(0xFFF8FAFF).withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autofocus: autofocus,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                prefixIcon,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                size: 18,
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 6),
          Text(
            helpText,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                const Color(0xFF16213E).withValues(alpha: 0.4),
              ],
            )
                : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.9),
                const Color(0xFFF8FAFF).withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                fontSize: 12,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedNavigationButtons(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.9),
            const Color(0xFF16213E).withValues(alpha: 0.8),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF8FAFF).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _previousStep,
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: isDark ? Colors.white : Colors.black,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Previous',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next Button
          if (_currentStep < _totalSteps - 1)
            Expanded(
              flex: 2,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentExpenseColor(),
                      _getCurrentExpenseColor().withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _getCurrentExpenseColor().withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _nextStep,
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next Step',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// Enhanced Savings Tracker Screen
class SavingsTrackerScreen extends StatefulWidget {
  const SavingsTrackerScreen({Key? key}) : super(key: key);

  @override
  State<SavingsTrackerScreen> createState() => _SavingsTrackerScreenState();
}

class _SavingsTrackerScreenState extends State<SavingsTrackerScreen>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  int _currentStep = 0;
  final int _totalSteps = 6;

  // Controllers
  final _valueController = TextEditingController();
  final _sourceController = TextEditingController();
  final _goalController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;
  bool _isRecurring = false;
  String? _selectedSource;

  // Enhanced sources with icons and colors
  final List<Map<String, dynamic>> _sources = [
    {'name': 'Salary', 'icon': Icons.work, 'color': Color(0xFF4CAF50), 'description': 'Monthly income'},
    {'name': 'Freelance', 'icon': Icons.computer, 'color': Color(0xFF2196F3), 'description': 'Project work'},
    {'name': 'Investment', 'icon': Icons.trending_up, 'color': Color(0xFF9C27B0), 'description': 'Returns & dividends'},
    {'name': 'Gift', 'icon': Icons.card_giftcard, 'color': Color(0xFFE91E63), 'description': 'Money received'},
    {'name': 'Bonus', 'icon': Icons.star, 'color': Color(0xFFFF9800), 'description': 'Work reward'},
    {'name': 'Side Hustle', 'icon': Icons.business_center, 'color': Color(0xFF607D8B), 'description': 'Extra income'},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Color(0xFF795548), 'description': 'Other sources'},
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    _valueController.dispose();
    _sourceController.dispose();
    _goalController.dispose();
    _descriptionController.dispose();

    for (var field in _customFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _restartAnimations();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _restartAnimations();
    }
  }

  void _restartAnimations() {
    _slideController.reset();
    _scaleController.reset();
    _slideController.forward();
    _scaleController.forward();
  }

  void _addCustomField() {
    HapticFeedback.selectionClick();
    setState(() {
      _customFields.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeCustomField(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _customFields[index]['key']?.dispose();
      _customFields[index]['value']?.dispose();
      _customFields.removeAt(index);
    });
  }

  Future<void> _saveEntry() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customData = <String, dynamic>{};
      for (var field in _customFields) {
        final key = field['key']?.text ?? '';
        final value = field['value']?.text ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          customData[key] = value;
        }
      }

      final entryData = {
        'value': double.tryParse(_valueController.text) ?? 0.0,
        'source': _selectedSource ?? _sourceController.text.trim(),
        'towardsGoal': _goalController.text.trim(),
        'description': _descriptionController.text.trim(),
        'recurring': _isRecurring,
        'customData': customData,
        'trackerType': 'savings',
      };

      await TrackerService.saveTrackerEntry('savings', entryData);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Savings entry saved successfully! 💰'),
              ],
            ),
            backgroundColor: _getCurrentSavingsColor(),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        Navigator.pop(context);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error saving entry: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getCurrentSavingsColor() {
    if (_selectedSource != null) {
      final source = _sources.firstWhere(
            (src) => src['name'] == _selectedSource,
        orElse: () => _sources[0],
      );
      return source['color'];
    }
    return const Color(0xFF4CAF50);
  }

  IconData _getCurrentSavingsIcon() {
    if (_selectedSource != null) {
      final source = _sources.firstWhere(
            (src) => src['name'] == _selectedSource,
        orElse: () => _sources[0],
      );
      return source['icon'];
    }
    return Icons.savings;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: _getGradientBackground(isDark),
          body: Container(
            decoration: BoxDecoration(
              gradient: _getBackgroundGradient(isDark),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Enhanced Progress Header - Fixed height
                    SizedBox(
                      height: 140,
                      child: _buildEnhancedProgressHeader(isDark),
                    ),

                    // Page View with proper constraints
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(isDark), // Amount
                          _buildStep2(isDark), // Source
                          _buildStep3(isDark), // Goal & Recurring
                          _buildStep4(isDark), // Description
                          _buildStep5(isDark), // Custom Fields
                          _buildStep6(isDark), // Review & Save
                        ],
                      ),
                    ),

                    // Enhanced Navigation Buttons - Fixed height
                    SizedBox(
                      height: 120,
                      child: _buildEnhancedNavigationButtons(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getGradientBackground(bool isDark) {
    return isDark
        ? const Color(0xFF0A0A0F)
        : const Color(0xFFF8FAFF);
  }

  Gradient _getBackgroundGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
        const Color(0xFF0A0A0F),
        const Color(0xFF1A1A2E),
        const Color(0xFF16213E),
      ]
          : [
        const Color(0xFFF8FAFF),
        const Color(0xFFE8F4FD),
        const Color(0xFFDDF4FF),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  Widget _buildEnhancedProgressHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.9),
            const Color(0xFF16213E).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF8FAFF).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              // Back Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white : Colors.black,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title Section
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCurrentSavingsColor(),
                            _getCurrentSavingsColor().withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          _getCurrentSavingsIcon(),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Savings Tracker',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_getStepTitle(_currentStep)}',
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // **🔧 FIXED PROGRESS CIRCLE - PROPERLY CENTERED**
              Container(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center, // ✅ This centers everything
                  children: [
                    // Background Circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    // Progress Circle - ✅ Properly sized and centered
                    SizedBox(
                      width: 46, // ✅ Slightly smaller than container
                      height: 46,
                      child: CircularProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                        strokeWidth: 3,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCurrentSavingsColor(),
                        ),
                      ),
                    ),
                    // Center Text - ✅ Perfectly centered
                    Container(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: Text(
                          '${_currentStep + 1}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Enhanced Progress Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getCurrentSavingsColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Amount';
      case 1: return 'Source';
      case 2: return 'Goal & Recurring';
      case 3: return 'Description';
      case 4: return 'Custom Data';
      case 5: return 'Review';
      default: return '';
    }
  }

  // Step 1: Amount
  Widget _buildStep1(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '💰 Savings Amount',
          subtitle: 'How much did you save?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Animated Savings Icon with shimmer
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            const Color(0xFF81C784).withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.3 * _shimmerAnimation.value),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.savings,
                          size: 50,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _valueController,
                  label: 'Amount',
                  hint: '₹ 0.00',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  autofocus: true,
                  prefixIcon: Icons.currency_rupee,
                  helpText: 'Enter the total amount saved',
                ),

                const SizedBox(height: 20),

                // Amount Suggestions
                _buildAmountSuggestions(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountSuggestions(bool isDark) {
    final suggestions = [500, 1000, 2000, 5000, 10000, 25000];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick amounts:',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions.map((amount) => GestureDetector(
              onTap: () {
                _valueController.text = amount.toString();
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '₹$amount',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Step 2: Source
  Widget _buildStep2(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '💼 Savings Source',
          subtitle: 'Where did this money come from?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Sources Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _sources.length,
                  itemBuilder: (context, index) {
                    final source = _sources[index];
                    final isSelected = _selectedSource == source['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSource = source['name'];
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [
                              source['color'].withValues(alpha: 0.2),
                              source['color'].withValues(alpha: 0.1),
                            ],
                          )
                              : LinearGradient(
                            colors: [
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? source['color']
                                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? source['color']
                                    : source['color'].withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                source['icon'],
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              source['name'],
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              source['description'],
                              style: TextStyle(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 3: Goal & Recurring
  Widget _buildStep3(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🎯 Savings Goal',
          subtitle: 'What are you saving for?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.2),
                        const Color(0xFFFFA500).withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flag,
                    size: 40,
                    color: const Color(0xFFFFD700),
                  ),
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _goalController,
                  label: 'Towards Goal',
                  hint: 'e.g., Emergency fund, Vacation, New car...',
                  isDark: isDark,
                  autofocus: true,
                  prefixIcon: Icons.flag_outlined,
                  helpText: 'What are you saving this money for?',
                ),

                const SizedBox(height: 20),

                // Goal Suggestions
                _buildGoalSuggestions(isDark),

                const SizedBox(height: 20),

                // Recurring Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? LinearGradient(
                      colors: [
                        const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                        const Color(0xFF16213E).withValues(alpha: 0.4),
                      ],
                    )
                        : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.9),
                        const Color(0xFFF8FAFF).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isRecurring
                              ? const Color(0xFF4CAF50)
                              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.repeat,
                          color: _isRecurring
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recurring Savings',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Is this a regular monthly saving?',
                              style: TextStyle(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                          HapticFeedback.selectionClick();
                        },
                        activeColor: const Color(0xFF4CAF50),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSuggestions(bool isDark) {
    final suggestions = [
      'Emergency Fund', 'Vacation', 'New Car', 'House Down Payment',
      'Wedding', 'Education', 'Retirement', 'Investment'
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular goals:',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions.map((goal) => GestureDetector(
              onTap: () {
                _goalController.text = goal;
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  goal,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 11,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Step 4: Description
  Widget _buildStep4(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '📝 Additional Notes',
          subtitle: 'Any additional details about this saving?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF9C27B0).withValues(alpha: 0.2),
                        const Color(0xFFBA68C8).withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_note,
                    size: 40,
                    color: const Color(0xFF9C27B0),
                  ),
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  hint: 'Add any notes about this savings entry...',
                  isDark: isDark,
                  maxLines: 4,
                  autofocus: true,
                  prefixIcon: Icons.note_add,
                  helpText: 'Any additional context or details',
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 5: Custom Fields (same structure as expense tracker)
  Widget _buildStep5(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🔧 Custom Data',
          subtitle: 'Add personalized savings tracking',
          child: _customFields.isEmpty
              ? _buildEmptyCustomFields(isDark)
              : SingleChildScrollView(
            child: Column(
              children: [
                // Custom Fields List
                ..._customFields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                        colors: [
                          const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                          const Color(0xFF16213E).withValues(alpha: 0.4),
                        ],
                      )
                          : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.8),
                          const Color(0xFFF8FAFF).withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactTextField(
                                controller: field['key']!,
                                label: 'Field Name',
                                hint: 'e.g., Account Type',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _removeCustomField(index),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCompactTextField(
                          controller: field['value']!,
                          label: 'Field Value',
                          hint: 'e.g., Savings Account',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                _buildAddCustomFieldButton(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCustomFields(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BCD4).withValues(alpha: 0.2),
                  const Color(0xFF009688).withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_circle_outline,
              size: 40,
              color: const Color(0xFF00BCD4),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'No custom fields yet',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Add custom metrics like account type,\ninvestment plan, or target date',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          _buildAddCustomFieldButton(isDark),
        ],
      ),
    );
  }

  Widget _buildAddCustomFieldButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addCustomField,
        icon: Icon(Icons.add, color: Colors.white, size: 18),
        label: Text(
          'Add Custom Field',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  // Step 6: Review & Save
  Widget _buildStep6(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '✅ Review Your Savings',
          subtitle: 'Confirm your savings data before saving',
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Review Cards
                _buildReviewCard('Amount', '₹${_valueController.text}', Icons.currency_rupee, _getCurrentSavingsColor(), isDark),
                _buildReviewCard('Source', _selectedSource ?? 'Not selected', _getCurrentSavingsIcon(), _getCurrentSavingsColor(), isDark),

                if (_goalController.text.isNotEmpty)
                  _buildReviewCard('Goal', _goalController.text, Icons.flag, Colors.amber, isDark),

                _buildReviewCard('Recurring', _isRecurring ? 'Yes' : 'No', Icons.repeat, _isRecurring ? Colors.green : Colors.grey, isDark),

                if (_descriptionController.text.isNotEmpty)
                  _buildReviewCard('Description', _descriptionController.text, Icons.note, Colors.purple, isDark),

                // Custom Fields Review
                if (_customFields.isNotEmpty) ...[
                  ..._customFields.map((field) {
                    final key = field['key']?.text ?? '';
                    final value = field['value']?.text ?? '';
                    if (key.isNotEmpty && value.isNotEmpty) {
                      return _buildReviewCard(key, value, Icons.settings, Colors.teal, isDark);
                    }
                    return const SizedBox.shrink();
                  }),
                ],

                const SizedBox(height: 24),

                // Enhanced Save Button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCurrentSavingsColor(),
                        _getCurrentSavingsColor().withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getCurrentSavingsColor().withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _saveEntry,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: _isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCurrentSavingsIcon(),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Save Savings Entry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.6),
            const Color(0xFF16213E).withValues(alpha: 0.4),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFF8FAFF).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods (same as expense tracker)
  Widget _buildStepContainer({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Content - Use Expanded to prevent overflow
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool autofocus = false,
    IconData? prefixIcon,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                const Color(0xFF16213E).withValues(alpha: 0.4),
              ],
            )
                : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.9),
                const Color(0xFFF8FAFF).withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autofocus: autofocus,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                prefixIcon,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                size: 18,
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 6),
          Text(
            helpText,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
            decoration: BoxDecoration(
            gradient: isDark
            ? LinearGradient(
            colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.6),
        const Color(0xFF16213E).withValues(alpha: 0.4),
      ],
    )
        : LinearGradient(
    colors: [
    Colors.white.withValues(alpha: 0.9),
    const Color(0xFFF8FAFF).withValues(alpha: 0.7),
    ],
    ),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
    ),
    ),
    child: TextFormField(
    controller: controller,
    style: TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: 12,
    ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
          fontSize: 12,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(12),
      ),
    ),
        ),
      ],
    );
  }

  Widget _buildEnhancedNavigationButtons(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.9),
            const Color(0xFF16213E).withValues(alpha: 0.8),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF8FAFF).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _previousStep,
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: isDark ? Colors.white : Colors.black,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Previous',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next Button
          if (_currentStep < _totalSteps - 1)
            Expanded(
              flex: 2,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentSavingsColor(),
                      _getCurrentSavingsColor().withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _getCurrentSavingsColor().withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _nextStep,
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next Step',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// Enhanced Alcohol Tracker Screen
class AlcoholTrackerScreen extends StatefulWidget {
  const AlcoholTrackerScreen({Key? key}) : super(key: key);

  @override
  State<AlcoholTrackerScreen> createState() => _AlcoholTrackerScreenState();
}

class _AlcoholTrackerScreenState extends State<AlcoholTrackerScreen>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  int _currentStep = 0;
  final int _totalSteps = 6;

  // Controllers
  final _valueController = TextEditingController();
  final _locationController = TextEditingController();
  final _reasonController = TextEditingController();

  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;
  String? _selectedType;
  String? _selectedSituation;

  // Enhanced alcohol types with icons and colors
  final List<Map<String, dynamic>> _alcoholTypes = [
    {'name': 'Beer', 'icon': Icons.sports_bar, 'color': Color(0xFFFFB74D), 'description': 'Light & refreshing'},
    {'name': 'Wine', 'icon': Icons.wine_bar, 'color': Color(0xFF8E24AA), 'description': 'Elegant & sophisticated'},
    {'name': 'Whiskey', 'icon': Icons.local_bar, 'color': Color(0xFF6D4C41), 'description': 'Strong & smooth'},
    {'name': 'Vodka', 'icon': Icons.liquor, 'color': Color(0xFF42A5F5), 'description': 'Clean & crisp'},
    {'name': 'Rum', 'icon': Icons.emoji_food_beverage, 'color': Color(0xFFD4AF37), 'description': 'Sweet & tropical'},
    {'name': 'Cocktail', 'icon': Icons.local_drink, 'color': Color(0xFFEC407A), 'description': 'Mixed & fruity'},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Color(0xFF78909C), 'description': 'Other beverages'},
  ];

  // Enhanced situations with icons and colors
  final List<Map<String, dynamic>> _situations = [
    {'name': 'Social Gathering', 'icon': Icons.group, 'color': Color(0xFF4CAF50), 'description': 'With friends & family'},
    {'name': 'Dinner', 'icon': Icons.restaurant, 'color': Color(0xFFFF9800), 'description': 'During meals'},
    {'name': 'Celebration', 'icon': Icons.celebration, 'color': Color(0xFFE91E63), 'description': 'Special occasions'},
    {'name': 'Relaxation', 'icon': Icons.self_improvement, 'color': Color(0xFF9C27B0), 'description': 'To unwind'},
    {'name': 'Work Event', 'icon': Icons.work, 'color': Color(0xFF3F51B5), 'description': 'Business occasions'},
    {'name': 'Date', 'icon': Icons.favorite, 'color': Color(0xFFF44336), 'description': 'Romantic setting'},
    {'name': 'Alone', 'icon': Icons.person, 'color': Color(0xFF607D8B), 'description': 'Solo drinking'},
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _valueController.dispose();
    _locationController.dispose();
    _reasonController.dispose();

    for (var field in _customFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _restartAnimations();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      _restartAnimations();
    }
  }

  void _restartAnimations() {
    _slideController.reset();
    _scaleController.reset();
    _slideController.forward();
    _scaleController.forward();
  }

  void _addCustomField() {
    HapticFeedback.selectionClick();
    setState(() {
      _customFields.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeCustomField(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _customFields[index]['key']?.dispose();
      _customFields[index]['value']?.dispose();
      _customFields.removeAt(index);
    });
  }

  Future<void> _saveEntry() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customData = <String, dynamic>{};
      for (var field in _customFields) {
        final key = field['key']?.text ?? '';
        final value = field['value']?.text ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          customData[key] = value;
        }
      }

      final entryData = {
        'value': double.tryParse(_valueController.text) ?? 0.0,
        'type': _selectedType ?? '',
        'situation': _selectedSituation ?? '',
        'location': _locationController.text.trim(),
        'reason': _reasonController.text.trim(),
        'customData': customData,
        'trackerType': 'alcohol',
      };

      await TrackerService.saveTrackerEntry('alcohol', entryData);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Alcohol entry saved successfully! 🍻'),
              ],
            ),
            backgroundColor: _getCurrentAlcoholColor(),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        Navigator.pop(context);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error saving entry: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getCurrentAlcoholColor() {
    if (_selectedType != null) {
      final type = _alcoholTypes.firstWhere(
            (t) => t['name'] == _selectedType,
        orElse: () => _alcoholTypes[0],
      );
      return type['color'];
    }
    return const Color(0xFFFFB74D);
  }

  IconData _getCurrentAlcoholIcon() {
    if (_selectedType != null) {
      final type = _alcoholTypes.firstWhere(
            (t) => t['name'] == _selectedType,
        orElse: () => _alcoholTypes[0],
      );
      return type['icon'];
    }
    return Icons.local_bar;
  }

  Color _getCurrentSituationColor() {
    if (_selectedSituation != null) {
      final situation = _situations.firstWhere(
            (s) => s['name'] == _selectedSituation,
        orElse: () => _situations[0],
      );
      return situation['color'];
    }
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: _getGradientBackground(isDark),
          body: Container(
            decoration: BoxDecoration(
              gradient: _getBackgroundGradient(isDark),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Enhanced Progress Header - Fixed height
                    SizedBox(
                      height: 140,
                      child: _buildEnhancedProgressHeader(isDark),
                    ),

                    // Page View with proper constraints
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(isDark), // Amount
                          _buildStep2(isDark), // Type
                          _buildStep3(isDark), // Situation
                          _buildStep4(isDark), // Location & Reason
                          _buildStep5(isDark), // Custom Fields
                          _buildStep6(isDark), // Review & Save
                        ],
                      ),
                    ),

                    // Enhanced Navigation Buttons - Fixed height
                    SizedBox(
                      height: 120,
                      child: _buildEnhancedNavigationButtons(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getGradientBackground(bool isDark) {
    return isDark
        ? const Color(0xFF0A0A0F)
        : const Color(0xFFF8FAFF);
  }

  Gradient _getBackgroundGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
        const Color(0xFF0A0A0F),
        const Color(0xFF1A1A2E),
        const Color(0xFF16213E),
      ]
          : [
        const Color(0xFFF8FAFF),
        const Color(0xFFE8F4FD),
        const Color(0xFFDDF4FF),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  Widget _buildEnhancedProgressHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.9),
            const Color(0xFF16213E).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF8FAFF).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              // Back Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white : Colors.black,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title Section
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCurrentAlcoholColor(),
                            _getCurrentAlcoholColor().withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          _getCurrentAlcoholIcon(),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Alcohol Tracker',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_getStepTitle(_currentStep)}',
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // **🔧 FIXED PROGRESS CIRCLE - PROPERLY CENTERED**
              Container(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center, // ✅ This centers everything
                  children: [
                    // Background Circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    // Progress Circle - ✅ Properly sized and centered
                    SizedBox(
                      width: 46, // ✅ Slightly smaller than container
                      height: 46,
                      child: CircularProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                        strokeWidth: 3,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCurrentAlcoholColor(),
                        ),
                      ),
                    ),
                    // Center Text - ✅ Perfectly centered
                    Container(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: Text(
                          '${_currentStep + 1}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Enhanced Progress Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getCurrentAlcoholColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Amount';
      case 1: return 'Type';
      case 2: return 'Situation';
      case 3: return 'Details';
      case 4: return 'Custom Data';
      case 5: return 'Review';
      default: return '';
    }
  }
// Step 1: Amount
  Widget _buildStep1(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🍻 Alcohol Amount',
          subtitle: 'How many drinks did you have?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Animated Alcohol Icon
                AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateAnimation.value * 0.1,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFB74D).withValues(alpha: 0.3),
                              const Color(0xFFFFE082).withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFFB74D),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.local_bar,
                            size: 50,
                            color: const Color(0xFFFFB74D),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _valueController,
                  label: 'Number of Drinks',
                  hint: '1, 2, 3...',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  autofocus: true,
                  prefixIcon: Icons.local_bar,
                  helpText: 'Enter the total number of drinks consumed',
                ),

                const SizedBox(height: 20),

                // Drink Count Suggestions
                _buildDrinkSuggestions(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrinkSuggestions(bool isDark) {
    final suggestions = [1, 2, 3, 4, 5, 6];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick counts:',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((count) => GestureDetector(
              onTap: () {
                _valueController.text = count.toString();
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFB74D).withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

// Step 2: Type
  Widget _buildStep2(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🥃 Alcohol Type',
          subtitle: 'What type of alcohol did you drink?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Alcohol Types Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _alcoholTypes.length,
                  itemBuilder: (context, index) {
                    final type = _alcoholTypes[index];
                    final isSelected = _selectedType == type['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = type['name'];
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [
                              type['color'].withValues(alpha: 0.2),
                              type['color'].withValues(alpha: 0.1),
                            ],
                          )
                              : LinearGradient(
                            colors: [
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? type['color']
                                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? type['color']
                                    : type['color'].withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                type['icon'],
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type['name'],
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type['description'],
                              style: TextStyle(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Step 3: Situation
  Widget _buildStep3(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '👥 Drinking Situation',
          subtitle: 'What was the occasion or setting?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Situations List
                ...(_situations.map((situation) {
                  final isSelected = _selectedSituation == situation['name'];

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSituation = situation['name'];
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [
                              situation['color'].withValues(alpha: 0.2),
                              situation['color'].withValues(alpha: 0.1),
                            ],
                          )
                              : LinearGradient(
                            colors: [
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? situation['color']
                                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? situation['color']
                                    : situation['color'].withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                situation['icon'],
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    situation['name'],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    situation['description'],
                                    style: TextStyle(
                                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: situation['color'],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                })),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Step 4: Location & Reason
  Widget _buildStep4(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '📍 Additional Details',
          subtitle: 'Where and why did you drink?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                _buildEnhancedTextField(
                  controller: _locationController,
                  label: 'Location (Optional)',
                  hint: 'Where did you drink? e.g., Home, Restaurant, Bar...',
                  isDark: isDark,
                  prefixIcon: Icons.location_on,
                  helpText: 'The place where you consumed alcohol',
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _reasonController,
                  label: 'Reason (Optional)',
                  hint: 'Why did you drink? e.g., Celebrating, Relaxing...',
                  isDark: isDark,
                  maxLines: 3,
                  prefixIcon: Icons.psychology,
                  helpText: 'Your motivation or reason for drinking',
                ),

                const SizedBox(height: 20),

                // Quick location suggestions
                _buildLocationSuggestions(isDark),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSuggestions(bool isDark) {
    final locations = ['Home', 'Restaurant', 'Bar', 'Club', 'Friend\'s House', 'Outdoor Event'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common locations:',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: locations.map((location) => GestureDetector(
              onTap: () {
                _locationController.text = location;
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFB74D).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  location,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

// Step 5: Custom Fields (same structure as other trackers)
  Widget _buildStep5(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🔧 Custom Data',
          subtitle: 'Add personalized alcohol tracking',
          child: _customFields.isEmpty
              ? _buildEmptyCustomFields(isDark)
              : SingleChildScrollView(
            child: Column(
              children: [
                // Custom Fields List
                ..._customFields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                        colors: [
                          const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                          const Color(0xFF16213E).withValues(alpha: 0.4),
                        ],
                      )
                          : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.8),
                          const Color(0xFFF8FAFF).withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactTextField(
                                controller: field['key']!,
                                label: 'Field Name',
                                hint: 'e.g., Brand Name',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _removeCustomField(index),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCompactTextField(
                          controller: field['value']!,
                          label: 'Field Value',
                          hint: 'e.g., Heineken',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                _buildAddCustomFieldButton(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCustomFields(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BCD4).withValues(alpha: 0.2),
                  const Color(0xFF009688).withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_circle_outline,
              size: 40,
              color: const Color(0xFF00BCD4),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'No custom fields yet',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Add custom metrics like brand name,\nalcohol percentage, or price',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          _buildAddCustomFieldButton(isDark),
        ],
      ),
    );
  }

  Widget _buildAddCustomFieldButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addCustomField,
        icon: Icon(Icons.add, color: Colors.white, size: 18),
        label: Text(
          'Add Custom Field',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

// Step 6: Review & Save
  Widget _buildStep6(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '✅ Review Your Entry',
          subtitle: 'Confirm your alcohol tracking data before saving',
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Review Cards
                _buildReviewCard('Drinks Count', '${_valueController.text} drinks', Icons.local_bar, _getCurrentAlcoholColor(), isDark),

                if (_selectedType != null)
                  _buildReviewCard('Alcohol Type', _selectedType!, _getCurrentAlcoholIcon(), _getCurrentAlcoholColor(), isDark),

                if (_selectedSituation != null)
                  _buildReviewCard('Situation', _selectedSituation!, Icons.group, _getCurrentSituationColor(), isDark),

                if (_locationController.text.isNotEmpty)
                  _buildReviewCard('Location', _locationController.text, Icons.location_on, Colors.blue, isDark),

                if (_reasonController.text.isNotEmpty)
                  _buildReviewCard('Reason', _reasonController.text, Icons.psychology, Colors.purple, isDark),

                // Custom Fields Review
                if (_customFields.isNotEmpty) ...[
                  ..._customFields.map((field) {
                    final key = field['key']?.text ?? '';
                    final value = field['value']?.text ?? '';
                    if (key.isNotEmpty && value.isNotEmpty) {
                      return _buildReviewCard(key, value, Icons.settings, Colors.teal, isDark);
                    }
                    return const SizedBox.shrink();
                  }),
                ],

                const SizedBox(height: 24),

                // Enhanced Save Button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCurrentAlcoholColor(),
                        _getCurrentAlcoholColor().withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getCurrentAlcoholColor().withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _saveEntry,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: _isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCurrentAlcoholIcon(),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Save Alcohol Entry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.6),
            const Color(0xFF16213E).withValues(alpha: 0.4),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFF8FAFF).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Helper methods (same as expense and savings trackers)
  Widget _buildStepContainer({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Content - Use Expanded to prevent overflow
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool autofocus = false,
    IconData? prefixIcon,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                const Color(0xFF16213E).withValues(alpha: 0.4),
              ],
            )
                : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.9),
                const Color(0xFFF8FAFF).withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autofocus: autofocus,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                prefixIcon,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                size: 18,
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 6),
          Text(
            helpText,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                const Color(0xFF16213E).withValues(alpha: 0.4),
              ],
            )
                : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.9),
                const Color(0xFFF8FAFF).withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                fontSize: 12,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedNavigationButtons(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.9),
            const Color(0xFF16213E).withValues(alpha: 0.8),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF8FAFF).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _previousStep,
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: isDark ? Colors.white : Colors.black,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Previous',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next Button
          if (_currentStep < _totalSteps - 1)
            Expanded(
              flex: 2,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentAlcoholColor(),
                      _getCurrentAlcoholColor().withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _getCurrentAlcoholColor().withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _nextStep,
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next Step',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

// Make sure to close the AlcoholTrackerScreen class
}

// All the step building methods (_buildStep1 through _buildStep6)
// All the helper methods (_buildStepContainer, _buildEnhancedTextField, etc.)

