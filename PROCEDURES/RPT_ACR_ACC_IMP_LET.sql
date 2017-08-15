--------------------------------------------------------
--  DDL for Procedure RPT_ACR_ACC_IMP_LET
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_ACC_IMP_LET" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_0    in     varchar2
, procparam_1    in     varchar2
, procparam_2    in     varchar2
, parameter_4    in     varchar2
, parameter_5    in     varchar2
, parameter_6    in     varchar2
, parameter_8    in     varchar2
, parameter_9    in     varchar2
, parameter_10   in     varchar2
, parameter_11   in     varchar2
, parameter_12   in     varchar2
, parameter_14   in     varchar2
, parameter_16   in     varchar2
, parameter_18   in     varchar2
, parameter_19   in     varchar2
, parameter_20   in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
)
is
/**
* description used for report ACR_ACC_IMPUTATION_LETTERING

* @author jliu 18 nov 2008
* @lastUpdate VHA 26 JUNE 2013
* @public
* @param procparam_0    ACC_NUMBER_From
* @param procparam_1    ACC_NUMBER_To
* @param procparam_2    ACS_FINANCIAL_YEAR_ID
* @param parameter_1    Date from/YYYY
* @param parameter_2    Date from/MM
* @param parameter_3    Date from/DD
* @param parameter_4    Date to/YYYY
* @param parameter_5    Date to/MM
* @param parameter_6    Date to/DD
* @param parameter_8    Only transaction without VAT
* @param parameter_9    C_TYPE_CUMUL = 'INT' :  0=No / 1=Yes
* @param parameter_10   Journal status = BRO : 1=Yes / 0=No
* @param parameter_11   Journal status = PROV : 1=Yes / 0=No
* @param parameter_12   Journal status = DEF : 1=Yes / 0=No
* @param parameter_14   Division_ID (List) # = All  or ACS_DIVISION_ACCOUNT_ID list
* @param parameter_16   Compare code : '0'=all / '1'= Matching / '2'= Unmatched
* @param parameter_18   C_TYPE_CUMUL = 'EXT' :  0=No / 1=Yes
* @param parameter_19   C_TYPE_CUMUL = 'PRE' :  0=No / 1=Yes
* @param parameter_20   C_TYPE_CUMUL = 'ENG' :  0=No / 1=Yes
*/
  TMP         number;
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id PCS.PC_USER.PC_USER_ID%type := null;
  PARAM5      varchar2(10);
  PARAM6      varchar2(10);
  vlstdivisions varchar2(4000);
