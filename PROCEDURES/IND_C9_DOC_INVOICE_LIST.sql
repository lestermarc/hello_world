--------------------------------------------------------
--  DDL for Procedure IND_C9_DOC_INVOICE_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_DOC_INVOICE_LIST" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PROCPARAM_0 in     date
, PROCPARAM_1 in     date
--, PROCPARAM_2 in  pcs.pc_lang.lanid%type
)

is
/**
* Procédure stockée utilisée pour le rapport DOC_INVOICE_LIST (Liste des factures)
*
* @author RGU
* @lastUpdate
* @param PROCPARAM_0    Date document de
* @param PROCPARAM_1    Date docuemnt à
* @param PROCPARAM_2    Langue (PC_LANG_ID)
*/

 vDateFrom date;
 vDateTo date;
 vLang pcs.pc_lang.lanid%type;

begin

vDateFrom:=PROCPARAM_0;
vDateTo:=PROCPARAM_1;
vLang:=1;

open aRefCursor for
      select
      dmt.dmt_number,
      dmt.dmt_date_document,
      dmt.C_DOCUMENT_STATUS,
      com_functions.GetDescodeDescr('C_DOCUMENT_STATUS', dmt.C_DOCUMENT_STATUS, vLang) C_DOCUMENT_STATUS_DESCR,
      gau.gau_describe,
      gau.DIC_GAUGE_GROUP_ID,
      com_dic_functions.GetDicoDescr('DIC_GAUGE_GROUP',gau.DIC_GAUGE_GROUP_ID,vLang) DIC_GAUGE_GROUP_DESCR,
      gst.C_GAUGE_TITLE,
      com_functions.GetDescodeDescr('C_GAUGE_TITLE', gst.C_GAUGE_TITLE, vLang) C_GAUGE_TITLE_DESCR,
      per.per_short_name,
      per.per_name,
      (select lanid
       from pcs.pc_lang lan
       where dmt.pc_lang_id=lan.pc_lang_id) lanid,
      (select currency
       from acs_financial_currency fcur, pcs.pc_curr cur
       where dmt.acs_financial_currency_id=fcur.acs_financial_currency_id
       and fcur.pc_curr_id=cur.pc_curr_id) currency,
      dmt.DMT_RATE_OF_EXCHANGE,
      (select acc_number
       from acs_account acc
       where acc.acs_account_id=dmt.acs_financial_account_id) doc_acc_num,
      (select des_description_summary
       from acs_description des
       where des.acs_account_id=dmt.acs_financial_account_id
       and des.pc_lang_id=vLang) doc_acc_descr,
      (select acc_number
       from acs_account div
       where div.acs_account_id=dmt.acs_division_account_id) doc_div_num,
      (select des_description_summary
       from acs_description des
       where des.acs_account_id=dmt.acs_division_account_id
       and des.pc_lang_id=vLang) doc_div_descr,
      COM_VFIELDS_4_PRNT.GetVF2Value_char('DOC_DOCUMENT','VFLD_DOC_EXTRACT_ID',dmt.doc_document_id) VFLD_DOC_EXTRACT_ID,
      COM_VFIELDS_4_PRNT.GetVF2Value_char('DOC_DOCUMENT','VFLD_DOC_OE_NUMBER',dmt.doc_document_id) VFLD_DOC_OE_NUMBER,
      COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_FROM',dmt.doc_document_id) VFLD_DOC_DATE_FROM,
      COM_VFIELDS_4_PRNT.GetVF2Value_date('DOC_DOCUMENT','VFLD_DOC_DATE_TO',dmt.doc_document_id) VFLD_DOC_DATE_TO,
      pos.c_gauge_type_pos,
      goo.goo_major_reference,
      (select DES_SHORT_DESCRIPTION
       from gco_description des
       where des.gco_good_id=pos.gco_good_id
       and des.pc_lang_id=vLang) DES_SHORT_DESCRIPTION,
      (select DES_LONG_DESCRIPTION
       from gco_description des
       where des.gco_good_id=pos.gco_good_id
       and des.pc_lang_id=vLang) DES_LONG_DESCRIPTION,
      DECODE (gst.C_GAUGE_TITLE,'9',(pos.POS_NET_VALUE_EXCL * -1),pos.POS_NET_VALUE_EXCL) POS_NET_VALUE_EXCL,
      DECODE (gst.C_GAUGE_TITLE,'9',(pos.POS_NET_VALUE_INCL * -1),pos.POS_NET_VALUE_INCL) POS_NET_VALUE_INCL,
      DECODE (gst.C_GAUGE_TITLE,'9',(pos.POS_NET_VALUE_EXCL_B * -1),pos.POS_NET_VALUE_EXCL_B) POS_NET_VALUE_EXCL_B,
      DECODE (gst.C_GAUGE_TITLE,'9',(pos.POS_NET_VALUE_INCL_B * -1),pos.POS_NET_VALUE_INCL_B) POS_NET_VALUE_INCL_B,
      (select acc_number
       from acs_account acc
       where acc.acs_account_id=pos.acs_financial_account_id) pos_acc_num,
      (select des_description_summary
       from acs_description des
       where des.acs_account_id=pos.acs_financial_account_id
       and des.pc_lang_id=vLang) pos_acc_descr,
      (select acc_number
       from acs_account div
       where div.acs_account_id=pos.acs_division_account_id) pos_div_num,
      (select des_description_summary
       from acs_description des
       where des.acs_account_id=pos.acs_division_account_id
       and des.pc_lang_id=vLang) pos_div_descr,
      foo.FOO_DOCUMENT_TOTAL_AMOUNT,
      foo.FOO_DOCUMENT_TOT_AMOUNT_B,
      (select min(PAD_PAYMENT_DATE)
       from DOC_PAYMENT_DATE pay
       where foo.doc_foot_id=pay.doc_foot_id) PAD_PAYMENT_DATE,
      dmt.doc_document_id,
      dmt.doc_gauge_id,
      dmt.pac_third_id,
      dmt.acs_financial_account_id doc_financial_account_id,
      dmt.acs_division_account_id doc_division_account_id,
      pos.acs_financial_account_id pos_financial_account_id,
      pos.acs_division_account_id pos_division_account_id,
      dmt.pc_lang_id,
      pos.gco_good_id
      from
      doc_document dmt,
      doc_position pos,
      pac_person per,
      doc_gauge gau,
      doc_gauge_structured gst,
      gco_good goo,
      doc_foot foo
      where
      dmt.doc_document_id=pos.doc_document_id(+)
      and dmt.pac_third_id=per.pac_person_id
      and dmt.doc_gauge_id=gau.doc_gauge_id
      and gau.doc_gauge_id=gst.doc_gauge_id
      and pos.gco_good_id=goo.gco_good_id(+)
      and dmt.doc_document_id=foo.doc_document_id(+)
      and gau.c_admin_domain='2'
      and pos.c_gauge_type_pos in ('1','5')
      and dmt.dmt_date_document >= vDateFrom
      and dmt.dmt_date_document <= vDateTo
        ;
end IND_C9_DOC_INVOICE_LIST;
