--------------------------------------------------------
--  DDL for Package Body CML_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "CML_RPT" 
is
/*
* Description
*    STORED PROCEDURE USED FOR THE REPORT CML_INVOICING_DOCUMENTS
*/
  procedure Cml_Invoicing_Documents_Rpt_PK(AREFCURSOR in out Crystal_Cursor_Types.DUALCURSORTYP, PARAMETER_0 in varchar2)
  is
  begin
    open AREFCURSOR for
      select INJ.INJ_DESCRIPTION
           , INJ_DATE
           , DOC.DMT_NUMBER
           , PER.PAC_PERSON_ID
           , PER.PER_NAME
           , PER.PER_KEY1
           , FOO.FOO_DOCUMENT_TOTAL_AMOUNT
           , CUR.CURRENCY
           , PCO.PCO_DESCR
        from CML_INVOICING_JOB INJ
           , DOC_DOCUMENT DOC
           , DOC_FOOT FOO
           , PAC_PERSON PER
           , ACS_FINANCIAL_CURRENCY ACS
           , PCS.PC_CURR CUR
           , PAC_PAYMENT_CONDITION PCO
       where INJ.CML_INVOICING_JOB_ID = DOC.CML_INVOICING_JOB_ID
         and DOC.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
         and DOC.PAC_THIRD_ID = PER.PAC_PERSON_ID
         and DOC.ACS_FINANCIAL_CURRENCY_ID = ACS.ACS_FINANCIAL_CURRENCY_ID
         and ACS.PC_CURR_ID = CUR.PC_CURR_ID
         and DOC.PAC_PAYMENT_CONDITION_ID = PCO.PAC_PAYMENT_CONDITION_ID
         and INJ.CML_INVOICING_JOB_ID = to_number(PARAMETER_0);
  end Cml_Invoicing_Documents_Rpt_PK;

/*
* Description
*    STORED PROCEDURE USED FOR THE SUB-REPORT CML_INVOICING_DOCUMENTS _TOTAL (CML_INVOICING_DOCUMENTS)
*/
  procedure CML_INV_DOC_TOTAL_SUB_RPT_PK(AREFCURSOR in out Crystal_Cursor_Types.DUALCURSORTYP, PARAMETER_0 in varchar2)
  is
  begin
    open AREFCURSOR for
      select   CUR.CURRENCY
             , sum(FOO.FOO_DOCUMENT_TOTAL_AMOUNT) CURRENCY_TOTAL
          from CML_INVOICING_JOB INJ
             , DOC_DOCUMENT DOC
             , DOC_FOOT FOO
             , ACS_FINANCIAL_CURRENCY ACS
             , PCS.PC_CURR CUR
         where INJ.CML_INVOICING_JOB_ID = DOC.CML_INVOICING_JOB_ID
           and DOC.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
           and DOC.ACS_FINANCIAL_CURRENCY_ID = ACS.ACS_FINANCIAL_CURRENCY_ID
           and ACS.PC_CURR_ID = CUR.PC_CURR_ID
           and INJ.CML_INVOICING_JOB_ID = to_number(PARAMETER_0)
      group by CUR.CURRENCY;
  end CML_INV_DOC_TOTAL_SUB_RPT_PK;

