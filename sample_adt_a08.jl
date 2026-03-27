# Forward-sample synthetic ADT^A08 messages from the PClean model.
#
# Generates clean entity values from the model's priors, then applies
# character-level corruption (insertions, deletions, transpositions)
# to produce dirty observed fields — the same generative process that
# PClean uses for inference, run in the forward direction.
#
# Usage:
#   julia sample_adt_a08.jl           # 10 messages to stdout
#   julia sample_adt_a08.jl 100       # 100 messages to stdout
#   julia sample_adt_a08.jl 50 out.csv

using Random

# ---------------------------------------------------------------------------
# Vocab tables from HL7 spec (same as adt_a08.jl)
# ---------------------------------------------------------------------------

const SEX = ["F", "M", "A", "N", "O", "U", "X"]
const MARITAL = ["A", "D", "M", "S", "W", "C", "P", "O", "U"]
const PATIENT_CLASS = ["E", "I", "O", "P", "R", "B", "C", "N", "U"]
const RACE = ["1002-5", "2028-9", "2054-5", "2076-8", "2106-3", "2131-1"]
const RELIGION = ["AGN","ATH","BAH","BUD","CAT","CHR","CNF","DOC","EPI","HIN","ISL","JEW","LUT","MEN","MET","MOM","MOS","NAM","OTH","PEN","PRE","PRO","QUA","SEV","UNI","UNK"]
const RELATIONSHIP = ["SEL","SPO","DOM","CHD","GCH","NCH","SCH","FCH","DEP","WRD","PAR","MTH","FTH","CGV","GRD","SIB","BRO","SIS","FND","OAD","EME","EMR","ASC","EMC","OWN","TRA","MGR","NON","UNK","OTH"]
const VERSION = ["2.3", "2.3.1", "2.4", "2.5", "2.5.1", "2.6", "2.7", "2.8", "2.9"]
const YN = ["Y", "N"]
const ETHNIC = ["H", "N", "U"]
const LIVING_DEP = ["S", "M", "CB", "D", "WU", "O", "U"]
const LIVING_ARR = ["A", "F", "I", "R", "S", "U"]
const STUDENT = ["F", "N", "P"]
const LIVING_WILL = ["F", "I", "N", "P", "U", "Y"]
const PROCESSING = ["P", "T", "D"]

# Simple name/address pools for realistic-looking strings
const LAST_NAMES = ["SMITH","JOHNSON","WILLIAMS","BROWN","JONES","GARCIA","MILLER","DAVIS","RODRIGUEZ","MARTINEZ","HERNANDEZ","LOPEZ","GONZALEZ","WILSON","ANDERSON","THOMAS","TAYLOR","MOORE","JACKSON","MARTIN"]
const FIRST_NAMES = ["JAMES","MARY","JOHN","PATRICIA","ROBERT","JENNIFER","MICHAEL","LINDA","DAVID","ELIZABETH","WILLIAM","BARBARA","RICHARD","SUSAN","JOSEPH","JESSICA","THOMAS","SARAH","CHRISTOPHER","KAREN"]
const MIDDLE = ["A","B","C","D","E","J","K","L","M","N","P","R","S","T","W"]
const STREETS = ["MAIN ST","OAK AVE","MAPLE DR","ELM ST","WASHINGTON BLVD","PARK AVE","CEDAR LN","PINE ST","LAKE RD","HILL ST"]
const CITIES = ["SPRINGFIELD","RIVERSIDE","FAIRVIEW","MADISON","GEORGETOWN","CLINTON","GREENVILLE","BRISTOL","OXFORD","SALEM"]
const STATES = ["MA","CT","NY","PA","NJ","CA","TX","FL","IL","OH"]
const FACILITIES = ["BMC","MGH","UMASS","MERCY","STVIN","HOLYOKE","COOLEY","NOBLE","WINGS","BHMC"]
const SERVICES = ["MED","SUR","OBS","PED","PSY","CAR","ONC","NEU","ORT","URO"]
const INSURERS = [("BCBS001","BLUE CROSS BLUE SHIELD"),("AETNA01","AETNA"),("UNITHC","UNITEDHEALTH"),("CIGNA01","CIGNA"),("HUMANA","HUMANA"),("MEDCR","MEDICARE"),("MEDCD","MEDICAID")]

# ---------------------------------------------------------------------------
# String corruption — mimics PClean's AddTypos
# ---------------------------------------------------------------------------

