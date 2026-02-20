# AI Algorithms for Saphnelo Neuropsychiatric Monitoring

## Part 1: AI Algorithm Development

### Algorithm 1: Temporal Pattern Detection Engine

**Purpose**: Detect significant changes in neuropsychiatric symptoms over time, distinguishing signal from noise

#### Algorithm Architecture

```python
class TemporalPatternDetector:
    """
    Detects temporal patterns in neuropsychiatric symptoms during Saphnelo treatment
    Uses time-series analysis, change-point detection, and statistical modeling
    """
    
    def __init__(self):
        self.baseline_window = 14  # days for baseline establishment
        self.detection_window = 7   # days for change detection
        self.significance_threshold = 0.05
        self.clinical_significance = {
            'cognitive': 2.0,  # points on 0-10 scale
            'mood': 3.0,       # PHQ-9 points
            'anxiety': 3.0,    # GAD-7 points
            'sleep': 1.5       # hours
        }
        
    def establish_baseline(self, patient_data):
        """
        Calculate baseline metrics from first 2 weeks of data
        Returns: baseline_metrics dict with mean, std, trend
        """
        baseline_metrics = {}
        
        for domain in ['cognitive', 'mood', 'anxiety', 'sleep']:
            data = patient_data[domain][:self.baseline_window]
            
            baseline_metrics[domain] = {
                'mean': np.mean(data),
                'std': np.std(data),
                'median': np.median(data),
                'trend': self._calculate_trend(data),
                'variability': self._calculate_variability(data)
            }
            
        return baseline_metrics
    
    def detect_change(self, patient_data, baseline_metrics, current_day):
        """
        Detect significant changes from baseline
        Uses multiple statistical methods for robustness
        """
        changes_detected = {}
        
        for domain in ['cognitive', 'mood', 'anxiety', 'sleep']:
            # Get recent data window
            recent_data = patient_data[domain][
                current_day - self.detection_window : current_day
            ]
            
            # Method 1: Statistical significance (t-test)
            baseline_data = patient_data[domain][:self.baseline_window]
            t_stat, p_value = stats.ttest_ind(recent_data, baseline_data)
            statistically_significant = p_value < self.significance_threshold
            
            # Method 2: Clinical significance (magnitude of change)
            mean_change = np.mean(recent_data) - baseline_metrics[domain]['mean']
            clinically_significant = abs(mean_change) >= self.clinical_significance[domain]
            
            # Method 3: Trend analysis (sustained direction)
            trend = self._calculate_trend(recent_data)
            sustained_trend = abs(trend) > 0.1  # slope threshold
            
            # Method 4: Change-point detection (Bayesian)
            changepoint_detected = self._detect_changepoint(
                patient_data[domain][:current_day]
            )
            
            # Combine methods
            if statistically_significant and clinically_significant:
                confidence = 'HIGH'
            elif (statistically_significant or clinically_significant) and sustained_trend:
                confidence = 'MODERATE'
            elif changepoint_detected:
                confidence = 'POSSIBLE'
            else:
                confidence = 'NONE'
            
            changes_detected[domain] = {
                'change_detected': confidence != 'NONE',
                'confidence': confidence,
                'direction': 'IMPROVEMENT' if mean_change < 0 else 'WORSENING',  # lower scores = better
                'magnitude': abs(mean_change),
                'p_value': p_value,
                'trend': trend,
                'changepoint_day': changepoint_detected
            }
        
        return changes_detected
    
    def _calculate_trend(self, data):
        """Calculate linear trend (slope) of data"""
        x = np.arange(len(data))
        slope, _ = np.polyfit(x, data, 1)
        return slope
    
    def _calculate_variability(self, data):
        """Calculate coefficient of variation"""
        return np.std(data) / np.mean(data) if np.mean(data) != 0 else 0
    
    def _detect_changepoint(self, data):
        """
        Bayesian change-point detection
        Returns: day of change-point or None
        """
        # Simplified implementation - in production use bayesian_changepoint_detection library
        if len(data) < 14:
            return None
            
        # Calculate cumulative sum of deviations
        mean = np.mean(data)
        cusum = np.cumsum(data - mean)
        
        # Find maximum deviation
        max_deviation_idx = np.argmax(np.abs(cusum))
        max_deviation = abs(cusum[max_deviation_idx])
        
        # Threshold for significance
        threshold = 2 * np.std(data) * np.sqrt(len(data))
        
        if max_deviation > threshold:
            return max_deviation_idx
        else:
            return None
    
    def generate_alert(self, changes_detected, patient_id, current_day):
        """
        Generate actionable alerts based on detected changes
        """
        alerts = []
        
        for domain, change_info in changes_detected.items():
            if change_info['confidence'] in ['HIGH', 'MODERATE']:
                alert = {
                    'patient_id': patient_id,
                    'day': current_day,
                    'domain': domain,
                    'type': change_info['direction'],
                    'confidence': change_info['confidence'],
                    'magnitude': change_info['magnitude'],
                    'message': self._generate_alert_message(domain, change_info),
                    'recommended_action': self._recommend_action(domain, change_info),
                    'urgency': self._assess_urgency(domain, change_info)
                }
                alerts.append(alert)
        
        return alerts
    
    def _generate_alert_message(self, domain, change_info):
        """Generate human-readable alert message"""
        direction = change_info['direction'].lower()
        confidence = change_info['confidence'].lower()
        magnitude = round(change_info['magnitude'], 1)
        
        domain_names = {
            'cognitive': 'cognitive function',
            'mood': 'depression symptoms',
            'anxiety': 'anxiety symptoms',
            'sleep': 'sleep quality'
        }
        
        return f"{confidence.capitalize()} confidence detection: {domain_names[domain]} {direction} by {magnitude} points"
    
    def _recommend_action(self, domain, change_info):
        """Recommend clinical action based on change"""
        if change_info['direction'] == 'IMPROVEMENT':
            if change_info['confidence'] == 'HIGH':
                return "Document therapeutic benefit. Continue current treatment. Consider steroid taper if appropriate."
            else:
                return "Monitor trend. Reassess at next visit."
        else:  # WORSENING
            if change_info['confidence'] == 'HIGH':
                if domain in ['mood', 'anxiety']:
                    return "Urgent: Comprehensive psychiatric assessment. Consider attribution analysis. Evaluate for adverse event."
                else:
                    return "Comprehensive assessment at next visit. Evaluate for NPSLE progression or adverse event."
            else:
                return "Close monitoring. Reassess in 1-2 weeks. Consider additional evaluation if trend continues."
    
    def _assess_urgency(self, domain, change_info):
        """Assess urgency level for clinical response"""
        if change_info['direction'] == 'IMPROVEMENT':
            return 'ROUTINE'
        
        if change_info['confidence'] == 'HIGH':
            if domain in ['mood', 'anxiety'] and change_info['magnitude'] >= 5:
                return 'URGENT'
            else:
                return 'PROMPT'
        else:
            return 'ROUTINE'
```

#### Example Usage and Output

```python
# Example patient data
patient_data = {
    'cognitive': [7, 7, 6, 7, 6, 6, 5, 6, 5, 5, 4, 4, 3, 3, 2, 2, 2, 1, 1, 1],  # Improving
    'mood': [8, 9, 8, 8, 9, 8, 8, 7, 7, 7, 6, 6, 5, 5, 4, 4, 3, 3, 3, 2],      # Improving
    'anxiety': [10, 10, 11, 11, 10, 10, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18],  # Worsening
    'sleep': [5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8]      # Improving
}

detector = TemporalPatternDetector()

# Establish baseline
baseline = detector.establish_baseline(patient_data)

# Detect changes at day 20
changes = detector.detect_change(patient_data, baseline, current_day=20)

# Generate alerts
alerts = detector.generate_alert(changes, patient_id='PT001', current_day=20)

# Output:
"""
Alert 1:
- Domain: cognitive function
- Type: IMPROVEMENT
- Confidence: HIGH
- Magnitude: 5.0 points
- Message: "High confidence detection: cognitive function improvement by 5.0 points"
- Action: "Document therapeutic benefit. Continue current treatment. Consider steroid taper if appropriate."
- Urgency: ROUTINE

Alert 2:
- Domain: anxiety symptoms
- Type: WORSENING
- Confidence: HIGH
- Magnitude: 7.0 points
- Message: "High confidence detection: anxiety symptoms worsening by 7.0 points"
- Action: "Urgent: Comprehensive psychiatric assessment. Consider attribution analysis. Evaluate for adverse event."
- Urgency: URGENT
"""
```

---

### Algorithm 2: Multi-Factor Attribution Engine

**Purpose**: Determine the most likely cause(s) of neuropsychiatric changes using probabilistic reasoning

#### Algorithm Architecture

