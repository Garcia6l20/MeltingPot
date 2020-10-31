set(MELD_DIST_VERSION v0.1.x)
set(MELT_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

# parse melt options
if(EXISTS ${CMAKE_SOURCE_DIR}/.melt_options)
  file(STRINGS ${CMAKE_SOURCE_DIR}/.melt_options _melt_raw_opts)
  foreach(_raw_opt ${_melt_raw_opts})
    set(_var_regex [[^([A-Za-z0-9_]+) *= *(.+) *$]])
    if("${_raw_opt}" MATCHES ${_var_regex})
      set(_opt)
      foreach(_val ${CMAKE_MATCH_2})
        string(STRIP ${_val} _val)
        list(APPEND _opt ${_val})
      endforeach()
      set(MELT_${CMAKE_MATCH_1} ${_opt})
      message(
        STATUS "melt option: MELT_${CMAKE_MATCH_1} = ${MELT_${CMAKE_MATCH_1}}")
    elseif("${_raw_opt}" MATCHES [[\#.*]])
      # comment ignored
    else()
      message(
        FATAL_ERROR
          "Bad variable in .melt_options file: ${_raw_opt} should match ${_var_regex}"
      )
    endif()
  endforeach()
endif()

if(NOT TARGET _melt_options)
  # interface library that will hold options
  add_library(_melt_options INTERFACE)
  # convenient alias
  add_library(Melt::options ALIAS _melt_options)
endif()

# Set a default build type if none was specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(
    STATUS "Setting build type to 'RelWithDebInfo' as none was specified.")
  set(CMAKE_BUILD_TYPE
      RelWithDebInfo
      CACHE STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui, ccmake
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
                                               "MinSizeRel" "RelWithDebInfo")
endif()

option(MELT_ENABLE_CCACHE "Enable ccache" ON)
if(MELT_ENABLE_CCACHE)
  find_program(CCACHE ccache)
  if(CCACHE)
    message("using ccache")
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE})
  else()
    message("ccache not found cannot use")
  endif()
endif()

# Generate compile_commands.json to make it easier to work with clang based
# tools
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(MELT_ENABLE_IPO
       "Enable Iterprocedural Optimization, aka Link Time Optimization (LTO)"
       OFF)

if(MELT_ENABLE_IPO)
  include(CheckIPOSupported)
  check_ipo_supported(RESULT result OUTPUT output)
  if(result)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
  else()
    message(SEND_ERROR "IPO is not supported: ${output}")
  endif()
endif()

if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
 message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
 file(DOWNLOAD "https://github.com/conan-io/cmake-conan/raw/v0.15/conan.cmake"
   "${CMAKE_BINARY_DIR}/conan.cmake")
endif()
include("${CMAKE_BINARY_DIR}/conan.cmake")

macro(conan_requires)

  if(CONAN_EXPORTED) # in conan local cache
    # standard conan installation, deps will be defined in conanfile.py and not
    # necessary to call conan again, conan is already running
    include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    conan_basic_setup(TARGETS)
  else()

    # some default values
    set(CONAN_BUILD outdated)

    set(options)
    set(oneValueArgs BUILD ARCH)
    set(multiValueArgs OPTIONS REPOSITORIES)
    cmake_parse_arguments(CONAN "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN})
    set(_requires ${CONAN_UNPARSED_ARGUMENTS})

    # Download automatically, you can also just copy the conan.cmake file
    if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
      set(CMAKE_CONAN_VERSION
          0.15
          CACHE STRING "Version of the cmake wrapper to download")
      message(
        STATUS
          "Downloading conan.cmake from https://github.com/conan-io/cmake-conan"
      )
      file(
        DOWNLOAD
        "https://github.com/conan-io/cmake-conan/raw/v${CMAKE_CONAN_VERSION}/conan.cmake"
        "${CMAKE_BINARY_DIR}/conan.cmake")
    endif()

    include(${CMAKE_BINARY_DIR}/conan.cmake)

    if(CONAN_REPOSITORIES)
      list(LENGTH CONAN_REPOSITORIES _len)
      math(EXPR _len "${_len} - 1")
      foreach(_ii RANGE 0 ${_len} 4)
        list(SUBLIST CONAN_REPOSITORIES ${_ii} 4 _repo)
        cmake_parse_arguments(CONAN_REPO "" "NAME;URL" "" ${_repo})
        if(NOT CONAN_REPO_NAME OR NOT CONAN_REPO_URL)
          message(
            FATAL_ERROR
              "REPOSITORIES arguments must match NAME <name> URL <url>")
        endif()
        string(STRIP ${CONAN_REPO_NAME} CONAN_REPO_NAME)
        string(STRIP ${CONAN_REPO_URL} CONAN_REPO_URL)
        conan_add_remote(NAME ${CONAN_REPO_NAME} URL ${CONAN_REPO_URL})
      endforeach()
    endif()

    set(MELT_${PROJECT_NAME}_REQUIRES ${_requires})
    set(MELT_${PROJECT_NAME}_DEFAULT_OPTIONS ${CONAN_OPTIONS})

    if(MELT_TESTING_BACKENDS)
      list(APPEND _requires ${MELT_TESTING_BACKENDS})
    endif()

    if (CMAKE_CXX_STANDARD)
      list(APPEND _extra_args SETTINGS compiler.cppstd=${CMAKE_CXX_STANDARD})
    endif()

    conan_cmake_run(
      REQUIRES
      ${_requires}
      OPTIONS
        "${CONAN_OPTIONS}"
      BASIC_SETUP
      CMAKE_TARGETS # individual targets to link to
      GENERATORS
        cmake_find_package
      BUILD
        "${CONAN_BUILD}"
      ARCH
        "${CONAN_ARCH}"
      ${_extra_args})

  endif()

  # expose conan's find packages
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})

