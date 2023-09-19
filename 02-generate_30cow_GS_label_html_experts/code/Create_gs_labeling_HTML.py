# -*- coding: utf-8 -*-

import os
import pandas as pd
from datetime import datetime
import itertools
import numpy as np
from datetime import date

today = date.today().strftime("%b-%d-%Y")
envir = "Sky"
if (envir == "Sora"):
    folder_path = '/Users/sora/Library/CloudStorage/OneDrive-UBC/Sora Jeong/results/30cow_artificial_group_compressed'
    input_dir = '/Users/sora/Library/CloudStorage/OneDrive-UBC/Sora Jeong/code/html modify code/input file'
    output_dir = '/Users/sora/Library/CloudStorage/OneDrive-UBC/Sora Jeong/results/html'
else:
    folder_path = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/30cow_artificial_group_compressed'
    input_dir = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/code/gs_labeling_html/input file'
    output_dir = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/results/gs_labeling_html'

################################################################
############## Generate HTML of the test HIT ###################
################################################################
# create a function to generate HTML once having the question list

def generate_html(input_dir, output_dir, df, total_ques, cur_hit, today):
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
    video1 = df['URL'].tolist()

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
    output_file = 'GS_30cows_HIT' + str(cur_hit) + '_' + today + '.html'
    with open(output_file, 'w') as f:
        f.write(merged_html)


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
######### Create a test HIT with 12 questions ##################
################################################################
# set HIT number
cur_hit = 0
total_ques = 30

generate_html(input_dir, output_dir, df, total_ques, cur_hit, today)
df.to_csv(os.path.join(output_dir, ('GS_30cows_HIT' + str(cur_hit) + '_' + today + '.csv')), index=False)
