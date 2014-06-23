# -*- coding: utf-8 -*-
from __future__ import (print_function, division, absolute_import, unicode_literals, )


from unittest import TestCase, main

from python_hl_lvar import extract_assignment


class ExtractTest(TestCase):

    def test_extruct_arguments(self):
        content = '''
def arg(a, b, c):
    return a, b, c'''
        ret = extract_assignment(content)
        self.assertEqual(ret, ['a', 'b', 'c', ])

    def test_for_statement(self):
        content = '''
def for_s(word):
    for l in word:
        pass
    for i, letter in enumerate(word):
        yield i, letter
'''
        ret = extract_assignment(content)
        self.assertListEqual(ret, ['word', 'l', 'i', 'letter', ])


    def test_with_statement(self):
        content = '''
def for_s():
    with none():
        pass
    with open('a') as f:
        f.read()
    with A() as e, B() as g:
        return e.read()
'''
        ret = extract_assignment(content)
        self.assertListEqual(ret, ['f', 'e', 'g', ])


if __name__ == '__main__':
    main()
