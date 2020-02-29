function(conan_requires)

  if(CONAN_EXPORTED) # in conan local cache
      # standard conan installation, deps will be defined in conanfile.py
      # and not necessary to call conan again, conan is already running
      include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
      conan_basic_setup()
  else()

    # some default values
    set(CONAN_BUILD outdated)

    set(options)
    set(oneValueArgs BUILD ARCH)
    set(multiValueArgs OPTIONS REPOSITORIES)
    cmake_parse_arguments(CONAN
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )
    set(_requires ${CONAN_UNPARSED_ARGUMENTS})

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

    if(CONAN_REPOSITORIES)
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
    endif()

    if(MELT_TESTING_BACKENDS)
      list(APPEND _requires ${MELT_TESTING_BACKENDS})
    endif()

    conan_cmake_run(
      REQUIRES ${_requires}
      OPTIONS ${CONAN_OPTIONS}
      BASIC_SETUP
      CMAKE_TARGETS # individual targets to link to
      GENERATORS cmake_find_package
      BUILD "${CONAN_BUILD}"
      ARCH "${CONAN_ARCH}"
    )

  endif()

  # expose conan's find packages
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})
  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} PARENT_SCOPE)

endfunction()
