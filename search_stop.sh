stop_file=zones-d-arrets.csv
[[ -r $stop_file ]] || {echo "File $stop_file does not exist or is not readable" && exit 5}
stop_file=$(cat $stop_file | sed s'/;/ (/' |  sed s'/;/ ; /g' | sed s'/.$/)/g' | sed s'/^/--> /g')

function get_stop() 
{
	echo -n "\033[4mDeparture stop:\033[m "
	read input
	input=$(echo $input | tr "ÄäÂâÀà" "a" |tr "ÈèÉéËëÊê" "e" | tr "ÏïÎî" "i" | tr "ÖöÔô" "o" | tr "ÜüÛû" "u" | tr "Çç" "c" | tr "[A-Z]" "[a-z]")
	res=$(echo $stop_file | grep "$input")
	[[ $(echo $res | wc -l) -eq 1 && $(echo $res | wc -c) -gt 2 ]] && stop=`echo $res | cut -d' ' -f2` && return
	[[ $(echo $res | wc -c) -eq 1 ]] && echo "No entry for $input (CTRL+C to quit)" && get_stop
	[[ $(echo $res | wc -l) -gt 1 ]] && echo "\n\033[1mMultiple entries found for \"$input\" (be more precise):\033[m\n$(echo $res)\n" && get_stop
} 

# get_stop as main:
#set stop
#get_stop 
#echo $stop

line_file=referentiel-des-lignes.csv
[[ -r $line_file ]] || {echo "File $line_file does not exist or is not readable" && exit 6}
line_clean=$(cat $line_file | sed s'/;/ (/' | sed s'/;/ /' | sed s'/$/)/g' | sed s'/^/--> /g' | sort)

function get_line() 
{
	echo -n "\033[4mLine \033[3m(ie. metro 3, rer a, tram t3a):\033[m "
	read input
	input=$(echo $input | tr "ÄäÂâÀà" "a" |tr "ÈèÉéËëÊê" "e" | tr "ÏïÎî" "i" | tr "ÖöÔô" "o" | tr "ÜüÛû" "u" | tr "Çç" "c" | tr "[A-Z]" "[a-z]" | tr " " ".")
	res=$(echo $line_clean | grep -i "$input")
	[[ $(echo $res | wc -l) -eq 1 && $(echo $res | wc -c) -gt 2 ]] && line=`echo $res | cut -d';' -f1` && return
	[[ $(echo $res | wc -c) -eq 1 ]] && echo "No entry for $input (CTRL+C to quit)" && get_line
	[[ $(echo $res | wc -l) -gt 1 ]] && echo "\n\033[1mMultiple entries found for \"$input\" (be more precise):\033[m\n$(echo $res)\n" && get_line
} 

# get_line as main:
#set line
#get_line 
#echo $line