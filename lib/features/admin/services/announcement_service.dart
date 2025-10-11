import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnnouncementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _collection = 'announcements';

  /// Create a new announcement (Admin only)
  static Future<void> createAnnouncement({
    required String title,
    required String message,
    required String priority, // 'high', 'medium', 'low'
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'title': title,
        'message': message,
        'priority': priority,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin1@gmail.com', // For offline admin
        'isActive': true,
        'views': 0,
      });
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  /// Get all active announcements (Real-time stream)
  static Stream<List<Map<String, dynamic>>> getAnnouncementsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((announcement) => announcement['isActive'] == true).toList();
    });
  }

  /// Get announcements for admin (includes inactive ones)
  static Stream<List<Map<String, dynamic>>> getAdminAnnouncementsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Update announcement status (Admin only)
  static Future<void> updateAnnouncementStatus(String announcementId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(announcementId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  /// Delete announcement (Admin only)
  static Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection(_collection).doc(announcementId).delete();
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  /// Increment view count
  static Future<void> incrementViewCount(String announcementId) async {
    try {
      await _firestore.collection(_collection).doc(announcementId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Failed to increment view count: $e');
    }
  }

  /// Format timestamp to readable string
  static String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get priority color
  static String getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '📢';
    }
  }

  /// Get count of announcements (for badge)
  static Stream<int> getAnnouncementsCountStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) => doc.data()['isActive'] == true).length;
    });
  }
}