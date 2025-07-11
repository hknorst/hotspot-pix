#!/usr/bin/env python3

import sqlite3
from datetime import datetime
import subprocess

DB_NAME = '/app/vouchers.db'

def disconnect(ip):
    try:
        subprocess.run(["iptables", "-D", "nodogsplash_authusers", "-s", ip, "-j", "ACCEPT"], check=True)
        print(f"[x] Acesso expirado para IP: {ip}")
    except subprocess.CalledProcessError:
        print(f"[!] Falha ao remover IP: {ip} (talvez já removido)")

def check_expired():
    now = datetime.now()
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT id, ip, expires_at FROM vouchers WHERE used = 1 AND expires_at IS NOT NULL")
    for id_, ip, expires_at in c.fetchall():
        if ip and expires_at:
            exp_time = datetime.fromisoformat(expires_at)
            if now > exp_time:
                disconnect(ip)
                c.execute("UPDATE vouchers SET ip = NULL, mac = NULL WHERE id = ?", (id_,))
    conn.commit()
    conn.close()

if __name__ == '__main__':
    check_expired()