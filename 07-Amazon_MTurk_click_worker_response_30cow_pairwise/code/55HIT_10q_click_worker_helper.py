
"""
###############################################################################
######################## Connect to Amazon AWS API ############################
###############################################################################
"""

""" 
Connect to Amazon AWS using access key
"""

def create_mturk_client(create_hits_in_live, key_dir):
    # Load the access key credential file
    access_key = pd.read_csv(os.path.join(key_dir, ("awp_rootkey.csv")), header=None)
    access_key_id_raw = access_key.at[0, 0]
    access_key_key_raw = access_key.at[1, 0]

    # Specify region name and access key to Amazon AWS account
    region_name = 'us-east-1'
    aws_access_key_id = access_key_id_raw.split("=")[1]
    aws_secret_access_key = access_key_key_raw.split("=")[1]
    
    environments = {
        "live": {
            "endpoint": "https://mturk-requester.us-east-1.amazonaws.com",
            "preview": "https://www.mturk.com/mturk/preview",
            "manage": "https://requester.mturk.com/mturk/manageHITs",
        },
        "sandbox": {
            "endpoint": "https://mturk-requester-sandbox.us-east-1.amazonaws.com",
            "preview": "https://workersandbox.mturk.com/mturk/preview",
            "manage": "https://requestersandbox.mturk.com/mturk/manageHITs",
        },
    }
        
    mturk_environment = environments["live"] if create_hits_in_live else environments["sandbox"]
    


    client = boto3.client(
        service_name='mturk',
        region_name=region_name,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        endpoint_url=mturk_environment['endpoint'],
    )

    return client, mturk_environment


def initialize_mturk_client(create_hits_in_live, html_name, cur_HIT_num, max_worker_num, key_dir):
    # Set the number of questions
    num_questions = set_num_questions(cur_HIT_num)
    award_value = num_questions / 10

    # Use profile if one was passed as an arg, otherwise
    profile_name = sys.argv[1] if len(sys.argv) >= 2 else None
    session = boto3.Session(profile_name=profile_name)
    
    # Create a client
    client, mturk_environment = create_mturk_client(create_hits_in_live, key_dir)

    # Test that you can connect to the API by checking your account balance
    user_balance = client.get_account_balance()
    # In Sandbox this always returns $10,000. In live, it will be your actual balance.
    print("Your account balance is {}".format(user_balance['AvailableBalance']))

    mturk_environment['reward'] = str(award_value)
    return client, mturk_environment



"""
###############################################################################
################################ Create HITs ##################################
###############################################################################
"""

