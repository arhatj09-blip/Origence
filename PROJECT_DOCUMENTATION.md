# ORIGENCE - Academic Plagiarism Detection System
## Complete Project Documentation

---

## 📋 TABLE OF CONTENTS
1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [System Architecture](#system-architecture)
4. [Database Schema](#database-schema)
5. [Backend Details](#backend-details)
6. [Frontend Details](#frontend-details)
7. [API Endpoints](#api-endpoints)
8. [Setup Instructions](#setup-instructions)
9. [Deployment](#deployment)
10. [Key Features](#key-features)
11. [How It Works](#how-it-works)
12. [Project Structure](#project-structure)
13. [Running & Testing](#running--testing)

---

## 🎯 PROJECT OVERVIEW

**Origence** is a batch-based academic plagiarism detection system designed for educational institutions. It enables faculty members to create batches with configurable similarity thresholds and allows students to join batches and submit documents for plagiarism checking.

### Core Problem Statement
Educational institutions need a simple, effective way to detect document plagiarism while preventing unnecessary false positives. Origence solves this by:
- Allowing faculty to set institution-specific similarity thresholds
- Checking documents only within their respective batches (batch isolation)
- Providing real-time feedback to both students and faculty
- Automatically accepting or rejecting documents based on configured thresholds

### Target Users
- **Faculty Members**: Create batches, set thresholds, monitor submissions
- **Students**: Join batches using codes, upload documents, view plagiarism scores

---

## 🛠️ TECH STACK

### Frontend
- **Framework**: Flutter 3.10.8
- **Language**: Dart
- **Key Dependencies**:
  - `http: ^1.2.0` - HTTP requests for API communication
  - `shared_preferences: ^2.5.4` - Local storage for user credentials
  - `file_selector: ^1.1.0` - File selection on web/desktop
  - `cupertino_icons: ^1.0.8` - iOS-style icons
  - `flutter_lints: ^6.0.0` - Code quality linting

**Platforms Supported**: Android, iOS, Web, Windows, macOS, Linux

### Backend
- **Framework**: Django 5.2.13 (Python Web Framework)
- **Language**: Python 3.11
- **Database**: SQLite (local development), PostgreSQL (production on Railway)
- **Web Server**: Gunicorn 25.3.0

### Key Backend Dependencies
```
Django==5.2.13
django-cors-headers==4.9.0          # CORS support for Flutter frontend
PyPDF2==3.0.1                       # PDF text extraction
python-docx==1.2.0                  # DOCX text extraction
lxml==6.1.0                         # XML/HTML parsing
scikit-learn==0.24.0                # TF-IDF similarity (optional)
sentence-transformers               # AI similarity (optional)
gunicorn==25.3.0                    # Production WSGI server
whitenoise==6.12.0                  # Static file serving
dj-database-url==3.1.2              # Database URL parsing
python-decouple==3.8                # Environment variable management
psycopg2-binary==2.9.11             # PostgreSQL adapter
```

### Document Processing
- **PDF**: PyPDF2 library extracts text from PDF files
- **DOCX**: python-docx extracts text from Word documents
- **TXT**: Native Python file reading

### Similarity Detection
The system uses a hybrid approach with three algorithms:
1. **TF-IDF (TfidfVectorizer)** - Traditional statistical text similarity
2. **N-gram Based** - Sequence matching without external dependencies
3. **AI-based (SentenceTransformers)** - Deep learning sentence embeddings

All three methods are optional; the system works with any combination.

---

## 🏗️ SYSTEM ARCHITECTURE

### High-Level Architecture Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                      ORIGENCE SYSTEM                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐                    ┌────────────────┐   │
│  │   FRONTEND   │                    │    BACKEND     │   │
│  │  (Flutter)   │◄──────HTTP/REST───►│   (Django)     │   │
│  └──────────────┘                    └────────────────┘   │
│      │                                       │              │
│      ├─ Login/Register                       ├─ User Auth  │
│      ├─ Dashboard                           ├─ Batch Mgmt │
│      ├─ Create/Join Batch                   ├─ Doc Upload │
│      ├─ Upload Document                     ├─ Similarity │
│      └─ View Status                         │  Calculation│
│                                             └─ Document DB│
│                                                           │
│                      ┌───────────────┐                  │
│                      │   DATABASE    │                  │
│                      │  (SQLite/Pg)  │                  │
│                      │  - Users      │                  │
│                      │  - Batches    │                  │
│                      │  - Documents  │                  │
│                      │  - Mappings   │                  │
│                      └───────────────┘                  │
│                                                           │
│   ┌────────────────────────────────────────────────────┐ │
│   │  NLP ENGINE - Document Similarity Analysis        │ │
│   │  ├─ Text Extraction (PDF/DOCX/TXT)              │ │
│   │  ├─ Text Preprocessing                          │ │
│   │  ├─ Sentence Splitting                          │ │
│   │  └─ Multi-Algorithm Comparison (TF-IDF,N-gram)│ │
│   └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow for Document Upload
```
1. Student selects document
   ↓
2. Frontend sends file + metadata to backend
   ↓
3. Backend validates user & batch membership
   ↓
4. File stored; text extracted (PDF/DOCX/TXT)
   ↓
5. Extract text compared against ALL other documents in SAME batch
   ↓
6. Similarity score calculated (0.0 - 1.0)
   ↓
7. Compare score with batch threshold:
   - If similarity < threshold → ACCEPTED
   - If similarity ≥ threshold → REJECTED
   ↓
8. Document status & score stored in database
   ↓
9. Response sent to frontend with acceptance/rejection status
   ↓
10. Student receives feedback on plagiarism check
```

---

## 💾 DATABASE SCHEMA

### Database Models (Django ORM)

#### 1. **User Model** (`auth_api/models.py`)
```python
class User(models.Model):
    ROLE_CHOICES = [
        ('faculty', 'Faculty'),
        ('student', 'Student'),
    ]
    
    username          CharField(max_length=150, unique=True)
    password          CharField(max_length=128)  # Hashed with make_password()
    role              CharField(max_length=10, choices=ROLE_CHOICES)
    
    __str__: "{username} ({role})"
```

**Purpose**: Authentication for both faculty and students
**Constraints**: Username is unique across the system

---

#### 2. **Batch Model** (`api/models.py`)
```python
class Batch(models.Model):
    batch_name        CharField(max_length=255)
    batch_code        CharField(max_length=50, unique=True)
    created_by        ForeignKey(User, on_delete=CASCADE)  # Faculty creator
    similarity_threshold  FloatField(default=0.8)
                      # Range: 0.0 to 1.0
                      # Documents with similarity >= threshold are REJECTED
    created_at        DateTimeField(auto_now_add=True)
    
    __str__: "{batch_name} [{batch_code}]"
```

**Purpose**: Represents a plagiarism checking batch created by faculty
**Key Features**:
- Unique batch code allows students to join
- Dynamic similarity threshold can be updated by faculty
- All documents in batch are compared only with others in the same batch

**Indices**: 
- `batch_code` (unique)
- `created_by` (foreign key)

---

#### 3. **StudentBatchMapping Model** (`api/models.py`)
```python
class StudentBatchMapping(models.Model):
    student           ForeignKey(User, on_delete=CASCADE)
    batch             ForeignKey(Batch, on_delete=CASCADE)
    joined_at         DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('student', 'batch')
    
    __str__: "{student.username} → {batch.batch_name}"
```

**Purpose**: Tracks student-batch relationships (many-to-many join table)
**Key Features**:
- Ensures a student can only join a batch once
- Records when student joined the batch
- Validates that students can only upload documents to batches they've joined

**Constraints**:
- Unique combination of (student, batch)

---

#### 4. **Document Model** (`api/models.py`)
```python
class Document(models.Model):
    STATUS_CHOICES = [
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
    ]
    
    user              ForeignKey(User, on_delete=CASCADE)
    batch             ForeignKey(Batch, on_delete=CASCADE)
    file_name         CharField(max_length=255)  # Original filename
    file              FileField(upload_to='documents/')
    extracted_text    TextField(blank=True, null=True)
    similarity_score  FloatField(default=0.0)
                      # Range: 0.0 to 1.0
                      # Highest similarity vs any other doc in batch
    status            CharField(max_length=10, choices=STATUS_CHOICES, default='accepted')
                      # 'accepted': similarity < threshold
                      # 'rejected': similarity >= threshold
    uploaded_at       DateTimeField(auto_now_add=True)
    
    __str__: "{file_name} ({user}) — {batch}"
```

**Purpose**: Represents a submitted document
**Key Features**:
- Text automatically extracted and stored
- Similarity score calculated against all other documents in batch
- Status automatically determined by comparing score with batch threshold
- Uploaded files stored in media/documents/ directory

**Indices**:
- `user` (foreign key)
- `batch` (foreign key)
- `similarity_score`
- `status`

---

### Database Relationships

```
User (Faculty)
    │
    └──(creates)─→ Batch
                    │
                    ├──(contains)─→ StudentBatchMapping ←──(joins)── User (Student)
                    │
                    └──(contains)─→ Document ←──(submits)── User (Student)
```

### Migration Files
- `0001_initial.py` - Initial model creation
- `0002_alter_document_user_batch_document_batch_and_more.py` - Schema adjustments
- `0003_document_extracted_text.py` - Added text extraction field
- `0004_batch_similarity_threshold.py` - Made threshold configurable
- `0005_document_similarity_score_document_status.py` - Added score and status tracking

---

## 🔌 BACKEND DETAILS

### Project Structure
```
backend/
├── manage.py                 # Django CLI tool
├── requirements.txt          # Python dependencies
├── runtime.txt              # Python version specification (3.11.0)
├── Procfile                 # Deployment configuration
├── db.sqlite3              # Development database
├── config/                 # Core Django settings
│   ├── settings.py         # Main Django configuration
│   ├── urls.py            # URL routing
│   ├── wsgi.py            # WSGI application entry point
│   └── asgi.py            # ASGI configuration
├── auth_api/               # User authentication app
│   ├── models.py          # User model
│   ├── views.py           # Auth views (register, login, logout)
│   ├── urls.py            # Auth URL routes
│   ├── migrations/        # Database migrations
│   └── admin.py           # Django admin config
├── api/                    # Main plagiarism detection app
│   ├── models.py          # Batch, Document, Mapping models
│   ├── views.py           # API views (upload, batch management)
│   ├── urls.py            # API URL routes
│   ├── nlp_engine.py      # Similarity calculation
│   ├── pdf_extractor.py   # Text extraction logic
│   ├── migrations/        # Database migrations
│   └── admin.py           # Django admin config
├── core/                   # Core app
│   ├── models.py
│   ├── views.py
│   ├── urls.py
│   ├── migrations/
│   └── admin.py
└── media/                  # Uploaded files storage
    └── documents/          # Uploaded documents
```

### Key Django Configuration (`config/settings.py`)

**Installed Apps**:
- `django.contrib.admin` - Admin interface
- `django.contrib.auth` - Built-in auth (not used; custom auth in auth_api)
- `django.contrib.contenttypes` - Content type framework
- `django.contrib.sessions` - Session management
- `django.contrib.messages` - Messages framework
- `django.contrib.staticfiles` - Static file handling
- `corsheaders` - CORS headers for Flutter
- `core`, `auth_api`, `api` - Custom apps

**Middleware Stack** (in order):
1. `SecurityMiddleware` - Security headers
2. `WhiteNoiseMiddleware` - Serve static files in production
3. `SessionMiddleware` - Session management
4. `CorsMiddleware` - CORS handling
5. `CommonMiddleware` - Common utilities
6. `CsrfViewMiddleware` - CSRF protection
7. `AuthenticationMiddleware` - User authentication
8. `MessageMiddleware` - Messages framework
9. `XFrameOptionsMiddleware` - Clickjacking protection

**CORS Configuration**:
```python
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_METHODS = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']
```
*Note: In production, restrict origins to specific domains*

**Database**:
- **Production** (Railway): PostgreSQL via `DATABASE_URL` environment variable
- **Development** (Local): SQLite at `db.sqlite3`
- Uses `dj-database-url` for automatic environment-based configuration

**Static Files**:
- `STATIC_ROOT = BASE_DIR / 'staticfiles'`
- `STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'`
- Compressed and served by WhiteNoise

---

### Authentication System (`auth_api/views.py`)

#### Register Endpoint
**Endpoint**: `POST /api/register/`
```python
def register(request):
    # Validates:
    # 1. Username not empty
    # 2. Password not empty
    # 3. Confirm password matches password
    # 4. Role is 'faculty' or 'student'
    # 5. Username doesn't already exist
    
    # Password hashing: Django's make_password() with PBKDF2
    user = User(
        username=username,
        password=make_password(password),
        role=role,
    )
    user.save()
```

**Request**:
```json
{
    "username": "john_doe",
    "password": "SecurePassword123",
    "confirm_password": "SecurePassword123",
    "role": "student"  // or "faculty"
}
```

**Response**:
```json
{
    "status": "success",
    "message": "User registered successfully"
}
```

**Error Response**:
```json
{
    "status": "error",
    "errors": {
        "username": "Username already exists",
        "password": "Passwords do not match"
    }
}
```

#### Login Endpoint
**Endpoint**: `POST /api/login/`
```python
def login(request):
    # 1. Fetch user by username
    # 2. Verify password using check_password()
    # 3. Set session['user_id'] for future requests
    # 4. Return user role and username
```

**Request**:
```json
{
    "username": "john_doe",
    "password": "SecurePassword123"
}
```

**Response**:
```json
{
    "status": "success",
    "username": "john_doe",
    "role": "student"
}
```

**Error Response**:
```json
{
    "status": "error",
    "message": "Invalid credentials"
}
```

#### Logout Endpoint
**Endpoint**: `POST /api/logout/`
```python
def logout(request):
    request.session.flush()  # Clear all session data
    return JsonResponse({'status': 'success', 'message': 'Logged out successfully'})
```

---

### Batch Management (`api/views.py`)

#### Create Batch (Faculty Only)
**Endpoint**: `POST /api/create-batch/`

**Validation**:
- User must exist and have role='faculty'
- batch_name, batch_code, username are required
- batch_code must be unique
- similarity_threshold must be 0.0 to 1.0

**Request**:
```json
{
    "username": "prof_smith",
    "batch_name": "CS101 Spring 2024",
    "batch_code": "CS101_SPR24",
    "similarity_threshold": 0.75
}
```

**Response**:
```json
{
    "status": "success",
    "message": "Batch created successfully",
    "batch": {
        "id": 1,
        "batch_name": "CS101 Spring 2024",
        "batch_code": "CS101_SPR24"
    }
}
```

---

#### Get Batches (Faculty)
**Endpoint**: `POST /api/get-batches/`

Returns all batches created by the faculty member.

**Request**:
```json
{
    "username": "prof_smith"
}
```

**Response**:
```json
{
    "status": "success",
    "batches": [
        {
            "id": 1,
            "batch_name": "CS101 Spring 2024",
            "batch_code": "CS101_SPR24",
            "member_count": 45,
            "similarity_threshold": 0.75
        },
        {
            "id": 2,
            "batch_name": "CS201 Spring 2024",
            "batch_code": "CS201_SPR24",
            "member_count": 32,
            "similarity_threshold": 0.80
        }
    ]
}
```

---

#### Update Similarity Threshold (Faculty)
**Endpoint**: `POST /api/set-batch-threshold/`

**Request**:
```json
{
    "username": "prof_smith",
    "batch_id": 1,
    "similarity_threshold": 0.70
}
```

**Response**:
```json
{
    "status": "success",
    "message": "Batch similarity threshold updated",
    "batch": {
        "id": 1,
        "batch_name": "CS101 Spring 2024",
        "batch_code": "CS101_SPR24",
        "similarity_threshold": 0.70
    }
}
```

---

#### Join Batch (Student)
**Endpoint**: `POST /api/join-batch/`

**Validation**:
- User must exist and have role='student'
- batch_code must exist
- Student cannot join the same batch twice

**Request**:
```json
{
    "username": "john_doe",
    "batch_code": "CS101_SPR24"
}
```

**Response**:
```json
{
    "status": "success",
    "message": "Joined batch \"CS101 Spring 2024\" successfully",
    "batch": {
        "id": 1,
        "batch_name": "CS101 Spring 2024",
        "batch_code": "CS101_SPR24"
    }
}
```

---

#### Get Student's Batches
**Endpoint**: `POST /api/get-student-batches/`

Returns all batches the student has joined.

**Request**:
```json
{
    "username": "john_doe"
}
```

**Response**:
```json
{
    "status": "success",
    "batches": [
        {
            "id": 1,
            "batch_name": "CS101 Spring 2024",
            "batch_code": "CS101_SPR24"
        },
        {
            "id": 2,
            "batch_name": "CS201 Spring 2024",
            "batch_code": "CS201_SPR24"
        }
    ]
}
```

---

### Document Management (`api/views.py`)

#### Upload Document (Student)
**Endpoint**: `POST /api/upload-document/` (Multipart form data)

**Validation**:
- User must exist and be a student
- Student must be a member of the target batch
- File must be provided
- File must be PDF, DOCX, or TXT
- File size validated

**Process**:
1. Store uploaded file in `media/documents/`
2. Extract text based on file type
3. Compare extracted text against all other documents in the same batch
4. Calculate similarity score (highest match)
5. Determine status based on batch threshold
6. Store document record in database

**Request**:
```
POST /api/upload-document/
Content-Type: multipart/form-data

username: john_doe
batch_id: 1
file: <binary file content>
```

**Response on Success** (similarity < threshold):
```json
{
    "status": "success",
    "message": "Document accepted! Similarity: 0.45",
    "document": {
        "id": 5,
        "file_name": "essay.pdf",
        "similarity_score": 0.45,
        "status": "accepted",
        "uploaded_at": "2024-04-14T10:30:00Z"
    }
}
```

**Response on Rejection** (similarity >= threshold):
```json
{
    "status": "error",
    "message": "Document rejected! Similarity: 0.82 (threshold: 0.75)",
    "document": {
        "id": 5,
        "file_name": "essay.pdf",
        "similarity_score": 0.82,
        "status": "rejected",
        "uploaded_at": "2024-04-14T10:30:00Z"
    }
}
```

---

#### Get Batch Documents (Faculty)
**Endpoint**: `POST /api/get-batch-documents/`

Returns all documents submitted by students in a specific batch.

**Request**:
```json
{
    "username": "prof_smith",
    "batch_id": 1
}
```

**Response**:
```json
{
    "status": "success",
    "documents": [
        {
            "id": 1,
            "file_name": "essay1.pdf",
            "student_username": "john_doe",
            "similarity_score": 0.45,
            "status": "accepted",
            "uploaded_at": "2024-04-14T10:30:00Z"
        },
        {
            "id": 2,
            "file_name": "essay2.pdf",
            "student_username": "jane_smith",
            "similarity_score": 0.82,
            "status": "rejected",
            "uploaded_at": "2024-04-14T10:35:00Z"
        }
    ]
}
```

---

#### Get Batch Details (Faculty)
**Endpoint**: `POST /api/get-batch-details/`

Returns complete information about a batch including students and documents.

**Request**:
```json
{
    "username": "prof_smith",
    "batch_id": 1
}
```

**Response**:
```json
{
    "status": "success",
    "batch": {
        "id": 1,
        "batch_name": "CS101 Spring 2024",
        "batch_code": "CS101_SPR24",
        "similarity_threshold": 0.75,
        "member_count": 45,
        "created_at": "2024-04-10T08:00:00Z"
    },
    "students": [
        {
            "username": "john_doe",
            "joined_at": "2024-04-11T09:00:00Z",
            "documents": [
                {
                    "id": 1,
                    "file_name": "essay1.pdf",
                    "similarity_score": 0.45,
                    "status": "accepted",
                    "uploaded_at": "2024-04-14T10:30:00Z"
                }
            ]
        },
        {
            "username": "jane_smith",
            "joined_at": "2024-04-11T09:15:00Z",
            "documents": []
        }
    ]
}
```

---

#### Download Document (Faculty)
**Endpoint**: `POST /api/download-document/`

Allows faculty to download documents submitted by students.

**Request**:
```json
{
    "username": "prof_smith",
    "document_id": 1
}
```

**Response**: File download (binary content)

---

### NLP Engine (`api/nlp_engine.py`)

The NLP engine implements a sophisticated multi-algorithm similarity detection system.

#### Algorithms

**1. TF-IDF (Term Frequency - Inverse Document Frequency)**
```python
def tfidf_similarity(s1, s2):
    # Statistical measure of word importance
    # Uses scikit-learn's TfidfVectorizer
    # Returns: float (0.0 to 1.0)
    # Dependency: scikit-learn (optional)
    # Fallback: Returns 0.0 if not installed
```

**Strengths**:
- Captures statistical importance of terms
- Effective for detecting copied content
- Fast computation

**Limitations**:
- Doesn't understand semantic meaning
- Sensitive to synonym substitution

---

**2. N-gram Based Matching**
```python
def ngram_similarity(s1, s2, n=3):
    # Sequence-based matching (3-word chunks)
    # No external dependencies
    # Returns: float (0.0 to 1.0)
    # Always available (Jaccard similarity of n-gram sets)
```

**Strengths**:
- No dependencies required
- Captures phrase-level similarity
- Detects paraphrasing attempts
- Fast and reliable

**Limitations**:
- Limited context understanding
- May miss semantic plagiarism

---

**3. AI/Sentence Transformers**
```python
def ai_similarity(s1, s2):
    # Deep learning sentence embeddings
    # Model: "all-MiniLM-L6-v2" (sentence-transformers)
    # Returns: float (0.0 to 1.0)
    # Dependency: sentence-transformers (optional)
    # Fallback: Returns 0.0 if not installed
```

**Strengths**:
- Understands semantic meaning
- Detects paraphrased content
- Context-aware comparison
- Captures synonym usage

**Limitations**:
- Requires ML library installation
- Slower than statistical methods

---

#### Text Preprocessing
```python
def clean_text(text):
    # 1. Convert to lowercase
    # 2. Remove punctuation
    # 3. Remove English stop words (the, a, an, etc.)
    # 4. Return cleaned text
```

---

#### Composite Similarity Calculation
```python
def compare_docs(doc1, doc2):
    # 1. Clean both documents
    # 2. Split into sentences
    # 3. For each sentence in doc1:
    #    - Find best matching sentence in doc2
    #    - Calculate similarity using available algorithms:
    #      * TF-IDF weight: 55% (if sklearn available)
    #      * N-gram weight: 25% or 30%
    #      * AI weight: 20% (if transformers available)
    #    - Use only available methods if dependencies missing
    # 4. Return average of best matches
```

**Algorithm Weight Distribution**:
- **Both sklearn & transformers available**: TF-IDF 55% + N-gram 25% + AI 20%
- **Only sklearn available**: TF-IDF 70% + N-gram 30%
- **Neither available**: N-gram 100% (graceful degradation)

---

#### Example Similarity Calculation
```python
# Input
doc1 = "The quick brown fox jumps over the lazy dog."
doc2 = "A swift auburn fox leaps above a sluggish dog."

# Process
# Cleaned: "quick brown fox jumps lazy dog", "swift auburn fox leaps sluggish dog"
# TF-IDF: 0.65
# N-gram: 0.42
# AI: 0.78
# Final score: (0.65 * 0.55) + (0.42 * 0.25) + (0.78 * 0.20) = 0.6260
```

---

### PDF/Document Extractor (`api/pdf_extractor.py`)

#### Supported Formats
1. **PDF (.pdf)**
   - Uses `PyPDF2` library
   - Extracts text from all pages
   - Combines text with newlines between pages

2. **DOCX (.docx)**
   - Uses `python-docx` library
   - Extracts text from all paragraphs
   - Preserves paragraph structure

3. **TXT (.txt)**
   - Native Python file reading
   - UTF-8 encoding support
   - Direct text retrieval

#### Extraction Function
```python
def extract_text(file_path):
    # 1. Detect file extension
    # 2. Call appropriate extraction function
    # 3. Return extracted text (or empty string on error)
    # 4. Error handling: Returns "" if extraction fails
```

---

## 📱 FRONTEND DETAILS

### Project Structure
```
frontend/
├── lib/
│   ├── main.dart                  # App entry point and Login screen
│   ├── api_service.dart           # API wrapper and HTTP client
│   ├── api_host.dart              # API URL configuration
│   ├── api_host_web.dart          # Web-specific API host
│   ├── api_host_io.dart           # iOS/Android-specific API host
│   ├── dashboard_page.dart        # Faculty & Student dashboards
│   ├── batch_detail_page.dart     # Batch details and monitoring
│   ├── create_account_page.dart   # Registration screen
│   ├── web_upload_html.dart       # Web file upload implementation
│   └── web_upload_stub.dart       # Stub for non-web platforms
├── android/                       # Android-specific code
├── ios/                          # iOS-specific code
├── web/                          # Web-specific code
├── windows/                      # Windows desktop code
├── macos/                        # macOS desktop code
├── linux/                        # Linux desktop code
├── test/                         # Widget tests
├── pubspec.yaml                  # Flutter dependencies
└── analysis_options.yaml         # Lint rules
```

### Flutter Configuration (`pubspec.yaml`)

**App Information**:
- Name: `origence`
- Version: `1.0.0+1`
- SDK Version: `^3.10.8`
- Publish: `none` (private package)

**Key Dependencies**:
- `flutter` - Flutter framework
- `cupertino_icons: ^1.0.8` - iOS-style icons
- `http: ^1.2.0` - HTTP client for API calls
- `shared_preferences: ^2.5.4` - Local persistent storage
- `file_selector: ^1.1.0` - Native file picker

---

### Navigation Architecture

```
LoginScreen (initial route)
    ├─ (login success, role=faculty)
    │  └→ FacultyDashboardPage
    │      ├─ (click create batch)
    │      │  └→ CreateBatchDialog
    │      │      └→ (back to) FacultyDashboardPage
    │      │
    │      └─ (click batch tile)
    │         └→ BatchDetailPage
    │             ├─ View students
    │             ├─ View documents
    │             ├─ Update threshold
    │             └─ (back to) FacultyDashboardPage
    │
    ├─ (login success, role=student)
    │  └→ StudentDashboardPage
    │      ├─ (click join batch)
    │      │  └→ JoinBatchDialog
    │      │      └→ (back to) StudentDashboardPage
    │      │
    │      └─ (click batch tile)
    │         └→ BatchDetailPage
    │             ├─ Upload document
    │             ├─ View document status
    │             └─ (back to) StudentDashboardPage
    │
    ├─ (create account button)
    │  └→ CreateAccountPage
    │      └─ (back to) LoginScreen
    │
    └─ (logout from any dashboard)
       └→ LoginScreen
```

---

### Main Entry Point (`lib/main.dart`)

#### MyApp Class
```dart
class MyApp extends StatelessWidget {
    // Root widget
    // Theme: Color scheme with indigo seed color
    // Material Design 3 theme
    // Initial route: LoginScreen
}
```

#### LoginScreen Widget
```dart
class LoginScreen extends StatefulWidget {
    // Form fields: username, password
    // Features:
    //   - Username validation (required)
    //   - Password visibility toggle
    //   - Error message display
    //   - Loading state during login
    //   - Link to create account page
    //   - Modern dark theme (Color 0xFF0F0F1A)
    
    // Login flow:
    // 1. Validate form
    // 2. Call ApiService.login()
    // 3. If success:
    //    - Route to FacultyDashboardPage or StudentDashboardPage
    //    - Clear all previous routes (pushAndRemoveUntil)
    // 4. If error: Display error message
}
```

---

### API Service (`lib/api_service.dart`)

**Purpose**: Centralized HTTP client for all API communication

#### Base Configuration
```dart
class ApiService {
    static String get _baseUrl => getApiBaseUrl();
    
    static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
    };
    
    // All methods are static for ease of use
    // Methods automatically handle:
    //   - JSON encoding/decoding
    //   - Error handling
    //   - Network retry logic (implicit via http package)
    //   - Debug logging via debugPrint()
}
```

#### Authentication Methods

**register()**
```dart
static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String role,  // 'faculty' or 'student'
}) async
```

**login()**
```dart
static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
}) async
// Saves credentials to SharedPreferences on success
```

**logout()**
```dart
static Future<Map<String, dynamic>> logout() async
// Clears SharedPreferences
```

#### Faculty Methods

**createBatch()**
```dart
static Future<Map<String, dynamic>> createBatch({
    required String username,
    required String batchName,
    required String batchCode,
    double? similarityThreshold,
}) async
```

**getBatches()**
```dart
static Future<Map<String, dynamic>> getBatches({
    required String username,
}) async
// Returns list of batches created by faculty
```

**setBatchThreshold()**
```dart
static Future<Map<String, dynamic>> setBatchThreshold({
    required String username,
    required int batchId,
    required double similarityThreshold,
}) async
```

**getBatchDetails()**
```dart
static Future<Map<String, dynamic>> getBatchDetails({
    required String username,
    required int batchId,
}) async
// Returns students, documents, and batch info
```

**downloadDocument()**
```dart
static Future<Uint8List?> downloadDocument({
    required String username,
    required int documentId,
}) async
// Downloads document as binary data
```

#### Student Methods

**joinBatch()**
```dart
static Future<Map<String, dynamic>> joinBatch({
    required String username,
    required String batchCode,
}) async
```

**getStudentBatches()**
```dart
static Future<Map<String, dynamic>> getStudentBatches({
    required String username,
}) async
// Returns list of batches student has joined
```

**uploadDocument()**
```dart
static Future<Map<String, dynamic>> uploadDocument({
    required String username,
    required int batchId,
    required String fileName,
    required Uint8List fileBytes,
}) async
// Multipart form upload
// Handles platform differences (web vs mobile)
// Returns: document status, similarity score, acceptance/rejection
```

---

### Dashboard Pages (`lib/dashboard_page.dart`)

#### FacultyDashboardPage
**Features**:
1. **Header Section**
   - Welcome message with faculty name
   - Logout button
   - Refresh icon

2. **Create Batch Dialog**
   - Text field: Batch Name (e.g., "CS101 Spring 2024")
   - Text field: Batch Code (e.g., "CS101_SPR24") - must be unique
   - Text field: Similarity Threshold (0.0 - 1.0, default 0.80)
   - Validation: All fields required, threshold in valid range

3. **Batches List**
   - Displays all created batches
   - Shows: Batch name, code, member count, threshold
   - Tap to view batch details
   - Pull-to-refresh functionality

4. **Empty State**
   - "No batches created yet" message when list empty
   - Prompts to create first batch

#### StudentDashboardPage
**Features**:
1. **Header Section**
   - Welcome message with student name
   - Logout button
   - Refresh icon

2. **Join Batch Dialog**
   - Text field: Batch Code (e.g., "CS101_SPR24")
   - Validation: Code must exist and student not already joined
   - Success message: "Joined batch successfully"

3. **Batches List**
   - Displays all joined batches
   - Shows: Batch name, code
   - Tap to view batch and upload documents
   - Pull-to-refresh functionality

4. **Empty State**
   - "No batches joined yet" message
   - Prompts to join first batch using code

---

### Batch Detail Page (`lib/batch_detail_page.dart`)

**Faculty View**:
1. **Batch Information Section**
   - Batch name and code
   - Current similarity threshold
   - Created date
   - Edit threshold button

2. **Students Tab**
   - List of all students in batch
   - Join date for each student
   - Document count per student

3. **Documents Tab**
   - All documents uploaded in batch
   - Shows: Student name, filename, similarity score, status
   - Download button for each document
   - Status indicator: ✓ Accepted / ✗ Rejected

4. **Refresh Button**
   - Pull-to-refresh to update data
   - Loading indicator during refresh

**Student View**:
1. **Batch Information Section**
   - Batch name and code
   - Current similarity threshold
   - Submission requirements

2. **Documents Section**
   - List of uploaded documents
   - Shows: Filename, similarity score, status, upload date
   - Status: ✓ Accepted or ✗ Rejected
   - Re-upload button for rejected documents (if supported)

3. **Upload Section**
   - File picker button
   - Supported formats: PDF, DOCX, TXT
   - Upload progress indicator
   - Success/error message display

---

### Account Creation (`lib/create_account_page.dart`)

**Form Fields**:
1. **Username**
   - Text input, required
   - Validation: Must be unique

2. **Password**
   - Password input with visibility toggle
   - Required, minimum length

3. **Confirm Password**
   - Must match password field
   - Validation on blur

4. **Role Selection**
   - Radio buttons or dropdown
   - Options: Faculty, Student
   - Default: Student

5. **Submit Button**
   - Creates account and navigates back to login
   - Shows loading spinner during registration

6. **Error Display**
   - Shows validation errors from backend
   - Displays user-friendly error messages

---

### API Host Configuration

#### `lib/api_host.dart` (Platform Dispatcher)
```dart
String getApiBaseUrl() {
    if (kIsWeb) {
        return getWebApiBaseUrl();
    } else {
        return getIOApiBaseUrl();
    }
}
// Automatically selects web or mobile/desktop API URL
```

#### `lib/api_host_web.dart` (Web Configuration)
```dart
const String _developmentUrl = 'http://localhost:8000/api/';
const String _productionUrl = 'https://origence.up.railway.app/api/';

String getWebApiBaseUrl() {
    // Development mode: localhost:8000
    // Production mode: Railway hosted URL
}
```

#### `lib/api_host_io.dart` (Mobile/Desktop Configuration)
```dart
const String _developmentUrl = 'http://10.0.2.2:8000/api/';
const String _productionUrl = 'https://origence.up.railway.app/api/';

String getIOApiBaseUrl() {
    // Android emulator: 10.0.2.2 (special alias for host)
    // Physical device: <your-machine-ip>:8000
    // Production: Railway URL
}
```

---

## 🔗 API ENDPOINTS

### Authentication Endpoints

| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| `POST` | `/api/register/` | All | User registration |
| `POST` | `/api/login/` | All | User login |
| `POST` | `/api/logout/` | All | User logout |

### Batch Management Endpoints

| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| `POST` | `/api/create-batch/` | Faculty | Create new batch |
| `POST` | `/api/get-batches/` | Faculty | Get created batches |
| `POST` | `/api/set-batch-threshold/` | Faculty | Update similarity threshold |
| `POST` | `/api/join-batch/` | Student | Join batch with code |
| `POST` | `/api/get-student-batches/` | Student | Get joined batches |
| `POST` | `/api/get-batch-details/` | Faculty | Get detailed batch info |

### Document Endpoints

| Method | Endpoint | Role | Description |
|--------|----------|------|-------------|
| `POST` | `/api/upload-document/` | Student | Upload document |
| `POST` | `/api/get-batch-documents/` | Faculty | Get all batch documents |
| `POST` | `/api/download-document/` | Faculty | Download document |

---

## 🚀 SETUP INSTRUCTIONS

### Prerequisites
- **Backend**: Python 3.11, pip
- **Frontend**: Flutter 3.10.8, Dart 3.10.8
- **Database**: SQLite (development) or PostgreSQL (production)
- **Git**: For version control

---

### Backend Setup

#### 1. Clone Repository
```bash
git clone <repository-url>
cd origence/backend
```

#### 2. Create Virtual Environment
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

#### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

#### 4. Create Environment Variables
Create `.env` file in `backend/` directory:
```env
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=  # Leave empty for SQLite
```

#### 5. Run Database Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

#### 6. Create Superuser (Optional - for admin panel)
```bash
python manage.py createsuperuser
```

#### 7. Start Development Server
```bash
python manage.py runserver
```

**Access**:
- API: http://localhost:8000/api/
- Admin: http://localhost:8000/admin/

---

### Frontend Setup

#### 1. Clone Repository
```bash
git clone <repository-url>
cd origence/frontend
```

#### 2. Install Flutter Dependencies
```bash
flutter pub get
```

#### 3. Update API Host (if needed)
Edit `lib/api_host_web.dart` and `lib/api_host_io.dart`:
```dart
const String _developmentUrl = 'http://your-backend-ip:8000/api/';
```

#### 4. Run Application

**Web**:
```bash
flutter run -d chrome
```

**Android**:
```bash
flutter run -d <device-id>
```

**iOS**:
```bash
flutter run -d <device-id>
```

**Windows**:
```bash
flutter run -d windows
```

#### 5. Login Credentials
Create test accounts via the registration page in the app.

---

## 🌐 DEPLOYMENT

### Backend Deployment (Railway)

#### Prerequisites
- Railway account (railway.app)
- GitHub repository

#### Deployment Steps

1. **Push to GitHub**
```bash
git add -A
git commit -m "Prepare for Railway deployment"
git push origin main
```

2. **Connect to Railway**
   - Create new project on Railway
   - Connect GitHub repository
   - Select `backend/` as root directory

3. **Add PostgreSQL Plugin**
   - Click "+ Add" button
   - Select PostgreSQL plugin
   - Database automatically configured via `DATABASE_URL` env var

4. **Set Environment Variables**
   - `SECRET_KEY`: Generate a secure key
   - `DEBUG`: Set to `False`
   - `ALLOWED_HOSTS`: `origence.up.railway.app,.up.railway.app`
   - `DATABASE_URL`: Automatically set by PostgreSQL plugin

5. **Deploy**
   - Railway auto-deploys on push to main branch
   - Monitor logs for any errors

#### Procfile
```
web: gunicorn backend.wsgi:application --bind 0.0.0.0:$PORT
release: python manage.py migrate && python manage.py collectstatic --noinput
```

---

### Frontend Deployment

#### Web Deployment (Firebase Hosting, Vercel, or Railway)

**Build for Web**:
```bash
flutter build web --release
```

**Deploy to Firebase Hosting**:
```bash
firebase deploy
```

**Update API URL in Production**:
Edit `lib/api_host_web.dart`:
```dart
const String _productionUrl = 'https://your-railway-url.app/api/';
```

#### Mobile Deployment (Google Play, App Store)

**Android**:
1. Generate signing key
2. Build APK/AAB
3. Upload to Google Play Console

**iOS**:
1. Set up Apple Developer account
2. Build and sign app
3. Upload to App Store

---

## ✨ KEY FEATURES

### Faculty Features
1. **Batch Creation**
   - Create multiple batches with unique codes
   - Set institution-specific similarity thresholds
   - Share batch codes with students

2. **Batch Management**
   - View all created batches
   - Update similarity thresholds dynamically
   - Monitor student enrollment
   - View submission progress

3. **Document Monitoring**
   - View all documents in batch
   - See student names and submission times
   - View plagiarism scores
   - Download submitted documents
   - Accept/reject decisions

4. **Student Tracking**
   - See which students have joined
   - Track who uploaded/didn't upload
   - View upload timestamps

### Student Features
1. **Batch Enrollment**
   - Join batches using unique batch codes
   - View all joined batches
   - See batch requirements (similarity threshold)

2. **Document Submission**
   - Upload documents (PDF, DOCX, TXT)
   - Get instant plagiarism feedback
   - Know if document is accepted or rejected
   - See similarity score

3. **Submission Tracking**
   - View uploaded documents
   - See plagiarism scores
   - Track acceptance/rejection status
   - Upload timestamps

### System Features
1. **Multi-Algorithm Plagiarism Detection**
   - TF-IDF statistical analysis
   - N-gram sequence matching
   - AI-based semantic similarity (optional)
   - Hybrid scoring for accuracy

2. **Batch Isolation**
   - Documents only compared within their batch
   - Prevents cross-batch contamination
   - Maintains data privacy

3. **Multiple File Format Support**
   - PDF documents
   - DOCX (Word documents)
   - TXT (Plain text)
   - Automatic text extraction

4. **Role-Based Access Control**
   - Faculty: Can create batches, manage thresholds, monitor documents
   - Student: Can join batches, upload documents, view scores

5. **Cross-Platform Support**
   - Web (Chrome, Firefox, Safari)
   - Mobile (Android, iOS)
   - Desktop (Windows, macOS, Linux)

---

## 🔄 HOW IT WORKS

### Complete Workflow

#### Step 1: Faculty Setup
```
1. Faculty registers with role='faculty'
2. Faculty logs in
3. Faculty creates batch with:
   - Batch name (e.g., "CS101 Spring 2024")
   - Batch code (e.g., "CS101_SPR24")
   - Similarity threshold (e.g., 0.75)
4. Faculty shares batch code with students
```

#### Step 2: Student Enrollment
```
1. Student registers with role='student'
2. Student logs in
3. Student joins batch using batch code
4. Student appears in faculty's batch member list
```

#### Step 3: Document Upload & Plagiarism Check
```
1. Student selects document from device
2. Document uploaded to server via HTTP multipart form
3. Backend receives upload:
   - Validates student is batch member
   - Extracts text (PDF → text, DOCX → text, etc.)
   - Stores extracted text in database
4. Similarity Calculation:
   - NEW document compared with all existing documents in batch
   - For each existing document:
     a) Clean text (lowercase, remove punctuation, stop words)
     b) Split into sentences
     c) Compare using three algorithms:
        - TF-IDF similarity
        - N-gram similarity
        - AI sentence transformer similarity
     d) Weight and combine scores
   - Find HIGHEST similarity score
   - Record this as document's similarity score
5. Decision Making:
   - If similarity < threshold → ACCEPTED (✓)
   - If similarity >= threshold → REJECTED (✗)
6. Database Storage:
   - Document record created with:
     * File name, user, batch
     * Extracted text
     * Similarity score
     * Status (accepted/rejected)
     * Upload timestamp
7. Response to Student:
   - If accepted: "Document accepted! Similarity: 0.45"
   - If rejected: "Document rejected! Similarity: 0.82"
```

#### Step 4: Faculty Monitoring
```
1. Faculty views batch details
2. Faculty sees all students and documents
3. Faculty can:
   - Download any document
   - See similarity scores
   - See submission status
   - Adjust threshold if needed
   - Re-check with new threshold applied to future uploads
```

#### Step 5: Document Comparison Deep Dive
```
Example: Comparing two documents

Document A: "The quick brown fox jumps over the lazy dog."
Document B: "A swift auburn fox leaps above a sluggish dog."

Process:
1. Extract text from both
2. Clean text:
   A: "quick brown fox jump lazy dog"
   B: "swift auburn fox leap sluggish dog"
3. Split sentences (same sentence here)
4. Calculate TF-IDF:
   - Vector A: {quick: 0.4, brown: 0.3, fox: 0.5, ...}
   - Vector B: {swift: 0.4, auburn: 0.3, fox: 0.5, ...}
   - Cosine similarity: 0.65
5. Calculate N-gram (3-word sequences):
   - A n-grams: {"quick brown fox", "brown fox jump", ...}
   - B n-grams: {"swift auburn fox", "auburn fox leap", ...}
   - Jaccard similarity: 0.42
6. Calculate AI Similarity:
   - Sentence A embedding: [...0.234, 0.891, -0.456...]
   - Sentence B embedding: [...0.267, 0.856, -0.523...]
   - Cosine similarity: 0.78
7. Weighted combination:
   - (0.65 × 0.55) + (0.42 × 0.25) + (0.78 × 0.20)
   - = 0.3575 + 0.105 + 0.156
   - = 0.6185 (approximately 62% similarity)
8. Compare with threshold (e.g., 0.75):
   - 0.6185 < 0.75 → ACCEPTED
```

---

## 📁 PROJECT STRUCTURE

```
origence/
│
├── 📄 README.md                          # Project overview
├── 📄 PROJECT_DOCUMENTATION.md           # This file
├── 📄 DEPLOYMENT_SUMMARY.md              # Deployment guide
├── 📄 DEPLOYMENT_CHECKLIST.md            # Pre-deployment checklist
├── 📄 RAILWAY_DEPLOYMENT_GUIDE.md        # Railway-specific guide
├── 📄 DELIVERY_SUMMARY.txt               # Project summary
├── 📄 Procfile                           # Web Procfile (root)
├── 📄 Dockerfile                         # Docker configuration
├── 📄 runtime.txt                        # Runtime specification
│
├── backend/                              # Django Backend (Python)
│   ├── 📄 manage.py                      # Django CLI
│   ├── 📄 requirements.txt                # Python dependencies
│   ├── 📄 runtime.txt                    # Python version (3.11.0)
│   ├── 📄 Procfile                       # Gunicorn command
│   ├── 📄 README.md                      # Backend docs
│   ├── 📄 db.sqlite3                     # SQLite database (dev)
│   ├── 📄 db.sqbpro                      # SQLiteStudio project
│   ├── 📂 config/                        # Django configuration
│   │   ├── settings.py                   # Django settings
│   │   ├── urls.py                       # URL routing
│   │   ├── wsgi.py                       # WSGI app
│   │   └── asgi.py                       # ASGI app
│   ├── 📂 api/                           # Plagiarism API app
│   │   ├── models.py                     # Batch, Document models
│   │   ├── views.py                      # API views
│   │   ├── urls.py                       # API routes
│   │   ├── nlp_engine.py                 # Similarity algorithms
│   │   ├── pdf_extractor.py              # Text extraction
│   │   ├── admin.py                      # Django admin
│   │   ├── apps.py                       # App config
│   │   ├── tests.py                      # Unit tests
│   │   └── 📂 migrations/                # Database migrations
│   ├── 📂 auth_api/                      # Authentication app
│   │   ├── models.py                     # User model
│   │   ├── views.py                      # Auth views
│   │   ├── urls.py                       # Auth routes
│   │   ├── admin.py                      # Django admin
│   │   ├── apps.py                       # App config
│   │   └── 📂 migrations/                # Database migrations
│   ├── 📂 core/                          # Core app
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── admin.py
│   │   ├── apps.py
│   │   ├── tests.py
│   │   └── 📂 migrations/
│   └── 📂 media/                         # Uploaded files
│       └── documents/                    # Uploaded documents
│
├── frontend/                             # Flutter Frontend (Dart)
│   ├── 📄 pubspec.yaml                   # Flutter dependencies
│   ├── 📄 analysis_options.yaml          # Lint configuration
│   ├── 📂 lib/                           # Dart source code
│   │   ├── main.dart                     # App entry & login
│   │   ├── api_service.dart              # API wrapper
│   │   ├── api_host.dart                 # Platform dispatcher
│   │   ├── api_host_web.dart             # Web API config
│   │   ├── api_host_io.dart              # Mobile/Desktop config
│   │   ├── dashboard_page.dart           # Faculty/Student dashboards
│   │   ├── batch_detail_page.dart        # Batch details view
│   │   ├── create_account_page.dart      # Registration screen
│   │   ├── web_upload_html.dart          # Web file upload
│   │   └── web_upload_stub.dart          # Non-web upload stub
│   ├── 📂 android/                       # Android project
│   ├── 📂 ios/                           # iOS project
│   ├── 📂 web/                           # Web project
│   ├── 📂 windows/                       # Windows project
│   ├── 📂 macos/                         # macOS project
│   ├── 📂 linux/                         # Linux project
│   ├── 📂 test/                          # Widget tests
│   └── 📂 build/                         # Build output
│
└── docs/                                 # Documentation
```

---

## 🧪 RUNNING & TESTING

### Running Backend

#### Development Mode
```bash
cd backend
python manage.py runserver
```
- Accessible at: http://localhost:8000
- Admin panel: http://localhost:8000/admin
- API: http://localhost:8000/api/

#### Database Management
```bash
# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Reset database
python manage.py migrate zero api
python manage.py migrate
```

#### Create Test Data
```bash
# Start interactive shell
python manage.py shell

# Create faculty
from auth_api.models import User
User.objects.create(username='prof_smith', password='hashed_pwd', role='faculty')

# Create student
User.objects.create(username='john_doe', password='hashed_pwd', role='student')
```

---

### Running Frontend

#### Web
```bash
cd frontend
flutter run -d chrome
```

#### Mobile (Requires connected device or emulator)
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

#### Test API Connectivity
The app will attempt to connect to the backend based on:
- **Web**: Uses localhost:8000 or Railway URL
- **Mobile/Desktop**: Uses 10.0.2.2:8000 (Android emulator) or machine IP

---

### Testing Workflow

#### Test Account 1 (Faculty)
```
Username: prof_smith
Password: password123
Role: faculty
```

1. Login with faculty account
2. Create batch: "CS101 Spring 2024" with code "CS101_SPR24", threshold 0.75
3. Note the batch code

#### Test Account 2 (Student)
```
Username: john_doe
Password: password123
Role: student
```

1. Login with student account
2. Join batch using code "CS101_SPR24"
3. Select and upload test PDF document
4. View similarity score and acceptance status

#### Test Account 3 (Another Student)
```
Username: jane_smith
Password: password123
Role: student
```

1. Login with student account
2. Join batch using code "CS101_SPR24"
3. Upload slightly different document
4. Verify different similarity score

#### Faculty Monitoring
1. Login with faculty account
2. View batch details
3. See all students and their documents
4. Check similarity scores
5. Download a document

---

## 🔐 Security Considerations

### Current Implementation
- **Password Hashing**: Django's `make_password()` (PBKDF2 by default)
- **CSRF Protection**: Django CSRF middleware enabled
- **CORS**: Currently open (`CORS_ALLOW_ALL_ORIGINS = True`)
- **Sessions**: Django session framework
- **Database**: No hardcoded credentials

### Production Recommendations
1. **CORS Configuration**
   - Restrict to specific frontend domain
   - Remove `CORS_ALLOW_ALL_ORIGINS = True`
   - Use: `CORS_ALLOWED_ORIGINS = ['https://yourdomain.com']`

2. **SSL/TLS**
   - Enable HTTPS on production
   - Use secure session cookies
   - `SESSION_COOKIE_SECURE = True` in production

3. **Database**
   - Use PostgreSQL instead of SQLite
   - Regular backups
   - Strong database passwords

4. **API Rate Limiting**
   - Implement rate limiting on endpoints
   - Use `django-ratelimit` or similar

5. **Input Validation**
   - Validate all file uploads
   - Check file types and sizes
   - Prevent path traversal

6. **Secrets Management**
   - Use environment variables
   - Never commit `.env` to git
   - Rotate SECRET_KEY regularly

---

## 📚 ADDITIONAL RESOURCES

### Documentation Files
- `README.md` - Quick start guide
- `DEPLOYMENT_SUMMARY.md` - Deployment overview
- `RAILWAY_DEPLOYMENT_GUIDE.md` - Railway-specific instructions
- `DEPLOYMENT_CHECKLIST.md` - Pre-deployment verification

### Official Documentation
- [Django Documentation](https://docs.djangoproject.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Railway Documentation](https://docs.railway.app/)
- [PyPDF2 Documentation](https://py-pdf.github.io/)

### Libraries Used
- [scikit-learn](https://scikit-learn.org/) - ML algorithms
- [sentence-transformers](https://www.sbert.net/) - AI embeddings
- [django-cors-headers](https://github.com/adamchainz/django-cors-headers) - CORS support
- [WhiteNoise](https://whitenoise.readthedocs.io/) - Static file serving

---

## 📝 VERSION INFORMATION

- **Project Version**: 1.0.0
- **Python Version**: 3.11.0
- **Flutter/Dart Version**: 3.10.8
- **Django Version**: 5.2.13
- **Last Updated**: April 24, 2026

---

## 🎓 CONCLUSION

Origence is a comprehensive plagiarism detection system built with modern web technologies. It provides faculty with powerful tools to manage batches and monitor document submissions while giving students immediate feedback on their work's originality. The multi-algorithm approach ensures accurate plagiarism detection across various document formats, while the batch-based architecture maintains data privacy and prevents cross-contamination of plagiarism scores.

For questions or issues, refer to the deployment guides or contact the development team.

---

**Document Generated**: April 24, 2026
**Status**: Production Ready
**Deployment Status**: Railway (Production), Local Development (SQLite)
