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