def create_and_submit_hit(client, input_dir, html_name, mturk_environment, max_worker_num, num_questions, cur_HIT_num, worker_qual):
    question_sample = open(os.path.join(input_dir, (html_name + ".html")), "r").read()

    # Master's qualification ID in live production environment: 2F1QJWKUDD8XADTFD2Q0G6UTO95ALH, comparator = "Exists"
    # this means we want master workers (high performance workers)
    #Worker_​PercentAssignmentsApproved ID: 000000000000000000L0
    if (worker_qual == "master"):
        worker_requirements = [{
            'QualificationTypeId': '2F1QJWKUDD8XADTFD2Q0G6UTO95ALH',
            'Comparator': 'Exists',
            'RequiredToPreview': True,
        }]
    elif (worker_qual == "nothing"):
        worker_requirements = [{
            'QualificationTypeId': '000000000000000000L0',
            'Comparator': 'GreaterThanOrEqualTo',
            'IntegerValues': [0],  # we only want workers with >= 90% approval rate in the past
            'RequiredToPreview': True,
        }]
    elif (worker_qual == "90 approval"):
        worker_requirements = [{
            'QualificationTypeId': '000000000000000000L0',
            'Comparator': 'GreaterThanOrEqualTo',
            'IntegerValues': [90],  # we only want workers with >= 90% approval rate in the past
            'RequiredToPreview': True,
        }]
    elif (worker_qual == "lameness"): # lameness experts in click workers qualification ID: '35YP7MFUO4XIASEUSZARYDBCH36O8B'
        worker_requirements = [{
            'QualificationTypeId': '35YP7MFUO4XIASEUSZARYDBCH36O8B',
            'Comparator': 'Exists',
            'RequiredToPreview': True,
        }]

    response = client.create_hit(
        MaxAssignments=max_worker_num,  #MaxAssignments: how many Workers you want to work on this 
        LifetimeInSeconds=(30*24*60*60), # 30days # How long this HIT will show up on the market
        AssignmentDurationInSeconds=1800, # 30 minutes # How long we allow the worker to work on one assignment
        AutoApprovalDelayInSeconds=1209600, # 14 days # How long to auto approve if we did not click approve ourselves
        Reward=mturk_environment['reward'],
        Title='Require PC/tablet/laptop: Which cow is more lame, and by how much? (' + str(num_questions) + ' questions) ' +  html_name + ' ' + str(today),
        Keywords='cow, video, agriculture, animal, lameness',
        Description='Play two videos of cows walking side by side, and select which cow looks more lame to you.',
        Question=question_sample,
        QualificationRequirements=worker_requirements,
    )

    # Get the preview of HIT and the result
    # The response included several fields that will be helpful later
    hit_type_id = response['HIT']['HITTypeId']
    hit_id = response['HIT']['HITId']
    hit_address = str(mturk_environment['preview'] + "?groupId={}".format(hit_type_id))
    result_address = str(mturk_environment['manage'])

    print("\nCreated HIT: {}".format(hit_id))
    print("\nYou can work the HIT here:")
    print(mturk_environment['preview'] + "?groupId={}".format(hit_type_id))
    print("\nAnd see results here:")
    print(mturk_environment['manage'])
    
    # Record the HIT address, and detailed information into a datasheet: submitted_tasks_tracker
    new_row = [{'HIT': cur_HIT_num, 'HIT_id': hit_id, 'HIT_website_address': hit_address, 'HIT_results_address': result_address}]
    submitted_tasks_tracker = pd.DataFrame(new_row)

    return submitted_tasks_tracker



def load_answer_key(input_dir, html_name):
    HIT_answer = pd.read_csv(os.path.join(input_dir, (html_name + "_answer.csv")))
    HIT_answer2 = HIT_answer[["expert_answer", "question_type", "question_num"]]
    return HIT_answer2

def process_html_files(html_files, input_dir, create_hits_in_live, key_dir, max_worker_num):
    master_submitted_tasks_tracker = pd.DataFrame()

    for html_file in html_files:
        #if html_file == "HIT0.html":
        #    continue

        html_name, cur_HIT_num = extract_hit_details(html_file)

        num_questions = set_num_questions(cur_HIT_num)
        award_value = num_questions / 10

        HIT_answer2 = load_answer_key(input_dir, html_name)

        client, mturk_environment = initialize_mturk_client(create_hits_in_live, html_name, cur_HIT_num, max_worker_num, key_dir)

        submitted_tasks_tracker = create_and_submit_hit(client, input_dir, html_name, mturk_environment, max_worker_num, num_questions, cur_HIT_num, worker_qual)

        master_submitted_tasks_tracker = pd.concat([master_submitted_tasks_tracker, submitted_tasks_tracker], ignore_index=True)

    return master_submitted_tasks_tracker

def extract_hit_details(html_file):
    match = re.match(r'(HIT\d+)', html_file)
    if match:
        html_name = match.group(1)
        cur_HIT_num = int(match.group(1)[3:])
        return html_name, cur_HIT_num
    return None, None

def set_num_questions(cur_HIT_num):
    if cur_HIT_num == 0:
        return 12
    else:
        return 10



"""
###############################################################################
########################## Collect Worker Response ############################
###############################################################################
"""
def all_q_columns(num_questions):
    return [f"q{i}" for i in range(1, num_questions + 1)]

