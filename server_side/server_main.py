from tornado import (
    web,
    ioloop,
    gen,
)

from wsserver.server import WSHandler
from driverclient.client import DriverClient

# TODO: document this stuff! module level and all
# TODO: this file is feeling might full. break up

# Main application
application = web.Application([
    (r'/ws', WSHandler),
])

# TODO: get a common logger going...
# for debug prints.
SRVMAINID = "server_side.server_main"

@gen.coroutine
def process_all(drvsock):
    """
    """
    # for debug prints.
    # TODO: Get all the things printing via a common method and format
    FUNCID = "%s.process_all" % (SRVMAINID)

    # TODO: make this so we're not passing the socket (actually TCP client)
    #       around everywhere...
    process_drv_socket(drvsock)
    process_ws_commands(drvsock)

@gen.coroutine
def process_drv_socket(sock):
    """
    Periodically called function for processing the api driver's socket
    TODO: rename this function and arguments (not a sock)
    TODO: Make this call a function in the sock (or change sock.drvreceive)
          that uses select to ensure read/write. Same for handle_ws_command
          in the function below. If this is potentially a blocking call, do
          the threadpool stuff in the tornado doc:
          http://www.tornadoweb.org/en/stable/guide/coroutines.html
    """
#    print("%s.process_drv_socket: processing from c app socket" % (SRVMAINID))
    rec_future = sock.drvreceive()
    ioloop.IOLoop.current().add_future(rec_future, handle_drvmsg)

def handle_drvmsg(future):
    """
    """
    if future.exception() is None:
        msg = future.result()
        print('%s.handle_drvmsg: got %s from drv socket, sending on' % (SRVMAINID, msg))
        WSHandler.send_to_connections(msg)
    else:
#        print('%s.handle_drvmsg: exception %s getting msg from drv socket' % (SRVMAINID, future.exception()))
        # TODO: handle exception...
        pass


@gen.coroutine
def process_ws_commands(sock):
    """
    """
    # TODO: don't touch the data member directly, make getting this list a
    #       static method
    cmds = list(WSHandler._cmd_list)
#    print("%s.process_ws_commands: processing commands from wsclients %s" % (SRVMAINID, cmds))
    del WSHandler._cmd_list[:]
    for cmd, cmd_val in cmds:
        print('   Processing cmd [%s] with val [%s]' % (cmd, cmd_val))
        sock.handle_ws_command(cmd, cmd_val)

# how fast should we process the driver socket (ms)
LINK_RATE = 2000
# how fast should we time out when processing the driver socket (ms)
LINK_TIMEOUT = 3000

WS_SERV_PORT = 8675
API_SERV_PORT = 60002
API_SERV_IP = '127.0.0.1'

if __name__ == "__main__":
    print("Starting http server for websocket on %s" % (WS_SERV_PORT))
    application.listen(WS_SERV_PORT)

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
        print("Starting IOLoop periodic callback...")
        proc_task.start()

        # start the ioloop
        # TODO: Change this to use current() instead of instance()
        print("Starting Main IOLoop (%s)..." % (ioloop.IOLoop.instance()))
        ioloop.IOLoop.instance().start()

    except KeyboardInterrupt:
        # TODO: Does application need to be stopped?
        proc_task.stop()
        drvsock.close()
        print('KeyboardInterrupt: Killed the server')
    except Exception as inst:
        print("UNEXPECTED EXCEPTION")
        print(type(inst))
        print(inst.args)
        print(inst)
