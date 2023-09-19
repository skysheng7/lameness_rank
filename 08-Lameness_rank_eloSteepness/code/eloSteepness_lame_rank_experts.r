library(EloRating)
library(EloSteepness)
library(RColorBrewer)
source("helpers.R")

# load in the data
setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/Amazon MTurk expert response/pairwise_Dan_Wali_Nina_all")
winner_loser <- read.csv("winner_loser_merged.csv", header = TRUE, sep = ",")
winner_loser_no_slip <- winner_loser[-which((winner_loser$winner %in% c(4035)) | (winner_loser$loser %in% c(4035))),]

setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results/30_cow_gs_HIT_launch")
gs_record <- read.csv("gs_response_combined_avg_Jul-15-2023.csv", header = TRUE, sep = ",")
gs_record2 <- gs_record[, c("Cow", "GS")]


setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results")
elo_result_master <- read.csv("lameness_rank_compare_summary.csv", header = TRUE, sep = ",")


# replicate row is degree > 1
# Apply the function to each row of the data frame
replicated_rows <- apply(winner_loser, 1, replicate_row)
# Remove NULL elements
replicated_rows <- replicated_rows[sapply(replicated_rows, length) > 0]
# Unlist the result and convert it back to a data frame
winner_loser_replicated <- do.call(rbind, unlist(replicated_rows, recursive = FALSE))
# Bind the replicated rows with the original data frame
winner_loser_degree_replct <- rbind(winner_loser, winner_loser_replicated)
winner_loser_degree_replct <- winner_loser_degree_replct[order(winner_loser_degree_replct$winner, winner_loser_degree_replct$loser),]


################################################################################
############# handle tie by duplicate row and flip winner loser#################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_processed <- swap_winner_loser(winner_loser, FALSE)
interaction_matrix <- with(winn_loser_processed, table(winner, loser))

# use elosteepness from matrix
elo_baysian_result <- elo_steepness_from_matrix(interaction_matrix, 
                                                      algo="original", 
                                                      cores = 4,
                                                      chains = 4,
                                                      iter = 5000, 
                                                      warmup = 1000,
                                                      seed = 88,)

# get individual's score
individual_elo_win_df <- individual_elo_win(elo_baysian_result$cumwinprobs, elo_baysian_result$ids)
score_sum <- scores(elo_baysian_result)
colnames(score_sum)[colnames(score_sum) == "id"] <- "Cow"
score_sum2 <- score_sum[, c("Cow", "mean", "sd")]
colnames(score_sum2) <- c("Cow", "EloSteep_wt_tie_mean", "EloSteep_wt_tie_sd")

elo_result_master <- merge(elo_result_master, score_sum2, all = TRUE)
elo_result_master <- elo_result_master[order(elo_result_master$EloSteep_wt_tie_mean, decreasing = TRUE), ]

plot_scores(elo_baysian_result, gs_record2)


setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results/elo_steepness_rank")
write.csv(score_sum2, file = "lame_rank_randomized_EloSteep_summary_with_tie.csv", row.names = FALSEc)
write.csv(individual_elo_win_df, file = "lame_rank_randomized_EloSteep_individual_score_with_tie.csv", row.names = FALSE)

setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results")
write.csv(elo_result_master, file = "lameness_rank_compare_summary.csv", row.names = FALSE)


################################################################################
########################## take degree into consideration + ####################
############# handle tie by duplicate row and flip winner loser#################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_Dan_processed <- swap_winner_loser(winner_loser_degree_replct, FALSE)
interaction_matrix <- with(winn_loser_Dan_processed, table(winner, loser))

# use elosteepness from matrix
elo_baysian_result_degree_replt <- elo_steepness_from_matrix(interaction_matrix, 
                                                algo="original", 
                                                cores = 4,
                                                chains = 4,
                                                iter = 5000, 
                                                warmup = 1000,
                                                seed = 88,)

# get individual's score
individual_elo_win_df_degree <- individual_elo_win(elo_baysian_result_degree_replt$cumwinprobs, elo_baysian_result_degree_replt$ids)
score_sum_degree_replt <- scores(elo_baysian_result_degree_replt)
colnames(score_sum_degree_replt)[colnames(score_sum_degree_replt) == "id"] <- "Cow"
score_sum_degree_replt2 <- score_sum_degree_replt[, c("Cow", "mean", "sd")]
colnames(score_sum_degree_replt2) <- c("Cow", "EloSteep_wt_tie_degree_replt_mean", "EloSteep_wt_tie_degree_replt_sd")

elo_result_master <- merge(elo_result_master, score_sum_degree_replt2, all = TRUE)
elo_result_master <- elo_result_master[order(elo_result_master$EloSteep_wt_tie_degree_replt_mean, decreasing = TRUE), ]


plot_scores(elo_baysian_result_degree_replt, gs_record2)


setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results/elo_steepness_rank")
write.csv(score_sum_degree_replt2, file = "lame_rank_randomized_EloSteep_summary_with_tie_degree_replt.csv", row.names = FALSE)
write.csv(individual_elo_win_df_degree, file = "lame_rank_randomized_EloSteep_individual_score_with_tie_degree_replt.csv", row.names = FALSE)

setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results")
write.csv(elo_result_master, file = "lameness_rank_compare_summary.csv", row.names = FALSE)


################################################################################
######### EloSteepness with average response from multiple worker ##############
################################################################################
setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/Amazon MTurk expert response/pairwise_Dan_Wali_Nina_all")
winner_loser <- read.csv("winner_loser_avg.csv", header = TRUE, sep = ",")

# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_Dan_processed <- swap_winner_loser(winner_loser, FALSE)
interaction_matrix <- with(winn_loser_Dan_processed, table(winner, loser))