endmacro()

function(_to_python_list _var)
  list(JOIN ${_var} "\", \"" _tmp)
  set(${_var}
      "\"${_tmp}\""
      PARENT_SCOPE)
endfunction()

function(_to_python_dict_items _var)
  set(_tmp ${${_var}})
  list(TRANSFORM _tmp REPLACE [[([A-Za-z_:]+)=([A-Za-z_]+)]] [["\1": \2]])
  list(JOIN _tmp ", " _tmp)
  set(${_var}
      ${_tmp}
      PARENT_SCOPE)
endfunction()

function(conan_package)

  set(MELT_PACKAGE_NAME ${PROJECT_NAME})
  set(MELT_PACKAGE_REQUIRES ${MELT_${PROJECT_NAME}_REQUIRES})
  set(MELT_PACKAGE_BUILD_REQUIRES ${MELT_TESTING_BACKENDS})

  set(options)
  set(oneValueArgs LICENSE AUTHOR URL SMC_URL)
  set(multiValueArgs OPTIONS DEFAULT_OPTIONS TOPICS BUILD_MODULES DESCRIPTION)
  cmake_parse_arguments(MELT_PACKAGE "${options}" "${oneValueArgs}"
                        "${multiValueArgs}" ${ARGN})
  list(APPEND MELT_PACKAGE_DEFAULT_OPTIONS
       ${MELT_${PROJECT_NAME}_DEFAULT_OPTIONS})

  _to_python_list(MELT_PACKAGE_REQUIRES)
  _to_python_list(MELT_PACKAGE_BUILD_REQUIRES)
  _to_python_list(MELT_PACKAGE_TOPICS)
  _to_python_list(MELT_PACKAGE_BUILD_MODULES)
  _to_python_dict_items(MELT_PACKAGE_DEFAULT_OPTIONS)
  list(JOIN MELT_PACKAGE_DESCRIPTION " " MELT_PACKAGE_DESCRIPTION)

  if(NOT MELT_PACKAGE_SMC_URL)
    set(MELT_PACKAGE_SMC_URL ${MELT_PACKAGE_URL})
  endif()

  if(NOT EXISTS ${MELT_MODULE_PATH}/conanfile.py.in AND MELD_DIST_VERSION)
    file(
      DOWNLOAD
      "https://raw.githubusercontent.com/Garcia6l20/MeltingPot/${MELD_DIST_VERSION}/dist/conanfile.py.in"
      "${MELT_MODULE_PATH}/conanfile.py.in")
  endif()

  configure_file(${MELT_MODULE_PATH}/conanfile.py.in
                 ${CMAKE_SOURCE_DIR}/conanfile.py @ONLY NEWLINE_STYLE LF)
