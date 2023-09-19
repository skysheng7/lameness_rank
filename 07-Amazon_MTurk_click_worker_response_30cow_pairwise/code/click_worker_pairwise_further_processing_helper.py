def process_data(df_1, df_2):
    if (df_2['HIT'].iloc[0] == 0) :
        all_test_q = df_1[(df_1['question_type'] == "pos_attention_easy")].copy()
        all_q_col = [f"q{i}" for i in range(1, 13)]
    else:
        # Remove all positive and negative attention checks, keep only 1 copy of the positive attention check
        all_test_q = df_1[(df_1['question_type'] != "neg_attention") & (df_1['question_type'] != "pos_attention_easy")].copy()
        all_q_col = [f"q{i}" for i in range(1, 11)]
        #pos_attention_q = df_1[df_1['question_type'] == "pos_attention_easy"].head(1).copy()

    # Concatenate the dataframes and reset the index
    #all_q = pd.concat([all_test_q, pos_attention_q], ignore_index=True)
    all_q = all_test_q
    all_q.reset_index(drop=True, inplace=True)

    # Select the desired columns and convert question_num to int
    all_q2 = all_q[['cow_L', 'cow_R', 'question_num', 'HIT']].copy()
    all_q2.loc[:, 'question_num'] = all_q2['question_num'].str[1:].astype(int)

    # Select the columns for response dataframe
    all_col = all_q_col.copy()
    all_col.append('HIT')
    all_col.append('Worker_id')

    # Get the response dataframe
    response = df_2[all_col].copy()

    return all_q2, response


def reshape_and_remove_nan(df):
    if (df['HIT'].iloc[0] == 0) :
        val_col = ['q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8', 'q9', 'q10', 'q11', 'q12']
    else:
        val_col = ['q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8', 'q9', 'q10']

    df_melted = df.melt(id_vars= ['HIT', 'Worker_id'], 
                        value_vars=val_col, 
                        var_name='question_num', 
                        value_name='response')
    df_melted['question_num'] = df_melted['question_num'].str[1:].astype(int)
    df_melted = df_melted.dropna()
    df_melted2 = df_melted[(df_melted['response'] != "video not playing")].copy().reset_index(drop=True)
    df_melted2['response'] = df_melted2['response'].astype(int)
    return df_melted2


def process_and_merge(df_1, df_2):
    all_q2, response = process_data(df_1, df_2)
    response_melted = reshape_and_remove_nan(response)
    merged_df = all_q2.merge(response_melted, on=['HIT', 'question_num'], how='inner').dropna()
    #merged_df2 = merged_df[['cow_L', 'cow_R', 'response']]
    merged_df2 = merged_df

    return merged_df2


def create_winner_loser_degree_df(final_df):
    winner = []
    loser = []
    degree = []

    for _, row in final_df.iterrows():
        if row['response'] <= 0:
            winner.append(row['cow_L'])
            loser.append(row['cow_R'])
            degree.append(abs(row['response']))
        else:
            winner.append(row['cow_R'])
            loser.append(row['cow_L'])
            degree.append(abs(row['response']))

    new_df = pd.DataFrame({
        'winner': winner,
        'loser': loser,
        'degree': degree
    })

    return new_df

def filter_HIT0_response_by_selected_worker(expert_response_dir, df_2):
    # first luanch of HIT0 12 questions 100 click workers recruited to do the test
    selected_worker = high_performance_worker(df_2, 90)
    
    temp1 = df_2[df_2['Worker_id'].isin(selected_worker)].copy()

    # second luanch of HIT0 12 questions 1 click workers recruited to re-do the test as he requested
    os.chdir(expert_response_dir)
    special_worker = pd.read_csv("master_all_responses_click_worker_Aug-07-2023.csv")
    selected_worker2 = high_performance_worker(special_worker, 90)
    temp2 = special_worker[special_worker['Worker_id'].isin(selected_worker2)].copy()

    df_2 = pd.concat([temp1, temp2], axis = 0)

    return df_2

def convert_pairwise_to_long(answer_dir, expert_response_dir, data_path_1, data_path_2, hits):
    """
    Convert click workers' response to each HIT (10 questions per HIT) into a long format
    recording cow ID for the cow on the left, cow ID for the right, and each click worker's 
    response about which cow is more lame & how much more lame
     
    Parameters:
    - answer_dir (str): Directory containing answer data.
    - expert_response_dir (str): Directory containing expert response data.
    - data_path_1 (str): Path to the first data file.
    - data_path_2 (str): Path to the second data file.
    - hits (str): String indicating the number of HITs, used in the output file name.
    
    Returns:
    - final_df (DataFrame): All responses without filtering.
    - final_df_pass_pos (DataFrame): Responses from workers who passed positive attention checks.
    - final_df_pass_neg (DataFrame): Responses from workers who passed negative attention checks.
    - final_df_pass_both (DataFrame): Responses from workers who passed both positive & negative attention checks.
    """
    
    
    os.chdir(answer_dir)
    df_1 = pd.read_csv(data_path_1)
    
    os.chdir(expert_response_dir)
    df_2 = pd.read_csv(data_path_2)

    if (df_2['HIT'].iloc[0] == 0) :
        df_2 = filter_HIT0_response_by_selected_worker(expert_response_dir, df_2)
    
    # All response, without filtering workers based on if they passed positive & negative attention checks
    final_df = process_and_merge(df_1, df_2)
    
    # Only workers who passed positive attention checks
    df_2_pass_pos = df_2[df_2['passed_positive_attention_easy'] == True].copy()
    final_df_pass_pos = process_and_merge(df_1, df_2_pass_pos)
    
    # Only workers who passed negative attention checks
    df_2_pass_neg = df_2[df_2['passed_negative_attention'] == True].copy()
    final_df_pass_neg = process_and_merge(df_1, df_2_pass_neg)
    
    # Workers who passed both positive & negative attention checks
    df_2_pass_both = df_2[(df_2['passed_negative_attention'] == True) & (df_2['passed_positive_attention_easy'] == True)].copy()
    final_df_pass_both = process_and_merge(df_1, df_2_pass_both)

    return final_df, final_df_pass_pos, final_df_pass_neg, final_df_pass_both
