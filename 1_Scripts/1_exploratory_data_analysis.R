# SETTING THE THEME AND FONT FOR ALL THE GRAPHS
theme_set(
  theme_minimal() +
    theme(text = element_text(family = 'mono'),
          plot.title = element_text(hjust = 0.5, size = 15, face = 'bold'),
          axis.title.x = element_text(size = 13, face = 'bold'),
          axis.title.y = element_text(size = 13, face = 'bold'),
          axis.text.x = element_text(size = 15, face = 'bold'),
          axis.text.y = element_text(size = 15, face = 'bold'),
          legend.title = element_text(size = 12, face = "bold"),
          legend.text = element_text(size = 10))
)

#### SONGS ---------------------------------------------------------------------
# Dropping NULL since it's redundant here
df_meta_songs_2 = df_meta_songs %>%
  drop_na()

# Popularity Distribution
# Visualizing the distribution of song popularity scores (spread of popularity values across songs)
pop_dist = ggplot(df_meta_songs_2, aes(x = popularity)) +
  geom_histogram(fill = "lightseagreen", bins = 30) +
  labs(
    title = "Distribution of Song Popularity Scores",
    x = "Popularity",
    y = "Count"
  ) +
  scale_x_continuous(breaks = seq(min(df_meta_songs_2$popularity), max(df_meta_songs_2$popularity), by = 15)) +
  scale_y_continuous(breaks = pretty_breaks(n = 8))

plot(pop_dist)
ggsave(paste0("popularity_distribution.jpeg"), pop_dist, path = "../2_Outputs/Plots/EDA")

# Grouping songs by popularity and summarizing
count_pop = df_meta_songs_2%>%
  group_by(popularity) %>%
  summarize(coun = n(),
            av = mean(popularity)) %>%
  filter(is.na(popularity) == FALSE)

# Count of songs with a popularity score >= 50
sum(count_pop[count_pop$popularity >= 50, c('coun')])

# Aggregating the song popularity over the years for the plot
overtime_mean_pop = df_pop_songs %>%
  left_join(df_meta_songs_2 %>% select(song_id, popularity) %>% distinct(), by = c('song_id')) %>%
  select(year, popularity) %>%
  distinct() %>%
  group_by(year) %>%
  summarize(
    mean_pop = mean(popularity)
  )

# Mean Popularity over the years
overall_pop_time = ggplot(overtime_mean_pop, aes(x = year, y = mean_pop)) +
  geom_line(color = "darkgreen", size = 1) +  # Line plot
  labs(
    title = "Mean Popularity Score Over the Years",
    x = "Year",
    y = "Popularity"
  ) +
  scale_x_continuous(breaks = seq(min(overtime_mean_pop$year), max(overtime_mean_pop$year), by = 6)) +
  scale_y_continuous(breaks = seq(round(min(overtime_mean_pop$mean_pop)), round(max(overtime_mean_pop$mean_pop)), by = 4))

plot(overall_pop_time)
ggsave(paste0("mean_popularity_overtime.jpeg"), overall_pop_time, path = "../2_Outputs/Plots/EDA")

# Preparing the data for the pie chart since we need a percentage and label for explicit songs
explicit_distribution = df_meta_songs_2 %>%
  group_by(explicit) %>%
  summarise(count = n()) %>%
  mutate(percentage = count / sum(count) * 100,
         label = paste0(ifelse(explicit == 'True', 'Explicit', 'Not Explicit'), " (", round(percentage, 1), "%)"))

