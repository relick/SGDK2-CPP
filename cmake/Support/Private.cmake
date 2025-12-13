include_guard(GLOBAL)

function(SGDK_extra_interface target extension)
  set(extra_target_var_name "target_${extension}")
  set(${extra_target_var_name} "${target}.${extension}")
  if(NOT TARGET ${${extra_target_var_name}})
    add_library(${${extra_target_var_name}} INTERFACE)
  endif()

  return(PROPAGATE ${extra_target_var_name})
endfunction()

macro(SGDK_extra_process_params prefix)
  set(header_scope_definition_count 0)
  if (${${prefix}_PUBLIC})
    math(EXPR header_scope_definition_count "${header_scope_definition_count} + 1")
    set(${prefix}_HEADER_SCOPE PUBLIC)
  endif()
  if (${${prefix}_PRIVATE})
    math(EXPR header_scope_definition_count "${header_scope_definition_count} + 1")
    set(${prefix}_HEADER_SCOPE PRIVATE)
  endif()
  if (${${prefix}_INTERFACE})
    math(EXPR header_scope_definition_count "${header_scope_definition_count} + 1")
    set(${prefix}_HEADER_SCOPE INTERFACE)
  endif()
  if(${header_scope_definition_count} EQUAL 0 OR ${header_scope_definition_count} GREATER 1)
    message(FATAL_ERROR "md_target_${prefix}_sources: Must set exactly one of PUBLIC/PRIVATE/INTERFACE for determining the scope of generated headers.")
  endif()

  if(DEFINED ${prefix}_BASE_DIRECTORY)
    cmake_path(ABSOLUTE_PATH ${prefix}_BASE_DIRECTORY BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" NORMALIZE)
  else()
    cmake_path(SET ${prefix}_BASE_DIRECTORY NORMALIZE "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  if(NOT DEFINED ${prefix}_PREFIX)
    set(${prefix}_PREFIX ${target})
  endif()

  set(${prefix}_SOURCE_FILES ${${prefix}_UNPARSED_ARGUMENTS})
endmacro()

function(SGDK_extra_out_dir target extension prefix)
  set(out_dir_var_name "${extension}_out_dir")
  cmake_path(APPEND ${out_dir_var_name} "${CMAKE_CURRENT_BINARY_DIR}" "SGDKFiles" "${target}.${extension}")
  cmake_path(ABSOLUTE_PATH prefix BASE_DIRECTORY "${${out_dir_var_name}}" NORMALIZE OUTPUT_VARIABLE prefix_out_dir)
  cmake_path(IS_PREFIX ${out_dir_var_name} ${prefix_out_dir} prefix_is_in_base_dir)
  if (prefix_is_in_base_dir)
    cmake_path(SET target_${out_dir_var_name} ${prefix_out_dir})
  else()
    message(WARNING "Unable to use prefix '${prefix}' as it is not (able to be) a child of '${${out_dir_var_name}}'")
    cmake_path(APPEND target_${out_dir_var_name} ${${out_dir_var_name}} ${target})
  endif()
  return(PROPAGATE ${out_dir_var_name} target_${out_dir_var_name})
endfunction()

function(SGDK_extra_out_interface target extension target_out_dir)
  set(extra_out_target_var_name "target_${extension}_out")
  set(${extra_out_target_var_name} "${target}.${extension}.out")
  if(NOT TARGET ${${extra_out_target_var_name}})
    add_library(${${extra_out_target_var_name}} INTERFACE)
  endif()

  target_include_directories(${${extra_out_target_var_name}}
    INTERFACE
      ${target_out_dir}
      # Upstream also includes src and res specifically
      $<$<BOOL:${SGDK_UPSTREAM_COMPATIBILITY}>:${target_out_dir}/src>
      $<$<BOOL:${SGDK_UPSTREAM_COMPATIBILITY}>:${target_out_dir}/res>
  )

  return(PROPAGATE ${extra_out_target_var_name})
endfunction()

function(SGDK_add_default_props target)
  set_target_properties(${target} PROPERTIES SGDK_BANK_SWITCH 0)
  set_target_properties(${target} PROPERTIES SGDK_EXT_EVERDRIVE 0)
  set_target_properties(${target} PROPERTIES SGDK_EXT_EVERDRIVE_FAT16 0)
  set_target_properties(${target} PROPERTIES SGDK_EXT_MEGAWIFI 0)
  set_target_properties(${target} PROPERTIES SGDK_EXT_MINIMUSIC 0)
  set_target_properties(${target} PROPERTIES SGDK_EXT_FLASHSAVE 0)
  set_target_properties(${target} PROPERTIES SGDK_EXT_CONSOLE 0)
  set_target_properties(${target} PROPERTIES SGDK_EXT_LINKCABLE 0)

  md_rom_title(${target} "SAMPLE PROGRAM")
  md_rom_serial_number(${target} "00000000")
  md_rom_revision(${target} 0)

  string(TIMESTAMP current_year "%Y")
  string(TIMESTAMP current_month "%b")
  string(TOUPPER ${current_month} current_month)
  md_rom_copyright(${target} "SGDK" ${current_month} ${current_year})

  md_rom_use_devices(${target} 3_BUTTON)

  md_rom_disable_extra_ram(${target})

  md_rom_region_all(${target})
endfunction()
