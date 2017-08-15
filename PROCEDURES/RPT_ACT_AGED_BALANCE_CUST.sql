--------------------------------------------------------
--  DDL for Procedure RPT_ACT_AGED_BALANCE_CUST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_AGED_BALANCE_CUST" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_1    in     varchar2
, parameter_2    in     varchar2
, parameter_3    in     varchar2
, parameter_4    in     varchar2
, parameter_5    in     varchar2
, parameter_6    in     varchar2
, parameter_11   in     varchar2
, procparam_0    in     varchar2
, procparam_1    in     varchar2
, procparam_2    in     varchar2
, procparam_3    in     varchar2
, procparam_4    in     varchar2
, procparam_5    in     varchar2
, procparam_6    in     number
, procparam_7    in     number
, procparam_8    in     varchar2
, procparam_9    in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
)
/**
* description used for report ACT_AGED_BALANCE_CUST (Echéanciers fournisseurs)

* @author SDO 2003
* @lastupdate SMA 13 January 2016
* @public
* @param parameter_1    Only expired : 0=No / 1=Yes
* @param parameter_2    Date expired : YYYYMMDD
* @param parameter_3    C_TYPE_CUMUL = INT : 0=No / 1=Yes
* @param parameter_4    C_TYPE_CUMUL = EXT : 0=No / 1=Yes
* @param parameter_5    C_TYPE_CUMUL = PRE : 0=No / 1=Yes
* @param parameter_6    C_TYPE_CUMUL = ENG : 0=No / 1=Yes
* @param parameter_11   Only summary : 0=No / 1=Yes
* @param procparam_1    Account from        ACC_NUMBER (AUXILIARY_ACCOUNT)
* @param procparam_2    Account to        ACC_NUMBER (AUXILIARY_ACCOUNT)
* @param procparam_3    Reference date
* @param procparam_3    SUBSET ID      Date pour le calcul des escomptes et des réévaluations
* @param procparam_4    Divisions (# = All  / null = selection (COM_LIST))
* @param procparam_5    Collectiv_ID (List)  # = All sinon liste des ID
* @param procparam_6    Type de cours        1 : Cours du jour (par défaut)
                                             2 : Cours d'évaluation
                                             3 : Cours d'inventaire
                                             4 : Cours de bouclement
                                             5 : Cours de facturation
* @param procparam_7    Currency_ID List)   '' = All sinon liste des ID   (ACS_FINANCIAL_CURRENCY_ID)
* @param procparam_8    ACS_PAYMENT_METHOD_ID (List)  ('#'= All or ID List)
* @param procparam_9    Job ID (COM_LIST)
*/
is
  vdate       date;
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type   := null;
begin
  if (procuser_lanid is not null) then
    PCS.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    vpc_lang_id  := PCS.PC_I_LIB_SESSION.getUserlangId;
  end if;

  begin
    if procparam_2 is null then
      vdate  := trunc(sysdate);
    else
      vdate  := to_date(procparam_2, 'YYYYMMDD');
    end if;
  exception
    when others then
      vdate  := trunc(sysdate);
  end;

  delete from act_aged_balance_cust_temp;

  if (ACS_FUNCTION.ExistDIVI = 1) then
    if    (procparam_4 is null)
       or (procparam_4 <> '#') then
      insert into act_aged_balance_cust_temp
        (select par.par_document
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
              , case
                  when(procparam_7 = 1)
                  and (act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, vdate, 1) <> 0) then act_functions.discountdateafter
                                                                                                                                           (exp.act_document_id
                                                                                                                                          , exp.exp_slice
                                                                                                                                          , vdate
                                                                                                                                           )
                  else exp.exp_adapted
                end exp_adapted
              , exp.exp_calculated
              , vdate - exp.exp_adapted days
              , exp.exp_amount_lc
              , exp.exp_amount_fc
              , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, vdate, 1) discount_lc
              , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, vdate, 0) discount_fc
              , act_functions.totalpaymentat(exp.act_expiry_id, vdate, 1) det_paied_lc
              , act_functions.totalpaymentat(exp.act_expiry_id, vdate, 0) det_paied_fc
              , exp.exp_amount_lc - act_functions.totalpaymentat(exp.act_expiry_id, vdate, 1) solde_exp_lc
              , exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, vdate, 0) solde_exp_fc
              , act_currency_evaluation.getconvertamount(exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, vdate, 0)
                                                       , par.acs_financial_currency_id
                                                       , par.acs_acs_financial_currency_id
                                                       , vdate
                                                       , procparam_6
                                                        ) solde_reeval_lc
              , exp.exp_slice
              , exp.acs_fin_acc_s_payment_id
              , act_functions.lastclaimsnumber(exp.act_expiry_id) last_claims_level
              , act_functions.lastclaimsdate(exp.act_expiry_id) last_claims_date
              , co2.pco_descr pco_descr_exp
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
              , (select acd.acc_number
                   from acs_account acd
                  where acd.acs_account_id = imp.imf_acs_division_account_id) acc_number_div
              , (select de2.des_description_summary
                   from acs_description de2
                  where de2.acs_account_id = imp.imf_acs_division_account_id
                    and de2.pc_lang_id = vpc_lang_id) account_div_descr
              , cus.pac_custom_partner_id
              , cus.acs_auxiliary_account_id
              , cus.c_partner_category
              , co1.pco_descr pco_descr_cus
              , acc.acc_number acc_number_aux
              , (select de3.des_description_summary
                   from acs_description de3
                  where de3.acs_account_id = cus.acs_auxiliary_account_id
                    and de3.pc_lang_id = vpc_lang_id) account_aux_descr
              , (select de4.des_description_large
                   from acs_description de4
                  where de4.acs_account_id = cus.acs_auxiliary_account_id
                    and de4.pc_lang_id = vpc_lang_id) account_aux_large_descr
              , acc.acs_sub_set_id
              , (select de5.des_description_summary
                   from acs_description de5
                  where de5.acs_sub_set_id = acc.acs_sub_set_id
                    and de5.pc_lang_id = vpc_lang_id) sub_set_descr
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
              , (select de6.des_description_summary
                   from acs_description de6
                  where de6.acs_payment_method_id = pfc.acs_payment_method_id
                    and de6.pc_lang_id = vpc_lang_id) acs_payment_method_descr_cust
              , (select de7.des_description_summary
                   from acs_description de7
                  where de7.acs_payment_method_id = pfe.acs_payment_method_id
                    and de7.pc_lang_id = vpc_lang_id) acs_payment_method_descr_exp
           from acs_payment_method pae
              , acs_fin_acc_s_payment pfe
              , acs_payment_method pac
              , acs_fin_acc_s_payment pfc
              , pac_payment_condition co2
              , pac_payment_condition co1
              , pac_person per
              , acs_auxiliary_account aux
              , pac_custom_partner cus
              , acs_financial_account fin
              , act_financial_imputation imp
              , act_etat_journal ejo
              , act_journal jou
              , act_expiry exp
              , acj_catalogue_document cat
              , act_document doc
              , act_part_imputation par
              , acs_account acc
              , (select c_type_cumul
                      , acj_catalogue_document_id
                   from acj_sub_set_cat
                  where c_sub_set = 'REC') sub
              , (select LIS_ID_1
                   from COM_LIST
                  where LIS_JOB_ID = to_number(procparam_9)
                    and LIS_CODE = 'ACS_DIVISION_ACCOUNT_ID') LIS
          where par.act_document_id = doc.act_document_id
            and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
            and cat.c_type_catalogue <> '8'
            and   -- Transaction de relance
                par.act_part_imputation_id = exp.act_part_imputation_id
            and exp_calc_net + 0 = 1
            and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.act_expiry_id, vdate) = 1
            and doc.act_journal_id = jou.act_journal_id
            and doc.act_journal_id = ejo.act_journal_id
            and ejo.c_sub_set = 'REC'
            and exp.act_part_imputation_id = imp.act_part_imputation_id
            and imp.act_det_payment_id is null
            and imp.acs_auxiliary_account_id is not null
            and imp.acs_financial_account_id = fin.acs_financial_account_id
            and (   exp.C_STATUS_EXPIRY = 0
                 or (    exp.C_STATUS_EXPIRY <> 0
                     and exp.EXP_DATE_PMT_TOT > vdate) )
            and imp.imf_transaction_date <= vdate
            and fin.fin_collective = 1
            and acc.acc_number >= procparam_0
            and acc.acc_number <= procparam_1
            and (   acc.acs_sub_set_id = procparam_3
                 or procparam_3 is null)
            and IMP.IMF_ACS_DIVISION_ACCOUNT_ID is not null
            and IMP.IMF_ACS_DIVISION_ACCOUNT_ID = LIS.LIS_ID_1
            and (   instr(',' || procparam_5 || ',', to_char(',' || fin.acs_financial_account_id || ',') ) > 0
                 or procparam_5 = '#')
            and (   instr(',' || procparam_8 || ',', to_char(',' || pae.ACS_PAYMENT_METHOD_ID || ',') ) > 0
                 or procparam_8 = '#')
            and par.pac_custom_partner_id = cus.pac_custom_partner_id
            and cus.acs_auxiliary_account_id = acc.acs_account_id
            and cus.acs_auxiliary_account_id = aux.acs_auxiliary_account_id
            and cus.pac_custom_partner_id = per.pac_person_id
            and cus.pac_payment_condition_id = co1.pac_payment_condition_id
            and par.pac_payment_condition_id = co2.pac_payment_condition_id(+)
            and cus.acs_fin_acc_s_payment_id = pfc.acs_fin_acc_s_payment_id(+)
            and pfc.acs_payment_method_id = pac.acs_payment_method_id(+)
            and exp.acs_fin_acc_s_payment_id = pfe.acs_fin_acc_s_payment_id(+)
            and pfe.acs_payment_method_id = pae.acs_payment_method_id(+)
            and doc.acj_catalogue_document_id = sub.acj_catalogue_document_id(+)
            and
                --Ctrl_only)expired
                (   parameter_1 = '0'
                 or (    parameter_1 = '1'
                     and (case
                            when(procparam_7 = 1)
                            and (act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, sysdate, 1) <> 0) then act_functions.discountdateafter
                                                                                                                                           (exp.act_document_id
                                                                                                                                          , exp.exp_slice
                                                                                                                                          , sysdate
                                                                                                                                           )
                            else exp.exp_adapted
                          end
                         ) <= to_date(parameter_2, 'YYYYMMDD')
                    )
                )
            and
                --Ctrl_c_type_cumul
                (    (    parameter_3 = '1'
                      and sub.c_type_cumul = 'INT')
                 or (    parameter_4 = '1'
                     and sub.c_type_cumul = 'EXT')
                 or (    parameter_5 = '1'
                     and sub.c_type_cumul = 'PRE')
                 or (    parameter_6 = '1'
                     and sub.c_type_cumul = 'ENG')
                )
            and
                --Ctrl_c_etat_journal
                (   parameter_11 = '1'
                 or (    parameter_11 = '0'
                     and ejo.c_etat_journal <> 'BRO') ) );

      commit;
    else
      insert into act_aged_balance_cust_temp
        (select par.par_document
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
              , case
                  when(procparam_7 = 1)
                  and (act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, vdate, 1) <> 0) then act_functions.discountdateafter
                                                                                                                                           (exp.act_document_id
                                                                                                                                          , exp.exp_slice
                                                                                                                                          , vdate
                                                                                                                                           )
                  else exp.exp_adapted
                end exp_adapted
              , exp.exp_calculated
              , vdate - exp.exp_adapted days
              , exp.exp_amount_lc
              , exp.exp_amount_fc
              , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, vdate, 1) discount_lc
              , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, vdate, 0) discount_fc
              , act_functions.totalpaymentat(exp.act_expiry_id, vdate, 1) det_paied_lc
              , act_functions.totalpaymentat(exp.act_expiry_id, vdate, 0) det_paied_fc
              , exp.exp_amount_lc - act_functions.totalpaymentat(exp.act_expiry_id, vdate, 1) solde_exp_lc
              , exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, vdate, 0) solde_exp_fc
              , act_currency_evaluation.getconvertamount(exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, vdate, 0)
                                                       , par.acs_financial_currency_id
                                                       , par.acs_acs_financial_currency_id
                                                       , vdate
                                                       , procparam_6
                                                        ) solde_reeval_lc
              , exp.exp_slice
              , exp.acs_fin_acc_s_payment_id
              , act_functions.lastclaimsnumber(exp.act_expiry_id) last_claims_level
              , act_functions.lastclaimsdate(exp.act_expiry_id) last_claims_date
              , co2.pco_descr pco_descr_exp
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
              , (select acd.acc_number
                   from acs_account acd
                  where acd.acs_account_id = imp.imf_acs_division_account_id) acc_number_div
              , (select de2.des_description_summary
                   from acs_description de2
                  where de2.acs_account_id = imp.imf_acs_division_account_id
                    and de2.pc_lang_id = vpc_lang_id) account_div_descr
              , cus.pac_custom_partner_id
              , cus.acs_auxiliary_account_id
              , cus.c_partner_category
              , co1.pco_descr pco_descr_cus
              , acc.acc_number acc_number_aux
              , (select de3.des_description_summary
                   from acs_description de3
                  where de3.acs_account_id = cus.acs_auxiliary_account_id
                    and de3.pc_lang_id = vpc_lang_id) account_aux_descr
              , (select de4.des_description_large
                   from acs_description de4
                  where de4.acs_account_id = cus.acs_auxiliary_account_id
                    and de4.pc_lang_id = vpc_lang_id) account_aux_large_descr
              , acc.acs_sub_set_id
              , (select de5.des_description_summary
                   from acs_description de5
                  where de5.acs_sub_set_id = acc.acs_sub_set_id
                    and de5.pc_lang_id = vpc_lang_id) sub_set_descr
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
              , (select de6.des_description_summary
                   from acs_description de6
                  where de6.acs_payment_method_id = pfc.acs_payment_method_id
                    and de6.pc_lang_id = vpc_lang_id) acs_payment_method_descr_cust
              , (select de7.des_description_summary
                   from acs_description de7
                  where de7.acs_payment_method_id = pfe.acs_payment_method_id
                    and de7.pc_lang_id = vpc_lang_id) acs_payment_method_descr_exp
           from acs_payment_method pae
              , acs_fin_acc_s_payment pfe
              , acs_payment_method pac
              , acs_fin_acc_s_payment pfc
              , pac_payment_condition co2
              , pac_payment_condition co1
              , pac_person per
              , acs_auxiliary_account aux
              , pac_custom_partner cus
              , acs_financial_account fin
              , act_financial_imputation imp
              , act_etat_journal ejo
              , act_journal jou
              , act_expiry exp
              , acj_catalogue_document cat
              , act_document doc
              , act_part_imputation par
              , acs_account acc
              , (select c_type_cumul
                      , acj_catalogue_document_id
                   from acj_sub_set_cat
                  where c_sub_set = 'REC') sub
          where par.act_document_id = doc.act_document_id
            and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
            and cat.c_type_catalogue <> '8'
            and   -- Transaction de relance
                par.act_part_imputation_id = exp.act_part_imputation_id
            and exp_calc_net + 0 = 1
            and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.act_expiry_id, vdate) = 1
            and doc.act_journal_id = jou.act_journal_id
            and doc.act_journal_id = ejo.act_journal_id
            and ejo.c_sub_set = 'REC'
            and exp.act_part_imputation_id = imp.act_part_imputation_id
            and imp.act_det_payment_id is null
            and imp.acs_auxiliary_account_id is not null
            and imp.acs_financial_account_id = fin.acs_financial_account_id
            and (   exp.C_STATUS_EXPIRY = 0
                 or (    exp.C_STATUS_EXPIRY <> 0
                     and exp.EXP_DATE_PMT_TOT > vdate) )
            and imp.imf_transaction_date <= vdate
            and fin.fin_collective = 1
            and acc.acc_number >= procparam_0
            and acc.acc_number <= procparam_1
            and (   acc.acs_sub_set_id = procparam_3
                 or procparam_3 is null)
            and (IMP.IMF_ACS_DIVISION_ACCOUNT_ID is not null)
            and (   instr(',' || procparam_5 || ',', to_char(',' || fin.acs_financial_account_id || ',') ) > 0
                 or procparam_5 = '#')
            and (   instr(',' || procparam_8 || ',', to_char(',' || pae.ACS_PAYMENT_METHOD_ID || ',') ) > 0
                 or procparam_8 = '#')
            and par.pac_custom_partner_id = cus.pac_custom_partner_id
            and cus.acs_auxiliary_account_id = acc.acs_account_id
            and cus.acs_auxiliary_account_id = aux.acs_auxiliary_account_id
            and cus.pac_custom_partner_id = per.pac_person_id
            and cus.pac_payment_condition_id = co1.pac_payment_condition_id
            and par.pac_payment_condition_id = co2.pac_payment_condition_id(+)
            and cus.acs_fin_acc_s_payment_id = pfc.acs_fin_acc_s_payment_id(+)
            and pfc.acs_payment_method_id = pac.acs_payment_method_id(+)
            and exp.acs_fin_acc_s_payment_id = pfe.acs_fin_acc_s_payment_id(+)
            and pfe.acs_payment_method_id = pae.acs_payment_method_id(+)
            and doc.acj_catalogue_document_id = sub.acj_catalogue_document_id(+)
            and
                --Ctrl_only)expired
                (   parameter_1 = '0'
                 or (    parameter_1 = '1'
                     and (case
                            when(procparam_7 = 1)
                            and (act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, sysdate, 1) <> 0) then act_functions.discountdateafter
                                                                                                                                           (exp.act_document_id
                                                                                                                                          , exp.exp_slice
                                                                                                                                          , sysdate
                                                                                                                                           )
                            else exp.exp_adapted
                          end
                         ) <= to_date(parameter_2, 'YYYYMMDD')
                    )
                )
            and
                --Ctrl_c_type_cumul
                (    (    parameter_3 = '1'
                      and sub.c_type_cumul = 'INT')
                 or (    parameter_4 = '1'
                     and sub.c_type_cumul = 'EXT')
                 or (    parameter_5 = '1'
                     and sub.c_type_cumul = 'PRE')
                 or (    parameter_6 = '1'
                     and sub.c_type_cumul = 'ENG')
                )
            and
                --Ctrl_c_etat_journal
                (   parameter_11 = '1'
                 or (    parameter_11 = '0'
                     and ejo.c_etat_journal <> 'BRO') ) );

      commit;
    end if;
  else   -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
    insert into act_aged_balance_cust_temp
      (select par.par_document
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
            , case
                when(procparam_7 = 1)
                and (act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, vdate, 1) <> 0) then act_functions.discountdateafter
                                                                                                                                           (exp.act_document_id
                                                                                                                                          , exp.exp_slice
                                                                                                                                          , vdate
                                                                                                                                           )
                else exp.exp_adapted
              end exp_adapted
            , exp.exp_calculated
            , vdate - exp.exp_adapted days
            , exp.exp_amount_lc
            , exp.exp_amount_fc
            , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, vdate, 1) discount_lc
            , act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, vdate, 0) discount_fc
            , act_functions.totalpaymentat(exp.act_expiry_id, vdate, 1) det_paied_lc
            , act_functions.totalpaymentat(exp.act_expiry_id, vdate, 0) det_paied_fc
            , exp.exp_amount_lc - act_functions.totalpaymentat(exp.act_expiry_id, vdate, 1) solde_exp_lc
            , exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, vdate, 0) solde_exp_fc
            , act_currency_evaluation.getconvertamount(exp.exp_amount_fc - act_functions.totalpaymentat(exp.act_expiry_id, vdate, 0)
                                                     , par.acs_financial_currency_id
                                                     , par.acs_acs_financial_currency_id
                                                     , vdate
                                                     , procparam_6
                                                      ) solde_reeval_lc
            , exp.exp_slice
            , exp.acs_fin_acc_s_payment_id
            , act_functions.lastclaimsnumber(exp.act_expiry_id) last_claims_level
            , act_functions.lastclaimsdate(exp.act_expiry_id) last_claims_date
            , co2.pco_descr pco_descr_exp
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
            , (select acd.acc_number
                 from acs_account acd
                where acd.acs_account_id = imp.imf_acs_division_account_id) acc_number_div
            , (select de2.des_description_summary
                 from acs_description de2
                where de2.acs_account_id = imp.imf_acs_division_account_id
                  and de2.pc_lang_id = vpc_lang_id) account_div_descr
            , cus.pac_custom_partner_id
            , cus.acs_auxiliary_account_id
            , cus.c_partner_category
            , co1.pco_descr pco_descr_cus
            , acc.acc_number acc_number_aux
            , (select de3.des_description_summary
                 from acs_description de3
                where de3.acs_account_id = cus.acs_auxiliary_account_id
                  and de3.pc_lang_id = vpc_lang_id) account_aux_descr
            , (select de4.des_description_large
                 from acs_description de4
                where de4.acs_account_id = cus.acs_auxiliary_account_id
                  and de4.pc_lang_id = vpc_lang_id) account_aux_large_descr
            , acc.acs_sub_set_id
            , (select de5.des_description_summary
                 from acs_description de5
                where de5.acs_sub_set_id = acc.acs_sub_set_id
                  and de5.pc_lang_id = vpc_lang_id) sub_set_descr
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
            , (select de6.des_description_summary
                 from acs_description de6
                where de6.acs_payment_method_id = pfc.acs_payment_method_id
                  and de6.pc_lang_id = vpc_lang_id) acs_payment_method_descr_cust
            , (select de7.des_description_summary
                 from acs_description de7
                where de7.acs_payment_method_id = pfe.acs_payment_method_id
                  and de7.pc_lang_id = vpc_lang_id) acs_payment_method_descr_exp
         from acs_payment_method pae
            , acs_fin_acc_s_payment pfe
            , acs_payment_method pac
            , acs_fin_acc_s_payment pfc
            , pac_payment_condition co2
            , pac_payment_condition co1
            , pac_person per
            , acs_auxiliary_account aux
            , pac_custom_partner cus
            , acs_financial_account fin
            , act_financial_imputation imp
            , act_etat_journal ejo
            , act_journal jou
            , act_expiry exp
            , acj_catalogue_document cat
            , act_document doc
            , act_part_imputation par
            , acs_account acc
            , (select c_type_cumul
                    , acj_catalogue_document_id
                 from acj_sub_set_cat
                where c_sub_set = 'REC') sub
        where par.act_document_id = doc.act_document_id
          and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
          and cat.c_type_catalogue <> '8'
          and   -- Transaction de relance
              par.act_part_imputation_id = exp.act_part_imputation_id
          and exp_calc_net + 0 = 1
          and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.act_expiry_id, vdate) = 1
          and doc.act_journal_id = jou.act_journal_id
          and doc.act_journal_id = ejo.act_journal_id
          and ejo.c_sub_set = 'REC'
          and exp.act_part_imputation_id = imp.act_part_imputation_id
          and imp.act_det_payment_id is null
          and imp.acs_auxiliary_account_id is not null
          and imp.acs_financial_account_id = fin.acs_financial_account_id
          and (   exp.C_STATUS_EXPIRY = 0
               or (    exp.C_STATUS_EXPIRY <> 0
                   and exp.EXP_DATE_PMT_TOT > vdate) )
          and imp.imf_transaction_date <= vdate
          and fin.fin_collective = 1
          and acc.acc_number >= procparam_0
          and acc.acc_number <= procparam_1
          and (   acc.acs_sub_set_id = procparam_3
               or procparam_3 is null)
          and (   instr(',' || procparam_5 || ',', to_char(',' || fin.acs_financial_account_id || ',') ) > 0
               or procparam_5 = '#')
          and (   instr(',' || procparam_8 || ',', to_char(',' || pae.ACS_PAYMENT_METHOD_ID || ',') ) > 0
               or procparam_8 = '#')
          and par.pac_custom_partner_id = cus.pac_custom_partner_id
          and cus.acs_auxiliary_account_id = acc.acs_account_id
          and cus.acs_auxiliary_account_id = aux.acs_auxiliary_account_id
          and cus.pac_custom_partner_id = per.pac_person_id
          and cus.pac_payment_condition_id = co1.pac_payment_condition_id
          and par.pac_payment_condition_id = co2.pac_payment_condition_id(+)
          and cus.acs_fin_acc_s_payment_id = pfc.acs_fin_acc_s_payment_id(+)
          and pfc.acs_payment_method_id = pac.acs_payment_method_id(+)
          and exp.acs_fin_acc_s_payment_id = pfe.acs_fin_acc_s_payment_id(+)
          and pfe.acs_payment_method_id = pae.acs_payment_method_id(+)
          and doc.acj_catalogue_document_id = sub.acj_catalogue_document_id(+)
          and
              --Ctrl_only)expired
              (   parameter_1 = '0'
               or (    parameter_1 = '1'
                   and (case
                          when(procparam_7 = 1)
                          and (act_functions.discountamountafter(exp.act_document_id, exp.exp_slice, sysdate, 1) <> 0) then act_functions.discountdateafter
                                                                                                                                           (exp.act_document_id
                                                                                                                                          , exp.exp_slice
                                                                                                                                          , sysdate
                                                                                                                                           )
                          else exp.exp_adapted
                        end
                       ) <= to_date(parameter_2, 'YYYYMMDD')
                  )
              )
          and
              --Ctrl_c_type_cumul
              (    (    parameter_3 = '1'
                    and sub.c_type_cumul = 'INT')
               or (    parameter_4 = '1'
                   and sub.c_type_cumul = 'EXT')
               or (    parameter_5 = '1'
                   and sub.c_type_cumul = 'PRE')
               or (    parameter_6 = '1'
                   and sub.c_type_cumul = 'ENG')
              )
          and
              --Ctrl_c_etat_journal
              (   parameter_11 = '1'
               or (    parameter_11 = '0'
                   and ejo.c_etat_journal <> 'BRO') ) );

    commit;
  end if;

  open arefcursor for
    select par_document
         , acs_acs_financial_currency_id
         , currency_mb
         , acs_financial_currency_id
         , currency_me
         , doc_number
         , c_type_catalogue
         , c_type_cumul
         , act_expiry_id
         , act_document_id
         , act_part_imputation_id
         , c_status_expiry
         , exp_adapted
         , exp_calculated
         , days
         , exp_amount_lc
         , exp_amount_fc
         , discount_lc
         , discount_fc
         , det_paied_lc
         , det_paied_fc
         , solde_exp_lc
         , solde_exp_fc
         , solde_reeval_lc
         , exp_slice
         , acs_fin_acc_s_payment_id
         , last_claims_level
         , last_claims_date
         , pco_descr_exp
         , acs_period_id
         , imf_transaction_date
         , imf_value_date
         , imf_description
         , acs_financial_account_id
         , acc_number_fin
         , account_fin_descr
         , jou_number
         , c_etat_journal
         , imf_acs_division_account_id
         , acc_number_div
         , account_div_descr
         , pac_custom_partner_id
         , acs_auxiliary_account_id
         , c_partner_category
         , pco_descr_cus
         , acc_number_aux
         , account_aux_descr
         , account_aux_large_descr
         , acs_sub_set_id
         , sub_set_descr
         , c_type_account
         , per_name
         , per_forename
         , per_short_name
         , per_activity
         , per_key1
         , add_format
         , acs_payment_method_descr_cust
         , acs_payment_method_descr_exp
      from act_aged_balance_cust_temp;
end RPT_ACT_AGED_BALANCE_CUST;
