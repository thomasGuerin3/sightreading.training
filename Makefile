# Modern development setup
.PHONY: install dev build serve test clean

# Install all dependencies
install:
	npm install
	cd server && npm install

# Development mode - runs both frontend and backend
dev:
	npm run dev & cd server && npm run dev

# Build production assets
build:
	npm run build

# Serve production (backend only, frontend served as static)
serve:
	cd server && npm start

# Database setup (keeping your existing schema)
init_schema:
	createdb -U postgres sightreading
	cat schema.sql | psql -U postgres sightreading

migrate:
	# Simple migration runner can be added later
	echo "Migrations handled by server on startup"

# Testing
test:
	npm test
	cd server && npm test

# Development database
test_db:
	-dropdb -U postgres sightreading_test
	createdb -U postgres sightreading_test
	pg_dump -s -U postgres sightreading | psql -U postgres sightreading_test

# Cleanup
clean:
	rm -rf node_modules server/node_modules
	rm -rf static/main.js static/main.min.js

# Backup (keeping your existing backup system)
checkpoint:
	mkdir -p dev_backup
	pg_dump -F c -U postgres sightreading > dev_backup/$$(date +%F_%H-%M-%S).dump

restore_checkpoint:
	-dropdb -U postgres sightreading
	createdb -U postgres sightreading
	pg_restore -U postgres -d sightreading $$(find dev_backup | grep \.dump | sort -V | tail -n 1)
