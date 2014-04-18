#!/bin/sh

fail() { echo "Compilation failed!" ; exit 1; }

false && { # ===== Do not compile libfakechroot and libfakedns, they are not used anymore =====

cd fakechroot
[ -e configure ] || ./autogen.sh || fail
[ -e config.h ] || ./configure --host=arm-linux-gnueabihf --prefix=/usr || fail
[ -e ../libfakechroot.so ] || {
	make -j4 CFLAGS="-march=armv7-a -fpic" LDFLAGS="-march=armv7-a" V=1 && \
	cp -f src/.libs/libfakechroot.so .. && \
	arm-linux-gnueabihf-strip ../libfakechroot.so || fail
} || fail
cd ..

cd c-ares
[ -e ares_config.h ] || LIBS=-Wl,--version-script=exports.txt \
	./configure --enable-shared --host=arm-linux-gnueabihf --prefix=/usr || fail
[ -e ../libfakedns.so ] || {
	make -j4 CFLAGS="-march=armv7-a -fpic" LDFLAGS="-march=armv7-a" libcares.la && \
	cp -f .libs/libcares.so ../libfakedns.so && \
	arm-linux-gnueabihf-strip ../libfakedns.so || fail
} || fail
cd ..

[ -e libfakedns.so ] || {
	arm-linux-gnueabihf-gcc -march=armv7-a -shared -fpic fakedns/*.c -I c-ares c-ares/.libs/libcares.a -o libfakedns.so && \
	arm-linux-gnueabihf-strip libfakedns.so || fail
} || fail

} # ===== libfakechroot and libfakedns =====

[ -e libdisableselinux.so ] || {
	arm-linux-gnueabihf-gcc -march=armv7-a -shared -fpic disableselinux/*.c -o libdisableselinux.so && \
	arm-linux-gnueabihf-strip libdisableselinux.so || fail
} || fail

[ -e libandroid-shmem.so ] || {
	[ -e android-shmem/LICENSE ] || {
		cd ..
		git submodule update --init android/android-shmem || fail
		cd $BUILDDIR
	} || exit 1
	[ -e android-shmem/libancillary/ancillary.h ] || {
		cd android-shmem
		git submodule update --init libancillary || fail
		cd ..
	} || exit 1

	cd android-shmem
	arm-linux-gnueabihf-gcc -march=armv7-a -shared -fpic -std=gnu99 *.c -I . -I libancillary \
		-o ../libandroid-shmem.so -Wl,--version-script=exports.txt -lc -lpthread && \
	arm-linux-gnueabihf-strip ../libandroid-shmem.so || fail
	cd ..
} || fail

[ -e libtalloc.a ] || {
	[ -e talloc-2.1.0 ] || curl http://www.samba.org/ftp/talloc/talloc-2.1.0.tar.gz | tar xvz || fail
	cd talloc-2.1.0
	make clean
	env CC=arm-linux-gnueabihf-gcc ./configure build --cross-compile --cross-execute='qemu-arm-static /usr/arm-linux-gnueabihf/lib/ld-linux.so.3 --library-path /usr/arm-linux-gnueabihf/lib' || fail
	#cp -f libtalloc.so ../libtalloc.so || fail
	ar rcs ../libtalloc.a bin/default/talloc*.o # bin/default/lib/replace/replace*.o 
	cd ..
} || fail

[ -e proot ] || {
	cd proot-src/src
	make clean
	env CC=arm-linux-gnueabihf-gcc CFLAGS="-I../../talloc-2.1.0 -Wall -Wextra -O2" LDFLAGS="-L../.. -ltalloc -static" V=1 make -e || fail
	cp proot ../../
	cd ../..
	arm-linux-gnueabihf-strip proot
} || fail

CFLAGSx86="-march=i686 -mtune=atom -mstackrealign -msse3 -mfpmath=sse -m32"

[ -e dist-x86/libdisableselinux.so ] || {
	gcc $CFLAGSx86 -shared -fpic disableselinux/*.c -o dist-x86/libdisableselinux.so && \
	strip dist-x86/libdisableselinux.so || fail
} || fail

[ -e dist-x86/libandroid-shmem.so ] || {
	cd android-shmem
	gcc $CFLAGSx86 -shared -fpic -std=gnu99 *.c -I . -I libancillary \
		-o ../dist-x86/libandroid-shmem.so -Wl,--version-script=exports.txt -lc -lpthread && \
	strip ../dist-x86/libandroid-shmem.so || fail
	cd ..
} || fail

[ -e libtalloc-x86.a ] || {
	cd talloc-2.1.0
	make clean
	env CC=gcc CFLAGS="$CFLAGSx86" LD=gcc LDFLAGS="$CFLAGSx86" ./configure build || fail
	#cp -f libtalloc.so ../libtalloc.so || fail
	ar rcs ../libtalloc-x86.a bin/default/talloc*.o # bin/default/lib/replace/replace*.o 
	cd ..
} || fail

[ -e dist-x86/proot ] || {
	cd proot-src/src
	make clean
	env CC=gcc CFLAGS="$CFLAGSx86 -I../../talloc-2.1.0 -Wall -Wextra -O2" LDFLAGS="$CFLAGSx86 -L../.. -ltalloc-x86 -static" V=1 make -e || fail
	cp proot ../../dist-x86/
	cd ../..
	strip dist-x86/proot
} || fail
