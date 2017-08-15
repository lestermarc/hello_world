--------------------------------------------------------
--  DDL for Package Body DOC_PACKING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PACKING" 
as
  function GetPacking(aDocumentId in varchar2)
    return varchar2
  is
    type pereTyp is record(
      Doc_Id       number
    , packing_type varchar2(10)
    , Qty_Doc      number
    , Qty_pack     number
    );

    detail pereTyp;
    retour varchar(1);
  begin
    select   det.DOC_DOCUMENT_ID
           , min(gau.C_PACKING_TYPE)
           , sum(det.PDE_FINAL_QUANTITY)
           , nvl(sum(pac.PAP_QUANTITY), 0)
        into detail
        from DOC_PACKING_PARCEL_POS pac
           , doc_position_detail det
           , doc_gauge gau
       where gau.DOC_GAUGE_ID = det.DOC_GAUGE_ID
         and det.DOC_POSITION_DETAIL_ID = pac.DOC_POSITION_DETAIL_ID(+)
         and det.DOC_DOCUMENT_ID = aDocumentId
    group by det.DOC_DOCUMENT_ID;

    --TEST
    if detail.Qty_pack > 0 then
      if detail.qty_doc = detail.qty_pack then
        -- Packing terminé
        retour  := 3;
      else
        -- Packing en cours
        retour  := 2;
      end if;
    else
      if detail.packing_type = '0' then
        --Pas de packing autorisé
        retour  := 0;
      else
        if detail.packing_type = '2' then
          -- Packing en cours
          retour  := 1;
        else
          -- Packing possible
          retour  := 1;
        end if;
      end if;
    end if;

    return Retour;
  end GetPacking;

  -- Détermine si un document peut être validé, en tenant compte des positions de
  -- colis et du gabarit
  function PackingValidate(aDocumentId in number)
    return boolean
  is
    PackingType DOC_GAUGE.C_PACKING_TYPE%type;
    GaugeId     DOC_GAUGE.DOC_GAUGE_ID%type;
    result      boolean;
    Quantity    DOC_PACKING_PARCEL_POS.PAP_QUANTITY%type;
    FinQuantity DOC_POSITION.POS_FINAL_QUANTITY%type;
    TypePos     varchar2(80);
  begin
    result  := true;

    -- recherche id gauge en fonction id document
    select DOC_GAUGE_ID
      into GaugeId
      from DOC_DOCUMENT DOC
     where DOC_DOCUMENT_ID = aDocumentId;

    -- recherche condition packing en fonction id gauge
    select C_PACKING_TYPE
      into PackingType
      from DOC_GAUGE GAU
     where GAU.DOC_GAUGE_ID = GaugeId;

    -- si colis obligatoire
    if PackingType = '2' then
      -- Recheche les types de position à prendre en compte pour le contrôle.
      TypePos  := PCS.PC_CONFIG.GetConfig('DOC_PACKING_POSITIONS');

      if    TypePos is null
         or (TypePos = '') then
        TypePos  := ',1,7,8,9,10,';
      end if;

      -- recherche quantité document et quantité en colis
      select nvl(POS.POS_FINAL_QUANTITY, 0)
           , nvl(PAP.PAP_QUANTITY, 0)
        into FinQuantity
           , Quantity
        from (select   Pap.DOC_DOCUMENT_ID DOC_DOCUMENT_ID
                     , sum(PAP_QUANTITY) PAP_QUANTITY
                  from DOC_PACKING_PARCEL_POS PAP
                 where PAP.DOC_DOCUMENT_ID = aDocumentId
              group by PAP.DOC_DOCUMENT_ID) PAP
           , (select
                       -- MAX nécessaire si la requête interne ne donne aucun résultat
                       max(POS.DOC_DOCUMENT_ID) DOC_DOCUMENT_ID
                     , max(sum(POS.POS_FINAL_QUANTITY) ) POS_FINAL_QUANTITY
                  from DOC_POSITION POS
                 where POS.DOC_DOCUMENT_ID = aDocumentId
                   and instr(TypePos, ',' || POS.C_GAUGE_TYPE_POS || ',') > 0
              group by POS.DOC_DOCUMENT_ID) POS
       where POS.DOC_DOCUMENT_ID = PAP.DOC_DOCUMENT_ID(+);

      -- si quantité document > quantité en colis
      if FinQuantity > Quantity then
        result  := false;
      end if;
    end if;

    return result;
  end PackingValidate;

  -- Procédure chargée de mettre à jour tous les colis contenant des positions
  -- provenant du détail position donné en paramètre.
  procedure UpdateParcels(aDocDetailPosId in number)
  is
    -- curseur sur les positions des colis
    cursor doc_parcel_positions(DocDetailPosId number)
    is
      select   pap.DOC_PACKING_PARCEL_ID doc_packing_parcel_id
             , sum(pap.PAP_TOT_NET_WEIGHT) pap_tot_net_weight
             , sum(pap.PAP_TOT_GROSS_WEIGHT) pap_tot_gross_weight
          from DOC_PACKING_PARCEL_POS pap
         where pap.DOC_POSITION_DETAIL_ID = DocDetailPosId
      group by pap.DOC_PACKING_PARCEL_ID;

    parcel doc_parcel_positions%rowtype;
  begin
    -- Ouverture du curseur sur les colis
    open DOC_PARCEL_POSITIONS(aDocDetailPosID);

    fetch DOC_PARCEL_POSITIONS
     into parcel;

    -- Pour tous les colis, on met à jour les poids calculés
    while DOC_PARCEL_POSITIONS%found loop
      update DOC_PACKING_PARCEL
         set PAR_NET_WEIGHT_CALC = nvl(PAR_NET_WEIGHT_CALC, 0) - parcel.PAP_TOT_NET_WEIGHT
           , PAR_GROSS_WEIGHT_CALC = nvl(PAR_GROSS_WEIGHT_CALC, 0) - parcel.PAP_TOT_GROSS_WEIGHT
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_PACKING_PARCEL_ID = parcel.DOC_PACKING_PARCEL_ID;

      -- Colis suivant
      fetch DOC_PARCEL_POSITIONS
       into parcel;
    end loop;

    close DOC_PARCEL_POSITIONS;
  end UpdateParcels;

  -- Procédure chargée de supprimer toutes les positions de colis provenant
  -- du détail position donné en paramètre.
  procedure DeleteParcelPositions(aDocDetailPosId in number)
  is
  begin
    delete      DOC_PACKING_PARCEL_POS
          where DOC_POSITION_DETAIL_ID = aDocDetailPosId;
  end DeleteParcelPositions;

  /**
  * procedure InsertPackTmpPosByDoc
  * Description
  *   Insertion dans la table DOC_PACKING_TMP_POSITION la position passée en param
  */
  procedure InsertPackTmpPos(aPackListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type, aPositionID in DOC_POSITION.DOC_POSITION_ID%type)
  is
    vCfgDefPackType      varchar2(30);
    vDIC_PACKING_TYPE_ID DIC_PACKING_TYPE.DIC_PACKING_TYPE_ID%type   default null;
  begin
    -- Config Type d'emballage par défaut
    vCfgDefPackType  := PCS.PC_CONFIG.GetConfig('DOC_EDEC_DEFAULT_PACKING_TYPE');

    -- Rechercher le type d'emballage au niveau des données compl. de vente du bien
    begin
      select nvl(CSA.DIC_PACKING_TYPE_ID, vCfgDefPackType)
        into vDIC_PACKING_TYPE_ID
        from DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , GCO_COMPL_DATA_SALE CSA
       where POS.DOC_POSITION_ID = aPositionID
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and CSA.GCO_COMPL_DATA_SALE_ID = GCO_LIB_COMPL_DATA.GetComplDataSaleID(POS.GCO_GOOD_ID, DMT.PAC_THIRD_CDA_ID)
         and CSA.CSA_GOOD_PACKED = 1;
    exception
      when no_data_found then
        vDIC_PACKING_TYPE_ID  := vCfgDefPackType;
    end;

    insert into DOC_PACKING_TMP_POSITION
                (PAR_NUMBER
               , PAR_QUANTITY
               , DOC_PACKING_LIST_ID
               , DIC_PACKING_TYPE_ID
               , DOC_POSITION_ID
               , DOC_DOCUMENT_ID
               , C_GAUGE_TYPE_POS
               , C_DOC_POS_STATUS
               , GCO_GOOD_ID
               , DOC_GAUGE_POSITION_ID
               , DOC_RECORD_ID
               , STM_STOCK_ID
               , STM_STM_STOCK_ID
               , STM_LOCATION_ID
               , STM_STM_LOCATION_ID
               , STM_MOVEMENT_KIND_ID
               , ACS_TAX_CODE_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , POS_NUMBER
               , POS_REFERENCE
               , POS_SHORT_DESCRIPTION
               , POS_LONG_DESCRIPTION
               , POS_FREE_DESCRIPTION
               , POS_BODY_TEXT
               , POS_GENERATE_MOVEMENT
               , POS_STOCK_OUTAGE
               , POS_DISCOUNT_AMOUNT
               , POS_CHARGE_AMOUNT
               , POS_VAT_AMOUNT
               , POS_VAT_BASE_AMOUNT
               , POS_GROSS_UNIT_VALUE
               , POS_NET_UNIT_VALUE
               , POS_NET_UNIT_VALUE_INCL
               , POS_REF_UNIT_VALUE
               , POS_GROSS_VALUE
               , POS_NET_VALUE_EXCL
               , POS_NET_VALUE_INCL
               , POS_BASIS_QUANTITY
               , POS_INTERMEDIATE_QUANTITY
               , POS_FINAL_QUANTITY
               , POS_BALANCE_QUANTITY
               , POS_RATE_FACTOR
               , POS_NET_WEIGHT
               , POS_GROSS_WEIGHT
               , DIC_UNIT_OF_MEASURE_ID
               , POS_CONVERT_FACTOR
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , POS_NOM_TEXT
               , POS_UNIT_COST_PRICE
               , POS_EAN_CODE
               , POS_EAN_UCC14_CODE
               , POS_HIBC_PRIMARY_CODE
               , PC_APPLTXT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , DIC_POS_FREE_TABLE_1_ID
               , DIC_POS_FREE_TABLE_2_ID
               , DIC_POS_FREE_TABLE_3_ID
               , POS_DECIMAL_1
               , POS_DECIMAL_2
               , POS_DECIMAL_3
               , POS_TEXT_1
               , POS_TEXT_2
               , POS_TEXT_3
               , POS_DATE_1
               , POS_DATE_2
               , POS_DATE_3
               , POS_DISCOUNT_UNIT_VALUE
               , POS_DISCOUNT_RATE
               , PAC_REPRESENTATIVE_ID
               , DOC_EXTRACT_COMMISSION_ID
               , POS_VALUE_QUANTITY
               , POS_INCLUDE_TAX_TARIFF
               , POS_GROSS_UNIT_VALUE_INCL
               , POS_GROSS_VALUE_INCL
               , POS_BALANCE_QTY_VALUE
               , CML_POSITION_ID
               , DOC_DOC_POSITION_ID
               , POS_UTIL_COEFF
               , POS_GROSS_UNIT_VALUE2
               , PAC_THIRD_ID
               , DOC_GAUGE_ID
               , DIC_DIC_UNIT_OF_MEASURE_ID
               , POS_CONVERT_FACTOR2
               , POS_VAT_AMOUNT_E
               , POS_NET_VALUE_EXCL_B
               , POS_NET_VALUE_EXCL_E
               , POS_NET_VALUE_INCL_B
               , POS_NET_VALUE_INCL_E
               , POS_MODIFY_RATE
               , POS_GROSS_VALUE_B
               , POS_GROSS_VALUE_E
               , POS_GROSS_VALUE_INCL_B
               , POS_GROSS_VALUE_INCL_E
               , POS_VAT_AMOUNT_V
               , POS_GROSS_VALUE_V
               , POS_GROSS_VALUE_INCL_V
               , POS_NET_VALUE_EXCL_V
               , POS_NET_VALUE_INCL_V
                )
      select 0 as PAR_NUMBER
           , 0 as PAR_QUANTITY
           , aPackListID as DOC_PACKING_LIST_ID
           , vDIC_PACKING_TYPE_ID as DIC_PACKING_TYPE_ID
           , POS.DOC_POSITION_ID
           , POS.DOC_DOCUMENT_ID
           , POS.C_GAUGE_TYPE_POS
           , POS.C_DOC_POS_STATUS
           , POS.GCO_GOOD_ID
           , POS.DOC_GAUGE_POSITION_ID
           , POS.DOC_RECORD_ID
           , POS.STM_STOCK_ID
           , POS.STM_STM_STOCK_ID
           , POS.STM_LOCATION_ID
           , POS.STM_STM_LOCATION_ID
           , POS.STM_MOVEMENT_KIND_ID
           , POS.ACS_TAX_CODE_ID
           , POS.ACS_FINANCIAL_ACCOUNT_ID
           , POS.ACS_DIVISION_ACCOUNT_ID
           , POS.POS_NUMBER
           , POS.POS_REFERENCE
           , POS.POS_SHORT_DESCRIPTION
           , POS.POS_LONG_DESCRIPTION
           , POS.POS_FREE_DESCRIPTION
           , POS.POS_BODY_TEXT
           , POS.POS_GENERATE_MOVEMENT
           , POS.POS_STOCK_OUTAGE
           , POS.POS_DISCOUNT_AMOUNT
           , POS.POS_CHARGE_AMOUNT
           , POS.POS_VAT_AMOUNT
           , POS.POS_VAT_BASE_AMOUNT
           , POS.POS_GROSS_UNIT_VALUE
           , POS.POS_NET_UNIT_VALUE
           , POS.POS_NET_UNIT_VALUE_INCL
           , POS.POS_REF_UNIT_VALUE
           , POS.POS_GROSS_VALUE
           , POS.POS_NET_VALUE_EXCL
           , POS.POS_NET_VALUE_INCL
           , POS.POS_BASIS_QUANTITY
           , POS.POS_INTERMEDIATE_QUANTITY
           , POS.POS_FINAL_QUANTITY
           , POS.POS_BALANCE_QUANTITY
           , POS.POS_RATE_FACTOR
           , POS.POS_NET_WEIGHT
           , POS.POS_GROSS_WEIGHT
           , POS.DIC_UNIT_OF_MEASURE_ID
           , POS.POS_CONVERT_FACTOR
           , POS.A_DATECRE
           , POS.A_DATEMOD
           , POS.A_IDCRE
           , POS.A_IDMOD
           , POS.A_RECLEVEL
           , POS.A_RECSTATUS
           , POS.A_CONFIRM
           , POS.POS_NOM_TEXT
           , POS.POS_UNIT_COST_PRICE
           , POS.POS_EAN_CODE
           , POS.POS_EAN_UCC14_CODE
           , POS.POS_HIBC_PRIMARY_CODE
           , POS.PC_APPLTXT_ID
           , POS.ACS_CPN_ACCOUNT_ID
           , POS.ACS_PF_ACCOUNT_ID
           , POS.ACS_PJ_ACCOUNT_ID
           , POS.ACS_CDA_ACCOUNT_ID
           , POS.DIC_POS_FREE_TABLE_1_ID
           , POS.DIC_POS_FREE_TABLE_2_ID
           , POS.DIC_POS_FREE_TABLE_3_ID
           , POS.POS_DECIMAL_1
           , POS.POS_DECIMAL_2
           , POS.POS_DECIMAL_3
           , POS.POS_TEXT_1
           , POS.POS_TEXT_2
           , POS.POS_TEXT_3
           , POS.POS_DATE_1
           , POS.POS_DATE_2
           , POS.POS_DATE_3
           , POS.POS_DISCOUNT_UNIT_VALUE
           , POS.POS_DISCOUNT_RATE
           , POS.PAC_REPRESENTATIVE_ID
           , POS.DOC_EXTRACT_COMMISSION_ID
           , POS.POS_VALUE_QUANTITY
           , POS.POS_INCLUDE_TAX_TARIFF
           , POS.POS_GROSS_UNIT_VALUE_INCL
           , POS.POS_GROSS_VALUE_INCL
           , POS.POS_BALANCE_QTY_VALUE
           , POS.CML_POSITION_ID
           , POS.DOC_DOC_POSITION_ID
           , POS.POS_UTIL_COEFF
           , POS.POS_GROSS_UNIT_VALUE2
           , POS.PAC_THIRD_ID
           , POS.DOC_GAUGE_ID
           , POS.DIC_DIC_UNIT_OF_MEASURE_ID
           , POS.POS_CONVERT_FACTOR2
           , POS.POS_VAT_AMOUNT_E
           , POS.POS_NET_VALUE_EXCL_B
           , POS.POS_NET_VALUE_EXCL_E
           , POS.POS_NET_VALUE_INCL_B
           , POS.POS_NET_VALUE_INCL_E
           , POS.POS_MODIFY_RATE
           , POS.POS_GROSS_VALUE_B
           , POS.POS_GROSS_VALUE_E
           , POS.POS_GROSS_VALUE_INCL_B
           , POS.POS_GROSS_VALUE_INCL_E
           , POS.POS_VAT_AMOUNT_V
           , POS.POS_GROSS_VALUE_V
           , POS.POS_GROSS_VALUE_INCL_V
           , POS.POS_NET_VALUE_EXCL_V
           , POS.POS_NET_VALUE_INCL_V
        from DOC_POSITION POS
       where POS.DOC_POSITION_ID = aPositionID;
  end InsertPackTmpPos;

  /**
  * procedure InsertPackTmpPosByDoc
  * Description
  *   Insertion dans la table DOC_PACKING_TMP_POSITION les positions du document
  *     passée en param
  */
  procedure InsertPackTmpPosByDoc(aPackListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type, aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    vCfgPackPos varchar2(30);
  begin
    -- Config qui indique le type de position à traiter pour les colis
    vCfgPackPos  := PCS.PC_CONFIG.GetConfig('DOC_PACKING_POSITIONS');

    if vCfgPackPos = '' then
      vCfgPackPos  := ',1,7,8,9,10,';
    end if;

    -- Balayer les positions du document passé en param
    for tplPos in (select   DOC_POSITION_ID
                       from DOC_POSITION
                      where DOC_DOCUMENT_ID = aDocumentID
                        and instr(vCfgPackPos, ',' || C_GAUGE_TYPE_POS || ',') > 0
                   order by POS_NUMBER) loop
      InsertPackTmpPos(aPackListID => aPackListID, aPositionID => tplPos.DOC_POSITION_ID);
    end loop;
  end InsertPackTmpPosByDoc;

  /**
  * procedure InsertPackTmpPosByParcel
  * Description
  *   Insertion dans la table DOC_PACKING_TMP_POSITION les positions des documents
  *     qui sont dans la table des positions de colis
  */
  procedure InsertPackTmpPosByParcel(aPackListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type)
  is
  begin
    -- Balayer la liste des documents qui sont dans la table des positions de colis
    for tplDoc in (select   DOC_DOCUMENT_ID
                       from DOC_PACKING_PARCEL_POS
                      where DOC_PACKING_LIST_ID = aPackListID
                   group by DOC_DOCUMENT_ID) loop
      InsertPackTmpPosByDoc(aPackListID => aPackListID, aDocumentID => tplDoc.DOC_DOCUMENT_ID);
    end loop;
  end InsertPackTmpPosByParcel;
end DOC_PACKING;
