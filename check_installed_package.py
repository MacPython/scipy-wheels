#!/usr/bin/env python
"""
check_installed_package.py [MODULE]

Check the presence of a LICENSE.txt in the installed module directory,
and that it appears to contain text prevalent for a Scipy binary
distribution.

On Windows, also check that all DLLs packaged in the SciPy
wheel reside at the same path---see gh-57.

"""
import os
import sys
import io
import re
import argparse
import platform
from pathlib import Path

def check_text(text):
    ok = (
        u'Copyright (c)' in text and
        re.search(u'The SciPy repository and source distributions bundle') and
        re.search(u'This binary distribution of \w+ also bundles the following software', text)
    )
    return ok

def check_dll_paths(mod):
    # all DLLs packaged in SciPy should have the
    # same path; see issue gh-57
    install_basedir = os.path.dirname(mod.__file__)
    list_filepaths = []

    for filename in Path(install_basedir).rglob('*.dll'):
        list_filepaths.append(filename)

    reference_basepath = os.path.dirname(str(list_filepaths.pop(0)))

    for filepath in list_filepaths:
        if os.path.dirname(str(filepath)) != reference_basepath:
            print("mismatch between current DLL file path: ",
                   filepath,
                   "and the reference file path for packaged DLLs: ",
                   reference_basepath)
            sys.exit(1)


def main():
    p = argparse.ArgumentParser(usage=__doc__.rstrip())
    p.add_argument('module', nargs='?', default='scipy')
    args = p.parse_args()

    # Drop '' from sys.path
    sys.path.pop(0)

    # Find module path
    __import__(args.module)
    mod = sys.modules[args.module]

    # Check license text - note that the license file is not installed inside
    # the package, but in the `scipy-x.y.z.dist-info` dir right next to it
    site_packages = Path(mod.__file__).parent.parent
    scipy_distinfo = [
        path for path in os.listdir(site_packages) if "scipy" in path and
        ".dist-info" in path
    ]
    if len(scipy_distinfo) > 1:
        raise RuntimeError("Found multiple .dist-info dirs, not expected")

    distinfo_dir = site_packages / scipy_distinfo[0]
    license_txt = distinfo_dir / 'LICENSE.txt'
    with io.open(license_txt, 'r', encoding='utf-8') as f:
        text = f.read()

    ok = check_text(text)
    if not ok:
        print("ERROR: License text {} does not contain expected "
              "text fragments\n".format(license_txt))
        print(text)
        sys.exit(1)


    if platform.system() == 'Windows':
        check_dll_paths(mod)

    sys.exit(0)


if __name__ == "__main__":
    main()