/*
* Procedure CML_INVOICING_EXTRACTION_RPT
* Description
*       STORED PROCEDURE USED FOR THE REPORT DOC_CAN_GOOD.RPT
*/
  procedure CML_INVOICE_EXTRACTION_RPT_PK(
    AREFCURSOR     in out CRYSTAL_CURSOR_TYPES.DUALCURSORTYP
  , PARAMETER_0    in     number
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  )
  is
    VPC_LANG_ID PCS.PC_LANG.PC_LANG_ID%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := PCS.PC_I_LIB_SESSION.GETUSERLANGID;

    open AREFCURSOR for
      select   INP.INP_SELECTION
             , INP.PAC_CUSTOM_PARTNER_ID
             , PER.PER_NAME
             , PER.PER_KEY1
             , (select PER_NAME
                  from PAC_PERSON PER_ACI
                 where PER_ACI.PAC_PERSON_ID = nvl(INP.PAC_CUSTOM_PARTNER_ACI_ID, INP.PAC_CUSTOM_PARTNER_ID) ) PER_NAME_ACI
             , CCO.CCO_NUMBER
             , CCO.CCO_DESCRIPTION
             , CPO.CPO_SEQUENCE
             , CPO.CPO_DESCRIPTION
             , CPO.C_CML_POS_TYPE
             , COM_FUNCTIONS.GETDESCODEDESCR('C_CML_POS_TYPE', CPO.C_CML_POS_TYPE, VPC_LANG_ID) C_CML_POS_TYPE_DESCR
             , CPO.C_CML_POS_STATUS
             , COM_FUNCTIONS.GETDESCODEDESCR('C_CML_POS_STATUS', CPO.C_CML_POS_STATUS, VPC_LANG_ID) C_CML_POS_STATUS_DESCR
             , CPO.CPO_INIT_PERIOD_PRICE
             , CPO.CPO_EXTEND_PERIOD_PRICE
             , case
                 when INP.C_INVOICING_PROCESS_TYPE = 'FIXEDPRICE' then CPO.CPO_BILL_TEXT
                 when INP.C_INVOICING_PROCESS_TYPE = 'EVENTS' then CEV.CEV_TEXT
                 when INP.C_INVOICING_PROCESS_TYPE = 'DEPOSIT' then CPO.CPO_DEPOT_TEXT
                 when INP.C_INVOICING_PROCESS_TYPE = 'PENALITY' then CPO.CPO_PENALITY_TEXT
               end POS_FREE_DESCRIPTION
             , CEV.CEV_SEQUENCE
             , CEV.CML_POSITION_SERVICE_DETAIL_ID
             , CTT.CTT_DESCR
             , CTT.DIC_ASA_UNIT_OF_MEASURE_ID
             , (select DES.DIT_DESCR
                  from DICO_DESCRIPTION DES
                 where DES.DIT_CODE = CTT.DIC_ASA_UNIT_OF_MEASURE_ID
                   and DES.DIT_TABLE = 'DIC_UNIT_OF_MEASURE'
                   and DES.PC_LANG_ID = VPC_LANG_ID) DIC_ASA_UNIT_OF_MEASURE_DESCR
             , CUR.CURRENCY
             , PCO.PCO_DESCR
             , INP.C_INVOICING_PROCESS_TYPE
             , COM_FUNCTIONS.GETDESCODEDESCR('C_INVOICING_PROCESS_TYPE', INP.C_INVOICING_PROCESS_TYPE, VPC_LANG_ID) C_INVOICING_PROCESS_DESCR
             , INP.CML_DOCUMENT_ID
             , COU.COU_COMMENT
             , INP.INP_BEGIN_PERIOD_DATE
             , INP.INP_END_PERIOD_DATE
             , INP.INP_AMOUNT
             , INP.INP_COUNTER_BEGIN_QTY
             , INP.INP_COUNTER_END_QTY
             , INP.INP_FREE_QTY
             , INP.INP_GROSS_CONSUMED_QTY
             , INP.INP_NET_CONSUMED_QTY
             , INP.INP_BALANCE_QTY
             , INP.INP_INVOICING_QTY
             , CPD.CPD_UNIT_VALUE
             , CMD.CMD_LAST_INVOICE_STATEMENT
             , CMD.CMD_INITIAL_STATEMENT
             , CPM.CPM_WEIGHT
             , RCO_INST.RCO_TITLE
             , GOO.GOO_MAJOR_REFERENCE
             , INP.INP_REGROUP_ID
             --, SUM(INP_AMOUNT) OVER (PARTITION BY INP_REGROUP_ID) SUM_INP_AMOUNT
      ,        sum(INP_AMOUNT) over(partition by PER.PER_KEY1, CCO.CCO_NUMBER, CPO.CPO_SEQUENCE, INP.C_INVOICING_PROCESS_TYPE) SUM_INP_AMOUNT
          from CML_INVOICING_PROCESS INP
             , CML_INVOICING_JOB INJ
             , PAC_PERSON PER
             , ACS_FINANCIAL_CURRENCY FIN
             , PCS.PC_CURR CUR
             , PAC_PAYMENT_CONDITION PCO
             , CML_DOCUMENT CCO
             , CML_POSITION CPO
             , CML_EVENTS CEV
             , ASA_COUNTER_STATEMENT CST
             , ASA_COUNTER COU
             , ASA_COUNTER_TYPE CTT
             , CML_POSITION_SERVICE_DETAIL CPD
             , CML_POSITION_MACHINE_DETAIL CMD
             , CML_POSITION_MACHINE CPM
             , DOC_RECORD RCO_INST
             , GCO_GOOD GOO
         where INP.CML_INVOICING_JOB_ID = INJ.CML_INVOICING_JOB_ID
           and INP.CML_INVOICING_JOB_ID = PARAMETER_0
           and INP.CML_EVENTS_ID = CEV.CML_EVENTS_ID(+)
           and CEV.CML_EVENTS_ID = CST.CML_EVENTS_ID(+)
           and CST.ASA_COUNTER_ID = COU.ASA_COUNTER_ID(+)
           and COU.ASA_COUNTER_TYPE_ID = CTT.ASA_COUNTER_TYPE_ID(+)
           and CEV.CML_POSITION_SERVICE_DETAIL_ID = CPD.CML_POSITION_SERVICE_DETAIL_ID(+)
           and CEV.CML_POSITION_MACHINE_DETAIL_ID = CMD.CML_POSITION_MACHINE_DETAIL_ID(+)
           and CMD.CML_POSITION_MACHINE_ID = CPM.CML_POSITION_MACHINE_ID(+)
           and CPM.DOC_RCO_MACHINE_ID = RCO_INST.DOC_RECORD_ID(+)
           and RCO_INST.RCO_MACHINE_GOOD_ID = GOO.GCO_GOOD_ID(+)
           and INP.DOC_POSITION_ID is null
           and PER.PAC_PERSON_ID = INP.PAC_CUSTOM_PARTNER_ID
           and INP.CML_POSITION_ID = CPO.CML_POSITION_ID
           and CPO.CML_DOCUMENT_ID = CCO.CML_DOCUMENT_ID
           and INP.ACS_FINANCIAL_CURRENCY_ID = FIN.ACS_FINANCIAL_CURRENCY_ID
           and FIN.PC_CURR_ID = CUR.PC_CURR_ID
           and PER.PAC_PERSON_ID = INP.PAC_CUSTOM_PARTNER_ID
           and INP.PAC_PAYMENT_CONDITION_ID = PCO.PAC_PAYMENT_CONDITION_ID(+)
           and INP.INP_SELECTION = 1
      order by INP.INP_ORDER_BY;
  end CML_INVOICE_EXTRACTION_RPT_PK;

