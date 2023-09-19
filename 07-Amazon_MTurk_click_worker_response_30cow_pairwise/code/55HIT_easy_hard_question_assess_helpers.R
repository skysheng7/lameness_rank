################################################################################
############## click worker interoserver reliability for each HIT ##############
################################################################################
cowLR_process <- function(df){
  worker_res <- df
  worker_res$question_num <- paste0("q", worker_res$question_num)
  colnames(worker_res) <- c("cow_L", "cow_R", "Q_ID", "Task_number", "Worker_id","Answer" )
  return(worker_res)
}

# Filter and reshape the worker responses
reshape_worker_responses <- function(worker_res, cur_HIT, delete_NA) {
  dat1 <- worker_res[which(worker_res$Task_number == cur_HIT),]
  dat1 <- dat1[, c("cow_L", "cow_R", "Worker_id","Answer")]
  dat_reshaped <- reshape(dat1, idvar = c("cow_L","cow_R"), timevar = "Worker_id", direction = "wide")
  
  bad_cols <- colnames(dat_reshaped)[colSums(is.na(dat_reshaped)) > 0]
  
  if(delete_NA & (length(bad_cols) > 0)) {
    dat_reshaped <- dat_reshaped[, -which(colnames(dat_reshaped) %in% bad_cols)]
  }
  
  # Calculate standard deviation for each column while ignoring NA values
  sds <- apply(dat_reshaped[, 3:ncol(dat_reshaped)], 2, sd, na.rm = TRUE)
  
  # Filter columns based on standard deviation
  filtered_cols <- dat_reshaped[, 3:ncol(dat_reshaped)][, sds != 0]
  
  # Combine the first two columns with the filtered columns
  result <- cbind(dat_reshaped[, 1:2], filtered_cols)
  
  return(result)
}

# Calculate ICC for a given data
compute_icc_for_data <- function(data) {
  dat <- data[, 3:ncol(data)]
  icc_value = icc(dat, model = "twoway", type = "agreement", unit = "single")$"value"
  return(icc_value)
}

# Compute summary statistics
compute_icc_summary <- function(allworker_icc) {
  icc_mean <- mean(allworker_icc$click_worker_interobserver)
  icc_sd <- sd(allworker_icc$click_worker_interobserver)
  return(list(mean = icc_mean, sd = icc_sd))
}

compute_inter_rater_ICC <- function(df) {
  worker_res <- cowLR_process(df)
  
  # Assuming reshape_worker_responses and compute_icc_for_data 
  # functions are already defined
  
  all_HIT <- unique(worker_res$Task_number)
  worker_compare <- list()
  allworker_icc <- data.frame()
  
  for(i in 1:length(all_HIT)) {
    cur_HIT <- all_HIT[i]
    worker_compare[[i]] <- reshape_worker_responses(worker_res, cur_HIT, delete_NA = TRUE)
    
    icc_value <- compute_icc_for_data(worker_compare[[i]])
    allworker_icc <- rbind(allworker_icc, data.frame(HIT = cur_HIT, click_worker_interobserver = icc_value))
  }
  
  icc_summary <- compute_icc_summary(allworker_icc)
  
  return(list(worker_compare = worker_compare, icc_summary = icc_summary))
}

directionality_pct <- function(x) {
  pos_count <- sum(x > 0)
  neg_count <- sum(x < 0)
  max_count <- max(pos_count, neg_count)
  return(round((max_count / length(x)) * 100, 2))
}

process_dirct_pct <- function(worker_compare) {
  # Initialize an empty dataframe to store the results
  results_df <- data.frame(cow_L = integer(), cow_R = integer(), dirct_pct = numeric())
  
  # Iterate through each dataframe in the list
  for (df in worker_compare) {
    # Calculate the directionality percentage for each row
    dirct_pct_values <- apply(df[, 3:ncol(df)], 1, directionality_pct)
    
    # Create a temporary dataframe to store the results for the current dataframe
    temp_df <- data.frame(cow_L = df$cow_L, cow_R = df$cow_R, dirct_pct = dirct_pct_values)
    
    # Bind the temporary dataframe to the results dataframe
    results_df <- rbind(results_df, temp_df)
  }
  
  return(results_df)
}


################################################################################
######## click worker average VS expert average interoserver reliability #######
################################################################################

