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
    SDL_RendererInfo renderer_info;
    SDL_Texture *tex;
    mp_image_t texmpi;
    mp_image_t *ssmpi;
};

struct formatmap_entry {
    Uint32 sdl;
    unsigned int mpv;
};
const struct formatmap_entry formats[] = {
    {SDL_PIXELFORMAT_RGB24, IMGFMT_RGB24},
    {SDL_PIXELFORMAT_BGR24, IMGFMT_BGR24},
    {SDL_PIXELFORMAT_RGB24, IMGFMT_RGB24},
    {SDL_PIXELFORMAT_BGR24, IMGFMT_BGR24},
#if BYTE_ORDER == BIG_ENDIAN
    {SDL_PIXELFORMAT_RGB332, IMGFMT_RGB8},
    {SDL_PIXELFORMAT_RGB444, IMGFMT_RGB12},
    {SDL_PIXELFORMAT_RGB555, IMGFMT_RGB15},
    {SDL_PIXELFORMAT_BGR555, IMGFMT_BGR15},
    {SDL_PIXELFORMAT_RGB565, IMGFMT_RGB16},
    {SDL_PIXELFORMAT_BGR565, IMGFMT_BGR16},
    {SDL_PIXELFORMAT_RGB888, IMGFMT_RGB24},
    {SDL_PIXELFORMAT_BGR888, IMGFMT_BGR24},
    {SDL_PIXELFORMAT_RGBX8888, IMGFMT_RGBA},
    {SDL_PIXELFORMAT_BGRX8888, IMGFMT_BGRA},
    {SDL_PIXELFORMAT_ARGB8888, IMGFMT_ARGB},
    {SDL_PIXELFORMAT_RGBA8888, IMGFMT_RGBA},
    {SDL_PIXELFORMAT_ABGR8888, IMGFMT_ABGR},
    {SDL_PIXELFORMAT_BGRA8888, IMGFMT_BGRA},
#else
    {SDL_PIXELFORMAT_RGB332, IMGFMT_RGB8},
    {SDL_PIXELFORMAT_RGB444, IMGFMT_BGR12},
    {SDL_PIXELFORMAT_RGB555, IMGFMT_BGR15},
    {SDL_PIXELFORMAT_BGR555, IMGFMT_RGB15},
    {SDL_PIXELFORMAT_RGB565, IMGFMT_BGR16},
    {SDL_PIXELFORMAT_BGR565, IMGFMT_RGB16},
    {SDL_PIXELFORMAT_RGB888, IMGFMT_BGR24},
    {SDL_PIXELFORMAT_BGR888, IMGFMT_RGB24},
    {SDL_PIXELFORMAT_RGBX8888, IMGFMT_ABGR},
    {SDL_PIXELFORMAT_BGRX8888, IMGFMT_ARGB},
    {SDL_PIXELFORMAT_ARGB8888, IMGFMT_BGRA},
    {SDL_PIXELFORMAT_RGBA8888, IMGFMT_ABGR},
    {SDL_PIXELFORMAT_ABGR8888, IMGFMT_RGBA},
    {SDL_PIXELFORMAT_BGRA8888, IMGFMT_ARGB},
#endif
    {SDL_PIXELFORMAT_YV12, IMGFMT_YV12},
    {SDL_PIXELFORMAT_IYUV, IMGFMT_IYUV},
    {SDL_PIXELFORMAT_YUY2, IMGFMT_YUY2},
    {SDL_PIXELFORMAT_UYVY, IMGFMT_UYVY},
    {SDL_PIXELFORMAT_YVYU, IMGFMT_YVYU}
};

