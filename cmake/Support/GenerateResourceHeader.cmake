if (SGDK_UPSTREAM_COMPATIBILITY)
	# Use generated header as-is
	file(RENAME ${IN_FILE} ${OUT_FILE})
else()
	# Insert SGDK/ to the include
	file(READ ${IN_FILE} old_header_contents)
	string(REPLACE
		<genesis.h>
		<SGDK/genesis.h>
		new_header_contents
		"${old_header_contents}"
	)
	file(WRITE ${OUT_FILE} "${new_header_contents}")
	file(REMOVE ${IN_FILE})
endif()
