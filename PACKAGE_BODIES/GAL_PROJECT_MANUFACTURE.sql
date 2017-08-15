--------------------------------------------------------
--  DDL for Package Body GAL_PROJECT_MANUFACTURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PROJECT_MANUFACTURE" 
is
  /**
  * function pGetManufTaskID
  * Description
  *   Appel de la fonction indiv qui retourne l'id du dossier de fabrication à utiliser
  *     lors de la génération des dossiers de fabrication
  * @created NGV 2015
  * @updated
  * @public
  * @param iProjectID    : ID de l'affaire
  * @param iBudgetID     : ID du budget
  * @param iFatherTaskID : ID de la tâche
  * @param iTaskGoodID   : ID de l'article directeur
  * @param iGoodID       : ID du bien (composé pour le DF)
  * @param iNomHeaderID  : ID de l'entête de la nomenclature
  * @param iGsmNomPath   : Chemin de la nomenclature
  * @param iQuantity     : Qté à lancer
  * @return id du dossier de fabrication
  */
  function pGetManufTaskID(
    iProjectID    in GAL_PROJECT.GAL_PROJECT_ID%type
  , iBudgetID     in GAL_TASK.GAL_BUDGET_ID%type
  , iFatherTaskID in GAL_TASK.GAL_TASK_ID%type
  , iTaskGoodID   in GAL_PROJECT_SUPPLY_MODE.GAL_TASK_GOOD_ID%type
  , iGoodID       in GAL_PROJECT_SUPPLY_MODE.GCO_GOOD_ID%type
  , iNomHeaderID  in GAL_PROJECT_SUPPLY_MODE.PPS_NOMENCLATURE_HEADER_ID%type
  , iGsmNomPath   in GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%type
  , iQuantity     in number
  )
    return number
  is
    lnManufTaskID GAL_TASK.GAL_TASK_ID%type   := null;
    lvSQL         varchar2(4000);
  begin
    lvSQL  := 'select ' || gcCfgRegroupFunction || '( ' || chr(10);
    lvSQL  := lvSQL || '   :iProjectID    ' || chr(10);
    lvSQL  := lvSQL || ' , :iBudgetID     ' || chr(10);
    lvSQL  := lvSQL || ' , :iFatherTaskID ' || chr(10);
    lvSQL  := lvSQL || ' , :iTaskGoodID   ' || chr(10);
    lvSQL  := lvSQL || ' , :iGoodID       ' || chr(10);
    lvSQL  := lvSQL || ' , :iNomHeaderID  ' || chr(10);
    lvSQL  := lvSQL || ' , :iGsmNomPath   ' || chr(10);
    lvSQL  := lvSQL || ' , :iQuantity )   ' || chr(10);
    lvSQL  := lvSQL || ' from dual        ';

    execute immediate lvSQL
                 into lnManufTaskID
                using iProjectID
                    , iBudgetID
                    , iFatherTaskID
                    , iTaskGoodID
                    , iGoodID
                    , iNomHeaderID
                    , iGsmNomPath
                    , iQuantity;

    return lnManufTaskID;
  exception
    when others then
      return null;
  end pGetManufTaskID;

  procedure generate_task_of_manufacture(
    iProjectID    in     GAL_PROJECT.GAL_PROJECT_ID%type
  , iTaskCategID  in     GAL_TASK.GAL_TASK_CATEGORY_ID%type
  , iBudgetID     in     GAL_TASK.GAL_BUDGET_ID%type
  , iFatherTaskID in     GAL_TASK.GAL_TASK_ID%type
  , ioManufTaskID in out GAL_TASK.GAL_TASK_ID%type
  , iGsmNomPath   in     GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%type
  , iGoodID       in     GAL_PROJECT_SUPPLY_MODE.GCO_GOOD_ID%type
  , iSupplyMode   in     GAL_PROJECT_SUPPLY_MODE.C_PROJECT_SUPPLY_MODE%type
  , iTaskGoodID   in     GAL_PROJECT_SUPPLY_MODE.GAL_TASK_GOOD_ID%type
  , iEndDate      in     GAL_TASK.TAS_END_DATE%type
  , iStartDate    in     GAL_TASK.TAS_START_DATE%type
  , iNomHeaderID  in     GAL_PROJECT_SUPPLY_MODE.PPS_NOMENCLATURE_HEADER_ID%type
  )
  is
    lvTaskCode    GAL_TASK.TAS_CODE%type;
    lnLaunchQty   number;
    lnNumberingID DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
  begin
    ioManufTaskID  := nvl(ioManufTaskID, 0);

    begin
      select   NFU_NET_QUANTITY_NEED -
               sum(nvl(decode(substr(GAL_RESOURCE_FOLLOW_UP.RFU_TYPE_NEED_OR_SUPPLY, 1, 1), 'S', RFU_USED_QUANTITY, 0), 0) ) -
               sum(nvl(RFU_QUANTITY, 0) )   --Dispo
          into lnLaunchQty
          from GAL_RESOURCE_FOLLOW_UP
             , GAL_NEED_FOLLOW_UP
         where GAL_RESOURCE_FOLLOW_UP.GAL_NEED_FOLLOW_UP_ID(+) = GAL_NEED_FOLLOW_UP.GAL_NEED_FOLLOW_UP_ID
           and GAL_TASK_GOOD_ID = iTaskGoodID
           and PPS_NOMENCLATURE_HEADER_ID = iNomHeaderID
           and GSM_NOM_PATH = iGsmNomPath
      group by NFU_NET_QUANTITY_NEED;
    exception
      when no_data_found then
        lnLaunchQty  := 0;
    end;

    if lnLaunchQty > 0 then
      -- Regroupement dans un DF spécifique à l'utilisateur
      if     (ioManufTaskID = 0)
         and (gcCfgRegroupFunction is not null) then
        -- Appel de la fonction indiv qui retourne l'id du dossier de fabrication à utiliser
        ioManufTaskID  :=
          pGetManufTaskID(iProjectID      => iProjectID
                        , iBudgetID       => iBudgetID
                        , iFatherTaskID   => iFatherTaskID
                        , iTaskGoodID     => iTaskGoodID
                        , iGoodID         => iGoodID
                        , iNomHeaderID    => iNomHeaderID
                        , iGsmNomPath     => iGsmNomPath
                        , iQuantity       => lnLaunchQty
                         );
      end if;

      -- Création du dossier de fabrication si pas passé en param
      if nvl(ioManufTaskID, 0) = 0 then
        ioManufTaskID  := INIT_ID_SEQ.nextval;
        lnNumberingID  := FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE_NUMBERING', 'GAN_DESCRIBE', PCS.PC_CONFIG.GetConfig('GAL_NUMBERING_MANUFACTURE') );
        DOC_DOCUMENT_FUNCTIONS.GetDocumentNumber(aGaugeID => null, aGaugeNumberingID => lnNumberingID, aDocNumber => lvTaskCode);

        insert into GAL_TASK
                    (GAL_PROJECT_ID
                   , GAL_TASK_ID
                   , TAS_END_DATE
                   , TAS_START_DATE
                   , GAL_TASK_CATEGORY_ID
                   , GAL_BUDGET_ID
                   , GAL_FATHER_TASK_ID
                   , TAS_CODE
                   , C_TAS_STATE
                   , TAS_WORDING
                   , TAS_TASK_PREPARED
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (iProjectID
                   , ioManufTaskID
                   , iEndDate
                   , iStartDate
                   , iTaskCategID
                   , iBudgetID
                   , iFatherTaskID
                   , lvTaskCode
                   , '10'
                   , lvTaskCode
                   , 0
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;

      generate_manufacture_lot(a_tac_id                => ioManufTaskID
                             , a_good_id               => iGoodID
                             , a_gsm_nom_path          => iGsmNomPath
                             , a_task_good_id          => iTaskGoodID
                             , a_pps_nomen_header_id   => iNomHeaderID
                             , a_sessionid             => PCS.PC_I_LIB_SESSION.GetUserIni
                             , a_to_launch_qty         => lnLaunchQty
                              );
      generate_manufacture_good(a_tac_id                => ioManufTaskID
                              , a_gsm_nom_path          => iGsmNomPath
                              , a_supply_mode           => iSupplyMode
                              , a_task_good_id          => iTaskGoodID
                              , a_pps_nomen_header_id   => iNomHeaderID
                              , a_sessionid             => PCS.PC_I_LIB_SESSION.GetUserIni
                              , a_father_tac_id         => iFatherTaskID
                              , a_good_id               => iGoodID
                               );
      commit;
    end if;
  end generate_task_of_manufacture;

 --**********************************************************************************************************--
--**********************************************************************************************************--
  procedure generate_manufacture_lot(
    a_tac_id              gal_task.gal_task_id%type default 0
  , a_good_id             gal_project_supply_mode.gco_good_id%type default 0
  , a_gsm_nom_path        gal_project_supply_mode.gsm_nom_path%type default ' '
  , a_task_good_id        gal_project_supply_mode.gal_task_good_id%type default 0
  , a_pps_nomen_header_id gal_project_supply_mode.pps_nomenclature_header_id%type default 0
  , a_sessionid           gal_task.A_IDCRE%type
  , a_to_launch_qty       number
  )
  is
    v_NextSeq         number                                             := 10;
    v_csant_qty       number;
    v_csant_qty_final number;
    v_plan_number     GCO_COMPL_DATA_MANUFACTURE.CMA_PLAN_NUMBER%type;
    v_plan_version    GCO_COMPL_DATA_MANUFACTURE.CMA_PLAN_VERSION%type;
    v_long_desc       GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
  begin
    begin
      select nvl(max(GTL_SEQUENCE), 0) + 10
        into v_NextSeq
        from GAL_TASK_LOT
       where GAL_TASK_ID = a_tac_id;
    exception
      when no_data_found then
        v_NextSeq  := 10;
    end;

    if a_to_launch_qty > 0 then
      update GAL_TASK_LOT
         set GTL_QUANTITY = GTL_QUANTITY + a_to_launch_qty
           , A_DATEMOD = sysdate
           , A_IDMOD = a_sessionid
       where GAL_TASK_LOT.GAL_TASK_ID = a_tac_id
         and GAL_TASK_LOT.GCO_GOOD_ID = a_good_id
         and rownum = 1;

      if sql%notfound then
        begin
          select trim(DES_LONG_DESCRIPTION)
            into v_long_desc
            from GCO_DESCRIPTION
           where nvl(trim(C_DESCRIPTION_TYPE), '01') = '01'
             and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
             and GCO_GOOD_ID = a_good_id;
        exception
          when no_data_found then
            v_long_desc  := null;
        end;

        begin
          select trim(rpad(CMA_PLAN_NUMBER, 60) )
               , trim(rpad(CMA_PLAN_VERSION, 60) )
            into v_plan_number
               , v_plan_version
            from GCO_COMPL_DATA_MANUFACTURE
           where CMA_DEFAULT = 1
             and GCO_GOOD_ID = a_good_id;
        exception
          when no_data_found then
            v_plan_number   := null;
            v_plan_version  := null;
        end;

        insert into GAL_TASK_LOT
                    (GAL_TASK_LOT_ID
                   , GAL_TASK_ID
                   , GCO_GOOD_ID
                   , GTL_QUANTITY
                   , GTL_SEQUENCE
                   , GTL_PLAN_NUMBER
                   , GTL_PLAN_VERSION
                   , DTL_DESCRIPTION
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval
                   , a_tac_id
                   , a_good_id
                   , a_to_launch_qty
                   , v_NextSeq
                   , v_plan_number
                   , v_plan_version
                   , v_long_desc
                   , sysdate
                   , a_sessionid
                    );
      end if;
    end if;
  end generate_manufacture_lot;

--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure insert_manufacture_good(
    a_tac_id                     gal_task.gal_task_id%type default 0
  , a_good_id                    gal_project_supply_mode.gco_good_id%type default 0
  , a_gal_task_good_id           gal_project_supply_mode.gal_task_good_id%type default 0
  , a_pps_nomenclature_header_id gal_project_supply_mode.pps_nomenclature_header_id%type default 0
  , a_gsm_nom_path               gal_project_supply_mode.gsm_nom_path%type default ' '
  , a_project_supply_mode        GAL_PROJECT_SUPPLY_MODE.C_PROJECT_SUPPLY_MODE%type default ' '
  , a_NextSeq                    GAL_TASK_GOOD.GML_SEQUENCE%type default 10
  , a_sessionid                  gal_task.A_IDCRE%type
  )
  is
    v_to_launch_qty   number;
    v_plan_number     GCO_COMPL_DATA_MANUFACTURE.CMA_PLAN_NUMBER%type;
    v_plan_version    GCO_COMPL_DATA_MANUFACTURE.CMA_PLAN_VERSION%type;
    v_long_desc       GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
    v_nfu_info_supply GAL_NEED_FOLLOW_UP.NFU_INFO_SUPPLY%type;
  begin
    begin
      select nfu_to_launch_quantity
           , nfu_info_supply
        into v_to_launch_qty
           , v_nfu_info_supply
        from GAL_NEED_FOLLOW_UP
       where GAL_NEED_FOLLOW_UP.GAL_TASK_GOOD_ID = A_GAL_TASK_GOOD_ID
         and GAL_NEED_FOLLOW_UP.PPS_NOMENCLATURE_HEADER_ID = A_PPS_NOMENCLATURE_HEADER_ID
         and GAL_NEED_FOLLOW_UP.GSM_NOM_PATH = A_GSM_NOM_PATH
         and trim(GAL_NEED_FOLLOW_UP.GGO_SUPPLY_TYPE) is not null
         and trim(GAL_NEED_FOLLOW_UP.GGO_SUPPLY_MODE) is not null;

      if v_to_launch_qty > 0 then
        update GAL_TASK_GOOD
           set GML_QUANTITY = GML_QUANTITY + v_to_launch_qty   --GML_QUANTITY + decode(v_nfu_info_supply, ' ', 0, v_to_launch_qty)
             , A_DATEMOD = sysdate
             , A_IDMOD = a_sessionid
             , C_PROJECT_SUPPLY_MODE = decode(v_nfu_info_supply, ' ', C_PROJECT_SUPPLY_MODE, a_project_supply_mode)
         where GAL_TASK_GOOD.GAL_TASK_ID = a_tac_id
           and GAL_TASK_GOOD.GCO_GOOD_ID = a_good_id
           and rownum = 1;

        if sql%notfound then
          begin
            select trim(DES_LONG_DESCRIPTION)
              into v_long_desc
              from GCO_DESCRIPTION
             where nvl(trim(C_DESCRIPTION_TYPE), '01') = '01'
               and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
               and GCO_GOOD_ID = a_good_id;
          exception
            when no_data_found then
              v_long_desc  := null;
          end;

          begin
            select trim(rpad(CMA_PLAN_NUMBER, 60) )
                 , trim(rpad(CMA_PLAN_VERSION, 60) )
              into v_plan_number
                 , v_plan_version
              from GCO_COMPL_DATA_MANUFACTURE
             where CMA_DEFAULT = 1
               and GCO_GOOD_ID = a_good_id;
          exception
            when no_data_found then
              v_plan_number   := null;
              v_plan_version  := null;
          end;

          insert into GAL_TASK_GOOD
                      (GAL_TASK_GOOD_ID
                     , GAL_TASK_ID
                     , GCO_GOOD_ID
                     , GML_QUANTITY
                     , GML_SEQUENCE
                     , C_PROJECT_SUPPLY_MODE
                     , GML_PLAN_NUMBER
                     , GML_PLAN_VERSION
                     , GML_DESCRIPTION
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (INIT_ID_SEQ.nextval
                     , a_tac_id
                     , a_good_id
                     , decode(v_nfu_info_supply, ' ', 0, v_to_launch_qty)
                     , a_NextSeq
                     , decode(v_nfu_info_supply, ' ', '5', a_project_supply_mode)
                     , v_plan_number
                     , v_plan_version
                     , v_long_desc
                     , sysdate
                     , a_sessionid
                      );
        end if;   --contrler trigger c_project_supply_mode
      end if;
    exception
      when no_data_found then
        null;
    end;
  end insert_manufacture_good;

   /*
   FUNCTION FATHER_PSEUDO(path GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%TYPE)
   RETURN NUMBER
   IS
     result NUMBER;
     v_father_pseudo NUMBER;
     v_father_path GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%TYPE;
   BEGIN
     BEGIN -- (-1) = pere est pseudo
     SELECT NVL(GSM_ALLOW_UPDATE,1),GSM_NOM_PATH INTO v_father_pseudo,v_father_path
       FROM GAL_PROJECT_SUPPLY_MODE
       WHERE PPS_NOMENCLATURE_HEADER_ID = a_pps_nomen_header_id
       AND GSM_NOM_PATH = substr(V_GSM_NOM_PATH,1,instr(V_GSM_NOM_PATH,'/',-1)-1)
       AND GAL_TASK_GOOD_ID = a_task_good_id AND ROWNUM = 1;
     EXCEPTION WHEN NO_DATA_FOUND THEN
     v_father_pseudo := 1;
     END;
     IF v_father_pseudo = -1
     THEN
       gal_project_manufacture.FATHER_PSEUDO(v_father_path);
       result:=1;
     ELSE result:=0; END IF;
     RETURN(RESULT);
   END FATHER_PSEUDO;
   */
--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure generate_manufacture_good(
    a_tac_id              gal_task.gal_task_id%type default 0
  , a_gsm_nom_path        gal_project_supply_mode.gsm_nom_path%type default ' '
  , a_supply_mode         gal_project_supply_mode.c_project_supply_mode%type default ' '
  , a_task_good_id        gal_project_supply_mode.gal_task_good_id%type default 0
  , a_pps_nomen_header_id gal_project_supply_mode.pps_nomenclature_header_id%type default 0
  , a_sessionid           gal_task.A_IDCRE%type
  , a_father_tac_id       gal_task.gal_task_id%type default 0
  , a_good_id             gal_project_supply_mode.gco_good_id%type default 0
  )
  is
    cursor C_GSM
    is
      select   nvl(GSM_ALLOW_UPDATE, 1)
             , GSM_NOM_LEVEL
             , GAL_PROJECT_SUPPLY_MODE.GCO_GOOD_ID
             , C_PROJECT_SUPPLY_MODE
             , GAL_TASK_GOOD_ID
             , PPS_NOMENCLATURE_HEADER_ID
             , GSM_NOM_PATH
             , PPS_NOMENCLATURE_ID
          from GAL_PROJECT_SUPPLY_MODE
         where PPS_NOMENCLATURE_HEADER_ID = a_pps_nomen_header_id
           and GSM_NOM_PATH like trim(a_gsm_nom_path) || '%'
           and GAL_TASK_GOOD_ID = a_task_good_id
      --AND NVL(GSM_ALLOW_UPDATE,1) <> -1
      order by GAL_PROJECT_SUPPLY_MODE_ID;   --GAL_TASK_GOOD_ID,PPS_NOMENCLATURE_HEADER_ID,GSM_NOM_PATH;

    v_pseudo                     GAL_PROJECT_SUPPLY_MODE.GSM_ALLOW_UPDATE%type;
    v_pseudo_level               GAL_PROJECT_SUPPLY_MODE.GSM_NOM_LEVEL%type;
    pseudo                       GAL_PROJECT_SUPPLY_MODE.GSM_NOM_LEVEL%type;
    v_NextSeq                    GAL_TASK_GOOD.GML_SEQUENCE%type                           := 0;
    v_nom_level                  number                                                    := 0;
    v_good_id                    GCO_GOOD.GCO_GOOD_ID%type;
    v_project_supply_mode        GAL_PROJECT_SUPPLY_MODE.C_PROJECT_SUPPLY_MODE%type;
    V_GAL_TASK_GOOD_ID           GAL_PROJECT_SUPPLY_MODE.GAL_TASK_GOOD_ID%type;
    V_PPS_NOMENCLATURE_HEADER_ID GAL_PROJECT_SUPPLY_MODE.PPS_NOMENCLATURE_HEADER_ID%type;
    V_PPS_NOMENCLATURE_ID        GAL_PROJECT_SUPPLY_MODE.PPS_NOMENCLATURE_ID%type;
    V_DOC_RECORD_ID              GAL_TASK.DOC_RECORD_ID%type;
    V_GSM_NOM_PATH               GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%type;
    v_csant_qty                  number;
    v_to_launch_qty              number;
    v_used_qty                   number;
    v_net_qty                    number;
    v_net_qty_stk                number;
    v_csant_qty_final            number;
    v_level                      number                                                    := 0;
    v_cpt                        number                                                    := 0;

    procedure FATHER_PSEUDO(path GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%type, nom_level GAL_PROJECT_SUPPLY_MODE.GSM_NOM_LEVEL%type)
    is
      v_father_pseudo number;
      v_father_path   GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%type;
      v_father_path2  GAL_PROJECT_SUPPLY_MODE.GSM_NOM_PATH%type;
    begin
      begin   -- (-1) = pere est pseudo
        select nvl(GSM_ALLOW_UPDATE, 1)
             , GSM_NOM_PATH
             , GSM_NOM_LEVEL
          into v_father_pseudo
             , v_father_path
             , pseudo
          from GAL_PROJECT_SUPPLY_MODE
         where PPS_NOMENCLATURE_HEADER_ID = a_pps_nomen_header_id
           and GSM_NOM_PATH = substr(V_GSM_NOM_PATH, 1, instr(V_GSM_NOM_PATH, '/', -1) - 1)
           and GAL_TASK_GOOD_ID = a_task_good_id
           and rownum = 1;
      exception
        when no_data_found then
          v_father_pseudo  := 1;
          v_pseudo_level   := 0;
      end;

      if v_father_pseudo = -1 then
        begin   -- (-1) = pere est pseudo
          select nvl(GSM_ALLOW_UPDATE, 1)
               , GSM_NOM_PATH
               , GSM_NOM_LEVEL
            into v_father_pseudo
               , v_father_path
               , pseudo
            from GAL_PROJECT_SUPPLY_MODE
           where PPS_NOMENCLATURE_HEADER_ID = a_pps_nomen_header_id
             and GSM_NOM_PATH = substr(v_father_path, 1, instr(v_father_path, '/', -1) - 1)
             and GAL_TASK_GOOD_ID = a_task_good_id
             and rownum = 1;
        exception
          when no_data_found then
            v_father_pseudo  := 1;
            v_pseudo_level   := 0;
        end;

        if v_father_path = a_gsm_nom_path then
          v_pseudo_level  := nom_level;
        --dbms_output.put_line('call0                  ' || to_char(nom_level) || '     > ' || v_father_path);
        else
          v_pseudo_level  := 0;
        --dbms_output.put_line('call1                  ' || to_char(nom_level) || '     > ' || v_father_path);
        end if;
      else
        v_pseudo_level  := 0;
      --dbms_output.put_line('call2                   ' || to_char(nom_level) || '     > ' || v_father_path);
      end if;
    end FATHER_PSEUDO;
  begin
    v_cpt           := 0;

    begin
      select nvl(max(GML_SEQUENCE), 0)
        into v_NextSeq
        from GAL_TASK_GOOD
       where GAL_TASK_ID = a_tac_id;
    exception
      when no_data_found then
        v_NextSeq  := 0;
    end;

    v_pseudo_level  := 0;

    open C_GSM;

    loop
      fetch C_GSM
       into v_pseudo
          , v_nom_level
          , v_good_id
          , v_project_supply_mode
          , V_GAL_TASK_GOOD_ID
          , V_PPS_NOMENCLATURE_HEADER_ID
          , V_GSM_NOM_PATH
          , V_PPS_NOMENCLATURE_ID;

      exit when C_GSM%notfound;

      if v_cpt = 0 then
        v_level  := v_nom_level;
      else
        --dbms_output.put_line('gsm <' || to_char(v_pseudo_level) || '>   ' || to_char(v_nom_level) || '     > ' || V_GSM_NOM_PATH );
        if v_pseudo_level <> v_nom_level then
          father_pseudo(v_gsm_nom_path, v_nom_level);
        end if;

        if    v_nom_level = v_level + 1
           or v_nom_level = v_pseudo_level then
          v_NextSeq  := v_NextSeq + 10;

          if v_pseudo <> -1 then
            --dbms_output.put_line('insert <' || to_char(v_pseudo_level) || '>   ' || to_char(v_nom_level) || '     > ' || V_GSM_NOM_PATH );
            insert_manufacture_good(a_tac_id
                                  , v_good_id
                                  , v_gal_task_good_id
                                  , v_pps_nomenclature_header_id
                                  , v_gsm_nom_path
                                  , v_project_supply_mode
                                  , v_NextSeq
                                  , a_sessionid
                                   );
          end if;
        end if;

        if     v_pseudo = -1
           and v_pseudo_level = v_nom_level then
          v_pseudo_level  := v_nom_level + 1;
        end if;
      end if;

      v_cpt  := v_cpt + 1;
    end loop;

    close C_GSM;
  end generate_manufacture_good;
end gal_project_manufacture;
