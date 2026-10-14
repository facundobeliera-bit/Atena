"""Administrative plans only: never prompts for credentials or contacts Supabase."""
import unittest
from onboarding_admin import plan

class AdminPlanTest(unittest.TestCase):
    user='00000000-0000-4000-8000-000000000001'
    def test_existing_scope_unchanged(self):
        self.assertEqual(plan(self.user,True)['rpc'],'atena_onboarding_reviewer')
    def test_family_scope_is_explicit_and_revocable(self):
        value=plan(self.user,False,'family')
        self.assertEqual(value['rpc'],'atena_family_reviewer')
        self.assertEqual(value['parameters'],{'p_user':self.user,'p_active':False})
        self.assertEqual(value['project'],'eaegvxxxkvhdukbkydvy')
    def test_invalid_scope_or_identity_rejected(self):
        with self.assertRaises(ValueError):plan(self.user,True,'admin')
        with self.assertRaises(ValueError):plan('arbitrary-profile',True,'family')
if __name__=='__main__':unittest.main()
