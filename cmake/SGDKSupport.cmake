cmake_minimum_required(VERSION 4.0.1)

# Rules to build Z80 source code
function(md_target_z80_sources target header_mode) # ARGN: .s80 files
  set(no_extra_includes)
  md_target_z80_sources_with_extra_includes(${target} no_extra_includes ${header_mode} ${ARGN})
endfunction()

# Extra includes should be passed as a list variable name
function(md_target_z80_sources_with_extra_includes target extra_includes_list_var header_mode) # ARGN: .s80 files
  set(z80_out_dir "${CMAKE_CURRENT_BINARY_DIR}/Intermediates/${target}.z80")

  set(target_includes "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>,PREPEND,-i>")
  set(extra_includes_list ${${extra_includes_list_var}})
  set(extra_includes $<LIST:TRANSFORM,${${extra_includes_list_var}},PREPEND,-i>) # Not in quotes, to prevent list being expanded with spaces
  
  set(processed_src)
  set(processed_headers)
  foreach(z80_source IN ITEMS ${ARGN})
    # message("Generating z80->m68k command for ${z80_source}...")
    cmake_path(RELATIVE_PATH z80_source BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" OUTPUT_VARIABLE z80_relative_source)
    cmake_path(REMOVE_EXTENSION z80_relative_source OUTPUT_VARIABLE z80_relative_stem)
    set(out_stem "${z80_out_dir}/${z80_relative_stem}")
    set(m68k_asm "${out_stem}.s")
    set(c_header "${out_stem}.h")
    set(z80_bin "${out_stem}.o80")
    # message("Building to ${m68k_asm}")

    add_custom_command(
      OUTPUT ${m68k_asm} ${c_header}
      COMMAND ${ASMZ80_CMD} ${target_includes} "${extra_includes}" "${z80_source}" ${z80_bin} &&
              ${BINTOS_CMD} ${z80_bin} ${m68k_asm}
      COMMAND_EXPAND_LISTS
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      VERBATIM
      DEPENDS "${z80_source}" bintos sjasm
      BYPRODUCTS ${z80_bin}
    )

    list(APPEND processed_src ${m68k_asm})
    list(APPEND processed_headers ${c_header})
  endforeach()

  target_sources(${target} PRIVATE ${processed_src})
  target_sources(${target}
    ${header_mode}
    FILE_SET z80_headers TYPE HEADERS BASE_DIRS ${z80_out_dir} FILES
      ${processed_headers}
  )

endfunction()

# Rules to build resources
function(md_target_res_sources target header_mode) # ARGN: .res files
  set(res_out_dir "${CMAKE_CURRENT_BINARY_DIR}/Intermediates/${target}.res")

  set(processed_src)
  set(processed_headers)
  foreach(res_source IN ITEMS ${ARGN})
    # message("Generating res->m68k command for ${res_source}...")
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
      DEPENDS "${res_source}" xgmtool
      BYPRODUCTS ${dep_file}
    )

    list(APPEND processed_src ${m68k_asm})
    list(APPEND processed_headers ${c_header})
  endforeach()

  target_sources(${target} PRIVATE ${processed_src})
  target_sources(${target}
    ${header_mode}
    FILE_SET res_headers TYPE HEADERS BASE_DIRS ${res_out_dir} FILES
      ${processed_headers}
  )

endfunction()
