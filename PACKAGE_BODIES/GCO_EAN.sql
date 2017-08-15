--------------------------------------------------------
--  DDL for Package Body GCO_EAN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_EAN" 
is
  function GetGenCod(aFirmNumber in varchar2, aReference in varchar2)
    return varchar2
  is
    GenCod1 integer      default 0;
    Gencod2 integer      default 0;
    Gencod3 integer      default 0;
    value   varchar2(12);
    OK      integer      default 1;
    Temp    integer;
  begin
    -- Controle que les paramètres transmis soient bien numériques
    begin
      temp  := to_number(aFirmNumber);
      temp  := to_number(aReference);

      if    not(length(aFirmNumber) = 6)
         or not(length(aReference) = 6) then
        Raise_application_error(-20000, '');
      end if;
    exception
      when others then
        OK  := 0;
    end;

    -- Si les paramètres sont OK on passe dans la partie génération du code
    if OK = 1 then
      -- 1) Concaténer le n° d'affilié et le n° d'article
      value    := aFirmNumber || aReference;
      -- 2) Additionner les valeurs des positions paires
      GenCod1  :=
        to_number(substr(value, 2, 1) ) +
        to_number(substr(value, 4, 1) ) +
        to_number(substr(value, 6, 1) ) +
        to_number(substr(value, 8, 1) ) +
        to_number(substr(value, 10, 1) ) +
        to_number(substr(value, 12, 1) );
      -- 3) Multiplier le total précédent [Gencod1] par 3
      GenCod1  := GenCod1 * 3;
      -- 4) Additionner les valeurs des positions impaires au résultat précédent [Gencod1]
      GenCod1  :=
        GenCod1 +
        to_number(substr(value, 1, 1) ) +
        to_number(substr(value, 3, 1) ) +
        to_number(substr(value, 5, 1) ) +
        to_number(substr(value, 7, 1) ) +
        to_number(substr(value, 9, 1) ) +
        to_number(substr(value, 11, 1) );
      -- 5) Diviser le résultat précédent [Gencod1] par 10 (division entière), conserver le résultat [Gencod2]
      -- 6) Ajouter 1 au résultat précédent [Gencod2]
      -- 7) Multiplier le résultat précédent [Gencod2] par 10
      GenCod2  := (trunc(GenCod1 / 10) + 1) * 10;
      -- 8) Soustraire le premier résultat [Gencod1] du second [Gencod2], ce qui donne le code de contrôle [Gencod3]
      GenCod3  := mod(GenCod2 - GenCod1, 10);
      return value || ltrim(to_char(GenCod3) );
    else
      return null;
    end if;
  end;

  function EAN_Gen(aGenre number, aGoodID number)
    return varchar2
  is
    EAN_Code varchar2(40);
    f_type   varchar2(10);
    f_gen    varchar2(10);
    cid      integer;
    ignore   integer;
    SqlCmd   varchar2(2000);
  begin
    -- Recherche du type
    if aGenre = 0 then   -- 0 = Produit
      select C_EAN_TYPE
           , DIC_GOOD_EAN_GEN_ID
        into f_type
           , f_gen
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 1 then   -- 1 = Stock
      select C_EAN_TYPE_STOCK
           , DIC_GOOD_EAN_GEN_STOCK_ID
        into f_type
           , f_gen
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 2 then   -- 2 = Inventaire
      select C_EAN_TYPE_INV
           , DIC_GOOD_EAN_GEN_INV_ID
        into f_type
           , f_gen
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 3 then   -- 3 = Achat
      select C_EAN_TYPE_PURCHASE
           , DIC_GOOD_EAN_GEN_PUR_ID
        into f_type
           , f_gen
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 4 then   -- 4 = Vente
      select C_EAN_TYPE_SALE
           , DIC_GOOD_EAN_GEN_SALE_ID
        into f_type
           , f_gen
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 5 then   -- 5 = SAV
      select C_EAN_TYPE_ASA
           , DIC_GOOD_EAN_GEN_ASA_ID
        into f_type
           , f_gen
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 6 then   -- 6 = Sous-traitance
      select C_EAN_TYPE_SUBCONTRACT
           , DIC_GOOD_EAN_GEN_SCO_ID
        into f_type
           , f_gen
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 7 then   -- 7 = Fabrication
      select C_EAN_TYPE_FAL
           , DIC_GOOD_EAN_GEN_FAL_ID
        into f_type
           , f_gen
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    end if;

    if    (f_type = '999')
       or (f_type is null)
       or (f_gen is null) then   -- Inactif
      EAN_Code  := '';
    else
      begin
        if f_type = '900' then   -- Code Indiv
          SqlCmd  := 'SELECT GCO_USER_EAN.EAN_GEN_' || f_gen || '(' || to_char(aGenre) || ',' || to_char(aGoodID) || ') FROM DUAL';
        else   -- Code PCS
          SqlCmd  := 'SELECT GCO_EAN.EAN_GEN_' || f_gen || '(' || to_char(aGenre) || ',' || to_char(aGoodID) || ') FROM DUAL';
        end if;

        -- Ouverture du curseur
        cid     := DBMS_SQL.OPEN_CURSOR;
        DBMS_SQL.PARSE(cid, SqlCmd, DBMS_SQL.v7);
        DBMS_SQL.DEFINE_COLUMN(cid, 1, EAN_Code, 40);
        -- Exécution de la fonction
        ignore  := DBMS_SQL.execute(cid);

        -- Récupére la variable en retour de la fonction
        if DBMS_SQL.fetch_rows(cid) > 0 then
          DBMS_SQL.column_value(cid, 1, EAN_Code);
        end if;

        -- Ferme le curseur
        DBMS_SQL.CLOSE_CURSOR(cid);
      exception
        when others then
          EAN_Code  := '';
      end;
    end if;

    return EAN_Code;
  end;

  function EAN_Ctrl(aGenre number, aEANCode varchar2, aGoodID number)
    return integer
  is
    iResult integer;
    f_type  varchar2(10);
    f_ctrl  varchar2(10);
    cid     integer;
    ignore  integer;
    SqlCmd  varchar2(2000);
  begin
    -- Recherche du type
    if aGenre = 0 then   -- 0 = Produit
      select C_EAN_TYPE
           , DIC_GOOD_EAN_CTRL_ID
        into f_type
           , f_ctrl
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 1 then   -- 1 = Stock
      select C_EAN_TYPE_STOCK
           , DIC_GOOD_EAN_CTRL_STOCK_ID
        into f_type
           , f_ctrl
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 2 then   -- 2 = Inventaire
      select C_EAN_TYPE_INV
           , DIC_GOOD_EAN_CTRL_INV_ID
        into f_type
           , f_ctrl
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 3 then   -- 3 = Achat
      select C_EAN_TYPE_PURCHASE
           , DIC_GOOD_EAN_CTRL_PUR_ID
        into f_type
           , f_ctrl
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 4 then   -- 4 = Vente
      select C_EAN_TYPE_SALE
           , DIC_GOOD_EAN_CTRL_SALE_ID
        into f_type
           , f_ctrl
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 5 then   -- 5 = SAV
      select C_EAN_TYPE_ASA
           , DIC_GOOD_EAN_CTRL_ASA_ID
        into f_type
           , f_ctrl
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 6 then   -- 6 = Sous-traitance
      select C_EAN_TYPE_SUBCONTRACT
           , DIC_GOOD_EAN_CTRL_SCO_ID
        into f_type
           , f_ctrl
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    elsif aGenre = 7 then   -- 7 = Fabrication
      select C_EAN_TYPE_FAL
           , DIC_GOOD_EAN_CTRL_FAL_ID
        into f_type
           , f_ctrl
        from GCO_GOOD_CATEGORY CAT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID;
    end if;

    if    (f_type = '999')
       or (f_type is null)
       or (f_ctrl is null) then   -- Inactif
      iResult  := 1;
    else
      begin
        if f_type = '900' then   -- Code Indiv
          SqlCmd  := 'SELECT GCO_USER_EAN.EAN_CTRL_' || f_ctrl || '(' || to_char(aGenre) || ',''' || aEANCode || ''') FROM DUAL';
        else   -- Code PCS
          SqlCmd  := 'SELECT GCO_EAN.EAN_CTRL_' || f_ctrl || '(' || to_char(aGenre) || ',''' || aEANCode || ''') FROM DUAL';
        end if;

        -- Ouverture du curseur
        cid     := DBMS_SQL.OPEN_CURSOR;
        DBMS_SQL.PARSE(cid, SqlCmd, DBMS_SQL.v7);
        DBMS_SQL.DEFINE_COLUMN(cid, 1, iResult);
        -- Exécution de la fonction
        ignore  := DBMS_SQL.execute(cid);

        -- Récupére la variable en retour de la fonction
        if DBMS_SQL.FETCH_ROWS(cid) > 0 then
          DBMS_SQL.column_value(cid, 1, iResult);
        end if;

        -- Ferme le curseur
        DBMS_SQL.CLOSE_CURSOR(cid);
      exception
        when others then
          iResult  := 1;
      end;
    end if;

    -- si le code EAN généré est le même que celui du bien en cours, pas d'erreur
    if iResult = aGoodId then
      iResult  := 1;
    end if;

    return iResult;
  end;

  procedure EAN_tgen(aGenre number, aCategoryID number, aGen_Code varchar2, aCtrl_Code varchar2)
  is
    blnCtrl      boolean;
    SqlCmd       varchar2(2000);
    SqlCmdUpdate varchar2(2000);
    cid          integer;
    cidUpdate    integer;
    ignore       integer;
    GoodID       number;
    ComplData_ID number;
    EAN_Code     varchar2(40);
  begin
    -- Commande SQL pour la génération/contrôle des codes EAN
    if aGenre = 0 then   -- PRODUIT
      SqlCmd  :=
        'select GCO_GOOD_ID, GCO_GOOD_ID, GOO_MAJOR_REFERENCE ' ||
        '  from GCO_GOOD ' ||
        ' where GCO_GOOD_CATEGORY_ID = ' ||
        to_char(aCategoryID) ||
        '   and GOO_EAN_CODE_AUTO_GEN = 1 ' ||
        ' order by GOO_MAJOR_REFERENCE' ||
        ' for update nowait';
    elsif aGenre = 1 then   -- STOCK
      SqlCmd  :=
        'select DAT.GCO_GOOD_ID, DAT.GCO_COMPL_DATA_STOCK_ID, GOO.GOO_MAJOR_REFERENCE ' ||
        'from GCO_COMPL_DATA_STOCK DAT, GCO_GOOD GOO ' ||
        'where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID and  GOO.GCO_GOOD_CATEGORY_ID = ' ||
        to_char(aCategoryID) ||
        ' order by GOO.GOO_MAJOR_REFERENCE' ||
        ' for update nowait';
    elsif aGenre = 2 then   -- INVENTAIRE
      SqlCmd  :=
        'select DAT.GCO_GOOD_ID, DAT.GCO_COMPL_DATA_INVENTORY_ID, GOO.GOO_MAJOR_REFERENCE ' ||
        'from GCO_COMPL_DATA_INVENTORY DAT, GCO_GOOD GOO ' ||
        'where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID and  GOO.GCO_GOOD_CATEGORY_ID = ' ||
        to_char(aCategoryID) ||
        ' order by GOO.GOO_MAJOR_REFERENCE' ||
        ' for update nowait';
    elsif aGenre = 3 then   -- ACHAT
      SqlCmd  :=
        'select DAT.GCO_GOOD_ID, DAT.GCO_COMPL_DATA_PURCHASE_ID, GOO.GOO_MAJOR_REFERENCE ' ||
        'from GCO_COMPL_DATA_PURCHASE DAT, GCO_GOOD GOO ' ||
        'where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID and  GOO.GCO_GOOD_CATEGORY_ID = ' ||
        to_char(aCategoryID) ||
        ' order by GOO.GOO_MAJOR_REFERENCE' ||
        ' for update nowait';
    elsif aGenre = 4 then   -- VENTE
      SqlCmd  :=
        'select DAT.GCO_GOOD_ID, DAT.GCO_COMPL_DATA_SALE_ID, GOO.GOO_MAJOR_REFERENCE ' ||
        'from GCO_COMPL_DATA_SALE DAT, GCO_GOOD GOO ' ||
        'where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID and  GOO.GCO_GOOD_CATEGORY_ID = ' ||
        to_char(aCategoryID) ||
        ' order by GOO.GOO_MAJOR_REFERENCE' ||
        ' for update nowait';
    elsif aGenre = 5 then   -- SAV
      SqlCmd  :=
        'select DAT.GCO_GOOD_ID, DAT.GCO_COMPL_DATA_ASS_ID, GOO.GOO_MAJOR_REFERENCE ' ||
        'from GCO_COMPL_DATA_ASS DAT, GCO_GOOD GOO ' ||
        'where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID and  GOO.GCO_GOOD_CATEGORY_ID = ' ||
        to_char(aCategoryID) ||
        ' order by GOO.GOO_MAJOR_REFERENCE' ||
        ' for update nowait';
    elsif aGenre = 6 then   -- SOUS-TRAITANCE
      SqlCmd  :=
        'select DAT.GCO_GOOD_ID, DAT.GCO_COMPL_DATA_SUBCONTRACT_ID, GOO.GOO_MAJOR_REFERENCE ' ||
        'from GCO_COMPL_DATA_SUBCONTRACT DAT, GCO_GOOD GOO ' ||
        'where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID and  GOO.GCO_GOOD_CATEGORY_ID = ' ||
        to_char(aCategoryID) ||
        ' order by GOO.GOO_MAJOR_REFERENCE' ||
        ' for update nowait';
    elsif aGenre = 7 then   -- FABRICATION
      SqlCmd  :=
        'select DAT.GCO_GOOD_ID, DAT.GCO_COMPL_DATA_MANUFACTURE_ID, GOO.GOO_MAJOR_REFERENCE ' ||
        'from GCO_COMPL_DATA_MANUFACTURE DAT, GCO_GOOD GOO ' ||
        'where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID and  GOO.GCO_GOOD_CATEGORY_ID = ' ||
        to_char(aCategoryID) ||
        ' order by GOO.GOO_MAJOR_REFERENCE' ||
        ' for update nowait';
    end if;

    cid     := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(cid, SqlCmd, DBMS_SQL.v7);
    DBMS_SQL.DEFINE_COLUMN(cid, 1, GoodID);
    DBMS_SQL.DEFINE_COLUMN(cid, 2, ComplData_ID);
    -- Exécution de la fonction
    ignore  := DBMS_SQL.execute(cid);

    -- Boucle pour toutes les lignes retournées par la commande SQL
    loop
      if DBMS_SQL.FETCH_ROWS(cid) > 0 then
        -- Récupére l'ID du bien
        DBMS_SQL.column_value(cid, 1, GoodID);
        DBMS_SQL.column_value(cid, 2, ComplData_ID);

        -- Pas de code à regénérer
        if aGen_Code = '0' then
          -- Recherche du code EAN au niveau de la base
          if aGenre = 0 then   -- PRODUIT
            select GOO_EAN_CODE
              into EAN_Code
              from GCO_GOOD
             where GCO_GOOD_ID = GoodID;
          elsif aGenre = 1 then   -- STOCK
            select CDA_COMPLEMENTARY_EAN_CODE
              into EAN_Code
              from GCO_COMPL_DATA_STOCK
             where GCO_COMPL_DATA_STOCK_ID = ComplData_ID;
          elsif aGenre = 2 then   -- INVENTAIRE
            select CDA_COMPLEMENTARY_EAN_CODE
              into EAN_Code
              from GCO_COMPL_DATA_INVENTORY
             where GCO_COMPL_DATA_INVENTORY_ID = ComplData_ID;
          elsif aGenre = 3 then   -- ACHAT
            select CDA_COMPLEMENTARY_EAN_CODE
              into EAN_Code
              from GCO_COMPL_DATA_PURCHASE
             where GCO_COMPL_DATA_PURCHASE_ID = ComplData_ID;
          elsif aGenre = 4 then   -- VENTE
            select CDA_COMPLEMENTARY_EAN_CODE
              into EAN_Code
              from GCO_COMPL_DATA_SALE
             where GCO_COMPL_DATA_SALE_ID = ComplData_ID;
          elsif aGenre = 5 then   -- SAV
            select CDA_COMPLEMENTARY_EAN_CODE
              into EAN_Code
              from GCO_COMPL_DATA_ASS
             where GCO_COMPL_DATA_ASS_ID = ComplData_ID;
          elsif aGenre = 6 then   -- SOUS-TRAITANCE
            select CDA_COMPLEMENTARY_EAN_CODE
              into EAN_Code
              from GCO_COMPL_DATA_SUBCONTRACT
             where GCO_COMPL_DATA_SUBCONTRACT_ID = ComplData_ID;
          elsif aGenre = 7 then   -- FABRICATION
            select CDA_COMPLEMENTARY_EAN_CODE
              into EAN_Code
              from GCO_COMPL_DATA_MANUFACTURE
             where GCO_COMPL_DATA_MANUFACTURE_ID = ComplData_ID;
          end if;
        else   -- Regénérer code EAN
          EAN_Code  := EAN_Gen(to_char(aGenre), to_char(GoodID) );
        end if;

        -- Contrôle du code EAN si existant
        if EAN_Code is not null then
          begin
            blnCtrl  := EAN_Ctrl(to_char(aGenre), '' || EAN_Code || '', to_char(GoodID) ) = 1;
          -- Si code EAN est faux
          exception
            when others then
              blnCtrl  := false;
          end;

          if not blnCtrl then
            EAN_Code  := '';
          end if;
        end if;

        -- Mise à jour du code EAN dans la Base
        if aGenre = 0 then   -- PRODUIT
          update GCO_GOOD
             set GOO_EAN_CODE = EAN_Code
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_GOOD_ID = GoodID;
        elsif aGenre = 1 then   -- STOCK
          update GCO_COMPL_DATA_STOCK
             set CDA_COMPLEMENTARY_EAN_CODE = EAN_Code
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_STOCK_ID = ComplData_ID;
        elsif aGenre = 2 then   -- INVENTAIRE
          update GCO_COMPL_DATA_INVENTORY
             set CDA_COMPLEMENTARY_EAN_CODE = EAN_Code
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_INVENTORY_ID = ComplData_ID;
        elsif aGenre = 3 then   -- ACHAT
          update GCO_COMPL_DATA_PURCHASE
             set CDA_COMPLEMENTARY_EAN_CODE = EAN_Code
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_PURCHASE_ID = ComplData_ID;
        elsif aGenre = 4 then   -- VENTE
          update GCO_COMPL_DATA_SALE
             set CDA_COMPLEMENTARY_EAN_CODE = EAN_Code
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_SALE_ID = ComplData_ID;
        elsif aGenre = 5 then   -- SAV
          update GCO_COMPL_DATA_ASS
             set CDA_COMPLEMENTARY_EAN_CODE = EAN_Code
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_ASS_ID = ComplData_ID;
        elsif aGenre = 6 then   -- SOUS-TRAITANCE
          update GCO_COMPL_DATA_SUBCONTRACT
             set CDA_COMPLEMENTARY_EAN_CODE = EAN_Code
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_SUBCONTRACT_ID = ComplData_ID;
        elsif aGenre = 7 then   -- FABRICATION
          update GCO_COMPL_DATA_MANUFACTURE
             set CDA_COMPLEMENTARY_EAN_CODE = EAN_Code
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_COMPL_DATA_MANUFACTURE_ID = ComplData_ID;
        end if;
      else
        exit;
      end if;
    end loop;

    -- Ferme le curseur
    DBMS_SQL.CLOSE_CURSOR(cid);
  end;

  function EAN_Intg(C_GENRE in number, C_EAN in varchar2)
    return integer
  --Controle de l'integrité du code EAN
  is
    retour integer default 0;
  begin
    if C_EAN is null then
      retour  := 1;
    else
      if C_GENRE = 0 then   --Produit
        begin
          select gco.GCO_GOOD_ID
            into retour
            from gco_good gco
           where gco.GOO_EAN_CODE = C_EAN;
        exception
          when no_data_found then
            retour  := 1;
        end;
      else
        retour  := 1;
      end if;
    end if;

    return retour;
  end;

  function EAN_13_ctrl(C_EAN in varchar2)
    return integer
  is
    factor integer default 0;
    i      integer default 0;
    somme  integer default 0;
  begin
    --Calcul du numéro de contrôle
    factor  := 3;
    somme   := 0;

    for i in reverse 1 .. 12 loop
      somme   := somme + substr(C_EAN, i, 1) * factor;
      factor  := 4 - factor;
    end loop;

    somme   := abs(mod(1000 - somme, 10) );
    --retour du numéro de contrôle
    return somme;
  end;

  function EAN_GEN_001(C_GENRE in number, GOOD_ID in number)
    return varchar2
  is
    somme    integer      default 0;
    compteur number;
    C_EAN    varchar2(13);
  begin
      -- Génération du code EAN 13 interne 20 + seq
    -- Recherche du prochain n° de séquence
    select GCO_EAN_13_INT_SEQ.nextval
      into compteur
      from dual;

    --Construction du code EAN
    C_EAN  := '20' || substr('0000000000' || compteur, -10);
    --Calcul du numéro de controle
    somme  := EAN_13_ctrl(C_EAN);
    C_EAN  := C_EAN || somme;
    --Retour du Code EAN
    return C_EAN;
  end;

  function EAN_GEN_002(C_GENRE in number, GOOD_ID in number)
    return varchar2
  is
    somme    integer      default 0;
    compteur number;
    C_EAN    varchar2(13);
    Code_EAN varchar2(8);
  begin
      -- Génération du code EAN 13 config + seq
    -- Recherche du prochain n° de séquence
    select GCO_EAN_13_INT_SEQ.nextval
      into compteur
      from dual;

    --Construction du code EAN
    code_EAN  := GetEAN_LIC;
    C_EAN     := code_EAN || substr('0000000000' || compteur, length(code_EAN) - 12);
    --Calcul du numéro de controle
    somme     := EAN_13_ctrl(C_EAN);
    C_EAN     := C_EAN || somme;
    --Retour du Code EAN
    return C_EAN;
  end;

  function EAN_GEN_003(C_GENRE in number, GOOD_ID in number)
    return varchar2
  is
    somme      integer      default 0;
    compteur   number;
    C_EAN      varchar2(13);
    Code_EAN   varchar2(8);
    aReference varchar2(10);
  begin
    -- Génération du code EAN 13 20 + goo_major_reference

    -- Définition de goo_major_reference
    select gco.goo_major_reference
      into aReference
      from gco_good gco
     where gco.gco_good_id = GOOD_ID;

    --Construction du code EAN
    code_EAN  := '20';
    C_EAN     := code_EAN || substr('0000000000' || aReference, length(code_EAN) - 12);
    --Calcul du numéro de controle
    somme     := EAN_13_ctrl(C_EAN);
    C_EAN     := C_EAN || somme;
    --Retour du Code EAN
    return C_EAN;
  end;

  function EAN_GEN_004(C_GENRE in number, GOOD_ID in number)
    return varchar2
  is
    somme      integer      default 0;
    compteur   number;
    C_EAN      varchar2(13);
    Code_EAN   varchar2(8);
    aReference varchar2(10);
  begin
    -- Génération du code EAN 13 config + goo_major_reference

    -- Définition de goo_major_reference
    select gco.goo_major_reference
      into aReference
      from gco_good gco
     where gco.gco_good_id = GOOD_ID;

    --Construction du code EAN
    code_EAN  := GetEAN_LIC;
    C_EAN     := code_EAN || substr('0000000000' || aReference, length(code_EAN) - 12);
    --Calcul du numéro de controle
    somme     := EAN_13_ctrl(C_EAN);
    C_EAN     := C_EAN || somme;
    --Retour du Code EAN
    return C_EAN;
  end;

  function EAN_CTRL_001(C_GENRE in number, C_EAN in varchar2)
    return integer
  is
    test   integer      default 0;
    config varchar2(20);
    ctrl   integer      default 0;
  begin
    if C_EAN is null then
      test  := 1;
    else
      --Test du numéro de contrôle et que le code EAN commence par '20'
      if     length(C_EAN) = 13
         and substr(C_EAN, 1, 2) = '20' then
        for i in 1 .. 13 loop
          if    ascii(substr(C_EAN, i, 1) ) < 48
             or ascii(substr(C_EAN, i, 1) ) > 57 then
            ctrl  := 1;
          end if;
        end loop;

        if     ctrl = 0
           and substr(C_EAN, -1) = EAN_13_ctrl(C_EAN) then
          test  := 1;
        end if;
      end if;

      if test = 1 then
        if PCS.PC_CONFIG.GetConfig('GCO_EAN_PRODUCT_INTEGRITY') = 'True' then
          test  := EAN_Intg(C_GENRE, C_EAN);
        end if;
      end if;
    end if;

    return test;
  end;

  function EAN_CTRL_002(C_GENRE in number, C_EAN in varchar2)
    return integer
  is
    test     integer      default 0;
    config   varchar2(20);
    ctrl     integer      default 0;
    code_EAN varchar2(8);
  begin
    if C_EAN is null then
      test  := 1;
    else
      --Test du numéro de contrôle et que le code EAN commence par le code LIC
      code_EAN  := GetEAN_LIC;

      if substr(C_EAN, 1, length(code_EAN) ) = Code_EAN then
        if length(C_EAN) = 13 then
          for i in 1 .. 13 loop
            if    ascii(substr(C_EAN, i, 1) ) < 48
               or ascii(substr(C_EAN, i, 1) ) > 57 then
              ctrl  := 1;
            end if;
          end loop;

          if     ctrl = 0
             and substr(C_EAN, -1) = EAN_13_ctrl(C_EAN) then
            test  := 1;
          end if;
        end if;
      end if;

      if test = 1 then
        if PCS.PC_CONFIG.GetConfig('GCO_EAN_PRODUCT_INTEGRITY') = 'True' then
          test  := EAN_Intg(C_GENRE, C_EAN);
        end if;
      end if;
    end if;

    return test;
  end;

  function EAN_CTRL_003(C_GENRE in number, C_EAN in varchar2)
    return integer
  is
    test     integer      default 0;
    config   varchar2(20);
    ctrl     integer      default 0;
    code_EAN varchar2(8);
  begin
    if C_EAN is null then
      test  := 1;
    else
      --Test du numéro de contrôle et que le code EAN commence 20
      if substr(C_EAN, 2) = '20' then
        if length(C_EAN) = 13 then
          for i in 1 .. 13 loop
            if    ascii(substr(C_EAN, i, 1) ) < 48
               or ascii(substr(C_EAN, i, 1) ) > 57 then
              ctrl  := 1;
            end if;
          end loop;

          if     ctrl = 0
             and substr(C_EAN, -1) = EAN_13_ctrl(C_EAN) then
            test  := 1;
          end if;
        end if;
      end if;

      if test = 1 then
        if PCS.PC_CONFIG.GetConfig('GCO_EAN_PRODUCT_INTEGRITY') = 'True' then
          test  := EAN_Intg(C_GENRE, C_EAN);
        end if;
      end if;
    end if;

    return test;
  end;

  function EAN_CTRL_004(C_GENRE in number, C_EAN in varchar2)
    return integer
  is
    test     integer      default 0;
    config   varchar2(20);
    ctrl     integer      default 0;
    code_EAN varchar2(8);
  begin
    if C_EAN is null then
      test  := 1;
    else
      --Test du numéro de contrôle et que le code EAN commence par le code LIC
      code_EAN  := GetEAN_LIC;

      if substr(C_EAN, 1, length(code_EAN) ) = Code_EAN then
        if length(C_EAN) = 13 then
          for i in 1 .. 13 loop
            if    ascii(substr(C_EAN, i, 1) ) < 48
               or ascii(substr(C_EAN, i, 1) ) > 57 then
              ctrl  := 1;
            end if;
          end loop;

          if     ctrl = 0
             and substr(C_EAN, -1) = EAN_13_ctrl(C_EAN) then
            test  := 1;
          end if;
        end if;
      end if;

      if test = 1 then
        if PCS.PC_CONFIG.GetConfig('GCO_EAN_PRODUCT_INTEGRITY') = 'True' then
          test  := EAN_Intg(C_GENRE, C_EAN);
        end if;
      end if;
    end if;

    return test;
  end;

/*---------------------------------------------------------------------*/
/* Contrôle du LIC EAN et renvoie du numéro                            */
/*---------------------------------------------------------------------*/
  function GetEAN_LIC
    return PCS.PC_COMP.COM_EAN_LIC%type
  is
    vLIC PCS.PC_COMP.COM_EAN_LIC%type;
  begin
    -- N° d'adhérent EAN de la société active
    begin
      select COM.COM_EAN_LIC
        into vLIC
        from PCS.PC_COMP COM
       where COM.PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;
    exception
      when no_data_found then
        vLIC  := null;
    end;

    return vLIC;
  end GetEAN_LIC;
end GCO_EAN;
