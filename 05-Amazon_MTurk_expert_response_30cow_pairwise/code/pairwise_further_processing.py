import pandas as pd
import numpy as np
import math
import os


"""
###############################################################################
###### convert individual expert pairwise response to winner loser df #########
###############################################################################
"""
# load all reponse and answer key csv
expert_response_dir = "/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/Amazon MTurk expert response/pairwise_Dan_Wali_Nina_all"
answer_dir1 = "/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/html"
answer_dir2 = "/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/Amazon MTurk expert response/wali_resubmission_html"
data_path_1='all_HIT_answer.csv'
data_path_2='master_all_responses_May-14-2023_to_May-18-2023_Dan.csv'


def merge_csv_files(df, directory, column_order):
    # Get a list of all csv files in the directory
    csv_files = [f for f in os.listdir(directory) if f.endswith('.csv')]

    # Iterate over each file
    for file in csv_files:
        # Create a temporary dataframe to hold the current csv file's data
        temp_df = pd.read_csv(os.path.join(directory, file))

        # Reorder the columns of temporary dataframe to the desired order
        temp_df = temp_df[column_order]

        # Append the data from the temporary dataframe to df
        df = pd.concat([df, temp_df], ignore_index=True)

    return df.reset_index(drop=True)

os.chdir(answer_dir1)
df_1= pd.read_csv(data_path_1)
column_ord = ['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL', 'cow_L_GS', 'cow_R_GS', 'GS_dif', 'question_type', 'question_num', 'HIT', 'question_id', 'pair_id']
#df_1 = merge_csv_files(df_1, answer_dir2, column_ord)


os.chdir(expert_response_dir)
df_2= pd.read_csv(data_path_2)


def process_data(df_1, df_2):
    # Remove all positive and negative attention checks, keep only 1 copy of the positive attention check
    all_test_q = df_1[(df_1['question_type'] != "neg_attention") & (df_1['question_type'] != "pos_attention_easy")].copy()
    pos_attention_q = df_1[df_1['question_type'] == "pos_attention_easy"].head(1).copy()

    # Concatenate the dataframes and reset the index
    all_q = pd.concat([all_test_q, pos_attention_q], ignore_index=True)
    all_q.reset_index(drop=True, inplace=True)

    # Select the desired columns and convert question_num to int
    all_q2 = all_q[['cow_L', 'cow_R', 'question_num', 'HIT']].copy()
    all_q2.loc[:, 'question_num'] = all_q2['question_num'].str[1:].astype(int)

    # Select the columns for response dataframe
    all_q_col = [f"q{i}" for i in range(1, 13)]
    all_col = all_q_col.copy()
    all_col.append('HIT')

    # Get the response dataframe
    response = df_2[all_col].copy()

    return all_q2, response


def reshape_and_remove_nan(df):
    df_melted = df.melt(id_vars='HIT', 
                        value_vars=['q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8', 'q9', 'q10', 'q11', 'q12'], 
                        var_name='question_num', 
                        value_name='response')
    df_melted['question_num'] = df_melted['question_num'].str[1:].astype(int)
    df_melted = df_melted.dropna()
    df_melted2 = df_melted[(df_melted['response'] != "video not playing")].copy().reset_index(drop=True)
    df_melted2['response'] = df_melted2['response'].astype(int)
    return df_melted2


def process_and_merge(df_1, df_2):
    all_q2, response = process_data(df_1, df_2)
    response_melted = reshape_and_remove_nan(response)
    merged_df = all_q2.merge(response_melted, on=['HIT', 'question_num'], how='inner').dropna()
    merged_df2 = merged_df[['cow_L', 'cow_R', 'response']]

    return merged_df2


def create_winner_loser_degree_df(final_df):
    winner = []
    loser = []
    degree = []

    for _, row in final_df.iterrows():
        if row['response'] <= 0:
            winner.append(row['cow_L'])
            loser.append(row['cow_R'])
            degree.append(abs(row['response']))
        else:
            winner.append(row['cow_R'])
            loser.append(row['cow_L'])
            degree.append(abs(row['response']))

    new_df = pd.DataFrame({
        'winner': winner,
        'loser': loser,
        'degree': degree
    })

    return new_df


final_df = process_and_merge(df_1, df_2)
final_df[["expert"]] = "DW"
winner_loser_df = create_winner_loser_degree_df(final_df)
winner_loser_df[["expert"]] = "DW"

os.chdir(expert_response_dir)
winner_loser_df.to_csv('winner_loser_Wali.csv', index=False)
final_df.to_csv('cowLR_response_Dan.csv', index=False)

matrix = winner_loser_df.pivot(index='winner', columns='loser', values='degree').fillna(0)

"""
###############################################################################
###################### merge different experts together #######################
###############################################################################
"""

os.chdir(expert_response_dir)
exp1= pd.read_csv("winner_loser_Dan.csv")
exp2 = pd.read_csv("winner_loser_Wali.csv")
exp_all = pd.concat([exp1, exp2], ignore_index=True)
exp_all.to_csv('winner_loser_merged.csv', index=False)

"""
###############################################################################
################ Average response from different experts ######################
###############################################################################
"""

os.chdir(expert_response_dir)
exp1_LR= pd.read_csv("cowLR_response_Dan.csv")
exp2_LR = pd.read_csv("cowLR_response_Wali.csv")
exp_all_LR = pd.concat([exp1_LR, exp2_LR], ignore_index=True)

# calculate the mean response for each unique set of cow_L and cow_R
mean_responses = exp_all_LR.groupby(['cow_L', 'cow_R'])['response'].mean().reset_index()
winner_loser_avg = create_winner_loser_degree_df(mean_responses)
winner_loser_avg[["expert"]] = "avg_D_W"
winner_loser_avg.to_csv('winner_loser_avg.csv', index=False)
