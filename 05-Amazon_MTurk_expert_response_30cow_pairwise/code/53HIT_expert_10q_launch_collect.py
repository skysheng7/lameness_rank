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
exec(open("05-Amazon_MTurk_expert_response_30cow_pairwise/code/53HIT_expert_10q_launch_collect_helper.py").read())


# get today's date
today = date.today().strftime("%b-%d-%Y")

input_dir = "04-generate_54HIT_html_experts/results"
key_dir ='/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/data/Amazon MTurk'
output_dir = "05-Amazon_MTurk_expert_response_30cow_pairwise/results/NV" # this can be "../results/DW", "../results/WS", "../results/HE" depending on different worker

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
# html_files = sorted(filter(lambda f: f.endswith(".html") and f.startswith("HIT"), os.listdir(input_dir)))
html_files = ['HIT10.html', 'HIT11.html']
master_submitted_tasks_tracker = process_html_files(html_files, input_dir, create_hits_in_live, key_dir, max_worker_num)
master_submitted_tasks_tracker = master_submitted_tasks_tracker.sort_values(by='HIT').reset_index(drop=True)

master_submitted_tasks_tracker.to_csv(os.path.join(output_dir, ('all_submitted_tracker_nina_resub' + today + '.csv')))

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
master_submitted_tasks_tracker = pd.read_csv(os.path.join(output_dir, ("all_submitted_tracker_nina_resubSep-22-2023.csv")))

# Create a client
client, mturk_environment = create_mturk_client(create_hits_in_live, key_dir)

# create master dataframes to store all the responses from all HITs
master_worker_response_tracker = pd.DataFrame()
master_approved_responses = pd.DataFrame()
master_rejected_responses = pd.DataFrame()
master_all_responses = pd.DataFrame()

# iterate through all 53 HITs
for index, row in master_submitted_tasks_tracker.iterrows():
    hit_id = row['HIT_id']
    cur_HIT_num = row['HIT']
    hit_address = row['HIT_website_address']
    result_address = row['HIT_results_address']
    html_name = "HIT" + str(cur_HIT_num)   
    HIT_answer = pd.read_csv(os.path.join(input_dir, (html_name + "_answer.csv")))
    HIT_answer2 = HIT_answer[["GS_dif", "question_type", "question_num"]]
    # Set the number of questions, there are 12 question sin HIT0, but the others have 10
    if (cur_HIT_num == 0):
        num_questions = 12
    else:
        num_questions = 10
        
        
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
    # Create DataFrames to record approved and rejected responses
    approved_responses = pd.DataFrame(columns=worker_response_tracker.columns)
    rejected_responses = pd.DataFrame(columns=worker_response_tracker.columns)
    all_responses = pd.DataFrame(columns=worker_response_tracker.columns)
    
    # process responses
    worker_response_tracker, approved_responses, rejected_responses, all_responses = process_responses(response, worker_response_tracker, approved_responses, rejected_responses, cur_HIT_num, hit_id, hit_address, result_address, hit_status, HIT_answer2, all_responses, q_col, track_ip, client)
    
    # Update the master DataFrames
    master_worker_response_tracker = pd.concat([master_worker_response_tracker, worker_response_tracker], ignore_index=True)
    master_approved_responses = pd.concat([master_approved_responses, approved_responses], ignore_index=True)
    master_rejected_responses = pd.concat([master_rejected_responses, rejected_responses], ignore_index=True)
    master_all_responses = pd.concat([master_all_responses, all_responses], ignore_index=True)
    


# Save DataFrames to CSV files
master_worker_response_tracker.to_csv(os.path.join(output_dir, ('master_worker_response_tracke_resub_' + today + '.csv')), index=False)
master_approved_responses.to_csv(os.path.join(output_dir, ('master_approved_responses_resub_' + today + '.csv')), index=False)
master_rejected_responses.to_csv(os.path.join(output_dir, ('master_rejected_responses_resub_' + today + '.csv')), index=False)
master_all_responses.to_csv(os.path.join(output_dir, ('master_all_responses_resub_' + today + '.csv')), index=False)




