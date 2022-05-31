#!/bin/bash

set -e
set -x

BASE=`pwd`
SRC=$BASE/src
PATCHES=$BASE/patches
RPATH=$PREFIX/lib
DEST=$BASE$PREFIX
LDFLAGS="-L$DEST/lib -s"
CPPFLAGS="-I$DEST/include"
CFLAGS=$EXTRACFLAGS
CXXFLAGS=$CFLAGS
CONFIGURE="./configure --prefix=$PREFIX --host=$DESTARCH-linux"
MAKE="make -j$(nproc)"
export CCACHE_DIR=$HOME/.ccache_rust

########### #################################################################
# OPENSSL # #################################################################
########### #################################################################

OPENSSL_VERSION=1.1.1o

cd $SRC/openssl

if [ ! -f .extracted ]; then
	rm -rf openssl openssl-${OPENSSL_VERSION}
	tar zxvf openssl-${OPENSSL_VERSION}.tar.gz
	mv openssl-${OPENSSL_VERSION} openssl
	touch .extracted
fi

cd openssl

if [ ! -f .configured ]; then
	./Configure linux-armv4 -march=armv7-a -mtune=cortex-a9 \
	--prefix=$PREFIX
	touch .configured
fi

if [ ! -f .built ]; then
	make CC=$DESTARCH-linux-gcc
	touch .built
fi

if [ ! -f .installed ]; then
	make install CC=$DESTARCH-linux-gcc INSTALLTOP=$DEST OPENSSLDIR=$DEST/ssl
	touch .installed
fi

############### #############################################################
# VAULTWARDEN # #############################################################
############### #############################################################

cd $SRC

if [ ! -f .cloned ]; then
	git clone https://github.com/dani-garcia/vaultwarden.git
	touch .cloned
fi
	cd vaultwarden
	git checkout 1.24.0

	CC_armv7_unknown_linux_musleabi=/opt/tomatoware/arm-soft-musl/bin/arm-linux-gcc \
	CXX_armv7_unknown_linux_musleabi=/opt/tomatoware/arm-soft-musl/bin/arm-linux-g++ \
	AR_armv7_unknown_linux_musleabi=/opt/tomatoware/arm-soft-musl/bin/arm-linux-ar \
	CFLAGS_armv7_unknown_linux_musleabi="-march=armv7-a -mtune=cortex-a9" \
	CXXFLAGS_armv7_unknown_linux_musleabi="-march=armv7-a -mtune=cortex-a9" \
	CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABI_LINKER=/opt/tomatoware/arm-soft-musl/bin/arm-linux-gcc \
	CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABI_RUSTFLAGS='-Clink-arg=-s -Ctarget-feature=+crt-static' \
	OPENSSL_DIR=$DEST \
	OPENSSL_STATIC=1 \
	cargo \
	build \
	--target armv7-unknown-linux-musleabi \
	--release \
	--features sqlite

	cp $SRC/vaultwarden/target/armv7-unknown-linux-musleabi/release/vaultwarden $BASE