combine_all_response <- function(click_worker_response, expert_response) {
  # click worker average
  click_worker_avg <- aggregate(click_worker_response$response, by = list(click_worker_response$cow_L, click_worker_response$cow_R), FUN = mean)
  colnames(click_worker_avg) <- c("cow_L", "cow_R", "click_worker_avg")
  
  # click worker median
  click_worker_median <- aggregate(click_worker_response$response, by = list(click_worker_response$cow_L, click_worker_response$cow_R), FUN = median)
  colnames(click_worker_median) <- c("cow_L", "cow_R", "click_worker_median")
  
  # expert average
  expert_response <- expert_response[, c("cow_L", "cow_R", "response_mean")]
  colnames(expert_response) <- c("cow_L", "cow_R", "expert_avg")
  
  compare_click_worker_expert <- merge(click_worker_avg, expert_response)
  return(compare_click_worker_expert)
}


# compute ICC between average click worker and expert
compute_icc_click_worker_expert <- function(click_worker_response, expert_response, cur_title) {
  compare_click_worker_expert <- combine_all_response(click_worker_response, expert_response)
  compare_click_worker_expert_easy <- compare_click_worker_expert[which(abs(compare_click_worker_expert$expert_avg) >= 1),]
  compare_click_worker_expert_hard <- compare_click_worker_expert[which(abs(compare_click_worker_expert$expert_avg) < 1),]
  
  easy_q <- nrow(compare_click_worker_expert_easy)
  hard_q <- nrow(compare_click_worker_expert_hard)
  
  icc_values_inter_all <- icc(compare_click_worker_expert[, 3:ncol(compare_click_worker_expert)],model = "twoway", type = "agreement", unit = "single")$value
  icc_values_inter_easy <- icc(compare_click_worker_expert_easy[, 3:ncol(compare_click_worker_expert_easy)],model = "twoway", type = "agreement", unit = "single")$value
  icc_values_inter_hard <- icc(compare_click_worker_expert_hard[, 3:ncol(compare_click_worker_expert_hard)],model = "twoway", type = "agreement", unit = "single")$value
  
  # Report the results
  print(paste("Total number of easy questions:", easy_q))
  print(paste("Total number of hard questions:", hard_q))
  print(paste("overall ICC between expert avg & click worker avg:", icc_values_inter_all))
  print(paste("easy question ICC between expert avg & click worker avg:", icc_values_inter_easy))
  print(paste("hard question ICC between expert avg & click worker avg:", icc_values_inter_hard))
  
  p1 <- plot_click_worker_expert(compare_click_worker_expert, cur_title)
  print(p1)
  return(compare_click_worker_expert)
}

plot_click_worker_expert <- function(df, cur_title) {
  p1 <- plot(df$expert_avg,df$click_worker_avg,
             ylab="Average worker rating",xlab="Average expert rating",xlim=c(-3,3),ylim=c(-3,3),
             pch=19, frame.plot=F, main = cur_title)
  
  return(p1)
}

plot_click_worker_expert_dirct_pct <- function(df, cur_title) {
  p1 <- plot(df$expert_avg,df$dirct_pct,
             ylab="worker directionaltiy percentage",xlab="Average expert rating",xlim=c(-3,3),ylim=c(0, 100),
             pch=19, frame.plot=F, main = cur_title)
  
  return(p1)
}

calculate_and_plot_direct_pct <- function(worker_compare, compare_click_worker_expert, cur_title) {
  worker_compare_direct_pct <- process_dirct_pct(worker_compare)
  worker_response_summary <- merge(compare_click_worker_expert, worker_compare_direct_pct)
  print(plot_click_worker_expert_dirct_pct(worker_response_summary, cur_title))
  
  return(worker_response_summary)
}

compare_click_worker_sd_and_expert_avg <- function(cowLR_response, expert_response) {
  click_worker_response_sd <- aggregate(cowLR_response$response, by = list(cowLR_response$cow_L, cowLR_response$cow_R), FUN = sd)
  colnames(click_worker_response_sd) <- c("cow_L", "cow_R", "click_worker_sd")
  
  temp_expert <- expert_response[, c("cow_L", "cow_R", "response_mean")]
  colnames(temp_expert) <- c("cow_L", "cow_R", "expert_avg")
  
  return(merge(click_worker_response_sd, temp_expert))
}


################################################################################
############################## workers clustering ##############################
################################################################################

