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
