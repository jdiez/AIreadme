# Knowledge Graph Schema Design for Patient-Centric Competitive Intelligence

A well-designed knowledge graph is the backbone of an AI multi-agent system, enabling agents to discover non-obvious relationships, perform complex reasoning, and generate strategic insights. Here's a comprehensive schema design tailored for healthcare CI.

## Core Ontology Architecture

### Fundamental Design Principles

**1. Entity-Relationship Model**: Build around key healthcare entities with rich, bidirectional relationships that capture competitive dynamics

**2. Temporal Awareness**: All relationships should support time-stamping to track evolution of competitive landscape

**3. Confidence Scoring**: Attach provenance and confidence metrics to enable agents to reason about uncertainty

**4. Multi-Modal Integration**: Support connections between structured data (clinical trials, claims) and unstructured insights (literature, KOL feedback)

## Primary Entity Types

### 1. **Patient-Centric Entities**

**Patient Segment Node**

```
PatientSegment {
  id: string
  disease_area: string
  demographics: {
    age_range: string
    gender_distribution: object
    geographic_regions: array
  }
  clinical_characteristics: {
    disease_severity: string
    comorbidities: array
    biomarkers: array
    prior_treatments: array
  }
  psychographic_profile: {
    treatment_preferences: array
    adherence_factors: array
    quality_of_life_priorities: array
  }
  size_estimate: integer
  growth_rate: float
  last_updated: timestamp
}
```

**Unmet Need Node**

```
UnmetNeed {
  id: string
  need_type: enum [efficacy_gap, safety_concern, access_barrier, 
                   convenience_issue, cost_burden, quality_of_life]
  description: text
  severity_score: float (0-10)
  prevalence: float (% of patient segment)
  patient_segments: array<PatientSegment>
  current_solutions: array<Treatment>
  competitive_white_space_score: float (0-100)
  evidence_sources: array<DataSource>
  confidence_level: float (0-1)
  identified_date: timestamp
}
```

**Patient Journey Stage Node**

```
PatientJourneyStage {
  id: string
  stage_name: enum [awareness, diagnosis, treatment_selection, 
                    initiation, adherence, monitoring, switching, discontinuation]
  disease_area: string
  typical_duration: duration
  key_stakeholders: array [patient, caregiver, physician, payer]
  friction_points: array<FrictionPoint>
  decision_factors: array
  competitive_touchpoints: array<CompetitorActivity>
}
```

**Friction Point Node**

```
FrictionPoint {
  id: string
  journey_stage: PatientJourneyStage
  friction_type: enum [diagnostic_delay, access_barrier, cost_burden,
                       side_effects, complexity, information_gap]
  description: text
  impact_severity: float (0-10)
  affected_patient_segments: array<PatientSegment>
  root_causes: array
  competitor_solutions: array<CompetitorOffering>
  opportunity_score: float (0-100)
}
```

### 2. **Competitive Intelligence Entities**

**Competitor Node**

```
Competitor {
  id: string
  name: string
  organization_type: enum [pharma, biotech, medtech, digital_health]
  market_cap: float
  therapeutic_focus_areas: array
  geographic_presence: array
  strategic_positioning: text
  innovation_profile: {
    rd_spend: float
    pipeline_strength_score: float
    digital_maturity: string
  }
  partnerships: array<Partnership>
  recent_activities: array<CompetitorActivity>
}
```

**Treatment/Product Node**

```
Treatment {
  id: string
  name: string
  brand_name: string
  generic_name: string
  owner: Competitor
  treatment_type: enum [drug, device, digital_therapeutic, procedure]
  therapeutic_area: string
  mechanism_of_action: text
  administration_route: string
  dosing_regimen: text
  development_stage: enum [discovery, preclinical, phase1, phase2, 
                           phase3, regulatory_review, approved, marketed]
  regulatory_status: object {
    fda_status: string
    ema_status: string
    other_regions: object
  }
  market_performance: {
    launch_date: date
    current_revenue: float
    market_share: float
    growth_trajectory: string
    patent_expiry: date
  }
  patient_segments_targeted: array<PatientSegment>
  unmet_needs_addressed: array<UnmetNeed>
  competitive_advantages: array
  limitations: array
}
```

