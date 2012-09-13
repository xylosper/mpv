#include <stdlib.h>

#include "talloc.h"
#include "path.h"
#include "mpcommon.h"
#include "configpath.h"

// http://standards.freedesktop.org/basedir-spec/basedir-spec-0.8.html

static bool validpath(bstr path)
{
    // XDG dictates absolute paths
    return bstr_startswith0(path, "/");
}

char *mp_get_os_user_config_path(void)
{
    bstr path = bstr0(getenv("XDG_CONFIG_HOME"));
    void *tmp = NULL;
    if (!validpath(path)) {
        path = bstr0(getenv("HOME"));
        if (!validpath(path))
            return NULL;
        path = bstr0(mp_path_join(NULL, path, bstr0(".config")));
        tmp = path.start;
    }
    char *res = mp_path_join(NULL, path, bstr0(MP_CONFIG_DIR));
    talloc_free(tmp);
    return res;
}

struct path_list *mp_get_os_system_config_paths(void)
{
    struct path_list *list = talloc_zero(NULL, struct path_list);
    bstr pathlist = bstr0(getenv("XDG_CONFIG_DIRS"));
    while (pathlist.len) {
        bstr item = bstr_split(pathlist, ":", &pathlist);
        if (validpath(item)) {
            char *path = mp_path_join(list, item, bstr0(MP_CONFIG_DIR));
            talloc_steal(list, path);
            MP_TARRAY_APPEND(list, list->paths, list->num_paths, path);
        }
    }
    if (!list->num_paths) {
        MP_TARRAY_APPEND(list, list->paths, list->num_paths,
                         talloc_strdup(list, "/etc/xdg/" MP_CONFIG_DIR));
    }
    return list;
}
