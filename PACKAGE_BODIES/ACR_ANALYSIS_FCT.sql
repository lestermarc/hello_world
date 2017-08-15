--------------------------------------------------------
--  DDL for Package Body ACR_ANALYSIS_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_ANALYSIS_FCT" 
is

  /**
  * procédure SetActionTypeSequence
  * Description  Renumérotation des séquences du type d'action de la méthode donnée
  **/
  procedure SetActionTypeSequence(pMethodId ACR_ANALYSIS_METHOD.ACR_ANALYSIS_METHOD_ID%type) /* Méthode d'analyse      */
  is
    cursor cMethodActType
    is
      select ACR_ANALYSIS_ACT_TYPE_ID
      from ACR_ANALYSIS_ACT_TYPE
      where ACR_ANALYSIS_METHOD_ID = pMethodId
      order by AAT_SEQUENCE;

    vMethodActType cMethodActType%rowtype;
    vCounter       integer;
  begin
    vCounter := 0;
    open cMethodActType;
    fetch cMethodActType  into vMethodActType;
    while cMethodActType%found
    loop
      vCounter := vCounter + 1;
      update ACR_ANALYSIS_ACT_TYPE
      set AAT_SEQUENCE = vCounter * 10
      where ACR_ANALYSIS_ACT_TYPE_ID = vMethodActType.ACR_ANALYSIS_ACT_TYPE_ID;
      fetch cMethodActType  into vMethodActType;
    end loop;
  end SetActionTypeSequence;

  /**
  * function GetActionTypeSequence
  * Description  Recherche et incrémentation du n° de séquence du type d'action de la méthode donnée
  **/
  function GetActionTypeSequence(pMethodId ACR_ANALYSIS_METHOD.ACR_ANALYSIS_METHOD_ID%type ) /* Méthode d'analyse      */
        return ACR_ANALYSIS_ACT_TYPE.AAT_SEQUENCE%type
  is
    vResult ACR_ANALYSIS_ACT_TYPE.AAT_SEQUENCE%type;
  begin
    select count(*)
    into vResult
    from ACR_ANALYSIS_ACT_TYPE
    where ACR_ANALYSIS_METHOD_ID = pMethodId;

    vResult := (vResult * 10) + 10;

    return vResult;
  end GetActionTypeSequence;


  /**
  * procedure DuplicateAnalysisMethod
  * Description  Copie d'une méthode d'analyse donnée avec option de copier toute la chaîne parent - enfant
  **/
  procedure DuplicateAnalysisMethod(pSourceMethodId    ACR_ANALYSIS_METHOD.ACR_ANALYSIS_METHOD_ID%type,        /* Méthode d'analyse source                 */
                                    pDuplicateAllChain integer,                                         /* Copie de toute la chaîne parent - enfant */
                                    pTargetMethodId    in out ACR_ANALYSIS_METHOD.ACR_ANALYSIS_METHOD_ID%type  /* Méthode d'analyse cible                  */
                                    )
  is

  begin
    /*Réception nouvel id dans la variable de retour */
    select INIT_ID_SEQ.NextVal into pTargetMethodId from dual;
    /*Création d'un nouvel enregistrement sur la base de la méthode source avec le nouvel id*/
    insert into ACR_ANALYSIS_METHOD(
        ACR_ANALYSIS_METHOD_ID
      , DIC_ACR_ANALYSIS_METHOD1_ID
      , DIC_ACR_ANALYSIS_METHOD2_ID
      , DIC_ACR_ANALYSIS_METHOD3_ID
      , DIC_ACR_ANALYSIS_METHOD4_ID
      , DIC_ACR_ANALYSIS_METHOD5_ID
      , C_ANALYSIS_TYPE
      , AAM_KEY
      , AAM_DESCRIPTION
      , AAM_COMMENT
      , AAM_AVAILABLE
      , A_DATECRE
      , A_IDCRE)
    select pTargetMethodId
         , DIC_ACR_ANALYSIS_METHOD1_ID
         , DIC_ACR_ANALYSIS_METHOD2_ID
         , DIC_ACR_ANALYSIS_METHOD3_ID
         , DIC_ACR_ANALYSIS_METHOD4_ID
         , DIC_ACR_ANALYSIS_METHOD5_ID
         , C_ANALYSIS_TYPE
         , substr(AAM_KEY,1,15)  || ' [' || UserIni || ' - ' || to_char(sysdate, 'hhmmss') || ']'
         , AAM_DESCRIPTION
         , AAM_COMMENT
         , AAM_AVAILABLE
         , SYSDATE
         , UserIni
    from ACR_ANALYSIS_METHOD
    where ACR_ANALYSIS_METHOD_id = pSourceMethodId;

    /* Copie des types d'actions si le flag l'indique */
    if pDuplicateAllChain = 1 then
      insert into ACR_ANALYSIS_ACT_TYPE (
                ACR_ANALYSIS_ACT_TYPE_ID
              , ACR_ANALYSIS_METHOD_ID
              , DIC_ACR_ACTION_TYPE1_ID
              , DIC_ACR_ACTION_TYPE2_ID
              , DIC_ACR_ACTION_TYPE3_ID
              , DIC_ACR_ACTION_TYPE4_ID
              , DIC_ACR_ACTION_TYPE5_ID
              , C_ANALYSIS_ACT_TYPE
              , AAT_SEQUENCE
              , AAT_DESCRIPTION
              , AAT_COMMENT
              , AAT_ACTION_NAME
              , AAT_FOLLOWING_ACT
              , AAT_ANALYSE_SUPPRESSION
              , AAT_MULTIPLE_EXECUTION
              , AAT_STORED_PROC
              , A_DATECRE
              , A_IDCRE)
      select INIT_ID_SEQ.NextVal
           , pTargetMethodId
           , DIC_ACR_ACTION_TYPE1_ID
           , DIC_ACR_ACTION_TYPE2_ID
           , DIC_ACR_ACTION_TYPE3_ID
           , DIC_ACR_ACTION_TYPE4_ID
           , DIC_ACR_ACTION_TYPE5_ID
           , C_ANALYSIS_ACT_TYPE
           , AAT_SEQUENCE
           , AAT_DESCRIPTION
           , AAT_COMMENT
           , AAT_ACTION_NAME
           , AAT_FOLLOWING_ACT
           , AAT_ANALYSE_SUPPRESSION
           , AAT_MULTIPLE_EXECUTION
           , AAT_STORED_PROC
           , SYSDATE
           , UserIni
      from ACR_ANALYSIS_ACT_TYPE
      where ACR_ANALYSIS_METHOD_id = pSourceMethodId;
    end if;

  end DuplicateAnalysisMethod;


  /**
  * procedure CreateActions
  * Description  Création des actions pour l'analyse donnée
  **/
  procedure CreateActions(pAnalysisId  ACR_ANALYSIS.ACR_ANALYSIS_ID%type         /* Analyse           */
                          )
  is
    vMethodId ACR_ANALYSIS.ACR_ANALYSIS_METHOD_ID%type; /** Réceptionne méthode d'analyse de l'analyse donnée **/
  begin
    select ACR_ANALYSIS_METHOD_ID
    into vMethodId
    from ACR_ANALYSIS
    where ACR_ANALYSIS_ID = pAnalysisId ;

    CreateActions(vMethodId, pAnalysisId );
  end CreateActions;

  /**
  * procedure CreateActions
  * Description  Création des actions de l'analyse donnée sur la base
  *             des types d'actions de la méthode donnée
  **/
  procedure CreateActions(pMethodId    ACR_ANALYSIS.ACR_ANALYSIS_METHOD_ID%type, /* Méthode d'analyse */
                          pAnalysisId  ACR_ANALYSIS.ACR_ANALYSIS_ID%type         /* Analyse           */
                          )
  is
  begin
    /** Création des actions sur la base des types d'actions de la méthode **/
    insert into ACR_ANALYSIS_ACTION (
        ACR_ANALYSIS_ACTION_ID
      , ACR_ANALYSIS_ACT_TYPE_ID
      , ACR_ANALYSIS_ID
      , AAA_SEQUENCE
      , AAA_STORED_PROC
      , AAA_JOB
      , AAA_DESCRIPTION
      , A_DATECRE
      , A_IDCRE)
    select INIT_ID_SEQ.NEXTVAL
         , ACR_ANALYSIS_ACT_TYPE_ID
         , pAnalysisId
         , AAT_SEQUENCE
         , AAT_STORED_PROC
         , AAT_JOB
         , AAT_DESCRIPTION
         , SYSDATE
         , UserIni
    from ACR_ANALYSIS_ACT_TYPE
    where ACR_ANALYSIS_METHOD_ID = pMethodId;
  end CreateActions;

  /**
  * procedure CreateAnalysis
  * Description  Création d'un enregistrement d'analyse de synthèse
  **/
  procedure CreateAnalysis(pMethodId           ACR_ANALYSIS.ACR_ANALYSIS_METHOD_ID%type, /* Méthode d'analyse      */
                           pDescription        ACR_ANALYSIS.AAN_DESCRIPTION%type,        /* Libellé analyse        */
                           pStartDate          ACR_ANALYSIS.AAN_START_REF_DATE%type,     /* Date de référence début*/
                           pEndDate            ACR_ANALYSIS.AAN_END_REF_DATE%type,       /* Date de référence fin  */
                           pAnalysisId  in out ACR_ANALYSIS.ACR_ANALYSIS_ID%type         /* Id enregistrement créé */
                           )
  is
   vAnalysisId  ACR_ANALYSIS.ACR_ANALYSIS_ID%type;  /* Réceptionne Id enregistrement créé */
  begin
    /** Réception d'un nouvel Id d'analyse **/
    select INIT_ID_SEQ.NEXTVAL  into vAnalysisId from dual;

    /** Création de l'Analyse **/
    insert into ACR_ANALYSIS (
        ACR_ANALYSIS_ID
      , ACR_ANALYSIS_METHOD_ID
      , AAN_DESCRIPTION
      , AAN_START_REF_DATE
      , AAN_END_REF_DATE
      , A_DATECRE
      , A_IDCRE)
    select vAnalysisId
         , pMethodId
         , nvl(pDescription, AAM_DESCRIPTION)
         , pStartDate
         , pEndDate
         , SYSDATE
         , UserIni
    from ACR_ANALYSIS_METHOD
    where ACR_ANALYSIS_METHOD_ID = pMethodId;

    /** Création des actions de la méthode **/
    CreateActions(pMethodId, vAnalysisId);

    pAnalysisId := vAnalysisId;
  end CreateAnalysis;

  /**
  * procedure ExecuteAction
  * Description  Lancement de la procédure de l'action donnée
  **/
  procedure ExecuteAction(pActionId ACR_ANALYSIS_ACTION.ACR_ANALYSIS_ACTION_ID%type  /* Action          */
                         )
  is
    vProcedureName     ACR_ANALYSIS.AAN_COMMENT%type;
    vJobName           ACR_ANALYSIS.AAN_COMMENT%type;
    vJobNumber         PCS.PC_JOB.JOB_NUMBER%type;
    vAnalysisId        ACR_ANALYSIS.ACR_ANALYSIS_ID%type;
    vAnalysisMethodId  ACR_ANALYSIS_METHOD.ACR_ANALYSIS_METHOD_ID%type;
    vAnalysisActTypeId ACR_ANALYSIS_ACT_TYPE.ACR_ANALYSIS_ACT_TYPE_ID%type;
    vAnalysisActType   ACR_ANALYSIS_ACT_TYPE.C_ANALYSIS_ACT_TYPE%type;
  begin
    select AAA.AAA_STORED_PROC, AAA.AAA_JOB, AAN.ACR_ANALYSIS_ID, AAM.ACR_ANALYSIS_METHOD_ID, AAT.ACR_ANALYSIS_ACT_TYPE_ID, AAT.C_ANALYSIS_ACT_TYPE
    into vProcedureName, vJobName, vAnalysisId, vAnalysisMethodId, vAnalysisActTypeId, vAnalysisActType
    from ACR_ANALYSIS_ACTION AAA, ACR_ANALYSIS AAN, ACR_ANALYSIS_METHOD AAM, ACR_ANALYSIS_ACT_TYPE AAT
    where AAA.ACR_ANALYSIS_ACTION_ID   = pActionId
      and AAN.ACR_ANALYSIS_ID          = AAA.ACR_ANALYSIS_ID
      and AAM.ACR_ANALYSIS_METHOD_ID   = AAN.ACR_ANALYSIS_METHOD_ID
      and AAT.ACR_ANALYSIS_METHOD_ID   = AAM.ACR_ANALYSIS_METHOD_ID
      and AAT.ACR_ANALYSIS_ACT_TYPE_ID = AAA.ACR_ANALYSIS_ACT_TYPE_ID;

    if vAnalysisActType = '1' then /** Procédure stockée **/
      vProcedureName := 'BEGIN ' || vProcedureName || '(:pAnalysisId, :pAnalysisMethodId, :pActionId); END;';
      execute immediate vProcedureName
      using vAnalysisId, vAnalysisMethodId, pActionId;
    elsif vAnalysisActType = '2' then  /** Job **/
      vJobNumber := 0;
      begin
        select JOB_NUMBER
        into vJobNumber
        from PCS.PC_JOB
        where JOB_NAME = SUBSTR(vJobName,INSTR(vJobName,'.') + 1,LENGTH(vJobName) - INSTR(vJobName,'.'));
      exception
        when no_data_found then
          vJobNumber := 0;
      end;
      if vJobNumber <> 0 then
        vProcedureName := 'BEGIN DBMS_JOB.RUN(:JOB_NUMBER); END;';
        execute immediate vProcedureName
        using vJobNumber;
      end if;
    end if;
    update ACR_ANALYSIS_ACTION
    set AAA_EXECUTED_ON = SYSDATE
      , AAA_EXECUTED_BY = UserIni
    where ACR_ANALYSIS_ACTION_ID = pActionId;
  end ExecuteAction;

  /**
  * procedure ExecuteAllAction
  * Description  Lancement des procédures de l'analyse donnée
  **/
  procedure ExecuteAllAction(pAnalysisId ACR_ANALYSIS.ACR_ANALYSIS_ID%type  /* Analyse   */
                            )
  is
    /**
    * Curseur de retour des informations des actions de l'analyse donnée
    **/
    cursor AnalysisActionsCursor
    is
    select AAA.AAA_STORED_PROC, AAA.AAA_JOB, AAM.ACR_ANALYSIS_METHOD_ID, AAT.ACR_ANALYSIS_ACT_TYPE_ID, AAT.C_ANALYSIS_ACT_TYPE, AAA.ACR_ANALYSIS_ACTION_ID
    from ACR_ANALYSIS_ACTION AAA,
         ACR_ANALYSIS AAN,
	       ACR_ANALYSIS_METHOD AAM,
	       ACR_ANALYSIS_ACT_TYPE AAT
    where AAN.ACR_ANALYSIS_ID          = pAnalysisId
      and AAA.ACR_ANALYSIS_ID          = AAN.ACR_ANALYSIS_ID
      and AAM.ACR_ANALYSIS_METHOD_ID   = AAN.ACR_ANALYSIS_METHOD_ID
      and AAT.ACR_ANALYSIS_METHOD_ID   = AAM.ACR_ANALYSIS_METHOD_ID
      and AAT.ACR_ANALYSIS_ACT_TYPE_ID = AAA.ACR_ANALYSIS_ACT_TYPE_ID
    order by AAT_SEQUENCE;

    vAnalysisActions AnalysisActionsCursor%rowtype;
    vProcedureName     ACR_ANALYSIS.AAN_COMMENT%type;
    vJobNumber         PCS.PC_JOB.JOB_NUMBER%type;
  begin
    open AnalysisActionsCursor;
    fetch AnalysisActionsCursor into vAnalysisActions;
    while AnalysisActionsCursor%found
    loop
      if ACR_ANALYSIS_FCT.CanExecuteAction(vAnalysisActions.ACR_ANALYSIS_ACTION_ID) = 1 then
        if vAnalysisActions.C_ANALYSIS_ACT_TYPE = '1' then /** Procédure stockée **/
          vProcedureName := 'BEGIN ' || vAnalysisActions.AAA_STORED_PROC || '(:pAnalysisId, :pAnalysisMethodId, :pActionId); END;';
          execute immediate vProcedureName
          using pAnalysisId , vAnalysisActions.ACR_ANALYSIS_METHOD_ID, vAnalysisActions.ACR_ANALYSIS_ACTION_ID;
        elsif vAnalysisActions.C_ANALYSIS_ACT_TYPE = '2' then  /** Job **/
          vJobNumber := 0;
          begin
            select JOB_NUMBER
            into vJobNumber
            from PCS.PC_JOB
            where JOB_NAME = SUBSTR(vAnalysisActions.AAA_JOB,INSTR(vAnalysisActions.AAA_JOB,'.') + 1,LENGTH(vAnalysisActions.AAA_JOB) - INSTR(vAnalysisActions.AAA_JOB,'.'));
          exception
            when no_data_found then
              vJobNumber := 0;
          end;
          if vJobNumber <> 0 then
            vProcedureName := 'BEGIN DBMS_JOB.RUN(:JOB_NUMBER); END;';
            execute immediate vProcedureName
            using vJobNumber;
          end if;
        end if;

        update ACR_ANALYSIS_ACTION
        set AAA_EXECUTED_ON = SYSDATE
          , AAA_EXECUTED_BY = UserIni
        where ACR_ANALYSIS_ACTION_ID = vAnalysisActions.ACR_ANALYSIS_ACTION_ID;
      end if;
      fetch AnalysisActionsCursor into vAnalysisActions;
    end loop;
  end ExecuteAllAction;

  /**
  * procedure CanExecuteAction
  * Description  Indique si l'action passée en paramètre peut être exécuté
  **/
  function CanExecuteAction(pAnalysisActionId ACR_ANALYSIS_ACTION.ACR_ANALYSIS_ACTION_ID%type)
    return integer
  is
    /** Curseur de retour des actions précédents par la séquence l'action courante **/
    cursor PreviousActionsCursor
    is
      select ANA.AAA_SEQUENCE,
             decode(ANA.AAA_EXECUTED_ON,null,0,1) AAA_EXECUTED_ON ,
             decode(ANA.AAA_EXECUTED_BY,null,0,1) AAA_EXECUTED_BY
      from ACR_ANALYSIS_ACTION ANA
         , ACR_ANALYSIS_ACTION AAA
      where AAA.ACR_ANALYSIS_ACTION_ID   = pAnalysisActionId
        and ANA.ACR_ANALYSIS_ID          = AAA.ACR_ANALYSIS_ID
        and ANA.AAA_SEQUENCE             < AAA.AAA_SEQUENCE
      order by AAA_SEQUENCE desc;

    vResult          integer;
    vFollowingAct    ACR_ANALYSIS_ACT_TYPE.AAT_FOLLOWING_ACT%type;
    vActSequence     ACR_ANALYSIS_ACTION.AAA_SEQUENCE%type;
    vPreviousActions PreviousActionsCursor%rowtype;
  begin
    /* Réception des valeurs utilisées et vérification du multi - lancement de l'action */
    select nvl(max(AAT_MULTIPLE_EXECUTION),0) , nvl(max(AAT_FOLLOWING_ACT),0)
    into vResult , vFollowingAct
    from ACR_ANALYSIS_ACT_TYPE AAT, ACR_ANALYSIS_ACTION AAA
    where AAA.ACR_ANALYSIS_ACTION_ID   = pAnalysisActionId
      and AAT.ACR_ANALYSIS_ACT_TYPE_ID = AAA.ACR_ANALYSIS_ACT_TYPE_ID;

    /* Si pas de multi - exécution Contrôler l'exécution antérieure de l'action */
    if vResult = 0 then
      select decode (max(ACR_ANALYSIS_ACTION_ID), null,0,1)
      into vResult
      from ACR_ANALYSIS_ACTION AAA
      where AAA.ACR_ANALYSIS_ACTION_ID   = pAnalysisActionId
        and AAA.AAA_EXECUTED_ON IS NULL
        and AAA.AAA_EXECUTED_BY IS NULL;
      /** La procédure peut être exécutée --> Contrôler si l'action précédente est terminés pour une action consécutive **/
      if (vResult = 1) and (vFollowingAct = 1) then
        open PreviousActionsCursor;
        fetch PreviousActionsCursor into vPreviousActions;
        if PreviousActionsCursor%found then
          if (vPreviousActions.AAA_EXECUTED_ON = 0) and (vPreviousActions.AAA_EXECUTED_BY = 0) then
            vResult := 0;
          end if;
        end if;
        close PreviousActionsCursor;
      end if;
    end if;
    return vResult;
  end CanExecuteAction;

  /**
  * procedure CanDeleteAnalyse
  * Description  Retourne l'état du flag  indiquant la supression ou non de l'analyse
  **/
  function CanDeleteAnalyse(pAnalysisActionId ACR_ANALYSIS_ACTION.ACR_ANALYSIS_ACTION_ID%type)
    return integer
  is
    vResult        integer;
  begin
    select DECODE( MAX(AAA.AAA_EXECUTED_ON), null,0,1)
    into vResult
    from  ACR_ANALYSIS_ACTION AAA
    where AAA.ACR_ANALYSIS_ACTION_ID   = pAnalysisActionId;

    if vResult = 1 then
      /* Vérifier la possibilité de supprimer après exécution */
      select nvl(max(AAT_ANALYSE_SUPPRESSION),0)
      into vResult
      from ACR_ANALYSIS_ACT_TYPE AAT, ACR_ANALYSIS_ACTION AAA
      where AAA.ACR_ANALYSIS_ACTION_ID   = pAnalysisActionId
        and AAT.ACR_ANALYSIS_ACT_TYPE_ID = AAA.ACR_ANALYSIS_ACT_TYPE_ID;
    end if;

    return vResult;
  end CanDeleteAnalyse;


begin
  UserIni         := PCS.PC_I_LIB_SESSION.GetUserIni;
  LocalCurrencyId := ACS_FUNCTION.GetLocalCurrencyId;
end ACR_ANALYSIS_FCT;
