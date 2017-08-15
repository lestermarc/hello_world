--------------------------------------------------------
--  DDL for Package Body GCO_OBS_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_OBS_FUNCTIONS" 
is
--------------------------------------------------------------------------------------------------
  function Get_Extraction_ID(aStageId in number)
    return number
  -- Retourne l'id d'une extraction en fonction de l'id d'une étape
  is
    vExtractId number;
  begin
    select GCO_OBS_EXTRACTION_ID
      into vExtractId
      from GCO_OBS_STAGE
     where GCO_OBS_STAGE_ID = aStageId;

    --
    return vExtractId;
  end;

--------------------------------------------------------------------------------------------------
  function Get_Function_ID(aStageId in number, aSeq in integer)
    return number
  -- Retourne l'id de la fonction d'une étape
  -- Selon la valeur de aSeq, il s'agit de l'id de la première ou seconde fonction
  is
    vFun1 number;
    vFun2 number;
  begin
    select GCO_OBS_FUNCTION_ID
         , GCO_GCO_OBS_FUNCTION_ID
      into vFun1
         , vFun2
      from GCO_OBS_STAGE
     where GCO_OBS_STAGE_ID = aStageId;

    --
    if aSeq = 1 then
      return vFun1;
    else
      return vFun2;
    end if;
  end;

--------------------------------------------------------------------------------------------------
  function Get_String_Param(aStageId in number, aFunctId in number, aName in varchar2)
    return varchar2
  -- Retourne la valeur string d'un paramètre d'étape.
  -- Si le paramètres n'existe pas retourne NULL
  is
    vStringValue varchar2(30);
  begin
    begin
      select GVA_STRING_VALUE
        into vStringValue
        from GCO_OBS_STAGE_PARAM_VALUE VAL
           , GCO_OBS_FUNCTION_PARAM PAR
       where VAL.GCO_OBS_STAGE_ID = aStageId
         and VAL.GCO_OBS_FUNCTION_ID = aFunctId
         and PAR.GCO_OBS_FUNCTION_PARAM_ID = VAL.GCO_OBS_FUNCTION_PARAM_ID
         and PAR.GPA_PARAM_NAME = aName;
    --
    exception
      when no_data_found then
        vStringValue  := null;
    end;

    --
    return vStringValue;
  end;

--------------------------------------------------------------------------------------------------
  function Get_Numeric_Param(aStageId in number, aFunctId in number, aName in varchar2)
    return number
  -- Retourne la valeur numérique d'un paramètre d'étape.
  -- Si le paramètres n'existe pas retourne NULL
  is
    vNumericValue number;
  begin
    begin
      select GVA_NUMERIC_VALUE
        into vNumericValue
        from GCO_OBS_STAGE_PARAM_VALUE VAL
           , GCO_OBS_FUNCTION_PARAM PAR
       where VAL.GCO_OBS_STAGE_ID = aStageId
         and VAL.GCO_OBS_FUNCTION_ID = aFunctId
         and PAR.GCO_OBS_FUNCTION_PARAM_ID = VAL.GCO_OBS_FUNCTION_PARAM_ID
         and PAR.GPA_PARAM_NAME = aName;
    --
    exception
      when no_data_found then
        vNumericValue  := null;
    end;

    --
    return vNumericValue;
  end;

--------------------------------------------------------------------------------------------------
  function Get_Date_Param(aStageId in number, aFunctId in number, aName in varchar2)
    return date
  -- Retourne la valeur date d'un paramètre d'étape.
  -- Si le paramètres n'existe pas retourne NULL
  is
    vDateValue date;
  begin
    begin
      select GVA_DATE_VALUE
        into vDateValue
        from GCO_OBS_STAGE_PARAM_VALUE VAL
           , GCO_OBS_FUNCTION_PARAM PAR
       where VAL.GCO_OBS_STAGE_ID = aStageId
         and VAL.GCO_OBS_FUNCTION_ID = aFunctId
         and PAR.GCO_OBS_FUNCTION_PARAM_ID = VAL.GCO_OBS_FUNCTION_PARAM_ID
         and PAR.GPA_PARAM_NAME = aName;
    --
    exception
      when no_data_found then
        vDateValue  := null;
    end;

    --
    return vDateValue;
  end;

