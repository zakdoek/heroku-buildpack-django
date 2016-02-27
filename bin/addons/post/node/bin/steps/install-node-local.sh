#!/usr/bin/env bash

# If in cache, restore from cache
if test -d $NODE_INSTALL_TARGET_CACHE/node_modules; then
    status "Found existing node_modules environment, restoring"
    rm -rf $BUILD_DIR/node_modules  # Ensure absense
    cp -r $NODE_INSTALL_TARGET_CACHE/node_modules $BUILD_DIR

    status "Prune old and unused dependencies"
    cd $BUILD_DIR
    status "Using npm version: $(npm --version)"
    npm prune --production 2>&1 | indent
    cd $current_dir_cache

    # Test if different node than original build
    if [ "$do_install_node" = true ]; then

        cd $BUILD_DIR
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

    cd $BUILD_DIR

    status "Installing dependencies"
    # Make npm output to STDOUT instead of its default STDERR
    status "Using npm version: $(npm --version)"
    npm install --production --userconfig $BUILD_DIR/.npmrc 2>&1 | indent

    cd $current_dir_cache
)

# Purge the cache
rm -rf $NODE_INSTALL_TARGET_CACHE/node_modules
if test -d $BUILD_DIR/node_modules; then
    cp -r $BUILD_DIR/node_modules $NODE_INSTALL_TARGET_CACHE/node_modules
fi

# Add node thing to environment
PATH=$BUILD_DIR/node_modules/.bin:$PATH
echo "export PATH=$BUILD_DIR/node_modules/.bin:\$PATH" >> $BUILD_DIR/.profile.d/node.sh
