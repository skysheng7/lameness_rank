![gif](04-generate_54HIT_html_experts/results/platform_example_short.gif)

# Redefining Lameness Assessment Using Crowd-Sourced Data

This repository contains the data and code for our project: **Which Cow is Most Lame? Redefining Lameness Assessment Using Crowd-Sourced Data**.

# Example Videos in Lameness Hierarchy
![gif](08-Lameness_rank_eloSteepness/plots/hierarchy_example.gif)

## Repository Structure
Here's a brief overview of the repository's structure. The prefix number in each folder name indicates the sequence of analysis. Each folder contains code and results in the sub-analysis:

- **00-easy_hard_question_cutoff**: Contains machine learning models and output used in analyzing a old data set from phase 1 of this project, in order to distinguish video pairs with clearly distinguishable (easy) and hard to distinguish (hard) lameness differences between the 2 cows.
- **01-video_select_compress**: Dataset that contains selected cow videos and code for video compression.
- **02-generate_30cow_GS_label_html_experts**: Code and data for generating HTML files to score 30 cows based on 5 level locomotion scoring system.
- **03-30cow_GS_label_expert_response**: 5 experts' (3 rounds per experts) answer regarding 30 cows' gait score.
- **04-generate_54HIT_html_experts**: Code and data used in generating HTML to ask lameness experts to compare every 2 cows in the 30 cow group (435 pairs of comparisons) for pairwise lameness assessment.
- **05-Amazon_MTurk_expert_response_30cow_pairwise**: 4 experts' responses to 435 pairs of lameness comparisons on Amazon MTurk.
- **06-generate_54HIT_html_click_worker**: Code and data used in generating HTML to ask click workers from Amazon MTurk to compare every 2 cows in the 30 cow group for pairwise lameness assessment.
- **07-Amazon_MTurk_click_worker_response_30cow_pairwise**: 20 click workers' responses to 435 pairs of lameness comparisons on Amazon MTurk.
- **08-Lameness_rank_eloSteepness**: Lameness rank generated based on pairwise lameness assessment using EloSteepness.
- **09-Lameness_rank_merge_sort**: Lameness rank generated based on pairwise lameness assessment using merge sort.
- **10-Lameness_rank_borda_counting**: Lameness rank generated based on pairwise lameness assessment using borda counting.

Thank you for your interest in our project. We hope you find the data and code insightful!

## Dataset Information

- **Title of Dataset:** Replication Data for: Utilizing Crowd-Sourced Data from Amazon MTurk to Derive Lameness Rankings of Diary Cows
- **Dataset DOI:** <https://doi.org/10.5683/SP3/QF1VTK>
- **Dataset Created:** 2023-09-17
- **Created by:** Kehan (Sky) Sheng

## Contributors

- **Principal Investigator:** Daniel Weary  
  - ORCID: 0000-0002-0917-3982  
  - Affiliation: University of British Columbia  
  - Email: <dan.weary@ubc.ca>
  
- **Co-investigator:** Marina von Keyserlingk  
  - ORCID: 0000-0002-1427-3152  
  - Affiliation: University of British Columbia  
  - Email: <nina@mail.ubc.ca>

- **Co-investigator:** Tiffany-Anne Timbers
  - ORCID: 0000-0002-2667-376X
  - Affiliation: University of British Columbia  
  - Email: <tiffany.timbers@stat.ubc.ca>

- **Contributor:** Kehan (Sky) Sheng  
  - ORCID: 0000-0001-6442-5284  
  - Affiliation: University of British Columbia  
  - Email: <skysheng7@gmail.com>

- **Contributor:** Borbala Foris  
  - ORCID: 0000-0002-0901-3057  
  - Affiliation 1: University of British Columbia
  - Affiliation 2: University of Veterinary Medicine, Vienna
  - Email: <forisbori@gmail.com>

- **Contributor:** Varinia Cabrera
  - ORCID: https://orcid.org/0009-0007-7819-6612
  - Affiliation 1: University of British Columbia  
  - Affiliation 2: Universidad de la República de Uruguay
  - Email: <variniacabrera6@gmail.com>

## Project Information

- **Date of Video Collection:** March 30, 2021 - June 11, 2021
- **Location of Video Collection:** UBC Dairy Education and Research Centre, 6947 No. 7 Highway, Agassiz, BC V0M 1A0, Canada  
- **Funding:** This project was supported by the NSERC Industrial Research Chair, University of British Columbia Land and Food System Internal Research Grant.
