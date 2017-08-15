--------------------------------------------------------
--  DDL for Package Body DOC_EDI_FUNCTION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_FUNCTION" 
is
  procedure SetDocumentId(aDoc_Document_ID in number)
  -- Assignation de l'ID du document
  is
  begin
    vDOC_DOCUMENT_ID  := aDoc_Document_ID;
  end;

  procedure SetEdiTypeId(aDoc_Edi_Type_Id in number)
  -- Assignation de l'ID du transfert
  -- Et recherche du nom du transfert
  is
  begin
    vDOC_EDI_TYPE_ID  := aDOC_Edi_Type_Id;

    --
    select DET_NAME
      into vDET_NAME
      from DOC_EDI_TYPE
     where DOC_EDI_TYPE_ID = vDOC_EDI_TYPE_ID;
  end;

  function GetDocumentID
    return number
  -- Retourne l'ID du document
  is
  begin
    return vDOC_DOCUMENT_ID;
  end;

  function GetEdiTypeId
    return number
  -- Retourne l'ID du transfert
  is
  begin
    return vDOC_EDI_TYPE_ID;
  end;

  procedure PutSpecialValue(aDep_Name in varchar2, aDep_Value in varchar2)
  -- Modification de la valeur d'un paramètre.
  -- Le paramètre doit exister
  is
    i DOC_EDI_TYPE_PARAM.DOC_EDI_TYPE_PARAM_ID%type;
  begin
    i  := vParamsTable.first;

    while i is not null loop
      if vParamsTable(i).DEP_NAME = aDep_Name then
        vParamsTable(i).DEP_VALUE  := aDep_Value;
        exit;
      end if;

      i  := vParamsTable.next(i);
    end loop;
  end;

  procedure FillSpecialParams(aJob_ID in number)
  -- Ajout des valeurs dynamiques au paramètres spéciaux
  is
    cursor ReadParams(JobId number)
    is
      select   DEP_NAME
             , DEP_VALUE
          from DOC_EDI_JOB_PARAM
         where DOC_EDI_IMPORT_JOB_ID = JobId
      order by DEP_NAME;

    params ReadParams%rowtype;
  begin
    -- Ouverture du curseur sur les paramètre.
    open ReadParams(aJob_ID);

    -- Recherche premier enregistrement
    fetch ReadParams
     into params;

    -- Pour tous les colis, on met à jour les poids calculés
    while ReadParams%found loop
      PutSpecialValue(params.DEP_NAME, params.DEP_VALUE);

      fetch ReadParams
       into params;
    end loop;

    -- fermeture du curseur
    close ReadParams;
  end;

  procedure FillParamsTable(aDoc_Edi_Type_ID in number)
  -- Remplissage de la table par les paramètres
  is
    cursor ReadParams(DocEdiTypeId number)
    is
      select   DEP.DOC_EDI_TYPE_PARAM_ID
             , DEP.DEP_NAME
             , DEP.DEP_VALUE
          from DOC_EDI_TYPE_PARAM DEP
         where DEP.DOC_EDI_TYPE_ID = DocEdiTypeId
      order by DEP.DEP_NAME;

    params ReadParams%rowtype;
  begin
    -- Suppression ancienne valeur mémorisé (pour accélérer la recherche)
    vLastName   := '';
    vLastValue  := '';
    -- Suppression de la table
    vParamsTable.delete;

    -- Ouverture du curseur sur les paramètre.
    open ReadParams(aDoc_Edi_Type_Id);

    -- Recherche premier enregistrement
    fetch ReadParams
     into params;

    -- Pour tous les colis, on met à jour les poids calculés
    while ReadParams%found loop
      vParamsTable(params.doc_edi_type_param_id).DEP_NAME   := upper(params.DEP_NAME);
      vParamsTable(params.doc_edi_type_param_id).DEP_VALUE  := params.DEP_VALUE;

      fetch ReadParams
       into params;
    end loop;

    -- fermeture du curseur
    close ReadParams;
  end;

  function GetParamValue(aDep_Name in varchar2)
    return varchar2
  -- Retourne la valeur d'un paramètre
  is
    i     DOC_EDI_TYPE_PARAM.DOC_EDI_TYPE_PARAM_ID%type;
    value DOC_EDI_TYPE_PARAM.DEP_VALUE%type;
  begin
    value  := '';

    --
    if upper(aDep_Name) = vLastName then
      value  := vLastValue;
    else
      i  := vParamsTable.first;

      while i is not null loop
        if vParamsTable(i).DEP_NAME = upper(aDep_Name) then
          vLastName   := upper(aDep_Name);
          vLastValue  := vParamsTable(i).DEP_VALUE;
          value       := vLastValue;
          exit;
        end if;

        i  := vParamsTable.next(i);
      end loop;
    end if;

    return value;
  end;

  function GetParamValue(iv_Dep_Name in varchar2, in_doc_edi_type_id doc_edi_type.doc_edi_type_id%type)
    return varchar2
  is
    lv_dep_value doc_edi_type_param.dep_value%type;
  begin
    select max(DEP_VALUE)
      into lv_dep_value
      from DOC_EDI_TYPE_PARAM
     where DOC_EDI_TYPE_ID = in_doc_edi_type_id
       and DEP_NAME = iv_Dep_Name;

    return lv_dep_value;
  end;

  function TestDocument(aDoc_Document_ID in number)
    return boolean
  -- Determine si le document passé en paramètre doit être exporté
  is
  begin
    return false;
  end;

  function TestDocument1(aDoc_Document_ID in number)
    return boolean
  -- Determine si le document passé en paramètre doit être exporté
  is
  begin
    return true;
  end;

  function GETE001CODETVA(aDate1 in date, aDate2 in date, aTaxCodeId in number)
    return varchar2
  -- Determine le code tva à retourner en fonction de deux dates et de l'id tva
  -- Fonction spécifique pour l'export E001
  is
    RateValue number;
  begin
    -- Taux tva
    RateValue  := ACS_FUNCTION.GETVATRATE(aTaxCodeId, to_char(nvl(aDate1, aDate2), 'YYYYMMDD') );

    -- Retourne le code en fonction du taux tva
    if RateValue <= 3 then
      return '1';
    else
      if RateValue <= 8 then
        return '2';
      else
        return '0';
      end if;
    end if;
  end;

  function ExportedEdi
    return integer
  -- Détermine si l'edi en cours à déja été exporté
  is
    strExported varchar2(500);
  begin
    -- Recherche du string des exportations
    select DMT_EDI_EXPORTED
      into strExported
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = vDOC_DOCUMENT_ID;

    -- Formattage avec ;
    strExported  := ';' || strExported || ';';

    -- Recherche nom du transfert dans le string des exportations effectuées
    if instr(upper(strExported),(';' || vDET_NAME || ';') ) > 0 then
      return 1;
    else
      return 0;
    end if;
  end;

  function GetPositionsNumber(aType in varchar2)
    return integer
  is
    result integer;
  begin
    begin
      if aType is null then
        select count(*)
          into result
          from DOC_POSITION
         where DOC_DOCUMENT_ID = vDOC_DOCUMENT_ID;
      else
        select count(*)
          into result
          from DOC_POSITION
         where DOC_DOCUMENT_ID = vDOC_DOCUMENT_ID
           and C_GAUGE_TYPE_POS = aType;
      end if;

      return result;
    --
    exception
      when no_data_found then
        return 0;
    end;
  end;

  procedure GetJob(aJobId in number, aEdiTypeId out number)
  -- Retourne l'id du transfert d'un job
  is
  begin
    select DOC_EDI_TYPE_ID
      into aEdiTypeId
      from DOC_EDI_IMPORT_JOB
     where DOC_EDI_IMPORT_JOB_ID = aJobId;
  --
  exception
    when no_data_found then
      aEdiTypeId  := 0;
  end;

  function ReplaceCtrl(aLine in varchar2)
    return varchar2
  -- Remplace les caractères de controle par des espaces
  is
    strLine varchar2(2000);
  begin
    select replace(replace(replace(aLine, chr(10), ' '), chr(13), ' '), chr(9), ' ')
      into strLine
      from dual;

    --
    return strline;
  end;

  -- Création d'un historique du job
  function InsertJobHisto(aJobId in number, aLogName in varchar2, aStatus in varchar2, aType in varchar2)
    return boolean
  is
    newId DOC_EDI_IMPORT_JOB_HISTO.DOC_EDI_IMPORT_JOB_HISTO_ID%type;
  begin
    -- Nouvel Id
    select Init_id_seq.nextval
      into newId
      from dual;

    -- Insert nouvel historique
    insert into DOC_EDI_IMPORT_JOB_HISTO
                (DOC_EDI_IMPORT_JOB_HISTO_ID
               , DOC_EDI_IMPORT_JOB_ID
               , C_EDI_JOB_STATUS
               , C_JOB_LOG_TYPE
               , DJH_PATH
               , A_DATECRE
               , A_IDCRE
                )
         values (newid
               , aJobId
               , aStatus
               , aType
               , aLogName
               , sysdate
               , pcs.PC_I_LIB_SESSION.GetUserIni
                );

    --
    return true;
  end;
end;
