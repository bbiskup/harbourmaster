build-debug: build-backend build-frontend-debug

build-frontend-debug:
	./docker-cmd.sh "(cd elm && elm make src/Main.elm --output ../static/elm.js --debug)"

build-backend:
	docker-compose build && \
	docker-compose up -d 
	./docker-cmd.sh "pipenv install --dev"

build-frontend:
	./docker-cmd.sh "(cd elm && elm make src/Main.elm --output ../static/elm.js)"

run-server:
	# NOTE: Only listen on all interfaces (0.0.0.0) when running the server in
	# a Docker container, otherwise the server will be accessible from a remote host!
	./docker-cmd.sh "pipenv run python3 python/harbourmaster.py 0.0.0.0"
	

test: test-frontend

test-frontend:
	./docker-cmd.sh "cd elm && elm-test"

