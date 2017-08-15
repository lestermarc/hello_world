--------------------------------------------------------
--  DDL for Package Body WEB_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_FUNCTIONS" 
as
  NCHECK constant pls_integer := 42949;

  function GeneratePassword(UserName in varchar2)
    return varchar2
  is
    j      number       := 0;
    k      number;
    str    varchar2(30);
    result varchar2(30);
  begin
    if UserName is null then
      return null;
    end if;

    str     := substr(UserName, 1, 4) || to_char(sysdate, 'SSSS');

    for i in 1 .. least(length(str), 8) loop
      j       := mod(j + ascii(substr(str, i, 1) ), 256);
      k       := mod(bitand(j, ascii(substr(str, i, 1) ) ), 74) + 48;

      if k between 58 and 64 then
        k  := k + 7;
      elsif k between 91 and 96 then
        k  := k + 6;
      end if;

      result  := result || chr(k);
    end loop;

    result  := replace(result, '1', '2');
    result  := replace(result, 'l', 'L');
    result  := replace(result, '0', '9');
    result  := replace(result, 'O', 'P');
    result  := 'A' || substr(result, 2);
    return result;
  exception
    when others then
      return null;
  end;

  procedure SetRightForUserToPage(pWebUserId in WEB_USER.WEB_USER_ID%type, pWebPageKey in varchar2, pRight in number)
  is
    vExist      number(1);
    vWebItemId  WEB_ITEM.WEB_ITEM_ID%type;
    vWebGroupId WEB_GROUP.WEB_GROUP_ID%type;
  begin
    -- try to update if exists
    select count(*)
      into vExist
      from WEB_UGRIR u
         , WEB_ITEM i
     where u.web_item_id = i.web_item_id
       and wei_item_name = pWebPageKey
       and web_user_id = pWebUserId;

    select web_item_id
      into vWebItemId
      from WEB_ITEM
     where wei_item_name = pWebPageKey;

    select web_group_id
      into vWebGroupId
      from WEB_GROUP
     where weg_group_name = 'shop';

    if (vExist = 1) then
      begin
        update WEB_UGRIR
           set wri_right = pRight
         where web_user_id = pWebUserId
           and web_item_id = vWebItemId;
      end;
    else
      begin
        -- if not, create new row
        insert into WEB_UGRIR
                    (WEB_UGRIR_ID
                   , WEB_USER_ID
                   , WEB_GROUP_ID
                   , WEB_ROLE_ID
                   , WEB_ITEM_ID
                   , WRI_RIGHT
                    )
             values (INIT_ID_SEQ.nextval
                   , pWebUserId
                   , vWebGroupId
                   , null
                   , vWebItemId
                   , pRight
                    );
      end;
    end if;
  end;

  function GetRightForUserToPage(pWebUserId in WEB_USER.WEB_USER_ID%type, pWebPageKey in varchar2)
    return number
  is
    vRight number(1);
  begin
    select nvl(u.WRI_RIGHT, i.WEI_DEFAULT_RIGHT)
      into vRight
      from WEB_UGRIR u
         , WEB_ITEM i
     where u.WEB_ITEM_ID(+) = i.WEB_ITEM_ID
       and u.web_user_id(+) = pWebUserId
       and i.WEI_ITEM_NAME = pWebPageKey;

    return vRight;
  exception
    when no_data_found then
      return RETURN_FATAL;
  end;

  function GetWebCategDescr(WebCategId in WEB_CATEG.WEB_CATEG_ID%type, LangId in PCS.PC_LANG.PC_LANG_ID%type)
    return varchar2
  is
    vDescr WEB_CATEG_DESCR.WCD_DESCR%type;
  begin
    if (    (WebCategId is null)
        or (LangId is null) ) then
      vDescr  := '';
    else
      select ' - ' || wcd_descr
        into vDescr
        from WEB_CATEG_DESCR
       where web_categ_id = WebCategId
         and pc_lang_id = LangId;
    end if;

    return vDescr;
  exception
    when others then
      return '';
  end;

  function GetWebCategCode(WebCategId in WEB_CATEG.WEB_CATEG_ID%type)
    return varchar2
  is
    vCode WEB_CATEG.WCA_CODE%type;
  begin
    if (WebCategId is null) then
      vCode  := '';
    else
      select ' - ' || wca_code
        into vCode
        from WEB_CATEG
       where web_categ_id = WebCategId;
    end if;

    return vCode;
  exception
    when others then
      return '';
  end;

  function GetWebCategArrayDescr(WebCategArrayId in WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type, LangId in PCS.PC_LANG.PC_LANG_ID%type)
    return varchar2
  is
    vDescr WEB_CATEG_DESCR.WCD_DESCR%type;
  begin
    select Web_Functions.GetWebCategDescr(web_categ_id_level1, LangId) ||
           Web_Functions.GetWebCategDescr(web_categ_id_level2, LangId) ||
           Web_Functions.GetWebCategDescr(web_categ_id_level3, LangId) ||
           Web_Functions.GetWebCategDescr(web_categ_id_level4, LangId) ||
           Web_Functions.GetWebCategDescr(web_categ_id_level5, LangId) ||
           ' -'
      into vDescr
      from WEB_CATEG_ARRAY
     where web_categ_array_id = WebCategArrayId;

    return vDescr;
  exception
    when others then
      return '';
  end;

  function GetWebCategArrayCode(WebCategArrayId in WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type)
    return varchar2
  is
    vCodes varchar2(100);
  begin
    select GetWebCategCode(web_categ_id_level1) ||
           GetWebCategCode(web_categ_id_level2) ||
           GetWebCategCode(web_categ_id_level3) ||
           GetWebCategCode(web_categ_id_level4) ||
           GetWebCategCode(web_categ_id_level5) ||
           ' -'
      into vCodes
      from WEB_CATEG_ARRAY
     where web_categ_array_id = WebCategArrayId;

    return vCodes;
  exception
    when others then
      return '';
  end;

  function Get_Qty_Conditioning(GoodId in GCO_GOOD.GCO_GOOD_ID%type, CustomId in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type)
    return WEB_PURCHASE_ORDER_GOOD.WPG_QUANTITY%type
  is
    tmp WEB_PURCHASE_ORDER_GOOD.WPG_QUANTITY%type;
  begin
    select nvl(csa_qty_conditioning, 1)
      into tmp
      from GCO_COMPL_DATA_SALE
     where pac_custom_partner_id = CustomId
       and gco_good_id = GoodId;

    return tmp;
  exception
    when others then
      return RETURN_FATAL;
  end Get_Qty_Conditioning;

  function GetWebUserData(pUserName in WEB_USER.WEU_LOGIN_NAME%type, pInfoName in varchar2)
    return varchar2
  is
    resShort varchar2(5);
    resId    number(12);
    isPcUser number(1);
    isEmploy number(1);
  begin
    select sign(pc_user_id)
         , sign(hrm_person_id)
      into isPcUser
         , isEmploy
      from WEB_USER
     where WEU_LOGIN_NAME = pUserName;

    if ('DIC_POS_FREE_TABLE_1_ID' = pInfoName) then
      begin
        resShort  := null;

        if (isPcUser = 1) then
          begin
            select use_ini
              into resShort
              from pcs.pc_user a
                 , WEB_USER b
             where b.pc_user_id = a.pc_user_id
               and b.WEU_LOGIN_NAME = pUserName;
          end;
        elsif(     (resShort is null)
              and (isEmploy = 1) ) then
          begin
            select per_initials
              into resShort
              from HRM_PERSON p
                 , WEB_USER w
             where w.hrm_person_id = p.hrm_person_id
               and WEU_LOGIN_NAME = pUserName;
          end;
        end if;

        return resShort;
      exception
        when no_data_found then
          return '?';
      end;
    elsif('PC_LANG_ID' = pInfoName) then
      begin
        select count(*)
          into isPcUser
          from WEB_USER
         where WEU_LOGIN_NAME = pUserName
           and pc_user_id is not null;

        if (isPcUser = 1) then
          begin
            select a.pc_lang_id
              into resId
              from pcs.pc_user a
                 , WEB_USER b
             where b.pc_user_id = a.pc_user_id
               and b.WEU_LOGIN_NAME = pUserName;

            return resId;
          end;
        else
          begin
            select count(*)
              into isEmploy
              from WEB_USER
             where WEU_LOGIN_NAME = pUserName
               and hrm_person_id is not null;

            if (isEmploy = 1) then
              begin
                select nvl(pc_lang_id, 1)
                  into resId
                  from WEB_USER
                 where WEU_LOGIN_NAME = pUserName;

                return resId;
              end;
            else
              begin
                select pc_lang_id
                  into resId
                  from pcs.pc_scrip s
                     , pcs.pc_comp c
                 where c.pc_scrip_id = s.pc_scrip_id
                   and upper(s.SCRDBOWNER) = upper(user)
                   and rownum = 1;

                return resId;
              end;
            end if;
          end;
        end if;
      exception
        when no_data_found then
          begin
            return RETURN_FATAL;
          end;
      end;
    elsif('USER_INI' = pInfoName) then
      begin
        resShort  := '?';

        if (isPcUser = 1) then
          begin
            select use_ini
              into resShort
              from pcs.pc_user a
                 , WEB_USER b
             where b.pc_user_id = a.pc_user_id
               and b.WEU_LOGIN_NAME = pUserName;
          end;
        elsif(     (resShort = '?')
              and (isEmploy = 1) ) then
          begin
            select per_initials
              into resShort
              from HRM_PERSON p
                 , WEB_USER w
             where w.hrm_person_id = p.hrm_person_id
               and WEU_LOGIN_NAME = pUserName;
          end;
        end if;

        return resShort;
      exception
        when no_data_found then
          return '?';
      end;
    elsif('USER_ID' = pInfoName) then
      begin
        select a.pc_user_id
          into resId
          from pcs.pc_user a
             , WEB_USER b
         where b.pc_user_id = a.pc_user_id
           and b.WEU_LOGIN_NAME = pUserName;

        return resId;
      exception
        when no_data_found then
          return null;
      end;
    end if;
  end;

  procedure CreateNewWebUser(
    pUserName        in WEB_USER.WEU_LOGIN_NAME%type
  , pApplicationName in WEB_GROUP.WEG_GROUP_NAME%type
  , pRoleName        in WEB_ROLE.WER_ROLE_NAME%type
  )
  is
    isOracleUser        number;
    isWebUser           number;
    isPacPerson         number;
    vPcUserId           number;
    vPacCustomPartnerId number;
    vHrmPersonId        number;
    vApplicationGroupId number;
    vRoleNameId         number;
    vWebUserId          number;
    vPassword           WEB_USER.WEU_PASSWORD_VALUE%type;
    vFirstName          WEB_USER.WEU_FIRST_NAME%type;
    vLastName           WEB_USER.WEU_LAST_NAME%type;
    vEmail              WEB_USER.WEU_EMAIL%type;
    hasEmail            number;
  begin
    select count(*)
      into isWebUser
      from WEB_USER
     where upper(weu_login_name) like upper(pUserName);

    if (isWebUser = 1) then
      begin
        RAISE_APPLICATION_ERROR(-20999, 'ch.proconcept.model.cpy.web ' || pUserName || ': User is already a webUser.');
      end;
    end if;

    if (pApplicationName = 'report') then
      begin
        /*check if oracle user*/
        select count(*)
          into isOracleUser
          from ALL_USERS
         where upper(username) like upper(pUserName);

        if (isOracleUser = 0) then
          begin
            RAISE_APPLICATION_ERROR(-20999, 'ch.proconcept.model.cpy.web ' || pUserName || ': User is not an Oracle user or a PCS user');
          end;
        else
          begin
            /* check if pUserName is already a webUser */
              /* creation du user */
            select pc_user_id
              into vPcUserId
              from pcs.pc_user
             where upper(use_name) like upper(pUserName);

            vPassword   := '-';
            vFirstName  := pUserName;
            vLastName   := pUserName;
            vEmail      := pUserName || '@pro-concept.com';
          end;
        end if;
      end;
    end if;   --(pApplicationName='report')

    if (pApplicationName = 'shop') then
      begin
        select count(*)
          into isPacPerson
          from PAC_PERSON
         where upper(per_key1) like upper(pUserName);

        if (isPacPerson = 0) then
          begin
            RAISE_APPLICATION_ERROR(-20999, 'ch.proconcept.model.cpy.web ' || pUserName || ': User is not an pac_person');
          end;
        else
          begin
            select pac_person_id
                 , per_key2
                 , per_name
                 , nvl(per_forename, per_name)
              into vPacCustomPartnerId
                 , vPassword
                 , vFirstName
                 , vLastName
              from PAC_PERSON
             where upper(per_key1) like upper(pUserName);

            select count(*)
              into hasEmail
              from PAC_COMMUNICATION a
             where a.DIC_COMMUNICATION_TYPE_ID = (select dic_communication_type_id
                                                    from DIC_COMMUNICATION_TYPE b
                                                   where dco_email = 1)
               and pac_person_id = vPacCustomPartnerId;

            if (hasEmail > 0) then
              begin
                select com_ext_number
                  into vEmail
                  from PAC_COMMUNICATION a
                 where a.DIC_COMMUNICATION_TYPE_ID = (select dic_communication_type_id
                                                        from DIC_COMMUNICATION_TYPE b
                                                       where dco_email = 1)
                   and pac_person_id = vPacCustomPartnerId;
              end;
            end if;
          end;
        end if;
      end;
    end if;   --application shop

    select web_group_id
      into vApplicationGroupId
      from WEB_GROUP a
     where upper(weg_group_name) like upper(pApplicationName);

    select web_role_id
      into vRoleNameId
      from WEB_ROLE
     where upper(wer_role_name) like upper(pRoleName);

    select init_id_seq.nextval
      into vWebUserId
      from dual;

    insert into WEB_USER
                (WEB_USER_ID
               , WEU_LOGIN_NAME
               , WEU_PASSWORD_VALUE
               , WEU_FIRST_NAME
               , WEU_LAST_NAME
               , WEU_EMAIL
               , WEU_CONFIRM_VALUE
               , WEU_LAST_LOGIN
               , WEU_DISABLED
               , WEU_PASSWORD_CHANGED
               , PC_USER_ID
               , HRM_PERSON_ID
               , PAC_REPRESENTATIVE_ID
               , PAC_CUSTOM_PARTNER_ID
               , PAC_SUPPLIER_PARTNER_ID
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
                )
         values (vWebUserId
               , pUserName
               , vPassword
               , vFirstName
               , vLastName
               , vEmail
               , 'CONFIRMED'
               , sysdate
               , 0
               , null
               , vPcUserId
               , vHrmPersonId
               , null
               , vPacCustomPartnerId
               , null
               , sysdate
               , null
               , 'AUTO'
               , null
               , 0
               , 0
                );

    insert into WEB_USER_GROUP_ROLE
                (WEB_USER_ID
               , WEB_GROUP_ID
               , WEB_ROLE_ID
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
                )
         values (vWebUserId
               , vApplicationGroupId
               , vRoleNameId
               , sysdate
               , null
               , 'AUTO'
               , null
                );
  end;

  procedure SetWebUserData(pUserName in WEB_USER.WEU_LOGIN_NAME%type, pInfoName in varchar2, pValue in varchar2)
  is
    userType varchar2(30);

    cursor cWebUser(pUserName in WEB_USER.WEU_LOGIN_NAME%type)
    is
      select pc_user_id
           , pac_custom_partner_id
           , pac_supplier_partner_id
           , hrm_person_id
        from WEB_USER
       where WEU_LOGIN_NAME = pUserName;

    r        cWebUser%rowtype;
  begin
    open cWebUser(pUserName);

    fetch cWebUser
     into r;

    userType  := '?';

    if (r.PC_USER_ID is not null) then
      userType  := 'PC_USER';
    elsif(r.HRM_PERSON_ID is not null) then
      userType  := 'HRM_PERSON';
    elsif(    (r.PAC_SUPPLIER_PARTNER_ID is not null)
          or (r.PAC_SUPPLIER_PARTNER_ID is not null) ) then
      userType  := 'PAC_THIRD';
    end if;

    if ('PC_LANG_ID' = pInfoName) then
      if (userType = 'PC_USER') then
        begin   --update PC_LANG_ID pour un WEB_USER définit comme utilisateur Pro-Concept
          update PCS.PC_USER
             set PC_LANG_ID = pValue
           where PC_USER_ID = r.PC_USER_ID;
        end;
      end if;
    end if;

    close cWebUser;
  end;

  function checksum(p_buffInput in varchar2)
    return integer
  is
    l_sum  pls_integer    := 0;
    l_n    pls_integer;
    p_buff varchar2(2000);
  begin
    p_buff  := replace(p_buffInput, '1', 'D');
    p_buff  := replace(p_buff, '2', 'A');
    p_buff  := replace(p_buff, '3', 'P');
    p_buff  := replace(p_buff, '4', 'W');
    p_buff  := replace(p_buff, '5', 'Q');
    p_buff  := replace(p_buff, '6', 'W');
    p_buff  := replace(p_buff, '7', 'E');
    p_buff  := replace(p_buff, '8', 'D');
    p_buff  := replace(p_buff, '9', 'S');
    p_buff  := replace(p_buff, '0', 'A');

    for i in 1 .. trunc(length(p_buff || 'x') / 2) loop
      l_n    := ascii(substr(p_buff || 'x', 1 + (i - 1) * 2, 1) ) * 256 + ascii(substr(p_buff || 'x', 2 + (i - 1) * 2, 1) );
      l_sum  := mod(l_sum + l_n, NCHECK);
    end loop;

    while(l_sum > 65536) loop
      l_sum  := bitand(l_sum, 65535) + trunc(l_sum / 65536);
    end loop;

    return l_sum;
  end checksum;

