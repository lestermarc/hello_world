--------------------------------------------------------
--  DDL for Package Body DOC_POSITION_INITIALIZE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_POSITION_INITIALIZE" 
is
  /*
  * Aiguillage de l'initialisation selon le mode de création
  */
  procedure CallInitProc
  is
    strIndivInitProc varchar2(250);
  begin
    -- Procédure d'initialisation de l'utilisateur renseigné à l'appel de la méthode
    if DOC_POSITION_INITIALIZE.PositionInfo.USER_INIT_PROCEDURE is not null then
      strIndivInitProc  := DOC_POSITION_INITIALIZE.PositionInfo.USER_INIT_PROCEDURE;
    else
      -- Recherche si une procédure d'initialisation indiv a été renseignée
      --  pour le gabarit et le type de création défini.
      select max(GCP_INIT_PROCEDURE)
        into strIndivInitProc
        from DOC_GAUGE_CREATE_PROC
       where DOC_GAUGE_ID = DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_ID
         and C_POS_CREATE_MODE = DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE
         and C_GROUP_CREATE_MODE = 'POS';
    end if;

    -- Procédure d'initialisation INDIV
    if strIndivInitProc is not null then
      DOC_POSITION_INITIALIZE.CallInitProcIndiv(strIndivInitProc);
    -- Appel de la méthode d'init PCS uniquement si code PCS (100 à 199)
    elsif to_number(DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE) between 100 and 199 then
      -- Procédure d'initialisation PCS
      DOC_POSITION_INITIALIZE.CallInitProcPCS(DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE);
    end if;
  end CallInitProc;

  /*
  *  Appel de la procédure d'initialisation Indiv
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

  /*
  *  Appel de la procédure d'initialisation PCS
  */
  procedure CallInitProcPCS(aInitMode in varchar2)
  is
    Sql_Statement varchar2(500);
  begin
    Sql_Statement  := ' BEGIN ' || '   DOC_POSITION_INITIALIZE.InitPosition_' || aInitMode || ';' || ' END;';

    execute immediate Sql_Statement;
  end CallInitProcPCS;

  /**
  *  procedure InitPosition_100
  *  Description
  *    Création - Standard sans possibilité d'indiv (pas accessible à l'utilisateur)
  */
  procedure InitPosition_100
  is
  begin
    null;
  end InitPosition_100;

  /**
  *  procedure InitPosition_110
  *  Description
  *    Création - En série
  */
  procedure InitPosition_110
  is
    cursor crTmpPosInfo(cTmpPos_ID in DOC_TMP_POSITION_DETAIL.DOC_POSITION_ID%type)
    is
      select   DOC_GAUGE_POSITION_ID
             , C_GAUGE_TYPE_POS
             , GCO_GOOD_ID
             , PDE_BASIS_QUANTITY
             , STM_LOCATION_ID
             , STM_STM_LOCATION_ID
             , DOC_RECORD_ID
             , PAC_REPRESENTATIVE_ID
             , PAC_REPR_ACI_ID
             , PAC_REPR_DELIVERY_ID
             , POS_GROSS_UNIT_VALUE
             , POS_UNIT_COST_PRICE
             , PPS_NOMENCLATURE_ID
             , POS_CONVERT_FACTOR
             , POS_BODY_TEXT
             , DOC_DOC_POSITION_ID
             , DTP_UTIL_COEF
          from DOC_TMP_POSITION_DETAIL
         where DOC_POSITION_ID = cTmpPos_ID
      order by DOC_POSITION_DETAIL_ID asc;

    tplTmpPosInfo crTmpPosInfo%rowtype;
  begin
    open crTmpPosInfo(DOC_POSITION_INITIALIZE.PositionInfo.DOC_TMP_POS_ID);

    fetch crTmpPosInfo
     into tplTmpPosInfo;

    if crTmpPosInfo%found then
      -- ID Gabarit position
      if     (tplTmpPosInfo.DOC_GAUGE_POSITION_ID is not null)
         and (DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_POSITION_ID is null) then
        DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_POSITION_ID  := tplTmpPosInfo.DOC_GAUGE_POSITION_ID;
      end if;

      -- Bien
      if     (tplTmpPosInfo.GCO_GOOD_ID is not null)
         and (DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID is null) then
        DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID  := tplTmpPosInfo.GCO_GOOD_ID;
      end if;

      -- Qté de la position
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY = 0)
         and (tplTmpPosInfo.PDE_BASIS_QUANTITY is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY      := tplTmpPosInfo.PDE_BASIS_QUANTITY;
      end if;

      -- Stock et emplacement de stock
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_STOCK = 0)
         and (tplTmpPosInfo.STM_LOCATION_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_STOCK        := 1;

        select STM_STOCK_ID
          into DOC_POSITION_INITIALIZE.PositionInfo.STM_STOCK_ID
          from STM_LOCATION
         where STM_LOCATION_ID = tplTmpPosInfo.STM_LOCATION_ID;

        DOC_POSITION_INITIALIZE.PositionInfo.STM_LOCATION_ID  := tplTmpPosInfo.STM_LOCATION_ID;
      end if;

      -- Stock et emplacement de transfert
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_TRANSFERT_STOCK = 0)
         and (tplTmpPosInfo.STM_STM_LOCATION_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_TRANSFERT_STOCK  := 1;

        select STM_STOCK_ID
          into DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_STOCK_ID
          from STM_LOCATION
         where STM_LOCATION_ID = tplTmpPosInfo.STM_STM_LOCATION_ID;

        DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_LOCATION_ID  := tplTmpPosInfo.STM_STM_LOCATION_ID;
      end if;

      -- Dossier
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_DOC_RECORD_ID = 0)
         and (tplTmpPosInfo.DOC_RECORD_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_DOC_RECORD_ID  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.DOC_RECORD_ID      := tplTmpPosInfo.DOC_RECORD_ID;
      end if;

      -- Représentant
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPRESENTATIVE_ID = 0)
         and (tplTmpPosInfo.PAC_REPRESENTATIVE_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPRESENTATIVE_ID  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPRESENTATIVE_ID      := tplTmpPosInfo.PAC_REPRESENTATIVE_ID;
      end if;

      -- Représentant facturation
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPR_ACI_ID = 0)
         and (tplTmpPosInfo.PAC_REPR_ACI_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPR_ACI_ID  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPR_ACI_ID      := tplTmpPosInfo.PAC_REPR_ACI_ID;
      end if;

      -- Représentant livraison
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPR_DELIVERY_ID = 0)
         and (tplTmpPosInfo.PAC_REPR_DELIVERY_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPR_DELIVERY_ID  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPR_DELIVERY_ID      := tplTmpPosInfo.PAC_REPR_DELIVERY_ID;
      end if;

      -- Prix unitaire
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_GOOD_PRICE = 0)
         and (tplTmpPosInfo.POS_GROSS_UNIT_VALUE is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_GOOD_PRICE  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE      := tplTmpPosInfo.POS_GROSS_UNIT_VALUE;
      end if;

      -- Prix de revient unitaire
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UNIT_COST_PRICE = 0)
         and (tplTmpPosInfo.POS_UNIT_COST_PRICE is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UNIT_COST_PRICE  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_UNIT_COST_PRICE      := tplTmpPosInfo.POS_UNIT_COST_PRICE;
      end if;

      -- Nomenclature
      if (tplTmpPosInfo.PPS_NOMENCLATURE_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.PPS_NOMENCLATURE_ID  := tplTmpPosInfo.PPS_NOMENCLATURE_ID;
      end if;

      -- Facteur de conversion
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_CONVERT_FACTOR = 0)
         and (tplTmpPosInfo.POS_CONVERT_FACTOR is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_CONVERT_FACTOR  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_CONVERT_FACTOR      := tplTmpPosInfo.POS_CONVERT_FACTOR;
      end if;

      -- ID de la position PT
      DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOC_POSITION_ID  := tplTmpPosInfo.DOC_DOC_POSITION_ID;

      -- Coefficient d'utilisation (pour les positions CPT)
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UTIL_COEFF = 0)
         and (tplTmpPosInfo.DTP_UTIL_COEF is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UTIL_COEFF  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_UTIL_COEFF      := tplTmpPosInfo.DTP_UTIL_COEF;
      end if;

      -- Texte de corps
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT = 0)
         and (tplTmpPosInfo.POS_BODY_TEXT is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT      := tplTmpPosInfo.POS_BODY_TEXT;
        DOC_POSITION_INITIALIZE.PositionInfo.PC_APPLTXT_ID      := null;
      end if;
    end if;

    close crTmpPosInfo;
  end InitPosition_110;

  /**
  *  procedure InitPosition_115
  *  Description
  *    Création - Bien en corrélation
  */
  procedure InitPosition_115
  is
  begin
    -- L'initialisation du 115 est actuellement la même que celle du 110
    DOC_POSITION_INITIALIZE.InitPosition_110;
  end InitPosition_115;

  /**
  *  procedure InitPosition_117
  *  Description
  *    Création - Emballage
  */
  procedure InitPosition_117
  is
  begin
    null;
  end InitPosition_117;

  /**
  *  procedure InitPosition_118
  *  Description
  *    Création - Litiges
  */
  procedure InitPosition_118
  is
    cursor crPos(cLitigID in DOC_LITIG.DOC_LITIG_ID%type)
    is
      select POS.*
        from DOC_POSITION POS
           , (select max(PDE.DOC_POSITION_ID) DOC_POSITION_ID
                from DOC_POSITION_DETAIL PDE
                   , DOC_LITIG DLG
               where PDE.DOC_POSITION_DETAIL_ID = DLG.DOC_POSITION_DETAIL_ID
                 and DLG.DOC_LITIG_ID = cLitigID) DLG
       where POS.DOC_POSITION_ID = DLG.DOC_POSITION_ID;

    tplPos crPos%rowtype;
  begin
    if PositionInfo.DOC_LITIG_ID is not null then
      -- Rechercher l'id du gabarit position de type litige
      select max(GAP.DOC_GAUGE_POSITION_ID)
        into PositionInfo.DOC_GAUGE_POSITION_ID
        from DOC_DOCUMENT DMT
           , DOC_GAUGE_POSITION GAP
       where DMT.DOC_DOCUMENT_ID = PositionInfo.DOC_DOCUMENT_ID
         and DMT.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
         and GAP.GAP_DEFAULT = 1
         and GAP.C_GAUGE_TYPE_POS = '21';

      -- Initialisation des données, si gabarit de type litige identifié
      --if PositionInfo.DOC_GAUGE_POSITION_ID is not null then
      open crPos(PositionInfo.DOC_LITIG_ID);

      fetch crPos
       into tplPos;

      if crPos%found then
        PositionInfo.C_GAUGE_TYPE_POS               := '21';
        PositionInfo.GCO_GOOD_ID                    := tplPos.GCO_GOOD_ID;
        PositionInfo.USE_ACS_TAX_CODE_ID            := 1;
        PositionInfo.ACS_TAX_CODE_ID                := tplPos.ACS_TAX_CODE_ID;
        PositionInfo.USE_STOCK                      := 1;
        PositionInfo.STM_STOCK_ID                   := tplPos.STM_STOCK_ID;
        PositionInfo.STM_LOCATION_ID                := tplPos.STM_LOCATION_ID;
        PositionInfo.USE_TRANSFERT_STOCK            := 1;
        PositionInfo.STM_STM_STOCK_ID               := tplPos.STM_STM_STOCK_ID;
        PositionInfo.STM_STM_LOCATION_ID            := tplPos.STM_STM_LOCATION_ID;
        PositionInfo.USE_DOC_RECORD_ID              := 1;
        PositionInfo.DOC_RECORD_ID                  := tplPos.DOC_RECORD_ID;
        PositionInfo.USE_DOC_DOC_RECORD_ID          := 1;
        PositionInfo.DOC_DOC_RECORD_ID              := tplPos.DOC_DOC_RECORD_ID;
        PositionInfo.USE_ACCOUNTS                   := 1;
        PositionInfo.ACS_FINANCIAL_ACCOUNT_ID       := tplPos.ACS_FINANCIAL_ACCOUNT_ID;
        PositionInfo.ACS_DIVISION_ACCOUNT_ID        := tplPos.ACS_DIVISION_ACCOUNT_ID;
        PositionInfo.ACS_CPN_ACCOUNT_ID             := tplPos.ACS_CPN_ACCOUNT_ID;
        PositionInfo.ACS_PF_ACCOUNT_ID              := tplPos.ACS_PF_ACCOUNT_ID;
        PositionInfo.ACS_PJ_ACCOUNT_ID              := tplPos.ACS_PJ_ACCOUNT_ID;
        PositionInfo.ACS_CDA_ACCOUNT_ID             := tplPos.ACS_CDA_ACCOUNT_ID;
        PositionInfo.USE_HRM_PERSON_ID              := 1;
        PositionInfo.HRM_PERSON_ID                  := tplPos.HRM_PERSON_ID;
        PositionInfo.USE_FAM_FIXED_ASSETS_ID        := 1;
        PositionInfo.FAM_FIXED_ASSETS_ID            := tplPos.FAM_FIXED_ASSETS_ID;
        PositionInfo.USE_C_FAM_TRANSACTION_TYP      := 1;
        PositionInfo.C_FAM_TRANSACTION_TYP          := tplPos.C_FAM_TRANSACTION_TYP;
        PositionInfo.USE_POS_IMF_TEXT               := 1;
        PositionInfo.POS_IMF_TEXT_1                 := tplPos.POS_IMF_TEXT_1;
        PositionInfo.POS_IMF_TEXT_2                 := tplPos.POS_IMF_TEXT_2;
        PositionInfo.POS_IMF_TEXT_3                 := tplPos.POS_IMF_TEXT_3;
        PositionInfo.POS_IMF_TEXT_4                 := tplPos.POS_IMF_TEXT_4;
        PositionInfo.POS_IMF_TEXT_5                 := tplPos.POS_IMF_TEXT_5;
        PositionInfo.USE_POS_IMF_NUMBER             := 1;
        PositionInfo.POS_IMF_NUMBER_2               := tplPos.POS_IMF_NUMBER_2;
        PositionInfo.POS_IMF_NUMBER_3               := tplPos.POS_IMF_NUMBER_3;
        PositionInfo.POS_IMF_NUMBER_4               := tplPos.POS_IMF_NUMBER_4;
        PositionInfo.POS_IMF_NUMBER_5               := tplPos.POS_IMF_NUMBER_5;
        PositionInfo.USE_DIC_IMP_FREE               := 1;
        PositionInfo.DIC_IMP_FREE1_ID               := tplPos.DIC_IMP_FREE1_ID;
        PositionInfo.DIC_IMP_FREE2_ID               := tplPos.DIC_IMP_FREE2_ID;
        PositionInfo.DIC_IMP_FREE3_ID               := tplPos.DIC_IMP_FREE3_ID;
        PositionInfo.DIC_IMP_FREE4_ID               := tplPos.DIC_IMP_FREE4_ID;
        PositionInfo.DIC_IMP_FREE5_ID               := tplPos.DIC_IMP_FREE5_ID;
        PositionInfo.USE_POS_REFERENCE              := 1;
        PositionInfo.POS_REFERENCE                  := tplPos.POS_REFERENCE;
        -- Recupérer le texte du dico de litige pour la réf. secondaire
        PositionInfo.USE_POS_SECONDARY_REFERENCE    := 1;

        begin
          select substr(DIT.DIT_DESCR, 1, 50)
            into PositionInfo.POS_SECONDARY_REFERENCE
            from DOC_LITIG DLG
               , DOC_POSITION_DETAIL PDE
               , DICO_DESCRIPTION DIT
               , DOC_DOCUMENT DMT
           where DMT.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
             and PDE.DOC_POSITION_DETAIL_ID = DLG.DOC_POSITION_DETAIL_ID
             and DLG.DOC_LITIG_ID = PositionInfo.DOC_LITIG_ID
             and DIT.DIT_TABLE = 'DIC_LITIG_TYPE'
             and DLG.DIC_LITIG_TYPE_ID = DIT.DIT_CODE
             and DIT.PC_LANG_ID = DMT.PC_LANG_ID;
        exception
          when no_data_found then
            PositionInfo.POS_SECONDARY_REFERENCE  := tplPos.POS_SECONDARY_REFERENCE;
        end;

        PositionInfo.USE_POS_SHORT_DESCRIPTION      := 1;
        PositionInfo.POS_SHORT_DESCRIPTION          := tplPos.POS_SHORT_DESCRIPTION;
        PositionInfo.USE_POS_LONG_DESCRIPTION       := 1;
        PositionInfo.POS_LONG_DESCRIPTION           := tplPos.POS_LONG_DESCRIPTION;
        PositionInfo.USE_POS_FREE_DESCRIPTION       := 1;
        PositionInfo.POS_FREE_DESCRIPTION           := tplPos.POS_FREE_DESCRIPTION;
        PositionInfo.USE_POS_EAN_CODE               := 1;
        PositionInfo.POS_EAN_CODE                   := tplPos.POS_EAN_CODE;
        PositionInfo.USE_POS_EAN_UCC14_CODE         := 1;
        PositionInfo.POS_EAN_UCC14_CODE             := tplPos.POS_EAN_UCC14_CODE;
        PositionInfo.USE_POS_HIBC_PRIMARY_CODE      := 1;
        PositionInfo.POS_HIBC_PRIMARY_CODE          := tplPos.POS_HIBC_PRIMARY_CODE;
        PositionInfo.USE_POS_BODY_TEXT              := 1;
        PositionInfo.POS_BODY_TEXT                  := tplPos.POS_BODY_TEXT;
        PositionInfo.PC_APPLTXT_ID                  := tplPos.PC_APPLTXT_ID;
        PositionInfo.USE_DIC_UNIT_OF_MEASURE_ID     := 1;
        PositionInfo.DIC_UNIT_OF_MEASURE_ID         := tplPos.DIC_UNIT_OF_MEASURE_ID;
        PositionInfo.USE_POS_NOM_TEXT               := 1;
        PositionInfo.POS_NOM_TEXT                   := tplPos.POS_NOM_TEXT;
        PositionInfo.USE_DIC_POS_FREE_TABLE         := 1;
        PositionInfo.DIC_POS_FREE_TABLE_1_ID        := tplPos.DIC_POS_FREE_TABLE_1_ID;
        PositionInfo.DIC_POS_FREE_TABLE_2_ID        := tplPos.DIC_POS_FREE_TABLE_2_ID;
        PositionInfo.DIC_POS_FREE_TABLE_3_ID        := tplPos.DIC_POS_FREE_TABLE_3_ID;
        PositionInfo.USE_POS_DECIMAL                := 1;
        PositionInfo.POS_DECIMAL_1                  := tplPos.POS_DECIMAL_1;
        PositionInfo.POS_DECIMAL_2                  := tplPos.POS_DECIMAL_2;
        PositionInfo.POS_DECIMAL_3                  := tplPos.POS_DECIMAL_3;
        PositionInfo.USE_POS_TEXT                   := 1;
        PositionInfo.POS_TEXT_1                     := tplPos.POS_TEXT_1;
        PositionInfo.POS_TEXT_2                     := tplPos.POS_TEXT_2;
        PositionInfo.POS_TEXT_3                     := tplPos.POS_TEXT_3;
        PositionInfo.USE_POS_DATE                   := 1;
        PositionInfo.POS_DATE_1                     := tplPos.POS_DATE_1;
        PositionInfo.POS_DATE_2                     := tplPos.POS_DATE_2;
        PositionInfo.POS_DATE_3                     := tplPos.POS_DATE_3;
        PositionInfo.USE_PAC_REPRESENTATIVE_ID      := 1;
        PositionInfo.PAC_REPRESENTATIVE_ID          := tplPos.PAC_REPRESENTATIVE_ID;
        PositionInfo.USE_PAC_REPR_ACI_ID            := 1;
        PositionInfo.PAC_REPR_ACI_ID                := tplPos.PAC_REPR_ACI_ID;
        PositionInfo.USE_PAC_REPR_DELIVERY_ID       := 1;
        PositionInfo.PAC_REPR_DELIVERY_ID           := tplPos.PAC_REPR_DELIVERY_ID;
        PositionInfo.USE_CML_POSITION_ID            := 1;
        PositionInfo.CML_POSITION_ID                := tplPos.CML_POSITION_ID;
        PositionInfo.USE_CML_EVENTS_ID              := 1;
        PositionInfo.CML_EVENTS_ID                  := tplPos.CML_EVENTS_ID;
        PositionInfo.USE_ASA_RECORD_ID              := 1;
        PositionInfo.ASA_RECORD_ID                  := tplPos.ASA_RECORD_ID;
        PositionInfo.USE_ASA_RECORD_COMP_ID         := 1;
        PositionInfo.ASA_RECORD_COMP_ID             := tplPos.ASA_RECORD_COMP_ID;
        PositionInfo.USE_ASA_RECORD_TASK_ID         := 1;
        PositionInfo.ASA_RECORD_TASK_ID             := tplPos.ASA_RECORD_TASK_ID;
        PositionInfo.USE_FAL_SUPPLY_REQUEST_ID      := 1;
        PositionInfo.FAL_SUPPLY_REQUEST_ID          := tplPos.FAL_SUPPLY_REQUEST_ID;
        PositionInfo.USE_PAC_PERSON_ID              := 1;
        PositionInfo.PAC_PERSON_ID                  := tplPos.PAC_PERSON_ID;
        PositionInfo.USE_C_POS_DELIVERY_TYP         := 1;
        PositionInfo.C_POS_DELIVERY_TYP             := tplPos.C_POS_DELIVERY_TYP;
        PositionInfo.USE_POS_RATE_FACTOR            := 1;
        PositionInfo.POS_RATE_FACTOR                := tplPos.POS_RATE_FACTOR;
        PositionInfo.USE_GOOD_PRICE                 := 1;

        begin
          select DLG_UNIT_VALUE
            into PositionInfo.GOOD_PRICE
            from DOC_LITIG
           where DOC_LITIG_ID = PositionInfo.DOC_LITIG_ID;
        exception
          when no_data_found then
            PositionInfo.GOOD_PRICE  := tplPos.POS_GROSS_UNIT_VALUE;
        end;

        PositionInfo.GOOD_PRICE                     := nvl(PositionInfo.GOOD_PRICE, tplPos.POS_GROSS_UNIT_VALUE);
        PositionInfo.USE_POS_NET_TARIFF             := 1;
        PositionInfo.POS_NET_TARIFF                 := tplPos.POS_NET_TARIFF;
        PositionInfo.USE_POS_SPECIAL_TARIFF         := 1;
        PositionInfo.POS_SPECIAL_TARIFF             := tplPos.POS_SPECIAL_TARIFF;
        PositionInfo.USE_POS_FLAT_RATE              := 1;
        PositionInfo.POS_FLAT_RATE                  := tplPos.POS_FLAT_RATE;
        PositionInfo.USE_POS_TARIFF_UNIT            := 1;
        PositionInfo.POS_TARIFF_UNIT                := tplPos.POS_TARIFF_UNIT;
        PositionInfo.USE_POS_TARIFF_SET             := 1;
        PositionInfo.POS_TARIFF_SET                 := tplPos.POS_TARIFF_SET;
        PositionInfo.USE_POS_DISCOUNT_RATE          := 1;
        PositionInfo.POS_DISCOUNT_RATE              := tplPos.POS_DISCOUNT_RATE;
        PositionInfo.USE_POS_DISCOUNT_UNIT_VALUE    := 1;
        PositionInfo.POS_DISCOUNT_UNIT_VALUE        := tplPos.POS_DISCOUNT_UNIT_VALUE;
        PositionInfo.USE_POS_WEIGHT                 := 1;
        PositionInfo.POS_NET_WEIGHT                 := tplPos.POS_NET_WEIGHT;
        PositionInfo.POS_GROSS_WEIGHT               := tplPos.POS_GROSS_WEIGHT;
        PositionInfo.USE_POS_UTIL_COEFF             := 1;
        PositionInfo.POS_UTIL_COEFF                 := tplPos.POS_UTIL_COEFF;
        PositionInfo.USE_POS_CONVERT_FACTOR         := 1;
        PositionInfo.POS_CONVERT_FACTOR             := tplPos.POS_CONVERT_FACTOR;
        PositionInfo.POS_CONVERT_FACTOR2            := tplPos.POS_CONVERT_FACTOR2;
        PositionInfo.USE_POS_PARTNER_NUMBER         := 1;
        PositionInfo.POS_PARTNER_NUMBER             := tplPos.POS_PARTNER_NUMBER;
        PositionInfo.USE_POS_PARTNER_REFERENCE      := 1;
        PositionInfo.POS_PARTNER_REFERENCE          := tplPos.POS_PARTNER_REFERENCE;
        PositionInfo.USE_POS_DATE_PARTNER_DOCUMENT  := 1;
        PositionInfo.POS_DATE_PARTNER_DOCUMENT      := tplPos.POS_DATE_PARTNER_DOCUMENT;
        PositionInfo.USE_POS_PARTNER_POS_NUMBER     := 1;
        PositionInfo.POS_PARTNER_POS_NUMBER         := tplPos.POS_PARTNER_POS_NUMBER;
        PositionInfo.DIC_TARIFF_ID                  := tplPos.DIC_TARIFF_ID;
        PositionInfo.USE_POS_TARIFF_DATE            := 1;
        PositionInfo.POS_TARIFF_DATE                := tplPos.POS_TARIFF_DATE;
        PositionInfo.USE_POS_UNIT_COST_PRICE        := 1;
        PositionInfo.POS_UNIT_COST_PRICE            := tplPos.POS_UNIT_COST_PRICE;
      end if;

      close crPos;
    --  end if;
    end if;
  end InitPosition_118;

  /**
  *  procedure InitPosition_120
  *  Description
  *    Création - Génération des cmds Sous-traitance
  */
  procedure InitPosition_120
  is
  begin
    null;
  end InitPosition_120;

  /**
  *  procedure InitPosition_121
  *  Description
  *    Création - Factures de débours
  */
  procedure InitPosition_121
  is
    lnACS_CDA_ACCOUNT_ID number;
  begin
    select ACS_CDA_ACCOUNT_ID
      into lnACS_CDA_ACCOUNT_ID
      from SCH_BILL_POSITION POS
     where SCH_BILL_POSITION_ID = DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID;

    PositionInfo.ACS_CDA_ACCOUNT_ID  := nvl(lnACS_CDA_ACCOUNT_ID, PositionInfo.ACS_CDA_ACCOUNT_ID);
    PositionInfo.USE_ACCOUNTS        := 1;
  exception
    when others then
      null;
  end InitPosition_121;

  /**
  *  procedure InitPosition_122
  *  Description
  *    Création - Factures d'écolages
  */
  procedure InitPosition_122
  is
  begin
    null;
  end InitPosition_122;

  /**
  *  procedure InitPosition_123
  *  Description
  *    Création - Sous-traitance d'achat
  */
  procedure InitPosition_123
  is
    vQty DOC_POSITION.POS_BASIS_QUANTITY%type;
  begin
    -- Recuperer le produit fabriqué de la donnée compl de sous-traitance
    -- si l'id donnée compl passé en param
    if (DOC_POSITION_INITIALIZE.PositionInfo.GCO_COMPL_DATA_ID is not null) then
      begin
        select GCO_GOOD_ID
             , GCO_GCO_GOOD_ID
             , CSU_LOT_QUANTITY
          into DOC_POSITION_INITIALIZE.PositionInfo.GCO_MANUFACTURED_GOOD_ID
             , DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID
             , vQty
          from GCO_COMPL_DATA_SUBCONTRACT
         where GCO_COMPL_DATA_SUBCONTRACT_ID = DOC_POSITION_INITIALIZE.PositionInfo.GCO_COMPL_DATA_ID;

        -- Utiliser la qté économique de la donnée compl. si la qté pas passée en param
        if DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY = 0 then
          DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY  := 1;
          DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY      := vQty;
        end if;
      exception
        when no_data_found then
          null;
      end;
    end if;
  end InitPosition_123;

  /**
  *  procedure InitPosition_124
  *  Description
  *    Création - Sous-traitance d'achat - BLST/BLRST
  */
  procedure InitPosition_124
  is
  begin
    null;
  end InitPosition_124;

  /**
  *  procedure InitPosition_125
  *  Description
  *    Création - Gestion des commandes cadre
  */
  procedure InitPosition_125
  is
    cursor crPos(cPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    is
      select *
        from DOC_POSITION
       where DOC_POSITION_ID = cPositionID;

    tplPos crPos%rowtype;
  begin
    open crPos(DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID);

    fetch crPos
     into tplPos;

    if crPos%found then
      DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_POSITION_ID          := tplPos.DOC_GAUGE_POSITION_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID                    := tplPos.GCO_GOOD_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_ACS_TAX_CODE_ID            := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.ACS_TAX_CODE_ID                := tplPos.ACS_TAX_CODE_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_STOCK                      := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.STM_STOCK_ID                   := tplPos.STM_STOCK_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.STM_LOCATION_ID                := tplPos.STM_LOCATION_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_TRANSFERT_STOCK            := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_STOCK_ID               := tplPos.STM_STM_STOCK_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_LOCATION_ID            := tplPos.STM_STM_LOCATION_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_DOC_RECORD_ID              := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.DOC_RECORD_ID                  := tplPos.DOC_RECORD_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_DOC_DOC_RECORD_ID          := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOC_RECORD_ID              := tplPos.DOC_DOC_RECORD_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_ACCOUNTS                   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.ACS_FINANCIAL_ACCOUNT_ID       := tplPos.ACS_FINANCIAL_ACCOUNT_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.ACS_DIVISION_ACCOUNT_ID        := tplPos.ACS_DIVISION_ACCOUNT_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.ACS_CPN_ACCOUNT_ID             := tplPos.ACS_CPN_ACCOUNT_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.ACS_PF_ACCOUNT_ID              := tplPos.ACS_PF_ACCOUNT_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.ACS_PJ_ACCOUNT_ID              := tplPos.ACS_PJ_ACCOUNT_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.ACS_CDA_ACCOUNT_ID             := tplPos.ACS_CDA_ACCOUNT_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_HRM_PERSON_ID              := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.HRM_PERSON_ID                  := tplPos.HRM_PERSON_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_FAM_FIXED_ASSETS_ID        := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.FAM_FIXED_ASSETS_ID            := tplPos.FAM_FIXED_ASSETS_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_C_FAM_TRANSACTION_TYP      := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.C_FAM_TRANSACTION_TYP          := tplPos.C_FAM_TRANSACTION_TYP;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_IMF_TEXT               := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_IMF_TEXT_1                 := tplPos.POS_IMF_TEXT_1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_IMF_TEXT_2                 := tplPos.POS_IMF_TEXT_2;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_IMF_TEXT_3                 := tplPos.POS_IMF_TEXT_3;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_IMF_TEXT_4                 := tplPos.POS_IMF_TEXT_4;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_IMF_TEXT_5                 := tplPos.POS_IMF_TEXT_5;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_IMF_NUMBER             := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_IMF_NUMBER_2               := tplPos.POS_IMF_NUMBER_2;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_IMF_NUMBER_3               := tplPos.POS_IMF_NUMBER_3;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_IMF_NUMBER_4               := tplPos.POS_IMF_NUMBER_4;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_IMF_NUMBER_5               := tplPos.POS_IMF_NUMBER_5;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_DIC_IMP_FREE               := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.DIC_IMP_FREE1_ID               := tplPos.DIC_IMP_FREE1_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.DIC_IMP_FREE2_ID               := tplPos.DIC_IMP_FREE2_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.DIC_IMP_FREE3_ID               := tplPos.DIC_IMP_FREE3_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.DIC_IMP_FREE4_ID               := tplPos.DIC_IMP_FREE4_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.DIC_IMP_FREE5_ID               := tplPos.DIC_IMP_FREE5_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_REFERENCE              := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_REFERENCE                  := tplPos.POS_REFERENCE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SECONDARY_REFERENCE    := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_SECONDARY_REFERENCE        := tplPos.POS_SECONDARY_REFERENCE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SHORT_DESCRIPTION      := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_SHORT_DESCRIPTION          := tplPos.POS_SHORT_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION       := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION           := tplPos.POS_LONG_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION       := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION           := tplPos.POS_FREE_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_EAN_CODE               := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_EAN_CODE                   := tplPos.POS_EAN_CODE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_EAN_UCC14_CODE         := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_EAN_UCC14_CODE             := tplPos.POS_EAN_UCC14_CODE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_HIBC_PRIMARY_CODE      := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_HIBC_PRIMARY_CODE          := tplPos.POS_HIBC_PRIMARY_CODE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT              := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT                  := tplPos.POS_BODY_TEXT;
      DOC_POSITION_INITIALIZE.PositionInfo.PC_APPLTXT_ID                  := tplPos.PC_APPLTXT_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_DIC_UNIT_OF_MEASURE_ID     := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.DIC_UNIT_OF_MEASURE_ID         := tplPos.DIC_UNIT_OF_MEASURE_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_NOM_TEXT               := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_NOM_TEXT                   := tplPos.POS_NOM_TEXT;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_DIC_POS_FREE_TABLE         := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.DIC_POS_FREE_TABLE_1_ID        := tplPos.DIC_POS_FREE_TABLE_1_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.DIC_POS_FREE_TABLE_2_ID        := tplPos.DIC_POS_FREE_TABLE_2_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.DIC_POS_FREE_TABLE_3_ID        := tplPos.DIC_POS_FREE_TABLE_3_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DECIMAL                := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_DECIMAL_1                  := tplPos.POS_DECIMAL_1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_DECIMAL_2                  := tplPos.POS_DECIMAL_2;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_DECIMAL_3                  := tplPos.POS_DECIMAL_3;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_TEXT                   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_TEXT_1                     := tplPos.POS_TEXT_1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_TEXT_2                     := tplPos.POS_TEXT_2;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_TEXT_3                     := tplPos.POS_TEXT_3;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DATE                   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_DATE_1                     := tplPos.POS_DATE_1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_DATE_2                     := tplPos.POS_DATE_2;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_DATE_3                     := tplPos.POS_DATE_3;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPRESENTATIVE_ID      := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPRESENTATIVE_ID          := tplPos.PAC_REPRESENTATIVE_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPR_ACI_ID            := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPR_ACI_ID                := tplPos.PAC_REPR_ACI_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPR_DELIVERY_ID       := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPR_DELIVERY_ID           := tplPos.PAC_REPR_DELIVERY_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID            := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID                := tplPos.CML_POSITION_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_EVENTS_ID              := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.CML_EVENTS_ID                  := tplPos.CML_EVENTS_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_ASA_RECORD_ID              := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.ASA_RECORD_ID                  := tplPos.ASA_RECORD_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_ASA_RECORD_COMP_ID         := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.ASA_RECORD_COMP_ID             := tplPos.ASA_RECORD_COMP_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_ASA_RECORD_TASK_ID         := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.ASA_RECORD_TASK_ID             := tplPos.ASA_RECORD_TASK_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_FAL_SUPPLY_REQUEST_ID      := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.FAL_SUPPLY_REQUEST_ID          := tplPos.FAL_SUPPLY_REQUEST_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_PERSON_ID              := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.PAC_PERSON_ID                  := tplPos.PAC_PERSON_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_C_POS_DELIVERY_TYP         := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.C_POS_DELIVERY_TYP             := tplPos.C_POS_DELIVERY_TYP;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_RATE_FACTOR            := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_RATE_FACTOR                := tplPos.POS_RATE_FACTOR;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_GOOD_PRICE                 := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE                     := tplPos.POS_GROSS_UNIT_VALUE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_NET_TARIFF             := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_NET_TARIFF                 := tplPos.POS_NET_TARIFF;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SPECIAL_TARIFF         := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_SPECIAL_TARIFF             := tplPos.POS_SPECIAL_TARIFF;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FLAT_RATE              := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_FLAT_RATE                  := tplPos.POS_FLAT_RATE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_TARIFF_UNIT            := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_TARIFF_UNIT                := tplPos.POS_TARIFF_UNIT;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_TARIFF_SET             := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_TARIFF_SET                 := tplPos.POS_TARIFF_SET;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DISCOUNT_RATE          := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_DISCOUNT_RATE              := tplPos.POS_DISCOUNT_RATE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DISCOUNT_UNIT_VALUE    := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_DISCOUNT_UNIT_VALUE        := tplPos.POS_DISCOUNT_UNIT_VALUE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_WEIGHT                 := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_NET_WEIGHT                 := tplPos.POS_NET_WEIGHT;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_GROSS_WEIGHT               := tplPos.POS_GROSS_WEIGHT;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UTIL_COEFF             := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_UTIL_COEFF                 := tplPos.POS_UTIL_COEFF;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_CONVERT_FACTOR         := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_CONVERT_FACTOR             := tplPos.POS_CONVERT_FACTOR;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_CONVERT_FACTOR2            := tplPos.POS_CONVERT_FACTOR2;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_PARTNER_NUMBER         := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_PARTNER_NUMBER             := tplPos.POS_PARTNER_NUMBER;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_PARTNER_REFERENCE      := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_PARTNER_REFERENCE          := tplPos.POS_PARTNER_REFERENCE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DATE_PARTNER_DOCUMENT  := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_DATE_PARTNER_DOCUMENT      := tplPos.POS_DATE_PARTNER_DOCUMENT;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_PARTNER_POS_NUMBER     := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_PARTNER_POS_NUMBER         := tplPos.POS_PARTNER_POS_NUMBER;
      DOC_POSITION_INITIALIZE.PositionInfo.DIC_TARIFF_ID                  := tplPos.DIC_TARIFF_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_TARIFF_DATE            := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_TARIFF_DATE                := tplPos.POS_TARIFF_DATE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UNIT_COST_PRICE        := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_UNIT_COST_PRICE            := tplPos.POS_UNIT_COST_PRICE;
    end if;

    close crPos;
  end InitPosition_125;

  /**
  *  procedure InitPosition_126
  *  Description
  *    Création - Devis - Offre client
  *  @created ngv
  *  @public
  */
  procedure InitPosition_126
  is
    cursor lcrPos(cEstimatePosID in number)
    is
      select DEP.GCO_GOOD_ID
           , DEP.DIC_UNIT_OF_MEASURE_ID
           , DEP.DEP_REFERENCE
           , DEP.DEP_SECONDARY_REFERENCE
           , DEP.DEP_SHORT_DESCRIPTION
           , DEP.DEP_LONG_DESCRIPTION
           , DEP.DEP_FREE_DESCRIPTION
           , DEP.C_DOC_ESTIMATE_CREATE_MODE
           , DEP.STM_STOCK_ID
           , DEP.STM_LOCATION_ID
           , nvl(dec.DEC_QUANTITY, 0) DEC_QUANTITY
           , nvl(dec.DEC_SALE_PRICE_CORR, 0) DEC_SALE_PRICE_CORR
           , DES.ACS_FINANCIAL_CURRENCY_ID
           , ACS_FUNCTION.GetLocalCurrencyId as LOCAL_CURRENCY
        from DOC_ESTIMATE_POS DEP
           , DOC_ESTIMATE_ELEMENT_COST dec
           , DOC_ESTIMATE DES
       where DEP.DOC_ESTIMATE_POS_ID = cEstimatePosID
         and DES.DOC_ESTIMATE_ID = DEP.DOC_ESTIMATE_ID
         and DEP.DOC_ESTIMATE_POS_ID = dec.DOC_ESTIMATE_POS_ID
         and dec.DOC_ESTIMATE_ELEMENT_ID is null;

    ltplPos          lcrPos%rowtype;
    bidon            DOC_POSITION.POS_NET_VALUE_EXCL_E%type;
    ldDocumentDate   DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    lnRateOfExchange DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    lnBasePrice      DOC_DOCUMENT.DMT_BASE_PRICE%type;
    lnPrice          DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
  begin
    open lcrPos(DOC_POSITION_INITIALIZE.PositionInfo.SOURCE_DOC_POSITION_ID);

    fetch lcrPos
     into ltplPos;

    if lcrPos%found then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY       := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY           := ltplPos.DEC_QUANTITY;

      -- Utiliser le bien créé (l'id du bien n'est pas màj sur le devis )
      if (ltplPos.C_DOC_ESTIMATE_CREATE_MODE in('01', '02') ) then
        DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', ltplPos.DEP_REFERENCE);
      end if;

      -- Si le bien n'est pas défini (produit pas créé)
      if DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID is null then
        -- Utiliser l'id du bien spécifié sur le devis et si null utiliser l'id du bien virtuel
        DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID  :=
                     nvl(ltplPos.GCO_GOOD_ID, FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GOOD') ) );
      end if;

      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_REFERENCE            := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_REFERENCE                := ltplPos.DEP_REFERENCE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SECONDARY_REFERENCE  := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_SECONDARY_REFERENCE      := ltplPos.DEP_SECONDARY_REFERENCE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_REFERENCE            := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_REFERENCE                := ltplPos.DEP_REFERENCE;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SHORT_DESCRIPTION    := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_SHORT_DESCRIPTION        := ltplPos.DEP_SHORT_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION     := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION         := ltplPos.DEP_FREE_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION     := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION         := ltplPos.DEP_LONG_DESCRIPTION;

      -- Unité de mesure
      if ltplPos.DIC_UNIT_OF_MEASURE_ID is not null then
        PositionInfo.USE_DIC_UNIT_OF_MEASURE_ID  := 1;
        PositionInfo.DIC_UNIT_OF_MEASURE_ID      := ltplPos.DIC_UNIT_OF_MEASURE_ID;
      end if;

      -- En mode création de bien dans les devis, le bien n'existe pas encore
      -- lors de la génération de l'offre.
      -- Il y a certaines données du devis à utiliser
      if     (ltplPos.C_DOC_ESTIMATE_CREATE_MODE = '01')
         and (ltplPos.STM_STOCK_ID is not null)
         and (ltplPos.STM_LOCATION_ID is not null) then
        -- Stock et Emplacement
        DOC_POSITION_INITIALIZE.PositionInfo.USE_STOCK        := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_STOCK_ID     := ltplPos.STM_STOCK_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_LOCATION_ID  := ltplPos.STM_LOCATION_ID;
      end if;

      DOC_POSITION_INITIALIZE.PositionInfo.USE_GOOD_PRICE               := 1;

      -- Prix unitaire = prix de vente corrigé divisé par la qté de la position du devis
      if ltplPos.DEC_QUANTITY = 0 then
        lnPrice  := ltplPos.DEC_SALE_PRICE_CORR;
      else
        lnPrice  := ltplPos.DEC_SALE_PRICE_CORR / ltplPos.DEC_QUANTITY;
      end if;

      if ltplPos.ACS_FINANCIAL_CURRENCY_ID = ltplPos.LOCAL_CURRENCY then
        DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE  := lnPrice;
      else
        -- Conversion du montant si la Monnaie définie sur l'entête de devis n'est pas la monnaie de base
        select DMT_DATE_DOCUMENT
             , DMT_RATE_OF_EXCHANGE
             , DMT_BASE_PRICE
          into ldDocumentDate
             , lnRateOfExchange
             , lnBasePrice
          from DOC_DOCUMENT
         where DOC_DOCUMENT_ID = DOC_POSITION_INITIALIZE.PositionInfo.DOC_DOCUMENT_ID;

        ACS_FUNCTION.ConvertAmount(lnPrice
                                 , ltplPos.LOCAL_CURRENCY
                                 , ltplPos.ACS_FINANCIAL_CURRENCY_ID
                                 , ldDocumentDate
                                 , lnRateOfExchange
                                 , lnBasePrice
                                 , 0
                                 , bidon
                                 , DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE
                                  );
      end if;
    end if;

    close lcrPos;
  end InitPosition_126;

  /**
  *  procedure InitPosition_127
  *  Description
  *    Création - Devis - Commande client
  *  @created ngv
  *  @public
  */
  procedure InitPosition_127
  is
  begin
    -- Devis simplifié
    -- Pour le moment, l'init de la commande client est la même que l'offre
    InitPosition_126;
  end InitPosition_127;

  /**
  *  procedure InitPosition_130
  *  Description
  *    Création - DRP (Demande de réapprovisionement)
  */
  procedure InitPosition_130
  is
  begin
    null;
  end InitPosition_130;

  /**
  *  procedure InitPosition_131
  *  Description
  *    Création - Traitement des lots périmés / refusés
  *  @created ngv
  *  @public
  */
  procedure InitPosition_131
  is
  begin
    null;
  end InitPosition_131;

  /**
  *  procedure InitPosition_135
  *  Description
  *    Création - Reprise des POA
  */
  procedure InitPosition_135
  is
  begin
    PositionInfo.USE_FAL_SUPPLY_REQUEST_ID  := 1;
    PositionInfo.FAL_SUPPLY_REQUEST_ID      := PositionInfo.SOURCE_DOC_POSITION_ID;
    PositionInfo.SOURCE_DOC_POSITION_ID     := null;
  end InitPosition_135;

  /**
  *  procedure InitPosition_137
  *  Description
  *    Création - Demandes de consultations
  */
  procedure InitPosition_137
  is
    cursor crConsultInfo(aConsultID FAL_DOC_CONSULT.FAL_DOC_CONSULT_ID%type)
    is
      select FDC.DIC_UNIT_OF_MEASURE_ID
           , FDC.FDC_PARTNER_NUMBER
           , FDC.FDC_PARTNER_REFERENCE
           , FDC.FDC_DATE_PARTNER_DOCUMENT
           , FDC.FDC_PARTNER_POS_NUMBER
           , FDP.FAL_SUPPLY_REQUEST_ID
           , FDC.GCO_GOOD_ID
           , FDC.GCO2_GOOD_ID
           , FDC.PAC_SUPPLIER_PARTNER_ID
           , FDC.PAC2_SUPPLIER_PARTNER_ID
        from FAL_DOC_CONSULT FDC
           , FAL_DOC_PROP FDP
       where FDC.FAL_DOC_CONSULT_ID = aConsultID
         and FDC.FAL_DOC_PROP_ID = FDP.FAL_DOC_PROP_ID(+);

    tplConsultInfo               crConsultInfo%rowtype;
    vCPU_CONTROL_DELAY           GCO_COMPL_DATA_PURCHASE.CPU_CONTROL_DELAY%type;
    vCPU_SUPPLY_DELAY            GCO_COMPL_DATA_PURCHASE.CPU_SUPPLY_DELAY%type;
    vCDA_COMPLEMENTARY_REFERENCE GCO_COMPL_DATA_PURCHASE.CDA_COMPLEMENTARY_REFERENCE%type;
    vCDA_SHORT_DESCRIPTION       GCO_COMPL_DATA_PURCHASE.CDA_SHORT_DESCRIPTION%type;
    vCDA_LONG_DESCRIPTION        GCO_COMPL_DATA_PURCHASE.CDA_LONG_DESCRIPTION%type;
    vCDA_FREE_DESCRIPTION        GCO_COMPL_DATA_PURCHASE.CDA_FREE_DESCRIPTION%type;
    vCDA_COMPLEMENTARY_EAN_CODE  GCO_COMPL_DATA_PURCHASE.CDA_COMPLEMENTARY_EAN_CODE%type;
  begin
    -- Recherche des infos concernant le
    open crConsultInfo(PositionInfo.SOURCE_DOC_POSITION_ID);

    fetch crConsultInfo
     into tplConsultInfo;

    if crConsultInfo%found then
      -- Unité de mesure
      if tplConsultInfo.DIC_UNIT_OF_MEASURE_ID is not null then
        PositionInfo.USE_DIC_UNIT_OF_MEASURE_ID  := 1;
        PositionInfo.DIC_UNIT_OF_MEASURE_ID      := tplConsultInfo.DIC_UNIT_OF_MEASURE_ID;
      end if;

      -- Numéro du document partenaire
      if tplConsultInfo.FDC_PARTNER_NUMBER is not null then
        PositionInfo.USE_POS_PARTNER_NUMBER  := 1;
        PositionInfo.POS_PARTNER_NUMBER      := tplConsultInfo.FDC_PARTNER_NUMBER;
      end if;

      -- Référence du document partenaire
      if tplConsultInfo.FDC_PARTNER_REFERENCE is not null then
        PositionInfo.USE_POS_PARTNER_REFERENCE  := 1;
        PositionInfo.POS_PARTNER_REFERENCE      := tplConsultInfo.FDC_PARTNER_REFERENCE;
      end if;

      -- Date du document partenaire
      if tplConsultInfo.FDC_DATE_PARTNER_DOCUMENT is not null then
        PositionInfo.USE_POS_DATE_PARTNER_DOCUMENT  := 1;
        PositionInfo.POS_DATE_PARTNER_DOCUMENT      := tplConsultInfo.FDC_DATE_PARTNER_DOCUMENT;
      end if;

      -- Numéro de position du document partenaire
      if tplConsultInfo.FDC_PARTNER_POS_NUMBER is not null then
        PositionInfo.USE_POS_PARTNER_POS_NUMBER  := 1;
        PositionInfo.POS_PARTNER_POS_NUMBER      := tplConsultInfo.FDC_PARTNER_POS_NUMBER;
      end if;

      -- Demande d'appro liée
      if tplConsultInfo.FAL_SUPPLY_REQUEST_ID is not null then
        PositionInfo.USE_FAL_SUPPLY_REQUEST_ID  := 1;
        PositionInfo.FAL_SUPPLY_REQUEST_ID      := tplConsultInfo.FAL_SUPPLY_REQUEST_ID;
      end if;

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
        -- Référence de la donnée complémentaire (conditionne les autres champs)
        if vCDA_COMPLEMENTARY_REFERENCE is not null then
          PositionInfo.USE_POS_REFERENCE  := 1;
          PositionInfo.POS_REFERENCE      := vCDA_COMPLEMENTARY_REFERENCE;

          -- Description courte
          if vCDA_SHORT_DESCRIPTION is not null then
            PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
            PositionInfo.POS_SHORT_DESCRIPTION      := vCDA_SHORT_DESCRIPTION;
          end if;

          -- Description longue
          if vCDA_LONG_DESCRIPTION is not null then
            PositionInfo.USE_POS_LONG_DESCRIPTION  := 1;
            PositionInfo.POS_LONG_DESCRIPTION      := vCDA_LONG_DESCRIPTION;
          end if;

          -- Description libre
          if vCDA_FREE_DESCRIPTION is not null then
            PositionInfo.USE_POS_FREE_DESCRIPTION  := 1;
            PositionInfo.POS_FREE_DESCRIPTION      := vCDA_FREE_DESCRIPTION;
          end if;

          -- Code EAN
          if vCDA_COMPLEMENTARY_EAN_CODE is not null then
            PositionInfo.USE_POS_EAN_CODE  := 1;
            PositionInfo.POS_EAN_CODE      := vCDA_COMPLEMENTARY_EAN_CODE;
          end if;
        end if;
      end if;
    end if;

    close crConsultInfo;

    -- Remise à zéro de l'ID position source
    PositionInfo.SOURCE_DOC_POSITION_ID  := null;
  end InitPosition_137;

  /**
  *  procedure InitPosition_140
  *  Description
  *    Création - Générateur de documents
  */
  procedure InitPosition_140
  is
    cursor crInterfacePosInfo(
      cInterfaceID    in DOC_INTERFACE.DOC_INTERFACE_ID%type
    , cInterfacePosID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
    , cPosNumber      in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
    )
    is
      select   DOC_GAUGE_POSITION_ID
             , C_GAUGE_TYPE_POS
             , GCO_GOOD_ID
             , ACS_TAX_CODE_ID
             , DOP_QTY
             , DOP_QTY_VALUE
             , nvl(DOP_UTIL_COEFF, 1) DOP_UTIL_COEFF
             , C_PRODUCT_DELIVERY_TYP
             , DOP_USE_GOOD_PRICE
             , DOP_GROSS_UNIT_VALUE
             , DOP_GROSS_VALUE
             , DOP_NET_VALUE_EXCL
             , DOP_NET_VALUE_INCL
             , DOP_NET_TARIFF
             , DOP_SPECIAL_TARIFF
             , DOP_TARIFF_DATE
             , DOP_FLAT_RATE
             , DOP_DISCOUNT_RATE
             , STM_STOCK_ID
             , STM_STM_STOCK_ID
             , STM_LOCATION_ID
             , STM_STM_LOCATION_ID
             , DOC_RECORD_ID
             , PAC_REPRESENTATIVE_ID
             , PAC_REPR_ACI_ID
             , PAC_REPR_DELIVERY_ID
             , DOP_SHORT_DESCRIPTION
             , DOP_LONG_DESCRIPTION
             , DOP_FREE_DESCRIPTION
             , PC_APPLTXT_ID
             , DOP_BODY_TEXT
             , DIC_POS_FREE_TABLE_1_ID
             , DIC_POS_FREE_TABLE_2_ID
             , DIC_POS_FREE_TABLE_3_ID
             , DOP_POS_TEXT_1
             , DOP_POS_TEXT_2
             , DOP_POS_TEXT_3
             , DOP_POS_DECIMAL_1
             , DOP_POS_DECIMAL_2
             , DOP_POS_DECIMAL_3
             , DOP_POS_DATE_1
             , DOP_POS_DATE_2
             , DOP_POS_DATE_3
             , DOP_PARTNER_REFERENCE
             , DOP_PARTNER_NUMBER
             , DOP_PARTNER_DATE
             , DOP_PARTNER_POS_NUMBER
             , PPS_NOMENCLATURE_ID
             , DOC_POSITION_PT_ID
             , A_DATECRE
             , A_IDCRE
             , A_DATEMOD
             , A_IDMOD
             , A_RECLEVEL
             , A_RECSTATUS
             , A_CONFIRM
             , DOP.DOP_GROSS_VALUE_EXCL
             , DOP.DOP_VAT_AMOUNT
             , DOP.DOP_VAT_RATE
             , DOP.DOP_GROSS_WEIGHT
             , DOP.DOP_NET_WEIGHT
             , DOP.ACS_FINANCIAL_ACCOUNT_ID
             , DOP.ACS_DIVISION_ACCOUNT_ID
             , DOP.ACS_CPN_ACCOUNT_ID
             , DOP.ACS_CDA_ACCOUNT_ID
             , DOP.ACS_PF_ACCOUNT_ID
             , DOP.ACS_PJ_ACCOUNT_ID
          from DOC_INTERFACE_POSITION DOP
         where DOC_INTERFACE_ID = cInterfaceID
           and (   DOC_INTERFACE_POSITION_ID = cInterfacePosID
                or cInterfacePosID is null)
           and (   DOP_POS_NUMBER = cPosNumber
                or cPosNumber is null)
           and nvl(C_INTERFACE_GEN_MODE, 'INSERT') = 'INSERT'
      order by DOC_INTERFACE_POSITION_ID;

    tplInterfacePosInfo crInterfacePosInfo%rowtype;
  begin
    open crInterfacePosInfo(DOC_POSITION_INITIALIZE.PositionInfo.DOC_INTERFACE_ID
                          , DOC_POSITION_INITIALIZE.PositionInfo.DOC_INTERFACE_POSITION_ID
                          , DOC_POSITION_INITIALIZE.PositionInfo.DOP_POS_NUMBER
                           );

    fetch crInterfacePosInfo
     into tplInterfacePosInfo;

    if crInterfacePosInfo%found then
      -- Gabarit position
      if DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_POSITION_ID is null then
        DOC_POSITION_INITIALIZE.PositionInfo.DOC_GAUGE_POSITION_ID  := tplInterfacePosInfo.DOC_GAUGE_POSITION_ID;
      end if;

      -- Type de position
      if DOC_POSITION_INITIALIZE.PositionInfo.C_GAUGE_TYPE_POS is null then
        DOC_POSITION_INITIALIZE.PositionInfo.C_GAUGE_TYPE_POS  := tplInterfacePosInfo.C_GAUGE_TYPE_POS;
      end if;

      -- Bien
      if DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID is null then
        DOC_POSITION_INITIALIZE.PositionInfo.GCO_GOOD_ID  := tplInterfacePosInfo.GCO_GOOD_ID;
      end if;

      -- Nomenclature pour la création des positions cpt
      if tplInterfacePosInfo.PPS_NOMENCLATURE_ID is not null then
        DOC_POSITION_INITIALIZE.PositionInfo.PPS_NOMENCLATURE_ID  := tplInterfacePosInfo.PPS_NOMENCLATURE_ID;
      end if;

      -- Code TVA
      if     DOC_POSITION_INITIALIZE.PositionInfo.USE_ACS_TAX_CODE_ID = 0
         and tplInterfacePosInfo.ACS_TAX_CODE_ID is not null then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_ACS_TAX_CODE_ID  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_TAX_CODE_ID      := tplInterfacePosInfo.ACS_TAX_CODE_ID;
      end if;

      -- Création de position de type CPT
      if tplInterfacePosInfo.DOC_POSITION_PT_ID is not null then
        -- Coefficient d'utilisation des positions CPT
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UTIL_COEFF  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_UTIL_COEFF      := tplInterfacePosInfo.DOP_UTIL_COEFF;
      else
        -- Création de position de type 1 ou PT
        -- Recherche des qtés
        if DOC_POSITION_INITIALIZE.PositionInfo.DOP_POS_NUMBER is not null then
          -- Quantité de base
          DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY  := 1;
          -- Quantité valeur
          DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_VALUE_QUANTITY  := 1;

          select sum(DOP_QTY)
               , sum(DOP_QTY_VALUE)
            into DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY
               , DOC_POSITION_INITIALIZE.PositionInfo.POS_VALUE_QUANTITY
            from DOC_INTERFACE_POSITION
           where DOC_INTERFACE_ID = DOC_POSITION_INITIALIZE.PositionInfo.DOC_INTERFACE_ID
             and DOP_POS_NUMBER = DOC_POSITION_INITIALIZE.PositionInfo.DOP_POS_NUMBER
             and nvl(C_INTERFACE_GEN_MODE, 'INSERT') = 'INSERT';
        else
          -- Quantité de base
          if DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY = 0 then
            DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY  := 1;
            DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY      := tplInterfacePosInfo.DOP_QTY;
          end if;

          -- Quantité valeur
          if DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_VALUE_QUANTITY = 0 then
            DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_VALUE_QUANTITY  := 1;
            DOC_POSITION_INITIALIZE.PositionInfo.POS_VALUE_QUANTITY      := tplInterfacePosInfo.DOP_QTY_VALUE;
          end if;
        end if;
      end if;

      -- La qté valeur ne peut pas être plus grande que la qté de base
      if abs(DOC_POSITION_INITIALIZE.PositionInfo.POS_VALUE_QUANTITY) > abs(DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY) then
        DOC_POSITION_INITIALIZE.PositionInfo.POS_VALUE_QUANTITY  := DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY;
      end if;

      -- Type de livraison
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_C_POS_DELIVERY_TYP = 0)
         and (tplInterfacePosInfo.C_PRODUCT_DELIVERY_TYP is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_C_POS_DELIVERY_TYP  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.C_POS_DELIVERY_TYP      := tplInterfacePosInfo.C_PRODUCT_DELIVERY_TYP;
      end if;

      -- Prix unitaire
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_GOOD_PRICE = 0)
         and (tplInterfacePosInfo.DOP_USE_GOOD_PRICE = 1) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_GOOD_PRICE  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE      := tplInterfacePosInfo.DOP_GROSS_UNIT_VALUE;
      end if;

      -- Tarif net
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_NET_TARIFF = 0)
         and (tplInterfacePosInfo.DOP_NET_TARIFF is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_NET_TARIFF  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_NET_TARIFF      := tplInterfacePosInfo.DOP_NET_TARIFF;
      end if;

      -- Tarif "Action"
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SPECIAL_TARIFF = 0)
         and (tplInterfacePosInfo.DOP_SPECIAL_TARIFF is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SPECIAL_TARIFF  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_SPECIAL_TARIFF      := tplInterfacePosInfo.DOP_SPECIAL_TARIFF;
      end if;

      -- Date pour recherche Tarif
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_TARIFF_DATE = 0)
         and (tplInterfacePosInfo.DOP_TARIFF_DATE is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_TARIFF_DATE  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_TARIFF_DATE      := tplInterfacePosInfo.DOP_TARIFF_DATE;
      end if;

      -- Tarif forfaitaire
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FLAT_RATE = 0)
         and (tplInterfacePosInfo.DOP_FLAT_RATE is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FLAT_RATE  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_FLAT_RATE      := tplInterfacePosInfo.DOP_FLAT_RATE;
      end if;

      -- Remise en %
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DISCOUNT_RATE = 0)
         and (tplInterfacePosInfo.DOP_DISCOUNT_RATE is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DISCOUNT_RATE  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_DISCOUNT_RATE      := tplInterfacePosInfo.DOP_DISCOUNT_RATE;
      end if;

      -- Stock et Emplacement
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_STOCK = 0)
         and (   tplInterfacePosInfo.STM_STOCK_ID is not null
              or tplInterfacePosInfo.STM_LOCATION_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_STOCK        := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_STOCK_ID     := tplInterfacePosInfo.STM_STOCK_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_LOCATION_ID  := tplInterfacePosInfo.STM_LOCATION_ID;
      end if;

      -- Stock et Emplacement de transfert
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_TRANSFERT_STOCK = 0)
         and (   tplInterfacePosInfo.STM_STM_STOCK_ID is not null
              or tplInterfacePosInfo.STM_STM_LOCATION_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_TRANSFERT_STOCK  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_STOCK_ID     := tplInterfacePosInfo.STM_STM_STOCK_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_LOCATION_ID  := tplInterfacePosInfo.STM_STM_LOCATION_ID;
      end if;

      -- Dossier
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_DOC_RECORD_ID = 0)
         and (tplInterfacePosInfo.DOC_RECORD_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_DOC_RECORD_ID  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.DOC_RECORD_ID      := tplInterfacePosInfo.DOC_RECORD_ID;
      end if;

      -- Représentant
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPRESENTATIVE_ID = 0)
         and (tplInterfacePosInfo.PAC_REPRESENTATIVE_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPRESENTATIVE_ID  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPRESENTATIVE_ID      := tplInterfacePosInfo.PAC_REPRESENTATIVE_ID;
      end if;

      -- Représentant facturation
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPR_ACI_ID = 0)
         and (tplInterfacePosInfo.PAC_REPR_ACI_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPR_ACI_ID  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPR_ACI_ID      := tplInterfacePosInfo.PAC_REPR_ACI_ID;
      end if;

      -- Représentant livraison
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPR_DELIVERY_ID = 0)
         and (tplInterfacePosInfo.PAC_REPR_DELIVERY_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_PAC_REPR_DELIVERY_ID  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.PAC_REPR_DELIVERY_ID      := tplInterfacePosInfo.PAC_REPR_DELIVERY_ID;
      end if;

      -- Description courte
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SHORT_DESCRIPTION = 0)
         and (tplInterfacePosInfo.DOP_SHORT_DESCRIPTION is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_SHORT_DESCRIPTION      := tplInterfacePosInfo.DOP_SHORT_DESCRIPTION;
      end if;

      -- Description longue
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION = 0)
         and (tplInterfacePosInfo.DOP_LONG_DESCRIPTION is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION      := tplInterfacePosInfo.DOP_LONG_DESCRIPTION;
      end if;

      -- Description libre
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION = 0)
         and (tplInterfacePosInfo.DOP_FREE_DESCRIPTION is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION      := tplInterfacePosInfo.DOP_FREE_DESCRIPTION;
      end if;

      -- Texte de la position
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT = 0)
         and (tplInterfacePosInfo.DOP_BODY_TEXT is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.PC_APPLTXT_ID      := tplInterfacePosInfo.PC_APPLTXT_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT      := tplInterfacePosInfo.DOP_BODY_TEXT;
      end if;

      -- Dicos libres
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_DIC_POS_FREE_TABLE = 0)
         and (   tplInterfacePosInfo.DIC_POS_FREE_TABLE_1_ID is not null
              or tplInterfacePosInfo.DIC_POS_FREE_TABLE_2_ID is not null
              or tplInterfacePosInfo.DIC_POS_FREE_TABLE_3_ID is not null
             ) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_DIC_POS_FREE_TABLE   := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.DIC_POS_FREE_TABLE_1_ID  := tplInterfacePosInfo.DIC_POS_FREE_TABLE_1_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.DIC_POS_FREE_TABLE_2_ID  := tplInterfacePosInfo.DIC_POS_FREE_TABLE_2_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.DIC_POS_FREE_TABLE_3_ID  := tplInterfacePosInfo.DIC_POS_FREE_TABLE_3_ID;
      end if;

      -- Décimales libres
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DECIMAL = 0)
         and (   tplInterfacePosInfo.DOP_POS_DECIMAL_1 is not null
              or tplInterfacePosInfo.DOP_POS_DECIMAL_2 is not null
              or tplInterfacePosInfo.DOP_POS_DECIMAL_3 is not null
             ) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DECIMAL  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_DECIMAL_1    := tplInterfacePosInfo.DOP_POS_DECIMAL_1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_DECIMAL_2    := tplInterfacePosInfo.DOP_POS_DECIMAL_2;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_DECIMAL_3    := tplInterfacePosInfo.DOP_POS_DECIMAL_3;
      end if;

      -- Textes libres
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_TEXT = 0)
         and (   tplInterfacePosInfo.DOP_POS_TEXT_1 is not null
              or tplInterfacePosInfo.DOP_POS_TEXT_2 is not null
              or tplInterfacePosInfo.DOP_POS_TEXT_3 is not null
             ) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_TEXT  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_TEXT_1    := tplInterfacePosInfo.DOP_POS_TEXT_1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_TEXT_2    := tplInterfacePosInfo.DOP_POS_TEXT_2;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_TEXT_3    := tplInterfacePosInfo.DOP_POS_TEXT_3;
      end if;

      -- Dates libres
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DATE = 0)
         and (   tplInterfacePosInfo.DOP_POS_DATE_1 is not null
              or tplInterfacePosInfo.DOP_POS_DATE_2 is not null
              or tplInterfacePosInfo.DOP_POS_DATE_3 is not null
             ) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DATE  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_DATE_1    := tplInterfacePosInfo.DOP_POS_DATE_1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_DATE_2    := tplInterfacePosInfo.DOP_POS_DATE_2;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_DATE_3    := tplInterfacePosInfo.DOP_POS_DATE_3;
      end if;

      -- Référence partenaire
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_PARTNER_REFERENCE = 0)
         and (tplInterfacePosInfo.DOP_PARTNER_REFERENCE is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_PARTNER_REFERENCE  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_PARTNER_REFERENCE      := tplInterfacePosInfo.DOP_PARTNER_REFERENCE;
      end if;

      -- N° document partenaire
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_PARTNER_NUMBER = 0)
         and (tplInterfacePosInfo.DOP_PARTNER_NUMBER is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_PARTNER_NUMBER  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_PARTNER_NUMBER      := tplInterfacePosInfo.DOP_PARTNER_NUMBER;
      end if;

      -- Date document partenaire
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DATE_PARTNER_DOCUMENT = 0)
         and (tplInterfacePosInfo.DOP_PARTNER_DATE is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DATE_PARTNER_DOCUMENT  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_DATE_PARTNER_DOCUMENT      := tplInterfacePosInfo.DOP_PARTNER_DATE;
      end if;

      -- N° position du document partenaire
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_PARTNER_POS_NUMBER = 0)
         and (tplInterfacePosInfo.DOP_PARTNER_POS_NUMBER is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_PARTNER_POS_NUMBER  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_PARTNER_POS_NUMBER      := tplInterfacePosInfo.DOP_PARTNER_POS_NUMBER;
      end if;

      -- Niveau
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_A_RECLEVEL = 0)
         and (tplInterfacePosInfo.A_RECLEVEL is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_A_RECLEVEL  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.A_RECLEVEL      := tplInterfacePosInfo.A_RECLEVEL;
      end if;

      -- Statut
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_A_RECSTATUS = 0)
         and (tplInterfacePosInfo.A_RECSTATUS is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_A_RECSTATUS  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.A_RECSTATUS      := tplInterfacePosInfo.A_RECSTATUS;
      end if;

      -- Confirmation
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_A_CONFIRM = 0)
         and (tplInterfacePosInfo.A_CONFIRM is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_A_CONFIRM  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.A_CONFIRM      := tplInterfacePosInfo.A_CONFIRM;
      end if;

      -- Prix décomposé
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_DECOMPOSITION = 0)
         and (tplInterfacePosInfo.DOP_GROSS_VALUE_EXCL is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_DECOMPOSITION  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_GROSS_VALUE    := tplInterfacePosInfo.DOP_GROSS_VALUE_EXCL;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_VAT_AMOUNT     := tplInterfacePosInfo.DOP_VAT_AMOUNT;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_VAT_RATE       := tplInterfacePosInfo.DOP_VAT_RATE;
      end if;

      -- Poids
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_WEIGHT = 0)
         and (tplInterfacePosInfo.DOP_GROSS_WEIGHT is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_WEIGHT    := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_GROSS_WEIGHT  := tplInterfacePosInfo.DOP_GROSS_WEIGHT;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_NET_WEIGHT    := tplInterfacePosInfo.DOP_NET_WEIGHT;
      end if;

      -- Comptes
      if    (tplInterfacePosInfo.ACS_FINANCIAL_ACCOUNT_ID is not null)
         or (tplInterfacePosInfo.ACS_DIVISION_ACCOUNT_ID is not null)
         or (tplInterfacePosInfo.ACS_CPN_ACCOUNT_ID is not null)
         or (tplInterfacePosInfo.ACS_CDA_ACCOUNT_ID is not null)
         or (tplInterfacePosInfo.ACS_PF_ACCOUNT_ID is not null)
         or (tplInterfacePosInfo.ACS_PJ_ACCOUNT_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_ACCOUNTS              := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_FINANCIAL_ACCOUNT_ID  := tplInterfacePosInfo.ACS_FINANCIAL_ACCOUNT_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_DIVISION_ACCOUNT_ID   := tplInterfacePosInfo.ACS_DIVISION_ACCOUNT_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_CPN_ACCOUNT_ID        := tplInterfacePosInfo.ACS_CPN_ACCOUNT_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_CDA_ACCOUNT_ID        := tplInterfacePosInfo.ACS_CDA_ACCOUNT_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_PF_ACCOUNT_ID         := tplInterfacePosInfo.ACS_PF_ACCOUNT_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_PJ_ACCOUNT_ID         := tplInterfacePosInfo.ACS_PJ_ACCOUNT_ID;
      end if;
    end if;

    close crInterfacePosInfo;
  end InitPosition_140;

  /**
  *  procedure InitPosition_141
  *  Description
  *    Création - Générateur de documents concernant la dématérialisation
  */
  procedure InitPosition_141
  is
  begin
    -- L'initialisation du 141 est actuellement la même que celle du 140
    InitPosition_140;
  end InitPosition_141;

  /**
  *  procedure InitPosition_142
  *  Description
  *    Création - Générateur de documents - E-Shop
  */
  procedure InitPosition_142
  is
  begin
    -- L'initialisation du 142 est actuellement la même que celle du 140
    InitPosition_140;
  end InitPosition_142;

  /**
  *  procedure InitPosition_150
  *  Description
  *    Création - Dossiers SAV
  */
  procedure InitPosition_150
  is
  begin
    null;
  end InitPosition_150;

  /**
  *  procedure InitPosition_155
  *  Description
  *    Création - SAV externe
  */
  procedure InitPosition_155
  is
  begin
    null;
  end InitPosition_155;

  /**
  *  procedure InitPosition_160
  *  Description
  *    Création - CML
  */
  procedure InitPosition_160
  is
  begin
    null;
  end InitPosition_160;

  /**
  *  procedure InitPosition_165
  *  Description
  *    Création - Facturation des contrats de maintenance
  */
  procedure InitPosition_165
  is
  begin
    null;
  end InitPosition_165;

  /**
  *  procedure InitPosition_170
  *  Description
  *    Création - Assistant devis
  */
  procedure InitPosition_170
  is
  begin
    null;
  end InitPosition_170;

  /**
  *  procedure InitPosition_180
  *  Description
  *    Création - Extraction des commissions
  */
  procedure InitPosition_180
  is
    cursor crCommissionAccounts
    is
      select PCS.PC_CONFIG.GetConfig('DOC_COMM_USE_ACS_FIN_ACCOUNT') USE_FIN_ACCOUNT
           , PCS.PC_CONFIG.GetConfig('DOC_COMM_USE_ACS_DIV_ACCOUNT') USE_DIV_ACCOUNT
           , PCS.PC_CONFIG.GetConfig('DOC_COMM_USE_ACS_CPN_ACCOUNT') USE_CPN_ACCOUNT
           , PCS.PC_CONFIG.GetConfig('DOC_COMM_USE_ACS_CDA_ACCOUNT') USE_CDA_ACCOUNT
           , PCS.PC_CONFIG.GetConfig('DOC_COMM_USE_ACS_PF_ACCOUNT') USE_PF_ACCOUNT
           , PCS.PC_CONFIG.GetConfig('DOC_COMM_USE_ACS_PJ_ACCOUNT') USE_PJ_ACCOUNT
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
        from DOC_EXTRACT_COMMISSION
       where DOC_EXTRACT_COMMISSION_ID = DOC_POSITION_INITIALIZE.PositionInfo.DOC_EXTRACT_COMMISSION_ID;

    tplCommissionAccounts crCommissionAccounts%rowtype;
  begin
    -- Initialisation des comptes

    -- Contrôle si les comptes sont repris du document à l'origine de la commission en fonction des codes de configuration
    --   Code de transfer du compte du projet dans la position du document de commissionnement à partir du document à l'origine de la commission :
    --   Valeur de configuration
    --     0   -> Initialisation en fonction du gabarit du document de commissionnement
    --     1   -> Transfert à partir du document d'origine de la commission
    --     2   -> Transfert à partir du document d'origine de la commission, si nul initialisation en fonction du gabarit du document de commissionnement
    open crCommissionAccounts;

    fetch crCommissionAccounts
     into tplCommissionAccounts;

    if crCommissionAccounts%found then
      -- Compte Financier
      if     tplCommissionAccounts.USE_FIN_ACCOUNT in('1', '2')
         and (tplCommissionAccounts.ACS_FINANCIAL_ACCOUNT_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_ACCOUNTS              := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_FINANCIAL_ACCOUNT_ID  := tplCommissionAccounts.ACS_FINANCIAL_ACCOUNT_ID;
      end if;

      -- Compte Division
      if     tplCommissionAccounts.USE_DIV_ACCOUNT in('1', '2')
         and (tplCommissionAccounts.ACS_DIVISION_ACCOUNT_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_ACCOUNTS             := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_DIVISION_ACCOUNT_ID  := tplCommissionAccounts.ACS_DIVISION_ACCOUNT_ID;
      end if;

      -- Compte Charge par nature
      if     tplCommissionAccounts.USE_CPN_ACCOUNT in('1', '2')
         and (tplCommissionAccounts.ACS_CPN_ACCOUNT_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_ACCOUNTS        := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_CPN_ACCOUNT_ID  := tplCommissionAccounts.ACS_CPN_ACCOUNT_ID;
      end if;

      -- Compte Centre d'analyse
      if     tplCommissionAccounts.USE_CDA_ACCOUNT in('1', '2')
         and (tplCommissionAccounts.ACS_CDA_ACCOUNT_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_ACCOUNTS        := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_CDA_ACCOUNT_ID  := tplCommissionAccounts.ACS_CDA_ACCOUNT_ID;
      end if;

      -- Compte Porteur
      if     tplCommissionAccounts.USE_PF_ACCOUNT in('1', '2')
         and (tplCommissionAccounts.ACS_PF_ACCOUNT_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_ACCOUNTS       := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_PF_ACCOUNT_ID  := tplCommissionAccounts.ACS_PF_ACCOUNT_ID;
      end if;

      -- Compte Projet
      if     tplCommissionAccounts.USE_PJ_ACCOUNT in('1', '2')
         and (tplCommissionAccounts.ACS_PJ_ACCOUNT_ID is not null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_ACCOUNTS       := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.ACS_PJ_ACCOUNT_ID  := tplCommissionAccounts.ACS_PJ_ACCOUNT_ID;
      end if;
    end if;

    close crCommissionAccounts;
  end InitPosition_180;

  /**
  *  procedure InitPosition_190
  *  Description
  *    Création - Echéancier
  */
  procedure InitPosition_190
  is
  begin
    null;
  end InitPosition_190;

  /**
  * Description
  *    Création des données de copie dans la table temporaire
  */
  procedure InsertCopyPosDetail(aTgtDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aSrcPositionID in DOC_POSITION.DOC_POSITION_ID%type)
  is
    cursor crCopyPde(cSrcPositionID in number, cTgtGaugeID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , DMT.PAC_THIRD_ID
                    , DMT.PAC_THIRD_ACI_ID
                    , DMT.PAC_THIRD_DELIVERY_ID
                    , DMT.PAC_THIRD_TARIFF_ID
                    , DMT.PAC_THIRD_CDA_ID
                    , PDE.DOC_GAUGE_ID
                    , null DOC_GAUGE_RECEIPT_ID
                    , 0 DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_MOVEMENT_DATE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , PDE.PDE_FINAL_QUANTITY DCD_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY_SU DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , DOC_GAUGE_POSITION GAP
                where POS.DOC_POSITION_ID = cSrcPositionID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                  and exists(
                        select GAP_TGT.DOC_GAUGE_POSITION_ID
                          from DOC_GAUGE_POSITION GAP_TGT
                         where GAP_TGT.DOC_GAUGE_ID = cTgtGaugeID
                           and GAP_TGT.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
                           and GAP_TGT.GAP_DESIGNATION = GAP.GAP_DESIGNATION)
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    cursor crCopyPdeCPT(cPositionID in number, cTgtDocumentID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , DCD.CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_DOCUMENT_ID
                    , DMT.PAC_THIRD_ID
                    , DMT.PAC_THIRD_ACI_ID
                    , DMT.PAC_THIRD_DELIVERY_ID
                    , DMT.PAC_THIRD_TARIFF_ID
                    , PDE.DOC_GAUGE_ID
                    , null DOC_GAUGE_RECEIPT_ID
                    , 0 DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_MOVEMENT_DATE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , PDE.PDE_FINAL_QUANTITY DCD_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY_SU DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , GAU.C_ADMIN_DOMAIN
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                    , DOC_GAUGE GAU
                where POS.DOC_DOC_POSITION_ID = cPositionID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and GAU.DOC_GAUGE_ID = DCD.DOC_GAUGE_ID
                  and DCD.NEW_DOCUMENT_ID = cTgtDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    --
    vTGT_PAC_THIRD_CDA_ID PAC_THIRD.PAC_THIRD_ID%type;
    vTGT_DOC_GAUGE_ID     DOC_GAUGE.DOC_GAUGE_ID%type;
    vTGT_C_ADMIN_DOMAIN   DOC_GAUGE.C_ADMIN_DOMAIN%type;
    vConvertFactorCalc    GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    --
    vTplDcd               V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vTplDcdCpt            V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
  begin
    -- Informations du document cible
    select DMT.PAC_THIRD_CDA_ID
         , DMT.DOC_GAUGE_ID
         , GAU.C_ADMIN_DOMAIN
      into vTGT_PAC_THIRD_CDA_ID
         , vTGT_DOC_GAUGE_ID
         , vTGT_C_ADMIN_DOMAIN
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
     where DMT.DOC_DOCUMENT_ID = aTgtDocumentID
       and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    -- Liste des détails du document source
    for vTplCopyPde in crCopyPde(aSrcPositionID, vTGT_DOC_GAUGE_ID) loop
      -- Traitement du changement de partenaire. Si le partenaire source est différent du partenaire cible,
      -- Il faut rechercher le facteur de conversion calculé.
      vConvertFactorCalc                    :=
        GCO_FUNCTIONS.GetThirdConvertFactor(vTplCopyPde.GCO_GOOD_ID
                                          , vTplCopyPde.PAC_THIRD_CDA_ID
                                          , vTplCopyPde.C_GAUGE_TYPE_POS
                                          , null
                                          , vTGT_PAC_THIRD_CDA_ID
                                          , vTGT_C_ADMIN_DOMAIN
                                           );
      vTplDcd                               := null;
      vTplDcd.DOC_POSITION_DETAIL_ID        := vTplCopyPde.DOC_POSITION_DETAIL_ID;
      vTplDcd.NEW_DOCUMENT_ID               := aTgtDocumentID;
      vTplDcd.C_PDE_CREATE_MODE             := nvl(DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE, '920');
      vTplDcd.CRG_SELECT                    := vTplCopyPde.CRG_SELECT;
      vTplDcd.DOC_GAUGE_FLOW_ID             := vTplCopyPde.DOC_GAUGE_FLOW_ID;
      vTplDcd.DOC_POSITION_ID               := vTplCopyPde.DOC_POSITION_ID;
      vTplDcd.DOC_DOC_POSITION_ID           := vTplCopyPde.DOC_DOC_POSITION_ID;
      vTplDcd.DOC_DOC_POSITION_DETAIL_ID    := vTplCopyPde.DOC_DOC_POSITION_DETAIL_ID;
      vTplDcd.DOC2_DOC_POSITION_DETAIL_ID   := vTplCopyPde.DOC2_DOC_POSITION_DETAIL_ID;
      vTplDcd.GCO_GOOD_ID                   := vTplCopyPde.GCO_GOOD_ID;
      vTplDcd.STM_LOCATION_ID               := vTplCopyPde.STM_LOCATION_ID;
      vTplDcd.STM_STM_LOCATION_ID           := vTplCopyPde.STM_STM_LOCATION_ID;
      vTplDcd.GCO_CHARACTERIZATION_ID       := vTplCopyPde.GCO_CHARACTERIZATION_ID;
      vTplDcd.GCO_GCO_CHARACTERIZATION_ID   := vTplCopyPde.GCO_GCO_CHARACTERIZATION_ID;
      vTplDcd.GCO2_GCO_CHARACTERIZATION_ID  := vTplCopyPde.GCO2_GCO_CHARACTERIZATION_ID;
      vTplDcd.GCO3_GCO_CHARACTERIZATION_ID  := vTplCopyPde.GCO3_GCO_CHARACTERIZATION_ID;
      vTplDcd.GCO4_GCO_CHARACTERIZATION_ID  := vTplCopyPde.GCO4_GCO_CHARACTERIZATION_ID;
      vTplDcd.DIC_PDE_FREE_TABLE_1_ID       := vTplCopyPde.DIC_PDE_FREE_TABLE_1_ID;
      vTplDcd.DIC_PDE_FREE_TABLE_2_ID       := vTplCopyPde.DIC_PDE_FREE_TABLE_2_ID;
      vTplDcd.DIC_PDE_FREE_TABLE_3_ID       := vTplCopyPde.DIC_PDE_FREE_TABLE_3_ID;
      vTplDcd.FAL_SCHEDULE_STEP_ID          := vTplCopyPde.FAL_SCHEDULE_STEP_ID;
      vTplDcd.DOC_RECORD_ID                 := vTplCopyPde.DOC_RECORD_ID;
      vTplDcd.DOC_DOCUMENT_ID               := vTplCopyPde.DOC_DOCUMENT_ID;
      vTplDcd.PAC_THIRD_ID                  := vTplCopyPde.PAC_THIRD_ID;
      vTplDcd.PAC_THIRD_ACI_ID              := vTplCopyPde.PAC_THIRD_ACI_ID;
      vTplDcd.PAC_THIRD_DELIVERY_ID         := vTplCopyPde.PAC_THIRD_DELIVERY_ID;
      vTplDcd.PAC_THIRD_TARIFF_ID           := vTplCopyPde.PAC_THIRD_TARIFF_ID;
      vTplDcd.DOC_GAUGE_ID                  := vTplCopyPde.DOC_GAUGE_ID;
      vTplDcd.DOC_GAUGE_RECEIPT_ID          := vTplCopyPde.DOC_GAUGE_RECEIPT_ID;
      vTplDcd.DOC_GAUGE_COPY_ID             := vTplCopyPde.DOC_GAUGE_COPY_ID;
      vTplDcd.C_GAUGE_TYPE_POS              := vTplCopyPde.C_GAUGE_TYPE_POS;
      vTplDcd.DIC_DELAY_UPDATE_TYPE_ID      := vTplCopyPde.DIC_DELAY_UPDATE_TYPE_ID;
      vTplDcd.PDE_BASIS_DELAY               := vTplCopyPde.PDE_BASIS_DELAY;
      vTplDcd.PDE_INTERMEDIATE_DELAY        := vTplCopyPde.PDE_INTERMEDIATE_DELAY;
      vTplDcd.PDE_FINAL_DELAY               := vTplCopyPde.PDE_FINAL_DELAY;
      vTplDcd.PDE_SQM_ACCEPTED_DELAY        := vTplCopyPde.PDE_SQM_ACCEPTED_DELAY;
      vTplDcd.PDE_BASIS_QUANTITY            := vTplCopyPde.PDE_BASIS_QUANTITY;
      vTplDcd.PDE_INTERMEDIATE_QUANTITY     := vTplCopyPde.PDE_INTERMEDIATE_QUANTITY;
      vTplDcd.PDE_FINAL_QUANTITY            := vTplCopyPde.PDE_FINAL_QUANTITY;
      vTplDcd.PDE_BALANCE_QUANTITY          := vTplCopyPde.PDE_BALANCE_QUANTITY;
      vTplDcd.PDE_BALANCE_QUANTITY_PARENT   := vTplCopyPde.PDE_BALANCE_QUANTITY_PARENT;
      vTplDcd.PDE_BASIS_QUANTITY_SU         := vTplCopyPde.PDE_BASIS_QUANTITY_SU;
      vTplDcd.PDE_INTERMEDIATE_QUANTITY_SU  := vTplCopyPde.PDE_INTERMEDIATE_QUANTITY_SU;
      vTplDcd.PDE_FINAL_QUANTITY_SU         := vTplCopyPde.PDE_FINAL_QUANTITY_SU;
      vTplDcd.PDE_MOVEMENT_QUANTITY         := vTplCopyPde.PDE_MOVEMENT_QUANTITY;
      vTplDcd.PDE_MOVEMENT_VALUE            := vTplCopyPde.PDE_MOVEMENT_VALUE;
      vTplDcd.PDE_MOVEMENT_DATE             := vTplCopyPde.PDE_MOVEMENT_DATE;
      vTplDcd.PDE_CHARACTERIZATION_VALUE_1  := vTplCopyPde.PDE_CHARACTERIZATION_VALUE_1;
      vTplDcd.PDE_CHARACTERIZATION_VALUE_2  := vTplCopyPde.PDE_CHARACTERIZATION_VALUE_2;
      vTplDcd.PDE_CHARACTERIZATION_VALUE_3  := vTplCopyPde.PDE_CHARACTERIZATION_VALUE_3;
      vTplDcd.PDE_CHARACTERIZATION_VALUE_4  := vTplCopyPde.PDE_CHARACTERIZATION_VALUE_4;
      vTplDcd.PDE_CHARACTERIZATION_VALUE_5  := vTplCopyPde.PDE_CHARACTERIZATION_VALUE_5;

      -- Lors de la copie pour les frais à répartir (206), la qté du détail est égale à 0
      -- dans ce cas, la valeur de caract doit être nulle si celle-ci n'est pas du type 2 - Caractéristiques
      if (DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE = '206') then
        if     (vTplCopyPde.GCO_CHARACTERIZATION_ID is not null)
           and (GCO_LIB_CHARACTERIZATION.GetCharacType(vTplCopyPde.GCO_CHARACTERIZATION_ID) <> '2') then
          vTplDcd.PDE_CHARACTERIZATION_VALUE_1  := null;
        end if;

        if     (vTplCopyPde.GCO_GCO_CHARACTERIZATION_ID is not null)
           and (GCO_LIB_CHARACTERIZATION.GetCharacType(vTplCopyPde.GCO_GCO_CHARACTERIZATION_ID) <> '2') then
          vTplDcd.PDE_CHARACTERIZATION_VALUE_2  := null;
        end if;

        if     (vTplCopyPde.GCO2_GCO_CHARACTERIZATION_ID is not null)
           and (GCO_LIB_CHARACTERIZATION.GetCharacType(vTplCopyPde.GCO2_GCO_CHARACTERIZATION_ID) <> '2') then
          vTplDcd.PDE_CHARACTERIZATION_VALUE_3  := null;
        end if;

        if     (vTplCopyPde.GCO3_GCO_CHARACTERIZATION_ID is not null)
           and (GCO_LIB_CHARACTERIZATION.GetCharacType(vTplCopyPde.GCO3_GCO_CHARACTERIZATION_ID) <> '2') then
          vTplDcd.PDE_CHARACTERIZATION_VALUE_4  := null;
        end if;

        if     (vTplCopyPde.GCO4_GCO_CHARACTERIZATION_ID is not null)
           and (GCO_LIB_CHARACTERIZATION.GetCharacType(vTplCopyPde.GCO4_GCO_CHARACTERIZATION_ID) <> '2') then
          vTplDcd.PDE_CHARACTERIZATION_VALUE_5  := null;
        end if;
      end if;

      vTplDcd.PDE_DELAY_UPDATE_TEXT         := vTplCopyPde.PDE_DELAY_UPDATE_TEXT;
      vTplDcd.PDE_DECIMAL_1                 := vTplCopyPde.PDE_DECIMAL_1;
      vTplDcd.PDE_DECIMAL_2                 := vTplCopyPde.PDE_DECIMAL_2;
      vTplDcd.PDE_DECIMAL_3                 := vTplCopyPde.PDE_DECIMAL_3;
      vTplDcd.PDE_TEXT_1                    := vTplCopyPde.PDE_TEXT_1;
      vTplDcd.PDE_TEXT_2                    := vTplCopyPde.PDE_TEXT_2;
      vTplDcd.PDE_TEXT_3                    := vTplCopyPde.PDE_TEXT_3;
      vTplDcd.PDE_DATE_1                    := vTplCopyPde.PDE_DATE_1;
      vTplDcd.PDE_DATE_2                    := vTplCopyPde.PDE_DATE_2;
      vTplDcd.PDE_DATE_3                    := vTplCopyPde.PDE_DATE_3;
      vTplDcd.PDE_GENERATE_MOVEMENT         := vTplCopyPde.PDE_GENERATE_MOVEMENT;

      -- Qté à copier
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY = 1)
         and (abs(DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY) < abs(vTplCopyPde.DCD_QUANTITY) ) then
        vTplDcd.DCD_QUANTITY     := DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY;
        vTplDcd.DCD_QUANTITY_SU  := DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY_SU;
      else
        vTplDcd.DCD_QUANTITY                                         := vTplCopyPde.DCD_QUANTITY;
        vTplDcd.DCD_QUANTITY_SU                                      := vTplCopyPde.DCD_QUANTITY_SU;
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY  := 0;
      end if;

      vTplDcd.DCD_BALANCE_FLAG              := vTplCopyPde.DCD_BALANCE_FLAG;
      vTplDcd.POS_CONVERT_FACTOR            := vTplCopyPde.POS_CONVERT_FACTOR;
      vTplDcd.POS_CONVERT_FACTOR_CALC       := nvl(vConvertFactorCalc, vTplCopyPde.POS_CONVERT_FACTOR);
      vTplDcd.POS_GROSS_UNIT_VALUE          := vTplCopyPde.POS_GROSS_UNIT_VALUE;
      vTplDcd.POS_GROSS_UNIT_VALUE_INCL     := vTplCopyPde.POS_GROSS_UNIT_VALUE_INCL;
      vTplDcd.POS_UNIT_OF_MEASURE_ID        := vTplCopyPde.DIC_UNIT_OF_MEASURE_ID;
      vTplDcd.DCD_DEPLOYED_COMPONENTS       := vTplCopyPde.DCD_DEPLOYED_COMPONENTS;
      vTplDcd.DCD_VISIBLE                   := 0;
      vTplDcd.A_DATECRE                     := vTplCopyPde.NEW_A_DATECRE;
      vTplDcd.A_IDCRE                       := vTplCopyPde.NEW_A_IDCRE;
      vTplDcd.PDE_ST_PT_REJECT              := vTplCopyPde.PDE_ST_PT_REJECT;
      vTplDcd.PDE_ST_CPT_REJECT             := vTplCopyPde.PDE_ST_CPT_REJECT;

      insert into V_DOC_POS_DET_COPY_DISCHARGE
           values vTplDcd;

      -- Changement de position et traitement d'une position kit ou assemblage
      if vTplCopyPde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        -- Traitement des détails de positions composants.
        for vTplCopyPdeCPT in crCopyPdeCPT(vTplDcd.DOC_POSITION_ID, aTgtDocumentID) loop
          vTplDcdCpt                               := null;
          vTplDcdCpt.DOC_POSITION_DETAIL_ID        := vTplCopyPdeCPT.DOC_POSITION_DETAIL_ID;
          vTplDcdCpt.NEW_DOCUMENT_ID               := aTgtDocumentID;
          vTplDcdCpt.C_PDE_CREATE_MODE             := nvl(DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE, '920');
          vTplDcdCpt.CRG_SELECT                    := vTplCopyPdeCPT.CRG_SELECT;
          vTplDcdCpt.DOC_GAUGE_FLOW_ID             := vTplCopyPdeCPT.DOC_GAUGE_FLOW_ID;
          vTplDcdCpt.DOC_POSITION_ID               := vTplCopyPdeCPT.DOC_POSITION_ID;
          vTplDcdCpt.DOC_DOC_POSITION_ID           := vTplCopyPdeCPT.DOC_DOC_POSITION_ID;
          vTplDcdCpt.DOC_DOC_POSITION_DETAIL_ID    := vTplCopyPdeCPT.DOC_DOC_POSITION_DETAIL_ID;
          vTplDcdCpt.DOC2_DOC_POSITION_DETAIL_ID   := vTplCopyPdeCPT.DOC2_DOC_POSITION_DETAIL_ID;
          vTplDcdCpt.GCO_GOOD_ID                   := vTplCopyPdeCPT.GCO_GOOD_ID;
          vTplDcdCpt.STM_LOCATION_ID               := vTplCopyPdeCPT.STM_LOCATION_ID;
          vTplDcdCpt.STM_STM_LOCATION_ID           := vTplCopyPdeCPT.STM_STM_LOCATION_ID;
          vTplDcdCpt.GCO_CHARACTERIZATION_ID       := vTplCopyPdeCPT.GCO_CHARACTERIZATION_ID;
          vTplDcdCpt.GCO_GCO_CHARACTERIZATION_ID   := vTplCopyPdeCPT.GCO_GCO_CHARACTERIZATION_ID;
          vTplDcdCpt.GCO2_GCO_CHARACTERIZATION_ID  := vTplCopyPdeCPT.GCO2_GCO_CHARACTERIZATION_ID;
          vTplDcdCpt.GCO3_GCO_CHARACTERIZATION_ID  := vTplCopyPdeCPT.GCO3_GCO_CHARACTERIZATION_ID;
          vTplDcdCpt.GCO4_GCO_CHARACTERIZATION_ID  := vTplCopyPdeCPT.GCO4_GCO_CHARACTERIZATION_ID;
          vTplDcdCpt.DIC_PDE_FREE_TABLE_1_ID       := vTplCopyPdeCPT.DIC_PDE_FREE_TABLE_1_ID;
          vTplDcdCpt.DIC_PDE_FREE_TABLE_2_ID       := vTplCopyPdeCPT.DIC_PDE_FREE_TABLE_2_ID;
          vTplDcdCpt.DIC_PDE_FREE_TABLE_3_ID       := vTplCopyPdeCPT.DIC_PDE_FREE_TABLE_3_ID;
          vTplDcdCpt.FAL_SCHEDULE_STEP_ID          := vTplCopyPdeCPT.FAL_SCHEDULE_STEP_ID;
          vTplDcdCpt.DOC_DOCUMENT_ID               := vTplCopyPdeCPT.DOC_DOCUMENT_ID;
          vTplDcdCpt.PAC_THIRD_ID                  := vTplCopyPdeCPT.PAC_THIRD_ID;
          vTplDcdCpt.PAC_THIRD_ACI_ID              := vTplCopyPdeCPT.PAC_THIRD_ACI_ID;
          vTplDcdCpt.PAC_THIRD_DELIVERY_ID         := vTplCopyPdeCPT.PAC_THIRD_DELIVERY_ID;
          vTplDcdCpt.PAC_THIRD_TARIFF_ID           := vTplCopyPdeCPT.PAC_THIRD_TARIFF_ID;
          vTplDcdCpt.DOC_GAUGE_ID                  := vTplCopyPdeCPT.DOC_GAUGE_ID;
          vTplDcdCpt.DOC_GAUGE_RECEIPT_ID          := vTplCopyPdeCPT.DOC_GAUGE_RECEIPT_ID;
          vTplDcdCpt.DOC_GAUGE_COPY_ID             := vTplCopyPdeCPT.DOC_GAUGE_COPY_ID;
          vTplDcdCpt.C_GAUGE_TYPE_POS              := vTplCopyPdeCPT.C_GAUGE_TYPE_POS;
          vTplDcdCpt.DIC_DELAY_UPDATE_TYPE_ID      := vTplCopyPdeCPT.DIC_DELAY_UPDATE_TYPE_ID;
          vTplDcdCpt.PDE_BASIS_DELAY               := vTplCopyPdeCPT.PDE_BASIS_DELAY;
          vTplDcdCpt.PDE_INTERMEDIATE_DELAY        := vTplCopyPdeCPT.PDE_INTERMEDIATE_DELAY;
          vTplDcdCpt.PDE_FINAL_DELAY               := vTplCopyPdeCPT.PDE_FINAL_DELAY;
          vTplDcdCpt.PDE_SQM_ACCEPTED_DELAY        := vTplCopyPdeCPT.PDE_SQM_ACCEPTED_DELAY;
          vTplDcdCpt.PDE_BASIS_QUANTITY            := vTplCopyPdeCPT.PDE_BASIS_QUANTITY;
          vTplDcdCpt.PDE_INTERMEDIATE_QUANTITY     := vTplCopyPdeCPT.PDE_INTERMEDIATE_QUANTITY;
          vTplDcdCpt.PDE_FINAL_QUANTITY            := vTplCopyPdeCPT.PDE_FINAL_QUANTITY;
          vTplDcdCpt.PDE_BALANCE_QUANTITY          := vTplCopyPdeCPT.PDE_BALANCE_QUANTITY;
          vTplDcdCpt.PDE_BALANCE_QUANTITY_PARENT   := vTplCopyPdeCPT.PDE_BALANCE_QUANTITY_PARENT;
          vTplDcdCpt.PDE_BASIS_QUANTITY_SU         := vTplCopyPdeCPT.PDE_BASIS_QUANTITY_SU;
          vTplDcdCpt.PDE_INTERMEDIATE_QUANTITY_SU  := vTplCopyPdeCPT.PDE_INTERMEDIATE_QUANTITY_SU;
          vTplDcdCpt.PDE_FINAL_QUANTITY_SU         := vTplCopyPdeCPT.PDE_FINAL_QUANTITY_SU;
          vTplDcdCpt.PDE_MOVEMENT_QUANTITY         := vTplCopyPdeCPT.PDE_MOVEMENT_QUANTITY;
          vTplDcdCpt.PDE_MOVEMENT_VALUE            := vTplCopyPdeCPT.PDE_MOVEMENT_VALUE;
          vTplDcdCpt.PDE_MOVEMENT_DATE             := vTplCopyPdeCPT.PDE_MOVEMENT_DATE;
          vTplDcdCpt.PDE_CHARACTERIZATION_VALUE_1  := vTplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_1;
          vTplDcdCpt.PDE_CHARACTERIZATION_VALUE_2  := vTplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_2;
          vTplDcdCpt.PDE_CHARACTERIZATION_VALUE_3  := vTplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_3;
          vTplDcdCpt.PDE_CHARACTERIZATION_VALUE_4  := vTplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_4;
          vTplDcdCpt.PDE_CHARACTERIZATION_VALUE_5  := vTplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_5;
          vTplDcdCpt.PDE_DELAY_UPDATE_TEXT         := vTplCopyPdeCPT.PDE_DELAY_UPDATE_TEXT;
          vTplDcdCpt.PDE_DECIMAL_1                 := vTplCopyPdeCPT.PDE_DECIMAL_1;
          vTplDcdCpt.PDE_DECIMAL_2                 := vTplCopyPdeCPT.PDE_DECIMAL_2;
          vTplDcdCpt.PDE_DECIMAL_3                 := vTplCopyPdeCPT.PDE_DECIMAL_3;
          vTplDcdCpt.PDE_TEXT_1                    := vTplCopyPdeCPT.PDE_TEXT_1;
          vTplDcdCpt.PDE_TEXT_2                    := vTplCopyPdeCPT.PDE_TEXT_2;
          vTplDcdCpt.PDE_TEXT_3                    := vTplCopyPdeCPT.PDE_TEXT_3;
          vTplDcdCpt.PDE_DATE_1                    := vTplCopyPdeCPT.PDE_DATE_1;
          vTplDcdCpt.PDE_DATE_2                    := vTplCopyPdeCPT.PDE_DATE_2;
          vTplDcdCpt.PDE_DATE_3                    := vTplCopyPdeCPT.PDE_DATE_3;
          vTplDcdCpt.PDE_GENERATE_MOVEMENT         := vTplCopyPdeCPT.PDE_GENERATE_MOVEMENT;
          vTplDcdCpt.DCD_QUANTITY                  := vTplCopyPdeCPT.DCD_QUANTITY;
          vTplDcdCpt.DCD_QUANTITY_SU               := vTplCopyPdeCPT.DCD_QUANTITY_SU;
          vTplDcdCpt.DCD_BALANCE_FLAG              := vTplCopyPdeCPT.DCD_BALANCE_FLAG;
          vTplDcdCpt.POS_CONVERT_FACTOR            := vTplCopyPdeCPT.POS_CONVERT_FACTOR;
          vTplDcdCpt.POS_CONVERT_FACTOR_CALC       := vTplCopyPdeCPT.POS_CONVERT_FACTOR;
          vTplDcdCpt.POS_GROSS_UNIT_VALUE          := vTplCopyPdeCPT.POS_GROSS_UNIT_VALUE;
          vTplDcdCpt.POS_GROSS_UNIT_VALUE_INCL     := vTplCopyPdeCPT.POS_GROSS_UNIT_VALUE_INCL;
          vTplDcdCpt.POS_UNIT_OF_MEASURE_ID        := vTplCopyPdeCPT.DIC_UNIT_OF_MEASURE_ID;
          vTplDcdCpt.POS_UTIL_COEFF                := vTplCopyPdeCPT.POS_UTIL_COEFF;
          vTplDcdCpt.DCD_VISIBLE                   := 0;
          vTplDcdCpt.A_DATECRE                     := vTplCopyPdeCPT.NEW_A_DATECRE;
          vTplDcdCpt.A_IDCRE                       := vTplCopyPdeCPT.NEW_A_IDCRE;
          vTplDcdCpt.PDE_ST_PT_REJECT              := vTplCopyPdeCPT.PDE_ST_PT_REJECT;
          vTplDcdCpt.PDE_ST_CPT_REJECT             := vTplCopyPdeCPT.PDE_ST_CPT_REJECT;

          insert into V_DOC_POS_DET_COPY_DISCHARGE
               values vTplDcdCpt;
        end loop;
      end if;
    end loop;
  end InsertCopyPosDetail;

  /**
  * procedure InsertDischargePosDetail
  * Description
  *    Création des données de décharge dans la table temporaire
  */
  procedure InsertDischargePosDetail(aTgtDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aSrcPositionID in DOC_POSITION.DOC_POSITION_ID%type)
  is
    cursor crDischargePde(cSrcPositionID in number, cTgtGaugeID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , DMT.PAC_THIRD_ID
                    , DMT.PAC_THIRD_ACI_ID
                    , DMT.PAC_THIRD_DELIVERY_ID
                    , DMT.PAC_THIRD_TARIFF_ID
                    , DMT.PAC_THIRD_CDA_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_MOVEMENT_DATE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , PDE.PDE_BALANCE_QUANTITY DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , DOC_GAUGE_POSITION GAP
                    , GCO_GOOD GOO
                where POS.DOC_POSITION_ID = cSrcPositionID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and PDE.DOC_POSITION_DETAIL_ID in(
                        select PDE2.DOC_POSITION_DETAIL_ID
                          from DOC_POSITION_DETAIL PDE2
                             , DOC_POSITION POS2
                         where PDE2.DOC_POSITION_ID = POS2.DOC_POSITION_ID
                           and POS2.DOC_POSITION_ID = cSrcPositionID
                           and (    (     ( (       POS2.C_DOC_POS_STATUS in('02', '03')
                                                and (   PDE2.PDE_BALANCE_QUANTITY <> 0
                                                     or nvl(PDE2.PDE_FINAL_QUANTITY, 0) = 0)
                                             or (    exists(
                                                       select DOC_GAUGE_POSITION_ID
                                                         from DOC_GAUGE_POSITION GAP_LINK
                                                        where GAP_LINK.DOC_GAUGE_POSITION_ID = POS2.DOC_GAUGE_POSITION_ID
                                                          and GAP_LINK.DOC_DOC_GAUGE_POSITION_ID is not null)
                                                 and (exists(
                                                        select POS_CPT.DOC_POSITION_ID
                                                          from DOC_POSITION POS_CPT
                                                         where POS_CPT.DOC_DOC_POSITION_ID = POS2.DOC_POSITION_ID
                                                           and POS_CPT.DOC_DOCUMENT_ID = POS2.DOC_DOCUMENT_ID
                                                           and POS_CPT.C_DOC_POS_STATUS < '04')
                                                     )
                                                )
                                            )
                                          )
                                     and POS2.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10')
                                     and POS2.DOC_DOC_POSITION_ID is null
                                    )
                                or (POS2.C_GAUGE_TYPE_POS not in('1', '2', '3', '7', '8', '9', '10', '71', '81', '91', '101') )
                               )
                           and exists(
                                 select GAP.DOC_GAUGE_POSITION_ID
                                   from DOC_GAUGE_POSITION GAP
                                  where GAP.DOC_GAUGE_ID = cTgtGaugeID
                                    and GAP.C_GAUGE_TYPE_POS = POS2.C_GAUGE_TYPE_POS
                                    and GAP.GAP_DESIGNATION in(
                                                 select GAP2.GAP_DESIGNATION
                                                   from DOC_GAUGE_POSITION GAP2
                                                  where GAP2.DOC_GAUGE_POSITION_ID = POS2.DOC_GAUGE_POSITION_ID
                                                    and GAP2.C_GAUGE_TYPE_POS = POS2.C_GAUGE_TYPE_POS)
                                    and GAP.GAP_INCLUDE_TAX_TARIFF = POS2.POS_INCLUDE_TAX_TARIFF
                                    and GAP.GAP_VALUE_QUANTITY = (select GAP3.GAP_VALUE_QUANTITY
                                                                    from DOC_GAUGE_POSITION GAP3
                                                                   where GAP3.DOC_GAUGE_POSITION_ID = POS2.DOC_GAUGE_POSITION_ID) ) )
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    cursor crDischargePdeCPT(cPositionID in number, cTgtDocumentID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_DOCUMENT_ID
                    , DMT.PAC_THIRD_ID
                    , DMT.PAC_THIRD_ACI_ID
                    , DMT.PAC_THIRD_DELIVERY_ID
                    , DMT.PAC_THIRD_TARIFF_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_MOVEMENT_DATE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , PDE.PDE_BALANCE_QUANTITY DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , GAU.C_ADMIN_DOMAIN
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                    , DOC_GAUGE GAU
                    , GCO_GOOD GOO
                where POS.DOC_DOC_POSITION_ID = cPositionID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and GAU.DOC_GAUGE_ID = DCD.DOC_GAUGE_ID
                  and DCD.NEW_DOCUMENT_ID = cTgtDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    --
    vTGT_PAC_THIRD_CDA_ID PAC_THIRD.PAC_THIRD_ID%type;
    vTGT_DOC_GAUGE_ID     DOC_GAUGE.DOC_GAUGE_ID%type;
    vTGT_C_ADMIN_DOMAIN   DOC_GAUGE.C_ADMIN_DOMAIN%type;
    vConvertFactorCalc    GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    --
    vTplDcd               V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vTplDcdCpt            V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
  begin
    -- Informations du document cible
    select DMT.PAC_THIRD_CDA_ID
         , DMT.DOC_GAUGE_ID
         , GAU.C_ADMIN_DOMAIN
      into vTGT_PAC_THIRD_CDA_ID
         , vTGT_DOC_GAUGE_ID
         , vTGT_C_ADMIN_DOMAIN
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
     where DMT.DOC_DOCUMENT_ID = aTgtDocumentID
       and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    -- Liste des détails du document source
    for vTplDischargePde in crDischargePde(aSrcPositionID, vTGT_DOC_GAUGE_ID) loop
      -- Traitement du changement de partenaire. Si le partenaire source est différent du partenaire cible,
      -- Il faut rechercher le facteur de conversion calculé.
      vConvertFactorCalc                    :=
        GCO_FUNCTIONS.GetThirdConvertFactor(vTplDischargePde.GCO_GOOD_ID
                                          , vTplDischargePde.PAC_THIRD_CDA_ID
                                          , vTplDischargePde.C_GAUGE_TYPE_POS
                                          , null
                                          , vTGT_PAC_THIRD_CDA_ID
                                          , vTGT_C_ADMIN_DOMAIN
                                           );
      vTplDcd                               := null;
      vTplDcd.DOC_POSITION_DETAIL_ID        := vTplDischargePde.DOC_POSITION_DETAIL_ID;
      vTplDcd.NEW_DOCUMENT_ID               := aTgtDocumentID;
      vTplDcd.C_PDE_CREATE_MODE             := nvl(DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE, '930');
      vTplDcd.CRG_SELECT                    := vTplDischargePde.CRG_SELECT;
      vTplDcd.DOC_GAUGE_FLOW_ID             := vTplDischargePde.DOC_GAUGE_FLOW_ID;
      vTplDcd.DOC_POSITION_ID               := vTplDischargePde.DOC_POSITION_ID;
      vTplDcd.DOC_DOC_POSITION_ID           := vTplDischargePde.DOC_DOC_POSITION_ID;
      vTplDcd.DOC_DOC_POSITION_DETAIL_ID    := vTplDischargePde.DOC_DOC_POSITION_DETAIL_ID;
      vTplDcd.DOC2_DOC_POSITION_DETAIL_ID   := vTplDischargePde.DOC2_DOC_POSITION_DETAIL_ID;
      vTplDcd.GCO_GOOD_ID                   := vTplDischargePde.GCO_GOOD_ID;
      vTplDcd.STM_LOCATION_ID               := vTplDischargePde.STM_LOCATION_ID;
      vTplDcd.STM_STM_LOCATION_ID           := vTplDischargePde.STM_STM_LOCATION_ID;
      vTplDcd.GCO_CHARACTERIZATION_ID       := vTplDischargePde.GCO_CHARACTERIZATION_ID;
      vTplDcd.GCO_GCO_CHARACTERIZATION_ID   := vTplDischargePde.GCO_GCO_CHARACTERIZATION_ID;
      vTplDcd.GCO2_GCO_CHARACTERIZATION_ID  := vTplDischargePde.GCO2_GCO_CHARACTERIZATION_ID;
      vTplDcd.GCO3_GCO_CHARACTERIZATION_ID  := vTplDischargePde.GCO3_GCO_CHARACTERIZATION_ID;
      vTplDcd.GCO4_GCO_CHARACTERIZATION_ID  := vTplDischargePde.GCO4_GCO_CHARACTERIZATION_ID;
      vTplDcd.DIC_PDE_FREE_TABLE_1_ID       := vTplDischargePde.DIC_PDE_FREE_TABLE_1_ID;
      vTplDcd.DIC_PDE_FREE_TABLE_2_ID       := vTplDischargePde.DIC_PDE_FREE_TABLE_2_ID;
      vTplDcd.DIC_PDE_FREE_TABLE_3_ID       := vTplDischargePde.DIC_PDE_FREE_TABLE_3_ID;
      vTplDcd.FAL_SCHEDULE_STEP_ID          := vTplDischargePde.FAL_SCHEDULE_STEP_ID;
      vTplDcd.DOC_RECORD_ID                 := vTplDischargePde.DOC_RECORD_ID;
      vTplDcd.DOC_DOCUMENT_ID               := vTplDischargePde.DOC_DOCUMENT_ID;
      vTplDcd.PAC_THIRD_ID                  := vTplDischargePde.PAC_THIRD_ID;
      vTplDcd.PAC_THIRD_ACI_ID              := vTplDischargePde.PAC_THIRD_ACI_ID;
      vTplDcd.PAC_THIRD_DELIVERY_ID         := vTplDischargePde.PAC_THIRD_DELIVERY_ID;
      vTplDcd.PAC_THIRD_TARIFF_ID           := vTplDischargePde.PAC_THIRD_TARIFF_ID;
      vTplDcd.DOC_GAUGE_ID                  := vTplDischargePde.DOC_GAUGE_ID;
      vTplDcd.DOC_GAUGE_RECEIPT_ID          := vTplDischargePde.DOC_GAUGE_RECEIPT_ID;
      vTplDcd.DOC_GAUGE_COPY_ID             := vTplDischargePde.DOC_GAUGE_COPY_ID;
      vTplDcd.C_GAUGE_TYPE_POS              := vTplDischargePde.C_GAUGE_TYPE_POS;
      vTplDcd.DIC_DELAY_UPDATE_TYPE_ID      := vTplDischargePde.DIC_DELAY_UPDATE_TYPE_ID;
      vTplDcd.PDE_BASIS_DELAY               := vTplDischargePde.PDE_BASIS_DELAY;
      vTplDcd.PDE_INTERMEDIATE_DELAY        := vTplDischargePde.PDE_INTERMEDIATE_DELAY;
      vTplDcd.PDE_FINAL_DELAY               := vTplDischargePde.PDE_FINAL_DELAY;
      vTplDcd.PDE_SQM_ACCEPTED_DELAY        := vTplDischargePde.PDE_SQM_ACCEPTED_DELAY;
      vTplDcd.PDE_BASIS_QUANTITY            := vTplDischargePde.PDE_BASIS_QUANTITY;
      vTplDcd.PDE_INTERMEDIATE_QUANTITY     := vTplDischargePde.PDE_INTERMEDIATE_QUANTITY;
      vTplDcd.PDE_FINAL_QUANTITY            := vTplDischargePde.PDE_FINAL_QUANTITY;
      vTplDcd.PDE_BALANCE_QUANTITY          := vTplDischargePde.PDE_BALANCE_QUANTITY;
      vTplDcd.PDE_BALANCE_QUANTITY_PARENT   := vTplDischargePde.PDE_BALANCE_QUANTITY_PARENT;
      vTplDcd.PDE_BASIS_QUANTITY_SU         := vTplDischargePde.PDE_BASIS_QUANTITY_SU;
      vTplDcd.PDE_INTERMEDIATE_QUANTITY_SU  := vTplDischargePde.PDE_INTERMEDIATE_QUANTITY_SU;
      vTplDcd.PDE_FINAL_QUANTITY_SU         := vTplDischargePde.PDE_FINAL_QUANTITY_SU;
      vTplDcd.PDE_MOVEMENT_QUANTITY         := vTplDischargePde.PDE_MOVEMENT_QUANTITY;
      vTplDcd.PDE_MOVEMENT_VALUE            := vTplDischargePde.PDE_MOVEMENT_VALUE;
      vTplDcd.PDE_MOVEMENT_DATE             := vTplDischargePde.PDE_MOVEMENT_DATE;
      vTplDcd.PDE_CHARACTERIZATION_VALUE_1  := vTplDischargePde.PDE_CHARACTERIZATION_VALUE_1;
      vTplDcd.PDE_CHARACTERIZATION_VALUE_2  := vTplDischargePde.PDE_CHARACTERIZATION_VALUE_2;
      vTplDcd.PDE_CHARACTERIZATION_VALUE_3  := vTplDischargePde.PDE_CHARACTERIZATION_VALUE_3;
      vTplDcd.PDE_CHARACTERIZATION_VALUE_4  := vTplDischargePde.PDE_CHARACTERIZATION_VALUE_4;
      vTplDcd.PDE_CHARACTERIZATION_VALUE_5  := vTplDischargePde.PDE_CHARACTERIZATION_VALUE_5;
      vTplDcd.PDE_DELAY_UPDATE_TEXT         := vTplDischargePde.PDE_DELAY_UPDATE_TEXT;
      vTplDcd.PDE_DECIMAL_1                 := vTplDischargePde.PDE_DECIMAL_1;
      vTplDcd.PDE_DECIMAL_2                 := vTplDischargePde.PDE_DECIMAL_2;
      vTplDcd.PDE_DECIMAL_3                 := vTplDischargePde.PDE_DECIMAL_3;
      vTplDcd.PDE_TEXT_1                    := vTplDischargePde.PDE_TEXT_1;
      vTplDcd.PDE_TEXT_2                    := vTplDischargePde.PDE_TEXT_2;
      vTplDcd.PDE_TEXT_3                    := vTplDischargePde.PDE_TEXT_3;
      vTplDcd.PDE_DATE_1                    := vTplDischargePde.PDE_DATE_1;
      vTplDcd.PDE_DATE_2                    := vTplDischargePde.PDE_DATE_2;
      vTplDcd.PDE_DATE_3                    := vTplDischargePde.PDE_DATE_3;
      vTplDcd.PDE_GENERATE_MOVEMENT         := vTplDischargePde.PDE_GENERATE_MOVEMENT;

      -- Qté à décharger
      if     (DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY = 1)
         and (abs(DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY) < abs(vTplDischargePde.DCD_QUANTITY) )
         and (DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY <> 0) then
        vTplDcd.DCD_QUANTITY     := DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY;
        vTplDcd.DCD_QUANTITY_SU  := DOC_POSITION_INITIALIZE.PositionInfo.POS_BASIS_QUANTITY_SU;
      else
        vTplDcd.DCD_QUANTITY                                         := vTplDischargePde.DCD_QUANTITY;
        vTplDcd.DCD_QUANTITY_SU                                      := vTplDischargePde.DCD_QUANTITY_SU;
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY  := 0;
      end if;

      vTplDcd.DCD_BALANCE_FLAG              := vTplDischargePde.DCD_BALANCE_FLAG;
      vTplDcd.POS_CONVERT_FACTOR            := vTplDischargePde.POS_CONVERT_FACTOR;
      vTplDcd.POS_CONVERT_FACTOR_CALC       := nvl(vConvertFactorCalc, vTplDischargePde.POS_CONVERT_FACTOR);

      -- Prix
      if DOC_POSITION_INITIALIZE.PositionInfo.USE_GOOD_PRICE = 1 then
        vTplDcd.POS_GROSS_UNIT_VALUE       := DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE;
        vTplDcd.POS_GROSS_UNIT_VALUE_INCL  := DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE;
      else
        vTplDcd.POS_GROSS_UNIT_VALUE       := vTplDischargePde.POS_GROSS_UNIT_VALUE;
        vTplDcd.POS_GROSS_UNIT_VALUE_INCL  := vTplDischargePde.POS_GROSS_UNIT_VALUE_INCL;
      end if;

      vTplDcd.POS_UNIT_OF_MEASURE_ID        := vTplDischargePde.DIC_UNIT_OF_MEASURE_ID;
      vTplDcd.DCD_DEPLOYED_COMPONENTS       := vTplDischargePde.DCD_DEPLOYED_COMPONENTS;
      vTplDcd.DCD_VISIBLE                   := 0;
      vTplDcd.A_DATECRE                     := vTplDischargePde.NEW_A_DATECRE;
      vTplDcd.A_IDCRE                       := vTplDischargePde.NEW_A_IDCRE;
      vTplDcd.PDE_ST_PT_REJECT              := vTplDischargePde.PDE_ST_PT_REJECT;
      vTplDcd.PDE_ST_CPT_REJECT             := vTplDischargePde.PDE_ST_CPT_REJECT;

      insert into V_DOC_POS_DET_COPY_DISCHARGE
           values vTplDcd;

      -- Changement de position et traitement d'une position kit ou assemblage
      if vTplDischargePde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        -- Traitement des détails de positions composants.
        for vTplDischargePdeCPT in crDischargePdeCPT(vTplDcd.DOC_POSITION_ID, aTgtDocumentID) loop
          vTplDcdCpt                               := null;
          vTplDcdCpt.DOC_POSITION_DETAIL_ID        := vTplDischargePdeCPT.DOC_POSITION_DETAIL_ID;
          vTplDcdCpt.NEW_DOCUMENT_ID               := aTgtDocumentID;
          vTplDcdCpt.C_PDE_CREATE_MODE             := nvl(DOC_POSITION_INITIALIZE.PositionInfo.C_POS_CREATE_MODE, '930');
          vTplDcdCpt.CRG_SELECT                    := vTplDischargePdeCPT.CRG_SELECT;
          vTplDcdCpt.DOC_GAUGE_FLOW_ID             := vTplDischargePdeCPT.DOC_GAUGE_FLOW_ID;
          vTplDcdCpt.DOC_POSITION_ID               := vTplDischargePdeCPT.DOC_POSITION_ID;
          vTplDcdCpt.DOC_DOC_POSITION_ID           := vTplDischargePdeCPT.DOC_DOC_POSITION_ID;
          vTplDcdCpt.DOC_DOC_POSITION_DETAIL_ID    := vTplDischargePdeCPT.DOC_DOC_POSITION_DETAIL_ID;
          vTplDcdCpt.DOC2_DOC_POSITION_DETAIL_ID   := vTplDischargePdeCPT.DOC2_DOC_POSITION_DETAIL_ID;
          vTplDcdCpt.GCO_GOOD_ID                   := vTplDischargePdeCPT.GCO_GOOD_ID;
          vTplDcdCpt.STM_LOCATION_ID               := vTplDischargePdeCPT.STM_LOCATION_ID;
          vTplDcdCpt.STM_STM_LOCATION_ID           := vTplDischargePdeCPT.STM_STM_LOCATION_ID;
          vTplDcdCpt.GCO_CHARACTERIZATION_ID       := vTplDischargePdeCPT.GCO_CHARACTERIZATION_ID;
          vTplDcdCpt.GCO_GCO_CHARACTERIZATION_ID   := vTplDischargePdeCPT.GCO_GCO_CHARACTERIZATION_ID;
          vTplDcdCpt.GCO2_GCO_CHARACTERIZATION_ID  := vTplDischargePdeCPT.GCO2_GCO_CHARACTERIZATION_ID;
          vTplDcdCpt.GCO3_GCO_CHARACTERIZATION_ID  := vTplDischargePdeCPT.GCO3_GCO_CHARACTERIZATION_ID;
          vTplDcdCpt.GCO4_GCO_CHARACTERIZATION_ID  := vTplDischargePdeCPT.GCO4_GCO_CHARACTERIZATION_ID;
          vTplDcdCpt.DIC_PDE_FREE_TABLE_1_ID       := vTplDischargePdeCPT.DIC_PDE_FREE_TABLE_1_ID;
          vTplDcdCpt.DIC_PDE_FREE_TABLE_2_ID       := vTplDischargePdeCPT.DIC_PDE_FREE_TABLE_2_ID;
          vTplDcdCpt.DIC_PDE_FREE_TABLE_3_ID       := vTplDischargePdeCPT.DIC_PDE_FREE_TABLE_3_ID;
          vTplDcdCpt.FAL_SCHEDULE_STEP_ID          := vTplDischargePdeCPT.FAL_SCHEDULE_STEP_ID;
          vTplDcdCpt.DOC_DOCUMENT_ID               := vTplDischargePdeCPT.DOC_DOCUMENT_ID;
          vTplDcdCpt.PAC_THIRD_ID                  := vTplDischargePdeCPT.PAC_THIRD_ID;
          vTplDcdCpt.PAC_THIRD_ACI_ID              := vTplDischargePdeCPT.PAC_THIRD_ACI_ID;
          vTplDcdCpt.PAC_THIRD_DELIVERY_ID         := vTplDischargePdeCPT.PAC_THIRD_DELIVERY_ID;
          vTplDcdCpt.PAC_THIRD_TARIFF_ID           := vTplDischargePdeCPT.PAC_THIRD_TARIFF_ID;
          vTplDcdCpt.DOC_GAUGE_ID                  := vTplDischargePdeCPT.DOC_GAUGE_ID;
          vTplDcdCpt.DOC_GAUGE_RECEIPT_ID          := vTplDischargePdeCPT.DOC_GAUGE_RECEIPT_ID;
          vTplDcdCpt.DOC_GAUGE_COPY_ID             := vTplDischargePdeCPT.DOC_GAUGE_COPY_ID;
          vTplDcdCpt.C_GAUGE_TYPE_POS              := vTplDischargePdeCPT.C_GAUGE_TYPE_POS;
          vTplDcdCpt.DIC_DELAY_UPDATE_TYPE_ID      := vTplDischargePdeCPT.DIC_DELAY_UPDATE_TYPE_ID;
          vTplDcdCpt.PDE_BASIS_DELAY               := vTplDischargePdeCPT.PDE_BASIS_DELAY;
          vTplDcdCpt.PDE_INTERMEDIATE_DELAY        := vTplDischargePdeCPT.PDE_INTERMEDIATE_DELAY;
          vTplDcdCpt.PDE_FINAL_DELAY               := vTplDischargePdeCPT.PDE_FINAL_DELAY;
          vTplDcdCpt.PDE_SQM_ACCEPTED_DELAY        := vTplDischargePdeCPT.PDE_SQM_ACCEPTED_DELAY;
          vTplDcdCpt.PDE_BASIS_QUANTITY            := vTplDischargePdeCPT.PDE_BASIS_QUANTITY;
          vTplDcdCpt.PDE_INTERMEDIATE_QUANTITY     := vTplDischargePdeCPT.PDE_INTERMEDIATE_QUANTITY;
          vTplDcdCpt.PDE_FINAL_QUANTITY            := vTplDischargePdeCPT.PDE_FINAL_QUANTITY;
          vTplDcdCpt.PDE_BALANCE_QUANTITY          := vTplDischargePdeCPT.PDE_BALANCE_QUANTITY;
          vTplDcdCpt.PDE_BALANCE_QUANTITY_PARENT   := vTplDischargePdeCPT.PDE_BALANCE_QUANTITY_PARENT;
          vTplDcdCpt.PDE_BASIS_QUANTITY_SU         := vTplDischargePdeCPT.PDE_BASIS_QUANTITY_SU;
          vTplDcdCpt.PDE_INTERMEDIATE_QUANTITY_SU  := vTplDischargePdeCPT.PDE_INTERMEDIATE_QUANTITY_SU;
          vTplDcdCpt.PDE_FINAL_QUANTITY_SU         := vTplDischargePdeCPT.PDE_FINAL_QUANTITY_SU;
          vTplDcdCpt.PDE_MOVEMENT_QUANTITY         := vTplDischargePdeCPT.PDE_MOVEMENT_QUANTITY;
          vTplDcdCpt.PDE_MOVEMENT_VALUE            := vTplDischargePdeCPT.PDE_MOVEMENT_VALUE;
          vTplDcdCpt.PDE_MOVEMENT_DATE             := vTplDischargePdeCPT.PDE_MOVEMENT_DATE;
          vTplDcdCpt.PDE_CHARACTERIZATION_VALUE_1  := vTplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_1;
          vTplDcdCpt.PDE_CHARACTERIZATION_VALUE_2  := vTplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_2;
          vTplDcdCpt.PDE_CHARACTERIZATION_VALUE_3  := vTplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_3;
          vTplDcdCpt.PDE_CHARACTERIZATION_VALUE_4  := vTplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_4;
          vTplDcdCpt.PDE_CHARACTERIZATION_VALUE_5  := vTplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_5;
          vTplDcdCpt.PDE_DELAY_UPDATE_TEXT         := vTplDischargePdeCPT.PDE_DELAY_UPDATE_TEXT;
          vTplDcdCpt.PDE_DECIMAL_1                 := vTplDischargePdeCPT.PDE_DECIMAL_1;
          vTplDcdCpt.PDE_DECIMAL_2                 := vTplDischargePdeCPT.PDE_DECIMAL_2;
          vTplDcdCpt.PDE_DECIMAL_3                 := vTplDischargePdeCPT.PDE_DECIMAL_3;
          vTplDcdCpt.PDE_TEXT_1                    := vTplDischargePdeCPT.PDE_TEXT_1;
          vTplDcdCpt.PDE_TEXT_2                    := vTplDischargePdeCPT.PDE_TEXT_2;
          vTplDcdCpt.PDE_TEXT_3                    := vTplDischargePdeCPT.PDE_TEXT_3;
          vTplDcdCpt.PDE_DATE_1                    := vTplDischargePdeCPT.PDE_DATE_1;
          vTplDcdCpt.PDE_DATE_2                    := vTplDischargePdeCPT.PDE_DATE_2;
          vTplDcdCpt.PDE_DATE_3                    := vTplDischargePdeCPT.PDE_DATE_3;
          vTplDcdCpt.PDE_GENERATE_MOVEMENT         := vTplDischargePdeCPT.PDE_GENERATE_MOVEMENT;

          -- Qté à décharger
          if DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BASIS_QUANTITY = 1 then
            vTplDcdCpt.DCD_QUANTITY     := vTplDischargePdeCPT.POS_UTIL_COEFF * vTplDcd.DCD_QUANTITY;
            vTplDcdCpt.DCD_QUANTITY_SU  := vTplDischargePdeCPT.POS_UTIL_COEFF * vTplDcd.DCD_QUANTITY_SU;
          else
            vTplDcdCpt.DCD_QUANTITY     := vTplDischargePdeCPT.DCD_QUANTITY;
            vTplDcdCpt.DCD_QUANTITY_SU  := vTplDischargePdeCPT.DCD_QUANTITY_SU;
          end if;

          vTplDcdCpt.DCD_BALANCE_FLAG              := vTplDischargePdeCPT.DCD_BALANCE_FLAG;
          vTplDcdCpt.POS_CONVERT_FACTOR            := vTplDischargePdeCPT.POS_CONVERT_FACTOR;
          vTplDcdCpt.POS_CONVERT_FACTOR_CALC       := vTplDischargePdeCPT.POS_CONVERT_FACTOR;
          vTplDcdCpt.POS_GROSS_UNIT_VALUE          := vTplDischargePdeCPT.POS_GROSS_UNIT_VALUE;
          vTplDcdCpt.POS_GROSS_UNIT_VALUE_INCL     := vTplDischargePdeCPT.POS_GROSS_UNIT_VALUE_INCL;
          vTplDcdCpt.POS_UNIT_OF_MEASURE_ID        := vTplDischargePdeCPT.DIC_UNIT_OF_MEASURE_ID;
          vTplDcdCpt.POS_UTIL_COEFF                := vTplDischargePdeCPT.POS_UTIL_COEFF;
          vTplDcdCpt.DCD_VISIBLE                   := 0;
          vTplDcdCpt.A_DATECRE                     := vTplDischargePdeCPT.NEW_A_DATECRE;
          vTplDcdCpt.A_IDCRE                       := vTplDischargePdeCPT.NEW_A_IDCRE;
          vTplDcdCpt.PDE_ST_PT_REJECT              := vTplDischargePdeCPT.PDE_ST_PT_REJECT;
          vTplDcdCpt.PDE_ST_CPT_REJECT             := vTplDischargePdeCPT.PDE_ST_CPT_REJECT;

          insert into V_DOC_POS_DET_COPY_DISCHARGE
               values vTplDcdCpt;
        end loop;
      end if;
    end loop;
  end InsertDischargePosDetail;

  /**
  *  procedure ControlInitPositionData
  *  Description
  *    Contrôle les données et si besoin initialise avant l'insertion même dans la table DOC_POSITION
  */
  procedure ControlInitPositionData
  is
    -- Info générales sur la position à créér
    cursor crCreateInfo(
      cDocumentID      DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , cGaugePosID      DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID%type
    , cInvoiceExpiryId DOC_INVOICE_EXPIRY.DOC_INVOICE_EXPIRY_ID%type
    )
    is
      (select DMT.DOC_DOCUMENT_ID
            , DMT.C_DOCUMENT_STATUS
            , DMT.PC_LANG_ID
            , DMT.DOC_GAUGE_ID
            , DMT.PAC_THIRD_ID
            , DMT.PAC_THIRD_ACI_ID
            , DMT.PAC_THIRD_DELIVERY_ID
            , DMT.PAC_THIRD_TARIFF_ID
            , DMT.PAC_THIRD_CDA_ID
            , DMT.PAC_THIRD_VAT_ID
            , DMT.PAC_REPRESENTATIVE_ID
            , DMT.PAC_REPR_ACI_ID
            , DMT.PAC_REPR_DELIVERY_ID
            , DMT.DOC_RECORD_ID
            , DMT.DIC_TYPE_SUBMISSION_ID
            , DMT.ACS_VAT_DET_ACCOUNT_ID
            , DMT.DIC_TARIFF_ID DMT_DIC_TARIFF_ID
            , DMT.DMT_TARIFF_DATE
            , DMT.DMT_DATE_DOCUMENT
            , DMT.DMT_DATE_DELIVERY
            , DMT.DMT_DATE_VALUE
            , DMT.ACS_FINANCIAL_CURRENCY_ID
            , DMT.DMT_RATE_OF_EXCHANGE
            , DMT.DMT_BASE_PRICE
            , DMT.DIC_POS_FREE_TABLE_1_ID
            , DMT.DIC_POS_FREE_TABLE_2_ID
            , DMT.DIC_POS_FREE_TABLE_3_ID
            , DMT.DMT_TEXT_1
            , DMT.DMT_TEXT_2
            , DMT.DMT_TEXT_3
            , DMT.DMT_DECIMAL_1
            , DMT.DMT_DECIMAL_2
            , DMT.DMT_DECIMAL_3
            , DMT.DMT_DATE_1
            , DMT.DMT_DATE_2
            , DMT.DMT_DATE_3
            , DMT.CML_POSITION_ID
            , DMT.ASA_RECORD_ID
            , GAU.C_ADMIN_DOMAIN
            , GAU.GAU_CONFIRM_STATUS
            , GAU.GAU_DOSSIER
            , GAU.GAU_USE_MANAGED_DATA
            , GAS.GAS_BALANCE_STATUS
            , nvl(GAP.DIC_TYPE_MOVEMENT_ID, GAS.DIC_TYPE_MOVEMENT_ID) DIC_TYPE_MOVEMENT_ID
            , GAS.GAS_VAT
            , GAS.C_ROUND_TYPE
            , GAS.GAS_ROUND_AMOUNT
            , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
            , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
            , GAS_INCLUDE_BUDGET_CONTROL
            , GAP.PC_APPLTXT_ID GAP_PC_APPLTXT_ID
            , GAP.GCO_GOOD_ID
            , GAP.STM_MOVEMENT_KIND_ID
            , GAP.STM_STOCK_ID
            , GAP.STM_LOCATION_ID
            , GAP.STM_STM_STOCK_ID
            , GAP.STM_STM_LOCATION_ID
            , GAP.GAP_VALUE_QUANTITY
            , GAP.GAP_INIT_STOCK_PLACE
            , GAP.GAP_MVT_UTILITY
            , GAP.GAP_PCENT
            , GAP.C_GAUGE_TYPE_POS
            , GAP.C_GAUGE_INIT_PRICE_POS
            , GAP.C_ROUND_APPLICATION
            , GAP.DIC_TARIFF_ID GAP_DIC_TARIFF_ID
            , GAP.GAP_FORCED_TARIFF
            , GAP.GAP_WEIGHT
            , GAP.GAP_INCLUDE_TAX_TARIFF
            , GAP.GAP_TRANSFERT_PROPRIETOR
            , GAP.GAP_DIRECT_REMIS
            , GAP.C_DOC_LOT_TYPE
            , GAP.GAP_SUBCONTRACTP_STOCK
            , GAP.GAP_STM_SUBCONTRACTP_STOCK
            , PAC_FUNCTIONS.IsTariffBySet(DMT.PAC_THIRD_TARIFF_ID, GAU.C_ADMIN_DOMAIN) DMT_TARIFF_BY_SET
            , nvl(GAS.GAS_ADDENDUM, 0) GAS_ADDENDUM
         from DOC_DOCUMENT DMT
            , DOC_GAUGE GAU
            , DOC_GAUGE_STRUCTURED GAS
            , DOC_GAUGE_POSITION GAP
        where DMT.DOC_DOCUMENT_ID = cDocumentID
          and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
          and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
          and GAP.DOC_GAUGE_POSITION_ID = cGaugePosID)
      union
      (select DMT_SRC.DOC_DOCUMENT_ID
            , '01' C_DOCUMENT_STATUS
            , DMT_SRC.PC_LANG_ID
            , INX.DOC_GAUGE_ID DOC_GAUGE_ID
            , DMT_SRC.PAC_THIRD_ID
            , DMT_SRC.PAC_THIRD_ACI_ID
            , DMT_SRC.PAC_THIRD_DELIVERY_ID
            , DMT_SRC.PAC_THIRD_TARIFF_ID
            , DMT_SRC.PAC_THIRD_CDA_ID
            , DMT_SRC.PAC_THIRD_VAT_ID
            , DMT_SRC.PAC_REPRESENTATIVE_ID
            , DMT_SRC.PAC_REPR_ACI_ID
            , DMT_SRC.PAC_REPR_DELIVERY_ID
            , DMT_SRC.DOC_RECORD_ID
            , DMT_SRC.DIC_TYPE_SUBMISSION_ID
            , DMT_SRC.ACS_VAT_DET_ACCOUNT_ID
            , DMT_SRC.DIC_TARIFF_ID DMT_DIC_TARIFF_ID
            , DMT_SRC.DMT_TARIFF_DATE
            , INX.INX_ISSUING_DATE DMT_DATE_DOCUMENT
            , null DMT_DATE_DELIVERY
            , INX.INX_ISSUING_DATE DMT_DATE_VALUE
            , DMT_SRC.ACS_FINANCIAL_CURRENCY_ID
            , DMT_SRC.DMT_RATE_OF_EXCHANGE
            , DMT_SRC.DMT_BASE_PRICE
            , DMT_SRC.DIC_POS_FREE_TABLE_1_ID
            , DMT_SRC.DIC_POS_FREE_TABLE_2_ID
            , DMT_SRC.DIC_POS_FREE_TABLE_3_ID
            , DMT_SRC.DMT_TEXT_1
            , DMT_SRC.DMT_TEXT_2
            , DMT_SRC.DMT_TEXT_3
            , DMT_SRC.DMT_DECIMAL_1
            , DMT_SRC.DMT_DECIMAL_2
            , DMT_SRC.DMT_DECIMAL_3
            , DMT_SRC.DMT_DATE_1
            , DMT_SRC.DMT_DATE_2
            , DMT_SRC.DMT_DATE_3
            , null CML_POSITION_ID
            , null ASA_RECORD_ID
            , GAU.C_ADMIN_DOMAIN
            , GAU.GAU_CONFIRM_STATUS
            , GAU.GAU_DOSSIER
            , GAU.GAU_USE_MANAGED_DATA
            , GAS.GAS_BALANCE_STATUS
            , nvl(GAP.DIC_TYPE_MOVEMENT_ID, GAS.DIC_TYPE_MOVEMENT_ID) DIC_TYPE_MOVEMENT_ID
            , GAS.GAS_VAT
            , GAS.C_ROUND_TYPE
            , GAS.GAS_ROUND_AMOUNT
            , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
            , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
            , GAS_INCLUDE_BUDGET_CONTROL
            , GAP.PC_APPLTXT_ID GAP_PC_APPLTXT_ID
            , GAP.GCO_GOOD_ID
            , GAP.STM_MOVEMENT_KIND_ID
            , GAP.STM_STOCK_ID
            , GAP.STM_LOCATION_ID
            , GAP.STM_STM_STOCK_ID
            , GAP.STM_STM_LOCATION_ID
            , GAP.GAP_VALUE_QUANTITY
            , GAP.GAP_INIT_STOCK_PLACE
            , GAP.GAP_MVT_UTILITY
            , GAP.GAP_PCENT
            , GAP.C_GAUGE_TYPE_POS
            , GAP.C_GAUGE_INIT_PRICE_POS
            , GAP.C_ROUND_APPLICATION
            , GAP.DIC_TARIFF_ID GAP_DIC_TARIFF_ID
            , GAP.GAP_FORCED_TARIFF
            , GAP.GAP_WEIGHT
            , GAP.GAP_INCLUDE_TAX_TARIFF
            , GAP.GAP_TRANSFERT_PROPRIETOR
            , GAP.GAP_DIRECT_REMIS
            , GAP.C_DOC_LOT_TYPE
            , GAP.GAP_SUBCONTRACTP_STOCK
            , GAP.GAP_STM_SUBCONTRACTP_STOCK
            , 0 DMT_TARIFF_BY_SET
            , nvl(GAS.GAS_ADDENDUM, 0) GAS_ADDENDUM
         from DOC_GAUGE GAU
            , DOC_GAUGE_STRUCTURED GAS
            , DOC_GAUGE_POSITION GAP
            , DOC_INVOICE_EXPIRY INX
            , DOC_DOCUMENT DMT_SRC
        where GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
          and INX.DOC_INVOICE_EXPIRY_Id = cInvoiceExpiryId
          and DMT_SRC.DOC_DOCUMENT_ID = INX.DOC_DOCUMENT_ID
          and GAU.DOC_GAUGE_ID = INX.DOC_GAUGE_ID
          and GAP.DOC_GAUGE_POSITION_ID = cGaugePosID);

    tplCreateInfo             crCreateInfo%rowtype;

    -- Cumul des position pour les montants de la position Recap
    cursor crGetPosRecapValues(cDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   DOC_POSITION_ID
             , C_GAUGE_TYPE_POS
             , POS_BASIS_QUANTITY
             , POS_VALUE_QUANTITY
             , POS_DISCOUNT_AMOUNT
             , POS_CHARGE_AMOUNT
             , POS_VAT_AMOUNT
             , POS_GROSS_UNIT_VALUE
             , POS_GROSS_UNIT_VALUE_INCL
             , POS_GROSS_UNIT_VALUE2
             , POS_REF_UNIT_VALUE
             , POS_NET_UNIT_VALUE
             , POS_NET_UNIT_VALUE_INCL
             , POS_GROSS_VALUE
             , POS_GROSS_VALUE_INCL
             , POS_NET_VALUE_EXCL
             , POS_NET_VALUE_INCL
             , POS_NET_WEIGHT
             , POS_GROSS_WEIGHT
          from DOC_POSITION
         where DOC_DOCUMENT_ID = cDocumentID
      order by POS_NUMBER desc;

    tplGetPosRecapValues      crGetPosRecapValues%rowtype;
    tot_basis_quantity        doc_position.pos_basis_quantity%type;
    tot_value_quantity        doc_position.pos_value_quantity%type;
    tot_discount_amount       doc_position.pos_discount_amount%type;
    tot_charge_amount         doc_position.pos_charge_amount%type;
    tot_vat_amount            doc_position.pos_vat_amount%type;
    tot_gross_unit_value      doc_position.pos_gross_unit_value%type;
    tot_gross_unit_value_incl doc_position.pos_gross_unit_value_incl%type;
    tot_gross_unit_value2     doc_position.pos_gross_unit_value2%type;
    tot_ref_unit_value        doc_position.pos_ref_unit_value%type;
    tot_net_unit_value        doc_position.pos_net_unit_value%type;
    tot_net_unit_value_incl   doc_position.pos_net_unit_value_incl%type;
    tot_gross_value           doc_position.pos_gross_value%type;
    tot_gross_value_incl      doc_position.pos_gross_value_incl%type;
    tot_net_value_excl        doc_position.pos_net_value_excl%type;
    tot_net_value_incl        doc_position.pos_net_value_incl%type;
    tot_net_weight            doc_position.pos_net_weight%type;
    tot_gross_weight          doc_position.pos_gross_weight%type;
    PosRecapFound             integer;
    PTPosQty                  DOC_POSITION.POS_BASIS_QUANTITY%type;
    StmStmMvtKindID           STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    CDA_StockID               DOC_POSITION.STM_STOCK_ID%type;
    CDA_LocationID            DOC_POSITION.STM_LOCATION_ID%type;
    CDA_PosReference          DOC_POSITION.POS_REFERENCE%type;
    CDA_PosSecondaryReference DOC_POSITION.POS_SECONDARY_REFERENCE%type;
    CDA_PosShortDescription   DOC_POSITION.POS_SHORT_DESCRIPTION%type;
    CDA_PosLongDescription    DOC_POSITION.POS_LONG_DESCRIPTION%type;
    CDA_PosFreeDescription    DOC_POSITION.POS_FREE_DESCRIPTION%type;
    CDA_PosEANCode            DOC_POSITION.POS_EAN_CODE%type;
    CDA_PosEANUCC14Code       DOC_POSITION.POS_EAN_UCC14_CODE%type;
    CDA_PosHIBCPrimaryCode    DOC_POSITION.POS_HIBC_PRIMARY_CODE%type;
    CDA_DicUnitMeasure        DOC_POSITION.DIC_UNIT_OF_MEASURE_ID%type;
    CDA_PosConvertFactor      DOC_POSITION.POS_CONVERT_FACTOR%type;
    CDA_GooNumberDecimal      GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    CDA_Quantity              DOC_POSITION.POS_BASIS_QUANTITY%type;
    PosStockID                DOC_POSITION.STM_STOCK_ID%type;
    PosLocationID             DOC_POSITION.STM_LOCATION_ID%type;
    PosTraStockID             DOC_POSITION.STM_STM_STOCK_ID%type;
    PosTraLocationID          DOC_POSITION.STM_STM_LOCATION_ID%type;
    FinAccountID              DOC_POSITION.ACS_FINANCIAL_ACCOUNT_ID%type;
    DivAccountID              DOC_POSITION.ACS_DIVISION_ACCOUNT_ID%type;
    CpnAccountID              DOC_POSITION.ACS_CPN_ACCOUNT_ID%type;
    CdaAccountID              DOC_POSITION.ACS_CDA_ACCOUNT_ID%type;
    PfAccountID               DOC_POSITION.ACS_PF_ACCOUNT_ID%type;
    PjAccountID               DOC_POSITION.ACS_PJ_ACCOUNT_ID%type;
    AccountInfo               ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    iCalculateAmounts         integer                                       default 1;
    iTransfertRecord          integer                                       default 0;
    iTransfertDescr           integer                                       default 0;
    iTransfertQuantity        integer                                       default 0;
    iTransfertPrice           integer                                       default 0;
    iTransfertStock           integer                                       default 0;
    iTransfertRepr            integer                                       default 0;
    iInitCostPrice            integer                                       default 0;
    iInvertAmount             integer                                       default 0;
    nSrcPosQuantity           DOC_POSITION.POS_BASIS_QUANTITY%type;
    ExistsPosNumber           integer;
    lnSourceSupplierID        PAC_THIRD.PAC_THIRD_ID%type;
    lnTargetSupplierID        PAC_THIRD.PAC_THIRD_ID%type;
    lnGooNumberDecimal        GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
  begin
    -- initialisation des compteurs de totalisation pour les positions de type 6 = Récap.
    tot_basis_quantity                         := 0;
    tot_value_quantity                         := 0;
    tot_discount_amount                        := 0;
    tot_charge_amount                          := 0;
    tot_vat_amount                             := 0;
    tot_gross_unit_value                       := 0;
    tot_gross_unit_value_incl                  := 0;
    tot_gross_unit_value2                      := 0;
    tot_ref_unit_value                         := 0;
    tot_net_unit_value                         := 0;
    tot_net_unit_value_incl                    := 0;
    tot_gross_value                            := 0;
    tot_gross_value_incl                       := 0;
    tot_net_value_excl                         := 0;
    tot_net_value_incl                         := 0;
    tot_net_weight                             := 0;
    tot_gross_weight                           := 0;
    PosRecapFound                              := 0;

    -- Document
    if PositionInfo.DOC_DOCUMENT_ID is null then
      -- Arrêter l'execution de cette procédure
      PositionInfo.A_ERROR          := 1;
      PositionInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de position - L''ID du document est manquant !');
      return;
    end if;

    -- Gabarit
    if PositionInfo.DOC_GAUGE_ID is null then
      select DOC_GAUGE_ID
        into PositionInfo.DOC_GAUGE_ID
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = PositionInfo.DOC_DOCUMENT_ID;
    end if;

    -- Vérifie le type de position à créer et son ID (gabarit position)
    if PositionInfo.DOC_GAUGE_POSITION_ID is null then
      if PositionInfo.C_GAUGE_TYPE_POS is null then
        -- Arrêter l'execution de cette procédure
        PositionInfo.A_ERROR          := 1;
        PositionInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de position - Le type de position est manquant !');
        return;
      else
        -- Recherche l'ID du gabarit position correspondant au type de position C_GAUGE_TYPE_POS
        begin
          -- En sous-traitance d'achat, il faut chercher la position dont le lot est Sous-traitance d'achat
          if (PositionInfo.C_POS_CREATE_MODE = '123') then
            select DOC_GAUGE_POSITION_ID
              into PositionInfo.DOC_GAUGE_POSITION_ID
              from DOC_GAUGE_POSITION
             where DOC_GAUGE_ID = PositionInfo.DOC_GAUGE_ID
               and C_GAUGE_TYPE_POS = PositionInfo.C_GAUGE_TYPE_POS
               and GAP_DEFAULT = 1
               and C_DOC_LOT_TYPE = '001';
          else
            select DOC_GAUGE_POSITION_ID
              into PositionInfo.DOC_GAUGE_POSITION_ID
              from DOC_GAUGE_POSITION
             where DOC_GAUGE_ID = PositionInfo.DOC_GAUGE_ID
               and C_GAUGE_TYPE_POS = PositionInfo.C_GAUGE_TYPE_POS
               and GAP_DEFAULT = 1
               and C_DOC_LOT_TYPE is null;
          end if;
        exception
          when no_data_found then
            -- Arrêter l'execution de cette procédure
            PositionInfo.A_ERROR          := 1;
            PositionInfo.A_ERROR_MESSAGE  :=
                                 PCS.PC_FUNCTIONS.TranslateWord('Création de position - Le type de position spécifié n''a pas été identifié dans le gabarit !');
            return;
        end;
      end if;
    else
      -- Recherche le type de position correspondant au DOC_GAUGE_POSITION_ID
      select C_GAUGE_TYPE_POS
        into PositionInfo.C_GAUGE_TYPE_POS
        from DOC_GAUGE_POSITION
       where DOC_GAUGE_POSITION_ID = PositionInfo.DOC_GAUGE_POSITION_ID;
    end if;

    -- Informations Gabarit, Gabarit structuré, Gabarit Position et Document de la position à créer
    open crCreateInfo(PositionInfo.DOC_DOCUMENT_ID, PositionInfo.DOC_GAUGE_POSITION_ID, PositionInfo.DOC_INVOICE_EXPIRY_ID);

    --raise_application_error(-20000,PositionInfo.DOC_DOCUMENT_ID||'/'||PositionInfo.DOC_GAUGE_POSITION_ID||'/'||PositionInfo.DOC_GAUGE_ID);
    fetch crCreateInfo
     into tplCreateInfo;

    PositionInfo.PAC_THIRD_CDA_ID              := tplCreateInfo.PAC_THIRD_CDA_ID;
    PositionInfo.PAC_THIRD_VAT_ID              := tplCreateInfo.PAC_THIRD_VAT_ID;

    close crCreateInfo;

    -- ID de la Position
    if PositionInfo.DOC_POSITION_ID is null then
      select INIT_ID_SEQ.nextval
        into PositionInfo.DOC_POSITION_ID
        from dual;
    end if;

    -- Tiers
    PositionInfo.PAC_THIRD_ID                  := tplCreateInfo.PAC_THIRD_ID;
    PositionInfo.PAC_THIRD_ACI_ID              := tplCreateInfo.PAC_THIRD_ACI_ID;
    PositionInfo.PAC_THIRD_DELIVERY_ID         := tplCreateInfo.PAC_THIRD_DELIVERY_ID;
    PositionInfo.PAC_THIRD_TARIFF_ID           := tplCreateInfo.PAC_THIRD_TARIFF_ID;

    -- N° position
    if PositionInfo.USE_POS_NUMBER = 0 then
      PositionInfo.USE_POS_NUMBER  := 1;

      if PositionInfo.SIMULATION = 0 then
        PositionInfo.POS_NUMBER  := DOC_POSITION_FUNCTIONS.GetNewPosNumber(PositionInfo.DOC_DOCUMENT_ID);
      else
        PositionInfo.POS_NUMBER  := 10;
      end if;
    else
      ExistsPosNumber  := 0;

      select count(*)
        into ExistsPosNumber
        from DOC_POSITION
       where POS_NUMBER = PositionInfo.POS_NUMBER
         and DOC_DOCUMENT_ID = PositionInfo.DOC_DOCUMENT_ID;

      if not ExistsPosNumber = 0 then
        PositionInfo.POS_NUMBER  := DOC_POSITION_FUNCTIONS.GetNewPosNumber(PositionInfo.DOC_DOCUMENT_ID);
      end if;
    end if;

    -- Type de mouvement
    PositionInfo.STM_MOVEMENT_KIND_ID          := tplCreateInfo.STM_MOVEMENT_KIND_ID;
    -- Gestion tarif TTC
    PositionInfo.POS_INCLUDE_TAX_TARIFF        := tplCreateInfo.GAP_INCLUDE_TAX_TARIFF;
    -- Transfert stock propriétaire
    PositionInfo.POS_TRANSFERT_PROPRIETOR      := tplCreateInfo.GAP_TRANSFERT_PROPRIETOR;
    -- Position de type sous-traitance d'achat
    PositionInfo.C_DOC_LOT_TYPE                := tplCreateInfo.C_DOC_LOT_TYPE;

    -- Initialise la date de création de la position si elle est nulle
    if PositionInfo.A_DATECRE is null then
      PositionInfo.A_DATECRE  := sysdate;
    end if;

    -- Initialise l'ID de la personne qui a créé la position s'il est nul
    if PositionInfo.A_IDCRE is null then
      PositionInfo.A_IDCRE  := PCS.PC_I_LIB_SESSION.GetUserIni;
    end if;

    -- Initialise le type informatif du CPT si position CPT est de type '1'
    if     (    PositionInfo.DOC_DOC_POSITION_ID is not null
            and PositionInfo.SIMULATION = 0)
       and (PositionInfo.C_GAUGE_TYPE_POS = '1') then
      -- Recherche le type de la position PT
      -- Renseigner le type du CPT (71,81,91 ou 101) si l'on a retrouvé la position PT
      select max(C_GAUGE_TYPE_POS || '1')
        into PositionInfo.C_GAUGE_TYPE_POS_CPT
        from DOC_POSITION
       where DOC_POSITION_ID = PositionInfo.DOC_DOC_POSITION_ID;
    end if;

    -- ID de la position PT obligatoire si création d'une pos CPT
    if     (PositionInfo.DOC_DOC_POSITION_ID is null)
       and (    (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(71, 81, 91, 101) )
            or (     (PositionInfo.C_GAUGE_TYPE_POS = '1')
                and (to_number(nvl(PositionInfo.C_GAUGE_TYPE_POS_CPT, '0') ) in(71, 81, 91, 101) ) )
           ) then
      -- Arrêter l'execution de cette procédure
      PositionInfo.A_ERROR          := 1;
      PositionInfo.A_ERROR_MESSAGE  :=
                     PCS.PC_FUNCTIONS.TranslateWord('Création de position - L''ID de la position PT est obligatoire lors de la création d''une position CPT !');
      return;
    end if;

    -- Si position de type Type 6 (Récap) calculer les montants cumuls
    if PositionInfo.C_GAUGE_TYPE_POS = '6' then
      -- Type 6 , Récap
      -- Curseur sur les positions du document
      open crGetPosRecapValues(PositionInfo.DOC_DOCUMENT_ID);

      fetch crGetPosRecapValues
       into tplGetPosRecapValues;

      PosRecapFound  := 0;

      -- Balayer la liste des positions du document dans l'orde décroissant
      -- et s'arreter dès qu'il y a une position récap ou qu'il n'y a plus de positions
      while(PosRecapFound = 0)
       and (crGetPosRecapValues%found) loop
        -- On est tombé sur une pos de type récap., il faut arreter le cumul
        if tplGetPosRecapValues.C_GAUGE_TYPE_POS = '6' then
          PosRecapFound  := 1;
        end if;

        if (PosRecapFound = 0) then
          -- cumul des positions
          tot_basis_quantity         := tot_basis_quantity + tplGetPosRecapValues.pos_basis_quantity;
          tot_value_quantity         := tot_value_quantity + tplGetPosRecapValues.pos_value_quantity;
          tot_discount_amount        := tot_discount_amount + tplGetPosRecapValues.pos_discount_amount;
          tot_charge_amount          := tot_charge_amount + tplGetPosRecapValues.pos_charge_amount;
          tot_vat_amount             := tot_vat_amount + tplGetPosRecapValues.pos_vat_amount;
          tot_gross_unit_value       := tot_gross_unit_value + tplGetPosRecapValues.pos_gross_unit_value;
          tot_gross_unit_value_incl  := tot_gross_unit_value_incl + tplGetPosRecapValues.pos_gross_unit_value_incl;
          tot_gross_unit_value2      := tot_gross_unit_value2 + tplGetPosRecapValues.pos_gross_unit_value2;
          tot_ref_unit_value         := tot_ref_unit_value + tplGetPosRecapValues.pos_ref_unit_value;
          tot_net_unit_value         := tot_net_unit_value + tplGetPosRecapValues.pos_net_unit_value;
          tot_net_unit_value_incl    := tot_net_unit_value_incl + tplGetPosRecapValues.pos_net_unit_value_incl;
          tot_gross_value            := tot_gross_value + tplGetPosRecapValues.pos_gross_value;
          tot_gross_value_incl       := tot_gross_value_incl + tplGetPosRecapValues.pos_gross_value_incl;
          tot_net_value_excl         := tot_net_value_excl + tplGetPosRecapValues.pos_net_value_excl;
          tot_net_value_incl         := tot_net_value_incl + tplGetPosRecapValues.pos_net_value_incl;
          tot_net_weight             := tot_net_weight + tplGetPosRecapValues.pos_net_weight;
          tot_gross_weight           := tot_gross_weight + tplGetPosRecapValues.pos_gross_weight;
        end if;

        fetch crGetPosRecapValues
         into tplGetPosRecapValues;
      end loop;

      close crGetPosRecapValues;
    end if;

    -- 'INSERT' - En création pas de flux et autres ...
    PositionInfo.DOC_GAUGE_FLOW_ID             := null;
    PositionInfo.DOC_GAUGE_COPY_ID             := null;
    PositionInfo.DOC_GAUGE_RECEIPT_ID          := null;

    -- Appliquer les arrondis définis sur le gabarit si le prix a été passé par l'utilisateur
    if PositionInfo.USE_GOOD_PRICE = 1 then
      -- Si 1 ou 2, Appliquer l'arrondi monnaie logistique
      if tplCreateInfo.C_ROUND_APPLICATION in('1', '2') then
        select ACS_FUNCTION.PcsRound(PositionInfo.GOOD_PRICE, C_ROUND_TYPE_DOC, FIN_ROUNDED_AMOUNT_DOC)
          into PositionInfo.GOOD_PRICE
          from ACS_FINANCIAL_CURRENCY
         where ACS_FINANCIAL_CURRENCY_ID = tplCreateInfo.ACS_FINANCIAL_CURRENCY_ID;
      end if;

      -- Arrondi gabarit
      select nvl(ACS_FUNCTION.PCSRound(PositionInfo.GOOD_PRICE, tplCreateInfo.C_ROUND_TYPE, tplCreateInfo.GAS_ROUND_AMOUNT), 0)
        into PositionInfo.GOOD_PRICE
        from dual;
    end if;

    -- Bien
    if     (PositionInfo.GCO_GOOD_ID is null)
       and (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(1, 2, 3, 7, 8, 9, 10, 71, 81, 91, 101, 21) ) then
      -- Utiliser le bien défini dans le gabarit position
      if tplCreateInfo.GCO_GOOD_ID is not null then
        PositionInfo.GCO_GOOD_ID  := tplCreateInfo.GCO_GOOD_ID;
      else
        -- Le bien est manquant dans le gabarit position
        -- Arrêter l'execution de cette procédure
        PositionInfo.A_ERROR          := 1;
        PositionInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de position - Le bien est obligatoire pour ce type de position !');
        return;
      end if;
    end if;

    -- Code TVA seulement sur le positions (1, 2, 3, 5, 7, 8, 10 , 91 , 1-91)
    if    (    PositionInfo.C_GAUGE_TYPE_POS = '1'
           and (   PositionInfo.C_GAUGE_TYPE_POS_CPT is null
                or PositionInfo.C_GAUGE_TYPE_POS_CPT = '91') )
       or (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(2, 3, 5, 7, 8, 91, 10, 21) ) then
      if     PositionInfo.USE_ACS_TAX_CODE_ID = 0
         and (tplCreateInfo.GAS_VAT = 1) then
        PositionInfo.USE_ACS_TAX_CODE_ID  := 1;
        -- Recherche code TVA
        PositionInfo.ACS_TAX_CODE_ID      :=
          ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(1
                                                , tplCreateInfo.PAC_THIRD_VAT_ID
                                                , PositionInfo.GCO_GOOD_ID
                                                , null
                                                , null
                                                , tplCreateInfo.C_ADMIN_DOMAIN
                                                , tplCreateInfo.DIC_TYPE_SUBMISSION_ID
                                                , tplCreateInfo.DIC_TYPE_MOVEMENT_ID
                                                , tplCreateInfo.ACS_VAT_DET_ACCOUNT_ID
                                                 );

        if (PositionInfo.ACS_TAX_CODE_ID is null) then
          -- Arrêter l'execution de cette procédure
          PositionInfo.A_ERROR          := 1;
          PositionInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de position - Aucun code TVA n''a été trouvé !');
          return;
        end if;
      else
        if     (PositionInfo.ACS_TAX_CODE_ID is null)
           and (tplCreateInfo.GAS_VAT = 1) then
          -- Arrêter l'execution de cette procédure
          PositionInfo.A_ERROR          := 1;
          PositionInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de position - Le code TVA est obligatoire !');
          return;
        end if;
      end if;
    else
      -- Les positions 4, 6, 9, 71, 81 et 101 n'ont pas de code TVA
      PositionInfo.USE_ACS_TAX_CODE_ID  := 1;
      PositionInfo.ACS_TAX_CODE_ID      := null;
    end if;

    -- Dossier
    -- Dossier géré au niveau du gabarit
    if tplCreateInfo.GAU_DOSSIER = 1 then
      -- Dossier pas init, reprendre celui du document
      if PositionInfo.USE_DOC_RECORD_ID = 0 then
        PositionInfo.USE_DOC_RECORD_ID  := 1;
        PositionInfo.DOC_RECORD_ID      := tplCreateInfo.DOC_RECORD_ID;
      end if;
    else
      PositionInfo.USE_DOC_RECORD_ID  := 1;
      PositionInfo.DOC_RECORD_ID      := null;
    end if;

    -- Dossier - DOC_DOC_RECORD_ID pas init, reprendre celui de la position sinon celui du document
    if PositionInfo.USE_DOC_DOC_RECORD_ID = 0 then
      PositionInfo.USE_DOC_DOC_RECORD_ID  := 1;
      PositionInfo.DOC_DOC_RECORD_ID      := nvl(PositionInfo.DOC_RECORD_ID, tplCreateInfo.DOC_RECORD_ID);
    end if;

    -- Personne
    if PositionInfo.USE_PAC_PERSON_ID = 0 then
      PositionInfo.USE_PAC_PERSON_ID  := 1;
      PositionInfo.PAC_PERSON_ID      := tplCreateInfo.PAC_THIRD_ID;
    end if;

    -- Comptes, Immobilisation, Type de transaction, Informations complémentaires
    if     (    (    PositionInfo.C_GAUGE_TYPE_POS = '1'
                 and (   PositionInfo.C_GAUGE_TYPE_POS_CPT is null
                      or PositionInfo.C_GAUGE_TYPE_POS_CPT = '91') )
            or (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(2, 3, 5, 7, 8, 91, 10, 21) )
           )
       and (   tplCreateInfo.GAS_FINANCIAL = 1
            or tplCreateInfo.GAS_ANALYTICAL = 1) then
      -- Effacer les comtpes pour la recherche si USE_ACCOUNTS = 0
      if PositionInfo.USE_ACCOUNTS = 0 then
        PositionInfo.ACS_FINANCIAL_ACCOUNT_ID  := null;
        PositionInfo.ACS_DIVISION_ACCOUNT_ID   := null;
        PositionInfo.ACS_CPN_ACCOUNT_ID        := null;
        PositionInfo.ACS_CDA_ACCOUNT_ID        := null;
        PositionInfo.ACS_PF_ACCOUNT_ID         := null;
        PositionInfo.ACS_PJ_ACCOUNT_ID         := null;
      end if;

      -- Informations complémentaires gérées
      if tplCreateInfo.GAU_USE_MANAGED_DATA = 1 then
        -- Personne HRM
        if PositionInfo.USE_HRM_PERSON_ID = 1 then
          AccountInfo.DEF_HRM_PERSON  := ACS_I_LIB_LOGISTIC_FINANCIAL.GetEmpNumber(PositionInfo.HRM_PERSON_ID);
        end if;

        -- Immobilisation
        if PositionInfo.USE_FAM_FIXED_ASSETS_ID = 1 then
          AccountInfo.FAM_FIXED_ASSETS_ID  := PositionInfo.FAM_FIXED_ASSETS_ID;
        end if;

        -- Type de transaction
        if PositionInfo.USE_C_FAM_TRANSACTION_TYP = 1 then
          AccountInfo.C_FAM_TRANSACTION_TYP  := PositionInfo.C_FAM_TRANSACTION_TYP;
        end if;

        -- Textes des Informations complémentaires
        if PositionInfo.USE_POS_IMF_TEXT = 1 then
          AccountInfo.DEF_TEXT1  := PositionInfo.POS_IMF_TEXT_1;
          AccountInfo.DEF_TEXT2  := PositionInfo.POS_IMF_TEXT_2;
          AccountInfo.DEF_TEXT3  := PositionInfo.POS_IMF_TEXT_3;
          AccountInfo.DEF_TEXT4  := PositionInfo.POS_IMF_TEXT_4;
          AccountInfo.DEF_TEXT5  := PositionInfo.POS_IMF_TEXT_5;
        end if;

        -- Numériques des Informations complémentaires
        if PositionInfo.USE_POS_IMF_NUMBER = 1 then
          AccountInfo.DEF_NUMBER2  := PositionInfo.POS_IMF_NUMBER_2;
          AccountInfo.DEF_NUMBER3  := PositionInfo.POS_IMF_NUMBER_3;
          AccountInfo.DEF_NUMBER4  := PositionInfo.POS_IMF_NUMBER_4;
          AccountInfo.DEF_NUMBER5  := PositionInfo.POS_IMF_NUMBER_5;
        end if;

        -- Dicos des Informations complémentaires
        if PositionInfo.USE_DIC_IMP_FREE = 1 then
          AccountInfo.DEF_DIC_IMP_FREE1  := PositionInfo.DIC_IMP_FREE1_ID;
          AccountInfo.DEF_DIC_IMP_FREE2  := PositionInfo.DIC_IMP_FREE2_ID;
          AccountInfo.DEF_DIC_IMP_FREE3  := PositionInfo.DIC_IMP_FREE3_ID;
          AccountInfo.DEF_DIC_IMP_FREE4  := PositionInfo.DIC_IMP_FREE4_ID;
          AccountInfo.DEF_DIC_IMP_FREE5  := PositionInfo.DIC_IMP_FREE5_ID;
        end if;
      end if;

      -- Position Valeur
      if PositionInfo.C_GAUGE_TYPE_POS = '5' then
        -- Recherche des comptes
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetAccounts(PositionInfo.GCO_GOOD_ID
                                               , '40'
                                               , tplCreateInfo.C_ADMIN_DOMAIN
                                               , tplCreateInfo.DMT_DATE_DOCUMENT
                                               , null
                                               , tplCreateInfo.DOC_GAUGE_ID
                                               , tplCreateInfo.DOC_DOCUMENT_ID
                                               , PositionInfo.DOC_POSITION_ID
                                               , PositionInfo.DOC_RECORD_ID
                                               , tplCreateInfo.PAC_THIRD_ACI_ID
                                               , PositionInfo.ACS_FINANCIAL_ACCOUNT_ID
                                               , PositionInfo.ACS_DIVISION_ACCOUNT_ID
                                               , PositionInfo.ACS_CPN_ACCOUNT_ID
                                               , PositionInfo.ACS_CDA_ACCOUNT_ID
                                               , PositionInfo.ACS_PF_ACCOUNT_ID
                                               , PositionInfo.ACS_PJ_ACCOUNT_ID
                                               , FinAccountID
                                               , DivAccountID
                                               , CpnAccountID
                                               , CdaAccountID
                                               , PfAccountID
                                               , PjAccountID
                                               , AccountInfo
                                                );
      else
        --raise_application_error(-20000, PositionInfo.GCO_GOOD_ID||'/'||tplCreateInfo.C_ADMIN_DOMAIN||'/'||tplCreateInfo.DOC_GAUGE_ID);
        -- Recherche des comptes
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetAccounts(PositionInfo.GCO_GOOD_ID
                                               , '10'
                                               , tplCreateInfo.C_ADMIN_DOMAIN
                                               , tplCreateInfo.DMT_DATE_DOCUMENT
                                               , PositionInfo.GCO_GOOD_ID
                                               , tplCreateInfo.DOC_GAUGE_ID
                                               , tplCreateInfo.DOC_DOCUMENT_ID
                                               , PositionInfo.DOC_POSITION_ID
                                               , PositionInfo.DOC_RECORD_ID
                                               , tplCreateInfo.PAC_THIRD_ACI_ID
                                               , PositionInfo.ACS_FINANCIAL_ACCOUNT_ID
                                               , PositionInfo.ACS_DIVISION_ACCOUNT_ID
                                               , PositionInfo.ACS_CPN_ACCOUNT_ID
                                               , PositionInfo.ACS_CDA_ACCOUNT_ID
                                               , PositionInfo.ACS_PF_ACCOUNT_ID
                                               , PositionInfo.ACS_PJ_ACCOUNT_ID
                                               , FinAccountID
                                               , DivAccountID
                                               , CpnAccountID
                                               , CdaAccountID
                                               , PfAccountID
                                               , PjAccountID
                                               , AccountInfo
                                                );
      end if;

      -- Comptes
      PositionInfo.USE_ACCOUNTS              := 1;
      PositionInfo.ACS_FINANCIAL_ACCOUNT_ID  := FinAccountID;
      PositionInfo.ACS_DIVISION_ACCOUNT_ID   := DivAccountID;
      PositionInfo.ACS_CPN_ACCOUNT_ID        := CpnAccountID;
      PositionInfo.ACS_CDA_ACCOUNT_ID        := CdaAccountID;
      PositionInfo.ACS_PF_ACCOUNT_ID         := PfAccountID;
      PositionInfo.ACS_PJ_ACCOUNT_ID         := PjAccountID;

      -- Informations complémentaires gérées
      if tplCreateInfo.GAU_USE_MANAGED_DATA = 1 then
        -- Immobilisation
        if PositionInfo.USE_FAM_FIXED_ASSETS_ID = 0 then
          PositionInfo.USE_FAM_FIXED_ASSETS_ID  := 1;
          PositionInfo.FAM_FIXED_ASSETS_ID      := AccountInfo.FAM_FIXED_ASSETS_ID;
        end if;

        -- Type de transaction
        if PositionInfo.USE_C_FAM_TRANSACTION_TYP = 0 then
          PositionInfo.USE_C_FAM_TRANSACTION_TYP  := 1;
          PositionInfo.C_FAM_TRANSACTION_TYP      := AccountInfo.C_FAM_TRANSACTION_TYP;
        end if;

        -- Personne HRM
        if PositionInfo.USE_HRM_PERSON_ID = 0 then
          PositionInfo.USE_HRM_PERSON_ID  := 1;
          PositionInfo.HRM_PERSON_ID      := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(AccountInfo.DEF_HRM_PERSON);
        end if;

        -- Textes des Informations complémentaires
        if PositionInfo.USE_POS_IMF_TEXT = 0 then
          PositionInfo.USE_POS_IMF_TEXT  := 1;
          PositionInfo.POS_IMF_TEXT_1    := AccountInfo.DEF_TEXT1;
          PositionInfo.POS_IMF_TEXT_2    := AccountInfo.DEF_TEXT2;
          PositionInfo.POS_IMF_TEXT_3    := AccountInfo.DEF_TEXT3;
          PositionInfo.POS_IMF_TEXT_4    := AccountInfo.DEF_TEXT4;
          PositionInfo.POS_IMF_TEXT_5    := AccountInfo.DEF_TEXT5;
        end if;

        -- Numériques des Informations complémentaires
        if PositionInfo.USE_POS_IMF_NUMBER = 0 then
          PositionInfo.USE_POS_IMF_NUMBER  := 1;
          PositionInfo.POS_IMF_NUMBER_2    := AccountInfo.DEF_NUMBER2;
          PositionInfo.POS_IMF_NUMBER_3    := AccountInfo.DEF_NUMBER3;
          PositionInfo.POS_IMF_NUMBER_4    := AccountInfo.DEF_NUMBER4;
          PositionInfo.POS_IMF_NUMBER_5    := AccountInfo.DEF_NUMBER5;
        end if;

        -- Dicos des Informations complémentaires
        if PositionInfo.USE_DIC_IMP_FREE = 0 then
          PositionInfo.USE_DIC_IMP_FREE  := 1;
          PositionInfo.DIC_IMP_FREE1_ID  := AccountInfo.DEF_DIC_IMP_FREE1;
          PositionInfo.DIC_IMP_FREE2_ID  := AccountInfo.DEF_DIC_IMP_FREE2;
          PositionInfo.DIC_IMP_FREE3_ID  := AccountInfo.DEF_DIC_IMP_FREE3;
          PositionInfo.DIC_IMP_FREE4_ID  := AccountInfo.DEF_DIC_IMP_FREE4;
          PositionInfo.DIC_IMP_FREE5_ID  := AccountInfo.DEF_DIC_IMP_FREE5;
        end if;
      else
        -- Immobilisation
        PositionInfo.USE_FAM_FIXED_ASSETS_ID    := 1;
        PositionInfo.FAM_FIXED_ASSETS_ID        := null;
        -- Type de transaction
        PositionInfo.USE_C_FAM_TRANSACTION_TYP  := 1;
        PositionInfo.C_FAM_TRANSACTION_TYP      := null;
        -- Personne HRM
        PositionInfo.USE_HRM_PERSON_ID          := 1;
        PositionInfo.HRM_PERSON_ID              := null;
        -- Textes des Informations complémentaires
        PositionInfo.USE_POS_IMF_TEXT           := 1;
        PositionInfo.POS_IMF_TEXT_1             := null;
        PositionInfo.POS_IMF_TEXT_2             := null;
        PositionInfo.POS_IMF_TEXT_3             := null;
        PositionInfo.POS_IMF_TEXT_4             := null;
        PositionInfo.POS_IMF_TEXT_5             := null;
        -- Numériques des Informations complémentaires
        PositionInfo.USE_POS_IMF_NUMBER         := 1;
        PositionInfo.POS_IMF_NUMBER_2           := null;
        PositionInfo.POS_IMF_NUMBER_3           := null;
        PositionInfo.POS_IMF_NUMBER_4           := null;
        PositionInfo.POS_IMF_NUMBER_5           := null;
        -- Dicos des Informations complémentaires
        PositionInfo.USE_DIC_IMP_FREE           := 1;
        PositionInfo.DIC_IMP_FREE1_ID           := null;
        PositionInfo.DIC_IMP_FREE2_ID           := null;
        PositionInfo.DIC_IMP_FREE3_ID           := null;
        PositionInfo.DIC_IMP_FREE4_ID           := null;
        PositionInfo.DIC_IMP_FREE5_ID           := null;
      end if;
    else
      -- Comptes
      PositionInfo.USE_ACCOUNTS               := 1;
      PositionInfo.ACS_FINANCIAL_ACCOUNT_ID   := null;
      PositionInfo.ACS_DIVISION_ACCOUNT_ID    := null;
      PositionInfo.ACS_CPN_ACCOUNT_ID         := null;
      PositionInfo.ACS_CDA_ACCOUNT_ID         := null;
      PositionInfo.ACS_PF_ACCOUNT_ID          := null;
      PositionInfo.ACS_PJ_ACCOUNT_ID          := null;
      -- Immobilisation
      PositionInfo.USE_FAM_FIXED_ASSETS_ID    := 1;
      PositionInfo.FAM_FIXED_ASSETS_ID        := null;
      -- Type de transaction
      PositionInfo.USE_C_FAM_TRANSACTION_TYP  := 1;
      PositionInfo.C_FAM_TRANSACTION_TYP      := null;
      -- Personne HRM
      PositionInfo.USE_HRM_PERSON_ID          := 1;
      PositionInfo.HRM_PERSON_ID              := null;
      -- Textes des Informations complémentaires
      PositionInfo.USE_POS_IMF_TEXT           := 1;
      PositionInfo.POS_IMF_TEXT_1             := null;
      PositionInfo.POS_IMF_TEXT_2             := null;
      PositionInfo.POS_IMF_TEXT_3             := null;
      PositionInfo.POS_IMF_TEXT_4             := null;
      PositionInfo.POS_IMF_TEXT_5             := null;
      -- Numériques des Informations complémentaires
      PositionInfo.USE_POS_IMF_NUMBER         := 1;
      PositionInfo.POS_IMF_NUMBER_2           := null;
      PositionInfo.POS_IMF_NUMBER_3           := null;
      PositionInfo.POS_IMF_NUMBER_4           := null;
      PositionInfo.POS_IMF_NUMBER_5           := null;
      -- Dicos des Informations complémentaires
      PositionInfo.USE_DIC_IMP_FREE           := 1;
      PositionInfo.DIC_IMP_FREE1_ID           := null;
      PositionInfo.DIC_IMP_FREE2_ID           := null;
      PositionInfo.DIC_IMP_FREE3_ID           := null;
      PositionInfo.DIC_IMP_FREE4_ID           := null;
      PositionInfo.DIC_IMP_FREE5_ID           := null;
    end if;

    -- Recherche les informations des données complémentaires du bien
    if PositionInfo.GCO_GOOD_ID is not null then
      -- Recherche les infos des données compl. (stock, descriptions, ...)
      GCO_FUNCTIONS.GetComplementaryData(PositionInfo.GCO_GOOD_ID
                                       , tplCreateInfo.C_ADMIN_DOMAIN
                                       , tplCreateInfo.PAC_THIRD_CDA_ID
                                       , tplCreateInfo.PC_LANG_ID
                                       , PositionInfo.FAL_SCHEDULE_STEP_ID
                                       , tplCreateInfo.GAP_TRANSFERT_PROPRIETOR
                                       , null   -- ComplDataID
                                       , CDA_StockID
                                       , CDA_LocationID
                                       , CDA_PosReference
                                       , CDA_PosSecondaryReference
                                       , CDA_PosShortDescription
                                       , CDA_PosLongDescription
                                       , CDA_PosFreeDescription
                                       , CDA_PosEANCode
                                       , CDA_PosEANUCC14Code
                                       , CDA_PosHIBCPrimaryCode
                                       , CDA_DicUnitMeasure
                                       , CDA_PosConvertFactor
                                       , CDA_GooNumberDecimal
                                       , CDA_Quantity
                                        );

      select GOO.GOO_NUMBER_OF_DECIMAL
        into lnGooNumberDecimal
        from GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = PositionInfo.GCO_GOOD_ID;
    end if;

    -- Facteur de conversion
    if    to_number(PositionInfo.C_GAUGE_TYPE_POS) in(7, 8, 9, 10)
       or (PositionInfo.DOC_DOC_POSITION_ID is not null) then
      -- le facteur de conversion pour les positions PT et CPT est = 1
      PositionInfo.USE_POS_CONVERT_FACTOR  := 1;
      PositionInfo.POS_CONVERT_FACTOR      := 1;
    else
      if    (PositionInfo.USE_POS_CONVERT_FACTOR = 0)
         or (nvl(PositionInfo.POS_CONVERT_FACTOR, 0) = 0) then
        if nvl(CDA_PosConvertFactor, 0) <> 0 then
          PositionInfo.POS_CONVERT_FACTOR  := CDA_PosConvertFactor;
        else
          PositionInfo.POS_CONVERT_FACTOR  := 1;
        end if;
      end if;
    end if;

    -- Unité de mesure
    if to_number(PositionInfo.C_GAUGE_TYPE_POS) in(4, 5, 6) then
      PositionInfo.USE_DIC_UNIT_OF_MEASURE_ID  := 1;
      PositionInfo.DIC_UNIT_OF_MEASURE_ID      := null;
      PositionInfo.DIC_DIC_UNIT_OF_MEASURE_ID  := null;
    else
      if PositionInfo.USE_DIC_UNIT_OF_MEASURE_ID = 0 then
        PositionInfo.USE_DIC_UNIT_OF_MEASURE_ID  := 1;
        PositionInfo.DIC_UNIT_OF_MEASURE_ID      := CDA_DicUnitMeasure;
      end if;

      -- Unité de mesure de stockage
      if PositionInfo.GCO_GOOD_ID is not null then
        select DIC_UNIT_OF_MEASURE_ID
          into PositionInfo.DIC_DIC_UNIT_OF_MEASURE_ID
          from GCO_GOOD
         where GCO_GOOD_ID = PositionInfo.GCO_GOOD_ID;
      end if;
    end if;

    -- Quantités
    if     (PositionInfo.DOC_DOC_POSITION_ID is not null)
       and (PositionInfo.SIMULATION = 0) then
      -- Création de positions CPT en direct depuis delphi, la position PT n'a pas encore la qté màj
      if PositionInfo.C_POS_CREATE_MODE = '100' then
        -- La qté passée à la création de la position CPT est la qté de la position PT
        PositionInfo.POS_BASIS_QUANTITY  := PositionInfo.POS_BASIS_QUANTITY * PositionInfo.POS_UTIL_COEFF;
      else
        -- Position CPT
        -- Recherche la qté sur la position Parent
        select POS_BASIS_QUANTITY
          into PTPosQty
          from DOC_POSITION
         where DOC_POSITION_ID = PositionInfo.DOC_DOC_POSITION_ID;

        -- Position CPT
        PositionInfo.POS_BASIS_QUANTITY  := PTPosQty * PositionInfo.POS_UTIL_COEFF;
      end if;
    else
      if PositionInfo.C_GAUGE_TYPE_POS = '4' then
        -- Type 4 , Texte
        PositionInfo.POS_BASIS_QUANTITY  := 0;
      elsif PositionInfo.C_GAUGE_TYPE_POS = '5' then
        -- Type 5 , Valeur
        PositionInfo.POS_BASIS_QUANTITY  := 1;
      elsif PositionInfo.C_GAUGE_TYPE_POS = '6' then
        -- Type 6 , Récap
        PositionInfo.POS_BASIS_QUANTITY  := tot_basis_quantity;
      else
        -- Position avec un bien 1,2,3,7,8,9,10
        -- Vérifier que la qté passée par l'utilisateur ne soit pas nulle
        if (PositionInfo.USE_POS_BASIS_QUANTITY = 0) then
          -- Rechercher la qté au niveau de la donnée compl.
          PositionInfo.POS_BASIS_QUANTITY  :=
                             DOC_POSITION_FUNCTIONS.GetPositionQuantity(PositionInfo.GCO_GOOD_ID, tplCreateInfo.PAC_THIRD_CDA_ID, tplCreateInfo.C_ADMIN_DOMAIN);
        end if;
      end if;
    end if;

    PositionInfo.USE_POS_BASIS_QUANTITY        := 1;

    -- Qté valeur
    if PositionInfo.C_GAUGE_TYPE_POS = '6' then
      PositionInfo.POS_VALUE_QUANTITY  := tot_value_quantity;
    else
      if     (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(1, 2, 3, 7, 8, 9, 10, 71, 81, 91, 101, 21) )
         and (tplCreateInfo.GAP_VALUE_QUANTITY = 1) then
        if    (PositionInfo.USE_POS_VALUE_QUANTITY = 0)
           or (PositionInfo.POS_VALUE_QUANTITY is null) then
          PositionInfo.POS_VALUE_QUANTITY  := PositionInfo.POS_BASIS_QUANTITY;
        end if;
      else
        PositionInfo.POS_VALUE_QUANTITY  := PositionInfo.POS_BASIS_QUANTITY;
      end if;
    end if;

    -- Position de type sous-traitance d'achat
    if PositionInfo.C_DOC_LOT_TYPE = '001' then
      -- Rechercher la donnée compl. de sous-traitance d'achat si celle-ci n'est pas encore init
      if PositionInfo.GCO_COMPL_DATA_ID is null then
        PositionInfo.GCO_COMPL_DATA_ID  :=
          GCO_I_LIB_COMPL_DATA.GetDefaultSubCComplDataID(iGoodId         => PositionInfo.GCO_MANUFACTURED_GOOD_ID
                                                       , iSupplierId     => tplCreateInfo.PAC_THIRD_CDA_ID
                                                       , iLinkedGoodId   => PositionInfo.GCO_GOOD_ID
                                                        );
      end if;

      -- Si pas de donnée compl. de sous-traitance d'achat -> Arreter le traitement
      if PositionInfo.GCO_COMPL_DATA_ID is null then
        -- Arrêter l'execution de cette procédure
        PositionInfo.A_ERROR          := 1;
        PositionInfo.A_ERROR_MESSAGE  :=
          PCS.PC_FUNCTIONS.TranslateWord
                       ('Création de position - La donnée complémentaire est obligatoire lors de la création d''une position de type sous-traitance d''achat !');
        return;
      else
        -- Contrôler les données définies dans la donnée compl. de sous-traitance d'achat
        DOC_I_LIB_SUBCONTRACTP.checkComplData(iComplDataId          => PositionInfo.GCO_COMPL_DATA_ID
                                            , iSupplierId           => tplCreateInfo.PAC_THIRD_CDA_ID
                                            , iManufacturedGoodId   => PositionInfo.GCO_MANUFACTURED_GOOD_ID
                                            , iServiceId            => PositionInfo.GCO_GOOD_ID
                                            , oError                => PositionInfo.A_ERROR_MESSAGE
                                             );

        if PositionInfo.A_ERROR_MESSAGE is not null then
          -- Arrêter l'execution de cette procédure
          PositionInfo.A_ERROR  := 1;
          return;
        end if;
      end if;

      -- La qté négative n'est pas autorisée
      if PositionInfo.POS_BASIS_QUANTITY < 0 then
        -- Arrêter l'execution de cette procédure
        PositionInfo.A_ERROR          := 1;
        PositionInfo.A_ERROR_MESSAGE  :=
          PCS.PC_FUNCTIONS.TranslateWord
                                        ('Création de position - La quantité négative n''est pas autorisée pour une position de type sous-traitance d''achat !');
        return;
      end if;
    end if;

    -- Initialiser le produit fabriqué si la position est liée à une opération de sous-traitance
    --   sauf pour les types de position spécifiés dans le test
    if     (PositionInfo.FAL_SCHEDULE_STEP_ID is not null)
       and (PositionInfo.GCO_MANUFACTURED_GOOD_ID is null)
       and (PositionInfo.C_GAUGE_TYPE_POS not in('2', '3', '4', '5', '6') ) then
      begin
        select LOT.GCO_GOOD_ID
          into PositionInfo.GCO_MANUFACTURED_GOOD_ID
          from FAL_TASK_LINK TAL
             , FAL_LOT LOT
         where TAL.FAL_SCHEDULE_STEP_ID = PositionInfo.FAL_SCHEDULE_STEP_ID
           and TAL.FAL_LOT_ID = LOT.FAL_LOT_ID;
      exception
        when no_data_found then
          null;
      end;
    end if;

    -- Garantir que le produit fabriqué soit nul pour les positions des types spécifiés dans le test
    if     (PositionInfo.GCO_MANUFACTURED_GOOD_ID is not null)
       and (PositionInfo.C_GAUGE_TYPE_POS in('2', '3', '4', '5', '6') ) then
      PositionInfo.GCO_MANUFACTURED_GOOD_ID  := null;
    end if;

    -- Effacer les données du champ DOC_DOC_RECORD_ID si le type DOC_RECORD
    -- n'est pas géré dans les info compl
    PositionInfo.USE_DOC_DOC_RECORD_ID         := 1;

    if tplCreateInfo.GAU_USE_MANAGED_DATA = 1 then
      select max(PositionInfo.DOC_DOC_RECORD_ID)
        into PositionInfo.DOC_DOC_RECORD_ID
        from DOC_GAUGE_MANAGED_DATA
       where DOC_GAUGE_ID = PositionInfo.DOC_GAUGE_ID
         and C_DATA_TYP = 'DOC_RECORD';
    else
      PositionInfo.DOC_DOC_RECORD_ID  := null;
    end if;

    -- Si la quantité en unité de stockage est spécifiée, la quantité en unité du document (donnée complémentaires) est recalculée et ensuite recorrigée si la précision
    -- du bien le demande.
    if     (nvl(PositionInfo.POS_BASIS_QUANTITY_SU, 0) <> 0)
       and (nvl(PositionInfo.POS_BASIS_QUANTITY, 0) = 0) then
      -- Convertit la quantité en fonction de l'unité de la donnée complémentaire et effectue un arrondi au plus près en fonction du nombre de décimal
      -- de la donnée complémentaire.
      PositionInfo.POS_BASIS_QUANTITY  :=
                  ACS_FUNCTION.RoundNear(PositionInfo.POS_BASIS_QUANTITY_SU / PositionInfo.POS_CONVERT_FACTOR, 1 / power(10, nvl(CDA_GooNumberDecimal, 0) ), 0);

      -- Redéfini le facteur de conversion s'il n'était pas explicitement spécifié avant.
      if (PositionInfo.USE_POS_CONVERT_FACTOR = 0) then
        PositionInfo.USE_POS_CONVERT_FACTOR  := 1;
        PositionInfo.POS_CONVERT_FACTOR      := PositionInfo.POS_BASIS_QUANTITY_SU / PositionInfo.POS_BASIS_QUANTITY;
      else
        -- Calcul la quantité en unité de stockage pour garantir la cohérence du facteur de conversion en appliquant également un arrondi supérieur en fonction
        -- du nombre de décimal du bien.
        PositionInfo.POS_BASIS_QUANTITY_SU  :=
                       ACS_FUNCTION.RoundNear(PositionInfo.POS_BASIS_QUANTITY * PositionInfo.POS_CONVERT_FACTOR, 1 / power(10, nvl(lnGooNumberDecimal, 0) ), 1);
      end if;
    elsif PositionInfo.POS_BASIS_QUANTITY is not null then
      -- Calcul la quantité en unité de stockage et arrondi supérieur la quantité en unité de stockage en fonction du nombre de décimal du bien.
      PositionInfo.POS_BASIS_QUANTITY_SU  :=
                       ACS_FUNCTION.RoundNear(PositionInfo.POS_BASIS_QUANTITY * PositionInfo.POS_CONVERT_FACTOR, 1 / power(10, nvl(lnGooNumberDecimal, 0) ), 1);
    end if;

    -- Qté intermédiaire et final
    PositionInfo.POS_INTERMEDIATE_QUANTITY     := PositionInfo.POS_BASIS_QUANTITY;
    PositionInfo.POS_FINAL_QUANTITY            := PositionInfo.POS_BASIS_QUANTITY;
    PositionInfo.POS_INTERMEDIATE_QUANTITY_SU  := PositionInfo.POS_BASIS_QUANTITY_SU;
    PositionInfo.POS_FINAL_QUANTITY_SU         := PositionInfo.POS_BASIS_QUANTITY_SU;

    -- Facteur de conversion initial
    if nvl(CDA_PosConvertFactor, 0) <> 0 then
      PositionInfo.POS_CONVERT_FACTOR2  := CDA_PosConvertFactor;
    else
      PositionInfo.POS_CONVERT_FACTOR2  := 1;
    end if;

    -- Stocks et emplacements
    if PositionInfo.GCO_GOOD_ID is not null then
      if PositionInfo.FORCE_STOCK_LOCATION = 0 then
        -- Init des variables avant la recherche des stocks
        -- Utiliser sotck passé en param pour init les variables si demandé par l'utilisateur
        if PositionInfo.USE_STOCK = 1 then
          PosStockID     := PositionInfo.STM_STOCK_ID;
          PosLocationID  := PositionInfo.STM_LOCATION_ID;

          -- On vérifie que l'emplacement soit du stock renseigné
          if     (PosStockID is not null)
             and (PosLocationID is not null) then
            -- Si l'emplacement n'appartient pas au stock renseigné, on garde le stock et on efface l'emplacement
            select nvl(max(STM_STOCK_ID), PosStockID)
                 , max(STM_LOCATION_ID)
              into PosStockID
                 , PosLocationID
              from STM_LOCATION
             where STM_STOCK_ID = PosStockID
               and STM_LOCATION_ID = PosLocationID;
          end if;
        else
          -- Utiliser stock du gabarit position pour init les variables
          PosStockID     := tplCreateInfo.STM_STOCK_ID;
          PosLocationID  := tplCreateInfo.STM_LOCATION_ID;
        end if;

        -- Utiliser sotck passé en param pour init les variables si demandé par l'utilisateur
        if PositionInfo.USE_TRANSFERT_STOCK = 1 then
          PosTraStockID     := PositionInfo.STM_STM_STOCK_ID;
          PosTraLocationID  := PositionInfo.STM_STM_LOCATION_ID;

          -- On vérifie que l'emplacement soit du stock renseigné
          if     (PosTraStockID is not null)
             and (PosTraLocationID is not null) then
            -- Si l'emplacement n'appartient pas au stock renseigné, on garde le stock et on efface l'emplacement
            select nvl(max(STM_STOCK_ID), PosTraStockID)
                 , max(STM_LOCATION_ID)
              into PosTraStockID
                 , PosTraLocationID
              from STM_LOCATION
             where STM_STOCK_ID = PosTraStockID
               and STM_LOCATION_ID = PosTraLocationID;
          end if;
        else
          -- Utiliser stock du gabarit position pour init les variables
          PosTraStockID     := tplCreateInfo.STM_STM_STOCK_ID;
          PosTraLocationID  := tplCreateInfo.STM_STM_LOCATION_ID;
        end if;

        lnSourceSupplierID                := null;
        lnTargetSupplierID                := null;

        if (tplCreateInfo.GAP_SUBCONTRACTP_STOCK = 1) then   -- Demande d'initialisation du stock source avec le stock du sous-traitant
          lnSourceSupplierID  := tplCreateInfo.PAC_THIRD_CDA_ID;
        elsif(tplCreateInfo.GAP_STM_SUBCONTRACTP_STOCK = 1) then   -- Demande d'initialisation du stock cible avec le stock du sous-traitant
          lnTargetSupplierID  := tplCreateInfo.PAC_THIRD_CDA_ID;
        end if;

        DOC_LIB_POSITION.getStockAndLocation(PositionInfo.GCO_GOOD_ID   -- Bien
                                           , tplCreateInfo.PAC_THIRD_ID
                                           , tplCreateInfo.STM_MOVEMENT_KIND_ID   -- Genre de mouvement
                                           , tplCreateInfo.C_ADMIN_DOMAIN
                                           , CDA_StockID   -- Stock du bien (données complémentaires)
                                           , CDA_LocationID   -- Emplacement du bien (données complémentaires)
                                           , null   -- Stock parent
                                           , null   -- Emplacement parent
                                           , null   -- Stock cible parent
                                           , null   -- Emplacement cible parent
                                           , tplCreateInfo.GAP_INIT_STOCK_PLACE   -- Initialisation du stock et de l'emplacement
                                           , tplCreateInfo.GAP_MVT_UTILITY   -- Utilisation du stock du genre de mouvement
                                           , 0   -- Transfert stock et emplacement depuis le parent
                                           , lnSourceSupplierID   -- Sous-traitant permettant l'initialisation du stock source
                                           , lnTargetSupplierID   -- Sous-traitant permettant l'initialisation du stock cible
                                           , PosStockID   -- Stock recherché
                                           , PosLocationID   -- Emplacement recherché
                                           , PosTraStockID   -- Stock cible recherché
                                           , PosTraLocationID   -- Emplacement cible recherché
                                            );
        -- Stock
        PositionInfo.USE_STOCK            := 1;
        PositionInfo.STM_STOCK_ID         := PosStockID;
        PositionInfo.STM_LOCATION_ID      := PosLocationID;
        -- Stock de transfert
        PositionInfo.USE_TRANSFERT_STOCK  := 1;
        PositionInfo.STM_STM_STOCK_ID     := PosTraStockID;
        PositionInfo.STM_STM_LOCATION_ID  := PosTraLocationID;

        -- Stock
        if     (tplCreateInfo.STM_MOVEMENT_KIND_ID is not null)
           and (    (PositionInfo.STM_STOCK_ID is null)
                or (    PositionInfo.STM_LOCATION_ID is null
                    and (STM_FUNCTIONS.IsVirtualStock(PositionInfo.STM_STOCK_ID) = 0) ) ) then
          -- Arrêter l'execution de cette procédure
          PositionInfo.A_ERROR          := 1;
          PositionInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de position - Le stock ou l''emplacement n''a pas été pas renseigné !');
          return;
        end if;

        -- Stock de transfert
          -- Position avec un mouvement
        if tplCreateInfo.STM_MOVEMENT_KIND_ID is not null then
          -- Vérifier si c'est un mouvement de transfert
          select decode(STM_STM_MOVEMENT_KIND_ID, 0, null, STM_STM_MOVEMENT_KIND_ID)
            into StmStmMvtKindID
            from STM_MOVEMENT_KIND
           where STM_MOVEMENT_KIND_ID = tplCreateInfo.STM_MOVEMENT_KIND_ID;

          -- Si c'est un mouvement de transfert, vérifier que le stock et emplacement de transfert soient renseignés
          if     (StmStmMvtKindID is not null)
             and (    (PositionInfo.STM_STM_STOCK_ID is null)
                  or (    PositionInfo.STM_STM_LOCATION_ID is null
                      and (STM_FUNCTIONS.IsVirtualStock(PositionInfo.STM_STM_STOCK_ID) = 0) )
                 ) then
            -- Arrêter l'execution de cette procédure
            PositionInfo.A_ERROR          := 1;
            PositionInfo.A_ERROR_MESSAGE  :=
                                  PCS.PC_FUNCTIONS.TranslateWord('Création de position - Le stock ou l''emplacement de transfert n''a pas été pas renseigné !');
            return;
          end if;

          -- Si ce n'est pas mouvement de transfert, vérifier l'emplacement de transfert ne soit pas renseignés
          if     (StmStmMvtKindID is null)
             and (PositionInfo.STM_STM_LOCATION_ID is not null) then
            PositionInfo.A_ERROR          := 1;
            PositionInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création de position - L''emplacement de transfert ne doit pas être renseigné !');
            return;
          end if;
        else
          -- Pas de mouvement au niveau du gabarit position
          -- Le stock et l'emplacement de transfert ne doivent être renseignés
          -- que si le gabarit gère le stock propriétaire
          if tplCreateInfo.GAP_TRANSFERT_PROPRIETOR = 1 then
            -- Arrêter l'execution de cette procédure
            -- Si le stock ou l'emplacement de transfert ne sont pas renseignés
            if    (PositionInfo.STM_STM_STOCK_ID is null)
               or (    PositionInfo.STM_STM_LOCATION_ID is null
                   and (STM_FUNCTIONS.IsVirtualStock(PositionInfo.STM_STM_STOCK_ID) = 0) ) then
              PositionInfo.A_ERROR          := 1;
              PositionInfo.A_ERROR_MESSAGE  :=
                                  PCS.PC_FUNCTIONS.TranslateWord('Création de position - Le stock ou l''emplacement de transfert n''a pas été pas renseigné !');
              return;
            end if;
          else
            -- Effacer le stock et l'emplacement de transfert
            PositionInfo.USE_TRANSFERT_STOCK  := 1;
            PositionInfo.STM_STM_STOCK_ID     := null;
            PositionInfo.STM_STM_LOCATION_ID  := null;
          end if;
        end if;
      end if;
    else
      -- Position sans bien
      PositionInfo.USE_STOCK            := 1;
      PositionInfo.STM_STM_STOCK_ID     := null;
      PositionInfo.STM_STM_LOCATION_ID  := null;
      PositionInfo.USE_TRANSFERT_STOCK  := 1;
      PositionInfo.STM_STM_STOCK_ID     := null;
      PositionInfo.STM_STM_LOCATION_ID  := null;
    end if;

    -- Init de la qté solde si null
    PositionInfo.POS_BALANCE_QUANTITY          := nvl(PositionInfo.POS_BALANCE_QUANTITY, PositionInfo.POS_BASIS_QUANTITY);

    -- Statut de la position
    --   Les positions de type 4, 5 et 6 sont créées avec le statut Liquidé
    if (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(1, 2, 3, 7, 8, 9, 10, 71, 81, 91, 101, 21) ) then
      -- Statut de la position, qté solde et qté solde valeur
      if tplCreateInfo.GAS_BALANCE_STATUS = 1 then   -- Gabarit statut "A solder" = OUI
        if tplCreateInfo.C_DOCUMENT_STATUS = '01' then   -- Document statut "A confirmer"
          PositionInfo.C_DOC_POS_STATUS       := '01';   -- Statut position "à confirmer"
          PositionInfo.POS_BALANCE_QUANTITY   := PositionInfo.POS_BASIS_QUANTITY;
          PositionInfo.POS_BALANCE_QTY_VALUE  := PositionInfo.POS_VALUE_QUANTITY;
        elsif tplCreateInfo.C_DOCUMENT_STATUS = '04' then   -- Document statut "Liquidé"
          PositionInfo.C_DOC_POS_STATUS       := '04';   -- Statut position "Liquidé"
          PositionInfo.POS_BALANCE_QUANTITY   := 0;
          PositionInfo.POS_BALANCE_QTY_VALUE  := 0;
        elsif tplCreateInfo.C_DOCUMENT_STATUS = '02' then   -- Document statut "A solder"
          PositionInfo.C_DOC_POS_STATUS       := '02';   -- Statut position "A solder"
          PositionInfo.POS_BALANCE_QUANTITY   := PositionInfo.POS_BASIS_QUANTITY;
          PositionInfo.POS_BALANCE_QTY_VALUE  := PositionInfo.POS_VALUE_QUANTITY;
        elsif tplCreateInfo.C_DOCUMENT_STATUS = '03' then   -- Document statut "Soldé partiellement"
          if PositionInfo.POS_BASIS_QUANTITY = PositionInfo.POS_BALANCE_QUANTITY then
            PositionInfo.C_DOC_POS_STATUS  := '02';   -- Statut "à solder"
          elsif PositionInfo.POS_BALANCE_QUANTITY = 0 then
            PositionInfo.C_DOC_POS_STATUS  := '04';   -- Statut "liquidé"
          else
            PositionInfo.C_DOC_POS_STATUS  := '03';   -- Statut "soldé partiellement"
          end if;
        end if;
      else   -- Gabarit statut "A solder" = NON
        PositionInfo.POS_BALANCE_QUANTITY   := 0;
        PositionInfo.POS_BALANCE_QTY_VALUE  := 0;

        if tplCreateInfo.GAU_CONFIRM_STATUS = 1 then   -- Gabarit statut "A confirmer" = OUI
          PositionInfo.C_DOC_POS_STATUS  := '01';   -- Statut position "à confirmer"
        else   -- Gabarit statut "A confirmer" = NON
          PositionInfo.C_DOC_POS_STATUS  := '04';   -- Statut position "liquidé"
        end if;
      end if;
    else
      -- Les positions de type 4, 5 et 6 sont créées avec le statut Liquidé
      PositionInfo.C_DOC_POS_STATUS       := '04';
      PositionInfo.POS_BALANCE_QUANTITY   := 0;
      PositionInfo.POS_BALANCE_QTY_VALUE  := 0;
    end if;

    -- Texte de corps
    if PositionInfo.USE_POS_BODY_TEXT = 0 then
      PositionInfo.USE_POS_BODY_TEXT  := 1;
      PositionInfo.PC_APPLTXT_ID      := tplCreateInfo.GAP_PC_APPLTXT_ID;
      PositionInfo.POS_BODY_TEXT      := PCS.PC_FUNCTIONS.GetApplTxtDescr_comp(tplCreateInfo.GAP_PC_APPLTXT_ID, tplCreateInfo.PC_LANG_ID);
    end if;

    -- Référence position
    -- Description Courte
    -- Description Longue
    -- Description Libre
    -- Code EAN
    if to_number(PositionInfo.C_GAUGE_TYPE_POS) in(4, 6) then
      -- Les champs suivants ne sont pas gérés pour les positions de type 4 et 6 :
      -- Référence position
      PositionInfo.USE_POS_REFERENCE            := 1;
      PositionInfo.POS_REFERENCE                := null;
      -- Référence secondaire position
      PositionInfo.USE_POS_SECONDARY_REFERENCE  := 1;
      PositionInfo.POS_SECONDARY_REFERENCE      := null;
      -- Description Courte
      PositionInfo.USE_POS_SHORT_DESCRIPTION    := 1;
      PositionInfo.POS_SHORT_DESCRIPTION        := null;
      -- Description Longue
      PositionInfo.USE_POS_LONG_DESCRIPTION     := 1;
      PositionInfo.POS_LONG_DESCRIPTION         := null;
      -- Description Libre
      PositionInfo.USE_POS_FREE_DESCRIPTION     := 1;
      PositionInfo.POS_FREE_DESCRIPTION         := null;
      -- Code EAN
      PositionInfo.USE_POS_EAN_CODE             := 1;
      PositionInfo.POS_EAN_CODE                 := null;
      -- Code EAN/UCC14
      PositionInfo.USE_POS_EAN_UCC14_CODE       := 1;
      PositionInfo.POS_EAN_UCC14_CODE           := null;
      -- Code HIBC
      PositionInfo.USE_POS_HIBC_PRIMARY_CODE    := 1;
      PositionInfo.POS_HIBC_PRIMARY_CODE        := null;
    else
      -- Référence position
      if PositionInfo.USE_POS_REFERENCE = 0 then
        PositionInfo.USE_POS_REFERENCE  := 1;
        PositionInfo.POS_REFERENCE      := CDA_PosReference;
      end if;

      -- Référence secondaire position
      if PositionInfo.USE_POS_SECONDARY_REFERENCE = 0 then
        PositionInfo.USE_POS_SECONDARY_REFERENCE  := 1;
        PositionInfo.POS_SECONDARY_REFERENCE      := CDA_PosSecondaryReference;
      end if;

      -- Description Courte
      if PositionInfo.USE_POS_SHORT_DESCRIPTION = 0 then
        PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
        PositionInfo.POS_SHORT_DESCRIPTION      := CDA_PosShortDescription;
      end if;

      -- Description Longue
      if PositionInfo.USE_POS_LONG_DESCRIPTION = 0 then
        PositionInfo.USE_POS_LONG_DESCRIPTION  := 1;
        PositionInfo.POS_LONG_DESCRIPTION      := CDA_PosLongDescription;
      end if;

      -- Description Libre
      if PositionInfo.USE_POS_FREE_DESCRIPTION = 0 then
        PositionInfo.USE_POS_FREE_DESCRIPTION  := 1;
        PositionInfo.POS_FREE_DESCRIPTION      := CDA_PosFreeDescription;
      end if;

      -- Code EAN
      if PositionInfo.USE_POS_EAN_CODE = 0 then
        PositionInfo.USE_POS_EAN_CODE  := 1;
        PositionInfo.POS_EAN_CODE      := CDA_PosEANCode;
      end if;

      -- Code EAN/UCC14
      if PositionInfo.USE_POS_EAN_UCC14_CODE = 0 then
        PositionInfo.USE_POS_EAN_UCC14_CODE  := 1;
        PositionInfo.POS_EAN_UCC14_CODE      := CDA_PosEANUCC14Code;
      end if;

      -- Code HIBC
      if PositionInfo.USE_POS_HIBC_PRIMARY_CODE = 0 then
        PositionInfo.USE_POS_HIBC_PRIMARY_CODE  := 1;
        PositionInfo.POS_HIBC_PRIMARY_CODE      := CDA_PosHIBCPrimaryCode;
      end if;
    end if;

    -- Date de modification
    if PositionInfo.USE_A_DATEMOD = 0 then
      PositionInfo.USE_A_DATEMOD  := 1;
      PositionInfo.A_DATEMOD      := null;
    end if;

    -- ID utilisateur de la modification
    if PositionInfo.USE_A_IDMOD = 0 then
      PositionInfo.USE_A_IDMOD  := 1;
      PositionInfo.A_IDMOD      := null;
    end if;

    -- Niveau
    if PositionInfo.USE_A_RECLEVEL = 0 then
      PositionInfo.USE_A_RECLEVEL  := 1;
      PositionInfo.A_RECLEVEL      := null;
    end if;

    -- Statut du tuple
    if PositionInfo.USE_A_RECSTATUS = 0 then
      PositionInfo.USE_A_RECSTATUS  := 1;
      PositionInfo.A_RECSTATUS      := null;
    end if;

    -- Confirmation
    if PositionInfo.USE_A_CONFIRM = 0 then
      PositionInfo.USE_A_CONFIRM  := 1;
      PositionInfo.A_CONFIRM      := 0;
    end if;

    -- Texte de nomenclature
    if PositionInfo.USE_POS_NOM_TEXT = 0 then
      PositionInfo.USE_POS_NOM_TEXT  := 1;
      PositionInfo.POS_NOM_TEXT      := 0;
    end if;

    -- Dicos libres
    -- Textes libres
    -- Numériques libres
    -- Dates libres
    if to_number(PositionInfo.C_GAUGE_TYPE_POS) in(4, 5, 6) then
      -- Les champs suivants ne sont pas gérés pour les positions de type 4,5,6
      -- Dicos libres
      PositionInfo.USE_DIC_POS_FREE_TABLE   := 1;
      PositionInfo.DIC_POS_FREE_TABLE_1_ID  := null;
      PositionInfo.DIC_POS_FREE_TABLE_2_ID  := null;
      PositionInfo.DIC_POS_FREE_TABLE_3_ID  := null;
      -- Textes libres
      PositionInfo.USE_POS_TEXT             := 1;
      PositionInfo.POS_TEXT_1               := null;
      PositionInfo.POS_TEXT_2               := null;
      PositionInfo.POS_TEXT_3               := null;
      -- Numériques libres
      PositionInfo.USE_POS_DECIMAL          := 1;
      PositionInfo.POS_DECIMAL_1            := null;
      PositionInfo.POS_DECIMAL_2            := null;
      PositionInfo.POS_DECIMAL_3            := null;
      -- Dates libres
      PositionInfo.USE_POS_DATE             := 1;
      PositionInfo.POS_DATE_1               := null;
      PositionInfo.POS_DATE_2               := null;
      PositionInfo.POS_DATE_3               := null;
    else
      -- Dicos libres
      if PositionInfo.USE_DIC_POS_FREE_TABLE = 0 then
        PositionInfo.USE_DIC_POS_FREE_TABLE   := 1;
        PositionInfo.DIC_POS_FREE_TABLE_1_ID  := tplCreateInfo.DIC_POS_FREE_TABLE_1_ID;
        PositionInfo.DIC_POS_FREE_TABLE_2_ID  := tplCreateInfo.DIC_POS_FREE_TABLE_2_ID;
        PositionInfo.DIC_POS_FREE_TABLE_3_ID  := tplCreateInfo.DIC_POS_FREE_TABLE_3_ID;
      end if;

      -- Textes libres
      if PositionInfo.USE_POS_TEXT = 0 then
        PositionInfo.USE_POS_TEXT  := 1;
        PositionInfo.POS_TEXT_1    := tplCreateInfo.DMT_TEXT_1;
        PositionInfo.POS_TEXT_2    := tplCreateInfo.DMT_TEXT_2;
        PositionInfo.POS_TEXT_3    := tplCreateInfo.DMT_TEXT_3;
      end if;

      -- Numériques libres
      if PositionInfo.USE_POS_DECIMAL = 0 then
        PositionInfo.USE_POS_DECIMAL  := 1;
        PositionInfo.POS_DECIMAL_1    := tplCreateInfo.DMT_DECIMAL_1;
        PositionInfo.POS_DECIMAL_2    := tplCreateInfo.DMT_DECIMAL_2;
        PositionInfo.POS_DECIMAL_3    := tplCreateInfo.DMT_DECIMAL_3;
      end if;

      -- Dates libres
      if PositionInfo.USE_POS_DATE = 0 then
        PositionInfo.USE_POS_DATE  := 1;
        PositionInfo.POS_DATE_1    := tplCreateInfo.DMT_DATE_1;
        PositionInfo.POS_DATE_2    := tplCreateInfo.DMT_DATE_2;
        PositionInfo.POS_DATE_3    := tplCreateInfo.DMT_DATE_3;
      end if;
    end if;

    -- Représentant
    if PositionInfo.USE_PAC_REPRESENTATIVE_ID = 0 then
      -- Utiliser le représentant du document
      PositionInfo.USE_PAC_REPRESENTATIVE_ID  := 1;
      PositionInfo.PAC_REPRESENTATIVE_ID      := tplCreateInfo.PAC_REPRESENTATIVE_ID;
    end if;

    -- Représentant facturation
    if PositionInfo.USE_PAC_REPR_ACI_ID = 0 then
      -- Utiliser le représentant facturation du document
      PositionInfo.USE_PAC_REPR_ACI_ID  := 1;
      PositionInfo.PAC_REPR_ACI_ID      := tplCreateInfo.PAC_REPR_ACI_ID;
    end if;

    -- Représentant livraison
    if PositionInfo.USE_PAC_REPR_DELIVERY_ID = 0 then
      -- Utiliser le représentant livraison du document
      PositionInfo.USE_PAC_REPR_DELIVERY_ID  := 1;
      PositionInfo.PAC_REPR_DELIVERY_ID      := tplCreateInfo.PAC_REPR_DELIVERY_ID;
    end if;

    -- Avenant
    if PositionInfo.USE_CML_POSITION_ID = 0 then
      PositionInfo.USE_CML_POSITION_ID  := 1;
      PositionInfo.CML_POSITION_ID      := tplCreateInfo.CML_POSITION_ID;
    end if;

    -- Evenement
    if PositionInfo.USE_CML_EVENTS_ID = 0 then
      PositionInfo.USE_CML_EVENTS_ID  := 1;
      PositionInfo.CML_EVENTS_ID      := null;
    end if;

    -- Dossier SAV
    if PositionInfo.USE_ASA_RECORD_ID = 0 then
      PositionInfo.USE_ASA_RECORD_ID  := 1;
      PositionInfo.ASA_RECORD_ID      := tplCreateInfo.ASA_RECORD_ID;
    end if;

    -- Composant dossier SAV
    if PositionInfo.USE_ASA_RECORD_COMP_ID = 0 then
      PositionInfo.USE_ASA_RECORD_COMP_ID  := 1;
      PositionInfo.ASA_RECORD_COMP_ID      := null;
    end if;

    -- Opération SAV
    if PositionInfo.USE_ASA_RECORD_TASK_ID = 0 then
      PositionInfo.USE_ASA_RECORD_TASK_ID  := 1;
      PositionInfo.ASA_RECORD_TASK_ID      := null;
    end if;

    -- Demandes d'Approvisionnement
    if PositionInfo.USE_FAL_SUPPLY_REQUEST_ID = 0 then
      PositionInfo.USE_FAL_SUPPLY_REQUEST_ID  := 1;
      PositionInfo.FAL_SUPPLY_REQUEST_ID      := null;
    end if;

    -- Personne
    if     PositionInfo.USE_PAC_PERSON_ID = 0
       and PositionInfo.C_GAUGE_TYPE_POS <> '4' then
      PositionInfo.USE_PAC_PERSON_ID  := 1;
      PositionInfo.PAC_PERSON_ID      := tplCreateInfo.PAC_THIRD_ID;
    end if;

    -- Reliquat position
    if PositionInfo.USE_C_POS_DELIVERY_TYP = 0 then
      PositionInfo.USE_C_POS_DELIVERY_TYP  := 1;
      PositionInfo.C_POS_DELIVERY_TYP      := null;
    end if;

    -- Coefficient en %
    if    (tplCreateInfo.GAP_PCENT = 0)
       or (PositionInfo.USE_POS_RATE_FACTOR = 0) then
      PositionInfo.USE_POS_RATE_FACTOR  := 1;
      PositionInfo.POS_RATE_FACTOR      := 0;
    end if;

    -- Date initialisation tarif
    if PositionInfo.USE_POS_TARIFF_DATE = 0 then
      PositionInfo.POS_TARIFF_DATE  := null;
    end if;

    -- Recherche du code tarif et de la valeur unitaire de la position
    if    (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(9, 71, 101) )
       or (    PositionInfo.C_GAUGE_TYPE_POS = '1'
           and to_number(nvl(PositionInfo.C_GAUGE_TYPE_POS_CPT, '0') ) in(71, 101) ) then
      -- Pour les positions 9, 71 et 101 on ne recherche pas de prix
      PositionInfo.DIC_TARIFF_ID                := null;
      PositionInfo.POS_EFFECTIVE_DIC_TARIFF_ID  := null;
      PositionInfo.USE_GOOD_PRICE               := 1;
      PositionInfo.GOOD_PRICE                   := 0;
      PositionInfo.USE_POS_NET_TARIFF           := 1;
      PositionInfo.POS_NET_TARIFF               := 0;
      PositionInfo.USE_POS_SPECIAL_TARIFF       := 1;
      PositionInfo.POS_SPECIAL_TARIFF           := 0;
      PositionInfo.USE_POS_FLAT_RATE            := 1;
      PositionInfo.POS_FLAT_RATE                := 0;
      PositionInfo.USE_POS_TARIFF_UNIT          := 1;
      PositionInfo.POS_TARIFF_UNIT              := 0;
    else
      if     (PositionInfo.USE_GOOD_PRICE = 0)
         and (PositionInfo.GCO_GOOD_ID is not null) then
        PositionInfo.USE_GOOD_PRICE          := 1;
        PositionInfo.USE_POS_NET_TARIFF      := 1;
        PositionInfo.USE_POS_SPECIAL_TARIFF  := 1;
        PositionInfo.USE_POS_FLAT_RATE       := 1;
        PositionInfo.USE_POS_TARIFF_UNIT     := 1;

        declare
          tmpDateRef date;
        begin
          -- Date pour la recherche du prix
          tmpDateRef  := nvl(PositionInfo.POS_TARIFF_DATE, nvl(tplCreateInfo.DMT_TARIFF_DATE, tplCreateInfo.DMT_DATE_DOCUMENT) );
          -- Recherche la valeur unitaire de la position
          DOC_POSITION_FUNCTIONS.GetPosUnitPrice(aGoodID              => PositionInfo.GCO_GOOD_ID
                                               , aQuantity            => PositionInfo.POS_VALUE_QUANTITY
                                               , aConvertFactor       => PositionInfo.POS_CONVERT_FACTOR
                                               , aRecordID            => PositionInfo.DOC_RECORD_ID
                                               , aFalScheduleStepID   => PositionInfo.FAL_SCHEDULE_STEP_ID
                                               , aDateRef             => tmpDateRef
                                               , aAdminDomain         => tplCreateInfo.C_ADMIN_DOMAIN
                                               , aThirdID             => nvl(tplCreateInfo.PAC_THIRD_TARIFF_ID, tplCreateInfo.PAC_THIRD_ID)
                                               , aDmtTariffID         => tplCreateInfo.DMT_DIC_TARIFF_ID
                                               , aDocCurrencyID       => tplCreateInfo.ACS_FINANCIAL_CURRENCY_ID
                                               , aExchangeRate        => tplCreateInfo.DMT_RATE_OF_EXCHANGE
                                               , aBasePrice           => tplCreateInfo.DMT_BASE_PRICE
                                               , aRoundType           => tplCreateInfo.C_ROUND_TYPE
                                               , aRoundAmount         => tplCreateInfo.GAS_ROUND_AMOUNT
                                               , aGapTariffID         => tplCreateInfo.GAP_DIC_TARIFF_ID
                                               , aForceTariff         => tplCreateInfo.GAP_FORCED_TARIFF
                                               , aTypePrice           => tplCreateInfo.C_GAUGE_INIT_PRICE_POS
                                               , aRoundApplication    => tplCreateInfo.C_ROUND_APPLICATION
                                               , aUnitPrice           => PositionInfo.GOOD_PRICE
                                               , aTariffID            => PositionInfo.POS_EFFECTIVE_DIC_TARIFF_ID
                                               , aNetTariff           => PositionInfo.POS_NET_TARIFF
                                               , aSpecialTariff       => PositionInfo.POS_SPECIAL_TARIFF
                                               , aFlatRate            => PositionInfo.POS_FLAT_RATE
                                               , aTariffUnit          => PositionInfo.POS_TARIFF_UNIT
                                                );

          -- correction du prix unitaire pour les composants quand la qté demandée est de 0
          if     PositionInfo.POS_VALUE_QUANTITY = 0
             and PositionInfo.POS_FLAT_RATE = 1
             and (PositionInfo.POS_UTIL_COEFF <> 1) then
            PositionInfo.GOOD_PRICE  := PositionInfo.GOOD_PRICE / PositionInfo.POS_UTIL_COEFF;
          end if;
        end;
      end if;

      if     tplCreateInfo.GAP_FORCED_TARIFF = 1
         and tplCreateInfo.GAP_DIC_TARIFF_ID is not null then
        PositionInfo.DIC_TARIFF_ID  := tplCreateInfo.GAP_DIC_TARIFF_ID;
      else
        PositionInfo.DIC_TARIFF_ID  := nvl(tplCreateInfo.DMT_DIC_TARIFF_ID, tplCreateInfo.GAP_DIC_TARIFF_ID);
      end if;

      -- Tarif net
      if PositionInfo.USE_POS_NET_TARIFF = 0 then
        PositionInfo.USE_POS_NET_TARIFF  := 1;
        PositionInfo.POS_NET_TARIFF      := 0;
      end if;

      -- Tarif "Action"
      if PositionInfo.USE_POS_SPECIAL_TARIFF = 0 then
        PositionInfo.USE_POS_SPECIAL_TARIFF  := 1;
        PositionInfo.POS_SPECIAL_TARIFF      := 0;
      end if;

      -- Tarif forfaitaire
      if PositionInfo.USE_POS_FLAT_RATE = 0 then
        PositionInfo.USE_POS_FLAT_RATE  := 1;
        PositionInfo.POS_FLAT_RATE      := 0;
      end if;

      -- Unité tariffaire
      if PositionInfo.USE_POS_TARIFF_UNIT = 0 then
        PositionInfo.USE_POS_TARIFF_UNIT  := 1;
        PositionInfo.POS_TARIFF_UNIT      := 0;
      end if;
    end if;

    -- Si Tarif net ne pas créer les remises/taxes de la position
    if PositionInfo.POS_NET_TARIFF = 1 then
      PositionInfo.CREATE_DISCOUNT_CHARGE  := 0;
    end if;

    -- Tariffication assortiment
    if (tplCreateInfo.DMT_TARIFF_BY_SET = 0) then
      PositionInfo.USE_POS_TARIFF_SET  := 1;
      PositionInfo.POS_TARIFF_SET      := null;
    else
      if (PositionInfo.USE_POS_TARIFF_SET = 0) then
        PositionInfo.USE_POS_TARIFF_SET  := 1;

        select decode(tplCreateInfo.C_ADMIN_DOMAIN, '1', max(DIC_TARIFF_SET_PURCHASE_ID), '2', max(DIC_TARIFF_SET_SALE_ID) )
          into PositionInfo.POS_TARIFF_SET
          from GCO_GOOD
         where GCO_GOOD_ID = PositionInfo.GCO_GOOD_ID;
      end if;
    end if;

    -- Remise en %
    if    (tplCreateInfo.GAP_DIRECT_REMIS = 0)
       or (PositionInfo.USE_POS_DISCOUNT_RATE = 0) then
      PositionInfo.USE_POS_DISCOUNT_RATE  := 1;
      PositionInfo.POS_DISCOUNT_RATE      := 0;
    end if;

    -- Valeur unitaire remise
    if PositionInfo.USE_POS_DISCOUNT_UNIT_VALUE = 0 then
      PositionInfo.USE_POS_DISCOUNT_UNIT_VALUE  := 1;

      if PositionInfo.POS_DISCOUNT_RATE = 0 then
        PositionInfo.POS_DISCOUNT_UNIT_VALUE  := 0;
      else
        PositionInfo.POS_DISCOUNT_UNIT_VALUE  := PositionInfo.GOOD_PRICE * PositionInfo.POS_DISCOUNT_RATE / 100;
      end if;
    end if;

    -- Poids Net et Brut
    if (tplCreateInfo.GAP_WEIGHT = 1) then
      if (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(1, 2, 3, 21, 71, 81, 91, 101) ) then
        -- Initalisations des poids selon les données du bien
        if PositionInfo.USE_POS_WEIGHT = 0 then
          PositionInfo.USE_POS_WEIGHT    := 1;

          -- Recherche les poids du bien
          select nvl(max(MEA_GROSS_WEIGHT), 0) GROSS_WEIGHT
               , nvl(max(MEA_NET_WEIGHT), 0) NET_WEIGHT
            into PositionInfo.POS_GROSS_WEIGHT
               , PositionInfo.POS_NET_WEIGHT
            from GCO_MEASUREMENT_WEIGHT
           where GCO_GOOD_ID = PositionInfo.GCO_GOOD_ID;

          PositionInfo.POS_GROSS_WEIGHT  := PositionInfo.POS_GROSS_WEIGHT * PositionInfo.POS_BASIS_QUANTITY * PositionInfo.POS_CONVERT_FACTOR;
          PositionInfo.POS_NET_WEIGHT    := PositionInfo.POS_NET_WEIGHT * PositionInfo.POS_BASIS_QUANTITY * PositionInfo.POS_CONVERT_FACTOR;
        end if;
      elsif PositionInfo.C_GAUGE_TYPE_POS = '6' then
        PositionInfo.USE_POS_WEIGHT    := 1;
        PositionInfo.POS_NET_WEIGHT    := tot_net_weight;
        PositionInfo.POS_GROSS_WEIGHT  := tot_gross_weight;
      else
        -- Rem : Les poids sur les positions PT = somme des poids des positions CPT
        --  et comme on est en train de créér la position (PT) les CPT n'existent pas encore
        PositionInfo.USE_POS_WEIGHT    := 1;
        PositionInfo.POS_NET_WEIGHT    := 0;
        PositionInfo.POS_GROSS_WEIGHT  := 0;
      end if;
    else
      -- Poids pas gérés
      PositionInfo.USE_POS_WEIGHT    := 1;
      PositionInfo.POS_NET_WEIGHT    := 0;
      PositionInfo.POS_GROSS_WEIGHT  := 0;
    end if;

    -- Coefficient Utilisation CPT
    if PositionInfo.DOC_DOC_POSITION_ID is not null then
      if    (PositionInfo.POS_UTIL_COEFF is null)
         or (PositionInfo.USE_POS_UTIL_COEFF = 0) then
        PositionInfo.POS_UTIL_COEFF  := 1;
      end if;
    else
      PositionInfo.POS_UTIL_COEFF  := 0;
    end if;

    PositionInfo.USE_POS_UTIL_COEFF            := 1;

    -- N° document partenaire
    -- Référence partenaire
    -- Date document partenaire
    if (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(3, 4, 5) ) then
      -- N° document partenaire
      PositionInfo.USE_POS_PARTNER_NUMBER         := 1;
      PositionInfo.POS_PARTNER_NUMBER             := null;
      -- Référence partenaire
      PositionInfo.USE_POS_PARTNER_REFERENCE      := 1;
      PositionInfo.POS_PARTNER_REFERENCE          := null;
      -- Date document partenaire
      PositionInfo.USE_POS_DATE_PARTNER_DOCUMENT  := 1;
      PositionInfo.POS_DATE_PARTNER_DOCUMENT      := null;
      -- N° position du document partenaire
      PositionInfo.USE_POS_PARTNER_POS_NUMBER     := 1;
      PositionInfo.POS_PARTNER_POS_NUMBER         := null;
    else
      -- N° document partenaire
      if PositionInfo.USE_POS_PARTNER_NUMBER = 0 then
        PositionInfo.USE_POS_PARTNER_NUMBER  := 1;
        PositionInfo.POS_PARTNER_NUMBER      := null;
      end if;

      -- Référence partenaire
      if PositionInfo.USE_POS_PARTNER_REFERENCE = 0 then
        PositionInfo.USE_POS_PARTNER_REFERENCE  := 1;
        PositionInfo.POS_PARTNER_REFERENCE      := null;
      end if;

      -- Date document partenaire
      if PositionInfo.USE_POS_DATE_PARTNER_DOCUMENT = 0 then
        PositionInfo.USE_POS_DATE_PARTNER_DOCUMENT  := 1;
        PositionInfo.POS_DATE_PARTNER_DOCUMENT      := null;
      end if;

      -- N° position du document partenaire
      if PositionInfo.USE_POS_PARTNER_POS_NUMBER = 0 then
        PositionInfo.USE_POS_PARTNER_POS_NUMBER  := 1;
        PositionInfo.POS_PARTNER_POS_NUMBER      := null;
      end if;
    end if;

    -- Prix de revient unitaire
    if     (PositionInfo.GCO_GOOD_ID is not null)
       and (    (PositionInfo.USE_POS_UNIT_COST_PRICE = 0)
            or (PositionInfo.POS_UNIT_COST_PRICE is null) ) then
      if to_number(nvl(PositionInfo.C_GAUGE_TYPE_POS, '0') ) in(8, 9, 10) then
        PositionInfo.POS_UNIT_COST_PRICE  := 0;
      else
        PositionInfo.POS_UNIT_COST_PRICE  :=
               GCO_FUNCTIONS.GetCostPriceWithManagementMode(PositionInfo.GCO_GOOD_ID, nvl(tplCreateInfo.PAC_THIRD_TARIFF_ID, tplCreateInfo.PAC_THIRD_ID), null);
      end if;
    end if;

    -- Montant de taxe
    -- Montant de remise
    if PositionInfo.USE_POSITION_AMOUNTS = 0 then
      if PositionInfo.C_GAUGE_TYPE_POS = '6' then
        if PositionInfo.USE_POSITION_AMOUNTS = 0 then
          PositionInfo.POS_CHARGE_AMOUNT    := tot_charge_amount;
          PositionInfo.POS_DISCOUNT_AMOUNT  := tot_discount_amount;
        end if;
      else
        PositionInfo.POS_CHARGE_AMOUNT    := 0;
        PositionInfo.POS_DISCOUNT_AMOUNT  := 0;
      end if;
    end if;

    -- Calculer les montants si pas déjà fait lors de la reprise des prix en copie/décharge
    if iCalculateAmounts = 1 then
      -- Valeur unitaire brute TTC
      -- Valeur unitaire brute HT
      -- Valeur unitaire brute Composant
      -- Valeur unitaire référence
      if PositionInfo.USE_POSITION_AMOUNTS = 0 then
        if PositionInfo.C_GAUGE_TYPE_POS = '6' then
          PositionInfo.POS_GROSS_UNIT_VALUE       := tot_gross_unit_value;
          PositionInfo.POS_GROSS_UNIT_VALUE_INCL  := tot_gross_unit_value_incl;
          PositionInfo.POS_GROSS_UNIT_VALUE2      := tot_gross_unit_value2;
          PositionInfo.POS_REF_UNIT_VALUE         := tot_ref_unit_value;
        elsif(to_number(PositionInfo.C_GAUGE_TYPE_POS) in(1, 2, 3, 5, 7, 8, 9, 10, 21, 71, 81, 91, 101) ) then
          -- HT
          if tplCreateInfo.GAP_INCLUDE_TAX_TARIFF = 0 then
            -- Valeur unitaire brute TTC
            PositionInfo.POS_GROSS_UNIT_VALUE_INCL  := 0;

            -- Valeur unitaire brute HT
            if    PositionInfo.C_GAUGE_TYPE_POS = '81'
               or (    PositionInfo.C_GAUGE_TYPE_POS = '1'
                   and PositionInfo.C_GAUGE_TYPE_POS_CPT = '81') then
              PositionInfo.POS_GROSS_UNIT_VALUE  := 0;
            else
              PositionInfo.POS_GROSS_UNIT_VALUE  := PositionInfo.GOOD_PRICE;
            end if;

            -- Si en décharge, il faut tenir compte du GAR_INVERT_AMOUNT
            if iInvertAmount = 1 then
              PositionInfo.POS_GROSS_UNIT_VALUE  := -PositionInfo.POS_GROSS_UNIT_VALUE;
            end if;
          else   -- TTC
            -- Valeur unitaire brute HT
            PositionInfo.POS_GROSS_UNIT_VALUE  := 0;

            -- Valeur unitaire brute TTC
            if    PositionInfo.C_GAUGE_TYPE_POS = '81'
               or (    PositionInfo.C_GAUGE_TYPE_POS = '1'
                   and PositionInfo.C_GAUGE_TYPE_POS_CPT = '81') then
              PositionInfo.POS_GROSS_UNIT_VALUE_INCL  := 0;
            else
              PositionInfo.POS_GROSS_UNIT_VALUE_INCL  := PositionInfo.GOOD_PRICE;
            end if;

            -- Si en décharge, il faut tenir compte du GAR_INVERT_AMOUNT
            if iInvertAmount = 1 then
              PositionInfo.POS_GROSS_UNIT_VALUE_INCL  := -PositionInfo.POS_GROSS_UNIT_VALUE_INCL;
            end if;
          end if;

          -- Valeur unitaire brute composant et Valeur unitaire référence
          if    PositionInfo.C_GAUGE_TYPE_POS = '81'
             or (    PositionInfo.C_GAUGE_TYPE_POS = '1'
                 and PositionInfo.C_GAUGE_TYPE_POS_CPT = '81') then
            -- Valeur unitaire brute composant
            PositionInfo.POS_GROSS_UNIT_VALUE2  := PositionInfo.GOOD_PRICE;
            -- Valeur unitaire référence
            PositionInfo.POS_REF_UNIT_VALUE     := 0;
          else
            -- Valeur unitaire brute composant
            PositionInfo.POS_GROSS_UNIT_VALUE2  := 0;
            -- Valeur unitaire référence
            PositionInfo.POS_REF_UNIT_VALUE     := PositionInfo.GOOD_PRICE;
          end if;
        else
          -- Position de type 4
          PositionInfo.POS_GROSS_UNIT_VALUE       := 0;
          PositionInfo.POS_GROSS_UNIT_VALUE_INCL  := 0;
          PositionInfo.POS_GROSS_UNIT_VALUE2      := 0;
          PositionInfo.POS_REF_UNIT_VALUE         := 0;
        end if;
      end if;

      -- Tarif original
      if     (   tplCreateInfo.C_GAUGE_INIT_PRICE_POS = '1'
              or tplCreateInfo.C_GAUGE_INIT_PRICE_POS = '2')
         and (PositionInfo.DIC_TARIFF_ID is not null)
         and to_number(PositionInfo.C_GAUGE_TYPE_POS) not in(4, 5, 6) then
        PositionInfo.POS_TARIFF_INITIALIZED  := PositionInfo.GOOD_PRICE;
      else
        PositionInfo.POS_TARIFF_INITIALIZED  := 0;
      end if;

      -- Valeur brute HT
      -- Valeur brute TTC
      -- Valeur nette HT
      -- Valeur nette TTC
      -- Montant TVA
      if PositionInfo.USE_POSITION_AMOUNTS = 0 then
        if (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(1, 2, 3, 5, 7, 8, 9, 10, 21, 71, 81, 91, 101) ) then
          if tplCreateInfo.GAP_INCLUDE_TAX_TARIFF = 0 then   -- HT
            -- Valeur brute HT
            if tplCreateInfo.GAP_VALUE_QUANTITY = 1 then
              PositionInfo.POS_GROSS_VALUE  := PositionInfo.POS_VALUE_QUANTITY *(PositionInfo.POS_GROSS_UNIT_VALUE - PositionInfo.POS_DISCOUNT_UNIT_VALUE);
            else
              PositionInfo.POS_GROSS_VALUE  := PositionInfo.POS_BASIS_QUANTITY *(PositionInfo.POS_GROSS_UNIT_VALUE - PositionInfo.POS_DISCOUNT_UNIT_VALUE);
            end if;

            -- Valeur brute TTC
            PositionInfo.POS_GROSS_VALUE_INCL  := 0;
            -- Valeur nette HT
            PositionInfo.POS_NET_VALUE_EXCL    := PositionInfo.POS_GROSS_VALUE + PositionInfo.POS_CHARGE_AMOUNT - PositionInfo.POS_DISCOUNT_AMOUNT;
            -- Montant TVA
            ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => PositionInfo.ACS_TAX_CODE_ID
                                     , aRefDate         => nvl(tplCreateInfo.DMT_DATE_DELIVERY, tplCreateInfo.DMT_DATE_VALUE)
                                     , aIncludedVat     => 'E'
                                     , aRoundAmount     => 0
                                     , aNetAmountExcl   => PositionInfo.POS_NET_VALUE_EXCL
                                     , aNetAmountIncl   => PositionInfo.POS_NET_VALUE_INCL
                                     , aVatAmount       => PositionInfo.POS_VAT_AMOUNT
                                      );
          else   -- TTC
            -- Valeur brute TTC
            if tplCreateInfo.GAP_VALUE_QUANTITY = 1 then
              PositionInfo.POS_GROSS_VALUE_INCL  :=
                                               PositionInfo.POS_VALUE_QUANTITY
                                               *(PositionInfo.POS_GROSS_UNIT_VALUE_INCL - PositionInfo.POS_DISCOUNT_UNIT_VALUE);
            else
              PositionInfo.POS_GROSS_VALUE_INCL  :=
                                               PositionInfo.POS_BASIS_QUANTITY
                                               *(PositionInfo.POS_GROSS_UNIT_VALUE_INCL - PositionInfo.POS_DISCOUNT_UNIT_VALUE);
            end if;

            -- Valeur brute HT
            PositionInfo.POS_GROSS_VALUE     := 0;
            -- Valeur nette TTC
            PositionInfo.POS_NET_VALUE_INCL  := PositionInfo.POS_GROSS_VALUE_INCL + PositionInfo.POS_CHARGE_AMOUNT - PositionInfo.POS_DISCOUNT_AMOUNT;
            -- Montant TVA
            ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => PositionInfo.ACS_TAX_CODE_ID
                                     , aRefDate         => nvl(tplCreateInfo.DMT_DATE_DELIVERY, tplCreateInfo.DMT_DATE_VALUE)
                                     , aIncludedVat     => 'I'
                                     , aRoundAmount     => 0
                                     , aNetAmountExcl   => PositionInfo.POS_NET_VALUE_EXCL
                                     , aNetAmountIncl   => PositionInfo.POS_NET_VALUE_INCL
                                     , aVatAmount       => PositionInfo.POS_VAT_AMOUNT
                                      );
          end if;
        elsif PositionInfo.C_GAUGE_TYPE_POS = '4' then
          PositionInfo.POS_GROSS_VALUE_INCL  := 0;
          PositionInfo.POS_GROSS_VALUE       := 0;
          PositionInfo.POS_VAT_AMOUNT        := 0;
          PositionInfo.POS_NET_VALUE_INCL    := 0;
          PositionInfo.POS_NET_VALUE_EXCL    := 0;
        elsif PositionInfo.C_GAUGE_TYPE_POS = '6' then
          if PositionInfo.USE_POSITION_AMOUNTS = 0 then
            PositionInfo.POS_GROSS_VALUE_INCL  := tot_gross_value_incl;
            PositionInfo.POS_GROSS_VALUE       := tot_gross_value;
            PositionInfo.POS_VAT_AMOUNT        := tot_vat_amount;
            PositionInfo.POS_NET_VALUE_INCL    := tot_net_value_incl;
            PositionInfo.POS_NET_VALUE_EXCL    := tot_net_value_excl;
          end if;
        end if;
      end if;

      -- Valeur unitaire nette HT
      -- Valeur unitaire nette TTC
      if PositionInfo.USE_POSITION_AMOUNTS = 0 then
        if (to_number(PositionInfo.C_GAUGE_TYPE_POS) in(1, 2, 3, 5, 7, 8, 9, 10, 21, 71, 81, 91, 101) ) then
          -- Valeur unitaire Nette TTC et HT
          if tplCreateInfo.GAP_VALUE_QUANTITY = 1 then
            if PositionInfo.POS_VALUE_QUANTITY <> 0 then
              -- Valeur unitaire nette TTC
              PositionInfo.POS_NET_UNIT_VALUE_INCL  := PositionInfo.POS_NET_VALUE_INCL / PositionInfo.POS_VALUE_QUANTITY;
              -- Valeur unitaire nette HT
              PositionInfo.POS_NET_UNIT_VALUE       := PositionInfo.POS_NET_VALUE_EXCL / PositionInfo.POS_VALUE_QUANTITY;
            else
              -- Valeur unitaire nette TTC
              PositionInfo.POS_NET_UNIT_VALUE_INCL  := 0;
              -- Valeur unitaire nette HT
              PositionInfo.POS_NET_UNIT_VALUE       := 0;
            end if;
          else
            if PositionInfo.POS_BASIS_QUANTITY <> 0 then
              -- Valeur unitaire nette TTC
              PositionInfo.POS_NET_UNIT_VALUE_INCL  := PositionInfo.POS_NET_VALUE_INCL / PositionInfo.POS_BASIS_QUANTITY;
              -- Valeur unitaire nette HT
              PositionInfo.POS_NET_UNIT_VALUE       := PositionInfo.POS_NET_VALUE_EXCL / PositionInfo.POS_BASIS_QUANTITY;
            else
              -- Valeur unitaire nette TTC
              PositionInfo.POS_NET_UNIT_VALUE_INCL  := 0;
              -- Valeur unitaire nette HT
              PositionInfo.POS_NET_UNIT_VALUE       := 0;
            end if;
          end if;
        elsif PositionInfo.C_GAUGE_TYPE_POS = '6' then
          PositionInfo.POS_NET_UNIT_VALUE_INCL  := tot_net_unit_value_incl;
          PositionInfo.POS_NET_UNIT_VALUE       := tot_net_unit_value;
        else
          PositionInfo.POS_NET_UNIT_VALUE_INCL  := 0;
          PositionInfo.POS_NET_UNIT_VALUE       := 0;
        end if;
      end if;
    end if;

    -- iCalculateAmounts = 1

    -- Avenant de document si géré au niveau du gabarit
    if    (DOC_POSITION_INITIALIZE.PositionInfo.USE_ADDENDUM = 0)
       or (tplCreateInfo.GAS_ADDENDUM = 0) then
      DOC_POSITION_INITIALIZE.PositionInfo.USE_ADDENDUM               := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_ADDENDUM_SRC_POS_ID    := null;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_ADDENDUM_QTY_BALANCED  := null;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_ADDENDUM_VALUE_QTY     := null;
    end if;
  end ControlInitPositionData;
end DOC_POSITION_INITIALIZE;
