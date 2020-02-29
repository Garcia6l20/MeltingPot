# MeltingPot

An easy to use CMake Tooling Pot

## Descriptions

This is a set of tools/preset for building high quality c++ code.

## Setup

### From starter template

1. Go the [starter repository](https://github.com/Garcia6l20/MeltingPot-starter)
2. Select a starting branch.
3. Click on *Use template* button.

### Code upgrade

1. Put a copy of the config file at the root of your project direclty:
```bash
cd <path_to_root_dir>
curl -O https://raw.githubusercontent.com/Garcia6l20/MeltingPot/v0.1.x/dist/.melt_options
```

2. Add folowing lines at the top of your root cmake project:
```cmake
if(NOT EXISTS "${CMAKE_BINARY_DIR}/MeltingPot.cmake")
  message(STATUS "Downloading MeltingPot.cmake from https://github.com/Garcia6l20/MeltingPot")
  file(DOWNLOAD "https://raw.githubusercontent.com/Garcia6l20/MeltingPot/v0.1.x/dist/MeltingPot.cmake" "${CMAKE_BINARY_DIR}/MeltingPot.cmake")
endif()
include(${CMAKE_BINARY_DIR}/MeltingPot.cmake)
```

3. Check the (comming soon) github pages for API reference, and upgrade your targets.

done !

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

# Suppress warnings
SUPPRESS_WARNINGS = -Wuseless-cast

# Global extra flags
EXTRA_FLAGS = -Wno-error=shadow

# Testing backends
TESTING_BACKENDS = gtest/1.10.0 \
                   catch2/2.11.0

# Default testing backend
# When used together you must specify the default backend
# and/or pass GTEST/CATCH option to melt_add_test to use the required backend
TESTING_DEFAULT_BACKEND = GTEST
```

## Status

I started this toolkit with recommendations of [Jason Turner](https://github.com/lefticus) and his [cpp_starter_project](https://github.com/lefticus/cpp_starter_project).
The aim here is to provide a collaborative toolkit with ready-to-use presets.


## Contributing

Any idea is welcome through issues or pull requests.

Rules:
 - Added features shall be optional an defaulted to OFF, it shall also be added in the the *.metl_options* file (commented) and in this current README (with an example when it make sense).
 - Respect the first rule.
