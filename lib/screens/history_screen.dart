import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_record.dart';
import '../services/history_service.dart';
import '../widgets/diagnosis_report_view.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<ScanRecord> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSeverityFilter = 'all'; // 'all', 'critical', 'moderate', 'healthy'

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await _historyService.loadRecords();
    if (!mounted) return;
    setState(() {
      _records = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(ScanRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scan?'),
        content: Text('Remove diagnosis for "${record.diseaseTitle}" from history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyService.deleteRecord(record.id);
      _loadHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan removed from history')),
      );
    }
  }

  Future<void> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text('This will delete all saved leaf scans and diagnoses from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyService.clearAll();
      _loadHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All scan history cleared')),
      );
    }
  }

  List<ScanRecord> get _filteredRecords {
    return _records.where((record) {
      final matchesSearch = record.diseaseTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          record.diagnosisText.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedSeverityFilter == 'all' ||
          record.severity.toLowerCase() == _selectedSeverityFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'severe':
      case 'critical':
        return Colors.red;
      case 'moderate':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History & Archive'),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              tooltip: 'Clear All History',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by disease name...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),

          // Severity Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Critical', 'severe', color: Colors.red),
                const SizedBox(width: 8),
                _buildFilterChip('Moderate', 'moderate', color: Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip('Healthy', 'healthy', color: Colors.green),
              ],
            ),
          ),

          const Divider(height: 16),

          // Records Feed
          Expanded(
            child: _buildFeedContent(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent(List<ScanRecord> filtered) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final record = filtered[index];
        final color = _getSeverityColor(record.severity);

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openDetail(record),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Image Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey.shade200,
                      child: File(record.imagePath).existsSync()
                          ? Image.file(
                              File(record.imagePath),
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey.shade500,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.diseaseTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                record.severity.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(record.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete Button
                  IconButton(
                    tooltip: 'Delete scan',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.grey.shade600,
                    onPressed: () => _deleteRecord(record),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, {Color? color}) {
    final isSelected = _selectedSeverityFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? Colors.white
            : (color ?? Colors.black87),
      ),
      selectedColor: color ?? Colors.green.shade700,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedSeverityFilter = value);
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Saved Scans Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results match "$_searchQuery". Try a different keyword.'
                  : 'Scanned leaves and diagnoses will be saved here automatically for offline review.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(ScanRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(record.diseaseTitle),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full Image Preview
                  if (File(record.imagePath).existsSync())
                    Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Image.file(
                        File(record.imagePath),
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Offline Clinical Report & Checklist
                  DiagnosisReportView(
                    diagnosisText: record.diagnosisText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
