# TODO: check all imports for usage
from cpython.mem cimport (
    PyMem_Malloc,
    PyMem_Free,
)

from cpython cimport (
    array,
)
import array

from libc.string cimport (
    memset,
    memcpy,
    strlen,
    strncpy,
)

from header_wrapper cimport (
    # structs
    MH_LIST_ITEM_t,
    MH_ITEM_LIST_t,
    SC_HEADER_t,
    # enums
    SC_MSG_TYPES_t,
    # defines/constants
    MH_MAX_NAME_LEN,
    MH_MAX_ITEMS,
)

from libc.stdint cimport int32_t, uint32_t

# TODO: Meta TODO, look for TODO's in code below
# TODO: break this up into multiple files. about to add wrapper classes for
#       things and this will get unweildly
# TODO: is bytearray or bytes better than using array.array?
# TODO: make get_bytes/from_bytes properties? one property (asbytes or somesuch
#       and use the implementations as is for __get_ and __set__)?
# TODO: for from_bytes/get_bytes methods (or property), maintain internal
#       array and manipulate that as needed? array has tobytes/frombytes
#       methods already
# TODO: replace the sizeof's with the len methods or self._bytesize
# TODO: Error checking on value/property sets (like lengths, etc)!
# TODO: see what can be moved into a common base class that these extend (like
#       common properties, __len__ - if a wrapped type is known, etc)
# TODO: Using PyMem_Free and PyMem_Malloc, which require the GIL to be aquired.
#       has not been an issue yet, but look into if this will be a problem, and
#       if so, look into the Py_RawXXX versions that don't require it (or,
#       aquire the GIL)
# TODO: switching to a base class with void* _data makes the subclasses a bit
#       simpler, but requires casting the ptr type everywhere. What's a better
#       way? using the wrapped type in a union instead might work (see above),
#       but seems the common methods that operate on _data would need to know
#       the right type, right (like to deallocate the right pointer). Have
#       thought about this for a whole 5 miutes...
###

# struct wrappers

# this gives access from python to the structs as dicts with keys equal to the
# struct fields. it *does not* respect things like name lengths, types (nameStr
# can be set to anything), so those have to be added in extension classes like
# below (MHListItem).
# TODO: MHListItem operates on the struct pointer, not a dict. update that or
#       do everything the same (unless providing an example)

# TODO: wrap these dicts to protect types (e.g. MH_LIST_ITEM['nameStr'] can be
#       assigned non-b'' strings if you want) and to enforce length constraints
#       (thought the buffer is supposed to be 32 chars, it will happily take
#       more, which I imagine will cause problems when used in the
#       MH_ITEM_LIST and converted to a byte array).
cpdef  SC_HEADER_t _SC_HEADER
SC_HEADER = _SC_HEADER

cpdef  MH_LIST_ITEM_t _MH_LIST_ITEM
MH_LIST_ITEM = _MH_LIST_ITEM

cpdef  MH_ITEM_LIST_t _MH_ITEM_LIST
MH_ITEM_LIST = _MH_ITEM_LIST

# enum wrappers and values
cpdef  SC_MSG_TYPES_t _SC_MSG_TYPES
SC_MSG_TYPES = _SC_MSG_TYPES
GET_REQ = SC_GET_REQ
GET_RESP = SC_GET_RESP
SET_REQ = SC_SET_REQ
SET_RESP = SC_SET_RESP
END_MSG_TYPE = SC_END_MSG_TYPE

# consts
MAX_NAME_LEN = MH_MAX_NAME_LEN
MAX_LIST_ITEMS = MH_MAX_ITEMS

GET_REQ = SC_GET_REQ
GET_RESP = SC_GET_RESP
SET_REQ = SC_SET_REQ
SET_RESP = SC_SET_RESP
END_MSG_TYPE = SC_END_MSG_TYPE

# relevant cython links for extension types/methods:
# http://docs.cython.org/src/userguide/extension_types.html
# http://docs.cython.org/src/userguide/special_methods.html#special-methods

