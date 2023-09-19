# -*- coding: utf-8 -*-
import os
import shutil

# specify the path to the main folder
main_folder = '/Users/sora/Library/CloudStorage/OneDrive-UBC/Sora Jeong/data/sorted_cow_video/23cow_10week'

# get a list of folders inside the main folder
folders = os.listdir(main_folder)

# loop through each folder inside the main folder
for folder_name in folders:
    # check if the folder name is a four digit number
    if folder_name.isdigit() and len(folder_name) == 4:
        # get the path to the 'good' folder inside this folder
        good_folder = os.path.join(main_folder, folder_name, 'good')
        # check if the 'good' folder exists
        if os.path.exists(good_folder):
            # loop through each .MP4 file inside the 'good' folder
            for file_name in os.listdir(good_folder):
                if file_name.endswith('.MP4'):
                    # get the new file name without the .MP4 extension
                    no_mp4 = os.path.splitext(file_name)[0]
                    # get the path to the original file
                    mp4_path = os.path.join(good_folder, file_name)
                    # get the path to the new file
                    no_mp4_path = os.path.join(good_folder, no_mp4)
                    # rename the file
                    shutil.move(mp4_path, no_mp4_path)
                    # get the new file name with the corresponding four digit number
                    new_file_name = no_mp4 + '_' + folder_name + '.MP4'
                    # get the path to the original file
                    original_file_path = os.path.join(good_folder, no_mp4)
                    # get the path to the new file
                    new_file_path = os.path.join(good_folder, new_file_name)
                    # rename the file
                    shutil.move(original_file_path, new_file_path)
