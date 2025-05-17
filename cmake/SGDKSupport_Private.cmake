include_guard(GLOBAL)

function(SGDK_ext_interface target extension)
  set(extra_target_var_name "target_${extension}")
  set(${extra_target_var_name} "${target}.${extension}")
  if(NOT TARGET ${${extra_target_var_name}})
    add_library(${${extra_target_var_name}} INTERFACE)
  endif()

  return(PROPAGATE ${extra_target_var_name})
endfunction()

function(SGDK_ext_out_dir target extension)
  set(out_dir_var_name "${extension}_out_dir")
  set(${out_dir_var_name} "${CMAKE_CURRENT_BINARY_DIR}/SGDKFiles/${target}.${extension}")
  return(PROPAGATE ${out_dir_var_name})
endfunction()

function(SGDK_add_default_props target)
  set_target_properties(${target} PROPERTIES SGDK_BANK_SWITCH 0)
  set_target_properties(${target} PROPERTIES SGDK_MEGA_WIFI 0)

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
