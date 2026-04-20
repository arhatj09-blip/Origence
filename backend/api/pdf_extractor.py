from PyPDF2 import PdfReader
import os
import time
from docx import Document as DocxDocument


# ------------------ EXTRACT TEXT ------------------

def extract_text_from_pdf(pdf_path):
    try:
        reader = PdfReader(pdf_path)
        text = ""

        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:  # avoid None issues
                text += page_text + "\n"

        return text.strip()
    except Exception:
        return ""


def extract_text_from_docx(docx_path):
    try:
        doc = DocxDocument(docx_path)
        text = ""
        for para in doc.paragraphs:
            text += para.text + "\n"
        return text.strip()
    except Exception:
        return ""


def extract_text_from_txt(txt_path):
    try:
        with open(txt_path, 'r', encoding='utf-8') as f:
            return f.read().strip()
    except Exception:
        return ""


def extract_text(file_path):
    _, ext = os.path.splitext(file_path.lower())
    if ext == '.pdf':
        return extract_text_from_pdf(file_path)
    elif ext == '.docx':
        return extract_text_from_docx(file_path)
    elif ext == '.txt':
        return extract_text_from_txt(file_path)
    else:
        return ""


# ------------------ SAVE TEXT FILE ------------------

def save_text_to_database(text, database_folder="database"):
    
    # Create folder if not exists
    if not os.path.exists(database_folder):
        os.makedirs(database_folder)

    # Unique filename using timestamp
    filename = f"report_{int(time.time())}.txt"
    file_path = os.path.join(database_folder, filename)

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(text)

    return file_path


# ------------------ FULL PIPELINE ------------------

def process_pdf(pdf_path, database_folder="database"):
    
    # Step 1: Extract text
    text = extract_text_from_pdf(pdf_path)

    # Step 2: Save extracted text
    saved_path = save_text_to_database(text, database_folder)

    return text, saved_path