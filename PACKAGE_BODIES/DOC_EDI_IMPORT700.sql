--------------------------------------------------------
--  DDL for Package Body DOC_EDI_IMPORT700
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_IMPORT700" 
as
-- *************************************************
-- *****             GENERAL                   *****
-- *************************************************

  -- Ajout dans le log de traitement
  procedure WriteLog(aLine varchar2, aType_1 integer)
  is
  begin
    DOC_EDI_IMPORT.WRITELOG(aLine, aType_1);
  end;

  -- Affichage d'un message d'information dans le log
  procedure PutMessage(aMessage varchar2)
  is
  begin
    WRITELOG(' ', 10);
    WRITELOG(aMessage, 10);
    WRITELOG(' ', 10);
  end;

  procedure PutError(aMessage varchar2)
  -- Message d'erreur dans le log avec le num�ro de ligne, la ligne, le message avec colone
  -- Le message est reformatt� en fonction de la position
  is
  begin
    LineRec.DID_ERROR_TEXT  := aMessage;
    DOC_EDI_IMPORT.PutError(LineRec.DID_ERROR_TEXT, LineRec.DOC_EDI_IMPORT_JOB_DATA_ID, LineRec.DID_VALUE, LineRec.DID_LINE_NUMBER, LineRec.NEW_ROW_POSITION);
  end;

  -- Mise en nombre une chaine de caract�res
  function PutInNumber(paNumber varchar2, paEnt integer, paDec integer)
    return number
  is
    str9      varchar2(20);
    strFormat varchar2(20);
    strNumber varchar2(20);
  begin
    WRITELOG('*PutInNumber', 0);

    --
    begin
      if paEnt = 0 then
        return to_number(paNumber);
      else
        -- Chaine de base pour formatage
        str9       := '99999999999999999999';
        -- Cr�ation du format
        strFormat  := substr(str9, 1, paEnt) || '.' || substr(str9, 1, paDec);
        -- Nombre transcrit
        strNumber  := substr(paNumber, 1, paEnt) || '.' || substr(paNumber, paEnt + 1, paDec);
        return to_number(strNumber, strFormat);
      end if;
    --
    exception
      when others then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Format d''un nombre incorrect') || ' : ' || paNumber);
        return null;
    end;
  end;

  -- Mise en date une chaine de caract�res
  function PutInDate(paDate varchar2, paFormat varchar2)
    return date
  is
  begin
    WRITELOG('*PutInDate', 0);

    begin
      return to_date(paDate, paFormat);
    --
    exception
      when others then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Format de date incorrect') || ' : ' || paDate || ', ' || paFormat);
        return null;
    end;
  end;

  -- Fonction sumulant une error - Pour test
  function RAISEERROR
    return boolean
  is
  begin
    RAISE_APPLICATION_ERROR(-20001, 'ERREUR PROVOQUEE POUR TEST');
    return false;
  end;

  -- Initialisation de la position de colonne pour la ligne en cours.
  -- Ce num�ro est utilis� en cas d'erreur.
  procedure PutRowPosition(aPos varchar2)
  is
  begin
    LineRec.NEW_ROW_POSITION  := aPos;
  end;

