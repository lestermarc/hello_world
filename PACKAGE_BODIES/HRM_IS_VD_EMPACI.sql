--------------------------------------------------------
--  DDL for Package Body HRM_IS_VD_EMPACI
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IS_VD_EMPACI" 
/**
 * Package regroupant les fonctions et procédures nécessaires
 * à l'établissement des listes récapitulatives et correctives
 * pour l'impôt à la source du canton de Vaud.
 *
 * @version 1.0
 * @date 04.2010
 * @author rhermann
 * @author spfister
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
IS

  gtt_emp_list TT_EMP_LIST;
  gcd_MAX_DATE CONSTANT DATE := to_date('31.12.2022','dd.mm.yyyy');

--
-- Private methods
--

/**
 * Recherche du nom d'un employé.
 * @param in_employee_id Identifiant de l'employé.
 * @return le nom complet de l'employé.
 */
function p_employee_name(
  in_employee_id IN hrm_person.hrm_person_id%TYPE)
  return VARCHAR2
  DETERMINISTIC
is
  lv_result VARCHAR2(32767);
begin
  select per_first_name||' '||per_last_name
  into lv_result
  from hrm_person
  where hrm_person_id = in_employee_id;
  return lv_result;

  exception
    when NO_DATA_FOUND then
      return to_char(in_employee_id);
end;

/**
 * Convertion d'un document Xml en texte, avec prologue.
 * @param XmlDoc  Document Xml original.
 * @return Un CLob contenant le texte du document Xml, ainsi qu'un prologue
 *         complet correspondant à l'encodage de la base.
 */
function p_XmlToClob(XmlDoc IN XMLType) return CLob is
begin
  if (XmlDoc is not null) then
    return pc_jutils.get_XMLPrologDefault ||Chr(10)|| XmlDoc.getClobVal();
  end if;
  return null;
end;



--
-- Public methods
--

function NextEmpTaxInDate(
  id_givenDate IN DATE,
  in_employee_id IN hrm_person.hrm_person_id%TYPE)
  return DATE
  RESULT_CACHE RELIES_ON (HRM_EMPLOYEE_TAXSOURCE)
is
  ld_result DATE;
  cursor lcur_next_inout_in_date is
      select emt_from-1
      from hrm_employee_taxsource
      where hrm_person_id = in_employee_id and
        emt_from > id_givenDate
      order by emt_from asc;
begin
  open lcur_next_inout_in_date;
  fetch lcur_next_inout_in_date into ld_result;
  if (lcur_next_inout_in_date%NOTFOUND) then
    ld_result := hrm_date.EndOfYear;
  end if;
  close lcur_next_inout_in_date;
  return ld_result;
end;

procedure add_employee(
  in_employee_id IN hrm_person.hrm_person_id%TYPE)
is
begin
  gtt_emp_list.EXTEND(1);
  gtt_emp_list(hrm_is_vd_empaci.count_employee) := in_employee_id;
end;
procedure add_employee(
  iv_employee IN VARCHAR2)
is
  ln_employee_id hrm_person.hrm_person_id%TYPE;
begin
  select HRM_PERSON_ID
  into ln_employee_id
  from HRM_PERSON
  where PER_LAST_NAME||' '||PER_FIRST_NAME = iv_employee;
  hrm_is_vd_empaci.add_employee(ln_employee_id);

  exception
    when NO_DATA_FOUND then
      null;
end;

function count_employee
  return INTEGER
is
begin
  return Nvl(gtt_emp_list.COUNT,0);
end;

procedure clear_employee
is
begin
  gtt_emp_list.DELETE;
end;

function employees(
  id_from IN DATE,
  id_to IN DATE)
  return TT_EMP_LIST
  PIPELINED
