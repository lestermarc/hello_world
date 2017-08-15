--------------------------------------------------------
--  DDL for Package Body HRM_STRUCTURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_STRUCTURE" 
AS
/**
 * Package regroupant des fonctions utilisées par la gestion des genres salaires et
 * par l'outil de migration
 *
 * @version 1.0
 * @date 01.2000
 * @author JS
 * @author SPF
 */

  TYPE PrefixesTabType IS TABLE OF
    hrm_elements_prefixes.elp_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE SuffixesTabType iS TABLE OF
    hrm_elements_suffixes.hrm_elements_suffixes_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE RootTabType IS TABLE OF
    hrm_elements_root.c_root_type%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE VariantTabType IS TABLE OF
    hrm_elements_root.c_root_variant%TYPE
    INDEX BY BINARY_INTEGER;

  gtt_prefixes PrefixesTabType;
  gtt_suffixes SuffixesTabType;
  gtt_root_type RootTabType;
  gtt_variant_type VariantTabType;

/**
 * Preparing prefixes
 */
procedure p_LoadPrefixes is
begin
  if (gtt_prefixes.COUNT = 0) then
    select Upper(elp_code) bulk collect into gtt_prefixes
    from hrm_elements_prefixes
    order by Substr(elp_code,1,2) asc, Length(elp_code) desc;
  end if;
end;

/**
 * Preparing suffixes
 */
procedure p_LoadSuffixes is
begin
  if (gtt_suffixes.COUNT = 0) then
    select hrm_elements_suffixes_id bulk collect into gtt_suffixes
    from hrm_elements_suffixes
    where Upper(hrm_elements_suffixes_id) <> 'NONE'
    order by Length(hrm_elements_suffixes_id) desc, Substr(hrm_elements_suffixes_id,1,2) asc;
  end if;
end;


