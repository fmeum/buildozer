visibility("//")

_URL_TEMPLATE = "https://github.com/bazelbuild/buildtools/releases/download/v{version}/buildozer-{os_arch}{extension}"

def _get_buildozer_os(os):
    name = os.name
    if name.startswith("linux"):
        return "linux"
    elif name.startswith("mac os x"):
        return "darwin"
    elif name.startswith("windows"):
        return "windows"
    else:
        fail("Unsupported OS: " + name)

def _get_buildozer_arch(os):
    arch = os.arch
    if arch == "amd64" or arch == "x86_64" or arch == "x64":
        return "amd64"
    elif arch == "aarch64":
        return "arm64"
    elif arch == "s390x" or arch == "s390":
        return "s390x"
    elif arch == "riscv64":
        return "riscv64"
    else:
        fail("Unsupported architecture: " + arch)

def _buildozer_binary_repo_impl(repository_ctx):
    repository_ctx.file("WORKSPACE")
    repository_ctx.file("BUILD.bazel", """exports_files(["buildozer.exe"])""")
    repository_ctx.download(
        url = [repository_ctx.attr.url],
        sha256 = repository_ctx.attr.sha256,
        # Always add the .exe extension, even on non-Windows platforms, so that
        # the file can be referenced via a platform-agnostic label.
        output = "buildozer.exe",
        executable = True,
    )
    if hasattr(repository_ctx, "repo_metadata"):
        # Available since Bazel 8.3.0. Makes the repository eligible for the
        # repo contents cache.
        return repository_ctx.repo_metadata(reproducible = True)
    return None

# The binary is selected by the extension, so the result of this rule is fully
# determined by its attributes and the repository can be vendored.
_buildozer_binary_repo = repository_rule(
    _buildozer_binary_repo_impl,
    attrs = {
        "sha256": attr.string(),
        "url": attr.string(),
    },
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

    buildozer_os = _get_buildozer_os(module_ctx.os)
    os_arch = buildozer_os + "-" + _get_buildozer_arch(module_ctx.os)
    sha256 = buildozer_attrs["sha256"].get(os_arch)
    if not sha256:
        fail("No match for '{os_arch}' in sha256".format(os_arch = os_arch))

    _buildozer_binary_repo(
        name = "buildozer_binary",
        url = _URL_TEMPLATE.format(
            version = buildozer_attrs["version"],
            os_arch = os_arch,
            extension = ".exe" if buildozer_os == "windows" else "",
        ),
        sha256 = sha256,
    )

    return module_ctx.extension_metadata(reproducible = True)

buildozer_binary = module_extension(
    _buildozer_binary_impl,
    tag_classes = {
        "buildozer": _buildozer_tag_class,
    },
    # The host platform determines the binary. Bazel accounts for this when
    # persisting the result, which only ends up in the hidden lockfile since
    # the extension is reproducible.
    os_dependent = True,
    arch_dependent = True,
)
