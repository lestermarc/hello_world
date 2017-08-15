--------------------------------------------------------
--  DDL for Package Body GCO_PRC_CHARACTERIZATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_PRC_CHARACTERIZATION" 
is
  -- constantes
  -- DESCODES
  -- C_CHARAC_TYPE
  gcCharacTypeVersion        constant char(1) := '1';
  gcCharacTypeCharacteristic constant char(1) := '2';
  gcCharacTypePiece          constant char(1) := '3';
  gcCharacTypeSet            constant char(1) := '4';
  gcCharacTypeChrono         constant char(1) := '5';
  -- C_ELEMENT_TYPE
  gcElementTypeSet           constant char(2) := '01';
  gcElementTypePiece         constant char(2) := '02';
  gcElementTypeVersion       constant char(2) := '03';
  -- C_ADMIN_DOMAIN
  gcAdminDomainPurchase      constant char(1) := '1';
  gcAdminDomainSale          constant char(1) := '2';
  -- C_CHRONOLOGY_TYPE
  gcChronologyTypePeremption constant char(1) := '3';
  -- C_DOC_POS_STATUS
  gcDocPosStatusToConfirm    constant char(2) := '01';
  -- C_ELE_NUM_STATUS
  gcEleNumStatusActive       constant char(2) := '02';
  --C_MOVEMENT_SORT
  gcMovementSortInput        constant char(3) := 'ENT';
  gcMovementSortOutput       constant char(3) := 'SOR';

  /**
  * procedure LogCharacWizardEvent
  * Description
  *   Inscrit les opération de l'assistant caractérisation dans la table GCO_CHAR_WIZARD_LOG
  * @created fp 2004
  * @lastUpdate fp 12.08.2005
  * @private
  * @param  iAction : ADD, DEL, ERA (erreur lors d'un ajout), ERD (erreur lors d'un effacement)
  * @param  iCharacterizationId
  * @param  iCharDesign : designation de la caractérisation
  * @param  iGoodId
  * @param  iErrorComment : commentaire en cas d'erreur
  */
  procedure LogCharacWizardEvent(
    iAction             in GCO_CHAR_WIZARD_LOG.C_GCO_CHAR_WIZARD_ACTION%type
  , iCharacterizationId in GCO_CHAR_WIZARD_LOG.GCO_CHARACTERIZATION_ID%type
  , iCharDesign         in GCO_CHARACTERIZATION.CHA_CHARACTERIZATION_DESIGN%type
  , iGoodId             in GCO_CHAR_WIZARD_LOG.GCO_GOOD_ID%type
  , iErrorComment       in GCO_CHAR_WIZARD_LOG.CWL_ERROR_COMMENT%type default null
  )
  is
    lMajorReference GCO_GOOD.GOO_MAJOR_REFERENCE%type;

    procedure insertNoAutonomous(
      iAction             in GCO_CHAR_WIZARD_LOG.C_GCO_CHAR_WIZARD_ACTION%type
    , iCharacterizationId in GCO_CHAR_WIZARD_LOG.GCO_CHARACTERIZATION_ID%type
    , iCharDesign         in GCO_CHARACTERIZATION.CHA_CHARACTERIZATION_DESIGN%type
    , iGoodId             in GCO_CHAR_WIZARD_LOG.GCO_GOOD_ID%type
    , iMajorReference     in GCO_GOOD.GOO_MAJOR_REFERENCE%type
    , iErrorComment       in GCO_CHAR_WIZARD_LOG.CWL_ERROR_COMMENT%type default null
    )
    is
    begin
      insert into GCO_CHAR_WIZARD_LOG
                  (GCO_CHAR_WIZARD_LOG_ID
                 , C_GCO_CHAR_WIZARD_ACTION
                 , GCO_GOOD_ID
                 , CWL_MAJOR_REFERENCE
                 , GCO_CHARACTERIZATION_ID
                 , CWL_CHARACTERIZATION_DESIGN
                 , CWL_ORACLE_USER
                 , CWL_OS_USER
                 , CWL_TERMINAL
                 , CWL_ERROR_COMMENT
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , iAction
                 , nvl(iGoodId, 0)
                 , iMajorReference
                 , iCharacterizationId
                 , iCharDesign
                 , user
                 , nvl(sys_context('USERENV', 'OS_USER'), 'UNKNOWN')
                 , nvl(userenv('TERMINAL'), 'UNKNOWN')
                 , iErrorComment
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end insertNoAutonomous;

    procedure insertAutonomous(
      iAction             in GCO_CHAR_WIZARD_LOG.C_GCO_CHAR_WIZARD_ACTION%type
    , iCharacterizationId in GCO_CHAR_WIZARD_LOG.GCO_CHARACTERIZATION_ID%type
    , iCharDesign         in GCO_CHARACTERIZATION.CHA_CHARACTERIZATION_DESIGN%type
    , iGoodId             in GCO_CHAR_WIZARD_LOG.GCO_GOOD_ID%type
    , iMajorReference     in GCO_GOOD.GOO_MAJOR_REFERENCE%type
    , iErrorComment       in GCO_CHAR_WIZARD_LOG.CWL_ERROR_COMMENT%type default null
    )
    is
      pragma autonomous_transaction;
    begin
      insertNoAutonomous(iAction, iCharacterizationId, iCharDesign, iGoodId, iMajorReference, iErrorComment);
      commit;
    end insertAutonomous;
  begin
    -- recherche de la référence principale du bien
    begin
      select GOO_MAJOR_REFERENCE
        into lMajorReference
        from GCO_GOOD
       where GCO_GOOD_ID = iGoodID;
    exception
      when no_data_found then
        lMajorReference  := '<NOT FOUND>';
    end;

    if iAction in('ERA', 'ERD') then
      insertAutonomous(iAction, iCharacterizationId, iCharDesign, iGoodId, lMajorReference, iErrorComment);
    else
      insertNoAutonomous(iAction, iCharacterizationId, iCharDesign, iGoodId, lMajorReference, iErrorComment);
    end if;
  end LogCharacWizardEvent;

  /**
  * Description
  *   Ajouter les descriptions à la table COM_LIST_ID_TEMP pour gérer les traductions des caractérisations
  */
  procedure AddCharDescr(iCharacterizationId in number, iDescription in varchar2)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplLang in (select PC_LANG_ID
                      from PCS.PC_LANG
                     where LANUSED = 1
                       and PC_LANG_ID not in(select LID_ID_2
                                               from COM_LIST_ID_TEMP
                                              where LID_ID_1 = iCharacterizationId
                                                and LID_CODE = 'CharDescr') ) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', INIT_ID_SEQ.nextval);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', iCharacterizationId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_2', tplLang.PC_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_CHAR_1', iDescription);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', 'CharDescr');
      FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end loop;
  end AddCharDescr;

  /**
  * Description
  *   Modifier une description de la table COM_LIST_ID_TEMP pour gérer les traductions des caractérisations
  */
  procedure UpdateCharDescr(iCharacterizationId in number, iLangId in number, iDescription in varchar2)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
    lComListID   number;
    lbModify     boolean                         := true;
  begin
    begin
      -- récupérer l'id de la description
      select COM_LIST_ID_TEMP_ID
        into lComListID
        from COM_LIST_ID_TEMP
       where LID_ID_1 = iCharacterizationId
         and LID_ID_2 = iLangId
         and LID_CODE = 'CharDescr';
    exception
      when no_data_found then
        lbModify  := false;
    end;

    if lbModify then
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', lComListID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_CHAR_1', iDescription);
      FWK_I_MGT_ENTITY.UpdateEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end if;
  end UpdateCharDescr;

  /**
  * Description
  *   Supprimer une description de la table COM_LIST_ID_TEMP pour gérer les traductions des caractérisations
  */
  procedure DeleteCharDescr(iCharacterizationId in number, iLangId in number)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
    lComListID   number;
    lbDelete     boolean                         := true;
  begin
    begin
      -- récupérer l'id de la description
      select COM_LIST_ID_TEMP_ID
        into lComListID
        from COM_LIST_ID_TEMP
       where LID_ID_1 = iCharacterizationId
         and LID_ID_2 = iLangId
         and LID_CODE = 'CharDescr';
    exception
      when no_data_found then
        lbDelete  := false;
    end;

    if lbDelete then
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', lComListID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end if;
  end DeleteCharDescr;

  /**
  * Description
  *   Dupliquer les descriptions d'un characteristique de base dans la table COM_LIST_ID_TEMP pour gérer les traductions des caractérisations
  */
  procedure DuplicateCharDescr(iCharacterizationId in number, iBaseCharacterizationId in number)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplDesc in (select PC_LANG_ID
                         , DLA_DESCRIPTION
                      from GCO_DESC_LANGUAGE
                     where GCO_BASE_CHARACTERIZATION_ID = iBaseCharacterizationId) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', INIT_ID_SEQ.nextval);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', iCharacterizationId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_2', tplDesc.PC_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_CHAR_1', tplDesc.DLA_DESCRIPTION);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', 'CharDescr');
      FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end loop;
  end DuplicateCharDescr;

  /**
  * Description
  *   Supprimer toutes les descriptions temporaires pour les caractérisations
  */
  procedure ClearCharDescr
  is
  begin
    COM_I_PRC_LIST_ID_TEMP.ClearIDList('CharDescr');
  end ClearCharDescr;

  /**
  * Description
  *   Ajouter les descriptions à la table COM_LIST_ID_TEMP pour gérer les traductions des éléments de caractérisation
  */
  procedure AddElemDescr(iCharacteristicElementId in number, iDescription in varchar2)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplLang in (select PC_LANG_ID
                      from PCS.PC_LANG
                     where LANUSED = 1
                       and PC_LANG_ID not in(select LID_ID_2
                                               from COM_LIST_ID_TEMP
                                              where LID_ID_1 = iCharacteristicElementId
                                                and LID_CODE = 'ElemDescr') ) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', INIT_ID_SEQ.nextval);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', iCharacteristicElementId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_2', tplLang.PC_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_CHAR_1', iDescription);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', 'ElemDescr');
      FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end loop;
  end AddElemDescr;

  /**
  * Description
  *   Modifier une description de la table COM_LIST_ID_TEMP pour gérer les traductions des éléments de caractérisation
  */
  procedure UpdateElemDescr(iCharacteristicElementId in number, iLangId in number, iDescription in varchar2)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
    lComListID   number;
    lbModify     boolean                         := true;
  begin
    begin
      -- récupérer l'id de la description
      select COM_LIST_ID_TEMP_ID
        into lComListID
        from COM_LIST_ID_TEMP
       where LID_ID_1 = iCharacteristicElementId
         and LID_ID_2 = iLangId
         and LID_CODE = 'ElemDescr';
    exception
      when no_data_found then
        lbModify  := false;
    end;

    if lbModify then
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', lComListID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_CHAR_1', iDescription);
      FWK_I_MGT_ENTITY.UpdateEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end if;
  end UpdateElemDescr;

  /**
  * Description
  *   Supprimer une description de la table COM_LIST_ID_TEMP pour gérer les traductions des éléments de caractérisation
  */
  procedure DeleteElemDescr(iCharacteristicElementId in number, iLangId in number)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
    lComListID   number;
    lbDelete     boolean                         := true;
  begin
    begin
      -- récupérer l'id de la description
      select COM_LIST_ID_TEMP_ID
        into lComListID
        from COM_LIST_ID_TEMP
       where LID_ID_1 = iCharacteristicElementId
         and LID_ID_2 = iLangId
         and LID_CODE = 'ElemDescr';
    exception
      when no_data_found then
        lbDelete  := false;
    end;

    if lbDelete then
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', lComListID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end if;
  end DeleteElemDescr;

  /**
  * Description
  *   Dupliquer les descriptions d'un characteristique de base dans la table COM_LIST_ID_TEMP pour gérer les traductions des éléments de caractérisation
  */
  procedure DuplicateElemDescr(iCharacteristicElementId in number, iBaseCharacteristicElementId in number)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplDesc in (select PC_LANG_ID
                         , DLA_DESCRIPTION
                      from GCO_DESC_LANGUAGE
                     where GCO_BASE_ELEMENT_CHARAC_ID = iBaseCharacteristicElementId) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', INIT_ID_SEQ.nextval);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', iCharacteristicElementId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_2', tplDesc.PC_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_CHAR_1', tplDesc.DLA_DESCRIPTION);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', 'ElemDescr');
      FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end loop;
  end DuplicateElemDescr;

  /**
  * Description
  *   Supprimer toutes les descriptions temporaires pour les éléments de caractérisation
  */
  procedure ClearElemDescr
  is
  begin
    COM_I_PRC_LIST_ID_TEMP.ClearIDList('ElemDescr');
  end ClearElemDescr;

  /**
  * Description
  *   Supprimer toutes les valeurs par défaut temporaires pour les éléments de caractérisation
  */
  procedure ClearCharElemValueEnable
  is
  begin
    COM_I_PRC_LIST_ID_TEMP.ClearIDList('CharElemValueEnable');
  end ClearCharElemValueEnable;

  /**
  * Description
  *   Mise à jour du dernier incrément utilisé
  */
  procedure UpdateCharLastUsedNumber(iCharacterizationId in number, iNewValue in varchar2)
  is
    lCharactType GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;

    procedure Main(iCharacterizationId in number, iNewValue in varchar2)
    is
    begin
      -- mise à jour nudernier numéro seulement si le format est OK, sinon on ne fait rien
      if GCO_LIB_CHARACTERIZATION.VerifyCharFormat(iCharacterizationId, iNewValue) = 1 then
        begin
          -- recherche du type de caractérisation et indirectement vérification de son existance
          select C_CHARACT_TYPE
            into lCharactType
            from GCO_CHARACTERIZATION
           where GCO_CHARACTERIZATION_ID = iCharacterizationID;
        exception
          when no_data_found then
            raise_application_error(-20088, 'PCS - Characterization does not exist');
        end;

        -- Gestion de pièces
        if lCharactType = gcCharacTypePiece then
          if not PCS.PC_CONFIG.GetBooleanConfig('STM_PIECE_SGL_NUMBERING_COMP') then
            -- pas de numérotation unique par mandat, gestion du dernier incrément
            -- au niveau des biens
            update GCO_CHARACTERIZATION
               set CHA_LAST_USED_INCREMENT =
                     GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_PREFIXE)
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_SUFFIXE)
                                                                   )
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where GCO_CHARACTERIZATION_ID = iCharacterizationId
               and CHA_LAST_USED_INCREMENT <
                     GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_PREFIXE)
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_SUFFIXE)
                                                                   );
          else
            -- numérotation unique par mandat

            -- Maj uniquement si la nouvelle valeur est plus grande que le dernier
            -- incrément précédement utilisé
            if GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                            , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_PIECE_PREFIX') )
                                                            , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_PIECE_SUFFIX') )
                                                             ) > COM_VAR.getNumeric('STM_LASTUSED_PIECENUMBER', null) then
              COM_VAR.setNumeric
                    ('STM_LASTUSED_PIECENUMBER'
                   , null
                   , null
                   , GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_PIECE_PREFIX') )
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_PIECE_SUFFIX') )
                                                                   )
                    );
            end if;
          end if;
        -- Gestion de lots
        elsif lCharactType = gcCharacTypeSet then
          if not PCS.PC_CONFIG.GetBooleanConfig('STM_SET_SGL_NUMBERING_COMP') then
            -- pas de numérotation unique par mandat, gestion du dernier incrément
            -- au niveau des biens
            update GCO_CHARACTERIZATION
               set CHA_LAST_USED_INCREMENT =
                     GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_PREFIXE)
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_SUFFIXE)
                                                                   )
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where GCO_CHARACTERIZATION_ID = iCharacterizationId
               and CHA_LAST_USED_INCREMENT <
                     GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_PREFIXE)
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_SUFFIXE)
                                                                   );
          else
            -- numérotation unique par mandat

            -- Maj uniquement si la nouvelle valeur est plus grande que le dernier
            -- incrément précédement utilisé
            if GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                            , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_SET_PREFIX') )
                                                            , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_SET_SUFFIX') )
                                                             ) > COM_VAR.getNumeric('STM_LASTUSED_SETNUMBER', null) then
              COM_VAR.setNumeric
                      ('STM_LASTUSED_SETNUMBER'
                     , null
                     , null
                     , GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                                    , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_SET_PREFIX') )
                                                                    , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_SET_SUFFIX') )
                                                                     )
                      );
            end if;
          end if;
        -- version
        elsif lCharactType = gcCharacTypeVersion then
          if not PCS.PC_CONFIG.GetBooleanConfig('STM_VERSION_SGL_NUMBERING_COMP') then
            -- pas de numérotation unique par mandat, gestion du dernier incrément
            -- au niveau des biens
            update GCO_CHARACTERIZATION
               set CHA_LAST_USED_INCREMENT =
                     GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_PREFIXE)
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_SUFFIXE)
                                                                   )
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where GCO_CHARACTERIZATION_ID = iCharacterizationId
               and CHA_LAST_USED_INCREMENT <
                     GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_PREFIXE)
                                                                  , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(CHA_SUFFIXE)
                                                                   );
          else
            -- numérotation unique par mandat

            -- Maj uniquement si la nouvelle valeur est plus grande que le dernier
            -- incrément précédement utilisé
            if GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                            , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_VERSION_PREFIX') )
                                                            , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_VERSION_SUFFIX') )
                                                             ) > COM_VAR.getNumeric('STM_LASTUSED_VERSIONNUMBER', null) then
              COM_VAR.setNumeric
                  ('STM_LASTUSED_VERSIONNUMBER'
                 , null
                 , null
                 , GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(iNewValue
                                                                , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_VERSION_PREFIX') )
                                                                , GCO_LIB_CHARACTERIZATION.prefixApplyMacro(PCS.PC_CONFIG.GetConfig('STM_VERSION_SUFFIX') )
                                                                 )
                  );
            end if;
          end if;
        end if;
      end if;
    end Main;

    procedure MainAutonomous(iCharacterizationId in number, iNewValue in varchar2)
    is
      pragma autonomous_transaction;
    begin
      Main(iCharacterizationId, iNewValue);
      commit;
    end;
  begin
    if upper(iNewValue) = 'N/A' then
      null;
    else
      if gCharManagementMode = 0 then
        -- En temps normal cette procedure est appelée en mode Transaction Autonome
        MainAutonomous(iCharacterizationId, iNewValue);
      else
        -- Lors de l'utilisation de l'assistant de création des caractérisations,
        -- comme on utilise une transaction qui crée également la caractérization,
        -- il est primordial de ne pas être en transaction autonome
        Main(iCharacterizationId, iNewValue);
      end if;
    end if;
  end UpdateCharLastUsedNumber;

  /**
  * Description
  *   Dans le cadre d'un ajout de
  *   procedure mettant à jour les différentes tables utilisant les caractérisation
  */
  procedure addCharToExisting(iCharacterizationId in number, iDefValue in varchar2, iQualityValue in number, iRetestValue in date, iError out number)
  is
    cursor lcurCharac(iCharacterizationId number)
    is
      select CHA.GCO_CHARACTERIZATION_ID
           , CHA.C_CHRONOLOGY_TYPE
           , CHA.C_CHARACT_TYPE
           , CHA.C_UNIT_OF_TIME
           , CHA.GCO_GOOD_ID
           , CHA_CHARACTERIZATION_DESIGN
           , CHA.CHA_AUTOMATIC_INCREMENTATION
           , CHA.CHA_INCREMENT_STE
           , CHA.CHA_LAST_USED_INCREMENT
           , CHA.CHA_LAPSING_DELAY
           , decode(PDT.PDT_STOCK_MANAGEMENT, 1, CHA.CHA_STOCK_MANAGEMENT, 0) CHA_STOCK_MANAGEMENT
           , CHA.GCO_CHAR_AUTONUM_FUNC_ID
           , CHA.CHA_LAPSING_MARGE
        from GCO_CHARACTERIZATION CHA
           , GCO_PRODUCT PDT
       where CHA.GCO_CHARACTERIZATION_ID = iCharacterizationId
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID;

    ltplCharac            lcurCharac%rowtype;

    cursor lcurPDE(iGoodId number)
    is
      select PDE.DOC_POSITION_DETAIL_ID
           , PDE.GCO_CHARACTERIZATION_ID
           , PDE.GCO_GCO_CHARACTERIZATION_ID
           , PDE.GCO2_GCO_CHARACTERIZATION_ID
           , PDE.GCO3_GCO_CHARACTERIZATION_ID
           , PDE.GCO4_GCO_CHARACTERIZATION_ID
           , POS.STM_MOVEMENT_KIND_ID
           , GAU.C_ADMIN_DOMAIN
           , GAS.GAS_CHARACTERIZATION
           , GAS.GAS_ALL_CHARACTERIZATION
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and PDE.PDE_BASIS_QUANTITY <> 0
         and POS.GCO_GOOD_ID = iGoodId;

    cursor lcurBarCodes(iGoodId number)
    is
      select dba.DOC_BARCODE_ID
           , dba.GCO_CHARACTERIZATION_ID
           , dba.GCO_GCO_CHARACTERIZATION_ID
           , dba.GCO2_GCO_CHARACTERIZATION_ID
           , dba.GCO3_GCO_CHARACTERIZATION_ID
           , dba.GCO4_GCO_CHARACTERIZATION_ID
        from DOC_BARCODE dba
       where dba.GCO_GOOD_ID = iGoodId;

    cursor lcurStockMovements(iGoodId number)
    is
      select SMO.STM_STOCK_MOVEMENT_ID
           , SMO.GCO_CHARACTERIZATION_ID
           , SMO.GCO_GCO_CHARACTERIZATION_ID
           , SMO.GCO2_GCO_CHARACTERIZATION_ID
           , SMO.GCO3_GCO_CHARACTERIZATION_ID
           , SMO.GCO4_GCO_CHARACTERIZATION_ID
           , SMO.SMO_CHARACTERIZATION_VALUE_1
           , SMO.SMO_CHARACTERIZATION_VALUE_2
           , SMO.SMO_CHARACTERIZATION_VALUE_3
           , SMO.SMO_CHARACTERIZATION_VALUE_4
           , SMO.SMO_CHARACTERIZATION_VALUE_5
           , SMO_PIECE
           , SMO_SET
           , SMO_VERSION
           , SMO_CHRONOLOGICAL
           , SMO_STD_CHAR_1
           , SMO_STD_CHAR_2
           , SMO_STD_CHAR_3
           , SMO_STD_CHAR_4
           , SMO_STD_CHAR_5
        from STM_STOCK_MOVEMENT SMO
       where GCO_GOOD_ID = iGoodId;

    cursor lcurStockPositions(iGoodId number)
    is
      select SPO.STM_STOCK_POSITION_ID
           , SPO.GCO_CHARACTERIZATION_ID
           , SPO.GCO_GCO_CHARACTERIZATION_ID
           , SPO.GCO2_GCO_CHARACTERIZATION_ID
           , SPO.GCO3_GCO_CHARACTERIZATION_ID
           , SPO.GCO4_GCO_CHARACTERIZATION_ID
           , SPO.SPO_CHARACTERIZATION_VALUE_1
           , SPO.SPO_CHARACTERIZATION_VALUE_2
           , SPO.SPO_CHARACTERIZATION_VALUE_3
           , SPO.SPO_CHARACTERIZATION_VALUE_4
           , SPO.SPO_CHARACTERIZATION_VALUE_5
           , SPO.STM_ELEMENT_NUMBER_ID
           , SPO.STM_STM_ELEMENT_NUMBER_ID
           , SPO.STM2_STM_ELEMENT_NUMBER_ID
        from STM_STOCK_POSITION SPO
       where GCO_GOOD_ID = iGoodId;

    cursor lcurAnnualEvolutions(iGoodId number)
    is
      select SAE.STM_ANNUAL_EVOLUTION_ID
           , SAE.GCO_CHARACTERIZATION_ID
           , SAE.GCO_GCO_CHARACTERIZATION_ID
           , SAE.GCO2_GCO_CHARACTERIZATION_ID
           , SAE.GCO3_GCO_CHARACTERIZATION_ID
           , SAE.GCO4_GCO_CHARACTERIZATION_ID
        from STM_ANNUAL_EVOLUTION SAE
       where GCO_GOOD_ID = iGoodId;

    cursor lcurExerciseEvolutions(iGoodId number)
    is
      select SPE.STM_EXERCISE_EVOLUTION_ID
           , SPE.GCO_CHARACTERIZATION_ID
           , SPE.GCO_GCO_CHARACTERIZATION_ID
           , SPE.GCO2_GCO_CHARACTERIZATION_ID
           , SPE.GCO3_GCO_CHARACTERIZATION_ID
           , SPE.GCO4_GCO_CHARACTERIZATION_ID
        from STM_EXERCISE_EVOLUTION SPE
       where GCO_GOOD_ID = iGoodId;

    cursor lcurIntercTrsf(iGoodId number)
    is
      select int.STM_INTERC_STOCK_TRSF_ID
           , int.GCO_CHARACTERIZATION_1_ID
           , int.GCO_CHARACTERIZATION_2_ID
           , int.GCO_CHARACTERIZATION_3_ID
           , int.GCO_CHARACTERIZATION_4_ID
           , int.GCO_CHARACTERIZATION_5_ID
        from STM_INTERC_STOCK_TRSF int
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFalLot(iGoodID number)
    is
      select distinct FAL_LOT_DETAIL.FAL_LOT_ID
                    , C_LOT_STATUS
                 from FAL_LOT_DETAIL
                    , FAL_LOT
                where C_LOT_DETAIL = '1'
                  and FAL_LOT_DETAIL.GCO_GOOD_ID = iGoodId
                  and FAL_LOT_DETAIL.FAL_LOT_ID = FAL_LOT.FAL_LOT_ID;

    cursor lcurLotDetail(iLotId number, iGoodId number)
    is
      select FAD.FAL_LOT_DETAIL_ID
           , FAD.GCO_CHARACTERIZATION_ID
           , FAD.GCO_GCO_CHARACTERIZATION_ID
           , FAD.GCO2_GCO_CHARACTERIZATION_ID
           , FAD.GCO3_GCO_CHARACTERIZATION_ID
           , FAD.GCO4_GCO_CHARACTERIZATION_ID
        from FAL_LOT_DETAIL FAD
       where FAL_LOT_ID = iLotId
         and GCO_GOOD_ID = iGoodId;

    cursor lcurLotDetailHist(iGoodId number)
    is
      select FAD.FAL_LOT_DETAIL_HIST_ID
           , FAD.GCO_CHARACTERIZATION_ID
           , FAD.GCO_GCO_CHARACTERIZATION_ID
           , FAD.GCO2_GCO_CHARACTERIZATION_ID
           , FAD.GCO3_GCO_CHARACTERIZATION_ID
           , FAD.GCO4_GCO_CHARACTERIZATION_ID
        from FAL_LOT_DETAIL_HIST FAD
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFactoryIn(iGoodId number)
    is
      select FAC.FAL_FACTORY_IN_ID
           , FAC.GCO_CHARACTERIZATION_ID
           , FAC.GCO_GCO_CHARACTERIZATION_ID
           , FAC.GCO2_GCO_CHARACTERIZATION_ID
           , FAC.GCO3_GCO_CHARACTERIZATION_ID
           , FAC.GCO4_GCO_CHARACTERIZATION_ID
           , FAC.IN_CHARACTERIZATION_VALUE_1
           , FAC.IN_CHARACTERIZATION_VALUE_2
           , FAC.IN_CHARACTERIZATION_VALUE_3
           , FAC.IN_CHARACTERIZATION_VALUE_4
           , FAC.IN_CHARACTERIZATION_VALUE_5
        from FAL_FACTORY_IN FAC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFactoryInHist(iGoodId number)
    is
      select FAC.FAL_FACTORY_IN_HIST_ID
           , FAC.GCO_CHARACTERIZATION_ID
           , FAC.GCO_GCO_CHARACTERIZATION_ID
           , FAC.GCO2_GCO_CHARACTERIZATION_ID
           , FAC.GCO3_GCO_CHARACTERIZATION_ID
           , FAC.GCO4_GCO_CHARACTERIZATION_ID
           , FAC.IN_CHARACTERIZATION_VALUE_1
           , FAC.IN_CHARACTERIZATION_VALUE_2
           , FAC.IN_CHARACTERIZATION_VALUE_3
           , FAC.IN_CHARACTERIZATION_VALUE_4
           , FAC.IN_CHARACTERIZATION_VALUE_5
        from FAL_FACTORY_IN_HIST FAC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFactoryOut(iGoodId number)
    is
      select FAC.FAL_FACTORY_OUT_ID
           , FAC.GCO_CHARACTERIZATION1_ID
           , FAC.GCO_CHARACTERIZATION2_ID
           , FAC.GCO_CHARACTERIZATION3_ID
           , FAC.GCO_CHARACTERIZATION4_ID
           , FAC.GCO_CHARACTERIZATION5_ID
           , FAC.OUT_CHARACTERIZATION_VALUE_1
           , FAC.OUT_CHARACTERIZATION_VALUE_2
           , FAC.OUT_CHARACTERIZATION_VALUE_3
           , FAC.OUT_CHARACTERIZATION_VALUE_4
           , FAC.OUT_CHARACTERIZATION_VALUE_5
        from FAL_FACTORY_OUT FAC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFalDocConsult(iGoodId number)
    is
      select FDC.FAL_DOC_CONSULT_ID
           , FDC.GCO_CHARACTERIZATION1_ID
           , FDC.GCO_CHARACTERIZATION2_ID
           , FDC.GCO_CHARACTERIZATION3_ID
           , FDC.GCO_CHARACTERIZATION4_ID
           , FDC.GCO_CHARACTERIZATION5_ID
        from FAL_DOC_CONSULT FDC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFalDocConsultHist(iGoodId number)
    is
      select FDC.FAL_DOC_CONSULT_HIST_ID
           , FDC.GCO_CHARACTERIZATION1_ID
           , FDC.GCO_CHARACTERIZATION2_ID
           , FDC.GCO_CHARACTERIZATION3_ID
           , FDC.GCO_CHARACTERIZATION4_ID
           , FDC.GCO_CHARACTERIZATION5_ID
        from FAL_DOC_CONSULT_HIST FDC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFalDocProp(iGoodId number)
    is
      select FDP.FAL_DOC_PROP_ID
           , FDP.GCO_CHARACTERIZATION1_ID
           , FDP.GCO_CHARACTERIZATION2_ID
           , FDP.GCO_CHARACTERIZATION3_ID
           , FDP.GCO_CHARACTERIZATION4_ID
           , FDP.GCO_CHARACTERIZATION5_ID
        from FAL_DOC_PROP FDP
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFalLotProp(iGoodId number)
    is
      select FAD.FAL_LOT_PROP_ID
           , FAD.GCO_CHARACTERIZATION1_ID
           , FAD.GCO_CHARACTERIZATION2_ID
           , FAD.GCO_CHARACTERIZATION3_ID
           , FAD.GCO_CHARACTERIZATION4_ID
           , FAD.GCO_CHARACTERIZATION5_ID
        from FAL_LOT_PROP FAD
       where GCO_GOOD_ID = iGoodId;

    cursor lcurNetworkNeed(iGoodId number)
    is
      select FAN.FAL_NETWORK_NEED_ID
           , FAN.GCO_CHARACTERIZATION1_ID
           , FAN.GCO_CHARACTERIZATION2_ID
           , FAN.GCO_CHARACTERIZATION3_ID
           , FAN.GCO_CHARACTERIZATION4_ID
           , FAN.GCO_CHARACTERIZATION5_ID
        from FAL_NETWORK_NEED FAN
       where GCO_GOOD_ID = iGoodId;

    cursor lcurNetworkSupply(iGoodId number)
    is
      select FAN.FAL_NETWORK_SUPPLY_ID
           , FAN.GCO_CHARACTERIZATION1_ID
           , FAN.GCO_CHARACTERIZATION2_ID
           , FAN.GCO_CHARACTERIZATION3_ID
           , FAN.GCO_CHARACTERIZATION4_ID
           , FAN.GCO_CHARACTERIZATION5_ID
        from FAL_NETWORK_SUPPLY FAN
       where GCO_GOOD_ID = iGoodId;

    --and (FAL_LOT_ID is null or isMorphDetail(FAL_LOT_ID));
    cursor lcurFalOutCBarCode(iGoodId number)
    is
      select FOC.FAL_OUT_COMPO_BARCODE_ID
           , FOC.GCO_CHARACTERIZATION_ID
           , FOC.GCO_GCO_CHARACTERIZATION_ID
           , FOC.GCO2_GCO_CHARACTERIZATION_ID
           , FOC.GCO3_GCO_CHARACTERIZATION_ID
           , FOC.GCO4_GCO_CHARACTERIZATION_ID
        from FAL_OUT_COMPO_BARCODE FOC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurAsaRecordRepair(iGoodId number)
    is
      select are.ASA_RECORD_ID
           , are.GCO_CHAR1_ID
           , are.GCO_CHAR2_ID
           , are.GCO_CHAR3_ID
           , are.GCO_CHAR4_ID
           , are.GCO_CHAR5_ID
        from ASA_RECORD are
       where GCO_ASA_TO_REPAIR_ID = iGoodId;

    cursor lcurAsaRecordExchange(iGoodId number)
    is
      select are.ASA_RECORD_ID
           , are.GCO_EXCH_CHAR1_ID
           , are.GCO_EXCH_CHAR2_ID
           , are.GCO_EXCH_CHAR3_ID
           , are.GCO_EXCH_CHAR4_ID
           , are.GCO_EXCH_CHAR5_ID
        from ASA_RECORD are
       where GCO_ASA_EXCHANGE_ID = iGoodId;

    cursor lcurAsaRecordNewGood(iGoodId number)
    is
      select are.ASA_RECORD_ID
           , are.GCO_NEW_CHAR1_ID
           , are.GCO_NEW_CHAR2_ID
           , are.GCO_NEW_CHAR3_ID
           , are.GCO_NEW_CHAR4_ID
           , are.GCO_NEW_CHAR5_ID
        from ASA_RECORD are
       where GCO_NEW_GOOD_ID = iGoodId;

    cursor lcurAsaRecordDetails(iGoodId number)
    is
      select red.ASA_RECORD_DETAIL_ID
           , red.GCO_CHAR1_ID
           , red.GCO_CHAR2_ID
           , red.GCO_CHAR3_ID
           , red.GCO_CHAR4_ID
           , red.GCO_CHAR5_ID
        from ASA_RECORD_DETAIL red
           , ASA_RECORD are
       where are.GCO_ASA_TO_REPAIR_ID = iGoodId
         and are.ASA_RECORD_ID = RED.ASA_RECORD_ID;

    cursor lcurAsaRecordRepDetails(iGoodId number)
    is
      select RRD.ASA_RECORD_REP_DETAIL_ID
           , RRD.GCO_CHAR1_ID
           , RRD.GCO_CHAR2_ID
           , RRD.GCO_CHAR3_ID
           , RRD.GCO_CHAR4_ID
           , RRD.GCO_CHAR5_ID
        from ASA_RECORD_REP_DETAIL RRD
           , ASA_RECORD_DETAIL RED
           , ASA_RECORD are
       where are.GCO_ASA_TO_REPAIR_ID = iGoodId
         and are.ASA_RECORD_ID = RED.ASA_RECORD_ID
         and RRD.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID;

    cursor lcurAsaRecordExchDetails(iGoodId number)
    is
      select REX.ASA_RECORD_EXCH_DETAIL_ID
           , REX.GCO_EXCH_CHAR1_ID
           , REX.GCO_EXCH_CHAR2_ID
           , REX.GCO_EXCH_CHAR3_ID
           , REX.GCO_EXCH_CHAR4_ID
           , REX.GCO_EXCH_CHAR5_ID
        from ASA_RECORD_EXCH_DETAIL REX
           , ASA_RECORD_DETAIL RED
           , ASA_RECORD are
       where are.GCO_ASA_EXCHANGE_ID = iGoodId
         and are.ASA_RECORD_ID = RED.ASA_RECORD_ID
         and REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID;

    cursor lcurAsaRecordComps(iGoodId number)
    is
      select ARC.ASA_RECORD_COMP_ID
           , ARC.GCO_CHAR1_ID
           , ARC.GCO_CHAR2_ID
           , ARC.GCO_CHAR3_ID
           , ARC.GCO_CHAR4_ID
           , ARC.GCO_CHAR5_ID
        from ASA_RECORD_COMP ARC
       where GCO_COMPONENT_ID = iGoodId;

    cursor lcurAsaGuarantyCards(iGoodId number)
    is
      select AGC.ASA_GUARANTY_CARDS_ID
           , AGC.GCO_CHAR1_ID
           , AGC.GCO_CHAR2_ID
           , AGC.GCO_CHAR3_ID
           , AGC.GCO_CHAR4_ID
           , AGC.GCO_CHAR5_ID
        from ASA_GUARANTY_CARDS AGC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurAsaStolenGoods(iGoodId number)
    is
      select ASG.ASA_STOLEN_GOODS_ID
           , ASG.GCO_CHAR1_ID
           , ASG.GCO_CHAR2_ID
           , ASG.GCO_CHAR3_ID
           , ASG.GCO_CHAR4_ID
           , ASG.GCO_CHAR5_ID
        from ASA_STOLEN_GOODS ASG
       where GCO_GOOD_ID = iGoodId;

    cursor lcurInterventionDetail(iGoodId number)
    is
      select AID.ASA_INTERVENTION_DETAIL_ID
           , AID.GCO_CHAR1_ID
           , AID.GCO_CHAR2_ID
           , AID.GCO_CHAR3_ID
           , AID.GCO_CHAR4_ID
           , AID.GCO_CHAR5_ID
        from ASA_INTERVENTION_DETAIL AID
       where GCO_GOOD_ID = iGoodId;

    lAtLeastOneElement    boolean                                         := false;
    lElementNumberId      STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lQualityStatusId      STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type   := null;
    lDefltStockNetwork    number;
    lDefltLocationNetwork number;
    lCheckIn              number;
  begin
    -- Début du mode de maintenance
    gCharManagementMode  := 1;
    -- Init du flag d'erreur
    iError               := 0;

    begin
      select CHA.GCO_CHARACTERIZATION_ID
           , CHA.C_CHRONOLOGY_TYPE
           , CHA.C_CHARACT_TYPE
           , CHA.C_UNIT_OF_TIME
           , CHA.GCO_GOOD_ID
           , CHA.CHA_CHARACTERIZATION_DESIGN
           , CHA.CHA_AUTOMATIC_INCREMENTATION
           , CHA.CHA_INCREMENT_STE
           , CHA.CHA_LAST_USED_INCREMENT
           , CHA.CHA_LAPSING_DELAY
           , decode(PDT.PDT_STOCK_MANAGEMENT, 1, CHA.CHA_STOCK_MANAGEMENT, 0) CHA_STOCK_MANAGEMENT
           , CHA.GCO_CHAR_AUTONUM_FUNC_ID
           , CHA.CHA_LAPSING_MARGE
        into ltplCharac
        from GCO_CHARACTERIZATION CHA
           , GCO_PRODUCT PDT
       where CHA.GCO_CHARACTERIZATION_ID = iCharacterizationId
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID;

      -- Log de l'opération
      LogCharacWizardEvent('ADD', iCharacterizationId, ltplCharac.CHA_CHARACTERIZATION_DESIGN, ltplCharac.GCO_GOOD_ID);
      -- Suppression des attributions du bien
      FAL_DELETE_ATTRIBS.Delete_All_Attribs(ltplCharac.GCO_GOOD_ID, null, null, 0);

      for tplPDE in lcurPDE(ltplCharac.GCO_GOOD_ID) loop
        declare
          lChar1Id DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type;
          lChar2Id DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type;
          lChar3Id DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type;
          lChar4Id DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type;
          lChar5Id DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type;
          lVal1    DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
          lVal2    DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
          lVal3    DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
          lVal4    DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
          lVal5    DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
        begin
          exit when iCharacterizationId in
                     (nvl(tplPDE.GCO_CHARACTERIZATION_ID, 0)
                    , nvl(tplPDE.GCO_GCO_CHARACTERIZATION_ID, 0)
                    , nvl(tplPDE.GCO2_GCO_CHARACTERIZATION_ID, 0)
                    , nvl(tplPDE.GCO3_GCO_CHARACTERIZATION_ID, 0)
                    , nvl(tplPDE.GCO4_GCO_CHARACTERIZATION_ID, 0)
                     );
          lAtLeastOneElement  := true;

          if    (    ltplCharac.CHA_STOCK_MANAGEMENT = 1
                 and (   tplPDE.STM_MOVEMENT_KIND_ID is not null
                      or (    tplPDE.GAS_CHARACTERIZATION = 1
                          and ltplCharac.C_CHARACT_TYPE in(gcCharacTypeVersion, gcCharacTypeCharacteristic) )
                      or (tplPDE.GAS_ALL_CHARACTERIZATION = 1)
                     )
                )
             or (    ltplCharac.CHA_STOCK_MANAGEMENT = 0
                 and ( (    tplPDE.C_ADMIN_DOMAIN = gcAdminDomainSale
                        and tplPDE.STM_MOVEMENT_KIND_ID is not null) ) ) then
            if tplPDE.GCO_CHARACTERIZATION_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplPDE.GCO_GCO_CHARACTERIZATION_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplPDE.GCO2_GCO_CHARACTERIZATION_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplPDE.GCO3_GCO_CHARACTERIZATION_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplPDE.GCO4_GCO_CHARACTERIZATION_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update DOC_POSITION_DETAIL
               set GCO_CHARACTERIZATION_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_ID)
                 , GCO_GCO_CHARACTERIZATION_ID = nvl(lChar2Id, GCO_GCO_CHARACTERIZATION_ID)
                 , GCO2_GCO_CHARACTERIZATION_ID = nvl(lChar3Id, GCO2_GCO_CHARACTERIZATION_ID)
                 , GCO3_GCO_CHARACTERIZATION_ID = nvl(lChar4Id, GCO3_GCO_CHARACTERIZATION_ID)
                 , GCO4_GCO_CHARACTERIZATION_ID = nvl(lChar5Id, GCO4_GCO_CHARACTERIZATION_ID)
                 , PDE_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, PDE_CHARACTERIZATION_VALUE_1, lVal1)
                 , PDE_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, PDE_CHARACTERIZATION_VALUE_2, lVal2)
                 , PDE_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, PDE_CHARACTERIZATION_VALUE_3, lVal3)
                 , PDE_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, PDE_CHARACTERIZATION_VALUE_4, lVal4)
                 , PDE_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, PDE_CHARACTERIZATION_VALUE_5, lVal5)
             where DOC_POSITION_DETAIL_ID = tplPDE.DOC_POSITION_DETAIL_ID;
          end if;
        end;
      end loop;

      -- Lors de l'ajout d'une caractérisation "Piece" éclater les details pour tous les encours
      if ltplCharac.C_CHARACT_TYPE = gcCharacTypePiece then
        splitDocDetailsForPiece(ltplCharac.GCO_GOOD_ID, ltplCharac.GCO_CHARACTERIZATION_ID, ltplCharac.CHA_STOCK_MANAGEMENT);

        if ltplCharac.CHA_STOCK_MANAGEMENT = 1 then
          splitFalLotDetailsForPiece(ltplCharac.GCO_GOOD_ID, ltplCharac.GCO_CHARACTERIZATION_ID);
        end if;
      end if;

      -- si la caractérisation à ajouter est gérée en stock
      if ltplCharac.CHA_STOCK_MANAGEMENT = 1 then
        for tplBarCode in lcurBarCodes(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id DOC_BARCODE.GCO_CHARACTERIZATION_ID%type;
            lChar2Id DOC_BARCODE.GCO_CHARACTERIZATION_ID%type;
            lChar3Id DOC_BARCODE.GCO_CHARACTERIZATION_ID%type;
            lChar4Id DOC_BARCODE.GCO_CHARACTERIZATION_ID%type;
            lChar5Id DOC_BARCODE.GCO_CHARACTERIZATION_ID%type;
            lVal1    DOC_BARCODE.DBA_CHARACTERIZATION_VALUE_1%type;
            lVal2    DOC_BARCODE.DBA_CHARACTERIZATION_VALUE_1%type;
            lVal3    DOC_BARCODE.DBA_CHARACTERIZATION_VALUE_1%type;
            lVal4    DOC_BARCODE.DBA_CHARACTERIZATION_VALUE_1%type;
            lVal5    DOC_BARCODE.DBA_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplBarCode.GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplBarCode.GCO_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplBarCode.GCO2_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplBarCode.GCO3_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplBarCode.GCO4_GCO_CHARACTERIZATION_ID, 0)
                       );

            if tplBarCode.GCO_CHARACTERIZATION_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplBarCode.GCO_GCO_CHARACTERIZATION_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplBarCode.GCO2_GCO_CHARACTERIZATION_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplBarCode.GCO3_GCO_CHARACTERIZATION_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplBarCode.GCO4_GCO_CHARACTERIZATION_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update DOC_BARCODE
               set GCO_CHARACTERIZATION_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_ID)
                 , GCO_GCO_CHARACTERIZATION_ID = nvl(lChar2Id, GCO_GCO_CHARACTERIZATION_ID)
                 , GCO2_GCO_CHARACTERIZATION_ID = nvl(lChar3Id, GCO2_GCO_CHARACTERIZATION_ID)
                 , GCO3_GCO_CHARACTERIZATION_ID = nvl(lChar4Id, GCO3_GCO_CHARACTERIZATION_ID)
                 , GCO4_GCO_CHARACTERIZATION_ID = nvl(lChar5Id, GCO4_GCO_CHARACTERIZATION_ID)
                 , DBA_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, DBA_CHARACTERIZATION_VALUE_1, lVal1)
                 , DBA_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, DBA_CHARACTERIZATION_VALUE_2, lVal2)
                 , DBA_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, DBA_CHARACTERIZATION_VALUE_3, lVal3)
                 , DBA_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, DBA_CHARACTERIZATION_VALUE_4, lVal4)
                 , DBA_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, DBA_CHARACTERIZATION_VALUE_5, lVal5)
             where DOC_BARCODE_ID = tplBarCode.DOC_BARCODE_ID;
          end;
        end loop;

        for tplStockMovement in lcurStockMovements(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id       STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
            lChar2Id       STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
            lChar3Id       STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
            lChar4Id       STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
            lChar5Id       STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
            lVal1          STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
            lVal2          STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
            lVal3          STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
            lVal4          STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
            lVal5          STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
            lPiece         varchar2(30);
            lSet           varchar2(30);
            lVersion       varchar2(30);
            lChronological varchar2(30);
            lCharStd1      varchar2(30);
            lCharStd2      varchar2(30);
            lCharStd3      varchar2(30);
            lCharStd4      varchar2(30);
            lCharStd5      varchar2(30);
          begin
            exit when iCharacterizationId in
                       (nvl(tplStockMovement.GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplStockMovement.GCO_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplStockMovement.GCO2_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplStockMovement.GCO3_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplStockMovement.GCO4_GCO_CHARACTERIZATION_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplStockMovement.GCO_CHARACTERIZATION_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplStockMovement.GCO_GCO_CHARACTERIZATION_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplStockMovement.GCO2_GCO_CHARACTERIZATION_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplStockMovement.GCO3_GCO_CHARACTERIZATION_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplStockMovement.GCO4_GCO_CHARACTERIZATION_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            -- Mise à jour des champs dénormalisé d'affichage des caractérisations
            GCO_LIB_CHARACTERIZATION.ClassifyCharacterizations(nvl(lChar1Id, tplStockMovement.GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar2Id, tplStockMovement.GCO_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar3Id, tplStockMovement.GCO2_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar4Id, tplStockMovement.GCO3_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar5Id, tplStockMovement.GCO4_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lVal1, tplStockMovement.SMO_CHARACTERIZATION_VALUE_1)
                                                             , nvl(lVal2, tplStockMovement.SMO_CHARACTERIZATION_VALUE_2)
                                                             , nvl(lVal3, tplStockMovement.SMO_CHARACTERIZATION_VALUE_3)
                                                             , nvl(lVal4, tplStockMovement.SMO_CHARACTERIZATION_VALUE_4)
                                                             , nvl(lVal5, tplStockMovement.SMO_CHARACTERIZATION_VALUE_5)
                                                             , lPiece
                                                             , lSet
                                                             , lVersion
                                                             , lChronological
                                                             , lCharStd1
                                                             , lCharStd2
                                                             , lCharStd3
                                                             , lCharStd4
                                                             , lCharStd5
                                                              );

            declare
              lCRUD_DEF fwk_i_typ_definition.t_crud_def;
            begin
              FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement
                                 , lCRUD_DEF
                                 , false
                                 , tplStockMovement.STM_STOCK_MOVEMENT_ID
                                 , null
                                 , 'STM_STOCK_MOVEMENT_ID'
                                  );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', tplStockMovement.STM_STOCK_MOVEMENT_ID);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO_CHARACTERIZATION_ID', nvl(lChar1Id, tplStockMovement.GCO_CHARACTERIZATION_ID) );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO_GCO_CHARACTERIZATION_ID', nvl(lChar2Id, tplStockMovement.GCO_GCO_CHARACTERIZATION_ID) );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO2_GCO_CHARACTERIZATION_ID', nvl(lChar3Id, tplStockMovement.GCO2_GCO_CHARACTERIZATION_ID) );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO3_GCO_CHARACTERIZATION_ID', nvl(lChar4Id, tplStockMovement.GCO3_GCO_CHARACTERIZATION_ID) );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO4_GCO_CHARACTERIZATION_ID', nvl(lChar5Id, tplStockMovement.GCO4_GCO_CHARACTERIZATION_ID) );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF
                                            , 'SMO_CHARACTERIZATION_VALUE_1'
                                            , case
                                                when lChar1Id is null then tplStockMovement.SMO_CHARACTERIZATION_VALUE_1
                                                else lVal1
                                              end
                                             );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF
                                            , 'SMO_CHARACTERIZATION_VALUE_2'
                                            , case
                                                when lChar2Id is null then tplStockMovement.SMO_CHARACTERIZATION_VALUE_2
                                                else lVal2
                                              end
                                             );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF
                                            , 'SMO_CHARACTERIZATION_VALUE_3'
                                            , case
                                                when lChar3Id is null then tplStockMovement.SMO_CHARACTERIZATION_VALUE_3
                                                else lVal3
                                              end
                                             );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF
                                            , 'SMO_CHARACTERIZATION_VALUE_4'
                                            , case
                                                when lChar4Id is null then tplStockMovement.SMO_CHARACTERIZATION_VALUE_4
                                                else lVal4
                                              end
                                             );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF
                                            , 'SMO_CHARACTERIZATION_VALUE_5'
                                            , case
                                                when lChar5Id is null then tplStockMovement.SMO_CHARACTERIZATION_VALUE_5
                                                else lVal5
                                              end
                                             );
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_PIECE', lPiece);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_SET', lSet);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_VERSION', lVersion);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_CHRONOLOGICAL', lChronological);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_STD_CHAR_1', lCharStd1);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_STD_CHAR_2', lCharStd2);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_STD_CHAR_3', lCharStd3);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_STD_CHAR_4', lCharStd4);
              FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_STD_CHAR_5', lCharStd5);
              FWK_I_MGT_ENTITY.UpdateEntity(lCRUD_DEF);
              FWK_I_MGT_ENTITY.Release(lCRUD_DEF);
            end loop;
          end;
        end loop;

        for tplAnnualEvolution in lcurAnnualEvolutions(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id STM_ANNUAL_EVOLUTION.GCO_CHARACTERIZATION_ID%type;
            lChar2Id STM_ANNUAL_EVOLUTION.GCO_CHARACTERIZATION_ID%type;
            lChar3Id STM_ANNUAL_EVOLUTION.GCO_CHARACTERIZATION_ID%type;
            lChar4Id STM_ANNUAL_EVOLUTION.GCO_CHARACTERIZATION_ID%type;
            lChar5Id STM_ANNUAL_EVOLUTION.GCO_CHARACTERIZATION_ID%type;
            lVal1    STM_ANNUAL_EVOLUTION.SAE_CHARACTERIZATION_VALUE_1%type;
            lVal2    STM_ANNUAL_EVOLUTION.SAE_CHARACTERIZATION_VALUE_1%type;
            lVal3    STM_ANNUAL_EVOLUTION.SAE_CHARACTERIZATION_VALUE_1%type;
            lVal4    STM_ANNUAL_EVOLUTION.SAE_CHARACTERIZATION_VALUE_1%type;
            lVal5    STM_ANNUAL_EVOLUTION.SAE_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplAnnualEvolution.GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplAnnualEvolution.GCO_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplAnnualEvolution.GCO2_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplAnnualEvolution.GCO3_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplAnnualEvolution.GCO4_GCO_CHARACTERIZATION_ID, 0)
                       );

            if tplAnnualEvolution.GCO_CHARACTERIZATION_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplAnnualEvolution.GCO_GCO_CHARACTERIZATION_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplAnnualEvolution.GCO2_GCO_CHARACTERIZATION_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplAnnualEvolution.GCO3_GCO_CHARACTERIZATION_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplAnnualEvolution.GCO4_GCO_CHARACTERIZATION_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update STM_ANNUAL_EVOLUTION
               set GCO_CHARACTERIZATION_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_ID)
                 , GCO_GCO_CHARACTERIZATION_ID = nvl(lChar2Id, GCO_GCO_CHARACTERIZATION_ID)
                 , GCO2_GCO_CHARACTERIZATION_ID = nvl(lChar3Id, GCO2_GCO_CHARACTERIZATION_ID)
                 , GCO3_GCO_CHARACTERIZATION_ID = nvl(lChar4Id, GCO3_GCO_CHARACTERIZATION_ID)
                 , GCO4_GCO_CHARACTERIZATION_ID = nvl(lChar5Id, GCO4_GCO_CHARACTERIZATION_ID)
                 , SAE_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, SAE_CHARACTERIZATION_VALUE_1, lVal1)
                 , SAE_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, SAE_CHARACTERIZATION_VALUE_2, lVal2)
                 , SAE_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, SAE_CHARACTERIZATION_VALUE_3, lVal3)
                 , SAE_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, SAE_CHARACTERIZATION_VALUE_4, lVal4)
                 , SAE_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, SAE_CHARACTERIZATION_VALUE_5, lVal5)
             where STM_ANNUAL_EVOLUTION_ID = tplAnnualEvolution.STM_ANNUAL_EVOLUTION_ID;
          end;
        end loop;

        for tplExerciseEvolution in lcurExerciseEvolutions(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id STM_EXERCISE_EVOLUTION.GCO_CHARACTERIZATION_ID%type;
            lChar2Id STM_EXERCISE_EVOLUTION.GCO_CHARACTERIZATION_ID%type;
            lChar3Id STM_EXERCISE_EVOLUTION.GCO_CHARACTERIZATION_ID%type;
            lChar4Id STM_EXERCISE_EVOLUTION.GCO_CHARACTERIZATION_ID%type;
            lChar5Id STM_EXERCISE_EVOLUTION.GCO_CHARACTERIZATION_ID%type;
            lVal1    STM_EXERCISE_EVOLUTION.SPE_CHARACTERIZATION_VALUE_1%type;
            lVal2    STM_EXERCISE_EVOLUTION.SPE_CHARACTERIZATION_VALUE_1%type;
            lVal3    STM_EXERCISE_EVOLUTION.SPE_CHARACTERIZATION_VALUE_1%type;
            lVal4    STM_EXERCISE_EVOLUTION.SPE_CHARACTERIZATION_VALUE_1%type;
            lVal5    STM_EXERCISE_EVOLUTION.SPE_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplExerciseEvolution.GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplExerciseEvolution.GCO_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplExerciseEvolution.GCO2_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplExerciseEvolution.GCO3_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplExerciseEvolution.GCO4_GCO_CHARACTERIZATION_ID, 0)
                       );

            if tplExerciseEvolution.GCO_CHARACTERIZATION_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplExerciseEvolution.GCO_GCO_CHARACTERIZATION_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplExerciseEvolution.GCO2_GCO_CHARACTERIZATION_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplExerciseEvolution.GCO3_GCO_CHARACTERIZATION_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplExerciseEvolution.GCO4_GCO_CHARACTERIZATION_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update STM_EXERCISE_EVOLUTION
               set GCO_CHARACTERIZATION_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_ID)
                 , GCO_GCO_CHARACTERIZATION_ID = nvl(lChar2Id, GCO_GCO_CHARACTERIZATION_ID)
                 , GCO2_GCO_CHARACTERIZATION_ID = nvl(lChar3Id, GCO2_GCO_CHARACTERIZATION_ID)
                 , GCO3_GCO_CHARACTERIZATION_ID = nvl(lChar4Id, GCO3_GCO_CHARACTERIZATION_ID)
                 , GCO4_GCO_CHARACTERIZATION_ID = nvl(lChar5Id, GCO4_GCO_CHARACTERIZATION_ID)
                 , SPE_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, SPE_CHARACTERIZATION_VALUE_1, lVal1)
                 , SPE_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, SPE_CHARACTERIZATION_VALUE_2, lVal2)
                 , SPE_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, SPE_CHARACTERIZATION_VALUE_3, lVal3)
                 , SPE_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, SPE_CHARACTERIZATION_VALUE_4, lVal4)
                 , SPE_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, SPE_CHARACTERIZATION_VALUE_5, lVal5)
             where STM_EXERCISE_EVOLUTION_ID = tplExerciseEvolution.STM_EXERCISE_EVOLUTION_ID;
          end;
        end loop;

        for tplIntercTrsf in lcurIntercTrsf(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_1_ID%type;
            lChar2Id STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_2_ID%type;
            lChar3Id STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_3_ID%type;
            lChar4Id STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_4_ID%type;
            lChar5Id STM_INTERC_STOCK_TRSF.GCO_CHARACTERIZATION_5_ID%type;
            lVal1    STM_INTERC_STOCK_TRSF.SIS_CHARACTERIZATION_VALUE_1%type;
            lVal2    STM_INTERC_STOCK_TRSF.SIS_CHARACTERIZATION_VALUE_2%type;
            lVal3    STM_INTERC_STOCK_TRSF.SIS_CHARACTERIZATION_VALUE_3%type;
            lVal4    STM_INTERC_STOCK_TRSF.SIS_CHARACTERIZATION_VALUE_4%type;
            lVal5    STM_INTERC_STOCK_TRSF.SIS_CHARACTERIZATION_VALUE_5%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplIntercTrsf.GCO_CHARACTERIZATION_1_ID, 0)
                      , nvl(tplIntercTrsf.GCO_CHARACTERIZATION_2_ID, 0)
                      , nvl(tplIntercTrsf.GCO_CHARACTERIZATION_3_ID, 0)
                      , nvl(tplIntercTrsf.GCO_CHARACTERIZATION_4_ID, 0)
                      , nvl(tplIntercTrsf.GCO_CHARACTERIZATION_5_ID, 0)
                       );

            if tplIntercTrsf.GCO_CHARACTERIZATION_1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplIntercTrsf.GCO_CHARACTERIZATION_2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplIntercTrsf.GCO_CHARACTERIZATION_3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplIntercTrsf.GCO_CHARACTERIZATION_4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplIntercTrsf.GCO_CHARACTERIZATION_5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update STM_INTERC_STOCK_TRSF
               set GCO_CHARACTERIZATION_1_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_1_ID)
                 , GCO_CHARACTERIZATION_2_ID = nvl(lChar2Id, GCO_CHARACTERIZATION_2_ID)
                 , GCO_CHARACTERIZATION_3_ID = nvl(lChar3Id, GCO_CHARACTERIZATION_3_ID)
                 , GCO_CHARACTERIZATION_4_ID = nvl(lChar4Id, GCO_CHARACTERIZATION_4_ID)
                 , GCO_CHARACTERIZATION_5_ID = nvl(lChar5Id, GCO_CHARACTERIZATION_5_ID)
                 , SIS_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, SIS_CHARACTERIZATION_VALUE_1, lVal1)
                 , SIS_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, SIS_CHARACTERIZATION_VALUE_2, lVal2)
                 , SIS_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, SIS_CHARACTERIZATION_VALUE_3, lVal3)
                 , SIS_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, SIS_CHARACTERIZATION_VALUE_4, lVal4)
                 , SIS_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, SIS_CHARACTERIZATION_VALUE_5, lVal5)
             where STM_INTERC_STOCK_TRSF_ID = tplIntercTrsf.STM_INTERC_STOCK_TRSF_ID;
          end;
        end loop;

        lDefltStockNetwork     := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');
        lDefltLocationNetwork  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', lDefltStockNetwork);

        for tplFalLot in lcurFalLot(ltplCharac.GCO_GOOD_ID) loop
          for tplLotDetail in lcurLotDetail(tplFalLot.FAL_LOT_ID, ltplCharac.GCO_GOOD_ID) loop
            declare
              lChar1Id FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
              lChar2Id FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
              lChar3Id FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
              lChar4Id FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
              lChar5Id FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
              lVal1    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
              lVal2    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
              lVal3    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
              lVal4    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
              lVal5    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
            begin
              exit when iCharacterizationId in
                         (nvl(tplLotDetail.GCO_CHARACTERIZATION_ID, 0)
                        , nvl(tplLotDetail.GCO_GCO_CHARACTERIZATION_ID, 0)
                        , nvl(tplLotDetail.GCO2_GCO_CHARACTERIZATION_ID, 0)
                        , nvl(tplLotDetail.GCO3_GCO_CHARACTERIZATION_ID, 0)
                        , nvl(tplLotDetail.GCO4_GCO_CHARACTERIZATION_ID, 0)
                         );
              lAtLeastOneElement  := true;

              if    tplLotDetail.GCO_CHARACTERIZATION_ID is null
                 or tplLotDetail.GCO_CHARACTERIZATION_ID = 0 then
                lChar1Id  := iCharacterizationId;
                lVal1     := iDefValue;
              elsif    tplLotDetail.GCO_GCO_CHARACTERIZATION_ID is null
                    or tplLotDetail.GCO_GCO_CHARACTERIZATION_ID = 0 then
                lChar2Id  := iCharacterizationId;
                lVal2     := iDefValue;
              elsif    tplLotDetail.GCO2_GCO_CHARACTERIZATION_ID is null
                    or tplLotDetail.GCO2_GCO_CHARACTERIZATION_ID = 0 then
                lChar3Id  := iCharacterizationId;
                lVal3     := iDefValue;
              elsif    tplLotDetail.GCO3_GCO_CHARACTERIZATION_ID is null
                    or tplLotDetail.GCO3_GCO_CHARACTERIZATION_ID = 0 then
                lChar4Id  := iCharacterizationId;
                lVal4     := iDefValue;
              elsif    tplLotDetail.GCO4_GCO_CHARACTERIZATION_ID is null
                    or tplLotDetail.GCO4_GCO_CHARACTERIZATION_ID = 0 then
                lChar5Id  := iCharacterizationId;
                lVal5     := iDefValue;
              end if;

              update FAL_LOT_DETAIL
                 set GCO_CHARACTERIZATION_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_ID)
                   , GCO_GCO_CHARACTERIZATION_ID = nvl(lChar2Id, GCO_GCO_CHARACTERIZATION_ID)
                   , GCO2_GCO_CHARACTERIZATION_ID = nvl(lChar3Id, GCO2_GCO_CHARACTERIZATION_ID)
                   , GCO3_GCO_CHARACTERIZATION_ID = nvl(lChar4Id, GCO3_GCO_CHARACTERIZATION_ID)
                   , GCO4_GCO_CHARACTERIZATION_ID = nvl(lChar5Id, GCO4_GCO_CHARACTERIZATION_ID)
                   , FAD_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, FAD_CHARACTERIZATION_VALUE_1, lVal1)
                   , FAD_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, FAD_CHARACTERIZATION_VALUE_2, lVal2)
                   , FAD_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, FAD_CHARACTERIZATION_VALUE_3, lVal3)
                   , FAD_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, FAD_CHARACTERIZATION_VALUE_4, lVal4)
                   , FAD_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, FAD_CHARACTERIZATION_VALUE_5, lVal5)
               where FAL_LOT_DETAIL_ID = tplLotDetail.FAL_LOT_DETAIL_ID;
            end;
          end loop;

          -- Reconstruction des réseaux (FAL_NETWORK_NEED et FAL_NETWORK_SUPPLY)
          if tplFalLot.C_LOT_STATUS in('1', '2') then
            FAL_NETWORK.ReseauApproFAL_Detail_SupprAll(tplFalLot.FAL_LOT_ID, 0);
            FAL_NETWORK.ReseauApproFAL_Detail_Creation(tplFalLot.FAL_LOT_ID, lDefltStockNetwork, lDefltLocationNetwork);
          end if;
        end loop;

        for tplLotDetailHist in lcurLotDetailHist(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
            lChar2Id FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
            lChar3Id FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
            lChar4Id FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
            lChar5Id FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
            lVal1    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
            lVal2    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
            lVal3    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
            lVal4    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
            lVal5    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplLotDetailHist.GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplLotDetailHist.GCO_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplLotDetailHist.GCO2_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplLotDetailHist.GCO3_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplLotDetailHist.GCO4_GCO_CHARACTERIZATION_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplLotDetailHist.GCO_CHARACTERIZATION_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplLotDetailHist.GCO_GCO_CHARACTERIZATION_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplLotDetailHist.GCO2_GCO_CHARACTERIZATION_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplLotDetailHist.GCO3_GCO_CHARACTERIZATION_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplLotDetailHist.GCO4_GCO_CHARACTERIZATION_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update FAL_LOT_DETAIL_HIST
               set GCO_CHARACTERIZATION_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_ID)
                 , GCO_GCO_CHARACTERIZATION_ID = nvl(lChar2Id, GCO_GCO_CHARACTERIZATION_ID)
                 , GCO2_GCO_CHARACTERIZATION_ID = nvl(lChar3Id, GCO2_GCO_CHARACTERIZATION_ID)
                 , GCO3_GCO_CHARACTERIZATION_ID = nvl(lChar4Id, GCO3_GCO_CHARACTERIZATION_ID)
                 , GCO4_GCO_CHARACTERIZATION_ID = nvl(lChar5Id, GCO4_GCO_CHARACTERIZATION_ID)
                 , FAD_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, FAD_CHARACTERIZATION_VALUE_1, lVal1)
                 , FAD_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, FAD_CHARACTERIZATION_VALUE_2, lVal2)
                 , FAD_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, FAD_CHARACTERIZATION_VALUE_3, lVal3)
                 , FAD_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, FAD_CHARACTERIZATION_VALUE_4, lVal4)
                 , FAD_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, FAD_CHARACTERIZATION_VALUE_5, lVal5)
             where FAL_LOT_DETAIL_HIST_ID = tplLotDetailHist.FAL_LOT_DETAIL_HIST_ID;
          end;
        end loop;

-- En fabrication
--   la mise à jour de FAL_NETWORK_NEED et FAL_NETWORK_SUPPLY se fait via la reconstruction des réseaux, effectuée en amont
-- En logistique
--   la mise à jour de FAL_NETWORK_NEED et FAL_NETWORK_SUPPLY se fait automatiquement via des triggers sur DOC_POSITION_DETAIL
--       for tplNetworkSupply in lcurNetworkSupply(ltplCharac.GCO_GOOD_ID) loop
--         declare
--           lChar1Id FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type;
--           lChar2Id FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type;
--           lChar3Id FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type;
--           lChar4Id FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type;
--           lChar5Id FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type;
--           lVal1    FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
--           lVal2    FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
--           lVal3    FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
--           lVal4    FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
--           lVal5    FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
--         begin
--           exit when iCharacterizationId in
--                      (nvl(tplNetworkSupply.GCO_CHARACTERIZATION1_ID,0)
--                     , nvl(tplNetworkSupply.GCO_CHARACTERIZATION2_ID,0)
--                     , nvl(tplNetworkSupply.GCO_CHARACTERIZATION3_ID,0)
--                     , nvl(tplNetworkSupply.GCO_CHARACTERIZATION4_ID,0)
--                     , nvl(tplNetworkSupply.GCO_CHARACTERIZATION5_ID,0)
--                      );
--           lAtLeastOneElement  := true;
--
--           if tplNetworkSupply.GCO_CHARACTERIZATION1_ID is null then
--             lChar1Id  := iCharacterizationId;
--             lVal1     := iDefValue;
--           elsif tplNetworkSupply.GCO_CHARACTERIZATION2_ID is null then
--             lChar2Id  := iCharacterizationId;
--             lVal2     := iDefValue;
--           elsif tplNetworkSupply.GCO_CHARACTERIZATION3_ID is null then
--             lChar3Id  := iCharacterizationId;
--             lVal3     := iDefValue;
--           elsif tplNetworkSupply.GCO_CHARACTERIZATION4_ID is null then
--             lChar4Id  := iCharacterizationId;
--             lVal4     := iDefValue;
--           elsif tplNetworkSupply.GCO_CHARACTERIZATION5_ID is null then
--             lChar5Id  := iCharacterizationId;
--             lVal5     := iDefValue;
--           end if;
--
--           update FAL_NETWORK_SUPPLY
--              set GCO_CHARACTERIZATION1_ID = nvl(lChar1Id, GCO_CHARACTERIZATION1_ID)
--                , GCO_CHARACTERIZATION2_ID = nvl(lChar2Id, GCO_CHARACTERIZATION2_ID)
--                , GCO_CHARACTERIZATION3_ID = nvl(lChar3Id, GCO_CHARACTERIZATION3_ID)
--                , GCO_CHARACTERIZATION4_ID = nvl(lChar4Id, GCO_CHARACTERIZATION4_ID)
--                , GCO_CHARACTERIZATION5_ID = nvl(lChar5Id, GCO_CHARACTERIZATION5_ID)
--                , FAN_CHAR_VALUE1 = decode(lChar1Id, null, FAN_CHAR_VALUE1, lVal1)
--                , FAN_CHAR_VALUE2 = decode(lChar2Id, null, FAN_CHAR_VALUE2, lVal2)
--                , FAN_CHAR_VALUE3 = decode(lChar3Id, null, FAN_CHAR_VALUE3, lVal3)
--                , FAN_CHAR_VALUE4 = decode(lChar4Id, null, FAN_CHAR_VALUE4, lVal4)
--                , FAN_CHAR_VALUE5 = decode(lChar5Id, null, FAN_CHAR_VALUE5, lVal5)
--            where FAL_NETWORK_SUPPLY_ID = tplNetworkSupply.FAL_NETWORK_SUPPLY_ID;
--         end;
--       end loop;
--
--       for tplNetworkNeed in lcurNetworkNeed(ltplCharac.GCO_GOOD_ID) loop
--         declare
--           lChar1Id FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type;
--           lChar2Id FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type;
--           lChar3Id FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type;
--           lChar4Id FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type;
--           lChar5Id FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type;
--           lVal1    FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
--           lVal2    FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
--           lVal3    FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
--           lVal4    FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
--           lVal5    FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
--         begin
--           exit when iCharacterizationId in
--                      (nvl(tplNetworkNeed.GCO_CHARACTERIZATION1_ID,0)
--                     , nvl(tplNetworkNeed.GCO_CHARACTERIZATION2_ID,0)
--                     , nvl(tplNetworkNeed.GCO_CHARACTERIZATION3_ID,0)
--                     , nvl(tplNetworkNeed.GCO_CHARACTERIZATION4_ID,0)
--                     , nvl(tplNetworkNeed.GCO_CHARACTERIZATION5_ID,0)
--                      );
--           lAtLeastOneElement  := true;
--
--           if tplNetworkNeed.GCO_CHARACTERIZATION1_ID is null then
--             lChar1Id  := iCharacterizationId;
--             lVal1     := iDefValue;
--           elsif tplNetworkNeed.GCO_CHARACTERIZATION2_ID is null then
--             lChar2Id  := iCharacterizationId;
--             lVal2     := iDefValue;
--           elsif tplNetworkNeed.GCO_CHARACTERIZATION3_ID is null then
--             lChar3Id  := iCharacterizationId;
--             lVal3     := iDefValue;
--           elsif tplNetworkNeed.GCO_CHARACTERIZATION4_ID is null then
--             lChar4Id  := iCharacterizationId;
--             lVal4     := iDefValue;
--           elsif tplNetworkNeed.GCO_CHARACTERIZATION5_ID is null then
--             lChar5Id  := iCharacterizationId;
--             lVal5     := iDefValue;
--           end if;
--
--           update FAL_NETWORK_NEED
--              set GCO_CHARACTERIZATION1_ID = nvl(lChar1Id, GCO_CHARACTERIZATION1_ID)
--                , GCO_CHARACTERIZATION2_ID = nvl(lChar2Id, GCO_CHARACTERIZATION2_ID)
--                , GCO_CHARACTERIZATION3_ID = nvl(lChar3Id, GCO_CHARACTERIZATION3_ID)
--                , GCO_CHARACTERIZATION4_ID = nvl(lChar4Id, GCO_CHARACTERIZATION4_ID)
--                , GCO_CHARACTERIZATION5_ID = nvl(lChar5Id, GCO_CHARACTERIZATION5_ID)
--                , FAN_CHAR_VALUE1 = decode(lChar1Id, null, FAN_CHAR_VALUE1, lVal1)
--                , FAN_CHAR_VALUE2 = decode(lChar2Id, null, FAN_CHAR_VALUE2, lVal2)
--                , FAN_CHAR_VALUE3 = decode(lChar3Id, null, FAN_CHAR_VALUE3, lVal3)
--                , FAN_CHAR_VALUE4 = decode(lChar4Id, null, FAN_CHAR_VALUE4, lVal4)
--                , FAN_CHAR_VALUE5 = decode(lChar5Id, null, FAN_CHAR_VALUE5, lVal5)
--            where FAL_NETWORK_NEED_ID = tplNetworkNeed.FAL_NETWORK_NEED_ID;
--         end;
--       end loop;
        for tplFalOutCBarCode in lcurFalOutCBarCode(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id FAL_OUT_COMPO_BARCODE.GCO_CHARACTERIZATION_ID%type;
            lChar2Id FAL_OUT_COMPO_BARCODE.GCO_GCO_CHARACTERIZATION_ID%type;
            lChar3Id FAL_OUT_COMPO_BARCODE.GCO2_GCO_CHARACTERIZATION_ID%type;
            lChar4Id FAL_OUT_COMPO_BARCODE.GCO3_GCO_CHARACTERIZATION_ID%type;
            lChar5Id FAL_OUT_COMPO_BARCODE.GCO4_GCO_CHARACTERIZATION_ID%type;
            lVal1    FAL_OUT_COMPO_BARCODE.FOC_CHARACTERIZATION_VALUE_1%type;
            lVal2    FAL_OUT_COMPO_BARCODE.FOC_CHARACTERIZATION_VALUE_1%type;
            lVal3    FAL_OUT_COMPO_BARCODE.FOC_CHARACTERIZATION_VALUE_1%type;
            lVal4    FAL_OUT_COMPO_BARCODE.FOC_CHARACTERIZATION_VALUE_1%type;
            lVal5    FAL_OUT_COMPO_BARCODE.FOC_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplFalOutCBarCode.GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFalOutCBarCode.GCO_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFalOutCBarCode.GCO2_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFalOutCBarCode.GCO3_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFalOutCBarCode.GCO4_GCO_CHARACTERIZATION_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplFalOutCBarCode.GCO_CHARACTERIZATION_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplFalOutCBarCode.GCO_GCO_CHARACTERIZATION_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplFalOutCBarCode.GCO2_GCO_CHARACTERIZATION_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplFalOutCBarCode.GCO3_GCO_CHARACTERIZATION_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplFalOutCBarCode.GCO4_GCO_CHARACTERIZATION_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update FAL_OUT_COMPO_BARCODE
               set GCO_CHARACTERIZATION_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_ID)
                 , GCO_GCO_CHARACTERIZATION_ID = nvl(lChar2Id, GCO_GCO_CHARACTERIZATION_ID)
                 , GCO2_GCO_CHARACTERIZATION_ID = nvl(lChar3Id, GCO2_GCO_CHARACTERIZATION_ID)
                 , GCO3_GCO_CHARACTERIZATION_ID = nvl(lChar4Id, GCO3_GCO_CHARACTERIZATION_ID)
                 , GCO4_GCO_CHARACTERIZATION_ID = nvl(lChar5Id, GCO4_GCO_CHARACTERIZATION_ID)
                 , FOC_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, FOC_CHARACTERIZATION_VALUE_1, lVal1)
                 , FOC_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, FOC_CHARACTERIZATION_VALUE_2, lVal2)
                 , FOC_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, FOC_CHARACTERIZATION_VALUE_3, lVal3)
                 , FOC_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, FOC_CHARACTERIZATION_VALUE_4, lVal4)
                 , FOC_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, FOC_CHARACTERIZATION_VALUE_5, lVal5)
             where FAL_OUT_COMPO_BARCODE_ID = tplFalOutCBarCode.FAL_OUT_COMPO_BARCODE_ID;
          end;
        end loop;

        for tplFactoryIn in lcurFactoryIn(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
            lChar2Id FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
            lChar3Id FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
            lChar4Id FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
            lChar5Id FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
            lVal1    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lVal2    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lVal3    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lVal4    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lVal5    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lPiece   FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lSet     FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lVersion FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lChrono  FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lStd1    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lStd2    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lStd3    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lStd4    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
            lStd5    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplFactoryIn.GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFactoryIn.GCO_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFactoryIn.GCO2_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFactoryIn.GCO3_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFactoryIn.GCO4_GCO_CHARACTERIZATION_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplFactoryIn.GCO_CHARACTERIZATION_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplFactoryIn.GCO_GCO_CHARACTERIZATION_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplFactoryIn.GCO2_GCO_CHARACTERIZATION_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplFactoryIn.GCO3_GCO_CHARACTERIZATION_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplFactoryIn.GCO4_GCO_CHARACTERIZATION_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            -- dénormalisation des caractérisations
            GCO_LIB_CHARACTERIZATION.ClassifyCharacterizations(nvl(lChar1Id, tplFactoryIn.GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar2Id, tplFactoryIn.GCO_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar3Id, tplFactoryIn.GCO2_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar4Id, tplFactoryIn.GCO3_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar5Id, tplFactoryIn.GCO4_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lVal1, tplFactoryIn.IN_CHARACTERIZATION_VALUE_1)
                                                             , nvl(lVal2, tplFactoryIn.IN_CHARACTERIZATION_VALUE_2)
                                                             , nvl(lVal3, tplFactoryIn.IN_CHARACTERIZATION_VALUE_3)
                                                             , nvl(lVal4, tplFactoryIn.IN_CHARACTERIZATION_VALUE_4)
                                                             , nvl(lVal5, tplFactoryIn.IN_CHARACTERIZATION_VALUE_5)
                                                             , lPiece
                                                             , lSet
                                                             , lVersion
                                                             , lChrono
                                                             , lStd1
                                                             , lStd2
                                                             , lStd3
                                                             , lStd4
                                                             , lStd5
                                                              );

            update FAL_FACTORY_IN
               set GCO_CHARACTERIZATION_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_ID)
                 , GCO_GCO_CHARACTERIZATION_ID = nvl(lChar2Id, GCO_GCO_CHARACTERIZATION_ID)
                 , GCO2_GCO_CHARACTERIZATION_ID = nvl(lChar3Id, GCO2_GCO_CHARACTERIZATION_ID)
                 , GCO3_GCO_CHARACTERIZATION_ID = nvl(lChar4Id, GCO3_GCO_CHARACTERIZATION_ID)
                 , GCO4_GCO_CHARACTERIZATION_ID = nvl(lChar5Id, GCO4_GCO_CHARACTERIZATION_ID)
                 , IN_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, IN_CHARACTERIZATION_VALUE_1, lVal1)
                 , IN_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, IN_CHARACTERIZATION_VALUE_2, lVal2)
                 , IN_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, IN_CHARACTERIZATION_VALUE_3, lVal3)
                 , IN_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, IN_CHARACTERIZATION_VALUE_4, lVal4)
                 , IN_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, IN_CHARACTERIZATION_VALUE_5, lVal5)
                 , IN_VERSION = lVersion
                 , IN_LOT = lSet
                 , IN_PIECE = lPiece
                 , IN_CHRONOLOGY = lChrono
                 , IN_STD_CHAR_1 = lStd1
                 , IN_STD_CHAR_2 = lStd2
                 , IN_STD_CHAR_3 = lStd3
                 , IN_STD_CHAR_4 = lStd4
                 , IN_STD_CHAR_5 = lStd5
             where FAL_FACTORY_IN_ID = tplFactoryIn.FAL_FACTORY_IN_ID;
          end;
        end loop;

        for tplFactoryInHist in lcurFactoryInHist(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id FAL_FACTORY_IN_HIST.GCO_CHARACTERIZATION_ID%type;
            lChar2Id FAL_FACTORY_IN_HIST.GCO_CHARACTERIZATION_ID%type;
            lChar3Id FAL_FACTORY_IN_HIST.GCO_CHARACTERIZATION_ID%type;
            lChar4Id FAL_FACTORY_IN_HIST.GCO_CHARACTERIZATION_ID%type;
            lChar5Id FAL_FACTORY_IN_HIST.GCO_CHARACTERIZATION_ID%type;
            lVal1    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lVal2    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lVal3    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lVal4    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lVal5    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lPiece   FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lSet     FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lVersion FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lChrono  FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lStd1    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lStd2    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lStd3    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lStd4    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
            lStd5    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplFactoryInHist.GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFactoryInHist.GCO_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFactoryInHist.GCO2_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFactoryInHist.GCO3_GCO_CHARACTERIZATION_ID, 0)
                      , nvl(tplFactoryInHist.GCO4_GCO_CHARACTERIZATION_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplFactoryInHist.GCO_CHARACTERIZATION_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplFactoryInHist.GCO_GCO_CHARACTERIZATION_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplFactoryInHist.GCO2_GCO_CHARACTERIZATION_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplFactoryInHist.GCO3_GCO_CHARACTERIZATION_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplFactoryInHist.GCO4_GCO_CHARACTERIZATION_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            -- dénormalisation des caractérisations
            GCO_LIB_CHARACTERIZATION.ClassifyCharacterizations(nvl(lChar1Id, tplFactoryInHist.GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar2Id, tplFactoryInHist.GCO_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar3Id, tplFactoryInHist.GCO2_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar4Id, tplFactoryInHist.GCO3_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lChar5Id, tplFactoryInHist.GCO4_GCO_CHARACTERIZATION_ID)
                                                             , nvl(lVal1, tplFactoryInHist.IN_CHARACTERIZATION_VALUE_1)
                                                             , nvl(lVal2, tplFactoryInHist.IN_CHARACTERIZATION_VALUE_2)
                                                             , nvl(lVal3, tplFactoryInHist.IN_CHARACTERIZATION_VALUE_3)
                                                             , nvl(lVal4, tplFactoryInHist.IN_CHARACTERIZATION_VALUE_4)
                                                             , nvl(lVal5, tplFactoryInHist.IN_CHARACTERIZATION_VALUE_5)
                                                             , lPiece
                                                             , lSet
                                                             , lVersion
                                                             , lChrono
                                                             , lStd1
                                                             , lStd2
                                                             , lStd3
                                                             , lStd4
                                                             , lStd5
                                                              );

            update FAL_FACTORY_IN_HIST
               set GCO_CHARACTERIZATION_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_ID)
                 , GCO_GCO_CHARACTERIZATION_ID = nvl(lChar2Id, GCO_GCO_CHARACTERIZATION_ID)
                 , GCO2_GCO_CHARACTERIZATION_ID = nvl(lChar3Id, GCO2_GCO_CHARACTERIZATION_ID)
                 , GCO3_GCO_CHARACTERIZATION_ID = nvl(lChar4Id, GCO3_GCO_CHARACTERIZATION_ID)
                 , GCO4_GCO_CHARACTERIZATION_ID = nvl(lChar5Id, GCO4_GCO_CHARACTERIZATION_ID)
                 , IN_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, IN_CHARACTERIZATION_VALUE_1, lVal1)
                 , IN_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, IN_CHARACTERIZATION_VALUE_2, lVal2)
                 , IN_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, IN_CHARACTERIZATION_VALUE_3, lVal3)
                 , IN_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, IN_CHARACTERIZATION_VALUE_4, lVal4)
                 , IN_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, IN_CHARACTERIZATION_VALUE_5, lVal5)
                 , IN_VERSION = lVersion
                 , IN_LOT = lSet
                 , IN_PIECE = lPiece
                 , IN_CHRONOLOGY = lChrono
                 , IN_STD_CHAR_1 = lStd1
                 , IN_STD_CHAR_2 = lStd2
                 , IN_STD_CHAR_3 = lStd3
                 , IN_STD_CHAR_4 = lStd4
                 , IN_STD_CHAR_5 = lStd5
             where FAL_FACTORY_IN_HIST_ID = tplFactoryInHist.FAL_FACTORY_IN_HIST_ID;
          end;
        end loop;

        for tplFactoryOut in lcurFactoryOut(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id FAL_FACTORY_OUT.GCO_CHARACTERIZATION1_ID%type;
            lChar2Id FAL_FACTORY_OUT.GCO_CHARACTERIZATION2_ID%type;
            lChar3Id FAL_FACTORY_OUT.GCO_CHARACTERIZATION3_ID%type;
            lChar4Id FAL_FACTORY_OUT.GCO_CHARACTERIZATION4_ID%type;
            lChar5Id FAL_FACTORY_OUT.GCO_CHARACTERIZATION5_ID%type;
            lVal1    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lVal2    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lVal3    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lVal4    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lVal5    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lPiece   FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lSet     FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lVersion FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lChrono  FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lStd1    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lStd2    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lStd3    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lStd4    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
            lStd5    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplFactoryOut.GCO_CHARACTERIZATION1_ID, 0)
                      , nvl(tplFactoryOut.GCO_CHARACTERIZATION2_ID, 0)
                      , nvl(tplFactoryOut.GCO_CHARACTERIZATION3_ID, 0)
                      , nvl(tplFactoryOut.GCO_CHARACTERIZATION4_ID, 0)
                      , nvl(tplFactoryOut.GCO_CHARACTERIZATION5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplFactoryOut.GCO_CHARACTERIZATION1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplFactoryOut.GCO_CHARACTERIZATION2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplFactoryOut.GCO_CHARACTERIZATION3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplFactoryOut.GCO_CHARACTERIZATION4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplFactoryOut.GCO_CHARACTERIZATION5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            -- dénormalisation des caractérisations
            GCO_LIB_CHARACTERIZATION.ClassifyCharacterizations(nvl(lChar1Id, tplFactoryOut.GCO_CHARACTERIZATION1_ID)
                                                             , nvl(lChar2Id, tplFactoryOut.GCO_CHARACTERIZATION2_ID)
                                                             , nvl(lChar3Id, tplFactoryOut.GCO_CHARACTERIZATION3_ID)
                                                             , nvl(lChar4Id, tplFactoryOut.GCO_CHARACTERIZATION4_ID)
                                                             , nvl(lChar5Id, tplFactoryOut.GCO_CHARACTERIZATION5_ID)
                                                             , nvl(lVal1, tplFactoryOut.OUT_CHARACTERIZATION_VALUE_1)
                                                             , nvl(lVal2, tplFactoryOut.OUT_CHARACTERIZATION_VALUE_2)
                                                             , nvl(lVal3, tplFactoryOut.OUT_CHARACTERIZATION_VALUE_3)
                                                             , nvl(lVal4, tplFactoryOut.OUT_CHARACTERIZATION_VALUE_4)
                                                             , nvl(lVal5, tplFactoryOut.OUT_CHARACTERIZATION_VALUE_5)
                                                             , lPiece
                                                             , lSet
                                                             , lVersion
                                                             , lChrono
                                                             , lStd1
                                                             , lStd2
                                                             , lStd3
                                                             , lStd4
                                                             , lStd5
                                                              );

            update FAL_FACTORY_OUT
               set GCO_CHARACTERIZATION1_ID = nvl(lChar1Id, GCO_CHARACTERIZATION1_ID)
                 , GCO_CHARACTERIZATION2_ID = nvl(lChar2Id, GCO_CHARACTERIZATION2_ID)
                 , GCO_CHARACTERIZATION3_ID = nvl(lChar3Id, GCO_CHARACTERIZATION3_ID)
                 , GCO_CHARACTERIZATION4_ID = nvl(lChar4Id, GCO_CHARACTERIZATION4_ID)
                 , GCO_CHARACTERIZATION5_ID = nvl(lChar5Id, GCO_CHARACTERIZATION5_ID)
                 , OUT_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, OUT_CHARACTERIZATION_VALUE_1, lVal1)
                 , OUT_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, OUT_CHARACTERIZATION_VALUE_2, lVal2)
                 , OUT_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, OUT_CHARACTERIZATION_VALUE_3, lVal3)
                 , OUT_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, OUT_CHARACTERIZATION_VALUE_4, lVal4)
                 , OUT_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, OUT_CHARACTERIZATION_VALUE_5, lVal5)
                 , OUT_VERSION = lVersion
                 , OUT_LOT = lSet
                 , OUT_PIECE = lPiece
                 , OUT_CHRONOLOGY = lChrono
                 , OUT_STD_CHAR_1 = lStd1
                 , OUT_STD_CHAR_2 = lStd2
                 , OUT_STD_CHAR_3 = lStd3
                 , OUT_STD_CHAR_4 = lStd4
                 , OUT_STD_CHAR_5 = lStd5
             where FAL_FACTORY_OUT_ID = tplFactoryOut.FAL_FACTORY_OUT_ID;
          end;
        end loop;

        for tplFalDocConsult in lcurFalDocConsult(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id FAL_DOC_CONSULT.GCO_CHARACTERIZATION1_ID%type;
            lChar2Id FAL_DOC_CONSULT.GCO_CHARACTERIZATION1_ID%type;
            lChar3Id FAL_DOC_CONSULT.GCO_CHARACTERIZATION1_ID%type;
            lChar4Id FAL_DOC_CONSULT.GCO_CHARACTERIZATION1_ID%type;
            lChar5Id FAL_DOC_CONSULT.GCO_CHARACTERIZATION1_ID%type;
            lVal1    FAL_DOC_CONSULT.FDC_CHARACTERIZATION_VALUE_1%type;
            lVal2    FAL_DOC_CONSULT.FDC_CHARACTERIZATION_VALUE_1%type;
            lVal3    FAL_DOC_CONSULT.FDC_CHARACTERIZATION_VALUE_1%type;
            lVal4    FAL_DOC_CONSULT.FDC_CHARACTERIZATION_VALUE_1%type;
            lVal5    FAL_DOC_CONSULT.FDC_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplFalDocConsult.GCO_CHARACTERIZATION1_ID, 0)
                      , nvl(tplFalDocConsult.GCO_CHARACTERIZATION2_ID, 0)
                      , nvl(tplFalDocConsult.GCO_CHARACTERIZATION3_ID, 0)
                      , nvl(tplFalDocConsult.GCO_CHARACTERIZATION4_ID, 0)
                      , nvl(tplFalDocConsult.GCO_CHARACTERIZATION5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplFalDocConsult.GCO_CHARACTERIZATION1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplFalDocConsult.GCO_CHARACTERIZATION2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplFalDocConsult.GCO_CHARACTERIZATION3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplFalDocConsult.GCO_CHARACTERIZATION4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplFalDocConsult.GCO_CHARACTERIZATION5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update FAL_DOC_CONSULT
               set GCO_CHARACTERIZATION1_ID = nvl(lChar1Id, GCO_CHARACTERIZATION1_ID)
                 , GCO_CHARACTERIZATION2_ID = nvl(lChar2Id, GCO_CHARACTERIZATION2_ID)
                 , GCO_CHARACTERIZATION3_ID = nvl(lChar3Id, GCO_CHARACTERIZATION3_ID)
                 , GCO_CHARACTERIZATION4_ID = nvl(lChar4Id, GCO_CHARACTERIZATION4_ID)
                 , GCO_CHARACTERIZATION5_ID = nvl(lChar5Id, GCO_CHARACTERIZATION5_ID)
                 , FDC_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, FDC_CHARACTERIZATION_VALUE_1, lVal1)
                 , FDC_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, FDC_CHARACTERIZATION_VALUE_2, lVal2)
                 , FDC_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, FDC_CHARACTERIZATION_VALUE_3, lVal3)
                 , FDC_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, FDC_CHARACTERIZATION_VALUE_4, lVal4)
                 , FDC_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, FDC_CHARACTERIZATION_VALUE_5, lVal5)
             where FAL_DOC_CONSULT_ID = tplFalDocConsult.FAL_DOC_CONSULT_ID;
          end;
        end loop;

        for tplFalDocConsultHist in lcurFalDocConsultHist(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id FAL_DOC_CONSULT_HIST.GCO_CHARACTERIZATION1_ID%type;
            lChar2Id FAL_DOC_CONSULT_HIST.GCO_CHARACTERIZATION1_ID%type;
            lChar3Id FAL_DOC_CONSULT_HIST.GCO_CHARACTERIZATION1_ID%type;
            lChar4Id FAL_DOC_CONSULT_HIST.GCO_CHARACTERIZATION1_ID%type;
            lChar5Id FAL_DOC_CONSULT_HIST.GCO_CHARACTERIZATION1_ID%type;
            lVal1    FAL_DOC_CONSULT_HIST.FDC_CHARACTERIZATION_VALUE_1%type;
            lVal2    FAL_DOC_CONSULT_HIST.FDC_CHARACTERIZATION_VALUE_1%type;
            lVal3    FAL_DOC_CONSULT_HIST.FDC_CHARACTERIZATION_VALUE_1%type;
            lVal4    FAL_DOC_CONSULT_HIST.FDC_CHARACTERIZATION_VALUE_1%type;
            lVal5    FAL_DOC_CONSULT_HIST.FDC_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplFalDocConsultHist.GCO_CHARACTERIZATION1_ID, 0)
                      , nvl(tplFalDocConsultHist.GCO_CHARACTERIZATION2_ID, 0)
                      , nvl(tplFalDocConsultHist.GCO_CHARACTERIZATION3_ID, 0)
                      , nvl(tplFalDocConsultHist.GCO_CHARACTERIZATION4_ID, 0)
                      , nvl(tplFalDocConsultHist.GCO_CHARACTERIZATION5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplFalDocConsultHist.GCO_CHARACTERIZATION1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplFalDocConsultHist.GCO_CHARACTERIZATION2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplFalDocConsultHist.GCO_CHARACTERIZATION3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplFalDocConsultHist.GCO_CHARACTERIZATION4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplFalDocConsultHist.GCO_CHARACTERIZATION5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update FAL_DOC_CONSULT_HIST
               set GCO_CHARACTERIZATION1_ID = nvl(lChar1Id, GCO_CHARACTERIZATION1_ID)
                 , GCO_CHARACTERIZATION2_ID = nvl(lChar2Id, GCO_CHARACTERIZATION2_ID)
                 , GCO_CHARACTERIZATION3_ID = nvl(lChar3Id, GCO_CHARACTERIZATION3_ID)
                 , GCO_CHARACTERIZATION4_ID = nvl(lChar4Id, GCO_CHARACTERIZATION4_ID)
                 , GCO_CHARACTERIZATION5_ID = nvl(lChar5Id, GCO_CHARACTERIZATION5_ID)
                 , FDC_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, FDC_CHARACTERIZATION_VALUE_1, lVal1)
                 , FDC_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, FDC_CHARACTERIZATION_VALUE_2, lVal2)
                 , FDC_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, FDC_CHARACTERIZATION_VALUE_3, lVal3)
                 , FDC_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, FDC_CHARACTERIZATION_VALUE_4, lVal4)
                 , FDC_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, FDC_CHARACTERIZATION_VALUE_5, lVal5)
             where FAL_DOC_CONSULT_HIST_ID = tplFalDocConsultHist.FAL_DOC_CONSULT_HIST_ID;
          end;
        end loop;

        for tplFalDocProp in lcurFalDocProp(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar2Id FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar3Id FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar4Id FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar5Id FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
            lVal1    FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
            lVal2    FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
            lVal3    FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
            lVal4    FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
            lVal5    FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplFalDocProp.GCO_CHARACTERIZATION1_ID, 0)
                      , nvl(tplFalDocProp.GCO_CHARACTERIZATION2_ID, 0)
                      , nvl(tplFalDocProp.GCO_CHARACTERIZATION3_ID, 0)
                      , nvl(tplFalDocProp.GCO_CHARACTERIZATION4_ID, 0)
                      , nvl(tplFalDocProp.GCO_CHARACTERIZATION5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplFalDocProp.GCO_CHARACTERIZATION1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplFalDocProp.GCO_CHARACTERIZATION2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplFalDocProp.GCO_CHARACTERIZATION3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplFalDocProp.GCO_CHARACTERIZATION4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplFalDocProp.GCO_CHARACTERIZATION5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update FAL_DOC_PROP
               set GCO_CHARACTERIZATION1_ID = nvl(lChar1Id, GCO_CHARACTERIZATION1_ID)
                 , GCO_CHARACTERIZATION2_ID = nvl(lChar2Id, GCO_CHARACTERIZATION2_ID)
                 , GCO_CHARACTERIZATION3_ID = nvl(lChar3Id, GCO_CHARACTERIZATION3_ID)
                 , GCO_CHARACTERIZATION4_ID = nvl(lChar4Id, GCO_CHARACTERIZATION4_ID)
                 , GCO_CHARACTERIZATION5_ID = nvl(lChar5Id, GCO_CHARACTERIZATION5_ID)
                 , FDP_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, FDP_CHARACTERIZATION_VALUE_1, lVal1)
                 , FDP_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, FDP_CHARACTERIZATION_VALUE_2, lVal2)
                 , FDP_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, FDP_CHARACTERIZATION_VALUE_3, lVal3)
                 , FDP_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, FDP_CHARACTERIZATION_VALUE_4, lVal4)
                 , FDP_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, FDP_CHARACTERIZATION_VALUE_5, lVal5)
             where FAL_DOC_PROP_ID = tplFalDocProp.FAL_DOC_PROP_ID;
          end;
        end loop;

        for tplFalDocProp in lcurFalDocProp(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar2Id FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar3Id FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar4Id FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar5Id FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
            lVal1    FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
            lVal2    FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
            lVal3    FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
            lVal4    FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
            lVal5    FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplFalDocProp.GCO_CHARACTERIZATION1_ID, 0)
                      , nvl(tplFalDocProp.GCO_CHARACTERIZATION2_ID, 0)
                      , nvl(tplFalDocProp.GCO_CHARACTERIZATION3_ID, 0)
                      , nvl(tplFalDocProp.GCO_CHARACTERIZATION4_ID, 0)
                      , nvl(tplFalDocProp.GCO_CHARACTERIZATION5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplFalDocProp.GCO_CHARACTERIZATION1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplFalDocProp.GCO_CHARACTERIZATION2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplFalDocProp.GCO_CHARACTERIZATION3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplFalDocProp.GCO_CHARACTERIZATION4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplFalDocProp.GCO_CHARACTERIZATION5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update FAL_DOC_PROP
               set GCO_CHARACTERIZATION1_ID = nvl(lChar1Id, GCO_CHARACTERIZATION1_ID)
                 , GCO_CHARACTERIZATION2_ID = nvl(lChar2Id, GCO_CHARACTERIZATION2_ID)
                 , GCO_CHARACTERIZATION3_ID = nvl(lChar3Id, GCO_CHARACTERIZATION3_ID)
                 , GCO_CHARACTERIZATION4_ID = nvl(lChar4Id, GCO_CHARACTERIZATION4_ID)
                 , GCO_CHARACTERIZATION5_ID = nvl(lChar5Id, GCO_CHARACTERIZATION5_ID)
                 , FDP_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, FDP_CHARACTERIZATION_VALUE_1, lVal1)
                 , FDP_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, FDP_CHARACTERIZATION_VALUE_2, lVal2)
                 , FDP_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, FDP_CHARACTERIZATION_VALUE_3, lVal3)
                 , FDP_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, FDP_CHARACTERIZATION_VALUE_4, lVal4)
                 , FDP_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, FDP_CHARACTERIZATION_VALUE_5, lVal5)
             where FAL_DOC_PROP_ID = tplFalDocProp.FAL_DOC_PROP_ID;
          end;
        end loop;

        for tplFalLotProp in lcurFalLotProp(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id FAL_LOT_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar2Id FAL_LOT_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar3Id FAL_LOT_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar4Id FAL_LOT_PROP.GCO_CHARACTERIZATION1_ID%type;
            lChar5Id FAL_LOT_PROP.GCO_CHARACTERIZATION1_ID%type;
            lVal1    FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1%type;
            lVal2    FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_2%type;
            lVal3    FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_3%type;
            lVal4    FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_4%type;
            lVal5    FAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_5%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplFalLotProp.GCO_CHARACTERIZATION1_ID, 0)
                      , nvl(tplFalLotProp.GCO_CHARACTERIZATION2_ID, 0)
                      , nvl(tplFalLotProp.GCO_CHARACTERIZATION3_ID, 0)
                      , nvl(tplFalLotProp.GCO_CHARACTERIZATION4_ID, 0)
                      , nvl(tplFalLotProp.GCO_CHARACTERIZATION5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplFalLotProp.GCO_CHARACTERIZATION1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplFalLotProp.GCO_CHARACTERIZATION2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplFalLotProp.GCO_CHARACTERIZATION3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplFalLotProp.GCO_CHARACTERIZATION4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplFalLotProp.GCO_CHARACTERIZATION5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update FAL_LOT_PROP
               set GCO_CHARACTERIZATION1_ID = nvl(lChar1Id, GCO_CHARACTERIZATION1_ID)
                 , GCO_CHARACTERIZATION2_ID = nvl(lChar2Id, GCO_CHARACTERIZATION2_ID)
                 , GCO_CHARACTERIZATION3_ID = nvl(lChar3Id, GCO_CHARACTERIZATION3_ID)
                 , GCO_CHARACTERIZATION4_ID = nvl(lChar4Id, GCO_CHARACTERIZATION4_ID)
                 , GCO_CHARACTERIZATION5_ID = nvl(lChar5Id, GCO_CHARACTERIZATION5_ID)
                 , FAD_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, FAD_CHARACTERIZATION_VALUE_1, lVal1)
                 , FAD_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, FAD_CHARACTERIZATION_VALUE_2, lVal2)
                 , FAD_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, FAD_CHARACTERIZATION_VALUE_3, lVal3)
                 , FAD_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, FAD_CHARACTERIZATION_VALUE_4, lVal4)
                 , FAD_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, FAD_CHARACTERIZATION_VALUE_5, lVal5)
             where FAL_LOT_PROP_ID = tplFalLotProp.FAL_LOT_PROP_ID;
          end;
        end loop;

        for tplAsaRecord_Repair in lcurAsaRecordRepair(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar2Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar3Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar4Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar5Id ASA_RECORD.GCO_CHAR1_ID%type;
            lVal1    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal2    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal3    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal4    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal5    ASA_RECORD.ARE_CHAR1_VALUE%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplAsaRecord_Repair.GCO_CHAR1_ID, 0)
                      , nvl(tplAsaRecord_Repair.GCO_CHAR2_ID, 0)
                      , nvl(tplAsaRecord_Repair.GCO_CHAR3_ID, 0)
                      , nvl(tplAsaRecord_Repair.GCO_CHAR4_ID, 0)
                      , nvl(tplAsaRecord_Repair.GCO_CHAR5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplAsaRecord_Repair.GCO_CHAR1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplAsaRecord_Repair.GCO_CHAR2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplAsaRecord_Repair.GCO_CHAR3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplAsaRecord_Repair.GCO_CHAR4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplAsaRecord_Repair.GCO_CHAR5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update ASA_RECORD
               set GCO_CHAR1_ID = nvl(lChar1Id, GCO_CHAR1_ID)
                 , GCO_CHAR2_ID = nvl(lChar2Id, GCO_CHAR2_ID)
                 , GCO_CHAR3_ID = nvl(lChar3Id, GCO_CHAR3_ID)
                 , GCO_CHAR4_ID = nvl(lChar4Id, GCO_CHAR4_ID)
                 , GCO_CHAR5_ID = nvl(lChar5Id, GCO_CHAR5_ID)
                 , ARE_CHAR1_VALUE = decode(lChar1Id, null, ARE_CHAR1_VALUE, lVal1)
                 , ARE_CHAR2_VALUE = decode(lChar2Id, null, ARE_CHAR2_VALUE, lVal2)
                 , ARE_CHAR3_VALUE = decode(lChar3Id, null, ARE_CHAR3_VALUE, lVal3)
                 , ARE_CHAR4_VALUE = decode(lChar4Id, null, ARE_CHAR4_VALUE, lVal4)
                 , ARE_CHAR5_VALUE = decode(lChar5Id, null, ARE_CHAR5_VALUE, lVal5)
             where ASA_RECORD_ID = tplAsaRecord_Repair.ASA_RECORD_ID;
          end;
        end loop;

        for tplAsaRecord_Exchange in lcurAsaRecordExchange(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar2Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar3Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar4Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar5Id ASA_RECORD.GCO_CHAR1_ID%type;
            lVal1    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal2    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal3    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal4    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal5    ASA_RECORD.ARE_CHAR1_VALUE%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplAsaRecord_Exchange.GCO_EXCH_CHAR1_ID, 0)
                      , nvl(tplAsaRecord_Exchange.GCO_EXCH_CHAR2_ID, 0)
                      , nvl(tplAsaRecord_Exchange.GCO_EXCH_CHAR3_ID, 0)
                      , nvl(tplAsaRecord_Exchange.GCO_EXCH_CHAR4_ID, 0)
                      , nvl(tplAsaRecord_Exchange.GCO_EXCH_CHAR5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplAsaRecord_Exchange.GCO_EXCH_CHAR1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplAsaRecord_Exchange.GCO_EXCH_CHAR2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplAsaRecord_Exchange.GCO_EXCH_CHAR3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplAsaRecord_Exchange.GCO_EXCH_CHAR4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplAsaRecord_Exchange.GCO_EXCH_CHAR5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update ASA_RECORD
               set GCO_EXCH_CHAR1_ID = nvl(lChar1Id, GCO_EXCH_CHAR1_ID)
                 , GCO_EXCH_CHAR2_ID = nvl(lChar2Id, GCO_EXCH_CHAR2_ID)
                 , GCO_EXCH_CHAR3_ID = nvl(lChar3Id, GCO_EXCH_CHAR3_ID)
                 , GCO_EXCH_CHAR4_ID = nvl(lChar4Id, GCO_EXCH_CHAR4_ID)
                 , GCO_EXCH_CHAR5_ID = nvl(lChar5Id, GCO_EXCH_CHAR5_ID)
                 , ARE_EXCH_CHAR1_VALUE = decode(lChar1Id, null, ARE_EXCH_CHAR1_VALUE, lVal1)
                 , ARE_EXCH_CHAR2_VALUE = decode(lChar2Id, null, ARE_EXCH_CHAR2_VALUE, lVal2)
                 , ARE_EXCH_CHAR3_VALUE = decode(lChar3Id, null, ARE_EXCH_CHAR3_VALUE, lVal3)
                 , ARE_EXCH_CHAR4_VALUE = decode(lChar4Id, null, ARE_EXCH_CHAR4_VALUE, lVal4)
                 , ARE_EXCH_CHAR5_VALUE = decode(lChar5Id, null, ARE_EXCH_CHAR5_VALUE, lVal5)
             where ASA_RECORD_ID = tplAsaRecord_Exchange.ASA_RECORD_ID;
          end;
        end loop;

        for tplAsaRecord_NewGood in lcurAsaRecordNewGood(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar2Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar3Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar4Id ASA_RECORD.GCO_CHAR1_ID%type;
            lChar5Id ASA_RECORD.GCO_CHAR1_ID%type;
            lVal1    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal2    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal3    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal4    ASA_RECORD.ARE_CHAR1_VALUE%type;
            lVal5    ASA_RECORD.ARE_CHAR1_VALUE%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplAsaRecord_NewGood.GCO_NEW_CHAR1_ID, 0)
                      , nvl(tplAsaRecord_NewGood.GCO_NEW_CHAR2_ID, 0)
                      , nvl(tplAsaRecord_NewGood.GCO_NEW_CHAR3_ID, 0)
                      , nvl(tplAsaRecord_NewGood.GCO_NEW_CHAR4_ID, 0)
                      , nvl(tplAsaRecord_NewGood.GCO_NEW_CHAR5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplAsaRecord_NewGood.GCO_NEW_CHAR1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplAsaRecord_NewGood.GCO_NEW_CHAR2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplAsaRecord_NewGood.GCO_NEW_CHAR3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplAsaRecord_NewGood.GCO_NEW_CHAR4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplAsaRecord_NewGood.GCO_NEW_CHAR5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update ASA_RECORD
               set GCO_NEW_CHAR1_ID = nvl(lChar1Id, GCO_NEW_CHAR1_ID)
                 , GCO_NEW_CHAR2_ID = nvl(lChar2Id, GCO_NEW_CHAR2_ID)
                 , GCO_NEW_CHAR3_ID = nvl(lChar3Id, GCO_NEW_CHAR3_ID)
                 , GCO_NEW_CHAR4_ID = nvl(lChar4Id, GCO_NEW_CHAR4_ID)
                 , GCO_NEW_CHAR5_ID = nvl(lChar5Id, GCO_NEW_CHAR5_ID)
                 , ARE_NEW_CHAR1_VALUE = decode(lChar1Id, null, ARE_NEW_CHAR1_VALUE, lVal1)
                 , ARE_NEW_CHAR2_VALUE = decode(lChar2Id, null, ARE_NEW_CHAR2_VALUE, lVal2)
                 , ARE_NEW_CHAR3_VALUE = decode(lChar3Id, null, ARE_NEW_CHAR3_VALUE, lVal3)
                 , ARE_NEW_CHAR4_VALUE = decode(lChar4Id, null, ARE_NEW_CHAR4_VALUE, lVal4)
                 , ARE_NEW_CHAR5_VALUE = decode(lChar5Id, null, ARE_NEW_CHAR5_VALUE, lVal5)
             where ASA_RECORD_ID = tplAsaRecord_NewGood.ASA_RECORD_ID;
          end;
        end loop;

        for tplAsaRecordDetail in lcurAsaRecordDetails(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar2Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar3Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar4Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar5Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lVal1    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal2    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal3    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal4    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal5    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplAsaRecordDetail.GCO_CHAR1_ID, 0)
                      , nvl(tplAsaRecordDetail.GCO_CHAR2_ID, 0)
                      , nvl(tplAsaRecordDetail.GCO_CHAR3_ID, 0)
                      , nvl(tplAsaRecordDetail.GCO_CHAR4_ID, 0)
                      , nvl(tplAsaRecordDetail.GCO_CHAR5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplAsaRecordDetail.GCO_CHAR1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplAsaRecordDetail.GCO_CHAR2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplAsaRecordDetail.GCO_CHAR3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplAsaRecordDetail.GCO_CHAR4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplAsaRecordDetail.GCO_CHAR5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update ASA_RECORD_DETAIL
               set GCO_CHAR1_ID = nvl(lChar1Id, GCO_CHAR1_ID)
                 , GCO_CHAR2_ID = nvl(lChar2Id, GCO_CHAR2_ID)
                 , GCO_CHAR3_ID = nvl(lChar3Id, GCO_CHAR3_ID)
                 , GCO_CHAR4_ID = nvl(lChar4Id, GCO_CHAR4_ID)
                 , GCO_CHAR5_ID = nvl(lChar5Id, GCO_CHAR5_ID)
                 , RED_CHAR1_VALUE = decode(lChar1Id, null, RED_CHAR1_VALUE, lVal1)
                 , RED_CHAR2_VALUE = decode(lChar2Id, null, RED_CHAR2_VALUE, lVal2)
                 , RED_CHAR3_VALUE = decode(lChar3Id, null, RED_CHAR3_VALUE, lVal3)
                 , RED_CHAR4_VALUE = decode(lChar4Id, null, RED_CHAR4_VALUE, lVal4)
                 , RED_CHAR5_VALUE = decode(lChar5Id, null, RED_CHAR5_VALUE, lVal5)
             where ASA_RECORD_DETAIL_ID = tplAsaRecordDetail.ASA_RECORD_DETAIL_ID;
          end;
        end loop;

        for tplAsaRecordRepDetail in lcurAsaRecordRepDetails(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar2Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar3Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar4Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar5Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lVal1    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal2    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal3    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal4    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal5    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplAsaRecordRepDetail.GCO_CHAR1_ID, 0)
                      , nvl(tplAsaRecordRepDetail.GCO_CHAR2_ID, 0)
                      , nvl(tplAsaRecordRepDetail.GCO_CHAR3_ID, 0)
                      , nvl(tplAsaRecordRepDetail.GCO_CHAR4_ID, 0)
                      , nvl(tplAsaRecordRepDetail.GCO_CHAR5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplAsaRecordRepDetail.GCO_CHAR1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplAsaRecordRepDetail.GCO_CHAR2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplAsaRecordRepDetail.GCO_CHAR3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplAsaRecordRepDetail.GCO_CHAR4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplAsaRecordRepDetail.GCO_CHAR5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update ASA_RECORD_REP_DETAIL
               set GCO_CHAR1_ID = nvl(lChar1Id, GCO_CHAR1_ID)
                 , GCO_CHAR2_ID = nvl(lChar2Id, GCO_CHAR2_ID)
                 , GCO_CHAR3_ID = nvl(lChar3Id, GCO_CHAR3_ID)
                 , GCO_CHAR4_ID = nvl(lChar4Id, GCO_CHAR4_ID)
                 , GCO_CHAR5_ID = nvl(lChar5Id, GCO_CHAR5_ID)
                 , RRD_NEW_CHAR1_VALUE = decode(lChar1Id, null, RRD_NEW_CHAR1_VALUE, lVal1)
                 , RRD_NEW_CHAR2_VALUE = decode(lChar2Id, null, RRD_NEW_CHAR2_VALUE, lVal2)
                 , RRD_NEW_CHAR3_VALUE = decode(lChar3Id, null, RRD_NEW_CHAR3_VALUE, lVal3)
                 , RRD_NEW_CHAR4_VALUE = decode(lChar4Id, null, RRD_NEW_CHAR4_VALUE, lVal4)
                 , RRD_NEW_CHAR5_VALUE = decode(lChar5Id, null, RRD_NEW_CHAR5_VALUE, lVal5)
             where ASA_RECORD_REP_DETAIL_ID = tplAsaRecordRepDetail.ASA_RECORD_REP_DETAIL_ID;
          end;
        end loop;

        for tplAsaRecordExchDetail in lcurAsaRecordExchDetails(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar2Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar3Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar4Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lChar5Id ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
            lVal1    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal2    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal3    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal4    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
            lVal5    ASA_RECORD_DETAIL.RED_CHAR1_VALUE%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplAsaRecordExchDetail.GCO_EXCH_CHAR1_ID, 0)
                      , nvl(tplAsaRecordExchDetail.GCO_EXCH_CHAR2_ID, 0)
                      , nvl(tplAsaRecordExchDetail.GCO_EXCH_CHAR3_ID, 0)
                      , nvl(tplAsaRecordExchDetail.GCO_EXCH_CHAR4_ID, 0)
                      , nvl(tplAsaRecordExchDetail.GCO_EXCH_CHAR5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplAsaRecordExchDetail.GCO_EXCH_CHAR1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplAsaRecordExchDetail.GCO_EXCH_CHAR2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplAsaRecordExchDetail.GCO_EXCH_CHAR3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplAsaRecordExchDetail.GCO_EXCH_CHAR4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplAsaRecordExchDetail.GCO_EXCH_CHAR5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update ASA_RECORD_EXCH_DETAIL
               set GCO_EXCH_CHAR1_ID = nvl(lChar1Id, GCO_EXCH_CHAR1_ID)
                 , GCO_EXCH_CHAR2_ID = nvl(lChar2Id, GCO_EXCH_CHAR2_ID)
                 , GCO_EXCH_CHAR3_ID = nvl(lChar3Id, GCO_EXCH_CHAR3_ID)
                 , GCO_EXCH_CHAR4_ID = nvl(lChar4Id, GCO_EXCH_CHAR4_ID)
                 , GCO_EXCH_CHAR5_ID = nvl(lChar5Id, GCO_EXCH_CHAR5_ID)
                 , REX_EXCH_CHAR1_VALUE = decode(lChar1Id, null, REX_EXCH_CHAR1_VALUE, lVal1)
                 , REX_EXCH_CHAR2_VALUE = decode(lChar2Id, null, REX_EXCH_CHAR2_VALUE, lVal2)
                 , REX_EXCH_CHAR3_VALUE = decode(lChar3Id, null, REX_EXCH_CHAR3_VALUE, lVal3)
                 , REX_EXCH_CHAR4_VALUE = decode(lChar4Id, null, REX_EXCH_CHAR4_VALUE, lVal4)
                 , REX_EXCH_CHAR5_VALUE = decode(lChar5Id, null, REX_EXCH_CHAR5_VALUE, lVal5)
             where ASA_RECORD_EXCH_DETAIL_ID = tplAsaRecordExchDetail.ASA_RECORD_EXCH_DETAIL_ID;
          end;
        end loop;

        for tplAsaRecordComp in lcurAsaRecordComps(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id ASA_RECORD_COMP.GCO_CHAR1_ID%type;
            lChar2Id ASA_RECORD_COMP.GCO_CHAR1_ID%type;
            lChar3Id ASA_RECORD_COMP.GCO_CHAR1_ID%type;
            lChar4Id ASA_RECORD_COMP.GCO_CHAR1_ID%type;
            lChar5Id ASA_RECORD_COMP.GCO_CHAR1_ID%type;
            lVal1    ASA_RECORD_COMP.ARC_CHAR1_VALUE%type;
            lVal2    ASA_RECORD_COMP.ARC_CHAR1_VALUE%type;
            lVal3    ASA_RECORD_COMP.ARC_CHAR1_VALUE%type;
            lVal4    ASA_RECORD_COMP.ARC_CHAR1_VALUE%type;
            lVal5    ASA_RECORD_COMP.ARC_CHAR1_VALUE%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplAsaRecordComp.GCO_CHAR1_ID, 0)
                      , nvl(tplAsaRecordComp.GCO_CHAR2_ID, 0)
                      , nvl(tplAsaRecordComp.GCO_CHAR3_ID, 0)
                      , nvl(tplAsaRecordComp.GCO_CHAR4_ID, 0)
                      , nvl(tplAsaRecordComp.GCO_CHAR5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplAsaRecordComp.GCO_CHAR1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplAsaRecordComp.GCO_CHAR2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplAsaRecordComp.GCO_CHAR3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplAsaRecordComp.GCO_CHAR4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplAsaRecordComp.GCO_CHAR5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update ASA_RECORD_COMP
               set GCO_CHAR1_ID = nvl(lChar1Id, GCO_CHAR1_ID)
                 , GCO_CHAR2_ID = nvl(lChar2Id, GCO_CHAR2_ID)
                 , GCO_CHAR3_ID = nvl(lChar3Id, GCO_CHAR3_ID)
                 , GCO_CHAR4_ID = nvl(lChar4Id, GCO_CHAR4_ID)
                 , GCO_CHAR5_ID = nvl(lChar5Id, GCO_CHAR5_ID)
                 , ARC_CHAR1_VALUE = decode(lChar1Id, null, ARC_CHAR1_VALUE, lVal1)
                 , ARC_CHAR2_VALUE = decode(lChar2Id, null, ARC_CHAR2_VALUE, lVal2)
                 , ARC_CHAR3_VALUE = decode(lChar3Id, null, ARC_CHAR3_VALUE, lVal3)
                 , ARC_CHAR4_VALUE = decode(lChar4Id, null, ARC_CHAR4_VALUE, lVal4)
                 , ARC_CHAR5_VALUE = decode(lChar5Id, null, ARC_CHAR5_VALUE, lVal5)
             where ASA_RECORD_COMP_ID = tplAsaRecordComp.ASA_RECORD_COMP_ID;
          end;
        end loop;

        for tplAsaGuarantyCard in lcurAsaGuarantyCards(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id ASA_GUARANTY_CARDS.GCO_CHAR1_ID%type;
            lChar2Id ASA_GUARANTY_CARDS.GCO_CHAR1_ID%type;
            lChar3Id ASA_GUARANTY_CARDS.GCO_CHAR1_ID%type;
            lChar4Id ASA_GUARANTY_CARDS.GCO_CHAR1_ID%type;
            lChar5Id ASA_GUARANTY_CARDS.GCO_CHAR1_ID%type;
            lVal1    ASA_GUARANTY_CARDS.AGC_CHAR1_VALUE%type;
            lVal2    ASA_GUARANTY_CARDS.AGC_CHAR2_VALUE%type;
            lVal3    ASA_GUARANTY_CARDS.AGC_CHAR3_VALUE%type;
            lVal4    ASA_GUARANTY_CARDS.AGC_CHAR4_VALUE%type;
            lVal5    ASA_GUARANTY_CARDS.AGC_CHAR5_VALUE%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplAsaGuarantyCard.GCO_CHAR1_ID, 0)
                      , nvl(tplAsaGuarantyCard.GCO_CHAR2_ID, 0)
                      , nvl(tplAsaGuarantyCard.GCO_CHAR3_ID, 0)
                      , nvl(tplAsaGuarantyCard.GCO_CHAR4_ID, 0)
                      , nvl(tplAsaGuarantyCard.GCO_CHAR5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplAsaGuarantyCard.GCO_CHAR1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplAsaGuarantyCard.GCO_CHAR2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplAsaGuarantyCard.GCO_CHAR3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplAsaGuarantyCard.GCO_CHAR4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplAsaGuarantyCard.GCO_CHAR5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update ASA_GUARANTY_CARDS
               set GCO_CHAR1_ID = nvl(lChar1Id, GCO_CHAR1_ID)
                 , GCO_CHAR2_ID = nvl(lChar2Id, GCO_CHAR2_ID)
                 , GCO_CHAR3_ID = nvl(lChar3Id, GCO_CHAR3_ID)
                 , GCO_CHAR4_ID = nvl(lChar4Id, GCO_CHAR4_ID)
                 , GCO_CHAR5_ID = nvl(lChar5Id, GCO_CHAR5_ID)
                 , AGC_CHAR1_VALUE = decode(lChar1Id, null, AGC_CHAR1_VALUE, lVal1)
                 , AGC_CHAR2_VALUE = decode(lChar2Id, null, AGC_CHAR2_VALUE, lVal2)
                 , AGC_CHAR3_VALUE = decode(lChar3Id, null, AGC_CHAR3_VALUE, lVal3)
                 , AGC_CHAR4_VALUE = decode(lChar4Id, null, AGC_CHAR4_VALUE, lVal4)
                 , AGC_CHAR5_VALUE = decode(lChar5Id, null, AGC_CHAR5_VALUE, lVal5)
             where ASA_GUARANTY_CARDS_ID = tplAsaGuarantyCard.ASA_GUARANTY_CARDS_ID;
          end;
        end loop;

        for tplAsaStolenGood in lcurAsaStolenGoods(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id ASA_STOLEN_GOODS.GCO_CHAR1_ID%type;
            lChar2Id ASA_STOLEN_GOODS.GCO_CHAR1_ID%type;
            lChar3Id ASA_STOLEN_GOODS.GCO_CHAR1_ID%type;
            lChar4Id ASA_STOLEN_GOODS.GCO_CHAR1_ID%type;
            lChar5Id ASA_STOLEN_GOODS.GCO_CHAR1_ID%type;
            lVal1    ASA_STOLEN_GOODS.ASG_CHAR1_VALUE%type;
            lVal2    ASA_STOLEN_GOODS.ASG_CHAR1_VALUE%type;
            lVal3    ASA_STOLEN_GOODS.ASG_CHAR1_VALUE%type;
            lVal4    ASA_STOLEN_GOODS.ASG_CHAR1_VALUE%type;
            lVal5    ASA_STOLEN_GOODS.ASG_CHAR1_VALUE%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplAsaStolenGood.GCO_CHAR1_ID, 0)
                      , nvl(tplAsaStolenGood.GCO_CHAR2_ID, 0)
                      , nvl(tplAsaStolenGood.GCO_CHAR3_ID, 0)
                      , nvl(tplAsaStolenGood.GCO_CHAR4_ID, 0)
                      , nvl(tplAsaStolenGood.GCO_CHAR5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplAsaStolenGood.GCO_CHAR1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplAsaStolenGood.GCO_CHAR2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplAsaStolenGood.GCO_CHAR3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplAsaStolenGood.GCO_CHAR4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplAsaStolenGood.GCO_CHAR5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update ASA_STOLEN_GOODS
               set GCO_CHAR1_ID = nvl(lChar1Id, GCO_CHAR1_ID)
                 , GCO_CHAR2_ID = nvl(lChar2Id, GCO_CHAR2_ID)
                 , GCO_CHAR3_ID = nvl(lChar3Id, GCO_CHAR3_ID)
                 , GCO_CHAR4_ID = nvl(lChar4Id, GCO_CHAR4_ID)
                 , GCO_CHAR5_ID = nvl(lChar5Id, GCO_CHAR5_ID)
                 , ASG_CHAR1_VALUE = decode(lChar1Id, null, ASG_CHAR1_VALUE, lVal1)
                 , ASG_CHAR2_VALUE = decode(lChar2Id, null, ASG_CHAR2_VALUE, lVal2)
                 , ASG_CHAR3_VALUE = decode(lChar3Id, null, ASG_CHAR3_VALUE, lVal3)
                 , ASG_CHAR4_VALUE = decode(lChar4Id, null, ASG_CHAR4_VALUE, lVal4)
                 , ASG_CHAR5_VALUE = decode(lChar5Id, null, ASG_CHAR5_VALUE, lVal5)
             where ASA_STOLEN_GOODS_ID = tplAsaStolenGood.ASA_STOLEN_GOODS_ID;
          end;
        end loop;

        for tplInterventionDetail in lcurInterventionDetail(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id ASA_INTERVENTION_DETAIL.GCO_CHAR1_ID%type;
            lChar2Id ASA_INTERVENTION_DETAIL.GCO_CHAR2_ID%type;
            lChar3Id ASA_INTERVENTION_DETAIL.GCO_CHAR3_ID%type;
            lChar4Id ASA_INTERVENTION_DETAIL.GCO_CHAR4_ID%type;
            lChar5Id ASA_INTERVENTION_DETAIL.GCO_CHAR5_ID%type;
            lVal1    ASA_INTERVENTION_DETAIL.AID_CHAR1_VALUE%type;
            lVal2    ASA_INTERVENTION_DETAIL.AID_CHAR2_VALUE%type;
            lVal3    ASA_INTERVENTION_DETAIL.AID_CHAR3_VALUE%type;
            lVal4    ASA_INTERVENTION_DETAIL.AID_CHAR4_VALUE%type;
            lVal5    ASA_INTERVENTION_DETAIL.AID_CHAR5_VALUE%type;
          begin
            exit when iCharacterizationId in
                       (nvl(tplInterventionDetail.GCO_CHAR1_ID, 0)
                      , nvl(tplInterventionDetail.GCO_CHAR2_ID, 0)
                      , nvl(tplInterventionDetail.GCO_CHAR3_ID, 0)
                      , nvl(tplInterventionDetail.GCO_CHAR4_ID, 0)
                      , nvl(tplInterventionDetail.GCO_CHAR5_ID, 0)
                       );
            lAtLeastOneElement  := true;

            if tplInterventionDetail.GCO_CHAR1_ID is null then
              lChar1Id  := iCharacterizationId;
              lVal1     := iDefValue;
            elsif tplInterventionDetail.GCO_CHAR2_ID is null then
              lChar2Id  := iCharacterizationId;
              lVal2     := iDefValue;
            elsif tplInterventionDetail.GCO_CHAR3_ID is null then
              lChar3Id  := iCharacterizationId;
              lVal3     := iDefValue;
            elsif tplInterventionDetail.GCO_CHAR4_ID is null then
              lChar4Id  := iCharacterizationId;
              lVal4     := iDefValue;
            elsif tplInterventionDetail.GCO_CHAR5_ID is null then
              lChar5Id  := iCharacterizationId;
              lVal5     := iDefValue;
            end if;

            update ASA_INTERVENTION_DETAIL
               set GCO_CHAR1_ID = nvl(lChar1Id, GCO_CHAR1_ID)
                 , GCO_CHAR2_ID = nvl(lChar2Id, GCO_CHAR2_ID)
                 , GCO_CHAR3_ID = nvl(lChar3Id, GCO_CHAR3_ID)
                 , GCO_CHAR4_ID = nvl(lChar4Id, GCO_CHAR4_ID)
                 , GCO_CHAR5_ID = nvl(lChar5Id, GCO_CHAR5_ID)
                 , AID_CHAR1_VALUE = decode(lChar1Id, null, AID_CHAR1_VALUE, lVal1)
                 , AID_CHAR2_VALUE = decode(lChar2Id, null, AID_CHAR2_VALUE, lVal2)
                 , AID_CHAR3_VALUE = decode(lChar3Id, null, AID_CHAR3_VALUE, lVal3)
                 , AID_CHAR4_VALUE = decode(lChar4Id, null, AID_CHAR4_VALUE, lVal4)
                 , AID_CHAR5_VALUE = decode(lChar5Id, null, AID_CHAR5_VALUE, lVal5)
             where ASA_INTERVENTION_DETAIL_ID = tplInterventionDetail.ASA_INTERVENTION_DETAIL_ID;
          end;
        end loop;

        -- split et création des détails si besoin pour les caractérisations de type pièces
        if ltplCharac.C_CHARACT_TYPE = gcCharacTypePiece then
          splitAsaRecordForPiece(ltplCharac.GCO_GOOD_ID, iCharacterizationId);
        end if;
      end if;

      -- création d'un élément dans STM_ELEMENT_NUMBER, si le bien avait déjà été utilisé au moins une fois
      if     lAtLeastOneElement
         and ltplCharac.C_CHARACT_TYPE in(gcCharacTypeVersion, gcCharacTypePiece, gcCharacTypeSet) then
        declare
          lAlreadyExists number(1);
        begin
          if nvl(iQualityValue, 0) <> 0 then
            lQualityStatusId  := iQualityValue;
          end if;

          STM_PRC_STOCK_POSITION.ManageElementNumber(iGoodId             => ltplCharac.GCO_GOOD_ID
                                                   , iCharId             => iCharacterizationId
                                                   , iStockManagement    => ltplCharac.CHA_STOCK_MANAGEMENT
                                                   , iUpdateMode         => 'IW'
                                                   , iMovementSort       => 'ENT'
                                                   , iCharacType         => ltplCharac.C_CHARACT_TYPE
                                                   , iSemValue           => iDefValue
                                                   , iElementStatus      => '02'
                                                   , iVerifyChar         => 1
                                                   , iAutoInc            => 0
                                                   , iIncStep            => 0
                                                   , oElementNumber      => lElementNumberId
                                                   , ioQualityStatusId   => lQualityStatusId
                                                   , oAlreadyExist       => lAlreadyExists
                                                   , iDateRetest         => iRetestValue
                                                    );
        end;
      end if;

      -- si la caractérisation à ajouter est gérée en stock
      if ltplCharac.CHA_STOCK_MANAGEMENT = 1 then
        -- Suppression des positions d'inventaire
        removeInventory(ltplCharac.GCO_GOOD_ID);

        for tplStockPosition in lcurStockPositions(ltplCharac.GCO_GOOD_ID) loop
          declare
            lChar1Id       STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
            lChar2Id       STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
            lChar3Id       STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
            lChar4Id       STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
            lChar5Id       STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
            lVal1          STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
            lVal2          STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
            lVal3          STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
            lVal4          STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
            lVal5          STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
            lEleNum1       STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
            lEleNum2       STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
            lEleNum3       STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
            lPiece         varchar2(30);
            lSet           varchar2(30);
            lVersion       varchar2(30);
            lChronological varchar2(30);
            lCharStd1      varchar2(30);
            lCharStd2      varchar2(30);
            lCharStd3      varchar2(30);
            lCharStd4      varchar2(30);
            lCharStd5      varchar2(30);
          begin
            if not iCharacterizationId in
                 (nvl(tplStockPosition.GCO_CHARACTERIZATION_ID, 0)
                , nvl(tplStockPosition.GCO_GCO_CHARACTERIZATION_ID, 0)
                , nvl(tplStockPosition.GCO2_GCO_CHARACTERIZATION_ID, 0)
                , nvl(tplStockPosition.GCO3_GCO_CHARACTERIZATION_ID, 0)
                , nvl(tplStockPosition.GCO4_GCO_CHARACTERIZATION_ID, 0)
                 ) then
              if tplStockPosition.GCO_CHARACTERIZATION_ID is null then
                lChar1Id  := iCharacterizationId;
                lVal1     := iDefValue;
              elsif tplStockPosition.GCO_GCO_CHARACTERIZATION_ID is null then
                lChar2Id  := iCharacterizationId;
                lVal2     := iDefValue;
              elsif tplStockPosition.GCO2_GCO_CHARACTERIZATION_ID is null then
                lChar3Id  := iCharacterizationId;
                lVal3     := iDefValue;
              elsif tplStockPosition.GCO3_GCO_CHARACTERIZATION_ID is null then
                lChar4Id  := iCharacterizationId;
                lVal4     := iDefValue;
              elsif tplStockPosition.GCO4_GCO_CHARACTERIZATION_ID is null then
                lChar5Id  := iCharacterizationId;
                lVal5     := iDefValue;
              end if;

              if ltplCharac.C_CHARACT_TYPE in(gcCharacTypeVersion, gcCharacTypePiece, gcCharacTypeSet) then
                if tplStockPosition.STM_ELEMENT_NUMBER_ID is null then
                  lEleNum1  := lElementNumberId;
                else
                  lEleNum1  := tplStockPosition.STM_ELEMENT_NUMBER_ID;

                  if tplStockPosition.STM_STM_ELEMENT_NUMBER_ID is null then
                    lEleNum2  := lElementNumberId;
                  else
                    lEleNum2  := tplStockPosition.STM_STM_ELEMENT_NUMBER_ID;

                    if tplStockPosition.STM2_STM_ELEMENT_NUMBER_ID is null then
                      lEleNum3  := lElementNumberId;
                    else
                      lEleNum3  := tplStockPosition.STM2_STM_ELEMENT_NUMBER_ID;
                    end if;
                  end if;
                end if;
              end if;

              lAtLeastOneElement  := true;
              GCO_LIB_CHARACTERIZATION.ClassifyCharacterizations(nvl(lChar1Id, tplStockPosition.GCO_CHARACTERIZATION_ID)
                                                               , nvl(lChar2Id, tplStockPosition.GCO_GCO_CHARACTERIZATION_ID)
                                                               , nvl(lChar3Id, tplStockPosition.GCO2_GCO_CHARACTERIZATION_ID)
                                                               , nvl(lChar4Id, tplStockPosition.GCO3_GCO_CHARACTERIZATION_ID)
                                                               , nvl(lChar5Id, tplStockPosition.GCO4_GCO_CHARACTERIZATION_ID)
                                                               , nvl(lVal1, tplStockPosition.SPO_CHARACTERIZATION_VALUE_1)
                                                               , nvl(lVal2, tplStockPosition.SPO_CHARACTERIZATION_VALUE_2)
                                                               , nvl(lVal3, tplStockPosition.SPO_CHARACTERIZATION_VALUE_3)
                                                               , nvl(lVal4, tplStockPosition.SPO_CHARACTERIZATION_VALUE_4)
                                                               , nvl(lVal5, tplStockPosition.SPO_CHARACTERIZATION_VALUE_5)
                                                               , lPiece
                                                               , lSet
                                                               , lVersion
                                                               , lChronological
                                                               , lCharStd1
                                                               , lCharStd2
                                                               , lCharStd3
                                                               , lCharStd4
                                                               , lCharStd5
                                                                );
              GCO_LIB_CHARACTERIZATION.CompactElementNumbers(lEleNum1, lEleNum2, lEleNum3);

              update STM_STOCK_POSITION
                 set GCO_CHARACTERIZATION_ID = nvl(lChar1Id, GCO_CHARACTERIZATION_ID)
                   , GCO_GCO_CHARACTERIZATION_ID = nvl(lChar2Id, GCO_GCO_CHARACTERIZATION_ID)
                   , GCO2_GCO_CHARACTERIZATION_ID = nvl(lChar3Id, GCO2_GCO_CHARACTERIZATION_ID)
                   , GCO3_GCO_CHARACTERIZATION_ID = nvl(lChar4Id, GCO3_GCO_CHARACTERIZATION_ID)
                   , GCO4_GCO_CHARACTERIZATION_ID = nvl(lChar5Id, GCO4_GCO_CHARACTERIZATION_ID)
                   , SPO_CHARACTERIZATION_VALUE_1 = decode(lChar1Id, null, SPO_CHARACTERIZATION_VALUE_1, lVal1)
                   , SPO_CHARACTERIZATION_VALUE_2 = decode(lChar2Id, null, SPO_CHARACTERIZATION_VALUE_2, lVal2)
                   , SPO_CHARACTERIZATION_VALUE_3 = decode(lChar3Id, null, SPO_CHARACTERIZATION_VALUE_3, lVal3)
                   , SPO_CHARACTERIZATION_VALUE_4 = decode(lChar4Id, null, SPO_CHARACTERIZATION_VALUE_4, lVal4)
                   , SPO_CHARACTERIZATION_VALUE_5 = decode(lChar5Id, null, SPO_CHARACTERIZATION_VALUE_5, lVal5)
                   , SPO_PIECE = lPiece
                   , SPO_SET = lSet
                   , SPO_VERSION = lVersion
                   , SPO_CHRONOLOGICAL = lChronological
                   , SPO_STD_CHAR_1 = lCharStd1
                   , SPO_STD_CHAR_2 = lCharStd2
                   , SPO_STD_CHAR_3 = lCharStd3
                   , SPO_STD_CHAR_4 = lCharStd4
                   , SPO_STD_CHAR_5 = lCharStd5
                   , STM_ELEMENT_NUMBER_ID = nvl(lEleNum1, STM_ELEMENT_NUMBER_ID)
                   , STM_STM_ELEMENT_NUMBER_ID = nvl(lEleNum2, STM_STM_ELEMENT_NUMBER_ID)
                   , STM2_STM_ELEMENT_NUMBER_ID = nvl(lEleNum3, STM2_STM_ELEMENT_NUMBER_ID)
               where STM_STOCK_POSITION_ID = tplStockPosition.STM_STOCK_POSITION_ID;
            end if;
          end;
        end loop;

        -- création des positions temporaire de stock qui serviront à caractériser
        -- le stock existant
        fillStkPosToTemp(ltplCharac.GCO_GOOD_ID, ltplCharac.C_CHARACT_TYPE, iQualityValue, iRetestValue);
      end if;

      -- suivi des modifications
      select nvl(max(SLO_ACTIVE), 0)
        into lCheckIn
        from PCS.PC_SYS_LOG
       where C_LTM_SYS_LOG = '01'
         and PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;

      if lCheckIn = 1 then
        lCheckIn  :=
          LTM_TRACK.CheckIn(ltplCharac.GCO_GOOD_ID
                          , '01'
                          , pcs.PC_FUNCTIONS.TranslateWord('Caractérisation ajoutée par l''assistant de mise à jour des caractérisations'
                                                         , pcs.PC_I_LIB_SESSION.GetCompLangId
                                                          )
                           );
      end if;
    exception
      when others then
        iError  := 1;
        LogCharacWizardEvent(iAction               => 'ERA'
                           , iCharacterizationId   => iCharacterizationId
                           , iCharDesign           => ltplCharac.CHA_CHARACTERIZATION_DESIGN
                           , iGoodId               => ltplCharac.GCO_GOOD_ID
                           , iErrorComment         => sqlerrm || chr(13) || DBMS_UTILITY.Format_Error_backtrace
                            );
    end;

    -- Fin du mode de maintenance
    gCharManagementMode  := 0;
  end addCharToExisting;

  /**
  * Description
  *   Dans le cadre de l'ajout d'un détail de caractérisation
  *   procedure mettant à jour les différentes tables utilisant les caractérisations
  */
  procedure addUseDetailToExisting(iCharacterizationId in number, iQualityValue in number, iRetestValue in date, iError out number)
  is
    lGoodId                    GCO_GOOD.GCO_GOOD_ID%type;
    lChaCharacterizationDesign GCO_CHARACTERIZATION.CHA_CHARACTERIZATION_DESIGN%type;
    lCCharactType              GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
  begin
    begin
      -- Récupération des informations de la caractérisation
      select GCO_GOOD_ID
           , C_CHARACT_TYPE
           , CHA_CHARACTERIZATION_DESIGN
        into lGoodId
           , lCCharactType
           , lChaCharacterizationDesign
        from GCO_CHARACTERIZATION
       where GCO_CHARACTERIZATION_ID = iCharacterizationId;

      -- Log de l'opération
      LogCharacWizardEvent('ADD', iCharacterizationId, lChaCharacterizationDesign, lGoodId);
      -- Ajouter le produit à une table temporaire pour effectuer le traitement de MAJ du statut et de la date de ré-analyse
      fillGoodToTemp(lGoodId);

      for tplElementNumber in (select STM_ELEMENT_NUMBER_ID
                                 from STM_ELEMENT_NUMBER
                                where GCO_GOOD_ID = lGoodId
                                  and STM_I_LIB_ELEMENT_NUMBER.GetCharFromDetailElement(STM_ELEMENT_NUMBER_ID) = iCharacterizationId) loop
        -- Dénormalisation du champ STM_ELEMENT_NUMBER_DETAIL_ID sur la position de stock
        STM_I_PRC_ELEMENT_NUMBER.DenormalizeElementNumber(tplElementNumber.STM_ELEMENT_NUMBER_ID);

        -- Changement du statut qualité
        if iQualityValue <> 0 then
          STM_I_PRC_ELEMENT_NUMBER.ChangeStatus(tplElementNumber.STM_ELEMENT_NUMBER_ID, iQualityValue);
        end if;

        -- Changement de la date de ré-analyse
        if iRetestValue is not null then
          STM_I_PRC_ELEMENT_NUMBER.ChangeRetestDate(tplElementNumber.STM_ELEMENT_NUMBER_ID, iRetestValue);
        end if;
      end loop;
    exception
      when others then
        iError  := 1;
        LogCharacWizardEvent(iAction               => 'ERA'
                           , iCharacterizationId   => iCharacterizationId
                           , iCharDesign           => lChaCharacterizationDesign
                           , iGoodId               => lGoodId
                           , iErrorComment         => sqlerrm || chr(13) || DBMS_UTILITY.Format_Error_backtrace
                            );
    end;
  end addUseDetailToExisting;

  /**
  * Description
  *   Ajout d'un détail de caractérisation à une caractérisation existante
  */
  procedure addUseDetail(
    iGoodID             in     GCO_GOOD.GCO_GOOD_ID%type
  , iCharType           in     GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , iUseDetail          in     GCO_CHARACTERIZATION.CHA_USE_DETAIL%type
  , iWithRetest         in     GCO_CHARACTERIZATION.CHA_WITH_RETEST%type
  , iRetestDelay        in     GCO_CHARACTERIZATION.CHA_RETEST_DELAY%type
  , iRetestMargin       in     GCO_CHARACTERIZATION.CHA_RETEST_MARGIN%type
  , iQualityStatusMgmt  in     GCO_CHARACTERIZATION.CHA_QUALITY_STATUS_MGMT%type
  , iQualityStatFlowId  in     GCO_CHARACTERIZATION.GCO_QUALITY_STAT_FLOW_ID%type
  , iQualityStatusId    in     GCO_CHARACTERIZATION.GCO_QUALITY_STATUS_ID%type
  , oCharacterizationId out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  )
  is
    lcharID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    ltChar  fwk_i_typ_definition.t_crud_def;
  begin
    begin
      select GCO_CHARACTERIZATION_ID
        into lcharID
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iGoodId
         and C_CHARACT_TYPE = iCharType;
    exception
      when no_data_found then
        lcharID  := null;
    end;

    if lcharID is not null then
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_GCO_ENTITY.gcGcoCharacterization, iot_crud_definition => ltChar, in_main_id => lcharID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltChar, 'CHA_USE_DETAIL', iUseDetail);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltChar, 'CHA_WITH_RETEST', iWithRetest);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltChar, 'CHA_RETEST_DELAY', iRetestDelay);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltChar, 'CHA_RETEST_MARGIN', iRetestMargin);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltChar, 'CHA_QUALITY_STATUS_MGMT', iQualityStatusMgmt);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltChar, 'GCO_QUALITY_STAT_FLOW_ID', iQualityStatFlowId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltChar, 'GCO_QUALITY_STATUS_ID', iQualityStatusId);
      FWK_I_MGT_ENTITY.UpdateEntity(ltChar);
      FWK_I_MGT_ENTITY.Release(ltChar);
    end if;

    oCharacterizationId  := lCharID;
  end addUseDetail;

  /**
  * Description
  *   Création des descriptions de caractérisation à partir de la COM_LIST_ID_TEMP
  */
  procedure CreateCharDescr(iCharacterizationId in number, iTempCharId in number)
  is
    ltGcoDescLang FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplDesc in (select   LID_ID_2 PC_LANG_ID
                           , LID_FREE_CHAR_1 DLA_DESCRIPTION
                        from COM_LIST_ID_TEMP
                       where LID_CODE = 'CharDescr'
                         and LID_ID_1 = iTempCharId
                    order by LID_ID_2) loop   -- Order by PC_LANG_ID
      FWK_I_MGT_ENTITY.new(FWK_TYP_GCO_ENTITY.gcGcoDescLanguage, ltGcoDescLang);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGcoDescLang, 'GCO_DESC_LANGUAGE_ID', INIT_ID_SEQ.nextval);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGcoDescLang, 'C_TYPE_DESC_LANG', '3');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGcoDescLang, 'GCO_CHARACTERIZATION_ID', iCharacterizationId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGcoDescLang, 'PC_LANG_ID', tplDesc.PC_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGcoDescLang, 'DLA_DESCRIPTION', tplDesc.DLA_DESCRIPTION);
      FWK_I_MGT_ENTITY.InsertEntity(ltGcoDescLang);
      FWK_I_MGT_ENTITY.Release(ltGcoDescLang);
    end loop;
  end CreateCharDescr;

  /**
  * Description
  *   Création des descriptions d'un élément de caractérisation  à partir de la COM_LIST_ID_TEMP
  */
  procedure CreateCharElemDescr(iCharacteristicElementID in number, iTempCharElemId in number)
  is
    ltGcoDescLang FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplDesc in (select   LID_ID_2 PC_LANG_ID
                           , LID_FREE_CHAR_1 DLA_DESCRIPTION
                        from COM_LIST_ID_TEMP
                       where LID_CODE = 'ElemDescr'
                         and LID_ID_1 = iTempCharElemId
                    order by LID_ID_2) loop   -- Order by PC_LANG_ID
      FWK_I_MGT_ENTITY.new(FWK_TYP_GCO_ENTITY.gcGcoDescLanguage, ltGcoDescLang);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGcoDescLang, 'GCO_DESC_LANGUAGE_ID', INIT_ID_SEQ.nextval);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGcoDescLang, 'C_TYPE_DESC_LANG', '4');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGcoDescLang, 'GCO_CHARACTERISTIC_ELEMENT_ID', iCharacteristicElementID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGcoDescLang, 'PC_LANG_ID', tplDesc.PC_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGcoDescLang, 'DLA_DESCRIPTION', tplDesc.DLA_DESCRIPTION);
      FWK_I_MGT_ENTITY.InsertEntity(ltGcoDescLang);
      FWK_I_MGT_ENTITY.Release(ltGcoDescLang);
    end loop;
  end CreateCharElemDescr;

  /**
  * Description
  *   Dans le cadre d'un retrait de caractérisation
  *   procedure mettant à jour les différentes tables utilisant les caractérisations
  *   !!!!!processus irréversible!!!!!
  */
  procedure removeCharToExisting(iCharacterizationId in number, iSilent in boolean default false, iError out number)
  is
    ltplCharac         GCO_CHARACTERIZATION%rowtype;

    cursor lcurPDE(iGoodId number, iCharId number)
    is
      select PDE.DOC_POSITION_DETAIL_ID
           , decode(PDE.GCO_CHARACTERIZATION_ID, iCharId, null, PDE.GCO_CHARACTERIZATION_ID || ',') ||
             decode(PDE.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, PDE.GCO_GCO_CHARACTERIZATION_ID || ',') ||
             decode(PDE.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, PDE.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
             decode(PDE.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, PDE.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
             decode(PDE.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, PDE.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
           , decode(PDE.GCO_CHARACTERIZATION_ID, iCharId, null, PDE.PDE_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(PDE.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, PDE.PDE_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(PDE.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, PDE.PDE_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(PDE.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, PDE.PDE_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(PDE.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, PDE.PDE_CHARACTERIZATION_VALUE_5 || ',') VALS
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
       where POS.GCO_GOOD_ID = iGoodId
         and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID;

    cursor lcurBarCode(iGoodId number, iCharId number)
    is
      select dba.DOC_BARCODE_ID
           , decode(dba.GCO_CHARACTERIZATION_ID, iCharId, null, dba.GCO_CHARACTERIZATION_ID || ',') ||
             decode(dba.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, dba.GCO_GCO_CHARACTERIZATION_ID || ',') ||
             decode(dba.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, dba.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
             decode(dba.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, dba.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
             decode(dba.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, dba.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
           , decode(dba.GCO_CHARACTERIZATION_ID, iCharId, null, dba.DBA_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(dba.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, dba.DBA_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(dba.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, dba.DBA_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(dba.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, dba.DBA_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(dba.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, dba.DBA_CHARACTERIZATION_VALUE_5 || ',') VALS
        from DOC_BARCODE dba
       where dba.GCO_GOOD_ID = iGoodId;

    cursor lcurStockMovements(iGoodId number, iCharId number)
    is
      select SMO.STM_STOCK_MOVEMENT_ID
           , decode(SMO.GCO_CHARACTERIZATION_ID, iCharId, null, SMO.GCO_CHARACTERIZATION_ID || ',') ||
             decode(SMO.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, SMO.GCO_GCO_CHARACTERIZATION_ID || ',') ||
             decode(SMO.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, SMO.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
             decode(SMO.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, SMO.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
             decode(SMO.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SMO.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
           , decode(SMO.GCO_CHARACTERIZATION_ID, iCharId, null, SMO.SMO_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(SMO.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, SMO.SMO_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(SMO.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, SMO.SMO_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(SMO.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, SMO.SMO_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(SMO.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SMO.SMO_CHARACTERIZATION_VALUE_5 || ',') VALS
           , SMO.GCO_CHARACTERIZATION_ID
           , SMO.GCO_GCO_CHARACTERIZATION_ID
           , SMO.GCO2_GCO_CHARACTERIZATION_ID
           , SMO.GCO3_GCO_CHARACTERIZATION_ID
           , SMO.GCO4_GCO_CHARACTERIZATION_ID
           , SMO.SMO_CHARACTERIZATION_VALUE_1
           , SMO.SMO_CHARACTERIZATION_VALUE_2
           , SMO.SMO_CHARACTERIZATION_VALUE_3
           , SMO.SMO_CHARACTERIZATION_VALUE_4
           , SMO.SMO_CHARACTERIZATION_VALUE_5
           , SMO_PIECE
           , SMO_SET
           , SMO_VERSION
           , SMO_CHRONOLOGICAL
           , SMO_STD_CHAR_1
           , SMO_STD_CHAR_2
           , SMO_STD_CHAR_3
           , SMO_STD_CHAR_4
           , SMO_STD_CHAR_5
        from STM_STOCK_MOVEMENT SMO
       where GCO_GOOD_ID = iGoodId;

    cursor lcurStockPositions(iGoodId number, iCharId number)
    is
      select   SPO.GCO_CHARACTERIZATION_ID
             , SPO.GCO_GCO_CHARACTERIZATION_ID
             , SPO.GCO2_GCO_CHARACTERIZATION_ID
             , SPO.GCO3_GCO_CHARACTERIZATION_ID
             , SPO.GCO4_GCO_CHARACTERIZATION_ID
             , decode(SPO.GCO_CHARACTERIZATION_ID, iCharId, null, SPO.GCO_CHARACTERIZATION_ID || ',') ||
               decode(SPO.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.GCO_GCO_CHARACTERIZATION_ID || ',') ||
               decode(SPO.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
               decode(SPO.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
               decode(SPO.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
             , decode(SPO.GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_1 || ',') ||
               decode(SPO.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_2 || ',') ||
               decode(SPO.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_3 || ',') ||
               decode(SPO.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_4 || ',') ||
               decode(SPO.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_5 || ',') VALS
             , decode(SPO.GCO_CHARACTERIZATION_ID, iCharId, ',', SPO.SPO_CHARACTERIZATION_VALUE_1 || ',') ||
               decode(SPO.GCO_GCO_CHARACTERIZATION_ID, iCharId, ',', SPO.SPO_CHARACTERIZATION_VALUE_2 || ',') ||
               decode(SPO.GCO2_GCO_CHARACTERIZATION_ID, iCharId, ',', SPO.SPO_CHARACTERIZATION_VALUE_3 || ',') ||
               decode(SPO.GCO3_GCO_CHARACTERIZATION_ID, iCharId, ',', SPO.SPO_CHARACTERIZATION_VALUE_4 || ',') ||
               decode(SPO.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_5) ORIGINAL_VALS
             , GCO_GOOD_ID
             , STM_LOCATION_ID
             , STM_STOCK_ID
             , max(C_POSITION_STATUS) C_POSITION_STATUS
             , max(STM_LAST_STOCK_MOVE_ID) STM_LAST_STOCK_MOVE_ID
             , sum(SPO_STOCK_QUANTITY) SPO_STOCK_QUANTITY
             , sum(SPO_ASSIGN_QUANTITY) SPO_ASSIGN_QUANTITY
             , sum(SPO_PROVISORY_INPUT) SPO_PROVISORY_INPUT
             , sum(SPO_PROVISORY_OUTPUT) SPO_PROVISORY_OUTPUT
             , sum(SPO_AVAILABLE_QUANTITY) SPO_AVAILABLE_QUANTITY
             , sum(SPO_THEORETICAL_QUANTITY) SPO_THEORETICAL_QUANTITY
             , sum(SPO_ALTERNATIV_QUANTITY_1) SPO_ALTERNATIV_QUANTITY_1
             , sum(SPO_ALTERNATIV_QUANTITY_2) SPO_ALTERNATIV_QUANTITY_2
             , sum(SPO_ALTERNATIV_QUANTITY_3) SPO_ALTERNATIV_QUANTITY_3
             , max(SPO_LAST_INVENTORY_DATE) SPO_LAST_INVENTORY_DATE
             , min(A_DATECRE) A_DATECRE
             , max(A_DATEMOD) A_DATEMOD
          from STM_STOCK_POSITION SPO
         where GCO_GOOD_ID = iGoodId
           and (   SPO.GCO_CHARACTERIZATION_ID = iCharId
                or SPO.GCO_GCO_CHARACTERIZATION_ID = iCharId
                or SPO.GCO2_GCO_CHARACTERIZATION_ID = iCharId
                or SPO.GCO3_GCO_CHARACTERIZATION_ID = iCharId
                or SPO.GCO4_GCO_CHARACTERIZATION_ID = iCharId
               )
      group by STM_LOCATION_ID
             , GCO_GOOD_ID
             , STM_STOCK_ID
             , SPO.GCO_CHARACTERIZATION_ID
             , SPO.GCO_GCO_CHARACTERIZATION_ID
             , SPO.GCO2_GCO_CHARACTERIZATION_ID
             , SPO.GCO3_GCO_CHARACTERIZATION_ID
             , SPO.GCO4_GCO_CHARACTERIZATION_ID
             , decode(SPO.GCO_CHARACTERIZATION_ID, iCharId, null, SPO.GCO_CHARACTERIZATION_ID || ',') ||
               decode(SPO.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.GCO_GCO_CHARACTERIZATION_ID || ',') ||
               decode(SPO.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
               decode(SPO.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
               decode(SPO.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.GCO4_GCO_CHARACTERIZATION_ID || ',')
             , decode(SPO.GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_1 || ',') ||
               decode(SPO.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_2 || ',') ||
               decode(SPO.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_3 || ',') ||
               decode(SPO.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_4 || ',') ||
               decode(SPO.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_5 || ',')
             , decode(SPO.GCO_CHARACTERIZATION_ID, iCharId, ',', SPO.SPO_CHARACTERIZATION_VALUE_1 || ',') ||
               decode(SPO.GCO_GCO_CHARACTERIZATION_ID, iCharId, ',', SPO.SPO_CHARACTERIZATION_VALUE_2 || ',') ||
               decode(SPO.GCO2_GCO_CHARACTERIZATION_ID, iCharId, ',', SPO.SPO_CHARACTERIZATION_VALUE_3 || ',') ||
               decode(SPO.GCO3_GCO_CHARACTERIZATION_ID, iCharId, ',', SPO.SPO_CHARACTERIZATION_VALUE_4 || ',') ||
               decode(SPO.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SPO.SPO_CHARACTERIZATION_VALUE_5);

    cursor lcurAnnualEvolutions(iGoodId number, iCharId number)
    is
      select SAE.STM_ANNUAL_EVOLUTION_ID
           , decode(SAE.GCO_CHARACTERIZATION_ID, iCharId, null, SAE.GCO_CHARACTERIZATION_ID || ',') ||
             decode(SAE.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, SAE.GCO_GCO_CHARACTERIZATION_ID || ',') ||
             decode(SAE.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, SAE.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
             decode(SAE.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, SAE.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
             decode(SAE.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SAE.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
           , decode(SAE.GCO_CHARACTERIZATION_ID, iCharId, null, SAE.SAE_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(SAE.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, SAE.SAE_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(SAE.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, SAE.SAE_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(SAE.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, SAE.SAE_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(SAE.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SAE.SAE_CHARACTERIZATION_VALUE_5 || ',') VALS
        from STM_ANNUAL_EVOLUTION SAE
       where GCO_GOOD_ID = iGoodId;

    cursor lcurExerciseEvolutions(iGoodId number, iCharId number)
    is
      select SPE.STM_EXERCISE_EVOLUTION_ID
           , decode(SPE.GCO_CHARACTERIZATION_ID, iCharId, null, SPE.GCO_CHARACTERIZATION_ID || ',') ||
             decode(SPE.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, SPE.GCO_GCO_CHARACTERIZATION_ID || ',') ||
             decode(SPE.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, SPE.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
             decode(SPE.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, SPE.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
             decode(SPE.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SPE.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
           , decode(SPE.GCO_CHARACTERIZATION_ID, iCharId, null, SPE.SPE_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(SPE.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, SPE.SPE_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(SPE.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, SPE.SPE_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(SPE.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, SPE.SPE_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(SPE.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, SPE.SPE_CHARACTERIZATION_VALUE_5 || ',') VALS
        from STM_EXERCISE_EVOLUTION SPE
       where GCO_GOOD_ID = iGoodId;

    cursor lcurIntercTrsf(iGoodId number, iCharId number)
    is
      select SIS.STM_INTERC_STOCK_TRSF_ID
           , decode(SIS.GCO_CHARACTERIZATION_1_ID, iCharId, null, SIS.GCO_CHARACTERIZATION_1_ID || ',') ||
             decode(SIS.GCO_CHARACTERIZATION_2_ID, iCharId, null, SIS.GCO_CHARACTERIZATION_2_ID || ',') ||
             decode(SIS.GCO_CHARACTERIZATION_3_ID, iCharId, null, SIS.GCO_CHARACTERIZATION_3_ID || ',') ||
             decode(SIS.GCO_CHARACTERIZATION_4_ID, iCharId, null, SIS.GCO_CHARACTERIZATION_4_ID || ',') ||
             decode(SIS.GCO_CHARACTERIZATION_5_ID, iCharId, null, SIS.GCO_CHARACTERIZATION_5_ID || ',') IDS
           , decode(SIS.GCO_CHARACTERIZATION_1_ID, iCharId, null, SIS.SIS_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(SIS.GCO_CHARACTERIZATION_2_ID, iCharId, null, SIS.SIS_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(SIS.GCO_CHARACTERIZATION_3_ID, iCharId, null, SIS.SIS_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(SIS.GCO_CHARACTERIZATION_4_ID, iCharId, null, SIS.SIS_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(SIS.GCO_CHARACTERIZATION_5_ID, iCharId, null, SIS.SIS_CHARACTERIZATION_VALUE_5 || ',') VALS
        from STM_INTERC_STOCK_TRSF SIS
       where GCO_GOOD_ID = iGoodId;

    cursor lcurLotDetail(iGoodId number, iCharId number)
    is
      select FAD.FAL_LOT_DETAIL_ID
           , decode(FAD.GCO_CHARACTERIZATION_ID, iCharId, null, FAD.GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAD.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.GCO_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAD.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAD.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAD.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
           , decode(FAD.GCO_CHARACTERIZATION_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(FAD.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(FAD.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(FAD.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(FAD.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_5 || ',') VALS
        from FAL_LOT_DETAIL FAD
       where GCO_GOOD_ID = iGoodId;

    cursor lcurLotDetailHist(iGoodId number, iCharId number)
    is
      select FAD.FAL_LOT_DETAIL_HIST_ID
           , decode(FAD.GCO_CHARACTERIZATION_ID, iCharId, null, FAD.GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAD.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.GCO_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAD.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAD.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAD.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
           , decode(FAD.GCO_CHARACTERIZATION_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(FAD.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(FAD.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(FAD.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(FAD.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_5 || ',') VALS
        from FAL_LOT_DETAIL_HIST FAD
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFactoryIn(iGoodId number, iCharId number)
    is
      select FAC.FAL_FACTORY_IN_ID
           , decode(FAC.GCO_CHARACTERIZATION_ID, iCharId, null, FAC.GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAC.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.GCO_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAC.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAC.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAC.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
           , decode(FAC.GCO_CHARACTERIZATION_ID, iCharId, null, FAC.IN_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(FAC.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.IN_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(FAC.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.IN_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(FAC.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.IN_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(FAC.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.IN_CHARACTERIZATION_VALUE_5 || ',') VALS
        from FAL_FACTORY_IN FAC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFactoryInHist(iGoodId number, iCharId number)
    is
      select FAC.FAL_FACTORY_IN_HIST_ID
           , decode(FAC.GCO_CHARACTERIZATION_ID, iCharId, null, FAC.GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAC.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.GCO_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAC.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAC.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FAC.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
           , decode(FAC.GCO_CHARACTERIZATION_ID, iCharId, null, FAC.IN_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(FAC.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.IN_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(FAC.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.IN_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(FAC.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.IN_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(FAC.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, FAC.IN_CHARACTERIZATION_VALUE_5 || ',') VALS
        from FAL_FACTORY_IN_HIST FAC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFactoryOut(iGoodId number, iCharId number)
    is
      select FAC.FAL_FACTORY_OUT_ID
           , decode(FAC.GCO_CHARACTERIZATION1_ID, iCharId, null, FAC.GCO_CHARACTERIZATION1_ID || ',') ||
             decode(FAC.GCO_CHARACTERIZATION2_ID, iCharId, null, FAC.GCO_CHARACTERIZATION2_ID || ',') ||
             decode(FAC.GCO_CHARACTERIZATION3_ID, iCharId, null, FAC.GCO_CHARACTERIZATION3_ID || ',') ||
             decode(FAC.GCO_CHARACTERIZATION4_ID, iCharId, null, FAC.GCO_CHARACTERIZATION4_ID || ',') ||
             decode(FAC.GCO_CHARACTERIZATION5_ID, iCharId, null, FAC.GCO_CHARACTERIZATION5_ID || ',') IDS
           , decode(FAC.GCO_CHARACTERIZATION1_ID, iCharId, null, FAC.OUT_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(FAC.GCO_CHARACTERIZATION2_ID, iCharId, null, FAC.OUT_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(FAC.GCO_CHARACTERIZATION3_ID, iCharId, null, FAC.OUT_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(FAC.GCO_CHARACTERIZATION4_ID, iCharId, null, FAC.OUT_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(FAC.GCO_CHARACTERIZATION5_ID, iCharId, null, FAC.OUT_CHARACTERIZATION_VALUE_5 || ',') VALS
        from FAL_FACTORY_OUT FAC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFalDocConsult(iGoodId number, iCharId number)
    is
      select FDC.FAL_DOC_CONSULT_ID
           , decode(FDC.GCO_CHARACTERIZATION1_ID, iCharId, null, FDC.GCO_CHARACTERIZATION1_ID || ',') ||
             decode(FDC.GCO_CHARACTERIZATION2_ID, iCharId, null, FDC.GCO_CHARACTERIZATION2_ID || ',') ||
             decode(FDC.GCO_CHARACTERIZATION3_ID, iCharId, null, FDC.GCO_CHARACTERIZATION3_ID || ',') ||
             decode(FDC.GCO_CHARACTERIZATION4_ID, iCharId, null, FDC.GCO_CHARACTERIZATION4_ID || ',') ||
             decode(FDC.GCO_CHARACTERIZATION5_ID, iCharId, null, FDC.GCO_CHARACTERIZATION5_ID || ',') IDS
           , decode(FDC.GCO_CHARACTERIZATION1_ID, iCharId, null, FDC.FDC_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(FDC.GCO_CHARACTERIZATION2_ID, iCharId, null, FDC.FDC_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(FDC.GCO_CHARACTERIZATION3_ID, iCharId, null, FDC.FDC_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(FDC.GCO_CHARACTERIZATION4_ID, iCharId, null, FDC.FDC_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(FDC.GCO_CHARACTERIZATION5_ID, iCharId, null, FDC.FDC_CHARACTERIZATION_VALUE_5 || ',') VALS
        from FAL_DOC_CONSULT FDC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFalDocConsultHist(iGoodId number, iCharId number)
    is
      select FDC.FAL_DOC_CONSULT_HIST_ID
           , decode(FDC.GCO_CHARACTERIZATION1_ID, iCharId, null, FDC.GCO_CHARACTERIZATION1_ID || ',') ||
             decode(FDC.GCO_CHARACTERIZATION2_ID, iCharId, null, FDC.GCO_CHARACTERIZATION2_ID || ',') ||
             decode(FDC.GCO_CHARACTERIZATION3_ID, iCharId, null, FDC.GCO_CHARACTERIZATION3_ID || ',') ||
             decode(FDC.GCO_CHARACTERIZATION4_ID, iCharId, null, FDC.GCO_CHARACTERIZATION4_ID || ',') ||
             decode(FDC.GCO_CHARACTERIZATION5_ID, iCharId, null, FDC.GCO_CHARACTERIZATION5_ID || ',') IDS
           , decode(FDC.GCO_CHARACTERIZATION1_ID, iCharId, null, FDC.FDC_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(FDC.GCO_CHARACTERIZATION2_ID, iCharId, null, FDC.FDC_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(FDC.GCO_CHARACTERIZATION3_ID, iCharId, null, FDC.FDC_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(FDC.GCO_CHARACTERIZATION4_ID, iCharId, null, FDC.FDC_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(FDC.GCO_CHARACTERIZATION5_ID, iCharId, null, FDC.FDC_CHARACTERIZATION_VALUE_5 || ',') VALS
        from FAL_DOC_CONSULT_HIST FDC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFalDocProp(iGoodId number, iCharId number)
    is
      select FDP.FAL_DOC_PROP_ID
           , decode(FDP.GCO_CHARACTERIZATION1_ID, iCharId, null, FDP.GCO_CHARACTERIZATION1_ID || ',') ||
             decode(FDP.GCO_CHARACTERIZATION2_ID, iCharId, null, FDP.GCO_CHARACTERIZATION2_ID || ',') ||
             decode(FDP.GCO_CHARACTERIZATION3_ID, iCharId, null, FDP.GCO_CHARACTERIZATION3_ID || ',') ||
             decode(FDP.GCO_CHARACTERIZATION4_ID, iCharId, null, FDP.GCO_CHARACTERIZATION4_ID || ',') ||
             decode(FDP.GCO_CHARACTERIZATION5_ID, iCharId, null, FDP.GCO_CHARACTERIZATION5_ID || ',') IDS
           , decode(FDP.GCO_CHARACTERIZATION1_ID, iCharId, null, FDP.FDP_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(FDP.GCO_CHARACTERIZATION2_ID, iCharId, null, FDP.FDP_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(FDP.GCO_CHARACTERIZATION3_ID, iCharId, null, FDP.FDP_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(FDP.GCO_CHARACTERIZATION4_ID, iCharId, null, FDP.FDP_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(FDP.GCO_CHARACTERIZATION5_ID, iCharId, null, FDP.FDP_CHARACTERIZATION_VALUE_5 || ',') VALS
        from FAL_DOC_PROP FDP
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFalLotProp(iGoodId number, iCharId number)
    is
      select FAD.FAL_LOT_PROP_ID
           , decode(FAD.GCO_CHARACTERIZATION1_ID, iCharId, null, FAD.GCO_CHARACTERIZATION1_ID || ',') ||
             decode(FAD.GCO_CHARACTERIZATION2_ID, iCharId, null, FAD.GCO_CHARACTERIZATION2_ID || ',') ||
             decode(FAD.GCO_CHARACTERIZATION3_ID, iCharId, null, FAD.GCO_CHARACTERIZATION3_ID || ',') ||
             decode(FAD.GCO_CHARACTERIZATION4_ID, iCharId, null, FAD.GCO_CHARACTERIZATION4_ID || ',') ||
             decode(FAD.GCO_CHARACTERIZATION5_ID, iCharId, null, FAD.GCO_CHARACTERIZATION5_ID || ',') IDS
           , decode(FAD.GCO_CHARACTERIZATION1_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(FAD.GCO_CHARACTERIZATION2_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(FAD.GCO_CHARACTERIZATION3_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(FAD.GCO_CHARACTERIZATION4_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(FAD.GCO_CHARACTERIZATION5_ID, iCharId, null, FAD.FAD_CHARACTERIZATION_VALUE_5 || ',') VALS
        from FAL_LOT_PROP FAD
       where GCO_GOOD_ID = iGoodId;

    cursor lcurNetworkNeed(iGoodId number, iCharId number)
    is
      select FAN.FAL_NETWORK_NEED_ID
           , decode(FAN.GCO_CHARACTERIZATION1_ID, iCharId, null, FAN.GCO_CHARACTERIZATION1_ID || ',') ||
             decode(FAN.GCO_CHARACTERIZATION2_ID, iCharId, null, FAN.GCO_CHARACTERIZATION2_ID || ',') ||
             decode(FAN.GCO_CHARACTERIZATION3_ID, iCharId, null, FAN.GCO_CHARACTERIZATION3_ID || ',') ||
             decode(FAN.GCO_CHARACTERIZATION4_ID, iCharId, null, FAN.GCO_CHARACTERIZATION4_ID || ',') ||
             decode(FAN.GCO_CHARACTERIZATION5_ID, iCharId, null, FAN.GCO_CHARACTERIZATION5_ID || ',') IDS
           , decode(FAN.GCO_CHARACTERIZATION1_ID, iCharId, null, FAN.FAN_CHAR_VALUE1 || ',') ||
             decode(FAN.GCO_CHARACTERIZATION2_ID, iCharId, null, FAN.FAN_CHAR_VALUE2 || ',') ||
             decode(FAN.GCO_CHARACTERIZATION3_ID, iCharId, null, FAN.FAN_CHAR_VALUE3 || ',') ||
             decode(FAN.GCO_CHARACTERIZATION4_ID, iCharId, null, FAN.FAN_CHAR_VALUE4 || ',') ||
             decode(FAN.GCO_CHARACTERIZATION5_ID, iCharId, null, FAN.FAN_CHAR_VALUE5 || ',') VALS
        from FAL_NETWORK_NEED FAN
       where GCO_GOOD_ID = iGoodId;

    cursor lcurNetworkSupply(iGoodId number, iCharId number)
    is
      select FAN.FAL_NETWORK_SUPPLY_ID
           , decode(FAN.GCO_CHARACTERIZATION1_ID, iCharId, null, FAN.GCO_CHARACTERIZATION1_ID || ',') ||
             decode(FAN.GCO_CHARACTERIZATION2_ID, iCharId, null, FAN.GCO_CHARACTERIZATION2_ID || ',') ||
             decode(FAN.GCO_CHARACTERIZATION3_ID, iCharId, null, FAN.GCO_CHARACTERIZATION3_ID || ',') ||
             decode(FAN.GCO_CHARACTERIZATION4_ID, iCharId, null, FAN.GCO_CHARACTERIZATION4_ID || ',') ||
             decode(FAN.GCO_CHARACTERIZATION5_ID, iCharId, null, FAN.GCO_CHARACTERIZATION5_ID || ',') IDS
           , decode(FAN.GCO_CHARACTERIZATION1_ID, iCharId, null, FAN.FAN_CHAR_VALUE1 || ',') ||
             decode(FAN.GCO_CHARACTERIZATION2_ID, iCharId, null, FAN.FAN_CHAR_VALUE2 || ',') ||
             decode(FAN.GCO_CHARACTERIZATION3_ID, iCharId, null, FAN.FAN_CHAR_VALUE3 || ',') ||
             decode(FAN.GCO_CHARACTERIZATION4_ID, iCharId, null, FAN.FAN_CHAR_VALUE4 || ',') ||
             decode(FAN.GCO_CHARACTERIZATION5_ID, iCharId, null, FAN.FAN_CHAR_VALUE5 || ',') VALS
        from FAL_NETWORK_SUPPLY FAN
       where GCO_GOOD_ID = iGoodId;

    cursor lcurFalOutCBarCode(iGoodId number, iCharId number)
    is
      select FOC.FAL_OUT_COMPO_BARCODE_ID
           , decode(FOC.GCO_CHARACTERIZATION_ID, iCharId, null, FOC.GCO_CHARACTERIZATION_ID || ',') ||
             decode(FOC.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, FOC.GCO_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FOC.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, FOC.GCO2_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FOC.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, FOC.GCO3_GCO_CHARACTERIZATION_ID || ',') ||
             decode(FOC.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, FOC.GCO4_GCO_CHARACTERIZATION_ID || ',') IDS
           , decode(FOC.GCO_CHARACTERIZATION_ID, iCharId, null, FOC.FOC_CHARACTERIZATION_VALUE_1 || ',') ||
             decode(FOC.GCO_GCO_CHARACTERIZATION_ID, iCharId, null, FOC.FOC_CHARACTERIZATION_VALUE_2 || ',') ||
             decode(FOC.GCO2_GCO_CHARACTERIZATION_ID, iCharId, null, FOC.FOC_CHARACTERIZATION_VALUE_3 || ',') ||
             decode(FOC.GCO3_GCO_CHARACTERIZATION_ID, iCharId, null, FOC.FOC_CHARACTERIZATION_VALUE_4 || ',') ||
             decode(FOC.GCO4_GCO_CHARACTERIZATION_ID, iCharId, null, FOC.FOC_CHARACTERIZATION_VALUE_5 || ',') VALS
        from FAL_OUT_COMPO_BARCODE FOC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurAsaRecordRepair(iGoodId number, iCharId number)
    is
      select are.ASA_RECORD_ID
           , decode(are.GCO_CHAR1_ID, iCharId, null, are.GCO_CHAR1_ID || ',') ||
             decode(are.GCO_CHAR2_ID, iCharId, null, are.GCO_CHAR2_ID || ',') ||
             decode(are.GCO_CHAR3_ID, iCharId, null, are.GCO_CHAR3_ID || ',') ||
             decode(are.GCO_CHAR4_ID, iCharId, null, are.GCO_CHAR4_ID || ',') ||
             decode(are.GCO_CHAR5_ID, iCharId, null, are.GCO_CHAR5_ID || ',') IDS
           , decode(are.GCO_CHAR1_ID, iCharId, null, are.ARE_CHAR1_VALUE || ',') ||
             decode(are.GCO_CHAR2_ID, iCharId, null, are.ARE_CHAR2_VALUE || ',') ||
             decode(are.GCO_CHAR3_ID, iCharId, null, are.ARE_CHAR3_VALUE || ',') ||
             decode(are.GCO_CHAR4_ID, iCharId, null, are.ARE_CHAR4_VALUE || ',') ||
             decode(are.GCO_CHAR5_ID, iCharId, null, are.ARE_CHAR5_VALUE || ',') VALS
        from ASA_RECORD are
       where GCO_ASA_TO_REPAIR_ID = iGoodId;

    cursor lcurAsaRecordExchange(iGoodId number, iCharId number)
    is
      select are.ASA_RECORD_ID
           , decode(are.GCO_EXCH_CHAR1_ID, iCharId, null, are.GCO_EXCH_CHAR1_ID || ',') ||
             decode(are.GCO_EXCH_CHAR2_ID, iCharId, null, are.GCO_EXCH_CHAR2_ID || ',') ||
             decode(are.GCO_EXCH_CHAR3_ID, iCharId, null, are.GCO_EXCH_CHAR3_ID || ',') ||
             decode(are.GCO_EXCH_CHAR4_ID, iCharId, null, are.GCO_EXCH_CHAR4_ID || ',') ||
             decode(are.GCO_EXCH_CHAR5_ID, iCharId, null, are.GCO_EXCH_CHAR5_ID || ',') IDS
           , decode(are.GCO_EXCH_CHAR1_ID, iCharId, null, are.ARE_EXCH_CHAR1_VALUE || ',') ||
             decode(are.GCO_EXCH_CHAR2_ID, iCharId, null, are.ARE_EXCH_CHAR2_VALUE || ',') ||
             decode(are.GCO_EXCH_CHAR3_ID, iCharId, null, are.ARE_EXCH_CHAR3_VALUE || ',') ||
             decode(are.GCO_EXCH_CHAR4_ID, iCharId, null, are.ARE_EXCH_CHAR4_VALUE || ',') ||
             decode(are.GCO_EXCH_CHAR5_ID, iCharId, null, are.ARE_EXCH_CHAR5_VALUE || ',') VALS
        from ASA_RECORD are
       where GCO_ASA_EXCHANGE_ID = iGoodId;

    cursor lcurAsaRecordNewGood(iGoodId number, iCharId number)
    is
      select are.ASA_RECORD_ID
           , decode(are.GCO_NEW_CHAR1_ID, iCharId, null, are.GCO_NEW_CHAR1_ID || ',') ||
             decode(are.GCO_NEW_CHAR2_ID, iCharId, null, are.GCO_NEW_CHAR2_ID || ',') ||
             decode(are.GCO_NEW_CHAR3_ID, iCharId, null, are.GCO_NEW_CHAR3_ID || ',') ||
             decode(are.GCO_NEW_CHAR4_ID, iCharId, null, are.GCO_NEW_CHAR4_ID || ',') ||
             decode(are.GCO_NEW_CHAR5_ID, iCharId, null, are.GCO_NEW_CHAR5_ID || ',') IDS
           , decode(are.GCO_NEW_CHAR1_ID, iCharId, null, are.ARE_NEW_CHAR1_VALUE || ',') ||
             decode(are.GCO_NEW_CHAR2_ID, iCharId, null, are.ARE_NEW_CHAR2_VALUE || ',') ||
             decode(are.GCO_NEW_CHAR3_ID, iCharId, null, are.ARE_NEW_CHAR3_VALUE || ',') ||
             decode(are.GCO_NEW_CHAR4_ID, iCharId, null, are.ARE_NEW_CHAR4_VALUE || ',') ||
             decode(are.GCO_NEW_CHAR5_ID, iCharId, null, are.ARE_NEW_CHAR5_VALUE || ',') VALS
        from ASA_RECORD are
       where GCO_NEW_GOOD_ID = iGoodId;

    cursor lcurAsaRecordDetails(iGoodId number, iCharId number)
    is
      select red.ASA_RECORD_DETAIL_ID
           , decode(red.GCO_CHAR1_ID, iCharId, null, red.GCO_CHAR1_ID || ',') ||
             decode(red.GCO_CHAR2_ID, iCharId, null, red.GCO_CHAR2_ID || ',') ||
             decode(red.GCO_CHAR3_ID, iCharId, null, red.GCO_CHAR3_ID || ',') ||
             decode(red.GCO_CHAR4_ID, iCharId, null, red.GCO_CHAR4_ID || ',') ||
             decode(red.GCO_CHAR5_ID, iCharId, null, red.GCO_CHAR5_ID || ',') IDS
           , decode(red.GCO_CHAR1_ID, iCharId, null, red.RED_CHAR1_VALUE || ',') ||
             decode(red.GCO_CHAR2_ID, iCharId, null, red.RED_CHAR2_VALUE || ',') ||
             decode(red.GCO_CHAR3_ID, iCharId, null, red.RED_CHAR3_VALUE || ',') ||
             decode(red.GCO_CHAR4_ID, iCharId, null, red.RED_CHAR4_VALUE || ',') ||
             decode(red.GCO_CHAR5_ID, iCharId, null, red.RED_CHAR5_VALUE || ',') VALS
        from ASA_RECORD are
           , ASA_RECORD_DETAIL red
       where are.GCO_ASA_TO_REPAIR_ID = iGoodId
         and red.ASA_RECORD_ID = are.ASA_RECORD_ID;

    cursor lcurAsaRecordRepDetails(iGoodId number, iCharId number)
    is
      select RRD.ASA_RECORD_REP_DETAIL_ID
           , decode(RRD.GCO_CHAR1_ID, iCharId, null, RRD.GCO_CHAR1_ID || ',') ||
             decode(RRD.GCO_CHAR2_ID, iCharId, null, RRD.GCO_CHAR2_ID || ',') ||
             decode(RRD.GCO_CHAR3_ID, iCharId, null, RRD.GCO_CHAR3_ID || ',') ||
             decode(RRD.GCO_CHAR4_ID, iCharId, null, RRD.GCO_CHAR4_ID || ',') ||
             decode(RRD.GCO_CHAR5_ID, iCharId, null, RRD.GCO_CHAR5_ID || ',') IDS
           , decode(RRD.GCO_CHAR1_ID, iCharId, null, RRD.RRD_NEW_CHAR1_VALUE || ',') ||
             decode(RRD.GCO_CHAR2_ID, iCharId, null, RRD.RRD_NEW_CHAR2_VALUE || ',') ||
             decode(RRD.GCO_CHAR3_ID, iCharId, null, RRD.RRD_NEW_CHAR3_VALUE || ',') ||
             decode(RRD.GCO_CHAR4_ID, iCharId, null, RRD.RRD_NEW_CHAR4_VALUE || ',') ||
             decode(RRD.GCO_CHAR5_ID, iCharId, null, RRD.RRD_NEW_CHAR5_VALUE || ',') VALS
        from ASA_RECORD are
           , ASA_RECORD_DETAIL RED
           , ASA_RECORD_REP_DETAIL RRD
       where are.GCO_ASA_TO_REPAIR_ID = iGoodId
         and RED.ASA_RECORD_ID = are.ASA_RECORD_ID
         and RRD.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID;

    cursor lcurAsaRecordExchDetails(iGoodId number, iCharId number)
    is
      select REX.ASA_RECORD_EXCH_DETAIL_ID
           , decode(REX.GCO_EXCH_CHAR1_ID, iCharId, null, REX.GCO_EXCH_CHAR1_ID || ',') ||
             decode(REX.GCO_EXCH_CHAR2_ID, iCharId, null, REX.GCO_EXCH_CHAR2_ID || ',') ||
             decode(REX.GCO_EXCH_CHAR3_ID, iCharId, null, REX.GCO_EXCH_CHAR3_ID || ',') ||
             decode(REX.GCO_EXCH_CHAR4_ID, iCharId, null, REX.GCO_EXCH_CHAR4_ID || ',') ||
             decode(REX.GCO_EXCH_CHAR5_ID, iCharId, null, REX.GCO_EXCH_CHAR5_ID || ',') IDS
           , decode(REX.GCO_EXCH_CHAR1_ID, iCharId, null, REX.REX_EXCH_CHAR1_VALUE || ',') ||
             decode(REX.GCO_EXCH_CHAR2_ID, iCharId, null, REX.REX_EXCH_CHAR2_VALUE || ',') ||
             decode(REX.GCO_EXCH_CHAR3_ID, iCharId, null, REX.REX_EXCH_CHAR3_VALUE || ',') ||
             decode(REX.GCO_EXCH_CHAR4_ID, iCharId, null, REX.REX_EXCH_CHAR4_VALUE || ',') ||
             decode(REX.GCO_EXCH_CHAR5_ID, iCharId, null, REX.REX_EXCH_CHAR5_VALUE || ',') VALS
        from ASA_RECORD are
           , ASA_RECORD_DETAIL RED
           , ASA_RECORD_EXCH_DETAIL REX
       where are.GCO_ASA_EXCHANGE_ID = iGoodId
         and RED.ASA_RECORD_ID = are.ASA_RECORD_ID
         and REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID;

    cursor lcurAsaRecordComps(iGoodId number, iCharId number)
    is
      select ARC.ASA_RECORD_COMP_ID
           , decode(ARC.GCO_CHAR1_ID, iCharId, null, ARC.GCO_CHAR1_ID || ',') ||
             decode(ARC.GCO_CHAR2_ID, iCharId, null, ARC.GCO_CHAR2_ID || ',') ||
             decode(ARC.GCO_CHAR3_ID, iCharId, null, ARC.GCO_CHAR3_ID || ',') ||
             decode(ARC.GCO_CHAR4_ID, iCharId, null, ARC.GCO_CHAR4_ID || ',') ||
             decode(ARC.GCO_CHAR5_ID, iCharId, null, ARC.GCO_CHAR5_ID || ',') IDS
           , decode(ARC.GCO_CHAR1_ID, iCharId, null, ARC.ARC_CHAR1_VALUE || ',') ||
             decode(ARC.GCO_CHAR2_ID, iCharId, null, ARC.ARC_CHAR2_VALUE || ',') ||
             decode(ARC.GCO_CHAR3_ID, iCharId, null, ARC.ARC_CHAR3_VALUE || ',') ||
             decode(ARC.GCO_CHAR4_ID, iCharId, null, ARC.ARC_CHAR4_VALUE || ',') ||
             decode(ARC.GCO_CHAR5_ID, iCharId, null, ARC.ARC_CHAR5_VALUE || ',') VALS
        from ASA_RECORD_COMP ARC
       where GCO_COMPONENT_ID = iGoodId;

    cursor lcurAsaGuarantyCards(iGoodId number, iCharId number)
    is
      select AGC.ASA_GUARANTY_CARDS_ID
           , decode(AGC.GCO_CHAR1_ID, iCharId, null, AGC.GCO_CHAR1_ID || ',') ||
             decode(AGC.GCO_CHAR2_ID, iCharId, null, AGC.GCO_CHAR2_ID || ',') ||
             decode(AGC.GCO_CHAR3_ID, iCharId, null, AGC.GCO_CHAR3_ID || ',') ||
             decode(AGC.GCO_CHAR4_ID, iCharId, null, AGC.GCO_CHAR4_ID || ',') ||
             decode(AGC.GCO_CHAR5_ID, iCharId, null, AGC.GCO_CHAR5_ID || ',') IDS
           , decode(AGC.GCO_CHAR1_ID, iCharId, null, AGC.AGC_CHAR1_VALUE || ',') ||
             decode(AGC.GCO_CHAR2_ID, iCharId, null, AGC.AGC_CHAR2_VALUE || ',') ||
             decode(AGC.GCO_CHAR3_ID, iCharId, null, AGC.AGC_CHAR3_VALUE || ',') ||
             decode(AGC.GCO_CHAR4_ID, iCharId, null, AGC.AGC_CHAR4_VALUE || ',') ||
             decode(AGC.GCO_CHAR5_ID, iCharId, null, AGC.AGC_CHAR5_VALUE || ',') VALS
        from ASA_GUARANTY_CARDS AGC
       where GCO_GOOD_ID = iGoodId;

    cursor lcurAsaStolenGoods(iGoodId number, iCharId number)
    is
      select ASG.ASA_STOLEN_GOODS_ID
           , decode(ASG.GCO_CHAR1_ID, iCharId, null, ASG.GCO_CHAR1_ID || ',') ||
             decode(ASG.GCO_CHAR2_ID, iCharId, null, ASG.GCO_CHAR2_ID || ',') ||
             decode(ASG.GCO_CHAR3_ID, iCharId, null, ASG.GCO_CHAR3_ID || ',') ||
             decode(ASG.GCO_CHAR4_ID, iCharId, null, ASG.GCO_CHAR4_ID || ',') ||
             decode(ASG.GCO_CHAR5_ID, iCharId, null, ASG.GCO_CHAR5_ID || ',') IDS
           , decode(ASG.GCO_CHAR1_ID, iCharId, null, ASG.ASG_CHAR1_VALUE || ',') ||
             decode(ASG.GCO_CHAR2_ID, iCharId, null, ASG.ASG_CHAR2_VALUE || ',') ||
             decode(ASG.GCO_CHAR3_ID, iCharId, null, ASG.ASG_CHAR3_VALUE || ',') ||
             decode(ASG.GCO_CHAR4_ID, iCharId, null, ASG.ASG_CHAR4_VALUE || ',') ||
             decode(ASG.GCO_CHAR5_ID, iCharId, null, ASG.ASG_CHAR5_VALUE || ',') VALS
        from ASA_STOLEN_GOODS ASG
       where GCO_GOOD_ID = iGoodId;

    cursor crAsaInterventionDetail(iGoodId number, iCharId number)
    is
      select AID.ASA_INTERVENTION_DETAIL_ID
           , decode(AID.GCO_CHAR1_ID, iCharId, null, AID.GCO_CHAR1_ID || ',') ||
             decode(AID.GCO_CHAR2_ID, iCharId, null, AID.GCO_CHAR2_ID || ',') ||
             decode(AID.GCO_CHAR3_ID, iCharId, null, AID.GCO_CHAR3_ID || ',') ||
             decode(AID.GCO_CHAR4_ID, iCharId, null, AID.GCO_CHAR4_ID || ',') ||
             decode(AID.GCO_CHAR5_ID, iCharId, null, AID.GCO_CHAR5_ID || ',') IDS
           , decode(AID.GCO_CHAR1_ID, iCharId, null, AID.AID_CHAR1_VALUE || ',') ||
             decode(AID.GCO_CHAR2_ID, iCharId, null, AID.AID_CHAR2_VALUE || ',') ||
             decode(AID.GCO_CHAR3_ID, iCharId, null, AID.AID_CHAR3_VALUE || ',') ||
             decode(AID.GCO_CHAR4_ID, iCharId, null, AID.AID_CHAR4_VALUE || ',') ||
             decode(AID.GCO_CHAR5_ID, iCharId, null, AID.AID_CHAR5_VALUE || ',') VALS
        from ASA_INTERVENTION_DETAIL AID
       where GCO_GOOD_ID = iGoodId;

    lAtLeastOneElement boolean                                         := false;
    lElementNumberId   STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lCheckIn           number;
    lnPositionID       STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
  begin
    -- Début du mode de maintenance
    gCharManagementMode  := 1;
    -- Init du flag de retour d'erreur
    iError               := 0;

    begin
      select *
        into ltplCharac
        from GCO_CHARACTERIZATION
       where GCO_CHARACTERIZATION_ID = iCharacterizationId;

      -- Log de l'opération
      if not iSilent then
        LogCharacWizardEvent('DEL', iCharacterizationId, ltplCharac.CHA_CHARACTERIZATION_DESIGN, ltplCharac.GCO_GOOD_ID);
      end if;

      -- Suppression des attributions du bien
      FAL_DELETE_ATTRIBS.Delete_All_Attribs(ltplCharac.GCO_GOOD_ID, null, null, 0);

      for tplPDE in lcurPDE(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update DOC_POSITION_DETAIL
           set GCO_CHARACTERIZATION_ID = ExtractLine(tplPDE.IDS, 1, ',')
             , GCO_GCO_CHARACTERIZATION_ID = ExtractLine(tplPDE.IDS, 2, ',')
             , GCO2_GCO_CHARACTERIZATION_ID = ExtractLine(tplPDE.IDS, 3, ',')
             , GCO3_GCO_CHARACTERIZATION_ID = ExtractLine(tplPDE.IDS, 4, ',')
             , GCO4_GCO_CHARACTERIZATION_ID = ExtractLine(tplPDE.IDS, 5, ',')
             , PDE_CHARACTERIZATION_VALUE_1 = ExtractLine(tplPDE.VALS, 1, ',')
             , PDE_CHARACTERIZATION_VALUE_2 = ExtractLine(tplPDE.VALS, 2, ',')
             , PDE_CHARACTERIZATION_VALUE_3 = ExtractLine(tplPDE.VALS, 3, ',')
             , PDE_CHARACTERIZATION_VALUE_4 = ExtractLine(tplPDE.VALS, 4, ',')
             , PDE_CHARACTERIZATION_VALUE_5 = ExtractLine(tplPDE.VALS, 5, ',')
         where DOC_POSITION_DETAIL_ID = tplPDE.DOC_POSITION_DETAIL_ID;
      end loop;

      for tplBarCode in lcurBarCode(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update DOC_BARCODE
           set GCO_CHARACTERIZATION_ID = ExtractLine(tplBarCode.IDS, 1, ',')
             , GCO_GCO_CHARACTERIZATION_ID = ExtractLine(tplBarCode.IDS, 2, ',')
             , GCO2_GCO_CHARACTERIZATION_ID = ExtractLine(tplBarCode.IDS, 3, ',')
             , GCO3_GCO_CHARACTERIZATION_ID = ExtractLine(tplBarCode.IDS, 4, ',')
             , GCO4_GCO_CHARACTERIZATION_ID = ExtractLine(tplBarCode.IDS, 5, ',')
             , DBA_CHARACTERIZATION_VALUE_1 = ExtractLine(tplBarCode.VALS, 1, ',')
             , DBA_CHARACTERIZATION_VALUE_2 = ExtractLine(tplBarCode.VALS, 2, ',')
             , DBA_CHARACTERIZATION_VALUE_3 = ExtractLine(tplBarCode.VALS, 3, ',')
             , DBA_CHARACTERIZATION_VALUE_4 = ExtractLine(tplBarCode.VALS, 4, ',')
             , DBA_CHARACTERIZATION_VALUE_5 = ExtractLine(tplBarCode.VALS, 5, ',')
         where DOC_BARCODE_ID = tplBarCode.DOC_BARCODE_ID;
      end loop;

      -- MAJ des positions de stock
      for tplStockPosition in lcurStockPositions(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        declare
          lChar1Id              STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
          lChar2Id              STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
          lChar3Id              STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
          lChar4Id              STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
          lChar5Id              STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
          lVal1                 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
          lVal2                 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
          lVal3                 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
          lVal4                 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
          lVal5                 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
          lEleNum1              STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
          lEleNum2              STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
          lEleNum3              STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
          lPiece                varchar2(30);
          lSet                  varchar2(30);
          lVersion              varchar2(30);
          lChronological        varchar2(30);
          lCharStd1             varchar2(30);
          lCharStd2             varchar2(30);
          lCharStd3             varchar2(30);
          lCharStd4             varchar2(30);
          lCharStd5             varchar2(30);
          tplCumulStockPosition STM_STOCK_POSITION%rowtype;
        begin
          GCO_I_LIB_CHARACTERIZATION.ClassifyCharacterizations(ExtractLine(tplStockPosition.IDS, 1, ',')
                                                             , ExtractLine(tplStockPosition.IDS, 2, ',')
                                                             , ExtractLine(tplStockPosition.IDS, 3, ',')
                                                             , ExtractLine(tplStockPosition.IDS, 4, ',')
                                                             , ExtractLine(tplStockPosition.IDS, 5, ',')
                                                             , ExtractLine(tplStockPosition.VALS, 1, ',')
                                                             , ExtractLine(tplStockPosition.VALS, 2, ',')
                                                             , ExtractLine(tplStockPosition.VALS, 3, ',')
                                                             , ExtractLine(tplStockPosition.VALS, 4, ',')
                                                             , ExtractLine(tplStockPosition.VALS, 5, ',')
                                                             , lPiece
                                                             , lSet
                                                             , lVersion
                                                             , lChronological
                                                             , lCharStd1
                                                             , lCharStd2
                                                             , lCharStd3
                                                             , lCharStd4
                                                             , lCharStd5
                                                              );
          GCO_LIB_CHARACTERIZATION.convertCharIdToElementNumber(ltplCharac.GCO_GOOD_ID
                                                              , ExtractLine(tplStockPosition.IDS, 1, ',')
                                                              , ExtractLine(tplStockPosition.IDS, 2, ',')
                                                              , ExtractLine(tplStockPosition.IDS, 3, ',')
                                                              , ExtractLine(tplStockPosition.IDS, 4, ',')
                                                              , ExtractLine(tplStockPosition.IDS, 5, ',')
                                                              , ExtractLine(tplStockPosition.VALS, 1, ',')
                                                              , ExtractLine(tplStockPosition.VALS, 2, ',')
                                                              , ExtractLine(tplStockPosition.VALS, 3, ',')
                                                              , ExtractLine(tplStockPosition.VALS, 4, ',')
                                                              , ExtractLine(tplStockPosition.VALS, 5, ',')
                                                              , lEleNum1
                                                              , lEleNum2
                                                              , lEleNum3
                                                               );

          delete from STM_STOCK_POSITION
                where STM_LOCATION_ID = tplStockPosition.STM_LOCATION_ID
                  and GCO_GOOD_ID = ltplCharac.GCO_GOOD_ID
                  and nvl(GCO_CHARACTERIZATION_ID, 0) = nvl(tplStockPosition.GCO_CHARACTERIZATION_ID, 0)
                  and nvl(GCO_GCO_CHARACTERIZATION_ID, 0) = nvl(tplStockPosition.GCO_GCO_CHARACTERIZATION_ID, 0)
                  and nvl(GCO2_GCO_CHARACTERIZATION_ID, 0) = nvl(tplStockPosition.GCO2_GCO_CHARACTERIZATION_ID, 0)
                  and nvl(GCO3_GCO_CHARACTERIZATION_ID, 0) = nvl(tplStockPosition.GCO3_GCO_CHARACTERIZATION_ID, 0)
                  and nvl(GCO4_GCO_CHARACTERIZATION_ID, 0) = nvl(tplStockPosition.GCO4_GCO_CHARACTERIZATION_ID, 0)
                  and (   SPO_CHARACTERIZATION_VALUE_1 = ExtractLine(tplStockPosition.ORIGINAL_VALS, 1, ',')
                       or ExtractLine(tplStockPosition.ORIGINAL_VALS, 1, ',') is null
                      )
                  and (   SPO_CHARACTERIZATION_VALUE_2 = ExtractLine(tplStockPosition.ORIGINAL_VALS, 2, ',')
                       or ExtractLine(tplStockPosition.ORIGINAL_VALS, 2, ',') is null
                      )
                  and (   SPO_CHARACTERIZATION_VALUE_3 = ExtractLine(tplStockPosition.ORIGINAL_VALS, 3, ',')
                       or ExtractLine(tplStockPosition.ORIGINAL_VALS, 3, ',') is null
                      )
                  and (   SPO_CHARACTERIZATION_VALUE_4 = ExtractLine(tplStockPosition.ORIGINAL_VALS, 4, ',')
                       or ExtractLine(tplStockPosition.ORIGINAL_VALS, 4, ',') is null
                      )
                  and (   SPO_CHARACTERIZATION_VALUE_5 = ExtractLine(tplStockPosition.ORIGINAL_VALS, 5, ',')
                       or ExtractLine(tplStockPosition.ORIGINAL_VALS, 5, ',') is null
                      );

          -- Vérifier si la position de stock existe déjà (elle a pu etre crée lors de l'update du PDE )
          begin
            select STM_STOCK_POSITION_ID
              into lnPositionID
              from STM_STOCK_POSITION
             where STM_LOCATION_ID = tplStockPosition.STM_LOCATION_ID
               and GCO_GOOD_ID = tplStockPosition.GCO_GOOD_ID
               and nvl(GCO_CHARACTERIZATION_ID, 0) = nvl(ExtractLine(tplStockPosition.IDS, 1, ','), 0)
               and nvl(GCO_GCO_CHARACTERIZATION_ID, 0) = nvl(ExtractLine(tplStockPosition.IDS, 2, ','), 0)
               and nvl(GCO2_GCO_CHARACTERIZATION_ID, 0) = nvl(ExtractLine(tplStockPosition.IDS, 3, ','), 0)
               and nvl(GCO3_GCO_CHARACTERIZATION_ID, 0) = nvl(ExtractLine(tplStockPosition.IDS, 4, ','), 0)
               and nvl(GCO4_GCO_CHARACTERIZATION_ID, 0) = nvl(ExtractLine(tplStockPosition.IDS, 5, ','), 0)
               and (   SPO_CHARACTERIZATION_VALUE_1 = ExtractLine(tplStockPosition.ORIGINAL_VALS, 1, ',')
                    or ExtractLine(tplStockPosition.ORIGINAL_VALS, 1, ',') is null
                   )
               and (   SPO_CHARACTERIZATION_VALUE_2 = ExtractLine(tplStockPosition.ORIGINAL_VALS, 2, ',')
                    or ExtractLine(tplStockPosition.ORIGINAL_VALS, 2, ',') is null
                   )
               and (   SPO_CHARACTERIZATION_VALUE_3 = ExtractLine(tplStockPosition.ORIGINAL_VALS, 3, ',')
                    or ExtractLine(tplStockPosition.ORIGINAL_VALS, 3, ',') is null
                   )
               and (   SPO_CHARACTERIZATION_VALUE_4 = ExtractLine(tplStockPosition.ORIGINAL_VALS, 4, ',')
                    or ExtractLine(tplStockPosition.ORIGINAL_VALS, 4, ',') is null
                   )
               and (   SPO_CHARACTERIZATION_VALUE_5 = ExtractLine(tplStockPosition.ORIGINAL_VALS, 5, ',')
                    or ExtractLine(tplStockPosition.ORIGINAL_VALS, 5, ',') is null
                   );
          exception
            when no_data_found then
              lnPositionID  := null;
          end;

          if lnPositionID is not null then
            -- update
            update STM_STOCK_POSITION
               set SPO_STOCK_QUANTITY = SPO_STOCK_QUANTITY + tplStockPosition.SPO_STOCK_QUANTITY
                 , SPO_ASSIGN_QUANTITY = SPO_ASSIGN_QUANTITY + tplStockPosition.SPO_ASSIGN_QUANTITY
                 , SPO_PROVISORY_INPUT = SPO_PROVISORY_INPUT + tplStockPosition.SPO_PROVISORY_INPUT
                 , SPO_PROVISORY_OUTPUT = SPO_PROVISORY_OUTPUT + tplStockPosition.SPO_PROVISORY_OUTPUT
                 , SPO_AVAILABLE_QUANTITY = SPO_AVAILABLE_QUANTITY + tplStockPosition.SPO_AVAILABLE_QUANTITY
                 , SPO_THEORETICAL_QUANTITY = SPO_THEORETICAL_QUANTITY + tplStockPosition.SPO_THEORETICAL_QUANTITY
                 , SPO_ALTERNATIV_QUANTITY_1 = SPO_ALTERNATIV_QUANTITY_1 + tplStockPosition.SPO_ALTERNATIV_QUANTITY_1
                 , SPO_ALTERNATIV_QUANTITY_2 = SPO_ALTERNATIV_QUANTITY_2 + tplStockPosition.SPO_ALTERNATIV_QUANTITY_2
                 , SPO_ALTERNATIV_QUANTITY_3 = SPO_ALTERNATIV_QUANTITY_3 + tplStockPosition.SPO_ALTERNATIV_QUANTITY_3
                 , STM_ELEMENT_NUMBER_ID = lEleNum1
                 , STM_STM_ELEMENT_NUMBER_ID = lEleNum2
                 , STM2_STM_ELEMENT_NUMBER_ID = lEleNum3
                 , A_IDMOD = 'PCS'
                 , A_DATEMOD = sysdate
             where STM_STOCK_POSITION_ID = lnPositionID;
          else
            -- insert
            insert into STM_STOCK_POSITION
                        (STM_STOCK_POSITION_ID
                       , C_POSITION_STATUS
                       , GCO_GOOD_ID
                       , STM_STOCK_ID
                       , STM_LOCATION_ID
                       , STM_LAST_STOCK_MOVE_ID
                       , SPO_STOCK_QUANTITY
                       , SPO_ASSIGN_QUANTITY
                       , SPO_PROVISORY_INPUT
                       , SPO_PROVISORY_OUTPUT
                       , SPO_AVAILABLE_QUANTITY
                       , SPO_THEORETICAL_QUANTITY
                       , SPO_ALTERNATIV_QUANTITY_1
                       , SPO_ALTERNATIV_QUANTITY_2
                       , SPO_ALTERNATIV_QUANTITY_3
                       , SPO_LAST_INVENTORY_DATE
                       , GCO_CHARACTERIZATION_ID
                       , GCO_GCO_CHARACTERIZATION_ID
                       , GCO2_GCO_CHARACTERIZATION_ID
                       , GCO3_GCO_CHARACTERIZATION_ID
                       , GCO4_GCO_CHARACTERIZATION_ID
                       , SPO_CHARACTERIZATION_VALUE_1
                       , SPO_CHARACTERIZATION_VALUE_2
                       , SPO_CHARACTERIZATION_VALUE_3
                       , SPO_CHARACTERIZATION_VALUE_4
                       , SPO_CHARACTERIZATION_VALUE_5
                       , STM_ELEMENT_NUMBER_ID
                       , STM_STM_ELEMENT_NUMBER_ID
                       , STM2_STM_ELEMENT_NUMBER_ID
                       , A_DATECRE
                       , A_DATEMOD
                       , A_IDCRE
                       , A_IDMOD
                       , A_RECSTATUS
                        )
              select init_id_seq.nextval
                   , tplStockPosition.C_POSITION_STATUS
                   , tplStockPosition.GCO_GOOD_ID
                   , tplStockPosition.STM_STOCK_ID
                   , tplStockPosition.STM_LOCATION_ID
                   , tplStockPosition.STM_LAST_STOCK_MOVE_ID
                   , tplStockPosition.SPO_STOCK_QUANTITY
                   , tplStockPosition.SPO_ASSIGN_QUANTITY
                   , tplStockPosition.SPO_PROVISORY_INPUT
                   , tplStockPosition.SPO_PROVISORY_OUTPUT
                   , tplStockPosition.SPO_AVAILABLE_QUANTITY
                   , tplStockPosition.SPO_THEORETICAL_QUANTITY
                   , tplStockPosition.SPO_ALTERNATIV_QUANTITY_1
                   , tplStockPosition.SPO_ALTERNATIV_QUANTITY_2
                   , tplStockPosition.SPO_ALTERNATIV_QUANTITY_3
                   , tplStockPosition.SPO_LAST_INVENTORY_DATE
                   , ExtractLine(tplStockPosition.IDS, 1, ',')
                   , ExtractLine(tplStockPosition.IDS, 2, ',')
                   , ExtractLine(tplStockPosition.IDS, 3, ',')
                   , ExtractLine(tplStockPosition.IDS, 4, ',')
                   , ExtractLine(tplStockPosition.IDS, 5, ',')
                   , ExtractLine(tplStockPosition.VALS, 1, ',')
                   , ExtractLine(tplStockPosition.VALS, 2, ',')
                   , ExtractLine(tplStockPosition.VALS, 3, ',')
                   , ExtractLine(tplStockPosition.VALS, 4, ',')
                   , ExtractLine(tplStockPosition.VALS, 5, ',')
                   , lEleNum1
                   , lEleNum2
                   , lEleNum3
                   , tplStockPosition.A_DATECRE
                   , tplStockPosition.A_DATEMOD
                   , 'PCS'
                   , 'PCS'
                   , '1'
                from dual;
          end if;
        end;
      end loop;

      -- MAJ des mouvements de stock
      for tplStockMovement in lcurStockMovements(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        declare
          lPiece         FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lSet           FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lVersion       FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lChronological FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lCharStd1      FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lCharStd2      FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lCharStd3      FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lCharStd4      FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lCharStd5      FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
        begin
          -- Mise à jour des champs dénormalisé d'affichage des caractérisations
          GCO_I_LIB_CHARACTERIZATION.ClassifyCharacterizations(ExtractLine(tplStockMovement.IDS, 1, ',')
                                                             , ExtractLine(tplStockMovement.IDS, 2, ',')
                                                             , ExtractLine(tplStockMovement.IDS, 3, ',')
                                                             , ExtractLine(tplStockMovement.IDS, 4, ',')
                                                             , ExtractLine(tplStockMovement.IDS, 5, ',')
                                                             , ExtractLine(tplStockMovement.VALS, 1, ',')
                                                             , ExtractLine(tplStockMovement.VALS, 2, ',')
                                                             , ExtractLine(tplStockMovement.VALS, 3, ',')
                                                             , ExtractLine(tplStockMovement.VALS, 4, ',')
                                                             , ExtractLine(tplStockMovement.VALS, 5, ',')
                                                             , lPiece
                                                             , lSet
                                                             , lVersion
                                                             , lChronological
                                                             , lCharStd1
                                                             , lCharStd2
                                                             , lCharStd3
                                                             , lCharStd4
                                                             , lCharStd5
                                                              );

          declare
            lCRUD_DEF fwk_i_typ_definition.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement
                               , lCRUD_DEF
                               , false
                               , tplStockMovement.STM_STOCK_MOVEMENT_ID
                               , null
                               , 'STM_STOCK_MOVEMENT_ID'
                                );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', tplStockMovement.STM_STOCK_MOVEMENT_ID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO_CHARACTERIZATION_ID', ExtractLine(tplStockMovement.IDS, 1, ',') );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO_GCO_CHARACTERIZATION_ID', ExtractLine(tplStockMovement.IDS, 2, ',') );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO2_GCO_CHARACTERIZATION_ID', ExtractLine(tplStockMovement.IDS, 3, ',') );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO3_GCO_CHARACTERIZATION_ID', ExtractLine(tplStockMovement.IDS, 4, ',') );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO4_GCO_CHARACTERIZATION_ID', ExtractLine(tplStockMovement.IDS, 5, ',') );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_CHARACTERIZATION_VALUE_1', ExtractLine(tplStockMovement.VALS, 1, ',') );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_CHARACTERIZATION_VALUE_2', ExtractLine(tplStockMovement.VALS, 2, ',') );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_CHARACTERIZATION_VALUE_3', ExtractLine(tplStockMovement.VALS, 3, ',') );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_CHARACTERIZATION_VALUE_4', ExtractLine(tplStockMovement.VALS, 4, ',') );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_CHARACTERIZATION_VALUE_5', ExtractLine(tplStockMovement.VALS, 5, ',') );
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_PIECE', lPiece);
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_SET', lSet);
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_VERSION', lVersion);
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_CHRONOLOGICAL', lChronological);
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_STD_CHAR_1', lCharStd1);
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_STD_CHAR_2', lCharStd2);
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_STD_CHAR_3', lCharStd3);
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_STD_CHAR_4', lCharStd4);
            FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'SMO_STD_CHAR_5', lCharStd5);
            FWK_I_MGT_ENTITY.UpdateEntity(lCRUD_DEF);
            FWK_I_MGT_ENTITY.Release(lCRUD_DEF);
          end;
        end;
      end loop;

      -- MAJ des évolutions annuelles
      for tplAnnualEvolution in lcurAnnualEvolutions(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update STM_ANNUAL_EVOLUTION
           set GCO_CHARACTERIZATION_ID = ExtractLine(tplAnnualEvolution.IDS, 1, ',')
             , GCO_GCO_CHARACTERIZATION_ID = ExtractLine(tplAnnualEvolution.IDS, 2, ',')
             , GCO2_GCO_CHARACTERIZATION_ID = ExtractLine(tplAnnualEvolution.IDS, 3, ',')
             , GCO3_GCO_CHARACTERIZATION_ID = ExtractLine(tplAnnualEvolution.IDS, 4, ',')
             , GCO4_GCO_CHARACTERIZATION_ID = ExtractLine(tplAnnualEvolution.IDS, 5, ',')
             , SAE_CHARACTERIZATION_VALUE_1 = ExtractLine(tplAnnualEvolution.VALS, 1, ',')
             , SAE_CHARACTERIZATION_VALUE_2 = ExtractLine(tplAnnualEvolution.VALS, 2, ',')
             , SAE_CHARACTERIZATION_VALUE_3 = ExtractLine(tplAnnualEvolution.VALS, 3, ',')
             , SAE_CHARACTERIZATION_VALUE_4 = ExtractLine(tplAnnualEvolution.VALS, 4, ',')
             , SAE_CHARACTERIZATION_VALUE_5 = ExtractLine(tplAnnualEvolution.VALS, 5, ',')
         where STM_ANNUAL_EVOLUTION_ID = tplAnnualEvolution.STM_ANNUAL_EVOLUTION_ID;
      end loop;

      -- MAJ des évolutions exercice
      for tplExerciseEvolution in lcurExerciseEvolutions(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update STM_EXERCISE_EVOLUTION
           set GCO_CHARACTERIZATION_ID = ExtractLine(tplExerciseEvolution.IDS, 1, ',')
             , GCO_GCO_CHARACTERIZATION_ID = ExtractLine(tplExerciseEvolution.IDS, 2, ',')
             , GCO2_GCO_CHARACTERIZATION_ID = ExtractLine(tplExerciseEvolution.IDS, 3, ',')
             , GCO3_GCO_CHARACTERIZATION_ID = ExtractLine(tplExerciseEvolution.IDS, 4, ',')
             , GCO4_GCO_CHARACTERIZATION_ID = ExtractLine(tplExerciseEvolution.IDS, 5, ',')
             , SPE_CHARACTERIZATION_VALUE_1 = ExtractLine(tplExerciseEvolution.VALS, 1, ',')
             , SPE_CHARACTERIZATION_VALUE_2 = ExtractLine(tplExerciseEvolution.VALS, 2, ',')
             , SPE_CHARACTERIZATION_VALUE_3 = ExtractLine(tplExerciseEvolution.VALS, 3, ',')
             , SPE_CHARACTERIZATION_VALUE_4 = ExtractLine(tplExerciseEvolution.VALS, 4, ',')
             , SPE_CHARACTERIZATION_VALUE_5 = ExtractLine(tplExerciseEvolution.VALS, 5, ',')
         where STM_EXERCISE_EVOLUTION_ID = tplExerciseEvolution.STM_EXERCISE_EVOLUTION_ID;
      end loop;

      -- MAJ des transfert stock inter-sociétés
      for tplIntercTrsf in lcurIntercTrsf(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update STM_INTERC_STOCK_TRSF
           set GCO_CHARACTERIZATION_1_ID = ExtractLine(tplIntercTrsf.IDS, 1, ',')
             , GCO_CHARACTERIZATION_2_ID = ExtractLine(tplIntercTrsf.IDS, 2, ',')
             , GCO_CHARACTERIZATION_3_ID = ExtractLine(tplIntercTrsf.IDS, 3, ',')
             , GCO_CHARACTERIZATION_4_ID = ExtractLine(tplIntercTrsf.IDS, 4, ',')
             , GCO_CHARACTERIZATION_5_ID = ExtractLine(tplIntercTrsf.IDS, 5, ',')
             , SIS_CHARACTERIZATION_VALUE_1 = ExtractLine(tplIntercTrsf.VALS, 1, ',')
             , SIS_CHARACTERIZATION_VALUE_2 = ExtractLine(tplIntercTrsf.VALS, 2, ',')
             , SIS_CHARACTERIZATION_VALUE_3 = ExtractLine(tplIntercTrsf.VALS, 3, ',')
             , SIS_CHARACTERIZATION_VALUE_4 = ExtractLine(tplIntercTrsf.VALS, 4, ',')
             , SIS_CHARACTERIZATION_VALUE_5 = ExtractLine(tplIntercTrsf.VALS, 5, ',')
         where STM_INTERC_STOCK_TRSF_ID = tplIntercTrsf.STM_INTERC_STOCK_TRSF_ID;
      end loop;

      -- maj des détails lots
      for tplLotDetail in lcurLotDetail(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update FAL_LOT_DETAIL
           set GCO_CHARACTERIZATION_ID = ExtractLine(tplLotDetail.IDS, 1, ',')
             , GCO_GCO_CHARACTERIZATION_ID = ExtractLine(tplLotDetail.IDS, 2, ',')
             , GCO2_GCO_CHARACTERIZATION_ID = ExtractLine(tplLotDetail.IDS, 3, ',')
             , GCO3_GCO_CHARACTERIZATION_ID = ExtractLine(tplLotDetail.IDS, 4, ',')
             , GCO4_GCO_CHARACTERIZATION_ID = ExtractLine(tplLotDetail.IDS, 5, ',')
             , FAD_CHARACTERIZATION_VALUE_1 = ExtractLine(tplLotDetail.VALS, 1, ',')
             , FAD_CHARACTERIZATION_VALUE_2 = ExtractLine(tplLotDetail.VALS, 2, ',')
             , FAD_CHARACTERIZATION_VALUE_3 = ExtractLine(tplLotDetail.VALS, 3, ',')
             , FAD_CHARACTERIZATION_VALUE_4 = ExtractLine(tplLotDetail.VALS, 4, ',')
             , FAD_CHARACTERIZATION_VALUE_5 = ExtractLine(tplLotDetail.VALS, 5, ',')
         where FAL_LOT_DETAIL_ID = tplLotDetail.FAL_LOT_DETAIL_ID;
      end loop;

      -- maj des historique de détails lots
      for tplLotDetailHist in lcurLotDetailHist(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update FAL_LOT_DETAIL_HIST
           set GCO_CHARACTERIZATION_ID = ExtractLine(tplLotDetailHist.IDS, 1, ',')
             , GCO_GCO_CHARACTERIZATION_ID = ExtractLine(tplLotDetailHist.IDS, 2, ',')
             , GCO2_GCO_CHARACTERIZATION_ID = ExtractLine(tplLotDetailHist.IDS, 3, ',')
             , GCO3_GCO_CHARACTERIZATION_ID = ExtractLine(tplLotDetailHist.IDS, 4, ',')
             , GCO4_GCO_CHARACTERIZATION_ID = ExtractLine(tplLotDetailHist.IDS, 5, ',')
             , FAD_CHARACTERIZATION_VALUE_1 = ExtractLine(tplLotDetailHist.VALS, 1, ',')
             , FAD_CHARACTERIZATION_VALUE_2 = ExtractLine(tplLotDetailHist.VALS, 2, ',')
             , FAD_CHARACTERIZATION_VALUE_3 = ExtractLine(tplLotDetailHist.VALS, 3, ',')
             , FAD_CHARACTERIZATION_VALUE_4 = ExtractLine(tplLotDetailHist.VALS, 4, ',')
             , FAD_CHARACTERIZATION_VALUE_5 = ExtractLine(tplLotDetailHist.VALS, 5, ',')
         where FAL_LOT_DETAIL_HIST_ID = tplLotDetailHist.FAL_LOT_DETAIL_HIST_ID;
      end loop;

      -- maj des approvisionnement
      for tplNetworkSupply in lcurNetworkSupply(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update FAL_NETWORK_SUPPLY
           set GCO_CHARACTERIZATION1_ID = ExtractLine(tplNetworkSupply.IDS, 1, ',')
             , GCO_CHARACTERIZATION2_ID = ExtractLine(tplNetworkSupply.IDS, 2, ',')
             , GCO_CHARACTERIZATION3_ID = ExtractLine(tplNetworkSupply.IDS, 3, ',')
             , GCO_CHARACTERIZATION4_ID = ExtractLine(tplNetworkSupply.IDS, 4, ',')
             , GCO_CHARACTERIZATION5_ID = ExtractLine(tplNetworkSupply.IDS, 5, ',')
             , FAN_CHAR_VALUE1 = ExtractLine(tplNetworkSupply.VALS, 1, ',')
             , FAN_CHAR_VALUE2 = ExtractLine(tplNetworkSupply.VALS, 2, ',')
             , FAN_CHAR_VALUE3 = ExtractLine(tplNetworkSupply.VALS, 3, ',')
             , FAN_CHAR_VALUE4 = ExtractLine(tplNetworkSupply.VALS, 4, ',')
             , FAN_CHAR_VALUE5 = ExtractLine(tplNetworkSupply.VALS, 5, ',')
         where FAL_NETWORK_SUPPLY_ID = tplNetworkSupply.FAL_NETWORK_SUPPLY_ID;
      end loop;

      -- MAJ des besoins
      for tplNetworkNeed in lcurNetworkNeed(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update FAL_NETWORK_NEED
           set GCO_CHARACTERIZATION1_ID = ExtractLine(tplNetworkNeed.IDS, 1, ',')
             , GCO_CHARACTERIZATION2_ID = ExtractLine(tplNetworkNeed.IDS, 2, ',')
             , GCO_CHARACTERIZATION3_ID = ExtractLine(tplNetworkNeed.IDS, 3, ',')
             , GCO_CHARACTERIZATION4_ID = ExtractLine(tplNetworkNeed.IDS, 4, ',')
             , GCO_CHARACTERIZATION5_ID = ExtractLine(tplNetworkNeed.IDS, 5, ',')
             , FAN_CHAR_VALUE1 = ExtractLine(tplNetworkNeed.VALS, 1, ',')
             , FAN_CHAR_VALUE2 = ExtractLine(tplNetworkNeed.VALS, 2, ',')
             , FAN_CHAR_VALUE3 = ExtractLine(tplNetworkNeed.VALS, 3, ',')
             , FAN_CHAR_VALUE4 = ExtractLine(tplNetworkNeed.VALS, 4, ',')
             , FAN_CHAR_VALUE5 = ExtractLine(tplNetworkNeed.VALS, 5, ',')
         where FAL_NETWORK_NEED_ID = tplNetworkNeed.FAL_NETWORK_NEED_ID;
      end loop;

      -- MAJ des composants d'OF
      for tplFactoryIn in lcurFactoryIn(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        declare
          lChar1Id FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
          lChar2Id FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
          lChar3Id FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
          lChar4Id FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
          lChar5Id FAL_FACTORY_IN.GCO_CHARACTERIZATION_ID%type;
          lVal1    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lVal2    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lVal3    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lVal4    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lVal5    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lPiece   FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lSet     FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lVersion FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lChrono  FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lStd1    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lStd2    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lStd3    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lStd4    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
          lStd5    FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type;
        begin
          -- dénormalisation des caractérisations
          GCO_I_LIB_CHARACTERIZATION.ClassifyCharacterizations(ExtractLine(tplFactoryIn.IDS, 1, ',')
                                                             , ExtractLine(tplFactoryIn.IDS, 2, ',')
                                                             , ExtractLine(tplFactoryIn.IDS, 3, ',')
                                                             , ExtractLine(tplFactoryIn.IDS, 4, ',')
                                                             , ExtractLine(tplFactoryIn.IDS, 5, ',')
                                                             , ExtractLine(tplFactoryIn.VALS, 1, ',')
                                                             , ExtractLine(tplFactoryIn.VALS, 2, ',')
                                                             , ExtractLine(tplFactoryIn.VALS, 3, ',')
                                                             , ExtractLine(tplFactoryIn.VALS, 4, ',')
                                                             , ExtractLine(tplFactoryIn.VALS, 5, ',')
                                                             , lPiece
                                                             , lSet
                                                             , lVersion
                                                             , lChrono
                                                             , lStd1
                                                             , lStd2
                                                             , lStd3
                                                             , lStd4
                                                             , lStd5
                                                              );

          update FAL_FACTORY_IN MAIN
             set GCO_CHARACTERIZATION_ID = ExtractLine(tplFactoryIn.IDS, 1, ',')
               , GCO_GCO_CHARACTERIZATION_ID = ExtractLine(tplFactoryIn.IDS, 2, ',')
               , GCO2_GCO_CHARACTERIZATION_ID = ExtractLine(tplFactoryIn.IDS, 3, ',')
               , GCO3_GCO_CHARACTERIZATION_ID = ExtractLine(tplFactoryIn.IDS, 4, ',')
               , GCO4_GCO_CHARACTERIZATION_ID = ExtractLine(tplFactoryIn.IDS, 5, ',')
               , IN_CHARACTERIZATION_VALUE_1 = ExtractLine(tplFactoryIn.VALS, 1, ',')
               , IN_CHARACTERIZATION_VALUE_2 = ExtractLine(tplFactoryIn.VALS, 2, ',')
               , IN_CHARACTERIZATION_VALUE_3 = ExtractLine(tplFactoryIn.VALS, 3, ',')
               , IN_CHARACTERIZATION_VALUE_4 = ExtractLine(tplFactoryIn.VALS, 4, ',')
               , IN_CHARACTERIZATION_VALUE_5 = ExtractLine(tplFactoryIn.VALS, 5, ',')
               , IN_VERSION = lVersion
               , IN_LOT = lSet
               , IN_PIECE = lPiece
               , IN_CHRONOLOGY = lChrono
               , IN_STD_CHAR_1 = lStd1
               , IN_STD_CHAR_2 = lStd2
               , IN_STD_CHAR_3 = lStd3
               , IN_STD_CHAR_4 = lStd4
               , IN_STD_CHAR_5 = lStd5
               , STM_STOCK_POSITION_ID =
                   (select STM_STOCK_POSITION_ID
                      from STM_STOCK_POSITION
                     where GCO_GOOD_ID = MAIN.GCO_GOOD_ID
                       and STM_LOCATION_ID = MAIN.STM_LOCATION_ID
                       and nvl(SPO_CHARACTERIZATION_VALUE_1, 'NULL') = nvl(ExtractLine(tplFactoryIn.VALS, 1, ','), 'NULL')
                       and nvl(SPO_CHARACTERIZATION_VALUE_2, 'NULL') = nvl(ExtractLine(tplFactoryIn.VALS, 2, ','), 'NULL')
                       and nvl(SPO_CHARACTERIZATION_VALUE_3, 'NULL') = nvl(ExtractLine(tplFactoryIn.VALS, 3, ','), 'NULL')
                       and nvl(SPO_CHARACTERIZATION_VALUE_4, 'NULL') = nvl(ExtractLine(tplFactoryIn.VALS, 4, ','), 'NULL')
                       and nvl(SPO_CHARACTERIZATION_VALUE_5, 'NULL') = nvl(ExtractLine(tplFactoryIn.VALS, 5, ','), 'NULL') )
           where FAL_FACTORY_IN_ID = tplFactoryIn.FAL_FACTORY_IN_ID;
        end;
      end loop;

      -- MAJ des composants d'OF
      for tplFactoryInHist in lcurFactoryInHist(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        declare
          lPiece   FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
          lSet     FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
          lVersion FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
          lChrono  FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
          lStd1    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
          lStd2    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
          lStd3    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
          lStd4    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
          lStd5    FAL_FACTORY_IN_HIST.IN_CHARACTERIZATION_VALUE_1%type;
        begin
          -- dénormalisation des caractérisations
          GCO_I_LIB_CHARACTERIZATION.ClassifyCharacterizations(ExtractLine(tplFactoryInHist.IDS, 1, ',')
                                                             , ExtractLine(tplFactoryInHist.IDS, 2, ',')
                                                             , ExtractLine(tplFactoryInHist.IDS, 3, ',')
                                                             , ExtractLine(tplFactoryInHist.IDS, 4, ',')
                                                             , ExtractLine(tplFactoryInHist.IDS, 5, ',')
                                                             , ExtractLine(tplFactoryInHist.VALS, 1, ',')
                                                             , ExtractLine(tplFactoryInHist.VALS, 2, ',')
                                                             , ExtractLine(tplFactoryInHist.VALS, 3, ',')
                                                             , ExtractLine(tplFactoryInHist.VALS, 4, ',')
                                                             , ExtractLine(tplFactoryInHist.VALS, 5, ',')
                                                             , lPiece
                                                             , lSet
                                                             , lVersion
                                                             , lChrono
                                                             , lStd1
                                                             , lStd2
                                                             , lStd3
                                                             , lStd4
                                                             , lStd5
                                                              );

          update FAL_FACTORY_IN_HIST
             set GCO_CHARACTERIZATION_ID = ExtractLine(tplFactoryInHist.IDS, 1, ',')
               , GCO_GCO_CHARACTERIZATION_ID = ExtractLine(tplFactoryInHist.IDS, 2, ',')
               , GCO2_GCO_CHARACTERIZATION_ID = ExtractLine(tplFactoryInHist.IDS, 3, ',')
               , GCO3_GCO_CHARACTERIZATION_ID = ExtractLine(tplFactoryInHist.IDS, 4, ',')
               , GCO4_GCO_CHARACTERIZATION_ID = ExtractLine(tplFactoryInHist.IDS, 5, ',')
               , IN_CHARACTERIZATION_VALUE_1 = ExtractLine(tplFactoryInHist.VALS, 1, ',')
               , IN_CHARACTERIZATION_VALUE_2 = ExtractLine(tplFactoryInHist.VALS, 2, ',')
               , IN_CHARACTERIZATION_VALUE_3 = ExtractLine(tplFactoryInHist.VALS, 3, ',')
               , IN_CHARACTERIZATION_VALUE_4 = ExtractLine(tplFactoryInHist.VALS, 4, ',')
               , IN_CHARACTERIZATION_VALUE_5 = ExtractLine(tplFactoryInHist.VALS, 5, ',')
               , IN_VERSION = lVersion
               , IN_LOT = lSet
               , IN_PIECE = lPiece
               , IN_CHRONOLOGY = lChrono
               , IN_STD_CHAR_1 = lStd1
               , IN_STD_CHAR_2 = lStd2
               , IN_STD_CHAR_3 = lStd3
               , IN_STD_CHAR_4 = lStd4
               , IN_STD_CHAR_5 = lStd5
           where FAL_FACTORY_IN_HIST_ID = tplFactoryInHist.FAL_FACTORY_IN_HIST_ID;
        end;
      end loop;

      -- MAJ des composants d'OF
      for tplFactoryOut in lcurFactoryOut(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        declare
          lChar1Id FAL_FACTORY_OUT.GCO_CHARACTERIZATION1_ID%type;
          lChar2Id FAL_FACTORY_OUT.GCO_CHARACTERIZATION2_ID%type;
          lChar3Id FAL_FACTORY_OUT.GCO_CHARACTERIZATION3_ID%type;
          lChar4Id FAL_FACTORY_OUT.GCO_CHARACTERIZATION4_ID%type;
          lChar5Id FAL_FACTORY_OUT.GCO_CHARACTERIZATION5_ID%type;
          lVal1    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lVal2    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lVal3    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lVal4    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lVal5    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lPiece   FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lSet     FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lVersion FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lChrono  FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lStd1    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lStd2    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lStd3    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lStd4    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
          lStd5    FAL_FACTORY_OUT.OUT_CHARACTERIZATION_VALUE_1%type;
        begin
          -- dénormalisation des caractérisations
          GCO_I_LIB_CHARACTERIZATION.ClassifyCharacterizations(ExtractLine(tplFactoryOut.IDS, 1, ',')
                                                             , ExtractLine(tplFactoryOut.IDS, 2, ',')
                                                             , ExtractLine(tplFactoryOut.IDS, 3, ',')
                                                             , ExtractLine(tplFactoryOut.IDS, 4, ',')
                                                             , ExtractLine(tplFactoryOut.IDS, 5, ',')
                                                             , ExtractLine(tplFactoryOut.VALS, 1, ',')
                                                             , ExtractLine(tplFactoryOut.VALS, 2, ',')
                                                             , ExtractLine(tplFactoryOut.VALS, 3, ',')
                                                             , ExtractLine(tplFactoryOut.VALS, 4, ',')
                                                             , ExtractLine(tplFactoryOut.VALS, 5, ',')
                                                             , lPiece
                                                             , lSet
                                                             , lVersion
                                                             , lChrono
                                                             , lStd1
                                                             , lStd2
                                                             , lStd3
                                                             , lStd4
                                                             , lStd5
                                                              );

          update FAL_FACTORY_OUT MAIN
             set GCO_CHARACTERIZATION1_ID = ExtractLine(tplFactoryOut.IDS, 1, ',')
               , GCO_CHARACTERIZATION2_ID = ExtractLine(tplFactoryOut.IDS, 2, ',')
               , GCO_CHARACTERIZATION3_ID = ExtractLine(tplFactoryOut.IDS, 3, ',')
               , GCO_CHARACTERIZATION4_ID = ExtractLine(tplFactoryOut.IDS, 4, ',')
               , GCO_CHARACTERIZATION5_ID = ExtractLine(tplFactoryOut.IDS, 5, ',')
               , OUT_CHARACTERIZATION_VALUE_1 = ExtractLine(tplFactoryOut.VALS, 1, ',')
               , OUT_CHARACTERIZATION_VALUE_2 = ExtractLine(tplFactoryOut.VALS, 2, ',')
               , OUT_CHARACTERIZATION_VALUE_3 = ExtractLine(tplFactoryOut.VALS, 3, ',')
               , OUT_CHARACTERIZATION_VALUE_4 = ExtractLine(tplFactoryOut.VALS, 4, ',')
               , OUT_CHARACTERIZATION_VALUE_5 = ExtractLine(tplFactoryOut.VALS, 5, ',')
               , OUT_VERSION = lVersion
               , OUT_LOT = lSet
               , OUT_PIECE = lPiece
               , OUT_CHRONOLOGY = lChrono
               , OUT_STD_CHAR_1 = lStd1
               , OUT_STD_CHAR_2 = lStd2
               , OUT_STD_CHAR_3 = lStd3
               , OUT_STD_CHAR_4 = lStd4
               , OUT_STD_CHAR_5 = lStd5
           where FAL_FACTORY_OUT_ID = tplFactoryOut.FAL_FACTORY_OUT_ID;
        end;
      end loop;

      -- MAJ FAL_DOC_CONSULT
      for tplFalDocConsult in lcurFalDocConsult(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update FAL_DOC_CONSULT
           set GCO_CHARACTERIZATION1_ID = ExtractLine(tplFalDocConsult.IDS, 1, ',')
             , GCO_CHARACTERIZATION2_ID = ExtractLine(tplFalDocConsult.IDS, 2, ',')
             , GCO_CHARACTERIZATION3_ID = ExtractLine(tplFalDocConsult.IDS, 3, ',')
             , GCO_CHARACTERIZATION4_ID = ExtractLine(tplFalDocConsult.IDS, 4, ',')
             , GCO_CHARACTERIZATION5_ID = ExtractLine(tplFalDocConsult.IDS, 5, ',')
             , FDC_CHARACTERIZATION_VALUE_1 = ExtractLine(tplFalDocConsult.VALS, 1, ',')
             , FDC_CHARACTERIZATION_VALUE_2 = ExtractLine(tplFalDocConsult.VALS, 2, ',')
             , FDC_CHARACTERIZATION_VALUE_3 = ExtractLine(tplFalDocConsult.VALS, 3, ',')
             , FDC_CHARACTERIZATION_VALUE_4 = ExtractLine(tplFalDocConsult.VALS, 4, ',')
             , FDC_CHARACTERIZATION_VALUE_5 = ExtractLine(tplFalDocConsult.VALS, 5, ',')
         where FAL_DOC_CONSULT_ID = tplFalDocConsult.FAL_DOC_CONSULT_ID;
      end loop;

      -- MAJ FAL_DOC_CONSULT_HIST
      for tplFalDocConsultHist in lcurFalDocConsultHist(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update FAL_DOC_CONSULT_HIST
           set GCO_CHARACTERIZATION1_ID = ExtractLine(tplFalDocConsultHist.IDS, 1, ',')
             , GCO_CHARACTERIZATION2_ID = ExtractLine(tplFalDocConsultHist.IDS, 2, ',')
             , GCO_CHARACTERIZATION3_ID = ExtractLine(tplFalDocConsultHist.IDS, 3, ',')
             , GCO_CHARACTERIZATION4_ID = ExtractLine(tplFalDocConsultHist.IDS, 4, ',')
             , GCO_CHARACTERIZATION5_ID = ExtractLine(tplFalDocConsultHist.IDS, 5, ',')
             , FDC_CHARACTERIZATION_VALUE_1 = ExtractLine(tplFalDocConsultHist.VALS, 1, ',')
             , FDC_CHARACTERIZATION_VALUE_2 = ExtractLine(tplFalDocConsultHist.VALS, 2, ',')
             , FDC_CHARACTERIZATION_VALUE_3 = ExtractLine(tplFalDocConsultHist.VALS, 3, ',')
             , FDC_CHARACTERIZATION_VALUE_4 = ExtractLine(tplFalDocConsultHist.VALS, 4, ',')
             , FDC_CHARACTERIZATION_VALUE_5 = ExtractLine(tplFalDocConsultHist.VALS, 5, ',')
         where FAL_DOC_CONSULT_HIST_ID = tplFalDocConsultHist.FAL_DOC_CONSULT_HIST_ID;
      end loop;

      -- MAJ FAL_DOC_PROP
      for tplFalDocProp in lcurFalDocProp(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update FAL_DOC_PROP
           set GCO_CHARACTERIZATION1_ID = ExtractLine(tplFalDocProp.IDS, 1, ',')
             , GCO_CHARACTERIZATION2_ID = ExtractLine(tplFalDocProp.IDS, 2, ',')
             , GCO_CHARACTERIZATION3_ID = ExtractLine(tplFalDocProp.IDS, 3, ',')
             , GCO_CHARACTERIZATION4_ID = ExtractLine(tplFalDocProp.IDS, 4, ',')
             , GCO_CHARACTERIZATION5_ID = ExtractLine(tplFalDocProp.IDS, 5, ',')
             , FDP_CHARACTERIZATION_VALUE_1 = ExtractLine(tplFalDocProp.VALS, 1, ',')
             , FDP_CHARACTERIZATION_VALUE_2 = ExtractLine(tplFalDocProp.VALS, 2, ',')
             , FDP_CHARACTERIZATION_VALUE_3 = ExtractLine(tplFalDocProp.VALS, 3, ',')
             , FDP_CHARACTERIZATION_VALUE_4 = ExtractLine(tplFalDocProp.VALS, 4, ',')
             , FDP_CHARACTERIZATION_VALUE_5 = ExtractLine(tplFalDocProp.VALS, 5, ',')
         where FAL_DOC_PROP_ID = tplFalDocProp.FAL_DOC_PROP_ID;
      end loop;

      -- MAJ FAL_LOT_PROP
      for tplFalLotProp in lcurFalLotProp(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update FAL_LOT_PROP
           set GCO_CHARACTERIZATION1_ID = ExtractLine(tplFalLotProp.IDS, 1, ',')
             , GCO_CHARACTERIZATION2_ID = ExtractLine(tplFalLotProp.IDS, 2, ',')
             , GCO_CHARACTERIZATION3_ID = ExtractLine(tplFalLotProp.IDS, 3, ',')
             , GCO_CHARACTERIZATION4_ID = ExtractLine(tplFalLotProp.IDS, 4, ',')
             , GCO_CHARACTERIZATION5_ID = ExtractLine(tplFalLotProp.IDS, 5, ',')
             , FAD_CHARACTERIZATION_VALUE_1 = ExtractLine(tplFalLotProp.VALS, 1, ',')
             , FAD_CHARACTERIZATION_VALUE_2 = ExtractLine(tplFalLotProp.VALS, 2, ',')
             , FAD_CHARACTERIZATION_VALUE_3 = ExtractLine(tplFalLotProp.VALS, 3, ',')
             , FAD_CHARACTERIZATION_VALUE_4 = ExtractLine(tplFalLotProp.VALS, 4, ',')
             , FAD_CHARACTERIZATION_VALUE_5 = ExtractLine(tplFalLotProp.VALS, 5, ',')
         where FAL_LOT_PROP_ID = tplFalLotProp.FAL_LOT_PROP_ID;
      end loop;

      -- MAJ FAL_OUT_COMPO_BARCODE
      for tplFalOutCBarcode in lcurFalOutCBarcode(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update FAL_OUT_COMPO_BARCODE
           set GCO_CHARACTERIZATION_ID = ExtractLine(tplFalOutCBarcode.IDS, 1, ',')
             , GCO_GCO_CHARACTERIZATION_ID = ExtractLine(tplFalOutCBarcode.IDS, 2, ',')
             , GCO2_GCO_CHARACTERIZATION_ID = ExtractLine(tplFalOutCBarcode.IDS, 3, ',')
             , GCO3_GCO_CHARACTERIZATION_ID = ExtractLine(tplFalOutCBarcode.IDS, 4, ',')
             , GCO4_GCO_CHARACTERIZATION_ID = ExtractLine(tplFalOutCBarcode.IDS, 5, ',')
             , FOC_CHARACTERIZATION_VALUE_1 = ExtractLine(tplFalOutCBarcode.VALS, 1, ',')
             , FOC_CHARACTERIZATION_VALUE_2 = ExtractLine(tplFalOutCBarcode.VALS, 2, ',')
             , FOC_CHARACTERIZATION_VALUE_3 = ExtractLine(tplFalOutCBarcode.VALS, 3, ',')
             , FOC_CHARACTERIZATION_VALUE_4 = ExtractLine(tplFalOutCBarcode.VALS, 4, ',')
             , FOC_CHARACTERIZATION_VALUE_5 = ExtractLine(tplFalOutCBarcode.VALS, 5, ',')
         where FAL_OUT_COMPO_BARCODE_ID = tplFalOutCBarcode.FAL_OUT_COMPO_BARCODE_ID;
      end loop;

      -- MAJ des dossiers SAV - bien à réparer
      for tplAsaRecord_Repair in lcurAsaRecordRepair(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update ASA_RECORD
           set GCO_CHAR1_ID = ExtractLine(tplAsaRecord_Repair.IDS, 1, ',')
             , GCO_CHAR2_ID = ExtractLine(tplAsaRecord_Repair.IDS, 2, ',')
             , GCO_CHAR3_ID = ExtractLine(tplAsaRecord_Repair.IDS, 3, ',')
             , GCO_CHAR4_ID = ExtractLine(tplAsaRecord_Repair.IDS, 4, ',')
             , GCO_CHAR5_ID = ExtractLine(tplAsaRecord_Repair.IDS, 5, ',')
             , ARE_CHAR1_VALUE = ExtractLine(tplAsaRecord_Repair.VALS, 1, ',')
             , ARE_CHAR2_VALUE = ExtractLine(tplAsaRecord_Repair.VALS, 2, ',')
             , ARE_CHAR3_VALUE = ExtractLine(tplAsaRecord_Repair.VALS, 3, ',')
             , ARE_CHAR4_VALUE = ExtractLine(tplAsaRecord_Repair.VALS, 4, ',')
             , ARE_CHAR5_VALUE = ExtractLine(tplAsaRecord_Repair.VALS, 5, ',')
         where ASA_RECORD_ID = tplAsaRecord_Repair.ASA_RECORD_ID;
      end loop;

      -- MAJ des dossiers SAV - bien échangé
      for tplAsaRecord_Exchange in lcurAsaRecordExchange(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update ASA_RECORD
           set GCO_EXCH_CHAR1_ID = ExtractLine(tplAsaRecord_Exchange.IDS, 1, ',')
             , GCO_EXCH_CHAR2_ID = ExtractLine(tplAsaRecord_Exchange.IDS, 2, ',')
             , GCO_EXCH_CHAR3_ID = ExtractLine(tplAsaRecord_Exchange.IDS, 3, ',')
             , GCO_EXCH_CHAR4_ID = ExtractLine(tplAsaRecord_Exchange.IDS, 4, ',')
             , GCO_EXCH_CHAR5_ID = ExtractLine(tplAsaRecord_Exchange.IDS, 5, ',')
             , ARE_EXCH_CHAR1_VALUE = ExtractLine(tplAsaRecord_Exchange.VALS, 1, ',')
             , ARE_EXCH_CHAR2_VALUE = ExtractLine(tplAsaRecord_Exchange.VALS, 2, ',')
             , ARE_EXCH_CHAR3_VALUE = ExtractLine(tplAsaRecord_Exchange.VALS, 3, ',')
             , ARE_EXCH_CHAR4_VALUE = ExtractLine(tplAsaRecord_Exchange.VALS, 4, ',')
             , ARE_EXCH_CHAR5_VALUE = ExtractLine(tplAsaRecord_Exchange.VALS, 5, ',')
         where ASA_RECORD_ID = tplAsaRecord_Exchange.ASA_RECORD_ID;
      end loop;

      -- MAJ des dossiers SAV - nouveau bien
      for tplAsaRecord_NewGood in lcurAsaRecordNewGood(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update ASA_RECORD
           set GCO_NEW_CHAR1_ID = ExtractLine(tplAsaRecord_NewGood.IDS, 1, ',')
             , GCO_NEW_CHAR2_ID = ExtractLine(tplAsaRecord_NewGood.IDS, 2, ',')
             , GCO_NEW_CHAR3_ID = ExtractLine(tplAsaRecord_NewGood.IDS, 3, ',')
             , GCO_NEW_CHAR4_ID = ExtractLine(tplAsaRecord_NewGood.IDS, 4, ',')
             , GCO_NEW_CHAR5_ID = ExtractLine(tplAsaRecord_NewGood.IDS, 5, ',')
             , ARE_NEW_CHAR1_VALUE = ExtractLine(tplAsaRecord_NewGood.VALS, 1, ',')
             , ARE_NEW_CHAR2_VALUE = ExtractLine(tplAsaRecord_NewGood.VALS, 2, ',')
             , ARE_NEW_CHAR3_VALUE = ExtractLine(tplAsaRecord_NewGood.VALS, 3, ',')
             , ARE_NEW_CHAR4_VALUE = ExtractLine(tplAsaRecord_NewGood.VALS, 4, ',')
             , ARE_NEW_CHAR5_VALUE = ExtractLine(tplAsaRecord_NewGood.VALS, 5, ',')
         where ASA_RECORD_ID = tplAsaRecord_NewGood.ASA_RECORD_ID;
      end loop;

      -- MAJ des detail de dossier SAV
      for tplAsaRecordDetail in lcurAsaRecordDetails(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update ASA_RECORD_DETAIL
           set GCO_CHAR1_ID = ExtractLine(tplAsaRecordDetail.IDS, 1, ',')
             , GCO_CHAR2_ID = ExtractLine(tplAsaRecordDetail.IDS, 2, ',')
             , GCO_CHAR3_ID = ExtractLine(tplAsaRecordDetail.IDS, 3, ',')
             , GCO_CHAR4_ID = ExtractLine(tplAsaRecordDetail.IDS, 4, ',')
             , GCO_CHAR5_ID = ExtractLine(tplAsaRecordDetail.IDS, 5, ',')
             , RED_CHAR1_VALUE = ExtractLine(tplAsaRecordDetail.VALS, 1, ',')
             , RED_CHAR2_VALUE = ExtractLine(tplAsaRecordDetail.VALS, 2, ',')
             , RED_CHAR3_VALUE = ExtractLine(tplAsaRecordDetail.VALS, 3, ',')
             , RED_CHAR4_VALUE = ExtractLine(tplAsaRecordDetail.VALS, 4, ',')
             , RED_CHAR5_VALUE = ExtractLine(tplAsaRecordDetail.VALS, 5, ',')
         where ASA_RECORD_DETAIL_ID = tplAsaRecordDetail.ASA_RECORD_DETAIL_ID;
      end loop;

      -- MAJ des detail réparation de dossier SAV
      for tplAsaRecordRepDetail in lcurAsaRecordRepDetails(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update ASA_RECORD_REP_DETAIL
           set GCO_CHAR1_ID = ExtractLine(tplAsaRecordRepDetail.IDS, 1, ',')
             , GCO_CHAR2_ID = ExtractLine(tplAsaRecordRepDetail.IDS, 2, ',')
             , GCO_CHAR3_ID = ExtractLine(tplAsaRecordRepDetail.IDS, 3, ',')
             , GCO_CHAR4_ID = ExtractLine(tplAsaRecordRepDetail.IDS, 4, ',')
             , GCO_CHAR5_ID = ExtractLine(tplAsaRecordRepDetail.IDS, 5, ',')
             , RRD_NEW_CHAR1_VALUE = ExtractLine(tplAsaRecordRepDetail.VALS, 1, ',')
             , RRD_NEW_CHAR2_VALUE = ExtractLine(tplAsaRecordRepDetail.VALS, 2, ',')
             , RRD_NEW_CHAR3_VALUE = ExtractLine(tplAsaRecordRepDetail.VALS, 3, ',')
             , RRD_NEW_CHAR4_VALUE = ExtractLine(tplAsaRecordRepDetail.VALS, 4, ',')
             , RRD_NEW_CHAR5_VALUE = ExtractLine(tplAsaRecordRepDetail.VALS, 5, ',')
         where ASA_RECORD_REP_DETAIL_ID = tplAsaRecordRepDetail.ASA_RECORD_REP_DETAIL_ID;
      end loop;

      -- MAJ des detail d'échange de dossier SAV
      for tplAsaRecordExchDetail in lcurAsaRecordExchDetails(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update ASA_RECORD_EXCH_DETAIL
           set GCO_EXCH_CHAR1_ID = ExtractLine(tplAsaRecordExchDetail.IDS, 1, ',')
             , GCO_EXCH_CHAR2_ID = ExtractLine(tplAsaRecordExchDetail.IDS, 2, ',')
             , GCO_EXCH_CHAR3_ID = ExtractLine(tplAsaRecordExchDetail.IDS, 3, ',')
             , GCO_EXCH_CHAR4_ID = ExtractLine(tplAsaRecordExchDetail.IDS, 4, ',')
             , GCO_EXCH_CHAR5_ID = ExtractLine(tplAsaRecordExchDetail.IDS, 5, ',')
             , REX_EXCH_CHAR1_VALUE = ExtractLine(tplAsaRecordExchDetail.VALS, 1, ',')
             , REX_EXCH_CHAR2_VALUE = ExtractLine(tplAsaRecordExchDetail.VALS, 2, ',')
             , REX_EXCH_CHAR3_VALUE = ExtractLine(tplAsaRecordExchDetail.VALS, 3, ',')
             , REX_EXCH_CHAR4_VALUE = ExtractLine(tplAsaRecordExchDetail.VALS, 4, ',')
             , REX_EXCH_CHAR5_VALUE = ExtractLine(tplAsaRecordExchDetail.VALS, 5, ',')
         where ASA_RECORD_EXCH_DETAIL_ID = tplAsaRecordExchDetail.ASA_RECORD_EXCH_DETAIL_ID;
      end loop;

      -- MAJ des composants SAV
      for tplAsaRecordComp in lcurAsaRecordComps(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update ASA_RECORD_COMP
           set GCO_CHAR1_ID = ExtractLine(tplAsaRecordComp.IDS, 1, ',')
             , GCO_CHAR2_ID = ExtractLine(tplAsaRecordComp.IDS, 2, ',')
             , GCO_CHAR3_ID = ExtractLine(tplAsaRecordComp.IDS, 3, ',')
             , GCO_CHAR4_ID = ExtractLine(tplAsaRecordComp.IDS, 4, ',')
             , GCO_CHAR5_ID = ExtractLine(tplAsaRecordComp.IDS, 5, ',')
             , ARC_CHAR1_VALUE = ExtractLine(tplAsaRecordComp.VALS, 1, ',')
             , ARC_CHAR2_VALUE = ExtractLine(tplAsaRecordComp.VALS, 2, ',')
             , ARC_CHAR3_VALUE = ExtractLine(tplAsaRecordComp.VALS, 3, ',')
             , ARC_CHAR4_VALUE = ExtractLine(tplAsaRecordComp.VALS, 4, ',')
             , ARC_CHAR5_VALUE = ExtractLine(tplAsaRecordComp.VALS, 5, ',')
         where ASA_RECORD_COMP_ID = tplAsaRecordComp.ASA_RECORD_COMP_ID;
      end loop;

      -- MAJ des cartes de garanties
      for tplAsaGuarantyCard in lcurAsaGuarantyCards(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update ASA_GUARANTY_CARDS
           set GCO_CHAR1_ID = ExtractLine(tplAsaGuarantyCard.IDS, 1, ',')
             , GCO_CHAR2_ID = ExtractLine(tplAsaGuarantyCard.IDS, 2, ',')
             , GCO_CHAR3_ID = ExtractLine(tplAsaGuarantyCard.IDS, 3, ',')
             , GCO_CHAR4_ID = ExtractLine(tplAsaGuarantyCard.IDS, 4, ',')
             , GCO_CHAR5_ID = ExtractLine(tplAsaGuarantyCard.IDS, 5, ',')
             , AGC_CHAR1_VALUE = ExtractLine(tplAsaGuarantyCard.VALS, 1, ',')
             , AGC_CHAR2_VALUE = ExtractLine(tplAsaGuarantyCard.VALS, 2, ',')
             , AGC_CHAR3_VALUE = ExtractLine(tplAsaGuarantyCard.VALS, 3, ',')
             , AGC_CHAR4_VALUE = ExtractLine(tplAsaGuarantyCard.VALS, 4, ',')
             , AGC_CHAR5_VALUE = ExtractLine(tplAsaGuarantyCard.VALS, 5, ',')
         where ASA_GUARANTY_CARDS_ID = tplAsaGuarantyCard.ASA_GUARANTY_CARDS_ID;
      end loop;

      -- MAJ des biens volés
      for tplAsaStolenGood in lcurAsaStolenGoods(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update ASA_STOLEN_GOODS
           set GCO_CHAR1_ID = ExtractLine(tplAsaStolenGood.IDS, 1, ',')
             , GCO_CHAR2_ID = ExtractLine(tplAsaStolenGood.IDS, 2, ',')
             , GCO_CHAR3_ID = ExtractLine(tplAsaStolenGood.IDS, 3, ',')
             , GCO_CHAR4_ID = ExtractLine(tplAsaStolenGood.IDS, 4, ',')
             , GCO_CHAR5_ID = ExtractLine(tplAsaStolenGood.IDS, 5, ',')
             , ASG_CHAR1_VALUE = ExtractLine(tplAsaStolenGood.VALS, 1, ',')
             , ASG_CHAR2_VALUE = ExtractLine(tplAsaStolenGood.VALS, 2, ',')
             , ASG_CHAR3_VALUE = ExtractLine(tplAsaStolenGood.VALS, 3, ',')
             , ASG_CHAR4_VALUE = ExtractLine(tplAsaStolenGood.VALS, 4, ',')
             , ASG_CHAR5_VALUE = ExtractLine(tplAsaStolenGood.VALS, 5, ',')
         where ASA_STOLEN_GOODS_ID = tplAsaStolenGood.ASA_STOLEN_GOODS_ID;
      end loop;

      -- MAJ des détails des interventions
      for tplAsaInterventionDetail in crAsaInterventionDetail(ltplCharac.GCO_GOOD_ID, iCharacterizationId) loop
        update ASA_INTERVENTION_DETAIL
           set GCO_CHAR1_ID = ExtractLine(tplAsaInterventionDetail.IDS, 1, ',')
             , GCO_CHAR2_ID = ExtractLine(tplAsaInterventionDetail.IDS, 2, ',')
             , GCO_CHAR3_ID = ExtractLine(tplAsaInterventionDetail.IDS, 3, ',')
             , GCO_CHAR4_ID = ExtractLine(tplAsaInterventionDetail.IDS, 4, ',')
             , GCO_CHAR5_ID = ExtractLine(tplAsaInterventionDetail.IDS, 5, ',')
             , AID_CHAR1_VALUE = ExtractLine(tplAsaInterventionDetail.VALS, 1, ',')
             , AID_CHAR2_VALUE = ExtractLine(tplAsaInterventionDetail.VALS, 2, ',')
             , AID_CHAR3_VALUE = ExtractLine(tplAsaInterventionDetail.VALS, 3, ',')
             , AID_CHAR4_VALUE = ExtractLine(tplAsaInterventionDetail.VALS, 4, ',')
             , AID_CHAR5_VALUE = ExtractLine(tplAsaInterventionDetail.VALS, 5, ',')
         where ASA_INTERVENTION_DETAIL_ID = tplAsaInterventionDetail.ASA_INTERVENTION_DETAIL_ID;
      end loop;

      -- Suppression des positions d'inventaire
      removeInventory(ltplCharac.GCO_GOOD_ID);

      -- supression des STM_ELEMENT_NUMBER liés
      case ltplCharac.C_CHARACT_TYPE
        when gcCharacTypeVersion then
          STM_PRC_ELEMENT_NUMBER.DeleteDetail(iGoodID => ltplCharac.GCO_GOOD_ID, iElementType => gcElementTypeVersion);
        when gcCharacTypePiece then
          STM_PRC_ELEMENT_NUMBER.DeleteDetail(iGoodID => ltplCharac.GCO_GOOD_ID, iElementType => gcElementTypePiece);
        when gcCharacTypeSet then
          STM_PRC_ELEMENT_NUMBER.DeleteDetail(iGoodID => ltplCharac.GCO_GOOD_ID, iElementType => gcElementTypeSet);
        else
          null;
      end case;

      -- effacement dans la table GCO_CHARACTERIZATION
      delete from GCO_CHARACTERIZATION
            where GCO_CHARACTERIZATION_ID = iCharacterizationId;

      -- suivi des modifications
      select nvl(max(SLO_ACTIVE), 0)
        into lCheckIn
        from PCS.PC_SYS_LOG
       where C_LTM_SYS_LOG = '01'
         and PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;

      if lCheckIn = 1 then
        lCheckIn  :=
          LTM_TRACK.CheckIn(ltplCharac.GCO_GOOD_ID
                          , '01'
                          , pcs.PC_FUNCTIONS.TranslateWord('Caractérisation supprimée par l''assistant de mise à jour des caractérisations'
                                                         , pcs.PC_I_LIB_SESSION.GetCompLangId
                                                          )
                           );
      end if;
    exception
      when others then
        iError  := 1;
        -- Log de l'opération
        LogCharacWizardEvent(iAction               => 'ERD'
                           , iCharacterizationId   => iCharacterizationId
                           , iCharDesign           => ltplCharac.CHA_CHARACTERIZATION_DESIGN
                           , iGoodId               => ltplCharac.GCO_GOOD_ID
                           , iErrorComment         => sqlerrm || chr(13) || DBMS_UTILITY.Format_Error_backtrace
                            );
    end;

    -- Fin du mode de maintenance
    gCharManagementMode  := 0;
  end removeCharToExisting;

  /**
  * Description
  *    Lors de l'ajout d'une caractérisation "Piece" éclater les details pour tous les encours
  */
  procedure splitDocDetailsForPiece(
    iGoodID             in GCO_GOOD.GCO_GOOD_ID%type
  , iCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iStkMgnt            in GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type
  )
  is
    cursor lcurDetailsToSplit(iGoodId number, iCharacterizationId number)
    is
      select DOC_POSITION_DETAIL_ID
           , PDE.DOC_DOCUMENT_ID
           , PDE_BASIS_QUANTITY
           , PDE_MOVEMENT_VALUE
           , PDE_BALANCE_QUANTITY_PARENT
           , PDE_BALANCE_QUANTITY
           , decode(GCO_CHARACTERIZATION_ID, iCharacterizationId, iCharacterizationId) CHAR_ID_1
           , decode(GCO_GCO_CHARACTERIZATION_ID, iCharacterizationId, iCharacterizationId) CHAR_ID_2
           , decode(GCO2_GCO_CHARACTERIZATION_ID, iCharacterizationId, iCharacterizationId) CHAR_ID_3
           , decode(GCO3_GCO_CHARACTERIZATION_ID, iCharacterizationId, iCharacterizationId) CHAR_ID_4
           , decode(GCO4_GCO_CHARACTERIZATION_ID, iCharacterizationId, iCharacterizationId) CHAR_ID_5
           , POS.STM_MOVEMENT_KIND_ID
           , GAU.C_ADMIN_DOMAIN
           , GAS.GAS_CHARACTERIZATION
           , GAS.GAS_ALL_CHARACTERIZATION
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where POS.GCO_GOOD_ID = iGoodId
         and POS.C_DOC_POS_STATUS = gcDocPosStatusToConfirm
         and POS.POS_BASIS_QUANTITY not in(0, 1)
         and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and PDE.PDE_BASIS_QUANTITY not in(0, 1)
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    type ttDetailsToSplit is table of lcurDetailsToSplit%rowtype;

    lttDetailsToSplit ttDetailsToSplit;
    lCounter          pls_integer;
  begin
    open lcurDetailsToSplit(iGoodId, iCharacterizationId);

    fetch lcurDetailsToSplit
    bulk collect into lttDetailsToSplit;

    close lcurDetailsToSplit;

    if lttDetailsToSplit.count > 0 then
      for lCounter in lttDetailsToSplit.first .. lttDetailsToSplit.last loop
        if    (    iStkMgnt = 1
               and (   lttDetailsToSplit(lCounter).STM_MOVEMENT_KIND_ID is not null
                    or lttDetailsToSplit(lCounter).GAS_ALL_CHARACTERIZATION = 1) )
           or (    iStkMgnt = 0
               and ( (    lttDetailsToSplit(lCounter).C_ADMIN_DOMAIN = gcAdminDomainSale
                      and lttDetailsToSplit(lCounter).STM_MOVEMENT_KIND_ID is not null) )
              ) then
          -- maj de la position en cours
          update DOC_POSITION_DETAIL
             set PDE_BASIS_QUANTITY = 1
               , PDE_INTERMEDIATE_QUANTITY = 1
               , PDE_FINAL_QUANTITY = 1
               , PDE_BALANCE_QUANTITY = decode(PDE_BALANCE_QUANTITY, 0, 0, 1)
               , PDE_MOVEMENT_QUANTITY = 1
               , PDE_MOVEMENT_VALUE = lttDetailsToSplit(lCounter).PDE_MOVEMENT_VALUE / lttDetailsToSplit(lCounter).PDE_BASIS_QUANTITY
               , PDE_BALANCE_QUANTITY_PARENT = decode(PDE_BALANCE_QUANTITY_PARENT, 0, 0, sign(PDE_BALANCE_QUANTITY_PARENT) * 1)
--****************************************************************
          ,      PDE_BASIS_QUANTITY_SU = 1
               , PDE_INTERMEDIATE_QUANTITY_SU = 1
               , PDE_FINAL_QUANTITY_SU = 1
           where DOC_POSITION_DETAIL_ID = lttDetailsToSplit(lCounter).DOC_POSITION_DETAIL_ID;

          -- création de détails unitaires
          insert into doc_position_detail
                      (DOC_POSITION_DETAIL_ID
                     , DOC_GAUGE_FLOW_ID
                     , DOC_POSITION_ID
                     , DOC_DOC_POSITION_DETAIL_ID
                     , DOC2_DOC_POSITION_DETAIL_ID
                     , PDE_BASIS_DELAY
                     , PDE_BASIS_DELAY_W
                     , PDE_BASIS_DELAY_M
                     , PDE_INTERMEDIATE_DELAY
                     , PDE_INTERMEDIATE_DELAY_W
                     , PDE_INTERMEDIATE_DELAY_M
                     , PDE_FINAL_DELAY
                     , PDE_FINAL_DELAY_W
                     , PDE_FINAL_DELAY_M
                     , PDE_BASIS_QUANTITY
                     , PDE_INTERMEDIATE_QUANTITY
                     , PDE_FINAL_QUANTITY
                     , PDE_BALANCE_QUANTITY
                     , PDE_MOVEMENT_QUANTITY
                     , PDE_MOVEMENT_VALUE
                     , PDE_CHARACTERIZATION_VALUE_1
                     , PDE_CHARACTERIZATION_VALUE_2
                     , PDE_CHARACTERIZATION_VALUE_3
                     , PDE_CHARACTERIZATION_VALUE_4
                     , PDE_CHARACTERIZATION_VALUE_5
                     , GCO_CHARACTERIZATION_ID
                     , GCO_GCO_CHARACTERIZATION_ID
                     , GCO2_GCO_CHARACTERIZATION_ID
                     , GCO3_GCO_CHARACTERIZATION_ID
                     , GCO4_GCO_CHARACTERIZATION_ID
                     , STM_LOCATION_ID
                     , STM_STM_LOCATION_ID
                     , PDE_BALANCE_QUANTITY_PARENT
                     , DIC_PDE_FREE_TABLE_1_ID
                     , DIC_PDE_FREE_TABLE_2_ID
                     , DIC_PDE_FREE_TABLE_3_ID
                     , PDE_DECIMAL_1
                     , PDE_DECIMAL_2
                     , PDE_DECIMAL_3
                     , PDE_TEXT_1
                     , PDE_TEXT_2
                     , PDE_TEXT_3
                     , FAL_SCHEDULE_STEP_ID
                     , DOC_GAUGE_RECEIPT_ID
                     , DOC_GAUGE_COPY_ID
                     , DIC_DELAY_UPDATE_TYPE_ID
                     , PDE_DELAY_UPDATE_TEXT
                     , PDE_BASIS_QUANTITY_SU
                     , PDE_INTERMEDIATE_QUANTITY_SU
                     , PDE_FINAL_QUANTITY_SU
                     , PDE_GENERATE_MOVEMENT
                     , PDE_BALANCE_PARENT
                     , FAL_NETWORK_LINK_ID
                     , PDE_DATE_1
                     , PDE_DATE_2
                     , PDE_DATE_3
                     , PDE_SQM_ACCEPTED_DELAY
                     , C_PDE_CREATE_MODE
                     , FAL_SUPPLY_REQUEST_ID
                     , GCO_GCO_GOOD_ID
                     , PDE_MOVEMENT_DATE
                     , A_DATECRE
                     , A_DATEMOD
                     , A_IDCRE
                     , A_IDMOD
                     , A_RECLEVEL
                     , A_RECSTATUS
                     , A_CONFIRM
                      )
            select init_id_seq.nextval
                 , DOC_GAUGE_FLOW_ID
                 , DOC_POSITION_ID
                 , DOC_DOC_POSITION_DETAIL_ID
                 , DOC2_DOC_POSITION_DETAIL_ID
                 , PDE_BASIS_DELAY
                 , PDE_BASIS_DELAY_W
                 , PDE_BASIS_DELAY_M
                 , PDE_INTERMEDIATE_DELAY
                 , PDE_INTERMEDIATE_DELAY_W
                 , PDE_INTERMEDIATE_DELAY_M
                 , PDE_FINAL_DELAY
                 , PDE_FINAL_DELAY_W
                 , PDE_FINAL_DELAY_M
                 , 1   --PDE_BASIS_QUANTITY
                 , 1   --PDE_INTERMEDIATE_QUANTITY
                 , 1   --PDE_FINAL_QUANTITY
                 , decode(PDE_BALANCE_QUANTITY, 0, 0, 1)   --PDE_BALANCE_QUANTITY
                 , 1   -- PDE_MOVEMENT_QUANTITY
                 , lttDetailsToSplit(lCounter).PDE_MOVEMENT_VALUE / lttDetailsToSplit(lCounter).PDE_BASIS_QUANTITY   -- PDE_MOVEMENT_VALUE
                 , nvl2(lttDetailsToSplit(lCounter).CHAR_ID_1, PDE_CHARACTERIZATION_VALUE_1, null)
                 , nvl2(lttDetailsToSplit(lCounter).CHAR_ID_2, PDE_CHARACTERIZATION_VALUE_2, null)
                 , nvl2(lttDetailsToSplit(lCounter).CHAR_ID_3, PDE_CHARACTERIZATION_VALUE_3, null)
                 , nvl2(lttDetailsToSplit(lCounter).CHAR_ID_4, PDE_CHARACTERIZATION_VALUE_4, null)
                 , nvl2(lttDetailsToSplit(lCounter).CHAR_ID_5, PDE_CHARACTERIZATION_VALUE_5, null)
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , STM_LOCATION_ID
                 , STM_STM_LOCATION_ID
                 , decode(sign(abs(lttDetailsToSplit(lCounter).PDE_BALANCE_QUANTITY_PARENT) -(NUM.no + 1) )
                        , 1, sign(PDE_BALANCE_QUANTITY_PARENT) * 1
                        , 0
                         )   -- PDE_BALANCE_QUANTITY_PARENT
                 , DIC_PDE_FREE_TABLE_1_ID
                 , DIC_PDE_FREE_TABLE_2_ID
                 , DIC_PDE_FREE_TABLE_3_ID
                 , PDE_DECIMAL_1
                 , PDE_DECIMAL_2
                 , PDE_DECIMAL_3
                 , PDE_TEXT_1
                 , PDE_TEXT_2
                 , PDE_TEXT_3
                 , FAL_SCHEDULE_STEP_ID
                 , DOC_GAUGE_RECEIPT_ID
                 , DOC_GAUGE_COPY_ID
                 , DIC_DELAY_UPDATE_TYPE_ID
                 , PDE_DELAY_UPDATE_TEXT
                 , 1   --PDE_BASIS_QUANTITY_SU
                 , 1   --PDE_INTERMEDIATE_QUANTITY_SU
                 , 1   --PDE_FINAL_QUANTITY_SU
                 , PDE_GENERATE_MOVEMENT
                 , PDE_BALANCE_PARENT
                 , FAL_NETWORK_LINK_ID
                 , PDE_DATE_1
                 , PDE_DATE_2
                 , PDE_DATE_3
                 , PDE_SQM_ACCEPTED_DELAY
                 , C_PDE_CREATE_MODE
                 , FAL_SUPPLY_REQUEST_ID
                 , GCO_GCO_GOOD_ID
                 , PDE_MOVEMENT_DATE
                 , A_DATECRE
                 , A_DATEMOD
                 , A_IDCRE
                 , A_IDMOD
                 , A_RECLEVEL
                 , A_RECSTATUS
                 , A_CONFIRM
              from doc_position_detail pde
                 , PCS.PC_NUMBER NUM
             where pde.DOC_POSITION_DETAIL_ID = lttDetailsToSplit(lCounter).DOC_POSITION_DETAIL_ID
               and NUM.no between 2 and lttDetailsToSplit(lCounter).PDE_BASIS_QUANTITY;

          -- mise à jour du flag indiquant des caractérisations manquantes sur le document
          update DOC_DOCUMENT
             set DMT_CHARACTERIZATION_MISSING = 1
           where DOC_DOCUMENT_ID = lttDetailsToSplit(lCounter).DOC_DOCUMENT_ID;
        end if;
      end loop;
    end if;
  end splitDocDetailsForPiece;

  /**
  * Description
  *    Lors de l'ajout d'une caractérisation "Piece" éclater les details pour tous les encours
  */
  procedure splitFalLotDetailsForPiece(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
  is
    cursor lcurAllGoodLot(iGoodID number)
    is
      select FAL_LOT_DETAIL.FAL_LOT_ID
        from FAL_LOT_DETAIL
           , FAL_LOT
       where C_LOT_DETAIL = '1'
         and FAD_BALANCE_QTY > 1
         and FAL_LOT_DETAIL.GCO_GOOD_ID = iGoodId
         and FAL_LOT_DETAIL.FAL_LOT_ID = FAL_LOT.FAL_LOT_ID;

    lNbDet pls_integer;
  begin
    -- 2 cas : 1) il existe déjà un detail, dans ce cas on le duplique n fois
    --         2) pas de détail, aucune création de détail
    for tplAllGoodLot in lcurAllGoodLot(iGoodID) loop
      select count(*)
        into lNbDet
        from FAL_LOT_DETAIL
       where FAL_LOT_ID = tplAllGoodLot.FAL_LOT_ID
         and GCO_GOOD_ID = iGoodId
         and FAD_BALANCE_QTY <> 0
         and C_LOT_DETAIL = '1';

      -- Cas 1 -> pas de détails
      if lNbDet = 0 then
        -- Si les détails n'existent pas, ils sera automatiquement demandé
        -- de les créer avant la réception de l'OF
        null;
      -- Cas 2 -> split des details
      else
        declare
          cursor lcurDetailLot(iLotId number)
          is
            select FAL_LOT_DETAIL_ID
                 , FAD_QTY
                 , FAD_RECEPT_QTY
                 , FAD_CANCEL_QTY
                 , FAD_BALANCE_QTY
              from FAL_LOT_DETAIL
             where FAL_LOT_ID = iLotId
               and GCO_GOOD_ID = iGoodId
               and FAD_BALANCE_QTY <> 1
               and C_LOT_DETAIL = '1';
        begin
          for tplDetailLot in lcurDetailLot(tplAllGoodLot.FAL_LOT_ID) loop
            -- rien n'a encore été réceptionné
            if tplDetailLot.FAD_BALANCE_QTY = tplDetailLot.FAD_QTY then
              update FAL_LOT_DETAIL
                 set FAD_QTY = 1
                   , FAD_BALANCE_QTY = 1
               where FAL_LOT_DETAIL_ID = tplDetailLot.FAL_LOT_DETAIL_ID;
            -- une réception partielle a déjà été effectuée
            else
              -- maj du détail existant en ne laissant que la qté déjà déchargée
              update FAL_LOT_DETAIL
                 set FAD_QTY = FAD_QTY - FAD_BALANCE_QTY
                   , FAD_BALANCE_QTY = 0
               where FAL_LOT_DETAIL_ID = tplDetailLot.FAL_LOT_DETAIL_ID;

              -- création du premier détail suivant
              insert into FAL_LOT_DETAIL
                          (FAL_LOT_DETAIL_ID
                         , FAL_LOT_ID
                         , GCO_CHARACTERIZATION_ID
                         , GCO_GCO_CHARACTERIZATION_ID
                         , GCO2_GCO_CHARACTERIZATION_ID
                         , GCO3_GCO_CHARACTERIZATION_ID
                         , GCO4_GCO_CHARACTERIZATION_ID
                         , FAD_CHARACTERIZATION_VALUE_1
                         , FAD_CHARACTERIZATION_VALUE_2
                         , FAD_CHARACTERIZATION_VALUE_3
                         , FAD_CHARACTERIZATION_VALUE_4
                         , FAD_CHARACTERIZATION_VALUE_5
                         , GCO_GOOD_ID
                         , FAD_RECEPT_SELECT
                         , FAD_QTY
                         , FAD_RECEPT_QTY
                         , FAD_BALANCE_QTY
                         , FAD_CANCEL_QTY
                         , FAD_VERSION
                         , FAD_LOT_CHARACTERIZATION
                         , FAD_PIECE
                         , FAD_CHRONOLOGY
                         , FAD_STD_CHAR_1
                         , FAD_STD_CHAR_2
                         , FAD_STD_CHAR_3
                         , FAD_STD_CHAR_4
                         , FAD_STD_CHAR_5
                         , FAD_LOT_REFCOMPL
                         , FAD_RECEPT_INPROGRESS_QTY
                         , FAD_MORPHO_REJECT_QTY
                         , GCG_INCLUDE_GOOD
                         , A_DATECRE
                         , A_IDCRE
                          )
                select init_id_seq.nextval FAL_LOT_DETAIL_ID
                     , FAL_LOT_ID
                     , GCO_CHARACTERIZATION_ID
                     , GCO_GCO_CHARACTERIZATION_ID
                     , GCO2_GCO_CHARACTERIZATION_ID
                     , GCO3_GCO_CHARACTERIZATION_ID
                     , GCO4_GCO_CHARACTERIZATION_ID
                     , FAD_CHARACTERIZATION_VALUE_1
                     , FAD_CHARACTERIZATION_VALUE_2
                     , FAD_CHARACTERIZATION_VALUE_3
                     , FAD_CHARACTERIZATION_VALUE_4
                     , FAD_CHARACTERIZATION_VALUE_5
                     , GCO_GOOD_ID
                     , 0 FAD_RECEPT_SELECT
                     , 1 FAD_QTY
                     , 0 FAD_RECEPT_QTY
                     , 1 FAD_BALANCE_QTY
                     , 0 FAD_CANCEL_QTY
                     , null FAD_VERSION
                     , null FAD_LOT_CHARACTERIZATION
                     , null FAD_PIECE
                     , null FAD_CHRONOLOGY
                     , null FAD_STD_CHAR_1
                     , null FAD_STD_CHAR_2
                     , null FAD_STD_CHAR_3
                     , null FAD_STD_CHAR_4
                     , null FAD_STD_CHAR_5
                     , FAD_LOT_REFCOMPL
                     , 0 FAD_RECEPT_INPROGRESS_QTY
                     , null FAD_MORPHO_REJECT_QTY
                     , GCG_INCLUDE_GOOD
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                  from fal_lot_detail fad
                 where fad.FAL_LOT_DETAIL_ID = tplDetailLot.FAL_LOT_DETAIL_ID;
            end if;

            -- création de details unitaires pour le solde
            insert into FAL_LOT_DETAIL
                        (FAL_LOT_DETAIL_ID
                       , FAL_LOT_ID
                       , GCO_CHARACTERIZATION_ID
                       , GCO_GCO_CHARACTERIZATION_ID
                       , GCO2_GCO_CHARACTERIZATION_ID
                       , GCO3_GCO_CHARACTERIZATION_ID
                       , GCO4_GCO_CHARACTERIZATION_ID
                       , FAD_CHARACTERIZATION_VALUE_1
                       , FAD_CHARACTERIZATION_VALUE_2
                       , FAD_CHARACTERIZATION_VALUE_3
                       , FAD_CHARACTERIZATION_VALUE_4
                       , FAD_CHARACTERIZATION_VALUE_5
                       , GCO_GOOD_ID
                       , FAD_RECEPT_SELECT
                       , FAD_QTY
                       , FAD_RECEPT_QTY
                       , FAD_BALANCE_QTY
                       , FAD_CANCEL_QTY
                       , FAD_VERSION
                       , FAD_LOT_CHARACTERIZATION
                       , FAD_PIECE
                       , FAD_CHRONOLOGY
                       , FAD_STD_CHAR_1
                       , FAD_STD_CHAR_2
                       , FAD_STD_CHAR_3
                       , FAD_STD_CHAR_4
                       , FAD_STD_CHAR_5
                       , FAD_LOT_REFCOMPL
                       , FAD_RECEPT_INPROGRESS_QTY
                       , FAD_MORPHO_REJECT_QTY
                       , GCG_INCLUDE_GOOD
                       , A_DATECRE
                       , A_IDCRE
                        )
              select init_id_seq.nextval FAL_LOT_DETAIL_ID
                   , FAL_LOT_ID
                   , GCO_CHARACTERIZATION_ID
                   , GCO_GCO_CHARACTERIZATION_ID
                   , GCO2_GCO_CHARACTERIZATION_ID
                   , GCO3_GCO_CHARACTERIZATION_ID
                   , GCO4_GCO_CHARACTERIZATION_ID
                   , FAD_CHARACTERIZATION_VALUE_1
                   , FAD_CHARACTERIZATION_VALUE_2
                   , FAD_CHARACTERIZATION_VALUE_3
                   , FAD_CHARACTERIZATION_VALUE_4
                   , FAD_CHARACTERIZATION_VALUE_5
                   , GCO_GOOD_ID
                   , 0 FAD_RECEPT_SELECT
                   , 1 FAD_QTY
                   , 0 FAD_RECEPT_QTY
                   , 1 FAD_BALANCE_QTY
                   , 0 FAD_CANCEL_QTY
                   , null FAD_VERSION
                   , null FAD_LOT_CHARACTERIZATION
                   , null FAD_PIECE
                   , null FAD_CHRONOLOGY
                   , null FAD_STD_CHAR_1
                   , null FAD_STD_CHAR_2
                   , null FAD_STD_CHAR_3
                   , null FAD_STD_CHAR_4
                   , null FAD_STD_CHAR_5
                   , FAD_LOT_REFCOMPL
                   , 0 FAD_RECEPT_INPROGRESS_QTY
                   , null FAD_MORPHO_REJECT_QTY
                   , GCG_INCLUDE_GOOD
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from fal_lot_detail fad
                   , pcs.pc_number num
               where num.no between 2 and tplDetailLot.FAD_BALANCE_QTY
                 and fad.FAL_LOT_DETAIL_ID = tplDetailLot.FAL_LOT_DETAIL_ID;
          end loop;
        end;
      end if;
    end loop;
  end splitFalLotDetailsForPiece;

  /**
  * Description
  *    Lors de l'ajout d'une caractérisation "Piece" éclater les details pour tous les encours
  */
  procedure splitAsaRecordForPiece(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
  is
    -- réparation  -> ASA_RECORD_DETAIL si qte > 1
    cursor lcurAsaRecordRep(iGoodID number)
    is
      select ASA_RECORD_ID
        from ASA_RECORD
       where GCO_ASA_TO_REPAIR_ID = iGoodID
         and (   ARE_REPAIR_QTY > 1
              or ARE_EXCH_QTY > 1)
         and STM_ASA_DEFECT_MVT_ID is null;

    -- échange
    cursor lcurAsaRecordExch(iGoodID number)
    is
      select ASA_RECORD_ID
        from ASA_RECORD
       where GCO_ASA_EXCHANGE_ID = iGoodID
         and ARE_EXCH_QTY > 1
         and STM_ASA_EXCH_MVT_ID is null;
  begin
    for tplAsaRecordRep in lcurAsaRecordRep(iGoodId) loop
      declare
        -- recherche des détails dont les mouvements n'ont pas encore été générés
        cursor crRecordDetail(iRecordId number)
        is
          select *
            from ASA_RECORD_DETAIL
           where ASA_RECORD_ID = iRecordId
             and RED_QTY_TO_REPAIR > 1
             and STM_STOCK_MOVEMENT_ID is null;

        tplRecordDetail crRecordDetail%rowtype;

        type ttblNewDetailId is table of ASA_RECORD_DETAIL.ASA_RECORD_DETAIL_ID%type
          index by binary_integer;

        -- tableau des id de details créés
        tblNewDetailId  ttblNewDetailId;
        lCounter        pls_integer;
      begin
        open crRecordDetail(tplAsaRecordRep.ASA_RECORD_ID);

        fetch crRecordDetail
         into tplRecordDetail;

        -- si on a trouvé des detail
        if crRecordDetail%found then
          declare
            cursor lcurRecordDetailToDuplicate(iRecordDetailId number, iQtyToRepair number)
            is
              select init_id_seq.nextval
                   , RED.DOC_ORIGIN_POSITION_ID
                   , RED.ASA_RECORD_ID
                   , RED.ASA_LAST_RECORD_ID
                   , RED.RED_CHAR1_VALUE
                   , RED.RED_CHAR2_VALUE
                   , RED.RED_CHAR3_VALUE
                   , RED.RED_CHAR4_VALUE
                   , RED.RED_CHAR5_VALUE
                   , 1   -- quantité
                   , RED.GCO_CHAR1_ID
                   , RED.GCO_CHAR2_ID
                   , RED.GCO_CHAR3_ID
                   , RED.GCO_CHAR4_ID
                   , RED.GCO_CHAR5_ID
                   , RED.A_DATECRE
                   , RED.A_DATEMOD
                   , RED.A_IDCRE
                   , RED.A_IDMOD
                   , RED.A_RECLEVEL
                   , RED.A_RECSTATUS
                   , RED.A_CONFIRM
                from ASA_RECORD_DETAIL RED
                   , PCS.PC_NUMBER NUM
               where NUM.no between 2 and iQtyToRepair
                 and RED.ASA_RECORD_DETAIL_ID = iRecordDetailId;
          begin
            while crRecordDetail%found loop
              -- mise à jour d'une quantité unitaire sur le détail existant
              update ASA_RECORD_DETAIL
                 set RED_QTY_TO_REPAIR = 1
               where ASA_RECORD_DETAIL_ID = tplRecordDetail.ASA_RECORD_DETAIL_ID;

              lCounter  := 0;

              -- création de nouveau details selon la quantité demandée
              for tplRecordDetailToDuplicate in lcurRecordDetailToDuplicate(tplRecordDetail.ASA_RECORD_DETAIL_ID, tplRecordDetail.RED_QTY_TO_REPAIR) loop
                insert into ASA_RECORD_DETAIL
                            (ASA_RECORD_DETAIL_ID
                           , DOC_ORIGIN_POSITION_ID
                           , ASA_RECORD_ID
                           , ASA_LAST_RECORD_ID
                           , RED_CHAR1_VALUE
                           , RED_CHAR2_VALUE
                           , RED_CHAR3_VALUE
                           , RED_CHAR4_VALUE
                           , RED_CHAR5_VALUE
                           , RED_QTY_TO_REPAIR
                           , GCO_CHAR1_ID
                           , GCO_CHAR2_ID
                           , GCO_CHAR3_ID
                           , GCO_CHAR4_ID
                           , GCO_CHAR5_ID
                           , A_DATECRE
                           , A_DATEMOD
                           , A_IDCRE
                           , A_IDMOD
                           , A_RECLEVEL
                           , A_RECSTATUS
                           , A_CONFIRM
                            )
                     values (init_id_seq.nextval
                           , tplRecordDetailToDuplicate.DOC_ORIGIN_POSITION_ID
                           , tplRecordDetailToDuplicate.ASA_RECORD_ID
                           , tplRecordDetailToDuplicate.ASA_LAST_RECORD_ID
                           , tplRecordDetailToDuplicate.RED_CHAR1_VALUE
                           , tplRecordDetailToDuplicate.RED_CHAR2_VALUE
                           , tplRecordDetailToDuplicate.RED_CHAR3_VALUE
                           , tplRecordDetailToDuplicate.RED_CHAR4_VALUE
                           , tplRecordDetailToDuplicate.RED_CHAR5_VALUE
                           , 1   -- quantité
                           , tplRecordDetailToDuplicate.GCO_CHAR1_ID
                           , tplRecordDetailToDuplicate.GCO_CHAR2_ID
                           , tplRecordDetailToDuplicate.GCO_CHAR3_ID
                           , tplRecordDetailToDuplicate.GCO_CHAR4_ID
                           , tplRecordDetailToDuplicate.GCO_CHAR5_ID
                           , tplRecordDetailToDuplicate.A_DATECRE
                           , tplRecordDetailToDuplicate.A_DATEMOD
                           , tplRecordDetailToDuplicate.A_IDCRE
                           , tplRecordDetailToDuplicate.A_IDMOD
                           , tplRecordDetailToDuplicate.A_RECLEVEL
                           , tplRecordDetailToDuplicate.A_RECSTATUS
                           , tplRecordDetailToDuplicate.A_CONFIRM
                            )
                  returning ASA_RECORD_DETAIL_ID
                       into tblnewDetailId(lCounter);

                lCounter  := lCounter + 1;

                fetch crRecordDetail
                 into tplRecordDetail;
              end loop;
            end loop;

            declare
              ltplRecordRepDetail ASA_RECORD_REP_DETAIL%rowtype;
            begin
              -- recherche d'éventuel detail de réparation
              select *
                into ltplRecordRepDetail
                from ASA_RECORD_REP_DETAIL
               where ASA_RECORD_DETAIL_ID = tplRecordDetail.ASA_RECORD_DETAIL_ID;

              -- maj du premier detail de réparation
              update ASA_RECORD_REP_DETAIL
                 set RRD_QTY_REPAIRED = 1
               where ASA_RECORD_DETAIL_ID = tplRecordDetail.ASA_RECORD_DETAIL_ID;

              -- création des nouveaux details de réparation avec lien sur les detail d'échange créés
              for lCounter in 0 .. ltplRecordRepDetail.RRD_QTY_REPAIRED - 2 loop
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
                           , A_DATEMOD
                           , A_IDCRE
                           , A_IDMOD
                           , A_RECLEVEL
                           , A_RECSTATUS
                           , A_CONFIRM
                            )
                  select init_id_seq.nextval
                       , tblNewDetailId(lCounter)
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
                       , A_DATEMOD
                       , A_IDCRE
                       , A_IDMOD
                       , A_RECLEVEL
                       , lCounter   --A_RECSTATUS
                       , A_CONFIRM
                    from ASA_RECORD_REP_DETAIL
                   where ASA_RECORD_REP_DETAIL_ID = ltplRecordRepDetail.ASA_RECORD_REP_DETAIL_ID;
              end loop;
            exception
              when no_data_found then
                null;
            end;

            -- details des échanges
            declare
              ltplRecordExchDetail ASA_RECORD_EXCH_DETAIL%rowtype;
            begin
              -- recherche d'éventuel detail de réparation
              select *
                into ltplRecordExchDetail
                from ASA_RECORD_EXCH_DETAIL
               where ASA_RECORD_DETAIL_ID = tplRecordDetail.ASA_RECORD_DETAIL_ID;

              -- maj du premier detail de réparation
              update ASA_RECORD_EXCH_DETAIL
                 set REX_QTY_EXCHANGED = 1
               where ASA_RECORD_EXCH_DETAIL_ID = ltplRecordExchDetail.ASA_RECORD_EXCH_DETAIL_ID;

              -- création des nouveaux details de réparation avec lien sur les detail d'échange créés
              for lCounter in 0 .. ltplRecordExchDetail.REX_QTY_EXCHANGED - 2 loop
                insert into ASA_RECORD_EXCH_DETAIL
                            (ASA_RECORD_EXCH_DETAIL_ID
                           , ASA_RECORD_DETAIL_ID
                           , GCO_EXCH_CHAR1_ID
                           , GCO_EXCH_CHAR2_ID
                           , GCO_EXCH_CHAR3_ID
                           , GCO_EXCH_CHAR4_ID
                           , GCO_EXCH_CHAR5_ID
                           , REX_EXCH_CHAR1_VALUE
                           , REX_EXCH_CHAR2_VALUE
                           , REX_EXCH_CHAR3_VALUE
                           , REX_EXCH_CHAR4_VALUE
                           , REX_EXCH_CHAR5_VALUE
                           , REX_QTY_EXCHANGED
                           , A_DATECRE
                           , A_DATEMOD
                           , A_IDCRE
                           , A_IDMOD
                           , A_RECLEVEL
                           , A_RECSTATUS
                           , A_CONFIRM
                            )
                  select init_id_seq.nextval
                       , tblNewDetailId(lCounter)
                       , GCO_EXCH_CHAR1_ID
                       , GCO_EXCH_CHAR2_ID
                       , GCO_EXCH_CHAR3_ID
                       , GCO_EXCH_CHAR4_ID
                       , GCO_EXCH_CHAR5_ID
                       , REX_EXCH_CHAR1_VALUE
                       , REX_EXCH_CHAR2_VALUE
                       , REX_EXCH_CHAR3_VALUE
                       , REX_EXCH_CHAR4_VALUE
                       , REX_EXCH_CHAR5_VALUE
                       , REX_QTY_EXCHANGED
                       , A_DATECRE
                       , A_DATEMOD
                       , A_IDCRE
                       , A_IDMOD
                       , ltplRecordExchDetail.REX_QTY_EXCHANGED   --A_RECLEVEL
                       , lCounter   --A_RECSTATUS
                       , A_CONFIRM
                    from ASA_RECORD_EXCH_DETAIL
                   where ASA_RECORD_EXCH_DETAIL_ID = ltplRecordExchDetail.ASA_RECORD_EXCH_DETAIL_ID;
              end loop;
            exception
              when no_data_found then
                null;
            end;
          end;
        end if;

        close crRecordDetail;
      end;
    end loop;

    -- si le bien n'est que le bien d'échange
    for tplAsaRecordExch in lcurAsaRecordExch(iGoodId) loop
      -- details des échanges
      declare
        cursor lcurRecordExchDetail(iRecordId number)
        is
          select REX.*
            from ASA_RECORD_EXCH_DETAIL REX
               , ASA_RECORD_DETAIL RED
           where RED.ASA_RECORD_ID = iRecordId
             and REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID
             and REX_QTY_EXCHANGED > 1;

        ltplRecordExchDetail ASA_RECORD_EXCH_DETAIL%rowtype;
      begin
        for ltplRecordExchDetail in lcurRecordExchDetail(tplAsaRecordExch.ASA_RECORD_ID) loop
          -- maj du premier detail de réparation
          update ASA_RECORD_EXCH_DETAIL
             set REX_QTY_EXCHANGED = 1
           where ASA_RECORD_EXCH_DETAIL_ID = ltplRecordExchDetail.ASA_RECORD_EXCH_DETAIL_ID;

          -- création des nouveaux details de réparation avec lien sur les detail d'échange créés
          for lCounter in 0 .. ltplRecordExchDetail.REX_QTY_EXCHANGED - 2 loop
            insert into ASA_RECORD_EXCH_DETAIL
                        (ASA_RECORD_EXCH_DETAIL_ID
                       , ASA_RECORD_DETAIL_ID
                       , GCO_EXCH_CHAR1_ID
                       , GCO_EXCH_CHAR2_ID
                       , GCO_EXCH_CHAR3_ID
                       , GCO_EXCH_CHAR4_ID
                       , GCO_EXCH_CHAR5_ID
                       , REX_EXCH_CHAR1_VALUE
                       , REX_EXCH_CHAR2_VALUE
                       , REX_EXCH_CHAR3_VALUE
                       , REX_EXCH_CHAR4_VALUE
                       , REX_EXCH_CHAR5_VALUE
                       , REX_QTY_EXCHANGED
                       , A_DATECRE
                       , A_DATEMOD
                       , A_IDCRE
                       , A_IDMOD
                       , A_RECLEVEL
                       , A_RECSTATUS
                       , A_CONFIRM
                        )
                 values (init_id_seq.nextval
                       , ltplRecordExchDetail.ASA_RECORD_DETAIL_ID
                       , ltplRecordExchDetail.GCO_EXCH_CHAR1_ID
                       , ltplRecordExchDetail.GCO_EXCH_CHAR2_ID
                       , ltplRecordExchDetail.GCO_EXCH_CHAR3_ID
                       , ltplRecordExchDetail.GCO_EXCH_CHAR4_ID
                       , ltplRecordExchDetail.GCO_EXCH_CHAR5_ID
                       , ltplRecordExchDetail.REX_EXCH_CHAR1_VALUE
                       , ltplRecordExchDetail.REX_EXCH_CHAR2_VALUE
                       , ltplRecordExchDetail.REX_EXCH_CHAR3_VALUE
                       , ltplRecordExchDetail.REX_EXCH_CHAR4_VALUE
                       , ltplRecordExchDetail.REX_EXCH_CHAR5_VALUE
                       , 1   --tplRecordExchDetail.REX_QTY_EXCHANGED
                       , ltplRecordExchDetail.A_DATECRE
                       , ltplRecordExchDetail.A_DATEMOD
                       , ltplRecordExchDetail.A_IDCRE
                       , ltplRecordExchDetail.A_IDMOD
                       , ltplRecordExchDetail.A_RECLEVEL
                       , ltplRecordExchDetail.A_RECSTATUS
                       , ltplRecordExchDetail.A_CONFIRM
                        );
          end loop;
        end loop;
      exception
        when no_data_found then
          null;
      end;
    end loop;
  end splitAsaRecordForPiece;

  /**
  * Description
  *    insertion du detail des positions dans une table temporaire
  *    pour saisie manuelle des valeurs du stock
  */
  procedure fillStkPosToTemp(
    iGoodID       in GCO_GOOD.GCO_GOOD_ID%type
  , iCharactType  in GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , iQualityValue in number
  , iRetestValue  in date
  )
  is
    cursor lcurStockPosition(iGoodID number)
    is
      select   SPO.STM_STOCK_POSITION_ID
             , SPO.SPO_STOCK_QUANTITY
             , STO.C_ACCESS_METHOD
          from STM_STOCK_POSITION SPO
             , STM_STOCK STO
         where SPO.GCO_GOOD_ID = iGoodID
           and SPO.STM_STOCK_ID = STO.STM_STOCK_ID
           and STO.STO_DESCRIPTION not in
                                     (nvl(PCS.PC_CONFIG.GetConfig('PPS_DefltSTOCK_FLOOR'), ' '), nvl(PCS.PC_CONFIG.GetConfig('ASA_WORK_STO_DESCRIPTION'), ' ') )
      order by STO.STO_CLASSIFICATION
             , SPO.STM_STOCK_POSITION_ID;

    /*
         and STM_STOCK_ID not in(
               select STM_STOCK_ID
                 from STM_STOCK
                where STO_DESCRIPTION in
                        (PCS.PC_CONFIG.GetConfig('PPS_DefltSTOCK_FLOOR')
                       , PCS.PC_CONFIG.GetConfig('ASA_WORK_STO_DESCRIPTION')
                        ) );
                        */
    lnCount    integer;
    lnQuantity STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
  begin
    -- pour chaque position de stock du bien excepté les stocks atelier
    for tplStockPosition in lcurStockPosition(iGoodID) loop
      -- Pour les positions de stock sur un stock privé, le split ne doit pas être fait (quel que soit le type de caract)
      if     (iCharactType = gcCharacTypePiece)
         and (tplStockPosition.C_ACCESS_METHOD <> 'PRIVATE') then
        -- Split de la position de stock, s'il s'agit d'une caract de type Piece
        lnCount     := tplStockPosition.SPO_STOCK_QUANTITY;
        lnQuantity  := 1;
      else
        lnCount     := 1;
        lnQuantity  := tplStockPosition.SPO_STOCK_QUANTITY;
      end if;

      -- création de details unitaires dans la table temporaire
      -- pour chaque position de stock
      insert into STM_TMP_STOCK_POSITION
                  (STM_TMP_STOCK_POSITION_ID
                 , STM_STOCK_POSITION_ID
                 , STM_STOCK_ID
                 , C_POSITION_STATUS
                 , GCO_GOOD_ID
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , STM_LOCATION_ID
                 , SPO_CHARACTERIZATION_VALUE_1
                 , SPO_CHARACTERIZATION_VALUE_2
                 , SPO_CHARACTERIZATION_VALUE_3
                 , SPO_CHARACTERIZATION_VALUE_4
                 , SPO_CHARACTERIZATION_VALUE_5
                 , SPO_STOCK_QUANTITY
                 , SPO_LAST_INVENTORY_DATE
                 , GCO_QUALITY_STATUS_ID
                 , SEM_RETEST_DATE
                 , SPO_ORIGIN
                 , SPO_ORIGIN_QUANTITY
                 , A_DATECRE
                 , A_DATEMOD
                 , A_IDCRE
                 , A_IDMOD
                 , A_RECLEVEL
                 , A_RECSTATUS
                 , A_CONFIRM
                  )
        select init_id_seq.nextval
             , SPO.STM_STOCK_POSITION_ID
             , SPO.STM_STOCK_ID
             , SPO.C_POSITION_STATUS
             , SPO.GCO_GOOD_ID
             , SPO.GCO_CHARACTERIZATION_ID
             , SPO.GCO_GCO_CHARACTERIZATION_ID
             , SPO.GCO2_GCO_CHARACTERIZATION_ID
             , SPO.GCO3_GCO_CHARACTERIZATION_ID
             , SPO.GCO4_GCO_CHARACTERIZATION_ID
             , SPO.STM_LOCATION_ID
             , SPO.SPO_CHARACTERIZATION_VALUE_1
             , SPO.SPO_CHARACTERIZATION_VALUE_2
             , SPO.SPO_CHARACTERIZATION_VALUE_3
             , SPO.SPO_CHARACTERIZATION_VALUE_4
             , SPO.SPO_CHARACTERIZATION_VALUE_5
             , lnQuantity as SPO_STOCK_QUANTITY
             , SPO.SPO_LAST_INVENTORY_DATE
             , iQualityValue
             , iRetestValue
             , 1   -- SPO_ORIGIN
             , lnQuantity as SPO_ORIGIN_QUANTITY
             , SPO.A_DATECRE
             , SPO.A_DATEMOD
             , SPO.A_IDCRE
             , SPO.A_IDMOD
             , SPO.A_RECLEVEL
             , SPO.A_RECSTATUS
             , SPO.A_CONFIRM
          from STM_STOCK_POSITION SPO
             , pcs.pc_number num
         where num.no between 1 and lnCount
           and SPO.STM_STOCK_POSITION_ID = tplStockPosition.STM_STOCK_POSITION_ID
           and SPO.SPO_STOCK_QUANTITY > 0;
    end loop;
  end fillStkPosToTemp;

  /**
  * Description
  *    insertion des biens à traiter dans une table temporaire
  */
  procedure fillGoodToTemp(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', iGoodID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', 'ListGood');
    FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end fillGoodToTemp;

  -- Assignation du mode de gestion des caractérisations
  procedure SetCharManagementMode(iValue in number)
  is
  begin
    gCharManagementMode  := iValue;
  end SetCharManagementMode;

  /**
  * Description
  *   Génération des mouvements de transformation de l'assistant de maintenance des caractérisations
  */
  procedure GenerateWizardMovements
  is
    cursor lcurMoves
    is
      select STM_TMP_STOCK_POSITION_ID
        from STM_TMP_STOCK_POSITION;

    lOk number(1);
  begin
    -- pour chaque position, un mouvment de sortie 'N/A' et en mouvement d'entrée avec la valeur saisie
    for tplMove in lcurMoves loop
      GenerateWizardMovement(tplMove.STM_TMP_STOCK_POSITION_ID, lOk);
    end loop;
  end GenerateWizardMovements;

  procedure setGenerateWizardMovementSp
  is
  begin
    savepoint spGenerateWizardMovement;
  end setGenerateWizardMovementSp;

  /**
  * Description
  *   Génération des mouvements de transformation de l'assistant de maintenance des caractérisations
  */
  procedure GenerateWizardMovement(iTmpStockPositionId in number, iGenerationOk out number)
  is
    cursor lcurMove(iTmpStockPositionId number)
    is
      select TMP.*
           , STO.C_ACCESS_METHOD
        from STM_TMP_STOCK_POSITION TMP
           , STM_STOCK STO
       where TMP.STM_TMP_STOCK_POSITION_ID = iTmpStockPositionId
         and TMP.STM_STOCK_ID = STO.STM_STOCK_ID;

    lNbChar          pls_integer;
    lOldGoodId       GCO_GOOD.GCO_GOOD_ID%type                           := 0;
    lAddedCharId     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
  begin
    iGenerationOk  := 1;

    -- pour chaque position, un mouvment de sortie 'N/A' et en mouvement d'entrée avec la valeur saisie
    for tplMove in lcurMove(iTmpStockPositionId) loop
      if tplMove.C_ACCESS_METHOD = 'PRIVATE' then
        declare
          lnCharID     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
          lvCharDesign GCO_CHARACTERIZATION.CHA_CHARACTERIZATION_DESIGN%type;
        begin
          -- Rechercher l'id et la descr de la caractérisation ajoutée
          select GCO_CHARACTERIZATION_ID
               , CHA_CHARACTERIZATION_DESIGN
            into lnCharID
               , lvCharDesign
            from GCO_CHARACTERIZATION
           where GCO_CHARACTERIZATION_ID = (select max(GCO_CHARACTERIZATION_ID)
                                              from GCO_CHARACTERIZATION
                                             where GCO_GOOD_ID = tplMove.GCO_GOOD_ID);

          LogCharacWizardEvent(iAction               => 'ERROR'
                             , iCharacterizationId   => lnCharID
                             , iCharDesign           => lvCharDesign
                             , iGoodId               => tplMove.GCO_GOOD_ID
                             , iErrorComment         => pcs.PC_FUNCTIONS.TranslateWord('Position de stock portant sur un stock privé!') ||
                                                        chr(10) ||
                                                        pcs.PC_FUNCTIONS.TranslateWord('Aucun traitement effectué')
                              );
        exception
          when no_data_found then
            null;
        end;
      else
        declare
          lInputStockMovementId  STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
          lOutputStockMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
          lOutputKindId          STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
          lInputKindId           STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
          lExerciseId            STM_EXERCISE.STM_EXERCISE_ID%type;
          lPeriodId              STM_PERIOD.STM_PERIOD_ID%type;
          lChar1                 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
          lChar2                 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_2%type;
          lChar3                 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_3%type;
          lChar4                 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_4%type;
          lChar5                 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_5%type;
        begin
          -- changement de bien
          if tplMove.GCO_GOOD_ID <> lOldGoodID then
            -- recherche du nombre de caractérisations gérées en stock
            select count(*)
              into lNbChar
              from GCO_CHARACTERIZATION CHA
                 , GCO_PRODUCT PDT
             where PDT.GCO_GOOD_ID = tplMove.GCO_GOOD_ID
               and CHA.GCO_GOOD_ID = PDT.GCO_GOOD_ID
               and CHA_STOCK_MANAGEMENT = 1
               and PDT_STOCK_MANAGEMENT = 1;

            -- Id de la caractérisation ajoutée
            lAddedCharId   :=
              nvl(tplMove.GCO4_GCO_CHARACTERIZATION_ID
                , nvl(tplMove.GCO3_GCO_CHARACTERIZATION_ID
                    , nvl(tplMove.GCO2_GCO_CHARACTERIZATION_ID, nvl(tplMove.GCO_GCO_CHARACTERIZATION_ID, tplMove.GCO_CHARACTERIZATION_ID) )
                     )
                 );
            -- mémorisation du bien courant
            lOldGoodID     := tplMove.GCO_GOOD_ID;
            iGenerationOk  := 1;
          end if;

          if iGenerationOk = 1 then
            -- recherche du type de mouvement de sortie
            select init_id_seq.nextval
                 , STM_MOVEMENT_KIND_ID
              into lOutputStockMovementId
                 , lOutputKindId
              from STM_MOVEMENT_KIND
             where C_MOVEMENT_CODE = '024'
               and C_MOVEMENT_TYPE = 'TRC'
               and C_MOVEMENT_SORT = 'SOR';

            -- recherche du type de mouvement d'entrée
            select init_id_seq.nextval
                 , STM_MOVEMENT_KIND_ID
              into lInputStockMovementId
                 , lInputKindId
              from STM_MOVEMENT_KIND
             where C_MOVEMENT_CODE = '024'
               and C_MOVEMENT_TYPE = 'TRC'
               and C_MOVEMENT_SORT = 'ENT';

            -- déterminer les valeur de chaque caractérisation
            select decode(lNbChar, 1, 'N/A', tplMove.SPO_CHARACTERIZATION_VALUE_1)
              into lChar1
              from dual;

            select decode(lNbChar, 2, 'N/A', tplMove.SPO_CHARACTERIZATION_VALUE_2)
              into lChar2
              from dual;

            select decode(lNbChar, 3, 'N/A', tplMove.SPO_CHARACTERIZATION_VALUE_3)
              into lChar3
              from dual;

            select decode(lNbChar, 4, 'N/A', tplMove.SPO_CHARACTERIZATION_VALUE_4)
              into lChar4
              from dual;

            select decode(lNbChar, 5, 'N/A', tplMove.SPO_CHARACTERIZATION_VALUE_5)
              into lChar5
              from dual;

            -- génération du mouvement de sortie
            STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lOutputStockMovementId
                                            , iGoodId                => tplMove.GCO_GOOD_ID
                                            , iMovementKindId        => lOutputKindId
                                            , iExerciseId            => STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(sysdate) )
                                            , iPeriodId              => STM_FUNCTIONS.GetPeriodId(sysdate)
                                            , iMvtDate               => STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(sysdate), sysdate)
                                            , iValueDate             => STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(sysdate), sysdate)
                                            , iStockId               => tplMove.STM_STOCK_ID
                                            , iLocationId            => tplMove.STM_LOCATION_ID
                                            , iThirdId               => null
                                            , iThirdAciId            => null
                                            , iThirdDeliveryId       => null
                                            , iThirdTariffId         => null
                                            , iRecordId              => null
                                            , iChar1Id               => tplMove.GCO_CHARACTERIZATION_ID
                                            , iChar2Id               => tplMove.GCO_GCO_CHARACTERIZATION_ID
                                            , iChar3Id               => tplMove.GCO2_GCO_CHARACTERIZATION_ID
                                            , iChar4Id               => tplMove.GCO3_GCO_CHARACTERIZATION_ID
                                            , iChar5Id               => tplMove.GCO4_GCO_CHARACTERIZATION_ID
                                            , iCharValue1            => lChar1
                                            , iCharValue2            => lChar2
                                            , iCharValue3            => lChar3
                                            , iCharValue4            => lChar4
                                            , iCharValue5            => lChar5
                                            , iMovement2Id           => null
                                            , iMovement3Id           => null
                                            , iWording               => 'Characterization Wizard'
                                            , iExternalDocument      => null
                                            , iExternalPartner       => null
                                            , iMvtQty                => tplMove.SPO_STOCK_QUANTITY
                                            , iMvtPrice              => 0
                                            , iDocQty                => 0
                                            , iDocPrice              => 0
                                            , iUnitPrice             => 0
                                            , iRefUnitPrice          => 0
                                            , iAltQty1               => 0
                                            , iAltQty2               => 0
                                            , iAltQty3               => 0
                                            , iDocPositionDetailId   => null
                                            , iDocPositionId         => null
                                            , iFinancialAccountId    => null
                                            , iDivisionAccountId     => null
                                            , iAFinancialAccountId   => null
                                            , iADivisionAccountId    => null
                                            , iCPNAccountId          => null
                                            , iACPNAccountId         => null
                                            , iCDAAccountId          => null
                                            , iACDAAccountId         => null
                                            , iPFAccountId           => null
                                            , iAPFAccountId          => null
                                            , iPJAccountId           => null
                                            , iAPJAccountId          => null
                                            , iFamFixedAssetsId      => null
                                            , iFamTransactionTyp     => null
                                            , iHrmPersonId           => null
                                            , iDicImpfree1Id         => null
                                            , iDicImpfree2Id         => null
                                            , iDicImpfree3Id         => null
                                            , iDicImpfree4Id         => null
                                            , iDicImpfree5Id         => null
                                            , iImpText1              => null
                                            , iImpText2              => null
                                            , iImpText3              => null
                                            , iImpText4              => null
                                            , iImpText5              => null
                                            , iImpNumber1            => null
                                            , iImpNumber2            => null
                                            , iImpNumber3            => null
                                            , iImpNumber4            => null
                                            , iImpNumber5            => null
                                            , iFinancialCharging     => null
                                            , iUpdateProv            => 0
                                            , iExtourneMvt           => 0
                                            , iRecStatus             => 2
                                            , iOrderKey              => null
                                             );
            -- Création des informations de tracabilité liée au mouvements de transformation (entrée traçabilité pour la valeur N/A)
            STM_PRC_MOVEMENT.AddTrsfTracability(iMovementId   => lOutputStockMovementId
                                              , iGoodId       => tplMove.GCO_GOOD_ID
                                              , iCharId1      => tplMove.GCO_CHARACTERIZATION_ID
                                              , iCharId2      => tplMove.GCO_GCO_CHARACTERIZATION_ID
                                              , iCharId3      => tplMove.GCO2_GCO_CHARACTERIZATION_ID
                                              , iCharId4      => tplMove.GCO3_GCO_CHARACTERIZATION_ID
                                              , iCharId5      => tplMove.GCO4_GCO_CHARACTERIZATION_ID
                                              , iOldChar1     => case
                                                  when lAddedCharId = tplMove.GCO_CHARACTERIZATION_ID then ''
                                                  else tplMove.SPO_CHARACTERIZATION_VALUE_1
                                                end
                                              , iNewChar1     => lChar1
                                              , iOldChar2     => case
                                                  when lAddedCharId = tplMove.GCO_GCO_CHARACTERIZATION_ID then ''
                                                  else tplMove.SPO_CHARACTERIZATION_VALUE_2
                                                end
                                              , iNewChar2     => lChar2
                                              , iOldChar3     => case
                                                  when lAddedCharId = tplMove.GCO2_GCO_CHARACTERIZATION_ID then ''
                                                  else tplMove.SPO_CHARACTERIZATION_VALUE_3
                                                end
                                              , iNewChar3     => lChar3
                                              , iOldChar4     => case
                                                  when lAddedCharId = tplMove.GCO3_GCO_CHARACTERIZATION_ID then ''
                                                  else tplMove.SPO_CHARACTERIZATION_VALUE_4
                                                end
                                              , iNewChar4     => lChar4
                                              , iOldChar5     => case
                                                  when lAddedCharId = tplMove.GCO4_GCO_CHARACTERIZATION_ID then ''
                                                  else tplMove.SPO_CHARACTERIZATION_VALUE_5
                                                end
                                              , iNewChar5     => lChar5
                                               );
            -- génération du mouvement d'entrée
            STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lInputStockMovementId
                                            , iGoodId                => tplMove.GCO_GOOD_ID
                                            , iMovementKindId        => lInputKindId
                                            , iExerciseId            => STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(sysdate) )
                                            , iPeriodId              => STM_FUNCTIONS.GetPeriodId(sysdate)
                                            , iMvtDate               => STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(sysdate), sysdate)
                                            , iValueDate             => STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(sysdate), sysdate)
                                            , iStockId               => tplMove.STM_STOCK_ID
                                            , iLocationId            => tplMove.STM_LOCATION_ID
                                            , iThirdId               => null
                                            , iThirdAciId            => null
                                            , iThirdDeliveryId       => null
                                            , iThirdTariffId         => null
                                            , iRecordId              => null
                                            , iChar1Id               => tplMove.GCO_CHARACTERIZATION_ID
                                            , iChar2Id               => tplMove.GCO_GCO_CHARACTERIZATION_ID
                                            , iChar3Id               => tplMove.GCO2_GCO_CHARACTERIZATION_ID
                                            , iChar4Id               => tplMove.GCO3_GCO_CHARACTERIZATION_ID
                                            , iChar5Id               => tplMove.GCO4_GCO_CHARACTERIZATION_ID
                                            , iCharValue1            => tplMove.SPO_CHARACTERIZATION_VALUE_1
                                            , iCharValue2            => tplMove.SPO_CHARACTERIZATION_VALUE_2
                                            , iCharValue3            => tplMove.SPO_CHARACTERIZATION_VALUE_3
                                            , iCharValue4            => tplMove.SPO_CHARACTERIZATION_VALUE_4
                                            , iCharValue5            => tplMove.SPO_CHARACTERIZATION_VALUE_5
                                            , iMovement2Id           => lOutputStockMovementId
                                            , iMovement3Id           => null
                                            , iWording               => 'Characterization Wizard'
                                            , iExternalDocument      => null
                                            , iExternalPartner       => null
                                            , iMvtQty                => tplMove.SPO_STOCK_QUANTITY
                                            , iMvtPrice              => 0
                                            , iDocQty                => 0
                                            , iDocPrice              => 0
                                            , iUnitPrice             => 0
                                            , iRefUnitPrice          => 0
                                            , iAltQty1               => 0
                                            , iAltQty2               => 0
                                            , iAltQty3               => 0
                                            , iDocPositionDetailId   => null
                                            , iDocPositionId         => null
                                            , iFinancialAccountId    => null
                                            , iDivisionAccountId     => null
                                            , iAFinancialAccountId   => null
                                            , iADivisionAccountId    => null
                                            , iCPNAccountId          => null
                                            , iACPNAccountId         => null
                                            , iCDAAccountId          => null
                                            , iACDAAccountId         => null
                                            , iPFAccountId           => null
                                            , iAPFAccountId          => null
                                            , iPJAccountId           => null
                                            , iAPJAccountId          => null
                                            , iFamFixedAssetsId      => null
                                            , iFamTransactionTyp     => null
                                            , iHrmPersonId           => null
                                            , iDicImpfree1Id         => null
                                            , iDicImpfree2Id         => null
                                            , iDicImpfree3Id         => null
                                            , iDicImpfree4Id         => null
                                            , iDicImpfree5Id         => null
                                            , iImpText1              => null
                                            , iImpText2              => null
                                            , iImpText3              => null
                                            , iImpText4              => null
                                            , iImpText5              => null
                                            , iImpNumber1            => null
                                            , iImpNumber2            => null
                                            , iImpNumber3            => null
                                            , iImpNumber4            => null
                                            , iImpNumber5            => null
                                            , iFinancialCharging     => null
                                            , iUpdateProv            => 0
                                            , iExtourneMvt           => 0
                                            , iRecStatus             => 2
                                            , iOrderKey              => null
                                             );
            -- Création des informations de tracabilité liée au mouvements de transformation
            STM_PRC_MOVEMENT.AddTrsfTracability(iMovementId   => lOutputStockMovementId
                                              , iGoodId       => tplMove.GCO_GOOD_ID
                                              , iCharId1      => tplMove.GCO_CHARACTERIZATION_ID
                                              , iCharId2      => tplMove.GCO_GCO_CHARACTERIZATION_ID
                                              , iCharId3      => tplMove.GCO2_GCO_CHARACTERIZATION_ID
                                              , iCharId4      => tplMove.GCO3_GCO_CHARACTERIZATION_ID
                                              , iCharId5      => tplMove.GCO4_GCO_CHARACTERIZATION_ID
                                              , iOldChar1     => lChar1
                                              , iNewChar1     => tplMove.SPO_CHARACTERIZATION_VALUE_1
                                              , iOldChar2     => lChar2
                                              , iNewChar2     => tplMove.SPO_CHARACTERIZATION_VALUE_2
                                              , iOldChar3     => lChar3
                                              , iNewChar3     => tplMove.SPO_CHARACTERIZATION_VALUE_3
                                              , iOldChar4     => lChar4
                                              , iNewChar4     => tplMove.SPO_CHARACTERIZATION_VALUE_4
                                              , iOldChar5     => lChar5
                                              , iNewChar5     => tplMove.SPO_CHARACTERIZATION_VALUE_5
                                               );
            -- Mise à jour des éléments de caractérisation
            lElementNumberId  := STM_LIB_ELEMENT_NUMBER.GetDetailElementFromStockMov(lInputStockMovementId);

            if tplMove.GCO_QUALITY_STATUS_ID <> 0 then
              STM_PRC_ELEMENT_NUMBER.ChangeStatus(lElementNumberId, tplMove.GCO_QUALITY_STATUS_ID);
            end if;

            if tplMove.SEM_RETEST_DATE is not null then
              STM_PRC_ELEMENT_NUMBER.ChangeRetestDate(lElementNumberId, tplMove.SEM_RETEST_DATE);
            end if;
          end if;
        exception
          when others then
            declare
              lCharDesign GCO_CHARACTERIZATION.CHA_CHARACTERIZATION_DESIGN%type;
              lError      number(1);
            begin
              select CHA_CHARACTERIZATION_DESIGN
                into lCharDesign
                from GCO_CHARACTERIZATION
               where GCO_CHARACTERIZATION_ID = lAddedCharId;

              -- 1) Ecriture de l'erreur dans la table de log
              LogCharacWizardEvent(iAction               => 'ERA'
                                 , iCharacterizationId   => lAddedCharId
                                 , iCharDesign           => lCharDesign
                                 , iGoodId               => lOldGoodID
                                 , iErrorComment         => sqlerrm || chr(13) || DBMS_UTILITY.Format_Error_backtrace
                                  );
              -- en cas d'erreur dans le traitement
              -- 2) annulation des éventuels mouvements effectués pour l'article traité
              rollback to spGenerateWizardMovement;

              -- 3) Suppression de la ligne de log d'ajout
              delete from GCO_CHAR_WIZARD_LOG
                    where GCO_CHARACTERIZATION_ID = lAddedCharId
                      and C_GCO_CHAR_WIZARD_ACTION = 'ADD';

              -- 4) suppression de la caractérisation créée
              removeCharToExisting(lAddedCharId, true, lError);
              iGenerationOk  := 0;
            end;
        end;
      end if;
    end loop;
  end GenerateWizardMovement;

  procedure removeInventory(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    -- Inventaires externes
    for tplInvExt in (select distinct STM_INVENTORY_EXTERNAL_ID
                                 from STM_INVENTORY_EXTERNAL_LINE
                                where GCO_GOOD_ID = iGoodID) loop
      for tplInvExtLine in (select STM_INVENTORY_EXTERNAL_LINE_ID
                              from STM_INVENTORY_EXTERNAL_LINE
                             where STM_INVENTORY_EXTERNAL_ID = tplInvExt.STM_INVENTORY_EXTERNAL_ID
                               and GCO_GOOD_ID = iGoodID) loop
        -- historique des modifications (inventaires externes)
        delete from STM_INVENTORY_EXTERNAL_LOG
              where STM_INVENTORY_EXTERNAL_LINE_ID = tplInvExtLine.STM_INVENTORY_EXTERNAL_LINE_ID;

        -- lignes d'un inventaire externe
        delete from STM_INVENTORY_EXTERNAL_LINE
              where STM_INVENTORY_EXTERNAL_LINE_ID = tplInvExtLine.STM_INVENTORY_EXTERNAL_LINE_ID;
      end loop;

      -- suppression de l'inventaire externe si celui-ci est vide
      delete from STM_INVENTORY_EXTERNAL IXT
            where STM_INVENTORY_EXTERNAL_ID = tplInvExt.STM_INVENTORY_EXTERNAL_ID
              and not exists(select STM_INVENTORY_EXTERNAL_LINE_ID
                               from STM_INVENTORY_EXTERNAL_LINE IEX
                              where IEX.STM_INVENTORY_EXTERNAL_ID = IXT.STM_INVENTORY_EXTERNAL_ID);

      if sql%found then
        -- l'inventaire externe a pu être supprimé, mise à jour des tables "annexes"
        update stm_inventory_list ili
           set ili.stm_inventory_external_id = null
         where ili.stm_inventory_external_id = tplInvExt.STM_INVENTORY_EXTERNAL_ID;
      end if;
    end loop;

    -- journaux
    for tplInvJob in (select distinct STM_INVENTORY_JOB_ID
                                 from STM_INVENTORY_JOB_DETAIL
                                where GCO_GOOD_ID = iGoodID) loop
      -- quantités
      delete from STM_INVENTORY_JOB_DETAIL
            where STM_INVENTORY_JOB_ID = tplInvJob.STM_INVENTORY_JOB_ID
              and GCO_GOOD_ID = iGoodID;

      -- journal
      delete from STM_INVENTORY_JOB
            where STM_INVENTORY_JOB_ID = tplInvJob.STM_INVENTORY_JOB_ID
              and not exists(select STM_INVENTORY_JOB_DETAIL_ID
                               from STM_INVENTORY_JOB_DETAIL
                              where STM_INVENTORY_JOB_ID = tplInvJob.STM_INVENTORY_JOB_ID);
    end loop;

    -- extractions
    for tplInvList in (select distinct STM_INVENTORY_LIST_ID
                                  from STM_INVENTORY_LIST_POS
                                 where GCO_GOOD_ID = iGoodID) loop
      -- positions
      delete from STM_INVENTORY_LIST_POS
            where STM_INVENTORY_LIST_ID = tplInvList.STM_INVENTORY_LIST_ID
              and GCO_GOOD_ID = iGoodID;

      -- journaux liés à la liste si celle-ci est vide
      delete from STM_INVENTORY_JOB IJO
            where IJO.STM_INVENTORY_LIST_ID = tplInvList.STM_INVENTORY_LIST_ID
              and not exists(select ILI.STM_INVENTORY_LIST_POS_ID
                               from STM_INVENTORY_LIST_POS ILI
                              where ILI.STM_INVENTORY_LIST_ID = IJO.STM_INVENTORY_LIST_ID);

      -- extraction
      delete from STM_INVENTORY_LIST ILI
            where ILI.STM_INVENTORY_LIST_ID = tplInvList.STM_INVENTORY_LIST_ID
              and not exists(select ILP.STM_INVENTORY_LIST_POS_ID
                               from STM_INVENTORY_LIST_POS ILP
                              where ILP.STM_INVENTORY_LIST_ID = ILI.STM_INVENTORY_LIST_ID);
    end loop;

    -- utilisateurs connectés
    delete from STM_INVENTORY_LIST_USER ILU
          where not exists(select STM_INVENTORY_LIST_ID
                             from STM_INVENTORY_LIST
                            where STM_INVENTORY_LIST_ID = ILU.STM_INVENTORY_LIST_ID)
             or not exists(select STM_INVENTORY_JOB_ID
                             from STM_INVENTORY_JOB
                            where STM_INVENTORY_JOB_ID = ILU.STM_INVENTORY_JOB_ID);

    -- table temporaire pour données en cours de saisie
    delete from STM_INVENTORY_LIST_WORK
          where GCO_GOOD_ID = iGoodID;

    -- historique de modification/suppression des attributions sur stock
    delete from STM_INVENTORY_UPDATED_LINKS
          where GCO_GOOD_ID = iGoodID;

    -- impressions
    delete from STM_INVENTORY_PRINT IPT
          where not exists(select STM_INVENTORY_JOB_ID
                             from STM_INVENTORY_JOB
                            where STM_INVENTORY_JOB_ID = IPT.STM_INVENTORY_JOB_ID)
             or not exists(select STM_INVENTORY_EXTERNAL_ID
                             from STM_INVENTORY_EXTERNAL
                            where STM_INVENTORY_EXTERNAL_ID = IPT.STM_INVENTORY_EXTERNAL_ID)
             or not exists(select STM_INVENTORY_LIST_ID
                             from STM_INVENTORY_LIST
                            where STM_INVENTORY_LIST_ID = IPT.STM_INVENTORY_LIST_ID);

    -- inventaires
    delete from STM_INVENTORY_TASK TSK
          where not exists(select STM_INVENTORY_JOB_ID
                             from STM_INVENTORY_JOB IJO
                            where IJO.STM_INVENTORY_TASK_ID = TSK.STM_INVENTORY_TASK_ID)
            and not exists(select STM_INVENTORY_JOB_DETAIL_ID
                             from STM_INVENTORY_JOB_DETAIL IJD
                            where IJD.STM_INVENTORY_TASK_ID = TSK.STM_INVENTORY_TASK_ID)
            and not exists(select STM_INVENTORY_LIST_ID
                             from STM_INVENTORY_LIST ILI
                            where ILI.STM_INVENTORY_TASK_ID = TSK.STM_INVENTORY_TASK_ID)
            and not exists(select STM_INVENTORY_LIST_POS_ID
                             from STM_INVENTORY_LIST_POS ILP
                            where ILP.STM_INVENTORY_TASK_ID = TSK.STM_INVENTORY_TASK_ID)
            and not exists(select STM_INVENTORY_LIST_POS_ID
                             from STM_INVENTORY_LIST_WORK ILW
                            where ILW.STM_INVENTORY_TASK_ID = TSK.STM_INVENTORY_TASK_ID)
            and not exists(select STM_INVENTORY_EXTERNAL_ID
                             from STM_INVENTORY_EXTERNAL IXT
                            where IXT.STM_INVENTORY_TASK_ID = TSK.STM_INVENTORY_TASK_ID)
            and not exists(select STM_INVENTORY_UPDATED_LINKS_ID
                             from STM_INVENTORY_UPDATED_LINKS IUL
                            where IUL.STM_INVENTORY_TASK_ID = TSK.STM_INVENTORY_TASK_ID);
  end removeInventory;
end GCO_PRC_CHARACTERIZATION;
