load("@bazel_features//:features.bzl", "bazel_features")

def _source_buildozer_impl(ctx):
    executable = ctx.actions.declare_file(ctx.label.name + (".bat" if ctx.attr.is_windows else ".sh"))

    ctx.actions.expand_template(
        template = ctx.file._windows_template if ctx.attr.is_windows else ctx.file._linux_template,
        output = executable,
        is_executable = True,
        substitutions = {
            "%%BUILDOZER_RLOCATIONPATH%%": ctx.file.buildozer_binary.short_path.lstrip("../"),
        }
    )
    files = [ctx.file.buildozer_binary]
    if not ctx.attr.is_windows:
        files.append(ctx.file._bash_runfiles)

    return [
        DefaultInfo(
            files = depset([executable]),
            executable = executable,
            runfiles = ctx.runfiles(files),
        )
    ]

source_buildozer = rule(
    doc = "An executable buildozer binary that changes directory into a workspace before running.",
    implementation = _source_buildozer_impl,
    attrs = {
        "buildozer_binary": attr.label(
            doc = "Buildozer binary to run. Must come from an external repository.",
            allow_single_file = True,
            executable = True,
            cfg = "target",
            mandatory = True,
        ),
        "is_windows": attr.bool(
            doc = "Whether the buildozer binary will be running on Windows.",
            mandatory = True,
        ),
        "_bash_runfiles": attr.label(
            allow_single_file = True,
            default = Label("@bazel_tools//tools/bash/runfiles"),
        ),
        "_linux_template": attr.label(
            allow_single_file = [".sh"],
            default = Label("//private:buildozer.template.sh"),
        ),
        "_windows_template": attr.label(
            allow_single_file = [".bat"],
            default = Label("//private:buildozer.template.bat"),
        )
    },
    executable = True,
)

def _get_buildozer_os(rctx_os):
    name = rctx_os.name
    if name.startswith("linux"):
        return "linux"
    elif name.startswith("mac os x"):
        return "darwin"
    elif name.startswith("windows"):
        return "windows"
    else:
        fail("Unsupported OS: " + name)

def _get_buildozer_arch(rctx_os):
    arch = rctx_os.arch
    if arch == "amd64" or arch == "x86_64" or arch == "x64":
        return "amd64"
    elif arch == "aarch64":
        return "arm64"
    elif arch == "s390x" or arch == "s390":
        return "s390x"
    else:
        fail("Unsupported architecture: " + arch)

def _buildozer_binary_repo_impl(repository_ctx):
    repository_ctx.file("WORKSPACE")

    os = _get_buildozer_os(repository_ctx.os)
    arch = _get_buildozer_arch(repository_ctx.os)
    os_arch = os + "-" + arch
    sha256 = repository_ctx.attr.sha256.get(os_arch)
    if not sha256:
        fail("No match for '{os_arch}' in sha256".format(os_arch = os_arch))

    repository_ctx.file("BUILD.bazel", """\
load("@buildozer//private:buildozer_binary.bzl", "source_buildozer")
exports_files(["buildozer.exe"])

source_buildozer(
    name = "source_buildozer",
    buildozer_binary = "buildozer.exe",
    is_windows = {is_windows},
    visibility = ["//visibility:public"],
)
""".format(is_windows = os == "windows"))

    repository_ctx.download(
        url = [
            "https://github.com/bazelbuild/buildtools/releases/download/v{version}/buildozer-{os_arch}{extension}".format(
                version = repository_ctx.attr.version,
                os_arch = os_arch,
                extension = ".exe" if os == "windows" else "",
            ),
        ],
        sha256 = sha256,
        # Always add the .exe extension, even on non-Windows platforms, so that
        # the file can be referenced via a platform-agnostic label.
        output = "buildozer.exe",
        executable = True,
    )

_buildozer_binary_repo = repository_rule(
    _buildozer_binary_repo_impl,
    attrs = {
        "sha256": attr.string_dict(),
        "version": attr.string(),
    },
    # This rule depends on repository_ctx.os, which can change when alternating
    # between Bazel binaries build for different architectures (e.g. with
    # Rosetta).
    configure = True,
)

_buildozer_tag_class = tag_class(
    attrs = {
        "sha256": attr.string_dict(),
        "version": attr.string(),
    },
)

def _buildozer_binary_impl(module_ctx):
    buildozer_attrs = {}
    for mod in module_ctx.modules:
        for tag in mod.tags.buildozer:
            if mod.name != "buildozer":
                fail("The buildozer tag is currently reserved for internal use only")
            buildozer_attrs["sha256"] = tag.sha256
            buildozer_attrs["version"] = tag.version

    if not buildozer_attrs:
        fail("No buildozer tag found")

    _buildozer_binary_repo(
        name = "buildozer_binary",
        **buildozer_attrs
    )

    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return module_ctx.extension_metadata(reproducible = True)
    else:
        return None

buildozer_binary = module_extension(
    _buildozer_binary_impl,
    tag_classes = {
        "buildozer": _buildozer_tag_class,
    },
)
