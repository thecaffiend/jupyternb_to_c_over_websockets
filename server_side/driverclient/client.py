"""
Adapted from: https://docs.python.org/3.4/howto/sockets.html

TODO: Get this based on tornado TCPClient class instead of this half baked
      thing
TODO: Do co-routines *or* callbacks. This goes for the whole thing, not just
      this class.
"""

import socket
from tornado import (
    gen,
)

class DriverClient:
    """
    Client for talking to the c driver socket server.
    TODO: Send/receive both need MSGLEN, and need to format the msgs right
          (bytes-like objects).
    TODO: Clean up use of coroutines vs callbacks (everywhere)
    """

    def __init__(self, sock=None):
        """
        Create the driver socket
        sock: An already created socket to use
        """
        if sock is None:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        else:
            self.sock = sock

    def connect(self, host, port):
        """
        Connect to the driver's socket.

        host: Host IP address
        port: Port to connect to
        """
        self.sock.connect((host, port))

        # TODO: use select to determine when to read, otherwise this will throw
        #       an occasional exception on read...
        self.sock.setblocking(0)

    @gen.coroutine
    def drvsend(self, msg):
        """
        Send to the driver.
        msg: String message to convert to a bytes-like object and send to the
             server.
        """
        totalsent = 0

        # TODO: for now this is a string, so just encode it and send. make more
        #       robust
        # while totalsent < MSGLEN:
        #     sent = self.sock.send(msg[totalsent:])
        #     if sent == 0:
        #         raise RuntimeError("socket connection broken")
        #     totalsent = totalsent + sent
        sent = self.sock.send(msg.encode())

        return sent

    @gen.coroutine
    def drvreceive(self):
        """
        Receive from the driver.
        """
        chunks = []
        bytes_recd = 0
        # TODO: hack so MSGLEN is defined. fix
        MSGLEN = 2048
        # TODO: get chunked read working
        # while bytes_recd < MSGLEN:
        #     chunk = self.sock.recv(min(MSGLEN - bytes_recd, 2048))
        #     if chunk == b'':
        #         raise RuntimeError("socket connection broken")
        #     chunks.append(chunk)
        #     bytes_recd = bytes_recd + len(chunk)
        # return b''.join(chunks)

        ret = self.sock.recv(2048)
        print('Received %s from the API server' % (ret))
        return ret

    def close(self):
        """
        Close our socket.
        """
        self.sock.close()

    @gen.coroutine
    def handle_ws_command(self, cmd, cmd_val):
        """
        Handle a command from the wsserver.
        """
        print('DriverClient is handling (%s, %s)' % (cmd, cmd_val))
        sent =  self.drvsend("{%s, %s}" % (cmd, cmd_val))
        return sent

    # TODO: just for testing, remove
    def test_echo(self):
        self.connect("127.0.0.1", 60002)
        self.drvsend("test")
        self.drvreceive()
        self.sock.close()
