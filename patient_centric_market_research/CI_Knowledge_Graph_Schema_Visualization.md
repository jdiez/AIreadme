# Knowledge Graph Schema Visualization Using Mermaid

## Core Patient-Centric Competitive Intelligence Schema

```mermaid
graph TB
    subgraph "Patient Domain"
        PS[PatientSegment<br/>---<br/>disease_area<br/>demographics<br/>clinical_characteristics<br/>size_estimate<br/>growth_rate]
        UN[UnmetNeed<br/>---<br/>need_type<br/>severity_score<br/>prevalence<br/>competitive_white_space_score]
        PJS[PatientJourneyStage<br/>---<br/>stage_name<br/>typical_duration<br/>key_stakeholders]
        FP[FrictionPoint<br/>---<br/>friction_type<br/>impact_severity<br/>opportunity_score]
    end
    
    subgraph "Competitive Domain"
        COMP[Competitor<br/>---<br/>name<br/>organization_type<br/>market_cap<br/>therapeutic_focus_areas<br/>innovation_profile]
        TREAT[Treatment<br/>---<br/>name<br/>development_stage<br/>therapeutic_area<br/>mechanism_of_action<br/>market_performance]
        CT[ClinicalTrial<br/>---<br/>nct_id<br/>phase<br/>status<br/>endpoints<br/>patient_centricity_score]
        CA[CompetitorActivity<br/>---<br/>activity_type<br/>impact_assessment<br/>date<br/>strategic_significance]
    end
    
    subgraph "Market Intelligence Domain"
        MO[MarketOpportunity<br/>---<br/>opportunity_type<br/>market_size_estimate<br/>competitive_intensity<br/>strategic_fit_score]
        RE[RegulatoryEvent<br/>---<br/>event_type<br/>regulatory_body<br/>decision_rationale<br/>date]
        PL[PayerLandscape<br/>---<br/>region<br/>coverage_policies<br/>reimbursement_criteria]
    end
    
    subgraph "Intelligence Sources"
        DS[DataSource<br/>---<br/>source_type<br/>credibility_score<br/>publication_date]
        KOL[KeyOpinionLeader<br/>---<br/>specialty<br/>influence_score<br/>therapeutic_expertise]
        KOLI[KOLInsight<br/>---<br/>insight_type<br/>content<br/>strategic_value]
    end
    
    %% Patient Relationships
    PS -->|EXPERIENCES<br/>severity, prevalence| UN
    PS -->|NAVIGATES<br/>duration, success_rate| PJS
    PJS -->|ENCOUNTERS<br/>frequency, impact| FP
    UN -->|CREATES_OPPORTUNITY<br/>opportunity_size, urgency| MO
    
    %% Competitive Relationships
    COMP -->|DEVELOPS<br/>investment_level, priority| TREAT
    COMP -->|PERFORMED<br/>date| CA
    TREAT -->|ADDRESSES<br/>effectiveness_score, coverage| UN
    TREAT -->|COMPETES_WITH<br/>intensity, market_overlap| TREAT
    CT -->|TESTS<br/>phase, differentiation| TREAT
    CA -->|RELATES_TO| TREAT
    
    %% Market Relationships
    RE -->|IMPACTS<br/>impact_type, magnitude| TREAT
    RE -->|AFFECTS| PL
    TREAT -->|TARGETS| PS
    FP -->|ADDRESSED_BY_COMPETITOR| TREAT
    
    %% Intelligence Relationships
    DS -->|SUPPORTS<br/>confidence_level| UN
    DS -->|SUPPORTS| TREAT
    DS -->|SUPPORTS| CA
    KOL -->|PROVIDES| KOLI
    KOLI -->|RELATES_TO| TREAT
    KOLI -->|IDENTIFIES| UN
    
    style PS fill:#e1f5ff
    style UN fill:#e1f5ff
    style PJS fill:#e1f5ff
    style FP fill:#e1f5ff
    style COMP fill:#ffe1e1
    style TREAT fill:#ffe1e1
    style CT fill:#ffe1e1
    style CA fill:#ffe1e1
    style MO fill:#fff4e1
    style RE fill:#fff4e1
    style PL fill:#fff4e1
    style DS fill:#f0f0f0
    style KOL fill:#f0f0f0
    style KOLI fill:#f0f0f0
```

