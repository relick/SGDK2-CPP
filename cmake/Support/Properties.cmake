include_guard(GLOBAL)

include("${SGDK_CMAKE_SUPPORT}/Private.cmake")

set(SGDK_ALL_PROPERTIES
  # rom lib targets
  SGDK_IS_MDLIB
  SGDK_IS_MDLIB_WITH_NEWLIB
  SGDK_IS_MDLIB_WITH_CPP

  # configuration targets
  SGDK_ENABLE_AUTO_BANK_SWITCH
  SGDK_AUTO_BANK_SWITCH # Used to prevent adding on/off at the same time

  # extra lib targets
  SGDK_EXT_EVERDRIVE
  SGDK_EXT_MEGAWIFI
)

foreach(property IN LISTS SGDK_ALL_PROPERTIES)
  define_property(TARGET PROPERTY ${property})
endforeach()

macro(SGDK_export_properties_on_target target)
  foreach(property IN LISTS SGDK_ALL_PROPERTIES)
    set_property(TARGET ${target} APPEND PROPERTY EXPORT_PROPERTIES ${property})
  endforeach()
endmacro()

macro(SGDK_set_exportable_INTERFACE_property target property value)
  set_target_properties(${target} PROPERTIES INTERFACE_${property} ${value})
  
  # Need to do this to make CMake actually export the property:
  set_property(TARGET ${target} APPEND PROPERTY COMPATIBLE_INTERFACE_BOOL ${property})
endmacro()
