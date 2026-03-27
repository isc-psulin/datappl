# HL7v2 ADT Models for PClean

## What this is

A PClean (Julia DSL) model for HL7v2 ADT^A08 (Patient Update) messages,
derived entirely from the HL7 v2plus specification (2021Jan edition).
No institutional data was used — all priors are uninformative/uniform.

## Model structure

```
Facility       — sending/receiving system  (from MSH segment)
Patient        — the person                (from PID + PD1 segments)
NextOfKin      — emergency contact         (from NK1 segment)
Visit          — clinical encounter        (from PV1 + PV2 segments)
InsurancePlan  — coverage info             (from IN1 segment)

ADT_A08_Record — one observed message (references all entities above,
                 with AddTypos corruption on each field)
```

PClean performs **entity resolution**: given many dirty ADT messages, it
infers that records with similar patient names, IDs, and addresses refer
to the **same latent Patient entity**, and recovers the clean values.

## File inventory

| File | Description |
|------|-------------|
| `adt_a08.jl` | PClean Julia model — 5 entity classes, 42 query columns |

## Running the model

Requires [PClean.jl](https://github.com/probcomp/PClean):

```julia
using Pkg
Pkg.add(url="https://github.com/probcomp/PClean")
include("adt_a08.jl")
```

To run inference, you need a CSV file with columns matching the query
mapping (PID_PatientName, PV1_PatientClass, etc.) — one row per message.

## What PClean cannot model

### 1. Variable-length repeating segments

Some HL7 messages have segments that repeat a variable number of times:
- NK1 (Next of Kin): 0..* per message (typically 0-3)
- IN1 (Insurance): 0..* per message (typically 0-2)
- OBX (Observations in ORU): 1-288 per message

PClean requires fixed cardinality — we model exactly 1 NK1 and 1 IN1.

### 2. Structural variants (variable field counts)

PV1 has 6 known structural variants in real data:
- 19 fields (47.4% of messages)
- 52 fields (41.0% of messages)
- 44 fields (2.3%), 45 fields (9.3%), etc.

PClean models one fixed schema.

### 3. Message-type-dependent segment composition

Different ADT event types include different segments:
- ADT^A03 (Discharge): MSH, EVN, PID, PV1, PV2
- ADT^A08 (Update): MSH, EVN, PID, PD1, NK1, PV1, PV2, IN1

This requires conditioning segment presence on message type — a structural
choice that PClean's fixed-schema model cannot express.

### 4. Cross-segment dependencies

In ORU^R01 (lab results), OBR.universal_service_id constrains which OBX
observations can appear. These cross-segment correlations require
conditional distributions that PClean's class-reference model doesn't support.

## HL7 ADT message types

This model covers ADT^A08 directly. ADT^A01 and ADT^A04 share the same
segment composition and can use this model as-is. ADT^A02 and ADT^A03
use fewer segments and would need separate models.

| Type | Event | Segments | Covered? |
|------|-------|----------|----------|
| ADT^A01 | Admit | MSH, EVN, PID, PD1, NK1, PV1, PV2, IN1 | Yes (same as A08) |
| ADT^A02 | Transfer | MSH, EVN, PID, PV1 | No |
| ADT^A03 | Discharge | MSH, EVN, PID, PV1, PV2 | No |
| ADT^A04 | Register | MSH, EVN, PID, PD1, NK1, PV1, PV2, IN1 | Yes (same as A08) |
| ADT^A08 | Update | MSH, EVN, PID, PD1, NK1, PV1, PV2, IN1 | Yes |

## Source

All field definitions, vocab tables, and data types come from:
HL7 v2plus specification, 2021Jan edition (http://www.hl7.org/implement/standards/product_brief.cfm?product_id=588)
