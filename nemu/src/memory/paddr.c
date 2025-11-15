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

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}


static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

#define MTRACE_LINE 1000 
typedef struct{
    paddr_t addr;
    word_t data;
    int op;
} MTRACE_UNIT;

static MTRACE_UNIT trace_buf[MTRACE_LINE];
static int nr_mtrace = 0;

static void mtrace_log(paddr_t addr, word_t data, int we) {
    if(nr_mtrace < MTRACE_LINE) {
        trace_buf[nr_mtrace].addr = addr;
        trace_buf[nr_mtrace].data = data;
        trace_buf[nr_mtrace].op = we;
        nr_mtrace++;
    } else {
        for(int i=0; i<MTRACE_LINE-1; i++) {
            trace_buf[i] = trace_buf[i+1];
        }
        trace_buf[MTRACE_LINE-1].addr = addr;
        trace_buf[MTRACE_LINE-1].data = data;
        trace_buf[MTRACE_LINE-1].op = we;
    }
}

void mtrace_print(paddr_t addr, int size) {
    if(nr_mtrace < MTRACE_LINE) {
        for(int i=0; i<nr_mtrace; i++) {
            if(trace_buf[i].addr >= addr && trace_buf[i].addr < addr+4*size) printf("addr(0x%08x): data(0x%08x) op(%s)\n", trace_buf[i].addr, trace_buf[i].data, trace_buf[i].op==0? "read" : trace_buf[i].op==1? "sb  " : trace_buf[i].op==2? "sh  " : "sw  ");
        }
    } else {
        for(int i=0; i<MTRACE_LINE; i++) {
            if(trace_buf[i].addr >= addr && trace_buf[i].addr < addr+4*size) printf("addr(0x%08x): data(0x%08x) op(%s)\n", trace_buf[i].addr, trace_buf[i].data, trace_buf[i].op==0? "read" : trace_buf[i].op==1? "sb  " : trace_buf[i].op==2? "sh  " : "sw  ");
        }
    }
}

word_t paddr_read(paddr_t addr, int len) {
    if (likely(in_pmem(addr))) {
        word_t read_data = pmem_read(addr, len);
        mtrace_log(addr, read_data, 0);
        return read_data;
    }
  IFDEF(CONFIG_DEVICE, word_t mmio_data = mmio_read(addr, len); mtrace_log(addr, mmio_data, 0); return mmio_data);
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  if (likely(in_pmem(addr))) { 
      pmem_write(addr, len, data); 
      mtrace_log(addr, len==1? data&0x000000ff : len==2? data&0x0000ffff : data&0xffffffff, len);
      return; 
  }
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); mtrace_log(addr, len==1? data&0x000000ff : len==2? data&0x0000ffff : data&0xffffffff, len); return);
  out_of_bound(addr);
}