begin
  if (procuser_lanid is not null) and (pc_user_id is not null)  then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => null
                                  , iConliId  => null);
      vpc_lang_id  := PCS.PC_I_LIB_SESSION.getUserlangId;
      vpc_user_id  := PCS.PC_I_LIB_SESSION.getUserId;
  end if;

  if (parameter_14 = '#') then
    vlstdivisions := null;
  else
    vlstdivisions := parameter_14;
  end if;

  if     (procparam_0 is not null)
     and (length(trim(procparam_0) ) > 0) then
    ACR_FUNCTIONS.ACC_NUMBER1  := procparam_0;
  else
    ACR_FUNCTIONS.ACC_NUMBER1  := '';
  end if;

  if     (procparam_1 is not null)
     and (length(trim(procparam_1) ) > 0) then
    ACR_FUNCTIONS.ACC_NUMBER2  := procparam_1;
  end if;

  if     (procparam_2 is not null)
     and (length(trim(procparam_2) ) > 0) then
    ACR_FUNCTIONS.FIN_YEAR_ID  := procparam_2;
  end if;

  if ACS_FUNCTION.GetFirstDivision is not null then
    ACR_FUNCTIONS.EXIST_DIVISION  := 1;
  else
    ACR_FUNCTIONS.EXIST_DIVISION  := 0;
  end if;

  if length(parameter_5) = 1 then
    PARAM5  := '0' || parameter_5;
  else
    PARAM5  := parameter_5;
  end if;

  if length(parameter_6) = 1 then
    PARAM6  := '0' || parameter_6;
  else
    PARAM6  := parameter_6;
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
  open aRefCursor for
    select V_ACC.ACC_NUMBER ACC_NUMBER
         , V_ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
         , V_ACC.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY
         , V_ACC.DES_DESCRIPTION_LARGE DES_DESCRIPTION_LARGE
         , V_IMP.ACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION_ID
         , V_IMP.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
         , V_IMP.IMF_TYPE IMF_TYPE
         , V_IMP.IMF_DESCRIPTION IMF_DESCRIPTION
         , V_IMP.IMF_AMOUNT_LC_D IMF_AMOUNT_LC_D
         , V_IMP.IMF_AMOUNT_LC_C IMF_AMOUNT_LC_C
         , V_IMP.IMF_VALUE_DATE IMF_VALUE_DATE
         , V_IMP.ACS_TAX_CODE_ID ACS_TAX_CODE_ID
         , V_IMP.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE
         , V_IMP.ACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT_ID
         , V_IMP.DOC_DATE_DELIVERY DOC_DATE_DELIVERY
         , V_IMP.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
         , V_IMP.DIV_NUMBER DIV_NUMBER
         , V_IMP.C_ETAT_JOURNAL C_ETAT_JOURNAL
         , V_IMP.C_TYPE_CUMUL C_TYPE_CUMUL
         , CAT.C_TYPE_CATALOGUE C_TYPE_CATALOGUE
         , AUX.ACC_NUMBER ACC_NUMBER_AUX
         , FIN.ACC_NUMBER ACC_NUMBER_FIN
         , VAT.ACS_ACCOUNT_ID VAT_ACS_ACCOUNT_ID
         , VAT.ACC_NUMBER ACC_NUMBER_VAT
         , FYR.ACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR_ID
         , ATD.ACT_DOCUMENT_ID ACT_DOCUMENT_ID
         , ATD.DOC_NUMBER DOC_NUMBER
         , JOU.JOU_DESCRIPTION JOU_DESCRIPTION
         , JOU.JOU_NUMBER JOU_NUMBER
         , CUR.CURRENCY CURRENCY
         , CUR_LC.CURRENCY CURRENCY_LC
         , LAN.LANID LANID
         , DES_AUX.DES_DESCRIPTION_SUMMARY AUX_DES_DESCRIPTION_SUMMARY
         , DES_DIV.DES_DESCRIPTION_SUMMARY DIV_DES_DESCRIPTION_SUMMARY
         , round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'D', null), 2) LET_AMNT_LD
         , round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'C', null), 2) LET_AMNT_LC
      from V_ACS_FINANCIAL_ACCOUNT V_ACC
         , V_ACT_ACC_IMP_REPORT V_IMP
         , PCS.PC_LANG LAN
         , ACS_PERIOD PRD
         , ACS_FINANCIAL_YEAR FYR
         , ACT_DOCUMENT ATD
         , ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_JOURNAL JOU
         , ACS_ACCOUNT VAT
         , ACS_ACCOUNT AUX
         , ACS_ACCOUNT FIN
         , ACS_FINANCIAL_CURRENCY FUR
         , PCS.PC_CURR CUR
         , ACS_FINANCIAL_CURRENCY FUR_LC
         , PCS.PC_CURR CUR_LC
         , ACT_FINANCIAL_IMPUTATION IMP
         , ACS_DESCRIPTION DES_AUX
         , ACS_DESCRIPTION DES_DIV
         , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, vlstdivisions) ) AUT
     where V_ACC.ACS_FINANCIAL_ACCOUNT_ID = V_IMP.ACS_FINANCIAL_ACCOUNT_ID
       and V_ACC.PC_LANG_ID(+) = vpc_lang_id
       and V_IMP.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID(+)
       and PRD.ACS_FINANCIAL_YEAR_ID = FYR.ACS_FINANCIAL_YEAR_ID(+)
       and V_IMP.ACT_DOCUMENT_ID = ATD.ACT_DOCUMENT_ID(+)
       and ATD.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and ATD.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
       and V_IMP.ACS_TAX_CODE_ID = VAT.ACS_ACCOUNT_ID(+)
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID(+)
       and FUR.PC_CURR_ID = CUR.PC_CURR_ID(+)
       and V_IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_ACCOUNT_ID(+)
       and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_LC.ACS_FINANCIAL_CURRENCY_ID(+)
       and FUR_LC.PC_CURR_ID = CUR_LC.PC_CURR_ID(+)
       and V_IMP.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID(+)
       and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_ACCOUNT_ID(+)
       and LAN.PC_LANG_ID(+) = vpc_lang_id
       and AUX.ACS_ACCOUNT_ID = DES_AUX.ACS_ACCOUNT_ID(+)
       and DES_AUX.PC_LANG_ID(+) = vpc_lang_id
       and V_IMP.ACS_DIVISION_ACCOUNT_ID = DES_DIV.ACS_ACCOUNT_ID(+)
       and DES_DIV.PC_LANG_ID(+) = vpc_lang_id
       and V_IMP.IMF_TRANSACTION_DATE <= to_date(parameter_4 || PARAM5 || PARAM6, 'yyyyMMdd')
       and (    (    parameter_10 = '1'
                 and V_IMP.C_ETAT_JOURNAL = 'BRO')
            or (    parameter_11 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'PROV')
            or (    parameter_12 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'DEF')
           )
       and V_IMP.ACS_DIVISION_ACCOUNT_ID is not null
       and AUT.column_value = V_IMP.ACS_DIVISION_ACCOUNT_ID
       and (   parameter_16 = '0'
            or (    parameter_16 = '1'
                and round(V_IMP.IMF_AMOUNT_LC_D, 2) = round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'D', null), 2)
                and round(V_IMP.IMF_AMOUNT_LC_C, 2) = round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'C', null), 2)
                and (   V_IMP.IMF_AMOUNT_LC_D <> 0
                     or V_IMP.IMF_AMOUNT_LC_C <> 0)
               )
            or (    parameter_16 = '1'
                and (   round(V_IMP.IMF_AMOUNT_LC_D, 2) <> round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'D', null), 2)
                     or round(V_IMP.IMF_AMOUNT_LC_C, 2) <> round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'C', null), 2)
                     or (    V_IMP.IMF_AMOUNT_LC_D = 0
                         and V_IMP.IMF_AMOUNT_LC_C = 0)
                    )
                and (    (    round(V_IMP.IMF_AMOUNT_LC_D, 2) <> 0
                          and round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'D', null), 2) <> 0
                         )
                     or (    round(V_IMP.IMF_AMOUNT_LC_C, 2) <> 0
                         and round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'C', null), 2) <> 0
                        )
                    )
               )
            or (    parameter_16 = '2'
                and CAT.C_TYPE_CATALOGUE is not null
                and CAT.C_TYPE_CATALOGUE <> '7'
                and (   V_IMP.IMF_AMOUNT_LC_D <> ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'D', null)
                     or V_IMP.IMF_AMOUNT_LC_C <> ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'C', null)
                    )
               )
           )
       and (    (    parameter_8 = '1'
                 and V_IMP.IMF_TYPE <> 'VAT'
                 and V_IMP.ACS_TAX_CODE_ID is null)
            or (    parameter_8 <> '1'
                and V_IMP.IMF_TYPE is not null) )
       and (    (    parameter_18 = '1'
                 and V_IMP.C_TYPE_CUMUL = 'EXT')
            or (    parameter_9 = '1'
                and V_IMP.C_TYPE_CUMUL = 'INT')
            or (    parameter_19 = '1'
                and V_IMP.C_TYPE_CUMUL = 'PRE')
            or (    parameter_20 = '1'
                and V_IMP.C_TYPE_CUMUL = 'ENG')
           )
    union all
    select distinct V_ACC.ACC_NUMBER ACC_NUMBER
                  , V_ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
                  , V_ACC.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY
                  , V_ACC.DES_DESCRIPTION_LARGE DES_DESCRIPTION_LARGE
                  , null ACT_FINANCIAL_IMPUTATION_ID
                  , null ACS_FINANCIAL_ACCOUNT_ID
                  , null IMF_TYPE
                  , null IMF_DESCRIPTION
                  , null IMF_AMOUNT_LC_D
                  , null IMF_AMOUNT_LC_C
                  , null IMF_VALUE_DATE
                  , null ACS_TAX_CODE_ID
                  , null IMF_TRANSACTION_DATE
                  , null ACS_AUXILIARY_ACCOUNT_ID
                  , null DOC_DATE_DELIVERY
                  , null ACS_DIVISION_ACCOUNT_ID
                  , null DIV_NUMBER
                  , null C_ETAT_JOURNAL
                  , null C_TYPE_CUMUL
                  , null C_TYPE_CATALOGUE
                  , null ACC_NUMBER_AUX
                  , null ACC_NUMBER_FIN
                  , null VAT_ACS_ACCOUNT_ID
                  , null ACC_NUMBER_VAT
                  , null ACS_FINANCIAL_YEAR_ID
                  , null ACT_DOCUMENT_ID
                  , null DOC_NUMBER
                  , null JOU_DESCRIPTION
                  , null JOU_NUMBER
                  , null CURRENCY
                  , null CURRENCY_LC
                  , null LANID
                  , null AUX_DES_DESCRIPTION_SUMMARY
                  , null DIV_DES_DESCRIPTION_SUMMARY
                  , null LET_AMNT_LD
                  , null LET_AMNT_LC
               from V_ACS_FINANCIAL_ACCOUNT V_ACC
              where V_ACC.ACS_FINANCIAL_ACCOUNT_ID not in(select V_IMP.ACS_FINANCIAL_ACCOUNT_ID
                                                            from V_ACT_ACC_IMP_REPORT V_IMP)
                and V_ACC.ACC_NUMBER >= ACR_FUNCTIONS.GetAccNumber(1)
                and V_ACC.ACC_NUMBER <= ACR_FUNCTIONS.GetAccNumber(0)
                and V_ACC.PC_LANG_ID = vpc_lang_id;
