class OnboardingData {
  String gender;
  String otherApps;
  String workoutFrequency;
  int heightFeet;
  int heightInches;
  double weightLbs;
  bool isMetric;
  DateTime? dateOfBirth;
  String goal;
  String accomplishment;
  double desiredWeight;
  String goalPace;
  String dietPreference;
  DateTime? completedAt;
  
  // New target fields
  double? targetAmount;
  String? targetUnit;
  int? targetTimeframe;

  // Computed properties for BMI calculation
  double get heightCm => (heightFeet * 12 + heightInches) * 2.54;
  double get weightKg => weightLbs * 0.453592;
  double get heightInMeters => heightCm / 100;

  OnboardingData({
    this.gender = '',
    this.otherApps = '',
    this.workoutFrequency = '',
    this.heightFeet = 5,
    this.heightInches = 6,
    this.weightLbs = 119.0,
    this.isMetric = false,
    this.dateOfBirth,
    this.goal = '',
    this.accomplishment = '',
    this.desiredWeight = 110.0,
    this.goalPace = '',
    this.dietPreference = '',
    this.completedAt,
    this.targetAmount,
    this.targetUnit,
    this.targetTimeframe,
  });

  // Method to calculate BMI
  double calculateBMI() {
    if (heightInMeters <= 0 || weightKg <= 0) {
      return 22.0; // Default BMI
    }
    return weightKg / (heightInMeters * heightInMeters);
  }

  // Method to get health score based on BMI
  Map<String, dynamic> getHealthScore() {
    double bmi = calculateBMI();
    double healthScore;
    String category;
    String message;

    if (bmi >= 18.5 && bmi <= 24.9) {
      double idealBMI = 22.5;
      double distance = (bmi - idealBMI).abs();
      if (distance <= 1.0) {
        healthScore = 10.0;
        category = 'Excellent Weight';
        message = 'Perfect! You\'re in the ideal weight range.';
      } else if (distance <= 2.5) {
        healthScore = 9.0;
        category = 'Normal Weight';
        message = 'Great! You\'re in the healthy weight range.';
      } else {
        healthScore = 8.0;
        category = 'Normal Weight';
        message = 'Good! You\'re in the healthy weight range.';
      }
    } else if (bmi >= 25.0 && bmi <= 29.9) {
      if (bmi <= 26.0) {
        healthScore = 7.0;
        category = 'Slightly Overweight';
        message = 'You\'re slightly above the healthy range. Small changes can make a big difference!';
      } else if (bmi <= 28.0) {
        healthScore = 6.0;
        category = 'Overweight';
        message = 'You\'re above the healthy range. Let\'s work on getting you back to optimal health.';
      } else {
        healthScore = 5.0;
        category = 'Overweight';
        message = 'You\'re significantly above the healthy range. We\'ll create a plan to help you reach your goals.';
      }
    } else if (bmi >= 30.0) {
      if (bmi <= 35.0) {
        healthScore = 4.0;
        category = 'Class I Obesity';
        message = 'You\'re in the obese range. We\'ll work together to create a sustainable weight loss plan.';
      } else if (bmi <= 40.0) {
        healthScore = 3.0;
        category = 'Class II Obesity';
        message = 'You\'re in the severely obese range. We\'ll create a comprehensive plan with medical guidance.';
      } else {
        healthScore = 2.0;
        category = 'Class III Obesity';
        message = 'You\'re in the very severely obese range. We\'ll work with healthcare professionals for your safety.';
      }
    } else {
      if (bmi >= 17.0) {
        healthScore = 6.0;
        category = 'Mildly Underweight';
        message = 'You\'re slightly below the healthy range. Focus on healthy weight gain and nutrition.';
      } else if (bmi >= 16.0) {
        healthScore = 5.0;
        category = 'Underweight';
        message = 'You\'re below the healthy range. We\'ll help you gain weight safely and healthily.';
      } else {
        healthScore = 4.0;
        category = 'Severely Underweight';
        message = 'You\'re significantly below the healthy range. We\'ll work with healthcare professionals.';
      }
    }

    return {
      'bmi': bmi,
      'healthScore': healthScore,
      'category': category,
      'message': message,
    };
  }

  // Convert to Map for storage (keep DateTime objects for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'otherApps': otherApps,
      'workoutFrequency': workoutFrequency,
      'heightFeet': heightFeet,
      'heightInches': heightInches,
      'heightCm': heightCm.round(),
      'weightLbs': weightLbs,
      'weightKg': weightKg,
      'isMetric': isMetric,
      'dateOfBirth': dateOfBirth,
      'goal': goal,
      'accomplishment': accomplishment,
      'desiredWeight': desiredWeight,
      'goalPace': goalPace,
      'dietPreference': dietPreference,
      'completedAt': completedAt,
      'targetAmount': targetAmount,
      'targetUnit': targetUnit,
      'targetTimeframe': targetTimeframe,
    };
  }

  // Create from Map
  factory OnboardingData.fromMap(Map<String, dynamic> map) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      // Handle Firestore Timestamp
      if (value.toString().contains('Timestamp')) {
        // This is a Firestore Timestamp, we'll need to handle it differently
        // For now, return null and let the service handle it
        return null;
      }
      return null;
    }

    return OnboardingData(
      gender: map['gender'] ?? '',
      otherApps: map['otherApps'] ?? '',
      workoutFrequency: map['workoutFrequency'] ?? '',
      heightFeet: map['heightFeet'] ?? 5,
      heightInches: map['heightInches'] ?? 6,
      weightLbs: (map['weightLbs'] ?? 119.0).toDouble(),
      isMetric: map['isMetric'] ?? false,
      dateOfBirth: parseDateTime(map['dateOfBirth']),
      goal: map['goal'] ?? '',
      accomplishment: map['accomplishment'] ?? '',
      desiredWeight: (map['desiredWeight'] ?? 110.0).toDouble(),
      goalPace: map['goalPace'] ?? '',
      dietPreference: map['dietPreference'] ?? '',
      completedAt: parseDateTime(map['completedAt']),
      targetAmount: map['targetAmount']?.toDouble(),
      targetUnit: map['targetUnit'],
      targetTimeframe: map['targetTimeframe'],
    );
  }
}