from django.http import JsonResponse, FileResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
import json
import os

from auth_api.models import User
from .models import Batch, Document, StudentBatchMapping
from .pdf_extractor import extract_text
from .nlp_engine import compare_docs


# ---------------------------------------------------------------------------
# Helper: resolve user from session or posted username field
# ---------------------------------------------------------------------------
def _get_user(request):
    user_id = request.session.get('user_id')
    if user_id:
        try:
            return User.objects.get(id=user_id)
        except User.DoesNotExist:
            pass
    posted_username = request.POST.get('username') or (
        json.loads(request.body).get('username') if request.content_type == 'application/json' else None
    )
    if posted_username:
        try:
            return User.objects.get(username=posted_username)
        except User.DoesNotExist:
            pass
    return None


# ---------------------------------------------------------------------------
# FACULTY: Create Batch
# ---------------------------------------------------------------------------
@csrf_exempt
def create_batch(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

    try:
        data = json.loads(request.body)
    except (json.JSONDecodeError, Exception):
        return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)

    username = data.get('username', '').strip()
    batch_name = data.get('batch_name', '').strip()
    batch_code = data.get('batch_code', '').strip()

    if not username or not batch_name or not batch_code:
        return JsonResponse(
            {'status': 'error', 'message': 'username, batch_name and batch_code are required'},
            status=400,
        )

    try:
        faculty = User.objects.get(username=username, role='faculty')
    except User.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'Faculty user not found'}, status=404)

    similarity_threshold = data.get('similarity_threshold', 0.8)
    try:
        similarity_threshold = float(similarity_threshold)
    except (ValueError, TypeError):
        return JsonResponse({'status': 'error', 'message': 'similarity_threshold must be a number between 0 and 1'}, status=400)

    if similarity_threshold < 0.0 or similarity_threshold > 1.0:
        return JsonResponse({'status': 'error', 'message': 'similarity_threshold must be between 0 and 1'}, status=400)

    if Batch.objects.filter(batch_code=batch_code).exists():
        return JsonResponse({'status': 'error', 'message': 'Batch code already exists'}, status=400)

    batch = Batch.objects.create(
        batch_name=batch_name,
        batch_code=batch_code,
        created_by=faculty,
        similarity_threshold=similarity_threshold,
    )

    return JsonResponse({
        'status': 'success',
        'message': 'Batch created successfully',
        'batch': {
            'id': batch.id,
            'batch_name': batch.batch_name,
            'batch_code': batch.batch_code,
        },
    })


# ---------------------------------------------------------------------------
# FACULTY: Get Batches created by faculty
# ---------------------------------------------------------------------------
@csrf_exempt
def get_batches(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

    try:
        data = json.loads(request.body)
    except (json.JSONDecodeError, Exception):
        return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)

    username = data.get('username', '').strip()
    if not username:
        return JsonResponse({'status': 'error', 'message': 'username is required'}, status=400)

    try:
        faculty = User.objects.get(username=username, role='faculty')
    except User.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'Faculty user not found'}, status=404)

    batches = Batch.objects.filter(created_by=faculty).order_by('-created_at')
    data_out = [
        {
            'id': b.id,
            'batch_name': b.batch_name,
            'batch_code': b.batch_code,
            'member_count': b.members.count(),
            'similarity_threshold': b.similarity_threshold,
        }
        for b in batches
    ]

    return JsonResponse({'status': 'success', 'batches': data_out})


