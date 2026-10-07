"""Verify the APK export checks without requiring a locally installed Android SDK."""
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import verify_apk
from prepare_android import APP_ID, MIN_SDK


class ApkVerificationTests(unittest.TestCase):
    def test_flutter_335_min_sdk_is_accepted(self):
        self.assertEqual(MIN_SDK, 24)
        self.assertEqual(verify_apk.verify_min_sdk("sdkVersion:'24'\n"), 24)

    def test_whitespace_and_both_quote_styles_are_accepted(self):
        for line in ("  sdkVersion: '24'  \r\n", 'sdkVersion: "24"\n'):
            with self.subTest(line=line):
                self.assertEqual(verify_apk.verify_min_sdk(line), 24)

    def test_target_sdk_cannot_be_mistaken_for_minimum_sdk(self):
        self.assertEqual(verify_apk.verify_min_sdk(
            "sdkVersion:'24'\ntargetSdkVersion:'36'\n"
        ), 24)
        with self.assertRaisesRegex(RuntimeError, "Cannot read"):
            verify_apk.verify_min_sdk("targetSdkVersion:'24'\n")

    def test_unexpected_sdk_reports_actual_and_expected_levels(self):
        for actual in (23, 25):
            with self.subTest(actual=actual):
                with self.assertRaisesRegex(RuntimeError, f"is {actual}; expected 24"):
                    verify_apk.verify_min_sdk(f"sdkVersion:'{actual}'\n")

    def test_missing_or_non_numeric_minimum_sdk_is_rejected(self):
        for output in ("", "sdkVersion:'VanillaIceCream'\n", "sdkVersion:'24extra'\n"):
            with self.subTest(output=output):
                with self.assertRaisesRegex(RuntimeError, "Cannot read"):
                    verify_apk.verify_min_sdk(output)

    def verify_fixture(self, *, permission=None, certificate_matches=True):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            sdk = root / "android-sdk"
            tools = sdk / "build-tools" / "36.0.0"
            tools.mkdir(parents=True)
            (tools / "aapt").touch()
            (tools / "apksigner").touch()
            apk = root / "app-release.apk"
            apk.write_bytes(b"APK export fixture; external Android commands are mocked")
            output = root / "dist"
            certificate = Path(verify_apk.__file__).parent / "demo-signing/demo-certificate.der"
            expected = hashlib.sha256(certificate.read_bytes()).hexdigest()
            signature = expected if certificate_matches else "0" * 64
            permissions = f"package: {APP_ID}\n"
            if permission:
                permissions += f"uses-permission: name='{permission}'\n"
            command_outputs = [
                f"package: name='{APP_ID}' versionCode='2'\nsdkVersion:'24'\n",
                permissions,
                f"Signer #1 certificate SHA-256 digest: {signature}\n",
            ]
            with patch.dict("os.environ", {"ANDROID_HOME": str(sdk)}), \
                    patch.object(verify_apk, "run", side_effect=command_outputs):
                if permission == "android.permission.INTERNET":
                    with self.assertRaisesRegex(RuntimeError, "Internet access"):
                        verify_apk.main(apk, output)
                    self.assertFalse(output.exists())
                elif not certificate_matches:
                    with self.assertRaisesRegex(RuntimeError, "fixed demo certificate"):
                        verify_apk.main(apk, output)
                    self.assertFalse(output.exists())
                else:
                    verify_apk.main(apk, output)
                    exported = output / "lightfuture-demo.apk"
                    self.assertEqual(exported.read_bytes(), apk.read_bytes())
                    self.assertIn("Minimum Android API: 24", (output / "build-report.txt")
                                  .read_text(encoding="utf-8"))
                    self.assertIn(hashlib.sha256(apk.read_bytes()).hexdigest(),
                                  (output / "SHA256SUMS.txt").read_text(encoding="utf-8"))

    def test_correct_api_and_signature_allow_export(self):
        self.verify_fixture()

    def test_internet_permission_still_blocks_export(self):
        self.verify_fixture(permission="android.permission.INTERNET")

    def test_wrong_signing_certificate_still_blocks_export(self):
        self.verify_fixture(certificate_matches=False)


if __name__ == "__main__":
    unittest.main()
