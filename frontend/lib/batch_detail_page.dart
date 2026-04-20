import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:html' as html;
import 'api_service.dart';

// ============================================================================
// BATCH DETAIL PAGE - Shows student and document status for a batch
// ============================================================================
class BatchDetailPage extends StatefulWidget {
  final String username;
  final int batchId;
  final String batchName;

  const BatchDetailPage({
    super.key,
    required this.username,
    required this.batchId,
    required this.batchName,
  });

  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _batchDetailsFuture;
  late AnimationController _fadeAnimationController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _batchDetailsFuture = _loadBatchDetails();
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadBatchDetails() async {
    final response = await ApiService.getBatchDetails(
      username: widget.username,
      batchId: widget.batchId,
    );
    return response;
  }

  void _refreshBatchDetails() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _batchDetailsFuture = _loadBatchDetails();
    });
    _fadeAnimationController.reset();
    _fadeAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: Text(widget.batchName),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshBatchDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _batchDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: const Color(0xFF0F0F1A),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.indigo.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading batch details...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Container(
              color: const Color(0xFF0F0F1A),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            );
          }

          final response = snapshot.data;
          if (response == null || response['status'] != 'success') {
            return Container(
              color: const Color(0xFF0F0F1A),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    response?['message'] ?? 'Failed to load batch details',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            );
          }

          final batch = response['batch'] as Map<String, dynamic>;
          return FadeTransition(
            opacity: _fadeAnimationController,
            child: _buildBatchDetailsUI(batch),
          );
        },
      ),
    );
  }

  Widget _buildBatchDetailsUI(Map<String, dynamic> batch) {
    final batchName = batch['batch_name'] ?? 'N/A';
    final batchCode = batch['batch_code'] ?? 'N/A';
    final threshold = (batch['similarity_threshold'] ?? 0.8) as num;
    final totalStudents = batch['total_students'] ?? 0;
    final documentsCount = batch['documents_count'] ?? 0;
    final students = List<Map<String, dynamic>>.from(batch['students'] ?? []);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header Gradient Card ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade700, Colors.indigo.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.folder_open,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batchName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code: $batchCode',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('Students', totalStudents.toString()),
                      _buildStatItem('Documents', documentsCount.toString()),
                      _buildStatItem(
                        'Threshold',
                        '${(threshold.toDouble() * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ---- Batch Information Card ----
            const Text(
              'Batch Information',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E3F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade800, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDarkInfoRow('Batch Name', batchName),
                  const SizedBox(height: 12),
                  _buildDarkInfoRow('Batch Code', batchCode),
                  const SizedBox(height: 12),
                  _buildDarkInfoRow(
                    'Similarity Threshold',
                    '${(threshold.toDouble() * 100).toStringAsFixed(1)}%',
                  ),
                  const SizedBox(height: 12),
                  _buildDarkInfoRow('Total Students', totalStudents.toString()),
                  const SizedBox(height: 12),
                  _buildDarkInfoRow(
                    'Documents Uploaded',
                    documentsCount.toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ---- Student & Document Status Table ----
            const Text(
              'Student & Document Status',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            if (students.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No students have joined this batch yet.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade800, width: 1),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 12,
                    dataRowColor: MaterialStateProperty.resolveWith(
                      (states) => const Color(0xFF161629),
                    ),
                    headingRowColor: MaterialStateProperty.all(
                      Colors.indigo.shade900.withOpacity(0.3),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Student',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Document',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Similarity',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    rows: [
                      for (final student in students)
                        _buildStudentRow(student, threshold.toDouble()),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // ---- Detailed Student Information ----
            const Text(
              'Detailed Student Information',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            if (students.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No students to display.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return _buildStudentCard(student, threshold.toDouble());
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDarkInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildStudentRow(Map<String, dynamic> student, double threshold) {
    final username = student['username'] ?? 'N/A';
    final isDocUploaded = student['document_uploaded'] ?? false;
    final docDetails =
        (student['document_details'] ?? {}) as Map<String, dynamic>;
    final fileName = docDetails['file_name'] ?? 'Not uploaded yet';
    final status = docDetails['status'] ?? 'pending';
    final similarity = docDetails['similarity_score'];
    final documentId = docDetails['document_id'] as int?;

    String statusDisplay;
    Color statusColor;

    if (!isDocUploaded || status == 'pending') {
      statusDisplay = 'Not Uploaded';
      statusColor = Colors.orange;
    } else if (status == 'accepted') {
      statusDisplay = 'Accepted';
      statusColor = Colors.green;
    } else if (status == 'rejected') {
      statusDisplay = 'Rejected';
      statusColor = Colors.red;
    } else {
      statusDisplay = status;
      statusColor = Colors.grey;
    }

    String similarityDisplay = 'N/A';
    if (similarity != null && isDocUploaded) {
      similarityDisplay =
          '${(similarity as num).toStringAsFixed(2)} '
          '(${((similarity as num).toDouble() * 100).toStringAsFixed(1)}%)';
    }

    return DataRow(
      cells: [
        DataCell(Text(username, style: const TextStyle(color: Colors.white))),
        DataCell(
          isDocUploaded && documentId != null
              ? GestureDetector(
                  onTap: () => _downloadDocument(documentId, fileName),
                  child: Text(
                    fileName.length > 20
                        ? '${fileName.substring(0, 17)}...'
                        : fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blue[400],
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Text(
                  fileName.length > 20
                      ? '${fileName.substring(0, 17)}...'
                      : fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              statusDisplay,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(similarityDisplay, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, double threshold) {
    final username = student['username'] ?? 'N/A';
    final joinedAt = student['joined_at'] ?? '';
    final isDocUploaded = student['document_uploaded'] ?? false;
    final docDetails =
        (student['document_details'] ?? {}) as Map<String, dynamic>;

    final fileName = docDetails['file_name'] ?? 'Not uploaded yet';
    final uploadedAt = docDetails['uploaded_at'];
    final status = docDetails['status'] ?? 'pending';
    final similarity = docDetails['similarity_score'];

    String statusDisplay;
    Color statusColor;
    IconData statusIcon;

    if (!isDocUploaded || status == 'pending') {
      statusDisplay = 'Not Uploaded';
      statusColor = Colors.orange;
      statusIcon = Icons.pending_actions;
    } else if (status == 'accepted') {
      statusDisplay = 'Accepted';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusDisplay = 'Rejected';
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else {
      statusDisplay = status;
      statusColor = Colors.grey;
      statusIcon = Icons.help;
    }

    String joinedDate = 'N/A';
    try {
      if (joinedAt.isNotEmpty) {
        final dt = DateTime.parse(joinedAt);
        joinedDate =
            '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Keep default
    }

    String uploadedDate = 'Not uploaded';
    try {
      if (uploadedAt != null && (uploadedAt as String).isNotEmpty) {
        final dt = DateTime.parse(uploadedAt as String);
        uploadedDate =
            '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Keep default
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade800, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Name & Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Joined: $joinedDate',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(statusIcon, size: 18, color: statusColor),
                  label: Text(statusDisplay),
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide(color: statusColor),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white24),
            // Document Details
            Text(
              'Document Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (isDocUploaded && docDetails['document_id'] != null)
              Row(
                children: [
                  Expanded(
                    child: _buildDarkDetailRow('Document Name', fileName),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _downloadDocument(
                      docDetails['document_id'] as int,
                      fileName,
                    ),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.indigo.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            else
              _buildDarkDetailRow('Document Name', fileName),
            const SizedBox(height: 8),
            _buildDarkDetailRow('Upload Time', uploadedDate),
            if (isDocUploaded && similarity != null) ...[
              const SizedBox(height: 8),
              _buildDarkDetailRow(
                'Similarity Score',
                '${(similarity as num).toStringAsFixed(4)} (${((similarity as num).toDouble() * 100).toStringAsFixed(2)}%)',
              ),
              const SizedBox(height: 8),
              _buildDarkDetailRow(
                'Threshold',
                '${(threshold * 100).toStringAsFixed(1)}%',
              ),
              if (similarity is num) ...[
                const SizedBox(height: 8),
                _buildDarkDetailRow(
                  'Decision',
                  status == 'accepted'
                      ? 'Accepted (Below Threshold)'
                      : 'Rejected (Exceeds Threshold)',
                  valueColor: status == 'accepted' ? Colors.green : Colors.red,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDarkDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadDocument(int documentId, String fileName) async {
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E3F),
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade700),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Downloading document...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final fileBytes = await ApiService.downloadDocument(
        documentId: documentId,
        username: widget.username,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (fileBytes == null || fileBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download document'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // On web, trigger download
      if (kIsWeb) {
        _downloadFileWeb(fileBytes, fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "$fileName" downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // On mobile, show options to save
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "$fileName" downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadFileWeb(Uint8List bytes, String fileName) {
    // For web platform, create a blob and download
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
