--------------------------------------------------------
--  DDL for Package Body SQM_ANC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_ANC_FUNCTIONS" 
is
/****************************************************** Proc�dure priv�es **********************************************************/

  /* Procedure qui renvoie pour le calendrier par d�faut de la soci�t�, la dur�e entre date d�but et date fin */
  procedure GetExactDuration(aBegin_Date in date, aEnd_Date in date, aResultat in out MaxVarchar2, aDuration in out number)
  is
    aCalendarID    number;
    aNbNonOpenDays number;
  begin
    if     aBegin_Date is not null
       and aEnd_Date is not null then
      -- Calendrier par d�faut de la soci�t�
      aCalendarID  := FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar;
      -- Nombre de jours non ouvr� entre les dates d�but et fin
      aDuration    := FAL_SCHEDULE_FUNCTIONS.GetDuration(null, null, null, null, null, aCalendarID, trunc(aBegin_Date), trunc(aEnd_Date) );
    else
      aDuration  := null;
    end if;
  exception
    when others then
      aResultat  := PCS.PC_FUNCTIONS.TRANSLATEWORD('Erreur d�tect�e pendant le calcul de la dur�e!');
  end GetExactDuration;

  /* V�rifie s'il existe des positions pour l'ANC, de statut different de valid�. */
  function ExistPositionToValidate(aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type)
    return boolean
  is
    cursor CUR_ANC_POSITION
    is
      select SQM_ANC_POSITION_ID
        from SQM_ANC_POSITION
       where SQM_ANC_ID = aSQM_ANC_ID
         and C_ANC_POS_STATUS = '1';

    CurAncPosition CUR_ANC_POSITION%rowtype;
    blnResult      boolean;
  begin
    blnResult  := false;

    open CUR_ANC_POSITION;

    fetch CUR_ANC_POSITION
     into CurAncPosition;

    if CUR_ANC_POSITION%found then
      blnResult  := true;
    end if;

    close CUR_ANC_POSITION;

    return blnResult;
  end ExistPositionToValidate;

  /* V�rifie s'il existe des positions pour l'ANC, de statut different de rejet� */
  function ExistPositionNotRejected(aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type)
    return boolean
  is
    cursor CUR_ANC_POSITION
    is
      select SQM_ANC_POSITION_ID
        from SQM_ANC_POSITION
       where SQM_ANC_ID = aSQM_ANC_ID
         and C_ANC_POS_STATUS <> '2';

    CurAncPosition CUR_ANC_POSITION%rowtype;
    blnResult      boolean;
  begin
    blnResult  := false;

    open CUR_ANC_POSITION;

    fetch CUR_ANC_POSITION
     into CurAncPosition;

    if CUR_ANC_POSITION%found then
      blnResult  := true;
    end if;

    close CUR_ANC_POSITION;

    return blnResult;
  end ExistPositionNotRejected;

  /* V�rifie si la position d'ANC � au moins une mesure Imm., une mesure pr�v. et une cause. */
  function IsPositionWithActions(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    return boolean
  is
    cursor CUR_ANC_POSITION_ACTIONS
    is
      select SAP.SQM_ANC_POSITION_ID
        from SQM_ANC_POSITION SAP
           , SQM_ANC_CAUSE SAC
           , SQM_ANC_DIRECT_ACTION SDA
           , SQM_ANC_PREVENTIVE_ACTION SPA
       where SAP.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID
         and SAP.SQM_ANC_POSITION_ID = SDA.SQM_ANC_POSITION_ID
         and SAP.SQM_ANC_POSITION_ID = SAC.SQM_ANC_POSITION_ID
         and SAC.SQM_ANC_CAUSE_ID = SPA.SQM_ANC_CAUSE_ID;

    CurAncPositionActions CUR_ANC_POSITION_ACTIONS%rowtype;
    blnResult             boolean;
  begin
    blnResult  := false;

    open CUR_ANC_POSITION_ACTIONS;

    fetch CUR_ANC_POSITION_ACTIONS
     into CurAncPositionActions;

    if CUR_ANC_POSITION_ACTIONS%found then
      blnResult  := true;
    end if;

    close CUR_ANC_POSITION_ACTIONS;

    return blnResult;
  end IsPositionWithActions;

  /* V�rifie si l'ANC de la position est en status "affect�e" */
  function IsANCAllocated(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    return boolean
  is
    cursor CUR_SQM_ANC
    is
      select ANC.SQM_ANC_ID
        from SQM_ANC ANC
           , SQM_ANC_POSITION SAP
       where SAP.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID
         and SAP.SQM_ANC_ID = ANC.SQM_ANC_ID
         and ANC.C_ANC_STATUS = '4';   -- "Affect�"

    CurSqmAnc CUR_SQM_ANC%rowtype;
    blnResult boolean;
  begin
    blnResult  := false;

    open CUR_SQM_ANC;

    fetch CUR_SQM_ANC
     into CurSqmAnc;

    if CUR_SQM_ANC%found then
      blnResult  := true;
    end if;

    close CUR_SQM_ANC;

    return blnResult;
  end IsANCAllocated;

  /* V�rifie si les mesures li�es � la position sont en statut "Termin�" */
  function IsANCPosActionsTerminated(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    return boolean
  is
    cursor CUR_ANC_POSITION_ACTIONS
    is
      select SAP.SQM_ANC_POSITION_ID
        from SQM_ANC_POSITION SAP
           , SQM_ANC_CAUSE SAC
           , SQM_ANC_DIRECT_ACTION SDA
           , SQM_ANC_PREVENTIVE_ACTION SPA
       where SAP.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID
         and SAP.SQM_ANC_POSITION_ID = SDA.SQM_ANC_POSITION_ID
         and SAP.SQM_ANC_POSITION_ID = SAC.SQM_ANC_POSITION_ID
         and SAC.SQM_ANC_CAUSE_ID = SPA.SQM_ANC_CAUSE_ID
         and (   SDA.C_SDA_STATUS <> '2'
              or SPA.C_SPA_STATUS <> '2');

    CurAncPositionActions CUR_ANC_POSITION_ACTIONS%rowtype;
    blnResult             boolean;
  begin
    blnResult  := true;

    open CUR_ANC_POSITION_ACTIONS;

    fetch CUR_ANC_POSITION_ACTIONS
     into CurAncPositionActions;

    if CUR_ANC_POSITION_ACTIONS%found then
      blnResult  := false;
    end if;

    close CUR_ANC_POSITION_ACTIONS;

    return blnResult;
  end IsANCPosActionsTerminated;

  /* V�rifie que toutes les positions de l'ANC sont en statut "Boucl�" */
  function IsClosableANC(aSQM_ANC_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    return boolean
  is
    cursor CUR_ANC_POSITION
    is
      select SAP.SQM_ANC_POSITION_ID
        from SQM_ANC_POSITION SAP
       where SAP.SQM_ANC_ID = aSQM_ANC_ID
         and SAP.C_ANC_POS_STATUS <> '4'
         and SAP.C_ANC_POS_STATUS <> '2';   -- Statut Boucl�

    CurAncPosition CUR_ANC_POSITION%rowtype;
    blnResult      boolean;
  begin
    blnResult  := true;

    open CUR_ANC_POSITION;

    fetch CUR_ANC_POSITION
     into CurAncPosition;

    if CUR_ANC_POSITION%found then
      blnResult  := false;
    end if;

    close CUR_ANC_POSITION;

    return blnResult;
  end IsClosableANC;

/**************************************************** Proc�dures publiques *********************************************************/

  /* Validation d'une ANC */
  procedure ANCValidation(
    aSQM_ANC_ID          in     SQM_ANC.SQM_ANC_ID%type
  , aResultat            in out MaxVarchar2
  , aUseExternalProc            boolean default true
  , aANC_VALIDATION_DATE in     SQM_ANC.ANC_VALIDATION_DATE%type default null   -- Date validation/refus
  , aPC_ANC_USER2_ID     in     SQM_ANC.PC_ANC_USER3_ID%type default null
  )   -- User validation/refus
  is
    aANC_VALIDATION_DURATION SQM_ANC.ANC_VALIDATION_DURATION%type;
    LocANC_VALIDATION_DATE   SQM_ANC.ANC_VALIDATION_DATE%type;
    LocPC_ANC_USER2_ID       SQM_ANC.PC_ANC_USER2_ID%type;
    aANC_DATE                SQM_ANC.ANC_DATE%type;
  begin
    aResultat               := '';
    LocANC_VALIDATION_DATE  := nvl(aANC_VALIDATION_DATE, sysdate);
    LocPC_ANC_USER2_ID      := nvl(aPC_ANC_USER2_ID, PCS.PC_PUBLIC.GETUSERID);

    -- Procedure avant Validation d'ANC
    if aUSeExternalProc then
      aResultat  := ExecuteConfiguratedProc('SQM_PROC_ANC_VALIDATION', aSQM_ANC_ID);
    end if;

    -- Date de cr�ation de l'ANC
    select nvl(ANC_DATE, A_DATECRE)
      into aANC_DATE
      from SQM_ANC
     where SQM_ANC_ID = aSQM_ANC_ID;

    -- Dur�e exacte de validation
    GetExactDuration(aANC_DATE, LocANC_VALIDATION_DATE, aResultat, aANC_VALIDATION_DURATION);

    if    trim(aResultat) = ''
       or trim(aResultat) is null then
      -- S'il existe des positions en status "A valider" pour l'ANC -> Abandon
      if ExistPositionToValidate(aSQM_ANC_ID) then
        aResultat  := PCS.PC_FUNCTIONS.TRANSLATEWORD('Il existe des positions en status � valider.');
      else
        update SQM_ANC
           set C_ANC_STATUS = '3'   --Status "Valid�".
             , ANC_VALIDATION_DATE = LocANC_VALIDATION_DATE
             , ANC_VALIDATION_DURATION = aANC_VALIDATION_DURATION
             , PC_ANC_USER2_ID = LocPC_ANC_USER2_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
         where SQM_ANC_ID = aSQM_ANC_ID;
      end if;
    end if;
  end ANCValidation;

  /* Affectation d'une ANC */
  procedure ANCAllocation(
    aSQM_ANC_ID          in     SQM_ANC.SQM_ANC_ID%type
  , aPC_ANC_USER4_ID     in     PCS.PC_USER.PC_USER_ID%type
  , aResultat            in out MaxVarchar2
  , aUseExternalProc            boolean default true
  , aANC_ALLOCATION_DATE in     SQM_ANC.ANC_ALLOCATION_DATE%type default null
  , aPC_ANC_USER3_ID     in     SQM_ANC.PC_ANC_USER3_ID%type default null
  )
  is
    aANC_ALLOCATION_DURATION SQM_ANC.ANC_ALLOCATION_DURATION%type;
    LocANC_ALLOCATION_DATE   SQM_ANC.ANC_ALLOCATION_DATE%type;
    LocPC_ANC_USER3_ID       SQM_ANC.PC_ANC_USER3_ID%type;
    aANC_VALIDATION_DATE     SQM_ANC.ANC_VALIDATION_DATE%type;
  begin
    aResultat               := '';
    LocANC_ALLOCATION_DATE  := nvl(aANC_ALLOCATION_DATE, sysdate);
    LocPC_ANC_USER3_ID      := nvl(aPC_ANC_USER3_ID, PCS.PC_PUBLIC.GETUSERID);

    -- Procedure avant Affectation d'ANC
    if aUseExternalProc then
      aResultat  := ExecuteConfiguratedProc('SQM_PROC_ANC_ALLOCATION', aSQM_ANC_ID);
    end if;

    -- Date de validation de l'ANC
    select ANC_VALIDATION_DATE
      into aANC_VALIDATION_DATE
      from SQM_ANC
     where SQM_ANC_ID = aSQM_ANC_ID;

    -- Dur�e exacte du refus
    GetExactDuration(aANC_VALIDATION_DATE, LocANC_ALLOCATION_DATE, aResultat, aANC_ALLOCATION_DURATION);

    if    trim(aResultat) = ''
       or trim(aResultat) is null then
      update SQM_ANC
         set PC_ANC_USER4_ID = aPC_ANC_USER4_ID
           , ANC_ALLOCATION_DATE = LocANC_ALLOCATION_DATE
           , ANC_ALLOCATION_DURATION = ANC_ALLOCATION_DURATION
           , C_ANC_STATUS = '4'   --Affect�e
           , PC_ANC_USER3_ID = LocPC_ANC_USER3_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
       where SQM_ANC_ID = aSQM_ANC_ID;
    end if;
  end ANCAllocation;

  /* Refus d'une ANC */
  procedure ANCRejection(
    aSQM_ANC_ID          in     SQM_ANC.SQM_ANC_ID%type
  , aResultat            in out MaxVarchar2
  , aUseExternalProc            boolean default true
  , aANC_VALIDATION_DATE in     SQM_ANC.ANC_VALIDATION_DATE%type default null   -- Date validation/refus
  , aPC_ANC_USER2_ID     in     SQM_ANC.PC_ANC_USER3_ID%type default null
  )   -- User validation/refus
  is
    aANC_VALIDATION_DURATION SQM_ANC.ANC_VALIDATION_DURATION%type;
    LocANC_VALIDATION_DATE   SQM_ANC.ANC_VALIDATION_DATE%type;
    LocPC_ANC_USER2_ID       SQM_ANC.PC_ANC_USER2_ID%type;
    aANC_DATE                SQM_ANC.ANC_DATE%type;
  begin
    aResultat               := '';
    LocANC_VALIDATION_DATE  := nvl(aANC_VALIDATION_DATE, sysdate);
    LocPC_ANC_USER2_ID      := nvl(aPC_ANC_USER2_ID, PCS.PC_PUBLIC.GETUSERID);

    -- Procedure avant Refus d' une ANC.
    if aUseExternalProc then
      aResultat  := ExecuteConfiguratedProc('SQM_PROC_ANC_REJECTION', aSQM_ANC_ID);
    end if;

    -- Date de cr�ation de l'ANC
    select nvl(ANC_DATE, A_DATECRE)
      into aANC_DATE
      from SQM_ANC
     where SQM_ANC_ID = aSQM_ANC_ID;

    -- Dur�e exacte de validation
    GetExactDuration(aANC_DATE, LocANC_VALIDATION_DATE, aResultat, aANC_VALIDATION_DURATION);

    if    trim(aResultat) = ''
       or trim(aResultat) is null then
      -- S'il existe des positions en status <> "refus�e" pour l'ANC -> Abandon
      if ExistPositionNotRejected(aSQM_ANC_ID) then
        aResultat  := PCS.PC_FUNCTIONS.TRANSLATEWORD('Il existe des positions en status diff�rent de refus�e.');
      -- Mise � jour ANC
      else
        update SQM_ANC
           set C_ANC_STATUS = '2'   --Status "Refus�e".
             , ANC_VALIDATION_DATE = LocANC_VALIDATION_DATE
             , ANC_VALIDATION_DURATION = aANC_VALIDATION_DURATION
             , PC_ANC_USER2_ID = LocPC_ANC_USER2_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
         where SQM_ANC_ID = aSQM_ANC_ID;
      end if;
    end if;
  end ANCRejection;

  /* Validation d'une position d'ANC */
  procedure ANCPosValidation(
    aSQM_ANC_POSITION_ID in     SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type
  , aResultat            in out MaxVarchar2
  , aUseExternalProc            boolean default true
  , aPC_SAP_USER1_ID     in     SQM_ANC_POSITION.PC_SAP_USER1_ID%type default null
  , aSAP_VALIDATION_DATE in     SQM_ANC_POSITION.SAP_VALIDATION_DATE%type default null
  )
  is
    LocSAP_VALIDATION_DATE   SQM_ANC_POSITION.SAP_VALIDATION_DATE%type;
    LocPC_SAP_USER1_ID       SQM_ANC_POSITION.PC_SAP_USER1_ID%type;
    aSAP_VALIDATION_DURATION SQM_ANC_POSITION.SAP_VALIDATION_DURATION%type;
    aSAP_CREATION_DATE       SQM_ANC_POSITION.SAP_CREATION_DATE%type;
  begin
    aResultat               := '';
    LocSAP_VALIDATION_DATE  := nvl(aSAP_VALIDATION_DATE, sysdate);
    LocPC_SAP_USER1_ID      := nvl(aPC_SAP_USER1_ID, PCS.PC_PUBLIC.GETUSERID);

    -- Procedure avant validation d'une position d'ANC
    if aUseExternalProc then
      aResultat  := ExecuteConfiguratedProc('SQM_PROC_ANC_POS_VALIDATION', aSQM_ANC_POSITION_ID);
    end if;

    -- Date de cr�ation de la position d'ANC
    select nvl(SAP_CREATION_DATE, A_DATECRE)
      into aSAP_CREATION_DATE
      from SQM_ANC_POSITION
     where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

    -- Dur�e exacte de validation
    GetExactDuration(aSAP_CREATION_DATE, LocSAP_VALIDATION_DATE, aResultat, aSAP_VALIDATION_DURATION);

    if    trim(aResultat) = ''
       or trim(aResultat) is null then
      update SQM_ANC_POSITION
         set C_ANC_POS_STATUS = '3'   --Status "Valid�e".
           , SAP_VALIDATION_DATE = LocSAP_VALIDATION_DATE
           , SAP_VALIDATION_DURATION = aSAP_VALIDATION_DURATION
           , PC_SAP_USER1_ID = LocPC_SAP_USER1_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
       where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;
    end if;
  end ANCPosValidation;

  /* Bouclement d'une position d'ANC */
  procedure ANCPosClosing(
    aSQM_ANC_POSITION_ID in     SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type
  , aResultat            in out MaxVarchar2
  , aUseExternalProc            boolean default true
  , aPC_SAP_USER2_ID     in     SQM_ANC_POSITION.PC_SAP_USER2_ID%type default null   -- User Bouclement
  , aSAP_CLOSING_DATE    in     SQM_ANC_POSITION.SAP_CLOSING_DATE%type default null
  )   -- Date bouclement
  is
    nSAP_DIRECT_COST            number;
    nSAP_PREVENTIVE_COST        number;
    nANC_DIRECT_COST            number;
    nANC_PREVENTIVE_COST        number;
    locSAP_CLOSING_DATE         SQM_ANC_POSITION.SAP_CLOSING_DATE%type;
    locPC_SAP_USER2_ID          SQM_ANC_POSITION.PC_SAP_USER2_ID%type;
    aSAP_VALIDATION_DATE        SQM_ANC_POSITION.SAP_VALIDATION_DATE%type;
    aSAP_CREATION_DATE          SQM_ANC_POSITION.SAP_CREATION_DATE%type;
    aSAP_VALIDATION_DURATION    SQM_ANC_POSITION.SAP_VALIDATION_DURATION%type;
    aSAP_PROCESSING_DURATION    SQM_ANC_POSITION.SAP_PROCESSING_DURATION%type;
    aSAP_TOTAL_DURATION         SQM_ANC_POSITION.SAP_TOTAL_DURATION%type;
    nSQM_ANC_ID                 SQM_ANC.SQM_ANC_ID%type;
    aANC_CLOSING_DATE           SQM_ANC.ANC_CLOSING_DATE%type;
    aANC_DATE                   SQM_ANC.ANC_DATE%type;
    aANC_VALIDATION_DATE        SQM_ANC.ANC_VALIDATION_DATE%type;
    aANC_PARTNER_DATE           SQM_ANC.ANC_PARTNER_DATE%type;
    aANC_PRINT_RECEPT_DATE      SQM_ANC.ANC_PRINT_RECEPT_DATE%type;
    aANC_ALLOCATION_DATE        SQM_ANC.ANC_ALLOCATION_DATE%type;
    aANC_VALIDATION_DURATION    SQM_ANC.ANC_VALIDATION_DURATION%type;
    aANC_REPLY_DURATION         SQM_ANC.ANC_REPLY_DURATION%type;
    aANC_ALLOCATION_DURATION    SQM_ANC.ANC_ALLOCATION_DURATION%type;
    aANC_PROCESSING_DURATION    SQM_ANC.ANC_PROCESSING_DURATION%type;
    aANC_TOTAL_DURATION         SQM_ANC.ANC_TOTAL_DURATION%type;
    blnUpdateANC_REPLY_DURATION boolean;
  begin
    aResultat                    := '';
    LocSAP_CLOSING_DATE          := nvl(aSAP_CLOSING_DATE, sysdate);
    locPC_SAP_USER2_ID           := nvl(aPC_SAP_USER2_ID, PCS.PC_PUBLIC.GetUserId);
    aANC_CLOSING_DATE            := LocSAP_CLOSING_DATE;
    blnUpdateANC_REPLY_DURATION  := true;

    -- Procedure avant Bouclement d'une position d'ANC
    if aUSeExternalProc then
      aResultat  := ExecuteConfiguratedProc('SQM_PROC_ANC_POS_CLOSING', aSQM_ANC_POSITION_ID);
    end if;

    if    trim(aResultat) = ''
       or trim(aResultat) is null then
      -- La Pos. � au moins une mesure imm�diate, pr�ventive ainsi qu'une cause
      if IsPositionWithActions(aSQM_ANC_POSITION_ID) then
        -- L'ANC Doit �tre en statut "Affect�e"
        if IsANCAllocated(aSQM_ANC_POSITION_ID) then
          -- L'ensemble des mesure li�es � la positions doivent �tre en status "Termin�"
          if IsANCPosActionsTerminated(aSQM_ANC_POSITION_ID) then
            -- R�cup�ration date cr�ation et validation de la position d'ANC
            select nvl(SAP_CREATION_DATE, A_DATECRE)
                 , SAP_VALIDATION_DATE
              into aSAP_CREATION_DATE
                 , aSAP_VALIDATION_DATE
              from SQM_ANC_POSITION
             where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

            -- Calcul dur�e de validation
            GetExactDuration(aSAP_CREATION_DATE, aSAP_VALIDATION_DATE, aResultat, aSAP_VALIDATION_DURATION);
            -- Calcul dur�e de traitement
            GetExactDuration(aSAP_VALIDATION_DATE, aSAP_CLOSING_DATE, aResultat, aSAP_PROCESSING_DURATION);
            -- Calcul dur�e totale
            GetExactDuration(aSAP_CREATION_DATE, aSAP_CLOSING_DATE, aResultat, aSAP_TOTAL_DURATION);
            -- Co�t position d'ANC
            CalcANCPositionCost(aSQM_ANC_POSITION_ID);

            -- Mise � jour position ANC.
            update SQM_ANC_POSITION
               set C_ANC_POS_STATUS = '4'   -- Boucl�
                 , SAP_CLOSING_DATE = LocSAP_CLOSING_DATE
                 , PC_SAP_USER2_ID = locPC_SAP_USER2_ID   -- User bouclement
                 , SAP_VALIDATION_DURATION = aSAP_VALIDATION_DURATION
                 , SAP_PROCESSING_DURATION = aSAP_PROCESSING_DURATION
                 , SAP_TOTAL_DURATION = aSAP_TOTAL_DURATION
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
             where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

            -- On r�cup�re l'ANC de la position
            begin
              select SQM_ANC_ID
                into nSQM_ANC_ID
                from SQM_ANC_POSITION
               where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;
            exception
              when no_data_found then
                raise;
            end;

            -- Si toutes les positions de l'ANC sont en statut boucl� ou refus�es :
            if IsClosableANC(nSQM_ANC_ID) then
              -- R�cup�ration date cr�ation et date validation de l'ANC
              select nvl(ANC_DATE, A_DATECRE)
                   , ANC_VALIDATION_DATE
                   , ANC_ALLOCATION_DATE
                into aANC_DATE
                   , aANC_VALIDATION_DATE
                   , aANC_ALLOCATION_DATE
                from SQM_ANC
               where SQM_ANC_ID = nSQM_ANC_ID;

              -- R�cup�ration date R�clamation tiers de l'ANC et date impression
              begin
                select ANC_PARTNER_DATE
                     , ANC_PRINT_RECEPT_DATE
                  into aANC_PARTNER_DATE
                     , aANC_PRINT_RECEPT_DATE
                  from SQM_ANC
                 where SQM_ANC_ID = nSQM_ANC_ID;
              exception
                when no_data_found then
                  begin
                    blnUpdateANC_REPLY_DURATION  := false;
                    aANC_REPLY_DURATION          := null;
                  end;
              end;

              -- Calcul dur�e de r�ponse ANC
              if blnUpdateANC_REPLY_DURATION then
                GetExactDuration(aANC_PARTNER_DATE, aANC_PRINT_RECEPT_DATE, aResultat, aANC_REPLY_DURATION);
              end if;

              -- Calcul dur�e de validation ANC
              GetExactDuration(aANC_DATE, aANC_VALIDATION_DATE, aResultat, aANC_VALIDATION_DURATION);
              -- Calcul dur�e d'affectation ANC
              GetExactDuration(aANC_VALIDATION_DATE, aANC_ALLOCATION_DATE, aResultat, aANC_ALLOCATION_DURATION);
              -- Calcul dur�e de traitement ANC
              GetExactDuration(aANC_ALLOCATION_DATE, aANC_CLOSING_DATE, aResultat, aANC_PROCESSING_DURATION);
              -- Calcul dur�e de totale ANC
              GetExactDuration(aANC_DATE, aANC_CLOSING_DATE, aResultat, aANC_TOTAL_DURATION);
              -- Calcul des co�t mesure imm�diates et pr�ventives ANC
              CalcANCCost(nSQM_ANC_ID);

              -- Bouclement de l'ANC
              update SQM_ANC
                 set C_ANC_STATUS = '5'   -- Boucl�
                   , ANC_CLOSING_DATE = aANC_CLOSING_DATE
                   , ANC_VALIDATION_DURATION = aANC_VALIDATION_DURATION
                   , ANC_REPLY_DURATION = aANC_REPLY_DURATION
                   , ANC_ALLOCATION_DURATION = aANC_ALLOCATION_DURATION
                   , ANC_PROCESSING_DURATION = aANC_PROCESSING_DURATION
                   , ANC_TOTAL_DURATION = aANC_TOTAL_DURATION
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
               where SQM_ANC_ID = nSQM_ANC_ID;
            end if;
          else
            aResultat  := PCS.PC_FUNCTIONS.TRANSLATEWORD('L''ensemble des actions et corrections li�es � la position doivent �tre en status Termin�.');
          end if;
        else
          aResultat  := PCS.PC_FUNCTIONS.TRANSLATEWORD('La NC doit �tre en status Affect�e, pour le bouclement des positions.');
        end if;
      else
        aResultat  := PCS.PC_FUNCTIONS.TRANSLATEWORD('Une position de NC doit comporter au moins une correction, une cause et une action.');
      end if;
    end if;
  end ANCPosClosing;

  /* Refus d'une position d'ANC */
  procedure ANCPosRejection(
    aSQM_ANC_POSITION_ID in     SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type
  , aResultat            in out MaxVarchar2
  , aUseExternalProc            boolean default true
  , aPC_SAP_USER1_ID     in     SQM_ANC_POSITION.PC_SAP_USER1_ID%type default null
  , aSAP_VALIDATION_DATE in     SQM_ANC_POSITION.SAP_VALIDATION_DATE%type default null
  )
  is
    LocSAP_VALIDATION_DATE   SQM_ANC_POSITION.SAP_VALIDATION_DATE%type;
    LocPC_SAP_USER1_ID       SQM_ANC_POSITION.PC_SAP_USER1_ID%type;
    aSAP_VALIDATION_DURATION SQM_ANC_POSITION.SAP_VALIDATION_DURATION%type;
    aSAP_CREATION_DATE       SQM_ANC_POSITION.SAP_CREATION_DATE%type;
  begin
    aResultat               := '';
    LocSAP_VALIDATION_DATE  := nvl(aSAP_VALIDATION_DATE, sysdate);
    LocPC_SAP_USER1_ID      := nvl(aPC_SAP_USER1_ID, PCS.PC_PUBLIC.GetUserId);

    -- Procedure avant Refus d'une position d'ANC
    if aUseExternalProc then
      aResultat  := ExecuteConfiguratedProc('SQM_PROC_ANC_POS_REJECTION', aSQM_ANC_POSITION_ID);
    end if;

    -- Date de cr�ation de la position d'ANC
    select nvl(SAP_CREATION_DATE, A_DATECRE)
      into aSAP_CREATION_DATE
      from SQM_ANC_POSITION
     where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

    -- Dur�e exacte de validation
    GetExactDuration(aSAP_CREATION_DATE, locSAP_VALIDATION_DATE, aResultat, aSAP_VALIDATION_DURATION);

    if    trim(aResultat) = ''
       or trim(aResultat) is null then
      update SQM_ANC_POSITION
         set C_ANC_POS_STATUS = '2'   --Status "Refus�e".
           , SAP_VALIDATION_DATE = LocSAP_VALIDATION_DATE
           , SAP_VALIDATION_DURATION = aSAP_VALIDATION_DURATION
           , PC_SAP_USER1_ID = LocPC_SAP_USER1_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
       where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;
    end if;
  end ANCPosRejection;

  /* Bouclement d'une mesure imm�diate */
  procedure DirectActionClosing(
    aSQM_ANC_DIRECT_ACTION_ID in     SQM_ANC_DIRECT_ACTION.SQM_ANC_DIRECT_ACTION_ID%type
  , aResultat                 in out MaxVarchar2
  , aUseExternalProc                 boolean default true
  , aPC_SDA_USER2_ID                 SQM_ANC_DIRECT_ACTION.PC_SDA_USER2_ID%type default null
  , aSDA_END_DATE                    SQM_ANC_DIRECT_ACTION.SDA_END_DATE%type default null
  )
  is
    aSDA_COST          number;
    aSDA_CREATION_DATE SQM_ANC_DIRECT_ACTION.A_DATECRE%type;
    aDOC_DOCUMENT_ID   number;
    aCalendarID        number;
    aSDA_DURATION      SQM_ANC_DIRECT_ACTION.SDA_DURATION%type;
    LocSDA_END_DATE    SQM_ANC_DIRECT_ACTION.SDA_END_DATE%type;
    LocPC_SDA_USER2_ID SQM_ANC_DIRECT_ACTION.PC_SDA_USER2_ID%type;
  begin
    aSDA_COST           := 0;
    aDOC_DOCUMENT_ID    := 0;
    LocSDA_END_DATE     := nvl(aSDA_END_DATE, sysdate);
    LocPC_SDA_USER2_ID  := nvl(aPC_SDA_USER2_ID, PCS.PC_PUBLIC.GETUSERID);
    -- Procedure avant Bouclement d'une mesure imm�diate
    aResultat           := '';

    if aUseExternalProc then
      aResultat  := ExecuteConfiguratedProc('SQM_PROC_ANC_DA_CLOSING', aSQM_ANC_DIRECT_ACTION_ID);
    end if;

    if    trim(aResultat) = ''
       or trim(aResultat) is null then
      -- Recherche du co�t de la mesure imm�diate
      begin
        select SDA_COST
             , SDA_CREATION_DATE
          into aSDA_COST
             , aSDA_CREATION_DATE
          from SQM_ANC_DIRECT_ACTION
         where SQM_ANC_DIRECT_ACTION_ID = aSQM_ANC_DIRECT_ACTION_ID
           and SDA_COST is not null;
      exception
        when no_data_found then
          aResultat  := PCS.PC_FUNCTIONS.TRANSLATEWORD('Un co�t doit �tre renseign� pour la correction.');
      end;

      -- S'agit-t'il d'un retour client ?
      begin
        select SAP.DOC_DOCUMENT2_ID
          into aDOC_DOCUMENT_ID
          from SQM_ANC_POSITION SAP
             , SQM_ANC_DIRECT_ACTION SDA
         where SDA.SQM_ANC_DIRECT_ACTION_ID = aSQM_ANC_DIRECT_ACTION_ID
           and SDA.SQM_ANC_POSITION_ID = SAP.SQM_ANC_POSITION_ID
           and SAP.SAP_RETURN = 1
           and SAP.DOC_DOCUMENT2_ID is null;

        aResultat  := PCS.PC_FUNCTIONS.TRANSLATEWORD('La r�f�rence du retour client doit �tre renseign�e.');
      exception
        when others then
          null;
      end;

      -- Calendrier par d�faut de la soci�t�
      aCalendarID    := FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar;
      -- Calcul de la dur�e de la mesure
      aSDA_DURATION  := FAL_SCHEDULE_FUNCTIONS.GetDuration(null, null, null, null, null, aCalendarID, trunc(aSDA_CREATION_DATE), trunc(LocSDA_END_DATE) );

      -- Si co�t <> 0 et (retour/ref retour)
      if    trim(aResultat) = ''
         or trim(aResultat) is null then
        update SQM_ANC_DIRECT_ACTION
           set SDA_DURATION = aSDA_DURATION
             , SDA_END_DATE = LocSDA_END_DATE
             , PC_SDA_USER2_ID = LocPC_SDA_USER2_ID
             , C_SDA_STATUS = '2'   --Termin�
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
         where SQM_ANC_DIRECT_ACTION_ID = aSQM_ANC_DIRECT_ACTION_ID;
      end if;
    end if;
  end DirectActionClosing;

  /* Bouclement d'une mesure imm�diate */
  procedure DirectActionReOpening(aSQM_ANC_DIRECT_ACTION_ID in SQM_ANC_DIRECT_ACTION.SQM_ANC_DIRECT_ACTION_ID%type, aResultat in out MaxVarchar2)
  is
  begin
    -- R�ouverture de la mesure imm�diate
    update SQM_ANC_DIRECT_ACTION
       set C_SDA_STATUS = '1'
     where SQM_ANC_DIRECT_ACTION_ID = aSQM_ANC_DIRECT_ACTION_ID
       and C_SDA_STATUS = '2';

    -- Qui entraine r�ouverture de la position
    update SQM_ANC_POSITION
       set C_ANC_POS_STATUS = '3'
     where C_ANC_POS_STATUS = '4'
       and SQM_ANC_POSITION_ID = (select SDA.SQM_ANC_POSITION_ID
                                    from SQM_ANC_DIRECT_ACTION SDA
                                   where SDA.SQM_ANC_DIRECT_ACTION_ID = aSQM_ANC_DIRECT_ACTION_ID);

    -- Qui entraine la r�ouverture de l'ANC
    update SQM_ANC
       set C_ANC_STATUS = '4'
     where C_ANC_STATUS = '5'
       and SQM_ANC_ID = (select POS.SQM_ANC_ID
                           from SQM_ANC_POSITION POS
                              , SQM_ANC_DIRECT_ACTION SDA
                          where POS.SQM_ANC_POSITION_ID = SDA.SQM_ANC_POSITION_ID
                            and SDA.SQM_ANC_DIRECT_ACTION_ID = aSQM_ANC_DIRECT_ACTION_ID);
  end DirectActionReOpening;

  /* Bouclement d'une mesure pr�ventive */
  procedure PreventiveActionClosing(
    aSQM_ANC_PREVENTIVE_ACTION_ID in     SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_PREVENTIVE_ACTION_ID%type
  , aResultat                     in out MaxVarchar2
  , aUseExternalProc                     boolean default true
  , aPC_SPA_USER2_ID                     SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER2_ID%type default null
  , aSPA_END_DATE                        SQM_ANC_PREVENTIVE_ACTION.SPA_END_DATE%type default null
  )
  is
    aSPA_COST          number;
    aCalendarID        number;
    aSPA_CREATION_DATE SQM_ANC_PREVENTIVE_ACTION.A_DATECRE%type;
    aSPA_DURATION      SQM_ANC_PREVENTIVE_ACTION.SPA_DURATION%type;
    LocSPA_END_DATE    SQM_ANC_PREVENTIVE_ACTION.SPA_END_DATE%type;
    LocPC_SPA_USER2_ID SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER2_ID%type;
  begin
    aSPA_COST           := 0;
    LocSPA_END_DATE     := nvl(aSPA_END_DATE, sysdate);
    LocPC_SPA_USER2_ID  := nvl(aPC_SPA_USER2_ID, PCS.PC_PUBLIC.GETUSERID);
    -- Procedure avant Bouclement d'une mesure pr�ventive
    aResultat           := '';

    if aUseExternalProc then
      aResultat  := ExecuteConfiguratedProc('SQM_PROC_ANC_PA_CLOSING', aSQM_ANC_PREVENTIVE_ACTION_ID);
    end if;

    if    trim(aResultat) = ''
       or trim(aResultat) is null then
      -- Recherche du co�t de la mesure imm�diate
      begin
        select SPA_COST
             , SPA_CREATION_DATE
          into aSPA_COST
             , aSPA_CREATION_DATE
          from SQM_ANC_PREVENTIVE_ACTION
         where SQM_ANC_PREVENTIVE_ACTION_ID = aSQM_ANC_PREVENTIVE_ACTION_ID
           and SPA_COST is not null;
      exception
        when no_data_found then
          aResultat  := PCS.PC_FUNCTIONS.TRANSLATEWORD('Un co�t doit �tre renseign� pour l''action.');
      end;

      -- Calendrier par d�faut de la soci�t�
      aCalendarID    := FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar;
      -- Calcul de la dur�e de la mesure
      aSPA_DURATION  := FAL_SCHEDULE_FUNCTIONS.GetDuration(null, null, null, null, null, aCalendarID, trunc(aSPA_CREATION_DATE), trunc(LocSPA_END_DATE) );

      -- Si co�t <> 0
      if    trim(aResultat) = ''
         or trim(aResultat) is null then
        update SQM_ANC_PREVENTIVE_ACTION
           set SPA_DURATION = aSPA_DURATION
             , SPA_END_DATE = LocSPA_END_DATE
             , PC_SPA_USER2_ID = LocPC_SPA_USER2_ID
             , C_SPA_STATUS = '2'   --Termin�
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
         where SQM_ANC_PREVENTIVE_ACTION_ID = aSQM_ANC_PREVENTIVE_ACTION_ID;
      end if;
    end if;
  end PreventiveActionClosing;

  /* Bouclement d'une mesure pr�ventive */
  procedure PreventiveActionReopening(
    aSQM_ANC_PREVENTIVE_ACTION_ID in     SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_PREVENTIVE_ACTION_ID%type
  , aResultat                     in out MaxVarchar2
  )
  is
  begin
    -- R�ouverture de la mesure pr�ventive
    update SQM_ANC_PREVENTIVE_ACTION
       set C_SPA_STATUS = '1'
     where SQM_ANC_PREVENTIVE_ACTION_ID = aSQM_ANC_PREVENTIVE_ACTION_ID
       and C_SPA_STATUS = '2';

    -- Qui entraine r�ouverture de la position
    update SQM_ANC_POSITION
       set C_ANC_POS_STATUS = '3'
     where C_ANC_POS_STATUS = '4'
       and SQM_ANC_POSITION_ID = (select SPA.SQM_ANC_POSITION_ID
                                    from SQM_ANC_PREVENTIVE_ACTION SPA
                                   where SPA.SQM_ANC_PREVENTIVE_ACTION_ID = aSQM_ANC_PREVENTIVE_ACTION_ID);

    -- Qui entraine la r�ouverture de l'ANC
    update SQM_ANC
       set C_ANC_STATUS = '4'
     where C_ANC_STATUS = '5'
       and SQM_ANC_ID = (select POS.SQM_ANC_ID
                           from SQM_ANC_POSITION POS
                              , SQM_ANC_PREVENTIVE_ACTION SPA
                          where POS.SQM_ANC_POSITION_ID = SPA.SQM_ANC_POSITION_ID
                            and SPA.SQM_ANC_PREVENTIVE_ACTION_ID = aSQM_ANC_PREVENTIVE_ACTION_ID);
  end PreventiveActionReOpening;

  /* Procedure qui Renvoie un nouveau num�ro d'ANC suivant le type celle-ci. */
  procedure GetANCNumber(aC_ANC_TYPE SQM_ANC.C_ANC_TYPE%type, aNewANC_NUMBER in out SQM_ANC.ANC_NUMBER%type)
  is
    gauge_id           DOC_GAUGE.DOC_GAUGE_ID%type;
    gauge_numbering_id DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
  begin
    -- R�cup�ration du gabarit pour le type d'ANC
    gauge_id  := SQM_ANC_FUNCTIONS.GetDocGaugeID(aC_ANC_TYPE);

    if gauge_id = 0 then
      if aC_ANC_TYPE = '1' then
        raise_application_error(-20010
                              , PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Gabarit de num�rotation NC interne non trouv�! Configuration : SQM_ANC_INTERN_GAUGE.')
                               );
      elsif aC_ANC_TYPE = '2' then
        raise_application_error
                           (-20010
                          , PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Gabarit de num�rotation NC fournisseur non trouv�! Configuration : SQM_ANC_SUPPLIER_GAUGE.')
                           );
      elsif aC_ANC_TYPE = '3' then
        raise_application_error(-20010
                              , PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Gabarit de num�rotation NC client non trouv�! Configuration : SQM_ANC_CUSTOM_GAUGE.')
                               );
      else
        raise_application_error(-20010, PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Type de la NC inconnu.') );
      end if;
    end if;

    -- Recherche du type de num�rotation
    begin
      select GAU.DOC_GAUGE_ID
           , GAU.DOC_GAUGE_NUMBERING_ID
        into gauge_id
           , gauge_numbering_id
        from DOC_GAUGE GAU
           , DOC_GAUGE_NUMBERING GAN
       where GAU.DOC_GAUGE_ID = gauge_id
         and GAN.DOC_GAUGE_NUMBERING_ID(+) = GAU.DOC_GAUGE_NUMBERING_ID
         and DOC_GAUGE_ID not in(select DOC_GAUGE_ID
                                   from DOC_GAUGE_STRUCTURED);
    exception
      when no_data_found then
        raise_application_error(-20010, PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Gabarit non trouv�!') );
    end;

    /* Et on recherche le nouveau Num d'ANC */
    DOC_DOCUMENT_FUNCTIONS.GetDocumentNumber(gauge_id, gauge_numbering_id, aNewANC_NUMBER);
  end GetANCNumber;

  /**
  * Procedure
  * Description GetANCPositionNumber
  *    Fonction qui renvoie un nouveau num�ro de position d'ANC
  * @author ECA
  * @version 2003
  * @lastUpdate
  */
  procedure GetANCPositionNumber(aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type, aSAP_NUMBER in out integer)
  is
    cursor CUR_MAX_POS_NUM
    is
      select nvl(max(SAP_NUMBER), 0) MAX_NUM
        from SQM_ANC_POSITION
       where SQM_ANC_ID = aSQM_ANC_ID;

    CurMaxPosNum CUR_MAX_POS_NUM%rowtype;
  begin
    open CUR_MAX_POS_NUM;

    fetch CUR_MAX_POS_NUM
     into CurMaxPosNum;

    if CUR_MAX_POS_NUM%found then
      aSAP_NUMBER  := CurMaxPosNum.MAX_NUM + 10;
    else
      aSAP_NUMBER  := 10;
    end if;

    close CUR_MAX_POS_NUM;
  end;

  /* Fonction qui renvoie la charact�risation de type lot d'un d�tail position */
  function GetLotCharacterization(aDOC_POSITION_DETAIL_ID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return varchar2
  is
    cursor CUR_DOC_POS_DETAIL
    is
      select PDE.PDE_CHARACTERIZATION_VALUE_1
           , PDE.PDE_CHARACTERIZATION_VALUE_2
           , PDE.PDE_CHARACTERIZATION_VALUE_3
           , PDE.PDE_CHARACTERIZATION_VALUE_4
           , PDE.PDE_CHARACTERIZATION_VALUE_5
           , nvl(CHA1.C_CHARACT_TYPE, '0') TYPE_CHA1
           , nvl(CHA2.C_CHARACT_TYPE, '0') TYPE_CHA2
           , nvl(CHA3.C_CHARACT_TYPE, '0') TYPE_CHA3
           , nvl(CHA4.C_CHARACT_TYPE, '0') TYPE_CHA4
           , nvl(CHA5.C_CHARACT_TYPE, '0') TYPE_CHA5
        from DOC_POSITION_DETAIL PDE
           , GCO_CHARACTERIZATION CHA1
           , GCO_CHARACTERIZATION CHA2
           , GCO_CHARACTERIZATION CHA3
           , GCO_CHARACTERIZATION CHA4
           , GCO_CHARACTERIZATION CHA5
       where PDE.DOC_POSITION_DETAIL_ID = aDOC_POSITION_DETAIL_ID
         and PDE.GCO_CHARACTERIZATION_ID = CHA1.GCO_CHARACTERIZATION_ID(+)
         and PDE.GCO_GCO_CHARACTERIZATION_ID = CHA2.GCO_CHARACTERIZATION_ID(+)
         and PDE.GCO2_GCO_CHARACTERIZATION_ID = CHA3.GCO_CHARACTERIZATION_ID(+)
         and PDE.GCO3_GCO_CHARACTERIZATION_ID = CHA4.GCO_CHARACTERIZATION_ID(+)
         and PDE.GCO4_GCO_CHARACTERIZATION_ID = CHA5.GCO_CHARACTERIZATION_ID(+);

    CurDocPosDetail CUR_DOC_POS_DETAIL%rowtype;
    vLotCharact     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
  begin
    open CUR_DOC_POS_DETAIL;

    fetch CUR_DOC_POS_DETAIL
     into CurDocPosDetail;

    if CUR_DOC_POS_DETAIL%found then
      if CurDocPosDetail.TYPE_CHA1 = '4' then
        vLotCharact  := CurDocPosDetail.PDE_CHARACTERIZATION_VALUE_1;
      elsif CurDocPosDetail.TYPE_CHA2 = '4' then
        vLotCharact  := CurDocPosDetail.PDE_CHARACTERIZATION_VALUE_2;
      elsif CurDocPosDetail.TYPE_CHA3 = '4' then
        vLotCharact  := CurDocPosDetail.PDE_CHARACTERIZATION_VALUE_3;
      elsif CurDocPosDetail.TYPE_CHA4 = '4' then
        vLotCharact  := CurDocPosDetail.PDE_CHARACTERIZATION_VALUE_4;
      elsif CurDocPosDetail.TYPE_CHA5 = '4' then
        vLotCharact  := CurDocPosDetail.PDE_CHARACTERIZATION_VALUE_5;
      else
        vLotCharact  := '';
      end if;
    else
      vLotCharact  := '';
    end if;

    close CUR_DOC_POS_DETAIL;

    return vLotCharact;
  end;

  /* Fonction qui renvoie la charact�risation de type pi�ce d'un d�tail position */
  function GetPieceCharacterization(aDOC_POSITION_DETAIL_ID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return varchar2
  is
    cursor CUR_DOC_POS_DETAIL
    is
      select PDE.PDE_CHARACTERIZATION_VALUE_1
           , PDE.PDE_CHARACTERIZATION_VALUE_2
           , PDE.PDE_CHARACTERIZATION_VALUE_3
           , PDE.PDE_CHARACTERIZATION_VALUE_4
           , PDE.PDE_CHARACTERIZATION_VALUE_5
           , nvl(CHA1.C_CHARACT_TYPE, '0') TYPE_CHA1
           , nvl(CHA2.C_CHARACT_TYPE, '0') TYPE_CHA2
           , nvl(CHA3.C_CHARACT_TYPE, '0') TYPE_CHA3
           , nvl(CHA4.C_CHARACT_TYPE, '0') TYPE_CHA4
           , nvl(CHA5.C_CHARACT_TYPE, '0') TYPE_CHA5
        from DOC_POSITION_DETAIL PDE
           , GCO_CHARACTERIZATION CHA1
           , GCO_CHARACTERIZATION CHA2
           , GCO_CHARACTERIZATION CHA3
           , GCO_CHARACTERIZATION CHA4
           , GCO_CHARACTERIZATION CHA5
       where PDE.DOC_POSITION_DETAIL_ID = aDOC_POSITION_DETAIL_ID
         and PDE.GCO_CHARACTERIZATION_ID = CHA1.GCO_CHARACTERIZATION_ID(+)
         and PDE.GCO_GCO_CHARACTERIZATION_ID = CHA2.GCO_CHARACTERIZATION_ID(+)
         and PDE.GCO2_GCO_CHARACTERIZATION_ID = CHA3.GCO_CHARACTERIZATION_ID(+)
         and PDE.GCO3_GCO_CHARACTERIZATION_ID = CHA4.GCO_CHARACTERIZATION_ID(+)
         and PDE.GCO4_GCO_CHARACTERIZATION_ID = CHA5.GCO_CHARACTERIZATION_ID(+);

    CurDocPosDetail CUR_DOC_POS_DETAIL%rowtype;
    vPieceCharact   DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
  begin
    open CUR_DOC_POS_DETAIL;

    fetch CUR_DOC_POS_DETAIL
     into CurDocPosDetail;

    if CUR_DOC_POS_DETAIL%found then
      if CurDocPosDetail.TYPE_CHA1 = '3' then
        vPieceCharact  := CurDocPosDetail.PDE_CHARACTERIZATION_VALUE_1;
      elsif CurDocPosDetail.TYPE_CHA2 = '3' then
        vPieceCharact  := CurDocPosDetail.PDE_CHARACTERIZATION_VALUE_2;
      elsif CurDocPosDetail.TYPE_CHA3 = '3' then
        vPieceCharact  := CurDocPosDetail.PDE_CHARACTERIZATION_VALUE_3;
      elsif CurDocPosDetail.TYPE_CHA4 = '3' then
        vPieceCharact  := CurDocPosDetail.PDE_CHARACTERIZATION_VALUE_4;
      elsif CurDocPosDetail.TYPE_CHA5 = '3' then
        vPieceCharact  := CurDocPosDetail.PDE_CHARACTERIZATION_VALUE_5;
      else
        vPieceCharact  := '';
      end if;
    else
      vPieceCharact  := '';
    end if;

    close CUR_DOC_POS_DETAIL;

    return vPieceCharact;
  end;

  /**
  * Procedure
  * Description GetDicoDescription
  *    Fonction qui renvoie une descr de dictionnaire
  * @author ECA
  * @version 2003
  * @lastUpdate
  */
  function GetDicoDescription(
    aDIT_CODE   DICO_DESCRIPTION.DIT_CODE%type
  , aDIT_TABLE  DICO_DESCRIPTION.DIT_TABLE%type
  , aPC_LANG_ID PCS.PC_LANG.PC_LANG_ID%type default PCS.PC_I_LIB_SESSION.GETUSERLANGID
  )
    return varchar2
  is
    tmp DICO_DESCRIPTION.dit_descr%type;
  begin
    select dit_descr
      into tmp
      from dico_description
     where dit_table = aDIT_TABLE
       and dit_code = aDIT_CODE
       and pc_lang_id = aPC_LANG_ID;

    return tmp;
  exception
    when others then
      return '';
  end;

  /**
  * Procedure
  * Description E
  *    Fonction qui renvoie une descr de dictionnaire
  * @author ECA
  * @version 2003
  * @lastUpdate
  */
  function ExecuteConfiguratedProc(aCONFIGNAME PCS.PC_CBASE.CBACNAME_UPPER%type, aSQM_ID number)
    return varchar2
  is
    lvResult   MaxVarchar2                   := null;
    lvProcList PCS.PC_CBASE.CBACVALUE%type;
  begin
    lvProcList  := trim(upper(PCS.PC_CONFIG.GetConfig(aCONFIGNAME) ) );

    if     (lvProcList is not null)
       and (lvProcList <> 'NULL') then
      begin
        DOC_FUNCTIONS.ExecuteExternProc(aParamID => aSQM_ID, aProcStatement => lvProcList, aResultText => lvResult);
      exception
        when others then
          lvResult  := '';
          raise;
      end;
    end if;

    return lvResult;
  end ExecuteConfiguratedProc;

  /* fonction qui renvoie l'ID du DOC_GAUGE_NUMBERING en fonction du type D'ANC */
  function GetDocGaugeID(aC_ANC_TYPE SQM_ANC.C_ANC_TYPE%type)
    return number
  is
    sGAU_DESCRIBE DOC_GAUGE.GAU_DESCRIBE%type;
    nDOC_GAUGE_ID DOC_GAUGE.DOC_GAUGE_ID%type;
    blnContinue   boolean;
  begin
    blnContinue    := true;
    nDOC_GAUGE_ID  := 0;

    /* On r�cup�re d'abord la d�signation du gabarit de num�rotation du type d'ANC */
    -- ANC Interne
    if aC_ANC_TYPE = '1' then
      sGAU_DESCRIBE  := PCS.PC_CONFIG.GetConfig('SQM_ANC_INTERN_GAUGE');
    -- ANC Fournisseur
    elsif aC_ANC_TYPE = '2' then
      sGAU_DESCRIBE  := PCS.PC_CONFIG.GetConfig('SQM_ANC_SUPPLIER_GAUGE');
    -- ANC client
    elsif aC_ANC_TYPE = '3' then
      sGAU_DESCRIBE  := PCS.PC_CONFIG.GetConfig('SQM_ANC_CUSTOM_GAUGE');
    -- Config non-renseign�e
    else
      blnContinue  := false;
    end if;

    sGAU_DESCRIBE  := rtrim(ltrim(sGAU_DESCRIBE) );

    /* On r�cup�re Ensuite son ID */
    if blnContinue then
      begin
        select max(DOC_GAUGE_ID)
          into nDOC_GAUGE_ID
          from DOC_GAUGE
         where GAU_DESCRIBE = sGAU_DESCRIBE
           and DOC_GAUGE_ID not in(select DOC_GAUGE_ID
                                     from DOC_GAUGE_STRUCTURED);
      exception
        when others then
          nDOC_GAUGE_ID  := 0;
          raise_application_error(-20030, PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Gabarit non trouv�!') );
      end;
    end if;

    return nDOC_GAUGE_ID;
  end GetDocGaugeID;

  /* Procedure de v�rification par d�faut des champs obligatoires au bouclement */
  function DefaultMandatoryFields(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    return varchar2
  is
    cursor CUR_ANC_POSITION
    is
      select SQM_ANC_POSITION_ID
        from SQM_ANC_POSITION SAP
       where SAP.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID
         and (   DIC_SAP_CTRL_ID is null
              or DIC_SAP_CDEF_ID is null
              or DIC_SAP_NDEF_ID is null
              or DIC_SAP_DECISION_ID is null
              or DIC_SAP_RESP_ID is null
              or SAP_TITLE is null
             );

    CurAncPosition CUR_ANC_POSITION%rowtype;
    sResult        MaxVarchar2;
  begin
    sResult  := '';

    open CUR_ANC_POSITION;

    fetch CUR_ANC_POSITION
     into CurAncPosition;

    if CUR_ANC_POSITION%found then
      sResult  :=
        PCS.PC_FUNCTIONS.TRANSLATEWORD
          (substr
             ('Les champs �tat du contr�le, cause du d�faut, nature du d�faut, d�cision prise, responsable et intitul� doivent �tre renseign�s pour le bouclement de la position'
            , 0
            , 79
             )
          );
    end if;

    close CUR_ANC_POSITION;

    return sResult;
  end DefaultMandatoryFields;

  procedure GetANCFixedCost(aC_ANC_TYPE in SQM_ANC.C_ANC_TYPE%type, aANC_FIXED_COST in out SQM_ANC.ANC_FIXED_COST%type)
  is
  begin
    -- ANC Interne
    if aC_ANC_TYPE = '1' then
      aANC_FIXED_COST  := to_number(PCS.PC_CONFIG.GetConfig('SQM_ANC_INTERN_COST') );
    -- ANC Fournisseur
    elsif aC_ANC_TYPE = '2' then
      aANC_FIXED_COST  := to_number(PCS.PC_CONFIG.GetConfig('SQM_ANC_SUPPLY_COST') );
    -- ANC client
    elsif aC_ANC_TYPE = '3' then
      aANC_FIXED_COST  := to_number(PCS.PC_CONFIG.GetConfig('SQM_ANC_CUSTOM_COST') );
    -- Config non-renseign�e
    else
      aANC_FIXED_COST  := 0;
    end if;
  end GetANCFixedCost;

  /* Recalcul du co�t d'une position ANC */
  procedure CalcANCPositionCost(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
  is
    blnContinue          boolean;
    aC_ANC_POS_STATUS    SQM_ANC_POSITION.C_ANC_POS_STATUS%type;
    aSAP_DIRECT_COST     SQM_ANC_POSITION.SAP_DIRECT_COST%type;
    aSAP_PREVENTIVE_COST SQM_ANC_POSITION.SAP_PREVENTIVE_COST%type;
  begin
    blnContinue  := true;

    -- Si proc�dure de calcul individualis�e de calcul de la position,
    -- alors on ex�cute cette proc�dure (Configuration SQM_ANC_CALC_POSITION_COST)
    if upper(PCS.PC_CONFIG.GetConfig('SQM_ANC_CALC_POSITION_COST') ) <> 'NULL' then
      ExecExternalCalculationProc(PCS.PC_CONFIG.GetConfig('SQM_ANC_CALC_POSITION_COST'), aSQM_ANC_POSITION_ID);
    -- Sinon Calcul Standard
    else
      -- Status de la position d'ANC
      begin
        select SAP.C_ANC_POS_STATUS
          into aC_ANC_POS_STATUS
          from SQM_ANC_POSITION SAP
         where SAP.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;
      exception
        when others then
          blnContinue  := false;
      end;

      if blnContinue then
        if     aC_ANC_POS_STATUS <> '2'
           and aC_ANC_POS_STATUS <> '4' then
          -- Co�t mesures pr�ventives
          begin
            select sum(SPA_COST)
              into aSAP_PREVENTIVE_COST
              from SQM_ANC_PREVENTIVE_ACTION
             where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;
          exception
            when others then
              aSAP_PREVENTIVE_COST  := 0;
          end;

          -- Co�t mesures directes
          begin
            select sum(SDA_COST)
              into aSAP_DIRECT_COST
              from SQM_ANC_DIRECT_ACTION
             where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;
          exception
            when others then
              aSAP_DIRECT_COST  := 0;
          end;

          -- Update des co�ts position
          update SQM_ANC_POSITION
             set SAP_DIRECT_COST = aSAP_DIRECT_COST
               , SAP_PREVENTIVE_COST = aSAP_PREVENTIVE_COST
               , SAP_TOTAL_COST = aSAP_DIRECT_COST + aSAP_PREVENTIVE_COST
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
           where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;
        end if;
      end if;
    end if;
  exception
    when others then
      raise;
  end CalcANCPositionCost;

  /* Recalcul du co�t d'une ANC */
  procedure CalcANCCost(aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type)
  is
    cursor CUR_SQM_ANC
    is
      select ANC.SQM_ANC_ID
           , ANC.C_ANC_STATUS
           , POS.SQM_ANC_POSITION_ID
        from SQM_ANC ANC
           , SQM_ANC_POSITION POS
       where ANC.SQM_ANC_ID = aSQM_ANC_ID
         and ANC.SQM_ANC_ID = POS.SQM_ANC_ID(+);

    CurSqmAnc            CUR_SQM_ANC%rowtype;
    nANC_DIRECT_COST     SQM_ANC.ANC_DIRECT_COST%type;
    nANC_PREVENTIVE_COST SQM_ANC.ANC_PREVENTIVE_COST%type;
    nANC_FIXED_COST      SQM_ANC.ANC_FIXED_COST%type;
    blnUpdateAnc         boolean;
  begin
      -- Si proc�dure de calcul individualis�e de calcul de l'ANC,
    -- alors on ex�cute cette proc�dure (Configuration SQM_ANC_CALC_COST)
    if upper(PCS.PC_CONFIG.GetConfig('SQM_ANC_CALC_COST') ) <> 'NULL' then
      ExecExternalCalculationProc(PCS.PC_CONFIG.GetConfig('SQM_ANC_CALC_COST'), aSQM_ANC_ID);
    else
      -- Calcul des positions
      blnUpdateAnc  := false;

      for CurSqmAnc in CUR_SQM_ANC loop
        if     CurSqmAnc.C_ANC_STATUS <> '2'
           and CurSqmAnc.C_ANC_STATUS <> '5' then
          blnUpdateAnc  := true;
          CalcANCPositionCost(CurSqmAnc.SQM_ANC_POSITION_ID);
        end if;
      end loop;

      --Calcul de l'ANC.
      if blnUpdateAnc = true then
        select   nvl(ANC.ANC_FIXED_COST, 0) ANC_FIXED_COST
               , nvl(sum(SAP.SAP_DIRECT_COST), 0) DIRECT_COST
               , nvl(sum(SAP.SAP_PREVENTIVE_COST), 0) PREVENTIVE_COST
            into nANC_FIXED_COST
               , nANC_DIRECT_COST
               , nANC_PREVENTIVE_COST
            from SQM_ANC ANC
               , SQM_ANC_POSITION SAP
           where ANC.SQM_ANC_ID = aSQM_ANC_ID
             and ANC.SQM_ANC_ID = SAP.SQM_ANC_ID(+)
             and ANC.C_ANC_STATUS <> '2'
             and ANC.C_ANC_STATUS <> '5'
        group by nvl(ANC.ANC_FIXED_COST, 0);

        update SQM_ANC
           set ANC_DIRECT_COST = nANC_DIRECT_COST
             , ANC_PREVENTIVE_COST = nANC_PREVENTIVE_COST
             , ANC_TOTAL_COST = nANC_DIRECT_COST + nANC_PREVENTIVE_COST + nANC_FIXED_COST
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_PUBLIC.GETUSERINI
         where SQM_ANC_ID = aSQM_ANC_ID;
      end if;
    end if;
  exception
    when others then
      raise;
  end CalcANCCost;

/* MAJ de la udr�e pour r�ponse d'une ANC */
  procedure SetANCReplyDateAndDuration(aANC_NUMBER SQM_ANC.ANC_NUMBER%type)
  is
    aANC_PRINT_RECEPT_DATE SQM_ANC.ANC_PRINT_RECEPT_DATE%type;
    aANC_PARTNER_DATE      SQM_ANC.ANC_DATE%type;
    blnContinue            boolean;
    aResultat              MaxVarchar2;
    aANC_REPLY_DURATION    SQM_ANC.ANC_REPLY_DURATION%type;
  begin
    blnContinue             := true;
    aANC_PRINT_RECEPT_DATE  := sysdate;

    -- Date r�clamation tiers
    begin
      select ANC_PARTNER_DATE
        into aANC_PARTNER_DATE
        from SQM_ANC
       where ANC_NUMBER = aANC_NUMBER;
    exception
      when no_data_found then
        begin
          blnContinue  := false;

          -- Si non renseign�e, alors on ne met � jour que la date impression(S'il elle n'a pas d�j� �t� renseign�e), et pas la dur�e
          update SQM_ANC
             set ANC_PRINT_RECEPT_DATE = aANC_PRINT_RECEPT_DATE
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GETUSERINI
           where ANC_NUMBER = aANC_NUMBER
             and ANC_PRINT_RECEPT_DATE is null;
        end;
    end;

    if blnContinue then
      -- Dur�e exacte de validation
      GetExactDuration(aANC_PARTNER_DATE, aANC_PRINT_RECEPT_DATE, aResultat, aANC_REPLY_DURATION);

      --MAJ de l'ANC
      update SQM_ANC
         set ANC_PRINT_RECEPT_DATE = aANC_PRINT_RECEPT_DATE
           , ANC_REPLY_DURATION = aANC_REPLY_DURATION
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GETUSERINI
       where ANC_NUMBER = aANC_NUMBER
         and ANC_PRINT_RECEPT_DATE is null;
    end if;
  end SetANCReplyDateAndDuration;

/* V�rifie si la position d'ANC � au moins une mesure Imm�diate */
  function IsPosWithDirectAct(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type, aC_SDA_STATUS SQM_ANC_DIRECT_ACTION.C_SDA_STATUS%type)
    return integer
  is
    cursor CUR_ANC_POSITION_ACTIONS
    is
      select SAP.SQM_ANC_POSITION_ID
        from SQM_ANC_POSITION SAP
           , SQM_ANC_DIRECT_ACTION SDA
       where SAP.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID
         and SAP.SQM_ANC_POSITION_ID = SDA.SQM_ANC_POSITION_ID
         and SDA.C_SDA_STATUS = aC_SDA_STATUS;

    CurAncPositionActions CUR_ANC_POSITION_ACTIONS%rowtype;
    blnResult             integer;
  begin
    blnResult  := 0;

    open CUR_ANC_POSITION_ACTIONS;

    fetch CUR_ANC_POSITION_ACTIONS
     into CurAncPositionActions;

    if CUR_ANC_POSITION_ACTIONS%found then
      blnResult  := 1;
    end if;

    close CUR_ANC_POSITION_ACTIONS;

    return blnResult;
  end IsPosWithDirectAct;

  /* V�rifie si la position d'ANC � au moins une mesure pr�ventive */
  function IsPosWithPrevActForClose(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    return integer
  is
    cursor CUR_ANC_POSITION_ACTIONS
    is
      select SAP.SQM_ANC_POSITION_ID
        from SQM_ANC_POSITION SAP
           , SQM_ANC_CAUSE SAC
           , SQM_ANC_PREVENTIVE_ACTION SPA
       where SAP.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID
         and SAP.SQM_ANC_POSITION_ID = SAC.SQM_ANC_POSITION_ID
         and SAC.SQM_ANC_CAUSE_ID = SPA.SQM_ANC_CAUSE_ID
         and SPA.C_SPA_STATUS = '1';

    CurAncPositionActions CUR_ANC_POSITION_ACTIONS%rowtype;
    blnResult             integer;
  begin
    blnResult  := 0;

    open CUR_ANC_POSITION_ACTIONS;

    fetch CUR_ANC_POSITION_ACTIONS
     into CurAncPositionActions;

    if CUR_ANC_POSITION_ACTIONS%found then
      blnResult  := 1;
    end if;

    close CUR_ANC_POSITION_ACTIONS;

    return blnResult;
  end IsPosWithPrevActForClose;

  /* V�rifie si la position d'ANC non refuser ou boucl�e � au moins une cause */
  function IsPosWithCause(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    return integer
  is
    cursor CUR_ANC_POSITION_ACTIONS
    is
      select SAP.SQM_ANC_POSITION_ID
           , SAC.SQM_ANC_CAUSE_ID
           , SAP.C_ANC_POS_STATUS
        from SQM_ANC_POSITION SAP
           , SQM_ANC_CAUSE SAC
       where SAP.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID
         and SAP.SQM_ANC_POSITION_ID = SAC.SQM_ANC_POSITION_ID(+);

    CurAncPositionActions CUR_ANC_POSITION_ACTIONS%rowtype;
    blnResult             integer;
  begin
    blnResult  := 0;

    for CurAncPositionActions in CUR_ANC_POSITION_ACTIONS loop
      if CUR_ANC_POSITION_ACTIONS%found then
        if    CurAncPositionActions.C_ANC_POS_STATUS = '2'
           or CurAncPositionActions.C_ANC_POS_STATUS = '4' then
          blnResult  := 1;
          return blnResult;
          exit;
        else
          if CurAncPositionActions.SQM_ANC_CAUSE_ID is null then
            blnResult  := 0;
          else
            blnResult  := 1;
            return blnResult;
            exit;
          end if;
        end if;
      end if;
    end loop;

    return blnResult;
  end IsPosWithCause;

  /*
  *    V�rifie si la position d'ANC non refus�e ou boucl�e disposant d'une cause
  *    disposent d'une mesure pr�ventive.
  */
  function IsPosWithMP(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    return integer
  is
    cursor CUR_ANC_POSITION_ACTIONS
    is
      select SAP.SQM_ANC_POSITION_ID
           , SAP.C_ANC_POS_STATUS
           , SPA.SQM_ANC_PREVENTIVE_ACTION_ID
        from SQM_ANC_POSITION SAP
           , SQM_ANC_PREVENTIVE_ACTION SPA
       where SAP.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID
         and SAP.SQM_ANC_POSITION_ID = SPA.SQM_ANC_POSITION_ID(+);

    CurAncPositionActions CUR_ANC_POSITION_ACTIONS%rowtype;
    blnResult             integer;
  begin
    blnResult  := 0;

    for CurAncPositionActions in CUR_ANC_POSITION_ACTIONS loop
      if CUR_ANC_POSITION_ACTIONS%found then
        if    CurAncPositionActions.C_ANC_POS_STATUS = '2'
           or CurAncPositionActions.C_ANC_POS_STATUS = '4' then
          blnResult  := 1;
          return blnResult;
          exit;
        else
          if CurAncPositionActions.SQM_ANC_PREVENTIVE_ACTION_ID is null then
            blnResult  := 0;
          else
            blnResult  := 1;
            return blnResult;
            exit;
          end if;
        end if;
      end if;
    end loop;

    return blnResult;
  end IsPosWithMP;

  /**
  * Description
  *    V�rifie si la Cause d'une position non refus�e ou non boubl�e poss�de une Mesure pr�ventive
  */
  function IsCauseWithMPForClosing(aSQM_ANC_CAUSE_ID SQM_ANC_CAUSE.SQM_ANC_CAUSE_ID%type)
    return integer
  is
    cursor CUR_ANC_POSITION_ACTIONS
    is
      select SAC.SQM_ANC_CAUSE_ID
        from SQM_ANC_POSITION SAP
           , SQM_ANC_CAUSE SAC
           , SQM_ANC_PREVENTIVE_ACTION SPA
       where SAC.SQM_ANC_CAUSE_ID = aSQM_ANC_CAUSE_ID
         and SAC.SQM_ANC_POSITION_ID = SAP.SQM_ANC_POSITION_ID
         and SAP.C_ANC_POS_STATUS <> '2'
         and SAP.C_ANC_POS_STATUS <> '4'
         and SAC.SQM_ANC_CAUSE_ID = SPA.SQM_ANC_CAUSE_ID
         and SPA.C_SPA_STATUS = '1';

    CurAncPositionActions CUR_ANC_POSITION_ACTIONS%rowtype;
    blnResult             integer;
  begin
    blnResult  := 0;

    open CUR_ANC_POSITION_ACTIONS;

    fetch CUR_ANC_POSITION_ACTIONS
     into CurAncPositionActions;

    if CUR_ANC_POSITION_ACTIONS%found then
      blnResult  := 1;
    end if;

    close CUR_ANC_POSITION_ACTIONS;

    return blnResult;
  end IsCauseWithMPForClosing;

  /**
  * Description
  *    V�rifie si une Mesure pr�ventive est � boucler, cad si sa position est non refus�e est Valid�e
  *    et que son status est plannifi�
  */
  function IsPrevActForClose(aSQM_ANC_PREVENTIVE_ACTION_ID SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_PREVENTIVE_ACTION_ID%type)
    return integer
  is
    cursor CUR_ANC_POSITION_ACTIONS
    is
      select SPA.SQM_ANC_PREVENTIVE_ACTION_ID
        from SQM_ANC_POSITION SAP
           , SQM_ANC_PREVENTIVE_ACTION SPA
       where SPA.SQM_ANC_PREVENTIVE_ACTION_ID = aSQM_ANC_PREVENTIVE_ACTION_ID
         and SAP.C_ANC_POS_STATUS = '3'
         and SPA.C_SPA_STATUS = '1';

    CurAncPositionActions CUR_ANC_POSITION_ACTIONS%rowtype;
    blnResult             integer;
  begin
    blnResult  := 0;

    open CUR_ANC_POSITION_ACTIONS;

    fetch CUR_ANC_POSITION_ACTIONS
     into CurAncPositionActions;

    if CUR_ANC_POSITION_ACTIONS%found then
      blnResult  := 1;
    end if;

    close CUR_ANC_POSITION_ACTIONS;

    return blnResult;
  end IsPrevActForClose;

  /**
  * Procedure
  * Description
  *    V�rifie si une Position est bouclable ou si une ANC poss�de des positions bouclables
  */
  function IsPosForClose(aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type, aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    return integer
  is
    cursor CUR_ANC_POSITION_ACTIONS
    is
      select SAP.SQM_ANC_POSITION_ID
           , SAP.C_ANC_POS_STATUS
           , SPA.C_SPA_STATUS
           , SDA.C_SDA_STATUS
        from SQM_ANC ANC
           , SQM_ANC_POSITION SAP
           , SQM_ANC_PREVENTIVE_ACTION SPA
           , SQM_ANC_DIRECT_ACTION SDA
       where ANC.SQM_ANC_ID = aSQM_ANC_ID
         and ANC.SQM_ANC_ID = SAP.SQM_ANC_ID
         and (   aSQM_ANC_POSITION_ID = 0
              or (    aSQM_ANC_POSITION_ID <> 0
                  and SAP.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID) )
         and SAP.SQM_ANC_POSITION_ID = SPA.SQM_ANC_POSITION_ID
         and SAP.SQM_ANC_POSITION_ID = SDA.SQM_ANC_POSITION_ID
         and SAP.C_ANC_POS_STATUS = '3';

    CurAncPositionActions CUR_ANC_POSITION_ACTIONS%rowtype;
    blnResult             integer;
  begin
    blnResult  := 1;

    -- Si non trouv�e -> position non bouclable
    open CUR_ANC_POSITION_ACTIONS;

    fetch CUR_ANC_POSITION_ACTIONS
     into CurAncPositionActions;

    if CUR_ANC_POSITION_ACTIONS%notfound then
      blnResult  := 0;
      return blnResult;
    end if;

    close CUR_ANC_POSITION_ACTIONS;

    -- Sinon toutes ses mesures doivent pouvoir �tre boucl�es
    for CurAncPositionActions in CUR_ANC_POSITION_ACTIONS loop
      if    CurAncPositionActions.C_SPA_STATUS <> '2'
         or CurAncPositionActions.C_SDA_STATUS <> '2'
         or CurAncPositionActions.SQM_ANC_POSITION_ID is null then
        blnResult  := 0;
        return blnResult;
      end if;
    end loop;

    return blnResult;
  end IsPosForClose;

  /**
  * Procedure ExecExternalCalculationProc
  * Description
  *    Appel des proc�dures externes pour calcul des co�ts ANC et positions d'ANC
  * @author ECA
  * @version 2003
  * @lastUpdate
  */
  procedure ExecExternalCalculationProc(aProcName varchar2, aParamID number)
  is
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         := ' BEGIN ' || aProcName || '(' || aParamID || ');' || ' END;';
    Cursor_Handle   := DBMS_SQL.open_cursor;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.close_cursor(Cursor_Handle);
  exception
    when others then
      raise;
  end ExecExternalCalculationProc;

  /***
  * Function    : GetNCFromProduct
  * Description : fonction (Package SQM_ANC_FUNCTIONS) permettant de renvoyer une chaine de caract�re contenant
  *               les couples (Composants/NC) d'un couple (Produit fabriqu� termin�/ Caract�risation (Lot ou pi�ce).
  *
  * Param�tres d'entr�e : Produit + Caract Lot et/ ou Piece
  * Recherche de l'OF correspondant, et pour chacuns de ses composants, regarder si une NC � �t� g�n�r�e, si oui la retourner.
  *
  * @author ECA.
  * @version 2003.
  * @lastUpdate.
  */
  procedure GetNCFromProduct(
    aGCO_GOOD_ID       in     GCO_GOOD.GCO_GOOD_ID%type
  , aLotCaract         in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , aPieceCaract       in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , aDIC_SDA_TYPE_ID   in     SQM_ANC_DIRECT_ACTION.DIC_SDA_TYPE_ID%type
  , aRecursiveSearch   in     integer
  , aResultat          in out MaxVarchar2
  , aNomenclatureLevel in     integer
  , aDepth             in     integer
  )
  is
    -- Ofs correspondants au produits caract�risation d'entr�e de la fonction
    cursor GET_FINISHED_PDT_OFS
    is
      select distinct LOT.FAL_LOT_ID
                    , LOT.LOT_REFCOMPL
                    , GOO.GOO_MAJOR_REFERENCE
                 from FAL_LOT LOT
                    , FAL_LOT_DETAIL DET
                    , GCO_GOOD GOO
                where LOT.FAL_LOT_ID = DET.FAL_LOT_ID
                  and LOT.GCO_GOOD_ID = aGCO_GOOD_ID
                  and LOT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                  and (   aPieceCaract is null
                       or     aPieceCaract is not null
                          and DET.FAD_PIECE = aPieceCaract)
                  and (   aLotcaract is null
                       or     aLotCaract is not null
                          and DET.FAD_LOT_CHARACTERIZATION = aLotCaract)
      union
      select distinct LOTH.FAL_LOT_HIST_ID as FAL_LOT_ID
                    , LOTH.LOT_REFCOMPL
                    , GOO.GOO_MAJOR_REFERENCE
                 from FAL_LOT_HIST LOTH
                    , FAL_LOT_DETAIL_HIST DETH
                    , GCO_GOOD GOO
                where LOTH.FAL_LOT_HIST_ID = DETH.FAL_LOT_HIST_ID
                  and LOTH.GCO_GOOD_ID = aGCO_GOOD_ID
                  and LOTH.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                  and (   aPieceCaract is null
                       or     aPieceCaract is not null
                          and DETH.FAD_PIECE = aPieceCaract)
                  and (   aLotcaract is null
                       or     aLotCaract is not null
                          and DETH.FAD_LOT_CHARACTERIZATION = aLotCaract);

    -- Composants consomm�s du lot de fabrication
    cursor GET_OUT_COMPONENTS(aFAL_LOT_ID FAL_LOT.FAL_LOT_ID%type)
    is
      select distinct PDT.C_SUPPLY_MODE
                    , GOO.GOO_MAJOR_REFERENCE
                    , GOO.GCO_GOOD_ID
                    , FOU.OUT_LOT
                    , FOU.OUT_PIECE
                 from FAL_FACTORY_OUT FOU
                    , GCO_PRODUCT PDT
                    , GCO_GOOD GOO
                where FOU.FAL_LOT_ID = aFAL_LOT_ID
                  and FOU.C_OUT_ORIGINE = '1'   -- R�ception.
                  and FOU.C_OUT_TYPE = '1'   -- Consomm�.
                  and FOU.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                  and FOU.GCO_GOOD_ID = GOO.GCO_GOOD_ID
      union
      select distinct PDT.C_SUPPLY_MODE
                    , GOO.GOO_MAJOR_REFERENCE
                    , GOO.GCO_GOOD_ID
                    , FOUH.OUT_LOT
                    , FOUH.OUT_PIECE
                 from FAL_FACTORY_OUT_HIST FOUH
                    , GCO_PRODUCT PDT
                    , GCO_GOOD GOO
                where FOUH.FAL_LOT_HIST_ID = aFAL_LOT_ID
                  and FOUH.C_OUT_ORIGINE = '1'   -- R�ception.
                  and FOUH.C_OUT_TYPE = '1'   -- Consomm�.
                  and FOUH.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                  and FOUH.GCO_GOOD_ID = GOO.GCO_GOOD_ID;

    -- Recherche des NC dans le cas de produits achet�s
    cursor GET_NC_BOUGHT_PRODUCT(
      aGCO_GOOD_ID   GCO_GOOD.GCO_GOOD_ID%type
    , aLOT_CHARACT   STM_ELEMENT_NUMBER.SEM_VALUE%type
    , aPIECE_CHARACT STM_ELEMENT_NUMBER.SEM_VALUE%type
    )
    is
      select distinct ANC.ANC_NUMBER
                 from SQM_ANC ANC
                    , SQM_ANC_POSITION POS
                    , SQM_ANC_LINK ALI
                    , STM_ELEMENT_NUMBER SEM1
                    , STM_ELEMENT_NUMBER SEM2
                    , SQM_ANC_DIRECT_ACTION SDA
                where ANC.SQM_ANC_ID = POS.SQM_ANC_ID
                  and POS.SQM_ANC_POSITION_ID = SDA.SQM_ANC_POSITION_ID(+)
                  and POS.SQM_ANC_POSITION_ID = ALI.SQM_ANC_POSITION_ID
                  and POS.GCO_GOOD_ID = aGCO_GOOD_ID
                  and ALI.STM_ELEMENT_NUMBER1_ID = SEM1.STM_ELEMENT_NUMBER_ID(+)
                  and ALI.STM_ELEMENT_NUMBER2_ID = SEM2.STM_ELEMENT_NUMBER_ID(+)
                  and (    (     (   aPIECE_CHARACT is null
                                  or SEM1.SEM_VALUE = aPIECE_CHARACT)
                            and (   aLOT_CHARACT is null
                                 or SEM2.SEM_VALUE = aLOT_CHARACT) )
                       or (    GetPieceCharacterization(ALI.DOC_POSITION_DETAIL_ID) = aPIECE_CHARACT
                           and GetLotCharacterization(ALI.DOC_POSITION_DETAIL_ID) = aLOT_CHARACT
                          )
                      )
                  and (   aDIC_SDA_TYPE_ID is null
                       or SDA.DIC_SDA_TYPE_ID = aDIC_SDA_TYPE_ID);

    -- Recherche des NC dans le cas de produits fabriqu�s
    cursor GET_NC_MADE_PRODUCT(
      aGCO_GOOD_ID   GCO_GOOD.GCO_GOOD_ID%type
    , aLOT_CHARACT   STM_ELEMENT_NUMBER.SEM_VALUE%type
    , aPIECE_CHARACT STM_ELEMENT_NUMBER.SEM_VALUE%type
    )
    is
      select distinct ANC.ANC_NUMBER
                 from SQM_ANC ANC
                    , SQM_ANC_POSITION POS
                    , SQM_ANC_LINK ALI
                    , STM_ELEMENT_NUMBER SEM1
                    , STM_ELEMENT_NUMBER SEM2
                    , FAL_LOT_DETAIL DET
                    , SQM_ANC_DIRECT_ACTION SDA
                where ANC.SQM_ANC_ID = POS.SQM_ANC_ID
                  and POS.SQM_ANC_POSITION_ID = SDA.SQM_ANC_POSITION_ID(+)
                  and POS.SQM_ANC_POSITION_ID = ALI.SQM_ANC_POSITION_ID
                  and POS.GCO_GOOD_ID = aGCO_GOOD_ID
                  and ALI.STM_ELEMENT_NUMBER1_ID = SEM1.STM_ELEMENT_NUMBER_ID(+)
                  and ALI.STM_ELEMENT_NUMBER2_ID = SEM2.STM_ELEMENT_NUMBER_ID(+)
                  and ALI.FAL_LOT_DETAIL_ID = DET.FAL_LOT_DETAIL_ID(+)
                  and (    (     (   aPIECE_CHARACT is null
                                  or SEM1.SEM_VALUE = aPIECE_CHARACT)
                            and (   aLOT_CHARACT is null
                                 or SEM2.SEM_VALUE = aLOT_CHARACT) )
                       or (     (   aPIECE_CHARACT is null
                                 or DET.FAD_PIECE = aPIECE_CHARACT)
                           and (   aLOT_CHARACT is null
                                or DET.FAD_LOT_CHARACTERIZATION = aLOT_CHARACT) )
                      )
                  and (   aDIC_SDA_TYPE_ID is null
                       or SDA.DIC_SDA_TYPE_ID = aDIC_SDA_TYPE_ID)
      union
      select distinct ANC.ANC_NUMBER
                 from SQM_ANC ANC
                    , SQM_ANC_POSITION POS
                    , SQM_ANC_LINK ALI
                    , SQM_ANC_DIRECT_ACTION SDA
                where ANC.SQM_ANC_ID = POS.SQM_ANC_ID
                  and POS.SQM_ANC_POSITION_ID = SDA.SQM_ANC_POSITION_ID(+)
                  and POS.SQM_ANC_POSITION_ID = ALI.SQM_ANC_POSITION_ID
                  and POS.GCO_GOOD_ID = aGCO_GOOD_ID
                  and (   aDIC_SDA_TYPE_ID is null
                       or SDA.DIC_SDA_TYPE_ID = aDIC_SDA_TYPE_ID);

    GetFinishedPdtOfs     GET_FINISHED_PDT_OFS%rowtype;
    GetOutComponents      GET_OUT_COMPONENTS%rowtype;
    GetNcBoughtProduct    GET_NC_BOUGHT_PRODUCT%rowtype;
    GetNcMadeProduct      GET_NC_MADE_PRODUCT%rowtype;
    atmpNomenclaturelevel integer;
  begin
    -- Pour chaque Ofs correspondants
    for GetFinishedPdtOfs in GET_FINISHED_PDT_OFS loop
      -- Pour chaque composant utilis� et acract�ris� Lot et/ou pi�ce, on regarde si une Non-conformit� � �t� cr��e
      for GetOutComponents in GET_OUT_COMPONENTS(GetFinishedPdtOfs.FAL_LOT_ID) loop
        -- Si le composant est caract�ris� on peut rechercher sa NC.
        if    (GetOutComponents.OUT_LOT is not null)
           or (GetOutComponents.OUT_PIECE is not null) then
          /* Si composant achet�, recherche des NC avec position sur le composant
             + lien sur documents + D�tail position avec les caract. ou liens sur les caract. */
          if GetOutComponents.C_SUPPLY_MODE = '1' then
            for GetNcBoughtProduct in GET_NC_BOUGHT_PRODUCT(GetOutComponents.GCO_GOOD_ID, GetOutComponents.OUT_LOT, GetOutComponents.OUT_PIECE) loop
              if aResultat is not null then
                aResultat  := aResultat || chr(13) || chr(10);
              end if;

              aResultat  := aResultat || GetOutComponents.GOO_MAJOR_REFERENCE || '(' || GetNcBoughtProduct.ANC_NUMBER || ')';
            end loop;
          /* Si composant fabriqu�, recherche d'une NC avec position sur le composant
             + lien sur lot + D�tail lot avec les caract. ou liens sur les caract. */
          elsif GetOutComponents.C_SUPPLY_MODE = '2' then
            for GetNcMadeProduct in GET_NC_MADE_PRODUCT(GetOutComponents.GCO_GOOD_ID, GetOutComponents.OUT_LOT, GetOutComponents.OUT_PIECE) loop
              if aResultat is not null then
                aResultat  := aResultat || chr(13) || chr(10);
              end if;

              aResultat  := aResultat || GetOutComponents.GOO_MAJOR_REFERENCE || '(' || GetNcMadeProduct.ANC_NUMBER || ')';
            end loop;
          end if;

          -- Si recherche r�cursive, on continue
          if aRecursiveSearch = 1 then
            atmpNomenclaturelevel  := aNomenclaturelevel + 1;

            if    aDepth is null
               or aDepth > aNomenclatureLevel then
              GetNCFromProduct(GetOutComponents.GCO_GOOD_ID
                             , GetOutComponents.OUT_LOT
                             , GetOutComponents.OUT_PIECE
                             , aDIC_SDA_TYPE_ID
                             , aRecursiveSearch
                             , aResultat
                             , atmpNomenclatureLevel
                             , aDepth
                              );
            end if;
          end if;
        end if;
      end loop;
    end loop;
  end GetNCFromProduct;

  /**
  * Procedure : ProtectNC.
  *
  * Description : Protection/D�protection d'une NC.
  *
  */
  procedure NCProtection(aSQM_ANC_ID in SQM_ANC.SQM_ANC_ID%type, aProtect number, aSessionID varchar2 default null)
  is
  begin
    /* M�j du flag de protection de la NC */
    update SQM_ANC
       set ANC_PROTECTED = aProtect
         , ANC_SESSION_ID = decode(aProtect, 1, aSessionID, null)
     where SQM_ANC_ID = aSQM_ANC_ID;
  end NCProtection;

/**
* Description
*   Mise � 0 du flag DOF_CREATING lors de l'abandon d'une NC
*   avant le post
*/
  procedure updateFreeNumberOnCancel(aGaugeId in number, aNC_NUMBER in varchar2)
  is
    gauNumber  DOC_GAUGE.GAU_NUMBERING%type;
    freeNumber DOC_GAUGE_NUMBERING.GAN_FREE_NUMBER%type;
  begin
    -- V�rifie si la r�cup�ration des num�ros libres est active
    begin
      select nvl(GAU_NUMBERING, 0)
           , nvl(GAN_FREE_NUMBER, 0)
        into gauNumber
           , freeNumber
        from DOC_GAUGE
           , DOC_GAUGE_NUMBERING
       where DOC_GAUGE_ID = aGaugeId
         and DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID(+) = DOC_GAUGE.DOC_GAUGE_NUMBERING_ID;
    exception
      when no_data_found then
        -- Rien ne se passe, l'id du gabarit n'existe simplement pas
        gauNumber   := 0;
        freeNumber  := 0;
    end;

    if     (gauNumber = 1)
       and (freeNumber = 1) then
      update DOC_FREE_NUMBER
         set DOF_CREATING = 0
       where DOF_NUMBER = aNC_NUMBER;
    end if;
  end updateFreeNumberOnCancel;
end SQM_ANC_FUNCTIONS;