def check_duplicate_ips(worker_response):
    # get the IP addresses from the worker_response dataframe
    ips = worker_response['worker_ip']

    # check for duplicate IP addresses
    duplicated_ips = ips[ips.duplicated()]

    # store only the unique duplicated IP addresses
    unique_duplicated_ips = duplicated_ips.unique()

    # filter out None values from unique_duplicated_ips
    unique_duplicated_ips = [ip for ip in unique_duplicated_ips if ip is not None]

    # create a dataframe to store the unique duplicated IP addresses
    duplicates_df = pd.DataFrame({'worker_ip': unique_duplicated_ips})

    return duplicates_df 

def process_responses(need_approve_or_reject, approve_all, response, worker_response_tracker, approved_responses, rejected_responses, cur_HIT_num, hit_id, hit_address, result_address, hit_status, HIT_answer2, all_responses, q_col, track_ip, client, need_score):
    
    # get the answer from the worker's response which is in XML format
    assignments = response['Assignments']
    
    # extract worker's response from XML format 
    if response['NumResults'] > 0:
        worker_response_tracker = extract_answer(assignments, cur_HIT_num, hit_id, hit_address, result_address, hit_status, worker_response_tracker, q_col)
    
    # iterate through each worker and score them
    for index in range(len(worker_response_tracker)):
        response_row = worker_response_tracker.iloc[[index]].copy()

        # Score the worker's response
        response_row, passed_negative_att, passed_pos_att1 = score_package(response_row, HIT_answer2, q_col, need_score)

        # check duplicated iP address, if the same IP appears >=2 times, the first submitted HIT is approved, and all the later HITs are rejected
        duplicates_df = check_duplicate_ips(worker_response_tracker.iloc[:(index+1)].copy())

        all_responses = pd.concat([all_responses, response_row.iloc[-1:]], ignore_index=True)
    
        if (need_approve_or_reject):
            approved_responses, rejected_responses = approve_or_reject(approve_all, response_row, duplicates_df, track_ip, HIT_answer2, q_col, passed_negative_att, passed_pos_att1, client, approved_responses, rejected_responses)
            
    return worker_response_tracker, approved_responses, rejected_responses, all_responses

# approve the work or rejct the work
def approve_or_reject(approve_all, response_row, duplicates_df, track_ip, HIT_answer2, q_col, passed_negative_att, passed_pos_att1, client, approved_responses, rejected_responses):
    assignment_id = response_row.loc[response_row.index[0], 'Assignment_id']
    assignment_status = response_row.loc[response_row.index[0], 'assignment_status']

    # Evaluate the response and update approved and rejected DataFrames
    # if we want to just approve all HITs without checking
    if approve_all:
        # Add the worker's response to the approved_responses DataFrame
        approved_responses = pd.concat([approved_responses, response_row.iloc[-1:]], ignore_index=True)
        
        if (assignment_status == "Submitted"):
            # Approve the assignment
            client.approve_assignment(
                AssignmentId=assignment_id,
                RequesterFeedback="Your submission has been approved. Thank you for your utterly remarkable work!",
            )
            print("Approved HIT: " + str(assignment_id))
    else:
        # Check if the worker's response meets the criteria
        if check_criteria(response_row, duplicates_df, track_ip, HIT_answer2, q_col, passed_negative_att, passed_pos_att1):
            # Add the worker's response to the approved_responses DataFrame
            approved_responses = pd.concat([approved_responses, response_row.iloc[-1:]], ignore_index=True)
            
            if (assignment_status == "Submitted"):
                # Approve the assignment
                client.approve_assignment(
                    AssignmentId=assignment_id,
                    RequesterFeedback="Your submission has been approved. Thank you for your utterly remarkable work!",
                )
                print("Approved HIT: " + str(assignment_id))
            
        
        else:
            # Add the worker's response to the rejected_responses DataFrame
            rejected_responses = pd.concat([rejected_responses, response_row.iloc[-1:]], ignore_index=True)

            if (assignment_status == "Submitted"):
                # Reject the assignment
                client.reject_assignment(
                    AssignmentId=assignment_id,
                    RequesterFeedback="Your submission has been rejected because you failed the attention checks. Please carefully follow the instructions.",
                )
                print("Rejected HIT: " + str(assignment_id))
    
    return approved_responses, rejected_responses

