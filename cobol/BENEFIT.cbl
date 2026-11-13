IDENTIFICATION DIVISION.
       PROGRAM-ID. BENEFIT.
       AUTHOR. RAHUL DHAWAN.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CLAIM-IN   ASSIGN TO INDD.
           SELECT REPORT-OUT ASSIGN TO OUTDD.

       DATA DIVISION.
       FILE SECTION.
       FD  CLAIM-IN
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       COPY CLAIMREC.

       FD  REPORT-OUT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  REPORT-LINE               PIC X(80).

       WORKING-STORAGE SECTION.
       01  WS-FLAGS.
           05 WS-EOF                 PIC X(01) VALUE 'N'.
              88 END-OF-FILE         VALUE 'Y'.

       01  WS-COUNTERS.
           05 WS-READ-CNT            PIC 9(05) VALUE ZERO.
           05 WS-APPROVED-CNT        PIC 9(05) VALUE ZERO.
           05 WS-REJECTED-CNT        PIC 9(05) VALUE ZERO.
           05 WS-PAYOUT-AMT          PIC 9(05)V99 VALUE ZERO.

       01  WS-OUT-DETAIL.
           05 OUT-ID                 PIC 9(06).
           05 FILLER                 PIC X(03) VALUE ' | '.
           05 OUT-TYPE               PIC X(04).
           05 FILLER                 PIC X(03) VALUE ' | '.
           05 OUT-DECISION           PIC X(10).
           05 FILLER                 PIC X(03) VALUE ' | $'.
           05 OUT-PAYOUT             PIC ZZ,ZZ9.99.
           05 FILLER                 PIC X(42) VALUE SPACES.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT  CLAIM-IN
                OUTPUT REPORT-OUT.

           PERFORM 1000-WRITE-HEADER.

           PERFORM UNTIL END-OF-FILE
               READ CLAIM-IN
                   AT END
                       SET END-OF-FILE TO TRUE
                   NOT AT END
                       ADD 1 TO WS-READ-CNT
                       PERFORM 2000-PROCESS-CLAIM
               END-READ
           END-PERFORM.

           PERFORM 3000-WRITE-SUMMARY.
           CLOSE CLAIM-IN REPORT-OUT.
           STOP RUN.

       1000-WRITE-HEADER.
           MOVE "CITIZEN ID | TYPE | DECISION   | PAYOUT AMOUNT"
             TO REPORT-LINE.
           WRITE REPORT-LINE.
           MOVE ALL "-" TO REPORT-LINE.
           WRITE REPORT-LINE.

       2000-PROCESS-CLAIM.
           MOVE CR-CITIZEN-ID TO OUT-ID.
           MOVE CR-CLAIM-TYPE TO OUT-TYPE.

           IF STATUS-ACTIVE AND CR-ANNUAL-INCOME < 45000.00
               MOVE "APPROVED" TO OUT-DECISION
               COMPUTE WS-PAYOUT-AMT = 1450.00
               ADD 1 TO WS-APPROVED-CNT
           ELSE
               MOVE "INELIGIBLE" TO OUT-DECISION
               MOVE ZERO TO WS-PAYOUT-AMT
               ADD 1 TO WS-REJECTED-CNT
           END-IF.

           MOVE WS-PAYOUT-AMT TO OUT-PAYOUT.
           MOVE WS-OUT-DETAIL TO REPORT-LINE.
           WRITE REPORT-LINE.

       3000-WRITE-SUMMARY.
           MOVE SPACES TO REPORT-LINE.
           WRITE REPORT-LINE.
           DISPLAY "TOTAL READ:     " WS-READ-CNT.
           DISPLAY "TOTAL APPROVED: " WS-APPROVED-CNT.
           DISPLAY "TOTAL REJECTED: " WS-REJECTED-CNT.