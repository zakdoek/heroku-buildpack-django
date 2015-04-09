#!/usr/bin/env bash

# Install compass
status "Installing Compass"

# Ensuring environment
RUBY_VERSION=$(ruby -e "require 'rbconfig';puts \"#{RUBY_ENGINE}/#{RbConfig::CONFIG['ruby_version']}\"")
export GEM_HOME=$build_dependencies/.gem/$RUBY_VERSION
PATH="$GEM_HOME/bin:$PATH"

if test -d $build_dependencies_cache/ruby; then

    status "Restoring ruby gems directory from cache"
    rm -rf $build_dependencies/.gem  # Ensure none is present
    cp -r $build_dependencies_cache/ruby $build_dependencies/.gem

    status "Try to update compass"
    cd $build_dependencies
    HOME=$build_dependencies gem update compass --user-install --no-rdoc --no-ri 2>&1 | indent
    HOME=$current_home_cache  # Reset home to current dir
    cd $current_dir_cache

else

    status "Compass not present, installing a fresh one"
    cd $build_dependencies
    HOME=$build_dependencies gem install compass --user-install --no-rdoc --no-ri 2>&1 | indent
    HOME=$current_home_cache # Reset home to current dir
    cd $current_dir_cache

fi

# Cache ruby gems
rm -rf $build_dependencies_cache/ruby

# If app has a gems directory, cache it.
if test -d $build_dependencies/.gem; then
    status "Caching ruby gems directory for future builds"
    cp -r $build_dependencies/.gem $build_dependencies_cache/ruby
fi

# Add to environment
# echo "export GEM_HOME=$GEM_HOME" >> $build_activate
# echo "export PATH=\"$GEM_HOME/bin:\$PATH\"" >> $build_activate
