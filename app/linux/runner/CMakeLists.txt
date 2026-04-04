cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, update BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` may complain
# about an unexpected executable name.
#
# Any new source files that you add to the application can be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Only the install-hierarchical target needs to link to the $ORIGIN/lib
# directory. All other targets link to the build directory, which is the
# default rpath.
target_link_options(${BINARY_NAME} PRIVATE "-Wl,-rpath,$ORIGIN/lib")
