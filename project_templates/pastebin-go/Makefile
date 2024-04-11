dev: postgres_up
	make -j 2 run_server run_frontend

run_server:
	DATABASE_URL="postgres://pastebin:pastebinpass@localhost:5432/pastebin" go run pastebin

run_frontend:
	cd assets && npm run dev

postgres_up:
	[ -x "`which docker 2>/dev/null`" ] && docker-compose up -d database || true
	[ -x "`which podman 2>/dev/null`" ] && podman compose up -d database || true

stop:
	[ -x "`which docker 2>/dev/null`" ] && docker-compose down || true
	[ -x "`which podman 2>/dev/null`" ] && podman compose down || true