# ---------------------------------------------------------------------------
# FACULTY: Update Batch Similarity Threshold
# ---------------------------------------------------------------------------
@csrf_exempt
def set_batch_threshold(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

    try:
        data = json.loads(request.body)
    except (json.JSONDecodeError, Exception):
        return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)

    username = data.get('username', '').strip()
    batch_id = data.get('batch_id')
    similarity_threshold = data.get('similarity_threshold')

    if not username or batch_id is None or similarity_threshold is None:
        return JsonResponse(
            {'status': 'error', 'message': 'username, batch_id and similarity_threshold are required'},
            status=400,
        )

    try:
        faculty = User.objects.get(username=username, role='faculty')
    except User.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'Faculty user not found'}, status=404)

    try:
        batch = Batch.objects.get(id=int(batch_id), created_by=faculty)
    except (Batch.DoesNotExist, ValueError):
        return JsonResponse({'status': 'error', 'message': 'Invalid batch or unauthorized'}, status=404)

    try:
        similarity_threshold = float(similarity_threshold)
    except (ValueError, TypeError):
        return JsonResponse({'status': 'error', 'message': 'similarity_threshold must be a number between 0 and 1'}, status=400)

    if similarity_threshold < 0.0 or similarity_threshold > 1.0:
        return JsonResponse({'status': 'error', 'message': 'similarity_threshold must be between 0 and 1'}, status=400)

    batch.similarity_threshold = similarity_threshold
    batch.save()

    return JsonResponse({
        'status': 'success',
        'message': 'Batch similarity threshold updated',
        'batch': {
            'id': batch.id,
            'batch_name': batch.batch_name,
            'batch_code': batch.batch_code,
            'similarity_threshold': batch.similarity_threshold,
        },
    })


# ---------------------------------------------------------------------------
# STUDENT: Join Batch
# ---------------------------------------------------------------------------
@csrf_exempt
def join_batch(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

    try:
        data = json.loads(request.body)
    except (json.JSONDecodeError, Exception):
        return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)

    username = data.get('username', '').strip()
    batch_code = data.get('batch_code', '').strip()

    if not username or not batch_code:
        return JsonResponse({'status': 'error', 'message': 'username and batch_code are required'}, status=400)

    try:
        student = User.objects.get(username=username, role='student')
    except User.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'Student user not found'}, status=404)

    try:
        batch = Batch.objects.get(batch_code=batch_code)
    except Batch.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'Invalid batch code'}, status=404)

    mapping, created = StudentBatchMapping.objects.get_or_create(student=student, batch=batch)
    if not created:
        return JsonResponse({'status': 'error', 'message': 'Already joined this batch'}, status=400)

    return JsonResponse({
        'status': 'success',
        'message': f'Joined batch "{batch.batch_name}" successfully',
        'batch': {
            'id': batch.id,
            'batch_name': batch.batch_name,
            'batch_code': batch.batch_code,
        },
    })


# ---------------------------------------------------------------------------
# STUDENT: Get batches the student has joined
# ---------------------------------------------------------------------------
@csrf_exempt
def get_student_batches(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

    try:
        data = json.loads(request.body)
    except (json.JSONDecodeError, Exception):
        return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)

    username = data.get('username', '').strip()
    if not username:
        return JsonResponse({'status': 'error', 'message': 'username is required'}, status=400)

    try:
        student = User.objects.get(username=username, role='student')
    except User.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'Student user not found'}, status=404)

    memberships = StudentBatchMapping.objects.filter(student=student).select_related('batch')
    data_out = [
        {
            'id': m.batch.id,
            'batch_name': m.batch.batch_name,
            'batch_code': m.batch.batch_code,
        }
        for m in memberships
    ]

    return JsonResponse({'status': 'success', 'batches': data_out})


