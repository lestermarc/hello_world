--------------------------------------------------------
--  DDL for Package Body SQM_AUDIT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_AUDIT_FUNCTIONS" 
is
/*--------------------------------------------------------------------------------------------------------------------*/
  procedure CalcAuditResult(aAuditID in SQM_AUDIT.SQM_AUDIT_ID%type, aResult out number)
  is
    cursor crQuestion
    is
      select case
               when SAX.C_AXIS_TYPE = '3' then (select case
                                                         when to_char(count(*) ) = 0 then '0'
                                                         else '3'
                                                       end
                                                  from SQM_AXIS_VALUE
                                                 where SQM_AXIS_ID = SAX.SQM_AXIS_ID)
               else SAX.C_AXIS_TYPE
             end C_AXIS_TYPE
           , ADE.SQM_AXIS_VALUE_ID
           , ADE.ADE_ANSWER_NUMBER
           , ADE.ADE_ANSWER_TEXT
           , AXV.AXV_VALUE
           , ADE.SQM_AUDIT_DETAIL_ID
           , AQU.SQM_SCALE_ID
           , AQU.AQU_GENERATE_PENALTY
           , ACH.ACH_EVAL_INTEGRATION
           , AUD.PAC_THIRD_ID
           , AUM.AUM_PSEUDO_GOOD_ID
           , nvl(AUD.AUD_DATE, trunc(sysdate) ) AUD_DATE
           , AQU.SQM_AXIS_ID
           , AQU.SQM_AUDIT_CHAPTER_ID
           , AQU.SQM_AUDIT_QUESTION_ID
           , ADE.ADE_MCQ_SELECTED
        from SQM_AUDIT_DETAIL ADE
           , SQM_AUDIT_QUESTION AQU
           , SQM_AXIS SAX
           , SQM_AXIS_VALUE AXV
           , SQM_AUDIT_CHAPTER ACH
           , SQM_AUDIT AUD
           , SQM_AUDIT_MODEL AUM
       where AUD.SQM_AUDIT_ID = aAuditID
         and ADE.SQM_AUDIT_ID = AUD.SQM_AUDIT_ID
         and ADE.SQM_AUDIT_QUESTION_ID = AQU.SQM_AUDIT_QUESTION_ID
         and AQU.SQM_AXIS_ID = SAX.SQM_AXIS_ID
         and AXV.SQM_AXIS_VALUE_ID(+) = ADE.SQM_AXIS_VALUE_ID
         and ACH.SQM_AUDIT_CHAPTER_ID = AQU.SQM_AUDIT_CHAPTER_ID
         and AUM.SQM_AUDIT_MODEL_ID = AUD.SQM_AUDIT_MODEL_ID;

    tplQuestion  crQuestion%rowtype;
    vContinue    boolean;
    vInitValue   SQM_PENALTY.SPE_INIT_VALUE%type;
    vDetailValue SQM_AUDIT_DETAIL.ADE_POINTS%type;
    vAuditValue  SQM_AUDIT.AUD_RESULT%type;

    /* Fonction de calcul des points du chapitre */
    function CalcChapter(aChapterID in SQM_AUDIT_CHAPTER.SQM_AUDIT_CHAPTER_ID%type)
      return SQM_AUDIT_DETAIL.ADE_POINTS%type
    is
      vSQL    SQM_INITIALIZATION_METHOD.SIM_FUNCTION%type;
      vResult SQM_AUDIT_DETAIL.ADE_POINTS%type;
    begin
      -- Récupération de la méthode d'initialisation
      begin
        select SIM_FUNCTION
          into vSQL
          from SQM_AUDIT_CHAPTER ACH
             , SQM_AXIS SAX
             , SQM_INITIALIZATION_METHOD SIM
         where SAX.SQM_AXIS_ID = ACH.SQM_AXIS_ID
           and ACH.SQM_AUDIT_CHAPTER_ID = aChapterID
           and SAX.SQM_INITIALIZATION_METHOD_ID = SIM.SQM_INITIALIZATION_METHOD_ID;

        -- Exécution de la méthode et calcul des valeurs
        execute immediate 'begin ' || vSQL || '(:aAuditID,:aChapterID,:aValue);end;'
                    using aAuditID, aChapterID, out vResult;
      exception
        when no_data_found then
          vResult  := null;
        when others then
          vResult  := null;
      end;

      return vResult;
    end CalcChapter;

    /* Fonction de calcul des points de l'audit */
    function CalcAudit
      return SQM_AUDIT.AUD_RESULT%type
    is
      vSQL    SQM_AUDIT_CALC_METHOD.ACM_FUNCTION%type;
      vResult SQM_AUDIT.AUD_RESULT%type;
    begin
      -- Récupération de la méthode de calcul
      begin
        select ACM_FUNCTION
          into vSQL
          from SQM_AUDIT AUD
             , SQM_AUDIT_MODEL AUM
             , SQM_AUDIT_CALC_METHOD ACM
         where AUM.SQM_AUDIT_CALC_METHOD_ID = ACM.SQM_AUDIT_CALC_METHOD_ID
           and AUD.SQM_AUDIT_MODEL_ID = AUM.SQM_AUDIT_MODEL_ID
           and AUD.SQM_AUDIT_ID = aAuditID;

        -- Exécution de la méthode et calcul des valeurs
        execute immediate 'begin ' || vSQL || '(:aAuditID,:aValue);end;'
                    using aAuditID, out vResult;
      exception
        when no_data_found then
          vResult  := null;
        when others then
          vResult  := null;
      end;

      return vResult;
    end CalcAudit;
  begin
