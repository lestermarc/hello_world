--------------------------------------------------------
--  DDL for Package Body STM_INVENTORY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_INVENTORY" 
is
  -- Reprise du prix d'inventaire sur le fichier externe. 0 = pas de reprise du prix d'inventaire; 1 = reprise du prix d'inventaire
  cfgUseUnitPrice constant varchar2(255) := pcs.pc_config.GetConfig('STM_INV_EXT_USE_UNIT_PRICE');

  /**
  * Curseur (global au package) sur l'ensemble des positions non traitées d'une extraction
  */
  cursor crGetListPosition(pStminventoryListId in stm_inventory_LIST.stm_inventory_LIST_ID%type)
  is
    select rownum rownumber
         , v.*
      from (select   ilp.*
                   , exe.stm_exercise_id
                   , ili.ili_description
                   , inv.inv_description
                from stm_inventory_list_pos ilp
                   , stm_inventory_list ili
                   , stm_inventory_task inv
                   , stm_period per
                   , stm_exercise exe
               where ilp.stm_inventory_list_id = pStminventoryListId
                 and ilp.ilp_is_validated = 0
                 and ilp.stm_period_id = per.stm_period_id
                 and per.stm_exercise_id = exe.stm_exercise_id
                 and ilp.stm_inventory_list_id = ili.stm_inventory_list_id
                 and ili.stm_inventory_task_id = inv.stm_inventory_task_id
            order by ilp.gco_good_id asc) v;

  type stm_inventory_list_pos_type is table of crGetListPosition%rowtype
    index by binary_integer;

  /**
  * Curseur (global au package) sur l'ensemble des lignes d'une importation de données externes
  */
  cursor crinventory_External_Lines_1(pstm_inventory_External_Id stm_inventory_External.stm_inventory_External_id%type)
  is
    select   stm_inventory_external_line_id
           , c_inventory_ext_line_status
           , gco_good_id
           , stm_location_id
           , stm_stock_id
           , iex_major_reference
           , iex_sto_description
           , iex_loc_description
           , iex_characterization_value_1
           , iex_characterization_value_2
           , iex_characterization_value_3
           , iex_characterization_value_4
           , iex_characterization_value_5
           , iex_quantity
           , iex_user_name
           , iex_input_line
           , gco_characterization_id
           , gco_gco_characterization_id
           , gco2_gco_characterization_id
           , gco3_gco_characterization_id
           , gco4_gco_characterization_id
           , stm_inventory_external_id
           , iex_free_date1
           , iex_free_date2
           , iex_free_date3
           , iex_free_date4
           , iex_free_date5
           , iex_free_text1
           , iex_free_text2
           , iex_free_text3
           , iex_free_text4
           , iex_free_text5
           , iex_free_number1
           , iex_free_number2
           , iex_free_number3
           , iex_free_number4
           , iex_free_number5
           , iex_unit_price
        from stm_inventory_external_line
       where stm_inventory_external_id = pstm_inventory_External_Id
         and iex_is_validated = 0
         and C_INVENTORY_EXT_LINE_STATUS <> '009'
    order by gco_good_id asc;

  /**
  * function pCheckCharactFormat
  * Description
  *    Vérifie le format des valeurs des caractérisations des lignes d'inventaire externes.
  * @created age 18.12.2013
  * @lastUpdate
  * @private
  * @param iCharacterizationId1 : id de la caractérisation 1
  * @param iValue1              : valeur de la caractérisation 1
  * @param iCharacterizationId2 : id de la caractérisation 2
  * @param iValue2              : valeur de la caractérisation 2
  * @param iCharacterizationId3 : id de la caractérisation 3
  * @param iValue3              : valeur de la caractérisation 3
  * @param iCharacterizationId4 : id de la caractérisation 4
  * @param iValue4              : valeur de la caractérisation 4
  * @param iCharacterizationId5 : id de la caractérisation 5
  * @param iValue5              : valeur de la caractérisation 5
  * @return true si le format est correcte, sinon False
  */
  function pCheckCharactFormat(
    iCharacterizationID1 in STM_INVENTORY_EXTERNAL_LINE.GCO_CHARACTERIZATION_ID%type
  , iValue1              in STM_INVENTORY_EXTERNAL_LINE.IEX_CHARACTERIZATION_VALUE_1%type
  , iCharacterizationID2 in STM_INVENTORY_EXTERNAL_LINE.GCO_GCO_CHARACTERIZATION_ID%type
  , iValue2              in STM_INVENTORY_EXTERNAL_LINE.IEX_CHARACTERIZATION_VALUE_2%type
  , iCharacterizationID3 in STM_INVENTORY_EXTERNAL_LINE.GCO2_GCO_CHARACTERIZATION_ID%type
  , iValue3              in STM_INVENTORY_EXTERNAL_LINE.IEX_CHARACTERIZATION_VALUE_3%type
  , iCharacterizationID4 in STM_INVENTORY_EXTERNAL_LINE.GCO3_GCO_CHARACTERIZATION_ID%type
  , iValue4              in STM_INVENTORY_EXTERNAL_LINE.IEX_CHARACTERIZATION_VALUE_4%type
  , iCharacterizationID5 in STM_INVENTORY_EXTERNAL_LINE.GCO4_GCO_CHARACTERIZATION_ID%type
  , iValue5              in STM_INVENTORY_EXTERNAL_LINE.IEX_CHARACTERIZATION_VALUE_5%type
  )
    return boolean
  as
  begin
    return     (GCO_I_LIB_CHARACTERIZATION.VerifyCharFormat(iCharacterizationID1, iValue1, 0) = 1)
           and (GCO_I_LIB_CHARACTERIZATION.VerifyCharFormat(iCharacterizationID2, iValue2, 0) = 1)
           and (GCO_I_LIB_CHARACTERIZATION.VerifyCharFormat(iCharacterizationID3, iValue3, 0) = 1)
           and (GCO_I_LIB_CHARACTERIZATION.VerifyCharFormat(iCharacterizationID4, iValue4, 0) = 1)
           and (GCO_I_LIB_CHARACTERIZATION.VerifyCharFormat(iCharacterizationID5, iValue5, 0) = 1);
  end pCheckCharactFormat;

  /**
  * procedure update_status_after_delete
  *
  * Description :
  *   mise à jour des status (biens et positions de stock) après effacement d'une position
  *   d'inventaire
  *
  * @created    Sener Kalayci
  * @version   1998
  * @param
  */
  procedure update_status_after_delete(
    good_id     in number
  , stock_id    in number
  , location_id in number
  , charac_id1  in number
  , charac_id2  in number
  , charac_id3  in number
  , charac_id4  in number
  , charac_id5  in number
  , charac1     in varchar2
  , charac2     in varchar2
  , charac3     in varchar2
  , charac4     in varchar2
  , charac5     in varchar2
  )
  is
    intTmpCounter number;
  begin
    -- mise a jour du status de la position de stock
    update STM_STOCK_POSITION
       set C_POSITION_STATUS = '01'
         , A_DATEMOD = sysdate
         , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
     where GCO_GOOD_ID = good_id
       and STM_STOCK_ID = stock_id
       and STM_LOCATION_ID = location_id
       and (     (   gco_characterization_id = charac_id1
                  or (    charac_id1 is null
                      and gco_characterization_id is null) )
            and (   gco_gco_characterization_id = charac_id2
                 or (    charac_id2 is null
                     and gco_gco_characterization_id is null) )
            and (   gco2_gco_characterization_id = charac_id3
                 or (    charac_id3 is null
                     and gco2_gco_characterization_id is null) )
            and (   gco3_gco_characterization_id = charac_id4
                 or (    charac_id4 is null
                     and gco3_gco_characterization_id is null) )
            and (   gco4_gco_characterization_id = charac_id5
                 or (    charac_id5 is null
                     and gco4_gco_characterization_id is null) )
            and (   spo_characterization_value_1 = charac1
                 or (    charac1 is null
                     and spo_characterization_value_1 is null) )
            and (   spo_characterization_value_2 = charac2
                 or (    charac2 is null
                     and spo_characterization_value_2 is null) )
            and (   spo_characterization_value_3 = charac3
                 or (    charac3 is null
                     and spo_characterization_value_3 is null) )
            and (   spo_characterization_value_4 = charac4
                 or (    charac4 is null
                     and spo_characterization_value_4 is null) )
            and (   spo_characterization_value_5 = charac5
                 or (    charac5 is null
                     and spo_characterization_value_5 is null) )
           );

    -- le bien retrouve son statut d'avant inventaire et l'on vide le champ de
    -- de réception du statut
    update    GCO_GOOD_CALC_DATA
          set GOO_INV_POS_COUNTER = GOO_INV_POS_COUNTER - 1
            , A_DATEMOD = sysdate
            , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
        where GCO_GOOD_ID = good_id
    returning GOO_INV_POS_COUNTER
         into intTmpCounter;

    -- si on a plus de positions d'inventaire
    if intTmpCounter = 0 then
      update GCO_GOOD_CALC_DATA
         set GOO_IN_INVENTORY = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
       where GCO_GOOD_ID = good_id;
    end if;
  end update_status_after_delete;

  /**
  * procedure Update_status_after_treatement
  *
  * Description
  *    Mise à jour du statut de la position de stock après génération du mouvement de stock
  *    correctif
  * @created Sener Kalayci / Pierre-Yves Voirol
  * @created 04.10.2001
  *
  * @param aGoodId        bien
  * @param aStock_id      stock
  * @param aLocation_id   emplacement
  * @param aCharac_id1..5 caractérisation 1..5
  * @param aCharac1..5    valeur de caractérisation 1..5
  * @param aUpdLastInventDt whether to update STM_STOCK_POSITION.SPO_LAST_INVENTORY_DATE or not
  */
  procedure update_status_after_treatement(
    aGood_id         in number
  , aStock_id        in number
  , aLocation_id     in number
  , aCharac_id1      in number
  , aCharac_id2      in number
  , aCharac_id3      in number
  , aCharac_id4      in number
  , aCharac_id5      in number
  , aCharac1         in varchar2
  , aCharac2         in varchar2
  , aCharac3         in varchar2
  , aCharac4         in varchar2
  , aCharac5         in varchar2
  , aUpdLastInventDt in date default null
  )
  is
    intTmpCounter number;
  begin
    -- mise a jour du status de la position de stock

    update stm_stock_position
       set c_position_status = '01'
         , A_DATEMOD = sysdate
         , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
         , SPO_LAST_INVENTORY_DATE = aUpdLastInventDt
     where gco_good_id = aGood_id
       and stm_stock_id = aStock_id
       and stm_location_id = aLocation_id
       and (     (   gco_characterization_id = aCharac_id1
                  or (    aCharac_id1 is null
                      and gco_characterization_id is null) )
            and (   gco_gco_characterization_id = aCharac_id2
                 or (    aCharac_id2 is null
                     and gco_gco_characterization_id is null) )
            and (   gco2_gco_characterization_id = aCharac_id3
                 or (    aCharac_id3 is null
                     and gco2_gco_characterization_id is null) )
            and (   gco3_gco_characterization_id = aCharac_id4
                 or (    aCharac_id4 is null
                     and gco3_gco_characterization_id is null) )
            and (   gco4_gco_characterization_id = aCharac_id5
                 or (    aCharac_id5 is null
                     and gco4_gco_characterization_id is null) )
            and (   spo_characterization_value_1 = aCharac1
                 or (    aCharac1 is null
                     and spo_characterization_value_1 is null) )
            and (   spo_characterization_value_2 = aCharac2
                 or (    aCharac2 is null
                     and spo_characterization_value_2 is null) )
            and (   spo_characterization_value_3 = aCharac3
                 or (    aCharac3 is null
                     and spo_characterization_value_3 is null) )
            and (   spo_characterization_value_4 = aCharac4
                 or (    aCharac4 is null
                     and spo_characterization_value_4 is null) )
            and (   spo_characterization_value_5 = aCharac5
                 or (    aCharac5 is null
                     and spo_characterization_value_5 is null) )
           );

    -- le bien retrouve son statut d'avant inventaire et l'on vide le champ de
    -- de réception du statut
    update    GCO_GOOD_CALC_DATA
          set GOO_INV_POS_COUNTER = GOO_INV_POS_COUNTER - 1
            , A_DATEMOD = sysdate
            , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
        where GCO_GOOD_ID = aGood_id
    returning GOO_INV_POS_COUNTER
         into intTmpCounter;

    -- si on a plus de positions d'inventaire
    if intTmpCounter = 0 then
      update GCO_GOOD_CALC_DATA
         set GOO_IN_INVENTORY = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
       where GCO_GOOD_ID = aGood_id;
    end if;
  end update_status_after_treatement;

  /**
  * procedure insertOnlyPreparedPos
  *
  * Description
  *    insertion dans la liste spécifiée (aListId) de positions d'inventaires
  *    ne provenant pas de positions de stock
  * @created Sener Kalayci / Pierre-Yves Voirol
  * @created 04.10.2001
  * @updated sma 11.09.2013
  * @param aSessionId   id de session permettant de récupérer les lignes préparées
  *                     par l'utilisateur connecté
  * @param aListId      extraction de destination des lignes insérées
  * @param ainvTaskId   inventaire choisi par l'utilisateur
  * @param ainvPeriodId période d'extraction et de traitement de l'inventaire (période active)
  * @param ainvType     type d'inventaire
  */
  procedure insertOnlyPreparedPos(
    aSessionid   stm_inventory_prepare.ipr_session_id%type
  , aListid      stm_inventory_list.stm_inventory_list_id%type
  , ainvtaskid   stm_inventory_list.stm_inventory_task_id%type
  , ainvperiodid stm_inventory_task.stm_period_id%type
  , ainvtype     stm_inventory_task.c_inventory_type%type
  )
  is
    /**
    * Curseur retournant l'ensemble des lignes "préparées" n'ayant pas de lien sur position de stock
    * dont les stocks sont publics, dont les articles sont sans caractérisations ...
    */
    cursor crOnlyPreparedPos(
      cSessionId   stm_inventory_prepare.ipr_session_id%type
    , cListId      stm_inventory_list.stm_inventory_list_id%type
    , cinvTaskId   stm_inventory_list.stm_inventory_task_id%type
    , cinvPeriodId stm_inventory_task.stm_period_id%type
    , cinvType     stm_inventory_task.c_inventory_type%type
    )
    is
      select   cListid stm_inventory_list_id
             , cinvtaskid stm_inventory_task_id
             , ipr.stm_stock_id stm_stock_id
             , ipr.stm_location_id stm_location_id
             , cinvperiodid stm_period_id
             , cinvtype c_inventory_type
             , sysdate a_datecre
             , pcs.PC_I_LIB_SESSION.getuserini a_idcre
             , ipr.gco_good_id gco_good_id
             , ipr.gco_characterization_id gco_characterization_id
             , ipr.gco_gco_characterization_id gco_gco_characterization_id
             , ipr.gco2_gco_characterization_id gco2_gco_characterization_id
             , ipr.gco3_gco_characterization_id gco3_gco_characterization_id
             , ipr.gco4_gco_characterization_id gco4_gco_characterization_id
             , ipr.ipr_characterization_value_1 ipr_characterization_value_1
             , ipr.ipr_characterization_value_2 ipr_characterization_value_2
             , ipr.ipr_characterization_value_3 ipr_characterization_value_3
             , ipr.ipr_characterization_value_4 ipr_characterization_value_4
             , ipr.ipr_characterization_value_5 ipr_characterization_value_5
             , 0 ipr_inventory_quantity
             , 0 ipr_system_quantity
             , 0 ipr_provisory_input
             , 0 ipr_provisory_output
             , 0 ipr_assign_quantity
             , 0 ipr_inventory_value
             , 0 ipr_system_value
             , 0 ipr_inv_alternativ_qty_1
             , 0 ipr_sys_alternativ_qty_1
             , 0 ipr_inv_alternativ_qty_2
             , 0 ipr_sys_alternativ_qty_2
             , 0 ipr_inv_alternativ_qty_3
             , 0 ipr_sys_alternativ_qty_3
             , sysdate ipr_inventory_date
             , (gco_functions.getcostpricewithmanagementmode(ipr.gco_good_id) ) ipr_inventory_unit_price
             , (gco_functions.getcostpricewithmanagementmode(ipr.gco_good_id) ) ipr_system_unit_price
             , decode(ipr.stm_stock_position_id, null, 0, 1) ipr_is_original_pos
             , 0 ipr_is_validated
             , null ipr_retest_date
             , GCO_I_LIB_QUALITY_STATUS.GetReceiptStatus(iGoodId => ipr.gco_good_id) GCO_QUALITY_STATUS_ID
          from stm_inventory_prepare ipr
         where
               --  Positions préparées de la session donnée
               ipr.ipr_session_id = aSessionId
           --  Positions sélectionnées
           and ipr.ipr_selection = 1
           -- et faisant référence à un produit avec gestion de stock
           and exists(select pdt.gco_good_id
                        from gco_product pdt
                       where pdt.gco_good_id = ipr.gco_good_id
                         and pdt.pdt_stock_management > 0)
           -- et dont le couple stock - emplacement est valide
           and exists(select loc.stm_location_id
                        from stm_location loc
                       where loc.stm_location_id = ipr.stm_location_id
                         and loc.stm_stock_id = ipr.stm_stock_id)
           -- et dont le stock est public
           and exists(select sto.stm_stock_id
                        from stm_stock sto
                       where sto.stm_stock_id = ipr.stm_stock_id
                         and sto.c_access_method = 'PUBLIC')
           -- et dont le produit n'a pas de caractérisations
           and not exists(select cha.gco_characterization_id
                            from gco_characterization cha
                           where cha.gco_good_id = ipr.gco_good_id
                             and cha.cha_stock_management = 1)
           --  et ne faisant pas référence à une position de stock déjà existante
           and ipr.stm_stock_position_id is null
           --  et dont les valeurs ne sont pas identiques à une position de stock
           and not exists(
                 select spo.stm_stock_position_id
                   from stm_stock_position spo
                  where spo.gco_good_id = ipr.gco_good_id
                    and spo.stm_stock_id = ipr.stm_stock_id
                    and spo.stm_location_id = ipr.stm_location_id
                    and (    (spo.gco_characterization_id = ipr.gco_characterization_id)
                         or (    spo.gco_characterization_id is null
                             and ipr.gco_characterization_id is null)
                        )
                    and (    (spo.gco_gco_characterization_id = ipr.gco_gco_characterization_id)
                         or (    spo.gco_gco_characterization_id is null
                             and ipr.gco_gco_characterization_id is null)
                        )
                    and (    (spo.gco2_gco_characterization_id = ipr.gco2_gco_characterization_id)
                         or (    spo.gco2_gco_characterization_id is null
                             and ipr.gco2_gco_characterization_id is null)
                        )
                    and (    (spo.gco3_gco_characterization_id = ipr.gco3_gco_characterization_id)
                         or (    spo.gco3_gco_characterization_id is null
                             and ipr.gco3_gco_characterization_id is null)
                        )
                    and (    (spo.gco4_gco_characterization_id = ipr.gco4_gco_characterization_id)
                         or (    spo.gco4_gco_characterization_id is null
                             and ipr.gco4_gco_characterization_id is null)
                        )
                    and (    (spo.spo_characterization_value_1 = ipr.ipr_characterization_value_1)
                         or (    spo.spo_characterization_value_1 is null
                             and ipr.ipr_characterization_value_1 is null)
                        )
                    and (    (spo.spo_characterization_value_2 = ipr.ipr_characterization_value_2)
                         or (    spo.spo_characterization_value_2 is null
                             and ipr.ipr_characterization_value_2 is null)
                        )
                    and (    (spo.spo_characterization_value_3 = ipr.ipr_characterization_value_3)
                         or (    spo.spo_characterization_value_3 is null
                             and ipr.ipr_characterization_value_3 is null)
                        )
                    and (    (spo.spo_characterization_value_4 = ipr.ipr_characterization_value_4)
                         or (    spo.spo_characterization_value_4 is null
                             and ipr.ipr_characterization_value_4 is null)
                        )
                    and (    (spo.spo_characterization_value_5 = ipr.ipr_characterization_value_5)
                         or (    spo.spo_characterization_value_5 is null
                             and ipr.ipr_characterization_value_5 is null)
                        ) )
           --  et dont les valeurs ne sont pas identiques à une position déjà existante de la liste
           and not exists(
                 select ilp.stm_inventory_list_pos_id
                   from stm_inventory_list_pos ilp
                  where ilp.gco_good_id = ipr.gco_good_id
                    and ilp.stm_stock_id = ipr.stm_stock_id
                    and ilp.stm_location_id = ipr.stm_location_id
                    and ilp.ilp_is_validated = 0
                    and (    (ilp.gco_characterization_id = ipr.gco_characterization_id)
                         or (    ilp.gco_characterization_id is null
                             and ipr.gco_characterization_id is null)
                        )
                    and (    (ilp.gco_gco_characterization_id = ipr.gco_gco_characterization_id)
                         or (    ilp.gco_gco_characterization_id is null
                             and ipr.gco_gco_characterization_id is null)
                        )
                    and (    (ilp.gco2_gco_characterization_id = ipr.gco2_gco_characterization_id)
                         or (    ilp.gco2_gco_characterization_id is null
                             and ipr.gco2_gco_characterization_id is null)
                        )
                    and (    (ilp.gco3_gco_characterization_id = ipr.gco3_gco_characterization_id)
                         or (    ilp.gco3_gco_characterization_id is null
                             and ipr.gco3_gco_characterization_id is null)
                        )
                    and (    (ilp.gco4_gco_characterization_id = ipr.gco4_gco_characterization_id)
                         or (    ilp.gco4_gco_characterization_id is null
                             and ipr.gco4_gco_characterization_id is null)
                        )
                    and (    (ilp.ilp_characterization_value_1 = ipr.ipr_characterization_value_1)
                         or (    ilp.ilp_characterization_value_1 is null
                             and ipr.ipr_characterization_value_1 is null)
                        )
                    and (    (ilp.ilp_characterization_value_2 = ipr.ipr_characterization_value_2)
                         or (    ilp.ilp_characterization_value_2 is null
                             and ipr.ipr_characterization_value_2 is null)
                        )
                    and (    (ilp.ilp_characterization_value_3 = ipr.ipr_characterization_value_3)
                         or (    ilp.ilp_characterization_value_3 is null
                             and ipr.ipr_characterization_value_3 is null)
                        )
                    and (    (ilp.ilp_characterization_value_4 = ipr.ipr_characterization_value_4)
                         or (    ilp.ilp_characterization_value_4 is null
                             and ipr.ipr_characterization_value_4 is null)
                        )
                    and (    (ilp.ilp_characterization_value_5 = ipr.ipr_characterization_value_5)
                         or (    ilp.ilp_characterization_value_5 is null
                             and ipr.ipr_characterization_value_5 is null)
                        ) )
      order by ipr.gco_good_id asc;

    tplOnlyPreparedPos crOnlyPreparedPos%rowtype;
  begin
    open crOnlyPreparedPos(aSessionId, aListId, ainvTaskId, ainvPeriodId, ainvType);

    fetch crOnlyPreparedPos
     into tplOnlyPreparedPos;

    while crOnlyPreparedPos%found loop
      insert into stm_inventory_list_pos
                  (stm_inventory_list_pos_id   -- positions de l'inventaire
                 , stm_inventory_list_id   -- liste d'inventaire
                 , stm_inventory_task_id   -- inventaire
                 , stm_stock_id   -- id stock logique
                 , stm_location_id   -- id emplacement de stock
                 , stm_period_id   -- id période
                 , c_inventory_type   -- type d'inventaire
                 , a_datecre   -- date de création
                 , a_idcre   -- id de création
                 , gco_good_id   -- id bien
                 , gco_characterization_id   -- id caractérisation
                 , gco_gco_characterization_id   -- gco_id charactérisation
                 , gco2_gco_characterization_id   -- gco2_id charactérisation
                 , gco3_gco_characterization_id   -- gco3_id charactérisation
                 , gco4_gco_characterization_id   -- gco4_id charactérisation
                 , ilp_characterization_value_1   -- valeur de caractérisation 1
                 , ilp_characterization_value_2   -- valeur de caractérisation 2
                 , ilp_characterization_value_3   -- valeur de caractérisation 3
                 , ilp_characterization_value_4   -- valeur de caractérisation 4
                 , ilp_characterization_value_5   -- valeur de caractérisation 5
                 , ilp_inventory_quantity   -- quantité inventoriée
                 , ilp_system_quantity   -- quantité système
                 , ilp_provisory_input   -- quantité entrée provisoire
                 , ilp_provisory_output   -- quantité sortie provisoire
                 , ilp_assign_quantity   -- quantité attribuée sur stock
                 , ilp_inventory_unit_price   -- prix unitaire inventorié
                 , ilp_system_unit_price   -- prix unitaire système
                 , ilp_inventory_value   -- valeur inventoriée
                 , ilp_system_value   -- valeur système
                 , ilp_inv_alternativ_qty_1   -- quantité alternative 1 (inventoriée)
                 , ilp_sys_alternativ_qty_1   -- quantité alternative 1 (système)
                 , ilp_inv_alternativ_qty_2   -- quantité alternative 2 (inventoriée)
                 , ilp_sys_alternativ_qty_2   -- quantité alternative 2 (système)
                 , ilp_inv_alternativ_qty_3   -- quantité alternative 3 (inventoriée)
                 , ilp_sys_alternativ_qty_3   -- quantité alternative 3 (système)
                 , ilp_inventory_date   -- date de l'inventaire
                 , ilp_is_original_pos   -- position extraite
                 , ilp_is_validated   -- position traitée
                 , ilp_retest_date   -- date réanalyse
                 , GCO_QUALITY_STATUS_ID   -- status qualité
                  )
           values (GetNewId   -- positions de l'inventaire
                 , tplOnlyPreparedPos.stm_inventory_list_id   -- liste d'inventaire
                 , tplOnlyPreparedPos.stm_inventory_task_id   -- inventaire
                 , tplOnlyPreparedPos.stm_stock_id   -- id stock logique
                 , tplOnlyPreparedPos.stm_location_id   -- id emplacement de stock
                 , tplOnlyPreparedPos.stm_period_id   -- id période
                 , tplOnlyPreparedPos.c_inventory_type   -- type d'inventaire
                 , tplOnlyPreparedPos.a_datecre   -- date de création
                 , tplOnlyPreparedPos.a_idcre   -- id de création
                 , tplOnlyPreparedPos.gco_good_id   -- id bien
                 , tplOnlyPreparedPos.gco_characterization_id   -- id caractérisation
                 , tplOnlyPreparedPos.gco_gco_characterization_id   -- gco_id charactérisation
                 , tplOnlyPreparedPos.gco2_gco_characterization_id   -- gco2_id charactérisation
                 , tplOnlyPreparedPos.gco3_gco_characterization_id   -- gco3_id charactérisation
                 , tplOnlyPreparedPos.gco4_gco_characterization_id   -- gco4_id charactérisation
                 , tplOnlyPreparedPos.ipr_characterization_value_1   -- valeur de caractérisation 1
                 , tplOnlyPreparedPos.ipr_characterization_value_2   -- valeur de caractérisation 2
                 , tplOnlyPreparedPos.ipr_characterization_value_3   -- valeur de caractérisation 3
                 , tplOnlyPreparedPos.ipr_characterization_value_4   -- valeur de caractérisation 4
                 , tplOnlyPreparedPos.ipr_characterization_value_5   -- valeur de caractérisation 5
                 , tplOnlyPreparedPos.ipr_inventory_quantity   -- quantité inventoriée
                 , tplOnlyPreparedPos.ipr_system_quantity   -- quantité système
                 , tplOnlyPreparedPos.ipr_provisory_input   -- quantité entrée provisoire
                 , tplOnlyPreparedPos.ipr_provisory_output   -- quantité sortie provisoire
                 , tplOnlyPreparedPos.ipr_assign_quantity   -- quantité attribuée sur stock
                 , tplOnlyPreparedPos.ipr_inventory_unit_price   -- prix unitaire inventorié
                 , tplOnlyPreparedPos.ipr_system_unit_price   -- prix unitaire système
                 , tplOnlyPreparedPos.ipr_inventory_value   -- valeur inventoriée
                 , tplOnlyPreparedPos.ipr_system_value   -- valeur système
                 , tplOnlyPreparedPos.ipr_inv_alternativ_qty_1   -- quantité alternative 1 (inventoriée)
                 , tplOnlyPreparedPos.ipr_sys_alternativ_qty_1   -- quantité alternative 1 (système)
                 , tplOnlyPreparedPos.ipr_inv_alternativ_qty_2   -- quantité alternative 2 (inventoriée)
                 , tplOnlyPreparedPos.ipr_sys_alternativ_qty_2   -- quantité alternative 2 (système)
                 , tplOnlyPreparedPos.ipr_inv_alternativ_qty_3   -- quantité alternative 3 (inventoriée)
                 , tplOnlyPreparedPos.ipr_sys_alternativ_qty_3   -- quantité alternative 3 (système)
                 , tplOnlyPreparedPos.ipr_inventory_date   -- date de l'inventaire
                 , tplOnlyPreparedPos.ipr_is_original_pos   -- position extraite
                 , tplOnlyPreparedPos.ipr_is_validated   -- position traitée
                 , tplOnlyPreparedPos.ipr_retest_date   -- date réanalyse
                 , tplOnlyPreparedPos.GCO_QUALITY_STATUS_ID   -- status qualité
                  );

      fetch crOnlyPreparedPos
       into tplOnlyPreparedPos;
    end loop;

    close crOnlyPreparedPos;
  end insertOnlyPreparedPos;

  /**
  * procedure insertExistinginvPos
  *
  * Description
  *    insertion dans la liste spécifiée (aListId) de positions d'inventaires
  *    issues de positions de stock
  * @created Sener Kalayci / Pierre-Yves Voirol
  * @created 04.10.2001
  *
  * @param aSessionId   id de session permettant de récupérer les lignes préparées
  *                     par l'utilisateur connecté
  * @param aListId      extraction de destination des lignes insérées
  * @param ainvTaskId   inventaire choisi par l'utilisateur
  * @param ainvPeriodId période d'extraction et de traitement de l'inventaire (période active)
  * @param ainvType     type d'inventaire
  */
  procedure insertExistinginvPos(
    aSessionId   stm_inventory_prepare.ipr_session_id%type
  , aListId      stm_inventory_list.stm_inventory_list_id%type
  , ainvTaskId   stm_inventory_list.stm_inventory_task_id%type
  , ainvPeriodId stm_inventory_task.stm_period_id%type
  , ainvType     stm_inventory_task.c_inventory_type%type
  )
  is
    cursor crExistinginvPos(
      cSessionId   stm_inventory_prepare.ipr_session_id%type
    , cListId      stm_inventory_list.stm_inventory_list_id%type
    , cinvTaskId   stm_inventory_list.stm_inventory_task_id%type
    , cinvPeriodId stm_inventory_task.stm_period_id%type
    , cinvType     stm_inventory_task.c_inventory_type%type
    )
    is
      select   cListId stm_inventory_list_id
             , cinvTaskId stm_inventory_task_id
             , spo.stm_stock_position_id stm_stock_position_id
             , spo.stm_stock_id stm_stock_id
             , spo.stm_location_id stm_location_id
             , cinvPeriodId stm_period_id
             , spo.stm_element_number_id stm_element_number_id
             , spo.stm_stm_element_number_id stm_stm_element_number_id
             , spo.stm2_stm_element_number_id stm2_stm_element_number_id
             , cinvType c_inventory_type
             , sysdate a_datecre
             , pcs.PC_I_LIB_SESSION.getuserini a_idcre
             , spo.gco_good_id gco_good_id
             , spo.gco_characterization_id gco_characterization_id
             , spo.gco_gco_characterization_id gco_gco_characterization_id
             , spo.gco2_gco_characterization_id gco2_gco_characterization_id
             , spo.gco3_gco_characterization_id gco3_gco_characterization_id
             , spo.gco4_gco_characterization_id gco4_gco_characterization_id
             , spo.spo_characterization_value_1 ipr_characterization_value_1
             , spo.spo_characterization_value_2 ipr_characterization_value_2
             , spo.spo_characterization_value_3 ipr_characterization_value_3
             , spo.spo_characterization_value_4 ipr_characterization_value_4
             , spo.spo_characterization_value_5 ipr_characterization_value_5
             , decode(inv.c_inventory_mode, '1', 0, '2', spo.spo_stock_quantity) ipr_inventory_quantity
             , spo.spo_stock_quantity ipr_system_quantity
             , spo.spo_provisory_input ipr_provisory_input
             , spo.spo_provisory_output ipr_provisory_output
             , spo.spo_assign_quantity ipr_assign_quantity
             , decode(inv.c_inventory_mode, '1', 0, '2', spo.spo_alternativ_quantity_1) ipr_inv_alternativ_qty_1
             , spo.spo_alternativ_quantity_1 ipr_sys_alternativ_qty_1
             , decode(inv.c_inventory_mode, '1', 0, '2', spo.spo_alternativ_quantity_2) ipr_inv_alternativ_qty_2
             , spo.spo_alternativ_quantity_2 ipr_sys_alternativ_qty_2
             , decode(inv.c_inventory_mode, '1', 0, '2', spo.spo_alternativ_quantity_3) ipr_inv_alternativ_qty_3
             , spo.spo_alternativ_quantity_3 ipr_sys_alternativ_qty_3
             , sysdate ipr_inventory_date
             , decode(ipr.stm_stock_position_id, null, 0, 1) ipr_is_original_pos
             , 0 ipr_is_validated
             , (gco_functions.getcostpricewithmanagementmode(spo.gco_good_id) ) ipr_inventory_unit_price
             , (gco_functions.getcostpricewithmanagementmode(spo.gco_good_id) ) ipr_system_unit_price
             , decode(inv.c_inventory_mode, '1', 0, '2', spo.spo_stock_quantity * gco_functions.getcostpricewithmanagementmode(spo.gco_good_id) )
                                                                                                                                            ipr_inventory_value
             , spo.spo_stock_quantity * gco_functions.getcostpricewithmanagementmode(spo.gco_good_id) ipr_system_value
             , stm_functions.getelementstatus(spo.stm_element_number_id) ipr_c_ele_num_status_1
             , stm_functions.getelementstatus(spo.stm_stm_element_number_id) ipr_c_ele_num_status_2
             , stm_functions.getelementstatus(spo.stm2_stm_element_number_id) ipr_c_ele_num_status_3
             , ele.sem_retest_date ipr_retest_date
             , ele.GCO_QUALITY_STATUS_ID
          from STM_STOCK_POSITION SPO
             , STM_INVENTORY_PREPARE IPR
             , STM_INVENTORY_TASK INV
             , STM_ELEMENT_NUMBER ELE
         where IPR.IPR_SESSION_ID = cSessionid   --  positions préparées de la session donnée
           and IPR.IPR_SELECTION = 1   -- positions sélectionnées
           and INV.STM_INVENTORY_TASK_ID = cInvTaskId
           and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = ELE.STM_ELEMENT_NUMBER_ID(+)
           and   --  et faisant référence à une position de stock déjà existante
               (    (    ipr.stm_stock_position_id = spo.stm_stock_position_id
                     and (    (spo.gco_characterization_id = ipr.gco_characterization_id)
                          or (    spo.gco_characterization_id is null
                              and ipr.gco_characterization_id is null)
                         )
                     and (    (spo.gco_gco_characterization_id = ipr.gco_gco_characterization_id)
                          or (    spo.gco_gco_characterization_id is null
                              and ipr.gco_gco_characterization_id is null)
                         )
                     and (    (spo.gco2_gco_characterization_id = ipr.gco2_gco_characterization_id)
                          or (    spo.gco2_gco_characterization_id is null
                              and ipr.gco2_gco_characterization_id is null)
                         )
                     and (    (spo.gco3_gco_characterization_id = ipr.gco3_gco_characterization_id)
                          or (    spo.gco3_gco_characterization_id is null
                              and ipr.gco3_gco_characterization_id is null)
                         )
                     and (    (spo.gco4_gco_characterization_id = ipr.gco4_gco_characterization_id)
                          or (    spo.gco4_gco_characterization_id is null
                              and ipr.gco4_gco_characterization_id is null)
                         )
                     and (    (spo.spo_characterization_value_1 = ipr.ipr_characterization_value_1)
                          or (    spo.spo_characterization_value_1 is null
                              and ipr.ipr_characterization_value_1 is null)
                         )
                     and (    (spo.spo_characterization_value_2 = ipr.ipr_characterization_value_2)
                          or (    spo.spo_characterization_value_2 is null
                              and ipr.ipr_characterization_value_2 is null)
                         )
                     and (    (spo.spo_characterization_value_3 = ipr.ipr_characterization_value_3)
                          or (    spo.spo_characterization_value_3 is null
                              and ipr.ipr_characterization_value_3 is null)
                         )
                     and (    (spo.spo_characterization_value_4 = ipr.ipr_characterization_value_4)
                          or (    spo.spo_characterization_value_4 is null
                              and ipr.ipr_characterization_value_4 is null)
                         )
                     and (    (spo.spo_characterization_value_5 = ipr.ipr_characterization_value_5)
                          or (    spo.spo_characterization_value_5 is null
                              and ipr.ipr_characterization_value_5 is null)
                         )
                    )
                or   --  ou ne faisant pas référence à une position de stock déjà existante mais...
                     -- ...dont les valeurs sont identiques à une position de stock
                   (    ipr.stm_stock_position_id is null
                    and spo.gco_good_id = ipr.gco_good_id
                    and spo.stm_stock_id = ipr.stm_stock_id
                    and spo.stm_location_id = ipr.stm_location_id
                    and (    (spo.gco_characterization_id = ipr.gco_characterization_id)
                         or (    spo.gco_characterization_id is null
                             and ipr.gco_characterization_id is null)
                        )
                    and (    (spo.gco_gco_characterization_id = ipr.gco_gco_characterization_id)
                         or (    spo.gco_gco_characterization_id is null
                             and ipr.gco_gco_characterization_id is null)
                        )
                    and (    (spo.gco2_gco_characterization_id = ipr.gco2_gco_characterization_id)
                         or (    spo.gco2_gco_characterization_id is null
                             and ipr.gco2_gco_characterization_id is null)
                        )
                    and (    (spo.gco3_gco_characterization_id = ipr.gco3_gco_characterization_id)
                         or (    spo.gco3_gco_characterization_id is null
                             and ipr.gco3_gco_characterization_id is null)
                        )
                    and (    (spo.gco4_gco_characterization_id = ipr.gco4_gco_characterization_id)
                         or (    spo.gco4_gco_characterization_id is null
                             and ipr.gco4_gco_characterization_id is null)
                        )
                    and (    (spo.spo_characterization_value_1 = ipr.ipr_characterization_value_1)
                         or (    spo.spo_characterization_value_1 is null
                             and ipr.ipr_characterization_value_1 is null)
                        )
                    and (    (spo.spo_characterization_value_2 = ipr.ipr_characterization_value_2)
                         or (    spo.spo_characterization_value_2 is null
                             and ipr.ipr_characterization_value_2 is null)
                        )
                    and (    (spo.spo_characterization_value_3 = ipr.ipr_characterization_value_3)
                         or (    spo.spo_characterization_value_3 is null
                             and ipr.ipr_characterization_value_3 is null)
                        )
                    and (    (spo.spo_characterization_value_4 = ipr.ipr_characterization_value_4)
                         or (    spo.spo_characterization_value_4 is null
                             and ipr.ipr_characterization_value_4 is null)
                        )
                    and (    (spo.spo_characterization_value_5 = ipr.ipr_characterization_value_5)
                         or (    spo.spo_characterization_value_5 is null
                             and ipr.ipr_characterization_value_5 is null)
                        )
                   )
               )
           --  et dont le stock est public
           and exists(select sto.stm_stock_id
                        from stm_stock sto
                       where sto.stm_stock_id = ipr.stm_stock_id
                         and sto.c_access_method = 'PUBLIC')
           and   -- et dont les valeurs ne sont pas identiques à une position déjà existante de la liste
               not exists(
                 select ilp.stm_inventory_list_pos_id
                   from stm_inventory_list_pos ilp
                  where ilp.gco_good_id = ipr.gco_good_id
                    and ilp.stm_stock_id = ipr.stm_stock_id
                    and ilp.stm_location_id = ipr.stm_location_id
                    and ilp.ilp_is_validated = 0
                    and (    (ilp.gco_characterization_id = ipr.gco_characterization_id)
                         or (    ilp.gco_characterization_id is null
                             and ipr.gco_characterization_id is null)
                        )
                    and (    (ilp.gco_gco_characterization_id = ipr.gco_gco_characterization_id)
                         or (    ilp.gco_gco_characterization_id is null
                             and ipr.gco_gco_characterization_id is null)
                        )
                    and (    (ilp.gco2_gco_characterization_id = ipr.gco2_gco_characterization_id)
                         or (    ilp.gco2_gco_characterization_id is null
                             and ipr.gco2_gco_characterization_id is null)
                        )
                    and (    (ilp.gco3_gco_characterization_id = ipr.gco3_gco_characterization_id)
                         or (    ilp.gco3_gco_characterization_id is null
                             and ipr.gco3_gco_characterization_id is null)
                        )
                    and (    (ilp.gco4_gco_characterization_id = ipr.gco4_gco_characterization_id)
                         or (    ilp.gco4_gco_characterization_id is null
                             and ipr.gco4_gco_characterization_id is null)
                        )
                    and (    (ilp.ilp_characterization_value_1 = ipr.ipr_characterization_value_1)
                         or (    ilp.ilp_characterization_value_1 is null
                             and ipr.ipr_characterization_value_1 is null)
                        )
                    and (    (ilp.ilp_characterization_value_2 = ipr.ipr_characterization_value_2)
                         or (    ilp.ilp_characterization_value_2 is null
                             and ipr.ipr_characterization_value_2 is null)
                        )
                    and (    (ilp.ilp_characterization_value_3 = ipr.ipr_characterization_value_3)
                         or (    ilp.ilp_characterization_value_3 is null
                             and ipr.ipr_characterization_value_3 is null)
                        )
                    and (    (ilp.ilp_characterization_value_4 = ipr.ipr_characterization_value_4)
                         or (    ilp.ilp_characterization_value_4 is null
                             and ipr.ipr_characterization_value_4 is null)
                        )
                    and (    (ilp.ilp_characterization_value_5 = ipr.ipr_characterization_value_5)
                         or (    ilp.ilp_characterization_value_5 is null
                             and ipr.ipr_characterization_value_5 is null)
                        ) )
      order by ipr.gco_good_id asc;

    tplExistinginvPos crExistinginvPos%rowtype;
  begin
    open crExistinginvPos(aSessionId, aListId, ainvTaskId, ainvPeriodId, ainvType);

    fetch crExistinginvPos
     into tplExistinginvPos;

    while crExistinginvPos%found loop
      insert into stm_inventory_list_pos
                  (stm_inventory_list_pos_id   -- positions de l'inventaire
                 , stm_inventory_list_id   -- liste d'inventaire
                 , stm_inventory_task_id   -- inventaire
                 , stm_stock_position_id   -- id positions de stock
                 , stm_stock_id   -- id stock logique
                 , stm_location_id   -- id emplacement de stock
                 , stm_period_id   -- id période
                 , stm_element_number_id   -- id numéro de pièce lot ou version
                 , stm_stm_element_number_id   -- stm_id numéro de pièce lot ou version
                 , stm2_stm_element_number_id   -- stm2_id numéro de pièce lot ou version
                 , c_inventory_type   -- type d'inventaire
                 , a_datecre   -- date de création
                 , a_idcre   -- id de création
                 , gco_good_id   -- id bien
                 , gco_characterization_id   -- id caractérisation
                 , gco_gco_characterization_id   -- gco_id charactérisation
                 , gco2_gco_characterization_id   -- gco2_id charactérisation
                 , gco3_gco_characterization_id   -- gco3_id charactérisation
                 , gco4_gco_characterization_id   -- gco4_id charactérisation
                 , ilp_characterization_value_1   -- valeur de caractérisation 1
                 , ilp_characterization_value_2   -- valeur de caractérisation 2
                 , ilp_characterization_value_3   -- valeur de caractérisation 3
                 , ilp_characterization_value_4   -- valeur de caractérisation 4
                 , ilp_characterization_value_5   -- valeur de caractérisation 5
                 , ilp_inventory_quantity   -- quantité inventoriée
                 , ilp_system_quantity   -- quantité système
                 , ilp_provisory_input   -- quantité entrée provisoire
                 , ilp_provisory_output   -- quantité sortie provisoire
                 , ilp_assign_quantity   -- quantité attribuée sur stock
                 , ilp_inventory_unit_price   -- prix unitaire inventorié
                 , ilp_system_unit_price   -- prix unitaire système
                 , ilp_inventory_value   -- valeur inventoriée
                 , ilp_system_value   -- valeur système
                 , ilp_inv_alternativ_qty_1   -- quantité alternative 1 (inventoriée)
                 , ilp_sys_alternativ_qty_1   -- quantité alternative 1 (système)
                 , ilp_inv_alternativ_qty_2   -- quantité alternative 2 (inventoriée)
                 , ilp_sys_alternativ_qty_2   -- quantité alternative 2 (système)
                 , ilp_inv_alternativ_qty_3   -- quantité alternative 3 (inventoriée)
                 , ilp_sys_alternativ_qty_3   -- quantité alternative 3 (système)
                 , ilp_inventory_date   -- date de l'inventaire
                 , ilp_is_original_pos   -- position extraite
                 , ilp_is_validated   -- position traitée
                 , ilp_c_ele_num_status_1   -- statut de la caractérisation 1
                 , ilp_c_ele_num_status_2   -- statut de la caractérisation 2
                 , ilp_c_ele_num_status_3   -- statut de la caractérisation 3
                 , ilp_retest_date   -- date réanalyse
                 , GCO_QUALITY_STATUS_ID   -- status qualité
                  )
           values (GetNewId   -- positions de l'inventaire
                 , tplExistinginvPos.stm_inventory_list_id   -- liste d'inventaire
                 , tplExistinginvPos.stm_inventory_task_id   -- inventaire
                 , tplExistinginvPos.stm_stock_position_id   -- id positions de stock
                 , tplExistinginvPos.stm_stock_id   -- stock logique
                 , tplExistinginvPos.stm_location_id   -- id emplacement de stock
                 , tplExistinginvPos.stm_period_id   -- id période
                 , tplExistinginvPos.stm_element_number_id   -- id numéro de pièce lot ou version
                 , tplExistinginvPos.stm_stm_element_number_id   -- stm_id numéro de pièce lot ou version
                 , tplExistinginvPos.stm2_stm_element_number_id   -- stm2_id numéro de pièce lot ou version
                 , tplExistinginvPos.c_inventory_type   -- type d'inventaire
                 , tplExistinginvPos.a_datecre   -- date de création
                 , tplExistinginvPos.a_idcre   -- id de création
                 , tplExistinginvPos.gco_good_id   -- id bien
                 , tplExistinginvPos.gco_characterization_id   -- id caractérisation
                 , tplExistinginvPos.gco_gco_characterization_id   -- gco_id charactérisation
                 , tplExistinginvPos.gco2_gco_characterization_id   -- gco2_id charactérisation
                 , tplExistinginvPos.gco3_gco_characterization_id   -- gco3_id charactérisation
                 , tplExistinginvPos.gco4_gco_characterization_id   -- gco4_id charactérisation
                 , tplExistinginvPos.ipr_characterization_value_1   -- valeur de caractérisation 1
                 , tplExistinginvPos.ipr_characterization_value_2   -- valeur de caractérisation 2
                 , tplExistinginvPos.ipr_characterization_value_3   -- valeur de caractérisation 3
                 , tplExistinginvPos.ipr_characterization_value_4   -- valeur de caractérisation 4
                 , tplExistinginvPos.ipr_characterization_value_5   -- valeur de caractérisation 5
                 , tplExistinginvPos.ipr_inventory_quantity   -- quantité inventoriée
                 , tplExistinginvPos.ipr_system_quantity   -- quantité système
                 , tplExistinginvPos.ipr_provisory_input   -- quantité entrée provisoire
                 , tplExistinginvPos.ipr_provisory_output   -- quantité sortie provisoire
                 , tplExistinginvPos.ipr_assign_quantity   -- quantité attribuée sur stock
                 , tplExistinginvPos.ipr_inventory_unit_price   -- prix unitaire inventorié
                 , tplExistinginvPos.ipr_system_unit_price   -- prix unitaire système
                 , tplExistinginvPos.ipr_inventory_value   -- valeur inventoriée
                 , tplExistinginvPos.ipr_system_value   -- valeur système
                 , tplExistinginvPos.ipr_inv_alternativ_qty_1   -- quantité alternative 1 (inventoriée)
                 , tplExistinginvPos.ipr_sys_alternativ_qty_1   -- quantité alternative 1 (système)
                 , tplExistinginvPos.ipr_inv_alternativ_qty_2   -- quantité alternative 2 (inventoriée)
                 , tplExistinginvPos.ipr_sys_alternativ_qty_2   -- quantité alternative 2 (système)
                 , tplExistinginvPos.ipr_inv_alternativ_qty_3   -- quantité alternative 3 (inventoriée)
                 , tplExistinginvPos.ipr_sys_alternativ_qty_3   -- quantité alternative 3 (système)
                 , tplExistinginvPos.ipr_inventory_date   -- date de l'inventaire
                 , tplExistinginvPos.ipr_is_original_pos   -- position extraite
                 , tplExistinginvPos.ipr_is_validated   -- position traitée
                 , tplExistinginvPos.ipr_c_ele_num_status_1   -- statut de la caractérisation 1
                 , tplExistinginvPos.ipr_c_ele_num_status_2   -- statut de la caractérisation 2
                 , tplExistinginvPos.ipr_c_ele_num_status_3   -- statut de la caractérisation 3
                 , tplExistinginvPos.ipr_retest_date   -- date réanalyse
                 , tplExistinginvPos.GCO_QUALITY_STATUS_ID   -- status qualité
                  );

      fetch crExistinginvPos
       into tplExistinginvPos;
    end loop;

    close crExistinginvPos;
  end insertExistinginvPos;

  function CreateNewJob(
    astm_inventory_list_id stm_inventory_list.stm_inventory_list_id%type
  , astm_inventory_task_id stm_inventory_task.stm_inventory_task_id%type
  , aC_inventory_job_type  stm_inventory_job.c_inventory_job_type%type
  , aJob_description       stm_inventory_job.ijo_job_description%type
  , aPc_user_id            pcs.pc_user.pc_user_id%type
  )
    return stm_inventory_job.stm_inventory_job_id%type
  is
    vstm_inventory_job_id stm_inventory_job.stm_inventory_job_id%type;
  begin
    select init_id_seq.nextval
      into vstm_inventory_job_id
      from dual;

    insert into stm_inventory_job
                (stm_inventory_JOB_ID
               , stm_inventory_TASK_ID
               , stm_inventory_LIST_ID
               , ijo_job_description
               , IJO_OWNER_NAME
               , PC_USER_ID
               , C_INVENTORY_JOB_TYPE
               , IJO_JOB_AVAILABLE
               , A_DATECRE
               , A_IDCRE
                )
         values (vstm_inventory_job_id
               , astm_inventory_task_id
               , astm_inventory_list_id
               , aJob_description
               , pcs.PC_I_LIB_SESSION.getuserini
               , aPc_user_id
               , aC_inventory_job_type
               , 1
               , sysdate
               , pcs.PC_I_LIB_SESSION.getuserini
                );

    return vstm_inventory_job_id;
  end CreateNewJob;

  procedure insert_qty_for_pos_without_det(pStm_inventory_list_id stm_inventory_list.stm_inventory_list_id%type)
  is
    cursor crAll_pos_without_det(cStm_inventory_list_id stm_inventory_list.stm_inventory_list_id%type)
    is
      select ilp.*
        from stm_inventory_list_pos ilp
       where ilp.stm_inventory_list_id = cStm_inventory_list_id
         and ilp.ilp_inventory_quantity = 0
         and ilp.ilp_is_validated = 0
         and not exists(select 1
                          from stm_inventory_job_detail ijd
                         where ijd.stm_inventory_list_pos_id = ilp.stm_inventory_list_pos_id);

    tplAll_pos_without_det crAll_pos_without_det%rowtype;
    vInventory_job_id      stm_inventory_job.stm_inventory_job_id%type;
    vInventory_task_id     stm_inventory_task.stm_inventory_task_id%type;
  begin
    open crAll_pos_without_det(pStm_inventory_list_id);

    fetch crAll_pos_without_det
     into tplAll_pos_without_det;

    if crAll_pos_without_det%found then
      select ili.stm_inventory_task_id
        into vInventory_task_id
        from stm_inventory_list ili
       where ili.stm_inventory_list_id = pStm_inventory_list_id;

