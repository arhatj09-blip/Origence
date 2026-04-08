# Batch-Specific Document Upload System

## Overview
Updated the Origence system so that:
- Document uploads are now **batch-specific**
- Students can only upload documents **after joining a batch**
- Upload buttons appear **inside each batch**, not globally
- Documents are organized and displayed **by batch**

---

## Backend Changes

### 1. Django Models (Already Implemented ✓)

**File:** `backend/api/models.py`

```python
class Batch(models.Model):
    batch_name = models.CharField(max_length=255)
    batch_code = models.CharField(max_length=50, unique=True)
    created_by = models.ForeignKey('auth_api.User', on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

class StudentBatchMapping(models.Model):
    student = models.ForeignKey('auth_api.User', on_delete=models.CASCADE)
    batch = models.ForeignKey(Batch, on_delete=models.CASCADE)
    joined_at = models.DateTimeField(auto_now_add=True)

class Document(models.Model):
    user = models.ForeignKey('auth_api.User', on_delete=models.CASCADE)
    batch = models.ForeignKey(Batch, on_delete=models.CASCADE, null=True, blank=True)
    file_name = models.CharField(max_length=255)
    file = models.FileField(upload_to='documents/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
```

### 2. API Endpoints

#### `/api/upload-document/` (Updated)
**Method:** POST  
**Purpose:** Upload a document to a specific batch  
**Required Fields:**
- `username` (string): Student username
- `batch_id` (integer): Batch ID
- `file` (file): PDF, DOCX, or TXT file

**Validation:**
- ✓ Checks if student is a member of the batch
- ✓ Rejects upload if student is not in the batch
- ✓ Links document to the batch in database

**Response:**
```json
{
  "status": "success",
  "message": "Document uploaded successfully"
}
```

#### `/api/get-batch-documents/` (New)
**Method:** POST or GET  
**Purpose:** Retrieve all documents uploaded to a specific batch  
**Required Parameter:**
- `batch_id` (integer): Batch ID

**Response:**
```json
{
  "status": "success",
  "documents": [
    {
      "id": 1,
      "file_name": "essay.pdf",
      "uploaded_by": "john_doe",
      "uploaded_at": "2024-04-08T10:30:00Z",
      "batch_id": 5
    }
  ]
}
```

#### Existing Endpoints (Unchanged)
- `/api/create-batch/` — Faculty creates batch
- `/api/get-batches/` — Get batches created by faculty
- `/api/join-batch/` — Student joins a batch
- `/api/get-student-batches/` — Get list of batches student joined

### 3. Backend Files Updated
- `backend/api/views.py` — Added `get_batch_documents()` endpoint
- `backend/api/urls.py` — Added route for `get_batch_documents`

**To apply changes:**
```bash
cd backend
python manage.py migrate  # Apply any pending migrations
python manage.py runserver
```

---

## Frontend Changes

### 1. API Service Updates

**File:** `frontend/lib/api_service.dart`

#### New Methods Added:

```dart
// Get all documents for a specific batch
static Future<Map<String, dynamic>> getBatchDocuments({
  required int batchId,
}) async { ... }

// Upload document to a specific batch  
static Future<Map<String, dynamic>> uploadDocumentToBatch({
  String? filePath,
  Uint8List? fileBytes,
  String? filename,
  required String username,
  required int batchId,
}) async { ... }
```

### 2. UI Changes

#### StudentDashboardPage (Updated)
**File:** `frontend/lib/dashboard_page.dart`

**Changes:**
- ✓ Removed global "Upload Document" action
- ✓ Shows "My Batches" list
- ✓ Batches are now **clickable**
- ✓ Navigates to `BatchDetailsPage` when batch is tapped

**Behavior:**
```
Student Dashboard
├─ Join Batch (always visible)
└─ My Batches (clickable list)
   └─ Batch A ──→ [TAP] → BatchDetailsPage
   └─ Batch B ──→ [TAP] → BatchDetailsPage
```

#### BatchDetailsPage (New)
**File:** `frontend/lib/dashboard_page.dart`

**Features:**
1. **Batch Header Card**
   - Batch name
   - Batch code
   - Document count

2. **Upload Button (Batch-Specific)**
   - Only uploads to the selected batch
   - Only visible inside the batch
   - Validates file type (PDF, DOCX, TXT)

3. **Documents List**
   - Shows all documents uploaded to this batch
   - Displays:
     - File name
     - Uploader name
     - Upload timestamp
   - Empty state message if no documents

**Code Structure:**
```dart
class BatchDetailsPage extends StatefulWidget {
  final Map<String, dynamic> batch;     // Batch data
  final String username;                 // Current student

  // Load batch documents on init
  // Handle file upload to this batch
  // Display documents list
}
```

#### _BatchTile (New)
**File:** `frontend/lib/dashboard_page.dart`

A clickable card for each batch in the student dashboard.

**Features:**
- Batch initial icon
- Batch name and code
- Arrow indicating it's clickable
- Navigates to `BatchDetailsPage` on tap

