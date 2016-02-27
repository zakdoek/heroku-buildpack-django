#!/usr/bin/env bash

# Look in package.json's engines.node field for a semver range
semver_range=$(cat $BUILD_DIR/package.json | $bp_dir/vendor/jq -r .engines.node)

# Resolve node version using semver.io
node_version=$(curl --silent --get --data-urlencode "range=${semver_range}" https://semver.io/node/resolve)

# Recommend using semver ranges in a safe manner
if [[ "$semver_range" == "null" ]]; then
  protip "Specify a node version in package.json"
  semver_range=""
elif [[ "$semver_range" == "*" ]]; then
  protip "Avoid using semver ranges like '*' in engines.node"
elif [[ ${semver_range:0:1} == ">" ]]; then
  protip "Avoid using semver ranges starting with '>' in engines.node"
fi

# Output info about requested range and resolved node version
if [[ "$semver_range" == "" ]]; then
  status "Defaulting to latest stable node: $node_version"
else
  status "Requested node range:  $semver_range"
  status "Resolved node version: $node_version"
fi

# Test if a correct node is already in cache
do_install_node=true

# Fetch the cached node version
if [[ -f "$NODE_INSTALL_TARGET_CACHE/node-version" ]]; then
    cached_node_version=$(cat "$NODE_INSTALL_TARGET_CACHE/node-version")

    status "The cached node version is $cached_node_version"
    status "The current node version is $node_version"

    # Test against desired node version
    if [[ "$cached_node_version" == "$node_version" ]]; then
        do_install_node=false
    fi
fi

if [[ "$do_install_node" = "true" ]]; then
    # Download node from Heroku's S3 mirror of nodejs.org/dist
    status "Downloading and installing node"
    node_url="http://s3pository.heroku.com/node/v$node_version/node-v$node_version-linux-x64.tar.gz"
    curl $node_url -s -o - | tar xzf - -C $NODE_INSTALL_TARGET

    # Move node (and npm)
    rm -rf $NODE_INSTALL_TARGET/node  # Ensure the dest folder does not exist
    mv $NODE_INSTALL_TARGET/node-v$node_version-linux-x64 $NODE_INSTALL_TARGET/node
    chmod +x $NODE_INSTALL_TARGET/node/bin/*  # Make all the things executable

    # Cache the node executable for future use
    rm -rf $NODE_INSTALL_TARGET_CACHE/node
    status "Caching node executable for future builds"
    cp -r $NODE_INSTALL_TARGET/node $NODE_INSTALL_TARGET_CACHE/node
    echo "$node_version" > $NODE_INSTALL_TARGET_CACHE/node-version
else
    # Copy from cache
    status "Fetching node runtime from cache"
    rm -rf $NODE_INSTALL_TARGET/node
    cp -r $NODE_INSTALL_TARGET_CACHE/node $NODE_INSTALL_TARGET/node
fi

# Add to path
export PATH=$NODE_INSTALL_TARGET/node/bin:$PATH
echo "export PATH=$NODE_INSTALL_TARGET/node/bin:\$PATH" >> $BUILD_DIR/.profile.d/node.sh
