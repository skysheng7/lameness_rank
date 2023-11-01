# load packages
library(ggplot2)
library(lubridate)
library(pdftools)
library("plyr")
library(tidyverse)
library(irr)
library(corrplot)
library(clValid)
library(gridExtra)
library(grid) 
source("55HIT_easy_hard_question_assess_helpers.R")
################################################################################
################################ Load Data #####################################
################################################################################
input_dir <- "../results"
answer_dir <- "../../05-Amazon_MTurk_expert_response_30cow_pairwise/results/all_experts"
output_dir <- "../results"

# read in the worker response data
cowLR_response <- read.csv("../results/cowLR_response_clickWorker_55HITs.csv", header = TRUE)
cowLR_response_pass_pos <- read.csv("../results/cowLR_response_clickWorker_55HITs_pass_pos.csv", header = TRUE)
cowLR_response_pass_neg <- read.csv("../results/cowLR_response_clickWorker_55HITs_pass_neg.csv", header = TRUE)
cowLR_response_pass_both <- read.csv("../results/cowLR_response_clickWorker_55HITs_pass_both.csv", header = TRUE)

expert_response <- read.csv(paste0(answer_dir, "/all_HIT_answer_DW_NV_SB_TM.csv"), header = TRUE)
cowlR_expert <- read.csv(paste0(answer_dir, "/cowLR_response_DW_NV_SB_TM.csv"), header = TRUE)
colnames(cowlR_expert)[colnames(cowlR_expert) == "expert"] <- "Worker_id"

################################################################################
################################### cleaning ###################################
################################################################################
# delete those who clicked the same answer across all questions in a HIT
cowLR_response <- delete_worker_answer_same(cowLR_response) 
cowLR_response_pass_pos <- delete_worker_answer_same(cowLR_response_pass_pos) 
cowLR_response_pass_neg <- delete_worker_answer_same(cowLR_response_pass_neg) 
cowLR_response_pass_both <- delete_worker_answer_same(cowLR_response_pass_both) 

################################################################################
################################# All experts ##################################
################################################################################
############## experienced assessor interoserver reliability ###################
expert_dat_reshaped <- reshape(cowlR_expert, idvar = c("cow_L","cow_R"), timevar = "Worker_id", direction = "wide")
expert_icc_value <- compute_icc_for_data(expert_dat_reshaped)

# easy and hard questions
results <- seperate_easy_hard_q_reshape(cowlR_expert, expert_response)
expert_easy_reshaped <- results$easy_reshaped
expert_hard_reshaped <- results$hard_reshaped

icc_values_inter_easy <- icc(expert_easy_reshaped[, 3:ncol(expert_easy_reshaped)],model = "twoway", type = "agreement", unit = "single")$value
icc_values_inter_hard <- icc(expert_hard_reshaped[, 3:ncol(expert_hard_reshaped)],model = "twoway", type = "agreement", unit = "single")$value


################################################################################
################################# All worker ###################################
################################################################################
############## click worker interoserver reliability for each HIT ##############
# inter-click worker ICC
result <- compute_inter_rater_ICC(cowLR_response, delete_same_answer = TRUE)
worker_compare <- result$worker_compare 
icc_summary <- result$icc_summary  
print(icc_summary)

######## click worker average VS expert average interoserver reliability #######
# get the average response from click worker VS experts
compare_click_worker_expert <- compute_icc_click_worker_expert(cowLR_response, expert_response, "all worker")
# calculate and plot direct_pct
worker_response_summary <- calculate_and_plot_direct_pct(worker_compare, compare_click_worker_expert, "all worker")
  
# calculate sd for each question
click_worker_response_sd_expert_avg <- compare_click_worker_sd_and_expert_avg(cowLR_response, expert_response)
plot(click_worker_response_sd_expert_avg$expert_avg,click_worker_response_sd_expert_avg$click_worker_sd,
     ylab="click worker response SD",xlab="Average expert rating",xlim=c(-3,3),ylim=c(0, 3),
     pch=19, frame.plot=F)

# test plot average click worker response VS directionality percentage
worker_response_summary$q_type <- "easy"
worker_response_summary$q_type[which(abs(worker_response_summary$expert_avg) <1)] <- "hard"
color_mapping <- c(easy = "green", hard = "red")
plot(worker_response_summary$click_worker_avg, worker_response_summary$dirct_pct,
     ylab = "click worker directionaltiy percentage",
     xlab = "click worker avg",
     xlim = c(-3, 3),
     ylim = c(0, 100),
     col = color_mapping[worker_response_summary$q_type],
     pch = 19,
     frame.plot = F)


