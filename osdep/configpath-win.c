#include <windows.h>
#include <shlobj.h>

#include "talloc.h"
#include "mpcommon.h"
#include "path.h"
#include "configpath.h"
#include "osdep/io.h"

// Just return the directory relative to the one containing the exe.
// Patches for "proper" semantics welcome.
char *mp_get_os_user_config_path(void)
{
    wchar_t path_w[MAX_PATH];
    if (SHGetFolderPathW(NULL, CSIDL_LOCAL_APPDATA | CSIDL_FLAG_CREATE,
                         NULL, 0, path_w) != S_OK)
    {
        return NULL;
    }
    char *path = mp_to_utf8(NULL, path_w);
    char *res = mp_path_join(NULL, bstr0(path), bstr0(MP_CONFIG_DIR));
    talloc_free(path);
    return res;
}

struct path_list *mp_get_os_system_config_paths(void)
{
    wchar_t exepath_w[MAX_PATH];
    int len = GetModuleFileNameW(NULL, exepath_w, MAX_PATH);
    if (len == 0 || len == MAX_PATH)
        return NULL;
    struct path_list *list = talloc_zero(NULL, struct path_list);
    char *exedir = bstrdup0(list, mp_dirname(mp_to_utf8(list, exepath_w)));
    MP_TARRAY_APPEND(list, list->paths, list->num_paths, exedir);
    return list;
}
