--------------------------------------------------------
--  DDL for Package Body DOC_LIB_POSITION_DETAIL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_POSITION_DETAIL" 
is
  /**
  * Description
  *   Calcul et retourne les informations de solde du parent et en particulier la quantité soldée en unité de stockage en fonction du
  *   facteur de conversion de la position.
  */
  procedure GetRejectInfo(
    iPositionDetailID         in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , ioBalanceQuantityParentSU in out DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY_PARENT%type
  , ioSTPtReject              in out DOC_POSITION_DETAIL.PDE_ST_PT_REJECT%type
  , ioSTCptReject             in out DOC_POSITION_DETAIL.PDE_ST_CPT_REJECT%type
  , ioUpdateOperation         in out STM_MOVEMENT_KIND.MOK_UPDATE_OP%type
  , ioConvertFactor           in out DOC_POSITION.POS_CONVERT_FACTOR%type
  , ioGooNumberOfDecimal      in out GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  )
  is
  begin
    -- recherche de la quantité en unité de stockage après prise en compte du facteur de conversion et
    -- du nombre de décimal du bien et également les informatons liées au rebut.
    begin
      select ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY_PARENT * nvl(POS.POS_CONVERT_FACTOR, 1), 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 1)
           , PDE.PDE_ST_PT_REJECT
           , PDE.PDE_ST_CPT_REJECT
           , (select nvl(max(MOK.MOK_UPDATE_OP), 0)
                from STM_MOVEMENT_KIND MOK
               where MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID)
           , nvl(POS.POS_CONVERT_FACTOR, 1)
           , GOO.GOO_NUMBER_OF_DECIMAL
        into ioBalanceQuantityParentSU
           , ioSTPtReject
           , ioSTCptReject
           , ioUpdateOperation
           , ioConvertFactor
           , ioGooNumberOfDecimal
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , GCO_GOOD GOO
       where PDE.DOC_POSITION_DETAIL_ID = iPositionDetailID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID;
    exception
      when no_data_found then
        ioBalanceQuantityParentSU  := 0;
        ioSTPtReject               := 0;
        ioSTPtReject               := 0;
        ioUpdateOperation          := 0;
        ioConvertFactor            := 1;
        ioGooNumberOfDecimal       := 0;
    end;
  end GetRejectInfo;

  /**
  * Description
  *   Calcul et retourne les informations de solde du parent et en particulier la quantité soldée en unité de stockage en fonction du
  *   facteur de conversion de la position.
  *
  *   Cette fonction peut s'utiliser à l'intérieur d'un trigger de création ou de mise à jour de la position ou
  *   du détail de position. Cela grace à l'utilisation du pragma autonomous_transaction. Mais attention, il
  *   faut être sur que la session dans laquel est déclenché le trigger n'effectue pas de mise à jour sur les
  *   enregistrements recherchés par la fonction.
  */
  procedure GetRejectInfoAT(
    iPositionDetailID         in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , ioBalanceQuantityParentSU in out DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY_PARENT%type
  , ioSTPtReject              in out DOC_POSITION_DETAIL.PDE_ST_PT_REJECT%type
  , ioSTCptReject             in out DOC_POSITION_DETAIL.PDE_ST_CPT_REJECT%type
  , ioUpdateOperation         in out STM_MOVEMENT_KIND.MOK_UPDATE_OP%type
  , ioConvertFactor           in out DOC_POSITION.POS_CONVERT_FACTOR%type
  , ioGooNumberOfDecimal      in out GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  )
  is
    pragma autonomous_transaction;
  begin
    GetRejectInfo(iPositionDetailID           => iPositionDetailID
                , ioBalanceQuantityParentSU   => ioBalanceQuantityParentSU
                , ioSTPtReject                => ioSTPtReject
                , ioSTCptReject               => ioSTCptReject
                , ioUpdateOperation           => ioUpdateOperation
                , ioConvertFactor             => ioConvertFactor
                , ioGooNumberOfDecimal        => ioGooNumberOfDecimal
                 );
  end GetRejectInfoAT;

  /**
  * function GetControlPicDetails
  * Description
  *   Renvoi la liste des détails de position dont la qté est supérieure au solde prévu par le PIC
  */
  function GetControlPicDetails(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return ID_TABLE_TYPE
  is
    lDetailList ID_TABLE_TYPE := ID_TABLE_TYPE();
  begin
    -- Liste des gabarits source en décharge du gabarit courant
    for ltplDetail in (select   PDE.DOC_POSITION_DETAIL_ID
                           from DOC_POSITION_DETAIL PDE
                              , FAL_PIC_LINE PIL
                              , GCO_PRODUCT PDT
                              , PAC_CUSTOM_PARTNER CUS
                              , DOC_POSITION POS
                          where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                            and POS.DOC_POSITION_ID = iPositionID
                            and CUS.PAC_CUSTOM_PARTNER_ID = PDE.PAC_THIRD_ID
                            and PIL.PIL_PREV_QTY - PIL.PIL_REAL_QTY - PIL.PIL_ORDER_QTY < 0
                            and PDT.PDT_PIC = 1
                            and PDT.GCO_GOOD_ID = PDE.GCO_GOOD_ID
                            and PDT.GCO_GOOD_ID = PIL.GCO_GOOD_ID
                            and PIL.PIL_ACTIF = 1
                            and (   PIL.PIL_GROUP_OR_THIRD = to_char(PDE.PAC_THIRD_ID)
                                 or PIL.PIL_GROUP_OR_THIRD = CUS.DIC_PIC_GROUP_ID
                                 or PIL.PIL_GROUP_OR_THIRD is null
                                )
                            and (   PIL.PAC_REPRESENTATIVE_ID = POS.PAC_REPRESENTATIVE_ID
                                 or PIL.PAC_REPRESENTATIVE_ID is null)
                            and (    (     (FAL_I_LIB_CONSTANT.gcCfgPicWeekMonth = 2)
                                      and (DOC_DELAY_FUNCTIONS.DateToWeek(PIl.PIL_DATE) = DOC_DELAY_FUNCTIONS.DateToWeek(PDE.PDE_BASIS_DELAY) )
                                     )
                                 or (     (FAL_I_LIB_CONSTANT.gcCfgPicWeekMonth = 1)
                                     and (to_char(PIL.PIL_DATE, 'MM.YYYY') = to_char(PDE.PDE_BASIS_DELAY, 'MM.YYYY') )
                                    )
                                )
                       order by PDE.PDE_BASIS_DELAY
                              , PDE.DOC_POSITION_DETAIL_ID) loop
      lDetailList.extend;
      lDetailList(lDetailList.last)  := ltplDetail.DOC_POSITION_DETAIL_ID;
    end loop;

    return lDetailList;
  end GetControlPicDetails;
end DOC_LIB_POSITION_DETAIL;
