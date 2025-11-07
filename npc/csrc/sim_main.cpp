#include <nvboard.h>
#include <Vtop.h>
#include <getopt.h>

#define MEM_DEPTH 131072 

static char *img_file; 

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME* top);

static uint32_t mem[MEM_DEPTH] = {0};


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

extern "C" uint32_t pmem_read(uint32_t raddr) {
    printf("data: 0x%x addr: 0x%x\n", mem[raddr>>2], raddr);
    if(raddr > MEM_DEPTH*2) {printf("Error: overflow, %x\n", raddr); assert(-1);}
    return mem[raddr>>2];
}

extern "C" void pmem_write(uint32_t waddr, uint32_t wdata, uint32_t wmask) {
    printf("waddr: 0x%08x\nwdata: 0x%08x\nmask:0x%08x\n", waddr, wdata, tra_mask(wmask));
    mem[waddr >> 2] = (wdata & tra_mask(wmask)) | (mem[waddr >> 2] & ~tra_mask(wmask));
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

static int parse_args(int argc, char *argv[]) {
    const struct option table[] = {
        {"batch"        , no_argument       , NULL, 'b'},
        {"log"          , required_argument , NULL, 'l'},
        {"diff"         , required_argument , NULL, 'd'},
        {"port"         , required_argument , NULL, 'p'},
        {"help"         , no_argument       , NULL, 'h'},
        {0              , 0                 , NULL,  0 },
    };
    
    int o;
    while( (o = getopt_long(argc, argv, "-bhl:d:p:", table, NULL)) != -1) {
        switch(o) {
            case 'b': /*sdb_set_batch_mode();*/ break;
            case 'p': /*scanf(optarg, "%d", &difftest_port);*/ break;
            case 'l': /*log_file = optarg;*/ break;
            case 'd': /*diff_so_file = optarg;*/ break;
            case '1': img_file = optarg; return 0;
            default :
                printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
                printf("\t-b,--batch              run with batch mode\n");
                printf("\t-l,--log=FILE           output log to FILE\n");
                printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
                printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
                printf("\n");
                exit(0);
        }
    }

    return 0;
}


int trap_flag = 0;
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


int main(int argc, char *argv[]) {
  nvboard_bind_all_pins(&dut);
  nvboard_init();
  
  parse_args(argc, argv);
  size_t size = load_img();
  printf("mem[0]: 0x%08x\n", mem[0]);

  reset(10);

  while(1) {
    nvboard_update();
    single_cycle();
    if(trap_flag == 1) {printf("success!\n"); return 0;}
    else if(trap_flag == 2) {printf("Error!\n"); return 0;}
  }
}
