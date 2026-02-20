# Temporal Queries & Hybrid Search Integration for Competitive Intelligence

## Part 1: Temporal Modeling for Competitive Dynamics

### Temporal Data Architecture

**Design Philosophy**: Competitive intelligence requires understanding not just *what* is happening, but *how* the landscape is evolving. Temporal modeling enables trend analysis, early warning signals, and predictive insights.

### 1. **Temporal Node Versioning**

**Approach A: Snapshot Pattern (Recommended for Slowly Changing Entities)**

Create immutable historical snapshots while maintaining a "current" pointer:

```
// Current state node
Treatment {
  id: "TREAT_001"
  name: "CompetitorDrug_X"
  is_current: true
  version: 5
  effective_from: "2025-11-01"
  effective_to: null
  market_share: 0.23
  revenue: 450000000
  development_stage: "marketed"
  // ... other properties
}

// Historical snapshot
Treatment {
  id: "TREAT_001_v4"
  name: "CompetitorDrug_X"
  is_current: false
  version: 4
  effective_from: "2025-05-01"
  effective_to: "2025-10-31"
  market_share: 0.19
  revenue: 380000000
  development_stage: "marketed"
  // ... other properties
}

// Relationship connecting versions
(current_treatment)-[:PREVIOUS_VERSION]->(historical_treatment)
```

**Cypher Implementation:**

```cypher
// Create new version when market share changes
MATCH (current:Treatment {id: "TREAT_001", is_current: true})
SET current.is_current = false,
    current.effective_to = date()
CREATE (new_version:Treatment)
SET new_version = current,
    new_version.id = "TREAT_001",
    new_version.version = current.version + 1,
    new_version.is_current = true,
    new_version.effective_from = date(),
    new_version.effective_to = null,
    new_version.market_share = 0.25  // Updated value
CREATE (new_version)-[:PREVIOUS_VERSION]->(current)
```

**Query Historical Evolution:**

```cypher
// Track market share evolution over time
MATCH path = (current:Treatment {id: "TREAT_001", is_current: true})
             -[:PREVIOUS_VERSION*0..]->(historical:Treatment)
WHERE historical.effective_from >= date("2024-01-01")
RETURN historical.effective_from as date,
       historical.market_share,
       historical.revenue
ORDER BY date DESC
```

**Approach B: Event Sourcing Pattern (Recommended for High-Frequency Changes)**

Store changes as discrete events rather than full snapshots:

```
TreatmentEvent {
  id: string
  treatment_id: string
  event_type: enum [market_share_change, revenue_update, 
                    stage_advancement, regulatory_event, 
                    competitive_action]
  timestamp: datetime
  previous_value: object
  new_value: object
  change_magnitude: float
  trigger_source: DataSource
  agent_detected: string
}

// Relationships
(Treatment)-[:HAS_EVENT]->(TreatmentEvent)
(TreatmentEvent)-[:NEXT_EVENT]->(TreatmentEvent)  // Ordered chain
```

**Reconstruct State at Any Point in Time:**

```cypher
// Get treatment state as of specific date
MATCH (t:Treatment {id: "TREAT_001"})
MATCH (t)-[:HAS_EVENT]->(e:TreatmentEvent)
WHERE e.timestamp <= datetime("2025-06-15T00:00:00Z")
WITH t, e
ORDER BY e.timestamp DESC
WITH t, collect(e) as events
RETURN t.id,
       // Reconstruct state by applying events in reverse
       reduce(state = {}, event IN events | 
         apoc.map.merge(state, event.previous_value)
       ) as state_at_date
```

### 2. **Temporal Relationship Modeling**

**Time-Varying Relationships with Validity Periods:**

```
COMPETES_WITH {
  relationship_id: string
  valid_from: datetime
  valid_to: datetime  // null = still active
  
  // Temporal metrics
  competitive_intensity: float
  market_overlap: float
  patient_switching_rate: float
  
  // Change tracking
  intensity_trend: enum [intensifying, stable, declining]
  trend_confidence: float
  last_updated: datetime
  
  // Historical snapshots embedded
  historical_snapshots: [
    {
      snapshot_date: "2025-01-15",
      competitive_intensity: 6.5,
      market_overlap: 0.42,
      key_events: ["competitor_price_reduction", "new_indication_approval"]
    },
    {
      snapshot_date: "2025-07-15",
      competitive_intensity: 8.2,
      market_overlap: 0.58,
      key_events: ["head_to_head_trial_results", "market_expansion"]
    }
  ]
}
```

