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

### Generate sample messages

`sample_adt_a08.jl` forward-samples from the model's priors and applies
character-level corruption to produce synthetic dirty messages:

```bash
julia sample_adt_a08.jl           # 10 messages to stdout
julia sample_adt_a08.jl 100       # 100 messages
julia sample_adt_a08.jl 50 out.hl7  # 50 messages to file
```

Example output (note the typos — `RODRIGGUEZ`, `CQGNA`, `CO8LEY`):

```
MSH|^~\&|EPIC|BHMC|||20180912103200||ADT^A08|MSG00001|T|2.8
EVN|A08|20180912103200
PID|1||MR39122^^^BHMC^MR||RODRIGUEZ^MICHAEL^K||195210S1I|N|||473I CEDAR LN^^SPRINGFIELD^OH^61310
PD1|S|R|BHMC PRIMARY CARE^^^^||||F|||P
NK1|1|MARTIN^THOMAS|BRO|9721 WASHINGTON BLVD^^OXFORD^NY^80080
PV1|1|P|J1^96^4^^^BHMC||||3695272602^MARTINEZ^ROBERT^^^^MD|||OBS||||1
PV2
IN1|1||HUMANA|HUMANA|||||||||||RODRIGGUEZ^MICHAEL^K|SEL|19521019
```

## Source

All field definitions, vocab tables, and data types come from:
HL7 v2plus specification, 2021Jan edition (http://www.hl7.org/implement/standards/product_brief.cfm?product_id=588)
