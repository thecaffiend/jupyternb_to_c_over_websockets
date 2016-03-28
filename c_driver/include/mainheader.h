/*************************************************************************//**
 * Some c header that defines constants and structs, uses a system include,
 * and includes some other scommon.h header.
 ****************************************************************************/

#ifndef MAINHEADER_H_
#define MAINHEADER_H_

#include <stdint.h>
#include "scommon.h"

#ifdef __cplusplus
extern "C" {
#endif

// some constants
#define MH_MAX_ITEMS                      64
#define MH_MAX_NAME_LEN                   32


typedef struct __mh_list_item_s
{
  int32_t itemType;
  int32_t scMsgType; // scommon message type
  char    nameStr[MH_MAX_NAME_LEN];
} MH_LIST_ITEM_t;


typedef struct __mh_item_list_s
{
  SC_HEADER_t  header;
  MH_LIST_ITEM_t   itemList[MH_MAX_ITEMS];
} MH_ITEM_LIST_t;

#ifdef __cplusplus
}
#endif

#endif /* MAINHEADER_H_ */
