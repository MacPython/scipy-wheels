"""
run_scipy_tests.py TEST_MODE [-- PYTEST_ARGS..]

Run scipy tests allowing for pytest and nosetests
"""

import sys
import argparse


def main():
    p = argparse.ArgumentParser(usage=__doc__.strip())
    p.add_argument('test_mode', metavar='TEST_MODE')
    p.add_argument('pytest_args', metavar='PYTEST_ARGS', nargs='*')
    args = p.parse_args()

    import scipy
    print("Scipy: {} {}".format(scipy.__version__, scipy.__path__))
    ret = scipy.test(args.test_mode, extra_argv=args.pytest_args)

    if hasattr(ret, 'wasSuccessful'):
        # Nosetests version
        ret = ret.wasSuccessful()

    sys.exit(not ret)


if __name__ == "__main__":
    main()

