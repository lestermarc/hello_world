--------------------------------------------------------
--  DDL for Package Body STM_INTER_STOCK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_INTER_STOCK" 
is
  -- CONSTANTES
  -- C_TRANSFERT_STATUS
  cTransfertStatusToValidate constant char(2) := '01';
  cTransfertStatusValidated  constant char(2) := '02';
  cTransfertStatusFinished   constant char(2) := '03';

  procedure GenerateTransfert(aMode in varchar2, aSessionID in varchar2, aSqlCmd in varchar2, aRegroupPos in number default 0)
  is
  begin
    -- Regroupement des documents, positions
    RegroupTransfertData(aMode, aSqlCmd, aRegroupPos);
    commit;

    -- Création des documents dans la table DOC_INTERFACE
    if aMode = 'SOURCE' then
      GenerateSourceDocuments(aSessionID);
      commit;
    else
      GenerateTargetDocuments(aSessionID);
      commit;
    end if;
  end GenerateTransfert;

  procedure RegroupTransfertData(aMode in varchar2, aSqlCmd in varchar2, aRegroupPos in number)
  is
    newDocID          STM_INTERC_STOCK_TRSF.SIS_DOC_SRC_ID%type;
    newPosID          STM_INTERC_STOCK_TRSF.SIS_POS_SRC_ID%type;

    type TToRegroupType is ref cursor;   -- define weak REF CURSOR type

    crToRegroup       TToRegroupType;
    tmpSqlCmd         varchar2(32000);
    --
    InterStkTransfID  STM_INTERC_STOCK_TRSF.STM_INTERC_STOCK_TRSF_ID%type;
    --
    GoodID            STM_INTERC_STOCK_TRSF.GCO_GOOD_ID%type;
    CompanySrcID      STM_INTERC_STOCK_TRSF.PC_COMP_SRC_ID%type;
    CompanyDstID      STM_INTERC_STOCK_TRSF.PC_COMP_DST_ID%type;
    GaugeSrcID        STM_INTERC_STOCK_TRSF.DOC_GAUGE_SRC_ID%type;
    GaugeDstID        STM_INTERC_STOCK_TRSF.DOC_GAUGE_DST_ID%type;
    ThirdSrcID        STM_INTERC_STOCK_TRSF.PAC_THIRD_SRC_ID%type;
    ThirdDstID        STM_INTERC_STOCK_TRSF.PAC_THIRD_DST_ID%type;
    StockSrcID        STM_INTERC_STOCK_TRSF.STM_STOCK_SRC_ID%type;
    StockDstID        STM_INTERC_STOCK_TRSF.STM_STOCK_DST_ID%type;
    LocationSrcID     STM_INTERC_STOCK_TRSF.STM_LOCATION_SRC_ID%type;
    LocationDstID     STM_INTERC_STOCK_TRSF.STM_LOCATION_DST_ID%type;
    CharID_1          STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_1_ID%type;
    CharID_2          STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_2_ID%type;
    CharID_3          STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_3_ID%type;
    CharID_4          STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_4_ID%type;
    CharID_5          STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_5_ID%type;
    Regroup_01        varchar2(100);
    Regroup_02        varchar2(100);
    Regroup_03        varchar2(100);
    Regroup_04        varchar2(100);
    Regroup_05        varchar2(100);
    Regroup_06        varchar2(100);
    Regroup_07        varchar2(100);
    Regroup_08        varchar2(100);
    Regroup_09        varchar2(100);
    Regroup_10        varchar2(100);
    Regroup_All       varchar2(250);
    ---
    Old_GoodID        STM_INTERC_STOCK_TRSF.GCO_GOOD_ID%type;
    Old_CompanySrcID  STM_INTERC_STOCK_TRSF.PC_COMP_SRC_ID%type;
    Old_CompanyDstID  STM_INTERC_STOCK_TRSF.PC_COMP_DST_ID%type;
    Old_GaugeSrcID    STM_INTERC_STOCK_TRSF.DOC_GAUGE_SRC_ID%type;
    Old_GaugeDstID    STM_INTERC_STOCK_TRSF.DOC_GAUGE_DST_ID%type;
    Old_ThirdSrcID    STM_INTERC_STOCK_TRSF.PAC_THIRD_SRC_ID%type;
    Old_ThirdDstID    STM_INTERC_STOCK_TRSF.PAC_THIRD_DST_ID%type;
    Old_StockSrcID    STM_INTERC_STOCK_TRSF.STM_STOCK_SRC_ID%type;
    Old_StockDstID    STM_INTERC_STOCK_TRSF.STM_STOCK_DST_ID%type;
    Old_LocationSrcID STM_INTERC_STOCK_TRSF.STM_LOCATION_SRC_ID%type;
    Old_LocationDstID STM_INTERC_STOCK_TRSF.STM_LOCATION_DST_ID%type;
    Old_Regroup_01    varchar2(100);
    Old_Regroup_02    varchar2(100);
    Old_Regroup_03    varchar2(100);
    Old_Regroup_04    varchar2(100);
    Old_Regroup_05    varchar2(100);
    Old_Regroup_06    varchar2(100);
    Old_Regroup_07    varchar2(100);
    Old_Regroup_08    varchar2(100);
    Old_Regroup_09    varchar2(100);
    Old_Regroup_10    varchar2(100);
    Old_Regroup_All   varchar2(250);
  begin
    Old_GoodID         := -1;
    Old_CompanySrcID   := -1;
    Old_CompanyDstID   := -1;
    Old_GaugeSrcID     := -1;
    Old_GaugeDstID     := -1;
    Old_ThirdSrcID     := -1;
    Old_ThirdDstID     := -1;
    Old_StockSrcID     := -1;
    Old_StockDstID     := -1;
    Old_LocationSrcID  := -1;
    Old_LocationDstID  := -1;
    Old_Regroup_01     := 'null';
    Old_Regroup_02     := 'null';
    Old_Regroup_03     := 'null';
    Old_Regroup_04     := 'null';
    Old_Regroup_05     := 'null';
    Old_Regroup_06     := 'null';
    Old_Regroup_07     := 'null';
    Old_Regroup_08     := 'null';
    Old_Regroup_09     := 'null';
    Old_Regroup_10     := 'null';
    Old_Regroup_All    := 'null';
    -- commande pour la reprise des données de la cmd utilisateur (champs de regroupement, champ de tri)
    tmpSqlCmd          :=
      'select MAIN.STM_INTERC_STOCK_TRSF_ID                                     ' ||
      '     , MAIN.PC_COMP_SRC_ID                                               ' ||
      '     , MAIN.PC_COMP_DST_ID                                               ' ||
      '     , MAIN.DOC_GAUGE_SRC_ID                                             ' ||
      '     , MAIN.DOC_GAUGE_DST_ID                                             ' ||
      '     , MAIN.PAC_THIRD_SRC_ID                                             ' ||
      '     , MAIN.PAC_THIRD_DST_ID                                             ' ||
      '     , MAIN.GCO_GOOD_ID                                                  ' ||
      '     , MAIN.STM_STOCK_SRC_ID                                             ' ||
      '     , MAIN.STM_LOCATION_SRC_ID                                          ' ||
      '     , MAIN.STM_STOCK_DST_ID                                             ' ||
      '     , MAIN.STM_LOCATION_DST_ID                                          ' ||
      '     , MAIN.GCO_CHARACTERIZATION_1_ID                                    ' ||
      '     , MAIN.GCO_CHARACTERIZATION_2_ID                                    ' ||
      '     , MAIN.GCO_CHARACTERIZATION_3_ID                                    ' ||
      '     , MAIN.GCO_CHARACTERIZATION_4_ID                                    ' ||
      '     , MAIN.GCO_CHARACTERIZATION_5_ID                                    ' ||
      '     , nvl(USR_CMD.REGROUP_01, ''null'') REGROUP_01                      ' ||
      '     , nvl(USR_CMD.REGROUP_02, ''null'') REGROUP_02                      ' ||
      '     , nvl(USR_CMD.REGROUP_03, ''null'') REGROUP_03                      ' ||
      '     , nvl(USR_CMD.REGROUP_04, ''null'') REGROUP_04                      ' ||
      '     , nvl(USR_CMD.REGROUP_05, ''null'') REGROUP_05                      ' ||
      '     , nvl(USR_CMD.REGROUP_06, ''null'') REGROUP_06                      ' ||
      '     , nvl(USR_CMD.REGROUP_07, ''null'') REGROUP_07                      ' ||
      '     , nvl(USR_CMD.REGROUP_08, ''null'') REGROUP_08                      ' ||
      '     , nvl(USR_CMD.REGROUP_09, ''null'') REGROUP_09                      ' ||
      '     , nvl(USR_CMD.REGROUP_10, ''null'') REGROUP_10                      ' ||
      '     , to_char(MAIN.GCO_GOOD_ID) || ''/'' ||                             ' ||
      '         to_char(MAIN.PC_COMP_SRC_ID) || ''/'' ||                        ' ||
      '         to_char(MAIN.PC_COMP_DST_ID) || ''/'' ||                        ' ||
      '         to_char(MAIN.PAC_THIRD_SRC_ID) || ''/'' ||                      ' ||
      '         to_char(MAIN.PAC_THIRD_DST_ID) || ''/'' ||                      ' ||
      '         to_char(MAIN.DOC_GAUGE_SRC_ID) || ''/'' ||                      ' ||
      '         to_char(MAIN.DOC_GAUGE_DST_ID) || ''/'' ||                      ' ||
      '         to_char(MAIN.DOC_RECORD_SRC_ID) || ''/'' ||                     ' ||
      '         to_char(MAIN.DOC_RECORD_DST_ID) || ''/'' ||                     ' ||
      '         to_char(MAIN.STM_LOCATION_SRC_ID) || ''/'' ||                   ' ||
      '         to_char(MAIN.STM_LOCATION_DST_ID) || ''/'' ||                   ' ||
      '         to_char(MAIN.STM_STOCK_SRC_ID) || ''/'' ||                      ' ||
      '         to_char(MAIN.STM_STOCK_DST_ID) || ''/'' ||                      ' ||
      '         to_char(MAIN.GCO_CHARACTERIZATION_1_ID) || ''/'' ||             ' ||
      '         to_char(MAIN.GCO_CHARACTERIZATION_2_ID) || ''/'' ||             ' ||
      '         to_char(MAIN.GCO_CHARACTERIZATION_3_ID) || ''/'' ||             ' ||
      '         to_char(MAIN.GCO_CHARACTERIZATION_4_ID) || ''/'' ||             ' ||
      '         to_char(MAIN.GCO_CHARACTERIZATION_5_ID) REGROUP_ALL             ' ||
      '   from STM_INTERC_STOCK_TRSF MAIN                                       ' ||
      '      , ( [USER_COMMAND] ) USR_CMD                                       ' ||
      '  where USR_CMD.STM_INTERC_STOCK_TRSF_ID = MAIN.STM_INTERC_STOCK_TRSF_ID ' ||
      '    and MAIN.SIS_SELECTION = 1                                           ';
    tmpSqlCmd          := replace(tmpSqlCmd, '[USER_COMMAND]', aSqlCmd);
    tmpSqlCmd          := replace(tmpSqlCmd, co.cCompanyOwner || '.', '');

    begin
      open crToRegroup for tmpSqlCmd;

      loop
        -- reprendre les données de regroupement et de tri de la cmd sql utilisateur de l'affichage des propositions
        fetch crToRegroup
         into InterStkTransfID
            , CompanySrcID
            , CompanyDstID
            , GaugeSrcID
            , GaugeDstID
            , ThirdSrcID
            , ThirdDstID
            , GoodID
            , StockSrcID
            , LocationSrcID
            , StockDstID
            , LocationDstID
            , CharID_1
            , CharID_2
            , CharID_3
            , CharID_4
            , CharID_5
            , Regroup_01
            , Regroup_02
            , Regroup_03
            , Regroup_04
            , Regroup_05
            , Regroup_06
            , Regroup_07
            , Regroup_08
            , Regroup_09
            , Regroup_10
            , Regroup_All;

        exit when crToRegroup%notfound;

        -- Regroupement des documents
        -- Pas de regroupement des documents demandé par l'utilisateur
        if (Regroup_01 = 'null') then
          if (Regroup_All <> Old_Regroup_All) then
            -- Nouveau ID de DOC_INTERFACE
            select INIT_ID_SEQ.nextval
                 , INIT_ID_SEQ.nextval
              into newDocID
                 , newPosID
              from dual;
          else
            if     (CharID_1 is null)
               and (CharID_2 is null)
               and (CharID_3 is null)
               and (CharID_4 is null)
               and (CharID_5 is null) then
              -- Nouveau ID de DOC_INTERFACE
              select INIT_ID_SEQ.nextval
                   , INIT_ID_SEQ.nextval
                into newDocID
                   , newPosID
                from dual;
            end if;
          end if;
        else
          if aMode = 'SOURCE' then
            -- Regroupement demandé par l'utilisateur
            if    (CompanySrcID <> Old_CompanySrcID)
               or (GaugeSrcID <> Old_GaugeSrcID)
               or (ThirdSrcID <> Old_ThirdSrcID)
               or (Regroup_01 <> Old_Regroup_01)
               or (Regroup_02 <> Old_Regroup_02)
               or (Regroup_03 <> Old_Regroup_03)
               or (Regroup_04 <> Old_Regroup_04)
               or (Regroup_05 <> Old_Regroup_05)
               or (Regroup_06 <> Old_Regroup_06)
               or (Regroup_07 <> Old_Regroup_07)
               or (Regroup_08 <> Old_Regroup_08)
               or (Regroup_09 <> Old_Regroup_09)
               or (Regroup_10 <> Old_Regroup_10) then
              -- Nouveau ID de DOC_INTERFACE
              select INIT_ID_SEQ.nextval
                   , INIT_ID_SEQ.nextval
                into newDocID
                   , newPosID
                from dual;
            end if;
          else
            -- Regroupement demandé par l'utilisateur
            if    (CompanyDstID <> Old_CompanyDstID)
               or (GaugeDstID <> Old_GaugeDstID)
               or (ThirdDstID <> Old_ThirdDstID)
               or (Regroup_01 <> Old_Regroup_01)
               or (Regroup_02 <> Old_Regroup_02)
               or (Regroup_03 <> Old_Regroup_03)
               or (Regroup_04 <> Old_Regroup_04)
               or (Regroup_05 <> Old_Regroup_05)
               or (Regroup_06 <> Old_Regroup_06)
               or (Regroup_07 <> Old_Regroup_07)
               or (Regroup_08 <> Old_Regroup_08)
               or (Regroup_09 <> Old_Regroup_09)
               or (Regroup_10 <> Old_Regroup_10) then
              -- Nouveau ID de DOC_INTERFACE
              select INIT_ID_SEQ.nextval
                   , INIT_ID_SEQ.nextval
                into newDocID
                   , newPosID
                from dual;
            end if;
          end if;
        end if;

        --Regroupement des positions
        if aRegroupPos = 1 then
          -- Un seul gabarit de document de Transfert dans la même société
          if     (CompanySrcID = CompanyDstID)
             and (GaugeSrcID = GaugeDstID) then
            if    (GoodID <> Old_GoodID)
               or (StockSrcID <> Old_StockSrcID)
               or (LocationSrcID <> Old_LocationSrcID)
               or (StockDstID <> Old_StockDstID)
               or (LocationDstID <> Old_LocationDstID) then
              -- Nouveau ID de DOC_INTERFACE_POSITION
              select INIT_ID_SEQ.nextval
                into newPosID
                from dual;
            end if;
          else
            -- Gabarit Destination <> Gabarit Source
            if aMode = 'SOURCE' then
              if    (GoodID <> Old_GoodID)
                 or (StockSrcID <> Old_StockSrcID)
                 or (LocationSrcID <> Old_LocationSrcID) then
                -- Nouveau ID de DOC_INTERFACE_POSITION
                select INIT_ID_SEQ.nextval
                  into newPosID
                  from dual;
              end if;
            else
              if    (GoodID <> Old_GoodID)
                 or (StockDstID <> Old_StockDstID)
                 or (LocationDstID <> Old_LocationDstID) then
                -- Nouveau ID de DOC_INTERFACE_POSITION
                select INIT_ID_SEQ.nextval
                  into newPosID
                  from dual;
              end if;
            end if;
          end if;
        else
          if (Regroup_All <> Old_Regroup_All) then
            select INIT_ID_SEQ.nextval
              into newPosID
              from dual;
          else
            if     (CharID_1 is null)
               and (CharID_2 is null)
               and (CharID_3 is null)
               and (CharID_4 is null)
               and (CharID_5 is null) then
              select INIT_ID_SEQ.nextval
                into newPosID
                from dual;
            end if;
          end if;
        end if;

        Old_CompanySrcID   := CompanySrcID;
        Old_CompanyDstID   := CompanyDstID;
        Old_GaugeSrcID     := GaugeSrcID;
        Old_GaugeDstID     := GaugeDstID;
        Old_ThirdSrcID     := ThirdSrcID;
        Old_ThirdDstID     := ThirdDstID;
        Old_GoodID         := GoodID;
        Old_StockSrcID     := StockSrcID;
        Old_StockDstID     := StockDstID;
        Old_LocationSrcID  := LocationSrcID;
        Old_LocationDstID  := LocationDstID;
        Old_Regroup_01     := Regroup_01;
        Old_Regroup_02     := Regroup_02;
        Old_Regroup_03     := Regroup_03;
        Old_Regroup_04     := Regroup_04;
        Old_Regroup_05     := Regroup_05;
        Old_Regroup_06     := Regroup_06;
        Old_Regroup_07     := Regroup_07;
        Old_Regroup_08     := Regroup_08;
        Old_Regroup_09     := Regroup_09;
        Old_Regroup_10     := Regroup_10;
        Old_Regroup_All    := Regroup_All;

        if aMode = 'SOURCE' then
          -- Màj des champs de regroupement
          update STM_INTERC_STOCK_TRSF
             set SIS_DOC_SRC_ID = newDocID
               , SIS_POS_SRC_ID = newPosID
           where STM_INTERC_STOCK_TRSF_ID = InterStkTransfID;
        else
          -- Màj des champs de regroupement
          update STM_INTERC_STOCK_TRSF
             set SIS_DOC_DST_ID = newDocID
               , SIS_POS_DST_ID = newPosID
           where STM_INTERC_STOCK_TRSF_ID = InterStkTransfID;
        end if;
      end loop;
    exception
      when others then
        raise_application_error(-20113, PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur lors du regroupement des positions à transferer!') );
    end;
  end RegroupTransfertData;

  procedure GenerateSourceDocuments(aSessionID in varchar2)
  is
    cursor crTransfertList(cSessionID in varchar2)
    is
      select   SIS.SIS_DOC_SRC_ID
             , SIS.SIS_POS_SRC_ID
             , SIS.PC_COMP_SRC_ID
             , SIS.PC_COMP_DST_ID
             , SIS.DOC_GAUGE_SRC_ID
             , SIS.DOC_GAUGE_DST_ID
             , SIS.PAC_THIRD_SRC_ID
             , PCS.PC_CONFIG.GETCONFIG('DOC_CART_CONFIG_GAUGE') GAUGE_CONFIG
             , GAU.C_ADMIN_DOMAIN
             , GAP.C_ROUND_APPLICATION
             , GAS.C_ROUND_TYPE
             , GAS.GAS_ROUND_AMOUNT
             , GAP.C_GAUGE_INIT_PRICE_POS
             , GAP.GAP_FORCED_TARIFF
             , GAP.DIC_TARIFF_ID GAP_DIC_TARIFF_ID
             , SIS.SIS_QUANTITY_TRANSFER
             , SIS.GCO_GOOD_ID
             , SIS.STM_STOCK_SRC_ID
             , SIS.STM_LOCATION_SRC_ID
             , SIS.STM_STOCK_DST_ID
             , SIS.STM_LOCATION_DST_ID
             , SIS.DOC_RECORD_SRC_ID
             , SIS.SIS_FREE_TEXT
             , SIS.SIS_FREE_TEXT2
             , SIS.SIS_FREE_TEXT3
             , SIS.GCO_CHARACTERIZATION_1_ID
             , SIS.GCO_CHARACTERIZATION_2_ID
             , SIS.GCO_CHARACTERIZATION_3_ID
             , SIS.GCO_CHARACTERIZATION_4_ID
             , SIS.GCO_CHARACTERIZATION_5_ID
             , SIS.SIS_CHARACTERIZATION_VALUE_1
             , SIS.SIS_CHARACTERIZATION_VALUE_2
             , SIS.SIS_CHARACTERIZATION_VALUE_3
             , SIS.SIS_CHARACTERIZATION_VALUE_4
             , SIS.SIS_CHARACTERIZATION_VALUE_5
             , SIS.STM_INTERC_STOCK_TRSF_ID
          from STM_INTERC_STOCK_TRSF SIS
             , DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_GAUGE_POSITION GAP
         where SIS.SIS_SELECTION = 1
           and SIS.SIS_ORA_SESSION_ID = cSessionID
           and SIS.C_TRANSFER_STATUS = '02'
           and SIS.DOC_GAUGE_SRC_ID = GAU.DOC_GAUGE_ID
           and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID(+)
           and GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID(+)
           and GAP.GAP_DEFAULT(+) = 1
           and GAP.C_GAUGE_TYPE_POS(+) = '1'
      order by SIS.SIS_DOC_SRC_ID
             , SIS.SIS_POS_SRC_ID;

    NewInterfaceID     DOC_INTERFACE.DOC_INTERFACE_ID%type;
    NewInterfaceNumber DOC_INTERFACE.DOI_NUMBER%type;
    NewIntPosID        DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type;
    NewIntPosNumber    DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type;
    oldDocID           STM_INTERC_STOCK_TRSF.SIS_DOC_SRC_ID%type;
    oldPosID           STM_INTERC_STOCK_TRSF.SIS_POS_SRC_ID%type;
    OldInterfaceID     DOC_INTERFACE.DOC_INTERFACE_ID%type;
    tmpInterfaceID     DOC_INTERFACE.DOC_INTERFACE_ID%type;
    tmpTotalPosQty     STM_INTERC_STOCK_TRSF.SIS_QUANTITY_TRANSFER%type;
    tmpGoodPrice       STM_INTERC_STOCK_TRSF.SIS_GOOD_PRICE%type;
    tmpTraStockID      STM_INTERC_STOCK_TRSF.STM_STOCK_DST_ID%type;
    tmpTraLocationID   STM_INTERC_STOCK_TRSF.STM_LOCATION_DST_ID%type;
    tmpCurrencyID      DOC_INTERFACE.ACS_FINANCIAL_CURRENCY_ID%type;
    tmpTariffID        DOC_INTERFACE.DIC_TARIFF_ID%type;
    tmpNetTariff       DOC_INTERFACE_POSITION.DOP_NET_TARIFF%type;
    tmpSpecialTariff   DOC_INTERFACE_POSITION.DOP_SPECIAL_TARIFF%type;
    tmpFlatRate        DOC_INTERFACE_POSITION.DOP_FLAT_RATE%type;
    tmpTariffUnit      DOC_POSITION.POS_TARIFF_UNIT%type;
  begin
    oldDocID  := -1;
    oldPosID  := -1;

    -- Création des documents
    for tplTransfertList in crTransfertList(aSessionID) loop
      -- Insertion dans la table DOC_INTERFACE
      if tplTransfertList.SIS_DOC_SRC_ID <> oldDocID then
        NewInterfaceID      := null;
        NewInterfaceNumber  := null;
        -- Création de l'interface
        DOC_INTERFACE_CREATE.CREATE_INTERFACE(tplTransfertList.PAC_THIRD_SRC_ID
                                            , tplTransfertList.GAUGE_CONFIG
                                            , tplTransfertList.DOC_GAUGE_SRC_ID
                                            , '005'
                                            , NewInterfaceNumber
                                            , NewInterfaceID
                                            , tplTransfertList.C_ADMIN_DOMAIN
                                             );

        -- Statut de l'interface à "Prêt"
        update DOC_INTERFACE
           set C_DOI_INTERFACE_STATUS = '02'
             , DOI_PROTECTED = 0
         where DOC_INTERFACE_ID = NewInterfaceID;

        oldDocID            := tplTransfertList.SIS_DOC_SRC_ID;
      end if;

      -- Insertion dans la table DOC_INTERFACE_POSITION
      if tplTransfertList.SIS_POS_SRC_ID <> oldPosID then
        NewIntPosNumber  := null;
        oldPosID         := tplTransfertList.SIS_POS_SRC_ID;

        -- Calculer la qté totale de la position pour la recherche du prix de la position
        select sum(SIS_QUANTITY_TRANSFER)
          into tmpTotalPosQty
          from STM_INTERC_STOCK_TRSF
         where SIS_SELECTION = 1
           and SIS_ORA_SESSION_ID = aSessionID
           and SIS_DOC_SRC_ID = tplTransfertList.SIS_DOC_SRC_ID
           and SIS_POS_SRC_ID = tplTransfertList.SIS_POS_SRC_ID;

        -- Recherche le type de tarif et la monnaie du document
        select DIC_TARIFF_ID
             , ACS_FINANCIAL_CURRENCY_ID
          into tmpTariffID
             , tmpCurrencyID
          from DOC_INTERFACE
         where DOC_INTERFACE_ID = NewInterfaceID;

        -- Recherche du prix de la position
        DOC_POSITION_FUNCTIONS.GetPosUnitPrice(aGoodID              => tplTransfertList.GCO_GOOD_ID
                                             , aQuantity            => tmpTotalPosQty
                                             , aConvertFactor       => 1
                                             , aRecordID            => tplTransfertList.DOC_RECORD_SRC_ID
                                             , aFalScheduleStepID   => null
                                             , aDateRef             => sysdate
                                             , aAdminDomain         => tplTransfertList.C_ADMIN_DOMAIN
                                             , aThirdID             => tplTransfertList.PAC_THIRD_SRC_ID
                                             , aDmtTariffID         => tmpTariffID
                                             , aDocCurrencyID       => tmpCurrencyID
                                             , aExchangeRate        => 0 -- use official rate
                                             , aBasePrice           => 0 -- use official rate
                                             , aRoundType           => tplTransfertList.C_ROUND_TYPE
                                             , aRoundAmount         => tplTransfertList.GAS_ROUND_AMOUNT
                                             , aGapTariffID         => tplTransfertList.GAP_DIC_TARIFF_ID
                                             , aForceTariff         => tplTransfertList.GAP_FORCED_TARIFF
                                             , aTypePrice           => tplTransfertList.C_GAUGE_INIT_PRICE_POS
                                             , aRoundApplication    => tplTransfertList.C_ROUND_APPLICATION
                                             , aUnitPrice           => tmpGoodPrice
                                             , aTariffID            => tmpTariffID
                                             , aNetTariff           => tmpNetTariff
                                             , aSpecialTariff       => tmpSpecialTariff
                                             , aFlatRate            => tmpFlatRate
                                             , aTariffUnit          => tmpTariffUnit
                                              );
      end if;

      NewIntPosID  := null;

      -- Utiliser le stock et l'emplacement de transfert si l'on est en train de créér
      -- un document de transfert dans la même société
      if     (tplTransfertList.PC_COMP_SRC_ID = tplTransfertList.PC_COMP_DST_ID)
         and (tplTransfertList.DOC_GAUGE_SRC_ID = tplTransfertList.DOC_GAUGE_DST_ID) then
        tmpTraStockID     := tplTransfertList.STM_STOCK_DST_ID;
        tmpTraLocationID  := tplTransfertList.STM_LOCATION_DST_ID;
      else
        tmpTraStockID     := null;
        tmpTraLocationID  := null;
      end if;

      -- Création de la position dans la table DOC_INTERFACE_POSITION
      DOC_INTERFACE_POSITION_CREATE.CreateInterfacePosition(NewIntPositionID   => NewIntPosID
                                                          , aIntPosNumber      => NewIntPosNumber
                                                          , aInterfaceID       => NewInterfaceID
                                                          , aGaugeID           => tplTransfertList.DOC_GAUGE_SRC_ID
                                                          , aTypePos           => '1'
                                                          , aGoodID            => tplTransfertList.GCO_GOOD_ID
                                                          , aQuantity          => tplTransfertList.SIS_QUANTITY_TRANSFER
                                                          , aGoodPrice         => tmpGoodPrice
                                                          , aRecordID          => tplTransfertList.DOC_RECORD_SRC_ID
                                                          , aStockID           => tplTransfertList.STM_STOCK_SRC_ID
                                                          , aLocationID        => tplTransfertList.STM_LOCATION_SRC_ID
                                                          , aTraStockID        => tmpTraStockID
                                                          , aTraLocationID     => tmpTraLocationID
                                                          , aNetTariff         => tmpNetTariff
                                                          , aSpecialTariff     => tmpSpecialTariff
                                                          , aFlatRate          => tmpFlatRate
                                                          , aCharID_1          => tplTransfertList.GCO_CHARACTERIZATION_1_ID
                                                          , aCharID_2          => tplTransfertList.GCO_CHARACTERIZATION_2_ID
                                                          , aCharID_3          => tplTransfertList.GCO_CHARACTERIZATION_3_ID
                                                          , aCharID_4          => tplTransfertList.GCO_CHARACTERIZATION_4_ID
                                                          , aCharID_5          => tplTransfertList.GCO_CHARACTERIZATION_5_ID
                                                          , aCharValue_1       => tplTransfertList.SIS_CHARACTERIZATION_VALUE_1
                                                          , aCharValue_2       => tplTransfertList.SIS_CHARACTERIZATION_VALUE_2
                                                          , aCharValue_3       => tplTransfertList.SIS_CHARACTERIZATION_VALUE_3
                                                          , aCharValue_4       => tplTransfertList.SIS_CHARACTERIZATION_VALUE_4
                                                          , aCharValue_5       => tplTransfertList.SIS_CHARACTERIZATION_VALUE_5
                                                          , aPdeText_1         => tplTransfertList.SIS_FREE_TEXT
                                                          , aPdeText_2         => tplTransfertList.SIS_FREE_TEXT2
                                                          , aPdeText_3         => tplTransfertList.SIS_FREE_TEXT3
                                                           );

      -- Statut de la position de l'interface à "Prêt"
      update DOC_INTERFACE_POSITION
         set C_DOP_INTERFACE_STATUS = '02'
       where DOC_INTERFACE_POSITION_ID = NewIntPosID;

      -- Màj le lien avec l'interface ainsi que le prix utilisé pour la société source
      if     (tplTransfertList.DOC_GAUGE_SRC_ID = tplTransfertList.DOC_GAUGE_DST_ID)
         and (tplTransfertList.PC_COMP_SRC_ID = tplTransfertList.PC_COMP_DST_ID) then
        update STM_INTERC_STOCK_TRSF
           set SIS_GOOD_PRICE = tmpGoodPrice
             , DOC_INTERFACE_SRC_ID = NewInterfaceID
             , DOC_INT_POSITION_SRC_ID = NewIntPosID
             , C_TRANSFER_STATUS = '03'
         where STM_INTERC_STOCK_TRSF_ID = tplTransfertList.STM_INTERC_STOCK_TRSF_ID;
      else
        update STM_INTERC_STOCK_TRSF
           set SIS_GOOD_PRICE = tmpGoodPrice
             , DOC_INTERFACE_SRC_ID = NewInterfaceID
             , DOC_INT_POSITION_SRC_ID = NewIntPosID
         where STM_INTERC_STOCK_TRSF_ID = tplTransfertList.STM_INTERC_STOCK_TRSF_ID;
      end if;
    end loop;
  end GenerateSourceDocuments;

  procedure GenerateTargetDocuments(aSessionID in varchar2)
  is
    cursor crTransfertList(cSessionID in varchar2)
    is
      select   SIS.SIS_DOC_DST_ID
             , SIS.SIS_POS_DST_ID
             , SIS.PC_COMP_SRC_ID
             , SIS.PC_COMP_DST_ID
             , SIS.DOC_GAUGE_SRC_ID
             , SIS.DOC_GAUGE_DST_ID
             , SIS.PAC_THIRD_DST_ID
             , SIS.SIS_QUANTITY_TRANSFER
             , SIS.GCO_GOOD_ID
             , GOO.GOO_MAJOR_REFERENCE
             , SIS.SIS_GOOD_PRICE
             , SIS.STM_STOCK_DST_ID
             , SIS.STM_LOCATION_DST_ID
             , SIS.DOC_RECORD_DST_ID
             , SIS.SIS_FREE_TEXT
             , SIS.SIS_FREE_TEXT2
             , SIS.SIS_FREE_TEXT3
             , SIS.GCO_CHARACTERIZATION_1_ID
             , SIS.GCO_CHARACTERIZATION_2_ID
             , SIS.GCO_CHARACTERIZATION_3_ID
             , SIS.GCO_CHARACTERIZATION_4_ID
             , SIS.GCO_CHARACTERIZATION_5_ID
             , SIS.SIS_CHARACTERIZATION_VALUE_1
             , SIS.SIS_CHARACTERIZATION_VALUE_2
             , SIS.SIS_CHARACTERIZATION_VALUE_3
             , SIS.SIS_CHARACTERIZATION_VALUE_4
             , SIS.SIS_CHARACTERIZATION_VALUE_5
             , SIS.STM_INTERC_STOCK_TRSF_ID
          from STM_INTERC_STOCK_TRSF SIS
             , GCO_GOOD GOO
         where SIS.SIS_SELECTION = 1
           and SIS.SIS_ORA_SESSION_ID = cSessionID
           and SIS.C_TRANSFER_STATUS = '02'
           and not(    SIS.DOC_GAUGE_SRC_ID = SIS.DOC_GAUGE_DST_ID
                   and SIS.PC_COMP_SRC_ID = SIS.PC_COMP_DST_ID)
           and SIS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
      order by SIS.SIS_DOC_DST_ID
             , SIS.SIS_POS_DST_ID;

    cursor crGetCompanyLink(cCompID in number, cStockID in number, cLocationID in number)
    is
      select distinct PC_COMP_ID
                    , STM_STOCK_ID
                    , STM_LOCATION_ID
                    , COM_NAME
                    , SCRDBOWNER
                    , SCRDB_LINK
                 from (select PC_COMP.PC_COMP_ID
                            , PC_STOCK_ACCESS.STM_STOCK_ID
                            , PC_STOCK_ACCESS.STM_LOCATION_ID
                            , PC_COMP.COM_NAME
                            , PC_SCRIP.SCRDBOWNER
                            , PC_SCRIP.SCRDB_LINK
                         from PCS.PC_COMP_COMP
                            , PCS.PC_COMP
                            , PCS.PC_COMP_ACCESS
                            , PCS.PC_USER_COMP
                            , PCS.PC_SCRIP
                            , PCS.PC_STOCK_ACCESS
                        where PC_COMP.PC_COMP_ID = PC_COMP_COMP.PC_COMP_BINDED_ID
                          and PC_COMP_COMP.PC_COMP_COMP_ID = PC_COMP_ACCESS.PC_COMP_COMP_ID
                          and PC_COMP_ACCESS.PC_USER_COMP_ID = PC_USER_COMP.PC_USER_COMP_ID
                          and PC_SCRIP.PC_SCRIP_ID = PC_COMP.PC_SCRIP_ID
                          and PC_USER_COMP.PC_USER_ID = PCS.PC_I_LIB_SESSION.GETUSERID   -- 65235
                          and PC_USER_COMP.PC_COMP_ID = PCS.PC_I_LIB_SESSION.GETCOMPANYID   -- 30622
                          and PC_STOCK_ACCESS.PC_COMP_ACCESS_ID(+) = PC_COMP_ACCESS.PC_COMP_ACCESS_ID
                       union all
                       select PC_COMP.PC_COMP_ID
                            , PC_STOCK_ACCESS.STM_STOCK_ID
                            , PC_STOCK_ACCESS.STM_LOCATION_ID
                            , PC_COMP.COM_NAME
                            , PC_SCRIP.SCRDBOWNER
                            , PC_SCRIP.SCRDB_LINK
                         from PCS.PC_COMP_COMP
                            , PCS.PC_COMP
                            , PCS.PC_COMP_ACCESS
                            , PCS.PC_USER_COMP
                            , PCS.PC_SCRIP
                            , PCS.PC_USER_GROUP
                            , PCS.PC_STOCK_ACCESS
                        where PC_COMP.PC_COMP_ID = PC_COMP_COMP.PC_COMP_BINDED_ID
                          and PC_COMP_COMP.PC_COMP_COMP_ID = PC_COMP_ACCESS.PC_COMP_COMP_ID
                          and PC_COMP_ACCESS.PC_USER_COMP_ID = PC_USER_COMP.PC_USER_COMP_ID
                          and PC_SCRIP.PC_SCRIP_ID = PC_COMP.PC_SCRIP_ID
                          and PC_USER_GROUP.PC_USER_ID = PCS.PC_I_LIB_SESSION.GETUSERID
                          and PC_USER_COMP.PC_USER_ID = PC_USER_GROUP.USE_GROUP_ID
                          and PC_USER_COMP.PC_COMP_ID = PCS.PC_I_LIB_SESSION.GETCOMPANYID
                          and PC_STOCK_ACCESS.PC_COMP_ACCESS_ID(+) = PC_COMP_ACCESS.PC_COMP_ACCESS_ID)
                where PC_COMP_ID = cCompID
             order by decode(PC_COMP_ID, PCS.PC_I_LIB_SESSION.GETCOMPANYID, 0, PC_COMP_ID) desc
                    , STM_STOCK_ID desc;

    tplGetCompanyLink  crGetCompanyLink%rowtype;
    NewInterfaceID     DOC_INTERFACE.DOC_INTERFACE_ID%type;
    NewInterfaceNumber DOC_INTERFACE.DOI_NUMBER%type;
    NewIntPosID        DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type;
    NewIntPosNumber    DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type;
    oldDocID           STM_INTERC_STOCK_TRSF.SIS_DOC_DST_ID%type;
    oldPosID           STM_INTERC_STOCK_TRSF.SIS_POS_DST_ID%type;
    OldInterfaceID     DOC_INTERFACE.DOC_INTERFACE_ID%type;
    tmpInterfaceID     DOC_INTERFACE.DOC_INTERFACE_ID%type;
    tmpTotalPosQty     STM_INTERC_STOCK_TRSF.SIS_QUANTITY_TRANSFER%type;
    tmpGoodPrice       STM_INTERC_STOCK_TRSF.SIS_GOOD_PRICE%type;
    tmpTraStockID      STM_INTERC_STOCK_TRSF.STM_STOCK_DST_ID%type;
    tmpTraLocationID   STM_INTERC_STOCK_TRSF.STM_LOCATION_DST_ID%type;
    tmpCurrencyID      DOC_INTERFACE.ACS_FINANCIAL_CURRENCY_ID%type;
    tmpTariffID        DOC_INTERFACE.DIC_TARIFF_ID%type;
    tmpNetTariff       DOC_INTERFACE_POSITION.DOP_NET_TARIFF%type;
    tmpSpecialTariff   DOC_INTERFACE_POSITION.DOP_SPECIAL_TARIFF%type;
    tmpFlatRate        DOC_INTERFACE_POSITION.DOP_FLAT_RATE%type;
    tmpTariffUnit      DOC_POSITION.POS_TARIFF_UNIT%type;
    sql_code           varchar2(32000);
    CompanyOwner2      varchar2(100);
    DstGoodID          GCO_GOOD.GCO_GOOD_ID%type;
    DstCharID_1        STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_1_ID%type;
    DstCharID_2        STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_2_ID%type;
    DstCharID_3        STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_3_ID%type;
    DstCharID_4        STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_4_ID%type;
    DstCharID_5        STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_5_ID%type;
    CompanyDBLink2     varchar2(100);
  begin
    oldDocID  := -1;
    oldPosID  := -1;

    -- Création des documents
    for tplTransfertList in crTransfertList(aSessionID) loop
      open crGetCompanyLink(tplTransfertList.PC_COMP_DST_ID, tplTransfertList.STM_STOCK_DST_ID, tplTransfertList.STM_LOCATION_DST_ID);

      fetch crGetCompanyLink
       into tplGetCompanyLink;

      if crGetCompanyLink%found then
        CompanyOwner2  := tplGetCompanyLink.scrdbowner || '.';

        if tplGetCompanyLink.scrdb_link is not null then
          CompanyDBLink2  := '@' || tplGetCompanyLink.scrdb_link;
        else
          CompanyDBLink2  := '';
        end if;

        -- Si on reste dans la même société, on copie simplement les ID liés au bien }
        if tplTransfertList.PC_COMP_DST_ID = tplTransfertList.PC_COMP_SRC_ID then
          DstGoodID    := tplTransfertList.GCO_GOOD_ID;
          DstCharID_1  := tplTransfertList.GCO_CHARACTERIZATION_1_ID;
          DstCharID_2  := tplTransfertList.GCO_CHARACTERIZATION_2_ID;
          DstCharID_3  := tplTransfertList.GCO_CHARACTERIZATION_3_ID;
          DstCharID_4  := tplTransfertList.GCO_CHARACTERIZATION_4_ID;
          DstCharID_5  := tplTransfertList.GCO_CHARACTERIZATION_5_ID;
        else
          -- Changement de société, il faut rechercher les ID liés au bien dans la société cible
          -- Rechercher l'id du bien dans la société cible
          begin
            sql_code  :=
              'select GCO_GOOD_ID                                   ' ||
              '  from [COMPANY_OWNER_2].GCO_GOOD@[COMPANY_DBLINK_2] ' ||
              ' where GOO_MAJOR_REFERENCE = :MAJ_REF                ';
            sql_code  := replace(sql_code, '[COMPANY_OWNER_2].', CompanyOwner2);
            sql_code  := replace(sql_code, '@[COMPANY_DBLINK_2]', CompanyDBLink2);

            execute immediate sql_code
                         into DstGoodID
                        using in tplTransfertList.GOO_MAJOR_REFERENCE;
          exception
            when no_data_found then
              raise_application_error(-20000
                                    , replace(PCS.PC_FUNCTIONS.TranslateWord('Le bien %s n''existe pas dans la société cible !')
                                            , '%s'
                                            , tplTransfertList.GOO_MAJOR_REFERENCE
                                             )
                                     );
          end;

          -- Initialiser les ID des caractérisations de la société cible
          DstCharID_1  := null;
          DstCharID_2  := null;
          DstCharID_3  := null;
          DstCharID_4  := null;
          DstCharID_5  := null;
          -- Cmd SQL pour la recherche de l'ID de la caractérisation dans la société cible
          sql_code     :=
            'select CHA_DST.GCO_CHARACTERIZATION_ID                                           ' ||
            '  from GCO_CHARACTERIZATION CHA_SRC                                              ' ||
            '     , [COMPANY_OWNER_2].GCO_CHARACTERIZATION@[COMPANY_DBLINK_2] CHA_DST         ' ||
            ' where CHA_SRC.GCO_CHARACTERIZATION_ID = :GCO_CHARACTERIZATION_ID                ' ||
            '   and CHA_DST.GCO_GOOD_ID = :GCO_GOOD_ID                                        ' ||
            '   and CHA_DST.CHA_CHARACTERIZATION_DESIGN = CHA_SRC.CHA_CHARACTERIZATION_DESIGN ';
          sql_code     := replace(sql_code, '[COMPANY_OWNER_2].', CompanyOwner2);
          sql_code     := replace(sql_code, '@[COMPANY_DBLINK_2]', CompanyDBLink2);

          -- Rechercher les ID des caractérisations dans la société cible
          begin
            if tplTransfertList.GCO_CHARACTERIZATION_1_ID is not null then
              execute immediate sql_code
                           into DstCharID_1
                          using in tplTransfertList.GCO_CHARACTERIZATION_1_ID, DstGoodID;
            end if;

            if tplTransfertList.GCO_CHARACTERIZATION_2_ID is not null then
              execute immediate sql_code
                           into DstCharID_2
                          using in tplTransfertList.GCO_CHARACTERIZATION_2_ID, DstGoodID;
            end if;

            if tplTransfertList.GCO_CHARACTERIZATION_3_ID is not null then
              execute immediate sql_code
                           into DstCharID_3
                          using in tplTransfertList.GCO_CHARACTERIZATION_3_ID, DstGoodID;
            end if;

            if tplTransfertList.GCO_CHARACTERIZATION_4_ID is not null then
              execute immediate sql_code
                           into DstCharID_4
                          using in tplTransfertList.GCO_CHARACTERIZATION_4_ID, DstGoodID;
            end if;

            if tplTransfertList.GCO_CHARACTERIZATION_5_ID is not null then
              execute immediate sql_code
                           into DstCharID_5
                          using in tplTransfertList.GCO_CHARACTERIZATION_5_ID, DstGoodID;
            end if;
          exception
            when no_data_found then
              raise_application_error(-20000
                                    , replace(PCS.PC_FUNCTIONS.TranslateWord('Type de caractérisation inexistante pour le bien %s dans la société cible !')
                                            , '%s'
                                            , tplTransfertList.GOO_MAJOR_REFERENCE
                                             )
                                     );
          end;
        end if;

        -- Insertion dans la table DOC_INTERFACE
        if tplTransfertList.SIS_DOC_DST_ID <> oldDocID then
          NewInterfaceID      := null;
          NewInterfaceNumber  := null;
          sql_code            :=
            ' begin                                                                                             ' ||
            '  [COMPANY_OWNER_2].DOC_INTERFACE_CREATE.CREATE_INTERFACE@[COMPANY_DBLINK_2](:PAC_THIRD_DST_ID     ' ||
            '                                                                           , null                  ' ||
            '                                                                           , :DOC_GAUGE_DST_ID     ' ||
            '                                                                           , ''005''               ' ||
            '                                                                           , :NEW_INTERFACE_NUMBER ' ||
            '                                                                           , :NEW_INTERFACE_ID     ' ||
            '                                                                           , null                  ' ||
            '                                                                            );                     ' ||
            ' end;                                                                                              ';
          sql_code            := replace(sql_code, '[COMPANY_OWNER_2].', CompanyOwner2);
          sql_code            := replace(sql_code, '@[COMPANY_DBLINK_2]', CompanyDBLink2);

          execute immediate sql_code
                      using in tplTransfertList.PAC_THIRD_DST_ID, in tplTransfertList.DOC_GAUGE_DST_ID, in out NewInterfaceNumber, in out NewInterfaceID;

          -- Statut de l'interface à "Prêt"
          sql_code            :=
            ' update [COMPANY_OWNER_2].DOC_INTERFACE@[COMPANY_DBLINK_2]  ' ||
            '    set C_DOI_INTERFACE_STATUS = ''02''                     ' ||
            '      , DOI_PROTECTED = 0                                   ' ||
            '  where DOC_INTERFACE_ID = :NEW_INTERFACE_ID                ';
          sql_code            := replace(sql_code, '[COMPANY_OWNER_2].', CompanyOwner2);
          sql_code            := replace(sql_code, '@[COMPANY_DBLINK_2]', CompanyDBLink2);

          execute immediate sql_code
                      using in NewInterfaceID;

          oldDocID            := tplTransfertList.SIS_DOC_DST_ID;
        end if;

        -- Insertion dans la table DOC_INTERFACE_POSITION
        if tplTransfertList.SIS_POS_DST_ID <> oldPosID then
          NewIntPosNumber  := null;
          oldPosID         := tplTransfertList.SIS_POS_DST_ID;
        end if;

        NewIntPosID    := null;
        -- Création de la position dans la table DOC_INTERFACE_POSITION
        sql_code       :=
          ' begin                                                                                                   ' ||
          '   [COMPANY_OWNER_2].DOC_INTERFACE_POSITION_CREATE.CreateInterfacePosition@[COMPANY_DBLINK_2]            ' ||
          '                                                    (NewIntPositionID   => :NEW_INT_POS_ID               ' ||
          '                                                   , aIntPosNumber      => :NEW_INT_POS_NUMBER           ' ||
          '                                                   , aInterfaceID       => :NEW_INTERFACE_ID             ' ||
          '                                                   , aGaugeID           => :DOC_GAUGE_DST_ID             ' ||
          '                                                   , aTypePos           => ''1''                         ' ||
          '                                                   , aGoodID            => :GCO_GOOD_ID                  ' ||
          '                                                   , aQuantity          => :SIS_QUANTITY_TRANSFER        ' ||
          '                                                   , aGoodPrice         => :GOOD_PRICE                   ' ||
          '                                                   , aRecordID          => :DOC_RECORD_DST_ID            ' ||
          '                                                   , aStockID           => :STM_STOCK_DST_ID             ' ||
          '                                                   , aLocationID        => :STM_LOCATION_DST_ID          ' ||
          '                                                   , aTraStockID        => null                          ' ||
          '                                                   , aTraLocationID     => null                          ' ||
          '                                                   , aNetTariff         => 0                             ' ||
          '                                                   , aSpecialTariff     => null                          ' ||
          '                                                   , aFlatRate          => null                          ' ||
          '                                                   , aCharID_1          => :GCO_CHARACTERIZATION_1_ID    ' ||
          '                                                   , aCharID_2          => :GCO_CHARACTERIZATION_2_ID    ' ||
          '                                                   , aCharID_3          => :GCO_CHARACTERIZATION_3_ID    ' ||
          '                                                   , aCharID_4          => :GCO_CHARACTERIZATION_4_ID    ' ||
          '                                                   , aCharID_5          => :GCO_CHARACTERIZATION_5_ID    ' ||
          '                                                   , aCharValue_1       => :SIS_CHARACTERIZATION_VALUE_1 ' ||
          '                                                   , aCharValue_2       => :SIS_CHARACTERIZATION_VALUE_2 ' ||
          '                                                   , aCharValue_3       => :SIS_CHARACTERIZATION_VALUE_3 ' ||
          '                                                   , aCharValue_4       => :SIS_CHARACTERIZATION_VALUE_4 ' ||
          '                                                   , aCharValue_5       => :SIS_CHARACTERIZATION_VALUE_5 ' ||
          '                                                   , aPdeText_1         => :SIS_FREE_TEXT_1              ' ||
          '                                                   , aPdeText_2         => :SIS_FREE_TEXT_2              ' ||
          '                                                   , aPdeText_3         => :SIS_FREE_TEXT_3              ' ||
          '                                                    );                                                   ' ||
          ' end;                                                                                                    ';
        sql_code       := replace(sql_code, '[COMPANY_OWNER_2].', CompanyOwner2);
        sql_code       := replace(sql_code, '@[COMPANY_DBLINK_2]', CompanyDBLink2);

        execute immediate sql_code
                    using in out NewIntPosID
                        , in out NewIntPosNumber
                        , in     NewInterfaceID
                        , in     tplTransfertList.DOC_GAUGE_DST_ID
                        , in     DstGoodID
                        , in     tplTransfertList.SIS_QUANTITY_TRANSFER
                        , in     tplTransfertList.SIS_GOOD_PRICE
                        , in     tplTransfertList.DOC_RECORD_DST_ID
                        , in     tplTransfertList.STM_STOCK_DST_ID
                        , in     tplTransfertList.STM_LOCATION_DST_ID
                        , in     DstCharID_1
                        , in     DstCharID_2
                        , in     DstCharID_3
                        , in     DstCharID_4
                        , in     DstCharID_5
                        , in     tplTransfertList.SIS_CHARACTERIZATION_VALUE_1
                        , in     tplTransfertList.SIS_CHARACTERIZATION_VALUE_2
                        , in     tplTransfertList.SIS_CHARACTERIZATION_VALUE_3
                        , in     tplTransfertList.SIS_CHARACTERIZATION_VALUE_4
                        , in     tplTransfertList.SIS_CHARACTERIZATION_VALUE_5
                        , in     tplTransfertList.SIS_FREE_TEXT
                        , in     tplTransfertList.SIS_FREE_TEXT2
                        , in     tplTransfertList.SIS_FREE_TEXT3;

        -- Statut de la position de l'interface à "Prêt"
        sql_code       :=
          ' update [COMPANY_OWNER_2].DOC_INTERFACE_POSITION@[COMPANY_DBLINK_2]  ' ||
          '    set C_DOP_INTERFACE_STATUS = ''02''                              ' ||
          '  where DOC_INTERFACE_POSITION_ID = :NewIntPosID                     ';
        sql_code       := replace(sql_code, '[COMPANY_OWNER_2].', CompanyOwner2);
        sql_code       := replace(sql_code, '@[COMPANY_DBLINK_2]', CompanyDBLink2);

        execute immediate sql_code
                    using in NewIntPosID;

        -- Màj le lien avec l'interface ainsi que le prix utilisé pour la société source
        update STM_INTERC_STOCK_TRSF
           set DOC_INTERFACE_DST_ID = NewInterfaceID
             , DOC_INT_POSITION_DST_ID = NewIntPosID
             , C_TRANSFER_STATUS = '03'
         where STM_INTERC_STOCK_TRSF_ID = tplTransfertList.STM_INTERC_STOCK_TRSF_ID;
      end if;

      close crGetCompanyLink;
    end loop;
  end GenerateTargetDocuments;

  /**
  * Description
  *    Mise à jour des quantités dans la table STM_STOCK_INTERC_TEMP
  */
  procedure majQtyInTemp(
    aMode            in varchar2
  , aGoodId          in GCO_GOOD.GCO_GOOd_ID%type
  , aQuantity        in STM_INTERC_STOCK_TRSF.SIS_QUANTITY_TRANSFER%type
  , aTransfertStatus in STM_INTERC_STOCK_TRSF.C_TRANSFER_STATUS%type
  , aSrcCompId          STM_INTERC_STOCK_TRSF.PC_COMP_SRC_ID%type
  , aSrcStockId         STM_INTERC_STOCK_TRSF.STM_STOCK_SRC_ID%type
  , aSrcLocationId      STM_INTERC_STOCK_TRSF.STM_LOCATION_SRC_ID%type
  , aDstCompId          STM_INTERC_STOCK_TRSF.PC_COMP_DST_ID%type
  , aDstStockId         STM_INTERC_STOCK_TRSF.STM_STOCK_DST_ID%type
  , aDstLocationId      STM_INTERC_STOCK_TRSF.STM_LOCATION_DST_ID%type
  )
  is
    vMajorReference GCO_GOOD.GOO_MAJOR_REFERENCE%type;
  begin
