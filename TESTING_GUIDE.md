# Faculty Batch Details Feature - Testing & Setup Guide

## Prerequisites
- Django backend running with SQLite database
- Flutter development environment set up
- Both backend and frontend codebases updated with latest changes

---

## Part 1: Backend Setup

### Step 1: Apply Database Migrations
```bash
cd backend
python manage.py migrate
```
✅ You should see: `Applying api.0005_document_similarity_score_document_status... OK`

### Step 2: Verify Models
```bash
python manage.py shell
```
Then in shell:
```python
from api.models import Document
print(Document._meta.get_fields())
# Should show: similarity_score and status fields
```

### Step 3: Start Django Development Server
```bash
python manage.py runserver
```
Backend should be running on: `http://127.0.0.1:8000/`

---

## Part 2: Flutter Setup

### Step 1: Update Dependencies (if needed)
```bash
cd frontend
flutter pub get
```

### Step 2: Verify Configuration
Check `lib/api_host.dart` to ensure backend URL is correct:
```dart
String getApiBaseUrl() {
  if (kIsWeb) {
    return 'http://YOUR_BACKEND_URL/api/';
  } else {
    return 'http://YOUR_BACKEND_URL/api/'; // Or localhost:8000
  }
}
```

### Step 3: Check for Analysis Issues
```bash
flutter analyze
```
Note: Some warnings about deprecated `withOpacity()` are expected and don't affect functionality.

### Step 4: Run Flutter App
```bash
flutter run
```
Or for web:
```bash
flutter run -d chrome
```

---

## Part 3: Manual Testing

### Test Case 1: Faculty Creates Batch and Views Details

**Steps:**
1. Register as faculty
2. Login with faculty credentials
3. Click "Create Batch"
4. Enter:
   - Batch Name: "Test Batch 1"
   - Batch Code: "TEST001"
   - Similarity Threshold: "0.80"
5. Click "Create"
6. See snackbar: "Batch "Test Batch 1" created!"

**Expected Result:** Batch created successfully

---

### Test Case 2: Students Join Batch

**Steps:**
1. Register 2-3 students
2. For each student:
   - Login
   - Click "Join a Batch"
   - Enter batch code: "TEST001"
   - Click "Join"
3. See snackbar: "Joined batch "Test Batch 1" successfully"

**Expected Result:** Multiple students joined the batch

---

### Test Case 3: Faculty Views Batch Details

**Steps:**
1. Login as faculty who created the batch
2. Click "View Batches"
3. In the dialog, see the batch "Test Batch 1" listed
4. **Click on the batch name** (NOT the edit button)
5. Navigate to `BatchDetailPage`

**Expected Page Contents:**
- Batch Information card showing:
  - Batch Name: "Test Batch 1"
  - Batch Code: "TEST001"
  - Similarity Threshold: "80.0%"
  - Total Students: "3" (or however many joined)
  - Documents Uploaded: "0"

- Student & Document Status table showing:
  - All 3 students listed
  - Document column showing "Not uploaded yet"
  - Status column showing "Not Uploaded" (orange badge)
  - Similarity column showing "N/A"

- Detailed Student Cards showing:
  - Each student with their join date/time
  - Status badge (Not Uploaded - orange)
  - Document Information section with "Not uploaded yet"

**Expected Result:** All information displays correctly ✅

---

### Test Case 4: Student Uploads Document (ACCEPTED)

**Steps:**
1. Login as first student
2. Select the batch "Test Batch 1"
3. Create a simple text file: `my_assignment.txt` with content "This is my assignment."
4. Click "Upload Document"
5. Select the file and upload

**Expected Result:**
- Snackbar: "Document uploaded successfully"
- Document accepted (similarity < 0.80)

---

### Test Case 5: Faculty Sees Accepted Document

**Steps:**
1. Keep faculty logged in or login again
2. View Batches → Click "Test Batch 1"
3. Check the Updated Batch Details page

**Expected Changes:**
- Documents Uploaded count: "1"
- In table:
  - Student 1: Document shows "my_assignment.txt"
  - Status shows "Accepted" (green badge)
  - Similarity shows "0.00" (only 1 document, nothing to compare to)
- In detailed cards:
  - Student 1 card shows:
    - Document Name: "my_assignment.txt"
    - Upload Time: (current date/time)
    - Similarity Score: "0.0000 (0.00%)"
    - Threshold: "80.0%"
    - Decision: "Accepted (Below Threshold)" (green text)

**Expected Result:** Document status accurately reflected ✅

---

### Test Case 6: Second Student Uploads Similar Document (REJECTED)

**Steps:**
1. Login as second student
2. Create a similar file: `my_assignment2.txt` with content "This is my assignment."
   (Same or very similar content as student 1)
3. Upload the document

**Expected Result:**
- Snackbar: "Document was rejected: similarity score X.XX exceeds threshold 0.80"
- Document still saved to database (for audit trail)

---

### Test Case 7: Faculty Sees Rejected Document

**Steps:**
1. Faculty views batch details (refresh page if needed)
2. Look for second student

**Expected Changes:**
- Documents Uploaded count: "2"
- In table:
  - Student 2: Document shows "my_assignment2.txt"
  - Status shows "Rejected" (red badge)
  - Similarity shows calculated value (e.g., "0.95" / "95.00%")
- In detailed cards:
  - Student 2 card shows:
    - Document Name: "my_assignment2.txt"
    - Upload Time: (time of upload)
    - Similarity Score: "0.95XX (95.XX%)"
    - Threshold: "80.0%"
    - Decision: "Rejected (Exceeds Threshold)" (red text)

