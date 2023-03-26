#! /bin/sh

line="C01743"
stop="474151"
terminus="vladivostok"

token='INSERT TOKEN HERE'
header="apikey: $token"
url="https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring?MonitoringRef=STIF%3AStopArea%3ASP%3A474151%3A&LineRef=STIF%3ALine%3A%3AC01743%3A"

#check token before request
#smthg like wc -c $token > 1
#echo err msg + link to token gen on idfm

#check date format
date | egrep -q 'CEST$|CET$' || {echo "Problem with date format. CET or CEST should be last parameter returned by date" && exit 47}

#set France GMT offset (+1 winter, +2 summer)
date | grep -q CET && GMT=1 || GMT=2

req=$(curl -s -X 'GET' -H $header $url | tr "{" "\n" | grep -i $terminus | tr "," "\n" | grep -i departuretime | egrep -o "([0-9]{2}:){2}[0-9]{2}")

#no need
req_depth=$(echo $req | wc -l | grep -o "[0-9]*") 

#array creation + fulfill 
RES=($(echo $req))

for res in "${RES[@]}"; do
hours=$(echo $res | sed s'/\(:[0-9]\{2\}\)\{2\}$//')
hours=$((( $hours + $GMT )))
[[ $hours -gt 24 ]] && hours=$(($hours - 24))
res=$(echo $hours`echo :``echo $res | cut -d':' -f2,3`)
echo $res
done

#add relative hours (ie: in 15 min)
#add selection menu with idfm data for generic use 
