include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/SGDKSupport_Private.cmake")

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
