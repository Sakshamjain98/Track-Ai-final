import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _lastSeenKey = 'last_seen_announcement_timestamp';
  
  /// Get unseen announcements count
  static Future<int> getUnseenAnnouncementsCount() async {
    try {
      final lastSeenTimestamp = await _getLastSeenTimestamp();
      
      final query = _firestore
          .collection('announcements')
          .where('isActive', isEqualTo: true)
          .where('createdAt', isGreaterThan: lastSeenTimestamp != null 
              ? Timestamp.fromDate(lastSeenTimestamp) 
              : null);
              
      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unseen announcements count: $e');
      return 0;
    }
  }

  /// Get unseen announcements count as a stream
  static Stream<int> getUnseenAnnouncementsCountStream() async* {
    try {
      final lastSeenTimestamp = await _getLastSeenTimestamp();
      
      yield* _firestore
          .collection('announcements')
          .where('isActive', isEqualTo: true)
          .where('createdAt', isGreaterThan: lastSeenTimestamp != null 
              ? Timestamp.fromDate(lastSeenTimestamp) 
              : null)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Error streaming unseen announcements count: $e');
      yield 0;
    }
  }

  /// Mark all announcements as seen (call when user opens announcements page)
  static Future<void> markAllAnnouncementsAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSeenKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error marking announcements as seen: $e');
    }
  }

  /// Get the last seen timestamp from SharedPreferences
  static Future<DateTime?> _getLastSeenTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSeenKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      print('Error getting last seen timestamp: $e');
      return null;
    }
  }

  /// Clear all notification data (useful for testing)
  static Future<void> clearNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSeenKey);
    } catch (e) {
      print('Error clearing notification data: $e');
    }
  }
}