import os
import pandas as pd
exec(open("01-video_select_compress/code/count_all_mp4_helper.py").read())

# count the total number of mp4 files in the current folder (including mp4 files in the subfolder of the current folder)
folder_path = "/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Kay Yang/sorted_cow_videos_all"
total_mp4 = count_mp4_files(folder_path)
print(f"Total number of .mp4 videos in the folder and its subfolders: {total_mp4}")

# 1046 videos in total


# count the total number of mp4 files for each cow (subfolder under the current directory)
results = count_mp4_files_per_subfolder(folder_path)

# Convert results to a dataframe
df = pd.DataFrame(results, columns=['Subfolder', 'MP4 Count'])

print(df)
df.to_csv("01-video_select_compress/results/videos_per_cow_count.csv", index = False)