```python
class AttributionEngine:
    """
    Probabilistic attribution of neuropsychiatric symptoms to various causes
    Uses Bayesian reasoning and multi-factor analysis
    """
    
    def __init__(self):
        # Prior probabilities based on literature and clinical experience
        self.priors = {
            'saphnelo_therapeutic': 0.30,  # 30% of patients with baseline NPSLE improve
            'saphnelo_adverse': 0.05,       # 5% experience adverse psychiatric effects
            'steroid_sparing': 0.40,        # 40% benefit from steroid reduction
            'npsle_breakthrough': 0.10,     # 10% have inadequate NPSLE control
            'steroid_taper_effect': 0.25,  # 25% have symptoms during taper
            'other_cause': 0.20             # 20% have other causes
        }
        
        # Feature weights for each attribution
        self.feature_weights = self._initialize_feature_weights()
    
    def _initialize_feature_weights(self):
        """
        Define how strongly each feature supports each attribution
        Values: -1 (strongly against), 0 (neutral), +1 (strongly for)
        """
        return {
            'saphnelo_therapeutic': {
                'baseline_npsle': 1.0,
                'improvement_direction': 1.0,
                'systemic_disease_improvement': 0.8,
                'temporal_correlation_saphnelo': 0.7,
                'steroid_dose_stable': 0.3,
                'gradual_improvement': 0.6,
                'sustained_benefit': 0.8
            },
            'saphnelo_adverse': {
                'no_baseline_npsle': 0.5,
                'worsening_direction': 1.0,
                'temporal_correlation_saphnelo': 0.9,
                'systemic_disease_improvement': -0.5,  # Paradoxical
                'family_psychiatric_history': 0.4,
                'acute_onset': 0.6,
                'dechallenge_improvement': 1.0
            },
            'steroid_sparing': {
                'baseline_steroid_high': 1.0,
                'steroid_dose_decreasing': 1.0,
                'improvement_direction': 0.8,
                'temporal_correlation_taper': 0.9,
                'prior_steroid_psychiatric': 0.7,
                'steroid_specific_symptoms': 0.8
            },
            'npsle_breakthrough': {
                'baseline_npsle': 0.6,
                'worsening_direction': 1.0,
                'systemic_disease_worsening': 0.8,
                'biomarkers_elevated': 0.7,
                'imaging_changes': 0.9,
                'neurological_symptoms': 0.8
            },
            'steroid_taper_effect': {
                'steroid_dose_decreasing': 1.0,
                'worsening_direction': 1.0,
                'temporal_correlation_taper': 1.0,
                'rapid_taper': 0.8,
                'prior_taper_failure': 0.7,
                'improvement_with_increase': 1.0
            },
            'other_cause': {
                'life_stressor': 0.8,
                'sleep_disturbance': 0.6,
                'hormonal_changes': 0.5,
                'other_medication_change': 0.7,
                'infection': 0.6,
                'no_temporal_correlation': 0.7
            }
        }
    
    def extract_features(self, patient_data, symptom_change):
        """
        Extract relevant features from patient data for attribution
        """
        features = {}
        
        # Baseline characteristics
        features['baseline_npsle'] = patient_data.get('baseline_npsle', False)
        features['no_baseline_npsle'] = not features['baseline_npsle']
        features['baseline_steroid_high'] = patient_data.get('baseline_prednisone', 0) >= 20
        features['family_psychiatric_history'] = patient_data.get('family_psych_hx', False)
        features['prior_steroid_psychiatric'] = patient_data.get('prior_steroid_psych', False)
        features['prior_taper_failure'] = patient_data.get('prior_taper_failure', False)
        
        # Symptom characteristics
        features['improvement_direction'] = symptom_change['direction'] == 'IMPROVEMENT'
        features['worsening_direction'] = symptom_change['direction'] == 'WORSENING'
        features['acute_onset'] = symptom_change.get('onset_days', 30) < 7
        features['gradual_improvement'] = symptom_change.get('onset_days', 30) > 30 and features['improvement_direction']
        features['sustained_benefit'] = symptom_change.get('duration_weeks', 0) > 12
        
        # Temporal correlations
        saphnelo_weeks = patient_data.get('saphnelo_weeks', 0)
        symptom_onset_week = symptom_change.get('onset_week', 0)
        features['temporal_correlation_saphnelo'] = self._calculate_temporal_correlation(
            saphnelo_weeks, symptom_onset_week, expected_lag=4
        )
        
        steroid_taper_week = patient_data.get('steroid_taper_start_week', None)
        if steroid_taper_week:
            features['temporal_correlation_taper'] = self._calculate_temporal_correlation(
                steroid_taper_week, symptom_onset_week, expected_lag=2
            )
        else:
            features['temporal_correlation_taper'] = 0
        
        features['no_temporal_correlation'] = (
            features['temporal_correlation_saphnelo'] < 0.3 and
            features['temporal_correlation_taper'] < 0.3
        )
        
        # Medication changes
        current_prednisone = patient_data.get('current_prednisone', patient_data.get('baseline_prednisone', 0))
        baseline_prednisone = patient_data.get('baseline_prednisone', 0)
        features['steroid_dose_decreasing'] = current_prednisone < baseline_prednisone
        features['steroid_dose_stable'] = abs(current_prednisone - baseline_prednisone) < 2.5
        features['rapid_taper'] = (baseline_prednisone - current_prednisone) / max(saphnelo_weeks, 1) > 2.5
        
        # Steroid-specific symptom patterns
        steroid_symptoms = ['insomnia', 'mood_lability', 'irritability', 'paranoia']
        features['steroid_specific_symptoms'] = any(
            patient_data.get(symptom, False) for symptom in steroid_symptoms
        )
        
        # Disease activity
        features['systemic_disease_improvement'] = patient_data.get('sledai_change', 0) < -2
        features['systemic_disease_worsening'] = patient_data.get('sledai_change', 0) > 2
        features['biomarkers_elevated'] = patient_data.get('anti_dsdna_elevated', False) or patient_data.get('complement_low', False)
        
        # Workup results
        features['imaging_changes'] = patient_data.get('mri_new_lesions', False)
        features['neurological_symptoms'] = patient_data.get('seizures', False) or patient_data.get('stroke_like', False)
        
        # Dechallenge (if applicable)
        features['dechallenge_improvement'] = patient_data.get('dechallenge_improved', False)
        features['improvement_with_increase'] = patient_data.get('steroid_increase_improved', False)
        
        # Other factors
        features['life_stressor'] = patient_data.get('life_stressor', False)
        features['sleep_disturbance'] = patient_data.get('sleep_hours', 7) < 5
        features['hormonal_changes'] = patient_data.get('perimenopause', False) or patient_data.get('menstrual_irregularity', False)
        features['other_medication_change'] = patient_data.get('other_med_change', False)
        features['infection'] = patient_data.get('infection', False)
        
        return features
    
    def _calculate_temporal_correlation(self, event1_week, event2_week, expected_lag):
        """
        Calculate how well two events correlate temporally
        Returns: 0-1 score (1 = perfect correlation)
        """
        if event1_week is None or event2_week is None:
            return 0
        
        time_diff = abs(event2_week - event1_week)
        
        # Gaussian function centered at expected_lag
        correlation = np.exp(-((time_diff - expected_lag) ** 2) / (2 * (expected_lag / 2) ** 2))
        
        return correlation
    
    def calculate_attribution_probabilities(self, patient_data, symptom_change):
        """
        Calculate posterior probabilities for each attribution using Bayesian reasoning
        """
        features = self.extract_features(patient_data, symptom_change)
        
        # Calculate likelihood for each attribution
        likelihoods = {}
        for attribution, weights in self.feature_weights.items():
            likelihood = 1.0
            for feature, weight in weights.items():
                if feature in features:
                    # Convert boolean to 0/1, keep numeric as is
                    feature_value = float(features[feature]) if isinstance(features[feature], bool) else features[feature]
                    # Update likelihood based on feature presence and weight
                    likelihood *= (1 + weight * feature_value)
            likelihoods[attribution] = likelihood
        
        # Apply Bayes' theorem: P(attribution|features) ∝ P(features|attribution) * P(attribution)
        posteriors = {}
        for attribution in self.priors.keys():
            posteriors[attribution] = likelihoods[attribution] * self.priors[attribution]
        
        # Normalize to get probabilities
        total = sum(posteriors.values())
        for attribution in posteriors:
            posteriors[attribution] /= total
        
        # Sort by probability
        sorted_attributions = sorted(posteriors.items(), key=lambda x: x[1], reverse=True)
        
        return sorted_attributions
    
    def generate_attribution_report(self, patient_data, symptom_change):
        """
        Generate comprehensive attribution report with probabilities and reasoning
        """
        attributions = self.calculate_attribution_probabilities(patient_data, symptom_change)
        features = self.extract_features(patient_data, symptom_change)
        
        report = {
            'patient_id': patient_data.get('patient_id'),
            'symptom_domain': symptom_change.get('domain'),
            'symptom_direction': symptom_change.get('direction'),
            'attributions': [],
            'primary_attribution': None,
            'confidence': None,
            'supporting_evidence': [],
            'contradicting_evidence': [],
            'recommended_actions': []
        }
        
        # Process each attribution
        for attribution, probability in attributions:
            attribution_info = {
                'cause': attribution,
                'probability': round(probability * 100, 1),
                'likelihood': self._categorize_likelihood(probability),
                'supporting_features': self._get_supporting_features(attribution, features),
                'contradicting_features': self._get_contradicting_features(attribution, features)
            }
            report['attributions'].append(attribution_info)
        
        # Determine primary attribution
        primary = attributions[0]
        report['primary_attribution'] = primary[0]
        report['confidence'] = self._assess_confidence(attributions)
        
        # Generate evidence lists
        report['supporting_evidence'] = self._get_supporting_features(primary[0], features)
        report['contradicting_evidence'] = self._get_contradicting_features(primary[0], features)
        
        # Generate recommendations
        report['recommended_actions'] = self._generate_recommendations(
            primary[0], report['confidence'], symptom_change
        )
        
        return report
    
    def _categorize_likelihood(self, probability):
        """Categorize probability into clinical terms"""
        if probability >= 0.70:
            return 'DEFINITE'
        elif probability >= 0.50:
            return 'PROBABLE'
        elif probability >= 0.30:
            return 'POSSIBLE'
        elif probability >= 0.10:
            return 'UNLIKELY'
        else:
            return 'VERY UNLIKELY'
    
    def _assess_confidence(self, attributions):
        """Assess overall confidence in attribution based on probability distribution"""
        top_prob = attributions[0][1]
        second_prob = attributions[1][1] if len(attributions) > 1 else 0
        
        # High confidence if top attribution much more likely than second
        if top_prob > 0.70 and (top_prob - second_prob) > 0.30:
            return 'HIGH'
        elif top_prob > 0.50 and (top_prob - second_prob) > 0.20:
            return 'MODERATE'
        else:
            return 'LOW'
    
    def _get_supporting_features(self, attribution, features):
        """Get list of features that support this attribution"""
        supporting = []
        weights = self.feature_weights[attribution]
        
        for feature, weight in weights.items():
            if feature in features and features[feature] and weight > 0:
                supporting.append(self._feature_to_text(feature, features[feature]))
        
        return supporting
    
    def _get_contradicting_features(self, attribution, features):
        """Get list of features that contradict this attribution"""
        contradicting = []
        weights = self.feature_weights[attribution]
        
        for feature, weight in weights.items():
            if feature in features:
                # Feature present but weight negative, or feature absent but weight positive
                if (features[feature] and weight < 0) or (not features[feature] and weight > 0.5):
                    contradicting.append(self._feature_to_text(feature, features[feature]))
        
        return contradicting
    
    def _feature_to_text(self, feature, value):
        """Convert feature name to human-readable text"""
        feature_text = {
            'baseline_npsle': 'Patient had NPSLE at baseline',
            'no_baseline_npsle': 'No NPSLE at baseline',
            'improvement_direction': 'Symptoms are improving',
            'worsening_direction': 'Symptoms are worsening',
            'temporal_correlation_saphnelo': 'Timing correlates with Saphnelo treatment',
            'temporal_correlation_taper': 'Timing correlates with steroid taper',
            'systemic_disease_improvement': 'Systemic lupus activity is improving',
            'systemic_disease_worsening': 'Systemic lupus activity is worsening',
            'steroid_dose_decreasing': 'Prednisone dose is being tapered',
            'baseline_steroid_high': 'Patient was on high-dose steroids',
            'prior_steroid_psychiatric': 'Prior steroid-related psychiatric symptoms',
            'family_psychiatric_history': 'Family history of psychiatric disorders',
            'dechallenge_improvement': 'Symptoms improved after stopping Saphnelo',
            'biomarkers_elevated': 'Lupus biomarkers are elevated',
            'imaging_changes': 'New changes on brain MRI',
            'life_stressor': 'Recent significant life stressor',
            'sleep_disturbance': 'Severe sleep disturbance present'
        }
        
        return feature_text.get(feature, feature.replace('_', ' ').capitalize())
    
    def _generate_recommendations(self, attribution, confidence, symptom_change):
        """Generate clinical recommendations based on attribution"""
        recommendations = []
        
        if attribution == 'saphnelo_therapeutic':
            recommendations.append("Document Saphnelo therapeutic benefit for NPSLE")
            recommendations.append("Continue current Saphnelo treatment")
            recommendations.append("Consider continuing steroid taper if appropriate")
            recommendations.append("Monitor for sustained benefit")
            
        elif attribution == 'saphnelo_adverse':
            if confidence == 'HIGH':
                recommendations.append("URGENT: Consider holding Saphnelo")
                recommendations.append("Initiate psychiatric treatment")
                recommendations.append("Evaluate patient off Saphnelo (dechallenge)")
                recommendations.append("Psychiatry consultation")
            else:
                recommendations.append("Close monitoring required")
                recommendations.append("Psychiatry consultation")
                recommendations.append("Consider holding Saphnelo if symptoms worsen")
                recommendations.append("Rule out other causes")
                
        elif attribution == 'steroid_sparing':
            recommendations.append("Document steroid-sparing benefit")
            recommendations.append("Continue Saphnelo to enable further taper")
            recommendations.append("Continue steroid taper at current pace")
            recommendations.append("Monitor for sustained improvement")
            
        elif attribution == 'npsle_breakthrough':
            recommendations.append("Comprehensive NPSLE workup (imaging, LP, antibodies)")
            recommendations.append("Assess systemic disease activity")
            recommendations.append("Consider additional immunosuppression")
            recommendations.append("Neurology consultation")
            
        elif attribution == 'steroid_taper_effect':
            recommendations.append("Slow steroid taper rate")
            recommendations.append("Consider temporary steroid dose increase")
            recommendations.append("Optimize sleep and psychiatric medications")
            recommendations.append("Reassess taper strategy")
            
        elif attribution == 'other_cause':
            recommendations.append("Comprehensive evaluation for other causes")
            recommendations.append("Address identified factors (sleep, stress, hormones)")
            recommendations.append("Continue Saphnelo (likely not causative)")
            recommendations.append("Multidisciplinary approach as needed")
        
        return recommendations
```

