#include <nvboard.h>
#include <Vtop.h>

#define MODE MEM
#define MEM_DEPTH 131072 

#if MODE==MEM
    #define MEM_DATA "mem.data"
#elif MODE==SUM
    #define MEM_DATA "sum.data"
#elif MODE==VGA
    #define MEM_DATA "vga.data"
#else
    #define MEM_DATA "inst.data"
#endif

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME* top);

static int mem[MEM_DEPTH] = {0};
int trap_flag = 0;

extern "C" int pmem_read(int raddr) {
    printf("data: 0x%08x addr: 0x%08x\n", mem[raddr>>2], raddr);
    return mem[raddr>>2];
}

static int tra_mask(int wmask) {
    switch(wmask) {
        case 0x00000001: return 0x000000ff;
        case 0x00000010: return 0x0000ff00;
        case 0x00000100: return 0x00ff0000;
        case 0x00001000: return 0xff000000;
        case 0x00000011: return 0x0000ffff;
        case 0x00001100: return 0xffff0000;
        case 0x00001111: return 0xffffffff;
        default: return 0;
    }
}

extern "C" void pmem_write(int waddr, int wdata, int wmask) {
    mem[waddr >> 2] = (wdata & tra_mask(wmask)) | (mem[waddr >> 2] & tra_mask(wmask));
    printf("0x%08x: 0x%08x data 0x%08x mask\n", waddr, wdata, wmask);
}

extern "C" void trap(int reg_data) {
    if(reg_data == 0) trap_flag = 1;
    else         trap_flag = 2;
}


static void single_cycle() {
  dut.clk = 0; dut.eval();
  dut.clk = 1; dut.eval();
}

static void reset(int n) {
  dut.rst_n = 0;
  while (n -- > 0) single_cycle();
  dut.rst_n = 1;
}


int main() {
  nvboard_bind_all_pins(&dut);
  nvboard_init();
  
  FILE *file = fopen(MEM_DATA, "r");
  if(file == NULL) printf("Error read\n");

  int count = 0;

  while(fscanf(file, "%x", &mem[count]) == 1 && count < MEM_DEPTH)
  count++;

  fclose(file);
  printf("count: %d\n", count);

  reset(10);
  

  while(1) {

    nvboard_update();
    single_cycle();
    if(trap_flag == 1) {printf("success!\n"); return 0;}
    else if(trap_flag == 2) {printf("Error!\n"); return 0;}
  }
}
