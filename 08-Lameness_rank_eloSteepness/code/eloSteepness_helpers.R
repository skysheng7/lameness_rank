################################################################################
############################# functions ########################################
################################################################################
# handle ties: duplicate the rows where degree = 0, 1 row: A wins over B, 2nd row: B wins over A
swap_winner_loser <- function(df, lt1_tie) {
  
  # Check if the input is a data.frame
  if (!is.data.frame(df)) {
    stop("The input must be a data.frame.")
  }
  
  # Check if the necessary columns exist in the data.frame
  necessary_cols <- c("winner", "loser", "degree")
  if (!all(necessary_cols %in% names(df))) {
    stop(paste("The data.frame must contain the following columns:", paste(necessary_cols, collapse = ", ")))
  }
  
  # Subset the data where degree equals 0
  # if lt1_tie == TRUE, meaning that we want to treat degree <1 as tie
  if (lt1_tie) {
    df_subset <- subset(df, degree < 1)
  } else {  # if lt1_tie == FALSE, meaning that we want to treat degree ==0 as tie
    df_subset <- subset(df, degree == 0)
  }
  
  
  # Swap 'winner' and 'loser' in the subset
  df_subset$tmp <- df_subset$winner
  df_subset$winner <- df_subset$loser
  df_subset$loser <- df_subset$tmp
  df_subset$tmp <- NULL
  
  # Append the subset to the original dataframe
  new_df <- rbind(df, df_subset)
  new_df <- new_df[sample(nrow(new_df)), ]
  rownames(new_df) <- NULL
  
  
  return(new_df)
}

# store the Elo winning probability from each iteration
individual_elo_win <- function(array_3d, ids) {
  # Initialize an empty matrix with appropriate dimensions
  res <- matrix(ncol = dim(array_3d)[3], nrow = length(array_3d[, , 1]))
  
  # Fill the matrix with the values from the 3D array
  for (i in seq_len(ncol(res))) {
    res[, i] <- array_3d[, , i]
  }
  
  # Set the column names of the matrix
  colnames(res) <- ids
  
  return(res)
}


plot_scores <- function(x, gs_record, adjustpar = 4, subset_ids = NULL, include_others = TRUE, num_colors) {
  
  
  correct_object <- FALSE
  if ("cumwinprobs" %in% names(x)) {
    res <- individual_elo_win(x$cumwinprobs, x$ids)
    xlab <- "Summed Elo winning probability"
    correct_object <- TRUE
  }
  if ("norm_ds" %in% names(x)) {
    res <- x$norm_ds
    xlab <- "David's score (normalized)"
    correct_object <- TRUE
  }
  
  if (!correct_object) {
    stop("object 'x' not of correct format")
  }
  
  n_ids <- ncol(res)
  
  if (!is.null(subset_ids)) {
    colnames(res) <- x$ids
    cn_locs <- which(!x$ids %in% subset_ids)
  }
  
  # prep data and set axis limits
  pdata <- apply(res, 2, density, adjust = adjustpar)
  pmax <- max(unlist(lapply(pdata, function(x) max(x$y))))
  xl <- c(0, n_ids - 1)
  yl <- c(0, pmax * 1.05)
  
  cols <- sapply(colnames(res), function(id) {
    record <- gs_record[gs_record$Cow == id, ]
    if (nrow(record) == 0) {
      return("black")
    } else {
      value <- record$GS
      return(rev(magma(num_colors))[round(((value - 1)/4) * (num_colors-1)) + 1])
    }
  })
  
  border_cols <- rep("black", n_ids)
  if (!is.null(subset_ids)) {
    cols[cn_locs] <- NA
    if (!include_others) {
      border_cols[cn_locs] <- NA
    }
  }

  
  # Calculate the number of colors needed
  color_palette <- rev(magma(num_colors))
  
  # Setup plot layout to accommodate both the main plot and the color bar
  layout(matrix(c(1, 2), nrow = 1, byrow = TRUE), widths = c(7,1), heights = c(1))
  
  # Main plot
  par(mar = c(6.5, 4, 5, 0) + 0.1) # Adjust right margin to create more white space
  

  # setup
  plot(0, 0, type = "n", xlim = c(1, 30), ylim = yl, yaxs = "i",
       xaxs = "i", axes = FALSE, xlab = "", ylab = "", bg = "white", xaxt = "n", yaxt = "n") # Turn off automatic axis plotting
  
  # Add x-axis with tick marks
  axis(1, at = seq(1, 31, by = 4), cex.axis = 2) # Adjust font size with cex.axis
  
  # Adjust the distance of axis labels
  title(ylab = "Density", line = 0.5, cex.lab=4) # Increase font size and adjust distance
  title(xlab = xlab, line = 4.5, cex.lab=4) # Increase font size and adjust distance
  
  # draw the filled posteriors
  for (i in seq_len(ncol(res))) {
    p <- pdata[[i]]
    p$x[p$x > (n_ids - 1)] <- n_ids - 1
    p$x[p$x < 0] <- 0
    polygon(c(p$x, rev(p$x)), c(rep(0, length(p$x)), rev(p$y)),
            border = NA, col = cols[i])
  }
  
  # draw the contours
  for (i in seq_len(ncol(res))) {
    p <- pdata[[i]]
    p$x[p$x > (n_ids - 1)] <- n_ids - 1
    p$x[p$x < 0] <- 0
    polygon(c(p$x, rev(p$x)), c(rep(0, length(p$x)), rev(p$y)), border = border_cols[i])
  }
  
  
  
  # Color bar plot
  par(mar = c(5, 0, 7, 8) + 0.1) # Adjust margins for the color bar, more space on the right
  
  # Start the color bar plot, set up its coordinate system but do not draw axes
  plot(0, 0, type = "n", xlim = c(0, 1), ylim = c(1, 5), axes = FALSE, xlab = "", ylab = "")
  
  # Draw the color bar
  bar_height <- (5 - 1) / num_colors
  for (i in 1:num_colors) {
    rect(0, 1 + (i - 1) * bar_height, 1, 1 + i * bar_height, col = color_palette[i], border = NA)
  }
  
  # Add an axis to the color bar with larger font size
  axis(4, at = seq(1, 5, by = 1), labels = seq(1, 5, by = 1), las = 2, cex.axis = 2) # Increased font size
  
  # Add "Average gait score" text aligned with the left side of the color bar
  mtext("Average\ngait score", side = 3, line = 1, cex = 2.6, adj = 0)
  
  
}


