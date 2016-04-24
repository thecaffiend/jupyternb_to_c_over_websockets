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
    memcmp,
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
# TODO: Move TODOs somewhere else (like the place in the README you made for
#       them...)
# TODO: change things to use _writedata
# TODO: Methods on the MHItemList.__itemlist member. Needs some of the normal
#       list methods, but protected
# TODO: Continue/finish tests for classes.
# TODO: One of the reasons you would define a header struct for use in other
#       structs like this is for making a protocol of some sort (messaging,
#       controls, etc). So many other types could need the header and
#       supported operations. There should be a base class for these (extending
#       WrapperBase?) that defines the header member and operations. This would
#       make this header_wrapper thing more of a generic protocol wrapper for
#       use with cython and c/c++. Move it out to it's own repo and treat it as
#       such (and look for other - better - implementations to see if the
#       effort would be a waste).
# TODO: make tobytes return bytes, not array.array
# TODO: make sure all memcpy's have a memset of 0 first. perhaps make a method
#       to ensure this (since its a common pattern)
# TODO: break this up into multiple files. about to add wrapper classes for
#       things and this will get unweildly
# TODO: is bytearray or bytes better than using array.array? bytearray since
#       it's mutable?
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
# TODO: write up why you would use these, but why we are not making use of them
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

    cdef void _writedata(self, void *bites, int32_t sz=0):
        """
        """
        # if no sz is passed in, assume we want to write our _bytesize to
        # data. Hopefully that isn't a poor choice...
        # TODO: make sure this isn't a poor choice.
        cdef int32_t nbytes
        nbytes = sz if sz > 0 else self._bytesize
        # clear internal buffer (whole thing, so _bytesize) and write the datas
        # (as many bytes as told to, or _bytesize)
        memset(self.wrapped_ptr(), 0, self._bytesize)
        memcpy(self.wrapped_ptr(), bites, nbytes)

    def __len__(self):
        """
        Return size of self._wrapper.data ptr. Set in __cinit__
        """
        if self._bytesize <= 0:
            t = self._wrapper.type
            if t == HEADER:
                self._bytesize = sizeof(SC_HEADER_t)
            elif t == LISTITEM:
                self._bytesize = sizeof(MH_LIST_ITEM_t)
            elif t == ITEMLIST:
                self._bytesize = sizeof(MH_ITEM_LIST_t)
            else:
                raise ValueError(
                    "WrapperBase.__len__: Cannot determine the type of the " \
                    "wrapped data and therefore don't know the size."
                )

        return self._bytesize

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
                'WrapperBase.frombytes expected bitelike size to be %s but ' \
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

        def __set__(self, namestr):
            py_bytes = namestr.encode('UTF-8')
            cdef const char* ns = py_bytes
            name_sz = MH_MAX_NAME_LEN - 1
            ns_len = strlen(ns)
            # check if new name is too long.
            # TODO: Truncate for now, but consider throwing error...
            cpy_len = name_sz if ns_len >= MH_MAX_NAME_LEN else ns_len

            # good citizen, zero the mem and then copy the string
            # TODO: use wrapped_ptr. check wrapped_ptr for NULL before using!
            memset(self._wrapper.data.li.nameStr, 0, MH_MAX_NAME_LEN)
            memcpy(self._wrapper.data.li.nameStr, ns, cpy_len)

cdef class SCHeader(WrapperBase):
    """
    Class wrapping the header struct.
    """

    def __cinit__(self):
        """
        C-Like initialization for the class
        """
        # set the size to what we should be
        self._bytesize = sizeof(SC_HEADER_t)
        # allocate memory for the internal struct
        self._wrapper.type = HEADER

        self._wrapper.data.sh = <SC_HEADER_t*> PyMem_Malloc(self._bytesize)

        # if it's NULL, that's bad...
        # TODO: use wrapped_ptr. check wrapped_ptr for NULL before using!
        if self._wrapper.data.sh == NULL:
          raise MemoryError("Could not allocate memory for a SCHeader!")

        # otherwise, party. initialize the struct to 0's
        # TODO: use wrapped_ptr. check wrapped_ptr for NULL before using!
        memset(self._wrapper.data.sh, 0, self._bytesize)

    property htype:
        """
        Get/set the internal struct's type.
        """
        def __get__(self):
            return self._wrapper.data.sh.type

        def __set__(self, int32_t sht):
            self._wrapper.data.sh.type = sht

    property hstatus:
        """
        Get/set the internal struct's status.
        """
        def __get__(self):
            return self._wrapper.data.sh.status

        def __set__(self, int32_t shs):
            self._wrapper.data.sh.status = shs

    property hcode:
        """
        Get/set the internal struct's code.
        """
        def __get__(self):
            return self._wrapper.data.sh.code

        def __set__(self, uint32_t shc):
            self._wrapper.data.sh.code = shc

    property hlength:
        """
        Get/set the internal struct's length.
        """
        def __get__(self):
            return self._wrapper.data.sh.length

        def __set__(self, uint32_t shl):
            self._wrapper.data.sh.length = shl