**Query Competitive Intensity Trends:**

```cypher
// Find competitors with rapidly intensifying competition
MATCH (our_treatment:Treatment {owner: "OurCompany"})
      -[comp:COMPETES_WITH]->(competitor_treatment:Treatment)
WHERE comp.valid_to IS NULL  // Active relationships only
WITH our_treatment, competitor_treatment, comp,
     comp.historical_snapshots as snapshots
UNWIND snapshots as snapshot
WITH our_treatment, competitor_treatment, comp,
     snapshot.snapshot_date as date,
     snapshot.competitive_intensity as intensity
ORDER BY date
WITH our_treatment, competitor_treatment, comp,
     collect({date: date, intensity: intensity}) as timeline
WHERE size(timeline) >= 3
WITH our_treatment, competitor_treatment, comp, timeline,
     // Calculate rate of change (slope)
     (last(timeline).intensity - head(timeline).intensity) / 
     duration.between(
       date(head(timeline).date), 
       date(last(timeline).date)
     ).months as intensity_change_rate
WHERE intensity_change_rate > 0.3  // Threshold for "rapidly intensifying"
RETURN our_treatment.name,
       competitor_treatment.name,
       competitor_treatment.owner as competitor,
       intensity_change_rate,
       last(timeline).intensity as current_intensity,
       timeline
ORDER BY intensity_change_rate DESC
```

### 3. **Advanced Temporal Query Patterns**

**Pattern A: Time-Series Aggregation for Market Dynamics**

```cypher
// Analyze quarterly market share shifts across therapeutic area
MATCH (t:Treatment)-[:HAS_EVENT]->(e:TreatmentEvent)
WHERE t.therapeutic_area = "oncology"
  AND e.event_type = "market_share_change"
  AND e.timestamp >= datetime("2024-01-01")
WITH t, e,
     // Group by quarter
     date.truncate("quarter", e.timestamp) as quarter
WITH quarter, t.owner as company,
     avg(e.new_value.market_share) as avg_market_share
ORDER BY quarter, company
RETURN quarter,
       collect({
         company: company,
         market_share: avg_market_share
       }) as market_composition
```

**Pattern B: Leading Indicator Detection**

Identify events that historically precede competitive threats:

```cypher
// Find patterns: regulatory events → market share gains
MATCH (re:RegulatoryEvent)-[:IMPACTS]->(t:Treatment)
WHERE re.event_type = "label_expansion"
  AND re.date >= date("2023-01-01")
WITH t, re.date as regulatory_date
MATCH (t)-[:HAS_EVENT]->(me:TreatmentEvent)
WHERE me.event_type = "market_share_change"
  AND me.timestamp > datetime(regulatory_date)
  AND me.timestamp < datetime(regulatory_date) + duration({months: 6})
  AND me.new_value.market_share > me.previous_value.market_share
WITH t, regulatory_date, me,
     duration.between(datetime(regulatory_date), me.timestamp).months as lag_months,
     me.new_value.market_share - me.previous_value.market_share as share_gain
RETURN t.name,
       t.owner as competitor,
       regulatory_date,
       avg(lag_months) as avg_lag_to_impact,
       avg(share_gain) as avg_share_gain,
       count(me) as occurrences
ORDER BY avg_share_gain DESC
```

**Pattern C: Competitive Trajectory Forecasting**

Use historical patterns to predict future competitive dynamics:

```cypher
// Predict market share 6 months forward using linear regression
MATCH (t:Treatment {id: "TREAT_001"})-[:HAS_EVENT]->(e:TreatmentEvent)
WHERE e.event_type = "market_share_change"
  AND e.timestamp >= datetime() - duration({months: 12})
WITH t, e
ORDER BY e.timestamp
WITH t, 
     collect(e.timestamp) as timestamps,
     collect(e.new_value.market_share) as market_shares
WITH t, timestamps, market_shares,
     // Calculate linear regression coefficients
     apoc.math.regr(
       [i IN range(0, size(timestamps)-1) | i],
       market_shares
     ) as regression
RETURN t.name,
       last(market_shares) as current_share,
       // Forecast 6 months ahead
       regression.slope * (size(timestamps) + 6) + regression.intercept as predicted_share_6m,
       regression.r2 as forecast_confidence
```

### 4. **Temporal Anomaly Detection**