# use elosteepness from matrix
elo_baysian_result <- elo_steepness_from_matrix(interaction_matrix, 
                                                algo="original", 
                                                cores = 4,
                                                chains = 4,
                                                iter = 5000, 
                                                warmup = 1000,
                                                seed = 88,)

# get individual's score
individual_elo_win_df <- individual_elo_win(elo_baysian_result$cumwinprobs, elo_baysian_result$ids)
score_sum <- scores(elo_baysian_result)
colnames(score_sum)[colnames(score_sum) == "id"] <- "Cow"
score_sum2 <- score_sum[, c("Cow", "mean", "sd")]
colnames(score_sum2) <- c("Cow", "EloSteep_wt_tie_avgResp_mean", "EloSteep_wt_tie_avgResp_sd")

elo_result_master <- merge(elo_result_master, score_sum2, all = TRUE)
elo_result_master <- elo_result_master[order(elo_result_master$EloSteep_wt_tie_avgResp_mean, decreasing = TRUE), ]

plot_scores(elo_baysian_result, gs_record2)


setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results/elo_steepness_rank")
write.csv(score_sum2, file = "lame_rank_randomized_EloSteep_summary_with_tie_avgResp.csv", row.names = FALSE)
write.csv(individual_elo_win_df, file = "lame_rank_randomized_EloSteep_individual_score_with_tie_avgResp.csv", row.names = FALSE)

setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results")
write.csv(elo_result_master, file = "lameness_rank_compare_summary.csv", row.names = FALSE)



################################################################################
######### EloSteepness with average response from multiple worker ##############
####################### + < 1 degree treated as tie ############################
################################################################################
setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/Amazon MTurk expert response/pairwise_Dan_Wali_Nina_all")
winner_loser <- read.csv("winner_loser_avg.csv", header = TRUE, sep = ",")

# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
winn_loser_Dan_processed <- swap_winner_loser(winner_loser, TRUE)
interaction_matrix <- with(winn_loser_Dan_processed, table(winner, loser))

# use elosteepness from matrix
elo_baysian_result <- elo_steepness_from_matrix(interaction_matrix, 
                                                algo="original", 
                                                cores = 4,
                                                chains = 4,
                                                iter = 5000, 
                                                warmup = 1000,
                                                seed = 88,)

# get individual's score
individual_elo_win_df <- individual_elo_win(elo_baysian_result$cumwinprobs, elo_baysian_result$ids)
score_sum <- scores(elo_baysian_result)
colnames(score_sum)[colnames(score_sum) == "id"] <- "Cow"
score_sum2 <- score_sum[, c("Cow", "mean", "sd")]
colnames(score_sum2) <- c("Cow", "EloSteep_wt_tie_avgResp_lt1Tie_mean", "EloSteep_wt_tie_avgResp_lt1Tie_sd")

elo_result_master <- merge(elo_result_master, score_sum2, all = TRUE)
elo_result_master <- elo_result_master[order(elo_result_master$EloSteep_wt_tie_avgResp_lt1Tie_mean, decreasing = TRUE), ]

plot_scores(elo_baysian_result, gs_record2)


setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results/elo_steepness_rank")
write.csv(score_sum2, file = "lame_rank_randomized_EloSteep_summary_with_tie_avgResp_lt1Tie.csv", row.names = FALSE)
write.csv(individual_elo_win_df, file = "lame_rank_randomized_EloSteep_individual_score_with_tie_avgResp_lt1Tie.csv", row.names = FALSE)

setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results")
write.csv(elo_result_master, file = "lameness_rank_compare_summary.csv", row.names = FALSE)









################################################################################
############## NOT USED : handle tie by delete degree = 0 ######################
################################################################################
# handle ties: delete all the degree = 0
winn_loser_Dan_processed_no_tie <- winn_loser_Dan_processed[which(winn_loser_Dan_processed$degree!= 0),]
# Convert winner and loser to factors with the same levels
all_ids <- unique(c(winn_loser_Dan_processed_no_tie$winner, winn_loser_Dan_processed_no_tie$loser))
winn_loser_Dan_processed_no_tie$winner <- factor(winn_loser_Dan_processed_no_tie$winner, levels = all_ids)
winn_loser_Dan_processed_no_tie$loser <- factor(winn_loser_Dan_processed_no_tie$loser, levels = all_ids)
interaction_matrix_no_tie <- with(winn_loser_Dan_processed_no_tie, table(winner, loser))

# use elosteepness from matrix, sequence does not matter
elo_baysian_result <- elo_steepness_from_matrix(interaction_matrix_no_tie, 
                                                algo="original", 
                                                cores = 4,
                                                chains = 4,
                                                iter = 7000, 
                                                warmup = 2000,
                                                seed = 88)

# get individual's score
individual_elo_win_df <- individual_elo_win(elo_baysian_result$cumwinprobs, elo_baysian_result$ids)
score_sum <- scores(elo_baysian_result)
colnames(score_sum)[colnames(score_sum) == "id"] <- "Cow"
score_sum2 <- merge(score_sum, gs_record, all = TRUE)
score_sum2 <- score_sum2[order(score_sum2$mean, decreasing = TRUE), ]

plot_scores(elo_baysian_result, gs_record2)


setwd("C:/Users/skysheng/OneDrive - The University Of British Columbia/University of British Columbia/Research/PhD Project/Amazon project phase 2/results/elo_steepness_rank")
write.csv(score_sum2, file = "lame_rank_randomized_EloSteep_summary_no_tie.csv")
write.csv(individual_elo_win_df, file = "lame_rank_randomized_EloSteep_individual_score_no_tie.csv")



