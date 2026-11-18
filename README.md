# z/OS Benefit Batch Processor

![COBOL Build](https://github.com/<your-username>/zOS-Benefit-Batch-Processor/actions/workflows/build.yml/badge.svg)
![Platform](https://img.shields.io/badge/Platform-IBM%20z%2FOS-blue)
![Language](https://img.shields.io/badge/Language-COBOL%20%7C%20JCL-lightgrey)

An enterprise mainframe batch processing pipeline built with **COBOL**, **JCL**, and **DFSORT** on **IBM z/OS**. This project simulates an automated public-sector overnight batch cycle—similar to Employment Insurance (EI) or pension claim adjudication—that validates citizen eligibility, calculates benefit payouts, and generates formatted audit reports.

---

## Architecture & Batch Pipeline

```text
+-----------------------------------+
|  &SYSUID..BENEFIT.RAW.INPUT       |  (50-byte Fixed-Block Sequential Dataset)
+-----------------+-----------------+
                  |
                  v
+-----------------------------------+
|  STEP01: JCL DFSORT (PGM=SORT)    |  - Filters Active ('A') claims only
|                                   |  - Sorts ascending by Citizen ID
+-----------------+-----------------+
                  |  Passes temporary dataset &&SORTED (COND=(0,NE,STEP01))
                  v
+-----------------------------------+
|  STEP02: COBOL Engine             |  - Uses CLAIMREC.cpy record layout
|  (PGM=BENEFIT)                    |  - Evaluates 88-level eligibility rules
|                                   |  - Computes $1,450.00 benefit payouts
+-----------------+-----------------+
                  |
        +---------+---------+
        |                   |
        v                   v
+---------------+   +---------------+
| REPORT.OUT    |   | JES SYSOUT    |
| (80-byte FB)  |   | Summary Stats |
+---------------+   +---------------+



# Benefit Batch Processor

This project contains a COBOL batch program that reads citizen benefit claim records, sorts and filters them with DFSORT, and writes a decision report.

## Input

The input is a sequential, fixed-width dataset with `RECFM=FB` and `LRECL=50`. The JCL reads `&SYSUID..BENEFIT.RAW.INPUT`.

Each 50-byte record has this layout:

| Positions | Length | Field | Format |
| --- | ---: | --- | --- |
| 1–6 | 6 | Citizen ID | Numeric |
| 7–10 | 4 | Claim type | `EI01` or `CPP2` |
| 11–19 | 9 | Annual income | 7 integer digits followed by 2 implied decimal digits; no decimal point |
| 20 | 1 | Status | `A` active, `I` inactive |
| 21–50 | 30 | Filler | Spaces |

For example, `100402EI01003200000A` represents citizen `100402`, claim type `EI01`, income `$32,000.00`, and active status. The record is padded with 30 spaces to 50 bytes.

The sample input contains four citizens:

| Citizen ID | Claim type | Annual income | Status | Result in current run |
| --- | --- | ---: | --- | --- |
| 100402 | EI01 | $32,000.00 | Active | Approved |
| 100105 | CPP2 | $58,000.00 | Active | Ineligible (income threshold) |
| 100890 | EI01 | $21,500.00 | Inactive | Excluded by SORT |
| 100215 | EI01 | $41,000.00 | Active | Approved |

`RUNBEN` sorts records by citizen ID in ascending order and includes only records with `A` in byte 20. Therefore, the COBOL program reads three of the four sample records. To process inactive claims too, remove the `INCLUDE COND` statement from the SORT input; COBOL will then count inactive claims as ineligible.

## Processing and output

`BENEFIT` approves an active claim when annual income is below `$45,000.00`. Approved claims receive a `$1,450.00` payout. All other records passed to the program are marked `INELIGIBLE` with a `$0.00` payout.

The report dataset is allocated as fixed-width records (`RECFM=FB`, `LRECL=80`). It contains a heading, a separator, and one detail row per record read. The total read, approved, and rejected counts are written to the `STEP02` SYSOUT spool, not to the report dataset.

In the successful run for user `Z69036`, the report dataset was `Z69036.BENEFIT.RPT2600.OUT`. Its summary was:

```text
TOTAL READ:     00003
TOTAL APPROVED: 00002
TOTAL REJECTED: 00001
```

The report details were:

```text
100105 | CPP2 | INELIGIBLE | $     0.00
100215 | EI01 | APPROVED   | $ 1,450.00
100402 | EI01 | APPROVED   | $ 1,450.00
```

The output dataset name is set on the `OUTDD` DD statement in `jcl/RUNBEN.jcl`. The checked-in JCL currently specifies `&SYSUID..BENEFIT.REPORT.OUT`; the successful mainframe run used `&SYSUID..BENEFIT.RPT2600.OUT` to avoid a catalog name conflict.

## Project files

- `cobol/BENEFIT.cbl` — COBOL batch program
- `copybooks/CLAIMREC.cpy` — 50-byte input record definition
- `data/sample_input.txt` — sample fixed-width input records
- `jcl/RUNBEN.jcl` — sort and run job
- `jcl/ALLOCATE.jcl` — dataset allocation job





What this project does
Think of it as a small benefits office workflow:
1. It receives a file of citizen claims.
2. It sorts the claims and keeps active citizens.
3. It checks each claim against the income rule.
4. It produces a report showing the decisions.
The COBOL program does the decision-making. The JCL files tell the mainframe how to prepare and run the program.
The files
File	In plain terms
data/sample_input.txt	A small example of the citizen claims being processed. It contains four 50-character records.
copybooks/CLAIMREC.cpy	The form that describes each record: where the citizen ID, claim type, income, and status appear.
cobol/BENEFIT.cbl	The program that reads claims and decides whether each one is approved or ineligible.
jcl/ALLOCATE.jcl	One-time setup instructions that created the mainframe datasets, which act like named file containers.
jcl/RUNBEN.jcl	The instructions to sort the input, run BENEFIT, and save the report.
README.md	A plain-language reference for the input format and output.
zapp.yaml	Zowe tooling configuration, including where the copybook is located for development.


You also created a COMPILE JCL member on the mainframe. It compiled the COBOL source and put the runnable program in Z69036.LOADLIB.
What’s in each citizen record
Each record has a citizen ID, a claim type, an annual income, and a status. For example, A means active and I means inactive. The income is stored as digits without a decimal point: 003200000 means $32,000.00. Extra spaces fill the record to 50 characters.
The decision rules
- The JCL sorts claims by citizen ID and passes only active (A) records to the COBOL program.
- COBOL approves an active claim if the income is below $45,000.00.
- An approved claim receives a $1,450.00 payout.
- Other claims that reach COBOL are marked ineligible, with no payout.
Since the JCL filters out inactive citizens first, inactive claims aren’t counted in the current report.
What happened in your successful run
The sample file had four citizens. SORT removed the one inactive record, so COBOL read three:
- 2 approved
- 1 ineligible
- 3 total read
The detailed report is in Z69036.BENEFIT.RPT2600.OUT. The totals appeared separately in the STEP02:SYSOUT job output.

One detail for future runs: the successful mainframe JCL used RPT2600.OUT because the original output name had a catalog conflict. The local jcl/RUNBEN.jcl still names REPORT.OUT, so update that line if you want the local JCL to match the version that ran successfully.
