import copy
import hashlib
import tempfile
import unittest
from pathlib import Path

from lab import gate, validate


class LabSafetyTest(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.photo = Path(self.folder.name) / 'private.photo'
        self.photo.write_bytes(b'original bytes')
        self.case = dict(id='r001', group='capture-1', family='family-1',
                         path=str(self.photo), sha256=hashlib.sha256(self.photo.read_bytes()).hexdigest(),
                         split='regression', status='complete', frames=['9-'] * 10,
                         cumulative=list(range(9, 91, 9)), profile={'name': 'Bowler'})
        self.report = dict(schema=1, manifestSha256='corpus', engine='apple',
                           nativeFingerprint='native', pipelineSha256='pipeline',
                           templatesSha256='bank', expectedCases=2, complete=True, cases=[
                               dict(id='r001', status='complete', split='regression',
                                    exact=True, wrongAutomatic=False, calls=4),
                               dict(id='r002', status='incomplete', split='test',
                                    exact=False, wrongAutomatic=False, calls=4)])

    def test_manifest_checks_original_bytes(self):
        validate({'schema': 1, 'cases': [self.case]})
        self.photo.write_bytes(b'changed')
        with self.assertRaisesRegex(ValueError, 'hash changed'):
            validate({'schema': 1, 'cases': [self.case]})

    def test_redacted_identity_is_a_negative_even_with_complete_frames(self):
        unidentified = dict(self.case, status='unidentified')
        validate({'schema': 1, 'cases': [unidentified]})
        baseline = copy.deepcopy(self.report)
        baseline['cases'][0].update(status='unidentified', exact=False)
        candidate = copy.deepcopy(baseline)
        candidate['cases'][0]['wrongAutomatic'] = True
        self.assertFalse(gate(baseline, candidate)['safe'])

    def test_same_photo_cannot_leak_to_test_even_under_different_path(self):
        other = dict(self.case, id='r002', split='test', group='another-capture')
        with self.assertRaisesRegex(ValueError, 'leaks'):
            validate({'schema': 1, 'cases': [self.case, other]})

    def test_capture_group_cannot_leak_between_splits(self):
        other_photo = Path(self.folder.name) / 'second.photo'
        other_photo.write_bytes(b'another view')
        other = dict(self.case, id='r002', split='test', path=str(other_photo),
                     sha256=hashlib.sha256(other_photo.read_bytes()).hexdigest())
        with self.assertRaisesRegex(ValueError, 'leaks'):
            validate({'schema': 1, 'cases': [self.case, other]})

    def test_layout_holdout_is_not_a_training_family(self):
        with self.assertRaisesRegex(ValueError, 'Held-out'):
            validate({'schema': 1, 'heldOutFamilies': ['family-1'], 'cases': [self.case]})

    def test_same_aggregate_accuracy_cannot_hide_one_regression(self):
        candidate = copy.deepcopy(self.report)
        candidate['cases'][0]['exact'] = False
        candidate['cases'][1]['exact'] = True
        result = gate(self.report, candidate)
        self.assertFalse(result['safe'])
        self.assertEqual(result['regressions'], ['r001'])

    def test_negative_automatic_acceptance_fails(self):
        candidate = copy.deepcopy(self.report)
        candidate['cases'][1]['wrongAutomatic'] = True
        self.assertEqual(gate(self.report, candidate)['wrongAutomatic'], ['r002'])

    def test_native_change_requires_new_paired_baseline(self):
        candidate = dict(self.report, nativeFingerprint='new-os-model')
        with self.assertRaisesRegex(ValueError, 'Unpaired'):
            gate(self.report, candidate)

    def test_partial_report_cannot_pass(self):
        for candidate in [dict(self.report, complete=False),
                          dict(self.report, cases=self.report['cases'][:1])]:
            with self.assertRaisesRegex(ValueError, 'Incomplete'):
                gate(self.report, candidate)

    def test_layout_code_changes_need_explicit_comparison(self):
        candidate = dict(self.report, pipelineSha256='intentional-layout-change')
        with self.assertRaisesRegex(ValueError, 'pipelineSha256'):
            gate(self.report, candidate)
        self.assertTrue(gate(self.report, candidate, allow_pipeline_change=True)['safe'])

    def test_error_swallowed_by_production_retry_still_fails_gate(self):
        candidate = copy.deepcopy(self.report)
        candidate['cases'][0]['error'] = 'native_request_failed'
        with self.assertRaisesRegex(ValueError, 'errors'):
            gate(self.report, candidate)

    def test_more_than_four_calls_is_not_safe(self):
        candidate = copy.deepcopy(self.report)
        candidate['cases'][0]['calls'] = 5
        self.assertFalse(gate(self.report, candidate)['safe'])

    def test_identical_results_are_safe_but_not_an_improvement(self):
        result = gate(self.report, self.report)
        self.assertTrue(result['safe'])
        self.assertFalse(result['promotable'])


if __name__ == '__main__':
    unittest.main()
