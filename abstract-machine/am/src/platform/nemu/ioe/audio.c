#include <am.h>
#include <nemu.h>
#include <klib.h>

#define AUDIO_FREQ_ADDR      (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR  (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR   (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR      (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR     (AUDIO_ADDR + 0x14)

static uint32_t sbuf_size = 0;
static uint64_t wpos = 0; // 已写入总字节数

void __am_audio_init() {
  sbuf_size = inl(AUDIO_SBUF_SIZE_ADDR);
}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg) {
  cfg->present   = (sbuf_size != 0);
  cfg->bufsize   = sbuf_size;
}

void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl) {
  outl(AUDIO_FREQ_ADDR,     ctrl->freq);
  outl(AUDIO_CHANNELS_ADDR, ctrl->channels);
  outl(AUDIO_SAMPLES_ADDR,  ctrl->samples);
  outl(AUDIO_INIT_ADDR,     1); // 开启
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat) {
  stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl) {
  if (&ctl->buf == NULL) return;
  uint32_t played = inl(AUDIO_COUNT_ADDR);
  uint64_t used = wpos - played;
  uint32_t free_bytes = (used >= sbuf_size) ? 0 : (sbuf_size - (uint32_t)used);
  int write_len = ctl->buf.end - ctl->buf.start;
  if (write_len > (int)free_bytes) write_len = free_bytes;
  if (write_len <= 0) return; // 没空间

  uint8_t *src = (uint8_t *)ctl->buf.start;
  uint32_t offset = (uint32_t)(wpos % sbuf_size);
  uint8_t *dst = (uint8_t *)AUDIO_SBUF_ADDR;

  uint32_t first = sbuf_size - offset;
  if (first > (uint32_t)write_len) first = (uint32_t)write_len;
  memcpy(dst + offset, src, first);
  uint32_t remain = write_len - first;
  if (remain) memcpy(dst, src + first, remain);

  wpos += write_len;
}
