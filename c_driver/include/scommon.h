/*************************************************************************//**
 * Some c header to be included by mainheader.h
 *
 ****************************************************************************/

#ifndef SYSCOMMON_H_
#define SYSCOMMON_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// enum of some message types
typedef enum __sc_msg_types_e
{
  SC_GET_REQ =   10,
  SC_GET_RESP,

  SC_SET_REQ =   100,
  SC_SET_RESP,

  SC_END_MSG_TYPE
} SC_MSG_TYPES_t;

/*
 * some header struct
 */
typedef struct __sc_header_s
{
  int32_t  type;
  int32_t  status;
  uint32_t code;
  uint32_t length;
} SC_HEADER_t;

#ifdef __cplusplus
}
#endif

#endif /* SYSCOMMON_H_ */
