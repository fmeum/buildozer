#!/usr/bin/env bash

# Based on
# https://github.com/bazel-contrib/rules-template/blob/07fefdbc09d7ca2a49d24220e00dac2efc2bf9b7/.github/workflows/release_prep.sh

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="buildozer-${TAG:1}"
ARCHIVE="buildozer-$TAG.tar.gz"
git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip > $ARCHIVE
SHA=$(shasum -a 256 $ARCHIVE | awk '{print $1}')

cat << EOF
## Using Bzlmod

1. Enable with \`common --enable_bzlmod\` in \`.bazelrc\` (default with Bazel 7).
2. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "buildozer", version = "${TAG:1}")
\`\`\`
EOF
