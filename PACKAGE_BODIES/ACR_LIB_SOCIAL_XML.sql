--------------------------------------------------------
--  DDL for Package Body ACR_LIB_SOCIAL_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_LIB_SOCIAL_XML" 
is
  gtActiveBreakdown ACR_SOCIAL_BREAKDOWN%rowtype;

  /**
  * Description
  *     Initialisation interne
  **/
  procedure InitIternals(iAcrSocialBreakdownId in ACR_SOCIAL_BREAKDOWN.ACR_SOCIAL_BREAKDOWN_ID%type)
  is
  begin
    select *
      into gtActiveBreakdown
      from ACR_SOCIAL_BREAKDOWN
     where ACR_SOCIAL_BREAKDOWN_ID = iAcrSocialBreakdownId;
  end InitIternals;

  /**
  * Description
  *     Retour des données de l'en-tête du décompte
  **/
  function GetHeaderDatas(iPacPersonId in PAC_PERSON.PAC_PERSON_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLForest( --PER_FILE_NUMBER || gtActiveBreakdown.ASB_MUNICIPALITY_NUMBER as "Id"
                       iPacPersonId || gtActiveBreakdown.ASB_MUNICIPALITY_NUMBER as "Id"
                    , (select FYE_NO_EXERCICE
                       from ACS_FINANCIAL_YEAR
                       where ACS_FINANCIAL_YEAR_ID = gtActiveBreakdown.ACS_FINANCIAL_YEAR_ID) as "Jahr"
                     ,gtActiveBreakdown.ASB_MUNICIPALITY_NUMBER as "AbrechnendeEinheit"
                     ,gtActiveBreakdown.ASB_MUNICIPALITY_AFFILIATED as "AngeschlosseneGemeinde"
                     ,PER_FILE_NUMBER as "DossierNummer"
                    )
    into lxmldata
    from V_PAC_SOC_BREAKDOWN
    where PAC_PERSON_ID = iPacPersonId;

    return lxmldata;
  end GetHeaderDatas;

  /**
  * Description
  *     Retour du montant des imputations concernées pour la personne et valeur
  *     de dico données
  **/
  function GetImputationAmount(iPacPersonId in PAC_PERSON.PAC_PERSON_ID%type,
                               iDicImpFreeId in DIC_IMP_FREE1.DIC_IMP_FREE1_ID%type)
    return varchar2
  is
    lnvResult number;
  begin
    select sum(nvl(IMF_AMOUNT_LC_D,0) - nvl(IMF_AMOUNT_LC_C,0))
    into lnvResult
    from V_ACR_SOC_BREAKDOWN ACR
    where PAC_PERSON_ID = iPacPersonId
      and DIC_IMP_FREE_ID like iDicImpFreeId || '%';

    return to_char(nvl(lnvResult,0), 'FM9999999990.00');
  end GetImputationAmount;

  /**
  * Description
  *     Retour des données de charge et produit du décompte
  **/
  function GetImputationDatas(iPacPersonId in PAC_PERSON.PAC_PERSON_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLForest( ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'C01') as "Grundbedarf"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'C02') as "Wohnkosten"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'C03') as "Gesundheitskosten"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'C04') as "KKPraemien"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'C05') as "Platzierungskosten1"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'C06') as "Platzierungskosten2"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'C07') as "AmbulanteMassnahmen"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'C08') as "UebrigeSIL"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'C09') as "IZU-MIZ"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'C10') as "Einkommensfreibetrag"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P01') as "Erwerbseinkommen"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P02') as "ALV"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P03') as "IV"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P04') as "EinkommenUebrigeSolzialVers"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P05') as "Alimente"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P06') as "Familienzulagen"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P07') as "KKRueckerstattungen"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P08') as "PersRueckerstattungen"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P09') as "ElternVerwandtenUnterst"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P10') as "HeimatlicheVerguetungen"
                     ,ACR_LIB_SOCIAL_XML.GetImputationAmount(iPacPersonId, 'P11') as "UebriegeEinkommen"
                    )
    into lxmldata
    from dual;
    return lxmldata;
  end GetImputationDatas;

  /**
  * Description  Retour des données statistiques
  **/
  function GetStatisticDatas(iPacPersonId in PAC_PERSON.PAC_PERSON_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLForest( nvl(PER_SOC_STAT_1,0) as "PlatzierungenErwachsene"
                     ,nvl(PER_SOC_STAT_2,0) as "PlatzierungenErwachseneVormundschaft"
                     ,nvl(PER_SOC_STAT_3,0) as "PlatzierungenUnter18"
                     ,nvl(PER_SOC_STAT_4,0) as "PlatzierungenUnter18Vormundschaft"
                     ,nvl(PER_SOC_STAT_5,0) as "AnzahlAmbulanteMassnahmen"
                     ,nvl(PER_SOC_STAT_6,0) as "AnzahlDossiers"
                     ,nvl(PER_SOC_STAT_7,0) as "AnzahlUnterstPersonen"
                     ,nvl(PER_SOC_STAT_8,0) as "AnzahlUnterstMonate"
                    )
    into lxmldata
    from V_PAC_SOC_BREAKDOWN
    where PAC_PERSON_ID = iPacPersonId;

    return lxmldata;
  end GetStatisticDatas;

  /**
  * Description  Retour des données de tous les dossiers sociaux
  **/
  function GetAllPersonDatas return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLAgg(XMLElement("DossierDSHR",
                             XMLConcat( ACR_LIB_SOCIAL_XML.GetHeaderDatas(PAC_PERSON_ID)
                                      , ACR_LIB_SOCIAL_XML.GetImputationDatas(PAC_PERSON_ID)
                                      , ACR_LIB_SOCIAL_XML.GetStatisticDatas (PAC_PERSON_ID)
                                      )
                            )
                  )
    into lxmldata
    from V_PAC_SOC_BREAKDOWN;

    return lxmldata;

  end GetAllPersonDatas;

  /**
  * Description  Retour des données complètes d'exportation
  **/
  function GetSocialExportation(iCurrentId in number) return xmltype
  is
    lxmldata xmltype;
  begin
    InitIternals(iCurrentId);

    select XMLElement
             ("DatenimportDSHR"
            , XMLAttributes
                 ('http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi",
                  'urn:DSHR.Datenimport' as "xmlns"
                 )
            , ACR_LIB_SOCIAL_XML.GetAllPersonDatas
             )
      into lxmldata
      from dual;

    return lxmldata;
  end GetSocialExportation;

  /**
  * Description  Retour des données complètes d'exportation
  **/
  function GetSocialXML(iCurrentId in number) return Clob
  is
    lxmldata xmltype;
  begin
    lxmldata  := ACR_LIB_SOCIAL_XML.GetSocialExportation(iCurrentId);

    if lxmldata is not null then
      return pc_jutils.get_XmlPrologDefault || chr(10) || lxmldata.GetClobVal();
    else
      return null;
    end if;
  end GetSocialXML;

      /**
  * Description :
  *   Retourne le document XSD de validation
  */
  function GetXsdSchema return Clob
  is
    vResult ACR_EDO.EDO_XML%type;
  begin
    select XSD_SCHEMA
      into vResult
      from PCS.PC_XSD_SCHEMA
     where XSD_NAME = 'XSD_ACR_SOCIAL_BREAKDOWN';

    return vResult;
  end GetXsdSchema;

end ACR_LIB_SOCIAL_XML;
