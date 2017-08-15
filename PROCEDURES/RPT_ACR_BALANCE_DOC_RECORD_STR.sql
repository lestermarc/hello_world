--------------------------------------------------------
--  DDL for Procedure RPT_ACR_BALANCE_DOC_RECORD_STR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_BALANCE_DOC_RECORD_STR" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PROCPARAM_0 in     varchar2
, PROCPARAM_1 in     varchar2
, PROCPARAM_2 in     varchar2
, PROCPARAM_3 in     number
, PROCPARAM_4 in     number
, PROCPARAM_5 in     number
, PROCPARAM_6 in     varchar2
, PROCPARAM_7 in     varchar2
, PROCCOMPANY_NAME in pcs.pc_comp.com_name%type
, PROCPC_USER_ID in pcs.pc_user.pc_user_id%type)

is
/**
* Procédure stockée utilisée pour le rapport ACR_BALANCE_DOC_RECORD_STR (Balance Dossier avec classification)
* Replace report ACR_BALANCE_DOC_RECORD_STR_RPT
*
* @author SDO
* @lastUpdate VHA 29 november 2013
* @version 2003
* @public
* @param PROCPARAM_0    Classification        (ClASSIFICATION_ID)
* @param PROCPARAM_1    Dossier du            (RCO_TITLE)
* @param PROCPARAM_2    Dossier au            (RCO_TITLE)
* @param PROCPARAM_3    Exercice              (FYE_NO_EXERCICE)
* @param PROCPARAM_4    Période de            (PER_NO_PERIOD)
* @param PROCPARAM_5    Période à             (PER_NO_PERIOD)
* @param PROCPARAM_6    Sous-dossiers         0 = No, 1 = Yes
* @param PROCPARAM_7    Categories_ID (List)  '' = All sinon liste des ID
*/

vUserName   pcs.pc_user.use_name%type := null;
VPC_LANG_ID pcs.pc_lang.pc_lang_id%type := null;
begin
  select max(USE_NAME)
    into vUserName
    from PCS.PC_USER USR
   where USR.PC_USER_ID = PROCPC_USER_ID;

  if PROCPARAM_0 is not null then
      pcs.PC_I_LIB_SESSION.initsession(PROCCOMPANY_NAME, vUserName);
      VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;
  end if;

