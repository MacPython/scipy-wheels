#!/bin/bash

repo_dir=${1:-$REPO_DIR}

source multibuild/common_utils.sh

if [ ! -f $repo_dir/LICENSE.txt ]; then
    echo "ERROR: License file in $repo_dir/ missing"
    exit 1
fi

if [ -z "$IS_OSX" ]; then
    cat LICENSE_linux.txt >> $repo_dir/LICENSE.txt
else
    cat LICENSE_osx.txt >> $repo_dir/LICENSE.txt
fi

# Remove pyproject.toml so that pip doesn't try to use it
pyproject_toml="$repo_dir/pyproject.toml"
if [ -f "$pyproject_toml" ]; then
    echo "pyproject.toml is present: removing it"
    rm "$pyproject_toml"
fi
