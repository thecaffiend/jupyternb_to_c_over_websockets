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
* Run websocket server (needs its own process) from the server_side dir
`python server_main.py`

## TODO:
* make able to send/receive custom messages
* get working with jupyter notebook
 * Run notebook server (needs its own bash env) `jupyter notebook --port [port_num]`