**Clinical Trial Node**

```
ClinicalTrial {
  id: string
  nct_id: string
  title: string
  sponsor: Competitor
  treatment_tested: Treatment
  phase: enum [phase1, phase2, phase3, phase4]
  status: enum [recruiting, active, completed, terminated, suspended]
  disease_area: string
  patient_population: {
    target_enrollment: integer
    actual_enrollment: integer
    inclusion_criteria: array
    exclusion_criteria: array
    demographics: object
  }
  study_design: {
    design_type: string
    blinding: string
    comparator: Treatment
    duration: duration
  }
  endpoints: {
    primary_endpoints: array
    secondary_endpoints: array
    patient_reported_outcomes: array
  }
  results: {
    efficacy_data: object
    safety_data: object
    patient_satisfaction: object
  }
  strategic_insights: {
    design_differentiation_score: float
    patient_centricity_score: float
    competitive_threat_level: float
  }
  start_date: date
  completion_date: date
}
```

**Competitor Activity Node**

```
CompetitorActivity {
  id: string
  competitor: Competitor
  activity_type: enum [pipeline_advancement, regulatory_filing, 
                       market_launch, partnership, acquisition, 
                       clinical_data_release, pricing_change, 
                       marketing_campaign, patent_filing]
  description: text
  related_treatment: Treatment
  impact_assessment: {
    strategic_significance: float (0-10)
    threat_level: float (0-10)
    opportunity_indicator: float (0-10)
    affected_market_segments: array<PatientSegment>
  }
  date: timestamp
  data_sources: array<DataSource>
}
```

### 3. **Market & Regulatory Entities**

**Regulatory Event Node**

```
RegulatoryEvent {
  id: string
  event_type: enum [approval, rejection, label_change, safety_alert,
                    guideline_update, reimbursement_decision]
  regulatory_body: enum [FDA, EMA, NICE, CMS, other]
  treatment_affected: Treatment
  decision_rationale: text
  patient_impact: {
    affected_segments: array<PatientSegment>
    access_implications: text
    safety_implications: text
  }
  competitive_implications: text
  date: date
  related_documents: array
}
```

**Market Opportunity Node**

```
MarketOpportunity {
  id: string
  opportunity_type: enum [white_space, unmet_need, market_shift, 
                          regulatory_change, competitor_weakness]
  description: text
  therapeutic_area: string
  patient_segments: array<PatientSegment>
  market_size_estimate: float
  growth_potential: float
  competitive_intensity: float (0-10)
  barriers_to_entry: array
  strategic_fit_score: float (0-100)
  time_to_market_estimate: duration
  confidence_level: float (0-1)
  identified_date: timestamp
  supporting_evidence: array<DataSource>
}
```

**Payer Landscape Node**

```
PayerLandscape {
  id: string
  region: string
  payer_type: enum [government, private_insurance, managed_care]
  coverage_policies: array
  reimbursement_criteria: {
    required_evidence_types: array
    patient_reported_outcomes_weight: float
    cost_effectiveness_threshold: float
  }
  recent_decisions: array<RegulatoryEvent>
  trends: {
    patient_centricity_emphasis: float (0-10)
    value_based_care_adoption: float (0-10)
  }
}
```

### 4. **Intelligence Source Entities**

**Data Source Node**

```
DataSource {
  id: string
  source_type: enum [clinical_trial_registry, regulatory_filing, 
                     scientific_literature, claims_database, 
                     patient_forum, kol_interview, conference_abstract,
                     news_article, patent_database, financial_report]
  source_name: string
  url: string
  publication_date: date
  credibility_score: float (0-1)
  data_quality_score: float (0-1)
  access_date: timestamp
  raw_content: text
  structured_extractions: object
}
```

