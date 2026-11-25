#!/system/bin/sh
moddir="${0%/*}"

# Magisk runs this before mounting modules. Disable the overlay if a ROM
# update has changed the underlying library registration.
read -r expected < "$moddir/sidecar.sha256" || expected=
actual=$(sha256sum /system_ext/etc/permissions/androidx.window.sidecar.xml 2>/dev/null)
if [ -z "$expected" ] || [ "${actual%% *}" != "$expected" ] ||
   [ ! -f /system_ext/framework/androidx.window.sidecar.jar ]; then
  touch "$moddir/disable"
  echo "ColorOS IR Remote disabled: incompatible ROM Sidecar configuration."
fi
