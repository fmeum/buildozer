#!/usr/bin/env bash

if [[ -z "${BUILD_WORKING_DIRECTORY+x}" ]]; then
    echo "BUILD_WORKING_DIRECTORY is not set. Please run this target with bazel run."
    exit 1
fi

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

buildozer_path=$(rlocation "%%BUILDOZER_RLOCATIONPATH%%")
if [[ ! -f "$buildozer_path" ]]; then
    echo "buildozer.exe not found at runfiles path %%BUILDOZER_RLOCATIONPATH%% and resolved path $buildozer_path."
    exit 1
fi

cd "$BUILD_WORKING_DIRECTORY"
exec "$buildozer_path" "$@"