--       DOC_FUNCTIONS.CreateHistoryInformation(null
--                                            , null   -- DOC_POSITION_ID
--                                            , aQuantity
--                                            , 'STM_TRSF_INSERT'   -- DUH_TYPE
--                                            , aMode
--                                            , aTransfertStatus
--                                            , null   -- status document
--                                            , null   -- status position
--                                             );
    -- si le status est "A valider" ou "Validé"
    if aTransfertStatus in(cTransfertStatusToValidate, cTransfertStatusValidated) then
      -- recherche de la référence du bien
      select GOO_MAJOR_REFERENCE
        into vMajorReference
        from GCO_GOOD
       where GCO_GOOD_ID = aGoodId;

      -- Maj de la quantité provisoires en entrée
      update STM_STOCK_INTERC_TEMP
         set STI_QTY_PROV_INPUT = decode(nvl(STI_QTY_PROV_INPUT, 0) + nvl(aQuantity, 0), 0, null, nvl(STI_QTY_PROV_INPUT, 0) + nvl(aQuantity, 0) )
           , SPO_PROVISORY_INPUT = decode(aMode, 'TRIGGER', nvl(SPO_PROVISORY_INPUT, 0) + nvl(aQuantity, 0), SPO_PROVISORY_INPUT)
           , SPO_THEORETICAL_QUANTITY = decode(aMode, 'TRIGGER', nvl(SPO_THEORETICAL_QUANTITY, 0) + nvl(aQuantity, 0), SPO_THEORETICAL_QUANTITY)
       where GOO_MAJOR_REFERENCE = vMajorReference
         and PC_COMP_ID = aDstCompId
         and STM_STOCK_ID = aDstStockId
         and STM_LOCATION_ID = aDstLocationId;

      -- Maj de la quantité provisoires en sortie
      update STM_STOCK_INTERC_TEMP
         set STI_QTY_PROV_OUTPUT = decode(nvl(STI_QTY_PROV_OUTPUT, 0) + nvl(aQuantity, 0), 0, null, nvl(STI_QTY_PROV_OUTPUT, 0) + nvl(aQuantity, 0) )
           , SPO_PROVISORY_OUTPUT = decode(aMode, 'TRIGGER', nvl(SPO_PROVISORY_OUTPUT, 0) + nvl(aQuantity, 0), SPO_PROVISORY_OUTPUT)
           , SPO_THEORETICAL_QUANTITY = decode(aMode, 'TRIGGER', nvl(SPO_THEORETICAL_QUANTITY, 0) - nvl(aQuantity, 0), SPO_THEORETICAL_QUANTITY)
           , SPO_AVAILABLE_QUANTITY = decode(aMode, 'TRIGGER', nvl(SPO_AVAILABLE_QUANTITY, 0) - nvl(aQuantity, 0), SPO_AVAILABLE_QUANTITY)
       where GOO_MAJOR_REFERENCE = vMajorReference
         and PC_COMP_ID = aSrcCompId
         and STM_STOCK_ID = aSrcStockId
         and STM_LOCATION_ID = aSrcLocationId;
    end if;
  end majQtyInTemp;

  /**
  * Description
  *    initialisation des quantités provisoires dans STM_STOCK_INTERC_TEMP à partir du contenu de STM_INTERC_STOCK_TRSF
  */
  procedure initProvisoryInTemp(aMajorReference in GCO_GOOD.GOO_MAJOR_REFERENCE%type, aStockCmd in varchar2)
  is
    vGoodId                   GCO_GOOD.GCO_GOOD_ID%type;

    type ttblSTM_INTERC_STOCK_TRSF is table of STM_INTERC_STOCK_TRSF%rowtype
      index by pls_integer;

    vtblSTM_INTERC_STOCK_TRSF ttblSTM_INTERC_STOCK_TRSF;
    vSql                      varchar2(20000);
    i                         pls_integer;
  begin
    -- recherche de la référence du bien
    select GCO_GOOD_ID
      into vGoodId
      from GCO_GOOD
     where GOO_MAJOR_REFERENCE = aMajorReference;

    vSql  :=
      'select *' ||
      '              from STM_INTERC_STOCK_TRSF' ||
      '             where GCO_GOOD_ID = :vGoodId' ||
      '               and C_TRANSFER_STATUS in(''01'',''02'')' ||
      '               and STM_LOCATION_SRC_ID in (' ||
      aStockCmd ||
      ')';

    execute immediate vSql
    bulk collect into vtblSTM_INTERC_STOCK_TRSF
                using vGoodId;

    if vtblSTM_INTERC_STOCK_TRSF.count > 0 then
      -- pour chaque transfert en cours
      for i in vtblSTM_INTERC_STOCK_TRSF.first .. vtblSTM_INTERC_STOCK_TRSF.last loop
        -- mise à jour de la table STM_STOCK_INTERC_TEMP
        majQtyInTemp('INIT'
                   , vtblSTM_INTERC_STOCK_TRSF(i).GCO_GOOD_ID
                   , vtblSTM_INTERC_STOCK_TRSF(i).SIS_QUANTITY_TRANSFER
                   , vtblSTM_INTERC_STOCK_TRSF(i).C_TRANSFER_STATUS
                   , vtblSTM_INTERC_STOCK_TRSF(i).PC_COMP_SRC_ID
                   , vtblSTM_INTERC_STOCK_TRSF(i).STM_STOCK_SRC_ID
                   , vtblSTM_INTERC_STOCK_TRSF(i).STM_LOCATION_SRC_ID
                   , vtblSTM_INTERC_STOCK_TRSF(i).PC_COMP_DST_ID
                   , vtblSTM_INTERC_STOCK_TRSF(i).STM_STOCK_DST_ID
                   , vtblSTM_INTERC_STOCK_TRSF(i).STM_LOCATION_DST_ID
                    );
      end loop;
    end if;
  exception
    when no_data_found then
      null;   -- rien à faire, le bien n'existe pas dans ce schéma
  end initProvisoryInTemp;
end STM_INTER_STOCK;