**Identify Unexpected Competitive Shifts:**

```cypher
// Detect anomalous competitive intensity changes
MATCH (t1:Treatment)-[comp:COMPETES_WITH]->(t2:Treatment)
WHERE comp.valid_to IS NULL
WITH t1, t2, comp,
     comp.historical_snapshots as snapshots
UNWIND snapshots as snapshot
WITH t1, t2, comp,
     snapshot.competitive_intensity as intensity,
     snapshot.snapshot_date as date
ORDER BY date
WITH t1, t2, comp,
     collect(intensity) as intensity_series
WITH t1, t2, comp, intensity_series,
     // Calculate moving statistics
     apoc.coll.avg(intensity_series) as mean_intensity,
     apoc.coll.stdev(intensity_series) as std_intensity,
     last(intensity_series) as current_intensity
WHERE current_intensity > mean_intensity + (2 * std_intensity)  // 2 sigma threshold
RETURN t1.name as our_treatment,
       t2.name as competitor_treatment,
       t2.owner as competitor,
       current_intensity,
       mean_intensity,
       (current_intensity - mean_intensity) / std_intensity as z_score,
       "ANOMALY_DETECTED" as alert_type
ORDER BY z_score DESC
```

### 5. **Temporal Window Functions**

**Sliding Window Analysis for Trend Detection:**

```cypher
// 90-day rolling average of competitive actions
MATCH (c:Competitor)-[:PERFORMED]->(ca:CompetitorActivity)
WHERE ca.date >= date() - duration({days: 365})
WITH c, ca
ORDER BY ca.date
WITH c,
     ca.date as activity_date,
     ca.impact_assessment.strategic_significance as significance,
     // Create 90-day windows
     [a IN collect(ca) WHERE 
      a.date >= activity_date - duration({days: 90}) AND
      a.date <= activity_date | 
      a.impact_assessment.strategic_significance
     ] as window_activities
WITH c, activity_date,
     apoc.coll.avg(window_activities) as rolling_avg_significance,
     size(window_activities) as activity_count
WHERE activity_count >= 5  // Minimum activities for meaningful average
RETURN c.name as competitor,
       activity_date,
       rolling_avg_significance,
       activity_count
ORDER BY competitor, activity_date
```

### 6. **Bitemporal Modeling for Audit Trail**

**Track both "valid time" (when fact was true) and "transaction time" (when we learned about it):**

```
CompetitorActivity {
  id: string
  
  // Valid time: when the activity actually occurred
  valid_from: date
  valid_to: date
  
  // Transaction time: when we recorded this information
  recorded_at: datetime
  superseded_at: datetime  // When this record was corrected/updated
  
  // Allow for late-arriving information
  is_current_version: boolean
  correction_reason: string
  
  activity_type: string
  description: text
  // ... other properties
}

// Relationships
(current_record)-[:CORRECTS]->(previous_record)
(activity)-[:DISCOVERED_BY]->(data_source)
```

**Query "What did we know when?":**

```cypher
// Reconstruct competitive landscape as of specific past date
MATCH (ca:CompetitorActivity)
WHERE ca.recorded_at <= datetime("2025-06-01T00:00:00Z")
  AND (ca.superseded_at IS NULL OR 
       ca.superseded_at > datetime("2025-06-01T00:00:00Z"))
  AND ca.valid_from <= date("2025-06-01")
  AND (ca.valid_to IS NULL OR ca.valid_to >= date("2025-06-01"))
RETURN ca.competitor,
       ca.activity_type,
       ca.description,
       ca.recorded_at as when_we_learned
ORDER BY ca.competitor, ca.valid_from
```

---

## Part 2: Hybrid Knowledge Graph + Vector Database Integration

### Architecture Overview

**Integration Philosophy**: Combine the structured reasoning power of knowledge graphs with the semantic understanding of vector embeddings to enable both precise queries and fuzzy similarity search.

### 1. **Dual-Store Architecture**

**Component Breakdown:**

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Agent Layer                            │
│  (Query Orchestration, Context Assembly, Reasoning)          │
└────────────┬────────────────────────────┬───────────────────┘
             │                            │
             ▼                            ▼
