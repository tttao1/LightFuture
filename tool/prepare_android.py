"""Generate the Android host with Flutter, without changing the source project."""
from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET

ANDROID_NS = "http://schemas.android.com/apk/res/android"
APP_ID = "cn.lightfuture.demo"
MIN_SDK = 24  # Flutter 3.35 requires Android 7.0 or newer.
ET.register_namespace("android", ANDROID_NS)


def replace_once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise ValueError(f"Unexpected Flutter Android template: {old!r}")
    return text.replace(old, new, 1)


def configure_gradle(text: str) -> str:
    signing = '''android {
    signingConfigs {
        create("demo") {
            storeFile = file("demo-keystore.jks")
            storePassword = "android"
            keyAlias = "lightfuture-demo"
            keyPassword = "android"
        }
    }
'''
    text = replace_once(text, "android {\n", signing)
    text = replace_once(text, 'signingConfig = signingConfigs.getByName("debug")',
                        'signingConfig = signingConfigs.getByName("demo")')
    text = replace_once(text, "minSdk = flutter.minSdkVersion", f"minSdk = {MIN_SDK}")
    text = replace_once(text, 'applicationId = "cn.lightfuture.light_future_demo"',
                        f'applicationId = "{APP_ID}"')
    return text


def configure_manifest(path: Path, *, main: bool) -> None:
    tree = ET.parse(path)
    root = tree.getroot()
    for permission in list(root):
        if permission.tag.startswith("uses-permission") and permission.get(
            f"{{{ANDROID_NS}}}name"
        ) in {"android.permission.INTERNET", "android.permission.ACCESS_NETWORK_STATE"}:
            root.remove(permission)
    if main:
        app = root.find("application")
        if app is None:
            raise ValueError("Android application element is missing")
        app.set(f"{{{ANDROID_NS}}}label", "脑力训练 Demo")
        for activity in app.findall("activity"):
            if activity.get(f"{{{ANDROID_NS}}}name") == ".MainActivity":
                activity.set(f"{{{ANDROID_NS}}}name", "cn.lightfuture.light_future_demo.MainActivity")
    tree.write(path, encoding="utf-8", xml_declaration=True)


def prepare(project: Path, repo: Path) -> None:
    project = project.resolve()
    allowed_parent = (repo / ".ci").resolve()
    if not project.is_relative_to(allowed_parent) or project == allowed_parent:
        raise ValueError("Generated project must be inside the repository's .ci directory")
    if project.exists():
        raise ValueError("Generated project already exists; use a fresh build directory")
    signing_key = repo / "tool" / "demo-signing" / "demo-keystore.jks"
    if not signing_key.is_file():
        raise FileNotFoundError("Missing public demo signing key; upload tool/demo-signing too")
    project.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([
        "flutter", "create", "--no-pub", "--empty", "--platforms=android",
        "--project-name", "light_future_demo", "--org", "cn.lightfuture", str(project),
    ], check=True, cwd=repo)
    for name in ("pubspec.yaml", "analysis_options.yaml"):
        shutil.copy2(repo / name, project / name)
    lock = repo / "pubspec.lock"
    if lock.is_file():
        shutil.copy2(lock, project / lock.name)
    for name in ("lib", "test"):
        shutil.copytree(repo / name, project / name, dirs_exist_ok=True)
    gradle = project / "android" / "app" / "build.gradle.kts"
    gradle.write_text(configure_gradle(gradle.read_text(encoding="utf-8")), encoding="utf-8")
    shutil.copy2(signing_key, gradle.parent / "demo-keystore.jks")
    for manifest in (project / "android" / "app" / "src").glob("*/AndroidManifest.xml"):
        configure_manifest(manifest, main=manifest.parent.name == "main")
    print(f"Prepared offline Android demo: {project}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    args = parser.parse_args()
    prepare(args.project, Path(__file__).resolve().parent.parent)
