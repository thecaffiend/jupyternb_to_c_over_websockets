# test application
from tornado import ioloop

from wsclient.client import TestWebSocketClient

def main():
    client = TestWebSocketClient()
    client.connect('ws://127.0.0.1:8675/ws')

    try:
        ioloop.IOLoop.instance().start()
    except KeyboardInterrupt:
        client.close()


if __name__ == '__main__':
    main()
