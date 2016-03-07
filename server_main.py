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
def process_all(drvsock):
    """
    """
    # TODO: make this so we're not passing the socket (actually TCP client)
    #       around everywhere...
    process_drv_socket(drvsock)
    process_ws_commands(drvsock)

@gen.coroutine
def process_drv_socket(sock):
    """
    Periodically called function for processing the api driver's socket
    TODO: rename this function and arguments (not a sock)
    """
    sock.drvsend('test')
    yield sock.drvreceive()

@gen.coroutine
def process_ws_commands(sock):
    """
    """
    print('processing commands from wsclients')
    cmds = list(WSHandler._cmd_list)
    del WSHandler._cmd_list[:]
    for cmd, cmd_val in cmds:
        print('   Processing cmd [%s] with val [%s]' % (cmd, cmd_val))
        # TODO: actually do stuff with the messages here, like pass them to the
        #       API server.
        sock.handle_ws_command(cmd, cmd_val)

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

        # background processs every LINK_RATE milliseconds
        proc_task = ioloop.PeriodicCallback(lambda: process_all(drvsock), LINK_RATE)
        proc_task.start()

        # start the ioloop
        ioloop.IOLoop.instance().start()

    except KeyboardInterrupt:
        http_server.stop()
        proc_task.stop()
        drvsock.close()
        print('KeyboardInterrupt: Killed the server')