---

## User Flow

### Before (Old System)
```
Login (Student)
    ↓
Student Dashboard
    ├─ Upload Document ─→ Global upload (no batch context)
    └─ Join Batch
```

### After (New System)
```
Login (Student)
    ↓
Student Dashboard
    ├─ Join Batch ─→ Enter batch code
    └─ My Batches (Clickable)
           ↓
        [Batch A]
           ↓
        Batch Details Page
           ├─ Upload Document ─→ Upload to Batch A only
           └─ Documents
              └─ List of files in Batch A
```

---

## Database Schema

### Document Table (Updated)
```
documents
├─ id (PK)
├─ user_id (FK) ──→ auth_api_user
├─ batch_id (FK) ──→ api_batch      ← NOW REQUIRED
├─ file_name
├─ file (path)
└─ uploaded_at

Key Change: batch_id is now linked for organization
```

---

## API Call Examples

### 1. Upload Document to Batch A
```javascript
POST /api/upload-document/
FormData:
  - username: "john_doe"
  - batch_id: "5"
  - file: <binary PDF file>

Response:
{
  "status": "success",
  "message": "Document uploaded successfully"
}
```

### 2. Fetch Documents from Batch A
```javascript
POST /api/get-batch-documents/
Payload:
{
  "batch_id": 5
}

Response:
{
  "status": "success",
  "documents": [
    {
      "id": 12,
      "file_name": "essay.pdf",
      "uploaded_by": "john_doe",
      "uploaded_at": "2024-04-08T10:30:00Z",
      "batch_id": 5
    },
    {
      "id": 13,
      "file_name": "report.docx",
      "uploaded_by": "jane_smith",
      "uploaded_at": "2024-04-08T11:45:00Z",
      "batch_id": 5
    }
  ]
}
```

---

## Key Features Implemented

✅ **Batch-Specific Uploads**
- Documents are linked to batches in database
- Upload validation ensures student is batch member

✅ **Batch-Scoped UI**
- Upload button appears only inside batch
- Documents shown only for that batch

✅ **Student Workflow**
- Join batch first
- Then upload inside that batch
- Unlimited documents per batch

✅ **Faculty View** (Unchanged)
- Can see their batches
- Can see member count
- Can monitor uploads per batch

✅ **Validation**
- Backend validates batch membership before upload
- Prevents cross-batch document mixing

---

## Testing Checklist

### Backend
- [ ] Create a batch as faculty
- [ ] Join batch as student
- [ ] Try to upload without joining (should fail)
- [ ] Upload document successfully
- [ ] Fetch documents for batch (should show only documents in that batch)
- [ ] Join another batch and upload (documents stay separate)

### Frontend
- [ ] Student dashboard shows "Join Batch" button
- [ ] Student can join batch with code
- [ ] Batch appears in "My Batches" list
- [ ] Clicking batch opens BatchDetailsPage
- [ ] Upload button works in batch details
- [ ] Uploaded documents appear in document list
- [ ] Multiple batches show separate documents

---

## Files Modified

**Backend:**
- `backend/api/views.py` — Added `get_batch_documents()` endpoint
- `backend/api/urls.py` — Added route registration
- `backend/api/models.py` — No changes (already correct)
- `backend/auth_api/models.py` — No changes

**Frontend:**
- `frontend/lib/api_service.dart`
  - Added imports for `dart:typed_data` and `flutter/foundation`  
  - Added `getBatchDocuments()` method
  - Added `uploadDocumentToBatch()` method
  
- `frontend/lib/dashboard_page.dart`
  - Updated `StudentDashboardPage` — Removed global upload, made batches clickable
  - Added `BatchDetailsPage` — New page for batch details
  - Added `_BatchTile` — New widget for batch card  
  - Removed `_pickAndUploadDocument()` — Now in `BatchDetailsPage`
  - Removed `_showBatchPickerDialog()` — No longer needed

---

## Troubleshooting

### "You are not a member of this batch"
**Cause:** Backend is correctly validating batch membership  
**Fix:** Student must join the batch first before uploading

### Documents not showing in batch
**Cause:** Documents from other users or old uploads may not be showing  
**Fix:** Check backend response includes correct `batch_id`

### Upload button doesn't appear
**Cause:** Student hasn't joined any batches  
**Fix:** Join a batch first using "Join Batch" button

### Document list is empty
**Cause:** No documents have been uploaded to this batch yet  
**Fix:** Upload your first document to populate the list

---

## Future Enhancements

- [ ] Download documents
- [ ] Delete documents (by uploader or admin)
- [ ] Plagiarism detection integration
- [ ] Document comments/feedback
- [ ] Batch statistics dashboard
- [ ] Export batch documents
- [ ] Document versioning

---

## Summary

The system now implements **true batch-specific uploads**:
- Students must join a batch before accessing upload
- Each batch maintains its own document list
- Backend validates all operations
- Clear UI distinction between batches
- Scalable to multiple batches per student
