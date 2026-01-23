cmake_minimum_required(VERSION 3.16)
project(CapnpSwiftWrapper LANGUAGES C CXX)

# Use Cap'n Proto's CMake build, but keep tests off and prefer static libs.
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

add_subdirectory(capnproto)

add_library(capnp_c STATIC src/CapnpCLib/capnp_c.cpp)

target_include_directories(capnp_c
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/CapnpCLib/include
    ${CMAKE_CURRENT_SOURCE_DIR}/capnproto/c++/src
)

target_link_libraries(capnp_c PUBLIC capnp kj)

install(TARGETS capnp_c ARCHIVE DESTINATION lib)
install(FILES src/CapnpCLib/include/capnp_c.h DESTINATION include)