**KOL (Key Opinion Leader) Node**

```
KOL {
  id: string
  name: string
  specialty: string
  institution: string
  geographic_region: string
  therapeutic_expertise: array
  influence_score: float (0-100)
  treatment_preferences: array
  recent_insights: array<KOLInsight>
  competitor_relationships: array<Competitor>
  publications: array<DataSource>
}
```

**KOL Insight Node**

```
KOLInsight {
  id: string
  kol: KOL
  insight_type: enum [unmet_need_identification, treatment_feedback,
                      patient_preference, market_trend, competitor_intel]
  content: text
  therapeutic_area: string
  related_treatments: array<Treatment>
  strategic_value: float (0-10)
  capture_date: timestamp
  source: enum [msl_interaction, conference, publication, interview]
}
```

## Critical Relationship Types

### Patient-Centric Relationships

**1. EXPERIENCES (Patient Segment → Unmet Need)**

```
EXPERIENCES {
  severity: float (0-10)
  prevalence: float (0-1)
  duration: duration
  impact_on_qol: float (0-10)
  temporal_pattern: string
  evidence_strength: float (0-1)
  last_validated: timestamp
}
```

**2. NAVIGATES (Patient Segment → Patient Journey Stage)**

```
NAVIGATES {
  typical_duration: duration
  success_rate: float (0-1)
  dropout_rate: float (0-1)
  satisfaction_score: float (0-10)
  key_decision_factors: array
}
```

**3. ENCOUNTERS (Patient Journey Stage → Friction Point)**

```
ENCOUNTERS {
  frequency: float (0-1)
  impact_severity: float (0-10)
  resolution_rate: float (0-1)
  competitive_vulnerability: float (0-10)
}
```

### Competitive Relationships

**4. ADDRESSES (Treatment → Unmet Need)**

```
ADDRESSES {
  effectiveness_score: float (0-10)
  evidence_quality: enum [preclinical, phase1, phase2, phase3, rwe]
  patient_satisfaction: float (0-10)
  coverage_completeness: float (0-1) // How fully it addresses the need
  competitive_advantage: float (-10 to 10) // vs. alternatives
  data_sources: array<DataSource>
  last_updated: timestamp
}
```

**5. COMPETES_WITH (Treatment → Treatment)**

```
COMPETES_WITH {
  competition_type: enum [direct, indirect, future_threat]
  market_overlap: float (0-1)
  patient_segments_contested: array<PatientSegment>
  head_to_head_comparisons: array {
    dimension: string
    winner: Treatment
    margin: float
    evidence_source: DataSource
  }
  switching_patterns: {
    from_to_rate: float
    to_from_rate: float
    reasons: array
  }
  competitive_intensity: float (0-10)
}
```

**6. DEVELOPS (Competitor → Treatment)**

```
DEVELOPS {
  development_stage: string
  investment_level: float
  strategic_priority: enum [core, growth, exploratory]
  partnership_model: string
  timeline_estimate: duration
  success_probability: float (0-1)
}
```

**7. TESTS (Clinical Trial → Treatment)**

```
TESTS {
  trial_phase: string
  enrollment_status: string
  interim_results: object
  competitive_differentiation_factors: array
  patient_centricity_score: float (0-10)
  strategic_threat_level: float (0-10)
}
```

### Market Intelligence Relationships

**8. CREATES_OPPORTUNITY (Unmet Need → Market Opportunity)**

```
CREATES_OPPORTUNITY {
  opportunity_size: float
  urgency_level: float (0-10)
  competitive_white_space: float (0-1)
  strategic_alignment: float (0-10)
  barriers_to_entry: array
  time_to_market: duration
}
```

**9. IMPACTS (Regulatory Event → Treatment)**

