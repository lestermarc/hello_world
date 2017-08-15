--------------------------------------------------------
--  DDL for Package Body STM_LIB_CHARACTERIZATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_LIB_CHARACTERIZATION" 
is
  cDocCharactNotInStock  constant integer := PCS.PC_CONFIG.GetConfig('DOC_CHARACT_NOT_IN_STOCK');
  cStmVersionSglNumbComp constant integer := case PCS.PC_CONFIG.getConfig('STM_VERSION_SGL_NUMBERING_COMP')
    when 'True' then 1
    else 0
  end;
  cStmVersionSglNumbGood constant integer := case PCS.PC_CONFIG.getConfig('STM_VERSION_SGL_NUMBERING_GOOD')
    when 'True' then 1
    else 0
  end;
  cStmPieceSglNumbComp   constant integer := case PCS.PC_CONFIG.getConfig('STM_PIECE_SGL_NUMBERING_COMP')
    when 'True' then 1
    else 0
  end;
  cStmSetSglNumbComp     constant integer := case PCS.PC_CONFIG.getConfig('STM_SET_SGL_NUMBERING_COMP')
    when 'True' then 1
    else 0
  end;
  cStmSetSglNumbGood     constant integer := case PCS.PC_CONFIG.getConfig('STM_SET_SGL_NUMBERING_GOOD')
    when 'True' then 1
    else 0
  end;

  function IsNumber(iValue in varchar2)
    return boolean
  is
    lnValueInNumber number;
  begin
    lnValueInNumber  := to_number(iValue);
    return true;
  exception
    when invalid_number then
      return false;
  end;

  function IsAutomaticIncrem(iCharactId in number)
    return boolean
  is
    lbResult              boolean;
    lChaAutoIncrement     GCO_CHARACTERIZATION.CHA_AUTOMATIC_INCREMENTATION%type;
    lGcoCharAutonumFuncId GCO_CHARACTERIZATION.GCO_CHAR_AUTONUM_FUNC_ID%type;
  begin
    lbResult  := false;

    if (iCharactId <> 0) then
      /* Recherche si la caractérisation version, pièce ou lot gère une incrémentation automatique */
      select max(CHA_AUTOMATIC_INCREMENTATION)
           , max(GCO_CHAR_AUTONUM_FUNC_ID)
        into lChaAutoIncrement
           , lGcoCharAutonumFuncId
        from GCO_CHARACTERIZATION
       where GCO_CHARACTERIZATION_ID = iCharactId;

      if    (nvl(lChaAutoIncrement, 0) = 0)
         or (lGcoCharAutonumFuncId is not null) then
        lbResult  := false;
      else
        lbResult  := true;
      end if;
    end if;

    return lbResult;
  end;

