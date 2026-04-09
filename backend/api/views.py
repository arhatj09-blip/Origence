from django.http import JsonResponse
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

        if existing_docs.exists():
            for doc in existing_docs:
                similarity = compare_docs(extracted_text, doc.extracted_text)
                max_similarity = max(max_similarity, similarity)

            if max_similarity >= threshold:
                # Reject: too similar
                # Delete the saved file
                default_storage.delete(saved_path)
                return JsonResponse({
                    'status': 'error',
                    'message': f'Document is too similar to existing documents (similarity: {max_similarity:.2f})',
                    'highest_similarity': max_similarity
                }, status=400)

        # Accept: save to DB
        Document.objects.create(
            user=user,
            batch=batch,
            file_name=upload.name,
            file=saved_path,
            extracted_text=extracted_text,
        )

        return JsonResponse({
            'status': 'success',
            'message': 'Document uploaded successfully',
            'highest_similarity': max_similarity
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