static int config(struct vo *vo, uint32_t width, uint32_t height,
        uint32_t d_width, uint32_t d_height, uint32_t flags,
        uint32_t format)
{
    struct priv *vc = vo->priv;
    SDL_SetWindowSize(vc->window, d_width, d_height);
    if (vc->tex)
        SDL_DestroyTexture(vc->tex);
    Uint32 texfmt = SDL_PIXELFORMAT_UNKNOWN;
    int i, j;
    for (i = 0; i < vc->renderer_info.num_texture_formats; ++i)
        for (j = 0; j < sizeof(formats) / sizeof(formats[0]); ++j)
            if (vc->renderer_info.texture_formats[i] == formats[j].sdl)
                if (format == formats[j].mpv)
                    texfmt = formats[j].sdl;
    if (texfmt == SDL_PIXELFORMAT_UNKNOWN) {
        mp_msg(MSGT_VO, MSGL_ERR, "Invalid pixel format\n");
        return -1;
    }
    vc->tex = SDL_CreateTexture(vc->renderer, texfmt,
            SDL_TEXTUREACCESS_STREAMING, width, height);
    if (!vc->tex) {
        mp_msg(MSGT_VO, MSGL_ERR, "Could not create a SDL2 texture\n");
        return -1;
    }
    SDL_ShowWindow(vc->window);
    mp_image_t *texmpi = &vc->texmpi;
    texmpi->width = texmpi->w = width;
    texmpi->height = texmpi->h = height;
    mp_image_setfmt(texmpi, format);
    switch (texmpi->num_planes) {
        case 1:
        case 3:
            break;
        default:
            mp_msg(MSGT_VO, MSGL_ERR, "Invalid plane count in pixel format\n");
            SDL_DestroyTexture(vc->tex);
            vc->tex = NULL;
            return -1;
    }
    vc->ssmpi = alloc_mpi(width, height, format);
    return 0;
}

static void flip_page(struct vo *vo)
{
    struct priv *vc = vo->priv;
    SDL_RenderPresent(vc->renderer);
}

static void check_events(struct vo *vo)
{
}

static void uninit(struct vo *vo)
{
    struct priv *vc = vo->priv;
    free_mp_image(vc->ssmpi);
    SDL_QuitSubSystem(SDL_INIT_VIDEO | SDL_INIT_TIMER);
    talloc_free(vc);
    vo->priv = NULL;
}

static void draw_osd(struct vo *vo, struct osd_state *osd)
{
}

static bool MP_SDL_IsGoodRenderer(int n)
{
    SDL_RendererInfo ri;
    if (SDL_GetRenderDriverInfo(n, &ri))
        return false;
    int i, j;
    for (i = 0; i < ri.num_texture_formats; ++i)
        for (j = 0; j < sizeof(formats) / sizeof(formats[0]); ++j)
            if (ri.texture_formats[i] == formats[j].sdl)
                return true;
    return false;
}

static int preinit(struct vo *vo, const char *arg)
{
    struct priv *vc;
    vo->priv = talloc_zero(vo, struct priv);
    vc = vo->priv;

    if (SDL_WasInit(SDL_INIT_VIDEO)) {
        mp_msg(MSGT_VO, MSGL_ERR, "SDL2 already initialized\n");
        return -1;
    }
    if (SDL_VideoInit(NULL)) {
        mp_msg(MSGT_VO, MSGL_ERR, "SDL_Init failed\n");
        return -1;
    }

    vc->window = SDL_CreateWindow("MPV",
            SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 320, 240,
            SDL_WINDOW_RESIZABLE);
    if (!vc->window) {
        mp_msg(MSGT_VO, MSGL_ERR, "Could not get a SDL2 window\n");
        return -1;
    }

    int i;
    for (i = 0; i < SDL_GetNumRenderDrivers(); ++i) {
        if (MP_SDL_IsGoodRenderer(i))
            break;
    }

    if (i >= SDL_GetNumRenderDrivers()) {
        mp_msg(MSGT_VO, MSGL_ERR, "No suitable SDL2 renderer\n");
        return -1;
    }

    vc->renderer = SDL_CreateRenderer(vc->window, i, 0);
    if (!vc->renderer) {
        mp_msg(MSGT_VO, MSGL_ERR, "Could not get a SDL2 renderer\n");
        SDL_DestroyWindow(vc->window);
        vc->window = NULL;
        return -1;
    }

    if(SDL_GetRendererInfo(vc->renderer, &vc->renderer_info)) {
        mp_msg(MSGT_VO, MSGL_ERR, "Could not get SDL2 renderer info\n");
        return 0;
    }

    mp_msg(MSGT_VO, MSGL_INFO, "Picked renderer: %s\n", vc->renderer_info.name);
    for (i = 0; i < vc->renderer_info.num_texture_formats; ++i) {
        mp_msg(MSGT_VO, MSGL_INFO, "supports %s\n",
                SDL_GetPixelFormatName(vc->renderer_info.texture_formats[i]));
        int j;
        for (j = 0; j < sizeof(formats) / sizeof(formats[0]); ++j)
            if (vc->renderer_info.texture_formats[i] == formats[j].sdl)
                mp_msg(MSGT_VO, MSGL_INFO, "mpv calls this one %s\n",
                        mp_imgfmt_to_name(formats[j].mpv));
    }

    // global renderer state - why not set up right now
    SDL_SetRenderDrawBlendMode(vc->renderer, SDL_BLENDMODE_NONE);

    return 0;
}

