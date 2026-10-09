# Hybrid CNN–SOM for Alzheimer's Disease vs Cognitively Normal Classification (M.Sc. Thesis Code)

Code accompanying the M.Sc. dissertation by Terese Michael Chen.

This repository contains the pre-processing script and notebooks for a research prototype that classifies
structural brain MRI scans as Alzheimer's disease (AD) or cognitively normal (CN). It combines a
SimCLR-pre-trained ResNet50 encoder, three-view (axial, sagittal, coronal) late fusion, and a trainable
prototype layer (a 10×10 grid of prototypes, trained by backpropagation with a quantisation loss and no
neighbourhood function) that supports case-based explanations alongside Grad-CAM and LIME.

**This is a research prototype. It is not a clinical diagnostic tool and has not been validated for clinical use.**

## Pipeline (run in this order)

| Step | File | What it does |
|------|------|--------------|
| 1 | `FSL pre-processing.sh` | Skull stripping (BET), registration to MNI152 (FLIRT, affine) and z-score normalisation (FSL) |
| 2 | *(slice-extraction / data-preparation notebooks: list exact file names here)* | Extracts the three views and builds the train/validation/test folders |
| 3 | `SimCLR_MultiView_FeatureLearning.ipynb` | Self-supervised pre-training of the encoder and the multi-view fusion baseline |
| 4 | `Final_Hybrid_CNN_SOM_AD_Classification.ipynb` | Trains and evaluates the hybrid CNN–SOM model; thresholds, ROC, U-Matrix, Grad-CAM, LIME, case-based explanations, Gradio demo |
| 5 | `Cross-Dataset_Test.ipynb` | Evaluates the trained model on a 200-image sample from a public Kaggle MRI dataset |


## Key settings

- Task: binary AD vs CN, subject-level 80:10:10 split
- Input: three 224×224 views per scan (axial, sagittal, coronal)
- Prototype layer: 10×10 prototypes, quantisation loss weight 0.01, no neighbourhood function
- Training: Adam (1e-4), class weights AD 2.0 : CN 1.0, 20 epochs, batch size 16
- Decision threshold: 0.10 on the AD probability (a manually chosen operating point, not tuned on the test set);
  a validation-selected alternative (Youden's J) is also reported in the main notebook

## Setup

```bash
pip install -r requirements.txt
```

The notebooks were written for Google Colab and use Google Drive paths such as `/content/drive/MyDrive/...`.
Change these paths to match your own environment before running. FSL must be installed separately for step 1.

## Data

No data is included in this repository.

- ADNI MRI data must be requested from the Alzheimer's Disease Neuroimaging Initiative (https://adni.loni.usc.edu).
- The external test used a public Kaggle brain MRI dataset (images were only resized; they did not go through the FSL pipeline).

## Not included

The three-class (AD/MCI/CN) experiment reported in the dissertation is *(not included in this repository / found in: add file name)*.
Trained model files (`.h5`) are not included. Results will differ slightly between runs and environments.

## Citation

If you use this code, please cite the dissertation: Chen, T. M. (2026). An Interpretable Hybrid CNN–SOM Framework for Alzheimer’s Disease Classification Using Structural MRI. M.Sc. dissertation, Department of Computer Science, Faculty of Computing, University of Jos, Nigeria
