#include "common.h"

#define MEM_DEPTH 0x08000000
static paddr_t pmem[MEM_DEPTH] = {0};

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

extern "C" uint32_t pmem_read(uint32_t raddr)
{
    // printf("data: 0x%x addr: 0x%x\n", pmem[raddr>>2], raddr);
    if (raddr >= (MEM_DEPTH << 2)) {
        printf("Error: overflow, %x\n", raddr);
        assert(0);
    }
    return pmem[raddr >> 2];
}

extern "C" void pmem_write(uint32_t waddr, uint32_t wdata, uint32_t wmask)
{
    // printf("waddr: 0x%08x\nwdata: 0x%08x\nmask:0x%08x\n", waddr, wdata, tra_mask(wmask));
    pmem[waddr >> 2] = (wdata & tra_mask(wmask)) | (pmem[waddr >> 2] & ~tra_mask(wmask));
}

paddr_t *guest_to_host(paddr_t paddr) {
    return pmem + paddr - RESET_VECTOR;
}

uint32_t EmuMemRead(paddr_t raddr)
{
    return pmem_read(raddr - RESET_VECTOR);
}

void EmuMemWrite(paddr_t waddr, uint32_t wdata, uint32_t wmask)
{
    pmem_write(waddr-RESET_VECTOR, wdata, wmask);
}