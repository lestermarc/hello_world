--------------------------------------------------------
--  DDL for Package Body HRM_GE_TAXSOURCE_DECLARATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_GE_TAXSOURCE_DECLARATION" 
IS

  gv_DPI VARCHAR2(32767);
  gv_date_from DATE;
  gv_date_to DATE;
  gn_list_id hrm_control_list.hrm_control_list_id%TYPE;


--
-- Internal implementation
--

/**
 * Initialisation des variables privées.
 */
procedure p_InitInternals(
  pDPI IN VARCHAR2,
  pDateFrom IN DATE,
  pDateTo IN DATE,
  pListId IN hrm_control_list.hrm_control_list_id%TYPE)
is
begin
  gv_DPI := pDPI;
  gv_date_from := pDateFrom;
  gv_date_to := pDateTo;
  gn_list_id := pListId;
end;


/**
 * Convertion d'un document Xml en texte, avec prologue.
 * @param XmlDoc  Document Xml original.
 * @return Un CLob contenant le texte du document Xml, ainsi qu'un prologue
 *         complet correspondant à l'encodage de la base.
 */
function p_XmlToClob(
  XmlDoc IN XMLType)
  return CLob
is
begin
  if (XmlDoc is not null) then
    return pc_jutils.get_XMLPrologDefault ||Chr(10)|| XmlDoc.getClobVal();
  end if;
  return null;
end;


--
-- Public implementation
--

function decode_ge_taxpayer(
  data IN hrm_person.c_hrm_ge_taxpayer%TYPE)
  return VARCHAR2
is
begin
  return case data
    -- seul LR1 est implémanté (codes c_hrm_ge_taxpayer: 1,4,5,6,7)
    -- LR1
    -- 1 salarié (1)
    -- 2 activité accessoire (6)
    -- 3 permis 120j (5)
    -- 4 administrateurs (4)
    -- 5 effeuilleurs (7)
    -- LR2
    -- 6 autres cantons (8)
    -- LR3
    -- 7 bénéficiaires de rente (3)
    -- LR4
    -- 8 revenu en compensation
    -- 9 Travail au noir
    -- LR5
    -- 10 Artistes sportifs
    -- LR6
    -- 11 Prestations en capitales
    when '1' then '1'
    when '4' then '4'
    when '5' then '3'
    when '6' then '2'
    when '7' then '5'
    else '1'
  end;
end;

function decode_ge_religion(
  data IN hrm_person.c_hrm_ge_religion%TYPE)
  return VARCHAR2
