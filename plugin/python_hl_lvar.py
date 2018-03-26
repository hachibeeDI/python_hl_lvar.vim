# -*- coding: utf-8 -*-
from __future__ import (print_function, division, absolute_import, unicode_literals, )

import sys
from logging import (Formatter, getLogger, StreamHandler, DEBUG, NullHandler, )
logger = getLogger(__name__)
try:
    import vim
    if int(vim.eval('g:python_hl_lvar_verbose')):
        handler = StreamHandler()
    else:
        handler = NullHandler()
except ImportError:
    handler = StreamHandler()
handler.setFormatter(Formatter("%(levelname)s: [in %(funcName)s] '%(message)s'"))
handler.setLevel(DEBUG)
logger.setLevel(DEBUG)
logger.addHandler(handler)

if sys.version_info < (3, 0, 0):
    TEXT_TYPE = basestring
else:
    TEXT_TYPE = str

import ast
from itertools import takewhile


def _provide_style_for_definition(given):
    if isinstance(given, TEXT_TYPE):
        given = given.strip().splitlines()
    tabspace = len(list(takewhile(lambda x: x == ' ', given[0])))
    func_definition_exclude_tabspace = '\n'.join([line[tabspace:] for line in given])

    logger.debug('highlight target -> \n' + func_definition_exclude_tabspace)
    return func_definition_exclude_tabspace


def extract_assignment(given_funcdef):
    if not given_funcdef:
        return []
    func_definition = _provide_style_for_definition(given_funcdef)
    definition_node = ast.walk(ast.parse(func_definition, mode='single').body[0])
    next(definition_node)
    result = []
    result_add = result.extend
    result_append = result.append
    for z in definition_node:  # TODO: cleanup
        # print(z)
        if isinstance(z, ast.arguments):
            v = [getattr(a, 'id', None) for a in z.args]
            result_add(filter(bool, v))
        elif isinstance(z, ast.Assign):
            v = [getattr(v, 'id', None) for v in z.targets]
            result_add(filter(bool, v))
        elif isinstance(z, ast.For):
            if isinstance(z.target, ast.Name):
                result_append(z.target.id)
            elif isinstance(z.target, ast.Tuple):
                result_add(elt.id for elt in z.target.elts)
        elif isinstance(z, ast.With):
            if z.optional_vars:
                result_append(z.optional_vars.id)
    return result


def interface_for_vim(start_of_line, end_of_line):
    logger.debug(' '.join(('called', 'from:', start_of_line, 'to:', end_of_line, )))
    func_definition_lines = vim.current.buffer[int(start_of_line) - 1:int(end_of_line)]
    logger.debug('eval ->\n' + '\n'.join(func_definition_lines))

    # cmd = 'let s:result = {0}'.format(repr(assignments))
    try:
        assignments = extract_assignment(func_definition_lines)
        return assignments
    except Exception as e:
        logger.error(str(e))
        return []


if __name__ == '__main__':
    from sys import argv
    interface_for_vim(argv[1], argv[2])
