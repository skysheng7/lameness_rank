# -*- coding: utf-8 -*-

import os
import pandas as pd
from datetime import datetime
import itertools
import numpy as np
exec(open("06-generate_54HIT_html_click_worker/code/Create_HTML_click worker_helper.py").read())

input_dir = '06-generate_54HIT_html_click_worker/code/input file'
output_dir = '06-generate_54HIT_html_click_worker/results'
old_html_dir = '04-generate_54HIT_html_experts/results'
test_q_dir = '05-Amazon_MTurk_expert_response_30cow_pairwise/results/all_experts'

# obtain unique_pair_id from each video pair
pair_id_record = pd.read_csv(os.path.join(old_html_dir, 'all_HIT_answer.csv'))
pair_id_record2 = pair_id_record[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL', 'pair_id']]
pair_id_record3 = pair_id_record2.drop_duplicates(inplace=False)
pair_id_record3 = pair_id_record3.reset_index(drop = True)
neg_temp = pair_id_record3[pair_id_record3['pair_id'] == -1]
pair_id_record4 = pair_id_record3[pair_id_record3['pair_id'] >=0]

# obtain the test HIT questions 
test_HIT_q = pd.read_csv(os.path.join(test_q_dir, 'test_HIT_q.csv'))
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

