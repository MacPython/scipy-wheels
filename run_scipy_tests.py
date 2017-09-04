""" Run scipy tests allowing for pytest and nosetests
"""

import sys

import scipy

ret = scipy.test(*sys.argv[1:], verbose=3)
if hasattr(ret, 'wasSuccessful'):
    # Nosetests version
    ret = ret.wasSuccessful()

sys.exit(not ret)
