import sqlite3

conn = sqlite3.connect('db.sqlite3')
c = conn.cursor()
c.execute('DROP TABLE IF EXISTS auth_api_user')
c.execute("DELETE FROM django_migrations WHERE app='auth_api'")
conn.commit()
conn.close()
print('Done: dropped auth_api_user table and cleared migration records')
