#include "common.h"
#include "utils.h"

extern "C" paddr_t paddr_read(paddr_t raddr);
extern "C" void paddr_write(paddr_t waddr, word_t wdata, uint32_t wmask);

vaddr_t vaddr_read(vaddr_t raddr) {
    return paddr_read(raddr);
}

void vaddr_write(vaddr_t waddr, word_t wdata, uint32_t wmask) {
    paddr_write(waddr, wdata, wmask);
}