--------------------
-- Initialisation --
--------------------

  -- Initialisation des variables syst�me
  procedure InitVarSys
  is
  begin
    -- IMPORTANT : Pas de WRITELOG car JOB_ID n'est pas initialis�
    SysRec.JOB_ID           := null;
    SysRec.DOC_EDI_TYPE_ID  := null;
    SysRec.RETURN_VALUE     := null;
  end;

  -- Init des variables g�n�rales pour toutes les lignes d'un job
  procedure InitVarJob
  is
  begin
    WRITELOG('*InitVarJob', 0);
    --
    -- Nom du gabarit pour table INTERFACE
    JobRec.GAU_DESCR                 := null;
    -- Pas de document ok
    JobRec.NEW_DOC_OK                := false;
    -- Pas de document en erreur
    JobRec.NEW_DOC_NOT_OK            := false;
    -- Client
    JobRec.INTERM_CUS_EAN_NUMBER     := null;
    JobRec.PAC_THIRD_ID              := null;
    -- Gabarit
    JobRec.INTERM_GAUGE_DESCRIPTION  := null;
    JobRec.DOC_GAUGE_ID              := null;
    --
    JobRec.INTERM_TEST_VALUE         := null;
  end;

  -- Init des variables g�n�rales pour le traiement d'un document d'un job
  procedure InitVarDoc
  is
  begin
    WRITELOG('*InitVarDoc', 0);
    --
    -- Id interface non initialis�
    DocumentRec.DOC_INTERFACE_ID  := null;
    -- Document un ordre
    DocumentRec.NEW_DOC_STOP      := false;
    -- Num�ro du document interface attribu�
    DocumentRec.NEW_DOI_NUMBER    := null;
  end;

  -- Init des variables pour la ligne data en cours
  procedure InitVarLine
  is
  begin
    WRITELOG('*InitVarLine', 0);
    --
    -- Id de la ligne en cours non init.
    LineRec.DOC_EDI_IMPORT_JOB_DATA_ID  := null;
    -- Status par d�faut de la ligne OK
    LineRec.C_EDI_JOB_DATA_STATUS       := 'OK';
    -- Pas d'erreur
    LineRec.DID_ERROR_TEXT              := null;
    -- pas de num�ro de ligne
    LineRec.DID_LINE_NUMBER             := 0;
    -- Pas de ligne
    LineRec.DID_VALUE                   := null;
    -- Num�ro de colonne
    PutRowPosition(null);
  end;

  -- Init des champs du d�tail
  procedure InitFieldsDetail
  is
  begin
    WRITELOG('*InitFieldsDetail', 0);
    --
    -- Id de la position de l'interface
    DetailDocu.DOC_INTERFACE_POSITION_ID  := null;
    -- Type de d�tail
    DetailDocu.C_GAUGE_TYPE_POS           := null;
    --
    -- Qte
    DetailDocu.INTERM_DOP_QTY             := null;
    DetailDocu.DOP_QTY                    := null;
    -- Produit
    DetailDocu.DOP_MAJOR_REFERENCE        := null;
    DetailDocu.GCO_GOOD_ID                := null;
    -- Date de saisie
    DetailDocu.INTERM_DOP_BASIS_DELAY     := null;
    DetailDocu.DOP_BASIS_DELAY            := null;
    -- Chantier - Record
    DetailDocu.INTERM_CHANTIER            := null;
    DetailDocu.DOC_RECORD_ID              := null;
    -- Num�ro de personne (->POS_TEXT_1)
    DetailDocu.INTERM_NO_PERS             := null;
    -- Valeur � tester
    DetailDocu.INTERM_TEST_VALUE          := null;
    --
    -- Copie du gauge du document sur le d�tail
    DetailDocu.DOC_GAUGE_ID               := JobRec.DOC_GAUGE_ID;
  end;

  function ConvertState(paState boolean)
    return integer
  -- Converti l'�tat boolean en integer
  -- True  -> 1
  -- False -> 0
  is
  begin
    if paState then
      return 1;
    else
      return 0;
    end if;
  end;

  procedure PutStatus(paStatus integer)
  -- Mise � jour du statut d'une ligne JOB DATA
  -- 0 -> ERREUR
  -- 1 -> OK
  -- 2 -> WARNING
  -- 3 -> UNDEF
  is
  begin
    WRITELOG('*PutStatus ' || paStatus, 0);

    --
    -- En ordre
    if paStatus = 1 then
      LineRec.C_EDI_JOB_DATA_STATUS  := 'OK';
    -- Erreur
    elsif paStatus = 0 then
      LineRec.C_EDI_JOB_DATA_STATUS  := 'ERROR';
      -- Erreur -> suppression des ajout dans l'interface
      DocumentRec.NEW_DOC_STOP       := true;
    -- Avertissement
    elsif paStatus = 2 then
      LineRec.C_EDI_JOB_DATA_STATUS  := 'WARNING';
    -- Ligne non trait�e
    else
      LineRec.C_EDI_JOB_DATA_STATUS  := 'UNDEF';
    end if;

    --
    -- Mise du status et de message d'erreur du job data en cours
    -- Provient en principe suite � un PutError
    if LineRec.DOC_EDI_IMPORT_JOB_DATA_ID is not null then
      update DOC_EDI_IMPORT_JOB_DATA
         set C_EDI_JOB_DATA_STATUS = LineRec.C_EDI_JOB_DATA_STATUS
           , DID_ERROR_TEXT = LineRec.DID_ERROR_TEXT
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_EDI_IMPORT_JOB_DATA_ID = LineRec.DOC_EDI_IMPORT_JOB_DATA_ID;
    end if;
  end;

  -- Insertion des donn�es dans l'interface document
  procedure InsertInterface
  is
  begin
    begin
      if not DocumentRec.NEW_DOC_STOP then
        WRITELOG('*InsertInterface', 0);
        WRITELOG('*Avant update InsertInterface ' || jobRec.pac_third_id, 0);
        WRITELOG('*Avant update InsertInterface ' || jobRec.gau_descr, 0);
        WRITELOG('*Avant update InsertInterface ' || jobRec.doc_gauge_id, 0);
        -- Cr�ation d'un enregistrement avec valeurs par d�faut
        DOC_INTERFACE_CREATE.CREATE_INTERFACE(JobRec.PAC_THIRD_ID
                                            ,   -- IN Id du client
                                              JobRec.GAU_DESCR
                                            ,   -- IN Nom du gabarit d'initialisation
                                              JobRec.DOC_GAUGE_ID
                                            ,   -- IN Id du gabarit
                                              '201'
                                            ,   -- IN Edi
                                              DocumentRec.NEW_DOI_NUMBER
                                            ,   -- OUT Num�ro d'interface
                                              DocumentRec.DOC_INTERFACE_ID
                                             );   -- OUT Id de l'interface
        -- Mise � jour de l'interface avec valeurs sp�cifiques
        WRITELOG('*Avant update InsertInterface', 0);

        update DOC_INTERFACE
           set DOI_PROTECTED = 0   -- Pas de protection
         where DOC_INTERFACE_ID = DocumentRec.DOC_INTERFACE_ID;
      end if;
    --
    exception
      when others then
        RAISE_APPLICATION_ERROR(-20001, sqlerrm);
    end;
  end;

  -- Insertion des donn�es dans l'interface position
  procedure InsertInterfacePosition
  is
  begin
    begin
      if not DocumentRec.NEW_DOC_STOP then
        WRITELOG('*InsertInterfacePosition', 0);
        --
        -- D�termine l'id de l'interface position
        DOC_INTERFACE_POSITION_CREATE.CREATE_INTERFACE_POSITION(DocumentRec.DOC_INTERFACE_ID
                                                              ,   -- IN ID de l'interface
                                                                JobRec.GAU_DESCR
                                                              ,   -- IN Nom du gabarit d'initialisation
                                                                DetailDocu.DOC_GAUGE_ID
                                                              ,   -- IN Id du gabarit
                                                                DetailDocu.C_GAUGE_TYPE_POS
                                                              ,   -- IN Type de position : 1
                                                                DetailDocu.DOC_INTERFACE_POSITION_ID
                                                               );   -- OUT
        -- Mise a jour interface position en fonction du produit
        DOC_INTERFACE_POSITION_CREATE.UPDATE_INTERFACE_POSITION(DocumentRec.DOC_INTERFACE_ID, DetailDocu.DOC_INTERFACE_POSITION_ID, DetailDocu.GCO_GOOD_ID);

        -- Mise � jour interface position en fonction valeurs sp�cifiques
        update DOC_INTERFACE_POSITION
           set   -- Num�ro de personne
              DOP_POS_TEXT_1 = DetailDocu.INTERM_NO_PERS
            ,
              -- Dossier ou chantier
              DOC_RECORD_ID = DetailDocu.DOC_RECORD_ID
            ,
              -- Qte command�e
              DOP_QTY = DetailDocu.DOP_QTY
            , DOP_QTY_VALUE = DetailDocu.DOP_QTY
            ,
              -- Date de saisie
              DOP_BASIS_DELAY = DetailDocu.DOP_BASIS_DELAY
            , DOP_INTERMEDIATE_DELAY = DetailDocu.DOP_BASIS_DELAY
            , DOP_FINAL_DELAY = DetailDocu.DOP_BASIS_DELAY
            , A_DATEMOD = sysdate
            , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_INTERFACE_POSITION_ID = DetailDocu.DOC_INTERFACE_POSITION_ID;
      end if;
    --
    exception
      when others then
        RAISE_APPLICATION_ERROR(-20001, sqlerrm);
    end;
  end;

  -- Mise � jour des enregistrements sans erreur en g�n�r�s
  procedure UpdateOKRecords
  is
  begin
    WRITELOG('------UPDATEOKRECORDS', 0);

    --
    update DOC_EDI_IMPORT_JOB_DATA
       set C_EDI_JOB_DATA_STATUS = 'GENE'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
       and C_EDI_JOB_DATA_STATUS = 'OK';
  end;

  -- D�termine le valeur de retour en fonction des �tats ok et not_ok
  -- 0 Pas de document trait�
  -- 1 Tous les documents g�n�r�
  -- 2 Documents ok + Documents en erreur
  -- 3 Tous les document en error
  function ReturnValue
    return integer
  is
  begin
    WRITELOG('*ReturnValue', 0);

    --
    if JobRec.NEW_DOC_OK then
      if JobRec.NEW_DOC_NOT_OK then
        -- Partiellement ok
        return 2;
      else
        -- Tous les documents ok
        return 1;
      end if;
    else
      if JobRec.NEW_DOC_NOT_OK then
        -- Tous les documents en erreur
        return 3;
      else
        -- Aucun document d�tect�
        return 0;
      end if;
    end if;
  end;

  -- Recherche l'id d'un client en fonction de code ean
  procedure GetCustomId(paNumber in varchar2, PacThirdId out number)
  is
  begin
    WRITELOG('*GetCustomId', 0);
    --
    PacThirdId  := null;

    --
    -- Si EAN null
    if paNumber is null then
      PutError(PCS.PC_FUNCTIONS.TranslateWord('Code EAN du client non saisi') );
    else
      begin
        select PAC_CUSTOM_PARTNER_ID
          into PacThirdId
          from PAC_CUSTOM_PARTNER
         where CUS_EAN_NUMBER = rtrim(paNumber);
      -- Client non trouv�
      exception
        when no_data_found then
          begin
            -- Message d'erreur
            PutError(PCS.PC_FUNCTIONS.TranslateWord('Client non trouv� selon code EAN') || ' : ' || paNumber);
          end;
        when others then
          PutError(sqlerrm);
      end;
    end if;
  end;

  -- Fonction charg�e de retourner l'id du dossier
  function GetRecordId(aTitle varchar2)
    return number
  is
    DocRecordId number(12);
  begin
    WRITELOG('*GetRecordId', 0);

    --
    begin
      select DOC_RECORD_ID
        into DocRecordId
        from DOC_RECORD
       where substr(RCO_TITLE, 1, 6) = ltrim(aTitle);
    --       RCO_TITLE = RTRIM(aTitle);
    --
    exception
      when no_data_found then
        begin
          -- Message d'erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Dossier non trouv�') || ' : ' || aTitle);
          DocRecordId  := null;
        end;
      when others then
        PutError(sqlerrm);
    end;

    --
    return DocRecordId;
  end;

  -- Retourne l'id d'un bien en fonction de sa r�f�rence
  function GetGcoGoodId(aReference varchar2)
    return number
  is
    GcoGoodId number(12);
  begin
    WRITELOG('*GetGcoGoodId', 0);

    --
    begin
      select GCO_GOOD_ID
        into GcoGoodId
        from GCO_GOOD
       where GOO_MAJOR_REFERENCE = rtrim(aReference);
    -- Bien non trouv�
    exception
      when no_data_found then
        begin
          -- Message d'erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Bien non trouv�') || ' : ' || aReference);
          GcoGoodId  := null;
        end;
      when others then
        PutError(sqlerrm);
    end;

    --
    return GcoGoodId;
  end;

  -- D�termine l'Id d'un gabarit en fonction de sa description.
  -- Si l'id de retoure est 0, cela signifie que le gabarit n'a pas �t� trouv�.
  function GetGaugeFromDescr(aDescr varchar2)
    return number
  is
    gauId number(12);
  begin
    WRITELOG('*GetGaugeFromDescr', 0);

    --
    begin
      select DOC_GAUGE_ID
        into gauId
        from DOC_GAUGE
       where rtrim(GAU_DESCRIBE) = aDescr;
    -- Gabarit non Trouv�
    exception
      when no_data_found then
        begin
          -- Message d'erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Gabarit non trouv�') || ': ' || aDescr);
          gauId  := null;
        end;
      when others then
        PutError(sqlerrm);
    end;

    --
    return gauId;
  end;

