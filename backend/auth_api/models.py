from django.db import models

class User(models.Model):
    ROLE_CHOICES = [
        ('faculty', 'Faculty'),
        ('student', 'Student'),
    ]

    username = models.CharField(max_length=150, unique=True)
    password = models.CharField(max_length=128)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)

    def __str__(self):
        return f"{self.username} ({self.role})"
