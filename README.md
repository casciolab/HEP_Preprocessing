# 🧠💓 EEG Preprocessing Pipeline for Heartbeat-Evoked Potentials (HEP) Analysis

This repository documents the preprocessing pipeline applied to EEG data for **HEP (heartbeat-evoked potential)** analysis. The pipeline is designed to maximize signal quality while minimizing noise and physiological artifacts.

---

## ⚙️ Overview

Following EEG acquisition, the raw data undergoes a comprehensive 12-step preprocessing procedure. The goal is to retain only high-fidelity neural signals synchronized with cardiac events.

---

## 🔬 Preprocessing Steps

Each step was carefully chosen to prepare the data for robust HEP detection and analysis:

1. 📉 **Loading and Downsampling**  
   Load data and set the data sampling rate to 512hz to optimize processing without loss of relevant information.

2. 🫀 **Manual ECG Noise Rejection**  
   Visual inspection and manual exclusion of segments with excessive ECG or hardware noise.

3. 🎚 **Filtering**  
   Apply appropriate bandpass filters to isolate HEP-relevant frequency bands.

4. ⚡ **Zapline-plus Noise Removal**  
   Automatic removal of frequency-specific line noise using **Zapline-plus** [^1].

5. 🧼 **Artifact Subspace Reconstruction (ASR)**  
   Clean transient, high-amplitude artifacts using ASR to preserve valid EEG activity.

6. 📉 **Bad Channel Removal**  
   Identify and exclude consistently noisy or disconnected channels.

7. 🔌 **Re-referencing**  
   Re-reference the EEG signal (e.g., average or mastoid) to reduce spatial bias.

8. 💓 **R-Peak Detection with HEPLAB**  
   Detect heartbeat R-peaks using the **HEPLAB toolbox** [^2]. (Modified Toolbox to run automaticly across subjects)

9. 👁 **Visual Inspection and Correction of R-Peaks**  
   Manually verify and correct any inaccurate R-peak detections.

10. 🧠 **AMICA Decomposition & Eye Artifact Removal**  
    Apply **Adaptive Mixture ICA (AMICA)** [^3] to isolate and remove ocular and muscle artifacts.

11. ⏱ **Epoching**  
    Segment EEG into epochs time-locked to R-peaks for subsequent averaging and analysis.

12. 🧹 **Epoch Rejection (Statistical)**  
    Discard outlier epochs based on amplitude, variance, or statistical criteria.

---

## 📁 Outputs

- Cleaned and epoched EEG data ready for HEP analysis  
- ICA component maps and removed components log  
- Event markers for validated R-peaks

---

## 🛠 Tools Used

- MATLAB / EEGLAB  
- [Zapline-plus](https://github.com/MariusKlug/zapline-plus)  
- [HEPLAB](https://github.com/perakakis/HEPLAB) (modified version)
- [AMICA](https://github.com/sccn/amica) 
- Custom preprocessing scripts

---

## 🤝 Contributing

Pull requests are welcome! If you have improvements for preprocessing, visualization, or HEP analysis methods, feel free to contribute.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 📌 **How to Cite Us**

If you use this preprocessing pipeline in your research, please cite the repository as follows:

> Fraile, M., Salamone, P., Zoltowski, A., Quackenbush, W., Keceli-Kaysili, B., & Cascio, C. J. (2025). *HEP_Preprocessing: EEG Preprocessing Pipeline for Heartbeat-Evoked Potentials (HEP) Analysis*. https://github.com/casciolab/HEP_Preprocessing

---

## 📚 BibTeX

For LaTeX users:

```bibtex
@misc{fraile2025hep,
  author       = {Fraile-Vazquez, Matias E.; Salamone, Paula; Zoltowski, Alisa; Quackenbush, William; Keceli-Kaysili, Bahar; Cascio, Carissa J.},
  title        = {HEP_Preprocessing: EEG Preprocessing Pipeline for Heartbeat-Evoked Potentials (HEP) Analysis},
  year         = {2025},
  howpublished = {\url{https://github.com/casciolab/HEP_Preprocessing}},
  note         = {Version 1.0}
}
```
---

## 📚 References

[^1]: Klug, M., & Gramann, K. (2021). *Zapline-plus: A Zapline extension for automatic and adaptive removal of frequency-specific noise artifacts in EEG data*. [DOI / Link]

[^2]: Perakakis, P. (2022). *HEPLAB: An open-source MATLAB toolbox for heartbeat-evoked potential analysis*. Available at: [https://github.com/perakakis/HEPLAB](https://github.com/perakakis/HEPLAB)

[^3]: Palmer, J. A., Kreutz-Delgado, K., & Makeig, S. (2008). *AMICA: An adaptive mixture of independent component analyzers with shared components*. [DOI / Link]

