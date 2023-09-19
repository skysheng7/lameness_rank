import os
import pandas as pd
from datetime import date
exec(open("process_gs_response_helper.py").read())

today = date.today().strftime("%b-%d-%Y")

response_dir = "../results"
response_file = "master_worker_response_tracker_Anna-merickSep-10-2023.csv"
html_dir = "../../02-generate_30cow_GS_label_html_experts/results"
html_cow_record = "GS_30cows_HIT0_Jun-04-2023.csv"

output_dir = "../results"

# read in the response file
response_df = pd.read_csv(os.path.join(response_dir, response_file)) 
response_df = response_df.replace("ARUXAWT9AUG92", "AS") # WS & AS used the amazon account with ID: "ARUXAWT9AUG92"
response_df = response_df[response_df['Worker_id'] == "AS"].copy()
html_df = pd.read_csv(os.path.join(html_dir, html_cow_record))
cow_record = html_df[['cow_id', 'date', 'question_num']]
cow_record = cow_record.rename(columns={'cow_id': 'Cow'})

num_questions = 30

response_melted = reshape_and_remove_nan(response_df, num_questions)
cow_record.loc[:, 'question_num'] = cow_record['question_num'].str[1:].astype(int)
merged_df = cow_record.merge(response_melted, on=['question_num'], how='inner')


merged_df.to_csv(os.path.join(output_dir, ('gs_response_' + str(today) +'.csv')), index=False)