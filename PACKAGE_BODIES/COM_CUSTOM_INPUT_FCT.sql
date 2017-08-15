--------------------------------------------------------
--  DDL for Package Body COM_CUSTOM_INPUT_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_CUSTOM_INPUT_FCT" 
is
  /**
   * procedure InitProc
   * Description
   *   Initialisation de la saisie
   */
  procedure InitProc(
    aCustomInputId     in     COM_CUSTOM_INPUT.COM_CUSTOM_INPUT_ID%type
  , aLastCustomInputId in     COM_CUSTOM_INPUT.COM_CUSTOM_INPUT_ID%type
  , aReqActions        out    varchar2
  , aFocusField        out    varchar2
  , aErrorCode         out    integer
  , aErrorMessage      out    varchar2
  )
  is
    vChar varchar2(255);
    vInt  integer;
  begin
    aErrorCode  := 0;

    begin
      -- Gestion de statut
      update COM_CUSTOM_INPUT
         set C_CTI_STATUS = '10'   -- Nouvelle saisie à valider
       where COM_CUSTOM_INPUT_ID = aCustomInputId;

      -- Report de la valeur d'un champ de la saisie précédente
      if aLastCustomInputId > 0 then
        select VFI_CHAR_02
             , VFI_INTEGER_05
          into vChar
             , vInt
          from COM_VFIELDS_RECORD
         where VFI_TABNAME = 'COM_CUSTOM_INPUT'
           and VFI_REC_ID = aLastCustomInputId;
      end if;

      update COM_VFIELDS_RECORD
         set VFI_CHAR_02 = nvl(vChar, 'OPER1')
           , VFI_INTEGER_05 = nvl(mod(vInt + 1, 5), 0)
       where VFI_TABNAME = 'COM_CUSTOM_INPUT'
         and VFI_REC_ID = aCustomInputId;
    exception
      when others then
        begin
          aErrorCode     := 1;
          aErrorMessage  := PCS.PC_FUNCTIONS.TranslateWord('Erreur Oracle :') || chr(13) || sqlerrm;
        end;
    end;

    -- Permet d'afficher la gestion des produits
    --aReqActions := '[CALL_OBJECT] OBJ=GCO_PRODUCT;RW=1';

  end InitProc;

  /**
   * procedure ValidProc
   * Description
   *   Validation de la saisie
   */
  procedure ValidProc(
    aCustomInputId in     COM_CUSTOM_INPUT.COM_CUSTOM_INPUT_ID%type
  , aReqActions    out    varchar2
  , aFocusField    out    varchar2
  , aErrorCode     out    integer
  , aErrorMessage  out    varchar2
  )
  is
    vStatus varchar2(10);
    vInt    integer;
  begin
    aErrorCode  := 0;

    select C_CTI_STATUS
      into vStatus
      from COM_CUSTOM_INPUT
     where COM_CUSTOM_INPUT_ID = aCustomInputId;

    -- Si la saisie a déjà été importée, on arrête le traitement
    if vStatus = '50' then
      aErrorCode     := 267;
      aErrorMessage  := 'Input already processed';
    else
      -- Sinon, validation
      select VFI_INTEGER_05
        into vInt
        from COM_VFIELDS_RECORD
       where VFI_TABNAME = 'COM_CUSTOM_INPUT'
         and VFI_REC_ID = aCustomInputId;

      -- Vérification valeur
      if vInt < 0 then
        aErrorCode     := 156;
        aErrorMessage  := 'Value can''t negative';
        aFocusField    := 'CTI_VTEST_5';
      elsif vInt > 5 then
        vInt  := 0;
      end if;

      -- Mise à jour du champ GCO_GOOD_ID de la table principale à partir de
      -- la valeur du champ virtuel correspondant
      begin
        update COM_CUSTOM_INPUT
           set GCO_GOOD_ID = (select VFI_FLOAT_01
                                from COM_VFIELDS_RECORD
                               where VFI_TABNAME = 'COM_CUSTOM_INPUT'
                                 and VFI_REC_ID = aCustomInputId)
         where COM_CUSTOM_INPUT_ID = aCustomInputId;
      exception
        when others then
          aErrorCode     := 189;
          aErrorMessage  := 'Good not found';
      end;

      if aErrorCode = 0 then
        -- Gestion de statut
        update COM_CUSTOM_INPUT
           set C_CTI_STATUS = '30'   -- Saisie validée sans erreur
             , CTI_ERROR_MESSAGE = 'Validated!' || ' ' || aErrorCode || ' ' || aCustomInputId
         where COM_CUSTOM_INPUT_ID = aCustomInputId;

        -- Traitement d'importation (mise à jour des tables métier) à partir
        -- des données la table principale.
        -- ......
        if aErrorCode = 0 then
          -- Gestion de statut
          update COM_CUSTOM_INPUT
             set C_CTI_STATUS = '50'   -- Saisie importée sans erreur
               , CTI_ERROR_MESSAGE = 'Imported!' || ' ' || aErrorCode || ' ' || aCustomInputId
           where COM_CUSTOM_INPUT_ID = aCustomInputId;
        else
          -- Gestion de statut
          update COM_CUSTOM_INPUT
             set C_CTI_STATUS = '40'   -- Saisie non importée (erreur)
               , C_CTI_ERROR_CODE = aErrorCode
               , CTI_ERROR_MESSAGE = 'Not imported!' || ' ' || aErrorCode || ' ' || aCustomInputId
           where COM_CUSTOM_INPUT_ID = aCustomInputId;
        end if;
      else
        -- Gestion de statut
        update COM_CUSTOM_INPUT
           set C_CTI_STATUS = '20'   -- Saisie non validée (erreur)
             , C_CTI_ERROR_CODE = aErrorCode
             , CTI_ERROR_MESSAGE = 'Not validated!' || ' ' || aErrorCode || ' ' || aCustomInputId
         where COM_CUSTOM_INPUT_ID = aCustomInputId;
      end if;
    end if;
  end ValidProc;

  /**
    * procedure FieldEnterProc
    * Description
    *   Procédure d'événement d'entrée d'un champ virtuel
    */
  procedure FieldEnterProc(
    aCustomInputId in     COM_CUSTOM_INPUT.COM_CUSTOM_INPUT_ID%type
  , aFieldName     in     varchar2
  , aFieldModified in     integer
  , aFocusField    out    varchar2
  , aErrorCode     out    integer
  , aErrorMessage  out    varchar2
  )
  is
    vInt integer;
  begin
    aErrorCode  := 0;

    -- Le champ CTI_VTEST_5 est initialisé à 1 s'il est null
    if aFieldName = 'CTI_VTEST_5' then
      select VFI_INTEGER_05
        into vInt
        from COM_VFIELDS_RECORD
       where VFI_TABNAME = 'COM_CUSTOM_INPUT'
         and VFI_REC_ID = aCustomInputId;

      if vInt is null then
        update COM_VFIELDS_RECORD
           set VFI_INTEGER_05 = 1
         where VFI_TABNAME = 'COM_CUSTOM_INPUT'
           and VFI_REC_ID = aCustomInputId;
      end if;
    end if;
  end FieldEnterProc;

  /**
   * procedure FieldExitProc
   * Description
   *   Procédure d'événement de sortie d'un champ virtuel
   */
  procedure FieldExitProc(
    aCustomInputId in     COM_CUSTOM_INPUT.COM_CUSTOM_INPUT_ID%type
  , aFieldName     in     varchar2
  , aFieldModified in     integer
  , aFocusField    out    varchar2
  , aErrorCode     out    integer
  , aErrorMessage  out    varchar2
  )
  is
    vInt integer;
  begin
    aErrorCode  := 0;

    -- Le champ CTI_VTEST_5 ne peut être null
    if aFieldName = 'CTI_VTEST_5' then
      select VFI_INTEGER_05
        into vInt
        from COM_VFIELDS_RECORD
       where VFI_TABNAME = 'COM_CUSTOM_INPUT'
         and VFI_REC_ID = aCustomInputId;

      if vInt is null then
        aErrorCode     := 1;
        aFocusField    := aFieldName;
        aErrorMessage  := aFieldName || ' can''t be null!';
      end if;
    end if;
  end FieldExitProc;

  /*
   * procedure ButtonProc
   * Description
   *   Traitement d’un bouton personnalisé avec paramètre
   */
  procedure ButtonProc(
    aRecordID     in     number
  , aReqActions   out    varchar2
  , aFocusField   out    varchar2
  , aErrorCode    out    integer
  , aErrorMessage out    varchar2
  )
  is
    vStatus varchar2(10);
  begin
    aErrorCode  := 0;

    if aRecordID is not null then
      select C_CTI_STATUS
        into vStatus
        from COM_CUSTOM_INPUT
       where COM_CUSTOM_INPUT_ID = aRecordID;

      -- Si la saisie a déjà été importée, on arrête le traitement
      if vStatus = '50' then
        aErrorCode     := -123;
        aErrorMessage  := 'Imported input is read only';
      else
        -- On ajoute le texte 'ButtonProc' au memo
        begin
          update COM_VFIELDS_RECORD
             set VFI_MEMO_07 = VFI_MEMO_07 || 'ButtonProc' || chr(13) || chr(10)
           where VFI_TABNAME = 'COM_CUSTOM_INPUT'
             and VFI_REC_ID = aRecordID;
        exception
          when others then
            aErrorCode     := -172;
            aErrorMessage  := sqlerrm;
        end;

        if aErrorCode = 0 then
          -- Si le memo dépasse 50 caractères, on le signale
          select nvl(max(-182), 0)
            into aErrorCode
            from COM_VFIELDS_RECORD
           where length(VFI_MEMO_07) >= 50
             and VFI_TABNAME = 'COM_CUSTOM_INPUT'
             and VFI_REC_ID = aRecordID;

          if aErrorCode = -182 then
            aErrorMessage  := 'Memo too long';
          end if;
        end if;
      end if;
    end if;
  end ButtonProc;

  /*
   * procedure ButtonProc
   * Description
   *   Traitement d’un bouton personnalisé sans paramètre
   */
  procedure ButtonProc(
    aReqActions   out varchar2
  , aFocusField   out varchar2
  , aErrorCode    out integer
  , aErrorMessage out varchar2
  )
  is
  begin
    aErrorCode  := 0;
  end ButtonProc;
end COM_CUSTOM_INPUT_FCT;
