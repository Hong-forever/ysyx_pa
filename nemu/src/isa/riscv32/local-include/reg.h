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

#ifndef __RISCV_REG_H__
#define __RISCV_REG_H__

#include <common.h>
#include <isa.h>

static inline int check_reg_idx(int idx) {
  IFDEF(CONFIG_RT_CHECK, assert(idx >= 0 && idx < MUXDEF(CONFIG_RVE, 16, 32)));
  return idx;
}

#define gpr(idx) (cpu.gpr[check_reg_idx(idx)])

#define mstatus  (cpu.mstatus_reg)
#define mcause   (cpu.mcause_reg)
#define mepc     (cpu.mepc_reg)
#define mtvec    (cpu.mtvec_reg)

static inline word_t csr_read(int idx) {
  switch (idx) {
    case 0x300: return mstatus;
    case 0x305: return mtvec;
    case 0x341: return mepc;
    case 0x342: return mcause;
    default:    panic("Unsupported CSR read: 0x%x\n", idx); return 0;
  }
}

static inline void csr_write(int idx, word_t val) {
  switch (idx) {
    case 0x300: mstatus = val; break;
    case 0x305: mtvec   = val; break;
    case 0x341: mepc    = val; break;
    case 0x342: mcause  = val; break;
    default:    panic("Unsupported CSR write: 0x%x\n", idx); break;
  }
}

static inline const char* reg_name(int idx) {
  extern const char* regs[];
  return regs[check_reg_idx(idx)];
}

#endif
