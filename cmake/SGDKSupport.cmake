include_guard(GLOBAL)

# Rules to build z80 source code
function(md_target_z80_include_directories target) # ARGN: include directories only used for .s80 files
  SGDK_ext_interface(${target} z80_includes) # sets target_z80_includes
  target_include_directories(${target_z80_includes} INTERFACE ${ARGN})
endfunction()

function(md_target_z80_sources target header_scope) # ARGN: .s80 files
  SGDK_ext_interface(${target} z80_includes) # sets target_z80_includes
  SGDK_ext_out_dir(${target} z80) # sets z80_out_dir

  set(target_includes "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>,PREPEND,-i>")
  set(extra_target_includes "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${target_z80_includes},INTERFACE_INCLUDE_DIRECTORIES>,PREPEND,-i>")
  
  set(processed_src)
  set(processed_headers)
  foreach(z80_source IN ITEMS ${ARGN})
    # message("Generating z80->m68k command for ${z80_source}...")
    cmake_path(ABSOLUTE_PATH z80_source BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
    cmake_path(RELATIVE_PATH z80_source BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" OUTPUT_VARIABLE z80_relative_source)
    cmake_path(REMOVE_EXTENSION z80_relative_source OUTPUT_VARIABLE z80_relative_stem)
    set(out_stem "${z80_out_dir}/${z80_relative_stem}")
    set(m68k_asm "${out_stem}.s")
    set(c_header "${out_stem}.h")
    set(z80_bin "${out_stem}.o80")
    # message("Building to ${m68k_asm}")

    add_custom_command(
      OUTPUT ${m68k_asm} ${c_header}
      COMMAND ${ASMZ80_CMD} ${target_includes} ${extra_target_includes} "${z80_source}" ${z80_bin}
      COMMAND ${BINTOS_CMD} ${z80_bin} ${m68k_asm}
      COMMAND_EXPAND_LISTS
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      VERBATIM
      MAIN_DEPENDENCY "${z80_source}"
      DEPENDS bintos sjasm
      BYPRODUCTS ${z80_bin}
    )

    list(APPEND processed_src ${m68k_asm})
    list(APPEND processed_headers ${c_header})
  endforeach()

  # Source files built by target
  target_sources(${target} PRIVATE ${processed_src})

  # Headers added to target using provided scope
  target_sources(${target}
    ${header_scope}
    FILE_SET z80_headers TYPE HEADERS BASE_DIRS ${z80_out_dir} FILES
      ${processed_headers}
  )

endfunction()

# Rules to build resources
function(md_target_resources target header_scope) # ARGN: .res files
  SGDK_ext_out_dir(${target} res) # sets res_out_dir

  set(processed_src)
  set(processed_headers)
  foreach(res_source IN ITEMS ${ARGN})
    # message("Generating res->m68k command for ${res_source}...")
    cmake_path(ABSOLUTE_PATH res_source BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
    cmake_path(RELATIVE_PATH res_source BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" OUTPUT_VARIABLE res_relative_source)
    cmake_path(REMOVE_EXTENSION res_relative_source OUTPUT_VARIABLE res_relative_stem)
    set(out_stem "${res_out_dir}/${res_relative_stem}")
    set(m68k_asm "${out_stem}.s")
    set(c_header "${out_stem}.h")
    set(dep_file "${out_stem}.d")
    # message("Building to ${m68k_asm}")

    add_custom_command(
      OUTPUT ${m68k_asm} ${c_header}
      DEPFILE ${dep_file}
      COMMAND ${RESCOMP_CMD} "${res_source}" ${m68k_asm} -dep ${dep_file}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      MAIN_DEPENDENCY "${res_source}"
      DEPENDS xgmtool
      BYPRODUCTS ${dep_file}
    )

    list(APPEND processed_src ${m68k_asm})
    list(APPEND processed_headers ${c_header})
  endforeach()

  # Source files built by target
  target_sources(${target} PRIVATE ${processed_src})

  # Headers added to target using provided scope
  target_sources(${target}
    ${header_scope}
    FILE_SET res_headers TYPE HEADERS BASE_DIRS ${res_out_dir} FILES
      ${processed_headers}
  )

endfunction()

# Create a ROM target using preferred SGDK library
function(md_add_rom target mdlib rom_head_c sega_s)
  ## Create target using given name, linking with chosen mdlib.
  # This will generate the .out, although the setup for that is further below.
  # This target can be added to by the user, with sources, options, properties etc.
  add_executable(${target})
  target_link_libraries(${target} PUBLIC ${mdlib})

  ## Set up the boot files
  # Build rom_head.c into an object
  set(target_rom_head "${target}.rom_head")
  add_library(${target_rom_head} OBJECT ${rom_head_c})
  target_link_libraries(${target_rom_head} PRIVATE ${mdlib})

  # Generate rom_head.bin. Because sega.s will try to include "out/rom_head.bin", the bin
  # needs to be created within a folder called "out", and the root of that folder will be passed
  # as an include for building sega.s
  set(out_rom_head_dir "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${target}.rom_head.dir")
  file(MAKE_DIRECTORY "${out_rom_head_dir}/out")
  set(out_rom_head_bin "${out_rom_head_dir}/out/rom_head.bin")
  add_custom_command(
    OUTPUT ${out_rom_head_bin}
    COMMAND ${OBJCPY_CMD} -O binary "$<TARGET_OBJECTS:${target_rom_head}>" "${out_rom_head_bin}"
    DEPENDS ${target_rom_head}
  )
  set(target_out_rom_head "${target}.out.rom_head")
  add_custom_target(${target_out_rom_head} DEPENDS ${out_rom_head_bin})

  # Build sega.s into an object
  set(target_boot "${target}.boot")
  add_library(${target_boot} OBJECT ${sega_s})
  target_link_libraries(${target_boot} PUBLIC ${mdlib})
  add_dependencies(${target_boot} ${target_out_rom_head})
  # Allow "out/rom_head.bin" to be found, by using this include directory.
  target_compile_options(${target_boot} PRIVATE "-Wa,-I${out_rom_head_dir}")

  ## Set up the executable
  # Link against sega.s
  target_link_libraries(${target} PRIVATE ${target_boot})

  # Apply linker script, link options, and use .bin suffix.
  # We're *actually* building the .out, but this allows us to tell CMake that the real executable is the bin
  set_target_properties(${target}
    PROPERTIES
      SUFFIX ".bin"
      LINK_DEPENDS ${SGDK_LINKER_SCRIPT}
  )
  target_link_options(${target}
    PRIVATE
      -n
      -T${SGDK_LINKER_SCRIPT}
      "LINKER:--gc-sections"
       -flto
       -flto=auto
       -ffat-lto-objects
  )

  # Final ROM generation: copy .out file, objcopy, pad
  set(target_bin "$<TARGET_FILE:${target}>")
  set(target_out "${CMAKE_CURRENT_BINARY_DIR}/${target}.out")
  add_custom_command(TARGET ${target}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E rename ${target_bin} ${target_out}
    COMMAND ${OBJCPY_CMD} -O binary ${target_out} ${target_bin} &&
            ${SIZEBND_CMD} ${target_bin} -sizealign 131072 -checksum
    BYPRODUCTS ${target_out}
  )

endfunction()

## Private
function(SGDK_ext_interface target extension)
  set(extra_target_name "target_${extension}")
  set(${extra_target_name} "${target}.${extension}" PARENT_SCOPE)
  if(NOT TARGET ${${extra_target_name}})
    add_library(${${extra_target_name}} INTERFACE)
  endif()
endfunction()

function(SGDK_ext_out_dir target extension)
  set(out_dir_var_name "${extension}_out_dir")
  set(${out_dir_var_name} "${CMAKE_CURRENT_BINARY_DIR}/SGDKFiles/${target}.${extension}" PARENT_SCOPE)
endfunction()
