cmake_minimum_required(VERSION 3.16)

# Get version
file(READ "${CMAKE_SOURCE_DIR}/VERSION" VER_RAW)
string(STRIP ${VER_RAW} VER)

project(hpa VERSION ${VER} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Widgets Quick QuickControls2)
find_package(PkgConfig REQUIRED)
set(CMAKE_CXX_STANDARD 23)

pkg_check_modules(
  deps
  REQUIRED
  IMPORTED_TARGET
  hyprutils
  polkit-agent-1
  polkit-qt6-1)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(fusion-polkitagent
    src/main.cpp
    src/core/Agent.cpp
    src/core/Agent.hpp
    src/core/PolkitListener.hpp
    src/core/PolkitListener.cpp
    src/QMLIntegration.cpp
    src/QMLIntegration.hpp
    src/core/SecureString.hpp
)

qt_add_qml_module(fusion-polkitagent
    URI fusionpolkit
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/IconLock.qml
    SOURCES
        src/QMLIntegration.cpp
        src/QMLIntegration.hpp
)

target_link_libraries(fusion-polkitagent
    PRIVATE Qt6::Widgets Qt6::Quick Qt6::Gui Qt6::QuickControls2 PkgConfig::deps
)

include(GNUInstallDirs)

# Hardening compile & link options (best-effort checks omitted for brevity)
if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(fusion-polkitagent PRIVATE -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE)
    target_link_options(fusion-polkitagent PRIVATE -pie -Wl,-z,relro -Wl,-z,now)
endif()

set(LIBEXECDIR ${CMAKE_INSTALL_FULL_LIBEXECDIR})
configure_file(assets/fusion-polkitagent-service.in fusion-polkitagent.service @ONLY)
configure_file(assets/fusion-polkitagent-dbus.in fusion-polkitagent-dbus.service @ONLY)

install(TARGETS fusion-polkitagent
        DESTINATION ${CMAKE_INSTALL_LIBEXECDIR})
install(FILES ${CMAKE_BINARY_DIR}/fusion-polkitagent.service
        DESTINATION "lib/systemd/user")
install(FILES ${CMAKE_BINARY_DIR}/fusion-polkitagent-dbus.service
        DESTINATION ${CMAKE_INSTALL_DATADIR}/dbus-1/services
        RENAME org.fusionpolkit.agent.service)
