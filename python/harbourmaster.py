import sys
from flask import Flask, Blueprint, redirect
from flask_restplus import Resource, Api
import requests
import requests_unixsocket


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

    def get(self, **kwargs):
        return self._handle_request(session.get, **kwargs)

    def post(self, **kwargs):
        return self._handle_request(session.post, **kwargs)
    
    def _handle_request(self, handler, **kwargs):
        args = docker_engine_parser.parse_args()
        url = args['url']
        print('URL: %s', url)
        r = handler('http+unix://%2Fvar%2Frun%2Fdocker.sock{url}'.format(url=url)) 

        if r.text:
            return r.json()
        else:
            return {}


if __name__ == '__main__':
    host = sys.argv[1] if len(sys.argv) == 2 else 'localhost'

    app.run(debug=True,
            host=host,
            port=9000)

