--------------------------------------------------------
--  DDL for Package Body WEB_STRUCTURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_STRUCTURE" 
IS

function GetMaxChildLevel(vParentSign in web_categ_array.wca_signature%type) return number
is
  tmp number;
begin
  select max(w.wca_level) into tmp
  from web_categ_array w
  where (wca_signature = vParentSign or wca_signature like vParentSign||'-%');
  return tmp;
  exception
    when others then return 0;
end GetMaxChildLevel;

function GetCategArrayID(vSignature in web_categ_array.wca_signature%type) return number
is
  tmp number;
begin
  select web_categ_array_id into tmp
  from web_categ_array
  where wca_signature = vSignature;
  if tmp > 0 then
    return tmp;
  else
    return 0;
  end if;
  exception
    when others then return 0;
end GetCategArrayId;

procedure UpdateParentId(vCategArrayId in web_categ_array.web_categ_array_id%type)
is
  vL1 number; vL2 number; vL3 number; vL4 number; vL5 number;
  vP1 number; vP2 number; vP3 number; vP4 number;
  vActive number;
begin
  -- Recherche des infos du noeud
  select web_categ_id_level1,web_categ_id_level2,web_categ_id_level3, web_categ_id_level4,
    web_categ_id_level5, wca_is_active
  into vL1, vL2, vL3, vL4, vL5, vActive
  from web_categ_array
  where web_categ_array_id = vCategArrayId;

  -- Création des parents manquants
  if vL2 is not null then
    vP1 := GetCategArrayId(vL1);
    if vP1 = 0 then
      select Init_id_seq.NextVal into vP1 from dual;
      INSERT INTO WEB_CATEG_ARRAY(WEB_CATEG_ARRAY_ID, WCA_IS_ACTIVE, WEB_CATEG_ID_LEVEL1, A_DATECRE, A_IDCRE)
      VALUES(vP1, vActive, vL1, SysDate, 'PCS');
    end if;

    if vL3 is not null then
      vP2 := GetCategArrayId(vL1||'-'||vL2);
      if vP2 = 0 then
        select Init_id_seq.NextVal into vP2 from dual;
        INSERT INTO WEB_CATEG_ARRAY(WEB_CATEG_ARRAY_ID, WCA_IS_ACTIVE, WEB_CATEG_ID_LEVEL1,
          WEB_CATEG_ID_LEVEL2, WEB_CATEG_ARRAY_ID_PARENT1, A_DATECRE, A_IDCRE)
        VALUES(vP2, vActive, vL1, vL2, vP1, SysDate, 'PCS');
      end if;

      if vL4 is not null then
        vP3 := GetCategArrayId(vL1||'-'||vL2||'-'||vL3);
        if vP3 = 0 then
          select Init_id_seq.NextVal into vP3 from dual;
          INSERT INTO WEB_CATEG_ARRAY(WEB_CATEG_ARRAY_ID, WCA_IS_ACTIVE, WEB_CATEG_ID_LEVEL1,
            WEB_CATEG_ID_LEVEL2, WEB_CATEG_ID_LEVEL3,
            WEB_CATEG_ARRAY_ID_PARENT1, WEB_CATEG_ARRAY_ID_PARENT2, A_DATECRE, A_IDCRE)
          VALUES(vP3, vActive, vL1, vL2, vL3, vP1, vP2, SysDate, 'PCS');
        end if;

        if vL5 is not null then
          vP4 := GetCategArrayId(vL1||'-'||vL2||'-'||vL3||'-'||vL4);
          if vP4 = 0 then
            select Init_id_seq.NextVal into vP4 from dual;
            INSERT INTO WEB_CATEG_ARRAY(WEB_CATEG_ARRAY_ID, WCA_IS_ACTIVE, WEB_CATEG_ID_LEVEL1,
              WEB_CATEG_ID_LEVEL2, WEB_CATEG_ID_LEVEL3, WEB_CATEG_ID_LEVEL4,
              WEB_CATEG_ARRAY_ID_PARENT1, WEB_CATEG_ARRAY_ID_PARENT2, WEB_CATEG_ARRAY_ID_PARENT3,
              A_DATECRE, A_IDCRE)
            VALUES(vP4, vActive, vL1, vL2, vL3, vL4, vP1, vP2, vP3, SysDate, 'PCS');
          end if;
        end if;
      end if;
    end if;
  end if;

  -- Mise à jour des liens
  UPDATE WEB_CATEG_ARRAY
  SET WEB_CATEG_ARRAY_ID_PARENT1 = vP1,
      WEB_CATEG_ARRAY_ID_PARENT2 = vP2,
      WEB_CATEG_ARRAY_ID_PARENT3 = vP3,
      WEB_CATEG_ARRAY_ID_PARENT4 = vP4
  WHERE WEB_CATEG_ARRAY_ID = vCategArrayId;

  exception
  when others then
  begin
    raise_application_error(-20065,'PCS-'||pcs.pc_functions.TranslateWord('Mise à jour de ''WEB_CATEG_ARRAY_ID_PARENT'' impossible.'));
    rollback;
  end;
end UpdateParentId;

function HasActChild(vArrayID in web_categ_array.web_categ_array_id%type,
    vSignature in web_categ_array.wca_signature%type) return number
is
  tmp number;
