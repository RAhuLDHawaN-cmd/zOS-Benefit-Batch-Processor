# z/OS Citizen Benefit Batch Processor

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
