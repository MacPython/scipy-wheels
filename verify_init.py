"""
Small CLI script that accepts the path to a directory containing one
or more wheel files.

Check that a wheel appropriately includes/excludes
_distributor_init.py with the contents of that same
file in the wheels repo.
"""

import sys
import pathlib
from zipfile import ZipFile


def check_for_dist_init(input_dir):
    p = pathlib.Path(input_dir)
    wheel_files = p.glob('**/*.whl')
    for wheel_file in wheel_files:
        with ZipFile(wheel_file) as zipf:
            file_names = zipf.namelist()
            dist_init_found = 0
            for file_name in file_names:
                if "_distributor_init.py" in file_name:
                    dist_init_found += 1
                    with zipf.open(file_name) as actual_file:
                        with open("_distributor_init.py", 'rb') as reference_file:
                            # currently just MacOS and Windows should have _distributor_init.py
                            # copied in from wheels repo; Linux should just have a generic
                            # version of the file
                            if "-macosx" in str(wheel_file) or "-win" in str(wheel_file):
                                actual_content = actual_file.read()
                                expected_content = reference_file.read()
                                if not actual_content == expected_content:
                                    raise ValueError(f"Contents of _distributor_init.py incorrect for {wheel_file}")
            if not dist_init_found:
                raise FileNotFoundError(f"_distributor_init.py missing from {wheel_file}")

if __name__ == "__main__":
    input_dir = sys.argv[1]
    check_for_dist_init(input_dir=input_dir)
