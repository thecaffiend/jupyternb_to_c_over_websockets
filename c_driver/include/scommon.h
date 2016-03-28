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
