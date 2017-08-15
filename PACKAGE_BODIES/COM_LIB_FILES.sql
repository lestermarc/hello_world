--------------------------------------------------------
--  DDL for Package Body COM_LIB_FILES
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_FILES" 
is
  /**
  * function GetMainImageFileId
  * Description
  *   Lookup for the main image file id linked to a thumbnail image file id
  * @created fpe 04.08.2014
  * @updated
  * @public
  * @param iThumbImageFileId : id of the thumbnail
  * @return see description
  */
  function GetMainImageFileId(iThumbImageFileId in COM_IMAGE_FILES.COM_IMAGE_FILES_ID%type)
    return COM_IMAGE_FILES.COM_IMAGE_FILES_ID%type
  is
    lResult COM_IMAGE_FILES.COM_IMAGE_FILES_ID%type;
  begin
    select min(C2.COM_IMAGE_FILES_ID)
      into lResult
      from COM_IMAGE_FILES C1, COM_IMAGE_FILES C2
     where C1.COM_IMAGE_FILES_ID = iThumbImageFileId
       and upper(C2.IMF_FILE) = replace(upper(C1.IMF_FILE),'_THUMB','');
    return lResult;
  end GetMainImageFileId;

end COM_LIB_FILES;