/*
Indiv avec lecture WEB_ACTIVITY_LOGIN_MSG_FCTNAME
return RETURN_WARNING si un message est transféré pour affichage sinon RETURN_OK
*/
  function GET_LOGIN_MSG(pWEB_USER_ID WEB_USER.WEB_USER_ID%type, pAPPLICATION_NAME varchar2, pMsg out varchar2)
    return number
  is
    compId      pcs.pc_comp.pc_comp_id%type;
    configValue pcs.pc_cbase.CBACVALUE%type;
    sqlToCheck  varchar2(4000);
    returnCode  number;
  begin
    select pc_comp_id
      into compId
      from pcs.pc_comp c
         , pcs.pc_scrip s
     where s.pc_scrip_id = c.pc_scrip_id
       and rownum = 1
       and s.SCRDBOWNER = user;

    pcs.PC_I_LIB_SESSION.SetCompanyId(compId);
    configValue  := pcs.pc_config.GetConfig('WEB_ACTIVITY_LOGIN_MSG_FCTNAME');

    if (configValue is not null) then
      sqlToCheck  :=
        'DECLARE errMsg varchar2(4000); returnCode number(2); ' ||
        'BEGIN returnCode:=' ||
        configValue ||
        '(:pWEB_USER_ID,:pAPPLICATION_NAME, errMsg); :returnErr:=errMsg; :returnCode:=returnCode; END;';

      execute immediate sqlToCheck
                  using pWEB_USER_ID, pAPPLICATION_NAME, out pMsg, out returnCode;

      return returnCode;
    end if;

    return RETURN_OK;
  end;

