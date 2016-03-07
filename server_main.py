from tornado import (
    web,
    httpserver,
    ioloop,
    gen,
)

from wsserver.server import WSHandler
from driverclient.client import DriverClient

application = web.Application([
    (r'/ws', WSHandler),
])

@gen.coroutine
def process_drv_socket(sock):
    """
    Periodically called function for processing the api driver's socket
    """
    sock.drvsend('test')
    yield sock.drvreceive()

# how fast should we process the driver socket (ms)
LINK_RATE = 2000
# how fast should we time out when processing the driver socket (ms)
LINK_TIMEOUT = 3000

WS_SERV_PORT = 8675
API_SERV_PORT = 60002
API_SERV_IP = '127.0.0.1'

if __name__ == "__main__":
    http_server = httpserver.HTTPServer(application)
    http_server.listen(WS_SERV_PORT)

    # assume nothing fails here...
    drvsock = DriverClient()
    drvsock.connect(API_SERV_IP, API_SERV_PORT)

    try:
        print(
            'Starting IOLoop with http server for websockets and driver socket'
        )

        # TODO: if coroutines...
        # TODO: works for a single loop, then stops. figure out how to keep
        #       going.
        # NOTE: don't mix this with a call to IOLoop.instance().start()
        # ioloop.IOLoop.instance().run_sync(lambda: process_drv_socket(drvsock))

        # TODO: this is using the callback style. other things use the
        #       coroutine style. pick one.
        # background processs of driver socket every LINK_RATE milliseconds
        drvsock_task = ioloop.PeriodicCallback(lambda: process_drv_socket(drvsock), LINK_RATE)
        drvsock_task.start()

        # start the ioloop
        ioloop.IOLoop.instance().start()

    except KeyboardInterrupt:
        http_server.stop()
        drvsock_task.stop()
        drvsock.close()
        print('KeyboardInterrupt: Killed the server')
