include_guard(GLOBAL)

include("${SGDK_CMAKE_SUPPORT}/Private.cmake")

## Config
function(md_rom_enable_bank_switch target)
  set_target_properties(${target} PROPERTIES SGDK_BANK_SWITCH 1)
endfunction()

function(md_rom_enable_mega_wifi target)
  set_target_properties(${target} PROPERTIES SGDK_MEGA_WIFI 1)
endfunction()

## Titles
function(md_rom_title target title) # [jp_title]
  if(${ARGC} GREATER 3)
    message(FATAL_ERROR "Too many arguments for: md_rom_set_title(target title [jp_title])")
  endif()
  set(jp_title ${ARGN})
  if(NOT jp_title)
    # Use same title for both
    set(jp_title ${title})
  endif()

  string(LENGTH ${title} title_len)
  if(${title_len} GREATER 48)
    message(FATAL_ERROR "Title must be up to 48 characters")
  endif()
  math(EXPR pad_len "48 - ${title_len}")
  string(REPEAT " " ${pad_len} padding)
  string(CONCAT padded_title ${title} ${padding})

  set_target_properties(${target} PROPERTIES SGDK_HEAD_OSTITLE ${padded_title})
  
  string(LENGTH ${jp_title} title_len)
  if(${title_len} GREATER 48)
    message(FATAL_ERROR "JP title must be up to 48 characters")
  endif()
  math(EXPR pad_len "48 - ${title_len}")
  string(REPEAT " " ${pad_len} padding)
  string(CONCAT padded_title ${jp_title} ${padding})

  set_target_properties(${target} PROPERTIES SGDK_HEAD_JPTITLE ${padded_title})
endfunction()

## Release metadata
function(md_rom_copyright target copyright month year)
  string(LENGTH ${copyright} len)
  if(NOT len EQUAL 4)
    message(FATAL_ERROR "Copyright name must be exactly 4 characters.")
  endif()
  string(TOUPPER ${copyright} upper_copyright)

  string(LENGTH ${month} month_len)
  if(NOT month_len GREATER_EQUAL 3)
    message(FATAL_ERROR "Release month must be at least 3 characters.")
  endif()
  string(SUBSTRING ${month} 0 3 month_sub)
  string(TOUPPER ${month_sub} upper_month)

  string(LENGTH ${year} year_len)
  if(NOT year_len EQUAL 4)
    message(FATAL_ERROR "Release year must be exactly 4 digits.")
  endif()

  set_target_properties(${target} PROPERTIES SGDK_HEAD_COPYRIGHT "(C)${upper_copyright} ${year}.${upper_month}")
endfunction()

function(md_rom_serial_number target serial)
  string(LENGTH ${serial} len)
  if(NOT len EQUAL 8)
    message(FATAL_ERROR "Serial number must be exactly 8 characters.")
  endif()

  set_target_properties(${target} PROPERTIES SGDK_HEAD_SERIAL ${serial})
endfunction()

function(md_rom_revision target revision)
  if(revision LESS 0 OR revision GREATER 99)
    message(FATAL_ERROR "Revision must be between 0 and 99")
  endif()
  if(revision LESS 10)
    set_target_properties(${target} PROPERTIES SGDK_HEAD_REVISION 0${revision})
  else()
    set_target_properties(${target} PROPERTIES SGDK_HEAD_REVISION ${revision})
  endif()
endfunction()

## Devices
function(md_rom_use_devices target) # [ARGN]
  list(APPEND md_devices
    3_BUTTON
    6_BUTTON
    # TODO: other devices
  )
  
  # Extract the devices to a real list
  set(target_devices)
  foreach(device IN ITEMS ${ARGN})
    if(NOT ${device} IN_LIST md_devices)
      message(FATAL_ERROR "Unknown device: ${device}. Valid devices are '${md_devices}'")
    endif()
    list(APPEND target_devices ${device})
  endforeach()

  set(devices_str "")
  set(pad_len 16)

  macro(SGDK_concat_device device letter)
    if(${device} IN_LIST target_devices)
      string(CONCAT devices_str ${devices_str} ${letter})
      math(EXPR pad_len "${pad_len} - 1")
    endif()
  endmacro()

  SGDK_concat_device(3_BUTTON "J")
  SGDK_concat_device(6_BUTTON "6")

  string(REPEAT " " ${pad_len} padding)
  string(CONCAT padded_devices ${devices_str} ${padding})

  set_target_properties(${target} PROPERTIES SGDK_HEAD_DEVICES ${padded_devices})
endfunction()

## Regions
function(md_rom_region_all target)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_REGIONS "JUE")
endfunction()

function(md_rom_region_pal_only target)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_REGIONS "  E")
endfunction()

function(md_rom_region_ntsc_only target)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_REGIONS "JU ")
endfunction()

function(md_rom_region_japan_only target)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_REGIONS "J  ")
endfunction()

function(md_rom_region_overseas_only target)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_REGIONS " UE")
endfunction()

function(md_rom_region_americas_only target)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_REGIONS " U ")
endfunction()

function(md_rom_region_europe_only target)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_REGIONS "  E")
endfunction()

## Extra RAM
function(md_rom_enable_sram target saving_type access_type)
  set(type_str "ExtRAMType_SRAM")

  if(${saving_type} STREQUAL "SAVING")
    string(CONCAT type_str ${type_str} "|SRAMFlag_Saving")
  elseif(${saving_type} STREQUAL "NO_SAVING")
    string(CONCAT type_str ${type_str} "|SRAMFlag_NoSaving")
  else()
    message(FATAL_ERROR "Only 'SAVING' 'NO_SAVING' are allowed values for SRAM saving type")
  endif()
  if(${access_type} STREQUAL "16")
    string(CONCAT type_str ${type_str} "|SRAMFlag_16Bit")
  elseif(${access_type} STREQUAL "ODD_8")
    string(CONCAT type_str ${type_str} "|SRAMFlag_8BitOdd")
  elseif(${access_type} STREQUAL "EVEN_8")
    string(CONCAT type_str ${type_str} "|SRAMFlag_8BitEven")
  else()
    message(FATAL_ERROR "Only '16' 'ODD_8' 'EVEN_8' are allowed values for SRAM access type")
  endif()

  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM_SIG "RA")
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM ${type_str})
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM_START 0x00200000)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM_END 0x0020FFFF)
endfunction()

function(md_rom_enable_eeprom target start_addr end_addr)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM_SIG "RA")
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM ExtRAMType_EEPROM)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM_START start_addr)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM_END end_addr)
endfunction()

function(md_rom_disable_extra_ram target)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM_SIG "  ")
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM ExtRAMType_None)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM_START 0x00200000)
  set_target_properties(${target} PROPERTIES SGDK_HEAD_EXTRA_MEM_END 0x0020FFFF)
endfunction()

