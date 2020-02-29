# parse melt options
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.melt_options)
  file(STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/.melt_options _melt_raw_opts)
  foreach(_raw_opt ${_melt_raw_opts})
    set(_var_regex [[^([A-Za-z0-9_]+) *= *(.+) *$]])
    if("${_raw_opt}" MATCHES ${_var_regex})
      set(_opt)
      foreach(_val ${CMAKE_MATCH_2})
          string(STRIP ${_val} _val)
          list(APPEND _opt ${_val})
      endforeach()
      set(MELT_${CMAKE_MATCH_1} ${_opt})
        message(STATUS "melt option: MELT_${CMAKE_MATCH_1} = ${MELT_${CMAKE_MATCH_1}}")
    elseif("${_raw_opt}" MATCHES [[\#.*]])
      # comment ignored
    else()
      message(FATAL_ERROR "Bad variable in .melt_options file: ${_raw_opt} should match ${_var_regex}")
    endif()
  endforeach()
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

find_program(CCACHE ccache)
if(CCACHE)
  message("using ccache")
  set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE})
else()
  message("ccache not found cannot use")
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
set(_MELT_TARGET_PARSE_OPTIONS
  IS_EXECUTABLE
  IS_LIBRARY
  SHARED
  NO_INSTALL
  DOXYGEN
)
set(_MELT_TARGET_PARSE_ONE_VALUE_ARGS
  ALIAS
  CXX_STANDARD
  FOLDER
)
set(_MELT_TARGET_PARSE_MULTI_VALUE_ARGS
  SOURCES
  HEADERS
  LIBRARIES
  DEFINITIONS
  INCLUDE_DIRS
  SYSTEM_INCLUDE_DIRS
  COMPILE_OPTIONS
)

macro(_melt_target _target)
    cmake_parse_arguments(MELT_ARGS
        "${_MELT_TARGET_PARSE_OPTIONS}"
        "${_MELT_TARGET_PARSE_ONE_VALUE_ARGS}"
        "${_MELT_TARGET_PARSE_MULTI_VALUE_ARGS}"
        "${ARGN}"
    )
    if(MELT_ARGS_IS_EXECUTABLE)
      add_executable(${_target} ${MELT_ARGS_SOURCES} ${MELT_ARGS_HEADERS})
    elseif(MELT_ARGS_IS_LIBRARY)
      if(MELT_ARGS_SHARED)
          set(_lib_type SHARED)
      endif()

      add_library(${_target} ${_lib_type} ${MELT_ARGS_SOURCES} ${MELT_ARGS_HEADERS})
      if(MELT_ARGS_FOLDER)
          set_target_properties(${_target} PROPERTIES FOLDER ${MELT_ARGS_FOLDER})
          set(_generated_include_dirs ${PROJECT_BINARY_DIR}/include/${MELT_ARGS_FOLDER})
      else()
          set(_generated_include_dirs ${PROJECT_BINARY_DIR}/include)
      endif()

      generate_export_header(${_target} EXPORT_FILE_NAME ${_generated_include_dirs}/${_target}-export.hpp)
      list(APPEND MELT_ARGS_HEADERS ${_generated_include_dirs}/${_target}-export.hpp)
      target_sources(${_target} PUBLIC ${_generated_include_dirs}/${_target}-export.hpp)

    else()
      message(FATAL_ERROR "you should use melt_library or melt_executable, not _melt_target direclty")
    endif()

    target_include_directories(${_target} PUBLIC include inline ${PROJECT_BINARY_DIR}/include ${MELT_ARGS_INCLUDE_DIRS})
    target_link_libraries(${_target} PUBLIC ${MELT_ARGS_LIBRARIES})
    target_include_directories(${_target} SYSTEM PUBLIC ${MELT_ARGS_SYSTEM_INCLUDE_DIRS})

    # setup melt warings
    melt_setup_wanings(${_target})

    if(MELT_ARGS_ALIAS)
        add_library(${MELT_ARGS_ALIAS} ALIAS ${_target})
    endif()

    if(MELT_ARGS_CXX_STANDARD)
        set_target_properties(${_target} PROPERTIES CXX_STANDARD ${MELT_ARGS_CXX_STANDARD})
        set_target_properties(${_target} PROPERTIES CXX_STANDARD_REQUIRED ON)
    endif()

    if (EXISTS ${${_target}_SOURCE_DIR}/tests)
        add_subdirectory(${${_target}_SOURCE_DIR}/tests)
    endif()

    if(MELT_ARGS_HEADERS)
        set_target_properties(${_target} PROPERTIES PUBLIC_HEADER "${MELT_ARGS_HEADERS}")
    endif()

    if(MELT_ARGS_DEFINITIONS)
        target_compile_definitions(${_target} PUBLIC "${MELT_ARGS_DEFINITIONS}")
    endif()

    if(MELT_ARGS_COMPILE_OPTIONS)
        target_compile_options(${_target} PUBLIC "${MELT_ARGS_COMPILE_OPTIONS}")
    endif()

    if(MELT_EXTRA_FLAGS)
        target_compile_options(${_target} PUBLIC "${MELT_EXTRA_FLAGS}")
    endif()

    if(NOT MELT_ARGS_NO_INSTALL)
        install(TARGETS ${_target}
            LIBRARY
              DESTINATION lib
              COMPONENT Libraries
              NAMELINK_COMPONENT Development
            PUBLIC_HEADER
              DESTINATION include/${MELT_ARGS_FOLDER}
              COMPONENT Development
        )
    endif()

    if(MELT_ARGS_DOXYGEN)
      melt_doxygen(${_target})
    endif()
endmacro()

macro(melt_library _target)
  _melt_target(${_target} IS_LIBRARY ${ARGN})
endmacro()

macro(melt_executable _target)
  _melt_target(${_target} IS_EXECUTABLE ${ARGN})
endmacro()