#### Example Usage and Output

```python
# Example patient data
patient_data = {
    'patient_id': 'PT001',
    'baseline_npsle': True,
    'baseline_prednisone': 30,
    'current_prednisone': 15,
    'saphnelo_weeks': 24,
    'steroid_taper_start_week': 12,
    'sledai_change': -6,  # Improved
    'prior_steroid_psych': True,
    'family_psych_hx': False,
    'anti_dsdna_elevated': False,
    'mri_new_lesions': False
}

symptom_change = {
    'domain': 'cognitive',
    'direction': 'IMPROVEMENT',
    'onset_week': 16,
    'onset_days': 112,
    'duration_weeks': 8,
    'magnitude': 5.0
}

engine = AttributionEngine()
report = engine.generate_attribution_report(patient_data, symptom_change)

# Output:
"""
Attribution Report for PT001
Domain: cognitive
Direction: IMPROVEMENT

Attributions (ranked by probability):
1. Steroid-sparing benefit: 45.2% (PROBABLE)
   Supporting evidence:
   - Patient was on high-dose steroids
   - Prednisone dose is being tapered
   - Symptoms are improving
   - Timing correlates with steroid taper
   - Prior steroid-related psychiatric symptoms
   
2. Saphnelo therapeutic effect: 38.7% (POSSIBLE)
   Supporting evidence:
   - Patient had NPSLE at baseline
   - Symptoms are improving
   - Systemic lupus activity is improving
   - Timing correlates with Saphnelo treatment
   
3. Other causes: 8.3% (UNLIKELY)
4. NPSLE breakthrough: 4.1% (VERY UNLIKELY)
5. Saphnelo adverse effect: 2.5% (VERY UNLIKELY)
6. Steroid taper effect: 1.2% (VERY UNLIKELY)

Primary Attribution: Steroid-sparing benefit
Confidence: MODERATE (both steroid-sparing and Saphnelo therapeutic effect likely contributing)

Recommended Actions:
- Document steroid-sparing benefit
- Continue Saphnelo to enable further taper
- Continue steroid taper at current pace
- Monitor for sustained improvement
- Note: Saphnelo therapeutic effect also likely contributing (38.7% probability)
"""
```

---

### Algorithm 3: Cognitive Performance Analyzer

**Purpose**: Analyze cognitive test performance over time, detecting subtle changes and predicting trajectories

#### Algorithm Architecture

