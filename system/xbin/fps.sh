ISP_EVENTS='/d/seninf_events/seninf1/pkt_frame_cntr'
FPS=0

if [[ "$1" == "ffc" ]]
then
	echo "4cc FPS"
	ISP_EVENTS='/d/seninf_events/seninf2/pkt_frame_cntr'
fi

echo "reading events from $ISP_EVENTS"

while [ true ]
do
	CNTR=$(cat $ISP_EVENTS )
	FPS=$(( $CNTR - $FPS ))
	if [[ $CNTR -eq 0 ]]
	then
		FPS=0
	fi
	echo $FPS
	sleep 1
	FPS=$CNTR
done
