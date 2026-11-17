// swift-tools-version: 5.9
// Swift Package Manager manifest, used when the host app has SPM enabled
// (the default since Flutter 3.44). CocoaPods builds use ../whisper_ggml.podspec,
// which compiles the same sources with the same settings; keep the two in sync.

import PackageDescription

let package = Package(
    name: "whisper_ggml",
    platforms: [
        .macOS("10.15"),
    ],
    products: [
        // Dynamic, like the CocoaPods framework: this is an FFI plugin, so
        // nothing links against its symbols and a static library would be
        // dead-stripped. Dart finds them with DynamicLibrary.process().
        .library(name: "whisper-ggml", type: .dynamic, targets: ["whisper_ggml"]),
    ],
    targets: [
        .target(
            name: "whisper_ggml",
            exclude: ["whisper/LICENSE"],
            // Only whisper.h is public; the ggml tree has duplicate header
            // basenames (common.h, quants.h).
            publicHeadersPath: "whisper/include",
            cSettings: [
                // whisper.cpp v1.9.5 (CPU backend) include roots
                .headerSearchPath("whisper/include"),
                .headerSearchPath("whisper/ggml/include"),
                .headerSearchPath("whisper/ggml/src"),
                .headerSearchPath("whisper/ggml/src/ggml-cpu"),
                .headerSearchPath("whisper/src"),
                .define("GGML_USE_CPU", to: "1"),
                .define("GGML_USE_ACCELERATE", to: "1"),
                .define("ACCELERATE_NEW_LAPACK", to: "1"),
                .define("ACCELERATE_LAPACK_ILP64", to: "1"),
                .define("WHISPER_VERSION", to: "\"1.9.5\""),
                // keep inference usable in debug builds
                .unsafeFlags(["-O3"]),
            ],
            cxxSettings: [
                .headerSearchPath("whisper/include"),
                .headerSearchPath("whisper/ggml/include"),
                .headerSearchPath("whisper/ggml/src"),
                .headerSearchPath("whisper/ggml/src/ggml-cpu"),
                .headerSearchPath("whisper/src"),
                .define("GGML_USE_CPU", to: "1"),
                .define("GGML_USE_ACCELERATE", to: "1"),
                .define("ACCELERATE_NEW_LAPACK", to: "1"),
                .define("ACCELERATE_LAPACK_ILP64", to: "1"),
                .define("WHISPER_VERSION", to: "\"1.9.5\""),
                .unsafeFlags(["-O3"]),
            ],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedLibrary("c++"),
            ]
        ),
    ],
    cxxLanguageStandard: .cxx20
)
