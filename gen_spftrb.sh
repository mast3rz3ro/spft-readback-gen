#!/bin/env bash

# Written by: mast3rz3ro
# Description: Generates readback_ui_bak.xml to use in SP-Flash-Tool
# Source: https://github.com/mast3rz3ro/spft-readback-gen
# Date: 07-05-2024


xml_head (){
	printf "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<flashtool-config version=\"2.0\">\n">"$project".xml
	printf "\t<general>\n\t\t<chip-name>$platform</chip-name>\n\t\t<storage-type>$storage</storage-type>\n\t</general>\n\t<commands>\n\t\t<readback>\n">>"$project".xml
	printf "\t\t\t<physical-readback is-physical-readback=\"false\" />\n\t\t\t<readback-list>\n">>"$project".xml
}

xml_item (){
	printf "\t\t\t\t<readback-rom-item readback-index=\"$index\" readback-enable=\"true\" readback-flag=\"NUTL_READ_PAGE_ONLY\" start-address=\"$str_add\" readback-length=\"$len_add\" addr-flag=\"NUTL_ADDR_LOGICAL\" part-id=\"8\">$part_name.bin</readback-rom-item>\n">>"$project".xml
}

xml_end (){
	printf "\t\t\t</readback-list>\n\t\t</readback>\n\t</commands>\n</flashtool-config>\n">>"$project".xml
}

count_item (){
	index="0"
for x in $items; do
	((index++))
done
}

if [ "$1" = '' ]; then
	printf -- "- Written by: mast3rz3ro (c) 2024\n- Description: Generates readback_ui_bak.xml to use in SP-Flash-Tool\n- Source: https://github.com/mast3rz3ro/spft-readback-gen\n"
	printf -- "- Usage: gen_spftrb.sh scatter.txt\n   Example: ./gen_spftrb.sh MT6750_Android_scatter.txt\n   For verbose mode use -v\n"
	exit 1
elif [ "$1" = '-v' ]; then
	verbose='yes'
	scatter="$2"
elif [ "$2" = '-v' ]; then
	verbose='yes'
	scatter="$1"
else
	scatter="$1"
fi


if [ -s "$scatter" ]; then

		printf -- "-- Reading scatter hw_info ...\n"
	project=$(grep "project:" "$scatter" | awk -F ':' '{print $2}' | sed 's/ //')
	platform=$(grep "platform:" "$scatter" | awk -F ':' '{print $2}' | sed 's/ //')
	storage=$(grep "storage:" "$scatter" | sed -n 1p | awk -F ':' '{print $2}' | sed 's/ //')
	
	printf -- "-- Reading partitions names ...\n"
	parts_name=$(grep "partition_name:" "$scatter" | awk -F ':' '{print $2}' | sed 's/ //')
	parts_str=$(grep "physical_start_addr:" "$scatter" | awk -F ':' '{print $2}' | sed 's/ //')
	parts_end=$(grep "partition_size:" "$scatter" | awk -F ':' '{print $2}' | sed 's/ //')

		printf -- "-- Validating the scatter file ...\n"
		# all must hold same count !
	items="$parts_name"; count_item # call function
	parts_count="$index"
	items="$parts_str"; count_item # call function
	stradd_count="$index"
	items="$parts_end"; count_item # call function
	endadd_count="$index"
	if [ "$parts_count" != "$stradd_count" ] || [ "$parts_count" != "$endadd_count" ]; then
		err_array='yes'
	elif [ "$stradd_count" != "$parts_count" ] || [ "$stradd_count" != "$endadd_count" ]; then
		err_array='yes'
	elif [ "$endadd_count" != "$parts_count" ] || [ "$endadd_count" != "$stradd_count" ]; then
		err_array='yes'
	fi
	if [ "$err_array" = 'yes' ]; then
		printf -- "-- Error the array has a incorrect order !\n    Please report this issue by providing your scatter file."
		exit 1
	fi

	printf -- "-- Generating xml_head ...\n"
	xml_head # call function

	printf -- "-- Generating xml_item ...\n"
	index="0"
	set $parts_str $parts_end
for i in $parts_name; do
	part_name="$i"
	str_add="$1"
	len_add="$2"
if [ "$part_name" != '' ] && [ "$part_name" != 'preloader' ]; then
		xml_item # call function
		((index++)) # increase index
	elif [ "$part_name" = 'preloader' ]; then # preloader are ignored since it's stored in different storage
		if [ "$verbose" = 'yes' ]; then printf '    Skipping preloader partition ..\n'; fi
	else
		printf -- "-- A unexpected error has ocurred while trying to read item.\n    Please report this issue by providing your scatter file."
		exit 1
fi
	#verbose
	if [ "$verbose" = 'yes' ]; then printf "    partition_name: $part_name --- physical_start_addr: $str_add --- partition_size: $len_add\n"; fi
	shift
done

	printf -- "-- Generating xml_end ...\n"
	xml_end # call function

	printf -- "-- Wrote into: $project.xml"

else
	printf -- '-- Error the passed file are empty or none exist !'
	exit 1
fi