################################################################################
##################### workers who pass positive attention check ################
################################################################################

############## click worker interoserver reliability for each HIT ##############
result <- compute_inter_rater_ICC(cowLR_response_pass_pos,  delete_same_answer = TRUE)
worker_compare_pass_pos <- result$worker_compare 
icc_summary_pass_pos <- result$icc_summary  
print(icc_summary_pass_pos)

######## click worker average VS expert average interoserver reliability #######
compare_click_worker_expert_pass_pos <- compute_icc_click_worker_expert(cowLR_response_pass_pos, expert_response, "pass positive")
# calculate and plot direct_pct
worker_response_summary_pass_pos <- calculate_and_plot_direct_pct(worker_compare_pass_pos, compare_click_worker_expert_pass_pos,  "pass positive")


################################################################################
##################### workers who pass negative attention check ################
################################################################################

############## click worker interoserver reliability for each HIT ##############
result <- compute_inter_rater_ICC(cowLR_response_pass_neg,  delete_same_answer = TRUE)
worker_compare_pass_neg <- result$worker_compare 
icc_summary_pass_neg <- result$icc_summary  
print(icc_summary_pass_neg)

######## click worker average VS expert average interoserver reliability #######
compare_click_worker_expert_pass_neg <- compute_icc_click_worker_expert(cowLR_response_pass_neg, expert_response, "pass negative")
# calculate and plot direct_pct
worker_response_summary_pass_neg <- calculate_and_plot_direct_pct(worker_compare_pass_neg, compare_click_worker_expert_pass_neg, "pass negative")


################################################################################
####################### workers who pass both attention check ##################
################################################################################

############## click worker interoserver reliability for each HIT ##############
result <- compute_inter_rater_ICC(cowLR_response_pass_both,  delete_same_answer = TRUE)
worker_compare_pass_both <- result$worker_compare 
icc_summary_pass_both <- result$icc_summary  
print(icc_summary_pass_both)

######## click worker average VS expert average interoserver reliability #######
compare_click_worker_expert_pass_both <- compute_icc_click_worker_expert(cowLR_response_pass_both, expert_response, "pass both")
# calculate and plot direct_pct
worker_response_summary_pass_both <- calculate_and_plot_direct_pct(worker_compare_pass_both, compare_click_worker_expert_pass_both, "pass both")

################################################################################
############################## workers clustering ##############################
################################################################################
############################ all worker clustered ##############################
worker_compare_cl <- cluster_worker(worker_compare)
compare_click_worker_expert_cl <- compute_icc_click_worker_expert_cl(worker_compare_cl, expert_response, "cluster")
# calculate and plot direct_pct
worker_response_summary_cl<- calculate_and_plot_direct_pct(worker_compare_cl, compare_click_worker_expert_cl, "cluster")

################### pass positive attention check clustered ####################
worker_compare_pass_pos_cl <- cluster_worker(worker_compare_pass_pos)
compare_click_worker_expert_pass_pos_cl <- compute_icc_click_worker_expert_cl(worker_compare_pass_pos_cl, expert_response, "pass positive cluster")
# calculate and plot direct_pct
worker_response_summary_pass_pos_cl<- calculate_and_plot_direct_pct(worker_compare_pass_pos_cl, compare_click_worker_expert_pass_pos_cl, "pass positive cluster")

################### pass negative attention check clustered ####################
worker_compare_pass_neg_cl <- cluster_worker(worker_compare_pass_neg)
compare_click_worker_expert_pass_neg_cl <- compute_icc_click_worker_expert_cl(worker_compare_pass_neg_cl, expert_response, "pass negative cluster")
# calculate and plot direct_pct
worker_response_summary_pass_neg_cl<- calculate_and_plot_direct_pct(worker_compare_pass_neg_cl, compare_click_worker_expert_pass_neg_cl, "pass negative cluster")


###################### pass both attention check clustered #####################
worker_compare_pass_both_cl <- cluster_worker(worker_compare_pass_both)
compare_click_worker_expert_pass_both_cl <- compute_icc_click_worker_expert_cl(worker_compare_pass_both_cl, expert_response, "pass both cluster")
# calculate and plot direct_pct
worker_response_summary_pass_both_cl<- calculate_and_plot_direct_pct(worker_compare_pass_both_cl, compare_click_worker_expert_pass_both_cl, "pass both cluster")