┌────────────────────────┐   ┌───────────────────────────────┐
│   Knowledge Graph      │   │   Vector Database             │
│   (Neo4j)              │   │   (Pinecone/Weaviate/Qdrant)  │
│                        │   │                               │
│ • Structured entities  │   │ • Semantic embeddings         │
│ • Explicit relations   │   │ • Similarity search           │
│ • Temporal tracking    │   │ • Fuzzy matching              │
│ • Multi-hop reasoning  │   │ • Cross-domain discovery      │
└────────────────────────┘   └───────────────────────────────┘
             │                            │
             └────────────┬───────────────┘
                          ▼
              ┌───────────────────────┐
              │   Sync & Index Layer  │
              │   (Bidirectional)     │
              └───────────────────────┘
```

### 2. **Entity Embedding Strategy**

**Embed Key Entities for Semantic Search:**

```python
# Conceptual implementation

class EntityEmbedder:
    def __init__(self, embedding_model="text-embedding-3-large"):
        self.model = embedding_model
        self.graph_db = Neo4jConnection()
        self.vector_db = PineconeClient()
    
    def generate_entity_embedding(self, entity_type, entity_id):
        """Create rich semantic representation of entity"""
        
        # Step 1: Fetch entity with context from graph
        context = self.graph_db.query(f"""
            MATCH (e:{entity_type} {{id: $entity_id}})
            OPTIONAL MATCH (e)-[r1]-(related1)
            OPTIONAL MATCH (e)-[r2]-(related2)-[r3]-(related3)
            RETURN e,
                   collect(DISTINCT related1) as direct_neighbors,
                   collect(DISTINCT related3) as extended_neighbors
        """, entity_id=entity_id)
        
        # Step 2: Construct rich text representation
        embedding_text = self._construct_embedding_text(context)
        
        # Step 3: Generate embedding
        embedding = self.embed_text(embedding_text)
        
        # Step 4: Store in vector DB with metadata
        self.vector_db.upsert(
            id=f"{entity_type}_{entity_id}",
            values=embedding,
            metadata={
                "entity_type": entity_type,
                "entity_id": entity_id,
                "graph_properties": context['e'],
                "last_updated": datetime.now().isoformat()
            }
        )
        
        # Step 5: Store embedding reference in graph
        self.graph_db.query(f"""
            MATCH (e:{entity_type} {{id: $entity_id}})
            SET e.embedding_id = $embedding_id,
                e.embedding_updated = datetime()
        """, entity_id=entity_id, 
             embedding_id=f"{entity_type}_{entity_id}")
        
        return embedding
    
    def _construct_embedding_text(self, context):
        """Create comprehensive text for embedding"""
        entity = context['e']
        
        # Build rich description
        text_parts = [
            f"Entity Type: {entity.labels[0]}",
            f"Name: {entity.get('name', entity.get('description', ''))}",
            f"Description: {entity.get('description', '')}",
        ]
        
        # Add domain-specific fields
        if 'UnmetNeed' in entity.labels:
            text_parts.extend([
                f"Need Type: {entity.get('need_type')}",
                f"Severity: {entity.get('severity_score')}",
                f"Patient Impact: {entity.get('description')}",
            ])
        elif 'Treatment' in entity.labels:
            text_parts.extend([
                f"Therapeutic Area: {entity.get('therapeutic_area')}",
                f"Mechanism: {entity.get('mechanism_of_action')}",
                f"Development Stage: {entity.get('development_stage')}",
            ])
        
        # Add relationship context
        if context['direct_neighbors']:
            neighbors_text = ", ".join([
                f"{n.labels[0]}: {n.get('name', n.get('description', ''))[:50]}"
                for n in context['direct_neighbors'][:5]
            ])
            text_parts.append(f"Related Entities: {neighbors_text}")
        
        return " | ".join(text_parts)
