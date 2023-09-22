load("@local_config_platform//:constraints.bzl", "HOST_CONSTRAINTS")

visibility("//")

def _get_buildozer_os():
    constraint_os = [
        c[len("@platforms//os:"):]
        for c in HOST_CONSTRAINTS
        if c.startswith("@platforms//os:")
    ]
    if not constraint_os:
        fail("No OS constraint in " + repr(HOST_CONSTRAINTS))
    constraint_os = constraint_os[0]
    if constraint_os == "osx":
        return "darwin"
    else:
        return constraint_os

def _get_buildozer_arch():
    constraint_cpu = [
        c[len("@platforms//cpu:"):]
        for c in HOST_CONSTRAINTS
        if c.startswith("@platforms//cpu:")
    ]
    if not constraint_cpu:
        fail("No CPU constraint in " + repr(HOST_CONSTRAINTS))
    constraint_cpu = constraint_cpu[0]
    if constraint_cpu == "x86_64":
        return "amd64"
    elif constraint_cpu == "aarch64" or constraint_cpu == "arm64":
        return "arm64"
    else:
        fail("Unsupported CPU: " + constraint_cpu)

_BUILDOZER_URL = "https://github.com/bazelbuild/buildtools/releases/download/v{version}/buildozer-{os_arch}{extension}"

def _buildozer_binary_repo_impl(repository_ctx):
    repository_ctx.file("WORKSPACE")
    repository_ctx.file("BUILD.bazel", """exports_files(["buildozer.exe"])""")

    os = _get_buildozer_os()
    arch = _get_buildozer_arch()
    os_arch = os + "-" + arch
    sha256 = repository_ctx.attr.sha256.get(os_arch)
    if not sha256:
        fail("No match for '{os_arch}' in sha256".format(os_arch = os_arch))

    repository_ctx.download(
        url = [_BUILDOZER_URL.format(
            version = repository_ctx.attr.version,
            os_arch = os_arch,
            extension = ".exe" if os == "windows" else "",
        )],
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