# TODO: any benefit to using this instead of the void* for _data?
#   cdef union WrappedPtr:
#       SC_HEADER_t* sh
#       MH_LIST_ITEM_t* li
#       MH_ITEM_LIST_t* il
#
#   It can be added to the base class with:
#       `cdef WrappedPtr _wrapped_ptr`
#   and accessed in the subclasses with (e.g. MH_LIST_ITEM_t* is the wrapped
#   type desired and self._bytesize has been set already):
#       `self._wrapped_ptr.li = <MH_LIST_ITEM_t*> PyMem_Malloc(self._bytesize)`
#   It might help with knowing the type/size without having it directly

cdef class WrapperBase:
    """
    Base class for all of our wrapped items. defines common methods and
    data structures.
    """
    # the buffer for our wrapped item
    cdef void* _data
    # the size of the wrapped item
    cdef readonly int _bytesize
    # TODO: would really like a place to store the wrapped type (so we can use
    #       it when raising error and such)

    def __dealloc__(self):
        """
        Deallocate the memory for the internal _data ptr.
        """
        if self._data != NULL:
            PyMem_Free(self._data)

    def tobytes(self):
        """
        Returns a copy of the wrapped _data pointer as an array of bytes.
        """
        cdef array.array arraytemplate = array.array('B', [])
        cdef array.array bites
        bites = array.clone(arraytemplate, self._bytesize, zero=True)
        memcpy(bites.data.as_voidptr, self._data, self._bytesize)
        return bites

    def frombytes(self, bitelike):
        """
        Sets the value of the _data pointer to the contents of the passed in
        bytes-like object
        """
        cdef array.array bites
        if len(bitelike) != self._bytesize:
            # Not the right size. raise an error
            raise ValueError(
                'WrapperBase.fromdata expected bitelike size to be %s but ' \
                'got size %s.' % (self._bytesize, len(bitelike))
            )
        # we can try to set with this...
        bites = array.array('B', bitelike)
        memcpy(self._data, bites.data.as_voidptr, self._bytesize)


cdef class MHListItem(WrapperBase):
    """
    Class wrapping the list item struct.
    """

    def __cinit__(self):
        """
        C-Like initialization for the class
        """
        # set the size to what we should be
        self._bytesize = sizeof(MH_LIST_ITEM_t)
        # allocate memory for the internal struct
        self._data = <MH_LIST_ITEM_t*> PyMem_Malloc(self._bytesize)

        # if it's NULL, that's bad...
        if self._data == NULL:
          raise MemoryError("Could not allocate memory for a MHListItem!")

        # otherwise, party. initialize the struct to 0's
        memset(self._data, 0, self._bytesize)

    def __len__(self):
        """
        Return size of self._data ptr. Set in __cinit__
        """
        return self._bytesize

    property item_type:
        """
        Get/set the internal struct's itemType.
        """
        def __get__(self):
            return (<MH_LIST_ITEM_t*>self._data).itemType

        def __set__(self, int32_t li):
            (<MH_LIST_ITEM_t*>self._data).itemType = li

    property sc_msg_type:
        """
        Get/set the internal struct's scMsgType.
        """
        def __get__(self):
            return (<MH_LIST_ITEM_t*>self._data).scMsgType

        def __set__(self, int32_t smt):
            (<MH_LIST_ITEM_t*>self._data).scMsgType = smt

    property name_str:
        """
        Get/set the internal struct's nameStr.
        """
        def __get__(self):
            # nameStr is a bytes_string
            return (<MH_LIST_ITEM_t*>self._data).nameStr.decode('UTF-8')

        def __set__(self, const char* ns):
            # ns should be converted to bytes before here.
            # TODO: error check for bytes/const char* of arg. or should we just
            #       take a string and go?
            name_sz = MH_MAX_NAME_LEN - 1
            ns_len = strlen(ns)
            # check if new name is too long.
            # TODO: Truncate for now, but consider throwing error...
            cpy_len = name_sz if ns_len >= MH_MAX_NAME_LEN else ns_len

            # good citizen, zero the mem and then copy the string
            memset((<MH_LIST_ITEM_t*>self._data).nameStr, 0, MH_MAX_NAME_LEN)
            memcpy((<MH_LIST_ITEM_t*>self._data).nameStr, ns, cpy_len)
