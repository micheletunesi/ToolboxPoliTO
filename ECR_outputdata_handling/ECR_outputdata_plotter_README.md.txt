ECR_outputdata_plotter

Overview
ECR_outputdata_plotter.m is a MATLAB script for batch processing of .mat files containing current measurements. The script loads each dataset, computes an average over a predefined interval, and generates annotated plots for inspection and comparison.

The workflow is designed for consistent post-processing across multiple files stored in a single directory.

---

Input Requirements

Place all input files in:
./output_files

Each .mat file must include:
- time_select: Time vector
- current_select: Current vector with the same length as time_select

Files that do not satisfy these conditions are skipped during execution.

---

Processing Workflow

For each file, the script:
1. Loads the required variables
2. Verifies data consistency and validity
3. Selects a subset of samples for averaging
4. Computes the mean current over the selected subset
5. Generates a figure showing:
   - full signal
   - selection boundaries
   - samples used in the calculation
   - average value as a reference line
6. Saves the figure in multiple formats

---

Output Structure

The script creates the following directories if they do not exist:
./output_files/figures
./output_files/plots

Per-file outputs:
- PNG figure: ./output_files/figures/<filename>.png
- MATLAB figure: ./output_files/plots/<filename>.fig

Summary outputs:
- Summary plot across all processed files:
  ./output_files/figures/summary_average_current.png
  ./output_files/plots/summary_average_current.fig

- Results table printed in the MATLAB Command Window

Optional export of the results table to .mat and .csv is available in the script.

---

Results Table

The generated table includes:
- FileName
- AverageCurrent_35_55s
- ProcessedSuccessfully

---

Usage

1. Place ECR_outputdata_plotter.m in your working directory
2. Create the folder: output_files
3. Add .mat files with the required variables
4. Run in MATLAB:
   ECR_outputdata_plotter

---

Notes

- Files with missing variables, inconsistent dimensions, or empty data are not processed
- If no valid samples are available for averaging, the result is set to NaN
- Files are processed in alphabetical order

---

File

- ECR_outputdata_plotter.m
Main script for batch processing and visualization