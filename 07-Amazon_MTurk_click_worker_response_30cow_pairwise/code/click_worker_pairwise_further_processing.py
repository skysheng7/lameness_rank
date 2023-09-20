import pandas as pd
import numpy as np
import math
import os
output_dir = "../results"
exec(open("click_worker_pairwise_further_processing_helper.py").read())
exec(open("55HIT_10q_helper.py").read())

"""
###############################################################################
####### convert individual click worker pairwise response to long format ######
###############################################################################
"""
# load all reponse and answer key csv
response_dir = "../results"
answer_dir = "../../06-generate_54HIT_html_click_worker/results"
data_path_1='all_HIT_answer.csv'

####### first launch: 1 test HIT ######
# only keep the responses from worker with >= 90% overall accuracy, 22 click workers in the end retained
# only keep the 3 positive attention easy checks' responses. the rest of the test q in HIT0 was all reassessed again in furutre HITs
# this is a worker recruitment test HIT only
data_path_2='master_all_responses_click_worker_Aug-02-2023.csv'
final_df_r1, final_df_pass_pos_r1, final_df_pass_neg_r1, final_df_pass_both_r1 = convert_pairwise_to_long(answer_dir, response_dir, data_path_1, data_path_2, "HIT0_selected_worker")

####### second launch: 10 HITs #######
# ~19 click workers per HIT
data_path_2='master_all_responses_click_worker_Sep-13-2023.csv'
final_df_r2, final_df_pass_pos_r2, final_df_pass_neg_r2, final_df_pass_both_r2 = convert_pairwise_to_long(answer_dir, response_dir, data_path_1, data_path_2, "10HITs")

####### third launch: 44 HITs ######
data_path_2='master_all_responses_click_worker_44HITsSep-13-2023.csv'
final_df_r3, final_df_pass_pos_r3, final_df_pass_neg_r3, final_df_pass_both_r3 = convert_pairwise_to_long(answer_dir, response_dir, data_path_1, data_path_2, "44HITs")

# merge all 3 launches together
final_df = pd.concat([final_df_r1, final_df_r2, final_df_r3], axis = 0)
final_df_pass_pos = pd.concat([final_df_pass_pos_r1, final_df_pass_pos_r2, final_df_pass_pos_r3], axis = 0)
final_df_pass_neg = pd.concat([final_df_pass_neg_r1, final_df_pass_neg_r2, final_df_pass_neg_r3], axis = 0)
final_df_pass_both = pd.concat([final_df_pass_both_r1, final_df_pass_both_r2, final_df_pass_both_r3], axis = 0)

# export as csv
final_df.to_csv(os.path.join(output_dir, f'cowLR_response_clickWorker_55HITS.csv'), index=False)
final_df_pass_pos.to_csv(os.path.join(output_dir, f'cowLR_response_clickWorker_55HITS_pass_pos.csv'), index=False)
final_df_pass_neg.to_csv(os.path.join(output_dir, f'cowLR_response_clickWorker_55HITS_pass_neg.csv'), index=False)
final_df_pass_both.to_csv(os.path.join(output_dir, f'cowLR_response_clickWorker_55HITS_pass_both.csv'), index=False)

"""
###############################################################################
############################ Winner loser format ##############################
###############################################################################
"""
winner_loser_df = create_winner_loser_degree_df(final_df)
winner_loser_df.to_csv(os.path.join(response_dir, 'winner_loser_55HITs.csv'), index=False)

matrix = winner_loser_df.pivot(index='winner', columns='loser', values='degree').fillna(0)


"""
###############################################################################
################ Average response from different experts ######################
###############################################################################
"""
# calculate the mean response for each unique set of cow_L and cow_R
mean_responses = final_df.groupby(['cow_L', 'cow_R'])['response'].mean().reset_index()
winner_loser_avg = create_winner_loser_degree_df(mean_responses)
winner_loser_avg[["expert"]] = "avg_click_workers"
winner_loser_avg.to_csv(os.path.join(output_dir, 'winner_loser_avg_55HITs.csv'), index=False)


"""
###############################################################################
################## sample same number of worker per pair#######################
###############################################################################
"""
final_df_sampled, min_worker_per_pair = sample_data_from_unique_qname(final_df)
final_df_sampled.to_csv(os.path.join(output_dir, 'cowLR_response_clickWorker_sampled_55HITS.csv'), index=False)
winner_loser_sampled = create_winner_loser_degree_df(final_df_sampled)
winner_loser_sampled.to_csv(os.path.join(output_dir, 'winner_loser_sampled_55HITs.csv'), index=False)

