from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
import os

from auth_api.models import User
from .models import Document


@csrf_exempt
def upload_document(request):
	if request.method != 'POST':
		return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

	# Identify user: prefer session, fallback to posted username
	user = None
	user_id = request.session.get('user_id')
	if user_id:
		try:
			user = User.objects.get(id=user_id)
		except User.DoesNotExist:
			user = None

	if not user:
		posted_username = request.POST.get('username')
		if not posted_username:
			return JsonResponse({'status': 'error', 'message': 'Authentication required'}, status=401)
		try:
			user = User.objects.get(username=posted_username)
		except User.DoesNotExist:
			return JsonResponse({'status': 'error', 'message': 'Invalid user'}, status=401)

	upload = request.FILES.get('file')
	if not upload:
		return JsonResponse({'status': 'error', 'message': 'No file provided'}, status=400)

	# Validate extension
	allowed_ext = ['.pdf', '.docx', '.txt']
	_, ext = os.path.splitext(upload.name.lower())
	if ext not in allowed_ext:
		return JsonResponse({'status': 'error', 'message': 'Unsupported file type'}, status=400)

	# Save file using Django storage
	saved_path = default_storage.save(f'documents/{upload.name}', ContentFile(upload.read()))

	# Create DB record
	doc = Document.objects.create(
		user=user,
		file_name=upload.name,
		file=saved_path,
	)

	return JsonResponse({'status': 'success', 'message': 'Document uploaded successfully'})
