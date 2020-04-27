""" Distributor init file

Distributors: you can add custom code here to support particular distributions
of scipy.

For example, this is a good place to put any checks for hardware requirements.

The scipy standard source distribution will not put code in this file, so you
can safely replace this file with your own version.
"""

import os

# on Windows SciPy loads important DLLs
# and the code below aims to alleviate issues with DLL
# path resolution portability with an absolute path DLL load
if os.name == 'nt':
    from ctypes import WinDLL
    import glob
    # convention for storing / loading the DLL from
    # scipy/.libs/, if present
    libs_path = os.path.abspath(os.path.join(os.path.dirname(__file__),
                                             '.libs'))
    if os.path.isdir(libs_path):
        # for Python < 3.8, try to achieve brute force resolution
        # of DLLs by moving into their storage dir; should have no
        # effect for Python >= 3.8
        owd = os.getcwd()
        os.chdir(libs_path)
        for filename in glob.glob(os.path.join(libs_path, '*dll')):
            WinDLL(os.path.abspath(filename))

        os.chdir(owd)
