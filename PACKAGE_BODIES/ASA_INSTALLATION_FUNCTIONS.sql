--------------------------------------------------------
--  DDL for Package Body ASA_INSTALLATION_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_INSTALLATION_FUNCTIONS" 
is
/*--------------------------------------------------------------------------------------------------------------------*/
/**
* Description
*    Génération du mouvement de base installée selon la mission passée en paramètre
*/
  procedure GenInstallationMvt(aMissionID in ASA_MISSION.ASA_MISSION_ID%type, aMovementId out ASA_INSTALLATION_MOVEMENT.ASA_INSTALLATION_MOVEMENT_ID%type)
  is
    vLangID    PAC_ADDRESS.PC_LANG_ID%type;
    vActiveMvt ASA_INSTALLATION_MOVEMENT.C_ASA_AIM_HISTORY_CODE%type;

    cursor cr_MisInfo(aASA_MISSION_ID ASA_MISSION.ASA_MISSION_ID%type)
    is
      select MIT.C_ASA_MIT_MVT_BASE
           , case
               when(MIT.C_ASA_MIT_MVT_BASE = '01') then MIS.PAC_CUSTOM_PARTNER_ID
               else MIT.PAC_CUSTOM_PARTNER_ID
             end PAC_CUSTOM_PARTNER_ID
           , case
               when(MIT.C_ASA_MIT_MVT_BASE = '01') then MIS.PAC_ADDRESS_ID
               else MIT.PAC_ADDRESS_ID
             end PAC_ADDRESS_ID
           , case
               when(MIT.C_ASA_MIT_MVT_BASE = '01') then MIS.PAC_DEPARTMENT_ID
               else MIT.PAC_DEPARTMENT_ID
             end PAC_DEPARTMENT_ID
           , MIS.ASA_MACHINE_ID
           , nvl(MIS.MIS_MOVEMENT_DATE, trunc(sysdate) ) MIS_MOVEMENT_DATE
           , MIS.MIS_LOCATION_COMMENT1
           , MIS.MIS_LOCATION_COMMENT2
        from ASA_MISSION_TYPE MIT
           , ASA_MISSION MIS
       where MIT.ASA_MISSION_TYPE_ID = MIS.ASA_MISSION_TYPE_ID
         and MIS.ASA_MISSION_ID = aASA_MISSION_ID;

    tplMisInfo cr_MisInfo%rowtype;
  begin
    -- Recherche du type de mouvement et l'installation concernée
    open cr_MisInfo(aMissionID);

    fetch cr_MisInfo
     into tplMisInfo;

    -- Si la mission provoque un mouvement de base installée
    if tplMisInfo.C_ASA_MIT_MVT_BASE <> '00' then
      -- ID du mouvement
      select init_id_seq.nextval
        into aMovementId
        from dual;

      -- Recherche du statut du nouveau mouvement en fonction de la date
      vActiveMvt  := isActiveMvt(tplMisInfo.MIS_MOVEMENT_DATE, tplMisInfo.ASA_MACHINE_ID);
      -- Recherche de la langue du client
      vLangId     := pcs.PC_I_LIB_SESSION.GetCompLangId;

      if nvl(tplMisInfo.PAC_ADDRESS_ID, 0) <> 0 then
        select PC_LANG_ID
          into vLangId
          from PAC_ADDRESS
         where PAC_ADDRESS_ID = tplMisInfo.PAC_ADDRESS_ID;
      end if;

      -- création du mouvement d'installation ou de désinstallation
      insert into ASA_INSTALLATION_MOVEMENT
                  (ASA_INSTALLATION_MOVEMENT_ID
                 , DOC_RECORD_ID
                 , ASA_MISSION_ID
                 , C_ASA_AIM_HISTORY_CODE
                 , PAC_CUSTOM_PARTNER_ID
                 , PAC_DEPARTMENT_ID
                 , PAC_ADDRESS_ID
                 , PC_APPLTXT_ID
                 , AIM_COMMENT
                 , C_ASA_GUARANTY_UNIT
                 , AIM_MOVEMENT_DATE
                 , AIM_GUARANTEE_END_DATE
                 , AIM_GUARANTEE_PERIOD
                 , AIM_LOCATION_COMMENT1
                 , AIM_LOCATION_COMMENT2
                 , A_DATECRE
                 , A_IDCRE
                  )
        select aMovementID
             , tplMisInfo.ASA_MACHINE_ID
             , aMissionID
             , vActiveMvt   -- C_ASA_AIM_HISTORY_CODE
             , tplMisInfo.PAC_CUSTOM_PARTNER_ID
             , tplMisInfo.PAC_DEPARTMENT_ID
             , tplMisInfo.PAC_ADDRESS_ID
             , MAIN.PC_APPLTXT_ID
             , MAIN.AIM_COMMENT
             , MAIN.C_ASA_GUARANTY_UNIT
             , tplMisInfo.MIS_MOVEMENT_DATE
             , case MAIN.C_ASA_GUARANTY_UNIT
                 when 'D' then tplMisInfo.MIS_MOVEMENT_DATE + MAIN.AIM_GUARANTEE_PERIOD
                 when 'M' then add_months(tplMisInfo.MIS_MOVEMENT_DATE, MAIN.AIM_GUARANTEE_PERIOD)
                 when 'W' then tplMisInfo.MIS_MOVEMENT_DATE + 7 * MAIN.AIM_GUARANTEE_PERIOD
                 when 'Y' then add_months(tplMisInfo.MIS_MOVEMENT_DATE, 12 * MAIN.AIM_GUARANTEE_PERIOD)
               end
             -- AIM_GUARANTEE_END_DATE
        ,      MAIN.AIM_GUARANTEE_PERIOD
             , tplMisInfo.MIS_LOCATION_COMMENT1
             , tplMisInfo.MIS_LOCATION_COMMENT2
             , sysdate
             , PCS.PC_I_LIB_SESSION.getUserIni
          from (select case
                         when RCO.C_ASA_MACHINE_STATE = 'NEW' then CEA.CEA_NEW_PC_APPLTXT_ID
                         else CEA.CEA_OLD_PC_APPLTXT_ID
                       end PC_APPLTXT_ID
                     , case
                         when RCO.C_ASA_MACHINE_STATE = 'NEW' then pcs.PC_FUNCTIONS.GetApplTxtDescr(CEA.CEA_NEW_PC_APPLTXT_ID, vLangId)
                         else pcs.PC_FUNCTIONS.GetAppltxtDescr(CEA.CEA_OLD_PC_APPLTXT_ID, vLangId)
                       end AIM_COMMENT
                     , case
                         when RCO.C_ASA_MACHINE_STATE = 'NEW' then CEA.C_ASA_NEW_GUARANTY_UNIT
                         else CEA.C_ASA_OLD_GUARANTY_UNIT
                       end C_ASA_GUARANTY_UNIT
                     , case
                         when RCO.C_ASA_MACHINE_STATE = 'NEW' then CEA.CEA_NEW_ITEMS_WARRANTY
                         else CEA.CEA_OLD_ITEMS_WARRANTY
                       end AIM_GUARANTEE_PERIOD
                  from ASA_MISSION MIS
                     , DOC_RECORD RCO
                     , GCO_COMPL_DATA_EXTERNAL_ASA CEA
                     , CML_POSITION CPO
                 where CEA.GCO_GOOD_ID = RCO.RCO_MACHINE_GOOD_ID
                   and RCO.DOC_RECORD_ID = MIS.ASA_MACHINE_ID
                   and MIS.ASA_MISSION_ID = aMissionId
                   and CPO.CML_POSITION_ID(+) = MIS.CML_POSITION_ID
                   and nvl(CEA.DIC_COMPLEMENTARY_DATA_ID, 0) = nvl(CPO.DIC_COMPLEMENTARY_DATA_ID, 0) ) MAIN;

      -- Mise à jour du mouvement actif
      if vActiveMvt = '1' then
        begin
          -- Vérifier que le mouvement a été créé
          select ASA_INSTALLATION_MOVEMENT_ID
            into aMovementID
            from ASA_INSTALLATION_MOVEMENT
           where ASA_INSTALLATION_MOVEMENT_ID = aMovementID;

          -- L'ancien mouvement actif passe au statut "historique"
          update ASA_INSTALLATION_MOVEMENT
             set C_ASA_AIM_HISTORY_CODE = '0'
           where C_ASA_AIM_HISTORY_CODE = '1'
             and ASA_INSTALLATION_MOVEMENT_ID <> aMovementID
             and DOC_RECORD_ID = tplMisInfo.ASA_MACHINE_ID;
        exception
          when no_data_found then
            null;
        end;
      end if;
    end if;

    close cr_MisInfo;
  end GenInstallationMvt;

