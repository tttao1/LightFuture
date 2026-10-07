"""Exercise the cloud bootstrap against Flutter's Android Kotlin template."""
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from prepare_android import ANDROID_NS, MIN_SDK, configure_gradle, configure_manifest, prepare

# Relevant lines of the Flutter 3.35.7 template, verified from flutter/flutter.
GRADLE = '''plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
android {
    namespace = "cn.lightfuture.light_future_demo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    defaultConfig {
        applicationId = "cn.lightfuture.light_future_demo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
flutter {
    source = "../.."
}
'''
MANIFEST = f'''<manifest xmlns:android="{ANDROID_NS}">
  <uses-permission android:name="android.permission.INTERNET" />
  <application android:name="${{applicationName}}" android:label="old"
               android:icon="@mipmap/ic_launcher">
    <activity android:name=".MainActivity" android:exported="true" />
    <meta-data android:name="flutterEmbedding" android:value="2" />
  </application>
</manifest>'''


class PrepareTests(unittest.TestCase):
    def test_gradle_uses_stable_test_key_and_preserves_namespace(self):
        configured = configure_gradle(GRADLE)
        self.assertIn('applicationId = "cn.lightfuture.demo"', configured)
        self.assertIn('namespace = "cn.lightfuture.light_future_demo"', configured)
        self.assertIn('signingConfig = signingConfigs.getByName("demo")', configured)
        self.assertIn('storeFile = file("demo-keystore.jks")', configured)
        self.assertEqual(MIN_SDK, 24)
        self.assertIn('minSdk = 24', configured)
        self.assertEqual(configured.count('create("demo")'), 1)

    def test_unexpected_template_fails_instead_of_silently_using_debug_key(self):
        with self.assertRaises(ValueError):
            configure_gradle(GRADLE.replace('getByName("debug")', 'getByName("different")'))

    def test_manifest_removes_network_permission_and_preserves_flutter_placeholder(self):
        with tempfile.TemporaryDirectory() as folder:
            manifest = Path(folder) / "AndroidManifest.xml"
            manifest.write_text(MANIFEST, encoding="utf-8")
            configure_manifest(manifest, main=True)
            root = ET.parse(manifest).getroot()
            self.assertEqual(root.findall("uses-permission"), [])
            app = root.find("application")
            self.assertEqual(app.get(f"{{{ANDROID_NS}}}label"), "脑力训练 Demo")
            self.assertEqual(app.get(f"{{{ANDROID_NS}}}name"), "${applicationName}")
            self.assertEqual(app.find("activity").get(f"{{{ANDROID_NS}}}name"),
                             "cn.lightfuture.light_future_demo.MainActivity")

    def test_output_outside_ci_is_rejected_before_running_flutter(self):
        with tempfile.TemporaryDirectory() as folder:
            repo = Path(folder)
            with patch("prepare_android.subprocess.run") as command:
                with self.assertRaises(ValueError):
                    prepare(repo / "lib", repo)
                command.assert_not_called()

    def test_bootstrap_copies_sources_and_configures_generated_project(self):
        with tempfile.TemporaryDirectory() as folder:
            repo = Path(folder)
            for name in ("lib", "test", "tool/demo-signing"):
                (repo / name).mkdir(parents=True)
            (repo / "lib/main.dart").write_text("original demo", encoding="utf-8")
            (repo / "test/widget_test.dart").write_text("demo tests", encoding="utf-8")
            (repo / "pubspec.yaml").write_text("name: light_future_demo", encoding="utf-8")
            (repo / "analysis_options.yaml").write_text("analyzer: {}", encoding="utf-8")
            (repo / "tool/demo-signing/demo-keystore.jks").write_bytes(b"test fixture key")
            project = repo / ".ci/android_project"

            def create_host(command, **kwargs):
                self.assertIn("--no-pub", command)
                android_app = project / "android/app"
                (android_app / "src/main").mkdir(parents=True)
                (android_app / "src/debug").mkdir(parents=True)
                (android_app / "build.gradle.kts").write_text(GRADLE, encoding="utf-8")
                (android_app / "src/main/AndroidManifest.xml").write_text(MANIFEST, encoding="utf-8")
                (android_app / "src/debug/AndroidManifest.xml").write_text(MANIFEST, encoding="utf-8")

            with patch("prepare_android.subprocess.run", side_effect=create_host):
                prepare(project, repo)
            self.assertEqual((project / "lib/main.dart").read_text(), "original demo")
            self.assertEqual((repo / "lib/main.dart").read_text(), "original demo")
            self.assertTrue((project / "android/app/demo-keystore.jks").is_file())
            self.assertEqual(ET.parse(project / "android/app/src/debug/AndroidManifest.xml")
                             .getroot().findall("uses-permission"), [])
            with self.assertRaises(ValueError):
                prepare(project, repo)


if __name__ == "__main__":
    unittest.main()