--, pcs.PC_I_LIB_SESSION.getuserlangid
      vInventory_job_id  :=
        CreateNewJob(pStm_inventory_list_id
                   , vInventory_task_id
                   , '01'
                   , pcs.pc_functions.TRANSLATEWORD('STM_INV_ZERO_JOB_AUTO_GENERATED') || ' (' || to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS') || ')'
                   , pcs.PC_I_LIB_SESSION.getuserid
                    );
    end if;

    while crAll_pos_without_det%found loop
      insert into stm_inventory_JOB_DETAIL
                  (stm_inventory_job_detail_id
                 , stm_inventory_JOB_ID
                 , stm_inventory_LIST_ID
                 , GCO_GOOD_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , IJD_QUANTITY
                 , IJD_VALUE
                 , IJD_UNIT_PRICE
                 , IJD_WORDinG
                 , IJD_CHARACTERIZATION_VALUE_1
                 , IJD_CHARACTERIZATION_VALUE_2
                 , IJD_CHARACTERIZATION_VALUE_3
                 , IJD_CHARACTERIZATION_VALUE_4
                 , IJD_CHARACTERIZATION_VALUE_5
                 , IJD_LinE_VALIDATED
                 , IJD_LinE_in_USE
                 , IJD_inPUT_USER_NAME
                 , A_DATECRE
                 , A_IDCRE
                 , stm_inventory_TASK_ID
                 , stm_inventory_LIST_POS_ID
                 , IJD_ALTERNATIV_QTY_1
                 , IJD_ALTERNATIV_QTY_2
                 , IJD_ALTERNATIV_QTY_3
                  )
        select init_id_seq.nextval
             , vInventory_job_id
             , pStm_inventory_list_id
             , tplAll_pos_without_det.GCO_GOOD_ID
             , tplAll_pos_without_det.STM_STOCK_ID
             , tplAll_pos_without_det.STM_LOCATION_ID
             , tplAll_pos_without_det.GCO_CHARACTERIZATION_ID
             , tplAll_pos_without_det.GCO_GCO_CHARACTERIZATION_ID
             , tplAll_pos_without_det.GCO2_GCO_CHARACTERIZATION_ID
             , tplAll_pos_without_det.GCO3_GCO_CHARACTERIZATION_ID
             , tplAll_pos_without_det.GCO4_GCO_CHARACTERIZATION_ID
             , tplAll_pos_without_det.ilp_system_quantity
             , tplAll_pos_without_det.ilp_system_value
             , tplAll_pos_without_det.ilp_system_unit_price
             , null
             , tplAll_pos_without_det.ILP_CHARACTERIZATION_VALUE_1
             , tplAll_pos_without_det.ILP_CHARACTERIZATION_VALUE_2
             , tplAll_pos_without_det.ILP_CHARACTERIZATION_VALUE_3
             , tplAll_pos_without_det.ILP_CHARACTERIZATION_VALUE_4
             , tplAll_pos_without_det.ILP_CHARACTERIZATION_VALUE_5
             , 0
             , 0
             , PCS.PC_I_LIB_SESSION.GetUserini
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserini
             , tplAll_pos_without_det.stm_inventory_task_id
             , tplAll_pos_without_det.stm_inventory_LIST_POS_ID
             , tplAll_pos_without_det.ILp_inV_ALTERNATIV_QTY_1
             , tplAll_pos_without_det.ILp_inV_ALTERNATIV_QTY_2
             , tplAll_pos_without_det.ILp_inV_ALTERNATIV_QTY_3
          from dual;

      fetch crAll_pos_without_det
       into tplAll_pos_without_det;
    end loop;

    close crAll_pos_without_det;
  end insert_qty_for_pos_without_det;

  -- insertion des positions préparées dans la liste
  procedure insertPreparedintoList(aSessionId stm_inventory_PREPARE.IPR_SESSION_ID%type, aListId stm_inventory_LIST.stm_inventory_LIST_ID%type)
  is
    vinvTaskId   stm_inventory_TASK.stm_inventory_TASK_ID%type;   -- inventaire lié à la liste
    vinvPeriodId stm_inventory_TASK.STM_PERIOD_ID%type;   -- Période de l'inventaire
    vinvType     stm_inventory_TASK.C_INVENTORY_TYPE%type;   -- Type d'inventaire
  begin
    select inv.stm_inventory_task_id
         , inv.stm_period_id
         , inv.c_inventory_type
      into vinvTaskId
         , vinvPeriodId
         , vinvType
      from stm_inventory_task inv
         , stm_inventory_list ili
     where ili.stm_inventory_list_id = aListId
       and inv.stm_inventory_task_id = ili.stm_inventory_task_id;

    if vinvType = '01' then
      /**
         inventaire initial
         insertion des positions préparées
         ne faisant pas référence à une position de stock
      */
      insertOnlyPreparedPos(aSessionId, aListId, vinvTaskId, vinvPeriodId, vinvType);
    elsif vinvType = '02' then
      /**
         inventaire manuel
         insertion des positions préparées faisant
         référence à une position de stock
      */
      insertExistinginvPos(aSessionId, aListId, vinvTaskId, vinvPeriodId, vinvType);
      /**
         insertion des positions préparées ne faisant pas
         référence à une position de stock
      */
      insertOnlyPreparedPos(aSessionId, aListId, vinvTaskId, vinvPeriodId, vinvType);
    end if;
  end insertPreparedintoList;

  procedure set_inventory_status(pinventoryId stm_inventory_TASK.stm_inventory_TASK_ID%type, pinvStatus stm_inventory_TASK.C_INVENTORY_STATUS%type)
  is
  begin
    update stm_inventory_TASK
       set C_INVENTORY_STATUS = pinvStatus
         , A_DATEMOD = sysdate
         , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
     where stm_inventory_TASK_ID = pinventoryId;
  end set_inventory_status;

  procedure set_inventory_list_status(pinventoryId stm_inventory_TASK.stm_inventory_TASK_ID%type, pinvStatus stm_inventory_TASK.C_INVENTORY_STATUS%type)
  is
  begin
    update stm_inventory_list
       set c_inventory_list_status = pinvstatus
         , A_DATEMOD = sysdate
         , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
     where stm_inventory_task_id = pinventoryid;
  end set_inventory_list_status;

  procedure set_list_status(pinvListId stm_inventory_LIST.stm_inventory_LIST_ID%type, pinvStatus stm_inventory_TASK.C_INVENTORY_STATUS%type)
  is
  begin
    update stm_inventory_LIST
       set C_INVENTORY_LIST_STATUS = pinvStatus
         , A_DATEMOD = sysdate
         , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
     where stm_inventory_LIST_ID = pinvListId;
  end set_list_status;

  function count_inv_list_by_status(pinventoryId stm_inventory_LIST.stm_inventory_TASK_ID%type, pListStatus stm_inventory_LIST.C_INVENTORY_LIST_STATUS%type)
    return number
  is
    vCounter number;
    vStatus  stm_inventory_LIST.C_INVENTORY_LIST_STATUS%type;
  begin
    select   C_INVENTORY_LIST_STATUS
           , count(stm_inventory_LIST_ID) COUNTER
        into vStatus
           , vCounter
        from stm_inventory_LIST
       where stm_inventory_TASK_ID = pinventoryId
    group by C_INVENTORY_LIST_STATUS
      having C_INVENTORY_LIST_STATUS = pListStatus;

    return vCounter;
  exception
    when no_data_found then
      return 0;
  end count_inv_list_by_status;

  function count_inv_list_all_status(pinventoryId stm_inventory_LIST.stm_inventory_TASK_ID%type)
    return number
  is
    vCounter number;
  begin
    select count(stm_inventory_LIST_ID) COUNTER
      into vCounter
      from stm_inventory_LIST
     where stm_inventory_TASK_ID = pinventoryId;

    return vCounter;
  end count_inv_list_all_status;

  procedure can_complete_inventory(
    pinventoryId   in     STM_INVENTORY_LIST.STM_INVENTORY_TASK_ID%type
  , pListStatus    in     STM_INVENTORY_LIST.C_INVENTORY_LIST_STATUS%type
  , pAllTreated    out    number
  , pAllIntegrated out    number
  )
  is
    vCounterAll number;
    vCounter    number;
  begin
    vCounterAll  := STM_INVENTORY.COUNT_INV_LIST_ALL_STATUS(pInventoryId);
    vCounter     := STM_INVENTORY.COUNT_INV_LIST_BY_STATUS(pInventoryId, pListStatus);

    if vCounterAll = 0 then
      pAllTreated  := -1;
    else
      pAllTreated  := vCounterAll - vCounter;
    end if;

    if IsAllExternalIntegrated(pInventoryId) = 0 then
      pAllIntegrated  := 1;
    else
      pAllIntegrated  := 0;
    end if;
  end can_complete_inventory;

  function count_list_connected_user(pinvListId in stm_inventory_LIST.stm_inventory_LIST_ID%type)
    return number
  is
    vCounter number;
  begin
    select count(*)
      into vCounter
      from stm_inventory_LIST_USER
     where stm_inventory_LIST_ID = pinvListId;

    return vCounter;
  end count_list_connected_user;

  function count_task_connected_user(pInvTaskId in STM_INVENTORY_TASK.STM_INVENTORY_TASK_ID%type)
    return number
  is
    vCounter number;
  begin
    select count(*)
      into vCounter
      from STM_INVENTORY_LIST_USER ILU
         , STM_INVENTORY_LIST ILI
     where ILI.STM_INVENTORY_LIST_ID = ILU.STM_INVENTORY_LIST_ID
       and ILI.STM_INVENTORY_TASK_ID = pInvTaskId;

    return vCounter;
  end count_task_connected_user;

  function list_position_exist(pinvListId stm_inventory_LIST.stm_inventory_LIST_ID%type)
    return number
  is
    vCounter number;
  begin
    select count(stm_inventory_LIST_POS_ID)
      into vCounter
      from stm_inventory_LIST_POS
     where stm_inventory_LIST_ID = pinvListId;

    return vCounter;
  end list_position_exist;

  procedure DELETE_inV_LIST(pinvListId stm_inventory_LIST.stm_inventory_LIST_ID%type, pStatus in out varchar)
  is
    cursor crinventory_List_Pos(cinvListId stm_inventory_list_pos.stm_inventory_list_pos_id%type)
    is
      select rownum rownumber
           , v.*
        from (select   ilp.stm_inventory_list_pos_id
                  from stm_inventory_list_pos ilp
                 where ilp.stm_inventory_list_Id = cinvListId
                   and ilp.ilp_is_validated = 0
              order by gco_good_id asc) v;

    type stm_inventory_list_pos_type is table of crinventory_List_Pos%rowtype
      index by binary_integer;

    vCounterStart         number;
    vCounterEnd           number;
    vStatus               stm_inventory_LIST.C_INVENTORY_LIST_STATUS%type;
    tplinventory_List_Pos crinventory_List_Pos%rowtype;
    tabinventory_List_Pos stm_inventory_list_pos_type;
    vLastRowNumber        binary_integer;
    vTabCounter           binary_integer;
  begin
    -- Recherche du statut de la liste
    select C_INVENTORY_LIST_STATUS
      into vStatus
      from STM_INVENTORY_LIST
     where STM_INVENTORY_LIST_ID = pinvListId;

    if vStatus in('01', '02', '03') then
      if COUNT_LIST_CONNECTED_USER(pinvListId) = 0 then
        -- Nombre d'enregistrements au début
        select count(*)
          into vCounterStart
          from stm_inventory_LIST_POS ILP
         where ILP.stm_inventory_LIST_ID = pinvListId;

        /*
           Explications relatives au traitement effectué ci-dessous
           --------------------------------------------------------

           Ancienne méthode :

           Delete
             From stm_inventory_List_Pos Ilp
           Where Ilp.stm_inventory_List_Id = pinvlistid and
                 Ilp.Ilp_Is_Validated = 0;

           Cette méthode générait des deadlocks car l'ordre de verrouillages des enregistrements
           n'était pas garanti (devrait être triée selon gco_good_id afin de s'accomoder aux
           mises à jour générées par les documents)


           Nouvelle méthode :

           Utilisation d'un curseur qui prépare les lignes à supprimer en les ordonnant
           selon le gco_good_id. Cette méthode devrait nous éviter des deadlocks, mais
           ne nous évitera pas les locks et temps d'attente.

           Afin d'éviter un autre écueil, lié à la modification de données présente dans un
           curseur (pouvant générer potentiellement un message "Snapshot too old"), la liste des
           lignes à supprimer est dans un premier temps transférée dans une table mémoire; puis cette
           table mémoire est parcouru dans l'ordre des enregistrements pour suppression des lignes.
        */

        -- transfert du curseur dans la table mémoire
        vLastRowNumber  := 0;

        open crinventory_List_Pos(pinvListId);

        fetch crinventory_List_Pos
         into tplinventory_List_Pos;

        while crinventory_List_Pos%found loop
          tabinventory_List_Pos(tplinventory_List_Pos.rownumber)  := tplinventory_List_Pos;
          vLastRowNumber                                          := tplinventory_List_Pos.rownumber;

          fetch crinventory_List_Pos
           into tplinventory_List_Pos;
        end loop;

        close crinventory_List_Pos;

        -- effacement des lignes contenues dans la table mémoire
        for vTabCounter in 1 .. vLastRowNumber loop
          -- suppression des détails des quantités saisies (détail de journal)
          delete from stm_inventory_job_detail det
                where det.stm_inventory_list_pos_id = tabinventory_List_Pos(vTabCounter).stm_inventory_list_pos_id;

          -- suppression des positions extraites
          delete from stm_inventory_list_pos ilp
                where ilp.stm_inventory_list_pos_id = tabinventory_List_Pos(vTabCounter).stm_inventory_list_pos_id;
        end loop;

        -- Nombre d'enregistrement avec effacement
        select count(*)
          into vCounterEnd
          from stm_inventory_LIST_POS ILP
         where ILP.stm_inventory_LIST_ID = pinvListId;

        -- Suppression liste complete
        if vCounterEnd = 0 then
          pStatus  := '001';   -- Liste effacée

          -- suppression des journaux liés à la liste
          delete from stm_inventory_job ijo
                where ijo.stm_inventory_list_id = pInvListId;

          -- suppression de la liste
          delete from stm_inventory_list
                where stm_inventory_list_id = pinvlistid;
        else
          if vCounterStart = vCounterEnd then
            pStatus  := '002';   -- Liste non effacée
          else
            pStatus  := '003';   -- Liste effacée partiellement
          end if;
        end if;
      else
        pStatus  := '004';   -- Liste en cours d'utilisation
      end if;
    else
      pStatus  := '005';   -- Status de la liste autre que 01, 02, 03
    end if;
  end DELETE_inV_LIST;

  procedure DELETE_inV_LIST_POS(pinvListPosId stm_inventory_LIST_POS.stm_inventory_LIST_POS_ID%type)
  is
  begin
    delete from stm_inventory_LIST_POS
          where stm_inventory_LIST_POS_ID = pinvListPosId
            and ILP_IS_VALIDATED = 0;
  end DELETE_inV_LIST_POS;

  procedure DELETE_inV_JOB(pinvJobId stm_inventory_JOB.stm_inventory_JOB_ID%type)
  is
    vCounter number;
  begin
    delete from stm_inventory_JOB_DETAIL   -- Suppression des détails non validés du journal
          where stm_inventory_JOB_ID = pinvJobId
            and IJD_LinE_VALIDATED = 0;

    select count(*)   -- Récupération du nombre de détails suite à la suppression
      into vCounter
      from stm_inventory_JOB_DETAIL
     where stm_inventory_JOB_ID = pinvJobId;

    if vCounter = 0 then
      delete from stm_inventory_JOB   -- Suppression du journal si celui - ci n'a plus de détails
            where stm_inventory_JOB_ID = pinvJobId;
    end if;
  end DELETE_inV_JOB;

  function DETAIL_JOB_EXIST(pinvJobId stm_inventory_JOB.stm_inventory_JOB_ID%type)
    return number
  is
    vCounter number;
  begin
    select count(stm_inventory_JOB_DETAIL_ID)
      into vCounter
      from stm_inventory_JOB_DETAIL
     where stm_inventory_JOB_ID = pinvJobId;

    return vCounter;
  end DETAIL_JOB_EXIST;

  procedure DELETE_PREPARED_POS(pSessionId stm_inventory_PREPARE.IPR_SESSION_ID%type)
  is
    vCounter number;
  begin
    delete from stm_inventory_prepare
          where IPR_SESSION_ID = pSessionId;
  end DELETE_PREPARED_POS;

  procedure STOP_JOB_CONNECTION(pListUserId STM_INVENTORY_LIST_USER.STM_INVENTORY_LIST_USER_ID%type, ListDisconnected out number)
  is
    vSessionId STM_INVENTORY_LIST_USER.ILU_SESSION_ID%type;
  begin
    begin
      select ILU_SESSION_ID
        into vSessionId
        from STM_INVENTORY_LIST_USER
       where STM_INVENTORY_LIST_USER_ID = pListUserId;

      if COM_FUNCTIONS.Is_Session_Alive(vSessionId) = 0 then
        ListDisconnected  := 1;

        delete from STM_INVENTORY_LIST_USER
              where STM_INVENTORY_LIST_USER_ID = pListUserId;
      else
        ListDisconnected  := 0;
      end if;
    exception
      when no_data_found then
        ListDisconnected  := -1;
    end;
  end STOP_JOB_CONNECTION;

  procedure stop_list_connection(pListId STM_INVENTORY_LIST_USER.STM_INVENTORY_LIST_ID%type, pError out number)
  is
    cursor crListUserId(cListId STM_INVENTORY_LIST_USER.STM_INVENTORY_LIST_ID%type)
    is
      select STM_INVENTORY_LIST_USER_ID
        from STM_INVENTORY_LIST_USER
       where STM_INVENTORY_LIST_ID = cListId;

    tplListUserId crListUserId%rowtype;   -- pas nécessaire avec la boucle for
  begin
    pError  := -1;

    for tplListUserId in crListUserId(pListId) loop
      STOP_JOB_CONNECTION(tplListUserId.STM_INVENTORY_LIST_USER_ID, pError);
    end loop;
  end stop_list_connection;

  function existsavailableuserjob(pUserId stm_inventory_JOB.PC_USER_ID%type, pListId stm_inventory_JOB.stm_inventory_LIST_ID%type)
    return number
  is
    vResult number;
  begin
    select sign(nvl(max(stm_inventory_JOB_ID), 0) )
      into vResult
      from stm_inventory_JOB
     where PC_USER_ID = pUserId
       and stm_inventory_LIST_ID = pListId
       and IJO_JOB_AVAILABLE = 1
       and rownum = 1;

    return vResult;
  exception
    when no_data_found then
      return 0;
  end existsavailableuserjob;

  procedure insertListPosintoWork(pListId stm_inventory_LIST.stm_inventory_LIST_ID%type, pJobId stm_inventory_JOB.stm_inventory_JOB_ID%type)
  is
  begin
    stm_inventory.UpdateConnection(pListId, pJobId, 1);   -- Ajout de la connexion
    stm_inventory.SET_LIST_STATUS(pListId, '03');

    insert into stm_inventory_list_work
                (stm_inventory_LIST_POS_ID   -- Positions de l'inventaire
               , stm_inventory_TASK_ID   -- inventaire
               , stm_inventory_LIST_ID   -- Liste d'inventaire
               , STM_STOCK_POSITION_ID   -- ID positions de stock
               , STM_STOCK_ID   -- ID stock logique
               , STM_LOCATION_ID   -- ID emplacement de stock
               , STM_PERIOD_ID   -- ID période
               , STM_ELEMENT_NUMBER_ID   -- ID numéro de pièce lot ou version
               , STM_STM_ELEMENT_NUMBER_ID   -- STM_ID numéro de pièce lot ou version
               , STM2_STM_ELEMENT_NUMBER_ID   -- STM2_ID numéro de pièce lot ou version
               , ILP_C_ELE_NUM_STATUS_1   -- Statut de la caractérisation 1
               , ILP_C_ELE_NUM_STATUS_2   -- Statut de la caractérisation 2
               , ILP_C_ELE_NUM_STATUS_3   -- Statut de la caractérisation 3
               , C_INVENTORY_TYPE   -- Type d'inventaire
               , C_INVENTORY_ERROR_STATUS   -- Statut de la position
               , GCO_GOOD_ID   -- ID bien
               , GCO_CHARACTERIZATION_ID   -- ID caractérisation
               , GCO_GCO_CHARACTERIZATION_ID   -- GCO_ID charactérisation
               , GCO2_GCO_CHARACTERIZATION_ID   -- GCO2_ID charactérisation
               , GCO3_GCO_CHARACTERIZATION_ID   -- GCO3_ID charactérisation
               , GCO4_GCO_CHARACTERIZATION_ID   -- GCO4_ID charactérisation
               , ILP_CHARACTERIZATION_VALUE_1   -- Valeur de caractérisation 1
               , ILP_CHARACTERIZATION_VALUE_2   -- Valeur de caractérisation 2
               , ILP_CHARACTERIZATION_VALUE_3   -- Valeur de caractérisation 3
               , ILP_CHARACTERIZATION_VALUE_4   -- Valeur de caractérisation 4
               , ILP_CHARACTERIZATION_VALUE_5   -- Valeur de caractérisation 5
               , ILP_SYS_ALTERNATIV_QTY_1   -- Quantité alternative 1 (système)
               , ILP_SYS_ALTERNATIV_QTY_2   -- Quantité alternative 2 (système)
               , ILP_SYS_ALTERNATIV_QTY_3   -- Quantité alternative 3 (système)
               , ILP_SYSTEM_VALUE   -- Valeur système
               , ILP_SYSTEM_UNIT_PRICE   -- Prix unitaire système
               , ILP_SYSTEM_QUANTITY   -- Quantité système
               , ILP_PROVISORY_INPUT   -- Quantité entrée provisoire
               , ILP_PROVISORY_OUTPUT   -- Quantité sortie provisoire
               , ILP_INV_ALTERNATIV_QTY_1   -- Quantité alternative 1 (inventoriée)
               , ILP_INV_ALTERNATIV_QTY_2   -- Quantité alternative 2 (inventoriée)
               , ILP_INV_ALTERNATIV_QTY_3   -- Quantité alternative 3 (inventoriée)
               , ILP_INVENTORY_VALUE   -- Valeur inventoriée
               , ILP_INVENTORY_UNIT_PRICE   -- Prix unitaire inventorié
               , ILP_INVENTORY_QUANTITY   -- Quantité inventoriée
               , ILP_IS_VALIDATED   -- Position traitée
               , ILP_IS_ORIGinAL_POS   -- Position extraite
               , ILP_INVENTORY_DATE   -- Date de l'inventaire
               , ILP_COMMENT   -- Commentaire
               , ILP_ASSIGN_QUANTITY   -- Quantité attribuée sur stock
               , ILW_SESSION_ID   -- Identifiant de session
               , ILW_INV_ALTERNATIV_QTY_1   -- Quantité alternative 1 saisie
               , ILW_INV_ALTERNATIV_QTY_2   -- Quantité alternative 2 saisie
               , ILW_INV_ALTERNATIV_QTY_3   -- Quantité alternative 3 saisie
               , ILW_INPUT_VALUE   -- Prix total saisie
               , ILW_INPUT_UNIT_PRICE   -- Prix unitaire saisie
               , ILW_INPUT_QUANTITY   -- Quantité saisie
               , A_IDCRE   -- ID de création
               , A_DATECRE   -- Date de création
               , ILW_RETEST_DATE   -- délai de réanalyse
               , GCO_QUALITY_STATUS_ID   --status qualité
                )
      select stm_inventory_LIST_POS_ID   -- Positions de l'inventaire
           , stm_inventory_TASK_ID   -- inventaire
           , stm_inventory_LIST_ID   -- Liste d'inventaire
           , STM_STOCK_POSITION_ID   -- ID positions de stock
           , STM_STOCK_ID   -- ID stock logique
           , STM_LOCATION_ID   -- ID emplacement de stock
           , STM_PERIOD_ID   -- ID période
           , STM_ELEMENT_NUMBER_ID   -- ID numéro de pièce lot ou version
           , STM_STM_ELEMENT_NUMBER_ID   -- STM_ID numéro de pièce lot ou version
           , STM2_STM_ELEMENT_NUMBER_ID   -- STM2_ID numéro de pièce lot ou version
           , ILP_C_ELE_NUM_STATUS_1   -- Statut de la caractérisation 1
           , ILP_C_ELE_NUM_STATUS_2   -- Statut de la caractérisation 2
           , ILP_C_ELE_NUM_STATUS_3   -- Statut de la caractérisation 3
           , C_INVENTORY_TYPE   -- Type d'inventaire
           , C_INVENTORY_ERROR_STATUS   -- Statut de la position
           , GCO_GOOD_ID   -- ID bien
           , GCO_CHARACTERIZATION_ID   -- ID caractérisation
           , GCO_GCO_CHARACTERIZATION_ID   -- GCO_ID charactérisation
           , GCO2_GCO_CHARACTERIZATION_ID   -- GCO2_ID charactérisation
           , GCO3_GCO_CHARACTERIZATION_ID   -- GCO3_ID charactérisation
           , GCO4_GCO_CHARACTERIZATION_ID   -- GCO4_ID charactérisation
           , ILP_CHARACTERIZATION_VALUE_1   -- Valeur de caractérisation 1
           , ILP_CHARACTERIZATION_VALUE_2   -- Valeur de caractérisation 2
           , ILP_CHARACTERIZATION_VALUE_3   -- Valeur de caractérisation 3
           , ILP_CHARACTERIZATION_VALUE_4   -- Valeur de caractérisation 4
           , ILP_CHARACTERIZATION_VALUE_5   -- Valeur de caractérisation 5
           , ILP_SYS_ALTERNATIV_QTY_1   -- Quantité alternative 1 (système)
           , ILP_SYS_ALTERNATIV_QTY_2   -- Quantité alternative 2 (système)
           , ILP_SYS_ALTERNATIV_QTY_3   -- Quantité alternative 3 (système)
           , ILP_SYSTEM_VALUE   -- Valeur système
           , ILP_SYSTEM_UNIT_PRICE   -- Prix unitaire système
           , ILP_SYSTEM_QUANTITY   -- Quantité système
           , ILP_PROVISORY_INPUT   -- Quantité entrée provisoire
           , ILP_PROVISORY_OUTPUT   -- Quantité sortie provisoire
           , ILP_INV_ALTERNATIV_QTY_1   -- Quantité alternative 1 (inventoriée)
           , ILP_INV_ALTERNATIV_QTY_2   -- Quantité alternative 2 (inventoriée)
           , ILP_INV_ALTERNATIV_QTY_3   -- Quantité alternative 3 (inventoriée)
           , ILP_INVENTORY_VALUE   -- Valeur inventoriée
           , ILP_INVENTORY_UNIT_PRICE   -- Prix unitaire inventorié
           , ILP_INVENTORY_QUANTITY   -- Quantité inventoriée
           , ILP_IS_VALIDATED   -- Position traitée
           , ILP_IS_ORIGINAL_POS   -- Position extraite
           , ILP_INVENTORY_DATE   -- Date de l'inventaire
           , ILP_COMMENT   -- Commentaire
           , ILP_ASSIGN_QUANTITY   -- Quantité attribuée sur stock
           , userenv('SESSIONID')   -- Identifiant de session
           , ILP_INV_ALTERNATIV_QTY_1   -- Quantité alternative 3 saisie
           , ILP_INV_ALTERNATIV_QTY_2   -- Quantité alternative 2 saisie
           , ILP_INV_ALTERNATIV_QTY_3   -- Quantité alternative 1 saisie
           , ILP_INVENTORY_VALUE   -- Prix total saisie
           , ILP_SYSTEM_UNIT_PRICE   -- Prix unitaire saisie
           , ILP_INVENTORY_QUANTITY   -- Quantité saisie
           , PCS.PC_I_LIB_SESSION.GetUserini   -- ID de création
           , sysdate   -- Date de création
           , ILP_RETEST_DATE   -- delai de réanalyse
           , GCO_QUALITY_STATUS_ID   --status qualité
        from stm_inventory_LIST_POS
       where stm_inventory_LIST_ID = pListId;
  end insertListPosintoWork;

  procedure UpdateConnection(
    pListId           STM_INVENTORY_LIST.STM_INVENTORY_LIST_ID%type
  , pJobId            STM_INVENTORY_JOB.STM_INVENTORY_JOB_ID%type
  , pCreateConnection number
  )
  is
  begin
    if pCreateConnection = 1 then
      insert into STM_INVENTORY_LIST_USER
                  (STM_INVENTORY_LIST_USER_ID
                 , STM_INVENTORY_LIST_ID
                 , STM_INVENTORY_JOB_ID
                 , PC_USER_ID
                 , ILU_MACHINE_NAME
                 , ILU_SESSION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select init_id_seq.nextval
             , pListId
             , pJobId
             , PCS.PC_I_LIB_SESSION.GetUserId
             , userenv('TERMINAL')
             ,
               --USERENV('SESSIONID'),
               sys.DBMS_SESSION.UNIQUE_SESSION_ID
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from dual;

      UpdateJob(pJobId, 1);
    elsif pCreateConnection = 0 then
      delete from STM_INVENTORY_LIST_USER
            where STM_INVENTORY_JOB_ID = pJobId;
    --mise à jour du nombre d'utilisateurs connectés au journal dans le trigger BD de la table STM_INVENTORY_LIST_USER
    end if;
  end UpdateConnection;

  procedure UpdateJob(pJobId STM_INVENTORY_JOB.STM_INVENTORY_JOB_ID%type, pConnection number)
  is
  begin
    if pConnection = 1 then
      update STM_INVENTORY_JOB
         set PC__PC_USER_ID = PCS.PC_I_LIB_SESSION.GETUSERID
           , IJO_CONNECTED_USER_NAME = PCS.PC_I_LIB_SESSION.GETUSERINI
           , IJO_JOB_AVAILABLE = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
       where STM_INVENTORY_JOB_ID = pJobId;
    elsif pConnection = 0 then
      update STM_INVENTORY_JOB
         set PC__PC_USER_ID = null
           , IJO_CONNECTED_USER_NAME = null
           , IJO_JOB_AVAILABLE = 1
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
       where STM_INVENTORY_JOB_ID = pJobId;
    end if;
  end UpdateJob;

  procedure DeleteWorkList(pSessionId stm_inventory_list_work.ILW_SESSION_ID%type, pListId stm_inventory_list_work.stm_inventory_LIST_ID%type)
  is
  begin
    delete from stm_inventory_list_work
          where ILW_SESSION_ID = pSessionId
            and stm_inventory_LIST_ID = pListId;
  end DeleteWorkList;

  procedure OnWorkGoodinput(
    pGoodId              stm_inventory_list_work.GCO_GOOD_ID%type
  , pGoodDigits      out GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  , pGoodUnitPrice   out STM_INVENTORY_LIST_WORK.ILW_INPUT_UNIT_PRICE%type
  , pStkManagement   out GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type
  , pStockId         out stm_inventory_list_work.STM_STOCK_ID%type
  , pLocationId      out stm_inventory_list_work.STM_LOCATION_ID%type
  , pAltQty1         out GCO_PRODUCT.PDT_ALTERNATIVE_QUANTITY_1%type
  , pAltQty2         out GCO_PRODUCT.PDT_ALTERNATIVE_QUANTITY_2%type
  , pAltQty3         out GCO_PRODUCT.PDT_ALTERNATIVE_QUANTITY_3%type
  , pAltFac1         out GCO_PRODUCT.PDT_CONVERSION_FACTOR_1%type
  , pAltFac2         out GCO_PRODUCT.PDT_CONVERSION_FACTOR_2%type
  , pAltFac3         out GCO_PRODUCT.PDT_CONVERSION_FACTOR_3%type
  , pAltDesc1        out DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_WORDinG%type
  , pAltDesc2        out DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_WORDinG%type
  , pAltDesc3        out DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_WORDinG%type
  , pCharId1         out stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type
  , pCharId2         out stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type
  , pCharId3         out stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type
  , pCharId4         out stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type
  , pCharId5         out stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type
  , pCharTyp1        out GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , pCharTyp2        out GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , pCharTyp3        out GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , pCharTyp4        out GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , pCharTyp5        out GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , pCharDesc1       out GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type
  , pCharDesc2       out GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type
  , pCharDesc3       out GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type
  , pCharDesc4       out GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type
  , pCharDesc5       out GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type
  , pRetestDate      out STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type
  , pQualityStatusId out STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type
  )
  is
  begin
    if pGoodId <> 0 then
      select gco.goo_number_of_decimal
           , gco_functions.GetCostPriceWithManagementMode(pGoodid)
           , pdt.pdt_stock_management
        into pGoodDigits
           , pGoodUnitPrice
           , pStkManagement
        from gco_good gco
           , gco_good_calc_data gcd
           , gco_product pdt
       where gco.gco_good_id = pGoodid
         and pdt.gco_good_id = gco.gco_good_id
         and gcd.gco_good_id = pdt.gco_good_id;

      GCO_functionS.GetListOfStkChar(pGoodId
                                   , pCharId1
                                   , pCharId2
                                   , pCharId3
                                   , pCharId4
                                   , pCharId5
                                   , pCharTyp1
                                   , pCharTyp2
                                   , pCharTyp3
                                   , pCharTyp4
                                   , pCharTyp5
                                   , pCharDesc1
                                   , pCharDesc2
                                   , pCharDesc3
                                   , pCharDesc4
                                   , pCharDesc5
                                    );

      if pStkManagement > 0 then
        GCO_functionS.GetGoodStockLocation(pGoodId, pStockId, pLocationId);
      else
        select nvl(max(STM_STOCK_ID), 0)
             , 0
          into pStockId
             , pLocationId
          from STM_STOCK
         where C_ACCESS_METHOD = 'DEFAULT';
      end if;

      GCO_functionS.GetGoodAltQty(pGoodId, pAltQty1, pAltQty2, pAltQty3, pAltFac1, pAltFac2, pAltFac3, pAltDesc1, pAltDesc2, pAltDesc3);
      pRetestDate       := GCO_I_LIB_CHARACTERIZATION.GetInitialRetestDelay(pGoodID, sysdate);
      pQualityStatusId  := GCO_I_LIB_QUALITY_STATUS.GetReceiptStatus(iGoodId => pGoodId);
    end if;
  end OnWorkGoodinput;

  procedure CtrlElementValue(
    pGoodId            STM_ELEMENT_NUMBER.GCO_GOOD_ID%type
  , pElemType          STM_ELEMENT_NUMBER.C_ELEMENT_TYPE%type
  , pElemValue         STM_ELEMENT_NUMBER.SEM_VALUE%type
  , pFound         out number
  , pFoundElemId   out STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , pFoundElemStat out STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type
  , pFoundElemGood out STM_ELEMENT_NUMBER.GCO_GOOD_ID%type
  )
  is
  begin
    if pElemType = '3' then   --  Type Pièce
      if upper(PCS.PC_CONFIG.GetConfig('STM_PIECE_SGL_NUMBERING_COMP') ) = 'TRUE' then   -- Numérotation Pièce unique par mandat activée
        select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
             , nvl(max(STM_ELEMENT_NUMBER_ID), 0)
             , max(C_ELE_NUM_STATUS)
             , nvl(max(GCO_GOOD_ID), 0)
          into pFound
             , pFoundElemId
             , pFoundElemStat
             , pFoundElemGood
          from STM_ELEMENT_NUMBER
         where SEM_VALUE = pElemValue
           and C_ELEMENT_TYPE = '02';
      else
        select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
             , nvl(max(STM_ELEMENT_NUMBER_ID), 0)
             , max(C_ELE_NUM_STATUS)
             , nvl(max(GCO_GOOD_ID), 0)
          into pFound
             , pFoundElemId
             , pFoundElemStat
             , pFoundElemGood
          from STM_ELEMENT_NUMBER
         where GCO_GOOD_ID = pGoodId
           and SEM_VALUE = pElemValue
           and C_ELEMENT_TYPE = '02';
      end if;
    elsif pElemType = '4' then   -- Type LOT
      if upper(PCS.PC_CONFIG.GetConfig('STM_SET_SGL_NUMBERING_GOOD') ) = 'TRUE' then   -- Numérotation LOT unique par bien activée
        select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
             , nvl(max(STM_ELEMENT_NUMBER_ID), 0)
             , max(C_ELE_NUM_STATUS)
             , nvl(max(GCO_GOOD_ID), 0)
          into pFound
             , pFoundElemId
             , pFoundElemStat
             , pFoundElemGood
          from STM_ELEMENT_NUMBER
         where GCO_GOOD_ID = pGoodId
           and SEM_VALUE = pElemValue
           and C_ELEMENT_TYPE = '01';
      else
        if upper(PCS.PC_CONFIG.GetConfig('STM_SET_SGL_NUMBERING_COMP') ) = 'TRUE' then   -- Numérotation LOT unique par mandat activée
          select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
               , nvl(max(STM_ELEMENT_NUMBER_ID), 0)
               , max(C_ELE_NUM_STATUS)
               , nvl(max(GCO_GOOD_ID), 0)
            into pFound
               , pFoundElemId
               , pFoundElemStat
               , pFoundElemGood
            from STM_ELEMENT_NUMBER
           where SEM_VALUE = pElemValue
             and C_ELEMENT_TYPE = '01';
        else   -- Numérotation LOT unique non activée
          select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
               , nvl(max(STM_ELEMENT_NUMBER_ID), 0)
               , max(C_ELE_NUM_STATUS)
               , nvl(max(GCO_GOOD_ID), 0)
            into pFound
               , pFoundElemId
               , pFoundElemStat
               , pFoundElemGood
            from STM_ELEMENT_NUMBER
           where GCO_GOOD_ID = pGoodId
             and SEM_VALUE = pElemValue
             and C_ELEMENT_TYPE = '01';
        end if;
      end if;
    elsif pElemType = '1' then   -- Type VERSION
      select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
           , nvl(max(STM_ELEMENT_NUMBER_ID), 0)
           , max(C_ELE_NUM_STATUS)
           , nvl(max(GCO_GOOD_ID), 0)
        into pFound
           , pFoundElemId
           , pFoundElemStat
           , pFoundElemGood
        from STM_ELEMENT_NUMBER
       where SEM_VALUE = pElemValue
         and C_ELEMENT_TYPE = '03';
    end if;
  end CtrlElementValue;

  procedure CtrlSetElementValue(
    pFound             number
  , pFoundElemId       STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , pFoundElemGood     STM_ELEMENT_NUMBER.GCO_GOOD_ID%type
  , pGoodId            STM_ELEMENT_NUMBER.GCO_GOOD_ID%type
  , pFoundElemStat     STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type
  , pAccept        out number
  )
  is
  begin
    if (pFound = 2) then
      pAccept  := 1;
    else
      if pFound = 1 then
        if pFoundElemGood = pGoodId then
          pAccept  := 1;
        else
          if upper(PCS.PC_CONFIG.GetConfig('STM_SET_SGL_NUMBERING_COMP') ) = 'FALSE' then   -- Numérotation LOT unique par mandat NON activée
            pAccept  := 1;
          else
            pAccept  := 0;
          end if;
        end if;
      end if;
    end if;
  end CtrlSetElementValue;

  procedure CtrlPieceElementValue(
    pFoundElemId        STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type   -- Elément à vérifier
  , pFoundinListPos out number   -- indique l'existence de l'élément dans les positions d'inventaire
  , pFoundinStkPos  out number   -- indique l'existence de l'élément dans les positions d'e stock
  , pFoundReserved  out number   -- indique l'existence de l'élément dans STM_ELEMENT_NUMBER avec le staus réservé
  , pAccept         out number
  )
  is
    vFoundId number;
  begin
    pFoundinListPos  := 0;   -- initialisation des flags de retour
    pFoundinStkPos   := 0;
    pFoundReserved   := 0;
    pAccept          := 1;

    select nvl(max(ILP.STM_INVENTORY_LIST_POS_ID), 0)
      into vFoundId
      from STM_INVENTORY_LIST_POS ILP
     where (   ILP.STM_ELEMENT_NUMBER_ID = pFoundElemId
            or ILP.STM_STM_ELEMENT_NUMBER_ID = pFoundElemId
            or ILP.STM2_STM_ELEMENT_NUMBER_ID = pFoundElemId)
       and ILP.ILP_IS_VALIDATED = 0;

    if vFoundId <> 0 then   -- L'élément à vérifier existe dans les positions d'inventaire
      pFoundinListPos  := 1;
      pAccept          := 0;
    else   -- L'élément à vérifier n'existe pas dans les positions d'inventaire
      select max(STM_ELEMENT_NUMBER_ID)
        into vFoundId
        from STM_ELEMENT_NUMBER
       where STM_ELEMENT_NUMBER_ID = pFoundElemId
         and C_ELE_NUM_STATUS = '03';

      if vFoundId is not null then   -- L'élément à vérifier existe dans STM_ELEMENT_NUMBER avec le status réservé
        pFoundReserved  := 1;
        pAccept         := 0;
      else
        select nvl(max(STM_STOCK_POSITION_ID), 0)   -- Recherce dans les positions de stock
          into vFoundId
          from STM_STOCK_POSITION
         where STM_ELEMENT_NUMBER_ID = pFoundElemId
            or STM_STM_ELEMENT_NUMBER_ID = pFoundElemId
            or STM2_STM_ELEMENT_NUMBER_ID = pFoundElemId;

        if vFoundId <> 0 then   -- L'élément à vérifier existe dans les positions de stock
          pFoundinStkPos  := 1;
          pAccept         := 0;
        end if;
      end if;
    end if;
  end CtrlPieceElementValue;

  function ExistSamePos(
    pTableName  varchar2
  , pGoodId     stm_inventory_list_work.GCO_GOOD_ID%type   -- Bien de la position
  , pStockId    stm_inventory_list_work.STM_STOCK_ID%type   -- Stock de la position
  , pLocationId stm_inventory_list_work.STM_LOCATION_ID%type   -- Emplacement de la position
  , pCharId1    stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type   -- Caractérisation 1 de la position
  , pCharId2    stm_inventory_list_work.GCO_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 2 de la position
  , pCharId3    stm_inventory_list_work.GCO2_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 3 de la position
  , pCharId4    stm_inventory_list_work.GCO3_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 4 de la position
  , pCharId5    stm_inventory_list_work.GCO4_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 5 de la position
  , pCharVal1   stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_1%type   -- Valeur Caractérisation 1 de la position
  , pCharVal2   stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_2%type   -- Valeur Caractérisation 2 de la position
  , pCharVal3   stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_3%type   -- Valeur Caractérisation 3 de la position
  , pCharVal4   stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_4%type   -- Valeur Caractérisation 4 de la position
  , pCharVal5   stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_5%type
  )   -- Valeur Caractérisation 5 de la position
    return number
  is
    vResult number;
  begin
    if pTableName = 'STM_INVENTORY_LIST_POS' then
      select nvl(max(stm_inventory_LIST_POS_ID), 0)
        into vResult
        from stm_inventory_LIST_POS
       where stm_inventory_LIST_POS.GCO_GOOD_ID = pGoodId
         and stm_inventory_LIST_POS.STM_LOCATION_ID = pLocationId
         and stm_inventory_LIST_POS.ILP_IS_VALIDATED = 0
         and (    (stm_inventory_LIST_POS.GCO_CHARACTERIZATION_ID = pCharId1)
              or (    stm_inventory_LIST_POS.GCO_CHARACTERIZATION_ID is null
                  and (nvl(pCharId1, 0) = 0) ) )
         and (    (stm_inventory_LIST_POS.GCO_GCO_CHARACTERIZATION_ID = pCharId2)
              or (    stm_inventory_LIST_POS.GCO_GCO_CHARACTERIZATION_ID is null
                  and (nvl(pCharId2, 0) = 0) )
             )
         and (    (stm_inventory_LIST_POS.GCO2_GCO_CHARACTERIZATION_ID = pCharId3)
              or (    stm_inventory_LIST_POS.GCO2_GCO_CHARACTERIZATION_ID is null
                  and (nvl(pCharId3, 0) = 0) )
             )
         and (    (stm_inventory_LIST_POS.GCO3_GCO_CHARACTERIZATION_ID = pCharId4)
              or (    stm_inventory_LIST_POS.GCO3_GCO_CHARACTERIZATION_ID is null
                  and (nvl(pCharId4, 0) = 0) )
             )
         and (    (stm_inventory_LIST_POS.GCO4_GCO_CHARACTERIZATION_ID = pCharId5)
              or (    stm_inventory_LIST_POS.GCO4_GCO_CHARACTERIZATION_ID is null
                  and (nvl(pCharId5, 0) = 0) )
             )
         and (    (stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_1 = pCharVal1)
              or (    stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_1 is null
                  and (pCharVal1 is null) )
             )
         and (    (stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_2 = pCharVal2)
              or (    stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_2 is null
                  and (pCharVal2 is null) )
             )
         and (    (stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_3 = pCharVal3)
              or (    stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_3 is null
                  and (pCharVal3 is null) )
             )
         and (    (stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_4 = pCharVal4)
              or (    stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_4 is null
                  and (pCharVal4 is null) )
             )
         and (    (stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_5 = pCharVal5)
              or (    stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_5 is null
                  and (pCharVal5 is null) )
             );
    elsif pTableName = 'STM_STOCK_POSITION' then
      select nvl(max(STM_STOCK_POSITION_ID), 0)
        into vResult
        from STM_STOCK_POSITION
       where STM_STOCK_POSITION.GCO_GOOD_ID = pGoodId
         and STM_STOCK_POSITION.STM_LOCATION_ID = pLocationId
         and (    (STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID = pCharId1)
              or (    STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID is null
                  and (nvl(pCharId1, 0) = 0) ) )
         and (    (STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID = pCharId2)
              or (    STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID is null
                  and (nvl(pCharId2, 0) = 0) ) )
         and (    (STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID = pCharId3)
              or (    STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID is null
                  and (nvl(pCharId3, 0) = 0) )
             )
         and (    (STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID = pCharId4)
              or (    STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID is null
                  and (nvl(pCharId4, 0) = 0) )
             )
         and (    (STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID = pCharId5)
              or (    STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID is null
                  and (nvl(pCharId5, 0) = 0) )
             )
         and (    (STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1 = pCharVal1)
              or (    STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1 is null
                  and (pCharVal1 is null) )
             )
         and (    (STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2 = pCharVal2)
              or (    STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2 is null
                  and (pCharVal2 is null) )
             )
         and (    (STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3 = pCharVal3)
              or (    STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3 is null
                  and (pCharVal3 is null) )
             )
         and (    (STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4 = pCharVal4)
              or (    STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4 is null
                  and (pCharVal4 is null) )
             )
         and (    (STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5 = pCharVal5)
              or (    STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5 is null
                  and (pCharVal5 is null) )
             );
    end if;

    return vResult;
  end ExistSamePos;

  function ExistVersionSetPce(
    pCharId1         stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type   -- Caractérisation 1 de la position
  , pCharId2         stm_inventory_list_work.GCO_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 2 de la position
  , pCharId3         stm_inventory_list_work.GCO2_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 3 de la position
  , pCharId4         stm_inventory_list_work.GCO3_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 4 de la position
  , pCharId5         stm_inventory_list_work.GCO4_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 5 de la position
  , pCharVal1        stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_1%type   -- Valeur Caractérisation 1 de la position
  , pCharVal2        stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_2%type   -- Valeur Caractérisation 2 de la position
  , pCharVal3        stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_3%type   -- Valeur Caractérisation 3 de la position
  , pCharVal4        stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_4%type   -- Valeur Caractérisation 4 de la position
  , pCharVal5        stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_5%type   -- Valeur Caractérisation 5 de la position
  , pCharTyp1        GCO_CHARACTERIZATION.C_CHARACT_TYPE%type   -- Type Caractérisation 1 de la position
  , pCharTyp2        GCO_CHARACTERIZATION.C_CHARACT_TYPE%type   -- Type Caractérisation 2 de la position
  , pCharTyp3        GCO_CHARACTERIZATION.C_CHARACT_TYPE%type   -- Type Caractérisation 3 de la position
  , pCharTyp4        GCO_CHARACTERIZATION.C_CHARACT_TYPE%type   -- Type Caractérisation 4 de la position
  , pCharTyp5        GCO_CHARACTERIZATION.C_CHARACT_TYPE%type   -- Type Caractérisation 5 de la position
  , pVerCharId   out stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type   -- Réceptionne la carctérisation de type version
  , pSetCharId   out stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type   -- Réceptionne la carctérisation de type Lot
  , pPceCharId   out stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type   -- Réceptionne la carctérisation de type Pce
  , pVerCharVal1 out stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_1%type   -- Réceptionne la valeur de la caractérisation de type version
  , pSetCharVal1 out stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_1%type   -- Réceptionne la valeur de la caractérisation de type Lot
  , pPceCharVal1 out stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_1%type   -- Réceptionne la valeur de la caractérisation de type Pce
  )
    return number
  is
  begin
    --  initialisation des variables de retour
    pVerCharId    := 0;
    pSetCharId    := 0;
    pPceCharId    := 0;
    pVerCharVal1  := '';
    pSetCharVal1  := '';
    pPceCharVal1  := '';

    if pCharTyp1 = '1' then
      pVerCharId    := pCharId1;
      pVerCharVal1  := pCharVal1;
    elsif pCharTyp2 = '1' then
      pVerCharId    := pCharId2;
      pVerCharVal1  := pCharVal2;
    elsif pCharTyp3 = '1' then
      pVerCharId    := pCharId3;
      pVerCharVal1  := pCharVal3;
    elsif pCharTyp4 = '1' then
      pVerCharId    := pCharId4;
      pVerCharVal1  := pCharVal4;
    elsif pCharTyp5 = '1' then
      pVerCharId    := pCharId5;
      pVerCharVal1  := pCharVal5;
    end if;

    if pCharTyp1 = '3' then
      pPceCharId    := pCharId1;
      pPceCharVal1  := pCharVal1;
    elsif pCharTyp2 = '3' then
      pPceCharId    := pCharId2;
      pPceCharVal1  := pCharVal2;
    elsif pCharTyp3 = '3' then
      pPceCharId    := pCharId3;
      pPceCharVal1  := pCharVal3;
    elsif pCharTyp4 = '3' then
      pPceCharId    := pCharId4;
      pPceCharVal1  := pCharVal4;
    elsif pCharTyp5 = '3' then
      pPceCharId    := pCharId5;
      pPceCharVal1  := pCharVal5;
    end if;

    if pCharTyp1 = '4' then
      pSetCharId    := pCharId1;
      pSetCharVal1  := pCharVal1;
    elsif pCharTyp2 = '4' then
      pSetCharId    := pCharId2;
      pSetCharVal1  := pCharVal2;
    elsif pCharTyp3 = '4' then
      pSetCharId    := pCharId3;
      pSetCharVal1  := pCharVal3;
    elsif pCharTyp4 = '4' then
      pSetCharId    := pCharId4;
      pSetCharVal1  := pCharVal4;
    elsif pCharTyp5 = '4' then
      pSetCharId    := pCharId5;
      pSetCharVal1  := pCharVal5;
    end if;

    if    (pVerCharId <> 0)
       or (pSetCharId <> 0)
       or (pPceCharId <> 0) then
      return 1;
    else
      return 0;
    end if;
  end ExistVersionSetPce;

  procedure ValidateModification(
    pListWorkId           stm_inventory_list_work.stm_inventory_LIST_POS_ID%type   -- Liste de travail courant
  , pSessionId            stm_inventory_list_work.ILW_SESSION_ID%type   -- Session courante
  , pGoodId               stm_inventory_list_work.GCO_GOOD_ID%type   -- Bien de la position
  , pCharId1              stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type   -- Caractérisation 1 de la position
  , pCharId2              stm_inventory_list_work.GCO_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 2 de la position
  , pCharId3              stm_inventory_list_work.GCO2_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 3 de la position
  , pCharId4              stm_inventory_list_work.GCO3_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 4 de la position
  , pCharId5              stm_inventory_list_work.GCO4_GCO_CHARACTERIZATION_ID%type   -- Caractérisation 5 de la position
  , pCharVal1             stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_1%type   -- Valeur Caractérisation 1 de la position
  , pCharVal2             stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_2%type   -- Valeur Caractérisation 2 de la position
  , pCharVal3             stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_3%type   -- Valeur Caractérisation 3 de la position
  , pCharVal4             stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_4%type   -- Valeur Caractérisation 4 de la position
  , pCharVal5             stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_5%type   -- Valeur Caractérisation 5 de la position
  , pCharTyp1             GCO_CHARACTERIZATION.C_CHARACT_TYPE%type   -- Type Caractérisation 1 de la position
  , pCharTyp2             GCO_CHARACTERIZATION.C_CHARACT_TYPE%type   -- Type Caractérisation 2 de la position
  , pCharTyp3             GCO_CHARACTERIZATION.C_CHARACT_TYPE%type   -- Type Caractérisation 3 de la position
  , pCharTyp4             GCO_CHARACTERIZATION.C_CHARACT_TYPE%type   -- Type Caractérisation 4 de la position
  , pCharTyp5             GCO_CHARACTERIZATION.C_CHARACT_TYPE%type   -- Type Caractérisation 5 de la position
  , pStockId              stm_inventory_list_work.STM_STOCK_ID%type   -- Stock de la position
  , pLocationId           stm_inventory_list_work.STM_LOCATION_ID%type   -- Emplacement de la position
  , pQty                  stm_inventory_list_work.ILW_inPUT_QUANTITY%type   -- Qté de la position
  , pValue                stm_inventory_list_work.ILW_inPUT_VALUE%type   -- Valeur de la position
  , pFoundSetElemId   out STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , pFoundVerElemId   out STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , pFoundPceElemId   out STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , pFoundSetElemStat out STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type
  , pFoundVerElemStat out STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type
  , pFoundPceElemStat out STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type
  )
  is
    vVerCharId             GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    vSetCharId             GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    vPceCharId             GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    vVerCharVal            STM_ELEMENT_NUMBER.SEM_VALUE%type;
    vSetCharVal            STM_ELEMENT_NUMBER.SEM_VALUE%type;
    vPceCharVal            STM_ELEMENT_NUMBER.SEM_VALUE%type;
    vFoundElemGood         STM_ELEMENT_NUMBER.GCO_GOOD_ID%type;
    vFound                 number;
    vPceFoundinListPos     number;
    vPceFoundinStkPos      number;
    vPceFoundReserved      number;
    vAccept                number;
    LangId                 number(12);   --Réceptionne la langue du user ou 'Anglais'
    vinv_description       stm_inventory_task.inV_DESCRIPTION%type;
    vIli_description       stm_inventory_list.ili_description%type;
    vinventory_list_pos_id stm_inventory_list_pos.stm_inventory_list_pos_id%type;
  begin
    select decode(PCS.PC_I_LIB_SESSION.GetUserLangId, null, PC_LANG_ID, PCS.PC_I_LIB_SESSION.GetUserLangId)
      into LangId
      from PCS.PC_LANG
     where LANID = 'EN';

    -- initialisation des variables
    vVerCharId              := 0;
    vSetCharId              := 0;
    vPceCharId              := 0;
    vFound                  := 0;
    vFoundElemGood          := 0;
    pFoundSetElemId         := 0;
    pFoundVerElemId         := 0;
    pFoundPceElemId         := 0;
    pFoundSetElemStat       := '';
    pFoundVerElemStat       := '';
    pFoundPceElemStat       := '';

    -- Bien géré avec caractérisation de type pce et qté <> 1
    if     (    (pCharTyp1 = '3')
            or (pCharTyp2 = '3')
            or (pCharTyp3 = '3')
            or (pCharTyp4 = '3')
            or (pCharTyp5 = '3') )
       and (pQty <> 1) then
      RAISE_APPLICATION_ERROR(-20901, PCS.PC_functionS.TranslateWord2('INV_QTY_MUST_BE_1', LangId) );
    end if;

    -- Vérification du format des valeurs de charactérisation.
    if not pCheckCharactFormat(pCharId1, pCharVal1, pCharId2, pCharVal2, pCharId3, pCharVal3, pCharId4, pCharVal4, pCharId5, pCharVal5) then
      raise_application_error(-20907, PCS.PC_FUNCTIONS.TranslateWord2('INV_BAD_CHAR_FORMAT', LangId) );
    end if;

    if     (cfgUseUnitPrice = '1')
       and (pValue < 0) then
      raise_application_error(-20908, PCS.PC_FUNCTIONS.TranslateWord('Prix d''inventaire négatif', LangId) );
    end if;

    -- Vérifier l'existence d'une position d'inventaire similaire
    vinventory_list_pos_id  :=
      stm_inventory.ExistSamePos('STM_INVENTORY_LIST_POS'
                               , pGoodId
                               , pStockId
                               , pLocationId
                               , pCharId1
                               , pCharId2
                               , pCharId3
                               , pCharId4
                               , pCharId5
                               , pCharVal1
                               , pCharVal2
                               , pCharVal3
                               , pCharVal4
                               , pCharVal5
                                );

    if vinventory_list_pos_id <> 0 then
      select inv.inv_description
           , ili.ili_description
        into vinv_description
           , vIli_description
        from stm_inventory_list_pos ilp
           , stm_inventory_list ili
           , stm_inventory_task inv
       where ilp.stm_inventory_list_pos_id = vinventory_list_pos_Id
         and ilp.stm_inventory_list_id = ili.stm_inventory_list_id
         and ilp.stm_inventory_task_id = inv.stm_inventory_task_id;

      RAISE_APPLICATION_ERROR(-20902
                            , PCS.PC_functionS.TranslateWord2('INV_SAME_POS_EXIST_IN_INV', LangId) ||
                              ' ' ||
                              pcs.pc_functions.translateWord2('Inventaire', LangId) ||
                              ' : ' ||
                              vinv_description ||
                              ' ' ||
                              pcs.pc_functions.translateWord2('Extraction', LangId) ||
                              ' : ' ||
                              vIli_description
                             );
    end if;

    -- Vérifier les valeurs de caractérisations pour les type LOT, PCE,Version
    if stm_inventory.ExistVersionSetPce(pCharId1
                                      , pCharId2
                                      , pCharId3
                                      , pCharId4
                                      , pCharId5
                                      , pCharVal1
                                      , pCharVal2
                                      , pCharVal3
                                      , pCharVal4
                                      , pCharVal5
                                      , pCharTyp1
                                      , pCharTyp2
                                      , pCharTyp3
                                      , pCharTyp4
                                      , pCharTyp5
                                      , vVerCharId
                                      , vSetCharId
                                      , vPceCharId
                                      , vVerCharVal
                                      , vSetCharVal
                                      , vPceCharVal
                                       ) = 1 then
      if vPceCharId <> 0 then
        stm_inventory.CtrlElementValue(pGoodId, '3', vPceCharVal, vFound, pFoundPceElemId, pFoundPceElemStat, vFoundElemGood);

        if vFound = 1 then
          stm_inventory.CtrlPieceElementValue(pFoundPceElemId, vPceFoundinListPos, vPceFoundinStkPos, vPceFoundReserved, vAccept);

          if vPceFoundinListPos = 1 then
            RAISE_APPLICATION_ERROR(-20903, PCS.PC_functionS.TranslateWord2('INV_PCE_ELEM_EXIST_IN_INV', LangId) );
          else
            if vPceFoundinStkPos = 1 then
              RAISE_APPLICATION_ERROR(-20904, PCS.PC_functionS.TranslateWord2('INV_PCE_ELEM_EXIST_IN_STK', LangId) );
            else
              if vPceFoundReserved = 1 then
                RAISE_APPLICATION_ERROR(-20906, PCS.PC_functionS.TranslateWord2('INV_PCE_ELEM_EXIST_RESERVED', LangId) );
              end if;
            end if;
          end if;
        else
          --stm_inventory.CreateElementValue(pGoodId,vPceCharVal,'02', '03',pFoundPceElemId);
          null;
        end if;
      end if;

      if vSetCharId <> 0 then
        stm_inventory.CtrlElementValue(pGoodId, '4', vSetCharVal, vFound, pFoundSetElemId, pFoundSetElemStat, vFoundElemGood);

        if vFound = 1 then
          stm_inventory.CtrlSetElementValue(vFound, pFoundSetElemId, vFoundElemGood, pGoodId, pFoundSetElemStat, vAccept);

          if vAccept = 0 then
            RAISE_APPLICATION_ERROR(-20906, PCS.PC_functionS.TranslateWord2('INV_SET_ELEM_EXIST', LangId) );
          end if;
        else
          --stm_inventory.CreateElementValue(pGoodId,vSetCharVal,'01','03',pFoundSetElemId);
          null;
        end if;
      end if;

      if vVerCharId <> 0 then
        stm_inventory.CtrlElementValue(pGoodId, '1', vVerCharVal, vFound, pFoundVerElemId, pFoundVerElemStat, vFoundElemGood);

        if vFound = 0 then
          --stm_inventory.CreateElementValue(pGoodId,vVerCharVal,'03','03',pFoundVerElemId);
          null;
        end if;
      end if;
    end if;
  end ValidateModification;

  procedure UpdateJobAfterinsert(
    pJobId      stm_inventory_JOB.stm_inventory_JOB_ID%type   -- Journal de travail
  , pTaskId     stm_inventory_TASK.stm_inventory_TASK_ID%type   -- inventaire
  , pListId     stm_inventory_LIST.stm_inventory_LIST_ID%type   -- Liste
  , pListWorkId stm_inventory_list_work.stm_inventory_LIST_POS_ID%type
  , pSessionId  stm_inventory_list_work.ILW_SESSION_ID%type
  )
  is
    vc_inventory_mode          stm_inventory_task.c_inventory_mode%type;
    vStm_inventory_list_pos_id stm_inventory_list_pos.stm_inventory_list_pos_id%type;
  begin
    select inv.c_inventory_mode
         , ilw.stm_inventory_list_pos_id
      into vc_inventory_mode
         , vStm_inventory_list_pos_id
      from stm_inventory_task inv
         , stm_inventory_list_work ilw
     where inv.stm_inventory_task_id = pTaskId
       and inv.stm_inventory_task_id = ilw.stm_inventory_task_id
       and ilw.stm_inventory_list_pos_id = pListWorkId
       and ilw.ilw_session_id = pSessionId;

    if vC_inventory_mode = '2' then
      delete from stm_inventory_job_detail ijd
            where ijd.stm_inventory_list_pos_id = vStm_inventory_list_pos_id;
    end if;

    -- insertion d'un mouvement dans le journal de saisie
    insert into stm_inventory_JOB_DETAIL
                (stm_inventory_JOB_DETAIL_ID
               , stm_inventory_JOB_ID
               , stm_inventory_LIST_ID
               , GCO_GOOD_ID
               , STM_LOCATION_ID
               , STM_STOCK_ID
               , GCO_CHARACTERIZATION_ID
               , GCO_GCO_CHARACTERIZATION_ID
               , GCO2_GCO_CHARACTERIZATION_ID
               , GCO3_GCO_CHARACTERIZATION_ID
               , GCO4_GCO_CHARACTERIZATION_ID
               , IJD_QUANTITY
               , IJD_VALUE
               , IJD_UNIT_PRICE
               , IJD_WORDING
               , IJD_CHARACTERIZATION_VALUE_1
               , IJD_CHARACTERIZATION_VALUE_2
               , IJD_CHARACTERIZATION_VALUE_3
               , IJD_CHARACTERIZATION_VALUE_4
               , IJD_CHARACTERIZATION_VALUE_5
               , IJD_LinE_VALIDATED
               , IJD_LinE_in_USE
               , IJD_inPUT_USER_NAME
               , A_DATECRE
               , A_IDCRE
               , stm_inventory_TASK_ID
               , stm_inventory_LIST_POS_ID
               , IJD_ALTERNATIV_QTY_1
               , IJD_ALTERNATIV_QTY_2
               , IJD_ALTERNATIV_QTY_3
               , IJD_FREE_TEXT1
               , IJD_FREE_TEXT2
               , IJD_FREE_TEXT3
               , IJD_FREE_TEXT4
               , IJD_FREE_TEXT5
               , IJD_FREE_NUMBER1
               , IJD_FREE_NUMBER2
               , IJD_FREE_NUMBER3
               , IJD_FREE_NUMBER4
               , IJD_FREE_NUMBER5
               , IJD_FREE_DATE1
               , IJD_FREE_DATE2
               , IJD_FREE_DATE3
               , IJD_FREE_DATE4
               , IJD_FREE_DATE5
               , IJD_RETEST_DATE
               , GCO_QUALITY_STATUS_ID
                )
      select init_id_seq.nextval
           , pJobId
           , pListId
           , GCO_GOOD_ID
           , STM_LOCATION_ID
           , STM_STOCK_ID
           , GCO_CHARACTERIZATION_ID
           , GCO_GCO_CHARACTERIZATION_ID
           , GCO2_GCO_CHARACTERIZATION_ID
           , GCO3_GCO_CHARACTERIZATION_ID
           , GCO4_GCO_CHARACTERIZATION_ID
           , ILW_inPUT_QUANTITY
           , ILW_inPUT_VALUE
           , ILW_inPUT_UNIT_PRICE
           , ILP_COMMENT
           , ILP_CHARACTERIZATION_VALUE_1
           , ILP_CHARACTERIZATION_VALUE_2
           , ILP_CHARACTERIZATION_VALUE_3
           , ILP_CHARACTERIZATION_VALUE_4
           , ILP_CHARACTERIZATION_VALUE_5
           , 0
           , 0
           , PCS.PC_I_LIB_SESSION.GetUserini
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserini
           , pTaskId
           , stm_inventory_LIST_POS_ID
           , ILW_inV_ALTERNATIV_QTY_1
           , ILW_inV_ALTERNATIV_QTY_2
           , ILW_inV_ALTERNATIV_QTY_3
           , ILW_FREE_TEXT1
           , ILW_FREE_TEXT2
           , ILW_FREE_TEXT3
           , ILW_FREE_TEXT4
           , ILW_FREE_TEXT5
           , ILW_FREE_NUMBER1
           , ILW_FREE_NUMBER2
           , ILW_FREE_NUMBER3
           , ILW_FREE_NUMBER4
           , ILW_FREE_NUMBER5
           , ILW_FREE_DATE1
           , ILW_FREE_DATE2
           , ILW_FREE_DATE3
           , ILW_FREE_DATE4
           , ILW_FREE_DATE5
           , ILW_RETEST_DATE
           , GCO_QUALITY_STATUS_ID   --status qualité
        from stm_inventory_list_work
       where stm_inventory_LIST_POS_ID = pListWorkId
         and ILW_SESSION_ID = pSessionId;
  end UpdateJobAfterinsert;

  procedure CreateNewWorkPosition(
    pWorkId          out stm_inventory_list_work.stm_inventory_LIST_POS_ID%type
  , pSessionId           stm_inventory_list_work.ILW_SESSION_ID%type
  , pJobId               stm_inventory_JOB.stm_inventory_JOB_ID%type
  , pListId              stm_inventory_list_work.stm_inventory_LIST_ID%type
  , pTaskId              stm_inventory_list_work.stm_inventory_TASK_ID%type
  , pPeriodId            stm_inventory_list_work.STM_PERIOD_ID%type
  , pinvType             stm_inventory_list_work.C_INVENTORY_TYPE%type
  , pinvDate             stm_inventory_list_work.ILP_INVENTORY_DATE%type
  , pGoodId              stm_inventory_list_work.GCO_GOOD_ID%type
  , pStockId             stm_inventory_list_work.STM_STOCK_ID%type
  , pLocationId          stm_inventory_list_work.STM_LOCATION_ID%type
  , pElementId1          stm_inventory_list_work.STM_ELEMENT_NUMBER_ID%type
  , pElementId2          stm_inventory_list_work.STM_STM_ELEMENT_NUMBER_ID%type
  , pElementId3          stm_inventory_list_work.STM2_STM_ELEMENT_NUMBER_ID%type
  , pCharId1             stm_inventory_list_work.GCO_CHARACTERIZATION_ID%type
  , pCharId2             stm_inventory_list_work.GCO_GCO_CHARACTERIZATION_ID%type
  , pCharId3             stm_inventory_list_work.GCO2_GCO_CHARACTERIZATION_ID%type
  , pCharId4             stm_inventory_list_work.GCO3_GCO_CHARACTERIZATION_ID%type
  , pCharId5             stm_inventory_list_work.GCO4_GCO_CHARACTERIZATION_ID%type
  , pStockPosId          stm_inventory_list_work.STM_STOCK_POSITION_ID%type
  , pinvValue            stm_inventory_list_work.ILP_INVENTORY_VALUE%type
  , pinvQty              stm_inventory_list_work.ILP_INVENTORY_QUANTITY%type
  , pinvUnitPrice        stm_inventory_list_work.ILP_INVENTORY_UNIT_PRICE%type
  , pinvAltQty1          stm_inventory_list_work.ILP_inV_ALTERNATIV_QTY_1%type
  , pinvAltQty2          stm_inventory_list_work.ILP_inV_ALTERNATIV_QTY_2%type
  , pinvAltQty3          stm_inventory_list_work.ILP_inV_ALTERNATIV_QTY_3%type
  , pComment             stm_inventory_list_work.ILP_COMMENT%type
  , pEleStatus1          stm_inventory_list_work.ILP_C_ELE_NUM_STATUS_1%type
  , pEleStatus2          stm_inventory_list_work.ILP_C_ELE_NUM_STATUS_2%type
  , pEleStatus3          stm_inventory_list_work.ILP_C_ELE_NUM_STATUS_3%type
  , pCharVal1            stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_1%type
  , pCharVal2            stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_2%type
  , pCharVal3            stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_3%type
  , pCharVal4            stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_4%type
  , pCharVal5            stm_inventory_list_work.ILP_CHARACTERIZATION_VALUE_5%type
  , pFreeText1           stm_inventory_list_work.ILW_FREE_TEXT1%type
  , pFreeText2           stm_inventory_list_work.ILW_FREE_TEXT2%type
  , pFreeText3           stm_inventory_list_work.ILW_FREE_TEXT3%type
  , pFreeText4           stm_inventory_list_work.ILW_FREE_TEXT4%type
  , pFreeText5           stm_inventory_list_work.ILW_FREE_TEXT5%type
  , pFreeNum1            stm_inventory_list_work.ILW_FREE_NUMBER1%type
  , pFreeNum2            stm_inventory_list_work.ILW_FREE_NUMBER2%type
  , pFreeNum3            stm_inventory_list_work.ILW_FREE_NUMBER3%type
  , pFreeNum4            stm_inventory_list_work.ILW_FREE_NUMBER4%type
  , pFreeNum5            stm_inventory_list_work.ILW_FREE_NUMBER5%type
  , pFreeDate1           stm_inventory_list_work.ILW_FREE_DATE1%type
  , pFreeDate2           stm_inventory_list_work.ILW_FREE_DATE2%type
  , pFreeDate3           stm_inventory_list_work.ILW_FREE_DATE3%type
  , pFreeDate4           stm_inventory_list_work.ILW_FREE_DATE4%type
  , pFreeDate5           stm_inventory_list_work.ILW_FREE_DATE5%type
  , pinvRetestDate       stm_inventory_list_work.ILW_RETEST_DATE%type
  , pQualityStatusId     stm_inventory_list_work.GCO_QUALITY_STATUS_ID%type
  )
  is
    cursor crStockPos(pStockPosId STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type)
    is
      select STM_STOCK_POSITION.SPO_STOCK_QUANTITY * GCO_functionS.GETCOSTPRICEWITHMANAGEMENTMODE(STM_STOCK_POSITION.GCO_GOOD_ID) SYSTEMVALUE
           , STM_STOCK_POSITION.SPO_STOCK_QUANTITY
           , GCO_functionS.GETCOSTPRICEWITHMANAGEMENTMODE(STM_STOCK_POSITION.GCO_GOOD_ID) UNITPRICE
           , STM_STOCK_POSITION.SPO_ALTERNATIV_QUANTITY_1
           , STM_STOCK_POSITION.SPO_ALTERNATIV_QUANTITY_2
           , STM_STOCK_POSITION.SPO_ALTERNATIV_QUANTITY_3
           , STM_STOCK_POSITION.SPO_PROVISORY_OUTPUT
           , STM_STOCK_POSITION.SPO_PROVISORY_inPUT
           , STM_STOCK_POSITION.SPO_ASSIGN_QUANTITY
        from STM_STOCK_POSITION
       where STM_STOCK_POSITION_ID = pStockPosId;

    STOCKPOSITION  crSTOCKPOS%rowtype;
    vSysVal        number;
    vSysQty        number;
    vSysUnitPrice  number;
    vSysAlt1       number;
    vSysAlt2       number;
    vSysAlt3       number;
    vSysProvOutput number;
    vSysprovinput  number;
    vSysAssign     number;
  begin
    vSysVal         := 0;
    vSysQty         := 0;
    vSysUnitPrice   := 0;
    vSysAlt1        := 0;
    vSysAlt2        := 0;
    vSysAlt3        := 0;
    vSysProvOutput  := 0;
    vSysprovinput   := 0;
    vSysAssign      := 0;

    open crStockPos(pStockPosId);

    fetch crStockPos
     into STOCKPOSITION;

    if crStockPos%found then
      vSysVal         := STOCKPOSITION.SYSTEMVALUE;
      vSysQty         := STOCKPOSITION.SPO_STOCK_QUANTITY;
      vSysUnitPrice   := STOCKPOSITION.UNITPRICE;
      vSysAlt1        := STOCKPOSITION.SPO_ALTERNATIV_QUANTITY_1;
      vSysAlt2        := STOCKPOSITION.SPO_ALTERNATIV_QUANTITY_2;
      vSysAlt3        := STOCKPOSITION.SPO_ALTERNATIV_QUANTITY_3;
      vSysProvOutput  := STOCKPOSITION.SPO_PROVISORY_OUTPUT;
      vSysprovinput   := STOCKPOSITION.SPO_PROVISORY_inPUT;
      vSysAssign      := STOCKPOSITION.SPO_ASSIGN_QUANTITY;
    end if;

    close crStockPos;

    select init_id_seq.nextval
      into pWorkId
      from dual;

    insert into STM_INVENTORY_LIST_POS
                (STM_INVENTORY_LIST_POS_ID
               , STM_INVENTORY_LIST_ID
               , STM_LOCATION_ID
               , GCO_GOOD_ID
               , STM_STOCK_ID
               , STM_ELEMENT_NUMBER_ID
               , STM_STM_ELEMENT_NUMBER_ID
               , STM2_STM_ELEMENT_NUMBER_ID
               , GCO_CHARACTERIZATION_ID
               , GCO_GCO_CHARACTERIZATION_ID
               , GCO2_GCO_CHARACTERIZATION_ID
               , GCO3_GCO_CHARACTERIZATION_ID
               , GCO4_GCO_CHARACTERIZATION_ID
               , C_INVENTORY_TYPE
               , STM_PERIOD_ID
               , STM_STOCK_POSITION_ID
               , ILP_IS_ORIGINAL_POS
               , ILP_IS_VALIDATED
               , ILP_SYSTEM_VALUE
               , ILP_SYSTEM_QUANTITY
               , ILP_SYSTEM_UNIT_PRICE
               , ILP_INVENTORY_VALUE
               , ILP_INVENTORY_QUANTITY
               , ILP_INVENTORY_UNIT_PRICE
               , ILP_INVENTORY_DATE
               , ILP_SYS_ALTERNATIV_QTY_1
               , ILP_SYS_ALTERNATIV_QTY_2
               , ILP_SYS_ALTERNATIV_QTY_3
               , ILP_PROVISORY_OUTPUT
               , ILP_PROVISORY_INPUT
               , ILP_INV_ALTERNATIV_QTY_1
               , ILP_INV_ALTERNATIV_QTY_2
               , ILP_INV_ALTERNATIV_QTY_3
               , ILP_COMMENT
               , ILP_C_ELE_NUM_STATUS_1
               , ILP_C_ELE_NUM_STATUS_2
               , ILP_C_ELE_NUM_STATUS_3
               , ILP_CHARACTERIZATION_VALUE_1
               , ILP_CHARACTERIZATION_VALUE_2
               , ILP_CHARACTERIZATION_VALUE_3
               , ILP_CHARACTERIZATION_VALUE_4
               , ILP_CHARACTERIZATION_VALUE_5
               , ILP_ASSIGN_QUANTITY
               , A_DATECRE
               , A_IDCRE
               , STM_INVENTORY_TASK_ID
               , ILP_RETEST_DATE
               , GCO_QUALITY_STATUS_ID   -- status qualité
                )
      select pWorkId
           , pListId
           , pLocationId
           , pGoodId
           , pStockId
           , decode(pElementId1, 0, null, pElementId1)
           , decode(pElementId2, 0, null, pElementId2)
           , decode(pElementId3, 0, null, pElementId3)
           , decode(pCharId1, 0, null, pCharId1)
           , decode(pCharId2, 0, null, pCharId2)
           , decode(pCharId3, 0, null, pCharId3)
           , decode(pCharId4, 0, null, pCharId4)
           , decode(pCharId5, 0, null, pCharId5)
           , pinvType
           , pPeriodId
           , decode(pStockPosId, 0, null, pStockPosId)
           , decode(pStockPosId, 0, 0, 1)
           , 0
           , vSysVal
           , vSysQty
           , vSysUnitPrice
           , decode(INV.C_INVENTORY_MODE, '1', 0, '2', vSysVal)   -- ILP_INVENTORY_VALUE
           , decode(INV.C_INVENTORY_MODE, '1', 0, '2', vSysQty)   -- ILP_INVENTORY_QUANTITY
           , decode(INV.C_INVENTORY_MODE, '1', 0, '2', vSysUnitPrice)   -- ILP_INVENTORY_UNIT_PRICE
           , pinvDate
           , vSysAlt1
           , vSysAlt2
           , vSysAlt3
           , vSysProvOutput
           , vSysProvinput
           , decode(INV.C_INVENTORY_MODE, '1', 0, '2', vSysAlt1)   -- ILP_INV_ALTERNATIV_QUANTITY_1
           , decode(INV.C_INVENTORY_MODE, '1', 0, '2', vSysAlt2)   -- ILP_INV_ALTERNATIV_QUANTITY_2
           , decode(INV.C_INVENTORY_MODE, '1', 0, '2', vSysAlt3)   -- ILP_INV_ALTERNATIV_QUANTITY_3
           , pComment
           , pEleStatus1
           , pEleStatus2
           , pEleStatus3
           , pCharVal1
           , pCharVal2
           , pCharVal3
           , pCharVal4
           , pCharVal5
           , vSysAssign
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserini
           , pTaskId
           , pinvRetestDate
           , pQualityStatusId
        from STM_INVENTORY_TASK INV
       where STM_INVENTORY_TASK_ID = pTaskId;

    insert into stm_inventory_list_work
                (stm_inventory_LIST_POS_ID   -- Positions de l'inventaire
               , stm_inventory_TASK_ID   -- inventaire
               , stm_inventory_LIST_ID   -- Liste d'inventaire
               , STM_STOCK_POSITION_ID   -- ID positions de stock
               , STM_STOCK_ID   -- ID stock logique
               , STM_LOCATION_ID   -- ID emplacement de stock
               , STM_PERIOD_ID   -- ID période
               , STM_ELEMENT_NUMBER_ID   -- ID numéro de pièce lot ou version
               , STM_STM_ELEMENT_NUMBER_ID   -- STM_ID numéro de pièce lot ou version
               , STM2_STM_ELEMENT_NUMBER_ID   -- STM2_ID numéro de pièce lot ou version
               , ILP_C_ELE_NUM_STATUS_1   -- Statut de la caractérisation 1
               , ILP_C_ELE_NUM_STATUS_2   -- Statut de la caractérisation 2
               , ILP_C_ELE_NUM_STATUS_3   -- Statut de la caractérisation 3
               , C_INVENTORY_TYPE   -- Type d'inventaire
               , C_INVENTORY_ERROR_STATUS   -- Statut de la position
               , GCO_GOOD_ID   -- ID bien
               , GCO_CHARACTERIZATION_ID   -- ID caractérisation
               , GCO_GCO_CHARACTERIZATION_ID   -- GCO_ID charactérisation
               , GCO2_GCO_CHARACTERIZATION_ID   -- GCO2_ID charactérisation
               , GCO3_GCO_CHARACTERIZATION_ID   -- GCO3_ID charactérisation
               , GCO4_GCO_CHARACTERIZATION_ID   -- GCO4_ID charactérisation
               , ILP_CHARACTERIZATION_VALUE_1   -- Valeur de caractérisation 1
               , ILP_CHARACTERIZATION_VALUE_2   -- Valeur de caractérisation 2
               , ILP_CHARACTERIZATION_VALUE_3   -- Valeur de caractérisation 3
               , ILP_CHARACTERIZATION_VALUE_4   -- Valeur de caractérisation 4
               , ILP_CHARACTERIZATION_VALUE_5   -- Valeur de caractérisation 5
               , ILP_SYS_ALTERNATIV_QTY_1   -- Quantité alternative 1 (système)
               , ILP_SYS_ALTERNATIV_QTY_2   -- Quantité alternative 2 (système)
               , ILP_SYS_ALTERNATIV_QTY_3   -- Quantité alternative 3 (système)
               , ILP_SYSTEM_VALUE   -- Valeur système
               , ILP_SYSTEM_UNIT_PRICE   -- Prix unitaire système
               , ILP_SYSTEM_QUANTITY   -- Quantité système
               , ILP_PROVISORY_inPUT   -- Quantité entrée provisoire
               , ILP_PROVISORY_OUTPUT   -- Quantité sortie provisoire
               , ILP_inV_ALTERNATIV_QTY_1   -- Quantité alternative 1 (inventoriée)
               , ILP_inV_ALTERNATIV_QTY_2   -- Quantité alternative 2 (inventoriée)
               , ILP_inV_ALTERNATIV_QTY_3   -- Quantité alternative 3 (inventoriée)
               , ILP_INVENTORY_VALUE   -- Valeur inventoriée
               , ILP_INVENTORY_UNIT_PRICE   -- Prix unitaire inventorié
               , ILP_INVENTORY_QUANTITY   -- Quantité inventoriée
               , ILP_IS_VALIDATED   -- Position traitée
               , ILP_IS_ORIGinAL_POS   -- Position extraite
               , ILP_INVENTORY_DATE   -- Date de l'inventaire
               , ILP_COMMENT   -- Commentaire
               , ILP_ASSIGN_QUANTITY   -- Quantité attribuée sur stock
               , ILW_SESSION_ID   -- Identifiant de session
               , ILW_inV_ALTERNATIV_QTY_3   -- Quantité alternative 3 saisie
               , ILW_inV_ALTERNATIV_QTY_2   -- Quantité alternative 2 saisie
               , ILW_inV_ALTERNATIV_QTY_1   -- Quantité alternative 1 saisie
               , ILW_inPUT_VALUE   -- Prix total saisie
               , ILW_inPUT_UNIT_PRICE   -- Prix unitaire saisie
               , ILW_inPUT_QUANTITY   -- Quantité saisie
               , A_IDCRE   -- ID de création
               , A_DATECRE   -- Date de création
               , ILW_FREE_DATE1
               , ILW_FREE_DATE2
               , ILW_FREE_DATE3
               , ILW_FREE_DATE4
               , ILW_FREE_DATE5
               , ILW_FREE_TEXT1
               , ILW_FREE_TEXT2
               , ILW_FREE_TEXT3
               , ILW_FREE_TEXT4
               , ILW_FREE_TEXT5
               , ILW_FREE_NUMBER1
               , ILW_FREE_NUMBER2
               , ILW_FREE_NUMBER3
               , ILW_FREE_NUMBER4
               , ILW_FREE_NUMBER5
               , ILW_RETEST_DATE   -- date réanalyse
               , GCO_QUALITY_STATUS_ID   --status qualité
                )
      select stm_inventory_LIST_POS_ID   -- Positions de l'inventaire
           , stm_inventory_TASK_ID   -- inventaire
           , stm_inventory_LIST_ID   -- Liste d'inventaire
           , STM_STOCK_POSITION_ID   -- ID positions de stock
           , STM_STOCK_ID   -- ID stock logique
           , STM_LOCATION_ID   -- ID emplacement de stock
           , STM_PERIOD_ID   -- ID période
           , STM_ELEMENT_NUMBER_ID   -- ID numéro de pièce lot ou version
           , STM_STM_ELEMENT_NUMBER_ID   -- STM_ID numéro de pièce lot ou version
           , STM2_STM_ELEMENT_NUMBER_ID   -- STM2_ID numéro de pièce lot ou version
           , ILP_C_ELE_NUM_STATUS_1   -- Statut de la caractérisation 1
           , ILP_C_ELE_NUM_STATUS_2   -- Statut de la caractérisation 2
           , ILP_C_ELE_NUM_STATUS_3   -- Statut de la caractérisation 3
           , C_INVENTORY_TYPE   -- Type d'inventaire
           , C_INVENTORY_ERROR_STATUS   -- Statut de la position
           , GCO_GOOD_ID   -- ID bien
           , GCO_CHARACTERIZATION_ID   -- ID caractérisation
           , GCO_GCO_CHARACTERIZATION_ID   -- GCO_ID charactérisation
           , GCO2_GCO_CHARACTERIZATION_ID   -- GCO2_ID charactérisation
           , GCO3_GCO_CHARACTERIZATION_ID   -- GCO3_ID charactérisation
           , GCO4_GCO_CHARACTERIZATION_ID   -- GCO4_ID charactérisation
           , ILP_CHARACTERIZATION_VALUE_1   -- Valeur de caractérisation 1
           , ILP_CHARACTERIZATION_VALUE_2   -- Valeur de caractérisation 2
           , ILP_CHARACTERIZATION_VALUE_3   -- Valeur de caractérisation 3
           , ILP_CHARACTERIZATION_VALUE_4   -- Valeur de caractérisation 4
           , ILP_CHARACTERIZATION_VALUE_5   -- Valeur de caractérisation 5
           , ILP_SYS_ALTERNATIV_QTY_1   -- Quantité alternative 1 (système)
           , ILP_SYS_ALTERNATIV_QTY_2   -- Quantité alternative 2 (système)
           , ILP_SYS_ALTERNATIV_QTY_3   -- Quantité alternative 3 (système)
           , ILP_SYSTEM_VALUE   -- Valeur système
           , ILP_SYSTEM_UNIT_PRICE   -- Prix unitaire système
           , ILP_SYSTEM_QUANTITY   -- Quantité système
           , ILP_PROVISORY_inPUT   -- Quantité entrée provisoire
           , ILP_PROVISORY_OUTPUT   -- Quantité sortie provisoire
           , ILP_inV_ALTERNATIV_QTY_1   -- Quantité alternative 1 (inventoriée)
           , ILP_inV_ALTERNATIV_QTY_2   -- Quantité alternative 2 (inventoriée)
           , ILP_inV_ALTERNATIV_QTY_3   -- Quantité alternative 3 (inventoriée)
           , ILP_INVENTORY_VALUE   -- Valeur inventoriée
           , ILP_INVENTORY_UNIT_PRICE   -- Prix unitaire inventorié
           , ILP_INVENTORY_QUANTITY   -- Quantité inventoriée
           , ILP_IS_VALIDATED   -- Position traitée
           , ILP_IS_ORIGinAL_POS   -- Position extraite
           , ILP_INVENTORY_DATE   -- Date de l'inventaire
           , ILP_COMMENT   -- Commentaire
           , ILP_ASSIGN_QUANTITY   -- Quantité attribuée sur stock
           , pSessionId   -- Identifiant de session
           , pinvAltQty3   -- Quantité alternative 3 saisie
           , pinvAltQty2   -- Quantité alternative 2 saisie
           , pinvAltQty1   -- Quantité alternative 1 saisie
           , pinvValue   -- Prix total saisie
           , pinvUnitPrice   -- Prix unitaire saisie
           , pinvQty   -- Quantité saisie
           , A_IDCRE   -- ID de création
           , A_DATECRE   -- Date de création
           , pFreeDate1
           , pFreeDate2
           , pFreeDate3
           , pFreeDate4
           , pFreeDate5
           , pFreeText1
           , pFreeText2
           , pFreeText3
           , pFreeText4
           , pFreeText5
           , pFreeNum1
           , pFreeNum2
           , pFreeNum3
           , pFreeNum4
           , pFreeNum5
           , pinvRetestDate   -- date réanalyse
           , pQualityStatusId   -- status qualité
        from stm_inventory_LIST_POS
       where stm_inventory_LIST_POS_ID = pWorkId;

    stm_inventory.UpdateJobAfterinsert(pJobId, pTaskId, pListId, pWorkId, pSessionId);
  end CreateNewWorkPosition;

  procedure CreateNewListPosition(
    aListPosId       out stm_inventory_LIST_POS.stm_inventory_LIST_POS_ID%type
  , aJobId               stm_inventory_JOB.stm_inventory_JOB_ID%type
  , aListId              stm_inventory_LIST_POS.stm_inventory_LIST_ID%type
  , aTaskId              stm_inventory_LIST_POS.stm_inventory_TASK_ID%type
  , aPeriodId            stm_inventory_LIST_POS.STM_PERIOD_ID%type
  , ainvType             stm_inventory_LIST_POS.C_INVENTORY_TYPE%type
  , ainvDate             stm_inventory_LIST_POS.ILP_INVENTORY_DATE%type
  , aGoodId              stm_inventory_LIST_POS.GCO_GOOD_ID%type
  , aStockId             stm_inventory_LIST_POS.STM_STOCK_ID%type
  , aLocationId          stm_inventory_LIST_POS.STM_LOCATION_ID%type
  ,
    --aElementId1    stm_inventory_LIST_POS.STM_ELEMENT_NUMBER_ID%TYPE,
    --aElementId2    stm_inventory_LIST_POS.STM_STM_ELEMENT_NUMBER_ID%TYPE,
    --aElementId3    stm_inventory_LIST_POS.STM2_STM_ELEMENT_NUMBER_ID%TYPE,
    aCharId1             stm_inventory_LIST_POS.GCO_CHARACTERIZATION_ID%type
  , aCharId2             stm_inventory_LIST_POS.GCO_GCO_CHARACTERIZATION_ID%type
  , aCharId3             stm_inventory_LIST_POS.GCO2_GCO_CHARACTERIZATION_ID%type
  , aCharId4             stm_inventory_LIST_POS.GCO3_GCO_CHARACTERIZATION_ID%type
  , aCharId5             stm_inventory_LIST_POS.GCO4_GCO_CHARACTERIZATION_ID%type
  , aStockPosId          stm_inventory_LIST_POS.STM_STOCK_POSITION_ID%type
  , ainvValue            stm_inventory_LIST_POS.ILP_INVENTORY_VALUE%type
  , ainvQty              stm_inventory_LIST_POS.ILP_INVENTORY_QUANTITY%type
  , ainvUnitPrice        stm_inventory_LIST_POS.ILP_INVENTORY_UNIT_PRICE%type
  , ainvAltQty1          stm_inventory_LIST_POS.ILP_inV_ALTERNATIV_QTY_1%type
  , ainvAltQty2          stm_inventory_LIST_POS.ILP_inV_ALTERNATIV_QTY_2%type
  , ainvAltQty3          stm_inventory_LIST_POS.ILP_inV_ALTERNATIV_QTY_3%type
  , aComment             stm_inventory_LIST_POS.ILP_COMMENT%type
  , aEleStatus1          stm_inventory_LIST_POS.ILP_C_ELE_NUM_STATUS_1%type
  , aEleStatus2          stm_inventory_LIST_POS.ILP_C_ELE_NUM_STATUS_2%type
  , aEleStatus3          stm_inventory_LIST_POS.ILP_C_ELE_NUM_STATUS_3%type
  , aCharVal1            stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_1%type
  , aCharVal2            stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_2%type
  , aCharVal3            stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_3%type
  , aCharVal4            stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_4%type
  , aCharVal5            stm_inventory_LIST_POS.ILP_CHARACTERIZATION_VALUE_5%type
  , ainvRetestDate       stm_inventory_LIST_POS.ILP_RETEST_DATE%type
  , aQualityStatusId     stm_inventory_LIST_POS.GCO_QUALITY_STATUS_ID%type
  )
  is
    cursor crStockPos(cStockPosId Stm_Stock_Position.Stm_Stock_Position_Id%type)
    is
      select gco_good_id
           , stm_location_id
           , stm_stock_id
           , stm_element_number_id
           , stm_stm_element_number_id
           , stm2_stm_element_number_id
           , gco_characterization_id
           , gco_gco_characterization_id
           , gco2_gco_characterization_id
           , gco3_gco_characterization_id
           , gco4_gco_characterization_id
           , spo_characterization_value_1
           , spo_characterization_value_2
           , spo_characterization_value_3
           , spo_characterization_value_4
           , spo_characterization_value_5
           , spo_stock_quantity * gco_functions.getcostpricewithmanagementmode(gco_good_id) systemvalue
           , spo_stock_quantity
           , gco_functions.getcostpricewithmanagementmode(gco_good_id) unitprice
           , spo_alternativ_quantity_1
           , spo_alternativ_quantity_2
           , spo_alternativ_quantity_3
           , spo_provisory_output
           , spo_provisory_input
           , spo_assign_quantity
        from stm_stock_position
       where stm_stock_position_id = cStockPosId;

    tplStockPos crStockPos%rowtype;
    vFoundPos   number;
  begin
    vFoundPos  := 0;

    open crStockPos(aStockPosId);

    fetch crStockPos
     into tplStockPos;

    if crStockPos%found then
      vFoundPos  := 1;
    end if;

    close crStockPos;

    select init_id_seq.nextval
      into aListPosId
      from dual;

    insert into stm_inventory_LIST_POS
                (stm_inventory_LIST_POS_ID
               , stm_inventory_LIST_ID
               , GCO_GOOD_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               ,
                 --STM_ELEMENT_NUMBER_ID,
                 --STM_STM_ELEMENT_NUMBER_ID,
                 --STM2_STM_ELEMENT_NUMBER_ID,
                 GCO_CHARACTERIZATION_ID
               , GCO_GCO_CHARACTERIZATION_ID
               , GCO2_GCO_CHARACTERIZATION_ID
               , GCO3_GCO_CHARACTERIZATION_ID
               , GCO4_GCO_CHARACTERIZATION_ID
               , C_INVENTORY_TYPE
               , STM_PERIOD_ID
               , STM_STOCK_POSITION_ID
               , ILP_IS_ORIGINAL_POS
               , ILP_IS_VALIDATED
               , ILP_SYSTEM_VALUE
               , ILP_SYSTEM_QUANTITY
               , ILP_SYSTEM_UNIT_PRICE
               , ILP_INVENTORY_VALUE
               , ILP_INVENTORY_QUANTITY
               , ILP_INVENTORY_UNIT_PRICE
               , ILP_INVENTORY_DATE
               , ILP_SYS_ALTERNATIV_QTY_1
               , ILP_SYS_ALTERNATIV_QTY_2
               , ILP_SYS_ALTERNATIV_QTY_3
               , ILP_PROVISORY_OUTPUT
               , ILP_PROVISORY_INPUT
               , ILP_INV_ALTERNATIV_QTY_1
               , ILP_INV_ALTERNATIV_QTY_2
               , ILP_INV_ALTERNATIV_QTY_3
               , ILP_COMMENT
               , ILP_C_ELE_NUM_STATUS_1
               , ILP_C_ELE_NUM_STATUS_2
               , ILP_C_ELE_NUM_STATUS_3
               , ILP_CHARACTERIZATION_VALUE_1
               , ILP_CHARACTERIZATION_VALUE_2
               , ILP_CHARACTERIZATION_VALUE_3
               , ILP_CHARACTERIZATION_VALUE_4
               , ILP_CHARACTERIZATION_VALUE_5
               , ILP_ASSIGN_QUANTITY
               , A_DATECRE
               , A_IDCRE
               , stm_inventory_TASK_ID
               , ILP_RETEST_DATE
               , GCO_QUALITY_STATUS_ID   -- status qualité
                )
      select aListPosId
           , aListId
           , decode(vFoundPos, 1, tplStockPos.gco_good_id, aGoodId)
           , decode(vFoundPos, 1, tplStockPos.stm_stock_id, aStockId)
           , decode(vFoundPos, 1, tplStockPos.stm_location_id, aLocationId)
           ,
             --decode (vFoundPos, 1, tplStockPos.stm_element_number_id,aElementId1),
             --decode (vFoundPos, 1, tplStockPos.stm_stm_element_number_id, aElementId2),
             --decode (vFoundPos, 1, tplStockPos.stm2_stm_element_number_id, aElementId3),
             decode(vFoundPos, 1, tplStockPos.gco_characterization_id, aCharId1)
           , decode(vFoundPos, 1, tplStockPos.gco_gco_characterization_id, aCharId2)
           , decode(vFoundPos, 1, tplStockPos.gco2_gco_characterization_id, aCharId3)
           , decode(vFoundPos, 1, tplStockPos.gco3_gco_characterization_id, aCharId4)
           , decode(vFoundPos, 1, tplStockPos.gco4_gco_characterization_id, aCharId5)
           , ainvType
           , aPeriodId
           , decode(vFoundPos, 1, aStockPosId, null)
           , decode(vFoundPos, 1, 1, 0)
           , 0
           , decode(vFoundPos, 1, tplStockPos.systemvalue, 0)
           , decode(vFoundPos, 1, tplStockPos.spo_stock_quantity, 0)
           , decode(vFoundPos, 1, tplStockPos.unitprice, gco_functions.getcostpricewithmanagementmode(aGoodId) )
           , decode(inv.c_inventory_mode, '1', 0, '2', decode(vFoundPos, 1, tplStockPos.systemvalue, 0) ) ipr_inventory_quantity
           , decode(inv.c_inventory_mode, '1', 0, '2', decode(vFoundPos, 1, tplStockPos.spo_stock_quantity, 0) ) ipr_inventory_quantity
           , decode(inv.c_inventory_mode, '1', 0, '2', decode(vFoundPos, 1, tplStockPos.unitprice, gco_functions.getcostpricewithmanagementmode(aGoodId) ) )
                                                                                                                                         ipr_inventory_quantity
           , ainvDate
           , decode(vFoundPos, 1, tplStockPos.spo_alternativ_quantity_1, 0)
           , decode(vFoundPos, 1, tplStockPos.spo_alternativ_quantity_2, 0)
           , decode(vFoundPos, 1, tplStockPos.spo_alternativ_quantity_3, 0)
           , decode(vFoundPos, 1, tplStockPos.spo_provisory_output, 0)
           , decode(vFoundPos, 1, tplStockPos.spo_provisory_input, 0)
           , decode(inv.c_inventory_mode, '1', 0, '2', decode(vFoundPos, 1, tplStockPos.spo_alternativ_quantity_1, 0) )
           , decode(inv.c_inventory_mode, '1', 0, '2', decode(vFoundPos, 1, tplStockPos.spo_alternativ_quantity_2, 0) )
           , decode(inv.c_inventory_mode, '1', 0, '2', decode(vFoundPos, 1, tplStockPos.spo_alternativ_quantity_3, 0) )
           , aComment
           , aEleStatus1
           , aEleStatus2
           , aEleStatus3
           , decode(vFoundPos, 1, tplStockPos.spo_characterization_value_1, aCharVal1)
           , decode(vFoundPos, 1, tplStockPos.spo_characterization_value_2, aCharVal2)
           , decode(vFoundPos, 1, tplStockPos.spo_characterization_value_3, aCharVal3)
           , decode(vFoundPos, 1, tplStockPos.spo_characterization_value_4, aCharVal4)
           , decode(vFoundPos, 1, tplStockPos.spo_characterization_value_5, aCharVal5)
           , decode(vFoundPos, 1, tplStockPos.spo_assign_quantity, 0)
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserini
           , aTaskId
           , aInvRetestDate
           , aQualityStatusId
        from stm_inventory_task inv
       where stm_inventory_task_id = aTaskId;
  end CreateNewListPosition;

  procedure insertintoPrint(
    pinsertList   number   --insertion de la liste
  , pinsertJob    number   --insertion des journaux de la liste
  , pinsertinvExt number   --insertion des inventaires externe
  , pListId       stm_inventory_PRinT.stm_inventory_LIST_ID%type
  , pinvExtId     stm_inventory_EXTERNAL.stm_inventory_EXTERNAL_ID%type
  , pSessionId    stm_inventory_PRinT.IPT_PRinT_SESSION%type
  )
  is
  begin
    -- insertion uniquement de la liste donnée
    if pinsertList = 1 then
      insert into stm_inventory_PRinT
                  (stm_inventory_PRinT_ID
                 , stm_inventory_JOB_ID
                 , stm_inventory_LIST_ID
                 , IPT_PRinT_SESSION
                  )
        select init_id_seq.nextval
             , null
             , pListId
             , pSessionId
          from dual;
    -- insertion d'un inventaire externe
    elsif pinsertinvExt = 1 then
      insert into stm_inventory_PRinT
                  (stm_inventory_PRinT_ID
                 ,
                   --stm_inventory_EXTERNAL_ID, PYV
                   IPT_PRinT_SESSION
                  )
        select init_id_seq.nextval
             ,
               --pinvExtId,
               pSessionId
          from dual;
    -- insertion des journaux de la liste donnée
    elsif pinsertJob = 1 then
      insert into stm_inventory_PRinT
                  (stm_inventory_PRinT_ID
                 , stm_inventory_JOB_ID
                 , stm_inventory_LIST_ID
                 , IPT_PRinT_SESSION
                  )
        select init_id_seq.nextval
             , stm_inventory_JOB_ID
             , stm_inventory_LIST_ID
             , pSessionId
          from stm_inventory_JOB
         where stm_inventory_LIST_ID = pListId;
    end if;
  end insertintoPrint;

  procedure DeleteFromPrint(pPrintId stm_inventory_PRinT.stm_inventory_PRinT_ID%type, pSessionId stm_inventory_PRinT.IPT_PRinT_SESSION%type)
  is
  begin
    if pPrintId = -1 then   --  Suppression de toutes les impressions de la session courante
      delete from stm_inventory_print
            where ipt_print_session = pSessionId;
    else   --  Suppression de l'impression courantde la session courante
      delete from stm_inventory_print
            where stm_inventory_print_id = pPrintId
              and IPT_PRinT_SESSION = psessionid;
    end if;
  end DeleteFromPrint;

  procedure GetMovementKind(
    pMovementType   in     stm_movement_kind.c_movement_type%type
  , pMovementSort   in     stm_movement_kind.c_movement_sort%type
  , pMovementCode   in     stm_movement_kind.c_movement_code%type
  , pMovementKindId in out stm_movement_kind.stm_movement_kind_id%type
  )
  is
  begin
    select STM_MOVEMENT_KinD_ID
      into pMovementKindId
      from STM_MOVEMENT_KinD
     where C_MOVEMENT_TYPE = pMovementType
       and C_MOVEMENT_SORT = pMovementSort
       and C_MOVEMENT_CODE = pMovementCode;
  end GetMovementKind;

  --
  -- procédure permettant de rechercher les types de mouvement utilisés durant le traitement de l'inventaire
  --
  procedure GetAllMovementKind(
    pinventoryType    in     stm_inventory_task.c_inventory_type%type   -- type d'inventaire
  , pActiveExerciseId in out stm_exercise.stm_exercise_id%type   -- id de l'exercice actif
  , pExeStartingDate  in out stm_exercise.exe_starting_exercise%type   -- date début exercice actif
  , pActivePeriodId   in out stm_period.stm_period_id%type   -- id de la période active
  , pMvtKindReportEnt in out stm_movement_kind.stm_movement_kind_id%type   -- mouvement de report ENT
  , pMvtKindReportSor in out stm_movement_kind.stm_movement_kind_id%type   -- mouvement de report SOR
  , pMvtKindinput     in out stm_movement_kind.stm_movement_kind_id%type   -- mouvement ENT
  , pMvtKindOutput    in out stm_movement_kind.stm_movement_kind_id%type   -- mouvement SOR
  , pMvtKindAltCorr   in out stm_movement_kind.stm_movement_kind_id%type   -- mouvement sur qté alternative ENT
  )
  is
  begin
    -- init des variables
    pActiveExerciseId  := null;
    pExeStartingDate   := null;
    pActiveExerciseId  := null;
    pActivePeriodId    := null;
    pMvtKindReportSor  := null;
    pMvtKindinput      := null;
    pMvtKindOutput     := null;
    pMvtKindAltCorr    := null;

    --Sélection de l'exercice actif, la date de début de cet exercice et de la période active de l'exercice actif
    select exe.stm_exercise_id
         , exe.exe_starting_exercise
         , per.stm_period_id
      into pActiveExerciseId
         , pExeStartingDate
         , pActivePeriodId
      from stm_exercise exe
         , stm_period per
     where exe.c_exercise_status = '02'
       and exe.stm_exercise_id = per.stm_exercise_id
       and per.c_period_status = '02';

    GetMovementKind('EXE', 'ENT', '005', pMvtKindReportEnt);   -- Correction d'exercice entrée
    GetMovementKind('EXE', 'SOR', '005', pMvtKindReportSor);   -- Correction d'exercice sortie

    -- recherche des genres de mouvement
    if pinventoryType = '01' then   -- inventaire initial
      GetMovementKind('INV', 'ENT', '001', pMvtKindinput);
    elsif    pinventoryType = '02'
          or pinventoryType = '04' then   -- inventaire manuel ou unitaire
      GetMovementKind('INV', 'ENT', '003', pMvtKindinput);
      GetMovementKind('INV', 'SOR', '003', pMvtKindOutput);
      GetMovementKind('INV', 'ENT', '016', pMvtKindAltCorr);
    elsif pinventoryType = '03' then   -- inventaire tournant
      GetMovementKind('INV', 'ENT', '002', pMvtKindinput);
      GetMovementKind('INV', 'SOR', '002', pMvtKindOutput);
      GetMovementKind('INV', 'ENT', '015', pMvtKindAltCorr);
    end if;
  end GetAllMovementKind;

  procedure UpdateNetworkLink(
    pDeltaSpoAssignQty  in stm_stock_position.spo_assign_quantity%type
  , pStmStockPositionId in stm_stock_position.stm_stock_position_id%type
  , aListPosition       in crGetListPosition%rowtype
  )
  is
    --  curseurs
    cursor crAllNetworkLink(cStmStockPositionId in stm_stock_position.stm_stock_position_id%type)
    is
      select     fln.fal_network_link_id
               , fln.fln_qty
               , fnn.fal_network_need_id
               , fnn.doc_position_detail_id
               , fnn.doc_position_id
               , fnn.fan_description
               , fnn.gco_good_id
               , fnn.fan_beg_plan
               , fnn.fan_free_qty
               , fnn.fan_stk_qty
            from fal_network_link fln
               , fal_network_need fnn
           where fln.stm_stock_position_id = cStmStockPositionId
             and fln.fal_network_need_id = fnn.fal_network_need_id
        order by fnn.fan_beg_plan desc
      for update;

    --  variables
    tplNetworkLink     crAllNetworkLink%rowtype;
    vDeltaSpoAssignQty stm_stock_position.spo_assign_quantity%type;
    vNeed_old_free_qty number(15, 4);
    vNeed_old_stk_qty  number(15, 4);
    vNeed_new_free_qty number(15, 4);
    vNeed_new_stk_qty  number(15, 4);
    vLink_old_qty      number(15, 4);
    vLink_new_qty      number(15, 4);
    vDelta_qty         number(15, 4);
    vDelta_qty_before  number(15, 4);
    vUpdate_Type       varchar2(10);
  begin
    --  attention : pDeltaSpoAssignQty est négatif
    vDeltaSpoAssignQty  := -pDeltaSpoAssignQty;
    vDelta_qty          := vDeltaSpoAssignQty;

    open crAllNetworkLink(pStmStockPositionId);

    fetch crAllNetworkLink
     into tplNetworkLink;

    while crAllNetworkLink%found
     and vDeltaSpoAssignQty > 0 loop
      vDelta_qty_before   := vDeltaSpoAssignQty;
      vNeed_old_free_qty  := tplNetworkLink.fan_free_qty;
      vNeed_old_stk_qty   := tplNetworkLink.fan_stk_qty;
      vLink_old_qty       := tplNetworkLink.fln_qty;

      if vDeltaSpoAssignQty < tplNetworkLink.fln_qty then
        vUpdate_type        := 'UPD';

        update fal_network_link fln
           set fln.fln_qty = fln.fln_qty - vDeltaSpoAssignQty
             , A_DATEMOD = sysdate
             , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
         where fln.fal_network_link_id = tplNetworkLink.fal_network_link_id;

        update fal_network_need fnn
           set fnn.fan_free_qty = fnn.fan_free_qty + vDeltaSpoAssignQty
             , fnn.fan_stk_qty = fnn.fan_stk_qty - vDeltaSpoAssignQty
             , A_DATEMOD = sysdate
             , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
         where fnn.fal_network_need_id = tplNetworkLink.fal_network_need_id;

        vNeed_new_free_qty  := tplNetworkLink.fan_free_qty + vDeltaSpoAssignQty;
        vNeed_new_stk_qty   := tplNetworkLink.fan_stk_qty - vDeltaSpoAssignQty;
        vLink_new_qty       := tplNetworkLink.fln_qty - vDeltaSpoAssignQty;
        vDeltaSpoAssignQty  := 0;
      else   -- vDeltaSpoAssignQty >= tplNetworkLink.fln_qty then
        vUpdate_type        := 'DEL';

        delete from fal_network_link fln
              where fln.fal_network_link_id = tplNetworkLink.fal_network_link_id;

        update fal_network_need fnn
           set fnn.fan_free_qty = fnn.fan_free_qty + tplNetworkLink.fln_qty
             , fnn.fan_stk_qty = fnn.fan_stk_qty - tplNetworkLink.fln_qty
             , A_DATEMOD = sysdate
             , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
         where fnn.fal_network_need_id = tplNetworkLink.fal_network_need_id;

        vNeed_new_free_qty  := tplNetworkLink.fan_free_qty + tplNetworkLink.fln_qty;
        vNeed_new_stk_qty   := tplNetworkLink.fan_stk_qty - tplNetworkLink.fln_qty;
        vLink_new_qty       := 0;
        vDeltaSpoAssignQty  := vDeltaSpoAssignQty - tplNetworkLink.fln_qty;
      end if;

      insert into stm_inventory_updated_links
                  (stm_inventory_updated_links_id
                 , STM_INVENTORY_TASK_ID
                 , STM_INVENTORY_LIST_ID
                 , STM_INVENTORY_LIST_POS_ID
                 , C_INV_UPDATE_LINK_TYPE
                 , DOC_DOCUMENT_ID
                 , DOC_POSITION_ID
                 , DOC_POSITION_DETAIL_ID
                 , DMT_NUMBER
                 , POS_NUMBER
                 , GCO_GOOD_ID
                 , IUL_NEED_BEFORE_FREE_QTY
                 , IUL_NEED_BEFORE_STK_QTY
                 , IUL_NEED_AFTER_FREE_QTY
                 , IUL_NEED_AFTER_STK_QTY
                 , IUL_LINK_BEFORE_QTY
                 , IUL_LINK_AFTER_QTY
                 , iul_delta_qty
                 , IUL_DELTA_QTY_BEFORE
                 , IUL_DELTA_QTY_AFTER
                 , IUL_BASIS_DELAY
                 , IUL_INTERMEDIATE_DELAY
                 , IUL_FINAL_DELAY
                 , A_DATECRE
                 , A_IDCRE
                  )
        select init_id_seq.nextval
             , aListPosition.stm_inventory_task_id
             , aListPosition.stm_inventory_list_id
             , aListPosition.stm_inventory_list_pos_id
             , vUpdate_type
             , dmt.doc_document_id
             , tplNetworkLink.doc_position_id
             , tplNetworkLink.doc_position_detail_id
             , dmt.dmt_number
             , pos.pos_number
             , tplNetworkLink.gco_good_id
             , vNEED_OLD_FREE_QTY
             , vNEED_OLD_STK_QTY
             , vNEED_NEW_FREE_QTY
             , vNEED_NEW_STK_QTY
             , vLINK_OLD_QTY
             , vLINK_NEW_QTY
             , vDelta_qty
             , vDelta_qty_before
             , vDeltaSpoAssignQty
             , pde.pde_basis_delay
             , pde.pde_intermediate_delay
             , pde.pde_basis_delay
             , sysdate
             , pcs.PC_I_LIB_SESSION.getuserini
          from doc_position_detail pde
             , doc_position pos
             , doc_document dmt
         where dmt.doc_document_id = pos.doc_document_id
           and pos.doc_position_id = pde.doc_position_id
           and pde.doc_position_detail_id = tplNetworkLink.doc_position_detail_id;

      fetch crAllNetworkLink
       into tplNetworkLink;
    end loop;

    close crAllNetworkLink;

    update stm_stock_position spo
       set spo.spo_assign_quantity = spo.spo_assign_quantity + pDeltaSpoAssignQty
         , spo.spo_available_quantity = spo.spo_available_quantity - pDeltaSpoAssignQty
         , A_DATEMOD = sysdate
         , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
     where spo.stm_stock_position_id = pStmStockPositionId;
  end UpdateNetworkLink;

  procedure ValidateOnePosition(
    ptab_list_pos     in     crGetListPosition%rowtype
  , pinventoryType    in     stm_inventory_task.c_inventory_type%type
  , pActiveExerciseId in out stm_exercise.stm_exercise_id%type   -- id de l'exercice actif
  , pExeStartingDate  in out stm_exercise.exe_starting_exercise%type   -- date début exercice actif
  , pActivePeriodId   in out stm_period.stm_period_id%type   -- id de la période active
  , pMvtKindReportEnt in out stm_movement_kind.stm_movement_kind_id%type   -- mouvement de report ENT
  , pMvtKindReportSor in out stm_movement_kind.stm_movement_kind_id%type   -- mouvement de report SOR
  , pMvtKindinput     in out stm_movement_kind.stm_movement_kind_id%type   -- mouvement ENT
  , pMvtKindOutput    in out stm_movement_kind.stm_movement_kind_id%type   -- mouvement SOR
  , pMvtKindAltCorr   in out stm_movement_kind.stm_movement_kind_id%type   -- mouvement sur qté alternative ENT
  , pError            in out number
  )
  is
    vStmStockPositionId stm_stock_position.stm_stock_position_id%type;
    vSpoStockQty        stm_stock_position.spo_stock_quantity%type;
    vSpoAssignQty       stm_stock_position.spo_assign_quantity%type;
    vSpoAlt1Qty         stm_stock_position.spo_alternativ_quantity_1%type;
    vSpoAlt2Qty         stm_stock_position.spo_alternativ_quantity_2%type;
    vSpoAlt3Qty         stm_stock_position.spo_alternativ_quantity_3%type;
    vContinue           number;
    vPriceMvt           stm_stock_movement.smo_movement_price%type;
    vDeltaSpoAssignQty  stm_stock_position.spo_assign_quantity%type;
    vMvt                stm_stock_movement.stm_stock_movement_id%type;
    vElementNumberId    stm_element_number.stm_element_number_id%type;
  begin
    -- init des variables
    vStmStockPositionId  := 0;
    vSpoStockQty         := 0;
    vSpoAssignQty        := 0;
    vSpoAlt1Qty          := 0;
    vSpoAlt2Qty          := 0;
    vSpoAlt3Qty          := 0;
    vContinue            := 1;
    vPriceMvt            := 0;
    pError               := 0;

    -- recherche de la position de stock en fonction de l'id de cette position de stock
    if ptab_list_pos.stm_stock_position_id is not null then
      select nvl(max(stm_stock_position_id), 0)
           , nvl(max(spo_stock_quantity), 0)
           , nvl(max(spo_assign_quantity), 0)
           , nvl(max(spo_alternativ_quantity_1), 0)
           , nvl(max(spo_alternativ_quantity_2), 0)
           , nvl(max(spo_alternativ_quantity_3), 0)
        into vStmStockPositionId
           , vSpoStockQty
           , vSpoAssignQty
           , vSpoAlt1Qty
           , vSpoAlt2Qty
           , vSpoAlt3Qty
        from STM_STOCK_POSITION
       where STM_STOCK_POSITION_ID = ptab_list_pos.stm_stock_position_id;
    end if;

    -- la position n'a pas été trouvée ou n'existait pas à la création de l'inventaire
    if    vStmStockPositionId = 0
       or ptab_list_pos.stm_stock_position_id is null then
      select nvl(max(stm_stock_position_id), 0)
           , nvl(max(spo_stock_quantity), 0)
           , nvl(max(spo_assign_quantity), 0)
           , nvl(max(spo_alternativ_quantity_1), 0)
           , nvl(max(spo_alternativ_quantity_2), 0)
           , nvl(max(spo_alternativ_quantity_3), 0)
        into vStmStockPositionId
           , vSpoStockQty
           , vSpoAssignQty
           , vSpoAlt1Qty
           , vSpoAlt2Qty
           , vSpoAlt3Qty
        from stm_stock_position
       where GCO_GOOD_ID = ptab_list_pos.gco_good_id
         and STM_STOCK_ID = ptab_list_pos.stm_stock_id
         and STM_LOCATION_ID = ptab_list_pos.stm_location_id
         and (     (   gco_characterization_id = ptab_list_pos.gco_characterization_id
                    or (    ptab_list_pos.gco_characterization_id is null
                        and gco_characterization_id is null)
                   )
              and (   gco_gco_characterization_id = ptab_list_pos.gco_gco_characterization_id
                   or (    ptab_list_pos.gco_gco_characterization_id is null
                       and gco_gco_characterization_id is null)
                  )
              and (   gco2_gco_characterization_id = ptab_list_pos.gco2_gco_characterization_id
                   or (    ptab_list_pos.gco2_gco_characterization_id is null
                       and gco2_gco_characterization_id is null)
                  )
              and (   gco3_gco_characterization_id = ptab_list_pos.gco3_gco_characterization_id
                   or (    ptab_list_pos.gco3_gco_characterization_id is null
                       and gco3_gco_characterization_id is null)
                  )
              and (   gco4_gco_characterization_id = ptab_list_pos.gco4_gco_characterization_id
                   or (    ptab_list_pos.gco4_gco_characterization_id is null
                       and gco4_gco_characterization_id is null)
                  )
              and (   spo_characterization_value_1 = ptab_list_pos.ilp_characterization_value_1
                   or (    ptab_list_pos.ilp_characterization_value_1 is null
                       and spo_characterization_value_1 is null)
                  )
              and (   spo_characterization_value_2 = ptab_list_pos.ilp_characterization_value_2
                   or (    ptab_list_pos.ilp_characterization_value_2 is null
                       and spo_characterization_value_2 is null)
                  )
              and (   spo_characterization_value_3 = ptab_list_pos.ilp_characterization_value_3
                   or (    ptab_list_pos.ilp_characterization_value_3 is null
                       and spo_characterization_value_3 is null)
                  )
              and (   spo_characterization_value_4 = ptab_list_pos.ilp_characterization_value_4
                   or (    ptab_list_pos.ilp_characterization_value_4 is null
                       and spo_characterization_value_4 is null)
                  )
              and (   spo_characterization_value_5 = ptab_list_pos.ilp_characterization_value_5
                   or (    ptab_list_pos.ilp_characterization_value_5 is null
                       and spo_characterization_value_5 is null)
                  )
             );
    end if;

    -- test : la valeur de la future position de stock
    if    vSpoStockQty +(ptab_list_pos.ilp_inventory_quantity - ptab_list_pos.ilp_system_quantity) < 0
       or vSpoAlt1Qty +(ptab_list_pos.ilp_inv_alternativ_qty_1 - ptab_list_pos.ilp_sys_alternativ_qty_1) < 0
       or vSpoAlt2Qty +(ptab_list_pos.ilp_inv_alternativ_qty_2 - ptab_list_pos.ilp_sys_alternativ_qty_2) < 0
       or vSpoAlt3Qty +(ptab_list_pos.ilp_inv_alternativ_qty_3 - ptab_list_pos.ilp_sys_alternativ_qty_3) < 0 then
      update stm_inventory_list_pos ilp
         set ilp.c_inventory_error_status = '001'
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
       where ilp.stm_inventory_list_pos_id = ptab_list_pos.stm_inventory_list_pos_id;

      pError     := 1;
      vContinue  := 0;
      commit;
    end if;

    if vContinue = 1 then
      if vStmStockPositionId <> 0 then
        vDeltaSpoAssignQty  := (vSpoStockQty +(ptab_list_pos.ilp_inventory_quantity - ptab_list_pos.ilp_system_quantity) ) - vSpoAssignQty;

        if vDeltaSpoAssignQty < 0 then
          UpdateNetworkLink(vDeltaSpoAssignQty, vStmStockPositionId, ptab_list_pos);
        end if;
      end if;

      if ptab_list_pos.ilp_inventory_quantity > ptab_list_pos.ilp_system_quantity then
        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => vMvt
                                        , iGoodId                => ptab_list_pos.gco_good_id
                                        , iMovementKindId        => pMvtKindinput
                                        , iExerciseId            => ptab_list_pos.stm_exercise_id
                                        , iPeriodId              => ptab_list_pos.stm_period_id
                                        , iMvtDate               => ptab_list_pos.ilp_inventory_date
                                        , iValueDate             => ptab_list_pos.ilp_inventory_date
                                        , iStockId               => ptab_list_pos.stm_stock_id
                                        , iLocationId            => ptab_list_pos.stm_location_id
                                        , iThirdId               => null
                                        , iThirdAciId            => null
                                        , iThirdDeliveryId       => null
                                        , iThirdTariffId         => null
                                        , iRecordId              => null
                                        , iChar1Id               => ptab_list_pos.gco_characterization_id
                                        , iChar2Id               => ptab_list_pos.gco_gco_characterization_id
                                        , iChar3Id               => ptab_list_pos.gco2_gco_characterization_id
                                        , iChar4Id               => ptab_list_pos.gco3_gco_characterization_id
                                        , iChar5Id               => ptab_list_pos.gco4_gco_characterization_id
                                        , iCharValue1            => ptab_list_pos.ilp_characterization_value_1
                                        , iCharValue2            => ptab_list_pos.ilp_characterization_value_2
                                        , iCharValue3            => ptab_list_pos.ilp_characterization_value_3
                                        , iCharValue4            => ptab_list_pos.ilp_characterization_value_4
                                        , iCharValue5            => ptab_list_pos.ilp_characterization_value_5
                                        , iMovement2Id           => null
                                        , iMovement3Id           => null
                                        , iWording               => ptab_list_pos.inv_description || ' / ' || ptab_list_pos.ili_description
                                        , iExternalDocument      => null
                                        , iExternalPartner       => null
                                        , iMvtQty                => ptab_list_pos.ilp_inventory_quantity - ptab_list_pos.ilp_system_quantity
                                        , iMvtPrice              => ptab_list_pos.ilp_inventory_value - ptab_list_pos.ilp_system_value
                                        , iDocQty                => 0
                                        , iDocPrice              => 0
                                        , iUnitPrice             => (ptab_list_pos.ilp_inventory_value - ptab_list_pos.ilp_system_value) /
                                                                    (ptab_list_pos.ilp_inventory_quantity - ptab_list_pos.ilp_system_quantity
                                                                    )
                                        , iRefUnitPrice          => GCO_functionS.GETCOSTPRICEWITHMANAGEMENTMODE(ptab_list_pos.gco_good_id)
                                        , iAltQty1               => ptab_list_pos.ilp_inv_alternativ_qty_1 - ptab_list_pos.ilp_sys_alternativ_qty_1
                                        , iAltQty2               => ptab_list_pos.ilp_inv_alternativ_qty_2 - ptab_list_pos.ilp_sys_alternativ_qty_2
                                        , iAltQty3               => ptab_list_pos.ilp_inv_alternativ_qty_3 - ptab_list_pos.ilp_sys_alternativ_qty_3
                                        , iDocPositionDetailId   => null
                                        , iDocPositionId         => null
                                        , iFinancialAccountId    => null
                                        , iDivisionAccountId     => null
                                        , iAFinancialAccountId   => null
                                        , iADivisionAccountId    => null
                                        , iCPNAccountId          => null
                                        , iACPNAccountId         => null
                                        , iCDAAccountId          => null
                                        , iACDAAccountId         => null
                                        , iPFAccountId           => null
                                        , iAPFAccountId          => null
                                        , iPJAccountId           => null
                                        , iAPJAccountId          => null
                                        , iFamFixedAssetsId      => null
                                        , iFamTransactionTyp     => null
                                        , iHrmPersonId           => null
                                        , iDicImpfree1Id         => null
                                        , iDicImpfree2Id         => null
                                        , iDicImpfree3Id         => null
                                        , iDicImpfree4Id         => null
                                        , iDicImpfree5Id         => null
                                        , iImpText1              => null
                                        , iImpText2              => null
                                        , iImpText3              => null
                                        , iImpText4              => null
                                        , iImpText5              => null
                                        , iImpNumber1            => null
                                        , iImpNumber2            => null
                                        , iImpNumber3            => null
                                        , iImpNumber4            => null
                                        , iImpNumber5            => null
                                        , iFinancialCharging     => null
                                        , iUpdateProv            => 0
                                        , iExtourneMvt           => 0
                                        , iRecStatus             => '8'
                                        , iOrderKey              => null
                                        , iDocFootAlloyID        => null
                                        , iInventoryMvt          => 1
                                         );
      elsif ptab_list_pos.ilp_inventory_quantity < ptab_list_pos.ilp_system_quantity then
        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => vMvt
                                        , iGoodId                => ptab_list_pos.gco_good_id
                                        , iMovementKindId        => pMvtKindOutput
                                        , iExerciseId            => ptab_list_pos.stm_exercise_id
                                        , iPeriodId              => ptab_list_pos.stm_period_id
                                        , iMvtDate               => ptab_list_pos.ilp_inventory_date
                                        , iValueDate             => ptab_list_pos.ilp_inventory_date
                                        , iStockId               => ptab_list_pos.stm_stock_id
                                        , iLocationId            => ptab_list_pos.stm_location_id
                                        , iThirdId               => null
                                        , iThirdAciId            => null
                                        , iThirdDeliveryId       => null
                                        , iThirdTariffId         => null
                                        , iRecordId              => null
                                        , iChar1Id               => ptab_list_pos.gco_characterization_id
                                        , iChar2Id               => ptab_list_pos.gco_gco_characterization_id
                                        , iChar3Id               => ptab_list_pos.gco2_gco_characterization_id
                                        , iChar4Id               => ptab_list_pos.gco3_gco_characterization_id
                                        , iChar5Id               => ptab_list_pos.gco4_gco_characterization_id
                                        , iCharValue1            => ptab_list_pos.ilp_characterization_value_1
                                        , iCharValue2            => ptab_list_pos.ilp_characterization_value_2
                                        , iCharValue3            => ptab_list_pos.ilp_characterization_value_3
                                        , iCharValue4            => ptab_list_pos.ilp_characterization_value_4
                                        , iCharValue5            => ptab_list_pos.ilp_characterization_value_5
                                        , iMovement2Id           => null
                                        , iMovement3Id           => null
                                        , iWording               => ptab_list_pos.inv_description || ' / ' || ptab_list_pos.ili_description
                                        , iExternalDocument      => null
                                        , iExternalPartner       => null
                                        , iMvtQty                => -(ptab_list_pos.ilp_inventory_quantity - ptab_list_pos.ilp_system_quantity)
                                        , iMvtPrice              => -(ptab_list_pos.ilp_inventory_value - ptab_list_pos.ilp_system_value)
                                        , iDocQty                => 0
                                        , iDocPrice              => 0
                                        , iUnitPrice             => (ptab_list_pos.ilp_inventory_value - ptab_list_pos.ilp_system_value) /
                                                                    (ptab_list_pos.ilp_inventory_quantity - ptab_list_pos.ilp_system_quantity
                                                                    )
                                        , iRefUnitPrice          => GCO_functionS.GETCOSTPRICEWITHMANAGEMENTMODE(ptab_list_pos.gco_good_id)
                                        , iAltQty1               => -(ptab_list_pos.ilp_inv_alternativ_qty_1 - ptab_list_pos.ilp_sys_alternativ_qty_1)
                                        , iAltQty2               => -(ptab_list_pos.ilp_inv_alternativ_qty_2 - ptab_list_pos.ilp_sys_alternativ_qty_2)
                                        , iAltQty3               => -(ptab_list_pos.ilp_inv_alternativ_qty_3 - ptab_list_pos.ilp_sys_alternativ_qty_3)
                                        , iDocPositionDetailId   => null
                                        , iDocPositionId         => null
                                        , iFinancialAccountId    => null
                                        , iDivisionAccountId     => null
                                        , iAFinancialAccountId   => null
                                        , iADivisionAccountId    => null
                                        , iCPNAccountId          => null
                                        , iACPNAccountId         => null
                                        , iCDAAccountId          => null
                                        , iACDAAccountId         => null
                                        , iPFAccountId           => null
                                        , iAPFAccountId          => null
                                        , iPJAccountId           => null
                                        , iAPJAccountId          => null
                                        , iFamFixedAssetsId      => null
                                        , iFamTransactionTyp     => null
                                        , iHrmPersonId           => null
                                        , iDicImpfree1Id         => null
                                        , iDicImpfree2Id         => null
                                        , iDicImpfree3Id         => null
                                        , iDicImpfree4Id         => null
                                        , iDicImpfree5Id         => null
                                        , iImpText1              => null
                                        , iImpText2              => null
                                        , iImpText3              => null
                                        , iImpText4              => null
                                        , iImpText5              => null
                                        , iImpNumber1            => null
                                        , iImpNumber2            => null
                                        , iImpNumber3            => null
                                        , iImpNumber4            => null
                                        , iImpNumber5            => null
                                        , iFinancialCharging     => null
                                        , iUpdateProv            => 0
                                        , iExtourneMvt           => 0
                                        , iRecStatus             => '8'
                                        , iOrderKey              => null
                                        , iDocFootAlloyID        => null
                                        , iInventoryMvt          => 1
                                         );
      elsif     (ptab_list_pos.ilp_inventory_quantity = ptab_list_pos.ilp_system_quantity)
            and (    (ptab_list_pos.ilp_inv_alternativ_qty_1 <> ptab_list_pos.ilp_sys_alternativ_qty_1)
                 or (ptab_list_pos.ilp_inv_alternativ_qty_2 <> ptab_list_pos.ilp_sys_alternativ_qty_2)
                 or (ptab_list_pos.ilp_inv_alternativ_qty_3 <> ptab_list_pos.ilp_sys_alternativ_qty_3)
                ) then
        if ptab_list_pos.ilp_inventory_quantity <> 0 then
          vPriceMvt  := (ptab_list_pos.ilp_inventory_value - ptab_list_pos.ilp_system_value) / ptab_list_pos.ilp_inventory_quantity;
        end if;

        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => vMvt
                                        , iGoodId                => ptab_list_pos.gco_good_id
                                        , iMovementKindId        => pMvtKindAltCorr
                                        , iExerciseId            => ptab_list_pos.stm_exercise_id
                                        , iPeriodId              => ptab_list_pos.stm_period_id
                                        , iMvtDate               => ptab_list_pos.ilp_inventory_date
                                        , iValueDate             => ptab_list_pos.ilp_inventory_date
                                        , iStockId               => ptab_list_pos.stm_stock_id
                                        , iLocationId            => ptab_list_pos.stm_location_id
                                        , iThirdId               => null
                                        , iThirdAciId            => null
                                        , iThirdDeliveryId       => null
                                        , iThirdTariffId         => null
                                        , iRecordId              => null
                                        , iChar1Id               => ptab_list_pos.gco_characterization_id
                                        , iChar2Id               => ptab_list_pos.gco_gco_characterization_id
                                        , iChar3Id               => ptab_list_pos.gco2_gco_characterization_id
                                        , iChar4Id               => ptab_list_pos.gco3_gco_characterization_id
                                        , iChar5Id               => ptab_list_pos.gco4_gco_characterization_id
                                        , iCharValue1            => ptab_list_pos.ilp_characterization_value_1
                                        , iCharValue2            => ptab_list_pos.ilp_characterization_value_2
                                        , iCharValue3            => ptab_list_pos.ilp_characterization_value_3
                                        , iCharValue4            => ptab_list_pos.ilp_characterization_value_4
                                        , iCharValue5            => ptab_list_pos.ilp_characterization_value_5
                                        , iMovement2Id           => null
                                        , iMovement3Id           => null
                                        , iWording               => ptab_list_pos.inv_description || ' / ' || ptab_list_pos.ili_description
                                        , iExternalDocument      => null
                                        , iExternalPartner       => null
                                        , iMvtQty                => (ptab_list_pos.ilp_inventory_quantity - ptab_list_pos.ilp_system_quantity)
                                        , iMvtPrice              => (ptab_list_pos.ilp_inventory_value - ptab_list_pos.ilp_system_value)
                                        , iDocQty                => 0
                                        , iDocPrice              => 0
                                        , iUnitPrice             => vPriceMvt
                                        , iRefUnitPrice          => GCO_functionS.GETCOSTPRICEWITHMANAGEMENTMODE(ptab_list_pos.gco_good_id)
                                        , iAltQty1               => (ptab_list_pos.ilp_inv_alternativ_qty_1 - ptab_list_pos.ilp_sys_alternativ_qty_1)
                                        , iAltQty2               => (ptab_list_pos.ilp_inv_alternativ_qty_2 - ptab_list_pos.ilp_sys_alternativ_qty_2)
                                        , iAltQty3               => (ptab_list_pos.ilp_inv_alternativ_qty_3 - ptab_list_pos.ilp_sys_alternativ_qty_3)
                                        , iDocPositionDetailId   => null
                                        , iDocPositionId         => null
                                        , iFinancialAccountId    => null
                                        , iDivisionAccountId     => null
                                        , iAFinancialAccountId   => null
                                        , iADivisionAccountId    => null
                                        , iCPNAccountId          => null
                                        , iACPNAccountId         => null
                                        , iCDAAccountId          => null
                                        , iACDAAccountId         => null
                                        , iPFAccountId           => null
                                        , iAPFAccountId          => null
                                        , iPJAccountId           => null
                                        , iAPJAccountId          => null
                                        , iFamFixedAssetsId      => null
                                        , iFamTransactionTyp     => null
                                        , iHrmPersonId           => null
                                        , iDicImpfree1Id         => null
                                        , iDicImpfree2Id         => null
                                        , iDicImpfree3Id         => null
                                        , iDicImpfree4Id         => null
                                        , iDicImpfree5Id         => null
                                        , iImpText1              => null
                                        , iImpText2              => null
                                        , iImpText3              => null
                                        , iImpText4              => null
                                        , iImpText5              => null
                                        , iImpNumber1            => null
                                        , iImpNumber2            => null
                                        , iImpNumber3            => null
                                        , iImpNumber4            => null
                                        , iImpNumber5            => null
                                        , iFinancialCharging     => null
                                        , iUpdateProv            => 0
                                        , iExtourneMvt           => 0
                                        , iRecStatus             => '8'
                                        , iOrderKey              => null
                                        , iDocFootAlloyID        => null
                                        , iInventoryMvt          => 1
                                         );
      elsif     ptab_list_pos.ilp_inventory_quantity = ptab_list_pos.ilp_system_quantity
            and ptab_list_pos.ilp_inventory_value > ptab_list_pos.ilp_system_value
            and pinventoryType <> '01' then
        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => vMvt
                                        , iGoodId                => ptab_list_pos.gco_good_id
                                        , iMovementKindId        => pMvtKindinput
                                        , iExerciseId            => ptab_list_pos.stm_exercise_id
                                        , iPeriodId              => ptab_list_pos.stm_period_id
                                        , iMvtDate               => ptab_list_pos.ilp_inventory_date
                                        , iValueDate             => ptab_list_pos.ilp_inventory_date
                                        , iStockId               => ptab_list_pos.stm_stock_id
                                        , iLocationId            => ptab_list_pos.stm_location_id
                                        , iThirdId               => null
                                        , iThirdAciId            => null
                                        , iThirdDeliveryId       => null
                                        , iThirdTariffId         => null
                                        , iRecordId              => null
                                        , iChar1Id               => ptab_list_pos.gco_characterization_id
                                        , iChar2Id               => ptab_list_pos.gco_gco_characterization_id
                                        , iChar3Id               => ptab_list_pos.gco2_gco_characterization_id
                                        , iChar4Id               => ptab_list_pos.gco3_gco_characterization_id
                                        , iChar5Id               => ptab_list_pos.gco4_gco_characterization_id
                                        , iCharValue1            => ptab_list_pos.ilp_characterization_value_1
                                        , iCharValue2            => ptab_list_pos.ilp_characterization_value_2
                                        , iCharValue3            => ptab_list_pos.ilp_characterization_value_3
                                        , iCharValue4            => ptab_list_pos.ilp_characterization_value_4
                                        , iCharValue5            => ptab_list_pos.ilp_characterization_value_5
                                        , iMovement2Id           => null
                                        , iMovement3Id           => null
                                        , iWording               => ptab_list_pos.inv_description || ' / ' || ptab_list_pos.ili_description
                                        , iExternalDocument      => null
                                        , iExternalPartner       => null
                                        , iMvtQty                => (ptab_list_pos.ilp_inventory_quantity - ptab_list_pos.ilp_system_quantity)
                                        , iMvtPrice              => (ptab_list_pos.ilp_inventory_value - ptab_list_pos.ilp_system_value)
                                        , iDocQty                => 0
                                        , iDocPrice              => 0
                                        , iUnitPrice             => (ptab_list_pos.ilp_inventory_value - ptab_list_pos.ilp_system_value)
                                        , iRefUnitPrice          => GCO_functionS.GETCOSTPRICEWITHMANAGEMENTMODE(ptab_list_pos.gco_good_id)
                                        , iAltQty1               => (ptab_list_pos.ilp_inv_alternativ_qty_1 - ptab_list_pos.ilp_sys_alternativ_qty_1)
                                        , iAltQty2               => (ptab_list_pos.ilp_inv_alternativ_qty_2 - ptab_list_pos.ilp_sys_alternativ_qty_2)
                                        , iAltQty3               => (ptab_list_pos.ilp_inv_alternativ_qty_3 - ptab_list_pos.ilp_sys_alternativ_qty_3)
                                        , iDocPositionDetailId   => null
                                        , iDocPositionId         => null
                                        , iFinancialAccountId    => null
                                        , iDivisionAccountId     => null
                                        , iAFinancialAccountId   => null
                                        , iADivisionAccountId    => null
                                        , iCPNAccountId          => null
                                        , iACPNAccountId         => null
                                        , iCDAAccountId          => null
                                        , iACDAAccountId         => null
                                        , iPFAccountId           => null
                                        , iAPFAccountId          => null
                                        , iPJAccountId           => null
                                        , iAPJAccountId          => null
                                        , iFamFixedAssetsId      => null
                                        , iFamTransactionTyp     => null
                                        , iHrmPersonId           => null
                                        , iDicImpfree1Id         => null
                                        , iDicImpfree2Id         => null
                                        , iDicImpfree3Id         => null
                                        , iDicImpfree4Id         => null
                                        , iDicImpfree5Id         => null
                                        , iImpText1              => null
                                        , iImpText2              => null
                                        , iImpText3              => null
                                        , iImpText4              => null
                                        , iImpText5              => null
                                        , iImpNumber1            => null
                                        , iImpNumber2            => null
                                        , iImpNumber3            => null
                                        , iImpNumber4            => null
                                        , iImpNumber5            => null
                                        , iFinancialCharging     => null
                                        , iUpdateProv            => 0
                                        , iExtourneMvt           => 0
                                        , iRecStatus             => '8'
                                        , iOrderKey              => null
                                        , iDocFootAlloyID        => null
                                        , iInventoryMvt          => 1
                                         );
      elsif     ptab_list_pos.ilp_inventory_quantity = ptab_list_pos.ilp_system_quantity
            and ptab_list_pos.ilp_inventory_value < ptab_list_pos.ilp_system_value
            and pinventoryType <> '01' then
        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => vMvt
                                        , iGoodId                => ptab_list_pos.gco_good_id
                                        , iMovementKindId        => pMvtKindinput
                                        , iExerciseId            => ptab_list_pos.stm_exercise_id
                                        , iPeriodId              => ptab_list_pos.stm_period_id
                                        , iMvtDate               => ptab_list_pos.ilp_inventory_date
                                        , iValueDate             => ptab_list_pos.ilp_inventory_date
                                        , iStockId               => ptab_list_pos.stm_stock_id
                                        , iLocationId            => ptab_list_pos.stm_location_id
                                        , iThirdId               => null
                                        , iThirdAciId            => null
                                        , iThirdDeliveryId       => null
                                        , iThirdTariffId         => null
                                        , iRecordId              => null
                                        , iChar1Id               => ptab_list_pos.gco_characterization_id
                                        , iChar2Id               => ptab_list_pos.gco_gco_characterization_id
                                        , iChar3Id               => ptab_list_pos.gco2_gco_characterization_id
                                        , iChar4Id               => ptab_list_pos.gco3_gco_characterization_id
                                        , iChar5Id               => ptab_list_pos.gco4_gco_characterization_id
                                        , iCharValue1            => ptab_list_pos.ilp_characterization_value_1
                                        , iCharValue2            => ptab_list_pos.ilp_characterization_value_2
                                        , iCharValue3            => ptab_list_pos.ilp_characterization_value_3
                                        , iCharValue4            => ptab_list_pos.ilp_characterization_value_4
                                        , iCharValue5            => ptab_list_pos.ilp_characterization_value_5
                                        , iMovement2Id           => null
                                        , iMovement3Id           => null
                                        , iWording               => ptab_list_pos.inv_description || ' / ' || ptab_list_pos.ili_description
                                        , iExternalDocument      => null
                                        , iExternalPartner       => null
                                        , iMvtQty                => (ptab_list_pos.ilp_inventory_quantity - ptab_list_pos.ilp_system_quantity)
                                        , iMvtPrice              => (ptab_list_pos.ilp_inventory_value - ptab_list_pos.ilp_system_value)
                                        , iDocQty                => 0
                                        , iDocPrice              => 0
                                        , iUnitPrice             => (ptab_list_pos.ilp_inventory_value - ptab_list_pos.ilp_system_value)
                                        , iRefUnitPrice          => GCO_functionS.GETCOSTPRICEWITHMANAGEMENTMODE(ptab_list_pos.gco_good_id)
                                        , iAltQty1               => (ptab_list_pos.ilp_inv_alternativ_qty_1 - ptab_list_pos.ilp_sys_alternativ_qty_1)
                                        , iAltQty2               => (ptab_list_pos.ilp_inv_alternativ_qty_2 - ptab_list_pos.ilp_sys_alternativ_qty_2)
                                        , iAltQty3               => (ptab_list_pos.ilp_inv_alternativ_qty_3 - ptab_list_pos.ilp_sys_alternativ_qty_3)
                                        , iDocPositionDetailId   => null
                                        , iDocPositionId         => null
                                        , iFinancialAccountId    => null
                                        , iDivisionAccountId     => null
                                        , iAFinancialAccountId   => null
                                        , iADivisionAccountId    => null
                                        , iCPNAccountId          => null
                                        , iACPNAccountId         => null
                                        , iCDAAccountId          => null
                                        , iACDAAccountId         => null
                                        , iPFAccountId           => null
                                        , iAPFAccountId          => null
                                        , iPJAccountId           => null
                                        , iAPJAccountId          => null
                                        , iFamFixedAssetsId      => null
                                        , iFamTransactionTyp     => null
                                        , iHrmPersonId           => null
                                        , iDicImpfree1Id         => null
                                        , iDicImpfree2Id         => null
                                        , iDicImpfree3Id         => null
                                        , iDicImpfree4Id         => null
                                        , iDicImpfree5Id         => null
                                        , iImpText1              => null
                                        , iImpText2              => null
                                        , iImpText3              => null
                                        , iImpText4              => null
                                        , iImpText5              => null
                                        , iImpNumber1            => null
                                        , iImpNumber2            => null
                                        , iImpNumber3            => null
                                        , iImpNumber4            => null
                                        , iImpNumber5            => null
                                        , iFinancialCharging     => null
                                        , iUpdateProv            => 0
                                        , iExtourneMvt           => 0
                                        , iRecStatus             => '8'
                                        , iOrderKey              => null
                                        , iDocFootAlloyID        => null
                                        , iInventoryMvt          => 1
                                         );
      elsif     ptab_list_pos.ilp_inventory_quantity = ptab_list_pos.ilp_system_quantity
            and ptab_list_pos.ilp_inventory_value = ptab_list_pos.ilp_system_value
            and ptab_list_pos.ilp_inv_alternativ_qty_1 = ptab_list_pos.ilp_sys_alternativ_qty_1
            and ptab_list_pos.ilp_inv_alternativ_qty_2 = ptab_list_pos.ilp_sys_alternativ_qty_2
            and ptab_list_pos.ilp_inv_alternativ_qty_3 = ptab_list_pos.ilp_sys_alternativ_qty_3
            and (PCS.PC_CONFIG.GetConfig('STM_GEN_NUL_MVT') = '1') then
        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => vMvt
                                        , iGoodId                => ptab_list_pos.gco_good_id
                                        , iMovementKindId        => pMvtKindinput
                                        , iExerciseId            => ptab_list_pos.stm_exercise_id
                                        , iPeriodId              => ptab_list_pos.stm_period_id
                                        , iMvtDate               => ptab_list_pos.ilp_inventory_date
                                        , iValueDate             => ptab_list_pos.ilp_inventory_date
                                        , iStockId               => ptab_list_pos.stm_stock_id
                                        , iLocationId            => ptab_list_pos.stm_location_id
                                        , iThirdId               => null
                                        , iThirdAciId            => null
                                        , iThirdDeliveryId       => null
                                        , iThirdTariffId         => null
                                        , iRecordId              => null
                                        , iChar1Id               => ptab_list_pos.gco_characterization_id
                                        , iChar2Id               => ptab_list_pos.gco_gco_characterization_id
                                        , iChar3Id               => ptab_list_pos.gco2_gco_characterization_id
                                        , iChar4Id               => ptab_list_pos.gco3_gco_characterization_id
                                        , iChar5Id               => ptab_list_pos.gco4_gco_characterization_id
                                        , iCharValue1            => ptab_list_pos.ilp_characterization_value_1
                                        , iCharValue2            => ptab_list_pos.ilp_characterization_value_2
                                        , iCharValue3            => ptab_list_pos.ilp_characterization_value_3
                                        , iCharValue4            => ptab_list_pos.ilp_characterization_value_4
                                        , iCharValue5            => ptab_list_pos.ilp_characterization_value_5
                                        , iMovement2Id           => null
                                        , iMovement3Id           => null
                                        , iWording               => ptab_list_pos.inv_description || ' / ' || ptab_list_pos.ili_description
                                        , iExternalDocument      => null
                                        , iExternalPartner       => null
                                        , iMvtQty                => 0
                                        , iMvtPrice              => 0
                                        , iDocQty                => 0
                                        , iDocPrice              => 0
                                        , iUnitPrice             => 0
                                        , iRefUnitPrice          => GCO_functionS.GETCOSTPRICEWITHMANAGEMENTMODE(ptab_list_pos.gco_good_id)
                                        , iAltQty1               => 0
                                        , iAltQty2               => 0
                                        , iAltQty3               => 0
                                        , iDocPositionDetailId   => null
                                        , iDocPositionId         => null
                                        , iFinancialAccountId    => null
                                        , iDivisionAccountId     => null
                                        , iAFinancialAccountId   => null
                                        , iADivisionAccountId    => null
                                        , iCPNAccountId          => null
                                        , iACPNAccountId         => null
                                        , iCDAAccountId          => null
                                        , iACDAAccountId         => null
                                        , iPFAccountId           => null
                                        , iAPFAccountId          => null
                                        , iPJAccountId           => null
                                        , iAPJAccountId          => null
                                        , iFamFixedAssetsId      => null
                                        , iFamTransactionTyp     => null
                                        , iHrmPersonId           => null
                                        , iDicImpfree1Id         => null
                                        , iDicImpfree2Id         => null
                                        , iDicImpfree3Id         => null
                                        , iDicImpfree4Id         => null
                                        , iDicImpfree5Id         => null
                                        , iImpText1              => null
                                        , iImpText2              => null
                                        , iImpText3              => null
                                        , iImpText4              => null
                                        , iImpText5              => null
                                        , iImpNumber1            => null
                                        , iImpNumber2            => null
                                        , iImpNumber3            => null
                                        , iImpNumber4            => null
                                        , iImpNumber5            => null
                                        , iFinancialCharging     => null
                                        , iUpdateProv            => 0
                                        , iExtourneMvt           => 0
                                        , iRecStatus             => '8'
                                        , iOrderKey              => null
                                        , iDocFootAlloyID        => null
                                        , iInventoryMvt          => 1
                                         );
      end if;

      if ptab_list_pos.ilp_system_quantity = 0 then   -- insert new stock position
        begin
          select SPO.STM_ELEMENT_NUMBER_DETAIL_ID
            into vElementNumberId
            from STM_STOCK_POSITION SPO
           where SPO.STM_LAST_STOCK_MOVE_ID = vMvt;
        exception
          when no_data_found then
            vElementNumberId  := null;
        end;

        if vElementNumberId is not null then
          STM_PRC_ELEMENT_NUMBER.ChangeRetestDate(vElementNumberId, ptab_list_pos.ILP_RETEST_DATE);
          STM_PRC_ELEMENT_NUMBER.ChangeStatus(vElementNumberId, ptab_list_pos.GCO_QUALITY_STATUS_ID);
        end if;
      end if;
    end if;   -- vContinue = 1
  end ValidateOnePosition;

  --
  -- procédure permettant le traitement d'une liste d'inventaire
  --
  procedure Validate_List(pStminventoryListID in stm_inventory_LIST.stm_inventory_LIST_ID%type,   -- liste à traiter
                                                                                               pValidateStatus in out varchar)   -- statut contenant le résultat du traitement
  is
    -- définition des variables
    vLastRowNumber        binary_integer;
    vTabCounter           binary_integer;
    tabinventory_list_pos stm_inventory_list_pos_type;
    vContinue             number;
    vError                number;
    vListHasError         number;
    aListPosition         crGetListPosition%rowtype;
    vConnectedUsers       number;
    vinventoryListStatus  stm_inventory_LIST.c_inventory_list_status%type;
    vinventoryType        stm_inventory_task.c_inventory_type%type;
    vActiveExerciseId     stm_exercise.stm_exercise_id%type;   -- id de l'exercice actif
    vExeStartingDate      stm_exercise.exe_starting_exercise%type;   -- date début exercice actif
    vActivePeriodId       stm_period.stm_period_id%type;   -- id de la période active
    vMvtKindReportEnt     stm_movement_kind.stm_movement_kind_id%type;   -- mouvement de report ENT
    vMvtKindReportSor     stm_movement_kind.stm_movement_kind_id%type;   -- mouvement de report SOR
    vMvtKindinput         stm_movement_kind.stm_movement_kind_id%type;   -- mouvement ENT
    vMvtKindOutput        stm_movement_kind.stm_movement_kind_id%type;   -- mouvement SOR
    vMvtKindAltCorr       stm_movement_kind.stm_movement_kind_id%type;   -- mouvement sur qté alternativ ENT
  begin
    -- init des variables
    vContinue          := 1;
    vError             := 0;
    vListHasError      := 0;
    vActiveExerciseId  := null;
    vExeStartingDate   := null;
    vActiveExerciseId  := null;
    vActivePeriodId    := null;
    vMvtKindReportSor  := null;
    vMvtKindinput      := null;
    vMvtKindOutput     := null;
    vMvtKindAltCorr    := null;
    pValidateStatus    := '101';   -- traitement ok

    -- récupération des informations de la liste à traiter
    begin
      select count_list_connected_user(pStmInventoryListId)
           , ili.c_inventory_list_status
           , inv.c_inventory_type
        into vConnectedUsers
           , vinventoryListStatus
           , vinventoryType
        from stm_inventory_list ili
           , stm_inventory_task inv
       where ili.stm_inventory_list_id = pStminventoryListId
         and ili.stm_inventory_task_id = inv.stm_inventory_task_id;
    exception
      when no_data_found then
        pValidateStatus  := '102';   -- impossible de trouver la liste de demandée
        vContinue        := 0;
    end;

    --
    -- vérifier qu'aucun utilisateur ne soit connecté et que la liste ait bien le statut attendu
    if vContinue = 1 then
      if vConnectedUsers = 0 then
        if vinventoryListStatus in('02', '03', '04', '05') then
          -- mise à jour du statut de la liste d'inventaire
          update stm_inventory_list ili
             set ili.c_inventory_list_status = '04'   -- En cours de traitement
               , A_DATEMOD = sysdate
               , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
           where ili.stm_inventory_list_id = pStminventoryListId;

          commit;

          --
          -- mise à jour des positions non traitées ayant précédemment générées une erreur lors du traitement
          update stm_inventory_list_pos ilp
             set ilp.c_inventory_error_status = null
               , A_DATEMOD = sysdate
               , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
           where ilp.stm_inventory_list_id = pStminventoryListId
             and ilp.c_inventory_error_status is not null;

          commit;
          -- recherche des genres de mouvement à utiliser
          GetAllMovementKind(vinventoryType
                           , vActiveExerciseId
                           , vExeStartingDate
                           , vActivePeriodId
                           , vMvtKindReportEnt
                           , vMvtKindReportSor
                           , vMvtKindinput
                           , vMvtKindOutput
                           , vMvtKindAltCorr
                            );
          -- ouverture du curseur sur les lignes à traiter
          vLastRowNumber  := 0;

          open crGetListPosition(pStminventoryListId);

          fetch crGetListPosition
           into aListPosition;

          while crGetListPosition%found loop
            tabinventory_list_pos(aListPosition.rownumber)  := aListPosition;
            vLastRowNumber                                  := aListPosition.rownumber;

            fetch crGetListPosition
             into aListPosition;
          end loop;

          close crGetListPosition;

          for vTabCounter in 1 .. vLastRowNumber loop
            ValidateOnePosition(tabinventory_list_pos(vTabCounter)
                              , vinventoryType
                              , vActiveExerciseId
                              , vExeStartingDate
                              , vActivePeriodId
                              , vMvtKindReportEnt
                              , vMvtKindReportSor
                              , vMvtKindinput
                              , vMvtKindOutput
                              , vMvtKindAltCorr
                              , vError
                               );

            if vError = 0 then
              -- Mise à jour position comme traitée
              update stm_inventory_list_pos ilp
                 set ilp.ilp_is_validated = 1
                   , ilp.a_datemod = sysdate
                   , ilp.A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
               where ilp.stm_inventory_list_pos_id = tabinventory_list_pos(vTabCounter).stm_inventory_list_pos_id;

              -- Mise à jour des détails
              update stm_inventory_job_detail ijd
                 set ijd.ijd_line_validated = 1
                   , ijd.a_datemod = sysdate
                   , ijd.A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
               where ijd.stm_inventory_list_pos_id = tabinventory_list_pos(vTabCounter).stm_inventory_list_pos_id;

              --
              stm_inventory.update_status_after_Treatement(tabinventory_list_pos(vTabCounter).GCO_GOOD_ID
                                                         , tabinventory_list_pos(vTabCounter).STM_STOCK_ID
                                                         , tabinventory_list_pos(vTabCounter).STM_LOCATION_ID
                                                         , tabinventory_list_pos(vTabCounter).GCO_CHARACTERIZATION_ID
                                                         , tabinventory_list_pos(vTabCounter).GCO_GCO_CHARACTERIZATION_ID
                                                         , tabinventory_list_pos(vTabCounter).GCO2_GCO_CHARACTERIZATION_ID
                                                         , tabinventory_list_pos(vTabCounter).GCO3_GCO_CHARACTERIZATION_ID
                                                         , tabinventory_list_pos(vTabCounter).GCO4_GCO_CHARACTERIZATION_ID
                                                         , tabinventory_list_pos(vTabCounter).ILP_CHARACTERIZATION_VALUE_1
                                                         , tabinventory_list_pos(vTabCounter).ILP_CHARACTERIZATION_VALUE_2
                                                         , tabinventory_list_pos(vTabCounter).ILP_CHARACTERIZATION_VALUE_3
                                                         , tabinventory_list_pos(vTabCounter).ILP_CHARACTERIZATION_VALUE_4
                                                         , tabinventory_list_pos(vTabCounter).ILP_CHARACTERIZATION_VALUE_5
                                                         , tabinventory_list_pos(vTabCounter).ILP_INVENTORY_DATE
                                                          );

              update gco_good_calc_data gcd
                 set gcd.goo_last_inventory_date = sysdate
                   , A_DATEMOD = sysdate
                   , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
               where gcd.gco_good_id = tabinventory_list_pos(vTabCounter).gco_good_id;

              commit;
            else
              vListHasError  := 1;
            end if;
          end loop;

          if vListHasError = 0 then
            update stm_inventory_list ili
               set ili.C_INVENTORY_LIST_STATUS = '06'   -- Liste traitée
                 , A_DATEMOD = sysdate
                 , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
             where ili.stm_inventory_list_id = pStminventoryListId;

            update stm_inventory_job ijo
               set ijo.IJO_JOB_AVAILABLE = 0
                 , A_DATEMOD = sysdate
                 , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
             where ijo.stm_inventory_list_id = pStminventoryListId;

            commit;
          else
            update stm_inventory_list ili
               set ili.C_INVENTORY_LIST_STATUS = '05'   -- Liste partiellement traitée
                 , A_DATEMOD = sysdate
                 , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
             where ili.stm_inventory_list_id = pStminventoryListId;

            update stm_inventory_job ijo
               set ijo.IJO_JOB_AVAILABLE = 1
                 , A_DATEMOD = sysdate
                 , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
             where ijo.stm_inventory_list_id = pStminventoryListId;

            commit;
            pValidateStatus  := '105';   -- La liste est partiellement traitée
          end if;
        else
          pValidateStatus  := '103';   -- la liste n'a pas le statut attendu [02,03,04,05]
        end if;
      else
        pValidateStatus  := '104';   -- des utilisateurs sont encore connectés à la liste
      end if;
    end if;
  end Validate_List;

  procedure Decode_inventory(astm_inventory_External_Id stm_inventory_External.stm_inventory_External_id%type, aDecodeprocedure varchar2, aPartDecode number)
  is
    vSqlCommand varchar2(2000);
    vDynamicCr  integer;
    vErrorCr    integer;
  begin
    vSqlCommand  :=
                   'begin ' || aDecodeprocedure || '(' || to_char(astm_inventory_External_Id, 'FM999999999999') || ',' || to_char(aPartDecode) || ');'
                   || ' END;';
    vDynamicCr   := DBMS_SQL.open_cursor;   -- Demande de curseur
    DBMS_SQL.parse(vDynamicCr, vSqlCommand, DBMS_SQL.native);   -- Vérification de la syntaxe
    vErrorCr     := DBMS_SQL.execute(vDynamicCr);   -- Execution
    DBMS_SQL.close_cursor(vDynamicCr);   -- Ferme le curseur
  end decode_inventory;

  function GetStockIdFromLocationId(aStm_location_id stm_location.stm_location_id%type)
    return number
  is
    vReturnValue number;
  begin
    vReturnValue  := 0;

    select nvl(max(stm_stock_id), 0)
      into vReturnValue
      from stm_location
     where stm_location_id = aStm_location_id;

    return vReturnValue;
  end GetStockIdFromLocationId;

  function GetStockAccessMethod(aStm_stock_id stm_stock.stm_stock_id%type)
    return varchar2
  is
    vReturnValue varchar2(10);
  begin
    vReturnValue  := null;

    select max(c_access_method)
      into vReturnValue
      from stm_stock
     where stm_stock_id = aStm_stock_id;

    return vReturnValue;
  end GetStockAccessMethod;

  function HasCharactTypeOf(pCaractType varchar2, pGco_good_id gco_good.gco_good_id%type)
    return boolean
  is
    vCharactId number;
  begin
    if pCaractType = '3' then
      begin
        select cha.gco_characterization_id
          into vCharactId
          from gco_characterization cha
             , gco_product pdt
         where pdt.gco_good_id = pGco_good_id
           and cha.gco_good_id = pdt.gco_good_id
           and cha.c_charact_type = pCaractType
           and cha.cha_stock_management = 1
           and pdt.pdt_stock_management = 1;

        return true;
      exception
        when no_data_found then
          return false;
      end;
    end if;
  end HasCharactTypeOf;

  function Verify_External_inventory_Test(
    ainventory_External_Lines crinventory_External_Lines_1%rowtype
  , aTestType                 stm_inventory_external_line.C_INVENTORY_EXT_LinE_STATUS%type
  )
    return boolean
  is
    vReturnValue boolean;
    vTestId      number;
  begin
    vReturnValue  := false;

    if aTestType = '101' then   -- référence principale inconnue
      vReturnValue  :=     ainventory_External_Lines.gco_good_id is null
                       and ainventory_External_Lines.iex_major_reference is not null;
    elsif aTestType = '102' then   -- pas de référence principale
      vReturnValue  :=     ainventory_External_Lines.gco_good_id is null
                       and ainventory_External_Lines.iex_major_reference is null;
    elsif aTestType = '103' then   -- valeur de caractérisation 1 manquante
      vReturnValue  :=     ainventory_External_Lines.gco_characterization_id is not null
                       and ainventory_External_Lines.iex_characterization_value_1 is null;
    elsif aTestType = '104' then   -- valeur de caractérisation 2 manquante
      vReturnValue  :=     ainventory_External_Lines.gco_gco_characterization_id is not null
                       and ainventory_External_Lines.iex_characterization_value_2 is null;
    elsif aTestType = '105' then   -- valeur de caractérisation 3 manquante
      vReturnValue  :=     ainventory_External_Lines.gco2_gco_characterization_id is not null
                       and ainventory_External_Lines.iex_characterization_value_3 is null;
    elsif aTestType = '106' then   -- valeur de caractérisation 4 manquante
      vReturnValue  :=     ainventory_External_Lines.gco3_gco_characterization_id is not null
                       and ainventory_External_Lines.iex_characterization_value_4 is null;
    elsif aTestType = '107' then   -- valeur de caractérisation 5 manquante
      vReturnValue  :=     ainventory_External_Lines.gco4_gco_characterization_id is not null
                       and ainventory_External_Lines.iex_characterization_value_5 is null;
    elsif aTestType = '108' then   -- stock inconnue
      vReturnValue  := ainventory_External_Lines.stm_stock_id is null;
    elsif aTestType = '109' then   -- emplacement inconnu
      vReturnValue  := ainventory_External_Lines.stm_location_id is null;
    elsif aTestType = '110' then   -- couple "stock/emplacement" erroné
      vReturnValue  := GetStockIdFromLocationId(ainventory_External_Lines.stm_location_id) <> ainventory_External_Lines.stm_stock_id;
    elsif aTestType = '111' then   -- Stock privé
      vReturnValue  := GetStockAccessMethod(ainventory_External_Lines.stm_stock_id) <> 'PUBLIC';
    elsif aTesttype = '112' then   -- doublon dans les descriptions des emplacements
      vReturnValue  :=     ainventory_external_lines.stm_location_id is null
                       and ainventory_External_Lines.stm_stock_id is null;
    elsif aTestType = '119' then   -- prix unitaire négatif
      vReturnValue  :=     (cfgUseUnitPrice = '1')
                       and (ainventory_External_Lines.IEX_UNIT_PRICE < 0);
    elsif aTestType = '120' then   -- quantité négative
      vReturnValue  := ainventory_External_Lines.iex_quantity < 0;
    elsif aTestType = '121' then   -- n° de série et quantité <> 1  ou <> 0
      if HasCharactTypeOf('3', ainventory_External_Lines.gco_good_id) then
        if    ainventory_External_Lines.iex_quantity = 0
           or aInventory_External_Lines.iex_quantity = 1 then
          vReturnValue  := false;
        else
          vReturnValue  := true;
        end if;
      end if;
    elsif aTestType = '122' then   -- quantité nulle
      vReturnValue  := ainventory_External_Lines.iex_quantity is null;
    elsif aTestType = '207' then   -- Format de caractérisation incorrecte.
      vReturnValue  :=
        not pCheckCharactFormat(ainventory_External_Lines.GCO_CHARACTERIZATION_ID
                              , ainventory_External_Lines.IEX_CHARACTERIZATION_VALUE_1
                              , ainventory_External_Lines.GCO_GCO_CHARACTERIZATION_ID
                              , ainventory_External_Lines.IEX_CHARACTERIZATION_VALUE_2
                              , ainventory_External_Lines.GCO2_GCO_CHARACTERIZATION_ID
                              , ainventory_External_Lines.IEX_CHARACTERIZATION_VALUE_3
                              , ainventory_External_Lines.GCO3_GCO_CHARACTERIZATION_ID
                              , ainventory_External_Lines.IEX_CHARACTERIZATION_VALUE_4
                              , ainventory_External_Lines.GCO4_GCO_CHARACTERIZATION_ID
                              , ainventory_External_Lines.IEX_CHARACTERIZATION_VALUE_5
                               );
    end if;

    return vReturnValue;
  end Verify_External_inventory_Test;

  procedure Verify_external_inventory(astm_inventory_External_Id stm_inventory_External.stm_inventory_External_id%type)
  is
    type DecodedLineRec is record(
      inv_Gco1_characterization_id number(12)
    , inv_Gco2_characterization_id number(12)
    , inv_Gco3_characterization_id number(12)
    , inv_Gco4_characterization_id number(12)
    , inv_Gco5_characterization_id number(12)
    , inv_CharType_1               varchar2(10)
    , inv_CharType_2               varchar2(10)
    , inv_CharType_3               varchar2(10)
    , inv_CharType_4               varchar2(10)
    , inv_CharType_5               varchar2(10)
    );

    tplinventory_External_Lines crinventory_External_Lines_1%rowtype;
    vinventory_Ext_Line_Status  stm_inventory_external_line.C_INVENTORY_EXT_LinE_STATUS%type;
    vinv_ext_line_error_status  stm_inventory_external_line.C_inV_EXT_LinE_ERROR_STATUS%type;
    vDecodedLine                DecodedLineRec;
    vDummyChar                  varchar2(100);
  begin
    open crinventory_External_Lines_1(astm_inventory_External_Id);

    fetch crinventory_External_Lines_1
     into tplinventory_External_Lines;

    while crinventory_External_Lines_1%found loop
      GCO_functionS.GetListOfStkChar(tplinventory_External_Lines.gco_good_id
                                   , vDecodedLine.inv_Gco1_Characterization_id
                                   , vDecodedLine.inv_Gco2_characterization_id
                                   , vDecodedLine.inv_Gco3_Characterization_id
                                   , vDecodedLine.inv_Gco4_Characterization_id
                                   , vDecodedLine.inv_Gco5_Characterization_id
                                   , vDecodedLine.inv_CharType_1
                                   , vDecodedLine.inv_CharType_2
                                   , vDecodedLine.inv_CharType_3
                                   , vDecodedLine.inv_CharType_4
                                   , vDecodedLine.inv_CharType_5
                                   ,
                                     -- les valeurs retournées pour les "descriptions" de caractérisations
                                     -- ne sont pas utilisées
                                     vDummyChar
                                   , vDummyChar
                                   , vDummyChar
                                   , vDummyChar
                                   , vDummyChar
                                    );

      -- effacement des ID et des valeurs de caractérisations inutiles (ne correspondant pas une caractérisation)
      if vDecodedLine.inv_Gco1_characterization_id is null then
        tplinventory_External_Lines.gco_characterization_id       := null;
        tplinventory_External_Lines.iex_characterization_value_1  := null;
      end if;

      if vDecodedLine.inv_Gco2_characterization_id is null then
        tplinventory_External_Lines.gco_gco_characterization_id   := null;
        tplinventory_External_Lines.iex_characterization_value_2  := null;
      end if;

      if vDecodedLine.inv_Gco3_characterization_id is null then
        tplinventory_External_Lines.gco2_gco_characterization_id  := null;
        tplinventory_External_Lines.iex_characterization_value_3  := null;
      end if;

      if vDecodedLine.inv_Gco4_characterization_id is null then
        tplinventory_External_Lines.gco3_gco_characterization_id  := null;
        tplinventory_External_Lines.iex_characterization_value_4  := null;
      end if;

      if vDecodedLine.inv_Gco5_characterization_id is null then
        tplinventory_External_Lines.gco4_gco_characterization_id  := null;
        tplinventory_External_Lines.iex_characterization_value_5  := null;
      end if;

      -- statut par défaut
      vinventory_Ext_Line_Status  := '001';   -- à intégrer
      vinv_ext_line_error_status  := '001';   -- à vérifier

      if Verify_External_inventory_Test(tplinventory_External_Lines, '101') then
        vinv_ext_line_error_status  := '101';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '102') then
        vinv_ext_line_error_status  := '102';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '103') then
        vinv_ext_line_error_status  := '103';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '104') then
        vinv_ext_line_error_status  := '104';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '105') then
        vinv_ext_line_error_status  := '105';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '106') then
        vinv_ext_line_error_status  := '106';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '107') then
        vinv_ext_line_error_status  := '107';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '112') then
        vinv_ext_line_error_status  := '112';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '108') then
        vinv_ext_line_error_status  := '108';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '109') then
        vinv_ext_line_error_status  := '109';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '110') then
        vinv_ext_line_error_status  := '110';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '111') then
        vinv_ext_line_error_status  := '111';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '119') then
        vinv_ext_line_error_status  := '119';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '120') then
        vinv_ext_line_error_status  := '120';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '121') then
        vinv_ext_line_error_status  := '121';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '122') then
        vinv_ext_line_error_status  := '122';
      elsif Verify_External_inventory_Test(tplinventory_External_Lines, '207') then
        vinv_ext_line_error_status  := '207';
      end if;

      if vinv_ext_line_error_status = '001' then
        vinv_ext_line_error_status  := '003';
      end if;

      update stm_inventory_external_line
         set c_inv_ext_line_error_status = vinv_ext_line_error_status
           , c_inventory_ext_line_status = decode(vinv_ext_line_error_status, '003', '003', '100')
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
       where stm_inventory_external_line_id = tplinventory_External_Lines.stm_inventory_external_line_id;

      fetch crinventory_External_Lines_1
       into tplinventory_External_Lines;
    end loop;

    close crinventory_External_Lines_1;
  end Verify_external_inventory;

  function GetinventoryJob02Id(aTableName varchar2, aId number)
    return number
  is
    vstm_inventory_job_id stm_inventory_job.stm_inventory_job_id%type;
  begin
    vstm_inventory_job_id  := 0;

    if aTableName = 'STM_INVENTORY_LIST_POS' then
      select nvl(max(ijo.stm_inventory_job_id), 0)
        into vstm_inventory_job_id
        from stm_inventory_list_Pos ilp
           , stm_inventory_job ijo
       where ilp.stm_inventory_list_pos_id = aId
         and ilp.stm_inventory_list_id = ijo.stm_inventory_list_id
         and ijo.c_inventory_job_type = '02';
    elsif aTableName = 'STM_INVENTORY_LIST' then
      select nvl(max(ijo.stm_inventory_job_id), 0)
        into vstm_inventory_job_id
        from stm_inventory_job ijo
       where ijo.stm_inventory_list_id = aId;
    end if;

    return vstm_inventory_job_id;
  end GetinventoryJob02Id;

  function GetinventoryListId(aTableName varchar2, aId number, aIsDefaultList boolean)
    return number
  is
    vId number;
  begin
    vId  := 0;

    if aTableName = 'STM_INVENTORY_LIST_POS' then
      select nvl(max(stm_inventory_list_id), 0)
        into vId
        from stm_inventory_list_pos
       where stm_inventory_list_pos_id = aId;
    elsif     aTableName = 'STM_INVENTORY_LIST'
          and aIsDefaultList = true then
      select nvl(max(ili.stm_inventory_list_id), 0)
        into vId
        from stm_inventory_list ili
       where stm_inventory_external_id = aId
         and ili.c_inventory_list_status = '03';
    end if;

    return vId;
  end GetinventoryListId;

  procedure Generate_external_inventory(astm_inventory_External_Id stm_inventory_External.stm_inventory_External_id%type)
  is
    /**
    * curseur récupérant toutes les lignes intégrables d'une intégration
    */
    cursor crinventory_External_Lines(cstm_inventory_External_Id stm_inventory_External.stm_inventory_External_id%type)
    is
      select rownum rownumber
           , v.*
        from (select   stm_inventory_external_line_id
                     , C_inventory_Ext_Line_Status
                     , Gco_Good_Id
                     , Stm_Location_Id
                     , Stm_Stock_Id
                     , Iex_Major_Reference
                     , Iex_Sto_Description
                     , Iex_Loc_Description
                     , Iex_Characterization_Value_1
                     , Iex_Characterization_Value_2
                     , Iex_Characterization_Value_3
                     , Iex_Characterization_Value_4
                     , Iex_Characterization_Value_5
                     , Iex_Quantity
                     , Iex_User_Name
                     , Iex_input_Line
                     , Gco_Characterization_Id
                     , Gco_Gco_Characterization_Id
                     , Gco2_Gco_Characterization_Id
                     , Gco3_Gco_Characterization_Id
                     , Gco4_Gco_Characterization_Id
                     , stm_inventory_External_Id
                     , iex_free_date1
                     , iex_free_date2
                     , iex_free_date3
                     , iex_free_date4
                     , iex_free_date5
                     , iex_free_text1
                     , iex_free_text2
                     , iex_free_text3
                     , iex_free_text4
                     , iex_free_text5
                     , iex_free_number1
                     , iex_free_number2
                     , iex_free_number3
                     , iex_free_number4
                     , iex_free_number5
                     , iex_unit_price
                  from stm_inventory_external_line
                 where stm_inventory_external_id = cstm_inventory_External_Id
                   and c_inventory_ext_line_status in('003', '300')
                   and iex_is_validated = 0
              order by gco_good_id) v;

