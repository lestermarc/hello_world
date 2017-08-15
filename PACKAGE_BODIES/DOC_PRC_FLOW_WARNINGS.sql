--------------------------------------------------------
--  DDL for Package Body DOC_PRC_FLOW_WARNINGS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_FLOW_WARNINGS" 
is
  /**
  * Description
  *   Suppression de tous les avertissements d'un flux
  *
  */
  procedure DeleteAllWarnings(iFlowID in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type)
  is
  begin
    -- Suppression des avertissements concernant le document du flux
    for tplFlowDocumWarning in (select DOC_GAUGE_FLOW_DOCUM_ID
                                     , C_DOC_GAUGE_FLOW_WARNING
                                  from DOC_GAUGE_FLOW_WARNINGS
                                 where DOC_GAUGE_FLOW_ID = iFlowID
                                   and DOC_GAUGE_RECEIPT_ID is null
                                   and DOC_GAUGE_COPY_ID is null) loop
      DeleteFlowDocumWarning(tplFlowDocumWarning.DOC_GAUGE_FLOW_DOCUM_ID, tplFlowDocumWarning.C_DOC_GAUGE_FLOW_WARNING);
    end loop;

    -- Suppression des avertissements concernant le lien de copie
    for tplCopyWarning in (select DOC_GAUGE_COPY_ID
                                , C_DOC_GAUGE_FLOW_WARNING
                             from DOC_GAUGE_FLOW_WARNINGS
                            where DOC_GAUGE_FLOW_ID = iFlowID
                              and DOC_GAUGE_COPY_ID is not null) loop
      DeleteCopyWarning(tplCopyWarning.DOC_GAUGE_COPY_ID, tplCopyWarning.C_DOC_GAUGE_FLOW_WARNING);
    end loop;

    -- Suppression des avertissements concernant le lien de décharge
    for tplReceiptWarning in (select DOC_GAUGE_RECEIPT_ID
                                   , C_DOC_GAUGE_FLOW_WARNING
                                from DOC_GAUGE_FLOW_WARNINGS
                               where DOC_GAUGE_FLOW_ID = iFlowID
                                 and DOC_GAUGE_RECEIPT_ID is not null) loop
      DeleteReceiptWarning(tplReceiptWarning.DOC_GAUGE_RECEIPT_ID, tplReceiptWarning.C_DOC_GAUGE_FLOW_WARNING);
    end loop;
  end DeleteAllWarnings;

  /**
  * Description
  *   Contrôle général d'un flux
  *
  */
  procedure ControlFlow(iFlowID in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type)
  is
    lCAdminDomain DOC_GAUGE_FLOW.C_ADMIN_DOMAIN%type;
  begin
    for tplFlowDocum in (select DOC_GAUGE_FLOW_DOCUM_ID
                           from DOC_GAUGE_FLOW_DOCUM
                          where DOC_GAUGE_FLOW_ID = iFlowID) loop
      ControlFlowDocum(tplFlowDocum.DOC_GAUGE_FLOW_DOCUM_ID);
    end loop;

    -- Test du flux pour le domaine sous-traitance
    select max(C_ADMIN_DOMAIN)
      into lCAdminDomain
      from DOC_GAUGE_FLOW
     where DOC_GAUGE_FLOW_ID = iFlowID;

    if lCAdminDomain = '5' then
      ControlCode05(iFlowID);
      ControlCode06(iFlowID);
    end if;
  end ControlFlow;

  /**
  * Description
  *   Contrôle du gabarit document d'un flux
  *
  */
  procedure ControlFlowDocum(iFlowDocumID in DOC_GAUGE_FLOW_DOCUM.DOC_GAUGE_FLOW_DOCUM_ID%type)
  is
  begin
    -- Traitement des décharges
    for tplReceipt in (select DOC_GAUGE_RECEIPT_ID
                         from DOC_GAUGE_RECEIPT
                        where DOC_GAUGE_FLOW_DOCUM_ID = iFlowDocumID) loop
      -- Test des avertissements
      ControlCode01(tplReceipt.DOC_GAUGE_RECEIPT_ID, null);
      ControlCode02(tplReceipt.DOC_GAUGE_RECEIPT_ID, null);
      ControlCode03(tplReceipt.DOC_GAUGE_RECEIPT_ID, null);
      ControlCode04(tplReceipt.DOC_GAUGE_RECEIPT_ID);
      ControlCode07(tplReceipt.DOC_GAUGE_RECEIPT_ID);
    end loop;

    -- Traitement des copies
    for tplCopy in (select DOC_GAUGE_COPY_ID
                      from DOC_GAUGE_COPY
                     where DOC_GAUGE_FLOW_DOCUM_ID = iFlowDocumID) loop
      -- Test des avertissements
      ControlCode01(null, tplCopy.DOC_GAUGE_COPY_ID);
      ControlCode02(null, tplCopy.DOC_GAUGE_COPY_ID);
      ControlCode03(null, tplCopy.DOC_GAUGE_COPY_ID);
    end loop;
  end ControlFlowDocum;

  /**
  * Description
  *   Création d'un avertissement pour le document du flux
  *
  */
  procedure CreateFlowDocumWarning(
    iFlowDocumID in DOC_GAUGE_FLOW_DOCUM.DOC_GAUGE_FLOW_DOCUM_ID%type
  , iWarning     in DOC_GAUGE_FLOW_WARNINGS.C_DOC_GAUGE_FLOW_WARNING%type
  , iRemark      in DOC_GAUGE_FLOW_WARNINGS.GAW_REMARK%type default null
  )
  is
    lGaugeFlowID    DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
    ln_AlreadyExist number(1);
    ln_FlagExist    number(1);
  begin
    -- Teste si l'avertissement existe déjà
    select nvl(max(1), 0)
         , nvl(max(GAD.GAD_WARNING), 0)
      into ln_AlreadyExist
         , ln_FlagExist
      from DOC_GAUGE_FLOW_WARNINGS GAW
         , DOC_GAUGE_FLOW_DOCUM GAD
     where GAW.DOC_GAUGE_FLOW_DOCUM_ID = iFlowDocumID
       and GAW.DOC_GAUGE_FLOW_DOCUM_ID = GAD.DOC_GAUGE_FLOW_DOCUM_ID
       and GAW.C_DOC_GAUGE_FLOW_WARNING = iWarning;

    if    (ln_AlreadyExist = 0)
       or (    ln_AlreadyExist = 1
           and ln_FlagExist = 0) then
      if ln_FlagExist = 0 then
        -- Existe dans la table des avertissements mais flag sur la décharge à 0
        -- Suppression l'avertissement
        DeleteFlowDocumWarning(iFlowDocumID, iWarning);
      end if;

      select DOC_GAUGE_FLOW_ID
        into lGaugeFlowID
        from DOC_GAUGE_FLOW_DOCUM
       where DOC_GAUGE_FLOW_DOCUM_ID = iFlowDocumID;

      CreateWarning(null, null, lGaugeFlowID, iFlowDocumID, iWarning, iRemark);
    end if;
  end CreateFlowDocumWarning;

  /**
  * Description
  *   Création d'un avertissement pour la décharge
  *
  */
  procedure CreateReceiptWarning(
    iGaugeReceiptID in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type
  , iWarning        in DOC_GAUGE_FLOW_WARNINGS.C_DOC_GAUGE_FLOW_WARNING%type
  , iRemark         in DOC_GAUGE_FLOW_WARNINGS.GAW_REMARK%type default null
  )
  is
    lGaugeFlowID      DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
    lGaugeFlowDocumID DOC_GAUGE_FLOW_DOCUM.DOC_GAUGE_FLOW_DOCUM_ID%type;
    ln_AlreadyExist   number(1);
    ln_FlagExist      number(1);
  begin
    -- Teste si l'avertissement existe déjà
    select nvl(max(1), 0)
         , nvl(max(GAR.GAR_WARNING), 0)
      into ln_AlreadyExist
         , ln_FlagExist
      from DOC_GAUGE_FLOW_WARNINGS GAW
         , DOC_GAUGE_RECEIPT GAR
     where GAW.DOC_GAUGE_RECEIPT_ID = iGaugeReceiptID
       and GAW.DOC_GAUGE_RECEIPT_ID = GAR.DOC_GAUGE_RECEIPT_ID
       and GAW.C_DOC_GAUGE_FLOW_WARNING = iWarning;

    if    (ln_AlreadyExist = 0)
       or (    ln_AlreadyExist = 1
           and ln_FlagExist = 0) then
      if ln_FlagExist = 0 then
        -- Existe dans la table des avertissements mais flag sur la décharge à 0
        -- Suppression l'avertissement
        DeleteReceiptWarning(iGaugeReceiptID, iWarning);
      end if;

      select DOC_GAUGE_FLOW_ID
           , DOC_GAUGE_FLOW_DOCUM_ID
        into lGaugeFlowID
           , lGaugeFlowDocumID
        from DOC_GAUGE_RECEIPT
       where DOC_GAUGE_RECEIPT_ID = iGaugeReceiptID;

      CreateWarning(iGaugeReceiptID, null, lGaugeFlowID, lGaugeFlowDocumID, iWarning, iRemark);
    end if;
  end CreateReceiptWarning;

  /**
  * Description
  *   Création d'un avertissement pour la copie
  *
  */
  procedure CreateCopyWarning(
    iGaugeCopyID in DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type
  , iWarning     in DOC_GAUGE_FLOW_WARNINGS.C_DOC_GAUGE_FLOW_WARNING%type
  , iRemark      in DOC_GAUGE_FLOW_WARNINGS.GAW_REMARK%type default null
  )
  is
    lGaugeFlowID      DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
    lGaugeFlowDocumID DOC_GAUGE_FLOW_DOCUM.DOC_GAUGE_FLOW_DOCUM_ID%type;
    ln_AlreadyExist   number(1);
    ln_FlagExist      number(1);
  begin
    -- Teste si l'avertissement existe déjà
    select nvl(max(1), 0)
         , nvl(max(GAC.GAC_WARNING), 0)
      into ln_AlreadyExist
         , ln_FlagExist
      from DOC_GAUGE_FLOW_WARNINGS GAW
         , DOC_GAUGE_COPY GAC
     where GAW.DOC_GAUGE_COPY_ID = iGaugeCopyID
       and GAW.DOC_GAUGE_COPY_ID = GAC.DOC_GAUGE_COPY_ID
       and GAW.C_DOC_GAUGE_FLOW_WARNING = iWarning;

    if    (ln_AlreadyExist = 0)
       or (    ln_AlreadyExist = 1
           and ln_FlagExist = 0) then
      if ln_FlagExist = 0 then
        -- Existe dans la table des avertissements mais flag sur la copie à 0
        -- Suppression de l'avertissement
        DeleteCopyWarning(iGaugeCopyID, iWarning);
      end if;

      select DOC_GAUGE_FLOW_ID
           , DOC_GAUGE_FLOW_DOCUM_ID
        into lGaugeFlowID
           , lGaugeFlowDocumID
        from DOC_GAUGE_COPY
       where DOC_GAUGE_COPY_ID = iGaugeCopyID;

      CreateWarning(null, iGaugeCopyID, lGaugeFLowID, lGaugeFlowDocumID, iWarning, iRemark);
    end if;
  end CreateCopyWarning;

  /**
  * Description
  *   Création d'un avertissement
  *
  */
  procedure CreateWarning(
    iGaugeReceiptID   in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type
  , iGaugeCopyID      in DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type
  , iGaugeFlowID      in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type
  , iGaugeFlowDocumID in DOC_GAUGE_FLOW_DOCUM.DOC_GAUGE_FLOW_DOCUM_ID%type
  , iWarning          in DOC_GAUGE_FLOW_WARNINGS.C_DOC_GAUGE_FLOW_WARNING%type
  , iRemark           in DOC_GAUGE_FLOW_WARNINGS.GAW_REMARK%type
  )
  is
    ltGaugeFlowWarnings fwk_i_typ_definition.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocGaugeFlowWarnings, ltGaugeFlowWarnings, true);
    -- Init du type d'avertissement
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeFlowWarnings, 'C_DOC_GAUGE_FLOW_WARNING', iWarning);

    -- Init de l'Id de la décharge
    if iGaugeReceiptID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeFlowWarnings, 'DOC_GAUGE_RECEIPT_ID', iGaugeReceiptID);
    end if;

    -- Init de l'Id de la copie
    if iGaugeCopyID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeFlowWarnings, 'DOC_GAUGE_COPY_ID', iGaugeCopyID);
    end if;

    -- Init de la remarque
    if iRemark is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeFlowWarnings, 'GAW_REMARK', iRemark);
    end if;

    -- Init de l'Id du flux
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeFlowWarnings, 'DOC_GAUGE_FLOW_ID', iGaugeFlowID);
    -- Init de l'Id du flux de document
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeFlowWarnings, 'DOC_GAUGE_FLOW_DOCUM_ID', iGaugeFlowDocumID);
    FWK_I_MGT_ENTITY.InsertEntity(ltGaugeFlowWarnings);
    FWK_I_MGT_ENTITY.Release(ltGaugeFlowWarnings);
  end CreateWarning;

  /**
  * Description
  *   Suppression d'un avertissement pour le document flux
  *
  */
  procedure DeleteFlowDocumWarning(
    iFlowDocumID in DOC_GAUGE_FLOW_DOCUM.DOC_GAUGE_FLOW_DOCUM_ID%type
  , iWarning     in DOC_GAUGE_FLOW_WARNINGS.C_DOC_GAUGE_FLOW_WARNING%type
  )
  is
  begin
    DeleteWarning(null, null, iFlowDocumID, iWarning);
  end DeleteFlowDocumWarning;

  /**
  * Description
  *   Suppression d'un avertissement pour la décharge
  *
  */
  procedure DeleteReceiptWarning(
    iGaugeReceiptID in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type
  , iWarning        in DOC_GAUGE_FLOW_WARNINGS.C_DOC_GAUGE_FLOW_WARNING%type
  )
  is
  begin
    DeleteWarning(iGaugeReceiptID, null, null, iWarning);
  end DeleteReceiptWarning;

  /**
  *   Suppression d'un avertissement pour la copie
  *
  */
  procedure DeleteCopyWarning(iGaugeCopyID in DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type, iWarning in DOC_GAUGE_FLOW_WARNINGS.C_DOC_GAUGE_FLOW_WARNING%type)
  is
  begin
    DeleteWarning(null, iGaugeCopyID, null, iWarning);
  end DeleteCopyWarning;

  /**
  *   Suppression d'un avertissement
  *
  */
  procedure DeleteWarning(
    iGaugeReceiptID in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type
  , iGaugeCopyID    in DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type
  , iFlowDocumID    in DOC_GAUGE_FLOW_DOCUM.DOC_GAUGE_FLOW_DOCUM_ID%type
  , iWarning        in DOC_GAUGE_FLOW_WARNINGS.C_DOC_GAUGE_FLOW_WARNING%type
  )
  is
    lnError              integer;
    lcError              varchar2(2000);
    ltGaugeFlowWarnings  fwk_i_typ_definition.t_crud_def;
    lGaugeFlowWarningsID DOC_GAUGE_FLOW_WARNINGS.DOC_GAUGE_FLOW_WARNINGS_ID%type;
  begin
    -- Rechercher l'id de l'opération à effacer
    select max(DOC_GAUGE_FLOW_WARNINGS_ID)
      into lGaugeFlowWarningsID
      from DOC_GAUGE_FLOW_WARNINGS
     where (   DOC_GAUGE_RECEIPT_ID = iGaugeReceiptID
            or DOC_GAUGE_COPY_ID = iGaugeCopyID
            or DOC_GAUGE_FLOW_DOCUM_ID = iFlowDocumID)
       and C_DOC_GAUGE_FLOW_WARNING = iWarning;

    if lGaugeFlowWarningsID is not null then
      -- Création de l'entité DOC_GAUGE_FLOW_WARNINGS
      FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocGaugeFlowWarnings, ltGaugeFlowWarnings);
      -- Init de l'id de l'avertissement à effacer
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeFlowWarnings, 'DOC_GAUGE_FLOW_WARNINGS_ID', lGaugeFlowWarningsID);

      begin
        FWK_I_MGT_ENTITY.DeleteEntity(ltGaugeFlowWarnings);
        lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
        lcError  := '';
      exception
        when others then
          lnError  := sqlcode;
          lcError  := sqlerrm;
      end;

      if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
        FWK_I_MGT_ENTITY.Release(ltGaugeFlowWarnings);
        fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                          , iv_message       => lcError
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteWarning'
                                           );
      end if;

      FWK_I_MGT_ENTITY.Release(ltGaugeFlowWarnings);
    end if;
  end DeleteWarning;

  /**
  * Description
  *   Mise à jour du flag indiquant qu'il y a un avertissement
  *
  */
  procedure UpdateFlag(iotGaugeFlowWarnings in out nocopy fwk_i_typ_definition.t_crud_def, iFlag in number)
  is
    ltGaugeReceipt fwk_i_typ_definition.t_crud_def;
    ltGaugeCopy    fwk_i_typ_definition.t_crud_def;
    ltFlowDocum    fwk_i_typ_definition.t_crud_def;
  begin
    if    not FWK_I_MGT_ENTITY_DATA.IsNull(iotGaugeFlowWarnings, 'DOC_GAUGE_RECEIPT_ID')
       or not FWK_I_MGT_ENTITY_DATA.IsNull(iotGaugeFlowWarnings, 'DOC_GAUGE_COPY_ID') then
      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotGaugeFlowWarnings, 'DOC_GAUGE_RECEIPT_ID') then
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocGaugeReceipt, ltGaugeReceipt, true);
        -- Init de l'id de la décharge
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeReceipt
                                      , 'DOC_GAUGE_RECEIPT_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGaugeFlowWarnings, 'DOC_GAUGE_RECEIPT_ID')
                                       );
        -- Init du flag d'avertissement
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeReceipt, 'GAR_WARNING', iFlag);
        FWK_I_MGT_ENTITY.UpdateEntity(ltGaugeReceipt);
        FWK_I_MGT_ENTITY.Release(ltGaugeReceipt);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotGaugeFlowWarnings, 'DOC_GAUGE_COPY_ID') then
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocGaugeCopy, ltGaugeCopy, true);
        -- Init de l'id de la copie
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeCopy, 'DOC_GAUGE_COPY_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGaugeFlowWarnings, 'DOC_GAUGE_COPY_ID') );
        -- Init du flag d'avertissement
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltGaugeCopy, 'GAC_WARNING', iFlag);
        FWK_I_MGT_ENTITY.UpdateEntity(ltGaugeCopy);
        FWK_I_MGT_ENTITY.Release(ltGaugeCopy);
      end if;
    else
      FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocGaugeFlowDocum, ltFlowDocum, true);
      -- Init de l'id de la décharge
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFlowDocum
                                    , 'DOC_GAUGE_FLOW_DOCUM_ID'
                                    , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGaugeFlowWarnings, 'DOC_GAUGE_FLOW_DOCUM_ID')
                                     );
      -- Init du flag d'avertissement
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFlowDocum, 'GAD_WARNING', iFlag);
      FWK_I_MGT_ENTITY.UpdateEntity(ltFlowDocum);
      FWK_I_MGT_ENTITY.Release(ltFlowDocum);
    end if;
  end UpdateFlag;

  /**
  * Description
  *   Contrôle type d'avertissement 01 : Type différent gabarit source-gabarit cible
  *
  */
  procedure ControlCode01(iGaugeReceiptID in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type, iGaugeCopyID in DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type)
  is
    cursor curTypePos(iGaugeID DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select C_GAUGE_TYPE_POS
        from DOC_GAUGE_POSITION GAP
       where GAP.DOC_GAUGE_ID = iGaugeID
         and GAP.C_GAUGE_TYPE_POS <> '21';

    lTypePos       DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type;
    lnPosExist     number(1);
    lGaugeID       DOC_GAUGE.DOC_GAUGE_ID%type;
    lGaugeIDTarget DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    lnPosExist  := 1;

    if (iGaugeReceiptID is not null) then
      select GAD.DOC_GAUGE_ID
           , GAR.DOC_DOC_GAUGE_ID
        into lGaugeID
           , lGaugeIDTarget
        from DOC_GAUGE_RECEIPT GAR
           , DOC_GAUGE_FLOW_DOCUM GAD
       where GAD.DOC_GAUGE_FLOW_DOCUM_ID = GAR.DOC_GAUGE_FLOW_DOCUM_ID
         and GAR.DOC_GAUGE_RECEIPT_ID = iGaugeReceiptID;
    else
      select GAD.DOC_GAUGE_ID
           , GAC.DOC_DOC_GAUGE_ID
        into lGaugeID
           , lGaugeIDTarget
        from DOC_GAUGE_COPY GAC
           , DOC_GAUGE_FLOW_DOCUM GAD
       where GAD.DOC_GAUGE_FLOW_DOCUM_ID = GAC.DOC_GAUGE_FLOW_DOCUM_ID
         and GAC.DOC_GAUGE_COPY_ID = iGaugeCopyID;
    end if;

    open curTypePos(lGaugeID);

    loop
      fetch curTypePos
       into lTypePos;

      exit when curTypePos%notfound
            or lnPosExist = 0;

      -- Test des types de position
      select nvl(max(1), 0)
        into lnPosExist
        from DOC_GAUGE_POSITION GAP
       where GAP.DOC_GAUGE_ID = lGaugeIDTarget
         and GAP.C_GAUGE_TYPE_POS = lTypePos;
    end loop;

    close curTypePos;

    if lnPosExist = 0 then
      -- Création de l'avertissement
      if (iGaugeReceiptID is not null) then
        CreateReceiptWarning(iGaugeReceiptID, '01');
      else
        CreateCopyWarning(iGaugeCopyID, '01');
      end if;
    else
      -- Suppression de l'avertissement
      if (iGaugeReceiptID is not null) then
        DeleteReceiptWarning(iGaugeReceiptID, '01');
      else
        DeleteCopyWarning(iGaugeCopyID, '01');
      end if;
    end if;
  end ControlCode01;

  /**
  * procedure ControlCode02
  * Description
  *   Contrôle type d'avertissement 02 : Mouvement sur gabarit cible mais pas d'initialisation du mouvement
  *
  */
  procedure ControlCode02(iGaugeReceiptID in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type, iGaugeCopyID in DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type)
  is
    lnMouvement   number(1);
    lInitQuantity DOC_GAUGE_RECEIPT.GAR_INIT_QTY_MVT%type;
  begin
    if (iGaugeReceiptID is not null) then
      begin
        select   sign(nvl(max(GAP.STM_MOVEMENT_KIND_ID), 0) )
               , GAR.GAR_INIT_QTY_MVT
            into lnMouvement
               , lInitQuantity
            from DOC_GAUGE_FLOW_DOCUM GAD
               , DOC_GAUGE_RECEIPT GAR
               , DOC_GAUGE GAU
               , DOC_GAUGE_POSITION GAP
           where GAR.DOC_GAUGE_RECEIPT_ID = iGaugeReceiptID
             and GAD.DOC_GAUGE_FLOW_DOCUM_ID = GAR.DOC_GAUGE_FLOW_DOCUM_ID
             and GAU.DOC_GAUGE_ID = GAD.DOC_GAUGE_ID
             and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
        group by GAR.GAR_INIT_QTY_MVT;
      exception
        when no_data_found then
          lnMouvement    := 0;
          lInitQuantity  := 0;
      end;
    else
      begin
        select   sign(nvl(max(GAP.STM_MOVEMENT_KIND_ID), 0) )
               , GAC.GAC_INIT_QTY_MVT
            into lnMouvement
               , lInitQuantity
            from DOC_GAUGE_FLOW_DOCUM GAD
               , DOC_GAUGE_COPY GAC
               , DOC_GAUGE GAU
               , DOC_GAUGE_POSITION GAP
           where GAC.DOC_GAUGE_COPY_ID = iGaugeCopyID
             and GAD.DOC_GAUGE_FLOW_DOCUM_ID = GAC.DOC_GAUGE_FLOW_DOCUM_ID
             and GAU.DOC_GAUGE_ID = GAD.DOC_GAUGE_ID
             and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
        group by GAC.GAC_INIT_QTY_MVT;
      exception
        when no_data_found then
          lnMouvement    := 0;
          lInitQuantity  := 0;
      end;
    end if;

    if     lnMouvement = 1
       and lInitQuantity = 0 then
      -- Création de l'avertissement
      if (iGaugeReceiptID is not null) then
        CreateReceiptWarning(iGaugeReceiptID, '02');
      else
        CreateCopyWarning(iGaugeCopyID, '02');
      end if;
    else
      -- Suppression de l'avertissement
      if (iGaugeReceiptID is not null) then
        DeleteReceiptWarning(iGaugeReceiptID, '02');
      else
        DeleteCopyWarning(iGaugeCopyID, '02');
      end if;
    end if;
  end ControlCode02;

    /**
  * procedure ControlCode03
  * Description
  *   Contrôle type d'avertissement 03 : Mouvement sur gabarit cible mais pas d'initialisation du prix du mouvement
  *
  */
  procedure ControlCode03(iGaugeReceiptID in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type, iGaugeCopyID in DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type)
  is
    lnMouvement number(1);
    lInitPrice  DOC_GAUGE_RECEIPT.GAR_INIT_PRICE_MVT%type;
  begin
    if (iGaugeReceiptID is not null) then
      begin
        select   sign(nvl(max(GAP.STM_MOVEMENT_KIND_ID), 0) )
               , GAR.GAR_INIT_PRICE_MVT
            into lnMouvement
               , lInitPrice
            from DOC_GAUGE_FLOW_DOCUM GAD
               , DOC_GAUGE_RECEIPT GAR
               , DOC_GAUGE GAU
               , DOC_GAUGE_POSITION GAP
           where GAR.DOC_GAUGE_RECEIPT_ID = iGaugeReceiptID
             and GAD.DOC_GAUGE_FLOW_DOCUM_ID = GAR.DOC_GAUGE_FLOW_DOCUM_ID
             and GAU.DOC_GAUGE_ID = GAD.DOC_GAUGE_ID
             and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
        group by GAR.GAR_INIT_PRICE_MVT;
      exception
        when no_data_found then
          lnMouvement  := 0;
          lInitPrice   := 0;
      end;
    else
      begin
        select   sign(nvl(max(GAP.STM_MOVEMENT_KIND_ID), 0) )
               , GAC.GAC_INIT_PRICE_MVT
            into lnMouvement
               , lInitPrice
            from DOC_GAUGE_FLOW_DOCUM GAD
               , DOC_GAUGE_COPY GAC
               , DOC_GAUGE GAU
               , DOC_GAUGE_POSITION GAP
           where GAC.DOC_GAUGE_COPY_ID = iGaugeCopyID
             and GAD.DOC_GAUGE_FLOW_DOCUM_ID = GAC.DOC_GAUGE_FLOW_DOCUM_ID
             and GAU.DOC_GAUGE_ID = GAD.DOC_GAUGE_ID
             and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
        group by GAC.GAC_INIT_PRICE_MVT;
      exception
        when no_data_found then
          lnMouvement  := 0;
          lInitPrice   := 0;
      end;
    end if;

    if     lnMouvement = 1
       and lInitPrice = 0 then
      -- Création de l'avertissement
      if (iGaugeReceiptID is not null) then
        CreateReceiptWarning(iGaugeReceiptID, '03');
      else
        CreateCopyWarning(iGaugeCopyID, '03');
      end if;
    else
      -- Suppression de l'avertissement
      if (iGaugeReceiptID is not null) then
        DeleteReceiptWarning(iGaugeReceiptID, '03');
      else
        DeleteCopyWarning(iGaugeCopyID, '03');
      end if;
    end if;
  end ControlCode03;

  /**
  * procedure ControlCode04
  * Description
  *   Contrôle type d'avertissement 04 : Mouvement d'extourne
  *
  */
  procedure ControlCode04(iGaugeReceiptID in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type)
  is
    lExtourne DOC_GAUGE_RECEIPT.GAR_EXTOURNE_MVT%type;
  begin
    select max(GAR_EXTOURNE_MVT)
      into lExtourne
      from DOC_GAUGE_RECEIPT GAR
     where GAR.DOC_GAUGE_RECEIPT_ID = iGaugeReceiptID;

    if lExtourne = 1 then
      -- Création de l'avertissement
      CreateReceiptWarning(iGaugeReceiptID, '04');
    else
      -- Suppression de l'avertissement
      DeleteReceiptWarning(iGaugeReceiptID, '04');
    end if;
  end ControlCode04;

  /**
  * procedure ControlCode05
  * Description
  *   Contrôle type d'avertissement 05 : Contrôle de l'intégrité du flux d'achat sous-traitance
  *   Avertissement s'il y a plus d'un gabarit lié à la réception d'un lot dans chaque branche de ce flux
  *
  */
  procedure ControlCode05(iFlowID in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type)
  is
    lvErrorFlowDocum varchar2(4000);
  begin
    lvErrorFlowDocum  := DOC_I_LIB_SUBCONTRACTP.checkSubcontractFlowManyRecept(iFlowID);

    -- Création ou suppression des avertissements
    for tplFlowDocum in (select DOC_GAUGE_FLOW_DOCUM_ID
                              , case
                                  when DOC_GAUGE_FLOW_DOCUM_ID in(select distinct to_number(column_value) DOC_GAUGE_FLOW_DOCUM_ID
                                                                             from table(PCS.CHARLISTTOTABLE(lvErrorFlowDocum, ',') ) ) then 'Create'
                                  else 'Delete'
                                end iAction
                           from DOC_GAUGE_FLOW_DOCUM
                          where DOC_GAUGE_FLOW_ID = iFlowID) loop
      if tplFlowDocum.iAction = 'Create' then
        CreateFlowDocumWarning(tplFlowDocum.DOC_GAUGE_FLOW_DOCUM_ID, '05');
      else
        DeleteFlowDocumWarning(tplFlowDocum.DOC_GAUGE_FLOW_DOCUM_ID, '05');
      end if;
    end loop;
  end ControlCode05;

  /**
  * procedure ControlCode06
  * Description
  *   Contrôle type d'avertissement 06 : Contrôle de l'intégrité du flux d'achat sous-traitance
  *   Avertissement s'il n'y a aucun gabarit lié à la réception d'un lot dans ce flux
  *
  */
  procedure ControlCode06(iFlowID in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type)
  is
    lvErrorFlowDocum varchar2(4000);
  begin
    lvErrorFlowDocum  := DOC_I_LIB_SUBCONTRACTP.checkSubcontractFlowNoRecept(iFlowID);

    -- Création ou suppression des avertissements
    for tplFlowDocum in (select DOC_GAUGE_FLOW_DOCUM_ID
                              , case
                                  when DOC_GAUGE_FLOW_DOCUM_ID in(select distinct to_number(column_value) DOC_GAUGE_FLOW_DOCUM_ID
                                                                             from table(PCS.CHARLISTTOTABLE(lvErrorFlowDocum, ',') ) ) then 'Create'
                                  else 'Delete'
                                end iAction
                           from DOC_GAUGE_FLOW_DOCUM
                          where DOC_GAUGE_FLOW_ID = iFlowID) loop
      if tplFlowDocum.iAction = 'Create' then
        CreateFlowDocumWarning(tplFlowDocum.DOC_GAUGE_FLOW_DOCUM_ID, '06');
      else
        DeleteFlowDocumWarning(tplFlowDocum.DOC_GAUGE_FLOW_DOCUM_ID, '06');
      end if;
    end loop;
  end ControlCode06;

  /**
  * procedure ControlCode07
  * Description
  *   Contrôle type d'avertissement 07 : Solder parent interdit
  */
  procedure ControlCode07(iGaugeReceiptID in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type)
  is
    lnMovementWithReceiptBatch number(1);
    lBalanceParent             DOC_GAUGE_RECEIPT.GAR_BALANCE_PARENT%type;
  begin
    begin
      select   sign(nvl(max(GAP.STM_MOVEMENT_KIND_ID), 0) )
             , GAR.GAR_BALANCE_PARENT
          into lnMovementWithReceiptBatch
             , lBalanceParent
          from DOC_GAUGE_FLOW_DOCUM GAD
             , DOC_GAUGE_RECEIPT GAR
             , DOC_GAUGE GAU
             , DOC_GAUGE_POSITION GAP
             , STM_MOVEMENT_KIND MOK
         where GAR.DOC_GAUGE_RECEIPT_ID = iGaugeReceiptID
           and GAD.DOC_GAUGE_FLOW_DOCUM_ID = GAR.DOC_GAUGE_FLOW_DOCUM_ID
           and GAU.DOC_GAUGE_ID = GAD.DOC_GAUGE_ID
           and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and DOC_I_LIB_SUBCONTRACTP.IsSUPRSGauge(GAP.DOC_GAUGE_ID) = 1
           and MOK.STM_MOVEMENT_KIND_ID = GAP.STM_MOVEMENT_KIND_ID
           and MOK.MOK_BATCH_RECEIPT = 1
      group by GAR.GAR_BALANCE_PARENT;
    exception
      when no_data_found then
        lBalanceParent              := 0;
        lnMovementWithReceiptBatch  := 0;
    end;

    -- Solder parent et réception du lot de sous-traitance interdit pour l'instant. A supprimer lorsque une solution
    -- pour éviter les deadlock sera trouvé.
    if     (lBalanceParent = 1)
       and (lnMovementWithReceiptBatch = 1) then
      -- Création de l'avertissement
      CreateReceiptWarning(iGaugeReceiptID, '07');
    else
      -- Suppression de l'avertissement
      DeleteReceiptWarning(iGaugeReceiptID, '07');
    end if;
  end ControlCode07;
end DOC_PRC_FLOW_WARNINGS;
