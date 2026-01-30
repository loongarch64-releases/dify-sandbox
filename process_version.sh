#!/bin/bash

set -euo pipefail

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Error: Version argument is required."
    exit 1
fi

ORG='langgenius'
PROJ='dify-sandbox'
# 容器工作目录
WORKSPACE="/workspace"
ARCH="$WORKSPACE/loong64"
SRCS="$WORKSPACE/srcs"
DISTS="$WORKSPACE/dists"
PATCHES="$WORKSPACE/patches"

mkdir -p "$DISTS/$VERSION" "$SRCS/$VERSION"

prepare()
{
    wget -O "$SRCS/$VERSION.tar.gz" --quiet --show-progress "https://github.com/$ORG/$PROJ/archive/refs/tags/$VERSION.tar.gz"
    tar -xzf "$SRCS/$VERSION.tar.gz" -C "$SRCS/$VERSION" --strip-components=1

    cp "$PATCHES/python-syscalls_loong64.go" "$SRCS/$VERSION/internal/static/python_syscall/syscalls_loong64.go"
    cp "$PATCHES/nodejs-syscalls_loong64.go" "$SRCS/$VERSION/internal/static/nodejs_syscall/syscalls_loong64.go"
    cp "$PATCHES/config_default_loong64.go" "$SRCS/$VERSION/internal/static/"
    cp "$PATCHES/seccomp_syscall_loong64.go" "$SRCS/$VERSION/internal/core/lib/"
    
    cp "$SRCS/$VERSION/build/build_amd64.sh" "$SRCS/$VERSION/build/build_loong64.sh"
    sed -i 's/amd64/loong64/g' "$SRCS/$VERSION/build/build_loong64.sh"
    chmod +x "$SRCS/$VERSION/build/build_loong64.sh"
}

build()
{
    pushd "$SRCS/$VERSION" > /dev/null
    go mod tidy
    ./build/build_loong64.sh
    popd > /dev/null
}

post_build()
{
    cp "$SRCS/$VERSION/main" "$SRCS/$VERSION/env" "$DISTS/$VERSION"
}

main()
{
    prepare
    build
    post_build
}

main