# ---------------------------------------------------------------------------
# STUDENT: Upload Document (must be in a batch)
# ---------------------------------------------------------------------------
@csrf_exempt
def upload_document(request):
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

    try:
        # Resolve user
        username = request.POST.get('username', '').strip()
        if not username:
            return JsonResponse({'status': 'error', 'message': 'Authentication required'}, status=401)

        user = User.objects.get(username=username)

        # Resolve batch
        batch_id = request.POST.get('batch_id', '').strip()
        if not batch_id:
            return JsonResponse({'status': 'error', 'message': 'batch_id is required'}, status=400)

        batch = Batch.objects.get(id=int(batch_id))

        # Validate student is part of the batch
        if user.role == 'student':
            if not StudentBatchMapping.objects.filter(student=user, batch=batch).exists():
                return JsonResponse(
                    {'status': 'error', 'message': 'You are not a member of this batch'},
                    status=403,
                )

        upload = request.FILES.get('file')
        if not upload:
            return JsonResponse({'status': 'error', 'message': 'No file provided'}, status=400)

        # Validate extension
        allowed_ext = ['.pdf', '.docx', '.txt']
        _, ext = os.path.splitext(upload.name.lower())
        if ext not in allowed_ext:
            return JsonResponse({'status': 'error', 'message': 'Unsupported file type'}, status=400)

        # Save file temporarily to extract text
        saved_path = default_storage.save(f'documents/{upload.name}', ContentFile(upload.read()))
        full_path = default_storage.path(saved_path)

        # Extract text
        extracted_text = extract_text(full_path)

        # Check similarity with existing documents in the batch
        existing_docs = Document.objects.filter(batch=batch).exclude(extracted_text__isnull=True).exclude(extracted_text='')
        threshold = batch.similarity_threshold
        max_similarity = 0.0
        status = 'accepted'  # by default

        if existing_docs.exists():
            for doc in existing_docs:
                similarity = compare_docs(extracted_text, doc.extracted_text)
                max_similarity = max(max_similarity, similarity)

            if max_similarity >= threshold:
                # Reject: too similar
                status = 'rejected'

        # Always save the document with its similarity score and status
        document = Document.objects.create(
            user=user,
            batch=batch,
            file_name=upload.name,
            file=saved_path,
            extracted_text=extracted_text,
            similarity_score=max_similarity,
            status=status,
        )

        # Return appropriate message based on status
        if status == 'rejected':
            return JsonResponse({
                'status': 'error',
                'message': f'Document was rejected: similarity score {max_similarity:.2f} exceeds threshold {threshold:.2f}',
                'document_id': document.id,
                'similarity_score': max_similarity,
                'threshold': threshold,
            }, status=400)
        else:
            return JsonResponse({
                'status': 'success',
                'message': 'Document uploaded successfully',
                'document_id': document.id,
                'highest_similarity': max_similarity,
                'threshold': threshold,
            })

    except Exception as e:
        # Catch any unexpected errors and return JSON
        return JsonResponse({
            'status': 'error',
            'message': f'An unexpected error occurred: {str(e)}'
        }, status=500)


# ---------------------------------------------------------------------------
# Get Documents for a Specific Batch
# ---------------------------------------------------------------------------
@csrf_exempt
def get_batch_documents(request):
    """
    GET or POST: /api/get-batch-documents/
    Required: batch_id
    Optional: username (for authorization checks)
    
    Returns all documents uploaded to a specific batch.
    """
    if request.method not in ['GET', 'POST']:
        return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

    # Get batch_id from request
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            batch_id = data.get('batch_id', '').strip()
        except (json.JSONDecodeError, Exception):
            return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)
    else:  # GET
        batch_id = request.GET.get('batch_id', '').strip()

    if not batch_id:
        return JsonResponse({'status': 'error', 'message': 'batch_id is required'}, status=400)

    try:
        batch = Batch.objects.get(id=int(batch_id))
    except (Batch.DoesNotExist, ValueError):
        return JsonResponse({'status': 'error', 'message': 'Invalid batch'}, status=404)

    # Fetch documents for this batch
    documents = Document.objects.filter(batch=batch).order_by('-uploaded_at')
    docs_data = [
        {
            'id': doc.id,
            'file_name': doc.file_name,
            'uploaded_by': doc.user.username,
            'uploaded_at': doc.uploaded_at.isoformat(),
            'batch_id': doc.batch.id,
        }
        for doc in documents
    ]

    return JsonResponse({'status': 'success', 'documents': docs_data})


