# 🧠💓 EEG Preprocessing Pipeline for Heartbeat-Evoked Potentials (HEP) Analysis

This repository documents the preprocessing pipeline applied to EEG data for **HEP (heartbeat-evoked potential)** analysis. The pipeline is designed to maximize signal quality while minimizing noise and physiological artifacts.

---

## ⚙️ Overview

Following EEG acquisition, the raw data undergoes a comprehensive 12-step preprocessing procedure. The goal is to retain only high-fidelity neural signals synchronized with cardiac events.

---

## 🔬 Preprocessing Steps

Each step was carefully chosen to prepare the data for robust HEP detection and analysis:

1. 📉 **Downsampling**  
   Reduce the data sampling rate to optimize processing without loss of relevant information.

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

## 📚 References

[^1]: Klug, M., & Gramann, K. (2021). *Zapline-plus: A Zapline extension for automatic and adaptive removal of frequency-specific noise artifacts in EEG data*. [DOI / Link]

[^2]: Perakakis, P. (2022). *HEPLAB: An open-source MATLAB toolbox for heartbeat-evoked potential analysis*. Available at: [https://github.com/perakakis/HEPLAB](https://github.com/perakakis/HEPLAB)

[^3]: Palmer, J. A., Kreutz-Delgado, K., & Makeig, S. (2008). *AMICA: An adaptive mixture of independent component analyzers with shared components*. [DOI / Link]

---

## 🛠 Tools Used

- MATLAB / EEGLAB  
- [Zapline-plus](https://github.com/methlabUZH/zapline-plus)  
- [HEPLAB](https://github.com/perakakis/HEPLAB)  
- [AMICA](https://sccn.ucsd.edu/~jason/amicaweb.html)  
- Custom preprocessing scripts

---

## 🤝 Contributing

Pull requests are welcome! If you have improvements for preprocessing, visualization, or HEP analysis methods, feel free to contribute.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
