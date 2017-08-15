--------------------------------------------------------
--  DDL for Package Body WEB_PERSON_CREATE_EHOTLINE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_PERSON_CREATE_EHOTLINE" AS

FUNCTION getPersonPolitnessFromId (aPersId IN NUMBER,
            aMsg OUT VARCHAR2) RETURN NUMBER IS
dicId  PAC_PERSON.DIC_PERSON_POLITNESS_ID%type;
BEGIN
    aMsg:='';
    select DIC_PERSON_POLITNESS_ID into dicId
    from PAC_PERSON where PAC_PERSON_ID=aPersId;
    aMsg:=dicId;
    RETURN WEB_FUNCTIONS.RETURN_OK;
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN WEB_FUNCTIONS.RETURN_ERROR;
END;

/** control l existance  de person et recupere  perName et per_forename */
/** pour afficher nom prenom */
FUNCTION checkPersonFromId (aPersId IN NUMBER,
            aMsg OUT VARCHAR2) RETURN NUMBER IS
nb NUMBER(1);
perName PAC_PERSON.PER_NAME%type;
perforeName PAC_PERSON.PER_FORENAME%type;
BEGIN
 select count(*) into nb
  from
    PAC_PERSON
  where PAC_PERSON_ID=aPersId;
  aMsg:= nb;
  if (nb > 0) then begin
    select PER_NAME,PER_FORENAME into perName,perforeName
    from PAC_PERSON where PAC_PERSON_ID=aPersId;
    aMsg:= perName ||'|'||perforeName;
    RETURN WEB_FUNCTIONS.RETURN_OK;
  end;
  end if;
  RETURN WEB_FUNCTIONS.RETURN_ERROR;

END;


/*================================================================================
*  get DIC_COMMUNICATION_TYPE_ID  flag 0: E-Mail sinon  Tel. En fonction du schema
*  on peut lire par DCO_DESCR
*/

FUNCTION getDicCommunicationTypeId (aTypeComm IN NUMBER) RETURN VARCHAR2 IS

  oDicCommId DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type;

BEGIN
  if (aTypeComm=0) then
    select
      dic_communication_type_id
    into
      oDicCommId
    from
      dic_communication_type
    where
      dco_default3=1
      and dco_email=1;
  end if;

  if (aTypeComm=1) then
    select
      dic_communication_type_id
    into
      oDicCommId
    from
      dic_communication_type
    where
      dco_default1=1
      and dco_phone=1;
  end if;

  return oDicCommId;
END;

/*
*  return Pro, Dom,Liv,Sec,Fac,Rel etc...: index: 0 - Pro,1 - Dom,2 - Liv, etc...
*/
FUNCTION getDicAddressTypeId (aTypeComm IN NUMBER) RETURN VARCHAR2 IS

oDicAddrId DIC_ADDRESS_TYPE.DIC_ADDRESS_TYPE_ID%type;

BEGIN
  /*  29 04 2008  modif */
  oDicAddrId := 'Fac';

  select
    dic_address_type_id
  into
    oDicAddrId
  from
    DIC_ADDRESS_TYPE
  where
    dad_default=1;

  return oDicAddrId;

  EXCEPTION WHEN NO_DATA_FOUND THEN RETURN oDicAddrId;

END;

/*
 return 3: ok
 create pac_communication voir trigger !! dans PAC_COMMUNICATION
 aDicCommunicationTypeId soit: Tel soit E-Mail
 Attention:
 un dictionnaire dont les labels changent en fonction du schéma et Id aussi
*/

FUNCTION EHL_PAC_COMMUNICATION_CREATE (aPersonId IN NUMBER,
                                       aAddressId IN NUMBER,
                                       aDicCommunicationTypeId IN VARCHAR2,
                                       aComNumber IN VARCHAR2,
                                       newId OUT NUMBER) RETURN NUMBER IS
  BEGIN

  SELECT init_id_seq.NEXTVAL INTO newId FROM dual;

  INSERT INTO PAC_COMMUNICATION (
     PAC_COMMUNICATION_ID,
     PAC_PERSON_ID,
     PAC_ADDRESS_ID,
     DIC_COMMUNICATION_TYPE_ID,
     COM_EXT_NUMBER,
     A_DATECRE,
     A_IDCRE)
     VALUES (
     newId,
     aPersonId,
     aAddressId,
     aDicCommunicationTypeId,
     aComNumber,
     SYSDATE,
     'WEB');

     --RETURN 3;
     RETURN WEB_FUNCTIONS.RETURN_OK;

  EXCEPTION WHEN OTHERS THEN
    --RETURN 0;
    RETURN WEB_FUNCTIONS.RETURN_ERROR;
  --return 2;
  RETURN WEB_FUNCTIONS.RETURN_WARNING;

 END;