/*****************************************************************/
/* 1. Vérifier que chaque question est associée à un axe qualité */
/*****************************************************************/
    select 1 - least(count(*), 1)
      into aResult
      from SQM_AUDIT_DETAIL ADE
         , SQM_AUDIT_QUESTION AQU
     where ADE.SQM_AUDIT_ID = aAuditID
       and ADE.SQM_AUDIT_QUESTION_ID = AQU.SQM_AUDIT_QUESTION_ID
       and AQU.SQM_AXIS_ID is null;

    if aResult = 1 then
/*******************************************************/
/* 2. Contrôle si toutes les questions ont une réponse */
/*******************************************************/
      for tplQuestion in crQuestion loop
        -- Axe de type alphanumérique avec tabelle de valeur ou booléen
        if to_number(tplQuestion.C_AXIS_TYPE) in(1, 3) then
          vContinue  := tplQuestion.SQM_AXIS_VALUE_ID is not null;
        -- Axe de type numérique
        elsif tplQuestion.C_AXIS_TYPE = '2' then
          vContinue  := tplQuestion.ADE_ANSWER_NUMBER is not null;
        -- Axe de type alphanumérique sans tabelle de valeur (type virtuellement passé à 0)
        elsif tplQuestion.C_AXIS_TYPE = '0' then
          vContinue  := tplQuestion.ADE_ANSWER_TEXT is not null;
        end if;

        -- On interrompt la boucle dès qu'une question n'a pas de réponse
        if (not vContinue) then
          aResult  := 0;
        end if;

        exit when(aResult = 0);
      end loop;

