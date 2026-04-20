from django.urls import path
from .views import (
    upload_document,
    create_batch,
    get_batches,
    set_batch_threshold,
    join_batch,
    get_student_batches,
    get_batch_documents,
    get_batch_details,
    download_document,
)

urlpatterns = [
    path('upload-document/', upload_document, name='upload_document'),
    path('create-batch/', create_batch, name='create_batch'),
    path('get-batches/', get_batches, name='get_batches'),
    path('set-batch-threshold/', set_batch_threshold, name='set_batch_threshold'),
    path('join-batch/', join_batch, name='join_batch'),
    path('get-student-batches/', get_student_batches, name='get_student_batches'),
    path('get-batch-documents/', get_batch_documents, name='get_batch_documents'),
    path('get-batch-details/', get_batch_details, name='get_batch_details'),
    path('download-document/', download_document, name='download_document'),
]
