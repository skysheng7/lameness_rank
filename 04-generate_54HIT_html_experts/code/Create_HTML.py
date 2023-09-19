# -*- coding: utf-8 -*-

import os
import pandas as pd
from datetime import datetime
import itertools
import numpy as np

envir = "Sky"
if (envir == "Sora"):
    folder_path = '/Users/sora/Library/CloudStorage/OneDrive-UBC/Sora Jeong/results/30cow_artificial_group_compressed'
    input_dir = '/Users/sora/Library/CloudStorage/OneDrive-UBC/Sora Jeong/code/html modify code/input file'
    output_dir = '/Users/sora/Library/CloudStorage/OneDrive-UBC/Sora Jeong/results/html_experts'
else:
    folder_path = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/30cow_artificial_group_compressed'
    input_dir = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/code/html modify code/input file'
    output_dir = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/html_experts'


# read in the file containing each cow's GS
os.chdir(folder_path)
gs_record = pd.read_csv('artificial_group_all_marked.csv')
gs_record2 = gs_record[["Cow","GS"]]

################################################################
############## Generate HTML of the test HIT ###################
################################################################
# create a function to generate HTML once having the question list

def generate_html(input_dir, output_dir, test_HIT_answer, total_ques, cur_hit):
    """
    ########################## p1 css processing ##############################
    """
    os.chdir(input_dir)
    with open(r'p1_css.txt', 'r') as file:
        p1_css = file.read()

    p1_css_mod = p1_css.replace("${total_q_num}", str(total_ques))
    p1_css_mod = p1_css_mod + "\n"

    """
    ######################### p2 html question processing #########################
    """
    video1 = test_HIT_answer['cow_L_URL'].tolist()
    video2 = test_HIT_answer['cow_R_URL'].tolist()

    with open(r'p2_html_q1.txt', 'r') as file:
        p2_html_q1 = file.read()
    with open(r'p2_html_other_q.txt', 'r') as file:
        p2_html_other = file.read()

    for n in range(total_ques):
        if n == 0:
            cur_q = p2_html_q1
        else:
            cur_q = p2_html_other

        cur_q = cur_q.replace("${cur_question}", str(n + 1))
        cur_q = cur_q.replace("${total_q_num}", str(total_ques))
        cur_q = cur_q.replace("${video1}", video1[n])
        cur_q = cur_q.replace("${video2}", video2[n]) 

        if n == 0:
            p2_html_mod = cur_q + "\n"
        else:
            p2_html_mod = p2_html_mod + cur_q + "\n"

    """
    ########################### p3 java script processing #########################
    """
    with open(r'p3_js.txt', 'r') as file:
        p3_js = file.read()

    p3_js_mod = p3_js.replace("${total_q_num}", str(total_ques))
    p3_js_mod = p3_js.replace("${total_q_num_js}", str((total_ques+2)))

    q_eqs = """const question$ = document.getElementById("question$")"""
    q_list = "question$,"

    for n in range(total_ques):
        cur_q_eqs = q_eqs
        cur_q = q_list
        cur_q_eqs = cur_q_eqs.replace("$", str(n + 1))
        cur_q = cur_q.replace("$", str(n + 1))

        if n == 0:
            all_eqs = cur_q_eqs
            all_q = cur_q
        else:
            all_eqs = all_eqs + "\n" + cur_q_eqs
            all_q = all_q + "\n" + cur_q

    p3_js_mod = p3_js_mod.replace("${q_equs}", all_eqs)
    p3_js_mod = p3_js_mod.replace("${q_list}", all_q)

    """
    ###################### merge all parts into 1 complete html ###################
    """
    merged_html = p1_css_mod + p2_html_mod + p3_js_mod

    """
    ################################ EXPORT result ################################
    """
    os.chdir(output_dir)
    output_file = 'HIT' + str(cur_hit) + '.html'
    with open(output_file, 'w') as f:
        f.write(merged_html)


# create a function to include GS and randomly shuffle
def shuffle_and_calculate_gs_diff(gs_df, cow_compare):
    # get the GS for cow on the left and right
    merged_gs = pd.merge(gs_df, cow_compare, left_on='Cow', right_on='cow_L', how='inner')
    merged_gs = pd.merge(merged_gs, gs_df, left_on='cow_R', right_on='Cow', how='inner')
    
    # rename columns
    new_names = {'GS_x': 'cow_L_GS', 'GS_y': 'cow_R_GS'}
    merged_gs = merged_gs.drop(columns=['Cow_x', 'Cow_y']).rename(columns=new_names)

    # randomly shuffle the sequence of the rows for the final product
    shuffled_gs = merged_gs.sample(frac=1, random_state=180).reset_index(drop=True)  # reproducibility
    
    # calculate the correct answer for each video pair based on GS
    # right cow - left cow, if positive, right cow more lame, if negative, left cow more lame
    shuffled_gs['GS_dif'] = shuffled_gs['cow_R_GS'] - shuffled_gs['cow_L_GS']
    
    # re order the columns
    final_gs = shuffled_gs[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL', 'cow_L_GS', 'cow_R_GS', 'GS_dif']]

    return final_gs

# create each HIT using every 8 test questions + 2 attention checks
def create_HIT(all_pairs, pos_neg_attention_checks, input_dir, output_dir, test_q_num):
    # Split the DataFrame into chunks of 8 rows
    chunks = np.array_split(all_pairs, len(all_pairs) // test_q_num)
    processed_chunks = []

    for i, chunk in enumerate(chunks):
        cur_hit = i+1
        # Attach 2 rows from pos_neg_attention_checks
        chunk = pd.concat([chunk, pos_neg_attention_checks], ignore_index=True)
        
        # Randomly reshuffle the rows and reset the index
        chunk = chunk.sample(frac=1, random_state=(170+i)).reset_index(drop=True)
        
        # Add new columns
        chunk['question_num'] = ['q' + str(o) for o in range(1, (chunk.shape[0] + 1))]
        chunk['HIT'] = cur_hit
        chunk['question_id'] = chunk['HIT'].astype(str) + "-" + chunk['question_num']
        
        # rearrange the columns
        chunk = chunk[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL', 'cow_L_GS', 'cow_R_GS', 'GS_dif', 'question_type', 'question_num', 'HIT', 'question_id', 'pair_id']]
        total_ques = chunk.shape[0]
        
        # Append the processed chunk to the list
        processed_chunks.append(chunk)
        
        # save csv
        chunk.to_csv(os.path.join(output_dir, ('HIT' + str(cur_hit) + '_answer.csv')), index=False)
        # generate HTML for the test HIT0
        generate_html(input_dir, output_dir, chunk, total_ques, cur_hit)
    
    # Concatenate the processed chunks into a single DataFrame
    processed_df = pd.concat(processed_chunks, ignore_index=True)
    return processed_df

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

# set directory
os.chdir(folder_path)

# read in the manually generated dataframe from Excel
df2 = pd.read_excel('Manual Dataframe Task (April 11).xlsx', sheet_name='Dataframe')

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
