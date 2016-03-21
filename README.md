# Websocket server side (with c driver)

Test websocket server interacting with a c driver. This side has a
a websocket server that communicates with a c driver over native sockets.
Commands come via a websocket to go to the driver, and data comes from the
driver to be sent over the websocket.

## Dependencies
* Anaconda 2.5.0 Envrionment (python 3.4)
 * tornado
 * pep8
 * ipython
 * cython (0.23.4 used)

## Usage
* Make the environment (assuming Anaconda 2.5.0 is installed)
`conda create --name websocket_dirver_server python=3 tornado pep8`
* Activate the environment
`source activate websocket_driver_server`
* Install new packages (as needed...should be documented here already)
`conda install --name websocket_server [packages]` or (in the activated
environment)`pip install [packages]`
* Run websocket server (needs its own process) from the server_side dir
`python server_main.py`

## TODO:
* make able to send/receive custom messages
* get working with c driver over sockets
 * implement a way to send all driver messages to all clients (or register
   message types of interest)
