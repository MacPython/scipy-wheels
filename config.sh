# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    if [ -n "$IS_OSX" ]; then
        sudo installer -pkg archives/gfortran-4.2.3.pkg -target /
    else
        build_openblas
    fi
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    if [ -n "$IS_OSX" ]; then
        python -c 'import scipy; scipy.test("full")'
    else  # Test both architectures on OSX
        arch -i386 python -c 'import scipy; scipy.test("full")'
        arch -x86_64 python -c 'import scipy; scipy.test("full")'
    fi
    # Show BLAS / LAPACK used
    python -c 'import scipy; scipy.show_config()'
}
