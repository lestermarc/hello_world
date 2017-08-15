--------------------------------------------------------
--  DDL for Package Body FAL_PRC_ASSEMBLY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_ASSEMBLY" 
is
  /**
  * procedure DeleteEmptyAssemblyPrgAndOrd
  * Description : Suppression des programmes et ordres vides
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure DeleteEmptyAssemblyPrgAndOrd
  is
    cursor crOrders
    is
      select ORD.FAL_ORDER_ID
           , JOP.JOP_REFERENCE
        from FAL_ORDER ORD
           , FAL_JOB_PROGRAM JOP
       where ORD.C_FAB_TYPE = '1'
         and ORD.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID
         and not exists(select 1
                          from FAL_LOT LOT
                         where LOT.FAL_ORDER_ID = ORD.FAL_ORDER_ID);

    cursor crPrograms
    is
      select JOP.FAL_JOB_PROGRAM_ID
        from FAL_JOB_PROGRAM JOP
       where JOP.C_FAB_TYPE = '1'
         and not exists(select 1
                          from FAL_ORDER ORD
                         where ORD.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID);

    nLockedOrder number;
    nLockedProg  number;
  begin
    -- Suppression des ordres "vides"
    for tplOrders in crOrders loop
      begin
        select        FAL_ORDER_ID
                 into nLockedOrder
                 from FAL_ORDER
                where FAL_ORDER_ID = tplOrders.FAL_ORDER_ID
        for update of fal_order_id nowait;

        delete from fal_order
              where fal_order_id = nLockedOrder;

        commit;
      exception
        when others then
          null;
      end;
    end loop;

    -- Suppression des programmes "vides"
    for tplPrograms in crPrograms loop
      begin
        select     FAL_JOB_PROGRAM_ID
              into nLockedProg
              from FAL_JOB_PROGRAM
             where FAL_JOB_PROGRAM_ID = tplPrograms.FAL_JOB_PROGRAM_ID
        for update nowait;

        delete from fal_job_program
              where fal_job_program_id = nLockedProg;
      exception
        when others then
          null;
      end;
    end loop;
  end DeleteEmptyAssemblyPrgAndOrd;

  /**
  * procedure CreatAssemblyPrgAndOrd
  * Description : Création des programmes et ordres d'assemblage
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure CreatAssemblyPrgAndOrd(
    iJopDescription   in     varchar2
  , iOrdsecondref     in     varchar2
  , iOrdShortDesc     in     varchar2
  , iOrdlongDesc      in     varchar2
  , iOrdfreeDesc      in     varchar2
  , iGcoGoodId        in     number
  , ioFalJobProgramId in out number
  , ioFalOrderId      in out number
  , ioJopReference    in out integer
  , ioOrdReference    in out integer
  )
  is
  begin
    -- Génération du programme d'assemblage
    if nvl(ioFalJobProgramId, 0) = 0 then
      ioFalJobProgramId  := FAL_PROGRAM_FUNCTIONS.CreateManufactureProgram(iJopDescription);

      update FAL_JOB_PROGRAM
         set C_FAB_TYPE = '1'
       where FAL_JOB_PROGRAM_ID = ioFalJobProgramId;

      select JOP_REFERENCE
        into ioJopReference
        from FAL_JOB_PROGRAM
       where FAL_JOB_PROGRAM_ID = ioFalJobProgramId;
    end if;

    -- Génération de l'ordre d'assemblage
    ioFalOrderId  := FAL_ORDER_FUNCTIONS.CreateManufactureOrder(ioFalJobProgramId, iGcoGoodId, null, '1', null, iOrdShortDesc, iOrdLongDesc, iOrdFreeDesc);

    update FAL_ORDER
       set ORD_SECOND_REF = iOrdSecondRef
         , C_ORDER_STATUS = '3'
     where FAL_ORDER_ID = ioFalOrderId;

    select ORD_REF
      into ioOrdReference
      from FAL_ORDER
     where FAL_ORDER_ID = ioFalOrderId;
  end;

  /**
  * Description : Insertion de la ligne de traçabilité particulère (démontage) et gestion de la réutilisation du détail de caractérisation
  */
  procedure AddDesassenblingTrace(
    iGoodId             in GCO_GOOD.GCO_GOOD_ID%type
  , iValueCaractPiece   in varchar2
  , iValueCaractSet     in varchar2
  , iValueCaractVersion in varchar2
  , iDismantledQty      in number
  )
  is
    ltTracability   FWK_I_TYP_DEFINITION.t_crud_def;
    ltElementNumber FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplTracability in (select FAL_TRACABILITY_ID
                                , (decode(nvl(HIS_FREE_TEXT, '')
                                        , '', FAL_TOOLS.Format_Lot(FAL_LOT_ID) || ' (' || PCS.PC_FUNCTIONS.TranslateWord('Désassemblé le') || ' ' || sysdate
                                           || ')'
                                        , HIS_FREE_TEXT || ' (' || PCS.PC_FUNCTIONS.TranslateWord('Désassemblé le') || ' ' || sysdate || ')'
                                         )
                                  ) HIS_FREE_TEXT_NEW
                             from FAL_TRACABILITY
                            where GCO_GOOD_ID = iGoodId
                              and nvl(HIS_DISASSEMBLED_PDT, 0) = 0
                              and (   iValueCaractPiece is null
                                   or HIS_PT_PIECE = iValueCaractPiece)
                              and (   iValueCaractSet is null
                                   or HIS_PT_LOT = iValueCaractSet)
                              and (   iValueCaractVersion is null
                                   or HIS_PT_VERSION = iValueCaractVersion) ) loop
      -- Insertion de la ligne de tracabilité particulière (démontage)
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalTracability, ltTracability, false, null, null, 'FAL_TRACABILITY_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTracability, 'FAL_TRACABILITY_ID', tplTracability.FAL_TRACABILITY_ID);
      -- Nouvelle valeur
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTracability, 'HIS_FREE_TEXT', tplTracability.HIS_FREE_TEXT_NEW);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTracability, 'HIS_DISASSEMBLED_PDT', 1);
      FWK_I_MGT_ENTITY.UpdateEntity(ltTracability);
      FWK_I_MGT_ENTITY.Release(ltTracability);
    end loop;

    -- Réutilisation possible de la caractérisation
    if PCS.PC_CONFIG.GetConfig('FAL_ASSEMBLING_TRAC_MODE') = '2' then
      for tplElementNumber in (select STM_ELEMENT_NUMBER_ID
                                 from STM_ELEMENT_NUMBER
                                where GCO_GOOD_ID = iGoodId
                                  and SEM_VALUE = iValueCaractPiece) loop
        -- Changer le status en 'Retourné' pour pouvoir le réutiliser
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmElementNumber, ltElementNumber, false, null, null, 'STM_ELEMENT_NUMBER_ID');
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltElementNumber, 'STM_ELEMENT_NUMBER_ID', tplElementNumber.STM_ELEMENT_NUMBER_ID);
        -- Nouvelle valeur
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltElementNumber, 'C_ELE_NUM_STATUS', '04');
        FWK_I_MGT_ENTITY.UpdateEntity(ltElementNumber);
        FWK_I_MGT_ENTITY.Release(ltElementNumber);
      end loop;
    end if;
  end AddDesassenblingTrace;

  /**
  * Description : Suppression des détails de caractérisation et de la traçabilité lors d'un désassemblage
  */
  procedure DeleteCharDetailAndTraca(
    iElementNumberId    in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iGoodId             in GCO_GOOD.GCO_GOOD_ID%type
  , iValueCaractPiece   in varchar2
  , iValueCaractSet     in varchar2
  , iValueCaractVersion in varchar2
  , iDismantledQty      in number
  )
  is
    ltElementNumber FWK_I_TYP_DEFINITION.t_crud_def;
    ltTracability   FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if iValueCaractPiece is not null then
      -- En fonction du mode de gestion de la traçabilité, on supprime ou non la traçabilité du PT
      if PCS.PC_CONFIG.GetConfig('FAL_ASSEMBLING_TRAC_MODE') = '0' then
        -- Contrôle de l'utilisation du STM_ELEMENT_NUMBER dans d'autre table
        if FAL_TRACABILITY_FCT.IsUsedElementNumber(iElementNumberId) = 0 then
          -- Supprimer le type pièce
          for tplElementNumber in (select STM_ELEMENT_NUMBER_ID
                                     from STM_ELEMENT_NUMBER
                                    where GCO_GOOD_ID = iGoodId
                                      and SEM_VALUE = iValueCaractPiece) loop
            FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmElementNumber, ltElementNumber);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltElementNumber, 'STM_ELEMENT_NUMBER_ID', tplElementNumber.STM_ELEMENT_NUMBER_ID);
            FWK_I_MGT_ENTITY.DeleteEntity(ltElementNumber);
            FWK_I_MGT_ENTITY.Release(ltElementNumber);
          end loop;
        end if;
      end if;

      if     iValueCaractSet is not null
         and (   upper(PCS.PC_CONFIG.GetConfig('STM_SET_SGL_NUMBERING_COMP') ) = 'TRUE'
              or upper(PCS.PC_CONFIG.GetConfig('STM_SET_SGL_NUMBERING_GOOD') ) = 'TRUE') then
        -- En fonction du mode de gestion de la traçabilité, on supprime ou non la traçabilité du PT
        if PCS.PC_CONFIG.GetConfig('FAL_ASSEMBLING_TRAC_MODE') = '0' then
          -- Contrôle de l'utilisation du STM_ELEMENT_NUMBER dans d'autre table
          if FAL_TRACABILITY_FCT.IsUsedElementNumber(iElementNumberId) = 0 then
            -- Supprimer le type lot
            for tplElementNumber in (select STM_ELEMENT_NUMBER_ID
                                       from STM_ELEMENT_NUMBER
                                      where GCO_GOOD_ID = iGoodId
                                        and SEM_VALUE = iValueCaractSet) loop
              FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmElementNumber, ltElementNumber);
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltElementNumber, 'STM_ELEMENT_NUMBER_ID', tplElementNumber.STM_ELEMENT_NUMBER_ID);
              FWK_I_MGT_ENTITY.DeleteEntity(ltElementNumber);
              FWK_I_MGT_ENTITY.Release(ltElementNumber);
            end loop;
          end if;
        end if;
      end if;

      if     iValueCaractVersion is not null
         and (   upper(PCS.PC_CONFIG.GetConfig('STM_VERSION_SGL_NUMBERING_COMP') ) = 'TRUE'
              or upper(PCS.PC_CONFIG.GetConfig('STM_VERSION_SGL_NUMBERING_GOOD') ) = 'TRUE'
             ) then
        -- En fonction du mode de gestion de la traçabilité, on supprime ou non la traçabilité du PT
        if PCS.PC_CONFIG.GetConfig('FAL_ASSEMBLING_TRAC_MODE') = '0' then
          -- Contrôle de l'utilisation du STM_ELEMENT_NUMBER dans d'autre table
          if FAL_TRACABILITY_FCT.IsUsedElementNumber(iElementNumberId) = 0 then
            -- Supprimer le type version
            for tplElementNumber in (select STM_ELEMENT_NUMBER_ID
                                       from STM_ELEMENT_NUMBER
                                      where GCO_GOOD_ID = iGoodId
                                        and SEM_VALUE = iValueCaractVersion) loop
              FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmElementNumber, ltElementNumber);
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltElementNumber, 'STM_ELEMENT_NUMBER_ID', tplElementNumber.STM_ELEMENT_NUMBER_ID);
              FWK_I_MGT_ENTITY.DeleteEntity(ltElementNumber);
              FWK_I_MGT_ENTITY.Release(ltElementNumber);
            end loop;
          end if;
        end if;
      end if;

      -- En fonction du mode de gestion de la traçabilité, on supprime ou non la traçabilité du PT
      if PCS.PC_CONFIG.GetConfig('FAL_ASSEMBLING_TRAC_MODE') = '0' then
        -- détruire le (aucun) ou les FAL_TRACABILITY
        -- pour le GCO_GOOD_ID = STM_STOCK_POSITION.GCO_GOOD_ID
        -- et HIS_PT_PIECE = Valeur de la caréctarisation correspondant à une caractérisation de type 3 (N° de série) de la position
        for tplFalTracability in (select FAL_TRACABILITY_ID
                                    from FAL_TRACABILITY
                                   where GCO_GOOD_ID = iGoodId
                                     and HIS_PT_PIECE = iValueCaractPiece) loop
          FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTracability, ltTracability);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltTracability, 'FAL_TRACABILITY_ID', tplFalTracability.FAL_TRACABILITY_ID);
          FWK_I_MGT_ENTITY.DeleteEntity(ltTracability);
          FWK_I_MGT_ENTITY.Release(ltTracability);
        end loop;
      else
        -- Conservation de la tracabilité et ajout d'une ligne d'indication du désassemblage
        AddDesassenblingTrace(iGoodId, iValueCaractPiece, iValueCaractSet, iValueCaractVersion, iDismantledQty);
      end if;
    end if;
  end DeleteCharDetailAndTraca;
end FAL_PRC_ASSEMBLY;
