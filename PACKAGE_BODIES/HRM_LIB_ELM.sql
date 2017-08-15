--------------------------------------------------------
--  DDL for Package Body HRM_LIB_ELM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_LIB_ELM" 
/**
 * Package de méthodes utilitaires pour déclaration Swissdec.
 *
 * @version 1.0
 * @date 07/2011
 * @author spfister
 *
 * Modifications:
 */
as
--
-- Private symbols
--
  cursor gcur_lang(id in number)
  is
    select LANID
      from PCS.PC_LANG
     where PC_LANG_ID = id;

--
-- Public methods
--
  function decode_civil_status(civil_status in hrm_person.c_civil_status%type)
    return varchar2
  is
  begin
    return case civil_status
      when 'Cel' then 'single'   -- Célibataire
      when 'Cnc' then 'unknown'   --Non marié ( Concubins)
      when 'Dec' then 'unknown'   -- Décédé(e)
      when 'Div' then 'divorced'   -- Divorcé(e)
      when 'Mar' then 'married'   -- Marié(e)
      when 'Pab' then 'partnershipDissolvedByDeclarationOfLost'   --Partenariat dissous ensuite déclaration d'absence
      when 'Pde' then 'partnershipDissolvedByDeath'   --Partenariat dissous par décès
      when 'Pdi' then 'partnershipDissolvedByLaw'   --Partenariat dissous judiciairement
      when 'Pen' then 'registeredPartnership'   --Partenariat enregistré
      when 'Sep' then 'separated'   -- Séparé(e)
      when 'Veu' then 'widowed'   -- Veuf(ve)
      else 'unknown'
    end;
  end;

  function decode_residence_categ(nationality in hrm_person.dic_nationality_id%type, permit in hrm_employee_wk_permit.dic_work_permit_id%type)
    return varchar2
  is
  begin
    return case nationality
      when 'CH' then null
      else case permit
      when 'L' then 'shortTerm-L'   -- Permis de courte durée
      when 'B' then 'annual-B'   -- Permis annuel
      when 'C' then 'settled-C'   -- Permis d'etablissement
      when 'G' then 'crossBorder-G'   -- Frontaliers
      when 'N' then 'asylumSeeker-N'
      when 'S' then 'needForProtection-S'
      else 'othersNotSwiss'   -- Autres (sans les Suisses)
    end
    end;
  end;

  function decode_ofs_education(education in hrm_person.c_ofs_training%type)
    return varchar2
  is
  begin
    return case education
      when '10' then 'doctorate'   -- Doctorat
      when '20' then 'universityMaster'   -- Université/EPF
      when '25' then 'universityBachelor'
      when '30' then 'higherEducationMaster'   -- Haute école spécialisée
      when '35' then 'higherEducationBachelor'
      when '40' then 'higherVocEducation'   -- Formation professionnelle supérieure
      when '50' then 'teacherCertificate'   -- Brevet d'enseignement
      when '60' then 'universityEntranceCertificate'   -- Maturité
      when '70' then 'vocEducationCompl'   -- Formation professionnelle achevée
      when '80' then 'enterpriseEducation'   -- Formations acquises exclusivement en entreprise
      when '90' then 'mandatorySchoolOnly'   -- Scolarité obligatoire, sans formation professionnelle complète
    end;
  end;

  function decode_ofs_skill(skill in hrm_person.c_ofs_job_qualif%type)
    return varchar2
  is
  begin
    return case skill
      when '1' then 'mostDemanding'   -- Poste impliquant des tâches particulièrement exigeantes et difficiles
      when '2' then 'qualified'   -- Travail indépendant et qualifié
      when '3' then 'specialized'   -- Connaissances professionnelles et spécialisées
      when '4' then 'simple'   -- Activités simples et répétitives
    end;
  end;

  function decode_ofs_position(position in hrm_person.c_ofs_responsability%type)
    return varchar2
  is
  begin
    return case position
      when '1' then 'highestCadre'   -- Cadre supérieur
      when '2' then 'middleCadre'   -- Cadre moyen
      when '3' then 'lowerCadre'   -- Cadre inférieur
      when '4' then 'lowestCadre'   -- Responsable de l’exécution des travaux
      when '5' then 'noCadre'   -- Sans fonction de cadre
    end;
  end;

  function decode_ofs_wageForm(wageForm in hrm_person.c_ofs_salary_type%type)
    return varchar2
  is
  begin
    return case wageForm
      when '1' then 'timeWages'   -- Salaire d’après le temps de travail
      when '2' then 'premiumWage'   -- Salaire-prime
      when '3' then 'wagesCommission'   -- Salaire avec part de commission
      when '4' then 'pieceWorkWage'   -- Salaire «à la pièce+
    end;
  end;

  function decode_ofs_payAgreement(payAgreement in pcs.pc_comp.c_ofs_salary_contract%type)
    return varchar2
  is
  begin
    return case payAgreement
      when '1' then 'CLA-Association'   -- Convention d’associations
      when '2' then 'collectiveContractOutside-CLA'   -- Convention d’entreprise ou de maison
      when '3' then 'CLA-BusinessOrGovernment'   -- Règlements de droit public
      when '4' then 'individualContract'   -- Contrat individuel
    end;
  end;

  function decode_ofs_contracttype(ContractType in hrm_person.c_ofs_contract_type%type)
    return varchar2
  is
  begin
    return case ContractType
      when '100' then 'indefiniteSalaryMth'   --CDI avec salaire mensuel
      when '110' then 'indefiniteSalaryMthAWT'   --CDI avec salaire mensuel et temps travail annuel
      when '120' then 'indefiniteSalaryHrs'   --CDI avec salaire horaire
      when '130' then 'indefiniteSalaryNoTimeConstraint'
      when '200' then 'fixedSalaryMth'   --CDD avec salaire mensuel
      when '210' then 'fixedSalaryHrs'   --CDD avec salaire horaire
      when '220' then 'fixedSalaryNoTimeConstraint'
      when '300' then 'apprentice'   --Contrat d'apprentissage
      when '310' then 'internshipContract'
      else ''
    end;
  end;

  function Format(N in number)
    return varchar2
  is
  begin
    return to_char(nvl(N, 0), HRM_LIB_ELM.gcNUMBER_FORMAT);
  end;

  function Format(D in date)
    return varchar2
  is
  begin
    return HRM_LIB_ELM.FormatDate(D);
  end;

  function FormatDate(D in date)
    return varchar2
  is
  begin
    return to_char(D, HRM_LIB_ELM.gcDATE_FORMAT);
  end;

  function FormatDateTime(D in date)
    return varchar2
  is
  begin
    return to_char(D, HRM_LIB_ELM.gcDATETIME_FORMAT);
  end;

  function to_link(id in number)
    return varchar2
  is
  begin
    return '#' || to_char(id);
  end;

  function ToDate(D in varchar2)
    return date
  is
  begin
    return to_date(D, HRM_LIB_ELM.gcDATE_FORMAT);
  end;

  function decode_lang(id in pcs.pc_lang.pc_lang_id%type)
    return varchar2
  is
    lv_lang varchar2(2);
  begin
    open gcur_lang(id);

    fetch gcur_lang
     into lv_lang;

    close gcur_lang;

    return case
      when lv_lang is null then 'en'
      else case lv_lang
      when 'GE' then 'de'
      when 'FR' then 'fr'
      when 'IT' then 'it'
      else 'en'
    end
    end;
  end;

  function decode_langid(id in pcs.pc_lang.pc_lang_id%type)
    return PCS.PC_LANG.PC_LANG_ID%type
  is
    ln_result PCS.PC_LANG.PC_LANG_ID%type;
  begin
    select PC_LANG_ID
      into ln_result
      from PCS.PC_LANG
     where LANID = upper(replace(decode_lang(id), 'de', 'GE') );

    return ln_result;
  end;

  function get_NewRequestId
    return varchar2
  is
  begin
    return to_char(systimestamp, HRM_LIB_ELM.gcREQUEST_FORMAT);
  end;

  function get_NewOrderNum
    return number
  is
  begin
    return hrm_transmission_order_seq.nextval();
  end;

  function is_all_recipient_completed(in_transmission_id in hrm_elm_transmission.hrm_elm_transmission_id%type)
    return integer
  is
    ln_has_not_completed integer;
  begin
    -- Recherche s'il existe des destinataires pas encore libérés
    select count(*)
      into ln_has_not_completed
      from dual
     where exists(
             select *
               from HRM_CONTROL_LIST L
                  , HRM_ELM_RECIPIENT R
              where R.HRM_ELM_TRANSMISSION_ID = in_transmission_id
                and R.ELM_SELECTED = 1
                and ELM_IS_COMPLETED = 0
                and L.HRM_CONTROL_LIST_ID = R.HRM_CONTROL_LIST_ID
                and L.C_CONTROL_LIST_TYPE in('102', '103', '111', '112', '113', '114', '116') );

    -- retourne 0 si au moins un des destinataires n'est pas libéré.
    return case ln_has_not_completed
      when 1 then 0
      else 1
    end;
  end;

  function can_use_recipient_type(
    in_transmission_id   in hrm_elm_transmission.hrm_elm_transmission_id%type
  , iv_control_list_type in hrm_control_list.c_control_list_type%type
  )
    return integer
  is
    ln_result integer;
  begin
    select count(*)
      into ln_result
      from dual
     where exists(
             select 1
               from HRM_CONTROL_LIST L
                  , HRM_ELM_RECIPIENT R
                  , HRM_ELM_TRANSMISSION T
              where T.HRM_ELM_TRANSMISSION_ID = in_transmission_id
                and DBMS_LOB.GetLength(ELM_CONTENT) > 0
                and R.HRM_ELM_TRANSMISSION_ID = T.HRM_ELM_TRANSMISSION_ID
                and R.ELM_SELECTED = 1
                and L.HRM_CONTROL_LIST_ID = R.HRM_CONTROL_LIST_ID
                and L.C_CONTROL_LIST_TYPE = iv_control_list_type);

    return ln_result;
  end can_use_recipient_type;

  /**
  * function HasExistingTAS
  * description :
  *    Indique s'il existe déjà une déclaration IS en suspend ou en traitement pour une periode donnée.
  */
  function HasExistingTAS(iEndPeriod in date)
    return integer
  is
    lnResult integer;
  begin
    select sign(count(*) )
      into lnResult
      from HRM_ELM_TRANSMISSION
     where ELM_VALID_AS_OF = iEndPeriod
       and C_HRM_ELM_STATUS in(0, 1);

    return lnResult;
  end HasExistingTAS;

  function decode_tax_entry(iv_entry hrm_employee_taxsource.c_hrm_tax_in%type)
    return varchar2
  is
  begin
    return case iv_entry
      when '01' then 'entryCompany'
      when '02' then 'cantonChange'
      when '03' then 'civilstate'
      when '04' then 'partnerWork'
      when '05' then 'sideline'
      when '06' then 'partnerWorkIT'
      when '07' then 'residence'
      when '08' then 'childrenDeduction'
      when '09' then 'churchTax'
      when '10' then 'activityRate'
      when '11' then 'others'
    end;
  end;

  function decode_tax_withdrawal(iv_leave hrm_employee_taxsource.c_hrm_tax_out%type)
    return varchar2
  is
  begin
    return case iv_leave
      when '01' then 'withdrawalCompany'
      when '02' then 'naturalization'
      when '03' then 'settled-C'
      when '04' then 'temporary'
      when '05' then 'cantonChange'
      when '06' then 'others'
    end;
  end;

  function recipient_comment(iv_comment in HRM_ELM_RECIPIENT.ELM_RECIPIENT_COMMENT%type)
    return xmltype
  is
    lx_result xmltype;
  begin
    if iv_comment is not null then
      select XMLElement("Comment"
                      , XMLElement("Notification"
                                 , XMLElement("QualityLevel", 'Comment')
                                 , XMLElement("DescriptionCode", '9999')
                                 , XMLElement("Description", iv_comment)
                                  )
                       )
        into lx_result
        from dual;
    end if;

    return lx_result;
  end recipient_comment;

  function tax_period_history(in_empid in hrm_person.hrM_person_id%type, iv_canton in hrm_employee_taxsource.emt_canton%type, in_recap pls_integer)
    return t_tax_period pipelined
  is
    lr_tax_period r_tax_period;
  begin
    for tpl in (select   c_hrm_tax_in
                       , elm_tax_per_end
                       , elm_tax_code emt_value
                       , elm_tax_code_open emt_value_special
                       , c_hrm_is_cat
                       , nvl(elm_tax_in_date, trunc(elm_tax_per_end, 'month') ) emt_from
                       , nvl(elm_tax_out_date, elm_tax_per_end) emt_to
                       , c_hrm_canton
                    from hrM_taxsource_ledger l
                   where hrm_person_id = in_empid
                     and trunc(elm_tax_per_end, 'year') = trunc(HRM_ELM.BEGINOFPERIOD, 'year')
                     and c_elm_tax_type in('01', '04', '03')
                     and (   c_elm_tax_type <> '03'
                          or sign(elm_tax_earning) = 1)
                     -- ne pas prendre les lignes virtuelles sans lien avec le canton ( annonces de mutation )
                     and not(    elm_tax_earning = 0
                             and elm_tax_source = 0
                             and nvl(c_hrm_tax_out, '00') = '05'
                             and elm_tax_out_date < elm_tax_per_end)
                     -- Les éléments extournés n'apparaissent pas dans l'historique sauf s'il n'existe plus
                     -- d'enregistrement pour le mois pour ce canton
                     and not exists(select 1
                                      from hrm_taxsource_ledger l2
                                     where l2.hrm_taxsource_ledger_ext_id = l.hrm_taxsource_ledger_id
                                       and c_elm_tax_type <> '02'
                                       and l2.c_hrm_canton = iv_canton)
                order by elm_tax_per_end asc
                       , c_hrm_canton asc) loop
      -- Pipe value only on change or rupture
      if lr_tax_period.emt_from is not null then
        if     in_recap = 0
           and (   lr_tax_period.emt_value <> tpl.emt_value
                or lr_tax_period.emt_value_special <> tpl.emt_value_special
                or lr_tax_period.c_hrm_is_cat <> tpl.c_hrm_is_cat
                or lr_tax_period.c_hrm_canton <> tpl.c_hrm_canton
               ) then
          if lr_tax_period.c_hrm_canton = iv_canton then
            pipe row(lr_tax_period);
          end if;

          lr_tax_period.emt_from  := null;
        else
          -- Recap : rupture qu'en cas de changement de canton ou d'embauche ( et de correction rétroactive )
          if (   tpl.c_hrm_tax_in in('01', '02')
              or lr_tax_period.c_hrm_canton <> tpl.c_hrm_canton) then
            if lr_tax_period.c_hrm_canton = iv_canton then
              pipe row(lr_tax_period);
            end if;

            lr_tax_period.emt_from  := null;
          end if;
        end if;
      end if;

      -- Mise à jour du record
      lr_tax_period.emt_from           := least(tpl.emt_from, nvl(lr_tax_period.emt_from, tpl.emt_from) );
      lr_tax_period.emt_to             := nvl(tpl.emt_to, hrm_elm.endofperiod);
      lr_tax_period.emt_value          := tpl.emt_value;
      lr_tax_period.emt_value_special  := tpl.emt_value_special;
      lr_tax_period.c_hrm_is_cat       := tpl.c_hrm_is_cat;
      lr_tax_period.c_hrm_canton       := tpl.c_hrm_canton;
    end loop;

    -- Pipe last record
    if     lr_tax_period.emt_from is not null
       and lr_tax_period.c_hrm_canton = iv_canton then
      pipe row(lr_tax_period);
    end if;
  end tax_period_history;
end HRM_LIB_ELM;
