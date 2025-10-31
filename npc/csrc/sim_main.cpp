#include <nvboard.h>
#include <Vtop.h>

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME* top);


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

  reset(10);
  
  // int n=50;

  while(1) {
    nvboard_update();
    //dut.eval();
    single_cycle();
    
    printf("%d\n", dut.dout);
    //printf("pc=%d\n", dut.pc_out);
    //printf("inst=%02x\n", dut.inst_out);
    //printf("reg0=%d reg1=%d reg2=%d reg3=%d\n", dut.reg0, dut.reg1, dut.reg2, dut.reg3);
  }
}
