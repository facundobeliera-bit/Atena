import unittest
from build_pilot_evaluation import validate_config, PROJECT

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

if __name__ == '__main__': unittest.main()