begin
  select 1 into tmp from dual
  where exists(
      select web_good_id
      from web_good wg, web_categ_array wca
      where wgo_is_active = 1 and
        wg.web_categ_array_id = wca.web_categ_array_id and
        (wca.wca_signature like vSignature||'-%' or
         wca.web_categ_array_id = vArrayID));
  return tmp;
  exception
    when others then return 0;
end HasActChild;

procedure ActiveStructure(vArrayID in web_categ_array.web_categ_array_id%type)
is
begin
  update web_categ_array
  set wca_is_active = 1
  where web_categ_array_id in
    (select p.web_categ_array_id
     from web_categ_array p, web_categ_array a
     where a.web_categ_array_id = vArrayId and
           p.web_categ_array_id in(a.web_categ_array_id_parent1, a.web_categ_array_id_parent2,
                                   a.web_categ_array_id_parent3, a.web_categ_array_id_parent4));
  exception
  when others then
  begin
    raise_application_error(-20065,'PCS-'||pcs.pc_functions.TranslateWord('Activation impossible.'));
    rollback;
  end;
end ActiveStructure;

procedure DesactiveStructure(vArrayID in web_categ_array.web_categ_array_id%type,
  vSignature in web_categ_array.wca_signature%type)
is

  cursor csParents(pcArrayId web_categ_array.web_categ_array_id%type) is
    select p.web_categ_array_id, p.wca_signature
    from web_categ_array p, web_categ_array a
    where a.web_categ_array_id = pcArrayId and
          p.web_categ_array_id in(a.web_categ_array_id_parent1, a.web_categ_array_id_parent2,
          a.web_categ_array_id_parent3, a.web_categ_array_id_parent4)
    order by p.wca_level desc;
  rParents csParents%rowtype;

begin
  -- Désactive les noeuds enfant
  update web_categ_array
  set wca_is_active = 0
  where web_categ_array_id in
    (select web_categ_array_id from web_categ_array
     where wca_signature like vSignature||'-%');

  -- Désactive les biens du noeud et les biens de ses enfants
  update web_good
  set wgo_is_active = 0
  where web_categ_array_id in
    (select web_categ_array_id from web_categ_array
     where (wca_signature like vSignature||'-%' or web_categ_array_id = vArrayID));


  -- Désactive les parents sans biens liés et sans enfants
  open csParents(vArrayId);
  loop
    fetch csParents into rParents;
    exit when csParents%notfound or
              HasActChild(rParents.web_categ_array_id, rParents.wca_signature) > 0;
    UPDATE WEB_CATEG_ARRAY
    SET WCA_IS_ACTIVE = 0
    WHERE WEB_CATEG_ARRAY_ID = rParents.WEB_CATEG_ARRAY_ID;
  end loop;

  exception
  when others then
  begin
    raise_application_error(-20065,'PCS-'||pcs.pc_functions.TranslateWord('Désactivation impossible.'));
    rollback;
  end;
end DesactiveStructure;

procedure DesactiveEmptyNode(vArrayID in web_categ_array.web_categ_array_id%type)
is
  cursor csParents(pcArrayId web_categ_array.web_categ_array_id%type) is
    select p.web_categ_array_id, p.wca_signature
    from web_categ_array p, web_categ_array a
    where a.web_categ_array_id = pcArrayId and
          p.web_categ_array_id in(pcArrayId, a.web_categ_array_id_parent1, a.web_categ_array_id_parent2,
          a.web_categ_array_id_parent3, a.web_categ_array_id_parent4)
    order by p.wca_level desc;
  rParents csParents%rowtype;
begin
  -- Désactive les noeuds sans biens liés et sans enfants
  open csParents(vArrayId);
  loop
    fetch csParents into rParents;
    exit when csParents%notfound or
              HasActChild(rParents.web_categ_array_id, rParents.wca_signature) > 0;
    UPDATE WEB_CATEG_ARRAY
    SET WCA_IS_ACTIVE = 0
    WHERE WEB_CATEG_ARRAY_ID = rParents.WEB_CATEG_ARRAY_ID;
  end loop;
  exception
  when others then
  begin
    raise_application_error(-20065,'PCS-'||pcs.pc_functions.TranslateWord('Désactivation impossible.'));
    rollback;
  end;
end DesactiveEmptyNode;

function GetLinkedImageName(vGcoGoodId GCO_GOOD.GCO_GOOD_ID%type,
    vKey01 COM_IMAGE_FILES.IMF_KEY01%type,
    vRootPath varchar2) return varchar2 is

  cursor getImg(pGcoGoodId GCO_GOOD.GCO_GOOD_ID%type,
                pKey01 COM_IMAGE_FILES.IMF_KEY01%type) is
  select
    IMF_CABINET||'\'||IMF_DRAWER||'\'||IMF_FOLDER||'\'||IMF_FILE
  from
    COM_IMAGE_FILES A
  where
    A.IMF_KEY01 = pKey01 AND
    A.IMF_TABLE = 'GCO_GOOD' AND
    IMF_REC_ID = pGcoGoodId
  ORDER BY
    IMF_SEQUENCE DESC;

  filename COM_IMAGE_FILES.IMF_PATHFILE%type;

begin
  if length(vRootPath) <> 0 then
    open getImg(vGcoGoodId, vKey01);
  	fetch getImg into filename;
  	if (getImg%notfound) then
      return null;
  	else
  	  return vRootPath||'\'||filename;
    end if;
  else
    return null;
  end if;

end getLinkedImageName;

end WEB_STRUCTURE;