#' Save Plot to PNG File
#'
#' This function saves a plot generated by the `plot_scores` function to a PNG file.
#'
#' @param elo_steep_result A result object from the EloSteepness analysis.
#' @param png_name A character string specifying the name of the PNG file (without the .png extension).
#' @param gs_record2 gait score record
#'
#' @return NULL. The function saves the plot to a PNG file and does not return any value.
save_plot_score <- function(elo_steep_result, png_name, gs_record2, num_colors) {
  file_name <- paste(png_name, ".png", sep = "")
  png(file_name, width = 1100, height = 650) # set the width and height of the PNG file
  print(plot_scores(elo_steep_result, gs_record2, num_colors = num_colors))
  dev.off() # close the PNG file
}

# replicate row is degree > 1
# Define a function to replicate each row
replicate_row <- function(row) {
  degree <- as.numeric(row[which(names(winner_loser) == "degree")])
  if (degree > 1) {
    replicate(degree - 1, row, simplify = FALSE)
  } else {
    NULL
  }
}

# replicate row is degree > 1 for every row in this dataframe
replicate_row_df <- function(winner_loser) {
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
  
  return(winner_loser_degree_replct)
}

interaction_matrix_generation <- function(winn_loser_sheet) {
  # Identify unique cows from both winner and loser columns
  unique_cows <- unique(c(winn_loser_sheet$winner, winn_loser_sheet$loser))
  
  # Create the interaction matrix using the unique cows
  interaction_matrix <- matrix(0, nrow=length(unique_cows), ncol=length(unique_cows),
                               dimnames=list(unique_cows, unique_cows))
  
  # Populate the matrix with the counts from the data
  for(i in 1:nrow(winn_loser_sheet)) {
    winner <- winn_loser_sheet$winner[i]
    loser <- winn_loser_sheet$loser[i]
    interaction_matrix[as.character(winner), as.character(loser)] <- interaction_matrix[as.character(winner), as.character(loser)] + 1
  }
  
  return(interaction_matrix)
}

run_elo <- function(winn_loser_sheet){
  interaction_matrix <- interaction_matrix_generation(winn_loser_sheet) 
  
  # use elosteepness from matrix
  elo_baysian_result <- elo_steepness_from_matrix_set(interaction_matrix)
  
  return(elo_baysian_result)
}


