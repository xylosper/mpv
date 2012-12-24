/*
 * SDL2 audio output
 * Copyright (C) 2012 Rudolf Polzer <divVerent@xonotic.org>
 *
 * This file is part of MPlayer.
 *
 * MPlayer is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * MPlayer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with MPlayer; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "config.h"
#include "audio/format.h"
#include "talloc.h"
#include "ao.h"
#include "core/mp_msg.h"
#include "libavutil/fifo.h"

#include <SDL.h>

//! size of one chunk, if this is too small MPlayer will start to "stutter"
//! after a short time of playback
#define CHUNK_SIZE (16 * 1024)
//! number of "virtual" chunks the buffer consists of
#define NUM_CHUNKS 8
#define BUFFSIZE (NUM_CHUNKS * CHUNK_SIZE)

struct priv
{
    AVFifoBuffer *buffer;
    bool unpause;
};

static void audio_callback(void *userdata, Uint8 *stream, int len)
{
    mp_msg(MSGT_AO, MSGL_INFO, "cb\n");
    struct ao *ao = userdata;
    struct priv *priv = ao->priv;

    while (len) {
        //LOCK
        int got = av_fifo_generic_read(priv->buffer, stream, len, NULL);
        //UNLOCK
        if (got < 0)
            break;
        if (got == 0)
            SDL_Delay(10); // FIXME hack
        len -= got;
        stream += len;
    }
}

static void uninit(struct ao *ao, bool cut_audio)
{
    struct priv *priv = ao->priv;
    if (!priv)
        return;

    // close audio device
    SDL_QuitSubSystem(SDL_INIT_AUDIO | SDL_INIT_TIMER);

    if (priv->buffer)
        av_fifo_free(priv->buffer);

    talloc_free(ao->priv);
    ao->priv = NULL;
}

static int init(struct ao *ao, char *params)
{
    struct priv *priv = talloc_zero(ao, struct priv);
    ao->priv = priv;

    SDL_InitSubSystem(SDL_INIT_AUDIO | SDL_INIT_TIMER);

    SDL_AudioSpec desired, obtained;

    switch (ao->format) {
        case AF_FORMAT_U8: desired.format = AUDIO_U8; break;
        case AF_FORMAT_S8: desired.format = AUDIO_S8; break;
        case AF_FORMAT_U16_LE: desired.format = AUDIO_U16LSB; break;
        case AF_FORMAT_U16_BE: desired.format = AUDIO_U16MSB; break;
        default:
        case AF_FORMAT_S16_LE: desired.format = AUDIO_S16LSB; break;
        case AF_FORMAT_S16_BE: desired.format = AUDIO_S16MSB; break;
        case AF_FORMAT_S32_LE: desired.format = AUDIO_S32LSB; break;
        case AF_FORMAT_S32_BE: desired.format = AUDIO_S32MSB; break;
        case AF_FORMAT_FLOAT_LE: desired.format = AUDIO_F32LSB; break;
        case AF_FORMAT_FLOAT_BE: desired.format = AUDIO_F32MSB; break;
    }
    desired.freq = ao->samplerate;
    desired.channels = ao->channels;
    desired.samples = BUFFSIZE / (SDL_AUDIO_BITSIZE(desired.format) * desired.channels);
    desired.callback = audio_callback;
    desired.userdata = ao;

    priv->buffer = av_fifo_alloc(BUFFSIZE);

    SDL_OpenAudio(&desired, &obtained);

    switch (obtained.format) {
        case AUDIO_U8: ao->format = AF_FORMAT_U8; break;
        case AUDIO_S8: ao->format = AF_FORMAT_S8; break;
        case AUDIO_S16LSB: ao->format = AF_FORMAT_S16_LE; break;
        case AUDIO_S16MSB: ao->format = AF_FORMAT_S16_BE; break;
        case AUDIO_U16LSB: ao->format = AF_FORMAT_U16_LE; break;
        case AUDIO_U16MSB: ao->format = AF_FORMAT_U16_BE; break;
        case AUDIO_S32LSB: ao->format = AF_FORMAT_S32_LE; break;
        case AUDIO_S32MSB: ao->format = AF_FORMAT_S32_BE; break;
        case AUDIO_F32LSB: ao->format = AF_FORMAT_FLOAT_LE; break;
        case AUDIO_F32MSB: ao->format = AF_FORMAT_FLOAT_BE; break;
        default:
           mp_msg(MSGT_AO, MSGL_ERR, "[sdl2] could not find matching format\n");
           uninit(ao, true);
           return 0;
    }
    ao->samplerate = obtained.freq;
    ao->channels = obtained.channels;
    ao->bps = ao->channels * ao->samplerate * (SDL_AUDIO_BITSIZE(obtained.format)) / 8;
    ao->buffersize = CHUNK_SIZE * NUM_CHUNKS;
    ao->outburst = CHUNK_SIZE;

    priv->unpause = 1;

    return 1;
}

static void reset(struct ao *ao)
{
    struct priv *priv = ao->priv;
    //LOCK
    av_fifo_reset(priv->buffer);
    //UNLOCK
}

static int get_space(struct ao *ao)
{
    struct priv *priv = ao->priv;
    //LOCK
    int space = av_fifo_space(priv->buffer);
    //UNLOCK
    return space;
}

static int play(struct ao *ao, void *data, int len, int flags)
{
    mp_msg(MSGT_AO, MSGL_INFO, "play\n");
    struct priv *priv = ao->priv;
    //LOCK
    int free = av_fifo_space(priv->buffer);
    if (len > free) len = free;
    int ret = av_fifo_generic_write(priv->buffer, data, len, NULL);
    //UNLOCK
    if (priv->unpause) {
        priv->unpause = 0;
        SDL_PauseAudio(SDL_FALSE);
    }
    mp_msg(MSGT_AO, MSGL_INFO, "play -> %d\n", ret);
    return ret;
}

static float get_delay(struct ao *ao)
{
    struct priv *priv = ao->priv;
    //LOCK
    int sz = av_fifo_size(priv->buffer);
    //UNLOCK
    // TODO add SDL's own delay?
    return sz / (float) ao->bps;
}

static void pause(struct ao *ao)
{
    struct priv *priv = ao->priv;
    SDL_PauseAudio(SDL_TRUE);
}

static void resume(struct ao *ao)
{
    struct priv *priv = ao->priv;
    SDL_PauseAudio(SDL_FALSE);
}

const struct ao_driver audio_out_sdl2 = {
    .is_new = true,
    .info = &(const struct ao_info) {
        "SDL2",
        "sdl2",
        "Rudolf Polzer <divVerent@xonotic.org>",
        ""
    },
    .init      = init,
    .uninit    = uninit,
    .get_space = get_space,
    .play      = play,
    .get_delay = get_delay,
    .pause     = pause,
    .resume    = resume,
    .reset     = reset,
};
