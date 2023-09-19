# load experts' pairwise response
setwd("/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/Amazon MTurk expert response/pairwise_Dan_Wali_Nina_all")
response_d <- read.csv("cowLR_response_Dan.csv", header = TRUE)
response_w <- read.csv("cowLR_response_Wali.csv", header = TRUE)

# calculate the SD and mean of each pair
response <- rbind(response_d, response_w)
summary_sd <- aggregate(response$response, by = list(response$cow_L, response$cow_R), FUN = sd)
summary_mean <- aggregate(response$response, by = list(response$cow_L, response$cow_R), FUN = mean)
colnames(summary_sd) <- c("cow_L", "cow_R", "response_sd")
colnames(summary_mean) <- c("cow_L", "cow_R", "response_mean")
summary_mean$response_mean_abs <- abs(summary_mean$response_mean)
summary2 <- merge(summary_sd, summary_mean)

# identify easy question, if the mean response >= 2, and SD < 0.8;
easy_q <- summary2[which((summary2$response_mean_abs >= 2) & (summary2$response_sd < 0.8)),]
# identify medium easy question, if the mean response == 1.5, and SD < 0.8
medium_q <- summary2[which((summary2$response_mean_abs == 1.5) & (summary2$response_sd < 0.8)),]
# we don't always want the same cows that show up multiple times in easy_q, sample other cows
medium_q_sub <- medium_q[-which((medium_q$cow_L == 5087) | (medium_q$cow_R == 5087) | (medium_q$cow_L == 4035) | (medium_q$cow_R == 4035)),]

# randomly sample 6 rows from easy_q
library(dplyr)
set.seed(19)
easy_q_sample1 <- easy_q[which(easy_q$cow_R == 4035),]
easy_q_5087 <- easy_q[-which(easy_q$cow_R == 4035),]
easy_q_sample2 <- sample_n(easy_q_5087, 4)
easy_q_sample <- rbind(easy_q_sample1, easy_q_sample2)

# randomly sample 6 rows from medium_q_sub
medium_q_sub_sample <- sample_n(medium_q_sub, 5)

# all sampled questions
sampled_q <- rbind(easy_q_sample, medium_q_sub_sample)

# add a negative attention check
#set.seed(70)
#neg_cow <- sample(sampled_q$cow_L, 1)
#new_row <- data.frame(
#  cow_L = neg_cow,  # Replace with the actual value
#  cow_R = neg_cow,  # Replace with the actual value
#  response_sd = 0,  # Replace with the actual value
#  response_mean = 0,  # Replace with the actual value
#  response_mean_abs = 0  # Replace with the actual value
#)
# Add the new row to the data frame
#sampled_q <- rbind(sampled_q, new_row)


# randomly shuffle the rows
sampled_q <- sample_n(sampled_q, nrow(sampled_q))
rownames(sampled_q) <- NULL

setwd("/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/Amazon MTurk expert response")
write.csv(sampled_q, file = "test_HIT_q.csv", row.names = FALSE)
write.csv(summary2, file = "all_HIT_answer_wali_dan.csv", row.names = FALSE)
