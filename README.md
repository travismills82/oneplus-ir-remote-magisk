# ColorOS IR Remote for Magisk

This project ports the ColorOS 17 IR Remote (`com.oplus.consumerIRApp` 17.0.35) from the OnePlus 15 to compatible Android ROMs. It packages the original, OPlus-signed firmware APK. The app uses its original remote database and sends commands through Android's Consumer IR API.

## Requirements

- Magisk installed on a booted Android 15 or newer ROM with ARM64 app support and a 4 KiB kernel page size.
- A working built-in IR blaster exposed through Android's `consumer_ir` service.
- The standard AndroidX Window Sidecar library and registration from AOSP.
- A device with no preinstalled or sideloaded copy of `com.oplus.consumerIRApp`.

The OnePlus 15 LineageOS `infiniti` 24.0 nightly dated 2026-11-25 includes a Consumer IR driver, HAL, and Android hardware feature declaration. This project uses the ROM's IR stack. Compatibility on other ROMs depends on their hardware support and Android implementation. ColorOS-only launcher cards, backup integration, and cloud services may be unavailable.

## Build

Use Python 3, a JDK, and Android SDK Platform 36 with Build Tools 36.1.0. While the phone is on ColorOS `CPH2747_17.0.1.201(EX01)`, extract the firmware APK.

```sh
adb pull /my_product/del-app/ConsumerIRApp/ConsumerIRApp.apk
```

```sh
python3 build.py ConsumerIRApp.apk dist/ColorOS-IR-Remote-Magisk-v1.0.0.zip \
  --sdk "$ANDROID_HOME"
```

The builder verifies the original APK against [the firmware SHA-256](source-apk.sha256) and writes a checksum next to the module ZIP. The APK inside the generated ZIP contains proprietary ColorOS assets. The repository contains project source and build instructions.

## Install or remove

1. In Magisk, open **Modules → Install from storage** and select the built ZIP.
2. Reboot, then open **IR Remote** from the launcher.
3. For the bundled catalogue, turn off **Obtain remote control data online** in the app's settings.
4. Add a remote and test it with an appliance you control.

To remove the port, select **Remove** on the Magisk module and reboot.

Magisk mounts the firmware APK as a normal system app. The module adds a small Java class through the optional AndroidX Window Sidecar library that the app already requests. The ROM's Sidecar JAR and IR HAL are used as shipped. A boot check disables the module if a ROM update changes the underlying Sidecar registration.

## Validation

The v1.0.0 ZIP installed with Magisk 31.0 and booted on Android 16 and 17 emulators with SELinux enforcing. With networking disabled, the app loaded the bundled Samsung TV codes and sent a 37.94 kHz, 136-duration power pattern to the emulator's test Consumer IR service.

The OnePlus 15 LineageOS 24.0 nightly dated 2026-11-25 was checked offline for the Sidecar registration, 4 KiB kernel, and IR stack. Physical appliance testing on LineageOS is pending.
