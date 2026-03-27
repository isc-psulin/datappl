# PClean model for HL7v2 ADT^A08 (Patient Update) messages
#
# Source: HL7 v2plus specification (2021Jan edition)
# This model uses ONLY spec-derived priors — no institutional data.
#
# ADT^A08 segment composition:
#   MSH (Message Header)      — always present, 1 per message
#   EVN (Event Type)           — always present, 1 per message
#   PID (Patient ID)           — always present, 1 per message
#   PD1 (Patient Demographics) — optional, 0..1 per message
#   NK1 (Next of Kin)          — optional, 0..* per message (PClean limitation: modeled as 0..1)
#   PV1 (Patient Visit)        — always present, 1 per message
#   PV2 (Visit - Additional)   — optional, 0..1 per message
#   IN1 (Insurance)            — optional, 0..* per message (PClean limitation: modeled as 0..1)
#
# PClean limitations demonstrated by this model:
#   1. No variable-length repeats — NK1 and IN1 can repeat in real HL7 but
#      PClean requires fixed cardinality. We model at most 1 of each.
#   2. No optional segments — PClean has no "maybe present" construct.
#      Optional segments are modeled with empty-string defaults.
#   3. No structural variants — PV1 has 6 known field-count variants in real
#      data (19, 39, 44, 45, 49, 52 fields). PClean models one fixed schema.
#
# These limitations are exactly where PLUCK (recursive ADTs, geometric
# distributions over list length) would provide a better fit.
#
# Entity structure:
#   Facility       — the sending/receiving system (from MSH)
#   Patient        — the person (from PID, PD1)
#   NextOfKin      — emergency contact (from NK1)
#   Visit          — the clinical encounter (from PV1, PV2)
#   InsurancePlan  — coverage info (from IN1)
#   Event          — what triggered this message (from EVN)
#   ADT_A08_Record — the observed (potentially dirty) message

using PClean

# --- Data loading would go here ---
# In practice: load a CSV where each row is one flattened ADT^A08 message
# with columns matching the query mapping at the bottom of this file.
#
# Example:
#   include("load_adt_data.jl")
#
# For now we define the possibilities arrays from the HL7 spec vocab tables.

# HL7 Table 0001: Administrative Sex
possibilities_sex = ["F", "M", "A", "N", "O", "U", "X"]

# HL7 Table 0002: Marital Status
possibilities_marital = ["A", "D", "M", "S", "W", "C", "P", "O", "U"]

# HL7 Table 0003: Event Type Code (subset — ADT events)
possibilities_event_type = [
    "A01", "A02", "A03", "A04", "A05", "A06", "A07", "A08",
    "A09", "A10", "A11", "A12", "A13", "A14", "A15", "A16",
    "A17", "A18", "A19", "A20", "A21", "A22", "A23", "A24",
    "A25", "A26", "A27", "A28", "A29", "A30", "A31", "A34",
    "A35", "A36", "A37", "A38", "A40", "A41", "A42", "A43",
    "A44", "A45", "A46", "A47", "A48", "A49", "A50", "A51"
]

# HL7 Table 0004: Patient Class
possibilities_patient_class = [
    "E",   # Emergency
    "I",   # Inpatient
    "O",   # Outpatient
    "P",   # Preadmit
    "R",   # Recurring patient
    "B",   # Obstetrics
    "C",   # Commercial account
    "N",   # Not applicable
    "U"    # Unknown
]

# HL7 Table 0005: Race
possibilities_race = ["1002-5", "2028-9", "2054-5", "2076-8", "2106-3", "2131-1"]

# HL7 Table 0006: Religion (abbreviated — full table has ~200 codes)
possibilities_religion = [
    "AGN", "ATH", "BAH", "BUD", "CAT", "CHR", "CNF", "DOC",
    "EPI", "HIN", "ISL", "JEW", "LUT", "MEN", "MET", "MOM",
    "MOS", "NAM", "OTH", "PEN", "PRE", "PRO", "QUA", "SEV",
    "UNI", "UNK"
]