```
IMPACTS {
  impact_type: enum [positive, negative, neutral]
  magnitude: float (0-10)
  affected_patient_segments: array<PatientSegment>
  market_access_change: string
  competitive_implications: text
  effective_date: date
}
```

**10. INFLUENCES (KOL → Treatment)**

```
INFLUENCES {
  influence_type: enum [advocate, critic, neutral]
  influence_strength: float (0-10)
  therapeutic_area: string
  key_messages: array
  patient_impact: text
  last_interaction: timestamp
}
```

### Evidence & Provenance Relationships

**11. SUPPORTS (Data Source → [Any Entity])**

```
SUPPORTS {
  evidence_type: string
  confidence_level: float (0-1)
  extraction_method: enum [manual, automated, hybrid]
  extraction_date: timestamp
  relevant_excerpts: array
  contradicts: array<DataSource> // Conflicting sources
}
```

**12. DERIVED_FROM (Market Opportunity → [Multiple Entities])**

```
DERIVED_FROM {
  reasoning_chain: array // Trace how opportunity was identified
  contributing_factors: array
  agent_id: string // Which AI agent identified this
  confidence_score: float (0-1)
  validation_status: enum [hypothesis, validated, actionable]
}
```

## Advanced Schema Features

### 1. **Temporal Modeling**

**Implement time-aware relationships to track competitive evolution:**

```
// Example: Track how competitor positioning changes over time
COMPETES_WITH {
  ...existing properties...
  temporal_snapshots: [
    {
      timestamp: "2024-01-15",
      competitive_intensity: 6.5,
      market_share_delta: -0.02
    },
    {
      timestamp: "2024-07-15",
      competitive_intensity: 8.2,
      market_share_delta: 0.05
    }
  ]
  trend_direction: enum [intensifying, stable, declining]
}
```

### 2. **Multi-Hop Reasoning Paths**

**Design schema to enable complex queries like:**

"Find patient segments with high unmet needs that are poorly addressed by competitor treatments, where our pipeline has potential solutions, and where recent regulatory changes favor patient-centric endpoints."

```cypher
// Example Cypher query for Neo4j
MATCH path = (ps:PatientSegment)-[e:EXPERIENCES]->(un:UnmetNeed)
             -[a:ADDRESSED_BY]->(t:Treatment)<-[d:DEVELOPS]-(c:Competitor)
WHERE e.severity > 7.0 
  AND a.effectiveness_score < 5.0
  AND c.name <> "OurCompany"
WITH ps, un, collect(t) as competitor_treatments
MATCH (un)-[:CREATES_OPPORTUNITY]->(mo:MarketOpportunity)
WHERE mo.competitive_white_space > 0.7
MATCH (re:RegulatoryEvent)-[:IMPACTS]->(t2:Treatment)
WHERE re.event_type = "guideline_update"
  AND re.date > date("2024-01-01")
  AND re.decision_rationale CONTAINS "patient-reported outcomes"
RETURN ps, un, mo, competitor_treatments, re
ORDER BY mo.strategic_fit_score DESC
```

### 3. **Confidence & Provenance Tracking**

**Every derived insight should trace back to sources:**

```
MarketOpportunity {
  ...
  derivation_metadata: {
    reasoning_chain: [
      {
        step: 1,
        logic: "Identified high-severity unmet need in RA patient segment",
        supporting_entities: [UnmetNeed_ID_123],
        confidence: 0.85
      },
      {
        step: 2,
        logic: "Competitor treatments show low effectiveness scores",
        supporting_entities: [Treatment_ID_456, Treatment_ID_789],
        confidence: 0.78
      },
      {
        step: 3,
        logic: "Recent FDA guidance emphasizes patient-reported outcomes",
        supporting_entities: [RegulatoryEvent_ID_321],
        confidence: 0.92
      }
    ],
    overall_confidence: 0.85, // Weighted average
    validation_status: "hypothesis",
    created_by_agent: "synthesis_agent_v2.1",
    created_date: "2024-11-15T14:32:00Z"
  }
}
```

