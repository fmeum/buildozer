#/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
    echo "Usage: bazel run //release <version>"
    exit 1
fi
version="$1"

cd $BUILD_WORKSPACE_DIRECTORY

release_archive=buildozer-v${version}.tar.gz
git archive --format=tar.gz -o $release_archive main
trap 'rm -f -- "$release_archive"' EXIT

notes=$(cat <<EOF
Uses buildozer ${version}.

## Usage
Add this line to your MODULE.bazel file:
\`\`\`starlark
bazel_dep(name = "buildozer", version = "${version}", dev_dependency = True)
\`\`\`
EOF
)

echo "$notes" | gh release create v${version} \
  --target main \
  --generate-notes \
  --notes-file - \
  --draft \
  $release_archive

