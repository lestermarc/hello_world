--------------------------------------------------------
--  DDL for Package Body WFL_ATTRIBUTES_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WFL_ATTRIBUTES_FUNCTIONS" 
is
  --Constantes pour le type d'attributs
  AttrTypeProcess  constant varchar2(10) := 'PROC_ATTR';
  AttrTypeActivity constant varchar2(10) := 'ACT_ATTR';

  /*************** InitProcessAttributes *************************************/
  procedure InitProcessAttributes(aProcInstId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
  is
    cursor crProcAttributes(aProcInstId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
    is
      select ATT.WFL_ATTRIBUTES_ID
           , ATT.ATT_NAME
        from WFL_ATTRIBUTES ATT
           , WFL_PROCESS_INSTANCES PRI
       where ATT.WFL_PROCESSES_ID = PRI.WFL_PROCESSES_ID
         and PRI.WFL_PROCESS_INSTANCES_ID = aProcInstId;

    tplProcAttributes crProcAttributes%rowtype;
  begin
    --récupération des attributs pour l'instance de process et initialisation
    open crProcAttributes(aProcInstId);

    fetch crProcAttributes
     into tplProcAttributes;

    if crProcAttributes%found then
      while(crProcAttributes%found) loop
        --initialisation des attributs du process
        WFL_ATTRIBUTES_FUNCTIONS.InitAttributeInst(aAttributeId     => tplProcAttributes.WFL_ATTRIBUTES_ID
                                                 , aAttributeName   => tplProcAttributes.ATT_NAME
                                                 , aProcInstId      => aProcInstId
                                                  );

        fetch crProcAttributes
         into tplProcAttributes;
      end loop;
    end if;

    close crProcAttributes;
  end InitProcessAttributes;

  /*************** InitAttributeInst *****************************************/
  procedure InitAttributeInst(
    aAttributeId   in WFL_ATTRIBUTE_INSTANCES.WFL_ATTRIBUTES_ID%type
  , aAttributeName in WFL_ATTRIBUTES.ATT_NAME%type
  , aProcInstId    in WFL_ATTRIBUTE_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  )
  is
    cSysAttrId     WFL_PROCESS_INSTANCES.PRI_REC_ID%type;
    cSysTabName    WFL_PROCESS_INSTANCES.PRI_TABNAME%type;
    cAttTableName  PCS.PC_TABLE.TABNAME%type;
    cAttFieldName  PCS.PC_FLDSC.FLDNAME%type;
    cAttFieldValue WFL_ATTRIBUTE_INSTANCES.ATI_VALUE%type;
  begin
    --récupération valeur attribut système et nom attribut
    select PRI_REC_ID
         , PRI_TABNAME
      into cSysAttrId
         , cSysTabName
      from WFL_PROCESS_INSTANCES
     where WFL_PROCESS_INSTANCES_ID = aProcInstId;

    --mise à jour de la valeur de l'attribut
    cAttTableName   := substr(aAttributeName, 0, instr(aAttributeName, '.', 1, 1) - 1);
    cAttFieldName   := substr(aAttributeName, instr(aAttributeName, '.', 1, 1) + 1, length(aAttributeName) );
    cAttFieldValue  :=
      GetAttributeValue(aAttTableName    => cAttTableName
                      , aAttFieldName    => cAttFieldName
                      , aSysFieldName    => cSysTabName || '_ID'
                      , aSysFieldValue   => cSysAttrId
                       );

    if cAttFieldValue is not null then
      --insert ou update attributs
      WFL_WORKFLOW_MANAGEMENT.AssignProcessInstanceAttribute(aProcessInstanceId   => aProcInstId
                                                           , aAttributeName       => aAttributeName
                                                           , aAttributeValue      => cAttFieldValue
                                                            );
    end if;
  exception
    when no_data_found then
      null;
  end InitAttributeInst;

  /*************** GetAttributeValue *****************************************/
  function GetAttributeValue(
    aAttTableName  in PCS.PC_TABLE.TABNAME%type
  , aAttFieldName  in PCS.PC_FLDSC.FLDNAME%type
  , aSysFieldName  in PCS.PC_FLDSC.FLDNAME%type
  , aSysFieldValue in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  )
    return WFL_ATTRIBUTE_INSTANCES.ATI_VALUE%type
  is
    result WFL_ATTRIBUTE_INSTANCES.ATI_VALUE%type;
  begin
    execute immediate 'select ' ||
                      aAttFieldName ||
                      ' from   ' ||
                      aAttTableName ||
                      ' where  ' ||
                      aSysFieldName ||
                      ' = ' ||
                      aSysFieldValue
                 into result;

    return result;
  exception
    when no_data_found then
      return null;
    when others then
      return null;
  end GetAttributeValue;

  /*************** AddShowAttribute ******************************************/
  procedure AddShowProcessAttribute(
    aAttributeId in WFL_ATTRIBUTES.WFL_ATTRIBUTES_ID%type
  , aActivityId  in WFL_ACT_ATTRIBUTES_SHOW.WFL_ACTIVITIES_ID%type
  , aVisible     in WFL_ACT_ATTRIBUTES_SHOW.WAA_VISIBLE%type
  , aEditable    in WFL_ACT_ATTRIBUTES_SHOW.WAA_EDITABLE%type
  , aRequired    in WFL_ACT_ATTRIBUTES_SHOW.WAA_REQUIRED%type
  )
  is
  begin
    --merge pour insérer dans la table des attributs affichés
    merge into WFL_ACT_ATTRIBUTES_SHOW WAA
      using (select aAttributeId WFL_ATTRIBUTES_ID
                  , aActivityId WFL_ACTIVITIES_ID
                  , aVisible WAA_VISIBLE
                  , aEditable WAA_EDITABLE
                  , aRequired WAA_REQUIRED
               from dual) SEL
      on (    WAA.WFL_ATTRIBUTES_ID = SEL.WFL_ATTRIBUTES_ID
          and WAA.WFL_ACTIVITIES_ID = SEL.WFL_ACTIVITIES_ID
          and WAA.C_WFL_ACT_ATTRIB_TYPE = AttrTypeProcess)
      when matched then
        --mise à jour des propriétés
    update
           set WAA.WAA_VISIBLE = SEL.WAA_VISIBLE, WAA.WAA_EDITABLE = SEL.WAA_EDITABLE
             , WAA.WAA_REQUIRED = SEL.WAA_REQUIRED, WAA.A_DATEMOD = sysdate, WAA.A_IDMOD = PCS.PC_PUBLIC.GetUserIni
      when not matched then
        insert(WAA.WFL_ACT_ATTRIBUTES_SHOW_ID, WAA.WFL_ATTRIBUTES_ID, WAA.WFL_ACTIVITIES_ID, WAA.C_WFL_ACT_ATTRIB_TYPE
             , WAA.WAA_VISIBLE, WAA.WAA_EDITABLE, WAA.WAA_REQUIRED, WAA.A_DATECRE, WAA.A_IDCRE)
        values(INIT_ID_SEQ.nextval, SEL.WFL_ATTRIBUTES_ID, SEL.WFL_ACTIVITIES_ID, AttrTypeProcess, SEL.WAA_VISIBLE
             , SEL.WAA_EDITABLE, SEL.WAA_REQUIRED, sysdate, PCS.PC_PUBLIC.GetUserIni);
  end AddShowProcessAttribute;

  procedure AddShowActivityAttribute(
    aAttributeId in WFL_ACTIVITY_ATTRIBUTES.WFL_ACTIVITY_ATTRIBUTES_ID%type
  , aActivityId  in WFL_ACT_ATTRIBUTES_SHOW.WFL_ACTIVITIES_ID%type
  , aVisible     in WFL_ACT_ATTRIBUTES_SHOW.WAA_VISIBLE%type
  , aEditable    in WFL_ACT_ATTRIBUTES_SHOW.WAA_EDITABLE%type
  , aRequired    in WFL_ACT_ATTRIBUTES_SHOW.WAA_REQUIRED%type
  )
  is
  begin
    --merge pour insérer dans la table des attributs affichés
    merge into WFL_ACT_ATTRIBUTES_SHOW WAA
      using (select aAttributeId WFL_ACTIVITY_ATTRIBUTES_ID
                  , aActivityId WFL_ACTIVITIES_ID
                  , aVisible WAA_VISIBLE
                  , aEditable WAA_EDITABLE
                  , aRequired WAA_REQUIRED
               from dual) SEL
      on (    WAA.WFL_ACTIVITY_ATTRIBUTES_ID = SEL.WFL_ACTIVITY_ATTRIBUTES_ID
          and WAA.WFL_ACTIVITIES_ID = SEL.WFL_ACTIVITIES_ID
          and WAA.C_WFL_ACT_ATTRIB_TYPE = AttrTypeActivity)
      when matched then
        --mise à jour des propriétés
    update
           set WAA.WAA_VISIBLE = SEL.WAA_VISIBLE, WAA.WAA_EDITABLE = SEL.WAA_EDITABLE
             , WAA.WAA_REQUIRED = SEL.WAA_REQUIRED, WAA.A_DATEMOD = sysdate, WAA.A_IDMOD = PCS.PC_PUBLIC.GetUserIni
      when not matched then
        insert(WAA.WFL_ACT_ATTRIBUTES_SHOW_ID, WAA.WFL_ACTIVITY_ATTRIBUTES_ID, WAA.WFL_ACTIVITIES_ID
             , WAA.C_WFL_ACT_ATTRIB_TYPE, WAA.WAA_VISIBLE, WAA.WAA_EDITABLE, WAA.WAA_REQUIRED, WAA.A_DATECRE
             , WAA.A_IDCRE)
        values(INIT_ID_SEQ.nextval, SEL.WFL_ACTIVITY_ATTRIBUTES_ID, SEL.WFL_ACTIVITIES_ID, AttrTypeActivity
             , SEL.WAA_VISIBLE, SEL.WAA_EDITABLE, SEL.WAA_REQUIRED, sysdate, PCS.PC_PUBLIC.GetUserIni);
  end AddShowActivityAttribute;

  /*************** InsertTmpInstanceAttributes *******************************/
  procedure InsertTmpAttributes(aActivityInstanceId in WFL_TMP_INST_ATTRIBUTES.WFL_ACTIVITY_INSTANCES_ID%type)
  is
    --curseur pour recherche des attributs d'activité et de process
    cursor crAttributes(aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    is
      select AIN.WFL_PROCESS_INSTANCES_ID
           , AIN.WFL_ACTIVITY_INSTANCES_ID
           , null as WFL_ATTRIBUTES_ID
           , ACA.WFL_ACTIVITY_ATTRIBUTES_ID
           , WAA.C_WFL_ACT_ATTRIB_TYPE
           , ACA.C_WFL_DATA_TYPE
           , ACA.ACA_NAME as WTI_NAME
           , AAI.AAI_VALUE as WTI_VALUE
           , nvl(AAD.AAD_DESCRIPTION, ACA.ACA_DESCRIPTION) as WTI_DESCRIPTION
           , WAA.WAA_VISIBLE as WTI_VISIBLE
           , WAA.WAA_EDITABLE as WTI_EDITABLE
           , WAA.WAA_REQUIRED as WTI_REQUIRED
           , ACA.ACA_LENGTH as WTI_LENGTH
        from WFL_ACTIVITY_INSTANCES AIN
           , WFL_ACTIVITY_ATTRIBUTES ACA
           , WFL_ACTIVITY_ATTRIBUTES_DESCR AAD
           , WFL_ACT_ATTRIBUTE_INSTANCES AAI
           , WFL_ACT_ATTRIBUTES_SHOW WAA
       where WAA.WFL_ACTIVITIES_ID = AIN.WFL_ACTIVITIES_ID
         and WAA.C_WFL_ACT_ATTRIB_TYPE = 'ACT_ATTR'
         and WAA.WFL_ACTIVITY_ATTRIBUTES_ID = AAI.WFL_ACTIVITY_ATTRIBUTES_ID
         and AAI.WFL_ACTIVITY_INSTANCES_ID = AIN.WFL_ACTIVITY_INSTANCES_ID
         and ACA.WFL_ACTIVITY_ATTRIBUTES_ID = AAI.WFL_ACTIVITY_ATTRIBUTES_ID
         and AAD.WFL_ACTIVITY_ATTRIBUTES_ID(+) = ACA.WFL_ACTIVITY_ATTRIBUTES_ID
         and AAD.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId
         and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
      union all
      select AIN.WFL_PROCESS_INSTANCES_ID
           , AIN.WFL_ACTIVITY_INSTANCES_ID
           , ATT.WFL_ATTRIBUTES_ID
           , null as WFL_ACTIVITY_ATTRIBUTES_ID
           , WAA.C_WFL_ACT_ATTRIB_TYPE
           , ATT.C_WFL_DATA_TYPE
           , ATT.ATT_NAME as WTI_NAME
           , ATI.ATI_VALUE as WTI_VALUE
           , nvl(ATD.ATD_DESCRIPTION, ATT.ATT_DESCRIPTION) as WTI_DESCRIPTION
           , WAA.WAA_VISIBLE as WTI_VISIBLE
           , WAA.WAA_EDITABLE as WTI_EDITABLE
           , WAA.WAA_REQUIRED as WTI_REQUIRED
           , ATT.ATT_LENGTH as WTI_LENGTH
        from WFL_ACTIVITY_INSTANCES AIN
           , WFL_ATTRIBUTES ATT
           , WFL_ATTRIBUTES_DESCR ATD
           , WFL_ATTRIBUTE_INSTANCES ATI
           , WFL_ACT_ATTRIBUTES_SHOW WAA
       where WAA.WFL_ACTIVITIES_ID = AIN.WFL_ACTIVITIES_ID
         and WAA.C_WFL_ACT_ATTRIB_TYPE = 'PROC_ATTR'
         and WAA.WFL_ATTRIBUTES_ID = ATI.WFL_ATTRIBUTES_ID
         and ATI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
         and ATT.WFL_ATTRIBUTES_ID = ATI.WFL_ATTRIBUTES_ID
         and ATD.WFL_ATTRIBUTES_ID(+) = ATT.WFL_ATTRIBUTES_ID
         and ATD.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId
         and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    tplAttributes crAttributes%rowtype;
  begin
    --suppression des éléments de la table temporaire
    delete from WFL_TMP_INST_ATTRIBUTES;

    for tplAttributes in crAttributes(aActivityInstanceId => aActivityInstanceId) loop
      --insertion des éléments dans la table temporaire
      insert into WFL_TMP_INST_ATTRIBUTES
                  (WFL_PROCESS_INSTANCES_ID
                 , WFL_ACTIVITY_INSTANCES_ID
                 , WFL_ATTRIBUTES_ID
                 , WFL_ACTIVITY_ATTRIBUTES_ID
                 , C_WFL_ACT_ATTRIB_TYPE
                 , C_WFL_DATA_TYPE
                 , WTI_NAME
                 , WTI_VALUE
                 , WTI_DESCRIPTION
                 , WTI_VISIBLE
                 , WTI_EDITABLE
                 , WTI_REQUIRED
                 , WTI_LENGTH
                  )
           values (tplAttributes.WFL_PROCESS_INSTANCES_ID
                 , tplAttributes.WFL_ACTIVITY_INSTANCES_ID
                 , tplAttributes.WFL_ATTRIBUTES_ID
                 , tplAttributes.WFL_ACTIVITY_ATTRIBUTES_ID
                 , tplAttributes.C_WFL_ACT_ATTRIB_TYPE
                 , tplAttributes.C_WFL_DATA_TYPE
                 , tplAttributes.WTI_NAME
                 , tplAttributes.WTI_VALUE
                 , tplAttributes.WTI_DESCRIPTION
                 , tplAttributes.WTI_VISIBLE
                 , tplAttributes.WTI_EDITABLE
                 , tplAttributes.WTI_REQUIRED
                 , tplAttributes.WTI_LENGTH
                  );
    end loop;
  end InsertTmpAttributes;

  /*************** UpdateInstAttributes **************************************/
  procedure UpdateInstAttributes
  is
    --curseur pour parcourir les attributs selon le type
    cursor crTmpAttributes(aAttribType in WFL_TMP_INST_ATTRIBUTES.C_WFL_ACT_ATTRIB_TYPE%type)
    is
      select WFL_PROCESS_INSTANCES_ID
           , WFL_ACTIVITY_INSTANCES_ID
           , WFL_ATTRIBUTES_ID
           , WFL_ACTIVITY_ATTRIBUTES_ID
           , WTI_VALUE
        from WFL_TMP_INST_ATTRIBUTES
       where C_WFL_ACT_ATTRIB_TYPE = aAttribType;

    tplTmpAttributes crTmpAttributes%rowtype;
  begin
    --parcours et mise à jour attributs d'activités
    for tplTmpAttributes in crTmpAttributes(aAttribType => 'ACT_ATTR') loop
      update WFL_ACT_ATTRIBUTE_INSTANCES
         set AAI_VALUE = tplTmpAttributes.WTI_VALUE
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_PUBLIC.GetUserIni
       where WFL_ACTIVITY_ATTRIBUTES_ID = tplTmpAttributes.WFL_ACTIVITY_ATTRIBUTES_ID
         and WFL_ACTIVITY_INSTANCES_ID = tplTmpAttributes.WFL_ACTIVITY_INSTANCES_ID;
    end loop;

    --parcours et mise à jour attributs de process
    for tplTmpAttributes in crTmpAttributes(aAttribType => 'PROC_ATTR') loop
      update WFL_ATTRIBUTE_INSTANCES
         set ATI_VALUE = tplTmpAttributes.WTI_VALUE
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_PUBLIC.GetUserIni
       where WFL_ATTRIBUTES_ID = tplTmpAttributes.WFL_ATTRIBUTES_ID
         and WFL_PROCESS_INSTANCES_ID = tplTmpAttributes.WFL_PROCESS_INSTANCES_ID;
    end loop;
  end UpdateInstAttributes;

  /*************** EvalActAttribute ******************************************/
  function EvalActAttribute(
    aActivityInstanceId in WFL_ACT_ATTRIBUTE_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aAttributeName      in WFL_ACTIVITY_ATTRIBUTES.ACA_NAME%type
  , aAttributeValue     in WFL_ACT_ATTRIBUTE_INSTANCES.AAI_VALUE%type
  , aOperator           in varchar2
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result number;
  begin
    execute immediate 'select SUM(YesNo)
       from   (select 1 as YesNo
               from   WFL_ACTIVITY_ATTRIBUTES ACA,
                      WFL_ACT_ATTRIBUTE_INSTANCES AAI
               where  AAI.WFL_ACTIVITY_ATTRIBUTES_ID = ACA.WFL_ACTIVITY_ATTRIBUTES_ID and
                      AAI.WFL_ACTIVITY_INSTANCES_ID = :ACT_INST_ID and
                      ACA.ACA_NAME = ' ||
                      aAttributeName ||
                      ' and
                      AAI.AAI_VALUE ' ||
                      aOperator ||
                      ' ' ||
                      aAttributeValue ||
                      ')'
                 into result
                using aActivityInstanceId;

    if result > 0 then
      return 1;
    else
      return 0;
    end if;
  end EvalActAttribute;

  /*************** EvalProcAttribute *****************************************/
  function EvalProcAttribute(
    aProcessInstanceId in WFL_ATTRIBUTE_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aAttributeName     in WFL_ATTRIBUTES.ATT_NAME%type
  , aAttributeValue    in WFL_ATTRIBUTE_INSTANCES.ATI_VALUE%type
  , aOperator          in varchar2
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result number;
  begin
    execute immediate 'select SUM(YesNo)
       from   (select 1 as YesNo
               from   WFL_ATTRIBUTES ATT,
                      WFL_ATTRIBUTE_INSTANCES ATI
               where  ATI.WFL_ATTRIBUTES_ID = ATT.WFL_ATTRIBUTES_ID and
                      ATI.WFL_PROCESS_INSTANCES_ID = :PROC_INST_ID and
                      ATT.ATT_NAME = ' ||
                      aAttributeName ||
                      ' and
                      ATI.ATI_VALUE ' ||
                      aOperator ||
                      ' ' ||
                      aAttributeValue ||
                      ')'
                 into result
                using aProcessInstanceId;

    if result > 0 then
      return 1;
    else
      return 0;
    end if;
  end EvalProcAttribute;
end WFL_ATTRIBUTES_FUNCTIONS;