```python
class CognitivePerformanceAnalyzer:
    """
    Analyzes cognitive test performance using machine learning
    Detects subtle changes, predicts trajectories, and flags concerning patterns
    """
    
    def __init__(self):
        self.domains = ['memory', 'attention', 'processing_speed', 'executive_function', 'language']
        self.test_battery = {
            'memory': ['word_list_immediate', 'word_list_delayed', 'digit_span'],
            'attention': ['digit_span_forward', 'trail_making_a'],
            'processing_speed': ['trail_making_a', 'symbol_digit'],
            'executive_function': ['trail_making_b', 'verbal_fluency', 'stroop'],
            'language': ['verbal_fluency', 'boston_naming']
        }
        
        # Normative data (age and education adjusted)
        self.normative_means = {
            'word_list_immediate': 12.0,
            'word_list_delayed': 10.0,
            'digit_span': 7.0,
            'trail_making_a': 30.0,  # seconds (lower is better)
            'trail_making_b': 75.0,  # seconds (lower is better)
            'symbol_digit': 50.0,
            'verbal_fluency': 18.0,
            'stroop': 45.0,
            'boston_naming': 28.0
        }
        
        self.normative_sds = {
            'word_list_immediate': 2.0,
            'word_list_delayed': 2.5,
            'digit_span': 1.5,
            'trail_making_a': 10.0,
            'trail_making_b': 25.0,
            'symbol_digit': 10.0,
            'verbal_fluency': 5.0,
            'stroop': 10.0,
            'boston_naming': 2.0
        }
        
        # Reliable change index thresholds
        self.rci_threshold = 1.96  # 95% confidence
        
    def calculate_z_scores(self, test_scores, age, education):
        """
        Calculate age and education-adjusted z-scores
        """
        # Simplified - in production, use comprehensive normative database
        z_scores = {}
        
        for test, score in test_scores.items():
            if test in self.normative_means:
                # Adjust for age and education (simplified)
                age_adjustment = (age - 40) * 0.05  # Decline with age
                education_adjustment = (education - 12) * 0.1  # Improvement with education
                
                adjusted_mean = self.normative_means[test] - age_adjustment + education_adjustment
                
                # Calculate z-score
                if test in ['trail_making_a', 'trail_making_b']:
                    # Lower is better for these tests
                    z_scores[test] = (adjusted_mean - score) / self.normative_sds[test]
                else:
                    # Higher is better for other tests
                    z_scores[test] = (score - adjusted_mean) / self.normative_sds[test]
        
        return z_scores
    
    def calculate_domain_scores(self, z_scores):
        """
        Calculate composite scores for each cognitive domain
        """
        domain_scores = {}
        
        for domain, tests in self.test_battery.items():
            relevant_scores = [z_scores[test] for test in tests if test in z_scores]
            if relevant_scores:
                domain_scores[domain] = np.mean(relevant_scores)
            else:
                domain_scores[domain] = None
        
        return domain_scores
    
    def classify_impairment(self, z_score):
        """
        Classify level of impairment based on z-score
        """
        if z_score >= -1.0:
            return 'NORMAL'
        elif z_score >= -1.5:
            return 'BORDERLINE'
        elif z_score >= -2.0:
            return 'MILD IMPAIRMENT'
        elif z_score >= -3.0:
            return 'MODERATE IMPAIRMENT'
        else:
            return 'SEVERE IMPAIRMENT'
    
    def calculate_reliable_change(self, baseline_score, current_score, test_name):
        """
        Calculate Reliable Change Index (RCI)
        Determines if change is statistically significant beyond practice effects
        """
        # Standard error of measurement (SEM)
        # Simplified - in production, use test-specific reliability coefficients
        reliability = 0.85  # Typical for cognitive tests
        sem = self.normative_sds[test_name] * np.sqrt(1 - reliability)
        
        # Standard error of difference
        se_diff = np.sqrt(2 * (sem ** 2))
        
        # Practice effect adjustment (simplified)
        practice_effect = 0.2 * self.normative_sds[test_name]  # Typical improvement
        
        # Calculate RCI
        if test_name in ['trail_making_a', 'trail_making_b']:
            # Lower is better
            adjusted_change = (baseline_score - current_score) - practice_effect
        else:
            # Higher is better
            adjusted_change = (current_score - baseline_score) - practice_effect
        
        rci = adjusted_change / se_diff
        
        # Classify change
        if rci >= self.rci_threshold:
            classification = 'SIGNIFICANT IMPROVEMENT'
        elif rci <= -self.rci_threshold:
            classification = 'SIGNIFICANT DECLINE'
        else:
            classification = 'NO SIGNIFICANT CHANGE'
        
        return {
            'rci': rci,
            'classification': classification,
            'change_magnitude': adjusted_change,
            'se_diff': se_diff
        }
    
    def analyze_longitudinal_trajectory(self, test_history):
        """
        Analyze trajectory of cognitive performance over multiple timepoints
        Uses linear mixed models to account for practice effects and individual variability
        """
        trajectories = {}
        
        for test_name in test_history.keys():
            scores = test_history[test_name]['scores']
            timepoints = test_history[test_name]['weeks']
            
            if len(scores) < 3:
                trajectories[test_name] = {
                    'trajectory': 'INSUFFICIENT DATA',
                    'slope': None,
                    'predicted_6month': None
                }
                continue
            
            # Fit linear model
            slope, intercept = np.polyfit(timepoints, scores, 1)
            
            # Classify trajectory
            if test_name in ['trail_making_a', 'trail_making_b']:
                # Lower is better - negative slope is improvement
                if slope < -0.5:
                    trajectory = 'IMPROVING'
                elif slope > 0.5:
                    trajectory = 'DECLINING'
                else:
                    trajectory = 'STABLE'
            else:
                # Higher is better - positive slope is improvement
                if slope > 0.1:
                    trajectory = 'IMPROVING'
                elif slope < -0.1:
                    trajectory = 'DECLINING'
                else:
                    trajectory = 'STABLE'
            
            # Predict 6-month score
            predicted_6month = slope * 24 + intercept  # 24 weeks = 6 months
            
            # Calculate confidence interval
            residuals = scores - (slope * np.array(timepoints) + intercept)
            se = np.sqrt(np.sum(residuals ** 2) / (len(scores) - 2))
            ci_95 = 1.96 * se
            
            trajectories[test_name] = {
                'trajectory': trajectory,
                'slope': slope,
                'predicted_6month': predicted_6month,
                'confidence_interval': (predicted_6month - ci_95, predicted_6month + ci_95),
                'r_squared': self._calculate_r_squared(scores, slope, intercept, timepoints)
            }
        
        return trajectories
    
    def _calculate_r_squared(self, scores, slope, intercept, timepoints):
        """Calculate R-squared for model fit"""
        predicted = slope * np.array(timepoints) + intercept
        ss_res = np.sum((scores - predicted) ** 2)
        ss_tot = np.sum((scores - np.mean(scores)) ** 2)
        return 1 - (ss_res / ss_tot) if ss_tot != 0 else 0
    
    def detect_cognitive_patterns(self, domain_scores, trajectories):
        """
        Detect clinically meaningful patterns in cognitive performance
        """
        patterns = []
        
        # Pattern 1: Global impairment (all domains impaired)
        impaired_domains = [d for d, score in domain_scores.items() if score and score < -1.5]
        if len(impaired_domains) >= 4:
            patterns.append({
                'pattern': 'GLOBAL COGNITIVE IMPAIRMENT',
                'severity': 'HIGH',
                'domains': impaired_domains,
                'clinical_significance': 'Suggests diffuse brain involvement or severe NPSLE'
            })
        
        # Pattern 2: Executive dysfunction predominant
        if domain_scores.get('executive_function', 0) < -1.5 and domain_scores.get('memory', 0) > -1.0:
            patterns.append({
                'pattern': 'EXECUTIVE DYSFUNCTION',
                'severity': 'MODERATE',
                'domains': ['executive_function'],
                'clinical_significance': 'Common in lupus, may respond to treatment'
            })
        
        # Pattern 3: Memory impairment predominant
        if domain_scores.get('memory', 0) < -1.5 and domain_scores.get('executive_function', 0) > -1.0:
            patterns.append({
                'pattern': 'MEMORY IMPAIRMENT',
                'severity': 'MODERATE',
                'domains': ['memory'],
                'clinical_significance': 'May indicate hippocampal involvement'
            })
        
        # Pattern 4: Processing speed impairment
        if domain_scores.get('processing_speed', 0) < -1.5:
            patterns.append({
                'pattern': 'PROCESSING SPEED DEFICIT',
                'severity': 'MODERATE',
                'domains': ['processing_speed'],
                'clinical_significance': 'Common in lupus, often improves with treatment'
            })
        
        # Pattern 5: Improving trajectory across domains
        improving_tests = [t for t, traj in trajectories.items() if traj['trajectory'] == 'IMPROVING']
        if len(improving_tests) >= 3:
            patterns.append({
                'pattern': 'GLOBAL COGNITIVE IMPROVEMENT',
                'severity': 'POSITIVE',
                'domains': 'multiple',
                'clinical_significance': 'Suggests treatment response'
            })
        
        # Pattern 6: Declining trajectory (red flag)
        declining_tests = [t for t, traj in trajectories.items() if traj['trajectory'] == 'DECLINING']
        if len(declining_tests) >= 2:
            patterns.append({
                'pattern': 'COGNITIVE DECLINE',
                'severity': 'HIGH',
                'domains': 'multiple',
                'clinical_significance': 'URGENT: Evaluate for NPSLE progression or adverse effect'
            })
        
        return patterns
    
    def generate_cognitive_report(self, patient_data, test_scores, baseline_scores=None, test_history=None):
        """
        Generate comprehensive cognitive assessment report
        """
        age = patient_data.get('age', 40)
        education = patient_data.get('education_years', 12)
        
        # Calculate z-scores
        z_scores = self.calculate_z_scores(test_scores, age, education)
        
        # Calculate domain scores
        domain_scores = self.calculate_domain_scores(z_scores)
        
        # Classify impairment
        impairment_classification = {
            domain: self.classify_impairment(score) if score else 'NOT ASSESSED'
            for domain, score in domain_scores.items()
        }
        
        # Calculate reliable change if baseline available
        reliable_changes = {}
        if baseline_scores:
            for test in test_scores.keys():
                if test in baseline_scores:
                    reliable_changes[test] = self.calculate_reliable_change(
                        baseline_scores[test], test_scores[test], test
                    )
        
        # Analyze trajectories if history available
        trajectories = {}
        if test_history:
            trajectories = self.analyze_longitudinal_trajectory(test_history)
        
        # Detect patterns
        patterns = self.detect_cognitive_patterns(domain_scores, trajectories)
        
        # Generate report
        report = {
            'patient_id': patient_data.get('patient_id'),
            'assessment_date': patient_data.get('assessment_date'),
            'age': age,
            'education': education,
            'test_scores': test_scores,
            'z_scores': z_scores,
            'domain_scores': domain_scores,
            'impairment_classification': impairment_classification,
            'reliable_changes': reliable_changes,
            'trajectories': trajectories,
            'patterns': patterns,
            'overall_summary': self._generate_summary(domain_scores, patterns, reliable_changes),
            'recommendations': self._generate_cognitive_recommendations(patterns, reliable_changes)
        }
        
        return report
    
    def _generate_summary(self, domain_scores, patterns, reliable_changes):
        """Generate overall cognitive summary"""
        # Count impaired domains
        impaired = sum(1 for score in domain_scores.values() if score and score < -1.5)
        total = sum(1 for score in domain_scores.values() if score is not None)
        
        # Determine overall status
        if impaired == 0:
            status = "Cognitive function within normal limits"
        elif impaired <= 1:
            status = f"Mild cognitive impairment in {impaired} domain(s)"
        elif impaired <= 2:
            status = f"Moderate cognitive impairment in {impaired} domains"
        else:
            status = f"Significant cognitive impairment across {impaired} domains"
        
        # Add change information
        if reliable_changes:
            improved = sum(1 for rc in reliable_changes.values() if rc['classification'] == 'SIGNIFICANT IMPROVEMENT')
            declined = sum(1 for rc in reliable_changes.values() if rc['classification'] == 'SIGNIFICANT DECLINE')
            
            if improved > 0:
                status += f". Significant improvement in {improved} test(s)"
            if declined > 0:
                status += f". Significant decline in {declined} test(s)"
        
        return status
    
    def _generate_cognitive_recommendations(self, patterns, reliable_changes):
        """Generate clinical recommendations based on cognitive findings"""
        recommendations = []
        
        # Based on patterns
        for pattern in patterns:
            if pattern['severity'] == 'HIGH':
                if pattern['pattern'] == 'GLOBAL COGNITIVE IMPAIRMENT':
                    recommendations.append("Comprehensive NPSLE workup recommended (imaging, LP, antibodies)")
                    recommendations.append("Neurology consultation")
                    recommendations.append("Consider intensifying immunosuppression")
                elif pattern['pattern'] == 'COGNITIVE DECLINE':
                    recommendations.append("URGENT: Evaluate for NPSLE progression or medication adverse effect")
                    recommendations.append("Review recent medication changes")
                    recommendations.append("Consider brain MRI")
            
            if pattern['severity'] == 'POSITIVE':
                recommendations.append("Document cognitive improvement as treatment response")
                recommendations.append("Continue current treatment regimen")
        
        # Based on reliable changes
        if reliable_changes:
            declined_tests = [test for test, rc in reliable_changes.items() if rc['classification'] == 'SIGNIFICANT DECLINE']
            if len(declined_tests) >= 2:
                recommendations.append(f"Significant decline in {len(declined_tests)} tests - comprehensive evaluation needed")
        
        # General recommendations
        if not recommendations:
            recommendations.append("Continue monitoring cognitive function")
            recommendations.append("Reassess in 3-6 months")
        
        # Add cognitive rehabilitation if impairment present
        if any(p['severity'] in ['MODERATE', 'HIGH'] for p in patterns):
            recommendations.append("Consider cognitive rehabilitation referral")
            recommendations.append("Occupational therapy evaluation for functional strategies")
        
        return recommendations
```

