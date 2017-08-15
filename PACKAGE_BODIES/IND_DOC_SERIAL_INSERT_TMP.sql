--------------------------------------------------------
--  DDL for Package Body IND_DOC_SERIAL_INSERT_TMP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_DOC_SERIAL_INSERT_TMP" 
is

  procedure InsertSerialPos(aReference in varchar2, aDocumentID in number)
  is
    vGaugeID        number;
    vAdminDomain    varchar2(10);
    vMvtSort        varchar2(10);
    vSearchCSAGapID number;
    vGapID          number;
  begin
    -- Effacer les données de la table temporaire
    DOC_SERIAL_POS_INSERT_TMP.DeleteAllTmpTable(userenv('SESSIONID') );

    -- Ne lancer que s'il y a une référence dans le champs de la recherche
    -- Evite dans tous les cas un fullscan
    --if ltrim(rtrim(aReference) ) is not null then
      -- Recherche l'ID du gabarit et le domaine du document et genre de mvt
      --  pour l'utiliser lors de la recherche du gabarit position
      select GAU.DOC_GAUGE_ID
           , GAU.C_ADMIN_DOMAIN
           , nvl(MOK.C_MOVEMENT_SORT, 'NULL')
        into vGaugeID
           , vAdminDomain
           , vMvtSort
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_POSITION GAP
           , STM_MOVEMENT_KIND MOK
       where DMT.DOC_DOCUMENT_ID = aDocumentID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
         and GAP.C_GAUGE_TYPE_POS = '1'
         and GAP.GAP_DEFAULT = 1
         and GAP.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+);

      -- Faire la recherche de l'ID du gabarit position au niveau des données compl de vente
      -- Si domaine = 'Vente' et Genre de Mvt <> 'Sortie'
      if     (vAdminDomain = '2')
         and (vMvtSort <> 'SOR') then
        vSearchCSAGapID  := 1;
      else
        vSearchCSAGapID  := 0;
        vGapID           := DOC_SERIAL_POS_INSERT_TMP.GetDefaultGapID(vGaugeID);
      end if;

      -- Insertion dans la table temporaire
      insert into DOC_TMP_POSITION_DETAIL
                  (DOC_POSITION_DETAIL_ID
                 , DOC_POSITION_ID
                 , DTP_SESSION_ID
                 , DOC_DOCUMENT_ID
                 , CRG_SELECT
                 , PDE_BASIS_QUANTITY
                 , GCO_GOOD_ID
                 , PPS_NOMENCLATURE_ID
                 , DOC_GAUGE_POSITION_ID
                 , CSA_GAP_TYPE_MANDATORY
                 , STM_LOCATION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
             , INIT_ID_SEQ.currval DOC_POSITION_ID
             , SQL_CMD.*
          from (select   userenv('SESSIONID') DTP_SESSION_ID
                       , DMT.DOC_DOCUMENT_ID DOC_DOCUMENT_ID
                       , 0 CRG_SELECT
                       , 1 PDE_BASIS_QUANTITY
                       , GOO.GCO_GOOD_ID GCO_GOOD_ID
                       , NOM.PPS_NOMENCLATURE_ID PPS_NOMENCLATURE_ID
                       , decode(vSearchCSAGapID
                              , 0, vGapID
                              , DOC_SERIAL_POS_INSERT_TMP.GetComplDataSaleGapID(GOO.GCO_GOOD_ID
                                                                              , vGaugeID
                                                                              , DMT.PAC_THIRD_CDA_ID
                                                                               )
                               ) DOC_GAUGE_POSITION_ID
                       , decode(vSearchCSAGapID
                              , 0, null
                              , DOC_SERIAL_POS_INSERT_TMP.GetCSAGaugeMandatoryType(GOO.GCO_GOOD_ID
                                                                                 , DMT.PAC_THIRD_CDA_ID)
                               ) CSA_GAP_TYPE_MANDATORY
                       , PDT.STM_LOCATION_ID STM_LOCATION_ID
                       , sysdate A_DATECRE
                       , PCS.PC_INIT_SESSION.GetUserIni A_IDCRE
                    from GCO_GOOD GOO
                       , GCO_PRODUCT PDT
                       , DOC_DOCUMENT DMT
                       , PPS_NOMENCLATURE NOM
                   where GOO.GOO_MAJOR_REFERENCE like LIKE_PARAM(aReference)
                     and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
                     and DMT.DOC_DOCUMENT_ID = aDocumentID
                     and GOO.GCO_GOOD_ID = NOM.GCO_GOOD_ID(+)
                     and NOM.NOM_DEFAULT(+) = 1
                     and NOM.C_TYPE_NOM(+) = 2
                order by GOO.GOO_MAJOR_REFERENCE) SQL_CMD;
    --end if;
  end InsertSerialPos;

end ind_doc_serial_insert_tmp;
