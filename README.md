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

The sample input contains ten citizens:

| Citizen ID | Claim type | Annual income | Status | Result in current run |
| --- | --- | ---: | --- | --- |
| 100402 | EI01 | $32,000.00 | Active | Approved |
| 100105 | CPP2 | $58,000.00 | Active | Ineligible (income threshold) |
| 100890 | EI01 | $21,500.00 | Inactive | Excluded by SORT |
| 100215 | EI01 | $41,000.00 | Active | Approved |
| 100020 | CPP2 | $28,500.00 | Active | Approved |
| 100335 | EI01 | $45,000.00 | Active | Ineligible (threshold is strictly below $45,000) |
| 100777 | CPP2 | $44,999.99 | Active | Approved |
| 100601 | EI01 | $36,000.00 | Inactive | Excluded by SORT |
| 100990 | CPP2 | $12,500.00 | Active | Approved |
| 100050 | EI01 | $55,000.00 | Active | Ineligible (income threshold) |

`RUNBEN` sorts records by citizen ID in ascending order and includes only records with `A` in byte 20. Therefore, the COBOL program reads eight of the ten sample records. To process inactive claims too, remove the `INCLUDE COND` statement from the SORT input; COBOL will then count inactive claims as ineligible.

## Processing and output

`BENEFIT` approves an active claim when annual income is below `$45,000.00`. Approved claims receive a `$1,450.00` payout. All other records passed to the program are marked `INELIGIBLE` with a `$0.00` payout.

The report dataset is allocated as fixed-width records (`RECFM=FB`, `LRECL=80`). It contains a heading, a separator, and one detail row per record read. The total read, approved, and rejected counts are written to the `STEP02` SYSOUT spool, not to the report dataset.

With the current ten-record sample, the expected summary is:

```text
TOTAL READ:     00008
TOTAL APPROVED: 00005
TOTAL REJECTED: 00003
```

The earlier successful run for user `Z69036` used the original four-record sample. Its report dataset was `Z69036.BENEFIT.RPT2600.OUT`, and its summary was:

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

## End-to-end workflow in Zowe Explorer

On z/OS, a **dataset** is a stored file or library. A partitioned dataset (PDS) works like a folder, and each **member** is a named file inside it. A sequential dataset is one file without members. In Zowe Explorer, **Data Sets** shows this stored material; **Jobs** shows work submitted to run and its spool output.

Follow the flow below to run the project:

1. **Allocate the mainframe datasets.** Submit `jcl/ALLOCATE.jcl` as a job. The `ALLOCATE` job creates the source, copybook, JCL, input, and load libraries under your user ID. `CC 0000` means allocation completed successfully.
2. **Put the source files into dataset members.** Upload `cobol/BENEFIT.cbl` to member `BENEFIT` in `Z69036.BENEFIT.COBOL`, and `copybooks/CLAIMREC.cpy` to member `CLAIMREC` in `Z69036.BENEFIT.COPY`. Upload `jcl/RUNBEN.jcl` to member `RUNBEN` in `Z69036.BENEFIT.JCL`. The raw input is a sequential dataset, so it contains records directly rather than members; copy `data/sample_input.txt` into `Z69036.BENEFIT.RAW.INPUT`.
3. **Create the compile instructions.** In Zowe Explorer, use **Create New Member** on `Z69036.BENEFIT.JCL` to create member `COMPILE`, then put the compile JCL in that member. This creates a JCL file inside the existing library.
4. **Compile the COBOL source.** Right-click the `COMPILE` member and choose **Submit Job**. z/OS runs the compiler and linker, reading `BENEFIT` and `CLAIMREC`, then places the runnable program named `BENEFIT` in `Z69036.LOADLIB`. Check the job under **Jobs**; `CC 0000` indicates the compile job succeeded.
5. **Run the batch job.** Right-click the `RUNBEN` member and choose **Submit Job**. That job runs SORT on the raw input, then runs `BENEFIT` from `LOADLIB` on the records that passed the filter.
6. **Read the results.** The detailed report is the dataset named on the `OUTDD` DD statement in `RUNBEN`. The totals appear in the `STEP02:SYSOUT` spool file under the run job in **Jobs**. With the current ten-record sample, expect 8 read, 5 approved, and 3 rejected.

Each time you choose **Submit Job**, Zowe sends the JCL to z/OS. z/OS assigns a job ID; use that job in the **Jobs** view to check its completion status and open its output.

## Project files

- `cobol/BENEFIT.cbl` — COBOL batch program
- `copybooks/CLAIMREC.cpy` — 50-byte input record definition
- `data/sample_input.txt` — sample fixed-width input records
- `jcl/RUNBEN.jcl` — sort and run job
- `jcl/ALLOCATE.jcl` — dataset allocation job