"""
################################################################################
### delete all responses between the 2 cows if average click worker response####
############################ is between (-1, 1) ################################
################################################################################
"""
remain_pairs = mean_responses[abs(mean_responses['response']) >= 1][['cow_L', 'cow_R']].copy()
final_df_sampled_delete_pairs = pd.merge(final_df_sampled, remain_pairs, on=['cow_L', 'cow_R'], how = "inner")
winner_loser_sampled_delete = create_winner_loser_degree_df(final_df_sampled_delete_pairs)
winner_loser_sampled_delete.to_csv(os.path.join(output_dir, 'winner_loser_sampled_delete_pairs_55HITs.csv'), index=False)

"""
################################################################################
########## if average click worker response is between (-1, 1) create ##########
############ min_worker_num/2 A wins B, min_worker_num/2 B wins A ##############
################################################################################
"""
deleted_pairs = mean_responses[abs(mean_responses['response']) < 1][['cow_L', 'cow_R']].copy().drop_duplicates().reset_index(drop=True)
duplicated_df = pd.concat([deleted_pairs] * (min_worker_per_pair/2)).reset_index(drop=True)
duplicated_df[['response']] = 0
final_df_sampled_delete_pairs2 = final_df_sampled_delete_pairs[['cow_L', 'cow_R', 'response']]
final_df_sampled_exchange0 = pd.concat([final_df_sampled_delete_pairs2, duplicated_df], ignore_index=True).reset_index(drop = True)

winner_loser_sampled_exchannge0 = create_winner_loser_degree_df(final_df_sampled_exchange0)
winner_loser_sampled_exchannge0.to_csv(os.path.join(output_dir, 'winner_loser_sampled_exchange0_55HITs.csv'), index=False)

"""
################################################################################
########## if individual click worker response is between [-1, 1] ##############
######################### set his/her response to 0 ############################
################################################################################
"""
final_df_ind_exchange0 = final_df_sampled.copy()
final_df_ind_exchange0.loc[abs(final_df_ind_exchange0['response']) <= 1, 'response'] = 0

winner_loser_sampled_ind_exchannge0 = create_winner_loser_degree_df(final_df_ind_exchange0)
winner_loser_sampled_ind_exchannge0.to_csv(os.path.join(output_dir, 'winner_loser_sampled_ind_exchange0_55HITs.csv'), index=False)

"""
################################################################################
############################ pick 5 milestone cows #############################
## 7045 (GS 1.9), 6096 (GS 2.4), 6086(GS 2.87), 4035 (GS 3.1), 5087 (GS 3.9) ###
## use minimum number of comparisons: start comparing with the most healthy ####
## cow, stop when the current cow is more than 1 degree more healthy than the ##
################################# milestone cows ###############################
################################################################################
"""
milestone = [7045, 6096, 6086, 4035, 5087]
unique_cows = pd.concat([final_df_sampled['cow_L'], final_df_sampled['cow_R']]).drop_duplicates().tolist()
# Remove cows that are in the milestone list
filtered_cows = [cow for cow in unique_cows if cow not in milestone]
milstone_compare_min = five_milestone_min_compare(final_df_sampled, filtered_cows, milestone, "min", min_worker_per_pair)

winner_loser_milestone_min = create_winner_loser_degree_df(milstone_compare_min)
winner_loser_milestone_min.to_csv(os.path.join(output_dir, 'winner_loser_milestone_min_55HITs.csv'), index=False)

"""
################################################################################
############################ pick 5 milestone cows #############################
## 7045 (GS 1.9), 6096 (GS 2.4), 6086(GS 2.87), 4035 (GS 3.1), 5087 (GS 3.9) ###
## use maximum number of comparisons: compare with each of the 5 milestone cows#
################################################################################
"""

milstone_compare_max = five_milestone_min_compare(final_df_sampled, filtered_cows, milestone, "max", min_worker_per_pair)
 
winner_loser_milestone_max = create_winner_loser_degree_df(milstone_compare_max)
winner_loser_milestone_max.to_csv(os.path.join(output_dir, 'winner_loser_milestone_max_55HITs.csv'), index=False)