/*
 appellé par EHL_PAC_PERSON_CREATE
 une ligne E-Mail et Telephone create: attention DIC_COMMUNICATION_TYPE_ID  pas  DCO_DESCR
 En fonction du schema, les labels et les codes changent!!!!! voir la table DIC_COMMUNICATION_TYPE
 pour scpecifier l id Type: peut prendre les valeurs EM ou Tel. ou autre chose
 creer 2 lignes: mail et tel pour une personne.
*/
FUNCTION EHL_PAC_COMM_CREATE_ALL (aPersonId IN NUMBER,aAddressId IN NUMBER,
                                  aComNumberEmail IN VARCHAR2,
                                  aComNumberTel IN VARCHAR2,
      newId OUT NUMBER) RETURN NUMBER IS

  communicationTypeId DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type;
  retValue NUMBER(1);
  BEGIN

   /* E-Mail type Id */
   communicationTypeId := getDicCommunicationTypeId(0);
   retValue := EHL_PAC_COMMUNICATION_CREATE (aPersonId,
                                             aAddressId,
                                             communicationTypeId,
                                             aComNumberEmail,
                                             newId);
   --DBMS_OUTPUT.PUT_LINE('->COMM_CREATE_ALL newId='||newId);
  --DBMS_OUTPUT.PUT_LINE('->COMM_CREATE_ALL retValue='||retValue);

   if (retValue=WEB_FUNCTIONS.RETURN_OK) then
       /* Telephone type Id */
       communicationTypeId := getDicCommunicationTypeId(1);
       retValue := EHL_PAC_COMMUNICATION_CREATE (aPersonId,
                                                 aAddressId,
                                                 communicationTypeId,
                                                 aComNumberTel,
                                                 newId);
       if (retValue=WEB_FUNCTIONS.RETURN_OK) then
         return retValue;
      end if;

   end if;

   EXCEPTION WHEN OTHERS THEN
   --RETURN 0;
    RETURN WEB_FUNCTIONS.RETURN_ERROR;
  --return 2;
  RETURN WEB_FUNCTIONS.RETURN_WARNING;
  END;

