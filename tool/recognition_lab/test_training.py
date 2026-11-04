import copy
import hashlib
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw
from train_templates import classify, normalize, train


class TrainingSafetyTest(unittest.TestCase):
    def test_classifier_retains_threshold_and_lead(self):
        self.assertIsNone(classify('11110000', [('1', int('11000000', 2)), ('7', int('00110000', 2))]))
        self.assertEqual(classify('11110000', [('1', int('11110000', 2)), ('7', int('00110000', 2))]), '1')

    def test_train_never_adds_validation_or_test_masks(self):
        with tempfile.TemporaryDirectory() as folder:
            sources = []
            for i, split in enumerate(['train', 'validation', 'test']):
                path = Path(folder) / f'{i}.png'
                image = Image.new('L', (24, 32))
                draw = ImageDraw.Draw(image)
                draw.line((4, 2, 4 + i * 5, 30), fill=255, width=3)
                image.save(path)
                sources.append(dict(kind='mask', label=str(i + 1), path=str(path),
                                    sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                                    split=split, group=split, family=split))
            baseline = {'width': 24, 'height': 32, 'variants': [
                {'text': '0', 'mask': '1' * 768}, {'text': '9', 'mask': '0' * 767 + '1'}]}
            original = copy.deepcopy(baseline)
            candidate, _ = train({'sources': sources}, baseline)
            self.assertEqual(baseline, original)
            self.assertEqual({v['text'] for v in candidate['variants']}, {'0', '9', '1'})
            sources[2]['family'] = 'train'
            with self.assertRaisesRegex(ValueError, 'leaks'):
                train({'sources': sources}, baseline)

    def test_normalization_rejects_blank_foreground(self):
        with self.assertRaisesRegex(ValueError, 'Empty'):
            normalize(Image.new('L', (24, 32)))


if __name__ == '__main__':
    unittest.main()
