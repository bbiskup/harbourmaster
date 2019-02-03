build-debug: build-backend build-frontend-debug

build-frontend-debug:
	./docker-cmd.sh "(cd elm && elm make src/Main.elm --output ../static/elm.js --debug)"

build-backend-python:
	docker-compose build && \
	docker-compose up -d 
	./docker-cmd.sh "pipenv install --dev"

build-backend-elixir:
	(cd harbourmaster_umbrella && mix compile)

build-backend: build-backend-python build-backend-elixir

build-frontend:
	./docker-cmd.sh "(cd elm && elm make src/Main.elm --output ../static/elm.js)"

run-server:
	# NOTE: Only listen on all interfaces (0.0.0.0) when running the server in
	# a Docker container, otherwise the server will be accessible from a remote host!
	./docker-cmd.sh "pipenv run python3 python/harbourmaster.py 0.0.0.0"
	

test: test-frontend

test-frontend:
	./docker-cmd.sh "cd elm && elm-test"

test-frontend-watch:
	./docker-cmd.sh "cd elm && elm-test --watch"
