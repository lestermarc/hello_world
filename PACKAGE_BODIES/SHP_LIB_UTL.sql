--------------------------------------------------------
--  DDL for Package Body SHP_LIB_UTL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_LIB_UTL" 
as
  /**
  * Description
  *   Cette fonction retourne la date au format MySQL. (Nomre de secondes depuis
  *   le 1er janvier 1970).
  */
  function toDate1970Based(idDate in date)
    return number
  as
  begin
    return trunc( (idDate - to_date('01.01.1970 00:00:00', 'dd.mm.yyyy hh24:mi:ss') ) * 86400);
  end toDate1970Based;


  /**
  * Description
  *   Retourne l'URL formattée selon paramètres.
  */
  function getFormattedURL(
    ivUrl                     in COM_IMAGE_FILES.IMF_PATHFILE%type
  , inUseWindowsPathDelimiter in number
  , ivRootPath                in varchar2
  , ivWebServerPath           in varchar2
  )
    return COM_IMAGE_FILES.IMF_PATHFILE%type
  as
    lFormattedURL COM_IMAGE_FILES.IMF_PATHFILE%type;
  begin
    case inUseWindowsPathDelimiter
      when 1 then
        lFormattedURL  := rtrim(ivWebServerPath, '\') || substr(ivUrl, -length(replace(lower(ivUrl), lower(rtrim(ivRootPath, '\') ) ) ) );
      else
        lFormattedURL  := rtrim(ivWebServerPath, '/') || replace(substr(ivUrl, -length(replace(lower(ivUrl), lower(rtrim(ivRootPath, '\') ) ) ) ), '\', '/');
    end case;

    return lFormattedURL;
  end getFormattedURL;
end SHP_LIB_UTL;
