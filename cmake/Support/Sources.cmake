include_guard(GLOBAL)

include("${SGDK_CMAKE_SUPPORT}/Private.cmake")

# Rules to build z80 source code
function(md_target_z80_include_directories target) # ARGN: include directories only used for .s80 files
  SGDK_extra_interface(${target} z80_includes) # sets target_z80_includes
  target_include_directories(${target_z80_includes} INTERFACE ${ARGN})
endfunction()

function(md_target_z80_sources target) # ARGN: [PUBLIC/PRIVATE/INTERFACE] [BASE_DIRECTORY base_dir] [PREFIX prefix] [PREFIX_OPTIONAL_FOR_TARGET] [.s80 files]
  SGDK_extra_interface(${target} z80_includes) # sets target_z80_includes

  # Sets z80_PUBLIC, etc...
  set(arg_options PUBLIC PRIVATE INTERFACE PREFIX_OPTIONAL_FOR_TARGET)
  set(arg_values BASE_DIRECTORY PREFIX)
  cmake_parse_arguments(PARSE_ARGV 1 z80 "${arg_options}" "${arg_values}" "")
  # Normalises the arguments and sets defaults, including setting z80_HEADER_SCOPE and z80_SOURCE_FILES
  SGDK_extra_process_params(z80)

  SGDK_extra_out_dir(${target} z80 ${z80_PREFIX}) # sets z80_out_dir and target_z80_out_dir

  set(target_includes "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>,PREPEND,-i>")
  set(extra_target_includes "$<LIST:TRANSFORM,$<TARGET_PROPERTY:${target_z80_includes},INTERFACE_INCLUDE_DIRECTORIES>,PREPEND,-i>")
  
  set(processed_src)
  set(processed_headers)
  foreach(z80_source IN ITEMS ${z80_SOURCE_FILES})
    # message("Generating z80->m68k command for ${z80_source}...")
    cmake_path(ABSOLUTE_PATH z80_source BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" NORMALIZE)
    cmake_path(IS_PREFIX z80_BASE_DIRECTORY ${z80_source} source_is_in_base_dir)
    if (NOT source_is_in_base_dir)
      message(FATAL_ERROR "Z80 source file '${z80_source}' does not belong to base directory '${z80_BASE_DIRECTORY}'")
    endif()
    cmake_path(RELATIVE_PATH z80_source BASE_DIRECTORY "${z80_BASE_DIRECTORY}" OUTPUT_VARIABLE z80_relative_source)
    cmake_path(REMOVE_EXTENSION z80_relative_source OUTPUT_VARIABLE z80_relative_stem)
    set(out_stem "${target_z80_out_dir}/${z80_relative_stem}")
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
    ${z80_HEADER_SCOPE}
    FILE_SET z80_headers TYPE HEADERS BASE_DIRS ${z80_out_dir} FILES
      ${processed_headers}
  )

  # Set up the private include target for non-prefixed access to the headers by the target
  if (${z80_PREFIX_OPTIONAL_FOR_TARGET} OR ${SGDK_UPSTREAM_COMPATIBILITY})
    SGDK_extra_out_interface(${target} z80 ${target_z80_out_dir}) # sets target_z80_out
    target_link_libraries(${target} PUBLIC $<BUILD_LOCAL_INTERFACE:${target_z80_out}>)
  endif()
endfunction()

# Rules to build resources
function(md_target_resources target header_scope) # ARGN: [BASE_DIRECTORY base_dir] [PREFIX prefix] [PREFIX_OPTIONAL_FOR_TARGET] [.res files]
  # Sets res_PUBLIC, etc...
  set(arg_options PUBLIC PRIVATE INTERFACE PREFIX_OPTIONAL_FOR_TARGET)
  set(arg_values BASE_DIRECTORY PREFIX)
  cmake_parse_arguments(PARSE_ARGV 1 res "${arg_options}" "${arg_values}" "")
  # Normalises the arguments and sets defaults, including setting res_HEADER_SCOPE and res_SOURCE_FILES
  SGDK_extra_process_params(res)

  SGDK_extra_out_dir(${target} res ${res_PREFIX}) # sets res_out_dir, and target_res_out_dir

  set(processed_src)
  set(processed_headers)
  foreach(res_source IN ITEMS ${res_SOURCE_FILES})
    # message("Generating res->m68k command for ${res_source}...")
    cmake_path(ABSOLUTE_PATH res_source BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" NORMALIZE)
    cmake_path(IS_PREFIX res_BASE_DIRECTORY ${res_source} source_is_in_base_dir)
    if (NOT source_is_in_base_dir)
      message(FATAL_ERROR "Resource file '${res_source}' does not belong to base directory '${res_BASE_DIRECTORY}'")
    endif()
    cmake_path(RELATIVE_PATH res_source BASE_DIRECTORY "${res_BASE_DIRECTORY}" OUTPUT_VARIABLE res_relative_source)
    cmake_path(REMOVE_EXTENSION res_relative_source OUTPUT_VARIABLE res_relative_stem)
    set(out_stem "${target_res_out_dir}/${res_relative_stem}")
    set(m68k_asm "${out_stem}.s")
    set(c_header "${out_stem}.h")
    set(dep_file "${out_stem}.d")
    # message("Building to ${m68k_asm}")

    add_custom_command(
      OUTPUT ${m68k_asm} ${c_header}
      DEPFILE ${dep_file}
      COMMAND ${RESCOMP_CMD} "${res_source}" ${m68k_asm} -dep ${dep_file}
      COMMAND ${CMAKE_COMMAND} -E rename ${c_header} ${c_header}.tmp
      COMMAND "${CMAKE_COMMAND}"
      -D IN_FILE=${c_header}.tmp
      -D OUT_FILE=${c_header}
      -D SGDK_UPSTREAM_COMPATIBILITY=${SGDK_UPSTREAM_COMPATIBILITY}
      -P "${SGDK_CMAKE_SUPPORT}/GenerateResourceHeader.cmake"
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
    ${res_HEADER_SCOPE}
    FILE_SET res_headers TYPE HEADERS BASE_DIRS ${res_out_dir} FILES
      ${processed_headers}
  )

  # Set up the private include target for non-prefixed access to the headers by the target
  if (${res_PREFIX_OPTIONAL_FOR_TARGET} OR ${SGDK_UPSTREAM_COMPATIBILITY})
    SGDK_extra_out_interface(${target} res ${target_res_out_dir}) # sets target_res_out
    target_link_libraries(${target} PUBLIC $<BUILD_LOCAL_INTERFACE:${target_res_out}>)
  endif()
endfunction()
