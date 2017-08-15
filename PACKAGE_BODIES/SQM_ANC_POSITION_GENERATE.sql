--------------------------------------------------------
--  DDL for Package Body SQM_ANC_POSITION_GENERATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_ANC_POSITION_GENERATE" 
is
  /*
  * Procedure FinalizeNC
  *
  * Description : Procedure de finalisation d'une NC, r�alise les point suivants :
  *         1) Protection de l'ANC correspondante.
  *         2) Pour chaque Correction et action recalcul des dur�es.
  *         4) Recalcul des dur�es de la position
  *         3) Recalcul des co�ts de la position + report des co�ts au niveau de l'ANC. (calcul tenant compte d'une evntuelle indiv du calcul).
  *           6) D�protection de l'ANC.
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
          -- Recalcul des dur�es.
          SQM_ANC_FUNCTIONS.GetExactDuration(CurNcCorrection.SDA_CREATION_DATE
                                           , CurNcCorrection.SDA_END_DATE
                                           , aResultat
                                           , aDuration
                                            );

          -- Modification de la dur�e
          if aDuration is not null then
            update SQM_ANC_DIRECT_ACTION
               set SDA_DURATION = aDuration
             where SQM_ANC_DIRECT_ACTION_ID = CurNcCorrection.SQM_ANC_DIRECT_ACTION_ID;
          end if;
        end loop;

        -- Pour chaque Action
        for CurNcAction in CUR_NC_ACTION(CurNcPosition.SQM_ANC_POSITION_ID) loop
          -- Recalcul des dur�es.
          SQM_ANC_FUNCTIONS.GetExactDuration(CurNcAction.SPA_CREATION_DATE
                                           , CurNcAction.SPA_END_DATE
                                           , aResultat
                                           , aDuration
                                            );

          -- Modification de la dur�e
          if aDuration is not null then
            update SQM_ANC_PREVENTIVE_ACTION
               set SPA_DURATION = aDuration
             where SQM_ANC_PREVENTIVE_ACTION_ID = CurNcAction.SQM_ANC_PREVENTIVE_ACTION_ID;
          end if;
        end loop;

        -- Traitement de la position : Recalcul des dur�es
          -- Calcul dur�e de validation
        SQM_ANC_FUNCTIONS.GetExactDuration(CurNcPosition.SAP_CREATION_DATE
                                         , CurNcPosition.SAP_VALIDATION_DATE
                                         , aResultat
                                         , aSAP_VALIDATION_DURATION
                                          );
        -- Calcul dur�e de traitement
        SQM_ANC_FUNCTIONS.GetExactDuration(CurNcPosition.SAP_VALIDATION_DATE
                                         , CurNcPosition.SAP_CLOSING_DATE
                                         , aResultat
                                         , aSAP_PROCESSING_DURATION
                                          );
        -- Calcul dur�e totale
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

        -- Traitement de la position : Recalcul des co�ts
        SQM_ANC_FUNCTIONS.CalcANCPositionCost(CurNcPosition.SQM_ANC_POSITION_ID);
      end loop;

      --  Recalcul des co�ts de la NC.
      SQM_ANC_FUNCTIONS.CalcANCCost(aSQM_ANC_ID);

      -- Recalcul des dur�es de la NC
        -- R�cup�ration date cr�ation et date validation de l'ANC
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

      -- R�cup�ration date R�clamation tiers de l'ANC et date impression
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

      -- Calcul dur�e de r�ponse ANC
      if blnUpdateANC_REPLY_DURATION then
        SQM_ANC_FUNCTIONS.GetExactDuration(aANC_PARTNER_DATE, aANC_PRINT_RECEPT_DATE, aResultat, aANC_REPLY_DURATION);
      end if;

      -- Calcul dur�e de validation ANC
      SQM_ANC_FUNCTIONS.GetExactDuration(aANC_DATE, aANC_VALIDATION_DATE, aResultat, aANC_VALIDATION_DURATION);
      -- Calcul dur�e d'affectation ANC
      SQM_ANC_FUNCTIONS.GetExactDuration(aANC_VALIDATION_DATE, aANC_ALLOCATION_DATE, aResultat
                                       , aANC_ALLOCATION_DURATION);
      -- Calcul dur�e de traitement ANC
      SQM_ANC_FUNCTIONS.GetExactDuration(aANC_ALLOCATION_DATE, aANC_CLOSING_DATE, aResultat, aANC_PROCESSING_DURATION);
      -- Calcul dur�e de totale ANC
      SQM_ANC_FUNCTIONS.GetExactDuration(aANC_DATE, aANC_CLOSING_DATE, aResultat, aANC_TOTAL_DURATION);

      update SQM_ANC
         set ANC_REPLY_DURATION = aANC_REPLY_DURATION
           , ANC_VALIDATION_DURATION = aANC_VALIDATION_DURATION
           , ANC_ALLOCATION_DURATION = aANC_ALLOCATION_DURATION
           , ANC_PROCESSING_DURATION = aANC_PROCESSING_DURATION
           , ANC_TOTAL_DURATION = aANC_TOTAL_DURATION
       where SQM_ANC_ID = aSQM_ANC_ID;

      -- D�protection de la NC.
      SQM_ANC_FUNCTIONS.NCProtection(aSQM_ANC_ID, 0);
    end if;
  end FinalizeNC;

  /* Proc�dure   : CheckNCPositionIntegrity
  *  Description : V�rification des r�gles d'int�grit� de base d'une position d'ANC, et de r�gles
  *          "Obligatoires"
  *
  *  aSQM_ANC_POSITION_Rec : Record contenant les infos � ins�rer dans la base
  *  aUseBasicRules        : V�rification des r�gles obligatoires ou non!
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

      -- Si status de l'ANC  diff�rent de "a valider"," Valid�e", "Affect�e".
      if aC_ANC_STATUS not in('1', '3', '4') then
        SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord
                      ('Le statut de la NC ne permet pas la cr�ation de nouvelle position! Celle-ci ne peut �tre cr��e.')
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
                             ('Probl�mes rencontr�s avec le statut de la position � cr�er! Celle-ci ne peut �tre cr��e.')
           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
           , 1
            );
          aCanCreate  := false;
        end;
    end;

    -- ID Cr�ation .
    if aSQM_ANC_POSITION_Rec.A_IDCRE is null then
      select A_IDCRE
        into aSQM_ANC_POSITION_Rec.A_IDCRE
        from SQM_ANC
       where SQM_ANC_ID = aSQM_ANC_POSITION_Rec.SQM_ANC_ID;
    end if;

      /* V�rification des champs mandatory (avec renseignement automatique si possible */
    -- ID Position de NC.
    if aSQM_ANC_POSITION_Rec.SQM_ANC_POSITION_ID is null then
      select INIT_ID_SEQ.nextval
        into aSQM_ANC_POSITION_Rec.SQM_ANC_POSITION_ID
        from dual;
    end if;

    -- Num�ro de position de NC .
    if aSQM_ANC_POSITION_Rec.SAP_NUMBER is null then
      -- Num�ro de NC.
      SQM_ANC_FUNCTIONS.GetANCPositionNumber(aSQM_ANC_POSITION_Rec.SQM_ANC_ID, aSQM_ANC_POSITION_Rec.SAP_NUMBER);
    end if;

    -- Intitul� de position
    if aSQM_ANC_POSITION_Rec.SAP_TITLE is null then
      aSQM_ANC_POSITION_Rec.SAP_TITLE  :=
                                       PCS.PC_FUNCTIONS.TranslateWord('Position n�')
                                       || aSQM_ANC_POSITION_Rec.SAP_NUMBER;
    end if;

    -- Date Cr�ation
    if aSQM_ANC_POSITION_Rec.A_DATECRE is null then
      aSQM_ANC_POSITION_Rec.A_DATECRE  := sysdate;
    end if;

    -- Cr�ateur NC
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

    -- Produit et r�f�rence secondaire et r�f�rence tiers
    if aSQM_ANC_POSITION_Rec.GCO_GOOD_ID is not null then
      -- R�f�rence secondaire.
      if aSQM_ANC_POSITION_Rec.SAP_SECOND_REF is null then
        aSQM_ANC_POSITION_Rec.SAP_SECOND_REF  :=
                                                FAL_TOOLS.GetGOO_SECONDARY_REFERENCE(aSQM_ANC_POSITION_Rec.GCO_GOOD_ID);
      end if;

      -- R�f�rence tiers.
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

    /* V�rification des valeurs de dico entr�es */
    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAP_CTRL', aSQM_ANC_POSITION_Rec.DIC_SAP_CTRL_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
                             ' ( DIC_SAP_FREE5 = ' ||
                             aSQM_ANC_POSITION_Rec.DIC_SAP_FREE5_ID ||
                             ' )'
                           , aSQM_ANC_POSITION_Rec.SQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_POSITION_Rec.DIC_SAP_FREE5_ID  := null;
    end if;
  end CheckNCPositionIntegrity;

  /* Proc�dure   : CheckNCCorrectionIntegrity
  *  Description : Procedure de contr�le de l'int�grit� d'une correction
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
    -- Flag de cr�ation possible.
    aCanCreate                                 := true;

    -- R�cup de l'ANC de la Position de la Correction
    select SQM_ANC_ID
         , A_IDCRE
         , C_ANC_POS_STATUS
      into aSQM_ANC_ID
         , aANCID_CRE
         , aC_ANC_POS_STATUS
      from SQM_ANC_POSITION
     where SQM_ANC_POSITION_ID = aSQM_ANC_CORRECTION_Rec.SQM_ANC_POSITION_ID;

    -- ID Cr�ation
    if aSQM_ANC_CORRECTION_Rec.A_IDCRE is null then
      aSQM_ANC_CORRECTION_Rec.A_IDCRE  := aANCID_CRE;
    end if;

    -- ID de la correction
    if aSQM_ANC_CORRECTION_Rec.SQM_ANC_DIRECT_ACTION_ID is null then
      select INIT_ID_SEQ.nextval
        into aSQM_ANC_CORRECTION_Rec.SQM_ANC_DIRECT_ACTION_ID
        from dual;
    end if;

    -- Status de la correction. doit �tre coh�rent avec celui de la position
    if aC_ANC_POS_STATUS not in('1', '3') then
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
                    ('On ne peut ajouter une correction � une position en statut diff�rent de "A valider" ou "valid�e"!')
       , aSQM_ANC_ID
       , 1
        );
      aCanCreate  := false;
    end if;

    -- Type de correction
    if aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
           (PCS.PC_FUNCTIONS.TranslateWord('Le type de la correction doit �tre pr�cis�. Celle-ci ne peut �tre cr��e!')
          , aSQM_ANC_ID
          , 1
           );
      aCanCreate  := false;
    end if;

    -- D�lai
    if aSQM_ANC_CORRECTION_Rec.SDA_DELAY is null then
      aSQM_ANC_CORRECTION_Rec.SDA_DELAY  := aSQM_ANC_CORRECTION_Rec.A_DATECRE;
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
           ('Le d�lai de la correction n''�tant pas pr�cis�, celui-ci � �t� mis � la date de cr�ation de la correction!')
       , aSQM_ANC_ID
       , 1
        );
    end if;

    -- Position
    if aSQM_ANC_CORRECTION_Rec.SQM_ANC_POSITION_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord('La position de la correction doit �tre pr�cis�e. Celle-ci ne peut �tre cr��e!')
       , aSQM_ANC_ID
       , 1
        );
      aCanCreate  := false;
    end if;

    -- Date cr�ation.
    aSQM_ANC_CORRECTION_Rec.SDA_CREATION_DATE  := nvl(aSQM_ANC_CORRECTION_Rec.SDA_CREATION_DATE, sysdate);

    -- User cr�ation
    if aSQM_ANC_CORRECTION_Rec.PC_SDA_USER3_ID is null then
      SQM_ANC_INITIALIZE.GetUserInfo(aSQM_ANC_CORRECTION_Rec.A_IDCRE, aSQM_ANC_CORRECTION_Rec.PC_SDA_USER3_ID);
    end if;

    /* V�rification des valeurs de dictionnaire entr�es */
    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SDA_TYPE', aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
                             ' ( DIC_SDA_FREE5_ID = ' ||
                             aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE5_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CORRECTION_Rec.DIC_SDA_FREE5_ID  := null;
    end if;
  end CheckNCCorrectionIntegrity;

   /* Proc�dure   : CheckNCCorrectionIntegrity
  *  Description : Procedure de contr�le de l'int�grit� d'une correction
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
    -- Indique si la cr�ation est possible
    aCanCreate                    := true;

    -- R�cup de l'ANC de la Position de la Correction
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
                  (PCS.PC_FUNCTIONS.TranslateWord('Le type de cause doit �tre pr�cis�e. Celle-ci ne peut �tre cr��e!')
                 , aSQM_ANC_ID
                 , 1
                  );
      aCanCreate  := false;
    end if;

    -- Position
    if aSQM_ANC_CAUSE_Rec.SQM_ANC_POSITION_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
           (PCS.PC_FUNCTIONS.TranslateWord('La position de la cause doit �tre pr�cis�e. Celle-ci ne peut �tre cr��e!')
          , aSQM_ANC_ID
          , 1
           );
      aCanCreate  := false;
    end if;

    -- le statut dela position permet-il de cr�er une cause?
    if aC_ANC_POS_STATUS not in('1', '3') then
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
           ('On ne peut ajouter une cause qu''� une position en statut "A valider" ou "Valid�e". Celle-ci ne peut �tre cr��e!'
           )
       , aSQM_ANC_ID
       , 1
        );
      aCanCreate  := false;
    end if;

    -- Date cr�ation
    aSQM_ANC_CAUSE_Rec.A_DATECRE  := nvl(aSQM_ANC_CAUSE_Rec.A_DATECRE, sysdate);

    -- ID cr�ation
    if aSQM_ANC_CAUSE_Rec.A_IDCRE is null then
      aSQM_ANC_CAUSE_Rec.A_IDCRE  := aANCID_CRE;
    end if;

    /* V�rification des dictionnaires */
    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SAC_TYPE', aSQM_ANC_CAUSE_Rec.DIC_SAC_TYPE_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
                             ' ( DIC_SAC_FREE5_ID = ' ||
                             aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE5_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_CAUSE_Rec.DIC_SAC_FREE5_ID  := null;
    end if;
  end CheckNCCauseIntegrity;

  /* Proc�dure   : CheckNCActionIntegrity
  *  Description : Procedure de contr�le de l'int�grit� d'une action
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
    -- Flag de cr�ation possible.
    aCanCreate                             := true;

    -- R�cup de l'ANC de la Position de la Correction
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
           ('On ne peut ajouter une action qu''� une position en statut "A valider" ou "Valid�e". Celle-ci ne peut �tre cr��e!'
           )
       , aSQM_ANC_ID
       , 1
        );
      aCanCreate  := false;
    end if;

    -- ID Cr�ation
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
               (PCS.PC_FUNCTIONS.TranslateWord('Le type de l''action doit �tre pr�cis�. Celle-ci ne peut �tre cr��e!')
              , aSQM_ANC_ID
              , 1
               );
      aCanCreate  := false;
    end if;

    -- D�lai
    if aSQM_ANC_ACTION_Rec.SPA_DELAY is null then
      aSQM_ANC_ACTION_Rec.SPA_DELAY  := aSQM_ANC_ACTION_Rec.A_DATECRE;
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
               ('Le d�lai de l''action n''�tant pas pr�cis�, celui-ci � �t� mis � la date de cr�ation de la correction!')
       , aSQM_ANC_ID
       , 1
        );
    end if;

    -- Position
    if aSQM_ANC_ACTION_Rec.SQM_ANC_POSITION_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord('La position de l''action doit �tre pr�cis�e. Celle-ci ne peut �tre cr��e!')
         , aSQM_ANC_ID
         , 1
          );
      aCanCreate  := false;
    end if;

    -- Cause
    if aSQM_ANC_ACTION_Rec.SQM_ANC_CAUSE_ID is null then
      SQM_ANC_GENERATE.AddErrorReport
             (PCS.PC_FUNCTIONS.TranslateWord('La cause de l''action doit �tre pr�cis�e. Celle-ci ne peut �tre cr��e!')
            , aSQM_ANC_ID
            , 1
             );
      aCanCreate  := false;
    end if;

    -- Date cr�ation.
    aSQM_ANC_ACTION_Rec.SPA_CREATION_DATE  := nvl(aSQM_ANC_ACTION_Rec.SPA_CREATION_DATE, sysdate);

    -- User cr�ation
    if aSQM_ANC_ACTION_Rec.PC_SPA_USER3_ID is null then
      SQM_ANC_INITIALIZE.GetUserInfo(aSQM_ANC_ACTION_Rec.A_IDCRE, aSQM_ANC_ACTION_Rec.PC_SPA_USER3_ID);
    end if;

    /* V�rification des valeurs de dictionnaire entr�es */
    if not SQM_ANC_GENERATE.IsGoodDicoValue('DIC_SPA_TYPE', aSQM_ANC_ACTION_Rec.DIC_SPA_TYPE_ID) then
      SQM_ANC_GENERATE.AddErrorReport
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
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
                            (PCS.PC_FUNCTIONS.TranslateWord('Le valeur de dictionnaire entr�e n''est pas correcte!') ||
                             ' ( DIC_SPA_FREE5_ID = ' ||
                             aSQM_ANC_ACTION_Rec.DIC_SPA_FREE5_ID ||
                             ' )'
                           , aSQM_ANC_ID
                           , 1
                            );
      aSQM_ANC_ACTION_Rec.DIC_SPA_FREE5_ID  := null;
    end if;
  end CheckNCActionIntegrity;

  /* Proc�dure   : CheckNCLinkIntegrity
  *  Description : Procedure de contr�le de l'int�grit� d'un Lien
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
    /* V�rification des champs obligatoires � la cr�ation du lien */

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
                   ('Le lien doit �tre li� soit � une position, soit � une correction de NC. Ce lien ne peut �tre cr��!')
         , aSQM_ANC_LINK_Rec.SQM_ANC_ID
         , 1
          );
        aCanCreate  := false;
      end if;

      -- Date cr�ation
      aSQM_ANC_LINK_Rec.A_DATECRE  := nvl(aSQM_ANC_LINK_Rec.A_DATECRE, sysdate);
      -- ID Cr�ation
      aSQM_ANC_LINK_Rec.A_IDCRE    := nvl(aSQM_ANC_LINK_Rec.A_IDCRE, aANC_IDCRE);
    end if;

    /* V�rification des r�gles d'int�grit� de base du lien � cr�er */
    if aCanCreate then
      -- Si il s'agit d'un lien sur une correction, on a soit un Lot, soit un lot archiv�, soit un document (Et c'est tout!)
      if aSQM_ANC_LINK_Rec.SQM_ANC_DIRECT_ACTION_ID is not null then
        if aSQM_ANC_LINK_Rec.FAL_LOT_ID is not null then
          aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID  := null;
        elsif aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID is not null then
          aSQM_ANC_LINK_Rec.FAL_LOT_ID       := null;
        else
          SQM_ANC_GENERATE.AddErrorReport
            (PCS.PC_FUNCTIONS.TranslateWord
                     ('Un lien sur une correction porte soit sur un lot, soit sur un lot archiv�, soit sur un document!')
           , aSQM_ANC_LINK_Rec.SQM_ANC_ID
           , 1
            );
          aCanCreate  := false;
        end if;
      elsif aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID is not null then
        -- Si il s'agit d'un lien sur une Position, on a suivant le type de la NC
        -- Si NC Interne, on a
        if aC_ANC_TYPE = '1' then
          -- Soit un couple Lot et eventuellement Op� + D�tail lot
          if aSQM_ANC_LINK_Rec.FAL_LOT_ID is not null then
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID  := null;
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID  := null;
            aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID         := null;
            aSQM_ANC_LINK_Rec.DOC_POSITION_DETAIL_ID  := null;
          -- Soit un couple Document et eventuellement D�tail position de document
          elsif aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID is not null then
            aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID   := null;
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID  := null;
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID  := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_ID              := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID       := null;
          -- Soit une caractlot et/ou pi�ce
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
                                      ('Les caract�ristiques du lien ne sont pas valides. Celui-ci ne peut �tre ins�r�!')
             , aSQM_ANC_LINK_Rec.SQM_ANC_ID
             , 1
              );
            aCanCreate  := false;
          end if;
        -- Sinon si NC Client ou fournisseur.
        elsif    aC_ANC_TYPE = '2'
              or aC_ANC_TYPE = '3' then
          -- Soit un couple Document et eventuellement D�tail position de document
          if aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID is not null then
            aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID   := null;
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID  := null;
            aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID  := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_ID              := null;
            aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID       := null;
          -- Soit une caractlot et/ou pi�ce
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
                                        ('Les caract�ristiques du lien ne sont pas valides. Celui-ci ne peut �tre cr��!')
             , aSQM_ANC_LINK_Rec.SQM_ANC_ID
             , 1
              );
            aCanCreate  := false;
          end if;
        end if;
      end if;

      -- Enfin s'il s'agit d'un lien sur une position, on v�rifie bien qu'il correspond au produit de la position.
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
                     ('Les caract�ristiques du lien ne sont pas valides par rapport au bien de sa position. Celui-ci ne peut �tre cr��!'
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
                     ('Les caract�ristiques du lien ne sont pas valides par rapport au bien de sa position. Celui-ci ne peut �tre cr��!'
                     )
                 , aSQM_ANC_LINK_Rec.SQM_ANC_ID
                 , 1
                  );
                aCanCreate  := false;
              end;
          end;
        -- Soit une caractlot et/ou pi�ce
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
                     ('Les caract�ristiques du lien ne sont pas valides par rapport au bien de sa position. Celui-ci ne peut �tre cr��!'
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

  /* Proc�dure   : Insert_NCPosition
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

  /* Proc�dure   : Insert_NCCorrection.
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

  /* Proc�dure   : Insert_NCCause.
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

  /* Proc�dure   : Insert_NCAction
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

  /* Proc�dure   : Insert_NCPosition
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

  /* Proc�dure   : CalculateANCPositionFields
  *  Description : Procedure d'ajout au record des champs calcul�s
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

    -- Num�ro de NC.
    SQM_ANC_FUNCTIONS.GetANCPositionNumber(aSQM_ANC_POSITION_Rec.SQM_ANC_ID, aSQM_ANC_POSITION_Rec.SAP_NUMBER);

    -- R�f�rence secondaire bien
    if aSQM_ANC_POSITION_Rec.GCO_GOOD_ID is not null then
      aSQM_ANC_POSITION_Rec.SAP_SECOND_REF  := FAL_TOOLS.GetGOO_SECONDARY_REFERENCE(aSQM_ANC_POSITION_Rec.GCO_GOOD_ID);
    end if;
  -- Cr�ateur de  la NC
  end;

  /* Proc�dure   : CalculateNCCorrectionFields
  *  Description : Procedure d'ajout au record des champs calcul�s
  *
  */
  procedure CalculateNCCorrectionFields(
    aSQM_ANC_CORRECTION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CORRECTION_Rec
  )
  is
    aResultat SQM_ANC_FUNCTIONS.MaxVarchar2;
  begin
    -- Statut correction (Plannifi�e en cr�ation).
    aSQM_ANC_CORRECTION_Rec.C_SDA_STATUS  := '1';

    -- ID Correction
    select INIT_ID_SEQ.nextval
      into aSQM_ANC_CORRECTION_Rec.SQM_ANC_DIRECT_ACTION_ID
      from dual;

    -- Date cr�ation
    aSQM_ANC_CORRECTION_Rec.A_DATECRE     := sysdate;
  end CalculateNCCorrectionFields;

  /* Proc�dure   : CalculateNCCauseFields
  *  Description : Procedure d'ajout au record des champs calcul�s
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

    -- Date cr�ation
    aSQM_ANC_CAUSE_Rec.A_DATECRE  := sysdate;
  end CalculateNCCauseFields;

  /* Proc�dure   : CalculateNCActionFields
  *  Description : Procedure d'ajout au record des champs calcul�s
  *
  */
  procedure CalculateNCActionFields(aSQM_ANC_ACTION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_ACTION_Rec)
  is
    aResultat SQM_ANC_FUNCTIONS.MaxVarchar2;
  begin
    -- Statut "a valider" en cr�ation
    aSQM_ANC_ACTION_Rec.C_SPA_STATUS  := '1';

    -- ID Action
    select INIT_ID_SEQ.nextval
      into aSQM_ANC_ACTION_Rec.SQM_ANC_PREVENTIVE_ACTION_ID
      from dual;

    -- Date cr�ation
    aSQM_ANC_ACTION_Rec.A_DATECRE     := sysdate;
  end CalculateNCActionFields;

  /* Proc�dure   : CalculateNCLinkFields
  *  Description : Procedure d'ajout au record des champs calcul�s
  *
  */
  procedure CalculateNCLinkFields(aSQM_ANC_LINK_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_LINK_Rec)
  is
  begin
    -- ID Action
    select INIT_ID_SEQ.nextval
      into aSQM_ANC_LINK_Rec.SQM_ANC_LINK_ID
      from dual;

    -- Date cr�ation
    aSQM_ANC_LINK_Rec.A_DATECRE  := sysdate;
  end CalculateNCLinkFields;

  /**
  * Procedure    : FormatANCPosWithGenParams
  * Description  : Formatage du record m�moire de stockage de la position de NC avec les param�tres d'appel de la fonction
  *                de g�n�ration de celle-ci, si une initialisation pr�alable n'a pas d�j� �t� effectu�e.
  */
  procedure FormatANCPosWithGenParams(
    aSQM_ANC_POSITION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_POSITION_Rec
  , aSQM_ANC_ID           in     SQM_ANC_POSITION.SQM_ANC_ID%type   -- NC.
  , aGCO_GOOD_ID          in     SQM_ANC_POSITION.GCO_GOOD_ID%type   -- Bien.
  , aDIC_SAP_CTRL_ID      in     SQM_ANC_POSITION.DIC_SAP_CTRL_ID%type   -- Etat du contr�le.
  , aDIC_SAP_CDEF_ID      in     SQM_ANC_POSITION.DIC_SAP_CDEF_ID%type   -- Cause du d�faut.
  , aDIC_SAP_NDEF_ID      in     SQM_ANC_POSITION.DIC_SAP_NDEF_ID%type   -- Nature du d�faut.
  , aDIC_SAP_DECISION_ID  in     SQM_ANC_POSITION.DIC_SAP_DECISION_ID%type   -- Decision prise.
  , aDIC_SAP_RESP_ID      in     SQM_ANC_POSITION.DIC_SAP_RESP_ID%type   -- Dept. responsable.
  , aDOC_DOCUMENT2_ID     in     SQM_ANC_POSITION.DOC_DOCUMENT2_ID%type   -- Document retour.
  , aSAP_PARTNER_REF      in     SQM_ANC_POSITION.SAP_PARTNER_REF%type   -- R�f�rence tier
  , aSAP_COMMENT          in     SQM_ANC_POSITION.SAP_COMMENT%type   -- Description defaut.
  , aSAP_QTY_ACCEPT       in     SQM_ANC_POSITION.SAP_QTY_ACCEPT%type   -- Qt� bonne.
  , aSAP_QTY_DEFECTIVE    in     SQM_ANC_POSITION.SAP_QTY_DEFECTIVE%type   -- Qt� deffectueuse.
  , aSAP_ACTUAL_VALUE     in     SQM_ANC_POSITION.SAP_ACTUAL_VALUE%type   -- Valeur actuelle.
  , aSAP_REQUIRE_VALUE    in     SQM_ANC_POSITION.SAP_REQUIRE_VALUE%type   -- Valeur attendue.
  , aSAP_TITLE            in     SQM_ANC_POSITION.SAP_TITLE%type   -- Intitul� position.
  , aA_IDCRE              in     SQM_ANC_POSITION.A_IDCRE%type   -- User Cr�ation.
  , aSAP_CREATION_DATE    in     SQM_ANC_POSITION.SAP_CREATION_DATE%type
  )   -- date Creation Position.
  is
  begin
    -- ANC .
    aSQM_ANC_POSITION_Rec.SQM_ANC_ID           := nvl(aSQM_ANC_POSITION_Rec.SQM_ANC_ID, aSQM_ANC_ID);
    -- Bien
    aSQM_ANC_POSITION_Rec.GCO_GOOD_ID          := nvl(aSQM_ANC_POSITION_Rec.GCO_GOOD_ID, aGCO_GOOD_ID);
    -- Etat du contr�le
    aSQM_ANC_POSITION_Rec.DIC_SAP_CTRL_ID      := nvl(aSQM_ANC_POSITION_Rec.DIC_SAP_CTRL_ID, aDIC_SAP_CTRL_ID);
    -- Cause du d�faut
    aSQM_ANC_POSITION_Rec.DIC_SAP_CDEF_ID      := nvl(aSQM_ANC_POSITION_Rec.DIC_SAP_CDEF_ID, aDIC_SAP_CDEF_ID);
    -- Nature du d�faut
    aSQM_ANC_POSITION_Rec.DIC_SAP_NDEF_ID      := nvl(aSQM_ANC_POSITION_Rec.DIC_SAP_NDEF_ID, aDIC_SAP_NDEF_ID);
    -- D�cision prise
    aSQM_ANC_POSITION_Rec.DIC_SAP_DECISION_ID  := nvl(aSQM_ANC_POSITION_Rec.DIC_SAP_DECISION_ID, aDIC_SAP_DECISION_ID);
    -- Dept. responsable
    aSQM_ANC_POSITION_Rec.DIC_SAP_RESP_ID      := nvl(aSQM_ANC_POSITION_Rec.DIC_SAP_RESP_ID, aDIC_SAP_RESP_ID);
    -- Document retour
    aSQM_ANC_POSITION_Rec.DOC_DOCUMENT2_ID     := nvl(aSQM_ANC_POSITION_Rec.DOC_DOCUMENT2_ID, aDOC_DOCUMENT2_ID);
    -- R�f�rence tiers
    aSQM_ANC_POSITION_Rec.SAP_PARTNER_REF      :=
                                           nvl(aSQM_ANC_POSITION_Rec.SAP_PARTNER_REF, substr(aSAP_PARTNER_REF, 0, 30) );
    --  Descr.d�faut
    aSQM_ANC_POSITION_Rec.SAP_COMMENT          :=
                                                 nvl(aSQM_ANC_POSITION_Rec.SAP_COMMENT, substr(aSAP_COMMENT, 0, 4000) );
    -- Qt� bonne
    aSQM_ANC_POSITION_Rec.SAP_QTY_ACCEPT       := nvl(aSQM_ANC_POSITION_Rec.SAP_QTY_ACCEPT, aSAP_QTY_ACCEPT);
    -- Qt� defectueuse
    aSQM_ANC_POSITION_Rec.SAP_QTY_DEFECTIVE    := nvl(aSQM_ANC_POSITION_Rec.SAP_QTY_DEFECTIVE, aSAP_QTY_DEFECTIVE);
    -- Qt� actuelle
    aSQM_ANC_POSITION_Rec.SAP_ACTUAL_VALUE     := nvl(aSQM_ANC_POSITION_Rec.SAP_ACTUAL_VALUE, aSAP_ACTUAL_VALUE);
    -- Valeur attendue
    aSQM_ANC_POSITION_Rec.SAP_REQUIRE_VALUE    := nvl(aSQM_ANC_POSITION_Rec.SAP_REQUIRE_VALUE, aSAP_REQUIRE_VALUE);
    -- Intitul�
    aSQM_ANC_POSITION_Rec.SAP_TITLE            := nvl(aSQM_ANC_POSITION_Rec.SAP_TITLE, substr(aSAP_TITLE, 0, 30) );
    -- Cr�ateur
    aSQM_ANC_POSITION_Rec.A_IDCRE              := nvl(aSQM_ANC_POSITION_Rec.A_IDCRE, aA_IDCRE);
    -- Date cr�ation
    aSQM_ANC_POSITION_Rec.SAP_CREATION_DATE    := nvl(aSQM_ANC_POSITION_Rec.SAP_CREATION_DATE, aSAP_CREATION_DATE);
  end FormatANCPosWithGenParams;

  /**
  * Procedure    : FormatANCPosWithGenParams
  * Description  : Formatage du record m�moire de stockage de la position de NC avec les param�tres d'appel de la fonction
  *                de g�n�ration de celle-ci, si une initialisation pr�alable n'a pas d�j� �t� effectu�e.
  */
  procedure FormatNCCorWithGenParams(
    aSQM_ANC_CORRECTION_Rec in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CORRECTION_Rec
  , aSQM_ANC_POSITION_ID    in     SQM_ANC_DIRECT_ACTION.SQM_ANC_POSITION_ID%type   -- Position
  , aPC_SDA_USER1_ID        in     SQM_ANC_DIRECT_ACTION.PC_SDA_USER1_ID%type   -- Responsable.
  , aDIC_DELAY_TYPE_ID      in     SQM_ANC_DIRECT_ACTION.DIC_DELAY_TYPE_ID%type   -- Code d�lai.
  , aSDA_COMMENT            in     SQM_ANC_DIRECT_ACTION.SDA_COMMENT%type   -- Description correction
  , aSDA_DELAY              in     SQM_ANC_DIRECT_ACTION.SDA_DELAY%type   -- D�lai.
  , aSDA_COST               in     SQM_ANC_DIRECT_ACTION.SDA_COST%type   -- Co�t
  , aA_IDCRE                in     SQM_ANC_DIRECT_ACTION.A_IDCRE%type   -- ID cr�ation
  , aPC_SDA_USER3_ID        in     SQM_ANC_DIRECT_ACTION.PC_SDA_USER3_ID%type   -- User cr�ation
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
    -- Code d�lai.
    aSQM_ANC_CORRECTION_Rec.DIC_DELAY_TYPE_ID    := nvl(aSQM_ANC_CORRECTION_Rec.DIC_DELAY_TYPE_ID, aDIC_DELAY_TYPE_ID);
    -- Description correction
    aSQM_ANC_CORRECTION_Rec.SDA_COMMENT          :=
                                                 nvl(aSQM_ANC_CORRECTION_Rec.SDA_COMMENT, substr(aSDA_COMMENT, 0, 50) );
    -- D�lai.
    aSQM_ANC_CORRECTION_Rec.SDA_DELAY            := nvl(aSQM_ANC_CORRECTION_Rec.SDA_DELAY, aSDA_DELAY);
    -- Co�t
    aSQM_ANC_CORRECTION_Rec.SDA_COST             := nvl(aSQM_ANC_CORRECTION_Rec.SDA_COST, aSDA_COST);
    -- ID cr�ation
    aSQM_ANC_CORRECTION_Rec.A_IDCRE              := nvl(aSQM_ANC_CORRECTION_Rec.A_IDCRE, aA_IDCRE);
    -- User cr�ation
    aSQM_ANC_CORRECTION_Rec.PC_SDA_USER3_ID      := nvl(aSQM_ANC_CORRECTION_Rec.PC_SDA_USER3_ID, aPC_SDA_USER3_ID);
    -- Date
    aSQM_ANC_CORRECTION_Rec.SDA_CREATION_DATE    := nvl(aSQM_ANC_CORRECTION_Rec.SDA_CREATION_DATE, aSDA_CREATION_DATE);
    -- Type de correction
    aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID      := nvl(aSQM_ANC_CORRECTION_Rec.DIC_SDA_TYPE_ID, aDIC_SDA_TYPE_ID);
  end FormatNCCorWithGenParams;

  /**
  * procedure   : FormatNCCorWithGenParams
  * Description : Formatage du record m�moire de stockage de la correction de la position de NC avec les param�tres d'appel de la fonction
  *               de g�n�ration de celle-ci, si une initialisation pr�alable n'a pas d�j� �t� effectu�e.
  */
  procedure FormatNCCauseWithGenParams(
    aSQM_ANC_CAUSE_Rec   in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_CAUSE_REC
  , aSQM_ANC_POSITION_ID in     SQM_ANC_CAUSE.SQM_ANC_POSITION_ID%type   -- Position
  , aDIC_SAC_TYPE_ID     in     SQM_ANC_CAUSE.DIC_SAC_TYPE_ID%type   -- Type de cause
  , aSAC_COMMENT         in     SQM_ANC_CAUSE.SAC_COMMENT%type   -- Commentaire
  , aA_IDCRE             in     SQM_ANC_CAUSE.A_IDCRE%type
  )   -- ID cr�ation
  is
  begin
    -- Position
    aSQM_ANC_CAUSE_Rec.SQM_ANC_POSITION_ID  := nvl(aSQM_ANC_CAUSE_Rec.SQM_ANC_POSITION_ID, aSQM_ANC_POSITION_ID);
    -- Type de cause
    aSQM_ANC_CAUSE_Rec.DIC_SAC_TYPE_ID      := nvl(aSQM_ANC_CAUSE_Rec.DIC_SAC_TYPE_ID, aDIC_SAC_TYPE_ID);
    -- Commentaire
    aSQM_ANC_CAUSE_Rec.SAC_COMMENT          := nvl(aSQM_ANC_CAUSE_Rec.SAC_COMMENT, substr(aSAC_COMMENT, 0, 4000) );
    -- ID cr�ation
    aSQM_ANC_CAUSE_Rec.A_IDCRE              := nvl(aSQM_ANC_CAUSE_Rec.A_IDCRE, aA_IDCRE);
  end FormatNCCauseWithGenParams;

  /**
  * Procedure    : FormatNCActionWithGenParams
  * Description  : Formatage du record m�moire de stockage d'une action de position de NC avec les param�tres d'appel de la fonction
  *                de g�n�ration de celle-ci, si une initialisation pr�alable n'a pas d�j� �t� effectu�e.
  */
  procedure FormatNCActionWithGenParams(
    aSQM_ANC_ACTION_REC  in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_ACTION_Rec
  , aSQM_ANC_POSITION_ID in     SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_POSITION_ID%type   -- Position
  , aSQM_ANC_CAUSE_ID    in     SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_CAUSE_ID%type   -- Cause
  , aPC_SPA_USER1_ID     in     SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER1_ID%type   -- Responsable
  , aDIC_DELAY_TYPE_ID   in     SQM_ANC_PREVENTIVE_ACTION.DIC_DELAY_TYPE_ID%type   -- Type de d�lai
  , aDIC_SPA_TYPE_ID     in     SQM_ANC_PREVENTIVE_ACTION.DIC_SPA_TYPE_ID%type   -- Type d'action
  , aSPA_COMMENT         in     SQM_ANC_PREVENTIVE_ACTION.SPA_COMMENT%type   -- Description action
  , aSPA_DELAY           in     SQM_ANC_PREVENTIVE_ACTION.SPA_DELAY%type   -- D�lai
  , aSPA_COST            in     SQM_ANC_PREVENTIVE_ACTION.SPA_COST%type   -- Co�t
  , aA_IDCRE             in     SQM_ANC_PREVENTIVE_ACTION.A_IDCRE%type   -- ID creation
  , aPC_SPA_USER3_ID     in     SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER3_ID%type   -- User cr�ation
  , aSPA_CREATION_DATE   in     SQM_ANC_PREVENTIVE_ACTION.SPA_CREATION_DATE%type
  )   -- Date cr�ation
  is
  begin
    -- Position
    aSQM_ANC_ACTION_REC.SQM_ANC_POSITION_ID  := nvl(aSQM_ANC_ACTION_REC.SQM_ANC_POSITION_ID, aSQM_ANC_POSITION_ID);
    -- Cause
    aSQM_ANC_ACTION_REC.SQM_ANC_CAUSE_ID     := nvl(aSQM_ANC_ACTION_REC.SQM_ANC_CAUSE_ID, aSQM_ANC_CAUSE_ID);
    -- Responsable
    aSQM_ANC_ACTION_REC.PC_SPA_USER1_ID      := nvl(aSQM_ANC_ACTION_REC.PC_SPA_USER1_ID, aPC_SPA_USER1_ID);
    -- Type de d�lai
    aSQM_ANC_ACTION_REC.DIC_DELAY_TYPE_ID    := nvl(aSQM_ANC_ACTION_REC.DIC_DELAY_TYPE_ID, aDIC_DELAY_TYPE_ID);
    -- Type d'action
    aSQM_ANC_ACTION_REC.DIC_SPA_TYPE_ID      := nvl(aSQM_ANC_ACTION_REC.DIC_SPA_TYPE_ID, aDIC_SPA_TYPE_ID);
    -- Description action
    aSQM_ANC_ACTION_REC.SPA_COMMENT          := nvl(aSQM_ANC_ACTION_REC.SPA_COMMENT, substr(aSPA_COMMENT, 0, 4000) );
    -- D�lai
    aSQM_ANC_ACTION_REC.SPA_DELAY            := nvl(aSQM_ANC_ACTION_REC.SPA_DELAY, aSPA_DELAY);
    -- Co�t
    aSQM_ANC_ACTION_REC.SPA_COST             := nvl(aSQM_ANC_ACTION_REC.SPA_COST, aSPA_COST);
    -- ID creation
    aSQM_ANC_ACTION_REC.A_IDCRE              := nvl(aSQM_ANC_ACTION_REC.A_IDCRE, aA_IDCRE);
    -- User cr�ation
    aSQM_ANC_ACTION_REC.PC_SPA_USER3_ID      := nvl(aSQM_ANC_ACTION_REC.PC_SPA_USER3_ID, aPC_SPA_USER3_ID);
    -- Date cr�ation
    aSQM_ANC_ACTION_REC.SPA_CREATION_DATE    := nvl(aSQM_ANC_ACTION_REC.SPA_CREATION_DATE, aSPA_CREATION_DATE);
  end FormatNCActionWithGenParams;

  /**
  * Procedure    : FormatNCActionWithGenParams
  * Description  : Formatage du record m�moire de stockage d'une action de position de NC avec les param�tres d'appel de la fonction
  *                de g�n�ration de celle-ci, si une initialisation pr�alable n'a pas d�j� �t� effectu�e.
  */
  procedure FormatNCLinkWithGenParams(
    aSQM_ANC_LINK_Rec       in out SQM_ANC_POSITION_INITIALIZE.TSQM_ANC_LINK_Rec
  , aSQM_ANC_POSITION_ID    in     SQM_ANC_LINK.SQM_ANC_POSITION_ID%type   -- Position de NC
  , aSQM_ANC_CORRECTION_ID  in     SQM_ANC_LINK.SQM_ANC_DIRECT_ACTION_ID%type   -- Correction
  , aSTM_ELEMENT_NUMBER1_ID in     SQM_ANC_LINK.STM_ELEMENT_NUMBER1_ID%type   -- Caract�risation 1 (Pi�ce).
  , aSTM_ELEMENT_NUMBER2_ID in     SQM_ANC_LINK.STM_ELEMENT_NUMBER2_ID%type   -- Caract�risation 2 (Lot).
  , aDOC_DOCUMENT_ID        in     SQM_ANC_LINK.DOC_DOCUMENT_ID%type   -- Document
  , aDOC_POSITION_DETAIL_ID in     SQM_ANC_LINK.DOC_POSITION_DETAIL_ID%type   -- D�tail position
  , aFAL_LOT_ID             in     SQM_ANC_LINK.FAL_LOT_ID%type   -- Lot.
  , aFAL_SCHEDULE_STEP2_ID  in     SQM_ANC_LINK.FAL_SCHEDULE_STEP2_ID%type   -- Op�ration
  , aFAL_LOT_DETAIL_ID      in     SQM_ANC_LINK.FAL_LOT_DETAIL_ID%type   -- D�tail lot
  , aA_IDCRE                in     SQM_ANC_LINK.A_IDCRE%type
  )   -- ID cr�ation
  is
  begin
    -- Position.
    aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID       := nvl(aSQM_ANC_LINK_Rec.SQM_ANC_POSITION_ID, aSQM_ANC_POSITION_ID);
    -- Correction
    aSQM_ANC_LINK_Rec.SQM_ANC_DIRECT_ACTION_ID  :=
                                                nvl(aSQM_ANC_LINK_Rec.SQM_ANC_DIRECT_ACTION_ID, aSQM_ANC_CORRECTION_ID);
    -- Caract�risation 1 (Piece)
    aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID    :=
                                                 nvl(aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER1_ID, aSTM_ELEMENT_NUMBER1_ID);
    -- Caract�risation 2 (Lot)
    aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID    :=
                                                 nvl(aSQM_ANC_LINK_Rec.STM_ELEMENT_NUMBER2_ID, aSTM_ELEMENT_NUMBER2_ID);
    -- Document
    aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID           := nvl(aSQM_ANC_LINK_Rec.DOC_DOCUMENT_ID, aDOC_DOCUMENT_ID);
    -- D�tail position de document
    aSQM_ANC_LINK_Rec.DOC_POSITION_DETAIL_ID    :=
                                                 nvl(aSQM_ANC_LINK_Rec.DOC_POSITION_DETAIL_ID, aDOC_POSITION_DETAIL_ID);
    -- Lot
    aSQM_ANC_LINK_Rec.FAL_LOT_ID                := nvl(aSQM_ANC_LINK_Rec.FAL_LOT_ID, aFAL_LOT_ID);
    -- Op�ration
    aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID     := nvl(aSQM_ANC_LINK_Rec.FAL_SCHEDULE_STEP2_ID, aFAL_SCHEDULE_STEP2_ID);
    -- D�tail Lot
    aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID         := nvl(aSQM_ANC_LINK_Rec.FAL_LOT_DETAIL_ID, aFAL_LOT_DETAIL_ID);
    -- Cr�ateur
    aSQM_ANC_LINK_Rec.A_IDCRE                   := nvl(aSQM_ANC_LINK_Rec.A_IDCRE, aA_IDCRE);
  end FormatNCLinkWithGenParams;

  /**
  * procdure GenerateANC .
  * Description :  procedure de g�n�ration hors interface d'une position de NC.
  *          La proc�dure d'initialisation individualis�e permet une initialisation autre que celle par d�faut
  *          Si une proc�dure d'initialisation indiv. est pr�cis�e alors les param�tres de cette fonction ne sont utilis�s
  *                que si cette proc�dure d'initialisation n'a pas d�j� initialis� les champs de la position de NC correspondante.
  */
  function GenerateNCPosition(
    aSQM_ANC_ID          in SQM_ANC_POSITION.SQM_ANC_ID%type   -- NC.
  , aGCO_GOOD_ID         in SQM_ANC_POSITION.GCO_GOOD_ID%type   -- Bien.
  , aDIC_SAP_CTRL_ID     in SQM_ANC_POSITION.DIC_SAP_CTRL_ID%type   -- Etat du contr�le.
  , aDIC_SAP_CDEF_ID     in SQM_ANC_POSITION.DIC_SAP_CDEF_ID%type   -- Cause du d�faut.
  , aDIC_SAP_NDEF_ID     in SQM_ANC_POSITION.DIC_SAP_NDEF_ID%type   -- Nature du d�faut.
  , aDIC_SAP_DECISION_ID in SQM_ANC_POSITION.DIC_SAP_DECISION_ID%type   -- Decision prise.
  , aDIC_SAP_RESP_ID     in SQM_ANC_POSITION.DIC_SAP_RESP_ID%type   -- Dept. responsable.
  , aDOC_DOCUMENT2_ID    in SQM_ANC_POSITION.DOC_DOCUMENT2_ID%type   -- Document retour.
  , aSAP_PARTNER_REF     in SQM_ANC_POSITION.SAP_PARTNER_REF%type   -- R�f�rence tier
  , aSAP_COMMENT         in SQM_ANC_POSITION.SAP_COMMENT%type   -- Description defaut.
  , aSAP_QTY_ACCEPT      in SQM_ANC_POSITION.SAP_QTY_ACCEPT%type   -- Qt� bonne.
  , aSAP_QTY_DEFECTIVE   in SQM_ANC_POSITION.SAP_QTY_DEFECTIVE%type   -- Qt� deffectueuse.
  , aSAP_ACTUAL_VALUE    in SQM_ANC_POSITION.SAP_ACTUAL_VALUE%type   -- Valeur actuelle.
  , aSAP_REQUIRE_VALUE   in SQM_ANC_POSITION.SAP_REQUIRE_VALUE%type   -- Valeur attendue.
  , aSAP_TITLE           in SQM_ANC_POSITION.SAP_TITLE%type   -- Intitul� position.
  , aA_IDCRE             in SQM_ANC_POSITION.A_IDCRE%type   -- User Cr�ation.
  , aSAP_CREATION_DATE   in SQM_ANC_POSITION.SAP_CREATION_DATE%type   -- date Creation Position.
  , aIndivInitProc       in varchar2 default null   -- Proc�dure d'initialisation individualis�e.
  , aStringParam1        in varchar2 default null   -- param�tres utilisable pour la procedure indiv d'initialisation
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
    -- Champs calcul�s
    aCanCreate boolean;
  begin
    -- V�rification de l'information pr�dominante � la cr�ation de la NC : Son Type
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

      -- Utilisation des param�tres d'appel de la fonction.
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
      -- Champs calcul�s:
      CalculateANCPositionFields(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_POSITION_Rec);
      -- V�rification des r�gles d'int�grit� de la NC.
      CheckNCPositionIntegrity(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_POSITION_Rec, aCanCreate);

      -- Cr�ation de la position de NC.
      if aCanCreate then
        Insert_NCPosition(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_POSITION_Rec);
      end if;

      -- Finalisation
      FinalizeNC(aSQM_ANC_ID);
      return SQM_ANC_POSITION_INITIALIZE.SQM_ANC_Position_Rec.SQM_ANC_POSITION_ID;
    -- ANC de la position non pr�cis�e
    else
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord('Erreur � la cr�ation de la position. La NC de la position doit �tre pr�cis�e!')
       , aSQM_ANC_ID
       , 1
        );
      return null;
    end if;
  exception
    when others then
      begin
        SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur � la cr�ation de la position') ||
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
  * Description :  Procedure de g�n�ration hors interface d'une Correction pour une position de NC
  *          La proc�dure d'initialisation individualis�e permet une initialisation autre que celle par d�faut
  *          Si une proc�dure d'initialisation indiv. est pr�cis�e alors les param�tres de cette fonction ne sont utilis�s
  *                que si cette proc�dure d'initialisation n'a pas d�j� initialis� les champs de la Correction de la position de NC correspondante.
  */
  function GenerateNCCorrection(
    aSQM_ANC_POSITION_ID    SQM_ANC_DIRECT_ACTION.SQM_ANC_POSITION_ID%type   -- Position NC.
  , aPC_SDA_USER1_ID        SQM_ANC_DIRECT_ACTION.PC_SDA_USER1_ID%type   -- Responsable.
  , aDIC_DELAY_TYPE_ID      SQM_ANC_DIRECT_ACTION.DIC_DELAY_TYPE_ID%type   -- Code d�lai.
  , aSDA_COMMENT            SQM_ANC_DIRECT_ACTION.SDA_COMMENT%type   -- Description correction
  , aSDA_DELAY              SQM_ANC_DIRECT_ACTION.SDA_DELAY%type   -- D�lai.
  , aSDA_COST               SQM_ANC_DIRECT_ACTION.SDA_COST%type   -- Co�t
  , aA_IDCRE                SQM_ANC_DIRECT_ACTION.A_IDCRE%type   -- ID cr�ation
  , aPC_SDA_USER3_ID        SQM_ANC_DIRECT_ACTION.PC_SDA_USER3_ID%type   -- User cr�ation
  , aSDA_CREATION_DATE      SQM_ANC_DIRECT_ACTION.SDA_CREATION_DATE%type   -- Date cr�ation
  , aDIC_SDA_TYPE_ID        SQM_ANC_DIRECT_ACTION.DIC_SDA_TYPE_ID%type   -- Type de correction
  , aIndivInitProc       in varchar2 default null   -- Proc�dure d'initialisation individualis�e.
  , aStringParam1        in varchar2 default null   -- param�tres utilisable pour la procedure indiv d'initialisation
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
    -- V�rification de l'information pr�dominante � la cr�ation de la NC : Son Type
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

      -- Utilisation des param�tres d'appel de la fonction.
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
      -- Champs calcul�s:
      CalculateNCCorrectionFields(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CORRECTION_Rec);
      -- V�rification des r�gles d'int�grit� de la NC.
      CheckNCCorrectionIntegrity(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CORRECTION_Rec, aCanCreate);

      -- Cr�ation de la position de NC.
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
    -- ANC de la position non pr�cis�e
    else
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
                        ('Erreur � la cr�ation de la correction. La position de NC de la correction doit �tre pr�cis�e!')
       , aSQM_ANC_ID
       , 1
        );
      return null;
    end if;
  exception
    when others then
      begin
        SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur � la cr�ation de la correction') ||
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
  * Description :  Procedure de g�n�ration hors interface d'une Cause pour une position de NC
  *          La proc�dure d'initialisation individualis�e permet une initialisation autre que celle par d�faut
  *          Si une proc�dure d'initialisation indiv. est pr�cis�e alors les param�tres de cette fonction ne sont utilis�s
  *                que si cette proc�dure d'initialisation n'a pas d�j� initialis� les champs de la Cause de la position de NC correspondante.
  */
  function GenerateNCCause(
    aSQM_ANC_POSITION_ID in SQM_ANC_CAUSE.SQM_ANC_POSITION_ID%type   -- ID de position
  , aDIC_SAC_TYPE_ID     in SQM_ANC_CAUSE.DIC_SAC_TYPE_ID%type   -- Type de cause
  , aSAC_COMMENT         in SQM_ANC_CAUSE.SAC_COMMENT%type   -- Commentaire
  , aA_IDCRE             in SQM_ANC_CAUSE.A_IDCRE%type   -- ID cr�ation
  , aIndivInitProc       in varchar2 default null   -- Proc�dure d'initialisation individualis�e.
  , aStringParam1        in varchar2 default null   -- param�tres utilisable pour la procedure indiv d'initialisation
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
    -- V�rification de l'information pr�dominante � la cr�ation de la cause : Position et IDCRE
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

        -- Utilisation des param�tres d'appel de la fonction.
        FormatNCCauseWithGenParams(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec
                                 , aSQM_ANC_POSITION_ID
                                 , aDIC_SAC_TYPE_ID
                                 , aSAC_COMMENT
                                 , aA_IDCRE
                                  );
        -- Champs calcul�s:
        CalculateNCCauseFields(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec);
        -- V�rification des r�gles d'int�grit� de la NC.
        CheckNCCauseIntegrity(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec, aCanCreate);

        -- Cr�ation de la cause de position de NC.
        if aCanCreate then
          Insert_NCCause(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec);
        end if;

        return SQM_ANC_POSITION_INITIALIZE.SQM_ANC_CAUSE_Rec.SQM_ANC_CAUSE_ID;
      -- Cr�ateur de la NC non indiqu�
      else
        SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord
                                   ('Erreur � la cr�ation de la cause. Le cr�ateur de la cause de NC doit �tre indiqu�!')
         , aSQM_ANC_ID
         , 1
          );
        return null;
      end if;
    -- ANC de la position non pr�cis�e
    else
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
                                  ('Erreur � la cr�ation de la cause. La position de NC de la cause doit �tre pr�cis�e!')
       , aSQM_ANC_ID
       , 1
        );
      return null;
    end if;
  exception
    when others then
      begin
        SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur � la cr�ation de la cause') ||
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
  * Description :  Procedure de g�n�ration hors interface d'une Action pour une position de NC .
  *          La proc�dure d'initialisation individualis�e permet une initialisation autre que celle par d�faut
  *          Si une proc�dure d'initialisation indiv. est pr�cis�e alors les param�tres de cette fonction ne sont utilis�s
  *                que si cette proc�dure d'initialisation n'a pas d�j� initialis� les champs de l'action de la position de NC correspondante.
  */
  function GenerateNCAction(
    aSQM_ANC_POSITION_ID in SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_POSITION_ID%type   -- Position
  , aSQM_ANC_CAUSE_ID    in SQM_ANC_PREVENTIVE_ACTION.SQM_ANC_CAUSE_ID%type   -- Cause
  , aPC_SPA_USER1_ID     in SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER1_ID%type   -- Responsable
  , aDIC_DELAY_TYPE_ID   in SQM_ANC_PREVENTIVE_ACTION.DIC_DELAY_TYPE_ID%type   -- Type de d�lai
  , aDIC_SPA_TYPE_ID     in SQM_ANC_PREVENTIVE_ACTION.DIC_SPA_TYPE_ID%type   -- Type d'action
  , aSPA_COMMENT         in SQM_ANC_PREVENTIVE_ACTION.SPA_COMMENT%type   -- Description action
  , aSPA_DELAY           in SQM_ANC_PREVENTIVE_ACTION.SPA_DELAY%type   -- D�lai
  , aSPA_COST            in SQM_ANC_PREVENTIVE_ACTION.SPA_COST%type   -- Co�t
  , aA_IDCRE             in SQM_ANC_PREVENTIVE_ACTION.A_IDCRE%type   -- ID creation
  , aPC_SPA_USER3_ID     in SQM_ANC_PREVENTIVE_ACTION.PC_SPA_USER3_ID%type   -- User cr�ation
  , aSPA_CREATION_DATE   in SQM_ANC_PREVENTIVE_ACTION.SPA_CREATION_DATE%type   -- Date cr�ation
  , aIndivInitProc       in varchar2 default null   -- Proc�dure d'initialisation individualis�e.
  , aStringParam1        in varchar2 default null   -- param�tres utilisable pour la procedure indiv d'initialisation
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
    -- V�rification de l'information pr�dominante � la cr�ation de la NC : Son Type
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

        -- Utilisation des param�tres d'appel de la fonction.
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
        -- Champs calcul�s:
        CalculateNCActionFields(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_ACTION_Rec);
        -- V�rification des r�gles d'int�grit� de la NC.
        CheckNCActionIntegrity(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_ACTION_Rec, aCanCreate);

        -- Cr�ation de la position de NC.
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
      -- Cause de l'action non pr�cis�e
      else
        SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord
                                         ('Erreur � la cr�ation de l''action. La cause de l''action doit �tre pr�cis�e!')
         , aSQM_ANC_ID
         , 1
          );
        return null;
      end if;
    -- Position de l'action non pr�cis�e
    else
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
                                ('Erreur � la cr�ation de l''action. La position de NC de l''action doit �tre pr�cis�e!')
       , aSQM_ANC_ID
       , 1
        );
      return null;
    end if;
  exception
    when others then
      begin
        SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur � la cr�ation de l''action') ||
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
  * Description :  Procedure de g�n�ration hors interface de liens pour une position de NC, une correction ou une action.
  */
  function GenerateNCLinks(
    aSQM_ANC_POSITION_ID    SQM_ANC_LINK.SQM_ANC_POSITION_ID%type   -- Position de NC
  , aSQM_ANC_CORRECTION_ID  SQM_ANC_LINK.SQM_ANC_DIRECT_ACTION_ID%type   -- Action
  , aSTM_ELEMENT_NUMBER1_ID SQM_ANC_LINK.STM_ELEMENT_NUMBER1_ID%type   -- Caract�risation 1 (Pi�ce).
  , aSTM_ELEMENT_NUMBER2_ID SQM_ANC_LINK.STM_ELEMENT_NUMBER2_ID%type   -- Caract�risation 2 (Lot).
  , aDOC_DOCUMENT_ID        SQM_ANC_LINK.DOC_DOCUMENT_ID%type   -- Document
  , aDOC_POSITION_DETAIL_ID SQM_ANC_LINK.DOC_POSITION_DETAIL_ID%type   -- D�tail position
  , aFAL_LOT_ID             SQM_ANC_LINK.FAL_LOT_ID%type   -- Lot.
  , aFAL_SCHEDULE_STEP2_ID  SQM_ANC_LINK.FAL_SCHEDULE_STEP2_ID%type   -- Op�ration
  , aFAL_LOT_DETAIL_ID      SQM_ANC_LINK.FAL_LOT_DETAIL_ID%type   -- D�tail lot
  , aA_IDCRE                SQM_ANC_LINK.A_IDCRE%type
  )   -- ID cr�ation
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

    -- V�rification de l'information pr�dominante � la cr�ation de la NC : Son Type
    if    aSQM_ANC_POSITION_ID is not null
       or aSQM_ANC_CORRECTION_ID is not null then
      -- RAZ des Variables globales.
      SQM_ANC_POSITION_INITIALIZE.ResetNCLinkRecord(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec);
      -- Utilisation des param�tres d'appel de la fonction.
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
      -- Champs calcul�s:
      CalculateNCLinkFields(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec);
      -- V�rification des r�gles d'int�grit� de la NC.
      CheckNCLinkIntegrity(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec, aCanCreate);

      -- Cr�ation de la position de NC.
      if aCanCreate then
        Insert_NCLink(SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec);
      end if;

      return SQM_ANC_POSITION_INITIALIZE.SQM_ANC_LINK_Rec.SQM_ANC_LINK_ID;
    -- Position ou correction du lien
    else
      SQM_ANC_GENERATE.AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord
                            ('Erreur � la cr�ation d''un lien. La position ou la correction du lien doit �tre pr�cis�e!')
       , aSQM_ANC_ID
       , 1
        );
      return null;
    end if;
  exception
    when others then
      begin
        SQM_ANC_GENERATE.AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur � la cr�ation d''un lien.') ||
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
  * Description : Proc�dure de bouclement d'une correction
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
    -- Update �ventuel du co�t de la correction
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

    -- R�cup�ration de la NC Correspondante
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
  * Description : Proc�dure de bouclement d'une action
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
    -- Update �ventuel du co�t de l'Action
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

    -- R�cup�ration de la NC Correspondante
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
  * Description : Proc�dure de changement de status d'une position (Ne permet pas de passer � un status inf�rieur.
  *
  * aSQM_ANC_POSITION_ID     : ID Position
  * aC_ANC_POS_STATUS        : Nouveau status de la position
  * aPC_SAP_USER1_ID     : User Validation
  * aPC_SAP_USER2_ID     : User Bouclement
  * aSAP_VALIDATION_DATE   : date validation
  * aSAP_CLOSING_DATE    : Date bouclement
  * aUseExternalProc         : Utilisation/ d�clenchement des �ventuelles proc�dures indiv. au bouclement..
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
    -- R�cup�ration de l'ancien status de la position
    select C_ANC_POS_STATUS
         , SQM_ANC_ID
      into aOldStatus
         , aSQM_ANC_ID
      from SQM_ANC_POSITION
     where SQM_ANC_POSITION_ID = aSQM_ANC_POSITION_ID;

    -- On ne permet la modification du status que si le status demand� est > � Oldstatus

    -- Position refus�e
    if aOldStatus = '2' then
      SQM_ANC_GENERATE.AddErrorReport
                 (PCS.PC_FUNCTIONS.TranslateWord('La position est d�j� refus�e, son statut ne peut plus �tre chang�!')
                , aSQM_ANC_ID
                , 1
                 );
    -- Position boucl�e
    elsif aOldStatus = '4' then
      SQM_ANC_GENERATE.AddErrorReport
                 (PCS.PC_FUNCTIONS.TranslateWord('La position est d�j� boucl�e, son statut ne peut plus �tre chang�!')
                , aSQM_ANC_ID
                , 1
                 );
    -- Position � valider
    elsif aOldStatus = '1' then
      -- Doit �tre refus�e
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

      -- Doit �tre "Valid�e"
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

      -- Doit �tre "boucl�e"
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
    -- Position "Valid�e"
    elsif aOldStatus = '3' then
      -- Doit �tre boucl�e
      if aC_ANC_POS_STATUS <> '4' then
        SQM_ANC_GENERATE.AddErrorReport
          (PCS.PC_FUNCTIONS.TranslateWord('La position est d�j� valid�e, son prochain statut est forc�ment "boucl�e"!')
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
