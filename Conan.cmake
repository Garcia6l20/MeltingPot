macro(conan_requires _requires)

  # some default values
  set(CONAN_BUILD outdated)

  set(options)
  set(oneValueArgs BUILD)
  set(multiValueArgs OPTIONS REPOSITORIES)
  cmake_parse_arguments(CONAN
      "${options}"
      "${oneValueArgs}"
      "${multiValueArgs}"
      ${ARGN}
  )

  # Download automatically, you can also just copy the conan.cmake file
  if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
    set(CMAKE_CONAN_VERSION 0.15 CACHE STRING "Version of the cmake wrapper to download")
    message(
      STATUS
        "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD "https://github.com/conan-io/cmake-conan/raw/v${CMAKE_CONAN_VERSION}/conan.cmake"
         "${CMAKE_BINARY_DIR}/conan.cmake")
  endif()

  include(${CMAKE_BINARY_DIR}/conan.cmake)

  list(LENGTH CONAN_REPOSITORIES _len)
  math(EXPR _len "${_len} - 1")
  foreach(_ii RANGE 0 ${_len} 4)
    list(SUBLIST CONAN_REPOSITORIES ${_ii} 4 _repo)
    cmake_parse_arguments(CONAN_REPO
      ""
      "NAME;URL"
      ""
      ${_repo}
    )
    if(NOT CONAN_REPO_NAME OR NOT CONAN_REPO_URL)
        message(FATAL_ERROR "REPOSITORIES arguments must match NAME <name> URL <url>")
    endif()
    string(STRIP ${CONAN_REPO_NAME} CONAN_REPO_NAME)
    string(STRIP ${CONAN_REPO_URL} CONAN_REPO_URL)
    conan_add_remote(NAME ${CONAN_REPO_NAME} URL ${CONAN_REPO_URL})
  endforeach()

  conan_cmake_run(
    REQUIRES
    ${_requires}
    OPTIONS
    ${CONAN_OPTIONS}
    BASIC_SETUP
    CMAKE_TARGETS # individual targets to link to
    BUILD
    outdated
  )
endmacro()
