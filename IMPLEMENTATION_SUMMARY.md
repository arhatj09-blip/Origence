# Faculty Batch Details Feature - Implementation Summary

## Overview
This implementation adds a detailed batch view where faculty can see all students in a batch and their document upload status, including similarity scores and acceptance/rejection status.

---

## Backend Changes

### 1. Database Model Updates
**File: `backend/api/models.py`**

Updated the `Document` model to include:
- `similarity_score` (FloatField): Stores the highest similarity score compared to existing documents in the batch
- `status` (CharField): Tracks whether the document was 'accepted' or 'rejected' based on threshold comparison
- Added validators to ensure similarity_score is between 0.0 and 1.0

### 2. Upload Document Logic Update
**File: `backend/api/views.py`** - `upload_document()` function

Changed the document upload logic:
- **Before**: Documents exceeding threshold were rejected and file was deleted
- **After**: All documents are saved with their similarity_score and status fields populated
  - Calculates the highest similarity score against all existing documents in the batch
  - Sets status to 'accepted' if similarity < threshold, 'rejected' if >= threshold
  - Always saves the document to database for complete audit trail
  - Returns appropriate success/error response based on status

### 3. New API Endpoint
**File: `backend/api/views.py`** - New `get_batch_details()` function

Creates a new endpoint: `POST /api/get-batch-details/`

**Request:**
```json
{
  "username": "faculty_username",
  "batch_id": 1
}
```

**Response:**
```json
{
  "status": "success",
  "batch": {
    "batch_id": 1,
    "batch_name": "CS101-Fall2024",
    "batch_code": "CS101",
    "similarity_threshold": 0.8,
    "created_at": "2024-01-15T10:30:00Z",
    "total_students": 5,
    "documents_count": 3,
    "students": [
      {
        "student_id": 2,
        "username": "student1",
        "joined_at": "2024-01-15T11:00:00Z",
        "document_uploaded": true,
        "document_details": {
          "document_id": 5,
          "file_name": "assignment.pdf",
          "uploaded_at": "2024-01-16T09:30:00Z",
          "similarity_score": 0.65,
          "status": "accepted"
        }
      },
      {
        "student_id": 3,
        "username": "student2",
        "joined_at": "2024-01-15T11:05:00Z",
        "document_uploaded": false,
        "document_details": {
          "file_name": "Not uploaded yet",
          "uploaded_at": null,
          "similarity_score": null,
          "status": "pending"
        }
      }
    ]
  }
}
```

**Features:**
- Authorizes that the requesting user is the faculty who created the batch
- Fetches all students who joined the batch
- For each student, retrieves their latest uploaded document
- Returns comprehensive student and document status information
- Clearly indicates when no document has been uploaded yet

### 4. URL Configuration
**File: `backend/api/urls.py`**

Added new URL pattern:
```python
path('get-batch-details/', get_batch_details, name='get_batch_details'),
```

### 5. Database Migration
**File: `backend/api/migrations/0005_document_similarity_score_document_status.py`**

Auto-generated migration that:
- Adds `similarity_score` field to Document model
- Adds `status` field to Document model
- Migration successfully applied to database

---

## Frontend (Flutter) Changes

### 1. API Service Extension
**File: `frontend/lib/api_service.dart`**

Added new method `getBatchDetails()`:
```dart
static Future<Map<String, dynamic>> getBatchDetails({
  required String username,
  required int batchId,
}) async
```

- Makes POST request to `/api/get-batch-details/`
- Handles network errors and JSON parsing
- Returns the complete batch details response

### 2. New Batch Detail Page
**File: `frontend/lib/batch_detail_page.dart`** (NEW FILE)

A comprehensive new page showing:

**Batch Information Card:**
- Batch name
- Batch code
- Similarity threshold (displayed as percentage)
- Total students count
- Documents uploaded count

**Student & Document Status Table:**
- Tabular view of all students
- Columns: Student, Document, Status, Similarity
- Status badges with color coding:
  - Orange: Not Uploaded (pending)
  - Green: Accepted (below threshold)
  - Red: Rejected (exceeds threshold)
- Shows similarity as decimal and percentage

**Detailed Student Information Cards:**
- One card per student with:
  - Student username
  - Date/time when joined batch
  - Status badge (visual indicator)
  - Document name
  - Upload date/time
  - Similarity score (if uploaded)
  - Threshold value (for comparison)
  - Final decision (Accepted/Rejected/Not Uploaded)
  