/**
*   curseur récupérant les caractérisations de type version (1), pièce (3), lot (4)
*   ordonné par ordre des caractérisations
*/
    cursor crGco_characterization_type(cGco_good_id gco_good.gco_good_id%type)
    is
      select   gco_characterization_id
             , c_charact_type
          from gco_characterization
         where gco_good_id = cGco_good_id
           and CHA_STOCK_MANAGEMENT = 1
           and C_CHARACT_TYPE in('1', '3', '4')
      order by gco_characterization_id asc;

    type stm_inventory_external_type is table of crinventory_External_Lines%rowtype
      index by binary_integer;

-- définition des variables
    vLastRowNumber               binary_integer;
    vTabCounter                  binary_integer;
    tabinventory_external        stm_inventory_external_type;
    tplinventory_External_Lines  crinventory_External_Lines%rowtype;
    tplGco_characterization_type crGco_characterization_type%rowtype;
    lInvExtLineErrorStatus       stm_inventory_external_line.C_INV_EXT_LINE_ERROR_STATUS%type;
    lInventoryExtLineStatus      stm_inventory_external_line.C_INVENTORY_EXT_LINE_STATUS%type;
    vstm_inventory_Task_Id       stm_inventory_Task.stm_inventory_task_id%type;
    vstm_inventory_List_Id       stm_inventory_List.stm_inventory_List_Id%type;
    vstm_inventory_list_pos_id   stm_inventory_list_pos.stm_inventory_list_pos_id%type;
    vstm_inventory_job_id        stm_inventory_job.stm_inventory_job_id%type;
    vStm_stock_position_id       Stm_stock_position.stm_stock_position_id%type;
    vIxt_description             stm_inventory_external.ixt_description%type;
    vDflt_stm_inventory_List_Id  stm_inventory_List.stm_inventory_List_Id%type;
    vDflt_stm_inventory_job_id   stm_inventory_job.stm_inventory_job_id%type;
    vStm_inventory_external_id   stm_inventory_external.stm_inventory_external_id%type;
    vStm_period_id               Stm_period.stm_period_id%type;
    vC_inventory_type            stm_inventory_task.c_inventory_type%type;
    vStm_element_number_id       stm_element_number.stm_element_number_id%type;
    vStm_stm_element_number_id   stm_element_number.stm_element_number_id%type;
    vStm2_stm_element_number_id  stm_element_number.stm_element_number_id%type;
    vFoundSetElemId              stm_element_number.stm_element_number_id%type;
    vFoundVerElemId              stm_element_number.stm_element_number_id%type;
    vFoundPceElemId              stm_element_number.stm_element_number_id%type;
    vC_ele_num_status_1          stm_element_number.c_ele_num_status%type;
    vC_ele_num_status_2          stm_element_number.c_ele_num_status%type;
    vC_ele_num_status_3          stm_element_number.c_ele_num_status%type;
    vFoundSetElemStat            stm_element_number.c_ele_num_status%type;
    vFoundVerElemStat            stm_element_number.c_ele_num_status%type;
    vFoundPceElemStat            stm_element_number.c_ele_num_status%type;
    vChartyp1                    gco_characterization.c_charact_type%type;
    vChartyp2                    gco_characterization.c_charact_type%type;
    vChartyp3                    gco_characterization.c_charact_type%type;
    vChartyp4                    gco_characterization.c_charact_type%type;
    vChartyp5                    gco_characterization.c_charact_type%type;
    vError                       number;
    vCounter                     number;
