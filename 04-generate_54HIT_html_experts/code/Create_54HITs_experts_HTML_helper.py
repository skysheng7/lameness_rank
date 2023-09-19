################################################################
############## Generate HTML of the test HIT ###################
################################################################
# create a function to generate HTML once having the question list

def generate_html(input_dir, output_dir, test_HIT_answer, total_ques, cur_hit):
    """
    ########################## p1 css processing ##############################
    """
    with open(os.path.join(input_dir, r'p1_css.txt'), 'r') as file:
        p1_css = file.read()

    p1_css_mod = p1_css.replace("${total_q_num}", str(total_ques))
    p1_css_mod = p1_css_mod + "\n"

    """
    ######################### p2 html question processing #########################
    """
    video1 = test_HIT_answer['cow_L_URL'].tolist()
    video2 = test_HIT_answer['cow_R_URL'].tolist()

    with open(os.path.join(input_dir, r'p2_html_q1.txt'), 'r') as file:
        p2_html_q1 = file.read()
    with open(os.path.join(input_dir, r'p2_html_other_q.txt'), 'r') as file:
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
    with open(os.path.join(input_dir, r'p3_js.txt'), 'r') as file:
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
    output_file = 'HIT' + str(cur_hit) + '.html'
    with open(os.path.join(output_dir, output_file), 'w') as f:
        f.write(merged_html)


# create a function to include GS and randomly shuffle
def shuffle_and_calculate_gs_diff(gs_df, cow_compare):
    # get the GS for cow on the left and right
    merged_gs = pd.merge(gs_df, cow_compare, left_on='Cow', right_on='cow_L', how='inner')
    merged_gs = pd.merge(merged_gs, gs_df, left_on='cow_R', right_on='Cow', how='inner')
    
    # rename columns
    new_names = {'GS_x': 'cow_L_GS', 'GS_y': 'cow_R_GS'}
    merged_gs = merged_gs.drop(columns=['Cow_x', 'Cow_y']).rename(columns=new_names)

    # randomly shuffle the sequence of the rows for the final product
    shuffled_gs = merged_gs.sample(frac=1, random_state=180).reset_index(drop=True)  # reproducibility
    
    # calculate the correct answer for each video pair based on GS
    # right cow - left cow, if positive, right cow more lame, if negative, left cow more lame
    shuffled_gs['GS_dif'] = shuffled_gs['cow_R_GS'] - shuffled_gs['cow_L_GS']
    
    # re order the columns
    final_gs = shuffled_gs[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL', 'cow_L_GS', 'cow_R_GS', 'GS_dif']]

    return final_gs

# create each HIT using every 8 test questions + 2 attention checks
def create_HIT(all_pairs, pos_neg_attention_checks, input_dir, output_dir, test_q_num):
    # Split the DataFrame into chunks of 8 rows
    chunks = np.array_split(all_pairs, len(all_pairs) // test_q_num)
    processed_chunks = []

    for i, chunk in enumerate(chunks):
        cur_hit = i+1
        # Attach 2 rows from pos_neg_attention_checks
        chunk = pd.concat([chunk, pos_neg_attention_checks], ignore_index=True)
        
        # Randomly reshuffle the rows and reset the index
        chunk = chunk.sample(frac=1, random_state=(170+i)).reset_index(drop=True)
        
        # Add new columns
        chunk['question_num'] = ['q' + str(o) for o in range(1, (chunk.shape[0] + 1))]
        chunk['HIT'] = cur_hit
        chunk['question_id'] = chunk['HIT'].astype(str) + "-" + chunk['question_num']
        
        # rearrange the columns
        chunk = chunk[['cow_L', 'cow_R', 'cow_L_URL', 'cow_R_URL', 'cow_L_GS', 'cow_R_GS', 'GS_dif', 'question_type', 'question_num', 'HIT', 'question_id', 'pair_id']]
        total_ques = chunk.shape[0]
        
        # Append the processed chunk to the list
        processed_chunks.append(chunk)
        
        # save csv
        chunk.to_csv(os.path.join(output_dir, ('HIT' + str(cur_hit) + '_answer.csv')), index=False)
        # generate HTML for the test HIT0
        generate_html(input_dir, output_dir, chunk, total_ques, cur_hit)
    
    # Concatenate the processed chunks into a single DataFrame
    processed_df = pd.concat(processed_chunks, ignore_index=True)
    return processed_df