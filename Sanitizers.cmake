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