cdef class MHItemList(WrapperBase):
    """
    Class wrapping the item list struct.

    TODO: This class doesn't feel right. Manually having to update the exposed
          header and listitems objects as well as keeping the underlying struct
          up to date seems brittle. Better way?
    """
    # MH_ITEM_LIST_t has a header and a list of MH_LIST_ITEM_t's:
    cdef SCHeader __header
    cdef list __itemlist

    def __cinit__(self):
        """
        C-Like initialization for the class
        """
        # set the size to what we should be
        self._bytesize = sizeof(MH_ITEM_LIST_t)
        # allocate memory for the internal struct
        self._wrapper.type = ITEMLIST

        self._wrapper.data.il = <MH_ITEM_LIST_t*> PyMem_Malloc(self._bytesize)

        # if it's NULL, that's bad...
        # TODO: use wrapped_ptr. check wrapped_ptr for NULL before using!
        if self._wrapper.data.il == NULL:
          raise MemoryError("Could not allocate memory for a MHItemList!")

        # otherwise, party. initialize the struct to 0's
        # TODO: use wrapped_ptr. check wrapped_ptr for NULL before using!
        memset(self._wrapper.data.il, 0, self._bytesize)

    def __init__(self):
        """
        Python initialization for the class
        """
        self.__header = None
        self.__itemlist = None

    def _commit_bytes(self):
        """
        Fill in the underlying struct with the values of the corresponding
        python objects.
        """
        # get the header as a bytes obj and each item in the itemlist as the
        # same (in a list).
        hbytes = self.header.tobytes()
        libytes = [
            self.itemlist[i].tobytes() for i in range(self.header.hlength)
        ]

        # make sure header and listitems agree on the number of items being
        # written
        nitems = self.header.hlength
        if nitems != len(libytes):
            raise ValueError(
                'MHItemList cannot save to internal struct. Header says ' \
                'there are %s list items, but %s were found' %
                (nitems, len(libytes))
            )

        # start an array for the reconstructed bytes
        cdef array.array bytearr
        bytearr = array.array('B', hbytes)

        # listcomp used like map() in this case, but clearer to read. extend
        # bytearr with each array in libytes.
        # TODO: Is this better done with bytearrays since they're mutable?
        [bytearr.extend(arr) for arr in libytes]

        # now assign the bytes in bytearr to the underlying struct
        # get the length of the header and list items we have
        bytelen = len(bytearr)

        # get rid of any existing struct values, then copy in the new values
        # TODO: use wrapped_ptr() but check it for NULL before using!
        memset(self._wrapper.data.il, 0, self._bytesize)
        memcpy(self._wrapper.data.il, bytearr.data.as_voidptr, bytelen)

    def tobytes(self):
        """
        Override of base class's tobytes. This class is a bit more complicated,
        so there's more to do. This calls the base class's tobytes after making
        sure the underlying struct is properly filled in.
        """
        self._commit_bytes()
        return super().tobytes()

    def frombytes(self, bitelike):
        """
        Override the base class's frombytes. This needs to fill in not only the
        struct, but also the objects exposed from this class (header and
        listitems).
        """
        # TODO: separate a function out from this to do the opposite of
        #       _commit_bytes
        # TODO: is the copy of the bitelike to array here needed?
        cdef array.array bites
        bites = array.array('B', bitelike)

        blen = len(bites)
        hlen = sizeof(SC_HEADER_t)
        ilen = sizeof(MH_LIST_ITEM_t)

        # get the length of the listitems
        lilen = blen - hlen

        # TODO: implement the errors
        if blen > self._bytesize:
            pass # error - too many bytes
        elif blen < hlen:
            pass # error - too few bytes
        else:
            if lilen % ilen != 0:
                pass # error - not a multiple of sizeof(MH_LIST_ITEM_t)

        # this is able to be decoded
        # TODO: can this be made easier/cleaner with memoryview's or something
        #       else?
        hbytes = bites[0:hlen]
        libytes = bites[hlen:]
        nitems = lilen // ilen # number of list items

        self.header.frombytes(hbytes)

        # TODO: Implement errors
        if self.header.hlength != nitems:
            pass # error, incoming header and itemlist disagree on number of
                 # items
        # TODO: make a decodeitems method to do this? will it be done a fair
        #       amount?
        # TODO: verify this works without a property setter (not defined)
        #       and cleans up memory as expected...
        del self.itemlist[:]
        for i in range(nitems):
            # TODO: try to clean up loop. and check indexing...
            startbyte = i * ilen
            endbyte = startbyte + ilen
            itembytes = libytes[startbyte:endbyte]
            # TODO: make constructor take optional byteslike
            li = MHListItem()
            li.frombytes(itembytes)
            self.itemlist.append(li)

        # LEFTOFF
        # TODO: check wrapped_ptr for NULL before using!
        # TODO: Check indexes
        # TODO: should _commit_bytes be called here, or should they both
        #       call a method that does this stuff? think separate method...
        self._writedata(bites.data.as_voidptr, sz=blen)

    property header:
        """
        Get/set the internal struct's header.
        """
        def __get__(self):
            if self.__header is None:
                self.__header = SCHeader()
            return self.__header

        def __set__(self, SCHeader h):
            self.__header = h

    property itemlist:
        """
        Get the internal struct's itemlist.
        TODO: Should we allow setting?
        """
        def __get__(self):
            if self.__itemlist is None:
                self.__itemlist = []
            return self.__itemlist
