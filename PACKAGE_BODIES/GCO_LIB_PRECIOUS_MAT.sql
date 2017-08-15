--------------------------------------------------------
--  DDL for Package Body GCO_LIB_PRECIOUS_MAT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_LIB_PRECIOUS_MAT" 
is
  gIsPreciousMat number(1);

  /**
  * Description
  *    Retourne 1 si on a au moins une matière précieuse
  */
  function IsPreciousMat
    return number deterministic
  is
  begin
    return gIsPreciousMat;
  end IsPreciousMat;

  /**
  * Description
  *    Cette function retourne 1 si le bien transmis en paramètre gère les
  *    matières précieuses. Sinon retourne 0
  */
  function doesManagePreciousMat(inGcoGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.GOO_PRECIOUS_MAT%type
  as
    lnManagePreciousMat GCO_GOOD.GOO_PRECIOUS_MAT%type   := 0;
  begin
    select nvl(GOO_PRECIOUS_MAT, 0)
      into lnManagePreciousMat
      from GCO_GOOD
     where GCO_GOOD_ID = inGcoGoodID;

    return lnManagePreciousMat;
  exception
    when no_data_found then
      return 0;
  end doesManagePreciousMat;

  /**
  * Description
  *    Cette function retourne 1 si le bien transmis en paramètre est composé
  *    d'au moins un alliage. Sinon retourne 0
  */
  function doesContainsPreciousMat(inGcoGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.GOO_PRECIOUS_MAT%type
  as
    lnContainsPreciousMat number;
  begin
    select sign(count(GCO_ALLOY_ID) )
      into lnContainsPreciousMat
      from GCO_PRECIOUS_MAT
     where GCO_GOOD_ID = inGcoGoodID;

    return lnContainsPreciousMat;
  exception
    when no_data_found then
      return 0;
  end doesContainsPreciousMat;

  /**
  * Description
  *    Retourne 1 si le bien transmis en paramètre contient au moins un alliage
  *    de type pierre.
  */
  function doesContainsStoneAlloy(inGcoGoodID in GCO_PRECIOUS_MAT.GCO_GOOD_ID%type)
    return number
  as
    lnDoesContainsStoneAlloy number(1) := 0;
  begin
    select sign(sum(nvl(gal.GAL_STONE, 0) ) )
      into lnDoesContainsStoneAlloy
      from GCO_PRECIOUS_MAT gpm
         , GCO_ALLOY gal
     where gal.GCO_ALLOY_ID = gpm.GCO_ALLOY_ID
       and gpm.GCO_GOOD_ID = inGcoGoodID;

    return lnDoesContainsStoneAlloy;
  exception
    when no_data_found then
      return 0;
  end doesContainsStoneAlloy;

  /**
  * Description
  *    Retourne 1 si le bien transmis en paramètre contient au moins un alliage
  *    avec pesée réelle.
  */
  function doesContainsRealWeighedAlloy(inGcoGoodID in GCO_PRECIOUS_MAT.GCO_GOOD_ID%type)
    return number
  as
    lnDoesContainsRealWeighedAlloy number(1) := 0;
  begin
    select sign(count(GCO_ALLOY_ID) )
      into lnDoesContainsRealWeighedAlloy
      from GCO_PRECIOUS_MAT gpm
     where gpm.GCO_GOOD_ID = inGcoGoodID
       and gpm.GPM_WEIGHT = 1
       and gpm.GPM_REAL_WEIGHT = 1;

    return lnDoesContainsRealWeighedAlloy;
  exception
    when no_data_found then
      return 0;
  end doesContainsRealWeighedAlloy;

  /**
  * Description
  *    Cette function retourne 1 si un alliage avec une pesée réelle ou théorique
  *    est défini sur le bien dont la clef primaire est transmise en paramètre;
  *    Sinon retourne 0
  */
  function hasPreciousMatWithWeight(iGcoGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lnHasPreciousMatWithWeight number(1) := 0;
  begin
    select sign(count(*) )
      into lnHasPreciousMatWithWeight
      from GCO_GOOD GOO
         , GCO_PRECIOUS_MAT GPM
     where GOO.GCO_GOOD_ID = iGcoGoodID
       and GPM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
       and GOO.GOO_PRECIOUS_MAT = 1
       and (   GPM.GPM_REAL_WEIGHT = 1
            or GPM_THEORICAL_WEIGHT = 1);

    return lnHasPreciousMatWithWeight;
  end hasPreciousMatWithWeight;

  /**
  * Description
  *    Cette function retourne 1 si un alliage avec une pesée réelle
  *    est défini sur le bien dont la clef primaire est transmise en paramètre;
  *    Sinon retourne 0
  */
  function hasPreciousMatWithRealWeight(iGcoGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lnHasPreciousMatWithRealWeight number(1) := 0;
  begin
    select sign(count(*) )
      into lnHasPreciousMatWithRealWeight
      from GCO_GOOD GOO
         , GCO_PRECIOUS_MAT GPM
     where GOO.GCO_GOOD_ID = iGcoGoodID
       and GPM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
       and GOO.GOO_PRECIOUS_MAT = 1
       and GPM.GPM_WEIGHT = 1
       and GPM.GPM_REAL_WEIGHT = 1;

    return lnHasPreciousMatWithRealWeight;
  end hasPreciousMatWithRealWeight;

  /**
  * Description
  *   retourne 0 si les données complémentaires d'achat du fournisseur par défaut
  *   indiquent qu'on ne valorise pas la matière précieuse du bien
  */
  function HasPreciousMatValorisation(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lCpuNoValorization GCO_COMPL_DATA_PURCHASE.CPU_PRECIOUS_MAT_VALUE%type;
  begin
    -- !!!!! en fait le champ indique si on ne valorise pas (l'inverse de ce que le nom de champ indique)
    select nvl(CPU.CPU_PRECIOUS_MAT_VALUE, 1)
      into lCpuNoValorization
      from GCO_COMPL_DATA_PURCHASE CPU
         , GCO_PRODUCT PDT
     where CPU.GCO_GOOD_ID = iGoodId
       and PDT.GCO_GOOD_ID = CPU.GCO_GOOD_ID
       and PDT.C_SUPPLY_MODE = '1'
       and CPU.CPU_DEFAULT_SUPPLIER = 1;

    if lCpuNoValorization = 1 then
      return 0;
    else
      return 1;
    end if;
  exception
    when no_data_found then
      return 1;
  end HasPreciousMatValorisation;

  /**
  * Description
  *    Cette function retourne 1 si le bien dont la clef primaire est transmise
  *    en paramètre contient l'alliage dont la clef primaire est tramsise en paramètre
  *    et qu'il est prévu en pesée réelle.
  */
  function goodContainsRealWeightAlloy(inGcoGoodID in GCO_PRECIOUS_MAT.GCO_GOOD_ID%type, inGcoAlloyID in GCO_ALLOY.GCO_ALLOY_ID%type)
    return number
  as
    lnContainsAlloy number;
  begin
    select sign(GCO_GOOD_ID)
      into lnContainsAlloy
      from GCO_PRECIOUS_MAT
     where GCO_GOOD_ID = inGcoGoodID
       and GCO_ALLOY_ID = inGcoAlloyID
       and GPM_WEIGHT = 1
       and GPM_REAL_WEIGHT = 1;

    return lnContainsAlloy;
  exception
    when no_data_found then
      return 0;
  end goodContainsRealWeightAlloy;

  /**
  * Description
  *    Recherche l'id d'une matière précieuse en fonction du bien et de l'alliage
  */
  function GetPreciousMatId(iGoodId in GCO_PRECIOUS_MAT.GCO_GOOD_ID%type, iAlloyId GCO_PRECIOUS_MAT.GCO_ALLOY_ID%type)
    return GCO_PRECIOUS_MAT.GCO_PRECIOUS_MAT_ID%type
  is
    lResult GCO_PRECIOUS_MAT.GCO_PRECIOUS_MAT_ID%type;
  begin
    select GCO_PRECIOUS_MAT_ID
      into lResult
      from GCO_PRECIOUS_MAT
     where GCO_GOOD_ID = iGoodId
       and GCO_ALLOY_ID = iAlloyId;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetPreciousMatId;

  /**
  * Description
  *    Retourne le poids total investi de l'alliage dans le produit transmis en
  *    paramètre.
  */
  function getWeightInvest(inGcoGoodID in GCO_PRECIOUS_MAT.GCO_GOOD_ID%type, inGcoAlloyID in GCO_PRECIOUS_MAT.GCO_ALLOY_ID%type)
    return GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST%type
  as
    lnResult GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST%type;
  begin
    select nvl(GPM_WEIGHT_INVEST, 0)
      into lnResult
      from GCO_PRECIOUS_MAT
     where GCO_GOOD_ID = inGcoGoodID
       and GCO_ALLOY_ID = inGcoAlloyID;

    return lnResult;
  exception
    when no_data_found then
      return 0;
  end getWeightInvest;

  /**
  * Description
  *    Retourne le poids copeaux théorique total de l'alliage dans le produit
  *    transmis en paramètre.
  */
  function getWeightChip(inGcoGoodID in GCO_PRECIOUS_MAT.GCO_GOOD_ID%type, inGcoAlloyID in GCO_PRECIOUS_MAT.GCO_ALLOY_ID%type)
    return GCO_PRECIOUS_MAT.GPM_WEIGHT_CHIP%type
  as
    lnResult GCO_PRECIOUS_MAT.GPM_WEIGHT_CHIP%type;
  begin
    select nvl(GPM_WEIGHT_CHIP, 0)
      into lnResult
      from GCO_PRECIOUS_MAT
     where GCO_GOOD_ID = inGcoGoodID
       and GCO_ALLOY_ID = inGcoAlloyID;

    return lnResult;
  exception
    when no_data_found then
      return 0;
  end getWeightChip;

  /**
  * Description
  *    Retourne le poids livré théorique de l'alliage dans le produit transmis en
  *    paramètre.
  */
  function getWeightDeliver(inGcoGoodID in GCO_PRECIOUS_MAT.GCO_GOOD_ID%type, inGcoAlloyID in GCO_PRECIOUS_MAT.GCO_ALLOY_ID%type)
    return GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type
  as
    lnResult GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type;
  begin
    select nvl(GPM_WEIGHT_DELIVER, 0)
      into lnResult
      from GCO_PRECIOUS_MAT
     where GCO_GOOD_ID = inGcoGoodID
       and GCO_ALLOY_ID = inGcoAlloyID;

    return lnResult;
  exception
    when no_data_found then
      return 0;
  end getWeightDeliver;
begin
  select sign(count(*) )
    into gIsPreciousMat
    from GCO_PRECIOUS_MAT;
end GCO_LIB_PRECIOUS_MAT;
