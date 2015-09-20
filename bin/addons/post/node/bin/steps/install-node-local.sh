#!/usr/bin/env bash

# If in cache, restore from cache
if test -d $build_dependencies_cache/node_modules; then
    status "Found existing node_modules environment, restoring"
    rm -rf $build_dir/node_modules  # Ensure absense
    cp -r $build_dependencies_cache/node_modules $build_dir

    status "Prune old and unused dependencies"
    cd $build_dir
    npm prune --production 2>&1 | indent
    cd $current_dir_cache

    # Test if different node than original build
    if [ "$do_install_node" = true ]; then

        cd $build_dir
        status "Node version changed since last build; rebuilding dependencies"
        npm rebuild 2>&1 | indent
        cd $current_dir_cache

    fi
 
fi

# Scope config var availability only to `npm install`
(
    if test -d $env_dir; then
        status "Exporting config vars to environment"
        export_env_dir $env_dir
    fi

    cd $build_dir

    status "Installing dependencies"
    # Make npm output to STDOUT instead of its default STDERR
    npm install --production --userconfig $build_dir/.npmrc 2>&1 | indent

    cd $current_dir_cache
)

# Purge the cache
rm -rf $build_dependencies_cache/node_modules
if test -d $build_dir/node_modules; then
    cp -r $build_dir/node_modules $build_dependencies_cache/node_modules
fi

# Add node thing to environment
PATH=$build_dir/node_modules/.bin:$PATH
# echo "export PATH=\"$build_dir/node_modules/.bin:\$PATH\"" >> $build_activate
