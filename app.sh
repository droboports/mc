### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib"
make
make install
rm -vf "${DEST}/lib/libz.a"
popd
}

### NCURSES ###
_build_ncurses() {
local VERSION="5.9"
local FOLDER="ncurses-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://ftp.gnu.org/gnu/ncurses/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --datadir="${DEST}/share" \
  --with-shared --enable-rpath
make
make install
rm -v "${DEST}/lib"/*.a
popd
}

### LIBFFI ###
_build_libffi() {
local VERSION="3.2.1"
local FOLDER="libffi-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="ftp://sourceware.org/pub/libffi/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"

# required by glib's native compilation below
if [ ! -d "target/${FOLDER}-native" ]; then
cp -aR "target/${FOLDER}" "target/${FOLDER}-native"
( . uncrosscompile.sh
  pushd "target/${FOLDER}-native"
  ./configure --prefix="${DEPS}-native"
  make
  make install )
fi

pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static
make
make install
mkdir -p "${DEPS}/include/"
cp -v "${DEST}/lib/${FOLDER}/include"/* "${DEPS}/include/"
popd
}

### GLIB ###
_build_glib() {
local VERSION="2.45.6"
local FOLDER="glib-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="http://ftp.gnome.org/pub/gnome/sources/glib/2.45/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"

if [ ! -d "target/${FOLDER}-native" ]; then
cp -aR "target/${FOLDER}" "target/${FOLDER}-native"
( . uncrosscompile.sh
  pushd "target/${FOLDER}-native"
  PKG_CONFIG_PATH="${DEPS}-native/lib/pkgconfig" \
    ./configure --prefix="${DEPS}-native"
  make
  make install )
fi

pushd "target/${FOLDER}"
PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
  PATH="${DEPS}-native/bin:${PATH}" \
  ./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  glib_cv_stack_grows=no glib_cv_uscore=no ac_cv_func_posix_getpwuid_r=yes ac_cv_func_posix_getgrgid_r=yes
make
make install
popd
}

### SLANG ###
_build_slang() {
local VERSION="2.3.0"
local FOLDER="slang-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="http://www.jedsoft.org/releases/slang/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" \
  --with-zinc="${DEPS}/include" --with-zlib="${DEST}/lib" \
  ac_cv_path_nc5config="${DEPS}/bin/ncurses5-config"
make
make install -j1
popd
}

### MC ###
_build_mc() {
local VERSION="4.8.14"
local FOLDER="mc-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="http://ftp.midnight-commander.org/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
  ./configure --host="${HOST}" --prefix="${DEST}" --mandir="${DEST}/man"
make
make install
popd
}

### BUILD ###
_build() {
  _build_zlib
  _build_ncurses
  _build_libffi
  _build_glib
  _build_slang
  _build_mc
  _package
}
