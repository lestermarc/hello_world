--------------------------------------------------------
--  DDL for Package Body GCO_LIB_CHARACTERIZATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_LIB_CHARACTERIZATION" 
is
  gcGCO_RETEST_MODE constant varchar2(1) := PCS.PC_CONFIG.GetConfigUpper('GCO_RETEST_MODE');

  /**
  * Description : Méthode qulCounter retourne les caractérisations associées à un bien donné
  */
  procedure GetCharacterizationsID(
    iGoodId         in     GCO_GOOD.GCO_GOOD_ID%type
  , iMovementKindID in     STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  , iGaugeID        in     DOC_POSITION.DOC_POSITION_ID%type
  , iGabChar        in     number
  , iAdminDomain    in     varchar2
  , ioCharactID_1   in out DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type
  , ioCharactID_2   in out DOC_POSITION_DETAIL.GCO_GCO_CHARACTERIZATION_ID%type
  , ioCharactID_3   in out DOC_POSITION_DETAIL.GCO2_GCO_CHARACTERIZATION_ID%type
  , ioCharactID_4   in out DOC_POSITION_DETAIL.GCO3_GCO_CHARACTERIZATION_ID%type
  , ioCharactID_5   in out DOC_POSITION_DETAIL.GCO4_GCO_CHARACTERIZATION_ID%type
  )
  is
    lCharacType1         gco_characterization.C_CHARACT_TYPE%type;
    lCharacType2         gco_characterization.C_CHARACT_TYPE%type;
    lCharacType3         gco_characterization.C_CHARACT_TYPE%type;
    lCharacType4         gco_characterization.C_CHARACT_TYPE%type;
    lCharacType5         gco_characterization.C_CHARACT_TYPE%type;
    lCharStk1            gco_characterization.cha_stock_management%type;
    lCharStk2            gco_characterization.cha_stock_management%type;
    lCharStk3            gco_characterization.cha_stock_management%type;
    lCharStk4            gco_characterization.cha_stock_management%type;
    lCharStk5            gco_characterization.cha_stock_management%type;
    lMovementSort        stm_movement_kind.c_movement_sort%type;
    lGestPiece           number(1)                                            default 0;
    lAllCharacterization DOC_GAUGE_STRUCTURED.GAS_ALL_CHARACTERIZATION%type;
  begin
    -- recherche des id de caractérisation
    if    (iGabChar = 1)
       or iMovementKindId <> 0 then
      if     iGaugeId is not null
         and nvl(iMovementKindId, 0) = 0 then
        lMovementSort  := null;

        select max(GAS.GAS_ALL_CHARACTERIZATION)
          into lAllCharacterization
          from DOC_GAUGE_STRUCTURED GAS
         where GAS.DOC_GAUGE_ID = iGaugeID;

        /* Gestion des caractérisations non morphologique dans les documents sans
          mouvements de stock. On recherche le type de mouvement en fonction du
          domaine. */
        if     PCS.PC_CONFIG.GetBooleanConfig('DOC_CHARACTERIZATION_MODE')
           and (lAllCharacterization = 1) then
          if (iAdminDomain = DOC_I_LIB_CONSTANT.gcAdminDomainPurchase) then   /* Achat */
            lMovementSort  := STM_I_LIB_CONSTANT.gcMovementSortInput;
          elsif(iAdminDomain = DOC_I_LIB_CONSTANT.gcAdminDomainSale) then   /* Vente */
            lMovementSort  := STM_I_LIB_CONSTANT.gcMovementSortOutput;
          end if;
        end if;
      elsif     iGaugeId is null
            and iMovementKindId is null
            and iAdminDomain is not null then
        if (iAdminDomain = DOC_I_LIB_CONSTANT.gcAdminDomainPurchase) then   /* Achat */
          lMovementSort  := STM_I_LIB_CONSTANT.gcMovementSortInput;
        elsif(iAdminDomain = DOC_I_LIB_CONSTANT.gcAdminDomainSale) then   /* Vente */
          lMovementSort  := STM_I_LIB_CONSTANT.gcMovementSortOutput;
        end if;
      elsif iMovementKindId is not null then
        select max(c_movement_sort)
          into lMovementSort
          from stm_movement_kind
         where stm_movement_kind_id = iMovementKindId;
      end if;

      -- recherche des id de caractérisations du nouveau détail de position
      GetListOfCharacterization(iGoodId
                              , iGabChar
                              , lMovementSort
                              , iAdminDomain
                              , ioCharactID_1
                              , ioCharactID_2
                              , ioCharactID_3
                              , ioCharactID_4
                              , ioCharactID_5
                              , lCharacType1
                              , lCharacType2
                              , lCharacType3
                              , lCharacType4
                              , lCharacType5
                              , lCharStk1
                              , lCharStk2
                              , lCharStk3
                              , lCharStk4
                              , lCharStk5
                              , lGestPiece
                               );
    end if;
  end GetCharacterizationsID;

  /**
  * Description
  *      Recherche des id de caractérization d'un bien
  */
  procedure GetListOfCharacterization(
    iGoodId          in     number
  , iCharManagement  in     number
  , iMovementSort    in     varchar2
  , iAdminDomain     in     varchar2
  , oCharac1Id       out    number
  , oCharac2Id       out    number
  , oCharac3Id       out    number
  , oCharac4Id       out    number
  , oCharac5Id       out    number
  , oCharacType1     out    varchar2
  , oCharacType2     out    varchar2
  , oCharacType3     out    varchar2
  , oCharacType4     out    varchar2
  , oCharacType5     out    varchar2
  , oCharacStk1      out    number
  , oCharacStk2      out    number
  , oCharacStk3      out    number
  , oCharacStk4      out    number
  , oCharacStk5      out    number
  , oPieceManagement out    number
  )
  is
    cursor lcurCharlist(iGoodId number, iAdminDomain varchar2, iMovementSort varchar2, iCharManagement number)
    is
      select   GCO_CHARACTERIZATION_ID
             , C_CHARACT_TYPE
             , decode(PDT_STOCK_MANAGEMENT, 1, CHA_STOCK_MANAGEMENT, 0) CHA_STOCK_MANAGEMENT
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where PDT.GCO_GOOD_ID = iGoodId
           and CHA.GCO_GOOD_ID = pdt.GCO_GOOD_ID
           and (    (    decode(PDT_STOCK_MANAGEMENT, 1, CHA_STOCK_MANAGEMENT, 0) = 1
                     and iMovementSort is not null)
                or (    decode(PDT_STOCK_MANAGEMENT, 1, CHA_STOCK_MANAGEMENT, 0) = 0
                    and iMovementSort = STM_I_LIB_CONSTANT.gcMovementSortOutput
                    and iAdminDomain in(DOC_I_LIB_CONSTANT.gcAdminDomainSale, DOC_I_LIB_CONSTANT.gcAdminDomainStock)
                    and iCharManagement = 1
                   )
                or (    decode(PDT_STOCK_MANAGEMENT, 1, CHA_STOCK_MANAGEMENT, 0) = 0
                    and iMovementSort = STM_I_LIB_CONSTANT.gcMovementSortInput
                    and iAdminDomain = DOC_I_LIB_CONSTANT.gcAdminDomainSale
                    and iCharManagement = 1
                   )
                or (    C_CHARACT_TYPE in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypeCharacteristic)
                    and (   iMovementSort is not null
                         or iCharManagement = 1)
                   )
               )
      order by GCO_CHARACTERIZATION_ID;

    ltplCharlist lcurCharlist%rowtype;
  begin
    oPieceManagement  := 0;

    open lcurCharlist(iGoodId, iAdminDomain, iMovementSort, iCharManagement);

    fetch lcurCharlist
     into ltplCharlist;

    if lcurCharlist%found then
      oCharac1Id    := ltplCharlist.GCO_CHARACTERIZATION_ID;
      oCharacType1  := ltplCharlist.C_CHARACT_TYPE;
      oCharacStk1   := ltplCharlist.CHA_STOCK_MANAGEMENT;

      if ltplCharlist.C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
        oPieceManagement  := 1;
      end if;
    end if;

    fetch lcurCharlist
     into ltplCharlist;

    if lcurCharlist%found then
      oCharac2Id    := ltplCharlist.GCO_CHARACTERIZATION_ID;
      oCharacType2  := ltplCharlist.C_CHARACT_TYPE;
      oCharacStk2   := ltplCharlist.CHA_STOCK_MANAGEMENT;

      if ltplCharlist.C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
        oPieceManagement  := 1;
      end if;
    end if;

    fetch lcurCharlist
     into ltplCharlist;

    if lcurCharlist%found then
      oCharac3Id    := ltplCharlist.GCO_CHARACTERIZATION_ID;
      oCharacType3  := ltplCharlist.C_CHARACT_TYPE;
      oCharacStk3   := ltplCharlist.CHA_STOCK_MANAGEMENT;

      if ltplCharlist.C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
        oPieceManagement  := 1;
      end if;
    end if;

    fetch lcurCharlist
     into ltplCharlist;

    if lcurCharlist%found then
      oCharac4Id    := ltplCharlist.GCO_CHARACTERIZATION_ID;
      oCharacType4  := ltplCharlist.C_CHARACT_TYPE;
      oCharacStk4   := ltplCharlist.CHA_STOCK_MANAGEMENT;

      if ltplCharlist.C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
        oPieceManagement  := 1;
      end if;
    end if;

    fetch lcurCharlist
     into ltplCharlist;

    if lcurCharlist%found then
      oCharac5Id    := ltplCharlist.GCO_CHARACTERIZATION_ID;
      oCharacType5  := ltplCharlist.C_CHARACT_TYPE;
      oCharacStk5   := ltplCharlist.CHA_STOCK_MANAGEMENT;

      if ltplCharlist.C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
        oPieceManagement  := 1;
      end if;
    end if;

    close lcurCharlist;
  end GetListOfCharacterization;

  /**
  * Description
  *     Méthode qui retourne les caractérisations associées à un bien donné
  */
  procedure GetAllCharactID(
    iGoodId      in     GCO_GOOD.GCO_GOOD_ID%type
  , iNoStkChar   in     number default 1
  , oCharactID_1 out    DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type
  , oCharactID_2 out    DOC_POSITION_DETAIL.GCO_GCO_CHARACTERIZATION_ID%type
  , oCharactID_3 out    DOC_POSITION_DETAIL.GCO2_GCO_CHARACTERIZATION_ID%type
  , oCharactID_4 out    DOC_POSITION_DETAIL.GCO3_GCO_CHARACTERIZATION_ID%type
  , oCharactID_5 out    DOC_POSITION_DETAIL.GCO4_GCO_CHARACTERIZATION_ID%type
  )
  is
  begin
    for ltplChar in (select   GCO_CHARACTERIZATION_ID
                         from GCO_CHARACTERIZATION CHA
                            , GCO_PRODUCT PDT
                        where PDT.GCO_GOOD_ID = iGoodId
                          and CHA.GCO_GOOD_ID = pdt.GCO_GOOD_ID
                          and (   decode(PDT_STOCK_MANAGEMENT, 1, CHA_STOCK_MANAGEMENT, 0) = 1
                               or iNoStkChar is not null)
                     order by GCO_CHARACTERIZATION_ID) loop
      case
        when oCharactID_1 is null then
          oCharactID_1  := ltplChar.GCO_CHARACTERIZATION_ID;
        when oCharactID_2 is null then
          oCharactID_2  := ltplChar.GCO_CHARACTERIZATION_ID;
        when oCharactID_3 is null then
          oCharactID_3  := ltplChar.GCO_CHARACTERIZATION_ID;
        when oCharactID_4 is null then
          oCharactID_4  := ltplChar.GCO_CHARACTERIZATION_ID;
        when oCharactID_5 is null then
          oCharactID_5  := ltplChar.GCO_CHARACTERIZATION_ID;
      end case;
    end loop;
  end GetAllCharactID;

  /**
  * Description
  *   Supprime le prefixe et le suffixe à la valeur de caracterisation retournée
  */
  function getValueWithoutPrefix(iValue in varchar2, iPrefix in GCO_CHARACTERIZATION.CHA_PREFIXE%type, iSuffix in GCO_CHARACTERIZATION.CHA_SUFFIXE%type)
    return number
  is
    lResult GCO_CHARACTERIZATION.CHA_LAST_USED_INCREMENT%type;
  begin
    begin
      if     iPrefix is not null
         and iSuffix is not null then
        lResult  := to_number(substr(substr(iValue, 1, length(iValue) - length(iSuffix) ), length(iPrefix) + 1) );
      elsif     iPrefix is not null
            and iSuffix is null then
        lResult  := to_number(substr(iValue, length(iPrefix) + 1) );
      elsif     iPrefix is null
            and iSuffix is not null then
        lResult  := to_number(substr(iValue, 1, length(iValue) - length(iSuffix) ) );
      elsif     iPrefix is null
            and iSuffix is null then
        lResult  := iValue;
      end if;
    exception
      when others then
        lResult  := null;
    end;

    return lResult;
  end getValueWithoutPrefix;

  /**
  * Description
  *   retourne la valeur effective d'un préfixe ou suffixe de caractérisation
  *   en interprétant les marcro qu'il contient
  */
  function prefixApplyMacro(iText in GCO_CHARACTERIZATION.CHA_PREFIXE%type)
    return GCO_CHARACTERIZATION.CHA_PREFIXE%type
  is
    lCounter integer;
    lResult  varchar2(100);
    lInMacro boolean       := false;
    lMacro   varchar2(100);
  begin
    if iText is not null then
      for lCounter in 1 .. length(iText) loop
        if lInMacro then
          if substr(iText, lCounter, 1) = ']' then
            lInMacro  := false;
            lResult   := lResult || prefixInterpretMacro(lMacro);
            lMacro    := '';
          else
            lMacro  := lMacro || substr(iText, lCounter, 1);
          end if;
        else
          if substr(iText, lCounter, 1) = '[' then
            lInMacro  := true;
          else
            lResult  := lResult || substr(iText, lCounter, 1);
          end if;
        end if;
      end loop;
    end if;

    return lResult;
  end prefixApplyMacro;

  /**
  * Description
  *   retourne l'évaluation d'une expression lMacro
  */
  function prefixInterpretMacro(iMacro in varchar2)
    return varchar2
  is
    lResult GCO_CHARACTERIZATION.CHA_PREFIXE%type;
  begin
    case
      when upper(iMacro) = 'USER' then
        lResult  := PCS.PC_I_LIB_SESSION.GetUserIni;
      when upper(iMacro) = 'OWNER' then
        lResult  := PCS.PC_I_LIB_SESSION.GetCompanyOwner;
      when upper(iMacro) = 'COMPANY' then
        select COM_NAME
          into lResult
          from PCS.PC_COMP
         where PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;
      when substr(upper(iMacro), 1, 5) = 'TIME:' then
        begin
          return to_char(sysdate, substr(iMacro, 6) );
        exception
          when others then
            raise_application_error(-20000
                                  , PCS.PC_FUNCTIONS.TranslateWord('PCS - Prefixe/Suffixe de caractérisation - Mauvaise lMacro de type TIME : ') || iMacro
                                   );
        end;
      else
        raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Prefixe/Suffixe de caractérisation - Macro mal implémentée : ') || iMacro);
    end case;

    return lResult;
  end prefixInterpretMacro;

  /**
  * function GetVersioningIndice
  * Description
  *   retourne l'indice de la caracterisation portant le versioning
  * @created fpe 19.02.2014
  * @updated
  * @public
  * @param iCharac1Id .. iCharac5Id : retour, id de caractérisation du bien
  * @return
  */
  function GetVersioningIndice(
    iGoodID     in GCO_GOOD.GCO_GOOD_ID%type
  , iCharact1Id in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharact2Id in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharact3Id in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharact4Id in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharact5Id in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  )
    return number
  is
    lCharVersionId GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    if IsVersioningManagement(iGoodId) = 1 then
      begin
        select GCO_CHARACTERIZATION_ID
          into lCharVersionId
          from GCO_CHARACTERIZATION
         where GCO_GOOD_ID = iGoodID
           and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeVersion;

        case lCharVersionId
          when iCharact1Id then
            return 1;
          when iCharact2Id then
            return 2;
          when iCharact3Id then
            return 3;
          when iCharact4Id then
            return 4;
          when iCharact5Id then
            return 5;
        end case;
      exception
        when no_data_found then
          ra(aMessage   => replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Mauvaise configuration du versioning pour le bien [GOO_MAJOR_REFERENCE]')
                                 , '[GOO_MAJOR_REFERENCE]'
                                 , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iGoodId)
                                  )
           , aErrNo     => -20900
            );
      end;
    end if;

    -- si pas concerné
    return null;
  end;

  /**
  * procedure convertCharIdToElementNumber
  * Description
  *      convertlCounter les id de caractérisation en ElementNumberId
  * @created fp 15.6.2005
  * @public
  * @param iCharact1Id .. iCharact5Id : id de caractérisation du bien
  * @param iCharac1Val .. iCharac5Val : valeur des caractérisations
  * @param oEleNum1Id .. oEleNum3Id : retour, id de caractérisation du bien
  */
  procedure convertCharIdToElementNumber(
    iGoodID     in     number
  , iCharact1Id in     number
  , iCharact2Id in     number
  , iCharact3Id in     number
  , iCharact4Id in     number
  , iCharact5Id in     number
  , iCharacVal1 in     varchar2
  , iCharacVal2 in     varchar2
  , iCharacVal3 in     varchar2
  , iCharacVal4 in     varchar2
  , iCharacVal5 in     varchar2
  , oEleNum1Id  out    number
  , oEleNum2Id  out    number
  , oEleNum3Id  out    number
  )
  is
    strEleNum varchar2(38);
  begin
    if     iCharact1Id is not null
       and GetCharacType(iCharact1Id) in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet) then
      select strEleNum || nvl2(stm_element_number_id, stm_element_number_id || ',', null)
        into strEleNum
        from stm_element_number
       where c_element_type =
               decode(GetCharacType(iCharact1Id)
                    , GCO_I_LIB_CONSTANT.gcCharacTypeVersion, STM_I_LIB_CONSTANT.gcElementTypeVersion
                    , GCO_I_LIB_CONSTANT.gcCharacTypePiece, STM_I_LIB_CONSTANT.gcElementTypePiece
                    , GCO_I_LIB_CONSTANT.gcCharacTypeSet, STM_I_LIB_CONSTANT.gcElementTypeSet
                     )
         and GCO_GOOD_ID = iGoodId
         and sem_value = iCharacVal1;
    end if;

    if     iCharact2Id is not null
       and GetCharacType(iCharact2Id) in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet) then
      select strEleNum || nvl2(stm_element_number_id, stm_element_number_id || ',', null)
        into strEleNum
        from stm_element_number
       where c_element_type =
               decode(GetCharacType(iCharact2Id)
                    , GCO_I_LIB_CONSTANT.gcCharacTypeVersion, STM_I_LIB_CONSTANT.gcElementTypeVersion
                    , GCO_I_LIB_CONSTANT.gcCharacTypePiece, STM_I_LIB_CONSTANT.gcElementTypePiece
                    , GCO_I_LIB_CONSTANT.gcCharacTypeSet, STM_I_LIB_CONSTANT.gcElementTypeSet
                     )
         and GCO_GOOD_ID = iGoodId
         and sem_value = iCharacVal2;
    end if;

    if     iCharact3Id is not null
       and GetCharacType(iCharact3Id) in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet) then
      select strEleNum || nvl2(stm_element_number_id, stm_element_number_id || ',', null)
        into strEleNum
        from stm_element_number
       where c_element_type =
               decode(GetCharacType(iCharact3Id)
                    , GCO_I_LIB_CONSTANT.gcCharacTypeVersion, STM_I_LIB_CONSTANT.gcElementTypeVersion
                    , GCO_I_LIB_CONSTANT.gcCharacTypePiece, STM_I_LIB_CONSTANT.gcElementTypePiece
                    , GCO_I_LIB_CONSTANT.gcCharacTypeSet, STM_I_LIB_CONSTANT.gcElementTypeSet
                     )
         and GCO_GOOD_ID = iGoodId
         and sem_value = iCharacVal3;
    end if;

    if     iCharact4Id is not null
       and GetCharacType(iCharact4Id) in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet) then
      select strEleNum || nvl2(stm_element_number_id, stm_element_number_id || ',', null)
        into strEleNum
        from stm_element_number
       where c_element_type =
               decode(GetCharacType(iCharact4Id)
                    , GCO_I_LIB_CONSTANT.gcCharacTypeVersion, STM_I_LIB_CONSTANT.gcElementTypeVersion
                    , GCO_I_LIB_CONSTANT.gcCharacTypePiece, STM_I_LIB_CONSTANT.gcElementTypePiece
                    , GCO_I_LIB_CONSTANT.gcCharacTypeSet, STM_I_LIB_CONSTANT.gcElementTypeSet
                     )
         and GCO_GOOD_ID = iGoodId
         and sem_value = iCharacVal4;
    end if;

    if     iCharact5Id is not null
       and GetCharacType(iCharact5Id) in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet) then
      select strEleNum || nvl2(stm_element_number_id, stm_element_number_id || ',', null)
        into strEleNum
        from stm_element_number
       where c_element_type =
               decode(GetCharacType(iCharact5Id)
                    , GCO_I_LIB_CONSTANT.gcCharacTypeVersion, STM_I_LIB_CONSTANT.gcElementTypeVersion
                    , GCO_I_LIB_CONSTANT.gcCharacTypePiece, STM_I_LIB_CONSTANT.gcElementTypePiece
                    , GCO_I_LIB_CONSTANT.gcCharacTypeSet, STM_I_LIB_CONSTANT.gcElementTypeSet
                     )
         and GCO_GOOD_ID = iGoodId
         and sem_value = iCharacVal5;
    end if;

    oEleNum1Id  := extractLine(strEleNum, 1, ',');
    oEleNum2Id  := extractLine(strEleNum, 2, ',');
    oEleNum3Id  := extractLine(strEleNum, 3, ',');
  end convertCharIdToElementNumber;

  /**
  * Description
  *    indique si le lot possède des caractérisations morphologiques
  */
  function isCharMorph(iCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return number
  is
    lResult GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    select case
             when C_CHARACT_TYPE in('1', '2') then 1
             else 0
           end
      into lResult
      from GCO_CHARACTERIZATION
     where GCO_CHARACTERIZATION_ID = iCharacterizationId;

    return lResult;
  end;

  /**
  * Description
  *   Recupère les types de chronologie du bien
  */
  procedure GetChronologicalType(iGoodID in number, ioFIFO in out number, ioLIFO in out number, ioTimeLimit in out number)
  is
    lvChronologyType GCO_CHARACTERIZATION.C_CHRONOLOGY_TYPE%type;
  begin
    ioFIFO       := 0;
    ioLIFO       := 0;
    ioTimeLimit  := 0;

    begin
      select C_CHRONOLOGY_TYPE
        into lvChronologyType
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iGoodId
         and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeChrono;

      if lvChronologyType = GCO_I_LIB_CONSTANT.gcChronologyTypeFifo then
        ioFIFO  := 1;
      elsif lvChronologyType = GCO_I_LIB_CONSTANT.gcChronologyTypeLifo then
        ioLIFO  := 1;
      elsif lvChronologyType = GCO_I_LIB_CONSTANT.gcChronologyTypePeremption then
        ioTimeLimit  := 1;
      end if;
    exception
      when no_data_found then
        null;
    end;
  end GetChronologicalType;

  /**
  * Description
  *   Est-ce que le produit est géré avec une caractérisation chronologique de type FIFO
  */
  function IsFIFOManagement(iGoodID in number)
    return number
  is
    lResult number(1);
  begin
    select sign(nvl(max(GCO_CHARACTERIZATION_ID), 0) )
      into lResult
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodId
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
       and C_CHRONOLOGY_TYPE = GCO_I_LIB_CONSTANT.gcChronologyTypeFifo;

    return lResult;
  end IsFIFOManagement;

  /**
  * Description
  *   Est-ce que le produit est géré avec une caractérisation chronologique de type LIFO
  */
  function IsLIFOManagement(iGoodID in number)
    return number
  is
    lResult number(1);
  begin
    select sign(nvl(max(GCO_CHARACTERIZATION_ID), 0) )
      into lResult
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodId
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
       and C_CHRONOLOGY_TYPE = GCO_I_LIB_CONSTANT.gcChronologyTypeLifo;

    return lResult;
  end IsLIFOManagement;

  /**
  * Description
  *   Est-ce que le produit est géré avec une date de péremption
  */
  function IsTimeLimitManagement(iGoodID in number)
    return number
  is
    lResult number(1);
  begin
    return sign(nvl(GetTimeLimitCharId(iGoodID), 0) );
  end IsTimeLimitManagement;

  /**
  * Description
  *   Indique si un produit est en mode versioning
  */
  function IsVersioningManagement(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult GCO_PRODUCT.PDT_VERSION_MANAGEMENT%type   := 0;
  begin
    if GCO_I_LIB_CONSTANT.gcCfgUseVersioning then
      select sign(nvl(max(PDT_VERSION_MANAGEMENT), 0) )
        into lResult
        from GCO_PRODUCT
       where GCO_GOOD_ID = iGoodId;
    end if;

    return lResult;
  end IsVersioningManagement;

  /**
  * Description
  *   Retourne l'id de la caracterisation portant la péremption
  */
  function GetTimeLimitCharId(iGoodID in number)
    return GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  is
    lResult GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    select max(GCO_CHARACTERIZATION_ID)
      into lResult
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodId
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
       and C_CHRONOLOGY_TYPE = GCO_I_LIB_CONSTANT.gcChronologyTypePeremption;

    return lResult;
  end GetTimeLimitCharId;

  /**
  * function pGetDetailTuple
  * Description
  *   return a tuple of the element detail
  * @created fpe 13.06.2014
  * @updated
  * @private
  * @param iDetCharId : Detailled charaterization identifier
  * @param iValue : value of the chractaerization
  * @return see description
  */
  function pGetDetailTuple(iDetCharId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type, iValue in STM_ELEMENT_NUMBER.SEM_VALUE%type)
    return STM_ELEMENT_NUMBER%rowtype
  is
    lResult STM_ELEMENT_NUMBER%rowtype;
  begin
    select SEM.*
      into lResult
      from STM_ELEMENT_NUMBER SEM
         , GCO_CHARACTERIZATION CHA
     where CHA.GCO_CHARACTERIZATION_ID = iDetCharId
       and SEM.GCO_GOOD_ID = CHA.GCO_GOOD_ID
       and CHA.C_CHARACT_TYPE in(GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet)
       and SEM.C_ELEMENT_TYPE =
             decode(CHA.C_CHARACT_TYPE
                  , GCO_I_LIB_CONSTANT.gcCharacTypePiece, STM_I_LIB_CONSTANT.gcElementTypePiece
                  , GCO_I_LIB_CONSTANT.gcCharacTypeSet, STM_I_LIB_CONSTANT.gcElementTypeSet
                   )
       and SEM.SEM_VALUE = iValue;

    return lResult;
  exception
    when no_data_found then
      return lResult;
  end pGetDetailTuple;

  /**
  * Description
  *   Return the manufacturing date of a set or a piece number
  */
  function GetManufacturingDate(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iValue in STM_ELEMENT_NUMBER.SEM_VALUE%type)
    return STM_ELEMENT_NUMBER.SEM_MANUFACTURING_DATE%type
  is
    lDetCharId GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type   := GetUseDetailCharID(iGoodId);
    lSemTuple  STM_ELEMENT_NUMBER%rowtype;
  begin
    lSemTuple  := pGetDetailTuple(lDetCharId, iValue);
    return lSemTuple.SEM_MANUFACTURING_DATE;
  end GetManufacturingDate;

  /**
  * Description
  *   Return timelimit date in regard to a reference date and the characteriaztion identifier
  */
  function CalcTimeLimit(iCharId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type, iRefDate in date default sysdate)
    return varchar2
  is
  begin
    return to_char(trunc(iRefDate) + nvl(FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_CHARACTERIZATION', 'CHA_LAPSING_DELAY', iCharId), 0), 'YYYYMMDD');
  end CalcTimeLimit;

  /**
  * Description
  *   Return retest date in regard to a reference date and the characteriaztion identifier
  */
  function CalcRetestDate(iCharId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type, iRefDate in date default sysdate)
    return date
  is
    lRetestDelay number(9) := FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_CHARACTERIZATION', 'CHA_RETEST_DELAY', iCharId);
  begin
    if lRetestDelay is not null then
      return trunc(iRefDate) + lRetestDelay;
    else
      return null;
    end if;
  end CalcRetestDate;

  /**
  * Description
  *   Est-ce que le bien possède une caractéristique numéro de pièce
  */
  function IsPieceChar(iGoodID in number)
    return number
  is
    lResult number(1);
  begin
    select sign(nvl(max(GCO_CHARACTERIZATION_ID), 0) )
      into lResult
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodId
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece;

    return lResult;
  end IsPieceChar;

   /**
  * Description
  *   Est-ce que le bien possède une caractéristique lot
  */
  function IsLotChar(iGoodID in number)
    return number
  is
    lResult number(1);
  begin
    select sign(nvl(max(GCO_CHARACTERIZATION_ID), 0) )
      into lResult
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodId
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeSet;

    return lResult;
  end IsLotChar;

   /**
  * Description
  *   Est-ce que le bien possède une caractéristique version
  */
  function IsVersionChar(iGoodID in number)
    return number
  is
    lResult number(1);
  begin
    select sign(nvl(max(GCO_CHARACTERIZATION_ID), 0) )
      into lResult
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodId
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeVersion;

    return lResult;
  end IsVersionChar;

  /**
  * Description
  *   Est-ce que le bien possède une caractéristique de type version avec gestion de stock
  */
  function IsVersionCharWithStockMgmt(iGoodID in number)
    return number
  is
    lResult number(1);
  begin
    select sign(nvl(max(GCO_CHARACTERIZATION_ID), 0) )
      into lResult
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodId
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
       and CHA_STOCK_MANAGEMENT = 1;

    return lResult;
  end IsVersionCharWithStockMgmt;

  /**
  * Description
  *   Est-ce que le bien possède une caractéristique chronologique
  */
  function IsChronoChar(iGoodID in number)
    return number
  is
    lResult number(1);
  begin
    select sign(nvl(max(GCO_CHARACTERIZATION_ID), 0) )
      into lResult
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodId
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeChrono;

    return lResult;
  end IsChronoChar;

  /**
  * Description
  *   recherche du délai de péremption (si pas trouvé, retourne null)
  */
  function getLapsingMarge(iGoodID in number, iThirdId in number default null)
    return number
  is
    lResult           GCO_CHARACTERIZATION.CHA_LAPSING_MARGE%type;
    lCharLapsingMarge GCO_CHARACTERIZATION.CHA_LAPSING_MARGE%type;
  begin
    begin
      -- Données de la caractérisation
      select nvl(CHA_LAPSING_MARGE, 0)
        into lCharLapsingMarge
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iGoodId
         and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
         and C_CHRONOLOGY_TYPE = GCO_I_LIB_CONSTANT.gcChronologyTypePeremption;

      -- si la recherche se fait sans tiers, on arrête à ce stade
      if iThirdId is null then
        return lCharLapsingMarge;
      end if;
    exception
      when no_data_found then
        -- signifie que le bien n'est pas géré en mode péremption
        return null;
    end;

    -- Données complémentaires de vente du tiers
    select CSA_LAPSING_MARGE
      into lResult
      from GCO_COMPL_DATA_SALE
     where GCO_GOOD_ID = iGoodId
       and PAC_CUSTOM_PARTNER_ID = iThirdId
       and DIC_COMPLEMENTARY_DATA_ID is null
       and CSA_LAPSING_MARGE is not null;

    return lResult;
  exception
    when no_data_found then
      begin
        -- Données complémentaires de vente générales (ne pas rechercher si aucun tiers passé à la fonction)
        select CSA.CSA_LAPSING_MARGE
          into lResult
          from GCO_COMPL_DATA_SALE CSA
             , PAC_CUSTOM_PARTNER CUS
         where CSA.GCO_GOOD_ID = iGoodId
           and CUS.PAC_CUSTOM_PARTNER_ID = iThirdId
           and CSA.PAC_CUSTOM_PARTNER_ID is null
           and CSA.DIC_COMPLEMENTARY_DATA_ID = CUS.DIC_COMPLEMENTARY_DATA_ID
           and CSA.CSA_LAPSING_MARGE is not null;

        return lResult;
      exception
        when no_data_found then
          begin
            -- Données complémentaires de vente générales (ne pas rechercher si aucun tiers passé à la fonction)
            select CSA_LAPSING_MARGE
              into lResult
              from GCO_COMPL_DATA_SALE
             where GCO_GOOD_ID = iGoodId
               and PAC_CUSTOM_PARTNER_ID is null
               and DIC_COMPLEMENTARY_DATA_ID is null
               and CSA_LAPSING_MARGE is not null;

            return lResult;
          exception
            when no_data_found then
              begin
                -- Données du tiers
                select CUS_LAPSING_MARGE
                  into lResult
                  from PAC_CUSTOM_PARTNER
                 where PAC_CUSTOM_PARTNER_ID = iThirdID
                   and CUS_LAPSING_MARGE is not null;

                return lResult;
              exception
                when no_data_found then
                  begin
                    return lCharLapsingMarge;
                  end;
              end;
          end;
      end;
  end getLapsingMarge;

  /**
  * Description
  *    Vérifie que les produits à traiter (Ajout détail de caractérisation)
  *    possèdent des positions de stock
  */
  function VerifyWizardStock
    return number
  is
    cursor lcurGoodToVerify
    is
      select   LID_ID_1 GCO_GOOD_ID
          from COM_LIST_ID_TEMP
         where LID_CODE = 'ListGood'
      group by LID_ID_1;

    lResult number(1) := 0;
  begin
    for tplGoodToVerify in lcurGoodToVerify loop
      lResult  := STM_I_LIB_STOCK_POSITION.GoodWithStockPosition(iGoodId => tplGoodToVerify.GCO_GOOD_ID);
      exit when lResult = 1;
    end loop;

    return lResult;
  end VerifyWizardStock;

  /**
  * Description
  *    Vérifie que les produits à traiter (Ajout détail de caractérisation)
  *    possèdent des détails de position de document (position de stock non liquidé)
  */
  function VerifyWizardDoc
    return number
  is
    cursor lcurGoodToVerify
    is
      select   LID_ID_1 GCO_GOOD_ID
          from COM_LIST_ID_TEMP
         where LID_CODE = 'ListGood'
      group by LID_ID_1;

    lResult number(1) := 0;
  begin
    for tplGoodToVerify in lcurGoodToVerify loop
      lResult  := GoodWithDocChar(iGoodId => tplGoodToVerify.GCO_GOOD_ID);
      exit when lResult = 1;
    end loop;

    return lResult;
  end VerifyWizardDoc;

  /**
  * Description
  *   Détermine s'il existe des documents aves des caracterisations saisies sans mouvement généré
  */
  function GoodWithDocChar(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult number(1);
  begin
    select sign(count(*) )
      into lResult
      from DOC_POSITION_DETAIL PDE
     where PDE.GCO_GOOD_ID = iGoodID
       and PDE.PDE_GENERATE_MOVEMENT = 0
       and STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(PDE.GCO_GOOD_ID, PDE.PDE_PIECE, PDE.PDE_SET, PDE.PDE_VERSION) <> 0;

    return lResult;
  end GoodWithDocChar;

  /**
  * Description
  *    Vérifie que les produits à traiter (Ajout détail de caractérisation)
  *    possèdent des détails de lot (quantité solde <> 0)
  */
  function VerifyWizardBatch
    return number
  is
    cursor lcurGoodToVerify
    is
      select   LID_ID_1 GCO_GOOD_ID
          from COM_LIST_ID_TEMP
         where LID_CODE = 'ListGood'
      group by LID_ID_1;

    lResult number(1) := 0;
  begin
    for tplGoodToVerify in lcurGoodToVerify loop
      lResult  := GoodWithBatchChar(iGoodId => tplGoodToVerify.GCO_GOOD_ID);
      exit when lResult = 1;
    end loop;

    return lResult;
  end VerifyWizardBatch;

    /**
  * Description
  *   Détermine s'il existe des lots aves des caracterisations saisies
  */
  function GoodWithBatchChar(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult number(1);
  begin
    select sign(count(*) )
      into lResult
      from FAL_LOT_DETAIL FAD
     where FAD.GCO_GOOD_ID = iGoodID
       and FAD_BALANCE_QTY > 0
       and STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(FAD.GCO_GOOD_ID, FAD.FAD_PIECE, FAD.FAD_LOT_CHARACTERIZATION, FAD.FAD_VERSION) <> 0;

    return lResult;
  end GoodWithBatchChar;

  /**
  * function VerifyWizardTmpPosValues
  */
  function VerifyWizardTmpPosValues
    return number
  is
    cursor lcurGoodtoverify
    is
      select   GCO_GOOD_ID
          from STM_TMP_STOCK_POSITION
      group by GCO_GOOD_ID;

    lResult number(1) := 0;
  begin
    for tplGoodToVerify in lcurGoodtoverify loop
      lResult  := VerifyWizardTmpPosValueGood(tplGoodToVerify.GCO_GOOD_ID);
      exit when lResult <> 0;
    end loop;

    return lResult;
  end VerifyWizardTmpPosValues;

  /**
  * function VerifyWizardTmpPosValuesGood
  */
  function VerifyWizardTmpPosValueGood(iGoodID GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    cursor lcurverify(iGoodId number, iNbChar number)
    is
      select   TMP.GCO_GOOD_ID
             , TMP.STM_STOCK_ID
             , TMP.STM_LOCATION_ID
             , TMP.GCO_CHARACTERIZATION_ID
             , TMP.GCO_GCO_CHARACTERIZATION_ID
             , TMP.GCO2_GCO_CHARACTERIZATION_ID
             , TMP.GCO3_GCO_CHARACTERIZATION_ID
             , TMP.GCO4_GCO_CHARACTERIZATION_ID
             , TMP.SPO_CHARACTERIZATION_VALUE_1
             , TMP.SPO_CHARACTERIZATION_VALUE_2
             , TMP.SPO_CHARACTERIZATION_VALUE_3
             , TMP.SPO_CHARACTERIZATION_VALUE_4
             , TMP.SPO_CHARACTERIZATION_VALUE_5
             , TMP.SPO_ORIGIN
             , TMP.SPO_ORIGIN_QUANTITY
             , TMP.SPO_STOCK_QUANTITY
          from STM_TMP_STOCK_POSITION TMP
             , STM_STOCK STO
         where TMP.GCO_GOOD_ID = iGoodId
           and TMP.STM_STOCK_ID = STO.STM_STOCK_ID
           and STO.C_ACCESS_METHOD <> 'PRIVATE'
      order by TMP.GCO_GOOD_ID
             , TMP.STM_STOCK_ID
             , TMP.STM_LOCATION_ID
             , TMP.GCO_CHARACTERIZATION_ID
             , TMP.GCO_GCO_CHARACTERIZATION_ID
             , TMP.GCO2_GCO_CHARACTERIZATION_ID
             , TMP.GCO3_GCO_CHARACTERIZATION_ID
             , TMP.GCO4_GCO_CHARACTERIZATION_ID
             , decode(sign(iNbChar - 1), 1, TMP.SPO_CHARACTERIZATION_VALUE_1, 'null')
             , decode(sign(iNbChar - 2), 1, TMP.SPO_CHARACTERIZATION_VALUE_2, 'null')
             , decode(sign(iNbChar - 3), 1, TMP.SPO_CHARACTERIZATION_VALUE_3, 'null')
             , decode(sign(iNbChar - 4), 1, TMP.SPO_CHARACTERIZATION_VALUE_4, 'null')
             , TMP.SPO_ORIGIN desc;

    lNbChar    pls_integer;
    lResult    number(1)                                    := 0;
    lCumQty    STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lOldRefQty STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
  begin
    select count(*)
      into lNbChar
      from GCO_CHARACTERIZATION CHA
         , GCO_PRODUCT PDT
     where PDT.GCO_GOOD_ID = iGoodID
       and CHA.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and CHA_STOCK_MANAGEMENT = 1
       and PDT_STOCK_MANAGEMENT = 1;

    for tplVerify in lcurverify(iGoodID, lNbChar) loop
      -- nouvelle clef
      --select tplVerify.GCO_GOOD_ID||'/'||tplVerify.STM_STOCK_ID||'/'||tplVerify.STM_LOCATION_ID||'/'||decode(lNbChar-1,1,tplVerify.SPO_CHARACTERIZATION_VALUE_1,null)||'/'||decode(lNbChar-2,1,tplVerify.SPO_CHARACTERIZATION_VALUE_2,null)||'/'||decode(lNbChar-3,1,tplVerify.SPO_CHARACTERIZATION_VALUE_3,null)||'/'||decode(lNbChar-4,1,tplVerify.SPO_CHARACTERIZATION_VALUE_4,null)
      --into lNewKey from dual;
      -- si ligne originale
      if tplVerify.SPO_ORIGIN = 1 then
        if lOldRefQty <> lCumQty then
          lResult  := 2;
          exit;
        end if;

        --vOldKey := lNewKey;
        lOldRefQty  := tplVerify.SPO_ORIGIN_QUANTITY;
        lCumQty     := 0;
      end if;

      lCumQty  := lCumQty + tplVerify.SPO_STOCK_QUANTITY;

      if     lNbChar >= 1
         and nvl(tplVerify.SPO_CHARACTERIZATION_VALUE_1, 'N/A') = 'N/A' then
        lResult  := 1;
        exit;
      elsif     lNbChar >= 2
            and nvl(tplVerify.SPO_CHARACTERIZATION_VALUE_2, 'N/A') = 'N/A' then
        lResult  := 1;
        exit;
      elsif     lNbChar >= 3
            and nvl(tplVerify.SPO_CHARACTERIZATION_VALUE_3, 'N/A') = 'N/A' then
        lResult  := 1;
        exit;
      elsif     lNbChar >= 4
            and nvl(tplVerify.SPO_CHARACTERIZATION_VALUE_4, 'N/A') = 'N/A' then
        lResult  := 1;
        exit;
      elsif     lNbChar >= 5
            and nvl(tplVerify.SPO_CHARACTERIZATION_VALUE_5, 'N/A') = 'N/A' then
        lResult  := 1;
        exit;
      end if;
    end loop;

    if lOldRefQty <> lCumQty then
      lResult  := 2;
    end if;

    return lResult;
  end VerifyWizardTmpPosValueGood;

  function getWizardBalanceQty(
    iGoodID     in STM_TMP_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockID    in STM_TMP_STOCK_POSITION.STM_STOCK_ID%type
  , iLocationID in STM_TMP_STOCK_POSITION.STM_LOCATION_ID%type
  , iChar1Value in STM_TMP_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iChar2Value in STM_TMP_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , iChar3Value in STM_TMP_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , iChar4Value in STM_TMP_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  )
    return STM_TMP_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  is
    lResult STM_TMP_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lNbChar number(1);
  begin
    -- recherche du nombre de caractérisations
    select count(*)
      into lNbChar
      from GCO_CHARACTERIZATION CHA
         , GCO_PRODUCT PDT
     where PDT.GCO_GOOD_ID = iGoodID
       and CHA.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and CHA_STOCK_MANAGEMENT = 1
       and PDT_STOCK_MANAGEMENT = 1;

    -- recherche de la quantité solde
    select sum(SPO_ORIGIN_QUANTITY) - sum(SPO_STOCK_QUANTITY)
      into lResult
      from STM_TMP_STOCK_POSITION
     where GCO_GOOD_ID = iGoodID
       and STM_STOCK_ID = iStockId
       and STM_LOCATION_ID = iLocationId
       and (   lNbChar <= 1
            or SPO_CHARACTERIZATION_VALUE_1 = iChar1Value)
       and (   lNbChar <= 2
            or SPO_CHARACTERIZATION_VALUE_2 = iChar2Value)
       and (   lNbChar <= 3
            or SPO_CHARACTERIZATION_VALUE_3 = iChar3Value)
       and (   lNbChar <= 4
            or SPO_CHARACTERIZATION_VALUE_4 = iChar4Value);

    return lResult;
  end getWizardBalanceQty;

  /**
  * function getWizardGoodPrivateStkPos
  * Description
  *   Vérifier s'il y a des positions de stock portant sur des stocks privés
  */
  function getWizardGoodPrivateStkPos(iGoodID in STM_TMP_STOCK_POSITION.GCO_GOOD_ID%type)
    return number
  is
    lnResult number;
  begin
    -- Vérifier s'il y a des positions de stock portant sur des stocks privés
    select sign(count(*) )
      into lnResult
      from STM_TMP_STOCK_POSITION TMP
         , STM_STOCK STO
     where TMP.GCO_GOOD_ID = iGoodID
       and TMP.STM_STOCK_ID = STO.STM_STOCK_ID
       and STO.C_ACCESS_METHOD = 'PRIVATE';

    return lnResult;
  end getWizardGoodPrivateStkPos;

  /**
  * Description
  *      Retourne les id de caractérisation selon la position désirée
  *      en supprimant les caractérisations non gérées en stock
  */
  function getStkCharPosId(iGoodId in number, iPos in number)
    return number
  is
    cursor lcurCharlist(iGoodId number)
    is
      select   GCO_CHARACTERIZATION_ID
          from gco_characterization cha
             , gco_product pdt
         where pdt.GCO_GOOD_ID = iGoodId
           and cha.GCO_GOOD_ID = pdt.GCO_GOOD_ID
           and cha_stock_management = 1
           and pdt_stock_management = 1
      order by GCO_CHARACTERIZATION_ID;

    lResult  GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCounter integer;
  begin
    open lcurCharlist(iGoodId);

    -- se positionne sur la nème char gérée en stock se lon iPos
    for lCounter in 1 .. iPos loop
      fetch lcurCharlist
       into lResult;
    end loop;

    -- si on pointe sur rien on renvoie null
    if not lcurCharlist%found then
      lResult  := null;
    end if;

    close lcurCharlist;

    return lResult;
  end getStkCharPosId;

  /**
  * procedure getStkCharPosValue
  * Description
  *      Retourne les valeur de caractérisation selon la position désirée
  *      en supprimant les caractérisations non gérées en stock
  */
  function getStkCharPosValue(
    iGoodId       in number
  , iPos          in number
  , iCharacValue1 in varchar2
  , iCharacValue2 in varchar2
  , iCharacValue3 in varchar2
  , iCharacValue4 in varchar2
  , iCharacValue5 in varchar2
  )
    return varchar2
  is
    cursor lcurCharlist(iGoodId number)
    is
      select   decode(PDT_STOCK_MANAGEMENT, 1, CHA_STOCK_MANAGEMENT, 0) CHA_STOCK_MANAGEMENT
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where PDT.GCO_GOOD_ID = iGoodId
           and CHA.GCO_GOOD_ID = PDT.GCO_GOOD_ID
      order by GCO_CHARACTERIZATION_ID;

    lResult   DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    lbStkMgt  number(1);
    lCounter  integer                                                 default 0;
    lCounter2 integer                                                 default 0;
  begin
    open lcurCharlist(iGoodId);

    lCounter  := iPos;

    -- on skip les caractérisations non gérées en stock
    -- en sortie de boucle la variable lCounter2 contient la position de la valeur à retourner
    fetch lcurCharlist
     into lbStkMgt;

    while lcurCharlist%found
     and lCounter > 0 loop
      if lbStkMgt = 1 then
        lCounter  := lCounter - 1;
      end if;

      lCounter2  := lCounter2 + 1;

      fetch lcurCharlist
       into lbStkMgt;
    end loop;

    if lCounter > 0 then
      -- si on est arrivé à la fin des caractérisations sans trové on retourne null
      lResult  := null;
    else
      -- si on a trouvé une caractérisation
      -- assignation de la valeur de retour en fonction de lCounter2
      if lCounter2 = 1 then
        lResult  := iCharacValue1;
      elsif lCounter2 = 2 then
        lResult  := iCharacValue2;
      elsif lCounter2 = 3 then
        lResult  := iCharacValue3;
      elsif lCounter2 = 4 then
        lResult  := iCharacValue4;
      elsif lCounter2 = 5 then
        lResult  := iCharacValue5;
      end if;
    end if;

    close lcurCharlist;

    return lResult;
  end getStkCharPosValue;

  /**
  * procedure ClassifyCharacterization
  * Description
  *    Décorticage d'un type de caractérisation et renvolCounter par genre
  * Sous-fonction de ClassifyCharacterizations
  * @param iCharacId  id de caractérisation
  * @param iCharValue :  valeur de caractérisation
  * @param out oPiece : retour du numéro de pièce
  * @param out oSet : retour du numéro de lot
  * @param out oVersion : retour du numéro de version
  * @param out oChronological : retour de la valeur de chronologie
  * @param out iCharStd : retour de valeur de caractérisation standard
  */
  procedure ClassifyCharacterization(
    iCharacId       in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharValue      in     varchar2
  , ioPiece         in out varchar2
  , ioSet           in out varchar2
  , ioVersion       in out varchar2
  , ioChronological in out varchar2
  , ioCharStd       in out varchar2
  )
  is
    lCharType GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
  begin
    -- recherche du type de caractérisation
    lCharType  := GetCharacType(iCharacId);

    if lCharType = GCO_I_LIB_CONSTANT.gcCharacTypeVersion then
      ioVersion  := iCharValue;
    elsif lCharType = GCO_I_LIB_CONSTANT.gcCharacTypeCharacteristic then
      ioCharStd  := iCharValue;
    elsif lCharType = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
      ioPiece  := iCharValue;
    elsif lCharType = GCO_I_LIB_CONSTANT.gcCharacTypeSet then
      ioSet  := iCharValue;
    elsif lCharType = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then   -- chronologie
      ioChronological  := iCharValue;

      if VerifyChronologicalFormat(iCharacId, iCharValue) = 0 then
        raise_application_error(-20000
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Mauvais format de caractérisation chronologique!') ||
                                chr(10) ||
                                PCS.PC_FUNCTIONS.TranslateWord('Caractérisation') ||
                                ' = "' ||
                                iCharValue ||
                                '"'
                               );
      end if;
    end if;
  end ClassifyCharacterization;

  /**
  * Description
  *    Décorticage des types de caractérisations et renvolCounter par genre
  */
  procedure ClassifyCharacterizations(
    iCharac1Id     in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharac2Id     in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharac3Id     in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharac4Id     in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharac5Id     in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharValue1    in     varchar2
  , iCharValue2    in     varchar2
  , iCharValue3    in     varchar2
  , iCharValue4    in     varchar2
  , iCharValue5    in     varchar2
  , oPiece         out    varchar2
  , oSet           out    varchar2
  , oVersion       out    varchar2
  , oChronological out    varchar2
  , oCharStd1      out    varchar2
  , oCharStd2      out    varchar2
  , oCharStd3      out    varchar2
  , oCharStd4      out    varchar2
  , oCharStd5      out    varchar2
  )
  is
    lCharStd1 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharStd2 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharStd3 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharStd4 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharStd5 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lIndex    number;
  begin
    oPiece          := '';
    oSet            := '';
    oVersion        := '';
    oChronological  := '';
    oCharStd1       := '';
    oCharStd2       := '';
    oCharStd3       := '';
    oCharStd4       := '';
    oCharStd5       := '';

    -- recherche du type de la première caractérisation
    if iCharac1Id is not null then
      ClassifyCharacterization(iCharac1Id, iCharValue1, oPiece, oSet, oVersion, oChronological, lCharStd1);
    end if;

    -- recherche du type de la seconde caractérisation
    if iCharac2Id is not null then
      ClassifyCharacterization(iCharac2Id, iCharValue2, oPiece, oSet, oVersion, oChronological, lCharStd2);
    end if;

    -- recherche du type de la troisième caractérisation
    if iCharac3Id is not null then
      ClassifyCharacterization(iCharac3Id, iCharValue3, oPiece, oSet, oVersion, oChronological, lCharStd3);
    end if;

    -- recherche du type de la 4e caractérisation
    if iCharac4Id is not null then
      ClassifyCharacterization(iCharac4Id, iCharValue4, oPiece, oSet, oVersion, oChronological, lCharStd4);
    end if;

    -- recherche du type de la 5e caractérisation
    if iCharac5Id is not null then
      ClassifyCharacterization(iCharac5Id, iCharValue5, oPiece, oSet, oVersion, oChronological, lCharStd5);
    end if;

    -- Mise à plat des caractérisations standard
    lIndex          := 0;

    for tplStd in (select   CHARSTD
                       from (select 1 SF
                                  , lCharStd1 CHARSTD
                               from dual
                             union
                             select 2 SF
                                  , lCharStd2 CHARSTD
                               from dual
                             union
                             select 3 SF
                                  , lCharStd3 CHARSTD
                               from dual
                             union
                             select 4 SF
                                  , lCharStd4 CHARSTD
                               from dual
                             union
                             select 5 SF
                                  , lCharStd5 CHARSTD
                               from dual)
                      where CHARSTD is not null
                   order by SF) loop
      lIndex  := lIndex + 1;

      if lIndex = 1 then
        oCharStd1  := tplStd.CHARSTD;
      elsif lIndex = 2 then
        oCharStd2  := tplStd.CHARSTD;
      elsif lIndex = 3 then
        oCharStd3  := tplStd.CHARSTD;
      elsif lIndex = 4 then
        oCharStd4  := tplStd.CHARSTD;
      elsif lIndex = 5 then
        oCharStd5  := tplStd.CHARSTD;
      end if;
    end loop;
  end ClassifyCharacterizations;

  /**
  * Description
  *     Méthode qui retourne les caractérisations ID et values en fonction d'info
  *     dénormalisées (no de pièce, no de lot, chrono et valeurs standard)
  */
  procedure ReverseClassify(
    iGoodId        in     GCO_GOOD.GCO_GOOD_ID%type
  , iOnlyGestStock in     number default 0
  , iPiece         in     varchar2
  , iSet           in     varchar2
  , iVersion       in     varchar2
  , iChronological in     varchar2
  , iCharStd1      in     varchar2
  , iCharStd2      in     varchar2
  , iCharStd3      in     varchar2
  , iCharStd4      in     varchar2
  , iCharStd5      in     varchar2
  , oCharId1       out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharId2       out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharId3       out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharId4       out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharId5       out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharValue1    out    varchar2
  , oCharValue2    out    varchar2
  , oCharValue3    out    varchar2
  , oCharValue4    out    varchar2
  , oCharValue5    out    varchar2
  )
  is
    type tChar is record(
      GCO_CHARACTERIZATION_ID number
    , C_CHARACT_TYPE          varchar2(10)
    , CHA_VALUE               varchar2(30)
    );

    type ttChar is table of tChar
      index by binary_integer;

    ltCharList ttChar;
    lOccurence pls_integer;
  begin
    -- liste des caractérisations dans un tableau
    select   GCO_CHARACTERIZATION_ID
           , C_CHARACT_TYPE
           , ''
    bulk collect into ltCharList
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iGoodId
         and (   CHA_STOCK_MANAGEMENT = 1
              or iOnlyGestStock = 0)
    order by GCO_CHARACTERIZATION_ID;

    if ltCharList.count > 0 then
      -- contrôle que le nombre de caractérisation donné corresponde au nombre de caractérisations de l'article
      declare
        lNbChar pls_integer;
      begin
        select nvl2(iPiece, 1, 0) +
               nvl2(iSet, 1, 0) +
               nvl2(iVersion, 1, 0) +
               nvl2(iChronological, 1, 0) +
               nvl2(iCharStd1, 1, 0) +
               nvl2(iCharStd2, 1, 0) +
               nvl2(iCharStd3, 1, 0) +
               nvl2(iCharStd4, 1, 0) +
               nvl2(iCharStd5, 1, 0)
          into lNbChar
          from dual;

        if lNbChar <> ltCharList.count then
          ra
            (PCS.PC_FUNCTIONS.TranslateWord
               (replace
                     ('Le nombre de valeurs de caractérisations fourni pour le bien [GOOD] n''est pas égal au nombre de caractérisations défini pour le bien.'
                    , '[GOOD]'
                    , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iGoodId)
                     )
               )
            );
        end if;
      end;

      -- numéro de série
      if iPiece is not null then
        for lIndex in 1 .. ltCharList.count loop
          if ltCharList(lIndex).C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
            ltCharList(lIndex).CHA_VALUE  := iPiece;
            exit;   -- exit from loop
          end if;
        end loop;
      end if;

      -- numéro de lot
      if iSet is not null then
        for lIndex in 1 .. ltCharList.count loop
          if ltCharList(lIndex).C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeSet then
            ltCharList(lIndex).CHA_VALUE  := iSet;
            exit;   -- exit from loop
          end if;
        end loop;
      end if;

      -- numéro de version
      if iVersion is not null then
        for lIndex in 1 .. ltCharList.count loop
          if ltCharList(lIndex).C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeVersion then
            ltCharList(lIndex).CHA_VALUE  := iVersion;
            exit;   -- exit from loop
          end if;
        end loop;
      end if;

      -- chronologique
      if iChronological is not null then
        for lIndex in 1 .. ltCharList.count loop
          if ltCharList(lIndex).C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
            ltCharList(lIndex).CHA_VALUE  := iChronological;
            exit;   -- exit from loop
          end if;
        end loop;
      end if;

      -- caracterisation standard 1
      if iCharStd1 is not null then
        for lIndex in 1 .. ltCharList.count loop
          if ltCharList(lIndex).C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeCharacteristic then
            ltCharList(lIndex).CHA_VALUE  := iCharStd1;
            exit;   -- exit from loop
          end if;
        end loop;
      end if;

      -- caracterisation standard 2
      if iCharStd2 is not null then
        lOccurence  := 1;

        for lIndex in 1 .. ltCharList.count loop
          if ltCharList(lIndex).C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeCharacteristic then
            if lOccurence = 2 then
              ltCharList(lIndex).CHA_VALUE  := iCharStd2;
              exit;   -- exit from loop
            end if;

            lOccurence  := lOccurence + 1;
          end if;
        end loop;
      end if;

      -- caracterisation standard 3
      if iCharStd3 is not null then
        lOccurence  := 1;

        for lIndex in 1 .. ltCharList.count loop
          if ltCharList(lIndex).C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeCharacteristic then
            if lOccurence = 3 then
              ltCharList(lIndex).CHA_VALUE  := iCharStd3;
              exit;   -- exit from loop
            end if;

            lOccurence  := lOccurence + 1;
          end if;
        end loop;
      end if;

      -- caracterisation standard 4
      if iCharStd4 is not null then
        lOccurence  := 1;

        for lIndex in 1 .. ltCharList.count loop
          if ltCharList(lIndex).C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeCharacteristic then
            if lOccurence = 4 then
              ltCharList(lIndex).CHA_VALUE  := iCharStd4;
              exit;   -- exit from loop
            end if;

            lOccurence  := lOccurence + 1;
          end if;
        end loop;
      end if;

      -- caracterisation standard 5
      if iCharStd5 is not null then
        lOccurence  := 1;

        for lIndex in 1 .. ltCharList.count loop
          if ltCharList(lIndex).C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeCharacteristic then
            if lOccurence = 5 then
              ltCharList(lIndex).CHA_VALUE  := iCharStd5;
              exit;   -- exit from loop
            end if;

            lOccurence  := lOccurence + 1;
          end if;
        end loop;
      end if;

      -- assignation des paramètres out
      for lIndex in ltCharList.first .. ltCharList.last loop
        case
          when lIndex = 1 then
            oCharId1     := ltCharList(lIndex).GCO_CHARACTERIZATION_ID;
            oCharValue1  := ltCharList(lIndex).CHA_VALUE;
          when lIndex = 2 then
            oCharId2     := ltCharList(lIndex).GCO_CHARACTERIZATION_ID;
            oCharValue2  := ltCharList(lIndex).CHA_VALUE;
          when lIndex = 3 then
            oCharId3     := ltCharList(lIndex).GCO_CHARACTERIZATION_ID;
            oCharValue3  := ltCharList(lIndex).CHA_VALUE;
          when lIndex = 4 then
            oCharId4     := ltCharList(lIndex).GCO_CHARACTERIZATION_ID;
            oCharValue4  := ltCharList(lIndex).CHA_VALUE;
          when lIndex = 5 then
            oCharId5     := ltCharList(lIndex).GCO_CHARACTERIZATION_ID;
            oCharValue5  := ltCharList(lIndex).CHA_VALUE;
        end case;
      end loop;
    end if;
  end ReverseClassify;

  /**
  * Description
  *        fonction qulCounter retourne la valeur de caractérisation pour la gestion FIFO/LIFO
  */
  function PropChronologicalFormat(iCharacterizationID in number, iBasisTime date, iContext in varchar2 default null, iElementId in number default null)
    return varchar2
  is
    lUnitOfTime     GCO_CHARACTERIZATION.C_UNIT_OF_TIME%type;
    lChronologyType GCO_CHARACTERIZATION.C_CHRONOLOGY_TYPE%type;
    lLapsingdelay   GCO_CHARACTERIZATION.CHA_LAPSING_DELAY%type;
    lCharactType    GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lStampFormat    varchar2(30);
    lResult         varchar2(30);
  begin
    select C_UNIT_OF_TIME
         , C_CHRONOLOGY_TYPE
         , nvl(CHA_LAPSING_DELAY, 0)
         , C_CHARACT_TYPE
      into lUnitOfTime
         , lChronologyType
         , lLapsingdelay
         , lCharactType
      from GCO_CHARACTERIZATION
     where GCO_CHARACTERIZATION_ID = iCharacterizationId;

    if lCharactType = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
      if lChronologyType in(GCO_I_LIB_CONSTANT.gcChronologyTypeFifo, GCO_I_LIB_CONSTANT.gcChronologyTypeLifo) then
        -- intantanné
        if lUnitOfTime in(GCO_I_LIB_CONSTANT.gcUnitOfTimeInstantaneous, '0') then
          lResult  := to_char(iBasisTime, 'YYYYMMDD HH24:MI:SS');
        -- arrondlCounter à la minute
        elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeMinute then
          lResult  := to_char(iBasisTime, 'YYYYMMDD HH24:MI') || ':00';
        -- arrondlCounter à l'heure
        elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeHeure then
          lResult  := to_char(iBasisTime, 'YYYYMMDD HH24') || ':00:00';
        -- arrondlCounter au demlCounter jour
        elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeHalfDay then
          if to_number(to_char(iBasisTime, 'HH24') ) < 12 then
            lResult  := to_char(iBasisTime, 'YYYYMMDD ') || '00:00:00';
          else
            lResult  := to_char(iBasisTime, 'YYYYMMDD ') || '12:00:00';
          end if;
        -- arrondlCounter au jour
        elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeDay then
          lResult  := to_char(iBasisTime, 'YYYYMMDD');
        -- arrondlCounter à la semaine
        elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeWeek then
          lResult  := to_char(iBasisTime, 'YYYYWW');
        -- arrondlCounter au mois
        elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeMonth then
          lResult  := to_char(iBasisTime, 'YYYYMM');
        elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeQuarter then
          -- arrondlCounter au quarter
          lResult  := to_char(iBasisTime, 'YYYYQ');
        -- arrondlCounter au semestre
        elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeHalfYear then
          if to_number(to_char(iBasisTime, 'MM') ) < 7 then
            lResult  := to_char(iBasisTime, 'YYYY') || '1';
          else
            lResult  := to_char(iBasisTime, 'YYYY') || '2';
          end if;
        -- arrondlCounter à l'année
        elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeYear then
          lResult  := to_char(iBasisTime, 'YYYY');
        end if;
      else
        if iContext = 'DOC_POSITION' then
          lResult  := DOC_I_LIB_POSITION.InitExpiryDate(iCharacterizationID, iElementId);
        elsif iContext = 'FAL_LOT' then
          lResult  := FAL_I_LIB_BATCH.InitExpiryDate(iCharacterizationID, iElementId);
        else
          lResult  := to_char(iBasisTime + lLapsingdelay, 'YYYYMMDD');
        end if;
      end if;
    end if;

    return lResult;
  end PropChronologicalFormat;

  /**
  * Description
  *    retourne la valeur de version courante
  */
  function PropVersion(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_PRODUCT.PDT_VERSION%type
  is
    lResult GCO_PRODUCT.PDT_VERSION%type;
  begin
    select PDT_VERSION
      into lResult
      from GCO_PRODUCT
     where GCO_GOOD_ID = iGoodId;

    return lResult;
  end PropVersion;

  /**
  * Description
  *    retourne la valeur de version courante
  */
  function PropVersion(iCharID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return GCO_PRODUCT.PDT_VERSION%type
  is
    lResult GCO_PRODUCT.PDT_VERSION%type;
  begin
    if iCharId is not null then
      if     FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_CHARACTERIZATION', 'C_CHARACT_TYPE', iCharID) = GCO_I_LIB_CONSTANT.gcCharacTypeVersion
         and IsVersioningManagement(iGoodId => FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_CHARACTERIZATION', 'GCO_GOOD_ID', iCharID) ) = 1 then
        return PropVersion(iGoodId => FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_CHARACTERIZATION', 'GCO_GOOD_ID', iCharID) );
      else
        return null;
      end if;
    else
      return null;
    end if;
  end PropVersion;

  function pVerifyCharFormat(
    iCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iValue              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iStrict             in number default 1
  )
    return number
  is
    lCharactType GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
  begin
    -- recherche du type de caractérization
    select C_CHARACT_TYPE
      into lCharactType
      from GCO_CHARACTERIZATION
     where GCO_CHARACTERIZATION_ID = iCharacterizationId;

    -- type chronologique (seul type contraignant)
    if lCharactType = '5' then
      if VerifyChronologicalFormat(iCharacterizationID, iValue) = 1 then
        return 0;
      else
        return lCharactType;
      end if;
    elsif     lCharactType in('1', '3', '4')
          and iStrict = 1 then
      if VerifyPieceSetVersionFormat(iCharacterizationID, iValue) = 1 then
        return 0;
      else
        return lCharactType;
      end if;
    else
      return 0;
    end if;
  exception
    when no_data_found then
      raise_application_error(-20000, iCharacterizationID || '/' || iValue || chr(13) || sqlerrm);
  end pVerifyCharFormat;

  /**
  * Description
  *        fonction qulCounter vérifie l'intégrité d'une valeur de caractérisation
  */
  function VerifyCharFormat(
    iCharacterizationID1 in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationID2 in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationID3 in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationID4 in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationID5 in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iValue1              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iValue2              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iValue3              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iValue4              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iValue5              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  )
    return number
  is
    lCounter       pls_integer   := 1;
    lCharIdList    varchar2(100);
    lCharValueList varchar2(200);
    lResult        number        := 1;
  begin
    lCharIdList     :=
      iCharacterizationID1 || chr(13) || iCharacterizationID2 || chr(13) || iCharacterizationID3 || chr(13) || iCharacterizationID4 || chr(13)
      || iCharacterizationID5;
    lCharValueList  := iValue1 || chr(13) || iValue2 || chr(13) || iValue3 || chr(13) || iValue4 || chr(13) || iValue5;

    while ExtractLine(lCharIdList, lCounter) is not null loop
      lResult   := pVerifyCharFormat(iCharacterizationID => ExtractLine(lCharIdList, lCounter), iValue => ExtractLine(lCharValueList, lCounter) );

      if lResult > 0 then
        return 0;
      end if;

      lCounter  := lCounter + 1;
    end loop;

    return 0;
  end VerifyCharFormat;

  function VerifyCharFormat(
    iCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iValue              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iStrict             in number default 1
  )
    return number
  is
  begin
    -- is pas d'id de caract alors on considère que c'est OK
    if (nvl(iCharacterizationID, 0) = 0) then
      return 1;
    end if;

    if pVerifyCharFormat(iCharacterizationID, iValue, iStrict) = 0 then
      return 1;
    else
      return 0;
    end if;
  end VerifyCharFormat;

  /**
  * Description
  *        fonction qulCounter vérifie l'intégrité d'une valeur de caractérisation
  *        pour la gestion FIFO/LIFO
  */
  function VerifyChronologicalFormat(
    iCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iValue              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  )
    return number
  is
    lUnitOfTime     gco_characterization.c_unit_of_time%type;
    lChronologyType gco_characterization.c_chronology_type%type;
  begin
    select C_UNIT_OF_TIME
         , C_CHRONOLOGY_TYPE
      into lUnitOfTime
         , lChronologyType
      from GCO_CHARACTERIZATION
     where GCO_CHARACTERIZATION_ID = iCharacterizationId;

    return VerifyChronologicalFormatCode(lChronologyType, lUnitOfTime, iValue);
  end VerifyChronologicalFormat;

  /**
  * Description
  *        fonction qulCounter vérifie l'intégrité d'une valeur de caractérisation
  *        pour la gestion FIFO/LIFO
  */
  function VerifyPieceSetVersionFormat(
    iCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iValue              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  )
    return number
  is
    lAutoInc   GCO_CHARACTERIZATION.CHA_AUTOMATIC_INCREMENTATION%type;
    lTrueValue DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
  begin
    select CHA_AUTOMATIC_INCREMENTATION
         , GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iValue
                                                        , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_PREFIXE)
                                                        , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_SUFFIXE)
                                                         )
      into lAutoInc
         , lTrueValue
      from GCO_CHARACTERIZATION
     where GCO_CHARACTERIZATION_ID = iCharacterizationId;

    if lAutoInc = 1 then
      return nvl(sign(PCSToNumber(lTrueValue) ), 0);
    else
      return 1;
    end if;
  end VerifyPieceSetVersionFormat;

  /**
  * Description
  *        fonction qulCounter vérifie l'intégrité d'une valeur de caractérisation
  *        pour la gestion FIFO/LIFO
  */
  function VerifyChronologicalFormatCode(
    iChronologyType in GCO_CHARACTERIZATION.C_CHRONOLOGY_TYPE%type
  , iUnitOfTime     in GCO_CHARACTERIZATION.C_UNIT_OF_TIME%type
  , iValue          in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  )
    return number
  is
    lTempString varchar2(30);
    lResult     number(1)    default 0;
  begin
    if iValue = 'N/A' then
      lResult  := 1;
    elsif iChronologyType in(GCO_I_LIB_CONSTANT.gcChronologyTypeFifo, GCO_I_LIB_CONSTANT.gcChronologyTypeLifo) then
      -- intantanné
      if iUnitOfTime in(GCO_I_LIB_CONSTANT.gcUnitOfTimeInstantaneous, '0') then
        lTempString  := to_date(iValue, 'YYYYMMDD HH24:MI:SS');

        if length(iValue) <> length('YYYYMMDD HH:MI:SS') then
          raise value_error;
        end if;
      -- arrondlCounter à la minute
      elsif iUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeMinute then
        lTempString  := to_date(substr(iValue, 1, 14), 'YYYYMMDD HH24:MI');

        if substr(iValue, 15) <> ':00' then
          raise value_error;
        end if;

        if length(iValue) <> length('YYYYMMDD HH:MI:00') then
          raise value_error;
        end if;
      -- arrondlCounter à l'heure
      elsif iUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeHeure then
        lTempString  := to_date(substr(iValue, 1, 11), 'YYYYMMDD HH24');

        if substr(iValue, 12) <> ':00:00' then
          raise value_error;
        end if;

        if length(iValue) <> length('YYYYMMDD HH:00:00') then
          raise value_error;
        end if;
      -- arrondlCounter au demlCounter jour
      elsif iUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeHalfDay then
        lTempString  := to_date(substr(iValue, 1, 11), 'YYYYMMDD HH24');

        if substr(iValue, 12) <> ':00:00' then
          raise value_error;
        end if;

        if substr(iValue, 10, 2) not in('00', '12') then
          raise value_error;
        end if;

        if length(iValue) <> length('YYYYMMDD HH:MI:SS') then
          raise value_error;
        end if;
      -- arrondlCounter au jour
      elsif iUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeDay then
        lTempString  := to_date(iValue, 'YYYYMMDD');

        if length(iValue) <> length('YYYYMMDD') then
          raise value_error;
        end if;
      -- arrondlCounter à la semaine
      elsif iUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeWeek then
        lTempString  := to_date(substr(iValue, 1, 4), 'YYYY');

        if not to_number(substr(iValue, 5, 2) ) between 1 and 53 then
          raise value_error;
        end if;

        if length(iValue) <> length('YYYYWW') then
          raise value_error;
        end if;
      -- arrondlCounter au mois
      elsif iUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeMonth then
        lTempString  := to_date(iValue, 'YYYYMM');

        if length(iValue) <> length('YYYYMM') then
          raise value_error;
        end if;
      -- arrondlCounter au quarter
      elsif iUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeQuarter then
        lTempString  := to_date(substr(iValue, 1, 4), 'YYYY');

        if not to_number(substr(iValue, 5, 1) ) between 1 and 4 then
          raise value_error;
        end if;

        if length(iValue) <> length('YYYYQ') then
          raise value_error;
        end if;
      -- arrondlCounter au semestre
      elsif iUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeHalfYear then
        if substr(iValue, 5) in('1', '2') then
          lTempString  := to_date(substr(iValue, 1, 4), 'YYYY');
        else
          raise value_error;
        end if;
      -- arrondlCounter à l'année
      elsif iUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeYear then
        lTempString  := to_date(iValue, 'YYYY');

        if length(iValue) <> length('YYYY') then
          raise value_error;
        end if;
      end if;

      lResult  := 1;
    elsif iChronologyType in(GCO_I_LIB_CONSTANT.gcChronologyTypePeremption) then
      lTempString  := to_date(iValue, 'YYYYMMDD');

      if length(iValue) <> length('YYYYMMDD') then
        raise value_error;
      end if;

      lResult      := 1;
    end if;

    return lResult;
  exception
    when others then
      return 0;
  end VerifyChronologicalFormatCode;

  /*
  * procedure GetAutoIncrementInfo
  *   procedure qui retourne la valeur du dernier numéro
  *   de pièce utilisé pour les caractérisations de type
  *   autoincrémental ainsi que la valeur du pas d'incrément
  */
  procedure GetAutoIncrementInfo(
    iCharacterizationID in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oLastUsedNumber     out    number
  , oIncrementStep      out    number
  , oPrefix             out    varchar2
  , oLenNumber          out    number
  , oSuffix             out    varchar2
  , oAutoIncFunction    out    number
  , oAutoInc            out    number
  , oUnique             out    number
  , oStockManagement    out    number
  )
  is
    lCharactType    GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lLastUsedNumber GCO_CHARACTERIZATION.CHA_LAST_USED_INCREMENT%type;
    lcPrefix        GCO_CHARACTERIZATION.CHA_PREFIXE%type;
    lcSuffix        GCO_CHARACTERIZATION.CHA_SUFFIXE%type;
    lIncrementStep  GCO_CHARACTERIZATION.CHA_INCREMENT_STE%type;
  begin
    if iCharacterizationId = 0 then
      return;
    end if;

    begin
      select CHA.C_CHARACT_TYPE
           , decode(CHA.CHA_AUTOMATIC_INCREMENTATION, 1, nvl(CHA.CHA_LAST_USED_INCREMENT, 0), null)
           , decode(CHA.CHA_INCREMENT_STE, null, 1, 0, 1, CHA.CHA_INCREMENT_STE)
           , CHA.CHA_AUTOMATIC_INCREMENTATION
           , CHA.CHA_PREFIXE
           , CHA.CHA_NUMBER
           , CHA.CHA_SUFFIXE
           , decode(PDT_STOCK_MANAGEMENT, 1, CHA.CHA_STOCK_MANAGEMENT, 0)
           , sign(nvl(CHA.GCO_CHAR_AUTONUM_FUNC_ID, 0) ) * CHA.CHA_AUTOMATIC_INCREMENTATION
        into lCharactType
           , lLastUsedNumber
           , lIncrementStep
           , oAutoInc
           , lcPrefix
           , oLenNumber
           , lcSuffix
           , oStockManagement
           , oAutoIncFunction
        from GCO_CHARACTERIZATION CHA
           , GCO_PRODUCT PDT
       where GCO_CHARACTERIZATION_ID = iCharacterizationID
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID;
    exception
      when no_data_found then
        raise_application_error(-20088, 'PCS - Characterization does not exist');
    end;

    -- Gestion de pièces
    if lCharactType = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
      oUnique  := 1;
    -- Gestion de lots
    elsif lCharactType = GCO_I_LIB_CONSTANT.gcCharacTypeSet then
      if    PCS.PC_CONFIG.GetBooleanConfig('STM_SET_SGL_NUMBERING_COMP')
         or PCS.PC_CONFIG.GetBooleanConfig('STM_SET_SGL_NUMBERING_GOOD')
         or PCS.PC_CONFIG.GetBooleanConfig('STM_SET_SGL_NUMBERING_DET') then
        oUnique  := 1;
      else
        oUnique  := 0;
      end if;
    -- Gestion de versions
    elsif lCharactType = GCO_I_LIB_CONSTANT.gcCharacTypeVersion then
      if    PCS.PC_CONFIG.GetBooleanConfig('STM_VERSION_SGL_NUMBERING_COMP')
         or PCS.PC_CONFIG.GetBooleanConfig('STM_VERSION_SGL_NUMBERING_GOOD')
         or PCS.PC_CONFIG.GetBooleanConfig('STM_VERSION_SGL_NUMBERING_DET') then
        oUnique  := 1;
      else
        oUnique  := 0;
      end if;
    end if;

    -- Garantit un incrément minimum de 1 tout particulièrement si une gestion unique de la caractérisation est demandé.
    if     (lIncrementStep = 0)
       and (oUnique = 1) then
      lIncrementStep  := 1;
    end if;

    -- As default value
    oIncrementStep  := lIncrementStep;

    -- set autoincrement informations
    if     oAutoIncFunction = 0
       and oAutoInc = 1 then
      -- Gestion de pièces
      if lCharactType = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
        if not PCS.PC_CONFIG.GetBooleanConfig('STM_PIECE_SGL_NUMBERING_COMP') then
          -- pas de numérotation unique par mandat, gestion du dernier incrément
          -- au niveau des biens
          if oAutoInc = 1 then
            oLastUsedNumber  := lLastUsedNumber;
          end if;

          oPrefix  := GCO_LIB_CHARACTERIZATION.prefixApplyMacro(lcPrefix);
          oSuffix  := GCO_LIB_CHARACTERIZATION.prefixApplyMacro(lcSuffix);
        else
          -- numérotation unique par mandat, gestion globale des propriété de caractérisation
          select to_number(nvl(PCS.PC_CONFIG.GetConfig('STM_PIECE_INCREMENT_STEP'), '1') )
               , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_PIECE_PREFIX') )
               , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_PIECE_SUFFIX') )
            into oIncrementStep
               , oPrefix
               , oSuffix
            from dual;

          if oAutoInc = 1 then
            oLastUsedNumber  := COM_VAR.getNumeric('STM_LASTUSED_PIECENUMBER', null);
          end if;
        end if;
      -- Gestion de lots
      elsif lCharactType = GCO_I_LIB_CONSTANT.gcCharacTypeSet then
        if not PCS.PC_CONFIG.GetBooleanConfig('STM_SET_SGL_NUMBERING_COMP') then
          -- pas de numérotation unique par mandat, gestion du dernier incrément
          -- au niveau des biens
          if oAutoInc = 1 then
            oLastUsedNumber  := lLastUsedNumber;
          end if;

          oPrefix  := GCO_LIB_CHARACTERIZATION.prefixApplyMacro(lcPrefix);
          oSuffix  := GCO_LIB_CHARACTERIZATION.prefixApplyMacro(lcSuffix);
        else
          -- numérotation unique par mandat, gestion globale des propriété de caractérisation
          select to_number(nvl(PCS.PC_CONFIG.GetConfig('STM_SET_INCREMENT_STEP'), '1') )
               , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_SET_PREFIX') )
               , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_SET_SUFFIX') )
            into oIncrementStep
               , oPrefix
               , oSuffix
            from dual;

          if oAutoInc = 1 then
            oLastUsedNumber  := COM_VAR.getNumeric('STM_LASTUSED_SETNUMBER', null);
          end if;
        end if;
      -- Gestion de versions
      elsif lCharactType = GCO_I_LIB_CONSTANT.gcCharacTypeVersion then
        if not PCS.PC_CONFIG.GetBooleanConfig('STM_VERSION_SGL_NUMBERING_COMP') then
          -- pas de numérotation unique par mandat, gestion du dernier incrément
          -- au niveau des biens
          if oAutoInc = 1 then
            oLastUsedNumber  := lLastUsedNumber;
          end if;

          oPrefix  := GCO_LIB_CHARACTERIZATION.prefixApplyMacro(lcPrefix);
          oSuffix  := GCO_LIB_CHARACTERIZATION.prefixApplyMacro(lcSuffix);
        else
          -- numérotation unique par mandat, gestion globale des propriété de caractérisation
          select to_number(nvl(PCS.PC_CONFIG.GetConfig('STM_VERSION_INCREMENT_STEP'), '1') )
               , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_VERSION_PREFIX') )
               , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_VERSION_SUFFIX') )
            into oIncrementStep
               , oPrefix
               , oSuffix
            from dual;

          if oAutoInc = 1 then
            oLastUsedNumber  := COM_VAR.getNumeric('STM_LASTUSED_VERSIONNUMBER', null);
          end if;
        end if;
      end if;
    end if;
  end GetAutoIncrementInfo;

  /**
  * Description
  *        procedure qui retourne la valeur de caractérization suivante
  *        en fonction des information de numérotation automatique
  */
  function GetNextCharValue(
    iCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iDocPositionId      in number default null
  , iFalLotId           in number default null
  , iStartValue         in number default null
  , iUpdateLastIncrem   in number default 1
  )
    return varchar2
  is
    lvCharValue  DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    lnCharNumber GCO_CHARACTERIZATION.CHA_LAST_USED_INCREMENT%type;
  begin
    GetNextCharValue(iCharacterizationID   => iCharacterizationID
                   , iDocPositionId        => iDocPositionId
                   , iFalLotId             => iFalLotId
                   , iStartValue           => iStartValue
                   , iUpdateLastIncrem     => iUpdateLastIncrem
                   , oIncremValue          => lnCharNumber
                   , oCharValue            => lvCharValue
                    );
    return lvCharValue;
  end GetNextCharValue;

  /**
  * Description
  *        procedure qui retourne la valeur de caractérization suivante et le numéro utilisé pour construire la valeur
  *        en fonction des information de numérotation automatique
  */
  procedure GetNextCharValue(
    iCharacterizationID in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iDocPositionId      in     number default null
  , iFalLotId           in     number default null
  , iStartValue         in     number default null
  , iUpdateLastIncrem   in     number default 1
  , oIncremValue        out    number
  , oCharValue          out    varchar2
  )
  is
    lLastUsedNumber  GCO_CHARACTERIZATION.CHA_LAST_USED_INCREMENT%type;
    lIncrementStep   GCO_CHARACTERIZATION.CHA_INCREMENT_STE%type;
    lAutoIncFunction number(1);
    lNextValue       GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE%type;
    lcPrefix         GCO_CHARACTERIZATION.CHA_PREFIXE%type;
    lnLenNumber      GCO_CHARACTERIZATION.CHA_NUMBER%type;
    lcSuffix         GCO_CHARACTERIZATION.CHA_SUFFIXE%type;
    lAutoNum         number(1);
    lUniqueNum       number(1);
    lStkManagement   number(1);
  begin
    oIncremValue  := null;
    GetAutoIncrementInfo(iCharacterizationID
                       , lLastUsedNumber
                       , lIncrementStep
                       , lcPrefix
                       , lnLenNumber
                       , lcSuffix
                       , lAutoIncFunction
                       , lAutoNum
                       , lUniqueNum
                       , lStkManagement
                        );

    if lAutoIncFunction = 1 then
      if iDocPositionId is not null then
        GCO_CHAR_AUTONUM_FUNCTIONS.CallAndVerify(iCharacterizationId, 'DOC', iDocPositionId, lNextValue);
      elsif iFalLotId is not null then
        GCO_CHAR_AUTONUM_FUNCTIONS.CallAndVerify(iCharacterizationId, 'FAL', iFalLotId, lNextValue);
      else
        GCO_CHAR_AUTONUM_FUNCTIONS.CallAndVerify(iCharacterizationId, null, null, lNextValue);
      end if;

      oCharValue  := lNextValue;
    elsif lLastUsedNumber is not null then
      if lcSuffix = '-YY' then
        lcSuffix  := '-' || to_char(sysdate, 'yy');
      end if;

      -- Utilise éventuellement la valeur de départ de numérotation spécifiée
      lLastUsedNumber  := nvl(iStartValue, lLastUsedNumber);
      oIncremValue     := lLastUsedNumber + lIncrementStep;

      -- Si un nombre de caractère de remplissage est demandé, on effectue un formatage avec des '0' de la partie numérotée
      if (nvl(lnLenNumber, 0) > 0) then
        oCharValue  := lcPrefix || lpad(to_char(oIncremValue), lnLenNumber, '0') || lcSuffix;
      else
        oCharValue  := lcPrefix || to_char(oIncremValue) || lcSuffix;
      end if;

      -- Mise à jour du dernier incrément utilisé demandé ?
      if nvl(iUpdateLastIncrem, 1) = 1 then
        GCO_PRC_CHARACTERIZATION.UpdateCharLastUsedNumber(iCharacterizationId, oCharValue);
      end if;
    else
      oCharValue  := null;
    end if;
  end GetNextCharValue;

  function GetCharacDescr(iCharacterizationId GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type, iLangId PCS.PC_LANG.PC_LANG_ID%type)
    return char
  is
    lResult char(30);
  begin
    select dla_description
      into lResult
      from gco_desc_language
     where GCO_CHARACTERIZATION_ID = iCharacterizationId
       and PC_LANG_ID + 0 = iLangId;

    return lResult;
  exception
    when no_data_found then
      return ' ';
  end GetCharacDescr;

  /**
  * Description
  *     retourne le type de la caractérisation
  */
  function GetCharacType(iCharacterizationId GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return char
  is
    lResult char(1);
  begin
    if iCharacterizationId is not null then
      begin
        select C_CHARACT_TYPE
          into lResult
          from gco_characterization
         where GCO_CHARACTERIZATION_ID = iCharacterizationId;

        return lResult;
      exception
        when no_data_found then
          return '';
      end;
    else
      return '';
    end if;
  end GetCharacType;

  /**
  * Description
  *      Recherche des id et description de caractérization avec gestion stock d'un bien
  */
  procedure GetListOfStkChar(
    iGoodId      in     number
  , oCharac1Id   out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharac2Id   out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharac3Id   out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharac4Id   out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharac5Id   out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharacType1 out    varchar2
  , oCharacType2 out    varchar2
  , oCharacType3 out    varchar2
  , oCharacType4 out    varchar2
  , oCharacType5 out    varchar2
  , oCharacDesc1 out    varchar2
  , oCharacDesc2 out    varchar2
  , oCharacDesc3 out    varchar2
  , oCharacDesc4 out    varchar2
  , oCharacDesc5 out    varchar2
  )
  is
    cursor lcurChar(iGoodId number)
    is
      select   CHA.GCO_CHARACTERIZATION_ID
             , CHA.C_CHARACT_TYPE
             , DES.DLA_DESCRIPTION
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
             , GCO_DESC_LANGUAGE DES
         where CHA.GCO_GOOD_ID = iGoodId
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA.CHA_STOCK_MANAGEMENT = 1
           and PDT.PDT_STOCK_MANAGEMENT = 1
           and DES.GCO_CHARACTERIZATION_ID(+) = CHA.GCO_CHARACTERIZATION_ID
           and DES.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GETUSERLANGID
           and DES.C_TYPE_DESC_LANG(+) = '3'
      order by CHA.GCO_CHARACTERIZATION_ID;

    ltplChar lcurChar%rowtype;
  begin
    open lcurChar(iGoodId);

    fetch lcurChar
     into ltplChar;

    if lcurChar%found then
      oCharac1Id    := ltplChar.GCO_CHARACTERIZATION_ID;
      oCharacType1  := ltplChar.C_CHARACT_TYPE;
      oCharacDesc1  := ltplChar.DLA_DESCRIPTION;
    end if;

    fetch lcurChar
     into ltplChar;

    if lcurChar%found then
      oCharac2Id    := ltplChar.GCO_CHARACTERIZATION_ID;
      oCharacType2  := ltplChar.C_CHARACT_TYPE;
      oCharacDesc2  := ltplChar.DLA_DESCRIPTION;
    end if;

    fetch lcurChar
     into ltplChar;

    if lcurChar%found then
      oCharac3Id    := ltplChar.GCO_CHARACTERIZATION_ID;
      oCharacType3  := ltplChar.C_CHARACT_TYPE;
      oCharacDesc3  := ltplChar.DLA_DESCRIPTION;
    end if;

    fetch lcurChar
     into ltplChar;

    if lcurChar%found then
      oCharac4Id    := ltplChar.GCO_CHARACTERIZATION_ID;
      oCharacType4  := ltplChar.C_CHARACT_TYPE;
      oCharacDesc4  := ltplChar.DLA_DESCRIPTION;
    end if;

    fetch lcurChar
     into ltplChar;

    if lcurChar%found then
      oCharac5Id    := ltplChar.GCO_CHARACTERIZATION_ID;
      oCharacType5  := ltplChar.C_CHARACT_TYPE;
      oCharacDesc5  := ltplChar.DLA_DESCRIPTION;
    end if;

    close lcurChar;
  end GetListOfStkChar;

  /**
  * Description
  *      Recherche des id et description de caractérization avec gestion stock d'un bien
  */
  procedure GetListOfStkChar(
    iGoodId    in     number
  , oCharac1Id out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharac2Id out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharac3Id out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharac4Id out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oCharac5Id out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  )
  is
    lCharacType1 GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lCharacType2 GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lCharacType3 GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lCharacType4 GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lCharacType5 GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lCharacDesc1 GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
    lCharacDesc2 GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
    lCharacDesc3 GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
    lCharacDesc4 GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
    lCharacDesc5 GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
  begin
    GetListOfStkChar(iGoodId        => iGoodId
                   , oCharac1Id     => oCharac1Id
                   , oCharac2Id     => oCharac2Id
                   , oCharac3Id     => oCharac3Id
                   , oCharac4Id     => oCharac4Id
                   , oCharac5Id     => oCharac5Id
                   , oCharacType1   => lCharacType1
                   , oCharacType2   => lCharacType2
                   , oCharacType3   => lCharacType3
                   , oCharacType4   => lCharacType4
                   , oCharacType5   => lCharacType5
                   , oCharacDesc1   => lCharacDesc1
                   , oCharacDesc2   => lCharacDesc2
                   , oCharacDesc3   => lCharacDesc3
                   , oCharacDesc4   => lCharacDesc4
                   , oCharacDesc5   => lCharacDesc5
                    );
  end GetListOfStkChar;

  /**
  * Description
  *    Retourne la prochaine valeur chronologique depuis le stock existant
  *    selon la règle :
  *      Type de chronologie = 2 (LIFO) : sélectionner les caractérisations les
  *        plus récentes disponibles dans l'emplacements du détail de position.
  *      Type de chronologie = 1 (FIFO) : sélectionner les caractérisations les
  *        plus anciennes disponibles dans l'emplacement du détail de position.
  *      Type de chornologie = 3 (Péremption) : sélectionner les lots péremptions
  *        les plus anciens, tout en respectant la marge sur date de péremption.
  */
  procedure pGetAutoChronoFromStock(
    iCharacterizationId in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iLocationId         in     STM_LOCATION.STM_LOCATION_ID%type
  , iThirdId            in     PAC_THIRD.PAC_THIRD_ID%type default null
  , iQuantity           in     number
  , iDateRef            in     date default sysdate
  , ioCharValue         in out varchar2
  , ioBalanceQuantity   in out number
  )
  is
  begin
    for tplCharInfo in (select GCO_GOOD_ID
                             , C_CHRONOLOGY_TYPE
                             , C_UNIT_OF_TIME
                             , CHA_LAPSING_MARGE
                          from GCO_CHARACTERIZATION
                         where GCO_CHARACTERIZATION_ID = iCharacterizationId
                           and C_CHARACT_TYPE = '5') loop
      case
        -- FIFO
      when tplCharInfo.C_CHRONOLOGY_TYPE = GCO_I_LIB_CONSTANT.gcChronologyTypeFifo then
          select   SPO_CHRONOLOGICAL
                 , iQuantity - least(sum(SPO_AVAILABLE_QUANTITY), iQuantity)
              into ioCharValue
                 , ioBalanceQuantity
              from STM_STOCK_POSITION
             where GCO_GOOD_ID = tplCharInfo.GCO_GOOD_ID
               and STM_LOCATION_ID = iLocationId
               and SPO_AVAILABLE_QUANTITY > 0
               and C_POSITION_STATUS = '01'
               and SPO_CHRONOLOGICAL = (select min(SPO_CHRONOLOGICAL)
                                          from STM_STOCK_POSITION
                                         where GCO_GOOD_ID = tplCharInfo.GCO_GOOD_ID
                                           and STM_LOCATION_ID = iLocationId
                                           and SPO_AVAILABLE_QUANTITY > 0
                                                                         --and C_POSITION_STATUS = '01'
                                      )
          group by SPO_CHRONOLOGICAL;
        -- LIFO
      when tplCharInfo.C_CHRONOLOGY_TYPE = GCO_I_LIB_CONSTANT.gcChronologyTypeLifo then
          select   SPO_CHRONOLOGICAL
                 , iQuantity - least(sum(SPO_AVAILABLE_QUANTITY), iQuantity)
              into ioCharValue
                 , ioBalanceQuantity
              from STM_STOCK_POSITION
             where GCO_GOOD_ID = tplCharInfo.GCO_GOOD_ID
               and STM_LOCATION_ID = iLocationId
               and SPO_AVAILABLE_QUANTITY > 0
               and C_POSITION_STATUS = '01'
               and SPO_CHRONOLOGICAL =
                     (select max(SPO_CHRONOLOGICAL)
                        from STM_STOCK_POSITION
                       where GCO_GOOD_ID = tplCharInfo.GCO_GOOD_ID
                         and STM_LOCATION_ID = iLocationId
                         and SPO_AVAILABLE_QUANTITY > 0
                         and C_POSITION_STATUS = '01')
          group by SPO_CHRONOLOGICAL;
        -- Peremption
      when tplCharInfo.C_CHRONOLOGY_TYPE = GCO_I_LIB_CONSTANT.gcChronologyTypePeremption then
          select   SPO_CHRONOLOGICAL
                 , iQuantity - least(sum(SPO_AVAILABLE_QUANTITY), iQuantity)
              into ioCharValue
                 , ioBalanceQuantity
              from STM_STOCK_POSITION
             where GCO_GOOD_ID = tplCharInfo.GCO_GOOD_ID
               and STM_LOCATION_ID = iLocationId
               and SPO_AVAILABLE_QUANTITY > 0
               and C_POSITION_STATUS = '01'
               and SPO_CHRONOLOGICAL =
                     (select min(SPO_CHRONOLOGICAL)
                        from STM_STOCK_POSITION
                       where GCO_GOOD_ID = tplCharInfo.GCO_GOOD_ID
                         and STM_LOCATION_ID = iLocationId
                         and SPO_AVAILABLE_QUANTITY > 0
                         and C_POSITION_STATUS = '01'
                         and trunc(GCO_I_LIB_CHARACTERIZATION.ChronoFormatToDate(SPO_CHRONOLOGICAL, GCO_I_LIB_CHARACTERIZATION.GetChronoCharID(GCO_GOOD_ID) ) ) -
                             getLapsingMarge(GCO_GOOD_ID, iThirdId) -
                             trunc(iDateRef) >= 0)
          group by SPO_CHRONOLOGICAL;
      end case;
    end loop;
  exception
    when no_data_found then
      ioBalanceQuantity  := iQuantity;
  end pGetAutoChronoFromStock;

  /**
  * Description
  *    Retourne la prochaine valeur chronologique depuis le stock existant
  *    selon la règle :
  *      Type de chronologie = 2 (LIFO) : sélectionner les caractérisations les
  *        plus récentes disponibles dans l'emplacements du détail de position.
  *      Type de chronologie = 1 (FIFO) : sélectionner les caractérisations les
  *        plus anciennes disponibles dans l'emplacement du détail de position.
  *      Type de chornologie = 3 (Péremption) : sélectionner les lots péremptions
  *        les plus anciens, tout en respectant la marge sur date de péremption.
  */
  procedure getAutoChronoFromStock(
    iCharacterizationId1 in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationId2 in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationId3 in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationId4 in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationId5 in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iLocationId          in     STM_LOCATION.STM_LOCATION_ID%type
  , iThirdId             in     PAC_THIRD.PAC_THIRD_ID%type default null
  , iQuantity            in     number
  , iDateRef             in     date default sysdate
  , ioCharValue1         in out varchar2
  , ioCharValue2         in out varchar2
  , ioCharValue3         in out varchar2
  , ioCharValue4         in out varchar2
  , ioCharValue5         in out varchar2
  , oBalanceQuantity     out    number
  )
  is
  begin
    case
      when     iCharacterizationId1 is not null
           and GetCharacType(iCharacterizationId1) = '5' then
        pGetAutoChronoFromStock(iCharacterizationId1, iLocationId, iThirdId, iQuantity, iDateRef, ioCharValue1, oBalanceQuantity);
      when     iCharacterizationId2 is not null
           and GetCharacType(iCharacterizationId2) = '5' then
        pGetAutoChronoFromStock(iCharacterizationId2, iLocationId, iThirdId, iQuantity, iDateRef, ioCharValue2, oBalanceQuantity);
      when     iCharacterizationId3 is not null
           and GetCharacType(iCharacterizationId3) = '5' then
        pGetAutoChronoFromStock(iCharacterizationId3, iLocationId, iThirdId, iQuantity, iDateRef, ioCharValue3, oBalanceQuantity);
      when     iCharacterizationId4 is not null
           and GetCharacType(iCharacterizationId4) = '5' then
        pGetAutoChronoFromStock(iCharacterizationId4, iLocationId, iThirdId, iQuantity, iDateRef, ioCharValue4, oBalanceQuantity);
      when     iCharacterizationId5 is not null
           and GetCharacType(iCharacterizationId5) = '5' then
        pGetAutoChronoFromStock(iCharacterizationId5, iLocationId, iThirdId, iQuantity, iDateRef, ioCharValue5, oBalanceQuantity);
    end case;
  end getAutoChronoFromStock;

  /**
  * Description
  *    Retourne la prochaine valeur chronologique depuis le stock existant
  *    selon la règle :
  *      Type de chronologie = 2 (LIFO) : sélectionner les caractérisations les
  *        plus récentes disponibles dans l'emplacements du détail de position.
  *      Type de chronologie = 1 (FIFO) : sélectionner les caractérisations les
  *        plus anciennes disponibles dans l'emplacement du détail de position.
  *      Type de chornologie = 3 (Péremption) : sélectionner les lots péremptions
  *        les plus anciens, tout en respectant la marge sur date de péremption.
  */
  procedure getAutoCharFromStock(
    iGoodId          in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId1         in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId2         in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId3         in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId4         in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId5         in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iLocationId      in     STM_LOCATION.STM_LOCATION_ID%type
  , iThirdId         in     PAC_THIRD.PAC_THIRD_ID%type default null
  , iQuantity        in     number
  , iDateRef         in     date default sysdate
  , ioCharValue1     in out varchar2
  , ioCharValue2     in out varchar2
  , ioCharValue3     in out varchar2
  , ioCharValue4     in out varchar2
  , ioCharValue5     in out varchar2
  , iAutoChar        in     DOC_GAUGE_STRUCTURED.GAS_AUTO_CHARACTERIZATION%type
  , oBalanceQuantity out    number
  )
  is
    lSql   varchar2(32000);

    type ttSPO is table of STM_PRC_STOCK_POSITION.gcurSPO%rowtype;

    lttSPO ttSPO;
  begin
    if GCO_LIB_FUNCTIONS.IsStockManagement(iGoodId) then
      -- Construit la requête sur STM_STOCK_POSITION
      STM_PRC_STOCK_POSITION.BuildSTM_STOCK_POSITIONQuery(oSQLQuery        => lSql
                                                        , iLocationId      => iLocationId
                                                        , iGoodId          => iGoodID
                                                        , iForceLocation   => 1
                                                        , iLotId           => 0
                                                        , iAutoChar        => iAutoChar
                                                        , iThirdId         => iThirdId
                                                        , iDateRef         => iDateRef
                                                         );

      -- Execute la requête sur STM_STOCK_POSITION en une fois
      execute immediate lSql
      bulk collect into lttSPO;

      -- si trouvé qqch, assignation des valeur de caractérisation et de la qté solde,
      -- Sinon qté solde = qté demandée
      if lttSPO.count > 0 then
        if iCharId1 = lttSPO(1).GCO_CHARACTERIZATION_ID then
          ioCharvalue1  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_1;
        elsif iCharId1 = lttSPO(1).GCO_GCO_CHARACTERIZATION_ID then
          ioCharvalue1  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_2;
        elsif iCharId1 = lttSPO(1).GCO2_GCO_CHARACTERIZATION_ID then
          ioCharvalue1  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_3;
        elsif iCharId1 = lttSPO(1).GCO3_GCO_CHARACTERIZATION_ID then
          ioCharvalue1  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_4;
        elsif iCharId1 = lttSPO(1).GCO4_GCO_CHARACTERIZATION_ID then
          ioCharvalue1  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_5;
        end if;

        if iCharId2 = lttSPO(1).GCO_CHARACTERIZATION_ID then
          ioCharvalue2  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_1;
        elsif iCharId2 = lttSPO(1).GCO_GCO_CHARACTERIZATION_ID then
          ioCharvalue2  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_2;
        elsif iCharId2 = lttSPO(1).GCO2_GCO_CHARACTERIZATION_ID then
          ioCharvalue2  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_3;
        elsif iCharId2 = lttSPO(1).GCO3_GCO_CHARACTERIZATION_ID then
          ioCharvalue2  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_4;
        elsif iCharId2 = lttSPO(1).GCO4_GCO_CHARACTERIZATION_ID then
          ioCharvalue2  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_5;
        end if;

        if iCharId3 = lttSPO(1).GCO_CHARACTERIZATION_ID then
          ioCharvalue3  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_1;
        elsif iCharId3 = lttSPO(1).GCO_GCO_CHARACTERIZATION_ID then
          ioCharvalue3  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_2;
        elsif iCharId3 = lttSPO(1).GCO2_GCO_CHARACTERIZATION_ID then
          ioCharvalue3  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_3;
        elsif iCharId3 = lttSPO(1).GCO3_GCO_CHARACTERIZATION_ID then
          ioCharvalue3  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_4;
        elsif iCharId3 = lttSPO(1).GCO4_GCO_CHARACTERIZATION_ID then
          ioCharvalue3  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_5;
        end if;

        if iCharId4 = lttSPO(1).GCO_CHARACTERIZATION_ID then
          ioCharvalue4  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_1;
        elsif iCharId4 = lttSPO(1).GCO_GCO_CHARACTERIZATION_ID then
          ioCharvalue4  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_2;
        elsif iCharId4 = lttSPO(1).GCO2_GCO_CHARACTERIZATION_ID then
          ioCharvalue4  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_3;
        elsif iCharId4 = lttSPO(1).GCO3_GCO_CHARACTERIZATION_ID then
          ioCharvalue4  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_4;
        elsif iCharId4 = lttSPO(1).GCO4_GCO_CHARACTERIZATION_ID then
          ioCharvalue4  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_5;
        end if;

        if iCharId5 = lttSPO(1).GCO_CHARACTERIZATION_ID then
          ioCharvalue5  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_1;
        elsif iCharId5 = lttSPO(1).GCO_GCO_CHARACTERIZATION_ID then
          ioCharvalue5  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_2;
        elsif iCharId5 = lttSPO(1).GCO2_GCO_CHARACTERIZATION_ID then
          ioCharvalue5  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_3;
        elsif iCharId5 = lttSPO(1).GCO3_GCO_CHARACTERIZATION_ID then
          ioCharvalue5  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_4;
        elsif iCharId5 = lttSPO(1).GCO4_GCO_CHARACTERIZATION_ID then
          ioCharvalue5  := lttSPO(1).SPO_CHARACTERIZATION_VALUE_5;
        end if;

        oBalanceQuantity  := greatest(iQuantity - nvl(lttSPO(1).SPO_AVAILABLE_QUANTITY, 0), 0);
      else
        oBalanceQuantity  := iQuantity;
      end if;
    end if;
  end getAutoCharFromStock;

  /**
  * Description
  *   retourne description d'une caractérisation
  *   dans la langue souhaitée
  */
  function GetCharacDescr4Prnt(iCharacterizationId GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type, iLanid PCS.PC_LANG.LANID%type)
    return GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type
  is
    lCharactDescr GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
  begin
    select DLA.DLA_DESCRIPTION
      into lCharactDescr
      from GCO_DESC_LANGUAGE DLA
         , PCS.PC_LANG LAN
     where DLA.GCO_CHARACTERIZATION_ID = iCharacterizationId
       and DLA.C_TYPE_DESC_LANG = '3'
       and DLA.PC_LANG_ID = LAN.PC_LANG_ID
       and LAN.LANID = iLanid;

    return lCharactDescr;
  exception
    when no_data_found then
      return null;
  end GetCharacDescr4Prnt;

  /**
  * Description
  *   indique si la caractérisation d'un produit est modifiable
  *   utilisée par le trigger GCO_CHA_BIUD_INTEGRITY et par le réplicator
  */
  function IsCharactUpdatable(iOldGcoGoodId in GCO_GOOD.GCO_GOOD_ID%type, iNewGcoGoodId in GCO_GOOD.GCO_GOOD_ID%type, oMessageError out varchar2)
    return number
  is
    lnTemp        number(12);
    lGoodId       number(12);
    lMessageError varchar2(4000);
    lIsUpdatable  number;
    lLangId       PCS.PC_LANG.PC_LANG_ID%type;
  begin
    lIsUpdatable   := 1;
    lMessageError  := '';
    lLangId        := nvl(PCS.PC_I_LIB_SESSION.getUserLangId, PCS.PC_I_LIB_SESSION.GetCompLangId);

    -- cette commande provoque volontairement une exception (trappée) si l'effacement
    -- vient depuis l'effacement d'un bien
    select max(GCO_GOOD_ID)
      into lnTemp
      from GCO_GOOD
     where GCO_GOOD_ID = nvl(iOldGcoGoodId, iNewGcoGoodId);

    -- ne permet pas de modifier les caractérisation si le bien est déjà utilisé dans les mouvements de stock
    -- implicitement dans les positions de stock et les évolutions annuelles et exercice
    select max(GCO_GOOD_ID)
      into lnTemp
      from STM_STOCK_MOVEMENT
     where GCO_GOOD_ID = nvl(iOldGcoGoodId, iNewGcoGoodId);

    if lnTemp is not null then
      lIsUpdatable   := 0;
      lMessageError  := PCS.PC_LIB_TABLE.GetTableDescr('STM_STOCK_MOVEMENT', lLangId) || CO.cLineBreak;
    end if;

    -- ne permet pas de mpodifier les caractérisation si le bien est déjà utilisé dans les positions de document
    -- implicitement dans les totalisateurs
    select max(GCO_GOOD_ID)
      into lnTemp
      from DOC_POSITION
     where GCO_GOOD_ID = nvl(iOldGcoGoodId, iNewGcoGoodId);

    if lnTemp is not null then
      lIsUpdatable   := 0;
      lMessageError  := lMessageError || PCS.PC_LIB_TABLE.GetTableDescr('DOC_POSITION', lLangId) || CO.cLineBreak;
    end if;

    -- ne permet pas de mpodifier les caractérisation si le bien est déjà utilisé dans les positions de document
    -- implicitement dans les totalisateurs
    select max(GCO_GOOD_ID)
      into lnTemp
      from FAL_FACTORY_IN
     where GCO_GOOD_ID = nvl(iOldGcoGoodId, iNewGcoGoodId);

    if lnTemp is not null then
      lIsUpdatable   := 0;
      lMessageError  := lMessageError || PCS.PC_LIB_TABLE.GetTableDescr('FAL_FACTORY_IN', lLangId) || CO.cLineBreak;
    end if;

    -- ne permet pas de mpodifier les caractérisation si le bien est déjà utilisé dans les positions de document
    -- implicitement dans les totalisateurs
    select max(GCO_GOOD_ID)
      into lnTemp
      from FAL_NETWORK_NEED
     where GCO_GOOD_ID = nvl(iOldGcoGoodId, iNewGcoGoodId);

    if lnTemp is not null then
      lIsUpdatable   := 0;
      lMessageError  := lMessageError || PCS.PC_LIB_TABLE.GetTableDescr('FAL_NETWORK_NEED', lLangId) || CO.cLineBreak;
    end if;

    -- ne permet pas de mpodifier les caractérisation si le bien est déjà utilisé dans les positions de document
    -- implicitement dans les totalisateurs
    select max(GCO_GOOD_ID)
      into lnTemp
      from FAL_NETWORK_SUPPLY
     where GCO_GOOD_ID = nvl(iOldGcoGoodId, iNewGcoGoodId);

    if lnTemp is not null then
      lIsUpdatable   := 0;
      lMessageError  := lMessageError || PCS.PC_LIB_TABLE.GetTableDescr('FAL_NETWORK_SUPPLY', lLangId) || CO.cLineBreak;
    end if;

    -- ne permet pas de mpodifier les caractérisation si le bien est déjà utilisé dans les positions de document
    -- implicitement dans les totalisateurs
    select max(GCO_GOOD_ID)
      into lnTemp
      from FAL_LOT_PROP
     where GCO_GOOD_ID = nvl(iOldGcoGoodId, iNewGcoGoodId);

    if lnTemp is not null then
      lIsUpdatable   := 0;
      lMessageError  := lMessageError || PCS.PC_LIB_TABLE.GetTableDescr('FAL_LOT_PROP', lLangId) || CO.cLineBreak;
    end if;

    -- ne permet pas de mpodifier les caractérisation si le bien est déjà utilisé dans les positions de document
    -- implicitement dans les totalisateurs
    select max(GCO_GOOD_ID)
      into lnTemp
      from FAL_DOC_PROP
     where GCO_GOOD_ID = nvl(iOldGcoGoodId, iNewGcoGoodId);

    if lnTemp is not null then
      lIsUpdatable   := 0;
      lMessageError  := lMessageError || PCS.PC_LIB_TABLE.GetTableDescr('FAL_DOC_PROP', lLangId) || CO.cLineBreak;
    end if;

    -- ne permet pas de mpodifier les caractérisation si le bien est déjà utilisé dans les positions de document
    -- implicitement dans les totalisateurs
    select max(GCO_GOOD_ID)
      into lnTemp
      from FAL_LOT_DETAIL
     where GCO_GOOD_ID = nvl(iOldGcoGoodId, iNewGcoGoodId);

    if lnTemp is not null then
      lIsUpdatable   := 0;
      lMessageError  := lMessageError || PCS.PC_LIB_TABLE.GetTableDescr('FAL_LOT_DETAIL', lLangId) || CO.cLineBreak;
    end if;

    if lIsUpdatable = 0 then
      oMessageError  :=
        CO.cLineBreak || pcs.pc_functions.translateword('Impossible de modifier la charactérisation', lLangId) || CO.cLineBreak || CO.cLineBreak
        || lMessageError;
    end if;

    return lIsUpdatable;
  exception
    when ex.TABLE_MUTATING then
      lIsUpdatable  := 1;
      return lIsUpdatable;
  end IsCharactUpdatable;

  /**
  * Description
  *   indique si la caractérisation d'un produit est modifiable
  *   utilisée par le trigger GCO_CHA_BIUD_INTEGRITY et par le réplicator
  */
  function IsCharactUpdatable(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lMessageError varchar2(4000);
  begin
    return IsCharactUpdatable(iGoodId, iGoodId, lMessageError);
  end IsCharactUpdatable;

  /**
  * procedure getCharIDandPos
  * Description
  *      Retourne l'id de caractérisation et la position selon le bien et le type de caractérisation
  */
  procedure getCharIDandPos(
    iGoodId in     GCO_GOOD.GCO_GOOD_ID%type
  , iType   in     GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , oCharID out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , oPos    out    number
  )
  is
    cursor lcurCharlist(iGoodId number)
    is
      select   GCO_CHARACTERIZATION_ID
             , C_CHARACT_TYPE
          from GCO_CHARACTERIZATION
         where GCO_GOOD_ID = iGoodId
      order by GCO_CHARACTERIZATION_ID;

    ltplCharlist lcurCharlist%rowtype;
  begin
    oPos     := null;
    ocharID  := null;

    open lcurCharlist(iGoodId);

    loop
      fetch lcurCharlist
       into ltplCharlist;

      exit when lcurCharlist%notfound;

      if ltplCharlist.C_CHARACT_TYPE = iType then
        oCharID  := ltplCharlist.GCO_CHARACTERIZATION_ID;
        oPos     := lcurCharlist%rowcount;
      end if;
    end loop;

    close lcurCharlist;
  end getCharIDandPos;

  /**
  * Description
  *      enlève les trous
  */
  procedure CompactElementNumbers(
    ioEleNum1 in out STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , ioEleNum2 in out STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , ioEleNum3 in out STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  )
  is
    lTemp varchar2(50);
    i     pls_integer  := 1;
  begin
    lTemp      := ioEleNum1 || ',' || ioEleNum2 || ',' || ioEleNum3;
    ioEleNum1  := null;
    ioEleNum2  := null;
    ioEleNum3  := null;

    while i <= 3
     and ioEleNum1 is null loop
      ioEleNum1  := ExtractLine(lTemp, i, ',');
      i          := i + 1;
    end loop;

    while i <= 3
     and ioEleNum2 is null loop
      ioEleNum2  := ExtractLine(lTemp, i, ',');
      i          := i + 1;
    end loop;

    while i <= 3
     and ioEleNum3 is null loop
      ioEleNum3  := ExtractLine(lTemp, i, ',');
      i          := i + 1;
    end loop;
  end CompactElementNumbers;

  /**
  * Description
  *      Défini si une charactérisation est nulle (prend aussi en compte la valeur 'N/A')
  */
  function CharIsNull(iCharValue in varchar2)
    return boolean
  is
  begin
    return    iCharValue is null
           or iCharValue = 'N/A';
  end CharIsNull;

  /**
  * Description
  *   retourne le nombre de caractérisastions gérées en stock d'un produit
  */
  function NbCharInStock(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult number(1);
  begin
    select count(*)
      into lResult
      from GCO_CHARACTERIZATION CHA
         , GCO_PRODUCT PDT
     where PDT.GCO_GOOD_ID = iGoodId
       and CHA.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and CHA_STOCK_MANAGEMENT = 1
       and PDT_STOCK_MANAGEMENT = 1;

    return lResult;
  end NbCharInStock;

  /**
  * Description
  *   Indicates if a characterization is stock-managed
  */
  function IsCharInStock(iCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return number
  is
    lResult number(1);
  begin
    if nvl(iCharacterizationId, 0) = 0 then
      return null;
    else
      select count(*)
        into lResult
        from GCO_CHARACTERIZATION CHA
           , GCO_PRODUCT PDT
       where CHA.GCO_CHARACTERIZATION_ID = iCharacterizationId
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
         and CHA_STOCK_MANAGEMENT = 1
         and PDT_STOCK_MANAGEMENT = 1;

      return lResult;
    end if;
  end IsCharInStock;

  /**
  * Description
  *   Indique si un bien gère le détail des caractérisations
  */
  function GoodUseDetail(iGoodID in GCO_CHARACTERIZATION.GCO_GOOD_ID%type)
    return number
  is
    lResult number(1) := 0;
  begin
    if GCO_I_LIB_CONSTANT.gcCfgChaUseDetail then
      select count(*)
        into lResult
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iGoodId
         and CHA_USE_DETAIL = 1;
    end if;

    if lResult > 1 then
      ra(replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Plus d''une caractérisation gère le detail sur le bien [GOO_MAJOR_REFERENCE]')
               , '[GOO_MAJOR_REFERENCE]'
               , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iGoodId)
                )
        );
    else
      return lResult;
    end if;
  end GoodUseDetail;

  /**
  * function GetUseDetailCharID
  * Description
  *   Renvoi l'id de la caractération qui gére le détail des caractérisations
  */
  function GetUseDetailCharID(iGoodID in GCO_CHARACTERIZATION.GCO_GOOD_ID%type)
    return GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  is
    lCharID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    if GCO_I_LIB_CONSTANT.gcCfgChaUseDetail then
      select GCO_CHARACTERIZATION_ID
        into lCharID
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iGoodId
         and CHA_USE_DETAIL = 1;
    end if;

    return lCharID;
  exception
    when no_data_found then
      return null;
    when too_many_rows then
      ra(replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Plus d''une caractérisation gère le detail sur le bien [GOO_MAJOR_REFERENCE]')
               , '[GOO_MAJOR_REFERENCE]'
               , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iGoodId)
                )
        );
  end GetUseDetailCharID;

  /**
  * Description
  *   Indique si le bien gère les status qualité
  */
  function HasQualityStatusManagement(iGoodID in GCO_PRODUCT.GCO_GOOD_ID%type)
    return GCO_CHARACTERIZATION.CHA_QUALITY_STATUS_MGMT%type
  is
    lTemp number(1) := 0;
  begin
    if STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      begin
        select 1
          into lTemp
          from GCO_CHARACTERIZATION
         where GCO_GOOD_ID = iGoodId
           and CHA_QUALITY_STATUS_MGMT = 1;

        return 1;
      exception
        when no_data_found then
          -- si pas trouvé
          return 0;
      end;
    else
      return 0;
    end if;
  end HasQualityStatusManagement;

  /**
  * function GetDetailledValue
  * Description
  *   retourne la valeur de la caractérisation qui est détaillée
  * @created fpe 23.10.2013
  * @updated
  * @public
  * @param iCharId1..5 : identifiant des caractérisations
  * @param iCharValue1..5 : valeurs de caractérisations
  * @return voir description
  */
  function GetDetailledValue(
    iCharId1    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId2    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId3    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId4    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharId5    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharValue1 in GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE%type
  , iCharValue2 in GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE%type
  , iCharValue3 in GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE%type
  , iCharValue4 in GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE%type
  , iCharValue5 in GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE%type
  )
    return GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE%type
  is
    lCharDetId GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
                                                 := GetUseDetailCharID(FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_CHARACTERIZATION', 'GCO_GOOD_ID', iCharId1) );
  begin
    case
      when lCharDetId = iCharId1 then
        return iCharValue1;
      when lCharDetId = iCharId2 then
        return iCharValue2;
      when lCharDetId = iCharId3 then
        return iCharValue3;
      when lCharDetId = iCharId4 then
        return iCharValue4;
      when lCharDetId = iCharId5 then
        return iCharValue5;
      else
        return null;
    end case;
  end GetDetailledValue;

  /**
  * function IsRetestManagement
  * Description
  *   Est-ce que le produit possède la gestion de la date de ré-analyse
  */
  function IsRetestManagement(iGoodID in number)
    return number
  is
    lResult number(1) := 0;
  begin
    if GCO_I_LIB_CONSTANT.gcCfgChaUseDetail then
      select sign(nvl(max(GCO_CHARACTERIZATION_ID), 0) )
        into lResult
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iGoodId
         and CHA_WITH_RETEST = 1;
    end if;

    return lResult;
  end IsRetestManagement;

  /**
  * function GetRetestDelay
  * Description
  *   Renvoi le delay de ré-analyse du produit
  */
  function GetRetestDelay(iGoodID in number)
    return GCO_CHARACTERIZATION.CHA_RETEST_DELAY%type
  is
    lRetestDelay GCO_CHARACTERIZATION.CHA_RETEST_Delay%type;
  begin
    select nvl(CHA_RETEST_DELAY, 0)
      into lRetestDelay
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodId
       and CHA_WITH_RETEST = 1;

    return lRetestDelay;
  exception
    when no_data_found then
      return null;
  end GetRetestDelay;

  /**
  * function GetInitialRetestDelay
  * Description
  *   Renvoi le delai initial de ré-analyse du produit
  */
  function GetInitialRetestDelay(iGoodID in number, iDateMvt date)
    return STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type
  is
  begin
    return trunc(iDateMvt) + GetRetestDelay(iGoodId);
  end GetInitialRetestDelay;

  /**
  * function GetRetestMargin
  * Description
  *   Renvoi la marge de ré-analyse du produit
  */
  function GetRetestMargin(iGoodID in number)
    return GCO_CHARACTERIZATION.CHA_RETEST_MARGIN%type
  is
    lRetestMargin GCO_CHARACTERIZATION.CHA_RETEST_MARGIN%type;
  begin
    select nvl(CHA_RETEST_MARGIN, 0)
      into lRetestMargin
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodId
       and CHA_WITH_RETEST = 1;

    return lRetestMargin;
  exception
    when no_data_found then
      return null;
  end GetRetestMargin;

  /**
  * Description
  *   Indique si la caracterisation gère les status qualité
  */
  function charUseQualityStatus(iCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return GCO_CHARACTERIZATION.CHA_QUALITY_STATUS_MGMT%type
  is
    lTemp number(1) := 0;
  begin
    if STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      begin
        select 1
          into lTemp
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCharacterizationId
           and CHA_QUALITY_STATUS_MGMT = 1;

        return 1;
      exception
        when no_data_found then
          -- si pas trouvé
          return 0;
      end;
    else
      return 0;
    end if;
  end charUseQualityStatus;

  /**
  * function GetQualityStatusCharID
  * Description
  *   Renvoi l'id de la caractérisation qui gère le statut qualité
  */
  function GetQualityStatusCharID(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  is
    lCharID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
  begin
    if STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      begin
        select GCO_CHARACTERIZATION_ID
          into lCharID
          from GCO_CHARACTERIZATION
         where GCO_GOOD_ID = iGoodID
           and CHA_QUALITY_STATUS_MGMT = 1;

        return lCharID;
      exception
        when no_data_found then
          return null;
      end;
    else
      return null;
    end if;
  end GetQualityStatusCharID;

  /**
  * Description
  *   Indique si la caracterisation gère la date de ré-analyse
  */
  function charUseRetestDate(iCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return GCO_CHARACTERIZATION.CHA_WITH_RETEST%type
  is
    lTemp number(1) := 0;
  begin
    if GCO_I_LIB_CONSTANT.gcCfgChaUseDetail then
      begin
        select 1
          into lTemp
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCharacterizationId
           and CHA_WITH_RETEST = 1;

        return 1;
      exception
        when no_data_found then
          -- si pas trouvé
          return 0;
      end;
    else
      return 0;
    end if;
  end charUseRetestDate;

  /**
  * Description
  *   Détermine si la date de péremption est dépassée en fonction d'une date spécifiée
  */
  function IsOutdated(
    iGoodID        in GCO_GOOD.GCO_GOOD_ID%type
  , iThirdId       in PAC_THIRD.PAC_THIRD_ID%type
  , iTimeLimitDate in varchar2
  , iDate          in date default sysdate
  , iLapsingMarge  in GCO_CHARACTERIZATION.CHA_LAPSING_MARGE%type default null
  )
    return number
  is
    lnResult        number(1) := 0;
    lPeremptionDate date;
  begin
    return IsOutDated(iGoodId            => iGoodId
                    , iThirdId           => iThirdId
                    , iTimeLimitDate     => iTimeLimitDate
                    , iDate              => iDate
                    , iLapsingMarge      => iLapsingMarge
                    , ioPeremptionDate   => lPeremptionDate
                     );
  end IsOutdated;

  function IsOutdated(
    iGoodID          in     GCO_GOOD.GCO_GOOD_ID%type
  , iThirdId         in     PAC_THIRD.PAC_THIRD_ID%type
  , iTimeLimitDate   in     varchar2
  , iDate            in     date default sysdate
  , iLapsingMarge    in     GCO_CHARACTERIZATION.CHA_LAPSING_MARGE%type default null
  , ioPeremptionDate in out date
  )
    return number
  is
    lnResult      number(1)                                     := 0;
    lLapsingMarge GCO_CHARACTERIZATION.CHA_LAPSING_MARGE%type   := 0;
  begin
    if     iTimeLimitDate is not null
       and (IsTimeLimitManagement(iGoodID) = 1) then
      if iLapsingMarge is null then
        lLapsingMarge  := nvl(getLapsingMarge(iGoodID, iThirdID), 0);
      else
        lLapsingMarge  := iLapsingMarge;
      end if;

      ioPeremptionDate  := to_date(iTimeLimitDate, 'YYYYMMDD') - lLapsingMarge;

      -- Contrôle de la date de péremption - la marge < date de référence
      if ioPeremptionDate < trunc(iDate) then
        lnResult  := 1;
      end if;
    end if;

    return lnResult;
  end IsOutdated;

  /**
  * Description
  *   Détermine si la date de ré-analyse est dépassée en fonction d'une date spécifiée
  */
  function IsRetestNeeded(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iRetestDate in date, iDate in date default sysdate)
    return number
  is
    lnResult number(1) := 0;
  begin
    if    iRetestDate is null
       or iDate is null then
      lnResult  := 0;
        -- Effectuer le contrôle de la date de ré-analyse
    -- La date de ré-analyse est dépassée si :
    --   Config GCO_RETEST_MODE = 0 et Date de retest < Date de référence
    --     OU  Config GCO_RETEST_MODE = 1 et Date de retest - Marge sur retest < Date de référence
    elsif    (     (gcGCO_RETEST_MODE = '0')
              and (iRetestDate < iDate) )
          or (     (gcGCO_RETEST_MODE = '1')
              and (iRetestDate - GetRetestMargin(iGoodID) < trunc(iDate) ) ) then
      lnResult  := 1;
    end if;

    return lnResult;
  end IsRetestNeeded;

  /**
  * Description
  *   Détermine si l'ajout d'un détail de caractérisation est possible
  */
  function CanAddUseDetail(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iCharType in varchar2)
    return number
  is
    lnResult number(1) := 0;
  begin
    begin
      select sign(nvl(max(GCO_GOOD_ID), 0) ) CHAR_EXIST
        into lnResult
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iGoodID
         and C_CHARACT_TYPE = iCharType
         and GCO_I_LIB_CHARACTERIZATION.GoodUseDetail(GCO_GOOD_ID) = 0;

      return lnResult;
    exception
      when no_data_found then
        -- si pas trouvé
        return 0;
    end;
  end CanAddUseDetail;

  /**
  * Description
  *   Retourne le message d'erreur lors de la suppression d'une caractérisation
  */
  function getDelErrorWizardLog(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return varchar2
  is
    lcStartId number;
    lvResult  varchar(4000);
  begin
    begin
      select max(GCO_CHAR_WIZARD_LOG_ID)
        into lcStartId
        from GCO_CHAR_WIZARD_LOG;

      select   CWL_ERROR_COMMENT
          into lvResult
          from GCO_CHAR_WIZARD_LOG
         where GCO_CHAR_WIZARD_LOG_ID >= lcStartId
           and GCO_GOOD_ID = iGoodId
           and C_GCO_CHAR_WIZARD_ACTION = 'ERD'
      order by CWL_MAJOR_REFERENCE;

      return lvResult;
    exception
      when others then
        -- si pas trouvé
        return '';
    end;
  end getDelErrorWizardLog;

  /**
  * Description
  *   Retourne le masque d'édition de la caractérisation
  */
  function getCharMaskFormat(iCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return varchar2
  is
    lvResult GCO_REFERENCE_TEMPLATE.RTE_FORMAT%type;
  begin
    begin
      select TPL.RTE_FORMAT
        into lvResult
        from GCO_REFERENCE_TEMPLATE TPL
           , GCO_CHARACTERIZATION CHA
       where CHA.GCO_CHARACTERIZATION_ID = iCharacterizationId
         and TPL.GCO_REFERENCE_TEMPLATE_ID = CHA.GCO_REFERENCE_TEMPLATE_ID;

      return lvResult;
    exception
      when no_data_found then
        return '';
    end;
  end getCharMaskFormat;

  /**
  * Description
  *   Retourne la valeur de caractérisation actuelle (SEM_VALUE)
  */
  function GetCharValue(iCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return varchar2
  is
    lvResult STM_ELEMENT_NUMBER.SEM_VALUE%type;
  begin
    begin
      select SEM_VALUE
        into lvResult
        from (select   SEM_VALUE
                  from STM_ELEMENT_NUMBER
                 where STM_I_LIB_ELEMENT_NUMBER.GetCharFromDetailElement(STM_ELEMENT_NUMBER_ID) = iCharacterizationId
              order by A_DATECRE desc)
       where rownum = 1;

      return lvResult;
    exception
      when no_data_found then
        return '';
    end;
  end GetCharValue;

  /**
  * Description
  *   Retourne la valeur téorique de la caractérisation
  */
  function GetTheoreticalCharValue(
    iCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iLastUsedIncrement  in GCO_CHARACTERIZATION.CHA_LAST_USED_INCREMENT%type
  , iIncrementStep      in GCO_CHARACTERIZATION.CHA_INCREMENT_STE%type
  )
    return varchar2
  is
    lnCharNumber GCO_CHARACTERIZATION.CHA_LAST_USED_INCREMENT%type;
    lvCharValue  DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
  begin
    GetNextCharValue(iCharacterizationID   => iCharacterizationID
                   , iDocPositionId        => null
                   , iFalLotId             => null
                   , iStartValue           => iLastUsedIncrement - iIncrementStep
                   , iUpdateLastIncrem     => 0
                   , oIncremValue          => lnCharNumber
                   , oCharValue            => lvCharValue
                    );
    return lvCharValue;
  end GetTheoreticalCharValue;

  /**
  * Function GetChronoCharID
  * Description
  *   Fonction qui renvoi l'id de la caractérisation du type chronologie d'un bien
  */
  function GetChronoCharID(iGoodID in number)
    return GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  is
    lCharID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type   := null;
  begin
    select GCO_CHARACTERIZATION_ID
      into lCharID
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodID
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeChrono;

    return lCharID;
  exception
    when no_data_found then
      return null;
  end GetChronoCharID;

  /**
  * Function ChronoFormatToDate
  * Description
  *   Fonction qui renvoi la date correspondant à la valeur de chronologie
  *     (dépendant de son type de caractérisation FIFO, LIFO ou Péremption)
  */
  function ChronoFormatToDate(
    iChronoValue        in STM_STOCK_POSITION.SPO_CHRONOLOGICAL%type
  , iCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  )
    return date
  is
    lDate           date                                          := null;
    lCharactType    GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lChronologyType GCO_CHARACTERIZATION.C_CHRONOLOGY_TYPE%type;
    lUnitOfTime     GCO_CHARACTERIZATION.C_UNIT_OF_TIME%type;
  begin
    if iChronoValue is not null then
      -- Infos sur le type de la caractérisation
      select C_CHARACT_TYPE
           , C_CHRONOLOGY_TYPE
           , C_UNIT_OF_TIME
        into lCharactType
           , lChronologyType
           , lUnitOfTime
        from GCO_CHARACTERIZATION
       where GCO_CHARACTERIZATION_ID = iCharacterizationID;

      -- Caractérisation de type "Chronologique"
      if lCharactType = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
        -- Type de chronologie : FIFO ou LIFO
        if lChronologyType in(GCO_I_LIB_CONSTANT.gcChronologyTypeFifo, GCO_I_LIB_CONSTANT.gcChronologyTypeLifo) then
          -- 1 : Instantané
          if lUnitOfTime in(GCO_I_LIB_CONSTANT.gcUnitOfTimeInstantaneous, '0') then
            lDate  := to_date(iChronoValue, 'YYYYMMDD HH24:MI:SS');
          -- 2 : Minute
          elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeMinute then
            lDate  := to_date(iChronoValue, 'YYYYMMDD HH24:MI:SS');
          -- 3 : Heure
          elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeHeure then
            lDate  := to_date(iChronoValue, 'YYYYMMDD HH24:MI:SS');
          -- 4 : Demi-journée
          elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeHalfDay then
            lDate  := to_date(iChronoValue, 'YYYYMMDD HH24:MI:SS');
          -- 5 : Journée
          elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeDay then
            lDate  := to_date(iChronoValue, 'YYYYMMDD HH24:MI:SS');
          -- 6 : Semaine
          elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeWeek then
            -- Renvoyer le lundi de la semaine
            lDate  := DOC_DELAY_FUNCTIONS.WeekToDate(aWeek => substr(iChronoValue, 1, 4) || '.' || substr(iChronoValue, 5, 2), aDay => 2);
          -- 7 : Mois
          elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeMonth then
            lDate  := to_date(iChronoValue || '01', 'YYYYMMDD');
          -- 8 : Trimestre
          elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeQuarter then
            case to_number(substr(iChronoValue, 5, 1) )
              when 1 then
                lDate  := to_date(substr(iChronoValue, 1, 4) || '0101', 'YYYYMMDD');
              when 2 then
                lDate  := to_date(substr(iChronoValue, 1, 4) || '0401', 'YYYYMMDD');
              when 3 then
                lDate  := to_date(substr(iChronoValue, 1, 4) || '0701', 'YYYYMMDD');
              when 4 then
                lDate  := to_date(substr(iChronoValue, 1, 4) || '1001', 'YYYYMMDD');
              else
                lDate  := null;
            end case;
          -- 9 : Semestre
          elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeHalfYear then
            case to_number(substr(iChronoValue, 5, 1) )
              when 1 then
                lDate  := to_date(substr(iChronoValue, 1, 4) || '0101', 'YYYYMMDD');
              when 2 then
                lDate  := to_date(substr(iChronoValue, 1, 4) || '0701', 'YYYYMMDD');
              else
                lDate  := null;
            end case;
          -- 10 : Année
          elsif lUnitOfTime = GCO_I_LIB_CONSTANT.gcUnitOfTimeYear then
            lDate  := to_date(iChronoValue || '0101', 'YYYYMMDD');
          end if;
        else
          -- Type de chronologie : Date de péremption
          lDate  := to_date(iChronoValue, 'YYYYMMDD');
        end if;
      end if;
    end if;

    return lDate;
  exception
    when others then
      return null;
  end ChronoFormatToDate;

  /**
  * function canCopyCharVersion
  * Description
  *   Détermine, pour un produit géré avec le versioning, si la caractérisation de type version associée doit être géré sur les produits "prototype"
  *
  * @created VJE 28.11.2014
  * @updated
  * @public
  * @param iSrcGoodId : ID du bien source
  * @param iTgtGoodId : ID du bien source
  * @param iCharType  : Type de caracterisation
  * @return
  */
  function canCopyCharVersion(
    iSrcGoodId in GCO_GOOD.GCO_GOOD_ID%type
  , iTgtGoodId in GCO_GOOD.GCO_GOOD_ID%type
  , iCharType  in GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  )
    return number
  is
    lnLinkID GCO_GOOD_LINK.GCO_GOOD_LINK_ID%type;
  begin
    -- Interdit la copie de la caratérisation de type version (porteuse du versioning) dans le cas ou le produit est géré en versioning
    -- et que la caractérisation est de type version et que la config n'autorise pas la copie de la version et qu'un
    -- lien de copie entre produits existe.
    if     IsVersioningManagement(iGoodId => iSrcGoodId) = 1
       and iCharType = GCO_LIB_CONSTANT.gcCharacTypeVersion
       and not GCO_LIB_CONSTANT.gcCfgCopyChaVersion then
      -- Vérifier s'il y a un lien de copie entre les 2 biens
      select max(GCO_GOOD_LINK_ID)
        into lnLinkID
        from GCO_GOOD_LINK
       where GCO_GOOD_SOURCE_ID = iSrcGoodID
         and GCO_GOOD_TARGET_ID = iTgtGoodID
         and C_GOOD_LINK_TYPE = '1';

      -- Lien de copie entre biens existant
      if lnLinkID is not null then
        return 0;
      else
        return 1;
      end if;
    else
      return 1;
    end if;
  end canCopyCharVersion;

  /**
  * Description
  *   table-function that return only stock-managed characterizaion (filter)
  */
  function GetStockCharacterizations(
    iChar1Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iChar2Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iChar3Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iChar4Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iChar5Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharValue1 in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , iCharValue2 in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , iCharValue3 in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , iCharValue4 in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , iCharValue5 in DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  )
    return ttStkChar pipelined
  is
    lCharIdList    varchar2(100);
    lCharValueList varchar2(1000);
    lResult        tStkChar;
  begin
    if IsCharInStock(iChar1Id) = 1 then
      lCharIdList     := lCharIdList || iChar1Id || ';';
      lCharValueList  := lCharValueList || iCharValue1 || ';';
    end if;

    if IsCharInStock(iChar2Id) = 1 then
      lCharIdList     := lCharIdList || iChar2Id || ';';
      lCharValueList  := lCharValueList || iCharValue2 || ';';
    end if;

    if IsCharInStock(iChar3Id) = 1 then
      lCharIdList     := lCharIdList || iChar3Id || ';';
      lCharValueList  := lCharValueList || iCharValue3 || ';';
    end if;

    if IsCharInStock(iChar4Id) = 1 then
      lCharIdList     := lCharIdList || iChar4Id || ';';
      lCharValueList  := lCharValueList || iCharValue4 || ';';
    end if;

    if IsCharInStock(iChar5Id) = 1 then
      lCharIdList     := lCharIdList || iChar5Id || ';';
      lCharValueList  := lCharValueList || iCharValue5 || ';';
    end if;

    lResult.GCO_CHARACTERIZATION_ID       := ExtractLine(lCharIdList, 1, ';');
    lResult.GCO_GCO_CHARACTERIZATION_ID   := ExtractLine(lCharIdList, 2, ';');
    lResult.GCO2_GCO_CHARACTERIZATION_ID  := ExtractLine(lCharIdList, 3, ';');
    lResult.GCO3_GCO_CHARACTERIZATION_ID  := ExtractLine(lCharIdList, 4, ';');
    lResult.GCO4_GCO_CHARACTERIZATION_ID  := ExtractLine(lCharIdList, 5, ';');
    lResult.GCO_CHARACTERIZATION_VALUE_1  := ExtractLine(lCharValueList, 1, ';');
    lResult.GCO_CHARACTERIZATION_VALUE_2  := ExtractLine(lCharValueList, 2, ';');
    lResult.GCO_CHARACTERIZATION_VALUE_3  := ExtractLine(lCharValueList, 3, ';');
    lResult.GCO_CHARACTERIZATION_VALUE_4  := ExtractLine(lCharValueList, 4, ';');
    lResult.GCO_CHARACTERIZATION_VALUE_5  := ExtractLine(lCharValueList, 5, ';');
    pipe row(lResult);
  end GetStockCharacterizations;
end GCO_LIB_CHARACTERIZATION;
