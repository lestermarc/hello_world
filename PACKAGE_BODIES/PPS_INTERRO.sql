--------------------------------------------------------
--  DDL for Package Body PPS_INTERRO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_INTERRO" 
is
  /**
  * procedure SearchAllGoodOfNomenclature
  * Description : Procedure de contrôle de la nomenclature. Cette procedure est appelée soit pour
  *               effectuer une interrogation, soit pour rechercher les cas d'emplois.
  *
  * @created
  * @lastUpdate ECA
  * @public
  * @param   aPPS_NOMENCLATURE_ID      : Id de la nomenclature à traiter
  * @param   aIndex                    : Niveau de récursivité
  * @param   aPPS_NOM_INTERRO_USER_ID  : Id de l'utilisateur Gestion du multi-user dans table PPS_NOM_INTERRO
  * @param   aTypeNom                  : Type de nomenclature à tester
  * @param   aGCO_GOOD_ID              : ID du bien
  * @param   aTypeInterr               : Type d'inérogation 0=Intérrogation nomenclature /1=cas d'emploi
  * @param   aOnglet                   : Onglet , 3=Achat, 4=Fab
  * @param   aTypeSumStock             : Méthode de calcul des stocks 0=Tous, 1=dans aStocksId, 2=Public, 3=Privé
  * @param   aStocksId                 : Id des stocks à prendre en compte
  * @param   iInclSubcontractPPdt      : Prise en compte des produits sous-traités achetés
  * @param   iInclPdtSuppliedBySubctor : Inclure/exlcure les produits fournis par les sous-traitants
  * @param   iInclTxtPosition          : Inclure/exlcure les positions texte
  */
  procedure SearchAllGoodOfNomenclature(
    aPPS_NOMENCLATURE_ID      in number
  , aIndex                    in number
  , aPPS_NOM_INTERRO_USER_ID  in number
  , aTypeNom                  in varchar2
  , aGCO_GOOD_ID              in number
  , aTypeInterr               in number
  , aOnglet                   in number
  , aTypeSumStock             in number
  , aStocksId                 in varchar2
  , iInclSubcontractPPdt      in integer default 1
  , iInclPdtSuppliedBySubctor in integer default 1
  , iInclTxtPosition          in integer default 1
  )
  is
    Nomenclature_Id           PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    NewSeq                    number;
    SumCursorAvailQty         number;
    SumCursorAssignQty        number;
    SumCursorProvIn           number;
    SumCursorProvOut          number;
    SumCursorAppro            number;
    SumCursorBesoin           number;

    -- Curseur AllGood_Nom_Interr
    -- Ce curseur contient tous les élement d'une nomenclature et leurs biens / Utilisé pour l'intérogation de la nomenclature
    -- Modèle :
    -- PPS_NOMENCLATURE -> PPS_NOM_BOND -> GCO_GOOD         (rem om : pas besoin de la table PPS_NOMENCLATURE
    --Nouveau modèle PPS_NOM_BOND -> GCO_GOOD
    cursor AllGood_Nom_Interr(Nomenclature_id number)
    is
      select   PPS_NOM_BOND1.GCO_GOOD_ID
             , PPS_NOM_BOND1.COM_SEQ
             , PPS_NOM_BOND1.C_TYPE_COM
             , PPS_NOM_BOND1.C_KIND_COM
             , PPS_NOM_BOND1.STM_STOCK_ID
             , PPS_NOM_BOND1.STM_LOCATION_ID
             , PPS_NOM_BOND1.C_DISCHARGE_COM
             , PPS_NOM_BOND1.C_REMPLACEMENT_NOM
             , PPS_NOM_BOND1.COM_UTIL_COEFF
             , PPS_NOM_BOND1.COM_PDIR_COEFF
             , PPS_NOM_BOND1.COM_REC_PCENT
             , PPS_NOM_BOND1.COM_POS
             , PPS_NOM_BOND1.COM_REMPLACEMENT
             , PPS_NOM_BOND1.COM_BEG_VALID
             , PPS_NOM_BOND1.COM_END_VALID
             , PPS_NOM_BOND1.COM_SUBSTITUT
             , PPS_NOM_BOND1.COM_INTERVAL
             , PPS_NOM_BOND1.COM_TEXT
             , PPS_NOM_BOND1.COM_RES_TEXT
             , PPS_NOM_BOND1.COM_RES_NUM
             , PPS_NOM_BOND1.COM_VAL
             , PPS_NOM_BOND1.FAL_SCHEDULE_STEP_ID
             , GCO_GOOD1.GOO_MAJOR_REFERENCE
             , GCO_GOOD1.DIC_UNIT_OF_MEASURE_ID
             , GCO_GOOD1.GOO_SECONDARY_REFERENCE
          from PPS_NOM_BOND PPS_NOM_BOND1
             , GCO_GOOD GCO_GOOD1
             , GCO_PRODUCT PDT
         where PPS_NOM_BOND1.PPS_NOMENCLATURE_ID = Nomenclature_Id
           and PPS_NOM_BOND1.GCO_GOOD_ID = GCO_GOOD1.GCO_GOOD_ID(+)
           and GCO_GOOD1.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
           and (   iInclPdtSuppliedBySubctor = 1
                or (    iInclPdtSuppliedBySubctor = 0
                    and PPS_NOM_BOND1.C_KIND_COM <> '4') )
           and (   iInclTxtPosition = 1
                or (    iInclTxtPosition = 0
                    and PPS_NOM_BOND1.C_KIND_COM <> '5') )
           and (   iInclSubcontractPPdt = 1
                or PDT.GCO_GOOD_ID is null
                or (    iInclSubcontractPPdt = 0
                    and PDT.C_SUPPLY_MODE <> '4') )
      order by PPS_NOM_BOND1.COM_SEQ;

    AllGood_Nom_tuple_Interr  AllGood_Nom_Interr%rowtype;

    -- Curseur AllGood_Nom_CasEmpl
    -- Ce curseur contient tous les cas d'emplois d'un bien / Utilisé pour les cas d'emploi du bien
    -- Modèle :
    -- GCO_GOOD -> PPS_NOM_BOND -> PPS_NOMENCLATURE
    cursor AllGood_Nom_CasEmpl(Good_Id in number)
    is
      select   PPS_NOMENCLATURE1.GCO_GOOD_ID
             , PPS_NOMENCLATURE1.C_TYPE_NOM
             , PPS_NOMENCLATURE1.NOM_VERSION
             , PPS_NOMENCLATURE1.NOM_DEFAULT
             , PPS_NOM_BOND1.COM_SEQ
             , PPS_NOM_BOND1.C_TYPE_COM
             , PPS_NOM_BOND1.C_KIND_COM
             , PPS_NOM_BOND1.STM_STOCK_ID
             , PPS_NOM_BOND1.STM_LOCATION_ID
             , PPS_NOM_BOND1.C_DISCHARGE_COM
             , PPS_NOM_BOND1.C_REMPLACEMENT_NOM
             , PPS_NOM_BOND1.COM_UTIL_COEFF
             , PPS_NOM_BOND1.COM_PDIR_COEFF
             , PPS_NOM_BOND1.COM_REC_PCENT
             , PPS_NOM_BOND1.COM_POS
             , PPS_NOM_BOND1.COM_REMPLACEMENT
             , PPS_NOM_BOND1.COM_BEG_VALID
             , PPS_NOM_BOND1.COM_END_VALID
             , PPS_NOM_BOND1.COM_SUBSTITUT
             , PPS_NOM_BOND1.COM_INTERVAL
             , PPS_NOM_BOND1.COM_TEXT
             , PPS_NOM_BOND1.COM_RES_TEXT
             , PPS_NOM_BOND1.COM_RES_NUM
             , PPS_NOM_BOND1.COM_VAL
             , PPS_NOM_BOND1.FAL_SCHEDULE_STEP_ID
             , GCO_GOOD1.GOO_MAJOR_REFERENCE
             , GCO_GOOD1.DIC_UNIT_OF_MEASURE_ID
             , GCO_GOOD1.GOO_SECONDARY_REFERENCE
          from PPS_NOMENCLATURE PPS_NOMENCLATURE1
             , PPS_NOM_BOND PPS_NOM_BOND1
             , GCO_GOOD GCO_GOOD1
         where PPS_NOM_BOND1.GCO_GOOD_ID = Good_Id
           and PPS_NOMENCLATURE1.PPS_NOMENCLATURE_ID = PPS_NOM_BOND1.PPS_NOMENCLATURE_ID
           and GCO_GOOD1.GCO_GOOD_ID = PPS_NOMENCLATURE1.GCO_GOOD_ID
      order by PPS_NOM_BOND1.COM_SEQ;

    AllGood_Nom_tuple_CasEmpl AllGood_Nom_CasEmpl%rowtype;
  begin
    if aTypeInterr = 0 then   -- Si on veut effectuer l'interrogation de la nomenclature
      --Ouvre le curseur et le tuple
      open AllGood_Nom_Interr(aPPS_NOMENCLATURE_ID);

      fetch AllGood_Nom_Interr
       into AllGood_Nom_tuple_Interr;

      --Tant qu'il y a des élement de nomenclature (avec ou sans bien)
      while AllGood_Nom_Interr%found loop
        GetStocks(AllGood_Nom_tuple_Interr.GCO_GOOD_ID, aTypeSumStock, aStocksId, SumCursorAvailQty, SumCursorAssignQty, SumcursorProvIn, SumCursorProvOut);
        GetNetwork(AllGood_Nom_tuple_Interr.GCO_GOOD_ID, aTypeSumStock, aStocksId, SumCursorAppro, SumCursorBesoin);

        insert into PPS_NOM_INTERRO
                    (PPS_NOM_INTERRO_ID
                   , PPS_NOM_INTERRO_USER_ID
                   , PPS_NOMENCLATURE_ID
                   , GCO_GOOD_ID
                   , INT_INDEX
                   , INT_TYPE
                   , COM_SEQ
                   , GOO_MAJOR_REFERENCE
                   , GOO_SECONDARY_REFERENCE
                   , C_TYPE_COM
                   , C_KIND_COM
                   , DES_SHORT_DESCRIPTION
                   , DIC_UNIT_OF_MEASURE_ID
                   , COM_UTIL_COEFF
                   , COM_PDIR_COEFF
                   , COM_REC_PCENT
                   , COM_POS
                   , SCS_STEP_NUMBER
                   , STO_DESCRIPTION
                   , LOC_DESCRIPTION
                   , COM_VAL
                   , C_DISCHARGE_COM
                   , C_REMPLACEMENT_NOM
                   , COM_REMPLACEMENT
                   , COM_BEG_VALID
                   , COM_END_VALID
                   , COM_SUBSTITUT
                   , COM_INTERVAL
                   , COM_TEXT
                   , COM_RES_TEXT
                   , COM_RES_NUM
                   , SPO_AVAILABLE_QUANTITY
                   , SPO_ASSIGN_QUANTITY
                   , SPO_PROVISORY_INPUT
                   , SPO_PROVISORY_OUTPUT
                   , FAN_BALANCE_QTY_SUPPLY
                   , FAN_BALANCE_QTY_NEED
                    )
             values (Init_Id_Seq.nextval
                   , aPPS_NOM_INTERRO_USER_ID
                   , aPPS_NOMENCLATURE_ID
                   , AllGood_Nom_tuple_Interr.GCO_GOOD_ID
                   , aIndex
                   , 1
                   , AllGood_Nom_tuple_Interr.COM_SEQ
                   , AllGood_Nom_tuple_Interr.GOO_MAJOR_REFERENCE
                   , AllGood_Nom_tuple_Interr.GOO_SECONDARY_REFERENCE
                   , AllGood_Nom_tuple_Interr.C_TYPE_COM
                   , AllGood_Nom_tuple_Interr.C_KIND_COM
                   , PPS_INTERRO.SearchShortDesc(AllGood_Nom_tuple_Interr.GCO_GOOD_ID)
                   , AllGood_Nom_tuple_Interr.DIC_UNIT_OF_MEASURE_ID
                   , AllGood_Nom_tuple_Interr.COM_UTIL_COEFF
                   , AllGood_Nom_tuple_Interr.COM_PDIR_COEFF
                   , AllGood_Nom_tuple_Interr.COM_REC_PCENT
                   , AllGood_Nom_tuple_Interr.COM_POS
                   , PPS_INTERRO.SearchStepLink(AllGood_Nom_tuple_Interr.FAL_SCHEDULE_STEP_ID)
                   , PPS_INTERRO.SearchStock(AllGood_Nom_tuple_Interr.STM_STOCK_ID)
                   , PPS_INTERRO.SearchLocation(AllGood_Nom_tuple_Interr.STM_LOCATION_ID)
                   , AllGood_Nom_tuple_Interr.COM_VAL
                   , AllGood_Nom_tuple_Interr.C_DISCHARGE_COM
                   , AllGood_Nom_tuple_Interr.C_REMPLACEMENT_NOM
                   , AllGood_Nom_tuple_Interr.COM_REMPLACEMENT
                   , AllGood_Nom_tuple_Interr.COM_BEG_VALID
                   , AllGood_Nom_tuple_Interr.COM_END_VALID
                   , AllGood_Nom_tuple_Interr.COM_SUBSTITUT
                   , AllGood_Nom_tuple_Interr.COM_INTERVAL
                   , AllGood_Nom_tuple_Interr.COM_TEXT
                   , AllGood_Nom_tuple_Interr.COM_RES_TEXT
                   , AllGood_Nom_tuple_Interr.COM_RES_NUM
                   , SumCursorAvailQty
                   , SumCursorAssignQty
                   , SumCursorProvIn
                   , SumCursorProvOut
                   , SumCursorAppro
                   , SumCursorBesoin
                    );

        if aOnglet = 3 then
          InsertGoodForAchat(aPPS_NOM_INTERRO_USER_ID, aPPS_NOMENCLATURE_ID, AllGood_Nom_tuple_Interr.GCO_GOOD_ID, aIndex, 1);
        end if;

        if aOnglet = 4 then
          InsertGoodForFab(aPPS_NOM_INTERRO_USER_ID, aPPS_NOMENCLATURE_ID, AllGood_Nom_tuple_Interr.GCO_GOOD_ID, aIndex, 1);
        end if;

        SearchAllGoodOfNomenclature(PPS_INTERRO.SearchNomenclature(AllGood_Nom_tuple_Interr.GCO_GOOD_ID, aTypeNom)
                                  , aIndex + 1
                                  , aPPS_NOM_INTERRO_USER_ID
                                  , aTypeNom
                                  , 0
                                  , aTypeInterr
                                  , aOnglet
                                  , aTypeSumstock
                                  , aStocksId
                                  , iInclSubcontractPPdt
                                  , iInclPdtSuppliedBySubctor
                                  , iInclTxtPosition
                                   );

        fetch AllGood_Nom_Interr
         into AllGood_Nom_tuple_Interr;
      end loop;

      close AllGood_Nom_Interr;
    else
      open AllGood_Nom_CasEmpl(aGCO_GOOD_ID);

      fetch AllGood_Nom_CasEmpl
       into AllGood_Nom_tuple_CasEmpl;

      while AllGood_Nom_CasEmpl%found loop
        GetStocks(AllGood_Nom_tuple_CasEmpl.GCO_GOOD_ID, aTypeSumStock, aStocksId, SumCursorAvailQty, SumCursorAssignQty, SumcursorProvIn, SumCursorProvOut);
        GetNetwork(AllGood_Nom_tuple_CasEmpl.GCO_GOOD_ID, aTypeSumStock, aStocksId, SumCursorAppro, SumCursorBesoin);

        insert into PPS_NOM_INTERRO
                    (PPS_NOM_INTERRO_ID
                   , PPS_NOM_INTERRO_USER_ID
                   , PPS_NOMENCLATURE_ID
                   , GCO_GOOD_ID
                   , INT_INDEX
                   , INT_TYPE
                   , COM_SEQ
                   , GOO_MAJOR_REFERENCE
                   , GOO_SECONDARY_REFERENCE
                   , C_TYPE_COM
                   , C_KIND_COM
                   , DES_SHORT_DESCRIPTION
                   , DIC_UNIT_OF_MEASURE_ID
                   , COM_UTIL_COEFF
                   , COM_PDIR_COEFF
                   , COM_REC_PCENT
                   , COM_POS
                   , SCS_STEP_NUMBER
                   , STO_DESCRIPTION
                   , LOC_DESCRIPTION
                   , COM_VAL
                   , C_DISCHARGE_COM
                   , C_REMPLACEMENT_NOM
                   , COM_REMPLACEMENT
                   , COM_BEG_VALID
                   , COM_END_VALID
                   , COM_SUBSTITUT
                   , COM_INTERVAL
                   , COM_TEXT
                   , COM_RES_TEXT
                   , COM_RES_NUM
                   , SPO_AVAILABLE_QUANTITY
                   , SPO_ASSIGN_QUANTITY
                   , SPO_PROVISORY_INPUT
                   , SPO_PROVISORY_OUTPUT
                   , FAN_BALANCE_QTY_SUPPLY
                   , FAN_BALANCE_QTY_NEED
                   , C_TYPE_NOM
                   , NOM_VERSION
                   , NOM_DEFAULT
                    )
             values (Init_Id_Seq.nextval
                   , aPPS_NOM_INTERRO_USER_ID
                   , aPPS_NOMENCLATURE_ID
                   , AllGood_Nom_tuple_CasEmpl.GCO_GOOD_ID
                   , aIndex
                   , 1
                   , AllGood_Nom_tuple_CasEmpl.COM_SEQ
                   , AllGood_Nom_tuple_CasEmpl.GOO_MAJOR_REFERENCE
                   , AllGood_Nom_tuple_CasEmpl.GOO_SECONDARY_REFERENCE
                   , AllGood_Nom_tuple_CasEmpl.C_TYPE_COM
                   , AllGood_Nom_tuple_CasEmpl.C_KIND_COM
                   , PPS_INTERRO.SearchShortDesc(AllGood_Nom_tuple_CasEmpl.GCO_GOOD_ID)
                   , AllGood_Nom_tuple_CasEmpl.DIC_UNIT_OF_MEASURE_ID
                   , AllGood_Nom_tuple_CasEmpl.COM_UTIL_COEFF
                   , AllGood_Nom_tuple_CasEmpl.COM_PDIR_COEFF
                   , AllGood_Nom_tuple_CasEmpl.COM_REC_PCENT
                   , AllGood_Nom_tuple_CasEmpl.COM_POS
                   , PPS_INTERRO.SearchStepLink(AllGood_Nom_tuple_CasEmpl.FAL_SCHEDULE_STEP_ID)
                   , PPS_INTERRO.SearchStock(AllGood_Nom_tuple_CasEmpl.STM_STOCK_ID)
                   , PPS_INTERRO.SearchLocation(AllGood_Nom_tuple_CasEmpl.STM_LOCATION_ID)
                   , AllGood_Nom_tuple_CasEmpl.COM_VAL
                   , AllGood_Nom_tuple_CasEmpl.C_DISCHARGE_COM
                   , AllGood_Nom_tuple_CasEmpl.C_REMPLACEMENT_NOM
                   , AllGood_Nom_tuple_CasEmpl.COM_REMPLACEMENT
                   , AllGood_Nom_tuple_CasEmpl.COM_BEG_VALID
                   , AllGood_Nom_tuple_CasEmpl.COM_END_VALID
                   , AllGood_Nom_tuple_CasEmpl.COM_SUBSTITUT
                   , AllGood_Nom_tuple_CasEmpl.COM_INTERVAL
                   , AllGood_Nom_tuple_CasEmpl.COM_TEXT
                   , AllGood_Nom_tuple_CasEmpl.COM_RES_TEXT
                   , AllGood_Nom_tuple_CasEmpl.COM_RES_NUM
                   , SumCursorAvailQty
                   , SumCursorAssignQty
                   , SumCursorProvIn
                   , SumCursorProvOut
                   , SumCursorAppro
                   , SumCursorBesoin
                   , AllGood_Nom_tuple_CasEmpl.C_TYPE_NOM
                   , AllGood_Nom_tuple_CasEmpl.NOM_VERSION
                   , AllGood_Nom_tuple_CasEmpl.NOM_DEFAULT
                    );

        if aOnglet = 3 then
          InsertGoodForAchat(aPPS_NOM_INTERRO_USER_ID, aPPS_NOMENCLATURE_ID, AllGood_Nom_tuple_CasEmpl.GCO_GOOD_ID, aIndex, 1);
        end if;

        if aOnglet = 4 then
          InsertGoodForFab(aPPS_NOM_INTERRO_USER_ID, aPPS_NOMENCLATURE_ID, AllGood_Nom_tuple_CasEmpl.GCO_GOOD_ID, aIndex, 1);
        end if;

        SearchAllGoodOfNomenclature(0
                                  , aIndex + 1
                                  , aPPS_NOM_INTERRO_USER_ID
                                  , aTypeNom
                                  , AllGood_Nom_tuple_CasEmpl.GCO_GOOD_ID
                                  , aTypeInterr
                                  , aOnglet
                                  , aTypeSumstock
                                  , aStocksId
                                  , iInclSubcontractPPdt
                                  , iInclPdtSuppliedBySubctor
                                  , iInclTxtPosition
                                   );

        fetch AllGood_Nom_CasEmpl
         into AllGood_Nom_tuple_CasEmpl;
      end loop;

      close AllGood_Nom_CasEmpl;
    end if;
  end SearchAllGoodOfNomenclature;

  procedure InsertGoodForAchat(aPPS_NOM_INTERRO_USER_ID in number, aPPS_NOMENCLATURE_ID in number, aGCO_GOOD_ID in number, aIndex in number, aType in number)
  is
    fIndex              number;

    cursor AllGood_Achat(GoodId number)
    is
      select   PAC_PERSON1.PER_NAME
             , GCO_COMPL_DATA_PURCHASE1.CDA_COMPLEMENTARY_REFERENCE
             , GCO_COMPL_DATA_PURCHASE1.CDA_SHORT_DESCRIPTION
             , GCO_COMPL_DATA_PURCHASE1.CDA_LONG_DESCRIPTION
             , GCO_COMPL_DATA_PURCHASE1.DIC_COMPLEMENTARY_DATA_ID
             , GCO_COMPL_DATA_PURCHASE1.STM_STOCK_ID
             , GCO_COMPL_DATA_PURCHASE1.STM_LOCATION_ID
             , GCO_COMPL_DATA_PURCHASE1.DIC_UNIT_OF_MEASURE_ID
             , GCO_COMPL_DATA_PURCHASE1.CDA_NUMBER_OF_DECIMAL
             , GCO_COMPL_DATA_PURCHASE1.CDA_CONVERSION_FACTOR
             , GCO_COMPL_DATA_PURCHASE1.C_QTY_SUPPLY_RULE
             , GCO_COMPL_DATA_PURCHASE1.CPU_FIXED_DELAY
             , GCO_COMPL_DATA_PURCHASE1.CPU_SUPPLY_CAPACITY
             , GCO_COMPL_DATA_PURCHASE1.CPU_CONTROL_DELAY
             , GCO_COMPL_DATA_PURCHASE1.GCO_QUALITY_PRINCIPLE_ID
             , GCO_COMPL_DATA_PURCHASE1.CPU_PERCENT_TRASH
             , GCO_COMPL_DATA_PURCHASE1.CPU_QTY_REFERENCE_TRASH
             , GCO_COMPL_DATA_PURCHASE1.CPU_FIXED_QUANTITY_TRASH
             , GCO_COMPL_DATA_PURCHASE1.CPU_ECONOMICAL_QUANTITY
             , GCO_COMPL_DATA_PURCHASE1.C_TIME_SUPPLY_RULE
             , GCO_COMPL_DATA_PURCHASE1.CPU_SUPPLY_DELAY
          from GCO_COMPL_DATA_PURCHASE GCO_COMPL_DATA_PURCHASE1
             , PAC_PERSON PAC_PERSON1
         where GCO_COMPL_DATA_PURCHASE1.GCO_GOOD_ID = GoodId
           and PAC_PERSON1.PAC_PERSON_ID = GCO_COMPL_DATA_PURCHASE1.PAC_SUPPLIER_PARTNER_ID
      order by CPU_DEFAULT_SUPPLIER desc;

    AllGood_Achat_tuple AllGood_Achat%rowtype;
  begin
    select max(INT_INDEX)
      into fIndex
      from PPS_NOM_INTERRO_ACHAT
     where PPS_NOM_INTERRO_USER_ID = aPPS_NOM_INTERRO_USER_ID;

    if fIndex is null then
      fIndex  := aIndex;
    end if;

    open AllGood_Achat(aGCO_GOOD_ID);

    fetch AllGood_Achat
     into AllGood_Achat_tuple;

    while AllGood_Achat%found loop
      insert into PPS_NOM_INTERRO_ACHAT
                  (PPS_NOM_INTERRO_ACHAT_ID
                 , PPS_NOM_INTERRO_USER_ID
                 , PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , INT_INDEX
                 , INT_TYPE
                 , PER_NAME
                 , CDA_COMPLEMENTARY_REFERENCE
                 , CDA_SHORT_DESCRIPTION
                 , CDA_LONG_DESCRIPTION
                 , DIC_COMPLEMENTARY_DATA_ID
                 , STO_DESCRIPTION_ACHAT
                 , LOC_DESCRIPTION_ACHAT
                 , DIC_UNIT_OF_MEASURE_ID_ACHAT
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_CONVERSION_FACTOR
                 , C_QTY_SUPPLY_RULE
                 , CPU_FIXED_DELAY
                 , CPU_SUPPLY_CAPACITY
                 , CPU_CONTROL_DELAY
                 , QPR_STANDARD_DESCRIPTION
                 , CPU_PERCENT_TRASH
                 , CPU_QTY_REFERENCE_TRASH
                 , CPU_FIXED_QUANTITY_TRASH
                 , CPU_ECONOMICAL_QUANTITY
                 , C_TIME_SUPPLY_RULE
                 , CPU_SUPPLY_DELAY
                  )
           values (Init_Id_Seq.nextval
                 , aPPS_NOM_INTERRO_USER_ID
                 , aPPS_NOMENCLATURE_ID
                 , aGCO_GOOD_ID
                 , fIndex + 1
                 , aType
                 , AllGood_Achat_tuple.PER_NAME
                 , AllGood_Achat_tuple.CDA_COMPLEMENTARY_REFERENCE
                 , AllGood_Achat_tuple.CDA_SHORT_DESCRIPTION
                 , AllGood_Achat_tuple.CDA_LONG_DESCRIPTION
                 , AllGood_Achat_tuple.DIC_COMPLEMENTARY_DATA_ID
                 , PPS_INTERRO.SearchStock(AllGood_Achat_tuple.STM_STOCK_ID)
                 , PPS_INTERRO.SearchLocation(AllGood_Achat_tuple.STM_LOCATION_ID)
                 , AllGood_Achat_tuple.DIC_UNIT_OF_MEASURE_ID
                 , AllGood_Achat_tuple.CDA_NUMBER_OF_DECIMAL
                 , AllGood_Achat_tuple.CDA_CONVERSION_FACTOR
                 , AllGood_Achat_tuple.C_QTY_SUPPLY_RULE
                 , AllGood_Achat_tuple.CPU_FIXED_DELAY
                 , AllGood_Achat_tuple.CPU_SUPPLY_CAPACITY
                 , AllGood_Achat_tuple.CPU_CONTROL_DELAY
                 , PPS_INTERRO.SearchQualityPrincipleDesc(AllGood_Achat_tuple.GCO_QUALITY_PRINCIPLE_ID)
                 , AllGood_Achat_tuple.CPU_PERCENT_TRASH
                 , AllGood_Achat_tuple.CPU_QTY_REFERENCE_TRASH
                 , AllGood_Achat_tuple.CPU_FIXED_QUANTITY_TRASH
                 , AllGood_Achat_tuple.CPU_ECONOMICAL_QUANTITY
                 , AllGood_Achat_tuple.C_TIME_SUPPLY_RULE
                 , AllGood_Achat_tuple.CPU_SUPPLY_DELAY
                  );

      fetch AllGood_Achat
       into AllGood_Achat_tuple;
    end loop;

    close AllGood_Achat;
  end InsertGoodForAchat;

  procedure InsertGoodForFab(aPPS_NOM_INTERRO_USER_ID in number, aPPS_NOMENCLATURE_ID in number, aGCO_GOOD_ID in number, aIndex in number, aType in number)
  is
    fIndex            number;

    cursor AllGood_Fab(GoodId number)
    is
      select   GCO_COMPL_DATA_MANUFACTURE1.DIC_FAB_CONDITION_ID
             , GCO_COMPL_DATA_MANUFACTURE1.C_QTY_SUPPLY_RULE
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_ECONOMICAL_QUANTITY
             , GCO_COMPL_DATA_MANUFACTURE1.C_TIME_SUPPLY_RULE
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_FIXED_DELAY
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_PERCENT_TRASH
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_PERCENT_WASTE
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_FIXED_QUANTITY_TRASH
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_FIXED_QUANTITY_WASTE
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_QTY_REFERENCE_LOSS
             , GCO_COMPL_DATA_MANUFACTURE1.FAL_SCHEDULE_PLAN_ID
             , GCO_COMPL_DATA_MANUFACTURE1.PPS_NOMENCLATURE_ID
             , GCO_COMPL_DATA_MANUFACTURE1.PPS_RANGE_ID
             , GCO_COMPL_DATA_MANUFACTURE1.PPS_OPERATION_PROCEDURE_ID
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_LOT_QUANTITY
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_MANUFACTURING_DELAY
             , GCO_COMPL_DATA_MANUFACTURE1.GCO_QUALITY_PRINCIPLE_ID
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_PLAN_NUMBER
             , GCO_COMPL_DATA_MANUFACTURE1.CMA_PLAN_VERSION
          from GCO_COMPL_DATA_MANUFACTURE GCO_COMPL_DATA_MANUFACTURE1
         where GCO_COMPL_DATA_MANUFACTURE1.GCO_GOOD_ID = GoodId
      order by CMA_DEFAULT desc;

    AllGood_Fab_tuple AllGood_Fab%rowtype;
  begin
    select max(INT_INDEX)
      into fIndex
      from PPS_NOM_INTERRO_FAB
     where PPS_NOM_INTERRO_USER_ID = aPPS_NOM_INTERRO_USER_ID;

    if fIndex is null then
      fIndex  := aIndex;
    end if;

    open AllGood_Fab(aGCO_GOOD_ID);

    fetch AllGood_Fab
     into AllGood_Fab_tuple;

    while AllGood_Fab%found loop
      insert into PPS_NOM_INTERRO_FAB
                  (PPS_NOM_INTERRO_FAB_ID
                 , PPS_NOM_INTERRO_USER_ID
                 , PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , INT_INDEX
                 , INT_TYPE
                 , DIC_FAB_CONDITION_ID
                 , C_QTY_SUPPLY_RULE
                 , CMA_ECONOMICAL_QUANTITY
                 , C_TIME_SUPPLY_RULE
                 , CMA_FIXED_DELAY
                 , CMA_PERCENT_TRASH
                 , CMA_PERCENT_WASTE
                 , CMA_FIXED_QUANTITY_TRASH
                 , CMA_FIXED_QUANTITY_WASTE
                 , CMA_QTY_REFERENCE_LOSS
                 , C_TYPE_NOM
                 , NOM_VERSION
                 , SCH_REF_NOM
                 , SCH_REF
                 , C_SCHEDULE_PLANNING
                 , C_STATUS_RANGE
                 , OPP_REFERENCE
                 , RAN_REFERENCE
                 , CMA_LOT_QUANTITY
                 , CMA_MANUFACTURING_DELAY
                 , QPR_STANDARD_DESCRIPTION
                 , CMA_PLAN_NUMBER
                 , CMA_PLAN_VERSION
                  )
           values (Init_Id_Seq.nextval
                 , aPPS_NOM_INTERRO_USER_ID
                 , aPPS_NOMENCLATURE_ID
                 , aGCO_GOOD_ID
                 , fIndex + 1
                 , aType
                 , AllGood_Fab_tuple.DIC_FAB_CONDITION_ID
                 , AllGood_Fab_tuple.C_QTY_SUPPLY_RULE
                 , AllGood_Fab_tuple.CMA_ECONOMICAL_QUANTITY
                 , AllGood_Fab_tuple.C_TIME_SUPPLY_RULE
                 , AllGood_Fab_tuple.CMA_FIXED_DELAY
                 , AllGood_Fab_tuple.CMA_PERCENT_TRASH
                 , AllGood_Fab_tuple.CMA_PERCENT_WASTE
                 , AllGood_Fab_tuple.CMA_FIXED_QUANTITY_TRASH
                 , AllGood_Fab_tuple.CMA_FIXED_QUANTITY_WASTE
                 , AllGood_Fab_tuple.CMA_QTY_REFERENCE_LOSS
                 , PPS_INTERRO.SearchNomType(AllGood_Fab_tuple.PPS_NOMENCLATURE_ID)
                 , PPS_INTERRO.SearchNomVersion(AllGood_Fab_tuple.PPS_NOMENCLATURE_ID)
                 , PPS_INTERRO.SearchRefGamme(PPS_INTERRO.SearchNomGamme(AllGood_Fab_tuple.PPS_NOMENCLATURE_ID) )
                 , PPS_INTERRO.SearchRefGamme(AllGood_Fab_tuple.FAL_SCHEDULE_PLAN_ID)
                 , PPS_INTERRO.SearchGamme(AllGood_Fab_tuple.FAL_SCHEDULE_PLAN_ID)
                 , PPS_INTERRO.SearchRange(AllGood_Fab_tuple.PPS_RANGE_ID)
                 , PPS_INTERRO.SearchProcedureOperation(AllGood_Fab_tuple.PPS_OPERATION_PROCEDURE_ID)
                 , PPS_INTERRO.SearchRefRange(AllGood_Fab_tuple.PPS_RANGE_ID)
                 , AllGood_Fab_tuple.CMA_LOT_QUANTITY
                 , AllGood_Fab_tuple.CMA_MANUFACTURING_DELAY
                 , PPS_INTERRO.SearchQualityPrincipleDesc(AllGood_Fab_tuple.GCO_QUALITY_PRINCIPLE_ID)
                 , AllGood_Fab_tuple.CMA_PLAN_NUMBER
                 , AllGood_Fab_tuple.CMA_PLAN_VERSION
                  );

      fetch AllGood_Fab
       into AllGood_Fab_tuple;
    end loop;

    close AllGood_Fab;
  end InsertGoodForFab;

-- Recherche de la quantité principale
  function SearchQualityPrincipleDesc(aQtyPrincipleId in number)
    return GCO_QUALITY_PRINCIPLE.QPR_STANDARD_DESCRIPTION%type
  is
    QtyPrinciple GCO_QUALITY_PRINCIPLE.QPR_STANDARD_DESCRIPTION%type;
  begin
    select QPR_STANDARD_DESCRIPTION
      into QtyPrinciple
      from GCO_QUALITY_PRINCIPLE
     where GCO_QUALITY_PRINCIPLE_ID = aQtyPrincipleId;

    return QtyPrinciple;
  exception
    when no_data_found then
      return 0;
  end SearchQualityPrincipleDesc;

-- Recherche de la nomenclature
  function SearchNomenclature(aGoodId in number, aTypeNom in varchar2)
    return PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  is
    Nomenclature_Id PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
  begin
    select PPS_NOMENCLATURE_ID
      into Nomenclature_Id
      from PPS_NOMENCLATURE
     where GCO_GOOD_ID = aGoodId
       and C_TYPE_NOM = aTypeNom
       and NOM_DEFAULT = 1;

    return Nomenclature_Id;
  exception
    when no_data_found then
      return 0;
  end SearchNomenclature;

-- Recherche de la description courte
  function SearchShortDesc(aGoodId in number)
    return GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type
  is
    ShortDesc GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
  begin
    select DES_SHORT_DESCRIPTION
      into ShortDesc
      from GCO_DESCRIPTION
     where GCO_GOOD_ID = aGoodId
       and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
       and C_DESCRIPTION_TYPE = '01';

    return ShortDesc;
  exception
    when no_data_found then
      return '';
  end SearchShortDesc;

-- Recherche du stock logique
  function SearchStock(aStockId in number)
    return STM_STOCK.STO_DESCRIPTION%type
  is
    StockDesc STM_STOCK.STO_DESCRIPTION%type;
  begin
    select STO_DESCRIPTION
      into StockDesc
      from STM_STOCK
     where STM_STOCK_ID = aStockId;

    return StockDesc;
  exception
    when no_data_found then
      return '';
  end SearchStock;

-- Recherche de l'emplacement du stock
  function SearchLocation(aLocationId in number)
    return STM_LOCATION.LOC_DESCRIPTION%type
  is
    LocDesc STM_LOCATION.LOC_DESCRIPTION%type;
  begin
    select LOC_DESCRIPTION
      into LocDesc
      from STM_LOCATION
     where STM_LOCATION_ID = aLocationId;

    return LocDesc;
  exception
    when no_data_found then
      return '';
  end SearchLocation;

-- Recherche du lien de tâche
  function SearchStepLink(aFalScheduleId in number)
    return FAL_LIST_STEP_LINK.SCS_STEP_NUMBER%type
  is
    FalList FAL_LIST_STEP_LINK.SCS_STEP_NUMBER%type;
  begin
    select SCS_STEP_NUMBER
      into FalList
      from FAL_LIST_STEP_LINK
     where FAL_SCHEDULE_STEP_ID = aFalScheduleId;

    return FalList;
  exception
    when no_data_found then
      return 0;
  end SearchStepLink;

-- Recherche du type de nomenclature
  function SearchNomType(aNomenclatureId in number)
    return PPS_NOMENCLATURE.C_TYPE_NOM%type
  is
    TypeNom PPS_NOMENCLATURE.C_TYPE_NOM%type;
  begin
    select C_TYPE_NOM
      into TypeNom
      from PPS_NOMENCLATURE
     where PPS_NOMENCLATURE_ID = aNomenclatureId;

    return TypeNom;
  exception
    when no_data_found then
      return '';
  end SearchNomType;

-- Recherche de la version de la nomenclature
  function SearchNomVersion(aNomenclatureId in number)
    return PPS_NOMENCLATURE.NOM_VERSION%type
  is
    VersionNom PPS_NOMENCLATURE.NOM_VERSION%type;
  begin
    select NOM_VERSION
      into VersionNom
      from PPS_NOMENCLATURE
     where PPS_NOMENCLATURE_ID = aNomenclatureId;

    return VersionNom;
  exception
    when no_data_found then
      return '';
  end SearchNomVersion;

-- Recherche de la gamme opératoire de la nomenclature
  function SearchNomGamme(aNomenclatureId in number)
    return PPS_NOMENCLATURE.FAL_SCHEDULE_PLAN_ID%type
  is
    GammeNom PPS_NOMENCLATURE.FAL_SCHEDULE_PLAN_ID%type;
  begin
    select FAL_SCHEDULE_PLAN_ID
      into GammeNom
      from PPS_NOMENCLATURE
     where PPS_NOMENCLATURE_ID = aNomenclatureId;

    return GammeNom;
  exception
    when no_data_found then
      return 0;
  end SearchNomGamme;

-- Recherche de la gamme opératoire
  function SearchGamme(aGammeId in number)
    return FAL_SCHEDULE_PLAN.C_SCHEDULE_PLANNING%type
  is
    Gamme FAL_SCHEDULE_PLAN.C_SCHEDULE_PLANNING%type;
  begin
    select C_SCHEDULE_PLANNING
      into Gamme
      from FAL_SCHEDULE_PLAN
     where FAL_SCHEDULE_PLAN_ID = aGammeId;

    return Gamme;
  exception
    when no_data_found then
      return '';
  end SearchGamme;

-- Recherche de la référence de la gamme opératoire
  function SearchRefGamme(aGammeId in number)
    return FAL_SCHEDULE_PLAN.SCH_REF%type
  is
    RefGamme FAL_SCHEDULE_PLAN.SCH_REF%type;
  begin
    select FAL_SCHEDULE_PLAN_ID
      into RefGamme
      from FAL_SCHEDULE_PLAN
     where FAL_SCHEDULE_PLAN_ID = aGammeId;

    return RefGamme;
  exception
    when no_data_found then
      return '';
  end SearchRefGamme;

-- Recherche du lien de tâche
  function SearchRange(aRangeId in number)
    return PPS_RANGE.C_STATUS_RANGE%type
  is
    fRange PPS_RANGE.C_STATUS_RANGE%type;
  begin
    select C_STATUS_RANGE
      into fRange
      from PPS_RANGE
     where PPS_RANGE_ID = aRangeId;

    return fRange;
  exception
    when no_data_found then
      return '';
  end SearchRange;

-- Recherche de la référence du lien de tâche
  function SearchRefRange(aRangeId in number)
    return PPS_RANGE.RAN_REFERENCE%type
  is
    RefRange PPS_RANGE.RAN_REFERENCE%type;
  begin
    select RAN_REFERENCE
      into RefRange
      from PPS_RANGE
     where PPS_RANGE_ID = aRangeId;

    return RefRange;
  exception
    when no_data_found then
      return '';
  end SearchRefRange;

-- Recherche de la procédure d'opération
  function SearchProcedureOperation(aProcOpId in number)
    return PPS_OPERATION_PROCEDURE.OPP_REFERENCE%type
  is
    ProcOp PPS_OPERATION_PROCEDURE.OPP_REFERENCE%type;
  begin
    select OPP_REFERENCE
      into ProcOp
      from PPS_OPERATION_PROCEDURE
     where PPS_OPERATION_PROCEDURE_ID = aProcOpId;

    return ProcOp;
  exception
    when no_data_found then
      return '';
  end SearchProcedureOperation;

--OM 10.12.98
--Recherche des valeurs de stock. récupère toutes les valeurs d'un coup.***************************************************
  procedure GetStocks(
    aGoodId       in     number
  ,   -- Id du bien dont on cherche les stocks
    aTypeSumStock in     number
  ,   -- Type de sommation de stocks (0=tous, 1=dans liste, 2=Public, 3=Privé)
    aStocksID     in     varchar2
  ,   -- Liste des stocks à tester dans le cas ou aTypeSumStock=1
    aSumAvailQty  in out number
  ,   -- Quantité disponible
    aSumAssignQty in out number
  ,   -- Quantité assignée
    aSumProvIn    in out number
  ,   -- Entrées provisoires
    aSumProvOut   in out number
  )   -- Sorties provisoires
  is
    --Variables locales
    strAccessMethod varchar2(10);   --Méthode d'acces au stocks, si pas tous ni dans liste
    dynResult       tDynSQLResult;   --tampon résultat req. dyn.
  begin
    if aGoodId is not null then   -- Ne recherche les stocks que si il y a un bien.
      --Sélection du type de recherche
      --Recherche dans tous les stocks
      if aTypeSumStock = 4 then
        --Requête de recherche des valeurs. Mets le résultat dans les variables
        select sum(SPO_AVAILABLE_QUANTITY)
             , sum(SPO_ASSIGN_QUANTITY)
             , sum(SPO_PROVISORY_INPUT)
             , sum(SPO_PROVISORY_OUTPUT)
          into aSumAvailQty
             , aSumAssignQty
             , aSumProvIn
             , aSumProvOut
          from STM_STOCK_POSITION
         where GCO_GOOD_ID = aGoodId;
      --Recherche dans liste de stocks sélectionnés
      elsif aTypeSumStock = 1 then
        --prépare la table temp
        dynResult.delete;
        dynResult(1)   := 0;
        dynResult(2)   := 0;
        dynResult(3)   := 0;
        dynResult(4)   := 0;
        ExecDynSQL
          ('SELECT SUM(SPO_AVAILABLE_QUANTITY),SUM(SPO_ASSIGN_QUANTITY),SUM(SPO_PROVISORY_INPUT),SUM(SPO_PROVISORY_OUTPUT) FROM STM_STOCK_POSITION WHERE GCO_GOOD_ID = ' ||
           aGoodId ||
           ' AND STM_STOCK_ID IN (' ||
           aStocksId ||
           ')'
         , dynResult
          );
        --récupere résultat
        aSumAvailQty   := dynResult(1);
        aSumAssignQty  := dynResult(2);
        aSumProvIn     := dynResult(3);
        aSumProvOut    := dynResult(4);
        --Tue la table temp
        dynResult.delete;
      --Recherche dans stocks publics et privés
      elsif    aTypeSumStock = 2
            or aTypeSumStock = 3 then
        if aTypeSumStock = 2 then
          strAccessMethod  := 'PUBLIC';
        else
          strAccessMethod  := 'PRIVATE';
        end if;

        --Requête de recherche des valeurs. Mets le résultat dans les variables
        select sum(SPO_AVAILABLE_QUANTITY)
             , sum(SPO_ASSIGN_QUANTITY)
             , sum(SPO_PROVISORY_INPUT)
             , sum(SPO_PROVISORY_OUTPUT)
          into aSumAvailQty
             , aSumAssignQty
             , aSumProvIn
             , aSumProvOut
          from STM_STOCK_POSITION
         where GCO_GOOD_ID = aGoodId
           and STM_STOCK_ID in(select STM_STOCK_ID
                                 from STM_STOCK
                                where C_ACCESS_METHOD = strAccessMethod);
      elsif aTypeSumStock = 0 then   -- Publics géré dans le calcul des besoins
        strAccessMethod  := 'PUBLIC';

        --Requête de recherche des valeurs. Mets le résultat dans les variables
        select sum(SPO_AVAILABLE_QUANTITY)
             , sum(SPO_ASSIGN_QUANTITY)
             , sum(SPO_PROVISORY_INPUT)
             , sum(SPO_PROVISORY_OUTPUT)
          into aSumAvailQty
             , aSumAssignQty
             , aSumProvIn
             , aSumProvOut
          from STM_STOCK_POSITION
         where GCO_GOOD_ID = aGoodId
           and STM_STOCK_ID in(select STM_STOCK_ID
                                 from STM_STOCK
                                where C_ACCESS_METHOD = strAccessMethod
                                  and STO_NEED_CALCULATION = 1);
      end if;   --if aTypeSumStock=...
    end if;   --If aGoodId Is Not Null Then
--Si pas de données trouvées, mettre tout à 0 ---------------------------------------------------------------------------
  exception
    when no_data_found then
      aSumAvailQty   := 0;
      aSumAssignQty  := 0;
      aSumProvIn     := 0;
      aSumProvOut    := 0;
  end GetStocks;

--*************************************************************************************************

  --Recherche des valeurs de réseau *****************************************************************************************
  procedure GetNetwork(
    aGoodId       in     number
  ,   -- Id du bien dont on cherche les stocks
    aTypeSumStock in     number
  ,   -- Type de sommation de stocks (0=tous, 1=dans liste, 2=Public, 3=Privé)
    aStocksID     in     varchar2
  ,   -- Liste des stocks à tester dans le cas ou aTypeSumStock=1
    aSumSupply    in out number
  ,   -- Quantité approvisionnement
    aSumNeed      in out number
  )   -- Quantité besoin
  is
    strAccessMethod varchar2(10);
    dynResult       tdynSQLResult;
    Step            integer;
  begin
    --Si il y a un bien à contrôler
    if aGoodId is not null then
      --Recherche Approvisionnement : aSumSupply ------------------------------------------------------------------------------
      Step  := 1;

      if aTypeSumStock = 4 then
        --Requête de recherche des valeurs. Mets le résultat dans les variables
        select sum(FAN_BALANCE_QTY)
          into aSumSupply
          from FAL_NETWORK_SUPPLY
         where GCO_GOOD_ID = aGoodId;
      --Recherche dans liste de stocks sélectionnés
      elsif aTypeSumStock = 1 then
        --prépare la table temp
        dynResult.delete;
        dynResult(1)  := 0;
        ExecDynSQL('SELECT SUM(FAN_BALANCE_QTY) FROM FAL_NETWORK_SUPPLY WHERE GCO_GOOD_ID = ' || aGoodId || ' AND STM_STOCK_ID IN (' || aStocksId || ')'
                 , dynResult
                  );
        --récupere résultat
        aSumSupply    := dynResult(1);
        --Tue la table temp
        dynResult.delete;
      --Recherche dans stocks publics et privés
      elsif    aTypeSumStock = 2
            or aTypeSumStock = 3 then
        if aTypeSumStock = 2 then
          strAccessMethod  := 'PUBLIC';
        else
          strAccessMethod  := 'PRIVATE';
        end if;

        --Requête de recherche de la valeur. Mets le résultat dans la variable
        select sum(FAN_BALANCE_QTY)
          into aSumSupply
          from FAL_NETWORK_SUPPLY
         where GCO_GOOD_ID = aGoodId
           and STM_STOCK_ID in(select STM_STOCK_ID
                                 from STM_STOCK
                                where C_ACCESS_METHOD = strAccessMethod);
      elsif aTypeSumStock = 0 then   -- Publics géré dans le calcul des besoins
        strAccessMethod  := 'PUBLIC';

        --Requête de recherche des valeurs. Mets le résultat dans les variables
        select sum(FAN_BALANCE_QTY)
          into aSumSupply
          from FAL_NETWORK_SUPPLY
         where GCO_GOOD_ID = aGoodId
           and STM_STOCK_ID in(select STM_STOCK_ID
                                 from STM_STOCK
                                where C_ACCESS_METHOD = strAccessMethod
                                  and STO_NEED_CALCULATION = 1);
      end if;   --if aTypeSumStock=...

      --Recherche Besoin : aSumNeed -------------------------------------------------------------------------------------------
      Step  := 2;

      if aTypeSumStock = 4 then
        --Requête de recherche des valeurs. Mets le résultat dans les variables
        select sum(FAN_BALANCE_QTY)
          into aSumNeed
          from FAL_NETWORK_NEED
         where GCO_GOOD_ID = aGoodId;
      --Recherche dans liste de stocks sélectionnés
      elsif aTypeSumStock = 1 then
        --prépare la table temp
        dynResult.delete;
        dynResult(1)  := 0;
        ExecDynSQL('SELECT SUM(FAN_BALANCE_QTY) FROM FAL_NETWORK_NEED WHERE GCO_GOOD_ID = ' || aGoodId || ' AND STM_STOCK_ID IN (' || aStocksId || ')'
                 , dynResult
                  );
        --récupere résultat
        aSumNeed      := dynResult(1);
        --Tue la table temp
        dynResult.delete;
      --Recherche dans stocks publics et privés
      elsif    aTypeSumStock = 2
            or aTypeSumStock = 3 then
        if aTypeSumStock = 2 then
          strAccessMethod  := 'PUBLIC';
        else
          strAccessMethod  := 'PRIVATE';
        end if;

        --Requête de recherche de la valeur. Mets le résultat dans la variable
        select sum(FAN_BALANCE_QTY)
          into aSumNeed
          from FAL_NETWORK_NEED
         where GCO_GOOD_ID = aGoodId
           and STM_STOCK_ID in(select STM_STOCK_ID
                                 from STM_STOCK
                                where C_ACCESS_METHOD = strAccessMethod);
      elsif aTypeSumStock = 0 then   -- Publics géré dans le calcul des besoins
        strAccessMethod  := 'PUBLIC';

        select sum(FAN_BALANCE_QTY)
          into aSumNeed
          from FAL_NETWORK_NEED
         where GCO_GOOD_ID = aGoodId
           and STM_STOCK_ID in(select STM_STOCK_ID
                                 from STM_STOCK
                                where C_ACCESS_METHOD = strAccessMethod
                                  and STO_NEED_CALCULATION = 1);
      end if;   --if aTypeSumStock=...
    end if;   --If aGoodId Is Not Null Then
----Si pas de données trouvées, mettre tout à 0 ---------------------------------------------------------------------------
  exception
    when no_data_found then
      if Step = 1 then
        aSumSupply  := 0;
      else
        aSumNeed  := 0;
      end if;
  end GetNetwork;

--************************************************************************************************

  --Procédure d'execution des requêtes SQL dynamiques. **********************************************************************
--Met à jour les n valeurs de la table aResult avec les colonnes de aSQL
-- ATTENTION, il faut que aSQL retourne au minimum autant de colonnes que aResult a de lignes
  procedure ExecDynSQL(aSQL in varchar, aResult in out tDynSQLResult)
  is
    LocSource_Cursor integer;
    Ignore           integer;
    Idx              binary_integer;
  begin
    LocSource_Cursor  := DBMS_SQL.open_cursor;
    --Parse la requête
    DBMS_SQL.Parse(LocSource_Cursor, aSQL, DBMS_SQL.V7);

    --Définition des colonnes
    for Idx in 1 .. aResult.count loop
      DBMS_SQL.Define_column(LocSource_Cursor, Idx, aResult(Idx) );
    end loop;

    --Execute
    Ignore            := DBMS_SQL.execute(LocSource_Cursor);

    --Récupère valeurs dans le tableau aResult
    if DBMS_SQL.fetch_rows(LocSource_cursor) > 0 then
--        Raise_application_error(-20000,'Data found');
      for Idx in 1 .. aResult.count loop
        DBMS_SQL.column_value(LocSource_Cursor, Idx, aResult(Idx) );

        if aResult(Idx) is null then
          aResult(Idx)  := 0;
        end if;
      end loop;
    --Else
    end if;   --fetchrows>0

    --Fermer le curseur dynamique
    DBMS_SQL.Close_cursor(LocSource_cursor);
  end ExecDynSQL;
--************************************************************************************************
end PPS_INTERRO;