/*--------------------------------------------------------------------------------------------------------------------*/
/**
* Description
*    Contrôle du mouvement actif
*/
  function isActiveMvt(aDate in date, aInstallationID in DOC_RECORD.DOC_RECORD_ID%type)
    return ASA_INSTALLATION_MOVEMENT.C_ASA_AIM_HISTORY_CODE%type
  is
    vDateRef date;
    vResult  ASA_INSTALLATION_MOVEMENT.C_ASA_AIM_HISTORY_CODE%type;
  begin
    begin
      select AIM_MOVEMENT_DATE
        into vDateRef
        from ASA_INSTALLATION_MOVEMENT
       where C_ASA_AIM_HISTORY_CODE = '1'
         and DOC_RECORD_ID = aInstallationId;

      if aDate >= vDateRef then
        vResult  := '1';
      else
        vResult  := '0';
      end if;
    exception
      when no_data_found then
        vResult  := '1';
    end;

    return vResult;
  end isActiveMvt;

/*--------------------------------------------------------------------------------------------------------------------*/
/**
* Description
*    Récupération des données de garantie de la donnée complémentaire SAV externe par défaut
*/
  procedure GetGuarantyInfo(
    aDOC_RECORD_ID          in     DOC_RECORD.DOC_RECORD_ID%type
  , aC_ASA_MACHINE_STATE    in     DOC_RECORD.C_ASA_MACHINE_STATE%type
  , aAIM_MOVEMENT_DATE      in     ASA_INSTALLATION_MOVEMENT.AIM_MOVEMENT_DATE%type
  , aPC_APPLTXT_ID          out    ASA_INSTALLATION_MOVEMENT.PC_APPLTXT_ID%type
  , aAIM_COMMENT            out    ASA_INSTALLATION_MOVEMENT.AIM_COMMENT%type
  , aC_ASA_GUARANTY_UNIT    out    ASA_INSTALLATION_MOVEMENT.C_ASA_GUARANTY_UNIT%type
  , aAIM_GUARANTEE_END_DATE out    ASA_INSTALLATION_MOVEMENT.AIM_GUARANTEE_END_DATE%type
  , aAIM_GUARANTEE_PERIOD   out    ASA_INSTALLATION_MOVEMENT.AIM_GUARANTEE_PERIOD%type
  )
  is
  begin
    select PC_APPLTXT_ID
         , AIM_COMMENT
         , C_ASA_GUARANTY_UNIT
         , trunc(case C_ASA_GUARANTY_UNIT
                   when 'D' then aAIM_MOVEMENT_DATE + AIM_GUARANTEE_PERIOD
                   when 'M' then add_months(aAIM_MOVEMENT_DATE, AIM_GUARANTEE_PERIOD)
                   when 'W' then aAIM_MOVEMENT_DATE + 7 * AIM_GUARANTEE_PERIOD
                   when 'Y' then add_months(aAIM_MOVEMENT_DATE, 12 * AIM_GUARANTEE_PERIOD)
                 end
                ) AIM_GUARANTEE_END_DATE
         , AIM_GUARANTEE_PERIOD
      into aPC_APPLTXT_ID
         , aAIM_COMMENT
         , aC_ASA_GUARANTY_UNIT
         , aAIM_GUARANTEE_END_DATE
         , aAIM_GUARANTEE_PERIOD
      from (select case
                     when aC_ASA_MACHINE_STATE = 'NEW' then CEA.CEA_NEW_PC_APPLTXT_ID
                     else CEA.CEA_OLD_PC_APPLTXT_ID
                   end PC_APPLTXT_ID
                 , case
                     when aC_ASA_MACHINE_STATE = 'NEW' then pcs.PC_FUNCTIONS.GetApplTxtDescr(CEA.CEA_NEW_PC_APPLTXT_ID, pcs.PC_I_LIB_SESSION.getUserLangID)
                     else pcs.PC_FUNCTIONS.GetAppltxtDescr(CEA.CEA_OLD_PC_APPLTXT_ID, pcs.PC_I_LIB_SESSION.getUserLangID)
                   end AIM_COMMENT
                 , case
                     when aC_ASA_MACHINE_STATE = 'NEW' then CEA.C_ASA_NEW_GUARANTY_UNIT
                     else CEA.C_ASA_OLD_GUARANTY_UNIT
                   end C_ASA_GUARANTY_UNIT
                 , case
                     when aC_ASA_MACHINE_STATE = 'NEW' then CEA.CEA_NEW_ITEMS_WARRANTY
                     else CEA.CEA_OLD_ITEMS_WARRANTY
                   end AIM_GUARANTEE_PERIOD
              from DOC_RECORD RCO
                 , GCO_COMPL_DATA_EXTERNAL_ASA CEA
             where CEA.GCO_GOOD_ID = RCO.RCO_MACHINE_GOOD_ID
               and RCO.DOC_RECORD_ID = aDOC_RECORD_ID
               and CEA.DIC_COMPLEMENTARY_DATA_ID is null);
  end GetGuarantyInfo;
end ASA_INSTALLATION_FUNCTIONS;
