#!/usr/bin/env bash

# Install bower dependencies
if test -f $build_dir/bower.json; then

    status "Install bower dependencies"
    if test -d $build_dependencies_cache/bower; then

        status "Restoring bower components from cache"
        rm -rf $build_dir/bower_components  # Ensure absence
        cp -r $build_dependencies_cache/bower $build_dir/bower_components

    fi
    
    cd $build_dir
    bower install  2>&1 | indent
    cd $current_dir_cache

    # Cache bower
    rm -rf $build_dependencies_cache/bower  # Ensure absence

    # If app has a bower directory, cache it.
    if test -d $build_dir/bower_components; then
        status "Caching bower cache directory for future builds"
        cp -r $build_dir/bower_components $build_dependencies_cache/bower
    fi
fi
