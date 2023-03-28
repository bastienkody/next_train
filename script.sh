#!/bin/sh

# token checker
token=$(cat ~/.token_idfm 2>/dev/null)
[[ $(echo $token | wc -c) -gt 1 ]] || {echo "token empty" && exit 45}

# research infos
line="C01743"
#line="C43"
stop="474151"
stop="45102"
#stop="451"
terminus=()

header="apikey: $token"
url="https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring?\
MonitoringRef=STIF%3AStopArea%3ASP%3A$stop%3A&LineRef=STIF%3ALine%3A%3A$line%3A"

# requete api idfm
req=$(curl -s -i -X 'GET' -H $header $url)
#echo $req

# check code (200 ok, 500||503 api ko, 400 -> input err. MonitoringRef:stop || LineRef:line)
code=$(echo $req | grep -m1 'HTTP' | egrep -o '[0-9]{3}')
echo $code | egrep -q '500|503' && echo "idfm ko" && exit 46
err=$(echo $code | egrep -q -o '400' && echo $req | grep -o "\"ErrorText\":\".*\"," | cut -d':' -f2 | tr -d "\",")
[[ `echo $err | wc -c` -gt 0 ]] && echo $err | grep -q "MonitoringRef" && echo "Stop code is not recognized" && exit 47
[[ `echo $err | wc -c` -gt 0 ]] && echo $err | grep -q "LineRef" && echo "Line code is not recognized" && exit 48

for term in "${terminus[@]}";
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
# if not current time 
current_time=$(date | egrep -o '[0-9]{2}:[0-9]{2}')
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

# - afficher terminus
# - erreur de terminus
# - recup les lignes (rer tram metro)

