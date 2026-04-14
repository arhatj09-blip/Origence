import 'package:flutter/material.dart';
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

class _BatchDetailPageState extends State<BatchDetailPage> {
  late Future<Map<String, dynamic>> _batchDetailsFuture;

  @override
  void initState() {
    super.initState();
    _batchDetailsFuture = _loadBatchDetails();
  }

  Future<Map<String, dynamic>> _loadBatchDetails() async {
    final response = await ApiService.getBatchDetails(
      username: widget.username,
      batchId: widget.batchId,
    );
    return response;
  }

  void _refreshBatchDetails() {
    setState(() {
      _batchDetailsFuture = _loadBatchDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batchName),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBatchDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _batchDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          final response = snapshot.data;
          if (response == null || response['status'] != 'success') {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  response?['message'] ?? 'Failed to load batch details',
                ),
              ),
            );
          }

          final batch = response['batch'] as Map<String, dynamic>;
          return _buildBatchDetailsUI(batch);
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Batch Name', batchName),
                    const SizedBox(height: 8),
                    _buildInfoRow('Batch Code', batchCode),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Similarity Threshold',
                      '${(threshold.toDouble() * 100).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Total Students', totalStudents.toString()),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Documents Uploaded',
                      documentsCount.toString(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Student & Document Status Table
            Text(
              'Student & Document Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[600],
              ),
            ),
            const SizedBox(height: 12),

            if (students.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No students have joined this batch yet.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12,
                  columns: const [
                    DataColumn(label: Text('Student')),
                    DataColumn(label: Text('Document')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Similarity')),
                  ],
                  rows: [
                    for (final student in students)
                      _buildStudentRow(student, threshold.toDouble()),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Student Details Section
            Text(
              'Detailed Student Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[600],
              ),
            ),
            const SizedBox(height: 12),

            if (students.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No students to display.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
        DataCell(Text(username)),
        DataCell(
          Text(
            fileName.length > 20 ? '${fileName.substring(0, 17)}...' : fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        DataCell(Text(similarityDisplay)),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Joined: $joinedDate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
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
                ),
              ],
            ),
            const Divider(height: 24),
            // Document Details
            Text(
              'Document Information',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Document Name', fileName),
            const SizedBox(height: 8),
            _buildDetailRow('Upload Time', uploadedDate),
            if (isDocUploaded && similarity != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Similarity Score',
                '${(similarity as num).toStringAsFixed(4)} (${((similarity as num).toDouble() * 100).toStringAsFixed(2)}%)',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Threshold',
                '${(threshold * 100).toStringAsFixed(1)}%',
              ),
              if (similarity is num) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
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
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