## Temporal Relationship Schema

```mermaid
graph LR
    subgraph "Current State"
        T_CURRENT[Treatment v5<br/>---<br/>is_current: true<br/>version: 5<br/>effective_from: 2025-11-01<br/>market_share: 0.23<br/>revenue: 450M]
    end
    
    subgraph "Historical Snapshots"
        T_V4[Treatment v4<br/>---<br/>is_current: false<br/>version: 4<br/>effective_from: 2025-05-01<br/>effective_to: 2025-10-31<br/>market_share: 0.19<br/>revenue: 380M]
        
        T_V3[Treatment v3<br/>---<br/>is_current: false<br/>version: 3<br/>effective_from: 2024-11-01<br/>effective_to: 2025-04-30<br/>market_share: 0.15<br/>revenue: 320M]
    end
    
    subgraph "Event Stream"
        E1[TreatmentEvent<br/>---<br/>event_type: market_share_change<br/>timestamp: 2025-11-01<br/>previous_value: 0.19<br/>new_value: 0.23<br/>change_magnitude: 0.04]
        
        E2[TreatmentEvent<br/>---<br/>event_type: regulatory_approval<br/>timestamp: 2025-10-15<br/>trigger: new_indication]
        
        E3[TreatmentEvent<br/>---<br/>event_type: competitive_action<br/>timestamp: 2025-09-20<br/>competitor: CompX]
    end
    
    T_CURRENT -->|PREVIOUS_VERSION| T_V4
    T_V4 -->|PREVIOUS_VERSION| T_V3
    
    T_CURRENT -->|HAS_EVENT| E1
    T_CURRENT -->|HAS_EVENT| E2
    T_CURRENT -->|HAS_EVENT| E3
    
    E1 -->|NEXT_EVENT| E2
    E2 -->|NEXT_EVENT| E3
    
    E2 -->|TRIGGERED_BY| RE[RegulatoryEvent<br/>FDA Approval]
    E3 -->|TRIGGERED_BY| CA[CompetitorActivity<br/>Price Reduction]
    
    style T_CURRENT fill:#90EE90
    style T_V4 fill:#FFE4B5
    style T_V3 fill:#FFE4B5
    style E1 fill:#87CEEB
    style E2 fill:#87CEEB
    style E3 fill:#87CEEB
```

## Temporal Competitive Dynamics Schema

```mermaid
graph TB
    subgraph "Time-Varying Relationships"
        T1[Treatment A<br/>OurCompany]
        T2[Treatment B<br/>Competitor X]
        
        T1 -.->|COMPETES_WITH<br/>valid_from: 2024-01-01<br/>valid_to: 2024-06-30<br/>competitive_intensity: 6.5<br/>market_overlap: 0.42| T2
        
        T1 ==>|COMPETES_WITH<br/>valid_from: 2024-07-01<br/>valid_to: 2025-01-31<br/>competitive_intensity: 8.2<br/>market_overlap: 0.58<br/>trend: intensifying| T2
        
        T1 -->|COMPETES_WITH<br/>valid_from: 2025-02-01<br/>valid_to: null<br/>competitive_intensity: 9.1<br/>market_overlap: 0.65<br/>trend: intensifying| T2
    end
    
    subgraph "Historical Snapshots Embedded"
        REL[COMPETES_WITH Relationship<br/>---<br/>historical_snapshots: [<br/>&nbsp;&nbsp;{date: 2024-01-15, intensity: 6.5},<br/>&nbsp;&nbsp;{date: 2024-07-15, intensity: 8.2},<br/>&nbsp;&nbsp;{date: 2025-02-15, intensity: 9.1}<br/>]<br/>intensity_change_rate: 0.43/month<br/>trend_confidence: 0.87]
    end
    
    subgraph "Trigger Events"
        E1[CompetitorActivity<br/>2024-06-15<br/>New Indication Approval]
        E2[CompetitorActivity<br/>2025-01-20<br/>Head-to-Head Trial Results]
    end
    
    E1 -.->|CAUSED_CHANGE| REL
    E2 -.->|CAUSED_CHANGE| REL
    
    style T1 fill:#90EE90
    style T2 fill:#FFB6C1
    style REL fill:#FFE4B5
    style E1 fill:#DDA0DD
    style E2 fill:#DDA0DD
```

## Bitemporal Schema (Valid Time vs Transaction Time)