/*
* Description
*    STORED PROCEDURE USED FOR THE REPORT CML_POSITION_STD
*/
  procedure CML_POSITION_STD_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  , PARAMETER_0    in     CML_POSITION.CML_POSITION_ID%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select CCO.CCO_NUMBER
           ,   /*No contrat*/
             to_char(CCO.CCO_INITDATE, 'MM/DD/YYYY') CCO_INITDATE
           ,
             /*Date*/
             CCO.CCO_DESCRIPTION
           ,   /*Descr*/
             PCS.PC_FUNCTIONS.GETDESCODEDESCR('C_CML_CONTRACT_STATUS', CCO.C_CML_CONTRACT_STATUS, VPC_LANG_ID) C_CML_CONTRACT_STATUS
           ,   /*Statut*/
             (select PER1.PER_NAME
                from PAC_PERSON PER1
               where PER1.PAC_PERSON_ID = CCO.PAC_CUSTOM_PARTNER_ID) CLIENT
           ,   /*Client*/
             (select PER2.PER_NAME
                from PAC_PERSON PER2
               where PER2.PAC_PERSON_ID = CCO.PAC_CUSTOM_PARTNER_ACI_ID) CLIENT_FACT
           ,   /*Client fact*/
             (select PER3.PER_NAME
                from PAC_PERSON PER3
               where PER3.PAC_PERSON_ID = CCO.PAC_CUSTOM_PARTNER_TARIFF_ID) CLIENT_TARIF
           ,   /*Client tarif*/
             CCO.DIC_TARIFF_ID
           ,   /*Code tarif*/
             CPO.CPO_SEQUENCE
           ,   /*No pos*/
             CPO.CPO_DESCRIPTION
           ,   /*Descr pos*/
             PCS.PC_FUNCTIONS.GETDESCODEDESCR('C_CML_POS_TYPE', CPO.C_CML_POS_TYPE, VPC_LANG_ID) C_CML_POS_TYPE
           ,   /*Type*/
             CPO.CPO_COST_PRICE
           ,   /*PR*/
             (select RCO1.RCO_TITLE
                from DOC_RECORD RCO1
               where RCO1.DOC_RECORD_ID = CPO.DOC_RECORD_ID) DOSSIER
           ,   /*Dossier*/
             (select REP.REP_DESCR
                from PAC_REPRESENTATIVE REP
               where REP.PAC_REPRESENTATIVE_ID = CPO.PAC_REPRESENTATIVE_ID) REPR
           ,   /*Repr.*/
             (select PUS.USE_NAME
                from PCS.PC_USER PUS
               where PUS.PC_USER_ID = CPO.CPO_PC_USER_ID) VISA_CTRL
           ,   /*Visa ctrl*/
             CPO.CPO_SALE_PRICE
           ,   /*PV*/
             to_char(CPO.CPO_CONCLUSION_DATE, 'MM/DD/YYYY') CPO_CONCLUSION_DATE
           ,
             /*Date Conclusion*/
             to_char(CPO.CPO_BEGIN_CONTRACT_DATE, 'MM/DD/YYYY') CPO_BEGIN_CONTRACT_DATE
           ,
             /*Date d?ut*/
             CPO.CPO_EXTENDED_MONTHES
           ,   /*Prol. Contrat/mois*/
             CPO.CPO_EXTENSION_PERIOD_NB
           ,   /*Prol autoris?*/
             to_char(CPO.CPO_BEGIN_SERVICE_DATE, 'MM/DD/YYYY') CPO_BEGIN_SERVICE_DATE
           ,
             /*Date mise service*/
             CPO.CPO_CONTRACT_MONTHES
           ,   /*Dur?*/
             CPO.CPO_EXTENSION_TIME
           ,   /*Dur? prol*/
             CPO.CPO_EXT_PERIOD_NB_DONE
           ,   /*Prol effectu?*/
             to_char(CPO.CPO_END_CONTRACT_DATE, 'MM/DD/YYYY') CPO_END_CONTRACT_DATE
           ,
             /*Date fin pr?ue*/
             to_char(CPO.CPO_END_EXTENDED_DATE, 'MM/DD/YYYY') CPO_END_EXTENDED_DATE
           ,
             /*Date fin pr?ue prol*/
             CPO.CPO_INIT_PERIOD_PRICE
           ,   /*Prix p?iode init*/
             CPO.CPO_EXTEND_PERIOD_PRICE
           ,   /*Prix prolongation*/
             CPO.CPO_POSITION_COST_PRICE
           ,   /*Prix revient pos.*/
             CPO.CPO_POSITION_AMOUNT
           ,   /*Montant factur?/*/
             CPO.CPO_POSITION_ADDED_AMOUNT
           ,   /*Montant suppl fact.*/
             CPO.CPO_POSITION_LOSS
           ,   /*Perte position*/
             CPR.CPR_JANUARY
           , CPR.CPR_FEBRUARY
           , CPR.CPR_MARCH
           , CPR.CPR_APRIL
           , CPR.CPR_MAY
           , CPR.CPR_JUNE
           , CPR.CPR_JULY
           , CPR.CPR_AUGUST
           , CPR.CPR_SEPTEMBER
           , CPR.CPR_OCTOBER
           , CPR.CPR_NOVEMBER
           , CPR.CPR_DECEMBER
           , to_char(CPO.CPO_LAST_PERIOD_BEGIN, 'MM/DD/YYYY') CPO_LAST_PERIOD_BEGIN
           ,
             /*D?ut derni?e p?iode*/
             to_char(CPO.CPO_LAST_PERIOD_END, 'MM/DD/YYYY') CPO_LAST_PERIOD_END
           ,
             /*Fin derni?e p?iode*/
             to_char(CPO.CPO_NEXT_DATE, 'MM/DD/YYYY') CPO_NEXT_DATE
           ,
             /*Prochaine ?h?nce*/
             CPO.DIC_CML_INVOICE_REGROUPING_ID
           ,   /*Code regroupement fact*/
             CPO.CPO_BILL_TEXT
           ,   /*Texte facturation*/
             to_char(CPO.CPO_SUSPENSION_DATE, 'MM/DD/YYYY') CPO_SUSPENSION_DATE
           ,
             /*Date suspension*/
             CPO.DIC_CML_SUSPENSION_REASON_ID
           ,   /*Motif suspension*/
             to_char(CPO.CPO_RESILIATION_DATE, 'MM/DD/YYYY') CPO_RESILIATION_DATE
           ,
             /*Date r?iliation*/
             CPO.DIC_CML_RESILIATION_REASON_ID
           ,   /*Motif r?iliation*/
             CPO.CPO_DEPOT_AMOUNT
           ,   /*Montant d??t*/
             to_char(CPO.CPO_DEPOT_BILL_DATE, 'MM/DD/YYYY') CPO_DEPOT_BILL_DATE
           ,
             /*Date facture d??t*/
             to_char(CPO.CPO_DEPOT_CN_DATE, 'MM/DD/YYYY') CPO_DEPOT_CN_DATE
           ,
             /*Date NC d??t*/
             CPO.CPO_PENALITY_AMOUNT
           ,   /*Montant p?alit?/*/
             to_char(CPO.CPO_PENALITY_BILL_DATE, 'MM/DD/YYYY') CPO_PENALITY_BILL_DATE
        /*Date fact. P?alit?/*/
      from   CML_POSITION CPO
           , CML_DOCUMENT CCO
           , CML_PROCESSING CPR
       where CPO.CML_DOCUMENT_ID = CCO.CML_DOCUMENT_ID
         and CPO.CML_POSITION_ID = CPR.CML_POSITION_ID(+)
         and CPO.CML_POSITION_ID = PARAMETER_0;
  end CML_POSITION_STD_RPT_PK;

