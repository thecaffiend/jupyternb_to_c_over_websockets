# Jupyter Notebook to C application via Websockets
Example of using websockets to provide communications between a Jupyter
Notebook and a C application. This was not an exercise in making all the right
decisions, but more about getting something working to prove a concept. Any
advice/criticism from internet land is welcome to learn from though. This was
all tested on Linux (Ubuntu Wiley) only to date. YMMV.

Interesting topics in this example:
* WebSockets comms from a Jupyter notebook to some websocket server
* Those same websocket comms being directed to a C application via a Unix
  socket
* (To come) Wrapping of C structs (used by the C app) for use in Python (using
  Cython), and using those structs as the interface of the Unix socket.
* A "server" (really a server/client) handling both websockets and unix sockets
  at the same time.
* Having the data returned from the C app to the WebSocket client (in the
  notebook) update a display element (currently a Matplotlib figure).
* (Eventually) Custom ipywidgets for use in the notebook.

*This doc is being updated.* Especially the dependencies until requirements.txt
Files are maintained. If problems are found, please drop a line.

### General Dependencies
* [Anaconda](https://www.continuum.io/why-anaconda) - Both the client_side and
  server_side have separate Python3 (3.5) environments with different
  dependencies. Anaconda is used to manage the environments.
* IPython - Installed with Anaconda and absolutely required for all the Python
  things

### General TODO
* Better documentation (README and code...especially code)
* Clean up coroutines vs callbacks on the Python side (go with coroutines)
* Better encapsulation where warranted on the Python side.
* Add logger instead of print's in client/server
* look at Jupyter server extensions
 * for our web socket handler (says REST handler needed in the Jupyter docs,
   but the websocket class extends from request handler, which is what is
   needed. Can we do this since it's a client too?)
 * for the socket client from the c side? can this be combined with the
   websocket handler? Can we even do this since it's a client?


## C Driver (c_driver) Specifics
C application for acting as a Unix socket server, sending/receiving data from
a websocket server (acting as a client of this application).

### c_driver Dependencies
* gcc

### C Driver Usage
* Build the driver.
 * cd to the c_driver directory
 * run `./builddriver.sh`
 * ignore warnings for now
* run the driver with `./driver`. This should be started before the
  server_side/server_main.py is.

### C Driver TODO:
* Rather than echoing what's received, do something with it.
* Print diagnostics.
* Include dummy header files (to show struct usage between driver and
  server_side)
* Investigate an ipywidget for a console to run this from (so everything can
  be in a notebook environment).

## Websocket Server (server_side) Specifics
This side has a websocket server that communicates with a C application over
native Unix sockets, using (eventually) C structs wrapped for Python (using
Cython) as the interface. Messages come to this server from websocket clients,
then go to the C app, and data comes from the C app to be sent over the
websocket back to the clients.

### server_side Dependencies
When stable, this application will include a requirements.txt file. For now,
this list will be manually kept up to date.
* tornado
* pep8
* ipython
* cython

### server_side Cython Wrapper
This is the wrapper that makes the C Header declarations available in python.

### server_side Usage
* Make the environment (assuming Anaconda is installed and on the path)
`conda create --name websocket_dirver_server python=3 tornado pep8`
* Activate the environment:
`source activate websocket_driver_server`
* Install new packages (as needed...should be documented here already)
`conda install --name websocket_driver_server [packages]` or (in the activated
environment)`pip install [packages]`
* Build the Cython header Wrapper
 * cd to the cython_wrapper directory
 * run `./build_inplace.sh`
 * to remove the built files (again from the cython_wrapper dir), run
   `./clean_built.sh`
 * from the cython_wrapper directory, run `python test_all.py` to test the
   build.
* Run websocket the server (needs its own process) from the server_side dir
`python server_main.py`
* NOTE: this should be a jupyter notebook of it's own soon.

### server_side TODO:
* make able to send/receive custom message dicts from the clients
* get structs working with c driver over sockets
 * implement a way to for websocket clients to register message types of
   interest (very low priority)
* make a notebook for the server (with the kernel pointed to the conda env for
  the server). [That process is here](http://ipython.readthedocs.org/en/stable/install/kernel_install.html)

## Websocket Client and Jupyter Notebook (client_side) Specifics
Test websocket client interacting with a Jupyter notebook. This side has as
a websocket client that sits in a jupyter notebook. Data from the notebook is
sent to the server, and data comes from the server to display on the notebook
(and update a graphical display element).

### client_side Dependencies
* tornado
* jupyter
* notebook
* pep8

### client_side Usage
* Make the environment (assuming Anaconda is installed and on the path)
`conda create --name websocket_ui_client python=3 tornado jupyter notebook pep8`
* Activate the environment
`source activate websocket_ui_client`
* Install new packages (as needed...should be documented here already)
`conda install --name websocket_ui_client [packages]` or `pip install [packages]`
* Run notebook server (blocking) `jupyter notebook --port [port_num]`
* Load the notebook 'WebsocketClient Sandbox'
* Have fun. Run the cells in order. Hopefully I'll have time to document things
  in the notebook better soon.

### client_side TODO:
* make able to send/receive custom messages (to be used server_side for filling
  in C struct wrappers)
* customizable ports (really, customizable many things)
* jupyter config values (python path, etc)

### client_side Notes:
* There's a test client (blocking) from the client_side dir:
 `python client_main.py`
