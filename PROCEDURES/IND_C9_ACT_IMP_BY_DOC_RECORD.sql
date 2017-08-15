--------------------------------------------------------
--  DDL for Procedure IND_C9_ACT_IMP_BY_DOC_RECORD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_ACT_IMP_BY_DOC_RECORD" (PROCPARAM0 acs_account.acc_number%type,
                                PROCPARAM1 acs_account.acc_number%type,
                                PROCPARAM2 acs_financial_year.fye_no_exercice%type,
                                PROCPARAM3 acs_period.per_no_period%type,
                                PROCPARAM4 acs_period.per_no_period%type,
                                PROCPARAM5 acs_account.acc_number%type,
                                PROCPARAM6 number,
                                PROCPARAM7 number,
                                PROCPARAM8 doc_record.rco_title%type,
                                PROCPARAM9 doc_record.rco_title%type,
                                aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
 -- Procédure pour rapport Crystal ACT_IMP_BY_DIVISION
 is
 AccountFrom acs_account.acc_number%type;
 AccountTo acs_account.acc_number%type;
 PeriodFrom acs_period.per_no_period%type;
 PeriodTo acs_period.per_no_period%type;
 pYear acs_financial_year.fye_no_exercice%type;
 DivNum acs_account.acc_number%type;
 SansDivExclu number(1);
 DetailImput number (1);
 DocRecordFrom doc_record.rco_title%type;
 DocRecordTo doc_record.rco_title%type;

 begin
  AccountFrom:=PROCPARAM0;
  AccountTo:=PROCPARAM1;
  pYear:=PROCPARAM2;
  PeriodFrom:=PROCPARAM3;
  PeriodTo:=PROCPARAM4;
  DivNum:=PROCPARAM5;
  SansDivExclu:=PROCPARAM6;
  DetailImput:=PROCPARAM7;
  DocRecordFrom:=PROCPARAM8;
  DocRecordTo:=PROCPARAM9;

  -- Ouverture du curseur
  OPEN AREFCURSOR FOR
      select IMP.ACT_FINANCIAL_IMPUTATION_ID,
       FIN.ACC_NUMBER,
	   (select des_description_summary from acs_description des where imp.acs_financial_account_id=des.acs_account_id and des.pc_lang_id=1) acc_description,
       (SELECT DIV.ACC_NUMBER FROM ACS_ACCOUNT DIV WHERE DIV.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) DIV_NUMBER,
	   (select des_description_summary from acs_description des where IMP.IMF_ACS_DIVISION_ACCOUNT_ID=des.acs_account_id and des.pc_lang_id=1) div_description,
       (select rco_title from doc_record rec where imp.doc_record_id=rec.doc_record_id) rco_title,
	   (select rco_description from doc_record rec where imp.doc_record_id=rec.doc_record_id) rco_description,
       (SELECT DOC.DOC_NUMBER FROM ACT_DOCUMENT DOC WHERE DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID) DOC_NUMBER,
	   ACR_FUNCTIONS.GetFinancialImputationId(IMP.ACT_FINANCIAL_IMPUTATION_ID) FINANCIAL_IMPUTATION_ID,
	   (select acc.acc_number
	    from act_financial_imputation imp2, acs_account acc
		where ACR_FUNCTIONS.GetFinancialImputationId(IMP.ACT_FINANCIAL_IMPUTATION_ID)=imp2.act_financial_imputation_id
		and imp2.acs_financial_account_id=acc.acs_account_id) contre_ecriture,
       IMP.IMF_TYPE,
       IMP.IMF_PRIMARY,
       IMP.IMF_DESCRIPTION,
	   (select currency
        from acs_financial_currency fcur, pcs.pc_curr cur
        where imp.acs_acs_financial_currency_id=fcur.acs_financial_currency_id
        and fcur.pc_curr_id=cur.pc_curr_id) CURRENCY_MB,
       IMP.IMF_AMOUNT_LC_D,
       IMP.IMF_AMOUNT_LC_C,
       (select currency
        from acs_financial_currency fcur, pcs.pc_curr cur
        where imp.acs_financial_currency_id=fcur.acs_financial_currency_id
        and fcur.pc_curr_id=cur.pc_curr_id) CURRENCY_ME,
       IMP.IMF_AMOUNT_FC_D,
       IMP.IMF_AMOUNT_FC_C,
	   IMP.IMF_EXCHANGE_RATE,
       IMP.IMF_AMOUNT_EUR_D,
       IMP.IMF_AMOUNT_EUR_C,
       IMP.IMF_VALUE_DATE,
       IMP.IMF_TRANSACTION_DATE,
       IMP.C_GENRE_TRANSACTION,
       IMP.A_CONFIRM,
       IMP.A_DATECRE,
       IMP.A_DATEMOD,
       IMP.A_IDCRE,
       IMP.A_IDMOD,
       IMP.IMF_GENRE,
       IMP.IMF_BASE_PRICE,
       (SELECT JOU.JOU_NUMBER FROM ACT_JOURNAL JOU WHERE JOU.ACT_JOURNAL_ID = (SELECT DOC.ACT_JOURNAL_ID FROM ACT_DOCUMENT DOC WHERE DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID)) JOU_NUMBER,
       (SELECT JOU.JOU_DESCRIPTION FROM ACT_JOURNAL JOU WHERE JOU.ACT_JOURNAL_ID = (SELECT DOC.ACT_JOURNAL_ID FROM ACT_DOCUMENT DOC WHERE DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID)) JOU_DESCRIPTION,
       (select ETA.C_ETAT_JOURNAL
       from ACT_ETAT_JOURNAL ETA
       where ETA.ACT_JOURNAL_ID = (SELECT DOC.ACT_JOURNAL_ID FROM ACT_DOCUMENT DOC WHERE DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID)
         and ETA.C_SUB_SET      = 'ACC') C_ETAT_JOURNAL,
       (select SCA.C_TYPE_CUMUL
        from ACJ_SUB_SET_CAT SCA
        where SCA.ACJ_CATALOGUE_DOCUMENT_ID = (SELECT DOC.ACJ_CATALOGUE_DOCUMENT_ID FROM ACT_DOCUMENT DOC WHERE DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID)
          and SCA.C_SUB_SET                   = 'ACC') C_TYPE_CUMUL,
       PER.C_TYPE_PERIOD,
       DetailImput DETAIL_IMPUT
  from
       ACS_PERIOD                 PER,
       ACT_FINANCIAL_IMPUTATION   IMP,
       ACS_ACCOUNT                FIN,
       ACS_SUB_SET                SUB,
       ACS_FINANCIAL_YEAR         YEA
 where SUB.ACS_SUB_SET_ID              = FIN.ACS_SUB_SET_ID
   and SUB.C_SUB_SET                   = 'ACC'
   and FIN.ACC_NUMBER                 >= AccountFrom
   and FIN.ACC_NUMBER                 <= AccountTo
   and YEA.FYE_NO_EXERCICE            = pYear
   and PER.PER_NO_PERIOD	            >= PeriodFrom
   and PER.PER_NO_PERIOD	            <= PeriodTo
   and nvl((select rco_title from doc_record rec where imp.doc_record_id=rec.doc_record_id),'0') >= nvl(DocRecordFrom,'0')
   and nvl((select rco_title from doc_record rec where imp.doc_record_id=rec.doc_record_id),'zz') <= nvl(DocRecordTo,'zz')
   and FIN.ACS_ACCOUNT_ID              = IMP.ACS_FINANCIAL_ACCOUNT_ID
   and IMP.ACS_PERIOD_ID               = PER.ACS_PERIOD_ID
   AND PER.ACS_FINANCIAL_YEAR_ID       = YEA.ACS_FINANCIAL_YEAR_ID
   and not exists (select 1
   	   	   		   from acs_division_account div
				   where IMP.IMF_ACS_DIVISION_ACCOUNT_ID=div.acs_division_account_id
				   and div.DIC_DIV_ACC_CODE_1_ID=decode(SansDivExclu,1,'02','XX'))
   and (
        exists (select 1
                from acs_account acc
                where acc.acs_account_id=IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                and acc.acc_number=DivNum)
        or DivNum is null
        );


 end ind_c9_act_imp_by_doc_record;
