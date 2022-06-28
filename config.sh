# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# See env_vars.sh for extra environment variables
source gfortran-install/gfortran_utils.sh

function pyproject_wheel_cmd {
    # Build wheels with `build` (uses build isolation, and dependencies listed
    # in pyproject.toml)
    $PYTHON_EXE -m pip install build
    $PYTHON_EXE -m build --wheel
}

function build_wheel {
    local repo_dir=${1:-$REPO_DIR}
    if [ -z "$IS_OSX" ]; then
        copy_libs $PLAT
        build_wheel_cmd "pyproject_wheel_cmd" "$repo_dir"
    else
        install_gfortran
        # `wrap_wheel_builder` is a no-op except on macOS when cross-compiling
        # to arm64
        wrap_wheel_builder pyproject_wheel_cmd $@
    fi
}

function copy_libs {
    PYTHON_EXE=`which python`
    $PYTHON_EXE -c"import platform; print('platform.uname().machine', platform.uname().machine)"
    basedir=$($PYTHON_EXE scipy/tools/openblas_support.py)
    $use_sudo cp -r $basedir/lib/* $BUILD_PREFIX/lib
    $use_sudo cp $basedir/include/* $BUILD_PREFIX/include
    export OPENBLAS=$BUILD_PREFIX
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
    set -ex

    # Copypaste from multibuild/common_utils.sh:install_run
    install_wheel --prefer-binary
    mkdir tmp_for_test
    (cd tmp_for_test && run_tests)
}
