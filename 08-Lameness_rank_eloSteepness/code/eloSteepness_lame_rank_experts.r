library(EloRating)
library(EloSteepness)
library(RColorBrewer)
library(irr)
library(viridis)
library(tidyverse)
library(ggforce)
source("eloSteepness_helpers.R")

# load in the data
expert_dir <- "../../05-Amazon_MTurk_expert_response_30cow_pairwise/results/all_experts/"
winner_loser <- read.csv(paste0(expert_dir, "winner_loser_merged_DW_NV_SB_TM_KI.csv"), header = TRUE, sep = ",")
winner_loser_no_slip <- winner_loser[-which((winner_loser$winner %in% c(4035)) | (winner_loser$loser %in% c(4035))),]

expert_gs_dir <- "../../03-30cow_GS_label_expert_response/results/"
gs_record <- read.csv(paste0(expert_gs_dir, "gs_response_combined_avg.csv"), header = TRUE, sep = ",")
gs_record2 <- gs_record[, c("Cow", "GS")]

output_dir <- "../results/"
#click_worker_experts <- read.csv(paste0(output_dir, "compare_summary.csv"), header = TRUE, sep = ",")

# replicate row is degree > 1
winner_loser_degree_replct <- replicate_row_df(winner_loser)

################################################################################
############# handle tie by duplicate row and flip winner loser#################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed <- swap_winner_loser(winner_loser, FALSE)
click_worker_experts <- random_elo_steep(winn_loser_processed, gs_record2, output_dir, "all", "experts", gs_record2)
#click_worker_experts <- random_elo_steep(winn_loser_processed, click_worker_experts, output_dir, "all", "experts", gs_record2)

################################################################################
############# handle tie by duplicate row and flip winner loser#################
######################## individual expert rank: Dan ###########################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_ind <- winn_loser_processed[which(winn_loser_processed$expert == "DW"),]
click_worker_experts <- random_elo_steep(winn_loser_ind, click_worker_experts, output_dir, "DW", "experts", gs_record2)

################################################################################
############# handle tie by duplicate row and flip winner loser#################
######################## individual expert rank: Wali ##########################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_ind <- winn_loser_processed[which(winn_loser_processed$expert == "WS"),]
click_worker_experts <- random_elo_steep(winn_loser_ind, click_worker_experts, output_dir, "WS", "experts", gs_record2)

################################################################################
############# handle tie by duplicate row and flip winner loser#################
######################## individual expert rank: Nina ##########################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_ind <- winn_loser_processed[which(winn_loser_processed$expert == "NV"),]
click_worker_experts <- random_elo_steep(winn_loser_ind, click_worker_experts, output_dir, "NV", "experts", gs_record2)

################################################################################
############# handle tie by duplicate row and flip winner loser#################
######################## individual expert rank: Sarah ##########################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_ind <- winn_loser_processed[which(winn_loser_processed$expert == "SB"),]
click_worker_experts <- random_elo_steep(winn_loser_ind, click_worker_experts, output_dir, "SB", "experts", gs_record2)

################################################################################
############# handle tie by duplicate row and flip winner loser#################
######################## individual expert rank: Tiago #########################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_ind <- winn_loser_processed[which(winn_loser_processed$expert == "TM"),]
click_worker_experts <- random_elo_steep(winn_loser_ind, click_worker_experts, output_dir, "TM", "experts", gs_record2)

################################################################################
############# handle tie by duplicate row and flip winner loser#################
######################## individual expert rank: Kiyomi ########################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_ind <- winn_loser_processed[which(winn_loser_processed$expert == "KI"),]
click_worker_experts <- random_elo_steep(winn_loser_ind, click_worker_experts, output_dir, "KI", "experts", gs_record2)

################################################################################
############# handle tie by duplicate row and flip winner loser#################
############ individual expert rank: Nina & Dan & SB & KI #################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_ind <- winn_loser_processed[which((winn_loser_processed$expert == "NV") | (winn_loser_processed$expert == "DW") | (winn_loser_processed$expert == "SB") |  (winn_loser_processed$expert == "KI")),]
click_worker_experts <- random_elo_steep(winn_loser_ind, click_worker_experts, output_dir, "NV_DW_SB_KI", "experts", gs_record2)

