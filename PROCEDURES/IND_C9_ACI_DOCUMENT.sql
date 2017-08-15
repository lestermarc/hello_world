--------------------------------------------------------
--  DDL for Procedure IND_C9_ACI_DOCUMENT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_ACI_DOCUMENT" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PROCPARAM_0 in     number
)

is
/**
* Procédure stockée utilisée dans un rapport. Document d'intégration
*
* @author
* @lastUpdate
* @version
* @public
* @param PROCPARAM_0    id du docuement        (ACI_DOCUMENT_ID)
*/
begin

--pcs.pc_init_session.setLanId (procuser_lanid);

open aRefCursor for
    select
    a.aci_document_id,
    a.C_INTERFACE_CONTROL,
    a.C_INTERFACE_ORIGIN,
    a.c_status_document,
    a.c_fail_reason,
    a.doc_number,
    a.doc_document_date,
    a.a_datecre,
    a.a_idcre,
    a.a_datemod,
    a.a_idmod,
    b.aci_financial_imputation_id,
    b.IMF_CONTROL_FLAG,
    b.IMF_VALUE_DATE,
    b.IMF_TRANSACTION_DATE,
    b.ACC_NUMBER,
    b.DIV_NUMBER,
    b.RCO_TITLE,
    b.imf_description,
    b.CURRENCY2,
    b.IMF_AMOUNT_LC_D,
    b.IMF_AMOUNT_LC_C,
    b.IMF_EXCHANGE_RATE,
    b.IMF_BASE_PRICE,
    b.CURRENCY1,
    b.IMF_AMOUNT_FC_D,
    b.IMF_AMOUNT_FC_C,
    b.a_datecre a_datecre_imp,
    b.a_idcre a_idcre_imp,
    b.a_datemod a_datemod_imp,
    b.a_idmod a_idmod_imp,
    (select decode(max(acc.acc_number),null,'Compte '||b.acc_number||' inexistant dans la Gestion des comptes','OK')
     from acs_account acc, acs_financial_account fin
     where acc.acs_account_id=fin.acs_financial_account_id
     and acc.acc_number= b.acc_number) test_account,
    (select decode(max(acc.acc_number),null,'Division '||b.div_number||' inexistante dans la Gestion des comptes','OK')
     from acs_account acc, acs_division_account fin
     where acc.acs_account_id=fin.acs_division_account_id
     and acc.acc_number= b.div_number) test_division,
    (select case
             when max(rec.rco_title) is null and b.rco_title is not null
             then 'Dossier '||b.rco_title||' inexistant dans la Gestion des dossiers'
             else 'OK'
            end
     from doc_record rec
     where rec.rco_title= b.rco_title) test_dossier
    from
    aci_document a,
    aci_financial_imputation b
    where
    a.aci_document_id=b.aci_document_id
    and a.aci_document_id=PROCPARAM_0;

end IND_C9_ACI_DOCUMENT;
