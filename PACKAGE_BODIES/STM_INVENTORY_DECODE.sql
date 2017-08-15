--------------------------------------------------------
--  DDL for Package Body STM_INVENTORY_DECODE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_INVENTORY_DECODE" 
as
  type DecodedLineRec is record(
    Inv_Goo_major_reference      gco_good.goo_major_reference%type
  , Inv_StoDescription           stm_stock.sto_description%type
  , Inv_LocDescription           stm_location.loc_description%type
  , Inv_Qty                      varchar2(16)
  , Inv_Char_value_1             stm_stock_position.spo_characterization_value_1%type
  , Inv_Char_value_2             stm_stock_position.spo_characterization_value_2%type
  , Inv_Char_value_3             stm_stock_position.spo_characterization_value_3%type
  , Inv_Char_value_4             stm_stock_position.spo_characterization_value_4%type
  , Inv_Char_value_5             stm_stock_position.spo_characterization_value_5%type
  , Inv_Gco_good_id              gco_good.gco_good_id%type
  , Inv_Stm_Stock_id             stm_stock.stm_stock_id%type
  , Inv_Stm_Location_id          stm_location.stm_location_id%type
  , Inv_Quantity                 stm_stock_position.spo_stock_quantity%type
  , Inv_Gco1_characterization_id gco_characterization.gco_characterization_id%type
  , Inv_Gco2_characterization_id gco_characterization.gco_characterization_id%type
  , Inv_Gco3_characterization_id gco_characterization.gco_characterization_id%type
  , Inv_Gco4_characterization_id gco_characterization.gco_characterization_id%type
  , Inv_Gco5_characterization_id gco_characterization.gco_characterization_id%type
  , freeDate1                    date
  , freeDate2                    date
  , freeDate3                    date
  , freeDate4                    date
  , freeDate5                    date
  , freeText1                    varchar2(100)
  , freeText2                    varchar2(100)
  , freeText3                    varchar2(100)
  , freeText4                    varchar2(100)
  , freeText5                    varchar2(100)
  , freeNumber1                  number(15, 4)
  , freeNumber2                  number(15, 4)
  , freeNumber3                  number(15, 4)
  , freeNumber4                  number(15, 4)
  , freeNumber5                  number(15, 4)
  , unitPrice                    number(15, 4)
  );

  procedure decode_inv_csv(aStm_Inventory_External_Id Stm_Inventory_External.Stm_Inventory_External_id%type, aPartDecode number)
  is
