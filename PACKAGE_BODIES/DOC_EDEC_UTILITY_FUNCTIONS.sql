--------------------------------------------------------
--  DDL for Package Body DOC_EDEC_UTILITY_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDEC_UTILITY_FUNCTIONS" 
is
  /**
  * function GetNextPosNumber
  * Description
  *    Recherche du prochain numéro de position
  * @created fp 14.08.2008
  * @lastUpdate
  * @public
  * @param aHeaderID : entête du document EDEC
  * @return prochain no de position
  */
  function GetNextPosNumber(aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type)
    return DOC_EDEC_POSITION.DEP_POS_NUMBER%type
  is
    vResult DOC_EDEC_POSITION.DEP_POS_NUMBER%type;
  begin
    select nvl(max(DEP_POS_NUMBER), 0)
      into vResult
      from DOC_EDEC_POSITION
     where DOC_EDEC_HEADER_ID = aHeaderID;

    return vResult + cPositionNumberStep;
  end GetNextPosNumber;

  /**
  * function GetNewHeaderNumber
  * Description
  *    Recherche du prochain numéro d'entête de la déclaration EDEC
  */
  function GetNewHeaderNumber
    return DOC_EDEC_HEADER.DEH_TRADER_DECLARATION_NUMBER%type
  is
    vNewNumber        DOC_EDEC_HEADER.DEH_TRADER_DECLARATION_NUMBER%type;
    vGaugeNumberingID DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
  begin
    -- Rechercher le gabarit pour la numérotation
    select nvl(max(DOC_GAUGE_NUMBERING_ID), -1)
      into vGaugeNumberingID
      from DOC_GAUGE_NUMBERING
     where GAN_DESCRIBE = PCS.PC_CONFIG.GetConfig('DOC_EDEC_NUMBERING');

    -- Demander un nouveau n°
    if vGaugeNumberingID <> -1 then
      DOC_DOCUMENT_FUNCTIONS.GetDocumentNumber(aGaugeID => null, aGaugeNumberingID => vGaugeNumberingID, aDocNumber => vNewNumber);
    else
      vNewNumber  := null;
    end if;

    return vNewNumber;
  end GetNewHeaderNumber;

  /**
  * procedure EdecProtect
  * Description
  *    Gestion des protections sur les déclaration EDEC
  */
  procedure EdecProtect(iHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, iProtect in integer default 1, ioSession in out string)
  is
  begin
    if     (iProtect = 1)
       and ioSession is null then
      select DBMS_SESSION.unique_session_id
        into ioSession
        from dual;
    end if;

    update DOC_EDEC_HEADER
       set DEH_PROTECTED = iProtect
         , DEH_SESSION_ID = ioSession
     where DOC_EDEC_HEADER_ID = iHeaderID;
  end EdecProtect;

  /**
  * procedure EdecProtectAutoCommit
  * Description
  *    Gestion des protections sur les déclaration EDEC en transaction autonome. Impose l'assignation d'une session unique provenant
  *    de la session Oracle appelant.
  */
  procedure EdecProtectAutoCommit(iHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, iProtect in integer default 1, ioSession in out string)
  is
    pragma autonomous_transaction;
  begin
    if     (iProtect = 1)
       and ioSession is null then
      PCS.ra('Parent unique Oracle session requiert !');
    end if;

    EdecProtect(iHeaderID, iProtect, ioSession);
    commit;   -- Indispensable en transaction autonome
  end EdecProtectAutoCommit;

  /**
  * procedure DeleteEdec
  * Description
  *   Efface toutes les données(tables enfants)pour une entête de déclaration EDEC
  */
  procedure DeleteEdec(aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type)
  is
  begin
    delete from DOC_EDEC_CONTAINER
          where DOC_EDEC_HEADER_ID = aHeaderID;

    delete from DOC_EDEC_ADDRESSES
          where DOC_EDEC_HEADER_ID = aHeaderID;

    delete from DOC_EDEC_DOCUMENT_MENTION
          where DOC_EDEC_HEADER_ID = aHeaderID;

    delete from DOC_EDEC_HEADER_DOCUMENTS
          where DOC_EDEC_HEADER_ID = aHeaderID;

    for tplPos in (select DOC_EDEC_POSITION_ID
                     from DOC_EDEC_POSITION
                    where DOC_EDEC_HEADER_ID = aHeaderID) loop
      delete from DOC_EDEC_DANGEROUS_GOOD
            where DOC_EDEC_POSITION_ID = tplPos.DOC_EDEC_POSITION_ID;

      delete from DOC_EDEC_NOTIFICATION
            where DOC_EDEC_POSITION_ID = tplPos.DOC_EDEC_POSITION_ID;

      delete from DOC_EDEC_PACKAGING
            where DOC_EDEC_POSITION_ID = tplPos.DOC_EDEC_POSITION_ID;

      delete from DOC_EDEC_PERMIT
            where DOC_EDEC_POSITION_ID = tplPos.DOC_EDEC_POSITION_ID;

      delete from DOC_EDEC_POSITION_MENTION
            where DOC_EDEC_POSITION_ID = tplPos.DOC_EDEC_POSITION_ID;

      delete from DOC_EDEC_POSITION_DETAIL
            where DOC_EDEC_POSITION_ID = tplPos.DOC_EDEC_POSITION_ID;

      delete from DOC_EDEC_POSITION_DOCUMENTS
            where DOC_EDEC_POSITION_ID = tplPos.DOC_EDEC_POSITION_ID;
    end loop;

    delete from DOC_EDEC_POSITION
          where DOC_EDEC_HEADER_ID = aHeaderID;

    delete from DOC_EDEC_HEADER
          where DOC_EDEC_HEADER_ID = aHeaderID;
  end DeleteEdec;

  /**
  * procedure DeleteEdecAddresses
  * Description
  *   Efface toutes les adresses d'une déclaration EDEC
  */
  procedure DeleteEdecAddresses(aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type)
  is
  begin
    -- Effacement des adresses
    delete from DOC_EDEC_ADDRESSES
          where DOC_EDEC_HEADER_ID = aHeaderID;
  end DeleteEdecAddresses;

  /**
  * procedure DeleteEdecPos
  * Description
  *   Efface toutes les positions de la table DOC_EDEC_POSITION ainsi que ses enfants
  */
  procedure DeleteEdecPos(aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type)
  is
  begin
    -- Effacer les détails et les emballages
    for tplPos in (select   DOC_EDEC_POSITION_ID
                       from DOC_EDEC_POSITION
                      where DOC_EDEC_HEADER_ID = aHeaderID
                   order by 1) loop
      -- Effacer les détails
      delete from DOC_EDEC_POSITION_DETAIL
            where DOC_EDEC_POSITION_ID = tplPos.DOC_EDEC_POSITION_ID;

      -- Effacer les emballages
      delete from DOC_EDEC_PACKAGING
            where DOC_EDEC_POSITION_ID = tplPos.DOC_EDEC_POSITION_ID;
    end loop;

    -- Effacer les positions
    delete from DOC_EDEC_POSITION
          where DOC_EDEC_HEADER_ID = aHeaderID;
  end DeleteEdecPos;

  /**
  * function GetCustomsElement
  * Description
  *   Préparation de la liste des données douanières
  */
  function GetCustomsElement(aCntryID PCS.PC_CNTRY.PC_CNTRY_ID%type)
    return TTblCustomsElements pipelined
  is
    cursor crCustomsElement(cGoodID GCO_GOOD.GCO_GOOD_ID%type, cCntryID PCS.PC_CNTRY.PC_CNTRY_ID%type)
    is
      select   CUS.*
          from GCO_CUSTOMS_ELEMENT CUS
         where CUS.GCO_GOOD_ID = cGoodID
           and CUS.C_CUSTOMS_ELEMENT_TYPE = 'EXPORT'
           and nvl(CUS.PC_CNTRY_ID, cCntryID) = cCntryID
      order by CUS.PC_CNTRY_ID nulls last;

    tplCustomsElement crCustomsElement%rowtype;
  begin
    -- Balayer les biens (regroupés) des positions
    for tplPosition in (select   POS.GCO_GOOD_ID
                            from DOC_POSITION POS
                               , (select COM_LIST_ID_TEMP_ID as DOC_POSITION_ID
                                    from COM_LIST_ID_TEMP
                                   where LID_CODE = 'DOC_POSITION_ID') POS_LIST
                           where POS_LIST.DOC_POSITION_ID = POS.DOC_POSITION_ID
                        group by POS.GCO_GOOD_ID) loop
      -- Récuperer la donnée de douane du bien
      -- Cascade
      --   1. Donnée douane pour le pays sélectionné
      --   2. Donnée douane sans pays défini
      open crCustomsElement(tplPosition.GCO_GOOD_ID, aCntryID);

      fetch crCustomsElement
       into tplCustomsElement;

      -- Si le bien ne possède pas de donnée de douane
      -- Ajouter une donnée vide
      if crCustomsElement%notfound then
        tplCustomsElement.GCO_GOOD_ID           := tplPosition.GCO_GOOD_ID;
        tplCustomsElement.CUS_CUSTONS_POSITION  := 'UNDEFINED';
      end if;

      pipe row(tplCustomsElement);

      close crCustomsElement;
    end loop;
  end GetCustomsElement;

  /**
  * function GetEdecCode
  * Description
  *   Récupere le type d'EDEC - E100 ou E101 selon les méthodes d'export passées
  */
  function GetEdecCode(
    aExportMethods in varchar2 default null
  , aHeaderID      in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type default null
  , aDocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPackingListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type default null
  , aThirdID       in PAC_THIRD.PAC_THIRD_ID%type default null
  )
    return varchar2
  is
    vEdecCode   DOC_EDI_TYPE.C_EDI_METHOD%type   default null;
    vExportList varchar2(4000)                   default null;
  begin
    if aExportMethods is not null then
      vExportList  := aExportMethods;
    else
      vExportList  := GetEdecExportMethods(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID, aThirdID => aThirdID);
    end if;

    if vExportList is not null then
      select min(DET.C_EDI_METHOD)
        into vEdecCode
        from DOC_EDI_TYPE DET
           , (select distinct column_value exp_method
                         from table(PCS.CHARLISTTOTABLE(vExportList, ';') ) ) MTH
       where MTH.EXP_METHOD is not null
         and MTH.EXP_METHOD = DET.DET_NAME
         and DET.C_EDI_METHOD in('E100', 'E101')
         and DET.PC_EXCHANGE_SYSTEM_ID is not null;
    end if;

    -- Renvoi le type d'export EDEC (E100 ou E101)
    return vEdecCode;
  end GetEdecCode;

  /**
  * function GetEdecExportMethods
  * Description
  *   Récupere le type d'EDEC - E100 ou E101 selon les définitions du client
  *     cette fonction travaille avec 4 possibilités de recherche
  *     (interface edec, document, envoi ou tiers)
  */
  function GetEdecExportMethods(
    aHeaderID      in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type default null
  , aDocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPackingListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type default null
  , aThirdID       in PAC_THIRD.PAC_THIRD_ID%type default null
  )
    return varchar2
  is
    vExportList    varchar2(4000)                                  default null;
    vDocumentID    DOC_DOCUMENT.DOC_DOCUMENT_ID%type               default null;
    vPackingListID DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type       default null;
    vCusDelivID    PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type   default null;
    vCusAciID      PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type   default null;
  begin
    vDocumentID     := aDocumentID;
    vPackingListID  := aPackingListID;

    -- Si ID interface edec est passé, rechercher l'origine de cette interface(document ou envoi)
    if aHeaderID is not null then
      select DOC_DOCUMENT_ID
           , DOC_PACKING_LIST_ID
        into vDocumentID
           , vPackingListID
        from DOC_EDEC_HEADER
       where DOC_EDEC_HEADER_ID = aHeaderID;
    end if;

    -- Si ID document renseigné, rechercher les clients (livraison et facturation) sur le document
    if vDocumentID is not null then
      select DMT.PAC_THIRD_ACI_ID
           , DMT.PAC_THIRD_DELIVERY_ID
           , GAS.GAS_EDI_EXPORT_METHOD
        into vCusAciID
           , vCusDelivID
           , vExportList
        from DOC_DOCUMENT DMT
           , DOC_GAUGE_STRUCTURED GAS
       where DMT.DOC_DOCUMENT_ID = vDocumentID
         and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;
    -- Si ID envoi renseigné, rechercher les clients (livraison et facturation) sur l'envoir
    elsif vPackingListID is not null then
      select PAC_THIRD_ACI_ID
           , PAC_THIRD_DELIVERY_ID
        into vCusAciID
           , vCusDelivID
        from DOC_PACKING_LIST
       where DOC_PACKING_LIST_ID = vPackingListID;

      -- récupération des méthodes d'export trouvées sur l'ensemble des gabarits
      for tplGasEdiMethod in (select distinct GAS.GAS_EDI_EXPORT_METHOD
                                         from DOC_PACKING_PARCEL_POS PAP
                                            , DOC_DOCUMENT DMT
                                            , DOC_GAUGE_STRUCTURED GAS
                                        where PAP.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                                          and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                                          and PAP.DOC_PACKING_LIST_ID = vPackingListID) loop
        vExportList  := vExportList || ';' || trim(both ';' from tplGasEdiMethod.GAS_EDI_EXPORT_METHOD);
      end loop;
    -- Si ID client renseigné, utiliser celui-ci pour les clients (livraison et facturation)
    elsif aThirdID is not null then
      vCusDelivID  := aThirdID;
      vCusAciID    := aThirdID;
    end if;

    -- Récuperer les méthodes d'export du client de livraison
    if vCusDelivID is not null then
      begin
        select vExportList || ';' || trim(both ';' from CUS_DATA_EXPORT)
          into vExportList
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = vCusDelivID;
      exception
        when no_data_found then
          fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                            , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('L''identifiant du client de livraison est incorrect !')
                                            , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                            , iv_cause         => 'CustomerExportData'
                                             );
      end;
    end if;

    -- Récuperer les méthodes d'export du client de facturation
    if     (vCusAciID is not null)
       and (vCusAciID <> vCusDelivID) then
      begin
        select vExportList || ';' || trim(both ';' from CUS_DATA_EXPORT)
          into vExportList
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = vCusAciID;
      exception
        when no_data_found then
          fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                            , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('L''identifiant du client de facturation est incorrect !')
                                            , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                            , iv_cause         => 'CustomerExportData'
                                             );
      end;
    end if;

    -- Renvoi les méthodes d'export
    return vExportList;
  end GetEdecExportMethods;

  /**
  * procedure CreateDischErrorLog
  * Description
  *   Création d'une ligne log à la suite de la décharge EDEC
  */
  procedure CreateDischErrorLog(aID in COM_LIST_ID_TEMP.COM_LIST_ID_TEMP_ID%type, aError in varchar2)
  is
  begin
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_DESCRIPTION
                )
         values (aID
               , 'EDEC_DISCHARGE_ERRORS'
               , aError
                );
  end CreateDischErrorLog;

  /**
  * procedure DeleteDischErrorLog
  * Description
  *   Effacer toutes les données log à la suite de la décharge EDEC
  */
  procedure DeleteDischErrorLog
  is
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'EDEC_DISCHARGE_ERRORS';
  end DeleteDischErrorLog;
end DOC_EDEC_UTILITY_FUNCTIONS;
