--------------------------------------------------------
--  DDL for Package Body SQM_CALCULATE_RESULTS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_CALCULATE_RESULTS" 
is
/*-----------------------------------------------------------------------------------*/
  procedure SelectPenalties(pEvaluationId in SQM_EVALUATION.SQM_EVALUATION_ID%type, pGenerated out number)
  is
  begin
    -- recherche des documents non déchargés et création des notes estimées correspondantes
    GenAwaitingPenalties(pEvaluationId);

    -- insertion dans la table des criticités de l'évaluation
    insert into SQM_EVAL_S_PENALTY
                (SQM_EVAL_S_PENALTY_ID
               , SQM_EVALUATION_ID
               , SQM_PENALTY_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval
           , pEvaluationId
           , SPE.SQM_PENALTY_ID
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from SQM_PENALTY SPE
           , SQM_EVALUATION EVA
       where SPE.SPE_DATE_REFERENCE >= EVA.EVA_STARTING_DATE
         and SPE.SPE_DATE_REFERENCE <= EVA.EVA_ENDING_DATE
         and SPE.C_PENALTY_STATUS in('CONF', 'DEF')
         and EVA.SQM_EVALUATION_ID = pEvaluationId
         and (   SPE.SQM_EVALUATION_ID = EVA.SQM_EVALUATION_ID
              or SPE.SQM_EVALUATION_ID is null);

    -- récupère le nombre d'enregistrements insérés
    select count(*)
      into pGenerated
      from SQM_EVAL_S_PENALTY
     where SQM_EVALUATION_ID = pEvaluationId;

    -- si des enregistrements ont été générés, l'évaluation passe au statut EN COURS
    if pGenerated > 0 then
      update SQM_EVALUATION
         set C_SQM_EVALUATION_STATUS = 'ENC'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SQM_EVALUATION_ID = pEvaluationId;

      pGenerated  := 1;
    else
      pGenerated  := 0;
    end if;
  end SelectPenalties;

/*-----------------------------------------------------------------------------------*/
  procedure GenAwaitingPenalties(pEvaluationId in SQM_EVALUATION.SQM_EVALUATION_ID%type)
  is
    cursor crDetail
    is
      select PDE.DOC_POSITION_DETAIL_ID
           , POS.DOC_POSITION_ID
           , decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ), 'VAL', DOC.DMT_DATE_VALUE, DOC.DMT_DATE_DOCUMENT) DATE_REFERENCE
           , DOC.PAC_THIRD_ID
           , POS.GCO_GOOD_ID
           , DOC.DOC_GAUGE_ID
           , POS.DOC_GAUGE_POSITION_ID
           , EVA.EVA_ENDING_DATE
        from DOC_DOCUMENT DOC
           , DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
           , SQM_EVALUATION EVA
       where DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and PDE.PDE_SQM_ACCEPTED_DELAY between EVA.EVA_STARTING_DATE and EVA.EVA_ENDING_DATE
         and EVA.SQM_EVALUATION_ID = pEvaluationId
         and not exists(select PDE_DISCHARGED.DOC_POSITION_DETAIL_ID
                          from DOC_POSITION_DETAIL PDE_DISCHARGED
                         where PDE_DISCHARGED.DOC_DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID);

    tplDetail  crDetail%rowtype;
    vExpValue  SQM_PENALTY.SPE_EXPECTED_VALUE%type;
    vEffValue  SQM_PENALTY.SPE_EFFECTIVE_VALUE%type;
    vAxisValue SQM_PENALTY.SPE_INIT_VALUE%type;
  begin
    -- Recherche des détails de position non déchargé dont le délai qualité est inscrit dans la période de l'évaluation
    open crDetail;

    fetch crDetail
     into tplDetail;

    while crDetail%found loop
      -- Pour chaque détail, rechercher les axes qualité applicables
      for cr_axis in (select SAX.SQM_AXIS_ID
                           , SQM_FUNCTIONS.GetFirstFitScale(SAX.SQM_AXIS_ID, tplDetail.DATE_REFERENCE, tplDetail.GCO_GOOD_ID) SCALE_ID
                        from DOC_GAUGE_RECEIPT_S_AXIS GRA
                           , DOC_GAUGE_RECEIPT GAR
                           , SQM_AXIS SAX
                           , DOC_GAUGE_POSITION GAP
                       where GAP.DOC_GAUGE_POSITION_ID = tplDetail.DOC_GAUGE_POSITION_ID
                         and GAR.DOC_DOC_GAUGE_ID = tplDetail.DOC_GAUGE_ID
                         and GAR.DOC_GAUGE_RECEIPT_ID = GRA.DOC_GAUGE_RECEIPT_ID
                         and GAP.C_SQM_EVAL_TYPE = '1'   -- Gabarit position gère la qualité
                         and SAX.SQM_AXIS_ID = GRA.SQM_AXIS_ID   -- Axe défini au niveau d'un flux potentiel
                         and SAX.C_AXIS_STATUS = 'ACT'   -- Axe actif
                         and GRA.GRA_ESTIMATE_CALCULATION = 1   -- Axe gérant les pénalités en attente
                         and SQM_FUNCTIONS.IsVerified(SAX.PC_SQLST_ID, tplDetail.GCO_GOOD_ID) = 1)   -- Condition d'application de l'axe vérifiée
                                                                                                  loop
        if cr_axis.SCALE_ID is not null then
          vExpValue                                      := null;
          vEffValue                                      := null;
          vAxisValue                                     := null;
          -- Initialisation des valeurs effectives (estimées)
          Sqm_Init_Method.dtDateDoc                      := least(tplDetail.EVA_ENDING_DATE, trunc(sysdate) );   -- pour les axes de type délai
          Sqm_Init_Method.DetailInfo.PDE_FINAL_QUANTITY  := 0;   -- pour les axes de type quantité
          -- Sqm_Init_Method.PosNetUnitValue                := 0; -- pour les axes de type prix
          Sqm_Init_Method.CalcAxisValue(cr_axis.SQM_AXIS_ID, vExpValue, vEffValue, vAxisValue, tplDetail.DOC_POSITION_dETAIL_ID);

          if vAxisValue is not null then
            insert into SQM_PENALTY
                        (SQM_PENALTY_ID
                       , SQM_SCALE_ID
                       , DOC_POSITION_DETAIL_ID
                       , DOC_POSITION_ID
                       , PAC_THIRD_ID
                       , GCO_GOOD_ID
                       , SQM_AXIS_ID
                       , C_PENALTY_STATUS
                       , SPE_DATE_REFERENCE
                       , SPE_CALC_PENALTY
                       , SPE_INIT_VALUE
                       , SPE_EXPECTED_VALUE
                       , SPE_EFFECTIVE_VALUE
                       , SQM_EVALUATION_ID
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , cr_axis.SCALE_ID
                       , tplDetail.DOC_POSITION_DETAIL_ID
                       , tplDetail.DOC_POSITION_ID
                       , tplDetail.PAC_THIRD_ID
                       , tplDetail.GCO_GOOD_ID
                       , cr_axis.SQM_AXIS_ID
                       , 'CONF'
                       , least(tplDetail.EVA_ENDING_DATE, trunc(sysdate) )
                       , SQM_FUNCTIONS.CalcPenalty(cr_axis.SCALE_ID, vAxisValue)
                       , vAxisValue
                       , vExpValue
                       , vEffValue
                       , pEvaluationId
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          end if;
        end if;
      end loop;

      fetch crDetail
       into tplDetail;
    end loop;

    close crDetail;
  end GenAwaitingPenalties;

/*-----------------------------------------------------------------------------------*/
  procedure RemovePenalties(pEvaluationId in SQM_EVALUATION.SQM_EVALUATION_ID%type)
  is
    vStatus varchar2(10);
  begin
    select C_SQM_EVALUATION_STATUS
      into vStatus
      from SQM_EVALUATION
     where SQM_EVALUATION_ID = pEvaluationId;

    -- la suppression de la sélection est impossible pour les évaluations Définitives
    if vStatus <> 'DEF' then
      -- mise à jour du statut des criticités liées à l'évaluation
      -- et absentes d'autres évaluations avec le statut calculé ou définitif
      update SQM_PENALTY
         set C_PENALTY_STATUS = 'CONF'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SQM_PENALTY_ID in(select SQM_PENALTY_ID
                                 from SQM_EVAL_S_PENALTY
                                where SQM_EVALUATION_ID = pEvaluationId)
         and SQM_PENALTY_ID not in(select ESP.SQM_PENALTY_ID
                                     from SQM_EVAL_S_PENALTY ESP
                                        , SQM_EVALUATION EVA
                                    where EVA.SQM_EVALUATION_ID = ESP.SQM_EVALUATION_ID
                                      and EVA.C_SQM_EVALUATION_STATUS in('CAL', 'DEF') );

      -- suppression de la sélection
      delete from SQM_EVAL_S_PENALTY
            where SQM_EVALUATION_ID = pEvaluationId;

      -- suppression des pénalités estimées
      delete from SQM_PENALTY
            where sqm_evaluation_id = pEvaluationId;

      -- mise à jour du statut de l'évaluation --> en cours
      update SQM_EVALUATION
         set C_SQM_EVALUATION_STATUS = 'PRE'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SQM_EVALUATION_ID = pEvaluationId;
    end if;
  end RemovePenalties;

/*-----------------------------------------------------------------------------------*/
  procedure CalculateResults(pEvaluationId in SQM_EVALUATION.SQM_EVALUATION_ID%type)
  is
    vCategId SQM_EVALUATION.SQM_EVALUATION_CATEGORY_ID%type;

    -- curseur sur les sous-macro de calcul de la catégorie
    cursor crCalcMethod(aCategId SQM_EVALUATION.SQM_EVALUATION_CATEGORY_ID%type)
    is
      select   EMS.SQM_SQM_EVALUATION_METHOD_ID
             , EMS.EMS_LEVEL
          from SQM_EVAL_METHOD_STRUCTURE EMS
             , SQM_EVALUATION_CATEGORY ECA
         where ECA.SQM_EVALUATION_METHOD_ID = EMS.SQM_EVALUATION_METHOD_ID
           and ECA.SQM_EVALUATION_CATEGORY_ID = aCategId
      order by EMS_LEVEL desc;
  begin
    -- confirmation de la sélection
    update SQM_PENALTY
       set C_PENALTY_STATUS = 'DEF'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where SQM_PENALTY_ID in(select SQM_PENALTY_ID
                               from SQM_EVAL_S_PENALTY
                              where SQM_EVALUATION_ID = pEvaluationId);

    -- Recherche de la catégorie de l'évaluation
    select ECA.SQM_EVALUATION_CATEGORY_ID
      into vCategId
      from SQM_EVALUATION EVA
         , SQM_EVALUATION_CATEGORY ECA
     where ECA.SQM_EVALUATION_CATEGORY_ID = EVA.SQM_EVALUATION_CATEGORY_ID
       and EVA.SQM_EVALUATION_ID = pEvaluationId;

    -- Calcul des résultats intermédiaires
    for CalcMacro in crCalcMethod(vCategId) loop
      GenerateMethodResult(CalcMacro.SQM_SQM_EVALUATION_METHOD_ID, vCategId, pEvaluationId, CalcMacro.EMS_LEVEL);
    end loop;

    -- mise à jour du statut de l'évaluation
    update SQM_EVALUATION
       set C_SQM_EVALUATION_STATUS = 'CAL'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where SQM_EVALUATION_ID = pEvaluationId;

    -- Mise à jour du code de classification pour la note finale
    for res in (select SQM_RESULT_ID
                     , RES_FINAL_NOTE
                  from SQM_RESULT RES
                     , SQM_EVALUATION EVA
                     , SQM_EVALUATION_CATEGORY ECA
                 where RES.SQM_EVALUATION_ID = EVA.SQM_EVALUATION_ID
                   and ECA.SQM_EVALUATION_CATEGORY_ID = EVA.SQM_EVALUATION_CATEGORY_ID
                   and RES.SQM_EVALUATION_ID = pEvaluationId
                   and RES.SQM_EVALUATION_METHOD_ID = ECA.SQM_EVALUATION_METHOD_ID) loop
      update SQM_RESULT
         set RES_FINAL_EVALUATION = SQM_FUNCTIONS.CalcEvalABC(pEvaluationId, res.RES_FINAL_NOTE)
       where SQM_RESULT_ID = res.SQM_RESULT_ID;
    end loop;
  end CalculateResults;

/*-----------------------------------------------------------------------------------*/
  procedure GenerateMethodResult(
    pMethodId in SQM_EVALUATION_METHOD.SQM_EVALUATION_METHOD_ID%type
  , pCategId  in SQM_EVALUATION_CATEGORY.SQM_EVALUATION_CATEGORY_ID%type
  , pEvalId   in SQM_EVALUATION.SQM_EVALUATION_ID%type
  , pLevel    in SQM_EVAL_METHOD_STRUCTURE.EMS_LEVEL%type
  )
  is
    vMacro       SQM_EVALUATION_METHOD.EME_MACRO%type;
    vScript      SQM_EVALUATION_METHOD.EME_SCRIPT%type;
    vGroupLevel  SQM_EVALUATION_CATEGORY.ECA_GROUP_LEVEL%type;
    vFinalScript varchar2(32767);
  begin
    select EME.EME_SCRIPT
         , EME.EME_MACRO
      into vScript
         , vMacro
      from SQM_EVALUATION_METHOD EME
     where SQM_EVALUATION_METHOD_ID = pMethodId;

    select ECA_GROUP_LEVEL
      into vGroupLevel
      from SQM_EVALUATION_CATEGORY
     where SQM_EVALUATION_CATEGORY_ID = pCategId;

    -- Méthode de calcul de plus bas niveau (script SQL)
    if vMacro is null then
      -- Formatage du script de la méthode
      vFinalScript  := FormatScript(pMethodId, vScript, pEvalId, vGroupLevel, pLevel);
    else
      vFinalScript  := FormatMacro(pMethodId, vMacro, pEvalId, vGroupLevel, pLevel);
    end if;

    vFinalScript  :=
      'insert into SQM_RESULT(SQM_RESULT_ID' ||
      ', SQM_EVALUATION_ID' ||
      ', PAC_THIRD_ID' ||
      ', GCO_GOOD_ID' ||
      ', RES_FINAL_NOTE' ||
      ', RES_LEVEL' ||
      ', SQM_EVALUATION_METHOD_ID' ||
      ', GCO_GOOD_CATEGORY_ID' ||
      ', DIC_GOOD_FAMILY_ID' ||
      ', DIC_GOOD_LINE_ID' ||
      ', DIC_GOOD_GROUP_ID' ||
      ', DIC_GOOD_MODEL_ID' ||
      ', DIC_ACCOUNTABLE_GROUP_ID' ||
      ', GCO_PRODUCT_GROUP_ID' ||
      ', DIC_GCO_STATISTIC_1_ID' ||
      ', DIC_GCO_STATISTIC_2_ID' ||
      ', DIC_GCO_STATISTIC_3_ID' ||
      ', DIC_GCO_STATISTIC_4_ID' ||
      ', DIC_GCO_STATISTIC_5_ID' ||
      ', DIC_GCO_STATISTIC_6_ID' ||
      ', DIC_GCO_STATISTIC_7_ID' ||
      ', DIC_GCO_STATISTIC_8_ID' ||
      ', DIC_GCO_STATISTIC_9_ID' ||
      ', DIC_GCO_STATISTIC_10_ID' ||
      ', A_DATECRE' ||
      ', A_IDCRE) ' ||
      vFinalScript;

    -- Calcul du résultat et insertion dans la table SQM_RESULT
    execute immediate vFinalScript;
  end GenerateMethodResult;

/*-----------------------------------------------------------------------------------*/
  function FormatScript(
    pMethodId   in SQM_EVALUATION_METHOD.SQM_EVALUATION_METHOD_ID%type
  , pScript     in SQM_EVALUATION_METHOD.EME_SCRIPT%type
  , pEvalId     in SQM_EVALUATION.SQM_EVALUATION_ID%type
  , pGroupLevel in SQM_EVALUATION_CATEGORY.ECA_GROUP_LEVEL%type
  , pLevel      in SQM_EVAL_METHOD_STRUCTURE.EMS_LEVEL%type
  )
    return varchar2
  is
    vScriptBuffer varchar2(32767);
    vLength       integer;
    strSelect     varchar2(32767);
    strFromWhere  varchar2(32767);
    strGroupBy    varchar2(32767);
    strFinalNote  varchar2(32767);
  begin
    vLength        := DBMS_LOB.GetLength(pScript);

    if vLength > 32767 then
      Raise_application_error(-20001, 'PCS - script length out of range !');
    end if;

    DBMS_LOB.read(pScript, vLength, 1, vScriptBuffer);
    -- mise en forme du script de création
    vScriptBuffer  := ltrim(vScriptBuffer);
    strFinalNote   := ltrim(vScriptBuffer, 'SELECTselect');
    strFinalNote   := substr(strFinalNote, 1, regexp_instr(strFinalNote, 'FROM', 1, 1, 1, 'i') - 5);
    strFinalNote   := ltrim(strFinalNote);
    vScriptBuffer  := regexp_replace(vScriptBuffer, ':SQM_EVALUATION_ID', pEvalId, 1, 0, 'i');
    -- Utilise les expressions régulière pour effectuer le remplacement de la macro du propriétaire des tables
    vScriptBuffer  := regexp_replace(vScriptBuffer, '\[(CO|COMPANY_OWNER)\]', PCS.PC_I_LIB_SESSION.GETCOMPANYOWNER, 1, 0, 'i');
    strGroupBy     := pGroupLevel;
    /*clause SELECT*/
    strSelect      := 'select ';
    -- champ SQM_RESULT_ID traité plus bas
    -- champ SQM_EVALUATION_ID
    strSelect      := strSelect || pEvalId || ' SQM_EVALUATION_ID';
    -- champ PAC_THIRD_ID
    strSelect      := strSelect || ',SPE.PAC_THIRD_ID' || ' PAC_THIRD_ID';
    strGroupBy     := regexp_replace(strGroupBy, 'PAC_THIRD_ID', 'SPE.PAC_THIRD_ID', 1, 0, 'i');

    -- champ GCO_GOOD_ID
    if instr(pGroupLevel, 'GCO_GOOD_ID') <> 0 then
      strSelect   := strSelect || ',GOO.GCO_GOOD_ID';
      strGroupBy  := regexp_replace(strGroupBy, 'GCO_GOOD_ID', 'GOO.GCO_GOOD_ID', 1, 0, 'i');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' GCO_GOOD_ID';
    -- champ RES_FINAL_NOTE
    strSelect      := strSelect || ',' || strFinalNote || ' RES_FINAL_NOTE';
    -- champ RES_LEVEL
    strSelect      := strSelect || ',' || pLevel || ' RES_LEVEL';
    -- champ SQM_EVALUATION_METHOD_ID
    strSelect      := strSelect || ',' || pMethodId || ' SQM_EVALUATION_METHOD_ID';

    -- champ GCO_GOOD_CATEGORY_ID
    if instr(pGroupLevel, 'GCO_GOOD_CATEGORY_ID') <> 0 then
      strSelect   := strSelect || ',GOO.GCO_GOOD_CATEGORY_ID';
      strGroupBy  := regexp_replace(strGroupBy, 'GCO_GOOD_CATEGORY_ID', 'GOO.GCO_GOOD_CATEGORY_ID', 1, 0, 'i');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' GCO_GOOD_CATEGORY_ID';

    -- champ DIC_GOOD_FAMILY_ID
    if instr(pGroupLevel, 'DIC_GOOD_FAMILY_ID') <> 0 then
      strSelect   := strSelect || ',GOO.DIC_GOOD_FAMILY_ID';
      strGroupBy  := regexp_replace(strGroupBy, 'DIC_GOOD_FAMILY_ID', 'GOO.DIC_GOOD_FAMILY_ID', 1, 0, 'i');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' DIC_GOOD_FAMILY_ID';

    -- champ DIC_GOOD_LINE_ID
    if instr(pGroupLevel, 'DIC_GOOD_LINE_ID') <> 0 then
      strSelect   := strSelect || ',GOO.DIC_GOOD_LINE_ID';
      strGroupBy  := regexp_replace(strGroupBy, 'DIC_GOOD_LINE_ID', 'GOO.DIC_GOOD_LINE_ID', 1, 0, 'i');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' DIC_GOOD_LINE_ID';

    -- champ DIC_GOOD_GROUP_ID
    if instr(pGroupLevel, 'DIC_GOOD_GROUP_ID') <> 0 then
      strSelect   := strSelect || ',GOO.DIC_GOOD_GROUP_ID';
      strGroupBy  := regexp_replace(strGroupBy, 'DIC_GOOD_GROUP_ID', 'GOO.DIC_GOOD_GROUP_ID', 1, 0, 'i');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' DIC_GOOD_GROUP_ID';

    -- champ DIC_GOOD_MODEL_ID
    if instr(pGroupLevel, 'DIC_GOOD_MODEL_ID') <> 0 then
      strSelect   := strSelect || ',GOO.DIC_GOOD_MODEL_ID';
      strGroupBy  := regexp_replace(strGroupBy, 'DIC_GOOD_MODEL_ID', 'GOO.DIC_GOOD_MODEL_ID', 1, 0, 'i');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' DIC_GOOD_MODEL_ID';

    -- champ DIC_ACCOUNTABLE_GROUP_ID
    if instr(pGroupLevel, 'DIC_ACCOUNTABLE_GROUP_ID') <> 0 then
      strSelect   := strSelect || ',GOO.DIC_ACCOUNTABLE_GROUP_ID';
      strGroupBy  := regexp_replace(strGroupBy, 'DIC_ACCOUNTABLE_GROUP_ID', 'GOO.DIC_ACCOUNTABLE_GROUP_ID', 1, 0, 'i');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' DIC_ACCOUNTABLE_GROUP_ID';

    -- champ GCO_PRODUCT_GROUP_ID
    if instr(pGroupLevel, 'GCO_PRODUCT_GROUP_ID') <> 0 then
      strSelect   := strSelect || ',GOO.GCO_PRODUCT_GROUP_ID';
      strGroupBy  := regexp_replace(strGroupBy, 'GCO_PRODUCT_GROUP_ID', 'GOO.GCO_PRODUCT_GROUP_ID', 1, 0, 'i');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' GCO_PRODUCT_GROUP_ID';

    -- champ DIC_GCO_STATISTIC_X_ID (X=1..10)
    for i in 1 .. 10 loop
      if instr(pGroupLevel, 'DIC_GCO_STATISTIC_' || to_char(i) || '_ID') <> 0 then
        strSelect   := strSelect || ',GOO.DIC_GCO_STATISTIC_' || to_char(i) || '_ID';
        strGroupBy  := regexp_replace(strGroupBy, 'DIC_GCO_STATISTIC_' || to_char(i) || '_ID', 'GOO.DIC_GCO_STATISTIC_' || to_char(i) || '_ID', 1, 0, 'i');
      else
        strSelect  := strSelect || ',null';
      end if;

      strSelect  := strSelect || ' DIC_GCO_STATISTIC_' || to_char(i) || '_ID';
    end loop;

    -- champ A_DATECRE
    strSelect      := strSelect || ',sysdate A_DATECRE';
    -- champ A_IDCRE
    strSelect      := strSelect || ',pcs.PC_I_LIB_SESSION.getuserini A_IDCRE';
    /*clause FROM et WHERE*/
    strFromWhere   := substr(vScriptBuffer, regexp_instr(vScriptBuffer, 'FROM', 1, 1, 1, 'i') - 4, length(vScriptBuffer) );
    /*clause GROUP BY*/
    strGroupBy     := 'GROUP BY ' || rtrim(strGroupBy, ',');
    vScriptBuffer  := 'select init_id_seq.nextval,tab.* from (' || strSelect || ' ' || strFromWhere || ' ' || strGroupBy || ') tab';
    return vScriptBuffer;
  end FormatScript;

/*-----------------------------------------------------------------------------------*/
  function FormatMacro(
    pMethodId   in SQM_EVALUATION_METHOD.SQM_EVALUATION_METHOD_ID%type
  , pMacro      in SQM_EVALUATION_METHOD.EME_MACRO%type
  , pEvalId     in SQM_EVALUATION.SQM_EVALUATION_ID%type
  , pGroupLevel in SQM_EVALUATION_CATEGORY.ECA_GROUP_LEVEL%type
  , pLevel      in SQM_EVAL_METHOD_STRUCTURE.EMS_LEVEL%type
  )
    return varchar2
  is
    vScriptBuffer varchar2(32767);
    vsubMethodId  SQM_EVALUATION_METHOD.SQM_EVALUATION_METHOD_ID%type;
    vSubMacro     SQM_EVALUATION_METHOD.EME_MACRO%type;
    strSubLevel   varchar2(30);
    strLevel      SQM_EVALUATION_CATEGORY.ECA_GROUP_LEVEL%type;
    strSelect     varchar2(32767);
    strFromWhere  varchar2(32767);
    strGroupBy    varchar2(32767);
    strFinalNote  varchar2(5000);
    vSQL          varchar2(5000);
    intIndex      number;
  begin
    strFinalNote   := pMacro;
    -- parse de la macro pour retrouver les résultats qu'elle utilise
    vSubMethodId   := 0;
    intIndex       := 0;

    while vSubMethodId is not null loop
      intIndex  := intIndex + 1;

      begin
        select SQM_EVALUATION_METHOD_ID
          into vSubMethodId
          from SQM_EVALUATION_METHOD
         where EME_CODE = SQM_GENERATE_METHOD_STRUCTURE.GetSubMacro(pMacro, intIndex);
      exception
        when no_data_found then
          vSubMethodId  := null;
      end;

      -- récupération des résultats de chaque sous-macro
      if vSubMethodId is not null then
        vSQL          :=
          'select NVL(RES_FINAL_NOTE, 0)' || '  from SQM_RESULT' || ' where SQM_EVALUATION_METHOD_ID = ' || vSubMethodId || '   and SQM_EVALUATION_ID = '
          || pEvalId;
        -- niveau de regroupement
        strLevel      := pGroupLevel;

        -- ajout de la jointure associée à chaque niveau de regroupement
        while rtrim(strLevel, ',') is not null loop
          strSubLevel  := substr(strLevel, 0, instr(strLevel, ',') - 1);
          vSQL         := vSQL || '   and ' || strSubLevel || ' = MAIN.' || strSubLevel;
          strLevel     := replace(strLevel, strSubLevel, '');
          strLevel     := ltrim(strLevel, ',');
        end loop;

        -- construction du champ RES_FINAL_NOTE
        strFinalNote  := replace(strFinalNote, '[' || SQM_GENERATE_METHOD_STRUCTURE.GetSubMacro(pMacro, intIndex) || ']', '(' || vSQL || ')');
      end if;
    end loop;

    -- Construction du script final
    strGroupBy     := pGroupLevel;
    /*clause SELECT*/
    strSelect      := 'select ';
    -- champ SQM_RESULT_ID traité plus bas
    -- champ SQM_EVALUATION_ID
    strSelect      := strSelect || pEvalId || ' SQM_EVALUATION_ID';
    -- champ PAC_THIRD_ID
    strSelect      := strSelect || ',MAIN.PAC_THIRD_ID' || ' PAC_THIRD_ID';
    strGroupBy     := replace(strGroupBy, 'PAC_THIRD_ID', 'MAIN.PAC_THIRD_ID');

    -- champ GCO_GOOD_ID
    if instr(pGroupLevel, 'GCO_GOOD_ID') <> 0 then
      strSelect   := strSelect || ',MAIN.GCO_GOOD_ID';
      strGroupBy  := replace(strGroupBy, 'GCO_GOOD_ID', 'MAIN.GCO_GOOD_ID');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' GCO_GOOD_ID';
    -- champ RES_FINAL_NOTE
    strSelect      := strSelect || ',' || strFinalNote || ' RES_FINAL_NOTE';
    -- champ RES_LEVEL
    strSelect      := strSelect || ',' || pLevel || ' RES_LEVEL';
    -- champ SQM_EVALUATION_METHOD_ID
    strSelect      := strSelect || ',' || pMethodId || ' SQM_EVALUATION_METHOD_ID';

    -- champ GCO_GOOD_CATEGORY_ID
    if instr(pGroupLevel, 'GCO_GOOD_CATEGORY_ID') <> 0 then
      strSelect   := strSelect || ',MAIN.GCO_GOOD_CATEGORY_ID';
      strGroupBy  := replace(strGroupBy, 'GCO_GOOD_CATEGORY_ID', 'MAIN.GCO_GOOD_CATEGORY_ID');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' GCO_GOOD_CATEGORY_ID';

    -- champ DIC_GOOD_FAMILY_ID
    if instr(pGroupLevel, 'DIC_GOOD_FAMILY_ID') <> 0 then
      strSelect   := strSelect || ',MAIN.DIC_GOOD_FAMILY_ID';
      strGroupBy  := replace(strGroupBy, 'DIC_GOOD_FAMILY_ID', 'MAIN.DIC_GOOD_FAMILY_ID');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' DIC_GOOD_FAMILY_ID';

    -- champ DIC_GOOD_LINE_ID
    if instr(pGroupLevel, 'DIC_GOOD_LINE_ID') <> 0 then
      strSelect   := strSelect || ',MAIN.DIC_GOOD_LINE_ID';
      strGroupBy  := replace(strGroupBy, 'DIC_GOOD_LINE_ID', 'MAIN.DIC_GOOD_LINE_ID');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' DIC_GOOD_LINE_ID';

    -- champ DIC_GOOD_GROUP_ID
    if instr(pGroupLevel, 'DIC_GOOD_GROUP_ID') <> 0 then
      strSelect   := strSelect || ',MAIN.DIC_GOOD_GROUP_ID';
      strGroupBy  := replace(strGroupBy, 'DIC_GOOD_GROUP_ID', 'MAIN.DIC_GOOD_GROUP_ID');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' DIC_GOOD_GROUP_ID';

    -- champ DIC_GOOD_MODEL_ID
    if instr(pGroupLevel, 'DIC_GOOD_MODEL_ID') <> 0 then
      strSelect   := strSelect || ',MAIN.DIC_GOOD_MODEL_ID';
      strGroupBy  := replace(strGroupBy, 'DIC_GOOD_MODEL_ID', 'MAIN.DIC_GOOD_MODEL_ID');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' DIC_GOOD_MODEL_ID';

    -- champ DIC_ACCOUNTABLE_GROUP_ID
    if instr(pGroupLevel, 'DIC_ACCOUNTABLE_GROUP_ID') <> 0 then
      strSelect   := strSelect || ',MAIN.DIC_ACCOUNTABLE_GROUP_ID';
      strGroupBy  := replace(strGroupBy, 'DIC_ACCOUNTABLE_GROUP_ID', 'MAIN.DIC_ACCOUNTABLE_GROUP_ID');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' DIC_ACCOUNTABLE_GROUP_ID';

    -- champ GCO_PRODUCT_GROUP_ID
    if instr(pGroupLevel, 'GCO_PRODUCT_GROUP_ID') <> 0 then
      strSelect   := strSelect || ',MAIN.GCO_PRODUCT_GROUP_ID';
      strGroupBy  := replace(strGroupBy, 'GCO_PRODUCT_GROUP_ID', 'MAIN.GCO_PRODUCT_GROUP_ID');
    else
      strSelect  := strSelect || ',null';
    end if;

    strSelect      := strSelect || ' GCO_PRODUCT_GROUP_ID';

    -- champ DIC_GCO_STATISTIC_X_ID (X=1..10)
    for i in 1 .. 10 loop
      if instr(pGroupLevel, 'DIC_GCO_STATISTIC_' || to_char(i) || '_ID') <> 0 then
        strSelect   := strSelect || ',MAIN.DIC_GCO_STATISTIC_' || to_char(i) || '_ID';
        strGroupBy  := replace(strGroupBy, 'DIC_GCO_STATISTIC_' || to_char(i) || '_ID', 'MAIN.DIC_GCO_STATISTIC_' || to_char(i) || '_ID');
      else
        strSelect  := strSelect || ',null';
      end if;

      strSelect  := strSelect || ' DIC_GCO_STATISTIC_' || to_char(i) || '_ID';
    end loop;

    -- champ A_DATECRE
    strSelect      := strSelect || ',sysdate A_DATECRE';
    -- champ A_IDCRE
    strSelect      := strSelect || ',pcs.PC_I_LIB_SESSION.getuserini A_IDCRE';
    /*clause FROM et WHERE*/
    strFromWhere   := 'from SQM_RESULT MAIN where MAIN.SQM_EVALUATION_ID = ' || pEvalId || ' and ' || strFinalNote || ' is not null';
    /*clause GROUP BY*/
    strGroupBy     := 'GROUP BY ' || rtrim(strGroupBy, ',');
    vScriptBuffer  := 'select init_id_seq.nextval,tab.* from (' || strSelect || ' ' || strFromWhere || ' ' || strGroupBy || ') tab';
    return vScriptBuffer;
  end FormatMacro;

/*-----------------------------------------------------------------------------------*/
  procedure CancelResults(pEvaluationId in SQM_EVALUATION.SQM_EVALUATION_ID%type)
  is
    cStatus SQM_EVALUATION.C_SQM_EVALUATION_STATUS%type;
  begin
    select C_SQM_EVALUATION_STATUS
      into cStatus
      from SQM_EVALUATION
     where SQM_EVALUATION_ID = pEvaluationId;

    -- Contrôle statut de l'évaluation
    if cStatus = 'CAL' then
      -- Suppression des enregistrements
      delete from SQM_RESULT
            where SQM_EVALUATION_ID = pEvaluationId;

      -- mise à jour du statut de l'évaluation : Calculée --> En cours
      update SQM_EVALUATION
         set C_SQM_EVALUATION_STATUS = 'ENC'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SQM_EVALUATION_ID = pEvaluationId;

      -- mise à jour du statut des criticités liées à l'évaluation
      -- et absentes d'autres évaluations avec le statut calculé ou définitif
      update SQM_PENALTY
         set C_PENALTY_STATUS = 'CONF'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SQM_PENALTY_ID in(select SQM_PENALTY_ID
                                 from SQM_EVAL_S_PENALTY
                                where SQM_EVALUATION_ID = pEvaluationId)
         and SQM_PENALTY_ID not in(select ESP.SQM_PENALTY_ID
                                     from SQM_EVAL_S_PENALTY ESP
                                        , SQM_EVALUATION EVA
                                    where EVA.SQM_EVALUATION_ID = ESP.SQM_EVALUATION_ID
                                      and EVA.C_SQM_EVALUATION_STATUS in('CAL', 'DEF') );
    end if;
  end CancelResults;

/*-----------------------------------------------------------------------------------*/
  procedure ValidateResults(pEvaluationId in SQM_EVALUATION.SQM_EVALUATION_ID%type)
  is
  begin
    -- mise à jour du statut de l'évaluation --> définitif
    update SQM_EVALUATION
       set C_SQM_EVALUATION_STATUS = 'DEF'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where SQM_EVALUATION_ID = pEvaluationId;
  end ValidateResults;

/*-----------------------------------------------------------------------------------*/
  procedure RegeneratePenalties(aAxisList in varchar2, aBegDate in date, aEndDate in date, aModified in number)
  is
    cursor crDetail
    is
      select   case
                 when upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ) = 'VAL' then DOC.DMT_DATE_VALUE
                 else DOC.DMT_DATE_DOCUMENT
               end DMT_DATE_DOCUMENT
             , POS.PAC_THIRD_ID
             , POS.GCO_GOOD_ID
             , POS.C_DOC_POS_STATUS
             , SQM_FUNCTIONS.GetFirstFitScale(SAX.SQM_AXIS_ID
                                            , case
                                                when upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ) = 'VAL' then DOC.DMT_DATE_VALUE
                                                else DOC.DMT_DATE_DOCUMENT
                                              end
                                            , POS.GCO_GOOD_ID
                                             ) SCALE_ID
             , SAX.SQM_AXIS_ID
             , PDE.DOC_POSITION_DETAIL_ID
             , POS.DOC_POSITION_ID
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DOC
             , SQM_AXIS SAX
             , DOC_GAUGE_RECEIPT_S_AXIS GRA
             , DOC_GAUGE_POSITION GAP
         where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
           and GRA.SQM_AXIS_ID = SAX.SQM_AXIS_ID
           and GRA.DOC_GAUGE_RECEIPT_ID = PDE.DOC_GAUGE_RECEIPT_ID
           and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
           and GAP.C_SQM_EVAL_TYPE = '1'   -- Gabarit position gère la qualité
           and SAX.C_AXIS_STATUS = 'ACT'   -- Axe actif
           and (   case
                     when upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ) = 'VAL' then DOC.DMT_DATE_VALUE
                     else DOC.DMT_DATE_DOCUMENT
                   end >= aBegDate
                or aBegDate is null
               )
           and (   case
                     when upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ) = 'VAL' then DOC.DMT_DATE_VALUE
                     else DOC.DMT_DATE_DOCUMENT
                   end <= aEndDate
                or aEndDate is null
               )
           and instr(aAxisList, ',' || to_char(SAX.SQM_AXIS_ID) ) > 0
      order by DMT_DATE_DOCUMENT;

    tplDetail  crDetail%rowtype;
    vExpValue  SQM_PENALTY.SPE_EXPECTED_VALUE%type;
    vEffValue  SQM_PENALTY.SPE_EFFECTIVE_VALUE%type;
    vAxisValue SQM_PENALTY.SPE_INIT_VALUE%type;
    tplPenalty SQM_PENALTY%rowtype;
    tplPenNull SQM_PENALTY%rowtype;
  begin
    if (aModified = 0) then
      -- suppression de toutes les notes (sauf manuelles)
      delete from SQM_PENALTY
            where SPE_DATE_REFERENCE >= nvl(aBegDate, SPE_DATE_REFERENCE)
              and SPE_DATE_REFERENCE <= nvl(aEndDate, SPE_DATE_REFERENCE)
              and instr(aAxisList, ',' || to_char(SQM_AXIS_ID) ) > 0
              and SPE_MANUAL_PENALTY = 0;
    else
      -- suppression des notes non modifiées (les notes modifiées seront traitées séparément)
      delete from SQM_PENALTY
            where SPE_DATE_REFERENCE >= nvl(aBegDate, SPE_DATE_REFERENCE)
              and SPE_DATE_REFERENCE <= nvl(aEndDate, SPE_DATE_REFERENCE)
              and SPE_MODIFIED_PENALTY is null
              and instr(aAxisList, ',' || to_char(SQM_AXIS_ID) ) > 0
              and SPE_MANUAL_PENALTY = 0;
    end if;

    -- pour tous les détails de position de la période, on génère les notes selon paramètres
    open crDetail;

    fetch crDetail
     into tplDetail;

    while crDetail%found loop
      -- Initialisation du record DetailInfo du package SQM_INIT_METHOD
      select *
        into SQM_INIT_METHOD.DetailInfo
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = tplDetail.DOC_POSITION_DETAIL_ID;

      if tplDetail.SCALE_ID is not null then
        vExpValue   := null;
        vEffValue   := null;
        vAxisValue  := null;
        SQM_INIT_METHOD.CalcAxisValue(tplDetail.SQM_AXIS_ID, vExpValue, vEffValue, vAxisValue);

        begin
          select *
            into tplPenalty
            from SQM_PENALTY
           where SQM_AXIS_ID = tplDetail.SQM_AXIS_ID
             and DOC_POSITION_DETAIL_ID = tplDetail.DOC_POSITION_DETAIL_ID;
        exception
          when no_data_found then
            tplPenalty  := tplPenNull;
        end;

        insert into SQM_PENALTY
                    (SQM_PENALTY_ID
                   , SQM_SCALE_ID
                   , DOC_POSITION_DETAIL_ID
                   , DOC_POSITION_ID
                   , PAC_THIRD_ID
                   , GCO_GOOD_ID
                   , SQM_AXIS_ID
                   , C_PENALTY_STATUS
                   , SPE_DATE_REFERENCE
                   , SPE_CALC_PENALTY
                   , SPE_MODIFIED_PENALTY
                   , DIC_SQM_MODIF_TYPE_ID
                   , SPE_MODIF_COMMENT
                   , SPE_INIT_VALUE
                   , SPE_UPDATED_VALUE
                   , SPE_EXPECTED_VALUE
                   , SPE_EFFECTIVE_VALUE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (init_id_seq.nextval
                   , tplDetail.SCALE_ID
                   , tplDetail.DOC_POSITION_DETAIL_ID
                   , tplDetail.DOC_POSITION_ID
                   , tplDetail.PAC_THIRD_ID
                   , tplDetail.GCO_GOOD_ID
                   , tplDetail.SQM_AXIS_ID
                   , decode(tplDetail.C_DOC_POS_STATUS, '01', 'PROV', 'CONF')
                   , tplDetail.DMT_DATE_DOCUMENT
                   , SQM_FUNCTIONS.CalcPenalty(tplDetail.SCALE_ID, vAxisValue)
                   , case
                       when(aModified = 1) then tplPenalty.SPE_MODIFIED_PENALTY
                       else null
                     end
                   , case
                       when(aModified = 1) then tplPenalty.DIC_SQM_MODIF_TYPE_ID
                       else null
                     end
                   , case
                       when(aModified = 1) then tplPenalty.SPE_MODIF_COMMENT
                       else null
                     end
                   , vAxisValue
                   , case
                       when(aModified = 1) then tplPenalty.SPE_UPDATED_VALUE
                       else null
                     end
                   , vExpValue
                   , vEffValue
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        if    (aModified = 1)
           or (tplPenalty.SPE_MANUAL_PENALTY = 1) then
          -- suppression de l'ancienne note modifiée ou manuelle (si elle est remplacée par une auto)
          delete from SQM_PENALTY
                where SQM_PENALTY_ID = tplPenalty.SQM_PENALTY_ID;
        end if;
      end if;

      fetch crDetail
       into tplDetail;
    end loop;
  end RegeneratePenalties;
end SQM_CALCULATE_RESULTS;
