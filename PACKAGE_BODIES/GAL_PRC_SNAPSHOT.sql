--------------------------------------------------------
--  DDL for Package Body GAL_PRC_SNAPSHOT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PRC_SNAPSHOT" 
is
  /**
  * procedure CreateSnapShot
  * Description
  *   Création de l'entête d'une photo à date
  */
  procedure CreateSnapShot(
    oSnapshotID   out    GAL_SNAPSHOT.GAL_SNAPSHOT_ID%type
  , iProjectID    in     GAL_SNAPSHOT.GAL_PROJECT_ID%type
  , iDate         in     GAL_SNAPSHOT.SNA_DATE%type
  , iComment      in     GAL_SNAPSHOT.SNA_COMMENT%type default null
  , iIdentifier   in     GAL_SNAPSHOT.SNA_IDENTIFIER%type default null
  , iSpendingType in     GAL_SNAPSHOT.C_GAL_SPENDING_TYPE%type default null
  , iFinOrigin    in     GAL_SNAPSHOT.SNA_FINANCIAL_ORIGIN%type default 0
  , iOnline       in     GAL_SNAPSHOT.SNA_ONLINE%type default 0
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalSnapShot, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_PROJECT_ID', iProjectID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SNA_DATE', iDate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SNA_COMMENT', iComment);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SNA_IDENTIFIER', iIdentifier);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_GAL_SPENDING_TYPE', iSpendingType);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SNA_FINANCIAL_ORIGIN', iFinOrigin);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SNA_ONLINE', iOnline);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    oSnapshotID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'GAL_SNAPSHOT_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end CreateSnapShot;

  /**
  * procedure DeleteSnapShot
  * Description
  *   Effacement d'une photo à date
  */
  procedure DeleteSnapShot(iSnapshotID in GAL_SNAPSHOT.GAL_SNAPSHOT_ID%type)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalSnapShot, ltCRUD_DEF, false);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_SNAPSHOT_ID', iSnapshotID);
    FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end DeleteSnapShot;

  /**
  * procedure CreateSnapLink
  * Description
  *   Création des liens document/position d'une photo à date
  */
  procedure CreateSnapLink(iSnapshotID in GAL_SNAPSHOT.GAL_SNAPSHOT_ID%type, ivGaugeType in varchar2 default 'ORDER')
  is
    cursor crPos(cnUseMultiply in number, cvGaugeDescr in varchar2)
    is
      select distinct DMT.DOC_DOCUMENT_ID
                    , DMT.DMT_NUMBER
                    , DMT.DMT_DATE_DOCUMENT
                    , DMT.DMT_DATE_VALUE
                    , DMT.ACS_FINANCIAL_CURRENCY_ID
                    , DMT.A_DATECRE as DMT_DATECRE
                    , DMT.A_IDCRE as DMT_IDCRE
                    , DMT.A_DATEMOD as DMT_DATEMOD
                    , DMT.A_IDMOD as DMT_IDMOD
                    , POS.DOC_POSITION_ID
                    , POS.POS_NUMBER
                    , POS.POS_NET_VALUE_EXCL *(case
                                                 when cnUseMultiply = 0 then 1
                                                 when GAS.C_DOC_JOURNAL_CALCULATION = 'REMOVE' then -1
                                                 else 1
                                               end) as CALC_POS_NET_VALUE_EXCL
                    , POS.POS_NET_VALUE_EXCL_B *(case
                                                   when cnUseMultiply = 0 then 1
                                                   when GAS.C_DOC_JOURNAL_CALCULATION = 'REMOVE' then -1
                                                   else 1
                                                 end) as CALC_POS_NET_VALUE_EXCL_B
                    , round(case
                              when (select sum(nvl(IMP2.POI_AMOUNT, 0) )
                                      from DOC_POSITION_IMPUTATION IMP2
                                     where IMP2.DOC_POSITION_ID = IMP.DOC_POSITION_ID) <> 0 then (sum(nvl(IMP.POI_AMOUNT, 0) ) /
                                                                                                  (select sum(nvl(IMP2.POI_AMOUNT, 0) )
                                                                                                     from DOC_POSITION_IMPUTATION IMP2
                                                                                                    where IMP2.DOC_POSITION_ID = IMP.DOC_POSITION_ID)
                                                                                                 ) *
                                                                                                 100
                              else 100
                            end
                          , 5
                           ) as CALC_POI_RATIO
                    , round(case
                              when (select sum(nvl(IMP2.POI_AMOUNT_B, 0) )
                                      from DOC_POSITION_IMPUTATION IMP2
                                     where IMP2.DOC_POSITION_ID = IMP.DOC_POSITION_ID) <> 0 then (sum(nvl(IMP.POI_AMOUNT_B, 0) ) /
                                                                                                  (select sum(nvl(IMP2.POI_AMOUNT_B, 0) )
                                                                                                     from DOC_POSITION_IMPUTATION IMP2
                                                                                                    where IMP2.DOC_POSITION_ID = IMP.DOC_POSITION_ID)
                                                                                                 ) *
                                                                                                 100
                              else 100
                            end
                          , 5
                           ) as CALC_POI_RATIO_B
                 from DOC_POSITION_IMPUTATION IMP
                    , DOC_POSITION POS
                    , DOC_GAUGE GAU
                    , DOC_GAUGE_STRUCTURED GAS
                    , DOC_DOCUMENT DMT
                    , table(GAL_PRJ_FUNCTIONS.TABLEDOC_RECORD) RCO
                where POS.C_DOC_POS_STATUS < '05'
                  and IMP.DOC_POSITION_ID(+) = POS.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID(+) = DMT.DOC_DOCUMENT_ID
                  and GAU.DOC_GAUGE_ID(+) = DMT.DOC_GAUGE_ID
                  and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID
                  and (    (    POS.POS_IMPUTATION = 0
                            and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID)
                       or (    POS.POS_IMPUTATION = 1
                           and IMP.DOC_RECORD_ID = RCO.DOC_RECORD_ID) )
                  and instr(';' || cvGaugeDescr || ';', ';' || trim(GAU.GAU_DESCRIBE) || ';') <> 0
             group by DMT.DOC_DOCUMENT_ID
                    , DMT.DMT_NUMBER
                    , DMT.DMT_DATE_DOCUMENT
                    , DMT.DMT_DATE_VALUE
                    , DMT.ACS_FINANCIAL_CURRENCY_ID
                    , DMT.A_DATECRE
                    , DMT.A_IDCRE
                    , DMT.A_DATEMOD
                    , DMT.A_IDMOD
                    , POS.DOC_POSITION_ID
                    , POS.POS_NUMBER
                    , POS.POS_IMPUTATION
                    , IMP.DOC_POSITION_ID
                    , POS.POS_NET_VALUE_EXCL_B
                    , POS.POS_NET_VALUE_EXCL
                    , GAS.C_DOC_JOURNAL_CALCULATION
             order by DMT.DMT_NUMBER asc
                    , POS.POS_NUMBER;

    ltCRUD_DEF         FWK_I_TYP_DEFINITION.t_crud_def;
    lnProjectCurrency  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lnLocalCurrency    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lbContractCurrency boolean;
    lvGaugeDescr       varchar2(32000);
    lvSpendingType     GAL_SNAPSHOT.C_GAL_SPENDING_TYPE%type;
    lnPosNetValExcl    GAL_SNAP_LINK.POS_NET_VALUE_EXCL%type;
    lnPoiRatio         GAL_SNAP_LINK.POI_RATIO%type;
    lnPoiAmount        GAL_SNAP_LINK.POI_AMOUNT%type;
    lnExchRate         GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type;
    lnBasePrice        GAL_CURRENCY_RATE.GCT_BASE_PRICE%type;
    vSalePrice         number;
    vBudgetamount      number;
    vTotalamount       number;
    lnProjectID        number;
    lnUseMultiply      number;
  begin
    -- Config indiquant la gestion de la monnaie de contrat
    lbContractCurrency  :=(pcs.pc_config.getconfig('GAL_CURRENCY_CONTRACT_BUDGET') = '1');
    lnUseMultiply       := 0;

    -- Rechercher les infos de l'affaire
    select C_GAL_SPENDING_TYPE
         , GAL_LIB_PROJECT.GetProjectCurrency(SNA.GAL_PROJECT_ID)
         , ACS_FUNCTION.GetLocalCurrencyID
         , GAL_PROJECT_ID
      into lvSpendingType
         , lnProjectCurrency
         , lnLocalCurrency
         , lnProjectID
      from GAL_SNAPSHOT SNA
     where GAL_SNAPSHOT_ID = iSnapshotID;

    -- Commande
    if ivGaugeType = 'ORDER' then
      lnUseMultiply  := 0;
      lvGaugeDescr   := trim(PCS.PC_CONFIG.GetConfig('GAL_GAUGE_BALANCE_ORDER') );
    -- Facture
    elsif ivGaugeType = 'INVOICE' then
      lnUseMultiply  := 1;
      lvGaugeDescr   := trim(PCS.PC_CONFIG.GetConfig('GAL_GAUGE_INVOICE') );
    end if;

    -- Initialiser la liste des id du DOC_RECORD_ID à traiter
    GAL_PRJ_FUNCTIONS.Init_TblDocRecord(lnProjectID, null);

    for ltplPos in crPos(lnUseMultiply, lvGaugeDescr) loop
      -- Si gestion Monnaie du contrat
      -- ET que le type de photo à date est en monnaie du contrat
      -- Et que la monnaie de l'affaire est diff de la monnaie de base
      if     lbContractCurrency
         and (lvSpendingType in('02', '04') )
         and (lnProjectCurrency <> lnLocalCurrency) then
        -- Si la monnaie du document = la monnaie du contrat
        if lnProjectCurrency = ltplPos.ACS_FINANCIAL_CURRENCY_ID then
          -- Utiliser les montants en monnaie du document
          lnPosNetValExcl  := ltplPos.CALC_POS_NET_VALUE_EXCL;
          lnPoiRatio       := ltplPos.CALC_POI_RATIO;
        else
          -- Autre monnaie que celle du contrat
          -- Conversion des montants en MB -> Monnaie du contrat
          -- Recherche le cours de change de la monnaie du contrat
          ACS_FUNCTION.GetExchangeRate(aDate           => ltplPos.DMT_DATE_VALUE
                                     , aCurrency_id    => lnProjectCurrency
                                     , aRateType       => 1
                                     , aExchangeRate   => lnExchRate
                                     , aBasePrice      => lnBasePrice
                                      );
          -- Convertir en devise affaire
          lnPosNetValExcl  :=
            ACS_FUNCTION.ConvertAmountForView(ltplPos.CALC_POS_NET_VALUE_EXCL_B
                                            , lnLocalCurrency
                                            , lnProjectCurrency
                                            , ltplPos.DMT_DATE_VALUE
                                            , lnExchRate
                                            , lnBasePrice
                                            , 0
                                             );
          lnPoiRatio       := ltplPos.CALC_POI_RATIO;
        end if;
      else
        lnPosNetValExcl  := ltplPos.CALC_POS_NET_VALUE_EXCL_B;
        lnPoiRatio       := ltplPos.CALC_POI_RATIO_B;
      end if;

      -- Montant
      lnPoiAmount  := lnPosNetValExcl *(lnPoiRatio / 100);

      if lnPoiAmount <> 0 then
        -- Création du lien
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalSnapLink, ltCRUD_DEF, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_SNAPSHOT_ID', iSnapshotID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_DOCUMENT_ID', ltplPos.DOC_DOCUMENT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_POSITION_ID', ltplPos.DOC_POSITION_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_NUMBER', ltplPos.DMT_NUMBER);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'POS_NUMBER', ltplPos.POS_NUMBER);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_DATE_DOCUMENT', ltplPos.DMT_DATE_DOCUMENT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SNL_DMT_DATECRE', ltplPos.DMT_DATECRE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SNL_DMT_DATEMOD', ltplPos.DMT_DATEMOD);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SNL_DMT_IDCRE', ltplPos.DMT_IDCRE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SNL_DMT_IDMOD', ltplPos.DMT_IDMOD);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'POS_NET_VALUE_EXCL', lnPosNetValExcl);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'POI_RATIO', lnPoiRatio);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'POI_AMOUNT', lnPoiAmount);
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end if;
    end loop;
  end CreateSnapLink;
end GAL_PRC_SNAPSHOT;
