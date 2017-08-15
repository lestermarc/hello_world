--------------------------------------------------------
--  DDL for Package Body IMP_PTC_TARIFF
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_PTC_TARIFF" 
as
  lcDomain constant varchar2(15) := 'PTC';

  /**
  * procedure pInsertTariffTable
  * Description
  *    Contrôle le format de la tabelle de prix. La tabelle est transmise sous la forme de [Qté de]-[Qté à]-[Prix]-[Forfaitaire]
  * @created age 25.07.2013
  * @lastUpdate
  * @public
  * @param iTariffTable       : Tabelle de prix
  * @param iTariffTableNumber : Numéro de la tabelle (1 à 12)
  * @param iImportID          : Id de la ligne d'import concernée
  * @param iExcelLine         : Ligne Excel d'origine
  */
  procedure pCheckTariffTable(iTariffTable in varchar2, iTariffTableNumber in varchar2, iImportId in number, iExcelLine in varchar2)
  as
  begin
    if     (iTariffTable is not null)
       and (    (nvl(PCS.ExtractLine(aStrText => iTariffTable, aNoLine => 1, aCharSep => '-'), -1) < 0)
            or (nvl(PCS.ExtractLine(aStrText => iTariffTable, aNoLine => 2, aCharSep => '-'), -1) < 0)
            or (nvl(PCS.ExtractLine(aStrText => iTariffTable, aNoLine => 3, aCharSep => '-'), -1) < 0)
            or (nvl(PCS.ExtractLine(aStrText => iTariffTable, aNoLine => 4, aCharSep => '-'), 0) < 0)
           ) then
      IMP_PRC_TOOLS.insertError(lcDomain
                              , iImportId
                              , iExcelLine
                              , replace(pcs.PC_FUNCTIONS.TranslateWord('La tabelle de prix [XXXXX] est invalide'), '[XXXXX]'
                                      , '''' || iTariffTableNumber || '''')
                               );
    end if;
  exception
    when others then
      if sqlcode = -6502 then
        /* Insertion dans la table d'erreur */
        IMP_PRC_TOOLS.insertError(lcDomain
                                , iImportId
                                , iExcelLine
                                , replace(pcs.PC_FUNCTIONS.TranslateWord('La tabelle de prix [XXXXX] est invalide')
                                        , '[XXXXX]'
                                        , '''' || iTariffTableNumber || ''''
                                         )
                                 );
      else
        IMP_PRC_TOOLS.insertError(lcDomain, iImportId, iExcelLine, sqlerrm);
      end if;
  end pCheckTariffTable;

  /**
  * procedure pInsertTariffTable
  * Description
  *    Insère une tabelle de prix. La tabelle est transmise sous la forme de [Qté de]-[Qté à]-[Prix]-[Forfaitaire]
  * @created age 25.07.2013
  * @lastUpdate
  * @public
  * @param iTariffId    : Id du tariff concerné
  * @param iTariffTable : Tabelle de prix
  */
  procedure pInsertTariffTable(iTariffId in number, iTariffTable in varchar2)
  as
  begin
    if iTariffTable is not null then
      insert into PTC_TARIFF_TABLE
                  (PTC_TARIFF_TABLE_ID
                 , PTC_TARIFF_ID
                 , TTA_FROM_QUANTITY
                 , TTA_TO_QUANTITY
                 , TTA_PRICE
                 , TTA_FLAT_RATE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , iTariffId
                 , PCS.ExtractLine(aStrText => iTariffTable, aNoLine => 1, aCharSep => '-')   --left_
                 , PCS.ExtractLine(aStrText => iTariffTable, aNoLine => 2, aCharSep => '-')   --right_
                 , PCS.ExtractLine(aStrText => iTariffTable, aNoLine => 3, aCharSep => '-')   --price_
                 , nvl(PCS.ExtractLine(aStrText => iTariffTable, aNoLine => 4, aCharSep => '-'), 0)   --nvl(lnFlatRate, 0)
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                  );
    end if;
  end pInsertTariffTable;

  /**
  * Description
  *    importation des données d'Excel dans la table temporaire IMP_PTC_TARIFF_. Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_PTC_TARIFF(
    pGOO_MAJOR_REFERENCE     varchar2
  , pTARIF_TYPE              varchar2
  , pCURRENCY                varchar2
  , pDIC_TARIFF_ID           varchar2
  , pTRF_NET_TARIFF          varchar2
  , pTRF_SPECIAL_TARIFF      varchar2
  , pTRF_DESCR               varchar2
  , pPER_KEY                 varchar2
  , pTRF_UNIT                varchar2
  , pC_ROUND_TYPE            varchar2
  , pTRF_ROUND_AMOUNT        varchar2
  , pTRF_STARTING_DATE       varchar2
  , pTRF_ENDING_DATE         varchar2
  , pUNIQUE_PRICE            varchar2
  , pTABLE_1                 varchar2
  , pTABLE_2                 varchar2
  , pTABLE_3                 varchar2
  , pTABLE_4                 varchar2
  , pTABLE_5                 varchar2
  , pTABLE_6                 varchar2
  , pTABLE_7                 varchar2
  , pTABLE_8                 varchar2
  , pTABLE_9                 varchar2
  , pTABLE_10                varchar2
  , pTABLE_11                varchar2
  , pTABLE_12                varchar2
  , pCPR_DEFAULT             varchar2
  , pTTA_FLAT_RATE           integer
  , pFREE1                   varchar2
  , pFREE2                   varchar2
  , pFREE3                   varchar2
  , pFREE4                   varchar2
  , pFREE5                   varchar2
  , pFREE6                   varchar2
  , pFREE7                   varchar2
  , pFREE8                   varchar2
  , pFREE9                   varchar2
  , pFREE10                  varchar2
  , pEXCEL_LINE              integer
  , pRESULT              out integer
  )
  is
  begin
    --Insertion dans la table IMP_PTC_TARIFF
    insert into IMP_PTC_TARIFF_
                (id
               , EXCEL_LINE
               , GOO_MAJOR_REFERENCE
               , TARIF_TYPE
               , CURRENCY
               , DIC_TARIFF_ID
               , TRF_NET_TARIFF
               , TRF_SPECIAL_TARIFF
               , TRF_DESCR
               , PER_KEY
               , TRF_UNIT
               , C_ROUND_TYPE
               , TRF_ROUND_AMOUNT
               , TRF_STARTING_DATE
               , TRF_ENDING_DATE
               , UNIQUE_PRICE
               , TABLE_1
               , TABLE_2
               , TABLE_3
               , TABLE_4
               , TABLE_5
               , TABLE_6
               , TABLE_7
               , TABLE_8
               , TABLE_9
               , TABLE_10
               , TABLE_11
               , TABLE_12
               , CPR_DEFAULT
               , TTA_FLAT_RATE
               , FREE1
               , FREE2
               , FREE3
               , FREE4
               , FREE5
               , FREE6
               , FREE7
               , FREE8
               , FREE9
               , FREE10
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , pEXCEL_LINE
               , trim(pGOO_MAJOR_REFERENCE)
               , trim(pTARIF_TYPE)
               , trim(pCURRENCY)
               , trim(pDIC_TARIFF_ID)
               , trim(pTRF_NET_TARIFF)
               , trim(pTRF_SPECIAL_TARIFF)
               , trim(pTRF_DESCR)
               , trim(pPER_KEY)
               , trim(pTRF_UNIT)
               , trim(pC_ROUND_TYPE)
               , trim(pTRF_ROUND_AMOUNT)
               , trim(pTRF_STARTING_DATE)
               , trim(pTRF_ENDING_DATE)
               , trim(pUNIQUE_PRICE)
               , trim(pTABLE_1)
               , trim(pTABLE_2)
               , trim(pTABLE_3)
               , trim(pTABLE_4)
               , trim(pTABLE_5)
               , trim(pTABLE_6)
               , trim(pTABLE_7)
               , trim(pTABLE_8)
               , trim(pTABLE_9)
               , trim(pTABLE_10)
               , trim(pTABLE_11)
               , trim(pTABLE_12)
               , trim(pCPR_DEFAULT)
               , trim(pTTA_FLAT_RATE)
               , trim(pFREE1)
               , trim(pFREE2)
               , trim(pFREE3)
               , trim(pFREE4)
               , trim(pFREE5)
               , trim(pFREE6)
               , trim(pFREE7)
               , trim(pFREE8)
               , trim(pFREE9)
               , trim(pFREE10)
               , sysdate
               , IMP_LIB_TOOLS.getImportUserIni
                );

    --Nombre de ligne insérées
    pResult  := 1;
    commit;
  end IMP_TMP_PTC_TARIFF;

  /**
  * Description
  *    Contrôle des données de la table IMP_PTC_TARIFF_ avant importation.
  */
  procedure IMP_PTC_TARIFF_CTRL
  is
    tmp            varchar2(200);
    tmp_int        number(10);
    tmp_date       date;
    tmp_date2      date;
    index1         integer;
    index2         integer;
    tmp_per_key    varchar2(20);
    tmp_per_key_nb varchar2(20);
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    --Parcours de toutes les lignes de la table IMP_PTC_TARIFF_
    for tdata in (select *
                    from IMP_PTC_TARIFF_) loop
      --> Est-ce que tous les champs obligatoires sont présents ?
      if (   tdata.GOO_MAJOR_REFERENCE is null
          or tdata.TARIF_TYPE is null) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
      else
        --> Est-ce que le bien existe ?
        IMP_PRC_TOOLS.checkGoodExists(tdata.GOO_MAJOR_REFERENCE, lcDomain, tdata.id, tdata.EXCEL_LINE);

--******************************************************************
--Est-ce que la monnaie comptable existe ?
--******************************************************************
      --Contrôle de l'existance de la monnaie
        begin
          select CURRENCY
            into tmp
            from pcs.PC_CURR
           where currency = nvl(tdata.CURRENCY, ACS_FUNCTION.GETLOCALCURRENCYNAME() );
        exception
          when no_data_found then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_CURRENCY') );
        end;

--******************************************************************
--Est-ce que  le code tarif existe ?  Ou le code prix de revient ?
--******************************************************************
        --S'il s'agit d'une PRF
        if (tdata.tarif_type = '2') then
          IMP_PRC_TOOLS.checkDicoValue('DIC_FIXED_COSTPRICE_DESCR', tdata.DIC_TARIFF_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        --Sinon c'est un tarif d'achat ou de vente
        else
          if (tdata.DIC_TARIFF_ID is not null) then
            IMP_PRC_TOOLS.checkDicoValue('DIC_TARIFF', tdata.DIC_TARIFF_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
          end if;
        end if;

        --> Tarif net
        IMP_PRC_TOOLS.checkBooleanValue('TRF_NET_TARIFF', nvl(tdata.TRF_NET_TARIFF, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Tarif action
        IMP_PRC_TOOLS.checkBooleanValue('TRF_SPECIAL_TARIFF', nvl(tdata.TRF_SPECIAL_TARIFF, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);
--******************************************************************
--Est-ce que le tiers existe ?
--******************************************************************
--Extraction du tiers et du numéro (per_key1 ou per_key2)
        tmp_per_key     := substr(tdata.per_key, 3, length(tdata.per_key) - 2);
        tmp_per_key_nb  := substr(tdata.per_key, 0, 1);

        if (tmp_per_key is not null) then
          if (tmp_per_key_nb = 1) then
            begin
              select per_key1
                into tmp
                from pac_person
               where per_key1 = tmp_per_key;
            exception
              when no_data_found then
                IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_THIRD') );
            end;
          else
            begin
              select per_key2
                into tmp
                from pac_person
               where per_key2 = tmp_per_key;
            exception
              when no_data_found then
                IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_THIRD') );
            end;
          end if;
        end if;

--***********************************************************************************
--Est-ce qu'il existe déjà un tarif pour ce tiers et ce produit et ce type de tarif
--et dans la même monnaie ?
--***********************************************************************************
        begin
          --S'il s'agit d'un prix de revient fixe
          if (tdata.tarif_type = '2') then
            if (tmp_per_key_nb = 1) then
              select count(*)
                into tmp_int
                from ptc_fixed_costprice
               where DIC_FIXED_COSTPRICE_DESCR_ID = tdata.dic_tariff_id
                 and nvl(pac_third_id, 0) = nvl( (select pac_person_id
                                                    from pac_person
                                                   where per_key1 = tmp_per_key), 0)
                 and gco_good_id = (select gco_good_id
                                      from gco_good
                                     where goo_major_reference = tdata.goo_major_reference);
            else
              select count(*)
                into tmp_int
                from ptc_fixed_costprice
               where DIC_FIXED_COSTPRICE_DESCR_ID = tdata.dic_tariff_id
                 and nvl(pac_third_id, 0) = nvl( (select pac_person_id
                                                    from pac_person
                                                   where per_key2 = tmp_per_key), 0)
                 and gco_good_id = (select gco_good_id
                                      from gco_good
                                     where goo_major_reference = tdata.goo_major_reference);
            end if;
          else
            if (tmp_per_key_nb = 1) then
              select count(*)
                into tmp_int
                from ptc_tariff
               where c_tariff_type =(case
                                       when tdata.tarif_type = 1 then 'A_FACTURER'
                                       else 'A_PAYER'
                                     end)
                 and nvl(dic_tariff_id, 0) = nvl(tdata.dic_tariff_id, 0)
                 and nvl(pac_third_id, 0) = nvl( (select pac_person_id
                                                    from pac_person
                                                   where per_key1 = tmp_per_key), 0)
                 and gco_good_id = (select gco_good_id
                                      from gco_good
                                     where goo_major_reference = tdata.goo_major_reference)
                 and acs_financial_currency_id = (select acs_financial_currency_id
                                                    from pcs.pc_curr curr
                                                   where curr.currency = tdata.currency);
            else
              select count(*)
                into tmp_int
                from ptc_tariff
               where c_tariff_type =(case
                                       when tdata.tarif_type = 1 then 'A_FACTURER'
                                       else 'A_PAYER'
                                     end)
                 and nvl(dic_tariff_id, 0) = nvl(tdata.dic_tariff_id, 0)
                 and nvl(pac_third_id, 0) = nvl( (select pac_person_id
                                                    from pac_person
                                                   where per_key2 = tmp_per_key), 0)
                 and gco_good_id = (select gco_good_id
                                      from gco_good
                                     where goo_major_reference = tdata.goo_major_reference)
                 and acs_financial_currency_id = (select acs_financial_currency_id
                                                    from pcs.pc_curr curr
                                                   where curr.currency = tdata.currency);
            end if;
          end if;

          --Si on trouve une entrée c'est que le tarif existe déjà
          if (tmp_int > 0) then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_TARIFF_EXIST') );
          end if;
        exception
          when no_data_found then
            null;
        end;

        --> Unité tarifaire
        if (tdata.TRF_UNIT is not null) then
          IMP_PRC_TOOLS.checkNumberValue('PTC_TARIFF', 'TRF_UNIT', tdata.TRF_UNIT, lcDomain, tdata.id, tdata.EXCEL_LINE, false);
        end if;

        --> Type d'arrondi
        IMP_PRC_TOOLS.checkDescodeValue('C_ROUND_TYPE', nvl(tdata.C_ROUND_TYPE, '0'), '{0,1,2,3,4}', lcDomain, tdata.id, tdata.EXCEL_LINE);

        --> Monant d'arrondi
        IMP_PRC_TOOLS.checkNumberValue('PTC_TARIFF', 'TRF_ROUND_AMOUNT', nvl(tdata.TRF_ROUND_AMOUNT, 0), lcDomain, tdata.id, tdata.EXCEL_LINE, true);

        --> Prix unique
        if (tdata.UNIQUE_PRICE is not null) then
          IMP_PRC_TOOLS.checkNumberValue('PTC_TARIFF_TABLE', 'TTA_PRICE', nvl(tdata.UNIQUE_PRICE, 0), lcDomain, tdata.id, tdata.EXCEL_LINE, true);
        end if;

--******************************************************************
--Est-ce qu'il y a soit un prix unique, soit des tabelles de prix ?
--******************************************************************
--S'il y a à la fois un prix unique et des tabelles, alors c'est une erreur
        if     (tdata.unique_price is not null)
           and (   tdata.table_1 is not null
                or tdata.table_2 is not null
                or tdata.table_3 is not null
                or tdata.table_4 is not null
                or tdata.table_5 is not null
                or tdata.table_6 is not null
                or tdata.table_7 is not null
                or tdata.table_8 is not null
                or tdata.table_9 is not null
                or tdata.table_10 is not null
                or tdata.table_11 is not null
                or tdata.table_12 is not null
               ) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_BOTH_PRICES') );
        end if;

        --S'il n'y a pas de prix unique et que les tabelles sont vides alors c'est une erreur
        if     (tdata.unique_price is null)
           and (    tdata.table_1 is null
                and tdata.table_2 is null
                and tdata.table_3 is null
                and tdata.table_4 is null
                and tdata.table_5 is null
                and tdata.table_6 is null
                and tdata.table_7 is null
                and tdata.table_8 is null
                and tdata.table_9 is null
                and tdata.table_10 is null
                and tdata.table_11 is null
                and tdata.table_12 is null
               ) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_NONE_PRICE') );
        end if;

        --> Type de tarif
        IMP_PRC_TOOLS.checkDescodeValue('TARIF_TYPE', tdata.TARIF_TYPE, '{0,1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);

        --> Est-ce que les tablles de prix sont valides ?
        pCheckTariffTable(tdata.TABLE_1, '1', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_2, '2', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_3, '3', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_4, '4', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_5, '5', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_6, '6', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_7, '7', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_8, '8', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_9, '9', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_10, '10', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_11, '11', tdata.id, tdata.EXCEL_LINE);
        pCheckTariffTable(tdata.TABLE_12, '12', tdata.id, tdata.EXCEL_LINE);

--******************************************************************
--Est-ce que les dates sont valides ?
--******************************************************************
        if (   tdata.trf_starting_date is not null
            or tdata.trf_ending_date is not null) then
          --Test de conversion des dates
          begin
            --contrôle le format de la date
            select to_date(tdata.TRF_STARTING_DATE, 'DD.MM.YYYY')
              into tmp_date
              from dual;

            select to_date(tdata.TRF_ENDING_DATE, 'DD.MM.YYYY')
              into tmp_date2
              from dual;

            --Si la date de fin est plus petite que la date de départ
            if (tmp_date2 < tmp_date) then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_DATE_INTERVAL') );
            end if;
          exception
            when others then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_DATES') );
          end;
        end if;

--*****************************************************************************
--Est-ce qu'il y au minimum et au maximum un prix de revient fixe par défaut
--entre ce qui existe et ce qui est à importer ?
--*****************************************************************************
--S'il s'agit d'un prix de revient fixe
        if (tdata.tarif_type = '2') then
          select (select count(pri.ptc_fixed_costprice_id)
                    from ptc_fixed_costprice pri
                       , gco_good goo
                   where goo.gco_good_id = pri.gco_good_id
                     and goo.goo_major_reference = tdata.goo_major_reference
                     and pri.cpr_default = 1) +
                 (select count(pri.id)
                    from IMP_PTC_TARIFF_ pri
                       , gco_good goo
                   where goo.goo_major_reference = pri.goo_major_reference
                     and goo.goo_major_reference = tdata.goo_major_reference
                     and pri.cpr_default = 1)
            into tmp_int
            from dual;

          if (tmp_int <> 1) then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_PTC_DEFAULT') );
          end if;
        end if;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_PTC_TARIFF_CTRL;

  /**
  * Description
  *    Importation des données tarifs achat et vente
  */
  procedure IMP_PTC_TARIFF_IMPORT
  is
    tmp            integer;
    tmp_int        integer;
    id_tarif       number(12);
    tmp_per_key    varchar2(20);
    tmp_per_key_nb varchar2(20);
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes à insérer
    for tdata in (select *
                    from IMP_PTC_TARIFF_) loop
      --Sauvegarde de l'id du tarif pour le reprendre dans la table des prix
      id_tarif        := GetNewId;
      --Extraction du tiers et du numéro (per_key1 ou per_key2)
      tmp_per_key     := substr(tdata.per_key, 3, length(tdata.per_key) - 2);
      tmp_per_key_nb  := substr(tdata.per_key, 0, 1);

      --S'il s'agit d'un prix de revient fixe à insérer
      if (tdata.tarif_type = '2') then
--*****************************************************************************
--Insertion des prix de revient fixe
--*****************************************************************************
        insert into PTC_FIXED_COSTPRICE
                    (PTC_FIXED_COSTPRICE_ID
                   , C_COSTPRICE_STATUS
                   , GCO_GOOD_ID
                   , PAC_THIRD_ID
                   , CPR_DESCR
                   , CPR_PRICE
                   , CPR_DEFAULT
                   , FCP_START_DATE
                   , FCP_END_DATE
                   , DIC_FIXED_COSTPRICE_DESCR_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (id_tarif
                   , 'ACT'
                   , (select gco_good_id
                        from gco_good
                       where goo_major_reference = tdata.goo_major_reference)
                   , (select case
                               when tmp_per_key_nb = 1 then (select pac_person_id
                                                               from pac_person
                                                              where per_key1 = tmp_per_key)
                               else (select pac_person_id
                                       from pac_person
                                      where per_key2 = tmp_per_key)
                             end
                        from dual)
                   , tdata.trf_descr
                   , tdata.unique_price
                   , tdata.cpr_default
                   , to_date(tdata.TRF_STARTING_DATE, 'DD.MM.YYYY')
                   , to_date(tdata.TRF_ENDING_DATE, 'DD.MM.YYYY')
                   , tdata.dic_tariff_id
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      else
--*****************************************************************************
--Insertion des tarifs
--*****************************************************************************
        insert into PTC_TARIFF
                    (PTC_TARIFF_ID
                   , GCO_GOOD_ID
                   , DIC_TARIFF_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , C_TARIFFICATION_MODE
                   , C_TARIFF_TYPE
                   , C_ROUND_TYPE
                   , PAC_THIRD_ID
                   , TRF_DESCR
                   , TRF_ROUND_AMOUNT
                   , TRF_UNIT
                   , TRF_SQL_CONDITIONAL
                   , TRF_STARTING_DATE
                   , TRF_ENDING_DATE
                   , PTC_FIXED_COSTPRICE_ID
                   , PTC_CALC_COSTPRICE_ID
                   , DIC_PUR_TARIFF_STRUCT_ID
                   , DIC_SALE_TARIFF_STRUCT_ID
                   , A_DATECRE
                   , A_IDCRE
                   , TRF_NET_TARIFF
                   , TRF_SPECIAL_TARIFF
                    )
             values (id_tarif
                   , (select gco_good_id
                        from gco_good
                       where goo_major_reference = tdata.goo_major_reference)
                   , tdata.DIC_TARIFF_ID
                   , (case
                        when tdata.currency is not null then (select acs_financial_currency_id
                                                                from acs_financial_currency
                                                               where pc_curr_id = (select pc_curr_id
                                                                                     from pcs.pc_curr
                                                                                    where currency = tdata.currency) )
                        else ACS_FUNCTION.GETLOCALCURRENCYID()
                      end)
                   , '1'
                   , (case
                        when tdata.tarif_type = 1 then 'A_FACTURER'
                        else 'A_PAYER'
                      end)
                   , nvl(tdata.c_round_type, 0)   --si type d'arrondi non spécifié, on met le code 0 (pas d'arrondi)
                   , (select case
                               when(tmp_per_key_nb = 1) then (select pac_person_id
                                                                from pac_person
                                                               where per_key1 = tmp_per_key)
                               else (select pac_person_id
                                       from pac_person
                                      where per_key2 = tmp_per_key)
                             end
                        from dual)
                   , tdata.trf_descr
                   , nvl(tdata.trf_round_amount, 0)
                   , nvl(tdata.trf_unit, 1)
                   , null
                   , to_date(tdata.TRF_STARTING_DATE, 'DD.MM.YYYY')
                   , to_date(tdata.TRF_ENDING_DATE, 'DD.MM.YYYY')
                   , null
                   , null
                   , null
                   , null
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                   , nvl(tdata.trf_net_tariff, 0)
                   , nvl(tdata.trf_special_tariff, 0)
                    );

        --Doit on insérer un prix unique ?
        if (tdata.UNIQUE_PRICE is not null) then
          pInsertTariffTable(id_tarif, '0-0-' || tdata.UNIQUE_PRICE || '-' || tdata.TTA_FLAT_RATE);
        else
          --Insertion des tabelles de prix
          pInsertTariffTable(id_tarif, tdata.TABLE_1);
          pInsertTariffTable(id_tarif, tdata.TABLE_2);
          pInsertTariffTable(id_tarif, tdata.TABLE_3);
          pInsertTariffTable(id_tarif, tdata.TABLE_4);
          pInsertTariffTable(id_tarif, tdata.TABLE_5);
          pInsertTariffTable(id_tarif, tdata.TABLE_6);
          pInsertTariffTable(id_tarif, tdata.TABLE_7);
          pInsertTariffTable(id_tarif, tdata.TABLE_8);
          pInsertTariffTable(id_tarif, tdata.TABLE_9);
          pInsertTariffTable(id_tarif, tdata.TABLE_10);
          pInsertTariffTable(id_tarif, tdata.TABLE_11);
          pInsertTariffTable(id_tarif, tdata.TABLE_12);
        end if;
      end if;

      --Insertion dans historique
      insert into IMP_HIST_PTC_TARIFF
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , GOO_MAJOR_REFERENCE
                 , TARIF_TYPE
                 , DIC_TARIFF_ID
                 , TRF_NET_TARIFF
                 , TRF_SPECIAL_TARIFF
                 , TRF_DESCR
                 , PER_KEY
                 , TRF_UNIT
                 , C_ROUND_TYPE
                 , TRF_ROUND_AMOUNT
                 , TRF_STARTING_DATE
                 , TRF_ENDING_DATE
                 , UNIQUE_PRICE
                 , TABLE_1
                 , TABLE_2
                 , TABLE_3
                 , TABLE_4
                 , TABLE_5
                 , TABLE_6
                 , TABLE_7
                 , TABLE_8
                 , TABLE_9
                 , TABLE_10
                 , TABLE_11
                 , TABLE_12
                 , CURRENCY
                 , TTA_FLAT_RATE
                 , FREE1
                 , FREE2
                 , FREE3
                 , FREE4
                 , FREE5
                 , FREE6
                 , FREE7
                 , FREE8
                 , FREE9
                 , FREE10
                 , CPR_DEFAULT
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , sysdate
                 , tdata.excel_line
                 , tdata.GOO_MAJOR_REFERENCE
                 , tdata.TARIF_TYPE
                 , tdata.DIC_TARIFF_ID
                 , tdata.TRF_NET_TARIFF
                 , tdata.TRF_SPECIAL_TARIFF
                 , tdata.TRF_DESCR
                 , tdata.PER_KEY
                 , tdata.TRF_UNIT
                 , tdata.C_ROUND_TYPE
                 , tdata.TRF_ROUND_AMOUNT
                 , tdata.TRF_STARTING_DATE
                 , tdata.TRF_ENDING_DATE
                 , tdata.UNIQUE_PRICE
                 , tdata.TABLE_1
                 , tdata.TABLE_2
                 , tdata.TABLE_3
                 , tdata.TABLE_4
                 , tdata.TABLE_5
                 , tdata.TABLE_6
                 , tdata.TABLE_7
                 , tdata.TABLE_8
                 , tdata.TABLE_9
                 , tdata.TABLE_10
                 , tdata.TABLE_11
                 , tdata.TABLE_12
                 , tdata.CURRENCY
                 , tdata.TTA_FLAT_RATE
                 , tdata.FREE1
                 , tdata.FREE2
                 , tdata.FREE3
                 , tdata.FREE4
                 , tdata.FREE5
                 , tdata.FREE6
                 , tdata.FREE7
                 , tdata.FREE8
                 , tdata.FREE9
                 , tdata.FREE10
                 , tdata.CPR_DEFAULT
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;
  end IMP_PTC_TARIFF_IMPORT;
end IMP_PTC_TARIFF;
