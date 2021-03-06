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

include(${CMAKE_CURRENT_LIST_DIR}/Conan.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/Doxygen.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/MemoryCheck.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/Sanitizers.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/StaticAnalyzers.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/Testing.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/Warnings.cmake)

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
