<<<<<<< HEAD
# origence

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
📄 Origence — Academic Plagiarism Detection System

Origence is a batch-based academic plagiarism detection system designed to ensure document originality within academic environments. It allows faculty to create batches and define similarity thresholds, while students can join batches and submit documents that are checked for plagiarism.

🚀 Features:
👨‍🏫 Faculty
Create batches with unique batch codes
Set allowed similarity threshold
View all created batches
View students joined in each batch
Track student submissions:
Uploaded / Not Uploaded
Accepted / Rejected
Similarity score
Monitor document status batch-wise
👨‍🎓 Student
Register and login with role-based access
Join batches using batch code
Upload documents only inside a batch
Automatic plagiarism checking before upload
Upload allowed only if similarity < threshold

🧠 Core Logic:
Each document is compared only with documents in the same batch
Plagiarism is calculated using similarity logic
If:
Similarity < Threshold → Document Accepted
Similarity ≥ Threshold → Document Rejected
Threshold is defined by faculty and dynamically fetched from backend

🏗️ System Architecture:
User (Faculty/Student)
        ↓
     Batch
        ↓
  Document Upload
        ↓
Similarity Check (Batch-wise)
        ↓
 Accept / Reject
 
🛠️ Tech Stack:
Frontend
Flutter
Dart
Backend
Django (Python)
REST APIs
Database
SQLite

📂 Project Structure:
origence/
├── frontend/        # Flutter App
├── backend/         # Django Backend
│   ├── api/
│   ├── auth_api/
│   ├── core/
│   ├── db.sqlite3
│   └── manage.py

⚙️ Setup Instructions:
1️⃣ Clone Repository
git clone <your-repo-link>
cd origence

2️⃣ Backend Setup (Django)
cd backend
python -m venv venv
venv\Scripts\activate   # Windows
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver

3️⃣ Frontend Setup (Flutter)
cd frontend
flutter pub get
flutter run

🔐 Authentication System:
Username + Password based login
Role-based access:
Faculty
Student

📊 Database Design:
Key Models:
User (with role)
Batch
Batch Membership (Student ↔ Batch)
Document

Each document stores:

User
Batch
File
Similarity Score
Status (Accepted / Rejected)
Upload Timestamp

🔥 Key Highlights:
Batch-specific plagiarism detection
Role-based system (Faculty & Student)
Dynamic threshold control
Clean UI with structured workflow
Scalable architecture

📌 Future Enhancements:
AI-based semantic similarity detection
PDF highlighting of plagiarized content
Cross-batch comparison
Admin panel
Cloud deployment (AWS / Firebase)
Notifications system


🤝 Contribution:
This is a team project developed as part of academic coursework. Contributions and suggestions are welcome.

📜 License:
This project is for educational purposes.

👨‍💻 Authors:
Arhat

⭐ Final Note:
Origence ensures document originality with structured, batch-based plagiarism detection, making it a practical solution for academic institutions.
>>>>>>> e6c979d13afeae6334e0f63d6b4233253f55fc7a
