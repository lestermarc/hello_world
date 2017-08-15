--------------------------------------------------------
--  DDL for Procedure RPT_ACR_AGED_CUSTOMER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_AGED_CUSTOMER" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, procparam_0    in     varchar2
, procparam_1    in     varchar2
, procparam_2    in     varchar2
, procparam_3    in     varchar2
, procparam_4    in     varchar2
, procparam_5    in     varchar2
, procparam_6    in     varchar2
, procparam_7    in     varchar2
, parameter_13   in     varchar2
, parameter_14   in     varchar2
, parameter_15   in     varchar2
, parameter_16   in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
)
is
/**
* description used for report ACR_AGED_CUSTOMER (Echéanciers clients)

* @author SDO 2003
* @lastUpdate VHA 26 JUNE 2013
* @public
* @param procparam_0: Acs_sub_set_ID       ACS_SUB_SET_ID
* @param procparam_1: Compte du ...        ACC_NUMBER (AUXILIARY_ACCOUNT)
* @param procparam_2: Compte au ...        ACC_NUMBER (AUXILIARY_ACCOUNT)
* @param procparam_3: Date référence       Date pour le calcul des escomptes et des réévaluations
* @param procparam_4: Division_ID (List) NULL = All  or ACS_DIVISION_ACCOUNT_ID list
* @param procparam_5: Collectiv_ID (List)  '' = All sinon liste des ID
* @param procparam_6: Type de cours        1 : Cours du jour (par défaut)
                                                                  2 : Cours d'évaluation
                                                                  3 : Cours d'inventaire
                                                                  4 : Cours de bouclement
                                                                  5 : Cours de facturation
* @param procparam_7: Currency_ID List)   '' = All sinon liste des ID   (ACS_FINANCIAL_CURRENCY_ID)
* @param parameter_13    C_TYPE_CUMUL = 'INT' :  0=No / 1=Yes
* @param parameter_14    C_TYPE_CUMUL = 'EXT' :  0=No / 1=Yes
* @param parameter_15    C_TYPE_CUMUL = 'PRE' :  0=No / 1=Yes
* @param parameter_16    C_TYPE_CUMUL = 'ENG' :  0=No / 1=Yes
*/
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id PCS.PC_USER.PC_USER_ID%type := null;
begin
  if (procuser_lanid is not null) and (pc_user_id is not null)  then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => null
                                  , iConliId  => null);
      vpc_lang_id  := PCS.PC_I_LIB_SESSION.getUserlangId;
      vpc_user_id  := PCS.PC_I_LIB_SESSION.getUserId;
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
  if (procparam_3 is null) then
    open arefcursor for
      select par.par_document
           , par.par_blocked_document
           , par.acs_acs_financial_currency_id
           , (select cub.currency
                from pcs.pc_curr cub
                   , acs_financial_currency cfb
               where cfb.acs_financial_currency_id = par.acs_acs_financial_currency_id
                 and cub.pc_curr_id = cfb.pc_curr_id) currency_mb
           , par.acs_financial_currency_id
           , (select cub.currency
                from pcs.pc_curr cub
                   , acs_financial_currency cfb
               where cfb.acs_financial_currency_id = par.acs_financial_currency_id
                 and cub.pc_curr_id = cfb.pc_curr_id) currency_me
           , doc.doc_number
           , cat.c_type_catalogue
           , sub.c_type_cumul
           , exp.act_expiry_id
           , exp.act_document_id
           , exp.act_part_imputation_id
           , exp.c_status_expiry
           , exp.exp_adapted
           , to_char(exp.exp_adapted, 'YYYY-IW') week_year
           , to_char(exp.exp_adapted, 'YYYY-MM') month_year
           , to_char(exp.exp_adapted, 'YYYY') year
           , exp.exp_calculated
           , exp.exp_amount_lc
           , exp.exp_amount_fc
           , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, sysdate, 1) discount_lc
           , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, sysdate, 0) discount_fc
           , act_functions.totalpaymentat(exp.act_expiry_id, sysdate, 1) det_paied_lc
           , act_functions.totalpaymentat(exp.act_expiry_id, sysdate, 0) det_paied_fc
           , exp.exp_amount_lc - act_functions.totalpaymentat(exp.act_expiry_id, sysdate, 1) solde_exp_lc
           , exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, sysdate, 0) solde_exp_fc
           , act_currency_evaluation.getconvertamount(exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, sysdate, 0)
                                                    , par.acs_financial_currency_id
                                                    , par.acs_acs_financial_currency_id
                                                    , sysdate
                                                    , procparam_6
                                                     ) solde_reeval_lc
           , exp.exp_slice
           , act_functions.lastclaimsnumber(exp.act_expiry_id) last_claims_level
           , act_functions.lastclaimsdate(exp.act_expiry_id) last_claims_date
           , exp.acs_fin_acc_s_payment_id
           , pmm.acs_payment_method_id
           , (select pme.c_method_category
                from acs_payment_method pme
               where pme.acs_payment_method_id = pmm.acs_payment_method_id) c_method_category
           , (select de4.des_description_summary
                from acs_description de4
               where de4.acs_payment_method_id = pmm.acs_payment_method_id
                 and de4.pc_lang_id = vpc_lang_id) payment_method_descr
           , imp.acs_period_id
           , imp.imf_transaction_date
           , imp.imf_value_date
           , imp.imf_description
           , imp.acs_financial_account_id
           , (select acf.acc_number
                from acs_account acf
               where acf.acs_account_id = imp.acs_financial_account_id) acc_number_fin
           , (select de1.des_description_summary
                from acs_description de1
               where de1.acs_account_id = imp.acs_financial_account_id
                 and de1.pc_lang_id = vpc_lang_id) account_fin_descr
           , jou.jou_number
           , ejo.c_etat_journal
           , imp.imf_acs_division_account_id
           , cus.pac_custom_partner_id
           , cus.acs_auxiliary_account_id
           , cus.c_partner_category
           , acc.acc_number acc_number_aux
           , (select de2.des_description_summary
                from acs_description de2
               where de2.acs_account_id = cus.acs_auxiliary_account_id
                 and de2.pc_lang_id = vpc_lang_id) account_aux_descr
           , acc.acs_sub_set_id
           , (select de3.des_description_summary
                from acs_description de3
               where de3.acs_sub_set_id = acc.acs_sub_set_id
                 and de3.pc_lang_id = vpc_lang_id) sub_set_descr
           , aux.c_type_account
           , per.per_name
           , per.per_forename
           , per.per_short_name
           , per.per_activity
           , per.per_key1
           , (select adr.add_format
                from pac_address adr
               where adr.pac_person_id = cus.pac_custom_partner_id
                 and adr.add_principal = '1') add_format
        from pac_person per
           , acs_auxiliary_account aux
           , pac_custom_partner cus
           , acs_financial_account fin
           , act_financial_imputation imp
           , act_etat_journal ejo
           , act_journal jou
           , acs_fin_acc_s_payment pmm
           , act_expiry exp
           , acj_catalogue_document cat
           , act_document doc
           , act_part_imputation par
           , acs_account acc
           , acj_sub_set_cat sub
           , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, procparam_4) ) AUT
       where par.act_document_id = doc.act_document_id
         and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
         and cat.c_type_catalogue <> '8'
         and   -- Transaction de relance
             par.act_part_imputation_id = exp.act_part_imputation_id
         and exp_calc_net + 0 = 1
         and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.act_expiry_id, sysdate) = 1
         and exp.acs_fin_acc_s_payment_id = pmm.acs_fin_acc_s_payment_id(+)
         and doc.act_journal_id = jou.act_journal_id
         and doc.act_journal_id = ejo.act_journal_id
         and ejo.c_sub_set = 'REC'
         and exp.act_part_imputation_id = imp.act_part_imputation_id
         and imp.act_det_payment_id is null
         and imp.acs_auxiliary_account_id is not null
         and imp.acs_financial_account_id = fin.acs_financial_account_id
         and exp.c_status_expiry = 0
         and fin.fin_collective = 1
         and acc.acc_number >= procparam_1
         and acc.acc_number <= procparam_2
         and (   acc.acs_sub_set_id = procparam_0
              or procparam_0 is null)
         and IMP.IMF_ACS_DIVISION_ACCOUNT_ID is not null
         and AUT.column_value = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
         and (   instr(',' || procparam_5 || ',', to_char(',' || fin.acs_financial_account_id || ',') ) > 0
              or procparam_5 is null)
         and (   instr(',' || procparam_7 || ',', to_char(',' || par.acs_financial_currency_id || ',') ) > 0
              or procparam_7 is null)
         and par.pac_custom_partner_id = cus.pac_custom_partner_id
         and cus.acs_auxiliary_account_id = acc.acs_account_id
         and cus.acs_auxiliary_account_id = aux.acs_auxiliary_account_id
         and cus.pac_custom_partner_id = per.pac_person_id
         and doc.acj_catalogue_document_id = sub.acj_catalogue_document_id
         and sub.c_sub_set = 'REC'
         and decode(sub.C_TYPE_CUMUL
                  , 'INT', decode(parameter_13, '1', 1, 0)
                  , 'EXT', decode(parameter_14, '1', 1, 0)
                  , 'PRE', decode(parameter_15, '1', 1, 0)
                  , 'ENG', decode(parameter_16, '1', 1, 0)
                  , 0
                   ) = 1;
  else
    open arefcursor for
      select par.par_document
           , par.par_blocked_document
           , par.acs_acs_financial_currency_id
           , (select cub.currency
                from pcs.pc_curr cub
                   , acs_financial_currency cfb
               where cfb.acs_financial_currency_id = par.acs_acs_financial_currency_id
                 and cub.pc_curr_id = cfb.pc_curr_id) currency_mb
           , par.acs_financial_currency_id
           , (select cub.currency
                from pcs.pc_curr cub
                   , acs_financial_currency cfb
               where cfb.acs_financial_currency_id = par.acs_financial_currency_id
                 and cub.pc_curr_id = cfb.pc_curr_id) currency_me
           , doc.doc_number
           , cat.c_type_catalogue
           , sub.c_type_cumul
           , exp.act_expiry_id
           , exp.act_document_id
           , exp.act_part_imputation_id
           , exp.c_status_expiry
           , exp.exp_adapted
           , to_char(exp.exp_adapted, 'YYYY-IW') week_year
           , to_char(exp.exp_adapted, 'YYYY-MM') month_year
           , to_char(exp.exp_adapted, 'YYYY') year
           , exp.exp_calculated
           , exp.exp_amount_lc
           , exp.exp_amount_fc
           , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, to_date(procparam_3, 'YYYYMMDD'), 1) discount_lc
           , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, to_date(procparam_3, 'YYYYMMDD'), 0) discount_fc
           , act_functions.totalpaymentat(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD'), 1) det_paied_lc
           , act_functions.totalpaymentat(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD'), 0) det_paied_fc
           , exp.exp_amount_lc - act_functions.totalpaymentat(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD'), 1) solde_exp_lc
           , exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD'), 0) solde_exp_fc
           , act_currency_evaluation.getconvertamount(exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD'), 0)
                                                    , par.acs_financial_currency_id
                                                    , par.acs_acs_financial_currency_id
                                                    , to_date(procparam_3, 'YYYYMMDD')
                                                    , procparam_6
                                                     ) solde_reeval_lc
           , exp.exp_slice
           , act_functions.lastclaimsnumber(exp.act_expiry_id) last_claims_level
           , act_functions.lastclaimsdate(exp.act_expiry_id) last_claims_date
           , exp.acs_fin_acc_s_payment_id
           , pmm.acs_payment_method_id
           , (select pme.c_method_category
                from acs_payment_method pme
               where pme.acs_payment_method_id = pmm.acs_payment_method_id) c_method_category
           , (select de4.des_description_summary
                from acs_description de4
               where de4.acs_payment_method_id = pmm.acs_payment_method_id
                 and de4.pc_lang_id = vpc_lang_id) payment_method_descr
           , imp.acs_period_id
           , imp.imf_transaction_date
           , imp.imf_value_date
           , imp.imf_description
           , imp.acs_financial_account_id
           , (select acf.acc_number
                from acs_account acf
               where acf.acs_account_id = imp.acs_financial_account_id) acc_number_fin
           , (select de1.des_description_summary
                from acs_description de1
               where de1.acs_account_id = imp.acs_financial_account_id
                 and de1.pc_lang_id = vpc_lang_id) account_fin_descr
           , jou.jou_number
           , ejo.c_etat_journal
           , imp.imf_acs_division_account_id
           , cus.pac_custom_partner_id
           , cus.acs_auxiliary_account_id
           , cus.c_partner_category
           , acc.acc_number acc_number_aux
           , (select de2.des_description_summary
                from acs_description de2
               where de2.acs_account_id = cus.acs_auxiliary_account_id
                 and de2.pc_lang_id = vpc_lang_id) account_aux_descr
           , acc.acs_sub_set_id
           , (select de3.des_description_summary
                from acs_description de3
               where de3.acs_sub_set_id = acc.acs_sub_set_id
                 and de3.pc_lang_id = vpc_lang_id) sub_set_descr
           , aux.c_type_account
           , per.per_name
           , per.per_forename
           , per.per_short_name
           , per.per_activity
           , per.per_key1
           , (select adr.add_format
                from pac_address adr
               where adr.pac_person_id = cus.pac_custom_partner_id
                 and adr.add_principal = '1') add_format
        from pac_person per
           , acs_auxiliary_account aux
           , pac_custom_partner cus
           , acs_financial_account fin
           , act_financial_imputation imp
           , act_etat_journal ejo
           , act_journal jou
           , acs_fin_acc_s_payment pmm
           , act_expiry exp
           , acj_catalogue_document cat
           , act_document doc
           , act_part_imputation par
           , acs_account acc
           , acj_sub_set_cat sub
           , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, procparam_4) ) AUT
       where par.act_document_id = doc.act_document_id
         and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
         and cat.c_type_catalogue <> '8'
         and   -- Transaction de relance
             par.act_part_imputation_id = exp.act_part_imputation_id
         and exp_calc_net + 0 = 1
         and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD') ) = 1
         and exp.acs_fin_acc_s_payment_id = pmm.acs_fin_acc_s_payment_id(+)
         and doc.act_journal_id = jou.act_journal_id
         and doc.act_journal_id = ejo.act_journal_id
         and ejo.c_sub_set = 'REC'
         and exp.act_part_imputation_id = imp.act_part_imputation_id
         and imp.act_det_payment_id is null
         and imp.acs_auxiliary_account_id is not null
         and imp.acs_financial_account_id = fin.acs_financial_account_id
         and (   imp.imf_transaction_date <= to_date(procparam_3, 'YYYYMMDD')
              or procparam_3 is null)
         and fin.fin_collective = 1
         and acc.acc_number >= procparam_1
         and acc.acc_number <= procparam_2
         and (   acc.acs_sub_set_id = procparam_0
              or procparam_0 is null)
         and IMP.IMF_ACS_DIVISION_ACCOUNT_ID is not null
         and AUT.column_value = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
         and (   instr(',' || procparam_5 || ',', to_char(',' || fin.acs_financial_account_id || ',') ) > 0
              or procparam_5 is null)
         and (   instr(',' || procparam_7 || ',', to_char(',' || par.acs_financial_currency_id || ',') ) > 0
              or procparam_7 is null)
         and par.pac_custom_partner_id = cus.pac_custom_partner_id
         and cus.acs_auxiliary_account_id = acc.acs_account_id
         and cus.acs_auxiliary_account_id = aux.acs_auxiliary_account_id
         and cus.pac_custom_partner_id = per.pac_person_id
         and sub.acj_catalogue_document_id = doc.acj_catalogue_document_id
         and sub.c_sub_set = 'REC'
         and decode(sub.C_TYPE_CUMUL
                  , 'INT', decode(parameter_13, '1', 1, 0)
                  , 'EXT', decode(parameter_14, '1', 1, 0)
                  , 'PRE', decode(parameter_15, '1', 1, 0)
                  , 'ENG', decode(parameter_16, '1', 1, 0)
                  , 0
                   ) = 1;
  end if;
else     -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
 if (procparam_3 is null) then
    open arefcursor for
      select par.par_document
           , par.par_blocked_document
           , par.acs_acs_financial_currency_id
           , (select cub.currency
                from pcs.pc_curr cub
                   , acs_financial_currency cfb
               where cfb.acs_financial_currency_id = par.acs_acs_financial_currency_id
                 and cub.pc_curr_id = cfb.pc_curr_id) currency_mb
           , par.acs_financial_currency_id
           , (select cub.currency
                from pcs.pc_curr cub
                   , acs_financial_currency cfb
               where cfb.acs_financial_currency_id = par.acs_financial_currency_id
                 and cub.pc_curr_id = cfb.pc_curr_id) currency_me
           , doc.doc_number
           , cat.c_type_catalogue
           , sub.c_type_cumul
           , exp.act_expiry_id
           , exp.act_document_id
           , exp.act_part_imputation_id
           , exp.c_status_expiry
           , exp.exp_adapted
           , to_char(exp.exp_adapted, 'YYYY-IW') week_year
           , to_char(exp.exp_adapted, 'YYYY-MM') month_year
           , to_char(exp.exp_adapted, 'YYYY') year
           , exp.exp_calculated
           , exp.exp_amount_lc
           , exp.exp_amount_fc
           , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, sysdate, 1) discount_lc
           , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, sysdate, 0) discount_fc
           , act_functions.totalpaymentat(exp.act_expiry_id, sysdate, 1) det_paied_lc
           , act_functions.totalpaymentat(exp.act_expiry_id, sysdate, 0) det_paied_fc
           , exp.exp_amount_lc - act_functions.totalpaymentat(exp.act_expiry_id, sysdate, 1) solde_exp_lc
           , exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, sysdate, 0) solde_exp_fc
           , act_currency_evaluation.getconvertamount(exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, sysdate, 0)
                                                    , par.acs_financial_currency_id
                                                    , par.acs_acs_financial_currency_id
                                                    , sysdate
                                                    , procparam_6
                                                     ) solde_reeval_lc
           , exp.exp_slice
           , act_functions.lastclaimsnumber(exp.act_expiry_id) last_claims_level
           , act_functions.lastclaimsdate(exp.act_expiry_id) last_claims_date
           , exp.acs_fin_acc_s_payment_id
           , pmm.acs_payment_method_id
           , (select pme.c_method_category
                from acs_payment_method pme
               where pme.acs_payment_method_id = pmm.acs_payment_method_id) c_method_category
           , (select de4.des_description_summary
                from acs_description de4
               where de4.acs_payment_method_id = pmm.acs_payment_method_id
                 and de4.pc_lang_id = vpc_lang_id) payment_method_descr
           , imp.acs_period_id
           , imp.imf_transaction_date
           , imp.imf_value_date
           , imp.imf_description
           , imp.acs_financial_account_id
           , (select acf.acc_number
                from acs_account acf
               where acf.acs_account_id = imp.acs_financial_account_id) acc_number_fin
           , (select de1.des_description_summary
                from acs_description de1
               where de1.acs_account_id = imp.acs_financial_account_id
                 and de1.pc_lang_id = vpc_lang_id) account_fin_descr
           , jou.jou_number
           , ejo.c_etat_journal
           , imp.imf_acs_division_account_id
           , cus.pac_custom_partner_id
           , cus.acs_auxiliary_account_id
           , cus.c_partner_category
           , acc.acc_number acc_number_aux
           , (select de2.des_description_summary
                from acs_description de2
               where de2.acs_account_id = cus.acs_auxiliary_account_id
                 and de2.pc_lang_id = vpc_lang_id) account_aux_descr
           , acc.acs_sub_set_id
           , (select de3.des_description_summary
                from acs_description de3
               where de3.acs_sub_set_id = acc.acs_sub_set_id
                 and de3.pc_lang_id = vpc_lang_id) sub_set_descr
           , aux.c_type_account
           , per.per_name
           , per.per_forename
           , per.per_short_name
           , per.per_activity
           , per.per_key1
           , (select adr.add_format
                from pac_address adr
               where adr.pac_person_id = cus.pac_custom_partner_id
                 and adr.add_principal = '1') add_format
        from pac_person per
           , acs_auxiliary_account aux
           , pac_custom_partner cus
           , acs_financial_account fin
           , act_financial_imputation imp
           , act_etat_journal ejo
           , act_journal jou
           , acs_fin_acc_s_payment pmm
           , act_expiry exp
           , acj_catalogue_document cat
           , act_document doc
           , act_part_imputation par
           , acs_account acc
           , acj_sub_set_cat sub
       where par.act_document_id = doc.act_document_id
         and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
         and cat.c_type_catalogue <> '8'
         and   -- Transaction de relance
             par.act_part_imputation_id = exp.act_part_imputation_id
         and exp_calc_net + 0 = 1
         and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.act_expiry_id, sysdate) = 1
         and exp.acs_fin_acc_s_payment_id = pmm.acs_fin_acc_s_payment_id(+)
         and doc.act_journal_id = jou.act_journal_id
         and doc.act_journal_id = ejo.act_journal_id
         and ejo.c_sub_set = 'REC'
         and exp.act_part_imputation_id = imp.act_part_imputation_id
         and imp.act_det_payment_id is null
         and imp.acs_auxiliary_account_id is not null
         and imp.acs_financial_account_id = fin.acs_financial_account_id
         and exp.c_status_expiry = 0
         and fin.fin_collective = 1
         and acc.acc_number >= procparam_1
         and acc.acc_number <= procparam_2
         and (   acc.acs_sub_set_id = procparam_0
              or procparam_0 is null)
         and (   instr(',' || procparam_5 || ',', to_char(',' || fin.acs_financial_account_id || ',') ) > 0
              or procparam_5 is null)
         and (   instr(',' || procparam_7 || ',', to_char(',' || par.acs_financial_currency_id || ',') ) > 0
              or procparam_7 is null)
         and par.pac_custom_partner_id = cus.pac_custom_partner_id
         and cus.acs_auxiliary_account_id = acc.acs_account_id
         and cus.acs_auxiliary_account_id = aux.acs_auxiliary_account_id
         and cus.pac_custom_partner_id = per.pac_person_id
         and doc.acj_catalogue_document_id = sub.acj_catalogue_document_id
         and sub.c_sub_set = 'REC'
         and decode(sub.C_TYPE_CUMUL
                  , 'INT', decode(parameter_13, '1', 1, 0)
                  , 'EXT', decode(parameter_14, '1', 1, 0)
                  , 'PRE', decode(parameter_15, '1', 1, 0)
                  , 'ENG', decode(parameter_16, '1', 1, 0)
                  , 0
                   ) = 1;
  else
    open arefcursor for
      select par.par_document
           , par.par_blocked_document
           , par.acs_acs_financial_currency_id
           , (select cub.currency
                from pcs.pc_curr cub
                   , acs_financial_currency cfb
               where cfb.acs_financial_currency_id = par.acs_acs_financial_currency_id
                 and cub.pc_curr_id = cfb.pc_curr_id) currency_mb
           , par.acs_financial_currency_id
           , (select cub.currency
                from pcs.pc_curr cub
                   , acs_financial_currency cfb
               where cfb.acs_financial_currency_id = par.acs_financial_currency_id
                 and cub.pc_curr_id = cfb.pc_curr_id) currency_me
           , doc.doc_number
           , cat.c_type_catalogue
           , sub.c_type_cumul
           , exp.act_expiry_id
           , exp.act_document_id
           , exp.act_part_imputation_id
           , exp.c_status_expiry
           , exp.exp_adapted
           , to_char(exp.exp_adapted, 'YYYY-IW') week_year
           , to_char(exp.exp_adapted, 'YYYY-MM') month_year
           , to_char(exp.exp_adapted, 'YYYY') year
           , exp.exp_calculated
           , exp.exp_amount_lc
           , exp.exp_amount_fc
           , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, to_date(procparam_3, 'YYYYMMDD'), 1) discount_lc
           , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, to_date(procparam_3, 'YYYYMMDD'), 0) discount_fc
           , act_functions.totalpaymentat(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD'), 1) det_paied_lc
           , act_functions.totalpaymentat(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD'), 0) det_paied_fc
           , exp.exp_amount_lc - act_functions.totalpaymentat(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD'), 1) solde_exp_lc
           , exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD'), 0) solde_exp_fc
           , act_currency_evaluation.getconvertamount(exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD'), 0)
                                                    , par.acs_financial_currency_id
                                                    , par.acs_acs_financial_currency_id
                                                    , to_date(procparam_3, 'YYYYMMDD')
                                                    , procparam_6
                                                     ) solde_reeval_lc
           , exp.exp_slice
           , act_functions.lastclaimsnumber(exp.act_expiry_id) last_claims_level
           , act_functions.lastclaimsdate(exp.act_expiry_id) last_claims_date
           , exp.acs_fin_acc_s_payment_id
           , pmm.acs_payment_method_id
           , (select pme.c_method_category
                from acs_payment_method pme
               where pme.acs_payment_method_id = pmm.acs_payment_method_id) c_method_category
           , (select de4.des_description_summary
                from acs_description de4
               where de4.acs_payment_method_id = pmm.acs_payment_method_id
                 and de4.pc_lang_id = vpc_lang_id) payment_method_descr
           , imp.acs_period_id
           , imp.imf_transaction_date
           , imp.imf_value_date
           , imp.imf_description
           , imp.acs_financial_account_id
           , (select acf.acc_number
                from acs_account acf
               where acf.acs_account_id = imp.acs_financial_account_id) acc_number_fin
           , (select de1.des_description_summary
                from acs_description de1
               where de1.acs_account_id = imp.acs_financial_account_id
                 and de1.pc_lang_id = vpc_lang_id) account_fin_descr
           , jou.jou_number
           , ejo.c_etat_journal
           , imp.imf_acs_division_account_id
           , cus.pac_custom_partner_id
           , cus.acs_auxiliary_account_id
           , cus.c_partner_category
           , acc.acc_number acc_number_aux
           , (select de2.des_description_summary
                from acs_description de2
               where de2.acs_account_id = cus.acs_auxiliary_account_id
                 and de2.pc_lang_id = vpc_lang_id) account_aux_descr
           , acc.acs_sub_set_id
           , (select de3.des_description_summary
                from acs_description de3
               where de3.acs_sub_set_id = acc.acs_sub_set_id
                 and de3.pc_lang_id = vpc_lang_id) sub_set_descr
           , aux.c_type_account
           , per.per_name
           , per.per_forename
           , per.per_short_name
           , per.per_activity
           , per.per_key1
           , (select adr.add_format
                from pac_address adr
               where adr.pac_person_id = cus.pac_custom_partner_id
                 and adr.add_principal = '1') add_format
        from pac_person per
           , acs_auxiliary_account aux
           , pac_custom_partner cus
           , acs_financial_account fin
           , act_financial_imputation imp
           , act_etat_journal ejo
           , act_journal jou
           , acs_fin_acc_s_payment pmm
           , act_expiry exp
           , acj_catalogue_document cat
           , act_document doc
           , act_part_imputation par
           , acs_account acc
           , acj_sub_set_cat sub
       where par.act_document_id = doc.act_document_id
         and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
         and cat.c_type_catalogue <> '8'
         and   -- Transaction de relance
             par.act_part_imputation_id = exp.act_part_imputation_id
         and exp_calc_net + 0 = 1
         and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.act_expiry_id, to_date(procparam_3, 'YYYYMMDD') ) = 1
         and exp.acs_fin_acc_s_payment_id = pmm.acs_fin_acc_s_payment_id(+)
         and doc.act_journal_id = jou.act_journal_id
         and doc.act_journal_id = ejo.act_journal_id
         and ejo.c_sub_set = 'REC'
         and exp.act_part_imputation_id = imp.act_part_imputation_id
         and imp.act_det_payment_id is null
         and imp.acs_auxiliary_account_id is not null
         and imp.acs_financial_account_id = fin.acs_financial_account_id
         and (   imp.imf_transaction_date <= to_date(procparam_3, 'YYYYMMDD')
              or procparam_3 is null)
         and fin.fin_collective = 1
         and acc.acc_number >= procparam_1
         and acc.acc_number <= procparam_2
         and (   acc.acs_sub_set_id = procparam_0
              or procparam_0 is null)
         and (   instr(',' || procparam_5 || ',', to_char(',' || fin.acs_financial_account_id || ',') ) > 0
              or procparam_5 is null)
         and (   instr(',' || procparam_7 || ',', to_char(',' || par.acs_financial_currency_id || ',') ) > 0
              or procparam_7 is null)
         and par.pac_custom_partner_id = cus.pac_custom_partner_id
         and cus.acs_auxiliary_account_id = acc.acs_account_id
         and cus.acs_auxiliary_account_id = aux.acs_auxiliary_account_id
         and cus.pac_custom_partner_id = per.pac_person_id
         and sub.acj_catalogue_document_id = doc.acj_catalogue_document_id
         and sub.c_sub_set = 'REC'
         and decode(sub.C_TYPE_CUMUL
                  , 'INT', decode(parameter_13, '1', 1, 0)
                  , 'EXT', decode(parameter_14, '1', 1, 0)
                  , 'PRE', decode(parameter_15, '1', 1, 0)
                  , 'ENG', decode(parameter_16, '1', 1, 0)
                  , 0
                   ) = 1;
  end if;
  end if;
end RPT_ACR_AGED_CUSTOMER;
