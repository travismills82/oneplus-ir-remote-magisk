#!/usr/bin/env python3
"""Build a Magisk module from a locally extracted ColorOS IR Remote APK."""

import argparse
import hashlib
import os
import subprocess
import tempfile
from io import BytesIO
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZIP_STORED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parent
MODULE = ROOT / "module"


def write_entry(archive, name, contents, compression=ZIP_DEFLATED):
    entry = ZipInfo(name)
    entry.create_system = 3
    entry.external_attr = 0o100644 << 16
    archive.writestr(entry, contents, compress_type=compression)


def build_compatibility_jar(work, d8, android_jar):
    classes = work / "classes"
    classes.mkdir()
    sources = sorted((ROOT / "compat").rglob("*.java"))
    subprocess.run(["javac", "--release", "11", "-d", classes, *sources], check=True)
    subprocess.run(
        [
            d8, "--min-api", "35", "--lib", android_jar, "--output", work,
            *sorted(classes.rglob("*.class")),
        ],
        check=True,
    )
    jar = BytesIO()
    with ZipFile(jar, "w") as archive:
        write_entry(archive, "classes.dex", (work / "classes.dex").read_bytes())
    return jar.getvalue()


def package(output, apk, d8, android_jar):
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".ir-remote-", dir=output.parent) as temp:
        work = Path(temp)
        compat = build_compatibility_jar(work, d8, android_jar)
        module_zip = work / "module.zip"
        with ZipFile(module_zip, "w") as archive:
            for name in ("module.prop", "customize.sh", "post-fs-data.sh",
                         "androidx.window.sidecar.xml", "sidecar.sha256"):
                write_entry(archive, name, (MODULE / name).read_bytes())
            write_entry(archive, "apk.sha256", (ROOT / "source-apk.sha256").read_bytes())
            if apk is None:
                write_entry(archive, "apk.source", b"external\n")
            else:
                write_entry(archive, "payload/ConsumerIRApp.apk", apk, ZIP_STORED)
            write_entry(archive, "payload/coloros-ir-compat.jar", compat, ZIP_STORED)
        module_zip.replace(output)

    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    checksum = output.with_name(output.name + ".sha256")
    checksum.write_text(f"{digest}  {output.name}\n")
    print(f"{output}\n{checksum}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path, nargs="?", help="original ConsumerIRApp.apk from ColorOS")
    parser.add_argument("output", type=Path, help="destination module ZIP")
    parser.add_argument("--external-apk", action="store_true",
                        help="use ConsumerIRApp.apk from the phone's Download folder at install time")
    parser.add_argument("--sdk", type=Path, default=os.getenv("ANDROID_HOME"))
    parser.add_argument("--build-tools", default="36.1.0", help="SDK build-tools version")
    args = parser.parse_args()

    if args.external_apk == (args.apk is not None):
        parser.error("provide either the original APK or --external-apk")
    if args.output.suffix != ".zip" or (args.apk and args.output.resolve() == args.apk.resolve()):
        parser.error("output must be a different file with a .zip extension")
    if args.sdk is None:
        parser.error("set ANDROID_HOME or pass --sdk")

    d8 = args.sdk / "build-tools" / args.build_tools / "d8"
    android_jar = args.sdk / "platforms" / "android-36" / "android.jar"
    for path in (d8, android_jar):
        if not path.is_file():
            parser.error(f"missing {path}")

    try:
        apk = None
        if args.apk:
            apk = args.apk.read_bytes()
            expected = (ROOT / "source-apk.sha256").read_text().strip()
            if hashlib.sha256(apk).hexdigest() != expected:
                parser.error("APK must be IR Remote 17.0.35 from CPH2747_17.0.1.201")
        package(args.output, apk, d8, android_jar)
    except (OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Build failed: {error}\n")


if __name__ == "__main__":
    main()
