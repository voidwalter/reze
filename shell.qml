//@ pragma UseQApplication
//@ pragma Env QT_QPA_PLATFORMTHEME=gtk3
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Io
import QtQuick

import qs.base
import qs.modules.bar
import qs.modules.applauncher
import qs.modules.notifications
import qs.modules.theme
import qs.modules.wallpaper
import qs.modules.media
import qs.modules.osd


Scope {
  ThemeSwitcher { id: ts }
  Bar { theme: ts.theme }
  AppLauncher { theme: ts.theme }
  NotificationPopup { theme: ts.theme }
  WallpaperManager { theme: ts.theme }
  MediaControl { theme: ts.theme }
  OSD { theme: ts.theme }
}
