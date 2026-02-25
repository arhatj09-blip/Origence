from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.hashers import make_password, check_password
import json
from .models import User

@csrf_exempt
def register(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        username = data.get('username', '').strip()
        email = data.get('email', '').strip()
        phone = data.get('phone', '').strip()
        password = data.get('password', '').strip()

        errors = {}
        if not username: errors['username'] = 'Username required'
        if not email: errors['email'] = 'Email required'
        if not phone: errors['phone'] = 'Phone required'
        if not password: errors['password'] = 'Password required'
        if len(phone) != 10 or not phone.isdigit():
            errors['phone'] = 'Phone must be 10 digits'
        if User.objects.filter(username=username).exists():
            errors['username'] = 'Username already exists'
        if User.objects.filter(email=email).exists():
            errors['email'] = 'Email already exists'
        if errors:
            return JsonResponse({'success': False, 'errors': errors}, status=400)

        user = User(username=username, email=email, phone=phone, password=make_password(password))
        user.save()
        return JsonResponse({'success': True, 'message': 'User registered successfully'})
    return JsonResponse({'success': False, 'message': 'Invalid request'}, status=405)

@csrf_exempt
def login(request):
    import sys
    print(f"[DEBUG] login() called. Method: {request.method}", file=sys.stderr)
    print(f"[DEBUG] Body: {request.body}", file=sys.stderr)
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
        except Exception as e:
            print(f"[DEBUG] JSON decode error: {e}", file=sys.stderr)
            return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)
        username_or_email = data.get('username', '').strip() or data.get('email', '').strip()
        password = data.get('password', '').strip()
        print(f"[DEBUG] username_or_email: {username_or_email}, password: {'*' * len(password)}", file=sys.stderr)
        if not username_or_email or not password:
            return JsonResponse({'status': 'error', 'message': 'All fields required'}, status=400)
        user = (User.objects.filter(username=username_or_email).first() or
                User.objects.filter(email=username_or_email).first())
        if user and check_password(password, user.password):
            request.session['user_id'] = user.id
            return JsonResponse({'status': 'success', 'username': user.username})
        else:
            return JsonResponse({'status': 'error', 'message': 'Invalid credentials'}, status=401)
    return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)

@csrf_exempt
def logout(request):
    if request.method == 'POST':
        request.session.flush()
        return JsonResponse({'status': 'success', 'message': 'Logged out successfully'})
    return JsonResponse({'status': 'error', 'message': 'Invalid request'}, status=405)
