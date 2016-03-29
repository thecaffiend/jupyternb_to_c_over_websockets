#!/usr/bin/env bash

# clean/delete the files built by build_inplace.sh
# assumes it's run from the cython_wrapper directory
rm -f *.so header_wrapper.c
rm -rf ./build
