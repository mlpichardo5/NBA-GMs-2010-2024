library(tidyverse)
library(ggplot2)
library(dplyr)
library(stringr)
library(readr)


NBA_GMS_Temp_Final <- read_csv("C:/Users/lucas/Downloads/PERSONAL_PROJECTS/NBA_GMS_Temp_Final")
NBA_GMS_Temp_Final

# Rather than manually editing the data set in sheets and reloading the csv file, I am going to make my changes here. I need to convert all the "Unknown" columns to NA and then filter out NA. 
NBA_GMs_Cleaned <- NBA_GMS_Temp_Final |>
  mutate(
    Regular_Season_Winning_Percentage = na_if(Regular_Season_Winning_Percentage, 'Unknown'),
    Playoff_Winning_Percentage = na_if(Playoff_Winning_Percentage, 'Unknown'),
    Playoff_Appearances = na_if(Playoff_Appearances, 'Unknown'),
    Championships = na_if(Championships, 'Unknown')
  )

# Now I am going to convert it to numeric. 
NBA_GMs_Numeric <- NBA_GMs_Cleaned |> 
  mutate(
    Regular_Season_Winning_Percentage = as.numeric(Regular_Season_Winning_Percentage),
    Playoff_Winning_Percentage = as.numeric(Playoff_Winning_Percentage),
    Playoff_Appearances = as.numeric(Playoff_Appearances),
    Championships = as.numeric(Championships)
  )

# Now I am going to filter out the NA values 
NBA_GMs_Numeric <- NBA_GMs_Numeric |> 
  filter(!is.na(Regular_Season_Winning_Percentage) & 
           !is.na(Playoff_Winning_Percentage) & 
           !is.na(Playoff_Appearances) & 
           !is.na(Championships))

# Since my data is all squared away, I am going to create a weighted average variable called the General Manager Success Index, or GMSI, to quantify success. 
NBA_GMs_GMSI <- NBA_GMs_Numeric |>
  mutate(
    GMSI = ((Tenure / 24) * 0.1) + 
      (Regular_Season_Winning_Percentage * 0.15) + 
      (Playoff_Winning_Percentage * 0.25) + 
      ((Playoff_Appearances / Tenure) * 0.1) + 
      (((Championships / Tenure + 1) / 0.28) * 0.35) - 
      (((Tenure / 24) * (1 - Championships)) * 0.05)
    
  )
# I now have a metric that measures success.
NBA_GMs_GMSI |> arrange(desc(GMSI)) |> relocate(GMSI)
relocate(GMSI)

# I simply calculated the mean using the mean function.
summary(NBA_GMS_Temp_Final$Tenure)

# Now I am going to compare GMSI between those who exceed 5.4 years and those who do not by calculating average GMSI for tenure groups
GMSI_summary <- NBA_GMs_GMSI |>
  mutate(Tenure_Group = ifelse(Tenure > 5.7, "Above 5.7 Years", "Below 5.7 Years")) |>
  group_by(Tenure_Group) |>
  summarise(Average_GMSI = mean(GMSI))

# Now I will create the graph
GMSI_summary |> ggplot(aes(x = Tenure_Group, y = Average_GMSI, fill = Tenure_Group)) +
  geom_col(width = 0.6) +
  labs(
    title = "Average GMSI by Tenure Group",
    x = "Tenure Group",
    y = "Average GMSI"
  ) +
  scale_fill_viridis_d(option = "C") +
  theme_minimal()


# Here I create a frequency table to give me the mode of the categorical variable.
created_table <- table(NBA_GMS_Temp_Final$Team)
# Then I found the mode of the table.
max_freq <- max(created_table)
max_freq
# max_freq outputs a value of 5, meaning that the mode of the table is 5. I then used this information to extract the actual names of the variables that occurred five times in the table below.
most_frequent_team <- names(created_table[created_table == max_freq])
# This is me printing the value.
most_frequent_team

# Calculate average GMSI for each of the four teams and league average
team_analysis <- NBA_GMs_GMSI |>
  filter(Team %in% c("Knicks", "Hawks", "Pistons", "Timberwolves")) |>
  group_by(Team) |>
  summarise(Average_GMSI = mean(GMSI)) |>
  bind_rows(
    NBA_GMs_GMSI |>
      summarise(Team = "League Average", Average_GMSI = mean(GMSI))
  )

# Create the graph
team_analysis |> ggplot(aes(x = reorder(Team, -Average_GMSI), y = Average_GMSI, fill = Team)) +
  geom_col(width = 0.6) +
  labs(
    title = "Average GMSI: Knicks, Hawks, Pistons, Timberwolves vs League Average",
    x = "Team",
    y = "Average GMSI"
  ) +
  scale_fill_viridis_d(option = "B", direction = -1) +
  theme_minimal()


# First I need to create a new data set that has a filtered "Colleges" column that only has colleges that appear more than once. 
filtered_colleges_NBA_GMS <- NBA_GMS_Temp_Final |> add_count(College) |> filter(n > 1)
# Now I am going to create a bar graph to display this data. I want to fill by the NCAA variable to see how many of these GMs played for their schools' basketball team. 
filtered_colleges_NBA_GMS |>
  ggplot(aes(x = reorder(College, -n), fill = NCAA)) +
  geom_bar() +
  coord_flip() +
  labs(
    title = "Colleges Producing NBA GMs",
    subtitle = "Colleges appearing more than once, with NCAA playing history",
    x = "College",
    y = "Number of GMs"
  ) +
  scale_fill_viridis_d(option = "D") +
  theme_minimal()

# I wanted to see which college had the most amount of GMs who didn't play college basketball, which I found below. 
filtered_colleges_NBA_GMS |> count(NCAA)
NBA_GMS_Temp_Final |> filter(College == "Northwestern") |> filter(NCAA == "N")


