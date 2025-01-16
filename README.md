# Biomedical Image Processing Laboratory

---
Projects for the "Laboratorio di Elaborazione di Bioimmagini" course held at @Politecnico di Milano.

---


This repository presents a collection of exciting projects related to the field of biomedical image processing. It covers a wide range of approaches to analyze, process, and classify biomedical images, from basic image filtering techniques to advanced machine learning models.

## Overview

This repository explores several essential areas of biomedical image processing:

- Image Filtering
- Image Segmentation
- Edge Detection**
- Classification
- Machine Learning & Deep Learning Models

---

## Projects in this Repository

### **1. Knee Osteoarthritis Classification**
   - **Goal**: Classifying knee X-ray images to detect and grade osteoarthritis severity using both handcrafted features (e.g., SVM, ensemble trees) and deep learning models (e.g., MobileNet, AlexNet).
   - This project analyzes knee X-ray images to classify the severity of osteoarthritis using multiple models. Classical approaches are combined with deep learning techniques to achieve robust performance.

### **2. Cells Segmentation and Classification**
   - **Goal**: Segmentation of normal and atypical plasmatic cells in a microscopic image.
   - This project involves identifying and segmenting normal and atypical cells based on their morphological features such as area, eccentricity, and intensity variations.

### **3. Edge Detection and Segmentation Using Compass Masks and Morphological Operators**
   - **Goal**: Segmenting an image to extract contours of squares inside circles using edge enhancement and Sobel compass masks.
   - This project applies edge enhancement techniques, followed by Sobel filters, to extract contours and segment complex structures in biomedical images.

### **4. Homomorphic Filtering Procedure**
   - **Goal**: Applying homomorphic filtering to enhance images in the frequency domain.
   - This project involves using homomorphic filtering to improve the quality of medical images by reducing noise and enhancing the contrast in both low and high-frequency components.

### **5. Noise Identification and Filtering**
   - **Goal**: Identifying and removing noise from corrupted images using custom filtering solutions.
   - This project focuses on detecting the type of noise in biomedical images (e.g., Gaussian, Salt and Pepper) and applying appropriate filtering techniques to improve image quality.

### **6. Blister Pack Analysis**
   - **Goal**: Automatically detecting how many pills have been used in a blister pack by analyzing an image of the blister.
   - This project detects the external contours of the blister, performs perspective warping to correct image inclination, and calculates the aspect ratio of the blister. It then identifies and separates the pills inside the blister using contour detection and image segmentation techniques.

---

## How to Use

Clone this repository and navigate through different projects by exploring their individual folders. Each project contains detailed explanations, instructions, and scripts to run the respective algorithms. For deep learning-based projects, ensure that the necessary hardware support (e.g., GPU for training deep models) are available.

---

## Tools & Libraries Used

- **OpenCV**: For general image processing and manipulation.
- **scikit-learn**: For predictive data analysis.
- **PyTorch**: For deep learning models and neural networks.
- **MATLAB**: For traditional image processing and prototyping.
- **NumPy / Pandas**: For data handling and analysis.

---

## License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