IF PROCPARAM_6 = 0 THEN
  open aRefCursor for
    SELECT
      'REEL' INFO,
      CFL.LEAF_DESCR LEAF_DESCR,
      CFL.NODE01,
      CFL.NODE02,
      CFL.NODE03,
      CFL.NODE04,
      CFL.NODE05,
      CFL.NODE06,
      CFL.NODE07,
      CFL.NODE08,
      CFL.NODE09,
      CFL.NODE10,
      CFL.PC_LANG_ID,
      MTO.ACS_PERIOD_ID,
      MTO.C_TYPE_CUMUL,
      MTO.DOC_RECORD_ID,
      RCO.RCO_TITLE,
      RCO.RCO_DESCRIPTION,
      (SELECT RCY.RCY_KEY
       FROM   DOC_RECORD_CATEGORY RCY
       WHERE  RCY.DOC_RECORD_CATEGORY_ID = RCO.DOC_RECORD_CATEGORY_ID ) RCY_KEY,
      MTO.ACS_CPN_ACCOUNT_ID,
      (SELECT ACC.ACC_NUMBER
       FROM   ACS_ACCOUNT ACC
       WHERE  ACC.ACS_ACCOUNT_ID = MTO.ACS_CPN_ACCOUNT_ID) ACC_NUMBER_CPN,
      (SELECT DES.DES_DESCRIPTION_SUMMARY
       FROM   ACS_DESCRIPTION DES
       WHERE  DES.ACS_ACCOUNT_ID   = MTO.ACS_CPN_ACCOUNT_ID and
              DES.PC_LANG_ID       = VPC_LANG_ID) ACCOUNT_CPN_DESCR,
      MTO.ACS_FINANCIAL_CURRENCY_ID,
      (SELECT CUR.CURRENCY
       FROM   PCS.PC_CURR CUR,
              ACS_FINANCIAL_CURRENCY FIC
       WHERE  FIC.ACS_FINANCIAL_CURRENCY_ID = MTO.ACS_ACS_FINANCIAL_CURRENCY_ID and
              FIC.PC_CURR_ID                = CUR.PC_CURR_ID) CURRENCY,
      (SELECT CURRENCY FROM PCS.PC_CURR WHERE PC_CURR_ID = (SELECT PC_CURR_ID
                                                              FROM ACS_FINANCIAL_CURRENCY
                                                             WHERE FIN_LOCAL_CURRENCY = 1)) LOCAL_CURRENCY_NAME,
      case
	  	  when (PROCPARAM_3 > -1) AND (PROCPARAM_4 > -1) AND
             ((SELECT PER_END_DATE FROM ACS_PERIOD WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) <
              (SELECT PER_START_DATE FROM ACS_PERIOD WHERE PER_NO_PERIOD = PROCPARAM_4 AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID FROM ACS_FINANCIAL_YEAR WHERE FYE_NO_EXERCICE = PROCPARAM_3)))
        then MTO.MTO_DEBIT_LC
		    else 0
	    end MTO_START_DEBIT_LC, --DEBIT AVANT
      case
	  	  when (PROCPARAM_3 > -1) AND (PROCPARAM_4 > -1) AND
             ((SELECT PER_END_DATE FROM ACS_PERIOD WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) <
              (SELECT PER_START_DATE FROM ACS_PERIOD WHERE PER_NO_PERIOD = PROCPARAM_4 AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID FROM ACS_FINANCIAL_YEAR WHERE FYE_NO_EXERCICE = PROCPARAM_3)))
        then MTO.MTO_CREDIT_LC
        else 0
	    end MTO_START_CREDIT_LC, --CREDIT AVANT
	    case
	  	  when (PROCPARAM_3 > -1) AND (PROCPARAM_4 > -1) AND(PROCPARAM_5 > -1) AND
             ((SELECT PER_START_DATE FROM ACS_PERIOD
                WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) BETWEEN (SELECT PER_START_DATE
                                                                    FROM ACS_PERIOD
                                                                   WHERE PER_NO_PERIOD = PROCPARAM_4
                                                                     AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID
                                                                                                    FROM ACS_FINANCIAL_YEAR
                                                                                                   WHERE FYE_NO_EXERCICE = PROCPARAM_3))
                                                             AND (SELECT PER_END_DATE
                                                                    FROM ACS_PERIOD
                                                                   WHERE PER_NO_PERIOD = PROCPARAM_5
                                                                     AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID
                                                                                                    FROM ACS_FINANCIAL_YEAR
                                                                                                   WHERE FYE_NO_EXERCICE = PROCPARAM_3)))
          and  (select C_TYPE_PERIOD
                   from ACS_PERIOD
                   where ACS_PERIOD_ID = MTO.ACS_PERIOD_ID)  <>'1'
        then MTO.MTO_DEBIT_LC
        else 0
        end MTO_DEBIT_LC,
	    case
	  	  when (PROCPARAM_3 > -1) AND (PROCPARAM_4 > -1) AND(PROCPARAM_5 > -1) AND
             ((SELECT PER_START_DATE FROM ACS_PERIOD
                WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) BETWEEN (SELECT PER_START_DATE
                                                                    FROM ACS_PERIOD
                                                                   WHERE PER_NO_PERIOD = PROCPARAM_4
                                                                     AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID
                                                                                                    FROM ACS_FINANCIAL_YEAR
                                                                                                   WHERE FYE_NO_EXERCICE = PROCPARAM_3))
                                                             AND (SELECT PER_END_DATE
                                                                    FROM ACS_PERIOD
                                                                   WHERE PER_NO_PERIOD = PROCPARAM_5
                                                                     AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID
                                                                                                    FROM ACS_FINANCIAL_YEAR
                                                                                                   WHERE FYE_NO_EXERCICE = PROCPARAM_3)))
          and  (select C_TYPE_PERIOD
                   from ACS_PERIOD
                   where ACS_PERIOD_ID = MTO.ACS_PERIOD_ID)  <>'1'
        then MTO.MTO_CREDIT_LC
        else 0
        end MTO_CREDIT_LC,
      MTO.MTO_DEBIT_FC,
      MTO.MTO_CREDIT_FC,
        case  when (PROCPARAM_3 = -1)
                           and (PROCPARAM_4 = -1)
                           and (PROCPARAM_5 = -1)
                           and ( (select  C_TYPE_PERIOD from ACS_PERIOD where ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) = '2')
                then MTO.MTO_DEBIT_LC
                else 0
        end MTO_END_DEBIT_LC, --TOTAL DEBIT
        case  when (PROCPARAM_3 = -1)
                           and (PROCPARAM_4 = -1)
                           and (PROCPARAM_5 = -1)
                           and ( (select C_TYPE_PERIOD from ACS_PERIOD where ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) = '2')
                then MTO.MTO_CREDIT_LC
                else 0
        end MTO_END_CREDIT_LC, --TOTAL CREDIT
      (SELECT PER_NO_PERIOD FROM ACS_PERIOD WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) PER_NO_PERIOD,
      (SELECT C_TYPE_PERIOD FROM ACS_PERIOD WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) C_TYPE_PERIOD
      FROM DOC_RECORD            RCO,
           ACT_MGM_TOT_BY_PERIOD MTO,
           CLASSIF_FLAT          CFL
     WHERE CFL.CLASSIFICATION_ID       = PROCPARAM_0
       AND CFL.PC_LANG_ID              = VPC_LANG_ID
       AND CFL.CLASSIF_LEAF_ID         = MTO.ACS_CPN_ACCOUNT_ID
       AND RCO.RCO_TITLE              >= PROCPARAM_1
       AND RCO.RCO_TITLE              <= PROCPARAM_2
       AND MTO.DOC_RECORD_ID           = RCO.DOC_RECORD_ID
       AND (INSTR(','||PROCPARAM_7||',', TO_CHAR(','||RCO.DOC_RECORD_CATEGORY_ID||',')) > 0 OR PROCPARAM_7 is null)
  UNION ALL
    SELECT
      'VIDE' INFO,
      NULL LEAF_DESCR,
      NULL NODE01,
      NULL NODE02,
      NULL NODE03,
      NULL NODE04,
      NULL NODE05,
      NULL NODE06,
      NULL NODE07,
      NULL NODE08,
      NULL NODE09,
      NULL NODE10,
      0 LANG_ID,
      0 ACS_PERIOD_ID,
      NULL C_TYPE_CUMUL,
      0 DOC_RECORD_ID,
      RCO.RCO_TITLE,
      RCO.RCO_DESCRIPTION,
      NULL RCY_KEY,
      0 ACS_CPN_ACCOUNT_ID,
      NULL ACC_NUMBER_CPN,
      NULL ACCOUNT_CPN_DESCR,
      0 ACS_FINANCIAL_CURRENCY_ID,
      NULL CURRENCY,
      (SELECT CURRENCY FROM PCS.PC_CURR WHERE PC_CURR_ID = (SELECT PC_CURR_ID
                                                              FROM ACS_FINANCIAL_CURRENCY
                                                             WHERE FIN_LOCAL_CURRENCY = 1)) LOCAL_CURRENCY_NAME,
      0 MTO_START_DEBIT_LC, --DEBIT AVANT
      0 MTO_START_CREDIT_LC, --CREDIT_AVANT
      0 MTO_DEBIT_LC,
      0 MTO_CREDIT_LC,
      0 MTO_DEBIT_FC,
      0 MTO_CREDIT_FC,
      0 MTO_END_DEBIT_LC, --TOTAL DEBIT
      0 MTO_END_CREDIT_LC, --TOTAL CREDIT
      0 PER_NO_PERIOD,
      NULL C_TYPE_PERIOD
      FROM DOC_RECORD RCO
     WHERE RCO.RCO_TITLE >= PROCPARAM_1
       AND RCO.RCO_TITLE <= PROCPARAM_2
       AND (INSTR(','||PROCPARAM_7||',', TO_CHAR(','||RCO.DOC_RECORD_CATEGORY_ID||',')) > 0 OR PROCPARAM_7 is null);