# HL7 Table 0063: Relationship (subset)
possibilities_relationship = [
    "SEL", "SPO", "DOM", "CHD", "GCH", "NCH", "SCH", "FCH",
    "DEP", "WRD", "PAR", "MTH", "FTH", "CGV", "GRD", "SIB",
    "BRO", "SIS", "FND", "OAD", "EME", "EMR", "ASC", "EMC",
    "OWN", "TRA", "MGR", "NON", "UNK", "OTH"
]

# HL7 Table 0104: Version ID
possibilities_version = [
    "2.1", "2.2", "2.3", "2.3.1", "2.4", "2.5", "2.5.1",
    "2.6", "2.7", "2.7.1", "2.8", "2.8.1", "2.8.2", "2.9"
]

# HL7 Table 0136: Yes/No
possibilities_yn = ["Y", "N"]

# HL7 Table 0189: Ethnic Group
possibilities_ethnic = ["H", "N", "U"]

# HL7 Table 0215: Publicity Code
possibilities_publicity = ["F", "N", "O", "U"]

# HL7 Table 0223: Living Dependency
possibilities_living_dep = ["S", "M", "CB", "D", "WU", "O", "U"]

# HL7 Table 0220: Living Arrangement
possibilities_living_arr = ["A", "F", "I", "R", "S", "U"]

# HL7 Table 0231: Student Indicator
possibilities_student = ["F", "N", "P"]

# HL7 Table 0315: Living Will Code
possibilities_living_will = ["F", "I", "N", "P", "U", "Y"]

# HL7 Table 0103: Processing ID
possibilities_processing = ["P", "T", "D"]


# ===========================================================================
# MODEL DEFINITION
# ===========================================================================