```mermaid
graph TB
    subgraph "Bitemporal Tracking"
        CA1[CompetitorActivity<br/>---<br/>VALID TIME:<br/>valid_from: 2025-01-15<br/>valid_to: 2025-01-15<br/>---<br/>TRANSACTION TIME:<br/>recorded_at: 2025-01-20<br/>superseded_at: null<br/>---<br/>is_current_version: true<br/>activity: Pipeline Advancement]
        
        CA2[CompetitorActivity<br/>---<br/>VALID TIME:<br/>valid_from: 2025-01-15<br/>valid_to: 2025-01-15<br/>---<br/>TRANSACTION TIME:<br/>recorded_at: 2025-01-18<br/>superseded_at: 2025-01-20<br/>---<br/>is_current_version: false<br/>activity: Regulatory Filing<br/>correction_reason: Late information]
    end
    
    CA1 -->|CORRECTS| CA2
    
    DS1[DataSource<br/>Press Release<br/>2025-01-20] -->|DISCOVERED_BY| CA1
    DS2[DataSource<br/>SEC Filing<br/>2025-01-18] -->|DISCOVERED_BY| CA2
    
    subgraph "Query Scenarios"
        Q1[What did we know<br/>on 2025-01-19?<br/>→ Returns CA2]
        Q2[What actually happened<br/>on 2025-01-15?<br/>→ Returns CA1]
        Q3[When did we learn<br/>the correct info?<br/>→ 2025-01-20]
    end
    
    style CA1 fill:#90EE90
    style CA2 fill:#FFB6C1
    style Q1 fill:#E0E0E0
    style Q2 fill:#E0E0E0
    style Q3 fill:#E0E0E0
```

## Hybrid Knowledge Graph + Vector Database Schema

```mermaid
graph TB
    subgraph "Knowledge Graph Layer - Neo4j"
        PS_G[PatientSegment<br/>---<br/>id: PS_001<br/>disease_area: RA<br/>embedding_id: PS_001_emb<br/>vector_synced_at: 2025-02-20]
        
        UN_G[UnmetNeed<br/>---<br/>id: UN_123<br/>description: adherence challenges<br/>severity_score: 8.5<br/>embedding_id: UN_123_emb<br/>vector_synced_at: 2025-02-20]
        
        T_G[Treatment<br/>---<br/>id: TREAT_456<br/>name: DrugX<br/>mechanism: JAK inhibitor<br/>embedding_id: TREAT_456_emb<br/>vector_synced_at: 2025-02-19]
    end
    
    subgraph "Vector Database Layer - Pinecone"
        PS_V[Vector: PS_001_emb<br/>---<br/>embedding: [0.23, -0.45, ...]<br/>metadata:<br/>&nbsp;&nbsp;entity_type: PatientSegment<br/>&nbsp;&nbsp;entity_id: PS_001<br/>&nbsp;&nbsp;disease_area: RA<br/>&nbsp;&nbsp;last_synced: 2025-02-20]
        
        UN_V[Vector: UN_123_emb<br/>---<br/>embedding: [0.67, 0.12, ...]<br/>metadata:<br/>&nbsp;&nbsp;entity_type: UnmetNeed<br/>&nbsp;&nbsp;entity_id: UN_123<br/>&nbsp;&nbsp;severity: 8.5<br/>&nbsp;&nbsp;last_synced: 2025-02-20]
        
        T_V[Vector: TREAT_456_emb<br/>---<br/>embedding: [-0.34, 0.78, ...]<br/>metadata:<br/>&nbsp;&nbsp;entity_type: Treatment<br/>&nbsp;&nbsp;entity_id: TREAT_456<br/>&nbsp;&nbsp;therapeutic_area: RA<br/>&nbsp;&nbsp;last_synced: 2025-02-19]
    end
    
    subgraph "Sync Layer"
        SYNC[Bidirectional Sync<br/>---<br/>Graph Update → Vector Update<br/>Incremental Sync Every 5 min<br/>Integrity Validation Hourly]
    end
    
    PS_G <-.->|sync| PS_V
    UN_G <-.->|sync| UN_V
    T_G <-.->|sync| T_V
    
    PS_G -->|EXPERIENCES| UN_G
    UN_G -->|ADDRESSED_BY| T_G
    
    PS_V -.->|semantic_similarity: 0.87| UN_V
    UN_V -.->|semantic_similarity: 0.72| T_V
    
    SYNC -.->|monitors| PS_G
    SYNC -.->|monitors| UN_G
    SYNC -.->|monitors| T_G
    SYNC -.->|updates| PS_V
    SYNC -.->|updates| UN_V
    SYNC -.->|updates| T_V
    
    style PS_G fill:#e1f5ff
    style UN_G fill:#e1f5ff
    style T_G fill:#ffe1e1
    style PS_V fill:#d4f1d4
    style UN_V fill:#d4f1d4
    style T_V fill:#ffd4d4
    style SYNC fill:#fff4e1
```

