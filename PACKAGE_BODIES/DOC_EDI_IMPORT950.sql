--------------------------------------------------------
--  DDL for Package Body DOC_EDI_IMPORT950
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_IMPORT950" 
as
-- *************************************************
-- *****             GENERAL                   *****
-- *************************************************

  -- Fonction sumulant une error - Pour test
  function RAISEERROR
    return boolean
  is
  begin
    RAISE_APPLICATION_ERROR(-20001, 'ERREUR PROVOQUEE POUR TEST');
    return false;
  end;

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

  procedure PutWarning(aMessage varchar2)
  -- Message d'avertissement dans le log avec le num�ro de ligne, la ligne, le message avec colone
  -- Le message est reformatt� en fonction de la position
  is
  begin
    LineRec.DID_ERROR_TEXT  := aMessage;
    DOC_EDI_IMPORT.PutWarning(LineRec.DID_ERROR_TEXT, LineRec.DOC_EDI_IMPORT_JOB_DATA_ID, LineRec.DID_VALUE, LineRec.DID_LINE_NUMBER, LineRec.NEW_ROW_POSITION);
  end;

  function PutInNumber(paNumber varchar2, paFormat varchar2)
    return number
  -- Mise en nombre une chaine de caract�res
  is
  begin
    WRITELOG('*PutInNumber', 0);

    --
    begin
      return to_number(paNumber, paFormat);
    --
    exception
      when others then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Format de nombre incorrect') || ' : ' || paNumber || ', ' || paFormat);
        return null;
    end;
  end;

  function PutInDate(paDate varchar2, paFormat varchar2)
    return date
  -- Mise en date une chaine de caract�res
  is
  begin
    WRITELOG('*PutInDate', 0);

    --
    begin
      return to_date(paDate, paFormat);
    --
    exception
      when others then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Format de date incorrect') || ' : ' || paDate || ', ' || paFormat);
        return null;
    end;
  end;

  function ParamExists(aPara in varchar2)
    return boolean
  -- D�termine si le param�tre existe
  is
  begin
    return DOC_EDI_IMPORT.ParamExists(vParameter, aPara);
  end;

  function GetValue(aPara in varchar2)
    return varchar2
  -- Retourne la valeur d'un param�tre en fonction du nom du param�tre
  is
  begin
    return DOC_EDI_IMPORT.GetValue(vParameter, vValue, aPara);
  end;

  function GetPosition(aPara in varchar2)
    return integer
  -- Retourne la position de d�but de valeur d'un param�tre
  is
  begin
    return DOC_EDI_IMPORT.GetPosition(vParameter, vValue, aPara);
  end;

  procedure PutRowPosition(aParam varchar2)
  -- Initialisation de la position de colonne pour la ligne en cours.
  -- Num�ro donn� en fonction du param�tre
  is
  begin
    LineRec.NEW_ROW_POSITION  := GetPosition(aParam);
  end;

  procedure FillRec(aString varchar2, aList out DOC_EDI_IMPORT.TStructureArray)
  -- Remplissage d'un array en fonction l'une liste s�par�e par des ;
  is
  begin
    DOC_EDI_IMPORT.FillRec(aString, aList);
  end;

