# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 0riginally created by Escalade (https://github.com/escalade)
# Copyright (C) 2018-present 5schatten (https://github.com/5schatten)

PKG_NAME="retroarch"
PKG_VERSION="49fa097"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/libretro/RetroArch"
PKG_URL="https://github.com/libretro/RetroArch.git"
PKG_DEPENDS_TARGET="toolchain alsa-lib freetype zlib retroarch-assets retroarch-overlays core-info retroarch-joypad-autoconfig ffmpeg joyutils sixpair empty"
PKG_LONGDESC="Reference frontend for the libretro API."
GET_HANDLER_SUPPORT="git"

pre_configure_target() {
  TARGET_CONFIGURE_OPTS=""
  PKG_CONFIGURE_OPTS_TARGET="--disable-vg \
                             --disable-sdl \
                             --disable-xvideo \
                             --disable-al \
                             --disable-oss \
                             --enable-zlib \
                             --host=$TARGET_NAME \
                             --enable-freetype"

  # SAMBA Support
  if [ "${SAMBA_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" samba"
  fi

  # AVAHI Support
  if [ "${AVAHI_DAEMON}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" avahi nss-mdns"
  fi

  # QT Support for WIMP GUI
  if [ "${PROJECT}" = "Generic" ]; then
    PKG_DEPENDS_TARGET+=" qt-everywhere"
    PKG_CONFIGURE_OPTS_TARGET+=" --enable-qt"
  else
    PKG_CONFIGURE_OPTS_TARGET+=" --disable-qt"
  fi

  # Displayserver Support
  if [ "${DISPLAYSERVER}" = "x11" ]; then
    PKG_DEPENDS_TARGET+=" xorg-server"
    PKG_CONFIGURE_OPTS_TARGET+=" --enable-x11"
  else
    PKG_CONFIGURE_OPTS_TARGET+=" --disable-x11"
  fi

  # OpenGL Support
  if [ "${OPENGL_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" ${OPENGL}"
    PKG_CONFIGURE_OPTS_TARGET+=" --enable-opengl \
                                 --enable-kms"
  fi

  # Vulkan Support
  if [ "${VULKAN_SUPPORT}" = "yes" ]; then
     PKG_CONFIGURE_OPTS_TARGET+=" --enable-vulkan"
  fi

  # OpenGLES Support
  if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" ${OPENGLES}"
    PKG_CONFIGURE_OPTS_TARGET+=" --enable-opengles \
                                 --disable-kms"

    # RPi OpenGLES Features Support
    if [ "${OPENGLES}" = "bcm2835-driver" ]; then
      PKG_CONFIGURE_OPTS_TARGET+=" --enable-dispmanx"

      CFLAGS="$CFLAGS -I$SYSROOT_PREFIX/usr/include/interface/vcos/pthreads \
                      -I$SYSROOT_PREFIX/usr/include/interface/vmcs_host/linux"

    # Amlogic OpenGLES Features Support
    elif [ "${OPENGLES}" = "opengl-meson" ] || [ "${OPENGLES}" = "opengl-meson-t82x" ]; then
      PKG_CONFIGURE_OPTS_TARGET+=" --enable-mali_fbdev"
    fi
  fi

  # NEON Support
  if target_has_feature neon; then
    PKG_CONFIGURE_OPTS_TARGET+=" --enable-neon"
  fi
  
  # Clean up & export env/version
  cd ..
  rm -rf .${TARGET_NAME}
  export PKG_CONF_PATH=$TOOLCHAIN/bin/pkg-config
  echo ${PKG_VERSION:0:7} > .gitversion
}

make_target() {
  make V=1 HAVE_LAKKA=1 HAVE_ZARCH=0 HAVE_NETWORKING=1 HAVE_QT=no
  make -C gfx/video_filters compiler=$CC extra_flags="$CFLAGS"
  make -C libretro-common/audio/dsp_filters compiler=$CC extra_flags="$CFLAGS"
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
  mkdir -p $INSTALL/etc
    cp $PKG_BUILD/retroarch $INSTALL/usr/bin
    cp $PKG_BUILD/retroarch.cfg $INSTALL/etc
  mkdir -p $INSTALL/usr/share/video_filters
    cp $PKG_BUILD/gfx/video_filters/*.so $INSTALL/usr/share/video_filters
    cp $PKG_BUILD/gfx/video_filters/*.filt $INSTALL/usr/share/video_filters
  mkdir -p $INSTALL/usr/share/audio_filters
    cp $PKG_BUILD/libretro-common/audio/dsp_filters/*.so $INSTALL/usr/share/audio_filters
    cp $PKG_BUILD/libretro-common/audio/dsp_filters/*.dsp $INSTALL/usr/share/audio_filters
  
  # General configuration
  sed -i -e "s/# libretro_directory =/libretro_directory = \"\/tmp\/cores\"/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# libretro_info_path =/libretro_info_path = \"\/tmp\/cores\"/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# rgui_browser_directory =/rgui_browser_directory =\/storage\/roms/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# content_database_path =/content_database_path =\/tmp\/database\/rdb/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# playlist_directory =/playlist_directory =\/storage\/playlists/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# savefile_directory =/savefile_directory =\/storage\/savefiles/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# savestate_directory =/savestate_directory =\/storage\/savestates/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# system_directory =/system_directory =\/storage\/roms\/bios/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# screenshot_directory =/screenshot_directory =\/storage\/screenshots/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# video_shader_dir =/video_shader_dir =\/tmp\/shaders/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# rgui_show_start_screen = true/rgui_show_start_screen = false/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# assets_directory =/assets_directory =\/tmp\/assets/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# overlay_directory =/overlay_directory =\/tmp\/overlays/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# cheat_database_path =/cheat_database_path =\/tmp\/database\/cht/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# menu_driver = \"rgui\"/menu_driver = \"xmb\"/" $INSTALL/etc/retroarch.cfg
 
  # Quick menu
  echo "core_assets_directory =/storage/roms/downloads" >> $INSTALL/etc/retroarch.cfg
  echo "quick_menu_show_undo_save_load_state = \"false\"" >> $INSTALL/etc/retroarch.cfg
  echo "quick_menu_show_save_core_overrides = \"false\"" >> $INSTALL/etc/retroarch.cfg
  echo "quick_menu_show_save_game_overrides = \"false\"" >> $INSTALL/etc/retroarch.cfg
  echo "quick_menu_show_cheats = \"true\"" >> $INSTALL/etc/retroarch.cfg
  
  # Video
  sed -i -e "s/# video_windowed_fullscreen = true/video_windowed_fullscreen = false/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# video_smooth = true/video_smooth = false/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# video_aspect_ratio_auto = false/video_aspect_ratio_auto = true/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# video_threaded = false/video_threaded = true/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# video_font_path =/video_font_path =\/usr\/share\/retroarch-assets\/xmb\/monochrome\/font.ttf/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# video_font_size = 48/video_font_size = 32/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# video_filter_dir =/video_filter_dir =\/usr\/share\/video_filters/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# video_gpu_screenshot = true/video_gpu_screenshot = false/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# video_fullscreen = false/video_fullscreen = true/" $INSTALL/etc/retroarch.cfg

  # Audio
  sed -i -e "s/# audio_driver =/audio_driver = \"alsathread\"/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# audio_filter_dir =/audio_filter_dir =\/usr\/share\/audio_filters/" $INSTALL/etc/retroarch.cfg
  if [ "$PROJECT" == "OdroidXU3" ]; then # workaround the 55fps bug
    sed -i -e "s/# audio_out_rate = 48000/audio_out_rate = 44100/" $INSTALL/etc/retroarch.cfg
  fi

  # Saving
  echo "savestate_thumbnail_enable = \"false\"" >> $INSTALL/etc/retroarch.cfg
  
  # Input
  sed -i -e "s/# input_driver = sdl/input_driver = udev/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# input_max_users = 16/input_max_users = 5/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# input_autodetect_enable = true/input_autodetect_enable = true/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# joypad_autoconfig_dir =/joypad_autoconfig_dir = \/tmp\/joypads/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# input_remapping_directory =/input_remapping_directory = \/storage\/remappings/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# input_menu_toggle_gamepad_combo = 0/input_menu_toggle_gamepad_combo = 2/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# all_users_control_menu = false/all_users_control_menu = true/" $INSTALL/etc/retroarch.cfg

  # Menu
  sed -i -e "s/# menu_mouse_enable = false/menu_mouse_enable = false/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# menu_core_enable = true/menu_core_enable = false/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# thumbnails_directory =/thumbnails_directory = \/storage\/thumbnails/" $INSTALL/etc/retroarch.cfg
  echo "menu_show_advanced_settings = \"false\"" >> $INSTALL/etc/retroarch.cfg
  echo "menu_wallpaper_opacity = \"1.0\"" >> $INSTALL/etc/retroarch.cfg
  echo "content_show_images = \"false\"" >> $INSTALL/etc/retroarch.cfg
  echo "content_show_music = \"false\"" >> $INSTALL/etc/retroarch.cfg
  echo "content_show_video = \"false\"" >> $INSTALL/etc/retroarch.cfg

  # Updater
  if [ "$ARCH" == "arm" ]; then
    sed -i -e "s/# core_updater_buildbot_url = \"http:\/\/buildbot.libretro.com\"/core_updater_buildbot_url = \"http:\/\/buildbot.libretro.com\/nightly\/linux\/armhf\/latest\/\"/" $INSTALL/etc/retroarch.cfg
  fi
  
  # Playlists
  echo "playlist_names = \"$RA_PLAYLIST_NAMES\"" >> $INSTALL/etc/retroarch.cfg
  echo "playlist_cores = \"$RA_PLAYLIST_CORES\"" >> $INSTALL/etc/retroarch.cfg
  echo "playlist_entry_rename = \"false\"" >> $INSTALL/etc/retroarch.cfg
  echo "playlist_entry_remove = \"false\"" >> $INSTALL/etc/retroarch.cfg

  #sx05re
  sed -i -e "s/# menu_show_core_updater = false/menu_show_core_updater = true/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# menu_show_online_updater = false/menu_show_online_updater = true/" $INSTALL/etc/retroarch.cfg
  sed -i -e "s/# input_overlay_opacity = 1.0/input_overlay_opacity = 0.15/" $INSTALL/etc/retroarch.cfg


  # Gamegirl
  if [ "$PROJECT" == "Gamegirl" ]; then
    echo "xmb_theme = 3" >> $INSTALL/etc/retroarch.cfg
    echo "xmb_menu_color_theme = 9" >> $INSTALL/etc/retroarch.cfg
    echo "video_font_size = 10" >> $INSTALL/etc/retroarch.cfg
    echo "aspect_ratio_index = 0" >> $INSTALL/etc/retroarch.cfg
    echo "audio_device = \"sysdefault:CARD=ALSA\"" >> $INSTALL/etc/retroarch.cfg
    echo "menu_timedate_enable = false" >> $INSTALL/etc/retroarch.cfg
    echo "xmb_shadows_enable = true" >> $INSTALL/etc/retroarch.cfg
    sed -i -e "s/input_menu_toggle_gamepad_combo = 2/input_menu_toggle_gamepad_combo = 4/" $INSTALL/etc/retroarch.cfg
    sed -i -e "s/video_smooth = false/video_smooth = true/" $INSTALL/etc/retroarch.cfg
    sed -i -e "s/video_font_path =\/usr\/share\/retroarch-assets\/xmb\/monochrome\/font.ttf//" $INSTALL/etc/retroarch.cfg
  fi
}

post_install() {  
  # link default.target to retroarch.target
  #ln -sf retroarch.target $INSTALL/usr/lib/systemd/system/default.target
  
  #enable_service retroarch-autostart.service
  enable_service retroarch.service
  enable_service tmp-cores.mount
  enable_service tmp-joypads.mount
  enable_service tmp-database.mount
  enable_service tmp-assets.mount
  enable_service tmp-shaders.mount
  enable_service tmp-overlays.mount
}

#post_makeinstall_target() {
 # mkdir -p $INSTALL/usr/lib/retroarch
  #  cp $PKG_DIR/scripts/retroarch-config $INSTALL/usr/lib/retroarch
#}