# HL7v2 ADT Models for PClean

## Documentation

- [HL7v2 Primer](https://isc-psulin.github.io/datappl/hl7v2-primer.html) — What HL7v2 is, how messages are structured, and why it's a data cleaning problem

## What this is

A PClean model for HL7v2 ADT^A08 (Patient Update) messages,
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

## Why ADT^A08

ADT^A08 (Patient Update) is the richest ADT message type — 8 segments
covering demographics, next of kin, visit, and insurance. ADT^A01 (Admit)
and ADT^A04 (Register) share the same segment composition, so this model
works for those too.

We chose a single message type because PClean requires a fixed schema.
It cannot model variable-length repeating segments (e.g. multiple NK1 or
IN1 per message) or condition segment presence on message type. A model
that handles multiple message types or variable repetition would require
a more expressive PPL.

## Source

All field definitions, vocab tables, and data types come from:
HL7 v2plus specification, 2021Jan edition (http://www.hl7.org/implement/standards/product_brief.cfm?product_id=588)