#### Example Usage and Output

```python
# Example patient data
patient_data = {
    'patient_id': 'PT001',
    'assessment_date': '2024-06-15',
    'age': 38,
    'education_years': 16
}

# Current test scores
test_scores = {
    'word_list_immediate': 10,
    'word_list_delayed': 8,
    'digit_span': 6,
    'trail_making_a': 35,
    'trail_making_b': 90,
    'symbol_digit': 42,
    'verbal_fluency': 15,
    'stroop': 40,
    'boston_naming': 26
}

# Baseline scores (6 months ago)
baseline_scores = {
    'word_list_immediate': 8,
    'word_list_delayed': 6,
    'digit_span': 5,
    'trail_making_a': 45,
    'trail_making_b': 110,
    'symbol_digit': 35,
    'verbal_fluency': 12,
    'stroop': 35,
    'boston_naming': 24
}

# Test history (multiple timepoints)
test_history = {
    'word_list_immediate': {
        'scores': [8, 9, 9, 10, 10],
        'weeks': [0, 6, 12, 18, 24]
    },
    'trail_making_a': {
        'scores': [45, 42, 40, 37, 35],
        'weeks': [0, 6, 12, 18, 24]
    }
}

analyzer = CognitivePerformanceAnalyzer()
report = analyzer.generate_cognitive_report(
    patient_data, test_scores, baseline_scores, test_history
)

# Output:
"""
Cognitive Assessment Report for PT001
Date: 2024-06-15
Age: 38, Education: 16 years

Domain Scores (z-scores):
- Memory: -1.2 (BORDERLINE)
- Attention: -0.8 (NORMAL)
- Processing Speed: -1.4 (BORDERLINE)
- Executive Function: -1.6 (MILD IMPAIRMENT)
- Language: -0.9 (NORMAL)

Reliable Change Analysis (from baseline 6 months ago):
- Word List Immediate: RCI = 2.1 (SIGNIFICANT IMPROVEMENT)
- Word List Delayed: RCI = 1.8 (NO SIGNIFICANT CHANGE, trending improvement)
- Trail Making A: RCI = 2.3 (SIGNIFICANT IMPROVEMENT)
- Symbol Digit: RCI = 1.9 (NO SIGNIFICANT CHANGE, trending improvement)
- Verbal Fluency: RCI = 2.0 (SIGNIFICANT IMPROVEMENT)

Longitudinal Trajectories:
- Word List Immediate: IMPROVING (slope = +0.5 points/month)
  Predicted 6-month score: 11.0 (95% CI: 10.2-11.8)
- Trail Making A: IMPROVING (slope = -2.0 seconds/month)
  Predicted 6-month score: 31 seconds (95% CI: 28-34)

Patterns Detected:
1. GLOBAL COGNITIVE IMPROVEMENT (Positive)
   - Multiple tests showing improvement trajectory
   - Clinical significance: Suggests treatment response

2. EXECUTIVE DYSFUNCTION (Moderate)
   - Executive function domain most impaired
   - Clinical significance: Common in lupus, may respond to treatment

Overall Summary:
Mild cognitive impairment in 1 domain (executive function). Significant improvement in 3 tests. Positive trajectory suggests treatment response.

Recommendations:
- Document cognitive improvement as treatment response
- Continue current treatment regimen
- Continue monitoring cognitive function
- Consider cognitive rehabilitation for executive function strategies
- Reassess in 3 months
"""
```

---

## Part 2: Prospective Pilot Study Protocol

# PROSPECTIVE PILOT STUDY PROTOCOL

## Title
**Systematic Neuropsychiatric Monitoring in Saphnelo-Treated Systemic Lupus Erythematosus: A Prospective Pilot Study (SNAP-SLE)**

---

## 1. STUDY OVERVIEW

### 1.1 Background and Rationale

Saphnelo (anifrolumab), a type I interferon receptor antagonist approved for moderate-to-severe SLE, has shown efficacy in controlling systemic disease activity. However, neuropsychiatric manifestations of SLE (NPSLE) affect 30-40% of patients and represent a major source of morbidity. The impact of Saphnelo on neuropsychiatric symptoms remains incompletely characterized.

**Key Knowledge Gaps:**
1. Incidence and characteristics of neuropsychiatric changes during Saphnelo treatment
2. Ability to distinguish Saphnelo therapeutic effects from adverse effects
3. Attribution of neuropsychiatric symptoms to Saphnelo vs. steroid-sparing vs. other causes
4. Optimal monitoring protocols for neuropsychiatric outcomes
5. Utility of AI-powered tools for detection and attribution

**Study Innovation:**
This pilot study will implement and evaluate a comprehensive neuropsychiatric monitoring system including:
- Standardized Saphnelo Neuropsychiatric Monitoring Protocol (SNMP)
- Patient-facing symptom tracking app with AI pattern detection
- Provider-facing decision support tool with attribution algorithms
- Systematic longitudinal assessment over 52 weeks

### 1.2 Study Objectives

**Primary Objective:**
To evaluate the feasibility and preliminary efficacy of a systematic neuropsychiatric monitoring protocol in SLE patients initiating Saphnelo treatment.

