--------------------------------------------------------
--  DDL for Package Body IND_DOC_BILLING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_DOC_BILLING" is

 procedure ind_doc_bill_extract(BillDescr varchar2, DateRef date, DateDocument date, DateEcheance date, BillCateg varchar2, ActiveLines number)
 -- Extraction des données de la paie pour facturation
 is
  ExportNum number;
  vCount integer;
 begin
  -- Création d'un record d'importation
  select nvl(max(IND_DOC_BILL_IMPORTATION_ID),0)+1 into ExportNum
  from IND_DOC_BILL_IMPORTATION;

  insert into ind_doc_bill_importation (
  IND_DOC_BILL_IMPORTATION_ID,
  BILL_DESCR,
  PAR_REMIND_DATE,
  DMT_DATE_DOCUMENT,
  BILL_MODELE_CATEG,
  PAD_PAYMENT_DATE,
  A_IDCRE,
  A_DATECRE)
  select
  ExportNum,
  BillDescr,
  DateRef,
  DateDocument,
  BillCateg,
  DateEcheance,
  pcs.pc_init_session.GetUserIni,
  sysdate
  from dual;

  delete from ind_doc_bill_extract_tmp
  where ind_doc_bill_importation_id=ExportNum;

  insert into ind_doc_bill_extract_tmp (
  PAR_REMIND_DATE,
  DMT_DATE_DOCUMENT,
  DATE_EXTRACT_FROM,
  DATE_EXTRACT_TO,
  DATE_PERIOD_FROM,
  DATE_PERIOD_TO,
  MODELE_MAD,
  MODELE_NDF,
  MODELE_RECAP,
  BILL_MODELE_CATEG,
  BILL_TYPE,
  BILL_MONTH_EXTRACT,
  BILL_MONTH_PROJECT,
  BILL_MAJORATION,
  BILL_REGROUP,
  GOO_MAJOR_REFERENCE_FG,
  DOC_GAUGE_FC_ID,
  DOC_GAUGE_NC_ID,
  GOO_IS_FG,
  GOO_IS_SUBTOTAL,
  GOO_IS_MAJORATED,
  GOO_IS_EXCEPT,
  HRM_EMPLOYEE_ID,
  EMP_NUMBER,
  RCO_TITLE,
  ACC_NUMBER,
  DES_DESCRIPTION_SUMMARY,
  CURRENCY,
  BASE_AMOUNT_ME,
  BASE_AMOUNT_MB,
  EMC_VALUE_FROM,
  EMC_VALUE_TO,
  GOO_MAJOR_REFERENCE,
	DES_SHORT_DESCRIPTION,
  AMOUNT_MB,
  AMOUNT_ME,
  BILL_MODELE_ID,
  PAC_PERSON_ID,
  IND_DOC_BILL_IMPORTATION_ID,
  BILL_ORIGINE,
  DMT_CONTACT1,
  PAD_PAYMENT_DATE,
  DIC_IMP_FREE1_ID,
  GOO_MAJOR_REFERENCE_TAX,
  GOO_IS_TAX,
  FG_IS_TAX)
-- PARTIE SALAIRES
  select
  DateRef,
  DateDocument DMT_DATE_DOCUMENT,
  case
   when bip.bill_type='Réel'
   then add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT+1)
   else add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT)
  end date_extract_from,
  case
   when bip.bill_type='Réel'
   then last_day(DateRef)
   else trunc(DateRef,'MM')-1
  end date_extract_to,
  case
   when bip.bill_type='Réel'
   then add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT+1)
   else trunc(DateRef,'MM')
  end date_period_from,
  case
   when bip.bill_type='Réel'
   then last_day(DateRef)
   else last_day(add_months(trunc(DateRef,'MM'),bip.BILL_MONTH_PROJECT-1))
  end date_period_to,
  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_MAD',emp.hrm_person_id),cus.cus_free_zone1) modele_MAD,
  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_NDF',emp.hrm_person_id),cus.cus_free_zone2) modele_NDF,
  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_RECAP',emp.hrm_person_id),cus.cus_free_zone3) modele_RECAP,
  bip.BILL_MODELE_CATEG,
  bip.bill_type,
  bip.BILL_MONTH_EXTRACT,
  bip.BILL_MONTH_PROJECT,
  bip.BILL_MAJORATION,
  bip.BILL_REGROUP,
  bip.GOO_MAJOR_REFERENCE_FG,
  bip.DOC_GAUGE_FC_ID,
  bip.DOC_GAUGE_NC_ID,
  bit.GOO_IS_FG,
  bit.GOO_IS_SUBTOTAL,
  bit.GOO_IS_MAJORATED,
  bit.GOO_IS_EXCEPT,
  emp.hrm_person_id HRM_EMPLOYEE_ID,
  div.acc_number EMP_NUMBER,
  (select max(rco_title) from doc_record rec where imp.doc_record_id=rec.doc_record_id) HEB_DIV_NUMBER,
  (select max(acc_number) from acs_account acc where acc.acs_account_id=imp.acs_financial_account_id) DIC_GROUP1_ID,
  imf_description DIC_DESCR,
  case
   when bill_convert_mb=1
   then acs_function.GetLocalCurrencyName
   else (select currency
        from acs_financial_currency fcur, pcs.pc_curr cur
        where imp.acs_financial_currency_id=fcur.acs_financial_currency_id
        and fcur.pc_curr_id=cur.pc_curr_id)
   end CURRENCY,
  case
   when imp.acs_financial_currency_id=acs_function.GetLocalCurrencyId or bill_convert_mb=1
   then decode(GOO_IS_MAJORATED,1,(nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0))*(BILL_MAJORATION),nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0))
   else decode(GOO_IS_MAJORATED,1,(nvl(IMF_AMOUNT_FC_D,0)-nvl(IMF_AMOUNT_FC_C,0))*(BILL_MAJORATION),nvl(IMF_AMOUNT_FC_D,0)-nvl(IMF_AMOUNT_FC_C,0))
  end HIS_PAY_SUM_VAL_DEV,
  nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0) HIS_PAY_SUM_VAL_CHF,
  IMF_TRANSACTION_DATE EMC_VALUE_FROM,
  IMF_TRANSACTION_DATE EMC_VALUE_TO,
  bit.goo_major_reference,
  (select max(DES_SHORT_DESCRIPTION)
   from gco_good gco, gco_description gd
   where gco.gco_good_id=gd.gco_good_id
   and bit.goo_major_reference=gco.goo_major_reference
   and gd.pc_lang_id=1),
  case
   when bip.bill_type='Réel'
   then nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0)
   else (nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0)) * decode(bit.goo_is_except,0,bill_month_project,1)
  end amount_chf,
  case
   when bip.bill_type='Réel'
   then
    case
     when imp.acs_financial_currency_id=acs_function.GetLocalCurrencyId or bill_convert_mb=1
     then nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0)
     else nvl(IMF_AMOUNT_FC_D,0)-nvl(IMF_AMOUNT_FC_C,0)
    end
   else
    case
     when imp.acs_financial_currency_id=acs_function.GetLocalCurrencyId or bill_convert_mb=1
     then (nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0)) * decode(bit.goo_is_except,0,bill_month_project,1)
     else (nvl(IMF_AMOUNT_FC_D,0)-nvl(IMF_AMOUNT_FC_C,0)) * decode(bit.goo_is_except,0,bill_month_project,1)
    end
  end amount_dev,
  bip.bill_modele_id,
  per.pac_person_id,
  ExportNum,
  'Salaire',
  case
   when with_contact=1
   then (select max(ppe.per_name)
        from pac_person_association pas, pac_person ppe
        where pas.pac_pac_person_id=ppe.pac_person_id
        and per.pac_person_id=pas.pac_person_id)
   else null
  end dmt_contact1,
  DateEcheance,
  imp.DIC_IMP_FREE1_ID,
  bip.GOO_MAJOR_REFERENCE_TAX,
  bit.GOO_IS_TAX,
  bip.FG_IS_TAX
  from
  act_financial_imputation imp,
  acs_account div,
  hrm_person emp,
  pac_person per,
  pac_custom_partner cus,
  ind_doc_bill_modele_param bip,
  ind_doc_bill_modele_param_det bit
  where
  (select max(rco_title) from doc_record rec where imp.doc_record_id=rec.doc_record_id)=per.per_short_name
  --and (select max(acc_number) from acs_account acc where acc.acs_account_id=imp.imf_acs_division_account_id)=emp.emp_number
  and imp.imf_acs_division_account_id=div.acs_account_id
  and div.acc_number=emp.emp_number(+)
  and per.pac_person_id=cus.pac_custom_partner_id
  and (nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_MAD',emp.hrm_person_id),cus.cus_free_zone1)=bip.bill_modele_id
    or  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_NDF',emp.hrm_person_id),cus.cus_free_zone2)=bip.bill_modele_id
    or nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_RECAP',emp.hrm_person_id),cus.cus_free_zone3)=bip.bill_modele_id
    or nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_REC_NDF',emp.hrm_person_id),cus.DIC_STATISTIC_3_ID)=bip.bill_modele_id)
  and bip.bill_modele_id=bit.bill_modele_id
  and imp.acs_financial_account_id=bit.acs_account_id
  and bip.bill_modele_categ=BillCateg
  and imp.IMF_TRANSACTION_DATE <= case
                                   when bip.bill_type='Réel'
                                   then last_day(DateRef)
                                   else trunc(DateRef,'MM')-1
                                  end
        and imp.IMF_TRANSACTION_DATE >= case
                                 when bip.bill_type='Réel'
                                 then add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT+1)
                                 else add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT)
                                end
   and (
          (exists (select 1
              from act_document doc, acj_catalogue_document cat, ind_doc_bill_modele_param_cat bic
              where imp.act_document_id=doc.act_document_id
              and doc.acj_catalogue_document_id=cat.acj_catalogue_document_id
              and cat.acj_catalogue_document_id=bic.acj_catalogue_document_id
              and bip.bill_modele_id=bic.bill_modele_id
              and imp.acs_financial_account_id=bic.acs_account_id)
          and exists (select 1
              from ind_doc_bill_modele_param_cat bic
              where bip.bill_modele_id=bic.bill_modele_id
              and imp.acs_financial_account_id=bic.acs_account_id
              having count(*)>0)
            )
        or exists (select 1
            from ind_doc_bill_modele_param_cat bic
            where bip.bill_modele_id=bic.bill_modele_id
            and imp.acs_financial_account_id=bic.acs_account_id
            having count(*)=0)
        )
      UNION ALL
