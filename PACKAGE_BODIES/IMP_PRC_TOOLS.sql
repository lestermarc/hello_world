--------------------------------------------------------
--  DDL for Package Body IMP_PRC_TOOLS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_PRC_TOOLS" 
as
  /**
  * Description
  *    Verifie si la valeur existe pour le dictionne transmis. Si la valeur n'existe pas, insère une erreur dans la table
  *    des erreurs.
  */
  procedure checkDicoValue(iDicoName in varchar2, iDicoValue in varchar2, iDomain in varchar2, iImportId in number, iExcelLine in varchar2)
  as
    lExists integer;
    lErrMsg varchar2(4000);
  begin
    execute immediate 'select Count(*)
                         from DUAL
                        where exists(select 1 from ' ||
                      iDicoName ||
                      ' where ' ||
                      iDicoName ||
                      '_ID = :iDicoValue)'
                 into lExists
                using in iDicoValue;

    if lExists = 0 then
      /* Insertion dans la table d'erreur */
      lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La valeur ''[XXXX]'' n''existe pas dans le dictionnaire ''[YYYY]''.');
      lErrMsg  := replace(replace(lErrMsg, '[XXXX]', iDicoValue), '[YYYY]', iDicoName);
      insertError(iDomain, iImportId, iExcelLine, lErrMsg);
    end if;
  exception
    when others then
      /* Insertion dans la table d'erreur */
      lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le dictionnaire ''[XXXX]'' n''existe pas.');
      lErrMsg  := replace(lErrMsg, '[XXXX]', iDicoName);
      insertError(iDomain, iImportId, iExcelLine, lErrMsg);
  end checkDicoValue;

  /**
  * Description
  *    Verifie si la valeur est un nombre entier. Dans le cas contraire, insère une erreur dans la table des erreurs.
  */
  procedure checkIntegerValue(iFieldName in varchar2, iFieldValue in number, iDomain in varchar2, iImportId in number, iExcelLine in varchar2)
  as
    lErrMsg varchar2(4000);
  begin
    if trunc(iFieldValue) < iFieldValue then
      lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La valeur ''[XXXX]'' du champ  ''[YYYY]'' doit être un nombre entier.');
      lErrMsg  := replace(replace(lErrMsg, '[XXXX]', iFieldValue), '[YYYY]', iFieldName);
      insertError(iDomain, iImportId, iExcelLine, lErrMsg);
    end if;
  end checkIntegerValue;

  /**
  * Description
  *    Verifie si la valeur existe pour le descode transmis. Si la valeur n'existe pas, insère une erreur dans la table
  *    des erreurs. Possibilité de définir les valeurs possibles.
  */
  procedure checkDescodeValue(
    iDescodeName      in varchar2
  , iDescodeValue     in varchar2
  , iAuthorizedValues in varchar2 default null
  , iDomain           in varchar2
  , iImportId         in number
  , iExcelLine        in varchar2
  )
  as
    lExists integer        := 0;
    lErrMsg varchar2(4000);
  begin
    if iAuthorizedValues is not null then
      if instr(iAuthorizedValues, iDescodeValue) = 0 then
        /* Insertion dans la table d'erreur */
        lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La valeur ''[XXXX]'' n''est pas autorisée pour le code ''[YYYY]''.');
        lErrMsg  := lErrMsg || ' ' || pcs.PC_FUNCTIONS.TranslateWord('Valeur autorisées : ''[ZZZZ]''');
        lErrMsg  := replace(replace(replace(lErrMsg, '[XXXX]', iDescodeValue), '[YYYY]', iDescodeName), '[ZZZZ]', iAuthorizedValues);
        insertError(iDomain, iImportId, iExcelLine, lErrMsg);
      end if;
    else
      select count(*)
        into lExists
        from dual
       where exists(select gclcode
                      from V_COM_CPY_PCS_CODES
                     where GCGNAME = upper(iDescodeName)
                       and gclcode = iDescodeValue);

      if lExists = 0 then
        /* Insertion dans la table d'erreur */
        lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La valeur ''[XXXX]'' n''est pas autorisée pour le code ''[YYYY]''.');
        lErrMsg  := replace(replace(lErrMsg, '[XXXX]', iDescodeValue), '[YYYY]', iDescodeName);
        insertError(iDomain, iImportId, iExcelLine, lErrMsg);
      end if;
    end if;
  exception
    when others then
      /* Insertion dans la table d'erreur */
      insertError(iDomain, iImportId, iExcelLine, sqlerrm);
  end checkDescodeValue;

  /**
  * Description
  *    Verifie si la valeur est correcte pour le boolean transmis (0 ou 1). Si la valeur n'est pas correcte, insère une erreur
  *    dans la table des erreurs.
  */
  procedure checkBooleanValue(iBooleanName in varchar2, iBooleanValue in varchar2, iDomain in varchar2, iImportId in number, iExcelLine in varchar2)
  as
    lErrMsg varchar2(4000);
  begin
    if instr('0,1', iBooleanValue) = 0 then
      /* Insertion dans la table d'erreur */
      lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La valeur ''[XXXX]'' n''est pas autorisée pour le boolean ''[YYYY]''. Valeurs autorisées : {0, 1}');
      lErrMsg  := replace(replace(lErrMsg, '[XXXX]', iBooleanValue), '[YYYY]', iBooleanName);
      insertError(iDomain, iImportId, iExcelLine, lErrMsg);
    end if;
  exception
    when others then
      /* Insertion dans la table d'erreur */
      insertError(iDomain, iImportId, iExcelLine, sqlerrm);
  end checkBooleanValue;

  /**
  * Description
  *    Verifie si la valeur est correcte pour le champ transmis. Si la valeur n'est pas correcte, insère une erreur dans la table
  *    des erreurs. Possibilité de restreindre le signe des valeurs possibles ainsi que d'inclure/exclure le 0.
  */
  procedure checkNumberValue(
    iTableName   in varchar2
  , iFieldName   in varchar2
  , iFieldValue  in varchar2
  , iDomain      in varchar2
  , iImportId    in number
  , iExcelLine   in varchar2
  , iIncludeZero in boolean default false
  , iSignType    in signtype default gcPositiveSignOnly
  )
  as
    lPrecision   number;
    lDecimals    number;
    lMaxAbsolute number;
    lMinValue    number;
    lMaxValue    number;
    lErrMsg      varchar2(4000);
  begin
    -- Calcul de la valeur max absolue possible.
--     select nvl(fld.FLDLENGTH, cols.DATA_PRECISION)
--          , nvl(fld.FLDDECIM, cols.DATA_SCALE)
--       into lPrecision
--          , lDecimals
--       from pcs.PC_FLDSC fld
--          , ALL_TAB_COLUMNS cols
--      where fld.FLDNAME(+) = cols.COLUMN_NAME
--        and OWNER = PCS.PC_I_LIB_SESSION.GetCompanyOwner
--        and TABLE_NAME = upper(iTableName)
--        and COLUMN_NAME = upper(iFieldName);
    -- Ne pas regarder dans la gestion des champs pour ces informations, car les valeurs
    -- ne sont pas toujours cohérentes (cf TAS_QTY_REF_AMOUNT par exemple).
    select DATA_PRECISION
         , DATA_SCALE
      into lPrecision
         , lDecimals
      from ALL_TAB_COLUMNS
     where OWNER = PCS.PC_I_LIB_SESSION.GetCompanyOwner
       and TABLE_NAME = upper(iTableName)
       and COLUMN_NAME = upper(iFieldName);
    lMaxAbsolute  := power(10, lPrecision - lDecimals) - power(10, -lDecimals);

    -- Définition des bornes
    case iSignType
      when gcNegativeSignOnly then
        begin
          lMinValue  := -lMaxAbsolute;
          lMaxValue  := 0;
        end;
      when gcPositiveSignOnly then
        begin
          lMinValue  := 0;
          lMaxValue  := lMaxAbsolute;
        end;
      when gcIndifferentSign then
        begin
          lMinValue  := -lMaxAbsolute;
          lMaxValue  := lMaxAbsolute;
        end;
    end case;

    if    (iFieldValue not between lMinValue and lMaxValue)
       or (    iFieldValue = 0
           and not(iIncludeZero) ) then
      if not iIncludeZero then
        if lMinValue = 0 then
          lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La valeur doit être comprise entre [MIN_VALUE] (non compris) et [MAX_VALUE].');
        elsif lMaxValue = 0 then
          lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La valeur doit être comprise entre [MIN_VALUE] et [MAX_VALUE] (non compris).');
        end if;
      else
        lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La valeur doit être comprise entre [MIN_VALUE] et [MAX_VALUE].');
      end if;

      lErrMsg  := replace(replace(lErrMsg, '[MIN_VALUE]', lMinValue), '[MAX_VALUE]', lMaxValue);
      lErrMsg  := iFieldName || ' : ' || lErrMsg;
      /* Insertion dans la table d'erreur */
      insertError(iDomain, iImportId, iExcelLine, lErrMsg);
    end if;
  exception
    when others then
      if sqlcode = -6502 then
        /* Insertion dans la table d'erreur */
        insertError(iDomain, iImportId, iExcelLine, pcs.PC_FUNCTIONS.TranslateWord('La valeur n''est pas numérique.') );
      else
        insertError(iDomain, iImportId, iExcelLine, sqlerrm);
      end if;
  end checkNumberValue;

  /**
  * Description
  *    Vérifie la présence de la langue transmise dans l'ERP
  */
  procedure checkLanguage(iLanID in varchar2, iDomain in varchar2, iImportId in number, iExcelLine in varchar2)
  as
    lExists number;
  begin
    select count(*)
      into lExists
      from dual
     where exists(select PC_LANG_ID
                    from pcs.PC_LANG
                   where LANID = upper(iLanID) );

    if lExists = 0 then
      insertError(iDomain, iImportId, iExcelLine
                , replace(pcs.PC_FUNCTIONS.TranslateWord('La langue [XXXXX] n''existe pas'), '[XXXXX]', '''' || iLanID || '''') );
    end if;
  end checkLanguage;

  /**
  * Description
  *    Vérifie s'il existe un bien dans l'ERP avec la référence principale transmise. Si inexistant, insère une
  *    erreur dans la table d'erreur d'importation ('Bien inexistant').
  */
  procedure checkGoodExists(iMajorRef in GCO_GOOD.GOO_MAJOR_REFERENCE%type, iDomain in varchar2, iImportId in number, iExcelLine in varchar2)
  as
    lExists number;
  begin
    select count(*)
      into lExists
      from dual
     where exists(select GCO_GOOD_ID
                    from GCO_GOOD
                   where GOO_MAJOR_REFERENCE = iMajorRef);

    if lExists = 0 then   -- Bien inexistant
      insertError(iDomain, iImportId, iExcelLine, pcs.PC_FUNCTIONS.TranslateWord('IMP_GOO_MAJOR_REFERENCE_MAIN_2') );
    end if;
  end checkGoodExists;

  /**
  * Description
  *    Vérifie la cohérence et l'existence des stocks et emplacement de stock transmis.
  */
  procedure checkStockAndLocataion(
    iStockDescr        in varchar2
  , iLocationDescr     in varchar2
  , iDomain            in varchar2
  , iImportId          in number
  , iExcelLine         in varchar2
  , iMandatoryLocation in boolean default true
  )
  as
    lExists number;
  begin
    /* Si seul le stock ou l'emplacement est renseigné --> Incohérence dans les stock */
    if    (    iStockDescr is null
           and iLocationDescr is not null)
       or (    iStockDescr is not null
           and iLocationDescr is null
           and iMandatoryLocation) then
      insertError(iDomain, iImportId, iExcelLine, pcs.PC_FUNCTIONS.TranslateWord('IMP_STM_STOCK_ID') );
    else
      select count(*)
        into lExists
        from dual
       where exists(select STM_STOCK_ID
                      from STM_STOCK
                     where STO_DESCRIPTION = iStockDescr);

      if lExists > 0 then
        if    iMandatoryLocation
           or iLocationDescr is not null then
          select count(*)
            into lExists
            from dual
           where exists(select loc.STM_LOCATION_ID
                          from STM_STOCK sto
                             , STM_LOCATION loc
                         where sto.STM_STOCK_ID = loc.STM_STOCK_ID
                           and sto.STO_DESCRIPTION = iStockDescr
                           and loc.LOC_DESCRIPTION = iLocationDescr);

          if lExists = 0 then
            --Création d'une erreur 'emplacement inexistant'
            insertError(iDomain, iImportId, iExcelLine, pcs.pc_functions.TranslateWord('Description d''emplacement de stock inexistante') );
          end if;
        end if;
      else
        --Création d'une erreur 'stock inexistant'
        insertError(iDomain, iImportId, iExcelLine, pcs.pc_functions.TranslateWord('Description de stock inexistante') );
      end if;
    end if;
  end checkStockAndLocataion;

  /**
  * Description
  *    Vérifie l'existance d'une erreur pour le domaine transmis dans la table des erreurs. Si aucun erreur trouvée, insère une 'erreur' contenant
  *    le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur : 'Aucune erreur'
  */
  procedure checkErrors(iDomain in varchar2)
  as
    lExists number;
  begin
    select count(*)
      into lExists
      from dual
     where exists(select IMP_CTRL_ERRORS_ID
                    from IMP_CTRL_ERRORS
                   where ERR_DOMAIN = iDomain);

    --Si la table d'erreurs du domaine est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    if (lExists = 0) then
      insertError(iDomain, null, 0, pcs.pc_functions.TranslateWord('IMP_NO_ERROR'), 'NO_ERRORS');
    end if;
  end checkErrors;

  /**
  * Description
  *    Vérifie l'absence d'erreurs pour le domaine transmis dans la table des erreurs à l'exception de 'l'erreur' contenant
  *    le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur : 'Aucune erreur'.
  *    Lève une erreur si au moins une erreur existe pour le domaine.
  */
  procedure checkErrorsBeforeImport(iDomain in varchar2)
  as
    lExists number;
  begin
    -- Contrôle que la table d'erreurs soit vide
    select count(*)
      into lExists
      from dual
     where exists(select IMP_CTRL_ERRORS_ID
                    from IMP_CTRL_ERRORS
                   where ERR_DOMAIN = iDomain
                     and nvl(ERR_NO, 'X') != 'NO_ERRORS');

    if (lExists > 0) then
      raise_application_error(-20000, pcs.pc_functions.TranslateWord('IMP_ERROR_NOT_EMPTY') );
    end if;
  end checkErrorsBeforeImport;

  /**
  * Description
  *    Supprime les erreurs du domaine transmis.
  */
  procedure deleteErrors(iDomain in varchar2)
  as
  begin
    -- Suppression des erreurs du domaine concerné.
    delete from IMP_CTRL_ERRORS
          where ERR_DOMAIN = iDomain;
  end deleteErrors;

  /**
  * procedure insertError
  * Description
  *    Insère une erreur dans la table d'erreur.
  */
  procedure insertError(
    iDomain         in varchar2
  , iErrImportId    in number
  , iExcelLine      in varchar2
  , iErrDescription in varchar2
  , iErrNo          in varchar2 default null
  , iErrValue       in varchar2 default null
  , iErrDate        in date default sysdate
  )
  as
  begin
    insert into IMP_CTRL_ERRORS
                (IMP_CTRL_ERRORS_ID
               , ERR_DOMAIN
               , ERR_EXCEL_LINE
               , ERR_NO
               , ERR_VALUE
               , ERR_DESCRIPTION
               , ERR_IMPORT_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , iDomain
               , iExcelLine
               , iErrNo
               , iErrValue
               , iErrDescription
               , iErrImportId
               , iErrDate
               , pcs.PC_I_LIB_SESSION.GetUserIni
                );
  end insertError;
end IMP_PRC_TOOLS;
