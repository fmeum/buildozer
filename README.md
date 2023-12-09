# buildozer

This Bazel module provides a pinned, prebuilt version of [buildozer](https://github.com/bazelbuild/buildtools/blob/master/buildozer/README.md), a tool for manipulating Bazel BUILD files.

## Requirements

* Bazel 6.2.0 or later

## Usage

1. Add the following line to your `MODULE.bazel` file:

```starlark
bazel_dep(name = "buildozer", version = "6.4.0", dev_dependency = True)
```

2. Run buildozer via `bazel run`:

```shell
bazel run @buildozer -- ...
```

The `--` is optional if you don't need to pass arguments to buildozer that start with a dash.

## Using buildozer in repository rules and module extensions

You can also use buildozer in a repository rule or module extension, i.e., during the loading phase:

1. Add the following line to your `MODULE.bazel` file:

```starlark
bazel_dep(name = "buildozer", version = "6.4.0")
``````

2. In your repository rule or module extension implementation function, get the path to the buildozer binary as follows:

```starlark
load("@buildozer//:buildozer.bzl", "BUILDOZER_LABEL")
...
def my_impl(repository_or_module_ctx):
    buildozer = repository_or_module_ctx.path(BUILDOZER_LABEL)
    ...
    repository_or_module_ctx.execute(
        [buildozer, 'set foo bar', '//path/to/pkg:target']
    )
```

Keep the `path` call at the top of your implementation function as it may cause a [restart of the repository rule](https://bazel.build/extending/repo#restarting_the_implementation_function).

### Alternative usage

If you dont want to or can't `load` from `@buildozer`, you can also use the following approach:

1. Add the following lines to your `MODULE.bazel` file:

```starlark
bazel_dep(name = "buildozer", version = "6.4.0")

buildozer_binary = use_extension("@buildozer//:buildozer_binary.bzl", "buildozer_binary")
use_repo(buildozer_binary, "buildozer_binary")
```

2. In your repository rule or module extension implementation function, get the path to the buildozer binary as follows:

```starlark
def my_impl(repository_or_module_ctx):
    # The ".exe" suffix is *not* a typo. It is present on all platforms to support
    # Windows while maintaining a stable label.
    buildozer = repository_or_module_ctx.path(Label("@buildozer_binary//:buildozer.exe))
```
