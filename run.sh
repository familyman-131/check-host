#!/bin/bash

if ! command -v jq &> /dev/null
then
    echo "pls install jq utility"
    sudo apt install jq -y
fi

WD=(/root/check-host)
RPRT=(${WD}/index.html )
LCKFL=(${WD}/.lockfile)

if [ ! -d ${WD}/json ]
then
    mkdir ${WD}/json
fi

if [ ! -f ${LCKFL} ]
then
    echo "lockfile does not exist, proceed"
else
    echo "lockfile found, exiting"
    exit 0
fi

rm   ${RPRT}
touch  ${RPRT}
touch ${LCKFL}

echo "<p>  started at $(date) pls refresh page in ~3 minutes"  >>   $RPRT

while read -r TGT;
do
  LNK=$( curl -H "Accept: application/json" https://check-host.net/check-http?host=$TGT | jq . | jq -r .permanent_link )
  ID=$(echo "${LNK}" | cut -d/ -f5 )
  echo "${ID}"
  echo "${LNK}"
  sleep 5
  curl -H "Accept: application/json" https://check-host.net/check-result/${ID} | jq . | tee ${WD}/json/${ID}.json 1>/dev/null
  OK=$(grep -c -i -E 'OK|moved' ${WD}/json/${ID}.json )
  TOTAL=21
  PRCNT=$(echo $(( ${OK}*100/${TOTAL} )))
  echo "<p>  ${PRCNT}% OK $TGT <a href='${LNK}' target='_blank' >${LNK}</a> <br /> " >>   $RPRT
done < ${WD}/targets.txt

echo "<p>  null means  check-host.net overloaded and we need to wait 5-10 minutes until next check "  >>   $RPRT
echo "<p>  <b>last update at $(date) </b>" >>   $RPRT
echo "<p>  <a href='https://github.com/familyman-131/site-checker' target='_blank' > github </a> <br />"   >>   $RPRT

rm ${WD}/json/*.json
rm ${LCKFL}

