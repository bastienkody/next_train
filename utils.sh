# Error msg
token_err="Error 401 : Invalid authentication credentials (bad token for Idfm API)"
i_e="Input error :"
sl_err="$i_e Stop code $stop is not a stop of line $line"
stop_err="$i_e Stop code $stop is not recognized"
line_err="$i_e Line code $line is not recognized"

# files
line_file=referentiel-des-lignes.csv
[[ -r $line_file ]] || {echo "File $line_file does not exist or is not readable" && exit 6}
line_clean=$(cat $line_file | sed s'/;/ (/' | sed s'/;/ /' | sed s'/$/)/g' | sed s'/^/--> /g' | sort)

stop_file=zones-d-arrets.csv
[[ -r $stop_file ]] || {echo "File $stop_file does not exist or is not readable" && exit 5}
stop_clean=$(cat $stop_file | sed s'/;/ (/' |  sed s'/;/ ; /g' | sed s'/.$/)/g' | sed s'/^/--> /g')

# function
function get_stop() 
{
	echo -n "\033[1mDeparture stop \033[3m(code or name)\033[m: "
	read input
	input=$(echo $input | iconv -f UTF-8 -t ASCII//TRANSLIT | tr "[A-Z]" "[a-z]" | tr -s "[:space:]")
	res=$(echo $stop_clean | grep "$input")
	[[ $(echo $res | wc -l) -eq 1 && $(echo $res | wc -c) -gt 2 ]] && stop=`echo $res | cut -d' ' -f2` && echo "\033[2mStop selected: $res\033[m" && return
	[[ $(echo $res | wc -c) -eq 1 ]] && echo "No entry for $input (CTRL+C to quit)" && get_stop
	[[ $(echo $res | wc -l) -gt 1 ]] && echo "\n\033[1mMultiple entries found for \"$input\" (be more precise):\033[m\n$(echo $res)\n" && get_stop
} 

function get_line() 
{
	echo -n "\033[1mLine \033[3m(ie. metro 3, rer a, tram t3a; or code)\033[m: "
	read input
	input=$(echo $input | iconv -f UTF-8 -t ASCII//TRANSLIT | tr "[A-Z]" "[a-z]" | tr -s "[:space:]")
	res=$(echo $line_clean | grep -i "$input")
	[[ $(echo $res | wc -l) -eq 1 && $(echo $res | wc -c) -gt 2 ]] && line=`echo $res | cut -d' ' -f2` && echo "\033[2mLine selected: $res\033[m" && return
	[[ $(echo $res | wc -c) -eq 1 ]] && echo "No entry for $input (CTRL+C to quit)" && get_line
	[[ $(echo $res | wc -l) -gt 1 ]] && echo "\n\033[1mMultiple entries found for \"$input\" (be more precise):\033[m\n$(echo $res)\n" && get_line
}

function get_terminus()
{
	test=($(echo $req | tr "," "\n" | grep -i destinationname | sort | uniq | egrep -o "\"value\":\".*}]$" | cut -d':' -f2 | egrep -o "\".*\"" | tr -d "\"" | tr " " "_"))
	i=0
	echo "\033[1mAvailable terminuses:\033[0m"
	for term in "${test[@]}" ;
	do
		i=$(($i+1))
		echo "$i - $(echo $term | tr "_" " ")"
	done
	echo -n "\033[1mSelect terminuses via digit (ie. 1 2 4):\033[0m "
	read selected_term
	while echo "$selected_term" | egrep -q "[^0-9 ]" && echo -n "Only numbers and spaces are accepted: " ;
	do
		read selected_term
	done
	echo "\033[2mTerminus selected: $selected_term\033[m"
	selected_term=($(echo $selected_term))
	terminus=()
	for term in "${selected_term[@]}" ;
	do
		terminus+=$(echo $test[$term] )
	done
}

function retrieve_codenline_names()
{
	line_name=$(cat $line_file | grep $line )
	echo $line_name | grep -q metro && line_name="METRO $(echo $line_name | cut -d';' -f3)" || line_name=$(echo $line_name | cut -d';' -f3)
	stop_name=$(cat $stop_file | grep $stop | tr "[a-z]" "[A-Z]")
	stop_name=$(echo $stop_name | cut -d';' -f2)
}


function print_usage()
{
	echo "NAME"
	echo "\tNEXT TRAIN Application - retrieves upcoming train runs infos"

	echo "DESCRIPTION"
	echo "Retrieve upcoming train runs infos from requesting IDFM (Paris suburban public transport) API."
	echo "The application works for metro, tramway, rer/ter and transilien."
	echo "Returns next runs for a specific line at a specific stop, and info/pertubations about the line."
 	echo "It is not a city mapper, it does not find routes"
	echo "SYNOPSYS"
}
