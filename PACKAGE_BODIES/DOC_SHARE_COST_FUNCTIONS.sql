--------------------------------------------------------
--  DDL for Package Body DOC_SHARE_COST_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_SHARE_COST_FUNCTIONS" 
is
  /**
  * procedure GenAllDetailCost
  * Description
  *    Création des détails des positions frais
  * @created NGV - mai 2006
  */
  procedure GenAllDetailCost(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    for tplPosCost in (select   POC.DOC_POSITION_COST_ID
                           from DOC_POSITION_COST POC
                              , PTC_COST_TYPE PCT
                          where POC.DOC_DOCUMENT_ID = aDocumentID
                            and POC.PTC_COST_TYPE_ID = PCT.PTC_COST_TYPE_ID
                       order by PCT.C_SHARING_MODE) loop
      GenerateDetailCost(tplPosCost.DOC_POSITION_COST_ID);
    end loop;
  end GenAllDetailCost;

  /**
  * procedure GenerateDetailCost
  * Description
  *    Création des détails des positions frais pour le frais courant
  * @created NGV - mai 2006
  */
  procedure GenerateDetailCost(aPosCostID in DOC_POSITION_COST.DOC_POSITION_COST_ID%type)
  is
    cursor crPosCostInfo
    is
      select POC.PTC_COST_TYPE_ID
           , POC.DIC_BASIS_MATERIAL_ID
           , POC.GCO_ALLOY_ID
           , POC.POC_BASIS_COMPL_AMOUNT
           , POC.POC_AMOUNT
           , PCT.C_SHARING_MODE
           , PCT.PCT_COMPL_AMOUNT
           , DMT.DOC_DOCUMENT_ID
           , SUP.C_MATERIAL_MGNT_MODE
        from DOC_POSITION_COST POC
           , PTC_COST_TYPE PCT
           , DOC_DOCUMENT DMT
           , PAC_SUPPLIER_PARTNER SUP
       where POC.DOC_POSITION_COST_ID = aPosCostID
         and PCT.PTC_COST_TYPE_ID = POC.PTC_COST_TYPE_ID
         and POC.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and DMT.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+);

    cursor crCustomsRate(cGoodID in number, cDocID in number)
    is
      select   CUS.CUS_COMMISSION_RATE
             , CUS.CUS_CHARGE_RATE
             , CUS.CUS_EXCISE_RATE
          from GCO_CUSTOMS_ELEMENT CUS
             , DOC_DOCUMENT DMT
         where CUS.GCO_GOOD_ID = cGoodID
           and CUS.C_CUSTOMS_ELEMENT_TYPE = 'IMPORT'
           and DMT.DOC_DOCUMENT_ID = cDocID
           and (   CUS.PC_CNTRY_ID = DMT.PC_CNTRY_ID
                or CUS.PC_CNTRY_ID is null)
      order by nvl(CUS.PC_CNTRY_ID, 0) desc;

    tplPosCostInfo    crPosCostInfo%rowtype;
    tplCustomsRate    crCustomsRate%rowtype;
    --
    vRow_DETAIL_COST  DOC_DETAIL_COST%rowtype;
    totRefValue       number(18, 6)                             := 0;
    totPosNetValExcl  DOC_POSITION.POS_NET_VALUE_EXCL%type      := 0;
    vLastDetailCostID DOC_DETAIL_COST.DOC_DETAIL_COST_ID%type;
    vDetailAmount     DOC_DETAIL_COST.DLC_AMOUNT%type           := 0.0;
  begin
    open crPosCostInfo;

    fetch crPosCostInfo
     into tplPosCostInfo;

    if tplPosCostInfo.POC_AMOUNT <> 0 then
      -- Effacer les éventuels détails déjà existants
      delete from DOC_DETAIL_COST
            where DOC_POSITION_COST_ID = aPosCostID;

      delete from COM_LIST_ID_TEMP;

      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                  )
        select POS.DOC_POSITION_ID
          from DOC_POSITION POS
             , DOC_POSITION_COST_LINK PCL
         where PCL.DOC_POSITION_COST_ID = aPosCostID
           and POS.DOC_DOCUMENT_ID = PCL.DOC_DOCUMENT_ID
           and POS.C_GAUGE_TYPE_POS = '1'
           and POS.DOC_DOC_POSITION_ID is null
           and not(    POS.DOC_DOCUMENT_ID = tplPosCostInfo.DOC_DOCUMENT_ID
                   and POS.C_POS_CREATE_MODE = '206');

      -- Recherche le diviseur du détail de frais
      GetDetailCostDivisor(aPosCostID          => aPosCostID
                         , aDocumentID         => tplPosCostInfo.DOC_DOCUMENT_ID
                         , aSharingMode        => tplPosCostInfo.C_SHARING_MODE
                         , aMatManagMode       => tplPosCostInfo.C_MATERIAL_MGNT_MODE
                         , aAlloyID            => tplPosCostInfo.GCO_ALLOY_ID
                         , aBasisMatID         => tplPosCostInfo.DIC_BASIS_MATERIAL_ID
                         , aDivisor            => vRow_DETAIL_COST.DLC_DIVISOR
                         , aTotPosNetValExcl   => totPosNetValExcl
                          );

      -- Balayer les documents, positions
      for tplDocLink in (select   PCL.DOC_DOCUMENT_ID
                                , PCL.DMT_BASE_PRICE
                                , PCL.DMT_RATE_OF_EXCHANGE
                                , POS.DOC_POSITION_ID
                                , POS.GCO_GOOD_ID
                                , nvl(POS.POS_FINAL_QUANTITY, 0) POS_FINAL_QUANTITY
                                , nvl(POS.POS_GROSS_UNIT_VALUE, 0) POS_GROSS_UNIT_VALUE
                                , nvl(POS.POS_NET_UNIT_VALUE, 0) POS_NET_UNIT_VALUE
                                , nvl(POS.POS_GROSS_VALUE, 0) POS_GROSS_VALUE
                                , nvl(POS.POS_NET_VALUE_EXCL, 0) POS_NET_VALUE_EXCL
                                , nvl(POS.POS_NET_WEIGHT, 0) POS_NET_WEIGHT
                                , nvl(POS.POS_GROSS_WEIGHT, 0) POS_GROSS_WEIGHT
                                , nvl(MEA.MEA_NET_VOLUME, 0) MEA_NET_VOLUME
                                , nvl(MEA.MEA_GROSS_VOLUME, 0) MEA_GROSS_VOLUME
                             from DOC_POSITION_COST_LINK PCL
                                , DOC_DOCUMENT DMT
                                , DOC_POSITION POS
                                , GCO_MEASUREMENT_WEIGHT MEA
                            where PCL.DOC_POSITION_COST_ID = aPosCostID
                              and PCL.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                              and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                              and POS.C_GAUGE_TYPE_POS = '1'
                              and POS.DOC_DOC_POSITION_ID is null
                              and not(    POS.DOC_DOCUMENT_ID = tplPosCostInfo.DOC_DOCUMENT_ID
                                      and POS.C_POS_CREATE_MODE = '206')
                              and POS.GCO_GOOD_ID = MEA.GCO_GOOD_ID(+)
                         order by DMT.DMT_NUMBER
                                , POS.POS_NUMBER) loop
        -- Init des données communes à tous les détails
        select INIT_ID_SEQ.nextval
             , aPosCostID
             , tplDocLink.DOC_DOCUMENT_ID
             , tplDocLink.DOC_POSITION_ID
             , tplDocLink.GCO_GOOD_ID
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          into vRow_DETAIL_COST.DOC_DETAIL_COST_ID
             , vRow_DETAIL_COST.DOC_POSITION_COST_ID
             , vRow_DETAIL_COST.DOC_DOCUMENT_ID
             , vRow_DETAIL_COST.DOC_POSITION_ID
             , vRow_DETAIL_COST.GCO_GOOD_ID
             , vRow_DETAIL_COST.A_DATECRE
             , vRow_DETAIL_COST.A_IDCRE
          from dual;

        -- Recherche toutes les valeurs du détail de frais
        GetDetailCostValues(aCurrentDocID         => tplPosCostInfo.DOC_DOCUMENT_ID
                          , aLinkDocID            => tplDocLink.DOC_DOCUMENT_ID
                          , aPositionID           => tplDocLink.DOC_POSITION_ID
                          , aGoodID               => tplDocLink.GCO_GOOD_ID
                          , aSharingMode          => tplPosCostInfo.C_SHARING_MODE
                          , aPosCostAmount        => tplPosCostInfo.POC_AMOUNT
                          , aPosCostComplAmount   => tplPosCostInfo.POC_BASIS_COMPL_AMOUNT
                          , aTotPosNetValExcl     => totPosNetValExcl
                          , aFinalQty             => tplDocLink.POS_FINAL_QUANTITY
                          , aNetUnitValue         => tplDocLink.POS_NET_UNIT_VALUE
                          , aGrossUnitValue       => tplDocLink.POS_GROSS_UNIT_VALUE
                          , aNetValueExcl         => tplDocLink.POS_NET_VALUE_EXCL
                          , aGrossValueExcl       => tplDocLink.POS_GROSS_VALUE
                          , aMeasNetVolume        => tplDocLink.MEA_NET_VOLUME
                          , aMeasGrossVolume      => tplDocLink.MEA_GROSS_VOLUME
                          , aNetWeight            => tplDocLink.POS_NET_WEIGHT
                          , aGrossWeight          => tplDocLink.POS_GROSS_WEIGHT
                          , aMatManagMode         => tplPosCostInfo.C_MATERIAL_MGNT_MODE
                          , aAlloyID              => tplPosCostInfo.GCO_ALLOY_ID
                          , aBasisMatID           => tplPosCostInfo.DIC_BASIS_MATERIAL_ID
                          , aRow_DETAIL_COST      => vRow_DETAIL_COST
                           );
        -- Additionner les montants et stocker l'id du dernier détail pour
        -- une eventuelle correction d'arrondi
        vLastDetailCostID  := vRow_DETAIL_COST.DOC_DETAIL_COST_ID;
        vDetailAmount      := vDetailAmount + vRow_DETAIL_COST.DLC_AMOUNT;

        insert into DOC_DETAIL_COST
             values vRow_DETAIL_COST;
      end loop;

      -- Le montant à répartir ne correspond pas au montant total à imputer
      if     (tplPosCostInfo.C_SHARING_MODE not in('50', '51', '52') )
         and (vDetailAmount <> tplPosCostInfo.POC_AMOUNT) then
        -- Corriger le montant à imputer du dernier détail
        update DOC_DETAIL_COST
           set DLC_AMOUNT = DLC_AMOUNT +(tplPosCostInfo.POC_AMOUNT - vDetailAmount)
         where DOC_DETAIL_COST_ID = vLastDetailCostID;
      end if;
    end if;

    close crPosCostInfo;
  end GenerateDetailCost;

  /**
  * procedure RecalcDetailCost
  * Description
  *    Récalculer les valeurs des détails de frais en appliquant la répartion sur les détails existants
  * @created NGV - mai 2006
  */
  procedure RecalcDetailCost(aPosCostID in DOC_POSITION_COST.DOC_POSITION_COST_ID%type)
  is
    cursor crPosCostInfo
    is
      select POC.PTC_COST_TYPE_ID
           , POC.DIC_BASIS_MATERIAL_ID
           , POC.GCO_ALLOY_ID
           , POC.POC_BASIS_COMPL_AMOUNT
           , POC.POC_AMOUNT
           , PCT.C_SHARING_MODE
           , PCT.PCT_COMPL_AMOUNT
           , DMT.DOC_DOCUMENT_ID
           , SUP.C_MATERIAL_MGNT_MODE
        from DOC_POSITION_COST POC
           , PTC_COST_TYPE PCT
           , DOC_DOCUMENT DMT
           , PAC_SUPPLIER_PARTNER SUP
       where POC.DOC_POSITION_COST_ID = aPosCostID
         and PCT.PTC_COST_TYPE_ID = POC.PTC_COST_TYPE_ID
         and POC.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and DMT.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+);

    cursor crCustomsRate(cGoodID in number, cDocID in number)
    is
      select   CUS.CUS_COMMISSION_RATE
             , CUS.CUS_CHARGE_RATE
             , CUS.CUS_EXCISE_RATE
          from GCO_CUSTOMS_ELEMENT CUS
             , DOC_DOCUMENT DMT
         where CUS.GCO_GOOD_ID = cGoodID
           and CUS.C_CUSTOMS_ELEMENT_TYPE = 'IMPORT'
           and DMT.DOC_DOCUMENT_ID = cDocID
           and (   CUS.PC_CNTRY_ID = DMT.PC_CNTRY_ID
                or CUS.PC_CNTRY_ID is null)
      order by nvl(CUS.PC_CNTRY_ID, 0) desc;

    tplPosCostInfo    crPosCostInfo%rowtype;
    tplCustomsRate    crCustomsRate%rowtype;
    vRow_DETAIL_COST  DOC_DETAIL_COST%rowtype;
    totRefValue       number(18, 6)                             := 0;
    totPosNetValExcl  DOC_POSITION.POS_NET_VALUE_EXCL%type      := 0;
    vLastDetailCostID DOC_DETAIL_COST.DOC_DETAIL_COST_ID%type;
    vDetailAmount     DOC_DETAIL_COST.DLC_AMOUNT%type           := 0.0;
  begin
    open crPosCostInfo;

    fetch crPosCostInfo
     into tplPosCostInfo;

    if tplPosCostInfo.POC_AMOUNT <> 0 then
      delete from COM_LIST_ID_TEMP;

      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                  )
        select distinct DOC_POSITION_ID
                   from DOC_DETAIL_COST DLC
                  where DOC_POSITION_COST_ID = aPosCostID;

      -- Recherche le diviseur du détail de frais
      GetDetailCostDivisor(aPosCostID          => aPosCostID
                         , aDocumentID         => tplPosCostInfo.DOC_DOCUMENT_ID
                         , aSharingMode        => tplPosCostInfo.C_SHARING_MODE
                         , aMatManagMode       => tplPosCostInfo.C_MATERIAL_MGNT_MODE
                         , aAlloyID            => tplPosCostInfo.GCO_ALLOY_ID
                         , aBasisMatID         => tplPosCostInfo.DIC_BASIS_MATERIAL_ID
                         , aDivisor            => vRow_DETAIL_COST.DLC_DIVISOR
                         , aTotPosNetValExcl   => totPosNetValExcl
                          );

      -- Balayer les documents, positions
      for tplDocLink in (select   DLC.DOC_DOCUMENT_ID
                                , POS.DOC_POSITION_ID
                                , POS.GCO_GOOD_ID
                                , nvl(POS.POS_FINAL_QUANTITY, 0) POS_FINAL_QUANTITY
                                , nvl(POS.POS_GROSS_UNIT_VALUE, 0) POS_GROSS_UNIT_VALUE
                                , nvl(POS.POS_NET_UNIT_VALUE, 0) POS_NET_UNIT_VALUE
                                , nvl(POS.POS_GROSS_VALUE, 0) POS_GROSS_VALUE
                                , nvl(POS.POS_NET_VALUE_EXCL, 0) POS_NET_VALUE_EXCL
                                , nvl(POS.POS_NET_WEIGHT, 0) POS_NET_WEIGHT
                                , nvl(POS.POS_GROSS_WEIGHT, 0) POS_GROSS_WEIGHT
                                , nvl(MEA.MEA_NET_VOLUME, 0) MEA_NET_VOLUME
                                , nvl(MEA.MEA_GROSS_VOLUME, 0) MEA_GROSS_VOLUME
                                , DLC.DOC_DETAIL_COST_ID
                             from DOC_DETAIL_COST DLC
                                , DOC_DOCUMENT DMT
                                , DOC_POSITION POS
                                , GCO_MEASUREMENT_WEIGHT MEA
                            where DLC.DOC_POSITION_COST_ID = aPosCostID
                              and DLC.DOC_POSITION_ID = POS.DOC_POSITION_ID
                              and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                              and POS.GCO_GOOD_ID = MEA.GCO_GOOD_ID(+)
                         order by DLC.DOC_DETAIL_COST_ID) loop
        -- Init des données communes à tous les détails
        select tplDocLink.DOC_DETAIL_COST_ID
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          into vRow_DETAIL_COST.DOC_DETAIL_COST_ID
             , vRow_DETAIL_COST.A_DATEMOD
             , vRow_DETAIL_COST.A_IDMOD
          from dual;

        -- Recherche toutes les valeurs du détail de frais
        GetDetailCostValues(aCurrentDocID         => tplPosCostInfo.DOC_DOCUMENT_ID
                          , aLinkDocID            => tplDocLink.DOC_DOCUMENT_ID
                          , aPositionID           => tplDocLink.DOC_POSITION_ID
                          , aGoodID               => tplDocLink.GCO_GOOD_ID
                          , aSharingMode          => tplPosCostInfo.C_SHARING_MODE
                          , aPosCostAmount        => tplPosCostInfo.POC_AMOUNT
                          , aPosCostComplAmount   => tplPosCostInfo.POC_BASIS_COMPL_AMOUNT
                          , aTotPosNetValExcl     => totPosNetValExcl
                          , aFinalQty             => tplDocLink.POS_FINAL_QUANTITY
                          , aNetUnitValue         => tplDocLink.POS_NET_UNIT_VALUE
                          , aGrossUnitValue       => tplDocLink.POS_GROSS_UNIT_VALUE
                          , aNetValueExcl         => tplDocLink.POS_NET_VALUE_EXCL
                          , aGrossValueExcl       => tplDocLink.POS_GROSS_VALUE
                          , aMeasNetVolume        => tplDocLink.MEA_NET_VOLUME
                          , aMeasGrossVolume      => tplDocLink.MEA_GROSS_VOLUME
                          , aNetWeight            => tplDocLink.POS_NET_WEIGHT
                          , aGrossWeight          => tplDocLink.POS_GROSS_WEIGHT
                          , aMatManagMode         => tplPosCostInfo.C_MATERIAL_MGNT_MODE
                          , aAlloyID              => tplPosCostInfo.GCO_ALLOY_ID
                          , aBasisMatID           => tplPosCostInfo.DIC_BASIS_MATERIAL_ID
                          , aRow_DETAIL_COST      => vRow_DETAIL_COST
                           );
        -- Additionner les montants et stocker l'id du dernier détail pour
        -- une eventuelle correction d'arrondi
        vLastDetailCostID  := vRow_DETAIL_COST.DOC_DETAIL_COST_ID;
        vDetailAmount      := vDetailAmount + vRow_DETAIL_COST.DLC_AMOUNT;

        update DOC_DETAIL_COST
           set DLC_BASIS_CALC_VALUE = vRow_DETAIL_COST.DLC_BASIS_CALC_VALUE
             , DLC_BASIS_REF_VALUE = vRow_DETAIL_COST.DLC_BASIS_REF_VALUE
             , DLC_COMPL_CALC_AMOUNT = vRow_DETAIL_COST.DLC_COMPL_CALC_AMOUNT
             , DLC_COMPL_REF_AMOUNT = vRow_DETAIL_COST.DLC_COMPL_REF_AMOUNT
             , DLC_BASIS_CALC_TOTAL = vRow_DETAIL_COST.DLC_BASIS_CALC_TOTAL
             , DLC_DIVISOR = vRow_DETAIL_COST.DLC_DIVISOR
             , DLC_RATE = vRow_DETAIL_COST.DLC_RATE
             , DLC_CALC_AMOUNT = vRow_DETAIL_COST.DLC_CALC_AMOUNT
             , DLC_AMOUNT = vRow_DETAIL_COST.DLC_AMOUNT
             , A_DATEMOD = vRow_DETAIL_COST.A_DATEMOD
             , A_IDMOD = vRow_DETAIL_COST.A_IDMOD
         where DOC_DETAIL_COST_ID = vRow_DETAIL_COST.DOC_DETAIL_COST_ID;
      end loop;

      -- Le montant à répartir ne correspond pas au montant total à imputer
      if     (tplPosCostInfo.C_SHARING_MODE not in('50', '51', '52') )
         and (vDetailAmount <> tplPosCostInfo.POC_AMOUNT) then
        -- Corriger le montant à imputer du dernier détail
        update DOC_DETAIL_COST
           set DLC_AMOUNT = DLC_AMOUNT +(tplPosCostInfo.POC_AMOUNT - vDetailAmount)
         where DOC_DETAIL_COST_ID = vLastDetailCostID;
      end if;
    end if;

    close crPosCostInfo;
  end RecalcDetailCost;

  /**
  * procedure GetDetailCostDivisor
  * Description
  *    Recherche le diviseur du détail de frais
  * @created NGV - mai 2006
  */
  procedure GetDetailCostDivisor(
    aPosCostID        in     DOC_POSITION_COST.DOC_POSITION_COST_ID%type
  , aDocumentID       in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSharingMode      in     varchar2
  , aMatManagMode     in     PAC_SUPPLIER_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aAlloyID          in     GCO_ALLOY.GCO_ALLOY_ID%type
  , aBasisMatID       in     DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , aDivisor          out    DOC_DETAIL_COST.DLC_DIVISOR%type
  , aTotPosNetValExcl out    DOC_POSITION.POS_NET_VALUE_EXCL%type
  )
  is
  begin
    -- Calcul du diviseur
    -- 01 : Valeur brute ht des positions
    if aSharingMode = '01' then
      select sum(nvl(POS.POS_GROSS_VALUE, 0) )
        into aDivisor
        from DOC_POSITION POS
           , COM_LIST_ID_TEMP LID
       where POS.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID;
    -- 02 : Quantité des positions
    elsif aSharingMode = '02' then
      select sum(nvl(POS.POS_FINAL_QUANTITY, 0) )
        into aDivisor
        from DOC_POSITION POS
           , COM_LIST_ID_TEMP LID
       where POS.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID;
    -- 03 : Volume net des positions
    elsif aSharingMode = '03' then
      select sum(nvl(POS.POS_FINAL_QUANTITY, 0) * nvl(MEA.MEA_NET_VOLUME, 0) )
        into aDivisor
        from DOC_POSITION POS
           , COM_LIST_ID_TEMP LID
           , GCO_MEASUREMENT_WEIGHT MEA
       where POS.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID
         and POS.GCO_GOOD_ID = MEA.GCO_GOOD_ID(+);
    -- 04 : Volume brut des positions
    elsif aSharingMode = '04' then
      select sum(nvl(POS.POS_FINAL_QUANTITY, 0) * nvl(MEA.MEA_GROSS_VOLUME, 0) )
        into aDivisor
        from DOC_POSITION POS
           , COM_LIST_ID_TEMP LID
           , GCO_MEASUREMENT_WEIGHT MEA
       where POS.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID
         and POS.GCO_GOOD_ID = MEA.GCO_GOOD_ID(+);
    -- 05 : Poids net des positions
    elsif aSharingMode = '05' then
      select sum(nvl(POS.POS_NET_WEIGHT, 0) )
        into aDivisor
        from DOC_POSITION POS
           , COM_LIST_ID_TEMP LID
       where POS.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID;
    -- 06 : Poids brut des positions
    elsif aSharingMode = '06' then
      select sum(nvl(POS.POS_GROSS_WEIGHT, 0) )
        into aDivisor
        from DOC_POSITION POS
           , COM_LIST_ID_TEMP LID
       where POS.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID;
    -- 07 : Poids matières précieuses
    elsif     aSharingMode = '07'
          and aMatManagMode is not null then
      -- 1 : Alliages
      if aMatManagMode = '1' then
        select sum(DOA.DOA_WEIGHT_DELIVERY)
          into aDivisor
          from DOC_POSITION_ALLOY DOA
             , COM_LIST_ID_TEMP LID
         where DOA.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID
           and (   DOA.GCO_ALLOY_ID = aAlloyID
                or (    DOA.GCO_ALLOY_ID is not null
                    and aAlloyID is null) );
      -- 2 : Matières de base
      elsif aMatManagMode = '2' then
        select sum(DOA.DOA_WEIGHT_DELIVERY)
          into aDivisor
          from DOC_POSITION_ALLOY DOA
             , COM_LIST_ID_TEMP LID
         where DOA.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID
           and (   DOA.DIC_BASIS_MATERIAL_ID = aBasisMatID
                or (    DOA.DIC_BASIS_MATERIAL_ID is not null
                    and aBasisMatID is null) );
      end if;
    -- 08 : Valeur nette HT des positions
    elsif aSharingMode = '08' then
      select sum(nvl(POS.POS_NET_VALUE_EXCL, 0) )
        into aDivisor
        from DOC_POSITION POS
           , COM_LIST_ID_TEMP LID
       where POS.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID;
    -- 50 : Pourcentage commission douanière
    elsif aSharingMode = '50' then
      aDivisor  := 1;

      -- valeur nette HT des positions
      select sum(nvl(POS.POS_NET_VALUE_EXCL, 0) )
        into aTotPosNetValExcl
        from DOC_POSITION POS
           , COM_LIST_ID_TEMP LID
       where POS.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID;
    -- 51 : Pourcentage taxe douanière
    elsif aSharingMode = '51' then
      aDivisor  := 1;

      -- valeur nette HT des positions
      select sum(nvl(POS.POS_NET_VALUE_EXCL, 0) )
        into aTotPosNetValExcl
        from DOC_POSITION POS
           , COM_LIST_ID_TEMP LID
       where POS.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID;
    -- 52 : Pourcentage taxe d'accises
    elsif aSharingMode = '52' then
      aDivisor  := 1;

      -- valeur nette HT des positions
      select sum(nvl(POS.POS_NET_VALUE_EXCL, 0) )
        into aTotPosNetValExcl
        from DOC_POSITION POS
           , COM_LIST_ID_TEMP LID
       where POS.DOC_POSITION_ID = LID.COM_LIST_ID_TEMP_ID;
    end if;
  end GetDetailCostDivisor;

  /**
  * procedure GetDetailCostValues
  * Description
  *    Recherche toutes les valeurs du détail de frais
  * @created NGV - mai 2006
  */
  procedure GetDetailCostValues(
    aCurrentDocID       in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aLinkDocID          in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aPositionID         in     DOC_POSITION.DOC_POSITION_ID%type
  , aGoodID             in     GCO_GOOD.GCO_GOOD_ID%type
  , aSharingMode        in     varchar2
  , aPosCostAmount      in     DOC_POSITION_COST.POC_AMOUNT%type
  , aPosCostComplAmount in     DOC_POSITION_COST.POC_BASIS_COMPL_AMOUNT%type
  , aTotPosNetValExcl   in     DOC_POSITION.POS_NET_VALUE_EXCL%type
  , aFinalQty           in     DOC_POSITION.POS_FINAL_QUANTITY%type
  , aNetUnitValue       in     DOC_POSITION.POS_NET_UNIT_VALUE%type
  , aGrossUnitValue     in     DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , aNetValueExcl       in     DOC_POSITION.POS_NET_VALUE_EXCL%type
  , aGrossValueExcl     in     DOC_POSITION.POS_GROSS_VALUE%type
  , aMeasNetVolume      in     GCO_MEASUREMENT_WEIGHT.MEA_NET_VOLUME%type
  , aMeasGrossVolume    in     GCO_MEASUREMENT_WEIGHT.MEA_GROSS_VOLUME%type
  , aNetWeight          in     DOC_POSITION.POS_NET_WEIGHT%type
  , aGrossWeight        in     DOC_POSITION.POS_GROSS_WEIGHT%type
  , aMatManagMode       in     PAC_SUPPLIER_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aAlloyID            in     GCO_ALLOY.GCO_ALLOY_ID%type
  , aBasisMatID         in     DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , aRow_DETAIL_COST    in out DOC_DETAIL_COST%rowtype
  )
  is
    cursor crCustomsRate(cGoodID in number, cDocID in number)
    is
      select   CUS.CUS_COMMISSION_RATE
             , CUS.CUS_CHARGE_RATE
             , CUS.CUS_EXCISE_RATE
          from GCO_CUSTOMS_ELEMENT CUS
             , DOC_DOCUMENT DMT
         where CUS.GCO_GOOD_ID = cGoodID
           and CUS.C_CUSTOMS_ELEMENT_TYPE = 'IMPORT'
           and DMT.DOC_DOCUMENT_ID = cDocID
           and (   CUS.PC_CNTRY_ID = DMT.PC_CNTRY_ID
                or CUS.PC_CNTRY_ID is null)
      order by nvl(CUS.PC_CNTRY_ID, 0) desc;

    tplCustomsRate crCustomsRate%rowtype;
  begin
    -- 01 : Valeur brutte HT des positions
    -- 02 : Quantité des positions
    -- 03 : Volume net des positions
    -- 04 : Volume brut des positions
    -- 05 : Poids net des positions
    -- 06 : Poids brut des positions
    -- 07 : Poids matière précieuse des positions
    -- 08 : Valeur nette HT des positions
    if aSharingMode in('01', '02', '03', '04', '05', '06', '07', '08') then
      -- 01 : Valeur brutte HT des positions
      if aSharingMode = '01' then
        -- Base calculée = Qté finale position * Prix unit. brutte HT
        aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE  := aFinalQty * aGrossUnitValue;
      -- 02 : Quantité des positions
      elsif aSharingMode = '02' then
        -- Base calculée = Qté finale position
        aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE  := aFinalQty;
      -- 03 : Volume net des positions
      elsif aSharingMode = '03' then
        -- Base calculée = Volume net position (cm3)
        aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE  := aFinalQty * aMeasNetVolume;
      -- 04 : Volume brut des positions
      elsif aSharingMode = '04' then
        -- Base calculée = Volume brut position (cm3)
        aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE  := aFinalQty * aMeasGrossVolume;
      -- 05 : Poids net des positions
      elsif aSharingMode = '05' then
        -- Base calculée = Poids net position
        aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE  := aNetWeight;
      -- 06 : Poids brut des positions
      elsif aSharingMode = '06' then
        -- Base calculée = Poids brut position
        aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE  := aGrossWeight;
      -- 07 : Poids matière précieuse des positions
      elsif aSharingMode = '07' then
        -- Base calculée = Poids matière précieuse de la matière précieuse définie sur la position frais.
        --   Si la matière de la position frais est nulle, on prendra le poids matière précieuse
        --   de toute matière confondue
        -- 1 : Alliages
        if aMatManagMode = '1' then
          select sum(DOA.DOA_WEIGHT_DELIVERY)
            into aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE
            from DOC_POSITION_ALLOY DOA
           where DOA.DOC_POSITION_ID = aPositionID
             and (   DOA.GCO_ALLOY_ID = aAlloyID
                  or (    DOA.GCO_ALLOY_ID is not null
                      and aAlloyID is null) );
        -- 2 : Matières de base
        elsif aMatManagMode = '2' then
          select sum(DOA.DOA_WEIGHT_DELIVERY)
            into aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE
            from DOC_POSITION_ALLOY DOA
           where DOA.DOC_POSITION_ID = aPositionID
             and (   DOA.DIC_BASIS_MATERIAL_ID = aBasisMatID
                  or (    DOA.DIC_BASIS_MATERIAL_ID is not null
                      and aBasisMatID is null) );
        end if;
      -- 08 : Valeur nette HT des positions
      elsif aSharingMode = '08' then
        -- Base calculée = Qté finale position * Prix unit. nette HT
        aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE  := aFinalQty * aNetUnitValue;
      end if;

      -- Base de référence = Base calculée
      aRow_DETAIL_COST.DLC_BASIS_REF_VALUE   := aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE;
      -- Base de calcul totale = Base calculée
      aRow_DETAIL_COST.DLC_BASIS_CALC_TOTAL  := aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE;

      -- Taux = Base de calcul totale / Diviseur
      if aRow_DETAIL_COST.DLC_DIVISOR = 0 then
        aRow_DETAIL_COST.DLC_RATE  := 0;
      else
        aRow_DETAIL_COST.DLC_RATE  := aRow_DETAIL_COST.DLC_BASIS_CALC_TOTAL / aRow_DETAIL_COST.DLC_DIVISOR;
      end if;

      -- Montant calculé = Montant à répartir positions frais * Taux
      aRow_DETAIL_COST.DLC_CALC_AMOUNT       := aPosCostAmount * aRow_DETAIL_COST.DLC_RATE;
      -- Montant imputé = Montant calculé
      aRow_DETAIL_COST.DLC_AMOUNT            := aRow_DETAIL_COST.DLC_CALC_AMOUNT;
    --
    -- 50 : Pourcentage commission douanière
    -- 51 : Pourcentage taxe douanière
    -- 52 : Pourcentage taxe d'accises
    elsif aSharingMode in('50', '51', '52') then
      -- Montant compl calculé
      aRow_DETAIL_COST.DLC_COMPL_CALC_AMOUNT  := (aNetValueExcl / aTotPosNetValExcl) * aPosCostComplAmount;

      if aSharingMode = '52' then
        select sum(nvl(DLC.DLC_AMOUNT, 0) ) + aRow_DETAIL_COST.DLC_COMPL_CALC_AMOUNT
          into aRow_DETAIL_COST.DLC_COMPL_CALC_AMOUNT
          from DOC_POSITION_COST POC
             , PTC_COST_TYPE PCT
             , DOC_DETAIL_COST DLC
         where POC.DOC_DOCUMENT_ID = aCurrentDocID
           and POC.PTC_COST_TYPE_ID = PCT.PTC_COST_TYPE_ID
           and PCT.C_SHARING_MODE in('50', '51')
           and POC.DOC_POSITION_COST_ID = DLC.DOC_POSITION_COST_ID
           and DLC.DOC_POSITION_ID = aPositionID;
      end if;

      -- Montant compl référence = Montant compl calculé
      aRow_DETAIL_COST.DLC_COMPL_REF_AMOUNT   := aRow_DETAIL_COST.DLC_COMPL_CALC_AMOUNT;
      -- Base calculée = Valeur nette HT positions monnaie document
      aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE   := aGrossValueExcl;
      -- Base de référence = Base calculée
      aRow_DETAIL_COST.DLC_BASIS_REF_VALUE    := aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE;
      -- Base de calcul totale = Base calculée + Montant compl référence
      aRow_DETAIL_COST.DLC_BASIS_CALC_TOTAL   := aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE + aRow_DETAIL_COST.DLC_COMPL_REF_AMOUNT;

      -- Taux  = Taux défini sur la donnée douanière de type IMPORT et dont
      --   le code pays correspond au code pays de l'adresse principale du tiers du document marchandise ou
      --   dont le code pays est NULL
      open crCustomsRate(aGoodID, aLinkDocID);

      -- NUNO attention est-ce vraiment le doc marchandise
      fetch crCustomsRate
       into tplCustomsRate;

      -- 50 : Pourcentage commission douanière
      if aSharingMode = '50' then
        aRow_DETAIL_COST.DLC_RATE  := tplCustomsRate.CUS_COMMISSION_RATE;
      -- 51 : Pourcentage taxe douanière
      elsif aSharingMode = '51' then
        aRow_DETAIL_COST.DLC_RATE  := tplCustomsRate.CUS_CHARGE_RATE;
      -- 52 : Pourcentage taxe d'accises
      elsif aSharingMode = '52' then
        aRow_DETAIL_COST.DLC_RATE  := tplCustomsRate.CUS_EXCISE_RATE;
      end if;

      close crCustomsRate;

      -- Montant calculé = Montant à répartir positions frais * Taux
      aRow_DETAIL_COST.DLC_CALC_AMOUNT        := aRow_DETAIL_COST.DLC_BASIS_CALC_TOTAL *(aRow_DETAIL_COST.DLC_RATE / 100);
      -- Montant imputé = Montant calculé
      aRow_DETAIL_COST.DLC_AMOUNT             := aRow_DETAIL_COST.DLC_CALC_AMOUNT;
    end if;

    -- Init des données communes à tous les détails
    select nvl(aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE, 0)
         , nvl(aRow_DETAIL_COST.DLC_BASIS_REF_VALUE, 0)
         , nvl(aRow_DETAIL_COST.DLC_COMPL_CALC_AMOUNT, 0)
         , nvl(aRow_DETAIL_COST.DLC_COMPL_REF_AMOUNT, 0)
         , nvl(aRow_DETAIL_COST.DLC_BASIS_CALC_TOTAL, 0)
         , nvl(aRow_DETAIL_COST.DLC_CALC_AMOUNT, 0)
         , nvl(aRow_DETAIL_COST.DLC_AMOUNT, 0)
      into aRow_DETAIL_COST.DLC_BASIS_CALC_VALUE
         , aRow_DETAIL_COST.DLC_BASIS_REF_VALUE
         , aRow_DETAIL_COST.DLC_COMPL_CALC_AMOUNT
         , aRow_DETAIL_COST.DLC_COMPL_REF_AMOUNT
         , aRow_DETAIL_COST.DLC_BASIS_CALC_TOTAL
         , aRow_DETAIL_COST.DLC_CALC_AMOUNT
         , aRow_DETAIL_COST.DLC_AMOUNT
      from dual;
  end GetDetailCostValues;

  /**
  * procedure ProcessShareCost
  * Description
  *   Répartition des frais sur le document
  * @created NGV - mai 2006
  */
  procedure ProcessShareCost(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    vPosList TPOS_LIST;
    vPOS_ID  DOC_POSITION.DOC_POSITION_ID%type;
  begin
    -- Effacer les positions du document courant pour la gestion des couts
    for tplDeletePos in (select DOC_POSITION_ID
                           from DOC_POSITION
                          where DOC_DOCUMENT_ID = aDocumentID
                            and C_POS_CREATE_MODE = '206'
                            and POS_BASIS_QUANTITY = 0) loop
      DOC_DELETE.DeletePosition(tplDeletePos.DOC_POSITION_ID, false);
    end loop;

    -- Effacer les taxes position et remises de pied du document courant
    delete from DOC_POSITION_CHARGE
          where DOC_DOCUMENT_ID = aDocumentID
            and C_CHARGE_ORIGIN = 'SC';

    delete from DOC_FOOT_CHARGE
          where DOC_FOOT_ID = aDocumentID
            and C_CHARGE_ORIGIN = 'SC';

    for tplPositionCost in (select   PCT.PTC_CHARGE_ID
                                   , PCT.PTC_DISCOUNT_ID
                                   , PCT.DIC_PTC_COST_TYPE_ID
                                   , POC.DOC_POSITION_COST_ID
                                   , POC.DOC_DOC_DOCUMENT_ID
                                   , POC.POC_AMOUNT
                                   , DMT.DOC_DOCUMENT_ID
                                   , DMT.ACS_FINANCIAL_CURRENCY_ID
                                   , DMT.DMT_RATE_OF_EXCHANGE
                                   , DMT.DMT_BASE_PRICE
                                   , DMT.DMT_DATE_DOCUMENT
                                   , DMT.PAC_THIRD_ID
                                   , DMT.PAC_THIRD_ACI_ID
                                   , DMT.PAC_THIRD_VAT_ID
                                   , DMT.PC_LANG_ID
                                   , DMT.DIC_TYPE_SUBMISSION_ID
                                   , DMT.ACS_VAT_DET_ACCOUNT_ID
                                   , DMT.DOC_RECORD_ID
                                   , DMT.ACS_FINANCIAL_ACCOUNT_ID
                                   , DMT.ACS_DIVISION_ACCOUNT_ID
                                   , DMT.ACS_CPN_ACCOUNT_ID
                                   , DMT.ACS_CDA_ACCOUNT_ID
                                   , DMT.ACS_PF_ACCOUNT_ID
                                   , DMT.ACS_PJ_ACCOUNT_ID
                                   , GAU.DOC_GAUGE_ID
                                   , GAU.C_ADMIN_DOMAIN
                                   , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
                                   , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
                                   , GAS.DIC_TYPE_MOVEMENT_ID
                                from DOC_DOCUMENT DMT
                                   , DOC_GAUGE GAU
                                   , DOC_GAUGE_STRUCTURED GAS
                                   , DOC_POSITION_COST POC
                                   , PTC_COST_TYPE PCT
                               where DMT.DOC_DOCUMENT_ID = aDocumentID
                                 and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                                 and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                                 and POC.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                                 and POC.PTC_COST_TYPE_ID = PCT.PTC_COST_TYPE_ID
                            order by PCT.C_SHARING_MODE) loop
      for tplDetail in (select   DLC.DOC_DOCUMENT_ID
                               , DLC.DOC_POSITION_ID
                               , DLC.DLC_AMOUNT
                               , DLC.DOC_DETAIL_COST_ID
                            from DOC_DETAIL_COST DLC
                               , DOC_DOCUMENT DMT
                               , DOC_POSITION POS
                           where DLC.DOC_POSITION_COST_ID = tplPositionCost.DOC_POSITION_COST_ID
                             and DLC.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                             and DLC.DOC_POSITION_ID = POS.DOC_POSITION_ID
                        order by DMT.DMT_NUMBER
                               , POS.POS_NUMBER) loop
        -- Document à imputer = Document courant
        if tplDetail.DOC_DOCUMENT_ID = aDocumentID then
          -- ID de la position sur laquelle on doit créer la taxe
          vPOS_ID  := tplDetail.DOC_POSITION_ID;
        else
          -- Document à imputer <> Document courant
          -- Création d'une position sur le doc courant par copie de la pos src
          -- avec qté = 0 et prix = 0

          -- Utilisation d'une table mémoire pour stocker les id des pos crées
          -- avec la correspondance des positions source

          -- Vérifier si l'on a déjà créé une position pour la pos src courante
          if not(vPosList.exists(tplDetail.DOC_POSITION_ID) ) then
            vPOS_ID                                         := null;
            -- Copie de la position
            DOC_POSITION_GENERATE.GeneratePosition(aPositionID               => vPOS_ID
                                                 , aDocumentID               => aDocumentID
                                                 , aTypePos                  => '1'
                                                 , aPosCreateMode            => '206'
                                                 , aSrcPositionID            => tplDetail.DOC_POSITION_ID
                                                 , aBasisQuantity            => 0
                                                 , aGoodPrice                => 0
                                                 , aGenerateDetail           => 1
                                                 , aGenerateCPT              => 1
                                                 , aGenerateDiscountCharge   => 0
                                                  );
            -- Sauvegarder l'ID de la pos qui vient d'être crée avec l'id de la pos src
            vPosList(tplDetail.DOC_POSITION_ID).NEW_POS_ID  := vPOS_ID;
          else
            -- On a déjà créé une position pour la pos src courante
            vPOS_ID  := vPosList(tplDetail.DOC_POSITION_ID).NEW_POS_ID;
          end if;
        end if;

        -- Création d'une taxe de position liée aux frais à répartir
        GeneratePosCostCharge(aPositionID      => vPOS_ID
                            , aDetailCostID    => tplDetail.DOC_DETAIL_COST_ID
                            , aChargeID        => tplPositionCost.PTC_CHARGE_ID
                            , aAmount          => tplDetail.DLC_AMOUNT
                            , aDicTypeCostID   => tplPositionCost.DIC_PTC_COST_TYPE_ID
                            , aThirdAciID      => tplPositionCost.PAC_THIRD_ACI_ID
                            , aDocumentID      => tplPositionCost.DOC_DOCUMENT_ID
                            , aDocumentDate    => tplPositionCost.DMT_DATE_DOCUMENT
                            , aCurrencyID      => tplPositionCost.ACS_FINANCIAL_CURRENCY_ID
                            , aDocExchRate     => tplPositionCost.DMT_RATE_OF_EXCHANGE
                            , aDocBasePrice    => tplPositionCost.DMT_BASE_PRICE
                            , aLangID          => tplPositionCost.PC_LANG_ID
                            , aGaugeID         => tplPositionCost.DOC_GAUGE_ID
                            , aAdminDomain     => tplPositionCost.C_ADMIN_DOMAIN
                            , aGasFinancial    => tplPositionCost.GAS_FINANCIAL
                            , aGasAnalytical   => tplPositionCost.GAS_ANALYTICAL
                             );
      end loop;

      -- Création d'une remise de pied liée aux frais à répartir
      if     (tplPositionCost.PTC_DISCOUNT_ID is not null)
         and (tplPositionCost.DOC_DOC_DOCUMENT_ID is not null) then
        GenerateFootCostDiscount(aDocumentID        => aDocumentID
                               , aPosCostID         => tplPositionCost.DOC_POSITION_COST_ID
                               , aDiscountID        => tplPositionCost.PTC_DISCOUNT_ID
                               , aAmount            => tplPositionCost.POC_AMOUNT
                               , aDicTypeCostID     => tplPositionCost.DIC_PTC_COST_TYPE_ID
                               , aThirdAciID        => tplPositionCost.PAC_THIRD_ACI_ID
                               , aThirdVatID        => tplPositionCost.PAC_THIRD_VAT_ID
                               , aRecordID          => tplPositionCost.DOC_RECORD_ID
                               , aDocumentDate      => tplPositionCost.DMT_DATE_DOCUMENT
                               , aCurrencyID        => tplPositionCost.ACS_FINANCIAL_CURRENCY_ID
                               , aDocExchRate       => tplPositionCost.DMT_RATE_OF_EXCHANGE
                               , aDocBasePrice      => tplPositionCost.DMT_BASE_PRICE
                               , aLangID            => tplPositionCost.PC_LANG_ID
                               , aGaugeID           => tplPositionCost.DOC_GAUGE_ID
                               , aAdminDomain       => tplPositionCost.C_ADMIN_DOMAIN
                               , aSubmissionType    => tplPositionCost.DIC_TYPE_SUBMISSION_ID
                               , aMvtType           => tplPositionCost.DIC_TYPE_MOVEMENT_ID
                               , aVatDetAccountID   => tplPositionCost.ACS_VAT_DET_ACCOUNT_ID
                               , aGasFinancial      => tplPositionCost.GAS_FINANCIAL
                               , aGasAnalytical     => tplPositionCost.GAS_ANALYTICAL
                                );
      end if;
    end loop;

    -- recalcul des montants des positions sur les positions touchées par les frais à répartir
    DOC_DOCUMENT_FUNCTIONS.RecalcModifPosChargeAndAmount(aDocumentID, true);
  end ProcessShareCost;

  /**
  * procedure GeneratePosCostCharge
  * Description
  *   Création d'une taxe de position liée aux frais à répartir
  * @created NGV - mai 2006
  */
  procedure GeneratePosCostCharge(
    aPositionID    in DOC_POSITION.DOC_POSITION_ID%type
  , aDetailCostID  in DOC_DETAIL_COST.DOC_DETAIL_COST_ID%type
  , aChargeID      in PTC_CHARGE.PTC_CHARGE_ID%type
  , aAmount        in DOC_POSITION_CHARGE.PCH_AMOUNT%type
  , aDicTypeCostID in DIC_PTC_COST_TYPE.DIC_PTC_COST_TYPE_ID%type
  , aThirdAciID    in DOC_DOCUMENT.PAC_THIRD_ACI_ID%type
  , aDocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDocumentDate  in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aCurrencyID    in DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aDocExchRate   in DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aDocBasePrice  in DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aLangID        in DOC_DOCUMENT.PC_LANG_ID%type
  , aGaugeID       in DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aAdminDomain   in DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aGasFinancial  in integer
  , aGasAnalytical in integer
  )
  is
    vRow_PCH        DOC_POSITION_CHARGE%rowtype;
    vAccountInfo    ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    vPOS_ACS_FIN_ID DOC_POSITION.ACS_FINANCIAL_ACCOUNT_ID%type;
    vPOS_ACS_DIV_ID DOC_POSITION.ACS_DIVISION_ACCOUNT_ID%type;
    vPOS_ACS_CPN_ID DOC_POSITION.ACS_CPN_ACCOUNT_ID%type;
    vPOS_ACS_CDA_ID DOC_POSITION.ACS_CDA_ACCOUNT_ID%type;
    vPOS_ACS_PF_ID  DOC_POSITION.ACS_PF_ACCOUNT_ID%type;
    vPOS_ACS_PJ_ID  DOC_POSITION.ACS_PJ_ACCOUNT_ID%type;
    vRecordID       DOC_POSITION.DOC_RECORD_ID%type;
  begin
    -- recherche de l'id de la taxe que l'on va créer
    select INIT_ID_SEQ.nextval
         , aAmount
         , 0
         , aDetailCostID
      into vRow_PCH.DOC_POSITION_CHARGE_ID
         , vRow_PCH.PCH_AMOUNT
         , vRow_PCH.PCH_MODIFY
         , vRow_PCH.DOC_DETAIL_COST_ID
      from dual;

    -- Si gestion des comptes financiers ou analytiques
    if    (aGasFinancial = 1)
       or (aGasAnalytical = 1) then
      -- Rechercher les comptes de la position
      select DOC_RECORD_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
        into vRecordID
           , vPOS_ACS_FIN_ID
           , vPOS_ACS_DIV_ID
           , vPOS_ACS_CPN_ID
           , vPOS_ACS_CDA_ID
           , vPOS_ACS_PF_ID
           , vPOS_ACS_PJ_ID
        from DOC_POSITION
       where DOC_POSITION_ID = aPositionID;

      -- Utilise les comptes de la taxe
      select ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
        into vRow_PCH.ACS_FINANCIAL_ACCOUNT_ID
           , vRow_PCH.ACS_DIVISION_ACCOUNT_ID
           , vRow_PCH.ACS_CPN_ACCOUNT_ID
           , vRow_PCH.ACS_CDA_ACCOUNT_ID
           , vRow_PCH.ACS_PF_ACCOUNT_ID
           , vRow_PCH.ACS_PJ_ACCOUNT_ID
        from PTC_CHARGE
       where PTC_CHARGE_ID = aChargeID;

      vAccountInfo.DEF_HRM_PERSON         := null;
      vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
      vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
      vAccountInfo.DEF_DIC_IMP_FREE1      := null;
      vAccountInfo.DEF_DIC_IMP_FREE2      := null;
      vAccountInfo.DEF_DIC_IMP_FREE3      := null;
      vAccountInfo.DEF_DIC_IMP_FREE4      := null;
      vAccountInfo.DEF_DIC_IMP_FREE5      := null;
      vAccountInfo.DEF_TEXT1              := null;
      vAccountInfo.DEF_TEXT2              := null;
      vAccountInfo.DEF_TEXT3              := null;
      vAccountInfo.DEF_TEXT4              := null;
      vAccountInfo.DEF_TEXT5              := null;
      vAccountInfo.DEF_NUMBER1            := null;
      vAccountInfo.DEF_NUMBER2            := null;
      vAccountInfo.DEF_NUMBER3            := null;
      vAccountInfo.DEF_NUMBER4            := null;
      vAccountInfo.DEF_NUMBER5            := null;
      -- recherche des comptes
      ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(aChargeID
                                               , '30'
                                               , aAdminDomain
                                               , aDocumentDate
                                               , aGaugeID
                                               , aDocumentID
                                               , aPositionID
                                               , vRecordID
                                               , aThirdAciID
                                               , vPOS_ACS_FIN_ID
                                               , vPOS_ACS_DIV_ID
                                               , vPOS_ACS_CPN_ID
                                               , vPOS_ACS_CDA_ID
                                               , vPOS_ACS_PF_ID
                                               , vPOS_ACS_PJ_ID
                                               , vRow_PCH.ACS_FINANCIAL_ACCOUNT_ID
                                               , vRow_PCH.ACS_DIVISION_ACCOUNT_ID
                                               , vRow_PCH.ACS_CPN_ACCOUNT_ID
                                               , vRow_PCH.ACS_CDA_ACCOUNT_ID
                                               , vRow_PCH.ACS_PF_ACCOUNT_ID
                                               , vRow_PCH.ACS_PJ_ACCOUNT_ID
                                               , vAccountInfo
                                                );

      if (aGasAnalytical = 0) then
        vRow_PCH.ACS_CPN_ACCOUNT_ID  := null;
        vRow_PCH.ACS_CDA_ACCOUNT_ID  := null;
        vRow_PCH.ACS_PJ_ACCOUNT_ID   := null;
        vRow_PCH.ACS_PF_ACCOUNT_ID   := null;
      end if;
    end if;

    -- calcul du montant fixe en monnaie de base
    select ACS_FUNCTION.ConvertAmountForView(vRow_PCH.PCH_AMOUNT, aCurrencyID, ACS_FUNCTION.GetLocalCurrencyId, aDocumentDate, aDocExchRate, aDocBasePrice, 0)
      into vRow_PCH.PCH_FIXED_AMOUNT_B
      from dual;

    vRow_PCH.DOC_POSITION_ID        := aPositionID;
    vRow_PCH.PTC_CHARGE_ID          := aChargeID;
    vRow_PCH.C_CHARGE_ORIGIN        := 'SC';
    vRow_PCH.C_FINANCIAL_CHARGE     := '03';

    -- Rechercher nom et descr de la taxe
    select CRG.CRG_NAME
         , substr(CHD.CHD_DESCR || ' - ' || COM_DIC_FUNCTIONS.GetDicoDescr('DIC_PTC_COST_TYPE', aDicTypeCostID, aLangID), 1, 255)
         , CRG.CRG_IN_SERIE_CALCULATION
         , 0 CRG_EXCLUSIVE
         , CRG.CRG_PRCS_USE
      into vRow_PCH.PCH_NAME
         , vRow_PCH.PCH_DESCRIPTION
         , vRow_PCH.PCH_IN_SERIES_CALCULATION
         , vRow_PCH.PCH_EXCLUSIVE
         , vRow_PCH.PCH_PRCS_USE
      from PTC_CHARGE CRG
         , PTC_CHARGE_DESCRIPTION CHD
     where CRG.PTC_CHARGE_ID = aChargeID
       and CHD.PTC_CHARGE_ID = CRG.PTC_CHARGE_ID
       and CHD.PC_LANG_ID(+) = aLangID;

    vRow_PCH.C_CALCULATION_MODE     := '0';
    vRow_PCH.HRM_PERSON_ID          := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON);
    vRow_PCH.FAM_FIXED_ASSETS_ID    := vAccountInfo.FAM_FIXED_ASSETS_ID;
    vRow_PCH.C_FAM_TRANSACTION_TYP  := vAccountInfo.C_FAM_TRANSACTION_TYP;
    vRow_PCH.PCH_IMP_TEXT_1         := vAccountInfo.DEF_TEXT1;
    vRow_PCH.PCH_IMP_TEXT_2         := vAccountInfo.DEF_TEXT2;
    vRow_PCH.PCH_IMP_TEXT_3         := vAccountInfo.DEF_TEXT3;
    vRow_PCH.PCH_IMP_TEXT_4         := vAccountInfo.DEF_TEXT4;
    vRow_PCH.PCH_IMP_TEXT_5         := vAccountInfo.DEF_TEXT5;
    vRow_PCH.PCH_IMP_NUMBER_1       := to_number(vAccountInfo.DEF_NUMBER1);
    vRow_PCH.PCH_IMP_NUMBER_2       := to_number(vAccountInfo.DEF_NUMBER2);
    vRow_PCH.PCH_IMP_NUMBER_3       := to_number(vAccountInfo.DEF_NUMBER3);
    vRow_PCH.PCH_IMP_NUMBER_4       := to_number(vAccountInfo.DEF_NUMBER4);
    vRow_PCH.PCH_IMP_NUMBER_5       := to_number(vAccountInfo.DEF_NUMBER5);
    vRow_PCH.DIC_IMP_FREE1_ID       := vAccountInfo.DEF_DIC_IMP_FREE1;
    vRow_PCH.DIC_IMP_FREE2_ID       := vAccountInfo.DEF_DIC_IMP_FREE2;
    vRow_PCH.DIC_IMP_FREE3_ID       := vAccountInfo.DEF_DIC_IMP_FREE3;
    vRow_PCH.DIC_IMP_FREE4_ID       := vAccountInfo.DEF_DIC_IMP_FREE4;
    vRow_PCH.DIC_IMP_FREE5_ID       := vAccountInfo.DEF_DIC_IMP_FREE5;
    DOC_DISCOUNT_CHARGE.InsertPositionCharge(vRow_PCH);

    -- Màj des flags de la position pour que les montants soient recalculés
    update DOC_POSITION
       set POS_CREATE_POSITION_CHARGE = 0
         , POS_UPDATE_POSITION_CHARGE = 1
         , POS_RECALC_AMOUNTS = 1
     where DOC_POSITION_ID = aPositionID;
  end GeneratePosCostCharge;

  /**
  * procedure GenerateFootCostDiscount
  * Description
  *   Création d'une remise de pied liée aux frais à répartir
  * @created NGV - mai 2006
  */
  procedure GenerateFootCostDiscount(
    aDocumentID      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aPosCostID       in DOC_POSITION_COST.DOC_POSITION_COST_ID%type
  , aDiscountID      in PTC_DISCOUNT.PTC_DISCOUNT_ID%type
  , aAmount          in DOC_FOOT_CHARGE.FCH_FIXED_AMOUNT%type
  , aDicTypeCostID   in DIC_PTC_COST_TYPE.DIC_PTC_COST_TYPE_ID%type
  , aThirdAciID      in DOC_DOCUMENT.PAC_THIRD_ACI_ID%type
  , aThirdVatID      in DOC_DOCUMENT.PAC_THIRD_ID%type
  , aRecordID        in DOC_DOCUMENT.DOC_RECORD_ID%type
  , aDocumentDate    in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aCurrencyID      in DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aDocExchRate     in DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aDocBasePrice    in DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aLangID          in DOC_DOCUMENT.PC_LANG_ID%type
  , aGaugeID         in DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aAdminDomain     in DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aSubmissionType  in DOC_DOCUMENT.DIC_TYPE_SUBMISSION_ID%type
  , aMvtType         in DOC_GAUGE_STRUCTURED.DIC_TYPE_MOVEMENT_ID%type
  , aVatDetAccountID in DOC_DOCUMENT.ACS_VAT_DET_ACCOUNT_ID%type
  , aGasFinancial    in integer
  , aGasAnalytical   in integer
  )
  is
    cursor crDiscount
    is
      select DNT.PTC_DISCOUNT_ID
           , substr(nvl(DID.DID_DESCR, DNT.DNT_NAME) || ' - ' || COM_DIC_FUNCTIONS.GetDicoDescr('DIC_PTC_COST_TYPE', aDicTypeCostID, aLangID), 1, 255)
                                                                                                                                                      DNT_DESCR
           , DNT.DNT_NAME
           , DNT.ACS_FINANCIAL_ACCOUNT_ID
           , DNT.ACS_DIVISION_ACCOUNT_ID
           , DNT.ACS_CPN_ACCOUNT_ID
           , DNT.ACS_CDA_ACCOUNT_ID
           , DNT.ACS_PF_ACCOUNT_ID
           , DNT.ACS_PJ_ACCOUNT_ID
           , DNT.C_DISCOUNT_TYPE
           , nvl(DNT_IN_SERIES_CALCULATION, 0) DNT_IN_SERIES_CALCULATION
           , 0 DNT_EXCLUSIVE
        from PTC_DISCOUNT DNT
           , PTC_DISCOUNT_DESCR DID
       where DNT.PTC_DISCOUNT_ID = aDiscountID
         and DNT.PTC_DISCOUNT_ID = DID.PTC_DISCOUNT_ID(+)
         and DID.PC_LANG_ID(+) = aLangID;

    vRow_FCH     DOC_FOOT_CHARGE%rowtype;
    vAccountInfo ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    tplDiscount  crDiscount%rowtype;
  begin
    -- recherche de l'id de la remise que l'on va créer
    select INIT_ID_SEQ.nextval
         , aAmount
         , 0
         , aPosCostID
      into vRow_FCH.DOC_FOOT_CHARGE_ID
         , vRow_FCH.FCH_FIXED_AMOUNT
         , vRow_FCH.FCH_MODIFY
         , vRow_FCH.DOC_POSITION_COST_ID
      from dual;

    open crDiscount;

    fetch crDiscount
     into tplDiscount;

    close crDiscount;

    -- Si gestion des comptes financiers ou analytiques
    if    (aGasFinancial = 1)
       or (aGasAnalytical = 1) then
      -- Utilise les comptes de la remise
      vRow_FCH.ACS_FINANCIAL_ACCOUNT_ID   := tplDiscount.ACS_FINANCIAL_ACCOUNT_ID;
      vRow_FCH.ACS_DIVISION_ACCOUNT_ID    := tplDiscount.ACS_DIVISION_ACCOUNT_ID;
      vRow_FCH.ACS_CPN_ACCOUNT_ID         := tplDiscount.ACS_CPN_ACCOUNT_ID;
      vRow_FCH.ACS_CDA_ACCOUNT_ID         := tplDiscount.ACS_CDA_ACCOUNT_ID;
      vRow_FCH.ACS_PF_ACCOUNT_ID          := tplDiscount.ACS_PF_ACCOUNT_ID;
      vRow_FCH.ACS_PJ_ACCOUNT_ID          := tplDiscount.ACS_PJ_ACCOUNT_ID;
      vAccountInfo.DEF_HRM_PERSON         := null;
      vAccountInfo.FAM_FIXED_ASSETS_ID    := null;
      vAccountInfo.C_FAM_TRANSACTION_TYP  := null;
      vAccountInfo.DEF_DIC_IMP_FREE1      := null;
      vAccountInfo.DEF_DIC_IMP_FREE2      := null;
      vAccountInfo.DEF_DIC_IMP_FREE3      := null;
      vAccountInfo.DEF_DIC_IMP_FREE4      := null;
      vAccountInfo.DEF_DIC_IMP_FREE5      := null;
      vAccountInfo.DEF_TEXT1              := null;
      vAccountInfo.DEF_TEXT2              := null;
      vAccountInfo.DEF_TEXT3              := null;
      vAccountInfo.DEF_TEXT4              := null;
      vAccountInfo.DEF_TEXT5              := null;
      vAccountInfo.DEF_NUMBER1            := null;
      vAccountInfo.DEF_NUMBER2            := null;
      vAccountInfo.DEF_NUMBER3            := null;
      vAccountInfo.DEF_NUMBER4            := null;
      vAccountInfo.DEF_NUMBER5            := null;
      -- recherche des comptes
      ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscount.PTC_DISCOUNT_ID
                                               , '20'
                                               , aAdminDomain
                                               , aDocumentDate
                                               , aGaugeID
                                               , aDocumentID
                                               , null
                                               , aRecordID
                                               , aThirdAciID
                                               , null
                                               , null
                                               , null
                                               , null
                                               , null
                                               , null
                                               , vRow_FCH.ACS_FINANCIAL_ACCOUNT_ID
                                               , vRow_FCH.ACS_DIVISION_ACCOUNT_ID
                                               , vRow_FCH.ACS_CPN_ACCOUNT_ID
                                               , vRow_FCH.ACS_CDA_ACCOUNT_ID
                                               , vRow_FCH.ACS_PF_ACCOUNT_ID
                                               , vRow_FCH.ACS_PJ_ACCOUNT_ID
                                               , vAccountInfo
                                                );

      if (aGasAnalytical = 0) then
        vRow_FCH.ACS_CPN_ACCOUNT_ID  := null;
        vRow_FCH.ACS_CDA_ACCOUNT_ID  := null;
        vRow_FCH.ACS_PJ_ACCOUNT_ID   := null;
        vRow_FCH.ACS_PF_ACCOUNT_ID   := null;
      end if;
    end if;

    vRow_FCH.ACS_TAX_CODE_ID            :=
      ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(tplDiscount.C_DISCOUNT_TYPE
                                            , aThirdVatID
                                            , 0
                                            , tplDiscount.PTC_DISCOUNT_ID
                                            , null
                                            , aAdminDomain
                                            , aSubmissionType
                                            , aMvtType
                                            , aVatDetAccountID
                                             );
    vRow_FCH.DOC_FOOT_ID                := aDocumentID;
    vRow_FCH.C_CHARGE_ORIGIN            := 'SC';   -- Frais à répartir
    vRow_FCH.C_FINANCIAL_CHARGE         := '02';   -- Remise
    vRow_FCH.FCH_NAME                   := tplDiscount.DNT_NAME;
    vRow_FCH.FCH_DESCRIPTION            := tplDiscount.DNT_DESCR;
    vRow_FCH.FCH_EXCL_AMOUNT            := aAmount;
    vRow_FCH.FCH_INCL_AMOUNT            := aAmount;   -- TVA calculée ultérieurement
    vRow_FCH.FCH_FIXED_AMOUNT_B         :=
                         ACS_FUNCTION.ConvertAmountForView(aAmount, aCurrencyID, ACS_FUNCTION.GetLocalCurrencyID, aDocumentDate, aDocExchRate, aDocBasePrice, 0);
    vRow_FCH.C_CALCULATION_MODE         := '0';
    vRow_FCH.FCH_IN_SERIES_CALCULATION  := tplDiscount.DNT_IN_SERIES_CALCULATION;
    vRow_FCH.FCH_EXCLUSIVE              := tplDiscount.DNT_EXCLUSIVE;
    vRow_FCH.FCH_MODIFY                 := 0;
    vRow_FCH.PTC_DISCOUNT_ID            := tplDiscount.PTC_DISCOUNT_ID;
    vRow_FCH.HRM_PERSON_ID              := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON);
    vRow_FCH.FAM_FIXED_ASSETS_ID        := vAccountInfo.FAM_FIXED_ASSETS_ID;
    vRow_FCH.C_FAM_TRANSACTION_TYP      := vAccountInfo.C_FAM_TRANSACTION_TYP;
    vRow_FCH.FCH_IMP_TEXT_1             := vAccountInfo.DEF_TEXT1;
    vRow_FCH.FCH_IMP_TEXT_2             := vAccountInfo.DEF_TEXT2;
    vRow_FCH.FCH_IMP_TEXT_3             := vAccountInfo.DEF_TEXT3;
    vRow_FCH.FCH_IMP_TEXT_4             := vAccountInfo.DEF_TEXT4;
    vRow_FCH.FCH_IMP_TEXT_5             := vAccountInfo.DEF_TEXT5;
    vRow_FCH.FCH_IMP_NUMBER_1           := to_number(vAccountInfo.DEF_NUMBER1);
    vRow_FCH.FCH_IMP_NUMBER_2           := to_number(vAccountInfo.DEF_NUMBER2);
    vRow_FCH.FCH_IMP_NUMBER_3           := to_number(vAccountInfo.DEF_NUMBER3);
    vRow_FCH.FCH_IMP_NUMBER_4           := to_number(vAccountInfo.DEF_NUMBER4);
    vRow_FCH.FCH_IMP_NUMBER_5           := to_number(vAccountInfo.DEF_NUMBER5);
    vRow_FCH.DIC_IMP_FREE1_ID           := vAccountInfo.DEF_DIC_IMP_FREE1;
    vRow_FCH.DIC_IMP_FREE2_ID           := vAccountInfo.DEF_DIC_IMP_FREE2;
    vRow_FCH.DIC_IMP_FREE3_ID           := vAccountInfo.DEF_DIC_IMP_FREE3;
    vRow_FCH.DIC_IMP_FREE4_ID           := vAccountInfo.DEF_DIC_IMP_FREE4;
    vRow_FCH.DIC_IMP_FREE5_ID           := vAccountInfo.DEF_DIC_IMP_FREE5;
    -- création de la taxe de pied
    DOC_DISCOUNT_CHARGE.InsertFootCharge(vRow_FCH);

    -- Ne pas créer les remises/taxes de pied standard si crées ci-dessus
    update DOC_DOCUMENT
       set DMT_CREATE_FOOT_CHARGE = 0
     where DOC_DOCUMENT_ID = aDocumentID;
  end GenerateFootCostDiscount;

  /**
  * procedure DeleteDOC_POS_COST
  * Description
  *   Processus d'éffacement d'une ligne de DOC_POSITION_COST
  * @created NGV - mai 2006
  */
  procedure DeleteDOC_POS_COST(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aPosCostID in DOC_POSITION_COST.DOC_POSITION_COST_ID%type)
  is
    vDocID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Effacer l'eventuelle remise de pied concernant le frais à répartir
    delete from DOC_FOOT_CHARGE
          where DOC_FOOT_ID = aDocumentID
            and DOC_POSITION_COST_ID = aPosCostID
            and C_CHARGE_ORIGIN = 'SC';

    -- Effaceer les liens documents des frais à répartir
    delete from DOC_POSITION_COST_LINK
          where DOC_POSITION_COST_ID = aPosCostID;

    for tplDetail in (select DOC_DETAIL_COST_ID
                        from DOC_DETAIL_COST
                       where DOC_POSITION_COST_ID = aPosCostID) loop
      DeleteDOC_DETAIL_COST(aDocumentID, tplDetail.DOC_DETAIL_COST_ID);
    end loop;

    delete from DOC_POSITION_COST
          where DOC_POSITION_COST_ID = aPosCostID;
  end DeleteDOC_POS_COST;

  /**
  * procedure DeleteDOC_POS_COST_LINK
  * Description
  *   Processus d'éffacement d'une ligne de DOC_POSITION_COST_LINK
  * @created NGV - mai 2006
  */
  procedure DeleteDOC_POS_COST_LINK(
    aDocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aPosCostID     in DOC_POSITION_COST.DOC_POSITION_COST_ID%type
  , aPosCostLinkID in DOC_POSITION_COST_LINK.DOC_POSITION_COST_LINK_ID%type
  )
  is
    vDOC_DOC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    select DOC_DOCUMENT_ID
      into vDOC_DOC_ID
      from DOC_POSITION_COST_LINK
     where DOC_POSITION_COST_LINK_ID = aPosCostLinkID;

    for tplDetail in (select DOC_DETAIL_COST_ID
                        from DOC_DETAIL_COST
                       where DOC_POSITION_COST_ID = aPosCostID
                         and DOC_DOCUMENT_ID = vDOC_DOC_ID) loop
      DeleteDOC_DETAIL_COST(aDocumentID, tplDetail.DOC_DETAIL_COST_ID);
    end loop;

    delete from DOC_POSITION_COST_LINK
          where DOC_POSITION_COST_LINK_ID = aPosCostLinkID;
  end DeleteDOC_POS_COST_LINK;

  /**
  * procedure DeleteDOC_DETAIL_COST
  * Description
  *   Processus d'éffacement d'une ligne de DOC_DETAIL_COST
  * @created NGV - mai 2006
  */
  procedure DeleteDOC_DETAIL_COST(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDetailCostID in DOC_DETAIL_COST.DOC_DETAIL_COST_ID%type)
  is
  begin
    -- Effacer la taxe concernant le frais à répartir
    delete from DOC_POSITION_CHARGE
          where DOC_DOCUMENT_ID = aDocumentID
            and DOC_DETAIL_COST_ID = aDetailCostID
            and C_CHARGE_ORIGIN = 'SC';

    delete from DOC_DETAIL_COST
          where DOC_DETAIL_COST_ID = aDetailCostID;

    -- Effacer les positions crées par le processus des frais à répartir qui n'ont plus de taxes
    for tplPos in (select POS.DOC_POSITION_ID
                     from DOC_POSITION POS
                    where POS.DOC_DOCUMENT_ID = aDocumentID
                      and POS.C_POS_CREATE_MODE = '206'
                      and (select count(*)
                             from DOC_POSITION_CHARGE
                            where DOC_POSITION_ID = POS.DOC_POSITION_ID) = 0) loop
      DOC_DELETE.DeletePosition(tplPos.DOC_POSITION_ID, false);
    end loop;
  end DeleteDOC_DETAIL_COST;
end DOC_SHARE_COST_FUNCTIONS;
