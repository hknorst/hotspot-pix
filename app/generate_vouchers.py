import sqlite3
import random
import string
from datetime import datetime
import qrcode
import os

DB_NAME = 'vouchers.db'

def init_db():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS vouchers (
            id TEXT PRIMARY KEY,
            duration INTEGER NOT NULL,
            used INTEGER DEFAULT 0,
            created_at TEXT,
            ip TEXT,
            expires_at TEXT,
            mac TEXT
        )
    ''')
    conn.commit()
    conn.close()

def generate_code(length=6):
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))

def create_vouchers(n, duration):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    now = datetime.now().isoformat()
    created = []

    for _ in range(n):
        code = generate_code()
        try:
            c.execute('INSERT INTO vouchers (id, duration, used, created_at) VALUES (?, ?, ?, ?)',
                      (code, duration, 0, now))
            created.append(code)
        except sqlite3.IntegrityError:
            pass

    conn.commit()
    conn.close()

    os.makedirs("static/qrcodes", exist_ok=True)
    for code in created:
        url = f"http://192.168.10.1/?voucher={code}"
        img = qrcode.make(url)
        img.save(f"static/qrcodes/{code}.png")

    return created