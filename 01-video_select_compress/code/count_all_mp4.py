import os

def count_mp4_files(directory):
    mp4_count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if ((file.endswith('.mp4')) or (file.endswith('.MP4'))):
                mp4_count += 1
    return mp4_count

folder_path = "/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Kay Yang/sorted_cow_videos_all"
total_mp4 = count_mp4_files(folder_path)
print(f"Total number of .mp4 videos in the folder and its subfolders: {total_mp4}")

# 1046 videos in total