# WBB CO2 STILT Tutorial
# Ben Fasoli

library(dplyr)
library(ggplot2)
library(raster)

# Load emisisons inventory, assigning the gridded product to "emissions" and
# extracting the time for each grid to "emissions_time"
emissions <- readRDS('emissions.rds') # umol CO2 m-2 s-1
emissions_time <- getZ(emissions)

# Find all footprint files produced by STILT
footprint_paths <- dir('../../out/footprints', full.names = T)

# For each footprint in "footprint_paths", calculate the CO2 contribution from
# the near-field emisisons
concentration <- lapply(1:length(footprint_paths), function(i) {
  message(i)

  footprint_path <- footprint_paths[i]
  
  # Import footprint and extract timestamp
  foot <- brick(footprint_path) # umol CO2 m-2 s-1
  time <- as.POSIXct(getZ(foot), tz = 'UTC', origin = '1970-01-01')

  # Subset "emissions" to match the footprint timestamps
  band <- findInterval(time, emissions_time)
  emissions_subset <- subset(emissions, band)
  
  # Extract simulation information from filename
  sim <- unlist(strsplit(basename(footprint_path), '_'))
  sim <- list(
    run_time = as.POSIXct(sim[1], tz = 'UTC', format = '%Y%m%d%H'),
    long = as.numeric(sim[2]),
    lati = as.numeric(sim[3]))

  # Calculate the near-field CO2 contribution by taking the product of the
  # footprints and the fluxes
  data_frame(Time_UTC = sim$run_time,
             long = sim$long,
             lati = sim$lati,
             dCO2 = sum(values(foot * emissions_subset), na.rm = T))
}) %>%
  bind_rows() %>%
  mutate(CO2 = dCO2 + 400) # Add a pseudo-background concentration of 400ppm

# Plot a timeseries of the modeled concentrations and save the figure
f <- concentration %>%
  ggplot(aes(x = long, y = lati, color = CO2)) +
  geom_point() +
  scale_color_gradientn(colors = c('blue', 'cyan', 'green', 'yellow', 'orange', 'red'),
                        limits = range(concentration$CO2)) +
  labs(x = 'Longitude', y = 'Latitude') +
  theme_classic()
ggsave('map.png', f)

f