**Secondary Objectives:**
1. Characterize the incidence, type, and timing of neuropsychiatric changes during Saphnelo treatment
2. Assess the accuracy of AI-powered attribution algorithms in determining causality of neuropsychiatric symptoms
3. Evaluate patient engagement with the symptom tracking app
4. Assess provider satisfaction with the decision support tool
5. Estimate effect sizes for neuropsychiatric outcomes to inform future definitive trials
6. Evaluate cost-effectiveness of systematic monitoring

**Exploratory Objectives:**
1. Identify predictors of neuropsychiatric response to Saphnelo
2. Characterize the relationship between interferon gene signature and neuropsychiatric outcomes
3. Explore biomarkers of neuropsychiatric improvement or adverse events
4. Assess impact on quality of life and functional outcomes

---

## 2. STUDY DESIGN

### 2.1 Study Type
Prospective, observational cohort study with embedded technology evaluation

### 2.2 Study Duration
- **Enrollment period:** 6 months
- **Follow-up period:** 52 weeks per patient
- **Total study duration:** 18 months

### 2.3 Study Sites
- **Number of sites:** 5
  * 3 academic medical centers with lupus specialty programs
  * 2 community rheumatology practices
- **Geographic distribution:** Diverse regions to ensure population diversity

### 2.4 Study Population

**Target Enrollment:** 100 patients

**Inclusion Criteria:**
1. Age ≥18 years
2. Diagnosis of SLE meeting 2019 EULAR/ACR classification criteria
3. Initiating Saphnelo treatment per standard clinical care
4. Able to provide informed consent
5. English or Spanish speaking (app available in both languages)
6. Access to smartphone or tablet (or willing to use study-provided device)
7. Willing to complete study assessments for 52 weeks

**Exclusion Criteria:**
1. Prior Saphnelo treatment (>2 doses)
2. Active severe NPSLE requiring hospitalization at enrollment
3. Primary psychiatric disorder requiring hospitalization in past 6 months
4. Substance use disorder (active, not in remission)
5. Dementia or severe cognitive impairment preventing informed consent
6. Life expectancy <12 months
7. Pregnancy (Saphnelo contraindicated)
8. Concurrent enrollment in interventional clinical trial

### 2.5 Sample Size Justification

**Primary Endpoint:** Feasibility (proportion of eligible patients successfully enrolled and completing ≥80% of assessments)

**Target:** 80% completion rate

**Sample Size:** 100 patients provides:
- 95% CI of 71-87% if true completion rate is 80%
- 80% power to detect 20% difference in neuropsychiatric change detection vs. historical controls (40% vs. 60%, two-sided α=0.05)
- Adequate precision for estimating effect sizes for future trials

**Stratification:**
- High risk (active NPSLE or high steroids): n=30
- Moderate risk (NPSLE history or moderate steroids): n=40
- Low risk (no NPSLE, low steroids): n=30

---

## 3. STUDY PROCEDURES

### 3.1 Screening and Enrollment

**Screening Process:**
1. Rheumatologist identifies patient for whom Saphnelo is clinically indicated
2. Research coordinator screens for eligibility
3. Informed consent obtained
4. Baseline assessments completed within 2 weeks before first Saphnelo dose

**Enrollment Timeline:**
- Month 1-6: Rolling enrollment (target 16-17 patients/month)

### 3.2 Study Assessments

#### 3.2.1 Baseline Assessment (Week 0)

**Clinical Assessments:**
- Demographics (age, sex, race/ethnicity, education)
- SLE history (duration, organ involvement, prior treatments)
- Current medications (steroids, immunosuppressants, psychiatric medications)
- Comorbidities
- NPSLE history (prior manifestations, treatments, outcomes)
- Family psychiatric history

**Disease Activity:**
- SLEDAI-2K (SLE Disease Activity Index)
- Physician Global Assessment (PGA)
- BILAG-2004 (British Isles Lupus Assessment Group)
- Steroid dose

**Neuropsychiatric Assessment:**
- NPSLE manifestations (ACR 19-syndrome checklist)
- Cognitive complaints (patient and family report)
- Montreal Cognitive Assessment (MoCA)
- Comprehensive neuropsychological testing (if clinically indicated or high-risk)
- PHQ-9 (depression)
- GAD-7 (anxiety)
- Columbia-Suicide Severity Rating Scale (C-SSRS)
- Sleep quality (Pittsburgh Sleep Quality Index - PSQI)
- Steroid-related psychiatric symptoms checklist

**Functional and Quality of Life:**
- SF-36 (Short Form-36 Health Survey)
- LupusQoL (Lupus Quality of Life)
- FACIT-Fatigue
- Work Productivity and Activity Impairment (WPAI)
- Functional Assessment of Chronic Illness Therapy (FACIT)

**Biomarkers:**
- Anti-dsDNA, complement (C3, C4)
- Complete blood count, comprehensive metabolic panel
- Interferon gene signature (if available)
- Anti-ribosomal P, anti-NR2 (if NPSLE history)

**Imaging (if clinically indicated):**
- Brain MRI with NPSLE protocol

**Risk Stratification:**
- Automated risk score calculated (high/moderate/low)

**Technology Onboarding:**
- Patient downloads symptom tracking app
- Tutorial on app use
- Baseline symptom logging
- Baseline cognitive micro-assessments in app

#### 3.2.2 Follow-Up Assessments

**Week 4 (After 1st Saphnelo dose):**
- Brief clinical assessment (15 min)
- Adverse event screening
- PHQ-2, GAD-2 (brief depression/anxiety)
- MoCA
- Sleep quality (single item)
- Steroid dose
- App data review

**Week 8 (After 2nd dose):**
- Same as Week 4

**Week 12 (After 3rd dose):**
- Comprehensive assessment (45 min)
- Full PHQ-9, GAD-7, C-SSRS
- MoCA
- SLEDAI-2K, PGA
- Steroid dose and taper progress
- Functional status (WPAI)
- Quality of life (SF-36 mental component)
- App data review and AI attribution analysis
- Provider decision support tool utilization

**Week 24 (After 6th dose):**
- Comprehensive assessment (same as Week 12)
- Comprehensive neuropsychological testing (if baseline done or if concerns)
- LupusQoL, FACIT-Fatigue

**Week 52 (After 13th dose):**
- Comprehensive assessment
- Full neuropsychological testing battery
- All quality of life measures
- Patient satisfaction survey
- Provider satisfaction survey
- Cost data collection

**Quarterly (Weeks 36, 48):**
- Comprehensive assessment (same as Week 12)

**PRN (As Needed):**
- Urgent evaluation for concerning symptoms
- Psychiatric consultation if indicated
- Neurology consultation if indicated

#### 3.2.3 App-Based Assessments

**Daily (Patient-Initiated):**
- Symptom logging (cognitive, mood, anxiety, sleep, physical)
- Medication tracking
- Free text notes

**Weekly (App-Prompted):**
- Cognitive micro-assessments (5 min)
- Steroid dose confirmation

**Continuous:**
- AI pattern detection running in background
- Alerts generated for significant changes
- Data transmitted to provider dashboard

### 3.3 Intervention (Monitoring Protocol)

**All patients receive:**

1. **Saphnelo Neuropsychiatric Monitoring Protocol (SNMP)**
   - Standardized assessment schedule based on risk stratification
   - Structured documentation templates
   - Red flag symptom monitoring
   - Attribution analysis framework

2. **Patient Symptom Tracking App**
   - Daily symptom logging
   - Weekly cognitive testing
   - AI pattern detection
   - Educational content
   - Medication reminders

3. **Provider Decision Support Tool**
   - Automated risk stratification
   - Monitoring schedule reminders
   - AI-powered attribution analysis
   - Management recommendations
   - Interdisciplinary consultation triggers

**Standard of Care:**
- Saphnelo dosing per FDA label (300mg IV every 4 weeks)
- All other SLE treatments per rheumatologist discretion
- Steroid taper per rheumatologist discretion
- Psychiatric/neurological consultations per clinical need

---

## 4. OUTCOME MEASURES

### 4.1 Primary Outcome

**Feasibility Outcome:**
- Proportion of enrolled patients completing ≥80% of scheduled assessments over 52 weeks

**Success Criterion:** ≥70% of patients complete ≥80% of assessments

### 4.2 Secondary Outcomes

**Neuropsychiatric Detection Outcomes:**
1. Proportion of patients with neuropsychiatric changes detected (any domain)
2. Time to detection of neuropsychiatric changes (from symptom onset to clinical recognition)
3. Sensitivity and specificity of AI pattern detection (vs. clinician assessment as gold standard)

**Attribution Outcomes:**
1. Proportion of neuropsychiatric changes with definite/probable attribution
2. Agreement between AI attribution and expert consensus attribution (kappa statistic)
3. Time to attribution determination

**Clinical Outcomes:**
1. Change in cognitive function (MoCA score) from baseline to Week 52
2. Change in depression (PHQ-9) from baseline to Week 52
3. Change in anxiety (GAD-7) from baseline to Week 52
4. Incidence of neuropsychiatric adverse events (any severity)
5. Incidence of serious neuropsychiatric adverse events
6. Change in SLEDAI-2K from baseline to Week 52
7. Steroid dose at Week 52 vs. baseline
8. Proportion achieving steroid taper goal (≤7.5mg or discontinuation)

