
cmake_policy(SET CMP0076 NEW)

macro(melt_add_test _name)

    if(NOT BUILD_TESTING)
      return()
    endif()

    set(_target ${PROJECT_NAME}-test-${_name})

    if(NOT WORKING_DIRECTORY IN_LIST _MELT_TARGET_PARSE_ONE_VALUE_ARGS)
      set(_MELT_TARGET_PARSE_ONE_VALUE_ARGS ${_MELT_TARGET_PARSE_ONE_VALUE_ARGS}
        WORKING_DIRECTORY
      )
    endif()

    # add cache variable to disable this test
    set(_no_test_var_name "${PROJECT_NAME}_NO_${_name}")
    string(TOUPPER ${_no_test_var_name} _no_test_var_name)
    string(REPLACE "-" "_" _no_test_var_name ${_no_test_var_name})
    set(${_no_test_var_name} OFF CACHE BOOL "Disable ${PROJECT_NAME}-${_name} while running tests")

    melt_executable(${_target} ${ARGN})

    if (EXISTS ${CMAKE_CURRENT_LIST_DIR}/test-${_name}.cpp)
        target_sources(${_target} PUBLIC test-${_name}.cpp)
    endif()

    # create project-test group
    if (NOT TARGET ${PROJECT_NAME}-tests)
        add_custom_target(${PROJECT_NAME}-tests)
    endif()
    add_dependencies(${PROJECT_NAME}-tests ${_target})

    if (NOT MELT_ARGS_WORKING_DIRECTORY)
        set(MELT_ARGS_WORKING_DIRECTORY ${${PROJECT_NAME}_BINARY_DIR})
    endif()
    target_link_libraries(${_target} PRIVATE CONAN_PKG::gtest Threads::Threads)
    if (NOT ${${_no_test_var_name}})
        include(GoogleTest)
        gtest_discover_tests(${_target} WORKING_DIRECTORY ${MELT_ARGS_WORKING_DIRECTORY})
    else()
        message(STATUS "test ${_target} disabled")
    endif()
    if(TARGET ${PROJECT_NAME})
        get_target_property(_test_folder ${PROJECT_NAME} FOLDER)
        if(_test_folder)
            set(_test_folder "${_test_folder}/${PROJECT_NAME}-tests")
        endif()
    endif()
    set_target_properties(${_target} PROPERTIES FOLDER ${_test_folder})
endmacro()


macro(melt_discover_tests)
    file(GLOB _files test-*.cpp)
    foreach(_file ${_files})
        get_filename_component(_name ${_file} NAME_WE)
        string(REGEX REPLACE "test-(.*)" [[\1]] _name ${_name})
        melt_add_test(${_name})
    endforeach()
endmacro()
