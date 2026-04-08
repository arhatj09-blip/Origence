from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.hashers import make_password, check_password
import json
from .models import User

VALID_ROLES = ('faculty', 'student')


@csrf_exempt
def register(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)

        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        confirm_password = data.get('confirm_password', '').strip()
        role = data.get('role', '').strip().lower()

        # --- validation ---
        errors = {}
        if not username:
            errors['username'] = 'Username is required'
        if not password:
            errors['password'] = 'Password is required'
        if not confirm_password:
            errors['confirm_password'] = 'Please confirm your password'
        if password and confirm_password and password != confirm_password:
            errors['confirm_password'] = 'Passwords do not match'
        if role not in VALID_ROLES:
            errors['role'] = 'Role must be faculty or student'
        if username and User.objects.filter(username=username).exists():
            errors['username'] = 'Username already exists'

        if errors:
            return JsonResponse({'status': 'error', 'errors': errors}, status=400)

        user = User(
            username=username,
            password=make_password(password),
            role=role,
        )
        user.save()

        return JsonResponse({'status': 'success', 'message': 'User registered successfully'})

    return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)


@csrf_exempt
def login(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)

        username = data.get('username', '').strip()
        password = data.get('password', '').strip()

        if not username or not password:
            return JsonResponse({'status': 'error', 'message': 'All fields are required'}, status=400)

        user = User.objects.filter(username=username).first()

        if user and check_password(password, user.password):
            request.session['user_id'] = user.id
            return JsonResponse({
                'status': 'success',
                'username': user.username,
                'role': user.role,
            })
        else:
            return JsonResponse({'status': 'error', 'message': 'Invalid credentials'}, status=401)

    return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)


@csrf_exempt
def logout(request):
    if request.method == 'POST':
        request.session.flush()
        return JsonResponse({'status': 'success', 'message': 'Logged out successfully'})
    return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)