### 4. **Semantic Embeddings for Similarity Search**

**Augment nodes with vector embeddings for AI-driven discovery:**

```
UnmetNeed {
  ...
  semantic_embedding: array<float>[1536] // e.g., OpenAI embedding
  similar_needs: array<UnmetNeed> // Pre-computed for performance
}

// Enable queries like:
// "Find unmet needs semantically similar to 'treatment adherence challenges 
// in chronic disease management' across different therapeutic areas"
```

## Implementation Considerations

### Graph Database Selection

**Neo4j (Recommended)**

- **Strengths**: Mature Cypher query language, excellent for multi-hop reasoning, strong community support
- **Use Case Fit**: Ideal for complex competitive intelligence queries requiring path traversal
- **Scalability**: Handles millions of nodes/relationships efficiently with proper indexing

**Amazon Neptune**

- **Strengths**: Managed service, supports both property graph (Gremlin) and RDF/SPARQL
- **Use Case Fit**: Good for cloud-native deployments with AWS ecosystem integration
- **Considerations**: Slightly less intuitive query language than Cypher

**TigerGraph**

- **Strengths**: Superior performance for deep-link analytics, parallel processing
- **Use Case Fit**: Best for real-time pattern detection across massive graphs
- **Considerations**: Steeper learning curve, smaller community

### Schema Evolution Strategy

**Version Control**: Treat schema as code with semantic versioning

```
schema_version: "2.1.0"
migration_scripts: [
  "v2.0_to_v2.1_add_patient_journey_stages.cypher"
]
backward_compatibility: true
deprecation_warnings: [
  "old_unmet_need_severity field deprecated, use severity_score"
]
```

**Incremental Enhancement**: Start with core entities (Patient Segments, Competitors, Treatments) and progressively add complexity

### Integration with AI Agents

**Graph-RAG Pattern**: Agents query knowledge graph for context before LLM reasoning

```python
# Conceptual agent-graph interaction

class CompetitorSurveillanceAgent:
    def analyze_competitor_threat(self, competitor_id, treatment_id):
        # Step 1: Query graph for context
        context = self.graph_db.query("""
            MATCH (c:Competitor {id: $comp_id})-[:DEVELOPS]->(t:Treatment {id: $treat_id})
            MATCH (t)-[a:ADDRESSES]->(un:UnmetNeed)<-[e:EXPERIENCES]-(ps:PatientSegment)
            MATCH (t)-[comp:COMPETES_WITH]->(t2:Treatment)
            RETURN c, t, collect(un) as unmet_needs, 
                   collect(ps) as patient_segments,
                   collect(t2) as competing_treatments
        """, comp_id=competitor_id, treat_id=treatment_id)
        
        # Step 2: Augment with vector similarity search
        similar_opportunities = self.find_similar_market_opportunities(
            context['unmet_needs']
        )
        
        # Step 3: LLM reasoning with graph context
        threat_assessment = self.llm.analyze(
            prompt=f"""Given this competitive context from our knowledge graph:
            {context}
            
            And these similar market opportunities:
            {similar_opportunities}
            
            Assess the strategic threat level and recommend response strategies."""
        )
        
        # Step 4: Write insights back to graph
        self.graph_db.create_competitor_activity(
            competitor_id=competitor_id,
            activity_type="threat_assessment",
            insights=threat_assessment,
            confidence=0.82
        )
        
        return threat_assessment
```

### Performance Optimization

**Indexing Strategy:**

- Create indexes on frequently queried properties: `disease_area`, `development_stage`, `therapeutic_area`
- Use composite indexes for common query patterns: `(therapeutic_area, development_stage)`
- Implement full-text search indexes for `description`, `content` fields

**Materialized Views:**

