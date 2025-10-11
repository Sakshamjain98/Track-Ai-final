import 'package:shared_preferences/shared_preferences.dart';
import '../../admin/services/announcement_service.dart';

class UnseenAnnouncementsService {
  static const String _seenAnnouncementsKey = 'seen_announcements';

  /// Mark announcement as seen
  static Future<void> markAsSeen(String announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    final seenIds = prefs.getStringList(_seenAnnouncementsKey) ?? [];
    
    if (!seenIds.contains(announcementId)) {
      seenIds.add(announcementId);
      await prefs.setStringList(_seenAnnouncementsKey, seenIds);
    }
  }

  /// Mark all current announcements as seen
  static Future<void> markAllAsSeen(List<String> announcementIds) async {
    final prefs = await SharedPreferences.getInstance();
    final seenIds = prefs.getStringList(_seenAnnouncementsKey) ?? [];
    
    for (final id in announcementIds) {
      if (!seenIds.contains(id)) {
        seenIds.add(id);
      }
    }
    
    await prefs.setStringList(_seenAnnouncementsKey, seenIds);
  }

  /// Get list of seen announcement IDs
  static Future<List<String>> getSeenAnnouncementIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_seenAnnouncementsKey) ?? [];
  }

  /// Get count of unseen announcements
  static Stream<int> getUnseenCountStream() {
    return AnnouncementService.getAnnouncementsStream().asyncMap((announcements) async {
      final seenIds = await getSeenAnnouncementIds();
      final unseenCount = announcements.where((announcement) {
        final id = announcement['id'] as String;
        return !seenIds.contains(id);
      }).length;
      return unseenCount;
    });
  }

  /// Clear all seen announcements (for testing)
  static Future<void> clearAllSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenAnnouncementsKey);
  }
}