/*
 Verification l existance de la personne avant de la creer
*/
FUNCTION EHL_PAC_PERSON_VERIFICATION (aPER_NAME IN VARCHAR2,
                                      aPER_FORENAME IN VARCHAR2,
                                      aPER_SHORT_NAME IN VARCHAR2,
                                      aDIC_PERSON_POLITNESS_ID IN VARCHAR2,
                                      aFonction IN VARCHAR2,
                                      oMsg OUT VARCHAR2) RETURN NUMBER IS
  n NUMBER(1);

  BEGIN
     n := 0;

     SELECT
       COUNT(*)
     INTO
       n
     FROM
       PAC_PERSON
    where PER_NAME=aPER_NAME
      and PER_FORENAME=aPER_FORENAME
      and PER_SHORT_NAME=aPER_SHORT_NAME
      and DIC_PERSON_POLITNESS_ID=aDIC_PERSON_POLITNESS_ID;

    IF (n=0) THEN
        oMsg := 'ok';
        RETURN 0;
    END IF;
    RETURN n;
 END;

 /* ===========================================================================
  return 3 : ok
  return 2 : personne existe
  create pac_person: java appelle cette seule fonction
 */
 FUNCTION EHL_PAC_PERSON_CREATE(aLangId IN NUMBER,
                                   aPER_NAME IN VARCHAR2,aPER_FORENAME IN VARCHAR2,
                                   aPER_SHORT_NAME IN VARCHAR2,
                                   aDIC_PERSON_POLITNESS_ID IN VARCHAR2,
                                   aFonction IN VARCHAR2,
                                   aIsoCode IN VARCHAR2,
                                   aPartnertId IN NUMBER,
                                   aComNumberEmail IN VARCHAR2,
                                   aComNumberTel IN VARCHAR2,
                                   msg OUT VARCHAR2) RETURN NUMBER IS
    retValue  NUMBER(1);
    newIdPer  NUMBER(12);
    newIdAddr NUMBER(12);
    newIdComm NUMBER(12);
    perComment PAC_PERSON.PER_COMMENT%type;
    distingName ECONCEPT.ECO_USERS.ECU_DISTINGUISHED_NAME%type;
    ecoUserId   ECONCEPT.ECO_USERS.ECO_USERS_ID%type;

   BEGIN
    msg := '0';
    newIdPer := NULL;
    perComment := 'eHotLine-CRM';
    retValue := EHL_PAC_PERSON_VERIFICATION (aPER_NAME,aPER_FORENAME,aPER_SHORT_NAME,aDIC_PERSON_POLITNESS_ID,aFonction,msg);
    IF (retValue > 0) THEN
      RETURN 200;
    END IF;

    msg:='->ok nom prenom not Found';

    SELECT nvl(max(PAC_PERSON_ID),0)+1 INTO newIdPer FROM PAC_PERSON;

    --SELECT init_id_seq.NEXTVAL INTO newIdPer FROM dual;

    msg:='->ok newIdPer='||newIdPer || ' PER_NAME='||aPER_NAME;
    msg:= msg ||' aDIC_PERSON_POLITNESS_ID='||aDIC_PERSON_POLITNESS_ID;

    INSERT INTO PAC_PERSON (
      PAC_PERSON_ID,
      DIC_PERSON_POLITNESS_ID,
      PER_NAME,
      PER_FORENAME,
      PER_SHORT_NAME,
      PER_ACTIVITY,
      PER_COMMENT,
      PER_CONTACT,
      A_DATECRE,
      A_IDCRE,
      C_PARTNER_STATUS)
    VALUES (newIdPer,
      aDIC_PERSON_POLITNESS_ID,
      aPER_NAME,aPER_FORENAME,
      aPER_SHORT_NAME,
      aFonction,
      perComment,
      1,SYSDATE,'WEB',1);

    msg:= 'Yes insert ok newIdPer='||newIdPer;

   --DBMS_OUTPUT.PUT_LINE('->PERSON_CREATE newIdPer='||newIdPer);

   if (newIdPer is not null and newIdPer > 0) then
     begin
       retValue := EHL_PAC_ADDRESS_CREATE (newIdPer,aLangId,aPartnertId,newIdAddr);
       msg:= 'ADDRESS_CREATE newIdAddr='||newIdAddr || ' retValue='||retValue;
       if (retValue=WEB_FUNCTIONS.RETURN_OK) then
         begin
           msg := newIdAddr||'';
           --DBMS_OUTPUT.PUT_LINE('->EHL_PAC_ADDRESS_CREATE retValue='||retValue);
         end;
         else begin
           msg := WEB_FUNCTIONS.RETURN_WARNING ||'adress error';
           /* attention  return si pas OK  */
           RETURN WEB_FUNCTIONS.RETURN_WARNING;
         end;
       end if;  /* end EHL_PAC_ADDRESS_CREATE */

       msg:= 'BEGIN COMM_CREATE_ALL aComNumberEmail='||aComNumberEmail;
       /* --------------------------------------------------------- */
       /*  creation communication mail, tel avec adressId ci dessus */
       /* --------------------------------------------------------- */
       retValue := EHL_PAC_COMM_CREATE_ALL (newIdPer,
                                            newIdAddr,
                                            aComNumberEmail,
                                            aComNumberTel,
                                            newIdComm);
        msg:= 'END COMM_CREATE_ALL aComNumberTel='||aComNumberTel || ' retValue='||retValue;

       if (retValue=WEB_FUNCTIONS.RETURN_OK) then
         begin
          /* recupere idPeson ou une autre table ! */
            msg :=  newIdPer || '';
            RETURN WEB_FUNCTIONS.RETURN_OK;   /* okay  return */
        end;  /* end   EHL_PAC_COMM_CREATE_ALL  */
        else
        return -1;
       end if;

   end;
   else msg:= 'newIdPer=0 ou null';
   end if;  /* end newIdPer > 0 */

   EXCEPTION WHEN OTHERS THEN
     RETURN WEB_FUNCTIONS.RETURN_ERROR;
   RETURN WEB_FUNCTIONS.RETURN_WARNING;

 END;


/*
 return 3 : ok
 create PAC_ADDRESS
*/
FUNCTION EHL_PAC_ADDRESS_CREATE (aPacPersonId IN NUMBER,
                                 aLangId IN NUMBER,
                                 aPartnertId IN NUMBER,
                                 newId OUT NUMBER) RETURN NUMBER IS

  dicAddressTypeId DIC_ADDRESS_TYPE.DIC_ADDRESS_TYPE_ID%type;
  lcomment PAC_ADDRESS.ADD_COMMENT%type;
  status PAC_ADDRESS.C_PARTNER_STATUS%type;
  retValue NUMBER(1);
  vCity    pac_address.ADD_CITY%type;
  contryId pcs.pc_cntry.pc_cntry_id%type;
  BEGIN

     lcomment := 'Address eHotline';
     status := '1';
     contryId:= 1;
     vCity:='';

     /** 0 */
     dicAddressTypeId:= getDicAddressTypeId (0);

     /**  08/2008  */
     /**  prendre countryId et city du client (depuis partnert Id) */
     select pc_cntry_id, add_city into contryId,vCity from (
         select pc_cntry_id, add_city
         from
           pac_address
         where pac_person_id=aPartnertId order by add_principal desc)
     where rownum=1;


     SELECT init_id_seq.NEXTVAL INTO newId FROM dual;

     INSERT INTO PAC_ADDRESS (
          PAC_ADDRESS_ID,
          PAC_PERSON_ID,
          PC_CNTRY_ID,
          PC_LANG_ID,
          ADD_CITY,
          DIC_ADDRESS_TYPE_ID,
          ADD_COMMENT,
          C_PARTNER_STATUS,
          A_DATECRE,
          A_IDCRE)
          VALUES (newId, aPacPersonId,contryId,aLangId,vCity,
          dicAddressTypeId,lcomment,status,SYSDATE,'WEB');

     --RETURN 3;
     RETURN WEB_FUNCTIONS.RETURN_OK;

    EXCEPTION WHEN OTHERS THEN
      --RETURN 0;
      RETURN WEB_FUNCTIONS.RETURN_ERROR;
    --return 2;
    RETURN WEB_FUNCTIONS.RETURN_WARNING;
