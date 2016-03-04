from tornado import websocket

class WSHandler(websocket.WebSocketHandler):
    def open(self):
        print('new connection')
        self.write_message("Hello World")

    def on_message(self, message):
        print('message received %s' % message)

    def on_close(self):
      print('connection closed')
