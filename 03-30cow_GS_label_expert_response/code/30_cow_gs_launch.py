"""
###############################################################################
###############################################################################
###                                                                         ###
### Author: Kehan (Sky) Sheng                                               ###
### Email: skysheng7@gmail.com                                              ###
### Association: UBC                                                        ###
### Date: September 12 2020 -  July 18, 2021                                ###
### Location: Vancouver, BC, Canada                                         ###
###                                                                         ###
### Description:  This code changes file name for the Amazon MTurk project, ###
###               trasnfer video formats and merge multiple video clips into###
###               one. This code also allow you to connect to Amazon AWS    ###
###               directly and use its developer API. We create HITs,       ###
###               approve worker's submittion, and collect response results ###
###               using Python code directly.                               ###
###                                                                         ###
### Source: 		  (1) 2017 Amazon.com, Inc.: CreateHitSample.py         ###
###                 file:///Users/skysheng/Downloads/CreateHitSample.py.html###
###                                                                         ###
###############################################################################
###############################################################################
"""

#import the packages
import os
import glob
import pandas as pd
from xml.dom.minidom import parseString
import xml.etree.ElementTree as ET
import random
import re
import boto3
import sys
import csv
import numpy as np
import xmltodict
from datetime import date
import datetime
import json
import math
exec(open("03-30cow_GS_label_expert_response/code/30_cow_gs_launch_helper.py").read())


# get today's date
today = date.today().strftime("%b-%d-%Y")
envir = "Sky"
if (envir == "Sky"):
    input_dir = "02-generate_30cow_GS_label_html_experts/results"
    key_dir ='/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/data/Amazon MTurk'
    output_dir = "03-30cow_GS_label_expert_response/results"
    
"""
###############################################################################
################################ Create HITs ##################################
###############################################################################
"""
# By default, HITs are created in the free-to-use Sandbox
create_hits_in_live = False
#create_hits_in_live = True
track_ip = False
max_worker_num = 20
html_files = ['GS_30cows_HIT0_Jun-04-2023.html']
master_submitted_tasks_tracker = process_html_files(html_files, input_dir, create_hits_in_live, key_dir, max_worker_num)
master_submitted_tasks_tracker = master_submitted_tasks_tracker.sort_values(by='HIT').reset_index(drop=True)

master_submitted_tasks_tracker.to_csv(os.path.join(output_dir, ('all_submitted_tracker' + today + '.csv')))

# a for loop to print out the HIT address of all HITs in master_submitted_tasks_tracker, in the format of "HIT0: address"
for index, row in master_submitted_tasks_tracker.iterrows():
    cur_HIT_num = row['HIT']
    hit_address = row['HIT_website_address']
    print("HIT" + str(cur_HIT_num) + ": " + hit_address)

"""
###############################################################################
########################## Collect Worker Response ############################
###############################################################################
"""

# read in submitted tasks
master_submitted_tasks_tracker = pd.read_csv(os.path.join(output_dir, ("all_submitted_trackerAug-30-2023.csv"))) 

# Create a client
client, mturk_environment = create_mturk_client(create_hits_in_live, key_dir)

# create master dataframes to store all the responses from all HITs
master_worker_response_tracker = pd.DataFrame()