is
begin
  return case data
    -- 0 : Non renseigné (pour les cas ou l'information est facultative ou N/A)
    -- 1 : Protestant
    -- 2 : Catholique chr?tien
    -- 3 : Catholique romain
    -- 4 : Sans confession
    -- 5 : Autre confession
    when '1' then '1'
    when '2' then '2'
    when '3' then '3'
    when '8' then '4'
    when '9' then '5'
    else '0'
  end;
end;

function decode_gender(
  data IN hrm_person.per_gender%TYPE)
  return VARCHAR2
is
begin
  return case data
    when 'M' then '1'
    when 'F' then '2'
  end;
end;

function decode_civil_status(
  data IN hrm_person.c_civil_status%TYPE)
  return VARCHAR2
is
begin
  return case data
    when 'Cel' then '1'
    when 'Cnc' then '1'
    when 'Mar' then '2'
    when 'Pdi' then '2'
    when 'Div' then '3'
    when 'Pab' then '4'
    when 'Sep' then '4'
    when 'Pde' then '5'
    when 'Veu' then '5'
    when 'Pen' then '6'
    else '0'
  end;
end;

function decode_employee_taxsource(
  data IN hrm_employee_taxsource.emt_value%TYPE)
  return VARCHAR2
is
begin
  return case Trim(Substr(data,3,2))
    when 'A0' then '1'
    when 'B0' then '2'
    when 'B1' then '3'
    when 'B2' then '4'
    when 'B3' then '5'
    when 'B4' then '6'
    when 'B5' then '7'
    when 'A1' then '50'
    when 'A2' then '51'
    when 'A3' then '52'
    when 'A4' then '53'
    when 'A5' then '54'
    when 'C0' then '55'
    when 'C1' then '56'
    when 'C2' then '57'
    when 'C3' then '58'
    when 'C4' then '59'
    when 'C5' then '60'
    WHEN 'H1' then '61'
    when 'H2' then '62'
    when 'H3' then '63'
    when 'H4' then '64'
    when 'H5' then '65'
    else data
  end;
end;

function decode_ge_prof_cat(
  data IN hrm_person.c_hrm_ge_prof_cat%TYPE)
  return VARCHAR2
is
begin
  return case LPad(data, 2, '0')
    when '01' then '1'
    when '02' then '2'
    when '03' then '4'
    when '04' then '5'
    when '05' then '6'
    when '06' then '7'
    when '07' then '9'
    when '08' then '11'
    when '09' then '3'
    when '10' then '8'
    when '11' then '10'
    when '12' then '12'
    when '13' then '13'
    else '0'
  end;
end;


function getDPI
  return VARCHAR2
is
begin
  return gv_DPI;
end;

function getDateFrom
  return DATE
is
begin
  return gv_date_from;
end;

function getDateTo
  return DATE
is
begin
  return gv_date_to;
end;

function getListId
  return hrm_control_list.hrm_control_list_id%TYPE
is
begin
  return gn_list_id;
end;



function GetDeclaration(
  pDPI IN VARCHAR2,
  pYear IN YearType,
  pListId IN hrm_control_list.hrm_control_list_id%TYPE)
  return CLOB
is
begin
  return p_XmlToClob(hrm_ge_taxsource_declaration.GetDeclarationXML(pDPI, pYear, pListId));
end;
function GetDeclaration(
  pDPI IN VARCHAR2,
  pDateFrom IN DATE,
  pDateTo IN DATE,
  pListId IN hrm_control_list.hrm_control_list_id%TYPE)
  return CLOB
is
begin
  return p_XmlToClob(hrm_ge_taxsource_declaration.GetDeclarationXML(pDPI, pDateFrom, pDateTo, pListId));
end;

function GetDeclarationXML(
  pDPI IN VARCHAR2,
  pYear IN YearType,
  pListId IN hrm_control_list.hrm_control_list_id%TYPE)
  return XMLType
is
begin
  p_InitInternals(
    pDPI,
    to_date('0101'||to_char(pYear),'DDMMYYYY'), to_date('3112'||pYear,'DDMMYYYY'),
    pListId);
  return hrm_ge_taxsource_declaration.GetDeclarationXML();
end;
function GetDeclarationXML(
  pDPI IN VARCHAR2,
  pDateFrom IN DATE,
  pDateTo IN DATE,
  pListId IN hrm_control_list.hrm_control_list_id%TYPE)
  return XMLType
is
begin
  p_InitInternals(pDPI, pDateFrom, pDateTo, pListId);
  return hrm_ge_taxsource_declaration.GetDeclarationXML();
end;
function GetDeclarationXML
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("ISEL_LR_2_0:declarationListeRecapitulative",
      XMLAttributes(
        'http://etat.geneve.ch/financeisel/schema/2_0' as "xmlns:ISEL_LR_2_0",
        'http://www.w3.org/2001/XMLSchema-instance' AS "xmlns:xsi",
        'http://etat.geneve.ch/financeisel/schema/2_0 ISEL_ListeRecapitulative_2_0.xsd' as "xsi:schemaLocation"),
      hrm_ge_taxsource_declaration.GetHeaderDPI,
      XMLElement("ISEL_LR_2_0:ListeRecapitulativeT1",
        hrm_ge_taxsource_declaration.GetTaxPayerDetails_12)
    ) into lx_data
  from DUAL;
  return lx_data;
end;

function GetHeaderDPI
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("ISEL_LR_2_0:DPI",
      XMLElement("ISEL_LR_1_03:numeroDPI", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") , gv_DPI),
      XMLElement("ISEL_LR_1_03:nomRaisonSocialeDPI", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") , Nvl(COM_SOCIALNAME,COM_DESCR)),
      XMLElement("ISEL_LR_1_03:adresseDPI", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,
        XMLElement("ISEL_LR_1_03:voieCasePostale",
          XMLElement("ISEL_LR_1_03:voieSeule",
            XMLElement("ISEL_LR_1_03:voie", COM_ADR)
          )
        ),
        XMLElement("ISEL_LR_1_03:NPA", COM_ZIP),
        XMLElement("ISEL_LR_1_03:localite", COM_CITY),
        XMLElement("ISEL_LR_1_03:pays",
          case (CN.CNTID)
            when 'CH' then XMLElement("ISEL_LR_1_03:suisse", CNTID)
            else XMLElement("ISEL_LR_1_03:paysEtranger", CNTID)
          end
        )
      ),
      XMLElement("ISEL_LR_1_03:periodeImpositionDPI", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,
        XMLElement("ISEL_LR_1_03:debut_imposition", to_char(gv_date_from,'dd.mm.yyyy')),
        XMLElement("ISEL_LR_1_03:fin_imposition", to_char(gv_date_to,'dd.mm.yyyy'))
      )
    ) into lx_data
  from
    PCS.PC_CNTRY CN,
    PCS.PC_COMP C
  where
    C.PC_COMP_ID = pcs.PC_I_LIB_SESSION.GetCompanyId and
    CN.PC_CNTRY_ID = C.PC_CNTRY_ID;

  return lx_data;

  exception
    when NO_DATA_FOUND then
      raise_application_error(-20000,'invalid or unknown company');
      return null;
end;

function GetTaxPayerDetails_12
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("ISEL_LR_2_0:declarationContribuable",
      XMLForest(
        hrm_ge_taxsource_declaration.decode_ge_taxpayer(C_HRM_GE_TAXPAYER) as "ISEL_LR_2_0:typeContribuable",
        NullIf(hrm_ge_taxsource_declaration.decode_ge_religion(C_HRM_GE_RELIGION),'0') as "ISEL_LR_2_0:confession"
      ),
      XMLElement("ISEL_LR_2_0:infoContribuable",
        case when EMP_SOCIAL_SECURITYNO2 is not null then
          XMLElement("ISEL_LR_1_03:nouveauNAVS13", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,EMP_SOCIAL_SECURITYNO2)
        end,

        XMLElement("ISEL_LR_1_03:nomPersonne", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,PER_LAST_NAME),
        XMLElement("ISEL_LR_1_03:prenomPersonne", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,PER_FIRST_NAME),
        XMLElement("ISEL_LR_1_03:dateNaissance", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,to_char(PER_BIRTH_DATE,'dd.mm.yyyy')),
        XMLElement("ISEL_LR_1_03:sexe",XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") , hrm_ge_taxsource_declaration.decode_gender(PER_GENDER)),
        XMLElement("ISEL_LR_1_03:etatCivil",XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") , hrm_ge_taxsource_declaration.decode_civil_status(C_CIVIL_STATUS))),
      hrm_ge_taxsource_declaration.GetFamily(HRM_PERSON_ID),
      hrm_ge_taxsource_declaration.GetHomeAddress(HRM_PERSON_ID),
      hrm_ge_taxsource_declaration.GetSubmission(HRM_PERSON_ID),
      hrm_ge_taxsource_declaration.GetTaxAmounts(HRM_PERSON_ID)
    )) into lx_data
  from HRM_PERSON P
  where C_HRM_GE_TAXPAYER in ('1','4','5','6','7') and
    -- Filtrer pour ceux qui ont eu des impôts uniquement
    Exists(select 1 from
            (select HRM_PERSON_ID, EMT_FROM, Nvl(EMT_TO, gv_date_to) EMT_TO, EMT_CANTON
             from HRM_EMPLOYEE_TAXSOURCE)
           where
             HRM_PERSON_ID = P.HRM_PERSON_ID and
             EMT_CANTON = 'GE' and
             EMT_FROM <= gv_date_to and EMT_TO >= gv_date_from) and
    Exists(select 1 from HRM_HISTORY_DETAIL D, HRM_CONTROL_ELEMENTS E
           where COE_BOX='S1' and D.HRM_ELEMENTS_ID = E.HRM_CONTROL_ELEMENTS_ID and
             HRM_CONTROL_LIST_ID = gn_list_id and
             HIS_PAY_PERIOD between gv_date_from and gv_date_to and HRM_EMPLOYEE_ID = P.HRM_PERSON_ID);

  return lx_data;

  exception
    when NO_DATA_FOUND then
      raise_application_error(-20000,'no data found with this selection');
      return null;
end;

function GetChildrenBirthDates(
  empid IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("ISEL_LR_2_0:dateNaissanceEnfantInf25",
      to_char(REL_BIRTH_DATE,'yyyy')
    ) order by REL_BIRTH_DATE ) into lx_data
  from (
    select REL_BIRTH_DATE, Trunc(Months_Between(gv_date_to, REL_BIRTH_DATE)/12) aging
    from HRM_RELATED_TO
    where HRM_EMPLOYEE_ID = empid and C_RELATED_TO_TYPE = '2')
  where AGING < 25;

  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function GetFamily(
  empid IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("ISEL_LR_2_0:famille",
      (
        select
          XMLConcat(
            XMLForest(
              REL_NAME as "ISEL_LR_2_0:nomConjoint",
              REL_FIRST_NAME as "ISEL_LR_2_0:prenomConjoint"
            ),
            case when DIC_CANTON_WORK_ID is not null then
                XMLElement("ISEL_LR_2_0:conjointAvecRevenu",1)
            end
           )
        from HRM_RELATED_TO
        where HRM_EMPLOYEE_ID = P.HRM_PERSON_ID and C_RELATED_TO_TYPE(+) = '1'

      ),
      hrm_ge_taxsource_declaration.GetChildrenBirthDates(hrm_person_id),
      XMLElement("ISEL_LR_2_0:unionLibre", Nvl(C_HRM_GE_COHABITATION,0))
    ) into lx_data
  from
    HRM_PERSON P
  where
    P.HRM_PERSON_ID = empid;

  return lx_data;
end;

function GetHomeAddress(
  empid IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("ISEL_LR_2_0:adresseDomicile",
      XMLElement("ISEL_LR_1_03:adresse",XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,
        XMLElement("ISEL_LR_1_03:voie",
          XMLElement("ISEL_LR_1_03:voie", Nvl(PER_TAXSTREET, PER_HOMESTREET))
        ),
        XMLElement("ISEL_LR_1_03:NPA",
          Nvl(Substr(PER_TAXPOSTALCODE, Instr(PER_TAXPOSTALCODE,'-')+1), Substr(PER_HOMEPOSTALCODE, Instr(PER_HOMEPOSTALCODE,'-')+1))
        )
      ),
      XMLElement("ISEL_LR_1_03:localite", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,Nvl(PER_TAXCITY, PER_HOMECITY)),
      case
        -- Seulement un entre "communePolitique", "canton" ou "pays"
        when (C_HRM_GE_HOMESTATE = 'GE' and C_HRM_GE_HOMECITY <> '0') then
          XMLElement("ISEL_LR_1_03:communePolitique", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,'66'||C_HRM_GE_HOMECITY)
        when C_HRM_GE_HOMESTATE in ('AG','AI','AR','BE','BL','BS','FR','GL','GR','JU','LU','NE','NW','OW','SG','SH','SO','SZ','TG','TI','UR','VD','VS','ZG','ZH') then
          XMLElement("ISEL_LR_1_03:canton", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,C_HRM_GE_HOMESTATE)
        when (hrm_country_fct.SearchCountryCode(Nvl(P.PER_TAXCOUNTRY, P.PER_HOMECOUNTRY)) is not null) then
          XMLElement("ISEL_LR_1_03:pays",XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,
            (select Max(CNTID) from PCS.PC_CNTRY
             where CNTID != 'CH' and CNTID = hrm_country_fct.SearchCountryCode(Nvl(P.PER_TAXCOUNTRY, P.PER_HOMECOUNTRY)))
          )
      end
--       XMLForest(
--         (select Max(c.cntid)
--           from pcs.pc_cntry c,
--             (select Substr(cnt_code,1,2) cnt_code, cnt_name
--              from hrm_country) co
--          where co.cnt_code <> 'CH' and co.cnt_code = c.cntid and
--                Instr(co.cnt_name,Nvl(p.per_taxcountry, p.per_homecountry))>0) "pays",
--         case
--           when dic_canton_work_id in ('AG','AI','AR','BE','BL','BS','FR','GL','GR','JU','LU','NE','NW','OW','SG','SH','SO','SZ','TG','TI','UR','VD','VS','ZG','ZH') then dic_canton_work_id
--         end "canton",
--         case
--           when dic_canton_work_id = 'GE' and c_hrm_ge_homecity <> '0' then '66'||c_hrm_ge_homecity
--         end "communePolitique"
--       )
    ) into lx_data
  from HRM_PERSON P
  where HRM_PERSON_ID = empid;

  return lx_data;
end;

function GetSubmission(
  empid IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  lx_data XMLType;
  est_address HRM_ESTABLISHMENT.EST_ADDRESS%type;
  est_zip HRM_ESTABLISHMENT.EST_ZIP%type;
  est_city HRM_ESTABLISHMENT.est_city%type;
begin

  select EST_ADDRESS, EST_ZIP, est_city into est_address, est_zip,est_city
    from (select E.EST_ADDRESS, E.EST_ZIP from HRM_IN_OUT IO, HRM_ESTABLISHMENT E
            where HRM_EMPLOYEE_ID = EMPID
            and gv_date_to between IO.INO_IN and HRM_DATE.NEXTINOUTINDATE(io.ino_in, EMPID)
            and IO.HRM_ESTABLISHMENT_ID = E.HRM_ESTABLISHMENT_ID
            order by IO.INO_IN desc)
            where ROWNUM = 1;

  select
    XMLAgg(XMLElement("ISEL_LR_2_0:assujettissementContribuable",
      XMLElement("ISEL_LR_2_0:periodeImposition",
        XMLElement("ISEL_LR_1_03:debut_imposition", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,to_char(Greatest(T.EMT_FROM, gv_date_from),'dd.mm.yyyy')),
        XMLElement("ISEL_LR_1_03:fin_imposition", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,to_char(Least(T.EMT_TO, gv_date_to),'dd.mm.yyyy'))
      ),
      XMLElement("ISEL_LR_2_0:adresseTravail",
        XMLElement("ISEL_LR_1_03:adresse",XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,
          XMLElement("ISEL_LR_1_03:voie",
            XMLElement("ISEL_LR_1_03:voie", est_address)
          ),
          XMLElement("ISEL_LR_1_03:NPA", est_zip)
        ),
        xmlelement("ISEL_LR_1_03:localite",XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,est_city),
        case
          -- Seulement un entre "communePolitique" ou "canton"
          when P.DIC_CANTON_WORK_ID='GE' and P.C_HRM_GE_WORKCITY is not null then
            -- RHE : Ajout du 66 dans la commune

            XMLElement("ISEL_LR_1_03:communePolitique",XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") , '66'||P.C_HRM_GE_WORKCITY)
          when P.DIC_CANTON_WORK_ID in ('AG','AI','AR','BE','BL','BS','FR','GL','GR','JU','LU','NE','NW','OW','SG','SH','SO','SZ','TG','TI','UR','VD','VS','ZG','ZH' ) then
            XMLElement("ISEL_LR_1_03:canton", XMLATTRIBUTES (
                                  'http://etat.geneve.ch/financeisel/schema/1_0' AS
                                          "xmlns:ISEL_LR_1_03") ,P.DIC_CANTON_WORK_ID)
        end
      ),
      XMLElement("ISEL_LR_2_0:baremeImposition",
        hrm_ge_taxsource_declaration.decode_employee_taxsource(T.EMT_VALUE)
      )
    )) into lx_data
  from
    (select HRM_PERSON_ID, EMT_VALUE, EMT_FROM, Nvl(EMT_TO, gv_date_to) EMT_TO, EMT_CANTON
     from HRM_EMPLOYEE_TAXSOURCE) T,
    HRM_PERSON P
  where
    P.HRM_PERSON_ID = empid and T.HRM_PERSON_ID = P.HRM_PERSON_ID and
    T.EMT_CANTON = 'GE' and
    T.EMT_FROM <= gv_date_to and T.EMT_TO >= gv_date_from;

  return lx_data;
end;

function GetTaxAmounts(
  empid IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("ISEL_LR_2_0:retenuePrestationsImpots",
      XMLElement("ISEL_LR_2_0:tauxImposition",
        case
          when trunc(Sum(case when COE_BOX='S1' then HIS_PAY_SUM_VAL * INVERSER else 0 end)) = 0 then 0
          else Abs(round(Sum(case when COE_BOX='I1' then HIS_PAY_SUM_VAL * INVERSER else 0 end)*100 /
                           Sum(case when COE_BOX='S1' then HIS_PAY_SUM_VAL * INVERSER else 0 end),
                         2))
        end
      ),
      /*
      RHE : Suppression
      XMLElement("ISEL_LR_2_0:raisonSocialeEmployeur",
       (select Nvl(com_socialname, com_descr) from pcs.pc_comp
        where pc_comp_id = pcs.PC_I_LIB_SESSION.getcompanyid)
      ),*/
      XMLElement("ISEL_LR_2_0:prestationsSoumisesImpot",
        -- Montant entier
        Trunc(Sum(case when COE_BOX='S1' then HIS_PAY_SUM_VAL * INVERSER else 0 end))
      ),
      XMLElement("ISEL_LR_2_0:retenueSalarie",

        -- Montants entiers
        XMLForest(
          Trunc(Sum(case when COE_BOX='R1' then HIS_PAY_SUM_VAL * INVERSER else 0 end)) as "ISEL_LR_2_0:nbrJoursAbsence"
        ),
        case when C_HRM_GE_TAXPAYER='5' then
          XMLElement("ISEL_LR_2_0:nbrJourstravailEffectif",
            Nvl(Trunc(Sum(case when COE_BOX='R2' then HIS_PAY_SUM_VAL * INVERSER else 0 end)),0)
          )
        end
        ,
        XMLForest(
          Trunc(Sum(case when COE_BOX='R3' then HIS_PAY_SUM_VAL * INVERSER else 0 end)) as "ISEL_LR_2_0:indemnitesDepart",
          Trunc(Sum(case when COE_BOX='R4' then HIS_PAY_SUM_VAL * INVERSER else 0 end)) as "ISEL_LR_2_0:prestationsNonPeriodiques",
          Trunc(Sum(case when COE_BOX='R5' then HIS_PAY_SUM_VAL * INVERSER else 0 end)) as "ISEL_LR_2_0:allocationsFamiliales",
          Trunc(Sum(case when COE_BOX='R6' then HIS_PAY_SUM_VAL * INVERSER else 0 end)) as "ISEL_LR_2_0:fraisEffectifsNonInclus",
          Trunc(Sum(case when COE_BOX='R7' then HIS_PAY_SUM_VAL * INVERSER else 0 end)) as "ISEL_LR_2_0:fraisForfaitairesNonInclus",
          case when C_HRM_GE_TAXPAYER='1' or
                    C_HRM_GE_HOMESTATE in ('AG','AI','AR','BE','BL','BS','FR','GL','GR','JU','LU','NE','NW','OW','SG','SH','SO','SZ','TG','TI','UR','VD','VS','ZG','ZH') then
            Trunc(PER_ACTIVITY_RATE,2)
          end as "ISEL_LR_2_0:tauxActivite",
          Trunc(Sum(case when COE_BOX='R8' then HIS_PAY_SUM_VAL * INVERSER else 0 end)) as "ISEL_LR_2_0:participationsEmployes"
         )
      ),
      -- Montant d'impôt, arrondi à 5cts et format
      XMLElement("ISEL_LR_2_0:impotsRetenus",
        to_char(Trunc((-Sum(case when COE_BOX='I1' then HIS_PAY_SUM_VAL * INVERSER else 0 end)*20)+0.5)/20,'FM99999990.00')
      ),
      -- Condition uniquement si <> 0, arrondis à 5cts et format
      case when Sum(case when COE_BOX='I2' then HIS_PAY_SUM_VAL * INVERSER else 0 end) <> 0 then
        XMLForest(to_char(Trunc((-Sum(case when COE_BOX='I2' then HIS_PAY_SUM_VAL * INVERSER else 0 end)*20)+0.5)/20,'FM99999990.00') as "ISEL_LR_2_0:contributionEcclesiastique")
      end
    ) into lx_data
  from
    HRM_HISTORY_DETAIL D,
    HRM_PERSON_TAX T,
    (select case when Nvl(COE_INVERSE,0) = 1 then -1 else 1 end INVERSER, E.*
     from HRM_CONTROL_ELEMENTS E) E,
    HRM_PERSON P
  where
    P.HRM_PERSON_ID = empid and D.HRM_EMPLOYEE_ID = P.HRM_PERSON_ID and
    D.HIS_PAY_PERIOD between gv_date_from and gv_date_to and
    E.HRM_CONTROL_LIST_ID = gn_list_id and
    D.HRM_ELEMENTS_ID = E.HRM_CONTROL_ELEMENTS_ID and
    T.HRM_PERSON_ID(+) = P.HRM_PERSON_ID and
    -- Filtrer pour ceux qui ont eu des impôts uniquement
     exists(select 1 from
             (select HRM_PERSON_ID, EMT_CANTON, EMT_FROM,
                     case when exists(select 1
                                      from HRM_IN_OUT
                                      where HRM_EMPLOYEE_ID = T.HRM_PERSON_ID
                                        and INO_OUT = EMT_TO) then
                       -- Si pas d'entrée suivante avant le 31.12, prendre cette date, sinon le dernier jour du mois précédent la prochaine entrée
                       case
                         when HRM_DATE.NEXTINOUTINDATE(EMT_TO, T.HRM_PERSON_ID) = HRM_DATE.ENDOFYEAR then HRM_DATE.ENDOFYEAR
                         else trunc(HRM_DATE.NEXTINOUTINDATE(EMT_TO, T.HRM_PERSON_ID), 'month') - 1
                       end
                     else nvl(last_day(EMT_TO), GV_DATE_TO)
                     end EMT_TO
               from HRM_EMPLOYEE_TAXSOURCE T)
            where HRM_PERSON_ID = P.HRM_PERSON_ID
              and EMT_CANTON = 'GE'
              and D.HIS_PAY_PERIOD between EMT_FROM and EMT_TO)
  group by
    P.C_HRM_GE_PROF_CAT,
    P.PER_ACTIVITY_RATE,
    T.C_HRM_CANTON_TAX_FEES,
    T.EMP_TAX_FULLFILLED, C_HRM_GE_TAXPAYER, C_HRM_GE_HOMESTATE;

  return lx_data;
end;

END HRM_GE_TAXSOURCE_DECLARATION;
