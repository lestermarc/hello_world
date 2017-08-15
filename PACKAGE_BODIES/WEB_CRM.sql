--------------------------------------------------------
--  DDL for Package Body WEB_CRM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_CRM" IS
/**
* get the status description of the status code
*/
 FUNCTION GET_BODY_MAIL_THANKS
                     ( pEve_Number PAC_EVENT.EVE_NUMBER%TYPE) RETURN VARCHAR2 IS
  mailBody VARCHAR2(4000);
  dicPolitness DICO_DESCRIPTION.DIT_DESCR%TYPE;
  pacEventId PAC_EVENT.PAC_EVENT_ID%TYPE;
  BEGIN
    SELECT MAX(PAC_EVENT_ID) INTO pacEventId FROM PAC_EVENT WHERE eve_number=pEve_Number;
    SELECT dic_person_politness_id INTO  dicPolitness FROM PAC_PERSON p, PAC_EVENT e WHERE p.pac_person_id = e.pac_person_id AND e.pac_event_id=pacEventId;
    mailBody := '<html><BODY><a href="http://www.pro-concept.com"><img border=0 src="http://127.0.0.1:8870/eAsa/pictures/logo_eConcept.png"></a><h1>Bonjour '||dicPolitness||'</h1>Merci pour votre intérêt.<br>Votre demande no'||pEve_Number||' sera traitée dans les meilleurs délais.<br><br>Toute l''équipe eConcept.</BODY></html>';

    RETURN mailBody;
  END;

 FUNCTION GET_BODY_MAIL_CONFIRM
                     (pEmail WEB_USER.WEU_EMAIL%TYPE) RETURN VARCHAR2 IS
  mailBody VARCHAR2(4000);
  id WEB_USER.WEB_USER_ID%TYPE;
 BEGIN
    SELECT web_user_id INTO id FROM WEB_USER WHERE UPPER(weu_login_name)=UPPER(pEmail);
    mailBody := '<html><BODY><a href="http://www.pro-concept.com"><img border=0 src="http://127.0.0.1:8870/eAsa/pictures/logo_eConcept.png"></a><h1>Confirmation de l''adresse mail'||pEmail||'</h1><a href="http://localhost/eAsa"></a><br><br><br>Toute l''équipe eConcept.</BODY></html>';
	RETURN mailBody;
 END;

 FUNCTION GET_BODY_MAIL_THANKS_REG
                     (pEmail WEB_USER.WEU_EMAIL%TYPE) RETURN VARCHAR2 IS
  mailBody VARCHAR2(4000);
  vPassword WEB_USER.WEU_PASSWORD_VALUE%TYPE;
 BEGIN
   SELECT weu_password_value INTO vPassword FROM WEB_USER WHERE UPPER(weu_login_name)=UPPER(pEmail);
    mailBody := '<html><BODY><a href="http://www.pro-concept.com"><img border=0 src="http://127.0.0.1:8870/eAsa/pictures/logo_eConcept.png"></a><h1>Merci de vous être enregistré.</h1><br>Adresse de votre compte :'||pEmail||'<br>Mot de passe : '||vPassword||'<br><br>Toute l''équipe eConcept.</BODY></html>';
	RETURN mailBody;
 END;

 FUNCTION GET_BODY_MAIL_THANKS_REG_PROD
                     (pAreNumber ASA_GUARANTY_CARDS.AGC_NUMBER%TYPE) RETURN VARCHAR2 IS
  mailBody VARCHAR2(4000);
 BEGIN
--    SELECT  WHERE are_number=pAreNumber;
    mailBody := '<html><BODY><a href="http://www.pro-concept.com"><img border=0 src="http://localhost:8870/eAsa/pictures/logo_eConcept.png"></a><h1>Merci de vous être enregistré.</h1><br>Merci pour avoir enregistré votre produit.<br><br>Toute l''équipe eConcept.</BODY></html>';
    RETURN mailBody;
  END;

  FUNCTION GET_BODY_MAIL_THANKS_STOLEN
                      (pAsgNumber ASA_STOLEN_GOODS.ASG_NUMBER%TYPE) RETURN VARCHAR2 IS
  mailBody VARCHAR2(4000);
  short VARCHAR2(100);
    Reference VARCHAR2(100);
	  serie VARCHAR2(100);
BEGIN
  SELECT
    des_short_description, goo_major_reference, asg_char1_value
    INTO short,reference,serie
  FROM
    ASA_STOLEN_GOODS a, GCO_GOOD g, GCO_DESCRIPTION d
  WHERE
    a.gco_good_id=g.gco_good_id AND d.gco_good_id= g.gco_good_id AND c_description_type='01' AND pc_lang_id=1 AND asg_number = pAsgNumber;

    mailBody := '<html><BODY><a href="http://www.pro-concept.com"><img border=0 src="http://localhost:8870/eAsa/pictures/logo_eConcept.png"></a><br> <h1>Bonjour,</h1> <h2>Vous nous avez contacté concernant :</h2><br>Le dossier no '||pAsgNumber||' traitant du vol du produit '||short||' ('||reference||') identifié sous le no '||serie||'.<br> Nous allons traiter votre demande dans les meilleures délais. <br><br>Toute l''équipe eConcept.<br><hr>Tel. +41 32 488 38 38</BODY></html>';
    RETURN mailBody;
  END;

 FUNCTION GET_BODY_MAIL_STOLEN_CONTACT
                      (pEmailContactRefStolenMessage VARCHAR2) RETURN VARCHAR2 IS
  mailBody VARCHAR2(4000);
  BEGIN
    mailBody := '<html><BODY><a href="http://www.pro-concept.com"><img border=0 src="http://localhost:8870/eAsa/pictures/logo_eConcept.png"></a>'||
	'<h1>Contact pris sur pièce volée :</h1><br>Email - Dossier :<br>'||pEmailContactRefStolenMessage||'.</BODY></html>';
    RETURN mailBody;
  END;


 FUNCTION GET_BODY_MAIL_CONFIRM_STOL_REG
                      (pAsgNumber ASA_STOLEN_GOODS.ASG_NUMBER%TYPE) RETURN VARCHAR2 IS
  mailBody VARCHAR2(4000);
  short VARCHAR2(100);
    Reference VARCHAR2(100);
	  serie VARCHAR2(100);
BEGIN
  SELECT
    des_short_description, goo_major_reference, asg_char1_value
    INTO short,reference,serie
  FROM
    ASA_STOLEN_GOODS a, GCO_GOOD g, GCO_DESCRIPTION d
  WHERE
    a.gco_good_id=g.gco_good_id AND d.gco_good_id= g.gco_good_id AND c_description_type='01' AND pc_lang_id=1 AND asg_number = pAsgNumber;

    mailBody := '<html><BODY><a href="http://www.pro-concept.com"><img border=0 src="http://localhost:8870/eAsa/pictures/logo_eConcept.png"></a><br> <h1>Bonjour,</h1> <h2>Vous nous avez contacté concernant :</h2><br>Le dossier no '||pAsgNumber||' traitant du vol du produit '||short||' ('||reference||') identifié sous le no '||serie||'.<br> Nous allons traiter votre demande dans les meilleures délais. <br><br>Toute l''équipe eConcept.<br><hr>Tel. +41 32 488 38 38</BODY></html>';
    RETURN mailBody;
  END;


END Web_Crm;
