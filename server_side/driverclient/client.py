"""
Adapted from: https://docs.python.org/3.4/howto/sockets.html

TODO: Get this based on tornado TCPClient class instead of this half baked
      thing
TODO: Do co-routines *or* callbacks. This goes for the whole thing, not just
      this class.
"""
import logging

import socket
from tornado import (
    gen,
)

# Cython header_wrapper stuff
from header_wrapper import (
    MHListItem,
    MHItemList,
    MAX_NAME_LEN,
    SCHeader,
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
    def drvsend(self, msgbytes):
        """
        Send the bytes to the driver.
        msgbytes: bytes like object to send to the c app.
        """
        totalsent = 0

        # TODO: make this check the length and send chucked if needed
        #       robust
        # while totalsent < MSGLEN:
        #     sent = self.sock.send(msg[totalsent:])
        #     if sent == 0:
        #         raise RuntimeError("socket connection broken")
        #     totalsent = totalsent + sent
        sent = self.sock.send(msgbytes)

#        sent = self.sock.send(msg.encode())

        return sent

    @gen.coroutine
    def drvreceive(self):
        """
        Receive from the driver.
        """
        chunks = []
        bytes_recd = 0
        # TODO: hack so MSGLEN is defined. fix
        MSGLEN = 4096
        # TODO: get chunked read working
        # while bytes_recd < MSGLEN:
        #     chunk = self.sock.recv(min(MSGLEN - bytes_recd, 2048))
        #     if chunk == b'':
        #         raise RuntimeError("socket connection broken")
        #     chunks.append(chunk)
        #     bytes_recd = bytes_recd + len(chunk)
        # return b''.join(chunks)

        ret = self.sock.recv(MSGLEN)
        # TODO: either need to convert this to something to send back to the
        #       WS clients, or move that logic elsewhere. since incoming WS
        #       msgs are converted to header_wrapper objects before drvsend,
        #       seems the opposite should go in this class too...
        # TODO: make another method called from the server to get the results
        #       from here (like handle_ws_msg in the other direction). That's
        #       where the conversion of bytes to objects should happen.
        logging.info('Received %s from the API server', ret)

        # convert to object for other side
        msg = self._convert_drv_msg(ret)
        return msg

    def close(self):
        """
        Close our socket.
        """
        self.sock.close()

    # @gen.coroutine
    # def handle_ws_command(self, cmd, cmd_val):
    #     """
    #     Handle a command from the wsserver.
    #     NOTE: DEPRECATED, DO NOT USE
    #     """
    #     print('DriverClient is handling (%s, %s)' % (cmd, cmd_val))
    #     sent =  self.drvsend("{%s, %s}" % (cmd, cmd_val))
    #     return sent

    def _convert_drv_msg(self, msgbytes):
        """
        Convert the incoming C app message to dict expected by the WS clients
        """
        # TODO: error check the incomming message (vals, bounds of list, etc)
        # TODO: add a way to get things like msg['header']['type'] without
        #       having to know about 'header' or 'type' key strings (shared
        #       class def with get methods for the fields of interest perhaps?)

        # if things went well, we can construct an MHItemList straight from the
        # incoming bytes for now (as it's an echo of what we sent).
        # TODO: check incoming message for type and construct right objects
        #       accordingly. doesn't matter while we only have one real message
        #       type

        mhil = MHItemList()
        mhil.frombytes(msgbytes)

        # for now we need to convert this message to the dict type used by the
        # WS clients.
        # TODO: There should be a shared class for this data type
        msg = {
            'header': {
                'type': mhil.header.htype,
                'status': mhil.header.hstatus,
                'code': mhil.header.hcode,
            },
            'listitems': [], # list of dicts
        }

        for mhli in mhil.item_list:
            li = {
                'type': mhli.item_type,
                'name': mhli.name_str,
            }
            msg['listitems'].append(li)

        return msg

    @gen.coroutine
    def handle_ws_msg(self, msg):
        """
        Handle a message (dict) from the wsserver.
        :param dict msg: dict to send as message to server. this dict will have
                         a header (to make an SCHeader from) and a list of
                         items (to make a MHItemList of MHListItem objects
                         from)
        """
        logging.info('Server\'s DriverClient is converting WS Msg %s', msg)
        mhil = self._convert_ws_msg(msg)
        logging.info('Server\'s DriverClient is sending converted msg bytes')
        sent =  self.drvsend(mhil.tobytes())
        #sent =  self.drvsend("%s" % (msg))
        return sent

    def _convert_ws_msg(self, msg):
        """
        Convert the incoming WS message to object from header_wrapper for
        sending to the C app.
        """
        # TODO: error check the incomming message (vals, bounds of list, etc)
        # TODO: add a way to get things like msg['header']['type'] without
        #       having to know about 'header' or 'type' key strings (shared
        #       class def with get methods for the fields of interest perhaps?)
        mhil = MHItemList()

        # setup te header
        mhil.header.htype = msg['header']['type']
        mhil.header.hstatus = msg['header']['status']
        mhil.header.hcode = msg['header']['code']
        # TODO: look at switching hlength to be number of bytes of the message
        #       (including header) instead of the number of list items. better
        #       for general usage
        mhil.header.hlength = len(msg['listitems'])

        # and now make list items and add them to the list for the C app
        for li in msg['listitems']:
            mhli = MHListItem()
            mhli.item_type = li['type']
            # this field is the same as the header htype. just cause
            mhli.sc_msg_type = mhil.header.htype
            mhli.name_str = li['name']

            mhil.item_list.append(mhli)

        return mhil

    # TODO: just for testing, remove
    def test_echo(self):
        self.connect("127.0.0.1", 60002)
        self.drvsend("test")
        self.drvreceive()
        self.sock.close()
