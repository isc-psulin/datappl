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

`sample_adt_a08.jl` generates synthetic ADT^A08 messages. Coded fields
(sex, race, patient class, etc.) are sampled from the HL7 spec code tables.
String fields (names, addresses) use placeholder pools.

```bash
julia sample_adt_a08.jl           # 10 messages to stdout
julia sample_adt_a08.jl 100       # 100 messages
julia sample_adt_a08.jl 50 out.hl7  # 50 messages to file
```

Example output:

```
MSH|^~\&|EPIC|BMC|||20190222110300||ADT^A08|MSG00001|D|2.3
EVN|A08|20190222110300
PID|1||MR71120^^^BMC^MR||DAVIS^RICHARD^E||19641103|O|||3028 ELM ST^^BRISTOL^PA^93628||||||O|AGN|ACCT36671057||||U||||||||||||N
PD1|U|F|BMC PRIMARY CARE^^^^||||P|||I
NK1|1|MARTINEZ^ROBERT|SEL|4089 CEDAR LN^^MADISON^OH^15987
PV1|1|C|M4^705^4^^^BMC||||1175407672^WILLIAMS^SARAH^^^^MD|||PSY||||1|||7222801419^MILLER^SUSAN^^^^MD
PV2
IN1|1||UNITHC|UNITEDHEALTH|||||||||||DAVIS^RICHARD^E|SEL|19641103||||||||||||||||||POL71848158
```

## Source

All field definitions, vocab tables, and data types come from:
HL7 v2plus specification, 2021Jan edition (http://www.hl7.org/implement/standards/product_brief.cfm?product_id=588)
