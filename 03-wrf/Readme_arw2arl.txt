ARW2ARL

Advanced Research WRF to ARL format converts ARW
NetCDF files to a HYSPLIT compatible format. When the input
file contains data for a single time period, then the ARL format
output file from each execution should be appended (cat >>) to
the output file from the previous time periods execution.

Requires the installation of the NCAR NetCDF libraries!
NetCDF version 3 use -lnetcdf
NetCDF version 4 use -lnetcdff

_______________________________________________
Notes:

- Optional TKE variable may need to be edited depending
  upon the version of WRF (TKE_PBL; TKE_MYJ; TKE); all
  versions should convert to the ARL variable TKEN

- The ARL packed value DIF{W|R} is the difference field
  between the packed value and the original value; used
  to increase precision for selected variables
