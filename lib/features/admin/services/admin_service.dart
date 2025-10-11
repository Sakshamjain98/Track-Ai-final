class AdminService {
  // List of admin email addresses
  static const List<String> _adminEmails = [
    'admin1@gmail.com',
    // Add more admin emails here as needed
  ];

  /// Check if the given email belongs to an admin user
  static bool isAdminEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return _adminEmails.contains(email.toLowerCase().trim());
  }

  /// Check if the current user is an admin
  static bool isCurrentUserAdmin() {
    // This can be extended to check Firebase Auth current user
    return false; // Placeholder for now
  }

  /// Get all admin emails (for management purposes)
  static List<String> getAdminEmails() {
    return List.unmodifiable(_adminEmails);
  }

  /// Validate admin credentials (basic check)
  static bool validateAdminCredentials(String email, String password) {
    // Basic validation - in production, this would be more secure
    return email.toLowerCase().trim() == 'admin1@gmail.com' && 
           password == 'admin1234@';
  }
}