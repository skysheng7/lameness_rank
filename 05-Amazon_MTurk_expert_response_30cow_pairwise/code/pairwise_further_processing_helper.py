
"""
###############################################################################
###### convert individual expert pairwise response to winner loser df #########
###############################################################################
"""

def merge_csv_files(df, directory, column_order):
    # Get a list of all csv files in the directory
    csv_files = [f for f in os.listdir(directory) if f.endswith('.csv')]

    # Iterate over each file
    for file in csv_files:
        # Create a temporary dataframe to hold the current csv file's data
        temp_df = pd.read_csv(os.path.join(directory, file))

        # Reorder the columns of temporary dataframe to the desired order
        temp_df = temp_df[column_order]

        # Append the data from the temporary dataframe to df
        df = pd.concat([df, temp_df], ignore_index=True)

    return df.reset_index(drop=True)


def process_data(df_1, df_2):
    # Remove all positive and negative attention checks, keep only 1 copy of the positive attention check
    all_test_q = df_1[(df_1['question_type'] != "neg_attention") & (df_1['question_type'] != "pos_attention_easy")].copy()
    pos_attention_q = df_1[df_1['question_type'] == "pos_attention_easy"].head(1).copy()

    # Concatenate the dataframes and reset the index
    all_q = pd.concat([all_test_q, pos_attention_q], ignore_index=True)
    all_q.reset_index(drop=True, inplace=True)

    # Select the desired columns and convert question_num to int
    all_q2 = all_q[['cow_L', 'cow_R', 'question_num', 'HIT']].copy()
    all_q2.loc[:, 'question_num'] = all_q2['question_num'].str[1:].astype(int)

    # Select the columns for response dataframe
    all_q_col = [f"q{i}" for i in range(1, 13)]
    all_col = all_q_col.copy()
    all_col.append('HIT')

    # Get the response dataframe
    response = df_2[all_col].copy()

    return all_q2, response


def reshape_and_remove_nan(df):
    df_melted = df.melt(id_vars='HIT', 
                        value_vars=['q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8', 'q9', 'q10', 'q11', 'q12'], 
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
    merged_df2 = merged_df[['cow_L', 'cow_R', 'response']]

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


