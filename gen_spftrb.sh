#!/bin/env bash

# Written by: mast3rz3ro
# Description: Generates readback_ui_bak.xml to use in SP-Flash-Tool
# License: BSD-3-Clause
# Source: https://github.com/mast3rz3ro/spft-readback-gen
# Release date: 07-05-2024
# Last update: 06-01-2025


_usage()
{

	msg="\
Usage: gen_spftrb.sh -i scatter.txt
Note: windows path delimiter are the default one.

  Parameters:
	-i, input file (e.g scatter.txt)
	-o, output file (e.g new.xml)
	-w, use windows path delimiter: '\'.
	-n, use unix path delimiter: '/'.
	-v, Enable verbose mode."

	echo -e "$msg"
	exit 1

}

_config()
{

	while getopts i:o:wnv option
		do
			case "$option"
		in
			i) scatter="${OPTARG}";;
			o) output="${OPTARG}";;
			w) slash='\\';;
			n) slash='/';;
			v) verbose='yes';;
			?) _usage
		esac
	done
			[ -z "$slash" ] && slash='\\'
		if [ -f "$scatter" ] && [ -s "$scatter" ]; then
			_read_scatter; _validate; _xml_head; _xml_item; _xml_end
		else
			echo '-- Error the passed file are empty or none exist !'
			return 1
		fi
	
}


_xml_head()
{

	echo -e "-- Generating xml_head..."
	echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<flashtool-config version=\"2.0\">\n">"$output"
	echo -e "\t<general>\n\t\t<chip-name>$platform</chip-name>\n\t\t<storage-type>$storage</storage-type>\n\t</general>\n\t<commands>\n\t\t<readback>\n">>"$output"
	echo -e "\t\t\t<physical-readback is-physical-readback=\"false\" />\n\t\t\t<readback-list>\n">>"$output"

}

_xml_item()
{

		echo "-- Generating xml_item..."
	_add_item()
		{
			echo -ne "\t\t\t\t<readback-rom-item readback-index=\"$index\" readback-enable=\"true\" readback-flag=\"NUTL_READ_PAGE_ONLY\" start-address=\"$str_add\" readback-length=\"$len_add\" addr-flag=\"NUTL_ADDR_LOGICAL\" part-id=\"8\">$out_add</readback-rom-item>\n">>"$output"
		}

	index="0"
for i in "${parts_name[@]}"; do
		part_name="$i"
		str_add="${parts_str[$index]}"
		len_add="${parts_end[$index]}"
		out_add="${project}${slash}${part_name}.bin"
	if [ -n "$part_name" ] && [ "$part_name" != 'preloader' ]; then
		_add_item
	elif [ "$part_name" = 'preloader' ]; then # preloader are ignored since it's stored in different storage
		[ "$verbose" = 'yes' ] && echo '    Skipping preloader partition...'
	else
		echo -e "-- An unexpected error has ocurred while trying to read item.\n    Please report this issue by providing your scatter file."
		exit 1
	fi
		((index++)); shift
		[ "$verbose" = 'yes' ] && echo "    partition_name: $part_name --- physical_start_addr: $str_add --- partition_size: $len_add"
done

}

_xml_end()
{

	echo "-- Generating xml_end..."
	echo -e "\t\t\t</readback-list>\n\t\t</readback>\n\t</commands>\n</flashtool-config>\n">>"$output"
	echo "-- Wrote into: $output"

}

_count_item (){
	index="0"
for x in $items; do
	((index++))
done
}

_validate()
{

	echo "-- Validating the scatter file..."
		# all must hold same count !
	items="${parts_name[@]}"; _count_item
	parts_count="$index"
	items="${parts_str[@]}"; _count_item
	stradd_count="$index"
	items="${parts_end[@]}"; _count_item
	endadd_count="$index"
		[ "$verbose" = 'yes' ] && { echo "    parts_count: $parts_count -- stradd_count: $stradd_count -- endadd_count: $endadd_count"; }
	if [ "$parts_count" != "$stradd_count" ] || [ "$parts_count" != "$endadd_count" ]; then
		err_array='yes'
	elif [ "$stradd_count" != "$parts_count" ] || [ "$stradd_count" != "$endadd_count" ]; then
		err_array='yes'
	elif [ "$endadd_count" != "$parts_count" ] || [ "$endadd_count" != "$stradd_count" ]; then
		err_array='yes'
	fi
		[ "$err_array" = 'yes' ] && { echo -e "-- Error the array has a incorrect order !\n    Please report this issue by providing your scatter file."; exit 1; }

}

_read_scatter()
{

	echo "-- Reading scatter hw_info..."
	project=$(grep "project:" "$scatter" | awk -F ':' '{print $2}' | sed 's/ //')
	platform=$(grep "platform:" "$scatter" | awk -F ':' '{print $2}' | sed 's/ //')
	storage=$(grep "storage:" "$scatter" | sed -n 1p | awk -F ':' '{print $2}' | sed 's/ //')
		[ -z "$output" ] && output="${project}.xml"
	
	echo "-- Reading partitions names..."
	parts_name=($(grep "partition_name:" "$scatter" | awk -F ':' '{print $2}' | sed 's/ //'))
	parts_str=($(grep "physical_start_addr:" "$scatter" | awk -F ':' '{print $2}' | sed 's/ //'))
	parts_end=($(grep "partition_size:" "$scatter" | awk -F ':' '{print $2}' | sed 's/ //'))

}

_config "$@"
