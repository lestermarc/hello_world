--------------------------------------------------------
--  DDL for Procedure IND_C9_DOC_RECAP_SEM_QUARTER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_DOC_RECAP_SEM_QUARTER" (aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, PROCPARAM_0 in date, PROCPARAM_1 in date)

is
/**
* Procédure stockée utilisée dans un rapport
*
* @author
* @lastUpdate
* @version
* @public
* @param PROCPARAM_0   Date de
*        PROCPARAM_1   Date à
*/
begin

--pcs.pc_init_session.setLanId (procuser_lanid);

open aRefCursor for
select
*
from
(
-- FACTURES
SELECT
'PRODUIT' DOMAINE,
  CUR.CURRENCY,
  NVL (RCO_TITLE,' ') RCO_TITLE,
  PER_NAME,
  ACC_NUMBER DIV_NUMBER,
  ACD.DES_DESCRIPTION_SUMMARY PER_FULLNAME,
  TO_CHAR (DOC.DMT_DATE_DOCUMENT,'YYYYMM') PERIOD,
  DOC.DMT_DATE_DOCUMENT,
  DMT_NUMBER,
  DIC_GAUGE_GROUP_ID,
  NVL (GOO.GOO_MAJOR_REFERENCE,' ') GOO_MAJOR_REFERENCE,
  DES_SHORT_DESCRIPTION,
  DES_LONG_DESCRIPTION,
  gca.GCO_CATEGORY_CODE,
  gca.GCO_GOOD_CATEGORY_WORDING,
  DECODE (DGS.C_GAUGE_TITLE,'9',(POS_NET_VALUE_EXCL * -1),'8',POS_NET_VALUE_EXCL,'30',POS_NET_VALUE_EXCL,0) POS_NET_VALUE_INCL,
  DECODE (DGS.C_GAUGE_TITLE,'9',(POS_NET_VALUE_EXCL_B * -1),'8',POS_NET_VALUE_EXCL_B,'30',POS_NET_VALUE_EXCL_B,0) POS_NET_VALUE_INCL_B,
  case
   when to_char(nvl(COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_FROM',doc.doc_document_id),DOC.DMT_DATE_DOCUMENT),'MM') between '01' and '03' then '1'
   when to_char(nvl(COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_FROM',doc.doc_document_id),DOC.DMT_DATE_DOCUMENT),'MM') between '04' and '06' then '2'
   when to_char(nvl(COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_FROM',doc.doc_document_id),DOC.DMT_DATE_DOCUMENT),'MM') between '07' and '09' then '3'
   when to_char(nvl(COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_FROM',doc.doc_document_id),DOC.DMT_DATE_DOCUMENT),'MM') between '10' and '12' then '4'
  end trimestre,
  nvl(pac_itx.GetCusLangId(per.pac_person_id),1) pc_lang_id,
  (select lanid from pcs.pc_lang where pc_lang_id=nvl(pac_itx.GetCusLangId(per.pac_person_id),1)) lanid
FROM
  DOC_POSITION POS,
  DOC_GAUGE_STRUCTURED DGS,
  DOC_RECORD DRE,
  GCO_GOOD GOO,
  PAC_CUSTOM_PARTNER PAC,
  PAC_THIRD THI,
  PAC_PERSON PER,
  DOC_DOCUMENT DOC,
  ACS_DIVISION_ACCOUNT DIV,
  ACS_ACCOUNT ACC,
  ACS_FINANCIAL_CURRENCY FCUR,
  PCS.PC_CURR CUR,
  ACS_DESCRIPTION ACD,
  GCO_DESCRIPTION GOD,
  DOC_GAUGE GAU,
  GCO_GOOD_CATEGORY gca
WHERE
  POS.ACS_DIVISION_ACCOUNT_ID=DIV.ACS_DIVISION_ACCOUNT_ID (+) AND
  DIV.ACS_DIVISION_ACCOUNT_ID=ACD.ACS_ACCOUNT_ID (+) AND
  (ACD.PC_LANG_ID=1 OR
  ACD.PC_LANG_ID IS NULL) AND
  GOO.GCO_GOOD_ID=GOD.GCO_GOOD_ID AND
  GOD.PC_LANG_ID=pac_itx.GetCusLangId(per.pac_person_id) AND
  DIV.ACS_DIVISION_ACCOUNT_ID=ACC.ACS_ACCOUNT_ID (+) AND
  DOC.ACS_FINANCIAL_CURRENCY_ID=FCUR.ACS_FINANCIAL_CURRENCY_ID AND
  FCUR.PC_CURR_ID=CUR.PC_CURR_ID AND
  DOC.DOC_GAUGE_ID=DGS.DOC_GAUGE_ID AND
  (DGS.C_GAUGE_TITLE = '8' OR
  DGS.C_GAUGE_TITLE = '9' OR
  DGS.C_GAUGE_TITLE = '30' ) AND
  (DOC.DMT_DATE_DOCUMENT >=PROCPARAM_0 AND
  DOC.DMT_DATE_DOCUMENT <=PROCPARAM_1 ) AND
  POS.DOC_RECORD_ID = DRE.DOC_RECORD_ID (+)  AND
  DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID AND
  ( POS.POS_FINAL_QUANTITY <> 0 OR
  POS.POS_NET_VALUE_EXCL <> 0) AND
  POS.C_DOC_POS_STATUS <> '05' AND
  (POS.C_GAUGE_TYPE_POS='1' OR
  POS.C_GAUGE_TYPE_POS='5' OR
  POS.C_GAUGE_TYPE_POS='7' OR
  POS.C_GAUGE_TYPE_POS='8' OR
  POS.C_GAUGE_TYPE_POS='91' OR
  POS.C_GAUGE_TYPE_POS='10') AND
  PER.PAC_PERSON_ID = DOC.PAC_THIRD_ID AND
  PER.PAC_PERSON_ID=THI.PAC_THIRD_ID AND
  THI.PAC_THIRD_ID=PAC.PAC_CUSTOM_PARTNER_ID AND
  POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID (+) AND
  DOC.DOC_GAUGE_ID=GAU.DOC_GAUGE_ID
  and DIC_GAUGE_GROUP_ID in ('MAP','RECAP')
  and goo.GCO_GOOD_CATEGORY_ID=gca.GCO_GOOD_CATEGORY_ID
UNION ALL
-- COMPTA (CHARGES)
select
'CHARGE' DOMAINE,
(select currency
 from acs_financial_currency fcur, pcs.pc_curr cur
 where imp.acs_financial_currency_id=fcur.acs_financial_currency_id
 and fcur.pc_curr_id=cur.pc_curr_id) currency,
(select rco_title from doc_record rec where imp.doc_record_id=rec.doc_record_id) rco_title,
per.per_name,
(SELECT DIV.ACC_NUMBER FROM ACS_ACCOUNT DIV WHERE DIV.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) DIV_NUMBER,
(select des_description_summary from acs_description des where IMP.IMF_ACS_DIVISION_ACCOUNT_ID=des.acs_account_id and des.pc_lang_id=1) div_description,
to_char(IMF_TRANSACTION_DATE,'YYYYMM') period,
IMF_TRANSACTION_DATE,
(SELECT DOC.DOC_NUMBER FROM ACT_DOCUMENT DOC WHERE DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID) DOC_NUMBER,
acc_number,
fac.DIC_FIN_ACC_CODE_6_ID,
DES_SHORT_DESCRIPTION,
DES_LONG_DESCRIPTION,
gca.GCO_CATEGORY_CODE,
gca.GCO_GOOD_CATEGORY_WORDING,
nvl(IMF_AMOUNT_FC_D,IMF_AMOUNT_LC_D)-nvl(IMF_AMOUNT_FC_C,IMF_AMOUNT_LC_C) amount_me,
IMF_AMOUNT_LC_D-IMF_AMOUNT_LC_C amount_mb,
case
 when to_char(IMF_TRANSACTION_DATE,'MM') between '01' and '03' then '1'
 when to_char(IMF_TRANSACTION_DATE,'MM') between '04' and '06' then '2'
 when to_char(IMF_TRANSACTION_DATE,'MM') between '07' and '09' then '3'
 when to_char(IMF_TRANSACTION_DATE,'MM') between '10' and '12' then '4'
end trimestre,
nvl(pac_itx.GetCusLangId(per.pac_person_id),1) pc_lang_id,
(select lanid from pcs.pc_lang where pc_lang_id=nvl(pac_itx.GetCusLangId(per.pac_person_id),1)) lanid
from
act_financial_imputation imp,
acs_account acc,
acs_financial_account fac,
gco_good goo,
gco_description god,
(select doc_record_id, rco_title, pac_person_id, per_short_name, per_name
 from doc_record a, pac_person b
 where a.rco_title=b.per_short_name) per,
GCO_GOOD_CATEGORY GCA
where
imp.acs_financial_account_id=fac.acs_financial_account_id
and fac.acs_financial_account_id=acc.acs_account_id
and IMF_TRANSACTION_DATE>=PROCPARAM_0
and IMF_TRANSACTION_DATE<=PROCPARAM_1
and fac.DIC_FIN_ACC_CODE_6_ID=goo.goo_major_reference
and goo.gco_good_id=god.gco_good_id
and god.pc_lang_id=pac_itx.GetCusLangId(per.pac_person_id)
and imp.doc_record_id=per.doc_record_id
and goo.GCO_GOOD_CATEGORY_ID=gca.GCO_GOOD_CATEGORY_ID
UNION ALL
-- FRAIS DE GESTION
SELECT
'CHARGE' DOMAINE,
  CUR.CURRENCY,
  NVL (RCO_TITLE,' ') RCO_TITLE,
  PER_NAME,
  ACC_NUMBER DIV_NUMBER,
  ACD.DES_DESCRIPTION_SUMMARY PER_FULLNAME,
  max(TO_CHAR (DOC.DMT_DATE_DOCUMENT,'YYYYMM')) PERIOD,
  max(DOC.DMT_DATE_DOCUMENT),
  'FG' DMT_NUMBER,
  max(DIC_GAUGE_GROUP_ID),
  max(NVL (GOO.GOO_MAJOR_REFERENCE,' ')) GOO_MAJOR_REFERENCE,
  max(DES_SHORT_DESCRIPTION),
  max(DES_LONG_DESCRIPTION),
  max(gca.GCO_CATEGORY_CODE),
  max(gca.GCO_GOOD_CATEGORY_WORDING),
  ind_doc_billing.GetFGAmount(ACC_NUMBER, RCO_TITLE, PROCPARAM_0, PROCPARAM_1) POS_NET_VALUE_INCL,
  ind_doc_billing.GetFGAmount(ACC_NUMBER, RCO_TITLE, PROCPARAM_0, PROCPARAM_1) POS_NET_VALUE_INCL_B,
  max(case
   when to_char(nvl(COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_FROM',doc.doc_document_id),DOC.DMT_DATE_DOCUMENT),'MM') between '01' and '03' then '1'
   when to_char(nvl(COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_FROM',doc.doc_document_id),DOC.DMT_DATE_DOCUMENT),'MM') between '04' and '06' then '2'
   when to_char(nvl(COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_FROM',doc.doc_document_id),DOC.DMT_DATE_DOCUMENT),'MM') between '07' and '09' then '3'
   when to_char(nvl(COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_FROM',doc.doc_document_id),DOC.DMT_DATE_DOCUMENT),'MM') between '10' and '12' then '4'
  end) trimestre,
  nvl(pac_itx.GetCusLangId(per.pac_person_id),1) pc_lang_id,
  --(select lanid from pcs.pc_lang where pc_lang_id=nvl(pac_itx.GetCusLangId(per.pac_person_id),1)) lanid
  lan.lanid
FROM
  DOC_POSITION POS,
  DOC_GAUGE_STRUCTURED DGS,
  DOC_RECORD DRE,
  GCO_GOOD GOO,
  PAC_CUSTOM_PARTNER PAC,
  PAC_THIRD THI,
  PAC_PERSON PER,
  DOC_DOCUMENT DOC,
  ACS_DIVISION_ACCOUNT DIV,
  ACS_ACCOUNT ACC,
  ACS_FINANCIAL_CURRENCY FCUR,
  PCS.PC_CURR CUR,
  ACS_DESCRIPTION ACD,
  GCO_DESCRIPTION GOD,
  DOC_GAUGE GAU,
  GCO_GOOD_CATEGORY gca,
  pcs.pc_lang lan
WHERE
  POS.ACS_DIVISION_ACCOUNT_ID=DIV.ACS_DIVISION_ACCOUNT_ID (+) AND
  DIV.ACS_DIVISION_ACCOUNT_ID=ACD.ACS_ACCOUNT_ID (+) AND
  (ACD.PC_LANG_ID=1 OR
  ACD.PC_LANG_ID IS NULL) AND
  GOO.GCO_GOOD_ID=GOD.GCO_GOOD_ID AND
  GOD.PC_LANG_ID=pac_itx.GetCusLangId(per.pac_person_id) AND
  DIV.ACS_DIVISION_ACCOUNT_ID=ACC.ACS_ACCOUNT_ID (+) AND
  DOC.ACS_FINANCIAL_CURRENCY_ID=FCUR.ACS_FINANCIAL_CURRENCY_ID AND
  FCUR.PC_CURR_ID=CUR.PC_CURR_ID AND
  DOC.DOC_GAUGE_ID=DGS.DOC_GAUGE_ID AND
  (DGS.C_GAUGE_TITLE = '8' OR
  DGS.C_GAUGE_TITLE = '9' OR
  DGS.C_GAUGE_TITLE = '30' ) AND
  (DOC.DMT_DATE_DOCUMENT >=PROCPARAM_0 AND
  DOC.DMT_DATE_DOCUMENT <=PROCPARAM_1 ) AND
  POS.DOC_RECORD_ID = DRE.DOC_RECORD_ID (+)  AND
  DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID AND
  ( POS.POS_FINAL_QUANTITY <> 0 OR
  POS.POS_NET_VALUE_EXCL <> 0) AND
  POS.C_DOC_POS_STATUS <> '05' AND
  (POS.C_GAUGE_TYPE_POS='1' OR
  POS.C_GAUGE_TYPE_POS='5' OR
  POS.C_GAUGE_TYPE_POS='7' OR
  POS.C_GAUGE_TYPE_POS='8' OR
  POS.C_GAUGE_TYPE_POS='91' OR
  POS.C_GAUGE_TYPE_POS='10') AND
  PER.PAC_PERSON_ID = DOC.PAC_THIRD_ID AND
  PER.PAC_PERSON_ID=THI.PAC_THIRD_ID AND
  THI.PAC_THIRD_ID=PAC.PAC_CUSTOM_PARTNER_ID AND
  POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID (+) AND
  DOC.DOC_GAUGE_ID=GAU.DOC_GAUGE_ID
  and DIC_GAUGE_GROUP_ID in ('MAP','RECAP')
  and goo.GCO_GOOD_CATEGORY_ID=gca.GCO_GOOD_CATEGORY_ID
  and gca.GCO_GOOD_CATEGORY_WORDING='FRAIS DE GESTION'
  and nvl(pac_itx.GetCusLangId(per.pac_person_id),1)=lan.pc_lang_id
  group by CUR.CURRENCY,
  NVL (RCO_TITLE,' '),
  PER_NAME,
  ACC_NUMBER,
  ACD.DES_DESCRIPTION_SUMMARY,
  ind_doc_billing.GetFGAmount(ACC_NUMBER, RCO_TITLE, PROCPARAM_0, PROCPARAM_1),
  nvl(pac_itx.GetCusLangId(per.pac_person_id),1),
  lan.lanid
) pri
where
exists (select 1
        from doc_position a, doc_record b, acs_account c, doc_document d, doc_gauge e
        where a.doc_record_id=b.doc_record_id
        and a.acs_division_account_id=c.acs_account_id
        and a.doc_document_id=d.doc_document_id
        and d.doc_gauge_id=e.doc_gauge_id
        --and COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_FROM',a.doc_document_id)=PROCPARAM_0
        and COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_TO',a.doc_document_id)=PROCPARAM_1
        --and b.rco_title=pri.rco_title
        and c.acc_number=pri.div_number
        and e.DIC_GAUGE_GROUP_ID='RECAP')
;

end IND_C9_DOC_RECAP_SEM_QUARTER;