-- *************************************************
-- *****        Import 700                     *****
-- *************************************************

  -- Decode d'une ligne d�tail document import
  function DecodeDetailDocu
    return boolean
  is
    result boolean;
  begin
    WRITELOG('------------DECODEDETAILDOCU', 0);
    --
    result  := true;

    --
    -- Test des valeurs � comparer
    if result then
      PutRowPosition('26');

      if DetailDocu.INTERM_TEST_VALUE <> JobRec.INTERM_TEST_VALUE then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Valeurs � tester diff�rentes') || ' : ' || JobRec.INTERM_TEST_VALUE || '/' || DetailDocu.INTERM_TEST_VALUE);
        result  := false;
      end if;
    end if;

    -- Recherche Id du dossier (chantier)
    if result then
      PutRowPosition('1');
      DetailDocu.DOC_RECORD_ID  := GetRecordId(DetailDocu.INTERM_CHANTIER);
      result                    := DetailDocu.DOC_RECORD_ID is not null;
    end if;

    -- Quantit�
    if result then
      PutRowPosition('11');
      -- Formatage
      DetailDocu.DOP_QTY  := PutInNumber(DetailDocu.INTERM_DOP_QTY, 5, 2);
      result              := DetailDocu.DOP_QTY is not null;
    end if;

    -- Recherche Id du bien
    if result then
      PutRowPosition('18');
      DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DetailDocu.DOP_MAJOR_REFERENCE);
      result                  := DetailDocu.GCO_GOOD_ID is not null;
    end if;

    -- Recherche de la date de saisie
    if result then
      PutRowPosition('29');
      DetailDocu.DOP_BASIS_DELAY  := PutInDate(DetailDocu.INTERM_DOP_BASIS_DELAY, 'DDMMYYYY');
      result                      := DetailDocu.DOP_BASIS_DELAY is not null;
    end if;

    --
    PutStatus(ConvertState(result) );
    --
    return result;
  end;

  -- Traitement du d�tail du document import
  procedure Detail_Docu
  is
    cursor DetailDocument
    is
      select   DOC_EDI_IMPORT_JOB_DATA_ID
             , DID_VALUE
             , DID_LINE_NUMBER
          from DOC_EDI_IMPORT_JOB_DATA
         where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
           and (   rtrim(C_EDI_JOB_DATA_STATUS) is null
                or C_EDI_JOB_DATA_STATUS <> 'GENE')
      order by DID_LINE_NUMBER;

    params DetailDocument%rowtype;
  begin
    WRITELOG('----------DETAIL_DOCU', 0);

    --
    open DetailDocument;

    fetch DetailDocument
     into params;

    while DetailDocument%found loop
      InitFieldsDetail;
      InitVarLine;
      -- Id du record
      LineRec.DOC_EDI_IMPORT_JOB_DATA_ID  := params.DOC_EDI_IMPORT_JOB_DATA_ID;
      -- Ligne
      LineRec.DID_VALUE                   := params.DID_VALUE;
      -- Num�ro de ligne
      LineRec.DID_LINE_NUMBER             := params.DID_LINE_NUMBER;
      -- Type de position d�tail
      DetailDocu.C_GAUGE_TYPE_POS         := '1';
      -- Chantier / Dossier
      DetailDocu.INTERM_CHANTIER          := substr(params.DID_VALUE, 1, 10);
      -- Quantit�
      DetailDocu.INTERM_DOP_QTY           := substr(params.DID_VALUE, 11, 7);
      -- Num�ro de produit
      DetailDocu.DOP_MAJOR_REFERENCE      := substr(params.DID_VALUE, 18, 2);
      -- Num�ro de personne
      DetailDocu.INTERM_NO_PERS           := substr(params.DID_VALUE, 20, 6);
      -- Valeur � tester
      DetailDocu.INTERM_TEST_VALUE        := substr(params.DID_VALUE, 26, 3);
      -- Date de saisie
      DetailDocu.INTERM_DOP_BASIS_DELAY   := substr(params.DID_VALUE, 29, 10);

      -- D�codage du d�tail
      if DecodeDetailDocu then
        -- Ajout dans l'interface position
        InsertInterfacePosition;
      end if;

      --
      fetch DetailDocument
       into params;
    end loop;
  end;

  procedure ProcessDocu
  -- Traitement g�n�ral du document
  is
  begin
    WRITELOG('----PROCESSDOCU', 0);
    --
    -- Inscription dans le log
    PutMessage(PCS.PC_FUNCTIONS.TranslateWord('Traitement du document') );
    -- Traitement de tous les d�tails document
    Detail_Docu;

    -- Probl�me document
    if DocumentRec.NEW_DOC_STOP then
      -- Document erreur (pour statut de retour final � delphi)
      JobRec.NEW_DOC_NOT_OK  := true;
      -- Suppression des enregistrements ajout�s
      DOC_EDI_IMPORT.DeleteInterfaceRecords(DocumentRec.DOC_INTERFACE_ID);
      -- Inscription num�ro interface dans le log
      PutMessage(PCS.PC_FUNCTIONS.TranslateWord('Document non trait�') );
    -- Document en ordre
    else
      -- Document en ordre (pour statut de retour final � delphi)
      JobRec.NEW_DOC_OK  := true;
      -- Mise � jour des status, passage de - en pr�paration - � - pr�t -
      DOC_EDI_IMPORT.UpdateInterfaceRecords(DocumentRec.DOC_INTERFACE_ID);
      -- Mise � jour des enregistrement --> GENE
      UpdateOKRecords;
      -- Inscription num�ro interface dans le log
      PutMessage(PCS.PC_FUNCTIONS.TranslateWord('Cr�ation de l''interface') || ' : ' || DocumentRec.NEW_DOI_NUMBER);
    end if;
  end;

  function DecodeHeaderFile
    return boolean
  -- Decode entete de fichier import
  -- Dans ce cas la ligne est fictive; elle ne provient que des param�tres ou configuration
  is
    result boolean;
  begin
    WRITELOG('------DECODEHEADERFILE', 0);
    --
    result            := true;
    --
    -- Nom du gabarit dans la configuration pour table INTERFACE (doit exister)
    JobRec.GAU_DESCR  := PCS.PC_CONFIG.GETCONFIG('DOC_EDI_CONFIG_GAUGE');

    --
    -- Gabarit
    if result then
      -- Gabarit provenant des param�tres
      JobRec.INTERM_GAUGE_DESCRIPTION  := DOC_EDI_FUNCTION.GetParamValue('GAUGE_DESCRIPTION');
      -- Id du gabarit pour document
      JobRec.DOC_GAUGE_ID              := GetGaugeFromDescr(JobRec.INTERM_GAUGE_DESCRIPTION);
      -- Existence ?
      result                           := JobRec.DOC_GAUGE_ID is not null;
    end if;

    --
    -- Client SELON EAN
    if result then
      -- Code EAN du client provenant des param�tres.
      JobRec.INTERM_CUS_EAN_NUMBER  := DOC_EDI_FUNCTION.GetParamValue('EAN_NUMBER');
      -- Recherche de l'id du client
      GetCustomId(JobRec.INTERM_CUS_EAN_NUMBER, JobRec.PAC_THIRD_ID);
      result                        := JobRec.PAC_THIRD_ID is not null;
    end if;

    --
    -- Valeur � tester
    if result then
      JobRec.INTERM_TEST_VALUE  := ltrim(DOC_EDI_FUNCTION.GetParamValue('TEST_VALUE') );

      if JobRec.INTERM_TEST_VALUE is null then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Param�tre servant de test non saisi') );
        result  := false;
      end if;
    end if;

    --
    return result;
  end;

  -- Traitement de la pseudo en-t�te du fichier import
  function HeaderFile
    return boolean
  is
    result boolean;
  begin
    WRITELOG('----HEADERFILE', 0);
    --
    -- Init des variables de la ligne
    InitVarLine;
    result  := DecodeHeaderFile;

    --
    if result then
      -- Ajout dans l'interface
      InsertInterface;
    end if;

    --
    return result;
  end;

  -- Import 700
  procedure Import700
  is
    result boolean;
  begin
    WRITELOG('--IMPORT700', 0);
    --
    InitVarDoc;
    -- Pseudo ent�te du fichier, lecture du gabarit � partir des param�tres
    result  := HeaderFile;

    -- Traitement complet du d�tail du document
    if result then
      ProcessDocu;
    end if;
  --
  -- Probl�me divers
  exception
    when others then
      -- Erreur technique - retour de la fonction
      SysRec.RETURN_VALUE  := 9;
      -- Erreur dans le log
      PutError(sqlerrm);
      -- Maj statut de la ligne ERROR
      PutStatus(0);
      -- Suppression des enregistrements de l'interface
      DOC_EDI_IMPORT.DeleteInterfaceRecords(DocumentRec.DOC_INTERFACE_ID);
  end;

  -- Importation g�n�rale
  procedure Import
  is
  begin
    -- Init des variables systeme
    InitVarSys;
    -- Id du job
    SysRec.JOB_ID  := DOC_EDI_IMPORT.GET_JOBID;
    -- Journal
    WRITELOG('IMPORT (DOC_EDI_IMPORT700)', 0);
    -- Init des variables du job
    InitVarJob;
    -- Recherche transfert
    DOC_EDI_FUNCTION.GetJob(SysRec.JOB_ID, SysRec.DOC_EDI_TYPE_ID);
    -- Param�tres du transfert
    DOC_EDI_FUNCTION.FillParamsTable(SysRec.DOC_EDI_TYPE_ID);
    -- Recherche de la fonction
    Import700;

    --
    -- Retour de la valeur
    --
    if SysRec.RETURN_VALUE is null then
      SysRec.RETURN_VALUE  := ReturnValue;
    end if;

    -- Retourne la valeur de retour des op�rations
    DOC_EDI_IMPORT.SET_RETURN_VALUE(SYSREC.RETURN_VALUE);
  end;
end;
