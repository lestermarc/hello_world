--------------------------------------------------------
--  DDL for Package Body HRM_ELM_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_ELM_XML" 
/**
 * Génération de document Xml pour déclaration Swissdec.
 *
 * @version 1.0
 * @date 01/2005
 * @revision 4.0 / 05/2014
 * @author rhermann
 * @author spfister
 * @author ireber
 * @author skalayci
 *
 * Copyright 1997-2014 SolvAxis SA. Tous droits réservés.
 */
as
--
-- Package body private symbols
--
  gn_sal_counter_AVS         binary_integer := 0;
  gn_sal_counter_LAA         binary_integer := 0;
  gn_sal_counter_LAAC        binary_integer := 0;
  gn_sal_counter_IJM         binary_integer := 0;
  gn_sal_counter_LPP         binary_integer := 0;
  gn_sal_counter_ALFA        binary_integer := 0;
  gn_sal_counter_TAX_Salary  binary_integer := 0;
  gn_sal_counter_TAX_Annuity binary_integer := 0;
  gn_sal_counter_OFS         binary_integer := 0;
  gn_sal_counter_TAXSource   binary_integer := 0;
  gv_gen_date                varchar2(23);
  gv_xmlns_types             varchar2(255)  := 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes';
  gv_xmlns_container         varchar2(255)  := 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer';
  gv_xmlns_declaration       varchar2(255)  := 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration';

-- Préparer rupture pour toutes les listes
-- Table temporaire des différents groupes (codes/périodes)
  procedure prepareAllList
  is
    cursor lcur_lists(in_transmission_id in hrm_elm.T_TRANSMISSION_ID)
    is
      select r.hrm_control_list_id
           , c_control_list_type
           , t.c_elm_transmission_type
           , r.hrm_elm_recipient_id
           , (select c_hrm_canton
                from hrm_taxsource_definition d
               where d.hrm_taxsource_definition_id = r.hrm_taxsource_definition_id) c_hrm_canton
        from hrm_elm_transmission t
           , hrm_control_list c
           , hrm_elm_recipient r
       where t.hrm_elm_transmission_id = in_transmission_id
         and r.hrm_elm_transmission_id = t.hrm_elm_transmission_id
         and c.hrm_control_list_id = r.hrm_control_list_id
         and r.elm_selected = 1;
  begin
    hrm_prc_rep_list.deletelist;
    HRM_PRC_REP_LIST.SETYear(to_char(hrm_elm.get_period) );

    for tpl_lists in lcur_lists(hrm_elm.get_TransmissionId) loop
      /** LPP */
      if (   tpl_lists.C_ELM_TRANSMISSION_TYPE in('2', '3')
          or tpl_lists.c_control_list_type = '116') then
        insert into hrm_tmp_rep_period
                    (hrm_employee_id
                   , ino_in
                   , ino_out
                   , hrm_control_list_id
                   , hrm_establishment_id
                    )
          (select   HRM_EMPLOYEE_ID
                  , min(INO_IN)
                  , max(INO_OUT)
                  , tpl_lists.hrm_control_list_id
                  , HRM_ESTABLISHMENT_ID
               from HRM_IN_OUT
              where C_IN_OUT_CATEGORY = '3'
                and hrm_elm.BeginOfPeriod between trunc(INO_IN, 'Y') and nvl(INO_OUT, hrm_elm.BeginOfPeriod)
                and case
                      when tpl_lists.C_ELM_TRANSMISSION_TYPE = '2'
                      and exists(select 1
                                   from hrm_lpp_emp_calc c
                                  where c.hrm_elm_transmission_id = hrm_elm.get_TransmissionId
                                    and c.hrm_person_id = hrm_employee_id) then 1
                      when tpl_lists.C_ELM_TRANSMISSION_TYPE in('1', '3') then 1
                      else 0
                    end = 1
           group by HRM_EMPLOYEE_ID
                  , HRM_ESTABLISHMENT_ID);
      elsif tpl_lists.c_control_list_type not in('110', '011', '112', '113', '114', '111') then
        hrm_prc_rep_list.prepareList(tpl_lists.hrm_control_list_id, hrm_elm.get_period, 'CODE');
      else
        /*
         * CAF (lancer qu'une fois même si pls listes)
         * Toutes ces listes ont la même configuration, c'est le canton de l'assurance liée qui change
         */
        if tpl_lists.c_control_list_type = '112' then
          hrm_prc_rep_list.prepareList(tpl_lists.hrm_control_list_id, hrm_elm.get_period, 'CODE');
        /*
         * LAAC
         * Gestion de 2 codes CODE et CODE2
         */
        elsif tpl_lists.c_control_list_type in('113', '114') then
          hrm_prc_rep_list.prepareList(tpl_lists.hrm_control_list_id, to_char(hrm_elm.get_period), 'CODE', 1);
          hrm_prc_rep_list.prepareList(tpl_lists.hrm_control_list_id, to_char(hrm_elm.get_period), 'CODE2', 2);
        /*
         * TAX
         * Insérer 1 record dans hrm_tmp_rep_period également (select du staff se basant sur les PersonId de cette table...)
         */
        elsif tpl_lists.c_control_list_type = '110' then
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
                    , tpl_lists.hrm_control_list_id
                    , IO.HRM_ESTABLISHMENT_ID
                 from HRM_HISTORY H
                    , HRM_IN_OUT IO
                where H.HRM_EMPLOYEE_ID = IO.HRM_EMPLOYEE_ID
                  and H.HIT_PAY_PERIOD between IO.INO_IN and hrm_date.nextInOutInDate(IO.INO_IN, IO.HRM_EMPLOYEE_ID)
                  and trunc(H.HIT_PAY_PERIOD, 'y') = hrm_elm.BeginOfPeriod
                  and IO.C_IN_OUT_CATEGORY = '3'
             group by H.HRM_EMPLOYEE_ID
                    , HRM_ESTABLISHMENT_ID);
        /* Impôt source */
        elsif tpl_lists.c_control_list_type = '111' then
          hrm_elm_taxsource_xml.prepare_taxsource(tpl_lists.hrm_elm_recipient_id, tpl_lists.c_hrm_canton, tpl_lists.hrm_control_list_id);
        /* OFS */
        elsif tpl_lists.c_control_list_type = '011' then
          hrm_prc_rep_list.prepareList(tpl_lists.hrm_control_list_id, hrm_elm.get_period);
        end if;
      end if;
    end loop;
  end prepareAllList;

--
-- Private methods
--

--
-- Public methods
--
  procedure getSalaryDeclarationRequest(ox_document out nocopy xmltype)
  is
  begin
    -- Date de génération à réutiliser partout dans le document
    gv_gen_date  := HRM_LIB_ELM.FormatDateTime(sysdate);
    -- Extraction dans la table temporaire;
    -- Préparer les données (ruptures pour toutes les listes)
    prepareAllList();

    select XMLElement("DeclareSalary"
                    , XMLAttributes(gv_xmlns_types as "xmlns")
                    , xmlcomment('generated at ' ||
                                 gv_gen_date ||
                                 ' by user ' ||
                                 user ||
                                 ' from ' ||
                                 sys_context('USERENV', 'HOST') ||
                                 ' on database ' ||
                                 sys_context('USERENV', 'DB_UNIQUE_NAME') ||
                                 ' with module ' ||
                                 sys_context('USERENV', 'MODULE') ||
                                 ' (Action is "' ||
                                 nvl(sys_context('USERENV', 'ACTION'), 'not defined') ||
                                 '"' ||
                                 ' Client info is "' ||
                                 nvl(sys_context('USERENV', 'CLIENT_INFO'), 'not defined') ||
                                 '")'
                                )
                    , get_request_context
                    , XMLElement("Job"
                               , XMLAttributes(gv_xmlns_container as "xmlns")
                               , XMLElement("Addressees", get_Job_Addressees)
                               , XMLElement("EndUserNotification"
                                          , XMLElement("Name", hrm_elm.get_ContactName)
                                          , XMLElement("EmailAddress", hrm_elm.get_ContactEMail)
                                          , XMLElement("PhoneNumber", hrm_elm.get_ContactPhone)
                                           )
                                )
                    , case
                        when(hrm_elm.get_SubstitutionId != 0.0) then get_substitution
                      end
                    , get_salary_declaration
                     )
      into ox_document
      from dual;
  end getSalaryDeclarationRequest;

  procedure getResultFromDeclareSalary(ox_document out nocopy xmltype)
  is
    xmldata xmltype;
  begin
    -- Date de génération à réutiliser partout dans le document
    gv_gen_date  := HRM_LIB_ELM.FormatDateTime(sysdate);

    select XMLElement("GetResultFromDeclareSalary", XMLAttributes(gv_xmlns_types as "xmlns"), get_request_context, get_insurance_domain)
      into ox_document
      from dual;
  end getResultFromDeclareSalary;

  procedure getResultFromSyncContract(ox_document out nocopy xmltype)
  is
    xmldata xmltype;
  begin
    -- Date de génération à réutiliser partout dans le document
    gv_gen_date  := HRM_LIB_ELM.FormatDateTime(sysdate);

    select XMLElement("GetResultFromSynchronizeContract", XMLAttributes(gv_xmlns_types as "xmlns"), get_request_context, get_insurance_domain)
      into ox_document
      from dual;
  end getResultFromSyncContract;

  function get_request_context
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement("RequestContext"
                    , XMLAttributes(gv_xmlns_container as "xmlns")
                    , XMLElement("UserAgent"
                               , XMLElement("Producer", 'SolvAxis SA')
                               , XMLElement("Name", 'ProConcept ERP')
                               , XMLElement("Version", '11.1')
                               , XMLElement("Certificate", '1023.08')
                               , XMLElement("ELM-SalaryStandardVersion", '4.0')
                                )
                    , XMLElement("CompanyName", (select XMLElement("HR-RC-Name", XMLAttributes(gv_xmlns_declaration as "xmlns"), COM_SOCIALNAME)
                                                   from PCS.PC_COMP
                                                  where PC_COMP_ID = pcs.PC_I_LIB_SESSION.GetCompanyId) )
                    , XMLElement("TransmissionDate", HRM_LIB_ELM.FormatDateTime(sysdate) )
                    , XMLElement("RequestID", hrm_elm.get_RequestId)
                    , XMLElement("LanguageCode", HRM_LIB_ELM.decode_lang(hrm_elm.get_LangId) )
                    , case
                        when(hrm_elm.get_ModeTest = 1) then XMLConcat(XMLElement("TestCase"), XMLElement("MonitoringID", 'proconcept') )
                      end
                     )
      into xmldata
      from dual;

    return xmldata;
  end get_request_context;

  function get_substitution
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement("Substitution"
                    , XMLAttributes(gv_xmlns_container as "xmlns")
                    , XMLForest(extractvalue(xmltype(ELM_RECEIPT_XML)
                                           , '//DeclarationID'
                                           , 'xmlns=' || gv_xmlns_container || ' xmlns:ns2=' || gv_xmlns_declaration || ' xmlns:ns3=' || gv_xmlns_types
                                            ) as "PredecessorDeclarationIDWithAcceptedState"
                               )
                     )
      into xmldata
      from HRM_ELM_TRANSMISSION
     where HRM_ELM_TRANSMISSION_ID = hrm_elm.get_SubstitutionId;

    return xmldata;
  exception
    when no_data_found then
      ra('No transmission found');
  end get_substitution;

  function get_Job_Addressees
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(case insurance
                    when '01' then XMLElement("AHV-AVS", XMLAttributes(RefId as "institutionIDRef"), XmlProcessed)
                    when '01b' then XMLElement("AHV-AVS", XMLAttributes(RefId as "institutionIDRef"), XmlProcessed)
                    when '02' then XMLElement("UVG-LAA", XMLAttributes(RefId as "institutionIDRef"), XmlProcessed)
                    when '03' then XMLElement("UVG-LAA", XMLAttributes(RefId as "institutionIDRef"), XmlProcessed)
                    when '04' then XMLElement("UVGZ-LAAC", XMLAttributes(RefId as "institutionIDRef"), XmlProcessed)
                    when '05' then XMLElement("KTG-AMC", XMLAttributes(RefId as "institutionIDRef"), XmlProcessed)
                    when '07' then XMLElement("BVG-LPP", XMLAttributes(RefId as "institutionIDRef"), XmlProcessed)
                    when '06' then XMLElement("FAK-CAF", XMLAttributes(RefId as "institutionIDRef"), XmlProcessed)
                    else case c_control_list_type
                    when '110' then XMLElement("Tax", XmlProcessed)
                    when '011' then XMLElement("Statistic", XmlProcessed)
                    when '111' then XMLElement("TaxAtSource", XMLAttributes(RefId as "institutionIDRef"), XmlProcessed)
                  end
                  end
                 )
      into xmldata
      from (select   insurance
                   , c_control_list_type
                   , HRM_LIB_ELM.to_link(InstitutionID) RefId
                   , XMLElement("ProcessByDistributor", case
                                  when(v.ELM_PIV = 1) then 'true'
                                  else 'false'
                                end) xmlProcessed
                from (select   insurance
                             , c_control_list_type
                             , institutionid
                             , max(elm_piv) elm_piv
                          from v_hrm_elm_insurance v
                             , hrm_control_list l
                             , hrm_elm_recipient r
                         where v.listid = r.hrm_control_list_id
                           and v.listid = l.hrm_control_list_id
                           and r.hrm_elm_transmission_id = hrm_elm.get_TransmissionId
                           and r.elm_selected = 1
                      group by insurance
                             , c_control_list_type
                             , institutionid
                      union all
                      select '70' insurance
                           , c_control_list_type
                           , r.hrm_elm_recipient_id institutionid
                           , elm_piv
                        from hrm_elm_recipient r
                           , hrm_control_list l
                       where c_control_list_type = '110'
                         and r.hrm_control_list_id = l.hrm_control_list_id
                         and hrm_elm_transmission_id = hrm_elm.get_TransmissionId
                         and elm_selected = 1
                      union all
                      select '75' insurance
                           , c_control_list_type
                           , r.hrm_elm_recipient_id institutionid
                           , elm_piv
                        from hrm_elm_recipient r
                           , hrm_control_list l
                       where c_control_list_type = '011'
                         and r.hrm_control_list_id = l.hrm_control_list_id
                         and hrm_elm_transmission_id = hrm_elm.get_TransmissionId
                         and elm_selected = 1
                      union all
                      select '80' insurance
                           , '111' c_control_list_type
                           , hrm_taxsource_definition_id institutionid
                           , elm_piv
                        from hrm_elm_recipient
                       where hrm_taxsource_definition_id is not null
                         and hrm_elm_transmission_id = hrm_elm.get_TransmissionId
                         and elm_selected = 1) V
            order by
                     -- CAF en dernier
                     case
                       when(insurance = '06') then '08'
                       else insurance
                     end asc
                   , c_control_list_type desc) v;

    return xmldata;
  exception
    when no_data_found then
      ra('No addresses found');
  end get_Job_Addressees;

  function get_salary_declaration
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement("SalaryDeclaration"
                    , XMLAttributes('0.0' as "schemaVersion", gv_xmlns_container as "xmlns")
                    , XMLElement("Company"
                               , XMLAttributes(gv_xmlns_declaration as "xmlns")
                               , get_company_header
                               , get_staff
                               , get_insurances
                               , XMLElement("SalaryTotals", get_company_totals)
                               , get_salary_counters
                               , get_company_statistic
                                )
                    , XMLElement("GeneralSalaryDeclarationDescription"
                               , XMLAttributes(gv_xmlns_declaration as "xmlns")
                               , XMLElement("CreationDate", HRM_LIB_ELM.FormatDateTime(sysdate) )
                               , XMLElement("AccountingPeriod"
                                          , case
                                              when(c_elm_transmission_type = '3') then to_number(to_char(elm_valid_as_of, 'yyyy') )
                                              else hrm_elm.get_Period
                                            end
                                           )
                               , XMLElement("ContactPerson"
                                          , XMLElement("Name", hrm_elm.get_ContactName)
                                          , XMLForest(hrm_elm.get_ContactEMail as "EmailAddress")
                                          ,   -- empty authorized
                                            XMLElement("PhoneNumber", hrm_elm.get_ContactPhone)
                                           )
                               , HRM_LIB_ELM.recipient_comment(elm_comment)
                                )
                     )
      into xmldata
      from hrm_elm_transmission
     where hrm_elm_transmission_id = hrm_elm.get_TransmissionId;

    return xmldata;
  exception
    when no_data_found then
      ra('Transmission not found');
  end get_salary_declaration;

  function get_AccountingTime(id_in in date, id_out in date, PeriodType in integer := 0)
    return xmltype
  is
    xmldata xmltype;
    ld_from varchar2(10);
    ld_to   varchar2(10);
  begin
    if id_out < hrm_prc_rep_list.beginofperiod then
      ld_from  := HRM_LIB_ELM.FormatDate(greatest(id_in, trunc(id_out, 'year') ) );
      ld_to    := HRM_LIB_ELM.FormatDate(id_out);
    else
      ld_from  := HRM_LIB_ELM.FormatDate(coalesce(greatest(id_in, hrm_prc_rep_list.BeginOfPeriod), id_in, hrm_prc_rep_list.BeginOfPeriod) );
      ld_to    := HRM_LIB_ELM.FormatDate(coalesce(least(id_out, hrm_prc_rep_list.EndOfPeriod), id_out, hrm_prc_rep_list.EndOfPeriod) );
    end if;

    select case PeriodType
             when 0 then XMLElement("AccountingTime", XMLForest(ld_from as "from", ld_to as "until") )
             when 1 then XMLElement("FAK-CAF-Period", XMLForest(ld_from as "from", ld_to as "until") )
             else XMLElement("Period", XMLForest(ld_from as "from", ld_to as "until") )
           end
      into xmldata
      from dual;

    return xmldata;
  end get_AccountingTime;

  function get_company_header
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement("CompanyDescription"
                    , XMLElement("Name", XMLElement("HR-RC-Name", COM_SOCIALNAME) )
                    , XMLElement("Address", XMLElement("Street", COM_ADR), XMLElement("ZIP-Code", COM_ZIP), XMLElement("City", COM_CITY) )
                    , XMLForest(COM_OFRC as "UID-EHRA", COM_IDE as "UID-BFS")
                    , get_BurRee
                    , get_delegate
                     )
      into xmldata
      from PCS.PC_COMP
     where PC_COMP_ID = pcs.PC_I_LIB_SESSION.GetCompanyId;

    return xmldata;
  exception
    when no_data_found then
      ra('Company not found');
  end get_company_header;

  function get_BurRee
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("Workplace"
                           , XMLAttributes(HRM_LIB_ELM.to_link(HRM_ESTABLISHMENT_ID) as "workplaceID")
                           , case
                               when est_ree is not null then XMLElement("BUR-REE-Number", EST_REE)
                             end
                           , case
                               when est_no is not null then XMLElement("InHouseID", est_no)
                             end
                           , XMLElement("AddressExtended"
                                      , XMLElement("ComplementaryLine", EST_NAME)
                                      , XMLElement("Street", EST_ADDRESS)
                                      , XMLElement("ZIP-Code", EST_ZIP)
                                      , XMLElement("City", EST_CITY)
                                      , case
                                          when pc_cntry_id is not null then XMLElement("Country", (select cntid
                                                                                                     from pcs.pc_cntry
                                                                                                    where pc_cntry_id = e.pc_cntry_id) )
                                        end
                                      , case
                                          when c_hrm_canton is not null then XMLElement("Canton", c_hrm_canton)
                                        end
                                      , case
                                          when ofs_city_no is not null then XMLElement("MunicipalityID", ofs_city_no)
                                        end
                                       )
                           , XMLElement("CompanyWorkingTime"
                                      , case
                                          when(nvl(EST_HOURS_WEEK, 0) != 0.0)
                                          and (nvl(EST_LESSONS_WEEK, 0) != 0.0) then XMLElement("WeeklyHoursAndLessons"
                                                                                              , XMLElement("WeeklyHours", to_char(EST_HOURS_WEEK, '99D00') )
                                                                                              , XMLElement("WeeklyLessons", round(EST_LESSONS_WEEK) )
                                                                                               )
                                          when(nvl(EST_HOURS_WEEK, 0) != 0.0) then XMLElement("WeeklyHours", to_char(EST_HOURS_WEEK, '99D00') )
                                          when(nvl(EST_LESSONS_WEEK, 0) != 0.0) then XMLElement("WeeklyLessons", round(EST_LESSONS_WEEK) )
                                        end
                                       )
                            )
                 )
      into xmldata
      from hrm_establishment e
         , pcs.pc_ofs_city c
     where e.pc_ofs_city_id = c.pc_ofs_city_id(+);

    return xmldata;
  exception
    when no_data_found then
      ra('Establishments not found');
  end get_BurRee;

  function get_delegate
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement("Delegate"
                    , XMLElement("Name", XMLElement("HR-RC-Name", aud_name) )
                    , XMLElement("Address"
                               , case
                                   when aud_compl_data is not null then XMLElement("ComplementaryLine", aud_compl_data)
                                 end
                               , case
                                   when aud_street is not null then XMLElement("Street", aud_street)
                                 end
                               , XMLElement("ZIP-Code", aud_zip)
                               , XMLElement("City", aud_city)
                               , XMLElement("Country", cntid)
                                )
                     )
      into xmldata
      from pcs.pc_auditor a
         , pcs.pc_comp c
         , pcs.pc_cntry cn
     where a.pc_auditor_id = c.pc_auditor_id
       and a.pc_cntry_id = cn.pc_cntry_id
       and pcs.PC_I_LIB_SESSION.getcompanyid = pc_comp_id;

    return xmldata;
  exception
    when no_data_found then
      return null;
  end get_delegate;