# pie chart showing the distribution of explicit songs
explicit_pie = ggplot(explicit_distribution, aes(x = "", y = count, fill = explicit)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar(theta = "y") + # Changing to pie
  labs(
    title = "Distribution of Explicit Songs",
    x = NULL,
    y = NULL
  ) +
  theme_void() +  # To clear up the chart
  geom_text(aes(label = label), position = position_stack(vjust = 0.5),
            family = 'mono',
            fontface = 'bold') +
  scale_fill_manual(values = c("olivedrab3", "red3")) +
  theme (plot.title = element_text(hjust = 0.5, size = 15, face = 'bold', family = 'mono'),
         legend.title = element_text(size = 12, face = "bold", family = 'mono'),
         legend.text = element_text(size = 10, family = 'mono'))

plot(explicit_pie)
ggsave(paste0("explicit_pie.jpeg"), explicit_pie, path = "../2_Outputs/Plots/EDA")

# Preparing the data for the pie chart since we need a percentage and label for song types
song_type_distribution = df_meta_songs_2 %>%
  group_by(song_type) %>%
  summarise(count = n()) %>%
  mutate(percentage = count / sum(count) * 100,
         label = paste0(song_type, " (", round(percentage, 1), "%)"))

# pie chart showing the distribution of song_type
song_t_pie = ggplot(song_type_distribution, aes(x = "", y = count, fill = song_type)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar(theta = "y") + # Changing to pie
  labs(
    title = "Distribution of Song Types",
    x = NULL,
    y = NULL
  ) +
  theme_void() +  # To clear up the chart
  geom_text(aes(label = label), position = position_stack(vjust = 0.5),
            family = 'mono',
            fontface = 'bold') +
  scale_fill_manual(values = c("orange", "steelblue")) +
  theme (plot.title = element_text(hjust = 0.5, size = 15, face = 'bold', family = 'mono'),
         legend.title = element_text(size = 12, face = "bold", family = 'mono'),
         legend.text = element_text(size = 10, family = 'mono'))

plot(song_t_pie)
ggsave(paste0("song_type_pie.jpeg"), song_t_pie, path = "../2_Outputs/Plots/EDA")

# Top 10 artists with the highest number of songs
# Breaking down songs by artist to identify those with the highest contributions
df_meta_songs_2= df_meta_songs_2 %>%
  mutate(artist_id_vectors := mapply(extract_artist, artists))

# preparing the data to get the top 10 artists and splitting the artist since one song can have multiple artists
df_exploded = df_meta_songs_2[, .(artist_id = unlist(strsplit(as.character(artist_id_vectors), ","))), by = song_id]

# Counting the number of songs per artist and choosing top 10
df_exploded = df_exploded %>%
  group_by(artist_id) %>%
  summarize(
    song_count = n_distinct(song_id)
  ) %>%
  arrange(desc(song_count)) %>%
  head(10) %>%
  left_join(df_meta_artists %>% select(artist_id, name), by = c('artist_id'))

# Plotting top 10 artists by song count
top_artists = ggplot(df_exploded, aes(x = fct_infreq(name, song_count), y = song_count)) +
  geom_col(fill = "steelblue3") +
  labs(
    title = "Top 10 Artists by Number of Songs",
    x = "Artist Name",
    y = "Song Count"
  ) +
  theme_minimal() +
  theme(text = element_text(family = 'mono'),
        plot.title = element_text(hjust = 0.5, size = 15, face = 'bold'),
        axis.text.x = element_text(size = 10, face = 'bold', angle = 60, vjust = 1.1, hjust = 1),
        axis.text.y = element_text(size = 10, face = 'bold'))

plot(top_artists)
ggsave(paste0("top_artists.jpeg"), top_artists, path = "../2_Outputs/Plots/EDA")

# Average year-end score over the years for songs
avg_yes_artist = ggplot(df_pop_songs %>% group_by(year) %>% summarize(avg_year_end_score = mean(year_end_score)),
       aes(x = year, y = avg_year_end_score)) +
  geom_area(fill = 'lightseagreen') +
  labs(
    title = "Average Year-End Score Over Years",
    x = "Year",
    y = "Average Year-End Score"
  ) +
  scale_x_continuous(breaks = pretty_breaks(n = 10)) +
  scale_y_continuous(breaks = pretty_breaks(n = 10))

plot(avg_yes_artist)
ggsave(paste0("avg_year_end_artist_years.jpeg"), avg_yes_artist, path = "../2_Outputs/Plots/EDA")

# Average year_end_score over the years for songs based on whether they are explicit or not
# Joining df_pop_songs with explicit column to include the explicit information
avg_explicit_yes = df_pop_songs %>% 
  left_join(df_meta_songs_2%>% select(song_id, explicit), by = c('song_id'))

# Plotting the average year_end_score grouped by year and explicit status
avg_explicit_plot = ggplot(avg_explicit_yes %>% 
                             group_by(year, explicit) %>% 
                             summarize(avg_year_end_score = mean(year_end_score, na.rm = TRUE)), # Handle NA values
                           aes(x = year, y = avg_year_end_score, fill = explicit)) +
  geom_area(alpha = 0.8) +
  scale_fill_manual(values = c("True" = "red3", "False" = "seagreen3")) +
  labs(
    title = "Average Year-End Score Over the Years by Explicit Status",
    x = "Year",
    y = "Average Year-End Score",
    fill = "Explicit"
  ) +
  scale_x_continuous(breaks = pretty_breaks(n = 8)) +
  scale_y_continuous(breaks = pretty_breaks(n = 8))

plot(avg_explicit_plot)
ggsave(paste0("avg_year_end_explicit.jpeg"), avg_explicit_plot, path = "../2_Outputs/Plots/EDA")

# Average year_end_score over the years for songs based on song type (Solo or Collaboration)
# Joining df_pop_songs with song_type column to include the song type information
avg_sol_c_yes = df_pop_songs %>% 
  left_join(df_meta_songs_2%>% select(song_id, song_type), by = c('song_id'))

# Plotting the average year_end_score grouped by year and song type
avg_song_type_plot = ggplot(avg_sol_c_yes %>% 
                              group_by(year, song_type) %>% 
                              summarize(avg_year_end_score = mean(year_end_score, na.rm = TRUE)), # Handle NA values
                            aes(x = year, y = avg_year_end_score, fill = song_type)) +
  geom_area(alpha = 0.8) +
  scale_fill_manual(values = c("Solo" = "steelblue", "Collaboration" = "orange")) +
  labs(
    title = "Average Year-End Score Over the Years by Song Type",
    x = "Year",
    y = "Average Year-End Score",
    fill = "Song Type"
  ) +
  scale_x_continuous(breaks = pretty_breaks(n = 8)) +
  scale_y_continuous(breaks = pretty_breaks(n = 8))

plot(avg_song_type_plot)
ggsave(paste0("avg_year_end_song_type.jpeg"), avg_song_type_plot, path = "../2_Outputs/Plots/EDA")

#### ARTIST --------------------------------------------------------------------
# Popularity Distribution (distribution of artist popularity scores)
popularity_dist = ggplot(df_meta_artists, aes(x = popularity)) +
  geom_histogram(fill = "orange", bins = 30) +
  labs(
    title = "Distribution of Artist Popularity Scores",
    x = "Popularity",
    y = "Count"
  ) +
  scale_x_continuous(breaks = seq(min(df_meta_artists$popularity), max(df_meta_artists$popularity), by = 15)) +
  scale_y_continuous(breaks = pretty_breaks(n = 8))

plot(popularity_dist)
ggsave(paste0("artist_popularity_distribution.jpeg"), popularity_dist, path = "../2_Outputs/Plots/EDA")

# Grouping artists by popularity and summarizing
# Summarizing for counts and mean popularity
count_pop = df_meta_artists %>%
  group_by(popularity) %>%
  summarize(
    coun = n(),
    av = mean(popularity)
  ) %>%
  filter(is.na(popularity) == FALSE)

# Count of artists with a popularity score >= 50
# Calculate total number of popular artists
sum(count_pop[count_pop$popularity >= 50, c('coun')])

# Followers Distribution (not a good idea) (the distribution of artist followers)
followers_dist = ggplot(df_meta_artists %>%
                          mutate(
                            followers = ifelse(followers == 'None', 0, followers),
                            followers = as.numeric(followers)
                          ),
                        aes(x = followers)) +
  geom_histogram(fill = "lightseagreen", bins = 30) +
  labs(
    title = "Distribution of Artist Followers",
    x = "Followers",
    y = "Count"
  )

plot(followers_dist)
ggsave(paste0("artist_followers_distribution.jpeg"), followers_dist, path = "../2_Outputs/Plots/EDA")

# Total followers of artists over the years
# Analyzing total followers over time
agg_followers = df_pop_artists %>%
  left_join(df_meta_artists %>% select(artist_id, followers), by = c('artist_id')) %>%
  mutate(
    followers = ifelse(followers == 'None', 0, followers),
    followers = as.numeric(followers)
  ) %>%
  group_by(year) %>%
  summarize(
    sum_fol = sum(followers, na.rm = TRUE)
  )

followers_over_years = ggplot(agg_followers, aes(x = year, y = sum_fol)) +
  geom_area(fill = "sienna2") +
  scale_y_continuous(labels = label_number(scale = 1e-6, suffix = " M")) +
  scale_x_continuous(breaks = seq(min(agg_followers$year), max(agg_followers$year), by = 6)) +
  labs(
    title = "Total Artist Followers Over the Years",
    x = "Year",
    y = "Total Followers (in Millions)"
  )

plot(followers_over_years)
ggsave(paste0("total_followers_over_years.jpeg"), followers_over_years, path = "../2_Outputs/Plots/EDA")

# Artist Type Bar Graph (Distribution of artist types
artist_type_bar = ggplot(df_meta_artists %>%
                           mutate(
                             artist_type = ifelse(artist_type == "'band'", 'band', artist_type),
                             artist_type = ifelse(artist_type == '-', 'Not Given', artist_type)
                           ), 
                         aes(x = artist_type)) +
  geom_bar(fill = "seagreen") +
  labs(
    title = "Distribution of Artist Types",
    x = "Artist Type",
    y = "Count"
  )

plot(artist_type_bar)
ggsave(paste0("artist_type_distribution.jpeg"), artist_type_bar, path = "../2_Outputs/Plots/EDA")

# Most Common Top 10 Main Genres of the Artist
# Analyzing the most common genres excluding 'Not Given'
genre_count_df = df_meta_artists %>%
  mutate(main_genre = ifelse(main_genre == '-', 'Not Given', main_genre)) %>%
  group_by(main_genre) %>%
  summarize(genres_count = n()) %>%
  arrange(desc(genres_count)) %>%
  head(11) %>%
  filter(main_genre != 'Not Given')

top_genres = ggplot(genre_count_df, aes(x = fct_infreq(main_genre, genres_count), y = genres_count)) +
  geom_col(fill = "lightseagreen") +
  labs(
    title = "Top 10 Main Genres of Artists",
    x = "Genre",
    y = "Count"
  ) +
  theme_minimal() +
  theme(
    text = element_text(family = 'mono'),
    plot.title = element_text(hjust = 0.5, size = 15, face = 'bold'),
    axis.text.x = element_text(size = 10, face = 'bold', angle = 60, vjust = 1, hjust = 1),
    axis.text.y = element_text(size = 10, face = 'bold')
  )

plot(top_genres)
ggsave(paste0("top_artist_genres.jpeg"), top_genres, path = "../2_Outputs/Plots/EDA")

# Average Year-End Score of Artists by Artist Type
# Analyzing year-end scores grouped by artist type and year
pop_meta = df_pop_artists %>%
  left_join(df_meta_artists %>% select(artist_id, artist_type) %>% distinct(), by = c('artist_id')) %>%
  mutate(
    artist_type = ifelse(artist_type == "'band'", 'band', artist_type),
    artist_type = ifelse(artist_type == '-', 'Not Given', artist_type),
    artist_type = ifelse(is.na(artist_type), 'Not Given', artist_type)
  ) %>%
  group_by(artist_type, year) %>%
  summarize(
    score_sum = sum(year_end_score, na.rm = TRUE)
  )

year_end_artist_type = ggplot(pop_meta, aes(x = year, y = score_sum, fill = artist_type)) +
  geom_area(alpha = 0.8) +
  scale_fill_manual(values = c(
    "singer" = "steelblue",
    "rapper" = "darkorange",
    "DJ" = "mediumpurple",
    "band" = "mediumseagreen",
    "Not Given" = "gray",
    "duo" = "lightcoral"
  )) +
  facet_wrap(~artist_type, scales = "free_y") +
  scale_y_continuous(labels = label_number(scale = 1e-3, suffix = " K")) +
  scale_x_continuous(breaks = seq(min(pop_meta$year), max(pop_meta$year), by = 10)) +
  labs(
    title = "Year-End Scores by Artist Type Over the Years",
    x = "Year",
    y = "Year-End Score (in Thousands)",
    fill = "Artist Type"
  ) +
  theme(text = element_text(family = 'mono'),
        plot.title = element_text(hjust = 0.5, size = 15, face = 'bold'),
        axis.title.x = element_text(size = 13, face = 'bold'),
        axis.title.y = element_text(size = 13, face = 'bold'),
        axis.text.x = element_text(size = 8, face = 'bold'),
        axis.text.y = element_text(size = 15, face = 'bold'),
        legend.title = element_text(size = 12, face = "bold"),
        legend.text = element_text(size = 10))

plot(year_end_artist_type)
ggsave(paste0("year_end_artist_type.jpeg"), year_end_artist_type, path = "../2_Outputs/Plots/EDA")

#### ACOUSTIC FEATURES ---------------------------------------------------------
# Distribution of Acoustic Features
# Visualizing the distribution of key acoustic features to understand their spread
features = c("acousticness", "danceability", "energy", "valence")

# Converting the dataset into a long format for easier faceting
df_acoustic_features_long = df_acoustic_features %>%
  select(all_of(features)) %>%
  pivot_longer(cols = everything(), names_to = "feature", values_to = "value") %>%
  rename("Acoustic Features" = 'feature')

# Density plot for feature distributions
feature_distribution = ggplot(df_acoustic_features_long, aes(x = value, fill = `Acoustic Features`)) +
  geom_density(alpha = 0.6) +
  facet_wrap(~`Acoustic Features`, scales = "free") +
  labs(
    title = "Distribution of Key Acoustic Features", 
    x = "Feature Value", 
    y = "Density"
  ) +
  theme(
    strip.text = element_text(size = 13, face = "bold"),
    axis.text.x = element_text(size = 10, face = 'bold'),
    axis.text.y = element_text(size = 10, face = 'bold')
  )

plot(feature_distribution)
ggsave(paste0("feature_distribution.jpeg"), feature_distribution, path = "../2_Outputs/Plots/EDA")

# Tempo vs. Energy Scatter Plot
# Analyzing the relationship between tempo and energy
tempo_vs_energy = ggplot(df_acoustic_features, aes(x = tempo, y = energy)) +
  geom_point(alpha = 0.5, color = "blue") +
  geom_smooth(method = "lm", color = "red", linetype = "dashed") +
  labs(
    title = "Relationship Between Tempo and Energy",
    x = "Tempo (BPM)",
    y = "Energy Level"
  )

plot(tempo_vs_energy)
ggsave(paste0("tempo_vs_energy.jpeg"), tempo_vs_energy, path = "../2_Outputs/Plots/EDA")

# Danceability by Time Signature
# Comparing danceability across different time signatures using a boxplot
danceability_time_signature = ggplot(df_acoustic_features, aes(x = factor(time_signature), y = danceability, fill = factor(time_signature))) +
  geom_boxplot(alpha = 0.7) +
  labs(
    title = "Danceability by Time Signature",
    x = "Time Signature",
    y = "Danceability"
  ) +
  theme(legend.position = "none")
plot(danceability_time_signature)
ggsave(paste0("danceability_by_time_signature.jpeg"), danceability_time_signature, path = "../2_Outputs/Plots/EDA")

# Heatmap for Acousticness and Energy by Key and Mode
# Creating grouped data for heatmap visualization
heatmap_data = df_acoustic_features %>%
  group_by(key, mode) %>%
  summarise(
    avg_acousticness = mean(acousticness, na.rm = TRUE),  # Average acousticness by key and mode
    avg_energy = mean(energy, na.rm = TRUE)  # Average energy by key and mode
  )

# Heatmap for Acousticness
heatmap_acousticness = ggplot(heatmap_data, aes(x = factor(key), y = factor(mode), fill = avg_acousticness)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(
    low = "blue", high = "red", mid = "white", midpoint = 0.5, name = "Acousticness"
  ) +
  labs(
    title = "Average Acousticness by Key and Mode",
    x = "Key",
    y = "Mode"
  )

plot(heatmap_acousticness)
ggsave(paste0("heatmap_acousticness.jpeg"), heatmap_acousticness, path = "../2_Outputs/Plots/EDA")

# Heatmap for Energy
heatmap_energy = ggplot(heatmap_data, aes(x = factor(key), y = factor(mode), fill = avg_energy)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(
    low = "blue", high = "red", mid = "white", midpoint = 0.5, name = "Energy"
  ) +
  labs(
    title = "Average Energy by Key and Mode",
    x = "Key",
    y = "Mode"
  ) +
  theme_minimal()

plot(heatmap_energy)
ggsave(paste0("heatmap_energy.jpeg"), heatmap_energy, path = "../2_Outputs/Plots/EDA")