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

# Enum for the types of structs that are wrappable
cdef enum __data_type_e:
    HEADER
    LISTITEM
    ITEMLIST

ctypedef __data_type_e DATA_TYPE_t

# union for pointers to wrappable types
cdef union __data_u:
    SC_HEADER_t* sh
    MH_LIST_ITEM_t* li
    MH_ITEM_LIST_t* il

ctypedef __data_u DATA_t

# struct for wrapped data ptr, and it's type
cdef struct __data_type_wrapper_s:
    DATA_TYPE_t type
    DATA_t data

ctypedef __data_type_wrapper_s DATA_WRAPPER_t

cdef class WrapperBase:
    """
    Base class for all of our wrapped items. defines common methods and
    data structures.
    """
    # the size of the wrapped item
    # TODO: either make one method (like __len__ in this base class) for size,
    #       or make the size part of the DATA_WRAPPER_t type
    cdef readonly int _bytesize

    # Our wrapped data and type
    cdef DATA_WRAPPER_t _wrapper

    def __dealloc__(self):
        """
        Deallocate the memory for the internal _data ptr.
        """
        cdef void* p = self.wrapped_ptr()
        if p != NULL:
            PyMem_Free(p)

    cdef void* wrapped_ptr(self):
        """
        Return the wrapped data ptr (the data part of self._wrapper) as a void*
        Convenience for thins like __dealloc__
        """
        cdef void* p = NULL
        if self._wrapper.type == HEADER:
            p = self._wrapper.data.sh
        elif self._wrapper.type == LISTITEM:
            p = self._wrapper.data.li
        elif self._wrapper.type == ITEMLIST:
            p = self._wrapper.data.il
        # TODO: check code using this to make sure it checks for NULL.
        return p

    def tobytes(self):
        """
        Returns a copy of the wrapped _data pointer as an array of bytes.
        """
        cdef array.array arraytemplate = array.array('B', [])
        cdef array.array bites
        bites = array.clone(arraytemplate, self._bytesize, zero=True)
        # TODO: check wrapped_ptr for NULL before using!
        memcpy(bites.data.as_voidptr, self.wrapped_ptr(), self._bytesize)
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
        # TODO: check wrapped_ptr for NULL before using!
        memcpy(self.wrapped_ptr(), bites.data.as_voidptr, self._bytesize)


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
        self._wrapper.type = LISTITEM
        self._wrapper.data.li = <MH_LIST_ITEM_t*> PyMem_Malloc(self._bytesize)

        # if it's NULL, that's bad...
        # TODO: use wrapped_ptr. check wrapped_ptr for NULL before using!
        if self._wrapper.data.li == NULL:
          raise MemoryError("Could not allocate memory for a MHListItem!")

        # otherwise, party. initialize the struct to 0's
        # TODO: use wrapped_ptr. check wrapped_ptr for NULL before using!
        memset(self._wrapper.data.li, 0, self._bytesize)

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
            return self._wrapper.data.li.itemType

        def __set__(self, int32_t li):
            self._wrapper.data.li.itemType = li

    property sc_msg_type:
        """
        Get/set the internal struct's scMsgType.
        """
        def __get__(self):
            return self._wrapper.data.li.scMsgType

        def __set__(self, int32_t smt):
            self._wrapper.data.li.scMsgType = smt

    property name_str:
        """
        Get/set the internal struct's nameStr.
        """
        def __get__(self):
            # nameStr is a bytes_string
            return self._wrapper.data.li.nameStr.decode('UTF-8')

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
            # TODO: use wrapped_ptr. check wrapped_ptr for NULL before using!
            memset(self._wrapper.data.li.nameStr, 0, MH_MAX_NAME_LEN)
            memcpy(self._wrapper.data.li.nameStr, ns, cpy_len)
