--------------------------------------------------------
--  DDL for Package Body PAC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_FUNCTIONS" 
is
  /**
  * retourne la description des conditions d'envoi
  */
  function GetSendCondDescr(
    condition_id pac_sending_condition_text.pac_sending_condition_id%type
  , lang_id      pac_sending_condition_text.pc_lang_id%type
  )
    return varchar2
  is
    result pac_sending_condition_text.sen_descr%type;
  begin
    select sen_descr
      into result
      from pac_sending_condition_text
     where pac_sending_condition_id = condition_id
       and pc_lang_id + 0 = lang_id;

    return result;
  exception
    when no_data_found then
      return ' ';
  end GetSendCondDescr;

  /**
  * Description
  *        Recherche des liens des événements de la personne donnée
  */
  function CountEventLink(pPersonId PAC_PERSON.PAC_PERSON_ID%type)
    return number
  is
    vCounter number;
  begin
    begin
      select count(*)
        into vCounter
        from PAC_LINK
       where PAC_EVENT_ID in(select PAC_EVENT_ID
                               from PAC_EVENT
                              where PAC_PERSON_ID = pPersonId);

      return vCounter;
    exception
      when no_data_found then
        return 0;
    end;
  end CountEventLink;

  /**
  * Description
  *        Recherche des images des événements de la personne donnée
  */
  function CountEventImage(pPersonId PAC_PERSON.PAC_PERSON_ID%type)
    return number
  is
    vCounter number;
  begin
    begin
      select count(*)
        into vCounter
        from COM_IMAGE_FILES
       where IMF_REC_ID in(select PAC_EVENT_ID
                             from PAC_EVENT
                            where PAC_PERSON_ID = pPersonId)
         and IMF_TABLE = 'PAC_EVENT';

      return vCounter;
    exception
      when no_data_found then
        return 0;
    end;
  end CountEventImage;

  /**
  * Description
  *        Recherche si le partenaire donné est référencé dans des documents logistiques
  */
  function CountPartnerLogDocument(pPersonId PAC_PERSON.PAC_PERSON_ID%type)
    return number
  is
    vCounter number;
  begin
    begin
      select count(*)
        into vCounter
        from DOC_DOCUMENT
       where PAC_THIRD_ID = pPersonId;

      return vCounter;
    exception
      when no_data_found then
        return 0;
    end;
  end CountPartnerLogDocument;

  /**
  * Description
  *        Recherche du mail du partenaire donné
  */
  function GetPartnerMail(pPersonId PAC_PERSON.PAC_PERSON_ID%type)
    return PAC_COMMUNICATION.COM_EXT_NUMBER%type
  is
    vMail PAC_COMMUNICATION.COM_EXT_NUMBER%type;
  begin
    begin
      select COM_EXT_NUMBER
        into vMail
        from DIC_COMMUNICATION_TYPE TYP
           , PAC_COMMUNICATION COM
       where PAC_PERSON_ID = pPersonId
         and COM.DIC_COMMUNICATION_TYPE_ID = TYP.DIC_COMMUNICATION_TYPE_ID
         and DCO_EMAIL + 0 = 1
         and rownum = 1;
    exception
      when no_data_found then
        vMail  := null;
    end;

    if vMail is null then
      vMail  := '';
    end if;

    return vMail;
  end GetPartnerMail;

  /**
  * Description
  *        Recherche en cascade du mail du partenaire ou du contact donné
  */
  function EmailExist(pPersonId PAC_PERSON.PAC_PERSON_ID%type, pContactId PAC_PERSON.PAC_PERSON_ID%type)
    return PAC_COMMUNICATION.COM_EXT_NUMBER%type
  is
    vMail PAC_COMMUNICATION.COM_EXT_NUMBER%type;
  begin
    begin
      /* Recherche primaire  => mail de la personne courante                                        */
      select COM_EXT_NUMBER
        into vMail
        from DIC_COMMUNICATION_TYPE TYP
           , PAC_COMMUNICATION COM
       where PAC_PERSON_ID = pPersonId
         and COM.DIC_COMMUNICATION_TYPE_ID = TYP.DIC_COMMUNICATION_TYPE_ID
         and DCO_EMAIL + 0 = 1
         and rownum = 1;

      if vMail is null then
        vMail  := PAC_FUNCTIONS.GetPartnerMail(pContactId);
      end if;
    exception
      when no_data_found then
        begin
          /* Recherche secondaire si mail partenaire inexistant => mail du contact                      */
          vMail  := PAC_FUNCTIONS.GetPartnerMail(pContactId);
        exception
          when no_data_found then
            vMail  := null;
        end;
    end;

    if vMail is null then
      vMail  := '';
    end if;

    return vMail;
  end EmailExist;

  /**
  * Description
  *        Recherche du fax du partenaire donné
  */
  function GetPartnerFax(pPersonId PAC_PERSON.PAC_PERSON_ID%type)
    return PAC_COMMUNICATION.COM_EXT_NUMBER%type
  is
    result PAC_COMMUNICATION.COM_EXT_NUMBER%type;
  begin
    select com_ext_number
      into result
      from pac_communication c
     where pac_communication_id =
             (select max(pac_communication_id)
                from dic_communication_type t
                   , pac_communication c
               where t.dic_communication_type_id = c.dic_communication_type_id
                 and c.pac_person_id = pPersonId
                 and t.dco_fax = 1);

    return result;
  exception
    when others then
      return null;
  end;

  /**
  * Description
  *        Recherche du fax du contact ou de la personne le cas échéant
  */
  function GetCascadePartnerFax(pContactId PAC_PERSON.PAC_PERSON_ID%type, pPersonId PAC_PERSON.PAC_PERSON_ID%type)
    return PAC_COMMUNICATION.COM_EXT_NUMBER%type
  is
    result PAC_COMMUNICATION.COM_EXT_NUMBER%type;
  begin
    if pContactId is not null then
      result  := nvl(GetPartnerFax(pContactId), GetPartnerFax(pPersonId) );
    else
      result  := GetPartnerFax(pPersonId);
    end if;

    return result;
  exception
    when others then
      return null;
  end;

  /**
  * function ControlThirdExist
  * Description
  *   return 1 if Third exists otherwise 0
  * @created fp 17.11.2003
  * @lastUpdate
  * @public
  * @param aThirdId : third to check
  * @return 1 if Third exists
  */
  function ControlThirdExist(aThirdId in PAC_THIRD.PAC_THIRD_ID%type, aAdminDomain in varchar2)
    return number
  is
    result number(1);
  begin
    if aAdminDomain in('2', '7') then   -- Ventes/SAV
      select sign(nvl(max(PAC_CUSTOM_PARTNER_ID), 0) )
        into result
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = aThirdId
         and C_PARTNER_STATUS = '1';
    elsif aAdminDomain in('1', '5') then   -- Achats/Sous-Traitance
      select sign(nvl(max(PAC_SUPPLIER_PARTNER_ID), 0) )
        into result
        from PAC_SUPPLIER_PARTNER
       where PAC_SUPPLIER_PARTNER_ID = aThirdId
         and C_PARTNER_STATUS = '1';
    else   -- autres
      select sign(nvl(max(CUS.PAC_CUSTOM_PARTNER_ID), 0) )
        into result
        from PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where CUS.PAC_CUSTOM_PARTNER_ID = aThirdId
         and SUP.PAC_SUPPLIER_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
         and (   CUS.C_PARTNER_STATUS = '1'
              or SUP.C_PARTNER_STATUS = '1');
    end if;

    return result;
  end ControlThirdExist;

  /**
  * Description
  *        Recherche du nombre de contact du partenaire donné
  */
  function CountPartnerAssociation(pPersonId PAC_PERSON.PAC_PERSON_ID%type)
    return number
  is
    vCounter number;
  begin
    begin
      select count(*)
        into vCounter
        from PAC_PERSON_ASSOCIATION
       where PAC_PERSON_ID = pPersonId;

      return vCounter;
    exception
      when no_data_found then
        return 0;
    end;
  end CountPartnerAssociation;

  /**
  * Description
  *        Recherche du nombre d'évènements du partenaire donné
  */
  function CountPartnerEvents(pPersonId PAC_PERSON.PAC_PERSON_ID%type)
    return number
  is
    vCounter number;
  begin
    begin
      select count(*)
        into vCounter
        from PAC_EVENT
       where PAC_PERSON_ID = pPersonId;

      return vCounter;
    exception
      when no_data_found then
        return 0;
    end;
  end CountPartnerEvents;

  /**
  * Description
  *        Liaison d'un code libre à un type d'événement
  */
  procedure InsertMandatoryCode(
    pEventTypeId PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type
  , pDicCodeName PCS.PC_TABLE.TABNAME%type
  , pDicCodeId   DIC_CHAR_CODE_TYP.DIC_CHAR_CODE_TYP_ID%type
  , pSequence    PAC_MANDATORY_CODE.PMC_SEQUENCE%type
  )
  is
    vMandatoryCodeId PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type;
  begin
    begin
      /*Réception d'un nouvel Id */
      select INIT_ID_SEQ.nextval
        into vMandatoryCodeId
        from dual;

      /*Ajout de l'enregistrement dans la table*/
      insert into PAC_MANDATORY_CODE
                  (PAC_MANDATORY_CODE_ID
                 , PAC_EVENT_TYPE_ID
                 , DIC_NUMBER_CODE_TYP_ID
                 , DIC_DATE_CODE_TYP_ID
                 , DIC_CHAR_CODE_TYP_ID
                 , DIC_BOOLEAN_CODE_TYP_ID
                 , PMC_SEQUENCE
                 , A_IDCRE
                 , A_DATECRE
                  )
           values (vMandatoryCodeId
                 , pEventTypeId
                 , decode(pDicCodeName, 'DIC_NUMBER_CODE_TYP', pDicCodeId, null)
                 , decode(pDicCodeName, 'DIC_DATE_CODE_TYP', pDicCodeId, null)
                 , decode(pDicCodeName, 'DIC_CHAR_CODE_TYP', pDicCodeId, null)
                 , decode(pDicCodeName, 'DIC_BOOLEAN_CODE_TYP', pDicCodeId, null)
                 , pSequence
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , sysdate
                  );

      /*Mise à jour valeur / défaut du code booléen à false pour les codes non booléens */
      /*Permet visuellement de mettre les checkBox associés non grisé                   */
      update PAC_MANDATORY_CODE
         set PMC_BOOLEAN_DEFAULT_VAL = 0
       where PAC_EVENT_TYPE_ID = pEventTypeId
         and DIC_BOOLEAN_CODE_TYP_ID is null;
    exception
      when others then
        vMandatoryCodeId  := 0;
        raise;
    end;
  end InsertMandatoryCode;

  /**
  * Description
  *        Liaison d'un code libre à un événement
  */
  procedure InsertEventCode(
    pEventId     PAC_EVENT.PAC_EVENT_ID%type
  , pDicCodeName PCS.PC_TABLE.TABNAME%type
  , pDicCodeId   DIC_CHAR_CODE_TYP.DIC_CHAR_CODE_TYP_ID%type
  )
  is
  begin
    begin
      if pDicCodeName = 'DIC_BOOLEAN_CODE_TYP' then
        insert into PAC_BOOLEAN_CODE
                    (DIC_BOOLEAN_CODE_TYP_ID
                   , PAC_EVENT_ID
                   , BOO_CODE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (pDicCodeId
                   , pEventId
                   , null
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      elsif pDicCodeName = 'DIC_CHAR_CODE_TYP' then
        insert into PAC_CHAR_CODE
                    (DIC_CHAR_CODE_TYP_ID
                   , PAC_EVENT_ID
                   , CHA_CODE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (pDicCodeId
                   , pEventId
                   , null
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      elsif pDicCodeName = 'DIC_NUMBER_CODE_TYP' then
        insert into PAC_NUMBER_CODE
                    (DIC_NUMBER_CODE_TYP_ID
                   , PAC_EVENT_ID
                   , NUM_CODE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (pDicCodeId
                   , pEventId
                   , null
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      elsif pDicCodeName = 'DIC_DATE_CODE_TYP' then
        insert into PAC_DATE_CODE
                    (DIC_DATE_CODE_TYP_ID
                   , PAC_EVENT_ID
                   , DAT_CODE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (pDicCodeId
                   , pEventId
                   , null
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;
    exception
      when others then
        raise;
    end;
  end InsertEventCode;

  /**
  * Description
  *        Renumérotation des séquences des codes libres du type d'événement donné
  */
  procedure OrderMandatoryCodeBySequence(pEventTypeId PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type)
  is
    cursor TypeMandatoryCode
    is
      select   PAC_MANDATORY_CODE_ID
          from PAC_MANDATORY_CODE
         where PAC_EVENT_TYPE_ID = pEventTypeId
      order by PMC_SEQUENCE
             , PAC_MANDATORY_CODE_ID;

    vMandatoryCodeId PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type;
    vSequence        PAC_MANDATORY_CODE.PMC_SEQUENCE%type;
  begin
    vSequence  := 0;

    /*Réception et parcours selon séquence / Id des codes libres du type d'événement*/
    open TypeMandatoryCode;

    fetch TypeMandatoryCode
     into vMandatoryCodeId;

    while TypeMandatoryCode%found loop
      vSequence  := vSequence + 10;   --Incrément de la séquence par pas de 10

      update PAC_MANDATORY_CODE   --Mise à jour de la séquence
         set PMC_SEQUENCE = vSequence
       where PAC_MANDATORY_CODE_ID = vMandatoryCodeId;

      fetch TypeMandatoryCode
       into vMandatoryCodeId;
    end loop;
  end OrderMandatoryCodeBySequence;

  /**
  * Description
  *    Retourne le type d'adresse par défaut
  */
  function GET_ADDRESS_TYPE
    return varchar2
  is
    DEFAULT_ADDRESS_TYPE DIC_ADDRESS_TYPE.DIC_ADDRESS_TYPE_ID%type;
  begin
    select nvl(max(DIC_ADDRESS_TYPE_ID), '')
      into DEFAULT_ADDRESS_TYPE
      from DIC_ADDRESS_TYPE
     where DAD_DEFAULT = 1;

    return DEFAULT_ADDRESS_TYPE;
  end GET_ADDRESS_TYPE;

  /**
  * Description
  *    Ramène Nom, Prénom, Localité de l'adresse par défaut
  */
  function GetNamesAndCity(aPAC_PERSON_ID PAC_PERSON.PAC_PERSON_ID%type)
    return varchar2
  is
    name      PAC_PERSON.PER_NAME%type;
    FORENAME  PAC_PERSON.PER_FORENAME%type;
    CITY      PAC_ADDRESS.ADD_CITY%type;
    str1      varchar2(153);
    strResult varchar2(100);
  begin
    select PER_NAME
         , PER_FORENAME
      into name
         , FORENAME
      from PAC_PERSON
     where PAC_PERSON_ID = aPAC_PERSON_ID;

    select max(ADD_CITY)
      into CITY
      from PAC_ADDRESS
     where PAC_PERSON_ID = aPAC_PERSON_ID
       and DIC_ADDRESS_TYPE_ID = GET_ADDRESS_TYPE;

    str1       := name;

    if FORENAME is not null then
      str1  := str1 || ' ' || FORENAME;
    end if;

    if CITY is not null then
      str1  := str1 || ', ' || CITY;
    end if;

    strResult  := substr(str1, 1, 100);
    return strResult;
  end GetNamesAndCity;

  function GetCustomerCurrencyId(pPAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type)
    return number
  is
    cursor C1
    is
      select   acs_financial_currency_id
          from ACS_AUX_ACCOUNT_S_FIN_CURR a
             , PAC_custom_partner b
         where a.acs_auxiliary_account_id = b.acs_auxiliary_account_id
           and b.PAC_CUSTOM_PARTNER_ID = pPAC_CUSTOM_PARTNER_ID
      order by a.ASC_DEFAULT desc;

    vCurrId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    open c1;

    fetch c1
     into vCurrId;

    close c1;

    if vCurrId is null then
      vCurrId  := Acs_Function.GETLOCALCURRENCYID;
    end if;

    return vCurrId;
  end GetCustomerCurrencyId;

  /**
  * Description
  *   Retourne 1 ou 0 selon que le partenaire  gère une référence financière dont le type est donné
  */
  function IsPartnerFinancialRef(
    pPAC_PERSON_ID  PAC_PERSON.PAC_PERSON_ID%type
  , pIsCustomer     number
  , pCTypeReference PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE%type
  )
    return number
  is
    vResult number;
  begin
    if pIsCustomer = 1 then
      select decode(max(PAC_FINANCIAL_REFERENCE_ID), null, 0, 1)
        into vResult
        from PAC_FINANCIAL_REFERENCE FRE
           , PAC_CUSTOM_PARTNER CUS
       where CUS.PAC_CUSTOM_PARTNER_ID = pPAC_PERSON_ID
         and FRE.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
         and FRE.C_TYPE_REFERENCE = pCTypeReference;
    else
      select decode(max(PAC_FINANCIAL_REFERENCE_ID), null, 0, 1)
        into vResult
        from PAC_FINANCIAL_REFERENCE FRE
           , PAC_SUPPLIER_PARTNER SUP
       where SUP.PAC_SUPPLIER_PARTNER_ID = pPAC_PERSON_ID
         and FRE.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
         and FRE.C_TYPE_REFERENCE = pCTypeReference;
    end if;

    return vResult;
  end IsPartnerFinancialRef;

  /**
  * Description
  *   Retourne true si le tiers gère les tarifs par assortiment
  */
  function IsTariffBySet(aThirdId PAC_THIRD.PAC_THIRD_ID%type, aAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type)
    return number
  is
    result number(1);
  begin
    if aThirdId is not null then
      if aAdminDomain = '1' then
        select CRE_TARIFF_BY_SET
          into result
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = aThirdId;
      elsif aAdminDomain = '2' then
        select CUS_TARIFF_BY_SET
          into result
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = aThirdId;
      end if;
    end if;

    return result;
  end IsTariffBySet;

  /**
  * Description
  *   Retourne true si le partenaire de l'échéance aACT_EXPIRY_ID possède une
  *   réf. financière nécessaire pour un paiement avec le type de support aC_TYPE_SUPPORT.
  */
  function CheckPartnerFinRefForPayment(
    aACT_EXPIRY_ID  ACT_EXPIRY.ACT_EXPIRY_ID%type
  , aC_TYPE_SUPPORT ACS_PAYMENT_METHOD.C_TYPE_SUPPORT%type
  )
    return number
  is
    result  number(1)                                           := 1;
    cust_id PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type;
    supp_id PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
  begin
    if aC_TYPE_SUPPORT in('22', '23', '24') then
      select EXP_PAC_SUPPLIER_PARTNER_ID
           , EXP_PAC_CUSTOM_PARTNER_ID
        into supp_id
           , cust_id
        from ACT_EXPIRY
       where ACT_EXPIRY.ACT_EXPIRY_ID = aACT_EXPIRY_ID;

      if aC_TYPE_SUPPORT in('22', '24') then
        --DTA, DTAUS
        select nvl(max(1), 0)
          into result
          from PAC_FINANCIAL_REFERENCE
         where (    (    supp_id is not null
                     and PAC_FINANCIAL_REFERENCE.PAC_SUPPLIER_PARTNER_ID = supp_id)
                or (    cust_id is not null
                    and PAC_FINANCIAL_REFERENCE.PAC_CUSTOM_PARTNER_ID = cust_id)
               )
           and PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE = 1
           and PAC_FINANCIAL_REFERENCE.C_PARTNER_STATUS <> 0
           and rownum = 1;
      elsif aC_TYPE_SUPPORT = '23' then
        -- OPAE
        select nvl(max(1), 0)
          into result
          from PAC_FINANCIAL_REFERENCE
         where (    (    supp_id is not null
                     and PAC_FINANCIAL_REFERENCE.PAC_SUPPLIER_PARTNER_ID = supp_id)
                or (    cust_id is not null
                    and PAC_FINANCIAL_REFERENCE.PAC_CUSTOM_PARTNER_ID = cust_id)
               )
           and PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE = 2
           and PAC_FINANCIAL_REFERENCE.C_PARTNER_STATUS <> 0
           and rownum = 1;
      end if;
    elsif aC_TYPE_SUPPORT in('21', '25', '28') then
      --LCR, LSVFrench, AFB
      select nvl(max(1), 0)
        into result
        from PAC_FINANCIAL_REFERENCE
           , ACT_PART_IMPUTATION
           , ACT_EXPIRY
       where ACT_EXPIRY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID = ACT_EXPIRY.ACT_PART_IMPUTATION_ID
         and PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID = ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID
         and PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE in(1, 4, 5)
         and PAC_FINANCIAL_REFERENCE.C_PARTNER_STATUS <> 0
         and rownum = 1;
    end if;

    return result;
  end CheckPartnerFinRefForPayment;

  /**
  * Description
  *   Retourne true si le partenaire de l'échéance aACT_EXPIRY_ID possède une
  *   réf. financière nécessaire pour un paiement avec la méthode de paiement aACS_PAYMENT_METHOD_ID.
  */
  function CheckPartnerFinRefForPayment(
    aACT_EXPIRY_ID         ACT_EXPIRY.ACT_EXPIRY_ID%type
  , aACS_PAYMENT_METHOD_ID ACS_PAYMENT_METHOD.ACS_PAYMENT_METHOD_ID%type
  )
    return number
  is
    type_support ACS_PAYMENT_METHOD.C_TYPE_SUPPORT%type;
  begin
    select max(C_TYPE_SUPPORT)
      into type_support
      from ACS_PAYMENT_METHOD
     where ACS_PAYMENT_METHOD_ID = aACS_PAYMENT_METHOD_ID;

    return CheckPartnerFinRefForPayment(aACT_EXPIRY_ID, type_support);
  end CheckPartnerFinRefForPayment;

  /**
  * Description
  *        Supprime tout le texte qui est avant le mot clé
  *
  function ClearSqlHeader4Xml(pExtractFromSql long, pStartKey varchar2)
    return long
  is
    vStartPos number;
  begin
    vStartPos := InStr(pExtractFromSql, pStartKey);
    if vStartPos > 0 then
      return SubStr(pExtractFromSql, vStartPos, length(pExtractFromSql));
    else
      return pExtractFromSql;
    end if;
  end ClearSqlHeader4Xml; */

  /**
  * Description
  *        Recherche de l'ID correspondant à la clé pour l'utilisateur
  *        Si pas de config xml retourne 0, autrement PAC_CONFIG_XML_ID
  */
  function GetSearchXmlKeyID(
    pConfigCode   PAC_CONFIG.C_PAC_CONFIG%type
  , pUserId       PAC_CONFIG.PC_USER_ID%type
  , pPropertyName PAC_CONFIG.CON_VALUES%type
  )
    return PAC_CONFIG_XML.PAC_CONFIG_XML_ID%type
  is
    vPacConfigXmlId PAC_CONFIG_XML.PAC_CONFIG_XML_ID%type;
    vConfigValues   PAC_CONFIG.CON_VALUES%type;
    vPacConfigId    PAC_CONFIG_XML.PAC_CONFIG_ID%type;
    vPropertyPos    number;
    vKeyXml         varchar2(500);
  begin
    vPropertyPos     := 0;
    vConfigValues    := '';
    vPacConfigXmlId  := 0;
    vPacConfigId     := 0;
    --Recherche de la clé + PAC_CONFIG_ID
    GetConfigProperties(pConfigCode, pUserId, pPropertyName, vPropertyPos, vConfigValues, vPacConfigId);
    vKeyXml          := ExtractPropertyVal(vConfigValues, vPropertyPos);

    if     (length(vKeyXml) > 0)
       and (vPacConfigId > 0) then
      select nvl(max(CXM.PAC_CONFIG_XML_ID), 0)
        into vPacConfigXmlId
        from PAC_CONFIG_XML CXM
       where CXM.PAC_CONFIG_ID = vPacConfigId
         and upper(CXM.CXM_KEY) = upper(vKeyXml);
    end if;

    return vPacConfigXmlId;
  end GetSearchXmlKeyID;

  /**
  * Description
  *        Retourne les valeurs pour l'utilisateur de la config PAC
  */
  procedure GetConfigProperties(
    pConfigCode       PAC_CONFIG.C_PAC_CONFIG%type
  , pUserId           PAC_CONFIG.PC_USER_ID%type
  , pPropertyName     PAC_CONFIG.CON_VALUES%type
  , pPropertyPos  out number
  , pConfigValues out PAC_CONFIG.CON_VALUES%type
  , pPacConfigId  out PAC_CONFIG.PAC_CONFIG_ID%type
  )
  is
  begin
    begin
      if pUserId is null then
        select instr(upper(CON_VALUES), upper(pPropertyName), 1, 1)
             , CON_VALUES
             , PAC_CONFIG_ID
          into pPropertyPos
             , pConfigValues
             , pPacConfigId
          from PAC_CONFIG
         where C_PAC_CONFIG = pConfigCode
           and PC_USER_ID is null;
      elsif not pUserId is null then
        begin
          select instr(upper(CON_VALUES), upper(pPropertyName), 1, 1)
               , CON_VALUES
               , PAC_CONFIG_ID
            into pPropertyPos
               , pConfigValues
               , pPacConfigId
            from PAC_CONFIG
           where C_PAC_CONFIG = pConfigCode
             and PC_USER_ID = pUserId;
        exception
          when no_data_found then
            select instr(upper(CON_VALUES), upper(pPropertyName), 1, 1)
                 , CON_VALUES
                 , PAC_CONFIG_ID
              into pPropertyPos
                 , pConfigValues
                 , pPacConfigId
              from PAC_CONFIG
             where C_PAC_CONFIG = pConfigCode
               and PC_USER_ID is null;
        end;
      end if;
    exception
      when no_data_found then
        pConfigValues  := '';
        pPacConfigId   := 0;
        pPropertyPos   := -1;
    end;
  end GetConfigProperties;

  /**
  * Description
  *        Extrait la valeur de la chaine de caractère
  */
  function ExtractPropertyVal(pConfigValues PAC_CONFIG.CON_VALUES%type, pPropertyPos number)
    return varchar2
  is
    cursor curConfigLines(pConfigValues PAC_CONFIG.CON_VALUES%type, pStartPos number)
    is
      /**
      * Réception d'une sous-chaîne de la chaîne pConfigValues de la position pStartPos
      * jusqu'au prochain <CR> ou fin de fichier
      **/
      select substr(pConfigValues
                  , pStartPos
                  , decode(instr(pConfigValues, chr(10), pStartPos, 1)
                         , 0, length(pConfigValues)
                         , instr(pConfigValues, chr(10), pStartPos, 1) - pStartPos
                          )
                   )
        from dual;

    cursor curConfigValues(pConfigLine varchar2)
    is
      /**
      * Réception de la partie située à droite du signe '=' correspondant à la valeur de la config
      * jusqu'au prochain <CR> ou fin de fichier
      **/
      select substr(pConfigLine, instr(pConfigLine, '=', 1, 1) + 1, length(pConfigLine) )
        from dual;

    vPropertyLine varchar2(500);
    vResult       varchar2(500);
  begin
    vResult  := '';

    if pPropertyPos > 0 then   --La propriété existe dans la config
      /**
      *  Réception de la ligne du paramètre recherché
      **/
      open curConfigLines(pConfigValues, pPropertyPos);

      fetch curConfigLines
       into vPropertyLine;

      close curConfigLines;

      /**
      *  Réception de la valeur du paramètre recherché
      **/
      open curConfigValues(vPropertyLine);

      fetch curConfigValues
       into vResult;

      close curConfigValues;
    end if;

    return vResult;
  end;

  /**
  * Description
  *        Retour de la valeur de la config PAC
  */
  function GetConfigPropertyVal(
    pConfigCode   PAC_CONFIG.C_PAC_CONFIG%type
  , pUserId       PAC_CONFIG.PC_USER_ID%type
  , pPropertyName PAC_CONFIG.CON_VALUES%type
  )
    return varchar2
  is
    vResult       PAC_CONFIG.CON_VALUES%type;
    vPropertyLine varchar2(500);
    vPropertyPos  number;
    vConfigValues PAC_CONFIG.CON_VALUES%type;
    vPacConfigId  PAC_CONFIG.PAC_CONFIG_ID%type;
  begin
    vResult  := '';
    GetConfigProperties(pConfigCode, pUserId, pPropertyName, vPropertyPos, vConfigValues, vPacConfigId);
    vResult  := ExtractPropertyVal(vConfigValues, vPropertyPos);
    return vResult;
  end GetConfigPropertyVal;

  /**
  *  Retour du numéro de téléphone formaté selon codes internationales
  **/
  function FormatInternationalPhoneNumber(
    pLocalPhoneNumber          varchar2
  , pCountryCode               PCS.PC_CNTRY.CNT_CC%type
  , pCountryDialNumber         PCS.PC_CNTRY.CNT_IDD%type
  , pExternalCallDigits        varchar2
  , pInternalPhoneNumberLength number
  )
    return PAC_COMMUNICATION.COM_INTERNATIONAL_NUMBER%type
  is
    vCharCounter number(2);
    vResult      varchar2(100);

    function IntE164(pPhoneNumber varchar2, pCntryCode PCS.PC_CNTRY.CNT_CC%type)
      return varchar2
    is
      vResult varchar2(100);
    begin
      vResult  := trim(pPhoneNumber);

      /**
      * Si numéro commence par le code pays et que un '0' se trouve àprès ce code et
      * que un chiffre > 0 se trouve en core après ce '0', on supprime le '0'
      **/
      if     (substr(vResult,(1 + length(pCntryCode) ), 1) = '0')
         and (substr(vResult,(1 + length(pCntryCode) + 1), 1) in('0', '1', '2', '3', '4', '5', '6', '7', '8', '9') ) then
        vResult  := substr(vResult, 1, length(pCntryCode) ) || substr(vResult, length(pCntryCode) + 2, length(vResult) );
      end if;

      return vResult;
    end;
  begin
    vCharCounter  := 1;

    /**
    * Seuls les caractère 0..9 et + sont acceptés ; + n'est accepté qu'une seule fois
    * et comme premier caractère.
    **/
    while vCharCounter <= length(pLocalPhoneNumber) loop
      if     substr(pLocalPhoneNumber, vCharCounter, 1) = '+'
         and (vCharCounter = 1) then
        vResult  := vResult || substr(pLocalPhoneNumber, vCharCounter, 1);
      elsif substr(pLocalPhoneNumber, vCharCounter, 1) in('0', '1', '2', '3', '4', '5', '6', '7', '8', '9') then
        vResult  := vResult || substr(pLocalPhoneNumber, vCharCounter, 1);
      end if;

      vCharCounter  := vCharCounter + 1;
    end loop;

    /**
    *  Longueur de la chaîne supérieure à la longueur des numéros internes
    **/
    if length(trim(vResult) ) > pInternalPhoneNumberLength then
      if substr(vResult, 1, 1) = '+' then
        vResult  := substr(vResult, 2, length(vResult) );   --Suppression du '+' si celui-ci occupe la première place

        if instr(vResult, pCountryCode) = 1 then
          vResult  := IntE164(vResult, pCountryCode);
--        else  --Erreur un n° commençant par +  et non suivi du code pays est faux !!
        end if;
      elsif instr(vResult, pExternalCallDigits || pCountryDialNumber) = 1 then
        vResult  := substr(vResult, 1 + length(pExternalCallDigits || pCountryDialNumber), length(vResult) );   --Suppression des codes de sortie si en première place

        if instr(vResult, pCountryCode) = 1 then
          vResult  := IntE164(vResult, pCountryCode);
        end if;

        vResult  := IntE164(vResult, pCountryCode);
      else
        if length(pExternalCallDigits) > 0 then
          vResult  :=
                    substr(vResult, instr(vResult, pExternalCallDigits) + length(pExternalCallDigits), length(vResult) );   --Suppression du code de la centrale si existant
        end if;

        if instr(vResult, pCountryDialNumber) = 1 then
          vResult  := substr(vResult, 1 + length(pCountryDialNumber), length(vResult) );   --Suppression du code de sortie pays

          if instr(vResult, pCountryCode) = 1 then
            vResult  := IntE164(vResult, pCountryCode);
          end if;
        else
          if     (substr(vResult, 1, 1) = '0')
             and (substr(vResult, 2, 1) in('1', '2', '3', '4', '5', '6', '7', '8', '9') ) then
            vResult  := substr(vResult, 2, length(vResult) );
          end if;

          vResult  := pCountryCode || vResult;
        end if;
      end if;
    end if;

    return trim(vResult);
  end FormatInternationalPhoneNumber;

  /**
  * Description
  *  Comparaison de deux chaines de caractères avec uniquement les chiffres 0-9 et les lettres a..z, A..Z
  */
  function CompValidChars(pReference varchar2, pComparison varchar2)
    return integer
  is
    vResult     integer;
    vReference  varchar2(2000);
    vComparison varchar2(2000);

    function CheckValidChar(pText varchar2)
      return varchar2
    is
      vIndex  pls_integer    := 1;
      vResult varchar2(2000) := '';
    begin
      while vIndex <= length(pText) loop
        if    (substr(pText, vIndex, 1) between 'A' and 'Z')
           or (substr(pText, vIndex, 1) between '0' and '9') then
          vResult  := concat(vResult, substr(pText, vIndex, 1) );
        end if;

        vIndex  := vIndex + 1;
      end loop;

      return vResult;
    end CheckValidChar;
  begin
    vReference   := upper(pReference);
    vComparison  := upper(pComparison);

    if vReference = vComparison then
      vResult  := 1;
    else
      vReference   := CheckValidChar(vReference);
      vComparison  := CheckValidChar(vComparison);

      if vReference = vComparison then
        vResult  := 1;
      else
        vResult  := 0;
      end if;
    end if;

    return vResult;
  end CompValidChars;

  /**
  * Description   Procedure de contrôle de cohérence de toutes les conditions de paiement
  **/
  procedure PayementConditionsCtrl(
    pErrorText          out varchar2
  , pPaymentConditionId out PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type
  , pPcoDescr out PAC_PAYMENT_CONDITION.PCO_DESCR%type
  , pPaymentConditionKind out PAC_PAYMENT_CONDITION.C_PAYMENT_CONDITION_KIND%type
  )
  is
    cursor crPaymentCondition
    is
      select PAC_PAYMENT_CONDITION_ID
           , PCO_DESCR
           , C_PAYMENT_CONDITION_KIND
        from PAC_PAYMENT_CONDITION;
     tplPaymentCondition       crPaymentCondition%rowtype;
   begin
    pErrorText := '';
    pPaymentConditionId := 0.0;

    open crPaymentCondition;
    fetch crPaymentCondition
     into tplPaymentCondition;

    while(crPaymentCondition%found) loop
      PAC_FUNCTIONS.CtrlDetailParity(tplPaymentCondition.PAC_PAYMENT_CONDITION_ID, pErrorText);
      if pErrorText is not null then
        pPaymentConditionId := tplPaymentCondition.PAC_PAYMENT_CONDITION_ID;
        pPcoDescr := tplPaymentCondition.PCO_DESCR;
        pPaymentConditionKind := tplPaymentCondition.C_PAYMENT_CONDITION_KIND;
        Exit;
      end if;

      fetch crPaymentCondition
       into tplPaymentCondition;
    end loop;
    close crPaymentCondition;
  end PayementConditionsCtrl;

  /**
  * Description   Procedure de contrôle de cohérence des détails de conditions de paiement
  **/
  procedure CtrlDetailParity(
    pPaymentConditionId in PAC_CONDITION_DETAIL.PAC_PAYMENT_CONDITION_ID%type
  , pErrorText          out varchar2
  )
  is
    cursor crConditionDetail(pPaymentConditionId PAC_CONDITION_DETAIL.PAC_PAYMENT_CONDITION_ID%type)
    is
      select   PCO.C_INVOICE_EXPIRY_INPUT_TYPE
             , PCO.C_PAYMENT_CONDITION_KIND
             , CDE.*
          from PAC_CONDITION_DETAIL CDE
             , PAC_PAYMENT_CONDITION PCO
         where PCO.PAC_PAYMENT_CONDITION_ID = pPaymentConditionId
           and CDE.PAC_PAYMENT_CONDITION_ID = PCO.PAC_PAYMENT_CONDITION_ID
      order by CDE.CDE_PART asc
             , decode(CDE.C_TIME_UNIT, 1, CDE.CDE_DAY * 30, CDE.CDE_DAY) asc
             , CDE.CDE_DISCOUNT_RATE desc;

    tplConditionDetail        crConditionDetail%rowtype;
    vTimeUnit                 number;   --Réceptionne unité de temps en jours
    Jours                     PAC_CONDITION_DETAIL.CDE_DAY%type;
    Proportion                PAC_CONDITION_DETAIL.CDE_ACCOUNT%type;
    Escompte                  PAC_CONDITION_DETAIL.CDE_DISCOUNT_RATE%type;
    Tranche                   PAC_CONDITION_DETAIL.CDE_PART%type;
    old_Tranche               PAC_CONDITION_DETAIL.CDE_PART%type;
    vErrorText                varchar2(500);
    vblnMandatoryDocTypeExist boolean;
  begin
    vErrorText  := '';

    open crConditionDetail(pPaymentConditionId);

    fetch crConditionDetail
     into tplConditionDetail;

    if crConditionDetail%found then
      vblnMandatoryDocTypeExist  := false;
      Tranche                    := 1;
      Old_Tranche                := 1;
      Jours                      := tplConditionDetail.CDE_DAY;

      if tplConditionDetail.C_TIME_UNIT = '1' then
        Jours  := Jours * 30;
      end if;

      Proportion                 := tplConditionDetail.CDE_ACCOUNT;
      Escompte                   := 101;

      while crConditionDetail%found loop
        if tplConditionDetail.C_TIME_UNIT = '1' then
          vTimeUnit  := 30;
        else
          vTimeUnit  := 1;
        end if;

        if tplConditionDetail.CDE_PART <> Tranche then
          if     (tplConditionDetail.C_PAYMENT_CONDITION_KIND = '01')
             and (Escompte <> 0) then
              vErrorText  :=
                          PCS.PC_FUNCTIONS.TranslateWord('Une erreur concernant le taux d''escompte a été rencontrée!');
          end if;

          Proportion  := tplConditionDetail.CDE_ACCOUNT;
          Tranche     := Tranche + 1;
          Jours       := tplConditionDetail.CDE_DAY * vTimeUnit;

          if tplConditionDetail.CDE_PART <> Tranche then
              vErrorText  :=
                       PCS.PC_FUNCTIONS.TranslateWord('Une erreur concernant les numéros de tranche a été rencontrée!');
          end if;
        end if;

        if Proportion = 0 then
          vErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Aucune proportion ne peut-être à zéro !');
        end if;

        if tplConditionDetail.CDE_ACCOUNT <> Proportion then
            vErrorText  :=
              PCS.PC_FUNCTIONS.TranslateWord
                         ('Une erreur concernant des différences dans les proportions d''une tranche a été rencontrée!');
        end if;

        if tplConditionDetail.C_PAYMENT_CONDITION_KIND = '01' then
          if Escompte <> tplConditionDetail.CDE_DISCOUNT_RATE then
            Escompte  := tplConditionDetail.CDE_DISCOUNT_RATE;
          else
            if Tranche = old_Tranche then
                vErrorText  :=
                          PCS.PC_FUNCTIONS.TranslateWord('Une erreur concernant le taux d''escompte a été rencontrée!');
            else
              Jours  := tplConditionDetail.CDE_DAY * vTimeUnit;
            end if;
          end if;
        end if;

        if Jours <=(tplConditionDetail.CDE_DAY * vTimeUnit) then
          Jours  := tplConditionDetail.CDE_DAY * vTimeUnit;
        else
          vErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Une erreur concernant les jours a été rencontrée!');
        end if;

        Old_Tranche  := tplConditionDetail.CDE_PART;

        if tplConditionDetail.C_PAYMENT_CONDITION_KIND = '02' then
          if     (tplConditionDetail.C_INVOICE_EXPIRY_INPUT_TYPE = '1')
             and (    (tplConditionDetail.C_INVOICE_EXPIRY_DOC_TYPE = '4')
                    or (tplConditionDetail.C_INVOICE_EXPIRY_DOC_TYPE = '5')
                   ) then
              vErrorText  :=
                PCS.PC_FUNCTIONS.TranslateWord
                                        ('Une erreur concernant les types de document de facturation a été rencontrée!');
          end if;

          if tplConditionDetail.C_INVOICE_EXPIRY_DOC_TYPE = '3' then
            vblnMandatoryDocTypeExist  := true;
          end if;
        end if;

        Exit when vErrorText is not null;

        fetch crConditionDetail
         into tplConditionDetail;
      end loop;

      if vErrorText is null then
        if     (tplConditionDetail.C_PAYMENT_CONDITION_KIND = '01')
           and (Escompte <> 0) then
            vErrorText  :=
                          PCS.PC_FUNCTIONS.TranslateWord('Une erreur concernant le taux d''escompte a été rencontrée!');
        end if;

        if     (tplConditionDetail.C_PAYMENT_CONDITION_KIND = '02')
           and (not vblnMandatoryDocTypeExist) then
          vErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Une position de type 3 (Facture finale) est obligatoire!');
        end if;
      end if;
    else
      vErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Une erreur concernant la saisie des données a été rencontrée!');
    end if;

    pErrorText  := vErrorText;
    close crConditionDetail;
  end CtrlDetailParity;

  /**
  * Description
  *    retourne le type de condition
  **/
  function getPayCondKind(aPaymentConditionId in PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type)
    return PAC_PAYMENT_CONDITION.C_PAYMENT_CONDITION_KIND%type
  is
    vResult PAC_PAYMENT_CONDITION.C_PAYMENT_CONDITION_KIND%type;
  begin
    if aPaymentConditionId is not null then
      select C_PAYMENT_CONDITION_KIND
        into vResult
        from PAC_PAYMENT_CONDITION
       where PAC_PAYMENT_CONDITION_ID = aPaymentConditionId;
    end if;

    return vResult;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * Description
  *    retourne l'address complète du client
  **/
  function getCustomerFormatAddress(iPacPersonId in PAC_PERSON.PAC_PERSON_ID%type)
    return varchar2
  is
    lvDicPersonPolitness DIC_PERSON_POLITNESS.DPO_DESCR%type;
    lvPerName            PAC_PERSON.PER_NAME%type;
    lvPerForname         PAC_PERSON.PER_FORENAME%type;
    lvPerActivity        PAC_PERSON.PER_ACTIVITY%type;
    lvAddAddress1        PAC_ADDRESS.ADD_FORMAT%type;
    lvAddFormat          PAC_ADDRESS.ADD_FORMAT%type;

    lvResult             varchar2(4000);
  begin
    select case
           when nvl(PER.PER_CONTACT,0) = 1 then
             COM_DIC_FUNCTIONS.GetDicoDescr('DIC_PERSON_POLITNESS'
                                           , PER.DIC_PERSON_POLITNESS_ID
                                           , pcs.PC_I_LIB_SESSION.GetUserLangId)
           else
             ''
          end PERSON_POLITNESS
        , PER.PER_NAME
        , PER.PER_FORENAME
        , PER.PER_ACTIVITY
        , ADR.ADD_ADDRESS1
        , ADR.ADD_FORMAT
    into lvDicPersonPolitness
       , lvPerName
       , lvPerForname
       , lvPerActivity
       , lvAddAddress1
       , lvAddFormat
    from PAC_PERSON PER
       , PAC_ADDRESS ADR
   where PER.PAC_PERSON_ID = iPacPersonId
     and PER.PAC_PERSON_ID = ADR.PAC_PERSON_ID
     and ADR.ADD_PRINCIPAL = 1;

    if lvDicPersonPolitness <> '' then
      lvResult := lvDicPersonPolitness || chr(13);
    end if;

    lvResult := lvResult || lvPerName;

    if lvPerForname <> '' then
      lvResult := lvResult || ' ' || lvPerForname;
    end if;

    if lvPerActivity <> '' then
      lvResult := lvResult || chr(13) || lvPerActivity;
    end if;

    lvResult := lvResult || chr(13) || lvAddAddress1 || chr(13) ||
                lvAddFormat;

    return lvResult;
  exception
  when no_data_found then
    return null;
  end getCustomerFormatAddress;

  /**
  * Description
  *    retourne les informations du client
  **/
  function getCustomerCommunication(iPacPersonId in PAC_PERSON.PAC_PERSON_ID%type)
    return varchar2
  is
    lvDicCommunicationTypeId PAC_COMMUNICATION.DIC_COMMUNICATION_TYPE_ID%type;
    lvComAreaCode            PAC_COMMUNICATION.COM_AREA_CODE%type;
    lvComNumber              PAC_COMMUNICATION.COM_EXT_NUMBER%type;

    lvResult                 varchar2(4000);
  begin
    select DIC_COMMUNICATION_TYPE_ID
         , COM_AREA_CODE
         , nvl(COM_EXT_NUMBER, COM_INT_NUMBER) COM_NUMBER
      into lvDicCommunicationTypeId
         , lvComAreaCode
         , lvComNumber
      from PAC_COMMUNICATION COM
     where PAC_PERSON_ID = iPacPersonId
       and COM_PREFERRED_CONTACT = 1;

    lvResult := lvDicCommunicationTypeId || ' : ';

    if lvComAreaCode <> '' then
      lvResult := lvResult || lvComAreaCode || ' ';
    end if;

    lvResult := lvResult || lvComNumber;

    return lvResult;
  exception
  when no_data_found then
    return null;
  end getCustomerCommunication;

  /**
  * Description
  *    retourne le commentaire de contact
  **/
  function getCustomerComment(iPacPersonId in PAC_PERSON.PAC_PERSON_ID%type)
    return varchar2
  is
    lvComComment PAC_COMMUNICATION.COM_COMMENT%type;
  begin
    select COM_COMMENT
      into lvComComment
      from PAC_COMMUNICATION COM
     where PAC_PERSON_ID = iPacPersonId
       and COM_PREFERRED_CONTACT = 1;

    return lvComComment;
  exception
  when no_data_found then
    return null;
  end getCustomerComment;
end PAC_FUNCTIONS;