PClean.@model ADT_A08_Model begin

    # -------------------------------------------------------------------
    # Facility: the sending/receiving healthcare system (from MSH)
    # -------------------------------------------------------------------
    @class Facility begin
        name        ~ StringPrior(1, 50, possibilities_sex)   # HD composite
        namespace   ~ StringPrior(1, 50, possibilities_sex)   # HD namespace ID
    end;

    # -------------------------------------------------------------------
    # Patient: the person this message is about (from PID)
    # -------------------------------------------------------------------
    @class Patient begin
        # PID-3: Patient Identifier List (CX composite)
        patient_id           ~ StringPrior(1, 50, possibilities_sex)

        # PID-5: Patient Name (XPN composite — last^first^middle)
        patient_name         ~ StringPrior(1, 80, possibilities_sex)

        # PID-6: Mother's Maiden Name
        mothers_maiden_name  ~ StringPrior(0, 50, possibilities_sex)

        # PID-7: Date/Time of Birth (DTM — YYYYMMDD or YYYYMMDDHHmmss)
        date_of_birth        ~ StringPrior(0, 14, possibilities_sex)

        # PID-8: Administrative Sex
        sex                  ~ ChooseUniformly(possibilities_sex)

        # PID-10: Race
        race                 ~ ChooseUniformly(possibilities_race)

        # PID-11: Patient Address (XAD composite)
        address              ~ StringPrior(0, 100, possibilities_sex)

        # PID-16: Marital Status
        marital_status       ~ ChooseUniformly(possibilities_marital)

        # PID-17: Religion
        religion             ~ ChooseUniformly(possibilities_religion)

        # PID-18: Patient Account Number
        account_number       ~ StringPrior(0, 50, possibilities_sex)

        # PID-22: Ethnic Group
        ethnic_group         ~ ChooseUniformly(possibilities_ethnic)

        # PID-30: Patient Death Indicator
        death_indicator      ~ ChooseUniformly(possibilities_yn)

        # PD1-1: Living Dependency
        living_dependency    ~ ChooseUniformly(possibilities_living_dep)

        # PD1-2: Living Arrangement
        living_arrangement   ~ ChooseUniformly(possibilities_living_arr)

        # PD1-3: Patient Primary Facility (XON)
        primary_facility     ~ StringPrior(0, 50, possibilities_sex)

        # PD1-5: Student Indicator
        student_indicator    ~ ChooseUniformly(possibilities_student)

        # PD1-7: Living Will Code
        living_will          ~ ChooseUniformly(possibilities_living_will)
    end;

    # -------------------------------------------------------------------
    # NextOfKin: emergency contact / next of kin (from NK1)
    # Note: NK1 can repeat [0..*] in real HL7 — PClean models exactly 1.
    # -------------------------------------------------------------------
    @class NextOfKin begin
        # NK1-2: Name (XPN)
        nk_name              ~ StringPrior(0, 80, possibilities_sex)

        # NK1-3: Relationship
        relationship         ~ ChooseUniformly(possibilities_relationship)

        # NK1-4: Address (XAD)
        nk_address           ~ StringPrior(0, 100, possibilities_sex)

        # NK1-7: Contact Role
        contact_role         ~ ChooseUniformly(possibilities_relationship)
    end;

    # -------------------------------------------------------------------
    # Visit: the clinical encounter (from PV1, PV2)
    # PV1 has up to 52 fields with 6 structural variants (19/39/44/45/49/52
    # fields). PClean cannot model this structural variation — all fields
    # are included with the understanding that trailing fields may be empty.
    # -------------------------------------------------------------------
    @class Visit begin
        # PV1-2: Patient Class
        patient_class        ~ ChooseUniformly(possibilities_patient_class)

        # PV1-3: Assigned Patient Location (PL composite)
        assigned_location    ~ StringPrior(0, 80, possibilities_sex)

        # PV1-4: Admission Type (CWE)
        admission_type       ~ StringPrior(0, 20, possibilities_sex)

        # PV1-7: Attending Doctor (XCN composite)
        attending_doctor     ~ StringPrior(0, 80, possibilities_sex)

        # PV1-8: Referring Doctor (XCN composite)
        referring_doctor     ~ StringPrior(0, 80, possibilities_sex)

        # PV1-10: Hospital Service (CWE)
        hospital_service     ~ StringPrior(0, 20, possibilities_sex)

        # PV1-14: Admit Source (CWE)
        admit_source         ~ StringPrior(0, 20, possibilities_sex)

        # PV1-18: Patient Type (CWE)
        patient_type         ~ StringPrior(0, 20, possibilities_sex)

        # PV1-19: Visit Number (CX)
        visit_number         ~ StringPrior(0, 50, possibilities_sex)

        # PV1-36: Discharge Disposition (CWE)
        discharge_disposition ~ StringPrior(0, 20, possibilities_sex)

        # PV1-44: Admit Date/Time (DTM)
        admit_datetime       ~ StringPrior(0, 14, possibilities_sex)

        # PV1-45: Discharge Date/Time (DTM)
        discharge_datetime   ~ StringPrior(0, 14, possibilities_sex)

        # PV2-3: Admit Reason (CWE)
        admit_reason         ~ StringPrior(0, 50, possibilities_sex)

        # PV2-33: Expected Surgery Date (DTM)
        expected_surgery     ~ StringPrior(0, 14, possibilities_sex)
    end;

    # -------------------------------------------------------------------
    # InsurancePlan: coverage information (from IN1)
    # Note: IN1 can repeat [0..*] — PClean models exactly 1.
    # -------------------------------------------------------------------
    @class InsurancePlan begin
        # IN1-2: Health Plan ID
        plan_id              ~ StringPrior(0, 20, possibilities_sex)

        # IN1-3: Insurance Company ID (CX)
        company_id           ~ StringPrior(1, 50, possibilities_sex)

        # IN1-4: Insurance Company Name (XON)
        company_name         ~ StringPrior(0, 80, possibilities_sex)

        # IN1-16: Name of Insured (XPN)
        insured_name         ~ StringPrior(0, 80, possibilities_sex)

        # IN1-36: Policy Number
        policy_number        ~ StringPrior(0, 30, possibilities_sex)
    end;

    # -------------------------------------------------------------------
    # ADT_A08_Record: the observed message (one row per ADT^A08 message)
    #
    # Each field is observed as a potentially corrupted version of the
    # corresponding clean entity attribute. AddTypos models character-level
    # corruption (insertions, deletions, substitutions, transpositions).
    #
    # This is where PClean's power shows: given a dirty message, it infers
    # the most likely clean entity values AND performs entity resolution
    # (linking multiple dirty records to the same latent Patient/Visit).
    # -------------------------------------------------------------------
    @class ADT_A08_Record begin
        # --- Block 1: Message header + Event (always present) ---
        begin
            # MSH fields (metadata — typically trusted/guaranteed)
            @guaranteed msh_version
            msh_version          ~ ChooseUniformly(possibilities_version)
            msh_processing_id    ~ ChooseUniformly(possibilities_processing)
            msh_datetime         ~ StringPrior(8, 14, possibilities_sex)

            # EVN fields
            evn_event_type       ~ ChooseUniformly(possibilities_event_type)
            evn_recorded_dt      ~ StringPrior(0, 14, possibilities_sex)
        end

        # --- Block 2: Patient identification (core of entity resolution) ---
        begin
            patient              ~ Patient

            # Observed (potentially dirty) versions of patient attributes
            pid_patient_id       ~ AddTypos(patient.patient_id)
            pid_patient_name     ~ AddTypos(patient.patient_name)
            pid_mothers_maiden   ~ AddTypos(patient.mothers_maiden_name)
            pid_dob              ~ AddTypos(patient.date_of_birth)
            pid_sex              ~ AddTypos(patient.sex)
            pid_race             ~ AddTypos(patient.race)
            pid_address          ~ AddTypos(patient.address)
            pid_marital          ~ AddTypos(patient.marital_status)
            pid_religion         ~ AddTypos(patient.religion)
            pid_account          ~ AddTypos(patient.account_number)
            pid_ethnic           ~ AddTypos(patient.ethnic_group)
            pid_death            ~ AddTypos(patient.death_indicator)

            # PD1 fields (additional demographics, same Patient entity)
            pd1_living_dep       ~ AddTypos(patient.living_dependency)
            pd1_living_arr       ~ AddTypos(patient.living_arrangement)
            pd1_primary_fac      ~ AddTypos(patient.primary_facility)
            pd1_student          ~ AddTypos(patient.student_indicator)
            pd1_living_will      ~ AddTypos(patient.living_will)
        end

        # --- Block 3: Next of kin ---
        begin
            nk                   ~ NextOfKin
            nk1_name             ~ AddTypos(nk.nk_name)
            nk1_relationship     ~ AddTypos(nk.relationship)
            nk1_address          ~ AddTypos(nk.nk_address)
            nk1_contact_role     ~ AddTypos(nk.contact_role)
        end

        # --- Block 4: Visit information ---
        begin
            visit                ~ Visit
            pv1_patient_class    ~ AddTypos(visit.patient_class)
            pv1_location         ~ AddTypos(visit.assigned_location)
            pv1_admission_type   ~ AddTypos(visit.admission_type)
            pv1_attending_doc    ~ AddTypos(visit.attending_doctor)
            pv1_referring_doc    ~ AddTypos(visit.referring_doctor)
            pv1_hospital_svc     ~ AddTypos(visit.hospital_service)
            pv1_admit_source     ~ AddTypos(visit.admit_source)
            pv1_patient_type     ~ AddTypos(visit.patient_type)
            pv1_visit_number     ~ AddTypos(visit.visit_number)
            pv1_discharge_disp   ~ AddTypos(visit.discharge_disposition)
            pv1_admit_dt         ~ AddTypos(visit.admit_datetime)
            pv1_discharge_dt     ~ AddTypos(visit.discharge_datetime)
            pv2_admit_reason     ~ AddTypos(visit.admit_reason)
            pv2_surgery_dt       ~ AddTypos(visit.expected_surgery)
        end

        # --- Block 5: Insurance ---
        begin
            insurance            ~ InsurancePlan
            in1_plan_id          ~ AddTypos(insurance.plan_id)
            in1_company_id       ~ AddTypos(insurance.company_id)
            in1_company_name     ~ AddTypos(insurance.company_name)
            in1_insured_name     ~ AddTypos(insurance.insured_name)
            in1_policy_number    ~ AddTypos(insurance.policy_number)
        end
    end;