procedure deactivateRoot(vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
is
begin
  for tplRoots in (
      select a.hrm_elements_id, b.elp_is_const
      from
        hrm_elements_family a,
        hrm_elements_prefixes b
      where
        hrm_elements_root_id = vRootId and
        a.hrm_elements_prefixes_id = b.hrm_elements_prefixes_id
      order by a.hrm_elements_prefixes_id Desc)
  loop
    if (tplRoots.elp_is_const = 1) then
      delete hrm_constants where hrm_constants_id = tplRoots.hrm_elements_id;
    else
      delete hrm_elements where hrm_elements_id = tplRoots.hrm_elements_id;
    end if;
    delete hrm_formulas_structure where main_id = tplRoots.hrm_elements_id;
    delete hrm_formulas_structure where related_id = tplRoots.hrm_elements_id;
    -- Suppression de l'élément dans la structure de ventilation
    delete hrm_break_structure where bre_item_id = tplRoots.hrm_elements_id;
    -- Suppression de l'affectation de l'élément aux décomptes
    delete hrm_salary_sheet_elements where hrm_elements_id = tplRoots.hrm_elements_id;
  end loop;

  -- Mise à jour de la famille
  update hrm_elements_family set hrm_elements_id = null
  where hrm_elements_root_id = vRootId;
  -- Mise à jour de la racine
  update hrm_elements_root set elr_is_active = 0
  where hrm_elements_root_id = vRootId;

  exception
    when OTHERS then
      rollback;
      raise;
end;

procedure deleteRoot(vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
is
begin
  for tplRoots in (
      select a.hrm_elements_id, b.elp_is_const
      from hrm_elements_family a, hrm_elements_prefixes b
      where hrm_elements_root_id = vRootId and
        a.hrm_elements_prefixes_id = b.hrm_elements_prefixes_id
      order by a.hrm_elements_prefixes_id desc)
  loop
    if (tplRoots.elp_is_const = 1) then
      delete hrm_constants where hrm_constants_id = tplRoots.hrm_elements_id;
    else
      delete hrm_elements where hrm_elements_id = tplRoots.hrm_elements_id;
    end if;
    -- Suppression des éléments constitutifs de la famille
    delete hrm_elements_family
    where hrm_elements_root_id = vRootId and hrm_elements_id = tplRoots.hrm_elements_id;
    -- Suppression de l'élément dans la structure de ventilation
    delete hrm_break_structure where bre_item_id = tplRoots.hrm_elements_id;
    -- Suppression de l'élément dans la structure de calcul
    delete hrm_formulas_structure where main_id = tplRoots.hrm_elements_id;
    -- Suppression de l'affectation de l'élément aux décomptes
    delete hrm_salary_sheet_elements where hrm_elements_id = tplRoots.hrm_elements_id;
  end loop;
  -- Suppression de la famille
  delete hrm_elements_root where hrm_elements_root_id = vRootId;

  exception
    when OTHERS then
      rollback;
      raise;
end;

procedure deleteElem(vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE,
  vElemId IN hrm_elements.hrm_elements_id%TYPE,
  vDeleted OUT INTEGER)
is
begin
  select Sum(Counted) into vDeleted
  from (
    -- Utilisé par d'autre éléments de calcul
    select Count(*) AS COUNTED
    from hrm_elements_root C, hrm_elements_family B,
         hrm_formulas_Structure A
    where a.related_id = vElemId and b.hrm_elements_id = a.main_id and
          b.hrm_elements_root_id <> vRootId and
          c.hrm_elements_root_id = b.hrm_elements_root_id and
          c.c_root_variant <> 'Base'
    union all
    -- Utilisation par des employés
    select Count(*) AS COUNTED
    from hrm_employee_elements
    where hrm_elements_id = vElemId
    union all
    select Count(*) AS COUNTED
    from hrm_employee_const
    where hrm_constants_id = vElemId
    union all
    -- Historique calculé
    select Count(*) AS COUNTED
    from hrm_history_detail
    where hrm_elements_id = vElemId
    union all
    -- Constante entreprise renseignée
    select Count(*) AS COUNTED
    from hrm_company_elements
    where hrm_elements_id = vElemId
  );

  if (vDeleted = 0) then
    delete from Hrm_Elements_Family where Hrm_Elements_Id = vElemId;
    delete from Hrm_Formulas_Structure where Main_ID = vElemId;
    delete from Hrm_Formulas_Structure where Related_ID = vElemId;
    delete from Hrm_Break_Structure where bre_item_id = vElemId;
    delete from Hrm_Salary_Sheet_Elements where Hrm_Elements_Id = vElemId;
    delete from Hrm_Elements where Hrm_Elements_ID = vElemId;
    delete from Hrm_Constants where Hrm_Constants_ID = vElemId;
  end if;
end;

-- Lock a root record
procedure LockRoot(vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
is
  dummy VARCHAR2(1);
begin
  select 'x' into dummy from hrm_elements_root
  where hrm_elements_root_id = vRootId
  for update nowait;

  exception
    when TIMEOUT_ON_RESOURCE then
      raise_application_error(-20000, 'This root is locked by another user');
    when NO_DATA_FOUND then
      raise_application_error(-20000, 'This root has been deleted by another user');
end;

function getRootId return hrm_elements_root.hrm_elements_root_id%TYPE
is
  result hrm_elements_root.hrm_elements_root_id%TYPE;
begin
  select Nvl(Max(hrm_elements_root_id),0)+1 into result
  from hrm_elements_root;
  return result;
end;

function elementFirstPriority(
  vElemId IN hrm_elements.hrm_elements_id%TYPE,
  vCode IN hrm_elements.ele_code%TYPE)
  return hrm_elements.hrm_elements_id%TYPE
is
  code1 VARCHAR2(2000);
  code2 VARCHAR2(2000);
  result hrm_elements.hrm_elements_id%TYPE;
begin
  code1 := Upper(Substr(vCode,2,Length(vCode)-1));
  code2 := Upper(Substr(vCode,2,Length(vCode)-7));
  select distinct related_id into result
  from (select related_id, main_id, related_code, Upper(related_code) rel_code
        from hrm_formulas_structure)
  where related_code like 'em%' and rel_code in (code1, code2)
  start with main_Id =  vElemId
  connect by prior related_id = main_id and level < 3;
  return result;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function elementSecondPriority(
  vElemId IN hrm_elements.hrm_elements_id%TYPE,
  vCode IN hrm_elements.ele_code%TYPE)
  return hrm_elements.hrm_elements_id%TYPE
is
  code1 VARCHAR2(2000);
  code2 VARCHAR2(2000);
  result hrm_elements.hrm_elements_id%TYPE;
begin
  code1 := Upper(Substr(vCode,2,Length(vCode)-1));
  code2 := Upper(Substr(vCode,2,Length(vCode)-7));
  select distinct related_id into result
  from (select related_id, main_id, related_code,
          Upper(Substr(related_code,4,Length(related_code)-3)) rel_code
        from hrm_formulas_structure)
  where related_code like 'Con%' and rel_code in (code1, code2)
  start with main_id = vElemId
  connect by prior related_id = main_id and level < 3;
  return result;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function isBaseElement(vElemId IN hrm_elements.hrm_elements_id%TYPE)
  return INTEGER
is
  result INTEGER;
begin
  select Count(*) into result from dual
  where Exists(select 1 from hrm_formulas_structure
               where Upper(related_code) like 'CEMSOUM%' or Upper(related_code) like 'CEMBAS%'
               start with main_id = vElemId and relation_type = 0
               connect by prior related_id = main_id and level < 3 and
                          prior relation_type = relation_type);

  return result;
end;

function isBaseRoot(vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return INTEGER
is
  result INTEGER;
begin
  select Count(*) into result from dual
  where Exists(select 1 from hrm_elements_root
               where hrm_elements_root_id = vRootId and c_root_variant = 'Base');

  return result;
end;

function elementRoot(vCode IN hrm_elements.ele_code%TYPE)
  return VARCHAR2
is
  tmp  hrm_elements.ele_code%TYPE := null;
  tmp2 hrm_elements.ele_code%TYPE := null;
  len BINARY_INTEGER;
begin
  p_LoadPrefixes;
  p_LoadSuffixes;
  -- we look for prefixes into code
  for cpt in gtt_prefixes.FIRST..gtt_prefixes.LAST loop
    len := Length(gtt_prefixes(cpt));
    -- if this prefix is used we fill tmp with code stripping prefix
    if Upper(Substr(vCode,1,len)) = gtt_prefixes(cpt) then
      tmp := Substr(vCode, len+1);
      Exit;
    end if;
  end loop;
  -- we look for suffixes into code
  for cpt in gtt_suffixes.FIRST..gtt_suffixes.LAST loop
    len := Instr(Upper(tmp), gtt_suffixes(cpt));
    -- if this suffix is used we fill tmp2 with tmp, stripping suffix
    if (len > 0) and ((len+Length(gtt_suffixes(cpt))-1) = Length(tmp)) then
      tmp2 := Substr(tmp,1,len-1);
      Exit;
    end if;
  end loop;

  -- if we found suffixes we send back tmp2 otherwise we send back tmp
  return Nvl(tmp2, tmp);

  exception
    when OTHERS then
      return '';
end;

function elementPrefix(vCode IN hrm_elements.ele_code%TYPE)
  return VARCHAR2
is
  len BINARY_INTEGER;
begin
  p_LoadPrefixes;
  -- we look for prefixes into code
  for cpt in gtt_prefixes.FIRST..gtt_prefixes.LAST loop
    len := Length(gtt_prefixes(cpt));
    -- if this prefix is used we fill Result with code stripping prefix
    if (Upper(Substr(vCode, 1, len)) = gtt_prefixes(cpt)) then
      return gtt_prefixes(cpt);
    end if;
  end loop;

  return '';
end;

function elementSuffix(vCode IN hrm_elements.ele_code%TYPE)
  return VARCHAR2
is
  len BINARY_INTEGER;
begin
  p_LoadSuffixes;
  -- we look for prefixes into code
  for cpt in gtt_suffixes.FIRST..gtt_suffixes.LAST loop
    len := Length(gtt_suffixes(cpt));
    -- if this prefix is used we fill Result with code stripping suffix starting at the end
    if (Upper(Substr(vCode, -len)) = gtt_suffixes(cpt)) then
      return gtt_suffixes(cpt);
    end if;
  end loop;

  return 'NONE';
end;

function formulaTab(vCode IN hrm_elements.ele_code%TYPE)
  return VARCHAR2
is
  strTab hrm_elements.ele_code%TYPE;
begin
  strTab := Substr(vCode, 1, Instr(vCode,'!')-1);
  return case
    when (Upper(strTab) in ('CONSTENT','VARCOL','CUMCOL','CONSTCOL','VARCAL')) then strTab
    else null
    end;
end;

function formulaColumn(vCode IN hrm_elements.ele_code%TYPE)
  return VARCHAR2
is
  code hrm_elements.ele_code%TYPE;
  col VARCHAR2(1);
  result VARCHAR2(10);
begin
  code := Upper(Substr(vCode, Instr(vCode,'!')+1));
  for cpt in 1..Length(code) loop
    col := Substr(code, cpt, 1);
    if (col >= 'A' and col <= 'Z') then
      result := result||col;
    elsif (col <> '$') then
      Exit;
    end if;
  end loop;

  return result;

  exception
    when OTHERS then
      return '';
end;

function formulaRow(vCode IN hrm_elements.ele_code%TYPE)
  return INTEGER
is
  code hrm_elements.ele_code%type;
  col VARCHAR2(1);
  result VARCHAR2(10);
begin
  code := Substr(vCode, Instr(vCode,'!')+1);
  for cpt in Length(code)..1 loop
    col := Substr(code, cpt, 1);
    Exit when (col < '0' or col > '9');
    result := col||result;
  end loop;

  return case
    when result is not null then to_number(result)
    else -1
    end;

  exception
    when OTHERS then
      return -1;
end;

function getElementId(vCode IN hrm_elements.ele_code%TYPE)
  return hrm_elements.hrm_elements_id%TYPE
is
  Result hrm_elements.hrm_elements_id%TYPE;
begin
  SELECT elemid into Result
  FROM (
    SELECT elemid
    FROM (select Upper(ele_code) code, hrm_elements_id elemid from hrm_elements)
    WHERE code = Upper(vCode)
    UNION ALL
    SELECT elemid
    FROM (select Upper(con_code) code, hrm_constants_id elemid from hrm_constants)
    WHERE code = Upper(vCode)
  );
  return Result;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function isValidCode(vCode IN hrm_elements.ele_code%TYPE,
  vRoot IN hrm_elements_root.elr_root_name%TYPE)
  return INTEGER
is
  strCode hrm_elements.ele_code%type;
  len BINARY_INTEGER;
begin
  -- have we got a prefix
  strCode := elementPrefix(vCode);
  -- if we do we calculate if the length of the prefix + the length of the root
  -- exceeds the length of the code. If it does we may well have a suffix
  if (strCode is not null) then
    len := Length(vCode) - (Length(vRoot)+Length(strCode));
    -- if the length is greater we search for a valid suffix if we don't find
    -- one we return 0
    -- if the length is 0 then we don't have a prefix and we retun 1 (ok)
    if (len > 0) then
      strCode := elementSuffix(vCode);
      return case
        when (strCode = 'NONE') then 0
        when (Upper(Substr(vCode, -(Length(vRoot)+Length(strCode)),Length(vRoot))) like Upper(vRoot)) then 1
        else 0
        end;
    else
      return case
        when (Upper(Substr(vCode, Length(strCode)+1)) like Upper(vRoot)) then 1
        else 0
        end;
    end if;
  end if;
  -- if prefix is null the suffix might be ok but we return 0
  return 0;
end;

procedure updateRootType(vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
is
  isSum      NUMBER(1) := 0;
  isFeedBack NUMBER(1) := 0;
  isConstEnt NUMBER(1) := 0;
  isCem      BINARY_INTEGER := 0;
  inputType  BINARY_INTEGER := 0;
  rType hrm_elements_root.c_root_type%TYPE := '';
  rVariant hrm_elements_root.c_root_variant%TYPE := '';
begin
  -- Type de GS
  if (gtt_root_type.COUNT = 0) then
    gtt_root_type(1) := 'Input';
    gtt_root_type(2) := 'Calculated';
    gtt_root_type(3) := 'Service';
  end if;

  -- Variante de GS
  if (gtt_variant_type.COUNT = 0) then
    gtt_variant_type(1) := 'Const';
    gtt_variant_type(2):= 'Var';
    gtt_variant_type(3):= 'VarConst';
    gtt_variant_type(4) := 'ConstEnt';
    gtt_variant_type(5) := 'Base';
    gtt_variant_type(6) := 'DLL';
    gtt_variant_type(7) := 'Formula';
    gtt_variant_type(8) := 'Print';
    gtt_variant_type(9):= 'Text';
    gtt_variant_type(10) := 'Other';
    gtt_variant_type(11):= 'SQL';
  end if;

  for tplFamily in (
      select hrm_elements_prefixes_id, elf_sql
      from hrm_elements_family
      where hrm_elements_root_id = vRootId and hrm_elements_suffixes_id = 'NONE'
      order by elf_is_reference)
  loop
    if (tplFamily.hrm_elements_prefixes_id = 'OUTCUMCEM') then
      isSum := 1;
    elsif (tplFamily.hrm_elements_prefixes_id = 'OUTCONEM') then
      isFeedBack := 1;
    elsif (tplFamily.hrm_elements_prefixes_id IN ('GM','GT')) then
      isConstEnt := 1;
    elsif (tplFamily.hrm_elements_prefixes_id = 'EM') then
      inputType := inputType + 2;
    elsif (tplFamily.hrm_elements_prefixes_id = 'CONEM') then
      inputType := inputType + 1;
    elsif (tplFamily.hrm_elements_prefixes_id = 'DIV') then
      if (tplFamily.elf_Sql is null) then
        rType := gtt_root_type(3);
        rVariant := gtt_variant_type(9);
      end if;
    elsif (tplFamily.hrm_elements_prefixes_id = 'CEM') then
        isCem := 1;
    elsif (tplFamily.hrm_elements_prefixes_id = 'PRINT') then
      rType := gtt_root_type(3);
      rVariant := gtt_variant_type(8);
    elsif (tplFamily.hrm_elements_prefixes_id = 'TXT') then
      rType := gtt_root_type(3);
      rVariant := gtt_variant_type(9);
    end if;
    if (tplFamily.elf_sql is not null) then
      rType := gtt_root_type(2);
      rVariant := gtt_variant_type(6);
    end if;
  end loop;
  if (inputType != 0) and (rType is null) then
    rType := gtt_root_type(1);
    rVariant := gtt_variant_type(inputType);
  else
    if (isConstEnt = 1) and (isSum = 0) then
      rType := gtt_root_type(1);
      rVariant := gtt_variant_type(4);
      isConstEnt := 0;
    elsif (isCem = 1) then
      rType := gtt_root_type(2);
      if (isBaseRoot(vRootId) = 1) then
        rVariant := gtt_variant_type(5);
      elsif (rVariant is null) then
        rVariant := gtt_variant_type(7);
      end if;
    end if;
  end if;

  update hrm_elements_root
    set c_root_type = rType,
        c_root_variant= rVariant,
        elr_uses_sums = isSum,
        elr_uses_feedBack = isFeedBack,
        elr_uses_constent = isConstEnt
  where hrm_elements_root_id = vRootId;

  exception
    when OTHERS then
      raise_application_error(-20200, 'erreur pendant la mise à jour du type du GS: '||to_char(vRootId));
end;

function isRounded(vFormula IN hrm_elements_family.elf_expression%TYPE)
  return INTEGER
is
begin
  return case
    when instr(vFormula,'+0.5') > 0 then 1
    else 0
    end;
end;

function elementSign(vFormula IN hrm_elements_family.elf_expression%TYPE)
  return VARCHAR2
is
  nPos BINARY_INTEGER;
begin
  nPos := instr(vFormula,'-');
  if (nPos > 2) then
    nPos := instr(vFormula,',-');
  end if;

  return case
    when (nPos > 0) then '-'
    else '+'
    end;
end;

function get_NumberRootUsedByHistory(
  vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return INTEGER
is
  Result INTEGER;
begin
  select Count(*) into result
  from hrm_history_detail
  where hrm_elements_id in (select hrm_elements_id from hrm_elements_family
                            where hrm_elements_root_id = vRootId);

  return Result;
end;

function get_NumberRootUsedBySheetEmpl(
  vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE,
  vSheetId IN hrm_salary_sheet.hrm_salary_sheet_id%TYPE)
  return INTEGER
is
  Result INTEGER;
begin
  select Count(e.hrm_employee_id) into Result
  from
    (select hrm_employee_id, hrm_elements_id
     from hrm_employee_elements
     union all
     select hrm_employee_id, hrm_constants_id
     from hrm_employee_const) e,
    hrm_salary_sheet_elements sse,
    hrm_elements_family f
  where f.hrm_elements_root_id = vRootId and
    sse.hrm_salary_sheet_id = vSheetId and
    sse.hrm_elements_id = f.hrm_elements_id and
    e.hrm_elements_id = sse.hrm_elements_id;

  return Result;
end;

function get_NumberRootUsedByElements(
  vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return INTEGER
is
  Result INTEGER;
begin
  select Count(*) into Result
  from
    hrm_elements_root C,
    hrm_elements_family B,
    hrm_formulas_Structure A,
    hrm_elements_family F
  where
    F.hrm_elements_root_id = vRootId and
    a.related_id = F.hrm_elements_id and
    b.hrm_elements_id = a.main_id and
    b.hrm_elements_root_id <> vRootId and
    c.hrm_elements_root_id = b.hrm_elements_root_id and
    c.c_root_variant <> 'Base';

  return Result;
end;

function get_NumberRootUsedByEmployee(
  vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return INTEGER
is
  Result INTEGER;
begin
  select Count(distinct hrm_employee_id) into Result
  from (
    select hrm_employee_id, hrm_elements_id
    from hrm_employee_elements
    union
    select hrm_employee_id, hrm_constants_id
    from hrm_employee_const) e,
    hrm_elements_family f
  where
    f.hrm_elements_root_id = vRootId and
    e.hrm_elements_id = f.hrm_elements_id;

  return Result;
end;

function get_NumberRootUsedByConstEnt(
  vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return INTEGER
is
  Result INTEGER;
begin
  select Count(*) into Result
  from hrm_company_elements
  where hrm_elements_id in (select hrm_elements_id from hrm_elements_family
                            where hrm_elements_root_id = vRootId);

  return Result;
end;

function get_NumberRootUsedByFinRef(
  vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return INTEGER
is
  Result INTEGER;
begin
  select Count(*) into Result
  from hrm_financial_ref
  where hrm_elements_id in (select hrm_elements_id from hrm_elements_family
                            where hrm_elements_root_id = vRootId);

  return Result;
end;

function get_NumberSheetUsedByHistory(
  vSheetId IN hrm_salary_sheet.hrm_salary_sheet_id%TYPE)
  return INTEGER
is
  Result INTEGER;
begin
  select Count(*) into Result
  from hrm_history_detail
  where hrm_salary_sheet_id = vSheetId;

  return Result;
end;

function get_NumberSheetUsedByEmployee(
  vSheetId IN hrm_salary_sheet.hrm_salary_sheet_id%TYPE)
  return INTEGER
is
  Result INTEGER;
begin
  select Count(distinct hrm_employee_id) into Result
  from (
    select hrm_employee_id, hrm_elements_id
    from hrm_employee_elements
    union
    select hrm_employee_id, hrm_constants_id
    from hrm_employee_const) e,
    hrm_salary_sheet_elements sse
  where
    sse.hrm_salary_sheet_id = vSheetId and
    e.hrm_elements_id = sse.hrm_elements_id;

  return Result;
end;

function Get_NumberEmployeeUsedByTax(vTax IN VARCHAR2) return INTEGER
is
  TaxName VARCHAR2(2);
  Result INTEGER;
begin
  TaxName := case
    when (Length(vTax) > 2) then Substr(vTax, 0, 2)
    else vTax
    end;

  select Count(ec.hrm_employee_id) into Result
  from
    hrm_employee_const ec,
    (select hrm_code_table_id, Substr(cod_code,0,2) code from hrm_code_table) t
  where t.code = TaxName and ec.hrm_code_table_id = t.hrm_code_table_id;

  return Result;
end;

function get_InputCalculatedMode(
  vElemId IN hrm_elements.hrm_elements_id%TYPE,
  vCode IN hrm_elements.ele_code%TYPE)
  return INTEGER
is
  auto NUMBER := 0;
begin
  select case when IS_AUTO = 0 then 1 else 0 end into auto
  from (
    select Max(ROWNUM) - Sum(IS_AUTO) AS IS_AUTO
    from (
      select case when (hrm_structure.elementRoot(related_code)=vCode) then 1 else 0 end AS IS_AUTO
      from hrm_formulas_structure
      where main_id = vElemId
    )
  );

  return auto;
end;

procedure set_InputPriority(
  vElemId IN hrm_elements.hrm_elements_id%TYPE,
  vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
is
begin
  for tplPriority in (
      select rownum, prefix, suffix
      from (
        select f.hrm_elements_prefixes_id prefix, f.hrm_elements_suffixes_id suffix
        from hrm_formulas_structure a, hrm_elements_family f
        where a.main_id = vElemId and f.hrm_elements_root_id = vRootId and
          f.hrm_elements_id = a.related_id
        order by a.rank))
  loop
    update hrm_elements_family
      set elf_priority = tplPriority.ROWNUM
    where
      hrm_elements_root_id = vRootId and
      hrm_elements_prefixes_id = tplPriority.prefix and
      hrm_elements_suffixes_id = tplPriority.suffix;
  end loop;
end;

procedure update_InputPriority
is
begin
  for tplRoots in (
      select hrm_elements_root_id, hrm_elements_id
      from hrm_elements_root
      where elr_input_type is not null)
  loop
    set_InputPriority(tplRoots.hrm_elements_id, tplRoots.hrm_elements_root_id);
  end loop;

  exception
    when OTHERS then
      rollback;
      raise_application_error(-20201,'problem in updating priorities, process has been canceled');
end;

function get_ExtElemNumber(
  vElemId IN hrm_elements.hrm_elements_id%TYPE,
  vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return INTEGER
is
  Result INTEGER;
begin
  select Count(*) into Result
  from hrm_formulas_structure a, hrm_elements_family b
  where a.main_id = vElemId and b.hrm_elements_id = a.related_id and
    b.hrm_Elements_root_id <> vRootId;

  return Result;
end;

function isRootUsedbySS(
  vSheetId IN hrm_salary_sheet.hrm_salary_sheet_id%TYPE,
  vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return INTEGER
is
  Result INTEGER;
begin
  select Count(*) into Result
  from hrm_salary_sheet_elements c, hrm_elements_family b
  where b.hrm_elements_root_id = vRootId and
    c.hrm_elements_id = b.hrm_elements_id and
    c.hrm_salary_sheet_id = vSheetId;
  return Result;
end;

procedure AssignConstRootToSheet(
  vSheetId IN hrm_salary_sheet.hrm_salary_sheet_id%TYPE)
is
begin
  insert into hrm_salary_sheet_elements
  (hrm_salary_sheet_id, hrm_elements_id)
  (select vSheetId, c.hrm_constants_id
   from hrm_constants c
   where c.c_hrm_sal_const_type = '2' and
     not exists (select sse.hrm_elements_id
                 from hrm_salary_sheet_elements sse
                 where sse.hrm_salary_sheet_id = vSheetId and
                   sse.hrm_elements_id = c.hrm_constants_id));

  exception
    when OTHERS then
      rollback;
      raise_application_error(-20202,'Unable to assign all submission constants to salary sheet');
end;

procedure AssignConstRootToSheets
is
begin
  for tplSheets in (select hrm_salary_sheet_id from hrm_salary_sheet) loop
    AssignConstRootToSheet(tplSheets.hrm_salary_sheet_id);
  end loop;

  exception
    when OTHERS then
      rollback;
      raise_application_error(-20203,'Unable to assign all submission constants to all salary sheets');
end;

procedure InsertConstRootToSheets(
  vRootId IN hrm_elements_root.hrm_elements_root_id%TYPE)
is
begin
  for tplFamily in (
    select f.hrm_elements_id
    from hrm_elements_prefixes p, hrm_elements_family f
    where f.hrm_elements_root_id = vRootId and
      p.hrm_elements_prefixes_id = f.hrm_elements_prefixes_id and
      (p.elp_is_const = 1 or p.elp_is_var = 1))
  loop
    for tplSheet in (select hrm_salary_sheet_id from hrm_salary_sheet) loop
      -- Assignation de la constante au décompte
      insert into hrm_salary_sheet_elements
      (hrm_salary_sheet_id, hrm_elements_id)
      values
      (tplSheet.hrm_salary_sheet_id, tplFamily.hrm_elements_id);
    end loop;
  end loop;

  exception
    when OTHERS then
      rollback;
      raise_application_error(-20204,'Unable to assign root constant to all salary sheets');
end;

function RemoveInvalidSheetElements return INTEGER is
begin
  delete hrm_salary_sheet_elements ss
  where not Exists(select 1 from v_hrm_elements_short
                   where elemid = SS.hrm_elements_id);
  return SQL%ROWCOUNT;
end;
function RemoveInvalidSheetElements(Id IN hrm_elements.hrm_elements_id%TYPE) return INTEGER is
begin
  delete hrm_salary_sheet_elements ss
  where hrm_elements_id = Id and
    not Exists(select 1 from v_hrm_elements_short
               where elemid = SS.hrm_elements_id);
  return SQL%ROWCOUNT;
end;

function RemoveInvalidControlElements return INTEGER is
begin
  delete hrm_control_elements ce
  where not Exists(select 1 from v_hrm_elements_short
                   where elemid = ce.hrm_control_elements_id);
  return SQL%ROWCOUNT;
end;
function RemoveInvalidControlElements(Id IN hrm_elements.hrm_elements_id%TYPE) return INTEGER is
begin
  delete hrm_control_elements ce
  where hrm_control_elements_id = Id and
    not Exists(select 1 from v_hrm_elements_short
               where elemid = ce.hrm_control_elements_id);
  return SQL%ROWCOUNT;
end;

END HRM_STRUCTURE;
