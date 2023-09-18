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

###################################################################################################
############################################ Load Data ############################################
###################################################################################################
pc_environment <- "Sky"

if (pc_environment == "Sky") {
  input_dir <- "../../data/"
  output_dir <- "../../results/"
  }else {
  input_dir <-"/Users/sora/Desktop/Sky's"
  output_dir <- "/Users/sora/Library/CloudStorage/OneDrive-UBC/Sora Jeong/results"
}
# read in the worker response data
worker_july19 <- read.csv(paste0(input_dir, "worker_response_tracker_collect_2Jul-19-2021.csv"), header = TRUE)
worker_july22 <- read.csv(paste0(input_dir, "worker_response_tracker_collect_Jul-22-2021.csv"), header = TRUE)
worker_response <- rbind(worker_july19, worker_july22)
worker_response$X <- NULL # delete unnecessary columns
worker_response2 <- worker_response
worker_response2$Task_number <- NULL

# For worker response, change the range from 1-2 to -3 to 3
worker_response2[, 11:20] <- sapply(worker_response2[, 11:20],as.character)
worker_response2[worker_response2 == "video not playing"] <- NA
worker_response2[worker_response2 == 1] <- -3
worker_response2[worker_response2 == 1.16] <- -2
worker_response2[worker_response2 == 1.32] <- -1
worker_response2[worker_response2 == 1.50] <- 0
worker_response2[worker_response2 == 1.68] <- 1
worker_response2[worker_response2 == 1.84] <- 2
worker_response2[worker_response2 == 2.00] <- 3
# change data type, now all columns are numeric
worker_response2[, 11:20] <- sapply(worker_response2[, 11:20],as.numeric)

# change dateTime format
worker_response2$Accept_time <- ymd_hms(substr(worker_response2$Accept_time, 1, 19)) 
worker_response2$Submit_time <- ymd_hms(substr(worker_response2$Submit_time, 1, 19))

#Get task completion times
worker_response_time <- worker_response2$Submit_time-worker_response2$Accept_time
hist(as.numeric(worker_response_time), breaks = c(1:30), xlab = "Task completion time (min)", main="")
mean(as.numeric(worker_response_time))
sd(as.numeric(worker_response_time))

worker_response3 <- cbind(worker_response2, worker_response_time)

# load "answer key" and prepare it (as assessed in Gardenier et al. 2021)
answer_july19 <- read.csv(paste0(input_dir, "answer_key_Jul-19-2021.csv"), header = TRUE)
answer_july22 <- read.csv(paste0(input_dir, "answer_key_Jul-22-2021.csv"), header = TRUE)
answer_key <- rbind(answer_july19, answer_july22)
answer_key2 <- answer_key
answer_key2$X <- NULL

# merge answer key and worker response to be in the same datasheet
result_compare <- merge(worker_response2, answer_key2, all = TRUE)
#result_compare2 <- result_compare[, c(1, 6, 8, 9, 11:20, 22:41),]
result_compare2 <- result_compare[, c(1, 6, 8, 9, 11:41),]

#Get Task Number, Worker_ID, Pair_ID, Answer data frame
worker_res = gather(result_compare2[,c(2,5:15)], key="Q_ID", value="Answer", c(2:11),-Worker_id, -Task_number)
worker_res= na.exclude(worker_res)

#For each task, create data frame with Questions as rows and worker responses as columns, exclude workers wit NA and giving the same response to all questions
worker_compare=list()

for(i in 1:11)
{
  dat1 <- worker_res[which(worker_res$Task_number==c(0:10)[i]),]
  worker_compare[[i]] <- spread(dat1,Worker_id, Answer)
  bad_cols=colnames(worker_compare[[i]])[colSums(is.na(worker_compare[[i]])) > 0]#exclude workers with NA values
  print(bad_cols)
  print(length(bad_cols)) # get for each HIT how many workes were excluded for NA
  
  if(length(bad_cols) > 0)
     {
       worker_compare[[i]] <- worker_compare[[i]][,-which(colnames(worker_compare[[i]])%in%bad_cols==T)]
  }
  
  worker_compare[[i]] <- cbind(worker_compare[[i]][,1:2], Filter(sd, worker_compare[[i]][,3:ncol(worker_compare[[i]])])) # Exclude workers giving the same answer to all questions
  
}

#################################################################################################################
##### Assess the correlation between raters and calculate ICC for reliability when considering all workers ######
#################################################################################################################

pdfPath = c(paste(output_dir, "/Correlation_plots_allworkers.pdf", sep = ""))
pdf(file=pdfPath)
cor_allHIT_allworker=list()
allworker_icc=list()
for(i in 1:11)
{
  print(i)
  dat=worker_compare[[i]][,3:ncol(worker_compare[[i]])]
  cormat=cor(dat,method = "spearman")
  cor_allHIT_allworker[[i]]=cormat
  corrplot(cormat,type="upper",title = i,order = "hclust",hclust.method = "average")
  allworker_icc[[i]]=icc(dat,model = "twoway",type = "agreement")$"value"
}
dev.off()


###################################################################################################
##################################### Filtering workers  ##########################################
###################################################################################################

# get those that pass positive and/or negative control questions
# create an empty master sheet
pass_dum_easy <- result_compare2[-c(1:nrow(result_compare2)),]
pass_dum_easy_list <- list()
pass_easy_list <- list()
empty <- pass_dum_easy
pass_dum <-pass_dum_easy
pass_easy <- pass_dum_easy
pass_dum_loose <- pass_dum_easy
pass_dum_loose_easy <- pass_dum_easy
dummy_q <- ""
easy_q <- ""

# iterate through each HIT
for (i in 1:length(unique(result_compare2$Task_number))) {
  temp_cur_HIT <- result_compare2[which(result_compare2$Task_number == (i-1)),]#task number goes from 0-10
  
  # iterate through columns
  colNum = 16
  while(colNum <= ncol(temp_cur_HIT)) {
    #print(colnames(temp_cur_HIT)[colNum])
    # find for dummy
    if (temp_cur_HIT[1, colNum] == (-1)) {
      colName <- colnames(temp_cur_HIT)[colNum]
      colName_split <- strsplit(colName, "_")
      dummy_q <- colName_split[[1]][1]
      dummy_q_index <- as.integer(which(colnames(temp_cur_HIT)==dummy_q))
      dummy_pair_id_index <- colNum
      dummy_key_index <- colNum + 1
    } else if ((temp_cur_HIT[1, colNum] == (-2)) |(temp_cur_HIT[1, colNum] == (-3))){
      colName_e <- colnames(temp_cur_HIT)[colNum]
      colName_e_split <- strsplit(colName_e, "_")
      easy_q <- colName_e_split[[1]][1]
      easy_q_index <- as.integer(which(colnames(temp_cur_HIT)==easy_q))
      easy_pair_id_index <- colNum
      easy_key_index <- colNum + 1
    }
      colNum = colNum + 2
      
  }
  
  pass_dum_easy <- rbind(pass_dum_easy, temp_cur_HIT[which((temp_cur_HIT[, dummy_q_index] == 0) & (temp_cur_HIT[, easy_q_index] == 3)),])
  pass_dum_easy_list[[i]] <- temp_cur_HIT[which((temp_cur_HIT[, dummy_q_index] == 0) & (temp_cur_HIT[, easy_q_index] == 3)),]
  pass_dum_easy_list[[i]][, c(dummy_q_index, easy_q_index, dummy_pair_id_index, dummy_key_index, easy_pair_id_index, easy_key_index)] <- NULL
  names(pass_dum_easy_list)[i] <- as.character((i-1))

  pass_dum <- rbind(pass_dum, temp_cur_HIT[which((temp_cur_HIT[, dummy_q_index] == 0)),])
  pass_dum_loose <- rbind(pass_dum, temp_cur_HIT[which((temp_cur_HIT[, dummy_q_index] >= (-1)) & (temp_cur_HIT[, dummy_q_index] <= (1))),])
  pass_dum_loose_easy <- rbind(pass_dum_easy, temp_cur_HIT[which((temp_cur_HIT[, dummy_q_index] >= (-1)) & (temp_cur_HIT[, dummy_q_index] <= (1)) & (temp_cur_HIT[, easy_q_index] > 0)),])
  
  # people who passed all positive control questions (definition: chose the more lame cow, regardless of the degree of differences between the 2 cows)
  pass_easy <- rbind(pass_easy, temp_cur_HIT[which((temp_cur_HIT[, easy_q_index] > 0)),])
  pass_easy_list[[i]] <- temp_cur_HIT[which((temp_cur_HIT[, easy_q_index] > 0)),]
  names(pass_easy_list)[i] <- as.character((i-1))
}


