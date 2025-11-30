#ifndef __NPC_H__
#define __NPC_H__

#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>
#include <klib-macros.h>

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END ((uintptr_t)&_pmem_start + PMEM_SIZE)
#define npc_trap(code) asm volatile("mv a0, %0; ebreak" : : "r"(code))

#define SERIAL_PORT     0x10000000
#define RTC_PORT        0x20000000

#endif