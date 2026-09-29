# Prototype Banking Role Classifier — V5.3 Technical Model Card

**Purpose:** Demonstrate a supervised Data Science pipeline that suggests a banking role family from synthetic candidate profile evidence.

**Inputs:** skills, normalized education level, experience years/band.

**Target:** synthetic banking role class.

**Algorithms:** TF-IDF + Logistic Regression and TF-IDF + Multinomial Naive Bayes. The higher weighted-F1 pipeline is persisted.

**Evaluation:** stratified 80/20 holdout plus stratified cross-validation; accuracy, precision, recall, weighted/macro F1 and confusion matrix are persisted.

**Training-data boundary:** only the controlled synthetic Demo Bank demo cohort is used by the internal training utility. Manual or uploaded applicant records are excluded.

**Leakage controls:** `role_applied` and `department` are target/context fields and are not inserted into model feature text. Education specialization is reduced to degree level. Synthetic profiles intentionally share transferable skills across roles.

**Limitations:** results validate a prototype/classroom pipeline. They are not estimates of real-world hiring accuracy, employee potential, performance or eligibility.

**Prohibited use:** autonomous hiring, rejection, offer, employment eligibility or discriminatory decision-making.

**Human oversight:** all model suggestions are decision support only. Human People & Culture users remain responsible for decisions.

**Presentation access:** no recruiter-facing model-training/governance screen is exposed in V5.3. The classifier remains an internal technical artifact only and is not required for the core resume/JD workflow.
