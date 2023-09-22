"""
Provides the buildozer label for use in repository rules and module extensions.
"""

visibility("public")

# The ".exe" suffix is *not* a typo. It is present on all platforms to support
# Windows while maintaining a stable label.
BUILDOZER_LABEL = Label("@buildozer_binary//:buildozer.exe")
