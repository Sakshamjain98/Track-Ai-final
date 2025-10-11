import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's ID
  static String? get _currentUserId => _auth.currentUser?.uid;

  // Helper method to convert Firestore data safely
  static Map<String, dynamic> _convertFirestoreData(Map<String, dynamic> data) {
    final convertedData = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (value is Timestamp) {
        // Convert Timestamp to ISO string
        convertedData[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        // Recursively handle nested maps
        convertedData[key] = _convertFirestoreData(value);
      } else {
        convertedData[key] = value;
      }
    });
    
    return convertedData;
  }

  /// Get all entries for a specific tracker type
  static Future<List<Map<String, dynamic>>> getTrackerEntries(String trackerId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .doc(trackerId)
          .collection('entries')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Convert any Timestamp objects to strings
        final convertedData = _convertFirestoreData(data);
        convertedData['id'] = doc.id;
        return convertedData;
      }).toList();
    } catch (e) {
      throw Exception('Failed to load tracker entries: $e');
    }
  }

  /// Update an existing tracker entry
  static Future<void> updateTrackerEntry(
    String trackerId, 
    String entryId, 
    Map<String, dynamic> updatedData
  ) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      updatedData['lastModified'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .doc(trackerId)
          .collection('entries')
          .doc(entryId)
          .update(updatedData);
    } catch (e) {
      throw Exception('Failed to update tracker entry: $e');
    }
  }

  /// Delete a tracker entry
  static Future<void> deleteTrackerEntry(String trackerId, String entryId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .doc(trackerId)
          .collection('entries')
          .doc(entryId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete tracker entry: $e');
    }
  }

  /// Get a specific tracker entry by ID
  static Future<Map<String, dynamic>?> getTrackerEntryById(String trackerId, String entryId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .doc(trackerId)
          .collection('entries')
          .doc(entryId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        // Convert any Timestamp objects to strings
        final convertedData = _convertFirestoreData(data);
        convertedData['id'] = docSnapshot.id;
        return convertedData;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get tracker entry: $e');
    }
  }

  /// Get entries for a specific tracker type within a date range
  static Future<List<Map<String, dynamic>>> getTrackerEntriesInDateRange(
    String trackerId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      // Use Timestamps for Firestore queries for better performance and accuracy
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .doc(trackerId)
          .collection('entries')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Convert any Timestamp objects to strings
        final convertedData = _convertFirestoreData(data);
        convertedData['id'] = doc.id;
        return convertedData;
      }).toList();
    } catch (e) {
      throw Exception('Failed to load tracker entries in date range: $e');
    }
  }

  /// Get statistics for a specific tracker
  static Future<Map<String, dynamic>> getTrackerStatistics(String trackerId) async {
    try {
      final entries = await getTrackerEntries(trackerId);
      
      if (entries.isEmpty) {
        return {
          'totalEntries': 0,
          'averageValue': 0.0,
          'firstEntry': null,
          'lastEntry': null,
        };
      }

      // Calculate statistics based on numeric values
      final numericValues = entries
          .where((entry) => entry['value'] != null)
          .map((entry) => double.tryParse(entry['value'].toString()) ?? 0.0)
          .where((value) => value > 0)
          .toList();

      final averageValue = numericValues.isNotEmpty 
          ? numericValues.reduce((a, b) => a + b) / numericValues.length 
          : 0.0;

      return {
        'totalEntries': entries.length,
        'averageValue': averageValue,
        'maxValue': numericValues.isNotEmpty ? numericValues.reduce((a, b) => a > b ? a : b) : 0.0,
        'minValue': numericValues.isNotEmpty ? numericValues.reduce((a, b) => a < b ? a : b) : 0.0,
        'firstEntry': entries.last['timestamp'],
        'lastEntry': entries.first['timestamp'],
      };
    } catch (e) {
      throw Exception('Failed to calculate tracker statistics: $e');
    }
  }

  /// Bulk delete entries for a tracker
  static Future<void> bulkDeleteTrackerEntries(String trackerId, List<String> entryIds) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final batch = _firestore.batch();
      
      for (String entryId in entryIds) {
        final docRef = _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('tracking')
            .doc(trackerId)
            .collection('entries')
            .doc(entryId);
        batch.delete(docRef);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk delete tracker entries: $e');
    }
  }

  /// Search entries by custom data or specific fields
  static Future<List<Map<String, dynamic>>> searchTrackerEntries(
    String trackerId, 
    String searchQuery
  ) async {
    try {
      final allEntries = await getTrackerEntries(trackerId);
      
      if (searchQuery.isEmpty) return allEntries;
      
      final searchLower = searchQuery.toLowerCase();
      
      return allEntries.where((entry) {
        // Search in main value
        if (entry['value']?.toString().toLowerCase().contains(searchLower) == true) {
          return true;
        }
        
        // Search in custom data
        final customData = entry['customData'] as Map<String, dynamic>?;
        if (customData != null) {
          for (final value in customData.values) {
            if (value?.toString().toLowerCase().contains(searchLower) == true) {
              return true;
            }
          }
        }
        
        // Search in tracker-specific fields
        final fieldsToSearch = [
          'emotions', 'context', 'peakMoodTime', // mood
          'type', 'afterEffect', // meditation
          'dreamNotes', 'interruptions', // sleep
          'category', 'paymentMethod', 'necessity', // expense
          'source', 'towardsGoal', // savings
          'drinkType', 'occasion', // alcohol
          'subjectTopic', 'location', // study
        ];
        
        for (final field in fieldsToSearch) {
          if (entry[field]?.toString().toLowerCase().contains(searchLower) == true) {
            return true;
          }
        }
        
        return false;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search tracker entries: $e');
    }
  }

  /// Save a new tracker entry
  static Future<String> saveTrackerEntry(String trackerId, Map<String, dynamic> entryData) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      // Use Firestore server timestamp for consistency
      entryData['timestamp'] = entryData['timestamp'] != null 
          ? (entryData['timestamp'] is String 
              ? Timestamp.fromDate(DateTime.parse(entryData['timestamp']))
              : entryData['timestamp'])
          : FieldValue.serverTimestamp();
      
      entryData['trackerType'] = trackerId;
      entryData['userId'] = _currentUserId;
      entryData['createdAt'] = FieldValue.serverTimestamp();
      entryData['lastModified'] = FieldValue.serverTimestamp();
      
      // Add the entry to Firestore and get the document reference
      final docRef = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .doc(trackerId)
          .collection('entries')
          .add(entryData);
      
      // Return the generated document ID
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save tracker entry: $e');
    }
  }

  /// Check if user is authenticated
  static bool get isUserAuthenticated => _currentUserId != null;

  /// Get current user ID (for debugging purposes)
  static String? getCurrentUserId() => _currentUserId;

  /// Initialize tracker document if it doesn't exist
  static Future<void> initializeTrackerIfNeeded(String trackerId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final trackerDoc = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .doc(trackerId);

      final docSnapshot = await trackerDoc.get();
      
      if (!docSnapshot.exists) {
        await trackerDoc.set({
          'trackerId': trackerId,
          'createdAt': FieldValue.serverTimestamp(),
          'totalEntries': 0,
        });
      }
    } catch (e) {
      throw Exception('Failed to initialize tracker: $e');
    }
  }

  /// Get all tracker types for current user
  static Future<List<String>> getUserTrackerTypes() async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .get();

      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get user tracker types: $e');
    }
  }

  /// Get entries with proper timestamp conversion (alternative method)
  static Future<List<Map<String, dynamic>>> getTrackerEntriesWithSafeTimestamps(String trackerId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .doc(trackerId)
          .collection('entries')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final safeData = <String, dynamic>{};
        
        // Handle each field carefully
        data.forEach((key, value) {
          if (value is Timestamp) {
            safeData[key] = value.toDate().toIso8601String();
          } else if (key == 'timestamp' && value == null) {
            // Handle null timestamps (shouldn't happen but just in case)
            safeData[key] = DateTime.now().toIso8601String();
          } else if (value is Map<String, dynamic>) {
            // Handle nested objects (like customData)
            safeData[key] = _convertFirestoreData(value);
          } else {
            safeData[key] = value;
          }
        });
        
        safeData['id'] = doc.id;
        return safeData;
      }).toList();
    } catch (e) {
      throw Exception('Failed to load tracker entries: $e');
    }
  }
}