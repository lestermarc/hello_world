--------------------------------------------------------
--  DDL for Package Body HRM_COUNTRY_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_COUNTRY_FCT" 
/**
 * Package de recherche étendue de pays.
 *
 * Le contenu de la table HRM_COUNTRY doit être basé sur les informations suivantes :
 *   http://www.iso.org/iso/support/country_codes/iso_3166_code_lists/iso-3166-1_decoding_table.htm
 *   http://en.wikipedia.org/wiki/Comparison_of_IOC,_FIFA,_and_ISO_3166_country_codes
 *   http://en.wikipedia.org/wiki/Postal_code#Formats_of_postal_codes_by_country_and_time
 *
 * @author spfister
 * @date 03.2003
 */
as
/**
 * @deprecated
 */
  function SearchCountry(Country in varchar2)
    return varchar2
  is
  begin
    /** This method is deprecated */
    return hrm_country_fct.SearchCountryName(Country);
  end;

  function GetCountryName(Country in varchar2)
    return varchar2
  is
  begin
    return hrm_country_fct.GetCountry(Country, hrm_country_fct.RETURN_COUNTRY);
  end;

  function GetCountryCode(Country in varchar2)
    return varchar2
  is
  begin
    return hrm_country_fct.GetCountry(Country, hrm_country_fct.RETURN_CODE);
  end;

  function GetCountry(Country in varchar2, ReturnVal in ReturnType)
    return varchar2
  is
    lv_country varchar2(32767);
    lv_result  varchar2(32767);
  begin
    if Country is null then
      return null;
    end if;

    lv_country  := '|' || upper(Country) || '|';

    -- Recherche par le code pays
    begin
      select case ReturnVal
               when hrm_country_fct.RETURN_CODE then CNT_CODE
               when hrm_country_fct.RETURN_COUNTRY then CNT_NAME
             end
        into lv_result
        from (select '|' || CNT_CODE || '|' CNT_CODE
                   , '|' || CNT_NAME || '|' CNT_NAME
                from HRM_COUNTRY
               where CNT_CODE is not null)
       where instr(upper(CNT_CODE), lv_country) > 0;

      return substr(lv_result, 2, instr(lv_result, '|', 2) - 2);
    exception
      when no_data_found then
        null;
    end;

    -- Rechercher par le nom du pays
    begin
      select case ReturnVal
               when hrm_country_fct.RETURN_CODE then substr(CNT_CODE, 2, instr(CNT_CODE, '|', 2) - 2)
               when hrm_country_fct.RETURN_COUNTRY then substr(CNT_NAME, COUNTRY_POS, length(Country) )
             end
        into lv_result
        from (select '|' || CNT_CODE || '|' CNT_CODE
                   , CNT_NAME
                   , instr('|' || upper(CNT_NAME) || '|', lv_country) COUNTRY_POS
                from HRM_COUNTRY
               where CNT_NAME is not null)
       where COUNTRY_POS > 0;

      return lv_result;
    exception
      when no_data_found then
        null;
    end;

    return null;
  end;

  function SearchCountryName(Country in varchar2)
    return varchar2
  is
  begin
    return hrm_country_fct.SearchCountry(Country, hrm_country_fct.RETURN_COUNTRY);
  end;

  function SearchCountryCode(Country in varchar2)
    return varchar2
  is
  begin
    return hrm_country_fct.SearchCountry(Country, hrm_country_fct.RETURN_CODE);
  end;

  function SearchCountry(Country in varchar2, ReturnVal in ReturnType)
    return varchar2
  is
    lv_name    varchar2(160);
    lv_code    varchar2(32);
    lv_country varchar2(32767);
    ln_pos     binary_integer;
  begin
    if Country is null then
      return null;
    end if;

    -- Recherche du pays
    lv_country  := hrm_country_fct.GetCountry(Country, ReturnVal);

    if (lv_country is not null) then
      return lv_country;
    end if;

    -- Recherhe si un pays semblable existe
    for tplCountry in (select   '|' || CNT_CODE || '|' CNT_CODE
                              , CNT_NAME || '|' CNT_NAME
                           from HRM_COUNTRY
                          where CNT_NAME is not null
                       order by CNT_NAME) loop
      lv_code     := tplCountry.cnt_code;
      lv_country  := tplCountry.cnt_name;

      while(lv_country is not null) loop
        ln_pos      := instr(lv_country, '|');
        lv_name     := substr(lv_country, 1, ln_pos - 1);

        if (    lv_name is not null
            and hrm_functions.SoundexEx(Country, lv_name) = 1) then
          return case ReturnVal
            when hrm_country_fct.RETURN_CODE then substr(lv_code, 2, instr(lv_code, '|', 2) - 2)
            when hrm_country_fct.RETURN_COUNTRY then lv_name
          end;
        end if;

        lv_country  := substr(lv_country, ln_pos + 1);
      end loop;
    end loop;

    return null;
  end;
end HRM_COUNTRY_FCT;
