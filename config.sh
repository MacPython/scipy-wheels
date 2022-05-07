# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# See env_vars.sh for extra environment variables
source gfortran-install/gfortran_utils.sh

function build_wheel {
    export FFLAGS="$FFLAGS -fPIC"
    if [ -z "$IS_OSX" ]; then
        build_libs $PLAT
        # Work round build dependencies spec in pyproject.toml
        build_bdist_wheel $@
    else
        install_gfortran
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

function build_wheel_with_patch {
    # Patch numpy distutils to fix OpenBLAS build
    (cd .. && ./patch_numpy.sh)
    bdist_wheel_cmd $@
}

function build_osx_wheel {
    local repo_dir=${1:-$REPO_DIR}
    if [ ! -z "$FC" ]; then
       export F77=$FC
       export F90=$FC
    fi
    build_libs
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
    set -ex
    PIP_CMD="$PYTHON_EXE -m pip"
    $PYTHON_EXE -m pip install $(pip_opts) setuptools_scm

    # Copypaste from multibuild/common_utils.sh:install_run
    install_wheel
    mkdir tmp_for_test
    (cd tmp_for_test && run_tests)
}

function clean_code {
    local repo_dir=${1:-$REPO_DIR}
    git config --global --add safe.directory "*"
    git config --global --add safe.directory "$repo_dir"
    local build_commit=${2:-$BUILD_COMMIT}
    [ -z "$repo_dir" ] && echo "repo_dir not defined" && exit 1
    [ -z "$build_commit" ] && echo "build_commit not defined" && exit 1
    # The package $repo_dir may be a submodule. git submodules do not
    # have a .git directory. If $repo_dir is copied around, tools like
    # Versioneer which require that it be a git repository are unable
    # to determine the version.  Give submodule proper git directory
    fill_submodule "$repo_dir"
    (cd $repo_dir \
        && git config --global --add safe.directory "*" \
        && git fetch origin \
        && git checkout $build_commit \
        && git clean -fxd \
        && git reset --hard \
        && git submodule update --init --recursive)
}
