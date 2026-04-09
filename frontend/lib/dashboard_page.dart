import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'main.dart';
import 'package:file_selector/file_selector.dart';

// ============================================================================
// FACULTY DASHBOARD
// ============================================================================
class FacultyDashboardPage extends StatefulWidget {
  final String username;
  const FacultyDashboardPage({super.key, required this.username});

  @override
  State<FacultyDashboardPage> createState() => _FacultyDashboardPageState();
}

class _FacultyDashboardPageState extends State<FacultyDashboardPage> {
  bool _isLoggingOut = false;
  List<Map<String, dynamic>> _batches = [];
  bool _loadingBatches = false;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _loadingBatches = true);
    final resp = await ApiService.getBatches(username: widget.username);
    if (mounted) {
      setState(() {
        _loadingBatches = false;
        if (resp['status'] == 'success') {
          _batches = List<Map<String, dynamic>>.from(resp['batches'] ?? []);
        }
      });
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showCreateBatchDialog() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final thresholdCtrl = TextEditingController(text: '0.80');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Batch'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Batch Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Batch Code (unique)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: thresholdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Similarity Threshold (0.0 - 1.0)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Required';
                  }
                  final value = double.tryParse(v);
                  if (value == null || value < 0.0 || value > 1.0) {
                    return 'Enter a number between 0 and 1';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final resp = await ApiService.createBatch(
                username: widget.username,
                batchName: nameCtrl.text.trim(),
                batchCode: codeCtrl.text.trim(),
                similarityThreshold: double.parse(thresholdCtrl.text.trim()),
              );
              if (!mounted) return;
              if (resp['status'] == 'success') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Batch "${nameCtrl.text.trim()}" created!'),
                  ),
                );
                await _loadBatches();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resp['message'] ?? 'Failed to create batch'),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateThresholdDialog(Map<String, dynamic> batch) async {
    final thresholdCtrl = TextEditingController(
      text: (batch['similarity_threshold'] ?? 0.8).toString(),
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Similarity Threshold'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: thresholdCtrl,
            decoration: const InputDecoration(
              labelText: 'Threshold (0.0 - 1.0)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Required';
              }
              final value = double.tryParse(v);
              if (value == null || value < 0.0 || value > 1.0) {
                return 'Enter a number between 0 and 1';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final value = double.parse(thresholdCtrl.text.trim());
              final resp = await ApiService.setBatchThreshold(
                username: widget.username,
                batchId: batch['id'] as int,
                similarityThreshold: value,
              );
              if (!mounted) return;
              Navigator.pop(ctx);
              if (resp['status'] == 'success') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Threshold updated to $value'),
                  ),
                );
                await _loadBatches();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resp['message'] ?? 'Failed to update threshold'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showViewBatchesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your Batches'),
        content: SizedBox(
          width: 360,
          child: _loadingBatches
              ? const Center(child: CircularProgressIndicator())
              : _batches.isEmpty
              ? const Text('No batches created yet.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _batches.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final b = _batches[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo[100],
                        child: Text(
                          (b['batch_name'] as String).isNotEmpty
                              ? (b['batch_name'] as String)[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.indigo[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(b['batch_name'] ?? ''),
                      subtitle: Text(
                        'Code: ${b['batch_code']} · Threshold: ${double.tryParse((b['similarity_threshold'] ?? 0.8).toString())?.toStringAsFixed(2) ?? '0.80'}',
                      ),
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text('${b['member_count']} students'),
                            backgroundColor: Colors.indigo[50],
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: 'Update threshold',
                            onPressed: () => _showUpdateThresholdDialog(b),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Faculty Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout, color: Colors.white),
            onPressed: _isLoggingOut ? null : _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header card ----
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
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prof. ${widget.username}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_batches.length} batch${_batches.length != 1 ? 'es' : ''} created',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Actions',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              // ---- Create Batch ----
              _ActionCard(
                icon: Icons.add_box_rounded,
                color: Colors.indigo,
                title: 'Create Batch',
                subtitle: 'Generate a new batch for students to join',
                onTap: _showCreateBatchDialog,
              ),
              const SizedBox(height: 12),
              // ---- View Batches ----
              _ActionCard(
                icon: Icons.view_list_rounded,
                color: Colors.deepPurple,
                title: 'View Batches',
                subtitle: 'See all batches and student counts',
                onTap: () {
                  _loadBatches().then((_) => _showViewBatchesDialog());
                },
                trailing: _loadingBatches
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              const SizedBox(height: 32),
              // ---- Batch summary chips ----
              if (_batches.isNotEmpty) ...[
                const Text(
                  'Recent Batches',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _batches.take(6).map((b) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Colors.indigo[700],
                        child: Text(
                          (b['batch_name'] as String)[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      label: Text(
                        '${b['batch_name']}  ·  ${b['batch_code']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF1E1E3F),
                      side: BorderSide(color: Colors.indigo.shade800),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STUDENT DASHBOARD
// ============================================================================
class StudentDashboardPage extends StatefulWidget {
  final String username;
  const StudentDashboardPage({super.key, required this.username});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  bool _isLoggingOut = false;
  bool _isUploading = false;
  bool _loadingBatches = true;
  List<Map<String, dynamic>> _joinedBatches = [];

  @override
  void initState() {
    super.initState();
    _loadJoinedBatches();
  }

  Future<void> _loadJoinedBatches() async {
    setState(() => _loadingBatches = true);
    final resp = await ApiService.getStudentBatches(username: widget.username);
    if (mounted) {
      setState(() {
        _loadingBatches = false;
        if (resp['status'] == 'success') {
          _joinedBatches = List<Map<String, dynamic>>.from(
            resp['batches'] ?? [],
          );
        }
      });
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showJoinBatchDialog() async {
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join a Batch'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: codeCtrl,
            decoration: const InputDecoration(
              labelText: 'Enter Batch Code',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key_rounded),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter a batch code'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final resp = await ApiService.joinBatch(
                username: widget.username,
                batchCode: codeCtrl.text.trim(),
              );
              if (!mounted) return;
              if (resp['status'] == 'success') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(resp['message'] ?? 'Joined batch!')),
                );
                await _loadJoinedBatches();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resp['message'] ?? 'Failed to join batch'),
                  ),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasJoinedBatch = _joinedBatches.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Student Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout, color: Colors.white),
            onPressed: _isLoggingOut ? null : _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loadingBatches
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Header card ----
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasJoinedBatch
                              ? [Colors.teal.shade700, Colors.teal.shade900]
                              : [
                                  Colors.blueGrey.shade700,
                                  Colors.blueGrey.shade900,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (hasJoinedBatch ? Colors.teal : Colors.blueGrey)
                                    .withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasJoinedBatch
                                      ? '${_joinedBatches.length} batch${_joinedBatches.length != 1 ? 'es' : ''} joined'
                                      : 'Not yet in any batch',
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
                    ),
                    const SizedBox(height: 32),

                    // ---- Status banner if no batch ----
                    if (!hasJoinedBatch)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          border: Border.all(color: Colors.amber.shade700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber[400]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'You need to join a batch before you can upload documents.',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!hasJoinedBatch) const SizedBox(height: 24),

                    const Text(
                      'Actions',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---- Join Batch (always visible) ----
                    _ActionCard(
                      icon: Icons.group_add_rounded,
                      color: Colors.indigo,
                      title: 'Join Batch',
                      subtitle: 'Enter a batch code to join',
                      onTap: _showJoinBatchDialog,
                    ),

                    // ---- Joined batches list (REMOVED global upload, now batch-specific) ----
                    if (hasJoinedBatch) ...[
                      const SizedBox(height: 32),
                      const Text(
                        'My Batches',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._joinedBatches.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _BatchTile(
                            batch: b,
                            username: widget.username,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BatchDetailsPage(
                                    batch: b,
                                    username: widget.username,
                                  ),
                                ),
                              ).then((_) {
                                // Refresh batch list on return
                                _loadJoinedBatches();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

// ============================================================================
// BATCH DETAILS PAGE — Show batch-specific upload and documents
// ============================================================================
class BatchDetailsPage extends StatefulWidget {
  final Map<String, dynamic> batch;
  final String username;

  const BatchDetailsPage({
    super.key,
    required this.batch,
    required this.username,
  });

  @override
  State<BatchDetailsPage> createState() => _BatchDetailsPageState();
}

class _BatchDetailsPageState extends State<BatchDetailsPage> {
  bool _isUploading = false;
  bool _isLoadingDocs = true;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoadingDocs = true);
    final resp = await ApiService.getBatchDocuments(
      batchId: widget.batch['id'] as int,
    );
    if (mounted) {
      setState(() {
        _isLoadingDocs = false;
        if (resp['status'] == 'success') {
          _documents = List<Map<String, dynamic>>.from(resp['documents'] ?? []);
        }
      });
    }
  }

  Future<void> _pickAndUploadDocument() async {
    setState(() => _isUploading = true);
    try {
      final XTypeGroup typeGroup = XTypeGroup(
        extensions: ['pdf', 'docx', 'txt'],
      );
      final XFile? picked = await openFile(acceptedTypeGroups: [typeGroup]);

      if (picked == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No file selected')));
        }
        return;
      }

      Map<String, dynamic> resp;
      if (kIsWeb) {
        final fileBytes = await picked.readAsBytes();
        resp = await ApiService.uploadDocumentToBatch(
          fileBytes: fileBytes,
          filename: picked.name,
          username: widget.username,
          batchId: widget.batch['id'] as int,
        );
      } else {
        final path = picked.path;
        if (path.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not resolve file path')),
            );
          }
          return;
        }
        resp = await ApiService.uploadDocumentToBatch(
          filePath: path,
          username: widget.username,
          batchId: widget.batch['id'] as int,
        );
      }

      if (!mounted) return;
      final highestSimilarity = resp['highest_similarity'];
      final accepted = resp['status'] == 'success';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(accepted ? 'Upload Accepted' : 'Upload Rejected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resp['message'] ??
                  (accepted ? 'Your document was uploaded.' : 'Your document was rejected.')),
              const SizedBox(height: 12),
              if (highestSimilarity != null)
                Text('Highest similarity: ${double.parse(highestSimilarity.toString()).toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (accepted) {
        await _loadDocuments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: Text(
          widget.batch['batch_name'] ?? 'Batch',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingDocs
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Batch Header Card ----
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade700, Colors.teal.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  (widget.batch['batch_name'] as String)[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.batch['batch_name'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Code: ${widget.batch['batch_code']}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_documents.length} document${_documents.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ---- Upload Button (Batch-Specific) ----
                    _ActionCard(
                      icon: Icons.upload_file_rounded,
                      color: Colors.teal,
                      title: 'Upload Document',
                      subtitle: 'Upload PDF, DOCX, or TXT to this batch',
                      onTap: _isUploading ? null : _pickAndUploadDocument,
                      trailing: _isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),

                    // ---- Documents List ----
                    const SizedBox(height: 32),
                    const Text(
                      'Documents Uploaded',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_documents.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade800),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              color: Colors.white30,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No documents yet',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Upload your first document to get started',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _documents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final doc = _documents[i];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.teal.shade900),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade900,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    color: Colors.teal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc['file_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'By ${doc['uploaded_by'] ?? 'Unknown'}',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        doc['uploaded_at'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white30,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ============================================================================
// BATCH TILE — Clickable batch card for student dashboard
// ============================================================================
class _BatchTile extends StatelessWidget {
  final Map<String, dynamic> batch;
  final String username;
  final VoidCallback onTap;

  const _BatchTile({
    required this.batch,
    required this.username,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade900),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal[800],
                child: Text(
                  (batch['batch_name'] as String)[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch['batch_name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Code: ${batch['batch_code']}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white38,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED — Action Card widget
// ============================================================================
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final MaterialColor color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.shade900),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color.shade300, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onTap != null ? Colors.white : Colors.white38,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: onTap != null ? Colors.white38 : Colors.white12,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
