# WBB Carbon Dioxide

Here, we'll simulate a day of carbon dioxide concentrations for the [UATAQ Lab](https://air.utah.edu), housed in the William Browning Building on the University of Utah campus. This tutorial assumes a base level of knowledge for [navigating UNIX based filesystems from the command line](https://www.digitalocean.com/community/tutorials/basic-linux-navigation-and-file-management), that you have read through the basics including [Installation](https://uataq.gitbooks.io/stilt/installation.html), and know where to find documentation for the different [Controls](https://uataq.gitbooks.io/stilt/controls.html).

## Dependencies

Let's start by checking to be sure the necessary dependencies are installed.

We need R version 3.2.5 or higher, which you can find in the output from

```r
> Rscript --version
# R scripting front-end version 3.4.1 (2017-06-30)
```

> If R is not found or the version is too old, you'll need to update R on your system before continuing

To compile the `hymodelc` executable, the makefile will default to searching for pgf90. We can check if pfg90 is installed with

```r
> which gfortran
# .../bin/gfortran\
```

> If `which` returns something along the lines of `/usr/bin/which: no gfortran in...`, you need to make some changes for the compilation to be successful. To use pgf90, you'll need to add the executable to your shell's PATH. To use a different compiler, you'll need to manually clone the [STILT Github Repository](https://github.com/uataq/stilt), specify the compiler in `fortran/Makefile` using the `FC` variable, then run the `./setup` executable.

Last, we need to check if we have netCDF installed. Footprints are saved in compressed netCDF files, which reduces their file size and stores results with associated metadata so that the output is self documenting. We can check if netCDF is installed with

```r
> nc-config --all
# This netCDF 4.4.1 has been built with the following features:
# ...
```


## Project setup

Now that we have the dependencies we need, let's start a new STILT project using the [uataq R package](https://github.com/benfasoli/uataq). We can install this package from Github within R using the `devtools` package as

```r
if (!require('devtools')) install.packages('devtools')
devtools::install_github('benfasoli/uataq')
```

Then we can initialize our STILT project in our current directory within R using

```r
uataq::stilt_init('wbb-tutorial')
```

To ensure everything compiled correctly, check to be sure you can find `hymodelc` in `exe/`

```r
> cd wbb-tutorial
> ls exe
# ASCDATA.CFG CONC.CFG hymodelc LANDUSE.ASC ROUGLEN.ASC
```

Success! We've now set up our STILT project.


## Input data

The minimum we need to simulate the carbon dioxide concentration at WBB is (1) meteorological data to transport the STILT particles and (2) a near-field emissions inventory. You can download example data for this tutorial in the base directory of your STILT project using

```r
> git clone https://github.com/uataq/stilt-tutorials
> ls stilt-tutorials/01-wbb
# emissions.rds met/ tutorial.r
```

which contains

1. `emissions.rds` - 0.002deg hourly emissions inventory
1. `met/` - meteorological data files
1. `tutorial.r` - a simple script to combine footprints with the emissions inventory and plot a timeseries of the concentrations


## Configuration

Now, we need to configure STILT for our example. Begin by opening `r/run_stilt.r` in a text editor.

Set the simulation timing and receptor location to

```r
# Simulation timing, yyyy-mm-dd HH:MM:SS
t_start <- '2015-12-10 00:00:00'
t_end <- '2015-12-10 23:00:00'
run_times <- seq(from = as.POSIXct(t_start, tz='UTC'),
to = as.POSIXct(t_end, tz='UTC'),
by = 'hour')

# Receptor locations
lati <- 40.766189
long <- -111.847672
zagl <- 25
```

Next, we need to tell STILT where to find the meteorological data files for the sample. Set the `met_directory` to

```r
# Meteorological data input
met_directory <- file.path(stilt_wd, 'stilt-tutorials', '01-wbb', 'met')
met_file_format <- '%Y%m%d.%Hz.hrrra'
```

Last, let's adjust the footprint grid settings so that it uses the same domain as our emissions inventory. Set the footprint grid settings to

```r
# Footprint grid settings
xmn <- -112.30
xmx <- -111.52
ymn <- 40.390
ymx <- 40.95
xres <- 0.002
yres <- xres
smooth_factor <- 1
time_integrate <- F
```

That's it! We're all set to run the model. From the base directory of our STILT project, run `Rscript r/run_stilt.r` and wait a few minutes for the simulations to complete.

```r
> Rscript r/run_stilt.r
# Parallelization disabled...
# Running simulation ID: 2015121000_-111.847672_40.766189_25
# Running simulation ID: 2015121001_-111.847672_40.766189_25
# ...
```


## Applying emissions

Now that we have 24 footprints for each hour of our simulation, the next step is to convolve the footprints with our emissions inventory. An example of how to do this can be found in `stilt-tutorials/01-wbb/tutorial.r`, which makes some overly-basic assumptions to calculate the carbon dioxide concentration at the receptor.

To convolve the footprints with emissions estimates,

```r
> cd stilt-tutorials/01-wbb
> Rscript tutorial.r
# 1
# 2
# ...
```

which will produce `timeseries.png` showing the modeled concentrations.

---

#### Credits:
- Ben Fasoli for assembling the tutorial
- Daniel Mendoza for providing the emissions inventory (Hestia)
