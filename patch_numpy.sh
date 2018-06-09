#!/bin/bash
# Patch numpy distutils and compat with the version in this repo.
# Needed for correct detection of openblas on Mac.
np_root=$(dirname $(python -c "import numpy as np; print(np.__file__)"))
for sdir in distutils compat; do
    rsync --delete -r numpy-distutils/numpy/${sdir}/ ${np_root}/${sdir}
done
