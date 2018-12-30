import sys
from flask import Flask, Blueprint, redirect
from flask_restplus import Resource, Api
import requests
import requests_unixsocket
import threading


app = Flask(__name__)
blueprint = Blueprint('api', __name__, url_prefix='/api')

api = Api(blueprint, doc='/doc/')
app.register_blueprint(blueprint)

session = requests_unixsocket.Session()

@app.route('/')
def root():
    return redirect('/app')

@app.route('/app', defaults={'path': ''})
@app.route('/<path:path>')
def index(path):
    return app.send_static_file('index.html')

docker_engine_parser = api.parser()
docker_engine_parser.add_argument('url',
                                  type=str,
                                  required=True,
                                  help='A Docker engine URL is required')


@api.route('/docker-engine/')
@api.expect(docker_engine_parser)
class DockerEngine(Resource):
    """Endpoint to communicate with Docker engine (via Unix domain socket)"""

    def __init__(self, *args, **kwargs):
        super(DockerEngine, self).__init__(*args, **kwargs)
        self._lock = threading.Lock()

    def get(self, **kwargs):
        return self._handle_request(session.get, **kwargs)

    def post(self, **kwargs):
        return self._handle_request(session.post, **kwargs)

    def delete(self, **kwargs):
        return self._handle_request(session.delete, **kwargs)
    
    def _handle_request(self, handler, **kwargs):
        args = docker_engine_parser.parse_args()
        url = args['url']
        print('URL: %s' % url)
        docker_request = 'http+unix://%2Fvar%2Frun%2Fdocker.sock{url}'.format(url=url)

        with self._lock:
            r = handler(docker_request) 

        print('Docker Engine API request: {req}, response: {status}'.format(
                req=docker_request, status=r.status_code))
        r.raise_for_status()

        if not r.content:
            # Handle empty response (HTTP status 204, 304, ...)
            return None
        else:
            return r.json()


if __name__ == '__main__':
    host = sys.argv[1] if len(sys.argv) == 2 else 'localhost'

    app.run(debug=True,
            host=host,
            port=9000)