## Hybrid Search Query Flow

```mermaid
sequenceDiagram
    participant Agent as AI Agent
    participant QO as Query Orchestrator
    participant VDB as Vector Database
    participant KG as Knowledge Graph
    participant Cache as Redis Cache
    
    Agent->>QO: Query: "treatments for RA adherence issues"
    
    QO->>Cache: Check cache
    Cache-->>QO: Cache miss
    
    par Parallel Execution
        QO->>VDB: Semantic search
        Note over VDB: Embed query<br/>Find top 50 similar entities
        VDB-->>QO: Candidate entity IDs + scores
    and
        QO->>KG: Structured query
        Note over KG: MATCH (ps:PatientSegment)<br/>WHERE disease_area = 'RA'
        KG-->>QO: Precise matches
    end
    
    QO->>KG: Enrich semantic candidates
    Note over KG: Fetch relationships,<br/>temporal data,<br/>competitive context
    KG-->>QO: Enriched results
    
    QO->>QO: Merge & rank results
    Note over QO: Combine precision + semantic scores<br/>Apply temporal filters<br/>Deduplicate
    
    QO->>Cache: Store results (TTL: 1h)
    QO->>Agent: Ranked, contextualized results
    
    Agent->>KG: Follow-up: Get competitive dynamics
    KG-->>Agent: Temporal relationship data
```

## Entity Embedding Architecture

```mermaid
graph TB
    subgraph "Entity in Knowledge Graph"
        E[UnmetNeed: RA Adherence<br/>---<br/>Properties:<br/>• need_type: adherence<br/>• severity_score: 8.5<br/>• description: "complex dosing..."<br/>• prevalence: 0.45]
        
        R1[Related: PatientSegment<br/>RA, elderly, comorbidities]
        R2[Related: Treatment<br/>DrugX, DrugY]
        R3[Related: FrictionPoint<br/>Complex dosing schedule]
    end
    
    E -->|EXPERIENCED_BY| R1
    E -->|ADDRESSED_BY| R2
    E -->|MANIFESTS_AS| R3
    
    subgraph "Embedding Generation"
        CTX[Context Assembly<br/>---<br/>Entity properties +<br/>1-hop neighbors +<br/>2-hop context +<br/>Temporal patterns]
        
        TXT[Rich Text Construction<br/>---<br/>"UnmetNeed in RA: complex dosing<br/>adherence challenges, severity 8.5,<br/>affects elderly patients with<br/>comorbidities, partially addressed<br/>by DrugX and DrugY..."]
        
        EMB[Embedding Model<br/>text-embedding-3-large<br/>---<br/>Output: [0.23, -0.45, 0.67, ...]<br/>Dimensions: 1536]
    end
    
    E --> CTX
    R1 --> CTX
    R2 --> CTX
    R3 --> CTX
    
    CTX --> TXT
    TXT --> EMB
    
    subgraph "Vector Storage"
        VEC[Pinecone Vector<br/>---<br/>id: UN_RA_ADH_001<br/>values: [0.23, -0.45, ...]<br/>metadata:<br/>&nbsp;&nbsp;entity_id: UN_RA_ADH_001<br/>&nbsp;&nbsp;entity_type: UnmetNeed<br/>&nbsp;&nbsp;severity: 8.5<br/>&nbsp;&nbsp;disease_area: RA]
    end
    
    EMB --> VEC
    
    VEC -.->|similarity search| VEC2[Similar Vectors<br/>Other adherence issues<br/>across therapeutic areas]
    
    style E fill:#e1f5ff
    style R1 fill:#f0f0f0
    style R2 fill:#f0f0f0
    style R3 fill:#f0f0f0
    style CTX fill:#fff4e1
    style TXT fill:#fff4e1
    style EMB fill:#d4f1d4
    style VEC fill:#d4f1d4
    style VEC2 fill:#d4f1d4
```

