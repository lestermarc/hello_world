--------------------------------------------------------
--  DDL for Package Body DOC_INTERFACE_CONFIG_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INTERFACE_CONFIG_FCT" 
is

  /**
   * Description
   *   Retourne la configuration désirée en fonction de l'origine du document,
   *   de son type et du tiers
   */
  function get_config(
      aDOIOrigin in DOC_INTERFACE_CONFIG.C_DOC_INTERFACE_ORIGIN%type
    , aThirdId in PAC_THIRD.PAC_THIRD_ID%type
    , aDOIType in DOC_INTERFACE_CONFIG.DOG_DOCUMENT_TYPE%type
    , aSearchPath in varchar2 default 'DEF_VALUE'
    , aDOIConfigId out DOC_INTERFACE_CONFIG%rowtype
    )
    return number
  is
    cursor cr_PathUsingThird(
              c_DOIOrigin DOC_INTERFACE_CONFIG.C_DOC_INTERFACE_ORIGIN%type
            , c_ThirdId PAC_THIRD.PAC_THIRD_ID%type
            , c_DOIType DOC_INTERFACE_CONFIG.DOG_DOCUMENT_TYPE%type)
    is
      select *
        from DOC_INTERFACE_CONFIG DOG
       where DOG.C_DOC_INTERFACE_ORIGIN = c_DOIOrigin
         and DOG.PAC_THIRD_ID = c_ThirdId
         and DOG.DOG_DOCUMENT_TYPE = c_DOIType;

    cursor cr_PathUsingDefValue(
              c_DOIOrigin DOC_INTERFACE_CONFIG.C_DOC_INTERFACE_ORIGIN%type
            , c_DOIType DOC_INTERFACE_CONFIG.DOG_DOCUMENT_TYPE%type)
    is
      select *
        from DOC_INTERFACE_CONFIG DOG
       where DOG.C_DOC_INTERFACE_ORIGIN = c_DOIOrigin
         and DOG.PAC_THIRD_ID is null
         and DOG.DOG_DOCUMENT_TYPE = c_DOIType;

    tpl_PathUsingThird DOC_INTERFACE_CONFIG%rowtype;
    tpl_PathUsingDefValue DOC_INTERFACE_CONFIG%rowtype;

    vResult number(1) := 0;
    vCounter number(2) := 1;
    vCurrentPath varchar2(10);
    vTempResult number;
    vTryNextPath boolean := true;
  begin

    vCurrentPath := extractline (aSearchPath, vCounter, ',' ,1);

    while vCurrentPath is not null and vTryNextPath loop

      if vCurrentPath = 'THIRD' then

        open cr_pathUsingThird (aDOIOrigin, aThirdId, aDOIType);
        fetch cr_pathUsingThird into aDOIConfigId;
        if cr_pathUsingThird%found then
          vTryNextPath := false;
          vResult := 1;
        end if;
        close cr_pathUsingThird;

      elsif vCurrentPath = 'DEF_VALUE' then

        open cr_pathUsingDefValue (aDOIOrigin, aDOIType);
        fetch cr_pathUsingDefValue into aDOIConfigId;
        if cr_pathUsingDefValue%found then
          vTryNextPath := false;
          vResult := 1;
        end if;
        close cr_pathUsingDefValue;

      end if;

      vCounter := vCounter+1;
      vCurrentPath := extractline (aSearchPath, vCounter, ',' ,1);
    end loop;
    return vResult;

  end get_config;

end DOC_INTERFACE_CONFIG_FCT;
