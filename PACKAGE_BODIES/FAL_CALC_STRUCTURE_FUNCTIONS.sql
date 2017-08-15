--------------------------------------------------------
--  DDL for Package Body FAL_CALC_STRUCTURE_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_CALC_STRUCTURE_FUNCTIONS" 
is
  /**
  * function ControlElementWithBasisRubric
  * Description : Controle de la cohérence Element de coût <--> rubrique de base associée
  *
  * @author ECA
  * @private
  * @param
  */
  function ControlElementWithBasisRubric(aC_COST_ELEMENT_TYPE in varchar2, aC_BASIS_RUBRIC in varchar2)
    return varchar2
  is
    aMessage varchar2(255);
  begin
    aMessage  := '';

    if     aC_COST_ELEMENT_TYPE = 'MAT'
       and aC_BASIS_RUBRIC <> '1' then
      aMessage  := PCS.PC_FUNCTIONS.TranslateWord('Incohérence : L''élément de coût "matière" comprend d''autres rubriques de base que la matière !');
    elsif     aC_COST_ELEMENT_TYPE = 'TMA'
          and aC_BASIS_RUBRIC <> '2' then
      aMessage  :=
             PCS.PC_FUNCTIONS.TranslateWord('Incohérence : L''élément de coût "travail machine" comprend d''autres rubriques de base que le travail machine !');
    elsif     aC_COST_ELEMENT_TYPE = 'TMO'
          and aC_BASIS_RUBRIC <> '6' then
      aMessage  :=
        PCS.PC_FUNCTIONS.TranslateWord
                              ('Incohérence : L''élément de coût "travail main d''oeuvre" comprend d''autres rubriques de base que le travail main d''oeuvre !');
    elsif     aC_COST_ELEMENT_TYPE = 'SST'
          and aC_BASIS_RUBRIC <> '4' then
      aMessage  :=
               PCS.PC_FUNCTIONS.TranslateWord('Incohérence : L''élément de coût "sous-traitance" comprend d''autres rubriques de base que la sous-traitance !');
    end if;

    return aMessage;
  end;

  /**
  * function ControlByLevel
  * Description : Controle récursif des différents niveau afin de vérifier
  *               le contenu des sous-totaux
  *
  * @author ECA
  * @private
  * @param   aFAL_ADV_STRUCT_CALC_ID : Structure à contrôler
  */
  function ControlByLevel(aFAL_ADV_RATE_STRUCT_ID in number, aC_COST_ELEMENT_TYPE in varchar2, aPRFControl in boolean)
    return varchar2
  is
    cursor crOneStructureLevel
    is
      select ARS.FAL_ADV_RATE_STRUCT_ID
           , ARS.C_BASIS_RUBRIC
           , ARS.C_RUBRIC_TYPE
           , ARS.ARS_SEQUENCE
        from FAL_ADV_RATE_STRUCT ARS
           , FAL_ADV_TOTAL_RATE ATR
       where ATR.FAL_ADV_RATE_STRUCT_ID = aFAL_ADV_RATE_STRUCT_ID
         and ATR.FAL_FAL_ADV_RATE_STRUCT_ID = ARS.FAL_ADV_RATE_STRUCT_ID;

    aMessage varchar2(4000);
  begin
    for tplOneStructureLevel in crOneStructureLevel loop
      -- Contrôle des éléments de coûts
      if not aPRFControl then
        -- Si Rubrique de type taux ou montant
        if tplOneStructureLevel.C_RUBRIC_TYPE in('2', '4') then
          return PCS.PC_FUNCTIONS.TranslateWord('Rubrique de type taux ou montant interdite sous des éléments de coût !') ||
                 chr(13) ||
                 PCS.PC_FUNCTIONS.TranslateWord('Séquence') ||
                 ' : ' ||
                 tplOneStructureLevel.ARS_SEQUENCE;
        -- Si rubrique de type sous total
        elsif tplOneStructureLevel.C_RUBRIC_TYPE = '3' then
          aMessage  := ControlByLevel(tplOneStructureLevel.FAL_ADV_RATE_STRUCT_ID, aC_COST_ELEMENT_TYPE, aPRFControl);

          if aMessage is not null then
            return aMessage;
          end if;
        -- Si rubrique de base, on vérifie la concordance élément de coût <-> rubrique de base
        elsif tplOneStructureLevel.C_RUBRIC_TYPE = '1' then
          aMessage  := ControlElementWithBasisRubric(aC_COST_ELEMENT_TYPE, tplOneStructureLevel.C_BASIS_RUBRIC);

          if aMessage is not null then
            return aMessage;
          end if;
        end if;
      -- Contrôle du niveau de PRF
      else
        -- Si Rubrique de type taux ou montant
        if tplOneStructureLevel.C_RUBRIC_TYPE in('2', '4') then
          return PCS.PC_FUNCTIONS.TranslateWord('Rubrique de type taux ou montant interdite sous un niveau de PRF !') ||
                 chr(13) ||
                 PCS.PC_FUNCTIONS.TranslateWord('Séquence') ||
                 ' : ' ||
                 tplOneStructureLevel.ARS_SEQUENCE;
        -- Si rubrique de type sous total
        elsif tplOneStructureLevel.C_RUBRIC_TYPE = '3' then
          aMessage  := ControlByLevel(tplOneStructureLevel.FAL_ADV_RATE_STRUCT_ID, aC_COST_ELEMENT_TYPE, aPRFControl);

          if aMessage is not null then
            return aMessage;
          end if;
        end if;
      end if;
    end loop;

    return '';
  end;

  /**
  * procedure StructureCoherenceControl
  * Description : Procedure destinée au contrôle des règles de gestion et
  *               limitations des structures de comptabilité industrielle.
  *
  * @author ECA
  * @public
  * @param   aFAL_ADV_STRUCT_CALC_ID : Structure à contrôler
  * @param   aMessage : Message utilisateur
  */
  procedure StructureCoherenceControl(aFAL_ADV_STRUCT_CALC_ID in number, aMessage in out varchar2)
  is
    cursor crFAL_ADV_RATE_STRUCT
    is
      select ARS.FAL_ADV_RATE_STRUCT_ID
           , ARS.C_COST_ELEMENT_TYPE
           , ARS.C_BASIS_RUBRIC
        from FAL_ADV_RATE_STRUCT ARS
       where FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID
         and C_COST_ELEMENT_TYPE is not null;

    iNbPRFLevel             integer;
    iErrorOnCostElement     integer;
    iErrorOnPRFDefinition   integer;
    iErrorOnBasisrubricType integer;
    aPRF_LEVEL              number;
  begin
    aMessage  := '';

    -- On vérifie que la structure ne comporte que des rubriques de base de type,
    -- matière, sous-traitance, travail machine, travail main d'oeuvre
    begin
      select count(FAL_ADV_RATE_STRUCT_ID)
        into iErrorOnBasisrubricType
        from FAL_ADV_RATE_STRUCT
       where C_BASIS_RUBRIC in('3', '5')
         and FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID;
    exception
      when no_data_found then
        iErrorOnBasisrubricType  := 0;
    end;

    if nvl(iErrorOnBasisrubricType, 0) > 0 then
      aMessage  := PCS.PC_FUNCTIONS.TranslateWord('La structure ne doit pas posséder de rubrique de base de type matières précieuses ou affectables.');
      return;
    end if;

    -- Vérification de l'existence d'un unique niveau de PRF
    begin
      select count(FAL_ADV_RATE_STRUCT_ID)
        into iNbPRFLevel
        from FAL_ADV_RATE_STRUCT
       where FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID
         and ARS_PRF_LEVEL = 1;
    exception
      when no_data_found then
        iNbPRFLevel  := 0;
    end;

    if iNbPRFLevel = 0 then
      aMessage  := PCS.PC_FUNCTIONS.TranslateWord('La structure doit posséder un niveau de PRF !');
      return;
    elsif iNbPRFLevel > 1 then
      aMessage  := PCS.PC_FUNCTIONS.TranslateWord('La structure ne doit posséder qu''un seul niveau de PRF !');
      return;
    end if;

    -- Vérification de la Structure sous les éléments de coût.
    -- Elle ne doit contenir d'autre élément de prix que les rubriques de base correspondantes
    -- ou éventuellement des rubriques de type sous-totaux
    for tplFAL_ADV_RATE_STRUCT in crFAL_ADV_RATE_STRUCT loop
      aMessage  := ControlElementWithBasisRubric(tplFAL_ADV_RATE_STRUCT.C_COST_ELEMENT_TYPE, tplFAL_ADV_RATE_STRUCT.C_BASIS_RUBRIC);

      if aMessage is not null then
        return;
      end if;

      aMessage  := ControlByLevel(tplFAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID, tplFAL_ADV_RATE_STRUCT.C_COST_ELEMENT_TYPE, false);

      if aMessage is not null then
        return;
      end if;
    end loop;

    -- Vérification de la règle PRF = Somme des éléments de coût, et rien d'autre.
    begin
      select FAL_ADV_RATE_STRUCT_ID
        into aPRF_LEVEL
        from FAL_ADV_RATE_STRUCT
       where FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID
         and ARS_PRF_LEVEL = 1;

      aMessage  := ControlByLevel(aPRF_LEVEL, null, true);

      if aMessage is not null then
        return;
      end if;
    exception
      when others then
        null;
    end;

    -- Une structure ne doit posséder qu'une fois chacun des éléments de coûts
    begin
      select   max(count(FAL_ADV_RATE_STRUCT_ID) )
          into iErrorOnCostElement
          from FAL_ADV_RATE_STRUCT
         where C_COST_ELEMENT_TYPE is not null
           and FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID
      group by C_COST_ELEMENT_TYPE
        having count(FAL_ADV_RATE_STRUCT_ID) > 1;

      if iErrorOnCostElement > 1 then
        aMessage  :=
                    PCS.PC_FUNCTIONS.TranslateWord('Une structure pour comptabilité industrielle ne doit posséder qu''une fois chacun des éléments de coûts !');
        return;
      end if;
    exception
      when others then
        raise;
    end;
  end;

  /**
  * Procedure DuplicateADVCalculationStructure
  *
  * Description
  *   Fonction de dupplication des structures de calculation avancées
  *
  * @author  Emmanuel Cassis
  * @version 24.08.2004
  * @public
  * @param aFAL_ADV_STRUCT_CALC_ID : Structure à dupliquer
  */
  procedure DuplicateADVCalculationStruct(aFAL_ADV_STRUCT_CALC_ID FAL_ADV_STRUCT_CALC.FAL_ADV_STRUCT_CALC_ID%type)
  is
    -- Curseur
    cursor CUR_FAL_ADV_RATE_STRUCT
    is
      select   *
          from FAL_ADV_RATE_STRUCT
         where FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID
      order by ARS_SEQUENCE;

    cursor CUR_FAL_ADV_TOTAL_RATE(aFAL_ADV_RATE_STRUCT_ID FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type)
    is
      select   ATR.FAL_FAL_ADV_RATE_STRUCT_ID
             , ARS.ARS_SEQUENCE
             , ARS.FAL_ADV_STRUCT_CALC_ID
          from FAL_ADV_TOTAL_RATE ATR
             , FAL_ADV_RATE_STRUCT ARS
         where ATR.FAL_ADV_RATE_STRUCT_ID = aFAL_ADV_RATE_STRUCT_ID
           and ATR.FAL_FAL_ADV_RATE_STRUCT_ID = ARS.FAL_ADV_RATE_STRUCT_ID(+)
      order by ATR.A_DATECRE;

    -- Variables
    CurFalAdvRateStruct  CUR_FAL_ADV_RATE_STRUCT%rowtype;
    CurFalAdvTotalRate   CUR_FAL_ADV_TOTAL_RATE%rowtype;
    aNewStructureID      FAL_ADV_STRUCT_CALC.FAL_ADV_STRUCT_CALC_ID%type;
    aNewrubricID         FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type;
    aLastDecompositionID number;

    /* Duplication de la structure */
    function DuplicateADVStructure
      return FAL_ADV_STRUCT_CALC.FAL_ADV_STRUCT_CALC_ID%type
    is
      -- Variables
      aNextReference FAL_ADV_STRUCT_CALC.ASC_REFERENCE%type;
      aNewId         FAL_ADV_STRUCT_CALC.FAL_ADV_STRUCT_CALC_ID%type;
      aNewDecompId   FAL_ADV_STRUCT_DECOMP.FAL_ADV_STRUCT_DECOMP_ID%type;

      /* Génération d'une nouvelle référence */
      function GetNextReference(aFAL_ADV_STRUCT_CALC_ID FAL_ADV_STRUCT_CALC.FAL_ADV_STRUCT_CALC_ID%type)
        return FAL_ADV_STRUCT_CALC.ASC_REFERENCE%type
      is
        -- Variables
        aNewASC_REFERENCE varchar2(60);
        aNewPattern       varchar2(30);

        /* Recherche existance de la référence */
        function ExistsReference(aASC_REFERENCE FAL_ADV_STRUCT_CALC.ASC_REFERENCE%type)
          return boolean
        is
          tmpFAL_ADV_STRUCT_CALC_ID FAL_ADV_STRUCT_CALC.FAL_ADV_STRUCT_CALC_ID%type;
        begin
          select max(FAL_ADV_STRUCT_CALC_ID)
            into tmpFAL_ADV_STRUCT_CALC_ID
            from FAL_ADV_STRUCT_CALC
           where ASC_REFERENCE = aASC_REFERENCE;

          if    tmpFAL_ADV_STRUCT_CALC_ID is null
             or tmpFAL_ADV_STRUCT_CALC_ID = 0 then
            return false;
          else
            return true;
          end if;
        exception
          when no_data_found then
            return false;
          when others then
            return true;
        end ExistsReference;
      begin
        aNewPattern  := ' <NEW>';

        loop
          select ASC_REFERENCE || aNewPattern
            into aNewASC_REFERENCE
            from FAL_ADV_STRUCT_CALC
           where FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID;

          if length(aNewASC_REFERENCE) > 30 then
            aNewASC_REFERENCE  := substr(aNewASC_REFERENCE, -30);
          end if;

          exit when ExistsReference(aNewASC_REFERENCE) = false;
          aNewPattern  := aNewPattern || '<NEW>';
        end loop;

        return aNewASC_REFERENCE;
      end GetNextReference;
    begin
      -- Recherche d'une nouvelle référence valide
      aNextReference  := GetNextReference(aFAL_ADV_STRUCT_CALC_ID);
      aNewId          := GetNewId;

      -- Dupplication de la structure
      insert into FAL_ADV_STRUCT_CALC
                  (FAL_ADV_STRUCT_CALC_ID
                 , ASC_REFERENCE
                 , GCO_GOOD_CATEGORY_ID
                 , ASC_CALC_STRUCT
                 , ASC_DEFAULT_STRUCT
                 , ASC_DESCRIPTION
                 , A_DATECRE
                 , A_IDCRE
                  )
        select aNewID
             , aNextReference
             , GCO_GOOD_CATEGORY_ID
             , 0   -- On ne copie pas les booléens
             , 0   -- On ne copie pas les booléens
             , PCS.PC_FUNCTIONS.TranslateWord('Copie de', PCS.PC_I_LIB_SESSION.GetUserLangId) || ' ' || ASC_REFERENCE
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from FAL_ADV_STRUCT_CALC
         where FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID;

      -- recherche dernière décomposition entrée
      begin
        select max(FAL_ADV_STRUCT_DECOMP_ID)
          into aNewDecompId
          from FAL_ADV_STRUCT_DECOMP
         where FAL_ADV_STRUCT_CALC_ID = aNewID;
      exception
        when no_data_found then
          aNewDecompId  := null;
      end;

      -- Dupplication de la décomposition du travail
      insert into FAL_ADV_STRUCT_DECOMP
                  (FAL_ADV_STRUCT_DECOMP_ID
                 , FAL_ADV_STRUCT_CALC_ID
                 , C_DECOMPOSITION_TYPE
                 , FAL_FAL_ADV_STRUCT_DECOMP_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select GetNewId
             , aNewID
             , C_DECOMPOSITION_TYPE
             , aNewDecompId
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from FAL_ADV_STRUCT_DECOMP
         where FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID;

      return aNewID;
    end DuplicateADVStructure;

    /* Dupplication d'une rubrique */
    function DuplicateRubric(aNewStructureId FAL_ADV_STRUCT_CALC.FAL_ADV_STRUCT_CALC_ID%type, aCurFalAdvRateStruct CUR_FAL_ADV_RATE_STRUCT%rowtype)
      return FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type
    is
      -- Variables
      aNewID                      FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type;
      aNewFAL_ADV_RATE_STRUCT1_ID FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type;
    begin
      -- récupération de l'ID de la rubrique d'application du taux de même séquence que celle de la structure copiée
      begin
        select ARS.FAL_ADV_RATE_STRUCT_ID
          into aNewFAL_ADV_RATE_STRUCT1_ID
          from FAL_ADV_RATE_STRUCT ARS
         where ARS.ARS_SEQUENCE =
                 (select max(ARS2.ARS_SEQUENCE)
                    from FAL_ADV_RATE_STRUCT ARS2
                   where ARS2.FAL_ADV_STRUCT_CALC_ID = aCurFalAdvRateStruct.FAL_ADV_STRUCT_CALC_ID
                     and ARS2.FAL_ADV_RATE_STRUCT_ID = aCurFalAdvRateStruct.FAL_ADV_RATE_STRUCT1_ID)
           and ARS.FAL_ADV_STRUCT_CALC_ID = aNewStructureId;
      exception
        when no_data_found then
          aNewFAL_ADV_RATE_STRUCT1_ID  := null;
      end;

      aNewID  := GetNewId;

      insert into FAL_ADV_RATE_STRUCT
                  (FAL_ADV_RATE_STRUCT_ID
                 , C_RUBRIC_TYPE
                 , C_BASIS_RUBRIC
                 , C_COST_ELEMENT_TYPE
                 , FAL_ADV_STRUCT_CALC_ID
                 , DIC_FIXED_COSTPRICE_DESCR_ID
                 , ARS_SEQUENCE
                 , ARS_RATE
                 , FAL_ADV_RATE_STRUCT1_ID
                 , ARS_PRF_LEVEL
                 , A_DATECRE
                 , A_IDCRE
                 , DIC_FAL_RATE_DESCR_ID
                 , ARS_RATE_PROC
                 , ARS_DEFAULT_PRF
                 , C_COSTPRICE_STATUS
                 , PC_COLORS_ID
                  )
           values (aNewId
                 , aCurFalAdvRateStruct.C_RUBRIC_TYPE
                 , aCurFalAdvRateStruct.C_BASIS_RUBRIC
                 , aCurFalAdvRateStruct.C_COST_ELEMENT_TYPE
                 , aNewStructureId
                 , aCurFalAdvRateStruct.DIC_FIXED_COSTPRICE_DESCR_ID
                 , aCurFalAdvRateStruct.ARS_SEQUENCE
                 , aCurFalAdvRateStruct.ARS_RATE
                 , aNewFAL_ADV_RATE_STRUCT1_ID
                 , aCurFalAdvRateStruct.ARS_PRF_LEVEL
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERIni
                 , aCurFalAdvRateStruct.DIC_FAL_RATE_DESCR_ID
                 , aCurFalAdvRateStruct.ARS_RATE_PROC
                 , aCurFalAdvRateStruct.ARS_DEFAULT_PRF
                 , aCurFalAdvRateStruct.C_COSTPRICE_STATUS
                 , aCurFalAdvRateStruct.PC_COLORS_ID
                  );

      return aNewID;
    end DuplicateRubric;

    /* Dupplication d'une rubrique */
    procedure DuplicateSequencesForTotal(
      aCurFalAdvTotalRate        CUR_FAL_ADV_TOTAL_RATE%rowtype
    , aNewFAL_ADV_STRUCT_CALC_ID FAL_ADV_STRUCT_CALC.FAL_ADV_STRUCT_CALC_ID%type
    , aNewFAL_ADV_RATE_STRUCT_ID FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type
    )
    is
      aNewFAL_FAL_ADV_RATE_STRUCT_ID number;
    begin
      -- récupération de l'ID de la rubrique de même séquence que celle de la structure copiée
      begin
        select FAL_ADV_RATE_STRUCT_ID
          into aNewFAL_FAL_ADV_RATE_STRUCT_ID
          from FAL_ADV_RATE_STRUCT
         where ARS_SEQUENCE = aCurFalAdvTotalRate.ARS_SEQUENCE
           and FAL_ADV_STRUCT_CALC_ID = aNewFAL_ADV_STRUCT_CALC_ID;
      exception
        when no_data_found then
          aNewFAL_FAL_ADV_RATE_STRUCT_ID  := null;
      end;

      -- Insertion du nouvel ID.
      insert into FAL_ADV_TOTAL_RATE
                  (FAL_ADV_TOTAL_RATE_ID
                 , FAL_ADV_RATE_STRUCT_ID
                 , FAL_FAL_ADV_RATE_STRUCT_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , aNewFAL_ADV_RATE_STRUCT_ID
                 , aNewFAL_FAL_ADV_RATE_STRUCT_ID
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERIni
                  );
    end DuplicateSequencesForTotal;
  begin
    -- Dupplication Structure
    aNewStructureID  := DuplicateADVStructure;

    -- Dupplication des rubriques
    for CurFalAdvRateStruct in CUR_FAL_ADV_RATE_STRUCT loop
      -- Dupplication d'une rubrique
      aNewRubricId  := DuplicateRubric(aNewStructureId, CurFalAdvRateStruct);

      -- Dupplication de ses éventuelles séquence pour total
      for CurFalAdvTotalRate in CUR_FAL_ADV_TOTAL_RATE(CurFalAdvRateStruct.FAL_ADV_RATE_STRUCT_ID) loop
        DuplicateSequencesForTotal(CurFalAdvTotalRate, aNewStructureId, aNewRubricId);
      end loop;
    end loop;
  end DuplicateADVCalculationStruct;

  /**
  * function ExistDefaultStructure
  *
  * Description
  *   Indique l'existance ou pas d'une structure par défaut du type donné
  *   (Standard ou Compta indus), différente de celle passée en paramètre)
  * @author  Emmanuel Cassis
  * @version 24.08.2004
  * @public
  * @param   aFAL_ADV_STRUCT_CALC_ID : Structure courante.
  * @param   aASC_MANUFACTURE_ACCOUNTING : Structure de compta indus.
  */
  function ExistDefaultStructure(aFAL_ADV_STRUCT_CALC_ID number, aASC_MANUFACTURE_ACCOUNTING integer default 0)
    return integer
  is
    aResult integer;
  begin
    select 1
      into aResult
      from FAL_ADV_STRUCT_CALC AST
     where AST.FAL_ADV_STRUCT_CALC_ID <> aFAL_ADV_STRUCT_CALC_ID
       and AST.ASC_DEFAULT_STRUCT = 1
       and AST.ASC_MANUFACTURE_ACCOUNTING = aASC_MANUFACTURE_ACCOUNTING;

    return aresult;
  exception
    when others then
      return 0;
  end;
end FAL_CALC_STRUCTURE_FUNCTIONS;
