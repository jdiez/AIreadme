-- ============================================================================
-- REFERENCE AND METADATA TABLES
-- ============================================================================

-- Clinical trials registry
CREATE TABLE clinical_trials (
    trial_id VARCHAR(50) PRIMARY KEY,
    trial_name VARCHAR(255) NOT NULL,
    trial_phase VARCHAR(20),
    sponsor VARCHAR(255),
    indication VARCHAR(255),
    therapeutic_area VARCHAR(255),
    start_date DATE,
    end_date DATE,
    protocol_version VARCHAR(50),
    total_enrolled INT,
    description TEXT,
    publication_references TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Treatment arms/cohorts within trials
CREATE TABLE treatment_arms (
    arm_id VARCHAR(50) PRIMARY KEY,
    trial_id VARCHAR(50) NOT NULL,
    arm_name VARCHAR(255) NOT NULL,
    arm_type VARCHAR(50), -- experimental, control, placebo
    treatment_description TEXT,
    dose_regimen VARCHAR(255),
    sample_size INT,
    FOREIGN KEY (trial_id) REFERENCES clinical_trials(trial_id),
    INDEX idx_trial_arm (trial_id)
);

-- Patient cohorts/subgroups for stratified analyses
CREATE TABLE patient_cohorts (
    cohort_id VARCHAR(50) PRIMARY KEY,
    trial_id VARCHAR(50) NOT NULL,
    arm_id VARCHAR(50),
    cohort_name VARCHAR(255) NOT NULL,
    cohort_description TEXT,
    stratification_criteria TEXT, -- age_group, disease_stage, biomarker_status, etc.
    sample_size INT,
    mean_age DECIMAL(5,2),
    age_std_dev DECIMAL(5,2),
    age_range VARCHAR(50),
    percent_female DECIMAL(5,2),
    disease_stage_distribution JSON,
    baseline_characteristics JSON,
    FOREIGN KEY (trial_id) REFERENCES clinical_trials(trial_id),
    FOREIGN KEY (arm_id) REFERENCES treatment_arms(arm_id),
    INDEX idx_trial_cohort (trial_id, cohort_id)
);

-- Clinical endpoints definition
CREATE TABLE endpoints (
    endpoint_id VARCHAR(50) PRIMARY KEY,
    endpoint_name VARCHAR(255) NOT NULL,
    endpoint_type VARCHAR(50) NOT NULL, -- efficacy, safety, surrogate, composite
    endpoint_category VARCHAR(100), -- OS, PFS, ORR, AE, biomarker_response
    description TEXT,
    measurement_unit VARCHAR(50),
    is_primary BOOLEAN DEFAULT FALSE,
    assessment_timepoint VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cohort-level endpoint outcomes (aggregated)
CREATE TABLE cohort_endpoints (
    cohort_endpoint_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cohort_id VARCHAR(50) NOT NULL,
    endpoint_id VARCHAR(50) NOT NULL,
    assessment_timepoint VARCHAR(100),
    days_from_baseline INT,
    n_evaluated INT,
    n_positive INT, -- number with positive outcome
    n_negative INT, -- number with negative outcome
    response_rate DECIMAL(5,4), -- proportion with positive outcome
    response_rate_ci_lower DECIMAL(5,4),
    response_rate_ci_upper DECIMAL(5,4),
    median_value DECIMAL(15,6),
    mean_value DECIMAL(15,6),
    std_dev DECIMAL(15,6),
    min_value DECIMAL(15,6),
    max_value DECIMAL(15,6),
    quartile_25 DECIMAL(15,6),
    quartile_75 DECIMAL(15,6),
    hazard_ratio DECIMAL(10,6),
    hazard_ratio_ci_lower DECIMAL(10,6),
    hazard_ratio_ci_upper DECIMAL(10,6),
    p_value DECIMAL(10,8),
    statistical_test VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cohort_id) REFERENCES patient_cohorts(cohort_id),
    FOREIGN KEY (endpoint_id) REFERENCES endpoints(endpoint_id),
    INDEX idx_cohort_endpoint (cohort_id, endpoint_id)
);

-- ============================================================================
-- BIOMARKER AND ASSAY TABLES
-- ============================================================================

-- Biomarker definitions and metadata
CREATE TABLE biomarkers (
    biomarker_id VARCHAR(50) PRIMARY KEY,
    biomarker_name VARCHAR(255) NOT NULL,
    biomarker_type VARCHAR(50) NOT NULL, -- genomic, proteomic, metabolomic, imaging, cellular
    measurement_category VARCHAR(100), -- gene_expression, mutation, protein_level, metabolite_concentration
    gene_symbol VARCHAR(50),
    protein_name VARCHAR(255),
    uniprot_id VARCHAR(50),
    ensembl_id VARCHAR(50),
    chromosome VARCHAR(10),
    genomic_position VARCHAR(100),
    pathway VARCHAR(255),
    biological_function TEXT,
    clinical_relevance TEXT,
    standard_nomenclature VARCHAR(255),
    ontology_reference VARCHAR(255), -- HUGO, GO, KEGG, etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_biomarker_type (biomarker_type),
    INDEX idx_gene_symbol (gene_symbol)
);

-- Assay platforms and methods
CREATE TABLE assay_platforms (
    platform_id VARCHAR(50) PRIMARY KEY,
    platform_name VARCHAR(255) NOT NULL,
    platform_type VARCHAR(100), -- RNA-seq, microarray, mass_spec, ELISA, IHC, NGS, flow_cytometry
    manufacturer VARCHAR(255),
    model VARCHAR(255),
    technology VARCHAR(255),
    measurement_type VARCHAR(100), -- absolute, relative, categorical, binary
    measurement_unit VARCHAR(50),
    detection_limit DECIMAL(15,6),
    quantification_limit DECIMAL(15,6),
    dynamic_range_min DECIMAL(15,6),
    dynamic_range_max DECIMAL(15,6),
    protocol_reference TEXT,
    validation_status VARCHAR(50), -- research_use, validated, FDA_approved, CE_marked
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dataset-level assay information
CREATE TABLE assay_datasets (
    dataset_id VARCHAR(50) PRIMARY KEY,
    trial_id VARCHAR(50) NOT NULL,
    platform_id VARCHAR(50) NOT NULL,
    dataset_name VARCHAR(255) NOT NULL,
    dataset_description TEXT,
    collection_timepoint VARCHAR(100),
    specimen_type VARCHAR(100), -- blood, plasma, serum, tissue, PBMC
    sample_size INT,
    processing_protocol TEXT,
    normalization_method VARCHAR(255),
    batch_correction_applied BOOLEAN DEFAULT FALSE,
    batch_correction_method VARCHAR(255),
    quality_control_criteria TEXT,
    data_availability VARCHAR(50), -- public, restricted, proprietary
    data_repository VARCHAR(255),
    accession_number VARCHAR(100),
    publication_doi VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trial_id) REFERENCES clinical_trials(trial_id),
    FOREIGN KEY (platform_id) REFERENCES assay_platforms(platform_id),
    INDEX idx_trial_dataset (trial_id)
);

-- ============================================================================
-- AGGREGATED MOLECULAR MEASUREMENTS
-- ============================================================================

-- Cohort-level biomarker summary statistics
CREATE TABLE cohort_biomarker_summary (
    summary_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cohort_id VARCHAR(50) NOT NULL,
    dataset_id VARCHAR(50) NOT NULL,
    biomarker_id VARCHAR(50) NOT NULL,
    n_samples INT NOT NULL,
    n_detected INT, -- number of samples with detectable levels
    detection_rate DECIMAL(5,4),
    mean_value DECIMAL(20,8),
    median_value DECIMAL(20,8),
    std_dev DECIMAL(20,8),
    std_error DECIMAL(20,8),
    min_value DECIMAL(20,8),
    max_value DECIMAL(20,8),
    quartile_25 DECIMAL(20,8),
    quartile_75 DECIMAL(20,8),
    percentile_10 DECIMAL(20,8),
    percentile_90 DECIMAL(20,8),
    geometric_mean DECIMAL(20,8),
    coefficient_variation DECIMAL(10,6),
    skewness DECIMAL(10,6),
    kurtosis DECIMAL(10,6),
    measurement_unit VARCHAR(50),
    transformation_applied VARCHAR(100), -- log2, log10, sqrt, none
    outliers_removed INT,
    quality_flags TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cohort_id) REFERENCES patient_cohorts(cohort_id),
    FOREIGN KEY (dataset_id) REFERENCES assay_datasets(dataset_id),
    FOREIGN KEY (biomarker_id) REFERENCES biomarkers(biomarker_id),
    INDEX idx_cohort_biomarker (cohort_id, biomarker_id),
    INDEX idx_dataset_biomarker (dataset_id, biomarker_id)
);

