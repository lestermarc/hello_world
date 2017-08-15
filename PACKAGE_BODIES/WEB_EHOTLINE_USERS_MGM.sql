--------------------------------------------------------
--  DDL for Package Body WEB_EHOTLINE_USERS_MGM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_EHOTLINE_USERS_MGM" 
AS
/******************************************************************************
   NAME:       ECO_USERS_MGM
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        1806.2008             1. Created this package body.
******************************************************************************/

   /* -------------------------------------------------------------*/
/*   get Id de  Person ou Partner  from ecoUserId and Tablename */
/*   Call  by java                                              */
/* -------------------------------------------------------------*/
   FUNCTION getidfromuserlinks (
      aecouserid    IN       NUMBER,
      aeultabname   IN       VARCHAR2,
      acompanyid    IN       NUMBER,
      amsg          OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue   NUMBER (1);
      eulrecid   NUMBER (12);
      sqlstmnt   VARCHAR2 (4000);
   BEGIN
      retvalue := web_functions.return_error;
      amsg := '0';
      sqlstmnt :=
         'begin :eulrecid := ECONCEPT.ECO_USERS_MGM.getLinksFromEcoUserIdTabName(:aEcoUserId,:aEulTabName,:aCompanyId); end;';

      EXECUTE IMMEDIATE sqlstmnt
                  USING IN OUT eulrecid,aecouserid, aeultabname, acompanyid;

      IF (eulrecid IS NOT NULL AND eulrecid > 0)
      THEN
         BEGIN
            amsg := eulrecid || '';
            RETURN web_functions.return_ok;
         END;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN web_functions.return_error;
   END;

/**  Control  pc_comp_id du companyId  */
/**  verif la pc_comp_id de ECO_COMPY  et  PCS.pc_public.setCompany() */
/** aMsg contenant pc_comp_id          */
/** RRI 2009 09 14 changement appel via execute imeediate */
   FUNCTION checkpccompid (acompanyid IN NUMBER, amsg OUT VARCHAR2)
      RETURN NUMBER
   IS
      pccompid   NUMBER (12);
      sqlstmnt   VARCHAR2 (4000);
   BEGIN
      amsg := '0';
      sqlstmnt :=
         'select PC_COMP_ID from econcept.eco_company where  ECO_COMPANY_ID=:aCompanyId';

      EXECUTE IMMEDIATE sqlstmnt
                  INTO pccompid
                  USING acompanyid;

      amsg := pccompid || '';
      RETURN web_functions.return_ok;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN web_functions.return_error;
   END;

/* ----------------------------------- */
/*  check compagny id: for REPOSITORY  */
/*  call  by java                      */
/*  par methods_id=1                   */
/* ------------------------------------*/
   FUNCTION checkcompanyidrepository (acompagnyid IN NUMBER, amsg OUT VARCHAR2)
      RETURN NUMBER
   IS
      retvalue   NUMBER (1);
      nb         NUMBER (1);
      sqlstmnt   VARCHAR2 (4000);
   BEGIN
      amsg := '0';
      sqlstmnt :=
         'SELECT count(*) nb FROM ECONCEPT.ECO_COMPANY WHERE ECO_CONNECT_METHODS_ID=1 and ECO_COMPANY_ID=:aCompanyId';

      EXECUTE IMMEDIATE sqlstmnt
                  INTO nb
                  USING acompagnyid;

      amsg := nb || '';
      RETURN web_functions.return_ok;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN web_functions.return_error;
   END;

/** ---------------------------------------------------------
*  Call  by java
*  Insert ECO_USERS
*  eHotline : aEcaModCode := 'eHotline'; aEcrCode := 'HOTLINE-CLIENT';
*  OUT pMsgReturn   contient  newId eco_users
*  il faut appeller  ECO_ROLES_MGM.RoleCreateForUser() apres.
*/
   FUNCTION usercreate (
      pusername      IN       VARCHAR2,
      ppasswsord     IN       VARCHAR2,
      pemail         IN       VARCHAR2,
      plastname      IN       VARCHAR2,
      pfirstname     IN       VARCHAR2,
      pisolocale     IN       VARCHAR2,
      pauthenmet     IN       NUMBER,
      pdisplayname   IN       VARCHAR2,
      pdistingname   IN       VARCHAR2,
      pmsgreturn     OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      newid      NUMBER (12);
      sqlstmnt   VARCHAR2 (4000);
      retvalue   NUMBER(1);
   BEGIN
      pmsgreturn := '0';
      sqlstmnt :=
         'begin :newid := ECONCEPT.ECO_USERS_MGM.UserCreate(:pUserName,:pPasswsord,:pEmail,:pLastName,:pFirstName,:pIsoLocale,:pAuthenMet,:pDisplayName,:pDistingName); end;';

      EXECUTE IMMEDIATE sqlstmnt
                  USING IN OUT newid,pusername,
                        ppasswsord,
                        pemail,
                        plastname,
                        pfirstname,
                        pisolocale,
                        pauthenmet,
                        pdisplayname,
                        pdistingname;

      IF (newid IS NOT NULL AND newid > 0)
      THEN
         BEGIN
            pmsgreturn := newid || '';
            RETURN web_functions.return_ok;
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            RETURN web_functions.return_error;
         END;
   END;

/**
 Call by java
 param in  aEcoUserId
 aMsg  contient  isoCode
*/
   FUNCTION getisocodefrom (aecouserid IN NUMBER, amsg OUT VARCHAR2)
      RETURN NUMBER
   IS
      sqlstmnt   VARCHAR2 (4000);
   BEGIN
      sqlstmnt :=
         'select ECONCEPT.ECO_USERS_MGM.getIsoCodeFrom(:aEcoUserId) from dual';

      EXECUTE IMMEDIATE sqlstmnt
                  INTO amsg
                  USING aecouserid;

      RETURN web_functions.return_ok;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN web_functions.return_error;
   END;

/* ------------------------- */
/*  Creation eco_user_links  */
/*  Call by Java             */
/* ------------------------- */
   FUNCTION userlinkscreate (
      aecouserid   IN       NUMBER,
      atablename   IN       VARCHAR2,
      aidoftable   IN       NUMBER,
      acompanyid   IN       NUMBER,
      amsgreturn   OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      newid      NUMBER (12);
      sqlstmnt   VARCHAR2 (4000);
      retvalue   NUMBER(1);
   BEGIN
      amsgreturn := '0';
      sqlstmnt :=
         'begin :newid := ECONCEPT.ECO_USERS_MGM.UserLinksCreate(:aEcoUserId,:aTableName,:aIdOfTable,:aCompanyId); end;';

      EXECUTE IMMEDIATE sqlstmnt
                  USING IN OUT newid,aecouserid, atablename, aidoftable, acompanyid;

      IF ((atablename = 'PAC_PERSON') OR (atablename = 'PAC_CUSTOM_PARTNER')
         )
      THEN
         sqlstmnt :=
            ' update econcept.eco_user_links set eul_descr=(select per_name||'' ''||per_key1 from pac_person where pac_person_id=:aIdOfTable) '||
            ' where eco_user_links_id=:newId';

         EXECUTE IMMEDIATE sqlstmnt USING aidoftable, newid;

      END IF;

      amsgreturn := newid || '';
      RETURN web_functions.return_ok;
   EXCEPTION
      WHEN OTHERS
      THEN
         amsgreturn := sqlerrm;
         RETURN web_functions.return_error;
   END;

/* -----------------------------------------*/
/* outil update EUL_REC_ID  Call by java    */
/* param aTableName et aSociete             */
/* -----------------------------------------*/
   FUNCTION updatelinkseulrecid (
      aecouserid   IN       NUMBER,
      aeulrecid    IN       NUMBER,
      atablename   IN       VARCHAR2,
      acompanyid   IN       NUMBER,
      amsgreturn   OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue   NUMBER (1);
      sqlstmnt   VARCHAR2 (4000);
   BEGIN
      amsgreturn := '0';
      sqlstmnt :=
         'begin '||
         ':retValue:= ECONCEPT.ECO_USERS_MGM.updateLinksEulRecId (:aEcoUserId,:aEulRecId,:aTableName,:aCompanyId);'||
         ' end;';

      EXECUTE IMMEDIATE sqlstmnt
                  USING IN OUT retValue, aecouserid, aeulrecid, atablename, acompanyid;

      amsgreturn := retvalue || '';
      RETURN retvalue;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN web_functions.return_error;
   END;

/** --------------------------------------- */
/** Call by Java                            */
/**  update password  a partir  ecoUserId   */
/** --------------------------------------- */
   FUNCTION userupdaterepositorypassword (
      aecouserid     IN       NUMBER,
      anewpassword   IN       VARCHAR2,
      amsg           OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue   NUMBER (1);
      sqlstmnt   VARCHAR2 (4000);
   BEGIN
      amsg := '0';
      sqlstmnt :=
         'begin '||
         ':retValue := ECONCEPT.ECO_USERS_MGM.UserUpdateRepositoryPassword (:aEcoUserId,:aNewPassword);'||
         ' end;';

      EXECUTE IMMEDIATE sqlstmnt
                  USING IN OUT retvalue,aecouserid, anewpassword;

      amsg := aecouserid || '';
      RETURN retvalue;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN web_functions.return_error;
   END;

/** only for eHotline, mécanisme dynamique package
interne method
Update telephone par le package WEB_PERSON_CREATE_EHOTLINE
*/
   FUNCTION executepackageupdatetel (
      packagename    IN   VARCHAR2,
      functionname   IN   VARCHAR2,
      aid            IN   NUMBER,
      avalue         IN   VARCHAR2
   )
      RETURN NUMBER
   IS
      cursor_handle   INTEGER;
      datas_updated   INTEGER;
      sqldynamic      VARCHAR2 (1024);
      msg             VARCHAR2 (200);
      retvalue        NUMBER (1);
/** array bind */
      outvarchar      DBMS_SQL.varchar2_table;
      retour          DBMS_SQL.number_table;
   BEGIN
/* Create a cursor to use for the dynamic SQL */
      cursor_handle := DBMS_SQL.open_cursor;
      sqldynamic :=
            'BEGIN :retValue:='
         || packagename
         || '.'
         || functionname
         || '(:persId,:tel,:msg); END;';
      DBMS_SQL.parse (cursor_handle, sqldynamic, DBMS_SQL.native);
/* Now I must supply values for the bind variables */
      DBMS_SQL.bind_variable (cursor_handle, 'persId', aid);
      DBMS_SQL.bind_variable (cursor_handle, 'tel', avalue);
/**  attention  bind avec array  varchar2  initialiser  */
      DBMS_SQL.bind_array (cursor_handle, 'msg', outvarchar);
/** initialiser bind avec array number  */
      DBMS_SQL.bind_array (cursor_handle, 'retValue', retour);
/* Execute the SQL statement */
      datas_updated := DBMS_SQL.EXECUTE (cursor_handle);
/**  Recuperer  les valeurs  */
      DBMS_SQL.variable_value (cursor_handle, 'retValue', retour);
      retvalue := retour (1);

--DBMS_OUTPUT.PUT_LINE('variable_value='||retValue);
      IF (retvalue = web_functions.return_ok)
      THEN
         BEGIN
            DBMS_SQL.variable_value (cursor_handle, 'msg', outvarchar);
            msg := outvarchar (1);
--DBMS_OUTPUT.PUT_LINE('outVarchar='||msg);
         END;
      END IF;

/** raz */
      sqldynamic := '';
/* Close the cursor */
      DBMS_SQL.close_cursor (cursor_handle);
--DBMS_OUTPUT.PUT_LINE('End close cursor='||msg);
      RETURN web_functions.return_ok;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            DBMS_SQL.close_cursor (cursor_handle);
         END;

         RETURN web_functions.return_error;
   END;

/** ---------------------------------------------------------------------- */
/** Call by java  for update all fields                                    */
/** possible call  un autre package                                        */
/**  aTableOrPackageName soit tableName  soit  nom du pacakage             */
/**  aFieldName nom du field  ou nom d'une fonction si aTableOrPackageName */
/**  est nom d un package                                                  */
/** ---------------------------------------------------------------------- */
   FUNCTION userupdateinfo (
      aecouserid     IN       NUMBER,
      aapplication   IN       VARCHAR2,
      afieldname     IN       VARCHAR2,
      afieldvalue    IN       VARCHAR2,
      amsg           OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue   NUMBER (1);
      sqlstmnt   VARCHAR2 (4000);
   BEGIN
      amsg := '0';
      sqlstmnt :=
         'begin '||
         ':retValue:=  ECONCEPT.ECO_USERS_MGM.UserUpdateInfo(:aEcoUserId, :aApplication,:aFieldName,:aFieldValue);'||
         ' end;';

      EXECUTE IMMEDIATE sqlstmnt
                  USING IN OUT retvalue,aecouserid, aapplication, afieldname, afieldvalue;

      amsg := retvalue || '';
      RETURN retvalue;
   EXCEPTION
      WHEN OTHERS
      THEN
         amsg := sqlerrm;
         RETURN web_functions.return_error;
   END;

/** ---------------------------------------------- */
   FUNCTION updatepackageexternetel (
      aecouserid      IN       NUMBER,
      aapplication    IN       VARCHAR2,
      acompanyid      IN       NUMBER,
      apackagename    IN       VARCHAR2,
      afunctionname   IN       VARCHAR2,
      avalue          IN       VARCHAR2,
      amsg            OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue       NUMBER (1);
      vpersid        NUMBER (12);
      vsocietename   VARCHAR2 (30);
      vpackagename   VARCHAR2 (512);
      sqlstmnt       VARCHAR2 (4000);
   BEGIN
      amsg := '0';
      sqlstmnt :=
         ':retvalue := ECONCEPT.ECO_MODULES_MGM.checkApplicationName (:aApplication);';

      EXECUTE IMMEDIATE sqlstmnt
              USING IN OUT retvalue, aapplication;

      IF (retvalue <> web_functions.return_ok)
      THEN
         RETURN web_functions.return_fatal;
      END IF;

/** ----------------------------------------- */
/**  update telephone du package WEB_EHOTLINE */
/** ----------------------------------------- */
/**  aFunctionName  contient le nom de la fonction */
      IF (afunctionname = 'updateTelephoneToCommunication')
      THEN
         BEGIN
            /**  search societe Name from companyId    */
            sqlstmnt :=
               'begin :vsocietename := ECONCEPT.ECO_USERS_MGM.getCompanyNameFromId (:aCompanyId); end;';

            EXECUTE IMMEDIATE sqlstmnt
                        USING IN OUT vsocietename,acompanyid;

            amsg := vsocietename;
            --DBMS_OUTPUT.PUT_LINE('vSocieteName='||vSocieteName);
            /** searche pac_person_id  from eco_links */
            retvalue :=
               getidfromuserlinks (aecouserid, 'PAC_PERSON', acompanyid,
                                   amsg);

            IF (retvalue = web_functions.return_ok)
            THEN
               BEGIN
                  vpersid := TO_NUMBER (amsg);
                  amsg := vpersid || '-' || vsocietename;

                  --DBMS_OUTPUT.PUT_LINE('aMsg='||aMsg);
                  IF (vpersid IS NOT NULL AND vpersid > 0)
                  THEN
                     BEGIN
/** -----------------------------------------  */
/** construction societe.packageName.function  */
/** -----------------------------------------  */
                        vpackagename := vsocietename || '.' || apackagename;
                        retvalue :=
                           executepackageupdatetel (vpackagename,
                                                    afunctionname,
                                                    vpersid,
                                                    avalue
                                                   );
                        amsg := retvalue || '';
                     --DBMS_OUTPUT.PUT_LINE('vPackageName='||vPackageName);
                     END;
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     RETURN web_functions.return_error;
               END;
            END IF;
         END;
      END IF;

      RETURN retvalue;
   END;

/* -----------------------------------------------  */
/* call this before UserCreate ()                   */
/* OUT aMsg  contient ecoUserId|| methodId          */
/* param aUsername = email                          */
/* --------------------------------------------     */
/* Call by Java                                     */
/* ------------------------------------------------ */
   FUNCTION usercheckemail (
      ausername          IN       VARCHAR2,
      aapplicationname   IN       VARCHAR2,
      amsg               OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue              NUMBER (1);
      vecoconnectmethodid   NUMBER (12);
      vecouserid            NUMBER (12);
      sqlstmnt              VARCHAR2 (4000);
   BEGIN
      amsg := '0';

      --retValue:= ECONCEPT.ECO_USERS_MGM.UserCheckEmail(aUsername,aApplicationName,vEcoUserId,vEcoConnectMethodId);
      sqlstmnt :=
         'begin :retvalue := ECONCEPT.ECO_USERS_MGM.UserCheckEmail(:ausername,:aapplicationname,:vecouserid,:vecoconnectmethodid); end;';

      EXECUTE IMMEDIATE sqlstmnt
                  USING OUT retvalue,
                        IN    ausername,
                        IN    aapplicationname,
                        OUT vecouserid,
                        OUT vecoconnectmethodid;

      amsg := vecouserid || '|' || vecoconnectmethodid;
      RETURN retvalue;
   END;

/* -----------------------------------------------  */
/* call this before UserCreate ()                   */
/* OUT aMsg  contient methodId || ecoUserId         */
/* param aUsername = account name                   */
/* --------------------------------------------     */
/*                                                  */
/* ------------------------------------------------ */
   FUNCTION usercheckaccount (
      ausername          IN       VARCHAR2,
      aapplicationname   IN       VARCHAR2,
      amsg               OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue              NUMBER (1);
      vecoconnectmethodid   NUMBER (12);
      vecouserid            NUMBER (12);
      sqlstmnt              VARCHAR2 (4000);
   BEGIN
      amsg := '0';
      sqlstmnt :=
         'begin retValue := ECONCEPT.ECO_USERS_MGM.UserCheckEmail(:aUsername,:aApplicationName,:vEcoUserId,:vEcoConnectMethodId); end;';

      EXECUTE IMMEDIATE sqlstmnt
                  USING IN OUT retvalue,
                               ausername,
                               aapplicationname,
                               vecouserid,
                               vecoconnectmethodid;

      amsg := vecouserid || '|' || vecoconnectmethodid;
      RETURN retvalue;
   END;

/* ----------------------------------------- */
/* Call par Java                             */
/*      ehotline aUsername= email            */
/*  return  RETURN_OK=3   ok  sinon          */
/*  return  RETURN_FATAL=1  pas  module      */
/*  Si Ok aMsg = ecoUserID | aEcoConnectMethodId   */
/* ----------------------------------------- */
   FUNCTION checkauthentication (
      ausername          IN       VARCHAR2,
      apassword          IN       VARCHAR2,
      aapplicationname   IN       VARCHAR2,
      amsg               OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue              NUMBER (1);
      vecoconnectmethodid   NUMBER (12);
      vecouserid            NUMBER (12);
      sqlstmnt              VARCHAR2 (4000);
   BEGIN
      amsg := '0';
      sqlstmnt :=
         'begin retValue:= ECONCEPT.ECO_USERS_MGM.CheckAuthenticationEmail(:aUsername,:aPassword,  :aApplicationName,:vEcoUserId,:vEcoConnectMethodId); end;';

      EXECUTE IMMEDIATE sqlstmnt
                  USING IN OUT retvalue,
                               ausername,
                               apassword,
                               aapplicationname,
                               vecouserid,
                               vecoconnectmethodid;

      amsg := vecouserid || '|' || vecoconnectmethodid;
      RETURN retvalue;
   END;

/* ----------------------------------------------- */
/*                                           */
/*      aUsername= Account name              */
/*  return  RETURN_OK=3   ok  sinon          */
/*  return  RETURN_FATAL=1  pas  module            */
/*  Si OK aMsg = ecoUserID | aEcoConnectMethodId   */
/* ---------------------------------------------- */
   FUNCTION checkauthenticationaccount (
      ausername          IN       VARCHAR2,
      apassword          IN       VARCHAR2,
      aapplicationname   IN       VARCHAR2,
      amsg               OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue              NUMBER (1);
      vecoconnectmethodid   NUMBER (12);
      vecouserid            NUMBER (12);
      sqlstmnt              VARCHAR2 (4000);
   BEGIN
      amsg := '0';
      sqlstmnt :=
         'begin retValue:= ECONCEPT.ECO_USERS_MGM.CheckAuthenticationAccount(:aUsername,:aPassword,  :aApplicationName,:vEcoUserId,:vEcoConnectMethodId); end;';

      EXECUTE IMMEDIATE sqlstmnt
                  USING IN OUT retvalue,
                               ausername,
                               apassword,
                               aapplicationname,
                               vecouserid,
                               vecoconnectmethodid;

      amsg := vecouserid || '|' || vecoconnectmethodid;
      RETURN retvalue;
   END;
END web_ehotline_users_mgm;