--------------------
-- Initialisation --
--------------------
  procedure InitVarSys
  -- Initialisation des variables syst�me
  is
  begin
    -- IMPORTANT : Pas de WRITELOG car JOB_ID n'est pas initialis�
    SysRec.JOB_ID           := null;
    SysRec.DOC_EDI_TYPE_ID  := null;
    SysRec.RETURN_VALUE     := null;
  end;

  procedure InitVarJob
  -- Init des variables g�n�rales pour toutes les lignes d'un job
  is
  begin
    WRITELOG('*InitVarJob', 0);
    --
    -- Pas de document ok
    JobRec.NEW_DOC_OK                := false;
    -- Pas de document en erreur
    JobRec.NEW_DOC_NOT_OK            := false;
    --
    -- Nom du gabarit pour table INTERFACE
    JobRec.PARAMETERSLIST            := null;
    -- Nom du gabarit pour table INTERFACE
    JobRec.GAU_DESCR                 := null;
    --
    -- Nom du gabarit du document
    JobRec.INTERM_GAUGE_DESCRIPTION  := null;
    -- Id du gabarit du document
    JobRec.DOC_GAUGE_ID              := null;
    --
    ---- pac_third_id
    JobRec.INTERM_CUS_EAN_NUMBER     := null;
    JobRec.PAC_THIRD_ID              := null;
  end;

  procedure InitVarDoc
  -- Init des variables g�n�rales pour le traiement d'un document d'un job
  is
  begin
    WRITELOG('*InitVarDoc', 0);
    --
    -- Id interface non initialis�
    DocumentRec.DOC_INTERFACE_ID  := null;
    -- Document un ordre
    DocumentRec.NEW_DOC_STOP      := false;
    -- Num�ro attribu�
    DocumentRec.NEW_DOI_NUMBER    := null;
  end;

  procedure InitVarLine
  -- Init des variables pour la ligne data en cours
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
    LineRec.NEW_ROW_POSITION            := 0;
  end;

  procedure InitFieldsDetail
  -- Init des champs du d�tail
  is
  begin
    WRITELOG('*InitFieldsDetail', 0);
    --
    DetailDocu.DOC_INTERFACE_POSITION_ID  := null;
    --
    DetailDocu.C_GAUGE_TYPE_POS           := null;
    -- Produit
    DetailDocu.DOP_MAJOR_REFERENCE        := null;
    DetailDocu.GCO_GOOD_ID                := null;
    -- Qte command�
    DetailDocu.INTERM_DOP_QTY             := null;
    DetailDocu.DOP_QTY                    := null;
    -- Delai demand�
    DetailDocu.INTERM_DOP_BASIS_DELAY     := null;
    DetailDocu.DOP_BASIS_DELAY            := null;
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
  -- 4 -> Mise a Null (non trait�)
  is
  begin
    WRITELOG('*PutStatus', 0);

    --
    -- En ordre
    if paStatus = 1 then
      LineRec.C_EDI_JOB_DATA_STATUS  := 'OK';
    -- Erreur
    elsif paStatus = 0 then
      LineRec.C_EDI_JOB_DATA_STATUS  := 'ERROR';
      -- Erreur -> suppression des ajout dans l'interface
      -- Important
      DocumentRec.NEW_DOC_STOP       := true;
    -- Avertissement
    elsif paStatus = 2 then
      LineRec.C_EDI_JOB_DATA_STATUS  := 'WARNING';
    -- Ligne non trait�e
    elsif paStatus = 3 then
      LineRec.C_EDI_JOB_DATA_STATUS  := 'UNDEF';
    else
      LineRec.C_EDI_JOB_DATA_STATUS  := null;
    end if;

    --
    if LineRec.DOC_EDI_IMPORT_JOB_DATA_ID is not null then
      -- Mise du status et de message d'erreur du job data en cours
      -- Le message d'erreur provient en g�n�ral du put_error ou autres.
      update DOC_EDI_IMPORT_JOB_DATA
         set C_EDI_JOB_DATA_STATUS = LineRec.C_EDI_JOB_DATA_STATUS
           , DID_ERROR_TEXT = LineRec.DID_ERROR_TEXT
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_EDI_IMPORT_JOB_DATA_ID = LineRec.DOC_EDI_IMPORT_JOB_DATA_ID;
    end if;
  end;

  procedure InsertInterface
  -- Insertion des donn�es dans l'interface document
  is
  begin
    if not DocumentRec.NEW_DOC_STOP then
      begin
        WRITELOG('------INSERTINTERFACE', 0);
        --
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
        update DOC_INTERFACE
           set DOI_PROTECTED = 0   -- Pas de protection
         where DOC_INTERFACE_ID = DocumentRec.DOC_INTERFACE_ID;
      --
      exception
        when others then
          RAISE_APPLICATION_ERROR(-20001, sqlerrm);
      end;
    end if;
  end;

  procedure InsertInterfacePosition
  -- Insertion des donn�es dans l'interface position
  is
    newId number(12);
  begin
    begin
      WRITELOG('--------INSERTINTERFACEPOSITION', 0);
      --
      -- D�termine l'id de l'interface position
      DOC_INTERFACE_POSITION_CREATE.CREATE_INTERFACE_POSITION(DocumentRec.DOC_INTERFACE_ID
                                                            ,   -- IN ID de l'interface
                                                              JobRec.GAU_DESCR
                                                            ,   -- IN Nom du gabarit d'initialisation
                                                              JobRec.DOC_GAUGE_ID
                                                            ,   -- IN Id du gabarit
                                                              DetailDocu.C_GAUGE_TYPE_POS
                                                            ,   -- IN Type de position : 1
                                                              DetailDocu.DOC_INTERFACE_POSITION_ID
                                                             );   -- OUT
      -- Mise a jour interface position en fonction du produit
      DOC_INTERFACE_POSITION_CREATE.UPDATE_INTERFACE_POSITION(DocumentRec.DOC_INTERFACE_ID, DetailDocu.DOC_INTERFACE_POSITION_ID, DetailDocu.GCO_GOOD_ID);

      --
      update DOC_INTERFACE_POSITION
         set
             -- D�lai demand�
             DOP_BASIS_DELAY = DetailDocu.DOP_BASIS_DELAY
           , DOP_INTERMEDIATE_DELAY = DetailDocu.DOP_BASIS_DELAY
           , DOP_FINAL_DELAY = DetailDocu.DOP_BASIS_DELAY
           ,
             -- Qte command�e
             DOP_QTY = DetailDocu.DOP_QTY
           , DOP_QTY_VALUE = DetailDocu.DOP_QTY
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_INTERFACE_POSITION_ID = DetailDocu.DOC_INTERFACE_POSITION_ID;
    --
    exception
      when others then
        RAISE_APPLICATION_ERROR(-20001, sqlerrm);
    end;
  end;

  procedure UpdateOKRecords
  -- Mise � jour des enregistrements sans erreur en g�n�r�s
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

  function GetGcoGoodId(aReference varchar2)
    return number
  -- Retourne l'id d'un bien en fonction de sa r�f�rence
  -- Cl� unique
  is
    GcoGoodId number(12);
  begin
    WRITELOG('*GetGcoGoodId', 0);
    --
    GcoGoodId  := null;

    --
    begin
      select GCO_GOOD_ID
        into GcoGoodId
        from GCO_GOOD
       where GOO_MAJOR_REFERENCE = rtrim(aReference);
    -- Bien non trouv� ou erreur
    exception
      when no_data_found then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Bien non trouv�') || ' : ' || aReference);
      when others then
        PutError(sqlerrm);
    end;

    --
    return GcoGoodId;
  end;

  function GetGaugeFromDescr(aDescr varchar2)
    return number
  -- D�termine l'Id d'un gabarit en fonction de sa description.
  -- Si l'id retourne NULL, cela signifie que le gabarit n'a pas �t� trouv�.
  is
    gauId number(12);
  begin
    WRITELOG('*GetGaugeFromDescr', 0);
    --
    gauId  := null;

    --
    begin
      select DOC_GAUGE_ID
        into gauId
        from DOC_GAUGE
       where rtrim(GAU_DESCRIBE) = aDescr;
    -- Gabarit non Trouv�
    exception
      when no_data_found then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Gabarit non trouv�') || ': ' || aDescr);
      when others then
        PutError(sqlerrm);
    end;

    --
    return gauId;
  end;

  procedure NoTreatedLines
  -- D�tection des lignes non trait�es
  is
    cursor JobLines
    is
      select   DOC_EDI_IMPORT_JOB_DATA_ID
             , DID_VALUE
             , DID_LINE_NUMBER
          from DOC_EDI_IMPORT_JOB_DATA
         where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
           and (   rtrim(C_EDI_JOB_DATA_STATUS) is null
                or C_EDI_JOB_DATA_STATUS = 'UNDEF')
      order by DOC_EDI_IMPORT_JOB_DATA_ID;

    params JobLines%rowtype;
  begin
    WRITELOG('----NOTREATEDLINES', 0);

    --
    open JobLines;

    fetch JobLines
     into params;

    while JobLines%found loop
      InitVarLine;
      -- Id du record
      LineRec.DOC_EDI_IMPORT_JOB_DATA_ID  := params.DOC_EDI_IMPORT_JOB_DATA_ID;
      -- Ligne
      LineRec.DID_VALUE                   := params.DID_VALUE;
      -- Num�ro de ligne
      LineRec.DID_LINE_NUMBER             := params.DID_LINE_NUMBER;
      -- Message de warning
      PutWarning(PCS.PC_FUNCTIONS.TranslateWord('Ligne ind�finie et non trait�e, car non rattach�e � un document') );
      -- Statut UNDEF
      PutStatus(3);

      fetch JobLines
       into params;
    end loop;
  end;

