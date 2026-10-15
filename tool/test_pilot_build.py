import unittest
import tempfile
from pathlib import Path
from build_pilot_evaluation import validate_config, configure_auth_return, PROJECT

class PilotBuildContract(unittest.TestCase):
    def setUp(self):
        self.config = {'ATENA_REMOTE_ENV': 'staging', 'ATENA_MULTIUSER': True,
            'ATENA_SUPABASE_URL': f'https://{PROJECT}.supabase.co',
            'ATENA_SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_fictional_test_only'}
    def test_public_pilot_accepted(self):
        self.assertEqual(validate_config(self.config), self.config)
    def test_remote_environment_cannot_be_omitted(self):
        self.config.pop('ATENA_REMOTE_ENV')
        with self.assertRaises(ValueError): validate_config(self.config)
    def test_other_project_refused(self):
        self.config['ATENA_SUPABASE_URL'] = 'https://other.supabase.co'
        with self.assertRaises(ValueError): validate_config(self.config)
    def test_production_refused(self):
        self.config['ATENA_REMOTE_ENV'] = 'production'
        with self.assertRaises(ValueError): validate_config(self.config)
    def test_local_fallback_refused(self):
        self.config['ATENA_MULTIUSER'] = False
        with self.assertRaises(ValueError): validate_config(self.config)
    def test_numeric_boolean_refused(self):
        self.config['ATENA_MULTIUSER'] = 1
        with self.assertRaises(ValueError): validate_config(self.config)
    def test_secret_or_jwt_refused(self):
        for key in ['sb_secret_test', 'eyJfictional.jwt.example', '']:
            with self.subTest(key_type=key.split('_')[0]):
                self.config['ATENA_SUPABASE_PUBLISHABLE_KEY'] = key
                with self.assertRaises(ValueError): validate_config(self.config)
    def test_extra_build_setting_refused(self):
        self.config['ATENA_ANDROID_DEMO'] = True
        with self.assertRaises(ValueError): validate_config(self.config)

    def test_return_receives_only_public_key_without_changing_source(self):
        source = Path(__file__).resolve().parents[1] / 'web/auth/return.html'
        before = source.read_bytes()
        with tempfile.TemporaryDirectory() as directory:
            web = Path(directory)
            page = web / 'auth/return.html'
            page.parent.mkdir()
            page.write_bytes(before)
            worker = web / 'flutter_service_worker.js'
            worker.write_text('const RESOURCES = {"auth/return.html":"old","main.dart.js":"preserve","_headers":"h"};\nconst OTHER = true;', encoding='utf-8')
            configure_auth_return(web, self.config)
            rendered = page.read_text(encoding='utf-8')
            self.assertNotIn('__ATENA_PUBLISHABLE_KEY__', rendered)
            self.assertIn(self.config['ATENA_SUPABASE_PUBLISHABLE_KEY'], rendered)
            self.assertEqual(before, source.read_bytes())
            self.assertNotIn('auth/return.html', worker.read_text())
            self.assertIn('"main.dart.js": "preserve"', worker.read_text())
            self.assertIn('const OTHER = true;', worker.read_text())
            with self.assertRaises(ValueError): configure_auth_return(web, self.config)

    def test_return_refuses_privileged_config_before_write(self):
        self.config['ATENA_SUPABASE_PUBLISHABLE_KEY'] = 'sb_secret_fictional'
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError): configure_auth_return(Path(directory), self.config)

if __name__ == '__main__': unittest.main()