# ---------------------------------------------------------------------------
# FACULTY: Get Batch Details with Students and Document Status
# ---------------------------------------------------------------------------
@csrf_exempt
def get_batch_details(request):
    """
    POST: /api/get-batch-details/
    Required: username (faculty), batch_id
    
    Returns batch information with all students and their document upload status.
    """
    if request.method != 'POST':
        return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

    try:
        data = json.loads(request.body)
    except (json.JSONDecodeError, Exception):
        return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)

    username = data.get('username', '').strip()
    batch_id = data.get('batch_id')

    if not username or batch_id is None:
        return JsonResponse(
            {'status': 'error', 'message': 'username and batch_id are required'},
            status=400,
        )

    try:
        faculty = User.objects.get(username=username, role='faculty')
    except User.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'Faculty user not found'}, status=404)

    try:
        batch = Batch.objects.get(id=int(batch_id), created_by=faculty)
    except (Batch.DoesNotExist, ValueError):
        return JsonResponse({'status': 'error', 'message': 'Invalid batch or unauthorized'}, status=404)

    # Get all students who joined this batch
    memberships = StudentBatchMapping.objects.filter(batch=batch).select_related('student').order_by('joined_at')

    # Build student list with document status
    students_data = []
    for membership in memberships:
        student = membership.student
        
        # Get documents uploaded by this student in this batch
        documents = Document.objects.filter(user=student, batch=batch).order_by('-uploaded_at')
        
        # Get the latest document for this student
        latest_doc = documents.first()
        
        student_info = {
            'student_id': student.id,
            'username': student.username,
            'joined_at': membership.joined_at.isoformat(),
            'document_uploaded': documents.exists(),
            'document_details': None,
        }
        
        # Add document details if uploaded
        if latest_doc:
            student_info['document_details'] = {
                'document_id': latest_doc.id,
                'file_name': latest_doc.file_name,
                'uploaded_at': latest_doc.uploaded_at.isoformat(),
                'similarity_score': latest_doc.similarity_score if latest_doc.similarity_score is not None else 0.0,
                'status': latest_doc.status,  # 'accepted' or 'rejected'
            }
        else:
            student_info['document_details'] = {
                'file_name': 'Not uploaded yet',
                'uploaded_at': None,
                'similarity_score': None,
                'status': 'pending',
            }
        
        students_data.append(student_info)

    # Return batch details with all students
    batch_details = {
        'batch_id': batch.id,
        'batch_name': batch.batch_name,
        'batch_code': batch.batch_code,
        'similarity_threshold': batch.similarity_threshold,
        'created_at': batch.created_at.isoformat(),
        'total_students': len(students_data),
        'documents_count': Document.objects.filter(batch=batch).count(),
        'students': students_data,
    }

    return JsonResponse({'status': 'success', 'batch': batch_details})


# ---------------------------------------------------------------------------
# FACULTY: Download Document (Faculty View Only)
# ---------------------------------------------------------------------------
@csrf_exempt
def download_document(request):
    """
    GET or POST: /api/download-document/
    Required: document_id, username (faculty)
    
    Allows faculty to download a document uploaded by a student.
    Faculty can only download documents from batches they created.
    """
    if request.method not in ['GET', 'POST']:
        return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

    # Get document_id and username from request
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            document_id = data.get('document_id')
            username = data.get('username', '').strip()
        except (json.JSONDecodeError, Exception):
            return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)
    else:  # GET
        document_id = request.GET.get('document_id')
        username = request.GET.get('username', '').strip()

    if not document_id or not username:
        return JsonResponse(
            {'status': 'error', 'message': 'document_id and username are required'},
            status=400,
        )

    # Verify faculty exists
    try:
        faculty = User.objects.get(username=username, role='faculty')
    except User.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'Faculty user not found'}, status=404)

    # Get the document
    try:
        document = Document.objects.get(id=int(document_id))
    except (Document.DoesNotExist, ValueError):
        return JsonResponse({'status': 'error', 'message': 'Document not found'}, status=404)

    # Verify that the document's batch was created by this faculty
    if document.batch.created_by != faculty:
        return JsonResponse(
            {'status': 'error', 'message': 'Unauthorized: You can only download documents from your batches'},
            status=403,
        )

    # Check if file exists
    if not document.file:
        return JsonResponse({'status': 'error', 'message': 'Document file not found'}, status=404)

    try:
        # Open the file
        file_path = document.file.path
        file_handle = open(file_path, 'rb')
        
        # Create response with proper headers for download
        response = FileResponse(
            file_handle,
            as_attachment=True,
            filename=document.file_name
        )
        response['Content-Type'] = 'application/pdf'
        response['Content-Disposition'] = f'attachment; filename="{document.file_name}"'
        
        return response
    except Exception as e:
        return JsonResponse(
            {'status': 'error', 'message': f'Failed to download document: {str(e)}'},
            status=500,
        )
