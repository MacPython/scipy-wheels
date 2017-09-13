#!/bin/bash

repo_dir=${1:-$REPO_DIR}

source multibuild/common_utils.sh

if [ -z "$IS_OSX" ]; then
    cat LICENSE_linux.txt >> $repo_dir/LICENSE.txt
else
    cat LICENSE_osx.txt >> $repo_dir/LICENSE.txt
fi
