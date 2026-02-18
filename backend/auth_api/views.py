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
    if request.method == 'POST':
        data = json.loads(request.body)
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        try:
            user = User.objects.get(username=username)
            if check_password(password, user.password):
                return JsonResponse({'success': True, 'username': user.username, 'user_id': user.id})
            else:
                return JsonResponse({'success': False, 'message': 'Invalid credentials'}, status=400)
        except User.DoesNotExist:
            return JsonResponse({'success': False, 'message': 'Invalid credentials'}, status=400)
    return JsonResponse({'success': False, 'message': 'Invalid request'}, status=405)

@csrf_exempt
def logout(request):
    return JsonResponse({'success': True, 'message': 'Logged out'})