**Features:**
- Pull-to-refresh functionality (refresh button in AppBar)
- Loading state with spinner
- Error handling with user-friendly messages
- Responsive design with scrollable content
- Color-coded status indicators throughout

### 3. Dashboard Page Updates
**File: `frontend/lib/dashboard_page.dart`**

Updated the Faculty Dashboard to enable navigation to batch details:

**Changes:**
1. Added import: `import 'batch_detail_page.dart';`

2. Modified "View Batches" dialog:
   - ListTile for each batch now has `onTap` handler
   - Tapping navigates to `BatchDetailPage` with:
     - Faculty username
     - Batch ID
     - Batch name
   - Dialog closes before navigation

3. Made "Recent Batches" chips tappable:
   - Wrapped each Chip in a `GestureDetector`
   - `onTap` navigates to `BatchDetailPage`
   - Improved user experience by allowing quick access from summary chips

---

## Data Flow

### Faculty Views Batch Details:
1. Faculty sees batch in "View Batches" dialog or "Recent Batches" chips
2. Faculty taps on batch
3. `BatchDetailPage` loads and calls `getBatchDetails()` API
4. API returns:
   - Batch information (name, code, threshold)
   - List of all students with their joined timestamp
   - For each student: their latest document with status and similarity score
5. Page renders:
   - Summary card with batch info
   - Table with quick status overview
   - Detailed cards for each student

### Document Consistency:
- Latest threshold from Batch table is always used
- No cached threshold values
- Similarity scores are calculated and stored at upload time
- Status is determined by comparing similarity_score with threshold at upload time
- Faculty can see the decision that was made for each document

---

## Key Features

✅ **Real-time Document Status Tracking**
- Immediate visibility into which students have uploaded documents
- Clear status indicators (accepted/rejected/pending)

✅ **Similarity Score Visibility**
- Faculty can see the exact similarity score for each document
- Displayed as both decimal and percentage
- Compared against the batch threshold

✅ **Comprehensive Student View**
- Per-student cards showing all relevant information
- Join date/time tracking
- Document name and upload timestamp

✅ **Batch-Specific Document Isolation**
- Documents are never mixed across batches
- Faculty only sees documents belonging to their batch
- Proper authorization checking in backend

✅ **Robust Error Handling**
- Network error handling in API calls
- User-friendly error messages
- Loading states during data fetch

✅ **Responsive Design**
- Works on different screen sizes
- Scrollable table and card layouts
- Mobile-friendly UI components

---

## Technical Notes

### Database:
- SQLite database automatically updated with migration
- No data loss (migration adds new nullable fields)
- Existing documents have similarity_score=0.0, status='accepted' by default

### API:
- All endpoints use CSRF exemption (as per existing pattern)
- Authorization checks for faculty ownership of batch
- Proper HTTP status codes (404, 403, 400, 500)

### Flutter:
- No new dependencies required
- Uses existing ApiService pattern
- Material Design components throughout
- Response handling matches existing API patterns

---

## Testing Checklist

- [ ] Backend migration applied successfully
- [ ] Test creating a new batch
- [ ] Test students joining batch
- [ ] Test uploading document under threshold (should be accepted)
- [ ] Test uploading document over threshold (should be rejected)
- [ ] Faculty views "View Batches" dialog and clicks on a batch
- [ ] Batch detail page loads and displays all information correctly
- [ ] "Recent Batches" chips are tappable and navigate to batch detail
- [ ] Similarity scores and status badges display correctly
- [ ] Test with multiple students and documents
- [ ] Test navigation back from batch detail page
- [ ] Test refresh functionality in batch detail page
- [ ] Test with students who haven't uploaded anything yet

---

## Future Enhancements

1. **Document Download**: Allow faculty to download documents from batch detail page
2. **Bulk Actions**: Select multiple students to perform actions
3. **Export**: Export batch data as CSV/PDF for reporting
4. **Similarity Report**: Show detailed similarity analysis between documents
5. **Re-evaluation**: Allow faculty to recalculate thresholds and re-check documents
6. **Historical Tracking**: Show previous document upload attempts
7. **Notifications**: Email faculty when new documents are uploaded or rejected
