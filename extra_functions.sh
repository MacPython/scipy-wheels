function rename_wheel {
    # Call with a name like scipy-1.5.0.dev0+58dbafa-cp37-cp37m-linux_x86_64.whl

    # Add a date after the dev0+ and before the hash in yyymmddHHMMSS format
    # so pip will pick up the newest build. Try a little to make sure
    # - the first part ends with 'dev0+'
    # - the second part starts with a lower case alphanumeric then a '-'
    # if those conditions are not met, the name will be returned as-is

    newname=$(echo "$1" | sed "s/\(.*dev0+\)\([a-z0-9]*-.*\)/\1$(date '+%Y%m%d%H%M%S_')\2/")
    if [ "$newname" != "$1" ]; then
        mv $1 $newname
    fi
}
