#include "isa.h"
#include "utils.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

CPU_state cpu = {};
Decode s = {};

extern "C" void cpu_value(int valid, int inst, int pc, int gpr0, int gpr1, int gpr2, int gpr3,
                          int gpr4, int gpr5, int gpr6, int gpr7,
                          int gpr8, int gpr9, int gpr10, int gpr11,
                          int gpr12, int gpr13, int gpr14, int gpr15,
                          int gpr16, int gpr17, int gpr18, int gpr19,
                          int gpr20, int gpr21, int gpr22, int gpr23,
                          int gpr24, int gpr25, int gpr26, int gpr27,
                          int gpr28, int gpr29, int gpr30, int gpr31)
{
    cpu_inst_valid = valid;
    s.inst = inst; s.pc = pc;

    cpu.pc = pc;
    cpu.gpr[0] = gpr0; cpu.gpr[1] = gpr1; cpu.gpr[2] = gpr2; cpu.gpr[3] = gpr3;
    cpu.gpr[4] = gpr4; cpu.gpr[5] = gpr5; cpu.gpr[6] = gpr6; cpu.gpr[7] = gpr7;
    cpu.gpr[8] = gpr8; cpu.gpr[9] = gpr9; cpu.gpr[10] = gpr10; cpu.gpr[11] = gpr11;
    cpu.gpr[12] = gpr12; cpu.gpr[13] = gpr13; cpu.gpr[14] = gpr14; cpu.gpr[15] = gpr15;
    cpu.gpr[16] = gpr16; cpu.gpr[17] = gpr17; cpu.gpr[18] = gpr18; cpu.gpr[19] = gpr19;
    cpu.gpr[20] = gpr20; cpu.gpr[21] = gpr21; cpu.gpr[22] = gpr22; cpu.gpr[23] = gpr23;
    cpu.gpr[24] = gpr24; cpu.gpr[25] = gpr25; cpu.gpr[26] = gpr26; cpu.gpr[27] = gpr27;
    cpu.gpr[28] = gpr28; cpu.gpr[29] = gpr29; cpu.gpr[30] = gpr30; cpu.gpr[31] = gpr31;
}

void reg_display()
{
    printf("[==> PC ==]  : 0x%08x\n", cpu.pc);
    for (int i = 0; i < 32; i++) {
        printf("regs[%02d]-%-4s: 0x%08x\n", i, regs[i], cpu.gpr[i]);
    }
}

word_t reg_str2val(const char *s, bool *success)
{
    *success = true;

    if (s[0] == '$')
        s++;

    for (int i = 0; i < 32; i++) {
        if (strcmp(s, regs[i]) == 0) {
            return cpu.gpr[i];
        }
    }

    if (strcmp(s, "pc") == 0) {
        return cpu.pc;
    }

    printf("Error: reg error\n");
    *success = false;
    return 0;
}

bool difftest_checkregs(CPU_state *ref_r, paddr_t pc) {
    bool flag = true;

    if(ref_r->pc != cpu.pc) {
        flag = false;
        printf(COLOR_RED "DIFF==>> ref cpu.pc: 0x%08x, dut cpu.pc: 0x%08x\n" COLOR_END, ref_r->pc, cpu.pc);
    }

    for(int i=0; i<32; i++) {
        if(ref_r->gpr[i] != cpu.gpr[i]) {
            printf(COLOR_RED "DIFF==>> ref cpu.gpr[%d]: 0x%08x, dut cpu.gpr[%d]: 0x%08x\n" COLOR_END, i, ref_r->pc, i, cpu.pc);
            flag = false;
            break;
        } 
    }

    if(!flag) {
        printf(COLOR_RED "Difftest: Error at pc: 0x%08x\n" COLOR_END, pc);
        return false;
    }

    return true;
}