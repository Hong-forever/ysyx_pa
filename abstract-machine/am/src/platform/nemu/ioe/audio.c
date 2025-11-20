#include <am.h>
#include <klib.h>
#include <nemu.h>
#include <string.h>

#define AUDIO_FREQ_ADDR      (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR  (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR   (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR      (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR     (AUDIO_ADDR + 0x14)

static uint32_t sbuf_size = 0;
static uint64_t wpos = 0;     // 累计写入字节(只用于计算环形写指针)
static int started = 0;

void __am_audio_init() {
  sbuf_size = inl(AUDIO_SBUF_SIZE_ADDR);
  wpos = 0;
  started = 0;
}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg) {
  cfg->present = (sbuf_size != 0);
  cfg->bufsize = sbuf_size;
}

// 设置格式；不启动（启动由首次成功写后决定）
void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl) {
  outl(AUDIO_FREQ_ADDR,     ctrl->freq);
  outl(AUDIO_CHANNELS_ADDR, ctrl->channels);
  outl(AUDIO_SAMPLES_ADDR,  ctrl->samples);
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat) {
  stat->count = inl(AUDIO_COUNT_ADDR); // 设备侧应返回“剩余待播”或“已占用”一致语义
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl) {
  if (!ctl || !ctl->buf.start || sbuf_size == 0) return;
  uint32_t wlen = (uint32_t)(ctl->buf.end - ctl->buf.start);
  if (wlen == 0) return;

  const uint8_t *src = (const uint8_t *)ctl->buf.start;
  volatile uint8_t *dst = (volatile uint8_t *)AUDIO_SBUF_ADDR;

  while (wlen) {
    // 设备侧约定：AUDIO_COUNT_ADDR 返回“剩余待播字节”(remaining) 或 “已占用字节”(used) 需统一。
    // 假设设备返回的是“剩余待播”并逐步减少到 0，则无法直接算空闲。
    // 推荐设备返回“已占用字节”(used)。若现在返回剩余，则请在设备改为 used。
    uint32_t used = inl(AUDIO_COUNT_ADDR);  // 若实际是 remaining，请在设备改语义，否则这里需换成 (produced - played)

    // 预留 1 字节避免满与空不区分
    uint32_t free_bytes = (used >= sbuf_size - 1) ? 0 : (sbuf_size - 1 - used);
    if (free_bytes == 0) {
      for (volatile int spin = 0; spin < 200; spin++) asm volatile("" ::: "memory");
      continue;
    }

    uint32_t chunk = (wlen < free_bytes) ? wlen : free_bytes;
    uint32_t offset = (uint32_t)(wpos % sbuf_size);

    uint32_t first = sbuf_size - offset;
    if (first > chunk) first = chunk;
    memcpy((void *)(dst + offset), src, first);
    if (chunk > first) {
      memcpy((void *)dst, src + first, chunk - first);
    }

    wpos += chunk;
    src  += chunk;
    wlen -= chunk;
  }

  if (!started) {
    outl(AUDIO_INIT_ADDR, 1);
    started = 1;
  }
}