################################################################################
########################## take degree into consideration + ####################
############# handle tie by duplicate row and flip winner loser#################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed_degree_replt <- swap_winner_loser(winner_loser_degree_replct, FALSE)
click_worker_experts <- random_elo_steep(winn_loser_processed_degree_replt, click_worker_experts, output_dir, "weighted", "experts", gs_record2)


################################################################################
## ICC for interobserver reliability of lameness hierarchy generated by ########
############################# different experts ################################
################################################################################
expert_compare <- click_worker_experts[, c("Cow", "DW_experts_mean", "NV_experts_mean", "SB_experts_mean", "KI_experts_mean")]
expert_compare_process <- expert_compare[, 2:ncol(expert_compare)]
expert_compare_icc_value <- icc(expert_compare_process, model = "twoway", type = "agreement", unit = "single")$"value"


################################################################################
## Agreement between lameness hierarchy generated by all experts and average####
############################### gait scores ####################################
################################################################################
gs_expert_compare <- click_worker_experts[, c("Cow", "GS", "NV_DW_SB_KI_experts_mean")]
# Calculate Spearman rank correlation using cor.test
cor_test_result <- cor.test(gs_expert_compare$GS, gs_expert_compare$NV_DW_SB_KI_experts_mean, method = "spearman")

# Print the result
print(cor_test_result)

# If you want to extract and print just the correlation coefficient and the p-value
correlation_coefficient <- cor_test_result$estimate
p_value <- cor_test_result$p.value

cat("Correlation coefficient:", correlation_coefficient, "\n")
cat("P-value:", p_value, "\n")

################################################################################
## ICC for interobserver reliability of lameness hierarchy generated by ########
##################### all experts and all click worker #########################
################################################################################

# calculate the ICC between experts and click worker for lameness hierarchy
expert_worker_compare <- click_worker_experts[, c("Cow", "all_click_worker_mean", "NV_DW_SB_KI_experts_mean")]
expert_worker_compare_process <- expert_worker_compare[, 2:ncol(expert_worker_compare)]
expert_worker_compare_icc_value <- icc(expert_worker_compare_process, model = "twoway", type = "agreement", unit = "single")$"value"

# plot to compare the summed elo winning probability from experts and from crowd workers
# prepare dataset
load("../results/large files/all_click_worker_elo_baysian.rdata")
worker_basyeian <- elo_baysian_result
worker_score <- scores(worker_basyeian)
worker_score<- worker_score[, c("id", "mean", "q045", "q955")]
names(worker_score) <- c("id", "worker_mean", "worker_q045", "worker_q955")
load("../results/large files/NV_DW_SB_KI_experts_elo_baysian.rdata")
expt_basyeian <- elo_baysian_result
expt_score <- scores(expt_basyeian)
expt_score<- expt_score[, c("id", "mean", "q045", "q955")]
names(expt_score) <- c("id", "expert_mean", "expert_q045", "expert_q955")
# merge the worker and expert summed Elo winning probability
worker_expt_sum <- merge(worker_score, expt_score)

# Create the plot
elo_plot <- ggplot(worker_expt_sum, aes(x = expert_mean, y = worker_mean)) +
  geom_point(aes(color = id), alpha = 0.9) +
  geom_ellipse(aes(x0 = (expert_q045 + expert_q955) / 2,
                   y0 = (worker_q045 + worker_q955) / 2,
                   a = (expert_q955 - expert_q045) / 2,
                   b = (worker_q955 - worker_q045) / 2,
                   angle = 0,
                   fill = id), alpha = 0.3, color = NA)  +
  labs(
    x = "Summed Elo winning probability \nfrom experienced assessors",
    y = "Summed Elo winning \nprobability from crowd workers"
  ) +
  guides(
    color = "none",  # hide the color legend
    fill = "none"    # hide the fill legend
  ) +
  theme_classic() +
  theme(
    text = element_text(size = 30),
    axis.text.x = element_text(size = 25),
    axis.text.y = element_text(size = 25)
  ) +
  scale_x_continuous(limits = c(1, 30)) +
  scale_y_continuous(limits = c(1, 30))

# Save the plot
ggsave("../plots/expert_crowd_worker_hiearchy_compare_NV_DW_SB_KI.png", plot = elo_plot, width = 10, height = 8, limitsize = FALSE)