-- Distribution bins for biomarker values (histogram data)
CREATE TABLE biomarker_distributions (
    distribution_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    summary_id BIGINT NOT NULL,
    bin_number INT NOT NULL,
    bin_lower_bound DECIMAL(20,8),
    bin_upper_bound DECIMAL(20,8),
    bin_count INT,
    bin_frequency DECIMAL(8,6),
    cumulative_frequency DECIMAL(8,6),
    FOREIGN KEY (summary_id) REFERENCES cohort_biomarker_summary(summary_id),
    INDEX idx_summary_distribution (summary_id)
);

-- Biomarker correlations within cohorts
CREATE TABLE biomarker_correlations (
    correlation_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cohort_id VARCHAR(50) NOT NULL,
    dataset_id VARCHAR(50) NOT NULL,
    biomarker_1_id VARCHAR(50) NOT NULL,
    biomarker_2_id VARCHAR(50) NOT NULL,
    correlation_coefficient DECIMAL(10,8),
    correlation_type VARCHAR(50), -- pearson, spearman, kendall
    p_value DECIMAL(15,10),
    n_samples INT,
    confidence_interval_lower DECIMAL(10,8),
    confidence_interval_upper DECIMAL(10,8),
    FOREIGN KEY (cohort_id) REFERENCES patient_cohorts(cohort_id),
    FOREIGN KEY (dataset_id) REFERENCES assay_datasets(dataset_id),
    FOREIGN KEY (biomarker_1_id) REFERENCES biomarkers(biomarker_id),
    FOREIGN KEY (biomarker_2_id) REFERENCES biomarkers(biomarker_id),
    INDEX idx_cohort_correlation (cohort_id, biomarker_1_id, biomarker_2_id)
);

