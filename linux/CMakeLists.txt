# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "whisper_ggml")
project(${PROJECT_NAME} LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Threads REQUIRED)

# The native sources are shared with Android; both platforms build the same
# vendored whisper.cpp v1.9.1 (CPU backend) plus the JSON request/stream API
# in main.cpp.
set(W ${CMAKE_CURRENT_SOURCE_DIR}/../android/src/whisper/whisper.cpp)

# The arch/ sources are internally guarded per architecture, so compiling
# arm + x86 everywhere is safe; the wrong-arch files compile to nothing.
file(GLOB GGML_SRC
    ${W}/ggml/src/*.c
    ${W}/ggml/src/*.cpp
    ${W}/ggml/src/ggml-cpu/*.c
    ${W}/ggml/src/ggml-cpu/*.cpp
    ${W}/ggml/src/ggml-cpu/arch/arm/*.c
    ${W}/ggml/src/ggml-cpu/arch/arm/*.cpp
    ${W}/ggml/src/ggml-cpu/arch/x86/*.c
    ${W}/ggml/src/ggml-cpu/arch/x86/*.cpp
    ${W}/ggml/src/ggml-cpu/amx/*.cpp
)

add_library(whisper_ggml_core STATIC ${GGML_SRC} ${W}/src/whisper.cpp)
set_target_properties(whisper_ggml_core PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(whisper_ggml_core PUBLIC
    ${W}/include
    ${W}/ggml/include
    ${W}/ggml/src
    ${W}/ggml/src/ggml-cpu
    ${W}/src
)
target_compile_definitions(whisper_ggml_core PUBLIC GGML_USE_CPU)
# glibc gates pthread affinity APIs (CPU_ZERO, pthread_getaffinity_np,
# getcpu) behind _GNU_SOURCE; upstream ggml defines it on Linux too.
target_compile_definitions(whisper_ggml_core PRIVATE _GNU_SOURCE)
# Upstream generates these from git; we vendor a fixed release.
target_compile_definitions(whisper_ggml_core PRIVATE
    GGML_VERSION="1.9.1"
    GGML_COMMIT="whisper.cpp-v1.9.1"
    WHISPER_VERSION="1.9.1"
)
# -O3 unconditionally: Flutter's Linux debug config would otherwise leave
# inference an order of magnitude slower (mirrors the iOS/macOS/Windows
# builds). The last -O flag wins with GCC/Clang.
target_compile_options(whisper_ggml_core PRIVATE
    -O3 -ffunction-sections -fdata-sections
)

# AVX2 matches upstream whisper.cpp's standard x64 binaries and is supported
# by virtually every x64 CPU since ~2013. Set WHISPER_GGML_AVX2=OFF for a
# baseline SSE2 build if very old CPUs must be supported. Unlike MSVC,
# GCC/Clang define the feature macros (__AVX2__ etc.) from -m flags.
option(WHISPER_GGML_AVX2 "Build the x64 whisper backend with AVX2/FMA/F16C" ON)
if(WHISPER_GGML_AVX2 AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|amd64|AMD64")
  target_compile_options(whisper_ggml_core PRIVATE -mavx2 -mfma -mf16c)
endif()

# The plugin shared library. Dart opens it by name ('libwhisper_ggml.so');
# it is bundled into the app's lib/ directory, which is on the loader path.
add_library(whisper_ggml_plugin SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/../android/src/whisper/main.cpp
)
set_target_properties(whisper_ggml_plugin PROPERTIES OUTPUT_NAME "whisper_ggml")
target_compile_definitions(whisper_ggml_plugin PUBLIC DART_SHARED_LIB)
target_compile_options(whisper_ggml_plugin PRIVATE
    -O3 -ffunction-sections -fdata-sections
)
target_link_options(whisper_ggml_plugin PRIVATE -Wl,--gc-sections)
target_link_libraries(whisper_ggml_plugin PRIVATE
    whisper_ggml_core
    Threads::Threads
    ${CMAKE_DL_LIBS}
    m
)

# List of absolute paths to libraries that should be bundled with the plugin.
set(whisper_ggml_bundled_libraries
    $<TARGET_FILE:whisper_ggml_plugin>
    PARENT_SCOPE
)
