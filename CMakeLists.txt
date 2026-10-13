cmake_minimum_required(VERSION 3.25)
project(motion_bricks_godot LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(FetchContent)

FetchContent_Declare(godot_cpp
  GIT_REPOSITORY https://github.com/godotengine/godot-cpp.git
  GIT_TAG 10.0.0-stable
)
set(GODOTCPP_API_VERSION "4.7" CACHE STRING "" FORCE)
FetchContent_MakeAvailable(godot_cpp)

FetchContent_Declare(motion_bricks
  GIT_REPOSITORY https://github.com/localai-org/motion-bricks.cpp.git
  GIT_TAG a0732b642c0333077e127a2f56ab0014c196bca4
  GIT_SUBMODULES ggml
  GIT_SHALLOW FALSE
)

# Keep the upstream build focused on the runtime library. Android does not
# need the CLI/tests/demo binaries, Vulkan, physics, or model download during
# the native-library build.
set(MOTIONBRICKS_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(MOTIONBRICKS_ENABLE_GGML ON CACHE BOOL "" FORCE)
set(MOTIONBRICKS_ENABLE_LLAMAFILE OFF CACHE BOOL "" FORCE)
set(MOTIONBRICKS_CPU_ALL_VARIANTS OFF CACHE BOOL "" FORCE)
set(MOTIONBRICKS_ENABLE_VULKAN OFF CACHE BOOL "" FORCE)
set(MOTIONBRICKS_ENABLE_PHYSICS OFF CACHE BOOL "" FORCE)
set(MOTIONBRICKS_DOWNLOAD_MODELS OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(motion_bricks)

add_library(motion_bricks_godot SHARED motion_bricks_native.cpp)
target_include_directories(motion_bricks_godot PRIVATE
  ${godot_cpp_SOURCE_DIR}/include
  ${godot_cpp_BINARY_DIR}/gen/include
  ${motion_bricks_SOURCE_DIR}/include
)
target_link_libraries(motion_bricks_godot PRIVATE godot-cpp motionbricks_static)
target_compile_definitions(motion_bricks_godot PRIVATE MOTIONBRICKS_SHARED)
set_target_properties(motion_bricks_godot PROPERTIES PREFIX "lib" OUTPUT_NAME "motion_bricks_godot")