/* recherche de l'origine d'une caractérisation réservée */
  function displayElementReservation(iCharId in number, iCharValue in varchar2)
    return varchar2
  is
    lvTableName   varchar2(30);
    lnReservingId number;
    lvResult      varchar2(4000);
  begin
    lvResult  := 'N/A';
    -- recherche de la provenance de la réservation
    STM_PRC_STOCK_POSITION.findElementReservation(iCharId, iCharValue, lvTableName, lnReservingId);

    -- formattage du message en fonction de la provenance des reservations
    if lvTableName = 'DOC_POSITION_DETAIL' then
      select replace
               (replace
                  (replace(PCS.PC_FUNCTIONS.TranslateWord('Le numéro de caractérisation "NOXXX" est réservé dans le document "DOCXXX" à la position "POSXXX"')
                         , 'NOXXX'
                         , iCharValue
                          )
                 , 'DOCXXX'
                 , DMT_NUMBER
                  )
              , 'POSXXX'
              , POS_NUMBER
               )
        into lvResult
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
       where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and PDE.DOC_POSITION_DETAIL_ID = lnReservingId;
    elsif lvTableName = 'FAL_LOT_DETAIL' then
      select replace
               (replace
                  (replace
                     (PCS.PC_FUNCTIONS.TranslateWord
                                                    ('Le numéro de caractérisation "NOXXX" est réservé par le lot "LOTXXX" du programme de fabrication "PRGXXX"')
                    , 'NOXXX'
                    , iCharValue
                     )
                 , 'PRGXXX'
                 , JOP_SHORT_DESCR
                  )
              , 'LOTXXX'
              , LOT.LOT_REFCOMPL
               )
        into lvResult
        from FAL_LOT_DETAIL FAD
           , FAL_LOT LOT
           , FAL_ORDER ORD
           , FAL_JOB_PROGRAM JOP
       where LOT.FAL_LOT_ID = FAD.FAL_LOT_ID
         and ORD.FAL_ORDER_ID = LOT.FAL_ORDER_ID
         and JOP.FAL_JOB_PROGRAM_ID = ORD.FAL_JOB_PROGRAM_ID
         and FAD.FAL_LOT_DETAIL_ID = lnReservingId;
    elsif lvTableName = 'ASA_RECORD_COMP' then
      select replace
               (replace
                  (replace
                     (PCS.PC_FUNCTIONS.TranslateWord
                                        ('Le numéro de caractérisation "NOXXX" est réservé comme composant dans le document SAV "DOCXXX" à la position "POSXXX"')
                    , 'NOXXX'
                    , iCharValue
                     )
                 , 'DOCXXX'
                 , ARE_NUMBER
                  )
              , 'POSXXX'
              , ARC_POSITION
               )
        into lvResult
        from ASA_RECORD_COMP ARC
           , ASA_RECORD are
       where ARC.ASA_RECORD_COMP_ID = lnReservingId
         and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID;
    end if;

    return lvResult;
  end;

  procedure VerifyVersion(
    iGoodId             in     number
  , iCharacterizationId in     number
  , iElementValue       in     varchar2
  , iPrefix             in     varchar2
  , iSuffix             in     varchar2
  , iVerifMovementCode  in     STM_MOVEMENT_KIND.C_MOVEMENT_CODE%type
  , ioRetouche          in out integer
  , ioResultMessage     in out varchar2
  )
  is
    lCEleNumStatus STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
    lvOrigin       varchar2(4000);
  begin
    if    (cStmVersionSglNumbComp = 1)
       or (cStmVersionSglNumbGood = 1) then
      select max(C_ELE_NUM_STATUS)
        into lCEleNumStatus
        from STM_ELEMENT_NUMBER
       where SEM_VALUE = trim(iElementValue)
         and (    (cStmVersionSglNumbComp = 1)
              or (     (cStmVersionSglNumbGood = 1)
                  and GCO_GOOD_ID = iGoodId) )
         and C_ELEMENT_TYPE = '03'
         and C_ELE_NUM_STATUS <> '04';

      if (lCEleNumStatus = '03') then
        lvOrigin  := displayElementReservation(iCharacterizationId, trim(iElementValue) );

        if lvOrigin <> 'N/A' then
          ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Un numéro de version similaire existe déjà !!') || chr(13) || lvOrigin || '[ABORT]';
        else
          ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Un numéro de version similaire existe déjà !!') || '[ABORT]';
        end if;
      elsif(lCEleNumStatus = '02') then
        if    (iVerifMovementCode <> '020')
           or (ioRetouche = 0) then
          ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce N° existe déjà, est-ce une retouche de pièce existante ?');
        elsif(iVerifMovementCode = '020') then
          ioRetouche  := 1;
        end if;
      end if;
    end if;

    if ioResultMessage is not null then
      if cStmVersionSglNumbComp = 1 then
        ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Numérotation unique par mandat') || ' - ' || ioResultMessage;
      else
        ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Numérotation unique par produit') || ' - ' || ioResultMessage;
      end if;
    end if;
  end;

  procedure VerifyPiece(
    iGoodId             in     number
  , iVerifChar          in     integer
  , iCharacterizationId in     number
  , iElementValue       in     varchar2
  , iGestStock          in     integer
  , iVerifMovementCode  in     STM_MOVEMENT_KIND.C_MOVEMENT_CODE%type
  , iVerifMovementSort  in     STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type
  , ioRetouche          in out integer
  , ioResultMessage     in out varchar2
  )
  is
    cursor crElementNumber
    is
      select C_ELE_NUM_STATUS
           , GCO_GOOD_ID
        from STM_ELEMENT_NUMBER
       where SEM_VALUE = trim(iElementValue)
         and (    (     (cStmPieceSglNumbComp = 1)
                   and C_ELEMENT_TYPE = '02')
              or (     (cStmPieceSglNumbComp = 0)
                  and GCO_GOOD_ID = iGoodId) );

    lvOrigin  varchar2(4000);
    liIsStock integer;
  begin
    for tplElementNumber in crElementNumber loop
      if ioResultMessage is not null then
        exit;
      end if;

      --  le status réservé indique qu'il y a un document en cours
      if tplElementNumber.C_ELE_NUM_STATUS = '03' then
        lvOrigin  := displayElementReservation(iCharacterizationId, trim(iElementValue) );

        if lvOrigin <> 'N/A' then
          ioResultMessage  :=
                         PCS.PC_FUNCTIONS.TranslateWord('Un numéro de pièce similaire avec le statut réservé existe déjà !!') || chr(13) || lvOrigin
                         || '[ABORT]';
        else
          ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Un numéro de pièce similaire avec le statut réservé existe déjà !!') || '[ABORT]';
        end if;
      elsif     (cStmPieceSglNumbComp = 1)
            and (tplElementNumber.GCO_GOOD_ID <> iGoodId) then
        ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Un numéro de pièce similaire est déjà utilisé pour un autre article !!') || '[ABORT]';
      elsif    (     (cStmPieceSglNumbComp = 1)
                and (    (     (tplElementNumber.C_ELE_NUM_STATUS = '02')
                          and (iVerifChar = 1)
                          and (iGestStock = 1)
                          and (iVerifMovementSort = 'ENT') )
                     or (     (tplElementNumber.C_ELE_NUM_STATUS = '02')
                         and (iVerifChar = 1)
                         and not(iGestStock = 1)
                         and (iVerifMovementSort = 'SOR') )
                    )
               )
            or (     (cStmPieceSglNumbComp = 0)
                and (     (tplElementNumber.C_ELE_NUM_STATUS = '02')
                     and (iVerifChar = 1) ) ) then
        if    (iVerifMovementCode <> '020')
           or (ioRetouche = 0) then
          ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce N° existe déjà, est-ce une retouche de pièce existante ?');
        elsif(iVerifMovementCode = '020') then
          ioRetouche  := 1;
        end if;
      elsif     (tplElementNumber.C_ELE_NUM_STATUS = '04')
            and (iVerifMovementSort = 'ENT')
            and not(iGestStock = 1) then
        ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Un numéro de pièce similaire avec le statut retourné existe déjà !!') || '[ABORT]';
      elsif     (cStmPieceSglNumbComp = 1)
            and (iGestStock = 1) then
        /* on vérifie que l'on ait pas ce numéro de pièces déjà en stock pour n'importe quel article
           Cette commande "sort" également les articles avec des entrées provisoires
           Attention : commande avec fullscan */
        select sign(nvl(max(SBC.GCO_GOOD_ID), 0) ) IS_STOCK
          into liIsStock
          from V_STM_STOCK_BY_CHAR SBC
             , GCO_CHARACTERIZATION CHA
         where SBC.GCO_CHARACTERIZATION_ID = CHA.GCO_CHARACTERIZATION_ID
           and CHA.C_CHARACT_TYPE = '3'
           and SPO_CHARACTERIZATION_VALUE = trim(iElementValue);

        if liIsStock = 1 then
          ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Un numéro de pièce similaire existe déjà en stock!!') || '[ABORT]';
        end if;
      elsif     (cStmPieceSglNumbComp = 0)
            and (     (tplElementNumber.C_ELE_NUM_STATUS = '02')
                 and not(iVerifChar = 1)
                 and (iGestStock = 1) ) then
        -- on vérifie malgrès tout que l'on ait pas de pièces déjà en stock
        select sign(max(GCO_GOOD_ID) ) IS_STOCK
          into liIsStock
          from V_STM_STOCK_BY_CHAR
         where GCO_GOOD_ID = iGoodId
           and GCO_CHARACTERIZATION_ID = iCharacterizationId
           and SPO_CHARACTERIZATION_VALUE = trim(iElementValue);

        if liIsStock = 1 then
          ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Un numéro de pièce similaire existe déjà en stock!!') || '[ABORT]';
        end if;
      end if;
    end loop;

    if ioResultMessage is not null then
      if (cStmSetSglNumbComp = 1) then
        ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Numérotation unique par mandat') || ' - ' || ioResultMessage;
      else
        ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Numérotation unique par produit') || ' - ' || ioResultMessage;
      end if;
    end if;
  end;

  procedure VerifyLot(
    iGoodId             in     number
  , iVerifChar          in     integer
  , iCharacterizationId in     number
  , iElementValue       in     varchar2
  , iVerifMovementCode  in     STM_MOVEMENT_KIND.C_MOVEMENT_CODE%type
  , ioRetouche          in out integer
  , ioResultMessage     in out varchar2
  )
  is
    cursor crElementNumber
    is
      select C_ELE_NUM_STATUS
        from STM_ELEMENT_NUMBER
       where SEM_VALUE = trim(iElementValue)
         and C_ELEMENT_TYPE = '01'
         and (    (cStmSetSglNumbComp = 1)
              or (     (cStmSetSglNumbGood = 1)
                  and GCO_GOOD_ID = iGoodId) )
         and (    (     (cStmSetSglNumbComp = 1)
                   and C_ELE_NUM_STATUS not in('04') )
              or (     (cStmSetSglNumbGood = 1)
                  and C_ELE_NUM_STATUS in('02', '03') ) );

    lvOrigin varchar2(4000);
  begin
    if     (    (cStmSetSglNumbComp = 1)
            or (cStmSetSglNumbGood = 1) )
       and (iVerifChar = 1) then   -- N° unique par produit
      for tplElementNumber in crElementNumber loop
        if ioResultMessage is not null then
          exit;
        end if;

        if (tplElementNumber.C_ELE_NUM_STATUS = '03') then
          lvOrigin  := displayElementReservation(iCharacterizationId, trim(iElementValue) );

          if lvOrigin <> 'N/A' then
            ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Un numéro de lot similaire existe déjà !!') || chr(13) || lvOrigin || '[ABORT]';
          else
            ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Un numéro de lot similaire existe déjà !!') || '[ABORT]';
          end if;
        elsif(tplElementNumber.C_ELE_NUM_STATUS = '02') then
          if    (iVerifMovementCode <> '020')
             or (ioRetouche = 0) then
            ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce N° existe déjà, est-ce une retouche de pièce existante ?');
          elsif(iVerifMovementCode = '020') then
            ioRetouche  := 1;
          end if;
        end if;
      end loop;
    end if;

    if ioResultMessage is not null then
      if (cStmSetSglNumbComp = 1) then
        ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Numérotation unique par mandat') || ' - ' || ioResultMessage;
      else
        ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Numérotation unique par produit') || ' - ' || ioResultMessage;
      end if;
    end if;
  end;

  /**
  * function VerifyElement
  * Description
  *   Vérification de l'élément de caractérisation sélectionné
  *   (reprise du code Delphi de STM_ELEMENT_NUMBER_FCT)
  * @created FPE/CLG 13.02.2012
  * @lastUpdate
  * @public
  * @param iGoodId                  Id du bien
  * @param iCharacterizationId      Id de la caractérisation
  * @param iMovementKindId          Id du type de mouvement
  * @param iElementType             Type de caractérisation (version, pièce, ...)
  * @param iElementValue            Valeur de caractérisation
  * @param iUseInformation          Détermine si on gère les caractérisations non morphologique dans les documents
  *                                 sans mouvements de stock
  * @param iMovementSort            Type de mouvement ('ENT' domaine achat, 'SOR' domaine vente)
  * @param iVerifyCharacterization  Vérification de la caractérisation
  * @param ioRetouche               Paramètre de retour indiquant s'il s'agit d'une retouche
  * @param ioResultMessage          Message de retour :
  *                                   - Null, la caractérisation est correcte
  *                                   - S'il contient la macro [ABORT], la caractérisation n'est pas valide
  *                                   - Sinon, contient une question pour validation par l'utilisateur
  */
  procedure VerifyElement(
    iGoodId                 in     number
  , iCharacterizationId     in     number
  , iMovementKindId         in     number
  , iElementType            in     integer
  , iElementValue           in     varchar2
  , iUseInformation         in     integer default 0
  , iMovementSort           in     varchar2 default null
  , iVerifyCharacterization in     integer default 0
  , ioRetouche              in out integer
  , ioResultMessage         in out varchar2
  )
  is
    lvSqlRequest        varchar2(4000);
    lbVerifIncrem       boolean;
    lvPrefix            GCO_CHARACTERIZATION.CHA_PREFIXE%type;
    lvSuffix            GCO_CHARACTERIZATION.CHA_SUFFIXE%type;
    liVerifChar         integer;
    lvVerifMovementSort STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lvVerifMovementCode STM_MOVEMENT_KIND.C_MOVEMENT_CODE%type;
    liGestStock         integer;
  begin
    ioResultMessage  := '';

    if upper(iElementValue) <> 'N/A' then
      if iUseInformation = 1 then
        liVerifChar          := iVerifyCharacterization;
        lvVerifMovementSort  := iMovementSort;
        lvVerifMovementCode  := '';
      else
        /* Recherche du flag de vérification de la caractérisation */
        select nvl(MOK_VERIFY_CHARACTERIZATION, 0)
             , C_MOVEMENT_SORT
             , C_MOVEMENT_CODE
          into liVerifChar
             , lvVerifMovementSort
             , lvVerifMovementCode
          from STM_MOVEMENT_KIND
         where STM_MOVEMENT_KIND_ID = iMovementKindId;
      end if;

      /* recherche du flag caractérisation gêrée en stock */
      lvSqlRequest   := ' select decode(PDT_STOCK_MANAGEMENT,1,nvl(CHA_STOCK_MANAGEMENT, 0) ,0) CHA_STOCK_MANAGEMENT ';

      if iElementType = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
        lvSqlRequest  :=
          lvSqlRequest ||
          '      , decode(PCS.PC_CONFIG.getConfigUpper(''STM_PIECE_SGL_NUMBERING_COMP'')
                  , ''TRUE'', PCS.PC_CONFIG.getConfigUpper(''STM_PIECE_PREFIX'')
                  , CHA_PREFIXE
                   ) CHA_PREFIXE
           , decode(PCS.PC_CONFIG.getConfigUpper(''STM_PIECE_SGL_NUMBERING_COMP'')
                  , ''TRUE'', PCS.PC_CONFIG.getConfigUpper(''STM_PIECE_SUFFIX'')
                  , CHA_SUFFIXE
                   ) CHA_SUFFIXE ';
      elsif iElementType = GCO_I_LIB_CONSTANT.gcCharacTypeSet then
        lvSqlRequest  :=
          lvSqlRequest ||
          '      , decode(PCS.PC_CONFIG.getConfigUpper(''STM_SET_SGL_NUMBERING_COMP'')
                  , ''TRUE'', PCS.PC_CONFIG.getConfigUpper(''STM_SET_PREFIX'')
                  , CHA_PREFIXE
                   ) CHA_PREFIXE
           , decode(PCS.PC_CONFIG.getConfigUpper(''STM_SET_SGL_NUMBERING_COMP'')
                  , ''TRUE'', PCS.PC_CONFIG.getConfigUpper(''STM_SET_SUFFIX'')
                  , CHA_SUFFIXE
                   ) CHA_SUFFIXE ';
      elsif iElementType = GCO_I_LIB_CONSTANT.gcCharacTypeVersion then
        lvSqlRequest  :=
          lvSqlRequest ||
          '      , decode(PCS.PC_CONFIG.getConfigUpper(''STM_VERSION_SGL_NUMBERING_COMP'')
                  , ''TRUE'', PCS.PC_CONFIG.getConfigUpper(''STM_VERSION_PREFIX'')
                  , CHA_PREFIXE
                   ) CHA_PREFIXE
           , decode(PCS.PC_CONFIG.getConfigUpper(''STM_VERSION_SGL_NUMBERING_COMP'')
                  , ''TRUE'', PCS.PC_CONFIG.getConfigUpper(''STM_VERSION_SUFFIX'')
                  , CHA_SUFFIXE
                   ) CHA_SUFFIXE ';
      else
        lvSqlRequest  := lvSqlRequest || '      , null CHA_PREFIXE
           , null CHA_SUFFIXE ';
      end if;

      lvSqlRequest   :=
        lvSqlRequest ||
        ' from GCO_CHARACTERIZATION CHA
         , GCO_PRODUCT PDT
     where GCO_CHARACTERIZATION_ID = :GCO_CHARACTERIZATION_ID
       and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID ';

      execute immediate lvSqlRequest
                   into liGestStock
                      , lvPrefix
                      , lvSuffix
                  using iCharacterizationId;

      -- Recherche si l'incrémentation de la version est automatique */
      lbVerifIncrem  := IsAutomaticIncrem(iCharacterizationId);

      /* Contrôle l'unicité des valeurs de caractérisation.
        A effectuer uniquement lorsque la caractérisation n'est pas gérée en stock ou que le mouvement
        lié n'est pas un mouvement de sortie.
        A l'exception du cas ou le gabarit position n'est pas lié avec un mouvement et que la gestion
        des caractérisations non morphologique est activé (iUseInformation) sur le gabarit et que
        la configuration DOC_CHARACT_NOT_IN_STOCK est active. */
      if    (     (lvVerifMovementSort = 'ENT')
             and (    (liGestStock = 1)
                  or (liVerifChar = 1)
                  or (iElementType = GCO_I_LIB_CONSTANT.gcCharacTypePiece) ) )
         or (     (lvVerifMovementSort = 'SOR')
             and not(liGestStock = 1) )
         or (     (lvVerifMovementSort = 'SOR')
             and (cDocCharactNotInStock = '1')
             and (iUseInformation = 1) ) then
        ioRetouche  := nvl(ioRetouche, 0);

        /* Validation pour les caractérisations de type version, pièce et lot */
        if     lbVerifIncrem
           and (not IsNumber(GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(trim(iElementValue), lvPrefix, lvSuffix) ) ) then
          ioResultMessage  := PCS.PC_FUNCTIONS.TranslateWord('Incrémentation automatique -> Valeur numérique requise !!') || '[ABORT]';
        elsif iElementType = GCO_I_LIB_CONSTANT.gcCharacTypeVersion then
          /* Caractéristique de type version */
          VerifyVersion(iGoodId               => iGoodId
                      , iCharacterizationId   => iCharacterizationId
                      , iElementValue         => iElementValue
                      , iPrefix               => lvPrefix
                      , iSuffix               => lvSuffix
                      , iVerifMovementCode    => lvVerifMovementCode
                      , ioRetouche            => ioRetouche
                      , ioResultMessage       => ioResultMessage
                       );
        elsif iElementType = GCO_I_LIB_CONSTANT.gcCharacTypePiece then
          /* Caractéristique de type pièce */
          VerifyPiece(iGoodId               => iGoodId
                    , iVerifChar            => liVerifChar
                    , iCharacterizationId   => iCharacterizationId
                    , iElementValue         => iElementValue
                    , iGestStock            => liGestStock
                    , iVerifMovementCode    => lvVerifMovementCode
                    , iVerifMovementSort    => lvVerifMovementSort
                    , ioRetouche            => ioRetouche
                    , ioResultMessage       => ioResultMessage
                     );
        elsif iElementType = GCO_I_LIB_CONSTANT.gcCharacTypeSet then
          /* Caractéristique de type lot */
          VerifyLot(iGoodId               => iGoodId
                  , iVerifChar            => liVerifChar
                  , iCharacterizationId   => iCharacterizationId
                  , iElementValue         => iElementValue
                  , iVerifMovementCode    => lvVerifMovementCode
                  , ioRetouche            => ioRetouche
                  , ioResultMessage       => ioResultMessage
                   );
        end if;
      end if;
    end if;
  end;
end STM_LIB_CHARACTERIZATION;
