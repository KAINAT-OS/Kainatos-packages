cmake_minimum_required(VERSION 3.5)
project(kio_mydisks)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

find_package(KF5 REQUIRED COMPONENTS CoreAddons KIO)

add_definitions(-DTRANSLATION_DOMAIN=\"kio_mydisks\")

add_library(kio_mydisks MODULE kio_mydisks.cpp)
target_link_libraries(kio_mydisks KF5::KIOCore KF5::KIOWidgets)

install(TARGETS kio_mydisks DESTINATION ${KDE_INSTALL_PLUGINDIR}/kf5/kio)
install(FILES mydisks.json DESTINATION ${KDE_INSTALL_KSERVICES5DIR})
