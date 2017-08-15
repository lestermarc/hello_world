--------------------------------------------------------
--  DDL for Package Body FAL_RECEPTION_DIVERS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_RECEPTION_DIVERS" 
is
  -- PRD-A040623-30361 DJ20040623-0834
  -- Mettre à jour QtéSortieRéception et QtéDéchetCPT
  -- Pour les composants non gérés en stock
  procedure Maj_LienCompo_Without_StkMngt(
    PrmFAL_LOT_ID                FAL_LOT.FAL_LOT_ID%type
  , PrmPourCalculQteSortieRecept number   -- Permet de savoir de combien on doit augmenter la Qté Sortie Réception
  , PrmPourCalculQteDechet       number   -- Permet de savoir de combien on doit augmenter la Qté Déchet CPT
  )
  is
    cursor CLot
    is
      select     FAL_LOT_MATERIAL_LINK_ID
            from FAL_LOT_MATERIAL_LINK
           where FAL_LOT_ID = PrmFAL_LOT_ID   -- Du lot en cours de réception
             and LOM_STOCK_MANAGEMENT <> 1   -- et non géré en stock
      for update;

    Elot CLot%rowtype;
  begin
    open CLot;

    loop
      fetch Clot
       into ELot;

      exit when CLot%notfound;

      -- Modifier QtéSortieRéception et QtéDéchetCPT
      update FAl_LOT_MATERIAL_LINK
         set LOM_EXIT_RECEIPT = nvl(LOM_EXIT_RECEIPT, 0) +(nvl(PrmPourCalculQteSortieRecept, 0) * LOM_UTIL_COEF)
           , LOM_CPT_REJECT_QTY = nvl(LOM_CPT_REJECT_QTY, 0) +(nvl(PrmPourCalculQteDechet, 0) * LOM_UTIL_COEF)
       where current of Clot;
    end loop;

    close Clot;
  end;
end;
