# Ideas

## Image or Multimodal
- TAC images to detect inflammation. Possible comparison or pair analysis with Pathology WSI.


## FDA
- Clinical trial pairwise alignment using data from API.
- Using FSA openAPI for natural language search.

- [Measuring semantic similarity of clinical trial outcomes using deep pre-trained language representations](https://pubmed.ncbi.nlm.nih.gov/34384580/)

Comparing therapeutic regimens semantically works best when you combine a well-defined data model with ontology-backed normalization and task-appropriate similarity metrics. Here’s a practical strategy you can implement step by step.

- **Define the comparison objective**: Clarify what “similar” means for your use case. For example, regimen equivalence for safety signals, interchangeability for labeling, or similarity of optimization strategy (dose-finding logic, sequencing, de-escalation rules). Your objective determines which features and weights matter.

- **Create a structured regimen schema**: Represent each regimen as a normalized, machine-readable graph rather than free text. Include:
  - **Agents**: active ingredients normalized to RxNorm, ChEMBL, or WHO ATC.
  - **Dose**: amount, unit, per-administration vs per‑kg, dose intensity, and cumulative exposure.
  - **Schedule**: cycle length, days on/off, sequencing, overlap, run-in, maintenance phases.
  - **Route/formulation**: IV, PO, SC; immediate vs modified release.
  - **Context**: line of therapy, indication (ICD/MedDRA/OncoTree), biomarkers, performance status ranges.
  - **Optimization strategy**: design type (3+3, CRM, BOIN, mTPI, adaptive seamless), target toxicity rate, escalation rules, stopping criteria, dose-modification algorithms.
  - **Concomitants and constraints**: premedications, dose caps, organ-adjusted dosing.
  - **Outcomes for robustness**: protocol amendments related to dosing, post-approval dose changes, emergent AEs, discontinuation rates, RDI.

- **Normalize with controlled vocabularies/ontologies**: Map text to standard concepts to reduce lexical variance.
  - **Drugs**: RxNorm, ATC, ChEMBL, UNII.
  - **Indications/biomarkers**: ICD-10, SNOMED CT, MedDRA, NCIt, OncoTree.
  - **Outcomes/AEs**: CTCAE, MedDRA PT/HLT/HLGT.
  - **Trial designs**: NCIt trial design terms; custom extension for dose-escalation parameters.
  - Use entity linking with synonym dictionaries and learned NER+linking models; maintain a canonicalization layer (e.g., unit conversions, schedule normalization to a day-granularity timeline).

- **Encode regimens into comparable representations**:
  - **Graph representation**: A regimen graph where nodes are drugs, doses, time segments, and rules; edges capture sequence, overlap, and constraints. This preserves regimen structure.
  - **Feature vectors**: Hand-crafted features such as daily dose intensity per agent, cycle periodicity, combination order, proportion of overlap, target DLT rate, escalation step size, dose-modification presence, and biomarker gates.
  - **Text embeddings (optional)**: For protocol narratives, use domain-tuned embeddings (e.g., BioClinicalBERT) after extracting regimen sections, but anchor them with structured features to avoid drift.

- **Choose similarity metrics matched to representation**:
  - **Graph similarity**: Graph edit distance or Graph Neural Networks with learned similarity; faster approximations via Weisfeiler–Lehman graph kernels.
  - **Feature similarity**: Weighted cosine distance or Mahalanobis distance; learn weights from outcomes (e.g., which features predict “robustness”).
  - **Hybrid approach**: Compute both structural (graph) and semantic (feature/text) similarities, then aggregate with learned weights.

- **Account for dose/schedule comparability**:
  - Convert all doses to standardized exposure metrics (mg/m2/day or AUC equivalents where appropriate).
  - Align schedules to a canonical timeline (e.g., 28-day cycles) and compute time-series similarity (Dynamic Time Warping) for administration patterns.
  - For combinations, use set/sequence-aware metrics (e.g., Jaccard for components plus order penalties for sequencing).

- **Model robustness and task-aware weighting**:
  - Train a supervised model using historical outcomes that proxy “robustness” (e.g., fewer post-approval changes, fewer protocol dose amendments, lower discontinuation due to AEs, stable RDI). Use the learned feature importances to weight similarity.
  - Alternatively, learn a metric directly (metric learning, Siamese networks over regimen graphs) to produce a similarity score that correlates with robustness or success probability.

- **Handle uncertainty and missingness**:
  - Impute or flag missing regimen elements; propagate uncertainty into similarity (e.g., confidence-weighted features).
  - Keep provenance: source section, page, and extraction confidence for auditability.

- **Evaluation and validation**:
  - Intrinsic: cluster purity against known regimen families and design types.
  - Extrinsic: kNN retrieval quality for “find similar regimens,” correlation with shared safety/efficacy profiles, and uplift in downstream tasks (e.g., predicting dose-mod changes).

- **Implementation notes**:
  - Start with a PoC on a small, well-annotated set of protocols and labels.
  - Use a schema-first approach (JSON Schema/Protégé+OWL for ontology), a simple feature baseline, then iterate to graph models.
  - Build a curation loop where experts can up/down-vote similarities to refine weights.

If helpful, I can sketch a minimal schema and a baseline similarity function you can prototype quickly. Are you aiming to compare regimens primarily for safety robustness, efficacy likelihood, or regulatory consistency?

### References: 
Here are well-regarded references and resource types you can use to ground semantic comparison of therapeutic regimens, dose‑finding designs, and ontology-driven normalization. I’m listing them by topic so you can target what you need.

- **Dose‑finding and optimization designs (concepts and methods)**:
  - **Cheung, Y.K.**: “Dose Finding by the Continual Reassessment Method” (Book). Comprehensive treatment of CRM and model-based escalation.
  - **O’Quigley, J., Pepe, M., Fisher, L.**: Original CRM paper in Biometrika; foundational for model-based dose escalation.
  - **Liu, S., Yuan, Y.**: “Bayesian Optimal Interval (BOIN) designs for phase I trials” (Statistics in Medicine). Practical interval-based escalation; widely used.
  - **Ji, Y., Liu, P., Li, Y., Bekele, B.N.**: “Modified Toxicity Probability Interval (mTPI) design” (Clinical Trials).
  - **Ivanova, A.**: “Escalation with Overdose Control (EWOC)” papers (Biometrics; Clinical Trials).
  - **Wheeler, G.M., et al.**: “Adaptive designs for clinical trials” (Journal/Book chapters). Good overviews of seamless/adaptive frameworks.
  - **Yuan, Y., et al.**: Reviews comparing 3+3, CRM, BOIN, mTPI (Journal of Biopharmaceutical Statistics/Clinical Trials).

- **Regimen representation, dose intensity, and schedule comparability**:
  - **Hryniuk, W., Bush, H.**: “Dose intensity for chemotherapy regimens” (JNCI). Classic framework for normalizing exposure and comparing regimens.
  - **Crawford, J., et al.**: Relative dose intensity (RDI) methodology and its clinical relevance (Oncology/Hematology reviews).
  - **Ewer, M.S., et al.**: Cumulative dose and cardiotoxicity with anthracyclines/ trastuzumab (JCO/Oncologist) for exposure normalization examples.
  - **Iyer, S., et al.**: Time‑series and scheduling effects in oncology regimens (methodological papers; dose‑density concepts).

- **Ontologies and controlled vocabularies for normalization**:
  - **RxNorm** (National Library of Medicine): Standardized drug identifiers for active ingredients, strengths, and dose forms.
  - **ATC/DDD system** (WHO Collaborating Centre): Drug classification and defined daily dose metrics.
  - **NCIt (NCI Thesaurus)**: Rich ontology for cancer indications, biomarkers, and trial design terms.
  - **SNOMED CT / ICD‑10**: Clinical conditions and findings; useful for indications and comorbidity normalization.
  - **MedDRA / CTCAE**: Adverse event terminology and grading for safety outcome alignment.
  - **OncoTree**: Cancer lineage ontology used in precision oncology.

- **Information extraction and semantic modeling from protocols**:
  - **Lee, J., et al.**: BioBERT and BioClinicalBERT papers—domain language models for extracting entities from clinical text.
  - **Wadden, D., et al.**: “SciIE” / scientific information extraction frameworks (ACL/NLP venues) for relation/event extraction.
  - **Peng, Y., et al.**: Entity linking in biomedical literature (BioNLP/ACL), useful for mapping regimen narratives to ontologies.
  - **Heftings on trial documents**: Methods for extracting structured trial design from ClinicalTrials.gov/NCT PDFs (informatics journals).

- **Graph‑based and metric learning approaches for regimen similarity**:
  - **Borgwardt, K., et al.**: Graph kernels (Weisfeiler–Lehman) for structured similarity (ML journals).
  - **Ying, R., et al.**: Graph Neural Networks and representation learning (NeurIPS/ICLR tutorials) applicable to regimen graphs.
  - **Koch, G.**: Siamese networks for metric learning (vision/NLP foundations), adaptable to clinical regimen similarity tasks.
  - **Sahoo, S.S., et al.**: Ontology‑based similarity measures in biomedicine (JBI), surveying semantic similarity methods.

- **Adaptive and agentic AI in regulatory/clinical contexts**:
  - **FDA/EMA guidance on adaptive designs**: Overviews of acceptable methods and considerations for regulatory submissions.
  - **Berry, D.A.**: Bayesian adaptive trials in drug development (Clinical Trials; NEJM commentaries).
  - **Friedman, L.M., Furberg, C., DeMets, D.**: “Fundamentals of Clinical Trials” (Book) for design taxonomy and regulatory context.

- **Evaluation of robustness and post‑approval changes**:
  - **Kwakkenbos, L., et al.**: Analyses of protocol amendments and their impact (clinical trial operations literature).
  - **Downing, N.S., et al.**: Post‑approval safety label changes (JAMA/health policy) for robustness proxies.
  - **Arlett, P., et al.**: Pharmacovigilance and signal management over the product life‑cycle (Drug Safety).

To locate these quickly, use search queries like: “Bayesian Optimal Interval design Statistics in Medicine,” “Continual Reassessment Method dose finding Biometrika,” “relative dose intensity oncology Hryniuk,” “NCIt trial design ontology,” “graph kernel Weisfeiler–Lehman biomedical similarity,” and “post‑approval label changes JAMA.” If you’re focusing on a particular therapeutic area (e.g., solid tumors vs hematology), I can narrow this to more specific regimen and scheduling literature—are you targeting oncology specifically or broader therapeutic domains?
