import os
import glob
import pandas as pd
from datetime import date
exec(open("05-Amazon_MTurk_expert_response_30cow_pairwise/code/relaunch_html_video_not_play_helper.py").read())

today = date.today().strftime("%b-%d-%Y")
cur_hit = 100

# load the responses from experts
response_dir = "05-Amazon_MTurk_expert_response_30cow_pairwise/results/WS"

response = pd.read_csv(os.path.join(response_dir, "master_all_responses_Jun-19-2023.csv"))
response2 = response[['HIT', 'Worker_id', 'q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8','q9', 'q10', 'q11', 'q12']]
wali_response = response2[response2["Worker_id"] == "ARUXAWT9AUG92"]
wali_response2 = wali_response[['HIT', 'q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8','q9', 'q10', 'q11', 'q12']]


wali_response3 = reshape_and_remove_nan(wali_response2)

# get a list of questions that has "video not playing" as a response
video_no_pl = wali_response3[wali_response3['response'] == 'video not playing']
video_no_pl = video_no_pl.reset_index(drop=True)
video_no_pl2 = video_no_pl[['HIT', 'question_num']]


# load the answer key recording which cow is which in the original html 
key_dir = "04-generate_54HIT_html_experts/results"
html_key = pd.read_csv(os.join.path(key_dir, "all_HIT_answer.csv"))
html_key['question_num'] = html_key['question_num'].str[1:].astype(int)

merged_df = video_no_pl2.merge(html_key, how='left', on=['HIT', 'question_num'])
merged_df2 = merged_df.copy()
merged_df2 = merged_df2.drop(["HIT", "question_num"], axis=1)



# generate html for all the video pairs who has video not playing 
input_dir = '04-generate_54HIT_html_experts/code/input file'
output_dir = '05-Amazon_MTurk_expert_response_30cow_pairwise/results/wali_resubmission_html'
total_ques = merged_df.shape[0]


chunk_q_num = 10
all_HIT_answer = create_HIT(merged_df2, input_dir, output_dir, chunk_q_num)


