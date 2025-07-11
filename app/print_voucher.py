from escpos.printer import Usb
import qrcode
from PIL import Image
import io

VENDOR_ID = 0x0519
PRODUCT_ID = 0x2013

def print_voucher(voucher_code, duration='60 minutos', local_ip='192.168.10.1'):
    try:
        p = Usb(VENDOR_ID, PRODUCT_ID, 0)
    except Exception as e:
        print("Erro ao conectar com a impressora:", e)
        return

    p.set(align='center', bold=True)
    p.text("💻 Wi-Fi Hotspot\n")
    p.text("-----------------------------\n")

    p.set(align='center', bold=True, height=2, width=2)
    p.text(f"{voucher_code}\n")

    p.set(align='center', bold=False, height=1, width=1)
    p.text(f"Validade: {duration}\n\n")

    url = f"http://{local_ip}/?voucher={voucher_code}"
    qr = qrcode.make(url)
    qr = qr.resize((200, 200))
    byte_io = io.BytesIO()
    qr.save(byte_io, format='PNG')
    qr_img = Image.open(io.BytesIO(byte_io.getvalue()))
    p.image(qr_img)

    p.text("\n1. Conecte ao Wi-Fi\n")
    p.text("2. Escaneie o QR ou digite o código\n")
    p.text("3. Aproveite a internet\n\n")
    p.text("-----------------------------\n")
    p.text("PrintUp Hotspot\n")
    p.cut()