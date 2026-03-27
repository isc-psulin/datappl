# HL7v2 ADT Models

## Documentation

- [HL7v2 Primer](https://isc-psulin.github.io/datappl/hl7v2-primer.html) — What HL7v2 is, how messages are structured, and why it's a data cleaning problem

## ADT^A08 — Patient Update

A sample Pluck probabilistic model for ADT^A08 messages, illustrating what
the intended model structure would look like. Derived entirely from the
HL7 v2plus specification (2021Jan edition) — no institutional data was used.

ADT^A08 is a patient demographic update message. For background on HL7v2 message structure, see the
[HL7v2 Primer](https://isc-psulin.github.io/datappl/hl7v2-primer.html).

### Segments

| Segment | Name | Cardinality | Fields |
|---------|------|-------------|--------|
| MSH | Message Header | 1 | Sending application, sending facility, timestamp, message type, version |
| EVN | Event Type | 1 | Event code, recorded timestamp |
| PID | Patient Identification | 1 | Patient ID, name, DOB, sex, race, address, marital status, ethnic group, death indicator |
| NK1 | Next of Kin | 0..* | Name, relationship, address |
| PV1 | Patient Visit | 1 | Patient class, location, attending doctor, hospital service |
| IN1 | Insurance | 0..* | Plan ID, company name, policy number |


## Source

All field definitions, vocab tables, and data types come from:
HL7 v2plus specification, 2021Jan edition (http://www.hl7.org/implement/standards/product_brief.cfm?product_id=588)
