# WBB CO2 STILT Tutorial
# Ben Fasoli

library(dplyr)
library(ggplot2)
library(raster)

# Load emisisons inventory, assigning the gridded product to "emissions" and
# extracting the time for each grid to "emissions_time"
emissions <- readRDS('tutorial/emissions.rds') # umol CO2 m-2 s-1
emissions_time <- getZ(emissions)

# Find all footprint files produced by STILT
footprint_paths <- dir('out/footprints', full.names = T)

# For each footprint in "footprint_paths", calculate the CO2 contribution from
# the near-field emisisons
concentration <- lapply(1:length(footprint_paths), function(i) {
  message(i)

  # Import footprint and extract timestamp
  foot <- brick(footprint_paths[i]) # umol CO2 m-2 s-1
  time <- as.POSIXct(getZ(foot), tz = 'UTC', origin = '1970-01-01')

  # Subset "emissions" to match the footprint timestamps
  band <- findInterval(time, emissions_time)
  emissions_subset <- subset(emissions, band)

  # Calculate the near-field CO2 contribution by taking the product of the
  # footprints and the fluxes
  data_frame(Time_UTC = max(time) + 3600,
             dCO2 = sum(values(foot * emissions_subset), na.rm = T))
}) %>%
  bind_rows() %>%
  mutate(CO2 = dCO2 + 400) # Add a pseudo-background concentration of 400ppm

# Plot a timeseries of the modeled concentrations and save the figure
f <- concentration %>%
  ggplot(aes(x = Time_UTC, y = CO2)) +
  geom_line() +
  theme_classic()
ggsave('timeseries.png', f)

f