## Multi-Agent Query Orchestration Schema

```mermaid
graph TB
    subgraph "User Query"
        Q[Find white spaces in oncology<br/>where patients have high unmet needs<br/>and competitors are weak]
    end
    
    subgraph "Query Decomposition"
        QD[Query Orchestrator<br/>---<br/>Decompose into:<br/>1. Semantic: "high unmet needs"<br/>2. Structured: disease_area = oncology<br/>3. Competitive: weak competitor coverage<br/>4. Temporal: recent trends]
    end
    
    Q --> QD
    
    subgraph "Parallel Execution"
        VQ[Vector Query<br/>---<br/>Semantic search:<br/>"high unmet needs oncology"<br/>Top 100 candidates]
        
        GQ1[Graph Query 1<br/>---<br/>MATCH (ps:PatientSegment)<br/>WHERE disease_area = 'oncology'<br/>AND severity > 7.0]
        
        GQ2[Graph Query 2<br/>---<br/>MATCH (un)-[:ADDRESSED_BY]->(t)<br/>WHERE effectiveness < 5.0<br/>Weak competitor solutions]
        
        GQ3[Graph Query 3<br/>---<br/>MATCH (t)-[:HAS_EVENT]->(e)<br/>WHERE timestamp > date()-6months<br/>Recent competitive dynamics]
    end
    
    QD --> VQ
    QD --> GQ1
    QD --> GQ2
    QD --> GQ3
    
    subgraph "Result Fusion"
        MERGE[Result Merger<br/>---<br/>• Intersect entity IDs<br/>• Calculate combined scores<br/>• Deduplicate<br/>• Rank by relevance]
        
        ENRICH[Context Enrichment<br/>---<br/>• Fetch full entity details<br/>• Add relationship context<br/>• Include temporal trends<br/>• Attach evidence sources]
    end
    
    VQ --> MERGE
    GQ1 --> MERGE
    GQ2 --> MERGE
    GQ3 --> MERGE
    
    MERGE --> ENRICH
    
    subgraph "Final Results"
        RES[Ranked Market Opportunities<br/>---<br/>1. Lung cancer, EGFR+ adherence<br/>&nbsp;&nbsp;&nbsp;Score: 0.92 (semantic: 0.88, graph: 0.95)<br/>2. Melanoma, elderly access barriers<br/>&nbsp;&nbsp;&nbsp;Score: 0.87 (semantic: 0.82, graph: 0.91)<br/>3. Breast cancer, HER2+ side effects<br/>&nbsp;&nbsp;&nbsp;Score: 0.84 (semantic: 0.86, graph: 0.82)]
    end
    
    ENRICH --> RES
    
    style Q fill:#e1f5ff
    style QD fill:#fff4e1
    style VQ fill:#d4f1d4
    style GQ1 fill:#ffe1e1
    style GQ2 fill:#ffe1e1
    style GQ3 fill:#ffe1e1
    style MERGE fill:#fff4e1
    style ENRICH fill:#fff4e1
    style RES fill:#90EE90
```

## Complete Entity Relationship Diagram (ERD Style)