else     -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
  open aRefCursor for
    select V_ACC.ACC_NUMBER ACC_NUMBER
         , V_ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
         , V_ACC.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY
         , V_ACC.DES_DESCRIPTION_LARGE DES_DESCRIPTION_LARGE
         , V_IMP.ACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION_ID
         , V_IMP.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
         , V_IMP.IMF_TYPE IMF_TYPE
         , V_IMP.IMF_DESCRIPTION IMF_DESCRIPTION
         , V_IMP.IMF_AMOUNT_LC_D IMF_AMOUNT_LC_D
         , V_IMP.IMF_AMOUNT_LC_C IMF_AMOUNT_LC_C
         , V_IMP.IMF_VALUE_DATE IMF_VALUE_DATE
         , V_IMP.ACS_TAX_CODE_ID ACS_TAX_CODE_ID
         , V_IMP.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE
         , V_IMP.ACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT_ID
         , V_IMP.DOC_DATE_DELIVERY DOC_DATE_DELIVERY
         , V_IMP.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
         , V_IMP.DIV_NUMBER DIV_NUMBER
         , V_IMP.C_ETAT_JOURNAL C_ETAT_JOURNAL
         , V_IMP.C_TYPE_CUMUL C_TYPE_CUMUL
         , CAT.C_TYPE_CATALOGUE C_TYPE_CATALOGUE
         , AUX.ACC_NUMBER ACC_NUMBER_AUX
         , FIN.ACC_NUMBER ACC_NUMBER_FIN
         , VAT.ACS_ACCOUNT_ID VAT_ACS_ACCOUNT_ID
         , VAT.ACC_NUMBER ACC_NUMBER_VAT
         , FYR.ACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR_ID
         , ATD.ACT_DOCUMENT_ID ACT_DOCUMENT_ID
         , ATD.DOC_NUMBER DOC_NUMBER
         , JOU.JOU_DESCRIPTION JOU_DESCRIPTION
         , JOU.JOU_NUMBER JOU_NUMBER
         , CUR.CURRENCY CURRENCY
         , CUR_LC.CURRENCY CURRENCY_LC
         , LAN.LANID LANID
         , DES_AUX.DES_DESCRIPTION_SUMMARY AUX_DES_DESCRIPTION_SUMMARY
         , DES_DIV.DES_DESCRIPTION_SUMMARY DIV_DES_DESCRIPTION_SUMMARY
         , round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'D', null), 2) LET_AMNT_LD
         , round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'C', null), 2) LET_AMNT_LC
      from V_ACS_FINANCIAL_ACCOUNT V_ACC
         , V_ACT_ACC_IMP_REPORT V_IMP
         , PCS.PC_LANG LAN
         , ACS_PERIOD PRD
         , ACS_FINANCIAL_YEAR FYR
         , ACT_DOCUMENT ATD
         , ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_JOURNAL JOU
         , ACS_ACCOUNT VAT
         , ACS_ACCOUNT AUX
         , ACS_ACCOUNT FIN
         , ACS_FINANCIAL_CURRENCY FUR
         , PCS.PC_CURR CUR
         , ACS_FINANCIAL_CURRENCY FUR_LC
         , PCS.PC_CURR CUR_LC
         , ACT_FINANCIAL_IMPUTATION IMP
         , ACS_DESCRIPTION DES_AUX
         , ACS_DESCRIPTION DES_DIV
     where V_ACC.ACS_FINANCIAL_ACCOUNT_ID = V_IMP.ACS_FINANCIAL_ACCOUNT_ID
       and V_ACC.PC_LANG_ID(+) = vpc_lang_id
       and V_IMP.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID(+)
       and PRD.ACS_FINANCIAL_YEAR_ID = FYR.ACS_FINANCIAL_YEAR_ID(+)
       and V_IMP.ACT_DOCUMENT_ID = ATD.ACT_DOCUMENT_ID(+)
       and ATD.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and ATD.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
       and V_IMP.ACS_TAX_CODE_ID = VAT.ACS_ACCOUNT_ID(+)
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID(+)
       and FUR.PC_CURR_ID = CUR.PC_CURR_ID(+)
       and V_IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_ACCOUNT_ID(+)
       and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_LC.ACS_FINANCIAL_CURRENCY_ID(+)
       and FUR_LC.PC_CURR_ID = CUR_LC.PC_CURR_ID(+)
       and V_IMP.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID(+)
       and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_ACCOUNT_ID(+)
       and LAN.PC_LANG_ID(+) = vpc_lang_id
       and AUX.ACS_ACCOUNT_ID = DES_AUX.ACS_ACCOUNT_ID(+)
       and DES_AUX.PC_LANG_ID(+) = vpc_lang_id
       and V_IMP.ACS_DIVISION_ACCOUNT_ID = DES_DIV.ACS_ACCOUNT_ID(+)
       and DES_DIV.PC_LANG_ID(+) = vpc_lang_id
       and V_IMP.IMF_TRANSACTION_DATE <= to_date(parameter_4 || PARAM5 || PARAM6, 'yyyyMMdd')
       and (    (    parameter_10 = '1'
                 and V_IMP.C_ETAT_JOURNAL = 'BRO')
            or (    parameter_11 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'PROV')
            or (    parameter_12 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'DEF')
           )
       and (   parameter_16 = '0'
            or (    parameter_16 = '1'
                and round(V_IMP.IMF_AMOUNT_LC_D, 2) = round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'D', null), 2)
                and round(V_IMP.IMF_AMOUNT_LC_C, 2) = round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'C', null), 2)
                and (   V_IMP.IMF_AMOUNT_LC_D <> 0
                     or V_IMP.IMF_AMOUNT_LC_C <> 0)
               )
            or (    parameter_16 = '1'
                and (   round(V_IMP.IMF_AMOUNT_LC_D, 2) <> round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'D', null), 2)
                     or round(V_IMP.IMF_AMOUNT_LC_C, 2) <> round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'C', null), 2)
                     or (    V_IMP.IMF_AMOUNT_LC_D = 0
                         and V_IMP.IMF_AMOUNT_LC_C = 0)
                    )
                and (    (    round(V_IMP.IMF_AMOUNT_LC_D, 2) <> 0
                          and round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'D', null), 2) <> 0
                         )
                     or (    round(V_IMP.IMF_AMOUNT_LC_C, 2) <> 0
                         and round(ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'C', null), 2) <> 0
                        )
                    )
               )
            or (    parameter_16 = '2'
                and CAT.C_TYPE_CATALOGUE is not null
                and CAT.C_TYPE_CATALOGUE <> '7'
                and (   V_IMP.IMF_AMOUNT_LC_D <> ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'D', null)
                     or V_IMP.IMF_AMOUNT_LC_C <> ACR_FUNCTIONS.TOTAL_LETTERING_AMOUNT_IMPUT(V_IMP.ACT_FINANCIAL_IMPUTATION_ID, 'C', null)
                    )
               )
           )
       and (    (    parameter_8 = '1'
                 and V_IMP.IMF_TYPE <> 'VAT'
                 and V_IMP.ACS_TAX_CODE_ID is null)
            or (    parameter_8 <> '1'
                and V_IMP.IMF_TYPE is not null) )
       and (    (    parameter_18 = '1'
                 and V_IMP.C_TYPE_CUMUL = 'EXT')
            or (    parameter_9 = '1'
                and V_IMP.C_TYPE_CUMUL = 'INT')
            or (    parameter_19 = '1'
                and V_IMP.C_TYPE_CUMUL = 'PRE')
            or (    parameter_20 = '1'
                and V_IMP.C_TYPE_CUMUL = 'ENG')
           )
    union all
    select distinct V_ACC.ACC_NUMBER ACC_NUMBER
                  , V_ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
                  , V_ACC.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY
                  , V_ACC.DES_DESCRIPTION_LARGE DES_DESCRIPTION_LARGE
                  , null ACT_FINANCIAL_IMPUTATION_ID
                  , null ACS_FINANCIAL_ACCOUNT_ID
                  , null IMF_TYPE
                  , null IMF_DESCRIPTION
                  , null IMF_AMOUNT_LC_D
                  , null IMF_AMOUNT_LC_C
                  , null IMF_VALUE_DATE
                  , null ACS_TAX_CODE_ID
                  , null IMF_TRANSACTION_DATE
                  , null ACS_AUXILIARY_ACCOUNT_ID
                  , null DOC_DATE_DELIVERY
                  , null ACS_DIVISION_ACCOUNT_ID
                  , null DIV_NUMBER
                  , null C_ETAT_JOURNAL
                  , null C_TYPE_CUMUL
                  , null C_TYPE_CATALOGUE
                  , null ACC_NUMBER_AUX
                  , null ACC_NUMBER_FIN
                  , null VAT_ACS_ACCOUNT_ID
                  , null ACC_NUMBER_VAT
                  , null ACS_FINANCIAL_YEAR_ID
                  , null ACT_DOCUMENT_ID
                  , null DOC_NUMBER
                  , null JOU_DESCRIPTION
                  , null JOU_NUMBER
                  , null CURRENCY
                  , null CURRENCY_LC
                  , null LANID
                  , null AUX_DES_DESCRIPTION_SUMMARY
                  , null DIV_DES_DESCRIPTION_SUMMARY
                  , null LET_AMNT_LD
                  , null LET_AMNT_LC
               from V_ACS_FINANCIAL_ACCOUNT V_ACC
              where V_ACC.ACS_FINANCIAL_ACCOUNT_ID not in(select V_IMP.ACS_FINANCIAL_ACCOUNT_ID
                                                            from V_ACT_ACC_IMP_REPORT V_IMP)
                and V_ACC.ACC_NUMBER >= ACR_FUNCTIONS.GetAccNumber(1)
                and V_ACC.ACC_NUMBER <= ACR_FUNCTIONS.GetAccNumber(0)
                and V_ACC.PC_LANG_ID = vpc_lang_id;
end if;
end RPT_ACR_ACC_IMP_LET;
