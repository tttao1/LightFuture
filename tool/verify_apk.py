"""Verify the finished APK and export the installable file and build report."""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess

from prepare_android import APP_ID


def run(command: list[str]) -> str:
    return subprocess.run(command, check=True, capture_output=True, text=True,
                          encoding="utf-8").stdout


def main(apk: Path, output: Path) -> None:
    if not apk.is_file():
        raise FileNotFoundError(apk)
    sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if not sdk:
        raise RuntimeError("Android SDK is not available on this runner")
    tools = [p for p in (Path(sdk) / "build-tools").iterdir()
             if (p / "aapt").is_file() and (p / "apksigner").is_file()]
    if not tools:
        raise RuntimeError("Android aapt and apksigner were not found")
    build_tools = max(tools, key=lambda p: tuple(int(n) for n in re.findall(r"\d+", p.name)))
    badging = run([str(build_tools / "aapt"), "dump", "badging", str(apk)])
    permissions = run([str(build_tools / "aapt"), "dump", "permissions", str(apk)])
    if "android.permission.INTERNET" in permissions:
        raise RuntimeError("Offline APK unexpectedly requests Internet access")
    if f"name='{APP_ID}'" not in badging:
        raise RuntimeError("APK has an unexpected application ID")
    if "sdkVersion:'23'" not in badging:
        raise RuntimeError("APK has an unexpected minimum Android version")
    signature = run([str(build_tools / "apksigner"), "verify", "--verbose", "--print-certs", str(apk)])
    certificate = Path(__file__).parent / "demo-signing" / "demo-certificate.der"
    expected = hashlib.sha256(certificate.read_bytes()).hexdigest()
    if f"certificate SHA-256 digest: {expected}" not in signature:
        raise RuntimeError("APK was not signed with the fixed demo certificate")
    output.mkdir(parents=True, exist_ok=True)
    destination = output / "lightfuture-demo.apk"
    shutil.copy2(apk, destination)
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    (output / "SHA256SUMS.txt").write_text(f"{digest}  {destination.name}\n", encoding="utf-8")
    report = (
        f"Application ID: {APP_ID}\nMinimum Android: 6.0 (API 23)\n"
        f"Commit: {os.environ.get('GITHUB_SHA', 'local')}\n"
        f"Run: {os.environ.get('GITHUB_RUN_NUMBER', 'local')}\n"
        f"APK SHA-256: {digest}\n\n{permissions}\n{signature}\n{badging}"
    )
    (output / "build-report.txt").write_text(report, encoding="utf-8")
    print(f"Verified signature, app identity, API level and offline permissions: {destination}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    main(args.apk.resolve(), args.output.resolve())
