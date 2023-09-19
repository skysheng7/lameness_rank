# this python code will read in all the MP4 file to be used for phase 2, and output the compressed version of it
from moviepy.editor import *
import os

input_folder = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/30cow_artificial_group'
output_folder = '/Users/skysheng/Library/CloudStorage/OneDrive-UBC/University of British Columbia/Research/PhD Project/Amazon project phase 2/Sora Jeong/results/30cow_artificial_group_compressed'
#
# Iterate through all files in the input folder
for file in os.listdir(input_folder):
    # Check if the file is an MP4 file
    if file.endswith('.MP4'):
        # Construct the input file path
        input_file_path = os.path.join(input_folder, file)
        # Load the video file using MoviePy
        video = VideoFileClip(input_file_path)
        # Compress the video (here, we set the bitrate)
        compressed_video = video.resize(0.3) # shrink it down the size
        # Construct the output file path
        output_file_path = os.path.join(output_folder, f'compressed_{file}')
        # Export the compressed video to the output folder
        compressed_video.write_videofile(output_file_path)
        # Close the video file
        video.close()
