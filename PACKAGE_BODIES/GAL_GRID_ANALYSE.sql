--------------------------------------------------------
--  DDL for Package Body GAL_GRID_ANALYSE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_GRID_ANALYSE" 
is
  /*hmo 06.08
  Mise à jour du prix de vente sur les affaires
  Contrôle qu'un prix de vente est déterminable depuis les documents
  si oui le met à jour
  sinon laise le prix de vente tel quel
  */
  procedure maj_info_comm_on_gal_project(aPrjID GAL_PROJECT.GAL_PROJECT_ID%type)
  is
    vSalePrice       number;
    vDmtNumber       DOC_DOCUMENT.DMT_NUMBER%type;
    vPacThirdId      DOC_DOCUMENT.PAC_THIRD_ID%type;
    vDmtDateDocument DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    vPdeFinalDelay   DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
  begin
    GAL_PRJ_FUNCTIONS.Get_Balance_Order_information(aPrjID, null, vSalePrice, vDmtNumber, vPacThirdId, vDmtDateDocument, vPdeFinalDelay);

    if vSalePrice = 0 then
      vSalePrice  := null;
    end if;

    ---- Mise a jour des PV des affaires et des infos comm
    -- si pas de docuement de vente, on laisse telles quelles les infos éventuellement rensignées
    if vDmtNumber is not null then
      update GAL_PROJECT
         set PRJ_CUSTOMER_ORDER_REF = vDmtNumber
           , PRJ_CUSTOMER_ORDER_DATE = vDmtDateDocument
           , PRJ_CUSTOMER_DELIVERY_DATE = nvl(vPdeFinalDelay, PRJ_CUSTOMER_DELIVERY_DATE)
           , PRJ_SALE_PRICE = vSalePrice
           , PAC_CUSTOM_PARTNER_ID = vPacThirdId
       where GAL_PROJECT_ID = aPrjID;
    end if;
  --commit;
  end maj_info_comm_on_gal_project;

--------------------------------------------------------------------------------
  procedure create_conso_and_maj_saleprice(
    aSqlGalProject       varchar2
  , aC_GAL_SPENDING_TYPE varchar2 default null
  , v_mode               integer default 0
  , adatemax             date default null
  )
  is
    vCrGalProject type_cursor;
    vGalProjectId GAL_PROJECT.GAL_PROJECT_ID%type;
    v_count       number;
  begin
    -- aSql contient commande sql de recherche des affaires
    if aSqlGalProject is not null then
      if v_mode = 1 then
        open vcrgalproject for asqlgalproject;

        loop
          fetch vcrgalproject
           into vgalprojectid;

          exit when vcrgalproject%notfound;
          maj_info_comm_on_gal_project(vgalprojectid);
        end loop;

        close vcrgalproject;
      end if;

      if v_mode = 2 then
        select count(gal_hours_id)
          into v_count
          from gal_hours
         where trunc(hou_pointing_date, 'DDD') <= trunc(adatemax, 'DDD')
           and hou_hourly_rate_eco is null;

        if v_count > 0 then
          raise_application_error(-20000, pcs.pc_functions.translateword('Less taux économiques ne sont pas mis à jour dans la période considérée') );
        end if;
      end if;

      gal_project_consolidation.gal_spending_generate_with_sel(asqlgalproject         => aSqlGalProject
                                                             , aC_GAL_SPENDING_TYPE   => aC_GAL_SPENDING_TYPE
                                                             , v_mode                 => v_mode
                                                             , adatemax               => adatemax
                                                              );
    end if;

    commit;
  end create_conso_and_maj_saleprice;
--------------------------------------------------------------------------------
end GAL_GRID_ANALYSE;
