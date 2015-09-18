#!/usr/bin/env bash

# Look in package.json's engines.node field for a semver range
semver_range=$(cat $build_dir/package.json | $bp_dir/vendor/jq -r .engines.node)

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
if [[ -f "$build_dependencies_cache/node-version" ]]; then
    cached_node_version=$(cat "$build_dependencies_cache/node-version")

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
    curl $node_url -s -o - | tar xzf - -C $build_dependencies

    # Move node (and npm)
    rm -rf $build_dependencies/node  # Ensure the dest folder does not exist
    mv $build_dependencies/node-v$node_version-linux-x64 $build_dependencies/node
    chmod +x $build_dependencies/node/bin/*  # Make all the things executable

    # Cache the node executable for future use
    rm -rf $build_dependencies_cache/node
    status "Caching node executable for future builds"
    cp -r $build_dependencies/node $build_dependencies_cache/node
    echo "$node_version" > $build_dependencies_cache/node-version
else
    # Copy from cache
    status "Fetching node runtime from cache"
    rm -rf $build_dependencies/node
    cp -r $build_dependencies_cache/node $build_dependencies/node
fi

# Add to path
PATH=$build_dependencies/node/bin:$PATH
