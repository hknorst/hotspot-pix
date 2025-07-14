setup:
	docker compose up -d --build

db-init:
	docker compose exec hotspot python generate_vouchers.py --init

print-test:
	docker compose exec hotspot python print_voucher.py TESTE123

logs:
	docker compose logs -f

restart:
	docker compose restart

stop:
	docker compose down