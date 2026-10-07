"""Create an uploadable source archive and check its required project files."""
from pathlib import Path
import zipfile


def package(repo: Path) -> Path:
    destination = repo / "dist" / "lightfuture-demo-source.zip"
    destination.parent.mkdir(parents=True, exist_ok=True)
    roots = [repo / folder for folder in ("lib", "test", "tool", ".github", "docs")]
    files = [repo / name for name in
             ("pubspec.yaml", "analysis_options.yaml", ".gitignore", "README.md")]
    for root in roots:
        files.extend(p for p in root.rglob("*")
                     if p.is_file() and "__pycache__" not in p.parts and p.suffix != ".pyc")
    lock = repo / "pubspec.lock"
    if lock.is_file():
        files.append(lock)
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(files):
            archive.write(path, path.relative_to(repo).as_posix())
    required = {
        ".github/workflows/android-apk.yml", "pubspec.yaml", "lib/main.dart", "lib/app.dart",
        "lib/games/reaction_controller.dart", "test/reaction_controller_test.dart",
        "test/widget_test.dart", "tool/prepare_android.py", "tool/verify_apk.py",
        "tool/demo-signing/demo-keystore.jks", "tool/demo-signing/demo-certificate.der",
        "tool/android/MainActivity.kt",
        "tool/android/training_icon.xml",
        "docs/GitHub打包APK教程.md",
    }
    with zipfile.ZipFile(destination) as archive:
        if required - set(archive.namelist()):
            raise RuntimeError(f"Source archive is incomplete: {required - set(archive.namelist())}")
        if archive.testzip() is not None:
            raise RuntimeError("Source archive failed its CRC check")
        print(f"Source files: {len(archive.namelist())}")
    print(f"Ready: {destination} ({destination.stat().st_size} bytes)")
    return destination


if __name__ == "__main__":
    package(Path(__file__).resolve().parent.parent)
