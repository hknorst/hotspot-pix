import logging
import os
import uuid
from pathlib import Path

import mercadopago
from dotenv import load_dotenv
from flask import Flask, redirect, render_template, request
from generate_vouchers import create_vouchers, init_db

load_dotenv()

# Cria pasta de logs
Path("logs").mkdir(exist_ok=True)

logging.basicConfig(
    filename="logs/pagamentos.log",
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# Determina ambiente (sandbox ou produção)
MP_ENV = os.getenv("MP_ENV", "production").lower()

if MP_ENV == "sandbox":
    ACCESS_TOKEN = os.getenv("ACCESS_TOKEN_SANDBOX")
    logging.info("[AMBIENTE] Usando credenciais de SANDBOX")
else:
    ACCESS_TOKEN = os.getenv("ACCESS_TOKEN")
    logging.info("[AMBIENTE] Usando credenciais de PRODUÇÃO")

app = Flask(__name__)
sdk = mercadopago.SDK(ACCESS_TOKEN)

PLANOS = {
    "1h": {"valor": 2.00, "duracao": 60},
    "3h": {"valor": 4.00, "duracao": 180},
    "24h": {"valor": 10.00, "duracao": 1440}
}


@app.route("/")
def home():
    return render_template("planos.html", planos=PLANOS)


@app.route("/pagar")
def pagar():
    plano = request.args.get("plano")
    if plano not in PLANOS:
        return "Plano inválido"

    info = PLANOS[plano]
    uid = str(uuid.uuid4())

    body = {
        "transaction_amount": info["valor"],
        "description": f"Acesso Wi-Fi - {plano}",
        "payment_method_id": "pix",
        "payer": {"email": f"cliente+{uid}@email.com"},
        "external_reference": uid
    }

    payment = sdk.payment().create(body)
    payment_id = payment["response"]["id"]  # ✅ primeiro define
    logging.info(
        f"[INICIADO] Plano: {plano}, ID: {payment_id}, Valor: {info['valor']}")

    qr_code_base64 = payment["response"]["point_of_interaction"]["transaction_data"]["qr_code_base64"]

    return render_template("pagamento.html", qr=qr_code_base64, id=payment_id, plano=plano)


@app.route("/verificar")
def verificar():
    payment_id = request.args.get("id")
    plano = request.args.get("plano")

    result = sdk.payment().get(payment_id)
    status = result["response"]["status"]
    logging.info(f"[STATUS] Pagamento {payment_id} → {status}")

    if status == "approved":
        duracao = PLANOS[plano]["duracao"]
        init_db()
        voucher = create_vouchers(1, duracao)[0]

        # LOG DO VOUCHER
        logging.info(
            f"[APROVADO] Voucher: {voucher} para plano {plano} – {duracao} min")

        return redirect(f"/voucher/{voucher}")
    else:
        logging.warning(
            f"[PENDENTE] Pagamento {payment_id} ainda não aprovado – Status: {status}")
        return "Pagamento ainda não confirmado."


@app.route("/voucher/<codigo>")
def mostrar_voucher(codigo):
    return render_template("voucher.html", codigo=codigo)


@app.route("/imprimir", methods=["POST"])
def imprimir():
    codigo = request.form.get("codigo")
    from print_voucher import print_voucher
    print_voucher(codigo)
    return f"Voucher {codigo} enviado para impressão!"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
