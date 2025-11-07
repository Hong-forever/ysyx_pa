#include <nvboard.h>
#include <Vtop.h>

#define MEM_DEPTH 131072 

static char *img_file = "dummy-minirv-npc.bin";

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME* top);

static uint32_t mem[MEM_DEPTH] = {0};

int trap_flag = 0;

extern "C" uint32_t pmem_read(uint32_t raddr) {
    printf("data: 0x%x addr: 0x%x\n", mem[raddr>>2], raddr);
    if(raddr > MEM_DEPTH*2) {printf("Error: overflow, %x\n", raddr); assert(-1);}
    return mem[raddr>>2];
}

static size_t load_img() {
    if(img_file == NULL) {
        printf("No image give\n");
        return 0;
    }

    FILE *fp = fopen(img_file, "rb");
    assert(fp);

    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);

    printf("The image is %s, size = %ld\n", img_file, size);

    fseek(fp, 0, SEEK_SET);
    int ret = fread(mem, size, 1, fp);
    assert(ret == 1);

    fclose(fp);
    return size;
}

static uint32_t tra_mask(uint32_t wmask) {
    switch(wmask) {
        case 0x00000001: return 0x000000ff;
        case 0x00000002: return 0x0000ff00;
        case 0x00000004: return 0x00ff0000;
        case 0x00000008: return 0xff000000;
        case 0x00000003: return 0x0000ffff;
        case 0x0000000c: return 0xffff0000;
        case 0x0000000f: return 0xffffffff;
        default: return 0;
    }
}

extern "C" void pmem_write(uint32_t waddr, uint32_t wdata, uint32_t wmask) {
    printf("waddr: 0x%08x\nwdata: 0x%08x\nmask:0x%08x\n", waddr, wdata, tra_mask(wmask));
    mem[waddr >> 2] = (wdata & tra_mask(wmask)) | (mem[waddr >> 2] & ~tra_mask(wmask));
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
  dut.rst = 1;
  while (n -- > 0) single_cycle();
  dut.rst = 0;
}


int main() {
  nvboard_bind_all_pins(&dut);
  nvboard_init();
  
  size_t size = load_img();

  printf("inst0: 0x%08x\n", mem[0]);
  printf("inst1: 0x%08x\n", mem[1]);

  reset(10);

  while(1) {

    nvboard_update();
    single_cycle();
    if(trap_flag == 1) {printf("success!\n"); return 0;}
    else if(trap_flag == 2) {printf("Error!\n"); return 0;}
  }
}
