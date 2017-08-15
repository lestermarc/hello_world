--------------------------------------------------------
--  DDL for Package Body GAL_CLEAR_DOC_ID_ON_FDP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_CLEAR_DOC_ID_ON_FDP" 
is
  procedure clear_doc_id
  is
    --But : Effacer le dossier pour les POA issus du calcul de besoin standrad
    l_stm_stock_id    STM_STOCK.STM_STOCK_ID%type;
    l_stm_location_id STM_LOCATION.STM_LOCATION_ID%type;
  begin
    if nvl(PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT'), 0) = 1 then
      begin
        select stm_stock_id
          into l_stm_stock_id
          from stm_stock
         where sto_description = (select PCS.PC_CONFIG.GETCONFIG('GCO_DefltSTOCK_PROJECT')
                                    from dual);
      exception
        when no_data_found then
          l_stm_stock_id  := null;
      end;

      begin
        select LOC.STM_LOCATION_ID
          into l_stm_location_id
          from STM_LOCATION LOC
         where LOC.LOC_description = (select PCS.PC_CONFIG.GETCONFIG('GCO_DefltLOCATION_PROJECT')
                                        from dual)
           and LOC.STM_STOCK_ID = l_stm_stock_id;
      exception
        when no_data_found then
          l_stm_location_id  := null;
      end;

      /*Suppression des DOC_RECORD_ID sur FAL_DOC_PROP*/
      -- -> les produits délégués au cbn normal (gérés sur stock) sont valorisés et suply par ées documents besoisn affaires et sortie affaire -> on doit enlever le dossier sur les poa et of
      for v_cur in (select fal_doc_prop_id
                         , doc_record_id
                      from fal_doc_prop fdp
                     where doc_record_id is not null
                       and stm_stm_stock_id <> l_stm_stock_id
                       and stm_stm_location_id <> l_stm_location_id) loop
        if gal_qi.GET_C_RCO_TYPE_RECORD_GAL(v_cur.doc_record_id) in('02', '03', '04') then   --budget, tache appro, tacheMO
          update fal_doc_prop
             set doc_record_id = null
           where fal_doc_prop_id = v_cur.fal_doc_prop_id;
        end if;
      end loop;

      for v_cur in (select fal_lot_prop_id
                         , doc_record_id
                      from fal_lot_prop fdp
                     where doc_record_id is not null
                       and stm_stock_id <> l_stm_stock_id
                       and stm_location_id <> l_stm_location_id) loop
        if gal_qi.GET_C_RCO_TYPE_RECORD_GAL(v_cur.doc_record_id) in('02', '03', '04') then   --budget, tache appro, tacheMO
          update fal_lot_prop
             set doc_record_id = null
           where fal_lot_prop_id = v_cur.fal_lot_prop_id;
        end if;
      end loop;
    end if;
  end clear_doc_id;
end gal_clear_doc_id_on_fdp;