# iterate through all HITs
for index, row in master_submitted_tasks_tracker.iterrows():
    hit_id = row['HIT_id']
    cur_HIT_num = row['HIT']
    hit_address = row['HIT_website_address']
    result_address = row['HIT_results_address']
    html_name = "HIT" + str(cur_HIT_num)   
    # Set the number of questions, there are 12 question sin HIT0, but the others have 10
    if (cur_HIT_num == 0):
        num_questions = 30
    else:
        num_questions = 30
        
        
    print(html_name)
        
    # Get the status of the current HIT
    hit = client.get_hit(HITId=hit_id)
    hit_status = str(hit['HIT']['HITStatus'])
    # get a dictionary with worker's response
    response = client.list_assignments_for_hit(
            HITId=hit_id,
            AssignmentStatuses=['Submitted', 'Approved', 'Rejected'],
            #AssignmentStatuses=['Submitted'],
            MaxResults=100,
            )
    
    # Process worker responses
    q_col = all_q_columns(num_questions)
    worker_response_tracker_columns = ['HIT','HIT_id','HIT_website_address','HIT_results_address', 'HIT_status', 'submitted_assignments', 'Worker_id', 'Assignment_id', 'Accept_time', 'Submit_time', 'Full_response', 'worker_ip','isBot','assignment_status'] + q_col
    
    # create a datasheet to record workers' responses
    worker_response_tracker = pd.DataFrame(columns=worker_response_tracker_columns)
    # process responses
    worker_response_tracker = process_responses(response, worker_response_tracker, cur_HIT_num, hit_id, hit_address, result_address, hit_status, q_col, track_ip, client)
    
    # Update the master DataFrames
    master_worker_response_tracker = pd.concat([master_worker_response_tracker, worker_response_tracker], ignore_index=True)

# assign round number
master_worker_response_tracker[["GS_round"]] = 3
# Save DataFrames to CSV files
master_worker_response_tracker.to_csv(os.path.join(output_dir, ('master_worker_response_tracker_Anna-merick' + today + '.csv')), index=False)


"""
###############################################################################
########################## Monitor HIT status ############################
###############################################################################
"""


# iterate through all 53 HITs, monitor how many HITs were submitted
for index, row in master_submitted_tasks_tracker.iterrows():
    hit_id = row['HIT_id']
    cur_HIT_num = row['HIT']
    hit_address = row['HIT_website_address']
    result_address = row['HIT_results_address']
    html_name = "HIT" + str(cur_HIT_num)   
    # Set the number of questions, there are 12 question sin HIT0, but the others have 10
    if (cur_HIT_num == 0):
        num_questions = 30
    else:
        num_questions = 30
        
        
    # Get the status of the current HIT
    #hit = client.get_hit(HITId=hit_id)
    #hit_status = str(hit['HIT']['HITStatus'])
    
    # get a dictionary with worker's response
    response = client.list_assignments_for_hit(
            HITId=hit_id,
            AssignmentStatuses=['Submitted', 'Approved', 'Rejected'],
            #AssignmentStatuses=['Submitted'],
            MaxResults=100,
            )
    
    print(hit_id)
    print(html_name + ": Submitted " + str(response['NumResults']))



"""
###############################################################################
################### Collect Expert Response from csv ##########################
###############################################################################
"""
manual_rp = pd.read_csv(os.path.join(output_dir, "gs_expert_manual_response.csv"))
manual_rp = manual_rp[['Expert', 'Response', 'html', 'date', 'GS_round']]
manual_rp.dropna(inplace=True)


# create master dataframes to store all the responses from all HITs
master_worker_response_tracker = pd.DataFrame()
num_questions = 30
hit_num = 0

# iterate through all HITs
for index, row in manual_rp.iterrows():
    expert = row['Expert']
    html_name = row['html']
    full_rp = row['Response']
    gs_round = row['GS_round']
    
    # Process worker responses
    q_col = all_q_columns(num_questions)
    worker_response_tracker_columns = ['HIT', 'Worker_id', 'html', 'Full_response'] + q_col
    
    # create a datasheet to record workers' responses
    worker_response_tracker = pd.DataFrame(columns=worker_response_tracker_columns)
    # process responses
    worker_response_tracker = extract_answer_manual(hit_num, expert, html_name, full_rp, worker_response_tracker)
    worker_response_tracker[["GS_round"]] = gs_round
    
    # Update the master DataFrames
    master_worker_response_tracker = pd.concat([master_worker_response_tracker, worker_response_tracker], ignore_index=True)


# Save DataFrames to CSV files
master_worker_response_tracker.to_csv(os.path.join(output_dir, ('manual_expert_response_extract_' + today + '.csv')), index=False)