/* curseur récupérant les lignes importées */
    cursor crInventory_External_Lines(pStm_Inventory_External_Id Stm_Inventory_External.Stm_Inventory_External_id%type)
    is
      select stm_inventory_external_line_id
           , iex_input_line
           , c_inventory_ext_line_status
        from stm_inventory_external_line iex
       where stm_inventory_external_id = pStm_inventory_external_id
         and iex.iex_is_validated = 0;

    tplInventory_External_Lines crInventory_External_Lines%rowtype;
    vDecodedLine                DecodedLineRec;
    vDummyChar                  varchar2(100);
  begin
    open crInventory_External_Lines(aStm_Inventory_External_id);

    fetch crInventory_External_Lines
     into tplInventory_External_Lines;

    while crInventory_External_Lines%found loop
      if    (aPartDecode = 0)
         or (    aPartDecode = 1
             and tplInventory_External_lines.c_inventory_ext_line_status between '100' and '199') then
        /* découpage de la ligne lue */
        vDecodedLine.Inv_goo_major_reference  := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 1, ';'), 1, 30) );
        vDecodedLine.Inv_StoDescription       := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 2, ';'), 1, 10) );
        vDecodedLine.Inv_LocDescription       := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 3, ';'), 1, 10) );
        vDecodedLine.Inv_Qty                  := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 4, ';'), 1, 16) );
        vDecodedLine.Inv_Char_value_1         := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 5, ';'), 1, 30) );
        vDecodedLine.Inv_Char_value_2         := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 6, ';'), 1, 30) );
        vDecodedLine.Inv_Char_value_3         := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 7, ';'), 1, 30) );
        vDecodedLine.Inv_Char_value_4         := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 8, ';'), 1, 30) );
        vDecodedLine.Inv_Char_value_5         := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 9, ';'), 1, 30) );
        vDecodedLine.freeDate1                := to_date(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 10, ';'), 1, 10) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate2                := to_date(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 11, ';'), 1, 10) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate3                := to_date(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 12, ';'), 1, 10) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate4                := to_date(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 13, ';'), 1, 10) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate5                := to_date(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 14, ';'), 1, 10) ), 'dd/mm/yyyy');
        vDecodedLine.freeText1                := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 15, ';'), 1, 100) );
        vDecodedLine.freeText2                := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 16, ';'), 1, 100) );
        vDecodedLine.freeText3                := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 17, ';'), 1, 100) );
        vDecodedLine.freeText4                := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 18, ';'), 1, 100) );
        vDecodedLine.freeText5                := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 19, ';'), 1, 100) );
        vDecodedLine.freeNumber1              :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 20, ';'), 1, 15) ), '99999999999.9999');
        vDecodedLine.freeNumber2              :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 21, ';'), 1, 15) ), '99999999999.9999');
        vDecodedLine.freeNumber3              :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 22, ';'), 1, 15) ), '99999999999.9999');
        vDecodedLine.freeNumber4              :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 23, ';'), 1, 15) ), '99999999999.9999');
        vDecodedLine.freeNumber5              :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 24, ';'), 1, 15) ), '99999999999.9999');
        vDecodedLine.UnitPrice                :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 25, ';'), 1, 15) ), '99999999999.9999');

        /* décodage des informations découpées */

        /* (1) récupération de gco_good_id */
        begin
          select Gco_good_id
            into vDecodedLine.Inv_Gco_good_id
            from Gco_good
           where goo_major_reference = rtrim(vDecodedLine.Inv_goo_major_reference);
        exception
          when no_data_found then
            vDecodedLine.Inv_Gco_Good_id  := null;
          when too_many_rows then
            vDecodedLine.Inv_Gco_Good_id  := null;
        end;

        /* (2a) récupération des ID de caractérisations gérées en stock */
        GCO_FUNCTIONS.GetListOfStkChar(vDecodedLine.Inv_Gco_good_id
                                     , vDecodedLine.Inv_Gco1_Characterization_id
                                     , vDecodedLine.Inv_Gco2_characterization_id
                                     , vDecodedLine.Inv_Gco3_Characterization_id
                                     , vDecodedLine.Inv_Gco4_Characterization_id
                                     , vDecodedLine.Inv_Gco5_Characterization_id
                                     ,
                                       -- les valeurs retournées pour le "type" de caractérisations ne sont pas utiliées
                                       vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     ,
                                       -- les valeurs retournées pour les "descriptions" de caractérisations ne sont pas utilisées
                                       vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                      );

        /* (2b) récupération des valeurs de caractérisations pour les caractérisations gérées en stock */
        if vDecodedLine.Inv_Gco1_characterization_id is null then
          vDecodedLine.Inv_Char_Value_1  := null;
        end if;

        if vDecodedLine.Inv_Gco2_characterization_id is null then
          vDecodedLine.Inv_Char_Value_2  := null;
        end if;

        if vDecodedLine.Inv_Gco3_characterization_id is null then
          vDecodedLine.Inv_Char_Value_3  := null;
        end if;

        if vDecodedLine.Inv_Gco4_characterization_id is null then
          vDecodedLine.Inv_Char_Value_4  := null;
        end if;

        if vDecodedLine.Inv_Gco5_characterization_id is null then
          vDecodedLine.Inv_Char_Value_5  := null;
        end if;

        /* (3a) récupération de ID de l'emplacement */
        begin
          select loc.stm_location_id
            into vDecodedLine.Inv_Stm_location_id
            from Stm_location loc
               , stm_stock sto
           where loc.stm_stock_id = sto.stm_stock_id
             and loc.Loc_Description = rtrim(vDecodedLine.Inv_LocDescription)
             and sto.sto_description = rtrim(vDecodedLine.Inv_StoDescription);
        exception
          when no_data_found then
            vDecodedLine.Inv_Stm_Location_id  := null;
          when too_many_rows then
            vDecodedLine.Inv_Stm_Location_id  := null;
        end;

        /* (3b) récupération de ID du stock */
        begin
          select stm_stock_id
            into vDecodedLine.Inv_Stm_stock_id
            from stm_location
           where stm_location_id = vDecodedLine.Inv_Stm_Location_id;
        exception
          when no_data_found then
            vDecodedLine.Inv_Stm_stock_id  := null;
        end;

        /* (4) récupération de la quantité */
        begin
          vDecodedLine.Inv_Quantity  := to_number(rtrim(ltrim(vDecodedLine.Inv_Qty) ), '99999999999.9999');
        exception
          when others then
            vDecodedLine.Inv_Quantity  := 0;
        end;

        /* mise à jour des données décodées */
        update stm_inventory_external_line
           set gco_good_Id = vDecodedLine.Inv_gco_good_id
             , stm_stock_id = vDecodedLine.Inv_stm_stock_id
             , stm_location_id = vDecodedLine.Inv_stm_location_id
             , iex_major_reference = vDecodedLine.Inv_goo_major_reference
             , iex_sto_description = vDecodedLine.Inv_StoDescription
             , iex_loc_description = vDecodedLine.Inv_LocDescription
             , iex_characterization_value_1 = vDecodedLine.Inv_Char_value_1
             , iex_characterization_value_2 = vDecodedLine.Inv_Char_value_2
             , iex_characterization_value_3 = vDecodedLine.Inv_Char_value_3
             , iex_characterization_value_4 = vDecodedLine.Inv_Char_value_4
             , iex_characterization_value_5 = vDecodedLine.Inv_Char_value_5
             , gco_characterization_id = vDecodedLine.Inv_Gco1_characterization_id
             , gco_gco_characterization_id = vDecodedLine.Inv_Gco2_characterization_id
             , gco2_gco_characterization_id = vDecodedLine.Inv_Gco3_characterization_id
             , gco3_gco_characterization_id = vDecodedLine.Inv_Gco4_characterization_id
             , gco4_gco_characterization_id = vDecodedLine.Inv_Gco5_characterization_id
             , iex_quantity = vDecodedLine.Inv_Quantity
             , c_inventory_ext_line_status = '001'
             , iex_free_date1 = vDecodedLine.freeDate1
             , iex_free_date2 = vDecodedLine.freeDate2
             , iex_free_date3 = vDecodedLine.freeDate3
             , iex_free_date4 = vDecodedLine.freeDate4
             , iex_free_date5 = vDecodedLine.freeDate5
             , iex_free_Text1 = vDecodedLine.freeText1
             , iex_free_Text2 = vDecodedLine.freeText2
             , iex_free_Text3 = vDecodedLine.freeText3
             , iex_free_Text4 = vDecodedLine.freeText4
             , iex_free_Text5 = vDecodedLine.freeText5
             , iex_free_Number1 = vDecodedLine.freeNumber1
             , iex_free_Number2 = vDecodedLine.freeNumber2
             , iex_free_Number3 = vDecodedLine.freeNumber3
             , iex_free_Number4 = vDecodedLine.freeNumber4
             , iex_free_Number5 = vDecodedLine.freeNumber5
             , iex_unit_price = vDecodedLine.UnitPrice
             , a_datecre = sysdate
             , a_idcre = pcs.PC_I_LIB_SESSION.getuserini
         where stm_inventory_external_line_id = tplInventory_External_Lines.stm_inventory_external_line_id;
      end if;

      fetch crInventory_External_Lines
       into tplInventory_External_Lines;
    end loop;

    close crInventory_External_Lines;
  end decode_inv_csv;

  procedure decode_inv_csv2(aStm_Inventory_External_Id Stm_Inventory_External.Stm_Inventory_External_id%type, aPartDecode number)
  is
