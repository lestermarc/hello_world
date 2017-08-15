--------------------------------------------------------
--  DDL for Package Body GCO_GOOD_NUMBERING_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_GOOD_NUMBERING_FUNCTIONS" 
is
  /**
  * Description
  *   Méthode de numérotation du PCN selon méthode de génération géré en transaction autonome
  */
  procedure GetNumberAutoTrans(aID in GCO_GOOD.GCO_GOOD_ID%type, aOriginTable in varchar2, aNumber out varchar2)
  is
    pragma autonomous_transaction;
  begin
    GetNumber(aID, aOriginTable, aNumber);
    commit;
  end GetNumberAutoTrans;

  /**
  * Description
  *   Fonction de numérotation du PCN selon méthode de génération
  */
  procedure GetNumber(aID in GCO_GOOD.GCO_GOOD_ID%type, aOriginTable in varchar2, aNumber out varchar2)
  is
    vNumberingID GCO_GOOD_NUMBERING.GCO_GOOD_NUMBERING_ID%type;
  begin
    -- Recherche de la méthode de génération
    begin
      if aOriginTable = 'GCO_GOOD_CATEGORY' then
        select GCN.GCO_GOOD_NUMBERING_ID
          into vNumberingID
          from GCO_GOOD_NUMBERING GCN
             , GCO_GOOD_CATEGORY CAT
             , GCO_GOOD GOO
         where GOO.GCO_GOOD_ID = aID
           and CAT.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID
           and CAT.GCO_GOOD_NUMBERING_ID = GCN.GCO_GOOD_NUMBERING_ID
           and CAT.GCO_GOOD_NUMBERING_ID is not null
           and CAT.CAT_AUTOM_NUMBERING = 1;
      elsif aOriginTable = 'GCO_GOOD_CATEGORY_BARCODE' then
        select GCN.GCO_GOOD_NUMBERING_ID
          into vNumberingID
          from GCO_GOOD_NUMBERING GCN
             , GCO_GOOD_CATEGORY CAT
             , GCO_GOOD GOO
         where GOO.GCO_GOOD_ID = aID
           and CAT.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID
           and CAT.GCO_GCO_GOOD_NUMBERING_ID = GCN.GCO_GOOD_NUMBERING_ID;
      elsif aOriginTable = 'DOC_RECORD_CATEGORY' then
        select GCN.GCO_GOOD_NUMBERING_ID
          into vNumberingID
          from GCO_GOOD_NUMBERING GCN
             , DOC_RECORD_CATEGORY RCY
         where RCY.DOC_RECORD_CATEGORY_ID = aID
           and RCY.GCO_GOOD_NUMBERING_ID = GCN.GCO_GOOD_NUMBERING_ID
           and RCY.GCO_GOOD_NUMBERING_ID is not null;
      end if;
    exception
      when no_data_found then
        vNumberingID  := 0;   -- Pas de numérotation automatique
    end;

    if vNumberingID > 0 then
      aNumber  := AutoNumbering(vNumberingID, aID);
    else
      aNumber  := null;
    end if;
  end GetNumber;

  /**
  * Description
  *    Fonction de numérotation automatique selon l'ID de la numérotation automatique
  */
  function AutoNumbering(aNumberingID GCO_GOOD_NUMBERING.GCO_GOOD_NUMBERING_ID%type, aID in GCO_GOOD.GCO_GOOD_ID%type)
    return varchar2
  is
    tplGoodNumbering GCO_GOOD_NUMBERING%rowtype;
    vFillerChar      varchar2(1);
    vReturnCode      number;
    aNumber          varchar2(100);
    aNewNumber       varchar2(100);
  begin
    select     *
          into tplGoodNumbering
          from GCO_GOOD_NUMBERING
         where GCO_GOOD_NUMBERING_ID = aNumberingID
    for update;

    vReturnCode  := 0;
    aNewNumber   := to_char(tplGoodNumbering.GCN_LAST_NUMBER + tplGoodNumbering.GCN_NUMBERING_STEP);
    aNumber      := aNewNumber;
    vFillerChar  := substr(tplGoodNumbering.GCN_FILLER_CHAR, 1, 1);

    -- Numérotation automatique
    if tplGoodNumbering.C_NUMBERING_TYPE <> '2' then
      -- Formule externe client
      if (tplGoodNumbering.GCN_CUSTOM_CALC_FORMULA = 1) then
        execute immediate 'BEGIN ' || 'GCO_USR_NUMBER.FRML_' || tplGoodNumbering.C_CALC_FORMULA || '(:1,:2,:3,:4); END;'
                    using in aID, in out aNumber, in tplGoodNumbering.GCN_NUMBER, in out vReturnCode;
      else
        -- pas de formule
        if (tplGoodNumbering.C_CALC_FORMULA = '0') then
          vReturnCode  := 1;
        -- formule externe standard
        else
          execute immediate 'BEGIN ' || 'GCO_NUMBER.FRML_' || tplGoodNumbering.C_CALC_FORMULA || '(:1,:2,:3,:4); END;'
                      using in aID, in out aNumber, in tplGoodNumbering.GCN_NUMBER, in out vReturnCode;
        end if;
      end if;
    -- Numérotation manuel, défini par le client
    else
      aNumber  := null;
    end if;

    if vReturnCode > 0 then
      if tplGoodNumbering.C_NUMBERING_TYPE = '1' then
        -- Mise à jour du dernier numéro
        update GCO_GOOD_NUMBERING
           set GCN_LAST_NUMBER = aNewNumber
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where GCO_GOOD_NUMBERING_ID = tplGoodNumbering.GCO_GOOD_NUMBERING_ID;

        -- Formatage du numéro
        if tplGoodNumbering.GCN_FORMAT is null then
          if     vFillerChar is not null
             and vFillerChar <> ' ' then
            aNumber  := lpad(aNumber, tplGoodNumbering.GCN_NUMBER, vFillerChar);
          end if;
        else
          aNumber  := PCS.PC_TEXT.FormatMaskText(tplGoodNumbering.GCN_FORMAT || ';0;0', aNumber);
          aNumber  := replace(aNumber, ' ', vFillerChar);
        end if;

        aNumber  := tplGoodNumbering.GCN_PREFIX || aNumber || tplGoodNumbering.GCN_SUFIX;
      end if;
    end if;

    return aNumber;
  end AutoNumbering;

  /**
  * Description
  *   Mise à jour du nouveau numero en transaction autonome
  */
  procedure UpdateNumberAutoTrans(iNumberingID in GCO_GOOD_NUMBERING.GCO_GOOD_NUMBERING_ID%type, iNewNumber in varchar2)
  is
    pragma autonomous_transaction;
  begin
    -- Mise à jour du dernier numéro
    update GCO_GOOD_NUMBERING
       set GCN_LAST_NUMBER = iNewNumber
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_NUMBERING_ID = iNumberingID;

    commit;
  end UpdateNumberAutoTrans;
end GCO_GOOD_NUMBERING_FUNCTIONS;
