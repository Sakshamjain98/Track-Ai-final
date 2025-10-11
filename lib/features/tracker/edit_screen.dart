import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/edit_log_entry.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class EditLogsScreen extends StatefulWidget {
  final String trackerId;
  final String trackerTitle;
  final Color trackerColor;
  final IconData trackerIcon;

  const EditLogsScreen({
    Key? key,
    required this.trackerId,
    required this.trackerTitle,
    required this.trackerColor,
    required this.trackerIcon,
  }) : super(key: key);

  @override
  State<EditLogsScreen> createState() => _EditLogsScreenState();
}

class _EditLogsScreenState extends State<EditLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _sortOrder = 'newest';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await TrackerService.getTrackerEntries(widget.trackerId);
      setState(() {
        _logs = logs as List<Map<String, dynamic>>;
        _sortLogs();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading logs: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _sortLogs() {
    _logs.sort((a, b) {
      final dateA = DateTime.parse(a['timestamp']);
      final dateB = DateTime.parse(b['timestamp']);
      
      if (_sortOrder == 'newest') {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateB);
      }
    });
  }

  List<Map<String, dynamic>> get filteredLogs {
    if (_searchQuery.isEmpty) return _logs;
    
    return _logs.where((log) {
      final searchLower = _searchQuery.toLowerCase();
      
      // Search in main fields
      if (log['value']?.toString().contains(searchLower) == true) return true;
      
      // Search in specific fields based on tracker type
      switch (widget.trackerId) {
        case 'sleep':
          return log['dreamNotes']?.toString().toLowerCase().contains(searchLower) == true ||
                 log['interruptions']?.toString().toLowerCase().contains(searchLower) == true;
        case 'mood':
          return log['emotions']?.toString().toLowerCase().contains(searchLower) == true ||
                 log['context']?.toString().toLowerCase().contains(searchLower) == true;
        case 'meditation':
          return log['type']?.toString().toLowerCase().contains(searchLower) == true ||
                 log['afterEffect']?.toString().toLowerCase().contains(searchLower) == true;
        case 'expense':
          return log['category']?.toString().toLowerCase().contains(searchLower) == true ||
                 log['paymentMethod']?.toString().toLowerCase().contains(searchLower) == true;
        case 'savings':
          return log['source']?.toString().toLowerCase().contains(searchLower) == true ||
                 log['towardsGoal']?.toString().toLowerCase().contains(searchLower) == true;
        case 'alcohol':
          return log['drinkType']?.toString().toLowerCase().contains(searchLower) == true ||
                 log['occasion']?.toString().toLowerCase().contains(searchLower) == true;
        case 'study':
          return log['subjectTopic']?.toString().toLowerCase().contains(searchLower) == true ||
                 log['location']?.toString().toLowerCase().contains(searchLower) == true;
        case 'menstrual':
          return log['lastPeriodDate']?.toString().toLowerCase().contains(searchLower) == true;
        default:
          return false;
      }
    }).toList();
  }

  Future<void> _deleteLog(String logId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final isDark = themeProvider.isDarkMode;
          return AlertDialog(
            backgroundColor: AppColors.cardBackground(isDark),
            title: Text(
              'Delete Entry',
              style: TextStyle(color: AppColors.textPrimary(isDark)),
            ),
            content: Text(
              'Are you sure you want to delete this entry? This action cannot be undone.',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary(isDark)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.errorColor),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      try {
        await TrackerService.deleteTrackerEntry(widget.trackerId, logId);
        await _loadLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Entry deleted successfully'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting entry: $e'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  String _formatDate(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[date.weekday - 1]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildLogCard(Map<String, dynamic> log, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Color.fromRGBO(40, 50, 49, 0.85),
                  const Color.fromARGB(215, 14, 14, 14),
                  Color.fromRGBO(33, 43, 42, 0.85),
                ]
              : [
                  AppColors.lightSecondary.withOpacity(0.85),
                  AppColors.lightSecondary.withOpacity(0.85),
                  AppColors.lightSecondary.withOpacity(0.85),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.trackerColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.trackerColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _editLog(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.trackerColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.trackerIcon,
                      color: widget.trackerColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLogTitle(log),
                          style: TextStyle(
                            color: AppColors.textPrimary(isDark),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(log['timestamp']),
                          style: TextStyle(
                            color: AppColors.textSecondary(isDark),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary(isDark),
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editLog(log);
                      } else if (value == 'delete') {
                        _deleteLog(log['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: AppColors.textPrimary(isDark), size: 18),
                            const SizedBox(width: 8),
                            Text('Edit', style: TextStyle(color: AppColors.textPrimary(isDark))),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppColors.errorColor, size: 18),
                            const SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.errorColor)),
                          ],
                        ),
                      ),
                    ],
                    color: AppColors.cardBackground(isDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLogDetails(log, isDark),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editLog(log),
                      icon: Icon(
                        Icons.edit,
                        color: widget.trackerColor,
                        size: 16,
                      ),
                      label: Text(
                        'Edit Entry',
                        style: TextStyle(
                          color: widget.trackerColor,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: widget.trackerColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _deleteLog(log['id']),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      side: BorderSide(color: AppColors.errorColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Icon(
                      Icons.delete,
                      color: AppColors.errorColor,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLogTitle(Map<String, dynamic> log) {
    switch (widget.trackerId) {
      case 'sleep':
        return '${log['value']} hours • Quality: ${log['quality']}/10';
      case 'mood':
        return 'Mood: ${log['value']}/10 • ${log['emotions'] ?? 'No emotions noted'}';
      case 'meditation':
        return '${log['value']} min • ${log['type'] ?? 'Meditation'}';
      case 'expense':
        return '${log['value']} • ${log['category'] ?? 'Uncategorized'}';
      case 'savings':
        return '${log['value']} • ${log['source'] ?? 'Unknown source'}';
      case 'alcohol':
        return '${log['value']} drinks • ${log['drinkType'] ?? 'Unknown type'}';
      case 'study':
        return '${log['value']} hours • ${log['subjectTopic'] ?? 'Study session'}';
      case 'menstrual':
        return 'Cycle: ${log['typicalCycleLength']} days • Period: ${log['periodLength']} days';
      default:
        return 'Value: ${log['value']}';
    }
  }

  Widget _buildLogDetails(Map<String, dynamic> log, bool isDark) {
    List<Widget> details = [];

    switch (widget.trackerId) {
      case 'sleep':
        if (log['dreamNotes']?.isNotEmpty == true) {
          details.add(_buildDetailRow('Dreams', log['dreamNotes'], isDark));
        }
        if (log['interruptions']?.isNotEmpty == true) {
          details.add(_buildDetailRow('Interruptions', log['interruptions'], isDark));
        }
        break;
      case 'mood':
        if (log['context']?.isNotEmpty == true) {
          details.add(_buildDetailRow('Context', log['context'], isDark));
        }
        if (log['peakMoodTime']?.isNotEmpty == true) {
          details.add(_buildDetailRow('Peak Time', log['peakMoodTime'], isDark));
        }
        break;
      case 'meditation':
        if (log['difficulty'] != null) {
          details.add(_buildDetailRow('Difficulty', '${log['difficulty']}/5', isDark));
        }
        if (log['afterEffect']?.isNotEmpty == true) {
          details.add(_buildDetailRow('After Effect', log['afterEffect'], isDark));
        }
        break;
      case 'expense':
        if (log['paymentMethod']?.isNotEmpty == true) {
          details.add(_buildDetailRow('Payment', log['paymentMethod'], isDark));
        }
        if (log['necessity']?.isNotEmpty == true) {
          details.add(_buildDetailRow('Necessity', log['necessity'], isDark));
        }
        break;
      case 'savings':
        if (log['towardsGoal']?.isNotEmpty == true) {
          details.add(_buildDetailRow('Goal', log['towardsGoal'], isDark));
        }
        if (log['recurring'] == true) {
          details.add(_buildDetailRow('Type', 'Recurring', isDark));
        }
        break;
      case 'alcohol':
        if (log['occasion']?.isNotEmpty == true) {
          details.add(_buildDetailRow('Occasion', log['occasion'], isDark));
        }
        if (log['craving'] != null) {
          details.add(_buildDetailRow('Craving', '${log['craving']}/5', isDark));
        }
        break;
      case 'study':
        if (log['location']?.isNotEmpty == true) {
          details.add(_buildDetailRow('Location', log['location'], isDark));
        }
        if (log['focusLevel'] != null) {
          details.add(_buildDetailRow('Focus', '${log['focusLevel']}/10', isDark));
        }
        break;
      case 'menstrual':
        if (log['lastPeriodDate']?.isNotEmpty == true) {
          final date = DateTime.parse(log['lastPeriodDate']);
          details.add(_buildDetailRow('Last Period', '${date.day}/${date.month}/${date.year}', isDark));
        }
        break;
    }

    // Add custom data
    if (log['customData'] != null && log['customData'].isNotEmpty) {
      final customData = log['customData'] as Map<String, dynamic>;
      customData.forEach((key, value) {
        if (value.toString().isNotEmpty) {
          details.add(_buildDetailRow(key, value.toString(), isDark));
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.isEmpty 
          ? [Text(
              'No additional details',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )]
          : details,
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editLog(Map<String, dynamic> log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLogEntryScreen(
          trackerId: widget.trackerId,
          trackerTitle: widget.trackerTitle,
          trackerColor: widget.trackerColor,
          trackerIcon: widget.trackerIcon,
          logData: log,
          onLogUpdated: () => _loadLogs(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final displayedLogs = filteredLogs;
        
        return Scaffold(
          backgroundColor: AppColors.background(isDark),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDark)),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit ${widget.trackerTitle}',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${displayedLogs.length} entries',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.sort, color: AppColors.textPrimary(isDark)),
                onSelected: (value) {
                  setState(() {
                    _sortOrder = value;
                    _sortLogs();
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'newest',
                    child: Row(
                      children: [
                        Icon(
                          _sortOrder == 'newest' ? Icons.check : Icons.schedule,
                          color: AppColors.textPrimary(isDark),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text('Newest First', style: TextStyle(color: AppColors.textPrimary(isDark))),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'oldest',
                    child: Row(
                      children: [
                        Icon(
                          _sortOrder == 'oldest' ? Icons.check : Icons.history,
                          color: AppColors.textPrimary(isDark),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text('Oldest First', style: TextStyle(color: AppColors.textPrimary(isDark))),
                      ],
                    ),
                  ),
                ],
                color: AppColors.cardBackground(isDark),
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundLinearGradient(isDark),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundLinearGradient(isDark),
            ),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search entries...',
                      hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary(isDark)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: Icon(Icons.clear, color: AppColors.textSecondary(isDark)),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.cardBackground(isDark),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary(isDark).withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary(isDark).withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary(isDark), width: 2),
                      ),
                    ),
                    style: TextStyle(color: AppColors.textPrimary(isDark)),
                  ),
                ),

                // Logs List
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(widget.trackerColor),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading entries...',
                                style: TextStyle(
                                  color: AppColors.textSecondary(isDark),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : displayedLogs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
                                    size: 64,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty 
                                        ? 'No entries found'
                                        : 'No entries yet',
                                    style: TextStyle(
                                      color: AppColors.textSecondary(isDark),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Try adjusting your search query'
                                        : 'Start logging data to see entries here',
                                    style: TextStyle(
                                      color: AppColors.textSecondary(isDark),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: widget.trackerColor,
                              onRefresh: _loadLogs,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: displayedLogs.length,
                                itemBuilder: (context, index) {
                                  final log = displayedLogs[index];
                                  return _buildLogCard(log, isDark);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }}