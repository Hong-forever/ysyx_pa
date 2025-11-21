#include <am.h>
#include <klib.h>
#include <nemu.h>

#define AUDIO_FREQ_ADDR        (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR    (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR     (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR   (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR        (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR       (AUDIO_ADDR + 0x14)

static uint32_t sbuf_pos = 0;
static uint32_t bytes_per_sec = 0;
static uint64_t last_us = 0;   // 上次估算时间
static int inited = 0;

void __am_audio_init() {
  sbuf_pos = 0;
  last_us = 0;
  bytes_per_sec = 0;
}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg) {
  uint32_t sbuf_size = inl(AUDIO_SBUF_SIZE_ADDR);
  cfg->present = (sbuf_size != 0);
  cfg->bufsize = sbuf_size;
}

void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl) {
  outl(AUDIO_FREQ_ADDR, ctrl->freq);
  outl(AUDIO_CHANNELS_ADDR, ctrl->channels);
  outl(AUDIO_SAMPLES_ADDR, ctrl->samples);
  bytes_per_sec = ctrl->freq * ctrl->channels * 2; // 16-bit
  if (!inited) {
    outl(AUDIO_INIT_ADDR, 1);
    inited = 1;
  }
  // 初始化时间基准
  AM_TIMER_UPTIME_T up;
  ioe_read(AM_TIMER_UPTIME, &up);
  last_us = up.us;
}

static void soft_consume() {
  if (bytes_per_sec == 0) return;
  AM_TIMER_UPTIME_T up;
  ioe_read(AM_TIMER_UPTIME, &up);
  uint64_t now = up.us;
  if (last_us == 0) { last_us = now; return; }
  uint64_t delta_us = now - last_us;
  if (delta_us == 0) return;

  uint64_t should_play = (bytes_per_sec * delta_us) / 1000000ULL;
  uint32_t used = inl(AUDIO_COUNT_ADDR);
  if (should_play >= used) {
    // 全部播放完
    outl(AUDIO_COUNT_ADDR, 0);
  } else {
    outl(AUDIO_COUNT_ADDR, used - (uint32_t)should_play);
  }
  last_us = now;
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat) {
  soft_consume(); // 刷新占用
  stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl) {
  volatile uint8_t *ab = (volatile uint8_t *)(uintptr_t)AUDIO_SBUF_ADDR;
  const uint8_t *src = (const uint8_t *)(ctl->buf).start;
  uint32_t len = (uint32_t)((ctl->buf).end - (ctl->buf).start);
  if (len == 0) return;

  uint32_t sbuf_size = inl(AUDIO_SBUF_SIZE_ADDR);

  // 先做一次软消耗，释放空间
  soft_consume();

  uint32_t used = inl(AUDIO_COUNT_ADDR);
  uint32_t free = (used < sbuf_size) ? (sbuf_size - used) : 0;
  if (free == 0) return; // 无空间，非阻塞返回

  uint32_t n = (len < free) ? len : free;

  // 环形写
  uint32_t tail = sbuf_size - sbuf_pos;
  uint32_t n1 = (n < tail) ? n : tail;
  for (uint32_t i = 0; i < n1; i++) ab[sbuf_pos + i] = src[i];
  sbuf_pos = (sbuf_pos + n1) % sbuf_size;
  if (n > n1) {
    uint32_t n2 = n - n1;
    for (uint32_t i = 0; i < n2; i++) ab[i] = src[n1 + i];
    sbuf_pos = (sbuf_pos + n2) % sbuf_size;
  }

  outl(AUDIO_COUNT_ADDR, used + n); // 使用写前的 used
}