#############################################################################################################################################################################
##### Assess the correlation between raters and calculate ICC for reliability for workers that passed both the positive and negative control questions (strong filter) ######
#############################################################################################################################################################################

worker_res_pass = gather(pass_dum_easy[,c(2,5:15)], key="Q_ID", value="Answer", c(2:11),-Worker_id, -Task_number)
worker_res_pass= na.exclude(worker_res_pass)

#Get the worker_res_pass dataframe without control question responses (these are the same for all workers after applying this filter)
worker_res_pass2=worker_res_pass[-c(1:nrow(worker_res_pass)),]
for(i in 1:11)
{
  worker_res_pass_tmp = gather(pass_dum_easy_list[[i]][,c(2,5:13)], key="Q_ID", value="Answer", c(2:9),-Worker_id, -Task_number)
  worker_res_pass2=rbind(worker_res_pass2,worker_res_pass_tmp)
}

worker_res_pass2 <- na.exclude(worker_res_pass2)

#Use only answers to real questions (no control) for reliability assessment
worker_compare_pass2=list()
for(i in 1:length(unique(worker_res_pass2$Task_number)))
{
  dat1 <- worker_res_pass2[which(worker_res_pass2$Task_number==unique(worker_res_pass2$Task_number)[i]),]
  worker_compare_pass2[[i]] <- spread(dat1,Worker_id, Answer)
  bad_cols=colnames(worker_compare_pass2[[i]])[colSums(is.na(worker_compare_pass2[[i]])) > 0]#exclude workers with NA values
  
  if(length(bad_cols) > 0)
  {
    worker_compare_pass2[[i]] <- worker_compare_pass2[[i]][,-which(colnames(worker_compare_pass2[[i]])%in%bad_cols==T)]
  }
  
  worker_compare_pass2[[i]] <- cbind(worker_compare_pass2[[i]][,1:2], Filter(sd, worker_compare_pass2[[i]][,3:ncol(worker_compare_pass2[[i]])])) # Exclude workers giving the same answer to all questions
}

#Get correlation between workers and ICC based on 8 real questions only
pdfPath = c(paste(output_dir, "Correlation_plots_pass.pdf", sep = ""))
pdf(file=pdfPath)
cor_allHIT_pass=list()
pass_icc=list()
for(i in 1:11)
{
  print(i)
  dat=worker_compare_pass2[[i]][,3:ncol(worker_compare_pass2[[i]])] 
  cormat=cor(dat,method = "spearman")
  cor_allHIT_pass[[i]]=cormat
  corrplot(cormat,type="upper",title = i,order = "hclust",hclust.method = "average")
  pass_icc[[i]]=icc(dat,model = "twoway",type = "agreement")$"value"
  
}
dev.off()


#######################################################################################################################################################
##### Assess the correlation between raters and calculate ICC for reliability for workers passing the positive control question (weak filter)    ######
#######################################################################################################################################################

worker_res_easypass = gather(pass_easy[,c(2,5:15)], key="Q_ID", value="Answer", c(2:11),-Worker_id, -Task_number)
worker_res_easypass= na.exclude(worker_res_easypass)


worker_compare_easypass=list()
for(i in 1:length(unique(worker_res_easypass$Task_number)))
{
  dat1 <- worker_res_easypass[which(worker_res_easypass$Task_number==unique(worker_res_easypass$Task_number)[i]),]
  worker_compare_easypass[[i]] <- spread(dat1,Worker_id, Answer)
  bad_cols=colnames(worker_compare_easypass[[i]])[colSums(is.na(worker_compare_easypass[[i]])) > 0]#exclude workers with NA values
  
  if(length(bad_cols) > 0)
  {
    worker_compare_easypass[[i]] <- worker_compare_easypass[[i]][,-which(colnames(worker_compare_easypass[[i]])%in%bad_cols==T)]
  }
  
  worker_compare_easypass[[i]] <- cbind(worker_compare_easypass[[i]][,1:2], Filter(sd, worker_compare_easypass[[i]][,3:ncol(worker_compare_easypass[[i]])])) # Exclude workers giving the same answer to all questions
  
}

pdfPath = c(paste(output_dir, "Correlation_plots_easypass.pdf", sep = ""))
pdf(file=pdfPath)
cor_allHIT=list()
easypass_icc=list()
for(i in 1:11)
{
  print(i)
  dat=Filter(sd, worker_compare_easypass[[i]][,3:ncol(worker_compare_easypass[[i]])]) #Exclude workers who gave the same answer to all questions
  cormat=cor(dat,method = "spearman")
  cor_allHIT[[i]]=cormat
  corrplot(cormat,type="upper",title = i,order = "hclust",hclust.method = "average")
  easypass_icc[[i]]=icc(dat,model = "twoway",type = "agreement")$"value"
  
}
dev.off()

############################################################
###############  CLUSTERING  workers   #####################
############################################################

# Get all the answers in a list form - this is already filtered for NA and SD
all_worker_list=worker_compare
for(i in 1:11)
{
  all_worker_list[[i]]=gather(all_worker_list[[i]], key="Worker_id", value="Answer", c(3:ncol(all_worker_list[[i]])))
  all_worker_list[[i]]=spread(all_worker_list[[i]], key = "Q_ID", value = "Answer")
}