# First I will make a new filtered data set so that I can easily create a graph. 
NBA_GMS_filtered_by_degree <- NBA_GMS_Temp_Final |> add_count(Degree_Name) |> filter(NCAA == "N") |> filter(Pro == "N") |> filter(Degree_Name != "Unknown")
# Now I will create a bar graph 
NBA_GMS_filtered_by_degree |>
  ggplot(aes(x = reorder(Degree_Name, -n))) +
  geom_bar(fill = "#2C3E50") +
  coord_flip() +
  labs(
    title = "Undergraduate Majors of Non-NCAA GMs",
    subtitle = "Only GMs who did not play NCAA or professional basketball",
    x = "Degree Name",
    y = "Number of GMs"
  ) +
  theme_minimal()


# I will once again make an modified data set to create my graph. 
NBA_GMS_work_experience <- NBA_GMS_Temp_Final |> add_count(Job_History, Job_History_II, Job_History_III, Job_History_IV, Job_History_V, Job_History_VI, Job_History_VII) |> filter(NCAA == "N") |> filter(Pro == "N") 

# Now I will make a column that includes all of the job history values. To do this, I am going to have a new data set that is not tidy.  
job_history_long <- NBA_GMS_work_experience |> 
  select(Name, 
         Job_History_1 = Job_History, 
         Job_History_2 = Job_History_II, 
         Job_History_3 = Job_History_III, 
         Job_History_4 = Job_History_IV, 
         Job_History_5 = Job_History_V, 
         Job_History_6 = Job_History_VI, 
         Job_History_7 = Job_History_VII) |> 
  pivot_longer(cols = starts_with('Job_History'), 
               names_to = 'Job_History_Type', 
               values_to = 'Job_History') |>
  filter(Job_History != 'Unknown') 

# Count occurrences of each job history. I am doing this because in the code above, I realized that the graph will be unreadable since there's so many observations. I am therefore going to filter the data to display jobs that occur more than once. 
job_history_counts <- job_history_long |>
  group_by(Job_History) |> 
  summarise(Count = n()) |>
  filter(Count > 1)

# Filtered the original data set to include only job histories that occur more than once
filtered_job_history_long <- job_history_long |>
  filter(Job_History %in% job_history_counts$Job_History)

# Now I will create a graph displaying their job histories along with when in their respective careers they occurred. 
filtered_job_history_long |> 
  ggplot(aes(x = Job_History, fill = Job_History_Type)) + 
  geom_bar(position = 'dodge', width = 0.7) + 
  coord_flip() + 
  theme(text = element_text(size = 14), 
        axis.text.y = element_text(size = 12), 
        plot.title = element_text(hjust = 0.5)) + 
  labs(title = 'Job History Distribution', subtitle = 'Of GMs who Did Not Play College or Pro', x = 'Job History', y = 'Count')


# I will now visualize the relationship between GMSI and various categorical variables. First up is GMSI and NCAA status
NBA_GMs_GMSI |>
  ggplot(aes(x = NCAA, y = GMSI, fill = NCAA)) +
  geom_boxplot() +
  labs(
    title = "GMSI by NCAA Status",
    subtitle = "Comparison of GMSI between NCAA players and non-players",
    x = "NCAA Status",
    y = "GMSI"
  ) +
  scale_fill_viridis_d(option = "B") +
  theme_minimal()

# This is GMSI and Pro Status 
NBA_GMs_GMSI |>
  ggplot(aes(x = Pro, y = GMSI, fill = Pro)) +
  geom_boxplot() +
  labs(
    title = "GMSI by Professional Experience",
    subtitle = "Comparison of GMSI between professional players and non-players",
    x = "Professional Experience",
    y = "GMSI"
  ) +
  scale_fill_viridis_d(option = "C") +
  theme_minimal()

# This is GMSI and whether or not they went to graduate school
NBA_GMs_GMSI |>
  ggplot(aes(x = Grad_School, y = GMSI, fill = Grad_School)) +
  geom_boxplot() +
  labs(
    title = "GMSI by Graduate Education",
    subtitle = "Impact of advanced degrees on GMSI",
    x = "Graduate Degree",
    y = "GMSI"
  ) +
  scale_fill_viridis_d(option = "D") +
  theme_minimal()


# This is GMSI and the most recent job the GMs had prior to being hired
NBA_GMs_GMSI |> 
  ggplot(aes(x = Job_History, y = GMSI, fill = Job_History)) +
  geom_boxplot() + 
  labs(
    title = "Relationship between GMSI and Job History",
    subtitle = "Job History being the last job they had prior to being hired",
    x = "Job History",
    y = "GMSI"
  ) +
  scale_fill_viridis_d(option = "E") +
  theme_minimal()


# Now I am going to filter out the data set again so I can analyze college degrees 
GMSI_filtered_by_degree <- NBA_GMs_GMSI |> add_count(Degree_Name) |> filter(Degree_Name != "Unknown") |> group_by(Degree_Name) |> summarise(Count = n()) |> filter(Count > 1)

GMSI_filtered_by_degree <- NBA_GMs_GMSI |>
  filter(Degree_Name %in% GMSI_filtered_by_degree$Degree_Name)

# This is the visualization of GMSI and college degrees
GMSI_filtered_by_degree |> 
  ggplot(aes(x = Degree_Name, y = GMSI, fill = Degree_Name)) +
  geom_boxplot() + 
  labs(
    title = "Relationship between GMSI and Degree",
    subtitle = "Undergraduate degree",
    x = "Degree Name",
    y = "GMSI"
  ) +
  scale_fill_viridis_d(option = "F") +
  theme_minimal()