is
begin
  if (gtt_emp_list.COUNT = 0) then
    select distinct HRM_PERSON_ID
    bulk collect into gtt_emp_list
    from
    (select HRM_PERSON_ID, EMT_VALUE, EMT_FROM, EMT_TO, EMT_EVENT_DATE, C_HRM_IS_VD_EVENT,
     case
       when exists(select 1
                   from HRM_IN_OUT IO
                   where IO.HRM_EMPLOYEE_ID = HRM_PERSON_ID
                     and INO_OUT = EMT_TO) then
         HRM_DATE.NEXTINOUTINDATE(EMT_TO,HRM_PERSON_ID)
       else nvl(EMT_TO,id_to)
     end EMT_TO2
     from HRM_EMPLOYEE_TAXSOURCE)
    where EMT_VALUE like 'VD%' and id_to >= EMT_FROM and id_from <= EMT_TO2
    and (exists(select 1
                from HRM_HISTORY_DETAIL
                where HIS_PAY_PERIOD between greatest(coalesce(emt_from,id_from),coalesce(id_from,emt_from)) and least(coalesce(emt_to2,id_to),coalesce(id_to,emt_to2)) and HRM_EMPLOYEE_ID = HRM_PERSON_ID
                and exists(select 1
                           from HRM_CONTROL_ELEMENTS CE, HRM_CONTROL_LIST L
                           where L.HRM_CONTROL_LIST_ID = CE.HRM_CONTROL_LIST_ID
                           and C_CONTROL_LIST_TYPE = '115'
                           and HRM_CONTROL_ELEMENTS_ID = HRM_ELEMENTS_ID)
                )
          or (C_HRM_IS_VD_EVENT is not null and EMT_EVENT_DATE between id_from and id_to )
        )
    ;
  end if;

  if (gtt_emp_list.COUNT > 0) then
    for cpt in gtt_emp_list.FIRST..gtt_emp_list.LAST loop
      pipe row(gtt_emp_list(cpt));
    end loop;
  end if;

  return;

  exception
    when NO_DATA_NEEDED then
      return;
end;



function contributors(
  iv_list_name IN hrm_control_list.col_name%TYPE,
  id_from IN DATE,
  id_to IN DATE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("decompteContribuable",
      XMLAttributes(rownum "noSequenceDecompte"),
      XMLELement("identite",
        XMLForest(EMP_SECONDARY_KEY "numContribuable" ), -- nouveau champ de contribuable
        XMLElement("nom", PER_LAST_NAME),
        XMLElement("prenom", PER_FIRST_NAME),
        XMLElement("dateNaissance", PER_BIRTH_DATE),
        XMLElement("codeSexe", Decode(PER_GENDER,'M',1,2)),
        case when emp_social_securityno2 is not null
          then XMLElement("numAvs", Replace(EMP_SOCIAL_SECURITYNO2,'.',''))
          else case when Length(EMP_SOCIAL_SECURITYNO) = 14 then
            XMLElement("numAvs", Replace(EMP_SOCIAL_SECURITYNO,'.',''))
          end
        end,
        case when (DIC_NATIONALITY_ID <> 'CH')
          then XMLElement("permisTravail", hrm_is_vd_empaci.permit(p.hrm_person_id, id_to))
          else XMLElement("suisse", 'true')
        end,
        XMLElement("commune",
          (select Min(PC_OFS_CITY_ID) from HRM_EMPLOYEE_TAXSOURCE
           where HRM_PERSON_ID = P.HRM_PERSON_ID and EMT_VALUE like 'VD%' and
             Trunc(id_from,'year') between Trunc(EMT_FROM,'year') and Nvl(EMT_TO, id_to))
        ), -- Gérer le code commune
        XMLElement("identifiantSalarieChezEmployeur", EMP_NUMBER)
      ),
      hrm_is_vd_empaci.salary(iv_list_name, hrm_person_id, id_from, id_to)
    )) into lx_data
  from TABLE(hrm_is_vd_empaci.employees(id_from, id_to)) T, HRM_PERSON P
  where T.COLUMN_VALUE = P.HRM_PERSON_ID;
  return lx_data;
end;


