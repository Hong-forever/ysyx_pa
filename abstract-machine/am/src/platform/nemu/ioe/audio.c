#include <am.h>
#include <klib.h>
#include <nemu.h>

#define AUDIO_FREQ_ADDR (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR (AUDIO_ADDR + 0x14)

static uint32_t sbuf_pos = 0;

void __am_audio_init()
{
}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg)
{
    uint32_t sbuf_size = inl(AUDIO_SBUF_SIZE_ADDR);
    cfg->present = false;
    cfg->bufsize = sbuf_size;
}

void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl)
{
    outl(AUDIO_FREQ_ADDR, ctrl->freq);
    outl(AUDIO_CHANNELS_ADDR, ctrl->channels);
    outl(AUDIO_SAMPLES_ADDR, ctrl->samples);
    outl(AUDIO_INIT_ADDR, 1);
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat)
{
    stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl)
{
  volatile uint8_t *ab = (volatile uint8_t *)(uintptr_t)AUDIO_SBUF_ADDR;
  const uint8_t *src = (const uint8_t *)(ctl->buf).start;
  uint32_t len = (uint32_t)((ctl->buf).end - (ctl->buf).start);

  if (len == 0) return;

  uint32_t sbuf_size = inl(AUDIO_SBUF_SIZE_ADDR);

  while (len > 0) {
    uint32_t used = inl(AUDIO_COUNT_ADDR);
    uint32_t free = (used < sbuf_size) ? (sbuf_size - used) : 0;
    if (free == 0) break; // 没空间了，交还控制权，稍后再写

    uint32_t n = (len < free) ? len : free;

    // 按环形缓冲写入，可能需要分两段
    uint32_t tail = sbuf_size - sbuf_pos;
    uint32_t n1 = (n < tail) ? n : tail;
    for (uint32_t i = 0; i < n1; i++) ab[sbuf_pos + i] = src[i];
    sbuf_pos = (sbuf_pos + n1) % sbuf_size;

    if (n > n1) {
      uint32_t n2 = n - n1;
      for (uint32_t i = 0; i < n2; i++) ab[i] = src[n1 + i];
      sbuf_pos = (sbuf_pos + n2) % sbuf_size;
    }

    outl(AUDIO_COUNT_ADDR, inl(AUDIO_COUNT_ADDR)+ n);
    src += n;
    len -= n;
  }
}
