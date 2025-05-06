cmake_minimum_required(VERSION 4.0)

project(sample_basics_hello-world C ASM)

find_package(SGDK REQUIRED)

md_add_rom(hello-world SGDK::md src/boot/rom_head.c src/boot/sega.s)
target_sources(hello-world PRIVATE src/main.c)
