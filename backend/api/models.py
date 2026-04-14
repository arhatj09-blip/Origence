from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class Batch(models.Model):
    batch_name = models.CharField(max_length=255)
    batch_code = models.CharField(max_length=50, unique=True)
    created_by = models.ForeignKey(
        'auth_api.User',
        on_delete=models.CASCADE,
        related_name='created_batches',
    )
    similarity_threshold = models.FloatField(
        default=0.8,
        validators=[MinValueValidator(0.0), MaxValueValidator(1.0)],
        help_text='Maximum allowed similarity score for new documents in this batch',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.batch_name} [{self.batch_code}]"


class StudentBatchMapping(models.Model):
    student = models.ForeignKey(
        'auth_api.User',
        on_delete=models.CASCADE,
        related_name='batch_memberships',
    )
    batch = models.ForeignKey(
        Batch,
        on_delete=models.CASCADE,
        related_name='members',
    )
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('student', 'batch')

    def __str__(self):
        return f"{self.student.username} → {self.batch.batch_name}"


class Document(models.Model):
    STATUS_CHOICES = [
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
    ]
    
    user = models.ForeignKey(
        'auth_api.User',
        on_delete=models.CASCADE,
        related_name='documents',
    )
    batch = models.ForeignKey(
        Batch,
        on_delete=models.CASCADE,
        related_name='documents',
        null=True,
        blank=True,
    )
    file_name = models.CharField(max_length=255)
    file = models.FileField(upload_to='documents/')
    extracted_text = models.TextField(blank=True, null=True)
    similarity_score = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(1.0)],
        null=True,
        blank=True,
        help_text='Highest similarity score compared to existing documents in the batch',
    )
    status = models.CharField(
        max_length=10,
        choices=STATUS_CHOICES,
        default='accepted',
        help_text='Whether the document was accepted or rejected based on threshold',
    )
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.file_name} ({self.user}) — {self.batch}"
