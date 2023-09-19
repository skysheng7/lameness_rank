# -*- coding: utf-8 -*-

import os
import pandas as pd
from datetime import datetime
import itertools
import numpy as np
exec(open("Create_54HITs_experts_HTML_helper.py").read())

folder_path = "../../01-video_select_compress/data"
input_dir = './input file'
output_dir = '../results'


# read in the file containing each cow's GS
gs_record = pd.read_csv(os.path.join(folder_path, 'artificial_group_all_marked.csv'))
gs_record2 = gs_record[["Cow","GS"]]


################################################################
############ TASK 1: create URL for each video files ###########
################################################################

# empty list to store the data
data = []

# loop through each file in the folder to store the data into the empty list
for file_name in os.listdir(folder_path):
    # get the file name for .MP4 files => column 1
    if file_name.endswith('.MP4'): 
        # extract the date (DDMMYY -> MM/DD/YY) => column 2
        file_parts = file_name.split("_")
        date_str = file_parts[1]
        date_obj = datetime.strptime(date_str, '%d%m%y')    # date string (DDMMYY)
        date = date_obj.strftime('%-m/%-d/%y')              # format date (MM/DD/YY)
        # extract the cow ID => column 3
        cow_id = file_parts[-1].split('.')[0]
        # create the URL
        url = 'https://skyshengtest1.s3.us-west-2.amazonaws.com/ubc_phase2/' + file_name
        # add the data to the list => column 4
        data.append([file_name, date, cow_id, url])

# create the data frame from the list
df = pd.DataFrame(data, columns=['file_name', 'date', 'cow_id', 'URL'])
# randomly reshuffle
df = df.sample(frac=1, random_state=170).reset_index(drop=True)

################################################################
##TASK 2: generate video pairs comparing everyone with everyone#
################################################################

# create a list of all possible pairs of cows
pairs = list(itertools.combinations(df.index, 2))

# create a dataframe with the pairs of cows and their URLs and cow IDs
df_pairs = pd.DataFrame(pairs, columns=['left', 'right'])
df_pairs['left_URL'] = df.loc[df_pairs['left'], 'URL'].values
df_pairs['left_cow_id'] = df.loc[df_pairs['left'], 'cow_id'].values
df_pairs['right_URL'] = df.loc[df_pairs['right'], 'URL'].values
df_pairs['right_cow_id'] = df.loc[df_pairs['right'], 'cow_id'].values

# re-order columns
df_pairs = df_pairs[['left_cow_id', 'left_URL', 'right_cow_id', 'right_URL']]

################################################################
######### Create a test HIT with 12 questions ##################
################################################################
# set HIT number
cur_hit = 0
total_ques = 12

# read in the manually generated dataframe from Excel
df2 = pd.read_excel(os.path.join(folder_path, 'Manual Dataframe Task (April 11).xlsx'), sheet_name='Dataframe')

# change dataframe values from integer to string
df2 = df2.astype(str)

# merge the two dataframes based on the common cow_id 
merged_df2 = pd.merge(df[['cow_id', 'URL']], df2, left_on='cow_id', right_on='cow_L', how='inner')
merged_df2 = pd.merge(merged_df2, df[['cow_id', 'URL']], left_on='cow_R', right_on='cow_id', how='inner')
# drop duplicate id columns, and rename the merged URL columns
merged_df2 = merged_df2.drop(columns=['cow_id_x', 'cow_id_y']).rename(columns={'URL_x': 'cow_L_URL', 'URL_y': 'cow_R_URL'})