/*
* Description
*    STORED PROCEDURE USED FOR THE REPORT CML_POSITION_STD
*/
  procedure CML_POS_MACHINE_SUB_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  , PARAMETER_0    in     CML_POSITION.CML_POSITION_ID%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select CPM.CML_POSITION_MACHINE_ID
           , (select RCO2.RCO_TITLE
                from DOC_RECORD RCO2
               where RCO2.DOC_RECORD_ID = CPM.DOC_RCO_MACHINE_ID) NO_INSTALLATION
           ,   /*No installation*/
             CPM.CPM_WEIGHT
           ,   /*Pond?ation*/
             (select CTT.CTT_KEY
                from ASA_COUNTER COU
                   , ASA_COUNTER_TYPE CTT
               where COU.ASA_COUNTER_TYPE_ID = CTT.ASA_COUNTER_TYPE_ID
                 and COU.ASA_COUNTER_ID = CMD.ASA_COUNTER_ID) COMPTEUR
           ,   /*Compteur*/
             CMD.CMD_INITIAL_STATEMENT
           ,   /*Compteur d?ut contrat*/
             CMD.CMD_LAST_INVOICE_STATEMENT   /*Compteur derni?e fact*/
        from CML_POSITION_MACHINE CPM
           , CML_POSITION_MACHINE_DETAIL CMD
       where CPM.CML_POSITION_MACHINE_ID = CMD.CML_POSITION_MACHINE_ID(+)
         and CPM.CML_POSITION_ID = PARAMETER_0;
  end CML_POS_MACHINE_SUB_RPT_PK;

  procedure CML_POS_SERVICES_SUB_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  , PARAMETER_0    in     CML_POSITION.CML_POSITION_ID%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select CPS.CML_POSITION_SERVICE_ID
           , (select GOO_MAJOR_REFERENCE
                from GCO_GOOD GOO
               where GOO.GCO_GOOD_ID = CPS.GCO_CML_SERVICE_ID) REF_PRESTATION
           ,   /*Ref prestation*/
             CPS.CPS_LONG_DESCRIPTION   /*Descr. Longue*/
        from CML_POSITION_SERVICE CPS
       where CPS.CML_POSITION_ID = PARAMETER_0;
  end CML_POS_SERVICES_SUB_RPT_PK;
end CML_RPT;
