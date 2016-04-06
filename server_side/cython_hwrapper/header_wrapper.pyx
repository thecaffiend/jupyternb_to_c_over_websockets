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

# TODO: break this up into multiple files. about to add wrapper classes for
#       things and this will get unweildly
# TODO: size_t/bytesize property (can it just sizeof MH_LIST_ITEM_t?)
# TODO: from_bytes (rename that and this method) method
# TODO: replace the sizeof's with the len methods
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


cdef class MHListItem:
    """
    Class wrapping the list item struct.

    TODO: Error checking on value sets!
    """
    cdef MH_LIST_ITEM_t* _list_item
    cdef readonly int _bytesize

    def __cinit__(self):
        """
        """
        # allocate memory for the internal struct
        self._list_item = <MH_LIST_ITEM_t*> PyMem_Malloc(
          sizeof(MH_LIST_ITEM_t)
        )
        self._bytesize = sizeof(MH_LIST_ITEM_t)

        # if it's NULL, that's bad...
        if self._list_item == NULL:
          raise MemoryError("Could not allocate memory for a MHListItem!")

        # otherwise, party. initialize it to 0's
        memset(self._list_item, 0, sizeof(MH_LIST_ITEM_t))

    def __dealloc__(self):
        """
        Deallocate the heap memory for the internal struct. If it's NULL,
        that's cool. This will be a no-op in that case.
        """
        PyMem_Free(self._list_item)

    def __len__(self):
        """
        Return size of self._list_item struct. Set in __cinit__
        """
        return self._bytesize

    def get_bytes(self):
        """
        Return a copy of the self._list_item as bytes for a socket.
        """
        # TODO: make this a calculated attr (property)?
        cdef array.array arraytemplate = array.array('B', [])
        cdef array.array bites
        bites = array.clone(arraytemplate, self._bytesize, zero=True)
        # TODO: check this logic another time and test thoroughly
        memcpy(bites.data.as_voidptr, self._list_item, self._bytesize)
        return bites

    property item_type:
        """
        Get/set the internal struct's itemType.
        """
        def __get__(self):
            return self._list_item.itemType

        def __set__(self, int32_t li):
            self._list_item.itemType = li

    property sc_msg_type:
        """
        Get/set the internal struct's scMsgType.
        """
        def __get__(self):
            return self._list_item.scMsgType

        def __set__(self, int32_t smt):
            self._list_item.scMsgType = smt

    property name_str:
        """
        Get/set the internal struct's nameStr.
        """
        def __get__(self):
            # nameStr is a bytes_string
            return self._list_item.nameStr.decode('UTF-8')

        def __set__(self, const char* ns):
            # ns should be converted to bytes before here.
            name_sz = MH_MAX_NAME_LEN - 1
            ns_len = strlen(ns)
            # check if new name is too long.
            # TODO: Truncate for now, but consider throwing error...
            cpy_len = name_sz if ns_len >= MH_MAX_NAME_LEN else ns_len

            # good citizen, zero the mem and then copy the string
            memset(self._list_item.nameStr, 0, MH_MAX_NAME_LEN)
            memcpy(self._list_item.nameStr, ns, cpy_len * sizeof(char))
