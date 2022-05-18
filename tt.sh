#!/usr/bin/bash
# Michal Žejdl, 2022
# takes a directory as an argument and makes a markdown table with statistics
#	of its .po files
# viewable at https://markdownlivepreview.com/

dir=$1

# preserve numbers read in pipe
shopt -s lastpipe

function f_usage
{
	echo "usage: $(basename "$0") <directory with .po files>" >&2
	exit 1
}

function f_parse_msgfmt-stats
{
	local total
	local second
	local s_selector
	local third
	local t_selector
	local fuzzy=0
	local untranslated=0

	# s_selector and t_selector can be "fuzzy" or "untranslated"
	read -r total _ _ second s_selector _ third t_selector _

	if test -n "$second"
	then
		printf -v "$s_selector" %d "$second"
		
		test -n "$third" && printf -v "$t_selector" %d "$third"
	fi

	echo "$total $fuzzy $untranslated"
}

test $# -eq 1 || f_usage

if test ! -d "$dir"
then
	echo "$dir is not a directory" >&2
	f_usage
fi

cd "$dir" || exit

echo "# Translations"

echo "## Statistics"

echo "File | Messages | Translated | Translated% | Fuzzy | Untranslated"
echo "--- | --: | --: | --: | --: | --:"

for file in *.po
do
	LANG=C msgfmt -o /dev/null --statistics "$file" 2>&1 \
		| f_parse_msgfmt-stats \
		| read -r -a numbers

	trans=${numbers[0]}
	fuzzy=${numbers[1]}
	untrans=${numbers[2]}

	all=$((trans + fuzzy + untrans))
	percent=$((trans * 100 / all))

	# avoid trash
	#test "$percent" -gt 5 || continue

	((count++))

	((total_all+=all))
	((total_trans+=trans))
	((total_fuzzy+=fuzzy))
	((total_untrans+=untrans))

	echo "$file | $all | $trans| $percent% | $fuzzy | $untrans"
done

percent=$((total_trans * 100 / total_all))

echo "## Totals"

echo "Files | Messages | Translated | Translated% | Fuzzy | Untranslated"
echo "--: | --: | --: | --: | --: | --:"
echo "$count | $total_all | $total_trans | $percent% | $total_fuzzy | $total_untrans"
