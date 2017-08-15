--------------------------------------------------------
--  DDL for Package Body GCO_LIB_ALLOY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_LIB_ALLOY" 
is
  gIsPreciousMat number(1);

  /**
  * Description
  *    Retourne 1 si on a au moins une mati�re pr�cieuse
  */
  function IsPreciousMat
    return number deterministic
  is
  begin
    return gIsPreciousMat;
  end IsPreciousMat;

  /**
  * Description
  *    Retourne la r�f�rence de l'alliage
  */
  function GetAlloyRef(iAlloyId in GCO_ALLOY.GCO_ALLOY_ID%type)
    return GCO_ALLOY.GAL_ALLOY_REF%type
  is
    lResult GCO_ALLOY.GAL_ALLOY_REF%type;
  begin
    select GAL_ALLOY_REF
      into lResult
      from GCO_ALLOY
     where GCO_ALLOY_ID = iAlloyId;

    return lResult;
  end GetAlloyRef;

  /**
  * Description
  *    Retourne l'identifiant de l'alliage en fonction de la r�f�rence
  */
  function GetAlloyID(iAlloyRef in GCO_ALLOY.GAL_ALLOY_REF%type)
    return GCO_ALLOY.GCO_ALLOY_ID%type
  is
    lcResult GCO_ALLOY.GCO_ALLOY_ID%type;
  begin
    select max(GCO_ALLOY_ID)
      into lcResult
      from GCO_ALLOY
     where GAL_ALLOY_REF = iAlloyRef;

    return lcResult;
  end GetAlloyID;

  /**
  * Description
  *   d�termine si le bien est une mati�re pr�cieuse (compos� � 100% de la m�me mati�re)
  */
  function IsGoodPurePrecMat(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult number(1);
  begin
    -- recherche un composant d'aliage � 100% (si plusiquers composants ou aucun -> exception, le bien n'est pas une mati�re pr�cieuse)
    select decode(GAC_RATE, 100, 1, 0)
      into lResult
      from GCO_ALLOY ALO
         , GCO_ALLOY_COMPONENT GAC
     where ALO.GCO_GOOD_ID = iGoodId
       and GAC.GCO_ALLOY_ID = ALO.GCO_ALLOY_ID;

    return lResult;
  exception
    when no_data_found then
      return 0;
    when too_many_rows then
      return 0;
  end IsGoodPurePrecMat;

  /**
  * function IsGoodLinkedToAlloy
  * Description
  *   d�termine si le bien est Produit li� � un alliage (compos� � 100% de la m�me mati�re ou pas)
  * @created fp 13.02.2012
  * @lastUpdate
  * @public
  * @param iGoodID : bien � tester
  * @return 0 ou 1
  */
  function IsGoodLinkedToAlloy(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult number(1);
  begin
    -- recherche un composant d'aliage � 100% (si plusiquers composants ou aucun -> exception, le bien n'est pas une mati�re pr�cieuse)
    select 1
      into lResult
      from GCO_ALLOY ALO
     where ALO.GCO_GOOD_ID = iGoodId;

    return lResult;
  exception
    when no_data_found then
      return 0;
    when too_many_rows then
      return 1;
  end IsGoodLinkedToAlloy;

  /**
  * Description
  *   d�termine si le bien est compos� de mati�res pr�cieuses
  */
  function IsGoodPreciousMat(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult number(1);
  begin
    -- recherche si le bien est compos� de  mati�res pr�cieuses
    select nvl(GOO_PRECIOUS_MAT,0)
      into lResult
      from GCO_GOOD GOO
     where GOO.GCO_GOOD_ID = iGoodId;

    return lResult;
  exception
    when no_data_found then
      return 0;
  end IsGoodPreciousMat;

  /**
  * Description
  *    Poids alliage initial
  */
  function GetAlloyInitialWeight(
    iAlloyId  in GCO_ALLOY.GCO_ALLOY_ID%type
  , iGoodId   in PPS_INTERROGATION.GCO_GOOD_ID%type
  , iCoefUtil in PPS_INTERROGATION.COM_UTIL_COEFF%type
  , iRefQty   in PPS_INTERROGATION.COM_REF_QTY%type
  )
    return GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type
  is
    lResult GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type;
  begin
    select GPM.GPM_WEIGHT_DELIVER * iCoefUtil / iRefQty
      into lResult
      from GCO_PRECIOUS_MAT GPM, GCO_GOOD GOO
     where GPM.GCO_GOOD_ID = iGoodId
       and GOO.GCO_GOOD_ID = GPM.GCO_GOOD_ID
       and GOO.GOO_PRECIOUS_MAT = 1
       and GPM.GCO_ALLOY_ID = iAlloyId;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetAlloyInitialWeight;

  /**
  * Description
  *    Poids alliage nouveau
  */
  function GetAlloyNewWeight(
    iAlloyId  in GCO_ALLOY.GCO_ALLOY_ID%type
  , iGoodId   in PPS_INTERROGATION.GCO_GOOD_ID%type
  , iCoefUtil in PPS_INTERROGATION.COM_UTIL_COEFF%type
  , iRefQty   in PPS_INTERROGATION.COM_REF_QTY%type
  )
    return GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type
  is
    lResult GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type;
  begin
    select GPM_WEIGHT_DELIVER * iCoefUtil / iRefQty
      into lResult
      from PPS_INTERRO_ALLOY
     where GCO_GOOD_ID = iGoodId
       and GCO_ALLOY_ID = iAlloyId
       and C_GPM_UPDATE_TYPE <> PPS_I_LIB_INTERRO.cGpmUpdateTypeDelete;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetAlloyNewWeight;

  /**
  * Description
  *    Poids produit initial
  */
  function GetProductInitialWeight(
    iGoodId   in PPS_INTERROGATION.GCO_GOOD_ID%type
  , iCoefUtil in PPS_INTERROGATION.COM_UTIL_COEFF%type
  , iRefQty   in PPS_INTERROGATION.COM_REF_QTY%type
  )
    return GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type
  is
    lResult GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type;
  begin
    select sum(GPM.GPM_WEIGHT_DELIVER * iCoefUtil / iRefQty)
      into lResult
      from GCO_PRECIOUS_MAT GPM, GCO_GOOD GOO
     where GPM.GCO_GOOD_ID = iGoodId
       and GOO.GCO_GOOD_ID = GPM.GCO_GOOD_ID
       and GOO.GOO_PRECIOUS_MAT = 1;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetProductInitialWeight;

  /**
  * Description
  *    Poids produit nouveau
  */
  function GetProductNewWeight(
    iGoodId   in PPS_INTERROGATION.GCO_GOOD_ID%type
  , iCoefUtil in PPS_INTERROGATION.COM_UTIL_COEFF%type
  , iRefQty   in PPS_INTERROGATION.COM_REF_QTY%type
  )
    return GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type
  is
    lResult GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type;
  begin
    select sum(GPM_WEIGHT_DELIVER * iCoefUtil / iRefQty)
      into lResult
      from PPS_INTERRO_ALLOY
     where GCO_GOOD_ID = iGoodId
       and C_GPM_UPDATE_TYPE <> PPS_I_LIB_INTERRO.cGpmUpdateTypeDelete;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetProductNewWeight;

  /**
  * Description
  *    Poids moyen des pes�es en r�ception de lots
  */
  function GetAlloyBatchReceiptWeight(
    iAlloyId   in GCO_ALLOY.GCO_ALLOY_ID%type
  , iGoodId    in PPS_INTERROGATION.GCO_GOOD_ID%type
  , iCoefUtil  in PPS_INTERROGATION.COM_UTIL_COEFF%type
  , iRefQty    in PPS_INTERROGATION.COM_REF_QTY%type
  , iBeginDate in date
  )
    return FAL_WEIGH.FWE_WEIGHT%type
  is
    lResult FAL_WEIGH.FWE_WEIGHT%type;
  begin
    select sum(FWE_WEIGHT) / sum(FWE_PIECE_QTY) * iCoefUtil / iRefQty
      into lResult
      from FAL_WEIGH
     where GCO_GOOD_ID = iGoodId
       and GCO_ALLOY_ID = iAlloyId
       and FWE_DATE >= nvl(iBeginDate, FWE_DATE)
       and FWE_WASTE = 0
       and FWE_TURNINGS = 0
       and FWE_PIECE_QTY > 0
       and C_WEIGH_TYPE = '4';

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetAlloyBatchReceiptWeight;

  /**
  * Description
  *    Poids moyen des pes�es en mouvements mati�re
  */
  function GetAlloyMatMvtWeight(
    iAlloyId   in GCO_ALLOY.GCO_ALLOY_ID%type
  , iGoodId    in PPS_INTERROGATION.GCO_GOOD_ID%type
  , iCoefUtil  in PPS_INTERROGATION.COM_UTIL_COEFF%type
  , iRefQty    in PPS_INTERROGATION.COM_REF_QTY%type
  , iBeginDate in date
  )
    return FAL_WEIGH.FWE_WEIGHT%type
  is
    lResult FAL_WEIGH.FWE_WEIGHT%type;
  begin
    select sum(FWE_WEIGHT) / sum(FWE_PIECE_QTY) * iCoefUtil / iRefQty
      into lResult
      from FAL_WEIGH
     where GCO_GOOD_ID = iGoodId
       and GCO_ALLOY_ID = iAlloyId
       and FWE_DATE >= nvl(iBeginDate, FWE_DATE)
       and FWE_WASTE = 0
       and FWE_TURNINGS = 0
       and FWE_PIECE_QTY > 0
       and C_WEIGH_TYPE = '3';

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetAlloyMatMvtWeight;

  /**
  * Description
  *    Poids moyen des pes�es en mouvements composants
  */
  function GetAlloyCptMvtWeight(
    iAlloyId   in GCO_ALLOY.GCO_ALLOY_ID%type
  , iGoodId    in PPS_INTERROGATION.GCO_GOOD_ID%type
  , iCoefUtil  in PPS_INTERROGATION.COM_UTIL_COEFF%type
  , iRefQty    in PPS_INTERROGATION.COM_REF_QTY%type
  , iBeginDate in date
  )
    return FAL_WEIGH.FWE_WEIGHT%type
  is
    lResult FAL_WEIGH.FWE_WEIGHT%type;
  begin
    select sum(FWE_WEIGHT) / sum(FWE_PIECE_QTY) * iCoefUtil / iRefQty
      into lResult
      from FAL_WEIGH
     where GCO_GOOD_ID = iGoodId
       and GCO_ALLOY_ID = iAlloyId
       and FWE_DATE >= nvl(iBeginDate, FWE_DATE)
       and FWE_WASTE = 0
       and FWE_TURNINGS = 0
       and FWE_PIECE_QTY > 0
       and C_WEIGH_TYPE in('6', '7', '8', '9', '10');

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetAlloyCptMvtWeight;

  /**
  * function IsStoneManagement
  * Description
  *   Alliage avec pierres pr�cieuses
  * @created fp 22.03.2012
  * @lastUpdate
  * @public
  * @param iAlloyId : alliage � tester
  * @return 0 ou 1
  */
  function IsStoneManagement(iAlloyId in GCO_ALLOY.GCO_ALLOY_ID%type)
    return number
  is
    lResult number(1);
  begin
    select GAL_STONE
      into lResult
      from GCO_ALLOY
     where GCO_ALLOY_ID = iAlloyId;

    return lResult;
  end IsStoneManagement;

  /**
  * Description
  *   Retourne le temps de recyclage interne dse copeaux de l'alliage transmis en param�tre.
  */
  function getChipInternalRecyclingTime(inGcoAlloyID in GCO_ALLOY.GCO_ALLOY_ID%type)
    return GCO_ALLOY.GAL_CHIP_INT_RECYCLING_TIME%type
  as
    lnGalChipIntRecyclingTime GCO_ALLOY.GAL_CHIP_INT_RECYCLING_TIME%type;
  begin
    select nvl(GAL_CHIP_INT_RECYCLING_TIME, 0)
      into lnGalChipIntRecyclingTime
      from GCO_ALLOY
     where GCO_ALLOY_ID = inGcoAlloyID;

    return lnGalChipIntRecyclingTime;
  end getChipInternalRecyclingTime;

  /**
  * Description
  *   Retourne le temps de recyclage externe dse copeaux de l'alliage transmis en param�tre.
  */
  function getChipExternalRecyclingTime(inGcoAlloyID in GCO_ALLOY.GCO_ALLOY_ID%type)
    return GCO_ALLOY.GAL_CHIP_EXT_RECYCLING_TIME%type
  as
    lnGalChipExtRecyclingTime GCO_ALLOY.GAL_CHIP_EXT_RECYCLING_TIME%type;
  begin
    select nvl(GAL_CHIP_EXT_RECYCLING_TIME, 0)
      into lnGalChipExtRecyclingTime
      from GCO_ALLOY
     where GCO_ALLOY_ID = inGcoAlloyID;

    return lnGalChipExtRecyclingTime;
  end getChipExternalRecyclingTime;

  /**
  * Description
  *   Retourne l'ID de l'alliage g�n�rique de la soci�t�. Si pas trouv�, retourne
  *   null
  */
  function getGenericAlloy
    return GCO_ALLOY.GCO_ALLOY_ID%type
  as
    lnGcoAlloyID GCO_ALLOY.GCO_ALLOY_ID%type;
  begin
    select GCO_ALLOY_ID
      into lnGcoAlloyID
      from GCO_ALLOY
     where GAL_GENERIC = 1;

    return lnGcoAlloyID;
  exception
    when no_data_found then
      return null;
  end getGenericAlloy;

  /**
  * Description
  *   retourne 1 si le bien poss�de une nomenclature de production par d�faut
  */
  function HasProdNomenclature(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
  begin
    if PPS_I_LIB_FUNCTIONS.GetDefaultNomenclature(iGoodId, PPS_I_LIB_FUNCTIONS.cTypeNomProd) is not null then
      return 1;
    else
      return 0;
    end if;
  end HasProdNomenclature;

begin
  select sign(count(*) )
    into gIsPreciousMat
    from GCO_PRECIOUS_MAT;
end GCO_LIB_ALLOY;
