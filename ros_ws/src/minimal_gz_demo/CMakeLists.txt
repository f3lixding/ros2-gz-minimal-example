cmake_minimum_required(VERSION 3.10)
project(minimal_gz_demo)

find_package(ament_cmake REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(rclcpp REQUIRED)

find_program(ZIG_EXECUTABLE zig REQUIRED)

set(TESTLIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../pkgs/testlib")
set(TESTLIB_INCLUDE_DIR "${TESTLIB_DIR}/zig-out/include")
set(TESTLIB_LIBRARY "${TESTLIB_DIR}/zig-out/lib/libtestlib.so")

add_custom_command(
  OUTPUT "${TESTLIB_LIBRARY}" "${TESTLIB_INCLUDE_DIR}/testlib.h"
  COMMAND "${ZIG_EXECUTABLE}" build --release=fast
  WORKING_DIRECTORY "${TESTLIB_DIR}"
  DEPENDS
    "${TESTLIB_DIR}/build.zig"
    "${TESTLIB_DIR}/build.zig.zon"
    "${TESTLIB_DIR}/src/root.zig"
    "${TESTLIB_DIR}/include/testlib.h"
  COMMENT "Building Zig testlib"
  VERBATIM
)

add_custom_target(testlib_zig DEPENDS "${TESTLIB_LIBRARY}" "${TESTLIB_INCLUDE_DIR}/testlib.h")

add_library(testlib SHARED IMPORTED GLOBAL)
set_target_properties(testlib PROPERTIES
  IMPORTED_LOCATION "${TESTLIB_LIBRARY}"
  INTERFACE_INCLUDE_DIRECTORIES "${TESTLIB_INCLUDE_DIR}"
)
add_dependencies(testlib testlib_zig)

add_executable(controller src/controller.cpp)
ament_target_dependencies(controller geometry_msgs nav_msgs rclcpp)
add_dependencies(controller testlib_zig)
target_link_libraries(controller testlib)

install(TARGETS controller DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY launch worlds DESTINATION share/${PROJECT_NAME})

ament_package()