--------------------------------------------------------------------------------------------------
  procedure Delete_Selection_Stage(aStageId in number)
  -- Suppression des tous les enregistrements d'une étape
  is
  begin
    delete      GCO_OBS_SELECTION
          where GCO_OBS_STAGE_ID = aStageId;
  end;

--------------------------------------------------------------------------------------------------
  procedure InsertInStage(aExtractId in number, aStageId in number, aGoodId in number)
  -- Création d'un nouvel enregistrement dans l'étape destination
  is
    newId GCO_OBS_SELECTION.GCO_OBS_SELECTION_ID%type;
  begin
    -- Nouvel Id
    select Init_id_seq.nextval
      into newId
      from dual;

    -- Insert nouvel historique
    insert into GCO_OBS_SELECTION
                (GCO_OBS_SELECTION_ID
               , GCO_OBS_EXTRACTION_ID
               , GCO_OBS_STAGE_ID
               , GCO_GOOD_ID
               , GSE_IS_SELECTED
               , A_DATECRE
               , A_IDCRE
                )
         values (newid
               , aExtractId
               , aStageId
               , aGoodId
               , 1
               , sysdate
               , pcs.PC_I_LIB_SESSION.GetUserIni
                );
  end;

--------------------------------------------------------------------------------------------------
  function BEGIN_Function(aStageId in number)
    return integer
  -- Initialisation des valeurs pour l'étape BEGIN
  is
    vExtractId number;

    --
    cursor ReadGood
    is
      select GCO_GOOD_ID
        from GCO_GOOD;

    params     ReadGood%rowtype;
  begin
    Delete_Selection_Stage(aStageId);
    vExtractId  := Get_Extraction_ID(aStageId);

    -- Ouverture du curseur
    open ReadGood;

    -- Recherche premier enregistrement
    fetch ReadGood
     into params;

    -- Parcours le curseur
    while ReadGood%found loop
      InsertInStage(vExtractId, aStageId, params.GCO_GOOD_ID);

      fetch ReadGood
       into params;
    end loop;

    -- fermeture du curseur
    close ReadGood;

    --
    return 1;
  end;

--------------------------------------------------------------------------------------------------
  function END_Function(aStageId in number, aStageSrceId in number)
    return integer
  -- Copie simplement la source dans la destination
  is
    vExtractId number;

    --
    cursor ReadGood(vSrcId in number)
    is
      select GCO_GOOD_ID
        from GCO_OBS_SELECTION
       where GCO_OBS_STAGE_ID = vSrcId;

    params     ReadGood%rowtype;
  begin
    Delete_Selection_Stage(aStageId);
    vExtractId  := Get_Extraction_ID(aStageId);

    -- Ouverture du curseur
    open ReadGood(aStageSrceId);

    -- Recherche premier enregistrement
    fetch ReadGood
     into params;

    -- Parcours le curseur
    while ReadGood%found loop
      InsertInStage(vExtractId, aStageId, params.GCO_GOOD_ID);

      fetch ReadGood
       into params;
    end loop;

    -- fermeture du curseur
    close ReadGood;

    --
    return 1;
  end;

--------------------------------------------------------------------------------------------------
  function UNION_Function(aStageDestId in number, aStageSrce1Id in number, aStageSrce2Id in number)
    return integer
  -- Fonction donnant les valeurs de source 1 ajoutées de celles de source 2
  is
    vExtractId number;

    --
    cursor ReadGood(vSrc1Id in number, vSrc2Id in number)
    is
      select GCO_GOOD_ID
        from GCO_OBS_SELECTION
       where GCO_OBS_STAGE_ID = vSrc1Id
      union
      select GCO_GOOD_ID
        from GCO_OBS_SELECTION
       where GCO_OBS_STAGE_ID = vSrc2Id;

    params     ReadGood%rowtype;
  begin
    Delete_Selection_Stage(aStageDestId);
    --
    vExtractId  := Get_Extraction_ID(aStageDestId);

    -- Ouverture du curseur
    open ReadGood(aStageSrce1Id, aStageSrce2Id);

    -- Recherche premier enregistrement
    fetch ReadGood
     into params;

    -- Parcours le curseur
    while ReadGood%found loop
      InsertInStage(vExtractId, aStageDestId, params.GCO_GOOD_ID);

      fetch ReadGood
       into params;
    end loop;

    -- fermeture du curseur
    close ReadGood;

    --
    return 1;
  end;