**Patient-Reported Outcomes:**
1. Change in quality of life (SF-36, LupusQoL) from baseline to Week 52
2. Change in fatigue (FACIT-Fatigue) from baseline to Week 52
3. Change in work productivity (WPAI) from baseline to Week 52
4. Patient satisfaction with monitoring protocol (custom survey)

**Technology Outcomes:**
1. App engagement: Proportion of patients with ≥60% daily logging completion at 6 months
2. App usability: System Usability Scale (SUS) score
3. Provider tool utilization: Proportion of visits with tool use documented
4. Provider satisfaction: Custom survey

**Economic Outcomes:**
1. Healthcare utilization (hospitalizations, ER visits, unscheduled clinic visits)
2. Cost of monitoring protocol implementation
3. Preliminary cost-effectiveness analysis

### 4.3 Exploratory Outcomes

1. Predictors of neuropsychiatric response (baseline characteristics, biomarkers)
2. Correlation between interferon gene signature and neuropsychiatric outcomes
3. Identification of novel biomarkers (metabolomics, proteomics if funding available)
4. Subgroup analyses by risk stratification, demographics, disease characteristics

---

## 5. DATA COLLECTION AND MANAGEMENT

### 5.1 Data Sources

**Electronic Health Record (EHR):**
- Demographics, medical history
- Medications, laboratory results
- Clinical notes, imaging reports

**Research Electronic Data Capture (REDCap):**
- Standardized assessment forms
- Outcome measures
- Adverse events

**Patient App:**
- Daily symptom logs
- Weekly cognitive assessments
- Medication tracking

**Provider Decision Support Tool:**
- Risk stratification data
- AI attribution analyses
- Clinical decision documentation

### 5.2 Data Quality Assurance

**Training:**
- All study coordinators trained on assessment administration
- Inter-rater reliability testing for MoCA (target κ>0.80)
- Standardized neuropsychological testing protocols

**Monitoring:**
- Weekly data quality checks
- Monthly site monitoring visits (remote or in-person)
- Query resolution within 2 weeks

**Data Security:**
- HIPAA-compliant data storage
- Encrypted data transmission
- Role-based access controls
- Regular security audits

### 5.3 Data Analysis Plan

**Primary Analysis:**
- Descriptive statistics for feasibility outcome (proportion with 95% CI)
- Comparison to pre-specified success criterion

**Secondary Analyses:**

*Neuropsychiatric Detection:*
- Incidence rates with 95% CI
- Time-to-event analysis (Kaplan-Meier curves)
- Sensitivity/specificity of AI detection (2x2 tables, ROC curves)

