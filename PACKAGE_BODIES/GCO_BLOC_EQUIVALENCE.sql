--------------------------------------------------------
--  DDL for Package Body GCO_BLOC_EQUIVALENCE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_BLOC_EQUIVALENCE" 
is
  -- Màj des données complémentaires d'achat depuis le PRODUIT
  procedure UpdateDataPurchase(
    aGood_ID        in     GCO_GOOD.GCO_GOOD_ID%type
  , aDeleteListId   out    varchar2
  , aDeleteListStr  out    varchar2
  , aMakeDefListId  out    varchar2
  , aMakeDefListStr out    varchar2
  )
  is
    cursor CUR_GCO_EQUIVALENCE_GOOD
    is
      select distinct GCO_GOOD_ID
                 from GCO_COMPL_DATA_PURCHASE
                where PAC_SUPPLIER_PARTNER_ID is not null
                  and GCO_GOOD_ID in(select GCO_GCO_GOOD_ID
                                       from GCO_EQUIVALENCE_GOOD
                                      where GCO_GOOD_ID = aGood_ID)
             group by GCO_GOOD_ID
               having max(CPU_DEFAULT_SUPPLIER) = 0;

    cursor DeletePurchase(aGCO_GOOD_ID number)
    is
      select PUR.GCO_COMPL_DATA_PURCHASE_ID
        from GCO_COMPL_DATA_PURCHASE PUR
       where PUR.GCO_GOOD_ID = aGCO_GOOD_ID
         and PUR.GCO_GCO_GOOD_ID is not null
         and (   PUR.GCO_GCO_GOOD_ID not in(
                   select EQU.GCO_GCO_GOOD_ID
                     from GCO_EQUIVALENCE_GOOD EQU
                    where GCO_GOOD_ID = aGCO_GOOD_ID
                      and EQU.C_GEG_STATUS = '1'
                      and (   EQU.GEG_BEGIN_DATE is null
                           or EQU.GEG_BEGIN_DATE <= sysdate)
                      and (   EQU.GEG_END_DATE is null
                           or EQU.GEG_END_DATE >= sysdate) )
              or PUR.PAC_SUPPLIER_PARTNER_ID not in(select PAC_DIST_PARTNER_ID
                                                      from PAC_DISTRIBUTOR
                                                     where PAC_SUPPLIER_PARTNER_ID = PUR.PAC_PAC_SUPPLIER_PARTNER_ID
                                                       and C_DIST_STATUS = '1')
             );

    cursor DeleteEquivPurchase(aGCO_GOOD_ID number)
    is
      select GCO_COMPL_DATA_PURCHASE_ID
        from GCO_COMPL_DATA_PURCHASE PUR
       where PUR.GCO_GCO_GOOD_ID is null
         and PUR.PAC_PAC_SUPPLIER_PARTNER_ID is null
         and PUR.GCO_GOOD_ID in(select EQU.GCO_GCO_GOOD_ID
                                  from GCO_EQUIVALENCE_GOOD EQU
                                 where EQU.GCO_GOOD_ID = aGCO_GOOD_ID)
         and (   PUR.GCO_GOOD_ID not in(
                   select EQU.GCO_GCO_GOOD_ID
                     from GCO_EQUIVALENCE_GOOD EQU
                    where EQU.GCO_GCO_GOOD_ID = PUR.GCO_GOOD_ID
                      and EQU.C_GEG_STATUS = '1'
                      and (   EQU.GEG_BEGIN_DATE is null
                           or EQU.GEG_BEGIN_DATE <= sysdate)
                      and (   EQU.GEG_END_DATE is null
                           or EQU.GEG_END_DATE >= sysdate) )
              or PUR.PAC_SUPPLIER_PARTNER_ID not in(
                                  select PAC_DIST_PARTNER_ID
                                    from PAC_DISTRIBUTOR DIST
                                       , GCO_PRODUCT PDT
                                   where PDT.GCO_GOOD_ID = PUR.GCO_GOOD_ID
                                     and PDT.PAC_SUPPLIER_PARTNER_ID = DIST.PAC_SUPPLIER_PARTNER_ID
                                     and C_DIST_STATUS = '1')
             );

    DelDataPurchase       DeletePurchase%rowtype;
    DelDataEquivPurchase  DeleteEquivPurchase%rowtype;
    CurGcoEquivalenceGood CUR_GCO_EQUIVALENCE_GOOD%rowtype;
    PurID                 number;
    iDefault              integer;
    strGOO_MAJOR_REF      varchar2(30);
  begin
    -- création des données complémentaires d'achat au niveau des produits fabricants.
    insert into GCO_COMPL_DATA_PURCHASE
                (GCO_COMPL_DATA_PURCHASE_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_PAC_SUPPLIER_PARTNER_ID
               , CDA_COMPLEMENTARY_REFERENCE
               , CDA_SHORT_DESCRIPTION
               , CDA_LONG_DESCRIPTION
               , CDA_FREE_DESCRIPTION
               , DIC_UNIT_OF_MEASURE_ID
               , CDA_NUMBER_OF_DECIMAL
               , CPU_DEFAULT_SUPPLIER
               , CDA_CONVERSION_FACTOR
               , C_QTY_SUPPLY_RULE
               , C_ECONOMIC_CODE
               , C_TIME_SUPPLY_RULE
               , CPU_SUPPLY_DELAY
               , CPU_AUTOMATIC_GENERATING_PROP
               , A_DATECRE
               , A_IDCRE
                )
      select Init_id_seq.nextval   -- GCO_COMPL_DATA_PURCHASE_ID
           , NewDca.GCO_GCO_GOOD_ID   -- GCO_GOOD_ID
           , null   -- GCO_GCO_GOOD_ID
           , NewDca.PAC_SUPPLIER_PARTNER_ID   -- PAC_SUPPLIER_PARTNER_ID
           , null   -- PAC_PAC_SUPPLIER_PARTNER_ID
           , null   -- CDA_COMPLEMENTARY_REFERENCE
           , null   -- CDA_SHORT_DESCRIPTION
           , null   -- CDA_LONG_DESCRIPTION
           , null   -- CDA_FREE_DESCRIPTION
           , GOO.DIC_UNIT_OF_MEASURE_ID   -- DIC_UNIT_OF_MEASURE_ID
           , GOO.GOO_NUMBER_OF_DECIMAL   -- CDA_NUMBER_OF_DECIMAL
           , 0   -- CPU_DEFAULT_SUPPLIER
           , 1   -- CDA_CONVERSION_FACTOR
           , '1'   -- C_QTY_SUPPLY_RULE
           , '1'   -- C_ECONOMIC_CODE
           , '1'   -- C_TIME_SUPPLY_RULE
           , null   -- CPU_SUPPLY_DELAY
           , 1   -- CPU_AUTOMATIC_GENERATING_PROP
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_GOOD GOO
           , (select EQU.GCO_GCO_GOOD_ID
                   , PDI.PAC_DIST_PARTNER_ID PAC_SUPPLIER_PARTNER_ID
                from GCO_EQUIVALENCE_GOOD EQU
                   , GCO_PRODUCT PDT
                   , PAC_DISTRIBUTOR PDI
               where EQU.GCO_GOOD_ID = aGood_ID
                 and EQU.GCO_GCO_GOOD_ID = PDT.GCO_GOOD_ID
                 and EQU.C_GEG_STATUS = '1'
                 and (   EQU.GEG_BEGIN_DATE is null
                      or EQU.GEG_BEGIN_DATE <= sysdate)
                 and (   EQU.GEG_END_DATE is null
                      or EQU.GEG_END_DATE >= sysdate)
                 and PDT.PAC_SUPPLIER_PARTNER_ID = PDI.PAC_SUPPLIER_PARTNER_ID
                 and PDI.C_DIST_STATUS = '1'
              minus
              select EQU.GCO_GCO_GOOD_ID
                   , PUR.PAC_SUPPLIER_PARTNER_ID
                from GCO_EQUIVALENCE_GOOD EQU
                   , GCO_COMPL_DATA_PURCHASE PUR
               where EQU.GCO_GOOD_ID = aGood_ID
                 and EQU.GCO_GCO_GOOD_ID = PUR.GCO_GOOD_ID) NewDca
       where GOO.GCO_GOOD_ID = NewDca.GCO_GCO_GOOD_ID;

    -- Effacer les anciennes données complémentaires des "produits équivalents" du produit "générique"
    open DeleteEquivPurchase(aGood_ID);

    fetch DeleteEquivPurchase
     into DelDataEquivPurchase;

    -- Balayage des données complémentaires à effacer
    while DeleteEquivPurchase%found loop
      begin
        -- Vérifie si l'enregistrement n'est pas en cours d'utilisation et
        -- réserve l'enregistrement pour l'effacement de celui-ci
        select     GCO_COMPL_DATA_PURCHASE_ID
              into PurID
              from GCO_COMPL_DATA_PURCHASE
             where GCO_COMPL_DATA_PURCHASE_ID = DelDataEquivPurchase.GCO_COMPL_DATA_PURCHASE_ID
        for update nowait;

        -- Effacer les anciennes données complémentaires qui ne correspondent plus aux produits équivalents
        delete      GCO_COMPL_DATA_PURCHASE
              where GCO_COMPL_DATA_PURCHASE_ID = DelDataEquivPurchase.GCO_COMPL_DATA_PURCHASE_ID;
      exception
        when others then
          begin
            -- Recherche la réf du bien pour lequel on n'as pas reussi à effacer la donnée compl d'achat
            select GOO.GOO_MAJOR_REFERENCE
              into strGOO_MAJOR_REF
              from GCO_GOOD GOO
                 , GCO_COMPL_DATA_PURCHASE PUR
             where GOO.GCO_GOOD_ID = PUR.GCO_GOOD_ID
               and PUR.GCO_COMPL_DATA_PURCHASE_ID = DelDataEquivPurchase.GCO_COMPL_DATA_PURCHASE_ID;

            if aDeleteListId is null then
              aDeleteListStr  := ',' || strGOO_MAJOR_REF || ',';
              aDeleteListId   := ',' || to_char(DelDataEquivPurchase.GCO_COMPL_DATA_PURCHASE_ID) || ',';
            else
              aDeleteListStr  := aDeleteListStr || strGOO_MAJOR_REF || ',';
              aDeleteListId   := aDeleteListId || to_char(DelDataEquivPurchase.GCO_COMPL_DATA_PURCHASE_ID) || ',';
            end if;
          end;
      end;

      fetch DeleteEquivPurchase
       into DelDataEquivPurchase;
    end loop;

    -- S'il y a des données complémentaires d'achat de bien qui n'as pas
    -- de fournisseur par défaut, il faut en définir un.
    -- ( Faire ce traitement seulement si on a reussi a effacer les vieiles données sans erreurs)
    if aDeleteListId is null then
      open CUR_GCO_EQUIVALENCE_GOOD;

      fetch CUR_GCO_EQUIVALENCE_GOOD
       into CurGcoEquivalenceGood;

      while CUR_GCO_EQUIVALENCE_GOOD%found loop
        begin
          update GCO_COMPL_DATA_PURCHASE
             set CPU_DEFAULT_SUPPLIER = 1
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_PURCHASE_ID = (select GCO_COMPL_DATA_PURCHASE_ID
                                                 from GCO_COMPL_DATA_PURCHASE
                                                where GCO_GOOD_ID = CurGcoEquivalenceGood.GCO_GOOD_ID
                                                  and PAC_SUPPLIER_PARTNER_ID is not null
                                                  and rownum = 1);
        exception
          when others then
            begin
              -- Recherche la réf du bien pour lequel on n'as pas reussi à mettre un fournisseur par défaut dans la donnée compl d'achat
              select GOO_MAJOR_REFERENCE
                into strGOO_MAJOR_REF
                from GCO_GOOD
               where GCO_GOOD_ID = CurGcoEquivalenceGood.GCO_GOOD_ID;

              if aMakeDefListId is null then
                aMakeDefListStr  := ',' || strGOO_MAJOR_REF || ',';
                aMakeDefListId   := ',' || to_char(CurGcoEquivalenceGood.GCO_GOOD_ID) || ',';
              else
                aMakeDefListStr  := aMakeDefListStr || strGOO_MAJOR_REF || ',';
                aMakeDefListId   := aMakeDefListId || to_char(CurGcoEquivalenceGood.GCO_GOOD_ID) || ',';
              end if;
            end;
        end;

        fetch CUR_GCO_EQUIVALENCE_GOOD
         into CurGcoEquivalenceGood;
      end loop;
    end if;

    -- Création des données complémentaires d'achat au niveau du produit "Générique" selon les produits équivalents
    insert into GCO_COMPL_DATA_PURCHASE
                (GCO_COMPL_DATA_PURCHASE_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_PAC_SUPPLIER_PARTNER_ID
               , CDA_COMPLEMENTARY_REFERENCE
               , CDA_SHORT_DESCRIPTION
               , CDA_LONG_DESCRIPTION
               , CDA_FREE_DESCRIPTION
               , DIC_UNIT_OF_MEASURE_ID
               , CDA_NUMBER_OF_DECIMAL
               , CPU_DEFAULT_SUPPLIER
               , CDA_CONVERSION_FACTOR
               , C_QTY_SUPPLY_RULE
               , C_ECONOMIC_CODE
               , C_TIME_SUPPLY_RULE
               , CPU_SUPPLY_DELAY
               , CPU_AUTOMATIC_GENERATING_PROP
               , A_DATECRE
               , A_IDCRE
                )
      select Init_id_seq.nextval   -- GCO_COMPL_DATA_PURCHASE_ID
           , aGood_ID   -- GCO_GOOD_ID
           , DATA_PUR.GCO_GCO_GOOD_ID   -- GCO_GCO_GOOD_ID
           , DATA_PUR.PAC_DIST_PARTNER_ID   -- PAC_SUPPLIER_PARTNER_ID
           , DATA_PUR.PAC_SUPPLIER_PARTNER_ID   -- PAC_PAC_SUPPLIER_PARTNER_ID
           , GOOD_EQU.GOO_MAJOR_REFERENCE   -- CDA_COMPLEMENTARY_REFERENCE
           , DES_PDT_EQU.DES_SHORT_DESCRIPTION   -- CDA_SHORT_DESCRIPTION
           , PER_MAKER.PER_NAME   -- CDA_LONG_DESCRIPTION
           , DES_PDT_EQU.DES_FREE_DESCRIPTION   -- CDA_FREE_DESCRIPTION
           , GOO.DIC_UNIT_OF_MEASURE_ID   -- DIC_UNIT_OF_MEASURE_ID
           , GOO.GOO_NUMBER_OF_DECIMAL   -- CDA_NUMBER_OF_DECIMAL
           , decode(PUR_DEFAULT.SUP_DEFAULT_EXISTS, 1, 0, decode(rownum, 1, 1, 0) )   -- CPU_DEFAULT_SUPPLIER
           , 1   -- CDA_CONVERSION_FACTOR
           , '1'   -- C_QTY_SUPPLY_RULE
           , '1'   -- C_ECONOMIC_CODE
           , '1'   -- C_TIME_SUPPLY_RULE
           , null   -- CPU_SUPPLY_DELAY
           , 1   -- CPU_AUTOMATIC_GENERATING_PROP
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from dual
           , GCO_GOOD GOO
           , GCO_GOOD GOOD_EQU
           , GCO_DESCRIPTION DES_PDT_EQU
           , PAC_SUPPLIER_PARTNER SUP
           , PAC_ADDRESS ADR
           , PAC_PERSON PER_MAKER
           , (select nvl(max(CPU_DEFAULT_SUPPLIER), 0) SUP_DEFAULT_EXISTS
                from GCO_COMPL_DATA_PURCHASE
               where GCO_GOOD_ID = aGood_ID
                 and CPU_DEFAULT_SUPPLIER = 1) PUR_DEFAULT
           , (select EQU.GCO_GCO_GOOD_ID   -- PRODUIT_EQUIVALENT
                   , PDT.PAC_SUPPLIER_PARTNER_ID   -- FABRICANT
                   , PDI.PAC_DIST_PARTNER_ID   -- FOURNISSEUR
                from GCO_EQUIVALENCE_GOOD EQU
                   , GCO_PRODUCT PDT
                   , PAC_DISTRIBUTOR PDI
               where EQU.GCO_GOOD_ID = aGood_ID
                 and EQU.GCO_GCO_GOOD_ID = PDT.GCO_GOOD_ID
                 and EQU.C_GEG_STATUS = '1'
                 and PDT.PAC_SUPPLIER_PARTNER_ID = PDI.PAC_SUPPLIER_PARTNER_ID
                 and PDI.C_DIST_STATUS = '1'
                 and (   EQU.GEG_BEGIN_DATE is null
                      or EQU.GEG_BEGIN_DATE <= sysdate)
                 and (   EQU.GEG_END_DATE is null
                      or EQU.GEG_END_DATE >= sysdate)
              minus
              select EQU.GCO_GCO_GOOD_ID   -- PRODUIT_EQUIVALENT
                   , PDT.PAC_SUPPLIER_PARTNER_ID   -- FABRICANT
                   , PDI.PAC_DIST_PARTNER_ID   -- FOURNISSEUR
                from GCO_EQUIVALENCE_GOOD EQU
                   , GCO_PRODUCT PDT
                   , PAC_DISTRIBUTOR PDI
                   , (select GCO_GCO_GOOD_ID
                           , PAC_SUPPLIER_PARTNER_ID
                        from GCO_COMPL_DATA_PURCHASE
                       where GCO_GOOD_ID = aGood_ID) PURCHASE
               where EQU.GCO_GOOD_ID = aGood_ID
                 and EQU.GCO_GCO_GOOD_ID = PDT.GCO_GOOD_ID
                 and EQU.C_GEG_STATUS = '1'
                 and PDT.PAC_SUPPLIER_PARTNER_ID = PDI.PAC_SUPPLIER_PARTNER_ID
                 and PDI.C_DIST_STATUS = '1'
                 and PURCHASE.PAC_SUPPLIER_PARTNER_ID = PDI.PAC_DIST_PARTNER_ID
                 and EQU.GCO_GCO_GOOD_ID = PURCHASE.GCO_GCO_GOOD_ID
                 and (   EQU.GEG_BEGIN_DATE is null
                      or EQU.GEG_BEGIN_DATE <= sysdate)
                 and (   EQU.GEG_END_DATE is null
                      or EQU.GEG_END_DATE >= sysdate) ) DATA_PUR
       where GOO.GCO_GOOD_ID = aGood_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID = DATA_PUR.PAC_DIST_PARTNER_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID = ADR.PAC_PERSON_ID
         and ADR.ADD_PRINCIPAL = 1
         and PER_MAKER.PAC_PERSON_ID = DATA_PUR.PAC_SUPPLIER_PARTNER_ID
         and GOOD_EQU.GCO_GOOD_ID = DATA_PUR.GCO_GCO_GOOD_ID
         and GOOD_EQU.GCO_GOOD_ID = DES_PDT_EQU.GCO_GOOD_ID
         and DES_PDT_EQU.PC_LANG_ID = ADR.PC_LANG_ID   -- UTILISER LA LANGUE DU FOURNISSEUR
         and DES_PDT_EQU.C_DESCRIPTION_TYPE = '01';

    -- Effacer les anciennes données complémentaires du produit "générique" qui ne correspondent plus aux produit équivalents
    open DeletePurchase(aGood_ID);

    fetch DeletePurchase
     into DelDataPurchase;

    -- Balayage des données complémentaires à effacer
    while DeletePurchase%found loop
      begin
        -- Vérifie si l'enregistrement n'est pas en cours d'utilisation et
        -- réserve l'enregistrement pour l'effacement de celui-ci
        select     GCO_COMPL_DATA_PURCHASE_ID
              into PurID
              from GCO_COMPL_DATA_PURCHASE
             where GCO_COMPL_DATA_PURCHASE_ID = DelDataPurchase.GCO_COMPL_DATA_PURCHASE_ID
        for update nowait;

        -- Effacer les anciennes données complémentaires qui ne correspondent plus aux produit équivalents
        delete      GCO_COMPL_DATA_PURCHASE
              where GCO_COMPL_DATA_PURCHASE_ID = DelDataPurchase.GCO_COMPL_DATA_PURCHASE_ID;
      exception
        when others then
          begin
            -- Recherche la réf du bien pour lequel on n'as pas reussi à effacer la donnée compl d'achat
            select GOO.GOO_MAJOR_REFERENCE
              into strGOO_MAJOR_REF
              from GCO_GOOD GOO
                 , GCO_COMPL_DATA_PURCHASE PUR
             where GOO.GCO_GOOD_ID = PUR.GCO_GOOD_ID
               and PUR.GCO_COMPL_DATA_PURCHASE_ID = DelDataPurchase.GCO_COMPL_DATA_PURCHASE_ID;

            if aDeleteListId is null then
              aDeleteListStr  := ',' || strGOO_MAJOR_REF || ',';
              aDeleteListId   := ',' || to_char(DelDataPurchase.GCO_COMPL_DATA_PURCHASE_ID) || ',';
            else
              aDeleteListStr  := aDeleteListStr || strGOO_MAJOR_REF || ',';
              aDeleteListId   := aDeleteListId || to_char(DelDataPurchase.GCO_COMPL_DATA_PURCHASE_ID) || ',';
            end if;
          end;
      end;

      fetch DeletePurchase
       into DelDataPurchase;
    end loop;

    -- S'il n'y a pas de fournisseur par défaut dans les données complémentaires du produit "generique", en mettre un au hasard
    begin
      select CPU_DEFAULT_SUPPLIER
        into iDefault
        from GCO_COMPL_DATA_PURCHASE
       where GCO_GOOD_ID = aGood_ID
         and CPU_DEFAULT_SUPPLIER = 1
         and PAC_SUPPLIER_PARTNER_ID is not null
         and rownum = 1;
    exception
      when no_data_found then
        update GCO_COMPL_DATA_PURCHASE
           set CPU_DEFAULT_SUPPLIER = 1
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where GCO_COMPL_DATA_PURCHASE_ID = (select GCO_COMPL_DATA_PURCHASE_ID
                                               from GCO_COMPL_DATA_PURCHASE
                                              where GCO_GOOD_ID = aGood_ID
                                                and PAC_SUPPLIER_PARTNER_ID is not null
                                                and rownum = 1);
    end;
  end UpdateDataPurchase;

  --  Màj des circuits de distribution -> depuis les FABRICANTS
  procedure UpdateDistributionChanels(
    aMaker_ID       in     PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aDeleteListId   out    varchar2
  , aDeleteListStr  out    varchar2
  , aMakeDefListId  out    varchar2
  , aMakeDefListStr out    varchar2
  )
  is
    cursor DeletePurchase(aSupplierID number)
    is
      select PUR.GCO_COMPL_DATA_PURCHASE_ID
        from GCO_COMPL_DATA_PURCHASE PUR
       where PUR.PAC_PAC_SUPPLIER_PARTNER_ID = aSupplierID
         and (    (PUR.PAC_SUPPLIER_PARTNER_ID not in(select PAC_DIST_PARTNER_ID
                                                        from PAC_DISTRIBUTOR
                                                       where PAC_SUPPLIER_PARTNER_ID = aSupplierID
                                                         and C_DIST_STATUS = '1') )
              or (    PUR.GCO_GCO_GOOD_ID is not null
                  and PUR.GCO_GCO_GOOD_ID not in(
                        select EQU.GCO_GCO_GOOD_ID
                          from GCO_EQUIVALENCE_GOOD EQU
                         where EQU.GCO_GOOD_ID = PUR.GCO_GOOD_ID
                           and EQU.C_GEG_STATUS = '1'
                           and (   EQU.GEG_BEGIN_DATE is null
                                or EQU.GEG_BEGIN_DATE <= sysdate)
                           and (   EQU.GEG_END_DATE is null
                                or EQU.GEG_END_DATE >= sysdate) )
                 )
             );

    cursor DeleteEquivPurchase(aSupplierID number)
    is
      select PUR.GCO_COMPL_DATA_PURCHASE_ID
        from GCO_COMPL_DATA_PURCHASE PUR
           , GCO_PRODUCT PDT
       where PDT.PAC_SUPPLIER_PARTNER_ID = aSupplierID
         and PDT.GCO_GOOD_ID = PUR.GCO_GOOD_ID
         and PUR.GCO_GCO_GOOD_ID is null
         and PUR.PAC_PAC_SUPPLIER_PARTNER_ID is null
         and (    (PUR.PAC_SUPPLIER_PARTNER_ID not in(select PAC_DIST_PARTNER_ID
                                                        from PAC_DISTRIBUTOR
                                                       where PAC_SUPPLIER_PARTNER_ID = aSupplierID
                                                         and C_DIST_STATUS = '1') )
              or (PDT.GCO_GOOD_ID not in(
                    select EQU.GCO_GCO_GOOD_ID
                      from GCO_EQUIVALENCE_GOOD EQU
                     where EQU.GCO_GCO_GOOD_ID = PDT.GCO_GOOD_ID
                       and EQU.C_GEG_STATUS = '1'
                       and (   EQU.GEG_BEGIN_DATE is null
                            or EQU.GEG_BEGIN_DATE <= sysdate)
                       and (   EQU.GEG_END_DATE is null
                            or EQU.GEG_END_DATE >= sysdate) )
                 )
             );

    cursor PurchaseNoSupDef
    is
      select   GCO_GOOD_ID
          from GCO_COMPL_DATA_PURCHASE
         where PAC_SUPPLIER_PARTNER_ID is not null
      group by GCO_GOOD_ID
        having max(CPU_DEFAULT_SUPPLIER) = 0;

    DelDataPurchase      DeletePurchase%rowtype;
    DelDataEquivPurchase DeleteEquivPurchase%rowtype;
    SetPurchaseSupDef    PurchaseNoSupDef%rowtype;
    PurID                number;
    strGOO_MAJOR_REF     varchar2(30);
  begin
    -- création des données complémentaires d'achat au niveau des produits fabricants.
    insert into GCO_COMPL_DATA_PURCHASE
                (GCO_COMPL_DATA_PURCHASE_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_PAC_SUPPLIER_PARTNER_ID
               , CDA_COMPLEMENTARY_REFERENCE
               , CDA_SHORT_DESCRIPTION
               , CDA_LONG_DESCRIPTION
               , CDA_FREE_DESCRIPTION
               , DIC_UNIT_OF_MEASURE_ID
               , CDA_NUMBER_OF_DECIMAL
               , CPU_DEFAULT_SUPPLIER
               , CDA_CONVERSION_FACTOR
               , C_QTY_SUPPLY_RULE
               , C_ECONOMIC_CODE
               , C_TIME_SUPPLY_RULE
               , CPU_SUPPLY_DELAY
               , CPU_AUTOMATIC_GENERATING_PROP
               , A_DATECRE
               , A_IDCRE
                )
      select Init_id_seq.nextval   -- GCO_COMPL_DATA_PURCHASE_ID
           , NEWDIST.GCO_GOOD_ID   -- GCO_GOOD_ID
           , null   -- GCO_GCO_GOOD_ID
           , NEWDIST.PAC_SUPPLIER_PARTNER_ID   -- PAC_SUPPLIER_PARTNER_ID
           , null   -- PAC_PAC_SUPPLIER_PARTNER_ID
           , null   -- CDA_COMPLEMENTARY_REFERENCE
           , null   -- CDA_SHORT_DESCRIPTION
           , null   -- CDA_LONG_DESCRIPTION
           , null   -- CDA_FREE_DESCRIPTION
           , GOO.DIC_UNIT_OF_MEASURE_ID   -- DIC_UNIT_OF_MEASURE_ID
           , GOO.GOO_NUMBER_OF_DECIMAL   -- CDA_NUMBER_OF_DECIMAL
           , 0   -- CPU_DEFAULT_SUPPLIER
           , 1   -- CDA_CONVERSION_FACTOR
           , '1'   -- C_QTY_SUPPLY_RULE
           , '1'   -- C_ECONOMIC_CODE
           , '1'   -- C_TIME_SUPPLY_RULE
           , null   -- CPU_SUPPLY_DELAY
           , 1   -- CPU_AUTOMATIC_GENERATING_PROP
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_GOOD GOO
           , (select DIST.PAC_DIST_PARTNER_ID PAC_SUPPLIER_PARTNER_ID
                   , PDT.GCO_GOOD_ID
                from PAC_DISTRIBUTOR DIST
                   , GCO_PRODUCT PDT
               where DIST.PAC_SUPPLIER_PARTNER_ID = aMaker_ID
                 and DIST.C_DIST_STATUS = '1'
                 and PDT.PAC_SUPPLIER_PARTNER_ID = DIST.PAC_SUPPLIER_PARTNER_ID
              minus
              select PUR.PAC_SUPPLIER_PARTNER_ID
                   , PUR.GCO_GOOD_ID
                from GCO_COMPL_DATA_PURCHASE PUR
                   , GCO_PRODUCT PDT
               where PDT.PAC_SUPPLIER_PARTNER_ID = aMaker_ID
                 and PDT.GCO_GOOD_ID = PUR.GCO_GOOD_ID) NewDist
       where GOO.GCO_GOOD_ID = NewDist.GCO_GOOD_ID;

    -- Effacer les anciennes données complémentaires qui ne correspondent plus aux fournisseurs des produits équivalents
    open DeleteEquivPurchase(aMaker_ID);

    fetch DeleteEquivPurchase
     into DelDataEquivPurchase;

    -- Balayage des données complémentaires à effacer
    while DeleteEquivPurchase%found loop
      begin
        -- Vérifie si l'enregistrement n'est pas en cours d'utilisation et
        -- réserve l'enregistrement pour l'effacement de celui-ci
        select     GCO_COMPL_DATA_PURCHASE_ID
              into PurID
              from GCO_COMPL_DATA_PURCHASE
             where GCO_COMPL_DATA_PURCHASE_ID = DelDataEquivPurchase.GCO_COMPL_DATA_PURCHASE_ID
        for update nowait;

        -- Effacer les anciennes données complémentaires qui ne correspondent plus aux produit équivalents
        delete      GCO_COMPL_DATA_PURCHASE
              where GCO_COMPL_DATA_PURCHASE_ID = DelDataEquivPurchase.GCO_COMPL_DATA_PURCHASE_ID;
      exception
        when others then
          begin
            -- Recherche la réf du bien pour lequel on n'as pas reussi à effacer la donnée compl d'achat
            select GOO.GOO_MAJOR_REFERENCE
              into strGOO_MAJOR_REF
              from GCO_GOOD GOO
                 , GCO_COMPL_DATA_PURCHASE PUR
             where GOO.GCO_GOOD_ID = PUR.GCO_GOOD_ID
               and PUR.GCO_COMPL_DATA_PURCHASE_ID = DelDataEquivPurchase.GCO_COMPL_DATA_PURCHASE_ID;

            if aDeleteListId is null then
              aDeleteListStr  := ',' || strGOO_MAJOR_REF || ',';
              aDeleteListId   := ',' || to_char(DelDataEquivPurchase.GCO_COMPL_DATA_PURCHASE_ID) || ',';
            else
              aDeleteListStr  := aDeleteListStr || strGOO_MAJOR_REF || ',';
              aDeleteListId   := aDeleteListId || to_char(DelDataEquivPurchase.GCO_COMPL_DATA_PURCHASE_ID) || ',';
            end if;
          end;
      end;

      fetch DeleteEquivPurchase
       into DelDataEquivPurchase;
    end loop;

    close DeleteEquivPurchase;

    -- Création des données complémentaires d'achat sur le produit générique
    insert into GCO_COMPL_DATA_PURCHASE
                (GCO_COMPL_DATA_PURCHASE_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_PAC_SUPPLIER_PARTNER_ID
               , CDA_COMPLEMENTARY_REFERENCE
               , CDA_SHORT_DESCRIPTION
               , CDA_LONG_DESCRIPTION
               , CDA_FREE_DESCRIPTION
               , DIC_UNIT_OF_MEASURE_ID
               , CDA_NUMBER_OF_DECIMAL
               , CPU_DEFAULT_SUPPLIER
               , CDA_CONVERSION_FACTOR
               , C_QTY_SUPPLY_RULE
               , C_ECONOMIC_CODE
               , C_TIME_SUPPLY_RULE
               , CPU_SUPPLY_DELAY
               , CPU_AUTOMATIC_GENERATING_PROP
               , A_DATECRE
               , A_IDCRE
                )
      select Init_id_seq.nextval   -- GCO_COMPL_DATA_PURCHASE_ID
           , global.GCO_GOOD_ID   -- GCO_GOOD_ID
           , global.GCO_GCO_GOOD_ID   -- GCO_GCO_GOOD_ID
           , global.PAC_SUPPLIER_PARTNER_ID   -- PAC_SUPPLIER_PARTNER_ID
           , aMaker_ID   -- PAC_PAC_SUPPLIER_PARTNER_ID
           , GOOD_EQU.GOO_MAJOR_REFERENCE   -- CDA_COMPLEMENTARY_REFERENCE
           , DES_PDT_EQU.DES_SHORT_DESCRIPTION   -- CDA_SHORT_DESCRIPTION
           , PER_MAKER.PER_NAME   -- CDA_LONG_DESCRIPTION
           , DES_PDT_EQU.DES_FREE_DESCRIPTION   -- CDA_FREE_DESCRIPTION
           , GOO.DIC_UNIT_OF_MEASURE_ID   -- DIC_UNIT_OF_MEASURE_ID
           , GOO.GOO_NUMBER_OF_DECIMAL   -- CDA_NUMBER_OF_DECIMAL
           , 0   -- CPU_DEFAULT_SUPPLIER
           , 1   -- CDA_CONVERSION_FACTOR
           , '1'   -- C_QTY_SUPPLY_RULE
           , '1'   -- C_ECONOMIC_CODE
           , '1'   -- C_TIME_SUPPLY_RULE
           , null   -- CPU_SUPPLY_DELAY
           , 1   -- CPU_AUTOMATIC_GENERATING_PROP
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_GOOD GOO
           , GCO_DESCRIPTION DES_PDT_EQU
           , GCO_GOOD GOOD_EQU
           , PAC_SUPPLIER_PARTNER SUP
           , PAC_ADDRESS ADR
           , PAC_PERSON PER_MAKER
           , (select PDT.GCO_GOOD_ID GCO_GCO_GOOD_ID   -- Produit Fabricant
                   , EQU.GCO_GOOD_ID GCO_GOOD_ID   -- Produit
                   , PDI.PAC_DIST_PARTNER_ID PAC_SUPPLIER_PARTNER_ID   -- Fournisseur
                from GCO_PRODUCT PDT
                   , GCO_EQUIVALENCE_GOOD EQU
                   , PAC_DISTRIBUTOR PDI
               where PDT.PAC_SUPPLIER_PARTNER_ID = aMaker_ID
                 and EQU.GCO_GCO_GOOD_ID = PDT.GCO_GOOD_ID
                 and EQU.C_GEG_STATUS = '1'
                 and PDI.PAC_SUPPLIER_PARTNER_ID = PDT.PAC_SUPPLIER_PARTNER_ID
                 and PDI.C_DIST_STATUS = '1'
                 and (   EQU.GEG_BEGIN_DATE is null
                      or EQU.GEG_BEGIN_DATE <= sysdate)
                 and (   EQU.GEG_END_DATE is null
                      or EQU.GEG_END_DATE >= sysdate)
              minus
              select PUR.GCO_GCO_GOOD_ID GCO_GCO_GOOD_ID   -- Produit Fabricant
                   , PUR.GCO_GOOD_ID GCO_GOOD_ID   -- Produit
                   , PUR.PAC_SUPPLIER_PARTNER_ID PAC_SUPPLIER_PARTNER_ID   -- Fournisseur
                from GCO_COMPL_DATA_PURCHASE PUR
                   , GCO_PRODUCT PDT
                   , GCO_EQUIVALENCE_GOOD EQU
                   , PAC_DISTRIBUTOR PDI
               where PDT.PAC_SUPPLIER_PARTNER_ID = aMaker_ID
                 and EQU.GCO_GCO_GOOD_ID = PDT.GCO_GOOD_ID
                 and EQU.C_GEG_STATUS = '1'
                 and PDI.PAC_SUPPLIER_PARTNER_ID = PDT.PAC_SUPPLIER_PARTNER_ID
                 and PDI.C_DIST_STATUS = '1'
                 and PUR.GCO_GCO_GOOD_ID = PDT.GCO_GOOD_ID
                 and PUR.GCO_GOOD_ID = EQU.GCO_GOOD_ID
                 and PUR.PAC_SUPPLIER_PARTNER_ID = PDI.PAC_DIST_PARTNER_ID
                 and (   EQU.GEG_BEGIN_DATE is null
                      or EQU.GEG_BEGIN_DATE <= sysdate)
                 and (   EQU.GEG_END_DATE is null
                      or EQU.GEG_END_DATE >= sysdate) ) global
       where GOO.GCO_GOOD_ID = global.GCO_GOOD_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID = global.PAC_SUPPLIER_PARTNER_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID = ADR.PAC_PERSON_ID
         and ADR.ADD_PRINCIPAL = 1
         and PER_MAKER.PAC_PERSON_ID = aMaker_ID
         and GOOD_EQU.GCO_GOOD_ID = global.GCO_GCO_GOOD_ID
         and GOOD_EQU.GCO_GOOD_ID = DES_PDT_EQU.GCO_GOOD_ID
         and DES_PDT_EQU.PC_LANG_ID = ADR.PC_LANG_ID   -- UTILISER LA LANGUE DU FOURNISSEUR
         and DES_PDT_EQU.C_DESCRIPTION_TYPE = '01';

    -- Effacer les anciennes données complémentaires qui ne correspondent plus aux produit équivalents
    open DeletePurchase(aMaker_ID);

    fetch DeletePurchase
     into DelDataPurchase;

    -- Balayage des données complémentaires à effacer
    while DeletePurchase%found loop
      begin
        -- Vérifie si l'enregistrement n'est pas en cours d'utilisation et
        -- réserve l'enregistrement pour l'effacement de celui-ci
        select     GCO_COMPL_DATA_PURCHASE_ID
              into PurID
              from GCO_COMPL_DATA_PURCHASE
             where GCO_COMPL_DATA_PURCHASE_ID = DelDataPurchase.GCO_COMPL_DATA_PURCHASE_ID
        for update nowait;

        -- Effacer les anciennes données complémentaires qui ne correspondent plus aux produit équivalents
        delete      GCO_COMPL_DATA_PURCHASE
              where GCO_COMPL_DATA_PURCHASE_ID = DelDataPurchase.GCO_COMPL_DATA_PURCHASE_ID;
      exception
        when others then
          begin
            -- Recherche la réf du bien pour lequel on n'as pas reussi à effacer la donnée compl d'achat
            select GOO.GOO_MAJOR_REFERENCE
              into strGOO_MAJOR_REF
              from GCO_GOOD GOO
                 , GCO_COMPL_DATA_PURCHASE PUR
             where GOO.GCO_GOOD_ID = PUR.GCO_GOOD_ID
               and PUR.GCO_COMPL_DATA_PURCHASE_ID = DelDataPurchase.GCO_COMPL_DATA_PURCHASE_ID;

            if aDeleteListId is null then
              aDeleteListStr  := ',' || strGOO_MAJOR_REF || ',';
              aDeleteListId   := ',' || to_char(DelDataPurchase.GCO_COMPL_DATA_PURCHASE_ID) || ',';
            else
              aDeleteListStr  := aDeleteListStr || strGOO_MAJOR_REF || ',';
              aDeleteListId   := aDeleteListId || to_char(DelDataPurchase.GCO_COMPL_DATA_PURCHASE_ID) || ',';
            end if;
          end;
      end;

      fetch DeletePurchase
       into DelDataPurchase;
    end loop;

    close DeletePurchase;

    -- S'il y a des données complémentaires d'achat de bien qui n'as pas
    -- de fournisseur par défaut, il faut en définir un.
    -- ( Faire ce traitement seulement si on a reussi a effacer les vieiles données sans erreurs)
    if aDeleteListId is null then
      open PurchaseNoSupDef;

      fetch PurchaseNoSupDef
       into SetPurchaseSupDef;

      while PurchaseNoSupDef%found loop
        begin
          update GCO_COMPL_DATA_PURCHASE
             set CPU_DEFAULT_SUPPLIER = 1
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_PURCHASE_ID = (select GCO_COMPL_DATA_PURCHASE_ID
                                                 from GCO_COMPL_DATA_PURCHASE
                                                where GCO_GOOD_ID = SetPurchaseSupDef.GCO_GOOD_ID
                                                  and PAC_SUPPLIER_PARTNER_ID is not null
                                                  and rownum = 1);
        exception
          when others then
            begin
              -- Recherche la réf du bien pour lequel on n'as pas reussi à mettre un fournisseur par défaut dans la donnée compl d'achat
              select GOO_MAJOR_REFERENCE
                into strGOO_MAJOR_REF
                from GCO_GOOD
               where GCO_GOOD_ID = SetPurchaseSupDef.GCO_GOOD_ID;

              if aMakeDefListId is null then
                aMakeDefListStr  := ',' || strGOO_MAJOR_REF || ',';
                aMakeDefListId   := ',' || to_char(SetPurchaseSupDef.GCO_GOOD_ID) || ',';
              else
                aMakeDefListStr  := aMakeDefListStr || strGOO_MAJOR_REF || ',';
                aMakeDefListId   := aMakeDefListId || to_char(SetPurchaseSupDef.GCO_GOOD_ID) || ',';
              end if;
            end;
        end;

        fetch PurchaseNoSupDef
         into SetPurchaseSupDef;
      end loop;
    end if;
  end UpdateDistributionChanels;

  -- Màj des circuits de distribution  -> depuis les FABRICANTS/ menu outils
  procedure UpdateAllDistributionChanels(aDeleteListId out varchar2, aDeleteListStr out varchar2, aMakeDefListId out varchar2, aMakeDefListStr out varchar2)
  is
    cursor CUR_ALL_MAKERS
    is
      select PAC_SUPPLIER_PARTNER_ID
        from PAC_SUPPLIER_PARTNER
       where CRE_MANUFACTURER = 1;

    CurAllMarkers   CUR_ALL_MAKERS%rowtype;

    subtype Longvarchar is varchar2(32000);

    vDeleteListId   Longvarchar;
    vDeleteListStr  Longvarchar;
    vMakeDefListId  Longvarchar;
    vMakeDefListStr Longvarchar;
  begin
    for CurAllMarkers in CUR_ALL_MAKERS loop
      UpdateDistributionChanels(CurAllMarkers.PAC_SUPPLIER_PARTNER_ID, aDeleteListId, aDeleteListStr, aMakeDefListId, aMakeDefListStr);

      if vDeleteListId is null then
        vDeleteListStr  := aDeleteListStr;
        vDeleteListId   := aDeleteListStr;
      else
        vDeleteListStr  := vDeleteListStr || substr(aDeleteListStr, 2, length(aDeleteListStr) );
        vDeleteListId   := vDeleteListId || substr(aDeleteListId, 2, length(aDeleteListId) );
      end if;

      if vMakeDefListId is null then
        vMakeDefListStr  := aMakeDefListStr;
        vMakeDefListId   := aMakeDefListStr;
      else
        vMakeDefListStr  := vMakeDefListStr || substr(aMakeDefListStr, 2, length(aMakeDefListStr) );
        vMakeDefListId   := vMakeDefListId || substr(aMakeDefListId, 2, length(aMakeDefListId) );
      end if;
    end loop;

    aDeleteListId    := vDeleteListId;
    aDeleteListStr   := vDeleteListStr;
    aMakeDefListId   := vMakeDefListId;
    aMakeDefListStr  := vMakeDefListStr;
  end UpdateAllDistributionChanels;

  -- Activer un produit avec des blocs d'équivalence
  procedure ActivateEquProduct(aGood_ID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor BlocEquivalence(GoodID in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select GCO_GOOD_ID
           , GCO_GCO_GOOD_ID
           , GCO_EQUIVALENCE_GOOD_ID
        from GCO_EQUIVALENCE_GOOD
       where GCO_GCO_GOOD_ID = GoodID;

    BlocEquivalence_tuple BlocEquivalence%rowtype;
    iDefault              integer;
  begin
    open BlocEquivalence(aGood_ID);

    fetch BlocEquivalence
     into BlocEquivalence_tuple;

    while BlocEquivalence%found loop
      -- Màj du statut du bloc d'équivalence
      update GCO_EQUIVALENCE_GOOD
         set C_GEG_STATUS = '1'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where GCO_EQUIVALENCE_GOOD_ID = BlocEquivalence_tuple.GCO_EQUIVALENCE_GOOD_ID;

      -- création des données complémentaires d'achat au niveau du produit equivalent si produit equivalent.
      insert into GCO_COMPL_DATA_PURCHASE
                  (GCO_COMPL_DATA_PURCHASE_ID
                 , GCO_GOOD_ID
                 , GCO_GCO_GOOD_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , PAC_PAC_SUPPLIER_PARTNER_ID
                 , CDA_COMPLEMENTARY_REFERENCE
                 , CDA_SHORT_DESCRIPTION
                 , CDA_LONG_DESCRIPTION
                 , CDA_FREE_DESCRIPTION
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDA_NUMBER_OF_DECIMAL
                 , CPU_DEFAULT_SUPPLIER
                 , CDA_CONVERSION_FACTOR
                 , C_QTY_SUPPLY_RULE
                 , C_ECONOMIC_CODE
                 , C_TIME_SUPPLY_RULE
                 , CPU_SUPPLY_DELAY
                 , CPU_AUTOMATIC_GENERATING_PROP
                 , A_DATECRE
                 , A_IDCRE
                  )
        select Init_id_seq.nextval   -- GCO_COMPL_DATA_PURCHASE_ID
             , NewDca.GCO_GCO_GOOD_ID   -- GCO_GOOD_ID
             , null   -- GCO_GCO_GOOD_ID
             , NewDca.PAC_SUPPLIER_PARTNER_ID   -- PAC_SUPPLIER_PARTNER_ID
             , null   -- PAC_PAC_SUPPLIER_PARTNER_ID
             , null   -- CDA_COMPLEMENTARY_REFERENCE
             , null   -- CDA_SHORT_DESCRIPTION
             , null   -- CDA_LONG_DESCRIPTION
             , null   -- CDA_FREE_DESCRIPTION
             , GOO.DIC_UNIT_OF_MEASURE_ID   -- DIC_UNIT_OF_MEASURE_ID
             , GOO.GOO_NUMBER_OF_DECIMAL   -- CDA_NUMBER_OF_DECIMAL
             , 0   -- CPU_DEFAULT_SUPPLIER
             , 1   -- CDA_CONVERSION_FACTOR
             , '1'   -- C_QTY_SUPPLY_RULE
             , '1'   -- C_ECONOMIC_CODE
             , '1'   -- C_TIME_SUPPLY_RULE
             , null   -- CPU_SUPPLY_DELAY
             , 1   -- CPU_AUTOMATIC_GENERATING_PROP
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from GCO_GOOD GOO
             , (select EQU.GCO_GCO_GOOD_ID
                     , PDI.PAC_DIST_PARTNER_ID PAC_SUPPLIER_PARTNER_ID
                  from GCO_EQUIVALENCE_GOOD EQU
                     , GCO_PRODUCT PDT
                     , PAC_DISTRIBUTOR PDI
                 where EQU.GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GOOD_ID
                   and EQU.GCO_GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GCO_GOOD_ID
                   and EQU.GCO_GCO_GOOD_ID = PDT.GCO_GOOD_ID
                   and EQU.C_GEG_STATUS = '1'
                   and (   EQU.GEG_BEGIN_DATE is null
                        or EQU.GEG_BEGIN_DATE <= sysdate)
                   and (   EQU.GEG_END_DATE is null
                        or EQU.GEG_END_DATE >= sysdate)
                   and PDT.PAC_SUPPLIER_PARTNER_ID = PDI.PAC_SUPPLIER_PARTNER_ID
                   and PDI.C_DIST_STATUS = '1'
                minus
                select EQU.GCO_GCO_GOOD_ID
                     , PUR.PAC_SUPPLIER_PARTNER_ID
                  from GCO_EQUIVALENCE_GOOD EQU
                     , GCO_COMPL_DATA_PURCHASE PUR
                 where EQU.GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GOOD_ID
                   and EQU.GCO_GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GCO_GOOD_ID
                   and EQU.GCO_GCO_GOOD_ID = PUR.GCO_GOOD_ID) NewDca
         where GOO.GCO_GOOD_ID = NewDca.GCO_GCO_GOOD_ID;

      -- Fournisseur par défaut si inexistant
      begin
        select CPU_DEFAULT_SUPPLIER
          into iDefault
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GCO_GOOD_ID
           and CPU_DEFAULT_SUPPLIER = 1
           and PAC_SUPPLIER_PARTNER_ID is not null
           and rownum = 1;
      exception
        when no_data_found then
          update GCO_COMPL_DATA_PURCHASE
             set CPU_DEFAULT_SUPPLIER = 1
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_PURCHASE_ID = (select GCO_COMPL_DATA_PURCHASE_ID
                                                 from GCO_COMPL_DATA_PURCHASE
                                                where GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GCO_GOOD_ID
                                                  and PAC_SUPPLIER_PARTNER_ID is not null
                                                  and rownum = 1);
      end;

      -- Création des données complémentaires d'achat au niveau du produit générique du produit equivalent
      insert into GCO_COMPL_DATA_PURCHASE
                  (GCO_COMPL_DATA_PURCHASE_ID
                 , GCO_GOOD_ID
                 , GCO_GCO_GOOD_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , PAC_PAC_SUPPLIER_PARTNER_ID
                 , CDA_COMPLEMENTARY_REFERENCE
                 , CDA_SHORT_DESCRIPTION
                 , CDA_LONG_DESCRIPTION
                 , CDA_FREE_DESCRIPTION
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDA_NUMBER_OF_DECIMAL
                 , CPU_DEFAULT_SUPPLIER
                 , CDA_CONVERSION_FACTOR
                 , C_QTY_SUPPLY_RULE
                 , C_ECONOMIC_CODE
                 , C_TIME_SUPPLY_RULE
                 , CPU_SUPPLY_DELAY
                 , CPU_AUTOMATIC_GENERATING_PROP
                 , A_DATECRE
                 , A_IDCRE
                  )
        select Init_id_seq.nextval   -- GCO_COMPL_DATA_PURCHASE_ID
             , BlocEquivalence_tuple.GCO_GOOD_ID   -- GCO_GOOD_ID
             , BlocEquivalence_tuple.GCO_GCO_GOOD_ID   -- GCO_GCO_GOOD_ID
             , DATA_PUR.PAC_DIST_PARTNER_ID   -- PAC_SUPPLIER_PARTNER_ID
             , DATA_PUR.PAC_SUPPLIER_PARTNER_ID   -- PAC_PAC_SUPPLIER_PARTNER_ID
             , GOOD_EQU.GOO_MAJOR_REFERENCE   -- CDA_COMPLEMENTARY_REFERENCE
             , DES_PDT_EQU.DES_SHORT_DESCRIPTION   -- CDA_SHORT_DESCRIPTION
             , PER_MAKER.PER_NAME   -- CDA_LONG_DESCRIPTION
             , DES_PDT_EQU.DES_FREE_DESCRIPTION   -- CDA_FREE_DESCRIPTION
             , GOO.DIC_UNIT_OF_MEASURE_ID   -- DIC_UNIT_OF_MEASURE_ID
             , GOO.GOO_NUMBER_OF_DECIMAL   -- CDA_NUMBER_OF_DECIMAL
             , 0   -- CPU_DEFAULT_SUPPLIER
             , 1   -- CDA_CONVERSION_FACTOR
             , '1'   -- C_QTY_SUPPLY_RULE
             , '1'   -- C_ECONOMIC_CODE
             , '1'   -- C_TIME_SUPPLY_RULE
             , null   -- CPU_SUPPLY_DELAY
             , 1   -- CPU_AUTOMATIC_GENERATING_PROP
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from dual
             , GCO_GOOD GOO
             , GCO_GOOD GOOD_EQU
             , GCO_DESCRIPTION DES_PDT_EQU
             , PAC_SUPPLIER_PARTNER SUP
             , PAC_ADDRESS ADR
             , PAC_PERSON PER_MAKER
             , (select PDT_EQU.GCO_GOOD_ID GCO_GCO_GOOD_ID   -- PRODUIT_EQUIVALENT
                     , PDT_EQU.PAC_SUPPLIER_PARTNER_ID   -- FABRICANT
                     , PDI.PAC_DIST_PARTNER_ID   -- FOURNISSEUR
                  from GCO_PRODUCT PDT_EQU
                     , PAC_DISTRIBUTOR PDI
                 where PDT_EQU.GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GCO_GOOD_ID
                   and PDT_EQU.PAC_SUPPLIER_PARTNER_ID = PDI.PAC_SUPPLIER_PARTNER_ID
                   and PDI.C_DIST_STATUS = '1'
                minus
                select CPU.GCO_GCO_GOOD_ID   -- PRODUIT_EQUIVALENT
                     , CPU.PAC_SUPPLIER_PARTNER_ID   -- FABRICANT
                     , CPU.PAC_SUPPLIER_PARTNER_ID PAC_DIST_PARTNER_ID   -- FOURNISSEUR
                  from GCO_COMPL_DATA_PURCHASE CPU
                 where CPU.GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GOOD_ID
                   and CPU.GCO_GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GCO_GOOD_ID) DATA_PUR
         where GOO.GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GOOD_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = DATA_PUR.PAC_DIST_PARTNER_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = ADR.PAC_PERSON_ID
           and ADR.ADD_PRINCIPAL = 1
           and PER_MAKER.PAC_PERSON_ID = DATA_PUR.PAC_SUPPLIER_PARTNER_ID
           and GOOD_EQU.GCO_GOOD_ID = DATA_PUR.GCO_GCO_GOOD_ID
           and GOOD_EQU.GCO_GOOD_ID = DES_PDT_EQU.GCO_GOOD_ID
           and DES_PDT_EQU.PC_LANG_ID = ADR.PC_LANG_ID   -- UTILISER LA LANGUE DU FOURNISSEUR
           and DES_PDT_EQU.C_DESCRIPTION_TYPE = '01';

      -- Fournisseur par défaut si inexistant
      begin
        select CPU_DEFAULT_SUPPLIER
          into iDefault
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GOOD_ID
           and CPU_DEFAULT_SUPPLIER = 1
           and PAC_SUPPLIER_PARTNER_ID is not null
           and rownum = 1;
      exception
        when no_data_found then
          update GCO_COMPL_DATA_PURCHASE
             set CPU_DEFAULT_SUPPLIER = 1
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_PURCHASE_ID = (select GCO_COMPL_DATA_PURCHASE_ID
                                                 from GCO_COMPL_DATA_PURCHASE
                                                where GCO_GOOD_ID = BlocEquivalence_tuple.GCO_GOOD_ID
                                                  and PAC_SUPPLIER_PARTNER_ID is not null
                                                  and rownum = 1);
      end;

      fetch BlocEquivalence
       into BlocEquivalence_tuple;
    end loop;
  end ActivateEquProduct;
end GCO_BLOC_EQUIVALENCE;
