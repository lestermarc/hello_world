--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT_TOOLS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT_TOOLS" 
is
  -- Traitement de récupération de la plus petite qté max receptionnable des liens composant du lot
  -- Traduction du code Delphi de Recuperation_plus_petite_QteMaxReceptionnable_Lot
  -- DJ20030103-0001 la fonction a été entierement revue.
  -- CLG20030908-001
  -- QtéMaxRécept du lot = Qté min (Qté max réceptionnables des composants type composant,
  --    actif, ayant un coefficient d'utilisation null ou égal 0 et gérés en stock).
  -- Si le lot n'a pas de composant :
  --    QtéMaxRécept du lot = Qté en fabrication    CLG20040329-0786
  function GetMinQteMaxReceptionnable_Lot(
    PrmFAL_LOT_ID     FAL_LOT.FAL_LOT_ID%type
  , PrmLOT_INPROD_QTY FAL_LOT.LOT_TOTAL_QTY%type default -1
  )
    return FAL_LOT_MATERIAL_LINK.LOM_MAX_RECEIPT_QTY%type
  is
    Qte_Max    FAL_LOT_MATERIAL_LINK.LOM_MAX_RECEIPT_QTY%type;
    CountCompo number;
  begin
    select count(*)
      into CountCompo
      from FAL_LOT_MATERIAL_LINK
     where FAL_LOT_ID = PrmFAL_LOT_ID
       and C_TYPE_COM = '1'   -- Actif
       and C_KIND_COM = '1'   -- Composant
       and LOM_STOCK_MANAGEMENT = 1   -- Géré en stock
       and nvl(LOM_UTIL_COEF, 0) <> 0;

    if CountCompo = 0 then
      if PrmLOT_INPROD_QTY = -1 then
        select nvl(LOT_INPROD_QTY, 0)
          into Qte_Max
          from FAL_LOT
         where FAL_LOT_ID = PrmFAL_LOT_ID;
      else
        Qte_Max  := PrmLOT_INPROD_QTY;
      end if;
    else
      select min(LOM_MAX_RECEIPT_QTY)
        into Qte_Max
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_ID = PrmFAL_LOT_ID
         and C_TYPE_COM = '1'   -- Actif
         and C_KIND_COM = '1'   -- Composant
         and LOM_STOCK_MANAGEMENT = 1   -- Géré en stock
         and nvl(LOM_UTIL_COEF, 0) <> 0;
    end if;

    return Qte_Max;
  end;


end;