def score_package(response_row, HIT_answer2, q_col, need_score):
    row_index = response_row.index[-1]
    passed_negative_att = passed_negative_attention(response_row, HIT_answer2, q_col)
    passed_pos_att1 = passed_positive_attention1(response_row, HIT_answer2, q_col)
    response_row.loc[row_index, 'passed_negative_attention'] = passed_negative_att
    response_row.loc[row_index, 'passed_positive_attention_easy'] = passed_pos_att1

    if need_score:
        score_pct, correct_questions, incorrect_questions = score_worker(response_row, HIT_answer2, q_col)
        score_mt1 = score_worker_expert_answer_me2(response_row, HIT_answer2, q_col)
        score_le1 = score_worker_expert_answer_lt2(response_row, HIT_answer2, q_col)
        
        response_row.loc[row_index, 'score_all'] = score_pct
        response_row.loc[row_index, 'score_me2'] = score_mt1
        response_row.loc[row_index, 'score_lt2'] = score_le1
        response_row.loc[row_index, 'correct_questions'] = ','.join(correct_questions)
        response_row.loc[row_index, 'incorrect_questions'] = ','.join(incorrect_questions)
    else:
        response_row.loc[row_index, 'score_all'] = None
        response_row.loc[row_index, 'score_me2'] = None
        response_row.loc[row_index, 'score_lt2'] = None
        response_row.loc[row_index, 'correct_questions'] = None
        response_row.loc[row_index, 'incorrect_questions'] = None
    
    return response_row, passed_negative_att, passed_pos_att1


def extract_answer(assignments, cur_HIT_num, hit_id, hit_address, result_address, hit_status, worker_response_tracker, q_col):

    submitted_num = len(assignments)
    
    for assignment in assignments:
        worker_id = assignment['WorkerId']
        assignment_id = assignment['AssignmentId']
        assignment_status = assignment['AssignmentStatus']
        answer_xml = parseString(assignment['Answer'])
        accept_time = assignment['AcceptTime']
        Submit_Time = assignment['SubmitTime']

        # the answer is an xml document. we pull out the value of the first
        # //QuestionFormAnswers/Answer/FreeText
        answer_js = answer_xml.getElementsByTagName('FreeText')[0]
        # See https://stackoverflow.com/questions/317413
        only_answer = " ".join(t.nodeValue for t in answer_js.childNodes if t.nodeType == t.TEXT_NODE)
        # load the JSON string as a pythoon object
        json_answer = json.loads(only_answer)
        # Extract the worker's IP address from the answer XML
        worker_ip_bot = json_answer[0].pop("worker_ip", None)
        json_answer_dict = json_answer[0].copy()
        # Extract the comments from the answer XML
        comment = json_answer_dict.pop("comment", None)
        json_answer_dict = json_answer_dict.copy()
        if worker_ip_bot is not None:
            parts = worker_ip_bot.split("-");
            worker_ip = parts[0];
            isBot = parts[1];
        else:
            worker_ip = None
            isBot = None
        
        # Make a copy of the dictionary inside the list
        

        #print('The Worker with ID {} submitted assignment {} and gave the answer "{}"'.format(worker_id, assignment_id, only_answer))

        # Create a new row for the worker_response_tracker DataFrame
        new_row = {
            'HIT': cur_HIT_num,
            'HIT_id': hit_id,
            'HIT_website_address': hit_address,
            'HIT_results_address': result_address,
            'HIT_status': hit_status,
            'submitted_assignments': submitted_num,
            'Worker_id': worker_id,
            'Assignment_id': assignment_id,
            'Accept_time': accept_time,
            'Submit_time': Submit_Time,
            'Full_response': only_answer,
            'worker_ip': worker_ip,
            'isBot': isBot,
            'assignment_status': assignment_status,
            'comment': comment
        }
        
        
        # Extract the true answers
        true_answers = {}
        for question, answers in json_answer_dict.items():
            for answer, value in answers.items():
                if value:
                    true_answers[question] = answer
        
        # Update the new_row with the true answers
        new_row.update(true_answers)
        
        # Convert the new_row dictionary to a DataFrame
        new_row_sheet = pd.DataFrame([new_row], columns=(['HIT', 'HIT_id', 'HIT_website_address', 'HIT_results_address', 'HIT_status', 'submitted_assignments', 'Worker_id', 'Assignment_id', 'Accept_time', 'Submit_time', 'Full_response', 'worker_ip', 'isBot','assignment_status', 'comment'] + q_col))
        
        worker_response_tracker = pd.concat([worker_response_tracker,new_row_sheet], ignore_index=True)
        
    return worker_response_tracker


