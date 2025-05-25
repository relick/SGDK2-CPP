## Generate the rom_head.c file
# In a separate script to allow use with add_custom_command

## This script does no preparation itself, all the following variables
## must be set and correctly formatted:
# enable_bank_switch
# enable_mega_wifi
# copyright_release_date
# japan_title
# overseas_title
# serial_number
# device_support
# extra_memory_sig
# extra_memory_type
# extra_memory_start_address
# extra_memory_end_address
# region_support

## Generate rom_head.c
configure_file(${ROM_HEAD_TEMPLATE} ${OUT_FILE} @ONLY)
