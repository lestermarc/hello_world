--------------------------------------------------------
--  DDL for Package Body DOC_ACCUMULATOR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_ACCUMULATOR" 
is
  /**
  * Description
  *   Procedure de mise à jour des totalisateur de document
  */
  procedure DOC_TOTAL_DOCUMENT(
    DOCUMENT_ID          number
  , DOC_DATE             date
  , GAUGE_TYPE_DOC_ID    varchar2
  , DOCUMENT_STATUS      varchar2
  , THIRD_ID             number
  , TOTAL_DOC_AMOUNT     number
  , TOTAL_DOC_VAT_AMOUNT number
  , sign                 number
  , global               number
  )
  is
    month_number            number(2);
    year_number             number(4);
    year_month_id           PCS.PC_YEAR_MONTH.PC_YEAR_MONTH_ID%type;
    document_accumulator_id DOC_DOCU_ACCUMULATOR.DOC_DOCU_ACCUMULATOR_ID%type;
  begin
    -- Initialisation de variables avec le mois et l'année du document
    year_month_id  := PCS.PC_FUNCTIONS.GetYearMonth_ID(doc_date);

    -- Recherche d'un totalisateur
    select max(DOC_DOCU_ACCUMULATOR_ID)
      into document_accumulator_id
      from DOC_DOCU_ACCUMULATOR
     where PC_YEAR_MONTH_ID = year_month_id
       and DIC_GAUGE_TYPE_DOC_ID = gauge_type_doc_id
       and (   PAC_THIRD_ID = third_id
            or (    PAC_THIRD_ID is null
                and third_id is null) )
       and C_DOCUMENT_STATUS = document_status;

    -- Si on a trouvé, on effectue une mise à jour
    if document_accumulator_id is not null then
      -- Modification de la position de totalisation existante
      if global = 0 then
        update DOC_DOCU_ACCUMULATOR
           set DAC_NUMBER_MONTH = DAC_NUMBER_MONTH + sign
             , DAC_VALUE_MONTH = nvl(DAC_VALUE_MONTH, 0) +(sign *(total_doc_amount - total_doc_vat_amount) )
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_DOCU_ACCUMULATOR_ID = document_accumulator_id;
      else
        update DOC_DOCU_ACCUMULATOR
           set DAC_NUMBER_MONTH = DAC_NUMBER_MONTH + sign
             , DAC_VALUE_MONTH = nvl(DAC_VALUE_MONTH, 0) +(sign *(total_doc_amount - total_doc_vat_amount) )
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_DOCU_ACCUMULATOR_ID = document_accumulator_id;
      end if;

      -- Effacement des tuples avec des donn‚es de mise … jour vides
      -- Effectue cet effacement uniquement lors d'une mise à jour
      -- non globale
      if global = 0 then
        -- Effacement du totalisateur courant à zéro
        delete from DOC_DOCU_ACCUMULATOR
              where DOC_DOCU_ACCUMULATOR_ID = document_accumulator_id
                and DAC_NUMBER_MONTH = 0
                and DAC_VALUE_MONTH = 0;
      end if;
    else
      -- Si on a pas trouvé, on crée un totalisateur
      insert into DOC_DOCU_ACCUMULATOR
                  (DOC_DOCU_ACCUMULATOR_ID
                 , DIC_GAUGE_TYPE_DOC_ID
                 , PAC_THIRD_ID
                 , C_DOCUMENT_STATUS
                 , PC_YEAR_MONTH_ID
                 , DAC_NUMBER_MONTH
                 , DAC_VALUE_MONTH
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , gauge_type_doc_id
                 , third_id
                 , document_status
                 , year_month_id
                 , sign
                 , sign *(total_doc_amount - total_doc_vat_amount)
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end DOC_TOTAL_DOCUMENT;

  /**
  * Description
  *   Procèdure de mise à jour des totalisateurs de positions de documents
  */
  procedure DOC_TOTAL_POSITION(
    GOOD_ID                  number
  , THIRD_ID                 number
  , aDIC_GAUGE_TYPE_DOC_ID   varchar2
  , CHARACTERIZATION_ID1     number
  , CHARACTERIZATION_ID2     number
  , CHARACTERIZATION_ID3     number
  , CHARACTERIZATION_ID4     number
  , CHARACTERIZATION_ID5     number
  , CHARACTERIZATION_VALUE_1 varchar2
  , CHARACTERIZATION_VALUE_2 varchar2
  , CHARACTERIZATION_VALUE_3 varchar2
  , CHARACTERIZATION_VALUE_4 varchar2
  , CHARACTERIZATION_VALUE_5 varchar2
  , aDELAY                   number
  , FINAL_DELAY              date
  , DATE_DOCUMENT            date
  , FINAL_QUANTITY           number
  , BALANCE_QUANTITY         number
  , NET_VALUE_EXCL           number
  , DOC_POS_STATUS           varchar2
  , BALANCE_STATUS           number
  , GAUGE_TYPE               varchar2
  , sign                     number
  , global                   number
  )
  is
    position_date         date;   -- date du delai de la position
    week_id               PCS.PC_YEAR_WEEK.PC_YEAR_WEEK_ID%type;   -- id de la semaine à mettre à jour
    accumulator_id        DOC_POSI_ACCUMULATOR.DOC_POSI_ACCUMULATOR_ID%type;   -- id du totalisateur de position
    charac_id1            GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;   -- identifieurs des caractérisations
    charac_id2            GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    charac_id3            GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    charac_id4            GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    charac_id5            GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    charac_val1           DOC_POSI_ACCUMULATOR.PAC_CHARACTERIZATION_VALUE_1%type;   -- valueur des caractérisations
    charac_val2           DOC_POSI_ACCUMULATOR.PAC_CHARACTERIZATION_VALUE_2%type;
    charac_val3           DOC_POSI_ACCUMULATOR.PAC_CHARACTERIZATION_VALUE_3%type;
    charac_val4           DOC_POSI_ACCUMULATOR.PAC_CHARACTERIZATION_VALUE_4%type;
    charac_val5           DOC_POSI_ACCUMULATOR.PAC_CHARACTERIZATION_VALUE_5%type;
    week_quantity         DOC_POSI_ACCUMULATOR.PAC_QUANTITY_WEEK%type;   -- qté de mise à jour
    week_balance          DOC_POSI_ACCUMULATOR.PAC_BALANCE_WEEK%type;   -- quantité de solde à mettre à jour
    week_value            DOC_POSI_ACCUMULATOR.PAC_VALUE_WEEK%type;   -- valeur unitaire
    charact_type          GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;

    -- Curseur de détail des positions du document
    cursor DETAIL_POSITION_CURSOR(doc_id number)
    is
      select POS.GCO_GOOD_ID
           , DOC.PAC_THIRD_ID
           , DOC.DIC_GAUGE_TYPE_DOC_ID
           , DET.GCO_CHARACTERIZATION_ID
           , DET.GCO_GCO_CHARACTERIZATION_ID
           , DET.GCO2_GCO_CHARACTERIZATION_ID
           , DET.GCO3_GCO_CHARACTERIZATION_ID
           , DET.GCO4_GCO_CHARACTERIZATION_ID
           , DET.PDE_CHARACTERIZATION_VALUE_1
           , DET.PDE_CHARACTERIZATION_VALUE_2
           , DET.PDE_CHARACTERIZATION_VALUE_3
           , DET.PDE_CHARACTERIZATION_VALUE_4
           , DET.PDE_CHARACTERIZATION_VALUE_5
           , GPO.GAP_DELAY
           , nvl(DET.PDE_FINAL_DELAY, DOC.DMT_DATE_DOCUMENT) PDE_FINAL_DELAY
           , DOC.DMT_DATE_DOCUMENT
           , DET.PDE_FINAL_QUANTITY
           , DET.PDE_BALANCE_QUANTITY
           , POS.POS_NET_VALUE_EXCL_B
           , POS.C_DOC_POS_STATUS
           , GST.GAS_BALANCE_STATUS
           , GAU.C_GAUGE_TYPE
        from DOC_DOCUMENT DOC
           , DOC_POSITION POS
           , DOC_POSITION_DETAIL DET
           , DOC_GAUGE_POSITION GPO
           , DOC_GAUGE_STRUCTURED GST
           , DOC_GAUGE GAU
       where DOC.DOC_DOCUMENT_ID = doc_id
         and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
         and GPO.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
         and DET.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and GST.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GST.DOC_GAUGE_ID
         and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '21', '91', '101');

    detail_position_tuple DETAIL_POSITION_CURSOR%rowtype;
  begin
    -- Recherche de la bonne date de delai en fonction du champ GAP_DELAI de DOC_GAUGE_POSITION
    if aDELAY = 0 then
      position_date  := nvl(DATE_DOCUMENT, FINAL_DELAY);
    else
      position_date  := nvl(FINAL_DELAY, DATE_DOCUMENT);
    end if;

    -- Recherche de la semaine à mettre à jour
    week_id        := PCS.PC_FUNCTIONS.GetYearWeek_ID(position_date);
    -- Quantité à mettre à jour pour la semaine est la quantité
    week_quantity  := FINAL_QUANTITY;

    -- Si le type de position est "à solder", on met à jour la quantité solde de position
    if BALANCE_STATUS = 1 then
      week_balance  := BALANCE_QUANTITY;
    else
      week_balance  := 0;
    end if;

    -- Valeur à mettre à jour pour la semaine
    week_value     := NET_VALUE_EXCL;

    -- Recherche du prix de base et du cours
    --rate_of_exchange := RATE_OF_EXCHANGE;
    --base_price := BASE_PRICE;

    --------------------------------------------------------------------