```

### 3. **Hybrid Search Patterns**

**Pattern A: Semantic Discovery → Graph Enrichment**

Use vector search to find similar entities, then use graph to explore relationships:

```python
class HybridSearchEngine:
    def semantic_discovery_with_graph_context(self, query_text, top_k=10):
        """
        Find semantically similar entities, then enrich with graph relationships
        """
        
        # Step 1: Vector similarity search
        query_embedding = self.embed_text(query_text)
        similar_entities = self.vector_db.query(
            vector=query_embedding,
            top_k=top_k,
            include_metadata=True
        )
        
        # Step 2: Extract entity IDs
        entity_ids = [
            match['metadata']['entity_id'] 
            for match in similar_entities['matches']
        ]
        
        # Step 3: Enrich with graph context
        enriched_results = []
        for entity_id, match in zip(entity_ids, similar_entities['matches']):
            entity_type = match['metadata']['entity_type']
            
            # Query graph for relationships
            graph_context = self.graph_db.query(f"""
                MATCH (e:{entity_type} {{id: $entity_id}})
                OPTIONAL MATCH (e)-[r:ADDRESSES]->(un:UnmetNeed)
                OPTIONAL MATCH (e)-[c:COMPETES_WITH]->(competitor:Treatment)
                OPTIONAL MATCH (e)<-[:DEVELOPS]-(comp:Competitor)
                RETURN e,
                       collect(DISTINCT un) as unmet_needs,
                       collect(DISTINCT competitor) as competitors,
                       comp.name as developer
            """, entity_id=entity_id)
            
            enriched_results.append({
                "entity": graph_context['e'],
                "similarity_score": match['score'],
                "unmet_needs": graph_context['unmet_needs'],
                "competitors": graph_context['competitors'],
                "developer": graph_context['developer']
            })
        
        return enriched_results

# Example usage
search = HybridSearchEngine()
results = search.semantic_discovery_with_graph_context(
    "treatments for chronic pain with poor adherence due to side effects"
)

# Returns treatments semantically matching the query, enriched with:
# - Which unmet needs they address
# - Competing treatments
# - Developer information
# - Competitive dynamics from graph
```

**Pattern B: Graph Traversal → Semantic Filtering**

Use graph to find candidate entities, then vector search to rank by relevance:

```python
def graph_traversal_with_semantic_ranking(self, start_entity_id, 
                                          semantic_filter_query,
                                          max_depth=3):
    """
    Traverse graph from starting point, then rank results by semantic relevance
    """
    
    # Step 1: Graph traversal to find candidates
    candidates = self.graph_db.query("""
        MATCH path = (start {id: $start_id})-[*1..{max_depth}]-(candidate)
        WHERE candidate:Treatment OR candidate:UnmetNeed OR candidate:MarketOpportunity
        RETURN DISTINCT candidate,
               length(path) as distance,
               [rel IN relationships(path) | type(rel)] as relationship_path
    """, start_id=start_entity_id, max_depth=max_depth)
    
    # Step 2: Get embeddings for candidates
    candidate_embeddings = []
    for candidate in candidates:
        embedding_id = candidate['candidate'].get('embedding_id')
        if embedding_id:
            candidate_embeddings.append({
                "candidate": candidate,
                "embedding_id": embedding_id
            })
    
    # Step 3: Semantic ranking
    filter_embedding = self.embed_text(semantic_filter_query)
    
    ranked_results = []
    for item in candidate_embeddings:
        # Fetch embedding from vector DB
        stored_embedding = self.vector_db.fetch([item['embedding_id']])
        
        # Calculate semantic similarity
        similarity = self._cosine_similarity(
            filter_embedding, 
            stored_embedding['vectors'][item['embedding_id']]['values']
        )
        
        ranked_results.append({
            "entity": item['candidate']['candidate'],
            "graph_distance": item['candidate']['distance'],
            "relationship_path": item['candidate']['relationship_path'],
            "semantic_similarity": similarity,
            # Hybrid score: combine graph proximity and semantic relevance
            "hybrid_score": (1 / item['candidate']['distance']) * similarity
        })
    
    # Sort by hybrid score
    ranked_results.sort(key=lambda x: x['hybrid_score'], reverse=True)
    
    return ranked_results

# Example usage
results = search.graph_traversal_with_semantic_ranking(
    start_entity_id="PATIENT_SEGMENT_RA_001",
    semantic_filter_query="innovative delivery mechanisms improving patient convenience",
    max_depth=3
)

# Returns entities connected to RA patient segment, ranked by how well they
# match "innovative delivery mechanisms" semantically
```

**Pattern C: Multi-Modal Query Fusion**

Combine structured graph queries with semantic search in single operation:

```python
def fused_competitive_intelligence_query(self, 
                                         structured_criteria,
                                         semantic_criteria):
    """
    Execute parallel structured and semantic queries, then merge results
    """
    
    # Parallel execution
    with ThreadPoolExecutor(max_workers=2) as executor:
        # Thread 1: Structured graph query
        graph_future = executor.submit(
            self._execute_structured_query,
            structured_criteria
        )
        
        # Thread 2: Semantic vector search
        vector_future = executor.submit(
            self._execute_semantic_search,
            semantic_criteria
        )
        
        graph_results = graph_future.result()
        vector_results = vector_future.result()
    
    # Merge and deduplicate
    merged_results = self._merge_results(graph_results, vector_results)
    
    return merged_results

