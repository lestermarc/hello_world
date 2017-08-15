--------------------------------------------------------
--  DDL for Package Body ASA_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_FUNCTIONS" 
as
/*--------------------------------------------------------------------------------------------------------------------*/
  function get_recid_from_docid(docId in doc_document.DOC_DOCUMENT_ID%type)
    return varchar2
  is
    result varchar2(20);
  begin
    select max(asa_record_id)
      into result
      from doc_position
     where doc_document_id = DocId;

    return result;
  exception
    when no_data_found then
      return '';
  end get_recid_from_docid;

/*--------------------------------------------------------------------------------------------------------------------*/
  function asa_record_w_stock_mvt(RecId in asa_record.ASA_RECORD_ID%type)
    return number
  is
    result number(12);
  begin
    select count(*)
      into result
      from asa_record are
         , asa_record_events aev
         , asa_record_comp arc
     where are.asa_record_id = RecId
       and are.asa_record_id = arc.asa_record_id
       and are.asa_record_id = aev.asa_record_id
       and are.C_ASA_REP_STATUS = aev.C_ASA_REP_STATUS
       and aev.ASA_RECORD_EVENTS_ID = arc.ASA_RECORD_EVENTS_ID
       and (   arc.arc_optional = 0
            or (    arc.arc_optional = 1
                and arc.C_ASA_accept_option = '2') )
       and arc.arc_cdmvt = 1
       and arc.stm_comp_stock_mvt_id is null;

    return result;
  exception
    when no_data_found then
      return 0;
  end asa_record_w_stock_mvt;

/*--------------------------------------------------------------------------------------------------------------------*/
  function ControlQtyRepaired(aRecordID ASA_RECORD.ASA_RECORD_ID%type)
    return number
  is
    QtyRepaired ASA_RECORD_REP_DETAIL.RRD_QTY_REPAIRED%type;
    result      number(1);

    cursor crRecordDetail
    is
      select ASA_RECORD_DETAIL_ID
           , RED_QTY_TO_REPAIR
        from ASA_RECORD_DETAIL
       where ASA_RECORD_ID = aRecordId;
  begin
    result  := 1;

    for Detail in crRecordDetail loop
      select nvl(sum(RRD_QTY_REPAIRED), 0)
        into QtyRepaired
        from ASA_RECORD_REP_DETAIL
       where ASA_RECORD_DETAIL_ID = Detail.ASA_RECORD_DETAIL_ID;

      if QtyRepaired <> Detail.RED_QTY_TO_REPAIR then
        result  := 0;
      end if;
    end loop;

    return result;
  end ControlQtyRepaired;

