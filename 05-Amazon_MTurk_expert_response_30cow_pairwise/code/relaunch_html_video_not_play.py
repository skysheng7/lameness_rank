import os
import glob
import pandas as pd
from datetime import date
today = date.today().strftime("%b-%d-%Y")
cur_hit = 100

# load the responses from experts
response_dir = "/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/Amazon MTurk expert response"

os.chdir(response_dir)
response = pd.read_csv("master_all_responses_Jun-19-2023.csv")
response2 = response[['HIT', 'Worker_id', 'q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8','q9', 'q10', 'q11', 'q12']]
wali_response = response2[response2["Worker_id"] == "ARUXAWT9AUG92"]
wali_response2 = wali_response[['HIT', 'q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8','q9', 'q10', 'q11', 'q12']]

def reshape_and_remove_nan(df):
    df_melted = df.melt(id_vars='HIT', 
                        value_vars=['q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8', 'q9', 'q10', 'q11', 'q12'], 
                        var_name='question_num', 
                        value_name='response')
    df_melted['question_num'] = df_melted['question_num'].str[1:].astype(int)
    df_melted = df_melted.dropna()
    return df_melted

wali_response3 = reshape_and_remove_nan(wali_response2)

# get a list of questions that has "video not playing" as a response
video_no_pl = wali_response3[wali_response3['response'] == 'video not playing']
video_no_pl = video_no_pl.reset_index(drop=True)
video_no_pl2 = video_no_pl[['HIT', 'question_num']]


# load the answer key recording which cow is which in the original html 
key_dir = "/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/html"
os.chdir(key_dir)
html_key = pd.read_csv("all_HIT_answer.csv")
html_key['question_num'] = html_key['question_num'].str[1:].astype(int)

merged_df = video_no_pl2.merge(html_key, how='left', on=['HIT', 'question_num'])
merged_df2 = merged_df.copy()
merged_df2 = merged_df2.drop(["HIT", "question_num"], axis=1)



# generate html for all the video pairs who has video not playing 
input_dir = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/code/html modify code/input file'
output_dir = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/Amazon MTurk expert response/wali_resubmission_html'
total_ques = merged_df.shape[0]


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



# create each HIT using every 8 test questions + 2 attention checks
def create_HIT(merged_df2, input_dir, output_dir, chunk_q_num):
    # Split the DataFrame into chunks of 10 rows
    chunks = np.array_split(merged_df2, len(merged_df2)//chunk_q_num)
    processed_chunks = []

    for i, chunk in enumerate(chunks):
        cur_hit = 100 + i
    
        # Randomly reshuffle the rows and reset the index
        chunk = chunk.sample(frac=1, random_state=(170+i)).reset_index(drop=True)
        
        # rearrange the columns
        total_ques = chunk.shape[0]

        chunk['question_num'] = ['q' + str(o) for o in range(1, (chunk.shape[0] + 1))]
        chunk['HIT'] = cur_hit
        
        # Append the processed chunk to the list
        processed_chunks.append(chunk)
        
        # save csv
        chunk.to_csv(os.path.join(output_dir, ('HIT' + str(cur_hit) + '_answer.csv')), index=False)
        # generate HTML for the test HIT0
        generate_html(input_dir, output_dir, chunk, total_ques, cur_hit)
    
    # Concatenate the processed chunks into a single DataFrame
    processed_df = pd.concat(processed_chunks, ignore_index=True)
    return processed_df

chunk_q_num = 10
all_HIT_answer = create_HIT(merged_df2, input_dir, output_dir, chunk_q_num)


