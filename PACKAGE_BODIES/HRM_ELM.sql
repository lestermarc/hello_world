--------------------------------------------------------
--  DDL for Package Body HRM_ELM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_ELM" 
/**
 * Package de génération de document pour déclaration Swissdec.
 *
 * Condition préalable d'utilisation:
 * - Oracle 9.2.x
 *
 * @version 1.0
 * @date 01/2005
 * @author spfister
 * @author ireber
 */
as
--
-- Private symbols
--

  -- Définition des informations d'une assurance.
  type t_insurance is record(
    InsuranceId T_INSURANCE_ID
  , key         varchar2(4000)
  , Pwd         varchar2(4000)
  , NodeName    varchar2(4000)
  );

  -- Définition des différentes dates
  type t_period_dates is record(
    Selected          T_PERIOD default 0
  ,   -- Année de sélection
    BeginOfPeriod     date
  , EndOfPeriod       date
  , BeginOfPrevPeriod date
  , EndOfPrevPeriod   date
  );

  -- Définition de la personne de contact de la société.
  type t_contact is record(
    name  varchar2(4000)
  , EMail varchar2(4000)
  , Phone varchar2(4000)
  );

  -- Définition des informations nécessaire pour générer le document
  -- Xml de transmission des données de salaire.
  type t_elm_options is record(
    PeriodDate     T_PERIOD_DATES
  ,   -- Définition des différentes dates
    ModeTest       T_MODE_TEST                                not null default 0
  ,   -- Mode test/réel
    TransmissionId T_TRANSMISSION_ID                          not null default 0
  ,   -- Id de la transmission
    RequestId      T_REQUEST_ID                                        default null
  ,   -- Id de la transmission
    SubstitutionId T_SUBSTITUTION_ID                          not null default 0
  ,   -- Id de la transmission remplacée (substitution)
    Contact        T_CONTACT
  ,   -- Personne de contact de la société
    LangId         T_LANG_ID
  ,   -- Langue utilisée pour la génération du doc XML
    Sorting_Code   t_sorting_code
  ,   -- Code de tri (GetStaff)
    Insurance      T_INSURANCE   -- Informations d'une assurance
  );

  gtt_elm_options T_ELM_OPTIONS;

  cursor gcur_lang(id in number)
  is
    select LANID
      from PCS.PC_LANG
     where PC_LANG_ID = id;

--
-- Private methods
--

  /**
  * Convertion d'un document Xml en texte, avec prologue.
  * @param XmlDoc  Document Xml original.
  * @return Un CLOB contenant le texte du document Xml, ainsi qu'un prologue
  *         complet correspondant à l'encodage de la base.
  */
  function p_XmlToClob(XmlDoc in xmltype)
    return clob
  is
  begin
    if (XmlDoc is not null) then
      return pc_jutils.get_XMLPrologDefault || chr(10) || XmlDoc.getClobVal();
    end if;

    return null;
  end;

