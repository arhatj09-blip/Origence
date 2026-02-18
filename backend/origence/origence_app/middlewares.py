
from django.shortcuts import redirect

# *********** Authenticated **************
# check session key set by our custom login view

def auth(view_function):
    def wrapped_view(request,*args,**kwargs):
        if not request.session.get('user_id'):
            return redirect('login')
        return view_function(request,*args,**kwargs)
    return wrapped_view

# *********** Guest **************
def guest(view_function):
    def wrapped_view(request,*args,**kwargs):
        if request.session.get('user_id'):
            return redirect('dashboard')
        return view_function(request,*args,**kwargs)
    return wrapped_view