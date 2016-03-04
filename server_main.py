from tornado import (
    web,
    httpserver,
    ioloop,
)

from wsserver.server import WSHandler

application = web.Application([
    (r'/ws', WSHandler),
])


if __name__ == "__main__":
    http_server = httpserver.HTTPServer(application)
    http_server.listen(8675)
    try:
        print('Starting IOLoop with http server for websockets')
        ioloop.IOLoop.instance().start()
    except KeyboardInterrupt:
        http_server.stop()
        print('KeyboardInterrupt: Killed the server')