def _execute_structured_query(self, criteria):
    """Execute precise graph query"""
    return self.graph_db.query("""
        MATCH (ps:PatientSegment)-[:EXPERIENCES]->(un:UnmetNeed)
        WHERE ps.disease_area = $disease_area
          AND un.severity_score > $min_severity
        MATCH (un)-[:CREATES_OPPORTUNITY]->(mo:MarketOpportunity)
        WHERE mo.competitive_white_space > $min_white_space
        RETURN ps, un, mo
    """, **criteria)

def _execute_semantic_search(self, criteria):
    """Execute fuzzy semantic search"""
    query_embedding = self.embed_text(criteria['semantic_query'])
    return self.vector_db.query(
        vector=query_embedding,
        filter={
            "entity_type": {"$in": criteria['entity_types']},
            "therapeutic_area": criteria.get('therapeutic_area')
        },
        top_k=50
    )

def _merge_results(self, graph_results, vector_results):
    """Intelligent result merging with scoring"""
    merged = {}
    
    # Add graph results with high precision score
    for result in graph_results:
        entity_id = result['un']['id']
        merged[entity_id] = {
            "entity": result['un'],
            "source": "graph",
            "precision_score": 1.0,  # Exact match
            "semantic_score": 0.0,
            "context": {
                "patient_segment": result['ps'],
                "market_opportunity": result['mo']
            }
        }
    
    # Add/augment with vector results
    for result in vector_results['matches']:
        entity_id = result['metadata']['entity_id']
        
        if entity_id in merged:
            # Entity found in both: boost score
            merged[entity_id]['semantic_score'] = result['score']
            merged[entity_id]['combined_score'] = (
                merged[entity_id]['precision_score'] * 0.6 +
                result['score'] * 0.4
            )
        else:
            # Entity only in semantic search
            merged[entity_id] = {
                "entity": result['metadata'],
                "source": "vector",
                "precision_score": 0.0,
                "semantic_score": result['score'],
                "combined_score": result['score'] * 0.4
            }
    
    # Sort by combined score
    return sorted(
        merged.values(),
        key=lambda x: x.get('combined_score', x['semantic_score']),
        reverse=True
    )

# Example usage
results = search.fused_competitive_intelligence_query(
    structured_criteria={
        "disease_area": "rheumatoid_arthritis",
        "min_severity": 7.0,
        "min_white_space": 0.7
    },
    semantic_criteria={
        "semantic_query": "patient adherence challenges due to complex dosing schedules",
        "entity_types": ["UnmetNeed", "Treatment"],
        "therapeutic_area": "rheumatoid_arthritis"
    }
)
```

### 4. **Bidirectional Synchronization**

**Keep Graph and Vector DB in Sync:**

```python
class GraphVectorSync:
    def __init__(self):
        self.graph_db = Neo4jConnection()
        self.vector_db = PineconeClient()
        self.embedding_model = EmbeddingModel()
    
    def sync_entity_update(self, entity_type, entity_id):
        """
        When entity updates in graph, propagate to vector DB
        """
        
        # Fetch updated entity from graph
        entity_data = self.graph_db.query(f"""
            MATCH (e:{entity_type} {{id: $entity_id}})
            OPTIONAL MATCH (e)-[r]-(related)
            RETURN e, collect(related) as context
        """, entity_id=entity_id)
        
        # Regenerate embedding with updated context
        embedding_text = self._construct_embedding_text(entity_data)
        new_embedding = self.embedding_model.embed(embedding_text)
        
        # Update vector DB
        self.vector_db.upsert(
            id=f"{entity_type}_{entity_id}",
            values=new_embedding,
            metadata={
                "entity_type": entity_type,
                "entity_id": entity_id,
                "last_synced": datetime.now().isoformat(),
                **entity_data['e']  # Include key properties
            }
        )
        
        # Update sync timestamp in graph
        self.graph_db.query(f"""
            MATCH (e:{entity_type} {{id: $entity_id}})
            SET e.vector_synced_at = datetime()
        """, entity_id=entity_id)
    
    def incremental_sync(self, since_timestamp):
        """
        Sync all entities modified since timestamp
        """
        
        # Find entities modified since last sync
        modified_entities = self.graph_db.query("""
            MATCH (e)
            WHERE e.last_updated > $since
              AND (e:Treatment OR e:UnmetNeed OR e:MarketOpportunity 
                   OR e:CompetitorActivity)
            RETURN labels(e)[0] as entity_type, 
                   e.id as entity_id,
                   e.last_updated as modified_at
            ORDER BY modified_at
        """, since=since_timestamp)
        
        # Batch sync
        for entity in modified_entities:
            self.sync_entity_update(
                entity['entity_type'],
                entity['entity_id']
            )
        
        return len(modified_entities)
    
    def validate_sync_integrity(self):
        """
        Ensure graph and vector DB are consistent
        """
        
        # Check for entities in graph missing from vector DB
        missing_in_vector = self.graph_db.query("""
            MATCH (e)
            WHERE (e:Treatment OR e:UnmetNeed OR e:MarketOpportunity)
              AND (e.embedding_id IS NULL OR e.vector_synced_at IS NULL)
            RETURN labels(e)[0] as entity_type, e.id as entity_id
            LIMIT 100
        """)
        
        # Sync missing entities
        for entity in missing_in_vector:
            self.sync_entity_update(
                entity['entity_type'],
                entity['entity_id']
            )
        
        return {
            "missing_synced": len(missing_in_vector),
            "sync_status": "healthy" if len(missing_in_vector) == 0 else "degraded"
        }
