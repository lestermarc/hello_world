--------------------------------------------------------
--  DDL for Package Body WEB_EXPENSIVE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_EXPENSIVE_FCT" 
as

/******************************************************************************

******************************************************************************/
  /**
   *
   * ecoUserId est l'utilisteur connecté
   * pcLangId est la langue actuellemetn utilisée
   * webExpensiveHeadId est l'ID de l'entête créée
   * msg est le message d'avertissement ou d'erreur éventuellement générée
   *
   * retourne WEB_FUNCTIONS.ERROR, WARNING ou OK
   *
      declare
        ret number(1);
        oMsg varchar2(2000);
        oWebExpensiveHeadId  number(12);
      begin
        ret := web_expensive_fct.WebExpensiveHeadCreate(3006455151,1,oWebExpensiveHeadId,oMsg);
        dbms_output.put_line(ret||' '||oWebExpensiveHeadId);
      end;
   *
   *
   */
  FUNCTION WebExpensiveHeadCreate (
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      oWebExpensiveHeadId OUT WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%type,
      oMsg                OUT NOCOPY VARCHAR2)
      RETURN NUMBER IS
  BEGIN
    select
      WEB_EXPENSIVE_SEQ.nextval into oWebExpensiveHeadId
    from dual;

  -- Initialisation des variables avant insert
  tplWebExpensiveHead.WEB_EXPENSIVE_HEAD_ID := oWebExpensiveHeadId;
  tplWebExpensiveHead.ECO_USERS_ID          := iEcoUsersId;
  tplWebExpensiveHead.WEH_NAME_TO           := web_functions.GETECOUSERSDISPLAYNAME(iEcoUsersId) ;
  tplWebExpensiveHead.ECO_USERS_ID_CREATOR  := iEcoUsersId;
  tplWebExpensiveHead.WEH_NAME_CREATOR      := web_functions.GETECOUSERSDISPLAYNAME(iEcoUsersId) ;
  tplWebExpensiveHead.WEH_TITLE             := to_char(sysdate,'monthyyyy')||'-'||web_functions.GETECOUSERSDISPLAYNAME(iEcoUsersId);
  tplWebExpensiveHead.WEH_DATE1             := trunc(sysdate);
  tplWebExpensiveHead.A_DATECRE             := sysdate;
  tplWebExpensiveHead.a_IDCRE               := 'WEB';
  tplWebExpensiveHead.C_WEB_EXPENSIVE_STATE := '0';
  tplWebExpensiveHead.WEH_NUMBER            := 'NF-'||lpad(oWebExpensiveHeadId,12,'0');

  INSERT INTO WEB_EXPENSIVE_HEAD VALUES tplWebExpensiveHead;

    oMsg := pcs.pc_functions.TRANSLATEWORD('message si besoin',iPcLangId);

    return WEB_FUNCTIONS.RETURN_OK;
  END;

  /**
   declare
        ret number(1);
        oMsg varchar2(2000);
        oWebExpensiveHeadId  number(12);
      begin
        ret := web_expensive_fct.WEBEXPENSIVEHEADTRANSMIT(3006455151,1,14,oMsg);
        dbms_output.put_line(ret);
      end;
   */
  FUNCTION WebExpensiveHeadTransmit (
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      iWebExpensiveHeadId IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%type,
      oMsg                OUT NOCOPY VARCHAR2
   )
      RETURN NUMBER IS
    BEGIN

      update
        WEB_EXPENSIVE_HEAD
      set (c_web_expensive_state,
           weh_date2,
           weh_name_valid) = (
           select
             '1',
             sysdate,
             'responsable hiérarchique' from dual)
      where
        WEB_EXPENSIVE_HEAD_ID=iWebExpensiveHeadId;

      update
        WEB_EXPENSIVE
      set (c_web_expensive_state,
           a_datemod,
           a_idmod) = (
           select
            EXPENSIVE_STATE_TRANSMIT,
             sysdate,
             'WEB' from dual)
      where
        WEB_EXPENSIVE_HEAD_ID=iWebExpensiveHeadId;

      oMsg := pcs.pc_functions.TRANSLATEWORD('Votre note de frais est transmise.',iPcLangId);

    return WEB_FUNCTIONS.RETURN_OK;
  END;

  /**
   *  Validation d'une position de la note de frais
   **/
     FUNCTION WebExpensiveValidation (
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      iWebExpensiveId IN WEB_EXPENSIVE.WEB_EXPENSIVE_ID%type,
      oMsg                OUT NOCOPY VARCHAR2
   )
      RETURN NUMBER IS
  BEGIN
       update
        WEB_EXPENSIVE
      set (c_web_expensive_state,
           a_datemod,
           a_idmod) = (
           select
             EXPENSIVE_STATE_VALIDATED,
             sysdate,
             'WEB' from dual)
      where
        WEB_EXPENSIVE_ID=iWebExpensiveId;

    return WEB_FUNCTIONS.RETURN_OK;
  END;

  /**
   *  Validation de l'entête de la note de frais
   *
    declare
        ret number(1);
        oMsg varchar2(2000);
        oWebExpensiveHeadId  number(12);
      begin
        ret := web_expensive_fct.WebExpensiveHeadValidation(3006455151,1,14,oMsg);
        dbms_output.put_line(ret);
      end;

   **/
     FUNCTION WebExpensiveHeadValidation (
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      iWebExpensiveHeadId IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%type,
      oMsg                OUT NOCOPY VARCHAR2
   )
      RETURN NUMBER IS

  BEGIN

   update
        WEB_EXPENSIVE_HEAD
      set (c_web_expensive_state,
           weh_date3,
           eco_users_id_validator,
           weh_name_valid) = (
           select
             EXPENSIVE_STATE_VALIDATED,
             sysdate,
             iEcoUsersId,
             web_functions.GETECOUSERSDISPLAYNAME(iEcoUsersId)
             from dual)
      where
        WEB_EXPENSIVE_HEAD_ID=iWebExpensiveHeadId;
    oMsg := pcs.pc_functions.TRANSLATEWORD('La note de frais est validée.',iPcLangId);
    return WEB_FUNCTIONS.RETURN_OK;
  END;


   /**
    *  RRI 2009 11 26
    *  Fait appel à WEB_FUNCTIONS.insertComImageFileEmpty
    * retour dans newId l'ID de com_ole_id inséré.
    *
    declare
      n number(1);
      id number(12);
      msg varchar2(2000);
    begin
      n := web_expensive_fct.insertComImageFileRetComId('test','HRM_PERSON',60054606872,id, msg);
      dbms_output.PUT_LINE(n||' '||id||' '||msg);
    end;
    *
    */
  FUNCTION insertComImageFileRetComId(
    filename  IN VARCHAR2,
    tableName IN VARCHAR2,
    redId     IN NUMBER,
    newId     OUT NUMBER,
    msg       OUT VARCHAR2
     ) return NUMBER IS
    ret number(1);
    comImgId COM_IMAGE_FILES.COM_IMAGE_FILES_ID%type;
  BEGIN

    ret := WEB_FUNCTIONS.insertComImageFileEmpty(filename, tableName,redId,comImgId,msg);

    select
      com_ole_id into newId
    from
      com_image_files
    where
      com_image_files_id=comImgId;

    return ret;
  END;


  /**
   *  Enregistrement de l'entête de la note de frais
   **/
     FUNCTION WebExpensiveHeadSave(
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      oWebExpensiveHeadId OUT WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%type,
      oMsg                OUT NOCOPY VARCHAR2
   )
      RETURN NUMBER
    IS

    BEGIN

      update
        WEB_EXPENSIVE_HEAD
      set
        (A_DATEMOD, A_IDMOD) =
        (SELECT sysdate, 'WEB' FROM DUAL)
      where
        WEB_EXPENSIVE_HEAD_ID=oWebExpensiveHeadId;


     oMsg :='Note de frais enregistrée.';
     RETURN WEB_FUNCTIONS.RETURN_OK;
    END;

 /**
  *  supression d'une note de frais
  *
  *
  *  suppression des positions
  *  suppression des pièces justificatives
  *  suppression de l'entête'
  *
  */
  FUNCTION WebExpensiveHeadDelete(
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      idWebExpensiveHead  IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%type,
      oMsg                OUT NOCOPY VARCHAR2
   )
      RETURN NUMBER IS
   BEGIN


      --utilisation de WebExpensiveDelete(iEcoUsersId,iPcLangId,); ?
      delete
        WEB_EXPENSIVE
      where
        WEB_EXPENSIVE_HEAD_ID=idWebExpensiveHead;



      delete
        com_image_files
      where
        imf_table like 'WEB_EXPENSIVE_HEAD'
        and imf_rec_id=idWebExpensiveHead;

      delete
        WEB_EXPENSIVE_HEAD
      where
        WEB_EXPENSIVE_HEAD_ID=idWebExpensiveHead;

   RETURN WEB_FUNCTIONS.RETURN_OK;
 END;

  /**
   *suppression d'une pièce jointe
   *
   */