--
-- Public methods
--
  procedure ClearSalaryDeclaration
  is
  begin
    set_Period(0, 0);
    gtt_elm_options.LangId                 := nvl(pcs.PC_I_LIB_SESSION.GetUserLangId, pcs.PC_I_LIB_SESSION.GetCompLangId);
    gtt_elm_options.ModeTest               := 0;
    gtt_elm_options.TransmissionId         := 0.0;
    gtt_elm_options.RequestId              := '';
    gtt_elm_options.SubstitutionId         := 0.0;
    gtt_elm_options.Contact.name           := '';
    gtt_elm_options.Contact.EMail          := '';
    gtt_elm_options.Contact.Phone          := '';
    gtt_elm_options.Insurance.InsuranceId  := 0.0;
    gtt_elm_options.Insurance.key          := '';
    gtt_elm_options.Insurance.Pwd          := '';
    gtt_elm_options.Sorting_Code           := '03';
  end;

  function get_Period
    return integer
  is
  begin
    return gtt_elm_options.PeriodDate.Selected;
  end;

  procedure set_Period(iYear in number, iMonth in number)
  is
  begin
    gtt_elm_options.PeriodDate.Selected           := 0;
    gtt_elm_options.PeriodDate.BeginOfPeriod      := null;
    gtt_elm_options.PeriodDate.EndOfPeriod        := null;
    gtt_elm_options.PeriodDate.BeginOfPrevPeriod  := null;
    gtt_elm_options.PeriodDate.EndOfPrevPeriod    := null;

    if (    iYear is not null
        and iYear > 0) then
      if (length(iYear) != 4) then
        raise_application_error(-20000, 'Period must have 4 digit');
      end if;

      gtt_elm_options.PeriodDate.Selected  := iYear;

      if iMonth = 0 then
        gtt_elm_options.PeriodDate.BeginOfPeriod      := to_date('0101' || to_char(iYear), 'DDMMYYYY');
        gtt_elm_options.PeriodDate.EndOfPeriod        := to_date('3112' || to_char(iYear), 'DDMMYYYY');
        gtt_elm_options.PeriodDate.BeginOfPrevPeriod  := to_date('0101' || to_char(iYear - 1), 'DDMMYYYY');
        gtt_elm_options.PeriodDate.EndOfPrevPeriod    := to_date('3112' || to_char(iYear - 1), 'DDMMYYYY');
      else
        gtt_elm_options.PeriodDate.BeginOfPeriod      := to_date('01' || lpad(to_char(iMonth), 2, 0) || to_char(iYear), 'DDMMYYYY');
        gtt_elm_options.PeriodDate.EndOfPeriod        := last_day(gtt_elm_options.PeriodDate.BeginOfPeriod);
        gtt_elm_options.PeriodDate.BeginOfPrevPeriod  := add_months(gtt_elm_options.PeriodDate.BeginOfPeriod, -1);
        gtt_elm_options.PeriodDate.EndOfPrevPeriod    := last_day(gtt_elm_options.PeriodDate.BeginOfPrevPeriod);
      end if;
    end if;
  end set_Period;

  function get_ModeTest
    return integer
  is
  begin
    return gtt_elm_options.ModeTest;
  end;

  procedure set_ModeTest(in_mode_test in T_MODE_TEST)
  is
  begin
    gtt_elm_options.ModeTest  := in_mode_test;
  end;

  function get_TransmissionId
    return number
  is
  begin
    return gtt_elm_options.TransmissionId;
  end;

  procedure set_TransmissionId(in_transmission_id in T_TRANSMISSION_ID)
  is
  begin
    gtt_elm_options.TransmissionId  := in_transmission_id;
  end;

  function get_TransmissionType
    return hrm_elm_transmission.c_elm_transmission_type%type
  is
    lv_result hrm_elm_transmission.c_elm_transmission_type%type;
  begin

    select c_elm_transmission_type
      into lv_result
      from hrm_elm_transmission
     where hrm_elm_transmission_id = get_transmissionid;

    return lv_result;
  end;

  function get_RequestId
    return varchar2
  is
  begin
    return gtt_elm_options.RequestId;
  end;

  procedure set_RequestId(iv_request_id in T_REQUEST_ID)
  is
  begin
    gtt_elm_options.RequestId  := iv_request_id;
  end;

  function get_SubstitutionId
    return number
  is
  begin
    return gtt_elm_options.SubstitutionId;
  end;

  procedure set_SubstitutionId(in_substitution_id in T_SUBSTITUTION_ID)
  is
  begin
    gtt_elm_options.SubstitutionId  := in_substitution_id;
  end;

  function BeginOfPeriod
    return date
  is
  begin
    return gtt_elm_options.PeriodDate.BeginOfPeriod;
  end;

  function EndOfPeriod
    return date
  is
  begin
    return gtt_elm_options.PeriodDate.EndOfPeriod;
  end;

  function BeginOfPrevPeriod
    return date
  is
  begin
    return gtt_elm_options.PeriodDate.BeginOfPrevPeriod;
  end;

  function EndOfPrevPeriod
    return date
  is
  begin
    return gtt_elm_options.PeriodDate.EndOfPrevPeriod;
  end;

  function get_ContactName
    return varchar2
  is
  begin
    return gtt_elm_options.Contact.name;
  end;

  procedure set_ContactName(iv_contact_name in T_CONTACT_NAME)
  is
  begin
    gtt_elm_options.Contact.name  := iv_contact_name;
  end;

  function get_ContactEMail
    return varchar2
  is
  begin
    return gtt_elm_options.Contact.EMail;
  end;

  procedure set_ContactEMail(iv_contact_mail in T_CONTACT_MAIL)
  is
  begin
    gtt_elm_options.Contact.EMail  := iv_contact_mail;
  end;

  function get_ContactPhone
    return varchar2
  is
  begin
    return gtt_elm_options.Contact.Phone;
  end;

  procedure set_ContactPhone(iv_contact_phone in T_CONTACT_PHONE)
  is
  begin
    gtt_elm_options.Contact.Phone  := iv_contact_phone;
  end;

  function get_Sorting_Code
    return varchar2
  is
  begin
    return gtt_elm_options.Sorting_Code;
  end;

  procedure set_Sorting_Code(iv_Sorting_Code in t_sorting_code)
  is
  begin
    gtt_elm_options.Sorting_Code  := iv_Sorting_Code;
  end;

  function get_langId
    return number
  is
  begin
    return gtt_elm_options.LangId;
  end;

  function get_InsuranceId
    return number
  is
  begin
    return gtt_elm_options.Insurance.InsuranceId;
  end;

  procedure set_InsuranceId(in_insurance_id in T_INSURANCE_ID)
  is
  begin
    gtt_elm_options.Insurance.InsuranceId  := in_insurance_id;
  end;

  function get_InsuranceKey
    return varchar2
  is
  begin
    return gtt_elm_options.Insurance.key;
  end;

  procedure set_InsuranceKey(iv_insurance_key in varchar2)
  is
  begin
    gtt_elm_options.Insurance.key  := iv_insurance_key;
  end;

  function get_InsurancePwd
    return varchar2
  is
  begin
    return gtt_elm_options.Insurance.Pwd;
  end;

  procedure set_InsurancePwd(iv_insurance_pwd in varchar2)
  is
  begin
    gtt_elm_options.Insurance.Pwd  := iv_insurance_pwd;
  end;

  function get_InsuranceNodeName
    return varchar2
  is
  begin
    return gtt_elm_options.Insurance.NodeName;
  end;

  procedure set_InsuranceNodeName(iv_insurance_node_name in varchar2)
  is
  begin
    gtt_elm_options.Insurance.NodeName  := iv_insurance_node_name;
  end;

  procedure DeclareSalary(
    in_year            in            number
  , in_month           in            number
  , in_mode_test       in            T_MODE_TEST
  , in_transmission_id in            T_TRANSMISSION_ID
  , iv_request_id      in            T_REQUEST_ID
  , in_substitution_id in            T_SUBSTITUTION_ID
  , iv_contact_name    in            T_CONTACT_NAME
  , iv_contact_mail    in            T_CONTACT_MAIL
  , iv_contact_phone   in            T_CONTACT_PHONE
  , iv_sorting_code    in            T_SORTING_CODE
  , oc_document        out nocopy    clob
  )
  is
    xmldata xmltype;
  begin
    hrm_elm.DeclareSalary(in_year
                        , in_month
                        , in_mode_test
                        , in_transmission_id
                        , iv_request_id
                        , in_substitution_id
                        , iv_contact_name
                        , iv_contact_mail
                        , iv_contact_phone
                        , iv_sorting_code
                        , xmldata
                         );
    oc_document  := p_XmlToClob(xmldata);
  end;

  procedure DeclareSalary(oc_document out nocopy clob)
  is
    xmldata xmltype;
  begin
    hrm_elm.DeclareSalary(xmldata);
    oc_document  := p_XmlToClob(xmldata);
  end;

  procedure DeclareSalary(
    in_year            in            number
  , in_month           in            number
  , in_mode_test       in            T_MODE_TEST
  , in_transmission_id in            T_TRANSMISSION_ID
  , iv_request_id      in            T_REQUEST_ID
  , in_substitution_id in            T_SUBSTITUTION_ID
  , iv_contact_name    in            T_CONTACT_NAME
  , iv_contact_mail    in            T_CONTACT_MAIL
  , iv_contact_phone   in            T_CONTACT_PHONE
  , iv_sorting_code    in            T_SORTING_CODE
  , ox_document        out nocopy    xmltype
  )
  is
  begin
    hrm_elm.ClearSalaryDeclaration;
    hrm_elm.set_Period(in_year, in_month);
    hrm_elm.set_ModeTest(in_mode_test);
    hrm_elm.set_TransmissionId(in_transmission_id);
    hrm_elm.set_RequestId(nvl(iv_request_id, hrm_lib_elm.get_NewRequestId) );
    hrm_elm.set_SubstitutionId(in_substitution_id);
    hrm_elm.set_ContactName(iv_contact_name);
    hrm_elm.set_ContactEMail(iv_contact_mail);
    hrm_elm.set_ContactPhone(iv_contact_phone);
    hrm_elm.set_Sorting_Code(iv_sorting_code);
    hrm_elm.DeclareSalary(ox_document);
  end;

  procedure DeclareSalary(ox_document out nocopy xmltype)
  is
  begin
    hrm_elm_xml.getSalaryDeclarationRequest(ox_document);

    select XMLElement
             ("DeclareSalary"
            , XMLAttributes('http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes' as "xmlns"
                          , 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' as "xmlns:sd"
                          , 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' as "xmlns:ct"
                          , 'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi"
                          , 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes SalaryDeclarationServiceTypes.xsd' as "xsi:schemaLocation"
                           )
            , extract(ox_document, '/*/*')
             )
      into ox_document
      from dual;
  end;

  procedure DeclareSalaryDeferred(
    in_year            in            number
  , in_month           in            number
  , in_mode_test       in            T_MODE_TEST
  , in_transmission_id in            T_TRANSMISSION_ID
  , iv_request_id      in            T_REQUEST_ID
  , in_substitution_id in            T_SUBSTITUTION_ID
  , iv_contact_name    in            T_CONTACT_NAME
  , iv_contact_mail    in            T_CONTACT_MAIL
  , iv_contact_phone   in            T_CONTACT_PHONE
  , iv_sorting_code    in            T_SORTING_CODE
  , oc_document        out nocopy    clob
  )
  is
  begin
    HRM_ELM.DeclareSalary(in_year              => in_year
                        , in_month             => in_month
                        , in_mode_test         => in_mode_test
                        , in_transmission_id   => in_transmission_id
                        , iv_request_id        => iv_request_id
                        , in_substitution_id   => in_substitution_id
                        , iv_contact_name      => iv_contact_name
                        , iv_contact_mail      => iv_contact_mail
                        , iv_contact_phone     => iv_contact_phone
                        , iv_sorting_code      => iv_sorting_code
                        , oc_document          => oc_document
                         );
  end DeclareSalaryDeferred;

  procedure SynchronizeContract(
    in_year            in            number
  , in_month           in            number
  , in_mode_test       in            T_MODE_TEST
  , in_transmission_id in            T_TRANSMISSION_ID
  , iv_request_id      in            T_REQUEST_ID
  , in_substitution_id in            T_SUBSTITUTION_ID
  , iv_contact_name    in            T_CONTACT_NAME
  , iv_contact_mail    in            T_CONTACT_MAIL
  , iv_contact_phone   in            T_CONTACT_PHONE
  , iv_sorting_code    in            T_SORTING_CODE
  , oc_document        out nocopy    clob
  )
  is
    xmldata xmltype;
  begin
    hrm_elm.SynchronizeContract(in_year
                              , in_month
                              , in_mode_test
                              , in_transmission_id
                              , iv_request_id
                              , in_substitution_id
                              , iv_contact_name
                              , iv_contact_mail
                              , iv_contact_phone
                              , iv_sorting_code
                              , xmldata
                               );
    oc_document  := p_XmlToClob(xmldata);
  end;

  procedure SynchronizeContract(oc_document out nocopy clob)
  is
    xmldata xmltype;
  begin
    hrm_elm.SynchronizeContract(xmldata);
    oc_document  := p_XmlToClob(xmldata);
  end;

  procedure SynchronizeContract(
    in_year            in            number
  , in_month           in            number
  , in_mode_test       in            T_MODE_TEST
  , in_transmission_id in            T_TRANSMISSION_ID
  , iv_request_id      in            T_REQUEST_ID
  , in_substitution_id in            T_SUBSTITUTION_ID
  , iv_contact_name    in            T_CONTACT_NAME
  , iv_contact_mail    in            T_CONTACT_MAIL
  , iv_contact_phone   in            T_CONTACT_PHONE
  , iv_sorting_code    in            T_SORTING_CODE
  , ox_document        out nocopy    xmltype
  )
  is
  begin
    hrm_elm.ClearSalaryDeclaration;
    hrm_elm.set_Period(in_year, in_month);
    hrm_elm.set_ModeTest(in_mode_test);
    hrm_elm.set_TransmissionId(in_transmission_id);
    hrm_elm.set_RequestId(nvl(iv_request_id, hrm_lib_elm.get_NewRequestId) );
    hrm_elm.set_SubstitutionId(in_substitution_id);
    hrm_elm.set_ContactName(iv_contact_name);
    hrm_elm.set_ContactEMail(iv_contact_mail);
    hrm_elm.set_ContactPhone(iv_contact_phone);
    hrm_elm.set_Sorting_Code(iv_sorting_code);
    hrm_elm.SynchronizeContract(ox_document);
  end;

  procedure SynchronizeContract(ox_document out nocopy xmltype)
  is
  begin
    hrm_elm_xml.getSalaryDeclarationRequest(ox_document);

    select XMLElement
             ("SynchronizeContract"
            , XMLAttributes('http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes' as "xmlns"
                          , 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' as "xmlns:sd"
                          , 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' as "xmlns:ct"
                          , 'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi"
                          , 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes SalaryDeclarationServiceTypes.xsd' as "xsi:schemaLocation"
                           )
            , extract(ox_document, '/*/*')
             )
      into ox_document
      from dual;
  end;

  procedure SynchronizeContractDeferred(
    in_year            in            number
  , in_month           in            number
  , in_mode_test       in            T_MODE_TEST
  , in_transmission_id in            T_TRANSMISSION_ID
  , iv_request_id      in            T_REQUEST_ID
  , in_substitution_id in            T_SUBSTITUTION_ID
  , iv_contact_name    in            T_CONTACT_NAME
  , iv_contact_mail    in            T_CONTACT_MAIL
  , iv_contact_phone   in            T_CONTACT_PHONE
  , iv_sorting_code    in            T_SORTING_CODE
  , oc_document        out nocopy    clob
  )
  is
    xmldata xmltype;
  begin
    hrm_elm.SynchronizeContractDeferred(in_year
                                      , in_month
                                      , in_mode_test
                                      , in_transmission_id
                                      , iv_request_id
                                      , in_substitution_id
                                      , iv_contact_name
                                      , iv_contact_mail
                                      , iv_contact_phone
                                      , iv_sorting_code
                                      , xmldata
                                       );
    oc_document  := p_XmlToClob(xmldata);
  end;

  procedure SynchronizeContractDeferred(oc_document out nocopy clob)
  is
    xmldata xmltype;
  begin
    hrm_elm.SynchronizeContractDeferred(xmldata);
    oc_document  := p_XmlToClob(xmldata);
  end;

  procedure SynchronizeContractDeferred(
    in_year            in            number
  , in_month           in            number
  , in_mode_test       in            T_MODE_TEST
  , in_transmission_id in            T_TRANSMISSION_ID
  , iv_request_id      in            T_REQUEST_ID
  , in_substitution_id in            T_SUBSTITUTION_ID
  , iv_contact_name    in            T_CONTACT_NAME
  , iv_contact_mail    in            T_CONTACT_MAIL
  , iv_contact_phone   in            T_CONTACT_PHONE
  , iv_sorting_code    in            T_SORTING_CODE
  , ox_document        out nocopy    xmltype
  )
  is
  begin
    hrm_elm.ClearSalaryDeclaration;
    hrm_elm.set_Period(in_year, in_month);
    hrm_elm.set_ModeTest(in_mode_test);
    hrm_elm.set_TransmissionId(in_transmission_id);
    hrm_elm.set_RequestId(nvl(iv_request_id, hrm_lib_elm.get_NewRequestId) );
    hrm_elm.set_SubstitutionId(in_substitution_id);
    hrm_elm.set_ContactName(iv_contact_name);
    hrm_elm.set_ContactEMail(iv_contact_mail);
    hrm_elm.set_ContactPhone(iv_contact_phone);
    hrm_elm.set_Sorting_Code(iv_sorting_code);
    hrm_elm.SynchronizeContract(ox_document);
  end;

  procedure SynchronizeContractDeferred(ox_document out nocopy xmltype)
  is
  begin
    hrm_elm_xml.getSalaryDeclarationRequest(ox_document);

    select XMLElement
             ("SynchronizeContractDeferred"
            , XMLAttributes('http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes' as "xmlns"
                          , 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' as "xmlns:sd"
                          , 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' as "xmlns:ct"
                          , 'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi"
                          , 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes SalaryDeclarationServiceTypes.xsd' as "xsi:schemaLocation"
                           )
            , extract(ox_document, '/*/*')
             )
      into ox_document
      from dual;
  end;

  procedure SynchronizeFromDeclareSalary(
    in_insurance_id        in            T_INSURANCE_ID
  , in_mode_test           in            T_MODE_TEST
  , iv_request_id          in            T_REQUEST_ID
  , iv_insurance_key       in            varchar2
  , iv_insurance_pwd       in            varchar2
  , iv_insurance_node_name in            varchar2
  , in_synchronize_mode    in            integer
  , oc_document            out nocopy    clob
  )
  is
    xmldata xmltype;
  begin
    hrm_elm.SynchronizeFromDeclareSalary(in_insurance_id
                                       , in_mode_test
                                       , iv_request_id
                                       , iv_insurance_key
                                       , iv_insurance_pwd
                                       , iv_insurance_node_name
                                       , in_synchronize_mode
                                       , xmldata
                                        );
    oc_document  := p_XmlToClob(xmldata);
  end;

  procedure SynchronizeFromDeclareSalary(in_synchronize_mode in integer, oc_document out nocopy clob)
  is
    xmldata xmltype;
  begin
    hrm_elm.SynchronizeFromDeclareSalary(in_synchronize_mode, xmldata);
    oc_document  := p_XmlToClob(xmldata);
  end;

  procedure SynchronizeFromDeclareSalary(
    in_insurance_id        in            T_INSURANCE_ID
  , in_mode_test           in            T_MODE_TEST
  , iv_request_id          in            T_REQUEST_ID
  , iv_insurance_key       in            varchar2
  , iv_insurance_pwd       in            varchar2
  , iv_insurance_node_name in            varchar2
  , in_synchronize_mode    in            integer
  , ox_document            out nocopy    xmltype
  )
  is
  begin
    hrm_elm.ClearSalaryDeclaration;
    hrm_elm.set_InsuranceId(in_insurance_id);
    hrm_elm.set_ModeTest(in_mode_test);
    hrm_elm.set_RequestId(nvl(iv_request_id, hrm_lib_elm.get_NewRequestId) );
    hrm_elm.set_InsuranceKey(iv_insurance_key);
    hrm_elm.set_InsurancePwd(iv_insurance_pwd);
    hrm_elm.set_InsuranceNodeName(iv_insurance_node_name);
    hrm_elm.SynchronizeFromDeclareSalary(in_synchronize_mode, ox_document);
  end;

  procedure SynchronizeFromDeclareSalary(in_synchronize_mode in integer, ox_document out nocopy xmltype)
  is
  begin
    if in_synchronize_mode = 1 then
      hrm_elm_xml.getResultFromSyncContract(ox_document);
    else
      hrm_elm_xml.getResultFromDeclareSalary(ox_document);
    end if;
  end;
end HRM_ELM;