-- définition des exceptions
    inv_qty_must_be_1            exception;
    inv_same_pos_exist_in_inv    exception;
    inv_pce_elem_exist_in_inv    exception;
    inv_pce_elem_exist_in_stk    exception;
    inv_pce_elem_exist           exception;
    inv_set_elem_exist           exception;
    inv_bad_char_format          exception;
    inv_negative_price           exception;
    pragma exception_init(inv_qty_must_be_1, -20901);
    pragma exception_init(inv_same_pos_exist_in_inv, -20902);
    pragma exception_init(inv_pce_elem_exist_in_inv, -20903);
    pragma exception_init(inv_pce_elem_exist_in_stk, -20904);
    pragma exception_init(inv_pce_elem_exist, -20905);
    pragma exception_init(inv_set_elem_exist, -20906);
    pragma exception_init(inv_bad_char_format, -20907);
    pragma exception_init(inv_negative_price, -20908);
  begin
/**
* Vérification des données à intégrer
* Cette vérification peut paraître comme un doublon mais elle est rendue
* nécessaire pour des motifs de sécurité des données
*/
    Verify_external_inventory(astm_inventory_External_Id);

-- récupération de l'Id de l'inventaire, période de l'inventaire, type d'inventaire
    select ixt.stm_inventory_task_id
         , inv.stm_period_id
         , inv.c_inventory_type
         , ixt.ixt_description
         , ixt.stm_inventory_external_id
      into vstm_inventory_Task_Id
         , vStm_period_id
         , vC_inventory_type
         , vIxt_description
         , vStm_inventory_external_id
      from stm_inventory_external ixt
         , stm_inventory_task inv
     where ixt.stm_inventory_external_id = astm_inventory_External_Id
       and ixt.stm_inventory_task_id = inv.stm_inventory_task_id;

