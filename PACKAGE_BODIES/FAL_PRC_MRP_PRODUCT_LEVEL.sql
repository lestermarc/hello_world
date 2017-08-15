--------------------------------------------------------
--  DDL for Package Body FAL_PRC_MRP_PRODUCT_LEVEL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_MRP_PRODUCT_LEVEL" 
is
  /**
  * procedure InsertRowInFAL_PROD_LEVEL
  * Description : Insérer un nouveau record dans FAL_PROD_LEVEL si le produit n'existe pas déjà
  *               S'il existe déjà, modifier le niveau
  * @created ECA
  * @lastUpdate
  * @private
  */
  procedure InsertRowInFAL_PROD_LEVEL(aGoodID in TTypeID, aLevel in integer, PrmFiltered integer, PrmFPL_SESSION_ID FAL_PROD_LEVEL.FPL_SESSION_ID%type)
  is
    aNewID     TTypeID;
    aCount     integer;
    aFPL_COEFF FAL_PROD_LEVEL.FPL_COEFF%type;
  begin
    -- Déterminer un nouvel ID
    aNewID      := GetNewId;

    if PrmFiltered = 1 then
      aNewId  := -aNewID;
    end if;

    -- Vérifier si le produit n'existe pas déjà dans la table
    if PrmFiltered = 1 then
      select count(*)
        into aCount
        from FAL_PROD_LEVEL
       where GCO_GOOD_ID = aGoodID
         and FAL_PROD_LEVEL_ID < 0;
    else
      select count(*)
        into aCount
        from FAL_PROD_LEVEL
       where GCO_GOOD_ID = aGoodID
         and FAL_PROD_LEVEL_ID > 0;
    end if;

    -- Calcul du coefficient des couplés
    aFPL_COEFF  := FAL_COUPLED_GOOD.GetSumQteByRefOfCoupledGood(aGoodID);

    if aCount = 0 then
      -- Insérer l'élement dans la table FAL_PROD_LEVEL
      insert into FAL_PROD_LEVEL
                  (FAL_PROD_LEVEL_ID
                 , GCO_GOOD_ID
                 , FPL_SESSION_ID
                 , FPL_LEVEL
                 , FPL_COEFF
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aNewID
                 , aGoodID
                 , PrmFPL_SESSION_ID
                 , aLevel
                 , aFPL_COEFF
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    else
      -- Modifier le niveau de l'élement dans la table FAL_PROD_LEVEL
      if PrmFiltered = 1 then
        update FAL_PROD_LEVEL
           set FPL_LEVEL = aLevel
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where GCO_GOOD_ID = aGoodID
           and FAL_PROD_LEVEL_ID < 0;
      else
        update FAL_PROD_LEVEL
           set FPL_LEVEL = aLevel
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where GCO_GOOD_ID = aGoodID
           and FAL_PROD_LEVEL_ID > 0;
      end if;
    end if;
  end;

  /**
  * function LoadProductLevelTableByLevel
  * Description : Traiter les cas de produits de niveau aLevel
  *               Retourner Vrai si au moins un produit a été traité pour ce niveau
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aLevel : Niveau à traiter
  * @param   PrmFiltered : produits filtrés
  * @param   PrmFPL_SESSION_ID : Session oracle
  * @param
  */
  function LoadProductLevelTableByLevel(
    aLevel               in     integer
  , PrmFiltered          in     integer
  , PrmFPL_SESSION_ID    in     FAl_PROD_LEVEL.FPL_SESSION_ID%type
  , aLastProcessedGoodID in out number
  )
    return boolean
  is
    aOneProductFound boolean;
    aNomID           TTypeID;

    --
    cursor GetProductLevelsFiltered(aLevel in integer)
    is
      select GCO_GOOD_ID
        from FAL_PROD_LEVEL
       where FPL_LEVEL = aLevel
         and FAL_PROD_LEVEL_ID < 0;

    -- Lecture de toutes les nomenclatures du produit donné
    cursor CurAllNomenclatureOfProduct(aGoodID in TTypeID)
    is
      select PPS_NOMENCLATURE_ID
        from PPS_NOMENCLATURE
       where GCO_GOOD_ID = aGoodID
         and C_TYPE_NOM in('2', '3', '4', '6');

    -- Lecture de tous les GCO_GOOD_ID de FAL_PROD_LEVEL pour le niveau donné
    cursor GetProductLevelsNotFiltered(aLevel in integer)
    is
      select GCO_GOOD_ID
        from FAL_PROD_LEVEL
       where FPL_LEVEL = aLevel
         and FAL_PROD_LEVEL_ID > 0;

    -- Lecture des composants de la nomenclature donnée
    cursor GetNomenclatureComponents(aNomID in TTypeID)
    is
      select distinct Nom.GCO_GOOD_ID
                 from PPS_NOM_BOND Nom
                    , GCO_PRODUCT Product
                    , GCO_GOOD Good
                where Nom.PPS_NOMENCLATURE_ID = aNomID
                  and Nom.GCO_GOOD_ID = Product.GCO_GOOD_ID
                  and Nom.GCO_GOOD_ID = Good.GCO_GOOD_ID
                  -- Type de lien actif
                  and Nom.C_TYPE_COM = '1'
                  -- on prend aussi les pseudos
                  -- mais attention si pseudo on se moque de savoir s'il est géré en stock ou pas
                  and (    (    Nom.C_KIND_COM = '1'
                            and Product.PDT_STOCK_MANAGEMENT = 1)   -- Genre de lien composant -- Avec management de stock
                       or (Nom.C_KIND_COM = '3')   -- Genre de lien Pseudo
                      )
                  -- Avec calcul des besoins
                  and Product.PDT_CALC_REQUIREMENT_MNGMENT = 1
                  -- Actif (2) ou En cours d'inventaire (4)
                  and Good.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive;
  begin
    aOneProductFound      := false;
    aLastProcessedGoodID  := null;

    if PrmFiltered = 1 then
      -- Pour chaque produit de niveau aLevel (N)
      for aProduct in GetProductLevelsFiltered(aLevel) loop
        -- Noter le fait qu'au moins un produit a été trouvé
        aOneProductFound  := true;

        -- Rechercher toutes les nomenclatures du produit
        open CurAllNomenclatureOfProduct(aProduct.GCO_GOOD_ID);

        loop
          fetch CurAllNomenclatureOfProduct
           into aNomID;

          exit when CurAllNomenclatureOfProduct%notfound;

          -- Parcourir les produits de la nomenclature et ajouter les records dans FAL_PROD_LEVEL
          for aComponent in GetNomenclatureComponents(aNomID) loop
            -- Ajouter l'élement dans la table FAL_PROD_LEVEL
            InsertRowInFAL_PROD_LEVEL(aComponent.GCO_GOOD_ID, aLevel + 1, PrmFiltered, PrmFPL_SESSION_ID);
            aLastProcessedGoodID  := aComponent.GCO_GOOD_ID;
          end loop;
        end loop;

        close CurAllNomenclatureOfProduct;
      end loop;
    end if;

    if PrmFiltered = 0 then
      -- Parcourir tous les records de FAL_PROD_LEVEL pour le niveau donné
      for aProduct in GetProductLevelsNotFiltered(aLevel) loop
        -- Noter le fait qu'au moins un produit a été trouvé
        aOneProductFound  := true;

        -- Rechercher toutes les nomenclatures du produit
        open CurAllNomenclatureOfProduct(aProduct.GCO_GOOD_ID);

        loop
          fetch CurAllNomenclatureOfProduct
           into aNomID;

          exit when CurAllNomenclatureOfProduct%notfound;

          -- Parcourir les produits de la nomenclature et ajouter les records dans FAL_PROD_LEVEL
          for aComponent in GetNomenclatureComponents(aNomID) loop
            -- Ajouter l'élement dans la table FAL_PROD_LEVEL
            InsertRowInFAL_PROD_LEVEL(aComponent.GCO_GOOD_ID, aLevel + 1, PrmFiltered, PrmFPL_SESSION_ID);
            aLastProcessedGoodID  := aComponent.GCO_GOOD_ID;
          end loop;
        end loop;

        close CurAllNomenclatureOfProduct;
      end loop;
    end if;

    return(aOneProductFound);
  end;

  /**
  * function ControleDonneeCompDeFab
  * Description : Le but de cette fonction est de controler l'intégrité au niveau
  *               des données complémentaires de fabrication.
  * @created ECA
  * @lastUpdate
  * @private
  */
  function ControleDonneeCompDeFab
    return boolean
  is
    cursor C1
    is
      select count(*)
        from gco_compl_data_manufacture gco1
           , pps_nomenclature pps1
           , gco_good gco2
       where gco1.pps_nomenclature_id = pps1.pps_nomenclature_id
         and gco1.gco_good_id <> pps1.gco_good_id
         and gco1.gco_good_id = gco2.gco_good_id;

    N integer;
  begin
    open C1;

    fetch C1
     into N;

    return N <= 1;

    close C1;
  exception
    when others then
      if C1%isopen then
        close C1;
      end if;

      return false;
  end;

  /**
  * procedure LoadProductLevelTable
  * Description : Chargement de la table des niveaux pour le calcul MRP
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFiltered : Filtrage ou non des produits
  * @param   PrmGCO_GOOD_ID : Produit particulier (calcul par produit)
  * @param   PrmGCO_GOOD_CATEGORY1_ID : Catégorie de...
  * @param   PrmGCO_GOOD_CATEGORY2_ID : Catégorie à ...
  * @param   PrmDIC_GOOD_FAMILY1_ID : Famille de produit de...
  * @param   PrmDIC_GOOD_FAMILY2_ID : Famille de produit à ...
  * @param   PrmDIC_ACCOUNTABLE_GROUP1_ID : Responsable de ...
  * @param   PrmDIC_ACCOUNTABLE_GROUP2_ID : Responsable à ...
  * @param   PrmDIC_GOOD_LINE1_ID : Ligne de produit de ...
  * @param   PrmDIC_GOOD_LINE2_ID : Ligne de produit à ...
  * @param   PrmDIC_GOOD_GROUP1_ID : Groupe de produits de ...
  * @param   PrmDIC_GOOD_GROUP2_ID : Groupe de produits à ...
  * @param   PrmDIC_GOOD_MODEL1_ID : Modèle de produit de...
  * @param   PrmDIC_GOOD_MODEL2_ID : Modèle de produit à ...
  * @param   PrmFPL_SESSION_ID : Session oracle.
  */
  procedure LoadProductLevelTable(
    PrmFiltered                  integer
  , PrmGCO_GOOD_ID               GCO_GOOD.GCO_GOOD_ID%type
  , PrmGCO_GOOD_CATEGORY1_ID     GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID%type
  , PrmGCO_GOOD_CATEGORY2_ID     GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID%type
  , PrmDIC_GOOD_FAMILY1_ID       DIC_FAMILY.DIC_FAMILY_ID%type
  , PrmDIC_GOOD_FAMILY2_ID       DIC_FAMILY.DIC_FAMILY_ID%type
  , PrmDIC_ACCOUNTABLE_GROUP1_ID DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , PrmDIC_ACCOUNTABLE_GROUP2_ID DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , PrmDIC_GOOD_LINE1_ID         DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , PrmDIC_GOOD_LINE2_ID         DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , PrmDIC_GOOD_GROUP1_ID        DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , PrmDIC_GOOD_GROUP2_ID        DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , PrmDIC_GOOD_MODEL1_ID        DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  , PrmDIC_GOOD_MODEL2_ID        DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  , PrmFPL_SESSION_ID            FAl_PROD_LEVEL.FPL_SESSION_ID%type
  )
  is
    -- Lecture de tous les GCO_GOOD_ID de GCO_PRODUCT non composant et n'ayant pas de nomenclature associée
    cursor GetProductWithoutNomenclature(
      PrmGCO_GOOD_ID                GCO_GOOD.GCO_GOOD_ID%type
    , PrmGCO_GOOD_CATEGORY_WORDING1 GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
    , PrmGCO_GOOD_CATEGORY_WORDING2 GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
    , PrmDIC_GOOD_FAMILY1_ID        DIC_FAMILY.DIC_FAMILY_ID%type
    , PrmDIC_GOOD_FAMILY2_ID        DIC_FAMILY.DIC_FAMILY_ID%type
    , PrmDIC_ACCOUNTABLE_GROUP1_ID  DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
    , PrmDIC_ACCOUNTABLE_GROUP2_ID  DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
    , PrmDIC_GOOD_LINE1_ID          DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
    , PrmDIC_GOOD_LINE2_ID          DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
    , PrmDIC_GOOD_GROUP1_ID         DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
    , PrmDIC_GOOD_GROUP2_ID         DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
    , PrmDIC_GOOD_MODEL1_ID         DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
    , PrmDIC_GOOD_MODEL2_ID         DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
    , PrmFiltered                   integer
    )
    is
      select distinct GCO_PRODUCT.GCO_GOOD_ID
                 from GCO_PRODUCT
                    , GCO_GOOD
                    , GCO_GOOD_CATEGORY
                where GCO_PRODUCT.GCO_GOOD_ID = GCO_GOOD.GCO_GOOD_ID
                  and GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID = GCO_GOOD.GCO_GOOD_CATEGORY_ID
                  and (   PrmGCO_GOOD_ID is null
                       or (    PrmGCO_GOOD_ID is not null
                           and GCO_GOOD.GCO_GOOD_ID = PrmGCO_GOOD_ID) )
                  and (   PrmGCO_GOOD_CATEGORY_WORDING1 is null
                       or (    PrmGCO_GOOD_CATEGORY_WORDING1 is not null
                           and GCO_GOOD_CATEGORY_WORDING >= PrmGCO_GOOD_CATEGORY_WORDING1)
                      )
                  and (   PrmGCO_GOOD_CATEGORY_WORDING2 is null
                       or (    PrmGCO_GOOD_CATEGORY_WORDING2 is not null
                           and nvl(GCO_GOOD_CATEGORY_WORDING, PrmGCO_GOOD_CATEGORY_WORDING2) <= PrmGCO_GOOD_CATEGORY_WORDING2
                          )
                      )
                  and (   PrmDIC_GOOD_FAMILY1_ID is null
                       or (    PrmDIC_GOOD_FAMILY1_ID is not null
                           and GCO_GOOD.DIC_GOOD_FAMILY_ID >= PrmDIC_GOOD_FAMILY1_ID) )
                  and (   PrmDIC_GOOD_FAMILY2_ID is null
                       or (    PrmDIC_GOOD_FAMILY2_ID is not null
                           and nvl(GCO_GOOD.DIC_GOOD_FAMILY_ID, PrmDIC_GOOD_FAMILY2_ID) <= PrmDIC_GOOD_FAMILY2_ID)
                      )
                  and (   PrmDIC_ACCOUNTABLE_GROUP1_ID is null
                       or (    PrmDIC_ACCOUNTABLE_GROUP1_ID is not null
                           and GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID >= PrmDIC_ACCOUNTABLE_GROUP1_ID)
                      )
                  and (   PrmDIC_ACCOUNTABLE_GROUP2_ID is null
                       or (    PrmDIC_ACCOUNTABLE_GROUP2_ID is not null
                           and nvl(GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID, PrmDIC_ACCOUNTABLE_GROUP2_ID) <= PrmDIC_ACCOUNTABLE_GROUP2_ID
                          )
                      )
                  and (   PrmDIC_GOOD_LINE1_ID is null
                       or (    PrmDIC_GOOD_LINE1_ID is not null
                           and GCO_GOOD.DIC_GOOD_LINE_ID >= PrmDIC_GOOD_LINE1_ID) )
                  and (   PrmDIC_GOOD_LINE2_ID is null
                       or (    PrmDIC_GOOD_LINE2_ID is not null
                           and nvl(GCO_GOOD.DIC_GOOD_LINE_ID, PrmDIC_GOOD_LINE2_ID) <= PrmDIC_GOOD_LINE2_ID)
                      )
                  and (   PrmDIC_GOOD_GROUP1_ID is null
                       or (    PrmDIC_GOOD_GROUP1_ID is not null
                           and GCO_GOOD.DIC_GOOD_GROUP_ID >= PrmDIC_GOOD_GROUP1_ID) )
                  and (   PrmDIC_GOOD_GROUP2_ID is null
                       or (    PrmDIC_GOOD_GROUP2_ID is not null
                           and nvl(GCO_GOOD.DIC_GOOD_GROUP_ID, PrmDIC_GOOD_GROUP2_ID) <= PrmDIC_GOOD_GROUP2_ID)
                      )
                  and (   PrmDIC_GOOD_MODEL1_ID is null
                       or (    PrmDIC_GOOD_MODEL1_ID is not null
                           and GCO_GOOD.DIC_GOOD_MODEL_ID >= PrmDIC_GOOD_MODEL1_ID) )
                  and (   PrmDIC_GOOD_MODEL2_ID is null
                       or (    PrmDIC_GOOD_MODEL2_ID is not null
                           and nvl(GCO_GOOD.DIC_GOOD_MODEL_ID, PrmDIC_GOOD_MODEL2_ID) <= PrmDIC_GOOD_MODEL2_ID)
                      )
                  and PDT_STOCK_MANAGEMENT = 1
                  and PDT_CALC_REQUIREMENT_MNGMENT = 1
                  and GCO_GOOD.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                  and (   PrmFiltered = 1
                       or not exists(
                            select 1
                              from PPS_NOM_BOND a
                                 , PPS_NOMENCLATURE b
                                 , GCO_GOOD c
                                 , GCO_PRODUCT D
                             where a.GCO_GOOD_ID = GCO_PRODUCT.GCO_GOOD_ID
                               and b.GCO_GOOD_ID = c.GCo_GOOD_ID
                               and b.gco_good_id = d.gco_good_id
                               and a.PPS_NOMENCLATURE_ID = b.PPS_NOMENCLATURE_ID
                               and a.C_TYPE_COM = '1'
                               and a.C_KIND_COM <> '5'
                               and b.C_TYPE_NOM in('2', '3', '4', '6')
                               and c.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                               and D.PDT_CALC_REQUIREMENT_MNGMENT = 1)
                      )
                  and not exists(select 1
                                   from PPS_NOMENCLATURE
                                  where PPS_NOMENCLATURE.GCO_GOOD_ID = GCO_PRODUCT.GCO_GOOD_ID);

    -- Lecture de tous les GCO_GOOD_ID de GCO_PRODUCT non composant et n'ayant au moins une nomenclature associée -----------
    cursor GetProductWithNomenclature(
      PrmGCO_GOOD_ID                GCO_GOOD.GCO_GOOD_ID%type
    , PrmGCO_GOOD_CATEGORY_WORDING1 GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
    , PrmGCO_GOOD_CATEGORY_WORDING2 GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
    , PrmDIC_GOOD_FAMILY1_ID        DIC_FAMILY.DIC_FAMILY_ID%type
    , PrmDIC_GOOD_FAMILY2_ID        DIC_FAMILY.DIC_FAMILY_ID%type
    , PrmDIC_ACCOUNTABLE_GROUP1_ID  DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
    , PrmDIC_ACCOUNTABLE_GROUP2_ID  DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
    , PrmDIC_GOOD_LINE1_ID          DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
    , PrmDIC_GOOD_LINE2_ID          DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
    , PrmDIC_GOOD_GROUP1_ID         DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
    , PrmDIC_GOOD_GROUP2_ID         DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
    , PrmDIC_GOOD_MODEL1_ID         DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
    , PrmDIC_GOOD_MODEL2_ID         DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
    , PrmFiltered                   integer
    )
    is
      select distinct GCO_PRODUCT.GCO_GOOD_ID
                 from GCO_PRODUCT
                    , GCO_GOOD
                    , GCO_GOOD_CATEGORY
                where GCO_PRODUCT.GCO_GOOD_ID = GCO_GOOD.GCO_GOOD_ID
                  and GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID = GCO_GOOD.GCO_GOOD_CATEGORY_ID
                  and (   PrmGCO_GOOD_ID is null
                       or (    PrmGCO_GOOD_ID is not null
                           and GCO_GOOD.GCO_GOOD_ID = PrmGCO_GOOD_ID) )
                  and (   PrmGCO_GOOD_CATEGORY_WORDING1 is null
                       or (    PrmGCO_GOOD_CATEGORY_WORDING1 is not null
                           and GCO_GOOD_CATEGORY_WORDING >= PrmGCO_GOOD_CATEGORY_WORDING1)
                      )
                  and (   PrmGCO_GOOD_CATEGORY_WORDING2 is null
                       or (    PrmGCO_GOOD_CATEGORY_WORDING2 is not null
                           and nvl(GCO_GOOD_CATEGORY_WORDING, PrmGCO_GOOD_CATEGORY_WORDING2) <= PrmGCO_GOOD_CATEGORY_WORDING2
                          )
                      )
                  and (   PrmDIC_GOOD_FAMILY1_ID is null
                       or (    PrmDIC_GOOD_FAMILY1_ID is not null
                           and GCO_GOOD.DIC_GOOD_FAMILY_ID >= PrmDIC_GOOD_FAMILY1_ID) )
                  and (   PrmDIC_GOOD_FAMILY2_ID is null
                       or (    PrmDIC_GOOD_FAMILY2_ID is not null
                           and nvl(GCO_GOOD.DIC_GOOD_FAMILY_ID, PrmDIC_GOOD_FAMILY2_ID) <= PrmDIC_GOOD_FAMILY2_ID)
                      )
                  and (   PrmDIC_ACCOUNTABLE_GROUP1_ID is null
                       or (    PrmDIC_ACCOUNTABLE_GROUP1_ID is not null
                           and GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID >= PrmDIC_ACCOUNTABLE_GROUP1_ID)
                      )
                  and (   PrmDIC_ACCOUNTABLE_GROUP2_ID is null
                       or (    PrmDIC_ACCOUNTABLE_GROUP2_ID is not null
                           and nvl(GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID, PrmDIC_ACCOUNTABLE_GROUP2_ID) <= PrmDIC_ACCOUNTABLE_GROUP2_ID
                          )
                      )
                  and (   PrmDIC_GOOD_LINE1_ID is null
                       or (    PrmDIC_GOOD_LINE1_ID is not null
                           and GCO_GOOD.DIC_GOOD_LINE_ID >= PrmDIC_GOOD_LINE1_ID) )
                  and (   PrmDIC_GOOD_LINE2_ID is null
                       or (    PrmDIC_GOOD_LINE2_ID is not null
                           and nvl(GCO_GOOD.DIC_GOOD_LINE_ID, PrmDIC_GOOD_LINE2_ID) <= PrmDIC_GOOD_LINE2_ID)
                      )
                  and (   PrmDIC_GOOD_GROUP1_ID is null
                       or (    PrmDIC_GOOD_GROUP1_ID is not null
                           and GCO_GOOD.DIC_GOOD_GROUP_ID >= PrmDIC_GOOD_GROUP1_ID) )
                  and (   PrmDIC_GOOD_GROUP2_ID is null
                       or (    PrmDIC_GOOD_GROUP2_ID is not null
                           and nvl(GCO_GOOD.DIC_GOOD_GROUP_ID, PrmDIC_GOOD_GROUP2_ID) <= PrmDIC_GOOD_GROUP2_ID)
                      )
                  and (   PrmDIC_GOOD_MODEL1_ID is null
                       or (    PrmDIC_GOOD_MODEL1_ID is not null
                           and GCO_GOOD.DIC_GOOD_MODEL_ID >= PrmDIC_GOOD_MODEL1_ID) )
                  and (   PrmDIC_GOOD_MODEL2_ID is null
                       or (    PrmDIC_GOOD_MODEL2_ID is not null
                           and nvl(GCO_GOOD.DIC_GOOD_MODEL_ID, PrmDIC_GOOD_MODEL2_ID) <= PrmDIC_GOOD_MODEL2_ID)
                      )
                  and PDT_CALC_REQUIREMENT_MNGMENT = 1
                  and GCO_GOOD.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                  and (   PrmFiltered = 1
                       or not exists(
                            select 1
                              from PPS_NOM_BOND a
                                 , PPS_NOMENCLATURE b
                                 , GCO_GOOD c
                                 , GCO_PRODUCT D
                             where a.GCO_GOOD_ID = GCO_PRODUCT.GCO_GOOD_ID
                               and b.GCO_GOOD_ID = c.GCo_GOOD_ID
                               and b.gco_good_id = d.gco_good_id
                               and a.PPS_NOMENCLATURE_ID = b.PPS_NOMENCLATURE_ID
                               and a.C_TYPE_COM = '1'
                               and a.C_KIND_COM <> '5'
                               and b.C_TYPE_NOM in('2', '3', '4', '6')
                               and c.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                               and d.PDT_CALC_REQUIREMENT_MNGMENT = 1)
                      )
                  and exists(select 1
                               from PPS_NOMENCLATURE
                              where PPS_NOMENCLATURE.GCO_GOOD_ID = GCO_PRODUCT.GCO_GOOD_ID);

    -- Compteur N
    aCompteurN                    integer;
    aContinueLoop                 boolean;
    BuffError                     varchar(2000);
    PrmGCO_GOOD_CATEGORY_WORDING1 GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type;
    PrmGCO_GOOD_CATEGORY_WORDING2 GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type;
    aLastProcessedGoodID          number;
  begin
    if not ControleDonneeCompDeFab then
      BuffError  := PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Données Complémentaires invalide !');
      raise_application_error(-20002, BUffError);
    end if;

    -- Vider la table FAL_PROD_LEVEL
    if PrmFiltered = 1 then
      delete from FAL_PROD_LEVEL
            where FAL_PROD_LEVEL_ID < 0;
    else
      delete from FAL_PROD_LEVEL;
    end if;

    -- Initialiser le compteur N
    aCompteurN                     := 0;
    -- Récupérer les wording des categories
    PrmGCO_GOOD_CATEGORY_WORDING1  := null;
    PrmGCO_GOOD_CATEGORY_WORDING2  := null;

    if PrmGCO_GOOD_CATEGORY1_ID is not null then
      select GCO_GOOD_CATEGORY_WORDING
        into PrmGCO_GOOD_CATEGORY_WORDING1
        from GCO_GOOD_CATEGORY
       where GCO_GOOD_CATEGORY_ID = PrmGCO_GOOD_CATEGORY1_ID;
    end if;

    if PrmGCO_GOOD_CATEGORY2_ID is not null then
      select GCO_GOOD_CATEGORY_WORDING
        into PrmGCO_GOOD_CATEGORY_WORDING2
        from GCO_GOOD_CATEGORY
       where GCO_GOOD_CATEGORY_ID = PrmGCO_GOOD_CATEGORY2_ID;
    end if;

    -- Fin de Récupérer les wording des categories

    -- Traitement des produits non composant et sans nomenclature
    for aProduct in GetProductWithoutNomenclature(PrmGCO_GOOD_ID
                                                , PrmGCO_GOOD_CATEGORY_WORDING1
                                                , PrmGCO_GOOD_CATEGORY_WORDING2
                                                , PrmDIC_GOOD_FAMILY1_ID
                                                , PrmDIC_GOOD_FAMILY2_ID
                                                , PrmDIC_ACCOUNTABLE_GROUP1_ID
                                                , PrmDIC_ACCOUNTABLE_GROUP2_ID
                                                , PrmDIC_GOOD_LINE1_ID
                                                , PrmDIC_GOOD_LINE2_ID
                                                , PrmDIC_GOOD_GROUP1_ID
                                                , PrmDIC_GOOD_GROUP2_ID
                                                , PrmDIC_GOOD_MODEL1_ID
                                                , PrmDIC_GOOD_MODEL2_ID
                                                , PrmFiltered
                                                 ) loop
      -- Ajouter l'élement dans la table FAL_PROD_LEVEL
      InsertRowInFAL_PROD_LEVEL(aProduct.GCO_GOOD_ID, aCompteurN, PrmFiltered, PrmFPL_SESSION_ID);   -- DJ-19991207-0257
    end loop;

    -- Initialiser le compteur N
    aCompteurN                     := 1;

    -- Traitement des produits non composant et avec nomenclature
    for aProduct in GetProductWithNomenclature(PrmGCO_GOOD_ID
                                             , PrmGCO_GOOD_CATEGORY_WORDING1
                                             , PrmGCO_GOOD_CATEGORY_WORDING2
                                             , PrmDIC_GOOD_FAMILY1_ID
                                             , PrmDIC_GOOD_FAMILY2_ID
                                             , PrmDIC_ACCOUNTABLE_GROUP1_ID
                                             , PrmDIC_ACCOUNTABLE_GROUP2_ID
                                             , PrmDIC_GOOD_LINE1_ID
                                             , PrmDIC_GOOD_LINE2_ID
                                             , PrmDIC_GOOD_GROUP1_ID
                                             , PrmDIC_GOOD_GROUP2_ID
                                             , PrmDIC_GOOD_MODEL1_ID
                                             , PrmDIC_GOOD_MODEL2_ID
                                             , PrmFiltered
                                              ) loop
      -- Ajouter l'élement dans la table FAL_PROD_LEVEL
      InsertRowInFAL_PROD_LEVEL(aProduct.GCO_GOOD_ID, aCompteurN, PrmFiltered, PrmFPL_SESSION_ID);
    end loop;

    -- Parcourir les niveaux
    aContinueLoop                  := true;

    while(aContinueLoop) loop
      -- Traiter les produits de niveau aCompteurN
      aContinueLoop  := LoadProductLevelTableByLevel(aCompteurN, PrmFiltered, PrmFPL_SESSION_ID, aLastProcessedGoodID);
      -- Incrémenter le niveau
      aCompteurN     := aCompteurN + 1;

      if aCompteurN > PCS.PC_CONFIG.GetCONFIG('FAL_CB_MAX_NOMENCLATURE_LEVEL') then
        BuffError  :=
          PCS.PC_FUNCTIONS.TRANSLATEWORD('Erreur lors de la mise à jour de la table des niveaux! Les causes probables à vérifier sont :') ||
          chr(13) ||
          chr(10) ||
          PCS.PC_FUNCTIONS.TRANSLATEWORD('1) Une configuration de niveau de nomenclature maximum trop basse. (Configuration FAL_CB_MAX_NOMENCLATURE_LEVEL)') ||
          chr(13) ||
          chr(10) ||
          PCS.PC_FUNCTIONS.TRANSLATEWORD('2) Des nomenclatures comportant des références circulaires.') ||
          chr(13) ||
          chr(10) ||
          PCS.PC_FUNCTIONS.TRANSLATEWORD('Dernière nomenclature traitée, produit : ') ||
          FAL_TOOLS.GetGOO_MAJOR_REFERENCE(aLastProcessedGoodID);
        raise_application_error(-20001, BuffError);
      end if;
    end loop;

    -- On ne traite ensuite dans le CB que les produits de mode d'appro 1 et 2
    delete from fal_prod_level
          where gco_good_id in(select gco_good_id
                                 from gco_product
                                where c_supply_mode not in('1', '2', '4') );
  exception
    when UNKNOWN_LevelTooHight then
      raise;
    when ERROR_ON_GCO_COMPL_DATA then
      raise;
  end;
end;
