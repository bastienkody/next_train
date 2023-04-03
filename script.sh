#!/bin/zsh

# help/usage mode
[[ $1 =~ "-h|-help|-usage|--help|--usage" ]] && echo "\033[1mPRINT USAGE\033[0m" && exit 0
# includes (only needed for interactive mode)
[[ $1 == "-i" ]] && source search_stop.sh

# token infos
token_path=~/.token_idfm
token=$(cat $token_path 2>/dev/null)
[[ $(echo $token | wc -c) -gt 1 ]] || {echo "token empty" && exit 45}

# research infos (mandatory for non interactive use)
line="C01743"
stop="474151"
terminus=("mitry")

# interactive mode (reset line stop)
[[ $1 == "-i" ]] && echo "\033[1;4mInteractive mode\033[0m" && get_stop && get_line

# requete api idfm
header="apikey: $token"
url="https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring?\
MonitoringRef=STIF%3AStopArea%3ASP%3A$stop%3A&LineRef=STIF%3ALine%3A%3A$line%3A"
req=$(curl -s -i -X 'GET' -H $header $url)
#echo $req

# Error msg
token_err="Error 401 : Invalid authentication credentials (bad token for Idfm API)"
i_e="Input error :"
sl_err="$i_e Stop code $stop is not a stop of line $line"
stop_err="$i_e Stop code $stop is not recognized"
line_err="$i_e Line code $line is not recognized"

# check code (401 token, 200 ok, 500||503 api ko, 400 input err)
code=$(echo $req | grep -m1 'HTTP' | egrep -o '[0-9]{3}')
echo $code | egrep -q '401' && echo $token_err && exit 45
echo $code | egrep -q '500|503' && echo "IDFM API KO" && exit 46
err=$(echo $code | egrep -q '400' && echo $req | grep -o "\"ErrorText\":\".*\"," | cut -d':' -f2 | tr -d "\",")
[[ `echo $err | wc -c` -gt 0 ]] && echo $err | grep -q "MonitoringRef/LineRef" && echo $sl_err && exit 47
[[ `echo $err | wc -c` -gt 0 ]] && echo $err | grep -q "MonitoringRef" && echo $stop_err && exit 47
[[ `echo $err | wc -c` -gt 0 ]] && echo $err | grep -q "LineRef" && echo $line_err && exit 48

# Get terminuses from req (interactive mode)
test=()
test=$(echo $req | tr "," "\n" | grep -i destinationname | sort | uniq | egrep -o "\"value\":\".*}]$" | cut -d':' -f2 | egrep -o "\".*\"" | tr -d "\"" | tr "ÄäÂâÀà" "a" |tr "ÈèÉéËëÊê" "e" | tr "ÏïÎî" "i" | tr "ÖöÔô" "o" | tr "ÜüÛû" "u" | tr "Çç" "c" | tr "[A-Z]" "[a-z]")
echo $test[@]
#exit 42

#possible_terminus=$(   )

for term in "${terminus[@]}" ;
do
	next_times+=$(echo $req | tr "{" "\n" | grep -i $term | tr "," "\n" | grep -i departuretime | egrep -o "[0-9]{2}:[0-9]{2}")$(echo " ")
done

# set France GMT offset (+1 winter, +2 summer)
date | egrep -q 'CEST|CET' || {echo "Problem with date format : (CET or CEST expected)" && exit 49}
date | grep -q CET && GMT=1 || GMT=2
# if unable to get CET or CEST in date cmd, provide the current Paris GMT offset below
#GMT=x

# for relative time
current_time=$(date +%R)
ct_hours=$(echo $current_time | cut -d':' -f1)
ct_min=$(echo $current_time | cut -d':' -f2)

RES=($(echo $next_times))

#print result intro
echo "Next $line at stop $stop direction $terminus:"

# GMT correction + relative time calculation + prints out results
for res in "${RES[@]}"; 
do
	min=$(echo $res | cut -d':' -f2)
	hours=$(( $(echo $res | cut -d':' -f1) + $GMT ))
	[[ $hours -gt 24 ]] && hours=$(($hours - 24))
	res=$(echo $hours`echo :``echo $res | cut -d':' -f2`)
	delta=$(( (($hours - $ct_hours) * 60) + $min - $ct_min ))
	[[ $delta -lt 0 ]] && echo "next at $res (retard)" || echo "next at $res (in $delta min)"
done

# - afficher terminus (le recup somehow dans next_times)
# - erreur de terminus
# - recup les lignes (rer tram metro) + mode interactif

