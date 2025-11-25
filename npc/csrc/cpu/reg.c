#include "common.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

int cpu_pc = 0;
int cpu_gpr[32];

extern "C" void reg_value(int pc, int gpr[]) {
    cpu_pc = pc;
    for (int i=0; i<32; i++) {
        cpu_gpr[i] = gpr[i];
    }
}

void reg_display() {
    printf("[===] PC [===]: 0x%08d\n", cpu_pc);
    for(int i=0; i<32; i++) {
        printf("regs[%02d]-%-4s: 0x%08x\n", i, regs[i], cpu_gpr[i]);
    }
}

word_t reg_str2val(const char *s, bool *success) {
    *success = true;

    if(s[0] == '$') s++;

    for(int i=0; i<32; i++) {
        if(strcmp(s, regs[i]) == 0) {
            return cpu_gpr[i];
        }
    }

    if(strcmp(s, "pc") == 0) {
        return cpu_pc;
    }

    printf("Error: reg error\n");
    *success = false;
    return 0;
}