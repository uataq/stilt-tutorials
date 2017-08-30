# WBB CO2 STILT Tutorial
# Ben Fasoli

library(dplyr)
library(ggplot2)
library(raster)

emissions <- readRDS('tutorial/emissions.rds') # umol CO2 m-2 s-1
emissions_time <- getZ(emissions)

footprint_paths <- dir('out/footprints', full.names = T)

concentration <- lapply(1:length(footprint_paths), function(i) {
  message(i)
  
  foot <- brick(footprint_paths[i]) # umol CO2 m-2 s-1
  time <- as.POSIXct(getZ(foot), tz = 'UTC', origin = '1970-01-01')
  
  band <- findInterval(time, emissions_time)
  emissions_subset <- subset(emissions, band)
  
  data_frame(Time_UTC = max(time) + 3600,
             dCO2 = sum(values(foot * emissions_subset), na.rm = T))
}) %>%
  bind_rows() %>%
  mutate(CO2 = dCO2 + 400)

f <- concentration %>%
  ggplot(aes(x = Time_UTC, y = CO2)) +
  geom_line() +
  theme_classic()
ggsave('timeseries.png', f)

f




