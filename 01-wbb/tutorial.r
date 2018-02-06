# WBB CO2 STILT Tutorial
# Ben Fasoli

library(dplyr)
library(ggmap)
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
  # Import footprint and extract timestamp
  foot <- brick(footprint_paths[i]) # umol CO2 m-2 s-1
  time <- as.POSIXct(getZ(foot), tz = 'UTC', origin = '1970-01-01')
  
  # Convert 3d brick to 2d raster if only a single timestep contains influence
  if (nlayers(foot) == 1)
    foot <- raster(foot, layer = 1)

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
concentration %>%
  ggplot(aes(x = Time_UTC, y = CO2)) +
  geom_line() +
  labs(x = 'Time (UTC)',
       y = expression(CO[2] ~ '(ppm)'),
       title = 'Transported Fluxes') +
  theme_classic()
ggsave('timeseries.png')


# For each footprint in "footprint_paths", fetch the footprint total into a list
foot_list <- lapply(1:length(footprint_paths), function(i) {
  # Import footprint and extract timestamp
  foot <- brick(footprint_paths[i]) # umol CO2 m-2 s-1
  
  # Convert 3d brick to 2d raster if only a single timestep contains influence
  if (nlayers(foot) == 1) {
    foot <- raster(foot, layer = 1)
  } else {
    foot <- sum(foot)
  }
  
  foot
})

# Calculate the average footprint from the list of footprint totals
foot_average <- sum(stack(foot_list)) / length(foot_list)

# Fetch a basemap from Google Maps to plot the results
basemap <- get_googlemap(center = c(lon = -112.0, lat = 40.7),
                         zoom = 10, scale = 2,
                         maptype = 'terrain', color = 'bw')

# Convert the raster object to a data frame of x,y,z(fill value) coordinates and
# overlay shaded image on Google Map
xyz <- foot_average %>%
  rasterToPoints() %>%
  as.data.frame()
ggmap(basemap, padding = 0) +
  coord_cartesian() +
  geom_raster(data = xyz, aes(x = x, y = y, fill = layer), alpha = 0.5) +
  scale_fill_gradientn(colors = c('blue','cyan','green','yellow','orange','red'),
                       guide = guide_colorbar(title = expression(frac(ppm ~ CO[2], m^{2} ~ s)))) +
  labs(x = NULL, y = NULL, fill = NULL) +
  theme(legend.key.width = unit(0.7, 'in'),
        legend.position = 'bottom')
ggsave('average_footprint.png')


# For each footprint in "footprint_paths", fetch the convolved flux field using
# emissions * footprints into a list of rasters that represent the contribution
# of fluxes over space
contribution_list <- lapply(1:length(footprint_paths), function(i) {
  # Import footprint and extract timestamp
  foot <- brick(footprint_paths[i]) # umol CO2 m-2 s-1
  time <- as.POSIXct(getZ(foot), tz = 'UTC', origin = '1970-01-01')
  
  # Convert 3d brick to 2d raster if only a single timestep contains influence
  if (nlayers(foot) == 1)
    foot <- raster(foot, layer = 1)
  
  # Subset "emissions" to match the footprint timestamps
  band <- findInterval(time, emissions_time)
  emissions_subset <- subset(emissions, band)
  
  # Calculate the near-field CO2 contribution by taking the product of the
  # footprints and the fluxes
  sum(foot * emissions_subset)
})

# Calculate the average contribution from the list of contribution totals
contribution_average <- sum(stack(contribution_list)) / length(contribution_list)

# Overlay on map
xyz <- contribution_average %>%
  rasterToPoints() %>%
  as.data.frame()
ggmap(basemap, padding = 0) +
  coord_cartesian() +
  geom_raster(data = xyz, aes(x = x, y = y, fill = log10(layer)), alpha = 0.5) +
  scale_fill_gradientn(colors = c('blue','cyan','green','yellow','orange','red'),
                       guide = guide_colorbar(title = expression(log[10] * (CO[2])))) +
  labs(x = NULL, y = NULL, fill = NULL) +
  theme(legend.key.width = unit(0.7, 'in'),
        legend.position = 'bottom')
ggsave('average_contribution.png')