-- Vérifie si les types de caractériations sont "caractéristique" --
--------------------------------------------------------------------
    if CHARACTERIZATION_ID1 is not null then
      select C_CHARACT_TYPE
        into charact_type
        from GCO_CHARACTERIZATION
       where GCO_CHARACTERIZATION_ID = CHARACTERIZATION_ID1;

      if charact_type <> '2' then
        charac_id1   := null;
        charac_val1  := null;
      else
        charac_id1   := CHARACTERIZATION_ID1;
        charac_val1  := CHARACTERIZATION_VALUE_1;
      end if;
    end if;

    if CHARACTERIZATION_ID2 is not null then
      select C_CHARACT_TYPE
        into charact_type
        from GCO_CHARACTERIZATION
       where GCO_CHARACTERIZATION_ID = CHARACTERIZATION_ID2;

      if charact_type <> '2' then
        charac_id2   := null;
        charac_val2  := null;
      else
        charac_id2   := CHARACTERIZATION_ID2;
        charac_val2  := CHARACTERIZATION_VALUE_2;
      end if;
    end if;

    if CHARACTERIZATION_ID3 is not null then
      select C_CHARACT_TYPE
        into charact_type
        from GCO_CHARACTERIZATION
       where GCO_CHARACTERIZATION_ID = CHARACTERIZATION_ID3;

      if charact_type <> '2' then
        charac_id3   := null;
        charac_val3  := null;
      else
        charac_id3   := CHARACTERIZATION_ID3;
        charac_val3  := CHARACTERIZATION_VALUE_3;
      end if;
    end if;

    if CHARACTERIZATION_ID4 is not null then
      select C_CHARACT_TYPE
        into charact_type
        from GCO_CHARACTERIZATION
       where GCO_CHARACTERIZATION_ID = CHARACTERIZATION_ID4;

      if charact_type <> '2' then
        charac_id4   := null;
        charac_val4  := null;
      else
        charac_id4   := CHARACTERIZATION_ID4;
        charac_val4  := CHARACTERIZATION_VALUE_4;
      end if;
    end if;

    if CHARACTERIZATION_ID5 is not null then
      select C_CHARACT_TYPE
        into charact_type
        from GCO_CHARACTERIZATION
       where GCO_CHARACTERIZATION_ID = CHARACTERIZATION_ID5;

      if charact_type <> '2' then
        charac_id5   := null;
        charac_val5  := null;
      else
        charac_id5   := CHARACTERIZATION_ID5;
        charac_val5  := CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    -- Recherche s'il y a déjà un totalisateur de position
    select max(DOC_POSI_ACCUMULATOR_ID)
      into accumulator_id
      from DOC_POSI_ACCUMULATOR
     where PAC_ALLKEY =
             to_char(week_id) ||
             '¦' ||
             to_char(GOOD_ID) ||
             '¦' ||
             DOC_POS_STATUS ||
             '¦' ||
             GAUGE_TYPE ||
             '¦' ||
             aDIC_GAUGE_TYPE_DOC_ID ||
             '|' ||
             to_char(THIRD_ID) ||
             '¦' ||
             to_char(charac_id1) ||
             '¦' ||
             to_char(charac_id2) ||
             '¦' ||
             to_char(charac_id3) ||
             '¦' ||
             to_char(charac_id4) ||
             '¦' ||
             to_char(charac_id5) ||
             '¦' ||
             charac_val1 ||
             '¦' ||
             charac_val2 ||
             '¦' ||
             charac_val3 ||
             '¦' ||
             charac_val4 ||
             '¦' ||
             charac_val5;

    -- Ajout d'un totalisateur de position s'il n'y en avait pas
    if accumulator_id is null then
      insert into DOC_POSI_ACCUMULATOR
                  (DOC_POSI_ACCUMULATOR_ID
                 , DIC_GAUGE_TYPE_DOC_ID
                 , PAC_QUANTITY_WEEK
                 , PAC_BALANCE_WEEK
                 , PAC_VALUE_WEEK
                 , PC_YEAR_WEEK_ID
                 , GCO_GOOD_ID
                 , C_DOC_POS_STATUS
                 , PAC_THIRD_ID
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , PAC_CHARACTERIZATION_VALUE_1
                 , PAC_CHARACTERIZATION_VALUE_2
                 , PAC_CHARACTERIZATION_VALUE_3
                 , PAC_CHARACTERIZATION_VALUE_4
                 , PAC_CHARACTERIZATION_VALUE_5
                 , C_GAUGE_TYPE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (INIT_ID_SEQ.nextval
                 , aDIC_GAUGE_TYPE_DOC_ID
                 , nvl(sign * week_quantity, 0)
                 , nvl(sign * week_balance, 0)
                 , sign * week_value
                 , week_id
                 , GOOD_ID
                 , DOC_POS_STATUS
                 , THIRD_ID
                 , charac_id1
                 , charac_id2
                 , charac_id3
                 , charac_id4
                 , charac_id5
                 , charac_val1
                 , charac_val2
                 , charac_val3
                 , charac_val4
                 , charac_val5
                 , GAUGE_TYPE
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    else
      -- Modification de la position de totalisation existante
      if global = 0 then
        update DOC_POSI_ACCUMULATOR
           set PAC_QUANTITY_WEEK = PAC_QUANTITY_WEEK +(sign * week_quantity)
             , PAC_BALANCE_WEEK = PAC_BALANCE_WEEK +(sign * week_balance)
             , PAC_VALUE_WEEK = PAC_VALUE_WEEK +(sign * week_value)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSI_ACCUMULATOR_ID = accumulator_id;
      else
        update DOC_POSI_ACCUMULATOR
           set PAC_QUANTITY_WEEK = PAC_QUANTITY_WEEK +(sign * week_quantity)
             , PAC_BALANCE_WEEK = PAC_BALANCE_WEEK +(sign * week_balance)
             , PAC_VALUE_WEEK = PAC_VALUE_WEEK +(sign * week_value)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_POSI_ACCUMULATOR_ID = accumulator_id;
      end if;
    end if;

    -- Effacement des totalisateurs de position à zéro
    -- Effectue cet effacement uniquement lors d'une mise à jour
    -- non globale
    if     global = 0
       and accumulator_id is not null then
      delete from DOC_POSI_ACCUMULATOR
            where PAC_QUANTITY_WEEK = 0
              and PAC_BALANCE_WEEK = 0
              and PAC_VALUE_WEEK = 0
              and DOC_POSI_ACCUMULATOR_ID = accumulator_id;
    end if;
  exception
    when others then
      null;   -- n'arrête pas le traitement en cas d'erreur
  end DOC_TOTAL_POSITION;

  /**
  * Description
  *   vide les buffer document et position
  */
  procedure PURGE_BUFFERS
  is
  begin
    PURGE_DOC_BUFFER;
    PURGE_POS_BUFFER;
  end PURGE_BUFFERS;

  -- mert à jour les  totalisateurs de positions avec les enregistrements qu'il y a dans le buffer
  procedure PURGE_DOC_BUFFER
  is
    cursor buffer
    is
      select     *
            from DOC_DOCU_ACCU_BUFFER
      for update;

    buffer_tuple buffer%rowtype;
  begin
    open buffer;

    fetch buffer
     into buffer_tuple;

    while buffer%found loop
      DOC_ACCUMULATOR.DOC_TOTAL_DOCUMENT(buffer_tuple.DOC_DOCUMENT_ID
                                       , buffer_tuple.DMT_DATE_DOCUMENT
                                       , buffer_tuple.DIC_GAUGE_TYPE_DOC_ID
                                       , buffer_tuple.C_DOCUMENT_STATUS
                                       , buffer_tuple.PAC_THIRD_ID
                                       , buffer_tuple.FOO_DOCUMENT_TOTAL_AMOUNT
                                       , buffer_tuple.FOO_TOTAL_VAT_AMOUNT
                                       , buffer_tuple.DAB_SIGN
                                       , 0
                                        );

      delete from DOC_DOCU_ACCU_BUFFER
            where DOC_DOCU_ACCU_BUFFER_ID = buffer_tuple.DOC_DOCU_ACCU_BUFFER_ID;

      fetch buffer
       into buffer_tuple;
    end loop;

    close buffer;
  end PURGE_DOC_BUFFER;

  -- mert à jour les  totalisateurs de positions avec les enregistrements qu'il y a dans le buffer
  procedure PURGE_POS_BUFFER
  is
    cursor buffer
    is
      select     *
            from DOC_POSI_ACCU_BUFFER
      for update;

    buffer_tuple buffer%rowtype;
  begin
    open buffer;

    fetch buffer
     into buffer_tuple;

    while buffer%found loop
      DOC_ACCUMULATOR.DOC_TOTAL_POSITION(buffer_tuple.GCO_GOOD_ID
                                       , buffer_tuple.PAC_THIRD_ID
                                       , buffer_tuple.DIC_GAUGE_TYPE_DOC_ID
                                       , buffer_tuple.GCO_CHARACTERIZATION_ID
                                       , buffer_tuple.GCO_GCO_CHARACTERIZATION_ID
                                       , buffer_tuple.GCO2_GCO_CHARACTERIZATION_ID
                                       , buffer_tuple.GCO3_GCO_CHARACTERIZATION_ID
                                       , buffer_tuple.GCO4_GCO_CHARACTERIZATION_ID
                                       , buffer_tuple.ABU_CHARACTERIZATION_VALUE_1
                                       , buffer_tuple.ABU_CHARACTERIZATION_VALUE_2
                                       , buffer_tuple.ABU_CHARACTERIZATION_VALUE_3
                                       , buffer_tuple.ABU_CHARACTERIZATION_VALUE_4
                                       , buffer_tuple.ABU_CHARACTERIZATION_VALUE_5
                                       , buffer_tuple.ABU_DELAY
                                       , buffer_tuple.ABU_FINAL_DELAY
                                       , buffer_tuple.ABU_DOCUMENT_DATE
                                       , buffer_tuple.ABU_FINAL_QUANTITY
                                       , buffer_tuple.ABU_BALANCE_QUANTITY
                                       , buffer_tuple.ABU_NET_VALUE_EXCL
                                       , buffer_tuple.C_DOC_POS_STATUS
                                       , buffer_tuple.ABU_BALANCE_STATUS
                                       , buffer_tuple.C_GAUGE_TYPE
                                       , buffer_tuple.ABU_SIGN
                                       , 0
                                        );

      delete from DOC_POSI_ACCU_BUFFER
            where DOC_POSI_ACCU_BUFFER_ID = buffer_tuple.DOC_POSI_ACCU_BUFFER_ID;

      fetch buffer
       into buffer_tuple;
    end loop;

    close buffer;
  end PURGE_POS_BUFFER;

  /*
  * Description
  *   Procèdure de mise à jour de tous les totalisateurs de position et de document
  */
  procedure DOC_REDO_ACCUMULATORS
  is
  begin
    -- Totalisateurs de document
    DOC_REDO_DOCU_ACCUMULATORS;
    -- Totalisateurs de position
    DOC_REDO_POSI_ACCUMULATORS;
  end DOC_REDO_ACCUMULATORS;

  /*
  * Description
  *   Procèdure de mise à jour de tous les totalisateurs de document
  */
  procedure DOC_REDO_DOCU_ACCUMULATORS
  is
    i                integer;

    -- curseur sur les totaux du pied de document
    cursor DOC_VALUES_CURSOR
    is
      select DOC.DOC_DOCUMENT_ID
           , DOC.DMT_DATE_DOCUMENT
           , DOC.DIC_GAUGE_TYPE_DOC_ID
           , DOC.C_DOCUMENT_STATUS
           , DOC.DMT_RATE_OF_EXCHANGE
           , DOC.DMT_BASE_PRICE
           , DOC.PAC_THIRD_ID
           , FOO.FOO_DOCUMENT_TOT_AMOUNT_B
           , FOO_TOT_VAT_AMOUNT_B
        from DOC_DOCUMENT DOC
           , DOC_FOOT FOO
       where FOO.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID;

    doc_values_tuple doc_values_cursor%rowtype;
  begin
    -- Effacement des ancienne valeurs contenues dans la table des totalisateurs de document
    delete from DOC_DOCU_ACCUMULATOR;

    delete from DOC_DOCU_ACCU_BUFFER;

    i  := 0;

    -- Ouverture du curseur sur les ID de documents
    open DOC_VALUES_CURSOR;

    fetch DOC_VALUES_CURSOR
     into doc_values_tuple;

    -- Pour tous les documents, on met à jour les totalisateurs de document
    while DOC_VALUES_CURSOR%found loop
      i  := i + 1;
      -- Totalisateurs de document
      -- mise à jour des totalisateurs de document
      DOC_TOTAL_DOCUMENT(doc_values_tuple.DOC_DOCUMENT_ID
                       , doc_values_tuple.DMT_DATE_DOCUMENT
                       , doc_values_tuple.DIC_GAUGE_TYPE_DOC_ID
                       , doc_values_tuple.C_DOCUMENT_STATUS
                       , doc_values_tuple.PAC_THIRD_ID
                       , nvl(doc_values_tuple.FOO_DOCUMENT_TOT_AMOUNT_B, 0)
                       , nvl(doc_values_tuple.FOO_TOT_VAT_AMOUNT_B, 0)
                       , 1
                       , 0
                        );

      -- Document suivant
      fetch DOC_VALUES_CURSOR
       into doc_values_tuple;

      if i = 100 then
        i  := 0;
      --commit;
      end if;
    end loop;

    close DOC_VALUES_CURSOR;

    --commit;

    -- Effacement des totalisateurs de document à zéro
    delete from DOC_DOCU_ACCUMULATOR
          where DAC_NUMBER_MONTH = 0
            and DAC_VALUE_MONTH = 0;
  --commit;
  end DOC_REDO_DOCU_ACCUMULATORS;

  /*
  * Procèdure de mise à jour de tous les totalisateurs de position
  */
  procedure DOC_REDO_POSI_ACCUMULATORS
  is
    i                     integer;

    -- curseur sur tous les detail position de la position
    cursor detail_position_cursor
    is
      select DET.GCO_CHARACTERIZATION_ID
           , DET.GCO_GCO_CHARACTERIZATION_ID
           , DET.GCO2_GCO_CHARACTERIZATION_ID
           , DET.GCO3_GCO_CHARACTERIZATION_ID
           , DET.GCO4_GCO_CHARACTERIZATION_ID
           , DET.PDE_CHARACTERIZATION_VALUE_1
           , DET.PDE_CHARACTERIZATION_VALUE_2
           , DET.PDE_CHARACTERIZATION_VALUE_3
           , DET.PDE_CHARACTERIZATION_VALUE_4
           , DET.PDE_CHARACTERIZATION_VALUE_5
           , DET.PDE_FINAL_DELAY
           , DET.PDE_FINAL_QUANTITY
           , DET.PDE_BALANCE_QUANTITY
           , POS.GCO_GOOD_ID
           , POS.C_DOC_POS_STATUS
           , POS.C_GAUGE_TYPE_POS
           , POS.ACS_TAX_CODE_ID
           , POS.POS_NET_VALUE_EXCL_B
           , DOC.PAC_THIRD_ID
           , DOC.DIC_GAUGE_TYPE_DOC_ID
           , DOC.DMT_DATE_DOCUMENT
           , GPO.GAP_DELAY
           , GST.GAS_BALANCE_STATUS
           , GAU.C_GAUGE_TYPE
        from DOC_POSITION_DETAIL DET
           , DOC_POSITION POS
           , DOC_DOCUMENT DOC
           , DOC_GAUGE_POSITION GPO
           , DOC_GAUGE_STRUCTURED GST
           , DOC_GAUGE GAU
       where POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
         and DET.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and GPO.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
         and GST.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GST.DOC_GAUGE_ID
         and POS.GCO_GOOD_ID is not null;

    detail_position_tuple detail_position_cursor%rowtype;
  begin
    -- Effacement des ancienne valeurs contenues dans la table des totalisateurs de position
    delete from DOC_POSI_ACCUMULATOR;

    -- Effacement du buffer car il est automatiquement recalculé
    delete from DOC_POSI_ACCU_BUFFER;

    -- Il ne faut pas que l'on puisse remplir le buffer pendant le recalcul, on risquerait d'avoir des données à double
    lock table DOC_POSI_ACCU_BUFFER in exclusive mode;
    i  := 0;

    -- Ouverture du curseur sur les ID de documents
    open detail_position_cursor;

    fetch detail_position_cursor
     into detail_position_tuple;

    -- Pour tous les documents, on met à jour les totalisateurs de position
    while detail_position_cursor%found loop
      i  := i + 1;
      -- Totalisateurs de position
      DOC_ACCUMULATOR.DOC_TOTAL_POSITION(detail_position_tuple.GCO_GOOD_ID
                                       , detail_position_tuple.PAC_THIRD_ID
                                       , detail_position_tuple.DIC_GAUGE_TYPE_DOC_ID
                                       , detail_position_tuple.GCO_CHARACTERIZATION_ID
                                       , detail_position_tuple.GCO_GCO_CHARACTERIZATION_ID
                                       , detail_position_tuple.GCO2_GCO_CHARACTERIZATION_ID
                                       , detail_position_tuple.GCO3_GCO_CHARACTERIZATION_ID
                                       , detail_position_tuple.GCO4_GCO_CHARACTERIZATION_ID
                                       , detail_position_tuple.PDE_CHARACTERIZATION_VALUE_1
                                       , detail_position_tuple.PDE_CHARACTERIZATION_VALUE_2
                                       , detail_position_tuple.PDE_CHARACTERIZATION_VALUE_3
                                       , detail_position_tuple.PDE_CHARACTERIZATION_VALUE_4
                                       , detail_position_tuple.PDE_CHARACTERIZATION_VALUE_5
                                       , detail_position_tuple.GAP_DELAY
                                       , nvl(detail_position_tuple.PDE_FINAL_DELAY, detail_position_tuple.DMT_DATE_DOCUMENT)
                                       , detail_position_tuple.DMT_DATE_DOCUMENT
                                       , detail_position_tuple.PDE_FINAL_QUANTITY
                                       , detail_position_tuple.PDE_BALANCE_QUANTITY
                                       , detail_position_tuple.POS_NET_VALUE_EXCL_B
                                       , detail_position_tuple.C_DOC_POS_STATUS
                                       , detail_position_tuple.GAS_BALANCE_STATUS
                                       , detail_position_tuple.C_GAUGE_TYPE
                                       , 1
                                       , 0
                                        );

      fetch detail_position_cursor
       into detail_position_tuple;

      if i = 100 then
        i  := 0;
        --commit;
        -- Il ne faut pas que l'on puisse remplir le buffer pendant le recalcul, on risquerait d'avoir des données à double
        lock table DOC_POSI_ACCU_BUFFER in exclusive mode;
      end if;
    end loop;

    close detail_position_cursor;

    --commit;

    -- Effacement des totalisateurs de position à zéro
    delete from DOC_POSI_ACCUMULATOR
          where PAC_QUANTITY_WEEK = 0
            and PAC_BALANCE_WEEK = 0
            and PAC_VALUE_WEEK = 0;
  --commit;
  end DOC_REDO_POSI_ACCUMULATORS;
end DOC_ACCUMULATOR;
