--------------------------------------------------------
--  DDL for Package Body DOC_DETAIL_SPAN_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DETAIL_SPAN_FUNCTIONS" 
is
  /**
  * procedure ClearList
  * Description
  *    Effacement des données de la variable temp
  */
  procedure ClearList
  is
  begin
    tblDetail.delete;
  end ClearList;

  /**
  * procedure InitSpanDetail
  * Description
  *    Création de N des tuples dans la variable temp en copie du detail ID passé
  */
  procedure InitSpanDetail(aDetailID in number, aDetailCount in integer)
  is
    intIndex integer;
  begin
    -- Effacement des données de la variable temp
    ClearList;

    -- Copier N fois le détail passé en param dans la variable temp
    select PDE.*
    bulk collect into tblDetail
      from DOC_POSITION_DETAIL PDE
         , PCS.PC_NUMBER PNO
     where DOC_POSITION_DETAIL_ID = aDetailID
       and PNO.no <= aDetailCount;

    -- Changer la valeur de l'ID du détail et maj des champs A_...
    if tblDetail.count > 0 then
      for intIndex in tblDetail.first .. tblDetail.last loop
        select INIT_ID_SEQ.nextval
             , null
             , null
             , null
             , PCS.PC_I_LIB_SESSION.GetUserIni
             , sysdate
             , null
             , null
          into tblDetail(intIndex).DOC_POSITION_DETAIL_ID
             , tblDetail(intIndex).DOC_DOC_POSITION_DETAIL_ID
             , tblDetail(intIndex).DOC2_DOC_POSITION_DETAIL_ID
             , tblDetail(intIndex).PDE_BALANCE_PARENT
             , tblDetail(intIndex).A_IDCRE
             , tblDetail(intIndex).A_DATECRE
             , tblDetail(intIndex).A_IDMOD
             , tblDetail(intIndex).A_DATEMOD
          from dual;
      end loop;
    end if;
  end InitSpanDetail;

  /**
  * procedure InsertSpanDetail
  * Description
  *    Insert dans la base des tuples de la variable temp
  */
  procedure InsertSpanDetail(iPositionId DOC_POSITION_DETAIL.DOC_POSITION_ID%type)
  is
    lUpdateIndex integer := 1;
  begin
    -- prise en compte des detail créés sans les valeurs de caractérisations
    for ltplDetailToUpdate in (select DOC_POSITION_DETAIL_ID
                                 from DOC_POSITION_DETAIL
                                where DOC_POSITION_ID = iPositionId
                                  and (    (    GCO_CHARACTERIZATION_ID is not null
                                            and PDE_CHARACTERIZATION_VALUE_1 is null)
                                       or (    GCO_GCO_CHARACTERIZATION_ID is not null
                                           and PDE_CHARACTERIZATION_VALUE_2 is null)
                                       or (    GCO2_GCO_CHARACTERIZATION_ID is not null
                                           and PDE_CHARACTERIZATION_VALUE_3 is null)
                                       or (    GCO3_GCO_CHARACTERIZATION_ID is not null
                                           and PDE_CHARACTERIZATION_VALUE_4 is null)
                                       or (    GCO4_GCO_CHARACTERIZATION_ID is not null
                                           and PDE_CHARACTERIZATION_VALUE_5 is null)) ) loop

      update DOC_POSITION_DETAIL
         set PDE_CHARACTERIZATION_VALUE_1 = nvl(PDE_CHARACTERIZATION_VALUE_1, tblDetail(lUpdateIndex).PDE_CHARACTERIZATION_VALUE_1)
           , PDE_CHARACTERIZATION_VALUE_2 = nvl(PDE_CHARACTERIZATION_VALUE_2, tblDetail(lUpdateIndex).PDE_CHARACTERIZATION_VALUE_2)
           , PDE_CHARACTERIZATION_VALUE_3 = nvl(PDE_CHARACTERIZATION_VALUE_3, tblDetail(lUpdateIndex).PDE_CHARACTERIZATION_VALUE_3)
           , PDE_CHARACTERIZATION_VALUE_4 = nvl(PDE_CHARACTERIZATION_VALUE_4, tblDetail(lUpdateIndex).PDE_CHARACTERIZATION_VALUE_4)
           , PDE_CHARACTERIZATION_VALUE_5 = nvl(PDE_CHARACTERIZATION_VALUE_5, tblDetail(lUpdateIndex).PDE_CHARACTERIZATION_VALUE_5)
       where DOC_POSITION_DETAIL_ID = ltplDetailToUpdate.DOC_POSITION_DETAIL_ID;

      lUpdateIndex  := lUpdateIndex + 1;
    end loop;

    -- Insertion dans la base des tuples
    if tblDetail.count - lUpdateIndex > 0 then
      for lIndex in lUpdateIndex .. tblDetail.last loop
        insert into DOC_POSITION_DETAIL
             values tblDetail(lIndex);
      end loop;
    end if;

    -- Effacement des données de la variable temp
    ClearList;
  end InsertSpanDetail;

  /**
  * procedure InsertSpanDetail_IO_View
  * Description
  *    Insert dans la base des tuples de la variable temp
  */
  procedure InsertSpanDetail_IO_View(iPositionId DOC_POSITION_DETAIL.DOC_POSITION_ID%type)
  is
    lUpdateIndex integer := 1;
  begin
    -- prise en compte des detail créés sans les valeurs de caractérisations
    for ltplDetailToUpdate in (select DOC_POSITION_DETAIL_ID
                                 from DOC_POSITION_DETAIL
                                where DOC_POSITION_ID = iPositionId
                                  and (    (    GCO_CHARACTERIZATION_ID is not null
                                            and PDE_CHARACTERIZATION_VALUE_1 is null)
                                       or (    GCO_GCO_CHARACTERIZATION_ID is not null
                                           and PDE_CHARACTERIZATION_VALUE_2 is null)
                                       or (    GCO2_GCO_CHARACTERIZATION_ID is not null
                                           and PDE_CHARACTERIZATION_VALUE_3 is null)
                                       or (    GCO3_GCO_CHARACTERIZATION_ID is not null
                                           and PDE_CHARACTERIZATION_VALUE_4 is null)
                                       or (    GCO4_GCO_CHARACTERIZATION_ID is not null
                                           and PDE_CHARACTERIZATION_VALUE_5 is null)
                                      ) ) loop
      exit when tblDetail.count < lUpdateIndex;
      update V_DOC_POSITION_DETAIL_IO
         set PDE_CHARACTERIZATION_VALUE_1 = nvl(PDE_CHARACTERIZATION_VALUE_1, tblDetail(lUpdateIndex).PDE_CHARACTERIZATION_VALUE_1)
           , PDE_CHARACTERIZATION_VALUE_2 = nvl(PDE_CHARACTERIZATION_VALUE_2, tblDetail(lUpdateIndex).PDE_CHARACTERIZATION_VALUE_2)
           , PDE_CHARACTERIZATION_VALUE_3 = nvl(PDE_CHARACTERIZATION_VALUE_3, tblDetail(lUpdateIndex).PDE_CHARACTERIZATION_VALUE_3)
           , PDE_CHARACTERIZATION_VALUE_4 = nvl(PDE_CHARACTERIZATION_VALUE_4, tblDetail(lUpdateIndex).PDE_CHARACTERIZATION_VALUE_4)
           , PDE_CHARACTERIZATION_VALUE_5 = nvl(PDE_CHARACTERIZATION_VALUE_5, tblDetail(lUpdateIndex).PDE_CHARACTERIZATION_VALUE_5)
           , PDE_BASIS_QUANTITY = 1
       where DOC_POSITION_DETAIL_ID = ltplDetailToUpdate.DOC_POSITION_DETAIL_ID;

      lUpdateIndex  := lUpdateIndex + 1;
    end loop;

    -- Insertion dans la base des tuples
    if tblDetail.count - lUpdateIndex > 0 then
      for lIndex in lUpdateIndex .. tblDetail.last loop
        insert into V_DOC_POSITION_DETAIL_IO
             values tblDetail(lIndex);
      end loop;
    end if;

    -- Effacement des données de la variable temp
    ClearList;
  end InsertSpanDetail_IO_View;

  /**
  * procedure InitIDValues
  * Description
  *    Init de données de type ID dans la variable temp
  */
  procedure InitIDValues(aFieldName in varchar2, aIndex integer, aValue number)
  is
    vSQL varchar2(4000);
    vID  number(12)     default null;
  begin
    -- Si valeur est à 0 (appel depuis Delphi) insèrer la valeur NULL
    if aValue <> 0 then
      vID  := aValue;
    end if;

    vSQL  := ' begin ' || ' DOC_DETAIL_SPAN_FUNCTIONS.tblDetail(:INT_INDEX).' || aFieldName || ' := :ID_VALUE;' || ' end;';

    execute immediate vSQL
                using aIndex, vID;
  end InitIDValues;

  /**
  * procedure InitNumberValues
  * Description
  *    Init de données de type numérique dans la variable temp
  */
  procedure InitNumberValues(aFieldName in varchar2, aIndex integer, aValue number)
  is
    vSQL varchar2(4000);
  begin
    vSQL  := ' begin ' || ' DOC_DETAIL_SPAN_FUNCTIONS.tblDetail(:INT_INDEX).' || aFieldName || ' := :NUM_VALUE;' || ' end;';

    execute immediate vSQL
                using aIndex, aValue;
  end InitNumberValues;

  /**
  * procedure InitVarcharValues
  * Description
  *    Init de données de type varchar dans la variable temp
  */
  procedure InitVarcharValues(aFieldName in varchar2, aIndex integer, aValue varchar2)
  is
    vSQL varchar2(4000);
  begin
    vSQL  := ' begin ' || ' DOC_DETAIL_SPAN_FUNCTIONS.tblDetail(:INT_INDEX).' || aFieldName || ' := :VCH_VALUE;' || ' end;';

    execute immediate vSQL
                using aIndex, aValue;
  end InitVarcharValues;
end DOC_DETAIL_SPAN_FUNCTIONS;