worker_cl_all <- list()
worker_cl_pass <- list()
worker_cl_easypass <- list()
for(i in 1:11)
{
  #### All workers with no NA and SD >0 ####
  worker_resp <- all_worker_list[[i]][,3:12]
  rownames(worker_resp) <- all_worker_list[[i]][,2]
  
  dist_mat <- dist(worker_resp, method = 'euclidean') #get distance matrix
  
  hclust_avg <- hclust(dist_mat, method = "average") #create clusters
  plot(hclust_avg, main = paste("all", i, sep = "-"))
  abline(h = mean(dist_mat), col = 'red') #visualize mean distance cut line
  
  cut_avg <- cutree(hclust_avg, k= mean(dist_mat)) #cut the clusters at mean distance
  print(paste("All",i, "Dunn Index:", sep="-"))
  print(dunn(distance = dist_mat, cut_avg, method = "euclidean"))#calculate Dunn Index to assess quality
  
  worker_resp_cl<- cbind(worker_resp, cut_avg) #Get which worker is in which cluster
  
  #Get only the workers from the largest cluster
  worker_cl_all[[i]] <- worker_resp_cl[which(worker_resp_cl$cut_avg==names(which.max(table(worker_resp_cl$cut_avg)))),]
  
  ### Workers passing the strong filter ###
  worker_resp_pass <- pass_dum_easy_list[[i]][,5:12]
  rownames(worker_resp_pass) <- pass_dum_easy_list[[i]][,2]
  worker_resp_pass <- na.exclude(worker_resp_pass) #Exclude workers with NA responses
  if(length(which(apply(worker_resp_pass, 1, sd)==0))!=0)
  {
    worker_resp_pass <- worker_resp_pass[-which(apply(worker_resp_pass, 1, sd)==0),] #Excluding workers with no SD
  }
  
  dist_mat_pass <- dist(worker_resp_pass, method = 'euclidean') #get distance matrix
  
  hclust_avg_pass <- hclust(dist_mat_pass, method = "average") #create clusters
  plot(hclust_avg_pass, main = paste("strong", i, sep = "-"))
  abline(h = mean(dist_mat_pass), col = 'red') #visualize mean distance cut line
  
  cut_avg_pass <- cutree(hclust_avg_pass, k= mean(dist_mat_pass)) #cut the clusters at mean distance
  print(paste("Pass",i, "Dunn Index:", sep="-"))
  print(dunn(distance = dist_mat_pass, cut_avg_pass , method = "euclidean"))#calculate Dunn Index to assess quality
  
  worker_resp_cl_pass <- cbind(worker_resp_pass, cut_avg_pass) #Get which worker is in which cluster
  
  #Get only the workers from the largest cluster
  worker_cl_pass[[i]] <- worker_resp_cl_pass[which(worker_resp_cl_pass$cut_avg_pass==names(which.max(table(worker_resp_cl_pass$cut_avg_pass)))),]
  
  ### Workers passing the weak filter ####
  worker_resp_easypass <- pass_easy_list[[i]][,5:14]
  rownames(worker_resp_easypass) <- pass_easy_list[[i]][,2]
  worker_resp_easypass <- na.exclude(worker_resp_easypass) #Exclude workers with NA responses
  if(length(which(apply(worker_resp_easypass, 1, sd)==0))!=0)
  {
    worker_resp_easypass <- worker_resp_easypass[-which(apply(worker_resp_easypass, 1, sd)==0),] #Excluding workers with no SD
  }
 
  dist_mat_easypass <- dist(worker_resp_easypass, method = 'euclidean') #get distance matrix
  
  hclust_avg_easypass <- hclust(dist_mat_easypass, method = "average") #create clusters
  plot(hclust_avg_easypass, main = paste("weak", i, sep = "-"))
  abline(h = mean(dist_mat_easypass), col = 'red') #visualize mean distance cut line
  
  cut_avg_easypass <- cutree(hclust_avg_easypass, k= mean(dist_mat_easypass)) #cut the clusters at mean distance
  print(paste("Easypass",i, "Dunn Index:", sep="-"))
  print(dunn(distance = dist_mat_easypass, cut_avg_easypass , method = "euclidean"))#calculate Dunn Index to assess quality
  
  worker_resp_cl_easypass <- cbind(worker_resp_easypass, cut_avg_easypass) #Get which worker is in which cluster
  
  #Get only the workers from the largest cluster
  worker_cl_easypass[[i]] <- worker_resp_cl_easypass[which(worker_resp_cl_easypass$cut_avg_easypass==names(which.max(table(worker_resp_cl_easypass$cut_avg_easypass)))),]
  
}

#######################################################################################################
##### Assess the correlation between raters and calculate ICC for workers in the largest cluster ######
#######################################################################################################

#### Reformat the cluster results to assess ICC ####
worker_cl_all_compare=worker_cl_all
worker_cl_easypass_compare=worker_cl_easypass
worker_cl_pass_compare=worker_cl_pass
for(i in 1:11)
{
  worker_cl_all_compare[[i]]=cbind(rownames(worker_cl_all_compare[[i]]), rep(i-1,nrow(worker_cl_all_compare[[i]])),worker_cl_all_compare[[i]][,c(1:ncol(worker_cl_all_compare[[i]])-1)])
  colnames(worker_cl_all_compare[[i]])[1:2]=c("Worker_id","Task_number")
  
  worker_cl_all_compare[[i]]=gather(worker_cl_all_compare[[i]], key="Q_ID", value="Answer", c(1:12),-Worker_id, -Task_number)
  worker_cl_all_compare[[i]]=spread(worker_cl_all_compare[[i]],Worker_id, Answer)
  
  worker_cl_easypass_compare[[i]]=cbind(rownames(worker_cl_easypass_compare[[i]]), rep(i-1,nrow(worker_cl_easypass_compare[[i]])),worker_cl_easypass_compare[[i]][,c(1:ncol(worker_cl_easypass_compare[[i]])-1)])
  colnames(worker_cl_easypass_compare[[i]])[1:2]=c("Worker_id","Task_number")
  
  worker_cl_easypass_compare[[i]]=gather(worker_cl_easypass_compare[[i]], key="Q_ID", value="Answer", c(1:12),-Worker_id, -Task_number)
  worker_cl_easypass_compare[[i]]=spread(worker_cl_easypass_compare[[i]],Worker_id, Answer)
  
  worker_cl_pass_compare[[i]]=cbind(rownames(worker_cl_pass_compare[[i]]), rep(i-1,nrow(worker_cl_pass_compare[[i]])),worker_cl_pass_compare[[i]][,c(1:ncol(worker_cl_pass_compare[[i]])-1)])
  colnames(worker_cl_pass_compare[[i]])[1:2]=c("Worker_id","Task_number")
  
  worker_cl_pass_compare[[i]]=gather(worker_cl_pass_compare[[i]], key="Q_ID", value="Answer", c(1:10),-Worker_id, -Task_number)
  worker_cl_pass_compare[[i]]=spread(worker_cl_pass_compare[[i]],Worker_id, Answer)
}


##### Plot agreement between cluster members and also calculate ICC #####

### All workers clustered
pdfPath = c(paste(output_dir, "Correlation_plots_all_clustered.pdf", sep = ""))
pdf(file=pdfPath)
cor_allHIT_all_cl=list()
all_cl_icc=list()
for(i in 1:11)
{
  print(i)
  dat=worker_cl_all_compare[[i]][,3:ncol(worker_cl_all_compare[[i]])]
  cormat=cor(dat,method = "spearman")
  cor_allHIT_all_cl[[i]]=cormat
  corrplot(cormat,type="upper",title = i,order = "hclust",hclust.method = "average")
  all_cl_icc[[i]]=icc(dat,model = "twoway",type = "agreement")$"value"
}
dev.off()

### Strong filter and then clustering
pdfPath = c(paste(output_dir, "Correlation_plots_pass_clustered.pdf", sep = ""))
pdf(file=pdfPath)
cor_allHIT_pass_cl=list()
pass_cl_icc=list()
for(i in 1:11)
{
  print(i)
  dat=worker_cl_pass_compare[[i]][,3:ncol(worker_cl_pass_compare[[i]])]
  cormat=cor(dat,method = "spearman")
  cor_allHIT_pass_cl[[i]]=cormat
  corrplot(cormat,type="upper",title = i,order = "hclust",hclust.method = "average")
  pass_cl_icc[[i]]=icc(dat,model = "twoway",type = "agreement")$"value"
}
dev.off()


### Weak filter and then clustering
pdfPath = c(paste(output_dir, "Correlation_plots_easypass_clustered.pdf", sep = ""))
pdf(file=pdfPath)
cor_allHIT_easypass_cl=list()
easypass_cl_icc=list()
for(i in 1:11)
{
  print(i)
  dat=worker_cl_easypass_compare[[i]][,3:ncol(worker_cl_easypass_compare[[i]])]
  cormat=cor(dat,method = "spearman")
  cor_allHIT_easypass_cl[[i]]=cormat
  corrplot(cormat,type="upper",title = i,order = "hclust",hclust.method = "average")
  easypass_cl_icc[[i]]=icc(dat,model = "twoway",type = "agreement")$"value"
}
dev.off()


##########################################################################################
#### Get ICC results per HIT from all different datasets (all, filtering, clustering) ####
##########################################################################################

icc_results<- as.data.frame(cbind(c(0:10),unlist(allworker_icc),unlist(all_cl_icc),unlist(easypass_icc),unlist(easypass_cl_icc),unlist(pass_icc),unlist(pass_cl_icc)))
colnames(icc_results)=c("Task_number","All_workers","All_workers_cluster","Weak_filter","Weak_filter_cluster","Strong_filter","Strong_filter_cluster")

icc_results_long <- gather(icc_results,key = Filter,value="ICC",-Task_number)

#### Add number of workers kept for each HIT under different filters ####
icc_results_workerno <- icc_results
for(i in 1:11)
{
  icc_results_workerno[i,2]=ncol(worker_compare[[i]])-2
  icc_results_workerno[i,3]=ncol(worker_cl_all_compare[[i]])-2
  icc_results_workerno[i,4]=ncol(worker_compare_easypass[[i]])-2
  icc_results_workerno[i,5]=ncol(worker_cl_easypass_compare[[i]])-2
  icc_results_workerno[i,6]=ncol(worker_compare_pass2[[i]])-2
  icc_results_workerno[i,7]=ncol(worker_cl_pass_compare[[i]])-2
  
}