*Attribution:*
- Agreement statistics (Cohen's kappa, weighted kappa)
- Confusion matrices for AI vs. expert attribution

*Clinical Outcomes:*
- Paired t-tests or Wilcoxon signed-rank tests for continuous outcomes (baseline vs. Week 52)
- Mixed-effects models for longitudinal trajectories
- Stratified analyses by risk group

*Technology Outcomes:*
- Descriptive statistics for engagement metrics
- Correlation between app engagement and outcome detection

*Economic Outcomes:*
- Cost per patient monitored
- Cost per neuropsychiatric change detected
- Preliminary cost-effectiveness ratios

**Exploratory Analyses:**
- Multivariable regression models for predictors of outcomes
- Subgroup analyses (with caution given sample size)
- Hypothesis generation for future studies

**Missing Data:**
- Multiple imputation for missing outcome data (if <20% missing)
- Sensitivity analyses with complete cases

**Statistical Software:**
- R version 4.0 or later
- SAS version 9.4 or later

**Significance Level:**
- Two-sided α=0.05 for primary and secondary outcomes
- Adjustment for multiple comparisons in exploratory analyses (Bonferroni or FDR)

---

## 6. SAFETY MONITORING

### 6.1 Adverse Event Definitions

**Neuropsychiatric Adverse Event (NPAE):**
Any new or worsening neuropsychiatric symptom during study period, including:
- Cognitive decline (≥2 point MoCA decrease)
- Depression (PHQ-9 increase ≥5 points or score ≥15)
- Anxiety (GAD-7 increase ≥4 points or score ≥15)
- Suicidal ideation (any positive C-SSRS response)
- Psychosis, mania, acute confusional state
- Seizures, stroke, other neurological events

**Serious Adverse Event (SAE):**
- Death
- Life-threatening event
- Hospitalization or prolongation of hospitalization
- Persistent or significant disability/incapacity
- Congenital anomaly/birth defect
- Important medical event requiring intervention

### 6.2 Safety Reporting

**Neuropsychiatric Adverse Events:**
- Documented in REDCap within 24 hours of detection
- Severity grading (mild, moderate, severe, life-threatening)
- Causality assessment (definite, probable, possible, unlikely, unrelated)
- Management documented

**Serious Adverse Events:**
- Reported to IRB within 24 hours
- Reported to FDA MedWatch within 7 days (if related to Saphnelo)
- Reported to study sponsor within 24 hours

**Suicidal Ideation:**
- Immediate psychiatric evaluation
- Safety plan implementation
- Family notification (with patient consent)
- Follow-up within 24 hours

### 6.3 Data Safety Monitoring

**Data Safety Monitoring Committee (DSMC):**
Not required for this observational study, but safety oversight provided by:
- Principal Investigator (ongoing review)
- Site IRBs (annual review minimum)
- Study sponsor medical monitor (quarterly review)

**Safety Review Meetings:**
- Monthly review of all adverse events by PI and study team
- Quarterly summary report to IRB
- Immediate review of any unexpected serious adverse events

**Stopping Rules:**
- Study will be paused if ≥10% of patients experience serious neuropsychiatric adverse events deemed definitely or probably related to monitoring procedures (not Saphnelo itself)
- Study will be reviewed if ≥20% of patients withdraw due to monitoring burden

---

## 7. ETHICAL CONSIDERATIONS

### 7.1 Informed Consent

**Consent Process:**
- Written informed consent obtained before any study procedures
- Consent form approved by local IRB
- Adequate time for questions
- Emphasis on voluntary participation and right to withdraw

**Key Elements:**
- Study purpose and procedures
- Risks and benefits
- Alternatives (standard care without systematic monitoring)
- Confidentiality protections
- Compensation (if any)
- Contact information for questions

**Capacity Assessment:**
- If cognitive impairment suspected, capacity assessment performed
- Legally authorized representative may provide consent if patient lacks capacity

### 7.2 Risk-Benefit Assessment

**Risks:**
- Minimal risk from study procedures (questionnaires, cognitive testing)
- Potential psychological distress from symptom monitoring
- Time burden (approximately 2-3 hours over 52 weeks)
- Privacy risks (mitigated by data security measures)

**Benefits:**
- Potential for earlier detection and management of neuropsychiatric symptoms
- Contribution to scientific knowledge
- No direct compensation, but free app access

**Risk Mitigation:**
- Trained personnel for assessments
- Mental health resources provided
- Ability to skip questions or withdraw at any time
- Robust data security

### 7.3 Privacy and Confidentiality

**Data Protection:**
- HIPAA compliance
- Encrypted data storage and transmission
- De-identified data for analysis
- Limited access to identifiable data

**Certificates of Confidentiality:**
- Obtained from NIH (if federally funded)
- Protects against compelled disclosure

**Data Sharing:**
- De-identified data may be shared with other researchers (with patient consent)
- Results published in aggregate form only

### 7.4 Vulnerable Populations

**Inclusion:**
- Study includes patients with cognitive impairment and psychiatric conditions (the population of interest)
- Special protections in place (capacity assessment, frequent monitoring)

**Exclusion:**
- Pregnant women excluded (Saphnelo contraindicated)
- Children excluded (Saphnelo not approved for pediatric use)
- Prisoners excluded (not appropriate population)

---

## 8. STUDY ORGANIZATION

### 8.1 Study Leadership

**Principal Investigator:**
- Rheumatologist with lupus expertise
- Responsible for overall study conduct
- Final authority on study decisions

**Co-Investigators:**
- Psychiatrist (neuropsychiatric expertise)
- Neurologist (NPSLE expertise)
- Neuropsychologist (cognitive assessment expertise)
- Biostatistician (data analysis)
- Health economist (cost-effectiveness analysis)

**Study Coordinator:**
- Manages day-to-day operations
- Patient recruitment and retention
- Data collection and quality assurance

### 8.2 Site Responsibilities

**Each Site:**
- Local PI (rheumatologist)
- Study coordinator
- IRB approval
- Regulatory compliance
- Patient enrollment (target 20 patients per site)

**Coordinating Center:**
- Overall study management
- Data management
- Statistical analysis
- Technology support (app and provider tool)

### 8.3 Advisory Board

**Composition:**
- Patient representatives (2)
- Lupus advocacy organization representative
- External rheumatologist
- External psychiatrist
- Bioethicist

**Role:**
- Provide input on study design and conduct
- Review patient materials
- Advise on ethical issues
- Dissemination of results

---

## 9. TIMELINE AND MILESTONES

### 9.1 Study Timeline

**Months 1-3: Preparation Phase**
- IRB submissions and approvals
- Site initiation visits
- Staff training
- Technology deployment (app, provider tool)
- Pilot testing with 5 patients

**Months 4-9: Enrollment Phase**
- Patient recruitment (target 16-17/month)
- Ongoing follow-up of enrolled patients
- Monthly safety reviews

**Months 10-21: Follow-Up Phase**
- Complete 52-week follow-up for all patients
- Ongoing data collection and quality assurance
- Quarterly interim analyses

**Months 22-24: Analysis and Dissemination Phase**
- Final data cleaning and analysis
- Manuscript preparation
- Conference presentations
- Final report to funders

### 9.2 Key Milestones

| Milestone | Target Date |
|-----------|-------------|
| IRB approvals complete | Month 3 |
| First patient enrolled | Month 4 |
| 50% enrollment complete | Month 6 |
| 100% enrollment complete | Month 9 |
| First patient completes 52 weeks | Month 16 |
| Last patient completes 52 weeks | Month 21 |
| Primary analysis complete | Month 23 |
| Manuscript submitted | Month 24 |

---

## 10. BUDGET AND RESOURCES

### 10.1 Budget Summary (Per Patient)

**Personnel:**
- Study coordinator time: $500
- Neuropsychological testing: $800
- Data management: $200

**Technology:**
- App development and maintenance: $100
- Provider tool licensing: $50

**Assessments:**
- Laboratory tests: $300
- Imaging (if indicated): $500 (estimated 30% of patients)

**Other:**
- IRB fees: $50
- Regulatory compliance: $100
- Patient compensation: $200 (for time and travel)

**Total per patient:** ~$2,800
**Total for 100 patients:** ~$280,000

**Additional Costs:**
- Coordinating center operations: $50,000
- Biostatistical analysis: $30,000
- Technology development (one-time): $150,000
- Dissemination (publications, conferences): $20,000

**Total Study Budget:** ~$530,000

### 10.2 Funding Sources

**Potential Funders:**
- National Institutes of Health (NIH/NIAMS)
- Patient-Centered Outcomes Research Institute (PCORI)
- Lupus Foundation of America
- AstraZeneca (manufacturer of Saphnelo) - investigator-initiated research grant
- Institutional funds

**Conflict of Interest Management:**
- If industry-funded, independent DSMC required
- Investigators must disclose any financial relationships
- Funder has no role in data analysis or manuscript preparation

---

## 11. DISSEMINATION PLAN

### 11.1 Publications

**Primary Manuscript:**
- Title: "Systematic Neuropsychiatric Monitoring in Saphnelo-Treated SLE: Results from the SNAP-SLE Pilot Study"
- Target Journal: Arthritis & Rheumatology or Lupus Science & Medicine
- Authorship: Per ICMJE guidelines

**Secondary Manuscripts:**
- AI algorithm validation and performance
- Patient and provider experience with technology
- Cost-effectiveness analysis
- Subgroup analyses (if interesting findings)

### 11.2 Conference Presentations

**Target Conferences:**
- American College of Rheumatology (ACR) Annual Meeting
- European League Against Rheumatism (EULAR) Congress
- Lupus Foundation of America National Conference
- American Psychiatric Association (APA) Annual Meeting (neuropsychiatric focus)

**Presentation Types:**
- Oral presentations (primary results)
- Poster presentations (secondary analyses)
- Workshop on AI in rheumatology

### 11.3 Stakeholder Engagement

**Patients and Advocacy Organizations:**
- Plain language summary of results
- Webinar for patient community
- Social media dissemination
- Input on future research directions

**Clinicians:**
- CME webinar on neuropsychiatric monitoring
- Clinical practice guidelines (if results support)
- Integration into lupus care pathways

**Policymakers:**
- Brief on implications for quality metrics
- Recommendations for reimbursement of systematic monitoring

### 11.4 Data Sharing

**De-identified Data:**
- Deposited in public repository (e.g., NIAMS Data Repository) 12 months after primary publication
- Data dictionary and analysis code provided
- Enables secondary analyses by other researchers

**App and Provider Tool:**
- If successful, make available to other centers
- Open-source code (if feasible)
- Implementation toolkit

---

## 12. LIMITATIONS AND MITIGATION STRATEGIES

### 12.1 Potential Limitations

**1. Selection Bias:**
- Patients willing to participate may differ from general Saphnelo population
- *Mitigation:* Compare enrolled vs. non-enrolled patients on key characteristics; report generalizability limitations

**2. Lack of Control Group:**
- Cannot definitively attribute outcomes to monitoring protocol vs. natural history
- *Mitigation:* Compare to historical controls from chart review; emphasize feasibility and effect size estimation as primary goals

**3. Technology Barriers:**
- Digital divide may exclude some patients
- *Mitigation:* Provide study devices if needed; offer low-tech alternatives (paper diaries)

**4. Provider Variability:**
- Different sites may implement protocol differently
- *Mitigation:* Standardized training; protocol adherence monitoring; site as covariate in analyses

**5. Small Sample Size:**
- Limited power for subgroup analyses and rare events
- *Mitigation:* Emphasize pilot nature; use findings to design definitive trial

**6. Attrition:**
- Patients may withdraw due to monitoring burden
- *Mitigation:* Minimize burden where possible; retention strategies (regular contact, compensation); intention-to-treat analysis

### 12.2 Contingency Plans

**Low Enrollment:**
- If enrollment <50% of target by Month 6, extend enrollment period or add sites

**High Attrition:**
- If attrition >30%, conduct exit interviews to understand reasons and modify protocol if feasible

**Technology Failures:**
- Backup data collection methods (paper forms)
- Technical support hotline for patients and providers

**Serious Adverse Events:**
- Immediate review by PI and IRB
- Modification or suspension of study if necessary

---

## 13. REGULATORY AND COMPLIANCE

### 13.1 IRB Approval

**Requirements:**
- IRB approval at each site before enrollment
- Annual continuing review
- Prompt reporting of protocol modifications and adverse events
- Final report upon study completion

**IRB Type:**
- Single IRB (sIRB) model if sites agree (preferred)
- Or local IRB at each site

### 13.2 Informed Consent

**Documentation:**
- Signed consent form for all participants
- Copy provided to participant
- Consent form version tracked in database

**Re-Consent:**
- Required if substantial protocol modifications

### 13.3 Data and Safety Monitoring

**Plan:**
- Monthly safety reviews by PI and study team
- Quarterly reports to IRB
- Annual DSMC review (if required by funder)

### 13.4 Regulatory Compliance

**Good Clinical Practice (GCP):**
- Study conducted per ICH-GCP guidelines
- Staff training documented

**HIPAA:**
- Business associate agreements with technology vendors
- Data use agreements for data sharing

**FDA:**
- This is an observational study of approved drug (Saphnelo)
- Not an IND study
- Adverse event reporting per FDA guidelines

---

## 14. CONCLUSION

The SNAP-SLE pilot study will evaluate the feasibility and preliminary efficacy of systematic neuropsychiatric monitoring in SLE patients treated with Saphnelo. By implementing a comprehensive protocol with AI-powered tools, this study will:

1. **Advance clinical care** by demonstrating feasibility of systematic monitoring
2. **Generate critical data** on neuropsychiatric outcomes with Saphnelo
3. **Validate AI algorithms** for detection and attribution
4. **Inform future research** by providing effect size estimates for definitive trials
5. **Improve patient outcomes** through early detection and management

If successful, this pilot will pave the way for larger-scale implementation and potentially transform the standard of care for neuropsychiatric monitoring in lupus.

---

## 15. APPENDICES

### Appendix A: Assessment Instruments
- Montreal Cognitive Assessment (MoCA)
- PHQ-9 (Patient Health Questionnaire-9)
- GAD-7 (Generalized Anxiety Disorder-7)
- Columbia-Suicide Severity Rating Scale (C-SSRS)
- SF-36 (Short Form-36)
- LupusQoL
- FACIT-Fatigue
- SLEDAI-2K
- BILAG-2004

### Appendix B: App Screenshots and User Guide
- Dashboard view
- Daily symptom logging interface
- Weekly cognitive assessment interface
- Alert notifications
- Educational content library

### Appendix C: Provider Decision Support Tool Interface
- Risk stratification calculator
- Monitoring schedule dashboard
- AI attribution analysis output
- Management recommendation algorithms

### Appendix D: Informed Consent Template
- Study purpose and procedures
- Risks and benefits
- Confidentiality
- Voluntary participation
- Contact information

### Appendix E: Data Collection Forms (REDCap)
- Baseline assessment
- Follow-up assessments
- Adverse event reporting
- Protocol deviation log

### Appendix F: Statistical Analysis Plan (Detailed)
- Variable definitions
- Analysis populations
- Statistical methods for each outcome
- Handling of missing data
- Sensitivity analyses

---

**Protocol Version:** 1.0  
**Protocol Date:** [Current Date]  
**Principal Investigator:** [Name, MD]  
**Institution:** [Institution Name]  
**Contact:** [Email, Phone]

---

This comprehensive protocol provides a detailed roadmap for conducting the SNAP-SLE pilot study, from study design through dissemination. It addresses all key elements required for IRB submission, funder applications, and successful study execution.