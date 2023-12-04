library(lubridate)
library(ggplot2)
library(irr)
source("combine_5experts_rating_helper.R")
gs_p1 <- read.csv("../results/gs_response_Aug-12-2023.csv", header = TRUE)
gs_p2 <- read.csv("../results/gs_response_Wali_Jul-10-2023.csv", header = TRUE)
gs_p3 <- read.csv("../results/gs_response_Wali_Jul-14-2023.csv", header = TRUE)
gs_p4 <- read.csv("../results/gs_response_Wali_Jul-18-2023.csv", header = TRUE)
gs_p5 <- read.csv("../results/gs_response_Sep-10-2023.csv", header = TRUE)

gs <- rbind(gs_p1, gs_p2)
gs <- rbind(gs, gs_p3)
gs <- rbind(gs, gs_p4)
gs <- rbind(gs, gs_p5)

# remove worker "SB" as she used a different lameness assessment method than the other workers
gs <- gs[which(gs$Worker_id != "SB"),]

######################## GS average processing #################################
# take the avearge across all experts for each cow
gs_avg <- aggregate(gs$GS, by = list(gs$Cow), FUN = mean)
colnames(gs_avg) <- c("Cow", "GS")

###################### intraobserver reliability ###############################
# you can only calculate intraobserver reliability if the expert answered >=2 times
temp <- gs[which(gs$Cow == 4008),]
expert_retain <- unique(temp$Worker_id[duplicated(temp$Worker_id)])
gs_retain <- gs[which(gs$Worker_id %in% expert_retain),]
gs_retain <- gs_retain[, c("Cow", "Worker_id", "GS_round", "GS")]

# calculate intraobserver reliability using iCC
# Get the unique worker IDs
workers <- unique(gs_retain$Worker_id)

# Initialize an empty vector to store the ICC for each worker
icc_values <- numeric(length(workers))

# Loop over each unique worker
for (i in seq_along(workers)) {
  # Subset the data for the current worker
  worker_data <- gs_retain[gs_retain$Worker_id == workers[i], ]
  
  # Reshape the data to wide format, with one row per cow and one column per observation
  worker_data_wide <- reshape(worker_data, idvar = c("Worker_id", "Cow"), timevar = "GS_round", direction = "wide")
  
  # Calculate the ICC for the current worker
  icc_result <- icc(worker_data_wide[, 3:ncol(worker_data_wide)],model = "twoway", type = "agreement", unit = "single")
  
  # Store the ICC value
  icc_values[i] <- icc_result$value
}

# Combine the worker IDs and ICC values into a data frame
icc_df <- data.frame(Worker_id = workers, ICC = icc_values)
icc_mean <- mean(icc_df$ICC)
icc_sd <- sd(icc_df$ICC)

### interobserver reliability calculated independetly for each of the 3 rounds##
inter_ICC_by_rounds <- interobserver_ICC_per_round_df(gs)
mean(inter_ICC_by_rounds$interobserver_ICC)
sd(inter_ICC_by_rounds$interobserver_ICC)

################# average scores from 3 rounds for each expert #################
######################## then calculate interobserver ##########################
score_avg_by_expert <- aggregate(gs$GS, by = list(gs$Cow, gs$Worker_id), FUN = mean)
colnames(score_avg_by_expert) <- c("Cow", "Worker_id", "GS")
inter_ICC_by_avg_score <- interobserver_ICC_per_round(score_avg_by_expert)

## progressively sample 1 to 4 assessors, and 1 to 3 rounds from full dataset ##
##### compare the agreement between average of subsampled score and avergae ####
################# from full set of 5 assessor & 3 rounds #######################
cor_change_df <- spearman_change_rounds_expert_num(gs) 
cor_se_df <- aggregate(cor_change_df$cor_subsample_with_full, by = list(cor_change_df$num_of_experts, cor_change_df$num_of_rounds), FUN = standard_error)
colnames(cor_se_df) <- c("num_of_experts", "num_of_rounds", "cor_SE")
cor_mean_df <- aggregate(cor_change_df$cor_subsample_with_full, by = list(cor_change_df$num_of_experts, cor_change_df$num_of_rounds), FUN = mean)
colnames(cor_mean_df) <- c("num_of_experts", "num_of_rounds", "cor_mean")
cor_mean_se_df <- merge(cor_mean_df, cor_se_df)
cor_mean_se_df <- cor_mean_se_df[-which((cor_mean_se_df$num_of_experts == 5) & (cor_mean_se_df$num_of_rounds == 3)),]

# plot the cor_mean_se_df
# Convert num_of_rounds to a factor
cor_mean_se_df$num_of_rounds_factor <- factor(cor_mean_se_df$num_of_rounds)

# Create a ggplot
cor_plot <- ggplot(cor_mean_se_df, aes(x = num_of_experts, y = cor_mean)) +
  geom_point(aes(size = num_of_rounds_factor, color = num_of_rounds_factor, alpha = 0.9)) + # Added alpha for transparency
  geom_errorbar(aes(ymin = cor_mean - cor_SE, ymax = cor_mean + cor_SE, width = 0.2)) + # Added geom_errorbar for SE error bars
  scale_size_manual(values = c(`1` = 10, `2` = 15, `3` = 20)) +
  scale_color_manual(values = c(`1` = "lightblue", `2` = "dodgerblue", `3` = "darkblue")) +
  labs(
    x = "Number of assessors",
    y = expression(atop(paste(r[s], " between subsampled"), "and complete responses")),
    size = "Number \nof rounds",
    color = "Number \nof rounds"
  ) +
  guides(
    color = guide_legend(override.aes = list(size = c(10, 15, 20), alpha = 0.7)),
    size = "none",  # hide the size legend
    alpha = "none"  # hide the alpha legend
  ) +
  theme_classic() +
  theme(
    text = element_text(size = 50),
    axis.text.x = element_text(size = 50)
  ) +
  scale_y_continuous(limits = c(0.5, 1), expand = expansion(mult = c(0, .1)))  # Set y-axis limits


# Save the plot
ggsave("../plots/cor_change_by_round_expert_num.png", plot = cor_plot, width = 15, height = 13, limitsize = FALSE)

write.csv(gs, file = "../results/gs_response_combined.csv")
write.csv(gs_avg, file = "../results/gs_response_combined_avg.csv")
write.csv(icc_df, file = "../results/intraobserver_reliability.csv")
write.csv(inter_ICC_by_rounds, file = "../results/interobserver_reliability_by_rounds.csv")
write.csv(cor_mean_se_df, file = "../results/cor_change_by_round_expert_num.csv")

