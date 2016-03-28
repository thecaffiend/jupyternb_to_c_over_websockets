# Jupyter Notebook to C application via Websockets
Example of using websockets to provide communications between a Jupyter Notebook and a C application.

*This doc is being updated.* For now consider it _almost right_. Once merged
to master, it should be right.

### General Dependencies

### General TODO

## C Driver (c_driver) Specifics
C application for acting as a socket server, sending/receiving commands from
a websocket server.

### c_driver Dependencies
* gcc

### C Driver Usage
* Build the driver.
 * cd to the c_driver directory
 * run `gcc driver.c -o driver`
 * ignore warnings for now
* run the driver with `./driver`. This should be started before the
  server_side/server_main.py is.

### C Driver TODO:
*

## Websocket Server (server_side) Specifics

Test websocket server interacting with a c driver. This side has a
a websocket server that communicates with a c driver over native sockets.
Commands come via a websocket to go to the driver, and data comes from the
driver to be sent over the websocket.

### server_side Dependencies
* Anaconda 2.5.0 Envrionment (python 3.4)
 * tornado
 * pep8
 * ipython
 * cython (0.23.4 used)

### server_side Usage
* Make the environment (assuming Anaconda 2.5.0 is installed)
`conda create --name websocket_dirver_server python=3 tornado pep8`
* Activate the environment
`source activate websocket_driver_server`
* Install new packages (as needed...should be documented here already)
`conda install --name websocket_server [packages]` or (in the activated
environment)`pip install [packages]`
* Run websocket server (needs its own process) from the server_side dir
`python server_main.py`

### server_side TODO:
* make able to send/receive custom messages
* get working with c driver over sockets
 * implement a way to send all driver messages to all clients (or register
   message types of interest)

## Websocket Client and Jupyter Notebook (client_side) Specifics

Test websocket client interacting with a Jupyter notebook. This side has as
a websocket client that sits in front of a jupyter notebook. Commands come
from the notebook to be sent to the server, and data comes from the server to
display on the notebook.

### client_side Dependencies
* Anaconda 2.5.0 Envrionment (python 3.4)
* tornado
* jupyter
* notebook
* pep8

### client_side Usage
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

### client_side TODO:
* make able to send/receive custom messages
* customizable ports
* jupyter config values (python path)
* server extensions
* for our web socket handler (says REST in the docs, but the websocket class
  extends from request handler, which is what is needed. Can we do this
  since it's a client?
* for the socket client from the c side? can this be combined with the
  websocket handler? Can we even do this since it's a client?

### client_side Notes:
* There's a test client (blocking) from the client_side dir:
 `python client_main.py`
