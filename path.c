/*
 * Get path to config dir/file.
 *
 * Return Values:
 *   Returns the pointer to the ALLOCATED buffer containing the
 *   zero terminated path string. This buffer has to be FREED
 *   by the caller.
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
#include <string.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include "config.h"
#include "mp_msg.h"
#include "path.h"

#ifdef CONFIG_MACOSX_BUNDLE

#include <unistd.h>
#elif defined(__MINGW32__)
#include <windows.h>
#elif defined(__CYGWIN__)
#include <windows.h>
#include <sys/cygwin.h>
#endif

#include "talloc.h"

#include "osdep/configpath.h"
#include "osdep/io.h"

static char *mp_get_config_path(void)
{
    char *path = getenv("MPLAYER_HOME");
    if (path)
        return talloc_strdup(NULL, path);
    path = mp_get_os_user_config_path();
    if (path)
        return path;
    mp_msg(MSGT_GLOBAL, MSGL_ERR, "No config path found!\n");
    // Use working dir as fallback.
    return talloc_strdup(NULL, ".");
}

char *mp_get_config_file_path(const char *sub_path)
{
    char *path = mp_get_config_path();
    if (!sub_path)
        return path;
    char *res = mp_path_join(NULL, bstr0(path), bstr0(sub_path));
    talloc_free(path);
    mp_msg(MSGT_GLOBAL, MSGL_V, "Config file '%s' -> '%s'\n", sub_path, res);
    return res;
}

struct path_list *mp_get_system_config_file_paths(const char *sub_path)
{
    struct path_list *list = mp_get_os_system_config_paths();
    if (!list)
        list = talloc_zero(NULL, struct path_list);
    if (sub_path) {
        for (int n = 0; n < list->num_paths; n++) {
            list->paths[n] = mp_path_join(list, bstr0(list->paths[n]),
                                                bstr0(sub_path));
        }
    }
    return list;
}

static int postfix_length(bstr path, char c)
{
    for (int n = 0; n < path.len; n++) {
        if (path.start[path.len - n - 1] != c)
            return n;
    }
    return path.len;
}

// Remove trailing slashes, unless every character is a slash
static void path_remove_trailing_seps(bstr *path)
{
    int len = postfix_length(*path, '/');
#if HAVE_DOS_PATHS
    int len2 = postfix_length(*path, '\\');
    len = len2 > len ? len2 : len;
#endif
    if (len < path->len)
        path->len = path->len - len;
}

// Works like Python's os.path.split() (plus bugs)
// Invariants for memory management and bstr issues:
//      out_head->start == path
//      out_tail->start[out_tail->len] == '\0'
static void mp_path_split(const char *path_, bstr *out_head, bstr *out_tail)
{
    char *path = (char *)path_;
    char *orig_path = (char *)path;
#if HAVE_DOS_PATHS
    // Advance path beyond the drive letters ("C:\path" => "\path")
    char *t = strchr(path, ':');
    if (t && (t[1] == '/' || t[1] == '\\'))
        path = t + 2;
#endif
    char *s = strrchr(path, '/');
#if HAVE_DOS_PATHS
    t = strrchr(path, '\\');
    if (t && (!s || t > s))
        s = t;
#endif
    if (s) {
        *out_head = (bstr) {path, s - path + 1};
        *out_tail = bstr0(s + 1);
    } else {
        *out_head = (bstr) {path, 0};
        *out_tail = bstr0(path);
    }

    path_remove_trailing_seps(out_head);

    // On DOS based systems, possibly add the drive letter back
    out_head->start = orig_path;
    out_head->len += path - orig_path;
}

char *mp_basename(const char *path)
{
    bstr head, tail;
    mp_path_split(path, &head, &tail);
    return tail.start;
}

struct bstr mp_dirname(const char *path)
{
    bstr head, tail;
    mp_path_split(path, &head, &tail);
    // The '.' makes this function more practical if the result is used for
    // opening directories.
    return (head.len == 0) ? bstr0(".") : head;
}

char *mp_path_join(void *talloc_ctx, struct bstr p1, struct bstr p2)
{
    if (p1.len == 0)
        return bstrdup0(talloc_ctx, p2);
    if (p2.len == 0)
        return bstrdup0(talloc_ctx, p1);

#if HAVE_DOS_PATHS
    if (p2.len >= 2 && p2.start[1] == ':'
        || p2.start[0] == '\\' || p2.start[0] == '/')
#else
    if (p2.start[0] == '/')
#endif
        return bstrdup0(talloc_ctx, p2);   // absolute path

    bool have_separator;
    int endchar1 = p1.start[p1.len - 1];
#if HAVE_DOS_PATHS
    have_separator = endchar1 == '/' || endchar1 == '\\'
        || p1.len == 2 && endchar1 == ':';     // "X:" only
#else
    have_separator = endchar1 == '/';
#endif

    return talloc_asprintf(talloc_ctx, "%.*s%s%.*s", BSTR_P(p1),
                           have_separator ? "" : "/", BSTR_P(p2));
}

bool mp_path_exists(const char *path)
{
    struct stat st;
    return mp_stat(path, &st) == 0;
}

bool mp_path_isdir(const char *path)
{
    struct stat st;
    return mp_stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}

void mp_mkdir_recursive(const char *path, int mode)
{
    bstr head, tail;
    mp_path_split(path, &head, &tail);

    if (bstrcmp0(head, path) == 0)
        return;

    if (head.len) {
        char *head0 = bstrdup0(NULL, head);
        mp_mkdir_recursive(head0, mode);
        mkdir(path, mode);
        talloc_free(head0);
    }
}
