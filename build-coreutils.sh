#!/usr/bin/env bash
# shellcheck disable=SC2086
# A Script to build GNU coreutils
set -e

# Specify some variables.
BUILD_DIR=$(pwd)
COREUTILS_DIR="$BUILD_DIR/coreutils"
INSTALL_DIR="$BUILD_DIR/coreutils-install"
COREUTILS_BUILD="$BUILD_DIR/coreutils-build"

cd $BUILD_DIR
rm -rf $COREUTILS_BUILD
mkdir -p $COREUTILS_BUILD
rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR
git clone https://git.savannah.gnu.org/git/coreutils.git --depth=1 -b master coreutils

cd $COREUTILS_DIR
./bootstrap
cd $COREUTILS_BUILD
"$COREUTILS_DIR"/configure \
	--prefix="$INSTALL_DIR" \
	--libexecdir="$INSTALL_DIR/lib" \
	CC="gcc" \
	CFLAGS="-march=x86-64 -mtune=generic -flto=auto -flto-compression-level=10 -O3 -pipe -ffunction-sections -fdata-sections" \
	LDFLAGS="-Wl,-O3,--sort-common,--as-needed,-z,now" \
	--enable-threads=isoc+posix \
	--enable-single-binary=symlinks \
	--with-openssl \
	--enable-single-binary-exceptions=groups,hostname,kill,uptime \
	--enable-no-install-program=groups,hostname,kill,uptime

make -j$(($(nproc --all) + 2))
make install-strip -j$(($(nproc --all) + 2))

cd $COREUTILS_DIR
coreutils_commit="$(git rev-parse HEAD)"
coreutils_commit_url="https://git.savannah.gnu.org/cgit/coreutils.git/commit/?id=$coreutils_commit"
release_date="$(date "+%B %-d, %Y")"

cd $BUILD_DIR
git clone https://"${GITHUB_USERNAME}":"${GITHUB_TOKEN}"@github.com/Neutron-Toolchains/neutron-coreutils.git $BUILD_DIR/neutron-coreutils
cd $BUILD_DIR/neutron-coreutils
rm -rf *
cd $BUILD_DIR
cp -r $INSTALL_DIR/* $BUILD_DIR/neutron-coreutils
cd $BUILD_DIR/neutron-coreutils
git checkout README.md
git add -A

git commit -asm "Import Neutron Coreutils Build Of $release_date
Coreutils at commit: $coreutils_commit_url"
git push origin main -f
