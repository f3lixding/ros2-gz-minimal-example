cmake_minimum_required(VERSION 3.10)
project(minimal_gz_demo)

find_package(ament_cmake REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(rclcpp REQUIRED)

add_executable(controller src/controller.cpp)
ament_target_dependencies(controller geometry_msgs nav_msgs rclcpp)

install(TARGETS controller DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY launch worlds DESTINATION share/${PROJECT_NAME})

ament_package()
