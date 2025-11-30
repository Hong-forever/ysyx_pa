#include "common.h"
#include "utils.h"
#include "device.h"

static word_t pmem[CONFIG_MSIZE] = {0};
static uint32_t rtc_value[2] = {0};

static uint32_t tra_mask(uint32_t wmask)
{
    switch (wmask) {
        case 0x00000001:    return 0x000000ff;
        case 0x00000002:    return 0x0000ff00;
        case 0x00000004:    return 0x00ff0000;
        case 0x00000008:    return 0xff000000;
        case 0x00000003:    return 0x0000ffff;
        case 0x0000000c:    return 0xffff0000;
        case 0x0000000f:    return 0xffffffff;
        default:            return 0;
    }
}

static inline bool in_pmem(paddr_t addr) {
  return (addr - CONFIG_MBASE) < (CONFIG_MSIZE << 2);
}

paddr_t *guest_to_host(paddr_t paddr) {
    return pmem + ((paddr - CONFIG_MBASE) >> 2);
}

paddr_t host_to_guest(paddr_t *haddr) {
    return ((haddr - pmem) << 2) + CONFIG_MBASE;
}

static void out_of_bound(paddr_t addr, bool is_write) {
    printf(COLOR_RED "%s address = 0x%08x is out of bound of pmem [0x%08x, 0x%08x] with the size of 0x%08x\n" COLOR_END, is_write?"Write":"Read", addr, PMEM_LEFT, PMEM_RIGHT, CONFIG_MSIZE);
    assert(0);
}

static word_t host_read(paddr_t *addr) {
    return *addr;
}

static void host_write(paddr_t *addr, word_t wdata, uint32_t wmask) {
    *addr = (wdata & tra_mask(wmask)) | (*addr & ~tra_mask(wmask));
}

void init_mem() {
    IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE * sizeof(word_t)));
    printf(COLOR_BLUE "physical memory area [0x%08x, 0x%08x]\n", PMEM_LEFT, PMEM_RIGHT);
}

IFDEF(MTRACE,
void mtrace_read(paddr_t addr, uint32_t data)
{
    if (addr >= CONFIG_MTRACE_BASE && addr < CONFIG_MTRACE_BASE + CONFIG_MTRACE_SIZE) {
        printf(COLOR_BLUE "[Mtrace] Read addr: 0x%08x data: 0x%08x\n" COLOR_END, addr, data);
    }
}

void mtrace_write(paddr_t addr, uint32_t data, uint32_t mask)
{
    if (addr >= CONFIG_MTRACE_BASE && addr < CONFIG_MTRACE_BASE + CONFIG_MTRACE_SIZE) {
        printf(COLOR_BLUE "[Mtrace] Wrtie addr: 0x%08x data: 0x%08x mask: 0x%08x\n" COLOR_END, addr, data, tra_mask(mask));
    }
}
);

static word_t pmem_read(paddr_t raddr)
{
    // printf("data: 0x%x addr: 0x%x\n", pmem[raddr>>2], raddr);
    word_t ret = host_read(guest_to_host(raddr));
    IFDEF(MTRACE, mtrace_read(raddr, ret));
    return ret;
}

static void pmem_write(paddr_t waddr, word_t wdata, uint32_t wmask)
{
    // printf("waddr: 0x%08x\nwdata: 0x%08x\nmask:0x%08x\n", waddr, wdata, tra_mask(wmask));
    host_write(guest_to_host(waddr), wdata, wmask);
    IFDEF(MTRACE, mtrace_write(waddr, wdata, wmask));
}

extern "C" word_t paddr_read(paddr_t raddr) {
    if (in_pmem(raddr)) {
        // printf("paddr_read addr: 0x%08x\n", raddr);
        return pmem_read(raddr);
    }
    else if ((raddr&~0x3u) == SERIAL_MMIO) {
        return 1;
    }
    else if ((raddr&~0x7u) == RTC_MMIO) {
        if (raddr & 0x4) {
            uint64_t us = get_time();
            if(rtc_value[0] == 0 && rtc_value[1] == 0) {
                rtc_value[0] = boot_time & 0xffffffff;
                rtc_value[1] = (boot_time >> 32) & 0xffffffff;
                return rtc_value[1];
            } else {
                rtc_value[0] = us & 0xffffffff;
                rtc_value[1] = (us >> 32) & 0xffffffff;
                return rtc_value[1];
            }
        } else {
            return rtc_value[0];
        }
    }

    out_of_bound(raddr, false);
    return 0;
}

extern "C" void paddr_write(paddr_t waddr, word_t wdata, uint32_t wmask) {
    if (in_pmem(waddr)) {
        pmem_write(waddr, wdata, wmask);
    }
    else if ((waddr&~0x3u) == SERIAL_MMIO) {
        // memory-mapped serial port write
        assert(wmask == 0x1);
        putchar((char)(wdata & 0xff));
    }
    else {
        out_of_bound(waddr, true);
    }
}
