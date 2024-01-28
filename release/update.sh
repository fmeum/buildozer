#/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
    echo "Usage: bazel run //release:update <version>"
    exit 1
fi
version=$1

cd $BUILD_WORKSPACE_DIRECTORY

buildozer_cmds_file=$(mktemp)
trap 'rm -f -- "$buildozer_cmds_file"' EXIT

echo "set version $version|//MODULE.bazel:%buildozer_binary.buildozer" > "$buildozer_cmds_file"

sha256_dict=""
declare -a os_archs=("darwin-amd64" "darwin-arm64" "linux-amd64" "linux-arm64" "windows-amd64")
for os_arch in "${os_archs[@]}"
do
    if [[ "$os_arch" == windows-* ]]; then
        extension=".exe"
    else
        extension=""
    fi
    url="https://github.com/bazelbuild/buildtools/releases/download/v${version}/buildozer-${os_arch}${extension}"
    echo "Computing checksum for $url..."
    sha256=$(curl -sL $url | sha256sum | cut -d' ' -f1)
    sha256_dict="${sha256_dict:+${sha256_dict} }${os_arch}:${sha256}"
done

echo "dict_set sha256 ${sha256_dict}|//MODULE.bazel:%buildozer_binary.buildozer" >> "$buildozer_cmds_file"

# Update MODULE.bazel
bazel run @buildozer -- -f "$buildozer_cmds_file"

# Update README.md
sed -i "s/version = \"[^\"]*\"/version = \"$version\"/" README.md
