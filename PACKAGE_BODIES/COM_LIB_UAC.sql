--------------------------------------------------------
--  DDL for Package Body COM_LIB_UAC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_UAC" 
is
  /**
  * function GetContextID
  * Description
  *   Renvoi l'id du contexte UAC correspondant aux liens entre l'objet de
  *     gestion et le type de contexte
  */
  function GetContextID(iObject     in PCS.PC_OBJECT.OBJ_NAME%type
                      , iContext    in COM_UAC.C_UAC_CONTEXT%type
                      , iDicContext in COM_UAC.DIC_UAC_CONTEXT_ID%type) return COM_UAC.COM_UAC_ID%type
  is
    lObjectID      PCS.PC_OBJECT.PC_OBJECT_ID%type;
    lContextID     COM_UAC.COM_UAC_ID%type;
    lContextLinkID COM_UAC_LINK_OBJ.COM_UAC_LINK_OBJ_ID%type;
  begin
    GetContextLinkID(iObject        => iObject
                   , iContext       => iContext
                   , iDicContext    => iDicContext
                   , oObjectID      => lObjectID
                   , oContextID     => lContextID
                   , oContextLinkID => lContextLinkID);

    return lContextID;
  end GetContextID;

  /**
  * procedure GetContextLinkID
  * Description
  *   Renvoi les id des liens entre entre l'objet de gestion et le type de contexte
  */
  procedure GetContextLinkID(iObject        in  PCS.PC_OBJECT.OBJ_NAME%type
                           , iContext       in  COM_UAC.C_UAC_CONTEXT%type
                           , iDicContext    in  COM_UAC.DIC_UAC_CONTEXT_ID%type
                           , oObjectID      out PCS.PC_OBJECT.PC_OBJECT_ID%type
                           , oContextID     out COM_UAC.COM_UAC_ID%type
                           , oContextLinkID out COM_UAC_LINK_OBJ.COM_UAC_LINK_OBJ_ID%type
                           )
  is
  begin
    select OBJ.PC_OBJECT_ID
         , UAC.COM_UAC_ID
         , LNK.COM_UAC_LINK_OBJ_ID
      into oObjectID
         , oContextID
         , oContextLinkID
      from PCS.PC_OBJECT OBJ
         , COM_UAC UAC
         , COM_UAC_LINK_OBJ LNK
     where OBJ.OBJ_NAME = iObject
       and UAC.C_UAC_CONTEXT = iContext
       and nvl(UAC.DIC_UAC_CONTEXT_ID, '[NULL]') = nvl(iDicContext, '[NULL]')
       and LNK.PC_OBJECT_ID = OBJ.PC_OBJECT_ID
       and LNK.COM_UAC_ID = UAC.COM_UAC_ID;
  exception
    when no_data_found or too_many_rows then
      oObjectID      := null;
      oContextID     := null;
      oContextLinkID := null;
  end GetContextLinkID;

  /**
  * function GetBackupElement
  * Description
  *   Renvoi un xml contenant les valeurs de l'élément X sauvegardé dans la
  *     table COM_LIST_ID_TEMP dans le cadre de l'UAC
  */
  function GetBackupElement(iElementID   in number
                          , iObject      in PCS.PC_OBJECT.OBJ_NAME%type
                          , iContext     in COM_UAC.C_UAC_CONTEXT%type
                          , iDicContext  in COM_UAC.DIC_UAC_CONTEXT_ID%type
                          , iProcessMode in varchar2) return clob
  is
   lClob Clob;
  begin
    begin
      select LID_CLOB
        into lClob
        from COM_LIST_ID_TEMP
       where LID_CODE = 'UAC'
         and LID_FREE_NUMBER_1 = iElementID
         and LID_FREE_CHAR_1 = iProcessMode
         and LID_FREE_CHAR_2 = iObject
         and LID_FREE_CHAR_3 = iContext
         and nvl(LID_FREE_CHAR_4, '[NULL]') = nvl(iDicContext, '[NULL]');
    exception
      when no_data_found or too_many_rows then
        null;
    end;

    return lClob;
  end GetBackupElement;

  /**
  * function GetEntityDescr
  * Description
  *   Renvoi la description de l'élément
  */
  function GetEntityDescr(iEntityID  in number
                        , iContext   in COM_UAC.C_UAC_CONTEXT%type) return varchar2
  is
    lv_Entity COM_UAC_LOG.UAC_ENTITY_MODIFY%type;
  begin
    case iContext
      when '01' then
        select max(GOO_MAJOR_REFERENCE)
          into lv_Entity
          from GCO_GOOD
         where GCO_GOOD_ID = iEntityID;
      when '02' then
        select max(GOO_MAJOR_REFERENCE)
          into lv_Entity
          from GCO_GOOD
         where GCO_GOOD_ID = iEntityID;
      when '03' then
        select max(SCH_REF)
          into lv_Entity
          from FAL_SCHEDULE_PLAN
         where FAL_SCHEDULE_PLAN_ID = iEntityID;
      when '04' then
        select max(PER_NAME || ' ' || PER_FORENAME)
          into lv_Entity
          from PAC_PERSON
         where PAC_PERSON_ID = iEntityID;
      else
        lv_Entity := '';
    end case;

    return lv_Entity;
  end GetEntityDescr;

  /**
  * function GetEntityDescr_Autonomus
  * Description
  *   Renvoi la description de l'élément en transaction autonome
  *     (en cas de suppresion de l'élément)
  */
  function GetEntityDescr_Autonomus(iEntityID  in number
                                  , iContext   in COM_UAC.C_UAC_CONTEXT%type) return varchar2
  is
    pragma autonomous_transaction;
  begin
    return GetEntityDescr(iEntityID => iEntityID
                        , iContext  => iContext);
  end GetEntityDescr_Autonomus;

  /**
  * function GetEntityModify
  * Description
  *   Renvoi la description de l'élément modififié
  */
  function GetEntityModify(iEntityID  in number
                         , iContext   in COM_UAC.C_UAC_CONTEXT%type) return varchar2
  is
    lv_Entity COM_UAC_LOG.UAC_ENTITY_MODIFY%type;
  begin
    -- Recherche la description de l'élément
    lv_Entity := GetEntityDescr(iEntityID => iEntityID
                              , iContext  => iContext);

    if lv_Entity is null then
    -- Recherche la description de l'élément en transaction autonome (en cas de suppresion)
      lv_Entity := GetEntityDescr_Autonomus(iEntityID => iEntityID
                                          , iContext  => iContext);
    end if;

    return lv_Entity;
  end GetEntityModify;

end COM_LIB_UAC;
