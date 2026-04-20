#!/usr/bin/env python
"""
Reset the entire application to a fresh state:
- Deletes all database entries
- Removes all uploaded documents
- Recreates the database schema

Run this script from the backend directory:
    python reset_all_data.py
"""

import os
import sys
import shutil
from pathlib import Path

def reset_application():
    """Reset the application to fresh state"""
    
    base_dir = Path(__file__).resolve().parent
    
    print("=" * 60)
    print("RESETTING APPLICATION TO FRESH STATE")
    print("=" * 60)
    
    # Step 1: Delete database
    db_path = base_dir / 'db.sqlite3'
    if db_path.exists():
        print(f"\n[1/3] Removing database: {db_path}")
        db_path.unlink()
        print("✓ Database deleted")
    else:
        print(f"\n[1/3] Database not found: {db_path}")
    
    # Step 2: Delete all uploaded documents
    media_path = base_dir / 'media'
    if media_path.exists():
        print(f"\n[2/3] Removing uploaded documents: {media_path}")
        shutil.rmtree(media_path)
        # Recreate empty media directory structure
        media_path.mkdir(parents=True, exist_ok=True)
        (media_path / 'documents').mkdir(exist_ok=True)
        print("✓ All uploaded documents deleted")
    else:
        print(f"\n[2/3] Media directory not found, creating it: {media_path}")
        media_path.mkdir(parents=True, exist_ok=True)
        (media_path / 'documents').mkdir(exist_ok=True)
    
    # Step 3: Recreate database schema
    print(f"\n[3/3] Recreating database schema...")
    os.system('python manage.py migrate')
    print("✓ Database schema recreated")
    
    print("\n" + "=" * 60)
    print("✓ APPLICATION RESET COMPLETE!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Start the backend server: python manage.py runserver")
    print("2. Create a new admin user: python manage.py createsuperuser")
    print("3. Your app is ready with a fresh database and no user data")
    print("=" * 60)

if __name__ == '__main__':
    try:
        reset_application()
    except Exception as e:
        print(f"\n❌ Error during reset: {e}", file=sys.stderr)
        sys.exit(1)
