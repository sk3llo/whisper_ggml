Pod::Spec.new do |s|
  s.name             = 'whisper_ggml'
  s.version          = '1.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'https://github.com/sk3llo/whisper_ggml'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'kapraton@gmail.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.dependency 'Flutter'
  s.source           = {
    :git => 'https://github.com/sk3llo/whisper_ggml'
  }
  s.source_files = 'Classes/**/*.{cpp,c,h,hpp}'
  # Only whisper.h is public; the ggml tree has duplicate header basenames
  # (common.h, quants.h) that collide when flattened into the framework.
  s.public_header_files = 'Classes/whisper/include/whisper.h'
  s.platform = :ios, '15.6'
  s.ios.deployment_target  = '15.6'

  s.library = 'c++'
  s.frameworks = 'Accelerate'
  # Build settings stay pod-scoped: s.xcconfig would also put them in the
  # app's Pods-Runner xcconfig, where they can override the app's own (#32).
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # Flutter.framework does not contain a i386 slice.
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
    # whisper.cpp v1.9.5 (CPU backend) include roots
    'HEADER_SEARCH_PATHS' => [
      '"$(PODS_TARGET_SRCROOT)/Classes/whisper/include"',
      '"$(PODS_TARGET_SRCROOT)/Classes/whisper/ggml/include"',
      '"$(PODS_TARGET_SRCROOT)/Classes/whisper/ggml/src"',
      '"$(PODS_TARGET_SRCROOT)/Classes/whisper/ggml/src/ggml-cpu"',
      '"$(PODS_TARGET_SRCROOT)/Classes/whisper/src"',
    ].join(' '),
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GGML_USE_CPU=1 GGML_USE_ACCELERATE=1 ACCELERATE_NEW_LAPACK=1 ACCELERATE_LAPACK_ILP64=1 WHISPER_VERSION=\"1.9.5\"',
    # keep inference usable in debug builds
    'GCC_OPTIMIZATION_LEVEL' => '3',
  }
  s.swift_version = '5.0'
end
