from django.shortcuts import render, redirect
from django.contrib.auth.hashers import make_password, check_password
from .middlewares import auth, guest
from .models import User

# basic register view without using Django auth forms
@guest
def register_view(request):
    errors = {}
    username = ''
    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '')
        confirm = request.POST.get('confirm', '')

        # validation
        if not username:
            errors['username'] = 'Username is required.'
        elif User.objects.filter(username=username).exists():
            errors['username'] = 'This username is already taken.'

        if not password:
            errors['password'] = 'Password is required.'
        if password and password != confirm:
            errors['confirm'] = 'Passwords do not match.'

        if not errors:
            hashed = make_password(password)
            User.objects.create(username=username, password=hashed)
            return redirect('login')

    context = {'errors': errors, 'username': username}
    return render(request, 'origence/register.html', context)

@guest
def login_view(request):
    error = ''
    username = ''
    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '')
        try:
            user = User.objects.get(username=username)
            if check_password(password, user.password):
                # store minimal info in session
                request.session['user_id'] = user.id
                request.session['username'] = user.username
                return redirect('dashboard')
            else:
                error = 'Invalid username or password.'
        except User.DoesNotExist:
            error = 'Invalid username or password.'

    return render(request, 'origence/login.html', {'error': error, 'username': username})

@auth

def dashboard_view(request):
    # we know user_id is in session because auth decorator checked
    return render(request, 'origence/dashboard.html', {'username': request.session.get('username')})


def logout_view(request):
    # clear all session data
    request.session.flush()
    return redirect('login')

