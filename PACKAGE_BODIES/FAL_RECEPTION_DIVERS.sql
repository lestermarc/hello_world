--------------------------------------------------------
--  DDL for Package Body FAL_RECEPTION_DIVERS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_RECEPTION_DIVERS" 
is
  -- PRD-A040623-30361 DJ20040623-0834
  -- Mettre � jour Qt�SortieR�ception et Qt�D�chetCPT
  -- Pour les composants non g�r�s en stock
  procedure Maj_LienCompo_Without_StkMngt(
    PrmFAL_LOT_ID                FAL_LOT.FAL_LOT_ID%type
  , PrmPourCalculQteSortieRecept number   -- Permet de savoir de combien on doit augmenter la Qt� Sortie R�ception
  , PrmPourCalculQteDechet       number   -- Permet de savoir de combien on doit augmenter la Qt� D�chet CPT
  )
  is
    cursor CLot
    is
      select     FAL_LOT_MATERIAL_LINK_ID
            from FAL_LOT_MATERIAL_LINK
           where FAL_LOT_ID = PrmFAL_LOT_ID   -- Du lot en cours de r�ception
             and LOM_STOCK_MANAGEMENT <> 1   -- et non g�r� en stock
      for update;

    Elot CLot%rowtype;
  begin
    open CLot;

    loop
      fetch Clot
       into ELot;

      exit when CLot%notfound;

      -- Modifier Qt�SortieR�ception et Qt�D�chetCPT
      update FAl_LOT_MATERIAL_LINK
         set LOM_EXIT_RECEIPT = nvl(LOM_EXIT_RECEIPT, 0) +(nvl(PrmPourCalculQteSortieRecept, 0) * LOM_UTIL_COEF)
           , LOM_CPT_REJECT_QTY = nvl(LOM_CPT_REJECT_QTY, 0) +(nvl(PrmPourCalculQteDechet, 0) * LOM_UTIL_COEF)
       where current of Clot;
    end loop;

    close Clot;
  end;
end;
