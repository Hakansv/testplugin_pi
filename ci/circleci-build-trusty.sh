#!/usr/bin/env bash

#
# Build the Trusty Ubuntu artifacts
#
set -xe
sudo apt-get -qq update
sudo apt-get install devscripts equivs

rm -rf build && mkdir build && cd build
mk-build-deps ../ci/control
sudo apt-get install  ./*all.deb  || :
sudo apt-get --allow-unauthenticated install -f
rm -f ./*all.deb

tag=$(git tag --contains HEAD)

if [ -n "$BUILD_GTK3" ]; then
  sudo update-alternatives --set wx-config /usr/lib/*-linux-*/wx/config/gtk3-unicode-3.0
fi

if [ -n "$tag" ]; then
  cmake -DCMAKE_BUILD_TYPE=Release ..
else
  cmake -DCMAKE_BUILD_TYPE=Debug ..
fi

make -j2
make package
ls -l

# install cloudsmith-cli, used in upload.
sudo apt-get install python3-pip python3-setuptools
sudo python3 -m pip install -q cloudsmith-cli