```

### 5. **Advanced Hybrid Query Patterns**

**Pattern D: Temporal Semantic Search**

Find entities similar to query that also show specific temporal patterns:

```python
def temporal_semantic_search(self, query_text, temporal_criteria):
    """
    Combine semantic similarity with temporal filtering
    """
    
    # Step 1: Semantic search for candidates
    query_embedding = self.embed_text(query_text)
    semantic_candidates = self.vector_db.query(
        vector=query_embedding,
        top_k=100,  # Cast wide net
        include_metadata=True
    )
    
    # Step 2: Filter by temporal patterns in graph
    candidate_ids = [m['metadata']['entity_id'] for m in semantic_candidates['matches']]
    
    temporal_filtered = self.graph_db.query("""
        MATCH (e)
        WHERE e.id IN $candidate_ids
        MATCH (e)-[:HAS_EVENT]->(event:TreatmentEvent)
        WHERE event.timestamp >= $start_date
          AND event.timestamp <= $end_date
        WITH e, event
        ORDER BY event.timestamp
        WITH e, collect(event) as events
        WHERE size(events) >= $min_events
        WITH e, events,
             // Calculate trend
             (last(events).new_value.market_share - 
              head(events).new_value.market_share) as trend
        WHERE trend > $min_trend
        RETURN e.id as entity_id, trend, events
    """, 
        candidate_ids=candidate_ids,
        start_date=temporal_criteria['start_date'],
        end_date=temporal_criteria['end_date'],
        min_events=temporal_criteria.get('min_events', 3),
        min_trend=temporal_criteria.get('min_trend', 0.05)
    )
    
    # Step 3: Merge semantic and temporal scores
    results = []
    semantic_scores = {
        m['metadata']['entity_id']: m['score'] 
        for m in semantic_candidates['matches']
    }
    
    for item in temporal_filtered:
        results.append({
            "entity_id": item['entity_id'],
            "semantic_score": semantic_scores[item['entity_id']],
            "temporal_trend": item['trend'],
            "events": item['events'],
            # Combined score
            "relevance_score": (
                semantic_scores[item['entity_id']] * 0.5 +
                min(item['trend'] * 10, 1.0) * 0.5  # Normalize trend
            )
        })
    
    return sorted(results, key=lambda x: x['relevance_score'], reverse=True)

