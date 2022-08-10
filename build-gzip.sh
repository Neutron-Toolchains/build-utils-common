#!/usr/bin/env bash
# shellcheck disable=SC2086
# A Script to build gzip
set -e

# Specify some variables.
BUILD_DIR=$(pwd)
GZIP_DIR="$BUILD_DIR/gzip"
INSTALL_DIR="$BUILD_DIR/gzip-install"
GZIP_BUILD="$BUILD_DIR/gzip-build"

cd $BUILD_DIR
rm -rf $GZIP_BUILD
mkdir -p $GZIP_BUILD
rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR
git clone https://git.savannah.gnu.org/git/gzip.git --depth=1 -b master gzip

cd $GZIP_DIR
./bootstrap
cd $GZIP_BUILD
"$GZIP_DIR"/configure \
  --prefix="$INSTALL_DIR" \
  --enable-threads=isoc+posix \
  --disable-gcc-warnings \
	CC="gcc" \
	CFLAGS="-march=x86-64 -mtune=generic -flto=auto -flto-compression-level=10 -O3 -pipe -ffunction-sections -fdata-sections" \
	LDFLAGS="-Wl,-O3,--sort-common,--as-needed,-z,now"

make -j$(($(nproc --all) + 2)) || exit 1
make install-strip -j$(($(nproc --all) + 2)) || exit 1

cd $GZIP_DIR
gzip_commit="$(git rev-parse HEAD)"
gzip_commit_url="https://git.savannah.gnu.org/cgit/gzip.git/commit/?id=$gzip_commit"
release_date="$(date "+%B %-d, %Y")"

cd $BUILD_DIR
git clone https://"${GITHUB_USERNAME}":"${GITHUB_TOKEN}"@github.com/Neutron-Toolchains/neutron-gzip.git $BUILD_DIR/neutron-gzip
cd $BUILD_DIR/neutron-gzip
rm -rf *
cd $BUILD_DIR
cp -r $INSTALL_DIR/* $BUILD_DIR/neutron-gzip
cd $BUILD_DIR/neutron-gzip
git checkout README.md
git add -A

git commit -asm "Import Neutron gzip Build Of $release_date
gzip at commit: $gzip_commit_url"
git push origin main -f
