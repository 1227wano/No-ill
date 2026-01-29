cmake_minimum_required(VERSION 3.8)
project(tracking_drive_test)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)

add_executable(person_cmdvel src/person_cmdvel.cpp)
ament_target_dependencies(person_cmdvel
  rclcpp
  std_msgs
  geometry_msgs
)

install(TARGETS
  person_cmdvel
  DESTINATION lib/${PROJECT_NAME}
)

ament_package()

