--------------------------------------------------------
--  DDL for Procedure RPT_PAC_CUS_PAR_PAY_MORALITY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_CUS_PAR_PAY_MORALITY" (
aRefCursor           IN OUT CRYSTAL_CURSOR_TYPES.DualCursorTyp,
PROCUSER_LANID       IN     pcs.pc_lang.lanid%type,
PROC_PARAMETER_0          IN     varchar2,
PROC_PARAMETER_1          IN     varchar2,
PROC_PARAMETER_2          IN     varchar2,
PROC_PARAMETER_3          IN     varchar2,
PROC_PARAMETER_4          IN     varchar2


)
IS

/**
* DESCRIPTION
* USED FOR REPORT  PAC_CUSTOM_PARTNER_PAYMENT_MORALITY
* @MIDIFIED BY   JLIU
* @LASTUPDATE   20 JUN 2010
* @PUBLIC

* @PARAM  parameter_0  List of subset if
* @PARAM  parameter_1  List of pac payment condition id
* @PARAM  parameter_2  List of pac person id
* @PARAM  parameter_3  Value(Average credit)
* @PARAM  parameter_4  Value(Coefficient)
*/

VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;

begin



pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);
VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;



open aRefCursor for

select ANNEE.FYE_NO_EXERCICE annee
     , DSUB.ACS_SUB_SET_ID
     , DSUB.DES_DESCRIPTION_SUMMARY
     , PER.PAC_PERSON_ID
     , PER.PER_KEY1
     , PER.PER_NAME
     , PAY.PCO_DESCR
     , trad.APT_LABEL
     , ACR_FUNCTIONS.AveragePaymentByExercice(aux.ACS_AUXILIARY_ACCOUNT_ID, annee.acs_financial_year_id) DELAI_PART
     , nvl(CUS.CUS_PAYMENT_FACTOR, 0) Coefficient
     , nvl(to_char(CUS.CUS_PAYMENT_FACTOR_DATE, 'dd.mm.yyyy'), 0) date_coeff
     , ACR_FUNCTIONS.MeanCreditInDay(aux.ACS_AUXILIARY_ACCOUNT_ID, annee.acs_financial_year_id) CREDIT_PART
  from pac_person per
     , pac_custom_partner cus
     , acs_auxiliary_account aux
     , acs_financial_year annee
     , acs_account acc
     , acs_sub_set sub
     , acs_description dsub
     , pac_payment_condition pay
     , pcs.PC_APPLTXT_TRADUCTION trad
 where cus.pac_custom_partner_id(+) = per.pac_person_id
   and cus.acs_auxiliary_account_id = aux.acs_auxiliary_account_id
   and ACC.ACS_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
   and ANNEE.FYE_NO_EXERCICE = to_char(sysdate, 'yyyy')
   and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
   and DSUB.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
   and DSUB.PC_LANG_ID = VPC_LANG_ID
   and CUS.PAC_PAYMENT_CONDITION_ID = PAY.PAC_PAYMENT_CONDITION_ID
   and PAY.PC_APPLTXT_ID = TRAD.PC_APPLTXT_ID
   and TRAD.PC_LANG_ID = VPC_LANG_ID
   and (PROC_PARAMETER_0 IS NULL OR INSTR( ',' || PROC_PARAMETER_0 ||',' , ',' || ACC.ACS_SUB_SET_ID ||',' ) > 0 )
   and (PROC_PARAMETER_2 IS NULL OR INSTR( ',' || PROC_PARAMETER_2 ||',' , ',' || per.pac_person_id  ||',' ) > 0 )
   and (PROC_PARAMETER_1 IS NULL OR INSTR( ',' || PROC_PARAMETER_1 ||',' , ',' || CUS.PAC_PAYMENT_CONDITION_ID  ||',' ) > 0 )
   and ACR_FUNCTIONS.MeanCreditInDay(aux.ACS_AUXILIARY_ACCOUNT_ID, annee.acs_financial_year_id)>=to_number(PROC_PARAMETER_3)
   and nvl(CUS.CUS_PAYMENT_FACTOR, 0)>=to_number(PROC_PARAMETER_4);


end RPT_PAC_CUS_PAR_PAY_MORALITY;