const ALPHA = collect("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

function add_typos(s::String; error_rate=0.05)
    chars = collect(s)
    result = Char[]
    for c in chars
        r = rand()
        if r < error_rate
            # Choose corruption type
            op = rand(1:4)
            if op == 1      # substitution
                push!(result, rand(ALPHA))
            elseif op == 2  # deletion
                # skip this character
            elseif op == 3  # insertion
                push!(result, c)
                push!(result, rand(ALPHA))
            else            # transposition (swap with next via double-push)
                push!(result, rand(ALPHA))
                push!(result, c)
            end
        else
            push!(result, c)
        end
    end
    String(result)
end

# ---------------------------------------------------------------------------
# Sampling helpers
# ---------------------------------------------------------------------------

pick(v) = v[rand(1:length(v))]

function random_date(year_range=1940:2005)
    y = rand(year_range)
    m = rand(1:12)
    d = rand(1:28)
    string(y, lpad(m, 2, '0'), lpad(d, 2, '0'))
end

function random_datetime()
    y = rand(2015:2025)
    m = rand(1:12)
    d = rand(1:28)
    h = rand(0:23)
    mi = rand(0:59)
    string(y, lpad(m,2,'0'), lpad(d,2,'0'), lpad(h,2,'0'), lpad(mi,2,'0'), "00")
end

random_id(prefix, len=5) = prefix * string(rand(10^(len-1):10^len - 1))
random_zip() = string(rand(10000:99999))
random_phone() = string(rand(2000000000:9999999999))
random_npi() = string(rand(1000000000:9999999999))

# ---------------------------------------------------------------------------
# Generate one ADT^A08 message (clean entities + dirty observations)
# ---------------------------------------------------------------------------

function sample_message(msg_id::Int)
    dt = random_datetime()

    # --- Clean entity values ---
    fac = pick(FACILITIES)
    last = pick(LAST_NAMES); first = pick(FIRST_NAMES); mid = pick(MIDDLE)
    patient_name = "$(last)^$(first)^$(mid)"
    patient_id = random_id("MR")
    mothers_maiden = pick(LAST_NAMES)
    dob = random_date()
    sex = pick(SEX); race = pick(RACE)
    street = "$(rand(100:9999)) $(pick(STREETS))"
    city = pick(CITIES); state = pick(STATES); zip = random_zip()
    address = "$(street)^^$(city)^$(state)^$(zip)"
    marital = pick(MARITAL); religion = pick(RELIGION)
    account = random_id("ACCT", 8)
    ethnic = pick(ETHNIC); death = pick(YN)

    living_dep = pick(LIVING_DEP); living_arr = pick(LIVING_ARR)
    primary_fac = "$(fac) PRIMARY CARE^^^^"
    student = pick(STUDENT); living_will = pick(LIVING_WILL)

    nk_last = pick(LAST_NAMES); nk_first = pick(FIRST_NAMES)
    nk_name = "$(nk_last)^$(nk_first)"
    nk_rel = pick(RELATIONSHIP)
    nk_street = "$(rand(100:9999)) $(pick(STREETS))"
    nk_address = "$(nk_street)^^$(pick(CITIES))^$(pick(STATES))^$(random_zip())"

    patient_class = pick(PATIENT_CLASS)
    location = "$(rand('A':'Z'))$(rand(1:9))^$(rand(100:999))^$(rand(1:4))^^^$(fac)"
    doc_npi = random_npi()
    doc_last = pick(LAST_NAMES); doc_first = pick(FIRST_NAMES)
    attending = "$(doc_npi)^$(doc_last)^$(doc_first)^^^^MD"
    ref_npi = random_npi()
    ref_last = pick(LAST_NAMES); ref_first = pick(FIRST_NAMES)
    referring = "$(ref_npi)^$(ref_last)^$(ref_first)^^^^MD"
    service = pick(SERVICES)
    visit_num = random_id("V", 6)
    admit_dt = random_datetime()

    ins_id, ins_name = pick(INSURERS)
    policy = random_id("POL", 8)
    version = pick(VERSION)

    # --- Build HL7 segments (dirty = typos applied) ---
    msh = "MSH|^~\\&|EPIC|$(fac)|||$(dt)||ADT^A08|MSG$(lpad(msg_id, 5, '0'))|$(pick(PROCESSING))|$(version)"
    evn = "EVN|A08|$(dt)"
    pid = "PID|1||$(add_typos(patient_id))^^^$(fac)^MR||$(add_typos(patient_name))||$(add_typos(dob))|$(add_typos(sex))|||$(add_typos(address))||||||$(add_typos(marital))|$(add_typos(religion))|$(add_typos(account))||||$(add_typos(ethnic))||||||||||||$(add_typos(death))"
    pd1 = "PD1|$(add_typos(living_dep))|$(add_typos(living_arr))|$(add_typos(primary_fac))||||$(add_typos(student))|||$(add_typos(living_will))"
    nk1 = "NK1|1|$(add_typos(nk_name))|$(add_typos(nk_rel))|$(add_typos(nk_address))"
    pv1 = "PV1|1|$(add_typos(patient_class))|$(add_typos(location))||||$(add_typos(attending))|||$(add_typos(service))||||1|||$(add_typos(referring))"
    pv2 = "PV2"
    in1 = "IN1|1||$(add_typos(ins_id))|$(add_typos(ins_name))|||||||||||$(add_typos(patient_name))|SEL|$(add_typos(dob))||||||||||||||||||$(add_typos(policy))"

    return join([msh, evn, pid, pd1, nk1, pv1, pv2, in1], "\n")
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

n = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 10
outfile = length(ARGS) >= 2 ? ARGS[2] : nothing

io = outfile !== nothing ? open(outfile, "w") : stdout

for i in 1:n
    print(io, sample_message(i))
    if i < n
        print(io, "\n\n")  # blank line between messages
    end
end

println(io)

if outfile !== nothing
    close(io)
    println(stderr, "Wrote $n messages to $outfile")
end
