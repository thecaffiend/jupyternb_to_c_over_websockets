# don't know if this will work on windows...
from libc.stdint cimport int32_t, uint32_t

# for scommon.h includes. since mainheader.h includes it, we don't want to
# re-include here.
cdef extern from *:
    # alternate form of the struct def. see cython docs.
    struct __sc_header_s:
        int32_t  type
        int32_t  status
        uint32_t code
        uint32_t length

    ctypedef __sc_header_s SC_HEADER_t

    enum __sc_msg_types_e:
      SC_GET_REQ = 10
      SC_GET_RESP
      SC_SET_REQ = 100
      SC_SET_RESP
      SC_END_MSG_TYPE

    ctypedef __sc_msg_types_e SC_MSG_TYPES_t

cdef extern from "mainheader.h":
    int MH_MAX_NAME_LEN
    int MH_MAX_ITEMS

    struct __mh_list_item_s:
        int32_t itemType
        int32_t scMsgType
        # TODO: how to use MH_MAX_NAME_LEN instead of 32 here?
        char    nameStr[32]
#        char    nameStr[MH_MAX_NAME_LEN]

    ctypedef __mh_list_item_s MH_LIST_ITEM_t

    struct __mh_item_list_s:
        SC_HEADER_t  header
        # TODO: how to use MH_MAX_ITEMS instead of 64 here?
        MH_LIST_ITEM_t   itemList[64]

    ctypedef __mh_item_list_s MH_ITEM_LIST_t