# Example usage
results = search.temporal_semantic_search(
    query_text="treatments showing improved patient adherence",
    temporal_criteria={
        "start_date": "2024-01-01",
        "end_date": "2025-12-31",
        "min_events": 4,
        "min_trend": 0.03  # 3% market share growth
    }
)
```

**Pattern E: Cross-Domain Semantic Bridging**

Discover non-obvious connections across different entity types:

```python
def cross_domain_discovery(self, source_entity_id, target_domain, 
                          semantic_bridge_query):
    """
    Find connections between disparate domains via semantic similarity
    """
    
    # Step 1: Get source entity context
    source_context = self.graph_db.query("""
        MATCH (source {id: $source_id})
        OPTIONAL MATCH (source)-[r*1..2]-(context)
        RETURN source, collect(DISTINCT context) as context_entities
    """, source_id=source_entity_id)
    
    # Step 2: Create rich semantic representation
    source_text = self._construct_embedding_text(source_context)
    bridge_text = f"{source_text} | {semantic_bridge_query}"
    bridge_embedding = self.embed_text(bridge_text)
    
    # Step 3: Search target domain
    target_candidates = self.vector_db.query(
        vector=bridge_embedding,
        filter={"entity_type": target_domain},
        top_k=20
    )
    
    # Step 4: Validate connections via graph reasoning
    validated_connections = []
    for candidate in target_candidates['matches']:
        target_id = candidate['metadata']['entity_id']
        
        # Check if there's a logical path in graph
        connection_path = self.graph_db.query("""
            MATCH path = shortestPath(
                (source {id: $source_id})-[*1..5]-(target {id: $target_id})
            )
            RETURN path,
                   [node IN nodes(path) | labels(node)[0]] as node_types,
                   [rel IN relationships(path) | type(rel)] as rel_types,
                   length(path) as path_length
        """, source_id=source_entity_id, target_id=target_id)
        
        if connection_path:
            validated_connections.append({
                "target_entity": candidate['metadata'],
                "semantic_similarity": candidate['score'],
                "graph_path": connection_path,
                "connection_strength": (
                    candidate['score'] * 0.6 +
                    (1 / connection_path['path_length']) * 0.4
                )
            })
    
    return sorted(
        validated_connections,
        key=lambda x: x['connection_strength'],
        reverse=True
    )

# Example usage
connections = search.cross_domain_discovery(
    source_entity_id="UNMET_NEED_RA_ADHERENCE",
    target_domain="Treatment",
    semantic_bridge_query="digital health solutions for medication reminders and patient engagement"
)

# Discovers treatments in different therapeutic areas that use similar
# digital engagement strategies, validated by graph relationships
```

### 6. **Performance Optimization**

**Caching Strategy:**

```python
class HybridSearchCache:
    def __init__(self):
        self.redis_client = redis.Redis()
        self.cache_ttl = 3600  # 1 hour
    
    def cached_hybrid_search(self, query_text, filters):
        """Cache frequent hybrid queries"""
        
        # Generate cache key
        cache_key = self._generate_cache_key(query_text, filters)
        
        # Check cache
        cached_result = self.redis_client.get(cache_key)
        if cached_result:
            return json.loads(cached_result)
        
        # Execute search
        results = self.hybrid_search(query_text, filters)
        
        # Cache results
        self.redis_client.setex(
            cache_key,
            self.cache_ttl,
            json.dumps(results)
        )
        
        return results
    
    def invalidate_entity_cache(self, entity_id):
        """Invalidate cache when entity updates"""
        
        # Find all cache keys containing this entity
        pattern = f"*entity:{entity_id}*"
        keys = self.redis_client.keys(pattern)
        
        if keys:
            self.redis_client.delete(*keys)
```

**Batch Processing:**

```python
def batch_hybrid_enrichment(self, entity_ids, batch_size=100):
    """
    Efficiently enrich multiple entities with hybrid search
    """
    
    results = []
    
    for i in range(0, len(entity_ids), batch_size):
        batch = entity_ids[i:i+batch_size]
        
        # Batch fetch from graph
        graph_data = self.graph_db.query("""
            MATCH (e)
            WHERE e.id IN $entity_ids
            RETURN e.id as entity_id, e
        """, entity_ids=batch)
        
        # Batch fetch embeddings
        embedding_ids = [f"{d['e'].labels[0]}_{d['entity_id']}" 
                        for d in graph_data]
        vector_data = self.vector_db.fetch(embedding_ids)
        
        # Combine results
        for graph_item in graph_data:
            entity_id = graph_item['entity_id']
            embedding_id = f"{graph_item['e'].labels[0]}_{entity_id}"
            
            results.append({
                "entity": graph_item['e'],
                "embedding": vector_data['vectors'].get(embedding_id),
                "enriched": True
            })
    
    return results
```

---

**Would you like me to explore specific implementation details further—such as the embedding model selection and fine-tuning strategy for healthcare domain, real-time streaming architectures for continuous sync, or specific agent workflows that leverage these hybrid query patterns?** I can also discuss monitoring and observability strategies for tracking query performance and result quality across both systems.