cluster_workers <- function(data) {
  worker_resp <- data[, 2:length(data)]
  rownames(worker_resp) <- data[,1]
  worker_resp <- na.exclude(worker_resp)
  
  dist_mat <- dist(worker_resp, method = 'euclidean')
  hclust_avg <- hclust(dist_mat, method = "average")
  cut_avg <- cutree(hclust_avg, k = mean(dist_mat))
  
  worker_resp_cl <- cbind(worker_resp, cut_avg)
  return(worker_resp_cl[which(worker_resp_cl$cut_avg == names(which.max(table(worker_resp_cl$cut_avg)))),])
}

reorientate_df <- function(worker_compare_example) {
  cur_df <- worker_compare_example
  cur_df$cow_pair <- paste(cur_df$cow_L, cur_df$cow_R, sep = "-")
  # Create a long dataframe where each row is a cow_pair, worker_id and answer
  long_df <- cur_df %>% 
    gather(key = "worker_id", value = "answer", starts_with("Answer.")) %>%
    select(worker_id, cow_pair, answer)
  
  # Spread the dataframe to wide format where each cow_pair is a column
  wide_df <- long_df %>%
    spread(key = cow_pair, value = answer)
  
  return(wide_df)
}

cluster_worker <- function(worker_compare) {
  worker_compare_list <- list()
  for (i in 1:length(worker_compare)) {
    cur_worker_compare <- worker_compare[[i]]
    # change data orientation
    wide_df <- reorientate_df(cur_worker_compare)
    # cluster workers together, get worker ID in the bigest cluster
    clustered_workers_df = cluster_workers(wide_df)
    clustered_workers <- rownames(clustered_workers_df)
    
    after_cluster <- cur_worker_compare[, c("cow_L", "cow_R", clustered_workers)]
    worker_compare_list[[i]] <- after_cluster
  }
  
  return(worker_compare_list)
}

process_and_combine <- function(df_list) {
  # Process each dataframe in the list
  processed_list <- lapply(df_list, function(df) {
    df$click_worker_avg <- rowMeans(df[, 3:ncol(df)])
    return(df[, c("cow_L", "cow_R", "click_worker_avg")])
  })
  
  # Combine all the processed dataframes into a master dataframe
  master_df <- do.call(rbind, processed_list)
  
  return(master_df)
}

combine_response_cl <- function(df_list, expert_response) {
  click_worker_avg_df <- process_and_combine(df_list)
  
  # expert average
  expert_response <- expert_response[, c("cow_L", "cow_R", "response_mean")]
  colnames(expert_response) <- c("cow_L", "cow_R", "expert_avg")
  
  compare_click_worker_expert <- merge(click_worker_avg_df, expert_response)
  return(compare_click_worker_expert)
}

compute_icc_click_worker_expert_cl <- function(df_list, expert_response, cur_title) {
  compare_click_worker_expert <- combine_response_cl(df_list, expert_response)
  compare_click_worker_expert_easy <- compare_click_worker_expert[which(abs(compare_click_worker_expert$expert_avg) >= 1),]
  compare_click_worker_expert_hard <- compare_click_worker_expert[which(abs(compare_click_worker_expert$expert_avg) < 1),]
  
  easy_q <- nrow(compare_click_worker_expert_easy)
  hard_q <- nrow(compare_click_worker_expert_hard)
  
  icc_values_inter_all <- icc(compare_click_worker_expert[, 3:ncol(compare_click_worker_expert)],model = "twoway", type = "agreement", unit = "single")$value
  icc_values_inter_easy <- icc(compare_click_worker_expert_easy[, 3:ncol(compare_click_worker_expert_easy)],model = "twoway", type = "agreement", unit = "single")$value
  icc_values_inter_hard <- icc(compare_click_worker_expert_hard[, 3:ncol(compare_click_worker_expert_hard)],model = "twoway", type = "agreement", unit = "single")$value
  
  # Report the results
  print(paste("Total number of easy questions:", easy_q))
  print(paste("Total number of hard questions:", hard_q))
  print(paste("overall ICC between expert avg & click worker avg:", icc_values_inter_all))
  print(paste("easy question ICC between expert avg & click worker avg:", icc_values_inter_easy))
  print(paste("hard question ICC between expert avg & click worker avg:", icc_values_inter_hard))
  
  p1 <- plot_click_worker_expert(compare_click_worker_expert, cur_title)
  print(p1)
  return(compare_click_worker_expert)
}