```mermaid
erDiagram
    PatientSegment ||--o{ UnmetNeed : EXPERIENCES
    PatientSegment ||--o{ PatientJourneyStage : NAVIGATES
    PatientJourneyStage ||--o{ FrictionPoint : ENCOUNTERS
    UnmetNeed ||--o{ MarketOpportunity : CREATES_OPPORTUNITY
    UnmetNeed }o--o{ Treatment : ADDRESSED_BY
    
    Competitor ||--o{ Treatment : DEVELOPS
    Competitor ||--o{ CompetitorActivity : PERFORMED
    Competitor }o--o{ Partnership : PARTICIPATES_IN
    
    Treatment ||--o{ ClinicalTrial : TESTED_IN
    Treatment }o--o{ Treatment : COMPETES_WITH
    Treatment }o--|| PatientSegment : TARGETS
    Treatment }o--o{ RegulatoryEvent : IMPACTED_BY
    
    ClinicalTrial }o--|| DataSource : DOCUMENTED_IN
    CompetitorActivity }o--|| DataSource : REPORTED_IN
    
    KOL ||--o{ KOLInsight : PROVIDES
    KOLInsight }o--|| Treatment : RELATES_TO
    KOLInsight }o--|| UnmetNeed : IDENTIFIES
    
    RegulatoryEvent }o--|| PayerLandscape : AFFECTS
    
    DataSource ||--o{ UnmetNeed : SUPPORTS
    DataSource ||--o{ Treatment : SUPPORTS
    DataSource ||--o{ CompetitorActivity : SUPPORTS
    
    PatientSegment {
        string id PK
        string disease_area
        object demographics
        object clinical_characteristics
        int size_estimate
        float growth_rate
        string embedding_id FK
        datetime vector_synced_at
    }
    
    UnmetNeed {
        string id PK
        enum need_type
        text description
        float severity_score
        float prevalence
        float competitive_white_space_score
        string embedding_id FK
        datetime last_updated
    }
    
    Treatment {
        string id PK
        string name
        string brand_name
        enum development_stage
        string therapeutic_area
        object market_performance
        string embedding_id FK
        int version
        boolean is_current
    }
    
    Competitor {
        string id PK
        string name
        enum organization_type
        float market_cap
        array therapeutic_focus_areas
        object innovation_profile
    }
    
    ClinicalTrial {
        string id PK
        string nct_id
        enum phase
        enum status
        object endpoints
        float patient_centricity_score
        date start_date
    }
    
    MarketOpportunity {
        string id PK
        enum opportunity_type
        float market_size_estimate
        float competitive_intensity
        float strategic_fit_score
        float confidence_level
    }
```

## Temporal Event Sourcing Schema

```mermaid
graph LR
    subgraph "Entity Current State"
        T[Treatment: DrugX<br/>Current State<br/>market_share: 0.25<br/>revenue: 500M<br/>stage: marketed]
    end
    
    subgraph "Event Stream (Ordered)"
        E1[Event 1<br/>2024-03-15<br/>Type: launch<br/>market_share: 0 → 0.08]
        
        E2[Event 2<br/>2024-06-20<br/>Type: indication_expansion<br/>market_share: 0.08 → 0.12]
        
        E3[Event 3<br/>2024-09-10<br/>Type: competitor_action<br/>market_share: 0.12 → 0.10<br/>trigger: CompX price cut]
        
        E4[Event 4<br/>2025-01-05<br/>Type: positive_trial_data<br/>market_share: 0.10 → 0.18]
        
        E5[Event 5<br/>2025-02-15<br/>Type: market_expansion<br/>market_share: 0.18 → 0.25]
    end
    
    T -->|HAS_EVENT| E1
    T -->|HAS_EVENT| E2
    T -->|HAS_EVENT| E3
    T -->|HAS_EVENT| E4
    T -->|HAS_EVENT| E5
    
    E1 -->|NEXT| E2
    E2 -->|NEXT| E3
    E3 -->|NEXT| E4
    E4 -->|NEXT| E5
    
    subgraph "State Reconstruction"
        R1[State at 2024-07-01<br/>Apply events 1-2<br/>market_share: 0.12]
        
        R2[State at 2024-12-01<br/>Apply events 1-4<br/>market_share: 0.10]
    end
    
    E2 -.->|reconstruct| R1
    E3 -.->|reconstruct| R2
    
    style T fill:#90EE90
    style E1 fill:#87CEEB
    style E2 fill:#87CEEB
    style E3 fill:#FFB6C1
    style E4 fill:#87CEEB
    style E5 fill:#87CEEB
    style R1 fill:#FFE4B5
    style R2 fill:#FFE4B5
```

---

These Mermaid diagrams provide comprehensive visualizations of:

1. **Core schema** with all major entities and relationships
2. **Temporal modeling** approaches (snapshots, events, bitemporal)
3. **Hybrid architecture** integrating knowledge graphs and vector databases
4. **Query orchestration** patterns for multi-agent systems
5. **Entity embedding** generation and synchronization
6. **Event sourcing** for temporal state reconstruction

**Would you like me to create additional diagrams for specific aspects—such as the agent communication flow, data ingestion pipeline architecture, or specific query pattern visualizations for different competitive intelligence use cases?** I can also provide diagrams showing the schema evolution strategy or monitoring/observability architecture.