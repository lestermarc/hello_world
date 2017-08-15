--------------------------------------------------------
--  DDL for Package Body DOC_DETAIL_INITIALIZE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DETAIL_INITIALIZE" 
is
  /**
  *  procedure CallInitProc
  *  Description
  *    Aiguillage de l'initialisation selon le mode de création
  */
  procedure CallInitProc
  is
    strIndivInitProc varchar2(250);
    iIndex           integer;
  begin
    iIndex  := DetailsInfo.first;

    -- Procédure d'initialisation de l'utilisateur renseigné à l'appel de la méthode
    if DetailsInfo(iIndex).USER_INIT_PROCEDURE is not null then
      strIndivInitProc  := DetailsInfo(iIndex).USER_INIT_PROCEDURE;
    else
      -- Recherche si une procédure d'initialisation indiv a été renseignée
      --  pour le gabarit et le type de création défini.
      select max(GCP_INIT_PROCEDURE)
        into strIndivInitProc
        from DOC_GAUGE_CREATE_PROC
       where DOC_GAUGE_ID = DetailsInfo(iIndex).DOC_GAUGE_ID
         and C_PDE_CREATE_MODE = DetailsInfo(iIndex).C_PDE_CREATE_MODE
         and C_GROUP_CREATE_MODE = 'PDE';
    end if;

    -- Procédure d'initialisation INDIV
    if strIndivInitProc is not null then
      DOC_DETAIL_INITIALIZE.CallInitProcIndiv(strIndivInitProc);
    -- Appel de la méthode d'init PCS uniquement si code PCS (100 à 199)
    elsif to_number(DetailsInfo(iIndex).C_PDE_CREATE_MODE) between 100 and 199 then
      -- Procédure d'initialisation PCS
      DOC_DETAIL_INITIALIZE.CallInitProcPCS(DetailsInfo(iIndex).C_PDE_CREATE_MODE);
    end if;
  end CallInitProc;

  /**
  *  procedure CallInitProcIndiv
  *  Description
  *    Appel de la procédure d'initialisation Indiv passée en param
  */
  procedure CallInitProcIndiv(aInitProc in DOC_GAUGE_CREATE_PROC.GCP_INIT_PROCEDURE%type)
  is
    Sql_Statement varchar2(500);
    tmpInitProc   DOC_GAUGE_CREATE_PROC.GCP_INIT_PROCEDURE%type;
  begin
    tmpInitProc    := trim(aInitProc);

    -- Ajouter le point-virgule s'il est absent
    if substr(tmpInitProc, length(tmpInitProc), 1) <> ';' then
      tmpInitProc  := tmpInitProc || ';';
    end if;

    Sql_Statement  := 'BEGIN ' || tmpInitProc || ' END;';

    execute immediate Sql_Statement;
  end CallInitProcIndiv;

  /**
  *  procedure CallInitProcPCS
  *  Description
  *    Appel de la procédure d'initialisation PCS correspondant au mode de création
  */
  procedure CallInitProcPCS(aInitMode in varchar2)
  is
    Sql_Statement varchar2(500);
  begin
    Sql_Statement  := ' BEGIN ' || '   DOC_DETAIL_INITIALIZE.InitDetail_' || aInitMode || ';' || ' END;';

    execute immediate Sql_Statement;
  end CallInitProcPCS;

  /**
  *  procedure InitDetail_100
  *  Description
  *    Création - Standard sans possibilité d'indiv (pas accessible à l'utilisateur)
  */
  procedure InitDetail_100
  is
  begin
    null;
  end InitDetail_100;

  /**
  *  procedure InitDetail_110
  *  Description
  *    Création - En série
  */
  procedure InitDetail_110
  is
    cursor crTmpPdeInfo(cTmpPDE_ID in DOC_TMP_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select PDE_BASIS_QUANTITY
           , STM_LOCATION_ID
           , STM_STM_LOCATION_ID
           , PDE_DOC_RECORD_ID
           , PDE_BASIS_DELAY
           , PDE_INTERMEDIATE_DELAY
           , PDE_FINAL_DELAY
           , PDE_CHARACTERIZATION_VALUE_1
           , PDE_CHARACTERIZATION_VALUE_2
           , PDE_CHARACTERIZATION_VALUE_3
           , PDE_CHARACTERIZATION_VALUE_4
           , PDE_CHARACTERIZATION_VALUE_5
           , DIC_PDE_FREE_TABLE_1_ID
           , DIC_PDE_FREE_TABLE_2_ID
           , DIC_PDE_FREE_TABLE_3_ID
           , PDE_DECIMAL_1
           , PDE_DECIMAL_2
           , PDE_DECIMAL_3
           , PDE_TEXT_1
           , PDE_TEXT_2
           , PDE_TEXT_3
           , PDE_DATE_1
           , PDE_DATE_2
           , PDE_DATE_3
           , DIC_DELAY_UPDATE_TYPE_ID
           , PDE_DELAY_UPDATE_TEXT
        from DOC_TMP_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = cTmpPDE_ID;

    tplTmpPdeInfo crTmpPdeInfo%rowtype;
    iIndex        integer;
  begin
    iIndex  := 1;

    open crTmpPdeInfo(DetailsInfo(iIndex).DOC_TMP_PDE_ID);

    fetch crTmpPdeInfo
     into tplTmpPdeInfo;

    if crTmpPdeInfo%found then
      -- Qté du détail
      if     (DetailsInfo(iIndex).USE_PDE_BASIS_QUANTITY = 0)
         and (tplTmpPdeInfo.PDE_BASIS_QUANTITY is not null) then
        DetailsInfo(iIndex).USE_PDE_BASIS_QUANTITY  := 1;
        DetailsInfo(iIndex).PDE_BASIS_QUANTITY      := tplTmpPdeInfo.PDE_BASIS_QUANTITY;
      end if;

      -- Emplacement de stock
      if     (DetailsInfo(iIndex).USE_STM_LOCATION_ID = 0)
         and (tplTmpPdeInfo.STM_LOCATION_ID is not null) then
        DetailsInfo(iIndex).USE_STM_LOCATION_ID  := 1;
        DetailsInfo(iIndex).STM_LOCATION_ID      := tplTmpPdeInfo.STM_LOCATION_ID;
      end if;

      -- Emplacement de transfert de stock
      if     (DetailsInfo(iIndex).USE_STM_STM_LOCATION_ID = 0)
         and (tplTmpPdeInfo.STM_STM_LOCATION_ID is not null) then
        DetailsInfo(iIndex).USE_STM_STM_LOCATION_ID  := 1;
        DetailsInfo(iIndex).STM_STM_LOCATION_ID      := tplTmpPdeInfo.STM_STM_LOCATION_ID;
      end if;

      -- Dossier (Installation)
      if     (DetailsInfo(iIndex).USE_DOC_RECORD_ID = 0)
         and (tplTmpPdeInfo.PDE_DOC_RECORD_ID is not null) then
        DetailsInfo(iIndex).USE_DOC_RECORD_ID  := 1;
        DetailsInfo(iIndex).DOC_RECORD_ID      := tplTmpPdeInfo.PDE_DOC_RECORD_ID;
      end if;

      -- Délais
      if     (DetailsInfo(iIndex).USE_DELAY = 0)
         and (   tplTmpPdeInfo.PDE_BASIS_DELAY is not null
              or tplTmpPdeInfo.PDE_INTERMEDIATE_DELAY is not null
              or tplTmpPdeInfo.PDE_FINAL_DELAY is not null) then
        DetailsInfo(iIndex).USE_DELAY               := 1;
        DetailsInfo(iIndex).PDE_BASIS_DELAY         := tplTmpPdeInfo.PDE_BASIS_DELAY;
        DetailsInfo(iIndex).PDE_INTERMEDIATE_DELAY  := tplTmpPdeInfo.PDE_INTERMEDIATE_DELAY;
        DetailsInfo(iIndex).PDE_FINAL_DELAY         := tplTmpPdeInfo.PDE_FINAL_DELAY;
      end if;

      -- Valeurs de caractérisation
      if     (DetailsInfo(iIndex).USE_CHARACTERIZATION_VALUES = 0)
         and (   tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_1 is not null
              or tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_2 is not null
              or tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_3 is not null
              or tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_4 is not null
              or tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_5 is not null
             ) then
        DetailsInfo(iIndex).USE_CHARACTERIZATION_VALUES   := 1;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_1  := tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_1;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_2  := tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_2;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_3  := tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_3;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_4  := tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_4;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_5  := tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_5;
      end if;

      -- Dicos libres
      if     (DetailsInfo(iIndex).USE_DIC_PDE_FREE_TABLE = 0)
         and (   tplTmpPdeInfo.DIC_PDE_FREE_TABLE_1_ID is not null
              or tplTmpPdeInfo.DIC_PDE_FREE_TABLE_2_ID is not null
              or tplTmpPdeInfo.DIC_PDE_FREE_TABLE_3_ID is not null
             ) then
        DetailsInfo(iIndex).USE_DIC_PDE_FREE_TABLE   := 1;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_1_ID  := tplTmpPdeInfo.DIC_PDE_FREE_TABLE_1_ID;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_2_ID  := tplTmpPdeInfo.DIC_PDE_FREE_TABLE_2_ID;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_3_ID  := tplTmpPdeInfo.DIC_PDE_FREE_TABLE_3_ID;
      end if;

      -- Décimales libres
      if     (DetailsInfo(iIndex).USE_PDE_DECIMAL = 0)
         and (   tplTmpPdeInfo.PDE_DECIMAL_1 is not null
              or tplTmpPdeInfo.PDE_DECIMAL_2 is not null
              or tplTmpPdeInfo.PDE_DECIMAL_3 is not null) then
        DetailsInfo(iIndex).USE_PDE_DECIMAL  := 1;
        DetailsInfo(iIndex).PDE_DECIMAL_1    := tplTmpPdeInfo.PDE_DECIMAL_1;
        DetailsInfo(iIndex).PDE_DECIMAL_2    := tplTmpPdeInfo.PDE_DECIMAL_2;
        DetailsInfo(iIndex).PDE_DECIMAL_3    := tplTmpPdeInfo.PDE_DECIMAL_3;
      end if;

      -- Textes libres
      if     (DetailsInfo(iIndex).USE_PDE_TEXT = 0)
         and (   tplTmpPdeInfo.PDE_TEXT_1 is not null
              or tplTmpPdeInfo.PDE_TEXT_2 is not null
              or tplTmpPdeInfo.PDE_TEXT_3 is not null) then
        DetailsInfo(iIndex).USE_PDE_TEXT  := 1;
        DetailsInfo(iIndex).PDE_TEXT_1    := tplTmpPdeInfo.PDE_TEXT_1;
        DetailsInfo(iIndex).PDE_TEXT_2    := tplTmpPdeInfo.PDE_TEXT_2;
        DetailsInfo(iIndex).PDE_TEXT_3    := tplTmpPdeInfo.PDE_TEXT_3;
      end if;

      -- Dates libres
      if     (DetailsInfo(iIndex).USE_PDE_DATE = 0)
         and (   tplTmpPdeInfo.PDE_DATE_1 is not null
              or tplTmpPdeInfo.PDE_DATE_2 is not null
              or tplTmpPdeInfo.PDE_DATE_3 is not null) then
        DetailsInfo(iIndex).USE_PDE_DATE  := 1;
        DetailsInfo(iIndex).PDE_DATE_1    := tplTmpPdeInfo.PDE_DATE_1;
        DetailsInfo(iIndex).PDE_DATE_2    := tplTmpPdeInfo.PDE_DATE_2;
        DetailsInfo(iIndex).PDE_DATE_3    := tplTmpPdeInfo.PDE_DATE_3;
      end if;

      -- Modif des délais
      if     (DetailsInfo(iIndex).USE_DELAY_UPDATE = 0)
         and (   tplTmpPdeInfo.DIC_DELAY_UPDATE_TYPE_ID is not null
              or tplTmpPdeInfo.PDE_DELAY_UPDATE_TEXT is not null) then
        DetailsInfo(iIndex).USE_DELAY_UPDATE          := 1;
        DetailsInfo(iIndex).DIC_DELAY_UPDATE_TYPE_ID  := tplTmpPdeInfo.DIC_DELAY_UPDATE_TYPE_ID;
        DetailsInfo(iIndex).PDE_DELAY_UPDATE_TEXT     := tplTmpPdeInfo.PDE_DELAY_UPDATE_TEXT;
      end if;
    end if;

    close crTmpPdeInfo;
  end InitDetail_110;

  /**
  *  procedure InitDetail_115
  *  Description
  *    Création - Bien en corrélation
  */
  procedure InitDetail_115
  is
  begin
    -- L'initialisation du 115 est actuellement la même que celle du 110
    DOC_DETAIL_INITIALIZE.InitDetail_110;
  end InitDetail_115;

  /**
  *  procedure InitDetail_117
  *  Description
  *    Création - Emballage
  */
  procedure InitDetail_117
  is
  begin
    null;
  end InitDetail_117;

  /**
  *  procedure InitDetail_118
  *  Description
  *    Création - Litiges
  */
  procedure InitDetail_118
  is
    cursor crPde(cLitigID in DOC_LITIG.DOC_LITIG_ID%type)
    is
      select PDE.*
        from DOC_POSITION_DETAIL PDE
           , DOC_LITIG DLG
       where PDE.DOC_POSITION_DETAIL_ID = DLG.DOC_POSITION_DETAIL_ID
         and DLG.DOC_LITIG_ID = cLitigID;

    tplPde crPde%rowtype;
    iIndex integer;
  begin
    iIndex  := 1;

    if DetailsInfo(iIndex).DOC_LITIG_ID is not null then
      open crPde(DetailsInfo(iIndex).DOC_LITIG_ID);

      fetch crPde
       into tplPde;

      if crPde%found then
        DetailsInfo(iIndex).DOC_PDE_LITIG_ID              := tplPde.DOC_POSITION_DETAIL_ID;
        DetailsInfo(iIndex).USE_FAL_NETWORK_LINK_ID       := 1;
        DetailsInfo(iIndex).FAL_NETWORK_LINK_ID           := tplPde.FAL_NETWORK_LINK_ID;
        DetailsInfo(iIndex).USE_FAL_SCHEDULE_STEP_ID      := 1;
        DetailsInfo(iIndex).FAL_SCHEDULE_STEP_ID          := tplPde.FAL_SCHEDULE_STEP_ID;
        DetailsInfo(iIndex).USE_DOC_RECORD_ID             := 1;
        DetailsInfo(iIndex).DOC_RECORD_ID                 := tplPde.DOC_RECORD_ID;
        DetailsInfo(iIndex).USE_DELAY                     := 1;
        DetailsInfo(iIndex).PDE_BASIS_DELAY               := tplPde.PDE_BASIS_DELAY;
        DetailsInfo(iIndex).PDE_INTERMEDIATE_DELAY        := tplPde.PDE_INTERMEDIATE_DELAY;
        DetailsInfo(iIndex).PDE_FINAL_DELAY               := tplPde.PDE_FINAL_DELAY;
        DetailsInfo(iIndex).PDE_SQM_ACCEPTED_DELAY        := tplPde.PDE_SQM_ACCEPTED_DELAY;
        DetailsInfo(iIndex).USE_DELAY_UPDATE              := 1;
        DetailsInfo(iIndex).DIC_DELAY_UPDATE_TYPE_ID      := tplPde.DIC_DELAY_UPDATE_TYPE_ID;
        DetailsInfo(iIndex).PDE_DELAY_UPDATE_TEXT         := tplPde.PDE_DELAY_UPDATE_TEXT;
        DetailsInfo(iIndex).GCO_CHARACTERIZATION_ID       := tplPde.GCO_CHARACTERIZATION_ID;
        DetailsInfo(iIndex).GCO_GCO_CHARACTERIZATION_ID   := tplPde.GCO_GCO_CHARACTERIZATION_ID;
        DetailsInfo(iIndex).GCO2_GCO_CHARACTERIZATION_ID  := tplPde.GCO2_GCO_CHARACTERIZATION_ID;
        DetailsInfo(iIndex).GCO3_GCO_CHARACTERIZATION_ID  := tplPde.GCO3_GCO_CHARACTERIZATION_ID;
        DetailsInfo(iIndex).GCO4_GCO_CHARACTERIZATION_ID  := tplPde.GCO4_GCO_CHARACTERIZATION_ID;
        DetailsInfo(iIndex).USE_CHARACTERIZATION_VALUES   := 1;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_1  := tplPde.PDE_CHARACTERIZATION_VALUE_1;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_2  := tplPde.PDE_CHARACTERIZATION_VALUE_2;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_3  := tplPde.PDE_CHARACTERIZATION_VALUE_3;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_4  := tplPde.PDE_CHARACTERIZATION_VALUE_4;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_5  := tplPde.PDE_CHARACTERIZATION_VALUE_5;
        DetailsInfo(iIndex).USE_STM_LOCATION_ID           := 1;
        DetailsInfo(iIndex).STM_LOCATION_ID               := tplPde.STM_LOCATION_ID;
        DetailsInfo(iIndex).USE_STM_STM_LOCATION_ID       := 1;
        DetailsInfo(iIndex).STM_STM_LOCATION_ID           := tplPde.STM_STM_LOCATION_ID;
        DetailsInfo(iIndex).USE_DIC_PDE_FREE_TABLE        := 1;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_1_ID       := tplPde.DIC_PDE_FREE_TABLE_1_ID;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_2_ID       := tplPde.DIC_PDE_FREE_TABLE_2_ID;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_3_ID       := tplPde.DIC_PDE_FREE_TABLE_3_ID;
        DetailsInfo(iIndex).USE_PDE_DECIMAL               := 1;
        DetailsInfo(iIndex).PDE_DECIMAL_1                 := tplPde.PDE_DECIMAL_1;
        DetailsInfo(iIndex).PDE_DECIMAL_2                 := tplPde.PDE_DECIMAL_2;
        DetailsInfo(iIndex).PDE_DECIMAL_3                 := tplPde.PDE_DECIMAL_3;
        DetailsInfo(iIndex).USE_PDE_TEXT                  := 1;
        DetailsInfo(iIndex).PDE_TEXT_1                    := tplPde.PDE_TEXT_1;
        DetailsInfo(iIndex).PDE_TEXT_2                    := tplPde.PDE_TEXT_2;
        DetailsInfo(iIndex).PDE_TEXT_3                    := tplPde.PDE_TEXT_3;
        DetailsInfo(iIndex).USE_PDE_DATE                  := 1;
        DetailsInfo(iIndex).PDE_DATE_1                    := tplPde.PDE_DATE_1;
        DetailsInfo(iIndex).PDE_DATE_2                    := tplPde.PDE_DATE_2;
        DetailsInfo(iIndex).PDE_DATE_3                    := tplPde.PDE_DATE_3;
      end if;

      close crPde;
    end if;
  end InitDetail_118;

  /**
  *  procedure InitDetail_120
  *  Description
  *    Création - Génération des cmds Sous-traitance
  */
  procedure InitDetail_120
  is
  begin
    null;
  end InitDetail_120;

  /**
  *  procedure InitDetail_121
  *  Description
  *    Création - Factures de débours
  */
  procedure InitDetail_121
  is
  begin
    null;
  end InitDetail_121;

  /**
  *  procedure InitDetail_122
  *  Description
  *    Création - Factures d'écolages
  */
  procedure InitDetail_122
  is
  begin
    null;
  end InitDetail_122;

  /**
  *  procedure InitDetail_123
  *  Description
  *    Création - Sous-traitance d'achat
  */
  procedure InitDetail_123
  is
  begin
    null;
  end InitDetail_123;

  /**
  *  procedure InitDetail_124
  *  Description
  *    Création - Sous-traitance d'achat - BLST/BLRST
  */
  procedure InitDetail_124
  is
  begin
    null;
  end InitDetail_124;

  /**
  *  procedure InitDetail_125
  *  Description
  *    Création - Gestion des commandes cadre
  */
  procedure InitDetail_125
  is
    cursor crPde(cDetailID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select *
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = cDetailID;

    tplPde crPde%rowtype;
    iIndex integer;
  begin
    iIndex  := 1;

    open crPde(DetailsInfo(iIndex).SOURCE_DOC_POSITION_DETAIL_ID);

    fetch crPde
     into tplPde;

    if crPde%found then
      DetailsInfo(iIndex).USE_FAL_NETWORK_LINK_ID       := 1;
      DetailsInfo(iIndex).FAL_NETWORK_LINK_ID           := tplPde.FAL_NETWORK_LINK_ID;
      DetailsInfo(iIndex).USE_FAL_SCHEDULE_STEP_ID      := 1;
      DetailsInfo(iIndex).FAL_SCHEDULE_STEP_ID          := tplPde.FAL_SCHEDULE_STEP_ID;
      DetailsInfo(iIndex).USE_DOC_RECORD_ID             := 1;
      DetailsInfo(iIndex).DOC_RECORD_ID                 := tplPde.DOC_RECORD_ID;
      DetailsInfo(iIndex).USE_DELAY                     := 1;
      DetailsInfo(iIndex).PDE_BASIS_DELAY               := tplPde.PDE_BASIS_DELAY;
      DetailsInfo(iIndex).PDE_INTERMEDIATE_DELAY        := tplPde.PDE_INTERMEDIATE_DELAY;
      DetailsInfo(iIndex).PDE_FINAL_DELAY               := tplPde.PDE_FINAL_DELAY;
      DetailsInfo(iIndex).PDE_SQM_ACCEPTED_DELAY        := tplPde.PDE_SQM_ACCEPTED_DELAY;
      DetailsInfo(iIndex).USE_DELAY_UPDATE              := 1;
      DetailsInfo(iIndex).DIC_DELAY_UPDATE_TYPE_ID      := tplPde.DIC_DELAY_UPDATE_TYPE_ID;
      DetailsInfo(iIndex).PDE_DELAY_UPDATE_TEXT         := tplPde.PDE_DELAY_UPDATE_TEXT;
      DetailsInfo(iIndex).GCO_CHARACTERIZATION_ID       := tplPde.GCO_CHARACTERIZATION_ID;
      DetailsInfo(iIndex).GCO_GCO_CHARACTERIZATION_ID   := tplPde.GCO_GCO_CHARACTERIZATION_ID;
      DetailsInfo(iIndex).GCO2_GCO_CHARACTERIZATION_ID  := tplPde.GCO2_GCO_CHARACTERIZATION_ID;
      DetailsInfo(iIndex).GCO3_GCO_CHARACTERIZATION_ID  := tplPde.GCO3_GCO_CHARACTERIZATION_ID;
      DetailsInfo(iIndex).GCO4_GCO_CHARACTERIZATION_ID  := tplPde.GCO4_GCO_CHARACTERIZATION_ID;
      DetailsInfo(iIndex).USE_CHARACTERIZATION_VALUES   := 1;
      DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_1  := tplPde.PDE_CHARACTERIZATION_VALUE_1;
      DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_2  := tplPde.PDE_CHARACTERIZATION_VALUE_2;
      DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_3  := tplPde.PDE_CHARACTERIZATION_VALUE_3;
      DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_4  := tplPde.PDE_CHARACTERIZATION_VALUE_4;
      DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_5  := tplPde.PDE_CHARACTERIZATION_VALUE_5;
      DetailsInfo(iIndex).USE_STM_LOCATION_ID           := 1;
      DetailsInfo(iIndex).STM_LOCATION_ID               := tplPde.STM_LOCATION_ID;
      DetailsInfo(iIndex).USE_STM_STM_LOCATION_ID       := 1;
      DetailsInfo(iIndex).STM_STM_LOCATION_ID           := tplPde.STM_STM_LOCATION_ID;
      DetailsInfo(iIndex).USE_DIC_PDE_FREE_TABLE        := 1;
      DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_1_ID       := tplPde.DIC_PDE_FREE_TABLE_1_ID;
      DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_2_ID       := tplPde.DIC_PDE_FREE_TABLE_2_ID;
      DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_3_ID       := tplPde.DIC_PDE_FREE_TABLE_3_ID;
      DetailsInfo(iIndex).USE_PDE_DECIMAL               := 1;
      DetailsInfo(iIndex).PDE_DECIMAL_1                 := tplPde.PDE_DECIMAL_1;
      DetailsInfo(iIndex).PDE_DECIMAL_2                 := tplPde.PDE_DECIMAL_2;
      DetailsInfo(iIndex).PDE_DECIMAL_3                 := tplPde.PDE_DECIMAL_3;
      DetailsInfo(iIndex).USE_PDE_TEXT                  := 1;
      DetailsInfo(iIndex).PDE_TEXT_1                    := tplPde.PDE_TEXT_1;
      DetailsInfo(iIndex).PDE_TEXT_2                    := tplPde.PDE_TEXT_2;
      DetailsInfo(iIndex).PDE_TEXT_3                    := tplPde.PDE_TEXT_3;
      DetailsInfo(iIndex).USE_PDE_DATE                  := 1;
      DetailsInfo(iIndex).PDE_DATE_1                    := tplPde.PDE_DATE_1;
      DetailsInfo(iIndex).PDE_DATE_2                    := tplPde.PDE_DATE_2;
      DetailsInfo(iIndex).PDE_DATE_3                    := tplPde.PDE_DATE_3;
    end if;

    close crPde;
  end InitDetail_125;

  /**
  *  procedure InitDetail_126
  *  Description
  *    Création - Devis simplifié - Offre client
  */
  procedure InitDetail_126
  is
  begin
    null;
  end InitDetail_126;

    /**
  *  procedure InitDetail_127
  *  Description
  *    Création - Devis simplifié - Commande client
  */
  procedure InitDetail_127
  is
  begin
    null;
  end InitDetail_127;

  /**
  *  procedure InitDetail_130
  *  Description
  *    Création - DRP (Demande de réapprovisionement)
  */
  procedure InitDetail_130
  is
  begin
    null;
  end InitDetail_130;

  /**
  *  procedure InitDetail_131
  *  Description
  *    Création - Traitement des lots périmés / refusés
  */
  procedure InitDetail_131
  is
  begin
    null;
  end InitDetail_131;

  /**
  *  procedure InitDetail_132
  *  Description
  *    Création - Assistant de définition des délais
  */
  procedure InitDetail_132
  is
  begin
    null;
  end InitDetail_132;

  /**
  *  procedure InitDetail_135
  *  Description
  *    Création - Reprise des POA
  */
  procedure InitDetail_135
  is
    iIndex integer := 1;
  begin
    DetailsInfo(iIndex).USE_FAL_SUPPLY_REQUEST_ID  := 1;
    DetailsInfo(iIndex).FAL_SUPPLY_REQUEST_ID      := DetailsInfo(iIndex).SOURCE_DOC_POSITION_ID;
    DetailsInfo(iIndex).SOURCE_DOC_POSITION_ID     := null;
  end InitDetail_135;

  /**
  *  procedure InitDetail_137
  *  Description
  *    Création - Demandes de consultations
  */
  procedure InitDetail_137
  is
    cursor crConsultInfo(aConsultID FAL_DOC_CONSULT.FAL_DOC_CONSULT_ID%type)
    is
      select FDC.GCO_GOOD_ID
           , FDC.GCO2_GOOD_ID
           , FDC.PAC_SUPPLIER_PARTNER_ID
           , FDC.PAC2_SUPPLIER_PARTNER_ID
           , CRE.CRE_SUPPLY_DELAY
        from FAL_DOC_CONSULT FDC
           , PAC_SUPPLIER_PARTNER CRE
       where FDC.FAL_DOC_CONSULT_ID = aConsultID
         and FDC.PAC_SUPPLIER_PARTNER_ID = CRE.PAC_SUPPLIER_PARTNER_ID(+);

    tplConsultInfo               crConsultInfo%rowtype;
    vCPU_CONTROL_DELAY           GCO_COMPL_DATA_PURCHASE.CPU_CONTROL_DELAY%type;
    vCPU_SUPPLY_DELAY            GCO_COMPL_DATA_PURCHASE.CPU_SUPPLY_DELAY%type;
    vCDA_COMPLEMENTARY_REFERENCE GCO_COMPL_DATA_PURCHASE.CDA_COMPLEMENTARY_REFERENCE%type;
    vCDA_SHORT_DESCRIPTION       GCO_COMPL_DATA_PURCHASE.CDA_SHORT_DESCRIPTION%type;
    vCDA_LONG_DESCRIPTION        GCO_COMPL_DATA_PURCHASE.CDA_LONG_DESCRIPTION%type;
    vCDA_FREE_DESCRIPTION        GCO_COMPL_DATA_PURCHASE.CDA_FREE_DESCRIPTION%type;
    vCDA_COMPLEMENTARY_EAN_CODE  GCO_COMPL_DATA_PURCHASE.CDA_COMPLEMENTARY_EAN_CODE%type;
    lScheduleID                  PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vBasisDelay                  DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    vInterDelay                  DOC_POSITION_DETAIL.PDE_INTERMEDIATE_DELAY%type;
    iIndex                       integer                                                    := 1;
  begin
    -- Recherche des infos concernant la consultation (on a toujours un seul détail par position)
    open crConsultInfo(DetailsInfo(iIndex).SOURCE_DOC_POSITION_ID);

    fetch crConsultInfo
     into tplConsultInfo;

    if crConsultInfo%found then
      if PCS.PC_CONFIG.GetConfig('DOC_THREE_DELAY') = '1' then
        -- Recherche du type de calendrier à utiliser
        lScheduleID  := FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendar(aPAC_SUPPLIER_PARTNER_ID => tplConsultInfo.PAC_SUPPLIER_PARTNER_ID);

        -- Recherche des données complémentaires d'achat
        if FAL_DELAY_ASSISTANT_DEF.GetDonnneesCompAchat(aGoodID                        => tplConsultInfo.GCO_GOOD_ID
                                                      , aGoodID2                       => tplConsultInfo.GCO2_GOOD_ID
                                                      , aThirdID                       => tplConsultInfo.PAC_SUPPLIER_PARTNER_ID
                                                      , aThirdID2                      => tplConsultInfo.PAC2_SUPPLIER_PARTNER_ID
                                                      , aCPU_CONTROL_DELAY             => vCPU_CONTROL_DELAY
                                                      , aCPU_SUPPLY_DELAY              => vCPU_SUPPLY_DELAY
                                                      , aCDA_Complementary_Reference   => vCDA_COMPLEMENTARY_REFERENCE
                                                      , aCDA_Short_Description         => vCDA_SHORT_DESCRIPTION
                                                      , aCDA_Long_Description          => vCDA_LONG_DESCRIPTION
                                                      , aCDA_Free_Description          => vCDA_FREE_DESCRIPTION
                                                      , aCDA_Complementary_EAN_Code    => vCDA_COMPLEMENTARY_EAN_CODE
                                                       ) then
          -- Calcul du délai intermédiaire
          vInterDelay  :=
            FAL_SCHEDULE_FUNCTIONS.GetDecalageBackwardDate(aCalendarID   => lScheduleID
                                                         , aFromDate     => DetailsInfo(iIndex).PDE_FINAL_DELAY
                                                         , aDecalage     => vCPU_CONTROL_DELAY
                                                          );
          -- Calcul du délai Initial
          vBasisDelay  := FAL_SCHEDULE_FUNCTIONS.GetDecalageBackwardDate(aCalendarID => lScheduleID, aFromDate => vInterDelay, aDecalage => vCPU_SUPPLY_DELAY);
        else
          -- Calcul du délai intermédiaire
          vInterDelay  := DetailsInfo(iIndex).PDE_FINAL_DELAY;
          -- Calcul du délai Initial
          vBasisDelay  :=
             FAL_SCHEDULE_FUNCTIONS.GetDecalageBackwardDate(aCalendarID   => lScheduleID, aFromDate => vInterDelay
                                                          , aDecalage     => tplConsultInfo.CRE_SUPPLY_DELAY);
        end if;
      else
        -- Calcul du délai intermédiaire
        vInterDelay  := DetailsInfo(iIndex).PDE_FINAL_DELAY;
        -- Calcul du délai Initial
        vBasisDelay  := vInterDelay;
      end if;

      -- Délai intermédiaire
      if vInterDelay is not null then
        DetailsInfo(iIndex).USE_DELAY               := 1;
        DetailsInfo(iIndex).PDE_INTERMEDIATE_DELAY  := vInterDelay;
      end if;

      -- Délai initial
      if vBasisDelay is not null then
        DetailsInfo(iIndex).USE_DELAY        := 1;
        DetailsInfo(iIndex).PDE_BASIS_DELAY  := vBasisDelay;
      end if;
    end if;

    close crConsultInfo;

    -- Remise à zéro de l'ID position source
    DetailsInfo(iIndex).SOURCE_DOC_POSITION_ID  := null;
  end InitDetail_137;

  /**
  *  procedure InitDetail_140
  *  Description
  *    Création - Générateur de documents
  */
  procedure InitDetail_140
  is
    cursor crInterfaceDetailInfo(
      cInterfaceID    in DOC_INTERFACE.DOC_INTERFACE_ID%type
    , cInterfacePosID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
    , cPosNumber      in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
    )
    is
      select   DOP_QTY
             , nvl(DOP_UTIL_COEFF, 1) DOP_UTIL_COEFF
             , DOC_POSITION_PT_ID
             , STM_LOCATION_ID
             , STM_STM_LOCATION_ID
             , DOP_CHARACTERIZATION_VALUE_1
             , DOP_CHARACTERIZATION_VALUE_2
             , DOP_CHARACTERIZATION_VALUE_3
             , DOP_CHARACTERIZATION_VALUE_4
             , DOP_CHARACTERIZATION_VALUE_5
             , DOP_BASIS_DELAY
             , DOP_INTERMEDIATE_DELAY
             , DOP_FINAL_DELAY
             , DIC_PDE_FREE_TABLE_1_ID
             , DIC_PDE_FREE_TABLE_2_ID
             , DIC_PDE_FREE_TABLE_3_ID
             , DOP_PDE_TEXT_1
             , DOP_PDE_TEXT_2
             , DOP_PDE_TEXT_3
             , DOP_PDE_DECIMAL_1
             , DOP_PDE_DECIMAL_2
             , DOP_PDE_DECIMAL_3
             , DOP_PDE_DATE_1
             , DOP_PDE_DATE_2
             , DOP_PDE_DATE_3
             , A_DATECRE
             , A_IDCRE
             , A_DATEMOD
             , A_IDMOD
             , A_RECLEVEL
             , A_RECSTATUS
             , A_CONFIRM
             , DOP.C_CHARACT1_TYPE
             , DOP.C_CHARACT2_TYPE
             , DOP.C_CHARACT3_TYPE
             , DOP.C_CHARACT4_TYPE
             , DOP.C_CHARACT5_TYPE
          from DOC_INTERFACE_POSITION DOP
         where DOC_INTERFACE_ID = cInterfaceID
           and (   DOC_INTERFACE_POSITION_ID = cInterfacePosID
                or cInterfacePosID is null)
           and (   DOP_POS_NUMBER = cPosNumber
                or cPosNumber is null)
           and nvl(C_INTERFACE_GEN_MODE, 'INSERT') = 'INSERT'
      order by DOC_INTERFACE_POSITION_ID;

    tplInterfaceDetailInfo crInterfaceDetailInfo%rowtype;
    iIndex                 integer;
    tmpDetailInfo          TDetailInfo;
  begin
    iIndex         := 1;
    tmpDetailInfo  := DetailsInfo(iIndex);

    -- Liste du ou des détail(s) à créer
    open crInterfaceDetailInfo(DetailsInfo(iIndex).DOC_INTERFACE_ID, DetailsInfo(iIndex).DOC_INTERFACE_POSITION_ID, DetailsInfo(iIndex).DOP_POS_NUMBER);

    fetch crInterfaceDetailInfo
     into tplInterfaceDetailInfo;

    while crInterfaceDetailInfo%found loop
      -- Quantité
      DetailsInfo(iIndex).USE_PDE_BASIS_QUANTITY  := 1;

      if tplInterfaceDetailInfo.DOC_POSITION_PT_ID is not null then
        select DOP_QTY * tplInterfaceDetailInfo.DOP_UTIL_COEFF
          into DetailsInfo(iIndex).PDE_BASIS_QUANTITY
          from DOC_INTERFACE_POSITION
         where DOC_INTERFACE_POSITION_ID = tplInterfaceDetailInfo.DOC_POSITION_PT_ID;
      else
        DetailsInfo(iIndex).PDE_BASIS_QUANTITY  := tplInterfaceDetailInfo.DOP_QTY;
      end if;

      -- Emplacement de stock
      if (tplInterfaceDetailInfo.STM_LOCATION_ID is not null) then
        DetailsInfo(iIndex).USE_STM_LOCATION_ID  := 1;
        DetailsInfo(iIndex).STM_LOCATION_ID      := tplInterfaceDetailInfo.STM_LOCATION_ID;
      end if;

      -- Emplacement de transfert de stock
      if (tplInterfaceDetailInfo.STM_STM_LOCATION_ID is not null) then
        DetailsInfo(iIndex).USE_STM_STM_LOCATION_ID  := 1;
        DetailsInfo(iIndex).STM_STM_LOCATION_ID      := tplInterfaceDetailInfo.STM_STM_LOCATION_ID;
      end if;

      -- Valeurs de caractérisation
      if (   tplInterfaceDetailInfo.DOP_CHARACTERIZATION_VALUE_1 is not null
          or tplInterfaceDetailInfo.DOP_CHARACTERIZATION_VALUE_2 is not null
          or tplInterfaceDetailInfo.DOP_CHARACTERIZATION_VALUE_3 is not null
          or tplInterfaceDetailInfo.DOP_CHARACTERIZATION_VALUE_4 is not null
          or tplInterfaceDetailInfo.DOP_CHARACTERIZATION_VALUE_5 is not null
         ) then
        DetailsInfo(iIndex).USE_CHARACTERIZATION_VALUES   := 1;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_1  := tplInterfaceDetailInfo.DOP_CHARACTERIZATION_VALUE_1;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_2  := tplInterfaceDetailInfo.DOP_CHARACTERIZATION_VALUE_2;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_3  := tplInterfaceDetailInfo.DOP_CHARACTERIZATION_VALUE_3;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_4  := tplInterfaceDetailInfo.DOP_CHARACTERIZATION_VALUE_4;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_5  := tplInterfaceDetailInfo.DOP_CHARACTERIZATION_VALUE_5;
      end if;

      -- Délais
      if (   tplInterfaceDetailInfo.DOP_BASIS_DELAY is not null
          or tplInterfaceDetailInfo.DOP_INTERMEDIATE_DELAY is not null
          or tplInterfaceDetailInfo.DOP_FINAL_DELAY is not null
         ) then
        DetailsInfo(iIndex).USE_DELAY               := 1;
        DetailsInfo(iIndex).PDE_BASIS_DELAY         := tplInterfaceDetailInfo.DOP_BASIS_DELAY;
        DetailsInfo(iIndex).PDE_INTERMEDIATE_DELAY  := tplInterfaceDetailInfo.DOP_INTERMEDIATE_DELAY;
        DetailsInfo(iIndex).PDE_FINAL_DELAY         := tplInterfaceDetailInfo.DOP_FINAL_DELAY;
      end if;

      -- Dicos libres
      if     (DetailsInfo(iIndex).USE_DIC_PDE_FREE_TABLE = 0)
         and (   tplInterfaceDetailInfo.DIC_PDE_FREE_TABLE_1_ID is not null
              or tplInterfaceDetailInfo.DIC_PDE_FREE_TABLE_2_ID is not null
              or tplInterfaceDetailInfo.DIC_PDE_FREE_TABLE_3_ID is not null
             ) then
        DetailsInfo(iIndex).USE_DIC_PDE_FREE_TABLE   := 1;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_1_ID  := tplInterfaceDetailInfo.DIC_PDE_FREE_TABLE_1_ID;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_2_ID  := tplInterfaceDetailInfo.DIC_PDE_FREE_TABLE_2_ID;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_3_ID  := tplInterfaceDetailInfo.DIC_PDE_FREE_TABLE_3_ID;
      end if;

      -- Textes libres
      if     (DetailsInfo(iIndex).USE_PDE_TEXT = 0)
         and (   tplInterfaceDetailInfo.DOP_PDE_TEXT_1 is not null
              or tplInterfaceDetailInfo.DOP_PDE_TEXT_2 is not null
              or tplInterfaceDetailInfo.DOP_PDE_TEXT_3 is not null
             ) then
        DetailsInfo(iIndex).USE_PDE_TEXT  := 1;
        DetailsInfo(iIndex).PDE_TEXT_1    := tplInterfaceDetailInfo.DOP_PDE_TEXT_1;
        DetailsInfo(iIndex).PDE_TEXT_2    := tplInterfaceDetailInfo.DOP_PDE_TEXT_2;
        DetailsInfo(iIndex).PDE_TEXT_3    := tplInterfaceDetailInfo.DOP_PDE_TEXT_3;
      end if;

      -- Décimales libres
      if     (DetailsInfo(iIndex).USE_PDE_DECIMAL = 0)
         and (   tplInterfaceDetailInfo.DOP_PDE_DECIMAL_1 is not null
              or tplInterfaceDetailInfo.DOP_PDE_DECIMAL_2 is not null
              or tplInterfaceDetailInfo.DOP_PDE_DECIMAL_3 is not null
             ) then
        DetailsInfo(iIndex).USE_PDE_DECIMAL  := 1;
        DetailsInfo(iIndex).PDE_DECIMAL_1    := tplInterfaceDetailInfo.DOP_PDE_DECIMAL_1;
        DetailsInfo(iIndex).PDE_DECIMAL_2    := tplInterfaceDetailInfo.DOP_PDE_DECIMAL_2;
        DetailsInfo(iIndex).PDE_DECIMAL_3    := tplInterfaceDetailInfo.DOP_PDE_DECIMAL_3;
      end if;

      -- Dates libres
      if     (DetailsInfo(iIndex).USE_PDE_DATE = 0)
         and (   tplInterfaceDetailInfo.DOP_PDE_DATE_1 is not null
              or tplInterfaceDetailInfo.DOP_PDE_DATE_2 is not null
              or tplInterfaceDetailInfo.DOP_PDE_DATE_3 is not null
             ) then
        DetailsInfo(iIndex).USE_PDE_DATE  := 1;
        DetailsInfo(iIndex).PDE_DATE_1    := tplInterfaceDetailInfo.DOP_PDE_DATE_1;
        DetailsInfo(iIndex).PDE_DATE_2    := tplInterfaceDetailInfo.DOP_PDE_DATE_2;
        DetailsInfo(iIndex).PDE_DATE_3    := tplInterfaceDetailInfo.DOP_PDE_DATE_3;
      end if;

      -- Date de création
      DetailsInfo(iIndex).A_DATECRE               := tplInterfaceDetailInfo.A_DATECRE;
      -- Utilisateur de la création
      DetailsInfo(iIndex).A_IDCRE                 := tplInterfaceDetailInfo.A_IDCRE;

      -- Date de modif
      if     (DetailsInfo(iIndex).USE_A_DATEMOD = 0)
         and (tplInterfaceDetailInfo.A_DATEMOD is not null) then
        DetailsInfo(iIndex).USE_A_DATEMOD  := 1;
        DetailsInfo(iIndex).A_DATEMOD      := tplInterfaceDetailInfo.A_DATEMOD;
      end if;

      -- Utilisateur de la modif
      if     (DetailsInfo(iIndex).USE_A_IDMOD = 0)
         and (tplInterfaceDetailInfo.A_IDMOD is not null) then
        DetailsInfo(iIndex).USE_A_IDMOD  := 1;
        DetailsInfo(iIndex).A_IDMOD      := tplInterfaceDetailInfo.A_IDMOD;
      end if;

      -- Niveau
      if     (DetailsInfo(iIndex).USE_A_RECLEVEL = 0)
         and (tplInterfaceDetailInfo.A_RECLEVEL is not null) then
        DetailsInfo(iIndex).USE_A_RECLEVEL  := 1;
        DetailsInfo(iIndex).A_RECLEVEL      := tplInterfaceDetailInfo.A_RECLEVEL;
      end if;

      -- Statut
      if     (DetailsInfo(iIndex).USE_A_RECSTATUS = 0)
         and (tplInterfaceDetailInfo.A_RECSTATUS is not null) then
        DetailsInfo(iIndex).USE_A_RECSTATUS  := 1;
        DetailsInfo(iIndex).A_RECSTATUS      := tplInterfaceDetailInfo.A_RECSTATUS;
      end if;

      -- Confirmation
      if     (DetailsInfo(iIndex).USE_A_CONFIRM = 0)
         and (tplInterfaceDetailInfo.A_CONFIRM is not null) then
        DetailsInfo(iIndex).USE_A_CONFIRM  := 1;
        DetailsInfo(iIndex).A_CONFIRM      := tplInterfaceDetailInfo.A_CONFIRM;
      end if;

      -- Type de caractérisation
      if (   tplInterfaceDetailInfo.C_CHARACT1_TYPE is not null
          or tplInterfaceDetailInfo.C_CHARACT2_TYPE is not null
          or tplInterfaceDetailInfo.C_CHARACT3_TYPE is not null
          or tplInterfaceDetailInfo.C_CHARACT4_TYPE is not null
          or tplInterfaceDetailInfo.C_CHARACT5_TYPE is not null
         ) then
        DetailsInfo(iIndex).USE_CHARACT_TYPE  := 1;
        DetailsInfo(iIndex).C_CHARACT1_TYPE   := tplInterfaceDetailInfo.C_CHARACT1_TYPE;
        DetailsInfo(iIndex).C_CHARACT2_TYPE   := tplInterfaceDetailInfo.C_CHARACT2_TYPE;
        DetailsInfo(iIndex).C_CHARACT3_TYPE   := tplInterfaceDetailInfo.C_CHARACT3_TYPE;
        DetailsInfo(iIndex).C_CHARACT4_TYPE   := tplInterfaceDetailInfo.C_CHARACT4_TYPE;
        DetailsInfo(iIndex).C_CHARACT5_TYPE   := tplInterfaceDetailInfo.C_CHARACT5_TYPE;
      end if;

      -- Détail suivant de la table DOC_INTERFACE_POSITION
      fetch crInterfaceDetailInfo
       into tplInterfaceDetailInfo;

      -- rajouter un record TDetailInfo à la structure de stockage s'il y a encore des détails
      if crInterfaceDetailInfo%found then
        iIndex               := iIndex + 1;
        -- Ajout d'un record dans la structure pour le détail suivant
        DetailsInfo(iIndex)  := tmpDetailInfo;
      end if;
    end loop;

    close crInterfaceDetailInfo;
  end InitDetail_140;

  /**
  *  procedure InitDetail_141
  *  Description
  *    Création - Générateur de documents concernant la dématérialisation
  */
  procedure InitDetail_141
  is
  begin
    -- L'initialisation du 141 est actuellement la même que celle du 140
    InitDetail_140;
  end InitDetail_141;

  /**
  *  procedure InitDetail_142
  *  Description
  *    Création - Générateur de documents - E-Shop
  */
  procedure InitDetail_142
  is
  begin
    -- L'initialisation du 142 est actuellement la même que celle du 140
    InitDetail_140;
  end InitDetail_142;

  /**
  *  procedure InitDetail_150
  *  Description
  *    Création - Dossiers SAV
  */
  procedure InitDetail_150
  is
  begin
    null;
  end InitDetail_150;

  /**
  *  procedure InitDetail_155
  *  Description
  *    Création - SAV externe
  */
  procedure InitDetail_155
  is
  begin
    null;
  end InitDetail_155;

  /**
  *  procedure InitDetail_160
  *  Description
  *    Création - CML
  */
  procedure InitDetail_160
  is
  begin
    null;
  end InitDetail_160;

  /**
  *  procedure InitDetail_165
  *  Description
  *    Création - Facturation des contrats de maintenance
  */
  procedure InitDetail_165
  is
  begin
    null;
  end InitDetail_165;

  /**
  *  procedure InitDetail_170
  *  Description
  *    Création - Assistant devis
  */
  procedure InitDetail_170
  is
  begin
    null;
  end InitDetail_170;

  /**
  *  procedure InitDetail_180
  *  Description
  *    Création - Extraction des commissions
  */
  procedure InitDetail_180
  is
  begin
    null;
  end InitDetail_180;

  /**
  *  procedure InitDetail_190
  *  Description
  *    Création - Echéancier
  */
  procedure InitDetail_190
  is
    cursor crTmpPdeInfo(cSrcID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select PDE_BASIS_QUANTITY
           , STM_LOCATION_ID
           , STM_STM_LOCATION_ID
           , PDE_BASIS_DELAY
           , PDE_INTERMEDIATE_DELAY
           , PDE_FINAL_DELAY
           , PDE_CHARACTERIZATION_VALUE_1
           , PDE_CHARACTERIZATION_VALUE_2
           , PDE_CHARACTERIZATION_VALUE_3
           , PDE_CHARACTERIZATION_VALUE_4
           , PDE_CHARACTERIZATION_VALUE_5
           , DIC_PDE_FREE_TABLE_1_ID
           , DIC_PDE_FREE_TABLE_2_ID
           , DIC_PDE_FREE_TABLE_3_ID
           , PDE_DECIMAL_1
           , PDE_DECIMAL_2
           , PDE_DECIMAL_3
           , PDE_TEXT_1
           , PDE_TEXT_2
           , PDE_TEXT_3
           , PDE_DATE_1
           , PDE_DATE_2
           , PDE_DATE_3
           , DIC_DELAY_UPDATE_TYPE_ID
           , PDE_DELAY_UPDATE_TEXT
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = cSrcID;

    tplTmpPdeInfo crTmpPdeInfo%rowtype;
    iIndex        integer;
  begin
    iIndex  := 1;

    open crTmpPdeInfo(DetailsInfo(iIndex).SOURCE_DOC_POSITION_DETAIL_ID);

    fetch crTmpPdeInfo
     into tplTmpPdeInfo;

    if crTmpPdeInfo%found then
      -- Emplacement de stock
      if     (DetailsInfo(iIndex).USE_STM_LOCATION_ID = 0)
         and (tplTmpPdeInfo.STM_LOCATION_ID is not null) then
        DetailsInfo(iIndex).USE_STM_LOCATION_ID  := 1;
        DetailsInfo(iIndex).STM_LOCATION_ID      := tplTmpPdeInfo.STM_LOCATION_ID;
      end if;

      -- Emplacement de transfert de stock
      if     (DetailsInfo(iIndex).USE_STM_STM_LOCATION_ID = 0)
         and (tplTmpPdeInfo.STM_STM_LOCATION_ID is not null) then
        DetailsInfo(iIndex).USE_STM_STM_LOCATION_ID  := 1;
        DetailsInfo(iIndex).STM_STM_LOCATION_ID      := tplTmpPdeInfo.STM_STM_LOCATION_ID;
      end if;

      -- Valeurs de caractérisation
      if     (DetailsInfo(iIndex).USE_CHARACTERIZATION_VALUES = 0)
         and (   tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_1 is not null
              or tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_2 is not null
              or tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_3 is not null
              or tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_4 is not null
              or tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_5 is not null
             ) then
        DetailsInfo(iIndex).USE_CHARACTERIZATION_VALUES   := 1;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_1  := tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_1;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_2  := tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_2;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_3  := tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_3;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_4  := tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_4;
        DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_5  := tplTmpPdeInfo.PDE_CHARACTERIZATION_VALUE_5;
      end if;

      -- Dicos libres
      if     (DetailsInfo(iIndex).USE_DIC_PDE_FREE_TABLE = 0)
         and (   tplTmpPdeInfo.DIC_PDE_FREE_TABLE_1_ID is not null
              or tplTmpPdeInfo.DIC_PDE_FREE_TABLE_2_ID is not null
              or tplTmpPdeInfo.DIC_PDE_FREE_TABLE_3_ID is not null
             ) then
        DetailsInfo(iIndex).USE_DIC_PDE_FREE_TABLE   := 1;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_1_ID  := tplTmpPdeInfo.DIC_PDE_FREE_TABLE_1_ID;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_2_ID  := tplTmpPdeInfo.DIC_PDE_FREE_TABLE_2_ID;
        DetailsInfo(iIndex).DIC_PDE_FREE_TABLE_3_ID  := tplTmpPdeInfo.DIC_PDE_FREE_TABLE_3_ID;
      end if;

      -- Décimales libres
      if     (DetailsInfo(iIndex).USE_PDE_DECIMAL = 0)
         and (   tplTmpPdeInfo.PDE_DECIMAL_1 is not null
              or tplTmpPdeInfo.PDE_DECIMAL_2 is not null
              or tplTmpPdeInfo.PDE_DECIMAL_3 is not null) then
        DetailsInfo(iIndex).USE_PDE_DECIMAL  := 1;
        DetailsInfo(iIndex).PDE_DECIMAL_1    := tplTmpPdeInfo.PDE_DECIMAL_1;
        DetailsInfo(iIndex).PDE_DECIMAL_2    := tplTmpPdeInfo.PDE_DECIMAL_2;
        DetailsInfo(iIndex).PDE_DECIMAL_3    := tplTmpPdeInfo.PDE_DECIMAL_3;
      end if;

      -- Textes libres
      if     (DetailsInfo(iIndex).USE_PDE_TEXT = 0)
         and (   tplTmpPdeInfo.PDE_TEXT_1 is not null
              or tplTmpPdeInfo.PDE_TEXT_2 is not null
              or tplTmpPdeInfo.PDE_TEXT_3 is not null) then
        DetailsInfo(iIndex).USE_PDE_TEXT  := 1;
        DetailsInfo(iIndex).PDE_TEXT_1    := tplTmpPdeInfo.PDE_TEXT_1;
        DetailsInfo(iIndex).PDE_TEXT_2    := tplTmpPdeInfo.PDE_TEXT_2;
        DetailsInfo(iIndex).PDE_TEXT_3    := tplTmpPdeInfo.PDE_TEXT_3;
      end if;

      -- Dates libres
      if     (DetailsInfo(iIndex).USE_PDE_DATE = 0)
         and (   tplTmpPdeInfo.PDE_DATE_1 is not null
              or tplTmpPdeInfo.PDE_DATE_2 is not null
              or tplTmpPdeInfo.PDE_DATE_3 is not null) then
        DetailsInfo(iIndex).USE_PDE_DATE  := 1;
        DetailsInfo(iIndex).PDE_DATE_1    := tplTmpPdeInfo.PDE_DATE_1;
        DetailsInfo(iIndex).PDE_DATE_2    := tplTmpPdeInfo.PDE_DATE_2;
        DetailsInfo(iIndex).PDE_DATE_3    := tplTmpPdeInfo.PDE_DATE_3;
      end if;
    end if;

    close crTmpPdeInfo;
  end InitDetail_190;
end DOC_DETAIL_INITIALIZE;