icc_results2 <- merge(icc_results,icc_results_workerno,by="Task_number")
icc_results2 <- icc_results2[,c(1,2,8,3,9,4,10,5,11,6,12,7,13)]

stats_icc_mean <- round(sapply(icc_results2[,2:13],mean),2)
stats_icc_sd <- round(sapply(icc_results2[,2:13],sd),2)

stats_summary <- as.data.frame(rbind(stats_icc_mean,stats_icc_sd))

##########################################################################################################################
##### Assess agreement of average worker response with experts for all unfiltered, filtered and clustered data sets ######
##########################################################################################################################

### Get average of worker responses for all questions in each dataset ###
mean_resp <- data.frame(Question=character(),Mean_worker_response=numeric(),stringsAsFactors=FALSE) 
for(i in 1:11)
{
  dat=worker_compare[[i]]
  Question=paste(dat[,1],dat[,2],sep="-")
  All_worker_means=round(rowMeans(dat[,3:ncol(dat)]),2)
  mean_resp=rbind(mean_resp,cbind(Question,All_worker_means))
  
}

mean_resp2 <- data.frame(Question=character(),Mean_worker_response=numeric(),stringsAsFactors=FALSE) 
for(i in 1:11)
{
  dat=worker_compare_pass2[[i]]
  Question=paste(dat[,1],dat[,2],sep="-")
  Pass_worker_means=round(rowMeans(dat[,3:ncol(dat)]),2)
  mean_resp2=rbind(mean_resp2,cbind(Question,Pass_worker_means))
  
}

mean_resp3 <- data.frame(Question=character(),Mean_worker_response=numeric(),stringsAsFactors=FALSE) 
for(i in 1:11)
{
  dat=worker_compare_easypass[[i]]
  Question=paste(dat[,1],dat[,2],sep="-")
  Easypass_worker_means=round(rowMeans(dat[,3:ncol(dat)]),2)
  mean_resp3=rbind(mean_resp3,cbind(Question,Easypass_worker_means))
  
}

mean_resp4 <- data.frame(Question=character(),Mean_worker_response=numeric(),stringsAsFactors=FALSE) 
for(i in 1:11)
{
  dat=worker_cl_all_compare[[i]]
  Question=paste(dat[,1],dat[,2],sep="-")
  All_cluster_worker_means=round(rowMeans(dat[,3:ncol(dat)]),2)
  mean_resp4=rbind(mean_resp4,cbind(Question,All_cluster_worker_means))
  
}

mean_resp5 <- data.frame(Question=character(),Mean_worker_response=numeric(),stringsAsFactors=FALSE) 
for(i in 1:11)
{
  dat=worker_cl_pass_compare[[i]]
  Question=paste(dat[,1],dat[,2],sep="-")
  Pass_cluster_worker_means=round(rowMeans(dat[,3:ncol(dat)]),2)
  mean_resp5=rbind(mean_resp5,cbind(Question,Pass_cluster_worker_means))
  
}

mean_resp6 <- data.frame(Question=character(),Mean_worker_response=numeric(),stringsAsFactors=FALSE) 
for(i in 1:11)
{
  dat=worker_cl_easypass_compare[[i]]
  Question=paste(dat[,1],dat[,2],sep="-")
  Easypass_cluster_worker_means=round(rowMeans(dat[,3:ncol(dat)]),2)
  mean_resp6=rbind(mean_resp6,cbind(Question,Easypass_cluster_worker_means))
  
}

mean_resp_all <- merge(mean_resp,mean_resp3,by="Question")
mean_resp_all <- merge(mean_resp_all,mean_resp2,by="Question",all.x = F ) #From here on we exclude easy and dummy questions from the assessment
mean_resp_all <- merge(mean_resp_all, mean_resp4, by="Question")
mean_resp_all <- merge(mean_resp_all, mean_resp5, by="Question")
mean_resp_all <- merge(mean_resp_all, mean_resp6, by="Question")

mean_resp_all[,c(2:7)] <- sapply(mean_resp_all[,c(2:7)], as.character)
mean_resp_all[,c(2:7)] <- sapply(mean_resp_all[,c(2:7)], as.numeric)

### Get the Gardenier et al 2021 observer ratings ###
expert <- answer_key2[,c(1,6,8,10,12,14,16,18,20,22,24)]
colnames(expert)[2:11]=c("q1","q2","q3","q4","q5","q6","q7","q8","q9","q10")
expert2 <- gather(expert,key=Question,value=Expert_rating,-Task_number)
expert3 <- cbind(paste(expert2$Task_number,expert2$Question,sep="-"),expert2$Expert_rating)
colnames(expert3)=c("Question","Expert_rating")
expert3 <- as.data.frame(expert3)
expert3$Expert_rating <- as.numeric(as.character(expert3$Expert_rating))

### combine worker responses with Gardenier et al. 2021 observer rating ###

combined_ratings <- merge(mean_resp_all,expert3,by="Question")

### Get 5 new trained lameness expert ratings answering the same HITs as click workers ###
expert_new <- read.csv(paste0(input_dir, "expert_answer_long_format_5expert.csv"))
expert_new <- expert_new[,2:7]

#transform expert answers to -3 to 3 scale
expert_new[expert_new == 1] <- -3
expert_new[expert_new == 1.16] <- -2
expert_new[expert_new == 1.32] <- -1
expert_new[expert_new == 1.50] <- 0
expert_new[expert_new == 1.68] <- 1
expert_new[expert_new == 2.00] <- 3
expert_new[expert_new == 1.84] <- 2

#Assess ICC between new experts
icc(expert_new[,2:6],model = "twoway",type = "agreement")
expert_new_hit <- cbind(expert_new, rep(c(0,1,10,2:9), times=rep(10,11)))
colnames(expert_new_hit)[7]="HIT_id"

#Assess ICC for each HIT among new experts
icc_expert_hit=c()
for(i in 1:11)
{
  dat=expert_new_hit[which(expert_new_hit$HIT_id==i-1),]
  icc_expert_hit[i]=round(icc(dat[,2:6],model = "twoway",type = "agreement")$"value",2)
}

round(mean(icc_expert_hit),2)
round(sd(icc_expert_hit),2)

#Get average expert response
expert_new$average_new_expert <- round(rowMeans(expert_new[,2:6]),2)

### Combine new expert responses with all others (this keeps real questions only and gets rid of control)
combined_ratings2 <- merge(combined_ratings,expert_new, by.x="Question", by.y="question_id")

##### Assess ICC between new expert average and each method and plot results #####
par(mfrow=c(2,3))
icc_expert_new_worker=c()
for(i in 2:7)
{
  print(icc(combined_ratings2[,c(i,14)],model = "twoway",type = "agreement"))
  icc_expert_new_worker[i-1]=round(icc(combined_ratings2[,c(i,14)],model = "twoway",type = "agreement")$"value",2)
  plot(combined_ratings2[,14],combined_ratings2[,i],
       ylab=colnames(combined_ratings2)[i],xlab=colnames(combined_ratings2)[14],xlim=c(-3,3),ylim=c(-3,3),
       main=paste("ICC=",icc_expert_new_worker[i-1],sep=""),pch=19)
  abline(h=0,col="red")
  abline(v=0,col="red")
}

    ### Assess ICC between new expert average and each method by HIT ###
    combined_ratings3=combined_ratings2
    combined_ratings3$HIT_id=rep(c(0,1,10,2:9), times=rep(8,11))
    
    icc_expert_new_worker_hit=matrix(0,11,7)
    colnames(icc_expert_new_worker_hit)=c("HIT_id",colnames(combined_ratings3[2:7]))
    for(i in 2:7) #goes over filtering methods
    {
      for(k in 1:11)#goes over HITs
      {
        icc_expert_new_worker_hit[k,1]=k-1
        icc_expert_new_worker_hit[k,i]=round(icc(combined_ratings3[which(combined_ratings3$HIT_id==k-1),c(i,14)],model = "twoway",type = "agreement")$"value",2)
      }
    }
    
    for(i in 2:7)
    {
      print(i)
      print(round(mean(icc_expert_new_worker_hit[,i]),2))
      print(round(sd(icc_expert_new_worker_hit[,i]),2))
    }