FUNCTION WebExpensiveHeadLink(
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      idLink              IN COM_IMAGE_FILES.COM_IMAGE_FILES_ID%type,
      oMsg                OUT NOCOPY VARCHAR2
   )
      RETURN NUMBER IS
   BEGIN

      delete
        com_image_files
      where
        com_image_files_id=idLink;
   RETURN WEB_FUNCTIONS.RETURN_OK;
END;

  /**
   *
   *      declare
        ret number(1);
        oMsg varchar2(2000);
        oWebExpensiveHeadId  number(12);
      begin
        ret := web_expensive_fct.WebExpensiveCreate(3006455151,1,91,oMsg);
        dbms_output.put_line(ret);
      end;
    "*/
  FUNCTION WebExpensiveCreate(
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      iWebExpensiveHeadId IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%type,
      oMsg                OUT NOCOPY VARCHAR2
   )
      RETURN NUMBER IS

  BEGIN

    select
      WEB_EXPENSIVE_SEQ.nextval into tplWebExpensive.WEB_EXPENSIVE_ID
    from dual;

    select
      * into tplWebExpensiveHead
    from
      WEB_EXPENSIVE_HEAD
    where
      WEB_EXPENSIVE_HEAD_ID = iWebExpensiveHeadId;


  tplWebExpensive.SCO_GROUP_NAME := '000000';
  tplWebExpensive.SCO_GROUP_KEY  := '000000';

  -- Initialisation des variables avant insert
  tplWebExpensive.WEB_EXPENSIVE_HEAD_ID := iWebExpensiveHeadId;

  tplWebExpensive.A_DATECRE             := sysdate;
  tplWebExpensive.a_IDCRE               := 'WEB';
  tplWebExpensive.SCO_QTE               := 0;
  tplWebExpensive.SCO_TO_BILL           := 0;
  tplWebExpensive.SCO_AMOUNT            := 0;
  tplWebExpensive.SCO_VAT_RATE          := 0;
  tplWebExpensive.C_WEB_EXPENSIVE_STATE := '00';

  --récupération de données depuis entête
  tplWebExpensive.SCO_PROJECT_ID        := tplWebExpensiveHead.WEH_PROJECT_ID;
  tplWebExpensive.SCO_DATE              := tplWebExpensiveHead.WEH_DATE1;

  INSERT INTO WEB_EXPENSIVE VALUES tplWebExpensive;


  RETURN WEB_FUNCTIONS.RETURN_OK;
  END;

 /**
  *  procédure après Sauvegarde d'une position
  *
  *
  *
  */
  FUNCTION WebExpensiveSave(
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      idWebExpensive      IN WEB_EXPENSIVE.WEB_EXPENSIVE_ID%type,
      oMsg                OUT NOCOPY VARCHAR2
   )
      RETURN NUMBER IS
  a varchar2(2000);
   BEGIN

   select
     dic_web_expensive_type_id into a
   from
     web_expensive
   where
     WEB_EXPENSIVE_ID = idWebExpensive;

    update
      WEB_EXPENSIVE
    set
      SCO_GROUP_NAME = to_char(sco_date,'yyyymmdd')||web_expensive_id,
      SCO_GROUP_KEY  = to_char(sco_date,'yyyymmdd')||web_expensive_id,
      A_DATEMOD      = sysdate,
      A_IDMOD        = 'WEB'
    where
      WEB_EXPENSIVE_ID = idWebExpensive;

   RETURN WEB_FUNCTIONS.RETURN_OK;
 END;


 /**
  *  supression d'une position
  *
  *
  *
  */
  FUNCTION WebExpensiveDelete(
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      idWebExpensive  IN WEB_EXPENSIVE.WEB_EXPENSIVE_ID%type,
      oMsg                OUT NOCOPY VARCHAR2
   )
      RETURN NUMBER IS
   BEGIN

      delete
        WEB_EXPENSIVE
      where
        WEB_EXPENSIVE_ID=idWebExpensive;

   RETURN WEB_FUNCTIONS.RETURN_OK;
 END;

  FUNCTION WebExpensiveGetSummary(
      iEcoUsersId         IN WEB_EXPENSIVE_HEAD.WEB_EXPENSIVE_HEAD_ID%TYPE,
      iPcLangId           IN PCS.PC_LANG.PC_LANG_ID%TYPE,
      idWebExpensiveHead  IN WEB_EXPENSIVE.WEB_EXPENSIVE_ID%type,
      oMsg                OUT NOCOPY VARCHAR2
   )
      RETURN NUMBER IS
    nbpositions number(3);
  BEGIN
    select
      count(*) into nbpositions
    from
      web_expensive
    where
      web_expensive_head_id=idWebExpensiveHead;

    select
      '<b>summary</b></br>'||nbpositions||' position(s)...' into oMsg
    from
      dual;
   RETURN WEB_FUNCTIONS.RETURN_OK;
  END;


END web_expensive_fct;
