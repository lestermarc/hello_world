--------------------------------------------------------
--  DDL for Package Body PAC_MACRO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_MACRO" 
IS

function formatAddress(pacPersonId IN pac_person.pac_person_id%TYPE,
  pacPacPersonId IN pac_person.pac_person_id%TYPE,
  addressFormatId IN pac_address_format.pac_address_format_id%TYPE,
  addressTypeId IN dic_address_type.dic_address_type_id%TYPE DEFAULT 'ADD_PRINCIPAL',
  cleanstr IN INTEGER DEFAULT 1)
  return VARCHAR2
is
  macroText pac_address_format.afo_macro%TYPE;
  freeTextId dic_free_text.dic_free_text_id%TYPE;
begin
  select afo_macro, dic_free_text_id
  into macroText, freeTextId
  from pac_address_format
  where pac_address_format_id = addressFormatId;

  return formatAddress(pacPersonId, pacPacPersonId, macroText, freeTextId, addressTypeId, cleanstr);

  exception
   when no_data_found then
     return null;
end;

function formatAddress(pacPersonId IN pac_person.pac_person_id%TYPE,
  pacPacPersonId IN pac_person.pac_person_id%TYPE,
  MacroText IN VARCHAR2,
  addressTypeId IN dic_address_type.dic_address_type_id%TYPE DEFAULT 'ADD_PRINCIPAL',
  cleanstr IN INTEGER DEFAULT 1)
  return VARCHAR2
is
begin
  return formatAddress(pacPersonId, pacPacPersonId, MacroText, '', addressTypeId, cleanstr);
end;

function formatAddress(pacPersonId IN pac_person.pac_person_id%TYPE,
  pacPacPersonId IN pac_person.pac_person_id%TYPE,
  MacroText IN VARCHAR2,
  freeTextId IN dic_free_text.dic_free_text_id%TYPE,
  addressTypeId IN dic_address_type.dic_address_type_id%TYPE,
  cleanstr IN INTEGER)
  return VARCHAR2
is
  strSQL VARCHAR2(32767);
  Result VARCHAR2(4000);
