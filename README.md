# MeltingPot

An easy to use CMake Tooling Pot

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