-- PARTIE COMPTA
  select
  DateRef,
  DateDocument DMT_DATE_DOCUMENT,
  case
   when bip.bill_type='Réel'
   then add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT+1)
   else add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT)
  end date_extract_from,
  case
   when bip.bill_type='Réel'
   then last_day(DateRef)
   else trunc(DateRef,'MM')-1
  end date_extract_to,
  case
   when bip.bill_type='Réel'
   then add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT+1)
   else trunc(DateRef,'MM')
  end date_period_from,
  case
   when bip.bill_type='Réel'
   then last_day(DateRef)
   else last_day(add_months(trunc(DateRef,'MM'),bip.BILL_MONTH_PROJECT-1))
  end date_period_to,
  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_MAD',emp.hrm_person_id),cus.cus_free_zone1) modele_MAD,
  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_NDF',emp.hrm_person_id),cus.cus_free_zone2) modele_NDF,
  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_RECAP',emp.hrm_person_id),cus.cus_free_zone3) modele_RECAP,
  bip.BILL_MODELE_CATEG,
  bip.bill_type,
  bip.BILL_MONTH_EXTRACT,
  bip.BILL_MONTH_PROJECT,
  bip.BILL_MAJORATION,
  bip.BILL_REGROUP,
  bip.GOO_MAJOR_REFERENCE_FG,
  bip.DOC_GAUGE_FC_ID,
  bip.DOC_GAUGE_NC_ID,
  bit.GOO_IS_FG,
  bit.GOO_IS_SUBTOTAL,
  bit.GOO_IS_MAJORATED,
  bit.GOO_IS_EXCEPT,
  emp.hrm_person_id HRM_EMPLOYEE_ID,
  div.acc_number EMP_NUMBER,
  (select max(rco_title) from doc_record rec where imp.doc_record_id=rec.doc_record_id) HEB_DIV_NUMBER,
  (select max(acc_number) from acs_account acc where acc.acs_account_id=imp.acs_financial_account_id) DIC_GROUP1_ID,
  imf_description DIC_DESCR,
  case
   when bit.bill_convert_mb=1
   then acs_function.GetLocalCurrencyName
   else (select currency
        from acs_financial_currency fcur, pcs.pc_curr cur
        where imp.acs_financial_currency_id=fcur.acs_financial_currency_id
        and fcur.pc_curr_id=cur.pc_curr_id)
  end CURRENCY,
  case
   when imp.acs_financial_currency_id=acs_function.GetLocalCurrencyId
   then nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0)
   else nvl(IMF_AMOUNT_FC_D,0)-nvl(IMF_AMOUNT_FC_C,0)
  end HIS_PAY_SUM_VAL_DEV,
  nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0) HIS_PAY_SUM_VAL_CHF,
  IMF_TRANSACTION_DATE EMC_VALUE_FROM,
  IMF_TRANSACTION_DATE EMC_VALUE_TO,
  bit.goo_major_reference,
  (select max(DES_SHORT_DESCRIPTION)
   from gco_good gco, gco_description gd
   where gco.gco_good_id=gd.gco_good_id
   and bit.goo_major_reference=gco.goo_major_reference
   and gd.pc_lang_id=1),
  nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0) amount_chf,
  case
   when imp.acs_financial_currency_id=acs_function.GetLocalCurrencyId or bit.bill_convert_mb=1
   then nvl(IMF_AMOUNT_LC_D,0)-nvl(IMF_AMOUNT_LC_C,0)
   else nvl(IMF_AMOUNT_FC_D,0)-nvl(IMF_AMOUNT_FC_C,0)
  end amount_dev,
  bip.bill_modele_id,
  per.pac_person_id,
  ExportNum,
  'Mouvements non lettrés',
  case
   when with_contact=1
   then (select max(ppe.per_name)
        from pac_person_association pas, pac_person ppe
        where pas.pac_pac_person_id=ppe.pac_person_id
        and per.pac_person_id=pas.pac_person_id)
   else null
  end dmt_contact1,
  DateEcheance,
  imp.DIC_IMP_FREE1_ID,
  bip.GOO_MAJOR_REFERENCE_TAX,
  bit.GOO_IS_TAX,
  bip.FG_IS_TAX
  from
  act_financial_imputation imp,
  acs_account div,
  hrm_person emp,
  pac_person per,
  pac_custom_partner cus,
  ind_doc_bill_modele_param bip,
  ind_doc_bill_modele_param_acc bit
  where
  (select max(rco_title) from doc_record rec where imp.doc_record_id=rec.doc_record_id)=per.per_short_name
  --and (select max(acc_number) from acs_account acc where acc.acs_account_id=imp.imf_acs_division_account_id)=emp.emp_number
  and imp.imf_acs_division_account_id=div.acs_account_id
  and div.acc_number=emp.emp_number(+)
  and per.pac_person_id=cus.pac_custom_partner_id
  and (nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_MAD',emp.hrm_person_id),cus.cus_free_zone1)=bip.bill_modele_id
    or  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_NDF',emp.hrm_person_id),cus.cus_free_zone2)=bip.bill_modele_id
    or nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_RECAP',emp.hrm_person_id),cus.cus_free_zone3)=bip.bill_modele_id
    or nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_REC_NDF',emp.hrm_person_id),cus.DIC_STATISTIC_3_ID)=bip.bill_modele_id)
  and bip.bill_modele_id=bit.bill_modele_id
  and imp.acs_financial_account_id=bit.acs_account_id
  and bip.bill_modele_categ=BillCateg
  and not exists (select 1
                 from act_lettering_detail let
                 where let.act_financial_imputation_id=imp.act_financial_imputation_id)
-- PARTIE SAISIE MANUELLE
UNION ALL
  select
  DateRef,
  DateDocument DMT_DATE_DOCUMENT,
  case
   when bip.bill_type='Réel'
   then add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT+1)
   else add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT)
  end date_extract_from,
  case
   when bip.bill_type='Réel'
   then last_day(DateRef)
   else trunc(DateRef,'MM')-1
  end date_extract_to,
  case
   when bip.bill_type='Réel'
   then add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT+1)
   else trunc(DateRef,'MM')
  end date_period_from,
  case
   when bip.bill_type='Réel'
   then last_day(DateRef)
   else last_day(add_months(trunc(DateRef,'MM'),bip.BILL_MONTH_PROJECT-1))
  end date_period_to,
  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_MAD',emp.hrm_person_id),cus.cus_free_zone1) modele_MAD,
  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_NDF',emp.hrm_person_id),cus.cus_free_zone2) modele_NDF,
  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_RECAP',emp.hrm_person_id),cus.cus_free_zone3) modele_RECAP,
  bip.BILL_MODELE_CATEG,
  bip.bill_type,
  bip.BILL_MONTH_EXTRACT,
  bip.BILL_MONTH_PROJECT,
  bip.BILL_MAJORATION,
  bip.BILL_REGROUP,
  bip.GOO_MAJOR_REFERENCE_FG,
  bip.DOC_GAUGE_FC_ID,
  bip.DOC_GAUGE_NC_ID,
  bit.GOO_IS_FG,
  bit.GOO_IS_SUBTOTAL,
  bit.GOO_IS_MAJORATED,
  bit.GOO_IS_EXCEPT,
  emp.hrm_person_id HRM_EMPLOYEE_ID,
  trim(fac.div_number) EMP_NUMBER,
  per.per_short_name HEB_DIV_NUMBER,
  to_char(fac.ind_doc_bill_entry_id) DIC_GROUP1_ID,
  fac.bill_comment DIC_DESCR,
  fac.CURRENCY,
  fac.HIS_PAY_SUM_VAL_DEV,
  fac.HIS_PAY_SUM_VAL_CHF,
  fac.EMC_VALUE_FROM,
  fac.EMC_VALUE_TO,
  bit.goo_major_reference,
  (select max(DES_SHORT_DESCRIPTION)
   from gco_good gco, gco_description gd
   where gco.gco_good_id=gd.gco_good_id
   and bit.goo_major_reference=gco.goo_major_reference
   and gd.pc_lang_id=1),
  case
   when bip.bill_type='Réel'
   then fac.HIS_PAY_SUM_VAL_CHF
   else fac.HIS_PAY_SUM_VAL_CHF * decode(bit.goo_is_except,0,bill_month_project,1)
  end amount_chf,
  case
   when bip.bill_type='Réel'
   then fac.HIS_PAY_SUM_VAL_DEV
   else fac.HIS_PAY_SUM_VAL_DEV * decode(bit.goo_is_except,0,bill_month_project,1)
  end amount_dev,
  bip.bill_modele_id,
  per.pac_person_id,
  ExportNum,
  'Saisie manuelle',
  case
   when with_contact=1
   then (select max(ppe.per_name)
        from pac_person_association pas, pac_person ppe
        where pas.pac_pac_person_id=ppe.pac_person_id
        and per.pac_person_id=pas.pac_person_id)
   else null
  end dmt_contact1,
  DateEcheance,
  fac.DIC_IMP_FREE1_ID,
  bip.GOO_MAJOR_REFERENCE_TAX,
  bit.GOO_IS_TAX,
  bip.FG_IS_TAX
  from
  ind_doc_bill_entry fac,
  pac_person per,
  hrm_person emp,
  pac_custom_partner cus,
  ind_doc_bill_modele_param bip,
  ind_doc_bill_modele_param_man bit
  where
  fac.pac_custom_partner_id=per.pac_person_id
  and per.pac_person_id=cus.pac_custom_partner_id
  and fac.div_number=emp.emp_number(+)
  --and (nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_MAD',emp.hrm_person_id),cus.cus_free_zone1)=bip.bill_modele_id
   -- or  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_NDF',emp.hrm_person_id),cus.cus_free_zone2)=bip.bill_modele_id
   -- or nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_RECAP',emp.hrm_person_id),cus.cus_free_zone3)=bip.bill_modele_id)
  --and bip.bill_modele_id in nvl((select min(bill_modele_id) from ind_doc_bill_modele_param_man),(select min(bill_modele_id) from ind_doc_bill_modele))
  and (nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_MAD',emp.hrm_person_id),cus.cus_free_zone1)=bit.bill_modele_id
    or  nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_NDF',emp.hrm_person_id),cus.cus_free_zone2)=bit.bill_modele_id
    or nvl(COM_VFIELDS_4_PRNT.GetVF2Value_char('HRM_PERSON','VFLD_EMP_BILL_MODELE_RECAP',emp.hrm_person_id),cus.cus_free_zone3)=bit.bill_modele_id)
  and bip.bill_modele_id=bit.bill_modele_id
  and fac.goo_major_reference=bit.goo_major_reference
  and fac.emc_value_from <= case
                             when bip.bill_type='Réel'
                             then last_day(DateRef)
                             else trunc(DateRef,'MM')-1
                            end
  and fac.emc_value_to >= case
                           when bip.bill_type='Réel'
                           then add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT+1)
                           else add_months(trunc(DateRef,'MM'),-bip.BILL_MONTH_EXTRACT)
                          end
  and bip.bill_modele_categ=BillCateg
  and (fac.ind_doc_bill_importation_id is null or elp_is_const=1)
  ;

 -- flag des saisies manuelles
 update ind_doc_bill_entry a
 set ind_doc_bill_importation_id=ExportNum
 where exists (select 1
              from ind_doc_bill_extract_tmp b
              where a.ind_doc_bill_entry_id=b.acc_number
              and b.bill_origine='Saisie manuelle'
              and b.ind_doc_bill_importation_id=ExportNum)
      ;

 -- Contrôle que des données sont retournées
 select count(*) into vCount
 from ind_doc_bill_extract_tmp
 where ind_doc_bill_importation_id=ExportNum;

 if vCount=0
  then
        delete from ind_doc_bill_importation
        where ind_doc_bill_importation_id=ExportNum;

        raise_application_error(-20001,chr(10)||'>>>>>>>>>>'||chr(10)||chr(10)||
                                      'Aucune donnée retournée pour les paramètres sélectionnés'||
                                      chr(10)||chr(10)||'>>>>>>>>>>'
                                );
 end if;


 -- Lancement procédure de calcul des frais de gestion
 ind_doc_billing.ind_doc_bill_fg(ExportNum);

 -- Lancement procédure de calcul des taxes
 ind_doc_billing.ind_doc_bill_tax(ExportNum);

 -- Lancement procédure permettant de structurer les données en documents
 ind_doc_billing.ind_doc_bill_structure(ExportNum, ActiveLines);

 -- Suppression des lignes à zéro
 delete from ind_doc_bill_position
 where IND_DOC_BILL_IMPORTATION_ID=ExportNum
 --and nvl(amount_chf,0)=0
 and nvl(amount_dev,0)=0;

 end ind_doc_bill_extract;

 procedure ind_doc_bill_file(BillDescr varchar2, DateDocument date, DateEcheance date, vDateFactFrom date, vDateFactTo date, vGaugeIdFC number, vGaugeIdNC number, vRegroup varchar2, FileDirectory varchar2, FileName varchar2)
 -- Reprise des données à facturer à partir d'un fichier
 is
  ExportNum number;
  vCount integer;
 begin
  -- Création d'un record d'importation
  select nvl(max(IND_DOC_BILL_IMPORTATION_ID),0)+1 into ExportNum
  from IND_DOC_BILL_IMPORTATION;

  -- Record d'entête
  insert into ind_doc_bill_importation (
  IND_DOC_BILL_IMPORTATION_ID,
  BILL_DESCR,
  PAR_REMIND_DATE,
  DMT_DATE_DOCUMENT,
  BILL_MODELE_CATEG,
  PAD_PAYMENT_DATE,
  A_IDCRE,
  A_DATECRE)
  select
  ExportNum,
  BillDescr,
  null,
  DateDocument,
  null,
  DateEcheance,
  pcs.pc_init_session.GetUserIni,
  sysdate
  from dual;

  -- remontée du fichier
  IND_REPRISE_FICHIER.LECTURE_FICHIER(FileDirectory, FileName, ExportNum);

  -- Détail
  delete from ind_doc_bill_extract_tmp
  where ind_doc_bill_importation_id=ExportNum;

  insert into ind_doc_bill_extract_tmp (
  PAR_REMIND_DATE,
  DMT_DATE_DOCUMENT,
  DATE_EXTRACT_FROM,
  DATE_EXTRACT_TO,
  DATE_PERIOD_FROM,
  DATE_PERIOD_TO,
  MODELE_MAD,
  MODELE_NDF,
  MODELE_RECAP,
  BILL_MODELE_CATEG,
  BILL_TYPE,
  BILL_MONTH_EXTRACT,
  BILL_MONTH_PROJECT,
  BILL_MAJORATION,
  BILL_REGROUP,
  GOO_MAJOR_REFERENCE_FG,
  DOC_GAUGE_FC_ID,
  DOC_GAUGE_NC_ID,
  GOO_IS_FG,
  GOO_IS_SUBTOTAL,
  GOO_IS_MAJORATED,
  GOO_IS_EXCEPT,
  HRM_EMPLOYEE_ID,
  EMP_NUMBER,
  RCO_TITLE,
  ACC_NUMBER,
  DES_DESCRIPTION_SUMMARY,
  CURRENCY,
  BASE_AMOUNT_ME,
  BASE_AMOUNT_MB,
  EMC_VALUE_FROM,
  EMC_VALUE_TO,
  GOO_MAJOR_REFERENCE,
	DES_SHORT_DESCRIPTION,
  AMOUNT_MB,
  AMOUNT_ME,
  BILL_MODELE_ID,
  PAC_PERSON_ID,
  IND_DOC_BILL_IMPORTATION_ID,
  BILL_ORIGINE,
  DMT_CONTACT1,
  PAD_PAYMENT_DATE)
  select
  DateDocument,
  DateDocument DMT_DATE_DOCUMENT,
  null date_extract_from,
  null date_extract_to,
  vDateFactFrom date_period_from,
  vDateFactTo date_period_to,
  null modele_MAD,
  null modele_NDF,
  null modele_RECAP,
  null BILL_MODELE_CATEG,
  null bill_type,
  null BILL_MONTH_EXTRACT,
  null BILL_MONTH_PROJECT,
  null BILL_MAJORATION,
  vRegroup BILL_REGROUP,
  null  GOO_MAJOR_REFERENCE_FG,
  vGaugeIdFC DOC_GAUGE_FC_ID,
  vGaugeIdNC DOC_GAUGE_NC_ID,
  null GOO_IS_FG,
  null GOO_IS_SUBTOTAL,
  null GOO_IS_MAJORATED,
  null GOO_IS_EXCEPT,
  (select hrm_person_id from hrm_person p where pcs.extractline(imp.ind_line,2,';')=p.emp_number) HRM_EMPLOYEE_ID,
  pcs.extractline(imp.ind_line,2,';') EMP_NUMBER,
  pcs.extractline(imp.ind_line,1,';') HEB_DIV_NUMBER,
  pcs.extractline(imp.ind_line,2,';') DIC_GROUP1_ID,
  'Importation fichier' DIC_DESCR,
  pcs.extractline(imp.ind_line,4,';') CURRENCY,
  pcs.extractline(imp.ind_line,5,';') HIS_PAY_SUM_VAL_DEV,
  case
   when pcs.extractline(imp.ind_line,4,';')=acs_function.GetLocalCurrencyName
   then pcs.extractline(imp.ind_line,5,';')
   else null
  end HIS_PAY_SUM_VAL_CHF,
  null EMC_VALUE_FROM,
  null EMC_VALUE_TO,
  pcs.extractline(imp.ind_line,3,';') goo_major_reference,
  (select max(DES_SHORT_DESCRIPTION)
   from gco_good gco, gco_description gd
   where gco.gco_good_id=gd.gco_good_id
   and pcs.extractline(imp.ind_line,3,';')=gco.goo_major_reference
   and gd.pc_lang_id=1),
  case
   when pcs.extractline(imp.ind_line,4,';')=acs_function.GetLocalCurrencyName
   then pcs.extractline(imp.ind_line,5,';')
   else null
  end amount_chf,
  pcs.extractline(imp.ind_line,5,';') amount_dev,
  null bill_modele_id,
  (select pac_person_id from pac_person p where pcs.extractline(imp.ind_line,1,';')=p.per_short_name) pac_person_id,
  ExportNum,
  'Fichier',
  (select max(ppe.per_name)
        from pac_person per, pac_person_association pas, pac_person ppe
        where pcs.extractline(imp.ind_line,1,';')=per.per_short_name
		and per.pac_person_id=pas.pac_person_id
		and pas.pac_pac_person_id=ppe.pac_person_id) dmt_contact1,
  DateEcheance
  from
  ind_fichier imp
  where
  imp.import_name=ExportNum;

  -- Lancement procédure permettant de structurer les données en documents
 ind_doc_billing.ind_doc_bill_structure(ExportNum, 1);

 end ind_doc_bill_file;

 procedure ind_doc_bill_fg(ExportNum number)
 --Calcul et insertion des frais de gestion dans la table d'export
 is

 begin

  -- FG de type montant
  insert into ind_doc_bill_extract_tmp (
  PAR_REMIND_DATE,
  DMT_DATE_DOCUMENT,
  DATE_EXTRACT_FROM,
  DATE_EXTRACT_TO,
  DATE_PERIOD_FROM,
  DATE_PERIOD_TO,
  MODELE_MAD,
  MODELE_NDF,
  MODELE_RECAP,
  BILL_MODELE_CATEG,
  BILL_TYPE,
  BILL_MONTH_EXTRACT,
  BILL_MONTH_PROJECT,
  BILL_MAJORATION,
  BILL_REGROUP,
  GOO_MAJOR_REFERENCE_FG,
  DOC_GAUGE_FC_ID,
  DOC_GAUGE_NC_ID,
  GOO_IS_FG,
  GOO_IS_SUBTOTAL,
  GOO_IS_MAJORATED,
  HRM_EMPLOYEE_ID,
  EMP_NUMBER,
  RCO_TITLE,
  ACC_NUMBER,
  DES_DESCRIPTION_SUMMARY,
  CURRENCY,
  BASE_AMOUNT_ME,
  BASE_AMOUNT_MB,
  EMC_VALUE_FROM,
  EMC_VALUE_TO,
  GOO_MAJOR_REFERENCE,
	DES_SHORT_DESCRIPTION,
  AMOUNT_MB,
  AMOUNT_ME,
  BILL_MODELE_ID,
  PAC_PERSON_ID,
  IND_DOC_BILL_IMPORTATION_ID,
  BILL_ORIGINE,
  DMT_CONTACT1,
  PAD_PAYMENT_DATE,
  DIC_IMP_FREE1_ID,
  GOO_MAJOR_REFERENCE_TAX,
  GOO_IS_TAX,
  FG_IS_TAX)
  select
  distinct
  a.PAR_REMIND_DATE,
  a.DMT_DATE_DOCUMENT,
  a.DATE_EXTRACT_FROM,
  a.DATE_EXTRACT_TO,
  a.DATE_PERIOD_FROM,
  a.DATE_PERIOD_TO,
  a.MODELE_MAD,
  a.MODELE_NDF,
  a.MODELE_RECAP,
  a.BILL_MODELE_CATEG,
  a.BILL_TYPE,
  a.BILL_MONTH_EXTRACT,
  a.BILL_MONTH_PROJECT,
  a.BILL_MAJORATION,
  a.BILL_REGROUP,
  a.GOO_MAJOR_REFERENCE_FG,
  a.DOC_GAUGE_FC_ID,
  a.DOC_GAUGE_NC_ID,
  0 GOO_IS_FG,  -- table détail (multi rows)
  0 GOO_IS_SUBTOTAL, -- table détail (multi rows)
  0 GOO_IS_MAJORATED, -- table détail (multi rows)
  a.HRM_EMPLOYEE_ID,
  a.EMP_NUMBER,
  nvl(d.per_short_name,c.per_short_name) rco_title,
  'FG' ACC_NUMBER,
  'Frais de gestion' DES_DESCRIPTION_SUMMARY,
  nvl(d.dic_statistic_2_id, c.dic_statistic_2_id) CURRENCY,
  nvl(to_number(nvl(d.cus_free_zone4,c.cus_free_zone4)),0) BASE_AMOUNT_ME,
  case
   when nvl(d.dic_statistic_2_id, c.dic_statistic_2_id)=acs_function.GetLocalCurrencyName
   then nvl(to_number(nvl(d.cus_free_zone4,c.cus_free_zone4)),0)
   else 0
  end BASE_AMOUNT_MB,
  TRUNC(a.EMC_VALUE_FROM,'MM'),
  last_day(a.EMC_VALUE_TO),
  a.GOO_MAJOR_REFERENCE_FG GOO_MAJOR_REFERENCE,
  (select max(DES_SHORT_DESCRIPTION)
     from gco_good gco, gco_description gd
     where gco.gco_good_id=gd.gco_good_id
     and a.goo_major_reference_fg=gco.goo_major_reference
     and gd.pc_lang_id=1) DES_SHORT_DESCRIPTION,
  case
   when nvl(d.dic_statistic_2_id, c.dic_statistic_2_id)=acs_function.GetLocalCurrencyName
   then nvl(
   			decode(a.bill_type,'Prévisionnel',a.bill_month_project,'Réel',1)
			*nvl(to_number(nvl(d.cus_free_zone4,c.cus_free_zone4)),0)
			,0)
   else 0
  end AMOUNT_MB,
  nvl(
  	  decode(a.bill_type,'Prévisionnel',a.bill_month_project,'Réel',1)
	  *nvl(to_number(nvl(d.cus_free_zone4,c.cus_free_zone4)),0)
	 ,0) AMOUNT_ME,
  a.BILL_MODELE_ID,
  nvl(d.pac_person_id,c.pac_person_id) pac_person_id,
  a.IND_DOC_BILL_IMPORTATION_ID,
  'Frais de gestion' BILL_ORIGINE,
  (select max(ppe.per_name)
        from pac_person_association pas, pac_person ppe
        where pas.pac_pac_person_id=ppe.pac_person_id
        and nvl(d.pac_person_id,c.pac_person_id)=pas.pac_person_id) dmt_contact1,
  a.pad_payment_date,
  a.DIC_IMP_FREE1_ID,
  a.GOO_MAJOR_REFERENCE_TAX,
  a.FG_IS_TAX GOO_IS_TAX,
  a.FG_IS_TAX
  from
  -- TABLE: tmp
  ind_doc_bill_extract_tmp a,
  -- TABLE: Groupes de répartitions
  (select
    max(eeb_rco_title) eeb_rco_title,
    emc.hrm_employee_id,
    pac.pac_person_id
    from
    hrm_employee_const emc,
    hrm_constants con,
    hrm_employee_elem_break eeb,
    pac_person pac
    where
    emc.hrm_constants_id=con.hrm_constants_id
    and emc.hrm_employee_const_id=eeb.hrm_emp_elements_id
    and eeb.eeb_rco_title=pac.per_short_name
    and con_code='ConEm0_GRP_Fact'
    and emc_value_from<=trunc(sysdate)
    and emc_value_to>=trunc(sysdate)
    and emc_active=1
    group by emc.hrm_employee_id,
    pac.pac_person_id) b,
  -- TABLE: custom pour lien sur tmp
  (select p1.pac_person_id pac_person_source_id,
    nvl(p2.pac_person_id,p1.pac_person_id) pac_person_id,
    nvl(p2.per_short_name,p1.per_short_name) per_short_name,
    nvl(c2.cus_free_zone4,c1.cus_free_zone4) cus_free_zone4,
    nvl(c1.cus_free_zone5,c1.cus_free_zone5) cus_free_zone5,
    nvl(c1.dic_statistic_1_id,c1.dic_statistic_1_id) dic_statistic_1_id,
    nvl(c1.dic_statistic_2_id,c1.dic_statistic_2_id) dic_statistic_2_id
    from pac_person p1, pac_custom_partner c1, pac_custom_partner c2, pac_person p2
    where p1.pac_person_id=c1.pac_custom_partner_id
    and c1.cus_free_zone5=c2.pac_custom_partner_id(+)
    and c2.pac_custom_partner_id=p2.pac_person_id(+)) c,
  -- TABLE: custom pour lien sur GRP répart
  (select p1.pac_person_id pac_person_source_id,
    nvl(p2.pac_person_id,p1.pac_person_id) pac_person_id,
    nvl(p2.per_short_name,p1.per_short_name) per_short_name,
    nvl(c2.cus_free_zone4,c1.cus_free_zone4) cus_free_zone4,
    nvl(c1.cus_free_zone5,c1.cus_free_zone5) cus_free_zone5,
    nvl(c1.dic_statistic_1_id,c1.dic_statistic_1_id) dic_statistic_1_id,
    nvl(c1.dic_statistic_2_id,c1.dic_statistic_2_id) dic_statistic_2_id
    from pac_person p1, pac_custom_partner c1, pac_custom_partner c2, pac_person p2
    where p1.pac_person_id=c1.pac_custom_partner_id
    and c1.cus_free_zone5=c2.pac_custom_partner_id(+)
    and c2.pac_custom_partner_id=p2.pac_person_id(+)) d
  where
  a.hrm_employee_id=b.hrm_employee_id(+)
  and a.pac_person_id=c.pac_person_source_id
  and b.pac_person_id=d.pac_person_source_id(+)
  and ind_doc_bill_importation_id=ExportNum
  and a.GOO_MAJOR_REFERENCE_FG is not null
  --and a.bill_type='Prévisionnel'
  and nvl(d.dic_statistic_1_id,c.dic_statistic_1_id)='Montant';

  -- FG de type pourcent
  insert into ind_doc_bill_extract_tmp (
  PAR_REMIND_DATE,
  DMT_DATE_DOCUMENT,
  DATE_EXTRACT_FROM,
  DATE_EXTRACT_TO,
  DATE_PERIOD_FROM,
  DATE_PERIOD_TO,
  MODELE_MAD,
  MODELE_NDF,
  MODELE_RECAP,
  BILL_MODELE_CATEG,
  BILL_TYPE,
  BILL_MONTH_EXTRACT,
  BILL_MONTH_PROJECT,
  BILL_MAJORATION,
  BILL_REGROUP,
  GOO_MAJOR_REFERENCE_FG,
  DOC_GAUGE_FC_ID,
  DOC_GAUGE_NC_ID,
  GOO_IS_FG,
  GOO_IS_SUBTOTAL,
  GOO_IS_MAJORATED,
  HRM_EMPLOYEE_ID,
  EMP_NUMBER,
  RCO_TITLE,
  ACC_NUMBER,
  DES_DESCRIPTION_SUMMARY,
  CURRENCY,
  BASE_AMOUNT_ME,
  BASE_AMOUNT_MB,
  EMC_VALUE_FROM,
  EMC_VALUE_TO,
  GOO_MAJOR_REFERENCE,
	DES_SHORT_DESCRIPTION,
  AMOUNT_MB,
  AMOUNT_ME,
  BILL_MODELE_ID,
  PAC_PERSON_ID,
  IND_DOC_BILL_IMPORTATION_ID,
  BILL_ORIGINE,
  DMT_CONTACT1,
  PAD_PAYMENT_DATE,
  DIC_IMP_FREE1_ID,
  GOO_MAJOR_REFERENCE_TAX,
  GOO_IS_TAX,
  FG_IS_TAX)
  select
  a.PAR_REMIND_DATE,
  a.DMT_DATE_DOCUMENT,
  a.DATE_EXTRACT_FROM,
  a.DATE_EXTRACT_TO,
  a.DATE_PERIOD_FROM,
  a.DATE_PERIOD_TO,
  a.MODELE_MAD,
  a.MODELE_NDF,
  a.MODELE_RECAP,
  a.BILL_MODELE_CATEG,
  a.BILL_TYPE,
  a.BILL_MONTH_EXTRACT,
  a.BILL_MONTH_PROJECT,
  a.BILL_MAJORATION,
  a.BILL_REGROUP,
  a.GOO_MAJOR_REFERENCE_FG,
  a.DOC_GAUGE_FC_ID,
  a.DOC_GAUGE_NC_ID,
  0 GOO_IS_FG,  -- table détail (multi rows)
  0 GOO_IS_SUBTOTAL, -- table détail (multi rows)
  0 GOO_IS_MAJORATED, -- table détail (multi rows)
  a.HRM_EMPLOYEE_ID,
  a.EMP_NUMBER,
  nvl(d.per_short_name,c.per_short_name) rco_title,
  'FG' ACC_NUMBER,
  'Frais de gestion' DES_DESCRIPTION_SUMMARY,
  a.currency CURRENCY,
  nvl(round(sum(BASE_AMOUNT_ME)*to_number(nvl(d.cus_free_zone4,c.cus_free_zone4))/100,2),0) BASE_AMOUNT_ME,
  nvl(round(sum(BASE_AMOUNT_MB)*to_number(nvl(d.cus_free_zone4,c.cus_free_zone4))/100,2),0) BASE_AMOUNT_MB,
  trunc(a.EMC_VALUE_FROM,'MM'),
  last_day(a.EMC_VALUE_TO),
  a.GOO_MAJOR_REFERENCE_FG GOO_MAJOR_REFERENCE,
  'Frais de gestion' DES_SHORT_DESCRIPTION,
  nvl(round(sum(AMOUNT_MB)*to_number(nvl(d.cus_free_zone4,c.cus_free_zone4))/100,2),0) AMOUNT_MB,
  nvl(round(sum(AMOUNT_ME)*to_number(nvl(d.cus_free_zone4,c.cus_free_zone4))/100,2),0) AMOUNT_ME,
  a.BILL_MODELE_ID,
  nvl(d.pac_person_id,c.pac_person_id) pac_person_id,
  a.IND_DOC_BILL_IMPORTATION_ID,
  'Frais de gestion' BILL_ORIGINE,
  --(select max(ppe.per_name)
   --     from pac_person_association pas, pac_person ppe
  --      where pas.pac_pac_person_id=ppe.pac_person_id
   --     and nvl(d.pac_person_id,c.pac_person_id)=pas.pac_person_id) dmt_contact1,
  a.DMT_CONTACT1,
  a.pad_payment_date,
  a.DIC_IMP_FREE1_ID,
  p.GOO_MAJOR_REFERENCE_TAX,
  p.FG_IS_TAX GOO_IS_TAX,
  p.FG_IS_TAX
  from
  -- TABLE: tmp
  ind_doc_bill_extract_tmp a,
  ind_doc_bill_modele_param p,
  -- TABLE: Groupes de répartitions
  (select
    max(eeb_rco_title) eeb_rco_title,
    emc.hrm_employee_id,
    pac.pac_person_id
    from
    hrm_employee_const emc,
    hrm_constants con,
    hrm_employee_elem_break eeb,
    pac_person pac
    where
    emc.hrm_constants_id=con.hrm_constants_id
    and emc.hrm_employee_const_id=eeb.hrm_emp_elements_id
    and eeb.eeb_rco_title=pac.per_short_name
    and con_code='ConEm0_GRP_Fact'
    and emc_value_from<=trunc(sysdate)
    and emc_value_to>=trunc(sysdate)
    and emc_active=1
    group by emc.hrm_employee_id,
    pac.pac_person_id) b,
  -- TABLE: custom pour lien sur tmp
  (select p1.pac_person_id pac_person_source_id,
    nvl(p2.pac_person_id,p1.pac_person_id) pac_person_id,
    nvl(p2.per_short_name,p1.per_short_name) per_short_name,
    nvl(c2.cus_free_zone4,c1.cus_free_zone4) cus_free_zone4,
    nvl(c1.cus_free_zone5,c1.cus_free_zone5) cus_free_zone5,
    nvl(c1.dic_statistic_1_id,c1.dic_statistic_1_id) dic_statistic_1_id,
    nvl(c1.dic_statistic_2_id,c1.dic_statistic_2_id) dic_statistic_2_id
    from pac_person p1, pac_custom_partner c1, pac_custom_partner c2, pac_person p2
    where p1.pac_person_id=c1.pac_custom_partner_id
    and c1.cus_free_zone5=c2.pac_custom_partner_id(+)
    and c2.pac_custom_partner_id=p2.pac_person_id(+)) c,
  -- TABLE: custom pour lien sur GRP répart
  (select p1.pac_person_id pac_person_source_id,
    nvl(p2.pac_person_id,p1.pac_person_id) pac_person_id,
    nvl(p2.per_short_name,p1.per_short_name) per_short_name,
    nvl(c2.cus_free_zone4,c1.cus_free_zone4) cus_free_zone4,
    nvl(c1.cus_free_zone5,c1.cus_free_zone5) cus_free_zone5,
    nvl(c1.dic_statistic_1_id,c1.dic_statistic_1_id) dic_statistic_1_id,
    nvl(c1.dic_statistic_2_id,c1.dic_statistic_2_id) dic_statistic_2_id
    from pac_person p1, pac_custom_partner c1, pac_custom_partner c2, pac_person p2
    where p1.pac_person_id=c1.pac_custom_partner_id
    and c1.cus_free_zone5=c2.pac_custom_partner_id(+)
    and c2.pac_custom_partner_id=p2.pac_person_id(+)) d
  where
  a.bill_modele_id=p.bill_modele_id
  and a.hrm_employee_id=b.hrm_employee_id(+)
  and a.pac_person_id=c.pac_person_source_id
  and b.pac_person_id=d.pac_person_source_id(+)
  and nvl(d.dic_statistic_1_id,c.dic_statistic_1_id)='Pourcent'
  and ind_doc_bill_importation_id=ExportNum
  and a.GOO_MAJOR_REFERENCE_FG is not null
  and a.goo_is_fg=1
  group by a.PAR_REMIND_DATE,
  a.PAR_REMIND_DATE,
  a.DMT_DATE_DOCUMENT,
  a.DATE_EXTRACT_FROM,
  a.DATE_EXTRACT_TO,
  a.DATE_PERIOD_FROM,
  a.DATE_PERIOD_TO,
  a.MODELE_MAD,
  a.MODELE_NDF,
  a.MODELE_RECAP,
  a.BILL_MODELE_CATEG,
  a.BILL_TYPE,
  a.BILL_MONTH_EXTRACT,
  a.BILL_MONTH_PROJECT,
  a.BILL_MAJORATION,
  a.BILL_REGROUP,
  a.GOO_MAJOR_REFERENCE_FG,
  a.DOC_GAUGE_FC_ID,
  a.DOC_GAUGE_NC_ID,
  0 ,  -- table détail (multi rows)
  0 , -- table détail (multi rows)
  0 , -- table détail (multi rows)
  a.HRM_EMPLOYEE_ID,
  a.EMP_NUMBER,
  nvl(d.per_short_name,c.per_short_name),
  a.currency ,
  trunc(a.EMC_VALUE_FROM,'MM'),
  last_day(a.EMC_VALUE_TO),
  a.GOO_MAJOR_REFERENCE_FG ,
  a.BILL_MODELE_ID,
  nvl(d.pac_person_id,c.pac_person_id) ,
  a.IND_DOC_BILL_IMPORTATION_ID,
  nvl(d.cus_free_zone4,c.cus_free_zone4),
  a.DMT_CONTACT1,
  a.pad_payment_date,
  a.DIC_IMP_FREE1_ID,
  p.GOO_MAJOR_REFERENCE_TAX,
  p.FG_IS_TAX;

  -- Pour les clients dont les FG sont refacturés à aux-même -> mettre sur facture séparée
  update ind_doc_bill_extract_tmp a
  set DMT_CONTACT1=nvl(DMT_CONTACT1,'')||'  '
  where IND_DOC_BILL_IMPORTATION_ID=ExportNum
  and BILL_ORIGINE='Frais de gestion'
  and exists (select 1
              from pac_custom_partner cus
              where a.pac_person_id=cus.pac_custom_partner_id
              and cus.pac_custom_partner_id=cus_free_zone5);

 end ind_doc_bill_fg;

 procedure ind_doc_bill_tax(ExportNum number)
 --Calcul et insertion de l'article de taxe suppl. dans la table d'export
 is

 begin

  insert into ind_doc_bill_extract_tmp (
  PAR_REMIND_DATE,
  DMT_DATE_DOCUMENT,
  DATE_EXTRACT_FROM,
  DATE_EXTRACT_TO,
  DATE_PERIOD_FROM,
  DATE_PERIOD_TO,
  MODELE_MAD,
  MODELE_NDF,
  MODELE_RECAP,
  BILL_MODELE_CATEG,
  BILL_TYPE,
  BILL_MONTH_EXTRACT,
  BILL_MONTH_PROJECT,
  BILL_MAJORATION,
  BILL_REGROUP,
  GOO_MAJOR_REFERENCE_FG,
  DOC_GAUGE_FC_ID,
  DOC_GAUGE_NC_ID,
  GOO_IS_FG,
  GOO_IS_SUBTOTAL,
  GOO_IS_MAJORATED,
  HRM_EMPLOYEE_ID,
  EMP_NUMBER,
  RCO_TITLE,
  ACC_NUMBER,
  DES_DESCRIPTION_SUMMARY,
  CURRENCY,
  BASE_AMOUNT_ME,
  BASE_AMOUNT_MB,
  EMC_VALUE_FROM,
  EMC_VALUE_TO,
  GOO_MAJOR_REFERENCE,
	DES_SHORT_DESCRIPTION,
  AMOUNT_MB,
  AMOUNT_ME,
  BILL_MODELE_ID,
  PAC_PERSON_ID,
  IND_DOC_BILL_IMPORTATION_ID,
  BILL_ORIGINE,
  DMT_CONTACT1,
  PAD_PAYMENT_DATE,
  DIC_IMP_FREE1_ID,
  GOO_MAJOR_REFERENCE_TAX,
  GOO_IS_TAX,
  FG_IS_TAX)
  select
  a.PAR_REMIND_DATE,
  a.DMT_DATE_DOCUMENT,
  a.DATE_EXTRACT_FROM,
  a.DATE_EXTRACT_TO,
  a.DATE_PERIOD_FROM,
  a.DATE_PERIOD_TO,
  a.MODELE_MAD,
  a.MODELE_NDF,
  a.MODELE_RECAP,
  a.BILL_MODELE_CATEG,
  a.BILL_TYPE,
  a.BILL_MONTH_EXTRACT,
  a.BILL_MONTH_PROJECT,
  a.BILL_MAJORATION,
  a.BILL_REGROUP,
  a.GOO_MAJOR_REFERENCE_FG,
  a.DOC_GAUGE_FC_ID,
  a.DOC_GAUGE_NC_ID,
  0 GOO_IS_FG,  -- table détail (multi rows)
  0 GOO_IS_SUBTOTAL, -- table détail (multi rows)
  0 GOO_IS_MAJORATED, -- table détail (multi rows)
  a.HRM_EMPLOYEE_ID,
  a.EMP_NUMBER,
  nvl(d.per_short_name,c.per_short_name) rco_title,
  'TAX' ACC_NUMBER,
  'Taxe (taux '||nvl(d.cus_free_zone4,c.cus_free_zone4)||'% - Montant soumis (ME)'||sum(BASE_AMOUNT_ME)||')' DES_DESCRIPTION_SUMMARY,
  a.currency CURRENCY,
  nvl(round(sum(BASE_AMOUNT_ME)*to_number(nvl(d.cus_free_zone4,c.cus_free_zone4))/100,2),0) BASE_AMOUNT_ME,
  nvl(round(sum(BASE_AMOUNT_MB)*to_number(nvl(d.cus_free_zone4,c.cus_free_zone4))/100,2),0) BASE_AMOUNT_MB,
  trunc(a.EMC_VALUE_FROM,'MM'),
  last_day(a.EMC_VALUE_TO),
  a.GOO_MAJOR_REFERENCE_TAX GOO_MAJOR_REFERENCE,
  'Taxe'  DES_SHORT_DESCRIPTION,
  nvl(round(sum(AMOUNT_MB)*to_number(nvl(d.cus_free_zone4,c.cus_free_zone4))/100,2),0) AMOUNT_MB,
  nvl(round(sum(AMOUNT_ME)*to_number(nvl(d.cus_free_zone4,c.cus_free_zone4))/100,2),0) AMOUNT_ME,
  a.BILL_MODELE_ID,
  nvl(d.pac_person_id,c.pac_person_id) pac_person_id,
  a.IND_DOC_BILL_IMPORTATION_ID,
  'Taxe' BILL_ORIGINE,
  a.DMT_CONTACT1,
  a.pad_payment_date,
  a.DIC_IMP_FREE1_ID,
  p.GOO_MAJOR_REFERENCE_TAX,
  p.FG_IS_TAX GOO_IS_TAX,
  p.FG_IS_TAX
  from
  -- TABLE: tmp
  ind_doc_bill_extract_tmp a,
  ind_doc_bill_modele_param p,
  -- TABLE: Groupes de répartitions
  (select
    max(eeb_rco_title) eeb_rco_title,
    emc.hrm_employee_id,
    pac.pac_person_id
    from
    hrm_employee_const emc,
    hrm_constants con,
    hrm_employee_elem_break eeb,
    pac_person pac
    where
    emc.hrm_constants_id=con.hrm_constants_id
    and emc.hrm_employee_const_id=eeb.hrm_emp_elements_id
    and eeb.eeb_rco_title=pac.per_short_name
    and con_code='ConEm0_GRP_Fact'
    and emc_value_from<=trunc(sysdate)
    and emc_value_to>=trunc(sysdate)
    and emc_active=1
    group by emc.hrm_employee_id,
    pac.pac_person_id) b,
    (select p1.pac_person_id pac_person_source_id,
    nvl(p2.pac_person_id,p1.pac_person_id) pac_person_id,
    nvl(p2.per_short_name,p1.per_short_name) per_short_name,
    decode(c2.pac_custom_partner_id,null,
          (select max(num_code) from pac_number_code n
                 where c1.pac_custom_partner_id=n.pac_person_id
                 and n.DIC_NUMBER_CODE_TYP_ID='TauxTaxe'),
          (select max(num_code) from pac_number_code n
                 where c2.pac_custom_partner_id=n.pac_person_id
                 and n.DIC_NUMBER_CODE_TYP_ID='TauxTaxe')) cus_free_zone4,
    nvl(c1.cus_free_zone5,c1.cus_free_zone5) cus_free_zone5,
    nvl(c1.dic_statistic_1_id,c1.dic_statistic_1_id) dic_statistic_1_id,
    nvl(c1.dic_statistic_2_id,c1.dic_statistic_2_id) dic_statistic_2_id
    from pac_person p1, pac_custom_partner c1, pac_custom_partner c2, pac_person p2
    where p1.pac_person_id=c1.pac_custom_partner_id
    and c1.cus_free_zone5=c2.pac_custom_partner_id(+)
    and c2.pac_custom_partner_id=p2.pac_person_id(+)) c,
  -- TABLE: custom pour lien sur GRP répart
  (select p1.pac_person_id pac_person_source_id,
    nvl(p2.pac_person_id,p1.pac_person_id) pac_person_id,
    nvl(p2.per_short_name,p1.per_short_name) per_short_name,
    decode(c2.pac_custom_partner_id,null,
          (select max(num_code) from pac_number_code n
                 where c1.pac_custom_partner_id=n.pac_person_id
                 and n.DIC_NUMBER_CODE_TYP_ID='TauxTaxe'),
          (select max(num_code) from pac_number_code n
                 where c2.pac_custom_partner_id=n.pac_person_id
                 and n.DIC_NUMBER_CODE_TYP_ID='TauxTaxe')) cus_free_zone4,
    nvl(c1.cus_free_zone5,c1.cus_free_zone5) cus_free_zone5,
    nvl(c1.dic_statistic_1_id,c1.dic_statistic_1_id) dic_statistic_1_id,
    nvl(c1.dic_statistic_2_id,c1.dic_statistic_2_id) dic_statistic_2_id
    from pac_person p1, pac_custom_partner c1, pac_custom_partner c2, pac_person p2
    where p1.pac_person_id=c1.pac_custom_partner_id
    and c1.cus_free_zone5=c2.pac_custom_partner_id(+)
    and c2.pac_custom_partner_id=p2.pac_person_id(+)) d
  where
  a.bill_modele_id=p.bill_modele_id
  and a.hrm_employee_id=b.hrm_employee_id(+)
  and a.pac_person_id=c.pac_person_source_id
  and b.pac_person_id=d.pac_person_source_id(+)
  and ind_doc_bill_importation_id=ExportNum
  and a.GOO_MAJOR_REFERENCE_TAX is not null
  and a.goo_is_tax=1
  group by a.PAR_REMIND_DATE,
  a.PAR_REMIND_DATE,
  a.DMT_DATE_DOCUMENT,
  a.DATE_EXTRACT_FROM,
  a.DATE_EXTRACT_TO,
  a.DATE_PERIOD_FROM,
  a.DATE_PERIOD_TO,
  a.MODELE_MAD,
  a.MODELE_NDF,
  a.MODELE_RECAP,
  a.BILL_MODELE_CATEG,
  a.BILL_TYPE,
  a.BILL_MONTH_EXTRACT,
  a.BILL_MONTH_PROJECT,
  a.BILL_MAJORATION,
  a.BILL_REGROUP,
  a.GOO_MAJOR_REFERENCE_FG,
  a.GOO_MAJOR_REFERENCE_TAX,
  a.DOC_GAUGE_FC_ID,
  a.DOC_GAUGE_NC_ID,
  0 ,  -- table détail (multi rows)
  0 , -- table détail (multi rows)
  0 , -- table détail (multi rows)
  a.HRM_EMPLOYEE_ID,
  a.EMP_NUMBER,
  nvl(d.per_short_name,c.per_short_name),
  a.currency ,
  trunc(a.EMC_VALUE_FROM,'MM'),
  last_day(a.EMC_VALUE_TO),
  a.GOO_MAJOR_REFERENCE_FG ,
  a.BILL_MODELE_ID,
  nvl(d.pac_person_id,c.pac_person_id) ,
  a.IND_DOC_BILL_IMPORTATION_ID,
  nvl(d.cus_free_zone4,c.cus_free_zone4),
  a.DMT_CONTACT1,
  a.pad_payment_date,
  a.DIC_IMP_FREE1_ID,
  p.GOO_MAJOR_REFERENCE_TAX,
  p.FG_IS_TAX;

  -- Pour les clients dont les FG sont refacturés à aux-même -> mettre sur facture séparée
  update ind_doc_bill_extract_tmp a
  set DMT_CONTACT1=nvl(DMT_CONTACT1,'')||'  '
  where IND_DOC_BILL_IMPORTATION_ID=ExportNum
  and BILL_ORIGINE='Taxe'
  and exists (select 1
              from pac_custom_partner cus
              where a.pac_person_id=cus.pac_custom_partner_id
              and cus.pac_custom_partner_id=cus_free_zone5);

 end ind_doc_bill_tax;

 procedure ind_doc_bill_structure(ExportNum number, ActiveLines number)
 -- Structure les données extraites par document (Entête/Positions) selon les règles de facturation
 is
  -- Curseur Factures globales
  cursor CurGlobal is
  select
  bill_modele_id,
  DMT_DATE_DOCUMENT,
  rco_title,
  pac_person_id,
  currency,
  doc_gauge_fc_id,
  doc_gauge_nc_id,
  date_period_from,
  date_period_to,
  dmt_contact1,
  pad_payment_date,
  sum(amount_me) total
  from ind_doc_bill_extract_tmp
  where bill_regroup='Global'
  and IND_DOC_BILL_IMPORTATION_ID=ExportNum
  group by bill_modele_id,
  DMT_DATE_DOCUMENT,
  rco_title,
  pac_person_id,
  currency,
  doc_gauge_fc_id,
  doc_gauge_nc_id,
  date_period_from,
  date_period_to,
  dmt_contact1,
  pad_payment_date;

  -- Curseur Factures individuelles
  cursor CurIndividuel is
  select
  bill_modele_id,
  DMT_DATE_DOCUMENT,
  rco_title,
  pac_person_id,
  currency,
  doc_gauge_fc_id,
  doc_gauge_nc_id,
  emp_number,
  hrm_employee_id,
  date_period_from,
  date_period_to,
  dmt_contact1,
  pad_payment_date,
  sum(amount_me) total
  from ind_doc_bill_extract_tmp
  where bill_regroup='Individuel'
  and IND_DOC_BILL_IMPORTATION_ID=ExportNum
  group by bill_modele_id,
  dmt_date_document,
  rco_title,
  pac_person_id,
  currency,
  doc_gauge_fc_id,
  doc_gauge_nc_id,
  emp_number,
  hrm_employee_id,
  date_period_from,
  date_period_to,
  dmt_contact1,
  pad_payment_date;

  DocNumber varchar2(30);

 begin

  -- Traitement des Factures globales
  for RowGlobal in CurGlobal
  loop

   -- Création No document
   select 'OE-'||lpad(nvl(max(to_number(replace(doc_number,'OE-',''))),0)+1,8,'0') into DocNumber
   from ind_doc_bill_header;
   --select 'OE-'||to_char(init_id_seq.nextval) into DocNumber
   --from dual;

   -- En-tête
   insert into ind_doc_bill_header (
    EMC_ACTIVE,
    DMT_DATE_DOCUMENT,
    IND_DOC_BILL_IMPORTATION_ID,
    DOC_NUMBER,
    BILL_MODELE_ID,
    RCO_TITLE,
    PAC_PERSON_ID,
    CURRENCY,
    DOC_GAUGE_FC_ID,
    DOC_GAUGE_NC_ID,
    EMP_NUMBER,
    HRM_EMPLOYEE_ID,
    BILL_REGROUP,
    DATE_PERIOD_FROM,
	  DATE_PERIOD_TO,
    DMT_CONTACT1,
    PAD_PAYMENT_DATE,
    DOC_TOTAL)
   values (
   ActiveLines,
   RowGlobal.dmt_date_document,
   ExportNum,
   DocNumber,
   RowGlobal.bill_modele_id,
   RowGlobal.rco_title,
   RowGlobal.pac_person_id,
   RowGlobal.currency,
   RowGlobal.doc_gauge_fc_id,
   RowGlobal.doc_gauge_nc_id,
   null,
   null,
  'Global',
   RowGlobal.date_period_from,
   RowGlobal.date_period_to,
   RowGlobal.dmt_contact1,
   RowGlobal.pad_payment_date,
   RowGlobal.total);

   -- Positions
   insert into ind_doc_bill_position (
   IND_DOC_BILL_IMPORTATION_ID,
   DOC_NUMBER,
   HRM_EMPLOYEE_ID,
   EMP_NUMBER,
   RCO_TITLE,
   GOO_MAJOR_REFERENCE,
   DES_SHORT_DESCRIPTION,
   CURRENCY,
   AMOUNT_CHF,
   AMOUNT_DEV,
   DIC_IMP_FREE1_ID)
   select
   ind_doc_bill_importation_id,
   DocNumber,
   HRM_EMPLOYEE_ID,
   EMP_NUMBER,
   RCO_TITLE,
   GOO_MAJOR_REFERENCE,
   DES_SHORT_DESCRIPTION,
   CURRENCY,
   sum(AMOUNT_MB) AMOUNT_CHF,
   sum(AMOUNT_ME) AMOUNT_DEV,
   DIC_IMP_FREE1_ID
   from
   ind_doc_bill_extract_tmp
   where
   ind_doc_bill_importation_id=ExportNum
   and bill_regroup='Global'
   and nvl(bill_modele_id,'NULL')=nvl(RowGlobal.bill_modele_id,'NULL')
   and nvl(rco_title,'NULL')=nvl(RowGlobal.rco_title,'NULL')
   and nvl(pac_person_id,0)=nvl(RowGlobal.pac_person_id,0)
   and nvl(currency,'NULL')=nvl(RowGlobal.currency,'NULL')
   and nvl(doc_gauge_fc_id,0)=nvl(RowGlobal.doc_gauge_fc_id,0)
   and nvl(doc_gauge_nc_id,0)=nvl(RowGlobal.doc_gauge_nc_id,0)
   and nvl(dmt_contact1,'NULL')=nvl(RowGlobal.dmt_contact1,'NULL')
   group by ind_doc_bill_importation_id,
   DocNumber,
   HRM_EMPLOYEE_ID,
   EMP_NUMBER,
   RCO_TITLE,
   GOO_MAJOR_REFERENCE,
   DES_SHORT_DESCRIPTION,
   CURRENCY,
   DIC_IMP_FREE1_ID;

  end loop;

  -- Traitement des Factures individuelles
  for RowIndividuel in CurIndividuel
  loop

   -- Création No document
   select 'OE-'||lpad(nvl(max(to_number(replace(doc_number,'OE-',''))),0)+1,8,'0') into DocNumber
   from ind_doc_bill_header;

   -- En-tête
   insert into ind_doc_bill_header (
    EMC_ACTIVE,
    dmt_date_document,
    IND_DOC_BILL_IMPORTATION_ID,
    DOC_NUMBER,
    BILL_MODELE_ID,
    RCO_TITLE,
    PAC_PERSON_ID,
    CURRENCY,
    DOC_GAUGE_FC_ID,
    DOC_GAUGE_NC_ID,
    EMP_NUMBER,
    HRM_EMPLOYEE_ID,
    BILL_REGROUP,
    DATE_PERIOD_FROM,
	  DATE_PERIOD_TO,
    DMT_CONTACT1,
    PAD_PAYMENT_DATE,
    DOC_TOTAL)
   values (
   ActiveLines,
   RowIndividuel.dmt_date_document,
   ExportNum,
   DocNumber,
   RowIndividuel.bill_modele_id,
   RowIndividuel.rco_title,
   RowIndividuel.pac_person_id,
   RowIndividuel.currency,
   RowIndividuel.doc_gauge_fc_id,
   RowIndividuel.doc_gauge_nc_id,
   RowIndividuel.emp_number,
   RowIndividuel.hrm_employee_id,
  'Individuel',
   RowIndividuel.date_period_from,
   RowIndividuel.date_period_to,
   RowIndividuel.dmt_contact1,
   RowIndividuel.pad_payment_date,
   RowIndividuel.total);

   -- Positions
   insert into ind_doc_bill_position (
   IND_DOC_BILL_IMPORTATION_ID,
   DOC_NUMBER,
   HRM_EMPLOYEE_ID,
   EMP_NUMBER,
   RCO_TITLE,
   GOO_MAJOR_REFERENCE,
   DES_SHORT_DESCRIPTION,
   CURRENCY,
   AMOUNT_CHF,
   AMOUNT_DEV,
   DIC_IMP_FREE1_ID)
   select
   ind_doc_bill_importation_id,
   DocNumber,
   HRM_EMPLOYEE_ID,
   EMP_NUMBER,
   RCO_TITLE,
   GOO_MAJOR_REFERENCE,
   DES_SHORT_DESCRIPTION,
   CURRENCY,
   sum(AMOUNT_MB) AMOUNT_CHF,
   sum(AMOUNT_ME) AMOUNT_DEV,
   DIC_IMP_FREE1_ID
   from
   ind_doc_bill_extract_tmp
   where
   ind_doc_bill_importation_id=ExportNum
   and bill_regroup='Individuel'
   and nvl(bill_modele_id,'NULL')=nvl(RowIndividuel.bill_modele_id,'NULL')
   and nvl(rco_title,'NULL')=nvl(RowIndividuel.rco_title,'NULL')
   and nvl(pac_person_id,0)=nvl(RowIndividuel.pac_person_id,0)
   and nvl(currency,'NULL')=nvl(RowIndividuel.currency,'NULL')
   and nvl(doc_gauge_fc_id,0)=nvl(RowIndividuel.doc_gauge_fc_id,0)
   and nvl(doc_gauge_nc_id,0)=nvl(RowIndividuel.doc_gauge_nc_id,0)
   and nvl(emp_number,'NULL')=nvl(RowIndividuel.emp_number,'NULL')
   and nvl(hrm_employee_id,0)=nvl(RowIndividuel.hrm_employee_id,0)
   and nvl(dmt_contact1,'NULL')=nvl(RowIndividuel.dmt_contact1,'NULL')
   group by ind_doc_bill_importation_id,
   DocNumber,
   HRM_EMPLOYEE_ID,
   EMP_NUMBER,
   RCO_TITLE,
   GOO_MAJOR_REFERENCE,
   DES_SHORT_DESCRIPTION,
   CURRENCY,
   DIC_IMP_FREE1_ID;

  end loop;

 --dbms_output.put_line('OK');

 end  ind_doc_bill_structure;

 procedure ind_doc_bill_delete(ExportNum number, DeleteMode varchar2)
 -- Suppression complète d'une extraction
 is
  cursor CurDoc is
  select
  a.doc_document_id
  from
      doc_document a
      where
      exists (select 1
              from com_vfields_record b
              where a.doc_document_id=b.vfi_rec_id
              and b.vfi_tabname='DOC_DOCUMENT'
              and vfi_integer_01=ExportNum);

  begin

  if DeleteMode='1' or DeleteMode='3'
  then
    for RowDoc in CurDoc
    loop

      doc_delete.deletedocument(RowDoc.doc_document_id,0);

      -- Suppression date génération
       update ind_doc_bill_importation
       set export_date=null
       where ind_doc_bill_importation_id=ExportNum;

    end loop;
  end if;

  if DeleteMode='1' or DeleteMode='2'
  then
   delete from ind_doc_bill_importation where ind_doc_bill_importation_id=ExportNum;
   delete from ind_doc_bill_extract_tmp where ind_doc_bill_importation_id=ExportNum;
   delete from ind_doc_bill_header where ind_doc_bill_importation_id=ExportNum;
   delete from ind_doc_bill_position where ind_doc_bill_importation_id=ExportNum;

   -- suppression flag saisies manuelles
   update ind_doc_bill_entry
   set ind_doc_bill_importation_id=null
   where ind_doc_bill_importation_id=ExportNum;

  end if;

 end ind_doc_bill_delete;

 procedure ind_doc_bill_generate(ExportNum number)
 -- Génération des facture dans DOC_DOCUMENT pour l'extraction donnée en paramètre
 is
  cursor CurDoc is
  select
  *
  from
  ind_doc_bill_header
  where
  ind_doc_bill_importation_id=ExportNum
  and emc_active=1
  order by bill_modele_id,rco_title,currency,emp_number;

  cursor CurPos(OE_Number varchar2) is
  select
  a.*,
  b.gco_good_id
  from
  ind_doc_bill_position a,
  gco_good b
  where
  a.goo_major_reference=b.goo_major_reference
  and ind_doc_bill_importation_id=ExportNum
  and doc_number=OE_number
  order by a.emp_number, a.goo_major_reference;

  vCount number;
  NewDocumentID doc_document.doc_document_id%type;
  NewPositionId doc_position.doc_position_id%type;
  GaugeId doc_gauge.doc_gauge_id%type;
  GaugeType DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%TYPE;
  ThirdId pac_third.pac_third_id%type;
  CurrId acs_financial_currency.acs_financial_currency_id%type;
  DivisionId acs_division_account.acs_division_account_id%type;
  DossierId doc_record.doc_record_id%type;
  GoodPrice number;
  PartnerRef doc_document.DMT_PARTNER_REFERENCE%type;

  begin
   -- CTRL que la génération n'a pas déjà été faite
   select
   count(*) into vCount
   from ind_doc_bill_importation
   where ind_doc_bill_importation_id=ExportNum
   and export_date is not null;

    if vCount > 0
     then raise_application_error (-20001,chr(10)||'>>>>>>>>>>'||chr(10)||chr(10)||
                                      'Les factures ont déjà été générées pour cette extration'||
                                      chr(10)||chr(10)||'>>>>>>>>>>'
                                  );
    end if;

   for RowDoc in CurDoc
   loop

    --id du document à créer
	select init_id_seq.nextval into NewDocumentID
	from dual;

    --recherche du gaugeId
    if RowDoc.doc_total>=0
     then GaugeId := RowDoc.doc_gauge_fc_id;
     else GaugeId := RowDoc.doc_gauge_nc_id;
    end if;

    -- Type de gabarit
    select max(C_GAUGE_TITLE) into GaugeType
    from DOC_GAUGE_STRUCTURED
    where doc_gauge_id=GaugeId;

    --recherche du Tiers
    if RowDoc.pac_person_id is not null
      then ThirdId:=RowDoc.pac_person_id;
      else
          select max(th.pac_third_id) into ThirdId
          from pac_person per, pac_third th
          where per.pac_person_id=th.pac_third_id
          and per.per_short_name=RowDoc.rco_title;
    end if;

    --recherche de la monnaie du document
    select max(acs_financial_currency_id) into CurrId
    from acs_financial_currency a,
         pcs.pc_curr b
    where a.pc_curr_id = b.pc_curr_id
    and   b.currency = RowDoc.currency;

    -- division ID (document)
    select max(acs_division_account_id) into DivisionId
    from acs_division_account a, acs_account b
    where a.acs_division_account_id=b.acs_account_id
    and b.acc_number=RowDoc.emp_number;

	if DivisionId is null
	  then
	  	   select max(acs_division_account_id) into DivisionId
		   from acs_division_account
		   where DIC_DIV_ACC_CODE_1_ID='03';
	end if;

  -- Recherche de la référence partenaire (sur la description longue de la division)
  select max(des_description_large) into PartnerRef
  from acs_division_account a, acs_description b
  where a.ACS_DIVISION_ACCOUNT_ID=b.acs_account_id
  and b.pc_lang_id=1
  and a.ACS_DIVISION_ACCOUNT_ID=DivisionId;


    -- Intilialisation
    DOC_DOCUMENT_GENERATE.ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO          :=  0;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_TEXT                 :=  1;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY             :=  1;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID    :=  CurrId;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_DIVISION_ACCOUNT_ID      :=  DivisionId;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_PAC_PAYMENT_CONDITION_ID :=  1;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.pac_payment_condition_id     :=  1918578;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE           :=  1;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE               :=  RowDoc.pad_payment_date;
    --DOC_DOCUMENT_INITIALIZE.DocumentInfo.dmt_contact1:=RowDoc.dmt_contact1;
    if PartnerRef is not null then
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_PARTNER_REFERENCE    :=  1;
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_PARTNER_REFERENCE        :=  PartnerRef;
    end if;

    -- création de l'entête du document
    Doc_Document_Generate.GenerateDocument(aNewDocumentID      => NewDocumentID
                                             , aMode               => '110'
                                             , aGaugeID            => GaugeId
                                             , aThirdID            => ThirdId
                                             , aDocDate            => RowDoc.dmt_date_document
                                              );

     --doc_invoice_expiry_functions.createBillBook(NewDocumentID);
    update doc_document
    set dmt_contact1=RowDoc.dmt_contact1
    where doc_document_id=NewDocumentId;



    -- champs virtuels
    insert into com_vfields_record (
    COM_VFIELDS_RECORD_ID,
    VFI_TABNAME,
    VFI_REC_ID,
    VFI_INTEGER_01,
    VFI_CHAR_01,
    VFI_DATE_01,
    VFI_DATE_02,
    A_DATECRE,
    A_IDCRE)
    select
    init_id_seq.nextval,
    'DOC_DOCUMENT',
    NewDocumentId,
    RowDoc.ind_doc_bill_importation_id,
    RowDoc.doc_number,
    RowDoc.date_period_from,
    RowDoc.date_period_to,
    sysdate,
    pcs.pc_init_session.getUserIni
    from dual;

      -- POSITIONS
      for RowPos in CurPos(RowDoc.doc_number)
      loop

        -- division ID (position)
        select max(acs_division_account_id) into DivisionId
        from acs_division_account a, acs_account b
        where a.acs_division_account_id=b.acs_account_id
        and b.acc_number=RowPos.emp_number;

        -- Dossier ID (position)
        select max(doc_record_id) into DossierId
        from doc_record
        where rco_title=RowPos.rco_title;

         -- Initialisation des données de la position que l'on va créer
            Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
            DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO    := 0;
            DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION :=0;
            doc_position_initialize.PositionInfo.CREATE_TYPE := 'INSERT';
            doc_position_initialize.PositionInfo.acs_division_account_id := DivisionId;
            doc_position_initialize.PositionInfo.doc_record_id := DossierId;
            doc_position_initialize.PositionInfo.DIC_IMP_FREE1_ID := RowPos.DIC_IMP_FREE1_ID;

            -- création d'une position de document
            select init_id_seq.nextval into NewPositionId from dual;

            -- inversion du signe pour les NC
            if GaugeType='9'
              then GoodPrice:=RowPos.Amount_dev*(-1);
              else GoodPrice:=RowPos.Amount_dev;
            end if;

               Doc_Position_initialize.PositionInfo.USE_GOOD_PRICE  := 1;
               Doc_Position_initialize.PositionInfo.GOOD_PRICE      := GoodPrice;
               Doc_Position_initialize.PositionInfo.POS_NET_TARIFF  := 1;

            --if RecPos.pps_nomenclature_id is not null then
            Doc_Position_Generate.GeneratePosition(aPositionID       => NewPositionID
                                                 , aDocumentID       => NewDocumentID
                                                 , aPosCreateMode    => '100'
                                                 , aTypePos          => '1'
                                                 , aGoodID           => RowPos.gco_good_id
                                                 , aBasisQuantity    => 1
                                                 , aGoodPrice        => RowPos.Amount_dev
                                                 --, aGenerateCPT      => 1
                                                 --, aNomenclatureID   => RecPos.pps_nomenclature_id
                                                  );

            update doc_position
            set DIC_IMP_FREE1_ID= RowPos.DIC_IMP_FREE1_ID
            where doc_position_id=NewPositionID;

            update doc_position
            set acs_division_account_id= divisionid
            where doc_position_id=NewPositionID;


      end loop;

    doc_document_functions.FINALIZEDOCUMENT(NewDocumentID);

    --dbms_output.put_line('OK');
   end loop;

   -- suppression des enregistrements non flagués
   delete from ind_doc_bill_position a
   where exists (select 1
                from ind_doc_bill_header b
                where a.doc_number=b.doc_number
                and b.emc_active=0
                and a.ind_doc_bill_importation_id=ExportNum);

    delete from ind_doc_bill_header
    where emc_active=0
    and ind_doc_bill_importation_id=ExportNum;

    -- Mise à jour date génération
   update ind_doc_bill_importation
   set export_date=sysdate
   where ind_doc_bill_importation_id=ExportNum;

 end ind_doc_bill_generate;

 procedure duplicate_modele(CodeModeleSource varchar2, CodeModeleDest varchar2, DescrModeleDest varchar2)
 -- copie (++) d'un modèle existant
 is

 begin

 if CodeModeleSource is not null and CodeModeleDest is not null and DescrModeleDest is not null and CodeModeleSource<>CodeModeleDest
 then

  -- Insert Modèle
  insert into ind_doc_bill_modele (
  BILL_MODELE_ID,
  BILL_MODELE_DESCR,
  A_DATECRE,
  A_IDCRE)
  select
  CodeModeleDest,
  DescrModeleDest,
  sysdate,
  nvl(pcs.pc_init_session.GetUserIni,'COPY')
  from dual;

  -- insert Paramères
  insert into ind_doc_bill_modele_param
  select
  CodeModeleDest BILL_MODELE_ID,
  BILL_MODELE_CATEG,
  BILL_MONTH_EXTRACT,
  BILL_MONTH_PROJECT,
  BILL_MAJORATION,
  BILL_REGROUP,
  GOO_MAJOR_REFERENCE_FG,
  DOC_GAUGE_ID,
  DOC_GAUGE_FC_ID,
  DOC_GAUGE_NC_ID,
  BILL_TYPE,
  WITH_CONTACT,
  sysdate A_DATECRE,
  nvl(pcs.pc_init_session.GetUserIni,'COPY') A_IDCRE,
  null A_DATEMOD,
  null A_IDMOD,
  GOO_MAJOR_REFERENCE_TAX,
  FG_IS_TAX
  from
  ind_doc_bill_modele_param
  where
  bill_modele_id=CodeModeleSource;

  -- insert Salaires
  insert into ind_doc_bill_modele_param_det
  select
  CodeModeleDest BILL_MODELE_ID,
  DIC_GROUP1_ID,
  GOO_MAJOR_REFERENCE,
  GOO_IS_FG,
  GOO_IS_SUBTOTAL,
  GOO_IS_MAJORATED,
  GOO_IS_EXCEPT,
  ACS_ACCOUNT_ID,
  sysdate A_DATECRE,
  nvl(pcs.pc_init_session.GetUserIni,'COPY') A_IDCRE,
  null A_DATEMOD,
  null A_IDMOD,
  GOO_IS_TAX,
  BILL_CONVERT_MB
  from
  ind_doc_bill_modele_param_det
  where
  bill_modele_id=CodeModeleSource;

  -- insert Mouvements non lettrés
  insert into ind_doc_bill_modele_param_acc
  select
  CodeModeleDest BILL_MODELE_ID,
  ACS_ACCOUNT_ID,
  GOO_MAJOR_REFERENCE,
  BILL_MONTH_EXTRACT,
  BILL_NOT_LET,
  BILL_CONVERT_MB,
  GOO_IS_FG,
  GOO_IS_SUBTOTAL,
  GOO_IS_MAJORATED,
  GOO_IS_EXCEPT,
  sysdate A_DATECRE,
  nvl(pcs.pc_init_session.GetUserIni,'COPY') A_IDCRE,
  null A_DATEMOD,
  null A_IDMOD,
  GOO_IS_TAX
  from
  ind_doc_bill_modele_param_acc
  where
  bill_modele_id=CodeModeleSource;

  -- insert Saisies manuelles
  insert into ind_doc_bill_modele_param_man
  select
  CodeModeleDest BILL_MODELE_ID,
  GOO_MAJOR_REFERENCE,
  GOO_IS_FG,
  GOO_IS_SUBTOTAL,
  GOO_IS_MAJORATED,
  GOO_IS_EXCEPT,
  sysdate A_DATECRE,
  nvl(pcs.pc_init_session.GetUserIni,'COPY') A_IDCRE,
  null A_DATEMOD,
  null A_IDMOD,
  GOO_IS_TAX
  from
  ind_doc_bill_modele_param_man
  where
  bill_modele_id=CodeModeleSource;

  -- insert Transactions
  insert into ind_doc_bill_modele_param_cat
  select
  CodeModeleDest BILL_MODELE_ID,
  ACS_ACCOUNT_ID,
  ACJ_CATALOGUE_DOCUMENT_ID,
  sysdate A_DATECRE,
  nvl(pcs.pc_init_session.GetUserIni,'COPY') A_IDCRE,
  null A_DATEMOD,
  null A_IDMOD
  from
  ind_doc_bill_modele_param_cat
  where
  bill_modele_id=CodeModeleSource;

 end if;

 end duplicate_modele;

 function GetFGAmount(DivNumber acs_account.acc_number%type, RcoTitle doc_record.rco_title%type, DateFrom date, DateTo date) return number
 -- Calcul des Frais de gestion sur une période donnée
 is
  PartnerId pac_person.pac_person_id%type;
  TypeFG PAC_CUSTOM_PARTNER.DIC_STATISTIC_1_ID%type;
  ValeurFG PAC_CUSTOM_PARTNER.CUS_FREE_ZONE4%type;
  retour number;
 begin

 -- recherche id du client
 select max(pac_person_id) into PartnerId
 from pac_person
 where per_short_name=RcoTitle;

 -- Type de FG
 select max(dic_statistic_1_id), max(cus_free_zone4)
 into TypeFG, ValeurFG
 from pac_custom_partner
 where pac_custom_partner_id=PartnerId;

 if TypeFG='Montant'
 then -- nb mois de présence de l'employé dans l'intervalle * montant
      select sum(acs_function.pcsround(months_between(
          least(nvl(ino_out,to_date('31.12.2022','DD.MM.YYYY')),DateTo),
          greatest(ino_in,DateFrom)),'4',1)) * ValeurFG
      into retour
      from hrm_in_out i, hrm_person p
      where i.hrm_employee_id=p.hrm_person_id
      and p.emp_number=DivNumber
      and ino_in<=DateTo
      and (ino_out>=DateFrom
          or ino_out is null);
 else -- Pourcentage. Recherche dans les imputations des comptes soumis à FG et application du taux
      select
      round(sum(case
       when imf_amount_fc_d is null and imf_amount_fc_c is null
       then nvl(imf_amount_lc_d,0)-nvl(imf_amount_lc_c,0)
       else nvl(imf_amount_fc_d,0)-nvl(imf_amount_fc_c,0)
      end) * ValeurFG/100,2) into retour
      from
      act_financial_imputation imp,
      ind_doc_bill_modele_param_det bil
      where
      imp.acs_financial_account_id=bil.acs_account_id
      and bil.goo_is_fg=1
      and bil.bill_modele_id='100'
      and imf_transaction_date>=DateFrom
      and imf_transaction_date<=DateTo
      and exists (select 1
                  from acs_account acc
                  where acc.acs_account_id=imp.imf_acs_division_account_id
                  and acc.acc_number=DivNumber)
      and exists (select 1
                  from doc_record rec
                  where rec.doc_record_id=imp.doc_record_id
                  and rec.rco_title=RcoTitle);
 end if;

 return nvl(retour,0);

 end GetFGAmount;

 procedure import_saie_man(FileDir varchar2, FileName varchar2, DelRecord number)
 -- importation fichier dans les saisies manuelles
 is
  cursor CurFile(ImportName varchar2) is
  select
  trim(pcs.extractline(ind_line,1,';')) elp_is_const,
  trim(pcs.extractline(ind_line,2,';')) div_number,
  trim(pcs.extractline(ind_line,3,';')) soc_number,
  trim(pcs.extractline(ind_line,4,';')) DIC_IMP_FREE1_ID,
  trim(pcs.extractline(ind_line,5,';')) goo_major_reference,
  trim(pcs.extractline(ind_line,6,';')) currency,
  trim(pcs.extractline(ind_line,7,';')) his_pay_sum_val_dev,
  trim(pcs.extractline(ind_line,8,';')) his_pay_sum_val_chf,
  trim(pcs.extractline(ind_line,9,';')) emc_value_from,
  trim(pcs.extractline(ind_line,10,';')) emc_value_to,
  trim(pcs.extractline(ind_line,11,';')) bill_comment
  from
  ind_fichier
  where import_name=ImportName;

  ImportName varchar2(50);
  vLine integer;
  DivNum varchar2(20);
  PersonId number;
  Free1Id varchar2(20);
  GoodRef varchar2(50);
  vCurr varchar2(5);
  AmountME number;
  AmountMB number;
  checkDateFormat date;

 begin
  -- définition du nom d'importation
  select FileName||'_'||to_char(sysdate,'YYYY-MM-DD_HH24:MI:SS') into ImportName
  from dual;

  -- reprise du fichier
  IND_REPRISE_FICHIER.LECTURE_FICHIER(FileDir, FileName, ImportName);

  vLine:=0;

  for RowFile in CurFile(ImportName)
  loop

  vLine:=vLine+1;

   -- check constante
   if nvl(RowFile.elp_is_const,'0') not in ('0','1')
   then raise_application_error(-20001,'Le code "constante" doit être 0 ou 1'||' [ligne '||vLine||']');
   end if;

   -- check division
   select max(acc_number) into DivNum
   from acs_Account a, acs_division_account b
   where a.acs_account_id=b.acs_division_account_id
   and a.acc_number=RowFile.div_number;

   if DivNum is null
   then raise_application_error(-20001,'La division '||RowFile.div_number||' n''existe pas'||' [ligne '||vLine||']');
   end if;

   -- check société
   select max(pac_person_id) into PersonId
   from pac_person
   where per_short_name=RowFile.soc_number;

   if PersonId is null
   then raise_application_error(-20001,'La société '||RowFile.soc_number||' n''existe pas'||' [ligne '||vLine||']');
   end if;

   -- check département
   select max(dic_imp_free1_id) into Free1Id
   from dic_imp_free1
   where dic_imp_free1_id=RowFile.dic_imp_free1_id;

   if Free1Id is null and RowFile.dic_imp_free1_id is not null
   then raise_application_error(-20001,'Le département (code libre imputation 1) '||RowFile.dic_imp_free1_id||' n''existe pas'||' [ligne '||vLine||']');
   end if;

   -- check article
   select max(goo_major_reference) into GoodRef
   from gco_good
   where goo_major_reference=RowFile.goo_major_reference;

   if GoodRef is null
   then raise_application_error(-20001,'L''article '||RowFile.goo_major_reference||' n''existe pas'||' [ligne '||vLine||']');
   end if;

   -- check monnaie
   select max(currency) into vCurr
   from pcs.pc_curr c, acs_financial_currency f
   where c.pc_curr_id=f.pc_curr_id
   and c.currency=RowFile.currency;

   if vCurr is null
   then raise_application_error(-20001,'La monnaie '||RowFile.currency||' n''existe pas'||' [ligne '||vLine||']');
   end if;

   -- check format nombre ME
   begin
     select to_number(RowFile.his_pay_sum_val_dev) into AmountME
     from dual;

     if AmountME is null
     then raise_application_error(-20001,'Le montant ME est obligatoire'||' [ligne '||vLine||']');
     end if;

     exception when others then raise_application_error(-20001,'Le format nombre (ME) '||RowFile.his_pay_sum_val_dev||' est incorrect'||' [ligne '||vLine||']');
   end;

   -- check format nombre MB
   begin
     select to_number(RowFile.his_pay_sum_val_chf) into AmountMB
     from dual;

     exception when others then raise_application_error(-20001,'Le format nombre (MB) '||RowFile.his_pay_sum_val_chf||' est incorrect'||' [ligne '||vLine||']');
   end;

   -- check format date début
   begin
     select to_date(RowFile.emc_value_from,'DD.MM.YYYY') into checkDateFormat
     from dual;

     if checkDateFormat is null
     then raise_application_error(-20001,'Le date de début de validité est obligatoire'||' [ligne '||vLine||']');
     end if;

     exception when others then raise_application_error(-20001,'Le format date (début de validité - "DD.MM.YYYY") '||RowFile.emc_value_from||' est incorrect'||' [ligne '||vLine||']');
   end;

   -- check format date fin
   begin
     select to_date(RowFile.emc_value_to,'DD.MM.YYYY') into checkDateFormat
     from dual;

     if checkDateFormat is null
     then raise_application_error(-20001,'Le date de fin de validité est obligatoire'||' [ligne '||vLine||']');
     end if;

     exception when others then raise_application_error(-20001,'Le format date (fin de validité - "DD.MM.YYYY") '||RowFile.emc_value_to||' est incorrect'||' [ligne '||vLine||']');
   end;

   -- suppression des anciennes saisies manuelles si param = 1
   if DelRecord=1
   then delete from ind_doc_bill_entry
        where ind_doc_bill_importation_id is null;
   end if;

   -- insert des saisies manuelles
   insert into ind_doc_bill_entry (IND_DOC_BILL_ENTRY_ID,
                                  IND_DOC_BILL_IMPORTATION_ID,
                                  PAC_CUSTOM_PARTNER_ID,
                                  DIV_NUMBER,
                                  GOO_MAJOR_REFERENCE,
                                  CURRENCY,
                                  HIS_PAY_SUM_VAL_DEV,
                                  HIS_PAY_SUM_VAL_CHF,
                                  EMC_VALUE_FROM,
                                  EMC_VALUE_TO,
                                  BILL_COMMENT,
                                  A_DATECRE,
                                  A_IDCRE,
                                  A_DATEMOD,
                                  A_IDMOD,
                                  ELP_IS_CONST,
                                  DIC_IMP_FREE1_ID)
   values (null, null, PersonId, RowFile.div_number, RowFile.goo_major_reference, RowFile.currency,
          AmountME, AmountMB, to_date(RowFile.emc_value_from,'DD.MM.YYYY'),
          to_date(RowFile.emc_value_to,'DD.MM.YYYY'), substr(RowFile.bill_comment,1,200), sysdate,
          pcs.pc_init_session.GetUserIni, null, null, nvl(RowFile.elp_is_const,0), RowFile.dic_imp_free1_id);

  end loop;

 end import_saie_man;

end ind_doc_billing;