/**
 * retourne le display name de l'utilisateur
 *
 * aecouserid id de l'utilisateur
 *
 */
  function getEcoUsersDisplayName(aecouserid in number)
    return varchar
  is
    sqlstmnt           varchar2(4000);
    ecoUsersDiplayName varchar2(100);
  begin
    sqlstmnt  := 'select ECU_DISPLAY_NAME from ECONCEPT.ECO_USERS where ECO_USERS_ID= :ECO_USERS_ID';

    execute immediate sqlstmnt
                 into ecoUsersDiplayName
                using aecouserid;

    return ecoUsersDiplayName;
  exception
    when no_data_found then
      return null;
  end;

  /**
   * Creation d'un com_ole + com_image_files
   *
    declare
      n number(1);
      id number(12);
      msg varchar2(2000);
    begin
      n := web_functions.INSERTCOMIMAGEFILEEMPTY('test','HRM_PERSON',60054606872,id, msg);
      dbms_output.PUT_LINE(n||' '||id||' '||msg);
    end;
   */
  function insertComImageFileEmpty(filename in varchar2, tableName in varchar2, redId in number, newId out number, msg out varchar2)
    return varchar
  is
    tplCOM_IMAGE_FILES COM_IMAGE_FILES%rowtype;
    newComOleId        COM_OLE.COM_OLE_ID%type;
    newComImageId      COM_IMAGE_FILES.COM_IMAGE_FILES_ID%type;
    composedName       varchar2(50);
  begin
    select init_id_seq.nextval
         , init_id_seq.nextval
      into newComOleId
         , newComImageId
      from dual;

    select substr(newComOleId || filename, 1, 50)
      into composedName
      from dual;

    insert into COM_OLE
                (COM_OLE_ID
               , OLE_NAME
               , OLE_DESCR
               , OLE_OLE
               , A_DATECRE
               , A_IDCRE
               , A_DATEMOD
               , A_IDMOD
               , OLE_ISOLE
                )
         values (newComOleId
               , composedName
               , filename
               , empty_blob()
               , sysdate
               , 'WEB'
               , null
               , null
               , 0
                );

    select count(*) + 1
      into tplCOM_IMAGE_FILES.IMF_IMAGE_INDEX
      from com_image_files
     where imf_rec_id = redId
       and imf_table = tableName;

    tplCOM_IMAGE_FILES.COM_IMAGE_FILES_ID  := newComImageId;
    tplCOM_IMAGE_FILES.IMF_TABLE           := tableName;
    tplCOM_IMAGE_FILES.IMF_REC_ID          := redId;
    tplCOM_IMAGE_FILES.IMF_SEQUENCE        := tplCOM_IMAGE_FILES.IMF_IMAGE_INDEX;
    tplCOM_IMAGE_FILES.IMF_COM_IMAGE_PATH  := null;
    tplCOM_IMAGE_FILES.IMF_CABINET         := null;
    tplCOM_IMAGE_FILES.IMF_DRAWER          := null;
    tplCOM_IMAGE_FILES.IMF_FOLDER          := null;
    tplCOM_IMAGE_FILES.IMF_FILE            := filename;
    tplCOM_IMAGE_FILES.IMF_DESCR           := null;
    tplCOM_IMAGE_FILES.IMF_STORED_IN       := 'DB';
    tplCOM_IMAGE_FILES.COM_OLE_ID          := newComOleId;
    tplCOM_IMAGE_FILES.IMF_KEY01           := null;
    tplCOM_IMAGE_FILES.IMF_KEY02           := null;
    tplCOM_IMAGE_FILES.IMF_KEY03           := null;
    tplCOM_IMAGE_FILES.IMF_KEY04           := null;
    tplCOM_IMAGE_FILES.IMF_KEY05           := null;
    tplCOM_IMAGE_FILES.IMF_KEY06           := null;
    tplCOM_IMAGE_FILES.IMF_KEY07           := null;
    tplCOM_IMAGE_FILES.IMF_KEY08           := null;
    tplCOM_IMAGE_FILES.IMF_KEY09           := null;
    tplCOM_IMAGE_FILES.IMF_KEY10           := null;
    tplCOM_IMAGE_FILES.IMF_KEY11           := null;
    tplCOM_IMAGE_FILES.IMF_KEY12           := null;
    tplCOM_IMAGE_FILES.IMF_KEY13           := null;
    tplCOM_IMAGE_FILES.IMF_KEY14           := null;
    tplCOM_IMAGE_FILES.IMF_KEY15           := null;
    tplCOM_IMAGE_FILES.A_DATECRE           := sysdate;
    tplCOM_IMAGE_FILES.A_DATEMOD           := null;
    tplCOM_IMAGE_FILES.A_IDCRE             := 'WEB';
    tplCOM_IMAGE_FILES.A_IDMOD             := null;
    tplCOM_IMAGE_FILES.IMF_PATHFILE        := null;
    tplCOM_IMAGE_FILES.IMF_LINKED_FILE     := 0;

    insert into COM_IMAGE_FILES
         values tplCOM_IMAGE_FILES;

