run-server:
	# flask-restplus application
	pipenv run python python/harbourmaster.py
	
	# FLASK_APP=harbourmaster.py flask run --port 9000

build-frontend:
	(cd elm && elm make src/HarbourMaster.elm --output ../static/elm.js)
	

