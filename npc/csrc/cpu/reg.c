#include "common.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

int cpu_pc = 0;
int cpu_gpr[32] = {0};

extern "C" void reg_value(int pc, int gpr0, int gpr1, int gpr2, int gpr3,
                          int gpr4, int gpr5, int gpr6, int gpr7,
                          int gpr8, int gpr9, int gpr10, int gpr11,
                          int gpr12, int gpr13, int gpr14, int gpr15,
                          int gpr16, int gpr17, int gpr18, int gpr19,
                          int gpr20, int gpr21, int gpr22, int gpr23,
                          int gpr24, int gpr25, int gpr26, int gpr27,
                          int gpr28, int gpr29, int gpr30, int gpr31)
{
    cpu_pc = pc;
    cpu_gpr[0] = gpr0;
    cpu_gpr[1] = gpr1;
    cpu_gpr[2] = gpr2;
    cpu_gpr[3] = gpr3;
    cpu_gpr[4] = gpr4;
    cpu_gpr[5] = gpr5;
    cpu_gpr[6] = gpr6;
    cpu_gpr[7] = gpr7;
    cpu_gpr[8] = gpr8;
    cpu_gpr[9] = gpr9;
    cpu_gpr[10] = gpr10;
    cpu_gpr[11] = gpr11;
    cpu_gpr[12] = gpr12;
    cpu_gpr[13] = gpr13;
    cpu_gpr[14] = gpr14;
    cpu_gpr[15] = gpr15;
    cpu_gpr[16] = gpr16;
    cpu_gpr[17] = gpr17;
    cpu_gpr[18] = gpr18;
    cpu_gpr[19] = gpr19;
    cpu_gpr[20] = gpr20;
    cpu_gpr[21] = gpr21;
    cpu_gpr[22] = gpr22;
    cpu_gpr[23] = gpr23;
    cpu_gpr[24] = gpr24;
    cpu_gpr[25] = gpr25;
    cpu_gpr[26] = gpr26;
    cpu_gpr[27] = gpr27;
    cpu_gpr[28] = gpr28;
    cpu_gpr[29] = gpr29;
    cpu_gpr[30] = gpr30;
    cpu_gpr[31] = gpr31;
}

void reg_display()
{
    printf("[==] PC [==] : 0x%08d\n", cpu_pc);
    for (int i = 0; i < 32; i++) {
        printf("regs[%02d]-%-4s: 0x%08x\n", i, regs[i], cpu_gpr[i]);
    }
}

word_t reg_str2val(const char *s, bool *success)
{
    *success = true;

    if (s[0] == '$')
        s++;

    for (int i = 0; i < 32; i++) {
        if (strcmp(s, regs[i]) == 0) {
            return cpu_gpr[i];
        }
    }

    if (strcmp(s, "pc") == 0) {
        return cpu_pc;
    }

    printf("Error: reg error\n");
    *success = false;
    return 0;
}