#### Plot all worker and strong filter with clustering agreement between workers and experts ####
par(mfrow=c(1,2))
  plot(combined_ratings2[,14],combined_ratings2[,2],
       ylab="Average worker rating",xlab="Average expert rating",xlim=c(-3,3),ylim=c(-3,3),
       #main=paste("ICC=",icc_expert_new_worker[1],sep=""),
       pch=19, frame.plot=F)
  axis(side=1)
  
  plot(combined_ratings2[,14],combined_ratings2[,6],
       ylab="",xlab="Average expert rating",xlim=c(-3,3),ylim=c(-3,3),
       #main=paste("ICC=",icc_expert_new_worker[5],sep=""),
       pch=19,frame.plot=F)
  axis(side=1)
 
################################################################################################
#### Dividing the original data frame into 2 data frames of high & low lameness differences ####
################################################################################################

# get the question and  task number in expert_new
target <- expert2[, c("Task_number", "Question")]
target$question_id <- paste(target$Task_number, "-", target$Question, sep = "")
expert_new2 <- merge(expert_new, target)
  
# filter expert rating (more than 1 or less than -1) ; easy qs
high_dif <- expert_new2[which((expert_new2$average_new_expert > 1.0) | (expert_new2$average_new_expert < (-1.0))),]
  
# filter expert rating (less= to 1 or more= to -1) ; hard qs
low_dif <- expert_new2[which((expert_new2$average_new_expert <= 1.0) & (expert_new2$average_new_expert >= (-1.0))),]
  
# create duplicates of worker_compare
hi_worker_compare <- worker_compare
lo_worker_compare <- worker_compare

#

for (i in 1:length(hi_worker_compare)) {
  
  task <- (hi_worker_compare[[i]][1, "Task_number"])
  Current_task <- high_dif[which(high_dif$Task_number == task),]
  cur_q <- Current_task$Question
  hi_worker_compare[[i]] <- hi_worker_compare[[i]][which(hi_worker_compare[[i]]$Q_ID %in% cur_q),]
  
  task <- (lo_worker_compare[[i]][1, "Task_number"])
  Current_task <- low_dif[which(low_dif$Task_number == task),]
  cur_q <- Current_task$Question
  lo_worker_compare[[i]] <- lo_worker_compare[[i]][which(lo_worker_compare[[i]]$Q_ID %in% cur_q),]
  
}
  

#################################################################################################
################################## low llameness diffs ##########################################
#### Randomly sample 43-2 workers 100 times from all HIT-s and assess agreement with experts ####
#################################################################################################

set.seed=1987
mean_resp_random <- list()
for(k in 1:42) # levels of random sample size, 43 to 2, increments of 1 (44 is the lowest number of workers in a HIT after data cleaning)
{
  print(k)
  size <- c(43:2)
  
  random_mean_all=as.data.frame(matrix(data = NA,nrow = 110,ncol = 101))
  for(j in 1:100)
  {
    random_mean <- data.frame(Question=character(),Mean_worker_response=numeric(),stringsAsFactors=FALSE)
    for(i in 1:11)
    {
      columns <- c(3:ncol(lo_worker_compare[[i]])) # get numbers of columns to sample from
      random_columns <- sample(columns,size=size[k],replace = F)
      #print(random_columns)
      dat=cbind(lo_worker_compare[[i]][,1:2],lo_worker_compare[[i]][,random_columns])
      Question=paste(dat[,1],dat[,2],sep="-")
      Random_worker_means=round(rowMeans(dat[,3:ncol(dat)]),2)
      random_mean=rbind(random_mean,cbind(Question,Random_worker_means))
    }
    random_mean_all[1:nrow(random_mean),1]=as.character(random_mean$Question)
    random_mean_all[1:nrow(random_mean),j+1]=as.numeric(as.character(random_mean[,2]))
  }
  random_mean_all <- na.omit(random_mean_all)
  
  mean_resp_random[[k]]=random_mean_all
  names(mean_resp_random)[k]=size[k]
}

#### Combine random sample mean columns with all worker ratings (get rid of control question responses) ####

mean_resp_random_expert=mean_resp_random
for(i in 1:42)
{
  colnames(mean_resp_random_expert[[i]])=c("Question",as.character(c(1:100)))
  mean_resp_random_expert[[i]]=merge(mean_resp_random_expert[[i]],combined_ratings2[,c(1,14)],by="Question")
}

#### Assess random sample response agreement with experts ####

icc_many_random=list()
for(i in 1:42)
{
  many_icc=c()
  for(j in 1:100)
  {
    many_icc[j]=round(icc(mean_resp_random_expert[[i]][,c(j+1,102)],model = "twoway",type = "agreement")$"value",2)
  }
  icc_many_random[[i]]=many_icc
  names(icc_many_random)[i]=c(43:2)[i]
}

icc_all=do.call(cbind,icc_many_random)

icc_all2=data.frame(ICC=numeric(),Worker_no=numeric(),stringsAsFactors=FALSE)
for(i in 1:42)
{
  dat=cbind(icc_all[,i],rep(colnames(icc_all)[i]))
  icc_all2=rbind(icc_all2,dat)
}
colnames(icc_all2)=c("ICC","Number_of_workers")

icc_all_lo <- icc_all2

#################################################################################################
################################## high llameness diffs #########################################
#### Randomly sample 43-2 workers 100 times from all HIT-s and assess agreement with experts ####
#################################################################################################

set.seed=1987
mean_resp_random <- list()
for(k in 1:42) # levels of random sample size, 43 to 2, increments of 1 (44 is the lowest number of workers in a HIT after data cleaning)
{
  print(k)
  size <- c(43:2)
  
  random_mean_all=as.data.frame(matrix(data = NA,nrow = 110,ncol = 101))
  for(j in 1:100)
  {
    random_mean <- data.frame(Question=character(),Mean_worker_response=numeric(),stringsAsFactors=FALSE)
    for(i in 1:11)
    {
      columns <- c(3:ncol(hi_worker_compare[[i]])) # get numbers of columns to sample from
      random_columns <- sample(columns,size=size[k],replace = F)
      #print(random_columns)
      dat=cbind(hi_worker_compare[[i]][,1:2],hi_worker_compare[[i]][,random_columns])
      Question=paste(dat[,1],dat[,2],sep="-")
      Random_worker_means=round(rowMeans(dat[,3:ncol(dat)]),2)
      random_mean=rbind(random_mean,cbind(Question,Random_worker_means))
    }
    random_mean_all[1:nrow(random_mean),1]=as.character(random_mean$Question)
    random_mean_all[1:nrow(random_mean),j+1]=as.numeric(as.character(random_mean[,2]))
  }
  random_mean_all <- na.omit(random_mean_all)
  
  mean_resp_random[[k]]=random_mean_all
  names(mean_resp_random)[k]=size[k]
}

#### Combine random sample mean columns with all worker ratings (get rid of control question responses) ####

mean_resp_random_expert=mean_resp_random
for(i in 1:42)
{
  colnames(mean_resp_random_expert[[i]])=c("Question",as.character(c(1:100)))
  mean_resp_random_expert[[i]]=merge(mean_resp_random_expert[[i]],combined_ratings2[,c(1,14)],by="Question")
}

#### Assess random sample response agreement with experts ####

icc_many_random=list()
for(i in 1:42)
{
  many_icc=c()
  for(j in 1:100)
  {
    many_icc[j]=round(icc(mean_resp_random_expert[[i]][,c(j+1,102)],model = "twoway",type = "agreement")$"value",2)
  }
  icc_many_random[[i]]=many_icc
  names(icc_many_random)[i]=c(43:2)[i]
}

