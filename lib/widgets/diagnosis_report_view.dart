import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

enum DiseaseSeverity {
  healthy('Healthy Plant', Colors.green, Icons.check_circle_outline),
  moderate('Moderate Attention', Colors.orange, Icons.warning_amber_rounded),
  severe('Critical / High Alert', Colors.red, Icons.error_outline_rounded);

  final String label;
  final MaterialColor color;
  final IconData icon;

  const DiseaseSeverity(this.label, this.color, this.icon);
}

class DiagnosisReportView extends StatefulWidget {
  final String diagnosisText;
  final VoidCallback? onScanAgain;
  final double tabContentHeight;

  const DiagnosisReportView({
    super.key,
    required this.diagnosisText,
    this.onScanAgain,
    this.tabContentHeight = 400,
  });

  @override
  State<DiagnosisReportView> createState() => _DiagnosisReportViewState();
}

class _DiagnosisReportViewState extends State<DiagnosisReportView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DiseaseSeverity _severity;
  late String _diseaseTitle;
  late List<String> _checklistItems;
  final Map<int, bool> _completedItems = {};
  final ScrollController _reportScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _severity = _determineSeverity(widget.diagnosisText);
    _diseaseTitle = _extractDiseaseTitle(widget.diagnosisText);
    _checklistItems = _extractChecklistItems(widget.diagnosisText);
  }

  @override
  void didUpdateWidget(covariant DiagnosisReportView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diagnosisText != widget.diagnosisText) {
      setState(() {
        _severity = _determineSeverity(widget.diagnosisText);
        _diseaseTitle = _extractDiseaseTitle(widget.diagnosisText);
        _checklistItems = _extractChecklistItems(widget.diagnosisText);
        _completedItems.clear();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reportScrollController.dispose();
    super.dispose();
  }

  String _extractDiseaseTitle(String text) {
    final lines = text.split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trim();
      final lower = line.toLowerCase();

      if (lower.contains('disease') ||
          lower.contains('condition') ||
          lower.contains('diagnosis:')) {
        final clean = line
            .replaceAll(RegExp(r'^[#\-*•\s]+'), '')
            .replaceAll('**', '')
            .replaceFirst(
              RegExp(
                r'^(Disease|Condition|Primary Diagnosis|Diagnosis)(\s*\/\s*Condition)?:\s*',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
        if (clean.isNotEmpty && clean.length > 3) {
          return clean;
        }
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.startsWith('#')) {
        final clean = line
            .replaceFirst(RegExp(r'^#+\s*'), '')
            .replaceAll('**', '')
            .trim();
        if (clean.isNotEmpty &&
            !clean.toLowerCase().contains('report') &&
            !clean.toLowerCase().contains('clinical')) {
          return clean;
        }
      }
    }

    return _severity.label;
  }

  DiseaseSeverity _determineSeverity(String text) {
    final lower = text.toLowerCase();
    final topSection = lower.length > 500 ? lower.substring(0, 500) : lower;

    final isSevere = topSection.contains('late blight') ||
        topSection.contains('yellow leaf curl') ||
        topSection.contains('bacterial wilt') ||
        topSection.contains('canker') ||
        topSection.contains('severe') ||
        topSection.contains('critical');

    if (isSevere) return DiseaseSeverity.severe;

    final hasDisease = topSection.contains('blight') ||
        topSection.contains('spot') ||
        topSection.contains('speck') ||
        topSection.contains('mold') ||
        topSection.contains('mildew') ||
        topSection.contains('virus') ||
        topSection.contains('wilt') ||
        topSection.contains('rot') ||
        topSection.contains('mosaic') ||
        topSection.contains('chlorosis') ||
        topSection.contains('deficiency') ||
        topSection.contains('mite') ||
        topSection.contains('anthracnose') ||
        topSection.contains('septoria') ||
        topSection.contains('fung');

    if (hasDisease) return DiseaseSeverity.moderate;

    if (topSection.contains('healthy') &&
        !topSection.contains('not healthy') &&
        !topSection.contains('unhealthy')) {
      return DiseaseSeverity.healthy;
    }

    return DiseaseSeverity.moderate;
  }

  List<String> _extractChecklistItems(String text) {
    final lines = text.split('\n');
    final items = <String>[];
    bool inActionSection = false;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      final lower = line.toLowerCase();

      // Detect relevant sections
      if (lower.contains('treatment') ||
          lower.contains('management') ||
          lower.contains('action') ||
          lower.contains('prevention') ||
          lower.contains('control')) {
        inActionSection = true;
      }

      // Check if bullet point or numbered item
      final isBullet = line.startsWith('- ') ||
          line.startsWith('* ') ||
          line.startsWith('• ') ||
          RegExp(r'^\d+\.\s').hasMatch(line);

      if (isBullet && inActionSection) {
        String cleanText = line
            .replaceFirst(RegExp(r'^[-*•]\s+'), '')
            .replaceFirst(RegExp(r'^\d+\.\s+'), '')
            .trim();

        // Clean leading bold markdown markers like **Pruning:**
        cleanText = cleanText.replaceAll('**', '').trim();

        if (cleanText.isNotEmpty && cleanText.length > 5) {
          items.add(cleanText);
        }
      }
    }

    // Fallback: if section-based extraction was too sparse, pick any bullet points
    if (items.isEmpty) {
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.startsWith('- ') || line.startsWith('* ')) {
          final clean = line.substring(2).replaceAll('**', '').trim();
          if (clean.length > 5) items.add(clean);
        }
      }
    }

    return items;
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.diagnosisText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Prescription copied to clipboard!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount =
        _completedItems.values.where((checked) => checked).length;
    final totalCount = _checklistItems.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Prescription Banner
          _buildHeaderBanner(theme),

          // Tab Bar (Report vs Action Checklist)
          Container(
            color: Colors.grey.shade50,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.grey.shade700,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              tabs: [
                const Tab(
                  icon: Icon(Icons.description_outlined, size: 20),
                  text: 'Clinical Report',
                ),
                Tab(
                  icon: Badge(
                    label: Text('${_checklistItems.length}'),
                    isLabelVisible: _checklistItems.isNotEmpty,
                    child: const Icon(Icons.checklist_rtl_rounded, size: 20),
                  ),
                  text: 'Action Checklist',
                ),
              ],
            ),
          ),

          // Tab Content
          SizedBox(
            height: widget.tabContentHeight,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Formatted Markdown Report
                _buildMarkdownReport(theme),

                // Tab 2: Interactive Checklist
                _buildChecklistTab(theme, completedCount, totalCount, progress),
              ],
            ),
          ),

          // Bottom Action Footer
          _buildFooterActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _severity.color.shade50,
        border: Border(
          bottom: BorderSide(color: _severity.color.shade200, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _severity.color.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(_severity.icon, color: _severity.color.shade800, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _diseaseTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: _severity.color.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _severity.color.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _severity.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.bold,
                          color: _severity.color.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy Report',
            icon: const Icon(Icons.copy_rounded, size: 20),
            color: _severity.color.shade800,
            onPressed: _copyToClipboard,
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownReport(ThemeData theme) {
    return Scrollbar(
      controller: _reportScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _reportScrollController,
        padding: const EdgeInsets.all(18),
        child: MarkdownBody(
          data: widget.diagnosisText,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            h1: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
              height: 1.4,
            ),
            h2: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
              height: 1.3,
            ),
            h3: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade900,
              height: 1.3,
            ),
            p: const TextStyle(
              fontSize: 14.5,
              height: 1.55,
              color: Colors.black87,
            ),
            listBullet: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            blockSpacing: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistTab(
    ThemeData theme,
    int completedCount,
    int totalCount,
    double progress,
  ) {
    if (_checklistItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No specific action steps detected.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Please refer to the Clinical Report tab for detailed instructions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Progress Meter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.green.shade50.withValues(alpha: 0.6),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Treatment Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green.shade900,
                    ),
                  ),
                  Text(
                    '$completedCount of $totalCount completed (${(progress * 100).toInt()}%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.green.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                ),
              ),
            ],
          ),
        ),

        // Interactive List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _checklistItems.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final isChecked = _completedItems[index] ?? false;
              final task = _checklistItems[index];

              return CheckboxListTile(
                value: isChecked,
                activeColor: Colors.green.shade700,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  task,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    color: isChecked ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _completedItems[index] = val ?? false;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy Prescription'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade800,
                side: BorderSide(color: Colors.green.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (widget.onScanAgain != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onScanAgain,
                icon: const Icon(Icons.document_scanner_outlined, size: 18),
                label: const Text('New Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
