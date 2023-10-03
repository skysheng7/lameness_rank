library(EloRating)
library(EloSteepness)
library(RColorBrewer)
source("eloSteepness_helpers.R")

# load in the data
expert_dir <- "../../05-Amazon_MTurk_expert_response_30cow_pairwise/results/all_experts/"
winner_loser <- read.csv(paste0(expert_dir, "winner_loser_merged.csv"), header = TRUE, sep = ",")
winner_loser_no_slip <- winner_loser[-which((winner_loser$winner %in% c(4035)) | (winner_loser$loser %in% c(4035))),]

expert_gs_dir <- "../../03-30cow_GS_label_expert_response/results/"
gs_record <- read.csv(paste0(expert_gs_dir, "gs_response_combined_avg.csv"), header = TRUE, sep = ",")
gs_record2 <- gs_record[, c("Cow", "GS")]

output_dir <- "../results/"
#elo_result_master <- read.csv(paste0(output_dir, "compare_summary.csv"), header = TRUE, sep = ",")

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
################### individual expert rank: Nina & Dan & SB ####################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_ind <- winn_loser_processed[which((winn_loser_processed$expert == "NV") | (winn_loser_processed$expert == "DW") | (winn_loser_processed$expert == "SB")),]
click_worker_experts <- random_elo_steep(winn_loser_ind, click_worker_experts, output_dir, "NV_DW_SB", "experts", gs_record2)


################################################################################
########################## take degree into consideration + ####################
############# handle tie by duplicate row and flip winner loser#################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed_degree_replt <- swap_winner_loser(winner_loser_degree_replct, FALSE)
click_worker_experts <- random_elo_steep(winn_loser_processed_degree_replt, click_worker_experts, output_dir, "weighted", "experts", gs_record2)