--------------------------------------------------------------------------------------------------
  function MINUS_Function(aStageDestId in number, aStageSrce1Id in number, aStageSrce2Id in number)
    return integer
  -- Fonction donnant les valeurs de source 1 moins source 2
  is
    vExtractId number;

    --
    cursor ReadGood(vSrc1Id in number, vSrc2Id in number)
    is
      select GCO_GOOD_ID
        from GCO_OBS_SELECTION
       where GCO_OBS_STAGE_ID = vSrc1Id
      minus
      select GCO_GOOD_ID
        from GCO_OBS_SELECTION
       where GCO_OBS_STAGE_ID = vSrc2Id;

    params     ReadGood%rowtype;
  begin
    Delete_Selection_Stage(aStageDestId);
    --
    vExtractId  := Get_Extraction_ID(aStageDestId);

    -- Ouverture du curseur
    open ReadGood(aStageSrce1Id, aStageSrce2Id);

    -- Recherche premier enregistrement
    fetch ReadGood
     into params;

    -- Parcours le curseur
    while ReadGood%found loop
      InsertInStage(vExtractId, aStageDestId, params.GCO_GOOD_ID);

      fetch ReadGood
       into params;
    end loop;

    -- fermeture du curseur
    close ReadGood;

    --
    return 1;
  end;

--------------------------------------------------------------------------------------------------
  function INTERSECT_Function(aStageDestId in number, aStageSrce1Id in number, aStageSrce2Id in number)
    return integer
  -- Fonction donnant les valeurs d'intersection entre deux sources
  is
    vExtractId number;

    --
    cursor ReadGood(vSrc1Id in number, vSrc2Id in number)
    is
      select GCO_GOOD_ID
        from GCO_OBS_SELECTION
       where GCO_OBS_STAGE_ID = vSrc1Id
      intersect
      select GCO_GOOD_ID
        from GCO_OBS_SELECTION
       where GCO_OBS_STAGE_ID = vSrc2Id;

    params     ReadGood%rowtype;
  begin
    Delete_Selection_Stage(aStageDestId);
    --
    vExtractId  := Get_Extraction_ID(aStageDestId);

    -- Ouverture du curseur
    open ReadGood(aStageSrce1Id, aStageSrce2Id);

    -- Recherche premier enregistrement
    fetch ReadGood
     into params;

    -- Parcours le curseur
    while ReadGood%found loop
      -- Remplissage de la nouvelle sélection
      InsertInStage(vExtractId, aStageDestId, params.GCO_GOOD_ID);

      fetch ReadGood
       into params;
    end loop;

    -- fermeture du curseur
    close ReadGood;

    --
    return 1;
  end;

--------------------------------------------------------------------------------------------------
  function GET_REFERENCE_PRICE(aStageId in number)
    return integer
  -- Mise à jour du prix de référence dans la sélection de l'étape END
  is
    cursor ReadGood(vSrcId in number)
    is
      select GCO_OBS_SELECTION_ID
        from GCO_OBS_SELECTION
       where GCO_OBS_STAGE_ID = vSrcId;

    params ReadGood%rowtype;
  begin
    -- Ouverture du curseur
    open ReadGood(aStageId);

    -- Recherche premier enregistrement
    fetch ReadGood
     into params;

    -- Parcours le curseur
    while ReadGood%found loop
      update GCO_OBS_SELECTION
         set GSE_REFERENCE_UNIT_PRICE = 1
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
       where GCO_OBS_SELECTION_ID = params.GCO_OBS_SELECTION_ID;

      fetch ReadGood
       into params;
    end loop;

    -- fermeture du curseur
    close ReadGood;

    --
    return 1;
  end;

