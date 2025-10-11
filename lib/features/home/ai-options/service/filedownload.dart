import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

class FileDownloadService {
  // Request storage permission with better error handling
  static Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // For Android 13+ (API 33+), we don't need storage permissions for media files
        if (androidInfo.version.sdkInt >= 33) {
          // For Android 13+, we can write to Downloads using MediaStore
          // But for simplicity, we'll use share functionality
          return true;
        } else if (androidInfo.version.sdkInt >= 30) {
          // For Android 11-12, try MANAGE_EXTERNAL_STORAGE first
          var status = await Permission.manageExternalStorage.status;
          if (status != PermissionStatus.granted) {
            status = await Permission.manageExternalStorage.request();
          }
          return status == PermissionStatus.granted;
        } else {
          // For older Android versions, use WRITE_EXTERNAL_STORAGE
          var status = await Permission.storage.status;
          if (status != PermissionStatus.granted) {
            status = await Permission.storage.request();
          }
          return status == PermissionStatus.granted;
        }
      } else if (Platform.isIOS) {
        // iOS doesn't require storage permissions for app documents
        return true;
      }

      return false;
    } catch (e) {
      print('Error requesting storage permission: $e');
      return false;
    }
  }

  // Get the best available download directory
  static Future<Directory?> getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // For newer Android versions, try different approaches
        if (androidInfo.version.sdkInt >= 30) {
          // Try to get external storage directory first
          Directory? externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Create a Downloads folder in the app's external directory
            Directory downloadDir = Directory('${externalDir.path}/Downloads');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            return downloadDir;
          }
        }
        
        // Try the public Downloads directory (requires permission)
        bool hasPermission = await requestStoragePermission();
        if (hasPermission) {
          Directory downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            return downloadsDir;
          }
        }

        // Fallback to external storage directory
        return await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        // For iOS, use documents directory
        return await getApplicationDocumentsDirectory();
      }

      return null;
    } catch (e) {
      print('Error getting download directory: $e');
      // Final fallback to app documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  // Download meal plan as text file with better error handling and path info
  static Future<Map<String, dynamic>> downloadMealPlan(
    String content,
    String planTitle,
  ) async {
    try {
      // Get the download directory
      Directory? directory = await getDownloadDirectory();

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create filename with timestamp
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final sanitizedTitle = planTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final fileName = 'MealPlan_${sanitizedTitle}_$timestamp.txt';

      // Create file
      final file = File('${directory.path}/$fileName');

      // Write content to file
      await file.writeAsString(content, encoding: utf8);

      // Verify file was created and has content
      if (!await file.exists()) {
        throw Exception('File was not created successfully');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File was created but is empty');
      }

      print('File downloaded successfully to: ${file.path}');
      print('File size: $fileSize bytes');
      
      // Check if it's in public Downloads or app directory
      bool isPublicDownload = file.path.contains('/storage/emulated/0/Download');
      
      return {
        'success': true,
        'filePath': file.path,
        'fileName': fileName,
        'fileSize': fileSize,
        'isPublicDownload': isPublicDownload,
        'directory': directory.path,
      };
    } catch (e) {
      print('Error downloading meal plan: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Alternative: Save to app directory and immediately share
  static Future<Map<String, dynamic>> saveAndShareMealPlan(
    String content, 
    String planTitle
  ) async {
    try {
      // Get app's documents directory (always accessible)
      final appDir = await getApplicationDocumentsDirectory();
      
      // Create filename
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      final sanitizedTitle = planTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final fileName = 'MealPlan_${sanitizedTitle}_$timestamp.txt';

      // Create file in app directory
      final file = File('${appDir.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);

      // Verify file creation
      if (!await file.exists()) {
        throw Exception('File was not created successfully');
      }

      // Immediately share the file so user can save it wherever they want
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My AI-generated meal plan',
        subject: 'Meal Plan - $planTitle',
      );

      return {
        'success': true,
        'filePath': file.path,
        'fileName': fileName,
        'shared': true,
        'message': 'File created and share dialog opened',
      };
    } catch (e) {
      print('Error in saveAndShareMealPlan: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Share meal plan file (existing method, but improved)
  static Future<void> shareWorkoutPlan(String content, String planTitle) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();

      // Create filename
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      final sanitizedTitle = planTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final fileName = 'MealPlan_${sanitizedTitle}_$timestamp.txt';

      // Create file in temp directory
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my AI-generated meal plan!',
        subject: 'My Meal Plan - $planTitle',
      );
    } catch (e) {
      print('Error sharing meal plan: $e');
      throw Exception('Failed to share meal plan: ${e.toString()}');
    }
  }

  // Show detailed result dialog
  static Future<void> showDownloadResult(
    BuildContext context, 
    Map<String, dynamic> result
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        if (result['success']) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Download Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File saved successfully!'),
                SizedBox(height: 8),
                Text('File: ${result['fileName']}', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Location: ${result['directory']}', style: TextStyle(fontSize: 12)),
                SizedBox(height: 4),
                Text('Size: ${result['fileSize']} bytes', style: TextStyle(fontSize: 12)),
                if (result['isPublicDownload'] == true) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'File saved to Downloads folder and should be visible in your file manager.',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'File saved to app directory. Use Share button to save to your preferred location.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Download Failed'),
              ],
            ),
            content: Text('Error: ${result['error']}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        }
      },
    );
  }

  // Show permission dialog
  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Storage Permission Required'),
          content: Text(
            'This app needs storage permission to download your meal plans. '
            'Please grant permission to continue, or use the Share option instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}