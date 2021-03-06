
  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_455142_177_1" as object (GAL_BUDGET_LINE_ID NUMBER(12),
GAL_BUDGET_ID NUMBER(12),
GAL_COST_CENTER_ID NUMBER(12),
BLI_SEQUENCE NUMBER(12),
BLI_WORDING VARCHAR2(60 CHAR),
BLI_BUDGET_QUANTITY NUMBER(14,2),
BLI_BUDGET_PRICE NUMBER(14,2),
BLI_BUDGET_AMOUNT NUMBER(14,2),
BLI_REMAINING_QUANTITY NUMBER(14,2),
BLI_REMAINING_PRICE NUMBER(14,2),
BLI_REMAINING_AMOUNT NUMBER(14,2),
BLI_HANGING_SPENDING_QUANTITY NUMBER(14,2),
BLI_HANGING_SPENDING_AMOUNT NUMBER(14,2),
BLI_DESCRIPTION VARCHAR2(4000 CHAR),
BLI_COMMENT VARCHAR2(4000 CHAR),
A_IDCRE VARCHAR2(5 CHAR),
A_DATECRE DATE,
A_IDMOD VARCHAR2(5 CHAR),
A_DATEMOD DATE,
BLI_LAST_BUDGET_DATE DATE,
BLI_LAST_REMAINING_DATE DATE,
BLI_LAST_ESTIMATION_QUANTITY NUMBER(14,2),
BLI_LAST_ESTIMATION_AMOUNT NUMBER(14,2));


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_455142_DUMMY_1" as table of number;


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_455275_469_1" as object (GAL_TASK_LINK_ID NUMBER(12),
GAL_TASK_ID NUMBER(12),
C_TAL_STATE VARCHAR2(10 CHAR),
C_RELATION_TYPE VARCHAR2(10 CHAR),
PPS_OPERATION_PROCEDURE_ID NUMBER(12),
PPS_PPS_OPERATION_PROCEDURE_ID NUMBER(12),
FAL_TASK_ID NUMBER(12),
FAL_FACTORY_FLOOR_ID NUMBER(12),
FAL_FAL_FACTORY_FLOOR_ID NUMBER(12),
PPS_TOOLS1_ID NUMBER(12),
PPS_TOOLS2_ID NUMBER(12),
PPS_TOOLS3_ID NUMBER(12),
PPS_TOOLS4_ID NUMBER(12),
PPS_TOOLS5_ID NUMBER(12),
PPS_TOOLS6_ID NUMBER(12),
PPS_TOOLS7_ID NUMBER(12),
PPS_TOOLS8_ID NUMBER(12),
PPS_TOOLS9_ID NUMBER(12),
PPS_TOOLS10_ID NUMBER(12),
PPS_TOOLS11_ID NUMBER(12),
PPS_TOOLS12_ID NUMBER(12),
PPS_TOOLS13_ID NUMBER(12),
PPS_TOOLS14_ID NUMBER(12),
PPS_TOOLS15_ID NUMBER(12),
SCS_STEP_NUMBER NUMBER(12),
SCS_SHORT_DESCR VARCHAR2(50 CHAR),
TAL_BEGIN_PLAN_DATE DATE,
TAL_END_PLAN_DATE DATE,
TAL_HOURLY_RATE NUMBER(14,2),
TAL_END_REAL_DATE DATE,
TAL_BEGIN_REAL_DATE DATE,
TAL_BALANCE_DATE DATE,
TAL_HANGING_DATE DATE,
TAL_EAN_CODE VARCHAR2(50 CHAR),
SCS_FREE_DESCR VARCHAR2(4000 CHAR),
SCS_LONG_DESCR VARCHAR2(4000 CHAR),
A_DATECRE DATE,
A_IDCRE VARCHAR2(5 CHAR),
A_DATEMOD DATE,
A_IDMOD VARCHAR2(5 CHAR),
DOC_RECORD_ID NUMBER(12),
C_TASK_TYPE VARCHAR2(10 CHAR),
PAC_SUPPLIER_PARTNER_ID NUMBER(12),
GCO_GCO_GOOD_ID NUMBER(12),
DIC_FREE_TASK_CODE_ID VARCHAR2(10 CHAR),
DIC_FREE_TASK_CODE2_ID VARCHAR2(10 CHAR),
DIC_FREE_TASK_CODE3_ID VARCHAR2(10 CHAR),
DIC_FREE_TASK_CODE4_ID VARCHAR2(10 CHAR),
DIC_FREE_TASK_CODE5_ID VARCHAR2(10 CHAR),
DIC_FREE_TASK_CODE6_ID VARCHAR2(10 CHAR),
DIC_FREE_TASK_CODE7_ID VARCHAR2(10 CHAR),
DIC_FREE_TASK_CODE8_ID VARCHAR2(10 CHAR),
DIC_FREE_TASK_CODE9_ID VARCHAR2(10 CHAR),
SCS_NUM_WORK_OPERATOR NUMBER(9),
TAL_NUM_UNITS_ALLOCATED NUMBER(9),
TAL_DUE_TSK NUMBER(15,4),
TAL_ACHIEVED_TSK NUMBER(15,4),
TAL_TSK_BALANCE NUMBER(15,4),
SCS_DELAY NUMBER(15,4),
SCS_TRANSFERT_TIME NUMBER(15,4),
SCS_PLAN_RATE NUMBER(15,4));


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_455275_DUMMY_1" as table of number;


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458926_12_2" as object (GAL_HOURS_ID NUMBER(12),
HRM_PERSON_ID NUMBER(12),
GAL_PROJECT_ID NUMBER(12),
GAL_TASK_ID NUMBER(12),
GAL_TASK_LINK_ID NUMBER(12),
GAL_COST_CENTER_ID NUMBER(12),
GAL_BUDGET_ID NUMBER(12),
GAL_TASK_BUDGET_ID NUMBER(12),
HOU_POINTING_DATE DATE,
HOU_WORKED_TIME NUMBER(14,2),
HOU_HOURLY_RATE NUMBER(14,2),
A_DATECRE DATE,
A_IDCRE VARCHAR2(5 CHAR));


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458926_132_2" as object (DOC_POSITION_ID NUMBER(12),
DOC_DOCUMENT_ID NUMBER(12),
PAC_THIRD_ID NUMBER(12),
POS_NUMBER NUMBER(5),
POS_REFERENCE VARCHAR2(30),
POS_LONG_DESCRIPTION VARCHAR2(4000),
POS_SHORT_DESCRIPTION VARCHAR2(30),
C_GAUGE_TYPE_POS VARCHAR2(10),
C_DOC_POS_STATUS VARCHAR2(10),
GCO_GOOD_ID NUMBER(12),
DOC_RECORD_ID NUMBER(12),
PAC_REPRESENTATIVE_ID NUMBER(12),
PAC_PERSON_ID NUMBER(12),
FAM_FIXED_ASSETS_ID NUMBER(12),
C_FAM_TRANSACTION_TYP VARCHAR2(10),
HRM_PERSON_ID NUMBER(12),
ACS_FINANCIAL_ACCOUNT_ID NUMBER(12),
ACS_DIVISION_ACCOUNT_ID NUMBER(12),
ACS_CPN_ACCOUNT_ID NUMBER(12),
ACS_CDA_ACCOUNT_ID NUMBER(12),
ACS_PF_ACCOUNT_ID NUMBER(12),
ACS_PJ_ACCOUNT_ID NUMBER(12),
POS_CONVERT_FACTOR NUMBER(15,5),
POS_BASIS_QUANTITY NUMBER(15,4),
POS_INTERMEDIATE_QUANTITY NUMBER(15,4),
POS_FINAL_QUANTITY NUMBER(15,4),
POS_BALANCE_QUANTITY NUMBER(15,4),
POS_BASIS_QUANTITY_SU NUMBER(15,4),
POS_INTERMEDIATE_QUANTITY_SU NUMBER(15,4),
POS_FINAL_QUANTITY_SU NUMBER(15,4),
STM_STOCK_ID NUMBER(12),
POS_GROSS_UNIT_VALUE NUMBER(20,6),
POS_GROSS_UNIT_VALUE_INCL NUMBER(20,6),
POS_NET_UNIT_VALUE NUMBER(20,6),
POS_NET_UNIT_VALUE_INCL NUMBER(20,6),
POS_GROSS_VALUE NUMBER(16,2),
POS_GROSS_VALUE_B NUMBER(16,2),
POS_GROSS_VALUE_INCL NUMBER(16,2),
POS_GROSS_VALUE_INCL_B NUMBER(16,2),
POS_NET_VALUE_EXCL NUMBER(16,2),
POS_NET_VALUE_EXCL_B NUMBER(16,2),
POS_NET_VALUE_INCL NUMBER(16,2),
POS_NET_VALUE_INCL_B NUMBER(16,2),
DIC_IMP_FREE1_ID VARCHAR2(10),
DIC_IMP_FREE2_ID VARCHAR2(10),
DIC_IMP_FREE3_ID VARCHAR2(10),
DIC_IMP_FREE4_ID VARCHAR2(10),
DIC_IMP_FREE5_ID VARCHAR2(10),
POS_IMF_NUMBER_2 NUMBER(15,6),
POS_IMF_NUMBER_3 NUMBER(15,6),
POS_IMF_NUMBER_4 NUMBER(15,6),
POS_IMF_NUMBER_5 NUMBER(15,6),
POS_IMF_TEXT_1 VARCHAR2(30),
POS_IMF_TEXT_2 VARCHAR2(30),
POS_IMF_TEXT_3 VARCHAR2(30),
POS_IMF_TEXT_4 VARCHAR2(30),
POS_IMF_TEXT_5 VARCHAR2(30),
DMT_NUMBER VARCHAR2(30),
DMT_DATE_DOCUMENT DATE,
DOC_GAUGE_ID NUMBER(12),
A_CONFIRM NUMBER(1),
A_DATECRE DATE,
A_DATEMOD DATE,
A_IDCRE VARCHAR2(5),
A_IDMOD VARCHAR2(5),
A_RECLEVEL NUMBER(3),
A_RECSTATUS NUMBER(4));


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458926_738_2" as table of C_ITX."SYS_PLSQL_458926_12_2";


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458926_746_2" as table of C_ITX."SYS_PLSQL_455275_469_1";


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458926_756_2" as table of C_ITX."SYS_PLSQL_455142_177_1";


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458926_766_2" as table of C_ITX."SYS_PLSQL_458926_132_2";


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458926_774_2" as object (DOC_RECORD_ID NUMBER(12));


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458926_786_2" as table of C_ITX."SYS_PLSQL_458926_774_2";


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458926_DUMMY_2" as table of number;


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458980_21_2" as table of C_ITX."SYS_PLSQL_458980_9_2";


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458980_9_2" as object (DOC_RECORD_ID NUMBER(12));


  CREATE OR REPLACE TYPE "C_ITX"."SYS_PLSQL_458980_DUMMY_2" as table of number;

