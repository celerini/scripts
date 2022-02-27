#!/usr/bin/bash
# Michal Žejdl, 2022
# transfer translations of common messages from src file to dst file

src=$1
dst=$2
pot=$3

function f_usage
{
	echo "usage: $(basename "$0") <src.po> <dst.po> <dst.pot>" >&2

	exit 1
}

function f_print_stats
{
	local file=$1

	echo
	echo "$*"
	msgfmt -o /dev/null --statistics "$file"
}

for file in src dst pot
do
	test -f "${!file}" || f_usage
done

msgcomm=$(mktemp) || exit
msgcat=$(mktemp) || exit

f_print_stats "$src" "- source file"
f_print_stats "$dst" "- destination file"

# msgcomm
#	- takes headers and translations for common messages from src
#	- uses obsolete messages (#~) too
msgcomm "$src" "$dst" >"$msgcomm" || exit

f_print_stats "$msgcomm" "- common messages"

# merge common translated messages with dst
#	- thanks to --use-first uses all translations from msgcomm on dst
msgcat --use-first "$msgcomm" "$dst" >"$msgcat" || exit

f_print_stats "$msgcat" "- common messages merged with destination file"

# repairs msgcat and makes it the new dst
#	- removes locations taken from src
#	- removes obsolete messages added as normal messages by msgcomm
msgmerge --previous "$msgcat" "$pot" >"$dst" || exit

f_print_stats "$dst" "- destination file repaired by msgmerge"

echo

rm "$msgcomm" "$msgcat"
