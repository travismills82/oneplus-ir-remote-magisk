#!/system/bin/sh
SKIPUNZIP=1

package_name=com.oplus.consumerIRApp
install_path=/system/app/ColorOSIrRemote/ConsumerIRApp.apk
sidecar_path=/system_ext/etc/permissions/androidx.window.sidecar.xml
active_module=/data/adb/modules/oneplus_ir_remote

find_firmware_apk() {
  local candidate candidate_hash
  for candidate in "$active_module$install_path" /data/media/0/Download/*.apk; do
    [ -f "$candidate" ] && [ ! -L "$candidate" ] || continue
    candidate_hash=$(sha256sum "$candidate" 2>/dev/null) || continue
    if [ "${candidate_hash%% *}" = "$expected_hash" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

[ "$BOOTMODE" = true ] || abort "! Install from the Magisk app after Android boots."
[ "${API:-0}" -ge 35 ] || abort "! IR Remote 17.0.35 requires Android 15 or newer."
case ",$(getprop ro.product.cpu.abilist)," in
  *,arm64-v8a,*) ;;
  *) abort "! Android must support arm64-v8a apps." ;;
esac
[ "$(/system/bin/getconf PAGE_SIZE)" = 4096 ] ||
  abort "! This IR Remote build requires a 4 KiB page-size ROM."

installed_packages=$(cmd package list packages -u --user 0 "$package_name") ||
  abort "! Android Package Manager is unavailable."
if printf '%s\n' "$installed_packages" | grep -Fxq "package:$package_name"; then
  installed_path=$(cmd package path --user 0 "$package_name")
  [ "$installed_path" = "package:$install_path" ] && [ -f "$active_module/module.prop" ] ||
    abort "! IR Remote already exists on this ROM or as an installed app."
fi

# IConsumerIrService transaction 1 returns a Binder status and hasIrEmitter().
ir_result=$(service call consumer_ir 1 2>/dev/null)
printf '%s\n' "$ir_result" |
  grep -Eq '^[[:space:]]*Result: Parcel\([[:space:]]*00000000[[:space:]]+00000001([[:space:]]|$)' ||
  abort "! Android's Consumer IR service did not report an active emitter."

[ -f /system_ext/framework/androidx.window.sidecar.jar ] ||
  abort "! This ROM is missing the AndroidX Window Sidecar library."
stock_hash=$(unzip -p "$ZIPFILE" sidecar.sha256) ||
  abort "! The Sidecar configuration checksum is missing."
live_hash=$(sha256sum "$sidecar_path" 2>/dev/null) ||
  abort "! This ROM is missing the standard Sidecar configuration."
if [ "${live_hash%% *}" != "$stock_hash" ]; then
  # A reinstall can see the module's existing overlay in the live namespace.
  active_hash=$(sha256sum "$active_module/system$sidecar_path" 2>/dev/null)
  [ -n "$active_hash" ] && [ "${live_hash%% *}" = "${active_hash%% *}" ] ||
    abort "! This ROM uses a different Sidecar configuration."
fi

apk_path="$MODPATH$install_path"
app_dir="${apk_path%/*}"
native_dir="$app_dir/lib/arm64"
ext_dir="$MODPATH/system/system_ext"
permissions_dir="$ext_dir/etc/permissions"
framework_dir="$ext_dir/framework"

ui_print "- Verifying the original OPlus-signed IR Remote APK"
mkdir -p "$native_dir" "$permissions_dir" "$framework_dir" ||
  abort "! Could not create module directories."
expected_hash=$(unzip -p "$ZIPFILE" apk.sha256) || abort "! The APK checksum is missing."
if [ "$(unzip -p "$ZIPFILE" apk.source 2>/dev/null)" = external ]; then
  source_apk=$(find_firmware_apk) ||
    abort "! Download the matching ColorOS IR Remote 17.0.35 APK to internal storage from the release instructions."
  ui_print "- Using ${source_apk##*/}"
  cp "$source_apk" "$apk_path" || abort "! Could not copy the firmware APK."
else
  unzip -p "$ZIPFILE" payload/ConsumerIRApp.apk > "$apk_path" ||
    abort "! Could not extract ConsumerIRApp.apk."
fi
actual_hash=$(sha256sum "$apk_path") || abort "! Could not hash the APK."
[ "${actual_hash%% *}" = "$expected_hash" ] ||
  abort "! The APK must be IR Remote 17.0.35 from ColorOS CPH2747_17.0.1.201."

ui_print "- Staging the app, ARM64 libraries, and Sidecar compatibility class"
unzip -oj "$apk_path" 'lib/arm64-v8a/*.so' -d "$native_dir" ||
  abort "! Could not extract the app's ARM64 libraries."
unzip -oj "$ZIPFILE" payload/coloros-ir-compat.jar -d "$framework_dir" ||
  abort "! Could not extract the compatibility JAR."
unzip -o "$ZIPFILE" androidx.window.sidecar.xml -d "$permissions_dir" ||
  abort "! Could not extract the Sidecar configuration."
unzip -o "$ZIPFILE" module.prop post-fs-data.sh sidecar.sha256 -d "$MODPATH" ||
  abort "! Could not extract module metadata."

set_perm_recursive "$MODPATH/system" 0 0 0755 0644 ||
  abort "! Could not set system file permissions."
for file in "$MODPATH/module.prop" "$MODPATH/sidecar.sha256"; do
  set_perm "$file" 0 0 0644 || abort "! Could not set permissions for $file."
done
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755 ||
  abort "! Could not set boot script permissions."
ui_print "- Reboot to add IR Remote to your launcher."