-- ============================================================================
-- BIOMARKER-ENDPOINT ASSOCIATIONS
-- ============================================================================

-- Statistical associations between biomarkers and endpoints
CREATE TABLE biomarker_endpoint_associations (
    association_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cohort_id VARCHAR(50) NOT NULL,
    biomarker_id VARCHAR(50) NOT NULL,
    endpoint_id VARCHAR(50) NOT NULL,
    dataset_id VARCHAR(50) NOT NULL,
    analysis_type VARCHAR(100), -- univariate, multivariate, survival_analysis
    statistical_test VARCHAR(100), -- t_test, mann_whitney, log_rank, cox_regression
    test_statistic DECIMAL(15,8),
    p_value DECIMAL(15,10),
    adjusted_p_value DECIMAL(15,10), -- FDR or Bonferroni corrected
    effect_size DECIMAL(15,8),
    effect_size_type VARCHAR(50), -- cohens_d, odds_ratio, hazard_ratio, correlation
    confidence_interval_lower DECIMAL(15,8),
    confidence_interval_upper DECIMAL(15,8),
    n_samples INT,
    covariates_adjusted TEXT, -- list of adjustment variables
    association_direction VARCHAR(50), -- positive, negative, none
    clinical_significance VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cohort_id) REFERENCES patient_cohorts(cohort_id),
    FOREIGN KEY (biomarker_id) REFERENCES biomarkers(biomarker_id),
    FOREIGN KEY (endpoint_id) REFERENCES endpoints(endpoint_id),
    FOREIGN KEY (dataset_id) REFERENCES assay_datasets(dataset_id),
    INDEX idx_biomarker_endpoint (biomarker_id, endpoint_id),
    INDEX idx_cohort_association (cohort_id, biomarker_id)
);

