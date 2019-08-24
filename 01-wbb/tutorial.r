# WBB CO2 STILT Tutorial
# Ben Fasoli

pkgs <- c('dplyr', 'htmlwidgets', 'leaflet', 'plotly', 'raster')

for (pkg in pkgs) {
  if (!pkg %in% installed.packages()) {
    install.packages(pkg, repos = 'https://cloud.r-project.org/')
  }
  require(pkg, character.only = T)
}


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
p <- plot_ly(concentration, x = ~Time_UTC, y = ~CO2,
        type = 'scatter', mode = 'lines') %>%
  layout(xaxis = list(title = ''),
         yaxis = list(title = '&#916;CO<sub>2</sub> [ppm]'))
htmlwidgets::saveWidget(p, 'timeseries.html')


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

crng <- range(values(foot_average))
cpal <- colorNumeric('Spectral', domain = crng, reverse = T)

map <- leaflet() %>%
  addProviderTiles('CartoDB.Positron') %>%
  addRasterImage(foot_average, opacity = 0.5, colors = cpal) %>%
  addLegend(position = 'bottomleft',
            pal = cpal,
            values = crng,
            title = paste0('m<sup>2</sup> s ppm<br>',
            '<span style="text-decoration:overline">&mu;mol</span>'))
map
htmlwidgets::saveWidget(map, 'average_footprint.html')


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
contribution_average <- log10(contribution_average)
contribution_average[contribution_average < -5] <- -5

# crng <- range(values(contribution_average))
crng <- c(-5.001, 0)
cpal <- colorNumeric('Spectral', domain = crng, reverse = T)

map <- leaflet() %>%
  addProviderTiles('CartoDB.Positron') %>%
  addRasterImage(contribution_average, opacity = 0.5, colors = cpal) %>%
  addLegend(position = 'bottomleft',
            pal = cpal,
            values = crng,
            title = paste0('log10 <br>',
                           'm<sup>2</sup> s ppm<br>',
                           '<span style="text-decoration:overline">&mu;mol</span>'))
map
htmlwidgets::saveWidget(map, 'average_contribution.html')