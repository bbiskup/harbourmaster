from flask import Flask
from flask_restplus import Resource, Api
import requests
import requests_unixsocket


app = Flask(__name__)
api = Api(app)

session = requests_unixsocket.Session()

@app.route('/')
def hello():
    return 'Hello'

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
        args = docker_engine_parser.parse_args()
        url = args['url']
        print('URL: %s', url)
        r = session.get('http+unix://%%2Fvar%%2Frun%%2Fdocker.sock%s' % url) 
        return r.json()


if __name__ == '__main__':
    app.run(debug=True, port=9000)