/* curseur récupérant les lignes importées */
    cursor crInventory_External_Lines(pStm_Inventory_External_Id Stm_Inventory_External.Stm_Inventory_External_id%type)
    is
      select stm_inventory_external_line_id
           , iex_input_line
           , c_inventory_ext_line_status
        from stm_inventory_external_line iex
       where stm_inventory_external_id = pStm_inventory_external_id
         and iex.iex_is_validated = 0;

    tplInventory_External_Lines crInventory_External_Lines%rowtype;
    vDecodedLine                DecodedLineRec;
    vDummyChar                  varchar2(100);
  begin
    open crInventory_External_Lines(aStm_Inventory_External_id);

    fetch crInventory_External_Lines
     into tplInventory_External_Lines;

    while crInventory_External_Lines%found loop
      if    (aPartDecode = 0)
         or (    aPartDecode = 1
             and tplInventory_External_lines.c_inventory_ext_line_status between '100' and '199') then
        /* découpage de la ligne lue */
        vDecodedLine.Inv_goo_major_reference  := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 1, ';'), 1, 30) );
        vDecodedLine.Inv_StoDescription       := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 2, ';'), 1, 10) );
        vDecodedLine.Inv_LocDescription       := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 3, ';'), 1, 10) );
        vDecodedLine.Inv_Qty                  := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 4, ';'), 1, 16) );
        vDecodedLine.UnitPrice                :=
                                           to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 5, ';'), 1, 15) ), '99999999999.9999');
        vDecodedLine.Inv_Char_value_1         := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 6, ';'), 1, 30) );
        vDecodedLine.Inv_Char_value_2         := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 7, ';'), 1, 30) );
        vDecodedLine.Inv_Char_value_3         := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 8, ';'), 1, 30) );
        vDecodedLine.Inv_Char_value_4         := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 8, ';'), 1, 30) );
        vDecodedLine.Inv_Char_value_5         := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 10, ';'), 1, 30) );
        vDecodedLine.freeDate1                := to_date(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 11, ';'), 1, 10) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate2                := to_date(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 12, ';'), 1, 10) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate3                := to_date(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 13, ';'), 1, 10) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate4                := to_date(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 14, ';'), 1, 10) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate5                := to_date(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 15, ';'), 1, 10) ), 'dd/mm/yyyy');
        vDecodedLine.freeText1                := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 16, ';'), 1, 100) );
        vDecodedLine.freeText2                := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 17, ';'), 1, 100) );
        vDecodedLine.freeText3                := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 18, ';'), 1, 100) );
        vDecodedLine.freeText4                := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 19, ';'), 1, 100) );
        vDecodedLine.freeText5                := trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 20, ';'), 1, 100) );
        vDecodedLine.freeNumber1              :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 21, ';'), 1, 15) ), '99999999999.9999');
        vDecodedLine.freeNumber2              :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 22, ';'), 1, 15) ), '99999999999.9999');
        vDecodedLine.freeNumber3              :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 23, ';'), 1, 15) ), '99999999999.9999');
        vDecodedLine.freeNumber4              :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 24, ';'), 1, 15) ), '99999999999.9999');
        vDecodedLine.freeNumber5              :=
                                          to_number(trim(substr(extractline(tplInventory_External_Lines.iex_Input_Line, 25, ';'), 1, 15) ), '99999999999.9999');

        /* décodage des informations découpées */

        /* (1) récupération de gco_good_id */
        begin
          select Gco_good_id
            into vDecodedLine.Inv_Gco_good_id
            from Gco_good
           where goo_major_reference = rtrim(vDecodedLine.Inv_goo_major_reference);
        exception
          when no_data_found then
            vDecodedLine.Inv_Gco_Good_id  := null;
          when too_many_rows then
            vDecodedLine.Inv_Gco_Good_id  := null;
        end;

        /* (2a) récupération des ID de caractérisations gérées en stock */
        GCO_FUNCTIONS.GetListOfStkChar(vDecodedLine.Inv_Gco_good_id
                                     , vDecodedLine.Inv_Gco1_Characterization_id
                                     , vDecodedLine.Inv_Gco2_characterization_id
                                     , vDecodedLine.Inv_Gco3_Characterization_id
                                     , vDecodedLine.Inv_Gco4_Characterization_id
                                     , vDecodedLine.Inv_Gco5_Characterization_id
                                     ,
                                       -- les valeurs retournées pour le "type" de caractérisations ne sont pas utiliées
                                       vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     ,
                                       -- les valeurs retournées pour les "descriptions" de caractérisations ne sont pas utilisées
                                       vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                      );

        /* (2b) récupération des valeurs de caractérisations pour les caractérisations gérées en stock */
        if vDecodedLine.Inv_Gco1_characterization_id is null then
          vDecodedLine.Inv_Char_Value_1  := null;
        end if;

        if vDecodedLine.Inv_Gco2_characterization_id is null then
          vDecodedLine.Inv_Char_Value_2  := null;
        end if;

        if vDecodedLine.Inv_Gco3_characterization_id is null then
          vDecodedLine.Inv_Char_Value_3  := null;
        end if;

        if vDecodedLine.Inv_Gco4_characterization_id is null then
          vDecodedLine.Inv_Char_Value_4  := null;
        end if;

        if vDecodedLine.Inv_Gco5_characterization_id is null then
          vDecodedLine.Inv_Char_Value_5  := null;
        end if;

        /* (3a) récupération de ID de l'emplacement */
        begin
          select loc.stm_location_id
            into vDecodedLine.Inv_Stm_location_id
            from Stm_location loc
               , stm_stock sto
           where loc.stm_stock_id = sto.stm_stock_id
             and loc.Loc_Description = rtrim(vDecodedLine.Inv_LocDescription)
             and sto.sto_description = rtrim(vDecodedLine.Inv_StoDescription);
        exception
          when no_data_found then
            vDecodedLine.Inv_Stm_Location_id  := null;
          when too_many_rows then
            vDecodedLine.Inv_Stm_Location_id  := null;
        end;

        /* (3b) récupération de ID du stock */
        begin
          select stm_stock_id
            into vDecodedLine.Inv_Stm_stock_id
            from stm_location
           where stm_location_id = vDecodedLine.Inv_Stm_Location_id;
        exception
          when no_data_found then
            vDecodedLine.Inv_Stm_stock_id  := null;
        end;

        /* (4) récupération de la quantité */
        begin
          vDecodedLine.Inv_Quantity  := to_number(rtrim(ltrim(vDecodedLine.Inv_Qty) ), '99999999999.9999');
        exception
          when others then
            vDecodedLine.Inv_Quantity  := 0;
        end;

        /* mise à jour des données décodées */
        update stm_inventory_external_line
           set gco_good_Id = vDecodedLine.Inv_gco_good_id
             , stm_stock_id = vDecodedLine.Inv_stm_stock_id
             , stm_location_id = vDecodedLine.Inv_stm_location_id
             , iex_major_reference = vDecodedLine.Inv_goo_major_reference
             , iex_sto_description = vDecodedLine.Inv_StoDescription
             , iex_loc_description = vDecodedLine.Inv_LocDescription
             , iex_characterization_value_1 = vDecodedLine.Inv_Char_value_1
             , iex_characterization_value_2 = vDecodedLine.Inv_Char_value_2
             , iex_characterization_value_3 = vDecodedLine.Inv_Char_value_3
             , iex_characterization_value_4 = vDecodedLine.Inv_Char_value_4
             , iex_characterization_value_5 = vDecodedLine.Inv_Char_value_5
             , gco_characterization_id = vDecodedLine.Inv_Gco1_characterization_id
             , gco_gco_characterization_id = vDecodedLine.Inv_Gco2_characterization_id
             , gco2_gco_characterization_id = vDecodedLine.Inv_Gco3_characterization_id
             , gco3_gco_characterization_id = vDecodedLine.Inv_Gco4_characterization_id
             , gco4_gco_characterization_id = vDecodedLine.Inv_Gco5_characterization_id
             , iex_quantity = vDecodedLine.Inv_Quantity
             , c_inventory_ext_line_status = '001'
             , iex_free_date1 = vDecodedLine.freeDate1
             , iex_free_date2 = vDecodedLine.freeDate2
             , iex_free_date3 = vDecodedLine.freeDate3
             , iex_free_date4 = vDecodedLine.freeDate4
             , iex_free_date5 = vDecodedLine.freeDate5
             , iex_free_Text1 = vDecodedLine.freeText1
             , iex_free_Text2 = vDecodedLine.freeText2
             , iex_free_Text3 = vDecodedLine.freeText3
             , iex_free_Text4 = vDecodedLine.freeText4
             , iex_free_Text5 = vDecodedLine.freeText5
             , iex_free_Number1 = vDecodedLine.freeNumber1
             , iex_free_Number2 = vDecodedLine.freeNumber2
             , iex_free_Number3 = vDecodedLine.freeNumber3
             , iex_free_Number4 = vDecodedLine.freeNumber4
             , iex_free_Number5 = vDecodedLine.freeNumber5
             , iex_unit_price = vDecodedLine.UnitPrice
             , a_datecre = sysdate
             , a_idcre = pcs.PC_I_LIB_SESSION.getuserini
         where stm_inventory_external_line_id = tplInventory_External_Lines.stm_inventory_external_line_id;
      end if;

      fetch crInventory_External_Lines
       into tplInventory_External_Lines;
    end loop;

    close crInventory_External_Lines;
  end decode_inv_csv2;

  procedure decode_inv(aStm_Inventory_External_Id Stm_Inventory_External.Stm_Inventory_External_id%type, aPartDecode number)
  is
    /* curseur récupérant les lignes importées */
    cursor crInventory_External_Lines(pStm_Inventory_External_Id Stm_Inventory_External.Stm_Inventory_External_id%type)
    is
      select stm_inventory_external_line_id
           , iex_input_line
           , c_inventory_ext_line_status
        from stm_inventory_external_line iex
       where stm_inventory_external_id = pStm_inventory_external_id
         and iex.iex_is_validated = 0;

    tplInventory_External_Lines crInventory_External_Lines%rowtype;
    vDecodedLine                DecodedLineRec;
    vDummyChar                  varchar2(100);
  begin
    open crInventory_External_Lines(aStm_Inventory_External_id);

    fetch crInventory_External_Lines
     into tplInventory_External_Lines;

    while crInventory_External_Lines%found loop
      if    (aPartDecode = 0)
         or (    aPartDecode = 1
             and tplInventory_External_lines.c_inventory_ext_line_status between '100' and '199') then
        /* découpage de la ligne lue */
        vDecodedLine.Inv_Goo_Major_Reference  := trim(substr(tplInventory_External_Lines.iex_Input_Line, 001, 030) );
        vDecodedLine.Inv_StoDescription       := trim(substr(tplInventory_External_Lines.iex_Input_Line, 031, 010) );
        vDecodedLine.Inv_LocDescription       := trim(substr(tplInventory_External_Lines.iex_Input_Line, 041, 010) );
        vDecodedLine.Inv_Qty                  := trim(substr(tplInventory_External_Lines.iex_Input_Line, 051, 016) );
        vDecodedLine.Inv_Char_value_1         := trim(substr(tplInventory_External_Lines.iex_Input_Line, 067, 030) );
        vDecodedLine.Inv_Char_value_2         := trim(substr(tplInventory_External_Lines.iex_Input_Line, 097, 030) );
        vDecodedLine.Inv_Char_value_3         := trim(substr(tplInventory_External_Lines.iex_Input_Line, 127, 030) );
        vDecodedLine.Inv_Char_value_4         := trim(substr(tplInventory_External_Lines.iex_Input_Line, 157, 030) );
        vDecodedLine.Inv_Char_value_5         := trim(substr(tplInventory_External_Lines.iex_Input_Line, 187, 030) );
        vDecodedLine.freeDate1                := to_date(trim(substr(tplInventory_External_Lines.iex_Input_Line, 217, 010) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate2                := to_date(trim(substr(tplInventory_External_Lines.iex_Input_Line, 227, 010) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate3                := to_date(trim(substr(tplInventory_External_Lines.iex_Input_Line, 237, 010) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate4                := to_date(trim(substr(tplInventory_External_Lines.iex_Input_Line, 247, 010) ), 'dd/mm/yyyy');
        vDecodedLine.freeDate5                := to_date(trim(substr(tplInventory_External_Lines.iex_Input_Line, 257, 010) ), 'dd/mm/yyyy');
        vDecodedLine.freeText1                := trim(substr(tplInventory_External_Lines.iex_Input_Line, 267, 100) );
        vDecodedLine.freeText2                := trim(substr(tplInventory_External_Lines.iex_Input_Line, 367, 100) );
        vDecodedLine.freeText3                := trim(substr(tplInventory_External_Lines.iex_Input_Line, 467, 100) );
        vDecodedLine.freeText4                := trim(substr(tplInventory_External_Lines.iex_Input_Line, 567, 100) );
        vDecodedLine.freeText5                := trim(substr(tplInventory_External_Lines.iex_Input_Line, 667, 100) );
        vDecodedLine.freeNumber1              := to_number(trim(substr(tplInventory_External_Lines.iex_Input_Line, 767, 015) ), '99999999999.9999');
        vDecodedLine.freeNumber2              := to_number(trim(substr(tplInventory_External_Lines.iex_Input_Line, 782, 015) ), '99999999999.9999');
        vDecodedLine.freeNumber3              := to_number(trim(substr(tplInventory_External_Lines.iex_Input_Line, 797, 015) ), '99999999999.9999');
        vDecodedLine.freeNumber4              := to_number(trim(substr(tplInventory_External_Lines.iex_Input_Line, 812, 015) ), '99999999999.9999');
        vDecodedLine.freeNumber5              := to_number(trim(substr(tplInventory_External_Lines.iex_Input_Line, 827, 015) ), '99999999999.9999');
        vDecodedLine.UnitPrice                := to_number(trim(substr(tplInventory_External_Lines.iex_Input_Line, 842, 015) ), '99999999999.9999');

        /* décodage des informations découpées */

        /* (1) récupération de gco_good_id */
        begin
          select Gco_good_id
            into vDecodedLine.Inv_Gco_good_id
            from Gco_good
           where goo_major_reference = rtrim(vDecodedLine.Inv_goo_Major_Reference);
        exception
          when no_data_found then
            vDecodedLine.Inv_Gco_Good_id  := null;
        end;

        /* (2a) récupération des ID de caractérisations gérées en stock */
        GCO_FUNCTIONS.GetListOfStkChar(vDecodedLine.Inv_Gco_good_id
                                     , vDecodedLine.Inv_Gco1_Characterization_id
                                     , vDecodedLine.Inv_Gco2_characterization_id
                                     , vDecodedLine.Inv_Gco3_Characterization_id
                                     , vDecodedLine.Inv_Gco4_Characterization_id
                                     , vDecodedLine.Inv_Gco5_Characterization_id
                                     ,
                                       -- les valeurs retournées pour le "type" de caractérisations ne sont pas utiliées
                                       vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     ,
                                       -- les valeurs retournées pour les "descriptions" de caractérisations ne sont pas utilisées
                                       vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                     , vDummyChar
                                      );

        /* (2b) récupération des valeurs de caractérisations pour les caractérisations gérées en stock */
        if vDecodedLine.Inv_Gco1_characterization_id is null then
          vDecodedLine.Inv_Char_Value_1  := null;
        end if;

        if vDecodedLine.Inv_Gco2_characterization_id is null then
          vDecodedLine.Inv_Char_Value_2  := null;
        end if;

        if vDecodedLine.Inv_Gco3_characterization_id is null then
          vDecodedLine.Inv_Char_Value_3  := null;
        end if;

        if vDecodedLine.Inv_Gco4_characterization_id is null then
          vDecodedLine.Inv_Char_Value_4  := null;
        end if;

        if vDecodedLine.Inv_Gco5_characterization_id is null then
          vDecodedLine.Inv_Char_Value_5  := null;
        end if;

        /* (3) récupération de ID du stock */
        begin
          select stm_stock_id
            into vDecodedLine.Inv_Stm_stock_id
            from Stm_stock
           where Sto_Description = rtrim(vDecodedLine.Inv_StoDescription);
        exception
          when no_data_found then
            vDecodedLine.Inv_Stm_stock_id  := null;
        end;

        /* (4) récupération de ID de l'emplacement */
        begin
          select stm_location_id
            into vDecodedLine.Inv_Stm_location_id
            from Stm_location
           where Loc_Description = rtrim(vDecodedLine.Inv_LocDescription);
        exception
          when no_data_found then
            vDecodedLine.Inv_Stm_Location_id  := null;
          when too_many_rows then
            vDecodedLine.Inv_Stm_Location_id  := null;
        end;

        /* (4) récupération de la quantité */
        begin
          vDecodedLine.Inv_Quantity  := to_number(rtrim(ltrim(vDecodedLine.Inv_Qty) ) );
        exception
          when others then
            vDecodedLine.Inv_Quantity  := 0;
        end;

        /* mise à jour des données décodées */
        update stm_inventory_external_line
           set gco_good_Id = vDecodedLine.Inv_gco_good_id
             , stm_stock_id = vDecodedLine.Inv_stm_stock_id
             , stm_location_id = vDecodedLine.Inv_stm_location_id
             , iex_major_reference = vDecodedLine.Inv_goo_Major_Reference
             , iex_sto_description = vDecodedLine.Inv_StoDescription
             , iex_loc_description = vDecodedLine.Inv_LocDescription
             , iex_characterization_value_1 = vDecodedLine.Inv_Char_value_1
             , iex_characterization_value_2 = vDecodedLine.Inv_Char_value_2
             , iex_characterization_value_3 = vDecodedLine.Inv_Char_value_3
             , iex_characterization_value_4 = vDecodedLine.Inv_Char_value_4
             , iex_characterization_value_5 = vDecodedLine.Inv_Char_value_5
             , gco_characterization_id = vDecodedLine.Inv_Gco1_characterization_id
             , gco_gco_characterization_id = vDecodedLine.Inv_Gco2_characterization_id
             , gco2_gco_characterization_id = vDecodedLine.Inv_Gco3_characterization_id
             , gco3_gco_characterization_id = vDecodedLine.Inv_Gco4_characterization_id
             , gco4_gco_characterization_id = vDecodedLine.Inv_Gco5_characterization_id
             , iex_quantity = vDecodedLine.Inv_Quantity
             , c_inventory_ext_line_status = '001'
             , iex_free_date1 = vDecodedLine.freeDate1
             , iex_free_date2 = vDecodedLine.freeDate2
             , iex_free_date3 = vDecodedLine.freeDate3
             , iex_free_date4 = vDecodedLine.freeDate4
             , iex_free_date5 = vDecodedLine.freeDate5
             , iex_free_Text1 = vDecodedLine.freeText1
             , iex_free_Text2 = vDecodedLine.freeText2
             , iex_free_Text3 = vDecodedLine.freeText3
             , iex_free_Text4 = vDecodedLine.freeText4
             , iex_free_Text5 = vDecodedLine.freeText5
             , iex_free_Number1 = vDecodedLine.freeNumber1
             , iex_free_Number2 = vDecodedLine.freeNumber2
             , iex_free_Number3 = vDecodedLine.freeNumber3
             , iex_free_Number4 = vDecodedLine.freeNumber4
             , iex_free_Number5 = vDecodedLine.freeNumber5
             , iex_unit_price = vDecodedLine.UnitPrice
             , a_datecre = sysdate
             , a_idcre = pcs.PC_I_LIB_SESSION.getuserini
         where stm_inventory_external_line_id = tplInventory_External_Lines.stm_inventory_external_line_id;
      end if;

      fetch crInventory_External_Lines
       into tplInventory_External_Lines;
    end loop;

    close crInventory_External_Lines;
  end decode_inv;
end STM_INVENTORY_DECODE;
