#include <am.h>
#include <nemu.h>
#include <klib.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
}


void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
    int w = (int)inw(VGACTL_ADDR+2); 
    int h = (int)inw(VGACTL_ADDR);
    *cfg = (AM_GPU_CONFIG_T) {
        .present = true, .has_accel = false,
        .width = w, .height = h,
        .vmemsz = w * h
    };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
    int width = (int)inw(VGACTL_ADDR+2); 
    uint32_t *px = (uint32_t *)ctl->pixels;
    if(px != NULL) {
        for(int j=0; j<ctl->h; j++) {
            for(int i=0; i<ctl->w; i++) {
                uint32_t px_value = px[j * ctl->w + i];
                outl(FB_ADDR + (ctl->y * width + ctl->x + j * ctl->w + i)*sizeof(uint32_t), px_value);
            }
        }
    }
    if (ctl->sync) {
        outl(SYNC_ADDR, 1);
    }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
    status->ready = true;
}
