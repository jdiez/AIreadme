# AI‑Derived H&E Biomarkers Predict Differential Survival Under Immunotherapy vs Chemotherapy in phase-3 metastatic NSCLC study NEPTUNE

## Authors

**Chintan Parmar¹**, **Vladimir Roudko¹**, **Victoria Muckerson¹**, **Jorge Blando²**, **Jennifer Daniel²**, **Javier Díez³**, **Sreeharsha Gunda⁴**, **Alvaro Mendoza Alcala⁵**, **Alex Franco⁵**, **Ivan Stambolic⁶**, **Cristina Benchea⁵**, **Ross Stewart⁷**, **Zhongwu Lai⁸**, **Jorge Reis-Filho⁹**, **Maurizio Scaltriti²**, **Douglas Palmer²**

### Affiliations

1. Translational Medicine, Astrazeneca, Waltham, US
2. Translational Medicine, Astrazeneca, Gaithersburg, US
3. Oncology Data Science AI, Astrazeneca, Barcelona, ES
4. R&D IT, Astrazeneca, Chennai, IN
5. Biopharmaceuticals, Astrazeneca, Barcelona, ES
6. Oncology Data Science AI, Astrazeneca, Munich DE
7. Translational Medicine, Astrazeneca, Cambridge, UK
8. Oncology Data Science AI, Astrazeneca, Waltham, US
9. Oncology Data Science AI, Astrazeneca, Gaithersburg US

---

## Background

Immunotherapy outcomes in metastatic NSCLC are variable, and existing biomarkers (PD‑L1, TMB) incompletely predict benefit. Routine H&E slides are widely available and capture spatial tumor microenvironment (TME) context. We applied AI‑Pathology to convert H&Es into quantitative, interpretable TME features and assessed whether they predict survival benefit with immunotherapy (IO) versus chemotherapy.

## Methods

We conducted a retrospective analysis of H&E slides from NEPTUNE (a phase 3, study in metastatic NSCLC comparing durvalumab+tremelimumab (D+T) vs chemotherapy (CTX)). Slides from **426 patients** (D+T n=154; CTX n=272) were processed using models trained independently on external, non‑NEPTUNE datasets (>6,000 pathologist‑annotated H&Es). **Fifteen features** (immune, cancer, fibroblast densities/ratios) were extracted in cancer‑associated stroma and cancer regions. Overall survival (OS) was analyzed by fitting univariate Coxph regression models with Benjamini–Hochberg FDR control. Treatment × marker interaction terms evaluated predictiveness. Routinely used markers followed cutoffs (PD‑L1 ≤25%; bTMB ≤20 mut/Mb) as described in the NEPTUNE study (de Castro Jr G et al., J Thorac Oncol, 2023;18:106–119).

## Results

**Higher stromal fibroblast density** was associated with inferior OS in both arms (D+T HR=1.60 [1.14–2.25]; CTX HR=1.36 [1.05–1.76]) with no treatment interaction (nominal p_interaction=0.82), indicating a **prognostic effect**. 

**Higher stromal immune density** was associated with improved benefit for D+T (HR=0.64 [0.45–0.90]; **median OS difference +5.8 months**; FDR p=0.04) but not CTX (HR=0.84 [0.65–1.08], FDR p=0.38), with a significant treatment interaction (nominal p_interaction=0.03), supporting a **predictive effect**. 

Overall, **AI‑H&E features showed comparable or stronger stratification** of D+T outcomes than established routine markers in this dataset, including:
- **PD‑L1** (HR=0.67 [0.46–0.96], FDR p=0.08)
- **bTMB** (HR=0.78 [0.48–1.26], FDR p=0.45)  
- **ECOG** (HR=0.74 [0.52–1.07], FDR p=0.19)

## Conclusions

NEPTUNE did not meet its primary endpoint. The observed **prognostic fibroblast signal** and **predictive immune signal** from AI‑derived H&E features suggest the potential for enriched selection or stratification to improve detection of checkpoint blockade benefit. These **assay‑free, interpretable biomarkers** warrant prospective validation for clinical application.