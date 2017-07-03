#!/bin/sh
T_MIN=58			#Below this temperature, the frequency will be increased
T_MAX=62			#Above this temperature, the frequency will be decreased
T_REFRESH=1800		#The temperature is checked every 1800s = 30m
FREQ_STEP=4			#Each step is 6.25MHz, so with FREQ_STEP=4 that's a 6.25*4=25MHz frequency increase or decrease
FREQ_MIN=500		#Minimum frequency
FREQ_MAX=700		#Maximum frequency

echo "Temperature regulation is active"
while true
do
	date
	temp=$(cgminer-api stats | grep temp_avg] | awk '{print $3}')
    if ! [ "$temp" -eq "$temp" ] 2> /dev/null
	then
		echo "Warning: temp not an integer! Waiting 60s."
        echo "temp: $temp"
		sleep 60	#Wait 60 seconds. Cgminer is probably restarting.
		continue	#Go to next loop iteration.
	fi
	echo "Temperature: $temp"
	freq=$(cgminer-api stats | grep frequency] | awk '{print $3}')
	echo "Frequency: $freq (Min: $FREQ_MIN - Max: $FREQ_MAX)"
	if [ $temp -gt $T_MAX ] && [ $freq -gt $FREQ_MIN ]
	then
		echo "Temperature too high: $temp";
		newFreq=$(cat freqList_S7 | grep -B "$FREQ_STEP" "$freq" | head -n 1)
		echo "New frequency: $newFreq"
	    sed -i "/bitmain-freq/c\"bitmain-freq\" : \"$newFreq\"," /config/cgminer.conf;
		echo "Restarting..."
		sleep 5s
		/etc/init.d/cgminer.sh restart
	elif [ $temp -lt $T_MIN ] && [ $freq -lt $FREQ_MAX ]
	then
		echo "Low temperature: $temp"
		newFreq=$(cat freqList_S7 | grep -A "$FREQ_STEP" "$freq" | tail -n 1)
		echo "New frequency: $newFreq"
		sed -i "/bitmain-freq/c\"bitmain-freq\" : \"$newFreq\"," /config/cgminer.conf;
		echo "Restarting..."
		sleep 5s
		/etc/init.d/cgminer.sh restart
	else
		echo "Temp OK: $temp (Min: $T_MIN - Max: $T_MAX)";
	fi
	echo "---------------------------------------"
	sleep $T_REFRESH
done