elo_steepness_from_matrix_set <- function(interaction_matrix) {
  # use elosteepness from matrix
  elo_baysian_result <- elo_steepness_from_matrix(interaction_matrix, 
                                                  algo="fixed_sd", 
                                                  cores = 2,
                                                  chains = 2,
                                                  iter = 5000, 
                                                  warmup = 1000,
                                                  seed = 88,
                                                  control = list(adapt_delta = 0.99)
  )
  
  return(elo_baysian_result)
}


#' Random Elo Steepness Calculation and Saving
#'
#' This function calculates the Elo steepness from a given winner-loser sheet, 
#' compares it with expert Elo steepness, and saves the results to specified output directories.
#'
#' @param winn_loser_sheet A data frame containing winner and loser data.
#' @param expert_eloSteep A data frame containing expert Elo steepness data.
#' @param output_dir A character string specifying the directory to save output files.
#' @param type A character string specifying the type of analysis: what method is used in the calculation
#' @param assessor A character string specifying the assessor type: expert or click_worker
#' @param gs_record2 gait score record
#'
#' @return NULL. The function saves results to files and does not return any value.
random_elo_steep <- function(winn_loser_sheet, expert_eloSteep, output_dir, type, assessor, gs_record2){
  
  # use elosteepness from matrix
  elo_baysian_result <- run_elo(winn_loser_sheet)
  
  # get individual's score
  individual_elo_win_df <- individual_elo_win(elo_baysian_result$cumwinprobs, elo_baysian_result$ids)
  score_sum <- scores(elo_baysian_result)
  colnames(score_sum)[colnames(score_sum) == "id"] <- "Cow"
  score_sum2_click_worker <- score_sum[, c("Cow", "mean", "sd")]
  colnames(score_sum2_click_worker) <- c("Cow", paste(type, assessor, "mean", sep = "_"), paste(type, assessor,"sd", sep = "_"))
  
  compare_result_master <- merge(expert_eloSteep, score_sum2_click_worker, all = TRUE)
  compare_result_master <- compare_result_master[order(compare_result_master$GS, decreasing = TRUE), ]
  
  # compute Elo steepness
  elo_steep_df <- steepness_df_construct(elo_baysian_result[["steepness"]], type, assessor) 
  
  write.csv(score_sum2_click_worker, file = paste0(output_dir, type, "_", assessor, "_scores.csv"), row.names = FALSE)
  write.csv(individual_elo_win_df, file = paste0(output_dir, type, "_", assessor, "_cumwinprobs.csv"), row.names = FALSE)
  write.csv(compare_result_master, file = paste0(output_dir, "compare_summary.csv"), row.names = FALSE)
  write.csv(elo_steep_df, file = paste0(output_dir, type, "_", assessor, "_steepness.csv"), row.names = FALSE)
  save(elo_baysian_result, file = paste0(output_dir, type, "_", assessor, "_elo_baysian.rdata"))
  save_plot_score(elo_baysian_result, paste0("../plots/", type, "_", assessor), gs_record2, num_colors = 8)
  
  return(compare_result_master)
}

count_unique_worker_per_HIT <- function(cowLR_df){
  HIT_worker <- unique(cowLR_df[,c("HIT","Worker_id")])
  count_worker_per_HIT <- HIT_worker %>%
    group_by(HIT) %>%
    summarise(count = n())
  colnames(count_worker_per_HIT) <- c("HIT", "worker_num")
  
  return(count_worker_per_HIT)
}


steepness_df_construct <- function(steepness_values, type, assessor) {
  steep_mean <- round(mean(steepness_values), digits = 2)
  steep_sd <- round(sd(steepness_values), digits = 2)
  method <- paste0(type, "_", assessor)
  elo_steep_df <- data.frame(method, steep_mean, steep_sd)
  colnames(elo_steep_df) <- c("method", "steepness_mean", "steepness_SD")
  
  return(elo_steep_df)
}

count_unique_worker_per_pair <- function(cowLR_df){
  HIT_qNum_worker <- unique(cowLR_df[,c("HIT", "question_num", "Worker_id")])
  HIT_qNum_worker$id <- paste(HIT_qNum_worker$HIT, HIT_qNum_worker$question_num, sep = "-")
  count_worker_per_pair <- HIT_qNum_worker %>%
    group_by(id) %>%
    summarise(count = n())
  colnames(count_worker_per_pair) <- c("q_name", "worker_num")
  
  return(count_worker_per_pair)
}

unique_pair_id_generation <- function(cowLR_df) {
  # Create the pair_id column by pasting the max and min values together with an underscore
  cowLR_df$pair_id <- paste0(cowLR_df$cow_L, "_", cowLR_df$cow_R)
  
  return(cowLR_df)
}

