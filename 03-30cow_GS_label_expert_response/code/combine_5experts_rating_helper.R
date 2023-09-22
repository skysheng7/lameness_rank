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

gs_subsampling <- function(gs, num_of_rounds, num_of_experts) {
  all_rounds <- unique(gs$GS_round)
  all_experts <- unique(gs$Worker_id)
  
  selected_rounds <- sample(all_rounds, num_of_rounds)
  selected_experts <- sample(all_experts, num_of_experts)
  
  gs_sampled <- gs[which((gs$Worker_id %in% selected_experts) & (gs$GS_round %in% selected_rounds)),]
  
  # take the avearge across all subsampled experts for each cow
  gs_sampled_avg <- aggregate(gs_sampled$GS, by = list(gs_sampled$Cow), FUN = mean)
  colnames(gs_sampled_avg) <- c("Cow", "GS_sampled_avg")
  
  return(gs_sampled_avg)
}

icc_change_rounds_expert_num <- function(gs) {
  # take the avearge across all experts for each cow
  gs_avg <- aggregate(gs$GS, by = list(gs$Cow), FUN = mean)
  colnames(gs_avg) <- c("Cow", "GS_avg")
  
  icc_change_df <- data.frame()
  
  for (num_of_experts in 1:(length(unique(gs$Worker_id)))) {
    for (num_of_rounds in 1:length(unique(gs$GS_round))) {
      gs_sampled_avg <- gs_subsampling(gs, num_of_rounds, num_of_experts) 
      
      gs_compare <- merge(gs_avg, gs_sampled_avg)
      
      # calculate ICC
      icc_result_inter <- icc(gs_compare[, 2:ncol(gs_compare)],model = "twoway", type = "agreement", unit = "single")
      icc_values_inter <- icc_result_inter$value  
      
      temp <- data.frame(num_of_experts = num_of_experts, num_of_rounds = num_of_rounds, icc_subsample_with_full = icc_values_inter)
      
      icc_change_df <- rbind(icc_change_df, temp)
    }
  }
  
  return(icc_change_df)
}