#!/bin/bash

ARW2ARL="./arw2arl"
INPUT_PATH="./wrfout"
OUTPUT_PATH="./arlout"

# Clean up any old files
rm -f WRFDATA.ARL
rm -f ARWDATA.CFG
rm -f ARLDATA.CFG
rm -fr ${OUTPUT_PATH}
mkdir -p $OUTPUT_PATH

# Loop through our WRF output files
for FILENAME in $INPUT_PATH/wrfout_*.nc; do
   BASENAME=$(basename $FILENAME)
   BASENAME=${BASENAME%.*}

   # Extract substring from filename containing time by day
   ARL_FILENAME=$OUTPUT_PATH/${BASENAME:0:21}.arl

   echo "Converting $FILENAME to $ARL_FILENAME"
   $ARW2ARL -i$FILENAME -c2
   cat ARLDATA.BIN >>$ARL_FILENAME
done

rm -f ARLDATA.BIN
rm -f WRFRAIN.bin
