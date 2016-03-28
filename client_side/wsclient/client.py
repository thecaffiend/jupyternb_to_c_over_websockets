"""
Simple Web socket client implementation using Tornado framework.

Stolen/adapted from here:
    http://code.activestate.com/recipes/579076-simple-web-socket-client-implementation-using-torn/

"""

# TODO: make sure all these imports are used/needed
from tornado import (
    escape,
    gen,
    httpclient,
    httputil,
    ioloop,
    websocket,
)

import functools
import json
import time

# TODO: Document the things!
# TODO: Coroutines, remove callbacks

APPLICATION_JSON = 'application/json'

# seconds
DEFAULT_CONNECT_TIMEOUT = 10
DEFAULT_REQUEST_TIMEOUT = 60

# for debug prints
WSCLIENTID = "client_side.WebSocketClient"
TWSCLIENTID = "client_side.TestWebSocketClient"

class WebSocketClient():
    """Base for web socket clients.
    """

    def __init__(self, *, connect_timeout=DEFAULT_CONNECT_TIMEOUT,
                 request_timeout=DEFAULT_REQUEST_TIMEOUT):

        self.connect_timeout = connect_timeout
        self.request_timeout = request_timeout
        print("WebSocketClient.__init__: cto, rto = %s, %s" % (self.connect_timeout, self.request_timeout))

    @gen.coroutine
    def connect(self, url):
        """Connect to the server.
        :param str url: server URL.
        """
        print("WebSocketClient.connect: attempting connection to: %s" % (url))
        headers = httputil.HTTPHeaders({'Content-Type': APPLICATION_JSON})
        request = httpclient.HTTPRequest(url=url,
                                         headers=headers,
                                         connect_timeout=self.connect_timeout,
                                         request_timeout=self.request_timeout)
        ws_conn = websocket.websocket_connect(request)
        print("WebSocketClient.connect: ws_conn is: %s" % (ws_conn))
        print("WebSocketClient.connect: adding to ioloop (%s)" % (ioloop.IOLoop.current()))
        ioloop.IOLoop.current().add_future(ws_conn, self._connect_callback)
        print("WebSocketClient.connect: done")


    def send(self, data):
        """Send message to the server
        :param str data: message.
        """
        if not self._ws_connection:
            raise RuntimeError('Web socket connection is closed.')

        # TODO: remove print (debug) and make one liner write_message
        jdata = escape.utf8(json.dumps(data))
        print('WSC: sending WSS %s' % (jdata))
        self._ws_connection.write_message(escape.utf8(json.dumps(data)))

    def close(self):
        """Close connection.
        """
        if not self._ws_connection:
            raise RuntimeError('Web socket connection is already closed.')

        self._ws_connection.close()

    def _connect_callback(self, future):
        """
        """
        if future.exception() is None:
            self._ws_connection = future.result()
            self._on_connection_success()
            self._read_messages()
        else:
            print("WSClient._connect_callback: exception caught %s" % (future.exception()))
            self._on_connection_error(future.exception())

    @gen.coroutine
    def _read_messages(self):
        """
        """
        while True:
            msg = yield self._ws_connection.read_message()
            if msg is None:
                self._on_connection_close()
                break

            self._on_message(msg)

    def _on_message(self, msg):
        """This is called when new message is available from the server.
        :param str msg: server message.
        """
        pass

    def _on_connection_success(self):
        """This is called on successful connection ot the server.
        """
        pass

    def _on_connection_close(self):
        """This is called when server closed the connection.
        """
        pass

    def _on_connection_error(self, exception):
        """This is called in case if connection to the server could
        not established.
        """
        pass

# TODO: rename this class intelligently. it's no longer a TestWebSocketClient
#       but is more specialized.
class TestWebSocketClient(WebSocketClient):
    def __init__(self):
        super().__init__()
        self._msgcallback = None

    def _on_message(self, msg):
        """
        """
        # handle the message coming in from the driver side (via the WSHandler)
        # TODO: something other than callbacks?
        print('%s._on_message: precessing %s from the server_side' % (TWSCLIENTID, msg))
        if self._msgcallback:
            print('calling callback!')
            self._msgcallback(msg)
        else:
            print('callback not yet defined, cannot process %s' % (msg))

    def _on_connection_success(self):
        """
        """
        print('Connected to Websocket Server!')

    def _on_connection_close(self):
        """
        """
        print('Connection to Websocket Server closed!')

    def _on_connection_error(self, exception):
        """
        """
        print('Connection error: %s', exception)

    def msg_callback(self, cb):
        """
        """
        self._msgcallback = cb;
