from django.db import models


class Batch(models.Model):
    batch_name = models.CharField(max_length=255)
    batch_code = models.CharField(max_length=50, unique=True)
    created_by = models.ForeignKey(
        'auth_api.User',
        on_delete=models.CASCADE,
        related_name='created_batches',
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
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.file_name} ({self.user}) — {self.batch}"
