Pod::Spec.new do |s|
  s.name             = 'bronze_monkey_ffi'
  s.version          = '0.0.1'
  s.summary          = 'Bronze Monkey Rust FFI static library'
  s.description      = 'Flutter plugin wrapping the Bronze Monkey Rust static library for iOS.'
  s.homepage         = 'https://github.com/ddavef/bronze_monkey_priv'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ddavef' => 'ddavef@users.noreply.github.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.static_framework = true
  s.vendored_libraries = 'libbronze_monkey.a'
  s.user_target_xcconfig = { 'DEAD_CODE_STRIPPING' => 'NO' }
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'
end
