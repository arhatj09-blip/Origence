from django.db import models


class Document(models.Model):
	user = models.ForeignKey('auth_api.User', on_delete=models.CASCADE)
	file_name = models.CharField(max_length=255)
	file = models.FileField(upload_to='documents/')
	uploaded_at = models.DateTimeField(auto_now_add=True)

	def __str__(self):
		return f"{self.file_name} ({self.user})"