END;

/*
 java appelle cette fonction: ne pas changer le nom de la fonction
*/
FUNCTION getTelephoneFromCommunication (aPacPersonId IN NUMBER,
                                        oNumPhone OUT VARCHAR2) RETURN NUMBER IS

dicCommunicationTypeId DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type;
retValue NUMBER(1);

BEGIN
   /* typeId telephone param = 1 */
   oNumPhone:='';

   dicCommunicationTypeId := getDicCommunicationTypeId(1);

   select
     COM_EXT_NUMBER
   into
     oNumPhone
   from
     PAC_COMMUNICATION
   where
     PAC_PERSON_ID=aPacPersonId
     and  DIC_COMMUNICATION_TYPE_ID=dicCommunicationTypeId;

   --return 3;
   RETURN WEB_FUNCTIONS.RETURN_OK;
   EXCEPTION WHEN NO_DATA_FOUND THEN
     --RETURN 1;
     RETURN WEB_FUNCTIONS.RETURN_FATAL;
END;

/*
 return 3 : ok
 java appelle cette fonction: ne pas changer le nom de la fonction
*/
FUNCTION updateTelephoneToCommunication (aPacPersonId IN NUMBER,
                                         aTelephone IN VARCHAR2,
                                         msg OUT VARCHAR2) RETURN NUMBER IS
dicCommunicationTypeId DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type;
retValue NUMBER(1);
BEGIN

   msg:='none';
   /* typeId telephone */
   dicCommunicationTypeId:= getDicCommunicationTypeId(1);

   UPDATE PAC_COMMUNICATION set COM_EXT_NUMBER=aTelephone,
   A_DATEMOD=SYSDATE,A_IDMOD='WEB'
   where PAC_PERSON_ID=aPacPersonId
   and  DIC_COMMUNICATION_TYPE_ID=dicCommunicationTypeId;
   msg:='ok';
   --return 3;
   RETURN WEB_FUNCTIONS.RETURN_OK;
   EXCEPTION WHEN OTHERS THEN
     --RETURN 0;
     RETURN WEB_FUNCTIONS.RETURN_ERROR;
   --return 2;
   RETURN WEB_FUNCTIONS.RETURN_WARNING;
END;


/*
* call par java pour l affichage
*/
FUNCTION getIsoCodeFromEMail (aEmail IN VARCHAR2,
                              eDisplayName IN VARCHAR2,
                              oIsoCode OUT VARCHAR2) RETURN NUMBER IS
BEGIN
  oIsoCode := '';

  select
    ECL_ISO_CODE
  into
    oIsoCode
  from
    ECONCEPT.ECO_USERS
  where
    lower(ECU_EMAIL)=aEmail and rownum=1;

  --return 3;
  RETURN WEB_FUNCTIONS.RETURN_OK;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    --RETURN 1;
    RETURN WEB_FUNCTIONS.RETURN_FATAL;
END;

/*  return 0 pas trouve sinon  return 3 ok */

FUNCTION existeECOMail (aEmail IN VARCHAR2,
                        msg OUT VARCHAR2) RETURN NUMBER IS

retValue NUMBER (1);
nb NUMBER;

BEGIN
  retValue:= 0;
  nb := 0;
  msg:='0';

  select
    count(*)
  into
    nb
  from
    ECONCEPT.ECO_USERS
  where
    lower(ECU_EMAIL)=aEmail;

  if (nb > 0) then begin
   msg:='3';
   --return 3; /* pas d insert */
   RETURN WEB_FUNCTIONS.RETURN_OK;
  end;
  end if;
  --return 0;
  RETURN WEB_FUNCTIONS.RETURN_ERROR;
END;



/*
Verif avant d iserer
retValue  rturn id si  existe sinon 0
aPersonId  id de  entreprise (ex: PubliMEd SA)
aPacPacPersonId  id d l user  (celui qui demande d itervention)
*/
FUNCTION existeAssociationContraints (aPersonId IN NUMBER,
                                      aPacPacPersonId IN NUMBER,
                                      aDicAssoTypeId IN VARCHAR2) RETURN NUMBER IS

