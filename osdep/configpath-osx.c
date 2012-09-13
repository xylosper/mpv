#include <CoreFoundation/CoreFoundation.h>

#include "talloc.h"
#include "mpcommon.h"
#include "path.h"
#include "configpath.h"

#define HOME_CONFIG_DIR "Library/Application Support/" MP_CONFIG_DIR

char *mp_get_os_user_config_path(void)
{
    char *home = getenv("HOME");
    if (!home)
        return NULL;
    return mp_path_join(NULL, bstr0(home), bstr0(HOME_CONFIG_DIR));
}

struct path_list *mp_get_os_system_config_paths(void)
{
    CFIndex maxlen = 256;
    CFURLRef res_url_ref = NULL;
    CFURLRef bdl_url_ref = NULL;
    char *res_url_path = NULL;
    char *bdl_url_path = NULL;

    res_url_ref = CFBundleCopyResourcesDirectoryURL(CFBundleGetMainBundle());
    bdl_url_ref = CFBundleCopyBundleURL(CFBundleGetMainBundle());

    if (res_url_ref && bdl_url_ref) {
        res_url_path = malloc(maxlen);
        bdl_url_path = malloc(maxlen);

        while (!CFURLGetFileSystemRepresentation(res_url_ref, true,
                                                 res_url_path, maxlen))
        {
            maxlen * =2;
            res_url_path = realloc(res_url_path, maxlen);
        }
        CFRelease(res_url_ref);

        while (!CFURLGetFileSystemRepresentation(bdl_url_ref, true,
                                                 bdl_url_path, maxlen))
        {
            maxlen * =2;
            bdl_url_path=realloc(bdl_url_path, maxlen);
        }
        CFRelease(bdl_url_ref);

        if (strcmp(res_url_path, bdl_url_path) == 0)
            res_url_path = NULL;
    }

    struct path_list *res = talloc_zero(NULL, struct path_list);

    if (res_url_path) {
        MP_TARRAY_APPEND(res, res->paths, res->num_paths,
                         talloc_strdup(res, res_url_path));
    }

    free(res_url_path);
    free(bdl_url_path);

    return res;
}