/*--------------------------------------------------------------------------------------------------------------------*/
  function ControlQtyExchanged(aRecordID ASA_RECORD.ASA_RECORD_ID%type)
    return number
  is
    QtyExchanged ASA_RECORD_EXCH_DETAIL.REX_QTY_EXCHANGED%type;
    QTyToExch    asa_Record_detail.red_qty_to_Repair%type;
    CharMgmt     number(1);
    result       number(1);
  begin
    result  := 1;

    -- Recherche si le produit pour échange a des caractérisations
    select sign(count(*) )
      into CharMgmt
      from GCO_CHARACTERIZATION CHA
         , ASA_RECORD are
     where are.GCO_ASA_EXCHANGE_ID = CHA.GCO_GOOD_ID
       and ASA_RECORD_ID = aRecordId;

    if CharMgmt = 1 then
      -- Si le produit pour échange a des caractérisations, on compare les détails entre eux
      for tplDetail in (select ASA_RECORD_DETAIL_ID
                             , RED_QTY_TO_REPAIR
                          from ASA_RECORD_DETAIL
                         where ASA_RECORD_ID = aRecordId) loop
        select nvl(sum(REX_QTY_EXCHANGED), 0)
          into QtyExchanged
          from ASA_RECORD_EXCH_DETAIL
         where ASA_RECORD_DETAIL_ID = tplDetail.ASA_RECORD_DETAIL_ID;

        if QtyExchanged <> tplDetail.RED_QTY_TO_REPAIR then
          result  := 0;
          exit;
        end if;
      end loop;
    else
      -- si le produit pour échange n'a pas de caractérisations, on compare la somme des qtés du détail
      select nvl(sum(RED_QTY_TO_REPAIR), 0)
        into QtyToExch
        from ASA_RECORD_DETAIL
       where ASA_RECORD_ID = ARECORDID;

      select ARE_EXCH_QTY
        into QtyExchanged
        from ASA_RECORD
       where ASA_RECORD_ID = aRecordId;

      if QtyToExch <> QtyExchanged then
        result  := 0;
      end if;
    end if;

    return result;
  end ControlQtyExchanged;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure AutoInsertRepDetail(paRecordID in ASA_RECORD.ASA_RECORD_ID%type)
  is
  begin
    insert into ASA_RECORD_REP_DETAIL
                (ASA_RECORD_REP_DETAIL_ID
               , ASA_RECORD_DETAIL_ID
               , GCO_CHAR1_ID
               , GCO_CHAR2_ID
               , GCO_CHAR3_ID
               , GCO_CHAR4_ID
               , GCO_CHAR5_ID
               , RRD_NEW_CHAR1_VALUE
               , RRD_NEW_CHAR2_VALUE
               , RRD_NEW_CHAR3_VALUE
               , RRD_NEW_CHAR4_VALUE
               , RRD_NEW_CHAR5_VALUE
               , RRD_QTY_REPAIRED
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval
           , ASA_RECORD_DETAIL_ID
           , GCO_CHAR1_ID
           , GCO_CHAR2_ID
           , GCO_CHAR3_ID
           , GCO_CHAR4_ID
           , GCO_CHAR5_ID
           , RED_CHAR1_VALUE
           , RED_CHAR2_VALUE
           , RED_CHAR3_VALUE
           , RED_CHAR4_VALUE
           , RED_CHAR5_VALUE
           , RED_QTY_TO_REPAIR
           , sysdate
           , PCS.PC_I_LIB_SESSION.GETUSERINI
        from ASA_RECORD_DETAIL
       where ASA_RECORD_ID = paRecordId
         and ASA_RECORD_DETAIL_ID not in(select ASA_RECORD_DETAIL_ID
                                           from ASA_RECORD_REP_DETAIL);
  end AutoInsertRepDetail;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure AutoInsertExchDetail(paRecordID in ASA_RECORD.ASA_RECORD_ID%type)
  is
  begin
    insert into ASA_RECORD_EXCH_DETAIL
                (ASA_RECORD_EXCH_DETAIL_ID
               , GCO_EXCH_CHAR1_ID
               , GCO_EXCH_CHAR2_ID
               , GCO_EXCH_CHAR3_ID
               , GCO_EXCH_CHAR4_ID
               , GCO_EXCH_CHAR5_ID
               , ASA_RECORD_DETAIL_ID
               , REX_EXCH_CHAR1_VALUE
               , REX_EXCH_CHAR2_VALUE
               , REX_EXCH_CHAR3_VALUE
               , REX_EXCH_CHAR4_VALUE
               , REX_EXCH_CHAR5_VALUE
               , REX_QTY_EXCHANGED
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval
           , GCO_CHAR1_ID
           , GCO_CHAR2_ID
           , GCO_CHAR3_ID
           , GCO_CHAR4_ID
           , GCO_CHAR5_ID
           , ASA_RECORD_DETAIL_ID
           , RED_CHAR1_VALUE
           , RED_CHAR2_VALUE
           , RED_CHAR3_VALUE
           , RED_CHAR4_VALUE
           , RED_CHAR5_VALUE
           , RED_QTY_TO_REPAIR
           , sysdate
           , PCS.PC_I_LIB_SESSION.GETUSERINI
        from ASA_RECORD_DETAIL RED
       where ASA_RECORD_ID = paRecordID;
  end AutoInsertExchDetail;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Function GeAttribQuantity
  * Description :
  *             Retourne la quantité attribuée selon le bien/stock/emplacement et les caractérisations
  */
  function GetCompAttribQuantity(aRecordCompID in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type)
    return number
  is
    vAttribQty FAL_NETWORK_LINK.FLN_QTY%type   default 0;
  begin
    select nvl(max(FLN.FLN_QTY), 0)
      into vAttribQty
      from STM_STOCK_POSITION SPO
         , FAL_NETWORK_LINK FLN
         , FAL_NETWORK_NEED FAN
         , DOC_POSITION_DETAIL PDE
         , ASA_RECORD_COMP ARC
     where SPO.STM_STOCK_POSITION_ID = FLN.STM_STOCK_POSITION_ID
       and FLN.FAL_NETWORK_NEED_ID = FAN.FAL_NETWORK_NEED_ID
       and FAN.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
       and PDE.DOC_POSITION_ID = ARC.DOC_ATTRIB_POSITION_ID
       and ARC.ASA_RECORD_COMP_ID = aRecordCompID
       and FLN.STM_LOCATION_ID = ARC.STM_COMP_LOCATION_ID
       and nvl(SPO.GCO_CHARACTERIZATION_ID, 0) = nvl(ARC.GCO_CHAR1_ID, 0)
       and nvl(SPO.GCO_GCO_CHARACTERIZATION_ID, 0) = nvl(ARC.GCO_CHAR2_ID, 0)
       and nvl(SPO.GCO2_GCO_CHARACTERIZATION_ID, 0) = nvl(ARC.GCO_CHAR3_ID, 0)
       and nvl(SPO.GCO3_GCO_CHARACTERIZATION_ID, 0) = nvl(ARC.GCO_CHAR4_ID, 0)
       and nvl(SPO.GCO4_GCO_CHARACTERIZATION_ID, 0) = nvl(ARC.GCO_CHAR5_ID, 0)
       and nvl(SPO.SPO_CHARACTERIZATION_VALUE_1, 0) = nvl(ARC.ARC_CHAR1_VALUE, 0)
       and nvl(SPO.SPO_CHARACTERIZATION_VALUE_2, 0) = nvl(ARC.ARC_CHAR2_VALUE, 0)
       and nvl(SPO.SPO_CHARACTERIZATION_VALUE_3, 0) = nvl(ARC.ARC_CHAR3_VALUE, 0)
       and nvl(SPO.SPO_CHARACTERIZATION_VALUE_4, 0) = nvl(ARC.ARC_CHAR4_VALUE, 0)
       and nvl(SPO.SPO_CHARACTERIZATION_VALUE_5, 0) = nvl(ARC.ARC_CHAR5_VALUE, 0);

    return vAttribQty;
  end GetCompAttribQuantity;

/*--------------------------------------------------------------------------------------------------------------------*/
/**
* Function GetQuantity
* Description :
*             Retourne la quantité disponible selon le bien/stock/emplacement et les caractérisations en tenant compte
*             des attributions éventuelles
*/
  function GetQuantity(
    good_id       in number
  , stock_id      in number
  , location_id   in number
  , charac1_id    in number
  , charac2_id    in number
  , charac3_id    in number
  , charac4_id    in number
  , charac5_id    in number
  , char_val_1    in varchar2
  , char_val_2    in varchar2
  , char_val_3    in varchar2
  , char_val_4    in varchar2
  , char_val_5    in varchar2
  , qtyToReturn   in varchar2
  , aRecordCompID in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type
  )
    return number
  is
    vQuantity  number;
    vAttribQty FAL_NETWORK_LINK.FLN_QTY%type   default 0;
  begin
    vQuantity  :=
      STM_FUNCTIONS.GetQuantity(good_id
                              , stock_id
                              , location_id
                              , charac1_id
                              , charac2_id
                              , charac3_id
                              , charac4_id
                              , charac5_id
                              , char_val_1
                              , char_val_2
                              , char_val_3
                              , char_val_4
                              , char_val_5
                              , qtyToReturn
                               );

    if     qtyToReturn = 'AVAILABLE'
       and aRecordCompID <> 0 then
      vAttribQty  := GetCompAttribQuantity(aRecordCompID => aRecordCompID);
      vQuantity   := vQuantity + vAttribQty;
    end if;

    return vQuantity;
  end GetQuantity;

/*--------------------------------------------------------------------------------------------------------------------*/
/**
* Function InitNbDaysWaitComp
* Description :
*             Retourne le délai d'attente composant du dossier SAV
*
* @author DSA
* @created 11.10.2005
*/
  procedure InitNbDaysWaitComp(
    aRecordID     in     ASA_RECORD.ASA_RECORD_ID%type
  , aRecordCompID in     ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type default null
  , vMaxDelay     out    ASA_RECORD.ARE_NB_DAYS_WAIT_COMP%type
  )
  is
    cursor crComp
    is
      select ARC.*
           , PDT.C_SUPPLY_MODE
           , are.ARE_DATE_REG_REP
           , are.PAC_CUSTOM_PARTNER_ID
        from ASA_RECORD_COMP ARC
           , GCO_PRODUCT PDT
           , ASA_RECORD are
       where ARC.ASA_RECORD_ID = aRecordID
         and PDT.GCO_GOOD_ID = ARC.GCO_COMPONENT_ID
         and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
         and ARC.ASA_RECORD_EVENTS_ID = are.ASA_RECORD_EVENTS_ID
         and ARC.ARC_CDMVT = 1
         and ARC.STM_COMP_STOCK_MVT_ID is null
         and ARC.C_ASA_ACCEPT_OPTION <> '1'
         and nvl(PDT.PDT_STOCK_MANAGEMENT, 0) = 1
         and (   ARC.ASA_RECORD_COMP_ID = aRecordCompID
              or aRecordCompID is null);

    vDelayOP       ASA_RECORD.ARE_NB_DAYS_WAIT_COMP%type;
    vDelay         ASA_RECORD.ARE_NB_DAYS_WAIT_COMP%type;
    vStartDate     date;
    vAvailableDate date;
    vDateSupply    FAL_NETWORK_LINK.FLN_SUPPLY_DELAY%type;
    vAttribKind    number;

    -- Fonction qui renvoie le type d'attribution (nulle ou partielle = 0, stock = 1, appro = 2)
    function KindOfAttrib(aComp in crComp%rowtype)
      return number
    is
      vAttStkQty   FAL_NETWORK_LINK.FLN_QTY%type;
      vAttApproQty FAL_NETWORK_LINK.FLN_QTY%type;
      vResult      number;
    begin
      vResult  := 0;   -- attribution nulle ou partielle

      -- recherche de la quantité attribuée sur stock
      select nvl(sum(fln.fln_qty), 0)
        into vAttStkQty
        from FAL_NETWORK_NEED FAN
           , FAL_NETWORK_LINK FLN
           , DOC_POSITION_DETAIL PDE
           , ASA_RECORD_COMP ARC
       where FLN.FAL_NETWORK_NEED_ID = FAN.FAL_NETWORK_NEED_ID
         and FAN.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
         and PDE.DOC_POSITION_ID = ARC.DOC_ATTRIB_POSITION_ID
         and ARC.ASA_RECORD_COMP_ID = aComp.ASA_RECORD_COMP_ID
         and FLN.STM_STOCK_POSITION_ID is not null;

      -- recherche de la quantité attribuée sur appro
      select nvl(sum(fln.fln_qty), 0)
           , max(trunc(FLN.FLN_SUPPLY_DELAY) )
        into vAttApproQty
           , vDateSupply
        from FAL_NETWORK_NEED FAN
           , FAL_NETWORK_LINK FLN
           , DOC_POSITION_DETAIL PDE
           , ASA_RECORD_COMP ARC
       where FLN.FAL_NETWORK_NEED_ID = FAN.FAL_NETWORK_NEED_ID
         and FAN.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
         and PDE.DOC_POSITION_ID = ARC.DOC_ATTRIB_POSITION_ID
         and ARC.ASA_RECORD_COMP_ID = aComp.ASA_RECORD_COMP_ID
         and FLN.STM_STOCK_POSITION_ID is null;

      -- attribution totale
      if (vAttApproQty + vAttStkQty) = aComp.ARC_QUANTITY then
        if vAttApproQty = 0 then   -- attribution sur stock
          vResult  := 1;
        elsif vAttStkQty = 0 then   -- attribution sur Appro
          vResult  := 2;
        else
          vResult  := 2;   -- attribution sur stock+appro
        end if;
      end if;

      return vResult;
    end KindOfAttrib;
  begin
    vMaxDelay    := 0;
    vDateSupply  := null;

    for tplComp in crComp loop
      vDelay          := 0;
      vDelayOP        := 0;
      vStartDate      := trunc(sysdate);
      vAvailableDate  := null;
      vAttribKind     := KindOfAttrib(tplComp);

      -- Si le composant du dossier SAV est attribué sur stock, on initialise le délai d'attente composant à 0
      if vAttribKind = 1 then
        vDelay  := 0;
      elsif vAttribKind = 2 then
        -- Si le composant du dossier SAV est attribué sur appro, on initialise le délai d'attente composant de la manière suivante :
          -- Délai d'appro  - Date d'enregistrement
        vDelay  :=
          greatest(DOC_DELAY_FUNCTIONS.OpenDaysBetween(aFromDate      => tplComp.ARE_DATE_REG_REP
                                                     , aToDate        => vDateSupply
                                                     , aAdminDomain   => 7
                                                     , aThirdID       => tplComp.PAC_CUSTOM_PARTNER_ID
                                                      )
                 , 0
                  );
      else
        -- Si le composant du dossier SAV n'est pas attribué (ou partiellement attribué),
        -- on initialise le délai d'attente composant selon la règle actuelle :
        if GetQuantity(tplComp.GCO_COMPONENT_ID
                     , tplComp.STM_COMP_STOCK_ID
                     , tplComp.STM_COMP_LOCATION_ID
                     , tplComp.GCO_CHAR1_ID
                     , tplComp.GCO_CHAR2_ID
                     , tplComp.GCO_CHAR3_ID
                     , tplComp.GCO_CHAR4_ID
                     , tplComp.GCO_CHAR5_ID
                     , tplComp.ARC_CHAR1_VALUE
                     , tplComp.ARC_CHAR2_VALUE
                     , tplComp.ARC_CHAR3_VALUE
                     , tplComp.ARC_CHAR4_VALUE
                     , tplComp.ARC_CHAR5_VALUE
                     , 'AVAILABLE'
                     , tplComp.ASA_RECORD_COMP_ID
                      ) >= tplComp.ARC_QUANTITY then
          -- Si quantité disponible en stock >= quantité du besoin -> délai d'attente composant = 0
          vDelay  := 0;
        else
          -- Si quantité disponible en stock < quantité du besoin -> délai d'attente composant =
          -- produit fabriqué : planif. selon cond. Fabr. Par défaut
          if tplComp.C_SUPPLY_MODE = '2' then
            FAL_DELAY_ASSISTANT_DEF.SearchPrevisionalEndDate(tplComp.GCO_COMPONENT_ID, tplComp.ARC_QUANTITY, vStartDate, vAvailableDate, vDelayOP, vDelay);
          else
            -- produit acheté : durée d'appro + durée de contrôle
            select   max(nvl(CPU_SUPPLY_DELAY, 0) + nvl(CPU_CONTROL_DELAY, 0) )
                into vDelay
                from GCO_COMPL_DATA_PURCHASE
               where GCO_GOOD_ID = tplComp.GCO_COMPONENT_ID
                 and (   CPU_DEFAULT_SUPPLIER = 1
                      or PAC_SUPPLIER_PARTNER_ID is null)
                 and rownum = 1
            order by CPU_DEFAULT_SUPPLIER desc;

            vDelayOp  := vDelay;
          end if;
        end if;
      end if;

      -- Mise à jour du délai d'attente du composant si modifié
      if vDelay <> nvl(tplComp.ARC_NB_DAYS_APPRO, 0) then
        update ASA_RECORD_COMP
           set ARC_NB_DAYS_APPRO = vDelay
         where ASA_RECORD_COMP_ID = tplComp.ASA_RECORD_COMP_ID;
      end if;

      vMaxDelay       := greatest(vMaxDelay, vDelay, vDelayOP);
    end loop;
  end InitNbDaysWaitComp;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Copie d'un type de réparation
  */
  procedure DuplicateRepType(aASA_REP_TYPE_ID in out ASA_REP_TYPE.ASA_REP_TYPE_ID%type, aRET_REP_TYPE in ASA_REP_TYPE.RET_REP_TYPE%type)
  is
    tplRepType        ASA_REP_TYPE%rowtype;
    tblRepDescr       TASA_REP_TYPE_DESCR;
    tblRepGood        TASA_REP_TYPE_GOOD;
    tblRepComp        TASA_REP_TYPE_COMP;
    tblRepTask        TASA_REP_TYPE_TASK;
    intIndexGood      integer;
    intIndex          integer;
    vOldRepTypeGoodID ASA_REP_TYPE_GOOD.ASA_REP_TYPE_GOOD_ID%type;
  begin
    -- Duplication du type de réparation
    select *
      into tplRepType
      from ASA_REP_TYPE
     where ASA_REP_TYPE_ID = aASA_REP_TYPE_ID;

    -- Changer la valeur de l'ID du détail et maj des champs A_...
    select INIT_ID_SEQ.nextval
         , substr(aRET_REP_TYPE, 1, 30)
         , '3'   -- statut inactif
         , sysdate
         , PCS.PC_I_LIB_SESSION.GetUserIni
         , null
         , null
      into tplRepType.ASA_REP_TYPE_ID
         , tplRepType.RET_REP_TYPE
         , tplRepType.C_ASA_REP_TYPE_STATUS
         , tplRepType.A_DATECRE
         , tplRepType.A_IDCRE
         , tplRepType.A_DATEMOD
         , tplRepType.A_IDMOD
      from dual;

    insert into ASA_REP_TYPE
         values tplRepType;

    -- Duplication des descriptions
    select DTR.*
    bulk collect into tblRepDescr
      from ASA_REP_TYPE_DESCR DTR
     where DTR.ASA_REP_TYPE_ID = aASA_REP_TYPE_ID;

    if tblRepDescr.count > 0 then
      for intIndex in tblRepDescr.first .. tblRepDescr.last loop
        select tplRepType.ASA_REP_TYPE_ID
             , PCS.PC_I_LIB_SESSION.GetUserIni
             , sysdate
             , null
             , null
          into tblRepDescr(intIndex).ASA_REP_TYPE_ID
             , tblRepDescr(intIndex).A_IDCRE
             , tblRepDescr(intIndex).A_DATECRE
             , tblRepDescr(intIndex).A_IDMOD
             , tblRepDescr(intIndex).A_DATEMOD
          from dual;
      end loop;
    end if;

    if tblRepDescr.count > 0 then
      for intIndex in tblRepDescr.first .. tblRepDescr.last loop
        insert into ASA_REP_TYPE_DESCR
             values tblRepDescr(intIndex);
      end loop;
    end if;

    -- Duplication des biens
    select RTG.*
    bulk collect into tblRepGood
      from ASA_REP_TYPE_GOOD RTG
     where RTG.ASA_REP_TYPE_ID = aASA_REP_TYPE_ID;

    if tblRepGood.count > 0 then
      for intIndexGood in tblRepGood.first .. tblRepGood.last loop
        vOldRepTypeGoodID  := tblRepGood(intIndexGood).ASA_REP_TYPE_GOOD_ID;

        select INIT_ID_SEQ.nextval
             , tplRepType.ASA_REP_TYPE_ID
             , PCS.PC_I_LIB_SESSION.GetUserIni
             , sysdate
             , null
             , null
          into tblRepGood(intIndexGood).ASA_REP_TYPE_GOOD_ID
             , tblRepGood(intIndexGood).ASA_REP_TYPE_ID
             , tblRepGood(intIndexGood).A_IDCRE
             , tblRepGood(intIndexGood).A_DATECRE
             , tblRepGood(intIndexGood).A_IDMOD
             , tblRepGood(intIndexGood).A_DATEMOD
          from dual;

        insert into ASA_REP_TYPE_GOOD
             values tblRepGood(intIndexGood);

        -- Duplication des composants
        select RTC.*
        bulk collect into tblRepComp
          from ASA_REP_TYPE_COMP RTC
         where RTC.ASA_REP_TYPE_GOOD_ID = vOldRepTypeGoodID;

        if tblRepComp.count > 0 then
          for intIndex in tblRepComp.first .. tblRepComp.last loop
            select tblRepGood(intIndexGood).ASA_REP_TYPE_GOOD_ID
                 , INIT_ID_SEQ.nextval
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , sysdate
                 , null
                 , null
              into tblRepComp(intIndex).ASA_REP_TYPE_GOOD_ID
                 , tblRepComp(intIndex).ASA_REP_TYPE_COMP_ID
                 , tblRepComp(intIndex).A_IDCRE
                 , tblRepComp(intIndex).A_DATECRE
                 , tblRepComp(intIndex).A_IDMOD
                 , tblRepComp(intIndex).A_DATEMOD
              from dual;
          end loop;
        end if;

        if tblRepComp.count > 0 then
          for intIndex in tblRepComp.first .. tblRepComp.last loop
            insert into ASA_REP_TYPE_COMP
                 values tblRepComp(intIndex);
          end loop;
        end if;

        -- Duplication des opérations
        select RTT.*
        bulk collect into tblRepTask
          from ASA_REP_TYPE_TASK RTT
         where RTT.ASA_REP_TYPE_GOOD_ID = vOldRepTypeGoodID;

        if tblRepTask.count > 0 then
          for intIndex in tblRepTask.first .. tblRepTask.last loop
            select tblRepGood(intIndexGood).ASA_REP_TYPE_GOOD_ID
                 , INIT_ID_SEQ.nextval
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , sysdate
                 , null
                 , null
              into tblRepTask(intIndex).ASA_REP_TYPE_GOOD_ID
                 , tblRepTask(intIndex).ASA_REP_TYPE_TASK_ID
                 , tblRepTask(intIndex).A_IDCRE
                 , tblRepTask(intIndex).A_DATECRE
                 , tblRepTask(intIndex).A_IDMOD
                 , tblRepTask(intIndex).A_DATEMOD
              from dual;
          end loop;
        end if;

        if tblRepTask.count > 0 then
          for intIndex in tblRepTask.first .. tblRepTask.last loop
            insert into ASA_REP_TYPE_TASK
                 values tblRepTask(intIndex);
          end loop;
        end if;
      end loop;
    end if;

    aASA_REP_TYPE_ID  := tplRepType.ASA_REP_TYPE_ID;
  end DuplicateRepType;

  /**
  *  procedure GetGoodDescription
  *  Description
  *    Recherche les descriptions pour le SAV
  */
  procedure GetGoodDescription(
    iGoodID     in     GCO_GOOD.GCO_GOOD_ID%type
  , iLangID     in     PCS.PC_LANG.PC_LANG_ID%type
  , oShortDescr out    ASA_INTERVENTION_DETAIL.AID_SHORT_DESCR%type
  , oLongDescr  out    ASA_INTERVENTION_DETAIL.AID_LONG_DESCR%type
  , oFreeDescr  out    ASA_INTERVENTION_DETAIL.AID_FREE_DESCR%type
  )
  is
    lnStockId            STM_STOCK.STM_STOCK_ID%type;
    lnLocationId         STM_LOCATION.STM_LOCATION_ID%type;
    lvReference          GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lvSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    lvEanCode            GCO_GOOD.GOO_EAN_CODE%type;
    lvEanUCC14Code       GCO_GOOD.GOO_EAN_UCC14_CODE%type;
    lvHIBCPrimaryCode    GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type;
    lvDicUnitOfMeasure   GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
    lnConvertFactor      GCO_COMPL_DATA_STOCK.CDA_CONVERSION_FACTOR%type;
    lnNumberOfDecimal    GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lnQuantity           GCO_COMPL_DATA_SUBCONTRACT.CSU_ECONOMICAL_QUANTITY%type;
  begin
    GCO_I_LIB_COMPL_DATA.GetComplementaryData(iGoodID               => iGoodID
                                            , iAdminDomain          => '7'
                                            , iThirdID              => null
                                            , iLangID               => iLangID
                                            , iOperationID          => null
                                            , iTransProprietor      => 0
                                            , iComplDataID          => null
                                            , oStockId              => lnStockId
                                            , oLocationId           => lnLocationId
                                            , oReference            => lvReference
                                            , oSecondaryReference   => lvSecondaryReference
                                            , oShortDescription     => oShortDescr
                                            , oLongDescription      => oLongDescr
                                            , oFreeDescription      => oFreeDescr
                                            , oEanCode              => lvEanCode
                                            , oEanUCC14Code         => lvEanUCC14Code
                                            , oHIBCPrimaryCode      => lvHIBCPrimaryCode
                                            , oDicUnitOfMeasure     => lvDicUnitOfMeasure
                                            , oConvertFactor        => lnConvertFactor
                                            , oNumberOfDecimal      => lnNumberOfDecimal
                                            , oQuantity             => lnQuantity
                                             );
  end GetGoodDescription;
end ASA_FUNCTIONS;
