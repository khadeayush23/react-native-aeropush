cmake_minimum_required(VERSION 3.13)
project(aeropush-crash)

add_library(aeropush-crash SHARED
    aeropush_signal_handler.cpp
)

target_link_libraries(aeropush-crash
    log
)

target_compile_options(aeropush-crash PRIVATE
    -Wall
    -Wextra
    -fno-exceptions
    -fno-rtti
)
