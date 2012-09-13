#ifndef MPLAYER_CONFIGPATH
#define MPLAYER_CONFIGPATH

#define MP_CONFIG_DIR "mplayer"

char *mp_get_os_user_config_path(void);
struct path_list *mp_get_os_system_config_paths(void);

#endif
