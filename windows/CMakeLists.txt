# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "whisper_ggml")
project(${PROJECT_NAME} LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# The native sources are shared with Android; both platforms build the same
# vendored whisper.cpp v1.9.1 (CPU backend) plus the JSON request/stream API
# in main.cpp.
set(W ${CMAKE_CURRENT_SOURCE_DIR}/../android/src/whisper/whisper.cpp)

if(MSVC)
  # ggml sources contain UTF-8 literals; without /utf-8 MSVC mis-decodes them
  # on non-UTF-8 system codepages.
  add_compile_options(/utf-8 /bigobj)
  add_compile_definitions(_CRT_SECURE_NO_WARNINGS NOMINMAX)
  # Keep inference usable in debug builds (mirrors the macOS podspec, which
  # forces -O3): unoptimized ggml is an order of magnitude slower. /RTC1 must
  # go first — it is incompatible with /O2.
  foreach(flag_var CMAKE_C_FLAGS_DEBUG CMAKE_CXX_FLAGS_DEBUG)
    string(REPLACE "/RTC1" "" ${flag_var} "${${flag_var}}")
    string(REPLACE "/Od" "/O2" ${flag_var} "${${flag_var}}")
    string(REPLACE "/Ob0" "/Ob2" ${flag_var} "${${flag_var}}")
  endforeach()
endif()

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
# Upstream generates these from git; we vendor a fixed release.
target_compile_definitions(whisper_ggml_core PRIVATE
    GGML_VERSION="1.9.1"
    GGML_COMMIT="whisper.cpp-v1.9.1"
    WHISPER_VERSION="1.9.1"
)

# AVX2 matches upstream whisper.cpp's standard x64 Windows binaries and is
# supported by virtually every x64 CPU since ~2013. MSVC does not define the
# GCC-style feature macros that ggml's dispatch code checks, so they are set
# explicitly alongside /arch:AVX2. Set WHISPER_GGML_AVX2=OFF for a baseline
# SSE2 build if very old CPUs must be supported.
option(WHISPER_GGML_AVX2 "Build the x64 whisper backend with AVX2/FMA/F16C" ON)
if(MSVC AND WHISPER_GGML_AVX2 AND NOT CMAKE_GENERATOR_PLATFORM MATCHES "ARM64"
   AND NOT CMAKE_SYSTEM_PROCESSOR MATCHES "ARM64|aarch64")
  target_compile_options(whisper_ggml_core PRIVATE /arch:AVX2)
  target_compile_definitions(whisper_ggml_core PRIVATE
      __SSE3__ __SSSE3__ __AVX__ __AVX2__ __FMA__ __F16C__
  )
endif()

# The plugin DLL. Dart opens it by name ('whisper_ggml.dll'); the exported
# request/stream_* functions are marked __declspec(dllexport) in main.h.
add_library(whisper_ggml_plugin SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/../android/src/whisper/main.cpp
)
set_target_properties(whisper_ggml_plugin PROPERTIES OUTPUT_NAME "whisper_ggml")
target_compile_definitions(whisper_ggml_plugin PUBLIC DART_SHARED_LIB)
target_link_libraries(whisper_ggml_plugin PRIVATE whisper_ggml_core)

# List of absolute paths to libraries that should be bundled with the plugin.
set(whisper_ggml_bundled_libraries
    $<TARGET_FILE:whisper_ggml_plugin>
    PARENT_SCOPE
)