nb  NUMBER (1);
BEGIN
   /*  return 0 si nouveau */
   nb := 0;
   if (aDicAssoTypeId is null or aDicAssoTypeId='?') then begin
     SELECT
       COUNT(*) INTO nb
     from
       PAC_PERSON_ASSOCIATION
     where
       PAC_PERSON_ID=aPersonId
       and PAC_PAC_PERSON_ID=aPacPacPersonId
       and DIC_ASSOCIATION_TYPE_ID is null;
   end;
   else
     SELECT
       COUNT(*) INTO nb
     from
       PAC_PERSON_ASSOCIATION
     where
       PAC_PERSON_ID=aPersonId
       and PAC_PAC_PERSON_ID=aPacPacPersonId
       and DIC_ASSOCIATION_TYPE_ID=aDicAssoTypeId;
   end if;
   return nb;
END;

/*
  Insert dans pac person association
*/
FUNCTION EHL_INSERT_PACPERASSOCIATION (aPersonId IN NUMBER,aPacPacPersonId IN NUMBER,
            aDicAssoTypeId IN VARCHAR2,msg OUT VARCHAR2) RETURN NUMBER IS
retValue NUMBER (1);
newId    NUMBER(12);
BEGIN

 msg := '0';
 retValue := existeAssociationContraints(aPersonId,aPacPacPersonId,aDicAssoTypeId);

 if (retValue is null or retValue=0) then begin
   /* insert ici  */
   SELECT init_id_seq.NEXTVAL INTO newId FROM dual;
   msg := newId||'';

   if (aDicAssoTypeId is null or aDicAssoTypeId='?') then begin
     INSERT INTO PAC_PERSON_ASSOCIATION (
      PAC_PERSON_ASSOCIATION_ID,
      PAC_PERSON_ID,
      PAC_PAC_PERSON_ID,
      A_DATECRE,
      A_IDCRE)
  VALUES(
    newId,
    aPersonId,
    aPacPacPersonId,
    SYSDATE,
    'WEB');
   --return 3;  /* insert ok */
   RETURN WEB_FUNCTIONS.RETURN_OK;
   end;
   else
     INSERT INTO PAC_PERSON_ASSOCIATION (PAC_PERSON_ASSOCIATION_ID,
          PAC_PERSON_ID,PAC_PAC_PERSON_ID,
          DIC_ASSOCIATION_TYPE_ID,
          A_DATECRE,A_IDCRE)
          VALUES(newId,aPersonId,aPacPacPersonId,aDicAssoTypeId,SYSDATE,'WEB');
     --return 3;  /* insert ok */
     RETURN WEB_FUNCTIONS.RETURN_OK;
   end if;
   EXCEPTION WHEN OTHERS THEN
     --RETURN 0;
     RETURN WEB_FUNCTIONS.RETURN_ERROR;

 end;
 end if;
 /*  si 1   existe */
return 1;
END;


FUNCTION existePacPersonFromMail (aEmail IN VARCHAR2,msg OUT VARCHAR2) RETURN NUMBER
IS
  retValue NUMBER(1);
  perId NUMBER(12);
BEGIN
  retValue := 1;
  perId:= 0;
  msg := '0';

  select
    pac_person_id
  into
    perId
  from
    pac_communication
  where
    dic_communication_type_id in (select
    dic_communication_type_id
  from
    dic_communication_type
  where
    dco_email=1)
    and lower(com_ext_number)=aEmail;

  if (perId is not null and perId > 0) then begin
      msg := perId||'';
      --return 3;
      RETURN WEB_FUNCTIONS.RETURN_OK;
   end;
   else
      --return 1;
      RETURN WEB_FUNCTIONS.RETURN_FATAL;
   end if;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    --RETURN 1;
    RETURN WEB_FUNCTIONS.RETURN_FATAL;

END;


FUNCTION getPacCommIdAddrFromMail (aEmail IN VARCHAR2,idAddr OUT NUMBER) RETURN NUMBER
IS
retValue NUMBER(1);
BEGIN
  retValue := 1;
  idAddr:= 0;

  select
    pac_address_id
  into
    idAddr
  from
    pac_communication
  where
    dic_communication_type_id in (select
    dic_communication_type_id
      from
        dic_communication_type
      where dco_email=1) and lower(com_ext_number)=aEmail;

  if (idAddr is not null and idAddr > 0) then begin
    --return 3;
    RETURN WEB_FUNCTIONS.RETURN_OK;
   end;
   else
      --return 1;
      RETURN WEB_FUNCTIONS.RETURN_FATAL;
   end if;

  EXCEPTION WHEN NO_DATA_FOUND THEN
  --RETURN 1;
  RETURN WEB_FUNCTIONS.RETURN_FATAL;

END;

FUNCTION getIdAddrFromPacPersonId (aPacPersonId IN NUMBER,idAddr OUT NUMBER) RETURN NUMBER
IS
  retValue NUMBER(1);