-- recherche de l'extraction par défaut utilisée pour stocker les positions
-- de stock non extraites
    vDflt_stm_inventory_List_Id  := GetinventoryListId('STM_INVENTORY_LIST', vStm_inventory_external_id, true);
    vDflt_stm_inventory_job_id   := GetinventoryJob02Id('STM_INVENTORY_LIST', vDflt_stm_inventory_List_Id);

    if vDflt_stm_inventory_List_Id = 0 then
      /**
      * l'extraction en statut '03' utilisée pour stocker les positions de stock non extraites
      * n'existe pas
      *
      * Création d'une extraction pour les positions de stock inventoriées
      * qui n'auraient pas été extraites sur d'autres extractions
      */
      select init_id_seq.nextval
        into vDflt_stm_inventory_List_Id
        from dual;

      insert into stm_inventory_list
                  (stm_inventory_LIST_ID
                 , C_INVENTORY_LIST_STATUS
                 , PC_SQLST_ID
                 , ILI_DESCRIPTION
                 , ILI_REMARK
                 , ILI_FORCE_SQLSTID
                 , A_DATECRE
                 , A_IDCRE
                 , stm_inventory_TASK_ID
                 , stm_inventory_external_id
                  )
        select vDflt_stm_inventory_List_Id
             , '03'
             , sqlst.pc_sqlst_id
             , pcs.pc_functions.TRANSLATEWORD('STM_EXTERNAL_INV', pcs.PC_I_LIB_SESSION.getuserlangid) ||
               ' : ' ||
               vIxt_description ||
               ' (' ||
               to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS') ||
               ')'
             , null
             , 0
             , sysdate
             , pcs.PC_I_LIB_SESSION.getuserini
             , vstm_inventory_task_id
             , vStm_inventory_external_id
          from pcs.pc_sqlst sqlst
             , pcs.pc_table tab
         where sqlst.pc_table_id = tab.pc_table_id
           and sqlst.C_SQGTYPE = 'INVENTORY_SORT'
           and sqlst.sqlid = pcs.pc_config.GETCONFIG('STM_INVENTORY_DEFL_SORT_SQLID')
           and tab.tabname = 'STM_INVENTORY_LIST_WORK';

      -- Création du job lié à l'extraction destinée aux positions de stock non extraites
      vDflt_stm_inventory_job_id  :=
        CreateNewJob(vDflt_stm_inventory_List_Id
                   , vstm_inventory_task_id
                   , '02'
                   , pcs.pc_functions.TRANSLATEWORD('STM_INV_JOB_AUTO_GENERATED', pcs.PC_I_LIB_SESSION.getuserlangid) ||
                     ' (' ||
                     to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS') ||
                     ')'
                   , pcs.PC_I_LIB_SESSION.getuserid
                    );
    end if;