**Expected Result:** Rejection properly recorded and displayed ✅

---

### Test Case 8: Recent Batches Chips Navigation

**Steps:**
1. Faculty Dashboard, if scrolled down, see "Recent Batches" section with chips
2. Look for "Test Batch 1 · TEST001" chip
3. **Click on the chip**
4. Should navigate to Batch Detail page for "Test Batch 1"

**Expected Result:** Chip tap navigates correctly ✅

---

### Test Case 9: Refresh Functionality

**Steps:**
1. In Batch Detail page, click the refresh icon in AppBar
2. Wait for data to reload

**Expected Result:**
- Shows loading spinner
- Reloads all batch details
- Updates any latest changes ✅

---

### Test Case 10: Multiple Documents from Same Student

**Steps:**
1. As Student 1, upload another document: `revised_assignment.txt`
   with different content
2. Faculty views batch details

**Expected Result:**
- Batch details show the LATEST document from Student 1
- Table shows the most recent document name and status
- Only the latest document is displayed in the card

---

### Test Case 11: Update Threshold and Re-check

**Steps:**
1. Faculty clicks "View Batches"
2. Clicks the edit icon (pencil) for "Test Batch 1"
3. Changes threshold from "0.80" to "0.95"
4. Clicks "Save"
5. Views batch details again
6. Look for Student 2's status

**Expected Behavior:**
- Threshold updated in Batch table
- Threshold displayed in Batch Detail page: "95.0%"
- Note: Already-uploaded documents' status is NOT retroactively changed

**Expected Result:** Threshold updates in UI ✅

---

### Test Case 12: Student Never Uploads

**Steps:**
1. Leave Student 3 without uploading
2. Faculty views batch details

**Expected:**
- Student 3 card shows:
  - Document Name: "Not uploaded yet"
  - Upload Time: "Not uploaded"
  - No Similarity Score shown
  - Status badge: "Not Uploaded" (orange)

**Expected Result:** Correctly shows pending/missing status ✅

---

## Part 4: API Testing (Optional)

### Test get-batch-details Endpoint Directly

**Using cURL:**
```bash
curl -X POST http://localhost:8000/api/get-batch-details/ \
  -H "Content-Type: application/json" \
  -d '{"username": "faculty_user", "batch_id": 1}'
```

**Expected Response:**
```json
{
  "status": "success",
  "batch": {
    "batch_id": 1,
    "batch_name": "Test Batch 1",
    "batch_code": "TEST001",
    "similarity_threshold": 0.95,
    "created_at": "2024-01-15T10:30:00Z",
    "total_students": 3,
    "documents_count": 2,
    "students": [...]
  }
}
```

---

## Troubleshooting

### Issue: "Batch not found" or "Unauthorized"
**Solution:** Ensure:
1. Batch ID is correct
2. Faculty username is correct
3. Faculty created the batch (authorization check)

### Issue: Similarity scores all showing 0
**Solution:** This is normal for first documents. Similarity is compared against existing documents. The first document has nothing to compare to.

### Issue: Documents not appearing in batch details
**Solution:**
1. Check Document model migration was applied
2. Verify documents were saved with correct batch_id
3. Check database: `SELECT * FROM api_document WHERE batch_id = 1;`

### Issue: Flutter page not loading
**Solution:**
1. Check network connection
2. Verify backend URL in `api_host.dart`
3. Check Flutter debug logs: `flutter logs`
4. Verify API endpoint is working with cURL

### Issue: "withOpacity is deprecated" warnings
**Solution:** These are Flutter deprecation warnings and don't affect functionality. They can be fixed in the code by using `.withValues(alpha: ...)` instead, but are not critical.

---

## Database Verification

### Check Documents Table Structure
```bash
cd backend
python manage.py shell
```

```python
from api.models import Document
for field in Document._meta.get_fields():
    print(f"{field.name}: {field.get_internal_type()}")
```

Should show:
- `id`: AutoField
- `user_id`: ForeignKey
- `batch_id`: ForeignKey
- `file_name`: CharField
- `file`: FileField
- `extracted_text`: TextField
- `uploaded_at`: DateTimeField
- **`similarity_score`: FloatField**  ← NEW
- **`status`: CharField**  ← NEW

---

## Performance Notes

- First batch load may take 2-3 seconds as it fetches all students and documents
- Use refresh button to reload latest data
- Similarity calculations happen at upload time (not on page load)
- No real-time updates (use refresh button for latest data)

---

## Success Criteria Checklist

- [ ] Django migration applied successfully
- [ ] Document model has similarity_score and status fields
- [ ] Faculty can navigate to batch details from "View Batches"
- [ ] Faculty can navigate to batch details from "Recent Batches" chips
- [ ] Batch detail page displays all students
- [ ] Accepted documents show green status badge
- [ ] Rejected documents show red status badge
- [ ] Not uploaded documents show orange "Not Uploaded" status
- [ ] Similarity scores displayed correctly
- [ ] Threshold value displayed and matches batch setting
- [ ] Table view shows quick overview
- [ ] Detailed cards show comprehensive information
- [ ] Refresh button works correctly
- [ ] No critical errors in logs

---

## Next Steps After Testing

1. Add more comprehensive error handling if needed
2. Test on different devices/screen sizes
3. Consider adding download functionality for documents
4. Add export to CSV feature
5. Implement real-time updates using WebSockets (optional)