begin
  -- Construction de la commande à exécuter
  strSQL :=
  -- 1 ère partie construction selon macros
      'SELECT '''||Replace(Replace(Replace(Replace(MacroText||'','''',''''''),
                                           '{CR}','<CARRIAGE_RETURN>'),
                                 '}', '||'''),
                         '{', '''||')||
      ''' FROM ' ||
  -- 2 ème partie (recherche des valeurs)
      '(SELECT * FROM (
        SELECT
          Decode(Nvl(p.per_contact,0),1,com_dic_functions.getdicodescr(''DIC_PERSON_POLITNESS'',p.dic_person_politness_id, a.pc_lang_id),'' '') person_politness,
          pac_macro.getPolitnessFormula(p.dic_person_politness_id,a.pc_lang_id,1) politness1,
          pac_macro.getPolitnessFormula(p.dic_person_politness_id,a.pc_lang_id,2) politness2,
          pac_macro.getPolitnessFormula(p.dic_person_politness_id,a.pc_lang_id,3) politness3,
          pac_macro.getPolitnessFormula(p.dic_person_politness_id,a.pc_lang_id,4) politness4,
          p.per_name per_name1, p.per_forename per_name2, a.add_care_of add_care_of,
          a.add_address1 add_address, a.add_po_box add_po_box, a.add_po_box_nbr add_po_box_nbr,
          p.per_activity per_activity, a.add_format add_format, a.add_state add_state, a.add_county add_county,
          com_dic_functions.getdicodescr (''DIC_PERSON_POLITNESS'',a2.dic_person_politness_id,a.pc_lang_id) pas_person_politness,
          pac_macro.getPolitnessFormula(a2.dic_person_politness_id,a.pc_lang_id,1) politness_contact1,
          pac_macro.getPolitnessFormula(a2.dic_person_politness_id,a.pc_lang_id,2) politness_contact2,
          pac_macro.getPolitnessFormula(a2.dic_person_politness_id,a.pc_lang_id,3) politness_contact3,
          pac_macro.getPolitnessFormula(a2.dic_person_politness_id,a.pc_lang_id,4) politness_contact4,
          a2.per_name pac_person_association1, a2.per_forename pac_person_association2,
          CASE WHEN a2.add_format IS NOT NULL THEN a2.add_care_of ELSE a.add_care_of end AS PAS_ADD_CARE_OF,
          CASE WHEN a2.add_format IS NOT NULL THEN a2.add_address1 ELSE a.add_address1 end AS PAS_ADDRESS,
          CASE WHEN a2.add_format IS NOT NULL THEN a2.add_po_box ELSE a.add_po_box end AS PAS_ADD_PO_BOX,
          CASE WHEN a2.add_format IS NOT NULL THEN a2.add_po_box_nbr ELSE a.add_po_box_nbr end AS PAS_ADD_PO_BOX_NBR,
          CASE WHEN a2.add_format IS NOT NULL THEN a2.per_activity ELSE p.per_activity end AS PAS_ACTIVITY,
          CASE WHEN a2.add_format IS NOT NULL THEN a2.add_format ELSE a.add_format end AS PAS_ADD_FORMAT,
          CASE WHEN a2.add_format IS NOT NULL THEN a2.add_state ELSE a.add_state end AS PAS_ADD_STATE,
          CASE WHEN a2.add_format IS NOT NULL THEN a2.add_county ELSE a.add_county end AS PAS_ADD_COUNTY,
          a2.pas_function,
          com_dic_functions.getDicoDescr(''DIC_FREE_TEXT'', :MacroFreeText, a.pc_lang_id)
        FROM
          (SELECT ass.pac_person_id personid, ass.pas_function, p.dic_person_politness_id, p.per_name,
             p.per_forename, a.add_format, a.add_care_of, a.add_address1, a.add_po_box, a.add_po_box_nbr,
             p.per_activity, a.add_state, a.add_county
           FROM pac_address a, pac_person_association ass, pac_person p
           WHERE p.pac_person_id = :pacPacPersonId AND ass.pac_pac_person_id = p.pac_person_id AND
            a.pac_address_id(+)= pac_macro.getMinaddressId(p.pac_person_id, :addressTypeId)
            -- Eviter doublons (2 associations Person/Contact identiques
            AND ass.pac_person_id = :pac_person_id and ROWNUM = 1
           ) a2,
          pac_address a,
          pac_person p
        WHERE p.pac_person_id = :pac_person_id AND
          a.pac_address_id(+) = pac_macro.getMinAddressId(p.pac_person_id, :addressTypeId) AND
          a2.personid(+) = p.pac_person_id
        ))';
  begin
    -- Exécution de la commande avec les paramètres donnés
   EXECUTE IMMEDIATE strSQL
      INTO Result
      USING freeTextId, pacpacpersonid, addressTypeId, pacpersonid, pacpersonid, addressTypeId;

    -- Nettoyage du résultat
    if (cleanstr = 1) then
      Result := Replace(Result,Chr(13),'');

     while (Instr(Result, ' '||Chr(10)) > 0) OR
            (Instr(Result, Chr(10)||' ') > 0) OR
            (Instr(Result, Chr(10)||Chr(10)) > 0) OR
            (Instr(Result, '  ') > 0) loop
        Result :=
            Replace(Replace(Replace(Replace(Result,'  ',' '),
                                    Chr(10)||Chr(10), Chr(10)),
                            ' '||Chr(10), Chr(10)),
                    Chr(10)||' ',Chr(10));
      end loop;

      Result := Replace(Result, '<CARRIAGE_RETURN>', Chr(10));

     if (Substr(Result, 1, 1) = Chr(10)) then
        Result := Substr(Result, 2);
      end if;

     if (Substr(Result, Length(Result)) = Chr(10)) then
        Result := Substr(Result, 1, Length(Result)-1);
     end if;
    end if;

   exception
      when NO_DATA_FOUND then null;
  end;

  return Trim(Result);

  exception
    when no_data_found then
      return null;
end;


procedure p_getDefCommunication(pPacPersonId IN pac_person.pac_person_id%TYPE,
  pComm1 OUT VARCHAR2, pComm2 OUT VARCHAR2, pComm3 OUT VARCHAR2)
is
begin
  if pPacPersonId is null then
    return;
  end if;

  select
    max(case NumDef when 1 then (com_area_code||' '||com_ext_number||com_int_number) end) com_number1,
    max(case NumDef when 2 then (com_area_code||' '||com_ext_number||com_int_number) end) com_number2,
    max(case NumDef when 3 then (com_area_code||' '||com_ext_number||com_int_number) end) com_number3
    into pComm1, pComm2, pComm3
  from
    pac_communication c,
    (select max(pac_communication_id) pac_communication_id, NumDef
     from(select pac_communication_id,
            case when dic.dco_default1 = 1 then 1
                 when dic.dco_default2 = 1 then 2
                 when dic.dco_default3 = 1 then 3 end NumDef
          from pac_communication c, dic_communication_type dic
          where c.dic_communication_type_id = dic.dic_communication_type_id and
            c.pac_person_id = pPacPersonId and
            (dic.dco_default1 = 1 or dic.dco_default2 = 1 or dic.dco_default3 = 1))
     group by NumDef) v
  where
    c.pac_communication_id = v.pac_communication_id;
end;

function formatEventText(pPacPersonId IN pac_person.pac_person_id%TYPE,
  pPacPacPersonId IN pac_person.pac_person_id%TYPE,
  pPcUserId IN pcs.pc_user.pc_user_id%TYPE,
  pEveDate IN pac_event.eve_date%TYPE,
  pEveEndDate IN pac_event.eve_enddate%TYPE,
  pEveNumber IN pac_event.eve_number%TYPE,
  pEveRecordId IN pac_event.doc_record_id%TYPE,
  pEveTypeDescr IN pac_event_type_descr.typ_long_description%TYPE,
  pEvtText IN pac_event.eve_text%TYPE)
  return VARCHAR2
is
  Result pac_event.eve_text%TYPE;

  type TComm is varray(3) of VARCHAR2(100);
  vCommP TComm := TComm('','','');
  vCommC TComm := TComm('','','');

  vRcoNumber doc_record.rco_number%TYPE;
  vRcoTitle doc_record.rco_title%TYPE;

  vUseName pcs.pc_user.use_name%TYPE;
  vUseDescr pcs.pc_user.use_descr%TYPE;
  vUseEMail pcs.pc_user.use_email%TYPE;
  vUseFax pcs.pc_user.use_fax%TYPE;
  vUsePhone pcs.pc_user.use_phone%TYPE;
  vUseFree1 pcs.pc_user.use_free1%TYPE;
  vUseFree2 pcs.pc_user.use_free2%TYPE;
begin

  Result := pEvtText;

  -- Vérifier si des macros sont utilisées
  if (instr(Result, '{') = 0) then
    return Result;
  end if;

  -- Remplacement des information de l'événement
  if (instr(Result, '{EVE_') <> 0) then
    -- Remplacement des informations
    Result :=
      Replace(Replace(Replace(Result,
        '{EVE_DATE}', To_Char(pEveDate, 'DD.MM.YYYY')),
        '{EVE_ENDDATE}', To_Char(pEveEndDate, 'DD.MM.YYYY')),
        '{EVE_NUMBER}', pEveNumber);
  end if;

  Result := Replace(Result, '{TYP_DESCRIPTION}', pEveTypeDescr);

  -- Remplacement de l'utilisateur
  if (instr(Result, '{USE_') <> 0) then
    --Recherche des informations
    if pPcUserId is not null then
      begin
        select use_name, use_descr, use_email, use_fax, use_phone,
          use_free1, use_free2
        into vUseName, vUseDescr, vUseEMail, vUseFax, vUsePhone,
          vUseFree1, vUseFree2
        from pcs.pc_user u
        where u.pc_user_id = pPcUserId;

        exception when no_data_found then null;
      end;
    end if;
     -- Remplacement des informations
    Result :=
      Replace(Replace(Replace(Replace(Replace(Replace(Replace(Result,
        '{USE_NAME}', vUseName),
        '{USE_DESCR}', vUseDescr),
        '{USE_EMAIL}', vUseEmail),
        '{USE_FAX}', vUseFax),
        '{USE_PHONE}', vUsePhone),
        '{USE_FREE1}', vUseFree1),
        '{USE_FREE2}', vUseFree2);
  end if;

  -- Remplacement du dossier
  if (instr(Result, '{RCO_') <> 0) then
    -- Recherche des information
    if pEveRecordId is not null then
      begin
        select rco_number, rco_title
        into vRcoNumber, vRcoTitle
        from doc_record
        where doc_record_id = pEveRecordId;

        exception when no_data_found then null;
      end;
    end if;
    -- Remplacement des informations
    Result :=
      Replace(Replace(Result,
        '{RCO_NUMBER}', vRcoNumber),
        '{RCO_TITLE}', vRcoTitle);
  end if;

  -- Remplacement des communications
  if (instr(Result, 'PAC_DCO_DEF') <> 0) then
    p_GetDefCommunication(pPacPersonId, vCommP(1), vCommP(2), vCommP(3));
    p_GetDefCommunication(pPacPacPersonId, vCommC(1), vCommC(2), vCommC(3));
    Result :=
      Replace(Replace(Replace(Replace(Replace(Replace(Result,
        '{PAC_DCO_DEF1}', vCommP(1)),
        '{PAC_DCO_DEF2}', vCommP(2)),
        '{PAC_DCO_DEF3}', vCommP(3)),
        '{PAC_PAC_DCO_DEF1}', nvl(vCommC(1), vCommP(1))),
        '{PAC_PAC_DCO_DEF2}', nvl(vCommC(2), vCommP(2))),
        '{PAC_PAC_DCO_DEF3}', nvl(vCommC(3), vCommP(3)));
  end if;

  -- Remplacement des adresses à la fin (éviter erreur de macro indéfinie)
  -- Vérifier si des macros sont utilisées
  if (instr(Result, '{') <> 0) then
    Result := formatAddress(pPacPersonId, pPacPacPersonId, Result, '', '', 0);
  end if;

  return Result;
end;

function getMinAddressId(pacpersonid IN pac_person.pac_person_id%TYPE,
  addressTypeId IN dic_address_type.dic_address_type_id%TYPE)
  return pac_address.pac_address_id%TYPE
is
  Result pac_address.pac_address_id%TYPE;
begin
  SELECT Nvl(Min(pac_address_id),0) INTO Result
  FROM pac_address
  WHERE pac_person_id = pacpersonid AND dic_address_type_id = addressTypeId;

  if not(result != 0.0) then
    SELECT Min(pac_address_id) into Result
    FROM pac_address
    WHERE pac_person_id = pacpersonid AND add_principal = 1 ;
  end if;

  return Result;
end;

function getPolitnessFormula(politness IN dic_person_politness.dic_person_politness_id%TYPE,
  lang IN pcs.pc_lang.pc_lang_id%TYPE,
  typeFormula IN INTEGER)
  return VARCHAR2
is
  Result varchar2(2000);
begin

  SELECT
    case typeFormula
      when 1 then pol_formula1
     when 2 then pol_formula2
    when 3 then pol_formula3
    when 4 then pol_formula4
    end into Result
  FROM pac_politness_formula f, pac_formula_traduction t
  WHERE f.pac_politness_formula_id = t.pac_politness_formula_id
  AND dic_person_politness_id = politness
  AND t.pc_lang_id = lang;

  return Result;

  exception
    when no_data_found then
      return null;
end;

END;
