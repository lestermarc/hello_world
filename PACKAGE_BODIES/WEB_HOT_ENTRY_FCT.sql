--------------------------------------------------------
--  DDL for Package Body WEB_HOT_ENTRY_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_HOT_ENTRY_FCT" IS
  /**
  * Création pour l'utilisateur web en cours d'une nouvelle ligne en statut 00

  Si l'utilisateur web n'est pas trouvé la procédure renvoir 2 et l'ID = 0
  Sinon la ligne est créée (sans commit) et l'ID retourné

  Valeurs de retour
  PUBLIC STATIC INT ERROR       = 0; //WHEN technical error IS encountred
  PUBLIC STATIC INT FATAL_ERROR = 1; //RETURN BY plsql
  PUBLIC STATIC INT WARNING     = 2; //RETURN BY plsql
  PUBLIC STATIC INT OK          = 3; //RETURN BY plsql

        DECLARE
          A VARCHAR2(2000);
          N NUMBER(1);
        BEGIN
        n:=Web_Hot_Entry_Fct.WHE_LF_CREATE(123,A);
        DBMS_OUTPUT.PUT_LINE('result : '||n);
        DBMS_OUTPUT.PUT_LINE('newId='||A);
        END;

  **/
  FUNCTION WHE_LF_CREATE(aWEB_USER_ID WEB_USER.WEB_USER_ID%TYPE, newId OUT WEB_HOT_ENTRY.WEB_HOT_ENTRY_ID%TYPE) RETURN NUMBER IS
    n NUMBER(1);
  BEGIN
    SELECT COUNT(*) INTO n FROM WEB_USER WHERE web_user_id=aWEB_USER_ID;

    IF (n=0) THEN
      BEGIN
        newId :=0;
        RETURN 2;
      END;
    END IF;

    SELECT init_id_seq.NEXTVAL INTO newId FROM dual;

    INSERT INTO WEB_HOT_ENTRY (
        WEB_HOT_ENTRY_ID, WEB_USER_ID, WHE_NUMBER, WHE_SUBJECT, PAC_EVENT_ID,
        WHE_DESCRIPTION, WHE_CONTEXT_COD1, WHE_CONTEXT_COD2, WHE_CONTEXT_COD3, WHE_CONTEXT_COD4,
        WHE_CONTEXT_COD5, WHE_CONTEXT_COD6, WHE_CONTEXT_BOOL1, WHE_CONTEXT_BOOL2, WHE_CONTEXT_BOOL3,
        WHE_CONTEXT_BOOL4, WHE_CONTEXT_BOOL5, WHE_CONTEXT_BOOL6, WHE_CONTEXT_TXT1, WHE_CONTEXT_TXT2,
        WHE_CONTEXT_TXT3, WHE_CONTEXT_TXT4, WHE_CONTEXT_TXT5, WHE_CONTEXT_TXT6, WHE_CONTEXT_DATE1,
        WHE_CONTEXT_DATE2, WHE_CONTEXT_DATE3, C_WEB_HOT_ENTRY_STATE, A_DATECRE, A_IDCRE, A_DATEMOD,
        A_IDMOD ) VALUES (
        newId, aWEB_USER_ID, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
        , NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, SYSDATE, NULL, NULL, '00',  SYSDATE
        , 'WEB', NULL, NULL);
     RETURN 3;

     EXCEPTION WHEN OTHERS THEN
       RETURN 0;
  END;
  /**
  * retourne un message de remerciement
    retourne 0 si l'id ne correspond pas à une entrée existante

    DECLARE
      A VARCHAR2(2000);
      N NUMBER(1);
    BEGIN
    n:=Web_Hot_Entry_Fct.WHE_LF_TRANSMIT(1,A);
    DBMS_OUTPUT.PUT_LINE('result : '||n);
    DBMS_OUTPUT.PUT_LINE('msg='||A);
    END;

  */
  FUNCTION WHE_LF_TRANSMIT(aWEB_HOT_ENTRY_ID WEB_HOT_ENTRY.WEB_HOT_ENTRY_ID%TYPE, msg OUT VARCHAR2) RETURN NUMBER IS
    A VARCHAR2(400);
    N NUMBER(1);
    WebName WEB_USER.WEU_LAST_NAME%TYPE;
    aEventType PAC_EVENT_TYPE.TYP_DESCRIPTION%type;
    aUser PCS.PC_USER.USE_NAME%type;
    aNewPacEventId PAC_EVENT.PAC_EVENT_ID%type;
    aPacNumber PAC_EVENT.EVE_NUMBER%type;
    aLangId PCS.PC_LANG.PC_LANG_ID%type;
  BEGIN
    select
      init_id_seq.nextval into aNewPacEventId
    from
      dual;

	aEventType := 'Intervention Hot-Line';

    aUser := 'ECONCEPT';

    select pc_lang_id into aLangId from web_user u, web_hot_entry e
    where
      e.WEB_USER_ID= u.WEB_USER_ID
      and web_hot_entry_id=aWEB_HOT_ENTRY_ID;

    SELECT COUNT(*) INTO n FROM WEB_HOT_ENTRY WHERE WEB_HOT_ENTRY_ID=aWEB_HOT_ENTRY_ID;
    IF (n=0) THEN
      BEGIN
        msg := 'No entry with ID '||aWEB_HOT_ENTRY_ID;
        RETURN 0;
      END;
    END IF;

	-- Ne pas changer svp la totalité du select.
	-- On peut changer 4 caracteres:  HOT-  en  XXX-  et  en trois endroits
	-- generer dans la table WEB_HOT_ENTRY   WHE_NUMBER
	-- HOT-07-000001,HOT-07-000002,etc      (07 : annee)

	select 'HOT-'||to_char(sysdate,'yy')||'-'||
     lpad(to_number(substr(nvl(max (whe_number),'HOT-'||to_char(sysdate,'yy')||'-'||'000000'),8,6)+1),6,'0')
    into A
    from web_hot_entry
    where whe_number like 'HOT-'||to_char(sysdate,'yy')||'-%';


    UPDATE WEB_HOT_ENTRY
    SET WHE_NUMBER=A
    WHERE WEB_HOT_ENTRY_ID=aWEB_HOT_ENTRY_ID;

    SELECT WEU_LAST_NAME INTO WebName FROM WEB_USER WHERE WEB_USER_ID=(SELECT web_user_id FROM WEB_HOT_ENTRY WHERE web_hot_entry_id=aWEB_HOT_ENTRY_ID);

    /** transfert depuis WEB_HOT_ENTRY -> PAC_EVENT
    */

  --Génération du numéro  old  not use  because  it is false
  --select 'TT-'||to_char(sysdate,'yy')||'-'||lpad(count(*)+1,5,'0') into aPacNumber
  --from
  --  pac_event e,
   -- pac_event_type t
  --where
  --  e.pac_event_type_id=t.pac_event_type_id
  --  and typ_description=aEventType;
  --Génération du numéro dans PAC_EVENT   : max len 9 caracteres
  -- prendre max des 5 derniers chiffres+1,fiable code: H07-00001, H07-00002 ,etc
  -- peut changer la caractre H  en une autre  de A à Z   (et en trois endroits)
  select 'H'||to_char(sysdate,'yy')||'-'||
    lpad(to_number(substr(nvl (max(eve_number),'H'||to_char(sysdate,'yy')||'-'||'00000'),5,5)+1),5,'0')
	into aPacNumber
	from pac_event e, pac_event_type t
	where e.pac_event_type_id=t.pac_event_type_id
	and typ_description=aEventType
	and eve_number like 'H'||to_char(sysdate,'yy')||'-%';


  --Création dans PAC_EVENT
  INSERT INTO PAC_EVENT (
        PAC_EVENT_ID,
        PAC_PERSON_ID,
        EVE_SUBJECT,
        EVE_TEXT,
        EVE_NUMBER,
        EVE_USER_ID,
        PC_USER_ID,
        PAC_EVENT_TYPE_ID,
        DIC_PRIORITY_CODE_ID,
        PAC_ASSOCIATION_ID,
        A_DATECRE,
        A_IDCRE,
        EVE_DATE,
        EVE_CAPTURE_DATE)
    SELECT
        aNewPacEventId,                                                        --PAC_EVENT_ID
        a.pac_person_id,                                                       --PAC_PERSON_ID
        whe_subject,                                                           --EVE_SUBJECT
        whe_description,                                                       --EVE_TEXT
        aPacNumber,                                                            --EVE_NUMBER
        0,                                                                     --EVE_USER_ID
        (select pc_user_id from pcs.pc_user where use_name like aUser),        --PC_USER_ID
        (select pac_event_type_id from pac_event_type where typ_description=aEventType), --PAC_EVENT_TYPE_ID
        whe_context_cod4,                                                      --DIC_PRIORITY_CODE_ID
        pac_person_association_id,                                             --PAC_ASSOCIATION_ID
        sysdate,                                                               --A_DATECRE
        'PROC',                                                                --A_IDCRE
        WHE_CONTEXT_DATE1,                                                     --EVE_DATE
        WHE_CONTEXT_DATE1                                                      --EVE_CAPTURE_DATE
    from
        web_hot_entry e,
        web_user u,
        pac_person_association a
    where
      a.pac_pac_person_id=u.pac_person_id
      and e.web_user_id=u.web_user_id
      and web_hot_entry_id=aWEB_HOT_ENTRY_ID;


  -- copie des pièces jointes
  insert into com_img_linked_files (
  COM_IMG_LINKED_FILES_ID,
  CLF_TABLE,
  CLF_REC_ID,
  CLF_SEQUENCE,
  CLF_DESCR,
  CLF_LINKED_FILE,
  CLF_FILENAME,
  CLF_FILE,
  CLF_STORED_IN,
  COM_OLE_ID,
  A_DATECRE,
  A_IDCRE)
  select
      init_id_seq.nextval,
      'PAC_EVENT',
      aNewPacEventId,
      CLF_SEQUENCE,
      CLF_DESCR,
      CLF_LINKED_FILE,
	  CLF_FILENAME,
      CLF_FILE,
      CLF_STORED_IN,
      COM_OLE_ID,
      sysdate,
      A_IDCRE
  from
    com_img_linked_files where clf_table='WEB_HOT_ENTRY' and clf_rec_id=aWEB_HOT_ENTRY_ID;


    UPDATE WEB_HOT_ENTRY SET C_WEB_HOT_ENTRY_STATE='01' WHERE WEB_HOT_ENTRY_ID=aWEB_HOT_ENTRY_ID;

    UPDATE WEB_HOT_ENTRY SET PAC_EVENT_ID=aNewPacEventId WHERE WEB_HOT_ENTRY_ID=aWEB_HOT_ENTRY_ID;

    msg := WebName||' ,'|| pcs.pc_functions.TRANSLATEWORD('Nous vous contacterons dès que possible',aLangId)||'|'||A;
     RETURN 3;

     EXCEPTION WHEN OTHERS THEN
	 raise;
       RETURN 0;
  END;
END;
