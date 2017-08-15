--------------------------------------------------------
--  DDL for Package Body SQM_ANC_POSITION_GENERATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_ANC_POSITION_GENERATE" 
is
  /*
  * Procedure FinalizeNC
  *
  * Description : Procedure de finalisation d'une NC, réalise les point suivants :
  *         1) Protection de l'ANC correspondante.
  *         2) Pour chaque Correction et action recalcul des durées.
  *         4) Recalcul des durées de la position
  *         3) Recalcul des coûts de la position + report des coûts au niveau de l'ANC. (calcul tenant compte d'une evntuelle indiv du calcul).
  *           6) Déprotection de l'ANC.
  */
  procedure FinalizeNC(aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type)
  is
    cursor CUR_NC_POSITION
    is
      select SAP.SQM_ANC_POSITION_ID
           , SAP_VALIDATION_DATE
           , SAP_CLOSING_DATE
           , SAP_CREATION_DATE
        from SQM_ANC_POSITION SAP
       where SAP.SQM_ANC_ID = aSQM_ANC_ID;

    cursor CUR_NC_CORRECTION(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    is
      select SAD.SQM_ANC_DIRECT_ACTION_ID
           , SDA_END_DATE
           , SDA_CREATION_DATE
        from SQM_ANC_DIRECT_ACTION SAD
       where SAD.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

    cursor CUR_NC_ACTION(aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type)
    is
      select SPA.SQM_ANC_PREVENTIVE_ACTION_ID
           , SPA_END_DATE
           , SPA_CREATION_DATE
        from SQM_ANC_PREVENTIVE_ACTION SPA
       where SPA.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

    CurNcPosition               CUR_NC_POSITION%rowtype;
    CurNcCorrection             CUR_NC_CORRECTION%rowtype;
    CurNcAction                 CUR_NC_ACTION%rowtype;
    aResultat                   SQM_ANC_FUNCTIONS.MaxVarChar2;
    aDuration                   number;
    aSAP_VALIDATION_DURATION    number;
    aSAP_PROCESSING_DURATION    number;
    aSAP_TOTAL_DURATION         number;
    aANC_VALIDATION_DURATION    number;
    aANC_REPLY_DURATION         number;
    aANC_ALLOCATION_DURATION    number;
    aANC_PROCESSING_DURATION    number;
    aANC_TOTAL_DURATION         number;
    aANC_PARTNER_DATE           date;
    aANC_PRINT_RECEPT_DATE      date;
    aANC_DATE                   date;
    aANC_VALIDATION_DATE        date;
    aANC_ALLOCATION_DATE        date;
    aANC_CLOSING_DATE           date;
    blnUpdateANC_REPLY_DURATION boolean;
  begin
    if aSQM_ANC_ID is not null then
      -- Protection de la NC correspondante
      SQM_ANC_FUNCTIONS.NCProtection(aSQM_ANC_ID, 1);

      -- Pour chaque position
      for CurNcPosition in CUR_NC_POSITION loop
        -- Pour chaque correction
        for CurNcCorrection in CUR_NC_CORRECTION(CurNcPosition.SQM_ANC_POSITION_ID) loop
          -- Recalcul des durées.
          SQM_ANC_FUNCTIONS.GetExactDuration(CurNcCorrection.SDA_CREATION_DATE
                                           , CurNcCorrection.SDA_END_DATE
                                           , aResultat
                                           , aDuration
                                            );

          -- Modification de la durée
          if aDuration is not null then
            update SQM_ANC_DIRECT_ACTION
               set SDA_DURATION = aDuration
             where SQM_ANC_DIRECT_ACTION_ID = CurNcCorrection.SQM_ANC_DIRECT_ACTION_ID;
          end if;
        end loop;

        -- Pour chaque Action
        for CurNcAction in CUR_NC_ACTION(CurNcPosition.SQM_ANC_POSITION_ID) loop
          -- Recalcul des durées.
          SQM_ANC_FUNCTIONS.GetExactDuration(CurNcAction.SPA_CREATION_DATE
                                           , CurNcAction.SPA_END_DATE
                                           , aResultat
                                           , aDuration
                                            );

          -- Modification de la durée
          if aDuration is not null then
            update SQM_ANC_PREVENTIVE_ACTION
               set SPA_DURATION = aDuration
             where SQM_ANC_PREVENTIVE_ACTION_ID = CurNcAction.SQM_ANC_PREVENTIVE_ACTION_ID;
          end if;
        end loop;

        -- Traitement de la position : Recalcul des durées
          -- Calcul durée de validation
        SQM_ANC_FUNCTIONS.GetExactDuration(CurNcPosition.SAP_CREATION_DATE
                                         , CurNcPosition.SAP_VALIDATION_DATE
                                         , aResultat
                                         , aSAP_VALIDATION_DURATION
                                          );
        -- Calcul durée de traitement
        SQM_ANC_FUNCTIONS.GetExactDuration(CurNcPosition.SAP_VALIDATION_DATE
                                         , CurNcPosition.SAP_CLOSING_DATE
                                         , aResultat
                                         , aSAP_PROCESSING_DURATION
                                          );
        -- Calcul durée totale
        SQM_ANC_FUNCTIONS.GetExactDuration(CurNcPosition.SAP_CREATION_DATE
                                         , CurNcPosition.SAP_CLOSING_DATE
                                         , aResultat
                                         , aSAP_TOTAL_DURATION
                                          );

        update SQM_ANC_POSITION
           set SAP_VALIDATION_DURATION = aSAP_VALIDATION_DURATION
             , SAP_PROCESSING_DURATION = aSAP_PROCESSING_DURATION
             , SAP_TOTAL_DURATION = aSAP_TOTAL_DURATION
         where SQM_ANC_POSITION_ID = CurNcPosition.SQM_ANC_POSITION_ID;

        -- Traitement de la position : Recalcul des coûts
        SQM_ANC_FUNCTIONS.CalcANCPositionCost(CurNcPosition.SQM_ANC_POSITION_ID);
      end loop;

      --  Recalcul des coûts de la NC.
      SQM_ANC_FUNCTIONS.CalcANCCost(aSQM_ANC_ID);

      -- Recalcul des durées de la NC
        -- Récupération date création et date validation de l'ANC
      select nvl(ANC_DATE, A_DATECRE)
           , ANC_VALIDATION_DATE
           , ANC_ALLOCATION_DATE
           , ANC_CLOSING_DATE
        into aANC_DATE
           , aANC_VALIDATION_DATE
           , aANC_ALLOCATION_DATE
           , aANC_CLOSING_DATE
        from SQM_ANC
       where SQM_ANC_ID = aSQM_ANC_ID;

      -- Récupération date Réclamation tiers de l'ANC et date impression
      begin
        blnUpdateANC_REPLY_DURATION  := true;

        select ANC_PARTNER_DATE
             , ANC_PRINT_RECEPT_DATE
          into aANC_PARTNER_DATE
             , aANC_PRINT_RECEPT_DATE
          from SQM_ANC
         where SQM_ANC_ID = aSQM_ANC_ID;
      exception
        when no_data_found then
          begin
            blnUpdateANC_REPLY_DURATION  := false;
            aANC_REPLY_DURATION          := null;
          end;
      end;

      -- Calcul durée de réponse ANC
      if blnUpdateANC_REPLY_DURATION then
        SQM_ANC_FUNCTIONS.GetExactDuration(aANC_PARTNER_DATE, aANC_PRINT_RECEPT_DATE, aResultat, aANC_REPLY_DURATION);
      end if;

      -- Calcul durée de validation ANC
      SQM_ANC_FUNCTIONS.GetExactDuration(aANC_DATE, aANC_VALIDATION_DATE, aResultat, aANC_VALIDATION_DURATION);
      -- Calcul durée d'affectation ANC
      SQM_ANC_FUNCTIONS.GetExactDuration(aANC_VALIDATION_DATE, aANC_ALLOCATION_DATE, aResultat
                                       , aANC_ALLOCATION_DURATION);
      -- Calcul durée de traitement ANC
      SQM_ANC_FUNCTIONS.GetExactDuration(aANC_ALLOCATION_DATE, aANC_CLOSING_DATE, aResultat, aANC_PROCESSING_DURATION);
      -- Calcul durée de totale ANC
      SQM_ANC_FUNCTIONS.GetExactDuration(aANC_DATE, aANC_CLOSING_DATE, aResultat, aANC_TOTAL_DURATION);

      update SQM_ANC
         set ANC_REPLY_DURATION = aANC_REPLY_DURATION
           , ANC_VALIDATION_DURATION = aANC_VALIDATION_DURATION
           , ANC_ALLOCATION_DURATION = aANC_ALLOCATION_DURATION
           , ANC_PROCESSING_DURATION = aANC_PROCESSING_DURATION
           , ANC_TOTAL_DURATION = aANC_TOTAL_DURATION
       where SQM_ANC_ID = aSQM_ANC_ID;

      -- Déprotection de la NC.
      SQM_ANC_FUNCTIONS.NCProtection(aSQM_ANC_ID, 0);
    end if;
  end FinalizeNC;

  /* Procédure   : CheckNCPositionIntegrity
  *  Description : Vérification des règles d'intégrité de base d'une position d'ANC, et de règles
  *          "Obligatoires"
  *
  *  aSQM_ANC_POSITION_Rec : Record contenant les infos à insérer dans la base
  *  aUseBasicRules        : Vérification des règles obligatoires ou non!
  *
  */
  procedure CheckNCPositionIntegrity(
    aSQM_ANC_POSITION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_POSITION_Rec
  , aCanCreate            in out boolean
  )
  is
    aC_ANC_TYPE              varchar2(10);
    aPAC_CUSTOM_PARTNER_ID   number;
    aPAC_SUPPLIER_PARTNER_ID number;
    aC_ANC_STATUS            varchar2(10);
  begin
    aCanCreate  := true;

    -- Correspondance des status NC et Position de NC.
    begin
      select C_ANC_STATUS
        into aC_ANC_STATUS
        from SQM_ANC
       where SQM_ANC_ID = aSQM_ANC_POSITION_Rec.SQM_ANC_ID;

      -- Si status de l'ANC  différent de "a valider"," Validée", "Affectée".
      if aC_ANC_STATUS not in('1', '3', '4') then
        SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord
                      ('Le statut de la NC ne permet pas la création de nouvelle position! Celle-ci ne peut être créée.')
         , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
         , 1
          );
        aCanCreate  := false;
      end if;
    exception
      when others then
        begin
          SQM_ANC_GENERATE.AddErrorReport
            (PCS.PC_FUNCTIONS.TranslateWord
                             ('Problèmes rencontrés avec le statut de la position à créer! Celle-ci ne peut être créée.')
           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
           , 1
            );
          aCanCreate  := false;
        end;
    end;

    -- ID Création .
    if aSQM_ANC_POSITION_Rec.A_IDCRE is null then
      select A_IDCRE
        into aSQM_ANC_POSITION_Rec.A_IDCRE
        from SQM_ANC
       where SQM_ANC_ID = aSQM_ANC_POSITION_Rec.SQM_ANC_ID;
    end if;

      /* Vérification des champs mandatory (avec renseignement automatique si possible */
    -- ID Position de NC.
    if aSQM_ANC_POSITION_Rec.SQM_ANC_POSITION_ID is null then
      select INIT_ID_SEQ.nextval
        into aSQM_ANC_POSITION_Rec.SQM_ANC_POSITION_ID
        from dual;
    end if;

    -- Numéro de position de NC .
    if aSQM_ANC_POSITION_Rec.SAP_NUMBER is null then
      -- Numéro de NC.
      SQM_ANC_FUNCTIONS.GetANCPositionNumber(aSQM_ANC_POSITION_Rec.SQM_ANC_ID, aSQM_ANC_POSITION_Rec.SAP_NUMBER);
    end if;

    -- Intitulé de position
    if aSQM_ANC_POSITION_Rec.SAP_TITLE is null then
      aSQM_ANC_POSITION_Rec.SAP_TITLE  :=
                                       PCS.PC_FUNCTIONS.TranslateWord('Position n°')
                                       || aSQM_ANC_POSITION_Rec.SAP_NUMBER;
    end if;

    -- Date Création
    if aSQM_ANC_POSITION_Rec.A_DATECRE is null then
      aSQM_ANC_POSITION_Rec.A_DATECRE  := sysdate;
    end if;

    -- Créateur NC
    if aSQM_ANC_POSITION_Rec.PC_SAP_USER3_ID is null then
      SQM_ANC_INITIALIZE.GetUserInfo(aSQM_ANC_POSITION_Rec.A_IDCRE, aSQM_ANC_POSITION_Rec.PC_SAP_USER3_ID);
    end if;

    -- Date position
    if aSQM_ANC_POSITION_Rec.SAP_CREATION_DATE is null then
      aSQM_ANC_POSITION_Rec.SAP_CREATION_DATE  := aSQM_ANC_POSITION_Rec.A_DATECRE;
    end if;

    -- Retour et document retour.
    if     (aSQM_ANC_POSITION_Rec.DOC_DOCUMENT2_ID is not null)
       and (aSQM_ANC_POSITION_Rec.SAP_RETURN <> 1) then
      aSQM_ANC_POSITION_Rec.SAP_RETURN  := 1;
    end if;

    -- Produit et référence secondaire et référence tiers
    if aSQM_ANC_POSITION_Rec.GCO_GOOD_ID is not null then
      -- Référence secondaire.
      if aSQM_ANC_POSITION_Rec.SAP_SECOND_REF is null then
        aSQM_ANC_POSITION_Rec.SAP_SECOND_REF  :=
                                                FAL_TOOLS.GetGOO_SECONDARY_REFERENCE(aSQM_ANC_POSITION_Rec.GCO_GOOD_ID);
      end if;

      -- Référence tiers.
      begin
        select C_ANC_TYPE
             , PAC_CUSTOM_PARTNER_ID
             , PAC_SUPPLIER_PARTNER_ID
          into aC_ANC_TYPE
             , aPAC_CUSTOM_PARTNER_ID
             , aPAC_SUPPLIER_PARTNER_ID
          from SQM_ANC
         where SQM_ANC_ID = aSQM_ANC_POSITION_Rec.SQM_ANC_ID;
      exception
        when others then
          begin
            aC_ANC_TYPE               := '';
            aPAC_CUSTOM_PARTNER_ID    := null;
            aPAC_SUPPLIER_PARTNER_ID  := null;
          end;
      end;

      if (    aC_ANC_TYPE = '2'
          and aPAC_SUPPLIER_PARTNER_ID is not null) then
        begin
          select CDA.CDA_COMPLEMENTARY_REFERENCE
            into aSQM_ANC_POSITION_Rec.SAP_PARTNER_REF
            from GCO_COMPL_DATA_PURCHASE CDA
           where CDA.GCO_GOOD_ID = aSQM_ANC_POSITION_Rec.GCO_GOOD_ID
             and CDA.PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID;
        exception
          when no_data_found then
            aSQM_ANC_POSITION_Rec.SAP_PARTNER_REF  := null;
        end;
      end if;

      if (    aC_ANC_TYPE = '3'
          and aPAC_CUSTOM_PARTNER_ID is not null) then
        begin
          select CDA.CDA_COMPLEMENTARY_REFERENCE
            into aSQM_ANC_POSITION_Rec.SAP_PARTNER_REF
            from GCO_COMPL_DATA_SALE CDA
           where CDA.GCO_GOOD_ID = aSQM_ANC_POSITION_Rec.GCO_GOOD_ID
             and CDA.PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID;
        exception
          when no_data_found then
            aSQM_ANC_POSITION_Rec.SAP_PARTNER_REF  := null;
        end;
      end if;
    end if;

    /* Vérification des valeurs de dico entrées */
    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_CTRL', aSQM_ANC_POSITION_Rec.DIC_SAP_CTRL_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAP_CTRL = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_CTRL_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_CTRL_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_CDEF', aSQM_ANC_POSITION_Rec.DIC_SAP_CDEF_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAP_CDEF = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_CDEF_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_CDEF_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_NDEF', aSQM_ANC_POSITION_Rec.DIC_SAP_NDEF_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAP_NDEF = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_NDEF_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_NDEF_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_DECISION', aSQM_ANC_POSITION_Rec.DIC_SAP_DECISION_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAP_DECISION = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_DECISION_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_DECISION_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_RESP', aSQM_ANC_POSITION_Rec.DIC_SAP_RESP_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAP_RESP = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_RESP_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_RESP_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_FREE1', aSQM_ANC_POSITION_Rec.DIC_SAP_FREE1_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAP_FREE1 = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_FREE1_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_FREE1_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_FREE2', aSQM_ANC_POSITION_Rec.DIC_SAP_FREE2_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAP_FREE2 = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_FREE2_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_FREE2_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_FREE3', aSQM_ANC_POSITION_Rec.DIC_SAP_FREE3_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAP_FREE3 = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_FREE3_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_FREE3_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_FREE4', aSQM_ANC_POSITION_Rec.DIC_SAP_FREE4_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAP_FREE4 = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_FREE4_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_FREE4_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_FREE5', aSQM_ANC_POSITION_Rec.DIC_SAP_FREE5_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAP_FREE5 = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_FREE5_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_FREE5_ID  := null;
    end if;
  end CheckNCPositionIntegrity;

  /* Procédure   : CheckNCCorrectionIntegrity
  *  Description : Procedure de contrôle de l'intégrité d'une correction
  *
  */
  procedure CheckNCCorrectionIntegrity(
    aSQM_ANC_CORRECTION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CORRECTION_Rec
  , aCanCreate              in out boolean
  )
  is
    aSQM_ANC_ID       SQM_ANC.SQM_ANC_ID%type;
    aANCID_CRE        SQM_ANC.A_IDCRE%type;
    aC_ANC_POS_STATUS SQM_ANC_POSITION.C_ANC_POS_STATUS%type;
  begin
    -- Flag de création possible.
    aCanCreate                                 := true;

    -- Récup de l'ANC de la Position de la Correction
    select SQM_ANC_ID
         , A_IDCRE
         , C_ANC_POS_STATUS
      into aSQM_ANC_ID
         , aANCID_CRE
         , aC_ANC_POS_STATUS
      from SQM_ANC_POSITION
     where SQM_ANC_POSITION_ID = aSQM_ANC_CORRECTION_Rec.SQM_ANC_POSITION_ID;

    -- ID Création
    if aSQM_ANC_CORRECTION_Rec.A_IDCRE is null then
      aSQM_ANC_CORRECTION_Rec.A_IDCRE  := aANCID_CRE;
    end if;

    -- ID de la correction
    if aSQM_ANC_CORRECTION_Rec.SQM_ANC_DIRECT_ACTION_ID is null then
      select INIT_ID_SEQ.nextval
        into aSQM_ANC_CORRECTION_Rec.SQM_ANC_DIRECT_ACTION_ID
        from dual;
    end if;

    -- Status de la correction. doit être cohérent avec celui de la position
    if aC_ANC_POS_STATUS not in('1', '3') then
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
                    ('On ne peut ajouter une correction à une position en statut différent de "A valider" ou "validée"!')
       , aSQM_ANC_ID
       , 1
        );
      aCanCreate  := false;
    end if;

    -- Type de correction
    if aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
           (PCS.PC_FUNCTIONS.TranslateWord('Le type de la correction doit être précisé. Celle-ci ne peut être créée!')
          , aSQM_ANC_ID
          , 1
           );
      aCanCreate  := false;
    end if;

    -- Délai
    if aSQM_ANC_CORRECTION_Rec.SDA_DELAY is null then
      aSQM_ANC_CORRECTION_Rec.SDA_DELAY  := aSQM_ANC_CORRECTION_Rec.A_DATECRE;
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
           ('Le délai de la correction n''étant pas précisé, celui-ci à été mis à la date de création de la correction!')
       , aSQM_ANC_ID
       , 1
        );
    end if;

    -- Position
    if aSQM_ANC_CORRECTION_Rec.SQM_ANC_POSITION_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord('La position de la correction doit être précisée. Celle-ci ne peut être créée!')
       , aSQM_ANC_ID
       , 1
        );
      aCanCreate  := false;
    end if;

    -- Date création.
    aSQM_ANC_CORRECTION_Rec.SDA_CREATION_DATE  := nvl(aSQM_ANC_CORRECTION_Rec.SDA_CREATION_DATE, sysdate);

    -- User création
    if aSQM_ANC_CORRECTION_Rec.PC_SDA_USER3_ID is null then
      SQM_ANC_INITIALIZE.GetUserInfo(aSQM_ANC_CORRECTION_Rec.A_IDCRE, aSQM_ANC_CORRECTION_Rec.PC_SDA_USER3_ID);
    end if;

    /* Vérification des valeurs de dictionnaire entrées */
    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SDA_TYPE', aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SDA_TYPE_ID = ' ||
                             aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_DELAY_TYPE', aSQM_ANC_CORRECTION_Rec.DIC_DELAY_TYPE_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_DELAY_TYPE_ID = ' ||
                             aSQM_ANC_CORRECTION_Rec.DIC_DELAY_TYPE_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CORRECTION_Rec.DIC_DELAY_TYPE_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SDA_FREE1', aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE1_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SDA_FREE1_ID = ' ||
                             aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE1_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE1_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SDA_FREE2', aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE2_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SDA_FREE2_ID = ' ||
                             aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE2_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE2_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SDA_FREE3', aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE3_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SDA_FREE3_ID = ' ||
                             aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE3_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE3_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SDA_FREE4', aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE4_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SDA_FREE4_ID = ' ||
                             aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE4_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE4_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SDA_FREE5', aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE5_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SDA_FREE5_ID = ' ||
                             aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE5_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE5_ID  := null;
    end if;
  end CheckNCCorrectionIntegrity;

   /* Procédure   : CheckNCCorrectionIntegrity
  *  Description : Procedure de contrôle de l'intégrité d'une correction
  *
  */
  procedure CheckNCCauseIntegrity(
    aSQM_ANC_CAUSE_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CAUSE_Rec
  , aCanCreate         in out boolean
  )
  is
    aSQM_ANC_ID       SQM_ANC.SQM_ANC_ID%type;
    aANCID_CRE        SQM_ANC.A_IDCRE%type;
    aC_ANC_POS_STATUS SQM_ANC_POSITION.C_ANC_POS_STATUS%type;
  begin
    -- Indique si la création est possible
    aCanCreate                    := true;

    -- Récup de l'ANC de la Position de la Correction
    select SQM_ANC_ID
         , C_ANC_POS_STATUS
      into aSQM_ANC_ID
         , aC_ANC_POS_STATUS
      from SQM_ANC_POSITION
     where SQM_ANC_POSITION_ID = aSQM_ANC_CAUSE_Rec.SQM_ANC_POSITION_ID;

    --ID cause.
    if aSQM_ANC_CAUSE_Rec.SQM_ANC_CAUSE_ID is null then
      select INIT_ID_SEQ.nextval
        into aSQM_ANC_CAUSE_Rec.SQM_ANC_CAUSE_ID
        from dual;
    end if;

    -- Type de cause
    if aSQM_ANC_CAUSE_Rec.DIC_SAC_TYPE_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
                  (PCS.PC_FUNCTIONS.TranslateWord('Le type de cause doit être précisée. Celle-ci ne peut être créée!')
                 , aSQM_ANC_ID
                 , 1
                  );
      aCanCreate  := false;
    end if;

    -- Position
    if aSQM_ANC_CAUSE_Rec.SQM_ANC_POSITION_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
           (PCS.PC_FUNCTIONS.TranslateWord('La position de la cause doit être précisée. Celle-ci ne peut être créée!')
          , aSQM_ANC_ID
          , 1
           );
      aCanCreate  := false;
    end if;

    -- le statut dela position permet-il de créer une cause?
    if aC_ANC_POS_STATUS not in('1', '3') then
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
           ('On ne peut ajouter une cause qu''à une position en statut "A valider" ou "Validée". Celle-ci ne peut être créée!'
           )
       , aSQM_ANC_ID
       , 1
        );
      aCanCreate  := false;
    end if;

    -- Date création
    aSQM_ANC_CAUSE_Rec.A_DATECRE  := nvl(aSQM_ANC_CAUSE_Rec.A_DATECRE, sysdate);

    -- ID création
    if aSQM_ANC_CAUSE_Rec.A_IDCRE is null then
      aSQM_ANC_CAUSE_Rec.A_IDCRE  := aANCID_CRE;
    end if;

    /* Vérification des dictionnaires */
    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAC_TYPE', aSQM_ANC_CAUSE_Rec.DIC_SAC_TYPE_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAC_TYPE_ID = ' ||
                             aSQM_ANC_CAUSE_Rec.DIC_SAC_TYPE_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CAUSE_Rec.DIC_SAC_TYPE_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAC_FREE1', aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE1_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAC_FREE1_ID = ' ||
                             aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE1_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE1_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAC_FREE2', aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE2_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAC_FREE2_ID = ' ||
                             aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE2_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE2_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAC_FREE3', aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE3_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAC_FREE3_ID = ' ||
                             aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE3_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE3_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAC_FREE4', aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE4_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAC_FREE4_ID = ' ||
                             aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE4_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE4_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAC_FREE5', aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE5_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SAC_FREE5_ID = ' ||
                             aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE5_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE5_ID  := null;
    end if;
  end CheckNCCauseIntegrity;

  /* Procédure   : CheckNCActionIntegrity
  *  Description : Procedure de contrôle de l'intégrité d'une action
  *
  */
  procedure CheckNCActionIntegrity(
    aSQM_ANC_ACTION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_ACTION_Rec
  , aCanCreate          in out boolean
  )
  is
    aSQM_ANC_ID       SQM_ANC.SQM_ANC_ID%type;
    aANCID_CRE        SQM_ANC.A_IDCRE%type;
    aC_ANC_POS_STATUS SQM_ANC_POSITION.C_ANC_POS_STATUS%type;
  begin
    -- Flag de création possible.
    aCanCreate                             := true;

    -- Récup de l'ANC de la Position de la Correction
    select SQM_ANC_ID
         , A_IDCRE
         , C_ANC_POS_STATUS
      into aSQM_ANC_ID
         , aANCID_CRE
         , aC_ANC_POS_STATUS
      from SQM_ANC_POSITION
     where SQM_ANC_POSITION_ID = aSQM_ANC_ACTION_Rec.SQM_ANC_POSITION_ID;

    -- Le status de la position permet-il l'ajout d'une action?
    if aC_ANC_POS_STATUS not in('1', '3') then
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
           ('On ne peut ajouter une action qu''à une position en statut "A valider" ou "Validée". Celle-ci ne peut être créée!'
           )
       , aSQM_ANC_ID
       , 1
        );
      aCanCreate  := false;
    end if;

    -- ID Création
    if aSQM_ANC_ACTION_Rec.A_IDCRE is null then
      aSQM_ANC_ACTION_Rec.A_IDCRE  := aANCID_CRE;
    end if;

    -- ID de la correction
    if aSQM_ANC_ACTION_Rec.SQM_ANC_PREVENTIVE_ACTION_ID is null then
      select INIT_ID_SEQ.nextval
        into aSQM_ANC_ACTION_Rec.SQM_ANC_PREVENTIVE_ACTION_ID
        from dual;
    end if;

    -- Type de correction
    if aSQM_ANC_ACTION_Rec.DIC_SPA_TYPE_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
               (PCS.PC_FUNCTIONS.TranslateWord('Le type de l''action doit être précisé. Celle-ci ne peut être créée!')
              , aSQM_ANC_ID
              , 1
               );
      aCanCreate  := false;
    end if;

    -- Délai
    if aSQM_ANC_ACTION_Rec.SPA_DELAY is null then
      aSQM_ANC_ACTION_Rec.SPA_DELAY  := aSQM_ANC_ACTION_Rec.A_DATECRE;
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
               ('Le délai de l''action n''étant pas précisé, celui-ci à été mis à la date de création de la correction!')
       , aSQM_ANC_ID
       , 1
        );
    end if;

    -- Position
    if aSQM_ANC_ACTION_Rec.SQM_ANC_POSITION_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord('La position de l''action doit être précisée. Celle-ci ne peut être créée!')
         , aSQM_ANC_ID
         , 1
          );
      aCanCreate  := false;
    end if;

    -- Cause
    if aSQM_ANC_ACTION_Rec.SQM_ANC_CAUSE_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
             (PCS.PC_FUNCTIONS.TranslateWord('La cause de l''action doit être précisée. Celle-ci ne peut être créée!')
            , aSQM_ANC_ID
            , 1
             );
      aCanCreate  := false;
    end if;

    -- Date création.
    aSQM_ANC_ACTION_Rec.SPA_CREATION_DATE  := nvl(aSQM_ANC_ACTION_Rec.SPA_CREATION_DATE, sysdate);

    -- User création
    if aSQM_ANC_ACTION_Rec.PC_SPA_USER3_ID is null then
      SQM_ANC_INITIALIZE.GetUserInfo(aSQM_ANC_ACTION_Rec.A_IDCRE, aSQM_ANC_ACTION_Rec.PC_SPA_USER3_ID);
    end if;

    /* Vérification des valeurs de dictionnaire entrées */
    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SPA_TYPE', aSQM_ANC_ACTION_Rec.DIC_SPA_TYPE_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SPA_TYPE_ID = ' ||
                             aSQM_ANC_ACTION_Rec.DIC_SPA_TYPE_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_ACTION_Rec.DIC_SPA_TYPE_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_DELAY_TYPE', aSQM_ANC_ACTION_Rec.DIC_DELAY_TYPE_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_DELAY_TYPE_ID = ' ||
                             aSQM_ANC_ACTION_Rec.DIC_DELAY_TYPE_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_ACTION_Rec.DIC_DELAY_TYPE_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SPA_FREE1', aSQM_ANC_ACTION_Rec.DIC_SPA_FREE1_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SPA_FREE1_ID = ' ||
                             aSQM_ANC_ACTION_Rec.DIC_SPA_FREE1_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_ACTION_Rec.DIC_SPA_FREE1_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SPA_FREE2', aSQM_ANC_ACTION_Rec.DIC_SPA_FREE2_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SPA_FREE2_ID = ' ||
                             aSQM_ANC_ACTION_Rec.DIC_SPA_FREE2_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_ACTION_Rec.DIC_SPA_FREE2_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SPA_FREE3', aSQM_ANC_ACTION_Rec.DIC_SPA_FREE3_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SPA_FREE3_ID = ' ||
                             aSQM_ANC_ACTION_Rec.DIC_SPA_FREE3_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_ACTION_Rec.DIC_SPA_FREE3_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SPA_FREE4', aSQM_ANC_ACTION_Rec.DIC_SPA_FREE4_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SPA_FREE4_ID = ' ||
                             aSQM_ANC_ACTION_Rec.DIC_SPA_FREE4_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_ACTION_Rec.DIC_SPA_FREE4_ID  := null;
    end if;

    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SPA_FREE5', aSQM_ANC_ACTION_Rec.DIC_SPA_FREE5_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entrée n''est pas correcte!') ||
                             ' ( DIC_SPA_FREE5_ID = ' ||
                             aSQM_ANC_ACTION_Rec.DIC_SPA_FREE5_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_ACTION_Rec.DIC_SPA_FREE5_ID  := null;
    end if;
  end CheckNCActionIntegrity;

  /* Procédure   : CheckNCLinkIntegrity
  *  Description : Procedure de contrôle de l'intégrité d'un Lien
  *
  */
  procedure CheckNCLinkIntegrity(
    aSQM_ANC_LINK_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_LINK_Rec
  , aCanCreate        in out boolean
  )
  is
    aANC_IDCRE              varchar2(10);
    aC_ANC_TYPE             varchar2(10);
    atmpSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type;
  begin
    /* Vérification des champs obligatoires à la création du lien */

    -- ID ANC et ID Position
    if aSQM_ANC_LINK_Rec.SQM_ANC_ID is null then
      begin
        select distinct SAP.SQM_ANC_ID
                      , SAP.SQM_ANC_POSITION_ID
                      , SAP.A_IDCRE
                      , ANC.C_ANC_TYPE
                   into aSQM_ANC_LINK_Rec.SQM_ANC_ID
                      , aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID
                      , aANC_IDCRE
                      , aC_ANC_TYPE
                   from SQM_ANC_POSITION SAP
                      , SQM_ANC_DIRECT_ACTION SDA
                      , SQM_ANC ANC
                  where SAP.SQM_ANC_POSITION_ID = SDA.SQM_ANC_POSITION_ID(+)
                    and SAP.SQM_ANC_ID = ANC.SQM_ANC_ID
                    and (    (SAP.SQM_ANC_POSITION_ID = aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID)
                         or (SDA.SQM_ANC_DIRECT_ACTION_ID = aSQM_ANC_LINK_Rec.SQM_ANC_DIRECT_ACTION_ID)
                        );
      exception
        when others then
          aCanCreate  := false;
      end;
    end if;

    if aCanCreate then
      -- ID Lien
      if aSQM_ANC_LINK_Rec.SQM_ANC_LINK_ID is null then
        select INIT_ID_SEQ.nextval
          into aSQM_ANC_LINK_Rec.SQM_ANC_LINK_ID
          from dual;
      end if;

      -- ID Position ou Correction
      if     (aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID is null)
         and (aSQM_ANC_LINK_Rec.SQM_ANC_DIRECT_ACTION_ID is null) then
        SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord
                   ('Le lien doit être lié soit à une position, soit à une correction de NC. Ce lien ne peut être créé!')
         , aSQM_ANC_LINK_Rec.SQM_ANC_ID
         , 1
          );
        aCanCreate  := false;
      end if;

      -- Date création
      aSQM_ANC_LINK_Rec.A_DATECRE  := nvl(aSQM_ANC_LINK_Rec.A_DATECRE, sysdate);
      -- ID Création
      aSQM_ANC_LINK_Rec.A_IDCRE    := nvl(aSQM_ANC_LINK_Rec.A_IDCRE, aANC_IDCRE);
    end if;

    /* Vérification des règles d'intégrité de base du lien à créer */
    if aCanCreate then
      -- Si il s'agit d'un lien sur une correction, on a soit un Lot, soit un lot archivé, soit un document (Et c'est tout!)
      if aSQM_ANC_LINK_Rec.SQM_ANC_DIRECT_ACTION_ID is not null then
        if aSQM_ANC_LINK_Rec.FAL_LOT_ID is not null then
          aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID  := null;
        elsif aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID is not null then
          aSQM_ANC_LINK_Rec.FAL_LOT_ID       := null;
        else
          SQM_ANC_GENERATE.AddErrorReport
            (PCS.PC_FUNCTIONS.TranslateWord
                     ('Un lien sur une correction porte soit sur un lot, soit sur un lot archivé, soit sur un document!')
           , aSQM_ANC_LINK_Rec.SQM_ANC_ID
           , 1
            );
          aCanCreate  := false;
        end if;
      elsif aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID is not null then
        -- Si il s'agit d'un lien sur une Position, on a suivant le type de la NC
        -- Si NC Interne, on a
        if aC_ANC_TYPE = '1' then
          -- Soit un couple Lot et eventuellement Opé + Détail lot
          if aSQM_ANC_LINK_Rec.FAL_LOT_ID is not null then
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID  := null;
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID  := null;
            aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID         := null;
            aSQM_ANC_LINK_Rec.DOC_POSITION_DETAIL_ID  := null;
          -- Soit un couple Document et eventuellement Détail position de document
          elsif aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID is not null then
            aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID   := null;
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID  := null;
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID  := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_ID              := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID       := null;
          -- Soit une caractlot et/ou pièce
          elsif    (aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID is not null)
                or (aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID is not null) then
            aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID   := null;
            aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID         := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_ID              := null;
            aSQM_ANC_LINK_Rec.DOC_POSITION_DETAIL_ID  := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID       := null;
          -- Lien non valide
          else
            SQM_ANC_GENERATE.AddErrorReport
              (PCS.PC_FUNCTIONS.TranslateWord
                                      ('Les caractéristiques du lien ne sont pas valides. Celui-ci ne peut être inséré!')
             , aSQM_ANC_LINK_Rec.SQM_ANC_ID
             , 1
              );
            aCanCreate  := false;
          end if;
        -- Sinon si NC Client ou fournisseur.
        elsif    aC_ANC_TYPE = '2'
              or aC_ANC_TYPE = '3' then
          -- Soit un couple Document et eventuellement Détail position de document
          if aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID is not null then
            aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID   := null;
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID  := null;
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID  := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_ID              := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID       := null;
          -- Soit une caractlot et/ou pièce
          elsif    (aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID is not null)
                or (aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID is not null) then
            aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID   := null;
            aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID         := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_ID              := null;
            aSQM_ANC_LINK_Rec.DOC_POSITION_DETAIL_ID  := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID       := null;
          -- Lien non valide
          else
            SQM_ANC_GENERATE.AddErrorReport
              (PCS.PC_FUNCTIONS.TranslateWord
                                        ('Les caractéristiques du lien ne sont pas valides. Celui-ci ne peut être créé!')
             , aSQM_ANC_LINK_Rec.SQM_ANC_ID
             , 1
              );
            aCanCreate  := false;
          end if;
        end if;
      end if;

      -- Enfin s'il s'agit d'un lien sur une position, on vérifie bien qu'il correspond au produit de la position.
      if aSQM_ANC_LINK_Rec.SQM_ANC_DIRECT_ACTION_ID is null then
        if aSQM_ANC_LINK_Rec.FAL_LOT_ID is not null then
          begin
            select distinct POS.SQM_ANC_POSITION_ID
                       into atmpSQM_ANC_POSITION_ID
                       from SQM_ANC_POSITION POS
                          , FAL_LOT LOT
                      where POS.SQM_ANC_POSITION_ID = aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID
                        and LOT.FAL_LOT_ID = aSQM_ANC_LINK_Rec.FAL_LOT_ID
                        and POS.GCO_GOOD_ID = LOT.GCO_GOOD_ID;
          exception
            when no_data_found then
              begin
                SQM_ANC_GENERATE.AddErrorReport
                  (PCS.PC_FUNCTIONS.TranslateWord
                     ('Les caractéristiques du lien ne sont pas valides par rapport au bien de sa position. Celui-ci ne peut être créé!'
                     )
                 , aSQM_ANC_LINK_Rec.SQM_ANC_ID
                 , 1
                  );
                aCanCreate  := false;
              end;
          end;
        elsif aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID is not null then
          begin
            select distinct POS.SQM_ANC_POSITION_ID
                       into atmpSQM_ANC_POSITION_ID
                       from SQM_ANC_POSITION POS
                          , DOC_POSITION DOCPOS
                      where POS.SQM_ANC_POSITION_ID = aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID
                        and DOCPOS.DOC_DOCUMENT_ID = aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID
                        and DOCPOS.GCO_GOOD_ID = POS.GCO_GOOD_ID;
          exception
            when no_data_found then
              begin
                SQM_ANC_GENERATE.AddErrorReport
                  (PCS.PC_FUNCTIONS.TranslateWord
                     ('Les caractéristiques du lien ne sont pas valides par rapport au bien de sa position. Celui-ci ne peut être créé!'
                     )
                 , aSQM_ANC_LINK_Rec.SQM_ANC_ID
                 , 1
                  );
                aCanCreate  := false;
              end;
          end;
        -- Soit une caractlot et/ou pièce
        elsif    (aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID is not null)
              or (aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID is not null) then
          begin
            select POS.SQM_ANC_POSITION_ID
              into atmpSQM_ANC_POSITION_ID
              from SQM_ANC_POSITION POS
             where POS.SQM_ANC_POSITION_ID = aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID
               and (    (    aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID is not null
                         and aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID is null
                         and POS.GCO_GOOD_ID in(select GCO_GOOD_ID
                                                  from STM_ELEMENT_NUMBER
                                                 where STM_ELEMENT_NUMBER_ID = aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID)
                        )
                    or (    aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID is null
                        and aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID is not null
                        and POS.GCO_GOOD_ID in(select GCO_GOOD_ID
                                                 from STM_ELEMENT_NUMBER
                                                where STM_ELEMENT_NUMBER_ID = aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID)
                       )
                    or (    aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID is not null
                        and aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID is not null
                        and POS.GCO_GOOD_ID in(select GCO_GOOD_ID
                                                 from STM_ELEMENT_NUMBER
                                                where STM_ELEMENT_NUMBER_ID = aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID)
                        and POS.GCO_GOOD_ID in(select GCO_GOOD_ID
                                                 from STM_ELEMENT_NUMBER
                                                where STM_ELEMENT_NUMBER_ID = aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID)
                       )
                   );
          exception
            when no_data_found then
              begin
                SQM_ANC_GENERATE.AddErrorReport
                  (PCS.PC_FUNCTIONS.TranslateWord
                     ('Les caractéristiques du lien ne sont pas valides par rapport au bien de sa position. Celui-ci ne peut être créé!'
                     )
                 , aSQM_ANC_LINK_Rec.SQM_ANC_ID
                 , 1
                  );
                aCanCreate  := false;
              end;
          end;
        end if;
      end if;
    end if;
  end CheckNCLinkIntegrity;

  /* Procédure   : Insert_NCPosition
  *  Description : Procedure d''insertion d'une position de NC
  *
  */
  procedure Insert_NCPosition(aSQM_ANC_POSITION_Rec in SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_POSITION_Rec)
  is
  begin
    insert into SQM_ANC_POSITION
                (SQM_ANC_POSITION_ID
               , GCO_GOOD_ID
               , PC_SAP_USER1_ID
               , PC_SAP_USER2_ID
               , DIC_SAP_CTRL_ID
               , DIC_SAP_CDEF_ID
               , DIC_SAP_NDEF_ID
               , DIC_SAP_DECISION_ID
               , DIC_SAP_RESP_ID
               , DOC_DOCUMENT2_ID
               , C_ANC_POS_STATUS
               , SQM_ANC_ID
               , DIC_SAP_FREE1_ID
               , DIC_SAP_FREE2_ID
               , DIC_SAP_FREE3_ID
               , DIC_SAP_FREE4_ID
               , DIC_SAP_FREE5_ID
               , SAP_NUMBER
               , SAP_SECOND_REF
               , SAP_PARTNER_REF
               , SAP_COMMENT
               , SAP_QTY_ACCEPT
               , SAP_QTY_DEFECTIVE
               , SAP_ACTUAL_VALUE
               , SAP_REQUIRE_VALUE
               , SAP_VALIDATION_DATE
               , SAP_CLOSING_DATE
               , SAP_VALIDATION_DURATION
               , SAP_PROCESSING_DURATION
               , SAP_TOTAL_DURATION
               , SAP_RETURN
               , SAP_TITLE
               , SAP_DIRECT_COST
               , SAP_PREVENTIVE_COST
               , SAP_TOTAL_COST
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , SAP_FREE_TEXT1
               , SAP_FREE_TEXT2
               , SAP_FREE_TEXT3
               , SAP_FREE_TEXT4
               , SAP_FREE_TEXT5
               , SAP_FREE_DATE1
               , SAP_FREE_DATE2
               , SAP_FREE_DATE3
               , SAP_FREE_DATE4
               , SAP_FREE_DATE5
               , SAP_FREE_NUMBER1
               , SAP_FREE_NUMBER2
               , SAP_FREE_NUMBER3
               , SAP_FREE_NUMBER4
               , SAP_FREE_NUMBER5
               , SAP_FREE_COMMENT1
               , SAP_FREE_COMMENT2
               , PC_SAP_USER3_ID
               , SAP_CREATION_DATE
                )
         values (aSQM_ANC_POSITION_Rec.SQM_ANC_POSITION_ID
               , aSQM_ANC_POSITION_Rec.GCO_GOOD_ID
               , aSQM_ANC_POSITION_Rec.PC_SAP_USER1_ID
               , aSQM_ANC_POSITION_Rec.PC_SAP_USER2_ID
               , aSQM_ANC_POSITION_Rec.DIC_SAP_CTRL_ID
               , aSQM_ANC_POSITION_Rec.DIC_SAP_CDEF_ID
               , aSQM_ANC_POSITION_Rec.DIC_SAP_NDEF_ID
               , aSQM_ANC_POSITION_Rec.DIC_SAP_DECISION_ID
               , aSQM_ANC_POSITION_Rec.DIC_SAP_RESP_ID
               , aSQM_ANC_POSITION_Rec.DOC_DOCUMENT2_ID
               , aSQM_ANC_POSITION_Rec.C_ANC_POS_STATUS
               , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
               , aSQM_ANC_POSITION_Rec.DIC_SAP_FREE1_ID
               , aSQM_ANC_POSITION_Rec.DIC_SAP_FREE2_ID
               , aSQM_ANC_POSITION_Rec.DIC_SAP_FREE3_ID
               , aSQM_ANC_POSITION_Rec.DIC_SAP_FREE4_ID
               , aSQM_ANC_POSITION_Rec.DIC_SAP_FREE5_ID
               , aSQM_ANC_POSITION_Rec.SAP_NUMBER
               , substr(aSQM_ANC_POSITION_Rec.SAP_SECOND_REF, 0, 30)
               , substr(aSQM_ANC_POSITION_Rec.SAP_PARTNER_REF, 0, 30)
               , substr(aSQM_ANC_POSITION_Rec.SAP_COMMENT, 0, 4000)
               , aSQM_ANC_POSITION_Rec.SAP_QTY_ACCEPT
               , aSQM_ANC_POSITION_Rec.SAP_QTY_DEFECTIVE
               , substr(aSQM_ANC_POSITION_Rec.SAP_ACTUAL_VALUE, 0, 100)
               , substr(aSQM_ANC_POSITION_Rec.SAP_REQUIRE_VALUE, 0, 100)
               , aSQM_ANC_POSITION_Rec.SAP_VALIDATION_DATE
               , aSQM_ANC_POSITION_Rec.SAP_CLOSING_DATE
               , aSQM_ANC_POSITION_Rec.SAP_VALIDATION_DURATION
               , aSQM_ANC_POSITION_Rec.SAP_PROCESSING_DURATION
               , aSQM_ANC_POSITION_Rec.SAP_TOTAL_DURATION
               , aSQM_ANC_POSITION_Rec.SAP_RETURN
               , substr(aSQM_ANC_POSITION_Rec.SAP_TITLE, 0, 30)
               , aSQM_ANC_POSITION_Rec.SAP_DIRECT_COST
               , aSQM_ANC_POSITION_Rec.SAP_PREVENTIVE_COST
               , aSQM_ANC_POSITION_Rec.SAP_TOTAL_COST
               , aSQM_ANC_POSITION_Rec.A_DATECRE
               , aSQM_ANC_POSITION_Rec.A_DATEMOD
               , aSQM_ANC_POSITION_Rec.A_IDCRE
               , aSQM_ANC_POSITION_Rec.A_IDMOD
               , substr(aSQM_ANC_POSITION_Rec.SAP_FREE_TEXT1, 0, 250)
               , substr(aSQM_ANC_POSITION_Rec.SAP_FREE_TEXT2, 0, 250)
               , substr(aSQM_ANC_POSITION_Rec.SAP_FREE_TEXT3, 0, 250)
               , substr(aSQM_ANC_POSITION_Rec.SAP_FREE_TEXT4, 0, 250)
               , substr(aSQM_ANC_POSITION_Rec.SAP_FREE_TEXT5, 0, 250)
               , aSQM_ANC_POSITION_Rec.SAP_FREE_DATE1
               , aSQM_ANC_POSITION_Rec.SAP_FREE_DATE2
               , aSQM_ANC_POSITION_Rec.SAP_FREE_DATE3
               , aSQM_ANC_POSITION_Rec.SAP_FREE_DATE4
               , aSQM_ANC_POSITION_Rec.SAP_FREE_DATE5
               , aSQM_ANC_POSITION_Rec.SAP_FREE_NUMBER1
               , aSQM_ANC_POSITION_Rec.SAP_FREE_NUMBER2
               , aSQM_ANC_POSITION_Rec.SAP_FREE_NUMBER3
               , aSQM_ANC_POSITION_Rec.SAP_FREE_NUMBER4
               , aSQM_ANC_POSITION_Rec.SAP_FREE_NUMBER5
               , substr(aSQM_ANC_POSITION_Rec.SAP_FREE_COMMENT1, 0, 4000)
               , substr(aSQM_ANC_POSITION_Rec.SAP_FREE_COMMENT2, 0, 4000)
               , aSQM_ANC_POSITION_Rec.PC_SAP_USER3_ID
               , aSQM_ANC_POSITION_Rec.SAP_CREATION_DATE
                );
  end Insert_NCPosition;

  /* Procédure   : Insert_NCCorrection.
  *  Description : Procedure d''insertion d'une correction d'une position de NC.
  *
  */
  procedure Insert_NCCorrection(aSQM_ANC_CORRECTION_Rec in SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CORRECTION_Rec)
  is
  begin
    insert into SQM_ANC_DIRECT_ACTION
                (SQM_ANC_DIRECT_ACTION_ID
               , PC_SDA_USER1_ID
               , PC_SDA_USER2_ID
               , DIC_DELAY_TYPE_ID
               , C_SDA_STATUS
               , DIC_SDA_TYPE_ID
               , SQM_ANC_POSITION_ID
               , DIC_SDA_FREE1_ID
               , DIC_SDA_FREE2_ID
               , DIC_SDA_FREE3_ID
               , DIC_SDA_FREE4_ID
               , DIC_SDA_FREE5_ID
               , SDA_COMMENT
               , SDA_DELAY
               , SDA_DURATION
               , SDA_COST
               , SDA_END_DATE
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , SDA_FREE_TEXT1
               , SDA_FREE_TEXT2
               , SDA_FREE_TEXT3
               , SDA_FREE_TEXT4
               , SDA_FREE_TEXT5
               , SDA_FREE_DATE1
               , SDA_FREE_DATE2
               , SDA_FREE_DATE3
               , SDA_FREE_DATE4
               , SDA_FREE_DATE5
               , SDA_FREE_NUMBER1
               , SDA_FREE_NUMBER2
               , SDA_FREE_NUMBER3
               , SDA_FREE_NUMBER4
               , SDA_FREE_NUMBER5
               , SDA_FREE_COMMENT1
               , SDA_FREE_COMMENT2
               , PC_SDA_USER3_ID
               , SDA_CREATION_DATE
                )
         values (aSQM_ANC_CORRECTION_Rec.SQM_ANC_DIRECT_ACTION_ID
               , aSQM_ANC_CORRECTION_Rec.PC_SDA_USER1_ID
               , aSQM_ANC_CORRECTION_Rec.PC_SDA_USER2_ID
               , aSQM_ANC_CORRECTION_Rec.DIC_DELAY_TYPE_ID
               , aSQM_ANC_CORRECTION_Rec.C_SDA_STATUS
               , aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID
               , aSQM_ANC_CORRECTION_Rec.SQM_ANC_POSITION_ID
               , aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE1_ID
               , aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE2_ID
               , aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE3_ID
               , aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE4_ID
               , aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE5_ID
               , substr(aSQM_ANC_CORRECTION_Rec.SDA_COMMENT, 0, 50)
               , aSQM_ANC_CORRECTION_Rec.SDA_DELAY
               , aSQM_ANC_CORRECTION_Rec.SDA_DURATION
               , aSQM_ANC_CORRECTION_Rec.SDA_COST
               , aSQM_ANC_CORRECTION_Rec.SDA_END_DATE
               , aSQM_ANC_CORRECTION_Rec.A_DATECRE
               , aSQM_ANC_CORRECTION_Rec.A_DATEMOD
               , aSQM_ANC_CORRECTION_Rec.A_IDCRE
               , aSQM_ANC_CORRECTION_Rec.A_IDMOD
               , substr(aSQM_ANC_CORRECTION_Rec.SDA_FREE_TEXT1, 0, 250)
               , substr(aSQM_ANC_CORRECTION_Rec.SDA_FREE_TEXT2, 0, 250)
               , substr(aSQM_ANC_CORRECTION_Rec.SDA_FREE_TEXT3, 0, 250)
               , substr(aSQM_ANC_CORRECTION_Rec.SDA_FREE_TEXT4, 0, 250)
               , substr(aSQM_ANC_CORRECTION_Rec.SDA_FREE_TEXT5, 0, 250)
               , aSQM_ANC_CORRECTION_Rec.SDA_FREE_DATE1
               , aSQM_ANC_CORRECTION_Rec.SDA_FREE_DATE2
               , aSQM_ANC_CORRECTION_Rec.SDA_FREE_DATE3
               , aSQM_ANC_CORRECTION_Rec.SDA_FREE_DATE4
               , aSQM_ANC_CORRECTION_Rec.SDA_FREE_DATE5
               , aSQM_ANC_CORRECTION_Rec.SDA_FREE_NUMBER1
               , aSQM_ANC_CORRECTION_Rec.SDA_FREE_NUMBER2
               , aSQM_ANC_CORRECTION_Rec.SDA_FREE_NUMBER3
               , aSQM_ANC_CORRECTION_Rec.SDA_FREE_NUMBER4
               , aSQM_ANC_CORRECTION_Rec.SDA_FREE_NUMBER5
               , substr(aSQM_ANC_CORRECTION_Rec.SDA_FREE_COMMENT1, 0, 4000)
               , substr(aSQM_ANC_CORRECTION_Rec.SDA_FREE_COMMENT2, 0, 4000)
               , aSQM_ANC_CORRECTION_Rec.PC_SDA_USER3_ID
               , aSQM_ANC_CORRECTION_Rec.SDA_CREATION_DATE
                );
  end Insert_NCCorrection;

  /* Procédure   : Insert_NCCause.
  *  Description : Procedure d''insertion d'une cause d'une position de NC.
  *
  */
  procedure Insert_NCCause(aSQM_ANC_CAUSE_Rec in SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CAUSE_Rec)
  is
  begin
    insert into SQM_ANC_CAUSE
                (SQM_ANC_CAUSE_ID
               , DIC_SAC_FREE1_ID
               , DIC_SAC_FREE2_ID
               , DIC_SAC_FREE3_ID
               , DIC_SAC_FREE4_ID
               , DIC_SAC_FREE5_ID
               , DIC_SAC_TYPE_ID
               , SQM_ANC_POSITION_ID
               , SAC_COMMENT
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , SAC_FREE_TEXT1
               , SAC_FREE_TEXT2
               , SAC_FREE_TEXT3
               , SAC_FREE_TEXT4
               , SAC_FREE_TEXT5
               , SAC_FREE_DATE1
               , SAC_FREE_DATE2
               , SAC_FREE_DATE3
               , SAC_FREE_DATE4
               , SAC_FREE_DATE5
               , SAC_FREE_NUMBER1
               , SAC_FREE_NUMBER2
               , SAC_FREE_NUMBER3
               , SAC_FREE_NUMBER4
               , SAC_FREE_NUMBER5
               , SAC_FREE_COMMENT1
               , SAC_FREE_COMMENT2
                )
         values (aSQM_ANC_CAUSE_Rec.SQM_ANC_CAUSE_ID
               , aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE1_ID
               , aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE2_ID
               , aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE3_ID
               , aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE4_ID
               , aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE5_ID
               , aSQM_ANC_CAUSE_Rec.DIC_SAC_TYPE_ID
               , aSQM_ANC_CAUSE_Rec.SQM_ANC_POSITION_ID
               , substr(aSQM_ANC_CAUSE_Rec.SAC_COMMENT, 0, 4000)
               , aSQM_ANC_CAUSE_Rec.A_DATECRE
               , aSQM_ANC_CAUSE_Rec.A_DATEMOD
               , aSQM_ANC_CAUSE_Rec.A_IDCRE
               , aSQM_ANC_CAUSE_Rec.A_IDMOD
               , substr(aSQM_ANC_CAUSE_Rec.SAC_FREE_TEXT1, 0, 250)
               , substr(aSQM_ANC_CAUSE_Rec.SAC_FREE_TEXT2, 0, 250)
               , substr(aSQM_ANC_CAUSE_Rec.SAC_FREE_TEXT3, 0, 250)
               , substr(aSQM_ANC_CAUSE_Rec.SAC_FREE_TEXT4, 0, 250)
               , substr(aSQM_ANC_CAUSE_Rec.SAC_FREE_TEXT5, 0, 250)
               , aSQM_ANC_CAUSE_Rec.SAC_FREE_DATE1
               , aSQM_ANC_CAUSE_Rec.SAC_FREE_DATE2
               , aSQM_ANC_CAUSE_Rec.SAC_FREE_DATE3
               , aSQM_ANC_CAUSE_Rec.SAC_FREE_DATE4
               , aSQM_ANC_CAUSE_Rec.SAC_FREE_DATE5
               , aSQM_ANC_CAUSE_Rec.SAC_FREE_NUMBER1
               , aSQM_ANC_CAUSE_Rec.SAC_FREE_NUMBER2
               , aSQM_ANC_CAUSE_Rec.SAC_FREE_NUMBER3
               , aSQM_ANC_CAUSE_Rec.SAC_FREE_NUMBER4
               , aSQM_ANC_CAUSE_Rec.SAC_FREE_NUMBER5
               , substr(aSQM_ANC_CAUSE_Rec.SAC_FREE_COMMENT1, 0, 4000)
               , substr(aSQM_ANC_CAUSE_Rec.SAC_FREE_COMMENT2, 0, 4000)
                );
  end Insert_NCCause;

  /* Procédure   : Insert_NCAction
  *  Description : Procedure d''insertion d'une action d'une position de NC.
  *
  */
  procedure Insert_NCAction(aSQM_ANC_ACTION_Rec in SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_ACTION_Rec)
  is
  begin
    insert into SQM_ANC_PREVENTIVE_ACTION
                (SQM_ANC_PREVENTIVE_ACTION_ID
               , PC_SPA_USER1_ID
               , PC_SPA_USER2_ID
               , SQM_ANC_POSITION_ID
               , DIC_DELAY_TYPE_ID
               , C_SPA_STATUS
               , DIC_SPA_TYPE_ID
               , SQM_ANC_CAUSE_ID
               , DIC_SPA_FREE1_ID
               , DIC_SPA_FREE2_ID
               , DIC_SPA_FREE3_ID
               , DIC_SPA_FREE4_ID
               , DIC_SPA_FREE5_ID
               , SPA_COMMENT
               , SPA_DELAY
               , SPA_DURATION
               , SPA_COST
               , SPA_END_DATE
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , SPA_FREE_TEXT1
               , SPA_FREE_TEXT2
               , SPA_FREE_TEXT3
               , SPA_FREE_TEXT4
               , SPA_FREE_TEXT5
               , SPA_FREE_DATE1
               , SPA_FREE_DATE2
               , SPA_FREE_DATE3
               , SPA_FREE_DATE4
               , SPA_FREE_DATE5
               , SPA_FREE_NUMBER1
               , SPA_FREE_NUMBER2
               , SPA_FREE_NUMBER3
               , SPA_FREE_NUMBER4
               , SPA_FREE_NUMBER5
               , SPA_FREE_COMMENT1
               , SPA_FREE_COMMENT2
               , PC_SPA_USER3_ID
               , SPA_CREATION_DATE
                )
         values (aSQM_ANC_ACTION_Rec.SQM_ANC_PREVENTIVE_ACTION_ID
               , aSQM_ANC_ACTION_Rec.PC_SPA_USER1_ID
               , aSQM_ANC_ACTION_Rec.PC_SPA_USER2_ID
               , aSQM_ANC_ACTION_Rec.SQM_ANC_POSITION_ID
               , aSQM_ANC_ACTION_Rec.DIC_DELAY_TYPE_ID
               , aSQM_ANC_ACTION_Rec.C_SPA_STATUS
               , aSQM_ANC_ACTION_Rec.DIC_SPA_TYPE_ID
               , aSQM_ANC_ACTION_Rec.SQM_ANC_CAUSE_ID
               , aSQM_ANC_ACTION_Rec.DIC_SPA_FREE1_ID
               , aSQM_ANC_ACTION_Rec.DIC_SPA_FREE2_ID
               , aSQM_ANC_ACTION_Rec.DIC_SPA_FREE3_ID
               , aSQM_ANC_ACTION_Rec.DIC_SPA_FREE4_ID
               , aSQM_ANC_ACTION_Rec.DIC_SPA_FREE5_ID
               , substr(aSQM_ANC_ACTION_Rec.SPA_COMMENT, 0, 4000)
               , aSQM_ANC_ACTION_Rec.SPA_DELAY
               , aSQM_ANC_ACTION_Rec.SPA_DURATION
               , aSQM_ANC_ACTION_Rec.SPA_COST
               , aSQM_ANC_ACTION_Rec.SPA_END_DATE
               , aSQM_ANC_ACTION_Rec.A_DATECRE
               , aSQM_ANC_ACTION_Rec.A_DATEMOD
               , aSQM_ANC_ACTION_Rec.A_IDCRE
               , aSQM_ANC_ACTION_Rec.A_IDMOD
               , substr(aSQM_ANC_ACTION_Rec.SPA_FREE_TEXT1, 0, 250)
               , substr(aSQM_ANC_ACTION_Rec.SPA_FREE_TEXT2, 0, 250)
               , substr(aSQM_ANC_ACTION_Rec.SPA_FREE_TEXT3, 0, 250)
               , substr(aSQM_ANC_ACTION_Rec.SPA_FREE_TEXT4, 0, 250)
               , substr(aSQM_ANC_ACTION_Rec.SPA_FREE_TEXT5, 0, 250)
               , aSQM_ANC_ACTION_Rec.SPA_FREE_DATE1
               , aSQM_ANC_ACTION_Rec.SPA_FREE_DATE2
               , aSQM_ANC_ACTION_Rec.SPA_FREE_DATE3
               , aSQM_ANC_ACTION_Rec.SPA_FREE_DATE4
               , aSQM_ANC_ACTION_Rec.SPA_FREE_DATE5
               , aSQM_ANC_ACTION_Rec.SPA_FREE_NUMBER1
               , aSQM_ANC_ACTION_Rec.SPA_FREE_NUMBER2
               , aSQM_ANC_ACTION_Rec.SPA_FREE_NUMBER3
               , aSQM_ANC_ACTION_Rec.SPA_FREE_NUMBER4
               , aSQM_ANC_ACTION_Rec.SPA_FREE_NUMBER5
               , substr(aSQM_ANC_ACTION_Rec.SPA_FREE_COMMENT1, 0, 4000)
               , substr(aSQM_ANC_ACTION_Rec.SPA_FREE_COMMENT2, 0, 4000)
               , aSQM_ANC_ACTION_Rec.PC_SPA_USER3_ID
               , aSQM_ANC_ACTION_Rec.SPA_CREATION_DATE
                );
  end Insert_NCAction;

  /* Procédure   : Insert_NCPosition
  *  Description : Procedure d''insertion d'un lien sur une position de NC ou une Correction
  *
  */
  procedure Insert_NCLink(aSQM_ANC_LINK_Rec in SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_LINK_Rec)
  is
  begin
    insert into SQM_ANC_LINK
                (SQM_ANC_LINK_ID
               , SQM_ANC_ID
               , SQM_ANC_POSITION_ID
               , SQM_ANC_DIRECT_ACTION_ID
               , FAL_SCHEDULE_STEP2_ID
               , STM_ELEMENT_NUMBER1_ID
               , STM_ELEMENT_NUMBER2_ID
               , DOC_DOCUMENT_ID
               , FAL_LOT_ID
               , DOC_POSITION_DETAIL_ID
               , FAL_LOT_DETAIL_ID
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
                )
         values (aSQM_ANC_LINK_Rec.SQM_ANC_LINK_ID
               , aSQM_ANC_LINK_Rec.SQM_ANC_ID
               , aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID
               , aSQM_ANC_LINK_Rec.SQM_ANC_DIRECT_ACTION_ID
               , aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID
               , aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID
               , aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID
               , aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID
               , aSQM_ANC_LINK_Rec.FAL_LOT_ID
               , aSQM_ANC_LINK_Rec.DOC_POSITION_DETAIL_ID
               , aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID
               , aSQM_ANC_LINK_Rec.A_DATECRE
               , aSQM_ANC_LINK_Rec.A_DATEMOD
               , aSQM_ANC_LINK_Rec.A_IDCRE
               , aSQM_ANC_LINK_Rec.A_IDMOD
                );
  end Insert_NCLink;

  /* Procédure   : CalculateANCPositionFields
  *  Description : Procedure d'ajout au record des champs calculés
  *
  */
  procedure CalculateANCPositionFields(aSQM_ANC_POSITION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_POSITION_Rec)
  is
    aResultat SQM_ANC_FUNCTIONS.MaxVarchar2;
  begin
    -- Statut position de NC (A valider).
    aSQM_ANC_POSITION_Rec.C_ANC_POS_STATUS  := '1';

    -- ID Position de NC.
    select INIT_ID_SEQ.nextval
      into aSQM_ANC_POSITION_Rec.SQM_ANC_POSITION_ID
      from dual;

    -- Numéro de NC.
    SQM_ANC_FUNCTIONS.GetANCPositionNumber(aSQM_ANC_POSITION_Rec.SQM_ANC_ID, aSQM_ANC_POSITION_Rec.SAP_NUMBER);

    -- Référence secondaire bien
    if aSQM_ANC_POSITION_Rec.GCO_GOOD_ID is not null then
      aSQM_ANC_POSITION_Rec.SAP_SECOND_REF  := FAL_TOOLS.GetGOO_SECONDARY_REFERENCE(aSQM_ANC_POSITION_Rec.GCO_GOOD_ID);
    end if;
  -- Créateur de  la NC
  end;

  /* Procédure   : CalculateNCCorrectionFields
  *  Description : Procedure d'ajout au record des champs calculés
  *
  */
  procedure CalculateNCCorrectionFields(
    aSQM_ANC_CORRECTION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CORRECTION_Rec
  )
  is
    aResultat SQM_ANC_FUNCTIONS.MaxVarchar2;
  begin
    -- Statut correction (Plannifiée en création).
    aSQM_ANC_CORRECTION_Rec.C_SDA_STATUS  := '1';

    -- ID Correction
    select INIT_ID_SEQ.nextval
      into aSQM_ANC_CORRECTION_Rec.SQM_ANC_DIRECT_ACTION_ID
      from dual;

    -- Date création
    aSQM_ANC_CORRECTION_Rec.A_DATECRE     := sysdate;
  end CalculateNCCorrectionFields;

  /* Procédure   : CalculateNCCauseFields
  *  Description : Procedure d'ajout au record des champs calculés
  *
  */
  procedure CalculateNCCauseFields(aSQM_ANC_CAUSE_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CAUSE_Rec)
  is
    aResultat SQM_ANC_FUNCTIONS.MaxVarchar2;
  begin
    -- ID Cause
    select INIT_ID_SEQ.nextval
      into aSQM_ANC_CAUSE_Rec.SQM_ANC_CAUSE_ID
      from dual;

    -- Date création
    aSQM_ANC_CAUSE_Rec.A_DATECRE  := sysdate;
  end CalculateNCCauseFields;

  /* Procédure   : CalculateNCActionFields
  *  Description : Procedure d'ajout au record des champs calculés
  *
  */
  procedure CalculateNCActionFields(aSQM_ANC_ACTION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_ACTION_Rec)
  is
    aResultat SQM_ANC_FUNCTIONS.MaxVarchar2;
  begin
    -- Statut "a valider" en création
    aSQM_ANC_ACTION_Rec.C_SPA_STATUS  := '1';

    -- ID Action
    select INIT_ID_SEQ.nextval
      into aSQM_ANC_ACTION_Rec.SQM_ANC_PREVENTIVE_ACTION_ID
      from dual;

    -- Date création
    aSQM_ANC_ACTION_Rec.A_DATECRE     := sysdate;
  end CalculateNCActionFields;

  /* Procédure   : CalculateNCLinkFields
  *  Description : Procedure d'ajout au record des champs calculés
  *
  */
  procedure CalculateNCLinkFields(aSQM_ANC_LINK_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_LINK_Rec)
  is
  begin
    -- ID Action
    select INIT_ID_SEQ.nextval
      into aSQM_ANC_LINK_Rec.SQM_ANC_LINK_ID
      from dual;

    -- Date création
    aSQM_ANC_LINK_Rec.A_DATECRE  := sysdate;
  end CalculateNCLinkFields;

  /**
  * Procedure    : FormatANCPosWithGenParams
  * Description  : Formatage du record mémoire de stockage de la position de NC avec les paramètres d'appel de la fonction
  *                de génération de celle-ci, si une initialisation préalable n'a pas déjà été effectuée.
  */
  procedure FormatANCPosWithGenParams(
    aSQM_ANC_POSITION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_POSITION_Rec
  , aSQM_ANC_ID           in     SQM_ANC_POSITION.SQM_ANC_ID%type   -- NC.
  , aGCO_GOOD_ID          in     SQM_ANC_POSITION.GCO_GOOD_ID%type   -- Bien.
  , aDIC_SAP_CTRL_ID      in     SQM_ANC_POSITION.DIC_SAP_CTRL_ID%type   -- Etat du contrôle.
  , aDIC_SAP_CDEF_ID      in     SQM_ANC_POSITION.DIC_SAP_CDEF_ID%type   -- Cause du défaut.
  , aDIC_SAP_NDEF_ID      in     SQM_ANC_POSITION.DIC_SAP_NDEF_ID%type   -- Nature du défaut.
  , aDIC_SAP_DECISION_ID  in     SQM_ANC_POSITION.DIC_SAP_DECISION_ID%type   -- Decision prise.
  , aDIC_SAP_RESP_ID      in     SQM_ANC_POSITION.DIC_SAP_RESP_ID%type   -- Dept. responsable.
  , aDOC_DOCUMENT2_ID     in     SQM_ANC_POSITION.DOC_DOCUMENT2_ID%type   -- Document retour.
  , aSAP_PARTNER_REF      in     SQM_ANC_POSITION.SAP_PARTNER_REF%type   -- Référence tier
  , aSAP_COMMENT          in     SQM_ANC_POSITION.SAP_COMMENT%type   -- Description defaut.
  , aSAP_QTY_ACCEPT       in     SQM_ANC_POSITION.SAP_QTY_ACCEPT%type   -- Qté bonne.
  , aSAP_QTY_DEFECTIVE    in     SQM_ANC_POSITION.SAP_QTY_DEFECTIVE%type   -- Qté deffectueuse.
  , aSAP_ACTUAL_VALUE     in     SQM_ANC_POSITION.SAP_ACTUAL_VALUE%type   -- Valeur actuelle.
  , aSAP_REQUIRE_VALUE    in     SQM_ANC_POSITION.SAP_REQUIRE_VALUE%type   -- Valeur attendue.
  , aSAP_TITLE            in     SQM_ANC_POSITION.SAP_TITLE%type   -- Intitulé position.
  , aA_IDCRE              in     SQM_ANC_POSITION.A_IDCRE%type   -- User Création.
  , aSAP_CREATION_DATE    in     SQM_ANC_POSITION.SAP_CREATION_DATE%type
  )   -- date Creation Position.
  is
  begin
    -- ANC .
    aSQM_ANC_POSITION_Rec.SQM_ANC_ID           := nvl(aSQM_ANC_POSITION_Rec.SQM_ANC_ID, aSQM_ANC_ID);
    -- Bien
    aSQM_ANC_POSITION_Rec.GCO_GOOD_ID          := nvl(aSQM_ANC_POSITION_Rec.GCO_GOOD_ID, aGCO_GOOD_ID);
    -- Etat du contrôle
    aSQM_ANC_POSITION_Rec.DIC_SAP_CTRL_ID      := nvl(aSQM_ANC_POSITION_Rec.DIC_SAP_CTRL_ID, aDIC_SAP_CTRL_ID);
    -- Cause du défaut
    aSQM_ANC_POSITION_Rec.DIC_SAP_CDEF_ID      := nvl(aSQM_ANC_POSITION_Rec.DIC_SAP_CDEF_ID, aDIC_SAP_CDEF_ID);
    -- Nature du défaut
    aSQM_ANC_POSITION_Rec.DIC_SAP_NDEF_ID      := nvl(aSQM_ANC_POSITION_Rec.DIC_SAP_NDEF_ID, aDIC_SAP_NDEF_ID);
    -- Décision prise
    aSQM_ANC_POSITION_Rec.DIC_SAP_DECISION_ID  := nvl(aSQM_ANC_POSITION_Rec.DIC_SAP_DECISION_ID, aDIC_SAP_DECISION_ID);
    -- Dept. responsable
    aSQM_ANC_POSITION_Rec.DIC_SAP_RESP_ID      := nvl(aSQM_ANC_POSITION_Rec.DIC_SAP_RESP_ID, aDIC_SAP_RESP_ID);
    -- Document retour
    aSQM_ANC_POSITION_Rec.DOC_DOCUMENT2_ID     := nvl(aSQM_ANC_POSITION_Rec.DOC_DOCUMENT2_ID, aDOC_DOCUMENT2_ID);
    -- Référence tiers
    aSQM_ANC_POSITION_Rec.SAP_PARTNER_REF      :=
                                           nvl(aSQM_ANC_POSITION_Rec.SAP_PARTNER_REF, substr(aSAP_PARTNER_REF, 0, 30) );
    --  Descr.défaut
    aSQM_ANC_POSITION_Rec.SAP_COMMENT          :=
                                                 nvl(aSQM_ANC_POSITION_Rec.SAP_COMMENT, substr(aSAP_COMMENT, 0, 4000) );
    -- Qté bonne
    aSQM_ANC_POSITION_Rec.SAP_QTY_ACCEPT       := nvl(aSQM_ANC_POSITION_Rec.SAP_QTY_ACCEPT, aSAP_QTY_ACCEPT);
    -- Qté defectueuse
    aSQM_ANC_POSITION_Rec.SAP_QTY_DEFECTIVE    := nvl(aSQM_ANC_POSITION_Rec.SAP_QTY_DEFECTIVE, aSAP_QTY_DEFECTIVE);
    -- Qté actuelle
    aSQM_ANC_POSITION_Rec.SAP_ACTUAL_VALUE     := nvl(aSQM_ANC_POSITION_Rec.SAP_ACTUAL_VALUE, aSAP_ACTUAL_VALUE);
    -- Valeur attendue
    aSQM_ANC_POSITION_Rec.SAP_REQUIRE_VALUE    := nvl(aSQM_ANC_POSITION_Rec.SAP_REQUIRE_VALUE, aSAP_REQUIRE_VALUE);
    -- Intitulé
    aSQM_ANC_POSITION_Rec.SAP_TITLE            := nvl(aSQM_ANC_POSITION_Rec.SAP_TITLE, substr(aSAP_TITLE, 0, 30) );
    -- Créateur
    aSQM_ANC_POSITION_Rec.A_IDCRE              := nvl(aSQM_ANC_POSITION_Rec.A_IDCRE, aA_IDCRE);
    -- Date création
    aSQM_ANC_POSITION_Rec.SAP_CREATION_DATE    := nvl(aSQM_ANC_POSITION_Rec.SAP_CREATION_DATE, aSAP_CREATION_DATE);
  end FormatANCPosWithGenParams;

  /**
  * Procedure    : FormatANCPosWithGenParams
  * Description  : Formatage du record mémoire de stockage de la position de NC avec les paramètres d'appel de la fonction
  *                de génération de celle-ci, si une initialisation préalable n'a pas déjà été effectuée.
  */
  procedure FormatNCCorWithGenParams(
    aSQM_ANC_CORRECTION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CORRECTION_Rec
  , aSQM_ANC_POSITION_ID    in     SQM_ANC_DIRECT_ACTION.SQM_ANC_POSITION_ID%type   -- Position
  , aPC_SDA_USER1_ID        in     SQM_ANC_DIRECT_ACTION.PC_SDA_USER1_ID%type   -- Responsable.
  , aDIC_DELAY_TYPE_ID      in     SQM_ANC_DIRECT_ACTION.DIC_DELAY_TYPE_ID%type   -- Code délai.
  , aSDA_COMMENT            in     SQM_ANC_DIRECT_ACTION.SDA_COMMENT%type   -- Description correction
  , aSDA_DELAY              in     SQM_ANC_DIRECT_ACTION.SDA_DELAY%type   -- Délai.
  , aSDA_COST               in     SQM_ANC_DIRECT_ACTION.SDA_COST%type   -- Coût
  , aA_IDCRE                in     SQM_ANC_DIRECT_ACTION.A_IDCRE%type   -- ID création
  , aPC_SDA_USER3_ID        in     SQM_ANC_DIRECT_ACTION.PC_SDA_USER3_ID%type   -- User création
  , aSDA_CREATION_DATE      in     SQM_ANC_DIRECT_ACTION.SDA_CREATION_DATE%type   -- Date
  , aDIC_SDA_TYPE_ID        in     SQM_ANC_DIRECT_ACTION.DIC_SDA_TYPE_ID%type
  )   -- Type de correction
  is
  begin
    -- Position
    aSQM_ANC_CORRECTION_Rec.SQM_ANC_POSITION_ID  :=
                                                 nvl(aSQM_ANC_CORRECTION_Rec.SQM_ANC_POSITION_ID, aSQM_ANC_POSITION_ID);
    -- Responsable.
    aSQM_ANC_CORRECTION_Rec.PC_SDA_USER1_ID      := nvl(aSQM_ANC_CORRECTION_Rec.PC_SDA_USER1_ID, aPC_SDA_USER1_ID);
    -- Code délai.
    aSQM_ANC_CORRECTION_Rec.DIC_DELAY_TYPE_ID    := nvl(aSQM_ANC_CORRECTION_Rec.DIC_DELAY_TYPE_ID, aDIC_DELAY_TYPE_ID);
    -- Description correction
    aSQM_ANC_CORRECTION_Rec.SDA_COMMENT          :=
                                                 nvl(aSQM_ANC_CORRECTION_Rec.SDA_COMMENT, substr(aSDA_COMMENT, 0, 50) );
    -- Délai.
    aSQM_ANC_CORRECTION_Rec.SDA_DELAY            := nvl(aSQM_ANC_CORRECTION_Rec.SDA_DELAY, aSDA_DELAY);
    -- Coût
    aSQM_ANC_CORRECTION_Rec.SDA_COST             := nvl(aSQM_ANC_CORRECTION_Rec.SDA_COST, aSDA_COST);
    -- ID création
    aSQM_ANC_CORRECTION_Rec.A_IDCRE              := nvl(aSQM_ANC_CORRECTION_Rec.A_IDCRE, aA_IDCRE);
    -- User création
    aSQM_ANC_CORRECTION_Rec.PC_SDA_USER3_ID      := nvl(aSQM_ANC_CORRECTION_Rec.PC_SDA_USER3_ID, aPC_SDA_USER3_ID);
    -- Date
    aSQM_ANC_CORRECTION_Rec.SDA_CREATION_DATE    := nvl(aSQM_ANC_CORRECTION_Rec.SDA_CREATION_DATE, aSDA_CREATION_DATE);
    -- Type de correction
    aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID      := nvl(aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID, aDIC_SDA_TYPE_ID);
  end FormatNCCorWithGenParams;

  /**
  * procedure   : FormatNCCorWithGenParams
  * Description : Formatage du record mémoire de stockage de la correction de la position de NC avec les paramètres d'appel de la fonction
  *               de génération de celle-ci, si une initialisation préalable n'a pas déjà été effectuée.
  */
  procedure FormatNCCauseWithGenParams(
    aSQM_ANC_CAUSE_Rec   in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CAUSE_REC
  , aSQM_ANC_POSITION_ID in     SQM_ANC_CAUSE.SQM_ANC_POSITION_ID%type   -- Position
  , aDIC_SAC_TYPE_ID     in     SQM_ANC_CAUSE.DIC_SAC_TYPE_ID%type   -- Type de cause
  , aSAC_COMMENT         in     SQM_ANC_CAUSE.SAC_COMMENT%type   -- Commentaire
  , aA_IDCRE             in     SQM_ANC_CAUSE.A_IDCRE%type
  )   -- ID création
  is
  begin
    -- Position
    aSQM_ANC_CAUSE_Rec.SQM_ANC_POSITION_ID  := nvl(aSQM_ANC_CAUSE_Rec.SQM_ANC_POSITION_ID, aSQM_ANC_POSITION_ID);
    -- Type de cause
    aSQM_ANC_CAUSE_Rec.DIC_SAC_TYPE_ID      := nvl(aSQM_ANC_CAUSE_Rec.DIC_SAC_TYPE_ID, aDIC_SAC_TYPE_ID);
    -- Commentaire
    aSQM_ANC_CAUSE_Rec.SAC_COMMENT          := nvl(aSQM_ANC_CAUSE_Rec.SAC_COMMENT, substr(aSAC_COMMENT, 0, 4000) );
    -- ID création
    aSQM_ANC_CAUSE_Rec.A_IDCRE              := nvl(aSQM_ANC_CAUSE_Rec.A_IDCRE, aA_IDCRE);
  end FormatNCCauseWithGenParams;

  /**
  * Procedure    : FormatNCActionWithGenParams
  * Description  : Formatage du record mémoire de stockage d'une action de position de NC avec les paramètres d'appel de la fonction
  *                de génération de celle-ci, si une initialisation préalable n'a pas déjà été effectuée.
  */
  procedure FormatNCActionWithGenParams(
    aSQM_ANC_ACTION_REC  in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_ACTION_Rec
  , aSQM_ANC_POSITION_ID in     SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_POSITION_ID%type   -- Position
  , aSQM_ANC_CAUSE_ID    in     SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_CAUSE_ID%type   -- Cause
  , aPC_SPA_USER1_ID     in     SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER1_ID%type   -- Responsable
  , aDIC_DELAY_TYPE_ID   in     SQM_ANC_PREVENTIVE_ACTION.DIC_DELAY_TYPE_ID%type   -- Type de délai
  , aDIC_SPA_TYPE_ID     in     SQM_ANC_PREVENTIVE_ACTION.DIC_SPA_TYPE_ID%type   -- Type d'action
  , aSPA_COMMENT         in     SQM_ANC_PREVENTIVE_ACTION.SPA_COMMENT%type   -- Description action
  , aSPA_DELAY           in     SQM_ANC_PREVENTIVE_ACTION.SPA_DELAY%type   -- Délai
  , aSPA_COST            in     SQM_ANC_PREVENTIVE_ACTION.SPA_COST%type   -- Coût
  , aA_IDCRE             in     SQM_ANC_PREVENTIVE_ACTION.A_IDCRE%type   -- ID creation
  , aPC_SPA_USER3_ID     in     SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER3_ID%type   -- User création
  , aSPA_CREATION_DATE   in     SQM_ANC_PREVENTIVE_ACTION.SPA_CREATION_DATE%type
  )   -- Date création
  is
  begin
    -- Position
    aSQM_ANC_ACTION_REC.SQM_ANC_POSITION_ID  := nvl(aSQM_ANC_ACTION_REC.SQM_ANC_POSITION_ID, aSQM_ANC_POSITION_ID);
    -- Cause
    aSQM_ANC_ACTION_REC.SQM_ANC_CAUSE_ID     := nvl(aSQM_ANC_ACTION_REC.SQM_ANC_CAUSE_ID, aSQM_ANC_CAUSE_ID);
    -- Responsable
    aSQM_ANC_ACTION_REC.PC_SPA_USER1_ID      := nvl(aSQM_ANC_ACTION_REC.PC_SPA_USER1_ID, aPC_SPA_USER1_ID);
    -- Type de délai
    aSQM_ANC_ACTION_REC.DIC_DELAY_TYPE_ID    := nvl(aSQM_ANC_ACTION_REC.DIC_DELAY_TYPE_ID, aDIC_DELAY_TYPE_ID);
    -- Type d'action
    aSQM_ANC_ACTION_REC.DIC_SPA_TYPE_ID      := nvl(aSQM_ANC_ACTION_REC.DIC_SPA_TYPE_ID, aDIC_SPA_TYPE_ID);
    -- Description action
    aSQM_ANC_ACTION_REC.SPA_COMMENT          := nvl(aSQM_ANC_ACTION_REC.SPA_COMMENT, substr(aSPA_COMMENT, 0, 4000) );
    -- Délai
    aSQM_ANC_ACTION_REC.SPA_DELAY            := nvl(aSQM_ANC_ACTION_REC.SPA_DELAY, aSPA_DELAY);
    -- Coût
    aSQM_ANC_ACTION_REC.SPA_COST             := nvl(aSQM_ANC_ACTION_REC.SPA_COST, aSPA_COST);
    -- ID creation
    aSQM_ANC_ACTION_REC.A_IDCRE              := nvl(aSQM_ANC_ACTION_REC.A_IDCRE, aA_IDCRE);
    -- User création
    aSQM_ANC_ACTION_REC.PC_SPA_USER3_ID      := nvl(aSQM_ANC_ACTION_REC.PC_SPA_USER3_ID, aPC_SPA_USER3_ID);
    -- Date création
    aSQM_ANC_ACTION_REC.SPA_CREATION_DATE    := nvl(aSQM_ANC_ACTION_REC.SPA_CREATION_DATE, aSPA_CREATION_DATE);
  end FormatNCActionWithGenParams;

  /**
  * Procedure    : FormatNCActionWithGenParams
  * Description  : Formatage du record mémoire de stockage d'une action de position de NC avec les paramètres d'appel de la fonction
  *                de génération de celle-ci, si une initialisation préalable n'a pas déjà été effectuée.
  */
  procedure FormatNCLinkWithGenParams(
    aSQM_ANC_LINK_Rec       in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_LINK_Rec
  , aSQM_ANC_POSITION_ID    in     SQM_ANC_LINK.SQM_ANC_POSITION_ID%type   -- Position de NC
  , aSQM_ANC_CORRECTION_ID  in     SQM_ANC_LINK.SQM_ANC_DIRECT_ACTION_ID%type   -- Correction
  , aSTM_ELEMENT_NUMBER1_ID in     SQM_ANC_LINK.STM_ELEMENT_NUMBER1_ID%type   -- Caractérisation 1 (Pièce).
  , aSTM_ELEMENT_NUMBER2_ID in     SQM_ANC_LINK.STM_ELEMENT_NUMBER2_ID%type   -- Caractérisation 2 (Lot).
  , aDOC_DOCUMENT_ID        in     SQM_ANC_LINK.DOC_DOCUMENT_ID%type   -- Document
  , aDOC_POSITION_DETAIL_ID in     SQM_ANC_LINK.DOC_POSITION_DETAIL_ID%type   -- Détail position
  , aFAL_LOT_ID             in     SQM_ANC_LINK.FAL_LOT_ID%type   -- Lot.
  , aFAL_SCHEDULE_STEP2_ID  in     SQM_ANC_LINK.FAL_SCHEDULE_STEP2_ID%type   -- Opération
  , aFAL_LOT_DETAIL_ID      in     SQM_ANC_LINK.FAL_LOT_DETAIL_ID%type   -- Détail lot
  , aA_IDCRE                in     SQM_ANC_LINK.A_IDCRE%type
  )   -- ID création
  is
  begin
    -- Position.
    aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID       := nvl(aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID, aSQM_ANC_POSITION_ID);
    -- Correction
    aSQM_ANC_LINK_Rec.SQM_ANC_DIRECT_ACTION_ID  :=
                                                nvl(aSQM_ANC_LINK_Rec.SQM_ANC_DIRECT_ACTION_ID, aSQM_ANC_CORRECTION_ID);
    -- Caractérisation 1 (Piece)
    aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID    :=
                                                 nvl(aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID, aSTM_ELEMENT_NUMBER1_ID);
    -- Caractérisation 2 (Lot)
    aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID    :=
                                                 nvl(aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID, aSTM_ELEMENT_NUMBER2_ID);
    -- Document
    aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID           := nvl(aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID, aDOC_DOCUMENT_ID);
    -- Détail position de document
    aSQM_ANC_LINK_Rec.DOC_POSITION_DETAIL_ID    :=
                                                 nvl(aSQM_ANC_LINK_Rec.DOC_POSITION_DETAIL_ID, aDOC_POSITION_DETAIL_ID);
    -- Lot
    aSQM_ANC_LINK_Rec.FAL_LOT_ID                := nvl(aSQM_ANC_LINK_Rec.FAL_LOT_ID, aFAL_LOT_ID);
    -- Opération
    aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID     := nvl(aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID, aFAL_SCHEDULE_STEP2_ID);
    -- Détail Lot
    aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID         := nvl(aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID, aFAL_LOT_DETAIL_ID);
    -- Créateur
    aSQM_ANC_LINK_Rec.A_IDCRE                   := nvl(aSQM_ANC_LINK_Rec.A_IDCRE, aA_IDCRE);
  end FormatNCLinkWithGenParams;

  /**
  * procdure GenerateANC .
  * Description :  procedure de génération hors interface d'une position de NC.
  *          La procédure d'initialisation individualisée permet une initialisation autre que celle par défaut
  *          Si une procédure d'initialisation indiv. est précisée alors les paramètres de cette fonction ne sont utilisés
  *                que si cette procédure d'initialisation n'a pas déjà initialisé les champs de la position de NC correspondante.
  */
  function GenerateNCPosition(
    aSQM_ANC_ID          in SQM_ANC_POSITION.SQM_ANC_ID%type   -- NC.
  , aGCO_GOOD_ID         in SQM_ANC_POSITION.GCO_GOOD_ID%type   -- Bien.
  , aDIC_SAP_CTRL_ID     in SQM_ANC_POSITION.DIC_SAP_CTRL_ID%type   -- Etat du contrôle.
  , aDIC_SAP_CDEF_ID     in SQM_ANC_POSITION.DIC_SAP_CDEF_ID%type   -- Cause du défaut.
  , aDIC_SAP_NDEF_ID     in SQM_ANC_POSITION.DIC_SAP_NDEF_ID%type   -- Nature du défaut.
  , aDIC_SAP_DECISION_ID in SQM_ANC_POSITION.DIC_SAP_DECISION_ID%type   -- Decision prise.
  , aDIC_SAP_RESP_ID     in SQM_ANC_POSITION.DIC_SAP_RESP_ID%type   -- Dept. responsable.
  , aDOC_DOCUMENT2_ID    in SQM_ANC_POSITION.DOC_DOCUMENT2_ID%type   -- Document retour.
  , aSAP_PARTNER_REF     in SQM_ANC_POSITION.SAP_PARTNER_REF%type   -- Référence tier
  , aSAP_COMMENT         in SQM_ANC_POSITION.SAP_COMMENT%type   -- Description defaut.
  , aSAP_QTY_ACCEPT      in SQM_ANC_POSITION.SAP_QTY_ACCEPT%type   -- Qté bonne.
  , aSAP_QTY_DEFECTIVE   in SQM_ANC_POSITION.SAP_QTY_DEFECTIVE%type   -- Qté deffectueuse.
  , aSAP_ACTUAL_VALUE    in SQM_ANC_POSITION.SAP_ACTUAL_VALUE%type   -- Valeur actuelle.
  , aSAP_REQUIRE_VALUE   in SQM_ANC_POSITION.SAP_REQUIRE_VALUE%type   -- Valeur attendue.
  , aSAP_TITLE           in SQM_ANC_POSITION.SAP_TITLE%type   -- Intitulé position.
  , aA_IDCRE             in SQM_ANC_POSITION.A_IDCRE%type   -- User Création.
  , aSAP_CREATION_DATE   in SQM_ANC_POSITION.SAP_CREATION_DATE%type   -- date Creation Position.
  , aIndivInitProc       in varchar2 default null   -- Procédure d'initialisation individualisée.
  , aStringParam1        in varchar2 default null   -- paramètres utilisable pour la procedure indiv d'initialisation
  , aStringParam2        in varchar2 default null   -- idem.
  , aStringParam3        in varchar2 default null   -- idem.
  , aStringParam4        in varchar2 default null   -- idem.
  , aStringParam5        in varchar2 default null   -- idem.
  , aCurrencyParam1      in number default null   -- idem.
  , aCurrencyParam2      in number default null   -- idem.
  , aCurrencyParam3      in number default null   -- idem.
  , aCurrencyParam4      in number default null   -- idem.
  , aCurrencyParam5      in number default null   -- idem.
  , aIntegerParam1       in integer default null   -- idem.
  , aIntegerParam2       in integer default null   -- idem.
  , aIntegerParam3       in integer default null   -- idem.
  , aIntegerParam4       in integer default null   -- idem.
  , aIntegerParam5       in integer default null   -- idem.
  , aDateParam1          in date default null   -- idem.
  , aDateParam2          in date default null   -- idem.
  , aDateParam3          in date default null   -- idem.
  , aDateParam4          in date default null   -- idem.
  , aDateParam5          in date default null
  )   -- idem.
    return SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type
  is
    -- Champs calculés
    aCanCreate boolean;
  begin
    -- Vérification de l'information prédominante à la création de la NC : Son Type
    if aSQM_ANC_ID is not null then
      -- RAZ des Variables globales.
      SQM_ANC_POSITION_INITIALIZE.ResetANCPositionRecord(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_POSITION_Rec);

      -- Initialisation du Record : Si initialisation indiv .
      if aIndivInitProc is not null then
        SQM_ANC_INITIALIZE.CallIndivInitProc(aIndivInitProc
                                           , 'SQM_ANC_POSITION_INITIALIZE.SQM_ANC_POSITION_Rec'
                                           , aStringparam1
                                           , aStringParam2
                                           , aStringParam3
                                           , aStringParam4
                                           , aStringParam5
                                           , aCurrencyParam1
                                           , aCurrencyParam2
                                           , aCurrencyParam3
                                           , aCurrencyParam4
                                           , aCurrencyParam5
                                           , aIntegerParam1
                                           , aIntegerParam2
                                           , aIntegerParam3
                                           , aIntegerParam4
                                           , aIntegerParam5
                                           , aDateParam1
                                           , aDateParam2
                                           , aDateParam3
                                           , aDateParam4
                                           , aDateParam5
                                            );
      end if;

      -- Utilisation des paramètres d'appel de la fonction.
      FormatANCPosWithGenParams(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_POSITION_Rec
                              , aSQM_ANC_ID
                              , aGCO_GOOD_ID
                              , aDIC_SAP_CTRL_ID
                              , aDIC_SAP_CDEF_ID
                              , aDIC_SAP_NDEF_ID
                              , aDIC_SAP_DECISION_ID
                              , aDIC_SAP_RESP_ID
                              , aDOC_DOCUMENT2_ID
                              , aSAP_PARTNER_REF
                              , aSAP_COMMENT
                              , aSAP_QTY_ACCEPT
                              , aSAP_QTY_DEFECTIVE
                              , aSAP_ACTUAL_VALUE
                              , aSAP_REQUIRE_VALUE
                              , aSAP_TITLE
                              , aA_IDCRE
                              , aSAP_CREATION_DATE
                               );
      -- Champs calculés:
      CalculateANCPositionFields(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_POSITION_Rec);
      -- Vérification des règles d'intégrité de la NC.
      CheckNCPositionIntegrity(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_POSITION_Rec, aCanCreate);

      -- Création de la position de NC.
      if aCanCreate then
        Insert_NCPosition(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_POSITION_Rec);
      end if;

      -- Finalisation
      FinalizeNC(aSQM_ANC_ID);
      return SQM_ANC_POSITION_INITIALIZE.SQM_ANC_Position_Rec.SQM_ANC_POSITION_ID;
    -- ANC de la position non précisée
    else
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord('Erreur à la création de la position. La NC de la position doit être précisée!')
       , aSQM_ANC_ID
       , 1
        );
      return null;
    end if;
  exception
    when others then
      begin
        SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur à la création de la position') ||
                                        ' ' ||
                                        sqlcode ||
                                        ' ' ||
                                        sqlerrm
                                      , aSQM_ANC_ID
                                      , 1
                                       );
        return null;
      end;
  end GenerateNCPosition;

  /**
  * procdure GenerateCorrection
  * Description :  Procedure de génération hors interface d'une Correction pour une position de NC
  *          La procédure d'initialisation individualisée permet une initialisation autre que celle par défaut
  *          Si une procédure d'initialisation indiv. est précisée alors les paramètres de cette fonction ne sont utilisés
  *                que si cette procédure d'initialisation n'a pas déjà initialisé les champs de la Correction de la position de NC correspondante.
  */
  function GenerateNCCorrection(
    aSQM_ANC_POSITION_ID    SQM_ANC_DIRECT_ACTION.SQM_ANC_POSITION_ID%type   -- Position NC.
  , aPC_SDA_USER1_ID        SQM_ANC_DIRECT_ACTION.PC_SDA_USER1_ID%type   -- Responsable.
  , aDIC_DELAY_TYPE_ID      SQM_ANC_DIRECT_ACTION.DIC_DELAY_TYPE_ID%type   -- Code délai.
  , aSDA_COMMENT            SQM_ANC_DIRECT_ACTION.SDA_COMMENT%type   -- Description correction
  , aSDA_DELAY              SQM_ANC_DIRECT_ACTION.SDA_DELAY%type   -- Délai.
  , aSDA_COST               SQM_ANC_DIRECT_ACTION.SDA_COST%type   -- Coût
  , aA_IDCRE                SQM_ANC_DIRECT_ACTION.A_IDCRE%type   -- ID création
  , aPC_SDA_USER3_ID        SQM_ANC_DIRECT_ACTION.PC_SDA_USER3_ID%type   -- User création
  , aSDA_CREATION_DATE      SQM_ANC_DIRECT_ACTION.SDA_CREATION_DATE%type   -- Date création
  , aDIC_SDA_TYPE_ID        SQM_ANC_DIRECT_ACTION.DIC_SDA_TYPE_ID%type   -- Type de correction
  , aIndivInitProc       in varchar2 default null   -- Procédure d'initialisation individualisée.
  , aStringParam1        in varchar2 default null   -- paramètres utilisable pour la procedure indiv d'initialisation
  , aStringParam2        in varchar2 default null   -- idem.
  , aStringParam3        in varchar2 default null   -- idem.
  , aStringParam4        in varchar2 default null   -- idem.
  , aStringParam5        in varchar2 default null   -- idem.
  , aCurrencyParam1      in number default null   -- idem.
  , aCurrencyParam2      in number default null   -- idem.
  , aCurrencyParam3      in number default null   -- idem.
  , aCurrencyParam4      in number default null   -- idem.
  , aCurrencyParam5      in number default null   -- idem.
  , aIntegerParam1       in integer default null   -- idem.
  , aIntegerParam2       in integer default null   -- idem.
  , aIntegerParam3       in integer default null   -- idem.
  , aIntegerParam4       in integer default null   -- idem.
  , aIntegerParam5       in integer default null   -- idem.
  , aDateParam1          in date default null   -- idem.
  , aDateParam2          in date default null   -- idem.
  , aDateParam3          in date default null   -- idem.
  , aDateParam4          in date default null   -- idem.
  , aDateParam5          in date default null
  )   -- idem.
    return SQM_ANC_DIRECT_ACTION.SQM_ANC_DIRECT_ACTION_ID%type
  is
    aCanCreate  boolean;
    aSQM_ANC_ID number;
  begin
    -- Vérification de l'information prédominante à la création de la NC : Son Type
    if aSQM_ANC_POSITION_ID is not null then
      -- RAZ des Variables globales.
      SQM_ANC_POSITION_INITIALIZE.ResetNCCorrectionRecord(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CORRECTION_Rec);

      -- Initialisation du Record : Si initialisation indiv .
      if aIndivInitProc is not null then
        SQM_ANC_INITIALIZE.CallIndivInitProc(aIndivInitProc
                                           , 'SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CORRECTION_Rec'
                                           , aStringparam1
                                           , aStringParam2
                                           , aStringParam3
                                           , aStringParam4
                                           , aStringParam5
                                           , aCurrencyParam1
                                           , aCurrencyParam2
                                           , aCurrencyParam3
                                           , aCurrencyParam4
                                           , aCurrencyParam5
                                           , aIntegerParam1
                                           , aIntegerParam2
                                           , aIntegerParam3
                                           , aIntegerParam4
                                           , aIntegerParam5
                                           , aDateParam1
                                           , aDateParam2
                                           , aDateParam3
                                           , aDateParam4
                                           , aDateParam5
                                            );
      end if;

      -- Utilisation des paramètres d'appel de la fonction.
      FormatNCCorWithGenParams(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CORRECTION_Rec
                             , aSQM_ANC_POSITION_ID
                             , aPC_SDA_USER1_ID
                             , aDIC_DELAY_TYPE_ID
                             , aSDA_COMMENT
                             , aSDA_DELAY
                             , aSDA_COST
                             , aA_IDCRE
                             , aPC_SDA_USER3_ID
                             , aSDA_CREATION_DATE
                             , aDIC_SDA_TYPE_ID
                              );
      -- Champs calculés:
      CalculateNCCorrectionFields(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CORRECTION_Rec);
      -- Vérification des règles d'intégrité de la NC.
      CheckNCCorrectionIntegrity(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CORRECTION_Rec, aCanCreate);

      -- Création de la position de NC.
      if aCanCreate then
        Insert_NCCorrection(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CORRECTION_Rec);
      end if;

      -- Finalisation.
      select distinct SQM_ANC_ID
                 into aSQM_ANC_ID
                 from SQM_ANC_POSITION
                where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

      FinalizeNC(aSQM_ANC_ID);
      return SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CORRECTION_Rec.SQM_ANC_DIRECT_ACTION_ID;
    -- ANC de la position non précisée
    else
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
                        ('Erreur à la création de la correction. La position de NC de la correction doit être précisée!')
       , aSQM_ANC_ID
       , 1
        );
      return null;
    end if;
  exception
    when others then
      begin
        SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur à la création de la correction') ||
                                        ' ' ||
                                        sqlcode ||
                                        ' ' ||
                                        sqlerrm
                                      , aSQM_ANC_ID
                                      , 1
                                       );
        return null;
      end;
  end GenerateNCCorrection;

  /**
  * procdure GenerateNCCause
  * Description :  Procedure de génération hors interface d'une Cause pour une position de NC
  *          La procédure d'initialisation individualisée permet une initialisation autre que celle par défaut
  *          Si une procédure d'initialisation indiv. est précisée alors les paramètres de cette fonction ne sont utilisés
  *                que si cette procédure d'initialisation n'a pas déjà initialisé les champs de la Cause de la position de NC correspondante.
  */
  function GenerateNCCause(
    aSQM_ANC_POSITION_ID in SQM_ANC_CAUSE.SQM_ANC_POSITION_ID%type   -- ID de position
  , aDIC_SAC_TYPE_ID     in SQM_ANC_CAUSE.DIC_SAC_TYPE_ID%type   -- Type de cause
  , aSAC_COMMENT         in SQM_ANC_CAUSE.SAC_COMMENT%type   -- Commentaire
  , aA_IDCRE             in SQM_ANC_CAUSE.A_IDCRE%type   -- ID création
  , aIndivInitProc       in varchar2 default null   -- Procédure d'initialisation individualisée.
  , aStringParam1        in varchar2 default null   -- paramètres utilisable pour la procedure indiv d'initialisation
  , aStringParam2        in varchar2 default null   -- idem.
  , aStringParam3        in varchar2 default null   -- idem.
  , aStringParam4        in varchar2 default null   -- idem.
  , aStringParam5        in varchar2 default null   -- idem.
  , aCurrencyParam1      in number default null   -- idem.
  , aCurrencyParam2      in number default null   -- idem.
  , aCurrencyParam3      in number default null   -- idem.
  , aCurrencyParam4      in number default null   -- idem.
  , aCurrencyParam5      in number default null   -- idem.
  , aIntegerParam1       in integer default null   -- idem.
  , aIntegerParam2       in integer default null   -- idem.
  , aIntegerParam3       in integer default null   -- idem.
  , aIntegerParam4       in integer default null   -- idem.
  , aIntegerParam5       in integer default null   -- idem.
  , aDateParam1          in date default null   -- idem.
  , aDateParam2          in date default null   -- idem.
  , aDateParam3          in date default null   -- idem.
  , aDateParam4          in date default null   -- idem.
  , aDateParam5          in date default null
  )   -- idem.
    return SQM_ANC_CAUSE.SQM_ANC_CAUSE_ID%type
  is
    aCanCreate  boolean;
    aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type;
  begin
    -- Vérification de l'information prédominante à la création de la cause : Position et IDCRE
    if aSQM_ANC_POSITION_ID is not null then
      select SQM_ANC_ID
        into aSQM_ANC_ID
        from SQM_ANC_POSITION
       where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

      if aA_IDCRE is not null then
        -- RAZ des Variables globales.
        SQM_ANC_POSITION_INITIALIZE.ResetNCCauseRecord(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec);

        -- Initialisation du Record : Si initialisation indiv .
        if aIndivInitProc is not null then
          SQM_ANC_INITIALIZE.CallIndivInitProc(aIndivInitProc
                                             , 'SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec'
                                             , aStringparam1
                                             , aStringParam2
                                             , aStringParam3
                                             , aStringParam4
                                             , aStringParam5
                                             , aCurrencyParam1
                                             , aCurrencyParam2
                                             , aCurrencyParam3
                                             , aCurrencyParam4
                                             , aCurrencyParam5
                                             , aIntegerParam1
                                             , aIntegerParam2
                                             , aIntegerParam3
                                             , aIntegerParam4
                                             , aIntegerParam5
                                             , aDateParam1
                                             , aDateParam2
                                             , aDateParam3
                                             , aDateParam4
                                             , aDateParam5
                                              );
        end if;

        -- Utilisation des paramètres d'appel de la fonction.
        FormatNCCauseWithGenParams(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec
                                 , aSQM_ANC_POSITION_ID
                                 , aDIC_SAC_TYPE_ID
                                 , aSAC_COMMENT
                                 , aA_IDCRE
                                  );
        -- Champs calculés:
        CalculateNCCauseFields(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec);
        -- Vérification des règles d'intégrité de la NC.
        CheckNCCauseIntegrity(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec, aCanCreate);

        -- Création de la cause de position de NC.
        if aCanCreate then
          Insert_NCCause(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec);
        end if;

        return SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec.SQM_ANC_CAUSE_ID;
      -- Créateur de la NC non indiqué
      else
        SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord
                                   ('Erreur à la création de la cause. Le créateur de la cause de NC doit être indiqué!')
         , aSQM_ANC_ID
         , 1
          );
        return null;
      end if;
    -- ANC de la position non précisée
    else
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
                                  ('Erreur à la création de la cause. La position de NC de la cause doit être précisée!')
       , aSQM_ANC_ID
       , 1
        );
      return null;
    end if;
  exception
    when others then
      begin
        SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur à la création de la cause') ||
                                        ' ' ||
                                        sqlcode ||
                                        ' ' ||
                                        sqlerrm
                                      , aSQM_ANC_ID
                                      , 1
                                       );
        return null;
      end;
  end GenerateNCCause;

  /**
  * procdure GenerateNCAction
  * Description :  Procedure de génération hors interface d'une Action pour une position de NC .
  *          La procédure d'initialisation individualisée permet une initialisation autre que celle par défaut
  *          Si une procédure d'initialisation indiv. est précisée alors les paramètres de cette fonction ne sont utilisés
  *                que si cette procédure d'initialisation n'a pas déjà initialisé les champs de l'action de la position de NC correspondante.
  */
  function GenerateNCAction(
    aSQM_ANC_POSITION_ID in SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_POSITION_ID%type   -- Position
  , aSQM_ANC_CAUSE_ID    in SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_CAUSE_ID%type   -- Cause
  , aPC_SPA_USER1_ID     in SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER1_ID%type   -- Responsable
  , aDIC_DELAY_TYPE_ID   in SQM_ANC_PREVENTIVE_ACTION.DIC_DELAY_TYPE_ID%type   -- Type de délai
  , aDIC_SPA_TYPE_ID     in SQM_ANC_PREVENTIVE_ACTION.DIC_SPA_TYPE_ID%type   -- Type d'action
  , aSPA_COMMENT         in SQM_ANC_PREVENTIVE_ACTION.SPA_COMMENT%type   -- Description action
  , aSPA_DELAY           in SQM_ANC_PREVENTIVE_ACTION.SPA_DELAY%type   -- Délai
  , aSPA_COST            in SQM_ANC_PREVENTIVE_ACTION.SPA_COST%type   -- Coût
  , aA_IDCRE             in SQM_ANC_PREVENTIVE_ACTION.A_IDCRE%type   -- ID creation
  , aPC_SPA_USER3_ID     in SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER3_ID%type   -- User création
  , aSPA_CREATION_DATE   in SQM_ANC_PREVENTIVE_ACTION.SPA_CREATION_DATE%type   -- Date création
  , aIndivInitProc       in varchar2 default null   -- Procédure d'initialisation individualisée.
  , aStringParam1        in varchar2 default null   -- paramètres utilisable pour la procedure indiv d'initialisation
  , aStringParam2        in varchar2 default null   -- idem.
  , aStringParam3        in varchar2 default null   -- idem.
  , aStringParam4        in varchar2 default null   -- idem.
  , aStringParam5        in varchar2 default null   -- idem.
  , aCurrencyParam1      in number default null   -- idem.
  , aCurrencyParam2      in number default null   -- idem.
  , aCurrencyParam3      in number default null   -- idem.
  , aCurrencyParam4      in number default null   -- idem.
  , aCurrencyParam5      in number default null   -- idem.
  , aIntegerParam1       in integer default null   -- idem.
  , aIntegerParam2       in integer default null   -- idem.
  , aIntegerParam3       in integer default null   -- idem.
  , aIntegerParam4       in integer default null   -- idem.
  , aIntegerParam5       in integer default null   -- idem.
  , aDateParam1          in date default null   -- idem.
  , aDateParam2          in date default null   -- idem.
  , aDateParam3          in date default null   -- idem.
  , aDateParam4          in date default null   -- idem.
  , aDateParam5          in date default null
  )   -- idem.
    return SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_PREVENTIVE_ACTION_ID%type
  is
    aCanCreate  boolean;
    aSQM_ANC_ID number;
  begin
    -- Vérification de l'information prédominante à la création de la NC : Son Type
    if aSQM_ANC_POSITION_ID is not null then
      if aSQM_ANC_CAUSE_ID is not null then
        -- RAZ des Variables globales.
        SQM_ANC_POSITION_INITIALIZE.ResetNCActionRecord(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_ACTION_Rec);

        -- Initialisation du Record : Si initialisation indiv .
        if aIndivInitProc is not null then
          SQM_ANC_INITIALIZE.CallIndivInitProc(aIndivInitProc
                                             , 'SQM_ANC_POSITION_INITIALIZE.SQM_ANC_ACTION_Rec'
                                             , aStringparam1
                                             , aStringParam2
                                             , aStringParam3
                                             , aStringParam4
                                             , aStringParam5
                                             , aCurrencyParam1
                                             , aCurrencyParam2
                                             , aCurrencyParam3
                                             , aCurrencyParam4
                                             , aCurrencyParam5
                                             , aIntegerParam1
                                             , aIntegerParam2
                                             , aIntegerParam3
                                             , aIntegerParam4
                                             , aIntegerParam5
                                             , aDateParam1
                                             , aDateParam2
                                             , aDateParam3
                                             , aDateParam4
                                             , aDateParam5
                                              );
        end if;

        -- Utilisation des paramètres d'appel de la fonction.
        FormatNCActionWithGenParams(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_ACTION_Rec
                                  , aSQM_ANC_POSITION_ID
                                  , aSQM_ANC_CAUSE_ID
                                  , aPC_SPA_USER1_ID
                                  , aDIC_DELAY_TYPE_ID
                                  , aDIC_SPA_TYPE_ID
                                  , aSPA_COMMENT
                                  , aSPA_DELAY
                                  , aSPA_COST
                                  , aA_IDCRE
                                  , aPC_SPA_USER3_ID
                                  , aSPA_CREATION_DATE
                                   );
        -- Champs calculés:
        CalculateNCActionFields(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_ACTION_Rec);
        -- Vérification des règles d'intégrité de la NC.
        CheckNCActionIntegrity(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_ACTION_Rec, aCanCreate);

        -- Création de la position de NC.
        if aCanCreate then
          Insert_NCAction(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_ACTION_Rec);
        end if;

        -- Finalisation.
        select distinct SQM_ANC_ID
                   into aSQM_ANC_ID
                   from SQM_ANC_POSITION
                  where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

        FinalizeNC(aSQM_ANC_ID);
        return SQM_ANC_POSITION_INITIALIZE.SQM_ANC_ACTION_Rec.SQM_ANC_PREVENTIVE_ACTION_ID;
      -- Cause de l'action non précisée
      else
        SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord
                                         ('Erreur à la création de l''action. La cause de l''action doit être précisée!')
         , aSQM_ANC_ID
         , 1
          );
        return null;
      end if;
    -- Position de l'action non précisée
    else
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
                                ('Erreur à la création de l''action. La position de NC de l''action doit être précisée!')
       , aSQM_ANC_ID
       , 1
        );
      return null;
    end if;
  exception
    when others then
      begin
        SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur à la création de l''action') ||
                                        ' ' ||
                                        sqlcode ||
                                        ' ' ||
                                        sqlerrm
                                      , aSQM_ANC_ID
                                      , 1
                                       );
        return null;
      end;
  end GenerateNCAction;

  /**
  * procdure GenerateNCLinks
  * Description :  Procedure de génération hors interface de liens pour une position de NC, une correction ou une action.
  */
  function GenerateNCLinks(
    aSQM_ANC_POSITION_ID    SQM_ANC_LINK.SQM_ANC_POSITION_ID%type   -- Position de NC
  , aSQM_ANC_CORRECTION_ID  SQM_ANC_LINK.SQM_ANC_DIRECT_ACTION_ID%type   -- Action
  , aSTM_ELEMENT_NUMBER1_ID SQM_ANC_LINK.STM_ELEMENT_NUMBER1_ID%type   -- Caractérisation 1 (Pièce).
  , aSTM_ELEMENT_NUMBER2_ID SQM_ANC_LINK.STM_ELEMENT_NUMBER2_ID%type   -- Caractérisation 2 (Lot).
  , aDOC_DOCUMENT_ID        SQM_ANC_LINK.DOC_DOCUMENT_ID%type   -- Document
  , aDOC_POSITION_DETAIL_ID SQM_ANC_LINK.DOC_POSITION_DETAIL_ID%type   -- Détail position
  , aFAL_LOT_ID             SQM_ANC_LINK.FAL_LOT_ID%type   -- Lot.
  , aFAL_SCHEDULE_STEP2_ID  SQM_ANC_LINK.FAL_SCHEDULE_STEP2_ID%type   -- Opération
  , aFAL_LOT_DETAIL_ID      SQM_ANC_LINK.FAL_LOT_DETAIL_ID%type   -- Détail lot
  , aA_IDCRE                SQM_ANC_LINK.A_IDCRE%type
  )   -- ID création
    return SQM_ANC_LINK.SQM_ANC_LINK_ID%type
  is
    aCanCreate  boolean;
    aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type;
  begin
    aCanCreate  := true;

    select min(ANC.SQM_ANC_ID)
      into aSQM_ANC_ID
      from SQM_ANC ANC
         , SQM_ANC_POSITION POS
         , SQM_ANC_DIRECT_ACTION SDA
     where ANC.SQM_ANC_ID = POS.SQM_ANC_ID
       and POS.SQM_ANC_POSITION_ID = SDA.SQM_ANC_POSITION_ID(+)
       and (    (   aSQM_ANC_POSITION_ID is null
                 or POS.SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID)
            or (   aSQM_ANC_CORRECTION_ID is null
                or SDA.SQM_ANC_DIRECT_ACTION_ID = aSQM_ANC_CORRECTION_ID)
           );

    -- Vérification de l'information prédominante à la création de la NC : Son Type
    if    aSQM_ANC_POSITION_ID is not null
       or aSQM_ANC_CORRECTION_ID is not null then
      -- RAZ des Variables globales.
      SQM_ANC_POSITION_INITIALIZE.ResetNCLinkRecord(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec);
      -- Utilisation des paramètres d'appel de la fonction.
      FormatNCLinkWithGenParams(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec
                              , aSQM_ANC_POSITION_ID
                              , aSQM_ANC_CORRECTION_ID
                              , aSTM_ELEMENT_NUMBER1_ID
                              , aSTM_ELEMENT_NUMBER2_ID
                              , aDOC_DOCUMENT_ID
                              , aDOC_POSITION_DETAIL_ID
                              , aFAL_LOT_ID
                              , aFAL_SCHEDULE_STEP2_ID
                              , aFAL_LOT_DETAIL_ID
                              , aA_IDCRE
                               );
      -- Champs calculés:
      CalculateNCLinkFields(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec);
      -- Vérification des règles d'intégrité de la NC.
      CheckNCLinkIntegrity(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec, aCanCreate);

      -- Création de la position de NC.
      if aCanCreate then
        Insert_NCLink(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec);
      end if;

      return SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec.SQM_ANC_LINK_ID;
    -- Position ou correction du lien
    else
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
                            ('Erreur à la création d''un lien. La position ou la correction du lien doit être précisée!')
       , aSQM_ANC_ID
       , 1
        );
      return null;
    end if;
  exception
    when others then
      begin
        SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur à la création d''un lien.') ||
                                        ' ' ||
                                        sqlcode ||
                                        ' ' ||
                                        sqlerrm
                                      , aSQM_ANC_ID
                                      , 1
                                       );
        return null;
      end;
  end GenerateNCLinks;

  /**
  * Procedure   : UpdateCorrectionStatus
  *
  * Description : Procédure de bouclement d'une correction
  */
  procedure CloseCorrection(
    aSQM_ANC_DIRECT_ACTION_ID SQM_ANC_DIRECT_ACTION.SQM_ANC_DIRECT_ACTION_ID%type
  , aSDA_END_DATE             SQM_ANC_DIRECT_ACTION.SDA_END_DATE%type   -- Date fin
  , aPC_SDA_USER2_ID          SQM_ANC_DIRECT_ACTION.PC_SDA_USER2_ID%type   -- USer bouclement
  , aSDA_COST                 SQM_ANC_DIRECT_ACTION.SDA_COST%type default null
  , aUseExternalProc          boolean default true
  )
  is
    aResultat   SQM_ANC_FUNCTIONS.MaxVarchar2;
    aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type;
  begin
    -- Update éventuel du coût de la correction
    if aSDA_COST is not null then
      update SQM_ANC_DIRECT_ACTION
         set SDA_COST = aSDA_COST
       where SQM_ANC_DIRECT_ACTION_ID = aSQM_ANC_DIRECT_ACTION_ID;
    end if;

    -- Bouclement de la correction
    SQM_ANC_FUNCTIONS.DirectActionClosing(aSQM_ANC_DIRECT_ACTION_ID
                                        , aResultat
                                        , aUseExternalProc
                                        , aPC_SDA_USER2_ID
                                        , aSDA_END_DATE
                                         );

    -- Récupération de la NC Correspondante
    select POS.SQM_ANC_ID
      into aSQM_ANC_ID
      from SQM_ANC_DIRECT_ACTION SDA
         , SQM_ANC_POSITION POS
     where SDA.SQM_ANC_DIRECT_ACTION_ID = aSQM_ANC_DIRECT_ACTION_ID
       and SDA.SQM_ANC_POSITION_ID = POS.SQM_ANC_POSITION_ID;

    -- Finalisation
    if aResultat <> '' then
      SQM_ANC_GENERATE.AddErrorReport(aResultat, aSQM_ANC_ID, 1);
    else
      FinalizeNC(aSQM_ANC_ID);
    end if;
  exception
    when others then
      SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur au bouclement d''une correction.') ||
                                      ' ' ||
                                      sqlcode ||
                                      ' ' ||
                                      sqlerrm
                                    , aSQM_ANC_ID
                                    , 1
                                     );
  end CloseCorrection;

  /**
  * Procedure   : CloseAction
  *
  * Description : Procédure de bouclement d'une action
  *
  */
  procedure CloseAction(
    aSQM_ANC_PREVENTIVE_ACTION_ID SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_PREVENTIVE_ACTION_ID%type
  , aSPA_END_DATE                 SQM_ANC_PREVENTIVE_ACTION.SPA_END_DATE%type   -- Date fin
  , aPC_SPA_USER2_ID              SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER2_ID%type   -- User bouclement
  , aSPA_COST                     SQM_ANC_PREVENTIVE_ACTION.SPA_COST%type default null
  , aUseExternalProc              boolean default true
  )
  is
    aResultat   SQM_ANC_FUNCTIONS.MaxVarchar2;
    aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type;
  begin
    -- Update éventuel du coût de l'Action
    if aSPA_COST is not null then
      update SQM_ANC_PREVENTIVE_ACTION
         set SPA_COST = aSPA_COST
       where SQM_ANC_PREVENTIVE_ACTION_ID = aSQM_ANC_PREVENTIVE_ACTION_ID;
    end if;

    -- Bouclement de la correction
    SQM_ANC_FUNCTIONS.PreventiveActionClosing(aSQM_ANC_PREVENTIVE_ACTION_ID
                                            , aResultat
                                            , aUseExternalProc
                                            , aPC_SPA_USER2_ID
                                            , aSPA_END_DATE
                                             );

    -- Récupération de la NC Correspondante
    select POS.SQM_ANC_ID
      into aSQM_ANC_ID
      from SQM_ANC_PREVENTIVE_ACTION SPA
         , SQM_ANC_POSITION POS
     where SPA.SQM_ANC_PREVENTIVE_ACTION_ID = aSQM_ANC_PREVENTIVE_ACTION_ID
       and SPA.SQM_ANC_POSITION_ID = POS.SQM_ANC_POSITION_ID;

    -- Finalisation
    if aResultat <> '' then
      SQM_ANC_GENERATE.AddErrorReport(aResultat, aSQM_ANC_ID, 1);
    else
      FinalizeNC(aSQM_ANC_ID);
    end if;
  exception
    when others then
      SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur au bouclement d''une action.') ||
                                      ' ' ||
                                      sqlcode ||
                                      ' ' ||
                                      sqlerrm
                                    , aSQM_ANC_ID
                                    , 1
                                     );
  end CloseAction;

  /**
  * Procedure   : UpdatePositionStatus
  *
  * Description : Procédure de changement de status d'une position (Ne permet pas de passer à un status inférieur.
  *
  * aSQM_ANC_POSITION_ID     : ID Position
  * aC_ANC_POS_STATUS        : Nouveau status de la position
  * aPC_SAP_USER1_ID     : User Validation
  * aPC_SAP_USER2_ID     : User Bouclement
  * aSAP_VALIDATION_DATE   : date validation
  * aSAP_CLOSING_DATE    : Date bouclement
  * aUseExternalProc         : Utilisation/ déclenchement des éventuelles procédures indiv. au bouclement..
  *
  */
  procedure UpdatePositionStatus(
    aSQM_ANC_POSITION_ID SQM_ANC_POSITION.SQM_ANC_POSITION_ID%type
  , aC_ANC_POS_STATUS    SQM_ANC_POSITION.C_ANC_POS_STATUS%type
  , aPC_SAP_USER1_ID     SQM_ANC_POSITION.PC_SAP_USER1_ID%type   -- User validation.
  , aPC_SAP_USER2_ID     SQM_ANC_POSITION.PC_SAP_USER2_ID%type   -- User bouclement.
  , aSAP_VALIDATION_DATE SQM_ANC_POSITION.SAP_VALIDATION_DATE%type   -- Date validation.
  , aSAP_CLOSING_DATE    SQM_ANC_POSITION.SAP_CLOSING_DATE%type   -- Date bouclement.
  , aUseExternalProc     boolean
  )
  is
    aOldStatus  SQM_ANC_POSITION.C_ANC_POS_STATUS%type;
    aSQM_ANC_ID SQM_ANC_POSITION.SQM_ANC_ID%type;
    aResultat   SQM_ANC_FUNCTIONS.MaxVarchar2;
  begin
    -- Récupération de l'ancien status de la position
    select C_ANC_POS_STATUS
         , SQM_ANC_ID
      into aOldStatus
         , aSQM_ANC_ID
      from SQM_ANC_POSITION
     where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

    -- On ne permet la modification du status que si le status demandé est > à Oldstatus

    -- Position refusée
    if aOldStatus = '2' then
      SQM_ANC_GENERATE.AddErrorReport
                 (PCS.PC_FUNCTIONS.TranslateWord('La position est déjà refusée, son statut ne peut plus être changé!')
                , aSQM_ANC_ID
                , 1
                 );
    -- Position bouclée
    elsif aOldStatus = '4' then
      SQM_ANC_GENERATE.AddErrorReport
                 (PCS.PC_FUNCTIONS.TranslateWord('La position est déjà bouclée, son statut ne peut plus être changé!')
                , aSQM_ANC_ID
                , 1
                 );
    -- Position à valider
    elsif aOldStatus = '1' then
      -- Doit être refusée
      if aC_ANC_POS_STATUS = '2' then
        SQM_ANC_FUNCTIONS.ANCPosRejection(aSQM_ANC_POSITION_ID
                                        , aResultat
                                        , aUseExternalProc
                                        , aPC_SAP_USER1_ID
                                        , aSAP_VALIDATION_DATE
                                         );

        if aResultat is not null then
          SQM_ANC_GENERATE.AddErrorReport(aResultat, aSQM_ANC_ID, 1);
        end if;
      end if;

      -- Doit être "Validée"
      if    aC_ANC_POS_STATUS = '3'
         or aC_ANC_POS_STATUS = '4' then
        SQM_ANC_FUNCTIONS.ANCPosValidation(aSQM_ANC_POSITION_ID
                                         , aResultat
                                         , aUseExternalProc
                                         , aPC_SAP_USER1_ID
                                         , aSAP_VALIDATION_DATE
                                          );

        if aResultat is not null then
          SQM_ANC_GENERATE.AddErrorReport(aResultat, aSQM_ANC_ID, 1);
        end if;
      end if;

      -- Doit ëtre "bouclée"
      if aC_ANC_POS_STATUS = '4' then
        SQM_ANC_FUNCTIONS.ANCPosClosing(aSQM_ANC_POSITION_ID
                                      , aResultat
                                      , aUseExternalProc
                                      , aPC_SAP_USER2_ID
                                      , aSAP_CLOSING_DATE
                                       );

        if aResultat is not null then
          SQM_ANC_GENERATE.AddErrorReport(aResultat, aSQM_ANC_ID, 1);
        end if;
      end if;
    -- Position "Validée"
    elsif aOldStatus = '3' then
      -- Doit être bouclée
      if aC_ANC_POS_STATUS <> '4' then
        SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord('La position est déjà validée, son prochain statut est forcément "bouclée"!')
         , aSQM_ANC_ID
         , 1
          );
      -- Bouclement de la position
      else
        SQM_ANC_FUNCTIONS.ANCPosClosing(aSQM_ANC_POSITION_ID
                                      , aResultat
                                      , aUseExternalProc
                                      , aPC_SAP_USER2_ID
                                      , aSAP_CLOSING_DATE
                                       );

        if aResultat is not null then
          SQM_ANC_GENERATE.AddErrorReport(aResultat, aSQM_ANC_ID, 1);
        end if;
      end if;
    end if;

    -- Finalisation de la position
    FinalizeNC(aSQM_ANC_ID);
  exception
    when others then
      SQM_ANC_GENERATE.AddErrorReport
                                  (PCS.PC_FUNCTIONS.TranslateWord('Erreur au changement de statut d''une position.') ||
                                   ' ' ||
                                   sqlcode ||
                                   ' ' ||
                                   sqlerrm
                                 , aSQM_ANC_ID
                                 , 1
                                  );
  end UpdatePositionStatus;
end SQM_ANC_POSITION_GENERATE;
