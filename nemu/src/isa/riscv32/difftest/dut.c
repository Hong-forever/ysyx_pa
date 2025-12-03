/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
    bool flag = true;

    if(ref_r->pc != cpu.pc) {
        flag = false;
        printf("DIFF==>> pc(ref): 0x%08x, pc(dut): 0x%08x\n", ref_r->pc, cpu.pc);
    }

    for(int i=0; i<MUXDEF(CONFIG_RVE, 16, 32); i++) {
        if(ref_r->gpr[i] != cpu.gpr[i]) {
            printf("gpr[%d](ref): 0x%08x, gpr[%d](dut): 0x%08x\n", i, ref_r->gpr[i], i, cpu.gpr[i]);
            flag = false;
            break;
        } 
    }

    if((ref_r->csr).mstatus != Mstatus()) {
        flag = false;
        printf("DIFF==>> mstatus(ref): 0x%08x, mstatus(dut): 0x%08x\n", ref_r->csr.mstatus, Mstatus());
    }

    if(ref_r->csr.mcause != Mcause()) {
        flag = false;
        printf("DIFF==>> mcause(ref): 0x%08x, mcause(dut): 0x%08x\n", ref_r->csr.mcause, Mcause());
    }
    
    if(ref_r->csr.mepc != Mepc()) {
        flag = false;
        printf("DIFF==>> mepc(ref): 0x%08x, mepc(dut): 0x%08x\n", ref_r->csr.mepc, Mepc());
    }

    if(ref_r->csr.mtvec != Mtvec()) {
        flag = false;
        printf("DIFF==>> mtvec(ref): 0x%08x, mtvec(dut): 0x%08x\n", ref_r->csr.mtvec, Mtvec());
    }

    if(!flag) {
        printf("Difftest: Error at pc: 0x%08x\n", pc);
        return false;
    }

    return true;
}

void isa_difftest_attach() {
}
