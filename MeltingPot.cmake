if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.melt_options)
  file(STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/.melt_options _melt_raw_opts)
  foreach(_raw_opt ${_melt_raw_opts})
    string(STRIP ${_raw_opt} _raw_opt)
    set(_var_regex [[^([A-Za-z0-9_]+) *= *([A-Za-z0-9_]+) *]])
    if(${_raw_opt} MATCHES ${_var_regex})
      message(STATUS "melt option: ${CMAKE_MATCH_1} = ${CMAKE_MATCH_2}")
      set(MELT_${CMAKE_MATCH_1} ${CMAKE_MATCH_2})
    elseif(${_raw_opt} MATCHES [[\#.*]])
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
include(${CMAKE_CURRENT_LIST_DIR}/Warnings.cmake)

include(GenerateExportHeader)

#
#
#
#
macro(_melt_target _target)
    set(options EXECUTABLE LIBRARY SHARED NO_INSTALL DOXYGEN)
    set(oneValueArgs ALIAS CXX_STANDARD FOLDER)
    set(multiValueArgs
        SOURCES
        HEADERS
        LIBRARIES
        DEFINITIONS
        INCLUDE_DIRS
        SYSTEM_INCLUDE_DIRS
    )
    cmake_parse_arguments(OPTS
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )
    if(OPTS_EXECUTABLE)
      add_executable(${_target} ${OPTS_SOURCES} ${OPTS_HEADERS})
    elseif(OPTS_LIBRARY)
      if(OPTS_SHARED)
          set(_lib_type SHARED)
      endif()

      add_library(${_target} ${_lib_type} ${OPTS_SOURCES} ${OPTS_HEADERS})
      if(OPTS_FOLDER)
          set_target_properties(${_target} PROPERTIES FOLDER ${OPTS_FOLDER})
          set(_generated_include_dirs ${PROJECT_BINARY_DIR}/include/${OPTS_FOLDER})
      else()
          set(_generated_include_dirs ${PROJECT_BINARY_DIR}/include)
      endif()

      generate_export_header(${_target} EXPORT_FILE_NAME ${_generated_include_dirs}/${_target}-export.hpp)
      list(APPEND OPTS_HEADERS ${_generated_include_dirs}/${_target}-export.hpp)
      target_sources(${_target} PUBLIC ${_generated_include_dirs}/${_target}-export.hpp)

    else()
      message(FATAL_ERROR "you should use melt_library or melt_executable, not _melt_target direclty")
    endif()

    target_include_directories(${_target} PUBLIC include inline ${PROJECT_BINARY_DIR}/include ${OPTS_INCLUDE_DIRS})
    target_link_libraries(${_target} PUBLIC ${OPTS_LIBRARIES})
    target_include_directories(${_target} SYSTEM PUBLIC ${OPTS_SYSTEM_INCLUDE_DIRS})

    # setup melt warings
    melt_setup_wanings(${_target})

    if(OPTS_ALIAS)
        add_library(${OPTS_ALIAS} ALIAS ${_target})
    endif()

    if(OPTS_CXX_STANDARD)
        set_target_properties(${_target} PROPERTIES CXX_STANDARD ${OPTS_CXX_STANDARD})
        set_target_properties(${_target} PROPERTIES CXX_STANDARD_REQUIRED ON)
    endif()

    if (EXISTS ${${_target}_SOURCE_DIR}/tests)
        add_subdirectory(${${_target}_SOURCE_DIR}/tests)
    endif()

    if(OPTS_HEADERS)
        set_target_properties(${_target} PROPERTIES HEADER "${OPTS_HEADERS}")
    endif()

    if(OPTS_DEFINITIONS)
        target_compile_definitions(${_target} PUBLIC OPTS_DEFINITIONS)
    endif()

    if(NOT OPTS_NO_INSTALL)
        install(TARGETS ${_target}
            LIBRARY
              DESTINATION lib
              COMPONENT Libraries
              NAMELINK_COMPONENT Development
            PUBLIC_HEADER
              DESTINATION include/${OPTS_FOLDER}
              COMPONENT Development
        )
    endif()

    if(OPTS_DOXYGEN)
      melt_doxygen(${_target})
    endif()
endmacro()

function(melt_library _target)
  _melt_target(${_target} LIBRARY ${ARGN})
endfunction()

function(melt_executable _target)
  _melt_target(${_target} EXECUTABLE ${ARGN})
endfunction()