end;

# ===========================================================================
# QUERY: maps CSV column names to clean/dirty attribute paths
# ===========================================================================

query = @query ADT_A08_Model.ADT_A08_Record [
    # Column              Clean path                      Dirty path
    # --- MSH / EVN (trusted metadata) ---
    MSH_VersionID         msh_version                     msh_version
    MSH_ProcessingID      msh_processing_id               msh_processing_id
    MSH_DateTime          msh_datetime                    msh_datetime
    EVN_EventType         evn_event_type                  evn_event_type
    EVN_RecordedDT        evn_recorded_dt                 evn_recorded_dt

    # --- PID (patient identification — core entity resolution target) ---
    PID_PatientID         patient.patient_id              pid_patient_id
    PID_PatientName       patient.patient_name            pid_patient_name
    PID_MothersMaiden     patient.mothers_maiden_name     pid_mothers_maiden
    PID_DOB               patient.date_of_birth           pid_dob
    PID_Sex               patient.sex                     pid_sex
    PID_Race              patient.race                    pid_race
    PID_Address           patient.address                 pid_address
    PID_MaritalStatus     patient.marital_status          pid_marital
    PID_Religion          patient.religion                pid_religion
    PID_AccountNumber     patient.account_number          pid_account
    PID_EthnicGroup       patient.ethnic_group            pid_ethnic
    PID_DeathIndicator    patient.death_indicator         pid_death

    # --- PD1 (additional demographics) ---
    PD1_LivingDep         patient.living_dependency       pd1_living_dep
    PD1_LivingArr         patient.living_arrangement      pd1_living_arr
    PD1_PrimaryFacility   patient.primary_facility        pd1_primary_fac
    PD1_Student           patient.student_indicator       pd1_student
    PD1_LivingWill        patient.living_will             pd1_living_will

    # --- NK1 (next of kin) ---
    NK1_Name              nk.nk_name                      nk1_name
    NK1_Relationship      nk.relationship                 nk1_relationship
    NK1_Address           nk.nk_address                   nk1_address
    NK1_ContactRole       nk.contact_role                 nk1_contact_role

    # --- PV1 (patient visit) ---
    PV1_PatientClass      visit.patient_class             pv1_patient_class
    PV1_Location          visit.assigned_location         pv1_location
    PV1_AdmissionType     visit.admission_type            pv1_admission_type
    PV1_AttendingDoc      visit.attending_doctor           pv1_attending_doc
    PV1_ReferringDoc      visit.referring_doctor           pv1_referring_doc
    PV1_HospitalService   visit.hospital_service          pv1_hospital_svc
    PV1_AdmitSource       visit.admit_source              pv1_admit_source
    PV1_PatientType       visit.patient_type              pv1_patient_type
    PV1_VisitNumber       visit.visit_number              pv1_visit_number
    PV1_DischargeDisp     visit.discharge_disposition     pv1_discharge_disp
    PV1_AdmitDT           visit.admit_datetime            pv1_admit_dt
    PV1_DischargeDT       visit.discharge_datetime        pv1_discharge_dt

    # --- PV2 (additional visit) ---
    PV2_AdmitReason       visit.admit_reason              pv2_admit_reason
    PV2_SurgeryDT         visit.expected_surgery          pv2_surgery_dt

    # --- IN1 (insurance) ---
    IN1_PlanID            insurance.plan_id               in1_plan_id
    IN1_CompanyID         insurance.company_id            in1_company_id
    IN1_CompanyName       insurance.company_name          in1_company_name
    IN1_InsuredName       insurance.insured_name          in1_insured_name
    IN1_PolicyNumber      insurance.policy_number         in1_policy_number
];

# ===========================================================================
# INFERENCE
# ===========================================================================

# config = PClean.InferenceConfig(1, 2; use_mh_instead_of_pg=true);
# observations = [ObservedDataset(query, dirty_table)];
# @time begin
#     trace = initialize_trace(observations, config);
#     run_inference!(trace, config);
# end
#
# results = evaluate_accuracy(dirty_table, clean_table, trace.tables[:ADT_A08_Record], query)
# PClean.save_results("results", "adt_a08", trace, observations)
# println(results)
