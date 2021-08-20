# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# See env_vars.sh for extra environment variables
source gfortran-install/gfortran_utils.sh

function build_wheel {
    if [ -z "$IS_OSX" ]; then
        unset FFLAGS
        export LDFLAGS="-shared -Wl,-strip-all"
        build_libs $PLAT
        # Work round build dependencies spec in pyproject.toml
        build_bdist_wheel $@
    else
        export FFLAGS="$FFLAGS -fPIC"
        wrap_wheel_builder build_osx_wheel $@
    fi
}

function build_libs {
    PYTHON_EXE=`which python`
    $PYTHON_EXE -c"import platform; print('platform.uname().machine', platform.uname().machine)"
    basedir=$($PYTHON_EXE scipy/tools/openblas_support.py)
    $use_sudo cp -r $basedir/lib/* $BUILD_PREFIX/lib
    $use_sudo cp $basedir/include/* $BUILD_PREFIX/include
    export OPENBLAS=$BUILD_PREFIX
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

function build_wheel_with_patch {
    # Patch numpy distutils to fix OpenBLAS build
    (cd .. && ./patch_numpy.sh)
    bdist_wheel_cmd $@
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
    # Work round build dependencies spec in pyproject.toml
    # See e.g.
    # https://travis-ci.org/matthew-brett/scipy-wheels/jobs/387794282
    build_wheel_cmd "build_wheel_with_patch" "$repo_dir"
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    # OSX tests seem to time out pretty often
    if [[ -z "$IS_OSX" && `uname -m` != 'aarch64' ]]; then
        local testmode="full"
    else
        local testmode="fast"
    fi
    # Check bundled license file
    $PYTHON_EXE ../check_installed_package.py
    # Run tests
    if [[ -z "$IS_OSX" && `uname -m` != 'aarch64' ]]; then
        $PYTHON_EXE ../run_scipy_tests.py $testmode -- -n2 -rfEX
    else
        $PYTHON_EXE ../run_scipy_tests.py $testmode -- -n8 -rfEX
    fi
    # Show BLAS / LAPACK used
    $PYTHON_EXE -c 'import scipy; scipy.show_config()'
}

function install_run {
    # Override multibuild test running command, to preinstall packages
    # that have to be installed before TEST_DEPENDS.
    PIP_CMD="$PYTHON_EXE -m pip"
    $PYTHON_EXE -m pip install $(pip_opts) setuptools_scm

    # Copypaste from multibuild/common_utils.sh:install_run
    install_wheel
    mkdir tmp_for_test
    (cd tmp_for_test && run_tests)
}
