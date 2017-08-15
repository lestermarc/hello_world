--------------------------------------------------------
--  DDL for Package Body COM_PRC_UAC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_PRC_UAC" 
is
  /**
  * procedure StartProcess
  * Description
  *   Point de départ du processus de contrôle UAC. Récuperation des données
  *     au format xml et stockage dans une table temp
  */
  procedure StartProcess(
    iElementID  in number
  , iObject     in PCS.PC_OBJECT.OBJ_NAME%type
  , iContext    in COM_UAC.C_UAC_CONTEXT%type
  , iDicContext in COM_UAC.DIC_UAC_CONTEXT_ID%type
  )
  is
    lXml               xmltype;
    ln_ContextID       COM_UAC.COM_UAC_ID%type;
    lv_ContextFunction COM_UAC.UAC_CONTEXT_FUNCTION%type;
    ln_StartProcess    number;
    lvError            varchar2(4000);
  begin
    ln_StartProcess  := 0;
    ln_ContextID     := COM_LIB_UAC.GetContextID(iObject => iObject, iContext => iContext, iDicContext => iDicContext);

    if ln_ContextID is not null then
      -- Rechercher le type de context + méthode utilisateur de contexte
      select UAC_CONTEXT_FUNCTION
        into lv_ContextFunction
        from COM_UAC
       where COM_UAC_ID = ln_ContextID;

      -- Méthode utilisateur définie
      if lv_ContextFunction is not null then
        lvError          := null;
        ln_StartProcess  :=
          ExecUserFunction(iElementID      => iElementID
                         , iObject         => iObject
                         , iContext        => iContext
                         , iDicContext     => iDicContext
                         , iUserFunction   => lv_ContextFunction
                         , oError          => lvError
                          );

        if lvError is not null then
          ln_StartProcess  := 0;
        end if;
      else
        ln_StartProcess  := 1;
      end if;

      -- Démarrer le processus UAC
      if ln_StartProcess = 1 then
        -- Récuperer les données de l'élément au format xml
        lXml  := GetXmlRecord(iElementID => iElementID, iContext => iContext, iDicContext => iDicContext);
        -- sauvegarder le xml dans une table temp (COM_LIST_ID_TEMP)
        BackupRecord(iElementID => iElementID, iXml => lXml, iObject => iObject, iContext => iContext, iDicContext => iDicContext, iProcessMode => 'OLD');
      end if;
    end if;
  end StartProcess;

  /**
  * procedure BackupRecord
  * Description
  *   Sauvegarde des données au format xml dans une table temp
  */
  procedure BackupRecord(
    iElementID   in number
  , iXml         in xmltype
  , iObject      in PCS.PC_OBJECT.OBJ_NAME%type
  , iContext     in COM_UAC.C_UAC_CONTEXT%type
  , iDicContext  in COM_UAC.DIC_UAC_CONTEXT_ID%type
  , iProcessMode in varchar2 default 'OLD'
  )
  is
  begin
    -- Effacer les données précèdentes lors du démarrage du contrôle UAC
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'UAC'
            and LID_FREE_CHAR_1 = iProcessMode;

    -- Sauvegarder le xml pour l'utiliser dans le contrôle final de l'UAC
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_FREE_NUMBER_1
               , LID_FREE_CHAR_1
               , LID_FREE_CHAR_2
               , LID_FREE_CHAR_3
               , LID_FREE_CHAR_4
               , LID_CLOB
                )
      select INIT_TEMP_ID_SEQ.nextval
           , 'UAC'
           , iElementID
           , iProcessMode
           , iObject
           , iContext
           , iDicContext
           , iXml.GetClobVal()
        from dual;
  end BackupRecord;

  /**
  * function GetXmlRecord
  * Description
  *   Renvoi les données de l'élément au format xml en fonction du contexte UAC
  */
  function GetXmlRecord(iElementID in number, iContext in COM_UAC.C_UAC_CONTEXT%type, iDicContext in COM_UAC.DIC_UAC_CONTEXT_ID%type)
    return xmltype
  is
    lXml             xmltype;
    lv_date_fmt      pcs.pc_lib_nls_parameters.NLS_NAME;
    lv_timestamp_fmt pcs.pc_lib_nls_parameters.NLS_NAME;
  begin
    -- Set du format de date pour la génération xml
    lv_date_fmt       := pcs.pc_lib_nls_parameters.SetDateFormat(ltm_track_utils.GetDefaultDateFormat);
    lv_timestamp_fmt  := pcs.pc_lib_nls_parameters.SetTimestampFormat(ltm_track_utils.GetDefaultDateFormat);

    case iContext
      -- 01 - Produits
    when '01' then
        lXml  := LTM_TRACK_LOG_FUNCTIONS.get_gco_good_xml(iElementID);
      -- 02 - Nomenclatures
    when '02' then
        lXml  := LTM_TRACK_IND_FUNCTIONS.get_pps_good_nomenclature_xml(iElementID);
      -- 03 - Gamme
    when '03' then
        lXml  := LTM_TRACK_IND_FUNCTIONS.get_fal_schedule_plan_xml(iElementID);
      -- 04 - Partenaires commerciaux
    when '04' then
        lXml  := LTM_TRACK_PAC_FUNCTIONS.get_pac_person_xml(iElementID);
      -- 05 - Statuts qualité
    when '05' then
        lXml  := LTM_TRACK_LOG_FUNCTIONS.get_gco_quality_status_xml(iElementID);
      -- 06 - Détail de caractérisation
    when '06' then
        lXml  := LTM_TRACK_LOG_FUNCTIONS.get_stm_element_number_xml(iElementID);
      -- 07 - Emplacement de stock
    when '07' then
        lXml  := LTM_TRACK_LOG_FUNCTIONS.get_stm_location_xml(iElementID);
      -- 08 - Flux qualité
    when '08' then
        lXml  := LTM_TRACK_LOG_FUNCTIONS.get_gco_quality_stat_flow_xml(iElementID);
      else
        null;
    end case;

    -- Remettre le format des dates original
    if (lv_date_fmt is not null) then
      lv_date_fmt  := pcs.pc_lib_nls_parameters.SetDateFormat(lv_date_fmt);
    end if;

    if (lv_timestamp_fmt is not null) then
      lv_timestamp_fmt  := pcs.pc_lib_nls_parameters.SetTimestampFormat(lv_timestamp_fmt);
    end if;

    return lXml;
  end GetXmlRecord;

  function GetXmlRecord_Autonomus(iElementID in number, iContext in COM_UAC.C_UAC_CONTEXT%type, iDicContext in COM_UAC.DIC_UAC_CONTEXT_ID%type)
    return xmltype
  is
    pragma autonomous_transaction;
  begin
    return GetXmlRecord(iElementID => iElementID, iContext => iContext, iDicContext => iDicContext);
  end GetXmlRecord_Autonomus;

  /**
  * function GenerateDifferences
  * Description
  *   Compare 2 éléments UAC et rempli la table COM_UAC_DIFF avec les differences
  */
  function GenerateDifferences(iClob1 in clob, iClob2 in clob)
    return number
  is
    lResult         number(12)     default 0;
    ln_count        integer;
    ln_parent_index number;
    ln_index        number;
    ln_table_id     number;
    lv_table        varchar2(4000);
    lv_field        varchar2(4000);
    lv_value        varchar2(4000);
    lv_mode         varchar2(4000);
    lv_type         varchar2(4000);
  begin
    -- Compteur de differences
    ln_count  := 0;
    -- 1° élément à comparer
    lResult   := PCS_JAVA.PC_XML_DIFFGEN.SetFirstDocument(iClob1);

    if lResult = 0 then
      RA('ERROR on generate differences, process : ' || 'SetFirstDocument');
    end if;

    -- 2° élément à comparer
    lResult   := PCS_JAVA.PC_XML_DIFFGEN.SetSecondDocument(iClob2);

    if lResult = 0 then
      RA('ERROR on generate differences, process : ' || 'SetSecondDocument');
    end if;

    -- Exécution de l'évaluation des deux documents.
    lResult   := PCS_JAVA.PC_XML_DIFFGEN.execute;

    if lResult <> PCS_JAVA.PC_XML_DIFFGEN.ERROR_NONE then
      RA('ERROR on generate differences, process : ' || 'Execute');
    end if;

    --
    if PCS_JAVA.PC_XML_DIFFGEN.HasDifferences > 0 then
      lResult  := PCS_JAVA.PC_XML_DIFFGEN.GenerateDifferences;

      if lResult <> PCS_JAVA.PC_XML_DIFFGEN.ERROR_NONE then
        RA('ERROR on generate differences, process : ' || 'GenerateDifferences');
      end if;

      -- Balayer la liste des différences et stockage dans table temp
      if (PCS_JAVA.PC_XML_DIFFGEN.FindFirstDiff(ln_parent_index, ln_index, ln_table_id, lv_table, lv_field, lv_value, lv_mode, lv_type) > 0) then
        loop
          -- Ne pas considèrer les champs A_IDMOD et A_DATEMOD
          if     (lv_type = 'FIELD')
             and (lv_field not in('A_IDMOD', 'A_DATEMOD') ) then
            ln_count  := ln_count + 1;

            -- Stockage de la diff dans table temp (pour contrôle utilisateur)
            insert into COM_UAC_DIFF
                        (COM_UAC_DIFF_ID
                       , CUD_TABLE_NAME
                       , CUD_FIELD_NAME
                       , CUD_FIELD_VALUE
                        )
              select INIT_TEMP_ID_SEQ.nextval
                   , lv_table
                   , lv_field
                   , substr(lv_value, 1, 4000)
                from dual;
          end if;

          exit when PCS_JAVA.PC_XML_DIFFGEN.FindNextDiff(ln_parent_index, ln_index, ln_table_id, lv_table, lv_field, lv_value, lv_mode, lv_type) = 0;
        end loop;
      end if;
    end if;

    return ln_Count;
  end GenerateDifferences;

  /**
  * function ExecUserFunction
  * Description
  *   Execution de la méthode utilisateur
  */
  function ExecUserFunction(
    iElementID    in     number
  , iObject       in     PCS.PC_OBJECT.OBJ_NAME%type
  , iContext      in     COM_UAC.C_UAC_CONTEXT%type
  , iDicContext   in     COM_UAC.DIC_UAC_CONTEXT_ID%type
  , iUserFunction in     varchar2
  , oError        out    varchar2
  )
    return number
  is
    lv_Sql  varchar2(32000);
    lResult number;
    lvError varchar2(4000);
  begin
    lResult  := 0;
    lv_Sql   :=
      'declare                ' ||
      '  vResult number;      ' ||
      'begin                  ' ||
      '   :vResult :=         ' ||
      iUserFunction ||
      '(:ID, :OBJ_NAME, :C_UAC_CONTEXT, :DIC_UAC_CONTEXT_ID); ' ||
      'exception              ' ||
      '  when others then     ' ||
      '    :vError := sqlerrm;' ||
      'end;                   ';

    execute immediate lv_Sql
                using out lResult, in iElementID, in iObject, in iContext, in iDicContext, out lvError;

    if lvError is not null then
      --ra('Exception ' || lvError || ' in ' || iUserFunction);
      oError  := 'Exception ' || lvError || ' in ' || iUserFunction;
    end if;

    return lResult;
  end ExecUserFunction;

  /**
  * function ControlUAC
  * Description
  *   Contrôle final de l'UAC sans tenir compte des erreurs.
  */
  function ControlUAC(
    iElementID    in number
  , iValidContext in PCS.PC_VALIDATION.C_CONTEXT_TYPE%type
  , iContext      in COM_UAC.C_UAC_CONTEXT%type
  , iDicContext   in COM_UAC.DIC_UAC_CONTEXT_ID%type default null
  )
    return PCS.PC_CTRL_VALIDATE.ErrorType
  is
    lReturn PCS.PC_CTRL_VALIDATE.ErrorType;
    lvError varchar2(4000);
  begin
    lReturn  := ControlUAC(iElementID => iElementID, iValidContext => iValidContext, iContext => iContext, iDicContext => iDicContext, oError => lvError);
    return lReturn;
  end ControlUAC;

  /**
  * function ControlUAC
  * Description
  *   Contrôle final de l'UAC
  */
  function ControlUAC(
    iElementID    in     number
  , iValidContext in     PCS.PC_VALIDATION.C_CONTEXT_TYPE%type
  , iContext      in     COM_UAC.C_UAC_CONTEXT%type
  , iDicContext   in     COM_UAC.DIC_UAC_CONTEXT_ID%type default null
  , oError        out    varchar2
  )
    return PCS.PC_CTRL_VALIDATE.ErrorType
  is
    lReturn            PCS.PC_CTRL_VALIDATE.ErrorType;
    lClob1             clob;
    lClob2             clob;
    ln_DiffCount       integer;
    lv_ContextFunction COM_UAC.UAC_CONTEXT_FUNCTION%type;
    lv_DiffFunction    COM_UAC.UAC_DIFF_FUNCTION%type;
    lObjectID          PCS.PC_OBJECT.PC_OBJECT_ID%type;
    lContextID         COM_UAC.COM_UAC_ID%type;
    lContextLinkID     COM_UAC_LINK_OBJ.COM_UAC_LINK_OBJ_ID%type;
    vCount             integer;
    lXml               xmltype;
    ln_Result          number;
    ln_StartProcess    number;
    lv_ObjName         PCS.PC_OBJECT.OBJ_NAME%type;
    lvError            varchar2(4000);
  begin
    lReturn          := PCS.PC_CTRL_VALIDATE.E_SUCCESS;
    ln_StartProcess  := 1;
    -- Rechercher l'objet de gestion courant
    lv_ObjName       := PCS.PC_I_LIB_SESSION.GetObjectName;
    -- Résoudre les ids
    COM_LIB_UAC.GetContextLinkID(iObject          => lv_ObjName
                               , iContext         => iContext
                               , iDicContext      => iDicContext
                               , oObjectID        => lObjectID
                               , oContextID       => lContextID
                               , oContextLinkID   => lContextLinkID
                                );

    -- Lien entre l'objet et le contexte identifié
    if lContextLinkID is not null then
      -- Rechercher méthode utilisateur de contôle de contexte
      -- Rechercher méthode utilisateur de contôle des différences
      select UAC_CONTEXT_FUNCTION
           , UAC_DIFF_FUNCTION
        into lv_ContextFunction
           , lv_DiffFunction
        from COM_UAC
       where COM_UAC_ID = lContextID;

      -- Méthode utilisateur de contrôle de contexte
      if lv_ContextFunction is not null then
        lvError          := null;
        ln_StartProcess  :=
          ExecUserFunction(iElementID      => iElementID
                         , iObject         => lv_ObjName
                         , iContext        => iContext
                         , iDicContext     => iDicContext
                         , iUserFunction   => lv_ContextFunction
                         , oError          => lvError
                          );

        if lvError is not null then
          -- Si une exception s'est produite dans la fonction de demande de contrôle de validation, on interrompt le processus
          lReturn          := PCS.PC_CTRL_VALIDATE.E_FATAL;
          ln_StartProcess  := 0;
          oError           := lvError;
        end if;
      end if;

      -- Processus UAC déclenché
      if ln_StartProcess = 1 then
        -- Effacer les données de la table temp de différences
        delete from COM_UAC_DIFF;

        -- Reprendre les anciennes données l'élément
        lXml    := GetXmlRecord_Autonomus(iElementID => iElementID, iContext => iContext, iDicContext => iDicContext);
        BackupRecord(iElementID => iElementID, iXml => lXml, iObject => lv_ObjName, iContext => iContext, iDicContext => iDicContext, iProcessMode => 'OLD');
        lClob1  := lXml.GetClobVal();
        -- Générer le xml des nouvelles données de l'élément
        lXml    := GetXmlRecord(iElementID => iElementID, iContext => iContext, iDicContext => iDicContext);
        -- Stockage des nouvelles données dans une table temp
        BackupRecord(iElementID => iElementID, iXml => lXml, iObject => lv_ObjName, iContext => iContext, iDicContext => iDicContext, iProcessMode => 'NEW');
        lClob2  := lXml.GetClobVal();

        -- En mode UPDATE, identifier les differences entre AVANT et APRES
        if iValidContext = 'UPDATE' then
          -- Identifier les differences et stocker celles-ci si existantes
          if     (lClob1 is not null)
             and (lClob2 is not null) then
            ln_DiffCount  := GenerateDifferences(iClob1 => lClob1, iClob2 => lClob2);
          else
            ln_DiffCount  := 1;
          end if;
        else
          -- Insertion ou Effacement - indiquer un nbr de diff pour que le
          -- contrôle UAC se fassse
          ln_DiffCount  := 1;
        end if;

        -- Données modifiées
        if (ln_DiffCount > 0) then
          -- Méthode utilisateur de contrôle des différences
          if lv_DiffFunction is not null then
            -- Execution fonction utilisateur de contrôle
            lvError    := null;
            ln_Result  :=
              ExecUserFunction(iElementID      => iElementID
                             , iObject         => lv_ObjName
                             , iContext        => iContext
                             , iDicContext     => iDicContext
                             , iUserFunction   => lv_DiffFunction
                             , oError          => lvError
                              );

            if lvError is not null then
              -- Si une exception s'est produite dans la fonction de contrôle des différences, on interrompt le processus
              oError  := lvError;
              return PCS.PC_CTRL_VALIDATE.E_FATAL;
            end if;

            -- Retour  1 : Demande la validation UAC
            if ln_Result = 1 then
              lReturn  := PCS.PC_CTRL_VALIDATE.E_UAC;
            else
              -- Retour  Valeur : autre - PAS de validation UAC
              lReturn  := PCS.PC_CTRL_VALIDATE.E_SUCCESS;
            end if;
          else
            lReturn  := PCS.PC_CTRL_VALIDATE.E_UAC;
          end if;
        end if;
      end if;
    end if;

    return lReturn;
  end ControlUAC;

  /**
  * function CreateCtxValidation
  * Description
  *   Création du contrôle de validation UAC en fonction du contexte et objet
  */
  function CreateCtxValidation(
    iObjectID    in PCS.PC_OBJECT.PC_OBJECT_ID%type
  , iContextID   in COM_UAC.COM_UAC_ID%type
  , iContextType in PCS.PC_VALIDATION.C_CONTEXT_TYPE%type
  )
    return PCS.PC_VALIDATION.PC_VALIDATION_ID%type
  is
    l_ValidID       PCS.PC_VALIDATION.PC_VALIDATION_ID%type;
    lv_ObjName      PCS.PC_OBJECT.OBJ_NAME%type;
    lv_Context      COM_UAC.C_UAC_CONTEXT%type;
    lv_DicContext   COM_UAC.DIC_UAC_CONTEXT_ID%type;
    lv_CtxDescr     V_COM_CPY_PCS_CODES.GCDTEXT1%type;
    lv_CtxTypeDescr V_COM_CPY_PCS_CODES.GCDTEXT1%type;
    lv_Seq          PCS.PC_VALIDATION.VAL_SEQUENCE%type;
    lv_Sql          PCS.PC_VALIDATION.VAL_SQL%type;
  begin
    l_ValidID  := INIT_ID_SEQ.nextval;

    -- Recherche le nom de l'objet
    select OBJ_NAME
      into lv_ObjName
      from PCS.PC_OBJECT
     where PC_OBJECT_ID = iObjectID;

    -- Récuperer le contexte
    select C_UAC_CONTEXT
         , DIC_UAC_CONTEXT_ID
         , COM_FUNCTIONS.GetDescodeDescr('C_UAC_CONTEXT', C_UAC_CONTEXT)
         , COM_FUNCTIONS.GetDescodeDescr('C_CONTEXT_TYPE', iContextType)
      into lv_Context
         , lv_DicContext
         , lv_CtxDescr
         , lv_CtxTypeDescr
      from COM_UAC
     where COM_UAC_ID = iContextID;

    -- Rechercher la séquence max pour le même type de contrôle de validation
    select nvl(max(VAL_SEQUENCE), 0)
      into lv_Seq
      from PCS.PC_VALIDATION
     where PC_OBJECT_ID = iObjectID
       and C_TRANSACTION_TYPE = 'COMMIT'
       and C_EXECUTE_TYPE = 'BEFORE'
       and C_CONTEXT_TYPE = iContextType;

    -- Définition du code sql de la validation
    lv_Sql     :=
      'begin ' ||
      chr(10) ||
      '  Result := [CO].COM_PRC_UAC.ControlUAC(Main_Id ' ||
      chr(10) ||
      '                                      , Context ' ||
      chr(10) ||
      '                                      , ' ||
      '''' ||
      lv_Context ||
      '''' ||
      chr(10) ||
      '                                      , ' ||
      '''' ||
      lv_DicContext ||
      '''' ||
      chr(10) ||
      '                                      , Message ' ||
      chr(10) ||
      '                                        ); ' ||
      chr(10) ||
      'end;  ';

    -- Création de la validation
    insert into PCS.PC_VALIDATION
                (PC_VALIDATION_ID
               , PC_OBJECT_ID
               , PC_TABLE_ID
               , C_TRANSACTION_TYPE
               , C_EXECUTE_TYPE
               , C_CONTEXT_TYPE
               , VAL_SEQUENCE
               , VAL_DESCR
               , VAL_SQL
               , VAL_ACTIVE
               , VAL_COMMENT
               , A_DATECRE
               , A_IDCRE
                )
      select l_ValidID as PC_VALIDATION_ID
           , iObjectID as PC_OBJECT_ID
           , null as PC_TABLE_ID
           , 'COMMIT' as C_TRANSACTION_TYPE
           , 'BEFORE' as C_EXECUTE_TYPE
           , iContextType as C_CONTEXT_TYPE
           , lv_Seq + 1 VAL_SEQUENCE
           , 'UAC - ' || lv_CtxDescr || ' - ' || lv_CtxTypeDescr as VAL_DESCR
           , lv_Sql as VAL_SQL
           , 1 as VAL_ACTIVE
           , 'UAC - ' || lv_CtxDescr || ' - ' || lv_CtxTypeDescr || ' - ' || PCS.PC_I_LIB_SESSION.GetComName as VAL_COMMENT
           , sysdate as A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
        from dual;

    return l_ValidID;
  end CreateCtxValidation;

  /**
  * function CreateLinkObj
  * Description
  *   Création d'un lien UAC objet de gestion
  */
  function CreateLinkObj(iObjectID in PCS.PC_OBJECT.PC_OBJECT_ID%type, iContextID in COM_UAC.COM_UAC_ID%type)
    return COM_UAC_LINK_OBJ.COM_UAC_LINK_OBJ_ID%type
  is
    l_Valid_Ins_ID PCS.PC_VALIDATION.PC_VALIDATION_ID%type     default null;
    l_Valid_Upd_ID PCS.PC_VALIDATION.PC_VALIDATION_ID%type     default null;
    l_Valid_Del_ID PCS.PC_VALIDATION.PC_VALIDATION_ID%type     default null;
    l_LinkID       COM_UAC_LINK_OBJ.COM_UAC_LINK_OBJ_ID%type;
    l_Insert       number;
    l_Update       number;
    l_Delete       number;
  begin
    -- Rechercher les processus qui sont gérés
    select UAC_PROCESS_INSERT
         , UAC_PROCESS_UPDATE
         , UAC_PROCESS_DELETE
      into l_Insert
         , l_Update
         , l_Delete
      from COM_UAC
     where COM_UAC_ID = iContextID;

    -- Création du contrôle de validation UAC en fonction du contexte et objet
    -- Insertion
    if l_Insert = 1 then
      l_Valid_Ins_ID  := CreateCtxValidation(iObjectID => iObjectID, iContextID => iContextID, iContextType => 'INSERT');
    end if;

    -- Modification
    if l_Update = 1 then
      l_Valid_Upd_ID  := CreateCtxValidation(iObjectID => iObjectID, iContextID => iContextID, iContextType => 'UPDATE');
    end if;

    -- Effacement
    if l_Delete = 1 then
      l_Valid_Del_ID  := CreateCtxValidation(iObjectID => iObjectID, iContextID => iContextID, iContextType => 'DELETE');
    end if;

    l_LinkID  := INIT_ID_SEQ.nextval;

    -- Création du lient UAC objet de gestion
    insert into COM_UAC_LINK_OBJ
                (COM_UAC_LINK_OBJ_ID
               , COM_UAC_ID
               , PC_OBJECT_ID
               , PC_VALIDATION_INS_ID
               , PC_VALIDATION_UPD_ID
               , PC_VALIDATION_DEL_ID
               , A_DATECRE
               , A_IDCRE
                )
      select l_LinkID as COM_UAC_LINK_OBJ_ID
           , iContextID as COM_UAC_ID
           , iObjectID as PC_OBJECT_ID
           , l_Valid_Ins_ID as PC_VALIDATION_INS_ID
           , l_Valid_Upd_ID as PC_VALIDATION_UPD_ID
           , l_Valid_Del_ID as PC_VALIDATION_DEL_ID
           , sysdate as A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
        from dual;

    return l_LinkID;
  end CreateLinkObj;

  /**
  * procedure DeleteLinkObj
  * Description
  *   Effacement d'un lien UAC objet de gestion
  */
  procedure DeleteLinkObjID(iLinkID in COM_UAC_LINK_OBJ.COM_UAC_LINK_OBJ_ID%type)
  is
    l_Valid_Ins_ID PCS.PC_VALIDATION.PC_VALIDATION_ID%type   default null;
    l_Valid_Upd_ID PCS.PC_VALIDATION.PC_VALIDATION_ID%type   default null;
    l_Valid_Del_ID PCS.PC_VALIDATION.PC_VALIDATION_ID%type   default null;
  begin
    -- Vérifier s'il y a un contrôle de validation lié
    select PC_VALIDATION_INS_ID
         , PC_VALIDATION_UPD_ID
         , PC_VALIDATION_DEL_ID
      into l_Valid_Ins_ID
         , l_Valid_Upd_ID
         , l_Valid_Del_ID
      from COM_UAC_LINK_OBJ
     where COM_UAC_LINK_OBJ_ID = iLinkID;

    -- Effacement du lien
    delete from COM_UAC_LINK_OBJ
          where COM_UAC_LINK_OBJ_ID = iLinkID;

    -- Effacement du contrôle de validation si identifié
    delete from PCS.PC_VALIDATION
          where PC_VALIDATION_ID = l_Valid_Ins_ID;

    delete from PCS.PC_VALIDATION
          where PC_VALIDATION_ID = l_Valid_Upd_ID;

    delete from PCS.PC_VALIDATION
          where PC_VALIDATION_ID = l_Valid_Del_ID;
  end DeleteLinkObjID;

  /**
  * procedure DeleteLinkObj
  * Description
  *   Effacement d'un lien UAC objet de gestion
  */
  procedure DeleteLinkObj(iObjectID in PCS.PC_OBJECT.PC_OBJECT_ID%type, iContextID in COM_UAC.COM_UAC_ID%type)
  is
  begin
    -- Effacer le lien pour l'objet passé en param OU
    -- pour tous les objets du contexte si l'objet est null
    for tplLink in (select COM_UAC_LINK_OBJ_ID
                      from COM_UAC_LINK_OBJ
                     where COM_UAC_ID = iContextID
                       and PC_OBJECT_ID = nvl(iObjectID, PC_OBJECT_ID) ) loop
      -- appeler la méthode d'effacement d'un lien
      DeleteLinkObjID(iLinkID => tplLink.COM_UAC_LINK_OBJ_ID);
    end loop;
  end DeleteLinkObj;

  /**
  * procedure UpdateValidLinkObj
  * Description
  *   Màj des liens des méthodes de validation en fonction des flags sur le contexte
  */
  procedure UpdateValidLinkObj(iContextID in COM_UAC.COM_UAC_ID%type)
  is
    cursor crLink
    is
      select UAC.UAC_PROCESS_INSERT
           , UAC.UAC_PROCESS_UPDATE
           , UAC.UAC_PROCESS_DELETE
           , LNK.PC_OBJECT_ID
           , LNK.PC_VALIDATION_INS_ID
           , LNK.PC_VALIDATION_UPD_ID
           , LNK.PC_VALIDATION_DEL_ID
           , LNK.COM_UAC_LINK_OBJ_ID
        from COM_UAC UAC
           , COM_UAC_LINK_OBJ LNK
       where UAC.COM_UAC_ID = iContextID
         and UAC.COM_UAC_ID = LNK.COM_UAC_ID;

    l_Valid_Ins_ID    PCS.PC_VALIDATION.PC_VALIDATION_ID%type;
    l_Valid_Upd_ID    PCS.PC_VALIDATION.PC_VALIDATION_ID%type;
    l_Valid_Del_ID    PCS.PC_VALIDATION.PC_VALIDATION_ID%type;
    l_UpdateLink      boolean;
    lv_ValidListToDel varchar2(100);
  begin
    -- Pour chaque lien contexte/objet, vérifier la méthode de validation liée
    for tplLink in crLink loop
      l_UpdateLink       := false;
      lv_ValidListToDel  := null;
      l_Valid_Ins_ID     := tplLink.PC_VALIDATION_INS_ID;
      l_Valid_Upd_ID     := tplLink.PC_VALIDATION_UPD_ID;
      l_Valid_Del_ID     := tplLink.PC_VALIDATION_DEL_ID;

      -- Si flag "insertion" coché et pas de méthode de validation liée
      if     (tplLink.UAC_PROCESS_INSERT = 1)
         and (tplLink.PC_VALIDATION_INS_ID is null) then
        -- Création de la méthode de validation
        l_Valid_Ins_ID  := CreateCtxValidation(iObjectID => tplLink.PC_OBJECT_ID, iContextID => iContextID, iContextType => 'INSERT');
        l_UpdateLink    := true;
      end if;

      -- Si flag "modification" coché et pas de méthode de validation liée
      if     (tplLink.UAC_PROCESS_UPDATE = 1)
         and (tplLink.PC_VALIDATION_UPD_ID is null) then
        -- Création de la méthode de validation
        l_Valid_Upd_ID  := CreateCtxValidation(iObjectID => tplLink.PC_OBJECT_ID, iContextID => iContextID, iContextType => 'UPDATE');
        l_UpdateLink    := true;
      end if;

      -- Si flag "effacement" coché et pas de méthode de validation liée
      if     (tplLink.UAC_PROCESS_DELETE = 1)
         and (tplLink.PC_VALIDATION_DEL_ID is null) then
        -- Création de la méthode de validation
        l_Valid_Del_ID  := CreateCtxValidation(iObjectID => tplLink.PC_OBJECT_ID, iContextID => iContextID, iContextType => 'DELETE');
        l_UpdateLink    := true;
      end if;

      -- Si flag "insertion" pas coché et méthode de validation renseignée
      if     (tplLink.UAC_PROCESS_INSERT = 0)
         and (tplLink.PC_VALIDATION_INS_ID is not null) then
        lv_ValidListToDel  := lv_ValidListToDel || tplLink.PC_VALIDATION_INS_ID || ',';
        l_Valid_Ins_ID     := null;
        l_UpdateLink       := true;
      end if;

      -- Si flag "modification" pas coché et méthode de validation renseignée
      if     (tplLink.UAC_PROCESS_UPDATE = 0)
         and (tplLink.PC_VALIDATION_UPD_ID is not null) then
        lv_ValidListToDel  := lv_ValidListToDel || tplLink.PC_VALIDATION_UPD_ID || ',';
        l_Valid_Upd_ID     := null;
        l_UpdateLink       := true;
      end if;

      -- Si flag "effacement" pas coché et méthode de validation renseignée
      if     (tplLink.UAC_PROCESS_DELETE = 0)
         and (tplLink.PC_VALIDATION_DEL_ID is not null) then
        lv_ValidListToDel  := lv_ValidListToDel || tplLink.PC_VALIDATION_DEL_ID || ',';
        l_Valid_Del_ID     := null;
        l_UpdateLink       := true;
      end if;

      -- Màj du lien contexte/objet s'il y a eu des changements
      if l_UpdateLink then
        update COM_UAC_LINK_OBJ
           set PC_VALIDATION_INS_ID = l_Valid_Ins_ID
             , PC_VALIDATION_UPD_ID = l_Valid_Upd_ID
             , PC_VALIDATION_DEL_ID = l_Valid_Del_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where COM_UAC_LINK_OBJ_ID = tplLink.COM_UAC_LINK_OBJ_ID;
      end if;

      -- Effacer les méthodes de validation obsolètes
      if lv_ValidListToDel is not null then
        delete from PCS.PC_VALIDATION
              where instr(lv_ValidListToDel, PC_VALIDATION_ID) > 0;
      end if;
    end loop;
  end UpdateValidLinkObj;

  /**
  * procedure CreateUacLog
  * Description
  *   Création d'un historique de validation UAC
  */
  procedure CreateUacLog(
    iElementID      in number
  , iContextID      in COM_UAC.COM_UAC_ID%type
  , iContextType    in COM_UAC_LOG.C_CONTEXT_TYPE%type
  , iParticipant1ID in COM_UAC_LOG.PC_WFL_PARTICIPANTS1_ID%type
  , iParticipant2ID in COM_UAC_LOG.PC_WFL_PARTICIPANTS2_ID%type
  , iTableName      in varchar2
  , iComment        in varchar2
  )
  is
    l_ClobOld        clob;
    l_ClobNew        clob;
    l_TableID        PCS.PC_TABLE.PC_TABLE_ID%type;
    lv_TableName     PCS.PC_TABLE.TABNAME%type;
    l_Participant1ID COM_UAC_LOG.PC_WFL_PARTICIPANTS1_ID%type;
    lv_UserName1     COM_UAC_LOG.UAC_USERNAME1%type;
    l_Participant2ID COM_UAC_LOG.PC_WFL_PARTICIPANTS2_ID%type;
    lv_UserName2     COM_UAC_LOG.UAC_USERNAME2%type;
  begin
    -- Rechercher le clob contenant le xml avec les anciennes données
    begin
      select LID_CLOB
        into l_ClobOld
        from COM_LIST_ID_TEMP
       where LID_CODE = 'UAC'
         and LID_FREE_NUMBER_1 = iElementID
         and LID_FREE_CHAR_1 = 'OLD';
    exception
      when no_data_found then
        l_ClobOld  := null;
    end;

    -- Rechercher le clob contenant le xml avec les nouvelles données
    begin
      select LID_CLOB
        into l_ClobNew
        from COM_LIST_ID_TEMP
       where LID_CODE = 'UAC'
         and LID_FREE_NUMBER_1 = iElementID
         and LID_FREE_CHAR_1 = 'NEW';
    exception
      when no_data_found then
        l_ClobNew  := null;
    end;

    -- Rechercher le nom du participant 1
    begin
      select WPA.PC_WFL_PARTICIPANTS_ID
           , WPA.WPA_NAME
        into l_Participant1ID
           , lv_UserName1
        from PCS.PC_WFL_PARTICIPANTS WPA
       where WPA.PC_WFL_PARTICIPANTS_ID = iParticipant1ID;
    exception
      when no_data_found then
        l_Participant1ID  := null;
        lv_UserName1      := null;
    end;

    -- Rechercher le nom du participant 2
    begin
      select WPA.PC_WFL_PARTICIPANTS_ID
           , WPA.WPA_NAME
        into l_Participant2ID
           , lv_UserName2
        from PCS.PC_WFL_PARTICIPANTS WPA
       where WPA.PC_WFL_PARTICIPANTS_ID = iParticipant2ID;
    exception
      when no_data_found then
        l_Participant2ID  := null;
        lv_UserName2      := null;
    end;

    -- Rechercher le nom et id de la table indiv si passée en param
    if iTableName is not null then
      begin
        select PC_TABLE_ID
             , TABNAME
          into l_TableID
             , lv_TableName
          from PCS.PC_TABLE
         where TABNAME = iTableName;
      exception
        when no_data_found then
          l_TableID     := null;
          lv_TableName  := null;
      end;
    end if;

    insert into COM_UAC_LOG
                (COM_UAC_LOG_ID
               , PC_OBJECT_ID
               , UAC_OBJ_NAME
               , COM_UAC_ID
               , C_UAC_CONTEXT
               , DIC_UAC_CONTEXT_ID
               , C_CONTEXT_TYPE
               , UAC_ENTITY_ID
               , PC_TABLE_ID
               , UAC_TABLE_NAME
               , PC_WFL_PARTICIPANTS1_ID
               , UAC_USERNAME1
               , PC_WFL_PARTICIPANTS2_ID
               , UAC_USERNAME2
               , UAC_ENTITY_MODIFY
               , UAC_ENTITY_OLD
               , UAC_ENTITY_NEW
               , UAC_COMMENT
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval as COM_UAC_LOG_ID
           , PCS.PC_I_LIB_SESSION.GetObjectId as PC_OBJECT_ID
           , PCS.PC_I_LIB_SESSION.GetObjectName as UAC_OBJ_NAME
           , UAC.COM_UAC_ID as COM_UAC_ID
           , UAC.C_UAC_CONTEXT as C_UAC_CONTEXT
           , UAC.DIC_UAC_CONTEXT_ID as DIC_UAC_CONTEXT_ID
           , iContextType as C_CONTEXT_TYPE
           , iElementID as UAC_ENTITY_ID
           , l_TableID as PC_TABLE_ID
           , lv_TableName as UAC_TABLE_NAME
           , l_Participant1ID as PC_WFL_PARTICIPANTS1_ID
           , lv_UserName1 as UAC_USERNAME1
           , l_Participant2ID as PC_WFL_PARTICIPANTS2_ID
           , lv_UserName2 as UAC_USERNAME2
           , COM_I_LIB_UAC.GetEntityModify(iElementID, UAC.C_UAC_CONTEXT) as UAC_ENTITY_MODIFY
           , l_ClobOld as UAC_ENTITY_OLD
           , l_ClobNew as UAC_ENTITY_NEW
           , iComment
           , sysdate as A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
        from COM_UAC UAC
       where UAC.COM_UAC_ID = iContextID;
  end CreateUacLog;
end COM_PRC_UAC;
