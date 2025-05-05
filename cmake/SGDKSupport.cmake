cmake_minimum_required(VERSION 4.0.1)

# Rules to build Z80 source code
function(md_target_z80_sources target header_mode) # ARGN: .s80 files
  md_target_z80_sources_with_inc(${target} ${target} ${header_mode} ${ARGN})
endfunction()

function(md_target_z80_sources_with_inc target inc_target header_mode) # ARGN: .s80 files
  set(z80_out_dir "${CMAKE_CURRENT_BINARY_DIR}/Intermediates/${target}.z80")

  set(processed_src)
  set(processed_headers)
  foreach(z80_source IN ITEMS ${ARGN})
    # message("Generating z80->m68k command for ${z80_source}...")
    cmake_path(RELATIVE_PATH z80_source BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" OUTPUT_VARIABLE z80_relative_source)
    cmake_path(REMOVE_EXTENSION z80_relative_source OUTPUT_VARIABLE z80_relative_stem)
    set(out_stem ${z80_out_dir}/${z80_relative_stem})
    set(m68k_asm ${out_stem}.s)
    set(c_header ${out_stem}.h)
    set(z80_bin ${out_stem}.o80)
    # message("Building to ${m68k_asm}")

    set(target_includes "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>,PREPEND,-i>")
    set(inc_target_includes "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${inc_target},INCLUDE_DIRECTORIES>,PREPEND,-i>")
    set(use_inc_target_includes "$<NOT:$<STREQUAL:${target},${inctarget}>>")
    add_custom_command(
      OUTPUT ${m68k_asm} ${c_header}
      COMMAND ${ASMZ80_CMD} ${target_includes} $<${use_inc_target_includes}:${inc_target_includes}> ${z80_source} ${z80_bin} &&
              ${BINTOS_CMD} ${z80_bin} ${m68k_asm}
      COMMAND_EXPAND_LISTS
      VERBATIM
      DEPENDS ${z80_source} bintos sjasm
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
    set(out_stem ${res_out_dir}/${res_relative_stem})
    set(m68k_asm ${out_stem}.s)
    set(c_header ${out_stem}.h)
    set(dep_file ${out_stem}.d)
    # message("Building to ${m68k_asm}")

    add_custom_command(
      OUTPUT ${m68k_asm} ${c_header}
      DEPFILE ${dep_file}
      COMMAND ${RESCOMP_CMD} ${res_source} ${m68k_asm} -dep ${dep_file}
      DEPENDS ${res_source} xgmtool
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