/*********************************************/
/* 3. Calcul des points pour chaque question */
/*********************************************/

      -- Toutes les questions ont une réponse
      if vContinue then
        for tplQuestion in crQuestion loop
          -- Recherche de la valeur à prendre en compte à la lecture de la tabelle
          if to_number(tplQuestion.C_AXIS_TYPE) in(1, 3) then
            vInitValue  := tplQuestion.AXV_VALUE;
          elsif tplQuestion.C_AXIS_TYPE = '2' then
            vInitValue  := tplQuestion.ADE_ANSWER_NUMBER;
          end if;

          if tplQuestion.C_AXIS_TYPE <> '0' then
            vDetailValue  := SQM_FUNCTIONS.CalcPenalty(tplQuestion.SQM_SCALE_ID, vInitValue);

            -- Mise à jour du nombre de points de la question
            update SQM_AUDIT_DETAIL
               set ADE_POINTS = vDetailValue
                 , A_DATEMOD = sysdate
                 , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
             where SQM_AUDIT_DETAIL_ID = tplQuestion.SQM_AUDIT_DETAIL_ID
               and ADE_MCQ_SELECTED = 1;
          end if;

          -- Génération des notes qualité si non générée au niveau du chapitre
          if     (tplQuestion.ACH_EVAL_INTEGRATION = 0)
             and (tplQuestion.AQU_GENERATE_PENALTY = 1) then
            insert into SQM_PENALTY
                        (SQM_PENALTY_ID
                       , PAC_THIRD_ID
                       , GCO_GOOD_ID
                       , C_PENALTY_STATUS
                       , SPE_DATE_REFERENCE
                       , A_DATECRE
                       , A_IDCRE
                       , SQM_AXIS_ID
                       , SPE_MANUAL_PENALTY
                       , SPE_CALC_PENALTY
                       , SQM_AUDIT_ID
                       , SQM_AUDIT_CHAPTER_ID
                       , SQM_AUDIT_QUESTION_ID
                        )
              select INIT_ID_SEQ.nextval
                   , tplQuestion.PAC_THIRD_ID
                   , tplQuestion.AUM_PSEUDO_GOOD_ID
                   , 'CONF'
                   , tplQuestion.AUD_DATE
                   , sysdate
                   , pcs.PC_I_LIB_SESSION.GetUserIni
                   , tplQuestion.SQM_AXIS_ID
                   , 0
                   , vDetailValue
                   , aAuditID
                   , tplQuestion.SQM_AUDIT_CHAPTER_ID
                   , tplQuestion.SQM_AUDIT_QUESTION_ID
                from dual;
          end if;
        end loop;
      end if;

/*********************************************/
/* 4. Calcul des points pour chaque chapitre */
/*********************************************/
      for crChapter in (select ADE.SQM_AUDIT_CHAPTER_ID
                             , ADE.SQM_AUDIT_DETAIL_ID
                             , ACH.ACH_EVAL_INTEGRATION
                             , AUD.PAC_THIRD_ID
                             , AUM.AUM_PSEUDO_GOOD_ID
                             , nvl(AUD.AUD_DATE, trunc(sysdate) ) AUD_DATE
                             , ACH.SQM_AXIS_ID
                          from SQM_AUDIT_DETAIL ADE
                             , SQM_AUDIT AUD
                             , SQM_AUDIT_MODEL AUM
                             , SQM_AUDIT_CHAPTER ACH
                         where AUD.SQM_AUDIT_ID = aAuditID
                           and AUD.SQM_AUDIT_ID = ADE.SQM_AUDIT_ID
                           and AUD.SQM_AUDIT_MODEL_ID = AUM.SQM_AUDIT_MODEL_ID
                           and ACH.SQM_AUDIT_CHAPTER_ID = ADE.SQM_AUDIT_CHAPTER_ID
                           and ADE.SQM_AUDIT_QUESTION_ID is null) loop
        vDetailValue  := CalcChapter(crChapter.SQM_AUDIT_CHAPTER_ID);

        -- Mise à jour du nombre de points du chapitre
        update SQM_AUDIT_DETAIL
           set ADE_POINTS = vDetailValue
             , A_DATEMOD = sysdate
             , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
         where SQM_AUDIT_DETAIL_ID = crChapter.SQM_AUDIT_DETAIL_ID
           and SQM_AUDIT_QUESTION_ID is null;

        -- Si le chapitre gère l'intégration avec la qualité, on génère une note par chapitre
        if (crChapter.ACH_EVAL_INTEGRATION = 1) then
          insert into SQM_PENALTY
                      (SQM_PENALTY_ID
                     , PAC_THIRD_ID
                     , GCO_GOOD_ID
                     , C_PENALTY_STATUS
                     , SPE_DATE_REFERENCE
                     , A_DATECRE
                     , A_IDCRE
                     , SQM_AXIS_ID
                     , SPE_MANUAL_PENALTY
                     , SPE_CALC_PENALTY
                     , SQM_AUDIT_ID
                     , SQM_AUDIT_CHAPTER_ID
                      )
            select INIT_ID_SEQ.nextval
                 , crChapter.PAC_THIRD_ID
                 , crChapter.AUM_PSEUDO_GOOD_ID
                 , 'CONF'
                 , crChapter.AUD_DATE
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                 , crChapter.SQM_AXIS_ID
                 , 0
                 , vDetailValue
                 , aAuditID
                 , crChapter.SQM_AUDIT_CHAPTER_ID
              from dual;
        end if;
      end loop;

