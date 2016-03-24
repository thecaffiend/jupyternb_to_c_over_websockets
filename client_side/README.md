# Websocket client side (UI in Jupyter Notebook)

Test websocket client interacting with a Jupyter notebook. This side has as
a websocket client that sits in front of a jupyter notebook. Commands come
from the notebook to be sent to the server, and data comes from the server to
display on the notebook.

## Dependencies
* Anaconda 2.5.0 Envrionment (python 3.4)
 * tornado
 * jupyter
 * notebook
 * pep8

## Usage
* Make the environment (assuming Anaconda 2.5.0 is installed)
`conda create --name websocket_ui_client python=3 tornado jupyter notebook pep8`
* Activate the environment
`source activate websocket_ui_client`
* Install new packages (as needed...should be documented here already)
`conda install --name websocket_ui_client [packages]` or `pip install [packages]`
* Run notebook server (blocking) `jupyter notebook --port [port_num]`
* Load the notebook 'WebsocketClient Sandbox'
* Change the client_side_path in the first cell to point at where your
  client_side is
* Have fun.

## TODO:
* make able to send/receive custom messages
* customizable ports
* jupyter config values (python path)
* server extensions
 * for our web socket handler (says REST in the docs, but the websocket class
   extends from request handler, which is what is needed. Can we do this
   since it's a client?
 * for the socket client from the c side? can this be combined with the
   websocket handler? Can we even do this since it's a client?

## Notes:
* There's a test client (blocking) from the client_side dir:
  `python client_main.py`
