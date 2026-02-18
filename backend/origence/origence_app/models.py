from django.db import models

# custom user model – not using Django's built-in auth
class User(models.Model):
    # id field is added automatically by Django as AutoField primary key
    username = models.CharField(max_length=150, unique=True)
    password = models.CharField(max_length=128)  # hashed password
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.username

# other application models can go below