# this function checks if workers should be approved or rejected for their work
# their work would be rejected if meeting 1 of the following creteria:
# [1] their work are in duplicated IP address
# [2] they clicked the same answer for all questions
# [3] they failed the 1st positive attention check questions, the easy one
# [4] they failed the negative attention check quetsion
# otherwise their work was approved
def check_criteria(response_row, duplicates_df, track_ip, HIT_answer2, q_col, pass_neg, pass_pos):

    # Check if worker selected the same answer for all questions
    question_columns = q_col
    unique_answers = set(response_row.iloc[-1][question_columns].values)
    if len(unique_answers) == 1:
        return False
    
    # Check if worker IP address is in the list of duplicates
    if (track_ip) and (duplicates_df.shape[0] > 0): # if we track IP and delete based on duplicated IP
        worker_ip = response_row.iloc[-1]['worker_ip']
        if worker_ip in duplicates_df['worker_ip'].values:
            return False

    # Check for pos_attention questions
    if pass_pos is not None:
        if not pass_pos:
            return False

    # Check for neg_attention questions
    if pass_neg is not None:
        if not pass_neg:
            return False

    return True


# assess if I need to score the worker or not
def need_to_score(cur_HIT_num):
    if cur_HIT_num == 0:
        return True
    else:
        return False

# score the workers response for all 12 questions. 
# only score for "which cow is more lame", not "how much more lame"
# if the correct answer is positive (cow on the right is more lame), they get 1 score if their response is also positive
# if the correct answer is negative (cow on the left is more lame), they get 1 score if their response is also negative  
# if the correct answer is the same, they get 1 score if their response is also the same 
def score_worker(response_row, HIT_answer2, q_col):
  
    question_columns = q_col
    score = 0
    correct_questions = []
    incorrect_questions = []

    for question, answer in response_row.iloc[-1][question_columns].items():
        if answer == "video not playing":
            incorrect_questions.append(question)
            continue

        question_data = HIT_answer2.loc[HIT_answer2['question_num'] == question].iloc[0]
        expert_answer = question_data['expert_answer']
        int_answer = int(answer)

        if ((expert_answer * int_answer) > 0) or (expert_answer == 0 and int_answer == 0):
            score += 1
            correct_questions.append(question)
        else:
            incorrect_questions.append(question)

    score_pct = (score/len(question_columns))* 100
    return score_pct, correct_questions, incorrect_questions

# score the workers response only for questions where the absolute GS difference between the 2 cows >= 1, and not the positive attention check
# only score for "which cow is more lame", not "how much more lame"
def score_worker_expert_answer_me2(response_row, HIT_answer2, q_col):

    question_columns = q_col
    score = 0
    total_questions = 0

    for question, answer in response_row.iloc[-1][question_columns].items():
        question_data = HIT_answer2.loc[HIT_answer2['question_num'] == question].iloc[0]
        expert_answer = question_data['expert_answer']
        question_type = question_data['question_type']

        if (abs(expert_answer) >= 2):
            total_questions += 1
            if answer == "video not playing":
                continue

            int_answer = int(answer)

            if ((expert_answer * int_answer) > 0):
                score += 1


    if total_questions > 0:
        score_pct = (score/total_questions) * 100
    else:
        score_pct = 0

    return score_pct

