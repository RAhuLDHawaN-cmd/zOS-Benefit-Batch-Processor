# z/OS Benefit Batch Processor

![COBOL Build](https://github.com/RAhuLDHawaN-cmd/zOS-Benefit-Batch-Processor/actions/workflows/build.yml/badge.svg)
![Platform](https://img.shields.io/badge/Platform-IBM%20z%2FOS-blue)
![Language](https://img.shields.io/badge/Language-COBOL%20%7C%20JCL-lightgrey)

A sample mainframe batch pipeline that reads citizen benefit claims, filters and sorts them with DFSORT, evaluates them in COBOL, and writes a report.

## How the project flows

```text
data/sample_input.txt
        │ upload with Zowe Explorer
        ▼
&SYSUID..BENEFIT.RAW.INPUT
        │ STEP01: DFSORT sorts by citizen ID and keeps active claims
        ▼
temporary dataset &&SORTED
        │ STEP02: BENEFIT reads records and applies the eligibility rule
        ├── report dataset named by OUTDD
        └── totals in the JES STEP02 SYSOUT
```

The source and copybook are compiled before the run job. The `COMPILE` job puts the runnable program in `&SYSUID..LOADLIB(BENEFIT)`; `RUNBEN` then loads the program from that library.

## Input file

`data/sample_input.txt` contains fixed-width records. Each line is 50 bytes: the fields occupy the first 20 bytes, followed by 30 spaces.

| Positions | Length | Field | Format |
| --- | ---: | --- | --- |
| 1–6 | 6 | Citizen ID | Numeric |
| 7–10 | 4 | Claim type | `EI01` or `CPP2` |
| 11–19 | 9 | Annual income | 7 integer digits and 2 implied decimal digits; no decimal point |
| 20 | 1 | Status | `A` active or `I` inactive |
| 21–50 | 30 | Filler | Spaces |

For example, `100402EI01003200000A` means citizen `100402`, claim type `EI01`, income `$32,000.00`, and active status. The record is padded to 50 bytes.

The mainframe input dataset is `&SYSUID..BENEFIT.RAW.INPUT`, allocated as `RECFM=FB,LRECL=50`.

## Processing rules

1. `RUNBEN` sorts records by citizen ID in ascending order.
2. Its SORT step passes only records with `A` in byte 20 to COBOL.
3. `BENEFIT` approves an active claim if its annual income is **below** `$45,000.00`.
4. Approved claims receive a `$1,450.00` payout. Other records passed to COBOL are marked `INELIGIBLE` with a `$0.00` payout.

Since the JCL filters inactive citizens first, inactive records are excluded from the COBOL totals. Remove the `INCLUDE COND` line in `RUNBEN` if you want COBOL to read inactive records and count them as ineligible.

## Sample citizens and expected results

The sample contains ten citizens. Eight are active and reach COBOL; five are approved and three are rejected.

| Citizen ID | Claim type | Annual income | Status | Result |
| --- | --- | ---: | --- | --- |
| 100402 | EI01 | $32,000.00 | Active | Approved |
| 100105 | CPP2 | $58,000.00 | Active | Ineligible |
| 100890 | EI01 | $21,500.00 | Inactive | Excluded by SORT |
| 100215 | EI01 | $41,000.00 | Active | Approved |
| 100020 | CPP2 | $28,500.00 | Active | Approved |
| 100335 | EI01 | $45,000.00 | Active | Ineligible (threshold is strictly below $45,000) |
| 100777 | CPP2 | $44,999.99 | Active | Approved |
| 100601 | EI01 | $36,000.00 | Inactive | Excluded by SORT |
| 100990 | CPP2 | $12,500.00 | Active | Approved |
| 100050 | EI01 | $55,000.00 | Active | Ineligible |

Expected job totals for this sample:

```text
TOTAL READ:     00008
TOTAL APPROVED: 00005
TOTAL REJECTED: 00003
```

## Mainframe datasets and members

A dataset is a file or library on z/OS. A partitioned dataset (PDS) is like a folder; its members are named files inside it. A sequential dataset stores records directly and has no members. Zowe Explorer's **Data Sets** view shows these stored files. Its **Jobs** view shows submitted work and job output.

| Dataset | Purpose | Contents |
| --- | --- | --- |
| `&SYSUID..BENEFIT.COBOL` | COBOL source library | Member `BENEFIT` |
| `&SYSUID..BENEFIT.COPY` | Copybook library | Member `CLAIMREC` |
| `&SYSUID..BENEFIT.JCL` | JCL library | Members `COMPILE` and `RUNBEN` |
| `&SYSUID..BENEFIT.RAW.INPUT` | Sequential input file | 50-byte claim records |
| `&SYSUID..LOADLIB` | Compiled program library | Load module `BENEFIT` |

`&SYSUID` is a JCL symbol for the submitting user ID. For example, for user `Z69036`, `&SYSUID..BENEFIT.RAW.INPUT` resolves to `Z69036.BENEFIT.RAW.INPUT`.

## Running with Zowe Explorer

1. **Allocate datasets:** submit `jcl/ALLOCATE.jcl`. This creates the source, copybook, JCL, input, and load libraries. A job ending in `CC 0000` completed successfully.
2. **Upload source and JCL members:** upload `cobol/BENEFIT.cbl` as member `BENEFIT`, `copybooks/CLAIMREC.cpy` as `CLAIMREC`, and `jcl/COMPILE.jcl` and `jcl/RUNBEN.jcl` as `COMPILE` and `RUNBEN` in the JCL library.
3. **Upload the input:** put `data/sample_input.txt` into the sequential dataset `&SYSUID..BENEFIT.RAW.INPUT`.
4. **Compile and link:** submit member `COMPILE`. It invokes the site's `IGYWCL` procedure, reads the COBOL source and copybook, and writes `BENEFIT` into `LOADLIB`. The compile procedure and compiler installation are site-specific.
5. **Run:** submit member `RUNBEN`. It runs SORT, then the COBOL program.
6. **Read results:** open the report dataset named by the `OUTDD` statement. Read the counts in `STEP02:SYSOUT` under the job in the Zowe **Jobs** view.

## Output

The report uses fixed-width records (`RECFM=FB,LRECL=80`) and contains a heading, separator, and one detail row per record read. Summary totals are displayed in the job's `STEP02:SYSOUT`, rather than written to the report dataset.

The report dataset name is set by `OUTDD` in `jcl/RUNBEN.jcl`. It currently uses `&SYSUID..BENEFIT.RPT2601.OUT`. Choose a fresh dataset name for each run, or remove an existing report before reusing its name. A successful earlier run used `Z69036.BENEFIT.RPT2600.OUT` with the original four-record input and reported 3 read, 2 approved, and 1 rejected.

## Project files

- `cobol/BENEFIT.cbl` — COBOL decision program
- `copybooks/CLAIMREC.cpy` — input record layout
- `data/sample_input.txt` — ten sample fixed-width claims
- `jcl/ALLOCATE.jcl` — dataset allocation job
- `jcl/COMPILE.jcl` — COBOL compile and link job
- `jcl/RUNBEN.jcl` — sort and run job
- `zapp.yaml` — Zowe tooling configuration for the local copybook library

The GitHub Actions workflow uses GnuCOBOL for a local syntax/build check. The batch job itself is designed to run under z/OS with the site's compiler, DFSORT, and dataset conventions.

