#ifndef __COMMON_H__
#define __COMMON_H__

#include <Vtop.h>
#include "macro.h"

typedef uint32_t paddr_t;
typedef uint32_t word_t;

#define RESET_VECTOR 0x80000000

extern void init_monitor(int argc, char *argv[]);
#endif