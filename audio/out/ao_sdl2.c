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

struct priv
{
    AVFifoBuffer *buffer;
    bool unpause;
};

static void audio_callback(void *userdata, Uint8 *stream, int len)
{
    struct ao *ao = userdata;
    struct priv *priv = ao->priv;
    // get len bytes for buffer
    // block if needed!
}

static int init(struct ao *ao, char *params)
{
    struct priv *priv = talloc_zero_size(ao, sizeof(priv));
    ao->priv = priv;

    SDL_InitSubSystem(SDL_INIT_AUDIO);

    SDL_AudioSpec desired, obtained;

    desired.format = ...;
    desired.freq = ao->samplerate;
    desired.channels = ao->channels;
    desired.samples = 8192;
    desired.callback = audio_callback;
    desired.userdata = ao;

    SDL_OpenAudio(&desired, &obtained);

    // move back obtained data
    // open audio device via SDL_OpenAudio

    priv->unpause = 1;

    return 1;
}

static void uninit(struct ao *ao, bool cut_audio)
{
    struct priv *priv = ao->priv;
    if (!priv)
        return;

    // close audio device
    SDL_QuitSubSystem(SDL_INIT_AUDIO);

    talloc_free(ao->priv);
    ao->priv = NULL;
}

static void reset(struct ao *ao)
{
    struct priv *priv = ao->priv;
    // flush buffer (seek)
}

static int get_space(struct ao *ao)
{
    struct priv *priv = ao->priv;
    return av_fifo_space(priv->buffer);
}

static int play(struct ao *ao, void *data, int len, int flags)
{
    struct priv *priv = ao->priv;
    int free = av_fifo_space(priv->buffer);
    if (len > free) len = free;
    int ret = av_fifo_generic_write(priv->buffer, data, len, NULL);
    if (priv->unpause) {
        priv->unpause = 0;
        SDL_PauseAudio(SDL_FALSE);
    }
    return ret;
}

static float get_delay(struct ao *ao)
{
    struct priv *priv = ao->priv;
    // get delay in seconds
    // this is buffer length + SDL's own latency
    return 0;
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