-- Stratified analysis by biomarker levels
CREATE TABLE stratified_outcomes (
    stratified_outcome_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    association_id BIGINT NOT NULL,
    biomarker_stratum VARCHAR(100) NOT NULL, -- low, medium, high, or quartile_1, quartile_2, etc.
    stratum_definition TEXT, -- threshold values or percentile ranges
    n_samples INT,
    n_positive_outcome INT,
    n_negative_outcome INT,
    outcome_rate DECIMAL(5,4),
    outcome_rate_ci_lower DECIMAL(5,4),
    outcome_rate_ci_upper DECIMAL(5,4),
    median_outcome_value DECIMAL(15,6),
    hazard_ratio DECIMAL(10,6),
    hazard_ratio_ci_lower DECIMAL(10,6),
    hazard_ratio_ci_upper DECIMAL(10,6),
    p_value DECIMAL(15,10),
    FOREIGN KEY (association_id) REFERENCES biomarker_endpoint_associations(association_id),
    INDEX idx_association_stratum (association_id)
);

-- ============================================================================
-- BIOMARKER CLASSIFICATION TABLES
-- ============================================================================

-- Classification models and versions
CREATE TABLE classification_models (
    model_id VARCHAR(50) PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    model_type VARCHAR(100), -- logistic_regression, random_forest, SVM, neural_network, threshold_based
    algorithm_details TEXT,
    training_cohorts TEXT, -- list of cohort_ids used for training
    training_sample_size INT,
    development_date DATE,
    validation_status VARCHAR(50), -- development, internal_validation, external_validation, production
    intended_use TEXT,
    model_features JSON, -- list of biomarkers and their roles
    hyperparameters JSON,
    feature_importance JSON,
    model_file_path VARCHAR(500),
    created_by VARCHAR(255),
    approved_by VARCHAR(255),
    approval_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_model_version (model_name, model_version)
);

-- Biomarker thresholds and cutpoints
CREATE TABLE biomarker_thresholds (
    threshold_id VARCHAR(50) PRIMARY KEY,
    biomarker_id VARCHAR(50) NOT NULL,
    endpoint_id VARCHAR(50) NOT NULL,
    model_id VARCHAR(50) NOT NULL,
    threshold_type VARCHAR(50), -- optimal, percentile, clinical, ROC_based, youden
    threshold_value DECIMAL(20,8) NOT NULL,
    threshold_unit VARCHAR(50),
    percentile_rank DECIMAL(5,2),
    derivation_cohorts TEXT, -- cohort_ids used to derive threshold
    derivation_sample_size INT,
    sensitivity DECIMAL(5,4),
    specificity DECIMAL(5,4),
    ppv DECIMAL(5,4),
    npv DECIMAL(5,4),
    accuracy DECIMAL(5,4),
    auc_roc DECIMAL(5,4),
    confidence_interval_lower DECIMAL(20,8),
    confidence_interval_upper DECIMAL(20,8),
    determination_method TEXT,
    clinical_rationale TEXT,
    effective_date DATE,
    expiration_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (biomarker_id) REFERENCES biomarkers(biomarker_id),
    FOREIGN KEY (endpoint_id) REFERENCES endpoints(endpoint_id),
    FOREIGN KEY (model_id) REFERENCES classification_models(model_id),
    INDEX idx_biomarker_endpoint (biomarker_id, endpoint_id),
    INDEX idx_active_thresholds (is_active, biomarker_id)
);