icc_all=do.call(cbind,icc_many_random)

icc_all2=data.frame(ICC=numeric(),Worker_no=numeric(),stringsAsFactors=FALSE)
for(i in 1:42)
{
  dat=cbind(icc_all[,i],rep(colnames(icc_all)[i]))
  icc_all2=rbind(icc_all2,dat)
}
colnames(icc_all2)=c("ICC","Number_of_workers")

icc_all_hi <- icc_all2


####################################### Save the results ##########################################
# save csv
write.csv(paste0(output_dir, icc_all_lo, file = "icc_all_lo.csv"), row.names = FALSE)
write.csv(paste0(output_dir, file = "icc_all_hi.csv") , row.names = FALSE)

################################################################################################
######## assess the interobserver reliability among experts for both the questions with  #######
############################ low and high lameness differences #################################
################################################################################################
# rename column
target_questions <- as.data.frame(combined_ratings2[,"Question"])
colnames(target_questions)=("question_id")

# delete control questions
target_expert_new <- merge(target_questions, expert_new)

# get John's expert ratings, they did absolute scoring, and calcuated the absolute scoring differences between 2 cows
expert_john <- expert2
expert_john$question_id <- paste(expert_john$Task_number, "-", expert_john$Question, sep = "")
expert_john2 <- expert_john[, c("Expert_rating","question_id")]
colnames(expert_john2) <- c("John_abs_score_dif", "question_id")
target_expert_new2 <- merge(target_expert_new, expert_john2)
target_expert_new2$John_abs_score_dif_pos <- abs(target_expert_new2$John_abs_score_dif)

# filter expert rating (more than 1 or less than -1) ; easy qs
exp_high_dif <- target_expert_new2[which((target_expert_new2$average_new_expert > 1.0) | (target_expert_new2$average_new_expert < (-1.0))),]

# filter expert rating (less= to 1 or more= to -1) ; hard qs
exp_low_dif <- target_expert_new2[which((target_expert_new2$average_new_expert <= 1.0) & (target_expert_new2$average_new_expert >= (-1.0))),]

icc(exp_high_dif[,2:6],model = "twoway",type = "agreement")
icc(exp_low_dif[,2:6],model = "twoway",type = "agreement")

# how many easy questions
nrow(exp_high_dif)

# how many hard question
nrow(exp_low_dif)


################################################################################################
##### assess the interobserver reliability among click worers for both the questions with  #####
############################ low and high lameness differences #################################
################################################################################################

cor_allHIT_allworker_hi=list()
allworker_icc_hi=list()
for(i in 1:11)
{
  dat=hi_worker_compare[[i]][,3:ncol(hi_worker_compare[[i]])]
  
  allworker_icc_hi[[i]]=icc(dat,model = "twoway",type = "agreement")$"value"
}


cor_allHIT_allworker_lo=list()
allworker_icc_lo=list()
for(i in 1:11)
{
  dat=lo_worker_compare[[i]][,3:ncol(lo_worker_compare[[i]])]
  allworker_icc_lo[[i]]=icc(dat,model = "twoway",type = "agreement")$"value"
}

###################################################################################################################################
##### "How much more lame" from pair-wise assessment reflective of the absolute lameness score difference between the 2 cows? #####
###################################################################################################################################

# create a scatterplot with exp_high_dif dataset
ggplot(exp_high_dif, aes(x = average_new_expert, y = John_abs_score_dif)) +
  geom_point()

################################################################################################
#################### Evaluate the cutoff for easy and hard questions ###########################
################################################################################################

# filter expert rating (more than 1 or less than -1) ; easy qs
high_exp_dif <- combined_ratings2[which((combined_ratings2$average_new_expert > 1.0) | (combined_ratings2$average_new_expert < (-1.0))),]

# filter expert rating (less= to 1 or more= to -1) ; hard qs
low_exp_dif <- combined_ratings2[which((combined_ratings2$average_new_expert <= 1.0) & (combined_ratings2$average_new_expert >= (-1.0))),]

# filter opposite signs (negative/positive) between avg expert and avg worker responses for easy questions 
opposite <- high_exp_dif[which(((high_exp_dif$average_new_expert < 0) & (high_exp_dif$All_worker_means > 0)) | ((high_exp_dif$average_new_expert > 0) & (high_exp_dif$All_worker_means < 0))),]

################################################################################################
#################### Calculate precision and recall ############################################
################################################################################################
# load the caret package
library(caret)

# "positive" for hard questions (<=1 and >=-1), "negative" for easy questions (>1 or <-1)
worker_means <- ifelse(((combined_ratings2$All_worker_means <= 1.0) & (combined_ratings2$All_worker_means >= (-1.0))), "positive", "negative")
expert_means <- ifelse(((combined_ratings2$average_new_expert <= 1.0) & (combined_ratings2$average_new_expert >= (-1.0))), "positive", "negative")

# create a table that shows whether it is "positive" or "negative" for All_worker_means and average_new_expert
prec_recall <- data.frame(All_worker_means = combined_ratings2$All_worker_means, worker_means, average_new_expert = combined_ratings2$average_new_expert, expert_means)

# create confusion matrix
predicted <- prec_recall$worker_means
actual <- prec_recall$expert_means
cm <- confusionMatrix(as.factor(predicted), as.factor(actual))

# calculate precision and recall
Sensitivity <- cm$byClass[["Sensitivity"]]
Specificity <- cm$byClass[["Specificity"]]

# print results
cat("Sensitivity =", Sensitivity, "\n")
cat("Specificity =", Specificity, "\n")

################################################################################################
#################### Evaluate the new cutoff for easy and hard questions (directional) #########
################################################################################################
# create a new dataframe to prepare all the independent variables (features; x axis variables)
# and labels (y axis dependent variables) that would be used for the machine learning algorithm
ml_df <- combined_ratings2

# create a vector of the column names you want to check
cols_to_check <- c("Dan", "Hanna", "Ruan", "Nina", "Wali_round2")

# create a new dataframe with the rows meeting the cretia of >= 3 out of 5 experts
# agree that one cow is more lame than the other, and that click worker and experts
# agree on average who is more lame
pos_easy <- ml_df[which((rowSums(ml_df[cols_to_check] > 0) >= 3) & (ml_df$All_worker_means*ml_df$average_new_expert >0)), ]
neg_easy <- ml_df[which((rowSums(ml_df[cols_to_check] < 0) >= 3) & (ml_df$All_worker_means*ml_df$average_new_expert >0)), ]
ml_df$question_type <- "hard" 

# find the matching rows between the two dataframes
matching_rows <- ml_df$Question %in% pos_easy$Question
# change the target column to "easy" for the matching rows
ml_df[matching_rows, "question_type"] <- "easy"

# find the matching rows between the two dataframes
matching_rows <- ml_df$Question %in% neg_easy$Question
# change the target column to "easy" for the matching rows
ml_df[matching_rows, "question_type"] <- "easy"

# delete ceratin columns
ml_df2 <- ml_df
ml_df2$Expert_rating <- NULL
ml_df2$Dan <- NULL
ml_df2$Hanna <- NULL
ml_df2$Ruan <- NULL
ml_df2$Nina <- NULL
ml_df2$Wali_round2 <-NULL


# only keep the Question id, the question type, and the average_new_expert
ml_df3 <- ml_df2[, c("Question", "question_type", "average_new_expert")]
colnames(ml_df3) <- c("question_id", "question_type", "average_new_expert")

################################################################################################
#################### extract the time of completion for each HIT ###############################
################################################################################################
# get a dataframe that contains the Task number and the completion time for all the workers
hit_id_task_number <- answer_key2[, c("Task_number", "HIT_id")]
hit_id_time <- worker_response3[, c("HIT_id", "worker_response_time", "Worker_id")]
hit_id_time$worker_response_time <- as.integer(hit_id_time$worker_response_time)
complete_time <- merge(hit_id_time, hit_id_task_number, all = TRUE)

