stop_file=zones-d-arrets.csv
[[ -r $stop_file ]] || {echo "File $stop_file does not exist or is not readable" && exit 5}

function get_stop() 
{
	echo -n "Departure stop: "
	read input
	input=$(echo $input | tr "ÄäÂâÀà" "a" |tr "ÈèÉéËëÊê" "e" | tr "ÏïÎî" "i" | tr "ÖöÔô" "o" | tr "ÜüÛû" "u" | tr "Çç" "c" | tr "[A-Z]" "[a-z]")
	res=$(cat $stop_file | grep "$input")
	[[ $(echo $res | wc -l) -eq 1 && $(echo $res | wc -c) -gt 2 ]] && stop=`echo $res | cut -d';' -f1` && return
	[[ $(echo $res | wc -c) -eq 1 ]] && echo "No entry for $input (CTRL+C to quit)" && get_stop
	[[ $(echo $res | wc -l) -gt 1 ]] && echo "Multiple entries found (be more precise):\n$(echo $res | sed s'/;/ (/' |  sed s'/;/ ; /g' | sed s'/.$/)/g' | sed s'/^/--> /g') " && get_stop
} 

# for usage as main file :
#set stop
#get_stop 
#echo $stop