ELSE
  open aRefCursor for
    SELECT
      'REEL' INFO,
      CFL.LEAF_DESCR LEAF_DESCR,
      CFL.NODE01,
      CFL.NODE02,
      CFL.NODE03,
      CFL.NODE04,
      CFL.NODE05,
      CFL.NODE06,
      CFL.NODE07,
      CFL.NODE08,
      CFL.NODE09,
      CFL.NODE10,
      CFL.PC_LANG_ID,
      MTO.ACS_PERIOD_ID,
      MTO.C_TYPE_CUMUL,
      MTO.DOC_RECORD_ID,
      RCO.RCO_TITLE,
      RCO.RCO_DESCRIPTION,
      (SELECT RCY.RCY_KEY
       FROM   DOC_RECORD_CATEGORY RCY
       WHERE  RCY.DOC_RECORD_CATEGORY_ID = RCO.DOC_RECORD_CATEGORY_ID ) RCY_KEY,
      MTO.ACS_CPN_ACCOUNT_ID,
      (SELECT ACC.ACC_NUMBER
       FROM   ACS_ACCOUNT ACC
       WHERE  ACC.ACS_ACCOUNT_ID = MTO.ACS_CPN_ACCOUNT_ID) ACC_NUMBER_CPN,
      (SELECT DES.DES_DESCRIPTION_SUMMARY
       FROM   ACS_DESCRIPTION DES
       WHERE  DES.ACS_ACCOUNT_ID   = MTO.ACS_CPN_ACCOUNT_ID and
              DES.PC_LANG_ID       = VPC_LANG_ID) ACCOUNT_CPN_DESCR,
      MTO.ACS_FINANCIAL_CURRENCY_ID,
      (SELECT CUR.CURRENCY
       FROM   PCS.PC_CURR CUR,
              ACS_FINANCIAL_CURRENCY FIC
       WHERE  FIC.ACS_FINANCIAL_CURRENCY_ID = MTO.ACS_ACS_FINANCIAL_CURRENCY_ID and
              FIC.PC_CURR_ID                = CUR.PC_CURR_ID) CURRENCY,
      (SELECT CURRENCY FROM PCS.PC_CURR WHERE PC_CURR_ID = (SELECT PC_CURR_ID
                                                              FROM ACS_FINANCIAL_CURRENCY
                                                             WHERE FIN_LOCAL_CURRENCY = 1)) LOCAL_CURRENCY_NAME,
      case
	  	  when (PROCPARAM_3 > -1) AND (PROCPARAM_4 > -1) AND
             ((SELECT PER_END_DATE FROM ACS_PERIOD WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) <
              (SELECT PER_START_DATE FROM ACS_PERIOD WHERE PER_NO_PERIOD = PROCPARAM_4 AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID FROM ACS_FINANCIAL_YEAR WHERE FYE_NO_EXERCICE = PROCPARAM_3)))
        then MTO.MTO_DEBIT_LC
		    else 0
	    end MTO_START_DEBIT_LC, --DEBIT AVANT
      case
	  	  when (PROCPARAM_3 > -1) AND (PROCPARAM_4 > -1) AND
             ((SELECT PER_END_DATE FROM ACS_PERIOD WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) <
              (SELECT PER_START_DATE FROM ACS_PERIOD WHERE PER_NO_PERIOD = PROCPARAM_4 AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID FROM ACS_FINANCIAL_YEAR WHERE FYE_NO_EXERCICE = PROCPARAM_3)))
        then MTO.MTO_CREDIT_LC
        else 0
	    end MTO_START_CREDIT_LC, --CREDIT AVANT
	    case
	  	  when (PROCPARAM_3 > -1) AND (PROCPARAM_4 > -1) AND(PROCPARAM_5 > -1) AND
             ((SELECT PER_START_DATE FROM ACS_PERIOD
                WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) BETWEEN (SELECT PER_START_DATE
                                                                    FROM ACS_PERIOD
                                                                   WHERE PER_NO_PERIOD = PROCPARAM_4
                                                                     AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID
                                                                                                    FROM ACS_FINANCIAL_YEAR
                                                                                                   WHERE FYE_NO_EXERCICE = PROCPARAM_3))
                                                             AND (SELECT PER_END_DATE
                                                                    FROM ACS_PERIOD
                                                                   WHERE PER_NO_PERIOD = PROCPARAM_5
                                                                     AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID
                                                                                                    FROM ACS_FINANCIAL_YEAR
                                                                                                   WHERE FYE_NO_EXERCICE = PROCPARAM_3)))
          and  (select C_TYPE_PERIOD
                   from ACS_PERIOD
                   where ACS_PERIOD_ID = MTO.ACS_PERIOD_ID)  <>'1'
        then MTO.MTO_DEBIT_LC
        else 0
        end MTO_DEBIT_LC,
	    case
	  	  when (PROCPARAM_3 > -1) AND (PROCPARAM_4 > -1) AND(PROCPARAM_5 > -1) AND
             ((SELECT PER_START_DATE FROM ACS_PERIOD
                WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) BETWEEN (SELECT PER_START_DATE
                                                                    FROM ACS_PERIOD
                                                                   WHERE PER_NO_PERIOD = PROCPARAM_4
                                                                     AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID
                                                                                                    FROM ACS_FINANCIAL_YEAR
                                                                                                   WHERE FYE_NO_EXERCICE = PROCPARAM_3))
                                                             AND (SELECT PER_END_DATE
                                                                    FROM ACS_PERIOD
                                                                   WHERE PER_NO_PERIOD = PROCPARAM_5
                                                                     AND ACS_FINANCIAL_YEAR_ID = (SELECT ACS_FINANCIAL_YEAR_ID
                                                                                                    FROM ACS_FINANCIAL_YEAR
                                                                                                   WHERE FYE_NO_EXERCICE = PROCPARAM_3)))
          and  (select C_TYPE_PERIOD
                   from ACS_PERIOD
                   where ACS_PERIOD_ID = MTO.ACS_PERIOD_ID)  <>'1'
        then MTO.MTO_CREDIT_LC
        else 0
        end MTO_CREDIT_LC,
      MTO.MTO_DEBIT_FC,
      MTO.MTO_CREDIT_FC,
        case  when (PROCPARAM_3 = -1)
                           and (PROCPARAM_4 = -1)
                           and (PROCPARAM_5 = -1)
                           and ( (select  C_TYPE_PERIOD from ACS_PERIOD where ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) = '2')
                then MTO.MTO_DEBIT_LC
                else 0
        end MTO_END_DEBIT_LC, --TOTAL DEBIT
        case  when (PROCPARAM_3 = -1)
                           and (PROCPARAM_4 = -1)
                           and (PROCPARAM_5 = -1)
                           and ( (select C_TYPE_PERIOD from ACS_PERIOD where ACS_PERIOD_ID = MTO.ACS_PERIOD_ID)  = '2')
                then MTO.MTO_CREDIT_LC
                else 0
        end MTO_END_CREDIT_LC, --TOTAL CREDIT
      (SELECT PER_NO_PERIOD FROM ACS_PERIOD WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) PER_NO_PERIOD,
      (SELECT C_TYPE_PERIOD FROM ACS_PERIOD WHERE ACS_PERIOD_ID = MTO.ACS_PERIOD_ID) C_TYPE_PERIOD
      FROM  (SELECT CHILD_DOC_RECORD_ID,
                    DOC_RECORD_ID
               FROM (SELECT COLUMN_VALUE CHILD_DOC_RECORD_ID,
    	                      RCO1.DOC_RECORD_ID
                       FROM DOC_RECORD RCO1,
    		                    table(ACR_FUNCTIONS.GetChildrenLinkedDocRecord(RCO1.DOC_RECORD_ID, 20))
                      WHERE RCO1.RCO_TITLE >= PROCPARAM_1
                        AND RCO1.RCO_TITLE <= PROCPARAM_2
                        AND (INSTR(','||PROCPARAM_7||',', TO_CHAR(','||RCO1.DOC_RECORD_CATEGORY_ID||',')) > 0 OR PROCPARAM_7 is null)
    	      )) CHI,
            ACT_MGM_TOT_BY_PERIOD MTO,
            DOC_RECORD RCO,
           CLASSIF_FLAT CFL
     WHERE CFL.CLASSIFICATION_ID  = PROCPARAM_0
       AND CFL.PC_LANG_ID         = VPC_LANG_ID
       AND CFL.CLASSIF_LEAF_ID    = MTO.ACS_CPN_ACCOUNT_ID
       AND MTO.DOC_RECORD_ID      = CHI.CHILD_DOC_RECORD_ID
       AND CHI.DOC_RECORD_ID      = RCO.DOC_RECORD_ID
  UNION ALL
    SELECT
      'VIDE' INFO,
      NULL LEAF_DESCR,
      NULL NODE01,
      NULL NODE02,
      NULL NODE03,
      NULL NODE04,
      NULL NODE05,
      NULL NODE06,
      NULL NODE07,
      NULL NODE08,
      NULL NODE09,
      NULL NODE10,
      0 LANG_ID,
      0 ACS_PERIOD_ID,
      NULL C_TYPE_CUMUL,
      0 DOC_RECORD_ID,
      RCO.RCO_TITLE,
      RCO.RCO_DESCRIPTION,
      NULL RCY_KEY,
      0 ACS_CPN_ACCOUNT_ID,
      NULL ACC_NUMBER_CPN,
      NULL ACCOUNT_CPN_DESCR,
      0 ACS_FINANCIAL_CURRENCY_ID,
      NULL CURRENCY,
      (SELECT CURRENCY FROM PCS.PC_CURR WHERE PC_CURR_ID = (SELECT PC_CURR_ID
                                                              FROM ACS_FINANCIAL_CURRENCY
                                                             WHERE FIN_LOCAL_CURRENCY = 1)) LOCAL_CURRENCY_NAME,
      0 MTO_START_DEBIT_LC, --DEBIT AVANT
      0 MTO_START_CREDIT_LC, --CREDIT_AVANT
      0 MTO_DEBIT_LC,
      0 MTO_CREDIT_LC,
      0 MTO_DEBIT_FC,
      0 MTO_CREDIT_FC,
      0 MTO_END_DEBIT_LC, --TOTAL DEBIT
      0 MTO_END_CREDIT_LC, --TOTAL CREDIT
      0 PER_NO_PERIOD,
      NULL C_TYPE_PERIOD
    FROM
      DOC_RECORD                    RCO
    WHERE (INSTR(','||PROCPARAM_7||',', TO_CHAR(','||RCO.DOC_RECORD_CATEGORY_ID||',')) > 0 OR PROCPARAM_7 is null)
      AND RCO.RCO_TITLE >= PROCPARAM_1
      AND RCO.RCO_TITLE <= PROCPARAM_2;
  end if;
end RPT_ACR_BALANCE_DOC_RECORD_STR;
