# Blister Pack Analysis

---

## Overview
In this exercise, the goal is to analyze an image of a pill blister, provided in the file **blister.jpg**, to automatically detect how many pills have been used. The exercise is divided into two main objectives:

1. **Detecting the external contours of the blister and computing its aspect ratio.**
2. **Identifying and separating the pills still in the blister from the missing ones.**

The steps involved in this exercise are as follows:
1. **External Contours Detection**: Using edge detection and contour extraction methods to detect the shape of the blister.
2. **Warping the Image**: The image was initially not taken perpendicular to the blister, causing an inclination. Therefore, warping was performed to correct the perspective and align the image properly.
3. **Aspect Ratio Calculation**: After detecting the external contours and correcting the image orientation, the aspect ratio (width/height) of the blister is computed.
4. **Pill Detection**: Analyzing the blister's interior to detect which pills remain, using techniques like thresholding and contour detection to separate used and unused pills.

---

## Preview of Input Image  

<center>
  <img src="blister.jpg" alt="Plasma Cells" width="300">
</center>
