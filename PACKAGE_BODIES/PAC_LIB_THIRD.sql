--------------------------------------------------------
--  DDL for Package Body PAC_LIB_THIRD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_LIB_THIRD" 
is

  /**
  * function GetPersonIdfromPerKey1
  * Description
  *    Retourne l'id d'une personne en fonction de la clef PER_KEY1
  * @created fp 07.09.2011
  * @lastUpdate
  * @public
  * @param @iPerKey1
  * @return voir description
  */
  function GetPersonIdfromPerKey1(iPerKey1 PAC_PERSON.PER_KEY1%type)
    return PAC_PERSON.PAC_PERSON_ID%type
  is
    lResult PAC_PERSON.PAC_PERSON_ID%type;
  begin
    if iPerKey1 is not null then
      select PAC_PERSON_ID
        into lResult
        from PAC_PERSON PER
       where PER.PER_KEY1 = iPerKey1;
    end if;
    return lResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end GetPersonIdfromPerKey1;

  /**
  * function GetThirdIdfromPerKey1
  * Description
  *    Retourne l'id d'un fournisseur en fonction de la clef PER_KEY1
  * @created fp 07.09.2011
  * @lastUpdate
  * @public
  * @param @iPerKey1
  * @return voir description
  */
  function GetThirdIdfromPerKey1(iPerKey1 PAC_PERSON.PER_KEY1%type)
    return PAC_THIRD.PAC_THIRD_ID%type
  is
    lResult PAC_THIRD.PAC_THIRD_ID%type;
  begin
    if iPerKey1 is not null then
      select PAC_THIRD_ID
        into lResult
        from PAC_PERSON PER,
             PAC_THIRD THI
       where PER.PER_KEY1 = iPerKey1
         and PER.PAC_PERSON_ID = THI.PAC_THIRD_ID;
    end if;
    return lResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end GetThirdIdfromPerKey1;


  /**
  * function GetCustomerIdfromPerKey1
  * Description
  *    Retourne l'id d'un client en fonction de la clef PER_KEY1
  * @created fp 07.09.2011
  * @lastUpdate
  * @public
  * @param @iPerKey1
  * @return voir description
  */
  function GetCustomerIdfromPerKey1(iPerKey1 PAC_PERSON.PER_KEY1%type)
    return PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  is
    lResult PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type;
  begin
    if iPerKey1 is not null then
      select PAC_CUSTOM_PARTNER_ID
        into lResult
        from PAC_PERSON PER,
             PAC_CUSTOM_PARTNER CUS
       where PER.PER_KEY1 = iPerKey1
         and PER.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID;
    end if;
    return lResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end GetCustomerIdfromPerKey1;

  /**
  * function GetSupplierIdfromPerKey1
  * Description
  *    Retourne l'id d'un fournisseur en fonction de la clef PER_KEY1
  * @created fp 07.09.2011
  * @lastUpdate
  * @public
  * @param @iPerKey1
  * @return voir description
  */
  function GetSupplierIdfromPerKey1(iPerKey1 PAC_PERSON.PER_KEY1%type)
    return PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  is
    lResult PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
  begin
    if iPerKey1 is not null then
      select PAC_SUPPLIER_PARTNER_ID
        into lResult
        from PAC_PERSON PER,
             PAC_SUPPLIER_PARTNER SUP
       where PER.PER_KEY1 = iPerKey1
         and PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID;
    end if;
    return lResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end GetSupplierIdfromPerKey1;

  /**
  * Description
  *    Retourne l'id d'une condition d'expédition
  */
  function GetSendingContitionId(iSEN_KEY          in PAC_SENDING_CONDITION.PAC_SENDING_CONDITION_ID%type,
                                 iC_CONDITION_MODE in PAC_SENDING_CONDITION.C_CONDITION_MODE%type)
    return PAC_SENDING_CONDITION.PAC_SENDING_CONDITION_ID%type
  is
    lResult PAC_SENDING_CONDITION.PAC_SENDING_CONDITION_ID%type;
  begin
    select PAC_SENDING_CONDITION_ID
      into lResult
      from PAC_SENDING_CONDITION
     where SEN_KEY = iSEN_KEY
       and C_CONDITION_MODE = iC_CONDITION_MODE;
    return lResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end GetSendingContitionId;

  /**
  * Description
  *    recherche de l'identifiant d'une donnée de communication
  */
  function GetCommunicationId(iPAC_PERSON_ID in PAC_PERSON.PAC_PERSON_ID%type
                            , iDIC_COMMUNICATION_TYPE_ID in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
                            , iCOM_EXT_NUMBER in PAC_COMMUNICATION.COM_EXT_NUMBER%type)
    return PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type
  is
    lResult PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type;
  begin
    select PAC_COMMUNICATION_ID
      into lResult
      from PAC_COMMUNICATION
     where PAC_PERSON_ID = iPAC_PERSON_ID
       and DIC_COMMUNICATION_TYPE_ID = iDIC_COMMUNICATION_TYPE_ID
       and COM_EXT_NUMBER = iCOM_EXT_NUMBER;
    return lResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end GetCommunicationId;

  /**
  * Description
  *    recherche des infos de communication par défaut
  */
  function GetDefaultCommunication(iPAC_PERSON_ID in PAC_PERSON.PAC_PERSON_ID%type)
    return PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type
  is
    lResult PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type;
  begin
    select PAC_COMMUNICATION_ID
      into lResult
      from PAC_COMMUNICATION
     where PAC_PERSON_ID = iPAC_PERSON_ID
       and COM_PREFERRED_CONTACT = 1;
    return lResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end GetDefaultCommunication;

end PAC_LIB_THIRD;
