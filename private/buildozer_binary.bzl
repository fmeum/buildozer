visibility("//")

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
    else:
        fail("Unsupported architecture: " + arch)

def _buildozer_binary_repo_impl(repository_ctx):
    repository_ctx.file("WORKSPACE")
    repository_ctx.file("BUILD.bazel", """exports_files(["buildozer.exe"])""")

    os = _get_buildozer_os(repository_ctx.os)
    arch = _get_buildozer_arch(repository_ctx.os)
    os_arch = os + "-" + arch
    sha256 = repository_ctx.attr.sha256.get(os_arch)
    if not sha256:
        fail("No match for '{os_arch}' in sha256".format(os_arch = os_arch))

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
    },
)

def _buildozer_binary_impl(module_ctx):
    buildozer_attrs = {}
    for mod in module_ctx.modules:
        for tag in mod.tags.buildozer:
            if mod.name != "buildozer":
                fail("The buildozer tag is currently reserved for internal use only")
            buildozer_attrs["sha256"] = tag.sha256
            buildozer_attrs["version"] = mod.version

    if not buildozer_attrs:
        fail("No buildozer tag found")

    _buildozer_binary_repo(
        name = "buildozer_binary",
        **buildozer_attrs
    )

buildozer_binary = module_extension(
    _buildozer_binary_impl,
    tag_classes = {
        "buildozer": _buildozer_tag_class,
    },
)
