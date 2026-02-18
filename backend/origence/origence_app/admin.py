from django.contrib import admin
from .models import User

# Register your custom user model so you can manage users via admin
admin.site.register(User)

