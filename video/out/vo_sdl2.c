/*
 * video output driver for SDL2
 *
 * by divVerent <divVerent@xonotic.org>
 *
 * Some functions/codes/ideas are from x11 and aalib vo
 *
 * TODO: support draw_alpha?
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

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <assert.h>

#include <SDL.h>

#include "config.h"
#include "vo.h"
#include "sub/sub.h"
#include "video/mp_image.h"
#include "video/vfcap.h"

#include "core/input/keycodes.h"
#include "core/input/input.h"
#include "core/mp_msg.h"
#include "core/mp_fifo.h"

struct priv {
    SDL_Window *window;
    SDL_Renderer *renderer;
};

static int config(struct vo *vo, uint32_t width, uint32_t height,
        uint32_t d_width, uint32_t d_height, uint32_t flags,
        uint32_t format)
{
    struct priv *vc = vo->priv;
    if (vc->renderer) {
        SDL_DestroyRenderer(vc->renderer);
        vc->renderer = NULL;
    }
    if (vc->window) {
        SDL_DestroyWindow(vc->window);
        vc->window = NULL;
    }
    Uint32 winflags = SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE;
    if (vo_fs)
        winflags |= SDL_WINDOW_FULLSCREEN;
    vc->window = SDL_CreateWindow("MPV",
            SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, d_width, d_height,
            winflags);
    if (!vc->window) {
        mp_msg(MSGT_VO, MSGL_ERR, "Could not get a SDL2 window");
        return -1;
    }
    vc->renderer = SDL_CreateRenderer(vc->window, -1, 0);
    if (!vc->renderer) {
        mp_msg(MSGT_VO, MSGL_ERR, "Could not get a SDL2 renderer");
        SDL_DestroyWindow(vc->window);
        vc->window = NULL;
        return -1;
    }
    return 0;
}

static void flip_page_timed(struct vo *vo, unsigned int pts_us, int duration)
{
}

static void check_events(struct vo *vo)
{
}

static void uninit(struct vo *vo)
{
    struct priv *vc = vo->priv;
    SDL_QuitSubSystem(SDL_INIT_VIDEO);
    talloc_free(vc);
    vo->priv = NULL;
}

static void draw_osd(struct vo *vo, struct osd_state *osd)
{
}

static int preinit(struct vo *vo, const char *arg)
{
    struct priv *vc;
    vo->priv = talloc_zero(vo, struct priv);
    vc = vo->priv;
    if(SDL_WasInit(SDL_INIT_VIDEO)) {
        mp_msg(MSGT_VO, MSGL_ERR, "SDL2 already initialized");
        return -1;
    }
    SDL_Init(SDL_INIT_VIDEO);
    return 0;
}

static int query_format(struct vo *vo, uint32_t format)
{
    return VFCAP_CSP_SUPPORTED; // TODO
}

static int control(struct vo *vo, uint32_t request, void *data)
{
    struct priv *vc = vo->priv;
    switch (request) {
        case VOCTRL_QUERY_FORMAT:
            return query_format(vo, *((uint32_t *)data));
    }
    return VO_NOTIMPL;
}

const struct vo_driver video_out_sdl2 = {
    .is_new = true,
    .info = &(const vo_info_t) {
        "SDL2",
        "sdl2",
        "Rudolf Polzer <divVerent@xonotic.org>",
        ""
    },
    .preinit = preinit,
    .config = config,
    .control = control,
    .uninit = uninit,
    .check_events = check_events,
    .draw_osd = draw_osd,
    .flip_page_timed = flip_page_timed,
};
