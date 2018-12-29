build-frontend-debug:
	(cd elm && elm make src/Main.elm --output ../static/elm.js --debug)

build-frontend:
	(cd elm && elm make src/Main.elm --output ../static/elm.js)

run-server:
	# flask-restplus application
	pipenv run python python/harbourmaster.py
	
	# FLASK_APP=harbourmaster.py flask run --port 9000
	

test: test-frontend

test-frontend:
	./docker-cmd.sh "cd elm && elm-test"

