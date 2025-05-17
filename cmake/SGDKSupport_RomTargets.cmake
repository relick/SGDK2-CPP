include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/SGDKSupport_Private.cmake")

# Create a ROM target using preferred SGDK library
function(md_add_rom target mdlib) # [sega_s]
  if(${ARGC} GREATER 3)
    message(FATAL_ERROR "Too many arguments for: md_add_rom(target mdlib [sega_s])")
  endif()
  set(sega_s ${ARGN})
  if(NOT sega_s)
    # Use default sega.s
    set(sega_s "${SGDK}/boot/sega.s")
  endif()

  # TODO: Make all the configuration options generate the config.h

  ## Create target using given name, linking with chosen mdlib.
  # This will generate the .elf and then finalise it into a .bin, although the setup for that is further below.
  # This target can be added to by the user, with sources, options, properties etc.
  add_executable(${target})
  target_link_libraries(${target} PUBLIC ${mdlib})

  SGDK_add_default_props(${target})
  target_compile_definitions(${target}
    PRIVATE
      ENABLE_BANK_SWITCH=$<TARGET_PROPERTY:SGDK_BANK_SWITCH>
      MODULE_MEGAWIFI=$<TARGET_PROPERTY:SGDK_MEGA_WIFI>
  )

  ## Set up the boot files
  # Create rom_head.c
  set(out_rom_head_dir "${CMAKE_CURRENT_BINARY_DIR}/SGDKFiles/${target}.rom_head")
  set(out_rom_head_c "${out_rom_head_dir}/rom_head.c")
  add_custom_command(
    OUTPUT ${out_rom_head_c}
    COMMAND "${CMAKE_COMMAND}"
      -D enable_bank_switch=$<TARGET_PROPERTY:${target},SGDK_BANK_SWITCH>
      -D enable_mega_wifi=$<TARGET_PROPERTY:${target},SGDK_MEGA_WIFI>
      -D copyright_release_date="$<TARGET_PROPERTY:${target},SGDK_HEAD_COPYRIGHT>"
      -D japan_title="$<TARGET_PROPERTY:${target},SGDK_HEAD_JPTITLE>"
      -D overseas_title="$<TARGET_PROPERTY:${target},SGDK_HEAD_OSTITLE>"
      -D serial_number="GM $<TARGET_PROPERTY:${target},SGDK_HEAD_SERIAL>-$<TARGET_PROPERTY:${target},SGDK_HEAD_REVISION>"
      -D device_support="$<TARGET_PROPERTY:${target},SGDK_HEAD_DEVICES>"
      -D rom_end_address=$<TARGET_PROPERTY:${target},SGDK_HEAD_ROM_END>
      -D extra_memory_sig="$<TARGET_PROPERTY:${target},SGDK_HEAD_EXTRA_MEM_SIG>"
      -D extra_memory_type=$<TARGET_PROPERTY:${target},SGDK_HEAD_EXTRA_MEM>
      -D extra_memory_start_address=$<TARGET_PROPERTY:${target},SGDK_HEAD_EXTRA_MEM_START>
      -D extra_memory_end_address=$<TARGET_PROPERTY:${target},SGDK_HEAD_EXTRA_MEM_END>
      -D region_support="$<TARGET_PROPERTY:${target},SGDK_HEAD_REGIONS>"
      -D ROM_HEAD_TEMPLATE=${SGDK}/boot/rom_head.c.in
      -D OUT_FILE=${out_rom_head_c}
      -P "${SGDK}/cmake/SGDKSupport_GenerateRomHead.cmake"
    DEPENDS "${SGDK}/boot/rom_head.c.in"
    VERBATIM
  )

  # Build rom_head.c into an object
  set(target_rom_head "${target}.rom_head")
  add_library(${target_rom_head} OBJECT ${out_rom_head_c})
  target_link_libraries(${target_rom_head} PRIVATE ${mdlib})

  # Generate rom_head.bin. Because sega.s will try to include "out/rom_head.bin", the bin
  # needs to be created within a folder called "out", and the root of that folder will be passed
  # as an include for building sega.s
  file(MAKE_DIRECTORY "${out_rom_head_dir}/out")
  set(out_rom_head_bin "${out_rom_head_dir}/out/rom_head.bin")
  add_custom_command(
    OUTPUT ${out_rom_head_bin}
    COMMAND ${OBJCPY_CMD} -O binary "$<TARGET_OBJECTS:${target_rom_head}>" "${out_rom_head_bin}"
    DEPENDS ${target_rom_head}
  )
  set(target_out_rom_head "${target}.out_rom_head")
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
  # We're *actually* building the .elf, but this allows us to tell CMake that the real executable is the bin
  set_target_properties(${target}
    PROPERTIES
      SUFFIX ".bin"
      LINK_DEPENDS ${SGDK_LINKER_SCRIPT}
  )
  target_link_options(${target}
    PRIVATE
      "LINKER:-n"
      -T${SGDK_LINKER_SCRIPT}
      "LINKER:--gc-sections"
       -flto
       -flto=auto
       -ffat-lto-objects
  )
  target_link_directories(${target}
    PRIVATE
      ${SGDK_LIB_DIRS}
  )

  # Final ROM generation: copy .elf file, objcopy, pad
  set(target_bin "$<TARGET_FILE:${target}>")
  set(target_out "${CMAKE_CURRENT_BINARY_DIR}/${target}.bin.elf")
  add_custom_command(TARGET ${target}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E rename ${target_bin} ${target_out}
    COMMAND ${OBJCPY_CMD} -O binary ${target_out} ${target_bin} &&
            ${SIZEBND_CMD} ${target_bin} -sizealign 131072 -checksum
    BYPRODUCTS ${target_out}
  )

endfunction()