endfunction()

function(melt_doxygen _target)
  option(MELT_ENABLE_DOXYGEN "Enable doxygen doc builds of source" OFF)
  if(MELT_ENABLE_DOXYGEN)
    set(DOXYGEN_CALLER_GRAPH ON)
    set(DOXYGEN_CALL_GRAPH ON)
    set(DOXYGEN_EXTRACT_ALL ON)
    find_package(Doxygen REQUIRED dot)
    doxygen_add_docs(${_target}-docs ${${_target}_SOURCE_DIR})

  endif()
endfunction()

option(MELT_ENABLE_CTEST_VALGRIND "Enable vagrind memorycheck of tests" OFF)
if(MELT_ENABLE_CTEST_VALGRIND)
  find_program(VALGRIND_EXE valgrind)
  if(VALGRIND_EXE)
    set(CTEST_MEMORYCHECK_COMMAND "${VALGRIND_EXE}")
  endif()
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL
                                           "Clang")
  option(MELT_ENABLE_COVERAGE "Enable coverage reporting for gcc/clang" OFF)

  if(ENABLE_COVERAGE)
    target_compile_options(_melt_options INTERFACE --coverage -O0 -g)
    target_link_libraries(_melt_options INTERFACE --coverage)
  endif()

  set(SANITIZERS "")

  option(MELT_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
  if(MELT_ENABLE_SANITIZER_ADDRESS)
    list(APPEND SANITIZERS "address")
  endif()

  option(MELT_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
  if(ENABLE_SANITIZER_MEMORY)
    list(APPEND SANITIZERS "memory")
  endif()

  option(MELT_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
         "Enable undefined behavior sanitizer" OFF)
  if(MELT_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR)
    list(APPEND SANITIZERS "undefined")
  endif()

  option(MELT_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
  if(MELT_ENABLE_SANITIZER_THREAD)
    list(APPEND SANITIZERS "thread")
  endif()

  list(JOIN SANITIZERS "," LIST_OF_SANITIZERS)

endif()

if(LIST_OF_SANITIZERS)
  if(NOT "${LIST_OF_SANITIZERS}" STREQUAL "")
    target_compile_options(_melt_options
                           INTERFACE -fsanitize=${LIST_OF_SANITIZERS})
    target_link_libraries(_melt_options
                          INTERFACE -fsanitize=${LIST_OF_SANITIZERS})
  endif()
endif()

option(MELT_ENABLE_CPPCHECK "Enable static analysis with cppcheck" OFF)
if(MELT_ENABLE_CPPCHECK)
  find_program(CPPCHECK cppcheck)
  if(CPPCHECK)
    set(CMAKE_CXX_CPPCHECK ${CPPCHECK} --suppress=missingInclude --enable=all
                           --inconclusive -i ${CMAKE_SOURCE_DIR}/imgui/lib)
  else()
    message(SEND_ERROR "cppcheck requested but executable not found")
  endif()
endif()

option(MELT_ENABLE_CLANG_TIDY "Enable static analysis with clang-tidy" OFF)
if(MELT_ENABLE_CLANG_TIDY)
  find_program(CLANGTIDY NAMES clang-tidy clang-tidy-11 clang-tidy-10 clang-tidy-9)
  if(CLANGTIDY)
    set(CMAKE_CXX_CLANG_TIDY ${CLANGTIDY})
  else()
    message(SEND_ERROR "clang-tidy requested but executable not found")
  endif()
endif()

cmake_policy(SET CMP0076 NEW)

macro(melt_add_test _name)

  include(CTest)

  if(NOT BUILD_TESTING)
    return()
  endif()

  set(_target ${PROJECT_NAME}-test-${_name})

  if(NOT CATCH IN_LIST _MELT_TARGET_PARSE_OPTIONS)
    list(APPEND _MELT_TARGET_PARSE_OPTIONS CATCH GTEST)
  endif()

  if(NOT WORKING_DIRECTORY IN_LIST _MELT_TARGET_PARSE_ONE_VALUE_ARGS)
    list(APPEND _MELT_TARGET_PARSE_ONE_VALUE_ARGS WORKING_DIRECTORY)
  endif()

  if(NOT EXTRA_ARGS IN_LIST _MELT_TARGET_PARSE_MULTI_VALUE_ARGS)
    list(APPEND _MELT_TARGET_PARSE_MULTI_VALUE_ARGS EXTRA_ARGS)
  endif()

  # add cache variable to disable this test
  set(_no_test_var_name "${PROJECT_NAME}_NO_TEST_${_name}")
  string(TOUPPER ${_no_test_var_name} _no_test_var_name)
  string(REPLACE "-" "_" _no_test_var_name ${_no_test_var_name})
  set(${_no_test_var_name}
      OFF
      CACHE BOOL "Disable ${PROJECT_NAME}-${_name} while running tests")

  melt_executable(${_target} ${ARGN})

  if(EXISTS ${CMAKE_CURRENT_LIST_DIR}/test-${_name}.cpp)
    target_sources(${_target} PUBLIC test-${_name}.cpp)
  endif()

  # create project-test group
  if(NOT TARGET ${PROJECT_NAME}-tests)
    add_custom_target(${PROJECT_NAME}-tests)
  endif()
  add_dependencies(${PROJECT_NAME}-tests ${_target})

  if(NOT MELT_ARGS_WORKING_DIRECTORY)
    set(MELT_ARGS_WORKING_DIRECTORY ${${PROJECT_NAME}_BINARY_DIR})
  endif()

  if(MELT_TESTING_BACKENDS AND (NOT TARGET CONAN_PKG::gtest AND NOT TARGET CONAN_PKG::catch2))
    message(STATUS "melt: retrieving testing backend(s): ${MELT_TESTING_BACKENDS}")
    conan_requires(${MELT_TESTING_BACKENDS} BUILD outdated)
  endif()

  if(NOT ${${_no_test_var_name}})
    if(TARGET CONAN_PKG::gtest AND TARGET CONAN_PKG::catch2)
      if(NOT MELT_TESTING_DEFAULT_BACKEND)
        if(NOT MELT_ARGS_CATCH OR MELT_ARGS_GTEST)
          message(
            FATAL_ERROR
              "Using catch and gtest togeter\
                requires to set the TESTING_DEFAULT_BACKEND to CATCH or GTEST in your .melt_options\
                configuration then specify CATCH or GTEST for non-default backend tests."
          )
        endif()
      endif()
      if(MELT_ARGS_GTEST AND MELT_ARGS_CATCH)
        message(FATAL_ERROR "You cannot use both GTEST and CATCH options")
      endif()
    endif()

    if(TARGET CONAN_PKG::gtest)
      if(NOT MELT_ARGS_CATCH)
        if(MELT_ARGS_GTEST
           OR NOT MELT_TESTING_DEFAULT_BACKEND
           OR MELT_TESTING_DEFAULT_BACKEND STREQUAL GTEST)
          target_link_libraries(${_target} PRIVATE CONAN_PKG::gtest)
          include(GoogleTest)
          gtest_discover_tests(${_target}
                               WORKING_DIRECTORY ${MELT_ARGS_WORKING_DIRECTORY}
                               EXTRA_ARGS ${MELT_ARGS_EXTRA_ARGS})
        endif()
      endif()
    endif()
    if(TARGET CONAN_PKG::catch2)
      if(NOT MELT_ARGS_GTEST)
        if(MELT_ARGS_CATCH
           OR NOT MELT_TESTING_DEFAULT_BACKEND
           OR MELT_TESTING_DEFAULT_BACKEND STREQUAL CATCH)
          include(Catch)
          target_link_libraries(${_target} PRIVATE CONAN_PKG::catch2)
          catch_discover_tests(${_target}
                               WORKING_DIRECTORY ${MELT_ARGS_WORKING_DIRECTORY}
                               EXTRA_ARGS ${MELT_ARGS_EXTRA_ARGS})
        endif()
      endif()
    endif()
  else()
    message(STATUS "test ${_target} disabled")
  endif()
  get_target_property(_type ${PROJECT_NAME} TYPE)
  if(NOT ${_type} STREQUAL INTERFACE_LIBRARY)
    if(TARGET ${PROJECT_NAME})
      get_target_property(_test_folder ${PROJECT_NAME} FOLDER)
      if(_test_folder)
        set(_test_folder "${_test_folder}/${PROJECT_NAME}-tests")
      endif()
    endif()
    set_target_properties(${_target} PROPERTIES FOLDER ${_test_folder})
  endif()
endmacro()

macro(melt_discover_tests _dir)
  if(NOT _dir)
    set(_dir ${CMAKE_CURRENT_LIST_DIR})
  endif()
  file(GLOB _files ${_dir}/test-*.cpp)
  foreach(_file ${_files})
    get_filename_component(_name ${_file} NAME_WE)
    string(REGEX REPLACE "test-(.*)" [[\1]] _name ${_name})
    melt_add_test(${_name} SOURCES ${_file} ${ARGN})
  endforeach()
endmacro()

option(MELT_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" OFF)

set(MSVC_WARNINGS
    /W4 # Baseline reasonable warnings
    /w14242 # 'identfier': conversion from 'type1' to 'type1', possible loss of
            # data
    /w14254 # 'operator': conversion from 'type1:field_bits' to
            # 'type2:field_bits', possible loss of data
    /w14263 # 'function': member function does not override any base class
            # virtual member function
    /w14265 # 'classname': class has virtual functions, but destructor is not
            # virtual instances of this class may not be destructed correctly
    /w14287 # 'operator': unsigned/negative constant mismatch
    /we4289 # nonstandard extension used: 'variable': loop control variable
            # declared in the for-loop is used outside the for-loop scope
    /w14296 # 'operator': expression is always 'boolean_value'
    /w14311 # 'variable': pointer truncation from 'type1' to 'type2'
    /w14545 # expression before comma evaluates to a function which is missing
            # an argument list
    /w14546 # function call before comma missing argument list
    /w14547 # 'operator': operator before comma has no effect; expected operator
            # with side-effect
    /w14549 # 'operator': operator before comma has no effect; did you intend
            # 'operator'?
    /w14555 # expression has no effect; expected expression with side- effect
    /w14619 # pragma warning: there is no warning number 'number'
    /w14640 # Enable warning on thread un-safe static member initialization
    /w14826 # Conversion from 'type1' to 'type_2' is sign-extended. This may
            # cause unexpected runtime behavior.
    /w14905 # wide string literal cast to 'LPSTR'
    /w14906 # string literal cast to 'LPWSTR'
    /w14928 # illegal copy-initialization; more than one user-defined conversion
            # has been implicitly applied
)

set(CLANG_WARNINGS
    -Wall
    -Wextra # reasonable and standard
    -Wshadow # warn the user if a variable declaration shadows one from a parent
             # context
    -Wnon-virtual-dtor # warn the user if a class with virtual functions has a
                       # non-virtual destructor. This helps catch hard to track
                       # down memory errors
    -Wold-style-cast # warn for c-style casts
    -Wcast-align # warn for potential performance problem casts
    -Wunused # warn on anything being unused
    -Woverloaded-virtual # warn if you overload (not override) a virtual
                         # function
    -Wpedantic # warn if non-standard C++ is used
    -Wconversion # warn on type conversions that may lose data
    -Wsign-conversion # warn on sign conversions
    -Wnull-dereference # warn if a null dereference is detected
    -Wdouble-promotion # warn if float is implicit promoted to double
    -Wformat=2 # warn on security issues around functions that format output (ie
               # printf)
)

if(MELT_WARNINGS_AS_ERRORS)
  set(CLANG_WARNINGS ${CLANG_WARNINGS} -Werror)
  set(MSVC_WARNINGS ${MSVC_WARNINGS} /WX)
endif()

set(GCC_WARNINGS
    ${CLANG_WARNINGS}
    -Wmisleading-indentation # warn if identation implies blocks where blocks do
                             # not exist
    -Wduplicated-cond # warn if if / else chain has duplicated conditions
    -Wduplicated-branches # warn if if / else branches have duplicated code
    -Wlogical-op # warn about logical operations being used where bitwise were
                 # probably wanted
    -Wuseless-cast # warn if you perform a cast to the same type
)

if(NOT CMAKE_CXX_COMPILER_ID)
  project(__fake_melt_projet CXX)
endif()

if(MSVC)
  set(MELT_WARNINGS ${MSVC_WARNINGS})
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR MELT_ENABLE_CLANG_TIDY)
  set(MELT_WARNINGS ${CLANG_WARNINGS})
else()
  set(MELT_WARNINGS ${GCC_WARNINGS})
endif()

set(MELT_WARNINGS
    ${MELT_WARNINGS}
    CACHE INTERNAL "Melt wanings")

if(MELT_SUPPRESS_WARNINGS)
  list(REMOVE_ITEM MELT_WARNINGS ${MELT_SUPPRESS_WARNINGS})
endif()

message(STATUS "MELT_WARNINGS: ${MELT_WARNINGS}")
target_compile_options(_melt_options INTERFACE ${MELT_WARNINGS})


include(GenerateExportHeader)

# extends those args to extend melt_library/executable
set(_MELT_TARGET_PARSE_OPTIONS IS_EXECUTABLE IS_LIBRARY SHARED INTERFACE NO_INSTALL
                               DOXYGEN)
set(_MELT_TARGET_PARSE_ONE_VALUE_ARGS ALIAS CXX_STANDARD FOLDER)
set(_MELT_TARGET_PARSE_MULTI_VALUE_ARGS
    SOURCES
    HEADERS
    LIBRARIES
    DEFINITIONS
    INCLUDE_DIRS
    SYSTEM_INCLUDE_DIRS
    COMPILE_OPTIONS
    COMPILE_FEATURES
    LINK_FLAGS
    PCH)

macro(_melt_target _target)
  cmake_parse_arguments(
    MELT_ARGS "${_MELT_TARGET_PARSE_OPTIONS}"
    "${_MELT_TARGET_PARSE_ONE_VALUE_ARGS}"
    "${_MELT_TARGET_PARSE_MULTI_VALUE_ARGS}" "${ARGN}")
  set(_public PUBLIC)
  if(MELT_ARGS_IS_EXECUTABLE)
    add_executable(${_target} ${MELT_ARGS_SOURCES} ${MELT_ARGS_HEADERS})
  elseif(MELT_ARGS_IS_LIBRARY)
    if(MELT_ARGS_SHARED)
      set(_lib_type SHARED)
    endif()
    if(MELT_ARGS_INTERFACE)
      set(_lib_type INTERFACE)
      set(_public INTERFACE)
    endif()

    add_library(${_target} ${_lib_type} ${MELT_ARGS_SOURCES}
                           ${MELT_ARGS_HEADERS})
    if(MELT_ARGS_FOLDER)
      if(NOT MELT_ARGS_INTERFACE)
        set_target_properties(${_target} PROPERTIES FOLDER ${MELT_ARGS_FOLDER})
      endif()
      set(_generated_include_dirs
          ${PROJECT_BINARY_DIR}/include/${MELT_ARGS_FOLDER})
    else()
      set(_generated_include_dirs ${PROJECT_BINARY_DIR}/include)
    endif()

    if(NOT MELT_ARGS_INTERFACE)
      generate_export_header(${_target} EXPORT_FILE_NAME
                             ${_generated_include_dirs}/${_target}-export.hpp)
      set_source_files_properties(${_generated_include_dirs}/${_target}-export.hpp
                                  PROPERTIES GENERATED TRUE)
      list(APPEND MELT_ARGS_HEADERS
           ${_generated_include_dirs}/${_target}-export.hpp)
      target_sources(${_target}
                     PUBLIC ${_generated_include_dirs}/${_target}-export.hpp)
    endif()

  else()
    message(
      FATAL_ERROR
        "you should use melt_library or melt_executable, not _melt_target direclty"
    )
  endif()

  target_include_directories(
    ${_target} ${_public} include inline ${PROJECT_BINARY_DIR}/include
                      ${MELT_ARGS_INCLUDE_DIRS})
  target_link_libraries(${_target} ${_public} ${MELT_ARGS_LIBRARIES})
  if(NOT MELT_ARGS_INTERFACE)
    target_link_libraries(${_target} PRIVATE Melt::options)
  endif()
#  if(NOT MELT_ARGS_INTERFACE)
    target_include_directories(${_target} SYSTEM
      ${_public} ${MELT_ARGS_SYSTEM_INCLUDE_DIRS})
#  else()
#    target_include_directories(${_target} INTERFACE ${MELT_ARGS_SYSTEM_INCLUDE_DIRS})
#  endif()

  if(MELT_ARGS_ALIAS)
    add_library(${MELT_ARGS_ALIAS} ALIAS ${_target})
  endif()

  if(MELT_ARGS_CXX_STANDARD)
    if (MELT_ARGS_INTERFACE)
      message(FATAL_ERROR "Cannot use CXX_STANDARD on INTERFACE libraries")
    else()
      set_target_properties(${_target} PROPERTIES CXX_STANDARD
                                                  ${MELT_ARGS_CXX_STANDARD})
      set_target_properties(${_target} PROPERTIES CXX_STANDARD_REQUIRED ON)
    endif()
  endif()

  if(MELT_ARGS_HEADERS)
    set_target_properties(${_target} PROPERTIES PUBLIC_HEADER
                                                "${MELT_ARGS_HEADERS}")
  endif()

  if(MELT_ARGS_DEFINITIONS)
    target_compile_definitions(${_target} ${_public} "${MELT_ARGS_DEFINITIONS}")
  endif()

  if(MELT_ARGS_COMPILE_OPTIONS)
    target_compile_options(${_target} ${_public} "${MELT_ARGS_COMPILE_OPTIONS}")
  endif()

  if(MELT_ARGS_COMPILE_FEATURES)
    target_compile_features(${_target} PUBLIC "${MELT_ARGS_COMPILE_FEATURES}")
  endif()

  if(MELT_ARGS_EXTRA_FLAGS)
    target_compile_options(${_target} ${_public} "${MELT_ARGS_EXTRA_FLAGS}")
  endif()

  if(MELT_ARGS_LINK_FLAGS)
    target_link_options(${_target} ${_public} "${MELT_ARGS_LINK_FLAGS}")
  endif()

  if(MELT_ARGS_PCH AND ${CMAKE_VERSION} VERSION_GREATER_EQUAL 3.14.0)
    target_precompile_headers(${_target} ${_public} "${MELT_ARGS_PCH}")
  endif()

  if(MELT_${CMAKE_C_COMPILER_ID}_EXTRA_FLAGS)
    target_compile_options(${_target}
                           ${_public} "${MELT_${CMAKE_C_COMPILER_ID}_EXTRA_FLAGS}")
  endif()

  if(NOT MELT_ARGS_NO_INSTALL)
    install(
      TARGETS ${_target}
      RUNTIME DESTINATION bin
      ARCHIVE DESTINATION lib
              COMPONENT Libraries
      LIBRARY DESTINATION lib
              COMPONENT Libraries
              NAMELINK_COMPONENT Development
      PUBLIC_HEADER DESTINATION include/${MELT_ARGS_FOLDER}
                    COMPONENT Development)
  endif()

  if(MELT_ARGS_DOXYGEN)
    melt_doxygen(${_target})
  endif()

  if(EXISTS ${${_target}_SOURCE_DIR}/tests)
    if(EXISTS ${${_target}_SOURCE_DIR}/tests/CMakeLists.txt)
      add_subdirectory(${${_target}_SOURCE_DIR}/tests)
    else()
      message(
        STATUS "melt: discovering tests in ${${_target}_SOURCE_DIR}/tests")
      melt_discover_tests(${${_target}_SOURCE_DIR}/tests LIBRARIES ${_target})
    endif()
  endif()
endmacro()

macro(melt_library _target)
  _melt_target(${_target} IS_LIBRARY ${ARGN})
endmacro()

macro(melt_executable _target)
  _melt_target(${_target} IS_EXECUTABLE ${ARGN})
endmacro()
