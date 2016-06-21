# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    if [ -n "$IS_OSX" ]; then
        sudo installer -pkg archives/gfortran-4.2.3.pkg -target /
        return
    fi
    # Rackspace builds of openblas
    local lib_url=https://d9a97980b71d47cde94d-aae005c4999d7244ac63632f8b80e089.ssl.cf2.rackcdn.com
    local lib_tgz="openblas_0.2.18-$(get_platform).tgz"
    (cd / && curl -LO $lib_url/${lib_tgz} && tar zxf $lib_tgz)
    # Force scipy to use OpenBLAS regardless of what numpy uses
    cat << EOF > $HOME/site.cfg
[openblas]
library_dirs = /usr/local/lib
include_dirs = /usr/local/include
EOF
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    if [ -n "$IS_OSX" ]; then  # Test both architectures on OSX
        # Can't afford full tests when running both test rigs in same job
        test_cmd="import sys; import scipy; sys.exit(not scipy.test().wasSuccessful())"
        arch -i386 python -c "$test_cmd"
        arch -x86_64 python -c "$test_cmd"
    else  # Not OSX
        test_cmd="import sys; import scipy; sys.exit(not scipy.test('full').wasSuccessful())"
        python -c "$test_cmd"
    fi
    # Show BLAS / LAPACK used
    python -c 'import scipy; scipy.show_config()'
}
