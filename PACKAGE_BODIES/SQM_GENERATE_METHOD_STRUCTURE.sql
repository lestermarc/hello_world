--------------------------------------------------------
--  DDL for Package Body SQM_GENERATE_METHOD_STRUCTURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_GENERATE_METHOD_STRUCTURE" 
is
  procedure GenerateStructure(pMethodId in SQM_EVALUATION_METHOD.SQM_EVALUATION_METHOD_ID%type, pLevel in SQM_EVAL_METHOD_STRUCTURE.EMS_LEVEL%type)
  is
    strMacro     SQM_EVALUATION_METHOD.EME_MACRO%type;
    strSubMacro  SQM_EVALUATION_METHOD.EME_MACRO%type;
    intLevel     SQM_EVAL_METHOD_STRUCTURE.EMS_LEVEL%type;
    intIndex     number;
    vSubMethodId SQM_EVALUATION_METHOD.SQM_EVALUATION_METHOD_ID%type;
  begin
    select upper(EME_MACRO)
      into strMacro
      from SQM_EVALUATION_METHOD
     where SQM_EVALUATION_METHOD_ID = pMethodId;

    intIndex     := 1;
    -- Parse de la macro
    strSubMacro  := GetSubMacro(strMacro, intIndex);

    while strSubMacro is not null loop
      intIndex     := intIndex + 1;

      -- Recherche de la méthode appelée
      select SQM_EVALUATION_METHOD_ID
        into vSubMethodId
        from SQM_EVALUATION_METHOD
       where EME_CODE = strSubMacro;

      -- Contrôle l'existence de cette macro à un niveau inférieur de la structure de la macro principale
      begin
        select EMS_LEVEL
          into intLevel
          from SQM_EVAL_METHOD_STRUCTURE
         where SQM_SQM_EVALUATION_METHOD_ID = vSubMethodId
           and SQM_EVALUATION_METHOD_ID = MainMethodId;
      exception
        when no_data_found then
          intLevel  := null;
      end;

      if intLevel is null then
        insert into SQM_EVAL_METHOD_STRUCTURE
                    (SQM_EVAL_METHOD_STRUCTURE_ID
                   , SQM_EVALUATION_METHOD_ID
                   , SQM_SQM_EVALUATION_METHOD_ID
                   , EMS_LEVEL
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (init_id_seq.nextval
                   , MainMethodId
                   , vSubMethodId
                   , pLevel
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      else
        if intLevel < pLevel then
          update SQM_EVAL_METHOD_STRUCTURE
             set EMS_LEVEL = pLevel
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where SQM_EVALUATION_METHOD_ID = MainMethodId
             and SQM_SQM_EVALUATION_METHOD_ID = vSubMethodId;
        end if;
      end if;

      -- Génère les niveaux inférieurs de la structure
      GenerateStructure(vSubMethodId, pLevel + 1);
      strSubMacro  := GetSubMacro(strMacro, intIndex);
    end loop;
  end GenerateStructure;

/*-----------------------------------------------------------------------------------*/
  function GetSubMacro(pMacro in SQM_EVALUATION_METHOD.EME_MACRO%type, pIndex number)
    return SQM_EVALUATION_METHOD.EME_MACRO%type
  is
    strSubMacro SQM_EVALUATION_METHOD.EME_MACRO%type;
  begin
    strSubMacro  := null;

    if instr(pMacro, ']', 1, pIndex) > 0 then
      strSubMacro  := substr(pMacro, instr(pMacro, '[', 1, pIndex), instr(pMacro, ']', 1, pIndex) - instr(pMacro, '[', 1, pIndex) + 1);
      strSubMacro  := replace(strSubMacro, '[', '');
      strSubMacro  := replace(strSubMacro, ']', '');
    end if;

    return strSubMacro;
  end GetSubMacro;

/*-----------------------------------------------------------------------------------*/
  procedure InitStructure(pMethodId in SQM_EVALUATION_METHOD.SQM_EVALUATION_METHOD_ID%type)
  is
  begin
    -- Suppression de la structure de la méthode en cours de modification
    delete from SQM_EVAL_METHOD_STRUCTURE
          where SQM_EVALUATION_METHOD_ID = pMethodId;

    MainMethodId  := pMethodId;
    -- Génération des niveaux inférieurs par récurrence
    GenerateStructure(pMethodId, 1);

    -- Génération du dernier niveau
    insert into SQM_EVAL_METHOD_STRUCTURE
                (SQM_EVAL_METHOD_STRUCTURE_ID
               , SQM_EVALUATION_METHOD_ID
               , SQM_SQM_EVALUATION_METHOD_ID
               , EMS_LEVEL
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , pMethodId
               , pMethodId
               , 0
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end InitStructure;
end SQM_GENERATE_METHOD_STRUCTURE;
