"""
Adapted from: https://docs.python.org/3.4/howto/sockets.html
"""

import socket

class DriverSocket:
    """
    Socket for talking to the c driver socket server.
    TODO: Currently blocking, make non-blocking
    TODO: Send/receive both need MSGLEN, and need to format the msgs right
          (bytes-like objects).
    """

    def __init__(self, sock=None):
        """
        """
        if sock is None:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            # TODO: set non-blocking and use select to determine when to read
            # socket.setblocking(0)
        else:
            self.sock = sock

    def connect(self, host, port):
        """
        Connect to the driver's socket.

        :param str host: Host IP address
        :param int port: Port to connect to
        """
        self.sock.connect((host, port))

    def drvsend(self, msg):
        """
        Send to the driver.
        :param str msg: String message to convert to a bytes-like object and
                        send to the server.
        """
        totalsent = 0
        # for now this is a string, so just encode it and send
        sent = self.sock.send(msg.encode())

        # while totalsent < MSGLEN:
        #     sent = self.sock.send(msg[totalsent:])
        #     if sent == 0:
        #         raise RuntimeError("socket connection broken")
        #     totalsent = totalsent + sent

    def drvreceive(self):
        """
        Receive from the driver.
        """
        chunks = []
        bytes_recd = 0
        # TODO: hack so MSGLEN is defined. fix
        MSGLEN = 2048
        # TODO: get chunked read working
        ret = self.sock.recv(2048)
        print(ret)
        return ret
        # while bytes_recd < MSGLEN:
        #     chunk = self.sock.recv(min(MSGLEN - bytes_recd, 2048))
        #     if chunk == b'':
        #         raise RuntimeError("socket connection broken")
        #     chunks.append(chunk)
        #     bytes_recd = bytes_recd + len(chunk)
        # return b''.join(chunks)

    def test_echo(self):
        self.connect("127.0.0.1", 60002)
        self.drvsend("test")
        self.drvreceive()
        self.sock.close()