subsample_and_process <- function(split_df, worker_num) {
  # Create an empty data frame to store the results
  sampled_df <- data.frame()
  
  # Loop through each group and sample 'worker_num' rows
  for (group in names(split_df)) {
    current_df <- split_df[[group]]
    # Ensure worker_num doesn't exceed the number of rows in the current group
    n_sample <- min(nrow(current_df), worker_num)
    sampled_rows <- current_df[sample(1:nrow(current_df), n_sample), ]
    sampled_df <- rbind(sampled_df, sampled_rows)
    
  }
  
  sampled_df$pair_id <- NULL
  
  
  return(sampled_df)
}

create_winner_loser_degree_df <- function(final_df) {
  winner <- vector()
  loser <- vector()
  degree <- vector()
  
  for (i in 1:nrow(final_df)) {
    if (final_df$response[i] <= 0) {
      winner <- c(winner, final_df$cow_L[i])
      loser <- c(loser, final_df$cow_R[i])
      degree <- c(degree, abs(final_df$response[i]))
    } else {
      winner <- c(winner, final_df$cow_R[i])
      loser <- c(loser, final_df$cow_L[i])
      degree <- c(degree, abs(final_df$response[i]))
    }
  }
  
  new_df <- data.frame(
    winner = winner,
    loser = loser,
    degree = degree
  )
  
  return(new_df)
}

five_milestone_compare <- function(final_df_sampled, filtered_cows, milestone, type, min_worker_per_pair) {
  
  # Create an empty data frame with the same columns as final_df_sampled
  milestone_compare <- final_df_sampled[-(1:nrow(final_df_sampled)),]
  
  for (cow in filtered_cows) {
    position_secure <- FALSE  # Flag variable
    
    for (stone in milestone) {
      cur_pair_results <- final_df_sampled[
        (final_df_sampled$cow_L == cow & final_df_sampled$cow_R == stone) |
          (final_df_sampled$cow_L == stone & final_df_sampled$cow_R == cow),]
      
      if (type == "max") {
        milestone_compare <- rbind(milestone_compare, cur_pair_results)
        
      } else if (type == "min" & !position_secure) {
        milestone_compare <- rbind(milestone_compare, cur_pair_results)
        pair_avg <- mean(cur_pair_results$response)
        
        if ((pair_avg <= -2 & cur_pair_results$cow_L[1] == stone) |
            (pair_avg >= 2 & cur_pair_results$cow_R[1] == stone)) {
          position_secure <- TRUE
        }
        
      } else if (type == "min" & position_secure) {
        new_df <- data.frame(
          cow_L = rep(cow, min_worker_per_pair),
          cow_R = rep(stone, min_worker_per_pair),
          question_num = sample(-200:-100, min_worker_per_pair, replace = TRUE),
          HIT = sample(-200:-100, min_worker_per_pair, replace = TRUE),
          Worker_id = sample(-200:-100, min_worker_per_pair, replace = TRUE),
          response = rep(3, min_worker_per_pair)
        )
        # Ensure the columns order match before binding rows
        new_df <- new_df[names(milestone_compare)]
        milestone_compare <- rbind(milestone_compare, new_df)
      }
    }
  }
  
  return(milestone_compare)
}



