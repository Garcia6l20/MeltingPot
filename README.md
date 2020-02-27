# MeltingPot

An easy to use CMake Tooling Pot

## Descriptions

This is a set of tools/preset for building high quality c++ code.

## Target creation

```cmake
# conan dependencies
conan_requires(
    fmt/6.1.0
    boost/1.71.0
  REPOSITORIES
    NAME bincrafters URL https://api.bintray.com/conan/bincrafters/public-conan
    NAME xdev        URL https://api.bintray.com/conan/6l20garcia/xdev
  BUILD missing
  OPTIONS
    boost:header_only=True
)

# Create a library target
melt_library(my-lib [SHARED|STATIC|MODULE]
  [NO_INSTALL]
  [DOXYGEN]
  ALIAS my::lib
  CXX_STANDARD 20
  SOURCES ...
  HEADERS ...
  LIBRARIES ...
  DEFINITIONS ...
  COMPILE_OPTIONS ...
  INCLUDE_DIRS ...
  SYSTEM_INCLUDE_DIRS ...
)

# Create an executable target
melt_executable(my-exe
  [NO_INSTALL]
  [DOXYGEN]
  CXX_STANDARD 20
  SOURCES ...
  HEADERS ...
  LIBRARIES ...
  DEFINITIONS ...
  COMPILE_OPTIONS ...
  INCLUDE_DIRS ...
  SYSTEM_INCLUDE_DIRS ...
)
```

## Configurable options

Copy the *.melt_options* file to your project root and customize it as needed:

```txt
# Enable doxygen doc builds of source
ENABLE_DOXYGEN = ON

# Enable Iterprocedural Optimization, aka Link Time Optimization (LTO)
ENABLE_IPO = ON

# Enable vagrind memorycheck of tests
ENABLE_CTEST_VALGRIND = ON

# Enable coverage reporting for gcc/clang
ENABLE_COVERAGE = ON

# Enable address sanitizer
ENABLE_SANITIZER_ADDRESS = ON

# Enable memory sanitizer
ENABLE_SANITIZER_MEMORY = ON

# Enable undefined behavior sanitizer
ENABLE_SANITIZER_UNDEFINED_BEHAVIOR = ON

# Enable thread sanitizer
ENABLE_SANITIZER_THREAD = ON

# Enable static analysis with cppcheck
ENABLE_CPPCHECK = ON

# Enable static analysis with clang-tidy
ENABLE_CLANG_TIDY = ON

# Treat compiler warnings as errors
WARNINGS_AS_ERRORS = ON
```

## Status

I started this toolkit with recommendations of [Jason Turner](https://github.com/lefticus) and his [cpp_starter_project](https://github.com/lefticus/cpp_starter_project).
The aim here is to provide a collaborative toolkit with ready-to-use presets.
From now it's usable by adding this repository as submodule and I'm managing to make it downloadable from a single file.

## Contributing

Any idea is welcome through issues or pull requests.

Rules:
 - Added features shall be optional an defaulted to OFF, it shall also be added in the the *.metl_options* file (commented) and in this current README (with an example when it make sense).
 - Respect the first rule.
