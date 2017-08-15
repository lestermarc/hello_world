--------------------------------------------------------
--  DDL for Package Body HRM_ELM_TAXSOURCE_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_ELM_TAXSOURCE_XML" 
as
  /* Children declaration for the taxsource fragment */
  function p_children(in_empid in hrm_person.hrm_person_id%type)
    return xmltype
  is
    lx_result xmltype;
  begin
    select XMLAgg(XMLElement("Children"
                           , XMLElement("Lastname", ch.rel_name)
                           , XMLElement("Firstname", ch.rel_first_name)
                           , XMLElement("DateOfBirth", HRM_LIB_ELM.formatdate(ch.rel_birth_date) )
                           , XMLElement("Start", HRM_LIB_ELM.formatdate(ch.allo_begin) )
                           , case
                               when ch.allo_end is not null
                               and ch.allo_end > ch.allo_begin then XMLElement("End", HRM_LIB_ELM.formatdate(ch.allo_end) )
                             end
                            )
                 )
      into lx_result
      from (select   hrm_employee_id
                   , rel_name
                   , rel_first_name
                   , rel_birth_date
                   , max(allo_begin) allo_begin
                   , max(allo_end) allo_end
                from hrm_related_to children
                   , hrm_related_allocation alloc
               where children.hrm_employee_id = in_empid
                 and children.hrm_related_to_id = alloc.hrm_related_to_id
                 and nvl(rel_is_dependant, 0) = 1
                 and last_day(rel_birth_date) + 1 < hrm_prc_rep_list.endofperiod
            group by hrm_employee_id
                   , rel_name
                   , rel_first_name
                   , rel_birth_date) ch;

    return lx_result;
  exception
    when no_data_found then
      return null;
  end p_children;

  /* Fragment with spouse information */
  function p_MarriagePartner(in_empid in hrm_person.hrm_person_id%type)
    return xmltype
  is
    lx_result xmltype;
  begin
    select XMLConcat
             (case
                when REL_SOCIAL_SECURITYNO2 is not null then XMLElement("Social-InsuranceIdentification", XMLElement("SV-AS-Number", REL_SOCIAL_SECURITYNO2)
                                                                                                                                                              /*
                                                                                                                                                              Selon mail de M. Müller
                                                                                                                                                              ELSE
                                                                                                                                                                 XMLELEMENT ("unknown")
                                                                                                                                                             */
                                                            )
              end
            , XMLElement("Lastname", r.rel_name)
            , XMLElement("Firstname", r.rel_first_name)
            , XMLElement("DateOfBirth", HRM_LIB_ELM.FORMATDATE(r.rel_birth_date) )
            , case
                when REL_ZIPCODE is not null then XMLElement("SeparateAddress"
                                                           , XMLForest(rel_address as "Street")
                                                           , XMLElement("ZIP-Code", rel_zipcode)
                                                           , XMLElement("City", rel_city)
                                                           , XMLElement("Country", HRM_COUNTRY_FCT.GETCOUNTRYCODE( (select cntname
                                                                                                                      from pcs.pc_cntry
                                                                                                                     where pc_cntry_id = r.pc_cntry_id) ) )
                                                            )
              end
            , case
                when nvl(c_spouse_income, '04') <> '04'
                and (   rel_activity_end is null
                     or rel_activity_end >= hrm_prc_rep_list.Beginofperiod)
                and (   rel_activity_begin is null
                     or rel_activity_begin <= hrm_prc_rep_list.Endofperiod) then XMLElement
                                                                                  ("Payment"
                                                                                 , case
                                                                                     when c_spouse_income = '01'
                                                                                     and (   rel_activity_end is null
                                                                                          or rel_activity_end >= hrm_prc_rep_list.Beginofperiod
                                                                                         )
                                                                                     and rel_activity_begin <= hrm_prc_rep_list.Endofperiod then XMLElement
                                                                                                                                                  ("WorkOrCompensatory"
                                                                                                                                                 , case
                                                                                                                                                     when r.c_hrm_is_vd_activity is not null then XMLElement
                                                                                                                                                                                                   ("Employment"
                                                                                                                                                                                                  , decode
                                                                                                                                                                                                      (r.c_hrm_is_vd_activity
                                                                                                                                                                                                     , '01', 'mainJob'
                                                                                                                                                                                                     , 'sideJob'
                                                                                                                                                                                                      )
                                                                                                                                                                                                   )
                                                                                                                                                   end
                                                                                                                                                 , XMLElement
                                                                                                                                                     ("Workplace"
                                                                                                                                                    , r.dic_canton_work_id
                                                                                                                                                     )
                                                                                                                                                 , XMLElement
                                                                                                                                                     ("Start"
                                                                                                                                                    , HRM_LIB_ELM.formatdate
                                                                                                                                                        (rel_activity_begin
                                                                                                                                                        )
                                                                                                                                                     )
                                                                                                                                                 , case
                                                                                                                                                     when rel_activity_end is not null then XMLElement
                                                                                                                                                                                             ("End"
                                                                                                                                                                                            , HRM_LIB_ELM.formatdate
                                                                                                                                                                                                (rel_activity_end
                                                                                                                                                                                                )
                                                                                                                                                                                             )
                                                                                                                                                   end
                                                                                                                                                  )
                                                                                     when c_spouse_income = '02'
                                                                                     and (   rel_activity_end is null
                                                                                          or rel_activity_end >= hrm_prc_rep_list.Beginofperiod
                                                                                         )
                                                                                     and rel_activity_begin <= hrm_prc_rep_list.Endofperiod then XMLElement
                                                                                                                                                  ("WorkOrCompensatoryAndAnnuity"
                                                                                                                                                 , case
                                                                                                                                                     when r.c_hrm_is_vd_activity is not null then XMLElement
                                                                                                                                                                                                   ("Employment"
                                                                                                                                                                                                  , decode
                                                                                                                                                                                                      (r.c_hrm_is_vd_activity
                                                                                                                                                                                                     , '01', 'mainJob'
                                                                                                                                                                                                     , 'sideJob'
                                                                                                                                                                                                      )
                                                                                                                                                                                                   )
                                                                                                                                                   end
                                                                                                                                                 , XMLElement
                                                                                                                                                     ("Workplace"
                                                                                                                                                    , r.dic_canton_work_id
                                                                                                                                                     )
                                                                                                                                                 , XMLElement
                                                                                                                                                     ("Start"
                                                                                                                                                    , HRM_LIB_ELM.formatdate
                                                                                                                                                        (rel_activity_begin
                                                                                                                                                        )
                                                                                                                                                     )
                                                                                                                                                 , case
                                                                                                                                                     when rel_activity_end is not null then XMLElement
                                                                                                                                                                                             ("End"
                                                                                                                                                                                            , HRM_LIB_ELM.formatdate
                                                                                                                                                                                                (rel_activity_end
                                                                                                                                                                                                )
                                                                                                                                                                                             )
                                                                                                                                                   end
                                                                                                                                                  )
                                                                                     when c_spouse_income = '03' then XMLElement("Annuity")
                                                                                   end
                                                                                  )
              end
             )
      into lx_result
      from (select *
              from hrm_related_to
             where c_related_to_type in('1', '5')
               and hrm_employee_id = in_empid) r;

    if lx_result is not null then
      select XMLElement("MarriagePartner", lx_result)
        into lx_result
        from dual;
    end if;

    return lx_result;
  exception
    when no_data_found then
      return null;
  end p_MarriagePartner;

  /* Returns the religion when declared in the ledger */
  function p_confession(in_empid in hrm_person.hrm_person_id%type)
    return xmltype
  is
    lx_result xmltype;
  begin
    select case
             when max(c_hrm_tax_confession) is not null then XMLElement("Denomination"
                                                                      , case max(c_hrm_tax_confession)
                                                                          when '01' then 'reformedEvangelical'
                                                                          when '02' then 'romanCatholic'
                                                                          when '03' then 'christianCatholic'
                                                                          when '04' then 'jewishCommunity'
                                                                          else 'otherOrNone'
                                                                        end
                                                                       )
           end
      into lx_result
      from hrm_taxsource_ledger
     where hrm_person_id = in_empid
       and elm_tax_per_end <= hrm_date.activeperiodenddate
       and c_elm_tax_type in('01', '04')
       and c_hrm_tax_confession is not null;

    return lx_result;
  exception
    when no_data_found then
      return null;
  end p_confession;

  /* Returns additionnal data for tax person based on the current declaration period */
  function p_taxsource_additional(in_empid in hrm_person.hrm_person_id%type)
    return xmltype
  is
    lx_result     xmltype;
    lx_children   xmltype;
    lx_spouse     xmltype;
    lx_confession xmltype;
  begin
    lx_children    := p_children(in_empid);
    lx_spouse      := p_MarriagePartner(in_empid);
    lx_confession  := p_confession(in_empid);

    select XMLConcat(lx_confession
                   , case
                       when c_hrm_is_vd_activity is not null then XMLElement("Employment", decode(c_hrm_is_vd_activity, '01', 'mainJob', 'sideJob') )
                     end
                   , case
                       when c_hrm_is_other_activity is not null then XMLElement("OtherActivities"
                                                                              , case c_hrm_is_other_activity
                                                                                  when '01' then 'CH'
                                                                                  when '02' then 'abroad'
                                                                                  when '03' then 'abroadAndCH'
                                                                                end
                                                                               )
                     end
                   , case
                       when EMT_ANNUITANT = 1 then XMLElement("Annuity")
                     end
                   , case
                       when c_hrm_ge_cohabitation is not null then XMLElement("Concubinage"
                                                                            , case c_hrm_ge_cohabitation
                                                                                when '1' then 'yes'
                                                                                when '2' then 'unknown'
                                                                                when '0' then 'no'
                                                                              end
                                                                             )
                     end
                   ,
                     -- Spouse fragment only when necessary
                     case
                       when c_civil_status in('Mar', 'Pen', 'Sep') then lx_spouse
                     end
                   , lx_children
                    )
      into lx_result
      from (select   c_hrm_is_vd_activity
                   , c_hrm_is_other_activity
                   , c_hrm_ge_cohabitation
                   , c_civil_status
                   , emt_annuitant
                from hrm_employee_taxsource t
                   , hrm_person p
               where t.hrm_person_id = p.hrm_person_id
                 and p.hrm_person_id = in_empid
                 and trunc(hrm_prc_rep_list.beginofperiod, 'year') between trunc(emt_from, 'year')
                                                                       and nvl(hrm_taxsource.reference_period_end(in_empid, emt_from, emt_to, c_hrm_tax_out), hrm_elm.endofperiod)
                 and emt_from < hrm_prc_rep_list.endofperiod
            order by emt_from desc)
     where rownum = 1;

    if lx_result is not null then
      select XMLElement("AdditionalParticulars", lx_result)
        into lx_result
        from dual;
    end if;

    return lx_result;
  exception
    when no_data_found then
      return null;
  end p_taxsource_additional;

  function get_last_taxcode(in_empid in number, id_period in date, id_declared_until in date, iv_canton in varchar2)
    return xmltype
  is
    lx_result xmltype;
  begin
    for x in (select   elm_tax_code
                     , elm_tax_code_open
                     , c_hrm_is_cat
                  from hrm_taxsource_ledger l
                     , hrm_elm_recipient r
                     , hrm_elm_transmission t
                 where hrm_person_id = in_empid
                   and elm_tax_per_end <= id_period
                   and l.hrm_elm_recipient_conf_id = r.hrm_elm_recipient_id
                   and r.hrm_elm_transmission_id = t.hrm_elm_transmission_id
                   and elm_valid_as_of <= id_declared_until
                   and c_hrm_canton = iv_canton
              order by l.a_datecre desc
                     , hrm_taxsource_ledger_id desc) loop
      select XMLElement("TaxAtSourceCategory"
                      , case
                          when x.elm_tax_code_open is null
                          and x.c_hrm_is_cat is null then XMLElement("TaxAtSourceCode", substr(x.elm_tax_code, 3) )
                          when x.c_hrm_is_cat is not null then XMLElement("CategoryPredefined"
                                                                        , case x.c_hrm_is_cat
                                                                            when '01' then 'specialAgreement'
                                                                            when '02' then 'honoraryBoardOfDirectorsResidingAbroad'
                                                                            when '03' then 'monetaryValuesServicesResidingAbroad'
                                                                          end
                                                                         )
                          when x.elm_tax_code_open is not null then XMLElement("CategoryOpen", x.elm_tax_code_open)
                        end
                       )
        into lx_result
        from dual;

      exit;
    end loop;

    return lx_result;
  end;

  procedure prepare_taxsource(
    in_recipient_id in hrm_elm_recipient.hrm_elm_recipient_id%type
  , iv_canton       in hrm_taxsource_ledger.c_hrm_canton%type
  , in_listid       in hrm_control_list.hrm_control_list_id%type
  )
  is
  begin
    HRM_PRC_REP_LIST.SETPERIOD(HRM_ELM.BEGINOFPERIOD);

    -- Mise à jour de la journalisation pour considérer les éléments non envoyés, sur l'année courante exclusivement
    update hrm_taxsource_ledger
       set hrm_elm_recipient_conf_id = in_recipient_id
     where c_hrm_canton = iv_canton
       and hrm_elm_recipient_conf_id is null
       and elm_tax_per_end between trunc(hrm_elm.beginofperiod, 'year') and hrm_elm.endofperiod;

    -- Mise à jour pour indiquer les mutations, uniquement pour les valeurs inexistantes et pas encore déclarées.
    update hrm_taxsource_ledger l
       set (C_HRM_TAX_IN, C_HRM_TAX_IN2, c_hrm_tax_in3, c_hrm_tax_in4, C_HRM_TAX_OUT, ELM_TAX_IN_DATE, ELM_TAX_OUT_DATE, pc_ofs_city_id, ELM_TAX_SPECIAL_CODE) =
             (select nvl(l.C_HRM_TAX_IN, max(case
                                               when exist_indate = 0
                                               and emt_from > add_months(hrm_elm.endofperiod, -1) then c_hrm_tax_in
                                             end) )
                   , nvl(l.C_HRM_TAX_IN2, max(case
                                                when exist_indate = 0
                                                and emt_from > add_months(hrm_elm.endofperiod, -1) then c_hrm_tax_in2
                                              end) )
                   , nvl(l.C_HRM_TAX_IN3, max(case
                                                when exist_indate = 0
                                                and emt_from > add_months(hrm_elm.endofperiod, -1) then c_hrm_tax_in3
                                              end) )
                   , nvl(l.C_HRM_TAX_IN4, max(case
                                                when exist_indate = 0
                                                and emt_from > add_months(hrm_elm.endofperiod, -1) then c_hrm_tax_in4
                                              end) )
                   , nvl(l.C_HRM_TAX_OUT, min(case
                                                when exist_outdate = 0
                                                and emt_to between trunc(hrm_elm.beginofperiod,'year') and hrm_elm.endofperiod then c_hrm_tax_out
                                              end) )
                   , nvl(l.ELM_TAX_IN_DATE, min(case
                                                  when exist_indate = 0
                                                  and emt_from > add_months(hrm_elm.endofperiod, -1) then emt_from
                                                end) )
                   , nvl(l.ELM_TAX_OUT_DATE, max(case
                                                   when exist_outdate = 0
                                                   and emt_to between trunc(hrm_elm.beginofperiod,'year') and hrm_elm.endofperiod then emt_to
                                                 end) )
                   , nvl(l.PC_OFS_CITY_ID, max(pc_ofs_city_id) )
                   , nvl(l.ELM_TAX_SPECIAL_CODE, min(emt_special_code) )
                from (select t.*
                           , case
                               when exists(select 1
                                             from hrm_taxsource_ledger l
                                            where l.hrm_person_id = t.hrm_person_id
                                              and elm_tax_in_date = emt_from
                                              and elm_tax_per_end <= hrm_elm.endofperiod) then 1
                               else 0
                             end exist_indate
                           , case
                               when exists(select 1
                                             from hrm_taxsource_ledger l
                                            where l.hrm_person_id = t.hrm_person_id
                                              and elm_tax_out_date = emt_to
                                              and elm_tax_per_end <= hrm_elm.endofperiod) then 1
                               else 0
                             end exist_outdate
                        from hrm_employee_taxsource t) t
               where t.hrm_person_id = l.hrm_person_id
                 and hrm_elm.beginofperiod between trunc(emt_from, 'month') and nvl(hrm_taxsource.reference_period_end(hrm_person_id, emt_from, emt_to, c_hrm_tax_out)
                                                                                  , hrm_elm.endofperiod)
                 and (   last_day(emt_to) >= hrm_elm.endofperiod
                      or emt_from <= hrm_elm.endofperiod) )
     where c_hrm_canton = iv_canton
       and hrm_elm_recipient_conf_id = in_recipient_id
       and elm_tax_per_end = hrm_elm.endofperiod
       -- Filtre pour ne prendre que les valeurs finales
       and c_elm_tax_type in('01', '04')
       and not exists(select 1
                        from hrm_taxsource_ledger
                       where hrm_taxsource_ledger_ext_id = l.hrm_taxsource_ledger_id);

    -- Insertion des employés partis/mutés lors du mois précédent et n'ayant pas fait l'objet d'une déclaration
    -- Une ligne est donc nécessaire pour annoncer le départ, même qu'il n'y a plus d'impôt => ligne non insérée lors du calcul.
    insert into hrm_taxsource_ledger
                (HRM_TAXSOURCE_LEDGER_ID
               , HRM_PERSON_ID
               , HRM_ELM_RECIPIENT_CONF_ID
               , C_HRM_CANTON
               , C_HRM_IS_CAT
               , C_ELM_TAX_TYPE
               , C_HRM_TAX_IN
               , c_hrm_tax_in2
               , C_HRM_TAX_OUT
               , ELM_TAX_PER_END
               , ELM_TAX_CODE
               , ELM_TAX_CODE_OPEN
               , ELM_TAX_IN_DATE
               , ELM_TAX_OUT_DATE
               , A_DATECRE
               , A_IDCRE
               , pc_ofs_city_id
                )
      select init_id_seq.nextval
           , T.hrm_person_id
           , in_recipient_id
           , T.emt_canton
           , T.c_hrm_is_cat
           , '01'   -- ce n'est pas une correction
           , null c_hrm_tax_in
           , null c_hrm_tax_in2
           , T.C_HRM_TAX_OUT
           , hrm_elm.endofperiod
           , T.emt_value
           , T.emt_value_special
           , null
           , T.emt_to
           , sysdate
           , pcs.PC_I_LIB_SESSION.getuserini
           , pc_ofs_city_id
        from hrm_employee_taxsource t
       where t.emt_canton = iv_canton
         -- uniquement pour l'année courante / période précédente
         and emt_to between greatest(trunc(hrm_elm.beginofperiod, 'year'), add_months(hrm_elm.Beginofperiod, -1) ) and hrm_elm.beginofperiod
         and not exists(select 1
                          from hrM_taxsource_ledger
                         -- A voir si on veut simplement tester la présence d'une déclaration ultérieure au lieu de vérifier la date
                        where  hrm_person_id = t.hrm_person_id
                           and c_hrm_tax_out = t.c_hrm_tax_out
                           and c_hrm_canton = iv_canton
                           and t.emt_to = elm_tax_out_date)
         and not exists(select 1
                          from hrm_taxsource_ledger
                         where hrm_person_id = t.hrm_person_id
                           and c_hrm_canton = iv_canton
                           and elm_tax_per_end = hrm_elm.endofperiod)
         -- Les changements de cantons ne sont pas à considérer si une correction existe pour cela
         and not exists(
               select 1
                 from hrm_taxsource_ledger l2
                    , hrm_taxsource_ledger cor
                where l2.hrm_person_id = t.hrm_person_id
                  and l2.hrm_taxsource_ledger_id = cor.hrm_taxsource_ledger_ext_id
                  and cor.c_hrm_canton <> l2.c_hrm_canton
                  and l2.c_hrm_canton = iv_canton
                  and l2.elm_tax_per_end between add_months(hrm_elm.Beginofperiod, -1) and hrm_elm.beginofperiod);

    --Insertion dans la table temporaire pour une prise en compte dans get_Staff
    insert into hrm_tmp_rep_period
                (hrm_employee_id
               , ino_in
               , ino_out
               , hrm_control_list_id
               , hrm_establishment_id
                )
      (select   H.HRM_EMPLOYEE_ID
              , min(IO.INO_IN)
              , max(IO.INO_OUT)
              , in_listid
              , IO.HRM_ESTABLISHMENT_ID
           from HRM_HISTORY H
              , HRM_IN_OUT IO
          where H.HRM_EMPLOYEE_ID = IO.HRM_EMPLOYEE_ID
            and H.HIT_PAY_PERIOD between IO.INO_IN and hrm_date.nextInOutInDate(IO.INO_IN, IO.HRM_EMPLOYEE_ID)
            and exists(select 1
                         from hrm_taxsource_ledger l
                        where l.hrm_person_id = h.hrm_employee_id
                          and elm_tax_per_end between trunc(hit_pay_period, 'year') and hit_pay_period)
       group by h.hrm_employee_id
              , hrm_establishment_id);
  end prepare_taxsource;

  function get_tax_mutation(
    iv_code         in varchar2
  , iv_code2        in varchar2
  , iv_code3        in varchar2
  , iv_code4        in varchar2
  , id_validasof    in date
  , iv_codeout      in varchar2
  , id_validasofout in date
  )
    return xmltype
  is
    lx_result xmltype;
  begin
    select XMLConcat(
                     /* Declare the entry date only for the current period */
                     case
                       when iv_code in('01', '02', '11') then XMLElement("Entry"
                                                                       , XMLElement("ValidAsOf", HRM_LIB_ELM.FormatDate(id_validasof) )
                                                                       , XMLElement("Reason", HRM_LIB_ELM.decode_tax_entry(iv_code) )
                                                                        )
                     end
                   , case
                       when iv_code2 in('01', '02', '11') then XMLElement("Entry"
                                                                        , XMLElement("ValidAsOf", HRM_LIB_ELM.FormatDate(id_validasof) )
                                                                        , XMLElement("Reason", HRM_LIB_ELM.decode_tax_entry(iv_code2) )
                                                                         )
                     end
                   ,
                     /* Declare the mutation date only when no entry specified and for the current period only */
                     case
                       when iv_code between '03' and '10' then XMLElement("Mutation"
                                                                        , XMLElement("ValidAsOf", HRM_LIB_ELM.FormatDate(id_validasof) )
                                                                        , XMLElement("Reason", HRM_LIB_ELM.decode_tax_entry(iv_code) )
                                                                         )
                     end
                   , case
                       when iv_code2 between '03' and '10' then XMLElement("Mutation"
                                                                         , XMLElement("ValidAsOf", HRM_LIB_ELM.FormatDate(id_validasof) )
                                                                         , XMLElement("Reason", HRM_LIB_ELM.decode_tax_entry(iv_code2) )
                                                                          )
                     end
                   , case
                       when iv_code3 between '03' and '10' then XMLElement("Mutation"
                                                                         , XMLElement("ValidAsOf", HRM_LIB_ELM.FormatDate(id_validasof) )
                                                                         , XMLElement("Reason", HRM_LIB_ELM.decode_tax_entry(iv_code3) )
                                                                          )
                     end
                   , case
                       when iv_code4 between '03' and '10' then XMLElement("Mutation"
                                                                         , XMLElement("ValidAsOf", HRM_LIB_ELM.FormatDate(id_validasof) )
                                                                         , XMLElement("Reason", HRM_LIB_ELM.decode_tax_entry(iv_code4) )
                                                                          )
                     end
                   ,
                     /* Declare the leave date in every case. */
                     case
                       when iv_codeout is not null then XMLElement("Withdrawal"
                                                                 , XMLElement("ValidAsOf", HRM_LIB_ELM.FormatDate(id_validasofout) )
                                                                 , XMLElement("Reason", HRM_LIB_ELM.decode_tax_withdrawal(iv_codeout) )
                                                                  )
                     end
                    )
      into lx_result
      from dual;

    return lx_result;
  end get_tax_mutation;

  function clean_mutations (ix_mutation in xmltype) return xmltype
  /* Permet de nettoyer les éléments pour n'avoir qu'une seule occurence de chaque type */
  is
   lx_result xmltype;
  begin
    select xmltransform(ix_mutation,
    xmltype('<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
     <DeclarationCategory>
       <xsl:for-each select="/DeclarationCategory/Entry[1]">
        <Entry>
          <xsl:copy-of select="./ValidAsOf"/>
          <xsl:copy-of select="./Reason"/>
       </Entry>
       </xsl:for-each>
       <xsl:for-each select="/DeclarationCategory/Mutation[not(Reason=following::Reason)]">
        <xsl:sort select="./Reason" order="ascending"/>
        <Mutation>
          <xsl:copy-of select="./ValidAsOf"/>
          <xsl:copy-of select="./Reason"/>
       </Mutation>
      </xsl:for-each>
         <xsl:for-each select="/DeclarationCategory/Withdrawal[1]">
        <Withdrawal>
          <xsl:copy-of select="./ValidAsOf"/>
          <xsl:copy-of select="./Reason"/>
       </Withdrawal>
       </xsl:for-each>
     </DeclarationCategory>
    </xsl:template>
    </xsl:stylesheet>')) into lx_result from dual;
    return lx_result;
  end clean_mutations;

  /* Returns the current values for the taxsource declaration based on the canton and a list */
  function get_taxsource_current(in_empid in hrm_person.hrm_person_id%type, in_recipient_id in hrm_taxsource_ledger.hrm_elm_recipient_conf_id%type)
    return xmltype
  is
    lx_result          xmltype;
    lx_declaration_cat xmltype;
    ln_establishment   hrm_establishment.hrm_establishment_id%type;
    lx_residence_code  xmltype;
    lx_tax_amounts     xmltype;
    lv_canton          hrm_taxsource_ledger.c_hrm_canton%type;
    ln_visible         pls_integer;
  begin
     /* Current est VIDE lorsque :
    1. Aucune période d'assujettissement valable
    2. Aucune correction EMEA
    */
    select c_hrm_canton
      into lv_canton
      from hrm_taxsource_definition t
         , hrm_elm_recipient r
     where t.hrm_taxsource_definition_id = r.hrm_taxsource_definition_id
       and hrm_elm_recipient_id = in_recipient_id;

    select sign(count(*) )
      into ln_visible
      from (select 1
              from hrm_taxsource_ledger l
             where hrm_person_id = in_empid
               and c_hrm_canton = lv_canton
               and hrm_prc_rep_list.endofperiod = elm_tax_per_end
               and c_elm_tax_type in('01', '04')
               and hrm_elm_recipient_conf_id = in_recipient_id
               and not exists(select 1
                                from hrm_taxsource_ledger
                               where hrm_taxsource_ledger_ext_id = l.hrm_taxsource_ledger_id)
            union all
            select 1
              from hrM_employee_taxsource t
             where hrm_person_id = in_empid
               and emt_canton = lv_canton
               and hrm_prc_rep_list.beginofperiod between trunc(emt_from, 'month') and nvl(emt_to, hrm_elm.endofperiod) );

    if ln_visible = 1 then
      /* Find the establishment of the period */
      begin
        select hrm_establishment_id
          into ln_establishment
          from (select   hrm_establishment_id
                    from hrm_in_out
                   where hrm_employee_id = in_empid
                     and c_in_out_category = '3'
                     and hrm_prc_rep_list.beginofperiod between trunc(ino_in, 'month') and HRM_DATE.NEXTINOUTINDATE(ino_in, in_empid)
                order by HRM_DATE.NEXTINOUTINDATE(ino_in, in_empid) desc)
         where rownum = 1;
      exception
        when no_data_found then
          ra('Aucune entrée/sortie trouvée');
      end;

      /* EMEA : annonce de mutations ( entrée/sortie... ) */
      begin
        select XMLAgg(get_tax_mutation(code, code2, code3, code4, validasof, codeout, validasofout) )
          into lx_declaration_cat
          from (select distinct elm_tax_in_date validasof
                              , c_hrm_tax_in code
                              , c_hrm_tax_in2 code2
                              , c_hrm_tax_in3 code3
                              , c_hrm_tax_in4 code4
                              , case
                                  when c_hrm_tax_out < '50' then c_hrm_tax_out
                                end codeout
                              , case
                                  when c_hrm_tax_out < '50' then elm_tax_out_date
                                end validasofout
                           from hrm_taxsource_ledger l
                          where hrm_person_id = in_empid
                            and hrm_elm.endofperiod = elm_tax_per_end
                            and c_elm_tax_type in('01', '04')
                            and hrm_elm_recipient_conf_id = in_recipient_id
                            /* Prise en compte uniquement si l'événement est dans une période d'entrée/sortie
                              pour exclure les paiements de bonus p.ex. qui doivent être affectés à une période fictive */
                            and exists(
                                  select 1
                                    from hrm_in_out io
                                   where io.hrm_employee_id = HRM_PERSON_ID
                                     and c_in_out_category = '3'
                                     and nvl(elm_tax_out_date, elm_tax_in_date) >= trunc(ino_in, 'month')
                                     and (   nvl(elm_tax_out_date, elm_tax_in_date) <= ino_out
                                          or ino_out is null) )
                            and not exists(select 1
                                             from hrm_taxsource_ledger
                                            where hrm_taxsource_ledger_ext_id = l.hrm_taxsource_ledger_id) );

        if lx_declaration_cat is not null then
          select XMLElement("DeclarationCategory", lx_declaration_cat)
            into lx_declaration_cat
            from dual;
        end if;

        lx_declaration_cat := clean_mutations(lx_declaration_cat);

      exception
        when no_data_found then
          null;
      end;

      begin
        /* Residence place and tax code */
        select XMLConcat(XMLElement("Residence"
                                  , case
                                      when per_homecountry is null then XMLElement("CantonCH", per_homestate)
                                      else XMLConcat(XMLElement("AbroadCountry", HRM_COUNTRY_FCT.GETCOUNTRYCODE(per_homecountry) )
                                                   , XMLElement("KindOfResidence"
                                                              , case
                                                                  when exists(
                                                                        select 1
                                                                          from hrm_employee_taxsource
                                                                         where hrm_person_id = in_empid
                                                                           and hrm_elm.endofperiod between emt_from
                                                                                                       and hrm_taxsource.reference_period_end(in_empid, emt_from, emt_to, c_hrm_tax_out)
                                                                           and C_HRM_IS_RESIDENCE = '01') then XMLElement("Daily")
                                                                  else XMLElement("Weekly"
                                                                                , XMLForest(per_taxstreet as "Street")
                                                                                , XMLElement("ZIP-Code", per_taxPOSTALCODE)
                                                                                , XMLElement("City", per_taxcity)
                                                                                 )
                                                                end
                                                               )
                                                    )
                                    end
                                   )
                       , get_last_taxcode(in_empid, hrm_elm.endofperiod, hrm_elm.endofperiod, lv_canton)
                        )
          into lx_residence_code
          from v_hrm_elm_person
         where empid = in_empid;
      exception
        when no_data_found then
          ra('Problem with view v_hrm_elm_person');
      end;

      begin
        /* Fragment containing the current amounts */
        select XMLConcat(XMLElement("TaxableEarning", HRM_LIB_ELM.Format(taxable) )
                       , case
                           when certain_taxable <> 0 then XMLElement("AscertainedTaxableEarning", HRM_LIB_ELM.Format(certain_taxable) )
                         end
                       , XMLElement("TaxAtSource", HRM_LIB_ELM.Format(tax) )
                        )
          into lx_tax_amounts
          from (select sum(nvl(elm_tax_earning, 0) ) taxable
                     , sum(nvl(elm_tax_ascertain_earning, 0) ) certain_taxable
                     , sum(nvl(elm_tax_source, 0) ) tax
                     , max(c_hrm_canton) c_hrm_canton
                  from hrm_taxsource_ledger l
                 where hrm_elm_recipient_conf_id = in_recipient_id
                   and hrm_person_id = in_empid
                   and elm_tax_per_end = hrm_prc_rep_list.endofperiod
                   and c_elm_tax_type in('01', '04')
                   -- Corrections are not included in this fragment
                   and not exists(select 1
                                    from hrm_taxsource_ledger
                                   where hrm_taxsource_ledger_ext_id = l.hrm_taxsource_ledger_id) );
      exception
        when no_data_found then
          begin
            select XMLConcat(XMLElement("TaxableEarning", HRM_LIB_ELM.Format(0) ), XMLElement("TaxAtSource", HRM_LIB_ELM.Format(0) ) )
              into lx_tax_amounts
              from dual;
          end;
      end;

      select XMLElement("Current"
                      , xmlattributes(HRM_LIB_ELM.to_link(ln_establishment) as "workplaceIDRef")
                      , lx_declaration_cat
                      , lx_residence_code
                      , lx_tax_amounts
                       )
        into lx_result
        from dual;
    end if;

    return lx_result;
  end get_taxsource_current;

  /* Returns the reversal and the corrected amounts not transmitted yet for the canton */
  function get_taxsource_correction(in_empid in hrm_person.hrm_person_id%type, iv_canton in hrm_taxsource_ledger.c_hrm_canton%type)
    return xmltype
  is
    lx_result xmltype;
  begin
    /* Les corrections proviennent du journal hrm_taxsource_ledger
      Les corrections sont des éléments saisis pour des périodes antérieures n'ayant pas fait l'objet d'une déclaration.
      Dans ce cas, il faut extourner les valeurs déjà déclarées et annoncer les nouvelles.
      Pour les changements de cantons, il n'y a pas forcément de ligne supplémentaire pour le nouveau canton et dans ce cas, il faut l'ajouter dynamiquement
    */
    select XMLAgg
             (XMLElement
                ("Correction"
               , XMLElement("Month", to_char(elm_tax_per_end, 'YYYY-MM') )
               , XMLElement("Old"
                          , XMLConcat(nvl(get_last_taxcode(in_empid, elm_tax_per_end, hrm_elm.endofperiod - 1, old_canton)
                                        , get_last_taxcode(in_empid, elm_tax_per_end, hrm_elm.endofperiod, c_hrm_canton)
                                         )
                                    , XMLElement("TaxableEarning", HRM_LIB_ELM.Format(-nvl(old_taxable_earning, 0) ) )
                                    , case
                                        when nvl(old_ascertain_taxable_earning, 0) <> 0 then XMLElement
                                                                                                      ("AscertainedTaxableEarning"
                                                                                                     , HRM_LIB_ELM.Format(-nvl(old_ascertain_taxable_earning, 0) )
                                                                                                      )
                                      end
                                    , XMLElement("TaxAtSource", HRM_LIB_ELM.Format(-nvl(old_taxsource, 0) ) )
                                     )
                           )
               , XMLElement("New"
                          , clean_mutations(XMLElement("DeclarationCategory", mutations))
                          , XMLConcat(nvl(get_last_taxcode(in_empid, elm_tax_per_end, hrm_elm.endofperiod, c_hrm_canton)
                                        , get_last_taxcode(in_empid, elm_tax_per_end, hrm_elm.endofperiod - 1, old_canton)
                                         )
                                    , XMLElement("TaxableEarning", HRM_LIB_ELM.Format(nvl(new_taxable_earning, 0) ) )
                                    , case
                                        when nvl(new_ascertain_taxable_earning, 0) <> 0 then XMLElement
                                                                                                      ("AscertainedTaxableEarning"
                                                                                                     , HRM_LIB_ELM.Format(nvl(new_ascertain_taxable_earning, 0) )
                                                                                                      )
                                      end
                                    , XMLElement("TaxAtSource", HRM_LIB_ELM.Format(nvl(new_taxsource, 0) ) )
                                     )
                           )
                ) order by elm_tax_per_end
             )
      into lx_result
      from v_hrm_elm_taxsource_correction
     where hrm_person_id = in_empid
       and elm_tax_per_end < hrm_elm.beginofperiod
       and (   c_hrm_canton = iv_canton
            or old_canton = iv_canton);

    return lx_result;
  exception
    when no_data_found then
      return null;
  end get_taxsource_correction;

  /* Returns the corrections asked from ACI in a previous answer not confirmed yet */
  function get_taxsource_correction_conf(in_empid in hrm_person.hrm_person_id%type, in_recipient_id in hrm_taxsource_ledger.hrm_elm_recipient_conf_id%type)
    return xmltype
  is
    lx_result xmltype;
  begin
    select XMLAgg(   /* Concaténation des confirmations de corrections effectuées par le biais d'extournes dans le journal
                       se fait par mois */
                  XMLElement("CorrectionConfirmed"
                           , XMLElement("Month", to_char(elm_tax_per_end, 'YYYY-MM') )
                           , XMLElement("TaxableEarning", HRM_LIB_ELM.Format(taxable) )
                           , XMLElement("TaxAtSource", HRM_LIB_ELM.Format(tax) )
                            )
                 )
      into lx_result
      from (select   sum(elm_tax_earning) taxable
                   , sum(elm_tax_ascertain_earning) certain_taxable
                   , sum(elm_tax_source) tax
                   , elm_tax_per_end
                from hrm_taxsource_ledger l
               where hrm_elm_recipient_conf_id = in_recipient_id
                 and hrm_person_id = in_empid
                 and c_elm_tax_type = '03'
                 -- Pris en compte dans un décompte
                 and elm_tax_hit_pay_num is not null
            group by elm_tax_per_end);

    return lx_result;
  exception
    when no_data_found then
      return null;
  end get_taxsource_correction_conf;

  /* Returns the history of the different taxcodes for the canton during the year */
  function get_taxsource_history(in_empid in hrm_person.hrm_person_id%type, iv_canton in hrm_employee_taxsource.emt_canton%type)
    return xmltype
  is
    lx_result     xmltype;
    lx_correction xmltype;
    ln_visible    pls_integer;
  begin
    /* Affichage de l'historique si existence d'un élément dans l'année pour le canton */
    select sign(count(*) )
      into ln_visible
      from hrm_taxsource_ledger
     where c_hrm_canton = iv_canton
       and elm_tax_per_end between trunc(hrm_prc_rep_list.beginofperiod, 'year') and hrm_prc_rep_list.endofperiod
       and hrm_person_id = in_empid;

    if ln_visible = 1 then
      begin
        select XMLAgg(XMLElement("History"
                               , XMLElement("Period"
                                          , XMLElement("from", HRM_LIB_ELM.formatdate(greatest(emt_from, trunc(hrm_prc_rep_list.beginofperiod, 'year') ) ) )
                                          , XMLElement("until"
                                                     , HRM_LIB_ELM.formatdate(least(hrm_prc_rep_list.endofperiod, nvl(emt_to, hrm_prc_rep_list.endofperiod) ) )
                                                      )
                                           )
                               , XMLElement("TaxAtSourceCategory"
                                          , case
                                              when EMT_VALUE_SPECIAL is null
                                              and c_hrm_is_cat is null then XMLElement("TaxAtSourceCode", substr(emt_value, 3) )
                                              when c_hrm_is_cat is not null then XMLElement("CategoryPredefined"
                                                                                          , case c_hrm_is_cat
                                                                                              when '01' then 'specialAgreement'
                                                                                              when '02' then 'honoraryBoardOfDirectorsResidingAbroad'
                                                                                              when '03' then 'monetaryValuesServicesResidingAbroad'
                                                                                            end
                                                                                           )
                                              when EMT_VALUE_SPECIAL is not null then XMLElement("CategoryOpen", EMT_VALUE_SPECIAL)
                                            end
                                           )
                                ) order by emt_from
                     )
          into lx_result
          from
          (select emt_from,
          case when emt_to<trunc(hrm_prc_rep_list.beginofperiod, 'year') then  hrm_prc_rep_list.endofperiod else emt_to end emt_to,
          emt_value_special, c_hrm_is_cat, emt_value
          from
          table(HRM_LIB_ELM.TAX_PERIOD_HISTORY(in_empid, iv_canton, 0) ));
      exception
        when no_data_found then
          return null;
      end;
    end if;

    return lx_result;
  end get_taxsource_history;

  /* Returns the last establishment for a submission tax period */
  function get_last_estab_for_tax(in_empid in hrm_person.hrm_person_id%type, id_from in hrm_employee_taxsource.emt_from%type)
    return hrm_in_out.hrm_establishment_id%type
  is
    ln_last_establisment hrm_in_out.hrm_establishment_id%type;

    cursor c_last_estab
    is
      select   hrm_establishment_id
          from hrm_in_out io
         where hrm_employee_id = in_empid
           and id_from between io.ino_in and hrm_date.nextinoutindate(ino_in, in_empid)
      order by io.ino_in desc;
  begin
    open c_last_estab;

    fetch c_last_estab
     into ln_last_establisment;

    close c_last_estab;

    return ln_last_establisment;
  end get_last_estab_for_tax;

  /* Returns the last tax rate for a submission period */
  function get_last_tax_rate(
    in_empid  in hrm_person.hrm_person_id%type
  , id_date   in hrm_employee_taxsource.emt_from%type
  , iv_canton in hrm_employee_taxsource.emt_canton%type
  )
    return number
  is
    ln_result number(6, 4);

    cursor c_rate
    is
      select   elm_tax_source / elm_tax_earning tax_rate
          from hrm_taxsource_ledger
         where hrm_person_id = in_empid
           -- Que les enregistrements de l'année
           and elm_tax_per_end between trunc(id_date, 'year') and id_date
           and c_hrm_canton = iv_canton
           and c_elm_tax_type in('01', '04')
           and elm_tax_source > 0
      -- Tri : dernière période, prendre la correction en premier
      order by elm_tax_per_end desc
             , hrm_taxsource_ledger_ext_id desc nulls last;
  begin
    open c_rate;

    fetch c_rate
     into ln_result;

    close c_rate;

    return nvl(ln_result, 0) * 100;
  exception
    when no_data_found then
      return 0;
    when zero_divide then
      return 0;
  end get_last_tax_rate;

  /* Detailed cumulative amounts per tax period */
  function get_taxsource_recap_amounts(
    in_empid  in hrm_person.hrm_person_id%type
  , iv_canton in hrm_employee_taxsource.emt_canton%type
  , id_from   in date
  , id_to     in date
  , in_listid in hrm_control_list.hrm_control_list_id%type
  )
    return xmltype
  is
    lx_result xmltype;
  begin
    select XMLConcat(XMLElement("TaxableEarningCumulative", HRM_LIB_ELM.Format(TaxableEarningCumulative) )
                   , XMLElement("TaxAtSourceCumulative", HRM_LIB_ELM.Format(TaxAtSourceCumulative) )
                   , case
                       when ChurchTaxCumulative <> 0 then XMLElement("ChurchTaxCumulative", HRM_LIB_ELM.Format(ChurchTaxCumulative) )
                     end
                   , case
                       when TerminationPayCumulative <> 0 then XMLElement("TerminationPayCumulative", HRM_LIB_ELM.Format(TerminationPayCumulative) )
                     end
                   , case
                       when SporadicBenefitsCumulative <> 0 then XMLElement("SporadicBenefitsCumulative", HRM_LIB_ELM.Format(SporadicBenefitsCumulative) )
                     end
                   , case
                       when OwnershipRightsCumulative <> 0 then XMLElement("OwnershipRightCumulative", HRM_LIB_ELM.Format(OwnershipRightsCumulative) )
                     end
                   , case
                       when BoardOfDirectorsRemuneration <> 0 then XMLElement("BoardOfDirectorsRemunerationCumulative"
                                                                            , HRM_LIB_ELM.Format(BoardOfDirectorsRemuneration)
                                                                             )
                     end
                   , case
                       when FamilyIncomeCumulative <> 0 then XMLElement("FamilyIncomeCumulative", HRM_LIB_ELM.Format(FamilyIncomeCumulative) )
                     end
                   , case
                       when ChargesEffectiveCumulative <> 0 then XMLElement("ChargesEffectiveCumulative", HRM_LIB_ELM.Format(ChargesEffectiveCumulative) )
                     end
                   , case
                       when ChargesLumpSumCumulative <> 0 then XMLElement("ChargesLumpSumCumulative", HRM_LIB_ELM.Format(ChargesLumpSumCumulative) )
                     end
                   , case
                       when GrantAtSourceCode <> 0 then XMLElement("GrantTaxAtSourceCode")
                     end
                   , case
                       when WorkDaysCumulativeCH <> 0 then XMLElement("WorkDaysCumulativeCH", WorkDaysCumulativeCH)
                     end
                    )
      into lx_result
      from (select sum(elm_tax_earning) TaxableEarningCumulative
                 , sum(elm_tax_source) TaxAtSourceCumulative
                 , sum(elm_tax_church) ChurchTaxCumulative
                 , sum(elm_tax_termination) TerminationPayCumulative
                 , sum(elm_tax_sporadic) SporadicBenefitsCumulative
                 , sum(elm_tax_ownership_rights) OwnershipRightsCumulative
                 , sum(elm_tax_board) BoardOfDirectorsRemuneration
                 , sum(elm_tax_family_income) FamilyIncomeCumulative
                 , sum(elm_tax_charges_effective) ChargesEffectiveCumulative
                 , sum(elm_tax_charges_lump) ChargesLumpSumCumulative
                 , max(elm_tax_special_code) GrantAtSourceCode
                 , sum(elm_tax_days) WorkDaysCumulativeCH
              from hrm_taxsource_ledger
             where hrm_person_id = in_empid
               and c_hrm_canton = iv_canton
               and elm_tax_per_end between id_from and id_to);

    return lx_result;
  exception
    when no_data_found then
      return null;
  end get_taxsource_recap_amounts;

  /*
  Periods of submission in the year
  */
  function get_taxsource_recap(
    in_empid  in hrm_person.hrm_person_id%type
  , iv_canton in hrm_employee_taxsource.emt_canton%type
  , in_listid in hrm_control_list.hrm_control_list_id%type
  )
    return xmltype
  is
    lx_result xmltype;
  begin
    select XMLAgg(XMLElement("Recapitulation"
                           , XMLAttributes(HRM_LIB_ELM.to_link(get_last_estab_for_tax(in_empid, emt_from) ) as "lastWorkplaceIDRef")
                           , XMLElement("Period"
                                      , XMLElement("from", HRM_LIB_ELM.formatdate(greatest(emt_from, trunc(hrm_prc_rep_list.beginofperiod, 'year') ) ) )
                                      , XMLElement("until"
                                                 , HRM_LIB_ELM.formatdate(least(hrm_prc_rep_list.endofperiod, nvl(emt_to, hrm_prc_rep_list.endofperiod) ) )
                                                  )
                                       )
                           , XMLElement("LastTax"
                                      , HRM_LIB_ELM.format(get_last_tax_rate(in_empid
                                                                           , least(hrm_prc_rep_list.endofperiod, get_tax_period_end(in_empid, emt_to, emt_to) )
                                                                           , iv_canton
                                                                            )
                                                          )
                                       )
                           , get_taxsource_recap_amounts(in_empid, iv_canton, emt_from, least(last_day(emt_to), hrm_prc_rep_list.endofperiod), in_listid)
                            )
                 )
      into lx_result
      from (select emt_from
                 ,case when emt_to<trunc(hrm_prc_rep_list.beginofperiod, 'year') then  hrm_prc_rep_list.endofperiod else emt_to end emt_to
              from table(HRM_LIB_ELM.TAX_PERIOD_HISTORY(in_empid, iv_canton, 1) ) )
     -- Exclure hrm_employee_taxsource si vide
    where  emt_from is not null;

    return lx_result;
  end get_taxsource_recap;

  /* Returns the end period to consider retroactive payslips */
  function get_tax_period_end(in_employee_id in hrm_person.hrm_person_id%type, id_from in date, id_to in date)
    return date
  is
    ld_result date;
  begin
    /* Recherche du type de sortie lié à la période d'assujettissement pour déterminer le traitement des décomptes post-sortie */

    return hrm_date.EndEmpTaxDate(id_from, id_to, in_employee_id);
  end get_tax_period_end;

  /* Returns the last city coupled with the canton */
  function get_lastmunicipality(in_empid in hrm_person.hrm_person_id%type, iv_canton in varchar2)
    return varchar2
  is
    cursor c_last_municipality
    is
      select   ofs_city_no
          from hrm_taxsource_ledger t
             , pcs.pc_ofs_city c
         where t.hrm_person_id = in_empid
           and elm_tax_per_end <= hrm_prc_rep_list.endofperiod
           and t.pc_ofs_city_id = c.pc_ofs_city_id
           and c_hrm_canton = iv_canton
      order by elm_tax_per_end desc;

    lv_result varchar2(20);
  begin
    /* Chargement des dernières valeurs disponibles*/
    open c_last_municipality;

    fetch c_last_municipality
     into lv_result;

    close c_last_municipality;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end get_lastmunicipality;

  /* Returns the taxsource fragment */
  function get_taxsource_salaries(in_empid in hrm_person.hrm_person_id%type)
    return xmltype
  is
    lx_result      xmltype;
    lx_additionnal xmltype;
  begin
    lx_additionnal  := p_taxsource_additional(in_empid);

    select XMLAgg
             (XMLElement("TaxAtSourceSalary"
                       , XMLAttributes(HRM_LIB_ELM.to_link(d.hrm_taxsource_definition_id) as "institutionIDRef")
                       , lx_additionnal
                       , XMLElement("TaxAtSourceCanton", c_hrm_canton)
                       , XMLElement("TaxAtSourceMunicipalityID", get_lastmunicipality(in_empid, c_hrm_canton) )
                       , XMLElement("CurrentMonth", to_char(hrm_prc_rep_list.endofperiod, 'yyyy-mm') )
                       , get_taxsource_current(in_empid, r.hrm_elm_recipient_id)
                       , get_taxsource_correction(in_empid, d.c_hrm_canton)
                       , get_taxsource_correction_conf(in_empid, r.hrm_elm_recipient_id)
                       , get_taxsource_history(in_empid, d.c_hrm_canton)
                       , get_taxsource_recap(in_empid, c_hrm_canton, r.hrm_control_list_id)
                        ) order by c_hrm_canton
             )   --case c_hrm_canton when 'LU' then 1 when 'BE' then 2 else 3 end )
      into lx_result
      from   /* Employé ayant de l'impôt pour les cantons concernés par la déclaration selon table de journalisation */
           hrm_person p
         , hrm_taxsource_definition d
         , hrm_elm_recipient r
     where p.hrm_person_id = in_empid
       and exists(
             select 1
               from hrm_taxsource_ledger l
              where l.c_hrm_canton = d.c_hrm_canton
                and hrm_person_id = in_empid
                and elm_tax_per_end between trunc(hrm_prc_rep_list.beginofperiod, 'year') and hrm_prc_rep_list.endofperiod)
       and r.hrm_elm_transmission_id = hrm_elm.GET_TRANSMISSIONID
       and r.hrm_taxsource_definition_id = d.hrm_taxsource_definition_id
       and elm_selected = 1;

    if lx_result is not null then
      select XMLElement("TaxAtSourceSalaries", lx_result)
        into lx_result
        from dual;
    end if;

    return lx_result;
  exception
    when no_data_found then
      return null;
  end get_taxSource_Salaries;

  /* Returns total tax for current month for the canton */
  function get_taxsource_monthly_total(
    in_recipient_id in hrm_elm_recipient.hrM_elm_recipient_id%type
  , in_commission      HRM_TAXSOURCE_DEFINITION.tax_commission%type
  )
    return xmltype
  is
    lx_result xmltype;
  begin
    select XMLElement("TotalMonth"
                    , XMLElement("CurrentMonth", to_char(hrm_prc_rep_list.endofperiod, 'yyyy-mm') )
                    , XMLElement("TotalTaxableEarning", HRM_LIB_ELM.Format(taxable) )
                    , XMLElement("TotalTaxAtSource", HRM_LIB_ELM.Format(tax) )
                    , XMLElement("TotalCommission", HRM_LIB_ELM.Format(trunc(in_commission * tax / 100, 1) ) )
                     )
      into lx_result
      from (select sum(elm_tax_earning) taxable
                 , sum(elm_tax_source) tax
              from hrm_taxsource_ledger
             where hrm_elm_recipient_conf_id = in_recipient_id
               and elm_tax_per_end = hrm_prc_rep_list.endofperiod);

    return lx_result;
  exception
    when no_data_found then
      return null;
  end get_taxsource_monthly_total;

  /* Returns total tax corrections for the canton */
  function get_taxsource_corr_total(iv_canton in hrm_taxsource_ledger.c_hrm_canton%type, in_commission hrm_taxsource_definition.tax_commission%type)
    return xmltype
  is
    lx_result xmltype;
  begin
    select XMLAgg(XMLElement("CorrectionMonth"
                           , XMLElement("Month", to_char(elm_tax_per_end, 'yyyy-mm') )
                           , XMLElement("TotalTaxableEarning", HRM_LIB_ELM.Format(taxable) )
                           , XMLElement("TotalTaxAtSource", HRM_LIB_ELM.Format(tax) )
                           , XMLElement("TotalCommission", HRM_LIB_ELM.Format(trunc(in_commission * tax / 100, 1) ) )
                            )
                 )
      into lx_result
      from (select   sum(nvl(new_taxable_earning, 0) - nvl(old_taxable_earning, 0) ) taxable
                   , sum(nvl(new_taxsource, 0) - nvl(old_taxsource, 0) ) tax
                   , elm_tax_per_end
                from V_HRM_ELM_TAXSOURCE_CORR_TOTAL
               where c_hrm_canton = iv_canton
               and elm_tax_per_end < hrm_elm.beginofperiod
            group by elm_tax_per_end);

    return lx_result;
  exception
    when no_data_found then
      return null;
  end get_taxsource_corr_total;

  /* Returns total tax for the year for the canton


   */
  function get_taxsource_total_year(iv_canton in varchar2, in_commission HRM_TAXSOURCE_DEFINITION.tax_commission%type)
    return xmltype
  is
    lx_result xmltype;
  begin
    select XMLElement("TotalYear"
                    , XMLElement("Period"
                               , XMLElement("from", HRM_LIB_ELM.FormatDate(trunc(mini, 'month') ) )
                               , XMLElement("until", HRM_LIB_ELM.FormatDate(maxi) )
                                )
                    , XMLElement("TotalTaxableEarning", HRM_LIB_ELM.Format(taxable) )
                    , XMLElement("TotalTaxAtSource", HRM_LIB_ELM.Format(tax) )
                    , XMLElement("TotalCommission", HRM_LIB_ELM.Format(trunc(in_commission * tax / 100, 1) ) )
                     )
      into lx_result
      from (select sum(elm_tax_earning) taxable
                 , sum(elm_tax_source) tax
                 , nvl(min(least(elm_tax_per_end, nvl(elm_tax_in_date, elm_tax_per_end) ) ), HRM_PRC_REP_LIST.beginofperiod) mini
                 , nvl(max(least(elm_tax_per_end, nvl(case when elm_tax_out_date<trunc(elm_tax_per_end,'year') then elm_tax_per_end else elm_tax_out_date end, elm_tax_per_end) ) ), HRM_PRC_REP_LIST.Endofperiod) maxi
              from hrm_taxsource_ledger
             where c_hrm_canton = iv_canton
               and elm_tax_per_end between trunc(hrm_prc_rep_list.beginofperiod, 'year') and hrm_prc_rep_list.endofperiod);

    return lx_result;
  exception
    when no_data_found then
      return null;
  end get_taxsource_total_year;

  /* Returns the totals for Tax at source salaries */
  function get_taxsource_Totals
    return xmltype
  is
    lx_result xmltype;
  begin
    -- Ramener les différents cantons touchés du ledger et appeler les 3 méthodes précédentes
    select XMLAgg(XMLElement("TaxAtSourceTotals"
                           , xmlattributes(HRM_LIB_ELM.to_link(d.hrm_taxsource_definition_id) as "institutionIDRef")
                           , get_taxsource_monthly_total(hrm_elm_recipient_id, tax_commission)
                           , get_taxsource_corr_total(c_hrm_canton, tax_commission)
                           , get_taxsource_total_year(c_hrm_canton, tax_commission)
                            )
                 )
      into lx_result
      from hrm_elm_recipient r
         , hrm_taxsource_definition d
     where r.hrm_taxsource_definition_id = d.hrm_taxsource_definition_id
       and r.hrm_elm_transmission_id = hrm_elm.get_transmissionid
       and elm_selected = 1;

    return lx_result;
  exception
    when no_data_found then
      return null;
  end get_TaxSource_Totals;

  function get_taxsource_canton
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLConcat(XMLAgg(XMLElement("TaxAtSource"
                                     , XMLAttributes(HRM_LIB_ELM.to_link(v.hrm_taxsource_definition_id) as "institutionID")
                                     , XMLElement("CantonID", c_hrm_canton)
                                     , XMLElement("CustomerIdentity", tax_payer_no)
                                     , case
                                         when TAX_ENTITY is not null then XMLElement("PayrollUnit", TAX_ENTITY)
                                       end
                                     , HRM_LIB_ELM.recipient_comment(elm_recipient_comment)
                                      )
                           )
                    )
      into xmldata
      from hrm_taxsource_definition V
         , HRM_ELM_RECIPIENT R
         , HRM_ELM_TRANSMISSION T
     where v.hrm_taxsource_definition_id = r.hrm_taxsource_definition_id
       and R.ELM_SELECTED = 1
       and T.HRM_ELM_TRANSMISSION_ID = hrm_elm.get_TransmissionId
       and R.HRM_ELM_TRANSMISSION_ID = T.HRM_ELM_TRANSMISSION_ID;

    return xmldata;
  end get_taxsource_canton;
end HRM_ELM_TAXSOURCE_XML;
