#ifndef __ISA_H__
#define __ISA_H__

#include "common.h"

typedef struct {
    word_t gpr[32];
    word_t pc;
} CPU_state;

extern CPU_state cpu;

typedef struct {
    // add ISA-specific state here
    word_t inst;
    word_t pc;
    IFDEF(CONFIG_ITRACE, char logbuf[128]);
} Decode;

extern Decode s;

extern int cpu_inst_valid;

// loop detect
typedef struct {
    word_t pc;
    word_t count;
} LoopHistory_t;

#define LOOP_HISTORY_SIZE 16
#define MAX_LOOP_COUNT 100000  // 最大循环次数阈值

#endif