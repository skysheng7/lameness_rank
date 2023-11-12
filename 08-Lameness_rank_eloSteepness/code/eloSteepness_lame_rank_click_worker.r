library(EloRating)
library(EloSteepness)
library(RColorBrewer)
library(dplyr)
library(irr)
library(gridExtra) 
library(ggplot2)
source("eloSteepness_helpers.R")


# load in the data
# all 55 HITs' response
click_worker_dir <- "../../07-Amazon_MTurk_click_worker_response_30cow_pairwise/results/"
winner_loser <- read.csv(paste0(click_worker_dir, "winner_loser_55HITs.csv"), header = TRUE, sep = ",")
cowLR <- read.csv(paste0(click_worker_dir,"cowLR_response_clickWorker_55HITS.csv"), header = TRUE, sep = ",")

# each of the 55 HITs have the same number of workers
winner_loser_sampled <- read.csv(paste0(click_worker_dir,"winner_loser_sampled_55HITs.csv"), header = TRUE, sep = ",")
cowLR_sampled <- read.csv(paste0(click_worker_dir,"cowLR_response_clickWorker_sampled_55HITS.csv"), header = TRUE, sep = ",")

# 55 HITs: delete all responses between the 2 cows if average click worker response is (-1, 1)
winner_loser_sampled_delete <- read.csv(paste0(click_worker_dir,"winner_loser_sampled_delete_pairs_55HITs.csv"), header = TRUE, sep = ",")

# 55 HITs: if average click worker response is between (-1, 1) create 
# min_worker_num/2 A wins B, min_worker_num/2 B wins A
winner_loser_sampled_exchannge0 <- read.csv(paste0(click_worker_dir,"winner_loser_sampled_exchange0_55HITs.csv"), header = TRUE, sep = ",")

# 55 HITs: if average click worker response is between (-1, 1) create 
# min_worker_num/2 A wins B, min_worker_num/2 B wins A
winner_loser_sampled_ind_exchannge0 <- read.csv(paste0(click_worker_dir,"winner_loser_sampled_ind_exchange0_55HITs.csv"), header = TRUE, sep = ",")

# 5 milestone cows: min number of comparisons
winner_loser_milestone_min <- read.csv(paste0(click_worker_dir,'winner_loser_milestone_min_55HITs.csv'), header = TRUE, sep = ",")

# 5 milestone cows: maximum number of comparisons
winner_loser_milestone_max <- read.csv(paste0(click_worker_dir,'winner_loser_milestone_max_55HITs.csv'), header = TRUE, sep = ",")

# 12 rounds of expert traditional gait score
expert_gs_dir <- "../../03-30cow_GS_label_expert_response/results/"
gs_record <- read.csv(paste0(expert_gs_dir, "gs_response_combined_avg.csv"), header = TRUE, sep = ",")
gs_record2 <- gs_record[, c("Cow", "GS")]

# load experts' eloSteepness results
expert_elo_dir <-"../results/"
expert_eloSteep <- read.csv(paste0(expert_elo_dir, "compare_summary.csv"), header = TRUE, sep = ",")
expert_eloSteep$X <- NULL

output_dir <- "../results/"

click_worker_experts <- read.csv("../results/compare_summary.csv", header = TRUE)

################################################################################
################ how many responses (worker) per unique pair ###################
################################################################################
# all 54 HITs
count_worker_per_HIT <- count_unique_worker_per_HIT(cowLR)
count_worker_per_pair <- count_unique_worker_per_pair(cowLR)

# sample the same number of workers per video pair
count_worker_per_pair_sampled <- count_unique_worker_per_pair(cowLR_sampled)
min_worker_num <- min(count_worker_per_pair_sampled$worker_num)
################################################################################
############# handle tie by duplicate row and flip winner loser#################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed <- swap_winner_loser(winner_loser, FALSE)
click_worker_experts <- random_elo_steep(winn_loser_processed, expert_eloSteep, output_dir, "all", "click_worker", gs_record2)

################################################################################
################# sample same number of worker per pair ########################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed_sampled <- swap_winner_loser(winner_loser_sampled, FALSE)
click_worker_experts <- random_elo_steep(winn_loser_processed_sampled, click_worker_experts, output_dir, "sampled", "click_worker", gs_record2)

################################################################################
### delete all responses between the 2 cows if average click worker response####
############################ is between (-1, 1) ################################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed_sampled_delete <- swap_winner_loser(winner_loser_sampled_delete, FALSE)
click_worker_experts <- random_elo_steep(winn_loser_processed_sampled_delete, click_worker_experts, output_dir, "sampled_delete", "click_worker", gs_record2)

################################################################################
########## if average click worker response is between (-1, 1) create ##########
############ min_worker_num/2 A wins B, min_worker_num/2 B wins A ##############
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed_sampled_exchange0 <- swap_winner_loser(winner_loser_sampled_exchannge0, FALSE)
click_worker_experts <- random_elo_steep(winn_loser_processed_sampled_exchange0, click_worker_experts, output_dir, "sampled_exchange0", "click_worker", gs_record2)

################################################################################
########## if individual click worker response is between (-1, 1) ##############
######################### set his/her response to 0 ############################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed_sampled_ind_exchange0 <- swap_winner_loser(winner_loser_sampled_ind_exchannge0, FALSE)
click_worker_experts <- random_elo_steep(winn_loser_processed_sampled_ind_exchange0, click_worker_experts, output_dir, "sampled_ind_exchange0", "click_worker", gs_record2)