comlete_time_sub_sampling <- function(complete_time, task_number, random_column_names) {
  temp <- complete_time[which((complete_time$Task_number == task_number) & (complete_time$Worker_id %in% random_column_names)),]
  complete_time2 <- temp[, c("worker_response_time","Task_number")]
  
  #calculate the median, and SD of the compeletion time for each Task
  complete_time_median <- aggregate(complete_time2$worker_response_time, by =  list(complete_time2$Task_number), FUN = median)
  colnames(complete_time_median) <- c("Task_number", "complete_time_median")
  complete_time_sd <- aggregate(complete_time2$worker_response_time, by =  list(complete_time2$Task_number), FUN = sd)
  colnames(complete_time_sd) <- c("Task_number", "complete_time_sd")
  complete_time_sum <- merge(complete_time_median, complete_time_sd)
  
  # attach the complete time to each of the questions
  complete_time_sum2 <-merge(complete_time_sum, target)
  complete_time_sum2$Task_number <- NULL
  complete_time_sum2$Question <- NULL
  
  # round SD to 2
  complete_time_sum2$complete_time_sd <- round(complete_time_sum2$complete_time_sd, digits = 2)
  
  return(complete_time_sum2)
}



################################################################################################
## extract the mean, median, sd, min, max, mode of directionality of each question's response###
################################################################################################
# Custom function to calculate mode
mode_func <- function(x) {
  unique_x <- unique(x)
  count_x <- tabulate(match(x, unique_x))
  unique_x[which.max(count_x)]
}

# this function will calculate the percentage of workers selected cow on the left (< 0)
# and the percentage of workers selected cow on the right (> 0), then take the max of
# this percentage of directionality selection
directionality_pct <- function(x) {
  pos_count <- sum(x > 0)
  neg_count <- sum(x < 0)
  max_count <- max(pos_count, neg_count)
  round((max_count / length(x)) * 100, 2)
}


# balance imbalanced dataset by randomly selecting the same number of easy questions 
# as the number of hard questions. Make sure that each unique question_id in the 
# easy question list get selected at least once
balance_data <- function(worker_result) {
  all_worker_result3_easy <- worker_result[which(worker_result$question_type == "easy"),]
  all_worker_result3_hard <- worker_result[which(worker_result$question_type == "hard"),]
  hard_n <- nrow(all_worker_result3_hard)
  
  # Get the unique question_id values
  unique_question_id <- unique(all_worker_result3_easy$question_id)
  
  # Sample one example for each unique question_id
  sampled_unique_easy <- lapply(unique_question_id, function(id) {
    sample_rows <- all_worker_result3_easy[all_worker_result3_easy$question_id == id,]
    sample_rows[sample(nrow(sample_rows), 1),]
  })
  sampled_unique_easy <- do.call(rbind, sampled_unique_easy)
  sampled_unique_easy2 <- sample_n(sampled_unique_easy, min(c(hard_n, nrow(sampled_unique_easy))))
  sampled_unique_easy2$sampled <- "Y"
  mark_down_sampled <- merge(all_worker_result3_easy, sampled_unique_easy2, all = TRUE)
  sampled_unique_easy2$sampled <- NULL
  
  remaining_easy <- mark_down_sampled[is.na(mark_down_sampled$sampled),]
  remaining_easy$sampled <- NULL
  
  # Calculate the number of additional rows needed to reach hard_n
  extra_rows_needed <- hard_n - nrow(sampled_unique_easy2)
  # Sample the extra rows needed from the remaining_easy data frame
  extra_rows <- remaining_easy[sample(nrow(remaining_easy), extra_rows_needed, replace = FALSE),]
  # Combine the sampled_unique_easy2 rows with the extra sampled rows
  sampled_easy <- rbind(sampled_unique_easy2, extra_rows)
  
  # combine randomly selected easy questions with all hard questions
  result_final <- rbind(sampled_easy, all_worker_result3_hard)
  result_final <- random_shuffle(result_final)
}


random_shuffle <- function(df) {
  # Let's assume 'df' is your data frame
  n_rows <- nrow(df)  # Get the number of rows in the data frame
  
  # Shuffle the row indices
  shuffled_indices <- sample(n_rows)
  
  # Reorder the rows in the data frame using the shuffled indices
  shuffled_df <- df[shuffled_indices, ]
  
  return(shuffled_df)
}


analyze_df <- function(df_list, random_sample_size,  pre_fix, output_dir) {
  # Initialize the resulting data frame with column names
  result <- data.frame(question_id = character(),
                       Mean = numeric(),
                       Median = numeric(),
                       Mode = numeric(),
                       SD = numeric(),
                       direction_pct = numeric(),
                       stringsAsFactors = FALSE)
  
  for (i in 1:11) {
    dat <- df_list[[i]]
    question_id <- paste(dat[, 1], dat[, 2], sep = "-")
    task_number <- df_list[[i]]$Task_number[1]
    
    # Select the desired columns
    all_columns <- dat[, 3:ncol(dat)]
    num_columns <- ncol(all_columns)
    
    # Initialize unselected columns
    unselected_columns <- colnames(all_columns)
    
    while (length(unselected_columns) >= random_sample_size) {
      # Randomly select columns
      selected_columns_idx <- sample(length(unselected_columns), size = random_sample_size, replace = FALSE)
      selected_columns <- all_columns[, unselected_columns[selected_columns_idx]]
      random_column_names <- colnames(selected_columns)
      
      # Remove selected columns from the unselected columns
      unselected_columns <- unselected_columns[-selected_columns_idx]
      
      # Calculate statistics for each row
      Mean <- round(apply(selected_columns, 1, mean), 2)
      Median <- round(apply(selected_columns, 1, median), 2)
      Mode <- apply(selected_columns, 1, mode_func)
      SD <- round(apply(selected_columns, 1, sd), 2)
      
      # Calculate the percentage of columns with values >0 or <0 for each row
      direction_pct <- apply(selected_columns, 1, directionality_pct)
      
      # Combine the results into a data frame
      temp_result <- data.frame(question_id = question_id,
                                Mean = Mean,
                                Median = Median,
                                Mode = Mode,
                                SD = SD,
                                direction_pct = direction_pct)
      
      # calculate the median, sd of task completion time for workers in selected columns
      complete_time_sum2 <- comlete_time_sub_sampling(complete_time, task_number, random_column_names)
      temp_result2 <- merge(temp_result, complete_time_sum2)
      
      # Append the temp_result to the final result data frame
      result <- rbind(result, temp_result2)
    }
  }
  
  test_question_list <- ml_df3$question_id
  result2 <- result[which(result$question_id %in% test_question_list),]
  result3 <- merge(result2, ml_df3, all = TRUE)
  result3 <- na.omit(result3) # remove all NA
  result_final <- balance_data(result3)

  # save results as csv files
  write.csv(paste0(output_dir, result_final), file = paste(pre_fix, "_sub", random_sample_size, ".csv", sep = ""), row.names = FALSE)
  
  # plot the distribution of each feature
  plot_distributions(result_final, output_dir, pre_fix, random_sample_size)
  # plot the scatter plot mean X directionality_pct; median X directionality_pct
  plot_scatter(df, output_dir, pre_fix, random_sample_size)
  
  return(result_final)
}

# plot the distribution of each feature for each dataframe
plot_distributions <- function(df, output_dir, pre_fix, random_sample_size) {
  # Create the output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir)
  }
  plots_list <- list() # Create an empty list to store the individual plots
  
  to_select <- c("Mean","Median","Mode","SD","direction_pct","complete_time_median","complete_time_sd")
  b <- 1
   # Iterate through each column except the last one
  for (col_index in (2:length(to_select))) {
    # Create the distribution plot
    column_name <- colnames(df)[col_index]
    p <- ggplot(df, aes_string(x = column_name, fill = "question_type")) +
      geom_density(alpha = 0.5) +
      theme_minimal() +
      theme(legend.title = element_blank(),
            axis.title.x = element_text(size = 14),
            axis.title.y = element_text(size = 14),
            legend.text = element_text(size = 12))
    plots_list[[b]] <- p # Add the plot to the list
    b <- b + 1
    
  }
  
  # Create a textGrob for the big title
  grid_title <- paste0(pre_fix, " ", random_sample_size, " randomly sampled workers")
  big_title <- textGrob(grid_title, gp = gpar(fontsize = 20, fontface = "bold"))
  # Arrange the plots in a 2x3 grid
  p_final <- grid.arrange(grobs = plots_list, ncol = 3, nrow = 2, top = big_title)
  # Save the plot to a file
  ggsave(filename = paste0(output_dir, "/", pre_fix, "_sub", random_sample_size, ".png"), plot = p_final)
  
}

