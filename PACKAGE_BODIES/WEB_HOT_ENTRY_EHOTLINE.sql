--------------------------------------------------------
--  DDL for Package Body WEB_HOT_ENTRY_EHOTLINE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_HOT_ENTRY_EHOTLINE" 
AS
/******************************************************************************
   NAME:       WEB_HOT_ENTRY_EHOTLINE
   PURPOSE: : version ProConcept

* @version 400.01
* @lastUpdate 01.04.2009


   REVISIONS:
   03/10/2007             1. Created this package body.
   04.03.2008 RRI Correction tranfert des pièces jointes
   24.04.2008 RRI Correction recherche d'un pacEventType par défaut pour le transmit

   ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   06/2008 LTR  update to  ECONCEPT.ECO_USERS



   +eco_users_id au lieu de  web_users_id
   +rajouter  eco_users_id qui pointe sur ECONCEPT.ECO_USERS
   Le champ web_user_id= (doit avoir un id pour pouvoir inserer)
   (60008964050   pour develop sur DEV1252A)  de la function WHE_LF_CREATE
   WEB_USER_ID=60008964050  EN DUR  existe dans  WEB_USER.
   Pour la nouvelle version WEB_USER_ID  not USE.

   0.01.2009 RRI ajout retour charriot dans concaténation commentaire

******************************************************************************/
   FUNCTION whe_lf_create (
      aeco_users_id            NUMBER,
      alangid         IN       NUMBER,
      newid           OUT      NUMBER
   )
      RETURN NUMBER
   IS
      n   NUMBER (1);
   BEGIN
      SELECT COUNT (*)
        INTO n
        FROM econcept.eco_users
       WHERE eco_users_id = aeco_users_id;

      IF (n = 0)
      THEN
         BEGIN
            newid := 0;
            RETURN web_functions.return_warning;
         END;
      END IF;

      SELECT init_id_seq.NEXTVAL
        INTO newid
        FROM DUAL;

      INSERT INTO web_hot_entry
                  (web_hot_entry_id, web_user_id, whe_number, whe_subject,
                   pac_event_id, whe_description, whe_context_cod1,
                   whe_context_cod2, whe_context_cod3, whe_context_cod4,
                   whe_context_cod5, whe_context_cod6, whe_context_bool1,
                   whe_context_bool2, whe_context_bool3, whe_context_bool4,
                   whe_context_bool5, whe_context_bool6, whe_context_txt1,
                   whe_context_txt2, whe_context_txt3, whe_context_txt4,
                   whe_context_txt5, whe_context_txt6, whe_context_date1,
                   whe_context_date2, whe_context_date3,
                   c_web_hot_entry_state, a_datecre, a_idcre, a_datemod,
                   a_idmod, eco_users_id
                  )
           VALUES (newid, NULL, NULL, NULL,
                   NULL, NULL, NULL,
                   NULL, NULL, NULL,
                   NULL, NULL, NULL,
                   NULL, NULL, NULL,
                   NULL, NULL, NULL,
                   NULL, NULL, NULL,
                   NULL, NULL, SYSDATE,
                   NULL, NULL,
                   '00', SYSDATE, 'WEB', NULL,
                   NULL, aeco_users_id
                  );

      RETURN web_functions.return_ok;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END;

   /**
   *  transmission de la demande et
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

   /** -----------------------------------------------------------
Changement:
WebName          ECONCEPT.ECO_USERS.ECU_DISPLAY_NAME%type;
ltr 06/02/09: sujetdemande   web_hot_entry.whe_subject%TYPE;
*---------------------------------------------------------------
*/
   FUNCTION whe_lf_transmit (
      aweb_hot_entry_id            NUMBER,
      alangid             IN       NUMBER,
      acompanyid          IN       NUMBER,
      msg                 OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      anewnumber                pac_event.eve_number%TYPE;
      n                         NUMBER (1);
      webname                   econcept.eco_users.ecu_display_name%TYPE;
      aeventtype                pac_event_type.typ_description%TYPE;
      auser                     pcs.pc_user.use_name%TYPE;
      anewpaceventid            pac_event.pac_event_id%TYPE;
      apacpersonid              pac_person.pac_person_id%TYPE;
      vpaceventtypeid           pac_event.pac_event_type_id%TYPE;
      vcontrol                  NUMBER (1);
      vpacpersonassociationid   pac_person_association.pac_person_association_id%TYPE;
      vwhecontextdate1          web_hot_entry.whe_context_date1%TYPE;
      vwhesubject               web_hot_entry.whe_subject%TYPE;
      vwhedescription           web_hot_entry.whe_description%TYPE;
      vwhecontextcod4           web_hot_entry.whe_context_cod4%TYPE;
      vpaccontactid             pac_person.pac_person_id%TYPE;
/* ------------------------ */
/*  05/2008                 */
/*  variable pour sendmail  */
/* ------------------------ */
      email                     VARCHAR2 (100);
      sender                    VARCHAR2 (100);
      reply                     VARCHAR2 (100);
      destinataire              VARCHAR2 (100);
      subject                   VARCHAR2 (4000);
      bodytext                  VARCHAR2 (4000);
      errormessages             VARCHAR2 (4000);
      sujetdemande              web_hot_entry.whe_subject%TYPE;
      patchset                  VARCHAR2 (50);
      votreschema               VARCHAR2 (30);
      /* --- end variables sendmail  */
      retvalue                  NUMBER (1);
   BEGIN
      SELECT pac_event_seq.NEXTVAL
        INTO anewpaceventid
        FROM DUAL;

      /* recherche d'un pac_event_type_id par défaut */
      SELECT pac_event_type_id
        INTO vpaceventtypeid
        FROM (SELECT   pac_event_type_id
                  FROM pac_event_type
              ORDER BY DECODE (typ_short_description, 'HTL', 1, 2))
       WHERE ROWNUM = 1;

      auser := 'ECONCEPT';

      /** correspond au champ PAC_CUSTOM_PARTNER_ID =aPacPersonID  en haut*/
      SELECT l.eul_rec_id
        INTO apacpersonid
        FROM econcept.eco_user_links l, web_hot_entry e
       WHERE e.eco_users_id = l.eco_users_id
         AND e.web_hot_entry_id = aweb_hot_entry_id
         AND l.eul_tab = 'PAC_CUSTOM_PARTNER'
         AND l.eco_company_id = acompanyid;

      /** correspond au champ PAC_PERSON_ID  pacContact  en haut */
      SELECT l.eul_rec_id
        INTO vpaccontactid
        FROM econcept.eco_user_links l, web_hot_entry e
       WHERE e.eco_users_id = l.eco_users_id
         AND e.web_hot_entry_id = aweb_hot_entry_id
         AND l.eul_tab = 'PAC_PERSON'
         AND l.eco_company_id = acompanyid;

      /** suite  */
      SELECT whe_context_date1, whe_subject, whe_description,
             whe_context_cod4, ecu_display_name
        INTO vwhecontextdate1, vwhesubject, vwhedescription,
             vwhecontextcod4, webname
        FROM econcept.eco_users u, web_hot_entry e
       WHERE e.web_hot_entry_id = aweb_hot_entry_id
         AND e.eco_users_id = u.eco_users_id;

      /** END new 06/2008  ltr */

      --Recherche de l'association entre user et client
      SELECT COUNT (*)
        INTO vcontrol
        FROM pac_person_association
       WHERE pac_person_id = apacpersonid
             AND pac_pac_person_id = vpaccontactid;

      IF (vcontrol = 1)
      THEN
         SELECT pac_person_association_id
           INTO vpacpersonassociationid
           FROM pac_person_association
          WHERE pac_person_id = apacpersonid
            AND pac_pac_person_id = vpaccontactid;
      ELSIF (vcontrol = 0)
      THEN
         msg := 'No association found.';
         RETURN 0;
      ELSE                                        --on prend le premier trouvé
         SELECT pac_person_association_id
           INTO vpacpersonassociationid
           FROM (SELECT   pac_person_association_id
                     FROM pac_person_association
                    WHERE pac_person_id = apacpersonid
                      AND pac_pac_person_id = vpaccontactid
                 ORDER BY NVL (dic_association_type_id, '') ASC)
          WHERE ROWNUM = 1;
      END IF;

      pac_partner_management.geteventnumber (vpaceventtypeid,
                                             SYSDATE,
                                             anewnumber
                                            );

      SELECT COUNT (*)
        INTO n
        FROM web_hot_entry
       WHERE web_hot_entry_id = aweb_hot_entry_id;

      IF (n = 0)
      THEN
         BEGIN
            msg := 'No entry with ID ' || aweb_hot_entry_id;
            --RETURN 0;
            RETURN web_functions.return_error;
         END;
      END IF;

      UPDATE web_hot_entry
         SET whe_number = anewnumber
       WHERE web_hot_entry_id = aweb_hot_entry_id;

      SELECT COUNT (*)
        INTO vcontrol
        FROM web_hot_entry e, econcept.eco_users u
       --web_user u
      WHERE  web_hot_entry_id = aweb_hot_entry_id
         AND e.eco_users_id = u.eco_users_id;

      --e.web_user_id=u.web_user_id;
      IF (vcontrol = 0)
      THEN
         msg := 'ECONCEPT.ECO_USERS_ID instance not found.';
         --msg :='WEB_USER_ID instance not found.';
         --return 0;
         RETURN web_functions.return_error;
      END IF;

      INSERT INTO pac_event
                  (pac_event_id, pac_person_id, eve_subject, eve_text,
                   eve_number, eve_user_id, pc_user_id, pac_event_type_id,
                   dic_priority_code_id, pac_association_id, a_datecre,
                   a_idcre, eve_date, eve_capture_date)
         SELECT anewpaceventid,                                 --PAC_EVENT_ID
                               apacpersonid,                   --PAC_PERSON_ID
                                            vwhesubject,         --EVE_SUBJECT
                                                        vwhedescription,

                --EVE_TEXT
                anewnumber,                                       --EVE_NUMBER
                           0,                                    --EVE_USER_ID
                             (SELECT pc_user_id
                                FROM pcs.pc_user
                               WHERE use_name LIKE auser),        --PC_USER_ID
                                                          vpaceventtypeid,

                --PAC_EVENT_TYPE_ID
                vwhecontextcod4,                        --DIC_PRIORITY_CODE_ID
                                vpacpersonassociationid,  --PAC_ASSOCIATION_ID
                                                        SYSDATE,   --A_DATECRE
                                                                'PROC',

                --A_IDCRE
                vwhecontextdate1,                                   --EVE_DATE
                                 vwhecontextdate1           --EVE_CAPTURE_DATE
           FROM DUAL;

  -- copie des pièces jointes uploaded vers l'évênement généré.

      UPDATE web_hot_entry
         SET c_web_hot_entry_state = '01'
       WHERE web_hot_entry_id = aweb_hot_entry_id;

      UPDATE web_hot_entry
         SET pac_event_id = anewpaceventid
       WHERE web_hot_entry_id = aweb_hot_entry_id;

      msg :=
         pcs.pc_functions.translateword
                               ('Nous vous contacterons le plus tôt possible',
                                alangid
                               );
      /* ne pas changer de sytax  : java recupere ce message */
      msg := webname || ', ' || msg || '|' || anewnumber;

/* -----------------------------  */
/* send mail  pour la transmise   */
/* -----------------------------  */
/*                                */

      /* info utile */
      SELECT whe_subject, whe_context_cod6, whe_context_txt2
        INTO sujetdemande, patchset, votreschema
        FROM web_hot_entry
       WHERE web_hot_entry_id = aweb_hot_entry_id;

      sender := 'hotline@proconcept.ch';
      destinataire := email;
      reply := email;
      /*  traduire subject et body en multilangues */
      subject :=
         pcs.pc_functions.translateword ('Demande d intervention numéro',
                                         alangid
                                        );
      subject := subject || ': ' || anewnumber;
      subject :=
            subject
         || ' '
         || pcs.pc_functions.translateword ('Votre demande a été transmise',
                                            alangid
                                           );
      bodytext := bodytext || '  Sujet=' || sujetdemande;
      bodytext := bodytext || '  Patchset=' || patchset;
      bodytext := bodytext || '  Schema=' || votreschema;
      bodytext :=
          bodytext || '.' || pcs.pc_functions.translateword ('Merci', alangid);
      n :=
         whe_sendmail (sender,
                       reply,
                       destinataire,
                       subject,
                       bodytext,
                       errormessages
                      );
      RETURN web_functions.return_ok;
   END;

/* -------------------------------------------------- */
/*  new 04/2008   RRi/Ltr                             */
/*  fonction interne  NOT  call par java              */
/* -------------------------------------------------- */
   FUNCTION whe_sendmail (
      asender          IN       VARCHAR2,
      areply           IN       VARCHAR2,
      adestinataire    IN       VARCHAR2,
      asubject         IN       VARCHAR2,
      abody            IN       VARCHAR2,
      aerrormessages   OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue         NUMBER (1);
      verrormessages   VARCHAR2 (4000);
      verrorcodes      VARCHAR2 (4000);
      vmailid          NUMBER;
      --msg              CLOB            DEFAULT NULL;
      --sujet            VARCHAR2 (200);
      --sender           VARCHAR2 (200);
      --reply            VARCHAR2 (200);
   BEGIN
      retvalue := 1;
      /*  Indiv  ICI  msg et sujet,body, sender, reply : multilangue  à  y penser ! */
      --msg := abody;
      --sujet := asubject;
      --sender := asender;
      --reply := areply;
      verrorcodes :=
         eml_sender.createmail
                         (aerrormessages       => verrormessages,
                          asender              => asender,
                          areplyto             => areply,
                          arecipients          => adestinataire,
                          accrecipients        => '',
                          abccrecipients       => '',
                          anotification        => 0,
                          apriority            => eml_sender.cpriotity_high_level,
                          acustomheaders       => 'X-Mailer: PCS mailer',
                          asubject             => asubject,
                          abodyplain           => '',
                          abodyhtml            => abody,
                          asendmode            => eml_sender.csendmode_immediate_forced,
                          adatetosend          => SYSDATE,
                          atimezoneoffset      => SESSIONTIMEZONE    --'02:00'
                                                                 ,
                          abackupmode          => eml_sender.cbackup_database
                         --, aBackupOptions => ''
                         );
      verrorcodes :=
            verrorcodes
         || eml_sender.send (aerrormessages      => verrormessages,
                             amailid             => vmailid
                            );
      --return 3;
      RETURN web_functions.return_ok;
   EXCEPTION
      WHEN OTHERS
      THEN
         --RETURN 0;
         RETURN web_functions.return_error;
         RETURN retvalue;
   END;

/** ---------------------------------------- */
/**    05/02/2009  call par java             */
/**    aDestinataire  email user             */
/**    new password   pour oublier password  */
   FUNCTION sendmailnewpassword (
      aecousersid      IN       NUMBER,
      adestinataire    IN       VARCHAR2,
      anewpassword     IN       VARCHAR2,
      alangid          IN       NUMBER,
      aerrormessages   OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      sender          VARCHAR2 (100);
      reply           VARCHAR2 (100);
      destinataire    VARCHAR2 (100);
      subject         VARCHAR2 (4000);
      bodytext        VARCHAR2 (4000);
      errormessages   VARCHAR2 (4000);
      retvalue        NUMBER (1);
   BEGIN
      aerrormessages := 'OK';
      sender := 'hotline@proconcept.ch';
      destinataire := adestinataire;
      reply := sender;
      /*  traduire subject et body en multilangues */
      subject := pcs.pc_functions.translateword ('Mot de passe', alangid);
      bodytext :=
         pcs.pc_functions.translateword ('Votre nouveau mot de passe',
                                         alangid
                                        );
      /** new password dans bodyText   */
      bodytext := bodytext || ': ' || anewpassword;
      retvalue :=
         whe_sendmail (sender,
                       reply,
                       destinataire,
                       subject,
                       bodytext,
                       errormessages
                      );
      aerrormessages := errormessages;
      RETURN retvalue;
   END;

/** ---------------------------------------------- */
/** Call par Java:  creation Com Img Linked Files  */
/** ---------------------------------------------- */
   FUNCTION createcomimglinkedfile (
      awebhotentryid   IN       NUMBER,
      acomoleid        IN       NUMBER,
      asequence        IN       NUMBER,
      afilename        IN       VARCHAR2,
      aclffile         IN       VARCHAR2,
      alinkedfile      IN       NUMBER,
      astoredb         IN       VARCHAR2,
      atablenamepac             VARCHAR2,
      amsg             OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      newid         com_image_files.com_image_files_id%TYPE;
      vpaceventid   pac_event.pac_event_id%TYPE;
   BEGIN
      amsg := afilename;

/** ------------------- pour COM_IMAGE_FILES --------------  */
/**                     ltr 01/09                            */
/** -------------------------------------------------------  */
      SELECT pac_event_id
        INTO vpaceventid
        FROM web_hot_entry
       WHERE web_hot_entry_id = awebhotentryid;

      amsg := 'vPacEventId=' || vpaceventid;

      SELECT init_id_seq.NEXTVAL
        INTO newid
        FROM DUAL;

      amsg :=
            '-->>newId from com_image_files='
         || newid
         || ' pac_event_id lu='
         || vpaceventid;

      INSERT INTO com_image_files
                  (com_image_files_id, imf_table, imf_rec_id,
                   imf_image_index, imf_sequence, imf_com_image_path,
                   imf_cabinet, imf_drawer, imf_folder, imf_file, imf_descr,
                   imf_stored_in, com_ole_id, a_datecre, a_idcre,
                   imf_pathfile, imf_linked_file
                  )
           VALUES (newid, 'PAC_EVENT', vpaceventid,
                   1, asequence, afilename,
                   NULL, 'PAC_EVENT', NULL, afilename, aclffile,
                   'DB', acomoleid, SYSDATE, 'WEB',
                   afilename, 1
                  );

      amsg := newid || '|' || afilename;
      RETURN web_functions.return_ok;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN web_functions.return_error;
   END;

   FUNCTION getidpacfromid (aidtable IN NUMBER, aiduser IN NUMBER)
      RETURN NUMBER
   IS
      retvalue   NUMBER (12);
   BEGIN
      retvalue := 0;

      SELECT pac_event_id
        INTO retvalue
        FROM web_hot_entry
       WHERE web_hot_entry_id = aidtable AND eco_users_id = aiduser;

      RETURN retvalue;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN web_functions.return_error;
   END;

/** ========================================== */
/**   07/01/2009   new functions              */
/** ==========================================*/
/**  07/01/2009 ----  call From Java */
/**  aUrlDetail url ehotline avec param : a envoyer  */
   FUNCTION closefromcustomer (
      awebhotentryid   IN       NUMBER,
      aecousersid      IN       NUMBER,
      aurldetail       IN       VARCHAR2,
      amsg             OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue        NUMBER (1);
      vecousersid     econcept.eco_users.eco_users_id%TYPE;
      vpaceventid     pac_event.pac_event_id%TYPE;
      email           econcept.eco_users.ecu_email%TYPE;
      sender          VARCHAR2 (100);
      reply           VARCHAR2 (100);
      destinataire    VARCHAR2 (100);
      subject         VARCHAR2 (4000);
      bodytext        VARCHAR2 (4000);
      errormessages   VARCHAR2 (4000);
      sujetdemande    web_hot_entry.whe_subject%TYPE;
      vlangid         econcept.eco_locale.pc_lang_id%TYPE;
      evenumber       web_hot_entry.whe_number%TYPE;
      n               NUMBER (1);
   BEGIN
      amsg := 'error';
      retvalue := web_functions.return_ok;

      SELECT whe_number, whe_subject, eco_users_id, pac_event_id
        INTO evenumber, sujetdemande, vecousersid, vpaceventid
        FROM web_hot_entry
       WHERE web_hot_entry_id = awebhotentryid;

-- attention eEcoUserId  est different  vEcoUsersId : multi users
      IF (vecousersid != aecousersid)
      THEN
         BEGIN
            SELECT ecu_email
              INTO email
              FROM econcept.eco_users
             WHERE eco_users_id = vecousersid;

            amsg :=
               'error: eveNumber=' || evenumber || '  email de demande='
               || email;
            RETURN web_functions.return_error;
         END;
      END IF;

      SELECT ecu_email
        INTO email
        FROM econcept.eco_users
       WHERE eco_users_id = aecousersid;

-- select lang_id
      SELECT el.pc_lang_id
        INTO vlangid
        FROM econcept.eco_locale el, econcept.eco_users eu
       WHERE el.ecl_iso_code = eu.ecl_iso_code
         AND eu.eco_users_id = aecousersid;

--terminer status -------------------------------------------
      UPDATE web_hot_entry
         SET c_web_hot_entry_state = '09',
             whe_context_date3 = SYSDATE
       WHERE web_hot_entry_id = awebhotentryid;

      /** mail */
      sender := 'hotline@proconcept.ch';
      destinataire := email;
      reply := email;
      /**  traduire subject et body en multilangues */
      /**  au users  */
      subject := pcs.pc_functions.translateword ('Cloture du cas', vlangid);
      subject := subject || ': ' || evenumber;
      bodytext := bodytext || '  Sujet=' || sujetdemande;
      bodytext :=
            bodytext
         || '.'
         || pcs.pc_functions.translateword
                              ('La hotline est informée de la cloture du cas',
                               vlangid
                              );
      bodytext := bodytext || '<br>' || aurldetail;
      amsg :=
         'email user=' || email || '  sujet=' || subject || ' body='
         || bodytext;
      /** au utilisateur */
      n :=
         whe_sendmail (sender,
                       reply,
                       destinataire,
                       subject,
                       bodytext,
                       errormessages
                      );
      /** service hotline */
      sender := email;
      destinataire := 'hotline@proconcept.ch';
      reply := destinataire;
      n :=
         whe_sendmail (sender,
                       reply,
                       destinataire,
                       subject,
                       bodytext,
                       errormessages
                      );
      RETURN web_functions.return_ok;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN web_functions.return_error;
   END;

/** ============================================ */
/**   confirmation call from Java                */
/** ============================================ */
   FUNCTION closeconfirmation (
      awebhotentryid   IN       NUMBER,
      aecousersid      IN       NUMBER,
      amsg             OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      email           econcept.eco_users.ecu_email%TYPE;
      displayname     econcept.eco_users.ecu_display_name%TYPE;
      sender          VARCHAR2 (100);
      reply           VARCHAR2 (100);
      destinataire    VARCHAR2 (100);
      subject         VARCHAR2 (4000);
      bodytext        VARCHAR2 (4000);
      errormessages   VARCHAR2 (4000);
      vlangid         NUMBER (1);
      evenumber       web_hot_entry.whe_number%TYPE;
      n               NUMBER (1);
      vecousersid     econcept.eco_users.eco_users_id%TYPE;
      messageconf     VARCHAR2 (128);
   BEGIN
      amsg := 'error';

-- select lang_id
      SELECT el.pc_lang_id
        INTO vlangid
        FROM econcept.eco_locale el, econcept.eco_users eu
       WHERE el.ecl_iso_code = eu.ecl_iso_code
         AND eu.eco_users_id = aecousersid;

/** a indiv */
      SELECT whe_number, eco_users_id
        INTO evenumber, vecousersid
        FROM web_hot_entry
       WHERE web_hot_entry_id = awebhotentryid;

-- attention eEcoUserId  est different  vEcoUsersId : multi users
      IF (vecousersid != aecousersid)
      THEN
         BEGIN
            SELECT ecu_email
              INTO email
              FROM econcept.eco_users
             WHERE eco_users_id = vecousersid;

            amsg :=
               'error: eveNumber=' || evenumber || '  email de Cloture='
               || email;
            RETURN web_functions.return_error;
         END;
      END IF;

      SELECT ecu_email, ecu_display_name
        INTO email, displayname
        FROM econcept.eco_users
       WHERE eco_users_id = aecousersid;

/** --------------------------------------------------  */
--Rajout infos lors de confirmation --
-- set C_WEB_HOT_ENTRRY_STATE=99   NON finalement
/** ---------------------------------------------------- */
      messageconf :=
         pcs.pc_functions.translateword ('Validation de la solution', vlangid);

--16.1.2008 - 16h40 - stephane.portenier@sage.com
      UPDATE web_hot_entry
         SET whe_description =
                   whe_description
                || CHR (13)
                || CHR (10)
                || messageconf
                || ' : '
                || SYSDATE
                || ' '
                || displayname,
             a_idmod = 'WEB'
       WHERE web_hot_entry_id = awebhotentryid;

      amsg := awebhotentryid || '|' || evenumber;

      /** send mail */
      sender := 'hotline@proconcept.ch';
      destinataire := email;
      reply := email;
      /*  traduire subject et body en multilangues */
      subject :=
         pcs.pc_functions.translateword ('Confirmation de la cloture',
                                         vlangid);
      subject := subject || ': ' || evenumber;
      bodytext :=
            bodytext
         || '=>'
         || pcs.pc_functions.translateword ('Validation de la solution',
                                            vlangid
                                           );
      bodytext := bodytext || ' Date de confirmation=' || SYSDATE;
      amsg :=
            'email user='
         || email
         || '  Confirmation ok='
         || bodytext
         || ' '
         || evenumber;
      n :=
         whe_sendmail (sender,
                       reply,
                       destinataire,
                       subject,
                       bodytext,
                       errormessages
                      );
      RETURN web_functions.return_ok;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN web_functions.return_error;
   END;

/** -------------------------------------- */
/**   closeFromHotline call from  Trigger  */
/** -------------------------------------- */
   FUNCTION closefromhotline (
      awebhotentryid   IN       NUMBER,
      aecousersid      IN       NUMBER,
      aurldetail       IN       VARCHAR2,
      amsg             OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue        NUMBER (1);
      vlangid         NUMBER (1);
      vecousersid     econcept.eco_users.eco_users_id%TYPE;
      email           econcept.eco_users.ecu_email%TYPE;
      sender          VARCHAR2 (100);
      reply           VARCHAR2 (100);
      destinataire    VARCHAR2 (100);
      subject         VARCHAR2 (4000);
      bodytext        VARCHAR2 (4000);
      errormessages   VARCHAR2 (4000);
      evenumber       web_hot_entry.whe_number%TYPE;
      n               NUMBER (1);
   BEGIN
      amsg := 'ok';
      retvalue := web_functions.return_ok;

      /** std */

      SELECT el.pc_lang_id
        INTO vlangid
        FROM econcept.eco_locale el, econcept.eco_users eu
       WHERE el.ecl_iso_code = eu.ecl_iso_code
         AND eu.eco_users_id = aecousersid;

-- attention eEcoUserId  est different  vEcoUsersId : multi users
      IF (vecousersid != aecousersid)
      THEN
         BEGIN
            SELECT ecu_email
              INTO email
              FROM econcept.eco_users
             WHERE eco_users_id = vecousersid;

            amsg :=
                  'error: fromHotline eveNumber='
               || evenumber
               || '  email de Cloture='
               || email;
            RETURN web_functions.return_error;
         END;
      END IF;

      SELECT ecu_email
        INTO email
        FROM econcept.eco_users
       WHERE eco_users_id = aecousersid;

      SELECT whe_number
        INTO evenumber
        FROM web_hot_entry
       WHERE web_hot_entry_id = awebhotentryid;

      sender := 'hotline@proconcept.ch';
      destinataire := email;
      reply := email;
      /**  traduire subject et body en multilangues */
      /**  au users  */
      subject := pcs.pc_functions.translateword ('Cloture du cas', vlangid);
      subject := subject || ': ' || evenumber;
      bodytext :=
            bodytext
         || '.'
         || pcs.pc_functions.translateword
                                         ('La hotline a effectuée la Cloture',
                                          vlangid
                                         );
      /** urlDetail contien un lien detail   à mettre  */
      bodytext := bodytext || '<br>' || aurldetail;
      amsg :=
         'email user=' || email || '  sujet=' || subject || ' body='
         || bodytext;
      /** au utilisateur */
      n :=
         whe_sendmail (sender,
                       reply,
                       destinataire,
                       subject,
                       bodytext,
                       errormessages
                      );
      RETURN retvalue;
   END;

/**   addComment call from Java  */
   FUNCTION addcomment (
      awebhotentryid   IN       NUMBER,
      acommentaire     IN       VARCHAR2,
      aecousersid      IN       NUMBER,
      amsg             OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue       NUMBER (1);
      cr             VARCHAR (2);
      vpaceventid    pac_event.pac_event_id%TYPE;
      taille         NUMBER (4);
      taille2        NUMBER (4);
      vcommentaire   VARCHAR2 (4000);
   BEGIN
      cr := CHR (13) || CHR (10);
      amsg := '';
      retvalue := web_functions.return_error;

      SELECT pac_event_id
        INTO vpaceventid
        FROM web_hot_entry
       WHERE web_hot_entry_id = awebhotentryid AND eco_users_id = aecousersid;

-- pour multi_user  pas de filtre par eco_users_id

      IF (vpaceventid IS NOT NULL)
      THEN
         BEGIN
            --test limite de taille atteinte
            SELECT LENGTH (whe_description || cr || cr || acommentaire)
              INTO taille
              FROM web_hot_entry
             WHERE web_hot_entry_id = awebhotentryid;

            SELECT LENGTH (eve_text || cr || cr || acommentaire)
              INTO taille2
              FROM pac_event
             WHERE pac_event_id = vpaceventid;

            IF (taille > 4000)
            THEN
               SELECT (taille - 4000)
                 INTO taille
                 FROM DUAL;

               amsg := 'Comment too long :reduce ' || taille || 'caracters.';
               RETURN web_functions.return_error;
            END IF;

            IF (taille2 > 4000)
            THEN
               SELECT (taille2 - 4000)
                 INTO taille2
                 FROM DUAL;

               amsg := 'Comment too long :reduce ' || taille2 || 'caracters.';
               RETURN web_functions.return_error;
            END IF;

            UPDATE web_hot_entry
               SET whe_description =
                                   whe_description || cr || cr || acommentaire
             WHERE web_hot_entry_id = awebhotentryid;

            UPDATE pac_event
               SET eve_text = eve_text || cr || cr || acommentaire
             WHERE pac_event_id = vpaceventid;

            amsg := vpaceventid || '';
            RETURN web_functions.return_ok;
         EXCEPTION
            WHEN OTHERS
            THEN
               RETURN web_functions.return_error;
         END;
      END IF;

      RETURN retvalue;
   END;

/** call from Java */
   FUNCTION evenementexist (
      awebhotentryid   IN       NUMBER,
      aecousersid      IN       NUMBER,
      amsg             OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      retvalue   NUMBER (1);
      nb         NUMBER (1);
   BEGIN
      amsg := 'ok';
      nb := 0;
      retvalue := web_functions.return_ok;
      RETURN retvalue;
   END;

/** ---------------- */
/** call from java   */
/** ---------------- */
   FUNCTION selectfilenameattach (
      aevenumber       IN       VARCHAR2,
      awebhotentryid   IN       NUMBER,
      amsg             OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      CURSOR cursfilename
      IS
         SELECT imf_file
           FROM com_image_files c, web_hot_entry w
          WHERE imf_table = 'PAC_EVENT'
            AND whe_number = aevenumber
            AND web_hot_entry_id = awebhotentryid
            AND c.a_idcre = 'WEB'
            AND c.imf_stored_in = 'DB'
            AND imf_rec_id = w.pac_event_id;

      retvalue   NUMBER (1);
      filename   VARCHAR2 (250);
   BEGIN
      amsg := '';
      retvalue := web_functions.return_ok;

      OPEN cursfilename;

      LOOP
         FETCH cursfilename
          INTO filename;

         EXIT WHEN cursfilename%NOTFOUND;

         IF (filename IS NOT NULL)
         THEN
            BEGIN
               amsg := amsg || filename || '|';
            END;
         END IF;                           /** end if fileName is not null  */
      END LOOP;

      CLOSE cursfilename;

      IF (amsg IS NULL)
      THEN
         BEGIN
            retvalue := web_functions.return_error;
         END;
      END IF;

      RETURN retvalue;
   END;

/** cal from Java */
   FUNCTION selectcomoleidattach (
      aevenumber       IN       VARCHAR2,
      awebhotentryid   IN       NUMBER,
      amsg             OUT      VARCHAR2
   )
      RETURN NUMBER
   IS
      CURSOR cursole
      IS
         SELECT com_ole_id
           FROM com_image_files c, web_hot_entry w
          WHERE imf_table = 'PAC_EVENT'
            AND w.whe_number = aevenumber
            AND web_hot_entry_id = awebhotentryid
            AND c.a_idcre = 'WEB'
            AND c.imf_stored_in = 'DB'
            AND imf_rec_id = w.pac_event_id;

      retvalue   NUMBER (1);
      oleid      NUMBER (12);
   BEGIN
      amsg := '';
      retvalue := web_functions.return_ok;

      OPEN cursole;

      LOOP
         FETCH cursole
          INTO oleid;

         EXIT WHEN cursole%NOTFOUND;

         IF (oleid IS NOT NULL)
         THEN
            BEGIN
               amsg := amsg || oleid || '|';
            END;
         END IF;
         /** end if oleId is not null  */
      END LOOP;

      CLOSE cursole;

      IF (amsg IS NULL)
      THEN
         BEGIN
            retvalue := web_functions.return_error;
         END;
      END IF;

      RETURN retvalue;
   END;
/**   end 07/01/2009  */
END web_hot_entry_ehotline;