"""
###############################################################################
########################## Monitor HIT status #################################
###############################################################################
"""
i = 1
for item in client.list_hits()['HITs']:
    
    print(i)
    i = i + 1
    hit_id_monitor=item['HITId']
    print('HITId:', hit_id_monitor)

    # Get HIT status
    status=client.get_hit(HITId=hit_id_monitor)['HIT']['HITStatus']
    print('HITStatus:', status)

    # Print HIT title
    hit_title = item['Title']
    print('HIT Title:', hit_title)
    
    #max_assignments=client.get_hit(HITId=hit_id_monitor)['HIT']['MaxAssignments']
    #print('Max assignments:', max_assignments)
    
    assignments_completed=client.get_hit(HITId=hit_id_monitor)['HIT']['NumberOfAssignmentsCompleted']
    print('Number Of Assignments Completed:', assignments_completed)
    
    assignments_pending=client.get_hit(HITId=hit_id_monitor)['HIT']['NumberOfAssignmentsPending']
    print('Number Of Assignments Pending:', assignments_pending)
    
    assignments_available=client.get_hit(HITId=hit_id_monitor)['HIT']['NumberOfAssignmentsAvailable']
    print('Number Of Assignments Available:', assignments_available)
    
    #expiration_time=client.get_hit(HITId=hit_id_monitor)['HIT']['Expiration']
    #print('Expiration:', expiration_time)
    
    HIT_review_status=client.get_hit(HITId=hit_id_monitor)['HIT']['HITReviewStatus']
    print('HIT Review Status:', HIT_review_status)

 
### number of assignments available means the number of assignments not claimed
### number of assignments pending means the number of assignments that have been accepted by workers but not submited
### number of assignments completed means the number of assignments submited   
    

# iterate through all 53 HITs, monitor how many HITs were submitted
for index, row in master_submitted_tasks_tracker.iterrows():
    hit_id = row['HIT_id']
    cur_HIT_num = row['HIT']
    hit_address = row['HIT_website_address']
    result_address = row['HIT_results_address']
    html_name = "HIT" + str(cur_HIT_num)   
    HIT_answer = pd.read_csv(os.path.join(input_dir, (html_name + "_answer.csv")))
    HIT_answer2 = HIT_answer[["GS_dif", "question_type", "question_num"]]
    # Set the number of questions, there are 12 question sin HIT0, but the others have 10
    if (cur_HIT_num == 0):
        num_questions = 12
    else:
        num_questions = 10
        
        
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
########################## repost HIT #########################################
###############################################################################
"""

master_submitted_tasks_tracker = pd.read_csv(os.path.join(output_dir, ("all_submitted_tracker_ninaSep-22-2023.csv")))
master_worker_response_tracker = pd.read_csv(os.path.join(output_dir, ("master_worker_response_tracke_Sep-22-2023.csv")))

unsubmitted_hits = find_unsubmitted_hits(master_submitted_tasks_tracker, master_worker_response_tracker)
unsubmitted_hit_list = get_unsubmitted_hit_list(unsubmitted_hits)


# Call the function with the unsubmitted_hit_list
unsubmitted_master_submitted_tasks_tracker = post_unsubmitted_hits(unsubmitted_hit_list, input_dir, create_hits_in_live, key_dir, max_worker_num)
unsubmitted_master_submitted_tasks_tracker = unsubmitted_master_submitted_tasks_tracker.sort_values(by='HIT').reset_index(drop=True)

unsubmitted_master_submitted_tasks_tracker.to_csv(os.path.join(output_dir, ('re_submitted_tracker_' + today + '.csv')))

# a for loop to print out the HIT address of all HITs in unsubmitted_master_submitted_tasks_tracker, in the format of "HIT0: address"
for index, row in unsubmitted_master_submitted_tasks_tracker.iterrows():
    cur_HIT_num = row['HIT']
    hit_address = row['HIT_website_address']
    print("HIT" + str(cur_HIT_num) + ": " + hit_address)


"""
###############################################################################
#### merge response collected from the same expert from multiple days #########
###############################################################################
"""   
output_dir = "../results/all_experts"

# Dan: 
merge_responses(["May-14-2023", "May-16-2023", "May-17-2023", "May-18-2023"], 'A10892I86DG5PR', 'Dan', output_dir)

# Wali:
merge_responses(["Jun-19-2023", "Jul-14-2023", "Wali_reSub_Jul-14-2023"], 'ARUXAWT9AUG92', 'Wali', output_dir)