# plot the 2d scatter of 2 features for each dataframe
plot_scatter <- function(df, output_dir, pre_fix, random_sample_size) {
  # Create the output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir)
  }
  
  # Scatter plot
  p <- ggplot(df, aes(x = Median, y = direction_pct, color = question_type)) +
    geom_point(position = "jitter") + 
    theme_minimal() +
    theme(legend.title = element_blank()) +
    theme(legend.title = element_blank(),
          axis.title.x = element_text(size = 14), # Increase x-axis title font size
          axis.title.y = element_text(size = 14), # Increase y-axis title font size
          legend.text = element_text(size = 12)) +
    ggtitle(paste0(pre_fix, "_sub", random_sample_size))+ 
    theme(plot.title = element_text(size = 20, hjust = 0.5)) # Center and increase the title size
  
  # Save the plot to a file
  ggsave(filename = paste0(output_dir, "/", pre_fix, "_sub", random_sample_size, "median_direct_pct.png"), plot = p)

  
  # Scatter plot
  p <- ggplot(df, aes(x = Mean, y = direction_pct, color = question_type)) +
    geom_point(position = "jitter") + 
    theme_minimal() +
    theme(legend.title = element_blank()) +
    theme(legend.title = element_blank(),
          axis.title.x = element_text(size = 14), # Increase x-axis title font size
          axis.title.y = element_text(size = 14), # Increase y-axis title font size
          legend.text = element_text(size = 12)) +
    ggtitle(paste0(pre_fix, "_sub", random_sample_size))+ 
    theme(plot.title = element_text(size = 20, hjust = 0.5)) # Center and increase the title size
  
  # Save the plot to a file
  ggsave(filename = paste0(output_dir, "/", pre_fix, "_sub", random_sample_size, "mean_direct_pct.png"), plot = p)
  
}

##################################################################################################
####################### Randomly select 10, 15, 20 click workers after filtering  ################
##################################################################################################
random_sample_size_list <- c(10, 15, 20)

for (i in (1:length(random_sample_size_list))) {
  random_sample_size <- random_sample_size_list[i]
  ################################## all click workers were used #################################
  ######################################### worker_compare #######################################
  ### This is using all workers without attention checks
  all_worker_result_final <- analyze_df(worker_compare, random_sample_size,  "all_worker", output_dir)
  
  ################################## pass both attention checks #################################
  #################################### worker_compare_pass2 ######################################
  ### this is using workers who passed both negative and positive attention checks
  pass2_result_final <- analyze_df(worker_compare_pass2, random_sample_size, "pass2", output_dir)
  
  ################################### pass all positive control ##################################
  ################################### worker_compare_easypass ####################################
  easypass_result_final <- analyze_df(worker_compare_easypass, random_sample_size, "easypass", output_dir)
  
  ############################################# cluster ##########################################
  ##################################### worker_cl_all_compare ####################################
  # only click workers that reside in the big cluster
  cl_all_result_final <- analyze_df(worker_cl_all_compare, random_sample_size, "cl_all", output_dir)
  
  ############################## cluster + pass both attention checks#############################
  #################################### worker_cl_pass_compare ####################################
  # only workers that pass both negative and positive attention checks, and those that reside in the big cluster
  cl_pass_result_final <- analyze_df(worker_cl_pass_compare, random_sample_size, "cl_pass2", output_dir)
  
  ############################# cluster + pass all positive control ##############################
  ################################## worker_cl_easypass_compare ##################################
  #people who passed all positive control questions (definition: chose the more lame cow, regardless
  # of the degree of differences between the 2 cows) and reside in the major cluster
  cl_easypass_result_final <- analyze_df(worker_cl_easypass_compare, random_sample_size, "cl_easypass", output_dir)

}

###############################################################################################################
############################### Retention Rate for Each Task  #################################################
###############################################################################################################
#make a list of the number of columns in every data frame for each filtering method
ncol_worker_compare <- list()
ncol_easypass <- list()
ncol_pass2 <- list()
ncol_cl_easypass <- list()
ncol_cl_pass2 <- list()
ncol_cl <- list()

for (i in seq_along(worker_compare)) {
  num_cols <- ncol(worker_compare[[i]])
  ncol_worker_compare[[i]] <- num_cols - 2
}

for (i in seq_along(worker_compare_easypass)) {
  num_cols <- ncol(worker_compare_easypass[[i]])
  ncol_easypass[[i]] <- num_cols - 2
}

for (i in seq_along(worker_compare_pass2)) {
  num_cols <- ncol(worker_compare_pass2[[i]])
  ncol_pass2[[i]] <- num_cols - 2
}

for (i in seq_along(worker_cl_easypass_compare)) {
  num_cols <- ncol(worker_cl_easypass_compare[[i]])
  ncol_cl_easypass[[i]] <- num_cols - 2
}

for (i in seq_along(worker_cl_pass_compare)) {
  num_cols <- ncol(worker_cl_pass_compare[[i]])
  ncol_cl_pass2[[i]] <- num_cols - 2
}

for (i in seq_along(worker_cl_all_compare)) {
  num_cols <- ncol(worker_cl_all_compare[[i]])
  ncol_cl[[i]] <- num_cols - 2
}

#retention rate after easypass method (pass all positive control)
ret_easypass <- as.numeric()
for (i in 1:length(ncol_easypass)) {
  ret_easypass[[i]] <- (ncol_easypass[[i]] / ncol_worker_compare[[i]]) * 100
}
#retention rate after pass2 method (pass both attention checks)
ret_pass2 <- as.numeric()
for (i in 1:length(ncol_pass2)) {
  ret_pass2[[i]] <- (ncol_pass2[[i]] / ncol_worker_compare[[i]]) * 100
}
#retention rate after cl_easypass method (cluster + pass all positive control) 
ret_cl_easypass <- as.numeric()
for (i in 1:length(ncol_cl_easypass)) {
  ret_cl_easypass[[i]] <- (ncol_cl_easypass[[i]] / ncol_worker_compare[[i]]) * 100
}
#retention rate after cl_pass2 method (cluster + pass both attention checks) 
ret_cl_pass2 <- as.numeric()
for (i in 1:length(ncol_cl_pass2)) {
  ret_cl_pass2[[i]] <- (ncol_cl_pass2[[i]] / ncol_worker_compare[[i]]) * 100
}
#retention rate after cl method (cluster)
ret_cl <- as.numeric()
for (i in 1:length(ncol_cl)) {
  ret_cl[[i]] <- (ncol_cl[[i]] / ncol_worker_compare[[i]]) * 100
}

#combine the retention rates of each method into a single data frame
ret_eachtask <- data.frame(cbind(Task = c(0:10), Easypass = ret_easypass, Pass2 = ret_pass2, Cl_Easypass = ret_cl_easypass, Cl_Pass2 = ret_cl_pass2, Cl = ret_cl))

###############################################################################################################
############################### Retention Rate across All Tasks  ##############################################
###############################################################################################################
ret_maxs <- apply(ret_eachtask[, -1], 2, max)
ret_mins <- apply(ret_eachtask[, -1], 2, min)
ret_avgs <- apply(ret_eachtask[, -1], 2, mean)

#data frame of min/max/avg retention rates across all tasks using each method 
ret_alltasks <- data.frame(rbind(Max = ret_maxs, Min = ret_mins, Average = ret_avgs))

###############################################################################################################
############################### New Section ###################################################################
###############################################################################################################

