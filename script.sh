#! /bin/sh

#token verifier
token=$(cat ~/.token_idfm 2>/dev/null)
[[ $(echo $token | wc -c) -gt 1 ]] || {echo "token empty" && exit 45}

#research infos
line="C01743"
#line="C43"
stop="474151"
stop="451"
terminus="mitry"

header="apikey: $token"
url="https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring?\
MonitoringRef=STIF%3AStopArea%3ASP%3A$stop%3A&LineRef=STIF%3ALine%3A%3A$line%3A"

#requete api idfm
req=$(curl -s -i -X 'GET' -H $header $url)

#check code (200 ok)
code=$(echo $req | grep -m1 'HTTP' | egrep -o '[0-9]{3}')
#500 && 503 -> api ko
echo $code | egrep -q -o '500|503' && echo "idfm ko" && exit 46
#400 -> input err. MonitoringRef : stop ; LineRef : line
echo $code | egrep -q -o '400' && echo $req | grep -o "\"ErrorText\":\"Le MonitoringRef renseigné n'existe pas\"" && exit

#200 ok
echo $code | egrep -q -o '200' && echo "requete ok"


next_times=$(echo $req | tr "{" "\n" | grep -i $terminus | tr "," "\n" | grep -i departuretime| egrep -o "([0-9]{2}:){2}[0-9]{2}")

#check date format
date | egrep -q 'CEST|CET' || {echo "Problem with date format : (CET or CEST waited)" && exit 47}

#set France GMT offset (+1 winter, +2 summer)
date | grep -q CET && GMT=1 || GMT=2

#get current time for relative time
current_time=$(date | egrep -o '[0-9]{2}(:[0-9]{2}){2}')

#array creation + fulfill 
RES=($(echo $next_times))

echo $current_time
for res in "${RES[@]}"; do
hours=$(echo $res | sed s'/\(:[0-9]\{2\}\)\{2\}$//')
hours=$(( $hours + $GMT ))
[[ $hours -gt 24 ]] && hours=$(($hours - 24))
res=$(echo $hours`echo :``echo $res | cut -d':' -f2,3`)
echo next train: $res
done

#add relative hours (ie: in 15 min)