-- Multi-biomarker signatures/panels
CREATE TABLE biomarker_signatures (
    signature_id VARCHAR(50) PRIMARY KEY,
    signature_name VARCHAR(255) NOT NULL,
    signature_version VARCHAR(50),
    description TEXT,
    signature_type VARCHAR(100), -- composite_score, risk_score, predictive_index, gene_expression_signature
    calculation_formula TEXT,
    intended_endpoint VARCHAR(255),
    development_cohorts TEXT,
    validation_cohorts TEXT,
    clinical_utility TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Components of multi-biomarker signatures
CREATE TABLE signature_components (
    signature_component_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    signature_id VARCHAR(50) NOT NULL,
    biomarker_id VARCHAR(50) NOT NULL,
    weight_coefficient DECIMAL(10,6),
    component_order INT,
    transformation VARCHAR(100), -- log, sqrt, standardize, none
    FOREIGN KEY (signature_id) REFERENCES biomarker_signatures(signature_id),
    FOREIGN KEY (biomarker_id) REFERENCES biomarkers(biomarker_id),
    INDEX idx_signature (signature_id)
);

-- Cohort-level classification results
CREATE TABLE cohort_classifications (
    cohort_classification_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cohort_id VARCHAR(50) NOT NULL,
    biomarker_id VARCHAR(50),
    signature_id VARCHAR(50),
    endpoint_id VARCHAR(50) NOT NULL,
    model_id VARCHAR(50) NOT NULL,
    threshold_id VARCHAR(50),
    classification_date DATE NOT NULL,
    total_samples INT,
    n_positive INT,
    n_negative INT,
    n_indeterminate INT,
    positive_rate DECIMAL(5,4),
    positive_rate_ci_lower DECIMAL(5,4),
    positive_rate_ci_upper DECIMAL(5,4),
    mean_predicted_probability DECIMAL(5,4),
    median_predicted_probability DECIMAL(5,4),
    mean_biomarker_value DECIMAL(20,8),
    threshold_used DECIMAL(20,8),
    classification_method VARCHAR(100),
    quality_flags TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cohort_id) REFERENCES patient_cohorts(cohort_id),
    FOREIGN KEY (biomarker_id) REFERENCES biomarkers(biomarker_id),
    FOREIGN KEY (signature_id) REFERENCES biomarker_signatures(signature_id),
    FOREIGN KEY (endpoint_id) REFERENCES endpoints(endpoint_id),
    FOREIGN KEY (model_id) REFERENCES classification_models(model_id),
    FOREIGN KEY (threshold_id) REFERENCES biomarker_thresholds(threshold_id),
    INDEX idx_cohort_classification (cohort_id, endpoint_id),
    INDEX idx_biomarker_classification (biomarker_id, endpoint_id)
);

-- Classification performance by biomarker status
CREATE TABLE classification_performance_by_status (
    performance_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cohort_classification_id BIGINT NOT NULL,
    biomarker_status VARCHAR(50) NOT NULL, -- positive, negative
    n_samples INT,
    n_positive_outcome INT,
    n_negative_outcome INT,
    outcome_rate DECIMAL(5,4),
    outcome_rate_ci_lower DECIMAL(5,4),
    outcome_rate_ci_upper DECIMAL(5,4),
    median_survival_days INT,
    hazard_ratio DECIMAL(10,6),
    hazard_ratio_ci_lower DECIMAL(10,6),
    hazard_ratio_ci_upper DECIMAL(10,6),
    p_value DECIMAL(15,10),
    FOREIGN KEY (cohort_classification_id) REFERENCES cohort_classifications(cohort_classification_id),
    INDEX idx_cohort_performance (cohort_classification_id)
);

-- ============================================================================
-- VALIDATION AND PERFORMANCE TRACKING TABLES
-- ============================================================================

-- Model validation results
CREATE TABLE model_validations (
    validation_id VARCHAR(50) PRIMARY KEY,
    model_id VARCHAR(50) NOT NULL,
    validation_type VARCHAR(50), -- internal, external, cross_validation, temporal, prospective
    validation_cohorts TEXT, -- list of cohort_ids
    validation_date DATE,
    total_sample_size INT,
    auc_roc DECIMAL(5,4),
    auc_roc_ci_lower DECIMAL(5,4),
    auc_roc_ci_upper DECIMAL(5,4),
    sensitivity DECIMAL(5,4),
    specificity DECIMAL(5,4),
    ppv DECIMAL(5,4),
    npv DECIMAL(5,4),
    accuracy DECIMAL(5,4),
    f1_score DECIMAL(5,4),
    balanced_accuracy DECIMAL(5,4),
    matthews_correlation DECIMAL(5,4),
    calibration_slope DECIMAL(10,6),
    calibration_intercept DECIMAL(10,6),
    brier_score DECIMAL(5,4),
    confusion_matrix JSON,
    roc_curve_data JSON,
    calibration_plot_data JSON,
    subgroup_performance JSON,
    validation_report_path VARCHAR(500),
    validated_by VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES classification_models(model_id),
    INDEX idx_model_validation (model_id, validation_type)
);