/************************************/
/* 5. Calcul du résultat de l'audit */
/************************************/
      vAuditValue  := CalcAudit;

      update SQM_AUDIT
         set AUD_RESULT = vAuditValue
           , AUD_DATE = nvl(AUD_DATE, trunc(sysdate) )
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
       where SQM_AUDIT_ID = aAuditID;

/***************************************************/
/* 6. Mise à jour du statut de l'audit --> Calculé */
/***************************************************/
      update SQM_AUDIT
         set C_SQM_AUDIT_STATUS = '2'
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
       where SQM_AUDIT_ID = aAuditID;
    end if;
  end CalcAuditResult;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure DeleteAuditResult(aAuditID in SQM_AUDIT.SQM_AUDIT_ID%type)
  is
  begin
    -- Effacement des points de tous les détails de l'audit
    update SQM_AUDIT_DETAIL
       set ADE_POINTS = null
     where SQM_AUDIT_ID = aAuditID;

    -- Suppression des notes associées à l'audit
    delete from SQM_PENALTY
          where SQM_AUDIT_ID = aAuditID;

    -- Mise à jour du statut de l'audit à "Saisi"
    update SQM_AUDIT
       set C_SQM_AUDIT_STATUS = '1'
         , AUD_RESULT = null
     where SQM_AUDIT_ID = aAuditID;
  end DeleteAuditResult;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure ConfirmAuditResult(aAuditID in SQM_AUDIT.SQM_AUDIT_ID%type)
  is
  begin
    -- Modification du statut de l'audit à "Liquidé"
    update SQM_AUDIT
       set C_SQM_AUDIT_STATUS = '3'
     where SQM_AUDIT_ID = aAuditID;

    -- Modification du statut des notes associées à l'audit
    update SQM_PENALTY
       set C_PENALTY_STATUS = 'DEF'
     where SQM_AUDIT_ID = aAuditID;
  end ConfirmAuditResult;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure DuplicateModel(aModelID in SQM_AUDIT_MODEL.SQM_AUDIT_MODEL_ID%type, aNewModelID out SQM_AUDIT_MODEL.SQM_AUDIT_MODEL_ID%type)
  is
  begin
    -- ID du nouveau modèle
    select INIT_ID_SEQ.nextval
      into aNewModelID
      from dual;

    -- Création du nouveau modèle par copie de la source
    insert into SQM_AUDIT_MODEL
                (SQM_AUDIT_MODEL_ID
               , C_SQM_AUDIT_TYPE
               , C_SQM_AUM_STATUS
               , SQM_AUDIT_CALC_METHOD_ID
               , AUM_PSEUDO_GOOD_ID
               , AUM_DESCRIPTION
               , AUM_VERSION
               , AUM_COMMENT
               , A_DATECRE
               , A_IDCRE
                )
      select aNewModelID
           , C_SQM_AUDIT_TYPE
           , '0'   -- C_SQM_AUM_STATUS
           , SQM_AUDIT_CALC_METHOD_ID
           , AUM_PSEUDO_GOOD_ID
           , AUM_DESCRIPTION
           , substr(AUM_VERSION, 0, 5) || '<NEW>'
           , AUM_COMMENT
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from SQM_AUDIT_MODEL
       where SQM_AUDIT_MODEL_ID = aModelID;

    -- Ajout des liens avec les chapitres
    insert into SQM_AUDIT_CHAP_S_MODEL
                (SQM_AUDIT_MODEL_ID
               , SQM_AUDIT_CHAPTER_ID
               , CSM_WEIGHT
               , CSM_SEQUENCE
               , A_DATECRE
               , A_IDCRE
                )
      select aNewModelID
           , SQM_AUDIT_CHAPTER_ID
           , CSM_WEIGHT
           , CSM_SEQUENCE
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from SQM_AUDIT_CHAP_S_MODEL
       where SQM_AUDIT_MODEL_ID = aModelID;
  end DuplicateModel;
end SQM_AUDIT_FUNCTIONS;