# reorder columns 
merged_df2 = merged_df2[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL']]
merged_df2['cow_L'] = merged_df2['cow_L'].astype(int)
merged_df2['cow_R'] = merged_df2['cow_R'].astype(int)

test_HIT_answer = shuffle_and_calculate_gs_diff(gs_record2, merged_df2)

# add a new column to mark down question_type
test_HIT_answer['question_type'] = np.where(abs(test_HIT_answer['GS_dif']) >= 2, 'pos_attention', 
                                       (np.where(test_HIT_answer['GS_dif'] == 0, 'neg_attention', '')))
# label as pos_attention_easy if cow_L is 5087 and cow_R is 6068
mask = (test_HIT_answer['cow_L'] == 5087) & (test_HIT_answer['cow_R'] == 6068)
test_HIT_answer.loc[mask, 'question_type'] = 'pos_attention_easy'

# add a new column question_num to test_HIT_answer
test_HIT_answer['question_num'] = ['q'+str(i) for i in range(1,(test_HIT_answer.shape[0]+1))]
test_HIT_answer['HIT'] = cur_hit
test_HIT_answer['question_id'] = test_HIT_answer['HIT'].astype(str) + "-" + test_HIT_answer['question_num']
# Add a new column 'pair_id' and assign unique values
pair_id = 1
for index, row in test_HIT_answer.iterrows():
    if row['question_type'] == 'neg_attention':
        test_HIT_answer.at[index, 'pair_id'] = -1
    else:
        test_HIT_answer.at[index, 'pair_id'] = pair_id
        pair_id += 1

test_HIT_answer.to_csv(os.path.join(output_dir, ('HIT' + str(cur_hit) + '_answer.csv')), index=False)
# generate HTML for the test HIT0
generate_html(input_dir, output_dir, test_HIT_answer, total_ques, cur_hit)


################################################################
#### Generate HITs using the rest of the video pairs ###########
################################################################
total_ques = 10
test_q_num = total_ques - 2

# extract the positive and negative attention checks
mask = ((test_HIT_answer['question_type'] == 'pos_attention_easy') | (test_HIT_answer['question_type'] == 'neg_attention'))
pos_neg_attention_checks = test_HIT_answer.loc[mask, :]
columns_to_drop = ['question_num', 'HIT', 'question_id']
pos_neg_attention_checks = pos_neg_attention_checks.drop(columns=columns_to_drop)

# delete the video pairs already used in test HIT (HIT0 ) from all the possible video pair comparisons
# Find the rows to drop
df_pairs['left_cow_id'] = df_pairs['left_cow_id'].astype(int)
df_pairs['right_cow_id'] = df_pairs['right_cow_id'].astype(int)
rows_to_drop = []
for index, row in test_HIT_answer.iterrows():
    cow_L = row['cow_L']
    cow_R = row['cow_R']
    match1 = (df_pairs['left_cow_id'] == cow_L) & (df_pairs['right_cow_id'] == cow_R)
    match2 = (df_pairs['left_cow_id'] == cow_R) & (df_pairs['right_cow_id'] == cow_L)
    rows_to_drop.extend(df_pairs[match1 | match2].index.tolist())

# Drop the rows from df_pairs
df_pairs2 = df_pairs.drop(rows_to_drop)
df_pairs2 = df_pairs2.rename(columns={'left_cow_id': 'cow_L', 'right_cow_id': 'cow_R', 'left_URL': 'cow_L_URL', 'right_URL': 'cow_R_URL'})

# shuffle and attach GS
df_pairs3 = shuffle_and_calculate_gs_diff(gs_record2, df_pairs2)
df_pairs3['question_type'] = ""

# Add a new column 'pair_id' and assign unique values
pair_id = 12
for index, row in df_pairs3.iterrows():
    df_pairs3.at[index, 'pair_id'] = pair_id
    pair_id += 1
  

# generate HTML, and save the answers to all HITs
all_HIT_answer = create_HIT(df_pairs3, pos_neg_attention_checks, input_dir, output_dir, test_q_num)
all_HIT_answer2 = pd.concat([test_HIT_answer, all_HIT_answer], ignore_index=True)
all_HIT_answer2.to_csv(os.path.join(output_dir, ('all_HIT_answer.csv')), index=False)
