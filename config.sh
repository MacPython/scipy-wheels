# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

# Enable Python fault handler on Pythons >= 3.3.
PYTHONFAULTHANDLER=1

# OpenBLAS version for systems that use it.
OPENBLAS_VERSION=0.2.18

source gfortran-install/gfortran_utils.sh

function build_wheel {
  export FFLAGS="$FFLAGS -fPIC -Wl,-strip-all"
    if [ -z "$IS_OSX" ]; then
        build_libs $PLAT
        build_pip_wheel $@
    else
        build_osx_wheel $@
    fi
}

function build_libs {
    if [ -n "$IS_OSX" ]; then return; fi  # No OpenBLAS for OSX
    local plat=${1:-$PLAT}
    local tar_path=$(abspath $(get_gf_lib "openblas-${OPENBLAS_VERSION}" "$plat"))
    (cd / && tar zxf $tar_path)
}

function set_arch {
    local arch=$1
    export CC="clang $arch"
    export CXX="clang++ $arch"
    export CFLAGS="$arch"
    export FFLAGS="$arch"
    export FARCH="$arch"
    export LDFLAGS="$arch"
}

function build_osx_wheel {
    # Build 64-bit wheel
    # Standard gfortran won't build dual arch objects.
    local repo_dir=${1:-$REPO_DIR}
    local py_ld_flags="-Wall -undefined dynamic_lookup -bundle"

    install_gfortran
    # 64-bit wheel
    local arch="-m64"
    set_arch $arch
    build_libs x86_64
    # Build wheel
    export LDSHARED="$CC $py_ld_flags"
    export LDFLAGS="$arch $py_ld_flags"
    build_pip_wheel "$repo_dir"
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    # OSX tests seem to time out pretty often
    if [ -z "$IS_OSX" ]; then
        local testmode="full"
    else
        local testmode="fast"
    fi
    # Check bundled license file
    python ../check_license.py
    # Run tests
    python ../run_scipy_tests.py $testmode -- -n2 -rfEX
    # Show BLAS / LAPACK used
    python -c 'import scipy; scipy.show_config()'
}
