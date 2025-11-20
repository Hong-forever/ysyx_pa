#include <am.h>
#include <klib.h>
#include <nemu.h>

#define AUDIO_FREQ_ADDR (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR (AUDIO_ADDR + 0x14)

static uint32_t sbuf_size = 0;
static uint32_t wpos = 0;


void __am_audio_init()
{
    sbuf_size = inl(AUDIO_SBUF_SIZE_ADDR);
}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg)
{
    cfg->present = (sbuf_size != 0);
    cfg->bufsize = sbuf_size;
}

void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl)
{
    outl(AUDIO_FREQ_ADDR, ctrl->freq);
    outl(AUDIO_CHANNELS_ADDR, ctrl->channels);
    outl(AUDIO_SAMPLES_ADDR, ctrl->samples);
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat)
{
    stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl)
{
    if(ctl == NULL || ctl->buf.start == NULL)
        return;
    uint32_t wlen = (uint32_t)(ctl->buf.end - ctl->buf.start);
    assert(wpos <= sbuf_size);

    uint8_t *src = (uint8_t *)ctl->buf.start;
    uint32_t offset = (uint32_t)(wpos % sbuf_size);
    uint8_t *dst = (uint8_t *)AUDIO_SBUF_ADDR;

    uint32_t first = sbuf_size - offset;
    if(first > wlen) first = wlen;
    memcpy(dst + offset, src, first);
    uint32_t remain = wlen - first;
    if (remain)
        memcpy(dst, src + first, remain);

    wpos += wlen;

    if(wlen < 4096)
        outl(AUDIO_INIT_ADDR, 1);
}
