# harbourmaster
UI for Docker Engine API

Status: **pre-alpha**

<aside class="warning">
Currently, there is no access control; the Docker engine API is accessible to anyone who can access the web application!
</aside>

# Development

```bash
$ pipenv shell
```

- Sample Docker URL via Flask app: ``http://localhost:9000/api/docker-engine/?url=/info``
- [API documentation](http://localhost:9000/api/doc/)

# Server

```bash
$ make run-server
```

## Reference documentation

- [Docker engine API](https://docs.docker.com/engine/api/v1.39)