# Example usage:
# process_data(answer_dir1, expert_response_dir, data_path_1, data_path_2, "10HITs")



def sample_data_from_unique_qname(final_df):
    # Extract unique combinations of "HIT", "question_num", and "Worker_id"
    HIT_qNum_worker = final_df

    # Create the 'id' column
    HIT_qNum_worker['id'] = HIT_qNum_worker['HIT'].astype(str) + "-" + HIT_qNum_worker['question_num'].astype(str)

    # Group by 'id' and count the number of workers
    count_worker_per_pair = HIT_qNum_worker.groupby('id').size().reset_index(name='count')
    count_worker_per_pair.columns = ["q_name", "worker_num"]

    # Sample the same number of rows from each unique q_name
    min_worker_per_pair = count_worker_per_pair['worker_num'].min()
    sampled_data = HIT_qNum_worker.groupby('id').apply(lambda x: x.sample(min_worker_per_pair)).reset_index(drop=True)
    
    return sampled_data, min_worker_per_pair

# Usage example:
# sampled_df = sample_data_from_unique_qname(final_df)


def five_milestone_min_compare(final_df_sampled, filtered_cows, milestone, type, min_worker_per_pair):
    """
    Generate comparisons between the filtered cows and milestone cows.

    Parameters:
    - final_df_sampled: DataFrame containing the sampled data.
    - filtered_cows: List of cows to be compared against the milestone cows.
    - milestone: List of milestone cows.
    - type: 
        - "min": minimum number of comparisons with milestone cows - start 
                 comparing with the most healthy cow, stop when the current 
                 cow is more than 1 degree more healthy than the milestone cow.
                 generate fake comparison data with the rest of the milestone cows
                 by setting the loser (more healthy cow) to always be the current cow.
                 The number of rows generated depends on min_worker_per_pair
        - "max": maximum number of comparisons with milestone cows: compare 
                 with each of the milestone cows
    - min_worker_per_pair: how many fake rows you want to generate when using "min"
                 type

    Returns:
    - milstone_compare: DataFrame containing the comparisons.
    """

    # Set the seed
    import random
    random.seed(42)

    # generate comparisons between the filtered cows and milestone cows
    milstone_compare = pd.DataFrame(columns=final_df_sampled.columns)

    for cow in filtered_cows:
    # since the percentage of healthy cows should be higher than the percentage of lame cows, 
    # go iterate through the milestone cow list from left to right (most healthy to most lame)
        position_secure = False # this is a flag variable to indicate for this cow, if her 
                                # position is secured by comparing with milestone cows

        for stone in milestone:
            cur_pair_results = final_df_sampled[((final_df_sampled['cow_L'] == cow) & (final_df_sampled['cow_R'] == stone)) 
                            | ((final_df_sampled['cow_L'] == stone) & (final_df_sampled['cow_R'] == cow))]
            
            if (type == "max"):
                # add the comparison between this cow and the milstone cow to the comparison list
                milstone_compare = pd.concat([milstone_compare, cur_pair_results], ignore_index=True)
                
            elif ((type == "min") & (not position_secure)) :
                # add the comparison between this cow and the milstone cow to the comparison list
                milstone_compare = pd.concat([milstone_compare, cur_pair_results], ignore_index=True)
                # calculate average response from worker for this pair comparison
                pair_avg = cur_pair_results['response'].mean()

                # if the milestone cow is on the left, and average click worker response < -1, 
                # meaning left cow clearly more lame, current cow more healthy, no need to compare
                # with other cows that are more lame
                if ((pair_avg < -1) & (cur_pair_results['cow_L'].iloc[0] == stone)):
                    position_secure = True # position is secured, flag variable set to True
                elif((pair_avg > 1) & (cur_pair_results['cow_R'].iloc[0] == stone)):
                    position_secure = True

            elif ((type == "min") & (position_secure)) :
                # generate fake rows of comparisons with the rest of the milestone cows by always 
                # setting the current cow to be the loser (more healthy)
                cow_L = [cow] * min_worker_per_pair
                cow_R = [stone] * min_worker_per_pair
                question_num = [random.randint(-200, -100)] * min_worker_per_pair # place holder column, won't be used in the future
                new_HIT_col = [random.randint(-200, -100)] * min_worker_per_pair # place holder column, won't be used in the future
                Worker_id = [random.randint(-200, -100) for _ in range(min_worker_per_pair)] # place holder column, won't be used in the future
                response = [3] * min_worker_per_pair
                id_col_value = [str(hit) + "-" + str(qn) for hit, qn in zip(new_HIT_col, question_num)]# place holder column, won't be used in the future

                new_df = pd.DataFrame({
                            'cow_L': cow_L,
                            'cow_R': cow_R,
                            'question_num': question_num,
                            'HIT': new_HIT_col,
                            'Worker_id':Worker_id,
                            'response': response,
                            'id': id_col_value
                        })
                # add the comparison between this cow and the milstone cow to the comparison list
                milstone_compare = pd.concat([milstone_compare, new_df], ignore_index=True)
                
    return milstone_compare

            