-- Cross-trial validation results
CREATE TABLE cross_trial_validations (
    cross_validation_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    model_id VARCHAR(50) NOT NULL,
    training_trial_id VARCHAR(50) NOT NULL,
    validation_trial_id VARCHAR(50) NOT NULL,
    validation_date DATE,
    sample_size INT,
    auc_roc DECIMAL(5,4),
    sensitivity DECIMAL(5,4),
    specificity DECIMAL(5,4),
    accuracy DECIMAL(5,4),
    generalizability_score DECIMAL(5,4),
    notes TEXT,
    FOREIGN KEY (model_id) REFERENCES classification_models(model_id),
    FOREIGN KEY (training_trial_id) REFERENCES clinical_trials(trial_id),
    FOREIGN KEY (validation_trial_id) REFERENCES clinical_trials(trial_id),
    INDEX idx_cross_validation (model_id, validation_trial_id)
);

-- Meta-analysis results across multiple cohorts
CREATE TABLE meta_analysis_results (
    meta_analysis_id VARCHAR(50) PRIMARY KEY,
    biomarker_id VARCHAR(50) NOT NULL,
    endpoint_id VARCHAR(50) NOT NULL,
    analysis_name VARCHAR(255),
    included_cohorts TEXT, -- list of cohort_ids
    total_sample_size INT,
    number_of_cohorts INT,
    pooled_effect_size DECIMAL(15,8),
    effect_size_type VARCHAR(50), -- odds_ratio, hazard_ratio, mean_difference
    pooled_ci_lower DECIMAL(15,8),
    pooled_ci_upper DECIMAL(15,8),
    pooled_p_value DECIMAL(15,10),
    heterogeneity_i2 DECIMAL(5,2), -- I-squared statistic
    heterogeneity_tau2 DECIMAL(10,6),
    heterogeneity_p_value DECIMAL(15,10),
    meta_analysis_method VARCHAR(100), -- fixed_effects, random_effects, DerSimonian_Laird
    publication_bias_test VARCHAR(100),
    publication_bias_p_value DECIMAL(15,10),
    forest_plot_data JSON,
    analysis_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (biomarker_id) REFERENCES biomarkers(biomarker_id),
    FOREIGN KEY (endpoint_id) REFERENCES endpoints(endpoint_id),
    INDEX idx_meta_analysis (biomarker_id, endpoint_id)
);

-- ============================================================================
-- AUDIT AND COMPLIANCE TABLES
-- ============================================================================

-- Data provenance and lineage
CREATE TABLE data_provenance (
    provenance_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_table VARCHAR(100) NOT NULL,
    source_record_id VARCHAR(100) NOT NULL,
    data_source VARCHAR(255), -- publication, database, internal_analysis
    source_reference VARCHAR(500), -- DOI, accession number, file path
    extraction_date DATE,
    extraction_method TEXT,
    data_quality_score DECIMAL(3,2),
    curator VARCHAR(255),
    verification_status VARCHAR(50), -- unverified, verified, validated
    verified_by VARCHAR(255),
    verification_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_source_table (source_table, source_record_id)
);

-- Audit trail for data changes
CREATE TABLE audit_log (
    audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id VARCHAR(100) NOT NULL,
    action_type VARCHAR(50) NOT NULL, -- INSERT, UPDATE, DELETE
    changed_fields JSON,
    old_values JSON,
    new_values JSON,
    changed_by VARCHAR(255),
    change_reason TEXT,
    change_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(50),
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_timestamp (change_timestamp)
);

-- Data quality issues and resolutions
CREATE TABLE data_quality_issues (
    issue_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100),
    record_id VARCHAR(100),
    issue_type VARCHAR(100), -- missing_data, inconsistency, outlier, duplicate
    severity VARCHAR(50), -- critical, major, minor
    description TEXT,
    detected_date DATE,
    detected_by VARCHAR(255),
    resolution_status VARCHAR(50), -- open, in_progress, resolved, closed, wont_fix
    resolution_description TEXT,
    resolved_date DATE,
    resolved_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_issue_status (resolution_status, severity)
);