-- ouverture du curseur sur les lignes à traiter
    vLastRowNumber               := 0;

    update stm_inventory_list ili
       set ili.c_inventory_list_status = '03'
         , A_DATEMOD = sysdate
         , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
     where ili.stm_inventory_list_id = vDflt_stm_inventory_List_Id;

    open crinventory_External_Lines(astm_inventory_External_Id);

    fetch crinventory_External_Lines
     into tplinventory_External_Lines;

    while crinventory_External_Lines%found loop
      tabinventory_external(tplinventory_External_Lines.rownumber)  := tplinventory_External_Lines;
      vLastRowNumber                                                := tplinventory_External_Lines.rownumber;

      fetch crinventory_External_Lines
       into tplinventory_External_Lines;
    end loop;

    close crinventory_External_Lines;

    for vTabCounter in 1 .. vLastRowNumber loop
      vError                      := 0;
      -- recherche d'une position d'inventaire correspondant à la ligne en cours
      -- de traitement
      vstm_inventory_list_pos_id  :=
        ExistSamePos('STM_INVENTORY_LIST_POS'
                   , tabinventory_external(vTabCounter).gco_good_id
                   , tabinventory_external(vTabCounter).stm_stock_id
                   , tabinventory_external(vTabCounter).stm_location_id
                   , nvl(tabinventory_external(vTabCounter).gco_characterization_id, 0)
                   , nvl(tabinventory_external(vTabCounter).gco_gco_characterization_id, 0)
                   , nvl(tabinventory_external(vTabCounter).gco2_gco_characterization_id, 0)
                   , nvl(tabinventory_external(vTabCounter).gco3_gco_characterization_id, 0)
                   , nvl(tabinventory_external(vTabCounter).gco4_gco_characterization_id, 0)
                   , tabinventory_external(vTabCounter).iex_characterization_value_1
                   , tabinventory_external(vTabCounter).iex_characterization_value_2
                   , tabinventory_external(vTabCounter).iex_characterization_value_3
                   , tabinventory_external(vTabCounter).iex_characterization_value_4
                   , tabinventory_external(vTabCounter).iex_characterization_value_5
                    );

      if vstm_inventory_list_pos_id <> 0 then
        -- recherche de l'extraction liée à la position d'inventaire trouvée
        vstm_inventory_List_Id  := GetinventoryListId('STM_INVENTORY_LIST_POS', vstm_inventory_list_pos_id, false);
        -- recherche du job de type "code barres" lié à la position d'inventaire trouvée
        vstm_inventory_job_id   := GetinventoryJob02Id('STM_INVENTORY_LIST_POS', vstm_inventory_list_pos_id);

        -- création de l'éventuel job s'il n'en existe aucun du type 02 pour la liste trouvée
        if vstm_inventory_job_id = 0 then
          vstm_inventory_job_id  :=
            CreateNewJob(vstm_inventory_List_Id
                       , vstm_inventory_task_id
                       , '02'
                       , pcs.pc_functions.TRANSLATEWORD('STM_INV_JOB_AUTO_GENERATED', pcs.PC_I_LIB_SESSION.getuserlangid) ||
                         ' (' ||
                         to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS') ||
                         ')'
                       , pcs.PC_I_LIB_SESSION.getuserid
                        );
        end if;

        -- insertion d'un détail dans le job trouvé / créé
        insert into stm_inventory_job_detail
                    (stm_inventory_job_detail_id
                   , stm_inventory_job_id
                   , stm_inventory_list_id
                   , gco_good_id
                   , stm_location_id
                   , stm_stock_id
                   , gco_characterization_id
                   , gco_gco_characterization_id
                   , gco2_gco_characterization_id
                   , gco3_gco_characterization_id
                   , gco4_gco_characterization_id
                   , ijd_quantity
                   , ijd_value
                   , ijd_unit_price
                   , ijd_wording
                   , ijd_characterization_value_1
                   , ijd_characterization_value_2
                   , ijd_characterization_value_3
                   , ijd_characterization_value_4
                   , ijd_characterization_value_5
                   , ijd_line_validated
                   , ijd_line_in_use
                   , ijd_input_user_name
                   , a_datecre
                   , a_idcre
                   , stm_inventory_task_id
                   , stm_inventory_list_pos_id
                   , ijd_alternativ_qty_1
                   , ijd_alternativ_qty_2
                   , ijd_alternativ_qty_3
                   , ijd_free_date1
                   , ijd_free_date2
                   , ijd_free_date3
                   , ijd_free_date4
                   , ijd_free_date5
                   , ijd_retest_date
                   , ijd_free_text1
                   , ijd_free_text2
                   , ijd_free_text3
                   , ijd_free_text4
                   , ijd_free_text5
                   , ijd_free_number1
                   , ijd_free_number2
                   , ijd_free_number3
                   , ijd_free_number4
                   , ijd_free_number5
                    )
          select init_id_seq.nextval
               , vstm_inventory_job_id
               , vstm_inventory_list_id
               , tabinventory_external(vTabCounter).gco_good_id
               , tabinventory_external(vTabCounter).stm_location_id
               , tabinventory_external(vTabCounter).stm_stock_id
               , tabinventory_external(vTabCounter).gco_characterization_id
               , tabinventory_external(vTabCounter).gco_gco_characterization_id
               , tabinventory_external(vTabCounter).gco2_gco_characterization_id
               , tabinventory_external(vTabCounter).gco3_gco_characterization_id
               , tabinventory_external(vTabCounter).gco4_gco_characterization_id
               , tabinventory_external(vTabCounter).iex_quantity
               , case
                   when cfgUseUnitPrice = '1' then tabinventory_external(vTabCounter).iex_unit_price
                   else ilp.ilp_system_unit_price
                 end *
                 tabinventory_external(vTabCounter).iex_quantity
               , case
                   when cfgUseUnitPrice = '1' then tabinventory_external(vTabCounter).iex_unit_price
                   else ilp.ilp_system_unit_price
                 end
               , null
               , tabinventory_external(vTabCounter).iex_characterization_value_1
               , tabinventory_external(vTabCounter).iex_characterization_value_2
               , tabinventory_external(vTabCounter).iex_characterization_value_3
               , tabinventory_external(vTabCounter).iex_characterization_value_4
               , tabinventory_external(vTabCounter).iex_characterization_value_5
               , 0
               , 0
               , pcs.PC_I_LIB_SESSION.getuserini
               , sysdate
               , pcs.PC_I_LIB_SESSION.getuserini
               , vstm_inventory_task_id
               , vstm_inventory_list_pos_id
               , 0
               , 0
               , 0
               , tabinventory_external(vTabCounter).iex_free_date1
               , tabinventory_external(vTabCounter).iex_free_date2
               , tabinventory_external(vTabCounter).iex_free_date3
               , tabinventory_external(vTabCounter).iex_free_date4
               , tabinventory_external(vTabCounter).iex_free_date5
               , GCO_I_LIB_CHARACTERIZATION.GetInitialRetestDelay(tabinventory_external(vTabCounter).gco_good_id, sysdate)
               , tabinventory_external(vTabCounter).iex_free_text1
               , tabinventory_external(vTabCounter).iex_free_text2
               , tabinventory_external(vTabCounter).iex_free_text3
               , tabinventory_external(vTabCounter).iex_free_text4
               , tabinventory_external(vTabCounter).iex_free_text5
               , tabinventory_external(vTabCounter).iex_free_number1
               , tabinventory_external(vTabCounter).iex_free_number2
               , tabinventory_external(vTabCounter).iex_free_number3
               , tabinventory_external(vTabCounter).iex_free_number4
               , tabinventory_external(vTabCounter).iex_free_number5
            from stm_inventory_list_pos ilp
           where ilp.stm_inventory_list_pos_id = vstm_inventory_list_pos_id;

        update stm_inventory_external_line
           set c_inventory_ext_line_status = '002'
             , c_inv_ext_line_error_status = '002'
             , iex_is_validated = 1
             , A_DATEMOD = sysdate
             , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
         where stm_inventory_external_line_id = tabinventory_external(vTabCounter).stm_inventory_external_line_id;
      else
        /**
        * pas de position d'inventaire correspond à la ligne "code barre",
        * recherche d'une position de stock qui, si elle est existante. sera extraite et mise
        * en inventaire
        */
        vStm_stock_position_id  :=
          ExistSamePos('STM_STOCK_POSITION'
                     , tabinventory_external(vTabCounter).gco_good_id
                     , tabinventory_external(vTabCounter).stm_stock_id
                     , tabinventory_external(vTabCounter).stm_location_id
                     , nvl(tabinventory_external(vTabCounter).gco_characterization_id, 0)
                     , nvl(tabinventory_external(vTabCounter).gco_gco_characterization_id, 0)
                     , nvl(tabinventory_external(vTabCounter).gco2_gco_characterization_id, 0)
                     , nvl(tabinventory_external(vTabCounter).gco3_gco_characterization_id, 0)
                     , nvl(tabinventory_external(vTabCounter).gco4_gco_characterization_id, 0)
                     , tabinventory_external(vTabCounter).iex_characterization_value_1
                     , tabinventory_external(vTabCounter).iex_characterization_value_2
                     , tabinventory_external(vTabCounter).iex_characterization_value_3
                     , tabinventory_external(vTabCounter).iex_characterization_value_4
                     , tabinventory_external(vTabCounter).iex_characterization_value_5
                      );

        if vStm_stock_position_id <> 0 then
          /**
          * Position de stock trouvée
          *
          * Création d'une position d'inventaire, sur l'extraction par défaut, par extraction
          * de la position de stock
          *
          */
          CreateNewListPosition(vstm_inventory_list_pos_id
                              , vDflt_stm_inventory_job_id
                              , vDflt_stm_inventory_List_Id
                              , vstm_inventory_task_id
                              , vStm_period_id
                              , vC_inventory_type
                              , sysdate
                              , null   -- gco_good_id
                              , null   -- stm_stock_id
                              , null   -- stm_location_id
                              --null, -- stm_element_number_id
                              --null, -- stm_stm_element_number_id
                              --null, -- stm2_stm_element_number_id
          ,                     null   -- gco_characterization_id
                              , null   -- gco_gco_characterization_id
                              , null   -- gco2_gco_characterization_id
                              , null   -- gco3_gco_characterization_id
                              , null   -- gco4_gco_characterization_id
                              , vStm_stock_position_id
                              , 0   -- valeur inventaire
                              , 0   -- qté inventaire
                              , 0   -- prix unitaire
                              , 0   -- qté alt 1
                              , 0   -- qté alt 2
                              , 0   -- qté alt 3
                              , null   -- commentaire
                              , null   -- statut stm_element_number_1
                              , null   -- statut stm_element_number_1
                              , null   -- statut stm_element_number_1
                              , null   -- characterization_value_1
                              , null   -- characterization_value_2
                              , null   -- characterization_value_3
                              , null   -- characterization_value_4
                              , null   -- characterization_value_4
                              , null   -- date de réanalyse
                              , null   -- status qualité
                               );

          -- insertion d'un détail dans le job
          insert into stm_inventory_job_detail
                      (stm_inventory_job_detail_id
                     , stm_inventory_job_id
                     , stm_inventory_list_id
                     , gco_good_id
                     , stm_stock_id
                     , stm_location_id
                     , gco_characterization_id
                     , gco_gco_characterization_id
                     , gco2_gco_characterization_id
                     , gco3_gco_characterization_id
                     , gco4_gco_characterization_id
                     , ijd_quantity
                     , ijd_value
                     , ijd_unit_price
                     , ijd_wording
                     , ijd_characterization_value_1
                     , ijd_characterization_value_2
                     , ijd_characterization_value_3
                     , ijd_characterization_value_4
                     , ijd_characterization_value_5
                     , ijd_line_validated
                     , ijd_line_in_use
                     , ijd_input_user_name
                     , a_datecre
                     , a_idcre
                     , stm_inventory_task_id
                     , stm_inventory_list_pos_id
                     , ijd_alternativ_qty_1
                     , ijd_alternativ_qty_2
                     , ijd_alternativ_qty_3
                     , ijd_free_date1
                     , ijd_free_date2
                     , ijd_free_date3
                     , ijd_free_date4
                     , ijd_free_date5
                     , ijd_retest_date
                     , ijd_free_text1
                     , ijd_free_text2
                     , ijd_free_text3
                     , ijd_free_text4
                     , ijd_free_text5
                     , ijd_free_number1
                     , ijd_free_number2
                     , ijd_free_number3
                     , ijd_free_number4
                     , ijd_free_number5
                      )
            select init_id_seq.nextval
                 , vDflt_stm_inventory_job_id
                 , vDflt_stm_inventory_list_id
                 , tabinventory_external(vTabCounter).GCO_GOOD_ID
                 , tabinventory_external(vTabCounter).STM_STOCK_ID
                 , tabinventory_external(vTabCounter).STM_LOCATION_ID
                 , tabinventory_external(vTabCounter).GCO_CHARACTERIZATION_ID
                 , tabinventory_external(vTabCounter).GCO_GCO_CHARACTERIZATION_ID
                 , tabinventory_external(vTabCounter).GCO2_GCO_CHARACTERIZATION_ID
                 , tabinventory_external(vTabCounter).GCO3_GCO_CHARACTERIZATION_ID
                 , tabinventory_external(vTabCounter).GCO4_GCO_CHARACTERIZATION_ID
                 , tabinventory_external(vTabCounter).iex_quantity
                 , case
                     when cfgUseUnitPrice = '1' then tabinventory_external(vTabCounter).iex_unit_price
                     else ilp.ilp_system_unit_price
                   end *
                   tabinventory_external(vTabCounter).iex_quantity
                 , case
                     when cfgUseUnitPrice = '1' then tabinventory_external(vTabCounter).iex_unit_price
                     else ilp.ilp_system_unit_price
                   end
                 , null
                 , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_1
                 , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_2
                 , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_3
                 , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_4
                 , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_5
                 , 0
                 , 0
                 , PCS.PC_I_LIB_SESSION.GetUserini
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserini
                 , vstm_inventory_task_id
                 , vstm_inventory_list_pos_id
                 , 0
                 , 0
                 , 0
                 , tabinventory_external(vTabCounter).iex_free_date1
                 , tabinventory_external(vTabCounter).iex_free_date2
                 , tabinventory_external(vTabCounter).iex_free_date3
                 , tabinventory_external(vTabCounter).iex_free_date4
                 , tabinventory_external(vTabCounter).iex_free_date5
                 , GCO_I_LIB_CHARACTERIZATION.GetInitialRetestDelay(tabinventory_external(vTabCounter).gco_good_id, sysdate)
                 , tabinventory_external(vTabCounter).iex_free_text1
                 , tabinventory_external(vTabCounter).iex_free_text2
                 , tabinventory_external(vTabCounter).iex_free_text3
                 , tabinventory_external(vTabCounter).iex_free_text4
                 , tabinventory_external(vTabCounter).iex_free_text5
                 , tabinventory_external(vTabCounter).iex_free_number1
                 , tabinventory_external(vTabCounter).iex_free_number2
                 , tabinventory_external(vTabCounter).iex_free_number3
                 , tabinventory_external(vTabCounter).iex_free_number4
                 , tabinventory_external(vTabCounter).iex_free_number5
              from stm_inventory_list_pos ilp
             where ilp.stm_inventory_list_pos_id = vstm_inventory_list_pos_id;

          update stm_inventory_external_line
             set c_inventory_ext_line_status = '002'
               , c_inv_ext_line_error_status = '002'
               , iex_is_validated = 1
               , A_DATEMOD = sysdate
               , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
           where stm_inventory_external_line_id = tabinventory_external(vTabCounter).stm_inventory_external_line_id;
        else
          -- position de stock non trouvée, création d'une position d'inventaire sans extraction
          -- de position de stock

          -- récupération du type de chaque caractérisation
          vCharTyp1  := gco_functions.GetCharacType(tabinventory_external(vTabCounter).GCO_CHARACTERIZATION_ID);
          vCharTyp2  := gco_functions.GetCharacType(tabinventory_external(vTabCounter).GCO_GCO_CHARACTERIZATION_ID);
          vCharTyp3  := gco_functions.GetCharacType(tabinventory_external(vTabCounter).GCO2_GCO_CHARACTERIZATION_ID);
          vCharTyp4  := gco_functions.GetCharacType(tabinventory_external(vTabCounter).GCO3_GCO_CHARACTERIZATION_ID);
          vCharTyp5  := gco_functions.GetCharacType(tabinventory_external(vTabCounter).GCO4_GCO_CHARACTERIZATION_ID);
          vError     := 0;

          -- vérification de l'existance des valeurs de caractérisation
          begin   -- Protected
            ValidateModification(null
                               ,   -- pas utilisé, liste courante
                                 null
                               ,   -- pas utilisé session courante
                                 tabinventory_external(vTabCounter).GCO_GOOD_ID
                               , tabinventory_external(vTabCounter).GCO_CHARACTERIZATION_ID
                               , tabinventory_external(vTabCounter).GCO_GCO_CHARACTERIZATION_ID
                               , tabinventory_external(vTabCounter).GCO2_GCO_CHARACTERIZATION_ID
                               , tabinventory_external(vTabCounter).GCO3_GCO_CHARACTERIZATION_ID
                               , tabinventory_external(vTabCounter).GCO4_GCO_CHARACTERIZATION_ID
                               , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_1
                               , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_2
                               , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_3
                               , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_4
                               , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_5
                               , vCharTyp1
                               , vCharTyp2
                               , vCharTyp3
                               , vCharTyp4
                               , vCharTyp5
                               , tabinventory_external(vTabCounter).STM_STOCK_ID
                               , tabinventory_external(vTabCounter).STM_LOCATION_ID
                               , tabinventory_external(vTabCounter).iex_quantity
                               , tabinventory_external(vTabCounter).IEX_UNIT_PRICE
                               , vFoundSetElemId
                               , vFoundVerElemId
                               , vFoundPceElemId
                               , vFoundSetElemStat
                               , vFoundVerElemStat
                               , vFoundPceElemStat
                                );
          exception
            when inv_qty_must_be_1 then
              vError                   := 1;
              lInvExtLineErrorStatus   := '201';
              lInventoryExtLineStatus  := '300';
            when inv_same_pos_exist_in_inv then
              vError                   := 1;
              lInvExtLineErrorStatus   := '202';
              lInventoryExtLineStatus  := '300';
            when inv_pce_elem_exist_in_inv then
              vError                   := 1;
              lInvExtLineErrorStatus   := '203';
              lInventoryExtLineStatus  := '300';
            when inv_pce_elem_exist_in_stk then
              vError                   := 1;
              lInvExtLineErrorStatus   := '204';
              lInventoryExtLineStatus  := '300';
            when inv_pce_elem_exist then
              vError                   := 1;
              lInvExtLineErrorStatus   := '205';
              lInventoryExtLineStatus  := '300';
            when inv_set_elem_exist then
              vError                   := 1;
              lInvExtLineErrorStatus   := '206';
              lInventoryExtLineStatus  := '300';
            when inv_bad_char_format then
              vError                   := 1;
              lInvExtLineErrorStatus   := '207';
              lInventoryExtLineStatus  := '300';
            when inv_negative_price then
              vError                   := 1;
              lInvExtLineErrorStatus   := '119';
              lInventoryExtLineStatus  := '300';
            when others then
              raise;
          end;   -- Protected

          if vError = 0 then
            vStm_element_number_id       := null;
            vStm_stm_element_number_id   := null;
            vStm2_stm_element_number_id  := null;
            vC_ele_num_status_1          := null;
            vC_ele_num_status_2          := null;
            vC_ele_num_status_3          := null;

            open crGco_characterization_type(tabinventory_external(vTabCounter).GCO_GOOD_ID);

            -- récupère la première caractérisation
            fetch crGco_characterization_type
             into tplGco_characterization_type;

            -- récupère le statut et l'élément en fonction du type de la première caractérisation
            if crGco_characterization_type%found then
              if tplGco_characterization_type.c_charact_type = '1' then
                vStm_element_number_id  := vFoundVerElemId;
                vC_ele_num_status_1     := vFoundVerElemStat;
              elsif tplGco_characterization_type.c_charact_type = '3' then
                vStm_element_number_id  := vFoundPceElemId;
                vC_ele_num_status_1     := vFoundPceElemStat;
              elsif tplGco_characterization_type.c_charact_type = '4' then
                vStm_element_number_id  := vFoundSetElemId;
                vC_ele_num_status_1     := vFoundSetElemStat;
              end if;
            end if;

            -- récupère la deuxième caractérisation
            fetch crGco_characterization_type
             into tplGco_characterization_type;

            -- récupère le statut et l'élément en fonction du type de la deuxième caractérisation
            if crGco_characterization_type%found then
              if tplGco_characterization_type.c_charact_type = '1' then
                vStm_Stm_element_number_id  := vFoundVerElemId;
                vC_ele_num_status_2         := vFoundVerElemStat;
              elsif tplGco_characterization_type.c_charact_type = '3' then
                vStm_stm_element_number_id  := vFoundPceElemId;
                vC_ele_num_status_2         := vFoundPceElemStat;
              elsif tplGco_characterization_type.c_charact_type = '4' then
                vStm_stm_element_number_id  := vFoundSetElemId;
                vC_ele_num_status_2         := vFoundSetElemStat;
              end if;
            end if;

            -- récupère la troisième caractérisation
            fetch crGco_characterization_type
             into tplGco_characterization_type;

            -- récupère le statut et l'élément en fonction du type de la troisième caractérisation
            if crGco_characterization_type%found then
              if tplGco_characterization_type.c_charact_type = '1' then
                vStm2_Stm_element_number_id  := vFoundVerElemId;
                vC_ele_num_status_3          := vFoundVerElemStat;
              elsif tplGco_characterization_type.c_charact_type = '3' then
                vStm2_stm_element_number_id  := vFoundPceElemId;
                vC_ele_num_status_3          := vFoundPceElemStat;
              elsif tplGco_characterization_type.c_charact_type = '4' then
                vStm2_stm_element_number_id  := vFoundSetElemId;
                vC_ele_num_status_3          := vFoundSetElemStat;
              end if;
            end if;

            close crGco_characterization_type;

            CreateNewListPosition(vstm_inventory_list_pos_id
                                ,   -- valeur de retour
                                  vDflt_stm_inventory_job_id
                                , vDflt_stm_inventory_List_Id
                                , vstm_inventory_task_id
                                , vStm_period_id
                                , vC_inventory_type
                                , sysdate
                                , tabinventory_external(vTabCounter).GCO_GOOD_ID
                                , tabinventory_external(vTabCounter).STM_STOCK_ID
                                , tabinventory_external(vTabCounter).STM_LOCATION_ID
                                , tabinventory_external(vTabCounter).GCO_CHARACTERIZATION_ID
                                , tabinventory_external(vTabCounter).GCO_GCO_CHARACTERIZATION_ID
                                , tabinventory_external(vTabCounter).GCO2_GCO_CHARACTERIZATION_ID
                                , tabinventory_external(vTabCounter).GCO3_GCO_CHARACTERIZATION_ID
                                , tabinventory_external(vTabCounter).GCO4_GCO_CHARACTERIZATION_ID
                                , null   -- pas de position de stock
                                , 0   -- valeur inventaire
                                , 0   -- qté inventaire
                                , 0   -- prix unitaire
                                , 0   -- qté alt 1
                                , 0   -- qté alt 2
                                , 0   -- qté alt 3
                                , null   -- commentaire
                                , vC_ele_num_status_1
                                , vC_ele_num_status_2
                                , vC_ele_num_status_3
                                , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_1
                                , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_2
                                , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_3
                                , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_4
                                , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_5
                                , null   -- date de réanalyse
                                , GCO_I_LIB_QUALITY_STATUS.GetReceiptStatus(iGoodId => tabinventory_external(vTabCounter).GCO_GOOD_ID)
                                 );

            -- insertion d'un détail dans le job t
            insert into stm_inventory_JOB_DETAIL
                        (stm_inventory_JOB_DETAIL_ID
                       , stm_inventory_JOB_ID
                       , stm_inventory_LIST_ID
                       , GCO_GOOD_ID
                       , STM_STOCK_ID
                       , STM_LOCATION_ID
                       , GCO_CHARACTERIZATION_ID
                       , GCO_GCO_CHARACTERIZATION_ID
                       , GCO2_GCO_CHARACTERIZATION_ID
                       , GCO3_GCO_CHARACTERIZATION_ID
                       , GCO4_GCO_CHARACTERIZATION_ID
                       , IJD_QUANTITY
                       , IJD_VALUE
                       , IJD_UNIT_PRICE
                       , IJD_WORDinG
                       , IJD_CHARACTERIZATION_VALUE_1
                       , IJD_CHARACTERIZATION_VALUE_2
                       , IJD_CHARACTERIZATION_VALUE_3
                       , IJD_CHARACTERIZATION_VALUE_4
                       , IJD_CHARACTERIZATION_VALUE_5
                       , IJD_LinE_VALIDATED
                       , IJD_LinE_in_USE
                       , IJD_inPUT_USER_NAME
                       , A_DATECRE
                       , A_IDCRE
                       , stm_inventory_TASK_ID
                       , stm_inventory_LIST_POS_ID
                       , IJD_ALTERNATIV_QTY_1
                       , IJD_ALTERNATIV_QTY_2
                       , IJD_ALTERNATIV_QTY_3
                       , ijd_free_date1
                       , ijd_free_date2
                       , ijd_free_date3
                       , ijd_free_date4
                       , ijd_free_date5
                       , ijd_retest_date
                       , ijd_free_text1
                       , ijd_free_text2
                       , ijd_free_text3
                       , ijd_free_text4
                       , ijd_free_text5
                       , ijd_free_number1
                       , ijd_free_number2
                       , ijd_free_number3
                       , ijd_free_number4
                       , ijd_free_number5
                        )
              select init_id_seq.nextval
                   , vDflt_stm_inventory_job_id
                   , vDflt_stm_inventory_list_id
                   , tabinventory_external(vTabCounter).GCO_GOOD_ID
                   , tabinventory_external(vTabCounter).STM_STOCK_ID
                   , tabinventory_external(vTabCounter).STM_LOCATION_ID
                   , tabinventory_external(vTabCounter).GCO_CHARACTERIZATION_ID
                   , tabinventory_external(vTabCounter).GCO_GCO_CHARACTERIZATION_ID
                   , tabinventory_external(vTabCounter).GCO2_GCO_CHARACTERIZATION_ID
                   , tabinventory_external(vTabCounter).GCO3_GCO_CHARACTERIZATION_ID
                   , tabinventory_external(vTabCounter).GCO4_GCO_CHARACTERIZATION_ID
                   , tabinventory_external(vTabCounter).iex_quantity
                   , case
                       when cfgUseUnitPrice = '1' then tabinventory_external(vTabCounter).iex_unit_price
                       else ilp.ilp_system_unit_price
                     end *
                     tabinventory_external(vTabCounter).iex_quantity
                   , case
                       when cfgUseUnitPrice = '1' then tabinventory_external(vTabCounter).iex_unit_price
                       else ilp.ilp_system_unit_price
                     end
                   , null
                   , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_1
                   , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_2
                   , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_3
                   , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_4
                   , tabinventory_external(vTabCounter).iex_CHARACTERIZATION_VALUE_5
                   , 0
                   , 0
                   , PCS.PC_I_LIB_SESSION.GetUserini
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserini
                   , vstm_inventory_task_id
                   , vstm_inventory_list_pos_id
                   , 0
                   , 0
                   , 0
                   , tabinventory_external(vTabCounter).iex_free_date1
                   , tabinventory_external(vTabCounter).iex_free_date2
                   , tabinventory_external(vTabCounter).iex_free_date3
                   , tabinventory_external(vTabCounter).iex_free_date4
                   , tabinventory_external(vTabCounter).iex_free_date5
                   , GCO_I_LIB_CHARACTERIZATION.GetInitialRetestDelay(tabinventory_external(vTabCounter).gco_good_id, sysdate)
                   , tabinventory_external(vTabCounter).iex_free_text1
                   , tabinventory_external(vTabCounter).iex_free_text2
                   , tabinventory_external(vTabCounter).iex_free_text3
                   , tabinventory_external(vTabCounter).iex_free_text4
                   , tabinventory_external(vTabCounter).iex_free_text5
                   , tabinventory_external(vTabCounter).iex_free_number1
                   , tabinventory_external(vTabCounter).iex_free_number2
                   , tabinventory_external(vTabCounter).iex_free_number3
                   , tabinventory_external(vTabCounter).iex_free_number4
                   , tabinventory_external(vTabCounter).iex_free_number5
                from stm_inventory_list_pos ilp
               where ilp.stm_inventory_list_pos_id = vstm_inventory_list_pos_id;

            update stm_inventory_external_line
               set c_inventory_ext_line_status = '002'
                 , c_inv_ext_line_error_status = '002'
                 , iex_is_validated = 1
                 , A_DATEMOD = sysdate
                 , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
             where stm_inventory_external_line_id = tabinventory_external(vTabCounter).stm_inventory_external_line_id;
          else
            update stm_inventory_external_line
               set c_inventory_ext_line_status = lInventoryExtLineStatus
                 , c_inv_ext_line_error_status = lInvExtLineErrorStatus
                 , iex_is_validated = 0
                 , A_DATEMOD = sysdate
                 , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
             where stm_inventory_external_line_id = tabinventory_external(vTabCounter).stm_inventory_external_line_id;
          end if;   -- vError = 0
        end if;   -- vStm_stock_position_id <> 0
      end if;   --vstm_inventory_list_pos_id <> 0
    end loop;

