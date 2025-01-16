# Knee Osteoarthritis Classification 

---

## Overview

This directory contains the project for classification of knee X-ray images to detect and classify the severity of osteoarthritis according to the Kellgren-Lawrence (KL) grading scale. The project is divided into two exercises, which involve both handcrafted feature-based techniques and deep learning models.

## Dataset Description

The dataset used for this project can be downloaded from the following Kaggle link:

[Knee Osteoarthritis Dataset with Severity Grading](https://www.kaggle.com/datasets/shashwatwork/knee-osteoarthritis-dataset-with-severity?resource=download)

This dataset contains knee X-ray images, and the task is to classify these images into the following severity grades:

- **Grade 0**: Healthy knee.
- **Grade 1 (Doubtful)**: Doubtful joint narrowing with possible osteophytic lipping.
- **Grade 2 (Minimal)**: Definite presence of osteophytes and possible joint space narrowing.
- **Grade 3 (Moderate)**: Multiple osteophytes, definite joint space narrowing, with mild sclerosis.
- **Grade 4 (Severe)**: Large osteophytes, significant joint narrowing, and severe sclerosis.

## File Structure & Execution Order

### Exercise 1: Handcrafted Features & Classical Models

This folder contains the files for Exercise 1, which focuses on feature extraction and classification using Support Vector Machines (SVMs) and ensemble tree models.

#### 1. **File 1_A: Dataset Analysis and Preprocessing**
   - This file describes the preliminary analysis of the dataset and all preprocessing operations applied.

#### 2. **File 1_B: Holdout Method**
   - This file contains the implementation of the holdout method, used to evaluate the performance of the models. All results and considerations derived from this approach are presented.

#### 3. **File 1_C: Stratified Cross-Validation**
   - This file describes the stratified cross-validation method and presents the results and considerations.

---

### Exercise 2: Fine-Tuning Deep Learning Models (MobileNet & AlexNet)

This folder contains the files for Exercise 2, which focuses on fine-tuning MobileNet and AlexNet for knee osteoarthritis classification.

#### 1. **File 2a: Fine-Tuning AlexNet**
   - This file includes the implementation of fine-tuning the AlexNet model for classification.

#### 2. **File 2b: Fine-Tuning MobileNet**
   - This file includes the implementation of fine-tuning the MobileNet model for classification.

---

## Example Knee Images for Each Grade

Below is a visual grid displaying examples of knee X-ray images for each severity grade. T
 **Grade 0: Healthy Knee** | **Grade 1: Doubtful** | **Grade 2: Minimal** | **Grade 3: Moderate** | **Grade 4: Severe** |
|:--------------------------:|:---------------------:|:--------------------:|:---------------------:|:-------------------:|
| ![Grade 0 Example](images/Grade_0/9009927_2.png) | ![Grade 1 Example](images/Grade_1/9035317R.png) | ![Grade 2 Example](images/Grade_2/9011053R.png) | ![Grade 3 Example](images/Grade_3/9011053L.png) | ![Grade 4 Example](images/Grade_4/9012867R.png) |