/*(
1213023, 'DOC_DOCUMENT', 1213012, 1, 2, 'C:\pcs\images', 'MAS_F', 'DOC_DOCUMENT', '2000_04'
, '000001213012_001_01.tif', NULL, 'FILE', NULL, NULL, NULL, NULL, NULL, NULL, NULL
, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  TO_Date( '04/17/2000 07:51:21 AM', 'MM/DD/YYYY HH:MI:SS AM')
,  TO_Date( '04/17/2000 08:20:45 AM', 'MM/DD/YYYY HH:MI:SS AM'), 'PAS', 'PAS', 'C:\pcs\images\MAS_F\DOC_DOCUMENT\2000_04\000001213012_001_01.tif'
, 0); */
    newId                                  := newComImageId;
    return RETURN_OK;
  end;

  /**
  * Description
  *   Check if user already exists in PC_USER (return 1) or in WEB_USER (reuturn 2) or does not exists (return 0)
  */
  function CheckWebUser(iUserName in PCS.PC_USER.USE_NAME%type)
    return number
  is
    lPCUserId  PCS.PC_USER.PC_USER_ID%type;
    lWebUserId WEB_USER.WEB_USER_ID%type;
  begin
    -- look if found in PC_USER
    select max(PC_USER_ID)
      into lPCUserId
      from PCS.PC_USER
     where upper(USE_NAME) = upper(iUserName)
        or upper(USE_ACCOUNT_NAME) = upper(iUserName);

    -- look if found in WEB_USER
    select max(WEB_USER_ID)
      into lWebUserId
      from WEB_USER
     where PC_USER_ID = lPCUserId;

    if lWebUserId is not null then
      -- already in WEB_USER
      return 2;
    else
      if lPCUserId is not null then
        -- exists in PC_USER but not in WEB_USER
        return 1;
      else
        -- exists nowhere
        return 0;
      end if;
    end if;
  end CheckWebUser;

  /**
  * Description
  *   Activate an existing PC_USER into a WEB_USER
  */
  procedure ActivateWebUser(iUserName in PCS.PC_USER.USE_NAME%type, oUserId out WEB_USER.WEB_USER_ID%type)
  is
    lUserId WEB_USER.WEB_USER_ID%type;
  begin
    -- look for PC_USER_ID
    select max(PC_USER_ID)
      into lUserId
      from PCS.PC_USER
     where upper(USE_NAME) = upper(iUserName)
        or upper(USE_ACCOUNT_NAME) = upper(iUserName);

    ActivateWebUser(iUserId => lUserId,
                    oUserId => oUserId);
  end ActivateWebUser;
  /**
  * Description
  *   Activate an existing PC_USER into a WEB_USER
  */
  procedure ActivateWebUser(iUserId in PCS.PC_USER.PC_USER_ID%type, oUserId out WEB_USER.WEB_USER_ID%type)
  is
    lCompId PCS.PC_COMP.PC_COMP_ID%type;
  begin

    -- look for company identifier
    select min(PC_COMP_ID)
      into lCompId
      from PCS.PC_COMP COM
         , PCS.PC_SCRIP SCR
     where SCR.SCRDBOWNER = COM_CURRENTSCHEMA
       and COM.PC_SCRIP_ID = SCR.PC_SCRIP_ID;

    -- be sure that flag USE_WEB si set to 1
    update PCS.PC_USER
       set USE_WEB = 1
     where PC_USER_ID = iUserId;

    -- activate the user in the current company
    insert into PCS.PC_USER_LINK
                (PC_USER_LINK_ID
               , PC_USER_ID
               , PC_COMP_ID
               , ULI_LINK_CODE
               , ULI_LINK_RECORD_ID
               , ULI_DESC
               , A_DATECRE
               , A_IDCRE
                )
         values (pcs.init_id_seq.nextval
               , iUserId
               , lCompId
               , 'WEB_USER'
               , iUserId
               , 'Created by WEB_FUNCTIONS.ActivateWebUser'
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
    -- activate the user in the current company
    insert into PCS.PC_USER_LINK
                (PC_USER_LINK_ID
               , PC_USER_ID
               , PC_COMP_ID
               , ULI_LINK_CODE
               , ULI_LINK_RECORD_ID
               , ULI_DESC
               , A_DATECRE
               , A_IDCRE
                )
         values (pcs.init_id_seq.nextval
               , iUserId
               , lCompId
               , 'WEB_USER.WEU_DISABLED'
               , 1
               , 'Created by WEB_FUNCTIONS.ActivateWebUser'
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
    -- gardé pour ne pas changer les signatures
    oUserId  := iUserId;
  end ActivateWebUser;
end Web_Functions;
