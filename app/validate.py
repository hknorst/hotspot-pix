#!/usr/bin/env python3

import sqlite3
import cgi
import os
from datetime import datetime, timedelta
import subprocess

DB_NAME = '/app/vouchers.db'

def get_mac(ip):
    try:
        result = subprocess.check_output(['arp', '-n', ip]).decode()
        for line in result.splitlines():
            if ip in line:
                return line.split()[2]
    except:
        return None

def check_voucher(code, client_ip):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT duration, used, mac FROM vouchers WHERE id = ?", (code,))
    row = c.fetchone()
    if not row:
        return False

    duration, used, mac_in_db = row
    client_mac = get_mac(client_ip)

    if used == 1 and client_mac != mac_in_db:
        return False

    expires_at = (datetime.now() + timedelta(minutes=duration)).isoformat()
    c.execute("UPDATE vouchers SET used = 1, ip = ?, mac = ?, expires_at = ? WHERE id = ?",
              (client_ip, client_mac, expires_at, code))
    conn.commit()
    conn.close()
    return True

def main():
    print("Content-type: text/plain\n")
    form = cgi.FieldStorage()
    code = form.getvalue("voucher")
    client_ip = os.environ.get("REMOTE_ADDR")

    if not code or not client_ip:
        print("Auth: 0")
        return

    if check_voucher(code.strip().upper(), client_ip):
        print("Auth: 1")
    else:
        print("Auth: 0")

if __name__ == '__main__':
    main()