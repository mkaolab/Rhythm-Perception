Data
	Raw Data/All Birds/					Raw per-bird CSV files, one row per trial across all training and testing blocks
	Bird_Summary.xlsx					Subject metadata (name, species, sex, box, training order, DOB, success/include flags)
	AllData.csv						Cache of the fully processed trial-level dataframe; rebuilt automatically from the raw CSVs when missing or more than 12 hours old
	Jupyter Output/						Created automatically; receives all exported CSVs and figures listed below

Exported CSVs (written to Jupyter Output/)
	probe_stats_by_tempo.csv				Probe testing (first 80 probe trials per block), summarized by bird x block x tempo x trial type
	probe_stats.csv						Probe testing (first 80 probe trials per block), summarized by bird x block x trial type
	rt_probe.csv						Trial-level reaction times for probe blocks (first 80 probe trials)
	rule_training_stats_by_trial.csv			Trial-level rule training data for the ZF 75-275, BF 40-240, and BF 40-275 range blocks
	rule_training_by_gap_bin.csv				Rule training summarized per bird x 10 ms gap-duration bin
	rule_training_by_ioi_bin.csv				Rule training summarized per bird x 10 ms IOI bin
	trials_to_criterion.csv					Trials to criterion per bird x training sound (A/B/C)
	rt_last500.csv						Last 500 valid (non-NR) reaction times per bird x sound before probe testing
	tempo_discrim_last500.csv				Last 500 trials of tempo discrimination

Exported figures (written to Jupyter Output/)
	FigS3_ZF_combined / FigS3_BF_combined			Fig S3: learning curves per training-order group
	FigS2_BF_discrim_combined				Fig S2: tempo-discrimination learning curves
	FigS1_ZF_CV / FigS1_BF_CV				Fig S1: rule and probe IOI CV panels
	FigS1_ZF_V_RMS / FigS1_BF_V_RMS				Fig S1: rule and probe V_RMS panels
	FigS5_rule_CV_accuracy_binned_Nms			Fig S5: rule CV colored by accuracy, binned tempi
	FigS1_Tempo_CV_VRMS_Legend				Shared legend for the Fig S1 panels
	Fig2_legend						Legend for Fig 2A
	learning_curve_<subjects>				Per-bird learning curves, one row per bird

Stimuli (STIM_DIR)
	Rule_Training_40-275/					Rule-training stimuli (Stimulus Identification.txt, File Data/, Stim Files/)
	Training_Probe/						Probe stimuli (same folder structure)
	Tempo_Discrim/						Tempo discrimination stimuli

Code
	Bird_Data_Analysis.ipynb				Main analysis notebook: builds the raw trial-level dataframe, exports the CSVs above, and generates the figures above
								The exported CSVs are used by the R scripts below for further plotting and statistical analysis
	Fig1_trials_to_criterion.R				Figure 1C: trials to criterion for 12 male Bengalese finches and 19 male zebra finches
	Fig2_probe_FigS4_rt.R					Figure 2B: probe performance and GLMM; Figure S4: reaction-time plot and Wilcoxon rank-sum test
	Fig3_rule_training.R					Figure 3: rule-training performance by IOI and gap duration; first-bin comparison and the 30-160 ms gap GLMM
	FigS2_tempo_discrim_stats.R				Figure S2: one-sided binomial tests of tempo-discrimination performance against chance (alpha = 0.05)
	config.R						Input and output paths used by the R scripts
	fig_settings.R						Figure dimensions, font settings, and figure-saving function

Requirements
	Paths must be set up as: LOCAL_DIR contains Raw Data/All Birds/, Bird_Summary.xlsx, and AllData.csv; STIM_DIR contains Rule_Training_40-275/ and Training_Probe/
	Run all cells under "Definitions", then the "Initialization" cell to build the analysis object; set reimport=True after modifying the Raw Data/All Birds/ folder
	Python environment (versions used): pandas 2.2.3, numpy 1.26.4, scipy 1.13.1, matplotlib 3.9.2, openpyxl 3.1.5
