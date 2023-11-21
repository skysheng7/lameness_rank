interobserver_ICC_per_round <- function(gs_retain2) {
  gs_retain2 <- gs_retain2[, c("Cow", "Worker_id", "GS")]
  
  # change data orientation
  worker_data_wide_inter <- reshape(gs_retain2, idvar = c("Cow"), timevar = "Worker_id", direction = "wide")
  # Calculate the ICC for the current worker
  icc_result_inter <- icc(worker_data_wide_inter[, 2:ncol(worker_data_wide_inter)],model = "twoway", type = "agreement", unit = "single")
  icc_values_inter <- icc_result_inter$value  
  
  return(icc_values_inter)
}

interobserver_ICC_per_round_df <- function(gs) {
  rounds <- unique(gs$GS_round)
  
  for (r in rounds) {
    gs_retain2 <- gs[which(gs$GS_round == r),]
    icc_values_inter <- interobserver_ICC_per_round(gs_retain2)
    temp <- data.frame(GS_round = r, interobserver_ICC = icc_values_inter)
    
    if (r == 1) {
      df <- temp
    } else {
      df <- rbind(df, temp)
    }
  }
  
  return(df)
}


gs_subsampling <- function(gs, selected_rounds, selected_experts) {
  gs_sampled <- gs[which((gs$Worker_id %in% selected_experts) & (gs$GS_round %in% selected_rounds)),]
  
  # take the average across all subsampled experts for each cow
  gs_sampled_avg <- aggregate(gs_sampled$GS, by = list(gs_sampled$Cow), FUN = mean)
  colnames(gs_sampled_avg) <- c("Cow", "GS_sampled_avg")
  
  return(gs_sampled_avg)
}

spearman_change_rounds_expert_num_round_seq <- function(gs) {
  all_rounds <- unique(gs$GS_round)
  all_experts <- unique(gs$Worker_id)
  
  # take the average across all experts for each cow
  gs_avg <- aggregate(gs$GS, by = list(gs$Cow), FUN = mean)
  colnames(gs_avg) <- c("Cow", "GS_avg")
  
  cor_change_df <- data.frame()
  
  for (num_of_experts in 1:(length(all_experts))) {
    expert_combinations <- combn(all_experts, num_of_experts, simplify = FALSE)
    for (num_of_rounds in 1:length(all_rounds)) {
      selected_rounds <- seq(1, num_of_rounds, by = 1)
      for (selected_experts in expert_combinations) {

        gs_sampled_avg <- gs_subsampling(gs, selected_rounds, selected_experts) 
        
        gs_compare <- merge(gs_avg, gs_sampled_avg)
        
        # calculate spearman correlation
        # Calculate Spearman rank correlation
        correlation <- cor(gs_compare$GS_avg, gs_compare$GS_sampled_avg, method="spearman")
        
        temp <- data.frame(num_of_experts = num_of_experts, num_of_rounds = num_of_rounds, cor_subsample_with_full = correlation)
        
        cor_change_df <- rbind(cor_change_df, temp)
    
      }
    }
  }
  
  return(cor_change_df)
}


spearman_change_rounds_expert_num <- function(gs) {
  all_rounds <- unique(gs$GS_round)
  all_experts <- unique(gs$Worker_id)
  
  # take the average across all experts for each cow
  gs_avg <- aggregate(gs$GS, by = list(gs$Cow), FUN = mean)
  colnames(gs_avg) <- c("Cow", "GS_avg")
  
  cor_change_df <- data.frame()
  
  for (num_of_experts in 1:(length(all_experts))) {
    expert_combinations <- combn(all_experts, num_of_experts, simplify = FALSE)
    for (num_of_rounds in 1:length(all_rounds)) {
      round_combinations <- combn(all_rounds, num_of_rounds, simplify = FALSE)
      for (selected_experts in expert_combinations) {
        for (selected_rounds in round_combinations) {
          gs_sampled_avg <- gs_subsampling(gs, selected_rounds, selected_experts) 
          
          gs_compare <- merge(gs_avg, gs_sampled_avg)
          
          # calculate spearman correlation
          # Calculate Spearman rank correlation
          correlation <- cor.test(gs_compare$GS_avg, gs_compare$GS_sampled_avg, method="spearman")
          
          # If you want to extract and print just the correlation coefficient and the p-value
          correlation_coefficient <- correlation$estimate
          p_value <- correlation$p.value
          
          temp <- data.frame(num_of_experts = num_of_experts, num_of_rounds = num_of_rounds, cor_subsample_with_full = correlation_coefficient, p_value = p_value)
          
          cor_change_df <- rbind(cor_change_df, temp)
        }
      }
    }
  }
  
  return(cor_change_df)
}

# Define a function to calculate standard error
standard_error <- function(x) {
  sd(x) / sqrt(length(x))
}