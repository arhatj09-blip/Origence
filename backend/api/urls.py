from django.urls import path
from .views import upload_document

urlpatterns = [
    path('upload-document/', upload_document, name='upload_document'),
]