BEGIN
  retValue := 1;
  idAddr:= 0;


  select pac_address_id into idAddr
  from pac_address
  where
      pac_person_id=aPacPersonId;

  if (idAddr is not null and idAddr > 0) then begin
      --return 3;
      RETURN WEB_FUNCTIONS.RETURN_OK;
   end;
   else
     --return 1;
     RETURN WEB_FUNCTIONS.RETURN_FATAL;
   end if;

  EXCEPTION WHEN NO_DATA_FOUND THEN
  --RETURN 1;
  RETURN WEB_FUNCTIONS.RETURN_FATAL;

END;



FUNCTION existePacCommFromTel (aTel IN VARCHAR2,msg OUT VARCHAR2) RETURN NUMBER
IS
perId NUMBER(12);
BEGIN
perId := 0;
msg := '0';
select pac_person_id into perId
from
  pac_communication
where
  dic_communication_type_id in (select
    dic_communication_type_id
    from
      dic_communication_type
    where dco_phone=1)
    and com_ext_number=aTel;

 if (perId is not null and perId > 0) then begin
   msg:= perId||'';
   --return 3;
   RETURN WEB_FUNCTIONS.RETURN_OK;
 end;
 else
   return 1;
 end if;
 EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 1;

END;


/**
 * UPDATE_PERSON_PN_CONTACT
 */

FUNCTION UPDATE_PERSON_PN_CONTACT (aPolitnessId IN VARCHAR2,
                                   aContact IN NUMBER,
                                   aPersonId IN NUMBER) RETURN NUMBER IS
BEGIN

  UPDATE PAC_PERSON set
    DIC_PERSON_POLITNESS_ID=aPolitnessId,
    PER_CONTACT=aContact,
    A_DATEMOD=SYSDATE,
    A_IDMOD='WEB'
  WHERE
    PAC_PERSON_ID=aPersonId;

  RETURN WEB_FUNCTIONS.RETURN_OK;

  EXCEPTION WHEN OTHERS THEN
    RETURN WEB_FUNCTIONS.RETURN_ERROR;
END;

/* ============================================= */
/*  Lors de la creation d un user cette fonction */
/*  permet de modifier, rajouter des infos (sans creer web_user ni pac_person)  */
/*  d'un user cree par l interface Web Proconcept */
/* ============================================= */
/* ===========================================================================
  return 3 : ok
  ici  pac_person existe deja
  et si pac_communication n existe pas on le cree (email , tel)
 */
 FUNCTION EHL_PAC_PERSON_UPDATE(aPerId IN NUMBER, aLangId IN NUMBER,
                                   aPER_NAME IN VARCHAR2,aPER_FORENAME IN VARCHAR2,
                                   aPER_SHORT_NAME IN VARCHAR2,
                                   aDIC_PERSON_POLITNESS_ID IN VARCHAR2,
                                   aFonction IN VARCHAR2,
                                   aIsoCode IN VARCHAR2,
                                   aPartnertId IN NUMBER,
                                   aComNumberEmail IN VARCHAR2,
                                   aComNumberTel IN VARCHAR2,
                                   msg OUT VARCHAR2) RETURN NUMBER IS
    retValue  NUMBER(1);
    newIdAddr NUMBER(12);
    newIdComm NUMBER(12);

    retFromEmail NUMBER(1);
    retFromTel   NUMBER(1);
    retAddr      NUMBER(1);

    distingName ECONCEPT.ECO_USERS.ECU_DISTINGUISHED_NAME%type;
    ecoUserId   ECONCEPT.ECO_USERS.ECO_USERS_ID%type;
    newComId    NUMBER(12);
    msgOut      VARCHAR2(200);
    communicationTypeId DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type;

   BEGIN
    newIdAddr := 0;
    msg := '0';
    if (aPerId > 0) then begin

       msg := aPerId || '|';
       /* regarde dans pac_communication email: return 3 existe sinon 1 */
       retFromEmail := existePacPersonFromMail (aComNumberEmail,msgOut);
       /* recupere idAddr  si email existe dans pac_communication */
       newIdAddr := 0;
       if (retFromEmail=WEB_FUNCTIONS.RETURN_OK) then
         retValue := getPacCommIdAddrFromMail (aComNumberEmail,newIdAddr);
       end if;

       /* cas ou  pas de pac_communication: recherche pac_address */
       if (retFromEmail=WEB_FUNCTIONS.RETURN_FATAL) then
         retValue := getIdAddrFromPacPersonId (aPerId,newIdAddr);
       end if;

       /* regarde dans pac_communication Telephone: return 3 existe sinon 1 */
       retFromTel := existePacCommFromTel (aComNumberTel,msgOut);


       if (newIdAddr=0) then
         /* address  create  pour pouvoir creer  dans pac_communication !*/
         retAddr := EHL_PAC_ADDRESS_CREATE (aPerId,aLangId,aPartnertId,newIdAddr);
       end if;

       if (newIdAddr > 0) then begin

          if (retFromEmail=1) then
             /* E-Mail type Id  : creer si pas trouver */
             communicationTypeId := getDicCommunicationTypeId(0);
             retValue := EHL_PAC_COMMUNICATION_CREATE (aPerId,newIdAddr,
                                communicationTypeId,aComNumberEmail,newComId);
          end if;

          if (retFromTel=1) then
          /* Telephone type Id creer si pas trouver */
            communicationTypeId := getDicCommunicationTypeId(1);
            retValue := EHL_PAC_COMMUNICATION_CREATE (aPerId,
                                                      newIdAddr,
                                                      communicationTypeId,
                                                      aComNumberTel,
                                                      newComId);
          end if;
          /* id pers et idAdd return.  */
          msg :=  aPerId || '|' || newIdAddr;

         end; end if;  /* end  newIdAddr > 0 */

     /* ------------------------------------------------------------------- */
     /* si pas email dans ECU_USER on insert:  ne pas modifier ni supprimer */
      /* ------------------------------------------------ */
      /*  eventuellement  update  politnessid  et contact */
      /* ------------------------------------------------ */
      retAddr:= UPDATE_PERSON_PN_CONTACT (aDIC_PERSON_POLITNESS_ID,1,aPerId);
      RETURN WEB_FUNCTIONS.RETURN_OK;

   end; end if;  /* end aPerId > 0 */

   --RETURN 2;
   RETURN WEB_FUNCTIONS.RETURN_WARNING;

 END;


 /* =================================  */
