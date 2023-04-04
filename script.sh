#!/bin/zsh
source utils.sh

# help/usage mode
[[ $1 =~ "^(-i|-h|-help|-usage|--help|--usage)$" ]] && echo "\033[1mPRINT USAGE\033[0m" && exit 0

# token infos
token_path=~/.token_idfm
token=$(cat $token_path 2>/dev/null)
[[ $(echo $token | wc -c) -gt 1 ]] || {echo "token empty" && exit 43}

# research infos (mandatory for non interactive use)
line="C01743"
stop="45102"
terminus=("robinson" "mitry" "charles")

# interactive mode (reset line stop)
[[ $1 == "-i" ]] && {echo "\033[1;4;30;47mINTERACTIVE MODE\033[0m" ; get_stop ; get_line}

# unwanted argument
[[ $# -ge 1 ]] && { [[ $1 =~ "^(-i|-h|-help|-usage|--help|--usage)$" ]] || echo "Error : argument \"$1\" unrecognized" && exit 44 }


# requete api idfm
header="apikey: $token"
url="https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring?\
MonitoringRef=STIF%3AStopArea%3ASP%3A$stop%3A&LineRef=STIF%3ALine%3A%3A$line%3A"
req=$(curl -s -i -X 'GET' -H $header $url)
#echo $req | tr "," "\n"


# check code (401 token, 200 ok, 500||503 api ko, 400 input err)
code=$(echo $req | grep -m1 'HTTP' | egrep -o '[0-9]{3}')
echo $code | egrep -q '401' && echo $token_err && exit 45
echo $code | egrep -q '500|503' && echo "IDFM API KO" && exit 46
err=$(echo $code | egrep -q '400' && echo $req | grep -o "\"ErrorText\":\".*\"," | cut -d':' -f2 | tr -d "\",")
[[ `echo $err | wc -c` -gt 0 ]] && echo $err | grep -q "MonitoringRef/LineRef" && echo $sl_err && exit 47
[[ `echo $err | wc -c` -gt 0 ]] && echo $err | grep -q "MonitoringRef" && echo $stop_err && exit 48
[[ `echo $err | wc -c` -gt 0 ]] && echo $err | grep -q "LineRef" && echo $line_err && exit 49

# Get terminuses from req (interactive mode)
[[ $1 == "-i" ]] && get_terminus

# time mgmt : paris gmt + relative time
date | egrep -q 'CEST|CET' || {echo "Problem with date format : (CET or CEST expected)" && exit 50}
date | grep -q CET && GMT=1 || GMT=2
# not CET or CEST in date cmd? delete both upper lines and provide Paris GMT offset below
#GMT=x
current_time=$(date +%R)
ct_hours=$(echo $current_time | cut -d':' -f1)
ct_min=$(echo $current_time | cut -d':' -f2)

# print intro
retrieve_codenline_names
echo "\033[1;4;44mNext $line_name at $stop_name:\033[m"

# print results
for term in "${terminus[@]}" ;
do
	echo "\033[4mTerminus: $(echo $term | tr "_" " ")\033[m"
	next_times=($(echo $req | tr "{" "\n" | iconv -f UTF-8 -t ASCII//TRANSLIT | tr "[A-Z]" "[a-z]" | grep -i "$(echo $term | iconv -f UTF-8 -t ASCII//TRANSLIT | tr "[A-Z]" "[a-z]" | tr "_" " ")" | tr "," "\n" | grep -i departuretime | egrep -o "[0-9]{2}:[0-9]{2}")$(echo " "))
	for time in "${next_times[@]}" ;
	do
		min=$(echo $time | cut -d':' -f2)
		hours=$(( $(echo $time | cut -d':' -f1) + $GMT ))
		[[ $hours -gt 24 ]] && hours=$(($hours - 24))
		time=$(echo $hours`echo :``echo $time | cut -d':' -f2`)
		delta=$(( (($hours - $ct_hours) * 60) + $min - $ct_min ))
		[[ $delta -lt 0 ]] && echo "\t$time (retard)" || echo "\t$time (in $delta min)"
	done
done

# pb si departure stop == terminus (faudrait quitter) mais bon ...
# print usage
# readme propre