-- *************************************************
-- *****        Import CSV 950                 *****
-- *************************************************
  procedure GetCustomId(paNumber in varchar2, PacThirdId out number)
  -- Recherche l'id d'un client en fonction de code ean
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
      --
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

  function DecodeDetailDocu
    return boolean
  -- Decode d'une ligne d�tail document import
  is
    result boolean;
  begin
    WRITELOG('--------DECODEDETAILDOCU', 0);
    --
    result  := true;

    -- Recherche Id du bien
    if result then
      if DetailDocu.DOP_MAJOR_REFERENCE is not null then
        PutRowPosition('REFERENCE');
        DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DetailDocu.DOP_MAJOR_REFERENCE);
        result                  := DetailDocu.GCO_GOOD_ID is not null;
      end if;
    end if;

    --
    -- D�lai demand�
    if result then
      if DetailDocu.INTERM_DOP_BASIS_DELAY is not null then
        PutRowPosition('DELAY');
        DetailDocu.DOP_BASIS_DELAY  := PutInDate(DetailDocu.INTERM_DOP_BASIS_DELAY, DOC_EDI_FUNCTION.GetParamValue('VALUE_DELAY_FORMAT') );
        result                      := DetailDocu.DOP_BASIS_DELAY is not null;
      end if;
    end if;

    --
    -- Quantit�
    if result then
      if DetailDocu.INTERM_DOP_QTY is not null then
        PutRowPosition('QUANTITY');
        DetailDocu.DOP_QTY  := PutInNumber(DetailDocu.INTERM_DOP_QTY, DOC_EDI_FUNCTION.GetParamValue('VALUE_QUANTITY_FORMAT') );
        result              := DetailDocu.DOP_QTY is not null;
      end if;
    end if;

    --
    PutStatus(ConvertState(result) );
    --
    return result;
  end;

  -- Traitement du d�tail du document import
  procedure Detail_Docu
  is
    blnOk  boolean;
    vCode  varchar2(2);

    --
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
    WRITELOG('------DETAIL_DOCU', 0);

    --
    open DetailDocument;

    fetch DetailDocument
     into params;

    while DetailDocument%found loop
      WRITELOG('', 0);
      WRITELOG('*********************', 0);
      WRITELOG('*ProcessNewDetailLine', 0);
      WRITELOG('*********************', 0);
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
      --
      --Remplissage de l'array des valeurs
      FILLREC(LineRec.DID_VALUE, vValue);
      --
      -- Passage que si CODE n'existe pas ou si il existe et valeur est A
      blnOK                               := true;

      if ParamExists('CODE') then
        vCode  := GetValue('CODE');

        if    (vCode is null)
           or (vCode <> 'A') then
          blnOk  := false;
        end if;
      end if;

      --
      if blnOk then
        -- Num�ro de produit
        DetailDocu.DOP_MAJOR_REFERENCE     := GetValue('REFERENCE');
        -- Delai demand�
        DetailDocu.INTERM_DOP_BASIS_DELAY  := GetValue('DELAY');
        -- Qte command�e
        DetailDocu.INTERM_DOP_QTY          := GetValue('QUANTITY');

        -- D�codage du d�tail
        if DecodeDetailDocu then
          -- Ajout dans l'interface position
          InsertInterfacePosition;
        end if;
      else
        -- Mise � vide - sera trait�e plus tard par notreatedlines
        PutStatus(4);
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
    -- Traitement d'un document complet
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
  -- Decode d'une ligne entete de fichier import
  -- Dans ce cas la ligne est fictive; elle ne provient que des param�tres
  is
    result boolean;
  begin
    WRITELOG('------DECODEHEADERFILE', 0);
    --
    result                 := true;
    --
    -- Nom du gabarit pour table INTERFACE
    JobRec.GAU_DESCR       := PCS.PC_CONFIG.GETCONFIG('DOC_EDI_CONFIG_GAUGE');
    -- Param�tres des lignes � traiter
    JobRec.PARAMETERSLIST  := DOC_EDI_FUNCTION.GetParamValue('PARAMETERS');
    -- Mise en array des param�tres
    FILLREC(JobRec.PARAMETERSLIST, vParameter);

    --
    -- Gabarit non obligatoire
    if result then
      -- Nom du gabarit pour document
      JobRec.INTERM_GAUGE_DESCRIPTION  := DOC_EDI_FUNCTION.GetParamValue('GAUGE_DESCRIPTION');

      if JobRec.INTERM_GAUGE_DESCRIPTION is not null then
        -- Id du gabarit pour document
        JobRec.DOC_GAUGE_ID  := GetGaugeFromDescr(JobRec.INTERM_GAUGE_DESCRIPTION);
        result               := JobRec.DOC_GAUGE_ID is not null;
      end if;
    end if;

    --
    -- Client selon EAN
    if result then
      -- Code EAN du client provenant des param�tres.
      JobRec.INTERM_CUS_EAN_NUMBER  := DOC_EDI_FUNCTION.GetParamValue('EAN_NUMBER');
      -- Recherche de l'id du client
      GetCustomId(JobRec.INTERM_CUS_EAN_NUMBER, JobRec.PAC_THIRD_ID);
      result                        := JobRec.PAC_THIRD_ID is not null;
    end if;

    --
    return result;
  end;

  function HeaderFile
    return boolean
  -- Traitement de la pseudo en-t�te du fichier import
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
      InsertInterface;
    end if;

    --
    return result;
  end;

  -- Import950
  procedure Import950
  is
    result boolean;
  begin
    WRITELOG('--IMPORT950', 0);
    --
    -- Pseudo ent�te du fichier, lecture client pour tous les documents du job
    result  := HeaderFile;

    -- Recherche et traitement complet de chaque document
    if result then
      ProcessDocu;
    end if;

    --
    -- Traitement des lignes non trait�es.
    NoTreatedLines;
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
      -- Suppression de records de l'interface
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
    --
    WRITELOG('IMPORT (DOC_EDI_IMPORT950)', 0);
    --
    -- Init des variables du job
    InitVarJob;
    -- Init des variables du document (il n'y en a qu'un)
    InitVarDoc;
    -- Recherche transfert
    DOC_EDI_FUNCTION.GetJob(SysRec.JOB_ID, SysRec.DOC_EDI_TYPE_ID);
    -- Param�tres du transfert
    DOC_EDI_FUNCTION.FillParamsTable(SysRec.DOC_EDI_TYPE_ID);
    -- Recherche de la fonction
    Import950;

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