################################################################################
############################ pick 5 milestone cows #############################
## 7045 (GS 1.9), 6096 (GS 2.4), 6086(GS 2.87), 4035 (GS 3.1), 5087 (GS 3.9) ###
## use minimum number of comparisons: start comparing with the most healthy ####
## cow, stop when the current cow is more than 1 degree more healthy than the ##
################################# milestone cows ###############################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed_milestone_min <- swap_winner_loser(winner_loser_milestone_min, FALSE)
click_worker_experts <- random_elo_steep(winn_loser_processed_milestone_min, click_worker_experts, output_dir, "sampled_milestone_min", "click_worker", gs_record2)
# around 106 comparisons made
################################################################################
############################ pick 5 milestone cows #############################
## 7045 (GS 1.9), 6096 (GS 2.4), 6086(GS 2.87), 4035 (GS 3.1), 5087 (GS 3.9) ###
## use maximum number of comparisons: compare with each of the 5 milestone cows#
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed_milestone_max <- swap_winner_loser(winner_loser_milestone_max, FALSE)
click_worker_experts <- random_elo_steep(winn_loser_processed_milestone_max, click_worker_experts, output_dir, "sampled_milestone_max", "click_worker", gs_record2)
# 125 comparisons

################################################################################
####### subsampling of crowd workers after picking 5 milestone cows ############
## 7045 (GS 1.9), 6096 (GS 2.4), 6086(GS 2.87), 4035 (GS 3.1), 5087 (GS 3.9) ###
#### increment the number of crowd workers subsampled, each level 10 rounds ####
################################################################################
all_unique_cows <- unique(c(cowLR$cow_L, cowLR$cow_R))
milestone <- c(7045, 6096, 6086, 4035, 5087)
filtered_cows <- all_unique_cows[!(all_unique_cows)%in%milestone]

# incrmentally subsample 1-14 crowd workers for each video pairs, at each level
# conduct random sampling of crowd workers 10 rounds
correlation_change_df <- icc_change_worker_num_milestone(random_rounds = 10, max_worker_num = 14, 
                                cowLR, click_worker_experts,
                                expert_col_name = "NV_DW_SB_experts_mean",
                                filtered_cows, milestone, type = "min")

# calcualte the mean and SE of correlation at each level of num_of_crowd_worker
spearman_with_full_worker_sum <- avg_se(correlation_change_df, 
                                        value_var = "spearman_subsample_with_full_worker", 
                                        by_var = c("num_of_crowd_worker"))
icc_with_full_expert_sum <- avg_se(correlation_change_df, 
                                        value_var = "icc_subsample_with_full_expert", 
                                        by_var = c("num_of_crowd_worker"))
subsample_sum <- merge(spearman_with_full_worker_sum, icc_with_full_expert_sum)
correlation_change_df_sum <- merge(correlation_change_df, subsample_sum)

# Plot A
plot_A <- ggplot(correlation_change_df_sum, aes(x = num_of_crowd_worker, y = spearman_subsample_with_full_worker)) +
  geom_point(color = "lightblue", alpha = 0.5, size = 10) +
  geom_point(aes(y = spearman_subsample_with_full_worker_cor_mean), color = "dodgerblue", size = 15) +
  geom_errorbar(aes(
      x = num_of_crowd_worker,
      ymin = spearman_subsample_with_full_worker_ymin, 
      ymax = spearman_subsample_with_full_worker_ymax, 
      width = 0.2
    )
  ) + 
  labs(
    x = "Number of crowd workers",
    #y = "Spearman correlation between \nsubsampled and complete \nresponses from crowd workers"
    y = "Spearman correlation coefficient"
  ) +
  theme_classic() +
  theme(
    text = element_text(size = 60),
    axis.text.x = element_text(size = 60)
  ) +
  scale_y_continuous(limits = c(0.5, 1), expand = expansion(mult = c(0, .1)))

# Plot B
plot_B <- ggplot(correlation_change_df_sum, aes(x = num_of_crowd_worker, y = icc_subsample_with_full_expert)) +
  geom_point(color = "lightblue", alpha = 0.5, size = 10) +
  geom_point(aes(y = icc_subsample_with_full_expert_cor_mean), color = "dodgerblue", size = 15) +
  geom_errorbar(aes(
      x = num_of_crowd_worker,
      ymin = icc_subsample_with_full_expert_cor_mean - icc_subsample_with_full_expert_cor_SE, 
      ymax = icc_subsample_with_full_expert_cor_mean + icc_subsample_with_full_expert_cor_SE, 
      width = 0.2
    )
  ) +
  labs(
    x = "Number of crowd workers",
    #y = "ICC between subsampled and \ncomplete responses from \nexperienced assessors"
    y = "ICC"
  ) +
  theme_classic() +
  theme(
    text = element_text(size = 60),
    axis.text.x = element_text(size = 60)
  ) +
  scale_y_continuous(limits = c(0.5, 1), expand = expansion(mult = c(0, .1)))

# Define the margin
margin = theme(plot.margin = unit(c(1, 1, 1, 1), "inches"))

# Add the margin to plot_A and plot_B
plot_A <- plot_A + margin
plot_B <- plot_B + margin

# Arrange the plots side by side using arrangeGrob()
combined_grob <- arrangeGrob(plot_A, plot_B, ncol=2)

# Save the combined plot
ggsave("../plots/combined_plot.png", plot = combined_grob, width = 30, height = 13, limitsize = FALSE)


################################################################################
########################### increamental subsampling ###########################
################################################################################
correlation_change_increment <- icc_change_worker_num_increamental(
  random_rounds = 10, worker_num_seq = c(2, 4, 6, 8, 10, 12, 14), unknown_freq_max = 0.9,
  cowLR_df = cowLR, click_worker_experts, expert_col_name = "NV_DW_SB_experts_mean")



