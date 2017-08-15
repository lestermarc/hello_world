--------------------------------------------------------
--  DDL for Package Body FAL_PFG_ENTRY_SYSTEMS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PFG_ENTRY_SYSTEMS" 
is
  -- Attention à la correspondance des séparateurs avec ceux des fichiers de
  -- données des système des saisie externe et des fichiers de contrôle !!!

  -- Séparateur de liste pour les enregistrements du fichier
  cSeparator            constant varchar2(1)  := ';';
  -- Séparateur de liste pour les enregistrements du fichier Calitime
  cCalitimeSeparator    constant varchar2(1)  := '|';
  -- Configurations
  cCombinedRefSeparator constant varchar2(1)  := nvl(PCS.PC_CONFIG.GetConfig('FAL_SEPAR_ORIGIN_REF_SEQ'), '/');
  -- Séparateur utilisé dans la référence GAL
  cGalSeparator         constant varchar2(1)  := cCombinedRefSeparator;
  -- Séparateur décimal pour les réels dans le fichier
  cDecimalSeparator     constant varchar2(1)  := '.';
  -- Format de date dans le fichier
  cDateFormat           constant varchar2(8)  := 'YYYYMMDD';
  -- Longueur maximale de l'ID d'opération pour RETech
  cRETechTalIdLength    constant integer      := 9;
  -- Longueur maximale de l'ID d'opération pour Calitime
  cCaliTalIdLength      constant integer      := 10;
  -- Modes de conversion de l'opérateur (Dic. operateur, numéro d'employé, ressource n°2)
  omDicOperator         constant integer      := 0;
  omDicOperatorEmpNumer constant integer      := 1;
  omFacFloorEmpNumer    constant integer      := 2;
  omFacFloorOperator    constant integer      := 3;
  cImportOperatorMode   constant integer      := nvl(PCS.PC_CONFIG.GetConfig('FAL_PFG_IMPORT_OPERATOR_MODE'), omDicOperator);
  -- Champ référence alternatif pour les ateliers
  cAltFacRefField       constant varchar2(30) := nvl(PCS.PC_CONFIG.GetConfig('FAL_PFG_ALT_FAC_REF_FIELD'), 'FAC_REFERENCE');
  cWorkUnitAdjustment   constant integer      := case
    when PCS.PC_CONFIG.GetConfig('PPS_WORK_UNIT') = 'M' then 60
    else 1
  end;

  /**
   * function TimeAsExport
   * Description
   *   Retourne les données d'exportation vers TimeAs sous forme de lignes du
   *   fichier de données en mode "pipelined".
   */
  function TimeAsExport
    return TROWS pipelined
  is
    cursor crTimeAsExportRows
    is
      select   cSeparator ||
               substr(LOT.LOT_REFCOMPL, 1, 20) ||
               cSeparator ||
               substr(GOO.GOO_MAJOR_REFERENCE, 1, 30) ||
               cSeparator ||
               substr(GOO.GOO_MAJOR_REFERENCE, 1, 15) ||
               cSeparator ||
               cSeparator ||
               '1' ||
               cSeparator ||
               to_char(LOT.A_DATECRE, cDateFormat) ||
               cSeparator ||
               to_char(LOT.LOT_PLAN_BEGIN_DTE, cDateFormat) ||
               cSeparator ||
               to_char(LOT.LOT_PLAN_END_DTE, cDateFormat) ||
               cSeparator ||
               cSeparator ||
               cSeparator ||
               '0001' ||
               cSeparator ||
               substr(GOO.GOO_MAJOR_REFERENCE, 1, 30) ||
               cSeparator ||
               cSeparator ||
               cSeparator ||
               cSeparator ||
               cSeparator ||
               TAL.SCS_STEP_NUMBER ||
               cSeparator ||
               poProduction ||
               lpad(TAL.FAL_SCHEDULE_STEP_ID, 12, '0') ||
               cSeparator ||
               to_char(TAL.TAL_BEGIN_PLAN_DATE, cDateFormat) ||
               cSeparator ||
               to_char(TAL.TAL_END_PLAN_DATE, cDateFormat) ||
               cSeparator ||
               substr(TAL.SCS_SHORT_DESCR, 1, 40) ||
               cSeparator ||
               cSeparator ||
               GetTimeAsAltFacRef(FAC.FAL_FACTORY_FLOOR_ID) ||
               cSeparator ||
               to_number(to_char(TAL.TAL_DUE_QTY, '9999999999990.99') ) ||
               cSeparator ||
               cSeparator ||
               to_number(to_char(TAL.TAL_TSK_BALANCE, '99999999990.9999') ) ||
               cSeparator ||
               to_number(to_char(TAL.TAL_DUE_QTY, '9999999999990.99') ) ||
               cSeparator ||
               (case
                  when nvl(TAL.SCS_QTY_FIX_ADJUSTING, 0) = 0 then to_number(to_char(TAL.TAL_TSK_AD_BALANCE / cWorkUnitAdjustment, '9999999999990.99') )
                  else to_number(to_char(ceil(TAL.TAL_DUE_QTY / TAL.SCS_QTY_FIX_ADJUSTING) * TAL.SCS_ADJUSTING_TIME / cWorkUnitAdjustment, '9999999999990.99') )
                end
               ) ||
               cSeparator ||
               '0' ROW_DATA
             , LOT.LOT_REFCOMPL || cCombinedRefSeparator || TAL.SCS_STEP_NUMBER ORDER_BY
          from FAL_LOT LOT
             , FAL_TASK_LINK TAL
             , GCO_GOOD GOO
             , FAL_FACTORY_FLOOR FAC
         where LOT.C_LOT_STATUS = '2'
           and nvl(LOT.C_FAB_TYPE, '0') <> '4'
           and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
           and TAL.C_OPERATION_TYPE in('1', '4')
           and TAL.TAL_DUE_QTY > 0
           and LOT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
           and TAL.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
      union all
      select   cSeparator ||
               truncstr(PRJ.PRJ_CODE || cGalSeparator || TAS.TAS_CODE, -20) ||
               cSeparator ||
               substr(PRJ.PRJ_WORDING, 1, 30) ||
               cSeparator ||
               substr(TAS.TAS_CODE, 1, 15) ||
               cSeparator ||
               substr(TAS.TAS_WORDING, 1, 30) ||
               cSeparator ||
               '1' ||
               cSeparator ||
               to_char(TAS.A_DATECRE, cDateFormat) ||
               cSeparator ||
               to_char(TAS.TAS_START_DATE, cDateFormat) ||
               cSeparator ||
               to_char(TAS.TAS_END_DATE, cDateFormat) ||
               cSeparator ||
               cSeparator ||
               cSeparator ||
               '0001' ||
               cSeparator ||
               substr(TAS.TAS_CODE, 1, 30) ||
               cSeparator ||
               cSeparator ||
               cSeparator ||
               cSeparator ||
               cSeparator ||
               TAL.SCS_STEP_NUMBER ||
               cSeparator ||
               poProject ||
               lpad(TAL.GAL_TASK_LINK_ID, 12, '0') ||
               cSeparator ||
               to_char(TAL.TAL_BEGIN_PLAN_DATE, cDateFormat) ||
               cSeparator ||
               to_char(TAL.TAL_END_PLAN_DATE, cDateFormat) ||
               cSeparator ||
               substr(TAL.SCS_SHORT_DESCR, 1, 40) ||
               cSeparator ||
               cSeparator ||
               GetTimeAsAltFacRef(FAC.FAL_FACTORY_FLOOR_ID) ||
               cSeparator ||
               cSeparator ||
               cSeparator ||
               to_number(to_char(TAL.TAL_TSK_BALANCE, '99999999990.9999') ) ||
               cSeparator ||
               cSeparator ||
               cSeparator ||
               '0' ROW_DATA
              , PRJ.PRJ_CODE || cGalSeparator || TAS.TAS_CODE || cCombinedRefSeparator || TAL.SCS_STEP_NUMBER ORDER_BY
          from GAL_TASK TAS
             , GAL_PROJECT PRJ
             , GAL_TASK_LINK TAL
             , FAL_FACTORY_FLOOR FAC
         where TAL.C_TAL_STATE in('20', '30')
           and PRJ.GAL_PROJECT_ID = TAS.GAL_PROJECT_ID
           and TAS.GAL_TASK_ID = TAL.GAL_TASK_ID
           and TAL.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
      order by ORDER_BY;
  begin
    for tplTimeAsExportRow in crTimeAsExportRows loop
      pipe row(tplTimeAsExportRow.ROW_DATA);
    end loop;
  end TimeAsExport;

  /**
   * function RETechExport
   * Description
   *   Retourne les données d'exportation vers RETECH sous forme de lignes du
   *   fichier de données en mode "pipelined".
   */
  function RETechExport
    return TROWS pipelined
  is
    cursor crRETechExportRows
    is
      select   truncstr(TAL.FAL_SCHEDULE_STEP_ID, -cRETechTalIdLength) ||
               cSeparator ||
               substr(poProduction || cCombinedRefSeparator || LOT.LOT_REFCOMPL, 1, 30) ||
               cSeparator ||
               DOC.RCO_TITLE ||
               cSeparator ||
               GOO.GOO_MAJOR_REFERENCE ROW_DATA
             , LOT.LOT_REFCOMPL || cCombinedRefSeparator || TAL.SCS_STEP_NUMBER ORDER_BY
          from FAL_LOT LOT
             , FAL_TASK_LINK TAL
             , GCO_GOOD GOO
             , DOC_RECORD DOC
         where LOT.C_LOT_STATUS = '2'
           and nvl(LOT.C_FAB_TYPE, '0') <> '4'
           and TAL.FAL_LOT_ID = LOT.FAL_LOT_ID
           and TAL.C_OPERATION_TYPE = '1'
           and TAL.C_TASK_TYPE = '1'
           and TAL.TAL_DUE_QTY > 0
           and GOO.GCO_GOOD_ID = LOT.GCO_GOOD_ID
           and LOT.DOC_RECORD_ID = DOC.DOC_RECORD_ID(+)
      union all
      select   truncstr(TAL.GAL_TASK_LINK_ID, -cRETechTalIdLength) ||
               cSeparator ||
               substr(poProject || cCombinedRefSeparator || PRJ.PRJ_CODE || cGalSeparator || TAS.TAS_CODE, 1, 30) ||
               cSeparator ||
               TAS.TAS_WORDING ||
               cSeparator ||
               PRJ.PRJ_WORDING ROW_DATA
             , PRJ.PRJ_CODE || cGalSeparator || TAS.TAS_CODE || cCombinedRefSeparator || TAL.SCS_STEP_NUMBER ORDER_BY
          from GAL_TASK TAS
             , GAL_PROJECT PRJ
             , GAL_TASK_LINK TAL
         where TAL.C_TAL_STATE in('20', '30')
           and TAL.C_TASK_TYPE = '1'
           and PRJ.GAL_PROJECT_ID = TAS.GAL_PROJECT_ID
           and TAS.GAL_TASK_ID = TAL.GAL_TASK_ID
      order by ORDER_BY;
  begin
    for tplRETechExportRow in crRETechExportRows loop
      pipe row(tplRETechExportRow.ROW_DATA);
    end loop;
  end RETechExport;

  /**
   * function CalitimeExport
   * Description
   *   Retourne les données d'exportation vers Calitime sous forme de lignes du
   *   fichier de données en mode "pipelined".
   */
  function CalitimeExport
    return TROWS pipelined
  is
    cursor crCalitimeExportRows
    is
      select   truncstr(TAL.FAL_SCHEDULE_STEP_ID, -cCaliTalIdLength) ||
               cCalitimeSeparator ||
               substr(poProduction || cCombinedRefSeparator || LOT.LOT_REFCOMPL, 1, 60) ||
               cCalitimeSeparator ||
               TAL.SCS_STEP_NUMBER ||
               cCalitimeSeparator ||
               TAS.TAS_REF ROW_DATA
             , LOT.LOT_REFCOMPL || cCombinedRefSeparator || TAL.SCS_STEP_NUMBER ORDER_BY
          from FAL_LOT LOT
             , FAL_TASK_LINK TAL
             , FAL_TASK TAS
         where LOT.C_LOT_STATUS = '2'
           and nvl(LOT.C_FAB_TYPE, '0') <> '4'
           and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
           and TAL.C_OPERATION_TYPE = '1'
           and TAL.TAL_DUE_QTY > 0
           and TAL.FAL_TASK_ID = TAS.FAL_TASK_ID
      union all
      select   truncstr(TAL.GAL_TASK_LINK_ID, -cCaliTalIdLength) ||
               cCalitimeSeparator ||
               substr(poProduction || cCombinedRefSeparator || PRJ.PRJ_CODE || cGalSeparator || TAS.TAS_CODE, 1, 60) ||
               cCalitimeSeparator ||
               TAL.SCS_STEP_NUMBER ||
               cCalitimeSeparator ||
               TAS.TAS_WORDING ROW_DATA
             , PRJ.PRJ_CODE || cGalSeparator || TAS.TAS_CODE || cCombinedRefSeparator || TAL.SCS_STEP_NUMBER ORDER_BY
          from GAL_TASK TAS
             , GAL_PROJECT PRJ
             , GAL_TASK_LINK TAL
         where TAL.C_TAL_STATE in('20', '30')
           and PRJ.GAL_PROJECT_ID = TAS.GAL_PROJECT_ID
           and TAS.GAL_TASK_ID = TAL.GAL_TASK_ID
      order by ORDER_BY;
  begin
    for tplCalitimeExportRow in crCalitimeExportRows loop
      pipe row(tplCalitimeExportRow.ROW_DATA);
    end loop;
  end CalitimeExport;

  /**
   * function MobaTimeExport
   * Description
   *   Retourne les données d'exportation vers MobaTime sous forme de lignes du
   *   fichier de données en mode "pipelined".
   */
  function MobaTimeExport
    return TROWS pipelined
  is
    cursor crMobaTimeExportRows
    is
      select   lpad(TAL.FAL_SCHEDULE_STEP_ID, 10, '0') ||
               cSeparator ||
               lpad(JOP.JOP_REFERENCE, 3, '0') ||
               lpad(ORD.ORD_REF, 6, '0') ||
               lpad(LOT.LOT_REF, 1, '0') ||
               cSeparator ||
               lpad(TAL.SCS_STEP_NUMBER, 4, '0') ||
               cSeparator ||
               rpad(substr(RCO.RCO_DESCRIPTION, 1, 20) || substr(ORD.ORD_PSHORT_DESCR, 1, 8), 28, ' ') ||
               cSeparator ||
               rpad(substr(TAL.SCS_SHORT_DESCR, 1, 30), 30, ' ') ||
               cSeparator ||
               rpad(substr(GetAltFacRef(TAL.FAL_FACTORY_FLOOR_ID), 1, 5), 7, ' ') ROW_DATA
             , LOT.LOT_REFCOMPL || cCombinedRefSeparator || TAL.SCS_STEP_NUMBER ORDER_BY
          from FAL_JOB_PROGRAM JOP
             , FAL_ORDER ORD
             , FAL_LOT LOT
             , FAL_TASK_LINK TAL
             , DOC_RECORD RCO
             , FAL_FACTORY_FLOOR FAC
         where JOP.FAL_JOB_PROGRAM_ID = ORD.FAL_JOB_PROGRAM_ID
           and ORD.FAL_ORDER_ID = LOT.FAL_ORDER_ID
           and LOT.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
           and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
           and TAL.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+)
           and LOT.C_LOT_STATUS = '2'
           and nvl(LOT.C_FAB_TYPE, '0') <> '4'
           and TAL.C_OPERATION_TYPE = '1'
           and TAL.TAL_DUE_QTY > 0
      union all
      select   lpad(TAL.GAL_TASK_LINK_ID, 10, '0') ||
               cSeparator ||
               substr(PRJ.PRJ_CODE || cGalSeparator || TAS.TAS_CODE, 1, 10) ||
               cSeparator ||
               lpad(TAL.SCS_STEP_NUMBER, 4, '0') ||
               cSeparator ||
               rpad(substr(PRJ.PRJ_WORDING, 1, 20) || substr(TAS.TAS_WORDING, 1, 8), 28, ' ') ||
               cSeparator ||
               rpad(substr(TAL.SCS_SHORT_DESCR, 1, 30), 30, ' ') ||
               cSeparator ||
               rpad(substr(GetAltFacRef(TAL.FAL_FACTORY_FLOOR_ID), 1, 5), 7, ' ') ROW_DATA
             , PRJ.PRJ_CODE || cGalSeparator || TAS.TAS_CODE || cCombinedRefSeparator || TAL.SCS_STEP_NUMBER ORDER_BY
          from GAL_TASK TAS
             , GAL_PROJECT PRJ
             , GAL_TASK_LINK TAL
         where TAL.C_TAL_STATE in('20', '30')
           and PRJ.GAL_PROJECT_ID = TAS.GAL_PROJECT_ID
           and TAS.GAL_TASK_ID = TAL.GAL_TASK_ID
      order by ORDER_BY;
  begin
    for tplMobaTimeExportRow in crMobaTimeExportRows loop
      pipe row(tplMobaTimeExportRow.ROW_DATA);
    end loop;
  end MobaTimeExport;

  /**
   * function GetAltFacRef
   * Description
   *   Retourne la référence alternative de l'atelier qui correspond à la valeur
   *   du champ spécifié dans la config FAL_PFG_ALT_FAC_REF_FIELD.
   *   FAC_REFERENCE est utilisé par défaut si la config est vide.
   */
  function GetAltFacRef(aFactoryFloorId FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type)
    return varchar2
  is
    vResult varchar2(255);
  begin
    if aFactoryFloorId is not null then
      execute immediate 'select ' || cAltFacRefField || '  from FAL_FACTORY_FLOOR ' || ' where FAL_FACTORY_FLOOR_ID = :FAL_FACTORY_FLOOR_ID'
                   into vResult
                  using in aFactoryFloorId;
    end if;

    return vResult;
  end GetAltFacRef;

  /**
   * function GetTimeAsAltFacRef
   * Description
   *   Retourne la référence alternative de l'atelier qui correspond à la valeur
   *   du champ spécifié dans la config FAL_PFG_ALT_FAC_REF_FIELD, formattée
   *   pour TimeAs.
   *   FAC_REFERENCE est utilisé par défaut si la config est vide.
   */
  function GetTimeAsAltFacRef(aFactoryFloorId FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type)
    return varchar2
  is
    vResult varchar2(255);
  begin
    vResult  := GetAltFacRef(aFactoryFloorId);
    return lpad(vResult, 4, '0');
  exception
    when others then
      ra(aMessage   => PCS.PC_FUNCTIONS.TranslateWord('Veuillez vérifier le format de la référence de vos ateliers') || co.cLineBreak || co.cLineBreak
                       || sqlerrm
       , aErrNo     => -20958
        );
  end GetTimeAsAltFacRef;

  /**
   * function GetLotRefComplFromTalId
   * Description
   *   Permet de retourner la référence complète d'un lot selon l'ID d'une opération
   */
  function GetLotRefComplFromTalId(aTaskLinkId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, aTalIdLength integer default null)
    return FAL_LOT_PROGRESS_FOG.PFG_LOT_REFCOMPL%type
  is
    vResult FAL_LOT_PROGRESS_FOG.PFG_LOT_REFCOMPL%type;
  begin
    if aTalIdLength is null then
      select max(LOT.LOT_REFCOMPL)
        into vResult
        from FAL_LOT LOT
           , FAL_TASK_LINK TAL
       where TAL.FAL_SCHEDULE_STEP_ID = aTaskLinkId
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID;
    else
      select   max(LOT.LOT_REFCOMPL)
          into vResult
          from FAL_LOT LOT
             , FAL_TASK_LINK TAL
         where truncstr(TAL.FAL_SCHEDULE_STEP_ID, -aTalIdLength) = aTaskLinkId
           and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
      order by nvl(TAL.A_DATEMOD, TAL.A_DATECRE) desc;
    end if;

    return vResult;
  end GetLotRefComplFromTalId;

  /**
   * function GetGalRefComplFromTalId
   * Description
   *   Permet de retourner la référence complète affaire/tâche selon l'ID d'une opération
   */
  function GetGalRefComplFromTalId(aTaskLinkId GAL_TASK_LINK.GAL_TASK_LINK_ID%type, aTalIdLength integer default null)
    return FAL_LOT_PROGRESS_FOG.PFG_GAL_REFCOMPL%type
  is
    vResult FAL_LOT_PROGRESS_FOG.PFG_GAL_REFCOMPL%type;
  begin
    if aTalIdLength is null then
      select max(PRJ.PRJ_CODE || cGalSeparator || TAS.TAS_CODE)
        into vResult
        from GAL_PROJECT PRJ
           , GAL_TASK TAS
           , GAL_TASK_LINK TAL
       where TAL.GAL_TASK_LINK_ID = aTaskLinkId
         and TAS.GAL_TASK_ID = TAL.GAL_TASK_ID
         and PRJ.GAL_PROJECT_ID = TAS.GAL_PROJECT_ID;
    else
      select   max(PRJ.PRJ_CODE || cGalSeparator || TAS.TAS_CODE)
          into vResult
          from GAL_PROJECT PRJ
             , GAL_TASK TAS
             , GAL_TASK_LINK TAL
         where truncstr(TAL.GAL_TASK_LINK_ID, -aTalIdLength) = aTaskLinkId
           and TAS.GAL_TASK_ID = TAL.GAL_TASK_ID
           and PRJ.GAL_PROJECT_ID = TAS.GAL_PROJECT_ID
      order by nvl(TAL.A_DATEMOD, TAL.A_DATECRE) desc;
    end if;

    return vResult;
  end GetGalRefComplFromTalId;

  /**
   * function GetSeqFromTalId
   * Description
   *   Permet de retourner la séquence d'une opération selon son ID
   */
  function GetSeqFromTalId(aTaskLinkId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, aTalIdLength integer default null)
    return FAL_LOT_PROGRESS_FOG.PFG_SEQ%type
  is
    vResult FAL_LOT_PROGRESS_FOG.PFG_SEQ%type;
  begin
    if aTalIdLength is null then
      -- Recherche dans les opérations de production
      select max(SCS_STEP_NUMBER)
        into vResult
        from FAL_TASK_LINK TAL
       where TAL.FAL_SCHEDULE_STEP_ID = aTaskLinkId;

      -- Recherche dans les opérations de gestion à l'affaire si non trouvé
      if vResult is null then
        select max(SCS_STEP_NUMBER)
          into vResult
          from GAL_TASK_LINK TAL
         where TAL.GAL_TASK_LINK_ID = aTaskLinkId;
      end if;
    else
      -- Recherche dans les opérations de production
      select   max(SCS_STEP_NUMBER)
          into vResult
          from FAL_TASK_LINK TAL
         where truncstr(TAL.FAL_SCHEDULE_STEP_ID, -aTalIdLength) = aTaskLinkId
      order by nvl(A_DATEMOD, A_DATECRE) desc;

      -- Recherche dans les opérations de gestion à l'affaire si non trouvé
      if vResult is null then
        select   max(SCS_STEP_NUMBER)
            into vResult
            from GAL_TASK_LINK TAL
           where truncstr(TAL.GAL_TASK_LINK_ID, -aTalIdLength) = aTaskLinkId
        order by nvl(A_DATEMOD, A_DATECRE) desc;
      end if;
    end if;

    return vResult;
  end GetSeqFromTalId;

  /**
   * function GetLotRefComplFromRETechTalId
   * Description
   *   Permet de retourner la référence complète d'un lot selon l'ID d'une opération provenant de RETech
   */
  function GetLotRefComplFromRETechTalId(aTaskLinkId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_LOT_PROGRESS_FOG.PFG_LOT_REFCOMPL%type
  is
  begin
    return GetLotRefComplFromTalId(aTaskLinkId, cRETechTalIdLength);
  end GetLotRefComplFromRETechTalId;

  /**
   * function GetGalRefComplFromRETechTalId
   * Description
   *   Permet de retourner la référence complète affaire/tâche selon l'ID d'une opération provenant de RETech
   */
  function GetGalRefComplFromRETechTalId(aTaskLinkId GAL_TASK_LINK.GAL_TASK_LINK_ID%type)
    return FAL_LOT_PROGRESS_FOG.PFG_GAL_REFCOMPL%type
  is
  begin
    return GetGalRefComplFromTalId(aTaskLinkId, cRETechTalIdLength);
  end GetGalRefComplFromRETechTalId;

  /**
   * function GetSeqFromRETechTalId
   * Description
   *   Permet de retourner la séquence d'une opération provenant de RETech selon son ID
   */
  function GetSeqFromRETechTalId(aTaskLinkId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_LOT_PROGRESS_FOG.PFG_SEQ%type
  is
  begin
    return GetSeqFromTalId(aTaskLinkId, cRETechTalIdLength);
  end GetSeqFromRETechTalId;

  /**
   * function GetTimeInWorkUnit
   * Description
   *   Retourne .
   */
  function GetTimeInWorkUnit(aTimeInHours number)
    return number
  is
  begin
    return aTimeInHours * cWorkUnitAdjustment;
  end GetTimeInWorkUnit;

  /**
   * function GetDicOperatorIdFromEmpNumber
   * Description
   *   Retourne le dic opérateur correspondant au numéro de l'employé ou
   *   NULL si rien trouvé.
   */
  function GetDicOperatorIdFromEmpNumber(aEmpNumber HRM_PERSON.EMP_NUMBER%type)
    return DIC_OPERATOR.DIC_OPERATOR_ID%type
  is
    cursor curGetDicOperatorId
    is
      select DIC_OPERATOR_ID
        from HRM_PERSON PER
           , HRM_PERSON_COMPANY PEC
       where PER.EMP_NUMBER = aEmpNumber
         and PEC.HRM_PERSON_ID = PER.HRM_PERSON_ID;

    vResult HRM_PERSON.EMP_NUMBER%type;
  begin
    -- Recherche de l'ID de l'opération
    vResult  := null;

    open curGetDicOperatorId;

    fetch curGetDicOperatorId
     into vResult;

    close curGetDicOperatorId;

    return nvl(vResult, aEmpNumber);
  end GetDicOperatorIdFromEmpNumber;

  /**
   * function GetFacFloorRefFromEmpNumber
   * Description
   *   Retourne le  correspondant au numéro de l'employé ou
   *   NULL si rien trouvé.
   */
  function GetFacFloorRefFromEmpNumber(aEmpNumber HRM_PERSON.EMP_NUMBER%type)
    return FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  is
    cursor curGetFacFloorRefFromEmpNumber
    is
      select FAC_REFERENCE
        from HRM_PERSON PER
           , HRM_PERSON_COMPANY PEC
           , FAL_FACTORY_FLOOR FAC
       where PER.EMP_NUMBER = aEmpNumber
         and PEC.HRM_PERSON_ID = PER.HRM_PERSON_ID
         and FAC.HRM_PERSON_ID = PER.HRM_PERSON_ID;

    vResult FAL_FACTORY_FLOOR.FAC_REFERENCE%type;
  begin
    -- Recherche de l'ID de l'opération
    vResult  := null;

    open curGetFacFloorRefFromEmpNumber;

    fetch curGetFacFloorRefFromEmpNumber
     into vResult;

    close curGetFacFloorRefFromEmpNumber;

    return nvl(GetFactoryFloorRef(vResult), aEmpNumber);
  end GetFacFloorRefFromEmpNumber;

  /**
   * function GetDicOperatorId
   * Description
   *   Retourne le dic opérateur correspondant
   *   NULL si rien trouvé.
   */
  function GetDicOperatorId(aOperator varchar2)
    return DIC_OPERATOR.DIC_OPERATOR_ID%type
  is
  begin
    case cImportOperatorMode
      when omDicOperator then
        return aOperator;
      when omDicOperatorEmpNumer then
        return GetDicOperatorIdFromEmpNumber(aOperator);
      else
        return null;
    end case;
  end GetDicOperatorId;

  /**
   * function GetOperFactoryFloorRef
   * Description
   *   Retourne le dic opérateur correspondant
   *   NULL si rien trouvé.
   */
  function GetOperFactoryFloorRef(aOperator varchar2)
    return FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  is
  begin
    case cImportOperatorMode
      when omFacFloorEmpNumer then
        return GetFacFloorRefFromEmpNumber(aOperator);
      when omFacFloorOperator then
        return aOperator;
      else
        return null;
    end case;
  end GetOperFactoryFloorRef;

  /**
   * function GetFactoryFloorRef
   * Description
   *   Retourne la référence de l'atelier correspondant à la référence
   *   alternative passée en paramètre (d'après le champ spécifié dans la config
   *   FAL_PFG_ALT_FAC_REF_FIELD).
   *   FAC_REFERENCE est utilisé par défaut si la config est vide.
   */
  function GetFactoryFloorRef(aAltFacRef varchar2)
    return FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  is
    vResult FAL_FACTORY_FLOOR.FAC_REFERENCE%type;
  begin
    execute immediate 'select FAC_REFERENCE      ' || '  from FAL_FACTORY_FLOOR  ' || ' where ' || cAltFacRefField || ' = :AltFacRef'
                 into vResult
                using in aAltFacRef;

    return vResult;
  exception
    when no_data_found then
      return aAltFacRef;
  end GetFactoryFloorRef;

  /**
   * procedure InsertProcessTrackRecord
   * Description
   *   Conversion et insertion de la ligne en enregistrement du brouillard
   * @version 2003
   * @author CLG 17.10.2011
   * @lastUpdate
   * @public
   * @param ivInLine          : Ligne à convertir
   * @param ivFunctionName    : Nom de la fonction utilisée pour convertir la ligne importée
   *                            en record à insérer dans la table du brouillard
   */
  procedure InsertProcessTrackRecord(ivInLine in varchar2, ivFunctionName in varchar2)
  is
  begin
    execute immediate 'insert into FAL_LOT_PROGRESS_FOG ' ||
                      '  (PFG_LOT_REFCOMPL ' ||
                      ' , PFG_SEQ ' ||
                      ' , PFG_REF_FACTORY_FLOOR ' ||
                      ' , PFG_RATE_FACTORY_FLOOR ' ||
                      ' , PFG_PROC_CONTROL ' ||
                      ' , PFG_PROC_EXECUTION ' ||
                      ' , PFG_TOOLS1 ' ||
                      ' , PFG_TOOLS2 ' ||
                      ' , PFG_DATE ' ||
                      ' , PFG_DIC_OPERATOR_ID ' ||
                      ' , PFG_DIC_REBUT_ID ' ||
                      ' , PFG_DIC_WORK_TYPE_ID ' ||
                      ' , PFG_PRODUCT_QTY ' ||
                      ' , PFG_PT_REFECT_QTY ' ||
                      ' , PFG_CPT_REJECT_QFY ' ||
                      ' , PFG_ADJUSTING_TIME ' ||
                      ' , PFG_WORK_TIME ' ||
                      ' , PFG_AMOUNT ' ||
                      ' , PFG_APPLY_DATE ' ||
                      ' , PFG_EAN_CODE ' ||
                      ' , PFG_SUP_QTY ' ||
                      ' , PFG_DIC_UNIT_OF_MEASURE_ID ' ||
                      ' , PFG_QTY_REF2_WORK ' ||
                      ' , PFG_PRODUCT_QTY_UOP ' ||
                      ' , PFG_PT_REJECT_QTY_UOP ' ||
                      ' , PFG_CPT_REJECT_QTY_UOP ' ||
                      ' , PFG_LABEL_CONTROL ' ||
                      ' , PFG_LABEL_REJECT ' ||
                      ' , PFG_REF_FACTORY_FLOOR2 ' ||
                      ' , C_PFG_STATUS ' ||
                      ' , PFG_SELECTION ' ||
                      ' , PFG_ERROR_MESSAGE ' ||
                      ' , C_PROGRESS_ORIGIN ' ||
                      ' , PFG_GAL_REFCOMPL ' ||
                      '  ) ' ||
                      ' select * from table(' ||
                      ivFunctionName ||
                      '(:ivInLine) )  '
                using ivInLine;
  end;

  /**
   * procedure ProcessBarcodeData
   * Description
   *   Récupération des données issues de fichiers code barre ou autre par le
   *   système d'échange de données et importation dans le brouillard du suivi
   *   d'avancement
   * @version 2003
   * @author CLG 17.10.2011
   * @lastUpdate
   * @public
   * @param ivExchangeKey          : Clé du système d'échange de données
   * @param ivFunctionName         : Nom de la fonction utilisée pour convertir la ligne importée
   *                                en record à insérer dans la table du brouillard
   * @param ibApplyProgressDaybook : Indique si on applique ou non automatiquement le brouillard
   * @param ivFilter               : Filtre sur les fichiers à importer
   */
  procedure ProcessBarcodeData(
    ivExchangeKey          in varchar2
  , ivFunctionName         in varchar2
  , ibApplyProgressDaybook in boolean default false
  , ivFilter               in varchar2 default '%'
  )
  is
    ltDataFile     pcs.pc_lib_exchange_data_const.t_exchange_data_type;
    lvImportedLine varchar2(4000);
    lbFileImported boolean                                             := false;
  begin
    /* recherche du premier fichier importé */
    ltDataFile  := PCS.PC_MGT_EXCHANGE_DATA_IN.FindFirst(ivExchangeKey, ivFilter);

    while not ltDataFile.EoSearch loop
      /* ouverture du fichier importé */
      PCS.PC_MGT_EXCHANGE_DATA_IN.open(ltDataFile);
      lvImportedLine  := PCS.PC_MGT_EXCHANGE_DATA_IN.get_line(ltDataFile);

      while not ltDataFile.Eof loop
        lbFileImported  := true;
        InsertProcessTrackRecord(lvImportedLine, ivFunctionName);
        lvImportedLine  := PCS.PC_MGT_EXCHANGE_DATA_IN.get_line(ltDataFile);
      end loop;

      /* fermeture du fichier importé */
      PCS.PC_MGT_EXCHANGE_DATA_IN.close(ltDataFile, true, true);
      /* récupération du prochain fichier */
      ltDataFile      := PCS.PC_MGT_EXCHANGE_DATA_IN.FindNext(ltDataFile);
    end loop;

    /* fermeture de la recherche */
    PCS.PC_MGT_EXCHANGE_DATA_IN.FindClose(ltDataFile);

    if     ibApplyProgressDaybook
       and lbFileImported then
      -- Commit des modifications avant l'application du traitement du brouillard
      commit;
      FAL_SUIVI_OPERATION.ApplyDaybook;
    end if;
  exception
    when others then
      raise_application_error(-20000
                            , 'Error in process barcode data (exchange_data_id: ' ||
                              ltDataFile.exchange_data_id ||
                              ', exchange_data_line_id: ' ||
                              ltDataFile.exchange_data_line_id ||
                              ')' ||
                              chr(10) ||
                              DBMS_UTILITY.FORMAT_ERROR_STACK
                             );
  end;

  /**
   * procedure export_data
   * Description
   *   procédure permettant l'envoi des données au système d'échange de données.
   *   Ne pas oublier de faire appel à pcs.PC_I_LIB_SESSION.initsession lors de l'appel de cette procédure.
   * @version 2003
   * @author PYV/CLG
   * @lastUpdate
   * @public
   * @param ivExchangeKey  : Clé du système d'échange de données
   * @param ivFunctionName : Nom de la fonction utilisée pour retourner la table des données à exporter
   */
  procedure export_data(ivExchangeKey in varchar2, ivFunctionName in varchar2)
  is
    cr_dataExport   sys_refcursor;
    lv_sqlStmnt     varchar2(4000);
    lv_exportedline varchar2(4000);
    lrec_DataFile   pcs.pc_lib_exchange_data_const.t_exchange_data_type;
  begin
    lv_sqlStmnt    := 'select exp.* from table (' || ivFunctionName || ') exp';

    open cr_dataExport for lv_sqlStmnt;

    fetch cr_dataExport
     into lv_exportedline;

    if cr_dataExport%found then
      lrec_DataFile  :=
          pcs.pc_mgt_exchange_data_out.open(iv_exchange_system_key   => ivExchangeKey, iv_filename => null, iv_destination_url => null
                                          , iv_file_encoding         => null);

      while cr_dataExport%found loop
        pcs.pc_mgt_exchange_data_out.put_line(lrec_DataFile, lv_exportedline);

        fetch cr_dataExport
         into lv_exportedline;
      end loop;

      pcs.pc_mgt_exchange_data_out.close(lrec_DataFile);
    end if;

    close cr_dataExport;
  end export_data;
end FAL_PFG_ENTRY_SYSTEMS;
