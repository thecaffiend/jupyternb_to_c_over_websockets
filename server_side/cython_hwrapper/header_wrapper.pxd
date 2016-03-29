# don't know if this will work on windows...
from libc.stdint cimport int32_t, uint32_t

cdef extern from "mainheader.h":
    cdef int MH_MAX_NAME_LEN

    cdef struct __mh_list_item_s:
        int32_t itemType
        int32_t scMsgType
        # TODO: how to use MH_MAX_NAME_LEN instead of 32 here?
        char    nameStr[32]

    ctypedef __mh_list_item_s MH_LIST_ITEM_t

# for scommon.h includes. since mainheader.h includes it, we don't want to
# re-include here.
cdef extern from *:
    # alternate form of the struct def. see cython docs.
    ctypedef struct SC_HEADER_t:
        int32_t  type
        int32_t  status
        uint32_t code
        uint32_t length