# score the workers response only for questions where the absolute GS difference between the 2 cows < 1, and not a negative attention check
# only score for "which cow is more lame", not "how much more lame"
def score_worker_expert_answer_lt2(response_row, HIT_answer2, q_col):

    question_columns = q_col
    score = 0
    total_questions = 0

    for question, answer in response_row.iloc[-1][question_columns].items():
        question_data = HIT_answer2.loc[HIT_answer2['question_num'] == question].iloc[0]
        expert_answer = question_data['expert_answer']
        question_type = question_data['question_type']

        if (question_type!='neg_attention') and (abs(expert_answer) < 2):
            total_questions += 1
            if answer == "video not playing":
                continue

            int_answer = int(answer)

            if ((expert_answer * int_answer) > 0) or (expert_answer == 0 and int_answer == 0):
                score += 1


    if total_questions > 0:
        score_pct = (score/total_questions) * 100
    else:
        score_pct = 0
        
    return score_pct

# check if the worker passed negative attention checks (2 cows are the same video)
def passed_negative_attention(response_row, HIT_answer2, q_col):

    question_columns = q_col
    score = None

    for question, answer in response_row.iloc[-1][question_columns].items():
        question_data = HIT_answer2.loc[HIT_answer2['question_num'] == question].iloc[0]
        question_type = question_data['question_type']

        if question_type == "neg_attention":
            if answer == "video not playing":
                score = None
                break

            int_answer = int(answer)

            if int_answer == 0:
                score = True
            else:
                score = False
            break

    return score

# check if the worker passed positive attention check, the real easy one
def passed_positive_attention1(response_row, HIT_answer2, q_col):

    question_columns = q_col
    score = None

    for question, answer in response_row.iloc[-1][question_columns].items():
        question_data = HIT_answer2.loc[HIT_answer2['question_num'] == question].iloc[0]
        expert_answer = question_data['expert_answer']
        question_type = question_data['question_type']

        if question_type == 'pos_attention_easy':
            if answer == "video not playing":
                score = None
                continue

            int_answer = int(answer)

            if ((expert_answer * int_answer) <= 0):
                score = False
                break
            else:
                score = True
            
    return score



"""
###############################################################################
################# Create a lameness qualification for workers #################
###############################################################################
"""


def high_performance_worker(master_all_responses, score_thershold):
    pass_neg_pos = master_all_responses.copy()
    pass_neg_pos['passed_negative_attention'] = pass_neg_pos['passed_negative_attention'].fillna(False)  # Replace NaN with False
    pass_neg_pos['passed_positive_attention_easy'] = pass_neg_pos['passed_positive_attention_easy'].fillna(False) 
    pass_neg_pos = pass_neg_pos[pass_neg_pos['passed_negative_attention'] == True]
    pass_neg_pos = pass_neg_pos[pass_neg_pos['passed_positive_attention_easy'] == True]

    high_performance = pass_neg_pos.copy()
    high_performance = high_performance[high_performance['score_all'] > score_thershold]
    
    worker_and_IP = high_performance[['Worker_id', 'worker_ip']]
    # drop worker with duplicated IP, keep the first occurance of the worker ID with duplicated IP, delete the rest
    worker_and_IP_unique = worker_and_IP.drop_duplicates(subset=['worker_ip'], keep='first').reset_index(drop = True)

    return worker_and_IP_unique['Worker_id'].tolist()


def grant_qualification(master_all_responses, score_thershold, qualific_id, client):
    selected_worker = high_performance_worker(master_all_responses, score_thershold)
    # Create a qualification type, only run this once

    # Iterate through your list of worker IDs and grant them the qualification
    for worker_id in selected_worker:
        response = client.associate_qualification_with_worker(
            QualificationTypeId=qualific_id,
            WorkerId=worker_id,
            IntegerValue=1,
            SendNotification=True
        )

        print(response)