/*  Java  appelle cette fonction  only */
/* ------------------------------------------------------------------ */
/* aFlag = 0 creation total: cas ou email n existe pas dans Web_user, */
/* ni dans PAC_PERSON, ni dans PAC_COMMUNICATION                      */
/* ------------------------------------------------------------------ */
/* aFlag = 1 creation  cas ou email n'existe pas dans Web_user,       */
/* mais existe dans PAC_COMMUNICATION  et email existe dans WEB_USER  */
/* avec PAC_PERSON_ID mais pas dans PAC_COMMUNICATION                 */
/* ------------------------------------------------------------------ */

FUNCTION PAC_PERSON_LF_CREATE_ALL (aLangId IN NUMBER,
                                    aPER_NAME IN VARCHAR2,
                                    aPER_FORENAME IN VARCHAR2,
                                    aPER_SHORT_NAME IN VARCHAR2,
                                    aDIC_PERSON_POLITNESS_ID IN VARCHAR2,
                                    aFonction IN VARCHAR2,
                                    aIsoCode IN VARCHAR2,
                                    aComNumberEmail IN VARCHAR2,
                                    aComNumberTel IN VARCHAR2,
                                    aPacPersonId IN NUMBER,
                                    aCustomPartnertId IN NUMBER,
                                    aDicAssoTypeId IN VARCHAR2,
                                    aFlag IN NUMBER,
                                    msg OUT VARCHAR2) RETURN NUMBER IS

  retValue NUMBER(1);
  retAsso  NUMBER(1);
  pacPersonId   NUMBER(12);
  logMsg VARCHAR2 (80);

  /*  variable pour sendmail */
  sender VARCHAR2 (50);
  reply  VARCHAR2 (50);
  destinataire VARCHAR2 (50);
  subject VARCHAR2 (128);
  bodyText   VARCHAR2 (4000);
  vTitleBody VARCHAR2 (256);
  errorMessages VARCHAR2 (256);
  vUsername ECONCEPT.ECO_USERS.ECU_EMAIL%type;
  vPassword ECONCEPT.ECO_USERS.ECU_ACCOUNT_PASSWORD%type;
  vSignature varchar2(1000);
  nb NUMBER(1);
BEGIN

msg := 'create-All';
retValue:= 0;
pacPersonId := 0;
/*  creation total: param aPacPersonId is null dans ce cas */
if (aFlag=0) then

    retValue:= EHL_PAC_PERSON_CREATE( aLangId,
                                      aPER_NAME,
                                      aPER_FORENAME,
                                      aPER_SHORT_NAME,
                                      aDIC_PERSON_POLITNESS_ID,
                                      aFonction,aIsoCode,
                                      aCustomPartnertId,
                                      aComNumberEmail,
                                      aComNumberTel,
                                      msg);
    if (retValue=3) then
      /* aPacPacPersonId = pacPersonId (celui qui demande)=user qui vient d etre cree */
      /* recupere person id  */
      pacPersonId := to_number(msg);
      /* ne pas supprimer */
      msg := msg || '|' ||retAsso;
    else
      --return 1;
      RETURN WEB_FUNCTIONS.RETURN_FATAL;
    end if;

end if;  /* end aFlag=0 */