-- suppression de la liste créé si celle-ci ne contient aucune position
    select count(*)
      into vCounter
      from stm_inventory_list_pos ilp
     where ilp.stm_inventory_list_id = vDflt_stm_inventory_List_Id;

    if vCounter = 0 then
      delete from stm_inventory_job ijo
            where ijo.stm_inventory_list_id = vDflt_stm_inventory_List_Id;

      delete from stm_inventory_list ili
            where ili.stm_inventory_list_id = vDflt_stm_inventory_List_Id;
    end if;
  end Generate_external_inventory;

  function stm_test_external_line_status(paType in varchar2, paCode in varchar2)
    return integer
  is
--  variables
    result integer;
  begin
    -- Faux par défaut
    result  := 0;

    -- Toutes les lignes
    if paType = '0000' then
      result  := 1;
    end if;

    -- Ligne à intégrer
    if paType = '0010' then
      if PaCode = '001' then
        result  := 1;
      end if;
    end if;

    -- Ligne intégrée
    if paType = '0020' then
      if PaCode = '002' then
        result  := 1;
      end if;
    end if;

    -- Ligne intégrable
    if paType = '0030' then
      if PaCode = '003' then
        result  := 1;
      end if;
    end if;

    -- Ligne supprimée
    if paType = '0090' then
      if PaCode = '009' then
        result  := 1;
      end if;
    end if;

    -- Ligne erronnée
    if paType = '1000' then
      if     PaCode >= '100'
         and PaCode <= '299' then
        result  := 1;
      end if;
    end if;

    -- Ligne douteuse
    if paType = '3000' then
      if     PaCode >= '300'
         and PaCode <= '499' then
        result  := 1;
      end if;
    end if;

    --
    return result;
  end stm_test_external_line_status;

  function is_inv_period_active(pTaskId in STM_INVENTORY_TASK.STM_INVENTORY_TASK_ID%type)
    return varchar2
  is
    vResult varchar2(10);
  begin
    select PER.C_PERIOD_STATUS
      into vResult
      from STM_PERIOD PER
         , STM_INVENTORY_TASK TSK
     where TSK.STM_INVENTORY_TASK_ID = pTaskId
       and PER.STM_PERIOD_ID = TSK.STM_PERIOD_ID;

    return vResult;
  end is_inv_period_active;

  -- retourne le nombre d'importation n'ayant pas le statut intégré
  function IsAllExternalIntegrated(pTaskId in STM_INVENTORY_TASK.STM_INVENTORY_TASK_ID%type)
    return number
  is
    vResult number;
  begin
    select count(C_INVENTORY_EXTERNAL_STATUS)
      into vResult
      from STM_INVENTORY_EXTERNAL
     where STM_INVENTORY_TASK_ID = pTaskId
       and C_INVENTORY_EXTERNAL_STATUS = '01';

    return vResult;
  end IsAllExternalIntegrated;

  procedure delete_job_det(pJobDetId STM_INVENTORY_JOB_DETAIL.STM_INVENTORY_JOB_DETAIL_ID%type)
  is
  begin
    delete from STM_INVENTORY_JOB_DETAIL
          where STM_INVENTORY_JOB_DETAIL_ID = pJobDetId;
  end delete_job_det;

  /**
  * procedure Delete_inv_task
  *
  * Description : Suppression en cascade d'un inventaire
  *
  * @created    PYV
  * @version   2003
  */
  procedure delete_inv_task(pinvtaskid stm_inventory_task.stm_inventory_task_id%type)
  is
    cursor crInventory_external(cTaskId in STM_INVENTORY_TASK.STM_INVENTORY_TASK_ID%type)
    is
      select ixt.stm_inventory_external_id
        from stm_inventory_external ixt
       where ixt.stm_inventory_task_id = cTaskId;

    tplInventory_external crInventory_external%rowtype;
  begin
    delete from stm_inventory_updated_links iul
          where iul.stm_inventory_task_id = pinvtaskid;

    delete from stm_inventory_list_work ilw
          where ilw.stm_inventory_task_id = pinvtaskid;

    delete from stm_inventory_list_pos ilp
          where ilp.stm_inventory_task_id = pinvtaskid;

    delete from stm_inventory_job_detail ijd
          where ijd.stm_inventory_task_id = pinvtaskid;

    delete from stm_inventory_list_user ilu
          where ilu.stm_inventory_job_id in(select ijo.stm_inventory_job_id
                                              from stm_inventory_job ijo
                                             where ijo.stm_inventory_task_id = pInvTaskId);

    delete from stm_inventory_print ipr
          where ipr.stm_inventory_job_id in(select ijo.stm_inventory_job_id
                                              from stm_inventory_job ijo
                                             where ijo.stm_inventory_task_id = pinvtaskid)
             or ipr.stm_inventory_list_id in(select ili.stm_inventory_list_id
                                               from stm_inventory_list ili
                                              where ili.stm_inventory_task_id = pinvtaskid)
             or ipr.stm_inventory_external_id in(select iex.stm_inventory_external_id
                                                   from stm_inventory_external iex
                                                  where iex.stm_inventory_task_id = pinvtaskid);

    delete from stm_inventory_job ijo
          where ijo.stm_inventory_task_id = pinvtaskid;

    delete from stm_inventory_list ili
          where ili.stm_inventory_task_id = pinvtaskid;

    open crInventory_external(pinvtaskid);

    fetch crInventory_external
     into tplInventory_external;

    while crInventory_external%found loop
      delete from stm_inventory_external_line iex
            where iex.stm_inventory_external_id = tplInventory_external.stm_inventory_external_id;

      fetch crInventory_external
       into tplInventory_external;
    end loop;

    close crInventory_external;

    delete from stm_inventory_external iex
          where iex.stm_inventory_task_id = pinvtaskid;

    delete from stm_inventory_task inv
          where inv.stm_inventory_task_id = pinvtaskid;
  end delete_inv_task;

  /**
  * procedure ExtractStockPosition
  *
  * Description : extraction des positions d'inventaire unitaire
  *
  * @created    DSA
  * @version   2003
  */
  procedure ExtractStockPosition(
    aGoodId     in     GCO_GOOD.GCO_GOOD_ID%type
  , aStockId    in     STM_STOCK.STM_STOCK_ID%type
  , aLocationId in     STM_LOCATION.STM_LOCATION_ID%type
  , aTaskId     out    STM_INVENTORY_TASK.STM_INVENTORY_TASK_ID%type
  , aListId     out    STM_INVENTORY_LIST.STM_INVENTORY_LIST_ID%type
  , aJobId      out    STM_INVENTORY_JOB.STM_INVENTORY_JOB_ID%type
  , aSessionId  out    STM_INVENTORY_LIST_WORK.ILW_SESSION_ID%type
  , aPeriodId   out    STM_PERIOD.STM_PERIOD_ID%type
  , isExtract   out    number
  )
  is
    vGooMajorRef GCO_GOOD.GOO_MAJOR_REFERENCE%type;
  begin
    -- Recherche de la description du bien
    select goo_major_reference
      into vGooMajorRef
      from gco_good
     where gco_good_id = aGoodId;

    -- Création de l'inventaire unitaire
    select INIT_ID_SEQ.nextval
      into aTaskId
      from dual;

    select stm_period_id
      into aPeriodId
      from stm_period
     where c_period_status = '02'
       and stm_exercise_id = stm_functions.GetActiveExercise;

    insert into stm_inventory_task
                (stm_inventory_task_id
               , stm_period_id
               , c_inventory_type
               , c_inventory_mode
               , c_inventory_status
               , inv_description
               , inv_authorized_value
               , a_datecre
               , a_idcre
                )
      select aTaskId
           , aPeriodId
           , '04'
           , '2'
           , '03'
           , pcs.pc_functions.TranslateWord('Inventaire unitaire', pcs.PC_I_LIB_SESSION.getuserlangid) ||
             ', ' ||
             pcs.pc_functions.TranslateWord('produit', pcs.PC_I_LIB_SESSION.getuserlangid) ||
             ' : ' ||
             vGooMajorRef ||
             ' (' ||
             pcs.PC_I_LIB_SESSION.GetUserIni ||
             ' - ' ||
             to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS') ||
             ')'
           , 0
           , sysdate
           , pcs.PC_I_LIB_SESSION.GetUserIni
        from dual;

    -- Création de l'extraction
    select init_id_seq.nextval
      into aListId
      from dual;

    insert into stm_inventory_list
                (stm_inventory_list_id
               , stm_inventory_task_id
               , c_inventory_list_status
               , pc_sqlst_id
               , ili_description
               , a_datecre
               , a_idcre
                )
      select aListId
           , aTaskId
           , '03'
           , sqlst.pc_sqlst_id
           , pcs.pc_functions.TranslateWord('Produit', pcs.PC_I_LIB_SESSION.getuserlangid) ||
             ' : ' ||
             ' ' ||
             vGooMajorRef ||
             ' (' ||
             PCS.PC_I_LIB_SESSION.GetUserIni ||
             ' - ' ||
             to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS') ||
             ')'
           , sysdate
           , pcs.PC_I_LIB_SESSION.GetUserIni
        from pcs.pc_sqlst sqlst
           , pcs.pc_table tab
       where sqlst.pc_table_id = tab.pc_table_id
         and sqlst.c_sqgtype = 'INVENTORY_SORT'
         and sqlst.sqlid = pcs.pc_config.GetConfig('STM_INVENTORY_DEFL_SORT_SQLID')
         and tab.tabname = 'STM_INVENTORY_LIST_WORK';

    -- Création du journal d'inventaire
    select init_id_seq.nextval
      into aJobId
      from dual;

    insert into stm_inventory_job
                (stm_inventory_job_id
               , stm_inventory_task_id
               , stm_inventory_list_id
               , c_inventory_job_type
               , ijo_job_description
               , ijo_owner_name
               , ijo_job_available
               , pc_user_id
               , a_datecre
               , a_idcre
                )
      select aJobId
           , aTaskId
           , aListId
           , '01'
           , pcs.pc_functions.TranslateWord('Produit', pcs.PC_I_LIB_SESSION.getuserlangid) || ' : ' || vGooMajorRef
           , pcs.PC_I_LIB_SESSION.GetUserIni
           , 1
           , pcs.PC_I_LIB_SESSION.GetUserId
           , sysdate
           , pcs.PC_I_LIB_SESSION.GetUserIni
        from dual;

    -- Création des positions de l'inventaire
    insert into stm_inventory_list_pos
                (stm_inventory_list_pos_id
               , stm_inventory_task_id
               , stm_inventory_list_id
               , stm_stock_id
               , stm_location_id
               , gco_good_id
               , stm_period_id
               , stm_stock_position_id
               , c_inventory_type
               , gco_characterization_id
               , gco_gco_characterization_id
               , gco2_gco_characterization_id
               , gco3_gco_characterization_id
               , gco4_gco_characterization_id
               , ilp_characterization_value_1
               , ilp_characterization_value_2
               , ilp_characterization_value_3
               , ilp_characterization_value_4
               , ilp_characterization_value_5
               , ilp_system_value
               , ilp_system_quantity
               , ilp_system_unit_price
               , ilp_inventory_value
               , ilp_inventory_quantity
               , ilp_inventory_unit_price
               , ilp_inventory_date
               , ilp_sys_alternativ_qty_1
               , ilp_sys_alternativ_qty_2
               , ilp_sys_alternativ_qty_3
               , ilp_provisory_output
               , ilp_provisory_input
               , ilp_inv_alternativ_qty_1
               , ilp_inv_alternativ_qty_2
               , ilp_inv_alternativ_qty_3
               , ilp_c_ele_num_status_1
               , ilp_c_ele_num_status_2
               , ilp_c_ele_num_status_3
               , ilp_assign_quantity
               , ilp_is_validated
               , ilp_is_original_pos
               , a_datecre
               , a_idcre
               , ilp_retest_date
               , GCO_QUALITY_STATUS_ID
                )
      select init_id_seq.nextval stm_inventory_list_pos_id
           , aTaskId stm_inventory_task_id
           , aListId stm_inventory_list_id
           , decode(aStockId, 0, spo.stm_stock_id, aStockId) stm_stock_id
           , decode(aLocationId, 0, spo.stm_location_id, aLocationId) stm_location_id
           , aGoodId
           , inv.stm_period_id
           , spo.stm_stock_position_id
           , inv.c_inventory_type
           , spo.gco_characterization_id
           , spo.gco_gco_characterization_id
           , spo.gco2_gco_characterization_id
           , spo.gco3_gco_characterization_id
           , spo.gco4_gco_characterization_id
           , spo.spo_characterization_value_1
           , spo.spo_characterization_value_2
           , spo.spo_characterization_value_3
           , spo.spo_characterization_value_4
           , spo.spo_characterization_value_5
           , spo.spo_stock_quantity * gco_functions.getcostpricewithmanagementmode(spo.gco_good_id)   -- ilp_system_value
           , spo_stock_quantity   -- ilp_system_quantity
           , (gco_functions.getcostpricewithmanagementmode(spo.gco_good_id) )   -- ilp_system_unit_price
           , decode(inv.c_inventory_mode
                  , '1', 0
                  , '2', spo.spo_stock_quantity * gco_functions.getcostpricewithmanagementmode(spo.gco_good_id)
                   )   -- ilp_inventory_value
           , decode(inv.c_inventory_mode, '1', 0, '2', spo.spo_stock_quantity)   -- ilp_inventory_quantity
           , (gco_functions.getcostpricewithmanagementmode(spo.gco_good_id) )   -- ilp_inventory_unit_price
           , sysdate   -- ilp_inventory_date
           , spo.spo_alternativ_quantity_1   -- ilp_sys_alternativ_qty_1
           , spo.spo_alternativ_quantity_2   -- ilp_sys_alternativ_qty_2
           , spo.spo_alternativ_quantity_3   -- ilp_sys_alternativ_qty_3
           , spo.spo_provisory_output
           , spo.spo_provisory_input
           , decode(inv.c_inventory_mode, '1', 0, '2', spo.spo_alternativ_quantity_1)   -- ilp_inv_alternativ_qty_1
           , decode(inv.c_inventory_mode, '1', 0, '2', spo.spo_alternativ_quantity_2)   -- ilp_inv_alternativ_qty_2
           , decode(inv.c_inventory_mode, '1', 0, '2', spo.spo_alternativ_quantity_3)   -- ilp_inv_alternativ_qty_3
           , stm_functions.getelementstatus(spo.stm_element_number_id)   -- ilp_c_ele_num_status_1
           , stm_functions.getelementstatus(spo.stm_stm_element_number_id)   -- ilp_c_ele_num_status_2
           , stm_functions.getelementstatus(spo.stm2_stm_element_number_id)   -- ilp_c_ele_num_status_3
           , spo.spo_assign_quantity
           , 0   -- ilp_is_validated
           , 1   -- ilp_is_original_pos
           , sysdate   -- a_datecre
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- a_idcre
           , ele.sem_retest_date   --ilp_retest_date
           , ele.GCO_QUALITY_STATUS_ID   --status qualité
        from stm_stock_position spo
           , stm_inventory_task inv
           , stm_stock sto
           , stm_element_number ele
       where inv.stm_inventory_task_id = aTaskId
         and (   spo.stm_stock_id = aStockId
              or aStockId = 0)
         and (   spo.stm_location_id = aLocationId
              or aLocationId = 0)
         and spo.gco_good_id = aGoodId
         and sto.stm_stock_id = spo.stm_stock_id
         and sto.c_access_method = 'PUBLIC'
         and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = ele.STM_ELEMENT_NUMBER_ID(+)
         and not exists(
               select ilp.stm_inventory_list_pos_id
                 from stm_inventory_list_pos ilp
                where ilp.gco_good_id = spo.gco_good_id
                  and ilp.stm_stock_id = spo.stm_stock_id
                  and ilp.stm_location_id = spo.stm_location_id
                  and ilp.ilp_is_validated = 0
                  and (    (ilp.gco_characterization_id = spo.gco_characterization_id)
                       or (    ilp.gco_characterization_id is null
                           and spo.gco_characterization_id is null)
                      )
                  and (    (ilp.gco_gco_characterization_id = spo.gco_gco_characterization_id)
                       or (    ilp.gco_gco_characterization_id is null
                           and spo.gco_gco_characterization_id is null)
                      )
                  and (    (ilp.gco2_gco_characterization_id = spo.gco2_gco_characterization_id)
                       or (    ilp.gco2_gco_characterization_id is null
                           and spo.gco2_gco_characterization_id is null)
                      )
                  and (    (ilp.gco3_gco_characterization_id = spo.gco3_gco_characterization_id)
                       or (    ilp.gco3_gco_characterization_id is null
                           and spo.gco3_gco_characterization_id is null)
                      )
                  and (    (ilp.gco4_gco_characterization_id = spo.gco4_gco_characterization_id)
                       or (    ilp.gco4_gco_characterization_id is null
                           and spo.gco4_gco_characterization_id is null)
                      )
                  and (    (ilp.ilp_characterization_value_1 = spo.spo_characterization_value_1)
                       or (    ilp.ilp_characterization_value_1 is null
                           and spo.spo_characterization_value_1 is null)
                      )
                  and (    (ilp.ilp_characterization_value_2 = spo.spo_characterization_value_2)
                       or (    ilp.ilp_characterization_value_2 is null
                           and spo.spo_characterization_value_2 is null)
                      )
                  and (    (ilp.ilp_characterization_value_3 = spo.spo_characterization_value_3)
                       or (    ilp.ilp_characterization_value_3 is null
                           and spo.spo_characterization_value_3 is null)
                      )
                  and (    (ilp.ilp_characterization_value_4 = spo.spo_characterization_value_4)
                       or (    ilp.ilp_characterization_value_4 is null
                           and spo.spo_characterization_value_4 is null)
                      )
                  and (    (ilp.ilp_characterization_value_5 = spo.spo_characterization_value_5)
                       or (    ilp.ilp_characterization_value_5 is null
                           and spo.spo_characterization_value_5 is null)
                      ) );

