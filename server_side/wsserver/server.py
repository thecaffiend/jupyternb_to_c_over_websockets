from tornado import websocket

import json

class WSHandler(websocket.WebSocketHandler):
    _clients = []
    # TODO: there has to be a better way to make this data available to the
    #       server_main processor. This assumes only one client (other clients'
    #       commands will go here too...
    _cmd_list = []

    def open(self):
        print('new connection')
        # keep track of the client so we can ping back
        WSHandler._clients.append(self)
        self.write_message("Hello World")

    def on_message(self, message):
        print('message received in WSHandler')
        try:
            self._handle_message(json.JSONDecoder().decode(message))
        except json.JSONDecodeError:
            print('Could not deserialize the incoming message: %s' % (message))

    def on_close(self):
        print('connection closed')
        # remove us from the list
        WSHandler._clients.append(self)

    def _handle_message(self, message):
        """
        Handle the incomming message. Could have more than one command included
        """
        if hasattr(message, 'items'):
            # this is the normal case when not debugging, a dict
            for cmd, cmd_val in message.items():
                print('message received (%s: %s)' % (cmd, cmd_val))
                # actually handle here...
                WSHandler._cmd_list.append((cmd, cmd_val))
        else:
            # not normal case (except for debug), print message as a string
            print('WSHandler processed message: %s' % (message))