/* creation partiale : pac_person existe */
/*  web_user existe ou non               */
/*  pac_communication existe ou non      */
/*  si pas de tel  on rajoute dans pac_comunication */

if (aFlag=1) then
  retValue := EHL_PAC_PERSON_UPDATE(aPacPersonId,
                                    aLangId,
                                    aPER_NAME,
                                    aPER_FORENAME,
                                    aPER_SHORT_NAME,
                                    aDIC_PERSON_POLITNESS_ID,
                                    aFonction,aIsoCode,
                                    aCustomPartnertId,
                                    aComNumberEmail,
                                    aComNumberTel,
                                    msg);
  pacPersonId := aPacPersonId;

end if;

/*  pour les deux cas  ci-dessus */
if (retValue=WEB_FUNCTIONS.RETURN_OK) then
   /*  insert pac_asso  si  pas trouve sinon  : fait rien */
   retAsso := EHL_INSERT_PACPERASSOCIATION (aCustomPartnertId,
                                            pacPersonId,
                                            aDicAssoTypeId,
                                            logMsg);
end if;


/* ----------------------------------------------- */
/*  Envoie email: soit create total soit partial   */
/* ----------------------------------------------- */
if (retValue=WEB_FUNCTIONS.RETURN_OK) then begin

 sender:= 'hotline@proconcept.ch';
 destinataire:=aComNumberEmail;
 reply:=aComNumberEmail;

-- 24/06/ 2008
select w.ECU_ACCOUNT_PASSWORD into vPassword
from econcept.eco_users w
where lower(w.ECU_EMAIL) = lower(aComNumberEmail);
--EXCEPTION WHEN NO_DATA_FOUND THEN retValue:=WEB_FUNCTIONS.RETURN_OK;

 subject:= 'eHotline Sage ProConcept ' ||pcs.pc_functions.TRANSLATEWORD(' : Création de votre compte',aLangId);


    if (aDIC_PERSON_POLITNESS_ID<>'1') then --<>'Monsieur'
      if    aLangId=1 then vTitleBody := 'Madame '||aPER_NAME||',';
      elsif aLangId=2 then vTitleBody := 'Sehr geehrte Frau '||aPER_NAME||',';
      else                 vTitleBody := 'Miss '||aPER_NAME||',';
      end if;
    else
      if    aLangId=1 then vTitleBody := 'Monsieur '||aPER_NAME;
      elsif aLangId=2 then vTitleBody := 'Sehr geehrter Herr '||aPER_NAME;
      else                 vTitleBody := 'Mister '||aPER_NAME;
      end if;
    end if;

    if (aLangId=1) then
    bodyText:= '<br>'||
    'Votre compte eHotline : '||
    '<br>'||
    'Adresse du site ... <a href="http://www.proconcept.ch">Hotline web access</a><br>'||
    'Username : '||aComNumberEmail||'<br>'||
    'Password : '||vPassword||'<br>'||
    '<br>'||
    'Meilleures saluations.<br><br>';
    elsif (aLangId=2) then
    bodyText:= 'Votre compte eHotline : '||
    '<br>'||
    'Adresse du site ... <a href="http://www.proconcept.ch">Hotline web access</a><br>'||
    'Username : '||aComNumberEmail||'<br>'||
    'Password : '||vPassword||'<br>'||
    '<br>'||
    'Mit freundlichen Grüssen.<br>';

    else
    bodyText:= 'Your account has been created.'||
    '<br>'||
    'Web site ... <a href="http://www.proconcept.ch">Hotline web access</a><br>'||
    'Username : '||aComNumberEmail||'<br>'||
    'Password : '||vPassword||'<br>'||
    '<br>'||
    'Best regards.<br>';
    end if;


 vSignature :=
    '--------------------------------------------<br>'||
    '<b>Sage Pro-Concept SA</b><br>'||
    'Hotline<br>'||
    'Phone +41 32 488 39 40<br>'||
    '<a href="mailto:hotline@proconcept.ch">hotline@proconcept.ch</a><br>'||
    '<a href="http://www.proconcept.ch">Hotline web access</a><br>'||
    '--------------------------------------------';

    --vSignature :='<br>';

    bodyText:= vTitleBody||'<br>'||bodyText || vSignature;

 /*  traduire subject et body en multilangues  */
 subject:= pcs.pc_functions.TRANSLATEWORD('eHotline Sage Pro-Concept : Votre compte',aLangId);

 retValue:= WEB_HOT_ENTRY_EHOTLINE.WHE_SENDMAIL (sender,reply,destinataire,
                                            subject,bodyText,errorMessages);

 --return 3;
 RETURN WEB_FUNCTIONS.RETURN_OK;

end; end if;

--return 1;
RETURN WEB_FUNCTIONS.RETURN_FATAL;

END;



END WEB_PERSON_CREATE_EHOTLINE;
