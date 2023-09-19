import os
import pandas as pd
from datetime import date

today = date.today().strftime("%b-%d-%Y")

response_dir = "/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/results/30_cow_gs_HIT_launch"
response_file = "master_worker_response_tracker_Anna-merickSep-10-2023.csv"
html_dir = "/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/results/gs_labeling_html"
html_cow_record = "GS_30cows_HIT0_Jun-04-2023.csv"

output_dir = "/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/results/30_cow_gs_HIT_launch"

# read in the response file
os.chdir(response_dir)
response_df = pd.read_csv(response_file)  
response_df = response_df.replace("ARUXAWT9AUG92", "Anna-Marieke") # Wali's worker id is "ARUXAWT9AUG92"
response_df = response_df[response_df['Worker_id'] == "Anna-Marieke"].copy()
os.chdir(html_dir)
html_df = pd.read_csv(html_cow_record)  
cow_record = html_df[['cow_id', 'date', 'question_num']]
cow_record = cow_record.rename(columns={'cow_id': 'Cow'})

num_questions = 30

def all_q_columns(num_questions):
    return [f"q{i}" for i in range(1, num_questions + 1)]


def reshape_and_remove_nan(df, num_questions):
    col_names = all_q_columns(num_questions)
    df_melted = df.melt(id_vars=['HIT', 'Worker_id', 'GS_round'], 
                    value_vars= col_names, 
                        var_name='question_num', 
                        value_name='GS')
    df_melted['question_num'] = df_melted['question_num'].str[1:].astype(int)
    df_melted = df_melted.dropna()
    return df_melted

response_melted = reshape_and_remove_nan(response_df, num_questions)
cow_record.loc[:, 'question_num'] = cow_record['question_num'].str[1:].astype(int)
merged_df = cow_record.merge(response_melted, on=['question_num'], how='inner')

os.chdir(output_dir)
merged_df.to_csv(('gs_response_' + str(today) +'.csv'), index=False)