# Salt Lake City light-rail train

Here, we'll simulate carbon dioxide concentrations along the Utah Transit Authority "red" light-rail route. This tutorial assumes a base level of knowledge for [navigating UNIX based filesystems from the command line](https://www.digitalocean.com/community/tutorials/basic-linux-navigation-and-file-management), that you have read through the basics including [Installation](https://uataq.gitbooks.io/stilt/installation.html), know where to find documentation for the different [Controls](https://uataq.gitbooks.io/stilt/controls.html), and have completed the [previous WBB Carbon Dioxide tutorial](https://github.com/uataq/stilt-tutorials/tree/master/01-wbb).


## Project setup

Let's start a new STILT project using the [uataq R package](https://github.com/benfasoli/uataq). We can initialize our STILT project in our current directory within R using

```r
uataq::stilt_init('train-tutorial')
```

To ensure everything compiled correctly, check to be sure you can find `hymodelc` in `exe/`

```r
> ls exe
# ASCDATA.CFG CONC.CFG hymodelc LANDUSE.ASC ROUGLEN.ASC
```

Success! We've now set up our STILT project.


## Input data

To simulate the carbon dioxide concentrations along the light-rail route, we need (1) meteorological data for the time period of interest, (2) a near-field emissions inventory, and (3) the locations to place simulation receptors.

You can download example data for this tutorial in the base directory of your STILT project using

```r
> git clone https://github.com/uataq/stilt-tutorials
> ls stilt-tutorials/02-train
# emissions.rds met/ receptors.rds tutorial.r
```

which contains

1. `emissions.rds` - 0.002deg hourly emissions inventory
1. `met/` - meteorological data files
1. `receptors.rds` - a data frame containing the lat/lon coordinates of receptors along the light-rail route
1. `tutorial.r` - a simple script to combine footprints with the emissions inventory and plot a timeseries of the concentrations


## Configuration

Now, we need to configure STILT for our example. Begin by opening `r/run_stilt.r` in a text editor.

We'll be assuming that the train completes the transect within an hour and will use the same timestamp for all points, since our emissions estimates are hourly. Set the simulation timing and receptor locations with

```r
# Simulation timing, yyyy-mm-dd HH:MM:SS
t_start <- '2015-12-10 23:00:00'
t_end <- '2015-12-10 23:00:00'
run_times <- seq(from = as.POSIXct(t_start, tz='UTC'),
to = as.POSIXct(t_end, tz='UTC'),
by = 'hour')

# Receptor locations
r <- readRDS('stilt-tutorials/train/receptors.rds')
lati <- r$lati
long <- r$long
zagl <- 5
```

Next, we need to tell STILT where to find the meteorological data files for the sample. Set the `met_directory` to

```r
# Meteorological data input
met_directory <- file.path(stilt_wd, 'stilt-tutorials', '02-train', 'met')
met_file_format <- '%Y%m%d.%Hz.hrrra'
```

Last, let's adjust the footprint grid settings so that it uses the same domain as our emissions inventory. We'll use the same grid and emissions inventory from the previous example. Set the footprint grid settings to

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

Last, we are now simulating concentrations for 215 receptors which will take significantly longer than the 24 receptors used in the previous example. Let's set STILT to run the simulations across a few parallel threads to speed things up by setting

```r
n_cores <- 2
```

> You can use a higher number of parallel threads depending on your system configuration. In general, you should not use more threads than available CPU cores. For this example, plan for 2GB of RAM to be allocated per thread to keep from going over available memory.

That's it! We're all set to run the model. From the base directory of our STILT project, run `Rscript r/run_stilt.r` and wait a few minutes for the simulations to complete.

```r
> Rscript r/run_stilt.r
# Parallelization using multiple R jobs. Dispatching processes...
#
# starting worker pid=67900 on localhost:11096 at 13:16:36.722
# starting worker pid=67901 on localhost:11096 at 13:16:36.737
#
# Running simulation ID: 2015121023_-111.84_40.768_5
# Running simulation ID: 2015121023_-111.9_40.632_5
# ...
```


## Applying emissions

Now that we have our footprints, the next step is to convolve the footprints with our emissions inventory. An example of how to do this can be found in `stilt-tutorials/train/tutorial.r`, which makes some overly-basic assumptions to calculate the carbon dioxide concentration at the receptors.

To convolve the footprints with emissions estimates,

```r
> cd stilt-tutorials/02-train
> Rscript tutorial.r
# 1
# 2
# ...
```

which will produce `map.png` showing the modeled concentrations.

---

#### Credits:
- Ben Fasoli for assembling the tutorial
- Daniel Mendoza for providing the emissions inventory (Hestia)
