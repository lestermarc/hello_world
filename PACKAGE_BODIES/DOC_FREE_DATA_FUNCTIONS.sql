--------------------------------------------------------
--  DDL for Package Body DOC_FREE_DATA_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_FREE_DATA_FUNCTIONS" 
is
  /**
  * Description
  *   Création des données libres document
  */
  procedure CreateFreeData(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    intInitDocFreeData integer;
  begin
    select nvl(max(GAS.GAS_INIT_FREE_DATA), 0)
      into intInitDocFreeData
      from DOC_GAUGE_STRUCTURED GAS
         , DOC_DOCUMENT DOC
     where GAS.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
       and DOC.DOC_DOCUMENT_ID = aDocumentID;

    -- Gabarit indique qu'il faut crééer les données libres
    if intInitDocFreeData = 1 then
      insert into DOC_FREE_DATA
                  (DOC_FREE_DATA_ID
                 , DOC_DOCUMENT_ID
                 , DIC_DOC_FREE_TABLE_1_ID
                 , DIC_DOC_FREE_TABLE_2_ID
                 , DIC_DOC_FREE_TABLE_3_ID
                 , DIC_DOC_FREE_TABLE_4_ID
                 , DIC_DOC_FREE_TABLE_5_ID
                 , FRD_ALPHA_LONG_1
                 , FRD_ALPHA_LONG_2
                 , FRD_ALPHA_LONG_3
                 , FRD_ALPHA_LONG_4
                 , FRD_ALPHA_LONG_5
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- DOC_FREE_DATA_ID
             , aDocumentID   -- DOC_DOCUMENT_ID
             , PER.DIC_FREE_CODE1_ID   -- DIC_DOC_FREE_TABLE_1_ID
             , PER.DIC_FREE_CODE2_ID   -- DIC_DOC_FREE_TABLE_2_ID
             , PER.DIC_FREE_CODE3_ID   -- DIC_DOC_FREE_TABLE_3_ID
             , PER.DIC_FREE_CODE4_ID   -- DIC_DOC_FREE_TABLE_4_ID
             , PER.DIC_FREE_CODE5_ID   -- DIC_DOC_FREE_TABLE_5_ID
             , decode(GAU.C_ADMIN_DOMAIN
                    , '1', SUP.CRE_FREE_ZONE1
                    , '2', CUS.CUS_FREE_ZONE1
                    , '5', SUP.CRE_FREE_ZONE1
                    , nvl(CUS.CUS_FREE_ZONE1, SUP.CRE_FREE_ZONE1)
                     ) ALPHA_LONG_1   -- FRD_ALPHA_LONG_1
             , decode(GAU.C_ADMIN_DOMAIN
                    , '1', SUP.CRE_FREE_ZONE2
                    , '2', CUS.CUS_FREE_ZONE2
                    , '5', SUP.CRE_FREE_ZONE2
                    , nvl(CUS.CUS_FREE_ZONE2, SUP.CRE_FREE_ZONE2)
                     ) ALPHA_LONG_2   -- FRD_ALPHA_LONG_2
             , decode(GAU.C_ADMIN_DOMAIN
                    , '1', SUP.CRE_FREE_ZONE3
                    , '2', CUS.CUS_FREE_ZONE3
                    , '5', SUP.CRE_FREE_ZONE3
                    , nvl(CUS.CUS_FREE_ZONE3, SUP.CRE_FREE_ZONE3)
                     ) ALPHA_LONG_3   -- FRD_ALPHA_LONG_3
             , decode(GAU.C_ADMIN_DOMAIN
                    , '1', SUP.CRE_FREE_ZONE4
                    , '2', CUS.CUS_FREE_ZONE4
                    , '5', SUP.CRE_FREE_ZONE4
                    , nvl(CUS.CUS_FREE_ZONE4, SUP.CRE_FREE_ZONE4)
                     ) ALPHA_LONG_4   -- FRD_ALPHA_LONG_4
             , decode(GAU.C_ADMIN_DOMAIN
                    , '1', SUP.CRE_FREE_ZONE5
                    , '2', CUS.CUS_FREE_ZONE5
                    , '5', SUP.CRE_FREE_ZONE5
                    , nvl(CUS.CUS_FREE_ZONE5, SUP.CRE_FREE_ZONE5)
                     ) ALPHA_LONG_5   -- FRD_ALPHA_LONG_5
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from DOC_DOCUMENT DOC
             , DOC_GAUGE GAU
             , PAC_PERSON PER
             , PAC_CUSTOM_PARTNER CUS
             , PAC_SUPPLIER_PARTNER SUP
         where DOC.DOC_DOCUMENT_ID = aDocumentID
           and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and DOC.PAC_THIRD_ID = PER.PAC_PERSON_ID
           and PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
           and PER.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID(+);
    end if;
  end CreateFreeData;

  /**
  * Description
  *   Copie des données libres d'un document vers un autre
  */
  procedure DuplicateFreeData(aSrcDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aTgtDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    intInitSource DOC_GAUGE_STRUCTURED.GAS_INIT_FREE_DATA%type;
    intInitTarget DOC_GAUGE_STRUCTURED.GAS_INIT_FREE_DATA%type;
  begin
    -- Recherche des flags des gabraits indiquant si les doc gérent les init des données libres
    begin
      select GAS_SOURCE.GAS_INIT_FREE_DATA INIT_SOURCE
           , GAS_TARGET.GAS_INIT_FREE_DATA INIT_TARGET
        into intInitSource
           , intInitTarget
        from DOC_GAUGE_STRUCTURED GAS_SOURCE
           , DOC_GAUGE_STRUCTURED GAS_TARGET
           , DOC_DOCUMENT DOC_SOURCE
           , DOC_DOCUMENT DOC_TARGET
       where GAS_SOURCE.DOC_GAUGE_ID = DOC_SOURCE.DOC_GAUGE_ID
         and GAS_TARGET.DOC_GAUGE_ID = DOC_TARGET.DOC_GAUGE_ID
         and DOC_SOURCE.DOC_DOCUMENT_ID = aSrcDocumentID
         and DOC_TARGET.DOC_DOCUMENT_ID = aTgtDocumentID;
    exception
      when no_data_found then
        intInitSource  := 0;
        intInitTarget  := 0;
    end;

    -- Si le gabarit du document cible "Initialisation des données libres"
    if intInitTarget = 1 then
      -- Si le gabarit du document source "Initialisation des données libres"
      if intInitSource = 1 then
        -- Copie des données libres du document source sur le document cible
        insert into DOC_FREE_DATA
                    (DOC_FREE_DATA_ID
                   , DOC_DOCUMENT_ID
                   , DIC_DOC_FREE_TABLE_1_ID
                   , DIC_DOC_FREE_TABLE_2_ID
                   , DIC_DOC_FREE_TABLE_3_ID
                   , DIC_DOC_FREE_TABLE_4_ID
                   , DIC_DOC_FREE_TABLE_5_ID
                   , FRD_ALPHA_SHORT_1
                   , FRD_ALPHA_SHORT_2
                   , FRD_ALPHA_SHORT_3
                   , FRD_ALPHA_SHORT_4
                   , FRD_ALPHA_SHORT_5
                   , FRD_ALPHA_LONG_1
                   , FRD_ALPHA_LONG_2
                   , FRD_ALPHA_LONG_3
                   , FRD_ALPHA_LONG_4
                   , FRD_ALPHA_LONG_5
                   , FRD_INTEGER_1
                   , FRD_INTEGER_2
                   , FRD_INTEGER_3
                   , FRD_INTEGER_4
                   , FRD_INTEGER_5
                   , FRD_DECIMAL_1
                   , FRD_DECIMAL_2
                   , FRD_DECIMAL_3
                   , FRD_DECIMAL_4
                   , FRD_DECIMAL_5
                   , FRD_BOOLEAN_1
                   , FRD_BOOLEAN_2
                   , FRD_BOOLEAN_3
                   , FRD_BOOLEAN_4
                   , FRD_BOOLEAN_5
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval   -- DOC_FREE_DATA_ID
               , aTgtDocumentID   -- DOC_DOCUMENT_ID
               , DIC_DOC_FREE_TABLE_1_ID
               , DIC_DOC_FREE_TABLE_2_ID
               , DIC_DOC_FREE_TABLE_3_ID
               , DIC_DOC_FREE_TABLE_4_ID
               , DIC_DOC_FREE_TABLE_5_ID
               , FRD_ALPHA_SHORT_1
               , FRD_ALPHA_SHORT_2
               , FRD_ALPHA_SHORT_3
               , FRD_ALPHA_SHORT_4
               , FRD_ALPHA_SHORT_5
               , FRD_ALPHA_LONG_1
               , FRD_ALPHA_LONG_2
               , FRD_ALPHA_LONG_3
               , FRD_ALPHA_LONG_4
               , FRD_ALPHA_LONG_5
               , FRD_INTEGER_1
               , FRD_INTEGER_2
               , FRD_INTEGER_3
               , FRD_INTEGER_4
               , FRD_INTEGER_5
               , FRD_DECIMAL_1
               , FRD_DECIMAL_2
               , FRD_DECIMAL_3
               , FRD_DECIMAL_4
               , FRD_DECIMAL_5
               , FRD_BOOLEAN_1
               , FRD_BOOLEAN_2
               , FRD_BOOLEAN_3
               , FRD_BOOLEAN_4
               , FRD_BOOLEAN_5
               , sysdate   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
            from DOC_FREE_DATA
           where DOC_DOCUMENT_ID = aSrcDocumentID;
      else
        -- Création des données libres pour le document cible
        CreateFreeData(aTgtDocumentID);
      end if;
    end if;
  end DuplicateFreeData;

  /**
  * procedure CreateInterfaceFreeData
  * Description
  *   Générateur de documents, création des données libres document depuis les données de DOC_INTERFACE_FREE_DATA
  * @created ngv 21.05.2014
  * @lastUpdate
  * @public
  * @param iDocumentID : id du document
  * @param iInterfaceID : id du interface (DOC_INTERFACE)
  */
  procedure CreateInterfaceFreeData(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
  is
    cursor lcrDocIntFreeData
    is
      select *
        from DOC_INTERFACE_FREE_DATA
       where DOC_INTERFACE_ID = iInterfaceID;

    ltplDocIntFreeData lcrDocIntFreeData%rowtype;
    ltFreeData         FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    open lcrDocIntFreeData;

    fetch lcrDocIntFreeData
     into ltplDocIntFreeData;

    if lcrDocIntFreeData%found then
      FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocFreeData, ltFreeData);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'DOC_DOCUMENT_ID', iDocumentID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'DIC_DOC_FREE_TABLE_1_ID', ltplDocIntFreeData.DIC_DOC_FREE_TABLE_1_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'DIC_DOC_FREE_TABLE_2_ID', ltplDocIntFreeData.DIC_DOC_FREE_TABLE_2_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'DIC_DOC_FREE_TABLE_3_ID', ltplDocIntFreeData.DIC_DOC_FREE_TABLE_3_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'DIC_DOC_FREE_TABLE_4_ID', ltplDocIntFreeData.DIC_DOC_FREE_TABLE_4_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'DIC_DOC_FREE_TABLE_5_ID', ltplDocIntFreeData.DIC_DOC_FREE_TABLE_5_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_ALPHA_SHORT_1', ltplDocIntFreeData.FRD_ALPHA_SHORT_1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_ALPHA_SHORT_2', ltplDocIntFreeData.FRD_ALPHA_SHORT_2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_ALPHA_SHORT_3', ltplDocIntFreeData.FRD_ALPHA_SHORT_3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_ALPHA_SHORT_4', ltplDocIntFreeData.FRD_ALPHA_SHORT_4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_ALPHA_SHORT_5', ltplDocIntFreeData.FRD_ALPHA_SHORT_5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_ALPHA_LONG_1', ltplDocIntFreeData.FRD_ALPHA_LONG_1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_ALPHA_LONG_2', ltplDocIntFreeData.FRD_ALPHA_LONG_2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_ALPHA_LONG_3', ltplDocIntFreeData.FRD_ALPHA_LONG_3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_ALPHA_LONG_4', ltplDocIntFreeData.FRD_ALPHA_LONG_4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_ALPHA_LONG_5', ltplDocIntFreeData.FRD_ALPHA_LONG_5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_INTEGER_1', ltplDocIntFreeData.FRD_INTEGER_1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_INTEGER_2', ltplDocIntFreeData.FRD_INTEGER_2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_INTEGER_3', ltplDocIntFreeData.FRD_INTEGER_3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_INTEGER_4', ltplDocIntFreeData.FRD_INTEGER_4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_INTEGER_5', ltplDocIntFreeData.FRD_INTEGER_5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_DECIMAL_1', ltplDocIntFreeData.FRD_DECIMAL_1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_DECIMAL_2', ltplDocIntFreeData.FRD_DECIMAL_2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_DECIMAL_3', ltplDocIntFreeData.FRD_DECIMAL_3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_DECIMAL_4', ltplDocIntFreeData.FRD_DECIMAL_4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_DECIMAL_5', ltplDocIntFreeData.FRD_DECIMAL_5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_BOOLEAN_1', ltplDocIntFreeData.FRD_BOOLEAN_1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_BOOLEAN_2', ltplDocIntFreeData.FRD_BOOLEAN_2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_BOOLEAN_3', ltplDocIntFreeData.FRD_BOOLEAN_3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_BOOLEAN_4', ltplDocIntFreeData.FRD_BOOLEAN_4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_BOOLEAN_5', ltplDocIntFreeData.FRD_BOOLEAN_5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_DATE_1', ltplDocIntFreeData.FRD_DATE_1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_DATE_2', ltplDocIntFreeData.FRD_DATE_2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_DATE_3', ltplDocIntFreeData.FRD_DATE_3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_DATE_4', ltplDocIntFreeData.FRD_DATE_4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFreeData, 'FRD_DATE_5', ltplDocIntFreeData.FRD_DATE_5);
      FWK_I_MGT_ENTITY.InsertEntity(ltFreeData);
      FWK_I_MGT_ENTITY.Release(ltFreeData);
    end if;

    close lcrDocIntFreeData;
  end CreateInterfaceFreeData;
end DOC_FREE_DATA_FUNCTIONS;
