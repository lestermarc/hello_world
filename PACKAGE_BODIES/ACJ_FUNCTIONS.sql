--------------------------------------------------------
--  DDL for Package Body ACJ_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACJ_FUNCTIONS" 
is
  function GetCharFreeData(
    aTABNAME                  in PCS.PC_TABLE.TABNAME%type
  , aID                       in ACJ_FREE_DATA.ACJ_FREE_DATA_ID%type
  , aDIC_FREE_DATA_WORDING_ID in DIC_FREE_DATA_WORDING.DIC_FREE_DATA_WORDING_ID%type
  )
    return ACJ_FREE_DATA.FDA_CHAR%type
  is
    Code ACJ_FREE_DATA.FDA_CHAR%type;
  begin
    begin
      if aTABNAME = 'ACJ_CATALOGUE_DOCUMENT' then
        select FDA_CHAR
          into Code
          from ACJ_FREE_DATA
         where ACJ_CATALOGUE_DOCUMENT_ID = aID
           and DIC_FREE_DATA_WORDING_ID = aDIC_FREE_DATA_WORDING_ID;
      end if;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetCharFreeData;

  function GetBooleanFreeData(
    aTABNAME                  in PCS.PC_TABLE.TABNAME%type
  , aID                       in ACJ_FREE_DATA.ACJ_FREE_DATA_ID%type
  , aDIC_FREE_DATA_WORDING_ID in DIC_FREE_DATA_WORDING.DIC_FREE_DATA_WORDING_ID%type
  )
    return ACJ_FREE_DATA.FDA_BOOLEAN%type
  is
    Code ACJ_FREE_DATA.FDA_BOOLEAN%type;
  begin
    begin
      if aTABNAME = 'ACJ_CATALOGUE_DOCUMENT' then
        select FDA_BOOLEAN
          into Code
          from ACJ_FREE_DATA
         where ACJ_CATALOGUE_DOCUMENT_ID = aID
           and DIC_FREE_DATA_WORDING_ID = aDIC_FREE_DATA_WORDING_ID;
      end if;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetBooleanFreeData;

  function GetDateFreeData(
    aTABNAME                  in PCS.PC_TABLE.TABNAME%type
  , aID                       in ACJ_FREE_DATA.ACJ_FREE_DATA_ID%type
  , aDIC_FREE_DATA_WORDING_ID in DIC_FREE_DATA_WORDING.DIC_FREE_DATA_WORDING_ID%type
  )
    return ACJ_FREE_DATA.FDA_DATE%type
  is
    Code ACJ_FREE_DATA.FDA_DATE%type;
  begin
    begin
      if aTABNAME = 'ACJ_CATALOGUE_DOCUMENT' then
        select FDA_DATE
          into Code
          from ACJ_FREE_DATA
         where ACJ_CATALOGUE_DOCUMENT_ID = aID
           and DIC_FREE_DATA_WORDING_ID = aDIC_FREE_DATA_WORDING_ID;
      end if;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetDateFreeData;

  function GetNumberFreeData(
    aTABNAME                  in PCS.PC_TABLE.TABNAME%type
  , aID                       in ACJ_FREE_DATA.ACJ_FREE_DATA_ID%type
  , aDIC_FREE_DATA_WORDING_ID in DIC_FREE_DATA_WORDING.DIC_FREE_DATA_WORDING_ID%type
  )
    return ACJ_FREE_DATA.FDA_NUMBER%type
  is
    Code ACJ_FREE_DATA.FDA_NUMBER%type;
  begin
    begin
      if aTABNAME = 'ACJ_CATALOGUE_DOCUMENT' then
        select FDA_NUMBER
          into Code
          from ACJ_FREE_DATA
         where ACJ_CATALOGUE_DOCUMENT_ID = aID
           and DIC_FREE_DATA_WORDING_ID = aDIC_FREE_DATA_WORDING_ID;
      end if;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetNumberFreeData;

  function GetMemoFreeData(
    aTABNAME                  in PCS.PC_TABLE.TABNAME%type
  , aID                       in ACJ_FREE_DATA.ACJ_FREE_DATA_ID%type
  , aDIC_FREE_DATA_WORDING_ID in DIC_FREE_DATA_WORDING.DIC_FREE_DATA_WORDING_ID%type
  )
    return ACJ_FREE_DATA.FDA_MEMO%type
  is
    Code ACJ_FREE_DATA.FDA_MEMO%type;
  begin
    begin
      if aTABNAME = 'ACJ_CATALOGUE_DOCUMENT' then
        select FDA_MEMO
          into Code
          from ACJ_FREE_DATA
         where ACJ_CATALOGUE_DOCUMENT_ID = aID
           and DIC_FREE_DATA_WORDING_ID = aDIC_FREE_DATA_WORDING_ID;
      end if;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetMemoFreeData;

  /**
  * Description
  *       Renvoie la description dans la langue utilisateur de la table ACJ_TRADUCTION selon l'id et
  *       le nom de l'identifiant donné
  */
  function GetDescription(pIdName in varchar2, pIdValue in ACJ_TRADUCTION.ACJ_TRADUCTION_ID%type)
    return ACJ_TRADUCTION.TRA_TEXT%type
  is
    vResult ACJ_TRADUCTION.TRA_TEXT%type;
  begin
    if pIdName = 'ACJ_JOB_TYPE_ID' then
      select nvl(nvl(TRA_TEXT, TYP_DESCRIPTION), '')
        into vResult
        from ACJ_TRADUCTION TRA
           , ACJ_JOB_TYPE TYP
       where TYP.ACJ_JOB_TYPE_ID = pIdValue
         and TYP.ACJ_JOB_TYPE_ID = TRA.ACJ_JOB_TYPE_ID(+)
         and TRA.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId;
    elsif pIdName = 'ACJ_DESCRIPTION_TYPE_ID' then
      select nvl(nvl(TRA_TEXT, DES_DESCR), '')
        into vResult
        from ACJ_TRADUCTION TRA
           , ACJ_DESCRIPTION_TYPE TYP
       where TYP.ACJ_DESCRIPTION_TYPE_ID = pIdValue
         and TYP.ACJ_DESCRIPTION_TYPE_ID = TRA.ACJ_DESCRIPTION_TYPE_ID(+)
         and TRA.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId;
    elsif pIdName = 'ACJ_CATALOGUE_TYPE_ID' then
      select nvl(nvl(TRA_TEXT, MOD_DESCR), '')
        into vResult
        from ACJ_TRADUCTION TRA
           , ACJ_CATALOGUE_TYPE TYP
       where TYP.ACJ_CATALOGUE_TYPE_ID = pIdValue
         and TYP.ACJ_CATALOGUE_TYPE_ID = TRA.ACJ_CATALOGUE_TYPE_ID(+)
         and TRA.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId;
    elsif pIdName = 'ACJ_CATALOGUE_DOCUMENT_ID' then
      select nvl(nvl(TRA_TEXT, CAT_DESCRIPTION), '')
        into vResult
        from ACJ_TRADUCTION TRA
           , ACJ_CATALOGUE_DOCUMENT DOC
       where DOC.ACJ_CATALOGUE_DOCUMENT_ID = pIdValue
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = TRA.ACJ_CATALOGUE_DOCUMENT_ID(+)
         and TRA.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId;
    end if;

    return vResult;
  end GetDescription;

  function GetDescriptionByLangId(
    pIdName  in varchar2
  , pIdValue in ACJ_TRADUCTION.ACJ_TRADUCTION_ID%type
  , pLangId  in ACJ_TRADUCTION.PC_LANG_ID%type
  )
    return ACJ_TRADUCTION.TRA_TEXT%type
  is
    vResult ACJ_TRADUCTION.TRA_TEXT%type;
    vLangId ACJ_TRADUCTION.PC_LANG_ID%type;
  begin
    if pLangId is null then
      vLangId  := PCS.PC_I_LIB_SESSION.GetUserLangId;
    else
      vLangId  := pLangId;
    end if;

    if pIdName = 'ACJ_JOB_TYPE_ID' then
      select nvl(max(TRA_TEXT), max(TYP_DESCRIPTION) )
        into vResult
        from ACJ_TRADUCTION TRA
           , ACJ_JOB_TYPE TYP
       where TYP.ACJ_JOB_TYPE_ID = pIdValue
         and TYP.ACJ_JOB_TYPE_ID = TRA.ACJ_JOB_TYPE_ID(+)
         and TRA.PC_LANG_ID(+) = vLangId;
    elsif pIdName = 'ACJ_DESCRIPTION_TYPE_ID' then
      select nvl(max(TRA_TEXT), max(DES_DESCR) )
        into vResult
        from ACJ_TRADUCTION TRA
           , ACJ_DESCRIPTION_TYPE TYP
       where TYP.ACJ_DESCRIPTION_TYPE_ID = pIdValue
         and TYP.ACJ_DESCRIPTION_TYPE_ID = TRA.ACJ_DESCRIPTION_TYPE_ID(+)
         and TRA.PC_LANG_ID(+) = vLangId;
    elsif pIdName = 'ACJ_CATALOGUE_TYPE_ID' then
      select nvl(max(TRA_TEXT), max(MOD_DESCR) )
        into vResult
        from ACJ_TRADUCTION TRA
           , ACJ_CATALOGUE_TYPE TYP
       where TYP.ACJ_CATALOGUE_TYPE_ID = pIdValue
         and TYP.ACJ_CATALOGUE_TYPE_ID = TRA.ACJ_CATALOGUE_TYPE_ID(+)
         and TRA.PC_LANG_ID(+) = vLangId;
    elsif pIdName = 'ACJ_CATALOGUE_DOCUMENT_ID' then
      select nvl(max(TRA_TEXT), max(CAT_DESCRIPTION) )
        into vResult
        from ACJ_TRADUCTION TRA
           , ACJ_CATALOGUE_DOCUMENT DOC
       where DOC.ACJ_CATALOGUE_DOCUMENT_ID = pIdValue
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = TRA.ACJ_CATALOGUE_DOCUMENT_ID(+)
         and TRA.PC_LANG_ID(+) = vLangId;
    end if;

    return vResult;
  end GetDescriptionByLangId;

  /**
  * Description  Procédure de renumérotation des séquences d'imputations des modèles de transaction
  **/
  procedure CatTypeNumerotation(pCatalogueTypeId in ACJ_IMPUTATION_TYPE.ACJ_CATALOGUE_TYPE_ID%type)
  is
  begin
    begin
      update ACJ_IMPUTATION_TYPE UPD
         set UPD.IMT_SEQUENCE =
               (select   count(*) * 10
                    from ACJ_IMPUTATION_TYPE IMT
                       , ACJ_IMPUTATION_TYPE CPT
                   where IMT.ACJ_CATALOGUE_TYPE_ID = pCatalogueTypeId
                     and CPT.ACJ_CATALOGUE_TYPE_ID = IMT.ACJ_CATALOGUE_TYPE_ID
                     and CPT.IMT_SEQUENCE <= IMT.IMT_SEQUENCE
                     and IMT.IMT_PRIMARY <> 1
                     and UPD.ACJ_IMPUTATION_TYPE_ID = IMT.ACJ_IMPUTATION_TYPE_ID
                group by IMT.IMT_SEQUENCE)
       where UPD.ACJ_CATALOGUE_TYPE_ID = pCatalogueTypeId;
    exception
      when others then
        raise;
    end;
  end CatTypeNumerotation;
  /**
  * Retourne la description du catalogue document donné dans la langue demandée
  **/
  function TranslateCatDescr(
    pCatDocumentId in ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , pLangId        in ACJ_TRADUCTION.PC_LANG_ID%type
  )
    return ACJ_TRADUCTION.TRA_TEXT%type
  is
  begin
    return GetDescriptionByLangId('ACJ_CATALOGUE_DOCUMENT_ID', pCatDocumentId, pLangId);
  end TranslateCatDescr;

  /**
  * Retourne la description du modèle de travaux donné dans la langue demandée
  **/
  function TranslateTypDescr(
    pJobTypeId in ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type
  , pLangId    in ACJ_TRADUCTION.PC_LANG_ID%type
  )
    return ACJ_TRADUCTION.TRA_TEXT%type
  is
  begin
    return GetDescriptionByLangId('ACJ_JOB_TYPE_ID', pJobTypeId, pLangId);
  end TranslateTypDescr;

end ACJ_FUNCTIONS;
