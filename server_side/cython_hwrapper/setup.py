from distutils.core import setup
from distutils.extension import Extension

from Cython.Build import cythonize

extensions = [
    Extension(
        'header_wrapper',
        ['header_wrapper.pyx'],
        include_dirs = ['../../c_driver/include']), # fix this for you...
    ]

setup(
  name = 'C Header Python Wrapper for Cython <-> C over Unix sockets',
  ext_modules = cythonize(extensions),
)