/* Returns the OfS City not linked to the last valid tax period */
  function get_tax_municipalityid(in_empid in hrm_person.hrm_person_id%type)
    return pcs.pc_ofs_city.ofs_city_no%type
  is
    lv_result pcs.pc_ofs_city.ofs_city_no%type;
    ld_leave  date;

    cursor city(empid in hrm_person.hrm_person_id%type)
    is
      select   ofs_city_no
          from hrm_taxsource_ledger t
             , pcs.pc_ofs_city c
         where t.hrm_person_id = empid
           and t.pc_ofs_city_id = c.pc_ofs_city_id
      order by elm_tax_per_end desc
             , c_hrm_tax_out nulls first;
  begin
    open city(in_empid);

    fetch city
     into lv_result;

    close city;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end get_tax_municipalityid;

  function get_permit(in_empid in hrm_person.hrM_person_id%type, id_end in date)
    return dic_work_permit.dic_work_permit_id%type
  is
    lv_result dic_work_permit.dic_work_permit_id%type;
  begin
    select max(DIC_WORK_PERMIT_ID) PERMIT
      into lv_result
      from HRM_EMPLOYEE_WK_PERMIT W
     where hrm_person_id = in_empid
       and WOP_VALID_FROM = (select max(WOP_VALID_FROM) WOP_VALID_FROM
                               from HRM_EMPLOYEE_WK_PERMIT
                              where HRM_PERSON_ID = in_empid
                                and hrm_prc_rep_list.BeginOfPeriod between trunc(WOP_VALID_FROM, 'Y') and nvl(WOP_VALID_TO, id_end) );

    return lv_result;
  exception
    when no_data_found then
      return null;
  end get_permit;

  function get_ownershiprightdetails(in_empid in hrm_person.hrM_person_id%type)
    return xmltype
  is
    xmldata  xmltype;
    ln_count pls_integer;
  begin
    select XMLAgg(XMLElement("OwnershipRightDetail"
                           , XMLElement("TypeOfOwnership"
                                      , case
                                          when c_tsh_type <> '06' then XMLElement("CategoryPredefined"
                                                                                , case c_tsh_type
                                                                                    when '01' then 'staffShares'
                                                                                    when '02' then 'publiclyTradedOptions'
                                                                                    when '03' then 'otherOptions'
                                                                                    when '04' then 'deferredBenefitsStaffShares'
                                                                                    when '05' then 'fictitiousStaffShare'
                                                                                  end
                                                                                 )
                                          else XMLElement("CategoryOpen", TSH_TYPE_DETAIL)
                                        end
                                       )
                           , XMLForest(tsh_share_name as "ShareName", tsh_share_plan_desc as "SharePlanDescription")
                           , case
                               when tsh_ruling_allowed is not null then XMLElement("Ruling"
                                                                                 , XMLElement("Allowed", HRM_LIB_ELM.FormatDate(tsh_ruling_allowed) )
                                                                                 , XMLElement("Canton", c_hrm_canton)
                                                                                  )
                             end
                           , XMLForest(HRM_LIB_ELM.formatdate(tsh_move_to_ch) as "MoveToCH"
                                     , HRM_LIB_ELM.formatdate(tsh_move_from_ch) as "MoveFromCH"
                                     , HRM_LIB_ELM.formatdate(tsh_entry_concern) as "EntryConcern"
                                     , HRM_LIB_ELM.formatdate(tsh_withdrawal_concern) as "WithdrawalConcern"
                                     , HRM_LIB_ELM.formatdate(tsh_entry_subcompany) as "EntrySubcompany"
                                     , HRM_LIB_ELM.formatdate(tsh_withdrawal_subcompany) as "WithdrawalSubcompany"
                                     , (select cntid
                                          from pcs.pc_cntry
                                         where pc_cntry_id = tsh_country_dest_workplace_id) as "CountryOfDestinationWorkplace"
                                     , (select cntid
                                          from pcs.pc_cntry
                                         where pc_cntry_id = tsh_country_dest_residence_id) as "CountryOfDestinationResidence"
                                     , HRM_LIB_ELM.formatdate(tsh_appropriation_buy_emission) as "AppropriationBuyEmission"
                                     , HRM_LIB_ELM.formatdate(tsh_expiry) as "Expiry"
                                     , tsh_duration as "Duration"
                                     , HRM_LIB_ELM.formatdate(tsh_expiry_vesting_period) as "ExpiryVestingPeriod"
                                     , tsh_reduction_income_prc as "ReductionIncomePercentage"
                                     , tsh_reduction_asset_prc as "ReductionAssetPercentage"
                                     , HRM_LIB_ELM.formatdate(tsh_expiry_before_release_vest) as "ExpiryBeforeReleaseVestingPeriod"
                                     , tsh_duration_vesting_period as "DurationVestingPeriod"
                                     , tsh_duration_obligation_return as "DurationObligationToReturn"
                                     , HRM_LIB_ELM.formatdate(tsh_return) as "Return"
                                     , HRM_LIB_ELM.formatdate(tsh_realization) as "Realization"
                                     , HRM_LIB_ELM.formatdate(tsh_start_vesting_period) as "StartVestingPeriod"
                                     , HRM_LIB_ELM.formatdate(tsh_end_vesting_period) as "EndVestingPeriod"
                                     , tsh_remark_vesting_period as "RemarkVestingPeriod"
                                     , tsh_number_calc_income as "NumberToCalculateIncome"
                                     , tsh_number_ownerships as "NumberOfOwnerships"
                                     , (select currency
                                          from pcs.pc_curr
                                         where pc_curr_id = s.pc_curr_id) as "Currency"
                                     , tsh_currency_rate as "CurrencyRate"
                                     , HRM_LIB_ELM.format(tsh_market_value) as "MarketValue"
                                     , HRM_LIB_ELM.format(tsh_market_value_formula) as "MarketValueFormula"
                                     , tsh_formula as "Formula"
                                     , HRM_LIB_ELM.format(tsh_reduced_market_value) as "ReducedMarketValue"
                                     , HRM_LIB_ELM.format(tsh_price) as "Price"
                                     , HRM_LIB_ELM.format(tsh_monetary_val_serv_pershare) as "MonetaryValuesServicesPerShare"
                                     , HRM_LIB_ELM.format(tsh_monetary_val_serv_tot) as "MonetaryValuesServicesTotal"
                                     , HRM_LIB_ELM.format(tsh_reduction_costs) as "ReductionCosts"
                                     , (select cntid
                                          from pcs.pc_cntry c
                                         where exists(
                                                 select 1
                                                   from hrm_establishment e
                                                      , hrm_in_out io
                                                  where e.hrm_establishment_id = io.hrm_establishment_id
                                                    and c_in_out_status = 'ACT'
                                                    and io.hrm_employee_id = in_empid
                                                    and c.pc_cntry_id = e.pc_cntry_id) ) as "Workplace"
                                     , tsh_workdays_ch_emission_vest as "WorkingDaysInCH-Emission-Vesting"
                                     , tsh_days_emission_vesting as "DaysEmission-Vesting"
                                     , tsh_part_ch_percentage as "PartInCH-Percentage"
                                     , HRM_LIB_ELM.format(tsh_part_income_abroad) as "PartIncomeAbroad"
                                     , HRM_LIB_ELM.format(tsh_part_income_ch) as "PartIncomeCH"
                                     , case c_workplace_time_realisation
                                         when '01' then 'CH'
                                         when '02' then 'abroad'
                                         when '03' then 'noWorksForCompany'
                                       end as "WorkplaceTimeOfRealisation"
                                     , case c_residence_time_realisation
                                         when '01' then 'CH'
                                         when '02' then 'abroad'
                                       end as "ResidenceTimeOfRealisation"
                                     , HRM_LIB_ELM.format(tsh_diverse_deduction) as "DiverseDeduction"
                                     , case c_tsh_operation_type
                                         when '01' then 'emission'
                                         when '02' then 'purchase'
                                         when '03' then 'issue'
                                         when '04' then 'vesting'
                                         when '05' then 'realization'
                                         when '06' then 'release'
                                         when '07' then 'returnEtc'
                                       end as "Operation"
                                     , HRM_LIB_ELM.formatdate(tsh_confirmation) as "Confirmation"
                                     , tsh_company as "Company"
                                     , tsh_company as "ConfirmationCompany"
                                     , tsh_confirm_concern as "ConfirmationConcern"
                                     , tsh_compact as "Contact"
                                     , tsh_phone as "Phone"
                                     , tsh_email as "Email"
                                      )
                           , HRM_LIB_ELM.recipient_comment(tsh_comment)
                            )
                 )
      into xmldata
      from hrm_person_tax t
         , hrm_person_tax_share s
     where t.hrm_person_tax_id = s.hrm_person_tax_id
       and t.hrm_person_id = in_empid;

    if xmldata is not null then
      select XMLElement("OwnershipRightDetails", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  exception
    when no_data_found then
      return null;
  end get_ownershiprightdetails;

  function get_work_attributes_until(in_transmissionid in hrm_elm_transmission.hrm_elm_transmission_id%type)
    return date deterministic
  is
    ld_result date;
  begin
    select case
             when c_elm_transmission_type in('2', '3') then elm_valid_as_of
             else hrm_prc_rep_list.endofperiod
           end
      into ld_result
      from hrm_elm_transmission
     where hrm_elm_transmission_id = in_transmissionid;

    return ld_result;
  end get_work_attributes_until;

  function get_work_attributes(in_empid in hrm_person.hrM_person_id%type)
    return xmltype
  is
    xmldata         xmltype;
    ld_entry        date;
    ld_leave        date;
    ln_lessons      hrm_contract.con_weekly_lessons%type;
    ln_hours        hrm_contract.con_weekly_hours%type;
    ln_activityrate hrm_contract.con_activity_rate%type;
    ln_leave        hrm_contract.con_leave_days%type;
    ld_until        date;

-- Recherche des vacances selon décompte (si pas mentionné dans le contrat)
    cursor tpl_leave
    is
      select   his_pay_sum_val
          from hrm_history_detail
         where exists(
                 select 1
                   from hrm_control_list l
                      , hrm_control_elements e
                  where l.hrm_control_list_id = e.hrm_control_list_id
                    and c_control_list_type = '011'
                    and coe_box = 'HOL'
                    and hrm_control_elements_id = hrm_elements_id)
           and hrm_employee_id = in_empid
      order by his_pay_period desc;
  begin
    ld_until  := get_work_attributes_until(hrm_elm.get_transmissionid);
    ld_leave  := hrm_prc_rep_list.get_leave(in_empid, 0);

    --ld_entry  := hrm_prc_rep_list.get_entry(in_empid, 0);

    -- Insertion de la dernière entrée de l'année
    -- Filtre pour prendre la première entrée en cas de records consécutifs
    select max(ino_in)
      into ld_entry
      from hrm_in_out io
     where hrm_employee_id = in_empid
       and trunc(ino_in, 'month') <= ld_until
       and not exists(select 1
                        from hrm_in_out
                       where hrm_employee_id = in_empid
                         and IO.ino_in = ino_out + 1);

    -- Recherche des valeurs au niveau des contrats actifs le dernier jour de la déclaration, respectivement le jour de sortie
    select sum(con_weekly_lessons)
         , sum(con_weekly_hours)
         , trunc(sum(nvl(con_activity_rate, 0) ) )
         , sum(nvl(con_leave_days, 0) )
      into ln_lessons
         , ln_hours
         , ln_activityrate
         , ln_leave
      from hrm_contract
     where hrm_employee_id = in_empid
       and least(nvl(ld_leave, ld_until), ld_until) between trunc(con_begin, 'month') and nvl(con_end, ld_until);

    /* Recherche selon historique calculé et position HOL de la liste OFS si rien n'est indiqué au niveau du contrat */
    if    ln_leave is null
       or ln_leave = 0 then
      open tpl_leave;

      fetch tpl_leave
       into ln_leave;

      close tpl_leave;
    end if;

    select XMLElement("Work"
                    , case
                        when(nvl(ln_HOURS, 0) != 0) then XMLElement("WorkingTime", XMLElement("WeeklyHours", HRM_LIB_ELM.format(ln_HOURS) ) )
                        when nvl(ln_LESSONS, 0) != 0 then XMLElement("WorkingTime", XMLElement("WeeklyLessons", Ln_LESSONS) )
                      end
                    , case
                        when ln_activityrate != 0 then XMLElement("ActivityRate", ln_ACTIVITYRATE)
                      end
                    , XMLElement("EntryDate", HRM_LIB_ELM.FormatDate(ld_entry) )
                    , XMLForest(HRM_LIB_ELM.FormatDate(ld_leave) as "WithdrawalDate")
                    , case
                        when ln_leave != 0 and hrm_elm.get_TransmissionType <> '4' then XMLElement("LeaveEntitlement", ln_leave)
                      end
                     )
      into xmldata
      from dual;

    return xmldata;
  exception
    when no_data_found then
      return null;
  end get_work_attributes;

  function get_company_statistic
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement("Statistic", XMLElement("PayAgreement", HRM_LIB_ELM.decode_ofs_payAgreement(C_OFS_SALARY_CONTRACT) ) )
      into xmldata
      from pcs.pc_comp
     where pc_comp_id = pcs.PC_I_LIB_SESSION.getcompanyid;

    return xmldata;
  exception
    when no_data_found then
      ra('Company not found');
  end get_company_statistic;

  function get_staff
    return xmltype
  is
    xmldata xmltype;
    ld_end  date;
  begin
    ld_end  := hrm_date.ActivePeriodEndDate;

    -- Par liste et par employé, rechercher les informations désirées
    select XMLAgg
             (XMLElement("Person"
                       , XMLElement("Particulars"
                                  , XMLElement("Social-InsuranceIdentification"
                                             , case
                                                 when(P.SECUNO2 is not null) then XMLElement("SV-AS-Number", P.SECUNO2)
                                               end
                                             , case
                                                 when P.SECUNO2 is null then XMLElement("unknown")
                                               end
                                              )
                                  , XMLElement("EmployeeNumber", P.MATRICULE)
                                  , XMLElement("Lastname", P.LAST_NAME)
                                  , XMLElement("Firstname", P.FIRST_NAME)
                                  , XMLElement("Sex", P.SEX)
                                  , XMLElement("DateOfBirth", HRM_LIB_ELM.FormatDate(P.BIRTH) )
                                  , XMLElement("Nationality", P.NATIONALITY)
                                  , XMLElement("CivilStatus"
                                             , XMLElement("Status", HRM_LIB_ELM.decode_civil_status(P.CIVIL_STATUS) )
                                             , case
                                                 when emp_civil_status_since is not null then XMLElement("ValidAsOf"
                                                                                                       , HRM_LIB_ELM.FormatDate(P.emp_civil_status_since)
                                                                                                        )
                                                 else XMLElement("ValidAsOf", HRM_LIB_ELM.FormatDate(P.BIRTH) )
                                               end
                                              )
                                  ,
                                    -- Tag SingleParent uniquement si valeur = 'true'
                                    case
                                      when(SINGLE_PARENT = 1) then XMLElement("SingleParent")
                                    end
                                  , XMLElement("Address"
                                             , case
                                                 when p.per_homestreet is not null then XMLElement("Street", case when permit='G' then P.per_homestreet else street end)
                                               end
                                             , XMLElement("ZIP-Code", case when permit='G' then P.per_homepostalcode else postalcode end)
                                             , XMLElement("City", case when permit='G' then P.per_homecity else city end)
                                             , XMLElement("Country", nvl(HRM_COUNTRY_FCT.GETCOUNTRYCODE(case when permit='G' then P.per_homecountry else country end), 'CH') )
                                              )
                                  , XMLForest(p.per_email as "EmailAddress", per_home_phone as "PhoneNumber")
                                  , XMLElement("ResidenceCanton", case
                                                 when per_homecountry is null then per_homestate
                                                 else 'EX'
                                               end)
                                  , XMLForest(case
                                                when per_homecountry is null then get_tax_municipalityid(p.empid)
                                              end as "MunicipalityID"
                                            , HRM_LIB_ELM.decode_residence_categ(NATIONALITY, get_PERMIT(p.empid, ld_end) ) as "ResidenceCategory"
                                            , HRM_LIB_ELM.decode_lang(p.langid) as "LanguageCode"
                                             )
                                   )
                       , get_work_attributes(p.empid)
                       , AVS_XML
                       , LAA_XML
                       , LAAC_XML
                       , IJM_XML
                       , LPP_XML
                       , ALFA_XML
                       , TAX_XML
                       , OFS_XML
                       , taxsource_xml
                        ) order by case hrm_elm.get_Sorting_Code
                 when '01' then lpad(P.MATRICULE, 10, '0')
                 when '02' then P.SEARCH_NAME
                 when '03' then P.STATE
               end
             , case hrm_elm.get_Sorting_Code
                 when '03' then P.SEARCH_NAME
               end
             )
      into xmldata
      from (select *
              from (select p.*
                         , get_PERMIT(p.empid, ld_end) permit
                         , get_AVS_Salaries(p.empid) avs_xml
                         , get_LAA_Salaries(p.empid) laa_xml
                         , get_LAAC_Salaries(p.empid) laac_xml
                         , get_IJM_Salaries(p.empid) ijm_xml
                         , get_LPP_Salaries(p.empid) lpp_xml
                         , get_ALFA_Salaries(p.empid) alfa_xml
                         , case
                             when hrm_prc_rep_list.get_tax_list(hrm_elm.get_transmissionid) is not null then get_TAX_Salaries
                                                                                                              (p.empid
                                                                                                             , hrm_prc_rep_list.get_tax_list
                                                                                                                                     (hrm_elm.get_transmissionid)
                                                                                                              )
                           end TAX_XML
                         , case
                             when hrm_prc_rep_list.get_ofs_list(hrm_elm.get_transmissionid) is not null then get_OFS_Salaries
                                                                                                              (p.empid
                                                                                                             , hrm_prc_rep_list.get_ofs_list
                                                                                                                                     (hrm_elm.get_transmissionid)
                                                                                                              )
                           end OFS_XML
                         , hrm_elm_taxsource_xml.get_taxsource_salaries(p.empid) taxsource_xml
                      from V_HRM_ELM_PERSON p
                     where EMPID in(select distinct HRM_EMPLOYEE_ID
                                               from HRM_TMP_REP_PERIOD) ) P
             where (   AVS_XML is not null
                    or LAA_XML is not null
                    or LAAC_XML is not null
                    or IJM_XML is not null
                    or TAX_XML is not null
                    or OFS_XML is not null
                    or ALFA_XML is not null
                    or LPP_XML is not null
                    or taxsource_xml is not null
                   ) ) P;

    if (xmldata is null) then
      raise_application_error(-20000, pcs.pc_public.TranslateWord('no data found for Staff') );
    end if;

    select XMLElement("Staff", xmldata)
      into xmldata
      from dual;

    select count(value(p) )
      into gn_sal_counter_AVS
      from table(xmlsequence(extract(xmldata, '//Staff/Person/AHV-AVS-Salaries/AHV-AVS-Salary') ) ) p;

    select count(value(p) )
      into gn_sal_counter_LAA
      from table(xmlsequence(extract(xmldata, '//Staff/Person/UVG-LAA-Salaries/UVG-LAA-Salary') ) ) p;

    select count(value(p) )
      into gn_sal_counter_LAAC
      from table(xmlsequence(extract(xmldata, '//Staff/Person/UVGZ-LAAC-Salaries/UVGZ-LAAC-Salary') ) ) p;

    select count(value(p) )
      into gn_sal_counter_IJM
      from table(xmlsequence(extract(xmldata, '//Staff/Person/KTG-AMC-Salaries/KTG-AMC-Salary') ) ) p;

    select count(value(p) )
      into gn_sal_counter_LPP
      from table(xmlsequence(extract(xmldata, '//Staff/Person/BVG-LPP-Salaries/BVG-LPP-Salary') ) ) p;

    select count(value(p) )
      into gn_sal_counter_ALFA
      from table(xmlsequence(extract(xmldata, '//Staff/Person/FAK-CAF-Salaries/FAK-CAF-Salary') ) ) p;

    select count(value(p) )
      into gn_sal_counter_TAX_Salary
      from table(xmlsequence(extract(xmldata, '//Staff/Person/TaxSalaries/TaxSalary') ) ) p;

    select count(value(p) )
      into gn_sal_counter_TAX_Annuity
      from table(xmlsequence(extract(xmldata, '//Staff/Person/TaxSalaries/TaxAnnuity') ) ) p;

    select count(value(p) )
      into gn_sal_counter_OFS
      from table(xmlsequence(extract(xmldata, '//Staff/Person/StatisticSalaries/StatisticSalary') ) ) p;

    select count(value(p) )
      into gn_sal_counter_TAXSource
      from table(xmlsequence(extract(xmldata, '//Staff/Person/TaxAtSourceSalaries/TaxAtSourceSalary') ) ) p;

    return xmldata;
  end get_staff;

  function get_AVS_DeclarationCategory(in_employee_id in hrm_person.hrm_person_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select
            /* Pour les transmissions de type déclaration individuelle avec destinataire AVS
              Transmission de l'entrée ou de la sortie, voire des 2 selon le code
           */
           case
             when(c_elm_transmission_type = '2') then XMLConcat
                                                              (case
                                                                 when c_lpp_mutation_type in('01', '03') then XMLElement
                                                                                                                   ("Entry"
                                                                                                                  , XMLElement("ValidAsOf"
                                                                                                                             , HRM_LIB_ELM.formatdate(lpp_in)
                                                                                                                              )
                                                                                                                   )
                                                               end
                                                             , case
                                                                 when C_LPP_MUTATION_TYPE in('02', '03') then XMLElement
                                                                                                                  ("Withdrawal"
                                                                                                                 , XMLElement("ValidAsOf"
                                                                                                                            , HRM_LIB_ELM.formatdate(lpp_out)
                                                                                                                             )
                                                                                                                  )
                                                               end
                                                              )
           end
      into xmldata
      from hrm_lpp_emp_calc l
         , hrm_elm_transmission t
     where l.hrm_person_id = in_employee_id
       and l.hrm_elm_transmission_id = hrm_elm.get_TransmissionId
       and t.hrm_elm_transmission_id = hrm_elm.get_TransmissionId
       and exists(select 1
                    from hrm_elm_recipient r
                       , hrm_insurance i
                   where hrm_elm_transmission_id = hrm_elm.get_TransmissionId
                     and r.hrm_insurance_id = i.hrm_insurance_id
                     and c_hrm_insurance = '01');

    if xmldata is not null then
      select XMLElement("DeclarationCategory", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_AVS_DeclarationCategory;

  function get_AVS_Salaries(in_employee_id in hrm_person.hrm_person_id%type)
    return xmltype
  is
    xmldata  xmltype;
    ld_until date;
  begin
    ld_until  := get_work_attributes_until(HRM_ELM.GET_TRANSMISSIONID);

    select XMLAgg(XMLElement("AHV-AVS-Salary"
                           , XMLAttributes(HRM_LIB_ELM.to_link(AVS_SUM.InsuranceId) as "institutionIDRef")
                           , get_AVS_DeclarationCategory(in_employee_id)
                           ,
                             /* En cas d'annonce d'entrée, si l'employé n'est pas encore entré, il faut mettre comme date de sortie la date d'entrée */
                             get_AccountingTime(AVS_SUM.DateIn, case
                                                  when AVS_SUM.DateIn >= ld_until then AVS_SUM.DateIn
                                                  else AVS_SUM.DateOut
                                                end)
                           , XMLElement("AHV-AVS-Income", HRM_LIB_ELM.format(AVS_SUM.SalaryAVSAmount) )
                           , case
                               when(AVS_SUM.FreeAVSAmount != 0.0) then XMLElement("AHV-AVS-Open", HRM_LIB_ELM.format(AVS_SUM.FreeAVSAmount) )
                             end
                           , XMLElement("ALV-AC-Income", HRM_LIB_ELM.format(AVS_SUM.SalaryACAmount) )
                           , case
                               when(AVS_SUM.SalaryAC2Amount != 0.0) then XMLElement("ALVZ-ACS-Income", HRM_LIB_ELM.format(AVS_SUM.SalaryAC2Amount) )
                             end
                           , case
                               when(AVS_SUM.FreeACAmount != 0.0) then XMLElement("ALV-AC-Open", HRM_LIB_ELM.format(AVS_SUM.FreeACAmount) )
                             end
                            ) order by datein
                 )
      into xmldata
      from (select InsuranceId
                 , DateIn
                 , DateOut
                 , SalaryAVSAmount
                 , FreeAVSAmount
                 , SalaryACAmount
                 , SalaryAC2Amount
                 , FreeACAmount
              from V_HRM_ELM_AVS_SUM
                 , HRM_ELM_TRANSMISSION ELM
             where EmpId = in_employee_id
               and ELM.HRM_ELM_TRANSMISSION_ID = HRM_ELM.get_transmissionid
               and ELM.C_ELM_TRANSMISSION_TYPE <> '2'
            union all
            select RCP.HRM_INSURANCE_ID as InsuranceId
                 , LPP.LPP_IN as DateIn
                 , LPP.LPP_OUT as DateOut
                 , 0.0 as SalaryAVSAmount
                 , 0.0 as FreeAVSAmount
                 , 0.0 as SalaryACAmount
                 , 0.0 as SalaryAC2Amount
                 , 0.0 as FreeACAmount
              from HRM_LPP_EMP_CALC LPP
                 , HRM_ELM_RECIPIENT RCP
                 , HRM_INSURANCE ISR
                 , HRM_ELM_TRANSMISSION ELM
             where LPP.HRM_PERSON_ID = in_employee_id
               and ELM.HRM_ELM_TRANSMISSION_ID = HRM_ELM.get_transmissionid
               and RCP.HRM_ELM_TRANSMISSION_ID = ELM.HRM_ELM_TRANSMISSION_ID
               and LPP.HRM_ELM_TRANSMISSION_ID = ELM.HRM_ELM_TRANSMISSION_ID
               and RCP.ELM_SELECTED = 1
               and RCP.HRM_INSURANCE_ID = ISR.HRM_INSURANCE_ID
               and ISR.C_HRM_INSURANCE = '01'
               and ELM.C_ELM_TRANSMISSION_TYPE = '2'
               and not exists(select 1
                                from V_HRM_ELM_AVS_SUM
                               where EmpId = in_employee_id
                                 and InsuranceID = ISR.HRM_INSURANCE_ID) ) AVS_SUM;

    if xmldata is not null then
      select XMLElement("AHV-AVS-Salaries", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_AVS_Salaries;

  function get_LAA_Salaries(in_employee_id in hrm_person.hrm_person_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("UVG-LAA-Salary"
                           , XMLAttributes(HRM_LIB_ELM.to_link(laa_sum.InsuranceId) as "institutionIDRef")
                           , get_AccountingTime(laa_sum.datein, laa_sum.dateout)
                           , XMLElement("UVG-LAA-Code", laa_sum.code)
                           , XMLElement("UVG-LAA-GrossSalary", HRM_LIB_ELM.format(laa_sum.GrossAmount) )
                           , XMLElement("UVG-LAA-BaseSalary", HRM_LIB_ELM.format(laa_sum.BaseSubLAAAmount) )
                           , XMLElement("UVG-LAA-ContributorySalary", HRM_LIB_ELM.format(laa_sum.SalaryLAAAmount) )
                            ) order by datein
                 , code
                 )
      into xmldata
      from v_hrm_elm_laa_sum laa_sum
     where laa_sum.empid = in_employee_id;

    if xmldata is not null then
      select XMLElement("UVG-LAA-Salaries", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_LAA_Salaries;

  function get_LAAC_Salaries(in_employee_id in hrm_person.hrm_person_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("UVGZ-LAAC-Salary"
                           , XMLAttributes(HRM_LIB_ELM.to_link(laac_sum.InsuranceId) as "institutionIDRef")
                           , get_AccountingTime(laac_sum.datein, laac_sum.dateout)
                           , XMLElement("UVGZ-LAAC-Code", laac_sum.code)
                           , XMLElement("UVGZ-LAAC-BaseSalary", HRM_LIB_ELM.format(laac_sum.BaseSubLAAAmount) )
                           , XMLElement("UVGZ-LAAC-ContributorySalary", HRM_LIB_ELM.format(laac_sum.SalaryLAAAmount) )
                            ) order by datein
                 , code
                 )
      into xmldata
      from v_hrm_elm_laac_sum laac_sum
     where laac_sum.empid = in_employee_id;

    if xmldata is not null then
      select XMLElement("UVGZ-LAAC-Salaries", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_LAAC_Salaries;

  function get_IJM_Salaries(in_employee_id in hrm_person.hrm_person_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("KTG-AMC-Salary"
                           , XMLAttributes(HRM_LIB_ELM.to_link(ijm_sum.InsuranceId) as "institutionIDRef")
                           , get_AccountingTime(ijm_sum.datein, ijm_sum.dateout)
                           , XMLElement("KTG-AMC-Code", ijm_sum.code)
                           , XMLElement("Reference-AHV-AVS-Salary", HRM_LIB_ELM.format(ijm_sum.BaseSubAMCAmount) )
                           , XMLElement("KTG-AMC-ContributorySalary", HRM_LIB_ELM.format(ijm_sum.SalaryAMCAmount) )
                            ) order by datein
                 , code
                 )
      into xmldata
      from v_hrm_elm_ijm_sum ijm_sum
     where ijm_sum.empid = in_employee_id;

    if xmldata is not null then
      select XMLElement("KTG-AMC-Salaries", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_IJM_Salaries;

  function get_LPP_Code(
    in_employee_id  in hrm_person.hrm_person_id%type
  , in_list_id      in hrm_control_list.hrm_control_list_id%type
  , in_insurance_id in hrm_insurance.hrm_insurance_id%type
  , in_occurence    in integer default 1
  )
    return hrm_code_table.cod_code%type
  is
    lv_lpp_code hrm_code_table.cod_code%type;
  begin
    select hrm_prc_rep_list.GetInsuranceEquivalence(in_insurance_id, F.HRM_ELEMENTS_ROOT_ID, T.COD_CODE)
      into lv_lpp_code
      from HRM_EMPLOYEE_CONST C
         , HRM_CODE_TABLE T
         , HRM_ELEMENTS_FAMILY F
     where HRM_EMPLOYEE_ID = in_employee_id
       and sysdate between EMC_VALUE_FROM and EMC_VALUE_TO
       and C.EMC_ACTIVE = 1
       and C.HRM_CONSTANTS_ID in(
             select HRM_CONTROL_ELEMENTS_ID
               from HRM_CONTROL_ELEMENTS E
                  , hrm_insurance i
              where E.HRM_CONTROL_ELEMENTS_ID = F.HRM_ELEMENTS_ID
                and E.COE_BOX = case
                                 when in_occurence = 1 then 'CODE'
                                 else 'CODE2'
                               end
                and e.hrm_control_list_id = i.hrm_control_list_id
                and i.hrm_insurance_id = in_insurance_id)
       and T.HRM_CODE_TABLE_ID = C.HRM_CODE_TABLE_ID;

    return lv_lpp_code;
  exception
    when no_data_found then
      return null;
  end get_LPP_Code;

  function get_LPP_Salaries(in_employee_id in hrm_person.hrm_person_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg
             (XMLElement
                ("BVG-LPP-Salary"
               , xmlattributes(HRM_LIB_ELM.to_link(hrm_insurance_id) as "institutionIDRef")
               , case
                   when(c_elm_transmission_type = '2') then XMLElement
                                                              ("DeclarationCategory"
                                                             , case
                                                                 when c_lpp_mutation_type in('01', '03') then XMLElement
                                                                                                                   ("Entry"
                                                                                                                  , XMLElement("ValidAsOf"
                                                                                                                             , HRM_LIB_ELM.formatdate(lpp_in)
                                                                                                                              )
                                                                                                                   )
                                                               end
                                                             , case
                                                                 when c_lpp_mutation_type = '04' then XMLElement
                                                                                                             ("Mutation"
                                                                                                            , XMLElement("ValidAsOf"
                                                                                                                       , HRM_LIB_ELM.formatdate(lpp_valid_on)
                                                                                                                        )
                                                                                                             )
                                                               end
                                                             , case
                                                                 when c_lpp_mutation_type in('02', '03') then XMLElement
                                                                                                                  ("Withdrawal"
                                                                                                                 , XMLElement("ValidAsOf"
                                                                                                                            , HRM_LIB_ELM.formatdate(lpp_out)
                                                                                                                             )
                                                                                                                  )
                                                               end
                                                              )
                 end
               , case
                   when nvl(ins_lpp_code_used, 1) = 1
                   and nvl(lpp_code, 'SUS') not in('SUS', ' ') then XMLElement("BVG-LPP-Code", lpp_code)
                 end
               , XMLElement("BVG-LPP-AnnualBasis"
                          , HRM_LIB_ELM.format(case
                                                 when(   c_elm_transmission_type = '3'
                                                      or (    c_elm_transmission_type <> '3'
                                                          and nvl(lpp_out, lpp_valid_on) < lpp_valid_on)
                                                     ) then 0
                                                 else lpp_yearly_amount
                                               end
                                              )
                           )
                )
             )
      into xmldata
      from (select v.lpp_valid_on
                 , v.lpp_yearly_amount
                 , v.hrm_insurance_id
                 , v.hrm_control_list_id
                 , v.lpp_code
                 , t.c_elm_transmission_type
                 , lpp_in
                 , lpp_out
                 , ins.ins_lpp_code_used
                 , c_lpp_mutation_type
              from (select l.lpp_valid_on
                         , l.lpp_yearly_amount
                         , l.hrm_person_id
                         , l.hrm_elm_transmission_id
                         , r.hrm_insurance_id
                         , r.hrm_control_list_id
                         , get_lpp_code(l.hrm_person_id, r.hrm_control_list_id, r.hrm_insurance_id, 1) lpp_code
                         , c_lpp_mutation_type
                         , lpp_in
                         , lpp_out
                      from hrm_lpp_emp_calc l
                         , hrm_elm_recipient r
                     where l.hrm_person_id = in_employee_id
                       and l.hrm_elm_transmission_id = hrm_elm.get_transmissionid
                       and r.hrm_elm_transmission_id = l.hrm_elm_transmission_id
                       and r.elm_selected = 1
                    union all
                    select l.lpp_valid_on
                         , l.lpp_yearly_amount
                         , l.hrm_person_id
                         , l.hrm_elm_transmission_id
                         , r.hrm_insurance_id
                         , r.hrm_control_list_id
                         , get_lpp_code(l.hrm_person_id, r.hrm_control_list_id, r.hrm_insurance_id, 2) lpp_code
                         , c_lpp_mutation_type
                         , lpp_in
                         , lpp_out
                      from hrm_lpp_emp_calc l
                         , hrm_elm_recipient r
                     where l.hrm_person_id = in_employee_id
                       and l.hrm_elm_transmission_id = hrm_elm.get_transmissionid
                       and r.hrm_elm_transmission_id = l.hrm_elm_transmission_id
                       and r.elm_selected = 1) v
                 , hrm_elm_transmission t
                 , hrm_insurance ins
             where t.hrm_elm_transmission_id = v.hrm_elm_transmission_id
               and ins.hrm_insurance_id = v.hrm_insurance_id
               and c_hrm_insurance = '07')
     where lpp_code <> 'N/A';

    if xmldata is not null then
      select XMLElement("BVG-LPP-Salaries", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_LPP_Salaries;

  function get_ALFA_Salaries(in_employee_id in hrm_person.hrm_person_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("FAK-CAF-Salary"
                           , XMLAttributes(HRM_LIB_ELM.to_link(alfa_sum.InsuranceId) as "institutionIDRef")
                           , get_AccountingTime(alfa_sum.DateIn, alfa_sum.DateOut, 1)
                           , XMLElement("FAK-CAF-ContributorySalary", HRM_LIB_ELM.format(alfa_sum.SalaryCAFAmount) )
                           , case
                               when(alfa_sum.AllocAmount != 0.0) then XMLElement("FAK-CAF-FamilyIncomeSupplement"
                                                                               , XMLElement("FAK-CAF-FamilyIncomeSupplementPerPerson"
                                                                                          , HRM_LIB_ELM.format(alfa_sum.AllocAmount)
                                                                                           )
                                                                                )
                             end
                           , XMLElement("FAK-CAF-WorkplaceCanton", alfa_sum.canton_work)
                            ) order by datein
                 )
      into xmldata
      from v_hrm_elm_alfa_sum alfa_sum
     where alfa_sum.empid = in_employee_id;

    if xmldata is not null then
      select XMLElement("FAK-CAF-Salaries", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_ALFA_Salaries;

  function get_tax_Salaries(in_employee_id in hrm_person.hrm_person_id%type, in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg
             (case c_hrm_tax_certif_type
                when '01' then XMLElement
                                ("TaxSalary"
                               , get_AccountingTime(ino_in, ino_out, 2)
                               , case
                                   when(   nvl(EMP_CARRIER_FREE, 0) = 1
                                        or tax_car = 1) then XMLElement("FreeTransport")
                                 end
                               , case
                                   when(nvl(EMP_CANTEEN, 0) = 1) then XMLElement("CanteenLunchCheck")
                                 end
                               ,
                                 --case when (Income != 0.0) then
                                 XMLElement("Income", HRM_LIB_ELM.format(Income) )
                               --end
                              ,  XMLForest(XMLForest(case
                                                       when(FoodLodging != 0.0) then HRM_LIB_ELM.format(FoodLodging)
                                                     end as "FoodLodging"
                                                   , case
                                                       when(CompanyCar != 0.0) then HRM_LIB_ELM.format(CompanyCar)
                                                     end as "CompanyCar"
                                                   , case
                                                       when amount23 != 0 then get_Tax_SalarySumText(in_employee_id, in_list_id, '2.3', 0, langid)
                                                     end as "Other"
                                                    ) as "FringeBenefits"
                                          )
                               , XMLForest(case
                                             when amount31 != 0 then get_Tax_SalarySumText(in_employee_id, in_list_id, '3.1', 0, langid)
                                           end as "SporadicBenefits"
                                         , case
                                             when amount41 != 0 then get_Tax_SalarySumText(in_employee_id, in_list_id, '4.1', 0, langid)
                                           end as "CapitalPayment"
                                          )
                               , case
                                   when(OwnerShipRight != 0.0) then XMLElement("OwnershipRight", HRM_LIB_ELM.format(OwnerShipRight) )
                                 end
                               , case
                                   when(BoardOfDirectorsRemuneration != 0.0) then XMLElement("BoardOfDirectorsRemuneration"
                                                                                           , HRM_LIB_ELM.format(BoardOfDirectorsRemuneration)
                                                                                            )
                                 end
                               , XMLForest(case
                                             when amount71 != 0 then get_Tax_SalarySumText(in_employee_id, in_list_id, '7.1', 0, langid)
                                           end as "OtherBenefits")
                               , XMLElement("GrossIncome", HRM_LIB_ELM.format(GrossIncome) )
                               , case
                                   when(AvsContribution != 0.0) then XMLElement("AHV-ALV-NBUV-AVS-AC-AANP-Contribution", HRM_LIB_ELM.format(-AvsContribution) )
                                 end
                               , XMLForest(XMLForest(case
                                                       when(RegularLPP != 0.0) then HRM_LIB_ELM.format(-RegularLPP)
                                                     end as "Regular"
                                                   , case
                                                       when(PurchaseLPP != 0.0) then HRM_LIB_ELM.format(-PurchaseLPP)
                                                     end as "Purchase"
                                                    ) as "BVG-LPP-Contribution"
                                          )
                               , XMLElement("NetIncome", HRM_LIB_ELM.format(NetIncome) )
                               , case
                                   when(DeductionAtSource != 0.0) then XMLElement("DeductionAtSource", HRM_LIB_ELM.format(-DeductionAtSource) )
                                 end
                               , case
                                   when(   emp_tax_fullfilled = 1
                                        or tax_fees = 1) then XMLElement
                                                               ("ChargesRule"
                                                              , case
                                                                  when(tax_fees = 1) then XMLElement
                                                                                             ("WithRegulation"
                                                                                            , XMLForest(HRM_LIB_ELM.FormatDate(emp_tax_fees_date) as "Allowed"
                                                                                                      , c_hrm_canton_tax_fees as "Canton"
                                                                                                       )
                                                                                             )
                                                                  else   /*when emp_tax_fullfilled = 1 then */
                                                                      XMLElement("Guidance")
                                                                end
                                                               )
                                 end
                               , XMLForest
                                   (XMLForest
                                      (XMLForest(case
                                                   when(    emp_tax_fullfilled != 1
                                                        and tax_fees != 1
                                                        and Trip != 0) then HRM_LIB_ELM.format(Trip)   -- 13.1.1
                                                 end as "TravelFoodAccommodation"
                                               , case
                                                   when amount1312 != 0 then get_Tax_SalarySumText(in_employee_id, in_list_id, '13.1.2', tax_fees, langid)
                                                 end as "Other"
                                                ) as "Effective"
                                     , XMLForest(case
                                                   when(Representation != 0.0) then HRM_LIB_ELM.format(Representation)
                                                 end as "Representation"
                                               , case
                                                   when(Car != 0.0) then HRM_LIB_ELM.format(Car)
                                                 end as "Car"
                                               , case
                                                   when amount1323 != 0 then get_Tax_SalarySumText(in_employee_id, in_list_id, '13.2.3', 0, langid)
                                                 end as "Other"
                                                ) as "LumpSum"
                                     , case
                                         when(Training != 0.0) then HRM_LIB_ELM.format(Training)
                                       end as "Education"
                                      ) as "Charges"
                                   )
                               , XMLForest(emp_tax_other_benefits as "OtherFringeBenefits")
                               , XMLElement
                                   ("StandardRemark"
                                  , case
                                      when(   emp_tax_third_share_name is not null
                                           or emp_tax_third_share != 0) then XMLElement("StaffShareThirdCompany", emp_tax_third_share_name)
                                    end
                                  , case
                                      when(nvl(emp_tax_child_allow_peravs, 0) = 1) then XMLElement
                                                                                         ("ChildAllowancePerAHV-AVS"
                                                                                        , case
                                                                                            when FamilyIncomePerAVS != 0 then XMLElement
                                                                                                                               ("FamilyIncome"
                                                                                                                              , HRM_LIB_ELM.format
                                                                                                                                             (FamilyIncomePerAVS)
                                                                                                                               )
                                                                                          end
                                                                                         )
                                    end
                                  , case
                                      when(RelocationCosts != 0.0) then XMLElement("RelocationCosts", HRM_LIB_ELM.format(RelocationCosts) )
                                    end
                                  , case
                                      when(    c_hrm_canton_tax_share is not null
                                           and emp_tax_share_date is not null) then XMLForest
                                                                                     (XMLForest(HRM_LIB_ELM.FormatDate(emp_tax_share_date) as "Allowed"
                                                                                              , c_hrm_canton_tax_share as "Canton"
                                                                                               ) as "StaffShareMarketValue"
                                                                                     )
                                    end
                                  , case
                                      when(trim(ShareReason) is not null) then XMLElement("StaffShareWithoutTaxableIncome", ShareReason)
                                    end
                                  , case
                                      when(tax_car = 1) then XMLForest
                                                                     (XMLForest(HRM_LIB_ELM.FormatDate(EMP_TAX_CAR_DATE) as "Allowed"
                                                                              , c_hrm_canton_tax_car as "Canton"
                                                                               ) as "PrivatePartCompanyCar"
                                                                     )
                                    end
                                  , case
                                      when(nvl(emp_tax_car_check, 0) = 1) then XMLElement("CompanyCarClarify")
                                    end
                                  , case
                                      when(nvl(EMP_TAX_CAR_MIN_PART, 0) = 1) then XMLElement("MinimalEmployeeCarPartPercentage")
                                    end
                                  , case
                                      when DeductionAtSource <> 0 then XMLElement("TaxAtSourcePeriodForObjection")
                                    end
                                   )
                               , XMLForest(trim(both ';' from case
                                                                when(emp_tax_remarks is not null) then emp_tax_remarks||'.'
                                                              end ||
                                                              nvl2(case151, case151 || ';', '') ||
                                                              case151Text
                                               ) as "Remark"
                                          )
                               ,
                                 -- Fonction à implémenter
                                 get_ownershipRightDetails(in_employee_id)
                               , case
                                   when EMP_TAX_CONTACT_NAME is not null then XMLElement("Contact"
                                                                                       , XMLElement("HR-RC-Name"
                                                                                                  , (select COM_SOCIALNAME
                                                                                                       from PCS.PC_COMP
                                                                                                      where PC_COMP_ID = pcs.PC_I_LIB_SESSION.GetCompanyId)
                                                                                                   )
                                                                                       , XMLElement("Address"
                                                                                                  , XMLElement("ZIP-Code", EMP_TAX_CONTACT_ZIP)
                                                                                                  , XMLElement("City", EMP_TAX_CONTACT_CITY)
                                                                                                   )
                                                                                       , XMLElement("Person", EMP_TAX_CONTACT_NAME)
                                                                                       , XMLElement("PhoneNumber", EMP_TAX_CONTACT_PHONE)
                                                                                        )
                                 end
                                )
                else   -- c_hrm_tax_certif_type = '02'
                    XMLElement("TaxAnnuity"
                             , get_AccountingTime(ino_in, ino_out, 2)
                             , XMLElement("Income", HRM_LIB_ELM.format(Income) )
                             , XMLElement("GrossIncome", HRM_LIB_ELM.format(GrossIncome) )
                             , XMLElement("NetIncome", HRM_LIB_ELM.format(NetIncome) )
                              )
              end
             )
      into xmldata
      from (select c_hrm_tax_certif_type
                 , Income
                 , FoodLodging
                 , CompanyCar
                 , OwnerShipRight
                 , BoardOfDirectorsRemuneration
                 , GrossIncome
                 , AvsContribution
                 , RegularLPP
                 , PurchaseLPP
                 , NetIncome
                 , DeductionAtSource
                 , Trip
                 , FamilyIncomePerAVS
                 , RelocationCosts
                 , amount23
                 , amount31
                 , amount41
                 , amount71
                 , amount1312
                 , amount1323
                 , langid
                 , Representation
                 , Car
                 , Training
                 , tax.emp_tax_remarks
                 , tax.emp_canteen
                 , tax.emp_carrier_free
                 , EMP_TAX_CAR_MIN_PART
                 , c_hrm_canton_tax_fees
                 , emp_tax_fees_date
                 , tax_fees
                 , emp_tax_fullfilled
                 , emp_tax_other_benefits
                 , emp_tax_third_share
                 , emp_tax_child_allow_peravs
                 , emp_tax_car_date
                 , c_hrm_canton_tax_car
                 , tax_car
                 , emp_tax_car_check
                 , c_hrm_canton_tax_share
                 , emp_tax_share_date
                 , emp_tax_third_share_name
                 , emp_tax_contact_city
                 , emp_tax_contact_email
                 , emp_tax_contact_name
                 , emp_tax_contact_phone
                 , emp_tax_contact_zip
                 , case
                     when(dic_hrm_tax_share_reason_id is not null) then com_dic_functions.getDicoDescr('DIC_HRM_TAX_SHARE_REASON'
                                                                                                     , dic_hrm_tax_share_reason_id
                                                                                                     , case c_hrm_elm_lang
                                                                                                         when '01' then (select pc_lang_id
                                                                                                                           from pcs.pc_lang
                                                                                                                          where lanid = 'FR')
                                                                                                         when '02' then (select pc_lang_id
                                                                                                                           from pcs.pc_lang
                                                                                                                          where lanid = 'GE')
                                                                                                         when '03' then (select pc_lang_id
                                                                                                                           from pcs.pc_lang
                                                                                                                          where lanid = 'IT')
                                                                                                         else langid
                                                                                                       end
                                                                                                      )
                   end ||
                   case
                     when(dic_hrm_tax_share_reason2_id is not null) then ' ' ||
                                                                         com_dic_functions.getDicoDescr('DIC_HRM_TAX_SHARE_REASON'
                                                                                                      , dic_hrm_tax_share_reason2_id
                                                                                                      , case c_hrm_elm_lang
                                                                                                          when '01' then (select pc_lang_id
                                                                                                                            from pcs.pc_lang
                                                                                                                           where lanid = 'FR')
                                                                                                          when '02' then (select pc_lang_id
                                                                                                                            from pcs.pc_lang
                                                                                                                           where lanid = 'GE')
                                                                                                          when '03' then (select pc_lang_id
                                                                                                                            from pcs.pc_lang
                                                                                                                           where lanid = 'IT')
                                                                                                          else langid
                                                                                                        end
                                                                                                       )
                   end ShareReason
                 , get_Tax_SalaryText(p.hrm_person_id, in_list_id, '15.1', langid) case151
                 , hrm_prc_rep_list.get_TextList(in_list_id, '15.1', langid, 1) case151Text
                 , hrm_prc_rep_list.get_entry(p.hrm_person_id, 1) ino_in
                 , hrm_prc_rep_list.get_leave(p.hrm_person_id, 1) ino_out
              from
                   /*Recherche des montants groupés par position*/
                   (select sum(case
                                 when coe_box = '1.1' then his_pay_sum_val
                                 else 0
                               end) income
                         , sum(case
                                 when coe_box = '2.1' then his_pay_sum_val
                                 else 0
                               end) foodlodging
                         , sum(case
                                 when coe_box = '2.2' then his_pay_sum_val
                                 else 0
                               end) companycar
                         , sum(case
                                 when coe_box = '5.1' then his_pay_sum_val
                                 else 0
                               end) ownershipright
                         , sum(case
                                 when coe_box = '6.1' then his_pay_sum_val
                                 else 0
                               end) boardofdirectorsremuneration
                         , sum(case
                                 when coe_box in('1.1', '2.1', '2.2', '2.3', '3.1', '4.1', '5.1', '6.1', '7.1') then his_pay_sum_val
                                 else 0
                               end) grossincome
                         , sum(case
                                 when coe_box = '9.1' then his_pay_sum_val
                                 else 0
                               end) avscontribution
                         , sum(case
                                 when coe_box = '10.1' then his_pay_sum_val
                                 else 0
                               end) regularlpp
                         , sum(case
                                 when coe_box = '10.2' then his_pay_sum_val
                                 else 0
                               end) purchaselpp
                         , sum(case
                                 when coe_box in('1.1', '2.1', '2.2', '2.3', '3.1', '4.1', '5.1', '6.1', '7.1', '9.1', '10.1', '10.2') then his_pay_sum_val
                                 else 0
                               end) netincome
                         , sum(case
                                 when coe_box = '12.1' then his_pay_sum_val
                                 else 0
                               end) deductionatsource
                         , sum(case
                                 when coe_box = '13.1.1' then his_pay_sum_val
                                 else 0
                               end) trip
                         , sum(case
                                 when coe_box = '13.2.1' then his_pay_sum_val
                                 else 0
                               end) representation
                         , sum(case
                                 when coe_box = '13.2.2' then his_pay_sum_val
                                 else 0
                               end) car
                         , sum(case
                                 when coe_box = '13.3.1' then his_pay_sum_val
                                 else 0
                               end) training
                         , sum(case
                                 when coe_box = '15.1.1' then his_pay_sum_val
                                 else 0
                               end) FamilyIncomePerAVS
                         , sum(case
                                 when coe_box = '15.1.2' then his_pay_sum_val
                                 else 0
                               end) RelocationCosts
                         , sum(case
                                 when coe_box = '2.3' then his_pay_sum_val
                                 else 0
                               end) amount23
                         , sum(case
                                 when coe_box = '3.1' then his_pay_sum_val
                                 else 0
                               end) amount31
                         , sum(case
                                 when coe_box = '4.1' then his_pay_sum_val
                                 else 0
                               end) amount41
                         , sum(case
                                 when coe_box = '7.1' then his_pay_sum_val
                                 else 0
                               end) amount71
                         , sum(case
                                 when coe_box = '13.1.2' then his_pay_sum_val
                                 else 0
                               end) amount1312
                         , sum(case
                                 when coe_box = '13.2.3' then his_pay_sum_val
                                 else 0
                               end) amount1323
                      from hrm_control_elements e
                         , hrm_history_detail d
                         , hrm_history h
                     where e.hrm_control_list_id = in_list_id
                       and d.hrm_elements_id = e.hrm_control_elements_id
                       and hit_pay_num = his_pay_num
                       and h.hrm_employee_id = in_employee_id
                       and d.hrm_employee_id = in_employee_id
                       and hit_pay_period between hrm_prc_rep_list.BeginOfPeriod and hrm_prc_rep_list.EndOfPeriod) s
                 , (select hrm_person_id
                         , HRM_LIB_ELM.decode_langid(person.pc_lang_id) langid
                      from hrm_person person) p
                 , (select case
                             when emp_tax_fees_date is not null
                             and c_hrm_canton_tax_fees is not null then 1
                             else 0
                           end tax_fees
                         , case
                             when emp_tax_car_date is not null
                             and c_hrm_canton_tax_car is not null then 1
                             else 0
                           end tax_car
                         , hrm_person_id
                         , c_hrm_tax_certif_type
                         , c_hrm_canton_tax_car
                         , emp_tax_car_date
                         , emp_tax_fullfilled
                         , c_hrm_canton_tax_share
                         , emp_tax_share_date
                         , dic_hrm_tax_share_reason_id
                         , emp_tax_expat_expenses
                         , emp_tax_other_benefits
                         , c_hrm_canton_tax_fees
                         , emp_tax_fees_date
                         , emp_tax_third_share
                         , emp_tax_third_share_name
                         , emp_tax_child_allow_peravs
                         , emp_tax_relocation_costs
                         , emp_tax_car_check
                         , dic_hrm_tax_share_reason2_id
                         , emp_tax_is_expatriate
                         , emp_tax_contact_name
                         , emp_tax_contact_phone
                         , emp_tax_contact_email
                         , emp_tax_contact_zip
                         , emp_tax_contact_city
                         , emp_tax_car_min_part
                         , emp_carrier_free
                         , emp_canteen
                         , trim(both ';' from nvl2(emp_certif_observation, emp_certif_observation || ';', '') ||
                                              nvl2(emp_tax_remark_line01, emp_tax_remark_line01 || ';', '') ||
                                              nvl2(emp_tax_remark_line02, emp_tax_remark_line02 || ';', '') ||
                                              nvl2(emp_tax_remark_line03, emp_tax_remark_line03 || ';', '') ||
                                              nvl2(emp_tax_remark_line04, emp_tax_remark_line04 || ';', '') ||
                                              nvl2(emp_tax_remark_line05, emp_tax_remark_line05 || ';', '') ||
                                              nvl2(emp_tax_remark_line06, emp_tax_remark_line06 || ';', '') ||
                                              nvl2(emp_tax_remark_line07, emp_tax_remark_line07 || ';', '') ||
                                              nvl2(emp_tax_remark_line08, emp_tax_remark_line08 || ';', '') ||
                                              nvl2(emp_tax_remark_line09, emp_tax_remark_line09 || ';', '') ||
                                              nvl2(emp_tax_remark_line10, emp_tax_remark_line10 || ';', '')
                               ) emp_tax_remarks
                         , hrm_person_tax_id
                      from hrm_person_tax
                     where emp_tax_year = hrm_elm.get_period) tax
                 , hrm_elm_transmission t
             where tax.hrm_person_id = in_employee_id
               and p.hrm_person_id = tax.hrm_person_id
               and t.hrm_elm_transmission_id = hrm_elm.get_transmissionid);

    if xmldata is not null then
      select XMLElement("TaxSalaries", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  exception
    when no_data_found then
      ra('Tax information not found');
  end get_tax_Salaries;

  function get_tax_salarySumText(
    in_employee_id in hrm_person.hrm_person_id%type
  , in_list_id     in hrm_control_list.hrm_control_list_id%type
  , iv_coebox      in hrm_control_elements.coe_box%type
  , in_optional    in integer default 0
  , in_langid      in pcs.pc_lang.pc_lang_id%type
  )
    return xmltype
  is
    xmldata xmltype;
    ln_sum  hrm_history_detail.his_pay_sum_val%type   := 0.0;
    lv_text varchar2(32767);

    cursor lcur_sum_text(id_from in date, id_to in date)
    is
      select   sum(HIS_PAY_SUM_VAL) HIS_PAY_SUM_VAL
             , ERD_DESCR TEXT
          from HRM_HISTORY_DETAIL H
             , HRM_HISTORY HT
             , HRM_CONTROL_ELEMENTS E
             , HRM_ELEMENTS_FAMILY F
             , HRM_ELEMENTS_ROOT_DESCR D
         where E.HRM_CONTROL_ELEMENTS_ID = H.HRM_ELEMENTS_ID
           and F.HRM_ELEMENTS_ID = E.HRM_CONTROL_ELEMENTS_ID
           and F.HRM_ELEMENTS_ROOT_ID = D.HRM_ELEMENTS_ROOT_ID
           and HT.HRM_EMPLOYEE_ID = in_employee_id
           and E.COE_BOX = iv_coebox
           and H.HRM_EMPLOYEE_ID = HT.HRM_EMPLOYEE_ID
           and HT.HIT_PAY_NUM = H.HIS_PAY_NUM
           and HT.HIT_PAY_PERIOD between id_from and id_to
           and E.HRM_CONTROL_LIST_ID = in_list_id
           and D.PC_LANG_ID = in_langid
      group by ERD_DESCR;
  begin
    for tpl_sum_text in lcur_sum_text(hrm_prc_rep_list.BeginOfPeriod, hrm_prc_rep_list.EndOfPeriod) loop
      ln_sum   := ln_sum + tpl_sum_text.his_pay_sum_val;
      lv_text  := lv_text || ', ' || tpl_sum_text.Text;
    end loop;

    if (ln_sum != 0.0) then
      select XMLForest(substr(lv_text, 3) as "Text", case
                         when(in_optional = 0) then HRM_LIB_ELM.format(ln_sum)
                       end as "Sum")
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_tax_salarySumText;

  function get_tax_salaryText(
    in_employee_id in hrm_person.hrm_person_id%type
  , in_list_id     in hrm_control_list.hrm_control_list_id%type
  , iv_coebox      in hrm_control_elements.coe_box%type
  , in_langid      in pcs.pc_lang.pc_lang_id%type
  )
    return varchar2
  is
    lv_text varchar2(32767);

    cursor lcur_text(id_from in date, id_to in date)
    is
      select case
               when(ELR_ROOT_RATE = 0) then ERD_DESCR || ' (' || to_char(HISVAL) || '); '
               when(HISVAL != 100) then   -- pas afficher si le % = 100
                                       ERD_DESCR || ' ' || to_char(HISVAL) || '%; '
             end TEXT
        from (select   nvl(hed_DESCR, coe_descr) ERD_DESCR
                     ,   -- utilisation de coe_descr, comme pour le rapport
                       case
                         when ELR_ROOT_RATE = 0 then sum(HIS_PAY_SUM_VAL)
                         else max(HIS_PAY_SUM_VAL)
                       end HISVAL
                     , ELR_ROOT_RATE
                  from HRM_HISTORY_DETAIL H
                     , HRM_HISTORY HT
                     , HRM_CONTROL_ELEMENTS E
                     , HRM_CONTROL_ELEMENTS_DESCR D
                     , HRM_ELEMENTS_FAMILY F
                     , HRM_ELEMENTS_ROOT R
                 where e.HRM_CONTROL_ELEMENTS_ID = H.HRM_ELEMENTS_ID
                   and F.HRM_ELEMENTS_ID = H.HRM_ELEMENTS_ID
                   and R.HRM_ELEMENTS_ROOT_ID = F.HRM_ELEMENTS_ROOT_ID
                   and HT.HRM_EMPLOYEE_ID = in_employee_id
                   and E.coE_BOX = iv_coebox
                   and HT.HIT_PAY_PERIOD between id_from and id_to
                   and HT.HRM_EMPLOYEE_ID = H.HrM_EMPLOYEE_ID
                   and HT.HIT_PAY_NUM = H.HIS_PAY_NUM
                   and E.hrM_CONTROL_LIST_ID = in_list_id
                   and E.HRM_CONTROL_ELEM_ID = D.HRM_CONTROL_ELEM_ID(+)
                   and D.PC_LANG_ID(+) = in_langid
              group by ELR_ROOT_RATE
                     , hed_descr
                     , COE_DESCR);
  begin
    for tpl_text in lcur_text(hrm_prc_rep_list.BeginOfPeriod, hrm_prc_rep_list.EndOfPeriod) loop
      lv_text  := lv_text || tpl_text.Text;
    end loop;

    return lv_text;
  exception
    when no_data_found then
      ra('Salary text not found');
  end get_tax_salaryText;

  function get_last_contract_type(in_employee_id in hrm_person.hrm_person_id%type, id_in in date, id_out in date)
    return varchar2
  is
    lv_result varchar2(50);
  begin
    select HRM_LIB_ELM.decode_ofs_contracttype(c_contract_type)
      into lv_result
      from (select   c_contract_type
                from hrm_contract
               where hrm_employee_id = in_employee_id
                 and con_begin between id_in and id_out
            order by con_begin desc)
     where rownum = 1;

    return lv_result;
  end get_last_contract_type;

  function get_OFS_October_Salaries(in_employee_id in hrm_person.hrm_person_id%type, in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata xmltype;
    ln_rate hrm_contract.con_activity_rate%type;
  begin
    begin
      select least(trunc(sum(nvl(CON_ACTIVITY_RATE, 0) ) ), 100)
        into ln_rate
        from HRM_CONTRACT
       where HRM_EMPLOYEE_ID = in_employee_id
         and add_months(hrm_prc_rep_list.BeginOfPeriod, 10) - 1 between CON_BEGIN and nvl(CON_END, hrm_prc_rep_list.EndOfPeriod);
    exception
      when no_data_found then
        null;
    end;

    select case
             when(   ln_rate != 0.0
                  or nvl(HOURSWORK, 0.0) != 0.0
                  or nvl(LESSONSWORK, 0.0) != 0.0
                  or nvl(GROSSEARNINGS, 0.0) != 0.0
                  or nvl(SOCIALCONTRIBUTIONS, 0.0) != 0.0
                 ) then XMLElement("October"
                                 , case
                                     when ln_rate != 0.0 then XMLElement("ActivityRate", trunc(ln_rate) )
                                   end
                                 , case
                                     when(HOURSWORK != 0.0) then XMLElement("TotalHoursOfWork", HRM_LIB_ELM.format(HOURSWORK) )
                                   end
                                 , case
                                     when(LESSONSWORK != 0.0) then XMLElement("TotalLessonsOfWork", LESSONSWORK)
                                   end
                                 , case
                                     when(GROSSEARNINGS != 0.0) then XMLElement("GrossEarnings", HRM_LIB_ELM.format(GROSSEARNINGS) )
                                   end
                                 , case
                                     when(SOCIALCONTRIBUTIONS != 0.0) then XMLElement("SocialContributions", HRM_LIB_ELM.format(SOCIALCONTRIBUTIONS) )
                                   end
                                 , case
                                     when(ALLOWANCES != 0.0) then XMLElement("Allowances", HRM_LIB_ELM.format(ALLOWANCES) )
                                   end
                                 , case
                                     when(PaymentsByThird != 0.0) then XMLElement("PaymentsByThird", HRM_LIB_ELM.format(PaymentsByThird) )
                                   end
                                 , case
                                     when(FamilyIncomeSupplement != 0.0) then XMLElement("FamilyIncomeSupplement", HRM_LIB_ELM.format(FamilyIncomeSupplement) )
                                   end
                                 , case
                                     when(LPP != 0.0) then XMLElement("BVG-LPP-RegularContribution", HRM_LIB_ELM.format(LPP) )
                                   end
                                  )
           end
      into xmldata
      from (select sum(case
                         when COE_BOX = 'F1' then HIS_PAY_SUM_VAL
                         else 0
                       end) HOURSWORK
                 , sum(case
                         when COE_BOX = 'F2' then HIS_PAY_SUM_VAL
                         else 0
                       end) LESSONSWORK
                 , sum(case
                         when COE_BOX = 'I' then HIS_PAY_SUM_VAL
                         else 0
                       end) GROSSEARNINGS
                 , sum(case
                         when COE_BOX = 'L' then HIS_PAY_SUM_VAL
                         else 0
                       end) SOCIALCONTRIBUTIONS
                 , sum(case
                         when COE_BOX = 'J' then HIS_PAY_SUM_VAL
                         else 0
                       end) ALLOWANCES
                 , sum(case
                         when COE_BOX = 'Y' then HIS_PAY_SUM_VAL
                         else 0
                       end) PaymentsByThird
                 , sum(case
                         when COE_BOX = 'K' then HIS_PAY_SUM_VAL
                         else 0
                       end) FamilyIncomeSupplement
                 , sum(case
                         when COE_BOX = 'M' then HIS_PAY_SUM_VAL
                         else 0
                       end) LPP
              from HRM_CONTROL_ELEMENTS E
                 , HRM_HISTORY_DETAIL D
                 , HRM_HISTORY H
             where E.HRM_CONTROL_LIST_ID = in_list_id
               and D.HRM_EMPLOYEE_ID = in_employee_id
               and H.HRM_EMPLOYEE_ID = D.HRM_EMPLOYEE_ID
               and H.HIT_PAY_NUM = D.HIS_PAY_NUM
               and add_months(hrm_prc_rep_list.BeginOfPeriod, 10) - 1 = HIT_PAY_PERIOD
               and D.HRM_ELEMENTS_ID = E.HRM_CONTROL_ELEMENTS_ID);

    return xmldata;
  exception
    when no_data_found then
      ra('OFS values to send not found');
  end get_OFS_October_Salaries;

  function get_OFS_Salaries(in_employee_id in hrm_person.hrm_person_id%type, in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("StatisticSalary"
                           , XMLAttributes(HRM_LIB_ELM.to_link(hrm_establishment_id) as "workplaceIDRef")
                           , case
                               when add_months(hrm_prc_rep_list.BeginOfPeriod, 10) - 1 between trunc(ino_in, 'month')
                                                                                           and nvl(last_day(ino_out), to_date('31.12.2050', 'dd.mm.yyyy') ) then get_OFS_October_Salaries
                                                                                                                                                                  (in_employee_id
                                                                                                                                                                 , in_list_id
                                                                                                                                                                  )
                             end
                           , get_AccountingTime(ino_in, ino_out, 2)
                           , case
                               when(HoursWork >= 1.0) then XMLElement("TotalHoursOfWork", HRM_LIB_ELM.format(HoursWork) )
                             end
                           , case
                               when(LessonsWork >= 1) then XMLElement("TotalLessonsOfWork", LessonsWork)
                             end
                           , case
                               when(GrossEarnings != 0.0) then XMLElement("GrossEarnings", HRM_LIB_ELM.format(GrossEarnings) )
                             end
                           , case
                               when(SocialContributions != 0.0) then XMLElement("SocialContributions", HRM_LIB_ELM.format(SocialContributions) )
                             end
                           , case
                               when(Allowances != 0.0) then XMLElement("Allowances", HRM_LIB_ELM.format(Allowances) )
                             end
                           , case
                               when(Overtime != 0.0) then XMLElement("Overtime", HRM_LIB_ELM.format(Overtime) )
                             end
                           , case
                               when(Earnings13th != 0.0) then XMLElement("Earnings13th", HRM_LIB_ELM.format(Earnings13th) )
                             end
                           , case
                               when(SporadicBenefits != 0.0) then XMLElement("SporadicBenefits", HRM_LIB_ELM.format(SporadicBenefits) )
                             end
                           , case
                               when(PayThird != 0.0) then XMLElement("PaymentsByThird", HRM_LIB_ELM.format(PayThird) )
                             end
                           , case
                               when(FamilyIncomeSupplement != 0.0) then XMLElement("FamilyIncomeSupplement", HRM_LIB_ELM.format(FamilyIncomeSupplement) )
                             end
                           , case
                               when(FringeBenefits != 0.0) then XMLElement("FringeBenefits", HRM_LIB_ELM.format(FringeBenefits) )
                             end
                           , case
                               when(CapitalPayment != 0.0) then XMLElement("CapitalPayment", HRM_LIB_ELM.format(CapitalPayment) )
                             end
                           , case
                               when(OtherBenefits != 0.0) then XMLElement("OtherBenefits", HRM_LIB_ELM.format(OtherBenefits) )
                             end
                           , case
                               when(LPPREGULAR != 0.0) then XMLElement("BVG-LPP-RegularContribution", HRM_LIB_ELM.format(LPPREGULAR) )
                             end
                           , case
                               when(LPPRACHAT != 0.0) then XMLElement("BVG-LPP-PurchaseContribution", HRM_LIB_ELM.format(LPPRACHAT) )
                             end
                           , XMLElement("Education", HRM_LIB_ELM.decode_ofs_education(c_ofs_training) )
                           , XMLElement("Position", HRM_LIB_ELM.decode_ofs_position(c_ofs_responsability) )
                           , XMLElement("Contract", get_last_contract_type(in_employee_id, ino_in, ino_out) )
                           , XMLElement("JobTitle", nvl(emp_ofs_position, (select job_title
                                                                             from hrm_job
                                                                            where hrm_job_id = v.hrm_job_id) ) )
                            )
                 )
      into xmldata
      from (select HoursWork
                 , LessonsWork
                 , GrossEarnings
                 , SocialContributions
                 , Allowances
                 , Overtime
                 , HRM_ESTABLISHMENT_ID
                 , Earnings13th
                 , SporadicBenefits
                 , PayThird
                 , FamilyIncomeSupplement
                 , OtherBenefits
                 , c_ofs_training
                 , c_ofs_job_qualif
                 , c_ofs_responsability
                 , c_ofs_activity
                 , c_ofs_salary_type
                 , hrm_job_id
                 , ino_in
                 , ino_out
                 , emp_ofs_position
                 , FringeBenefits
                 , lppregular
                 , lpprachat
                 , capitalpayment
              from
                   /*Info de la personne*/
                   hrm_person p
                 ,
                   /*Recherche des montants groupés par position*/
                   (select   hrm_establishment_id
                           , ino_in
                           , nvl(ino_out, hrm_prc_rep_list.EndOfPeriod) ino_out
                           , sum(case
                                   when coe_box = 'F1' then his_pay_sum_val
                                   else 0
                                 end) HoursWork
                           , sum(case
                                   when coe_box = 'F2' then his_pay_sum_val
                                   else 0
                                 end) LessonsWork
                           , sum(case
                                   when coe_box = 'I' then his_pay_sum_val
                                   else 0
                                 end) GrossEarnings
                           , sum(case
                                   when coe_box = 'L' then his_pay_sum_val
                                   else 0
                                 end) SocialContributions
                           , sum(case
                                   when coe_box = 'J' then his_pay_sum_val
                                   else 0
                                 end) Allowances
                           , sum(case
                                   when coe_box = 'P' then his_pay_sum_val
                                   else 0
                                 end) Overtime
                           , sum(case
                                   when coe_box = 'O' then his_pay_sum_val
                                   else 0
                                 end) Earnings13th
                           , sum(case
                                   when coe_box = 'Q' then his_pay_sum_val
                                   else 0
                                 end) SporadicBenefits
                           , sum(case
                                   when coe_box = 'Y' then his_pay_sum_val
                                   else 0
                                 end) PayThird
                           , sum(case
                                   when coe_box = 'K' then his_pay_sum_val
                                   else 0
                                 end) FamilyIncomeSupplement
                           , sum(case
                                   when coe_box = 'R' then his_pay_sum_val
                                   else 0
                                 end) FringeBenefits
                           , sum(case
                                   when coe_box = 'T' then his_pay_sum_val
                                   else 0
                                 end) OtherBenefits
                           , sum(case
                                   when coe_box = 'S' then his_pay_sum_val
                                   else 0
                                 end) capitalpayment
                           , sum(case
                                   when coe_box = 'M' then his_pay_sum_val
                                   else 0
                                 end) lppregular
                           , sum(case
                                   when coe_box = 'Z' then his_pay_sum_val
                                   else 0
                                 end) lpprachat
                        from hrm_control_elements e
                           , hrm_tmp_rep_period p
                           , hrm_history_detail h
                       where e.hrm_control_list_id = in_list_id
                         and p.hrm_control_list_id = e.hrm_control_list_id
                         and p.hrm_employee_id = in_employee_id
                         and h.hrm_employee_id = p.hrm_employee_id
                         and h.his_pay_num between p.fromnum and p.tonum
                         and h.hrm_elements_id = e.hrm_control_elements_id
                    group by ino_in
                           , ino_out
                           , hrm_establishment_id) v
             where p.hrm_person_id = in_employee_id
               and emp_ofs_included = 1) v;

    if xmldata is not null then
      select XMLElement("StatisticSalaries", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_OFS_Salaries;

  function get_insurance_AVS
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("AHV-AVS"
                           , XMLAttributes(HRM_LIB_ELM.to_link(v.InstitutionID) as "institutionID")
                           , XMLElement("AK-CC-BranchNumber", v.reference)
                           , XMLElement("AK-CC-CustomerNumber", v.CustomerNumber)
                           , XMLForest(v.CustomerSubNumber as "AK-CC-SubNumber")
                           ,   -- empty authorized
                             HRM_LIB_ELM.recipient_comment(elm_recipient_comment)
                            )
                 )
      into xmldata
      from v_hrm_elm_insurance v
         , hrm_elm_recipient r
     where v.Insurance = '01'
       and v.InstitutionID = r.hrm_insurance_id
       and r.elm_selected = 1
       and r.hrm_elm_transmission_id = hrm_elm.get_TransmissionId;

    return xmldata;
  end get_insurance_AVS;

  function get_insurance_LAAC
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("UVGZ-LAAC"
                           , XMLAttributes(HRM_LIB_ELM.to_link(v.InstitutionID) as "institutionID")
                           , XMLElement("InsuranceID", v.reference)
                           , XMLElement("InsuranceCompanyName", v.CompanyName)
                           , XMLElement("CustomerIdentity", v.CustomerNumber)
                           , XMLElement("ContractIdentity", v.ContractNumber)
                           , HRM_LIB_ELM.recipient_comment(elm_recipient_comment)
                            )
                 )
      into xmldata
      from v_hrm_elm_insurance v
         , hrm_elm_recipient r
     where v.Insurance = '04'
       and v.InstitutionID = r.hrm_insurance_id
       and r.elm_selected = 1
       and r.hrm_elm_transmission_id = hrm_elm.get_TransmissionId;

    return xmldata;
  end get_insurance_LAAC;

  function get_insurance_IJM
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("KTG-AMC"
                           , XMLAttributes(HRM_LIB_ELM.to_link(v.InstitutionID) as "institutionID")
                           , XMLElement("InsuranceID", v.reference)
                           , XMLElement("InsuranceCompanyName", v.CompanyName)
                           , XMLElement("CustomerIdentity", v.CustomerNumber)
                           , XMLElement("ContractIdentity", v.ContractNumber)
                           , HRM_LIB_ELM.recipient_comment(elm_recipient_comment)
                            )
                 )
      into xmldata
      from v_hrm_elm_insurance v
         , hrm_elm_recipient r
     where v.Insurance = '05'
       and v.InstitutionID = r.hrm_insurance_id
       and r.elm_selected = 1
       and r.hrm_elm_transmission_id = hrm_elm.get_TransmissionId;

    return xmldata;
  end get_insurance_IJM;

  function get_insurance_LPP
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("BVG-LPP"
                           , XMLAttributes(HRM_LIB_ELM.to_link(InstitutionID) as "institutionID")
                           , XMLElement("InsuranceID", reference)
                           , XMLElement("InsuranceCompanyName", CompanyName)
                           , XMLForest(CustomerNumber as "CustomerIdentity")
                           , XMLElement("ContractIdentity", ContractNumber)
                           , HRM_LIB_ELM.recipient_comment(elm_recipient_comment)
                           , case
                               when PayrollUnit is not null then XMLElement("PayrollUnit", payrollunit)
                             end
                           , XMLElement("GeneralValidAsOf", ELM_VALID_AS_OF)
                            )
                 )
      into xmldata
      from (select   max(ELM_RECIPIENT_COMMENT) ELM_RECIPIENT_COMMENT
                   , max(elm_incomplete) ELM_INCOMPLETE
                   , Insurance
                   , InstitutionId
                   , reference
                   , CompanyName
                   , CustomerNumber
                   , ContractNumber
                   , PayrollUnit
                   , trunc(ELM_VALID_AS_OF) ELM_VALID_AS_OF
                from V_HRM_ELM_INSURANCE V
                   , HRM_ELM_RECIPIENT R
                   , HRM_ELM_TRANSMISSION T
               where v.Insurance = '07'
                 and v.InstitutionID = R.HRM_INSURANCE_ID
                 and R.ELM_SELECTED = 1
                 and T.HRM_ELM_TRANSMISSION_ID = hrm_elm.get_TransmissionId
                 and R.HRM_ELM_TRANSMISSION_ID = T.HRM_ELM_TRANSMISSION_ID
            group by Insurance
                   , InstitutionId
                   , reference
                   , CompanyName
                   , CustomerNumber
                   , PayrollUnit
                   , ContractNumber
                   , trunc(ELM_VALID_AS_OF) );

    return xmldata;
  end get_insurance_LPP;

  function get_insurance_ALFA
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("FAK-CAF"
                           , XMLAttributes(HRM_LIB_ELM.to_link(v.InstitutionID) as "institutionID")
                           , XMLElement("FAK-CAF-BranchNumber", v.reference)
                           , XMLElement("FAK-CAF-CustomerNumber", v.CustomerNumber)
                           , XMLForest(v.CustomerSubNumber as "FAK-CAF-SubNumber")
                           , HRM_LIB_ELM.recipient_comment(elm_recipient_comment)
                            )
                 )
      into xmldata
      from v_hrm_elm_insurance v
         , hrm_elm_recipient r
     where v.Insurance = '06'
       and v.InstitutionID = r.hrm_insurance_id
       and r.elm_selected = 1
       and r.hrm_elm_transmission_id = hrm_elm.get_TransmissionId;

    return xmldata;
  end get_insurance_ALFA;

  function get_insurance_LAA
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(XMLElement("UVG-LAA"
                           , XMLAttributes(HRM_LIB_ELM.to_link(v.InstitutionID) as "institutionID")
                           , XMLElement("InsuranceID", v.reference)
                           , XMLElement("InsuranceCompanyName", v.CompanyName)
                           , XMLElement("CustomerIdentity", v.CustomerNumber)
                           , XMLElement("ContractIdentity", nvl(v.CustomerSubNumber, v.ContractNumber) )
                           , HRM_LIB_ELM.recipient_comment(elm_recipient_comment)
                            )
                 )
      into xmldata
      from v_hrm_elm_insurance v
         , hrm_elm_recipient r
     where v.Insurance in('02', '03')
       and v.InstitutionID = r.hrm_insurance_id
       and r.elm_selected = 1
       and r.hrm_elm_transmission_id = hrm_elm.get_TransmissionId;

    return xmldata;
  end get_insurance_LAA;

  function get_insurances
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLConcat(get_insurance_AVS
                   , get_insurance_LAA
                   , get_insurance_LAAC
                   , get_insurance_IJM
                   , get_insurance_LPP
                   , get_insurance_ALFA
                   , hrm_elm_taxsource_xml.get_taxsource_canton
                    )
      into xmldata
      from dual;

    if xmldata is not null then
      select XMLElement("Institutions", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_insurances;

  function get_company_totals
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLAgg(case c_control_list_type
                    when '102' then get_AVS_company_totals(hrm_control_list_id)
                    when '103' then get_LAA_company_totals(hrm_control_list_id)
                    when '113' then get_LAAC_company_totals(hrm_control_list_id)
                    when '114' then get_IJM_company_totals(hrm_control_list_id)
                    when '112' then get_ALFA_totals_by_canton(hrm_control_list_id)
                    when '111' then hrm_elm_taxsource_xml.get_TaxSource_Totals
                  end
                 )
      into xmldata
      from (select distinct c_control_list_type
                          , l.hrm_control_list_id
                       from hrm_control_list l
                          , hrm_elm_recipient r
                      where l.hrm_control_list_id = r.hrm_control_list_id
                        and r.hrm_elm_transmission_id = hrm_elm.get_TransmissionId
                        and r.elm_selected = 1
                   order by
                            -- Ordre
                            case c_control_list_type
                              when '102' then 1
                              when '103' then 2
                              when '113' then 3
                              when '114' then 4
                              when '112' then 5
                              when '111' then 6
                            end);

    return xmldata;
  end get_company_totals;

  function get_AVS_company_totals(in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select   XMLElement("AHV-AVS-Totals"
                      , XMLAttributes(HRM_LIB_ELM.to_link(AVS.InsuranceId) as "institutionIDRef")
                      , XMLElement("Total-AHV-AVS-Incomes", HRM_LIB_ELM.format(sum(AVS.SalaryAVSAmount) ) )
                      , XMLElement("Total-AHV-AVS-Open", HRM_LIB_ELM.format(sum(AVS.FreeAVSAmount) ) )
                      , XMLElement("Total-ALV-AC-Incomes", HRM_LIB_ELM.format(sum(AVS.SalaryACAmount) ) )
                      , XMLElement("Total-ALVZ-ACS-Incomes", HRM_LIB_ELM.format(sum(AVS.SalaryAC2Amount) ) )
                      , XMLElement("Total-ALV-AC-Open", HRM_LIB_ELM.format(sum(AVS.FreeACAmount) ) )
                       )
        into xmldata
        from (select InsuranceId
                   , SalaryAVSAmount
                   , FreeAVSAmount
                   , SalaryACAmount
                   , SalaryAC2Amount
                   , FreeACAmount
                from V_HRM_ELM_AVS_SUM
               where ListId = in_list_id
              union all
              select RCP.HRM_INSURANCE_ID as InsuranceId
                   , 0.0 as SalaryAVSAmount
                   , 0.0 as FreeAVSAmount
                   , 0.0 as SalaryACAmount
                   , 0.0 as SalaryAC2Amount
                   , 0.0 as FreeACAmount
                from HRM_LPP_EMP_CALC LPP
                   , HRM_ELM_RECIPIENT RCP
                   , HRM_INSURANCE ISR
                   , HRM_ELM_TRANSMISSION ELM
               where ELM.HRM_ELM_TRANSMISSION_ID = HRM_ELM.get_transmissionid
                 and RCP.HRM_ELM_TRANSMISSION_ID = ELM.HRM_ELM_TRANSMISSION_ID
                 and RCP.HRM_CONTROL_LIST_ID = in_list_id
                 and LPP.HRM_ELM_TRANSMISSION_ID = ELM.HRM_ELM_TRANSMISSION_ID
                 and RCP.ELM_SELECTED = 1
                 and RCP.HRM_INSURANCE_ID = ISR.HRM_INSURANCE_ID
                 and ISR.C_HRM_INSURANCE = '01'
                 and ELM.C_ELM_TRANSMISSION_TYPE = '2'
                 and not exists(select 1
                                  from V_HRM_ELM_AVS_SUM
                                 where EmpId = LPP.HRM_PERSON_ID
                                   and InsuranceID = ISR.HRM_INSURANCE_ID) ) AVS
    group by AVS.InsuranceId;

    return xmldata;
  end get_AVS_company_totals;

  function get_LAA_company_totals(in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select   XMLAgg(XMLElement("UVG-LAA-Totals"
                             , XMLAttributes(HRM_LIB_ELM.to_link(InsuranceId) as "institutionIDRef")
                             , get_LAA_total_by_branch(in_list_id)
                             , XMLElement("UVG-LAA-MasterTotal", HRM_LIB_ELM.format(sum(SalaryLAAAmount) ) )
                             , get_LAA_count_emp_by_gender(in_list_id)
                              )
                   )
        into xmldata
        from v_hrm_elm_laa_sum
       where listid = in_list_id
    group by InsuranceId;

    return xmldata;
  end get_LAA_company_totals;

  function get_LAA_total_by_branch(in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select   XMLAgg(XMLElement("UVG-LAA-BranchTotal"
                             , XMLElement("BranchIdentifier", TOT_LAA.LAA_CODE)
                             , XMLElement("Female-Totals"
                                        , XMLElement("NBU-BU-ANP-AP-Total", HRM_LIB_ELM.format(sum(TOT_LAA.FEMALE_LAA_SOUM) ) )
                                        , XMLElement("BU-AP-Total", HRM_LIB_ELM.format(sum(TOT_LAA.FEMALE_LAA_SOUMAP) ) )
                                         )
                             , XMLElement("Male-Totals"
                                        , XMLElement("NBU-BU-ANP-AP-Total", HRM_LIB_ELM.format(sum(TOT_LAA.MALE_LAA_SOUM) ) )
                                        , XMLElement("BU-AP-Total", HRM_LIB_ELM.format(sum(TOT_LAA.MALE_LAA_SOUMAP) ) )
                                         )
                              )
                   )
        into xmldata
        from (select SUM_LAA.LAA_CODE
                   , case
                       when SUM_LAA.LAA_VALUE in('1', '2') then SUM_LAA.MALE_LAA
                     end MALE_LAA_SOUM
                   , case
                       when SUM_LAA.LAA_VALUE in('1', '2') then SUM_LAA.FEMALE_LAA
                     end FEMALE_LAA_SOUM
                   , case
                       when SUM_LAA.LAA_VALUE = '3' then SUM_LAA.MALE_LAA
                     end MALE_LAA_SOUMAP
                   , case
                       when SUM_LAA.LAA_VALUE = '3' then SUM_LAA.FEMALE_LAA
                     end FEMALE_LAA_SOUMAP
                from (select   substr(CODE, 1, 1) LAA_CODE
                             , substr(CODE, -1) LAA_VALUE
                             , sum(MALE_SALARYAMOUNT) MALE_LAA
                             , sum(FEMALE_SALARYAMOUNT) FEMALE_LAA
                          from (select CODE
                                     , case
                                         when (select PER_GENDER
                                                 from HRM_PERSON
                                                where HRM_PERSON_ID = empid) = 'M' then SALARYLAAAMOUNT
                                       end MALE_SALARYAMOUNT
                                     , case
                                         when (select PER_GENDER
                                                 from HRM_PERSON
                                                where HRM_PERSON_ID = empid) = 'F' then SALARYLAAAMOUNT
                                       end FEMALE_SALARYAMOUNT
                                  from V_HRM_ELM_LAA_SUM
                                 where LISTID = in_list_id)
                         where substr(CODE, -1) != '0'
                           and code != '0'
                      group by CODE) SUM_LAA) TOT_LAA
    group by TOT_LAA.LAA_CODE;

    if xmldata is not null then
      select XMLElement("UVG-LAA-BranchTotals", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_LAA_total_by_branch;

  function get_LAA_count_emp_by_gender(in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata      xmltype;
    ld_reference date;
  begin
    ld_reference  := to_date('3009' || to_char(hrm_prc_rep_list.getYear), 'DDMMYYYY');

    select XMLConcat(XMLElement("NumberOfFemalePersons", nvl(sum(counter.Female), 0) ), XMLElement("NumberOfMalePersons", nvl(sum(counter.Male), 0) ) )
      into xmldata
      from (select   case
                       when per_gender = 'F' then 1
                     end Female
                   , case
                       when per_gender = 'M' then 1
                     end Male
                from hrm_person
               where hrm_person_id in(select hrm_employee_id
                                        from (select substr(hisval, -1) code
                                                   , hrm_employee_id
                                                from hrm_tmp_rep_period
                                               where hrm_control_list_id = in_list_id
                                                 and ld_reference between ino_in and ino_out)
                                       where substr(code, -1) != '0'
                                         and code != 'N/A')
            group by per_gender
                   , hrm_person_id) counter;

    return xmldata;
  end get_LAA_count_emp_by_gender;

  function get_LAAC_company_totals(in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select   XMLAgg(XMLElement("UVGZ-LAAC-Totals"
                             , XMLAttributes(HRM_LIB_ELM.to_link(InsuranceId) as "institutionIDRef")
                             , get_LAAC_categories_by_gender(in_list_id)
                             , XMLElement("UVGZ-LAAC-MasterTotal", HRM_LIB_ELM.format(sum(SalaryLAAAmount) ) )
                              )
                   )
        into xmldata
        from v_hrm_elm_laac_sum
       where listid = in_list_id
         and substr(code, -1) != '0'
         and code != 'N/A'
    group by InsuranceId;

    return xmldata;
  end get_LAAC_company_totals;

  function get_LAAC_categories_by_gender(in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select   XMLAgg(XMLElement("UVGZ-LAAC-CategoryTotal"
                             , XMLElement("CategoryCode", code)
                             , XMLElement("Female-Total", HRM_LIB_ELM.format(sum(Female) ) )
                             , XMLElement("Male-Total", HRM_LIB_ELM.format(sum(Male) ) )
                              ) order by code
                   )
        into xmldata
        from (select code
                   , case
                       when per_gender = 'F' then Salary
                     end Female
                   , case
                       when per_gender = 'M' then Salary
                     end Male
                from (select   p.per_gender
                             , v.code code
                             , sum(v.SalaryLAAAmount) Salary
                          from (select code
                                     , empid
                                     , SalaryLAAAmount
                                  from v_hrm_elm_LAAC_sum
                                 where listid = in_list_id
                                   and substr(code, -1) != '0'
                                   and code != 'N/A') v
                             , hrm_person p
                         where p.hrm_person_id = v.empid
                      group by p.per_gender
                             , v.code) ) counter
    group by code;

    if (xmldata is not null) then
      select XMLElement("UVGZ-LAAC-CategoryTotals", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_LAAC_categories_by_gender;

  function get_IJM_company_totals(in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select   XMLAgg(XMLElement("KTG-AMC-Totals"
                             , XMLAttributes(HRM_LIB_ELM.to_link(InsuranceId) as "institutionIDRef")
                             , get_IJM_categories_by_gender(in_list_id)
                             , XMLElement("KTG-AMC-MasterTotal", HRM_LIB_ELM.format(sum(SalaryAMCAmount) ) )
                              )
                   )
        into xmldata
        from v_hrm_elm_ijm_sum
       where listid = in_list_id
         and SalaryAMCAmount != 0.0
    group by InsuranceId;

    return xmldata;
  end get_IJM_company_totals;

  function get_IJM_categories_by_gender(in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select   XMLAgg(XMLElement("KTG-AMC-CategoryTotal"
                             , XMLElement("CategoryCode", code)
                             , XMLElement("Female-Total", HRM_LIB_ELM.format(sum(Female) ) )
                             , XMLElement("Male-Total", HRM_LIB_ELM.format(sum(Male) ) )
                              ) order by code
                   )
        into xmldata
        from (select code
                   , case
                       when per_gender = 'F' then Salary
                     end Female
                   , case
                       when per_gender = 'M' then Salary
                     end Male
                from (select   p.per_gender
                             , v.code code
                             , sum(v.SalaryAMCAmount) Salary
                          from (select code
                                     , empid
                                     , SalaryAMCAmount
                                  from v_hrm_elm_IJM_sum
                                 where listid = in_list_id
                                   and SalaryAMCAmount != 0.0) v
                             , hrm_person p
                         where p.hrm_person_id = v.empid
                           and substr(code, -1) != '0'
                           and code != 'N/A'
                      group by p.per_gender
                             , v.code) ) counter
    group by code;

    if (xmldata is not null) then
      select XMLElement("KTG-AMC-CategoryTotals", xmldata)
        into xmldata
        from dual;
    end if;

    return xmldata;
  end get_IJM_categories_by_gender;

  function get_ALFA_totals_by_canton(in_list_id in hrm_control_list.hrm_control_list_id%type)
    return xmltype
  is
    xmldata   xmltype;
    xmlcanton xmltype;
  begin
    select   XMLAgg(XMLElement("Total-FAK-CAF-PerCanton"
                             , XMLElement("Total-FAK-CAF-ContributorySalary", HRM_LIB_ELM.format(sum(SalaryCAFAmount) ) )
                             , case
                                 when(nvl(sum(ALLOCAMOUNT), 0.0) > 0.0) then XMLElement("Total-FAK-CAF-FamilyIncomeSupplement"
                                                                                      , HRM_LIB_ELM.format(sum(ALLOCAMOUNT) )
                                                                                       )
                               end
                             , XMLElement("Canton", CANTON_WORK)
                              )
                   )
        into xmlcanton
        from v_hrm_elm_alfa_sum alfa_sum_canton
       where listid = in_list_id
         and canton_work in(select nvl(i.dic_canton_work_id, canton_work)
                              from hrm_elm_recipient r
                                 , hrm_insurance i
                             where i.hrm_insurance_id = r.hrm_insurance_id
                               and r.hrm_elm_transmission_id = hrm_elm.get_transmissionId
                               and r.elm_selected = 1)
    group by CANTON_WORK;

    select XMLElement("FAK-CAF-Totals", XMLAttributes(HRM_LIB_ELM.to_link(hrm_insurance_id) as "institutionIDRef"), xmlcanton)
      into xmldata
      from hrm_insurance
     where hrm_control_list_id = in_list_id;

    return xmldata;
  end get_ALFA_totals_by_canton;

  function get_salary_counters
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement("SalaryCounters"
                    , case
                        when(gn_sal_counter_AVS != 0) then XMLElement("NumberOf-AHV-AVS-Salary-Tags", gn_sal_counter_AVS)
                      end
                    , case
                        when(gn_sal_counter_LAA != 0) then XMLElement("NumberOf-UVG-LAA-Salary-Tags", gn_sal_counter_LAA)
                      end
                    , case
                        when(gn_sal_counter_LAAC != 0) then XMLElement("NumberOf-UVGZ-LAAC-Salary-Tags", gn_sal_counter_LAAC)
                      end
                    , case
                        when(gn_sal_counter_IJM != 0) then XMLElement("NumberOf-KTG-AMC-Salary-Tags", gn_sal_counter_IJM)
                      end
                    , case
                        when(gn_sal_counter_LPP != 0) then XMLElement("NumberOf-BVG-LPP-Salary-Tags", gn_sal_counter_LPP)
                      end
                    , case
                        when(gn_sal_counter_ALFA != 0) then XMLElement("NumberOf-FAK-CAF-Salary-Tags", gn_sal_counter_ALFA)
                      end
                    , case
                        when(gn_sal_counter_Tax_Annuity != 0) then XMLElement("NumberOf-TaxAnnuity-Tags", gn_sal_counter_Tax_Annuity)
                      end
                    , case
                        when(gn_sal_counter_Tax_Salary != 0) then XMLElement("NumberOf-TaxSalary-Tags", gn_sal_counter_Tax_Salary)
                      end
                    , case
                        when(gn_sal_counter_OFS != 0) then XMLElement("NumberOf-StatisticSalary-Tags", gn_sal_counter_OFS)
                      end
                    , case
                        when(gn_sal_counter_TAXSource != 0) then XMLElement("NumberOf-TaxAtSourceSalary-Tags", gn_sal_counter_TAXSource)
                      end
                     )
      into xmldata
      from dual;

    return xmldata;
  end get_salary_counters;

  function get_insurances_node_name(iv_insurance_node_name in varchar2)
    return varchar2
  is
  begin
    return case iv_insurance_node_name
      when 'TaxAtSource' then iv_insurance_node_name || 'Identification'
      when 'Statistic' then iv_insurance_node_name || 'Identification'
      else iv_insurance_node_name || '-Identification'
    end;
  end get_insurances_node_name;

  function get_insurance_domain
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement("Domain"
                    , XMLAttributes(gv_xmlns_container as "xmlns", gv_xmlns_declaration as "xmlns:ns2")
                    , XMLElement(evalname(get_insurances_node_name(hrm_elm.get_InsuranceNodeName) )
                               , XMLElement("ns2:Key", hrm_elm.get_InsuranceKey)
                               ,
                                 --<translation>Clé</translation>
                                 XMLElement("ns2:Password", hrm_elm.get_InsurancePwd)
                               ,
                                 --<translation>Mot de passe</translation>
                                 case hrm_elm.get_InsuranceNodeName
                                   when 'Statistic' then null
                                   when 'TaxAtSource' then (select XMLElement("ns2:Institution"
                                                                            , XMLElement("ns2:CantonID", c_hrm_canton)
                                                                            , XMLElement("ns2:CustomerIdentity", tax_payer_no)
                                                                            , case
                                                                                when TAX_ENTITY is not null then XMLElement("PayrollUnit", TAX_ENTITY)
                                                                              end
                                                                             )
                                                              from hrm_taxsource_definition V
                                                             where v.hrm_taxsource_definition_id = hrm_elm.get_InsuranceId)
                                   when 'AHV-AVS' then (select XMLElement("ns2:Institution"
                                                                        , XMLElement("ns2:AK-CC-BranchNumber", reference)
                                                                        , XMLElement("ns2:AK-CC-CustomerNumber", CustomerNumber)
                                                                        , XMLForest(CustomerSubNumber as "ns2:AK-CC-SubNumber")
                                                                         )
                                                          from V_HRM_ELM_INSURANCE
                                                         where InstitutionID = hrm_elm.get_InsuranceId)
                                   when 'FAK-CAF' then (select XMLElement("ns2:Institution"
                                                                        , XMLElement("ns2:FAK-CAF-BranchNumber", reference)
                                                                        , XMLElement("ns2:FAK-CAF-CustomerNumber", CustomerNumber)
                                                                        , XMLForest(CustomerSubNumber as "ns2:FAK-CAF-SubNumber")
                                                                         )
                                                          from V_HRM_ELM_INSURANCE
                                                         where InstitutionID = hrm_elm.get_InsuranceId)
                                   else (select XMLElement("ns2:Institution"
                                                         , XMLElement("ns2:InsuranceID", reference)
                                                         , XMLElement("ns2:InsuranceCompanyName", CompanyName)
                                                         , XMLForest(CustomerNumber as "ns2:CustomerIdentity")
                                                         , XMLElement("ns2:ContractIdentity", nvl(ContractNumber, CustomerSubNumber) )
                                                          )
                                           from V_HRM_ELM_INSURANCE
                                          where InstitutionID = hrm_elm.get_InsuranceId)
                                 end
                                )
                     )
      into xmldata
      from dual;

    return xmldata;
  end get_insurance_domain;
end HRM_ELM_XML;
