# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    if [ -n "$IS_OSX" ]; then
        sudo installer -pkg archives/gfortran-4.2.3.pkg -target /
    else
        build_openblas
        # Force scipy to use OpenBLAS regardless of what numpy uses
        cat << EOF > $HOME/site.cfg
[openblas]
library_dirs = /usr/local/lib
include_dirs = /usr/local/include
EOF
    fi
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    test_cmd="import sys; import scipy; sys.exit(not scipy.test('full').wasSuccessful())"
    if [ -n "$IS_OSX" ]; then  # Test both architectures on OSX
        arch -i386 python -c "$test_cmd"
        arch -x86_64 python -c "$test_cmd"
    else  # Not OSX
        python -c "$test_cmd"
    fi
    # Show BLAS / LAPACK used
    python -c 'import scipy; scipy.show_config()'
}
