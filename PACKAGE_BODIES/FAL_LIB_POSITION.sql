--------------------------------------------------------
--  DDL for Package Body FAL_LIB_POSITION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_POSITION" 
is
  /**
  * Description
  *    Cette fonction retourne le délai jusqu'au prochain inventaire matières
  *    précieuses pour le poste
  */
  function getDelayInvent(inFalPositionID in FAL_POSITION.FAL_POSITION_ID%type)
    return FAL_POSITION.FPO_DELAY_INVENT%type
  as
    lnFpoDelayInvent FAL_POSITION.FPO_DELAY_INVENT%type;
  begin
    select FPO_DELAY_INVENT
      into lnFpoDelayInvent
      from FAL_POSITION
     where FAL_POSITION_ID = inFalPositionID;

    return lnFpoDelayInvent;
  exception
    when no_data_found then
      return null;
  end getDelayInvent;

  /**
  * Description
  *    Cette fonction retourne l'identifiant de la postion en fonction de la
  *    description du poste
  */
  function getPositionID(iDescription in FAL_POSITION.FPO_DESCRIPTION%type)
    return FAL_POSITION.FAL_POSITION_ID%type
  is
    lcResult FAL_POSITION.FAL_POSITION_ID%type;
  begin
    select nvl(max(FAL_POSITION_ID), 0)
      into lcResult
      from FAL_POSITION
     where upper(FPO_DESCRIPTION) = upper(iDescription);

    return lcResult;
  end getPositionID;

  /**
  * Description
  *    Cette fonction retourne la description du poste de la matière précieuse
  */
  function getDescription(inFalPositionID in FAL_POSITION.FAL_POSITION_ID%type)
    return FAL_POSITION.FPO_DESCRIPTION%type
  as
    lvFpoDescription FAL_POSITION.FPO_DESCRIPTION%type;
  begin
    select FPO_DESCRIPTION
      into lvFpoDescription
      from FAL_POSITION
     where FAL_POSITION_ID = inFalPositionID;

    return lvFpoDescription;
  exception
    when no_data_found then
      return null;
  end getDescription;

  /**
  * Description
  *    Cette fonction retourne la description du poste de la matière précieuse
  *    en fonction du stock
  */
  function getDescriptionByStock(iStockID in FAL_POSITION.STM_STOCK_ID%type)
    return FAL_POSITION.FPO_DESCRIPTION%type
  is
    lvResult FAL_POSITION.FPO_DESCRIPTION%type;
  begin
    select max(FPO_DESCRIPTION)
      into lvResult
      from FAL_POSITION
     where STM_STOCK_ID = iStockId;

    return lvResult;
  end getDescriptionByStock;

/* Fonction qui recherche une description unique pour un poste. Utilisée dans les cas de création
  automatique des postes en fonctions des stocks et ateliers */
  function GetValidPositionDescr(aFPO_DESCRIPTION FAL_POSITION.FPO_DESCRIPTION%type)
    return FAL_POSITION.FPO_DESCRIPTION%type
  is
    cursor EXIST_POSITION_WITH_THIS_DESCR(aFPO_DESCRIPTION FAL_POSITION.FPO_DESCRIPTION%type)
    is
      select FAL_POSITION_ID
        from FAL_POSITION
       where FPO_DESCRIPTION = aFPO_DESCRIPTION;

    ExistPositionWithThisDescr EXIST_POSITION_WITH_THIS_DESCR%rowtype;
    vStartDescription          varchar2(255);
    vValidDescription          varchar2(255);
    iUniqueKey                 integer;
  begin
    vValidDescription  := '';
    vStartDescription  := aFPO_DESCRIPTION;
    iUniqueKey         := 1;

    -- Recherche d'une description unique.
    loop
      iUniqueKey  := iUniqueKey + 1;

      open EXIST_POSITION_WITH_THIS_DESCR(vStartDescription);

      fetch EXIST_POSITION_WITH_THIS_DESCR
       into ExistPositionWithThisDescr;

      if EXIST_POSITION_WITH_THIS_DESCR%found then
        if instr(vStartDescription, '(' || to_char(iUniqueKey - 1) || ')') <> 0 then
          vStartDescription  := substr(vStartDescription, 0, length(vStartDescription) - 3) || '(' || to_char(iUniqueKey) || ')';
        else
          vStartDescription  := vStartDescription || ' (' || to_char(iUniqueKey) || ')';
        end if;
      else
        vValidDescription  := vStartDescription;
      end if;

      close EXIST_POSITION_WITH_THIS_DESCR;

      exit when vValidDescription is not null;
    end loop;

    return vValidDescription;
  end GetValidPositionDescr;

  /**
  * function existsWithFactoryFloor
  * Description
  *    cette fonction retourne 1 si la position existe pour l'atelier transmis
  *    en paramètre.
  * @created age 28.03.2012
  * @lastUpdate
  * @public
  * @param inFalFactoryFloorID : Atelier
  * @return : 1 si existant, sinon 0
  */
  function existsWithFactoryFloor(inFalFactoryFloorID in FAL_POSITION.FAL_FACTORY_FLOOR_ID%type)
    return number
  as
    lnNumber number;
  begin
    select count(FAL_POSITION_ID)
      into lnNumber
      from FAL_POSITION
     where FAL_FACTORY_FLOOR_ID = inFalFactoryFloorID;

    return lnNumber;
  exception
    when no_data_found then
      return 0;
  end existsWithFactoryFloor;

  /**
  * Description
  *    cette fonction retourne 1 si la position existe pour le stock logique transmis
  *    en paramètre.
  */
  function existsWithStock(inStmStockID in FAL_POSITION.STM_STOCK_ID%type)
    return number
  as
    lnNumber number;
  begin
    select count(FAL_POSITION_ID)
      into lnNumber
      from FAL_POSITION
     where STM_STOCK_ID = inStmStockID;

    return lnNumber;
  exception
    when no_data_found then
      return 0;
  end existsWithStock;

  /**
  * Description
  *    cette fonction retourne l'ID du poste MP dont le stock logique correspond
  *    au stock logique transmis en paramètre.
  */
  function getPositionIDByStockID(inStmStockID in FAL_POSITION.STM_STOCK_ID%type)
    return FAL_POSITION.FAL_POSITION_ID%type
  as
    lnFalPositionID FAL_POSITION.FAL_POSITION_ID%type;
  begin
    select FAL_POSITION_ID
      into lnFalPositionID
      from FAL_POSITION
     where STM_STOCK_ID = inStmStockID;

    return lnFalPositionID;
  exception
    when no_data_found then
      return null;
  end getPositionIDByStockID;
end FAL_LIB_POSITION;
