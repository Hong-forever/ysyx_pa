/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <common.h>
#include <device/map.h>
#include <SDL2/SDL.h>
#include <string.h>

enum {
  reg_freq,
  reg_channels,
  reg_samples,
  reg_sbuf_size,
  reg_init,
  reg_count,
  nr_reg
};

static uint8_t  *sbuf        = NULL;
static uint32_t *audio_base  = NULL;

static volatile uint32_t rpos = 0;    // 设备侧读指针

static void sdl_audio_callback(void *userdata, uint8_t *stream, int len) {
  int remain = len, off = 0;
  while (remain) {
    int chunk = CONFIG_SB_SIZE - rpos;
    if (chunk > remain) chunk = remain;
    memcpy(stream + off, sbuf + rpos, chunk);
    rpos = (rpos + chunk) % CONFIG_SB_SIZE;
    off += chunk;
    remain -= chunk;
  }
  audio_base[reg_count] = rpos;
}

static void audio_start() {
  SDL_AudioSpec want;
  memset(&want, 0, sizeof(want));
  want.freq     = audio_base[reg_freq];
  want.channels = audio_base[reg_channels];
  want.samples  = audio_base[reg_samples];
  want.userdata = NULL;
  want.format   = AUDIO_S16SYS;
  want.callback = sdl_audio_callback;
  if (SDL_InitSubSystem(SDL_INIT_AUDIO) == 0 && SDL_OpenAudio(&want, NULL) == 0) {
    SDL_PauseAudio(0);
  }
}

static void audio_io_handler(uint32_t offset, int len, bool is_write) {
  uint32_t idx = offset >> 2;
  if (idx == reg_init) {
    if (audio_base[reg_init]) audio_start();
  }
}

void init_audio() {
  uint32_t sz = sizeof(uint32_t) * nr_reg;
  audio_base = (uint32_t *)new_space(sz);
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map("audio", CONFIG_AUDIO_CTL_PORT, audio_base, sz, audio_io_handler);
#else
  add_mmio_map("audio", CONFIG_AUDIO_CTL_MMIO, audio_base, sz, audio_io_handler);
#endif
  for (int i = 0; i < nr_reg; i++) audio_base[i] = 0;
  audio_base[reg_sbuf_size] = CONFIG_SB_SIZE;
  audio_base[reg_count] = 0;

  sbuf = (uint8_t *)new_space(CONFIG_SB_SIZE);
  add_mmio_map("audio-sbuf", CONFIG_SB_ADDR, sbuf, CONFIG_SB_SIZE, NULL);
}
