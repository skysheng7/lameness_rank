# -*- coding: utf-8 -*-

import os
import pandas as pd
from datetime import datetime
import itertools
import numpy as np

input_dir = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/code/generate 54HIT html click worker/input file'
output_dir = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/html_click_workers'
old_html_dir = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/html_experts'
test_q_dir = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/Amazon MTurk expert response'

# obtain unique_pair_id from each video pair
os.chdir(old_html_dir)
pair_id_record = pd.read_csv('all_HIT_answer.csv')
pair_id_record2 = pair_id_record[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL', 'pair_id']]
pair_id_record3 = pair_id_record2.drop_duplicates(inplace=False)
pair_id_record3 = pair_id_record3.reset_index(drop = True)
neg_temp = pair_id_record3[pair_id_record3['pair_id'] == -1]
pair_id_record4 = pair_id_record3[pair_id_record3['pair_id'] >=0]

# obtain the test HIT questions 
os.chdir(test_q_dir)
test_HIT_q = pd.read_csv('test_HIT_q.csv')
test_HIT_q = test_HIT_q.rename(columns={"response_mean": "expert_answer"})

################################################################
### Identify positive and negative attention check questions ###
################################################################
# generate a list of positive attention questions
all_easy_q = test_HIT_q[test_HIT_q['response_mean_abs'] == 2]
np.random.seed(2)
# sample 3 rows
pos_attention = all_easy_q.sample(n=3)
pos_attention = pos_attention[['cow_L', 'cow_R', 'expert_answer']]
pos_attention[['question_type']] = "pos_attention_easy"
pos_attention2 = pos_attention.merge(pair_id_record4, how = 'inner')
pos_attention2 = pos_attention2[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL', 'pair_id', 'question_type', 'expert_answer']]

# generate a list of negative attention questions
temp = pair_id_record3[['cow_L', 'cow_L_URL']]
neg_attention = temp.drop_duplicates(inplace=False)
neg_attention = neg_attention[neg_attention['cow_L'] != 8083].reset_index(drop = True)
neg_attention[['cow_R']] = neg_attention[['cow_L']]
neg_attention[['cow_R_URL']] = neg_attention[['cow_L_URL']]
neg_attention = neg_attention[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL']]
neg_attention['pair_id'] = -neg_attention.index - 2
neg_attention = pd.concat([neg_temp, neg_attention], ignore_index=True).reset_index(drop = True)
neg_attention[['question_type']] = "neg_attention"
neg_attention[['expert_answer']] = 0

# summarize all unique pairs info
pair_id_sum = pair_id_record4.merge(pos_attention2, how = "outer")
pair_id_sum = pd.concat([pair_id_sum, neg_attention], ignore_index = True).reset_index(drop = True)

pair_id_sum.to_csv(os.path.join(output_dir, ('unique_pair_id.csv')), index=False)


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

# randomly pick certain number of negative or positive attention checks
def pick_att(attention_df, num, s):
    np.random.seed(s)
    selected_att = attention_df.sample(n=num)
    return selected_att

def hit_standardize(chunk, s, cur_hit):
    # Randomly reshuffle the rows and reset the index
    chunk = chunk.sample(frac=1, random_state=(s)).reset_index(drop=True)
    
    # Add new columns
    chunk['question_num'] = ['q' + str(o) for o in range(1, (chunk.shape[0] + 1))]
    chunk['HIT'] = cur_hit
    chunk['question_id'] = chunk['HIT'].astype(str) + "-" + chunk['question_num']
    
    # rearrange the columns
    chunk = chunk[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL', 'pair_id', 'question_type', 'expert_answer', 'question_num', 'HIT', 'question_id']]
    return chunk

# create each HIT using every 8 test questions + 2 attention checks
def create_all_HIT_answer(all_pairs, pos_attention2, neg_attention, input_dir, output_dir, test_q_num):
    # Split the DataFrame into chunks of 8 rows
    chunks = np.array_split(all_pairs, len(all_pairs) // test_q_num)
    processed_chunks = []

    for i, chunk in enumerate(chunks):
        cur_hit = i+1
        s = cur_hit*15 # set seed number

        # Select: randomly select 1 positive and 1 negative attention check questions
        selected_pos = pick_att(pos_attention2, 1, s)
        selected_neg = pick_att(neg_attention, 1, s)

        # Attach: Attach negative and postiive attention check questions
        chunk = pd.concat([chunk, selected_pos], ignore_index=True)
        chunk = pd.concat([chunk, selected_neg], ignore_index=True)

        # Shuffle and standardize
        chunk = hit_standardize(chunk, s, cur_hit)
        # Append the processed chunk to the list
        processed_chunks.append(chunk)
        
        # save csv
        chunk.to_csv(os.path.join(output_dir, ('HIT' + str(cur_hit) + '_answer.csv')), index=False)
        # generate HTML for the test HIT0
        total_ques = chunk.shape[0]
        generate_html(input_dir, output_dir, chunk, total_ques, cur_hit)
    
    # Concatenate the processed chunks into a single DataFrame
    processed_df = pd.concat(processed_chunks, ignore_index=True)
    return processed_df


################################################################
######### Create a test HIT with 12 questions ##################
################################################################
# set HIT number
cur_hit = 0
s = cur_hit*15

# organize the test HIT
test_HIT_q2 = test_HIT_q[['cow_L', 'cow_R', 'expert_answer']]
test_HIT_q3 = test_HIT_q2.merge(pos_attention, how='outer')
test_HIT_q4 = test_HIT_q3.merge(pair_id_record4, how = "inner")
test_HIT_q4 = test_HIT_q4[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL', 'pair_id', 'question_type', 'expert_answer']]

selected_neg = pick_att(neg_attention, 1, s)
test_HIT_q5 = pd.concat([test_HIT_q4, selected_neg], ignore_index = True).reset_index(drop = True)

test_HIT_answer = hit_standardize(test_HIT_q5, s)

total_ques = test_HIT_answer.shape[0]

test_HIT_answer.to_csv(os.path.join(output_dir, ('HIT' + str(cur_hit) + '_answer.csv')), index=False)
# generate HTML for the test HIT0
generate_html(input_dir, output_dir, test_HIT_answer, total_ques, cur_hit)


################################################################
#### Generate HITs using the rest of the video pairs ###########
################################################################
total_ques = 10
test_q_num = total_ques - 2

all_test_q = pair_id_sum[pd.isna(pair_id_sum['question_type'])]
all_test_q = all_test_q.sample(frac=1, random_state=170).reset_index(drop=True)

# generate HTML, and save the answers to all HITs
all_HIT_answer = create_all_HIT_answer(all_test_q, pos_attention2, neg_attention, input_dir, output_dir, test_q_num)
all_HIT_answer2 = pd.concat([test_HIT_answer, all_HIT_answer], ignore_index=True)
all_HIT_answer2.to_csv(os.path.join(output_dir, ('all_HIT_answer.csv')), index=False)


################################################################
#### Double check the random assignment of videos pairs ########
################################################################
# check if all test q was included
test_q = all_HIT_answer.copy()
test_q2 = test_q[pd.isna(test_q['question_type'])]
testq3 = test_q2.drop_duplicates()
print(testq3.shape)

# check the distribution of negative and positive  attention checks
pos_q = test_q[test_q['question_type'] == "pos_attention_easy"]
neg_q = test_q[test_q['question_type'] == "neg_attention"]
pos_q_pair_id_counts = pos_q['pair_id'].value_counts()
neg_q_pair_id_counts = neg_q['pair_id'].value_counts()

