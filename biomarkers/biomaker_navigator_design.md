# Comprehensive Table and Column Specifications

## Table of Contents

1. [Reference and Metadata Tables](#reference-and-metadata-tables)
2. [Biomarker and Assay Tables](#biomarker-and-assay-tables)
3. [Aggregated Measurements Tables](#aggregated-measurements-tables)
4. [Statistical Associations Tables](#statistical-associations-tables)
5. [Classification Tables](#classification-tables)
6. [Validation and Meta-Analysis Tables](#validation-and-meta-analysis-tables)
7. [Audit and Governance Tables](#audit-and-governance-tables)

---

## Reference and Metadata Tables

### clinical_trials

**Purpose**: Central registry of clinical trials providing foundational context for all biomarker data. This table serves as the top-level organizational unit for the entire database.

**Business Context**: Each clinical trial represents a distinct research study with specific protocols, patient populations, and objectives. This table enables cross-trial comparisons, meta-analyses, and tracking of biomarker performance across different study contexts.

**Data Sources**: ClinicalTrials.gov, internal trial registries, published literature, regulatory submissions.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| trial_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for the clinical trial, typically using standardized registry numbers | 'NCT04567890', 'KEYNOTE-001', 'CHECKMATE-067' | Must be unique across database; prefer NCT numbers when available |
| trial_name | VARCHAR(255) | NOT NULL | Full official name or commonly used acronym for the trial | 'A Phase III Study of Pembrolizumab vs Chemotherapy', 'KEYNOTE-024' | Should match official trial registration |
| trial_phase | VARCHAR(20) | NULL | Clinical development phase of the trial | 'Phase I', 'Phase II', 'Phase III', 'Phase IV', 'Phase I/II' | Use standard phase nomenclature; NULL for observational studies |
| sponsor | VARCHAR(255) | NULL | Organization or company sponsoring the trial | 'AstraZeneca', 'Merck & Co.', 'National Cancer Institute' | Primary sponsor only; collaborators in description |
| indication | VARCHAR(255) | NULL | Primary disease or condition being studied | 'Non-Small Cell Lung Cancer', 'Metastatic Melanoma', 'Triple-Negative Breast Cancer' | Use standardized disease terminology (MedDRA, ICD-10) |
| therapeutic_area | VARCHAR(255) | NULL | Broader therapeutic classification | 'Oncology', 'Immunology', 'Cardiovascular', 'Neurology' | Consistent categorization for filtering and reporting |
| start_date | DATE | NULL | Date when trial enrollment began | '2018-03-15', '2020-01-01' | Actual start date, not planned; NULL if unknown |
| end_date | DATE | NULL | Date when trial was completed or terminated | '2022-06-30', '2023-12-31' | Primary completion date; NULL for ongoing trials |
| protocol_version | VARCHAR(50) | NULL | Version number of the trial protocol | 'v1.0', 'v2.3', 'Amendment 5' | Track protocol amendments that may affect biomarker collection |
| total_enrolled | INT | NULL, CHECK (total_enrolled >= 0) | Total number of patients enrolled in the trial | 150, 500, 1200 | Should match sum of all cohort sample sizes; NULL if not available |
| description | TEXT | NULL | Detailed description of trial objectives, design, and key features | 'A randomized, double-blind study comparing...' | Free text for additional context; include key eligibility criteria |
| publication_references | TEXT | NULL | Citations or DOIs for key publications from this trial | 'PMID: 12345678; DOI: 10.1056/NEJMoa...', 'N Engl J Med 2021;384:1234-45' | Semicolon-separated list of references |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created in database | '2024-01-15 14:30:22' | System-generated; immutable |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Timestamp when record was last modified | '2024-06-20 09:15:33' | System-generated; auto-updates |

**Indexes**:
- PRIMARY KEY on `trial_id`
- INDEX on `indication` for disease-specific queries
- INDEX on `therapeutic_area` for broad categorization
- FULLTEXT INDEX on `trial_name`, `indication`, `description` for search functionality

**Relationships**:
- **Parent to**: `treatment_arms`, `patient_cohorts`, `assay_datasets`, `cross_trial_validations`
- **Cardinality**: One trial to many arms/cohorts/datasets

**Data Quality Checks**:
- `trial_id` must be unique and non-null
- `start_date` should be before `end_date` if both present
- `total_enrolled` should approximately match sum of cohort sizes
- At least one of `trial_name` or `trial_id` should be meaningful

**Usage Examples**:
```sql
-- Find all oncology trials with biomarker data
SELECT * FROM clinical_trials 
WHERE therapeutic_area = 'Oncology' 
AND trial_id IN (SELECT DISTINCT trial_id FROM assay_datasets);

-- Get trial timeline
SELECT trial_name, start_date, end_date, 
       DATEDIFF(end_date, start_date) AS duration_days
FROM clinical_trials
WHERE end_date IS NOT NULL;
```

---

### treatment_arms

**Purpose**: Defines distinct treatment groups within clinical trials, enabling treatment-stratified biomarker analyses and comparative effectiveness assessments.

**Business Context**: Most clinical trials include multiple treatment arms (e.g., experimental drug vs. standard of care vs. placebo). Biomarker performance may vary by treatment, making arm-level tracking essential for predictive biomarker development.

**Data Sources**: Trial protocols, statistical analysis plans, clinical study reports.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| arm_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for the treatment arm | 'NCT04567890_ARM_A', 'KEYNOTE001_PEMBRO', 'CHECKMATE067_COMBO' | Combine trial_id with arm designation for uniqueness |
| trial_id | VARCHAR(50) | FOREIGN KEY (clinical_trials.trial_id), NOT NULL | Links to parent clinical trial | 'NCT04567890', 'KEYNOTE-001' | Must exist in clinical_trials table |
| arm_name | VARCHAR(255) | NOT NULL | Descriptive name for the treatment arm | 'Pembrolizumab 200mg Q3W', 'Standard of Care Chemotherapy', 'Placebo' | Use protocol-specified arm names |
| arm_type | VARCHAR(50) | NULL | Classification of arm purpose | 'experimental', 'control', 'placebo', 'active_comparator', 'standard_of_care' | Standardized vocabulary for arm types |
| treatment_description | TEXT | NULL | Detailed description of treatment regimen | 'Pembrolizumab 200mg IV every 3 weeks until progression or unacceptable toxicity' | Include dosing, schedule, duration, combination details |
| dose_regimen | VARCHAR(255) | NULL | Concise dosing information | '200mg Q3W', '75mg/m² D1 Q21D', '2mg/kg weekly' | Standardized format for dose and frequency |
| sample_size | INT | NULL, CHECK (sample_size >= 0) | Number of patients randomized to this arm | 150, 300, 75 | Should match sum of cohorts within this arm |

**Indexes**:
- PRIMARY KEY on `arm_id`
- FOREIGN KEY INDEX on `trial_id`
- INDEX on `arm_type` for filtering by arm category

**Relationships**:
- **Child of**: `clinical_trials` (many arms to one trial)
- **Parent to**: `patient_cohorts` (one arm to many cohorts if further stratified)
- **Cardinality**: Typically 2-4 arms per trial

**Data Quality Checks**:
- Each `trial_id` should have at least one arm
- `sample_size` should sum to approximately `total_enrolled` in parent trial
- `arm_type` should use controlled vocabulary
- At least one arm per trial should be 'experimental'

**Usage Examples**:
```sql
-- Compare sample sizes across arms within a trial
SELECT t.trial_name, ta.arm_name, ta.sample_size,
       ROUND(100.0 * ta.sample_size / t.total_enrolled, 1) AS percent_of_total
FROM treatment_arms ta
JOIN clinical_trials t ON ta.trial_id = t.trial_id
WHERE t.trial_id = 'NCT04567890'
ORDER BY ta.sample_size DESC;

-- Find all experimental arms across oncology trials
SELECT t.trial_name, ta.arm_name, ta.treatment_description
FROM treatment_arms ta
JOIN clinical_trials t ON ta.trial_id = t.trial_id
WHERE ta.arm_type = 'experimental'
AND t.therapeutic_area = 'Oncology';
```

---

### patient_cohorts

**Purpose**: Defines patient subgroups within trials for stratified analyses, representing aggregated patient populations without individual-level data. This is the primary organizational unit for all biomarker measurements and classifications.

**Business Context**: Clinical trials often stratify patients by baseline characteristics (disease stage, biomarker status, demographics) for subgroup analyses. This table enables biomarker evaluation within clinically relevant patient segments while maintaining privacy through aggregation.

**Data Sources**: Trial databases, statistical analysis plans, clinical study reports, published subgroup analyses.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| cohort_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for the patient cohort | 'NCT04567890_PDL1_HIGH', 'KEYNOTE001_NSCLC_1L', 'CHECKMATE067_STAGE4' | Descriptive ID combining trial and stratification |
| trial_id | VARCHAR(50) | FOREIGN KEY (clinical_trials.trial_id), NOT NULL | Links to parent clinical trial | 'NCT04567890', 'KEYNOTE-001' | Must exist in clinical_trials table |
| arm_id | VARCHAR(50) | FOREIGN KEY (treatment_arms.arm_id), NULL | Links to specific treatment arm if cohort is arm-specific | 'NCT04567890_ARM_A', NULL | NULL if cohort spans multiple arms |
| cohort_name | VARCHAR(255) | NOT NULL | Descriptive name for the cohort | 'PD-L1 ≥50% Population', 'First-Line NSCLC', 'Stage IV Melanoma' | Clear, clinically meaningful description |
| cohort_description | TEXT | NULL | Detailed description of cohort definition and characteristics | 'Patients with non-small cell lung cancer, PD-L1 tumor proportion score ≥50%, no prior systemic therapy' | Include all key inclusion/exclusion criteria |
| stratification_criteria | TEXT | NULL | Specific criteria used to define this cohort | 'PD-L1 TPS ≥50%; ECOG PS 0-1; Stage IIIB/IV; No prior therapy', 'Biomarker: TMB ≥10 mut/Mb' | Structured list of stratification variables |
| sample_size | INT | NULL, CHECK (sample_size >= 0) | Number of patients in this cohort | 150, 75, 300 | Minimum recommended: 10 for privacy; 30 for statistical validity |
| mean_age | DECIMAL(5,2) | NULL, CHECK (mean_age >= 0 AND mean_age <= 120) | Mean age of patients in cohort (years) | 62.5, 58.3, 71.2 | Aggregated statistic only; no individual ages |
| age_std_dev | DECIMAL(5,2) | NULL, CHECK (age_std_dev >= 0) | Standard deviation of age | 8.5, 12.3, 6.7 | Measure of age variability within cohort |
| age_range | VARCHAR(50) | NULL | Age range in cohort | '45-78', '18-85', '≥65' | Min-max or categorical age grouping |
| percent_female | DECIMAL(5,2) | NULL, CHECK (percent_female >= 0 AND percent_female <= 100) | Percentage of female patients | 45.5, 62.0, 38.7 | Aggregated gender distribution |
| disease_stage_distribution | JSON | NULL | Distribution of disease stages within cohort | `{"Stage III": 0.25, "Stage IV": 0.75}` | JSON object with stage categories as keys, proportions as values |
| baseline_characteristics | JSON | NULL | Additional baseline clinical and demographic characteristics | `{"ECOG_0": 0.40, "ECOG_1": 0.60, "median_tumor_size_mm": 45}` | Flexible JSON structure for cohort-specific variables |

**Indexes**:
- PRIMARY KEY on `cohort_id`
- FOREIGN KEY INDEX on `trial_id`
- FOREIGN KEY INDEX on `arm_id`
- COMPOSITE INDEX on (`trial_id`, `cohort_id`) for trial-specific queries
- INDEX on `sample_size` for filtering by cohort size

**Relationships**:
- **Child of**: `clinical_trials`, `treatment_arms`
- **Parent to**: `cohort_endpoints`, `cohort_biomarker_summary`, `biomarker_correlations`, `biomarker_endpoint_associations`, `cohort_classifications`
- **Cardinality**: Many cohorts per trial (typically 2-20 depending on stratification)

**Data Quality Checks**:
- `sample_size` should be ≥10 for privacy (recommended ≥30 for statistical validity)
- `mean_age` and `percent_female` should be consistent with trial population
- Sum of cohort sizes within a trial should approximately equal trial `total_enrolled`
- `disease_stage_distribution` proportions should sum to 1.0
- JSON fields should be valid JSON format

**Usage Examples**:
```sql
-- Find large cohorts with high female representation
SELECT c.cohort_name, t.trial_name, c.sample_size, c.percent_female
FROM patient_cohorts c
JOIN clinical_trials t ON c.trial_id = t.trial_id
WHERE c.sample_size >= 100
AND c.percent_female >= 50
ORDER BY c.percent_female DESC;

-- Get cohort demographics summary
SELECT 
    cohort_name,
    sample_size,
    mean_age,
    age_std_dev,
    percent_female,
    JSON_EXTRACT(disease_stage_distribution, '$.\"Stage IV\"') AS stage_iv_proportion
FROM patient_cohorts
WHERE trial_id = 'NCT04567890';

-- Find biomarker-stratified cohorts
SELECT cohort_name, stratification_criteria, sample_size
FROM patient_cohorts
WHERE stratification_criteria LIKE '%PD-L1%'
OR stratification_criteria LIKE '%TMB%'
ORDER BY sample_size DESC;
```

---

### endpoints

**Purpose**: Standardized catalog of clinical endpoints (outcomes) measured across trials, enabling consistent endpoint definitions and cross-trial comparisons.

**Business Context**: Clinical trials measure various efficacy and safety outcomes. Standardizing endpoint definitions is critical for biomarker-endpoint association analyses and meta-analyses. This table serves as the reference for all outcome measurements.

**Data Sources**: FDA guidance documents, ICH guidelines, trial protocols, endpoint adjudication charters.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| endpoint_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for the endpoint | 'OS', 'PFS', 'ORR', 'AE_GRADE3_PLUS', 'DOR' | Use standard abbreviations when available |
| endpoint_name | VARCHAR(255) | NOT NULL | Full descriptive name of the endpoint | 'Overall Survival', 'Progression-Free Survival', 'Objective Response Rate', 'Grade 3+ Adverse Events' | Use standardized nomenclature (FDA, RECIST, CTCAE) |
| endpoint_type | VARCHAR(50) | NOT NULL | Classification of endpoint purpose | 'efficacy', 'safety', 'surrogate', 'composite', 'exploratory', 'pharmacodynamic' | Controlled vocabulary for endpoint categorization |
| endpoint_category | VARCHAR(100) | NULL | Specific endpoint category within type | 'OS', 'PFS', 'ORR', 'DOR', 'AE', 'QoL', 'biomarker_response', 'PRO' | More granular classification than endpoint_type |
| description | TEXT | NULL | Detailed definition of endpoint including measurement criteria | 'Time from randomization to death from any cause', 'Proportion of patients with complete or partial response per RECIST v1.1' | Include assessment criteria, timing, adjudication process |
| measurement_unit | VARCHAR(50) | NULL | Unit of measurement for continuous endpoints | 'months', 'days', 'percent', 'mg/dL', 'score' | NULL for binary/categorical endpoints |
| is_primary | BOOLEAN | DEFAULT FALSE | Indicates if this is a primary endpoint in any trial | TRUE, FALSE | TRUE if used as primary in at least one trial |
| assessment_timepoint | VARCHAR(100) | NULL | Typical timing of endpoint assessment | 'Every 6 weeks', 'Week 12', 'End of treatment', 'Continuous monitoring' | General guidance; specific timing in cohort_endpoints |

**Indexes**:
- PRIMARY KEY on `endpoint_id`
- INDEX on `endpoint_type` for filtering by endpoint category
- INDEX on `endpoint_category` for specific endpoint queries
- INDEX on `is_primary` for primary endpoint analyses
- FULLTEXT INDEX on `endpoint_name`, `description` for search

**Relationships**:
- **Parent to**: `cohort_endpoints`, `biomarker_endpoint_associations`, `biomarker_thresholds`, `cohort_classifications`, `meta_analysis_results`
- **Cardinality**: Typically 50-200 distinct endpoints across database

**Data Quality Checks**:
- `endpoint_id` should use standard abbreviations (OS, PFS, ORR, etc.)
- `endpoint_type` should use controlled vocabulary
- `description` should be detailed enough for unambiguous interpretation
- Time-to-event endpoints should have `measurement_unit` of 'months' or 'days'
- Binary endpoints (response, progression) should have NULL `measurement_unit`

**Usage Examples**:
```sql
-- Find all efficacy endpoints
SELECT endpoint_id, endpoint_name, endpoint_category, description
FROM endpoints
WHERE endpoint_type = 'efficacy'
ORDER BY endpoint_name;

-- Get primary endpoints used across trials
SELECT e.endpoint_name, COUNT(DISTINCT ce.cohort_id) AS num_cohorts
FROM endpoints e
JOIN cohort_endpoints ce ON e.endpoint_id = ce.endpoint_id
WHERE e.is_primary = TRUE
GROUP BY e.endpoint_name
ORDER BY num_cohorts DESC;

-- Find survival endpoints
SELECT * FROM endpoints
WHERE endpoint_category IN ('OS', 'PFS', 'DOR')
OR endpoint_name LIKE '%survival%';
```

---

### cohort_endpoints

**Purpose**: Stores aggregated clinical endpoint outcomes for each patient cohort, providing the ground truth data for validating biomarker classifications and assessing clinical utility.

**Business Context**: This table captures actual clinical outcomes that biomarkers aim to predict. It enables calculation of biomarker sensitivity, specificity, and clinical utility by comparing predicted vs. actual outcomes.

**Data Sources**: Clinical study reports, statistical analysis plans, published trial results, regulatory submissions.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| cohort_endpoint_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this cohort-endpoint record | 1, 2, 3, ... | System-generated sequential ID |
| cohort_id | VARCHAR(50) | FOREIGN KEY (patient_cohorts.cohort_id), NOT NULL | Links to patient cohort | 'NCT04567890_PDL1_HIGH' | Must exist in patient_cohorts table |
| endpoint_id | VARCHAR(50) | FOREIGN KEY (endpoints.endpoint_id), NOT NULL | Links to endpoint definition | 'OS', 'PFS', 'ORR' | Must exist in endpoints table |
| assessment_timepoint | VARCHAR(100) | NULL | Specific timepoint when endpoint was assessed | 'Week 12', 'Month 24', 'Primary analysis cutoff', 'Final analysis' | Trial-specific assessment timing |
| days_from_baseline | INT | NULL, CHECK (days_from_baseline >= 0) | Number of days from baseline to assessment | 84, 180, 730 | Enables time-based analyses |
| n_evaluated | INT | NULL, CHECK (n_evaluated >= 0) | Number of patients evaluated for this endpoint | 150, 145, 138 | May be less than cohort size due to dropout |
| n_positive | INT | NULL, CHECK (n_positive >= 0) | Number of patients with positive outcome | 60, 45, 30 | Definition of "positive" is endpoint-specific |
| n_negative | INT | NULL, CHECK (n_negative >= 0) | Number of patients with negative outcome | 90, 100, 108 | Complement of n_positive for binary endpoints |
| response_rate | DECIMAL(5,4) | NULL, CHECK (response_rate >= 0 AND response_rate <= 1) | Proportion of patients with positive outcome | 0.4000, 0.3103, 0.2174 | n_positive / n_evaluated |
| response_rate_ci_lower | DECIMAL(5,4) | NULL, CHECK (response_rate_ci_lower >= 0 AND response_rate_ci_lower <= 1) | Lower bound of 95% confidence interval for response rate | 0.3200, 0.2450, 0.1580 | Typically 95% CI; specify method in notes |
| response_rate_ci_upper | DECIMAL(5,4) | NULL, CHECK (response_rate_ci_upper >= 0 AND response_rate_ci_upper <= 1) | Upper bound of 95% confidence interval for response rate | 0.4800, 0.3756, 0.2768 | Should be > response_rate_ci_lower |
| median_value | DECIMAL(15,6) | NULL | Median value for continuous endpoints | 18.5, 12.3, 24.7 | For time-to-event or continuous outcomes |
| mean_value | DECIMAL(15,6) | NULL | Mean value for continuous endpoints | 20.3, 14.8, 26.2 | May be skewed for survival endpoints |
| std_dev | DECIMAL(15,6) | NULL, CHECK (std_dev >= 0) | Standard deviation for continuous endpoints | 8.5, 6.2, 10.3 | Measure of variability |
| min_value | DECIMAL(15,6) | NULL | Minimum observed value | 2.1, 0.5, 5.0 | Range minimum |
| max_value | DECIMAL(15,6) | NULL | Maximum observed value | 48.5, 36.2, 60.0 | Range maximum; may be censored for survival |
| quartile_25 | DECIMAL(15,6) | NULL | 25th percentile (Q1) | 12.5, 8.3, 15.0 | First quartile |
| quartile_75 | DECIMAL(15,6) | NULL | 75th percentile (Q3) | 28.5, 20.1, 35.0 | Third quartile |
| hazard_ratio | DECIMAL(10,6) | NULL, CHECK (hazard_ratio > 0) | Hazard ratio for time-to-event endpoints | 0.6500, 0.7800, 1.2500 | Relative to reference group; <1 favors experimental |
| hazard_ratio_ci_lower | DECIMAL(10,6) | NULL, CHECK (hazard_ratio_ci_lower > 0) | Lower bound of 95% CI for hazard ratio | 0.5200, 0.6100, 0.9800 | Typically 95% CI |
| hazard_ratio_ci_upper | DECIMAL(10,6) | NULL, CHECK (hazard_ratio_ci_upper > 0) | Upper bound of 95% CI for hazard ratio | 0.8100, 0.9900, 1.5900 | Should be > hazard_ratio_ci_lower |
| p_value | DECIMAL(10,8) | NULL, CHECK (p_value >= 0 AND p_value <= 1) | Statistical significance of outcome | 0.00123456, 0.04500000, 0.15000000 | From appropriate statistical test |
| statistical_test | VARCHAR(100) | NULL | Statistical test used to calculate p_value | 'Log-rank test', 'Chi-square test', 'Cox proportional hazards', 'Kaplan-Meier' | Document test methodology |
| notes | TEXT | NULL | Additional context, caveats, or methodological details | 'Censored at 36 months', 'Intent-to-treat population', 'Per-protocol analysis' | Free text for important details |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `cohort_endpoint_id`
- FOREIGN KEY INDEX on `cohort_id`
- FOREIGN KEY INDEX on `endpoint_id`
- COMPOSITE INDEX on (`cohort_id`, `endpoint_id`) for cohort-specific endpoint queries
- INDEX on `assessment_timepoint` for time-based analyses

**Relationships**:
- **Child of**: `patient_cohorts`, `endpoints`
- **Used by**: `classification_performance_by_status` for validation

**Data Quality Checks**:
- `n_positive + n_negative` should equal `n_evaluated` for binary endpoints
- `n_evaluated` should be ≤ cohort `sample_size`
- `response_rate` should equal `n_positive / n_evaluated`
- `response_rate_ci_lower < response_rate < response_rate_ci_upper`
- `hazard_ratio_ci_lower < hazard_ratio < hazard_ratio_ci_upper`
- For survival endpoints, `median_value` should be present
- `p_value` should be present if comparing groups

**Usage Examples**:
```sql
-- Get response rates across cohorts for a specific endpoint
SELECT 
    pc.cohort_name,
    ce.n_evaluated,
    ce.response_rate,
    ce.response_rate_ci_lower,
    ce.response_rate_ci_upper,
    ce.p_value
FROM cohort_endpoints ce
JOIN patient_cohorts pc ON ce.cohort_id = pc.cohort_id
WHERE ce.endpoint_id = 'ORR'
ORDER BY ce.response_rate DESC;

-- Compare survival outcomes across treatment arms
SELECT 
    ta.arm_name,
    ce.median_value AS median_os_months,
    ce.hazard_ratio,
    ce.hazard_ratio_ci_lower,
    ce.hazard_ratio_ci_upper,
    ce.p_value
FROM cohort_endpoints ce
JOIN patient_cohorts pc ON ce.cohort_id = pc.cohort_id
JOIN treatment_arms ta ON pc.arm_id = ta.arm_id
WHERE ce.endpoint_id = 'OS'
AND pc.trial_id = 'NCT04567890';

-- Find endpoints with significant results
SELECT 
    e.endpoint_name,
    pc.cohort_name,
    ce.response_rate,
    ce.p_value
FROM cohort_endpoints ce
JOIN endpoints e ON ce.endpoint_id = e.endpoint_id
JOIN patient_cohorts pc ON ce.cohort_id = pc.cohort_id
WHERE ce.p_value < 0.05
ORDER BY ce.p_value;
```

---

## Biomarker and Assay Tables

### biomarkers

**Purpose**: Comprehensive catalog of all biomarkers measured across trials, serving as the central reference for molecular, cellular, and imaging markers. This table standardizes biomarker nomenclature and provides biological context.

**Business Context**: Biomarkers span diverse molecular types (genes, proteins, metabolites) and measurement modalities. Standardized biomarker definitions enable cross-trial comparisons, pathway analyses, and integration with external databases.

**Data Sources**: HUGO Gene Nomenclature Committee, UniProt, Ensembl, HMDB, published literature, assay specifications.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| biomarker_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for the biomarker | 'PD_L1', 'TMB', 'EGFR_MUTATION', 'IL6_PROTEIN', 'GLUCOSE_METABOLITE' | Use standardized nomenclature; underscores for spaces |
| biomarker_name | VARCHAR(255) | NOT NULL | Full descriptive name of the biomarker | 'Programmed Death-Ligand 1', 'Tumor Mutational Burden', 'Epidermal Growth Factor Receptor Mutation' | Official name from authoritative source |
| biomarker_type | VARCHAR(50) | NOT NULL | High-level classification of biomarker modality | 'genomic', 'proteomic', 'metabolomic', 'imaging', 'cellular', 'transcriptomic' | Controlled vocabulary for biomarker types |
| measurement_category | VARCHAR(100) | NULL | Specific measurement type within biomarker_type | 'gene_expression', 'mutation', 'copy_number', 'protein_level', 'metabolite_concentration', 'cell_count', 'radiomics' | More granular than biomarker_type |
| gene_symbol | VARCHAR(50) | NULL | Official gene symbol (HGNC) | 'CD274', 'EGFR', 'KRAS', 'TP53', 'BRCA1' | Use HUGO Gene Nomenclature Committee symbols |
| protein_name | VARCHAR(255) | NULL | Protein name if biomarker is protein-based | 'Programmed cell death 1 ligand 1', 'Epidermal growth factor receptor', 'Interleukin-6' | Use UniProt recommended name |
| uniprot_id | VARCHAR(50) | NULL | UniProt accession number for proteins | 'Q9NZQ7', 'P00533', 'P05231' | Links to UniProt database |
| ensembl_id | VARCHAR(50) | NULL | Ensembl gene ID | 'ENSG00000120217', 'ENSG00000146648', 'ENSG00000133703' | Links to Ensembl database |
| chromosome | VARCHAR(10) | NULL | Chromosomal location | '9', '7', '12', 'X', 'MT' | Human chromosome designation |
| genomic_position | VARCHAR(100) | NULL | Genomic coordinates | 'chr9:5450503-5470566', '7:55019017-55211628' | Genome build should be specified in notes |
| pathway | VARCHAR(255) | NULL | Primary biological pathway | 'Immune checkpoint', 'EGFR signaling', 'DNA damage response', 'Glycolysis' | Use pathway databases (KEGG, Reactome, GO) |
| biological_function | TEXT | NULL | Description of biological role and mechanism | 'Inhibits T-cell activation by binding to PD-1 receptor', 'Tyrosine kinase receptor involved in cell proliferation' | Concise functional description |
| clinical_relevance | TEXT | NULL | Known clinical associations and therapeutic implications | 'Predictive biomarker for anti-PD-1 therapy response in NSCLC', 'Targetable driver mutation in lung adenocarcinoma' | Focus on clinical utility |
| standard_nomenclature | VARCHAR(255) | NULL | Alternative standard names or aliases | 'CD274', 'B7-H1', 'PDCD1LG1' | Semicolon-separated list of synonyms |
| ontology_reference | VARCHAR(255) | NULL | Links to ontology databases | 'HGNC:17635', 'GO:0042802', 'KEGG:hsa04151' | Semicolon-separated ontology IDs |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `biomarker_id`
- INDEX on `biomarker_type` for filtering by modality
- INDEX on `gene_symbol` for gene-based queries
- INDEX on `measurement_category` for specific measurement types
- FULLTEXT INDEX on `biomarker_name`, `biological_function`, `clinical_relevance` for search

**Relationships**:
- **Parent to**: `cohort_biomarker_summary`, `biomarker_correlations`, `biomarker_endpoint_associations`, `biomarker_thresholds`, `signature_components`, `cohort_classifications`, `meta_analysis_results`
- **Cardinality**: Typically 1,000-100,000 biomarkers depending on scope

**Data Quality Checks**:
- `biomarker_id` should be unique and descriptive
- `biomarker_type` should use controlled vocabulary
- For genomic biomarkers, `gene_symbol` should be present
- For proteomic biomarkers, `protein_name` and ideally `uniprot_id` should be present
- `biological_function` and `clinical_relevance` should be populated for key biomarkers
- Cross-reference IDs (uniprot_id, ensembl_id) should be validated against external databases

**Usage Examples**:
```sql
-- Find all immune checkpoint biomarkers
SELECT biomarker_id, biomarker_name, gene_symbol, clinical_relevance
FROM biomarkers
WHERE pathway LIKE '%checkpoint%'
OR clinical_relevance LIKE '%checkpoint%'
ORDER BY biomarker_name;

-- Get genomic biomarkers with known clinical utility
SELECT biomarker_id, biomarker_name, gene_symbol, clinical_relevance
FROM biomarkers
WHERE biomarker_type = 'genomic'
AND clinical_relevance IS NOT NULL
AND clinical_relevance LIKE '%predictive%'
ORDER BY gene_symbol;

-- Find biomarkers on a specific chromosome
SELECT biomarker_id, biomarker_name, gene_symbol, genomic_position
FROM biomarkers
WHERE chromosome = '7'
ORDER BY genomic_position;

-- Search for biomarkers by function
SELECT biomarker_id, biomarker_name, biological_function
FROM biomarkers
WHERE MATCH(biological_function) AGAINST('kinase signaling' IN NATURAL LANGUAGE MODE);
```

---

### assay_platforms

**Purpose**: Documents measurement technologies and their technical specifications, enabling platform-specific quality assessment, data harmonization, and appropriate interpretation of biomarker measurements.

**Business Context**: Biomarker measurements depend critically on assay technology. Different platforms have varying sensitivity, specificity, dynamic ranges, and measurement units. This table tracks platform characteristics essential for data quality assessment and cross-platform comparisons.

**Data Sources**: Manufacturer specifications, assay validation reports, platform documentation, published methods.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| platform_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for the assay platform | 'ILLUMINA_NOVASEQ', 'AFFYMETRIX_U133', 'LUMINEX_XMAP', 'VENTANA_SP263' | Combine manufacturer and model |
| platform_name | VARCHAR(255) | NOT NULL | Full commercial or descriptive name | 'Illumina NovaSeq 6000', 'Affymetrix Human Genome U133 Plus 2.0', 'Luminex xMAP Technology' | Official product name |
| platform_type | VARCHAR(100) | NULL | High-level technology classification | 'RNA-seq', 'microarray', 'mass_spec', 'ELISA', 'IHC', 'NGS', 'flow_cytometry', 'qPCR', 'Luminex' | Standardized platform categories |
| manufacturer | VARCHAR(255) | NULL | Company that produces the platform | 'Illumina', 'Thermo Fisher Scientific', 'Roche', 'Agilent', 'Bio-Rad' | Official manufacturer name |
| model | VARCHAR(255) | NULL | Specific model or version | 'NovaSeq 6000', 'HiSeq 4000', 'Orbitrap Fusion', 'SP263' | Model designation from manufacturer |
| technology | VARCHAR(255) | NULL | Underlying measurement technology | 'Sequencing by synthesis', 'Oligonucleotide microarray', 'Immunohistochemistry', 'Electrochemiluminescence' | Technical principle |
| measurement_type | VARCHAR(100) | NULL | Nature of measurement output | 'absolute', 'relative', 'categorical', 'binary', 'semi-quantitative' | How measurements should be interpreted |
| measurement_unit | VARCHAR(50) | NULL | Standard unit for measurements | 'TPM', 'RPKM', 'fluorescence_intensity', 'H-score', 'positive/negative', 'pg/mL' | Platform-specific units |
| detection_limit | DECIMAL(15,6) | NULL, CHECK (detection_limit >= 0) | Lower limit of detection (LOD) | 0.1, 1.0, 10.0 | Minimum detectable concentration/signal |
| quantification_limit | DECIMAL(15,6) | NULL, CHECK (quantification_limit >= 0) | Lower limit of quantification (LOQ) | 0.5, 5.0, 25.0 | Minimum reliably quantifiable level; typically > LOD |
| dynamic_range_min | DECIMAL(15,6) | NULL | Minimum value in quantifiable range | 0.5, 1.0, 10.0 | Lower bound of linear range |
| dynamic_range_max | DECIMAL(15,6) | NULL | Maximum value in quantifiable range | 10000.0, 50000.0, 100000.0 | Upper bound of linear range |
| protocol_reference | TEXT | NULL | Reference to detailed protocol or SOP | 'Illumina TruSeq Stranded mRNA Library Prep Kit Protocol v2.5', 'DOI: 10.1038/nprot.2016.095' | Links to detailed methods |
| validation_status | VARCHAR(50) | NULL | Regulatory or validation status | 'research_use', 'validated', 'FDA_approved', 'CE_marked', 'CLIA_certified' | Regulatory classification |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `platform_id`
- INDEX on `platform_type` for technology-based filtering
- INDEX on `manufacturer` for vendor-specific queries
- INDEX on `validation_status` for regulatory filtering

**Relationships**:
- **Parent to**: `assay_datasets`
- **Cardinality**: Typically 50-500 distinct platforms

**Data Quality Checks**:
- `quantification_limit` should be ≥ `detection_limit`
- `dynamic_range_max` should be > `dynamic_range_min`
- `validation_status` should use controlled vocabulary
- For quantitative platforms, `measurement_unit` should be specified
- `protocol_reference` should be provided for key platforms

**Usage Examples**:
```sql
-- Find FDA-approved diagnostic platforms
SELECT platform_name, platform_type, manufacturer, validation_status
FROM assay_platforms
WHERE validation_status LIKE '%FDA%'
ORDER BY platform_type, platform_name;

-- Compare dynamic ranges across RNA-seq platforms
SELECT 
    platform_name,
    measurement_unit,
    detection_limit,
    quantification_limit,
    dynamic_range_max / dynamic_range_min AS fold_range
FROM assay_platforms
WHERE platform_type = 'RNA-seq'
ORDER BY fold_range DESC;

-- Get all platforms from a specific manufacturer
SELECT platform_id, platform_name, platform_type, model
FROM assay_platforms
WHERE manufacturer = 'Illumina'
ORDER BY platform_type, model;
```

---

### assay_datasets

**Purpose**: Links clinical trials to specific molecular measurement datasets, providing dataset-level metadata essential for data quality assessment, reproducibility, and appropriate data interpretation.

**Business Context**: Each trial may generate multiple molecular datasets using different platforms, specimen types, and timepoints. This table documents dataset characteristics critical for understanding data provenance, quality, and applicability.

**Data Sources**: Trial databases, data repositories (GEO, SRA, EGA), publications, data transfer agreements.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| dataset_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for the dataset | 'NCT04567890_RNASEQ_BL', 'KEYNOTE001_TMB', 'CHECKMATE067_PDL1_IHC' | Combine trial and assay type |
| trial_id | VARCHAR(50) | FOREIGN KEY (clinical_trials.trial_id), NOT NULL | Links to parent clinical trial | 'NCT04567890', 'KEYNOTE-001' | Must exist in clinical_trials table |
| platform_id | VARCHAR(50) | FOREIGN KEY (assay_platforms.platform_id), NOT NULL | Links to assay platform used | 'ILLUMINA_NOVASEQ', 'VENTANA_SP263' | Must exist in assay_platforms table |
| dataset_name | VARCHAR(255) | NOT NULL | Descriptive name for the dataset | 'Baseline RNA-seq', 'Tumor Mutational Burden Analysis', 'PD-L1 IHC at Screening' | Clear, informative name |
| dataset_description | TEXT | NULL | Detailed description of dataset scope and characteristics | 'RNA sequencing of baseline tumor biopsies from all enrolled patients, processed using standard TruSeq protocol' | Include specimen details, processing, scope |
| collection_timepoint | VARCHAR(100) | NULL | When specimens were collected relative to treatment | 'Baseline', 'Week 6', 'Progression', 'Pre-treatment', 'On-treatment Day 15' | Standardized timepoint terminology |
| specimen_type | VARCHAR(100) | NULL | Type of biological specimen analyzed | 'blood', 'plasma', 'serum', 'tissue', 'PBMC', 'tumor_biopsy', 'FFPE_tissue', 'fresh_frozen' | Controlled vocabulary for specimen types |
| sample_size | INT | NULL, CHECK (sample_size >= 0) | Number of samples in dataset | 150, 200, 85 | May be less than trial enrollment due to availability |
| processing_protocol | TEXT | NULL | Description of sample processing and preparation | 'FFPE sections cut at 5μm, RNA extracted using RNeasy FFPE Kit, library prep with TruSeq Stranded mRNA' | Detailed processing steps |
| normalization_method | VARCHAR(255) | NULL | Method used to normalize raw measurements | 'TPM', 'RPKM', 'DESeq2', 'quantile_normalization', 'VST', 'Z-score' | Specify normalization algorithm |
| batch_correction_applied | BOOLEAN | DEFAULT FALSE | Whether batch correction was performed | TRUE, FALSE | Important for multi-batch datasets |
| batch_correction_method | VARCHAR(255) | NULL | Batch correction algorithm if applied | 'ComBat', 'limma_removeBatchEffect', 'SVA', 'RUVSeq' | NULL if batch_correction_applied = FALSE |
| quality_control_criteria | TEXT | NULL | QC metrics and thresholds applied | 'RIN ≥7, >10M reads per sample, mapping rate >80%, excluded samples with >20% missing data' | Document QC filters |
| data_availability | VARCHAR(50) | NULL | Access level for the dataset | 'public', 'restricted', 'proprietary', 'controlled_access' | Data sharing status |
| data_repository | VARCHAR(255) | NULL | Public repository where data is deposited | 'GEO', 'SRA', 'EGA', 'dbGaP', 'ArrayExpress' | Repository name if publicly available |
| accession_number | VARCHAR(100) | NULL | Repository accession number | 'GSE123456', 'PRJNA654321', 'EGAS00001004567' | Unique identifier in repository |
| publication_doi | VARCHAR(255) | NULL | DOI of primary publication describing dataset | '10.1038/s41586-021-03234-5', '10.1056/NEJMoa2034577' | Link to published methods |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `dataset_id`
- FOREIGN KEY INDEX on `trial_id`
- FOREIGN KEY INDEX on `platform_id`
- COMPOSITE INDEX on (`trial_id`, `platform_id`) for trial-platform queries
- INDEX on `specimen_type` for specimen-based filtering
- INDEX on `data_availability` for access-level queries

**Relationships**:
- **Child of**: `clinical_trials`, `assay_platforms`
- **Parent to**: `cohort_biomarker_summary`, `biomarker_correlations`, `biomarker_endpoint_associations`
- **Cardinality**: Typically 1-10 datasets per trial

**Data Quality Checks**:
- `sample_size` should be ≤ trial `total_enrolled`
- If `batch_correction_applied` = TRUE, `batch_correction_method` should be specified
- If `data_availability` = 'public', `data_repository` and `accession_number` should be present
- `normalization_method` should be appropriate for `platform_id` type
- `collection_timepoint` should be consistent with trial design

**Usage Examples**:
```sql
-- Find publicly available RNA-seq datasets
SELECT 
    t.trial_name,
    ad.dataset_name,
    ad.sample_size,
    ad.data_repository,
    ad.accession_number
FROM assay_datasets ad
JOIN clinical_trials t ON ad.trial_id = t.trial_id
JOIN assay_platforms ap ON ad.platform_id = ap.platform_id
WHERE ap.platform_type = 'RNA-seq'
AND ad.data_availability = 'public'
ORDER BY t.trial_name;

-- Get dataset processing details for a trial
SELECT 
    dataset_name,
    specimen_type,
    collection_timepoint,
    normalization_method,
    batch_correction_applied,
    batch_correction_method,
    quality_control_criteria
FROM assay_datasets
WHERE trial_id = 'NCT04567890';

-- Find datasets with batch correction
SELECT 
    t.trial_name,
    ad.dataset_name,
    ap.platform_name,
    ad.batch_correction_method
FROM assay_datasets ad
JOIN clinical_trials t ON ad.trial_id = t.trial_id
JOIN assay_platforms ap ON ad.platform_id = ap.platform_id
WHERE ad.batch_correction_applied = TRUE;
```

---

## Aggregated Measurements Tables

### cohort_biomarker_summary

**Purpose**: Stores comprehensive summary statistics for each biomarker measured in each cohort, representing the primary aggregated molecular measurement data. This table enables biomarker distribution analyses, threshold determination, and cross-cohort comparisons without individual patient data.

**Business Context**: This is the core table for biomarker measurements. All downstream analyses (associations, classifications, thresholds) derive from these summary statistics. The table captures both central tendency and distribution characteristics essential for statistical modeling.

**Data Sources**: Processed assay data, statistical analysis outputs, published supplementary data.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| summary_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this summary record | 1, 2, 3, ... | System-generated sequential ID |
| cohort_id | VARCHAR(50) | FOREIGN KEY (patient_cohorts.cohort_id), NOT NULL | Links to patient cohort | 'NCT04567890_PDL1_HIGH' | Must exist in patient_cohorts table |
| dataset_id | VARCHAR(50) | FOREIGN KEY (assay_datasets.dataset_id), NOT NULL | Links to source dataset | 'NCT04567890_RNASEQ_BL' | Must exist in assay_datasets table |
| biomarker_id | VARCHAR(50) | FOREIGN KEY (biomarkers.biomarker_id), NOT NULL | Links to biomarker definition | 'PD_L1', 'TMB', 'CD8A_EXPRESSION' | Must exist in biomarkers table |
| n_samples | INT | NOT NULL, CHECK (n_samples > 0) | Number of samples with measurements | 150, 200, 85 | Should be ≤ cohort sample_size |
| n_detected | INT | NULL, CHECK (n_detected >= 0 AND n_detected <= n_samples) | Number of samples with detectable levels | 145, 180, 60 | For biomarkers with detection limits |
| detection_rate | DECIMAL(5,4) | NULL, CHECK (detection_rate >= 0 AND detection_rate <= 1) | Proportion of samples with detectable levels | 0.9667, 0.9000, 0.7059 | n_detected / n_samples |
| mean_value | DECIMAL(20,8) | NULL | Arithmetic mean of biomarker values | 45.67890123, 12.34567890, 156.78901234 | Central tendency measure |
| median_value | DECIMAL(20,8) | NULL | Median (50th percentile) of biomarker values | 42.50000000, 10.25000000, 145.00000000 | Robust central tendency; preferred for skewed distributions |
| std_dev | DECIMAL(20,8) | NULL, CHECK (std_dev >= 0) | Standard deviation of biomarker values | 15.23456789, 8.45678901, 45.67890123 | Measure of variability |
| std_error | DECIMAL(20,8) | NULL, CHECK (std_error >= 0) | Standard error of the mean | 1.24567890, 0.61234567, 4.89012345 | std_dev / sqrt(n_samples) |
| min_value | DECIMAL(20,8) | NULL | Minimum observed value | 5.00000000, 0.10000000, 20.00000000 | Range minimum |
| max_value | DECIMAL(20,8) | NULL | Maximum observed value | 95.00000000, 50.00000000, 500.00000000 | Range maximum |
| quartile_25 | DECIMAL(20,8) | NULL | 25th percentile (Q1) | 32.50000000, 6.75000000, 110.00000000 | First quartile |
| quartile_75 | DECIMAL(20,8) | NULL | 75th percentile (Q3) | 58.75000000, 16.25000000, 195.00000000 | Third quartile |
| percentile_10 | DECIMAL(20,8) | NULL | 10th percentile | 20.00000000, 3.50000000, 75.00000000 | Lower tail of distribution |
| percentile_90 | DECIMAL(20,8) | NULL | 90th percentile | 75.00000000, 25.00000000, 280.00000000 | Upper tail of distribution |
| geometric_mean | DECIMAL(20,8) | NULL, CHECK (geometric_mean >= 0) | Geometric mean of biomarker values | 40.12345678, 9.87654321, 142.34567890 | Appropriate for log-normal distributions |
| coefficient_variation | DECIMAL(10,6) | NULL, CHECK (coefficient_variation >= 0) | Coefficient of variation (CV) | 0.333333, 0.685714, 0.291304 | std_dev / mean; relative variability |
| skewness | DECIMAL(10,6) | NULL | Skewness of distribution | 0.567890, -0.234567, 1.456789 | Measure of asymmetry; 0 = symmetric |
| kurtosis | DECIMAL(10,6) | NULL | Kurtosis of distribution | 2.345678, 3.567890, 5.123456 | Measure of tail heaviness; 3 = normal |
| measurement_unit | VARCHAR(50) | NULL | Unit of measurement | 'TPM', 'H-score', 'mutations/Mb', 'pg/mL', 'percent' | Should match platform measurement_unit |
| transformation_applied | VARCHAR(100) | NULL | Transformation applied to raw values | 'log2', 'log10', 'sqrt', 'none', 'Box-Cox' | Document data transformation |
| outliers_removed | INT | NULL, CHECK (outliers_removed >= 0) | Number of outliers excluded from summary | 0, 3, 5 | Document outlier handling |
| quality_flags | TEXT | NULL | Quality control flags or warnings | 'High CV', 'Bimodal distribution', 'Low detection rate', 'Batch effects detected' | Free text for QC issues |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `summary_id`
- FOREIGN KEY INDEX on `cohort_id`
- FOREIGN KEY INDEX on `dataset_id`
- FOREIGN KEY INDEX on `biomarker_id`
- COMPOSITE INDEX on (`cohort_id`, `biomarker_id`) for cohort-biomarker queries
- COMPOSITE INDEX on (`dataset_id`, `biomarker_id`) for dataset-biomarker queries
- COMPOSITE INDEX on (`biomarker_id`, `mean_value`) for biomarker-level analyses
- INDEX on `detection_rate` for filtering by detection

**Relationships**:
- **Child of**: `patient_cohorts`, `assay_datasets`, `biomarkers`
- **Parent to**: `biomarker_distributions`
- **Cardinality**: Potentially millions of records (cohorts × biomarkers)

**Data Quality Checks**:
- `n_samples` should be ≤ cohort `sample_size`
- `n_detected` should be ≤ `n_samples`
- `detection_rate` should equal `n_detected / n_samples`
- `min_value` ≤ `quartile_25` ≤ `median_value` ≤ `quartile_75` ≤ `max_value`
- `percentile_10` ≤ `percentile_90`
- `std_error` should approximately equal `std_dev / sqrt(n_samples)`
- `coefficient_variation` should equal `std_dev / mean_value`
- For log-transformed data, `geometric_mean` should be present
- `measurement_unit` should be consistent with `platform_id` in parent dataset

**Usage Examples**:
```sql
-- Get biomarker distribution summary for a cohort
SELECT 
    b.biomarker_name,
    cbs.n_samples,
    cbs.mean_value,
    cbs.median_value,
    cbs.std_dev,
    cbs.quartile_25,
    cbs.quartile_75,
    cbs.measurement_unit
FROM cohort_biomarker_summary cbs
JOIN biomarkers b ON cbs.biomarker_id = b.biomarker_id
WHERE cbs.cohort_id = 'NCT04567890_PDL1_HIGH'
ORDER BY b.biomarker_name;

-- Compare biomarker levels across cohorts
SELECT 
    pc.cohort_name,
    cbs.mean_value AS mean_pdl1,
    cbs.median_value AS median_pdl1,
    cbs.detection_rate
FROM cohort_biomarker_summary cbs
JOIN patient_cohorts pc ON cbs.cohort_id = pc.cohort_id
WHERE cbs.biomarker_id = 'PD_L1'
ORDER BY cbs.mean_value DESC;

-- Find biomarkers with high variability
SELECT 
    b.biomarker_name,
    pc.cohort_name,
    cbs.coefficient_variation,
    cbs.mean_value,
    cbs.std_dev
FROM cohort_biomarker_summary cbs
JOIN biomarkers b ON cbs.biomarker_id = b.biomarker_id
JOIN patient_cohorts pc ON cbs.cohort_id = pc.cohort_id
WHERE cbs.coefficient_variation > 0.5
ORDER BY cbs.coefficient_variation DESC;

-- Identify biomarkers with low detection rates
SELECT 
    b.biomarker_name,
    pc.cohort_name,
    cbs.n_samples,
    cbs.n_detected,
    cbs.detection_rate
FROM cohort_biomarker_summary cbs
JOIN biomarkers b ON cbs.biomarker_id = b.biomarker_id
JOIN patient_cohorts pc ON cbs.cohort_id = pc.cohort_id
WHERE cbs.detection_rate < 0.8
ORDER BY cbs.detection_rate;
```

---

Due to the extensive length of this comprehensive documentation, I'll continue with the remaining tables in a structured format. Would you like me to continue with:

1. **biomarker_distributions** - Histogram/binned distribution data
2. **biomarker_correlations** - Pairwise biomarker correlations
3. **biomarker_endpoint_associations** - Statistical associations
4. **stratified_outcomes** - Outcome stratification by biomarker levels
5. **classification_models** - Model registry
6. **biomarker_thresholds** - Classification cutpoints
7. **biomarker_signatures** - Multi-biomarker panels
8. **signature_components** - Signature composition
9. **cohort_classifications** - Classification results
10. **classification_performance_by_status** - Performance metrics
11. **model_validations** - Validation results
12. **cross_trial_validations** - Cross-trial performance
13. **meta_analysis_results** - Pooled analyses
14. **data_provenance** - Data lineage
15. **audit_log** - Change tracking
16. **data_quality_issues** - Quality management
17. **user_access_log** - Access tracking

Would you like me to continue with the remaining tables in the same comprehensive detail?

# Comprehensive Table and Column Specifications (Continued)

## Aggregated Measurements Tables (Continued)

### biomarker_distributions

**Purpose**: Stores histogram/binned distribution data for biomarker values, enabling detailed distribution visualization, normality testing, percentile calculations, and identification of multimodal distributions that may indicate distinct patient subpopulations.

**Business Context**: Summary statistics (mean, median, quartiles) provide limited information about distribution shape. Histogram data reveals bimodality, skewness, and outliers that are critical for threshold determination and understanding biological heterogeneity. This table supports advanced statistical modeling and data quality assessment.

**Data Sources**: Statistical analysis of raw biomarker data, histogram generation algorithms, distribution fitting procedures.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| distribution_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this distribution bin record | 1, 2, 3, ... | System-generated sequential ID |
| summary_id | BIGINT | FOREIGN KEY (cohort_biomarker_summary.summary_id), NOT NULL | Links to parent biomarker summary | 12345, 67890 | Must exist in cohort_biomarker_summary table |
| bin_number | INT | NOT NULL, CHECK (bin_number > 0) | Ordinal position of bin in histogram | 1, 2, 3, ..., 20 | Sequential numbering from lowest to highest values |
| bin_lower_bound | DECIMAL(20,8) | NULL | Lower boundary of bin (inclusive) | 0.00000000, 10.00000000, 20.00000000 | NULL for leftmost bin if unbounded |
| bin_upper_bound | DECIMAL(20,8) | NULL | Upper boundary of bin (exclusive) | 10.00000000, 20.00000000, 30.00000000 | NULL for rightmost bin if unbounded |
| bin_count | INT | NULL, CHECK (bin_count >= 0) | Number of observations in this bin | 15, 28, 42, 0 | Should sum to n_samples in parent summary |
| bin_frequency | DECIMAL(8,6) | NULL, CHECK (bin_frequency >= 0 AND bin_frequency <= 1) | Proportion of observations in this bin | 0.100000, 0.186667, 0.280000 | bin_count / total_n_samples |
| cumulative_frequency | DECIMAL(8,6) | NULL, CHECK (cumulative_frequency >= 0 AND cumulative_frequency <= 1) | Cumulative proportion up to and including this bin | 0.100000, 0.286667, 0.566667 | Sum of bin_frequency from bin 1 to current bin |

**Indexes**:
- PRIMARY KEY on `distribution_id`
- FOREIGN KEY INDEX on `summary_id`
- COMPOSITE INDEX on (`summary_id`, `bin_number`) for ordered bin retrieval
- INDEX on `bin_count` for filtering non-empty bins

**Relationships**:
- **Child of**: `cohort_biomarker_summary` (many bins to one summary)
- **Cardinality**: Typically 10-50 bins per biomarker summary

**Data Quality Checks**:
- Sum of `bin_count` across all bins for a `summary_id` should equal `n_samples` in parent summary
- Sum of `bin_frequency` across all bins should equal 1.0 (within rounding tolerance)
- `cumulative_frequency` should be monotonically increasing with `bin_number`
- Final bin's `cumulative_frequency` should equal 1.0
- `bin_lower_bound` of bin N should equal `bin_upper_bound` of bin N-1 (for continuous bins)
- `bin_upper_bound` should be > `bin_lower_bound` for each bin
- No gaps between consecutive bins (unless intentional for sparse data)

**Usage Examples**:
```sql
-- Get histogram data for a specific biomarker in a cohort
SELECT 
    bd.bin_number,
    bd.bin_lower_bound,
    bd.bin_upper_bound,
    bd.bin_count,
    bd.bin_frequency,
    bd.cumulative_frequency
FROM biomarker_distributions bd
JOIN cohort_biomarker_summary cbs ON bd.summary_id = cbs.summary_id
WHERE cbs.cohort_id = 'NCT04567890_PDL1_HIGH'
AND cbs.biomarker_id = 'PD_L1'
ORDER BY bd.bin_number;

-- Identify bimodal distributions (bins with local maxima)
SELECT 
    b.biomarker_name,
    pc.cohort_name,
    bd.bin_number,
    bd.bin_count,
    bd.bin_frequency
FROM biomarker_distributions bd
JOIN cohort_biomarker_summary cbs ON bd.summary_id = cbs.summary_id
JOIN biomarkers b ON cbs.biomarker_id = b.biomarker_id
JOIN patient_cohorts pc ON cbs.cohort_id = pc.cohort_id
WHERE bd.bin_count > (
    SELECT AVG(bin_count) 
    FROM biomarker_distributions 
    WHERE summary_id = bd.summary_id
)
ORDER BY b.biomarker_name, bd.bin_number;

-- Calculate percentiles from cumulative distribution
SELECT 
    b.biomarker_name,
    bd.bin_lower_bound AS percentile_50_approx
FROM biomarker_distributions bd
JOIN cohort_biomarker_summary cbs ON bd.summary_id = cbs.summary_id
JOIN biomarkers b ON cbs.biomarker_id = b.biomarker_id
WHERE cbs.cohort_id = 'NCT04567890_PDL1_HIGH'
AND bd.cumulative_frequency >= 0.5
ORDER BY bd.bin_number
LIMIT 1;

-- Find biomarkers with heavy tails (high counts in extreme bins)
SELECT 
    b.biomarker_name,
    pc.cohort_name,
    SUM(CASE WHEN bd.bin_number <= 2 OR bd.bin_number >= (SELECT MAX(bin_number) - 1 FROM biomarker_distributions WHERE summary_id = bd.summary_id) 
        THEN bd.bin_count ELSE 0 END) AS extreme_bin_count,
    cbs.n_samples,
    ROUND(100.0 * SUM(CASE WHEN bd.bin_number <= 2 OR bd.bin_number >= (SELECT MAX(bin_number) - 1 FROM biomarker_distributions WHERE summary_id = bd.summary_id) 
        THEN bd.bin_count ELSE 0 END) / cbs.n_samples, 2) AS extreme_percent
FROM biomarker_distributions bd
JOIN cohort_biomarker_summary cbs ON bd.summary_id = cbs.summary_id
JOIN biomarkers b ON cbs.biomarker_id = b.biomarker_id
JOIN patient_cohorts pc ON cbs.cohort_id = pc.cohort_id
GROUP BY b.biomarker_name, pc.cohort_name, cbs.n_samples
HAVING extreme_percent > 20;
```

---

### biomarker_correlations

**Purpose**: Captures pairwise Pearson, Spearman, or Kendall correlations between biomarkers within cohorts, enabling identification of redundant biomarkers, biological relationships, and multicollinearity assessment for multi-biomarker models.

**Business Context**: Biomarkers often correlate due to shared biological pathways, regulatory mechanisms, or technical artifacts. Understanding these correlations is essential for: (1) feature selection in predictive models, (2) identifying biomarker redundancy, (3) discovering biological relationships, and (4) pathway enrichment analyses.

**Data Sources**: Correlation analysis of biomarker data, network analysis outputs, pathway analysis results.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| correlation_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this correlation record | 1, 2, 3, ... | System-generated sequential ID |
| cohort_id | VARCHAR(50) | FOREIGN KEY (patient_cohorts.cohort_id), NOT NULL | Links to patient cohort | 'NCT04567890_PDL1_HIGH' | Must exist in patient_cohorts table |
| dataset_id | VARCHAR(50) | FOREIGN KEY (assay_datasets.dataset_id), NOT NULL | Links to source dataset | 'NCT04567890_RNASEQ_BL' | Must exist in assay_datasets table; both biomarkers should be from same dataset |
| biomarker_1_id | VARCHAR(50) | FOREIGN KEY (biomarkers.biomarker_id), NOT NULL | First biomarker in correlation pair | 'PD_L1', 'CD8A_EXPRESSION' | Must exist in biomarkers table |
| biomarker_2_id | VARCHAR(50) | FOREIGN KEY (biomarkers.biomarker_id), NOT NULL | Second biomarker in correlation pair | 'CD274', 'IFNG_EXPRESSION' | Must exist in biomarkers table; should be different from biomarker_1_id |
| correlation_coefficient | DECIMAL(10,8) | NULL, CHECK (correlation_coefficient >= -1 AND correlation_coefficient <= 1) | Correlation coefficient value | 0.85678901, -0.45678901, 0.12345678 | Range: -1 (perfect negative) to +1 (perfect positive) |
| correlation_type | VARCHAR(50) | NULL | Type of correlation calculated | 'pearson', 'spearman', 'kendall', 'partial', 'distance' | Pearson for linear relationships; Spearman for monotonic; Kendall for ordinal |
| p_value | DECIMAL(15,10) | NULL, CHECK (p_value >= 0 AND p_value <= 1) | Statistical significance of correlation | 0.0000123456, 0.0450000000, 0.3456789012 | Tests null hypothesis of zero correlation |
| n_samples | INT | NULL, CHECK (n_samples > 0) | Number of paired observations used | 150, 145, 138 | May be less than cohort size due to missing data |
| confidence_interval_lower | DECIMAL(10,8) | NULL, CHECK (confidence_interval_lower >= -1 AND confidence_interval_lower <= 1) | Lower bound of 95% CI for correlation | 0.78901234, -0.56789012, 0.01234567 | Typically 95% confidence interval |
| confidence_interval_upper | DECIMAL(10,8) | NULL, CHECK (confidence_interval_upper >= -1 AND confidence_interval_upper <= 1) | Upper bound of 95% CI for correlation | 0.90123456, -0.34567890, 0.23456789 | Should be > confidence_interval_lower |

**Indexes**:
- PRIMARY KEY on `correlation_id`
- FOREIGN KEY INDEX on `cohort_id`
- FOREIGN KEY INDEX on `dataset_id`
- FOREIGN KEY INDEX on `biomarker_1_id`
- FOREIGN KEY INDEX on `biomarker_2_id`
- COMPOSITE INDEX on (`cohort_id`, `biomarker_1_id`, `biomarker_2_id`) for specific pair queries
- COMPOSITE INDEX on (`biomarker_1_id`, `biomarker_2_id`, `correlation_coefficient`) for correlation strength queries
- INDEX on `p_value` for filtering significant correlations
- INDEX on `correlation_coefficient` for filtering by strength

**Relationships**:
- **Child of**: `patient_cohorts`, `assay_datasets`, `biomarkers` (×2)
- **Cardinality**: Potentially millions of records (cohorts × biomarker pairs)

**Data Quality Checks**:
- `biomarker_1_id` should not equal `biomarker_2_id` (no self-correlations)
- `correlation_coefficient` should be between -1 and +1
- `confidence_interval_lower` < `correlation_coefficient` < `confidence_interval_upper`
- `n_samples` should be ≥ 3 for meaningful correlation
- For symmetric correlations, only store one direction (e.g., A-B, not both A-B and B-A)
- `p_value` should be consistent with `correlation_coefficient` and `n_samples`
- Both biomarkers should exist in the same `dataset_id`

**Usage Examples**:
```sql
-- Find highly correlated biomarker pairs
SELECT 
    b1.biomarker_name AS biomarker_1,
    b2.biomarker_name AS biomarker_2,
    bc.correlation_coefficient,
    bc.p_value,
    bc.n_samples
FROM biomarker_correlations bc
JOIN biomarkers b1 ON bc.biomarker_1_id = b1.biomarker_id
JOIN biomarkers b2 ON bc.biomarker_2_id = b2.biomarker_id
WHERE bc.cohort_id = 'NCT04567890_PDL1_HIGH'
AND ABS(bc.correlation_coefficient) > 0.7
AND bc.p_value < 0.05
ORDER BY ABS(bc.correlation_coefficient) DESC;

-- Identify redundant biomarkers (very high correlation)
SELECT 
    b1.biomarker_name AS biomarker_1,
    b2.biomarker_name AS biomarker_2,
    bc.correlation_coefficient,
    bc.p_value
FROM biomarker_correlations bc
JOIN biomarkers b1 ON bc.biomarker_1_id = b1.biomarker_id
JOIN biomarkers b2 ON bc.biomarker_2_id = b2.biomarker_id
WHERE ABS(bc.correlation_coefficient) > 0.95
AND bc.p_value < 0.001
ORDER BY ABS(bc.correlation_coefficient) DESC;

-- Find negative correlations (potential antagonistic relationships)
SELECT 
    b1.biomarker_name AS biomarker_1,
    b2.biomarker_name AS biomarker_2,
    bc.correlation_coefficient,
    bc.p_value,
    pc.cohort_name
FROM biomarker_correlations bc
JOIN biomarkers b1 ON bc.biomarker_1_id = b1.biomarker_id
JOIN biomarkers b2 ON bc.biomarker_2_id = b2.biomarker_id
JOIN patient_cohorts pc ON bc.cohort_id = pc.cohort_id
WHERE bc.correlation_coefficient < -0.5
AND bc.p_value < 0.05
ORDER BY bc.correlation_coefficient;

-- Get correlation network for a specific biomarker
SELECT 
    b2.biomarker_name AS correlated_biomarker,
    bc.correlation_coefficient,
    bc.p_value,
    bc.correlation_type
FROM biomarker_correlations bc
JOIN biomarkers b2 ON bc.biomarker_2_id = b2.biomarker_id
WHERE bc.biomarker_1_id = 'PD_L1'
AND bc.cohort_id = 'NCT04567890_PDL1_HIGH'
AND bc.p_value < 0.05
ORDER BY ABS(bc.correlation_coefficient) DESC;
```

---

## Statistical Associations Tables

### biomarker_endpoint_associations

**Purpose**: Documents statistical relationships between biomarkers and clinical endpoints, representing the core evidence for biomarker-outcome associations. This table captures univariate and multivariate analyses with comprehensive statistical metrics.

**Business Context**: This is the critical table for biomarker discovery and validation. It stores evidence of predictive, prognostic, or pharmacodynamic relationships between molecular markers and clinical outcomes. These associations form the basis for threshold development and biomarker qualification.

**Data Sources**: Statistical analysis outputs, published association studies, survival analyses, regression models, clinical study reports.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| association_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this association record | 1, 2, 3, ... | System-generated sequential ID |
| cohort_id | VARCHAR(50) | FOREIGN KEY (patient_cohorts.cohort_id), NOT NULL | Links to patient cohort | 'NCT04567890_PDL1_HIGH' | Must exist in patient_cohorts table |
| biomarker_id | VARCHAR(50) | FOREIGN KEY (biomarkers.biomarker_id), NOT NULL | Predictor biomarker | 'PD_L1', 'TMB', 'CD8A_EXPRESSION' | Must exist in biomarkers table |
| endpoint_id | VARCHAR(50) | FOREIGN KEY (endpoints.endpoint_id), NOT NULL | Outcome endpoint | 'OS', 'PFS', 'ORR', 'AE_GRADE3_PLUS' | Must exist in endpoints table |
| dataset_id | VARCHAR(50) | FOREIGN KEY (assay_datasets.dataset_id), NOT NULL | Source dataset for biomarker measurements | 'NCT04567890_RNASEQ_BL' | Must exist in assay_datasets table |
| analysis_type | VARCHAR(100) | NULL | Type of statistical analysis performed | 'univariate', 'multivariate', 'survival_analysis', 'logistic_regression', 'cox_regression', 'linear_regression' | Describes analytical approach |
| statistical_test | VARCHAR(100) | NULL | Specific statistical test used | 't_test', 'mann_whitney', 'log_rank', 'cox_regression', 'chi_square', 'fisher_exact', 'wilcoxon' | Name of statistical procedure |
| test_statistic | DECIMAL(15,8) | NULL | Value of test statistic | 3.45678901, -2.12345678, 15.67890123 | Test-specific statistic (t, z, chi-square, F, etc.) |
| p_value | DECIMAL(15,10) | NULL, CHECK (p_value >= 0 AND p_value <= 1) | Raw p-value from statistical test | 0.0001234567, 0.0350000000, 0.4567890123 | Unadjusted significance level |
| adjusted_p_value | DECIMAL(15,10) | NULL, CHECK (adjusted_p_value >= 0 AND adjusted_p_value <= 1) | Multiple testing corrected p-value | 0.0012345678, 0.0850000000, 0.8901234567 | FDR (Benjamini-Hochberg) or Bonferroni correction |
| effect_size | DECIMAL(15,8) | NULL | Magnitude of association | 2.50000000, 0.65000000, -0.45000000 | Interpretation depends on effect_size_type |
| effect_size_type | VARCHAR(50) | NULL | Type of effect size measure | 'cohens_d', 'odds_ratio', 'hazard_ratio', 'correlation', 'risk_ratio', 'mean_difference', 'beta_coefficient' | Specifies effect_size interpretation |
| confidence_interval_lower | DECIMAL(15,8) | NULL | Lower bound of 95% CI for effect size | 2.10000000, 0.52000000, -0.65000000 | Typically 95% confidence interval |
| confidence_interval_upper | DECIMAL(15,8) | NULL | Upper bound of 95% CI for effect size | 3.20000000, 0.81000000, -0.25000000 | Should be > confidence_interval_lower |
| n_samples | INT | NULL, CHECK (n_samples > 0) | Number of samples in analysis | 150, 145, 138 | May be less than cohort size due to missing data |
| covariates_adjusted | TEXT | NULL | List of covariates adjusted for in multivariate analysis | 'age, sex, disease_stage, ECOG_PS', 'treatment_arm, baseline_tumor_size' | Semicolon or comma-separated list |
| association_direction | VARCHAR(50) | NULL | Direction of association | 'positive', 'negative', 'none', 'U-shaped', 'inverted-U' | Positive = higher biomarker → better outcome |
| clinical_significance | VARCHAR(255) | NULL | Clinical interpretation of association | 'Predictive of response to anti-PD-1', 'Prognostic for survival', 'No clinically meaningful association' | Brief clinical context |
| notes | TEXT | NULL | Additional methodological details or caveats | 'Continuous biomarker analyzed as log2-transformed', 'Stratified by treatment arm', 'Sensitivity analysis excluding outliers' | Free text for important details |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `association_id`
- FOREIGN KEY INDEX on `cohort_id`
- FOREIGN KEY INDEX on `biomarker_id`
- FOREIGN KEY INDEX on `endpoint_id`
- FOREIGN KEY INDEX on `dataset_id`
- COMPOSITE INDEX on (`biomarker_id`, `endpoint_id`) for biomarker-endpoint queries
- COMPOSITE INDEX on (`cohort_id`, `biomarker_id`, `endpoint_id`) for specific association queries
- COMPOSITE INDEX on (`biomarker_id`, `endpoint_id`, `p_value`) for significance filtering
- INDEX on `p_value` for filtering significant associations
- INDEX on `adjusted_p_value` for multiple testing corrected results
- INDEX on `association_direction` for directional filtering

**Relationships**:
- **Child of**: `patient_cohorts`, `biomarkers`, `endpoints`, `assay_datasets`
- **Parent to**: `stratified_outcomes`
- **Cardinality**: Potentially millions of records (cohorts × biomarkers × endpoints)

**Data Quality Checks**:
- `n_samples` should be ≤ cohort `sample_size`
- `adjusted_p_value` should be ≥ `p_value` (multiple testing correction increases p-values)
- `confidence_interval_lower` < `effect_size` < `confidence_interval_upper` (for most effect sizes)
- For hazard ratios and odds ratios, `effect_size` should be > 0
- `effect_size_type` should be appropriate for `analysis_type` and `statistical_test`
- If `analysis_type` = 'multivariate', `covariates_adjusted` should be populated
- `association_direction` should be consistent with sign of `effect_size`
- `p_value` should be consistent with confidence interval (CI excluding null → p < 0.05)

**Usage Examples**:
```sql
-- Find significant biomarker-endpoint associations
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    pc.cohort_name,
    bea.effect_size,
    bea.effect_size_type,
    bea.p_value,
    bea.adjusted_p_value,
    bea.n_samples
FROM biomarker_endpoint_associations bea
JOIN biomarkers b ON bea.biomarker_id = b.biomarker_id
JOIN endpoints e ON bea.endpoint_id = e.endpoint_id
JOIN patient_cohorts pc ON bea.cohort_id = pc.cohort_id
WHERE bea.adjusted_p_value < 0.05
ORDER BY bea.adjusted_p_value;

-- Get associations for a specific biomarker across all endpoints
SELECT 
    e.endpoint_name,
    e.endpoint_type,
    bea.effect_size,
    bea.effect_size_type,
    bea.confidence_interval_lower,
    bea.confidence_interval_upper,
    bea.p_value,
    bea.association_direction
FROM biomarker_endpoint_associations bea
JOIN endpoints e ON bea.endpoint_id = e.endpoint_id
WHERE bea.biomarker_id = 'PD_L1'
AND bea.cohort_id = 'NCT04567890_PDL1_HIGH'
ORDER BY bea.p_value;

-- Compare univariate vs multivariate associations
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    bea.analysis_type,
    bea.effect_size,
    bea.p_value,
    bea.covariates_adjusted
FROM biomarker_endpoint_associations bea
JOIN biomarkers b ON bea.biomarker_id = b.biomarker_id
JOIN endpoints e ON bea.endpoint_id = e.endpoint_id
WHERE bea.biomarker_id = 'TMB'
AND bea.endpoint_id = 'OS'
ORDER BY bea.analysis_type;

-- Find predictive biomarkers (positive association with efficacy)
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    bea.effect_size,
    bea.effect_size_type,
    bea.p_value,
    bea.clinical_significance
FROM biomarker_endpoint_associations bea
JOIN biomarkers b ON bea.biomarker_id = b.biomarker_id
JOIN endpoints e ON bea.endpoint_id = e.endpoint_id
WHERE e.endpoint_type = 'efficacy'
AND bea.association_direction = 'positive'
AND bea.adjusted_p_value < 0.05
ORDER BY bea.effect_size DESC;

-- Identify consistent associations across multiple cohorts
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    COUNT(DISTINCT bea.cohort_id) AS num_cohorts,
    AVG(bea.effect_size) AS avg_effect_size,
    MIN(bea.p_value) AS best_p_value,
    SUM(CASE WHEN bea.adjusted_p_value < 0.05 THEN 1 ELSE 0 END) AS num_significant
FROM biomarker_endpoint_associations bea
JOIN biomarkers b ON bea.biomarker_id = b.biomarker_id
JOIN endpoints e ON bea.endpoint_id = e.endpoint_id
GROUP BY b.biomarker_name, e.endpoint_name
HAVING num_cohorts >= 3
AND num_significant >= 2
ORDER BY avg_effect_size DESC;
```

---

### stratified_outcomes

**Purpose**: Stores clinical outcome rates stratified by biomarker levels (e.g., low/medium/high, quartiles, tertiles), enabling evaluation of dose-response relationships, identification of optimal cutpoints, and assessment of threshold robustness.

**Business Context**: Understanding how outcomes vary across biomarker strata is essential for threshold determination. This table reveals whether relationships are linear, threshold-based, or more complex. It supports data-driven cutpoint selection and demonstrates clinical utility across biomarker ranges.

**Data Sources**: Stratified survival analyses, subgroup analyses, quartile/tertile analyses, threshold optimization procedures.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| stratified_outcome_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this stratified outcome record | 1, 2, 3, ... | System-generated sequential ID |
| association_id | BIGINT | FOREIGN KEY (biomarker_endpoint_associations.association_id), NOT NULL | Links to parent biomarker-endpoint association | 12345, 67890 | Must exist in biomarker_endpoint_associations table |
| biomarker_stratum | VARCHAR(100) | NOT NULL | Label for biomarker stratum | 'low', 'medium', 'high', 'quartile_1', 'quartile_2', 'quartile_3', 'quartile_4', 'negative', 'positive', '<10', '10-50', '>50' | Descriptive stratum label |
| stratum_definition | TEXT | NULL | Detailed definition of stratum boundaries | 'PD-L1 TPS <1%', 'TMB 10-19.9 mutations/Mb', '25th-50th percentile', 'CD8+ T-cells ≥100 cells/mm²' | Explicit threshold values or percentile ranges |
| n_samples | INT | NULL, CHECK (n_samples >= 0) | Number of patients in this stratum | 50, 75, 100 | Should sum to total n_samples in parent association |
| n_positive_outcome | INT | NULL, CHECK (n_positive_outcome >= 0 AND n_positive_outcome <= n_samples) | Number with positive outcome in stratum | 20, 35, 60 | Definition of "positive" from parent endpoint |
| n_negative_outcome | INT | NULL, CHECK (n_negative_outcome >= 0 AND n_negative_outcome <= n_samples) | Number with negative outcome in stratum | 30, 40, 40 | Complement of n_positive_outcome for binary endpoints |
| outcome_rate | DECIMAL(5,4) | NULL, CHECK (outcome_rate >= 0 AND outcome_rate <= 1) | Proportion with positive outcome | 0.4000, 0.4667, 0.6000 | n_positive_outcome / n_samples |
| outcome_rate_ci_lower | DECIMAL(5,4) | NULL, CHECK (outcome_rate_ci_lower >= 0 AND outcome_rate_ci_lower <= 1) | Lower bound of 95% CI for outcome rate | 0.2800, 0.3500, 0.5000 | Typically 95% confidence interval |
| outcome_rate_ci_upper | DECIMAL(5,4) | NULL, CHECK (outcome_rate_ci_upper >= 0 AND outcome_rate_ci_upper <= 1) | Upper bound of 95% CI for outcome rate | 0.5200, 0.5834, 0.7000 | Should be > outcome_rate_ci_lower |
| median_outcome_value | DECIMAL(15,6) | NULL | Median value for continuous outcomes | 12.50000000, 18.30000000, 24.70000000 | For time-to-event or continuous endpoints |
| hazard_ratio | DECIMAL(10,6) | NULL, CHECK (hazard_ratio > 0) | Hazard ratio vs reference stratum | 1.00000000, 0.75000000, 0.55000000 | Reference stratum typically has HR = 1.0 |
| hazard_ratio_ci_lower | DECIMAL(10,6) | NULL, CHECK (hazard_ratio_ci_lower > 0) | Lower bound of 95% CI for hazard ratio | 1.00000000, 0.60000000, 0.42000000 | Typically 95% confidence interval |
| hazard_ratio_ci_upper | DECIMAL(10,6) | NULL, CHECK (hazard_ratio_ci_upper > 0) | Upper bound of 95% CI for hazard ratio | 1.00000000, 0.93750000, 0.72000000 | Should be > hazard_ratio_ci_lower |
| p_value | DECIMAL(15,10) | NULL, CHECK (p_value >= 0 AND p_value <= 1) | Statistical significance vs reference stratum | 1.0000000000, 0.0450000000, 0.0012345678 | Tests difference from reference group |

**Indexes**:
- PRIMARY KEY on `stratified_outcome_id`
- FOREIGN KEY INDEX on `association_id`
- COMPOSITE INDEX on (`association_id`, `biomarker_stratum`) for stratum-specific queries
- INDEX on `outcome_rate` for filtering by outcome prevalence
- INDEX on `p_value` for filtering significant strata

**Relationships**:
- **Child of**: `biomarker_endpoint_associations` (many strata to one association)
- **Cardinality**: Typically 2-5 strata per association (e.g., low/medium/high or quartiles)

**Data Quality Checks**:
- Sum of `n_samples` across all strata should equal `n_samples` in parent association
- `n_positive_outcome + n_negative_outcome` should equal `n_samples` for binary endpoints
- `outcome_rate` should equal `n_positive_outcome / n_samples`
- `outcome_rate_ci_lower` < `outcome_rate` < `outcome_rate_ci_upper`
- `hazard_ratio_ci_lower` < `hazard_ratio` < `hazard_ratio_ci_upper`
- At least one stratum should serve as reference (typically lowest stratum with HR = 1.0)
- Strata should be mutually exclusive and collectively exhaustive
- `stratum_definition` should clearly specify boundaries

**Usage Examples**:
```sql
-- Get outcome rates across biomarker strata
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    so.biomarker_stratum,
    so.stratum_definition,
    so.n_samples,
    so.outcome_rate,
    so.outcome_rate_ci_lower,
    so.outcome_rate_ci_upper
FROM stratified_outcomes so
JOIN biomarker_endpoint_associations bea ON so.association_id = bea.association_id
JOIN biomarkers b ON bea.biomarker_id = b.biomarker_id
JOIN endpoints e ON bea.endpoint_id = e.endpoint_id
WHERE bea.cohort_id = 'NCT04567890_PDL1_HIGH'
AND bea.biomarker_id = 'PD_L1'
AND bea.endpoint_id = 'ORR'
ORDER BY so.outcome_rate DESC;

-- Evaluate dose-response relationship
SELECT 
    so.biomarker_stratum,
    so.n_samples,
    so.median_outcome_value AS median_survival_months,
    so.hazard_ratio,
    so.hazard_ratio_ci_lower,
    so.hazard_ratio_ci_upper,
    so.p_value
FROM stratified_outcomes so
JOIN biomarker_endpoint_associations bea ON so.association_id = bea.association_id
WHERE bea.biomarker_id = 'TMB'
AND bea.endpoint_id = 'OS'
AND bea.cohort_id = 'NCT04567890_PDL1_HIGH'
ORDER BY so.hazard_ratio;

-- Identify optimal cutpoint (maximum separation between strata)
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    so.stratum_definition,
    so.outcome_rate,
    ABS(so.outcome_rate - LAG(so.outcome_rate) OVER (PARTITION BY so.association_id ORDER BY so.outcome_rate)) AS separation
FROM stratified_outcomes so
JOIN biomarker_endpoint_associations bea ON so.association_id = bea.association_id
JOIN biomarkers b ON bea.biomarker_id = b.biomarker_id
JOIN endpoints e ON bea.endpoint_id = e.endpoint_id
WHERE bea.cohort_id = 'NCT04567890_PDL1_HIGH'
ORDER BY separation DESC;

-- Compare outcomes between high and low biomarker strata
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    MAX(CASE WHEN so.biomarker_stratum = 'high' THEN so.outcome_rate END) AS high_outcome_rate,
    MAX(CASE WHEN so.biomarker_stratum = 'low' THEN so.outcome_rate END) AS low_outcome_rate,
    MAX(CASE WHEN so.biomarker_stratum = 'high' THEN so.outcome_rate END) - 
    MAX(CASE WHEN so.biomarker_stratum = 'low' THEN so.outcome_rate END) AS absolute_difference
FROM stratified_outcomes so
JOIN biomarker_endpoint_associations bea ON so.association_id = bea.association_id
JOIN biomarkers b ON bea.biomarker_id = b.biomarker_id
JOIN endpoints e ON bea.endpoint_id = e.endpoint_id
WHERE so.biomarker_stratum IN ('high', 'low')
GROUP BY b.biomarker_name, e.endpoint_name
HAVING absolute_difference > 0.2
ORDER BY absolute_difference DESC;
```

---

## Classification Tables

### classification_models

**Purpose**: Central registry of all classification models with comprehensive versioning, metadata, and lifecycle tracking. This table documents model development, validation status, and deployment history.

**Business Context**: Classification models convert continuous biomarker measurements or multi-biomarker signatures into binary predictions (positive/negative, responder/non-responder). This table supports model governance, reproducibility, regulatory submissions, and model comparison. Each model version is tracked separately to maintain a complete audit trail.

**Data Sources**: Model development documentation, validation reports, model training scripts, regulatory submission packages.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| model_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for the model version | 'PDL1_LR_V1.0', 'TMB_RF_V2.3', 'MULTIBIO_NN_V1.5' | Combine biomarker, algorithm, and version |
| model_name | VARCHAR(255) | NOT NULL | Descriptive name of the model | 'PD-L1 Logistic Regression Classifier', 'TMB Random Forest Model', 'Multi-Biomarker Neural Network' | Human-readable model name |
| model_version | VARCHAR(50) | NOT NULL | Version number of the model | 'v1.0', 'v2.3', 'v1.5_beta' | Semantic versioning recommended (major.minor.patch) |
| model_type | VARCHAR(100) | NULL | Classification algorithm type | 'logistic_regression', 'random_forest', 'SVM', 'neural_network', 'gradient_boosting', 'threshold_based', 'decision_tree', 'naive_bayes' | Standardized algorithm names |
| algorithm_details | TEXT | NULL | Detailed description of algorithm implementation | 'L2-regularized logistic regression with C=1.0, max_iter=1000, solver=lbfgs', 'Random Forest with 500 trees, max_depth=10, min_samples_split=20' | Include hyperparameters and implementation details |
| training_cohorts | TEXT | NULL | List of cohort IDs used for model training | 'NCT04567890_ARM_A, NCT04567890_ARM_B, KEYNOTE001_NSCLC', 'Cohorts from 3 trials: NCT123, NCT456, NCT789' | Semicolon or comma-separated cohort_ids |
| training_sample_size | INT | NULL, CHECK (training_sample_size > 0) | Total number of samples used for training | 500, 1200, 2500 | Sum across all training cohorts |
| development_date | DATE | NULL | Date when model was developed | '2023-06-15', '2024-01-20' | Model creation date |
| validation_status | VARCHAR(50) | NULL | Current validation and deployment status | 'development', 'internal_validation', 'external_validation', 'production', 'retired', 'deprecated' | Lifecycle stage of model |
| intended_use | TEXT | NULL | Description of model's intended clinical application | 'Predict response to anti-PD-1 therapy in NSCLC patients', 'Identify patients likely to benefit from immunotherapy' | Clinical context and target population |
| model_features | JSON | NULL | List of input features (biomarkers) and their roles | `[{"biomarker_id": "PD_L1", "transformation": "log2", "role": "predictor"}, {"biomarker_id": "TMB", "transformation": "sqrt", "role": "predictor"}]` | Structured feature specification |
| hyperparameters | JSON | NULL | Model hyperparameters and configuration | `{"learning_rate": 0.01, "n_estimators": 500, "max_depth": 10, "min_samples_split": 20}` | Algorithm-specific parameters |
| feature_importance | JSON | NULL | Variable importance scores for each feature | `{"PD_L1": 0.45, "TMB": 0.32, "CD8A": 0.15, "IFNG": 0.08}` | Relative importance of predictors |
| model_file_path | VARCHAR(500) | NULL | File system path or URL to serialized model | '/models/pdl1_lr_v1.0.pkl', 's3://bucket/models/tmb_rf_v2.3.h5' | Location of saved model object |
| created_by | VARCHAR(255) | NULL | User or team who developed the model | 'John Doe', 'Biomarker Analytics Team', 'External Vendor XYZ' | Model developer identification |
| approved_by | VARCHAR(255) | NULL | User who approved model for production use | 'Jane Smith', 'Medical Director', 'Regulatory Affairs' | Approval authority |
| approval_date | DATE | NULL | Date when model was approved for production | '2023-08-20', '2024-03-15' | Production approval date |
| is_active | BOOLEAN | DEFAULT TRUE | Whether model is currently in use | TRUE, FALSE | FALSE for retired or superseded models |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `model_id`
- COMPOSITE INDEX on (`model_name`, `model_version`) for version queries
- INDEX on `model_type` for algorithm-based filtering
- INDEX on `validation_status` for lifecycle filtering
- INDEX on `is_active` for active model queries
- INDEX on `development_date` for temporal analyses

**Relationships**:
- **Parent to**: `biomarker_thresholds`, `cohort_classifications`, `model_validations`, `cross_trial_validations`
- **Cardinality**: Typically 10-100 models across database

**Data Quality Checks**:
- Combination of `model_name` and `model_version` should be unique
- `model_id` should be unique and descriptive
- If `validation_status` = 'production', `approved_by` and `approval_date` should be populated
- `training_sample_size` should be reasonable for model complexity (e.g., ≥100 for simple models, ≥1000 for complex)
- `model_features` JSON should be valid and contain at least one predictor
- If `is_active` = FALSE, there should be a newer version with `is_active` = TRUE (or model is retired)
- `hyperparameters` should be appropriate for `model_type`

**Usage Examples**:
```sql
-- Get all active production models
SELECT 
    model_name,
    model_version,
    model_type,
    training_sample_size,
    approval_date,
    intended_use
FROM classification_models
WHERE is_active = TRUE
AND validation_status = 'production'
ORDER BY approval_date DESC;

-- Compare model versions
SELECT 
    model_name,
    model_version,
    development_date,
    training_sample_size,
    validation_status,
    JSON_EXTRACT(feature_importance, '$.PD_L1') AS pdl1_importance
FROM classification_models
WHERE model_name LIKE '%PD-L1%'
ORDER BY development_date DESC;

-- Find models using a specific biomarker
SELECT 
    model_id,
    model_name,
    model_version,
    model_features
FROM classification_models
WHERE JSON_CONTAINS(model_features, JSON_OBJECT('biomarker_id', 'TMB'))
AND is_active = TRUE;

-- Get model development timeline
SELECT 
    model_name,
    model_version,
    development_date,
    validation_status,
    approval_date,
    DATEDIFF(approval_date, development_date) AS days_to_approval
FROM classification_models
WHERE approval_date IS NOT NULL
ORDER BY development_date DESC;

-- Find recently retired models
SELECT 
    model_name,
    model_version,
    validation_status,
    created_at,
    created_by
FROM classification_models
WHERE is_active = FALSE
AND validation_status = 'retired'
ORDER BY created_at DESC;
```

---

### biomarker_thresholds

**Purpose**: Defines cutpoints for converting continuous biomarker measurements into binary classifications (positive/negative, high/low). This table documents threshold derivation methods, performance metrics, and validity periods.

**Business Context**: Thresholds are critical decision points that determine patient classification. This table supports threshold optimization, validation, updating, and regulatory documentation. Each threshold is linked to a specific model, endpoint, and derivation cohort, enabling traceability and appropriate application.

**Data Sources**: ROC analysis outputs, Youden index calculations, clinical cutpoint studies, percentile analyses, threshold optimization algorithms.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| threshold_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for the threshold | 'PDL1_OS_50PCT', 'TMB_PFS_10MUT', 'CD8_ORR_MEDIAN' | Combine biomarker, endpoint, and threshold value |
| biomarker_id | VARCHAR(50) | FOREIGN KEY (biomarkers.biomarker_id), NOT NULL | Links to biomarker | 'PD_L1', 'TMB', 'CD8A_EXPRESSION' | Must exist in biomarkers table |
| endpoint_id | VARCHAR(50) | FOREIGN KEY (endpoints.endpoint_id), NOT NULL | Links to predicted endpoint | 'OS', 'PFS', 'ORR' | Must exist in endpoints table |
| model_id | VARCHAR(50) | FOREIGN KEY (classification_models.model_id), NOT NULL | Links to classification model | 'PDL1_LR_V1.0', 'TMB_THRESHOLD_V2.0' | Must exist in classification_models table |
| threshold_type | VARCHAR(50) | NULL | Method used to derive threshold | 'optimal', 'percentile', 'clinical', 'ROC_based', 'youden', 'fixed_sensitivity', 'fixed_specificity' | Classification of threshold derivation approach |
| threshold_value | DECIMAL(20,8) | NOT NULL | Cutpoint value for classification | 50.00000000, 10.00000000, 145.50000000 | Values ≥ threshold are classified as positive |
| threshold_unit | VARCHAR(50) | NULL | Unit of measurement for threshold | 'percent', 'mutations/Mb', 'TPM', 'H-score' | Should match biomarker measurement_unit |
| percentile_rank | DECIMAL(5,2) | NULL, CHECK (percentile_rank >= 0 AND percentile_rank <= 100) | Percentile corresponding to threshold | 50.00, 75.00, 90.00 | For percentile-based thresholds |
| derivation_cohorts | TEXT | NULL | Cohort IDs used to derive this threshold | 'NCT04567890_ARM_A, KEYNOTE001_NSCLC', 'Training cohorts from 5 trials' | Semicolon or comma-separated cohort_ids |
| derivation_sample_size | INT | NULL, CHECK (derivation_sample_size > 0) | Total samples used for threshold derivation | 500, 1200, 2500 | Sum across derivation cohorts |
| sensitivity | DECIMAL(5,4) | NULL, CHECK (sensitivity >= 0 AND sensitivity <= 1) | Sensitivity at this threshold | 0.8500, 0.7200, 0.9100 | True positive rate |
| specificity | DECIMAL(5,4) | NULL, CHECK (specificity >= 0 AND specificity <= 1) | Specificity at this threshold | 0.7800, 0.8500, 0.6500 | True negative rate |
| ppv | DECIMAL(5,4) | NULL, CHECK (ppv >= 0 AND ppv <= 1) | Positive predictive value | 0.7500, 0.8200, 0.6800 | Proportion of positives that are true positives |
| npv | DECIMAL(5,4) | NULL, CHECK (npv >= 0 AND npv <= 1) | Negative predictive value | 0.8200, 0.7500, 0.9000 | Proportion of negatives that are true negatives |
| accuracy | DECIMAL(5,4) | NULL, CHECK (accuracy >= 0 AND accuracy <= 1) | Overall classification accuracy | 0.8100, 0.7850, 0.8400 | (TP + TN) / (TP + TN + FP + FN) |
| auc_roc | DECIMAL(5,4) | NULL, CHECK (auc_roc >= 0 AND auc_roc <= 1) | Area under ROC curve | 0.7800, 0.8500, 0.7200 | Discriminatory ability; 0.5 = random, 1.0 = perfect |
| confidence_interval_lower | DECIMAL(20,8) | NULL | Lower bound of 95% CI for threshold | 45.00000000, 8.50000000, 130.00000000 | Uncertainty in threshold estimate |
| confidence_interval_upper | DECIMAL(20,8) | NULL | Upper bound of 95% CI for threshold | 55.00000000, 12.00000000, 160.00000000 | Should be > confidence_interval_lower |
| determination_method | TEXT | NULL | Detailed description of threshold derivation | 'Youden index maximization from ROC analysis', 'Median split in training cohort', 'Clinical consensus based on published literature' | Methodology documentation |
| clinical_rationale | TEXT | NULL | Clinical justification for threshold selection | 'Balances sensitivity and specificity for treatment selection', 'Aligns with FDA-approved companion diagnostic', 'Maximizes benefit-risk ratio' | Clinical context and decision rationale |
| effective_date | DATE | NULL | Date when threshold becomes valid | '2023-09-01', '2024-01-15' | Start of validity period |
| expiration_date | DATE | NULL | Date when threshold is no longer valid | '2025-12-31', NULL | NULL for indefinite validity |
| is_active | BOOLEAN | DEFAULT TRUE | Whether threshold is currently in use | TRUE, FALSE | FALSE for superseded or expired thresholds |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `threshold_id`
- FOREIGN KEY INDEX on `biomarker_id`
- FOREIGN KEY INDEX on `endpoint_id`
- FOREIGN KEY INDEX on `model_id`
- COMPOSITE INDEX on (`biomarker_id`, `endpoint_id`) for biomarker-endpoint threshold queries
- COMPOSITE INDEX on (`biomarker_id`, `endpoint_id`, `is_active`) for active threshold queries
- INDEX on `is_active` for filtering current thresholds
- INDEX on `effective_date` for temporal queries
- INDEX on `auc_roc` for performance-based filtering

**Relationships**:
- **Child of**: `biomarkers`, `endpoints`, `classification_models`
- **Parent to**: `cohort_classifications`
- **Cardinality**: Typically 1-10 thresholds per biomarker-endpoint pair (different derivation methods, versions)

**Data Quality Checks**:
- `threshold_value` should be within plausible range for biomarker
- `confidence_interval_lower` < `threshold_value` < `confidence_interval_upper`
- `sensitivity + specificity` should be > 1.0 for useful thresholds
- `effective_date` should be ≤ `expiration_date` if both present
- If `is_active` = TRUE, `effective_date` should be ≤ current date
- If `expiration_date` < current date, `is_active` should be FALSE
- `threshold_unit` should match biomarker `measurement_unit`
- `auc_roc` should be > 0.5 for predictive thresholds
- For percentile-based thresholds, `percentile_rank` should be populated

**Usage Examples**:
```sql
-- Get active thresholds for a biomarker
SELECT 
    bt.threshold_id,
    e.endpoint_name,
    bt.threshold_value,
    bt.threshold_unit,
    bt.sensitivity,
    bt.specificity,
    bt.auc_roc,
    bt.clinical_rationale
FROM biomarker_thresholds bt
JOIN endpoints e ON bt.endpoint_id = e.endpoint_id
WHERE bt.biomarker_id = 'PD_L1'
AND bt.is_active = TRUE
ORDER BY e.endpoint_name;

-- Compare threshold performance metrics
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    bt.threshold_type,
    bt.threshold_value,
    bt.sensitivity,
    bt.specificity,
    bt.accuracy,
    bt.auc_roc,
    (bt.sensitivity + bt.specificity - 1) AS youden_index
FROM biomarker_thresholds bt
JOIN biomarkers b ON bt.biomarker_id = b.biomarker_id
JOIN endpoints e ON bt.endpoint_id = e.endpoint_id
WHERE bt.is_active = TRUE
ORDER BY youden_index DESC;

-- Find high-performing thresholds
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    bt.threshold_value,
    bt.threshold_unit,
    bt.auc_roc,
    bt.sensitivity,
    bt.specificity,
    bt.derivation_sample_size
FROM biomarker_thresholds bt
JOIN biomarkers b ON bt.biomarker_id = b.biomarker_id
JOIN endpoints e ON bt.endpoint_id = e.endpoint_id
WHERE bt.auc_roc >= 0.75
AND bt.sensitivity >= 0.70
AND bt.specificity >= 0.70
AND bt.is_active = TRUE
ORDER BY bt.auc_roc DESC;

-- Track threshold evolution over time
SELECT 
    bt.threshold_id,
    bt.threshold_value,
    bt.effective_date,
    bt.expiration_date,
    bt.auc_roc,
    bt.derivation_sample_size,
    bt.is_active
FROM biomarker_thresholds bt
WHERE bt.biomarker_id = 'TMB'
AND bt.endpoint_id = 'PFS'
ORDER BY bt.effective_date DESC;

-- Identify thresholds needing update (expiring soon)
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    bt.threshold_value,
    bt.expiration_date,
    DATEDIFF(bt.expiration_date, CURRENT_DATE) AS days_until_expiration
FROM biomarker_thresholds bt
JOIN biomarkers b ON bt.biomarker_id = b.biomarker_id
JOIN endpoints e ON bt.endpoint_id = e.endpoint_id
WHERE bt.is_active = TRUE
AND bt.expiration_date IS NOT NULL
AND bt.expiration_date <= DATE_ADD(CURRENT_DATE, INTERVAL 90 DAY)
ORDER BY bt.expiration_date;
```

---

Due to length constraints, I'll continue with the remaining tables. Would you like me to proceed with:

1. **biomarker_signatures** - Multi-biomarker composite scores
2. **signature_components** - Individual biomarkers within signatures
3. **cohort_classifications** - Classification results at cohort level
4. **classification_performance_by_status** - Performance by biomarker status
5. **model_validations** - Comprehensive validation results
6. **cross_trial_validations** - Cross-trial performance tracking
7. **meta_analysis_results** - Pooled analyses across studies
8. **data_provenance** - Data lineage and quality tracking
9. **audit_log** - Complete change history
10. **data_quality_issues** - Quality issue management
11. **user_access_log** - Access tracking and security

Shall I continue with these remaining tables?

# Comprehensive Table and Column Specifications (Continued)

## Classification Tables (Continued)

### biomarker_signatures

**Purpose**: Defines multi-biomarker composite scores, risk indices, or gene expression signatures that combine multiple individual biomarkers into a single predictive score. This table documents signature composition, calculation methodology, and intended clinical use.

**Business Context**: Many clinical scenarios require integration of multiple biomarkers to achieve adequate predictive performance. Signatures can represent biological pathways, immune profiles, or empirically-derived risk scores. This table supports complex multi-marker classifiers and enables signature versioning and validation tracking.

**Data Sources**: Signature development studies, published gene signatures (e.g., Oncotype DX, MammaPrint), pathway analysis results, machine learning feature selection outputs.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| signature_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for the signature | 'IMMUNE_INFLAM_SIG_V1', 'TGFB_PATHWAY_SCORE', 'CUSTOM_RISK_INDEX_V2' | Descriptive ID combining signature name and version |
| signature_name | VARCHAR(255) | NOT NULL | Descriptive name of the signature | 'Immune Inflammation Signature', 'TGF-β Pathway Score', 'Custom 10-Gene Risk Index' | Human-readable signature name |
| signature_version | VARCHAR(50) | NULL | Version number of the signature | 'v1.0', 'v2.3', 'v1.5_updated' | Semantic versioning for signature evolution |
| description | TEXT | NULL | Detailed description of signature purpose and composition | 'Composite score of 18 immune-related genes measuring tumor inflammation', 'Pathway activity score based on TGF-β signaling genes' | Comprehensive signature documentation |
| signature_type | VARCHAR(100) | NULL | Classification of signature methodology | 'composite_score', 'risk_score', 'predictive_index', 'gene_expression_signature', 'pathway_score', 'immune_signature', 'weighted_sum' | Standardized signature categories |
| calculation_formula | TEXT | NULL | Mathematical formula for calculating signature score | 'log2(mean(gene1, gene2, gene3)) - log2(mean(gene4, gene5))', 'w1*biomarker1 + w2*biomarker2 + ... + intercept', 'Weighted sum of standardized z-scores' | Explicit calculation methodology |
| intended_endpoint | VARCHAR(255) | NULL | Primary endpoint the signature predicts | 'Overall Survival', 'Response to Immunotherapy', 'Risk of Recurrence' | Clinical outcome of interest |
| development_cohorts | TEXT | NULL | Cohort IDs used for signature development | 'NCT04567890_ARM_A, KEYNOTE001_NSCLC, CHECKMATE067_MEL', 'Training set from 5 trials (n=2,500)' | Semicolon or comma-separated cohort_ids |
| validation_cohorts | TEXT | NULL | Cohort IDs used for signature validation | 'NCT98765432_ARM_B, IMpower150_NSCLC', 'Independent validation in 3 trials (n=1,200)' | Semicolon or comma-separated cohort_ids |
| clinical_utility | TEXT | NULL | Description of clinical application and decision-making context | 'Identifies patients with >50% response probability to anti-PD-1 therapy', 'Stratifies patients into low/intermediate/high risk groups for treatment selection' | Clinical interpretation and use case |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `signature_id`
- INDEX on `signature_name` for name-based queries
- INDEX on `signature_type` for filtering by signature category
- FULLTEXT INDEX on `signature_name`, `description` for search functionality

**Relationships**:
- **Parent to**: `signature_components`, `cohort_classifications`
- **Cardinality**: Typically 10-100 signatures across database

**Data Quality Checks**:
- `signature_id` should be unique and descriptive
- Combination of `signature_name` and `signature_version` should be unique
- `calculation_formula` should be explicit and reproducible
- `signature_type` should use controlled vocabulary
- At least one of `development_cohorts` or `validation_cohorts` should be populated
- Signature should have at least 2 components in `signature_components` table
- `intended_endpoint` should correspond to an endpoint_id in endpoints table

**Usage Examples**:
```sql
-- Get all active signatures with their descriptions
SELECT 
    signature_id,
    signature_name,
    signature_version,
    signature_type,
    description,
    intended_endpoint
FROM biomarker_signatures
ORDER BY signature_name, signature_version DESC;

-- Find immune-related signatures
SELECT 
    signature_name,
    signature_type,
    description,
    clinical_utility
FROM biomarker_signatures
WHERE signature_type LIKE '%immune%'
OR description LIKE '%immune%'
OR signature_name LIKE '%immune%'
ORDER BY signature_name;

-- Get signatures for a specific endpoint
SELECT 
    signature_name,
    signature_version,
    signature_type,
    development_cohorts,
    validation_cohorts
FROM biomarker_signatures
WHERE intended_endpoint LIKE '%Survival%'
ORDER BY signature_name;

-- Compare signature versions
SELECT 
    signature_name,
    signature_version,
    created_at,
    calculation_formula
FROM biomarker_signatures
WHERE signature_name = 'Immune Inflammation Signature'
ORDER BY created_at DESC;
```

---

### signature_components

**Purpose**: Defines the individual biomarkers that comprise each multi-biomarker signature, including their weights, transformations, and order in the calculation. This table enables signature calculation, interpretation, and component-level analysis.

**Business Context**: Understanding signature composition is essential for biological interpretation, quality control, and regulatory documentation. This table documents exactly which biomarkers contribute to each signature and how they are mathematically combined.

**Data Sources**: Signature development protocols, feature selection outputs, published signature specifications, pathway databases.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| signature_component_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this component record | 1, 2, 3, ... | System-generated sequential ID |
| signature_id | VARCHAR(50) | FOREIGN KEY (biomarker_signatures.signature_id), NOT NULL | Links to parent signature | 'IMMUNE_INFLAM_SIG_V1', 'TGFB_PATHWAY_SCORE' | Must exist in biomarker_signatures table |
| biomarker_id | VARCHAR(50) | FOREIGN KEY (biomarkers.biomarker_id), NOT NULL | Links to component biomarker | 'CD8A_EXPRESSION', 'IFNG_EXPRESSION', 'PD_L1' | Must exist in biomarkers table |
| weight_coefficient | DECIMAL(10,6) | NULL | Numerical weight for this biomarker in signature calculation | 0.450000, -0.230000, 1.000000, 0.000000 | Positive weights increase score; negative weights decrease score |
| component_order | INT | NULL, CHECK (component_order > 0) | Order of biomarker in signature calculation | 1, 2, 3, ..., 18 | Sequential ordering for calculation |
| transformation | VARCHAR(100) | NULL | Mathematical transformation applied before weighting | 'log', 'log2', 'log10', 'sqrt', 'standardize', 'z-score', 'none', 'rank' | Preprocessing transformation |

**Indexes**:
- PRIMARY KEY on `signature_component_id`
- FOREIGN KEY INDEX on `signature_id`
- FOREIGN KEY INDEX on `biomarker_id`
- COMPOSITE INDEX on (`signature_id`, `component_order`) for ordered component retrieval
- COMPOSITE INDEX on (`signature_id`, `biomarker_id`) for component lookup
- INDEX on `weight_coefficient` for filtering by importance

**Relationships**:
- **Child of**: `biomarker_signatures`, `biomarkers`
- **Cardinality**: Typically 2-50 components per signature

**Data Quality Checks**:
- Each `signature_id` should have at least 2 components
- `component_order` should be sequential within each signature (1, 2, 3, ...)
- No duplicate `biomarker_id` within the same `signature_id`
- `weight_coefficient` should not be zero (zero-weight components should be excluded)
- Sum of absolute weights within a signature should be > 0
- `transformation` should use controlled vocabulary
- All component biomarkers should be measurable in the same assay platform

**Usage Examples**:
```sql
-- Get all components of a specific signature
SELECT 
    sc.component_order,
    b.biomarker_name,
    sc.weight_coefficient,
    sc.transformation
FROM signature_components sc
JOIN biomarkers b ON sc.biomarker_id = b.biomarker_id
WHERE sc.signature_id = 'IMMUNE_INFLAM_SIG_V1'
ORDER BY sc.component_order;

-- Find signatures containing a specific biomarker
SELECT 
    bs.signature_name,
    bs.signature_version,
    sc.weight_coefficient,
    sc.transformation
FROM signature_components sc
JOIN biomarker_signatures bs ON sc.signature_id = bs.signature_id
WHERE sc.biomarker_id = 'PD_L1'
ORDER BY ABS(sc.weight_coefficient) DESC;

-- Identify most important components by weight
SELECT 
    bs.signature_name,
    b.biomarker_name,
    sc.weight_coefficient,
    ABS(sc.weight_coefficient) AS absolute_weight
FROM signature_components sc
JOIN biomarker_signatures bs ON sc.signature_id = bs.signature_id
JOIN biomarkers b ON sc.biomarker_id = b.biomarker_id
WHERE sc.signature_id = 'IMMUNE_INFLAM_SIG_V1'
ORDER BY absolute_weight DESC
LIMIT 5;

-- Compare component composition across signature versions
SELECT 
    bs.signature_version,
    b.biomarker_name,
    sc.weight_coefficient,
    sc.component_order
FROM signature_components sc
JOIN biomarker_signatures bs ON sc.signature_id = bs.signature_id
JOIN biomarkers b ON sc.biomarker_id = b.biomarker_id
WHERE bs.signature_name = 'Immune Inflammation Signature'
ORDER BY bs.signature_version, sc.component_order;

-- Calculate signature complexity (number of components)
SELECT 
    bs.signature_name,
    bs.signature_version,
    COUNT(*) AS num_components,
    SUM(ABS(sc.weight_coefficient)) AS total_weight
FROM signature_components sc
JOIN biomarker_signatures bs ON sc.signature_id = bs.signature_id
GROUP BY bs.signature_name, bs.signature_version
ORDER BY num_components DESC;
```

---

### cohort_classifications

**Purpose**: Stores aggregated classification results at the cohort level, documenting how many patients in each cohort were classified as biomarker-positive, biomarker-negative, or indeterminate. This table represents the application of classification models and thresholds to patient populations.

**Business Context**: This table captures the output of biomarker classification processes, showing the distribution of classifications within cohorts. It enables assessment of biomarker prevalence, classification rates across populations, and serves as input for clinical utility analyses.

**Data Sources**: Classification algorithm outputs, threshold application results, diagnostic test results, clinical laboratory reports.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| cohort_classification_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this classification record | 1, 2, 3, ... | System-generated sequential ID |
| cohort_id | VARCHAR(50) | FOREIGN KEY (patient_cohorts.cohort_id), NOT NULL | Links to classified cohort | 'NCT04567890_PDL1_HIGH', 'KEYNOTE001_NSCLC' | Must exist in patient_cohorts table |
| biomarker_id | VARCHAR(50) | FOREIGN KEY (biomarkers.biomarker_id), NULL | Single biomarker used for classification | 'PD_L1', 'TMB', 'CD8A_EXPRESSION' | NULL if signature_id is used; one of biomarker_id or signature_id must be NOT NULL |
| signature_id | VARCHAR(50) | FOREIGN KEY (biomarker_signatures.signature_id), NULL | Multi-biomarker signature used for classification | 'IMMUNE_INFLAM_SIG_V1', 'TGFB_PATHWAY_SCORE' | NULL if biomarker_id is used; one of biomarker_id or signature_id must be NOT NULL |
| endpoint_id | VARCHAR(50) | FOREIGN KEY (endpoints.endpoint_id), NOT NULL | Endpoint being predicted | 'OS', 'PFS', 'ORR' | Must exist in endpoints table |
| model_id | VARCHAR(50) | FOREIGN KEY (classification_models.model_id), NOT NULL | Classification model applied | 'PDL1_LR_V1.0', 'TMB_THRESHOLD_V2.0' | Must exist in classification_models table |
| threshold_id | VARCHAR(50) | FOREIGN KEY (biomarker_thresholds.threshold_id), NULL | Threshold applied (if threshold-based classification) | 'PDL1_OS_50PCT', 'TMB_PFS_10MUT' | NULL for non-threshold models; must exist in biomarker_thresholds table if specified |
| classification_date | DATE | NOT NULL | Date when classification was performed | '2024-01-15', '2023-06-20' | Date of classification analysis |
| total_samples | INT | NOT NULL, CHECK (total_samples > 0) | Total number of samples classified | 150, 200, 85 | Should be ≤ cohort sample_size |
| n_positive | INT | NULL, CHECK (n_positive >= 0 AND n_positive <= total_samples) | Number classified as biomarker-positive | 75, 120, 45 | Count of positive classifications |
| n_negative | INT | NULL, CHECK (n_negative >= 0 AND n_negative <= total_samples) | Number classified as biomarker-negative | 70, 75, 38 | Count of negative classifications |
| n_indeterminate | INT | NULL, CHECK (n_indeterminate >= 0 AND n_indeterminate <= total_samples) | Number with indeterminate classification | 5, 5, 2 | Count of indeterminate results (e.g., borderline values, QC failures) |
| positive_rate | DECIMAL(5,4) | NULL, CHECK (positive_rate >= 0 AND positive_rate <= 1) | Proportion classified as positive | 0.5000, 0.6000, 0.5294 | n_positive / total_samples |
| positive_rate_ci_lower | DECIMAL(5,4) | NULL, CHECK (positive_rate_ci_lower >= 0 AND positive_rate_ci_lower <= 1) | Lower bound of 95% CI for positive rate | 0.4200, 0.5300, 0.4100 | Typically 95% confidence interval |
| positive_rate_ci_upper | DECIMAL(5,4) | NULL, CHECK (positive_rate_ci_upper >= 0 AND positive_rate_ci_upper <= 1) | Upper bound of 95% CI for positive rate | 0.5800, 0.6700, 0.6487 | Should be > positive_rate_ci_lower |
| mean_predicted_probability | DECIMAL(5,4) | NULL, CHECK (mean_predicted_probability >= 0 AND mean_predicted_probability <= 1) | Average predicted probability across cohort | 0.5500, 0.6200, 0.4800 | For probabilistic models; mean of individual probabilities |
| median_predicted_probability | DECIMAL(5,4) | NULL, CHECK (median_predicted_probability >= 0 AND median_predicted_probability <= 1) | Median predicted probability across cohort | 0.5200, 0.6500, 0.4500 | Robust central tendency for probabilities |
| mean_biomarker_value | DECIMAL(20,8) | NULL | Mean biomarker value in classified cohort | 55.67890123, 12.34567890, 145.67890123 | Average of biomarker measurements |
| threshold_used | DECIMAL(20,8) | NULL | Actual threshold value applied | 50.00000000, 10.00000000, 145.00000000 | Cutpoint for positive/negative classification |
| classification_method | VARCHAR(100) | NULL | Method used for classification | 'threshold_based', 'model_based', 'composite', 'probabilistic', 'rule_based' | Classification approach |
| quality_flags | TEXT | NULL | Quality control flags or warnings | 'High missing data rate', '5 samples excluded due to QC failure', 'Borderline threshold performance' | Free text for QC issues |
| notes | TEXT | NULL | Additional context or methodological details | 'Classification based on baseline measurements', 'Excluded patients with prior therapy', 'Used imputation for missing values' | Free text for important details |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `cohort_classification_id`
- FOREIGN KEY INDEX on `cohort_id`
- FOREIGN KEY INDEX on `biomarker_id`
- FOREIGN KEY INDEX on `signature_id`
- FOREIGN KEY INDEX on `endpoint_id`
- FOREIGN KEY INDEX on `model_id`
- FOREIGN KEY INDEX on `threshold_id`
- COMPOSITE INDEX on (`cohort_id`, `endpoint_id`) for cohort-endpoint queries
- COMPOSITE INDEX on (`biomarker_id`, `endpoint_id`) for biomarker-endpoint queries
- COMPOSITE INDEX on (`cohort_id`, `biomarker_id`, `endpoint_id`) for specific classification queries
- INDEX on `classification_date` for temporal analyses
- INDEX on `positive_rate` for filtering by prevalence

**Relationships**:
- **Child of**: `patient_cohorts`, `biomarkers`, `biomarker_signatures`, `endpoints`, `classification_models`, `biomarker_thresholds`
- **Parent to**: `classification_performance_by_status`
- **Cardinality**: Potentially thousands of records (cohorts × biomarkers/signatures × endpoints)

**Data Quality Checks**:
- Exactly one of `biomarker_id` or `signature_id` should be NOT NULL
- `n_positive + n_negative + n_indeterminate` should equal `total_samples`
- `total_samples` should be ≤ cohort `sample_size`
- `positive_rate` should equal `n_positive / total_samples`
- `positive_rate_ci_lower` < `positive_rate` < `positive_rate_ci_upper`
- If `threshold_id` is specified, `threshold_used` should match threshold value in biomarker_thresholds
- `classification_method` should be consistent with `model_id` type
- `mean_predicted_probability` should be between 0 and 1 for probabilistic models
- If `biomarker_id` is specified, `mean_biomarker_value` should be populated

**Usage Examples**:
```sql
-- Get classification results for a cohort
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    cc.total_samples,
    cc.n_positive,
    cc.n_negative,
    cc.positive_rate,
    cc.positive_rate_ci_lower,
    cc.positive_rate_ci_upper,
    cm.model_name
FROM cohort_classifications cc
JOIN biomarkers b ON cc.biomarker_id = b.biomarker_id
JOIN endpoints e ON cc.endpoint_id = e.endpoint_id
JOIN classification_models cm ON cc.model_id = cm.model_id
WHERE cc.cohort_id = 'NCT04567890_PDL1_HIGH'
ORDER BY e.endpoint_name;

-- Compare positive rates across cohorts for a biomarker
SELECT 
    pc.cohort_name,
    ct.trial_name,
    cc.total_samples,
    cc.positive_rate,
    cc.positive_rate_ci_lower,
    cc.positive_rate_ci_upper,
    cc.mean_biomarker_value
FROM cohort_classifications cc
JOIN patient_cohorts pc ON cc.cohort_id = pc.cohort_id
JOIN clinical_trials ct ON pc.trial_id = ct.trial_id
WHERE cc.biomarker_id = 'PD_L1'
AND cc.endpoint_id = 'ORR'
ORDER BY cc.positive_rate DESC;

-- Find cohorts with high biomarker-positive rates
SELECT 
    b.biomarker_name,
    pc.cohort_name,
    e.endpoint_name,
    cc.positive_rate,
    cc.total_samples
FROM cohort_classifications cc
JOIN biomarkers b ON cc.biomarker_id = b.biomarker_id
JOIN patient_cohorts pc ON cc.cohort_id = pc.cohort_id
JOIN endpoints e ON cc.endpoint_id = e.endpoint_id
WHERE cc.positive_rate >= 0.7
AND cc.total_samples >= 50
ORDER BY cc.positive_rate DESC;

-- Track classification over time
SELECT 
    cc.classification_date,
    b.biomarker_name,
    cc.positive_rate,
    cc.total_samples,
    cm.model_version
FROM cohort_classifications cc
JOIN biomarkers b ON cc.biomarker_id = b.biomarker_id
JOIN classification_models cm ON cc.model_id = cm.model_id
WHERE cc.cohort_id = 'NCT04567890_PDL1_HIGH'
AND cc.endpoint_id = 'OS'
ORDER BY cc.classification_date DESC;

-- Identify classifications with quality issues
SELECT 
    b.biomarker_name,
    pc.cohort_name,
    cc.total_samples,
    cc.n_indeterminate,
    ROUND(100.0 * cc.n_indeterminate / cc.total_samples, 2) AS indeterminate_percent,
    cc.quality_flags
FROM cohort_classifications cc
JOIN biomarkers b ON cc.biomarker_id = b.biomarker_id
JOIN patient_cohorts pc ON cc.cohort_id = pc.cohort_id
WHERE cc.n_indeterminate > 0
OR cc.quality_flags IS NOT NULL
ORDER BY indeterminate_percent DESC;
```

---

### classification_performance_by_status

**Purpose**: Links classification results to actual clinical outcomes, stratified by biomarker status (positive vs. negative). This table enables calculation of sensitivity, specificity, positive/negative predictive values, and demonstrates clinical utility of biomarker classifications.

**Business Context**: This is the validation table that proves whether biomarker classifications actually predict clinical outcomes. It compares predicted biomarker status against observed outcomes, enabling calculation of all standard diagnostic performance metrics and assessment of clinical benefit.

**Data Sources**: Merged classification and outcome data, diagnostic test validation studies, clinical utility analyses.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| performance_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this performance record | 1, 2, 3, ... | System-generated sequential ID |
| cohort_classification_id | BIGINT | FOREIGN KEY (cohort_classifications.cohort_classification_id), NOT NULL | Links to parent classification | 12345, 67890 | Must exist in cohort_classifications table |
| biomarker_status | VARCHAR(50) | NOT NULL | Biomarker classification group | 'positive', 'negative', 'high', 'low', 'intermediate' | Typically 'positive' or 'negative' |
| n_samples | INT | NULL, CHECK (n_samples >= 0) | Number of patients in this biomarker status group | 75, 70, 40 | Should match n_positive or n_negative from parent classification |
| n_positive_outcome | INT | NULL, CHECK (n_positive_outcome >= 0 AND n_positive_outcome <= n_samples) | Number with positive clinical outcome | 45, 25, 20 | True positives (if biomarker_status='positive') or false negatives (if 'negative') |
| n_negative_outcome | INT | NULL, CHECK (n_negative_outcome >= 0 AND n_negative_outcome <= n_samples) | Number with negative clinical outcome | 30, 45, 20 | False positives (if biomarker_status='positive') or true negatives (if 'negative') |
| outcome_rate | DECIMAL(5,4) | NULL, CHECK (outcome_rate >= 0 AND outcome_rate <= 1) | Proportion with positive outcome in this group | 0.6000, 0.3571, 0.5000 | n_positive_outcome / n_samples |
| outcome_rate_ci_lower | DECIMAL(5,4) | NULL, CHECK (outcome_rate_ci_lower >= 0 AND outcome_rate_ci_lower <= 1) | Lower bound of 95% CI for outcome rate | 0.4900, 0.2500, 0.3600 | Typically 95% confidence interval |
| outcome_rate_ci_upper | DECIMAL(5,4) | NULL, CHECK (outcome_rate_ci_upper >= 0 AND outcome_rate_ci_upper <= 1) | Upper bound of 95% CI for outcome rate | 0.7100, 0.4642, 0.6400 | Should be > outcome_rate_ci_lower |
| median_survival_days | INT | NULL, CHECK (median_survival_days >= 0) | Median survival time for time-to-event endpoints | 540, 365, 730 | For OS, PFS, DOR endpoints |
| hazard_ratio | DECIMAL(10,6) | NULL, CHECK (hazard_ratio > 0) | Hazard ratio for biomarker-positive vs. negative | 0.65000000, 0.78000000, 1.25000000 | <1 favors biomarker-positive; typically positive vs. negative |
| hazard_ratio_ci_lower | DECIMAL(10,6) | NULL, CHECK (hazard_ratio_ci_lower > 0) | Lower bound of 95% CI for hazard ratio | 0.52000000, 0.61000000, 0.98000000 | Typically 95% confidence interval |
| hazard_ratio_ci_upper | DECIMAL(10,6) | NULL, CHECK (hazard_ratio_ci_upper > 0) | Upper bound of 95% CI for hazard ratio | 0.81000000, 0.99000000, 1.59000000 | Should be > hazard_ratio_ci_lower |
| p_value | DECIMAL(15,10) | NULL, CHECK (p_value >= 0 AND p_value <= 1) | Statistical significance of outcome difference | 0.0001234567, 0.0450000000, 0.3456789012 | Tests biomarker-positive vs. negative difference |

**Indexes**:
- PRIMARY KEY on `performance_id`
- FOREIGN KEY INDEX on `cohort_classification_id`
- COMPOSITE INDEX on (`cohort_classification_id`, `biomarker_status`) for status-specific queries
- INDEX on `biomarker_status` for filtering by classification
- INDEX on `outcome_rate` for filtering by performance
- INDEX on `p_value` for filtering significant results

**Relationships**:
- **Child of**: `cohort_classifications`
- **Cardinality**: Typically 2-3 records per classification (positive, negative, possibly indeterminate)

**Data Quality Checks**:
- `n_positive_outcome + n_negative_outcome` should equal `n_samples`
- `outcome_rate` should equal `n_positive_outcome / n_samples`
- `outcome_rate_ci_lower` < `outcome_rate` < `outcome_rate_ci_upper`
- `hazard_ratio_ci_lower` < `hazard_ratio` < `hazard_ratio_ci_upper`
- Sum of `n_samples` across all biomarker_status for a classification should equal `total_samples` in parent
- For each `cohort_classification_id`, there should be at least 2 records (positive and negative)
- `hazard_ratio` should be calculated with consistent reference group (typically negative)
- `p_value` should reflect comparison between biomarker-positive and negative groups

**Derived Metrics** (can be calculated from this table):
- **Sensitivity**: `n_positive_outcome (biomarker=positive) / (n_positive_outcome (positive) + n_positive_outcome (negative))`
- **Specificity**: `n_negative_outcome (biomarker=negative) / (n_negative_outcome (positive) + n_negative_outcome (negative))`
- **PPV**: `outcome_rate` for biomarker_status='positive'
- **NPV**: `1 - outcome_rate` for biomarker_status='negative'
- **Accuracy**: `(TP + TN) / (TP + TN + FP + FN)`

**Usage Examples**:
```sql
-- Calculate diagnostic performance metrics for a classification
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    SUM(CASE WHEN cpbs.biomarker_status = 'positive' THEN cpbs.n_positive_outcome ELSE 0 END) AS true_positives,
    SUM(CASE WHEN cpbs.biomarker_status = 'negative' THEN cpbs.n_negative_outcome ELSE 0 END) AS true_negatives,
    SUM(CASE WHEN cpbs.biomarker_status = 'positive' THEN cpbs.n_negative_outcome ELSE 0 END) AS false_positives,
    SUM(CASE WHEN cpbs.biomarker_status = 'negative' THEN cpbs.n_positive_outcome ELSE 0 END) AS false_negatives,
    ROUND(SUM(CASE WHEN cpbs.biomarker_status = 'positive' THEN cpbs.n_positive_outcome ELSE 0 END) * 1.0 / 
          (SUM(CASE WHEN cpbs.biomarker_status = 'positive' THEN cpbs.n_positive_outcome ELSE 0 END) + 
           SUM(CASE WHEN cpbs.biomarker_status = 'negative' THEN cpbs.n_positive_outcome ELSE 0 END)), 4) AS sensitivity,
    ROUND(SUM(CASE WHEN cpbs.biomarker_status = 'negative' THEN cpbs.n_negative_outcome ELSE 0 END) * 1.0 / 
          (SUM(CASE WHEN cpbs.biomarker_status = 'negative' THEN cpbs.n_negative_outcome ELSE 0 END) + 
           SUM(CASE WHEN cpbs.biomarker_status = 'positive' THEN cpbs.n_negative_outcome ELSE 0 END)), 4) AS specificity
FROM classification_performance_by_status cpbs
JOIN cohort_classifications cc ON cpbs.cohort_classification_id = cc.cohort_classification_id
JOIN biomarkers b ON cc.biomarker_id = b.biomarker_id
JOIN endpoints e ON cc.endpoint_id = e.endpoint_id
WHERE cc.cohort_id = 'NCT04567890_PDL1_HIGH'
AND cc.biomarker_id = 'PD_L1'
AND cc.endpoint_id = 'ORR'
GROUP BY b.biomarker_name, e.endpoint_name;

-- Compare outcomes between biomarker-positive and negative groups
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    pc.cohort_name,
    cpbs.biomarker_status,
    cpbs.n_samples,
    cpbs.outcome_rate,
    cpbs.outcome_rate_ci_lower,
    cpbs.outcome_rate_ci_upper,
    cpbs.median_survival_days,
    cpbs.hazard_ratio,
    cpbs.p_value
FROM classification_performance_by_status cpbs
JOIN cohort_classifications cc ON cpbs.cohort_classification_id = cc.cohort_classification_id
JOIN biomarkers b ON cc.biomarker_id = b.biomarker_id
JOIN endpoints e ON cc.endpoint_id = e.endpoint_id
JOIN patient_cohorts pc ON cc.cohort_id = pc.cohort_id
WHERE cc.biomarker_id = 'TMB'
AND cc.endpoint_id = 'OS'
ORDER BY pc.cohort_name, cpbs.biomarker_status;

-- Find biomarkers with significant outcome differences
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    pc.cohort_name,
    MAX(CASE WHEN cpbs.biomarker_status = 'positive' THEN cpbs.outcome_rate END) AS positive_outcome_rate,
    MAX(CASE WHEN cpbs.biomarker_status = 'negative' THEN cpbs.outcome_rate END) AS negative_outcome_rate,
    MAX(CASE WHEN cpbs.biomarker_status = 'positive' THEN cpbs.outcome_rate END) - 
    MAX(CASE WHEN cpbs.biomarker_status = 'negative' THEN cpbs.outcome_rate END) AS absolute_difference,
    MAX(cpbs.hazard_ratio) AS hazard_ratio,
    MIN(cpbs.p_value) AS p_value
FROM classification_performance_by_status cpbs
JOIN cohort_classifications cc ON cpbs.cohort_classification_id = cc.cohort_classification_id
JOIN biomarkers b ON cc.biomarker_id = b.biomarker_id
JOIN endpoints e ON cc.endpoint_id = e.endpoint_id
JOIN patient_cohorts pc ON cc.cohort_id = pc.cohort_id
GROUP BY b.biomarker_name, e.endpoint_name, pc.cohort_name
HAVING p_value < 0.05
AND absolute_difference > 0.2
ORDER BY absolute_difference DESC;

-- Evaluate clinical utility (outcome rates by biomarker status)
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    cpbs.biomarker_status,
    AVG(cpbs.outcome_rate) AS avg_outcome_rate,
    MIN(cpbs.outcome_rate) AS min_outcome_rate,
    MAX(cpbs.outcome_rate) AS max_outcome_rate,
    COUNT(DISTINCT cc.cohort_id) AS num_cohorts
FROM classification_performance_by_status cpbs
JOIN cohort_classifications cc ON cpbs.cohort_classification_id = cc.cohort_classification_id
JOIN biomarkers b ON cc.biomarker_id = b.biomarker_id
JOIN endpoints e ON cc.endpoint_id = e.endpoint_id
WHERE e.endpoint_type = 'efficacy'
GROUP BY b.biomarker_name, e.endpoint_name, cpbs.biomarker_status
HAVING num_cohorts >= 3
ORDER BY b.biomarker_name, cpbs.biomarker_status;
```

---

## Validation and Meta-Analysis Tables

### model_validations

**Purpose**: Stores comprehensive validation results for classification models, including internal validation, external validation, cross-validation, and temporal validation. This table documents model performance across different validation strategies and provides evidence for model reliability and generalizability.

**Business Context**: Model validation is essential for regulatory approval, clinical implementation, and scientific publication. This table captures all validation evidence, enabling comparison of model performance across validation types, identification of overfitting, and assessment of model robustness.

**Data Sources**: Validation study reports, cross-validation outputs, ROC analysis results, calibration assessments, bootstrap analyses.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| validation_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for this validation | 'PDL1_LR_V1_INT_VAL', 'TMB_RF_V2_EXT_VAL_2024', 'MULTIBIO_CV_FOLD5' | Combine model_id, validation type, and identifier |
| model_id | VARCHAR(50) | FOREIGN KEY (classification_models.model_id), NOT NULL | Links to validated model | 'PDL1_LR_V1.0', 'TMB_RF_V2.3' | Must exist in classification_models table |
| validation_type | VARCHAR(50) | NULL | Type of validation performed | 'internal', 'external', 'cross_validation', 'temporal', 'prospective', 'bootstrap', 'leave_one_out' | Standardized validation categories |
| validation_cohorts | TEXT | NULL | Cohort IDs used for validation | 'NCT98765432_ARM_B, IMpower150_NSCLC', 'Independent cohorts from 3 trials' | Semicolon or comma-separated cohort_ids |
| validation_date | DATE | NULL | Date when validation was performed | '2024-03-15', '2023-11-20' | Validation completion date |
| total_sample_size | INT | NULL, CHECK (total_sample_size > 0) | Total number of samples in validation | 500, 1200, 250 | Sum across all validation cohorts |
| auc_roc | DECIMAL(5,4) | NULL, CHECK (auc_roc >= 0 AND auc_roc <= 1) | Area under ROC curve | 0.7800, 0.8500, 0.7200 | Primary discriminatory metric; 0.5=random, 1.0=perfect |
| auc_roc_ci_lower | DECIMAL(5,4) | NULL, CHECK (auc_roc_ci_lower >= 0 AND auc_roc_ci_lower <= 1) | Lower bound of 95% CI for AUC-ROC | 0.7200, 0.8100, 0.6500 | Typically 95% confidence interval |
| auc_roc_ci_upper | DECIMAL(5,4) | NULL, CHECK (auc_roc_ci_upper >= 0 AND auc_roc_ci_upper <= 1) | Upper bound of 95% CI for AUC-ROC | 0.8400, 0.8900, 0.7900 | Should be > auc_roc_ci_lower |
| sensitivity | DECIMAL(5,4) | NULL, CHECK (sensitivity >= 0 AND sensitivity <= 1) | True positive rate | 0.8500, 0.7200, 0.9100 | TP / (TP + FN) |
| specificity | DECIMAL(5,4) | NULL, CHECK (specificity >= 0 AND specificity <= 1) | True negative rate | 0.7800, 0.8500, 0.6500 | TN / (TN + FP) |
| ppv | DECIMAL(5,4) | NULL, CHECK (ppv >= 0 AND ppv <= 1) | Positive predictive value | 0.7500, 0.8200, 0.6800 | TP / (TP + FP) |
| npv | DECIMAL(5,4) | NULL, CHECK (npv >= 0 AND npv <= 1) | Negative predictive value | 0.8200, 0.7500, 0.9000 | TN / (TN + FN) |
| accuracy | DECIMAL(5,4) | NULL, CHECK (accuracy >= 0 AND accuracy <= 1) | Overall classification accuracy | 0.8100, 0.7850, 0.8400 | (TP + TN) / (TP + TN + FP + FN) |
| f1_score | DECIMAL(5,4) | NULL, CHECK (f1_score >= 0 AND f1_score <= 1) | Harmonic mean of precision and recall | 0.7900, 0.7650, 0.8200 | 2 * (precision * recall) / (precision + recall) |
| balanced_accuracy | DECIMAL(5,4) | NULL, CHECK (balanced_accuracy >= 0 AND balanced_accuracy <= 1) | Average of sensitivity and specificity | 0.8150, 0.7850, 0.7800 | (sensitivity + specificity) / 2 |
| matthews_correlation | DECIMAL(5,4) | NULL, CHECK (matthews_correlation >= -1 AND matthews_correlation <= 1) | Matthews correlation coefficient | 0.6200, 0.5800, 0.6800 | Balanced metric; -1 to +1; 0=random |
| calibration_slope | DECIMAL(10,6) | NULL | Slope of calibration plot | 1.000000, 0.950000, 1.050000 | Ideal=1.0; <1=overconfident, >1=underconfident |
| calibration_intercept | DECIMAL(10,6) | NULL | Intercept of calibration plot | 0.000000, -0.050000, 0.030000 | Ideal=0.0; measures systematic bias |
| brier_score | DECIMAL(5,4) | NULL, CHECK (brier_score >= 0 AND brier_score <= 1) | Mean squared error of predictions | 0.1500, 0.1800, 0.1200 | Lower is better; 0=perfect, 0.25=uninformative |
| confusion_matrix | JSON | NULL | Detailed confusion matrix | `{"TP": 85, "TN": 78, "FP": 22, "FN": 15, "total": 200}` | Counts of TP, TN, FP, FN |
| roc_curve_data | JSON | NULL | ROC curve coordinates for plotting | `{"thresholds": [0.0, 0.1, ..., 1.0], "tpr": [1.0, 0.95, ..., 0.0], "fpr": [1.0, 0.85, ..., 0.0]}` | Arrays of threshold, TPR, FPR values |
| calibration_plot_data | JSON | NULL | Calibration plot data | `{"predicted": [0.1, 0.2, ..., 0.9], "observed": [0.12, 0.18, ..., 0.88]}` | Predicted vs. observed outcome rates |
| subgroup_performance | JSON | NULL | Performance metrics by subgroups | `{"age_<65": {"auc": 0.82, "n": 120}, "age_>=65": {"auc": 0.78, "n": 80}}` | Subgroup-specific metrics |
| validation_report_path | VARCHAR(500) | NULL | File path or URL to detailed validation report | '/reports/pdl1_lr_v1_validation.pdf', 's3://bucket/validations/tmb_rf_v2_external.html' | Location of comprehensive report |
| validated_by | VARCHAR(255) | NULL | Person or team who performed validation | 'Jane Smith', 'External Validation Team', 'Independent CRO' | Validator identification |
| notes | TEXT | NULL | Additional validation details or caveats | 'Validation performed on independent dataset', 'Excluded patients with missing baseline data', 'Temporal validation using most recent cohort' | Free text for important context |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `validation_id`
- FOREIGN KEY INDEX on `model_id`
- COMPOSITE INDEX on (`model_id`, `validation_type`) for model-specific validation queries
- COMPOSITE INDEX on (`model_id`, `validation_date`) for temporal tracking
- INDEX on `validation_type` for filtering by validation category
- INDEX on `auc_roc` for filtering by performance
- INDEX on `validation_date` for temporal analyses

**Relationships**:
- **Child of**: `classification_models`
- **Cardinality**: Typically 1-10 validations per model (internal, external, cross-validation, etc.)

**Data Quality Checks**:
- `auc_roc_ci_lower` < `auc_roc` < `auc_roc_ci_upper`
- `sensitivity`, `specificity`, `ppv`, `npv`, `accuracy` should all be between 0 and 1
- `balanced_accuracy` should approximately equal `(sensitivity + specificity) / 2`
- `matthews_correlation` should be between -1 and +1
- `calibration_slope` should be close to 1.0 for well-calibrated models
- `calibration_intercept` should be close to 0.0 for well-calibrated models
- `brier_score` should be < 0.25 for useful models
- `confusion_matrix` JSON should contain TP, TN, FP, FN with sum = `total_sample_size`
- For cross-validation, multiple validation records should exist with same `model_id`
- `total_sample_size` should be reasonable for validation type (e.g., ≥100 for external validation)

**Usage Examples**:
```sql
-- Compare validation performance across validation types
SELECT 
    cm.model_name,
    mv.validation_type,
    mv.total_sample_size,
    mv.auc_roc,
    mv.sensitivity,
    mv.specificity,
    mv.accuracy,
    mv.validation_date
FROM model_validations mv
JOIN classification_models cm ON mv.model_id = cm.model_id
WHERE cm.model_id = 'PDL1_LR_V1.0'
ORDER BY mv.validation_date DESC;

-- Find well-performing models (high AUC across validations)
SELECT 
    cm.model_name,
    cm.model_type,
    COUNT(*) AS num_validations,
    AVG(mv.auc_roc) AS avg_auc,
    MIN(mv.auc_roc) AS min_auc,
    MAX(mv.auc_roc) AS max_auc,
    STDDEV(mv.auc_roc) AS auc_std_dev
FROM model_validations mv
JOIN classification_models cm ON mv.model_id = cm.model_id
WHERE mv.validation_type IN ('internal', 'external')
GROUP BY cm.model_name, cm.model_type
HAVING avg_auc >= 0.75
AND num_validations >= 2
ORDER BY avg_auc DESC;

-- Assess model calibration
SELECT 
    cm.model_name,
    mv.validation_type,
    mv.calibration_slope,
    mv.calibration_intercept,
    mv.brier_score,
    CASE 
        WHEN ABS(mv.calibration_slope - 1.0) <= 0.1 AND ABS(mv.calibration_intercept) <= 0.05 
        THEN 'Well-calibrated'
        ELSE 'Poorly-calibrated'
    END AS calibration_status
FROM model_validations mv
JOIN classification_models cm ON mv.model_id = cm.model_id
WHERE mv.calibration_slope IS NOT NULL
ORDER BY ABS(mv.calibration_slope - 1.0) + ABS(mv.calibration_intercept);

-- Track validation performance over time
SELECT 
    cm.model_name,
    mv.validation_date,
    mv.validation_type,
    mv.auc_roc,
    mv.total_sample_size,
    mv.validated_by
FROM model_validations mv
JOIN classification_models cm ON mv.model_id = cm.model_id
WHERE cm.model_name LIKE '%PD-L1%'
ORDER BY mv.validation_date DESC;

-- Compare internal vs external validation performance
SELECT 
    cm.model_name,
    MAX(CASE WHEN mv.validation_type = 'internal' THEN mv.auc_roc END) AS internal_auc,
    MAX(CASE WHEN mv.validation_type = 'external' THEN mv.auc_roc END) AS external_auc,
    MAX(CASE WHEN mv.validation_type = 'internal' THEN mv.auc_roc END) - 
    MAX(CASE WHEN mv.validation_type = 'external' THEN mv.auc_roc END) AS performance_drop
FROM model_validations mv
JOIN classification_models cm ON mv.model_id = cm.model_id
GROUP BY cm.model_name
HAVING internal_auc IS NOT NULL AND external_auc IS NOT NULL
ORDER BY performance_drop;
```

---

Due to length, shall I continue with the remaining tables:

1. **cross_trial_validations** - Cross-trial performance tracking
2. **meta_analysis_results** - Pooled analyses across studies
3. **data_provenance** - Data lineage and quality tracking
4. **audit_log** - Complete change history
5. **data_quality_issues** - Quality issue management
6. **user_access_log** - Access tracking and security

Would you like me to complete the documentation with these final tables?

# Comprehensive Table and Column Specifications (Continued)

## Validation and Meta-Analysis Tables (Continued)

### cross_trial_validations

**Purpose**: Tracks model performance when applied to different clinical trials than those used for training, assessing model generalizability across diverse patient populations, treatment regimens, and study contexts. This table is critical for understanding external validity and identifying trial-specific effects.

**Business Context**: A model that performs well in its training trial but poorly in other trials has limited clinical utility. Cross-trial validation reveals whether biomarker-outcome relationships are robust across different clinical contexts, patient populations, and treatment settings. This evidence is essential for regulatory approval and broad clinical implementation.

**Data Sources**: External validation studies, cross-trial analyses, model portability assessments, multi-trial meta-analyses.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| cross_validation_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this cross-trial validation record | 1, 2, 3, ... | System-generated sequential ID |
| model_id | VARCHAR(50) | FOREIGN KEY (classification_models.model_id), NOT NULL | Links to validated model | 'PDL1_LR_V1.0', 'TMB_RF_V2.3' | Must exist in classification_models table |
| training_trial_id | VARCHAR(50) | FOREIGN KEY (clinical_trials.trial_id), NOT NULL | Trial used for model development | 'NCT04567890', 'KEYNOTE-001' | Must exist in clinical_trials table |
| validation_trial_id | VARCHAR(50) | FOREIGN KEY (clinical_trials.trial_id), NOT NULL | Trial used for validation | 'NCT98765432', 'CHECKMATE-067' | Must exist in clinical_trials table; should differ from training_trial_id |
| validation_date | DATE | NULL | Date when cross-trial validation was performed | '2024-03-15', '2023-11-20' | Validation completion date |
| sample_size | INT | NULL, CHECK (sample_size > 0) | Number of samples in validation trial | 500, 300, 150 | Total samples from validation_trial_id used |
| auc_roc | DECIMAL(5,4) | NULL, CHECK (auc_roc >= 0 AND auc_roc <= 1) | Area under ROC curve in validation trial | 0.7800, 0.8200, 0.7000 | Discriminatory performance in new trial |
| sensitivity | DECIMAL(5,4) | NULL, CHECK (sensitivity >= 0 AND sensitivity <= 1) | True positive rate in validation trial | 0.8200, 0.7500, 0.8800 | TP / (TP + FN) |
| specificity | DECIMAL(5,4) | NULL, CHECK (specificity >= 0 AND specificity <= 1) | True negative rate in validation trial | 0.7500, 0.8200, 0.6800 | TN / (TN + FP) |
| accuracy | DECIMAL(5,4) | NULL, CHECK (accuracy >= 0 AND accuracy <= 1) | Overall classification accuracy in validation trial | 0.7850, 0.7950, 0.7600 | (TP + TN) / (TP + TN + FP + FN) |
| generalizability_score | DECIMAL(5,4) | NULL, CHECK (generalizability_score >= 0 AND generalizability_score <= 1) | Custom metric assessing cross-trial performance | 0.9200, 0.8500, 0.7800 | Ratio of validation AUC to training AUC, or other composite metric |
| notes | TEXT | NULL | Additional context about cross-trial validation | 'Different treatment regimen in validation trial', 'Validation trial included broader patient population', 'Geographic differences between trials' | Free text for important contextual differences |

**Indexes**:
- PRIMARY KEY on `cross_validation_id`
- FOREIGN KEY INDEX on `model_id`
- FOREIGN KEY INDEX on `training_trial_id`
- FOREIGN KEY INDEX on `validation_trial_id`
- COMPOSITE INDEX on (`model_id`, `validation_trial_id`) for model-trial queries
- COMPOSITE INDEX on (`training_trial_id`, `validation_trial_id`) for trial pair comparisons
- INDEX on `auc_roc` for filtering by performance
- INDEX on `generalizability_score` for filtering by generalizability

**Relationships**:
- **Child of**: `classification_models`, `clinical_trials` (×2)
- **Cardinality**: Potentially many records per model (one per validation trial)

**Data Quality Checks**:
- `training_trial_id` should not equal `validation_trial_id` (no self-validation)
- `sample_size` should be reasonable (typically ≥50 for meaningful validation)
- `auc_roc` should be > 0.5 for useful models
- `generalizability_score` should be ≤ 1.0
- All performance metrics should be between 0 and 1
- `validation_date` should be after model `development_date`
- Model should have been trained on cohorts from `training_trial_id`

**Usage Examples**:
```sql
-- Assess model generalizability across trials
SELECT 
    cm.model_name,
    ct_train.trial_name AS training_trial,
    ct_val.trial_name AS validation_trial,
    ctv.sample_size,
    ctv.auc_roc,
    ctv.generalizability_score,
    ctv.validation_date
FROM cross_trial_validations ctv
JOIN classification_models cm ON ctv.model_id = cm.model_id
JOIN clinical_trials ct_train ON ctv.training_trial_id = ct_train.trial_id
JOIN clinical_trials ct_val ON ctv.validation_trial_id = ct_val.trial_id
WHERE cm.model_id = 'PDL1_LR_V1.0'
ORDER BY ctv.auc_roc DESC;

-- Find models with consistent performance across trials
SELECT 
    cm.model_name,
    COUNT(DISTINCT ctv.validation_trial_id) AS num_validation_trials,
    AVG(ctv.auc_roc) AS avg_auc,
    MIN(ctv.auc_roc) AS min_auc,
    MAX(ctv.auc_roc) AS max_auc,
    STDDEV(ctv.auc_roc) AS auc_std_dev,
    AVG(ctv.generalizability_score) AS avg_generalizability
FROM cross_trial_validations ctv
JOIN classification_models cm ON ctv.model_id = cm.model_id
GROUP BY cm.model_name
HAVING num_validation_trials >= 3
AND auc_std_dev < 0.1
ORDER BY avg_generalizability DESC;

-- Compare performance across different validation trials
SELECT 
    ct_val.trial_name AS validation_trial,
    ct_val.indication,
    COUNT(DISTINCT ctv.model_id) AS num_models_tested,
    AVG(ctv.auc_roc) AS avg_auc,
    MIN(ctv.auc_roc) AS min_auc,
    MAX(ctv.auc_roc) AS max_auc
FROM cross_trial_validations ctv
JOIN clinical_trials ct_val ON ctv.validation_trial_id = ct_val.trial_id
GROUP BY ct_val.trial_name, ct_val.indication
HAVING num_models_tested >= 2
ORDER BY avg_auc DESC;

-- Identify models with poor generalizability
SELECT 
    cm.model_name,
    ct_train.trial_name AS training_trial,
    ct_val.trial_name AS validation_trial,
    ctv.auc_roc AS validation_auc,
    ctv.generalizability_score,
    ctv.notes
FROM cross_trial_validations ctv
JOIN classification_models cm ON ctv.model_id = cm.model_id
JOIN clinical_trials ct_train ON ctv.training_trial_id = ct_train.trial_id
JOIN clinical_trials ct_val ON ctv.validation_trial_id = ct_val.trial_id
WHERE ctv.generalizability_score < 0.8
OR ctv.auc_roc < 0.65
ORDER BY ctv.generalizability_score;

-- Track cross-trial validation over time
SELECT 
    cm.model_name,
    ctv.validation_date,
    ct_val.trial_name AS validation_trial,
    ctv.auc_roc,
    ctv.sample_size
FROM cross_trial_validations ctv
JOIN classification_models cm ON ctv.model_id = cm.model_id
JOIN clinical_trials ct_val ON ctv.validation_trial_id = ct_val.trial_id
WHERE cm.model_name LIKE '%PD-L1%'
ORDER BY ctv.validation_date DESC;
```

---

### meta_analysis_results

**Purpose**: Stores pooled analyses that synthesize biomarker-endpoint associations across multiple cohorts or trials, providing higher statistical power and more robust effect estimates than individual studies. This table supports evidence synthesis, heterogeneity assessment, and publication bias detection.

**Business Context**: Individual trials may be underpowered or show inconsistent results. Meta-analysis combines evidence across studies to provide definitive answers about biomarker-outcome relationships. This table is critical for regulatory submissions, clinical guideline development, and establishing biomarker clinical validity.

**Data Sources**: Meta-analysis software outputs (RevMan, Comprehensive Meta-Analysis), systematic review results, pooled analyses, IPD meta-analyses.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| meta_analysis_id | VARCHAR(50) | PRIMARY KEY, NOT NULL | Unique identifier for this meta-analysis | 'PDL1_OS_META_2024', 'TMB_PFS_POOLED_V1', 'CD8_ORR_SYNTHESIS' | Descriptive ID combining biomarker, endpoint, and analysis |
| biomarker_id | VARCHAR(50) | FOREIGN KEY (biomarkers.biomarker_id), NOT NULL | Links to analyzed biomarker | 'PD_L1', 'TMB', 'CD8A_EXPRESSION' | Must exist in biomarkers table |
| endpoint_id | VARCHAR(50) | FOREIGN KEY (endpoints.endpoint_id), NOT NULL | Links to analyzed endpoint | 'OS', 'PFS', 'ORR' | Must exist in endpoints table |
| analysis_name | VARCHAR(255) | NULL | Descriptive name for this meta-analysis | 'PD-L1 and Overall Survival Meta-Analysis 2024', 'TMB Predictive Meta-Analysis Across Immunotherapy Trials' | Human-readable analysis name |
| included_cohorts | TEXT | NULL | List of cohort IDs included in meta-analysis | 'NCT04567890_ARM_A, KEYNOTE001_NSCLC, CHECKMATE067_MEL, IMpower150_NSCLC', 'Cohorts from 8 trials (see notes)' | Semicolon or comma-separated cohort_ids |
| total_sample_size | INT | NULL, CHECK (total_sample_size > 0) | Total number of patients across all included cohorts | 2500, 5000, 1200 | Sum of sample sizes from included cohorts |
| number_of_cohorts | INT | NULL, CHECK (number_of_cohorts > 0) | Number of cohorts/studies included | 8, 12, 5 | Count of distinct cohorts in meta-analysis |
| pooled_effect_size | DECIMAL(15,8) | NULL | Combined effect size estimate | 0.65000000, 2.50000000, -0.45000000 | Interpretation depends on effect_size_type |
| effect_size_type | VARCHAR(50) | NULL | Type of pooled effect size | 'odds_ratio', 'hazard_ratio', 'risk_ratio', 'mean_difference', 'standardized_mean_difference', 'correlation' | Standardized effect size nomenclature |
| pooled_ci_lower | DECIMAL(15,8) | NULL | Lower bound of 95% CI for pooled effect | 0.55000000, 2.10000000, -0.65000000 | Typically 95% confidence interval |
| pooled_ci_upper | DECIMAL(15,8) | NULL | Upper bound of 95% CI for pooled effect | 0.77000000, 2.98000000, -0.25000000 | Should be > pooled_ci_lower |
| pooled_p_value | DECIMAL(15,10) | NULL, CHECK (pooled_p_value >= 0 AND pooled_p_value <= 1) | Statistical significance of pooled effect | 0.0000012345, 0.0010000000, 0.0450000000 | Overall test of pooled effect vs. null |
| heterogeneity_i2 | DECIMAL(5,2) | NULL, CHECK (heterogeneity_i2 >= 0 AND heterogeneity_i2 <= 100) | I-squared statistic for heterogeneity | 45.50, 72.30, 12.80 | Percentage of variation due to heterogeneity; 0-40%=low, 30-60%=moderate, 50-90%=substantial, 75-100%=considerable |
| heterogeneity_tau2 | DECIMAL(10,6) | NULL, CHECK (heterogeneity_tau2 >= 0) | Tau-squared: variance of true effects | 0.025000, 0.150000, 0.005000 | Between-study variance; 0=no heterogeneity |
| heterogeneity_p_value | DECIMAL(15,10) | NULL, CHECK (heterogeneity_p_value >= 0 AND heterogeneity_p_value <= 1) | Statistical test for heterogeneity | 0.0450000000, 0.0001234567, 0.3456789012 | Cochran's Q test; p<0.10 suggests significant heterogeneity |
| meta_analysis_method | VARCHAR(100) | NULL | Statistical method used for pooling | 'fixed_effects', 'random_effects', 'DerSimonian_Laird', 'inverse_variance', 'Mantel_Haenszel', 'Peto', 'REML' | Standardized meta-analysis methodology |
| publication_bias_test | VARCHAR(100) | NULL | Method used to assess publication bias | 'Egger_test', 'Begg_test', 'funnel_plot', 'trim_and_fill', 'PET-PEESE' | Publication bias assessment approach |
| publication_bias_p_value | DECIMAL(15,10) | NULL, CHECK (publication_bias_p_value >= 0 AND publication_bias_p_value <= 1) | Statistical test for publication bias | 0.1234567890, 0.0450000000, 0.7890123456 | p<0.10 suggests potential publication bias |
| forest_plot_data | JSON | NULL | Data for forest plot visualization | `{"studies": [{"cohort_id": "COHORT_001", "effect": 0.65, "ci_lower": 0.52, "ci_upper": 0.81, "weight": 0.25}, ...], "pooled": {"effect": 0.68, "ci_lower": 0.60, "ci_upper": 0.77}}` | Individual study effects and pooled estimate |
| analysis_date | DATE | NULL | Date when meta-analysis was performed | '2024-06-15', '2023-12-20' | Analysis completion date |
| notes | TEXT | NULL | Additional methodological details or limitations | 'Random effects model used due to high heterogeneity', 'Excluded 2 studies due to insufficient data', 'Subgroup analysis by treatment type showed significant differences' | Free text for important context |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `meta_analysis_id`
- FOREIGN KEY INDEX on `biomarker_id`
- FOREIGN KEY INDEX on `endpoint_id`
- COMPOSITE INDEX on (`biomarker_id`, `endpoint_id`) for biomarker-endpoint meta-analyses
- INDEX on `analysis_date` for temporal queries
- INDEX on `pooled_p_value` for filtering significant results
- INDEX on `heterogeneity_i2` for filtering by heterogeneity

**Relationships**:
- **Child of**: `biomarkers`, `endpoints`
- **Cardinality**: Typically 1-10 meta-analyses per biomarker-endpoint pair (different time periods, subsets)

**Data Quality Checks**:
- `number_of_cohorts` should be ≥ 2 (minimum for meta-analysis)
- `total_sample_size` should be greater than sum of minimum cohort sizes
- `pooled_ci_lower` < `pooled_effect_size` < `pooled_ci_upper` (for most effect types)
- For hazard ratios and odds ratios, `pooled_effect_size` should be > 0
- `heterogeneity_i2` should be between 0 and 100
- `heterogeneity_tau2` should be ≥ 0
- If `heterogeneity_i2` > 50%, `meta_analysis_method` should typically be 'random_effects'
- `included_cohorts` should list at least `number_of_cohorts` cohort IDs
- `forest_plot_data` JSON should contain `number_of_cohorts` study entries

**Usage Examples**:
```sql
-- Get all meta-analyses for a biomarker-endpoint pair
SELECT 
    mar.meta_analysis_id,
    mar.analysis_name,
    mar.number_of_cohorts,
    mar.total_sample_size,
    mar.pooled_effect_size,
    mar.effect_size_type,
    mar.pooled_ci_lower,
    mar.pooled_ci_upper,
    mar.pooled_p_value,
    mar.heterogeneity_i2,
    mar.analysis_date
FROM meta_analysis_results mar
WHERE mar.biomarker_id = 'PD_L1'
AND mar.endpoint_id = 'OS'
ORDER BY mar.analysis_date DESC;

-- Find significant meta-analyses with low heterogeneity
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    mar.number_of_cohorts,
    mar.total_sample_size,
    mar.pooled_effect_size,
    mar.effect_size_type,
    mar.pooled_p_value,
    mar.heterogeneity_i2,
    mar.meta_analysis_method
FROM meta_analysis_results mar
JOIN biomarkers b ON mar.biomarker_id = b.biomarker_id
JOIN endpoints e ON mar.endpoint_id = e.endpoint_id
WHERE mar.pooled_p_value < 0.05
AND mar.heterogeneity_i2 < 40
AND mar.number_of_cohorts >= 5
ORDER BY mar.pooled_p_value;

-- Assess publication bias across meta-analyses
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    mar.number_of_cohorts,
    mar.publication_bias_test,
    mar.publication_bias_p_value,
    CASE 
        WHEN mar.publication_bias_p_value < 0.10 THEN 'Potential bias detected'
        WHEN mar.publication_bias_p_value >= 0.10 THEN 'No significant bias'
        ELSE 'Not assessed'
    END AS bias_assessment
FROM meta_analysis_results mar
JOIN biomarkers b ON mar.biomarker_id = b.biomarker_id
JOIN endpoints e ON mar.endpoint_id = e.endpoint_id
WHERE mar.publication_bias_test IS NOT NULL
ORDER BY mar.publication_bias_p_value;

-- Compare fixed vs random effects models
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    mar.meta_analysis_method,
    mar.pooled_effect_size,
    mar.pooled_ci_lower,
    mar.pooled_ci_upper,
    mar.heterogeneity_i2,
    mar.analysis_date
FROM meta_analysis_results mar
JOIN biomarkers b ON mar.biomarker_id = b.biomarker_id
JOIN endpoints e ON mar.endpoint_id = e.endpoint_id
WHERE b.biomarker_id = 'TMB'
AND e.endpoint_id = 'PFS'
ORDER BY mar.analysis_date DESC;

-- Identify biomarkers with consistent effects across meta-analyses
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    COUNT(*) AS num_meta_analyses,
    AVG(mar.pooled_effect_size) AS avg_effect,
    MIN(mar.pooled_effect_size) AS min_effect,
    MAX(mar.pooled_effect_size) AS max_effect,
    AVG(mar.heterogeneity_i2) AS avg_heterogeneity,
    SUM(CASE WHEN mar.pooled_p_value < 0.05 THEN 1 ELSE 0 END) AS num_significant
FROM meta_analysis_results mar
JOIN biomarkers b ON mar.biomarker_id = b.biomarker_id
JOIN endpoints e ON mar.endpoint_id = e.endpoint_id
GROUP BY b.biomarker_name, e.endpoint_name
HAVING num_meta_analyses >= 2
ORDER BY num_significant DESC, avg_effect DESC;
```

---

## Audit and Governance Tables

### data_provenance

**Purpose**: Tracks the origin, extraction method, and quality assessment of all data in the database, ensuring complete traceability from source to database record. This table supports data quality management, regulatory compliance, and reproducibility.

**Business Context**: Regulatory agencies and scientific journals require documentation of data sources and quality. This table provides the audit trail showing where each piece of data came from, how it was extracted, who verified it, and its quality level. Essential for FDA submissions, publications, and data integrity audits.

**Data Sources**: Data extraction logs, literature references, database accession numbers, internal data transfer documentation.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| provenance_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this provenance record | 1, 2, 3, ... | System-generated sequential ID |
| source_table | VARCHAR(100) | NOT NULL | Name of table containing the data | 'cohort_biomarker_summary', 'biomarker_endpoint_associations', 'cohort_endpoints' | Must be valid table name in database |
| source_record_id | VARCHAR(100) | NOT NULL | Primary key value of the source record | '12345', 'NCT04567890_PDL1_HIGH', 'IMMUNE_INFLAM_SIG_V1' | Links to specific record in source_table |
| data_source | VARCHAR(255) | NULL | Type or name of original data source | 'publication', 'database', 'internal_analysis', 'GEO', 'clinical_study_report', 'supplementary_data' | Categorization of source type |
| source_reference | VARCHAR(500) | NULL | Specific reference to data source | 'PMID: 12345678', 'DOI: 10.1056/NEJMoa2034577', 'GSE123456', 'Clinical Study Report NCT04567890 v2.0', '/data/trial_NCT04567890/biomarkers.csv' | Citation, accession number, or file path |
| extraction_date | DATE | NULL | Date when data was extracted from source | '2024-01-15', '2023-11-20' | Date of data capture |
| extraction_method | TEXT | NULL | Description of how data was extracted | 'Manual extraction from Table 2 of publication', 'Automated download from GEO using GEOquery', 'Direct export from clinical database', 'Web scraping from ClinicalTrials.gov' | Methodology documentation |
| data_quality_score | DECIMAL(3,2) | NULL, CHECK (data_quality_score >= 0 AND data_quality_score <= 1) | Overall quality assessment score | 0.95, 0.80, 0.65 | 0=poor, 1=excellent; composite of completeness, accuracy, consistency |
| curator | VARCHAR(255) | NULL | Person who extracted/curated the data | 'John Doe', 'Data Curation Team', 'Automated Pipeline v2.3' | Data curator identification |
| verification_status | VARCHAR(50) | NULL | Level of quality verification performed | 'unverified', 'verified', 'validated', 'double_checked', 'expert_reviewed' | Quality control status |
| verified_by | VARCHAR(255) | NULL | Person who verified the data | 'Jane Smith', 'QC Team Lead', 'Senior Biostatistician' | Verifier identification |
| verification_date | DATE | NULL | Date when data was verified | '2024-01-20', '2023-12-05' | Date of quality verification |
| notes | TEXT | NULL | Additional provenance details or caveats | 'Data extracted from supplementary table; some values imputed', 'Contacted authors for clarification on measurement units', 'Original data in different format; converted to standard units' | Free text for important context |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `provenance_id`
- COMPOSITE INDEX on (`source_table`, `source_record_id`) for record-specific provenance lookup
- INDEX on `source_table` for table-level queries
- INDEX on `data_source` for filtering by source type
- INDEX on `verification_status` for filtering by QC status
- INDEX on `data_quality_score` for filtering by quality
- INDEX on `extraction_date` for temporal analyses

**Relationships**:
- **Links to**: Any table via `source_table` and `source_record_id` (polymorphic relationship)
- **Cardinality**: Potentially one or more provenance records per data record

**Data Quality Checks**:
- `source_table` should be a valid table name in the database schema
- `source_record_id` should exist in the specified `source_table`
- If `verification_status` is 'verified' or higher, `verified_by` and `verification_date` should be populated
- `verification_date` should be ≥ `extraction_date`
- `data_quality_score` should be between 0 and 1
- `source_reference` should be provided for all external data sources
- `verification_status` should use controlled vocabulary

**Usage Examples**:
```sql
-- Get provenance for specific biomarker summary records
SELECT 
    dp.source_record_id,
    dp.data_source,
    dp.source_reference,
    dp.extraction_date,
    dp.data_quality_score,
    dp.verification_status,
    dp.curator
FROM data_provenance dp
WHERE dp.source_table = 'cohort_biomarker_summary'
AND dp.source_record_id IN (
    SELECT summary_id 
    FROM cohort_biomarker_summary 
    WHERE biomarker_id = 'PD_L1'
)
ORDER BY dp.data_quality_score DESC;

-- Find unverified data records
SELECT 
    dp.source_table,
    COUNT(*) AS num_unverified_records,
    MIN(dp.extraction_date) AS oldest_extraction,
    MAX(dp.extraction_date) AS newest_extraction
FROM data_provenance dp
WHERE dp.verification_status = 'unverified'
GROUP BY dp.source_table
ORDER BY num_unverified_records DESC;

-- Assess data quality by source type
SELECT 
    dp.data_source,
    COUNT(*) AS num_records,
    AVG(dp.data_quality_score) AS avg_quality_score,
    MIN(dp.data_quality_score) AS min_quality_score,
    MAX(dp.data_quality_score) AS max_quality_score,
    SUM(CASE WHEN dp.verification_status IN ('verified', 'validated') THEN 1 ELSE 0 END) AS num_verified
FROM data_provenance dp
GROUP BY dp.data_source
ORDER BY avg_quality_score DESC;

-- Track data curation activity over time
SELECT 
    DATE_FORMAT(dp.extraction_date, '%Y-%m') AS extraction_month,
    dp.curator,
    COUNT(*) AS num_records_curated,
    AVG(dp.data_quality_score) AS avg_quality
FROM data_provenance dp
WHERE dp.extraction_date >= DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH)
GROUP BY extraction_month, dp.curator
ORDER BY extraction_month DESC, num_records_curated DESC;

-- Identify high-quality data sources
SELECT 
    dp.source_reference,
    dp.data_source,
    COUNT(*) AS num_records,
    AVG(dp.data_quality_score) AS avg_quality,
    COUNT(DISTINCT dp.source_table) AS num_tables_populated
FROM data_provenance dp
WHERE dp.data_quality_score >= 0.9
GROUP BY dp.source_reference, dp.data_source
HAVING num_records >= 10
ORDER BY avg_quality DESC, num_records DESC;

-- Find records needing verification
SELECT 
    dp.source_table,
    dp.source_record_id,
    dp.extraction_date,
    dp.curator,
    DATEDIFF(CURRENT_DATE, dp.extraction_date) AS days_since_extraction
FROM data_provenance dp
WHERE dp.verification_status = 'unverified'
AND dp.extraction_date < DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
ORDER BY days_since_extraction DESC;
```

---

### audit_log

**Purpose**: Maintains a complete, immutable record of all data modifications (inserts, updates, deletes) across the database, supporting regulatory compliance, data integrity verification, change investigation, and potential data recovery.

**Business Context**: Regulatory requirements (21 CFR Part 11, GDPR) mandate audit trails for clinical data systems. This table provides forensic-level tracking of who changed what, when, why, and from where. Essential for FDA inspections, data integrity investigations, and demonstrating GxP compliance.

**Data Sources**: Database triggers, application-level logging, change data capture (CDC) mechanisms.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| audit_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this audit record | 1, 2, 3, ... | System-generated sequential ID; immutable |
| table_name | VARCHAR(100) | NOT NULL | Name of table that was modified | 'biomarker_thresholds', 'classification_models', 'cohort_endpoints' | Must be valid table name |
| record_id | VARCHAR(100) | NOT NULL | Primary key value of modified record | '12345', 'PDL1_OS_50PCT', 'NCT04567890_PDL1_HIGH' | Identifies specific modified record |
| action_type | VARCHAR(50) | NOT NULL | Type of modification performed | 'INSERT', 'UPDATE', 'DELETE', 'APPROVE', 'RETIRE' | Standardized action types |
| changed_fields | JSON | NULL | List of fields that were modified | `["threshold_value", "sensitivity", "specificity"]` | Array of column names; NULL for INSERT/DELETE |
| old_values | JSON | NULL | Previous values before modification | `{"threshold_value": 45.0, "sensitivity": 0.82, "specificity": 0.75}` | JSON object with field:value pairs; NULL for INSERT |
| new_values | JSON | NULL | New values after modification | `{"threshold_value": 50.0, "sensitivity": 0.85, "specificity": 0.78}` | JSON object with field:value pairs; NULL for DELETE |
| changed_by | VARCHAR(255) | NOT NULL | User who made the change | 'john.doe@astrazeneca.com', 'SYSTEM', 'api_user_12345' | User identification (email, username, or system) |
| change_reason | TEXT | NULL | Justification for the change | 'Updated threshold based on new validation data', 'Corrected data entry error', 'Model approved for production use' | Required for significant changes |
| change_timestamp | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP, NOT NULL | When the change occurred | '2024-01-15 14:30:22.123456' | System-generated; high precision timestamp |
| ip_address | VARCHAR(50) | NULL | IP address of user who made change | '192.168.1.100', '10.0.0.50', '2001:0db8:85a3::8a2e:0370:7334' | IPv4 or IPv6 address |

**Indexes**:
- PRIMARY KEY on `audit_id`
- COMPOSITE INDEX on (`table_name`, `record_id`) for record-specific audit trail
- COMPOSITE INDEX on (`table_name`, `change_timestamp`) for table-level temporal queries
- INDEX on `changed_by` for user activity tracking
- INDEX on `action_type` for filtering by action
- INDEX on `change_timestamp` for temporal analyses

**Relationships**:
- **Links to**: Any table via `table_name` and `record_id` (polymorphic relationship)
- **Cardinality**: Potentially millions of audit records over time

**Data Quality Checks**:
- `audit_id` should be sequential and never reused
- `table_name` should be a valid table name in database schema
- `action_type` should use controlled vocabulary (INSERT, UPDATE, DELETE)
- For UPDATE actions, `changed_fields`, `old_values`, and `new_values` should all be populated
- For INSERT actions, `old_values` should be NULL
- For DELETE actions, `new_values` should be NULL
- `change_timestamp` should be immutable after record creation
- `changed_by` should never be NULL
- JSON fields should be valid JSON format
- Records should never be deleted from audit_log (append-only table)

**Usage Examples**:
```sql
-- Get complete audit trail for a specific record
SELECT 
    al.audit_id,
    al.action_type,
    al.changed_fields,
    al.old_values,
    al.new_values,
    al.changed_by,
    al.change_reason,
    al.change_timestamp
FROM audit_log al
WHERE al.table_name = 'biomarker_thresholds'
AND al.record_id = 'PDL1_OS_50PCT'
ORDER BY al.change_timestamp DESC;

-- Track user activity
SELECT 
    al.changed_by,
    COUNT(*) AS num_changes,
    MIN(al.change_timestamp) AS first_change,
    MAX(al.change_timestamp) AS last_change,
    COUNT(DISTINCT al.table_name) AS num_tables_modified,
    SUM(CASE WHEN al.action_type = 'INSERT' THEN 1 ELSE 0 END) AS num_inserts,
    SUM(CASE WHEN al.action_type = 'UPDATE' THEN 1 ELSE 0 END) AS num_updates,
    SUM(CASE WHEN al.action_type = 'DELETE' THEN 1 ELSE 0 END) AS num_deletes
FROM audit_log al
WHERE al.change_timestamp >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY al.changed_by
ORDER BY num_changes DESC;

-- Identify recent changes to critical tables
SELECT 
    al.table_name,
    al.record_id,
    al.action_type,
    al.changed_by,
    al.change_reason,
    al.change_timestamp
FROM audit_log al
WHERE al.table_name IN ('classification_models', 'biomarker_thresholds', 'model_validations')
AND al.change_timestamp >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 7 DAY)
ORDER BY al.change_timestamp DESC;

-- Investigate specific field changes
SELECT 
    al.table_name,
    al.record_id,
    JSON_EXTRACT(al.old_values, '$.threshold_value') AS old_threshold,
    JSON_EXTRACT(al.new_values, '$.threshold_value') AS new_threshold,
    al.changed_by,
    al.change_reason,
    al.change_timestamp
FROM audit_log al
WHERE al.table_name = 'biomarker_thresholds'
AND JSON_CONTAINS(al.changed_fields, '"threshold_value"')
ORDER BY al.change_timestamp DESC;

-- Detect unauthorized or suspicious changes
SELECT 
    al.table_name,
    al.record_id,
    al.action_type,
    al.changed_by,
    al.change_timestamp,
    al.ip_address,
    al.change_reason
FROM audit_log al
WHERE (al.change_reason IS NULL OR al.change_reason = '')
AND al.action_type IN ('UPDATE', 'DELETE')
AND al.table_name IN ('classification_models', 'biomarker_thresholds')
ORDER BY al.change_timestamp DESC;

-- Generate compliance report for specific time period
SELECT 
    DATE(al.change_timestamp) AS change_date,
    al.table_name,
    al.action_type,
    COUNT(*) AS num_changes,
    COUNT(DISTINCT al.changed_by) AS num_users,
    COUNT(DISTINCT al.record_id) AS num_records_affected
FROM audit_log al
WHERE al.change_timestamp BETWEEN '2024-01-01' AND '2024-01-31'
GROUP BY change_date, al.table_name, al.action_type
ORDER BY change_date DESC, num_changes DESC;
```

---

### data_quality_issues

**Purpose**: Systematically tracks identified data quality problems, their severity, resolution status, and corrective actions. This table supports data quality management workflows, continuous improvement, and documentation of quality decisions.

**Business Context**: Data quality issues are inevitable in large databases. This table provides a structured approach to identifying, prioritizing, investigating, and resolving quality problems. It demonstrates due diligence in data quality management for regulatory inspections and supports root cause analysis.

**Data Sources**: Automated data quality checks, manual QC reviews, user-reported issues, validation failures.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| issue_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this quality issue | 1, 2, 3, ... | System-generated sequential ID |
| table_name | VARCHAR(100) | NULL | Name of table containing the issue | 'cohort_biomarker_summary', 'biomarker_endpoint_associations', 'cohort_classifications' | NULL if issue spans multiple tables |
| record_id | VARCHAR(100) | NULL | Primary key value of affected record | '12345', 'NCT04567890_PDL1_HIGH', 'IMMUNE_INFLAM_SIG_V1' | NULL if issue affects multiple records |
| issue_type | VARCHAR(100) | NOT NULL | Category of quality issue | 'missing_data', 'inconsistency', 'outlier', 'duplicate', 'invalid_value', 'referential_integrity', 'calculation_error', 'unit_mismatch' | Controlled vocabulary for issue types |
| severity | VARCHAR(50) | NOT NULL | Impact level of the issue | 'critical', 'major', 'minor', 'cosmetic' | Critical=affects key analyses; Major=significant impact; Minor=limited impact; Cosmetic=display only |
| description | TEXT | NOT NULL | Detailed description of the issue | 'Biomarker mean value (150.5) exceeds expected range (0-100) for this assay', 'Missing endpoint data for 15 patients in cohort', 'Duplicate entries for same patient-biomarker-timepoint' | Clear, specific problem description |
| detected_date | DATE | NOT NULL | Date when issue was identified | '2024-01-15', '2023-12-20' | Issue discovery date |
| detected_by | VARCHAR(255) | NOT NULL | Person or system that identified the issue | 'Automated QC Check v2.3', 'Jane Smith', 'User Report #456', 'Validation Pipeline' | Issue reporter identification |
| resolution_status | VARCHAR(50) | NOT NULL | Current status of issue resolution | 'open', 'in_progress', 'resolved', 'closed', 'wont_fix', 'deferred', 'duplicate' | Workflow status |
| resolution_description | TEXT | NULL | Description of how issue was resolved | 'Corrected data entry error; updated value to 85.5', 'Contacted data provider; missing data not available', 'Marked as outlier but biologically plausible; retained in dataset' | Detailed resolution documentation |
| resolved_date | DATE | NULL | Date when issue was resolved | '2024-01-20', '2024-02-05' | Resolution completion date; NULL if not resolved |
| resolved_by | VARCHAR(255) | NULL | Person who resolved the issue | 'John Doe', 'Data Curation Team', 'Senior Biostatistician' | Resolver identification; NULL if not resolved |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when record was created | '2024-01-15 14:30:22' | System-generated |

**Indexes**:
- PRIMARY KEY on `issue_id`
- COMPOSITE INDEX on (`table_name`, `record_id`) for record-specific issues
- COMPOSITE INDEX on (`resolution_status`, `severity`) for prioritization queries
- INDEX on `issue_type` for filtering by issue category
- INDEX on `severity` for filtering by impact
- INDEX on `detected_date` for temporal analyses
- INDEX on `resolved_date` for resolution tracking

**Relationships**:
- **Links to**: Any table via `table_name` and `record_id` (polymorphic relationship)
- **Cardinality**: Potentially thousands of quality issues over time

**Data Quality Checks**:
- `severity` should use controlled vocabulary (critical, major, minor, cosmetic)
- `resolution_status` should use controlled vocabulary
- If `resolution_status` is 'resolved' or 'closed', `resolved_date` and `resolved_by` should be populated
- `resolved_date` should be ≥ `detected_date`
- If `resolution_status` is 'open' or 'in_progress', `resolved_date` should be NULL
- `description` should be detailed and specific
- Critical and major issues should not remain open for extended periods
- `issue_type` should use standardized categories

**Usage Examples**:
```sql
-- Get open critical and major issues
SELECT 
    dqi.issue_id,
    dqi.table_name,
    dqi.issue_type,
    dqi.severity,
    dqi.description,
    dqi.detected_date,
    DATEDIFF(CURRENT_DATE, dqi.detected_date) AS days_open
FROM data_quality_issues dqi
WHERE dqi.resolution_status IN ('open', 'in_progress')
AND dqi.severity IN ('critical', 'major')
ORDER BY dqi.severity, days_open DESC;

-- Analyze issue trends over time
SELECT 
    DATE_FORMAT(dqi.detected_date, '%Y-%m') AS detection_month,
    dqi.issue_type,
    dqi.severity,
    COUNT(*) AS num_issues,
    SUM(CASE WHEN dqi.resolution_status IN ('resolved', 'closed') THEN 1 ELSE 0 END) AS num_resolved,
    AVG(DATEDIFF(dqi.resolved_date, dqi.detected_date)) AS avg_resolution_days
FROM data_quality_issues dqi
WHERE dqi.detected_date >= DATE_SUB(CURRENT_DATE, INTERVAL 12 MONTH)
GROUP BY detection_month, dqi.issue_type, dqi.severity
ORDER BY detection_month DESC, num_issues DESC;

-- Identify tables with most quality issues
SELECT 
    dqi.table_name,
    COUNT(*) AS total_issues,
    SUM(CASE WHEN dqi.severity = 'critical' THEN 1 ELSE 0 END) AS critical_issues,
    SUM(CASE WHEN dqi.severity = 'major' THEN 1 ELSE 0 END) AS major_issues,
    SUM(CASE WHEN dqi.resolution_status IN ('open', 'in_progress') THEN 1 ELSE 0 END) AS open_issues,
    AVG(DATEDIFF(COALESCE(dqi.resolved_date, CURRENT_DATE), dqi.detected_date)) AS avg_days_to_resolve
FROM data_quality_issues dqi
WHERE dqi.table_name IS NOT NULL
GROUP BY dqi.table_name
ORDER BY total_issues DESC;

-- Track resolution performance by resolver
SELECT 
    dqi.resolved_by,
    COUNT(*) AS num_issues_resolved,
    AVG(DATEDIFF(dqi.resolved_date, dqi.detected_date)) AS avg_resolution_days,
    MIN(DATEDIFF(dqi.resolved_date, dqi.detected_date)) AS min_resolution_days,
    MAX(DATEDIFF(dqi.resolved_date, dqi.detected_date)) AS max_resolution_days,
    COUNT(DISTINCT dqi.table_name) AS num_tables_addressed
FROM data_quality_issues dqi
WHERE dqi.resolved_date IS NOT NULL
AND dqi.resolved_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
GROUP BY dqi.resolved_by
ORDER BY num_issues_resolved DESC;

-- Find recurring issues (same type and table)
SELECT 
    dqi.table_name,
    dqi.issue_type,
    COUNT(*) AS num_occurrences,
    MIN(dqi.detected_date) AS first_occurrence,
    MAX(dqi.detected_date) AS last_occurrence,
    COUNT(DISTINCT dqi.detected_by) AS num_reporters
FROM data_quality_issues dqi
GROUP BY dqi.table_name, dqi.issue_type
HAVING num_occurrences >= 3
ORDER BY num_occurrences DESC;

-- Generate quality issue report for specific period
SELECT 
    dqi.severity,
    dqi.issue_type,
    COUNT(*) AS num_issues,
    SUM(CASE WHEN dqi.resolution_status IN ('resolved', 'closed') THEN 1 ELSE 0 END) AS num_resolved,
    ROUND(100.0 * SUM(CASE WHEN dqi.resolution_status IN ('resolved', 'closed') THEN 1 ELSE 0 END) / COUNT(*), 2) AS resolution_rate,
    AVG(CASE WHEN dqi.resolved_date IS NOT NULL 
        THEN DATEDIFF(dqi.resolved_date, dqi.detected_date) END) AS avg_resolution_days
FROM data_quality_issues dqi
WHERE dqi.detected_date BETWEEN '2024-01-01' AND '2024-03-31'
GROUP BY dqi.severity, dqi.issue_type
ORDER BY dqi.severity, num_issues DESC;
```

---

### user_access_log

**Purpose**: Records all user interactions with the database for security monitoring, usage analytics, compliance reporting, and access pattern analysis. This table supports security audits, usage optimization, and regulatory compliance.

**Business Context**: Regulatory requirements and information security policies mandate tracking of who accesses what data, when, and from where. This table provides evidence of appropriate data access controls, supports investigation of potential security incidents, and enables usage analytics for system optimization.

**Data Sources**: Application-level logging, database connection logs, query interceptors, API gateway logs.

| Column Name | Data Type | Constraints | Description | Example Values | Business Rules |
|-------------|-----------|-------------|-------------|----------------|----------------|
| access_id | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier for this access record | 1, 2, 3, ... | System-generated sequential ID |
| user_id | VARCHAR(100) | NOT NULL | Unique identifier for the user | 'john.doe@astrazeneca.com', 'api_key_abc123', 'service_account_biomarker_app' | User identification (email, API key, or service account) |
| user_name | VARCHAR(255) | NULL | Full name of the user | 'John Doe', 'Biomarker Analytics Service', 'External Collaborator' | Human-readable user identification |
| access_type | VARCHAR(50) | NOT NULL | Type of access operation | 'query', 'export', 'update', 'classification', 'model_training', 'report_generation', 'API_call' | Categorization of user activity |
| accessed_table | VARCHAR(100) | NULL | Primary table accessed | 'cohort_biomarker_summary', 'biomarker_endpoint_associations', 'classification_models' | NULL if multiple tables or non-table operation |
| query_details | TEXT | NULL | Details of query or operation performed | 'SELECT * FROM biomarkers WHERE biomarker_type = "genomic"', 'Exported classification results for cohort NCT04567890', 'Trained new model using 5 biomarkers' | Sanitized query text or operation description |
| record_count | INT | NULL, CHECK (record_count >= 0) | Number of records accessed or affected | 150, 1000, 5 | Count of rows returned or modified |
| access_timestamp | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP, NOT NULL | When the access occurred | '2024-01-15 14:30:22.123456' | System-generated; high precision timestamp |
| ip_address | VARCHAR(50) | NULL | IP address of user | '192.168.1.100', '10.0.0.50', '2001:0db8:85a3::8a2e:0370:7334' | IPv4 or IPv6 address |
| session_id | VARCHAR(100) | NULL | Session identifier for grouping related accesses | 'sess_abc123def456', 'token_xyz789', 'connection_12345' | Links related operations within a session |

**Indexes**:
- PRIMARY KEY on `access_id`
- COMPOSITE INDEX on (`user_id`, `access_timestamp`) for user activity tracking
- COMPOSITE INDEX on (`accessed_table`, `access_timestamp`) for table access patterns
- INDEX on `access_type` for filtering by operation type
- INDEX on `access_timestamp` for temporal analyses
- INDEX on `ip_address` for security monitoring
- INDEX on `session_id` for session-based queries

**Relationships**:
- **No foreign key relationships** (logging table)
- **Cardinality**: Potentially millions of access records over time

**Data Quality Checks**:
- `user_id` should never be NULL
- `access_type` should use controlled vocabulary
- `access_timestamp` should be immutable after record creation
- `record_count` should be ≥ 0
- For 'query' access_type, `accessed_table` should typically be populated
- For 'export' access_type, `record_count` should be populated
- `ip_address` should be valid IPv4 or IPv6 format
- Records should never be deleted (append-only table)
- Sensitive information should be sanitized from `query_details`

**Usage Examples**:
```sql
-- Track user activity over time
SELECT 
    ual.user_id,
    ual.user_name,
    COUNT(*) AS num_accesses,
    MIN(ual.access_timestamp) AS first_access,
    MAX(ual.access_timestamp) AS last_access,
    COUNT(DISTINCT ual.accessed_table) AS num_tables_accessed,
    SUM(ual.record_count) AS total_records_accessed
FROM user_access_log ual
WHERE ual.access_timestamp >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY ual.user_id, ual.user_name
ORDER BY num_accesses DESC;

-- Identify most accessed tables
SELECT 
    ual.accessed_table,
    COUNT(*) AS num_accesses,
    COUNT(DISTINCT ual.user_id) AS num_users,
    SUM(ual.record_count) AS total_records_accessed,
    AVG(ual.record_count) AS avg_records_per_access
FROM user_access_log ual
WHERE ual.accessed_table IS NOT NULL
AND ual.access_timestamp >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY)
GROUP BY ual.accessed_table
ORDER BY num_accesses DESC;

-- Monitor data exports
SELECT 
    ual.user_id,
    ual.user_name,
    ual.accessed_table,
    ual.record_count,
    ual.access_timestamp,
    ual.ip_address
FROM user_access_log ual
WHERE ual.access_type = 'export'
AND ual.record_count > 1000
AND ual.access_timestamp >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY)
ORDER BY ual.record_count DESC;

-- Detect unusual access patterns
SELECT 
    ual.user_id,
    DATE(ual.access_timestamp) AS access_date,
    COUNT(*) AS num_accesses,
    COUNT(DISTINCT ual.ip_address) AS num_ip_addresses,
    SUM(ual.record_count) AS total_records
FROM user_access_log ual
WHERE ual.access_timestamp >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY ual.user_id, access_date
HAVING num_accesses > 100
OR num_ip_addresses > 3
ORDER BY num_accesses DESC;

-- Analyze access patterns by time of day
SELECT 
    HOUR(ual.access_timestamp) AS hour_of_day,
    ual.access_type,
    COUNT(*) AS num_accesses,
    COUNT(DISTINCT ual.user_id) AS num_users,
    AVG(ual.record_count) AS avg_records
FROM user_access_log ual
WHERE ual.access_timestamp >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY hour_of_day, ual.access_type
ORDER BY hour_of_day, num_accesses DESC;

-- Generate compliance report for specific user
SELECT 
    ual.access_timestamp,
    ual.access_type,
    ual.accessed_table,
    ual.record_count,
    ual.ip_address,
    LEFT(ual.query_details, 100) AS query_preview
FROM user_access_log ual
WHERE ual.user_id = 'john.doe@astrazeneca.com'
AND ual.access_timestamp BETWEEN '2024-01-01' AND '2024-01-31'
ORDER BY ual.access_timestamp DESC;

-- Identify inactive users
SELECT DISTINCT
    ual.user_id,
    ual.user_name,
    MAX(ual.access_timestamp) AS last_access,
    DATEDIFF(CURRENT_DATE, MAX(ual.access_timestamp)) AS days_since_last_access
FROM user_access_log ual
GROUP BY ual.user_id, ual.user_name
HAVING days_since_last_access > 90
ORDER BY days_since_last_access DESC;
```

---

## Summary

This comprehensive documentation covers all 31 tables in the biomarker database schema with detailed specifications for each column including:

- **Data types and constraints** for proper data validation
- **Business context** explaining the purpose and use cases
- **Relationships** showing how tables connect
- **Data quality checks** ensuring data integrity
- **Usage examples** demonstrating practical queries

### Key Table Categories:

1. **Reference and Metadata** (5 tables): Clinical trials, treatment arms, patient cohorts, endpoints, cohort endpoints
2. **Biomarker and Assay** (3 tables): Biomarkers, assay platforms, assay datasets
3. **Aggregated Measurements** (3 tables): Cohort biomarker summary, distributions, correlations
4. **Statistical Associations** (2 tables): Biomarker-endpoint associations, stratified outcomes
5. **Classification** (6 tables): Models, thresholds, signatures, components, classifications, performance
6. **Validation and Meta-Analysis** (3 tables): Model validations, cross-trial validations, meta-analysis results
7. **Audit and Governance** (4 tables): Data provenance, audit log, data quality issues, user access log

This schema provides a robust foundation for biomarker discovery, classification, validation, and clinical decision support while maintaining complete traceability, data quality, and regulatory compliance.