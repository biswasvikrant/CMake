# Copyright (c) 2014 Stefan.Eilemann@epfl.ch

# Configures the build for a simple library:
#   common_library(<Name>)
#
# Uses:
# * NAME_SOURCES for all compilation units
# * NAME_HEADERS for all internal header files
# * NAME_PUBLIC_HEADERS for public, installed header files
# * NAME_LINK_LIBRARIES for dependencies of name
# * NAME_LIBRARY_TYPE or COMMON_LIBRARY_TYPE for SHARED or STATIC library, with
#   COMMON_LIBRARY_TYPE being an option stored in the CMakeCache.
# * NAME_OMIT_PROJECT_HEADER when set, no project header (name.h) is generated.
# * PROJECT_INCLUDE_NAME for the include directory and project include header
# * VERSION for the API version
# * VERSION_ABI for the ABI version
#
# If NAME_LIBRARY_TYPE is a list, libraries are built of each specified
# (i.e. shared and static) type. Whichever is first becomes the library
# target associated with <Name>.
#
# Builds libName and installs it. Installs the public headers to include/name.
# Generates a PROJECT_INCLUDE_NAME/{BASE_NAME of PROJECT_INCLUDE_NAME}.h
# including all public headers.

include(InstallFiles)

set(COMMON_LIBRARY_TYPE SHARED CACHE STRING
  "Library type {any combination of SHARED, STATIC}")
set_property(CACHE COMMON_LIBRARY_TYPE PROPERTY STRINGS SHARED STATIC)

macro(GENERATE_PROJECT_HEADER NAME)
  get_filename_component(BASE_NAME ${PROJECT_INCLUDE_NAME} NAME)

  set(PROJECT_GENERATED_HEADER
    ${PROJECT_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/${BASE_NAME}.in.h)

  file(WRITE ${PROJECT_GENERATED_HEADER}
    "// generated by CommonLibrary.cmake, do not edit\n"
    "#ifndef ${NAME}_H\n"
    "#define ${NAME}_H\n")
  foreach(PUBLIC_HEADER ${PUBLIC_HEADERS})
    if(IS_ABSOLUTE ${PUBLIC_HEADER})
      get_filename_component(PUBLIC_HEADER ${PUBLIC_HEADER} NAME)
    endif()
    if(NOT PUBLIC_HEADER MATCHES "defines.+\\.h" AND
        (PUBLIC_HEADER MATCHES ".*\\.h$" OR
        PUBLIC_HEADER MATCHES ".*\\.hpp$"))

      file(APPEND ${PROJECT_GENERATED_HEADER}
        "#include <${PROJECT_INCLUDE_NAME}/${PUBLIC_HEADER}>\n")
    endif()
  endforeach()
  file(APPEND ${PROJECT_GENERATED_HEADER} "#endif\n")
  set(PROJECT_INCLUDE_HEADER
    ${PROJECT_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/${BASE_NAME}.h)

  configure_file(
    ${PROJECT_GENERATED_HEADER}
    ${PROJECT_INCLUDE_HEADER} COPYONLY)
  list(APPEND PUBLIC_HEADERS ${PROJECT_INCLUDE_HEADER})
endmacro()

function(COMMON_LIBRARY Name)
  string(TOUPPER ${Name} NAME)
  if(NOT PROJECT_INCLUDE_NAME)
    string(TOLOWER ${Name} PROJECT_INCLUDE_NAME)
  endif()
  set(SOURCES ${${NAME}_SOURCES})
  set(HEADERS ${${NAME}_HEADERS})
  set(PUBLIC_HEADERS ${${NAME}_PUBLIC_HEADERS})
  set(LINK_LIBRARIES ${${NAME}_LINK_LIBRARIES})

  if(NOT ${NAME}_OMIT_PROJECT_HEADER)
    generate_project_header(${NAME})
  endif()

  if(SOURCES)
    list(SORT SOURCES)
  endif()
  if(HEADERS)
    list(SORT HEADERS)
  endif()
  list(SORT PUBLIC_HEADERS)

  source_group(
    ${PROJECT_INCLUDE_NAME} FILES ${SOURCES} ${HEADERS} ${PUBLIC_HEADERS})
  if (NOT ${NAME}_LIBRARY_TYPE)
    set(${NAME}_LIBRARY_TYPE ${COMMON_LIBRARY_TYPE})
    if (NOT ${NAME}_LIBRARY_TYPE)
      set(${NAME}_LIBRARY_TYPE SHARED)
    endif()
  endif()
  foreach(LIBRARY_TYPE ${${NAME}_LIBRARY_TYPE})
    set(LIBNAME ${Name})
    if (TARGET ${Name})
    set(LIBNAME "${Name}_${LIBRARY_TYPE}")
    endif()
    add_library(${LIBNAME} ${LIBRARY_TYPE} ${SOURCES} ${HEADERS} ${PUBLIC_HEADERS})
    set_target_properties(${LIBNAME}
      PROPERTIES VERSION ${VERSION} SOVERSION ${VERSION_ABI} OUTPUT_NAME ${Name})
    target_link_libraries(${LIBNAME} ${LINK_LIBRARIES})
    install(TARGETS ${LIBNAME}
      ARCHIVE DESTINATION ${LIBRARY_DIR} COMPONENT dev
      RUNTIME DESTINATION bin COMPONENT lib
      LIBRARY DESTINATION ${LIBRARY_DIR} COMPONENT lib)
  endforeach()

  if(MSVC AND "${${NAME}_LIBRARY_TYPE}" MATCHES "SHARED")
    install(FILES ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug/${Name}.pdb
      DESTINATION bin COMPONENT lib CONFIGURATIONS Debug)
    install(FILES ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/RelWithDebInfo/${Name}.pdb
      DESTINATION bin COMPONENT lib CONFIGURATIONS RelWithDebInfo)
  endif()

  # install(TARGETS ... PUBLIC_HEADER ...) flattens directories
  install_files(include/${PROJECT_INCLUDE_NAME}
    FILES ${PUBLIC_HEADERS} COMPONENT dev)
endfunction()
