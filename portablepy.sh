#!/usr/bin/env bash
set -e

PY_VERSION=3.11.7
PREFIX_DIR="$(pwd)/python-portable"
BUILD_DIR="$(pwd)/build-python"

echo "==> Installing build dependencies"
sudo apt-get update
sudo apt-get install -y \
  build-essential wget curl \
  libssl-dev zlib1g-dev \
  libncurses5-dev libncursesw5-dev \
  libreadline-dev libsqlite3-dev \
  libgdbm-dev libbz2-dev libexpat1-dev \
  liblzma-dev tk-dev libffi-dev \
  patchelf

echo "==> Preparing directories"
rm -rf "$BUILD_DIR" "$PREFIX_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "==> Downloading Python $PY_VERSION"
wget https://www.python.org/ftp/python/$PY_VERSION/Python-$PY_VERSION.tgz
tar -xzf Python-$PY_VERSION.tgz
cd Python-$PY_VERSION

echo "==> Configuring Python (shared build)"
./configure \
  --prefix="$PREFIX_DIR" \
  --enable-shared \
  --with-ensurepip=install

echo "==> Building Python"
make -j$(nproc)
make install

cd "$PREFIX_DIR"

echo "==> Creating lib directory"
mkdir -p lib

echo "==> Copying required shared libraries"

# Detect system lib directory
LIBDIR="/usr/lib/x86_64-linux-gnu"

# Core libs to bundle
cp -v $LIBDIR/libssl.so.* lib/ || true
cp -v $LIBDIR/libcrypto.so.* lib/ || true
cp -v $LIBDIR/libffi.so.* lib/ || true
cp -v $LIBDIR/libz.so.* lib/ || true
cp -v $LIBDIR/libbz2.so.* lib/ || true
cp -v $LIBDIR/liblzma.so.* lib/ || true
cp -v $LIBDIR/libsqlite3.so.* lib/ || true
cp -v $LIBDIR/libreadline.so.* lib/ || true
cp -v $LIBDIR/libncursesw.so.* lib/ || true
cp -v $LIBDIR/libtinfo.so.* lib/ || true

echo "==> Patching RPATH for Python binary"
patchelf --set-rpath '$ORIGIN/../lib' bin/python3.11

echo "==> Patching RPATH for all extension modules"
find lib/python3.11 -name "*.so" -exec patchelf --set-rpath '$ORIGIN/../../../../lib' {} \;

echo "==> Installing pip packages"
bin/python3.11 -m ensurepip
bin/python3.11 -m pip install --upgrade pip
bin/python3.11 -m pip install pyinstaller

echo "==> Testing Python"
bin/python3.11 -c "import ssl, ctypes; print('SSL:', ssl.OPENSSL_VERSION)"

echo "==> DONE"
echo ""
echo "Your portable Python is ready at:"
echo "  $PREFIX_DIR"
echo ""
echo "Run it like:"
echo "  ./python-portable/bin/python3.11"