function amount_for_type(
  iv_list_name IN hrm_control_list.col_name%TYPE,
  iv_position IN hrm_control_elements.coe_box%TYPE,
  in_employee_id IN hrm_person.hrm_person_id%TYPE,
  id_from IN DATE,
  id_to IN DATE)
  return hrm_history_detail.his_pay_sum_val%TYPE
is
  ln_result hrm_history_detail.his_pay_sum_val%TYPE;
begin
  select Sum(HIS_PAY_SUM_VAL * case when Nvl(COE_INVERSE,0) = 1 then -1 else 1 end)
  into ln_result
  from HRM_HISTORY_DETAIL D, HRM_CONTROL_ELEMENTS E,HRM_HISTORY H
  where
    Exists(select 1 from HRM_CONTROL_LIST
           where COL_NAME = iv_list_name and HRM_CONTROL_LIST_ID = E.HRM_CONTROL_LIST_ID) and
    Exists(select 1 from TABLE(hrm_is_vd_empaci.employees(id_from, id_to)) T
           where
             H.HRM_EMPLOYEE_ID = T.COLUMN_VALUE) and
    D.HRM_ELEMENTS_ID = E.HRM_CONTROL_ELEMENTS_ID and
    H.HRM_EMPLOYEE_ID = D.HRM_EMPLOYEE_ID and H.HRM_EMPLOYEE_ID = Nvl(in_employee_id, H.HRM_EMPLOYEE_ID) and
    E.COE_BOX = iv_position and
    H.HIT_PAY_NUM = D.HIS_PAY_NUM and
    H.HIT_PAY_PERIOD between id_from and LAST_DAY(id_to);


  return Nvl(ln_result,0);

  exception
    when NO_DATA_FOUND then
      return 0;
end;

function permit(
  in_employee_id IN hrm_person.hrm_person_id%TYPE,
  id_to IN DATE)
  return VARCHAR2
is
  lv_result VARCHAR2(2);
begin
  select hrm_is_vd_empaci.DecodeWorkPermit(DIC_WORK_PERMIT_ID)
  into lv_result
  from (
    select DIC_WORK_PERMIT_ID
    from HRM_EMPLOYEE_WK_PERMIT
    where HRM_PERSON_ID = in_employee_id and id_to >= WOP_VALID_FROM
    order by WOP_VALID_FROM desc
  )
  where rownum = 1;
  return lv_result;

  exception
    when NO_DATA_FOUND then
      raise_application_error(-20000,'Permis manquant pour '||p_employee_name(in_employee_id));
end permit;

