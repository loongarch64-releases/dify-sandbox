#!/bin/bash
set -euo pipefail

echo "   🏢 Org:   ${UPSTREAM_OWNER}"
echo "   📦 Proj:  ${UPSTREAM_REPO}"
echo "   🏷️  Ver:   ${VERSION}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DISTS="${ROOT_DIR}/dists"
SRCS="${ROOT_DIR}/srcs"
PATCHES="${ROOT_DIR}/patches"
mkdir -p "${DISTS}" "$SRCS/$VERSION"

# ==========================================
# 👇 用户自定义构建逻辑 (示例)
# ==========================================

echo "🔧 Compiling ${UPSTREAM_OWNER}/${UPSTREAM_REPO} ${VERSION}..."

prepare()
{
    wget -O "$SRCS/$VERSION.tar.gz" --quiet --show-progress "https://github.com/$UPSTREAM_OWNER/$UPSTREAM_REPO/archive/refs/tags/$VERSION.tar.gz"
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
    cp "$SRCS/$VERSION/main" "$SRCS/$VERSION/env" "$DISTS/$VERSION/"
}

main()
{
    prepare
    build
    post_build
}

main


# ==========================================
# 👆 自定义逻辑结束
# ==========================================

cat > "${DISTS}/release.txt" <<EOF
Project: ${UPSTREAM_REPO}
Organization: ${UPSTREAM_OWNER}
Version: ${VERSION}
Build Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "✅ Compilation finished."
ls -lh "${DISTS}"
