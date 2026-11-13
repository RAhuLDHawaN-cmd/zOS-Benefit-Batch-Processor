******************************************************************
      * COPYBOOK: CLAIMREC - CITIZEN BENEFIT CLAIM RECORD (50 BYTES)   *
      ******************************************************************
       01  CLAIM-RECORD.
           05 CR-CITIZEN-ID          PIC 9(06).
           05 CR-CLAIM-TYPE          PIC X(04).
              88 TYPE-EI             VALUE 'EI01'.
              88 TYPE-CPP            VALUE 'CPP2'.
           05 CR-ANNUAL-INCOME       PIC 9(07)V99.
           05 CR-STATUS              PIC X(01).
              88 STATUS-ACTIVE       VALUE 'A'.
              88 STATUS-INACTIVE     VALUE 'I'.
           05 FILLER                 PIC X(30).