from tornado import websocket

# TODO: Do better than global...

class WSHandler(websocket.WebSocketHandler):
    _clients = []

    def open(self):
        print('new connection')
        # keep track of the client so we can ping back
        WSHandler._clients.append(self)
        self.write_message("Hello World")

    def on_message(self, message):
        print('message received %s' % message)
        # reply that we got it - good for debug, but starts an infinite loop
        #WSHandler._clients[WSHandler._clients.index(self)].write_message(
        # {
        #  'message': message, 
        #  'it': 'blended'
        # })


    def on_close(self):
        print('connection closed')
        # remove us from the list
        WSHandler._clients.append(self)
