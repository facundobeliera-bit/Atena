import copy
import hashlib
from pathlib import Path
import tempfile
import unittest
from verify_recovery_inventory import compare, DB_SECTIONS

class RecoveryInventoryTest(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.a=Path(self.temp.name)/'source';self.b=Path(self.temp.name)/'restored'
        self.a.mkdir();self.b.mkdir()
        data=b'FICTITIOUS PRIVATE DOCUMENT'
        for root in (self.a,self.b):(root/'object.bin').write_bytes(data)
        user='00000000-0000-4000-8000-000000000001';h=hashlib.sha256(data).hexdigest()
        self.before={'format':1,'fixture_only':True,'environment_id':'atena_disposable_source',
          'postgres':{s:{'fixture':h} for s in DB_SECTIONS},'auth_users':[user],
          'objects':{'object.bin':{'sha256':h,'size':len(data),'owner':user,'private':True}},
          'profiles':{'profile':[user]},'enrollments':{'request':'profile'},
          'documents':{'document':{'object':'object.bin','profile':'profile'}},
          'configuration':{'purge_enabled':False,'outbound_mail_enabled':False,'public_access_enabled':False,
          'migrations_sha256':h,'auth_config_sha256':h,'storage_config_sha256':h}}
        self.after=copy.deepcopy(self.before);self.after['environment_id']='atena_disposable_restored'
    def run_check(self):return compare(self.before,self.after,self.a,self.b)
    def test_complete_inventory_does_not_claim_service_restoration(self):
        result=self.run_check();self.assertTrue(result['inventory_consistent']);self.assertFalse(result['integral_restore_validated'])
    def test_missing_storage(self):
        (self.b/'object.bin').unlink()
        with self.assertRaises(OSError):self.run_check()
    def test_changed_bytes(self):
        (self.b/'object.bin').write_bytes(b'wrong')
        with self.assertRaises(ValueError):self.run_check()
    def test_missing_auth(self):
        self.after['auth_users']=[]
        with self.assertRaises(ValueError):self.run_check()
    def test_broken_enrollment(self):
        self.after['enrollments']['request']='missing'
        with self.assertRaises(ValueError):self.run_check()
    def test_public_private_object(self):
        self.after['objects']['object.bin']['private']=False
        with self.assertRaises(ValueError):self.run_check()
    def test_policy_drift(self):
        self.after['postgres']['rls']['fixture']='0'*64
        with self.assertRaises(ValueError):self.run_check()
    def test_same_destination_rejected(self):
        self.after['environment_id']=self.before['environment_id']
        with self.assertRaises(ValueError):self.run_check()
    def test_unsafe_path(self):
        self.after['objects']['../object.bin']=self.after['objects'].pop('object.bin')
        with self.assertRaises(ValueError):self.run_check()
    def test_unknown_sections_and_secrets_not_accepted(self):
        self.after['password']='TEST ONLY'
        with self.assertRaises(ValueError):self.run_check()
    def test_active_purge_rejected(self):
        self.after['configuration']['purge_enabled']=True
        with self.assertRaises(ValueError):self.run_check()
    def test_source_objects_cannot_be_reused_as_restoration(self):
        with self.assertRaises(ValueError):compare(self.before,self.after,self.a,self.a)
    def test_unlisted_restored_file_rejected(self):
        (self.b/'extra.bin').write_bytes(b'FICTITIOUS')
        with self.assertRaises(ValueError):self.run_check()

if __name__=='__main__':unittest.main()