--------------------------------------------------------------------------------------------------
  function GET_OBSOLETE_PRICE(aStageId in number)
    return integer
  -- Mise à jour du prix obsolete dans la sélection de l'étape END
  is
    cursor ReadGood(vSrcId in number)
    is
      select GCO_OBS_SELECTION_ID
        from GCO_OBS_SELECTION
       where GCO_OBS_STAGE_ID = vSrcId;

    params ReadGood%rowtype;
  begin
    -- Ouverture du curseur
    open ReadGood(aStageId);

    -- Recherche premier enregistrement
    fetch ReadGood
     into params;

    -- Parcours le curseur
    while ReadGood%found loop
      update GCO_OBS_SELECTION
         set GSE_OBSOLETE_UNIT_PRICE = 2
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
       where GCO_OBS_SELECTION_ID = params.GCO_OBS_SELECTION_ID;

      fetch ReadGood
       into params;
    end loop;

    -- fermeture du curseur
    close ReadGood;

    --
    return 1;
  end;

--------------------------------------------------------------------------------------------------
  function END_FINAL_FUNCTION(aStageId in number)
    return integer
  -- Mise à jour du flag obsolete du bien
  is
    result integer;

    cursor ReadSelection(vStageId in number)
    is
      select GCO_GOOD_ID
        from GCO_OBS_SELECTION
       where GCO_OBS_STAGE_ID = vStageId
         and GSE_IS_SELECTED = 1;

    params ReadSelection%rowtype;
  begin
    -- Mise à false (0) tous les flags goo_obsolete des biens
    update GCO_GOOD
       set GOO_OBSOLETE = 0;

    --
    -- Mise à true (1) le flags goo_obsolete
    -- Ouverture du curseur
    open ReadSelection(aStageId);

    -- Recherche premier enregistrement
    fetch ReadSelection
     into params;

    -- Parcours le curseur
    while ReadSelection%found loop
      update GCO_GOOD
         set GOO_OBSOLETE = 1
           , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where GCO_GOOD_ID = Params.GCO_GOOD_ID;

      fetch ReadSelection
       into params;
    end loop;

    -- fermeture du curseur
    close ReadSelection;

    --
    result  := 1;
    return result;
  end;

--------------------------------------------------------------------------------------------------
  function MIN_MAX_TEST(aStageDestId in number, aStageSrceId in number)
    return integer
  -- Fonction test
  is
    vExtractId number;
    vFunctId   number;
    vMin       varchar2(50);
    vMax       varchar2(50);

    --
    cursor ReadGood(vMin in varchar2, vMax in varchar2)
    is
      select GOOD.GCO_GOOD_ID
        from GCO_OBS_SELECTION SEL
           , GCO_GOOD GOOD
       where SEL.GCO_OBS_STAGE_ID = aStageSrceId
         and GOOD.GCO_GOOD_ID = SEL.GCO_GOOD_ID
         and GOOD.GOO_MAJOR_REFERENCE >= vMin
         and GOOD.GOO_MAJOR_REFERENCE <= vMax;

    params     ReadGood%rowtype;
  begin
    Delete_Selection_Stage(aStageDestId);
    --
    vExtractId  := Get_Extraction_ID(aStageDestId);
    --
    vFunctId    := Get_Function_Id(aStageDestId, 1);
    --
    vMin        := Get_String_Param(aStageDestId, vFunctId, 'MIN_ART');
    vMax        := Get_String_Param(aStageDestId, vFunctId, 'MAX_ART');

    -- Ouverture du curseur
    open ReadGood(vMin, vMax);

    -- Recherche premier enregistrement
    fetch ReadGood
     into params;

    -- Parcours le curseur
    while ReadGood%found loop
      InsertInStage(vExtractId, aStageDestId, params.GCO_GOOD_ID);

      fetch ReadGood
       into params;
    end loop;

    -- fermeture du curseur
    close ReadGood;

    --
    return 1;
  end;
--------------------------------------------------------------------------------------------------
end;
