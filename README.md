# ColorOS IR Remote for Magisk

This project ports the ColorOS 17 IR Remote (`com.oplus.consumerIRApp` 17.0.35) from the OnePlus 15 to compatible Android ROMs. The module uses the original, OPlus-signed firmware APK and its bundled remote database. The app sends commands through Android's Consumer IR API.

## Requirements

- Magisk installed on a booted Android 15 or newer ROM with ARM64 app support and a 4 KiB kernel page size.
- A working built-in IR blaster exposed through Android's `consumer_ir` service.
- The standard AndroidX Window Sidecar library and registration from AOSP.
- A device with no preinstalled or sideloaded copy of `com.oplus.consumerIRApp`.

The OnePlus 15 LineageOS `infiniti` 24.0 nightly dated 2026-11-25 includes a Consumer IR driver, HAL, and Android hardware feature declaration. This project uses the ROM's IR stack. Compatibility on other ROMs depends on their hardware support and Android implementation. ColorOS-only launcher cards, backup integration, and cloud services may be unavailable.

## Install the public test build

1. Download [ColorOS IR Remote Magisk v1.0.3](https://github.com/travismills82/oneplus-ir-remote-magisk/releases/tag/v1.0.3). The ZIP contains the original OPlus-signed IR Remote 17.0.35 APK.
2. In Magisk, open **Modules → Install from storage** and select the ZIP.
3. Reboot and open **IR Remote** from the launcher.
4. For the bundled catalogue, turn off **Obtain remote control data online** in the app's settings. Add a remote and test it with an appliance you control.

To remove the port, select **Remove** on the Magisk module and reboot.

Magisk mounts the firmware APK as a normal system app. The module adds a small Java class through the optional AndroidX Window Sidecar library that the app already requests. The ROM's Sidecar JAR and IR HAL are used as shipped. A boot check disables the module if a ROM update changes the underlying Sidecar registration.

On ROMs that ship `oplus-fwk.jar`, Android loads the ROM's OPlus class first. The module uses Android's package allowlist to let the original IR Remote app access that framework.

## Build a self-contained ZIP

Use Python 3, a JDK, and Android SDK Platform 36 with Build Tools 36.1.0. Connect your OnePlus 15 running ColorOS `CPH2747_17.0.1.201(EX01)` with USB debugging enabled, then run:

```sh
python3 build.py --from-device dist/ColorOS-IR-Remote-Magisk-v1.0.3.zip \
  --sdk "$ANDROID_HOME"
```

The builder pulls the original APK, checks the firmware hash, and bundles it. Install the resulting ZIP through Magisk and reboot. You can also pass an extracted APK or the matching `my_product.img` in place of `--from-device`. The image input uses `dump.erofs` from erofs-utils.

The builder writes a checksum next to the ZIP.

## Validation

The v1.0.0 ZIP installed with Magisk 31.0 and booted on Android 16 and 17 emulators with SELinux enforcing. With networking disabled, the app loaded the bundled Samsung TV codes and sent a 37.94 kHz, 136-duration power pattern to the emulator's test Consumer IR service.

The bundled v1.0.3 ZIP installed and launched after reboot on a physical OnePlus 15 running LineageOS 24.0 nightly dated 2026-11-25. The Fire TV profile paired successfully, and volume and input controls worked on the TV.
