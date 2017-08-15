--------------------------------------------------------
--  DDL for Procedure RPT_ACT_JOB_BATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_JOB_BATCH" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0   in     varchar2
, parameter_1    in     number
, parameter_2    in     varchar2
, parameter_3    in     varchar2
, parameter_4    in     number
, parameter_5    in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
)
/**
*Description - used for report ACT_JOB_BATCH.rpt and ACT_JOB.rpt
* @author jliu 18th Nov 2008
* @lastupdate VHA 07 Mai 2014
* @public
* @PARAM parameter_0: act_job_id
* @PARAM parameter_1: acj_job_type_id
* @PARAM parameter_2: Job description from
* @PARAM parameter_3: Job description to
* @PARAM parameter_4: acs_financial_year_id
* @PARAM parameter_5: pc_user_id
*/
is
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select info
         , acj_catalogue_document_id
         , cat_description
         , fin_local_currency
         , act_document_id
         , doc_number
         , doc_total_amount_dc
         , doc_document_date
         , act_journal_id
         , act_act_journal_id
         , jou_number_fin
         , jou_number_mgm
         , act_job_id
         , job_description
         , acs_financial_year_id
         , a_datecre
         , a_datemod
         , a_idcre
         , a_idmod
         , currency
         , act_part_imputation_id
         , partner_name
         , part_amount
         , par_document
         , currency_imp
         , acs_financial_currency_id
         , acs_acs_financial_currency_id
         , doc_number_rem
         , exp_adapted
         , exp_amount_lc
         , exp_amount_fc
         , imf_primary
         , imf_transaction_date
         , rem_payable_amount_lc
         , rem_payable_amount_fc
         , rem_number
      from (select 'JOB_BATCH' info
                 , cat.acj_catalogue_document_id
                 , acj_functions.translatecatdescr(cat.acj_catalogue_document_id, vpc_lang_id) cat_description
                 , fur.fin_local_currency
                 , doc.act_document_id
                 , doc.doc_number
                 , case when row_number() over(partition by doc.act_document_id order by doc.act_document_id) = 1
                        then doc_total_amount_dc
                        else 0
                   end  doc_total_amount_dc
                 , doc.doc_document_date
                 , doc.act_journal_id
                 , doc.act_act_journal_id
                 , (select jou_number
                      from act_journal
                     where act_journal_id = doc.act_journal_id) jou_number_fin
                 , (select jou_number
                      from act_journal
                     where act_journal_id = doc.act_act_journal_id) jou_number_mgm
                 , job.act_job_id
                 , job.job_description
                 , job.acs_financial_year_id
                 , job.a_datecre
                 , job.a_datemod
                 , job.a_idcre
                 , job.a_idmod
                 , cur.currency
                 , imp.act_part_imputation_id
                 , (select nvl2(cus.per_name
                              , nvl2(cus.per_forename, cus.per_name || ' ' || cus.per_forename, cus.per_name)
                              , nvl2(sup.per_forename, sup.per_name || ' ' || sup.per_forename, sup.per_name)
                               )
                      from pac_person cus
                         , pac_person sup
                     where cus.pac_person_id(+) = imp.pac_custom_partner_id
                       and sup.pac_person_id(+) = imp.pac_custom_partner_id) partner_name
                 , (select sum(case
                                 when(fmp.acs_financial_currency_id <> fmp.acs_acs_financial_currency_id) then nvl2
                                                                                                                 (fmp.imf_amount_fc_d
                                                                                                                , nvl2(fmp.imf_amount_fc_c
                                                                                                                     , (fmp.imf_amount_fc_c
                                                                                                                        - fmp.imf_amount_fc_d
                                                                                                                       )
                                                                                                                     , -fmp.imf_amount_fc_d
                                                                                                                      )
                                                                                                                , null
                                                                                                                 )   --part_amount_me
                                 else nvl2(fmp.imf_amount_lc_d, nvl2(fmp.imf_amount_lc_c,(fmp.imf_amount_lc_c - fmp.imf_amount_lc_d), -fmp.imf_amount_lc_d)
                                         , null)   --part_amount_mb
                               end
                              )
                      from act_financial_imputation fmp
                     where fmp.act_part_imputation_id = imp.act_part_imputation_id
                       and fmp.acs_auxiliary_account_id is not null) part_amount
                 , imp.par_document
                 , (select max(case
                                 when(fmp.acs_financial_currency_id = fmp.acs_acs_financial_currency_id) then cmb.currency
                                 else cme.currency
                               end)
                      from act_financial_imputation fmp
                         , acs_financial_currency fmb
                         , acs_financial_currency fme
                         , pcs.pc_curr cmb
                         , pcs.pc_curr cme
                     where fmp.act_part_imputation_id = imp.act_part_imputation_id
                       and fmp.acs_acs_financial_currency_id = fmb.acs_financial_currency_id
                       and fmp.acs_financial_currency_id = fme.acs_financial_currency_id
                       and fmb.pc_curr_id = cmb.pc_curr_id
                       and fme.pc_curr_id = cme.pc_curr_id) currency_imp
                 , imp.acs_financial_currency_id
                 , imp.acs_acs_financial_currency_id
                 , null doc_number_rem
                 , null exp_adapted
                 , null exp_amount_lc
                 , null exp_amount_fc
                 , null imf_primary
                 , null imf_transaction_date
                 , null rem_payable_amount_lc
                 , null rem_payable_amount_fc
                 , null rem_number
              from acj_catalogue_document cat
                 , acj_job_type typ
                 , acs_financial_currency fur
                 , acs_financial_year yea
                 , act_document doc
                 , act_job job
                 , act_part_imputation imp
                 , pcs.pc_curr cur
             where job.act_job_id = doc.act_job_id(+)
               and doc.acs_financial_currency_id = fur.acs_financial_currency_id(+)
               and fur.pc_curr_id = cur.pc_curr_id(+)
               and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id(+)
               and job.acj_job_type_id = typ.acj_job_type_id
               and job.acs_financial_year_id = yea.acs_financial_year_id
               and imp.act_document_id(+) = doc.act_document_id
               and job.acs_financial_year_id = parameter_4
               and typ.acj_job_type_id = parameter_1
               and act_functions.isuserautorizedforjobtype(parameter_5, job.acj_job_type_id) = 1
               and (        (parameter_2 <> parameter_3)
                       and (    parameter_2 is not null
                            and parameter_3 is not null)
                       and (    job.job_description >= parameter_2
                            and job.job_description <= parameter_3)
                    or (     (parameter_2 <> parameter_3)
                        and (    parameter_2 is not null
                             and parameter_3 is null)
                        and (job.job_description >= parameter_2) )
                    or (     (parameter_2 <> parameter_3)
                        and (    parameter_2 is null
                             and parameter_3 is not null)
                        and (job.job_description <= parameter_3) )
                    or (    parameter_2 is null
                        and parameter_3 is null
                        and parameter_0 = 0)
                    or (    not(    parameter_2 is null
                                and parameter_3 is null
                                and parameter_0= 0)
                        and job.act_job_id = parameter_0)
                   ) )
    union all
    (select 'REMINDER' INFO
          , cat.acj_catalogue_document_id
          , acj_functions.translatecatdescr(cat.acj_catalogue_document_id, vpc_lang_id) cat_description
          , fur.fin_local_currency
          , doc.act_document_id
          , doc.doc_number
          , null doc_total_amount_dc
          , doc.doc_document_date
          , doc.act_journal_id
          , doc.act_act_journal_id
          , null jou_number_fin
          , null jou_number_mgm
          , job.act_job_id
          , job.job_description
          , job.acs_financial_year_id
          , job.a_datecre
          , job.a_datemod
          , job.a_idcre
          , job.a_idmod
          , cur.currency
          , null act_part_imputation_id
          , null partner_name
          , null part_amount
          , null par_document
          , null currency_imp
          , imp.acs_financial_currency_id
          , imp.acs_acs_financial_currency_id
          , atd.doc_number doc_number_rem
          , exp.exp_adapted
          , exp.exp_amount_lc
          , exp.exp_amount_fc
          , imp.imf_primary
          , imp.imf_transaction_date
          , rmd.rem_payable_amount_lc
          , rmd.rem_payable_amount_fc
          , rmd.rem_number
       from acj_catalogue_document cat
          , acj_job_type typ
          , acs_financial_currency fur
          , acs_financial_year yea
          , act_document doc
          , act_job job
          , pcs.pc_curr cur
          , act_reminder rmd
          , act_expiry exp
          , act_part_imputation par
          , act_document atd
          , pac_person cus
          , pac_person sup
          , act_financial_imputation imp
      where job.act_job_id = doc.act_job_id(+)
        and doc.acs_financial_currency_id = fur.acs_financial_currency_id(+)
        and fur.pc_curr_id = cur.pc_curr_id(+)
        and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id(+)
        and job.acj_job_type_id = typ.acj_job_type_id
        and job.acs_financial_year_id = yea.acs_financial_year_id
        and job.acs_financial_year_id = parameter_4
        and typ.acj_job_type_id = parameter_1
        and act_functions.isuserautorizedforjobtype(parameter_5, job.acj_job_type_id) = 1
        and (        (parameter_2 <> parameter_3)
                and (    parameter_2 is not null
                     and parameter_3 is not null)
                and (    job.job_description >= parameter_2
                     and job.job_description <= parameter_3)
             or (     (parameter_2 <> parameter_3)
                 and (    parameter_2 is not null
                      and parameter_3 is null)
                 and (job.job_description >= parameter_2) )
             or (     (parameter_2 <> parameter_3)
                 and (    parameter_2 is null
                      and parameter_3 is not null)
                 and (job.job_description <= parameter_3) )
             or (    parameter_2 is null
                 and parameter_3 is null
                 and parameter_0 = 0)
             or (    not(    parameter_2 is null
                         and parameter_3 is null
                         and parameter_0 = 0)
                 and job.act_job_id = parameter_0)
            )
        and rmd.act_expiry_id = exp.act_expiry_id
        and exp.act_part_imputation_id = par.act_part_imputation_id
        and par.act_document_id = atd.act_document_id
        and atd.act_document_id = imp.act_document_id
        and par.pac_custom_partner_id = cus.pac_person_id(+)
        and par.pac_supplier_partner_id = sup.pac_person_id(+)
        and imp.imf_primary = 1
        and rmd.act_document_id = doc.act_document_id);
end rpt_act_job_batch;