icc_change_worker_num_milestone <- function(random_rounds = 10, max_worker_num = 14, 
                                            cowLR_df, click_worker_experts,
                                            expert_col_name, filtered_cows, 
                                            milestone, type) {
  set.seed(7)
  # prepare an empty df to store change in spearman correlation results
  correlation_change_df <- data.frame()
  
  # generate unique pair ID
  cowLR_df <- unique_pair_id_generation(cowLR_df)
  # Split the data frame by pair_id
  split_df <- split(cowLR_df, cowLR_df$pair_id)
  
  for (worker_num in 1:max_worker_num) {
    for (round in 1:random_rounds){
      print(paste0("worker number: ", worker_num, ", round: ", round))
      # subsample worker
      sampled_cowLR <- subsample_and_process(split_df, worker_num)
      
      # compare with milestone cows
      sampled_cowLR_milestone <- five_milestone_compare(sampled_cowLR, filtered_cows, milestone, type, worker_num)
      
      # count how many comparisons were made with milestone cows
      count_compare <- sampled_cowLR_milestone[which(sampled_cowLR_milestone$question_num > 0),]
      total_compare <- nrow(unique(count_compare[, c("question_num", "HIT")]))
      
      # convert to winner and loser format
      sampled_winner_lower <- create_winner_loser_degree_df(sampled_cowLR_milestone)
      
      # duplicate the rows and swap winner and loser if response is 0
      sampled_df_processed <- swap_winner_loser(sampled_winner_lower, FALSE)
      
      # run elosteepness from matrix
      elo_baysian_result <- run_elo(sampled_df_processed)
      
      # get individual's score
      score_sum <- scores(elo_baysian_result)
      colnames(score_sum)[colnames(score_sum) == "id"] <- "Cow"
      score_sum2_click_worker <- score_sum[, c("Cow", "mean")]
      
      # calculate spearman correlation against all workers all response
      compare_full_result <- compare_with_full_hierarchy(click_worker_experts, expert_col_name,score_sum2_click_worker)
      spearman_worker_result <- compare_full_result$spearman_worker_values
      spearman_worker_values <- spearman_worker_result$estimate
      spearman_worker_p_values <- spearman_worker_result$p.value
      # ICC against all experts' hierarchy 
      icc_expert_values <- compare_full_result$icc_expert_values
      
      temp <- data.frame(num_of_crowd_worker = worker_num, num_of_comparison = total_compare, spearman_subsample_with_full_worker = spearman_worker_values, spearman_subsample_with_full_worker_p_value = spearman_worker_p_values, icc_subsample_with_full_expert= icc_expert_values)
      
      correlation_change_df <- rbind(correlation_change_df, temp)
      
      # save eloSteepness results
      save(elo_baysian_result, file = paste0("../results/large files/elo_milestone_", worker_num, "_worker_v", round, ".rdata"))
      save(score_sum, file = paste0("../results/large files/elo_score_milestone_", worker_num, "_worker_v", round, ".rdata"))
      
    }
  }

  save(correlation_change_df, file = "../results/milestone_worker_num_ICC_change.rdata")
  
  return(correlation_change_df)
}



# Define a function to calculate standard error
standard_error <- function(x) {
  sd(x) / sqrt(length(x))
}

avg_se <- function(df, value_var, by_var) {
  cor_se_df <- aggregate(df[, value_var], by = list(df[, by_var]), FUN = standard_error)
  colnames(cor_se_df) <- c("num_of_crowd_worker", paste0(value_var, "_cor_SE"))
  cor_mean_df <- aggregate(df[, value_var], by = list(df[, by_var]), FUN = mean)
  colnames(cor_mean_df) <- c("num_of_crowd_worker", paste0(value_var, "_cor_mean"))
  cor_mean_se_df <- merge(cor_mean_df, cor_se_df)
  cor_mean_se_df[, paste0(value_var, "_ymin")] <- cor_mean_se_df[, paste0(value_var, "_cor_mean")] - cor_mean_se_df[, paste0(value_var, "_cor_SE")]
  cor_mean_se_df[, paste0(value_var, "_ymax")] <- cor_mean_se_df[, paste0(value_var, "_cor_mean")] + cor_mean_se_df[, paste0(value_var, "_cor_SE")]
  
  return(cor_mean_se_df)
}

compare_with_full_hierarchy <- function(click_worker_experts, expert_col_name,score_sum2_click_worker) {
  all_worker_rank <- click_worker_experts[, c("Cow", "all_click_worker_mean")]
  all_expert_rank <- click_worker_experts[, c("Cow", expert_col_name)]
  
  # calculate spearman correlation against all workers all response
  temp_compare <- merge(all_worker_rank, score_sum2_click_worker)
  spearman_worker_values <- cor.test(temp_compare$mean, temp_compare$all_click_worker_mean, method="spearman")
  
  # calculate ICC against all experts' response
  temp_compare <- merge(all_expert_rank, score_sum2_click_worker)
  icc_expert_result <- icc(temp_compare[, 2:ncol(temp_compare)], model = "twoway", type = "agreement", unit = "single")
  icc_expert_values <- icc_expert_result$value  
  
  return(list(spearman_worker_values= spearman_worker_values, 
              icc_expert_values = icc_expert_values))
}

calculate_scc <- function(var1, var2){
  # Calculate Spearman rank correlation using cor.test
  cor_test_result <- cor.test(var1, var2, method = "spearman")
  
  # Print the result
  print(cor_test_result)
  
  # If you want to extract and print just the correlation coefficient and the p-value
  correlation_coefficient <- cor_test_result$estimate
  p_value <- cor_test_result$p.value
  
  cat("Correlation coefficient:", correlation_coefficient, "\n")
  cat("P-value:", p_value, "\n")
  
}