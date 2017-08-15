--------------------------------------------------------
--  DDL for Package Body ACR_LIB_EDO_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_LIB_EDO_XML" 
is
  gtActiveProfil ACR_EDO%rowtype;

  /**
  * Description  Initialisation interne
  **/
  procedure InitIternals(iAcrEdoId in ACR_EDO.ACR_EDO_ID%type)
  is
  begin
    select *
      into gtActiveProfil
      from ACR_EDO
     where ACR_EDO_ID = iAcrEdoId;
  end InitIternals;

  /**
  * Description Retour des données complètes d'exportation
  **/
  function GetEdoFin(iAcrEdoId in ACR_EDO.ACR_EDO_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    InitIternals(iAcrEdoId);

    select XMLElement("jahresrechnung"
                    , XMLAttributes('http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi"
                                  , 'http://www.bfs.admin.ch/xmlns/finstat/rechnung/1/rechnung_1_6.xsd' as "xsi:noNamespaceSchemaLocation"
                                   )
                    , ACR_LIB_EDO_XML.GetInfo
                    , ACR_LIB_EDO_XML.GetRechnungTeile
                     )
      into lxmldata
      from dual;

    return lxmldata;
  end GetEdoFin;

  function GetEdoFinXML(iAcrEdoId in ACR_EDO.ACR_EDO_ID%type)
    return clob
  is
    lxmldata xmltype;
  begin
    InitIternals(iAcrEdoId);
    lxmldata  := ACR_LIB_EDO_XML.GETEDOFIN(iAcrEdoId);

    if lxmldata is not null then
      return pc_jutils.get_XmlPrologDefault || chr(10) || lxmldata.GetClobVal();
    else
      return null;
    end if;
  end GetEdoFinXML;

  /**
  * Description Retour des données informatives statiques du profil
  **/
  function GetInfo
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("info", ACR_LIB_EDO_XML.GetMunicipality, ACR_LIB_EDO_XML.GetContact, ACR_LIB_EDO_XML.GetSoftware)
      into lxmldata
      from dual;

    return lxmldata;
  end GetInfo;

  /**
  * Description Retour des données liées aux écritures
  **/
  function GetRechnungTeile
    return xmltype
  is
    lxmldata   xmltype;
    lv_picture ACS_PICTURE.PIC_PICTURE%type;
  begin
    select nvl(max(length(PIC.PIC_PICTURE) ), 0)
      into lv_picture
      from ACS_ACCOUNT_CATEG CAT
         , ACS_PICTURE PIC
     where CAT.ACS_PICTURE_ID = PIC.ACS_PICTURE_ID
       and CAT.C_BALANCE_SHEET_PROFIT_LOSS = 'B';

    /*
    Si lv_picture = 7, on est dans le contexte MCH1
      Alors utilisation des vues originales V_ACR_EDO_WO, V_ACR_EDO_IN et V_ACR_EDO_BS
    Si lv_picture = 8, on est dans le contexte MCH2
        Alors utilisation des nouvelles vues V_ACR_EDO_WO_MCH2, V_ACR_EDO_IN_MCH2 et V_ACR_EDO_BS_MCH2
    Si vl_picture < 7 or vl_picture > 8
        On ne devrait rien faire, car on ne se trouve pas un contexte comptable communal :
    */
    if     (lv_picture = 7)
       and (gtActiveProfil.C_EDO_ACCOUNTING_MODEL = '10') then
      -- Model 20 (MCH2) n'a pas de sens avec un contexte MCH1
      select XMLConcat(ACR_LIB_EDO_XML.GetAccountWO, ACR_LIB_EDO_XML.GetAccountIN, ACR_LIB_EDO_XML.GetAccountBS)
        into lxmldata
        from dual;
    elsif(lv_picture = 8) then
      --Contexte MCH2 mais modèle MCH1 --> Utilsiations des synonymes
      if (gtActiveProfil.C_EDO_ACCOUNTING_MODEL = '10') then
        select XMLConcat(ACR_LIB_EDO_XML.GetAccountWO_Alt, ACR_LIB_EDO_XML.GetAccountIN_Alt, ACR_LIB_EDO_XML.GetAccountBS_Alt)
          into lxmldata
          from dual;
      elsif(gtActiveProfil.C_EDO_ACCOUNTING_MODEL = '20') then
        --Contexte MCH2 et modèle MCH2 --> Utilisation vues sur le groupe de dictionnaires 2
        select XMLConcat(ACR_LIB_EDO_XML.GetAccountWO_MCH2, ACR_LIB_EDO_XML.GetAccountIN_MCH2, ACR_LIB_EDO_XML.GetAccountBS_MCH2)
          into lxmldata
          from dual;
      end if;
    end if;

    return lxmldata;
  end GetRechnungTeile;

  /**
  * Description Retour des informations communales du profil
  **/
  function GetMunicipality
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("gemeinde"
                    , XMLElement("gemeindeNummer", gtActiveProfil.EDO_MUNICIPALITY_NUMBER)
                    , XMLElement("gemeindeName", gtActiveProfil.EDO_MUNICIPALITY_NAME)
                    , XMLElement("rechnungsJahr", (select FYE_NO_EXERCICE
                                                     from ACS_FINANCIAL_YEAR
                                                    where ACS_FINANCIAL_YEAR_ID = gtActiveProfil.ACS_FINANCIAL_YEAR_ID) )
                    , XMLElement("rechnungsPeriode", '00')
                    , XMLElement("haushaltsGruppeID", gtActiveProfil.C_EDO_CANTON)
                    , XMLElement("lieferTypID", gtActiveProfil.C_EDO_ACCOUNTING_MODEL)
                    , XMLElement("kommentar", gtActiveProfil.EDO_COMMENT)
                     )
      into lxmldata
      from dual;

    return lxmldata;
  end GetMunicipality;

  /**
  * Description Retour des informations du contact du profil
  **/
  function GetContact
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("kontaktPerson"
                    , XMLElement("anrede", case
                                   when gtActiveProfil.C_EDO_CONTACT_TITLE = '0' then 'Frau'
                                   else 'Herr'
                                 end)
                    , XMLElement("sprache", (select LANID
                                               from PCS.PC_LANG
                                              where PC_LANG_ID = gtActiveProfil.PC_LANG_ID) )
                    , XMLElement("nachname", gtActiveProfil.EDO_CONTACT_NAME)
                    , XMLElement("vorname", gtActiveProfil.EDO_CONTACT_FORENAME)
                    , XMLElement("verwaltungsName", gtActiveProfil.EDO_CONTACT_AUTHORITIES)
                    , XMLElement("funktion", gtActiveProfil.EDO_CONTACT_POSITION)
                    , XMLElement("strasse", gtActiveProfil.EDO_CONTACT_STREET)
                    , XMLElement("plz", gtActiveProfil.EDO_CONTACT_ZIPCODE)
                    , XMLElement("ort", gtActiveProfil.EDO_CONTACT_CITY)
                    , XMLElement("telefon", gtActiveProfil.EDO_CONTACT_TEL)
                    , XMLElement("email", gtActiveProfil.EDO_CONTACT_EMAIL)
                     )
      into lxmldata
      from dual;

    return lxmldata;
  end GetContact;

  /**
  * Description Retour des informations du système informatique
  **/
  function GetSoftware
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("software"
                    , XMLElement("softwareHersteller", 'SolvAxis')
                    , XMLElement("softwareName", 'ProConcept ERP')
                    , XMLForest(PCS.PC_ERP_VERSION.PATCHSET as "softwareVersion")
                     )
      into lxmldata
      from dual;

    return lxmldata;
  end GetSoftware;

  /**
  * Description Retour des comptes financiers de la vue selon leur nature
  **/
  function GetAccountWO
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("teilrechnung"
            , XMLElement("teilrechnungName", 'Laufende Rechnung')
            , XMLAgg
                (case
                   when(V.ACS_FINANCIAL_ACCOUNT_ID < 0) then case
                                                              when(CountAccountChilds(V.ACS_FINANCIAL_ACCOUNT_ID, V.ACC_NUMBER, 0, 'V_ACR_EDO_WO') > 0) then XMLElement
                                                                                                                                                              ("konto"
                                                                                                                                                             , XMLElement
                                                                                                                                                                 ("kontoNummer"
                                                                                                                                                                , V.ACC_NUMBER
                                                                                                                                                                 )
                                                                                                                                                             , XMLElement
                                                                                                                                                                 ("kontoBezeichnung"
                                                                                                                                                                , ACR_LIB_EDO_XML.GetParentDescription
                                                                                                                                                                    (V.DICO_PARENT
                                                                                                                                                                   , v.ACC_NUMBER
                                                                                                                                                                    )
                                                                                                                                                                 )
                                                                                                                                                             , XMLElement
                                                                                                                                                                 ("kontoParent"
                                                                                                                                                                , V.ACC_PARENT
                                                                                                                                                                 )
                                                                                                                                                              )
                                                            end
                   when(V.ACS_FINANCIAL_ACCOUNT_ID > 0)
                   and (V.ACC_NATURE is not null) then XMLElement("konto"
                                                                , XMLElement("kontoNummer", V.ACC_NUMBER)
                                                                , XMLElement("kontoBezeichnung", V.ACC_DESCRIPTION)
                                                                , XMLElement("kontoParent", V.ACC_PARENT)
                                                                , GetDetailsBalance(V.ACS_FINANCIAL_ACCOUNT_ID
                                                                                  , V.MANAGEMENT_NUMBER
                                                                                  , V.MANAGEMENT_COMPLEMENT
                                                                                  , V.ACC_NATURE
                                                                                  , V.ACC_TASK
                                                                                  , substr(V.MANAGEMENT_NUMBER, 1, 3)
                                                                                  , 'WO'
                                                                                   )
                                                                 )
                 end
                )
             )
      into lxmldata
      from V_ACR_EDO_WO V
     where (V.ACS_FINANCIAL_ACCOUNT_ID < 0)
        or (     (V.ACS_FINANCIAL_ACCOUNT_ID > 0)
            and (        (gtActiveProfil.EDO_PREVIOUS_YEAR_DATAS = 1)
                    and (length(GetVRVBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_CURRENT_YEAR_DATAS = 1)
                    and (length(GetVRBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_BUDGET_DATAS = 1)
                    and (length(GetVABalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                )
           );

    return lxmldata;
  end GetAccountWO;

  /**
  * Description Retour des comptes financiers de la vue selon leur nature
  **/
  function GetAccountWO_Alt
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("teilrechnung"
            , XMLElement("teilrechnungName", 'Laufende Rechnung')
            , XMLAgg
                (case
                   when(V.ACS_FINANCIAL_ACCOUNT_ID < 0) then case
                                                              when(CountAccountChilds(V.ACS_FINANCIAL_ACCOUNT_ID, V.ACC_NUMBER, 0, 'V_ACR_EDO_WO_ALT') > 0) then XMLElement
                                                                                                                                                                  ("konto"
                                                                                                                                                                 , XMLElement
                                                                                                                                                                     ("kontoNummer"
                                                                                                                                                                    , V.ACC_NUMBER
                                                                                                                                                                     )
                                                                                                                                                                 , XMLElement
                                                                                                                                                                     ("kontoBezeichnung"
                                                                                                                                                                    , ACR_LIB_EDO_XML.GetParentDescription
                                                                                                                                                                        (V.DICO_PARENT
                                                                                                                                                                       , v.ACC_NUMBER
                                                                                                                                                                        )
                                                                                                                                                                     )
                                                                                                                                                                 , XMLElement
                                                                                                                                                                     ("kontoParent"
                                                                                                                                                                    , V.ACC_PARENT
                                                                                                                                                                     )
                                                                                                                                                                  )
                                                            end
                   when(V.ACS_FINANCIAL_ACCOUNT_ID > 0)
                   and (V.ACC_NATURE is not null) then XMLElement("konto"
                                                                , XMLElement("kontoNummer", V.ACC_NUMBER)
                                                                , XMLElement("kontoBezeichnung", V.ACC_DESCRIPTION)
                                                                , XMLElement("kontoParent", V.ACC_PARENT)
                                                                , GetDetailsBalance(V.ACS_FINANCIAL_ACCOUNT_ID
                                                                                  , V.MANAGEMENT_NUMBER
                                                                                  , V.MANAGEMENT_COMPLEMENT
                                                                                  , V.ACC_NATURE
                                                                                  , V.ACC_TASK
                                                                                  , substr(V.MANAGEMENT_NUMBER, 1, 3)
                                                                                  , 'WO'
                                                                                   )
                                                                 )
                 end
                )
             )
      into lxmldata
      from V_ACR_EDO_WO_ALT V
     where (V.ACS_FINANCIAL_ACCOUNT_ID < 0)
        or (     (V.ACS_FINANCIAL_ACCOUNT_ID > 0)
            and (        (gtActiveProfil.EDO_PREVIOUS_YEAR_DATAS = 1)
                    and (length(GetVRVBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_CURRENT_YEAR_DATAS = 1)
                    and (length(GetVRBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_BUDGET_DATAS = 1)
                    and (length(GetVABalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                )
           );

    return lxmldata;
  end GetAccountWO_Alt;

  /**
  * Description Retour des comptes financiers de la vue selon leur nature
  **/
  function GetAccountWO_MCH2
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("teilrechnung"
            , XMLElement("teilrechnungName", 'Laufende Rechnung')
            , XMLAgg
                (case
                   when(V.ACS_FINANCIAL_ACCOUNT_ID < 0) then case
                                                              when(CountAccountChilds(V.ACS_FINANCIAL_ACCOUNT_ID, V.ACC_NUMBER, 0, 'V_ACR_EDO_WO_MCH2') > 0) then XMLElement
                                                                                                                                                                   ("konto"
                                                                                                                                                                  , XMLElement
                                                                                                                                                                      ("kontoNummer"
                                                                                                                                                                     , V.ACC_NUMBER
                                                                                                                                                                      )
                                                                                                                                                                  , XMLElement
                                                                                                                                                                      ("kontoBezeichnung"
                                                                                                                                                                     , ACR_LIB_EDO_XML.GetParentDescription
                                                                                                                                                                         (V.DICO_PARENT
                                                                                                                                                                        , v.ACC_NUMBER
                                                                                                                                                                         )
                                                                                                                                                                      )
                                                                                                                                                                  , XMLElement
                                                                                                                                                                      ("kontoParent"
                                                                                                                                                                     , V.ACC_PARENT
                                                                                                                                                                      )
                                                                                                                                                                   )
                                                            end
                   when(V.ACS_FINANCIAL_ACCOUNT_ID > 0)
                   and (V.ACC_NATURE is not null) then XMLElement("konto"
                                                                , XMLElement("kontoNummer", V.ACC_NUMBER)
                                                                , XMLElement("kontoBezeichnung", V.ACC_DESCRIPTION)
                                                                , XMLElement("kontoParent", V.ACC_PARENT)
                                                                , GetDetailsBalance(V.ACS_FINANCIAL_ACCOUNT_ID
                                                                                  , V.MANAGEMENT_NUMBER
                                                                                  , V.MANAGEMENT_COMPLEMENT
                                                                                  , V.ACC_NATURE
                                                                                  , V.ACC_TASK
                                                                                  , substr(V.MANAGEMENT_NUMBER, 1, 4)
                                                                                  , 'WO'
                                                                                   )
                                                                 )
                 end
                )
             )
      into lxmldata
      from V_ACR_EDO_WO_MCH2 V
     where (V.ACS_FINANCIAL_ACCOUNT_ID < 0)
        or (     (V.ACS_FINANCIAL_ACCOUNT_ID > 0)
            and (        (gtActiveProfil.EDO_PREVIOUS_YEAR_DATAS = 1)
                    and (length(GetVRVBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_CURRENT_YEAR_DATAS = 1)
                    and (length(GetVRBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_BUDGET_DATAS = 1)
                    and (length(GetVABalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                )
           );

    return lxmldata;
  end GetAccountWO_MCH2;

  function GetAccountIN
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("teilrechnung"
            , XMLElement("teilrechnungName", 'Investitionsrechnung')
            , XMLAgg
                (case
                   when(V.ACS_FINANCIAL_ACCOUNT_ID < 0) then case
                                                              when(CountAccountChilds(V.ACS_FINANCIAL_ACCOUNT_ID, V.ACC_NUMBER, 0, 'V_ACR_EDO_IN') > 0) then XMLElement
                                                                                                                                                              ("konto"
                                                                                                                                                             , XMLElement
                                                                                                                                                                 ("kontoNummer"
                                                                                                                                                                , V.ACC_NUMBER
                                                                                                                                                                 )
                                                                                                                                                             , XMLElement
                                                                                                                                                                 ("kontoBezeichnung"
                                                                                                                                                                , ACR_LIB_EDO_XML.GetParentDescription
                                                                                                                                                                    (V.DICO_PARENT
                                                                                                                                                                   , v.ACC_NUMBER
                                                                                                                                                                    )
                                                                                                                                                                 )
                                                                                                                                                             , XMLElement
                                                                                                                                                                 ("kontoParent"
                                                                                                                                                                , V.ACC_PARENT
                                                                                                                                                                 )
                                                                                                                                                              )
                                                            end
                   when(V.ACS_FINANCIAL_ACCOUNT_ID > 0)
                   and (V.ACC_NATURE is not null) then XMLElement("konto"
                                                                , XMLElement("kontoNummer", V.ACC_NUMBER)
                                                                , XMLElement("kontoBezeichnung", V.ACC_DESCRIPTION)
                                                                , XMLElement("kontoParent", V.ACC_PARENT)
                                                                , GetDetailsBalance(V.ACS_FINANCIAL_ACCOUNT_ID
                                                                                  , V.MANAGEMENT_NUMBER
                                                                                  , V.MANAGEMENT_COMPLEMENT
                                                                                  , V.ACC_NATURE
                                                                                  , V.ACC_TASK
                                                                                  , substr(V.MANAGEMENT_NUMBER, 1, 3)
                                                                                  , 'IN'
                                                                                   )
                                                                 )
                 end
                )
             )
      into lxmldata
      from V_ACR_EDO_IN V
     where (V.ACS_FINANCIAL_ACCOUNT_ID < 0)
        or (     (V.ACS_FINANCIAL_ACCOUNT_ID > 0)
            and (        (gtActiveProfil.EDO_PREVIOUS_YEAR_DATAS = 1)
                    and (length(GetVRVBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_CURRENT_YEAR_DATAS = 1)
                    and (length(GetVRBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_BUDGET_DATAS = 1)
                    and (length(GetVABalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                )
           );

    return lxmldata;
  end GetAccountIN;

  function GetAccountIN_Alt
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("teilrechnung"
            , XMLElement("teilrechnungName", 'Investitionsrechnung')
            , XMLAgg
                (case
                   when(V.ACS_FINANCIAL_ACCOUNT_ID < 0) then case
                                                              when(CountAccountChilds(V.ACS_FINANCIAL_ACCOUNT_ID, V.ACC_NUMBER, 0, 'V_ACR_EDO_IN_Alt') > 0) then XMLElement
                                                                                                                                                                  ("konto"
                                                                                                                                                                 , XMLElement
                                                                                                                                                                     ("kontoNummer"
                                                                                                                                                                    , V.ACC_NUMBER
                                                                                                                                                                     )
                                                                                                                                                                 , XMLElement
                                                                                                                                                                     ("kontoBezeichnung"
                                                                                                                                                                    , ACR_LIB_EDO_XML.GetParentDescription
                                                                                                                                                                        (V.DICO_PARENT
                                                                                                                                                                       , v.ACC_NUMBER
                                                                                                                                                                        )
                                                                                                                                                                     )
                                                                                                                                                                 , XMLElement
                                                                                                                                                                     ("kontoParent"
                                                                                                                                                                    , V.ACC_PARENT
                                                                                                                                                                     )
                                                                                                                                                                  )
                                                            end
                   when(V.ACS_FINANCIAL_ACCOUNT_ID > 0)
                   and (V.ACC_NATURE is not null) then XMLElement("konto"
                                                                , XMLElement("kontoNummer", V.ACC_NUMBER)
                                                                , XMLElement("kontoBezeichnung", V.ACC_DESCRIPTION)
                                                                , XMLElement("kontoParent", V.ACC_PARENT)
                                                                , GetDetailsBalance(V.ACS_FINANCIAL_ACCOUNT_ID
                                                                                  , V.MANAGEMENT_NUMBER
                                                                                  , V.MANAGEMENT_COMPLEMENT
                                                                                  , V.ACC_NATURE
                                                                                  , V.ACC_TASK
                                                                                  , substr(V.MANAGEMENT_NUMBER, 1, 3)
                                                                                  , 'IN'
                                                                                   )
                                                                 )
                 end
                )
             )
      into lxmldata
      from V_ACR_EDO_IN_Alt V
     where (V.ACS_FINANCIAL_ACCOUNT_ID < 0)
        or (     (V.ACS_FINANCIAL_ACCOUNT_ID > 0)
            and (        (gtActiveProfil.EDO_PREVIOUS_YEAR_DATAS = 1)
                    and (length(GetVRVBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_CURRENT_YEAR_DATAS = 1)
                    and (length(GetVRBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_BUDGET_DATAS = 1)
                    and (length(GetVABalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                )
           );

    return lxmldata;
  end GetAccountIN_Alt;

  function GetAccountIN_MCH2
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("teilrechnung"
            , XMLElement("teilrechnungName", 'Investitionsrechnung')
            , XMLAgg
                (case
                   when(V.ACS_FINANCIAL_ACCOUNT_ID < 0) then case
                                                              when(CountAccountChilds(V.ACS_FINANCIAL_ACCOUNT_ID, V.ACC_NUMBER, 0, 'V_ACR_EDO_IN_MCH2') > 0) then XMLElement
                                                                                                                                                                   ("konto"
                                                                                                                                                                  , XMLElement
                                                                                                                                                                      ("kontoNummer"
                                                                                                                                                                     , V.ACC_NUMBER
                                                                                                                                                                      )
                                                                                                                                                                  , XMLElement
                                                                                                                                                                      ("kontoBezeichnung"
                                                                                                                                                                     , ACR_LIB_EDO_XML.GetParentDescription
                                                                                                                                                                         (V.DICO_PARENT
                                                                                                                                                                        , v.ACC_NUMBER
                                                                                                                                                                         )
                                                                                                                                                                      )
                                                                                                                                                                  , XMLElement
                                                                                                                                                                      ("kontoParent"
                                                                                                                                                                     , V.ACC_PARENT
                                                                                                                                                                      )
                                                                                                                                                                   )
                                                            end
                   when(V.ACS_FINANCIAL_ACCOUNT_ID > 0)
                   and (V.ACC_NATURE is not null) then XMLElement("konto"
                                                                , XMLElement("kontoNummer", V.ACC_NUMBER)
                                                                , XMLElement("kontoBezeichnung", V.ACC_DESCRIPTION)
                                                                , XMLElement("kontoParent", V.ACC_PARENT)
                                                                , GetDetailsBalance(V.ACS_FINANCIAL_ACCOUNT_ID
                                                                                  , V.MANAGEMENT_NUMBER
                                                                                  , V.MANAGEMENT_COMPLEMENT
                                                                                  , V.ACC_NATURE
                                                                                  , V.ACC_TASK
                                                                                  , substr(V.MANAGEMENT_NUMBER, 1, 4)
                                                                                  , 'IN'
                                                                                   )
                                                                 )
                 end
                )
             )
      into lxmldata
      from V_ACR_EDO_IN_MCH2 V
     where (V.ACS_FINANCIAL_ACCOUNT_ID < 0)
        or (     (V.ACS_FINANCIAL_ACCOUNT_ID > 0)
            and (        (gtActiveProfil.EDO_PREVIOUS_YEAR_DATAS = 1)
                    and (length(GetVRVBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_CURRENT_YEAR_DATAS = 1)
                    and (length(GetVRBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_BUDGET_DATAS = 1)
                    and (length(GetVABalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                )
           );

    return lxmldata;
  end GetAccountIN_MCH2;

  function GetAccountBS
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("teilrechnung"
            , XMLElement("teilrechnungName", 'Bestandesrechnung')
            , XMLAgg
                (case
                   when(V.ACS_FINANCIAL_ACCOUNT_ID < 0) then case
                                                              when(CountAccountChilds(V.ACS_FINANCIAL_ACCOUNT_ID, V.ACC_NUMBER, 0, 'V_ACR_EDO_BS') > 0) then XMLElement
                                                                                                                                                              ("konto"
                                                                                                                                                             , XMLElement
                                                                                                                                                                 ("kontoNummer"
                                                                                                                                                                , V.ACC_NUMBER
                                                                                                                                                                 )
                                                                                                                                                             , XMLElement
                                                                                                                                                                 ("kontoBezeichnung"
                                                                                                                                                                , ACR_LIB_EDO_XML.GetParentDescription
                                                                                                                                                                    (V.DICO_PARENT
                                                                                                                                                                   , v.ACC_NUMBER
                                                                                                                                                                    )
                                                                                                                                                                 )
                                                                                                                                                             , XMLElement
                                                                                                                                                                 ("kontoParent"
                                                                                                                                                                , V.ACC_PARENT
                                                                                                                                                                 )
                                                                                                                                                              )
                                                            end
                   when(V.ACS_FINANCIAL_ACCOUNT_ID > 0)
                   and (V.ACC_NATURE is not null) then XMLElement("konto"
                                                                , XMLElement("kontoNummer", V.ACC_NUMBER)
                                                                , XMLElement("kontoBezeichnung", V.ACC_DESCRIPTION)
                                                                , XMLElement("kontoParent", V.ACC_PARENT)
                                                                , GetDetailsBalance(V.ACS_FINANCIAL_ACCOUNT_ID
                                                                                  , V.MANAGEMENT_NUMBER
                                                                                  , V.MANAGEMENT_COMPLEMENT
                                                                                  , V.ACC_NATURE
                                                                                  , V.ACC_TASK
                                                                                  , ''
                                                                                  , 'BS'
                                                                                   )
                                                                 )
                 end
                )
             )
      into lxmldata
      from V_ACR_EDO_BS V
     where (V.ACS_FINANCIAL_ACCOUNT_ID < 0)
        or (     (V.ACS_FINANCIAL_ACCOUNT_ID > 0)
            and (        (gtActiveProfil.EDO_PREVIOUS_YEAR_DATAS = 1)
                    and (length(GetVRVBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_CURRENT_YEAR_DATAS = 1)
                    and (length(GetVRBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_BUDGET_DATAS = 1)
                    and (length(GetVABalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                )
           );

    return lxmldata;
  end GetAccountBS;

  function GetAccountBS_Alt
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("teilrechnung"
            , XMLElement("teilrechnungName", 'Bestandesrechnung')
            , XMLAgg
                (case
                   when(V.ACS_FINANCIAL_ACCOUNT_ID < 0) then case
                                                              when(CountAccountChilds(V.ACS_FINANCIAL_ACCOUNT_ID, V.ACC_NUMBER, 0, 'V_ACR_EDO_BS_Alt') > 0) then XMLElement
                                                                                                                                                                  ("konto"
                                                                                                                                                                 , XMLElement
                                                                                                                                                                     ("kontoNummer"
                                                                                                                                                                    , V.ACC_NUMBER
                                                                                                                                                                     )
                                                                                                                                                                 , XMLElement
                                                                                                                                                                     ("kontoBezeichnung"
                                                                                                                                                                    , ACR_LIB_EDO_XML.GetParentDescription
                                                                                                                                                                        (V.DICO_PARENT
                                                                                                                                                                       , v.ACC_NUMBER
                                                                                                                                                                        )
                                                                                                                                                                     )
                                                                                                                                                                 , XMLElement
                                                                                                                                                                     ("kontoParent"
                                                                                                                                                                    , V.ACC_PARENT
                                                                                                                                                                     )
                                                                                                                                                                  )
                                                            end
                   when(V.ACS_FINANCIAL_ACCOUNT_ID > 0)
                   and (V.ACC_NATURE is not null) then XMLElement("konto"
                                                                , XMLElement("kontoNummer", V.ACC_NUMBER)
                                                                , XMLElement("kontoBezeichnung", V.ACC_DESCRIPTION)
                                                                , XMLElement("kontoParent", V.ACC_PARENT)
                                                                , GetDetailsBalance(V.ACS_FINANCIAL_ACCOUNT_ID
                                                                                  , V.MANAGEMENT_NUMBER
                                                                                  , V.MANAGEMENT_COMPLEMENT
                                                                                  , V.ACC_NATURE
                                                                                  , V.ACC_TASK
                                                                                  , ''
                                                                                  , 'BS'
                                                                                   )
                                                                 )
                 end
                )
             )
      into lxmldata
      from V_ACR_EDO_BS_Alt V
     where (V.ACS_FINANCIAL_ACCOUNT_ID < 0)
        or (     (V.ACS_FINANCIAL_ACCOUNT_ID > 0)
            and (        (gtActiveProfil.EDO_PREVIOUS_YEAR_DATAS = 1)
                    and (length(GetVRVBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_CURRENT_YEAR_DATAS = 1)
                    and (length(GetVRBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_BUDGET_DATAS = 1)
                    and (length(GetVABalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                )
           );

    return lxmldata;
  end GetAccountBS_Alt;

  function GetAccountBS_MCH2
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("teilrechnung"
            , XMLElement("teilrechnungName", 'Bestandesrechnung')
            , XMLAgg
                (case
                   when(V.ACS_FINANCIAL_ACCOUNT_ID < 0) then case
                                                              when(CountAccountChilds(V.ACS_FINANCIAL_ACCOUNT_ID, V.ACC_NUMBER, 0, 'V_ACR_EDO_BS_MCH2') > 0) then XMLElement
                                                                                                                                                                   ("konto"
                                                                                                                                                                  , XMLElement
                                                                                                                                                                      ("kontoNummer"
                                                                                                                                                                     , V.ACC_NUMBER
                                                                                                                                                                      )
                                                                                                                                                                  , XMLElement
                                                                                                                                                                      ("kontoBezeichnung"
                                                                                                                                                                     , ACR_LIB_EDO_XML.GetParentDescription
                                                                                                                                                                         (V.DICO_PARENT
                                                                                                                                                                        , v.ACC_NUMBER
                                                                                                                                                                         )
                                                                                                                                                                      )
                                                                                                                                                                  , XMLElement
                                                                                                                                                                      ("kontoParent"
                                                                                                                                                                     , V.ACC_PARENT
                                                                                                                                                                      )
                                                                                                                                                                   )
                                                            end
                   when(V.ACS_FINANCIAL_ACCOUNT_ID > 0)
                   and (V.ACC_NATURE is not null) then XMLElement("konto"
                                                                , XMLElement("kontoNummer", V.ACC_NUMBER)
                                                                , XMLElement("kontoBezeichnung", V.ACC_DESCRIPTION)
                                                                , XMLElement("kontoParent", V.ACC_PARENT)
                                                                , GetDetailsBalance(V.ACS_FINANCIAL_ACCOUNT_ID
                                                                                  , V.MANAGEMENT_NUMBER
                                                                                  , V.MANAGEMENT_COMPLEMENT
                                                                                  , V.ACC_NATURE
                                                                                  , V.ACC_TASK
                                                                                  , ''
                                                                                  , 'BS'
                                                                                   )
                                                                 )
                 end
                )
             )
      into lxmldata
      from V_ACR_EDO_BS_MCH2 V
     where (V.ACS_FINANCIAL_ACCOUNT_ID < 0)
        or (     (V.ACS_FINANCIAL_ACCOUNT_ID > 0)
            and (        (gtActiveProfil.EDO_PREVIOUS_YEAR_DATAS = 1)
                    and (length(GetVRVBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_CURRENT_YEAR_DATAS = 1)
                    and (length(GetVRBalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                 or     (gtActiveProfil.EDO_BUDGET_DATAS = 1)
                    and (length(GetVABalance(V.ACS_FINANCIAL_ACCOUNT_ID) ) > 0)
                )
           );

    return lxmldata;
  end GetAccountBS_MCH2;

  function GetParentDescription(iAccountDicName in V_ACR_EDO_BS.DICO_PARENT%type, iAccountDicValue in V_ACR_EDO_BS.ACC_PARENT%type)
    return DIC_FIN_ACC_CODE_1.DIC_DESCRIPTION%type
  is
    lDynStmt        varchar2(200);
    lDicDiscription DIC_FIN_ACC_CODE_1.DIC_DESCRIPTION%type;
  begin
    lDynStmt  := 'select DIC_DESCRIPTION from ' || iAccountDicName || ' where ' || iAccountDicName || '_id = :iAccountDicValue';

    execute immediate lDynStmt
                 into lDicDiscription
                using iAccountDicValue;

    return lDicDiscription;
  end GetParentDescription;

  /**
  * Description Retour du solde VA ( budgetisé) du compte donné
  **/
  function GetVABalance(iAcsFinancialAccountId in V_ACR_EDO_BS.ACS_FINANCIAL_ACCOUNT_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("saldo"
                    , XMLElement("erhebungsArt", 'VA')
                    , XMLElement("sollBetrag", nvl(sum(GLO.GLO_AMOUNT_D), 0) )
                    , XMLElement("habenBetrag", nvl(sum(GLO.GLO_AMOUNT_C), 0) )
                     )
      into lxmldata
      from ACB_BUDGET BUD
         , ACB_BUDGET_VERSION VER
         , ACB_GLOBAL_BUDGET GLO
     where VER.VER_DEFAULT = 1
       and VER.ACB_BUDGET_VERSION_ID = GLO.ACB_BUDGET_VERSION_ID
       and BUD.ACB_BUDGET_ID = VER.ACB_BUDGET_ID
       and BUD.ACS_FINANCIAL_YEAR_ID = gtActiveProfil.ACS_FINANCIAL_YEAR_ID
       and GLO.ACS_FINANCIAL_ACCOUNT_ID = iAcsFinancialAccountId
    having (nvl(sum(GLO.GLO_AMOUNT_D), 0) <> 0)
        or (nvl(sum(GLO.GLO_AMOUNT_C), 0) <> 0);

    return lxmldata;
  end GetVABalance;

  /**
  * Description Retour du solde VR (Exercice du profil actif)
  **/
  function GetVRBalance(iAcsFinancialAccountId in V_ACR_EDO_BS.ACS_FINANCIAL_ACCOUNT_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("saldo"
                    , XMLElement("erhebungsArt", 'VR')
                    , XMLElement("sollBetrag", nvl(sum(TOT.TOT_DEBIT_LC), 0) )
                    , XMLElement("habenBetrag", nvl(sum(TOT.TOT_CREDIT_LC), 0) )
                     )
      into lxmldata
      from ACT_TOTAL_BY_PERIOD TOT
         , ACS_PERIOD PER
     where PER.ACS_FINANCIAL_YEAR_ID = gtActiveProfil.ACS_FINANCIAL_YEAR_ID
       and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and TOT.ACS_DIVISION_ACCOUNT_ID is null
       and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
       and TOT.ACS_FINANCIAL_ACCOUNT_ID = iAcsFinancialAccountId
       and TOT.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
       and TOT.C_TYPE_CUMUL = 'EXT'
    having (nvl(sum(TOT.TOT_DEBIT_LC), 0) <> 0.0)
        or (nvl(sum(TOT.TOT_CREDIT_LC), 0) <> 0.0);

    return lxmldata;
  end GetVRBalance;

  /**
  * Description Retour du solde VRV (Exercice précedent l'exercice du profil actif)
  **/
  function GetVRVBalance(iAcsFinancialAccountId in V_ACR_EDO_BS.ACS_FINANCIAL_ACCOUNT_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("saldo"
                    , XMLElement("erhebungsArt", 'VRV')
                    , XMLElement("sollBetrag", nvl(sum(TOT.TOT_DEBIT_LC), 0) )
                    , XMLElement("habenBetrag", nvl(sum(TOT.TOT_CREDIT_LC), 0) )
                     )
      into lxmldata
      from ACT_TOTAL_BY_PERIOD TOT
         , ACS_PERIOD PER
         , ACS_FINANCIAL_YEAR CYE
         , ACS_FINANCIAL_YEAR PYE
     where CYE.ACS_FINANCIAL_YEAR_ID = gtActiveProfil.ACS_FINANCIAL_YEAR_ID
       and PYE.FYE_NO_EXERCICE = CYE.FYE_NO_EXERCICE - 1
       and PER.ACS_FINANCIAL_YEAR_ID = PYE.ACS_FINANCIAL_YEAR_ID
       and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and TOT.ACS_DIVISION_ACCOUNT_ID is null
       and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
       and TOT.ACS_FINANCIAL_ACCOUNT_ID = iAcsFinancialAccountId
       and TOT.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
       and TOT.C_TYPE_CUMUL = 'EXT'
    having (nvl(sum(TOT.TOT_DEBIT_LC), 0) <> 0)
        or (nvl(sum(TOT.TOT_CREDIT_LC), 0) <> 0);

    return lxmldata;
  end GetVRVBalance;

  /**
  * Description Retour des écritures composant le solde
  **/
  function GetDetailsBalance(
    iAcsFinancialAccountId in V_ACR_EDO_BS.ACS_FINANCIAL_ACCOUNT_ID%type
  , iManagementNumber      in V_ACR_EDO_BS.MANAGEMENT_NUMBER%type
  , iManagementComplement  in V_ACR_EDO_BS.MANAGEMENT_COMPLEMENT%type
  , iNature                in V_ACR_EDO_BS.ACC_NATURE%type
  , iTask                  in V_ACR_EDO_BS.ACC_TASK%type
  , iAppropriateGroup      in V_ACR_EDO_BS.MANAGEMENT_COMPLEMENT%type
  , iAccType               in V_ACR_EDO_BS.ACC_TYPE%type
  )
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("kontoDetails"
                    , XMLElement("BECodeID", gtActiveProfil.C_EDO_ACCOUNTING_TYPE)
                    , XMLElement("kontoArt"
                               , case
                                   when substr(iNature, length(iNature), length(iNature) ) in(1, 3, 5, 9) then 1
                                   when substr(iNature, length(iNature), length(iNature) ) in(2, 4, 6) then 2
                                 end
                                )
                    , XMLElement("verwaltungsEinheit", nvl(iTask, '0') )
                    , case
                        when(iAccType <> 'BS') then XMLElement("urFunktion", substr(iTask,1,3))
                      end
                    , XMLElement("verwaltungsKonto", iManagementNumber)
                    , case
                        when iAccType <> 'BS' then XMLElement("urSachGruppe", iAppropriateGroup)
                      end
                    , case
                        when length(replace(iManagementComplement,'0','')) > 0 then XMLElement("verwaltungsKontoZusatz", iManagementComplement)
                      end
                    , case
                        when gtActiveProfil.EDO_PREVIOUS_YEAR_DATAS = 1 then GetVRVBalance(iAcsFinancialAccountId)
                      end
                    , case
                        when gtActiveProfil.EDO_CURRENT_YEAR_DATAS = 1 then GetVRBalance(iAcsFinancialAccountId)
                      end
                    , case
                        when gtActiveProfil.EDO_BUDGET_DATAS = 1 then GetVABalance(iAcsFinancialAccountId)
                      end
                    , case
                        when(    (     (iAccType = 'WO')
                                  and exists(select 1
                                               from ACR_EDO_WO WO
                                              where WO.EDW_TASK = iTask
                                                and WO.ACR_EDO_ID = gtActiveProfil.ACR_EDO_ID) )
                             or (     (iAccType = 'IN')
                                 and exists(select 1
                                              from ACR_EDO_IN INV
                                             where INV.EDI_TASK = iTask
                                               and INV.ACR_EDO_ID = gtActiveProfil.ACR_EDO_ID) )
                            )
                        and (ImputationCount(iAcsFinancialAccountId) > 0) then GetImputation(iAcsFinancialAccountId)
                      end
                     )
      into lxmldata
      from dual;

    return lxmldata;
  end GetDetailsBalance;

  /**
  * Description Retour du nombre d'écritures / d'imputations du compte
  * @param iAcsFinancialAccountId Id compte ...valeur et signe permet de détecter si parent ou compte gestion
  **/
  function ImputationCount(iAcsFinancialAccountId in V_ACR_EDO_BS.ACS_FINANCIAL_ACCOUNT_ID%type)
    return number
  is
    lCounter number;
  begin
    select count(*)
      into lCounter
      from ACT_FINANCIAL_IMPUTATION IMP
     where IMP.ACS_FINANCIAL_ACCOUNT_ID = iAcsFinancialAccountId
       and IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
       and IMP.IMF_ACS_FINANCIAL_YEAR_ID = gtActiveProfil.ACS_FINANCIAL_YEAR_ID;

    return lCounter;
  end ImputationCount;

  /**
  * Description Retour du nombre de comptes de type donné (WO,IN,BI) et ayant pour parent le compte donné
  **/
  function CountAccountChilds(
    iAcsFinancialAccountId in V_ACR_EDO_WO.ACS_FINANCIAL_ACCOUNT_ID%type
  , iAccNumber             in V_ACR_EDO_WO.ACC_NUMBER%type
  , iPreviousCount            number
  , iViewName                 varchar2
  )
    return number
  is
    type trParentCursor is ref cursor;

    crParentCursor         trParentCursor;
    lAcsFinancialAccountId V_ACR_EDO_WO.ACS_FINANCIAL_ACCOUNT_ID%type;
    lAccNumber             V_ACR_EDO_WO.ACC_NUMBER%type;
    lResult                number;
    lDynStmt               varchar2(200);
  begin
    lResult  := iPreviousCount;

    if iAcsFinancialAccountId < -1 then
      lDynStmt  :=
               'select V.ACS_FINANCIAL_ACCOUNT_ID, V.ACC_NUMBER from ' || iViewName || ' V where V.ACC_PARENT = :iAccNumber and V.ACS_FINANCIAL_ACCOUNT_ID < 0';

      open crParentCursor for lDynStmt using iAccNumber;

      fetch crParentCursor
       into lAcsFinancialAccountId
          , lAccNumber;

      while crParentCursor%found loop
        lResult  := CountAccountChilds(lAcsFinancialAccountId, lAccNumber, lResult, iViewName);

        fetch crParentCursor
         into lAcsFinancialAccountId
            , lAccNumber;
      end loop;
    else
      lDynStmt  := 'select count(*) from ' || iViewName || ' V where ACC_PARENT = :iAccNumber and ACS_FINANCIAL_ACCOUNT_ID > 0';

      execute immediate lDynStmt
                   into lResult
                  using iAccNumber;
    end if;

    return lResult + iPreviousCount;
  end CountAccountChilds;

  /**
  * Description Retour des écritures composant le solde
  **/
  function GetImputation(iAcsFinancialAccountId in V_ACR_EDO_BS.ACS_FINANCIAL_ACCOUNT_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("buchungen"
                    , XMLAgg(XMLElement("buchung"
                                      , XMLElement("belegNummer", IMF_NUMBER)
                                      , XMLElement("belegText", IMF_DESCRIPTION)
                                      , XMLElement("belegDatum", IMF_TRANSACTION_DATE)
                                      , case
                                          when(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C) > 0 then XMLElement("belegSollBetrag"
                                                                                                    , nvl(abs(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 0)
                                                                                                     )
                                          else XMLElement("belegHabenBetrag", nvl(abs(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 0) )
                                        end
                                       )
                            )
                     )
      into lxmldata
      from ACT_FINANCIAL_IMPUTATION IMP
     where IMP.ACS_FINANCIAL_ACCOUNT_ID = iAcsFinancialAccountId
       and IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
       and IMP.IMF_ACS_FINANCIAL_YEAR_ID = gtActiveProfil.ACS_FINANCIAL_YEAR_ID;

    return lxmldata;
  end GetImputation;
end ACR_LIB_EDO_XML;
