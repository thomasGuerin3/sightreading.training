
.PHONY: new_migration migrate init_schema test_db lint lint_js checkpoint restore_checkpoint annotate_models

new_migration:
	(echo "  [$$(date +%s)]: =>"; echo) >> migrations.moon

migrate:
	lapis migrate
	make schema.sql

schema.sql::
	pg_dump -s -U postgres sightreading > schema.sql
	pg_dump -a -t lapis_migrations -U postgres sightreading >> schema.sql

init_schema:
	createdb -U postgres sightreading
	cat schema.sql | psql -U postgres sightreading

test_db:
	-dropdb -U postgres sightreading_test
	createdb -U postgres sightreading_test
	pg_dump -s -U postgres sightreading | psql -U postgres sightreading_test
	pg_dump -a -t lapis_migrations -U postgres sightreading | psql -U postgres sightreading_test

install:
	npm install

	luarocks --lua-version=5.1 install --tree lua_modules https://luarocks.org/manifests/leafo/lapis-dev-1.rockspec
	luarocks --lua-version=5.1 install --tree lua_modules bcrypt
	luarocks --lua-version=5.1 install --tree lua_modules tableshape
	luarocks --lua-version=5.1 install --tree lua_modules moonscript
	luarocks --lua-version=5.1 install --tree lua_modules luabitop
	luarocks --lua-version=5.1 install --tree lua_modules busted
	luarocks --lua-version=5.1 install --tree lua_modules lua-discount
	luarocks --lua-version=5.1 install --tree lua_modules lpeg 1.0.2-1 --pin
	luarocks --lua-version=5.1 install --tree lua_modules LuaSocket
	luarocks --lua-version=5.1 install --tree lua_modules lua-cjson

build_client:
	rm -rf .tup
	rm -rf static/guides/*.json
	rm -rf static/scss/*.css
	rm -rf static/js/st/song_parser_peg.js
	rm -rf static/js/st/staff_assets.jsx
	rm -rf static/jasmine.js static/main.js static/main.js.map static/main.min.js
	rm -rf static/service_worker.js static/service_worker.js.map static/service_worker.min.js
	rm -rf static/specs.js static/specs.js.map
	rm -rf static/specs.css static/style.css static/style.min.css
	tup init
	tup generate build.sh
	./build.sh

build_server:
	git ls-files | grep '\.moon$$' | xargs -n 100 lua_modules/bin/moonc

serve:
	lua_modules/bin/lapis serve --trace

lint:
	git ls-files | grep '\.moon$$' | grep -v config.moon | xargs -n 100 lua_modules/bin/moonc -l

lint_js:
	node_modules/.bin/eslint $$(git ls-files static/js/ | grep '\.js[x]$$')

checkpoint:
	mkdir -p dev_backup
	pg_dump -F c -U postgres sightreading > dev_backup/$$(date +%F_%H-%M-%S).dump

restore_checkpoint:
	-dropdb -U postgres sightreading
	createdb -U postgres sightreading
	pg_restore -U postgres -d sightreading $$(find dev_backup | grep \.dump | sort -V | tail -n 1)

annotate_models:
	lapis annotate $$(find models -type f | grep moon$$)

docker_test:
	docker build --platform linux/amd64 -t sightreading-test .
	docker run --platform=linux/amd64 sightreading-test