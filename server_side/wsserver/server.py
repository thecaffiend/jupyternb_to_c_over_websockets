from tornado import websocket

import json

class WSHandler(websocket.WebSocketHandler):
    # Set of connected WSHandlers
    _connections = set()
    # TODO: there has to be a better way to make this data available to the
    #       server_main processor. This assumes only one client (other clients'
    #       commands will go here too...
    _cmd_list = []

    @staticmethod
    def send_to_connections(msg):
        """
        """
        # send the incoming message to all connected clients for processing
        # TODO: determine if there are any threading issues here...
        [con.write_message(msg) for con in WSHandler._connections]

    def open(self):
        """
        """
        print('new connection')
        # Each connection should have a differrent WSHandler, so store them
        # in the class's _connections
        WSHandler._connections.add(self)
        # TODO: debug, remove or make more useful
        self.write_message("Hello World")

    def on_message(self, message):
        """
        """
        print('message received in WSHandler')
        try:
            self._handle_message(json.JSONDecoder().decode(message))
        except json.JSONDecodeError:
            print('Could not deserialize the incoming message: %s' % (message))

    def on_close(self):
        """
        """
        print('connection closed')
        # remove us from the list
        WSHandler._connections.remove(self)

    def _handle_message(self, message):
        """
        Handle the incomming message. Could have more than one command included
        """
        if hasattr(message, 'items'):
            # TODO: dicts here, or switch out with wrapped header structs?
            #       either way, clean up
            WSHandler._cmd_list.append(message)

        else:
            # not normal case (except for debug), print message as a string
            print('WSHandler processed message: %s' % (message))
