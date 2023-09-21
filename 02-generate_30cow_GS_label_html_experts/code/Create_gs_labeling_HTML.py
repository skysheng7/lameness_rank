# -*- coding: utf-8 -*-

import os
import pandas as pd
from datetime import datetime
import itertools
import numpy as np
from datetime import date
exec(open("Create_gs_labeling_HTML_helper.py").read())

today = date.today().strftime("%b-%d-%Y")


folder_path = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/30cow_artificial_group_compressed'
input_dir = '02-generate_30cow_GS_label_html_experts/code/input file'
output_dir = '02-generate_30cow_GS_label_html_experts/results'

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
# used state = 170
df = df.sample(frac=1, random_state=180).reset_index(drop=True)
# add a new column question_num to df
df['question_num'] = ['q'+str(i) for i in range(1,(df.shape[0]+1))]

################################################################
######### Create a test HIT with 30 GS questions ###############
################################################################
# set HIT number
cur_hit = 0
total_ques = 30

generate_html(input_dir, output_dir, df, total_ques, cur_hit, today)
df.to_csv(os.path.join(output_dir, ('GS_30cows_HIT' + str(cur_hit) + '_' + today + '.csv')), index=False)