- Pre-compute high-value aggregations: "Top 10 market opportunities by therapeutic area"
- Cache frequently accessed subgraphs: "Complete competitive landscape for oncology"
- Update materialized views asynchronously when source data changes

**Query Optimization:**

```cypher
// Inefficient: Scans all nodes
MATCH (ps:PatientSegment)-[:EXPERIENCES]->(un:UnmetNeed)
WHERE ps.disease_area = "oncology"
RETURN ps, un

// Optimized: Uses index
MATCH (ps:PatientSegment {disease_area: "oncology"})-[:EXPERIENCES]->(un:UnmetNeed)
RETURN ps, un

// Further optimized: Limits traversal depth
MATCH (ps:PatientSegment {disease_area: "oncology"})-[:EXPERIENCES]->(un:UnmetNeed)
WHERE un.severity_score > 7.0
WITH ps, un LIMIT 100
MATCH (un)-[:CREATES_OPPORTUNITY]->(mo:MarketOpportunity)
RETURN ps, un, mo
```

## Sample Use Cases

### Use Case 1: White Space Identification

**Query**: "Find patient segments with severe unmet needs that no competitor adequately addresses"

```cypher
MATCH (ps:PatientSegment)-[e:EXPERIENCES]->(un:UnmetNeed)
WHERE e.severity > 8.0 AND e.prevalence > 0.3
WITH ps, un
MATCH (un)-[a:ADDRESSED_BY]->(t:Treatment)
WITH ps, un, avg(a.effectiveness_score) as avg_effectiveness
WHERE avg_effectiveness < 5.0
MATCH (un)-[:CREATES_OPPORTUNITY]->(mo:MarketOpportunity)
WHERE mo.competitive_white_space > 0.8
RETURN ps.disease_area, un.description, mo.market_size_estimate, 
       mo.strategic_fit_score
ORDER BY mo.strategic_fit_score DESC
LIMIT 10
```

### Use Case 2: Competitive Threat Assessment

**Query**: "Identify competitor pipeline advances that threaten our market position"

```cypher
MATCH (c:Competitor)-[:DEVELOPS]->(t:Treatment)
WHERE t.development_stage IN ["phase3", "regulatory_review"]
MATCH (t)-[a:ADDRESSES]->(un:UnmetNeed)<-[:ADDRESSES]-(our_t:Treatment)
WHERE our_t.owner.name = "OurCompany"
  AND a.effectiveness_score > 7.0
MATCH (t)<-[:TESTS]-(ct:ClinicalTrial)
WHERE ct.patient_centricity_score > 8.0
RETURN c.name, t.name, un.description, 
       ct.patient_centricity_score,
       a.effectiveness_score as threat_effectiveness
ORDER BY threat_effectiveness DESC
```

### Use Case 3: Patient Journey Optimization

**Query**: "Find friction points in patient journey where competitors have solutions but we don't"

```cypher
MATCH (ps:PatientSegment)-[:NAVIGATES]->(pjs:PatientJourneyStage)
      -[:ENCOUNTERS]->(fp:FrictionPoint)
WHERE fp.impact_severity > 7.0
MATCH (fp)-[:ADDRESSED_BY_COMPETITOR]->(co:CompetitorOffering)
      -[:OFFERED_BY]->(c:Competitor)
WHERE NOT EXISTS {
  MATCH (fp)-[:ADDRESSED_BY_OUR_SOLUTION]->(os:OurSolution)
}
RETURN ps.disease_area, pjs.stage_name, fp.description,
       collect(c.name) as competitors_with_solutions,
       fp.opportunity_score
ORDER BY fp.opportunity_score DESC
```

---

**Would you like me to elaborate on any specific aspect—such as the implementation of temporal queries for tracking competitive dynamics over time, the integration strategy between the knowledge graph and vector databases for hybrid search, or specific query patterns for different agent types?** I can also provide more detailed examples of how to populate this schema from various data sources or discuss schema governance and quality assurance strategies.