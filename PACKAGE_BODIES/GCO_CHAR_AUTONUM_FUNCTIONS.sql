--------------------------------------------------------
--  DDL for Package Body GCO_CHAR_AUTONUM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_CHAR_AUTONUM_FUNCTIONS" 
is
  /**
  * Description
  *   Apelle la fonction de numérotation effectue la vérification d'unicité et effectue
  *   un rollback si cette dernière echoue
  */
  procedure CallAndVerify(aCharId in number, aCallFrom in varchar2, aRefId in number, aNewCharValue out varchar2)
  is
    vSqlCommand            varchar2(2000);
    vProcedureName         GCO_CHAR_AUTONUM_FUNC.CAF_NUMBERING_FUNCTION%type;
    vCharactType           GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    vGoodId                GCO_GOOD.GCO_GOOD_ID%type;
    vAutonomousTransaction GCO_CHAR_AUTONUM_FUNC.CAF_AUTONOMOUS_TRANSACTION%type;

    -- Execution de la commande en mode transaction autonome
    function ExecuteCommandAT(aSqlCommand in varchar2, aGoodId in number, aCharactType in varchar2, aCharId in number, aCallFrom in varchar2, aRefId in number)
      return varchar2
    is
      vResult varchar2(30);
      pragma autonomous_transaction;
    begin
      execute immediate aSqlCommand
                  using aCharId, aCallFrom, aRefId, out vResult;

      -- si on a un valeur de retour de la part de la procedure de numérotation
      -- on vérifie que cette valeur soit compatible avec les config d'unicité
      if vResult is not null then
        if STM_I_PRC_STOCK_POSITION.GetControlMode(aGoodId, aCharactType, vResult) = 1 then
          vResult  := '';
          rollback;
        end if;
      end if;

      commit;
      return vResult;
    end;

    -- Execution de la commande en mode normal sans transaction autonome
    function ExecuteCommand(aSqlCommand in varchar2, aGoodId in number, aCharactType in varchar2, aCharId in number, aCallFrom in varchar2, aRefId in number)
      return varchar2
    is
      vResult varchar2(30);
    begin
      savepoint beginExecuteCommand;

      execute immediate aSqlCommand
                  using aCharId, aCallFrom, aRefId, out vResult;

      -- si on a un valeur de retour de la part de la procedure de numérotation
      -- on vérifie que cette valeur soit compatible avec les config d'unicité
      if vResult is not null then
        if STM_I_PRC_STOCK_POSITION.GetControlMode(aGoodId, aCharactType, vResult) = 1 then
          vResult  := '';
          rollback to beginExecuteCommand;
        end if;
      end if;

      return vResult;
    end;
  begin
    -- recherche du nom de la procedure à exécuter
    begin
      select A.GCO_GOOD_ID
           , A.C_CHARACT_TYPE
           , B.CAF_NUMBERING_FUNCTION
           , B.CAF_AUTONOMOUS_TRANSACTION
        into vGoodId
           , vCharactType
           , vProcedureName
           , vAutonomousTransaction
        from GCO_CHARACTERIZATION A
           , GCO_CHAR_AUTONUM_FUNC B
       where A.GCO_CHARACTERIZATION_ID = aCharId
         and B.GCO_CHAR_AUTONUM_FUNC_ID = A.GCO_CHAR_AUTONUM_FUNC_ID;
    exception
      when no_data_found then
        raise_application_error(-20000, 'PCS - No Numbering method linked to the characterization');
    end;

    -- Appelle de la procedure plsql qui doit nous donner la prochaine valeur de la caractérisation
    -- et mettre à jour les compteurs adéquats
    vSqlCommand  := 'BEGIN ' || vProcedureName || '(:ACHARID, :ACALLFROM, :AREFID, :ANEWCHARVALUE); END;';

    if vAutonomousTransaction = 1 then
      aNewCharValue  := ExecuteCommandAT(vSqlCommand, vGoodID, vCharactType, aCharId, aCallFrom, aRefId);
    else
      aNewCharValue  := ExecuteCommand(vSqlCommand, vGoodID, vCharactType, aCharId, aCallFrom, aRefId);
    end if;
  exception
    when others then
      aNewCharValue  := '';
  end CallAndVerify;

  /**
  * Description
  *   Numérotation automatique avec prefixe et suffixe, unique par société (si toutes les
  *   caractérisations de type pièce utilisent cette fonction!)
  *   gêrant les compteurs au niveau de la table GCO_CHAR_AUTONUM_FUNC
  */
  procedure CompanyPrefixeSuffixeAutoNum(aCharId in number, aCallFrom in varchar2, aRefId in number, aNewCharValue out varchar2)
  is
    vSuffixe GCO_CHAR_AUTONUM_FUNC.CAF_SUFFIXE%type;
  begin
    select CAF_SUFFIXE
      into vSuffixe
      from GCO_CHAR_AUTONUM_FUNC
     where GCO_CHAR_AUTONUM_FUNC_ID = (select GCO_CHAR_AUTONUM_FUNC_ID
                                         from GCO_CHARACTERIZATION A
                                        where A.GCO_CHARACTERIZATION_ID = aCharId);

    if vSuffixe = '-YY' then
      vSuffixe  := '-' || to_char(sysdate, 'yy');
    end if;

    update    GCO_CHAR_AUTONUM_FUNC
          set CAF_LAST_USED_INCREMENT = PCS.PC_PREFIXE.IncrementNumber(CAF_LAST_USED_INCREMENT, nvl(CAF_INCREMENT_STEP, 1) )
            , A_DATEMOD = sysdate
            , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
        where GCO_CHAR_AUTONUM_FUNC_ID = (select GCO_CHAR_AUTONUM_FUNC_ID
                                            from GCO_CHARACTERIZATION A
                                           where A.GCO_CHARACTERIZATION_ID = aCharId)
    returning CAF_PREFIXE || lpad(CAF_LAST_USED_INCREMENT, 7, '0') || vSuffixe
         into aNewCharValue;
  end CompanyPrefixeSuffixeAutoNum;

  /**
  *   Numérotation automatique avec prefixe et suffixe, unique par bien (même si toutes les
  *   caractérisations de type pièce utilisent cette fonction!)
  *   gêrant les compteurs au niveau de la table GCO_CHARACTERIZATION
  */
  procedure GoodPrefixeSuffixeAutoNum(aCharId in number, aCallFrom in varchar2, aRefId in number, aNewCharValue out varchar2)
  is
    vSuffixe GCO_CHARACTERIZATION.CHA_SUFFIXE%type;
  begin
    select CHA_SUFFIXE
      into vSuffixe
      from GCO_CHARACTERIZATION
     where GCO_CHARACTERIZATION_ID = aCharId;

    if vSuffixe = '-YY' then
      vSuffixe  := '-' || to_char(sysdate, 'yy');
    end if;

    update    GCO_CHARACTERIZATION
          set CHA_LAST_USED_INCREMENT = PCS.PC_PREFIXE.IncrementNumber(CHA_LAST_USED_INCREMENT, nvl(CHA_INCREMENT_STE, 1) )
            , A_DATEMOD = sysdate
            , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
        where GCO_CHARACTERIZATION_ID = aCharId
    returning CHA_PREFIXE || lpad(CHA_LAST_USED_INCREMENT, 7, '0') || vSuffixe
         into aNewCharValue;
  end GoodPrefixeSuffixeAutoNum;
end GCO_CHAR_AUTONUM_FUNCTIONS;