static int query_format(struct vo *vo, uint32_t format)
{
    struct priv *vc = vo->priv;
    int i, j;
    mp_msg(MSGT_VO, MSGL_INFO, "Trying format: %08x\n", format);
    for (i = 0; i < vc->renderer_info.num_texture_formats; ++i)
        for (j = 0; j < sizeof(formats) / sizeof(formats[0]); ++j)
            if (vc->renderer_info.texture_formats[i] == formats[j].sdl)
                if (format == formats[j].mpv)
                    return VFCAP_CSP_SUPPORTED;
    return 0;
}

static void draw_image(struct vo *vo, mp_image_t *mpi, double pts)
{
    struct priv *vc = vo->priv;

    void *pixels;
    int pitch;
    if (SDL_LockTexture(vc->tex, NULL, &pixels, &pitch))
    {
        mp_msg(MSGT_VO, MSGL_ERR, "Failed to lock texture\n");
        return;
    }

    mp_image_t *texmpi = &vc->texmpi;
    texmpi->planes[0] = pixels;
    texmpi->stride[0] = pitch;
    if (texmpi->num_planes == 3) {
        if (texmpi->imgfmt == IMGFMT_YV12) {
            texmpi->planes[2] =
                ((Uint8 *) texmpi->planes[0] + texmpi->h * pitch);
            texmpi->stride[2] = pitch / 2;
            texmpi->planes[1] =
                ((Uint8 *) texmpi->planes[2] + (texmpi->h * pitch) / 4);
            texmpi->stride[1] = pitch / 2;
        } else {
            texmpi->planes[1] =
                ((Uint8 *) texmpi->planes[0] + texmpi->h * pitch);
            texmpi->stride[1] = pitch / 2;
            texmpi->planes[2] =
                ((Uint8 *) texmpi->planes[1] + (texmpi->h * pitch) / 4);
            texmpi->stride[2] = pitch / 2;
        }
    }
    copy_mpi(texmpi, mpi);
    SDL_UnlockTexture(vc->tex);

    // typically these two calls will run in parallel
    SDL_RenderCopy(vc->renderer, vc->tex, NULL, NULL);
    copy_mpi(vc->ssmpi, mpi);
}

static int control(struct vo *vo, uint32_t request, void *data)
{
    switch (request) {
        case VOCTRL_QUERY_FORMAT:
            return query_format(vo, *((uint32_t *)data));
        case VOCTRL_DRAW_IMAGE:
            draw_image(vo, (mp_image_t *)data, vo->next_pts);
            return 0;
        // TODO:
        case VOCTRL_UPDATE_SCREENINFO:
        case VOCTRL_FULLSCREEN:
            ;
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
    .flip_page = flip_page,
};
