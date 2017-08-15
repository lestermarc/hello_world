--------------------------------------------------------
--  DDL for Package Body SQM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_FUNCTIONS" 
is
  sqlCommand varchar2(2000);

/*-----------------------------------------------------------------------------------*/
  function GetFirstFitScale(pAxisId in SQM_SCALE.SQM_AXIS_ID%type, pDateDoc in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type, pGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return SQM_SCALE.SQM_SCALE_ID%type
  is
    cursor crFitScale(AxisId in SQM_SCALE.SQM_AXIS_ID%type, DateDoc in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type, GoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select   SCA.SQM_SCALE_ID
          from SQM_SCALE SCA
             , SQM_AXIS SAX
         where SCA.SQM_AXIS_ID = pAxisId
           and SAX.SQM_AXIS_ID = SCA.SQM_AXIS_ID
           and SQM_FUNCTIONS.IsVerified(SAX.PC_SQLST_ID, GoodId) = 1
           and SQM_FUNCTIONS.IsVerified(SCA.PC_SQLST_ID, GoodId) = 1
           and DateDoc >= SCA_STARTING_DATE
           and (   DateDoc <= SCA_ENDING_DATE
                or SCA_ENDING_DATE is null)
      order by SCA.SCA_PRIORITY desc
             , SCA.SCA_STARTING_DATE desc;

    result SQM_SCALE.SQM_SCALE_ID%type;
  begin
    open crFitScale(pAxisId, pDateDoc, pGoodId);

    fetch crFitScale
     into result;

    close crFitScale;

    return result;
  end GetFirstFitScale;

/*-----------------------------------------------------------------------------------*/
  function IsVerified(pSqlstId in PCS.PC_SQLST.PC_SQLST_ID%type, pGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    vScriptBuffer varchar2(32767);
    vCondition    PCS.PC_SQLST.SQLSTMNT%type;
    vLength       integer;
    vResult       number;
  begin
    vResult  := 1;

    if pSqlstId is not null then
      select SQLST.SQLSTMNT
        into vCondition
        from PCS.PC_SQLST SQLST
       where SQLST.PC_SQLST_ID = pSqlstId;

      vLength  := DBMS_LOB.GetLength(vCondition);

      if vLength > 32767 then
        Raise_application_error(-20001, 'PCS - CONDITION script length out of range !');
      end if;

      if     vLength is not null
         and vLength > 0 then
        DBMS_LOB.read(vCondition, vLength, 1, vScriptBuffer);
        -- Elimine la clause SELECT et la clause ORDER BY...
        vScriptBuffer  := substr(vScriptBuffer, instr(upper(vScriptBuffer), 'FROM', 1) );
        vScriptBuffer  := substr(vScriptBuffer, 0, instr(upper(vScriptBuffer), 'ORDER BY', -1) - 2);
        -- Ajout du paramètre :GCO_GOOD_ID
        vScriptBuffer  := 'SELECT' || chr(13) || '  GCO_GOOD.GCO_GOOD_ID ' || chr(13) || vScriptBuffer;

        if instr(upper(vScriptBuffer), 'WHERE') = 0 then
          vScriptBuffer  := vScriptBuffer || chr(13) || ' WHERE ';
        else
          vScriptBuffer  := vScriptBuffer || ' AND ';
        end if;

        vScriptBuffer  := vScriptBuffer || chr(13) || '  GCO_GOOD.GCO_GOOD_ID = ' || pGoodId;

        begin
          execute immediate vScriptBuffer
                       into vResult;
        exception
          when no_data_found then
            vResult  := 0;
          when others then
            Raise_application_error(-20001, 'PCS - Notation Management : Invalid application condition (SCA_CONDITION)!');
        end;
      end if;

      if vResult <> 0 then
        vResult  := 1;
      end if;
    else   -- pas de commande SQL
      vResult  := 1;
    end if;

    return vResult;
  end IsVerified;

/*-----------------------------------------------------------------------------------*/
  function PosPenaltyMngmt(pPosId in SQM_PENALTY.DOC_POSITION_ID%type)
    return number
  is
    vManagement number;
  begin
    select count(*)
      into vManagement
      from SQM_PENALTY SPE
         , DOC_POSITION_DETAIL PDE
     where PDE.DOC_POSITION_ID = pPosId
       and PDE.DOC_POSITION_DETAIL_ID = SPE.DOC_POSITION_DETAIL_ID;

    return vManagement;
  end PosPenaltyMngmt;

/*-----------------------------------------------------------------------------------*/
  function CalcPenalty(pScaleID in SQM_SCALE.SQM_SCALE_ID%type, pAxisValue in SQM_PENALTY.SPE_INIT_VALUE%type)
    return SQM_PENALTY.SPE_CALC_PENALTY%type
  is
    vCalcPenalty number;
    vAxisType    SQM_AXIS.C_AXIS_TYPE%type;
    vInitValue   SQM_SCALE.SCA_INIT_FROM_AXIS%type;
  begin
    -- Type d'axe
    select SAX.C_AXIS_TYPE
         , SCA.SCA_INIT_FROM_AXIS
      into vAxisType
         , vInitValue
      from SQM_AXIS SAX
         , SQM_SCALE SCA
     where SAX.SQM_AXIS_ID = SCA.SQM_AXIS_ID
       and SCA.SQM_SCALE_ID = pScaleID;

    if     vInitValue = 1
       and vAxisType = '2' then
      return pAxisValue;
    else
      -- Recherche de la note correspondant à la valeur de l'axe passée en paramètre
      begin
        if vAxisType = '2' then   -- axe de type Numérique
          select STA.STA_PENALTY
            into vCalcPenalty
            from SQM_SCALE_TABLE STA
           where STA.SQM_SCALE_ID = pScaleID
             and STA.C_SQM_VARIATION_TYPE = decode(sign(pAxisValue), -1, 'NEG', 'POS')
             and abs(pAxisValue) >= STA_VARIATION_FROM
             and (    (    abs(pAxisValue) < STA_VARIATION_TO
                       and STA_VARIATION_TO <> 0)
                  or STA_VARIATION_TO = 0);
        else   -- axe de type Booléen ou Alphanumérique
          select STA.STA_PENALTY
            into vCalcPenalty
            from SQM_SCALE_TABLE STA
               , SQM_AXIS_VALUE AXV
           where STA.SQM_AXIS_VALUE_ID = AXV.SQM_AXIS_VALUE_ID
             and STA.SQM_SCALE_ID = pScaleID
             and AXV.AXV_VALUE = pAxisValue;
        end if;
      exception
        when no_data_found then
          return null;
      end;

      return vCalcPenalty;
    end if;
  end CalcPenalty;

/*-----------------------------------------------------------------------------------*/
  function isScaleUsed(pScaleId in SQM_PENALTY.SQM_SCALE_ID%type)
    return number
  is
    vResult number;
  begin
    -- recherche au niveau des notes
    select count(*)
      into vResult
      from SQM_PENALTY
     where SQM_SCALE_ID = pScaleId;

    if vResult = 0 then
      -- recherche au niveau des détails des audits au statut calculé ou terminé
      select count(*)
        into vResult
        from SQM_AUDIT_DETAIL ADE
           , SQM_AUDIT_QUESTION AQU
           , SQM_AUDIT_CHAPTER ACH
           , SQM_AUDIT AUD
       where ADE.SQM_AUDIT_CHAPTER_ID = ACH.SQM_AUDIT_CHAPTER_ID
         and ADE.SQM_AUDIT_QUESTION_ID = AQU.SQM_AUDIT_QUESTION_ID
         and (   ACH.SQM_SCALE_ID = pScaleId
              or AQU.SQM_SCALE_ID = pScaleId)
         and AUD.SQM_AUDIT_ID = ADE.SQM_AUDIT_ID
         and AUD.C_SQM_AUDIT_STATUS <> '1';
    end if;

    return vResult;
  end isScaleUsed;

/*-----------------------------------------------------------------------------------*/
  function isAxisUsed(pAxisId in SQM_AXIS.SQM_AXIS_ID%type)
    return number
  is
    vResult number;
  begin
    select count(SQM_PENALTY_ID)
      into vResult
      from SQM_PENALTY
     where SQM_AXIS_ID = pAxisId;

    if vResult = 0 then
      select count(SQM_SCALE_ID)
        into vResult
        from SQM_SCALE
       where SQM_AXIS_ID = pAxisId;

      if vResult = 0 then
        return 0;   -- l'axe n'est pas utilisé au niveau des notations
      else
        return 1;   -- l'axe est utilisé au niveau des notations mais pas au niveau des notes
      end if;
    else
      return 2;   -- l'axe est utilisé au niveau des notes
    end if;
  end isAxisUsed;

/*-----------------------------------------------------------------------------------*/
  function isCategUsedDef(pCategId in SQM_EVALUATION_CATEGORY.SQM_EVALUATION_CATEGORY_ID%type)
    return number
  is
    vResult number;
  begin
    select count(SQM_EVALUATION_ID)
      into vResult
      from SQM_EVALUATION
     where SQM_EVALUATION_CATEGORY_ID = pCategId
       and C_SQM_EVALUATION_STATUS in('DEF', 'CAL');

    return vResult;
  end isCategUsedDef;

/*-----------------------------------------------------------------------------------*/
  function isAllPeriodDocConfirm(pEvalId in SQM_EVALUATION.SQM_EVALUATION_ID%type)
    return number
  is
    vResult number;
  begin
    select count(*)
      into vResult
      from SQM_PENALTY SPE
         , SQM_EVALUATION EVA
     where SPE.C_PENALTY_STATUS = 'PROV'
       and EVA.SQM_EVALUATION_ID = pEvalId
       and SPE.SPE_DATE_REFERENCE >= EVA.EVA_STARTING_DATE
       and SPE.SPE_DATE_REFERENCE <= EVA.EVA_ENDING_DATE;

    return vResult;
  end isAllPeriodDocConfirm;

/*-----------------------------------------------------------------------------------*/
  function CalcEvalABC(pEvalId in SQM_EVALUATION.SQM_EVALUATION_ID%type, pFinalPenalty in SQM_RESULT.RES_FINAL_NOTE%type)
    return SQM_EVALUATION_CATEG_DETAIL.EDE_CODE%type
  is
    vResult SQM_EVALUATION_CATEG_DETAIL.EDE_CODE%type;
  begin
    begin
      select DET.EDE_CODE
        into vResult
        from SQM_EVALUATION_CATEG_DETAIL DET
           , SQM_EVALUATION_CATEGORY ECA
           , SQM_EVALUATION EVA
       where EVA.SQM_EVALUATION_ID = pEvalId
         and EVA.SQM_EVALUATION_CATEGORY_ID = ECA.SQM_EVALUATION_CATEGORY_ID
         and DET.SQM_EVALUATION_CATEGORY_ID = ECA.SQM_EVALUATION_CATEGORY_ID
         and nvl(pFinalPenalty, 0) >= DET.EDE_FROM
         and (    (    nvl(pFinalPenalty, 0) < DET.EDE_TO
                   and DET.EDE_TO <> 0)
              or DET.EDE_TO = 0);
    exception
      when no_data_found then
        return null;
    end;

    return vResult;
  end CalcEvalABC;

/*-----------------------------------------------------------------------------------*/
  procedure CanCreateScale(pAxisId in SQM_AXIS.SQM_AXIS_ID%type, pscaleId in sqm_scale.sqm_scale_id%type, pStartingDate in out date)
  is
    vMinDate date;
  begin
    -- Quelque soit la priorité, la date début doit être supérieure à la date de la note la plus récente (pour le même axe)
    select max(SPE.SPE_DATE_REFERENCE)
      into vMinDate
      from SQM_PENALTY SPE
         , SQM_SCALE SCA
     where SPE.SQM_AXIS_ID = pAxisID
       and SCA.SQM_AXIS_ID = SPE.SQM_AXIS_ID
       and (   sca.sqm_scale_id <> pscaleid
            or pscaleid is null);

    if pStartingDate <= vMinDate then
      pStartingDate  := vMinDate;
    else
      pStartingDate  := null;
    end if;
  end CanCreateScale;

/*-----------------------------------------------------------------------------------*/
  function GetLastAcceptedDelay(pDocPosDetId in SQM_PENALTY.DOC_POSITION_DETAIL_ID%type)
    return date
  is
    -- curseur sur les détails de position enfants déjà existants
    cursor crChildPosDet(DocPosDetFather in SQM_PENALTY.DOC_POSITION_DETAIL_ID%type)
    is
      --select   SPE.SPE_EXPECTED_DATE
      select   spe.spe_date_Reference
          from SQM_PENALTY SPE
             , DOC_POSITION_DETAIL PDE_SOURCE
             , DOC_POSITION_DETAIL PDE_TARGET
         where PDE_TARGET.DOC_POSITION_DETAIL_ID = PDE_SOURCE.DOC_DOC_POSITION_DETAIL_ID
           and PDE_SOURCE.DOC_POSITION_DETAIL_ID = SPE.DOC_POSITION_DETAIL_ID
           and PDE_TARGET.DOC_POSITION_DETAIL_ID = DocPosDetFather
      --and SPE.C_SQM_SCALE_TYPE = 'DELAY'
      order by SPE.SPE_DATE_REFERENCE desc;

    result date;
  --SQM_PENALTY.SPE_EXPECTED_DATE%type;
  begin
    -- ouverture du curseur
    open crChildPosDet(pDocPosDetId);

    -- récupération du dernier délai accepté
    fetch crChildPosDet
     into result;

    -- fermeture du curseur
    close crChildPosDet;

    return result;
  end GetLastAcceptedDelay;

/*-----------------------------------------------------------------------------------*/
  procedure DuplicateScale(
    pSrcScaleId   in     SQM_SCALE.SQM_SCALE_id%type
  , pTgetScaleId  out    SQM_SCALE.SQM_SCALE_id%type
  , pAxisId       in     SQM_SCALE.SQM_AXIS_ID%type
  , pPriority     in     SQM_SCALE.SCA_PRIORITY%type
  , pName         in     SQM_SCALE.SCA_NAME%type
  , pStartingDate in     date
  , pEndingDate   in     date
  )
  is
    vCount     number;
    vSrcAxisId SQM_AXIS.SQM_AXIS_ID%type;
  begin
    select count(*)
      into vCount
      from SQM_SCALE
     where SCA_PRIORITY = pPriority
       and SCA_STARTING_DATE = pStartingDate
       and SCA_ENDING_DATE = pEndingDate
       and SQM_AXIS_ID = pAxisId;

    if vCount <> 0 then
      pTgetScaleId  := -1;
    else
      select init_id_seq.nextval
        into pTgetScaleId
        from dual;

      insert into SQM_SCALE
                  (SQM_SCALE_ID
                 , SQM_AXIS_ID
                 , SCA_NAME
                 , SCA_STARTING_DATE
                 , SCA_ENDING_DATE
                 , SCA_PRIORITY
                 , A_DATECRE
                 , A_IDCRE
                  )
        select pTgetScaleId
             , pAxisId
             , pName
             , pStartingDate
             , pEndingDate
             , pPriority
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from SQM_SCALE
         where SQM_SCALE_ID = pSrcScaleId;

      -- si axe identique, copie à l'identique
      select SQM_AXIS_ID
        into vSrcAxisId
        from SQM_SCALE
       where SQM_SCALE_ID = pSrcScaleId;

      if vSrcAxisId = pAxisId then
        insert into SQM_SCALE_TABLE
                    (SQM_SCALE_TABLE_ID
                   , SQM_SCALE_ID
                   , C_SQM_VARIATION_TYPE
                   , STA_VARIATION_FROM
                   , STA_VARIATION_TO
                   , STA_PENALTY
                   , SQM_AXIS_VALUE_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , pTgetScaleId
               , C_SQM_VARIATION_TYPE
               , STA_VARIATION_FROM
               , STA_VARIATION_TO
               , STA_PENALTY
               , SQM_AXIS_VALUE_ID
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from SQM_SCALE_TABLE
           where SQM_SCALE_ID = pSrcScaleId;
      else
        AutoInsertScaleTable(pTgetScaleId, pAxisId);
      end if;
    end if;
  end DuplicateScale;

/*-----------------------------------------------------------------------------------*/
  procedure CanModifyScale(pScaleId in SQM_SCALE.SQM_SCALE_ID%type, pStartingDate in out date, pEndingDate in out date)
  is
    vMinDate date;
    vMaxDate date;
  begin
    select min(SPE_DATE_REFERENCE)
         , max(SPE_DATE_REFERENCE)
      into vMinDate
         , vMaxDate
      from SQM_PENALTY
     where SQM_SCALE_ID = pScaleId;

    if    (pStartingDate > vMinDate)
       or (pEndingDate < vMaxDate) then
      pStartingDate  := vMinDate;
      pEndingDate    := vMaxDate;
    else
      pStartingDate  := null;
      pEndingDate    := null;
    end if;
  end CanModifyScale;

/*-----------------------------------------------------------------------------------*/
  function GetScaleTableId(pPenaltyId in SQM_PENALTY.SQM_PENALTY_ID%type)
    return number
  is
    vScaleTableId SQM_SCALE_TABLE.SQM_SCALE_TABLE_ID%type;
    vType         SQM_AXIS.C_AXIS_TYPE%type;
  begin
    vscaletableid  := 0;
    vType          := '1';

    -- Type d'axe
    select SAX.C_AXIS_TYPE
      into vType
      from SQM_PENALTY SPE
         , SQM_AXIS SAX
     where SAX.SQM_AXIS_ID = SPE.SQM_AXIS_ID
       and SQM_PENALTY_ID = pPenaltyId;

    -- Axe qualité numérique
    if vType = '2' then
      select STA.SQM_SCALE_TABLE_ID
        into vScaleTableId
        from SQM_SCALE_TABLE STA
           , SQM_PENALTY SPE
       where STA.SQM_SCALE_ID = SPE.SQM_SCALE_ID
         and SPE.SQM_PENALTY_ID = pPenaltyId
         and STA.C_SQM_VARIATION_TYPE = decode(sign(to_number(nvl(SPE.SPE_UPDATED_VALUE, SPE.SPE_INIT_VALUE) ) ), -1, 'NEG', 'POS')
         and abs(to_number(nvl(SPE.SPE_UPDATED_VALUE, SPE.SPE_INIT_VALUE) ) ) >= STA.STA_VARIATION_FROM
         and (    (    abs(to_number(nvl(SPE.SPE_UPDATED_VALUE, SPE.SPE_INIT_VALUE) ) ) < STA.STA_VARIATION_TO
                   and STA.STA_VARIATION_TO <> 0)
              or STA.STA_VARIATION_TO = 0
             );
    else   -- Axe qualité booléen ou alphanumérique
      select STA.SQM_SCALE_TABLE_ID
        into vScaleTableId
        from SQM_SCALE_TABLE STA
           , SQM_PENALTY SPE
           , SQM_AXIS_VALUE AXV
       where AXV.SQM_AXIS_VALUE_ID = STA.SQM_AXIS_VALUE_ID
         and STA.SQM_SCALE_ID = SPE.SQM_SCALE_ID
         and SPE.SQM_PENALTY_ID = pPenaltyId
         and AXV.AXV_VALUE = nvl(SPE.SPE_UPDATED_VALUE, SPE.SPE_INIT_VALUE);
    end if;

    return vScaleTableId;
  end GetScaleTableId;

/*-----------------------------------------------------------------------------------*/
  function isMethodUsed(pMethodId in SQM_EVALUATION_METHOD.SQM_EVALUATION_METHOD_ID%type)
    return number
  is
    vResult number;
  begin
    -- recherche si la méthode est utilisée par une évaluation calculée ou terminée
    select count(*)
      into vResult
      from SQM_RESULT
     where SQM_EVALUATION_METHOD_ID = pMethodId;

    if vResult <> 0 then
      vResult  := 1;
    end if;

    return vResult;
  end isMethodUsed;

/*-----------------------------------------------------------------------------------*/
  procedure AutoInsertScaleTable(pScaleId in SQM_SCALE.SQM_SCALE_ID%type, pAxisId in SQM_SCALE.SQM_AXIS_ID%type)
  is
    cAxisType SQM_AXIS.C_AXIS_TYPE%type;
  begin
    -- recherche du type d'axe qualité
    select C_AXIS_TYPE
      into cAxisType
      from SQM_AXIS
     where SQM_AXIS_ID = pAxisId;

    -- Suppression des anciennes valeurs de la tabelle
    delete from SQM_SCALE_TABLE
          where SQM_SCALE_ID = pScaleId;

    -- Axe de type booléen ou alphanumérique
    if    cAxisType = '1'
       or cAxisType = '3' then
      -- Insertion des valeurs discrètes de l'axe
      insert into SQM_SCALE_TABLE
                  (SQM_SCALE_TABLE_ID
                 , SQM_SCALE_ID
                 , STA_PENALTY
                 , SQM_AXIS_VALUE_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select init_id_seq.nextval
             , pScaleId
             , 0.0
             , SQM_AXIS_VALUE_ID
             , A_DATECRE
             , A_IDCRE
          from SQM_AXIS_VALUE
         where SQM_AXIS_ID = pAxisId;
    end if;
  -- Initialisation de la condition d'application de la méthode avec celle de l'axe qualité
  end AutoInsertScaleTable;

/*-----------------------------------------------------------------------------------*/
  function PosDetailPenaltyMngmt(pPosId in SQM_PENALTY.DOC_POSITION_ID%type)
    return number
  is
  begin
    return null;
  end;

/*--------------------------------------------------------------------------------------------------------------------*/
  function GetEvent(pResultId in SQM_RESULT.SQM_RESULT_ID%type, pCategId in SQM_EVALUATION_CATEGORY.SQM_EVALUATION_CATEGORY_ID%type)
    return SQM_EVENT.EVE_FUNCTION%type
  is
    vResult SQM_EVENT.EVE_FUNCTION%type;
  begin
    select EVE.EVE_FUNCTION
      into vResult
      from SQM_EVALUATION_CATEG_DETAIL DET
         , SQM_RESULT RES
         , SQM_EVALUATION_CATEGORY ECA
         , SQM_EVENT EVE
     where DET.SQM_EVALUATION_CATEGORY_ID = ECA.SQM_EVALUATION_CATEGORY_ID
       and DET.SQM_EVENT_ID = EVE.SQM_EVENT_ID
       and RES_FINAL_EVALUATION = DET.EDE_CODE
       and nvl(RES.RES_FINAL_NOTE, 0) >= DET.EDE_FROM
       and (    (    nvl(RES.RES_FINAL_NOTE, 0) < DET.EDE_TO
                 and DET.EDE_TO <> 0)
            or DET.EDE_TO = 0)
       and RES.SQM_RESULT_ID = pResultID
       and ECA.SQM_EVALUATION_CATEGORY_ID = pCategId;

    return vResult;
  end GetEvent;

/*--------------------------------------------------------------------------------------------------------------------*/
  function IsPenaltyUsed(pPenaltyId in SQM_PENALTY.SQM_PENALTY_ID%type, pResultID in SQM_RESULT.SQM_RESULT_ID%type)
    return number
  is
    vScriptBuffer varchar2(32767);
    vLength       integer;
    vPenaltyUsed  SQM_PENALTY.SQM_PENALTY_ID%type;
    vScriptSQL    SQM_EVALUATION_METHOD.EME_SCRIPT%type;
    vEvalId       SQM_EVALUATION.SQM_EVALUATION_ID%type;
  begin
    -- Récupération de la commande SQL du résultat
    select EME.EME_SCRIPT
         , RES.SQM_EVALUATION_ID
      into vScriptSQL
         , vEvalId
      from SQM_RESULT RES
         , SQM_EVALUATION_METHOD EME
     where EME.SQM_EVALUATION_METHOD_ID = RES.SQM_EVALUATION_METHOD_ID
       and RES.SQM_RESULT_ID = pResultId;

    vLength  := DBMS_LOB.GetLength(vScriptSQL);

    if vLength > 32767 then
      Raise_application_error(-20001, 'PCS - Script length out of range !');
    end if;

    if     vLength is not null
       and vLength > 0 then
      DBMS_LOB.read(vScriptSQL, vLength, 1, vScriptBuffer);
      vScriptBuffer  := upper(vScriptBuffer);
      -- Elimine la clause SELECT
      vScriptBuffer  := substr(vScriptBuffer, instr(vScriptBuffer, 'FROM', 1) );
      -- Ajout du SELECT
      vScriptBuffer  := 'SELECT' || chr(13) || '  SPE.SQM_PENALTY_ID ' || chr(13) || vScriptBuffer;

      -- Ajout de la condition sur SQM_PENALTY_ID dans la clause WHERE
      if instr(upper(vScriptBuffer), 'WHERE') = 0 then
        vScriptBuffer  := vScriptBuffer || chr(13) || ' WHERE ';
      else
        vScriptBuffer  := vScriptBuffer || ' AND ';
      end if;

      vScriptBuffer  := vScriptBuffer || chr(13) || '  SPE.SQM_PENALTY_ID = ' || pPenaltyId;
      -- Remplacement du paramètre :SQM_EVALUATION_ID
      vScriptBuffer  := replace(vScriptBuffer, ':SQM_EVALUATION_ID', vEvalId);

      execute immediate vScriptBuffer
                   into vPenaltyUsed;
    end if;

    -- Si aucun enregistrement trouvé la fonction retourne 0 sinon elle retourne l'ID de la note
    return nvl(vPenaltyUsed, 0);
  end;
end SQM_FUNCTIONS;