function emp_event(
  in_employee_id IN hrm_person.hrm_person_id%TYPE,
  id_from IN DATE,
  id_to IN DATE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("evenement",
      XMLAttributes(EMT_EVENT_DATE "date"),
      hrm_is_vd_empaci.DecodeEvent(C_HRM_IS_VD_EVENT)
    ) into lx_data
  from HRM_EMPLOYEE_TAXSOURCE
  where HRM_PERSON_ID = in_employee_id
    and EMT_EVENT_DATE between id_from and id_to
    and C_HRM_IS_VD_EVENT not in ( 'A','B');

  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function salary(
  iv_list_name IN hrm_control_list.col_name%TYPE,
  in_employee_id IN hrm_person.hrm_person_id%TYPE,
  id_from IN DATE,
  id_to IN DATE)
  return XMLType
is
  lx_data XMLType;
  ln_is number(16,2);
begin
  select
    XMLAgg(XMLElement("salaire",
      XMLAttributes(
        greatest(T.STRICT_EMT_FROM,id_from) "debutVersement",
        greatest(id_from,Least(Nvl(T.STRICT_EMT_TO, id_to), id_to)) "finVersement",
        rownum "noSequenceSalaire"),
      XMLElement("revenuNonProportionel", hrm_is_vd_empaci.amount_for_type(iv_list_name,'NONPROP',in_employee_id,EMT_FROM,EMT_TO2)),
      XMLElement("salaireVerseOuPrestationImposable", hrm_is_vd_empaci.amount_for_type(iv_list_name,'PROP',in_employee_id,EMT_FROM,EMT_TO2)),
      XMLElement("retenueDImpot", -hrm_is_vd_empaci.amount_for_type(iv_list_name,'IS',in_employee_id,EMT_FROM,EMT_TO3)),
      XMLElement("bareme",
        XMLElement("nombreAllocations", Substr(T.EMT_VALUE,4,1)),
        XMLElement("typeActivite", hrm_is_vd_empaci.DecodeActivity(T.C_HRM_IS_VD_ACTIVITY)),
        XMLElement("tauxActivite", T.EMT_ACTIVITY_RATE), -- ajouter une colonne pour le taux d'activité dans le permis
        XMLElement("codeBareme",
          case when (Substr(T.EMT_VALUE,4,1) < 'A' and to_char(id_from,'yyyy') < '2014' ) or substr(t.emt_value,3,1) = 'D'
            then Substr(T.EMT_VALUE,3,1)
            else Substr(T.EMT_VALUE,3,2)
          end
        )
      ),
       case
        when C_HRM_IS_VD_EVENT='I' then
          XMLElement("evenement",
            XMLAttributes(INO_OUT "date"),
            'I-Décès'
          )
        when (INO_OUT between EMT_FROM and EMT_TO) and (ino_out between id_from and id_to) then
          XMLElement("evenement",
            XMLAttributes(INO_OUT "date"),
            'B-Sortie'
          )
        when emt_other_event is not null then emt_other_event
        when (INO_IN between emt_from and emt_to) and (ino_in between id_from and id_to) then
          XMLElement("evenement",
            XMLAttributes(INO_IN "date"),
            'A-Entrée'
          )
      end
    )) into lx_data
  from (
    select T.HRM_PERSON_ID,
      EMT_FROM STRICT_EMT_FROM,
      EMT_TO STRICT_EMT_TO,
      trunc(Greatest(T.EMT_FROM, id_from), 'month') EMT_FROM,
      last_day(Least(id_to, Nvl(T.EMT_TO, id_to))) EMT_TO,
      case when exists(select 1 from hrm_in_out io where io.hrm_employee_id = p.hrm_person_id and ino_out = emt_to) then
        case
        when to_char(emt_to,'yyyy') <>  to_char(id_from,'yyyy') then to_date('31.12.'||to_char(emt_to,'yyyy'),'dd.mm.yyyy')
        when HRM_DATE.NEXTINOUTINDATE(ino_in,p.hrm_person_id) = hrm_date.endofyear then
            hrm_date.endofyear
             else
              case when HRM_DATE.NEXTINOUTINDATE(ino_in,p.hrm_person_id) = last_day( HRM_DATE.NEXTINOUTINDATE(ino_in,p.hrm_person_id)) then
                 HRM_DATE.NEXTINOUTINDATE(ino_in,p.hrm_person_id)
                else trunc(HRM_DATE.NEXTINOUTINDATE(ino_in,p.hrm_person_id) ,'month')-1 -- dernier jour du mois précèdent la précèdente
                end
        end
        else last_day(nvl(emt_to,id_to)) end emt_to2,
      Replace(T.EMT_VALUE,'VDV','VDD') EMT_VALUE,
      T.C_HRM_IS_VD_ACTIVITY, T.C_HRM_IS_VD_EVENT, T.EMT_EVENT_DATE,
      trunc(Nvl(Nvl(T.EMT_ACTIVITY_RATE,P.PER_ACTIVITY_RATE),100)) EMT_ACTIVITY_RATE,
      hrm_is_vd_empaci.emp_event(in_employee_id, greatest(emt_from,id_from), least(nvl(emt_to,id_to),id_to)) EMT_OTHER_EVENT,
      least(trunc(NextEmpTaxInDate(emt_from, t.hrm_person_id)+1,'month')-1,id_to) emt_to3,
      INO_IN,
      INO_OUT
    from HRM_EMPLOYEE_TAXSOURCE T, HRM_PERSON P, HRM_IN_OUT I
    where T.EMT_VALUE like 'VD%' and T.HRM_PERSON_ID = P.HRM_PERSON_ID
     and I.HRM_EMPLOYEE_ID = in_employee_id
    and I.INO_IN <= nvl(EMT_TO,gcd_max_date) and Nvl(I.INO_OUT, nvl(T.EMT_TO,gcd_max_date)) >= T.EMT_FROM and I.C_IN_OUT_CATEGORY = '3') T
  where
    T.HRM_PERSON_ID = in_employee_id and
    id_to >= T.EMT_FROM and id_from <= emt_to2    ;


  return lx_data;
end salary;


function DecodeActivity(
  iv_is_vd_activity IN hrm_employee_taxsource.c_hrm_is_vd_activity%TYPE)
  return VARCHAR2
is
begin
  return
    case iv_is_vd_activity
      when '01' then 'principale'
      when '02' then 'accessoire'
      when '03' then 'complémentaire'
      else 'activité invalide/manquante'
    end;
end;

function DecodeEvent(
  iv_is_vd_event IN hrm_employee_taxsource.c_hrm_is_vd_event%TYPE)
  return VARCHAR2
is
begin
  return
    case iv_is_vd_event
      when 'A' then 'A-Entrée'
      when 'B' then 'B-Sortie'
      when 'C' THEN 'C-Mariage'
      when 'D' then 'D-DébutDroitAllocation'
      when 'E' then 'E-FinDroitAllocation'
      when 'F' then 'F-NouveauTauxActivité'
      when 'G' then 'G-Séparation'
      when 'H' then 'H-Divorce'
      when 'I' then 'I-Décès'
      when 'K' then 'K-Veuvage'
      when 'L' then 'L-ChangementFor'
      when 'M' then 'M-ChangementBareme'
      when 'E01' then 'E01-EmbaucheDansEntreprise'
      when 'E02' then 'E02-ChangementDeCanton'
      when 'E99' then 'E99-EntréeAutre'
      when 'S01' then 'S01-DépartDeEntreprise'
      when 'S02' then 'S02-Naturalisation'
      when 'S03' then 'S03-PermisEtablissementC'
      when 'S04' then 'S04-EmploiTemporaire'
      when 'S05' then 'S05-ChangementDeCanton'
      when 'S99' then 'S99-SortieAutre'
      when 'M01' then 'M01-EtatCivil'
      when 'M02' then 'M02-TravailDuPartenaire'
      when 'M03' then 'M03-TravailDuPartenaireEnItalie'
      when 'M04' then 'M04-AdresseDeDomicile'
      when 'M05' then 'M05-DéductionPourEnfant'
      when 'M06' then 'M06-TauxOccupation'
      when 'M07' then 'M07-ActivitéAnnexe'
      when 'M98' then 'M98-ImpôtEcclésiastique'
      when 'M99' then 'M99-MutationAutre'
    end;
end;

function DecodeWorkPermit(
  iv_work_permit IN hrm_employee_wk_permit.dic_work_permit_id%TYPE)
  return VARCHAR2
is
begin
  return
    case iv_work_permit
--      when 'A' then '01'
      when 'B' then '02'
      when 'C' then '03'
      when 'Ci' then '04'
      when 'F' then '05'
      when 'G' then '06'
      when 'L' then '07'
      when 'N' then '08'
      when 'S' then '09'
      else '10'
    end;
end;

function generate_lr(
  iv_list_name IN hrm_control_list.col_name%TYPE,
  id_from IN DATE,
  id_to IN DATE,
  iv_firm_no VARCHAR2,
  in_rate IN NUMBER)
  return CLOB
is
  lx_data XMLType;
  l_is hrm_history_detail.his_pay_sum_val%TYPE;
begin
  select sum(-hrm_is_vd_empaci.amount_for_type(iv_list_name, 'IS', HRM_PERSON_ID, greatest(EMT_FROM, id_from), least(id_to, EMT_TO3) ) )
  into l_is
  from (select T.HRM_PERSON_ID
             , EMT_FROM STRICT_EMT_FROM
             , EMT_TO STRICT_EMT_TO
             , trunc(greatest(T.EMT_FROM, id_from), 'month') EMT_FROM
             , last_day(least(id_to, nvl(T.EMT_TO, id_to) ) ) EMT_TO
             , case
                 when exists(select 1
                               from hrm_in_out io
                              where io.hrm_employee_id = p.hrm_person_id
                                and ino_out = emt_to) then case
                                                            when to_char(emt_to, 'yyyy') <> to_char(id_from, 'yyyy') then to_date('31.12.' ||
                                                                                                                                  to_char(emt_to, 'yyyy')
                                                                                                                                , 'dd.mm.yyyy'
                                                                                                                                 )
                                                            when HRM_DATE.NEXTINOUTINDATE(ino_in, p.hrm_person_id) = hrm_date.endofyear then hrm_date.endofyear
                                                            else last_day(trunc(HRM_DATE.NEXTINOUTINDATE(ino_in, p.hrm_person_id) - 1, 'month') )
                                                          end
                 else last_day(nvl(emt_to, id_to) )
               end emt_to2
             , replace(T.EMT_VALUE, 'VDV', 'VDD') EMT_VALUE
             , T.C_HRM_IS_VD_ACTIVITY
             , T.C_HRM_IS_VD_EVENT
             , T.EMT_EVENT_DATE
             , trunc(nvl(nvl(T.EMT_ACTIVITY_RATE, P.PER_ACTIVITY_RATE), 100) ) EMT_ACTIVITY_RATE
             , least(hrm_is_vd_empaci.NextEmpTaxInDate(emt_from, t.hrm_person_id), id_to) emt_to3
             , INO_IN
             , INO_OUT
          from HRM_EMPLOYEE_TAXSOURCE T
             , HRM_PERSON P
             , HRM_IN_OUT I
         where T.EMT_VALUE like 'VD%'
           and T.HRM_PERSON_ID = P.HRM_PERSON_ID
           and i.hrm_employee_id = p.hrm_person_id
           and I.INO_IN <= nvl(EMT_TO, gcd_max_date)
           and nvl(I.INO_OUT, nvl(T.EMT_TO, gcd_max_date) ) >= T.EMT_FROM
           and I.C_IN_OUT_CATEGORY = '3') s
     , table(hrm_is_vd_empaci.employees(id_from, id_to) ) T
 where T.column_value = S.HRM_PERSON_ID
   and id_to >= s.EMT_FROM
   and id_from <= emt_to2;


  select
    XMLElement("tns:listeImpotSource",
      XMLAttributes(
        'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi",
        'http://www.vd.ch/fiscalite/impotsource/liste-impot-source/4' as "xmlns:tns",
        'http://www.vd.ch/fiscalite/impotsource/liste-impot-source/4 Liste_impot_source-4.xsd' as "xsi:schemaLocation",
        id_from "debutPeriodeDeclaration",
        id_to "finPeriodeDeclaration"),
      XMLElement("typeListe", 'LR'),
      XMLElement("numDebiteur", iv_firm_no),
      XMLElement("montantBrut", l_is),
      XMLElement("montantCommission", Trunc(l_is*in_rate/100, 2)), -- gérer le taux de commission
      hrm_is_vd_empaci.contributors(iv_list_name, id_from, id_to)
    ) into lx_data
  from dual;

  return p_XmlToClob(lx_data);
end generate_lr;


function generate_lc(
  iv_list_name IN hrm_control_list.col_name%TYPE,
  id_from IN DATE,
  id_to IN DATE,
  iv_firm_no VARCHAR2)
  return CLOB
is
  lx_data XMLType;
  l_is hrm_history_detail.his_pay_sum_val%TYPE;
  lx_cont XMLType;
begin
  lx_cont := hrm_is_vd_empaci.contributors(iv_list_name, id_from, id_to);

  select sum(-hrm_is_vd_empaci.amount_for_type(iv_list_name, 'IS', HRM_PERSON_ID, greatest(EMT_FROM, id_from), least(id_to, EMT_TO3) ) )
  into l_is
  from (select T.HRM_PERSON_ID
             , EMT_FROM STRICT_EMT_FROM
             , EMT_TO STRICT_EMT_TO
             , trunc(greatest(T.EMT_FROM, id_from), 'month') EMT_FROM
             , last_day(least(id_to, nvl(T.EMT_TO, id_to) ) ) EMT_TO
             , case
                 when exists(select 1
                               from hrm_in_out io
                              where io.hrm_employee_id = p.hrm_person_id
                                and ino_out = emt_to) then case
                                                            when to_char(emt_to, 'yyyy') <> to_char(id_from, 'yyyy') then to_date('31.12.' ||
                                                                                                                                  to_char(emt_to, 'yyyy')
                                                                                                                                , 'dd.mm.yyyy'
                                                                                                                                 )
                                                            when HRM_DATE.NEXTINOUTINDATE(ino_in, p.hrm_person_id) = hrm_date.endofyear then hrm_date.endofyear
                                                            else last_day(trunc(HRM_DATE.NEXTINOUTINDATE(ino_in, p.hrm_person_id) - 1, 'month') )
                                                          end
                 else last_day(nvl(emt_to, id_to) )
               end emt_to2
             , replace(T.EMT_VALUE, 'VDV', 'VDD') EMT_VALUE
             , T.C_HRM_IS_VD_ACTIVITY
             , T.C_HRM_IS_VD_EVENT
             , T.EMT_EVENT_DATE
             , trunc(nvl(nvl(T.EMT_ACTIVITY_RATE, P.PER_ACTIVITY_RATE), 100) ) EMT_ACTIVITY_RATE
             , least(hrm_is_vd_empaci.NextEmpTaxInDate(emt_from, t.hrm_person_id), id_to) emt_to3
             , INO_IN
             , INO_OUT
          from HRM_EMPLOYEE_TAXSOURCE T
             , HRM_PERSON P
             , HRM_IN_OUT I
         where T.EMT_VALUE like 'VD%'
           and T.HRM_PERSON_ID = P.HRM_PERSON_ID
           and i.hrm_employee_id = p.hrm_person_id
           and I.INO_IN <= nvl(EMT_TO, gcd_max_date)
           and nvl(I.INO_OUT, nvl(T.EMT_TO, gcd_max_date) ) >= T.EMT_FROM
           and I.C_IN_OUT_CATEGORY = '3') s
     , table(hrm_is_vd_empaci.employees(id_from, id_to) ) T
 where T.column_value = S.HRM_PERSON_ID
   and id_to >= s.EMT_FROM
   and id_from <= emt_to2;


  select
    XMLElement("tns:listeImpotSource",
      XMLAttributes(
        'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi",
        'http://www.vd.ch/fiscalite/impotsource/liste-impot-source/4' as "xmlns:tns",
        'http://www.vd.ch/fiscalite/impotsource/liste-impot-source/4 Liste_impot_source-4.xsd' as "xsi:schemaLocation",
        id_from "debutPeriodeDeclaration",
        id_to "finPeriodeDeclaration"),
      XMLElement("typeListe", 'LC'),
      XMLElement("numDebiteur", iv_firm_no),
      XMLElement("montantBrut", l_is),
      XMLElement("montantCommission", 0),
      lx_cont
    ) into lx_data
  from dual;

  return p_XmlToClob(lx_data);
end generate_lc;


procedure import_data(
  pData IN CLOB)
is
begin
  null;
end import_data;


BEGIN

  gtt_emp_list := TT_EMP_LIST();

END HRM_IS_VD_EMPACI;
