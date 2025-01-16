# Homomorphic Filtering Procedure

## Overview
In this exercise,  will be implemented the homomorphic filtering procedure and applied it to the image **h2_PET_image.tif**. The goal is to filter the image in the frequency domain and visualize the results alongside the original image.

### Formula for the Homomorphic Filter
The homomorphic filter is defined by the following formula:

\[
H(u, v) = A + \frac{B}{1 + \left(\frac{D(u,v)}{D_0}\right)^{C}}
\]

Where:
- \( A \), \( B \), and \( C \) are constants provided.
- \( D_0 \) is a constant related to the size of the image, defined as \( D_0 = \frac{\min(M, N)}{8} \), where \( M \) and \( N \) are the dimensions of the image.
- \( D(u, v) \) is the distance from the continuous frequency component.
- \( M \) and \( N \) are the image dimensions (width and height, in pixels).

---

## Contents of this Folder
- **h2_PET_image.tif**: Input image to be processed.
- **code.m**: MATLAB script implementing the homomorphic filtering procedure.
- **report.pdf**: Detailed report explaining the methodology, accompanied by visual examples of the filtering process and results.
