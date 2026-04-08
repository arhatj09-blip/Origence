from django.urls import path
from .views import (
    upload_document,
    create_batch,
    get_batches,
    join_batch,
    get_student_batches,
    get_batch_documents,
)

urlpatterns = [
    path('upload-document/', upload_document, name='upload_document'),
    path('create-batch/', create_batch, name='create_batch'),
    path('get-batches/', get_batches, name='get_batches'),
    path('join-batch/', join_batch, name='join_batch'),
    path('get-student-batches/', get_student_batches, name='get_student_batches'),
    path('get-batch-documents/', get_batch_documents, name='get_batch_documents'),
]
