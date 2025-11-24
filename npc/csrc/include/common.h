#ifndef __COMMON_H__
#define __COMMON_H__

#include <Vtop.h>
#include <nvboard.h>

#define COLOR_RED "\033[1;31m"
#define COLOR_GREEN "\033[1;32m"
#define COLOR_END "\033[0m"

typedef uint32_t paddr_t;


extern void init_monitor(int argc, char *argv[]);
#endif