-- User access log
CREATE TABLE user_access_log (
    access_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    user_name VARCHAR(255),
    access_type VARCHAR(50), -- query, export, update, classification
    accessed_table VARCHAR(100),
    query_details TEXT,
    record_count INT,
    access_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(50),
    session_id VARCHAR(100),
    INDEX idx_user_access (user_id, access_timestamp)
);


-- ============================================================================
-- PERFORMANCE OPTIMIZATION INDEXES
-- ============================================================================

-- Composite indexes for common query patterns
CREATE INDEX idx_cohort_summary_composite ON cohort_biomarker_summary(cohort_id, biomarker_id, mean_value);
CREATE INDEX idx_associations_composite ON biomarker_endpoint_associations(biomarker_id, endpoint_id, p_value);
CREATE INDEX idx_classifications_composite ON cohort_classifications(cohort_id, endpoint_id, positive_rate);
CREATE INDEX idx_thresholds_active ON biomarker_thresholds(biomarker_id, endpoint_id, is_active);
CREATE INDEX idx_validation_model ON model_validations(model_id, validation_type, auc_roc);

-- Full-text search indexes
CREATE FULLTEXT INDEX idx_biomarker_search ON biomarkers(biomarker_name, biological_function, clinical_relevance);
CREATE FULLTEXT INDEX idx_trial_search ON clinical_trials(trial_name, indication, description);
CREATE FULLTEXT INDEX idx_endpoint_search ON endpoints(endpoint_name, description);


-- ============================================================================
-- EXAMPLE QUERIES
-- ============================================================================

-- Find biomarkers significantly associated with a specific endpoint across multiple trials
SELECT 
    b.biomarker_name,
    e.endpoint_name,
    COUNT(DISTINCT bea.cohort_id) AS num_cohorts,
    AVG(bea.effect_size) AS avg_effect_size,
    MIN(bea.adjusted_p_value) AS best_p_value
FROM biomarker_endpoint_associations bea
JOIN biomarkers b ON bea.biomarker_id = b.biomarker_id
JOIN endpoints e ON bea.endpoint_id = e.endpoint_id
WHERE e.endpoint_name = 'Overall Survival'
    AND bea.adjusted_p_value < 0.05
GROUP BY b.biomarker_name, e.endpoint_name
HAVING COUNT(DISTINCT bea.cohort_id) >= 2
ORDER BY best_p_value;

-- Get classification performance for a specific biomarker
SELECT 
    pc.cohort_name,
    ct.trial_name,
    cc.total_samples,
    cc.positive_rate,
    cpbs_pos.outcome_rate AS positive_outcome_rate,
    cpbs_neg.outcome_rate AS negative_outcome_rate,
    cpbs_pos.hazard_ratio
FROM cohort_classifications cc
JOIN patient_cohorts pc ON cc.cohort_id = pc.cohort_id
JOIN clinical_trials ct ON pc.trial_id = ct.trial_id
JOIN classification_performance_by_status cpbs_pos 
    ON cc.cohort_classification_id = cpbs_pos.cohort_classification_id
    AND cpbs_pos.biomarker_status = 'positive'
JOIN classification_performance_by_status cpbs_neg 
    ON cc.cohort_classification_id = cpbs_neg.cohort_classification_id
    AND cpbs_neg.biomarker_status = 'negative'
WHERE cc.biomarker_id = 'BIOMARKER_001';

-- Compare biomarker distributions across treatment arms
SELECT 
    ta.arm_name,
    b.biomarker_name,
    cbs.n_samples,
    cbs.mean_value,
    cbs.median_value,
    cbs.std_dev
FROM cohort_biomarker_summary cbs
JOIN patient_cohorts pc ON cbs.cohort_id = pc.cohort_id
JOIN treatment_arms ta ON pc.arm_id = ta.arm_id
JOIN biomarkers b ON cbs.biomarker_id = b.biomarker_id
WHERE ta.trial_id = 'TRIAL_001'
    AND b.biomarker_id = 'BIOMARKER_001'
ORDER BY ta.arm_name;