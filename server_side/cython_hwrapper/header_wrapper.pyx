from cpython.mem cimport (
    PyMem_Malloc,
    PyMem_Free,
)

from libc.string cimport (
    memset,
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

# struct wrappers

# this gives access to the structs as dicts with keys equal to the struct
# fields. it *does not* respect things like name lengths, so those have to
# be added in extension classes like below.

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

# enum wrappers
cpdef  SC_MSG_TYPES_t _SC_MSG_TYPES
SC_MSG_TYPES = _SC_MSG_TYPES

# consts
MAX_NAME_LEN = MH_MAX_NAME_LEN
MAX_LIST_ITEMS = MH_MAX_ITEMS

cdef class MHListItem:
    """
    Class wrapping the list item struct.

    TODO: Error checking on value sets!
    """
    cdef MH_LIST_ITEM_t* _list_item

    def __cinit__(self):
        """
        """
        # allocate memory for the internal struct
        self._list_item = <MH_LIST_ITEM_t*> PyMem_Malloc(
          sizeof(MH_LIST_ITEM_t)
        )

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

            # NOTE: Use the names from C land here (like MH_MAX_NAME_LEN) since
            #       sizeof is being used. Hopefully, that works as expected.
            # TODO: do we need all of this here? do we need a null term? is
            #       there a better way?
            name_len = (MH_MAX_NAME_LEN * sizeof(char)) - 1
            memset(self._list_item.nameStr, 0, sizeof(MH_MAX_NAME_LEN))
            strncpy(self._list_item.nameStr, ns, name_len)

    # TODO: investigate @property usage. setters didn't appear to work (gave
    #       "TypeError: 'property' object is not callable", but perhaps there
    #       was a typo somewhere. original included below)
    # @property
    # def item_type(self):
    #     """
    #     Get/set the internal struct's itemType.
    #     """
    #     return self._list_item.itemType
    #
    # @item_type.setter
    # def item_type(self, int32_t it):
    #     self._list_item.itemType = it
    #
    # @property
    # def sc_msg_type(self):
    #     """
    #     Get/set the internal struct's scMsgType.
    #     """
    #     return self._list_item.scMsgType
    #
    # @sc_msg_type.setter
    # def sc_msg_type(self, int32_t smt):
    #     self._list_item.scMsgType = smt
    #
    # @property
    # def name_str(self):
    #     """
    #     Get/set the internal struct's nameStr.
    #     """
    #     return self._list_item.nameStr.decode('UTF-8')
    #
    # @name_str.setter
    # def name_str(self, const char* ns):
    #     name_len = (MH_MAX_NAME_LEN * sizeof(char)) - 1
    #     memset(self._list_item, 0, sizeof(MH_LIST_ITEM_t))
    #     strncpy(self._list_item.nameStr, ns, name_len)
