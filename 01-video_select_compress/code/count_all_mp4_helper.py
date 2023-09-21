def count_mp4_files(directory):
    mp4_count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if ((file.endswith('.mp4')) or (file.endswith('.MP4'))):
                mp4_count += 1
    return mp4_count

def count_mp4_files_per_subfolder(directory):
    data = []

    # Get immediate subdirectories only
    subdirs = [d for d in os.listdir(directory) if os.path.isdir(os.path.join(directory, d))]

    for subdir in subdirs:
        subdir_path = os.path.join(directory, subdir)
        mp4_count = 0

        for root, _, files in os.walk(subdir_path):
            mp4_count += sum(1 for file in files if file.lower().endswith('.mp4'))

        data.append([subdir, mp4_count])

    return data