-- Génération de la liste de saisie des positions d'inventaire
    insertListPosintoWork(aListId, aJobId);
    -- Enregistrement de l'id de session
    aSessionId  := userenv('SESSIONID');

    select decode(count(*), 0, 0, 1)
      into IsExtract
      from stm_inventory_list_work
     where stm_inventory_list_id = aListId
       and ilw_session_id = aSessionId;
  end ExtractStockPosition;

  /**
  * procedure TreatInventoryUnit
  *
  * Description : traitement de l'inventaire unitaire
  *
  * @created    DSA
  * @version   2003
  */
  procedure TreatInventoryUnit(
    aSessionId    in     STM_INVENTORY_LIST_WORK.ILW_SESSION_ID%type
  , aListId       in     STM_INVENTORY_LIST.STM_INVENTORY_LIST_ID%type
  , aJobId        in     STM_INVENTORY_JOB.STM_INVENTORY_JOB_ID%type
  , aStatusReport out    varchar
  )
  is
    vTaskId STM_INVENTORY_TASK.STM_INVENTORY_TASK_ID%type;
  begin
    -- id de l'inventaire
    select stm_inventory_task_id
      into vTaskId
      from stm_inventory_list
     where stm_inventory_list_id = aListId;

    -- mise à jour de la connexion
    UpdateConnection(aListId, aJobId, 0);
    -- Procédure de traitement de l'extraction
    Validate_List(aListId, aStatusReport);
    --Suppression du contenu de stm_inventory_list_work
    DeleteWorkList(aSessionId, aListId);

    -- si traitement ok
    if aStatusReport = '101' then
      -- passer le statut de l'inventaire à "traité"
      Set_Inventory_Status(vTaskId, '05');
    else
      -- sinon, "partiellement traité"
      Set_Inventory_Status(vTaskId, '04');
    end if;
  end TreatInventoryUnit;

  /**
  * procedure FinalizeInventoryUnit
  * Description : finalisation de l'inventaire unitaire
  * @created    DSA
  * @version   2003
  */
  procedure FinalizeInventoryUnit(aListId in STM_INVENTORY_LIST.STM_INVENTORY_LIST_ID%type)
  is
    vTaskId       STM_INVENTORY_TASK.STM_INVENTORY_TASK_ID%type;
    vStatusReport varchar(10);
  begin
    -- id de l'inventaire
    select stm_inventory_task_id
      into vTaskId
      from stm_inventory_list
     where stm_inventory_list_id = aListId;

    -- suppression des lignes erronnées de l'extraction
    delete from stm_inventory_list_pos
          where stm_inventory_list_id = aListId
            and c_inventory_error_status is not null;

    -- traitement de l'extraction
    Validate_List(aListId, vStatusReport);
    -- passer le statut de l'inventaire à "traité"
    Set_Inventory_Status(vTaskId, '05');
  end FinalizeInventoryUnit;
end STM_INVENTORY;
