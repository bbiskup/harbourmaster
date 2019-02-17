build-debug: build-backend build-frontend-debug

build-frontend-debug:
	./docker-cmd.sh "(cd elm && elm make src/Main.elm --output ../static/elm.js --debug)"

build-backend-elixir:
	./docker-cmd.sh "(cd harbourmaster_umbrella && mix deps.get && mix compile)"

build-backend:  build-backend-elixir

build-frontend:
	./docker-cmd.sh "(cd elm && elm make src/Main.elm --output ../harbourmaster_umbrella/apps/web/priv/static/js/elm.js)"

run-server:
	# NOTE: Only listen on all interfaces (0.0.0.0) when running the server in
	# a Docker container, otherwise the server will be accessible from a remote host!
	./docker-cmd.sh "pipenv run python3 python/harbourmaster.py 0.0.0.0"
	

test: test-frontend # test-backend

test-frontend:
	./docker-cmd.sh "cd elm && elm-test"

test-frontend-watch:
	./docker-cmd.sh "cd elm && elm-test --watch"

test-backend: test-backend-elixir

test-backend-elixir:
	(cd harbourmaster_umbrella && mix test)

prepare: prepare-backend

prepare-backend:
	./docker-cmd.sh "(cd harbourmaster_umbrella && \
	 mix local.hex --force && \
	 mix deps.get && \
	 mix local.rebar && \
	 mix archive.install --force hex phx_new 1.4.0)"

build-docker:
	docker build -f Dockerfile.alpine -t harbourmaster_dev .

start-container:
	./run_dev_container.sh

start-server:
	./docker-cmd.sh "(cd harbourmaster_umbrella && mix phx.server)"

backend-clean:
	./docker-cmd.sh "harbourmaster_umbrella/_build"


stop-container:
	docker rm -f harbourmaster_dev 2>/dev/null || true

total-clean: stop-container backend-clean frontend-clean

clean: backend-clean frontend-clean
