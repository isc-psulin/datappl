# HL7v2 ADT Models for PClean

## Documentation

- [HL7v2 Primer](https://isc-psulin.github.io/datappl/hl7v2-primer.html) — What HL7v2 is, how messages are structured, and why it's a data cleaning problem

## ADT^A08 — Patient Update

A PClean model for ADT^A08 messages, derived entirely from the
HL7 v2plus specification (2021Jan edition). No institutional data was
used — all priors are spec-derived.

ADT^A08 is a patient demographic update message. It has a fixed set of
8 segments, which fits PClean's fixed-schema requirement. ADT^A01 (Admit)
and ADT^A04 (Register) share the same segment composition, so the model
works for those too.

For background on HL7v2 message structure, see the
[HL7v2 Primer](https://isc-psulin.github.io/datappl/hl7v2-primer.html).

### Segments

| Segment | Name | Fields |
|---------|------|--------|
| MSH | Message Header | Sending application, sending facility, timestamp, message type, version |
| EVN | Event Type | Event code, recorded timestamp |
| PID | Patient Identification | Patient ID, name, mother's maiden name, DOB, sex, race, address, marital status, religion, account number, ethnic group, death indicator |
| PD1 | Patient Demographics | Living dependency, living arrangement, primary facility, student indicator, living will |
| NK1 | Next of Kin | Name, relationship, address, contact role |
| PV1 | Patient Visit | Patient class, location, admission type, attending doctor, referring doctor, hospital service, admit source, patient type, visit number, discharge disposition, admit/discharge dates |
| PV2 | Patient Visit (add'l) | Admit reason, expected surgery date |
| IN1 | Insurance | Plan ID, company ID, company name, insured name, policy number |


## Source

All field definitions, vocab tables, and data types come from:
HL7 v2plus specification, 2021Jan edition (http://www.hl7.org/implement/standards/product_brief.cfm?product_id=588)
