--------------------------------------------------------
--  DDL for Package Body DOC_RECORD_CATEGORY_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_RECORD_CATEGORY_FUNCTIONS" 
is
  /**
  * Description
  *   Recherche une cat�gorie de dossier ainsi que le lien de cat�gorie � partir du module Affaire
  */
  procedure GetRecordCategProject(
    aProjectID            in     GAL_PROJECT.GAL_PROJECT_ID%type default null
  , aSupplyTaskID         in     GAL_TASK.GAL_TASK_ID%type default null
  , aLaborTaskID          in     GAL_TASK.GAL_TASK_ID%type default null
  , aBudgetID             in     GAL_BUDGET.GAL_BUDGET_ID%type default null
  , aTaskLinkID           in     GAL_TASK_LINK.GAL_TASK_LINK_ID%type default null
  , aRecordCategoryID     out    DOC_RECORD_CATEGORY.DOC_RECORD_CATEGORY_ID%type
  , aRecordCategoryLinkID out    DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CATEGORY_LINK_ID%type
  )
  is
    docRecordID                DOC_RECORD.DOC_RECORD_ID%type;
    cRcoType                   DOC_RECORD_CATEGORY.C_RCO_TYPE%type;
    cRcoStatus                 DOC_RECORD_CATEGORY.C_RCO_STATUS%type;
    cProjectRcoType            DOC_RECORD_CATEGORY.C_RCO_TYPE%type;
    cProjectRcoStatus          DOC_RECORD_CATEGORY.C_RCO_STATUS%type;
    docRecordCategoryID        DOC_RECORD_CATEGORY.DOC_RECORD_CATEGORY_ID%type;
    docProjectRecordCategoryID DOC_RECORD_CATEGORY.DOC_RECORD_CATEGORY_ID%type;
    docRecordCategoryLinkID    DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CATEGORY_LINK_ID%type;
    rcyKey                     DOC_RECORD_CATEGORY.RCY_KEY%type;
    rcyDescr                   DOC_RECORD_CATEGORY.RCY_DESCR%type;
  begin
    if (   aProjectID is not null
        or aSupplyTaskID is not null
        or aLaborTaskID is not null
        or aTaskLinkID is not null
        or aBudgetID is not null) then
      if aSupplyTaskID is not null then
        cRcoType    := '02';   -- T�che d'approvisionnement
        cRcoStatus  := '0';   -- Actif
        rcyKey      := PCS.PC_CONFIG.GetConfig('GAL_RECORD_CAT_KEY_SUPPLY_TASK');
        rcyDescr    := 'T�che d''approvisionnement affaire';
      elsif aLaborTaskID is not null then
        cRcoType    := '03';   -- T�che de main d'oeuvre
        cRcoStatus  := '0';   -- Actif
        rcyKey      := PCS.PC_CONFIG.GetConfig('GAL_RECORD_CAT_KEY_LABOR_TASK');
        rcyDescr    := 'T�che de main d''oeuvre affaire';
      elsif aBudgetID is not null then
        cRcoType    := '04';   -- Code de budget
        cRcoStatus  := '0';   -- Actif
        rcyKey      := PCS.PC_CONFIG.GetConfig('GAL_RECORD_CATEG_KEY_BUDGET');
        rcyDescr    := 'Code budget affaire';
      elsif aTaskLinkID is not null then
        cRcoType    := '05';   -- op�ration externe
        cRcoStatus  := '0';   -- Actif
        rcyKey      := PCS.PC_CONFIG.GetConfig('GAL_RECORD_CATEG_KEY_TASK_LINK');
        rcyDescr    := 'Op�ration externe';
      elsif aProjectID is not null then
        cRcoType    := '01';   -- Affaire
        cRcoStatus  := '0';   -- Actif
        rcyKey      := PCS.PC_CONFIG.GetConfig('GAL_RECORD_CATEG_KEY_PROJECT');
        rcyDescr    := 'Affaire';
      end if;

      -- V�rifie l'existence d'une cat�gorie de dossier associ� au dossier en cours de cr�ation
      begin
        select DOC_RECORD_CATEGORY_ID
          into docRecordCategoryID
          from DOC_RECORD_CATEGORY
         where C_RCO_TYPE = cRcoType;
      exception
        when no_data_found then
          docRecordCategoryID  := null;
      end;

      -- Aucune categorie de dossier existante pour le type de dossier � cr�er. On cr�� la cat�gorie selon les
      -- configurations suivantes :
      --
      --   GAL_RECORD_CATEG_KEY_PROJECT pour les affaires
      --   GAL_RECORD_CAT_KEY_SUPPLY_TASK pour les t�ches d'approvisionnement
      --   GAL_RECORD_CAT_KEY_LABOR_TASK pour les t�ches de main-d'oeuvre
      --   GAL_RECORD_CATEG_KEY_BUDGET pour les code budget
      --
      if docRecordCategoryID is null then
        select INIT_ID_SEQ.nextval
          into docRecordCategoryID
          from dual;

        insert into DOC_RECORD_CATEGORY
                    (DOC_RECORD_CATEGORY_ID
                   , RCY_KEY
                   , RCY_DESCR
                   , C_RCO_STATUS
                   , C_RCO_TYPE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (docRecordCategoryID   -- DOC_RECORD_CATEGORY_ID
                   , rcyKey   -- RCY_KEY
                   , rcyDescr   -- RCY_DESCR
                   , cRcoStatus   -- C_RCO_STATUS
                   , cRcoType   -- C_RCO_TYPE
                   , sysdate   -- A_DATECRE
                   , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                    );

        -- Si la cat�gorie de dossier qui vient d'�tre cr�� n'est pas de type Affaire, il faut v�rifier que la
        -- cat�gorie du dossier affaire existe. Si elle n'existe pas, on la cr��. Si elle existe, on effectue
        -- le lien entre la cat�gorie Affaire et la cat�gorie fille (t�che d'appro. ou code budget).
        --
        if cRcoType <> '01' then
          -- V�rifie l'existence de la cat�gorie de dossier de type Affaire associ� au dossier en cours de cr�ation
          begin
            select DOC_RECORD_CATEGORY_ID
              into docProjectRecordCategoryID
              from DOC_RECORD_CATEGORY
             where C_RCO_TYPE = '01';
          exception
            when no_data_found then
              docProjectRecordCategoryID  := null;
          end;

          if docProjectRecordCategoryID is null then
            select INIT_ID_SEQ.nextval
              into docProjectRecordCategoryID
              from dual;

            cProjectRcoType    := '01';   -- Affaire
            cProjectRcoStatus  := '0';   -- Actif
            rcyKey             := PCS.PC_CONFIG.GetConfig('GAL_RECORD_CATEG_KEY_PROJECT');
            rcyDescr           := PCS.PC_FUNCTIONS.TranslateWord('Affaire');

            insert into DOC_RECORD_CATEGORY
                        (DOC_RECORD_CATEGORY_ID
                       , RCY_KEY
                       , RCY_DESCR
                       , C_RCO_STATUS
                       , C_RCO_TYPE
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (docProjectRecordCategoryID   -- DOC_RECORD_CATEGORY_ID
                       , rcyKey   -- RCY_KEY
                       , rcyDescr   -- RCY_DESCR
                       , cProjectRcoStatus   -- C_RCO_STATUS
                       , cProjectRcoType   -- C_RCO_TYPE
                       , sysdate   -- A_DATECRE
                       , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                        );
          end if;
        end if;
      elsif cRcoType <> '01' then
        -- V�rifie l'existence de la cat�gorie de dossier de type Affaire associ� au dossier en cours de cr�ation
        begin
          --if cRcoType IN ('02','03','04') then
          select DOC_RECORD_CATEGORY_ID
            into docProjectRecordCategoryID
            from DOC_RECORD_CATEGORY
           where C_RCO_TYPE = '01';
        --end if;
        /*
        if cRcoType = '05' then
              select DOC_RECORD_CATEGORY_ID
                into docProjectRecordCategoryID
                from DOC_RECORD_CATEGORY
               where C_RCO_TYPE = '02';
        end if;
        */
        exception
          when no_data_found then
            docProjectRecordCategoryID  := null;
        end;
      end if;

      if     docRecordCategoryID is not null
         and docProjectRecordCategoryID is not null then
        -- Recherche un lien entre cat�gorie de dossier � partir du module Affaire
        docRecordCategoryLinkID  :=
                    GetRecordCategLinkProject(aProjectID, aSupplyTaskID, aLaborTaskID, aBudgetID, aTaskLinkID, docProjectRecordCategoryID, docRecordCategoryID);
      end if;
    end if;

    aRecordCategoryID      := docRecordCategoryID;
    aRecordCategoryLinkID  := docRecordCategoryLinkID;
  end GetRecordCategProject;

  /**
  * function GetRecordCategLinkProject
  * Description
  *   Recherche un lien entre cat�gorie de dossier � partir du module Affaire
  * @created VJ 21.03.2005
  */
  function GetRecordCategLinkProject(
    aProjectID         in GAL_PROJECT.GAL_PROJECT_ID%type default null
  , aSupplyTaskID      in GAL_TASK.GAL_TASK_ID%type default null
  , aLaborTaskID       in GAL_TASK.GAL_TASK_ID%type default null
  , aBudgetID          in GAL_BUDGET.GAL_BUDGET_ID%type default null
  , aTaskLinkID        in GAL_TASK_LINK.GAL_TASK_LINK_ID%type default null
  , aRecordCatFather   in DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CAT_FATHER_ID%type
  , aRecordCatDaughter in DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CAT_DAUGHTER_ID%type
  )
    return DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CATEGORY_LINK_ID%type
  is
  begin
    return GetRecordCategLinkProject(aProjectID, aSupplyTaskID, aLaborTaskID, aBudgetID, aTaskLinkID, null, aRecordCatFather, aRecordCatDaughter);
  end GetRecordCategLinkProject;

  /**
  * function GetRecordCategLinkProject
  * Description
  *   Recherche un lien entre cat�gorie de dossier � partir du module Affaire
  * @created VJ 21.03.2005
  */
  function GetRecordCategLinkProject(
    aProjectID         in GAL_PROJECT.GAL_PROJECT_ID%type default null
  , aSupplyTaskID      in GAL_TASK.GAL_TASK_ID%type default null
  , aLaborTaskID       in GAL_TASK.GAL_TASK_ID%type default null
  , aBudgetID          in GAL_BUDGET.GAL_BUDGET_ID%type default null
  , aTaskLinkID        in GAL_TASK_LINK.GAL_TASK_LINK_ID%type default null
  , aDocumentID        in DOC_RECORD.DOC_RECORD_ID%type default null
  , aRecordCatFather   in DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CAT_FATHER_ID%type
  , aRecordCatDaughter in DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CAT_DAUGHTER_ID%type
  )
    return DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CATEGORY_LINK_ID%type
  is
    docRecordCategoryLinkID     DOC_RECORD_CATEGORY_LINK.DOC_RECORD_CATEGORY_LINK_ID%type;
    docRecordCategoryLinkTypeID DOC_RECORD_CAT_LINK_TYPE.DOC_RECORD_CAT_LINK_TYPE_ID%type;
    cRcoLinkCode                DOC_RECORD_CATEGORY_LINK.C_RCO_LINK_CODE%type;
  begin
    if (   aProjectID is not null
        or aSupplyTaskID is not null
        or aLaborTaskID is not null
        or aTaskLinkID is not null
        or aBudgetID is not null
        or aDocumentID is not null
       ) then
      if aSupplyTaskID is not null then
        cRcoLinkCode  := 'AFAP';   -- Affaire - T�che d�appro
      elsif aLaborTaskID is not null then
        cRcoLinkCode  := 'AFMO';   -- Affaire - T�che de main d�oeuvre
      elsif aBudgetID is not null then
        cRcoLinkCode  := 'AFCB';   -- Affaire - Code de budget
      elsif aTaskLinkID is not null then
        cRcoLinkCode  := 'AFOP';   -- Affaire - op�ration externe
      elsif aDocumentID is not null then
        cRcoLinkCode  := 'CDAF';   -- Commande - Affaire
      elsif aProjectID is not null then
        cRcoLinkCode  := null;   -- pas g�r�
      end if;

      -- V�rifie l'existence d'une cat�gorie de dossier associ� au dossier en cours de cr�ation
      begin
        select DOC_RECORD_CATEGORY_LINK_ID
          into docRecordCategoryLinkID
          from DOC_RECORD_CATEGORY_LINK
         where DOC_RECORD_CAT_FATHER_ID = aRecordCatFather
           and DOC_RECORD_CAT_DAUGHTER_ID = aRecordCatDaughter;
      exception
        when no_data_found then
          docRecordCategoryLinkID  := null;
      end;

      -- Aucun lien entre categorie de dossier existant pour le type de dossier � cr�er. On cr�� le lien de cat�gorie
      if docRecordCategoryLinkID is null then
        -- Recherche du type de lien entre cat�gorie de dossier � partir du module Affaire
        docRecordCategoryLinkTypeID  := GetRecordCategLinkTypeProject(aProjectID, aSupplyTaskID, aLaborTaskID, aBudgetID, aTaskLinkID, aDocumentID);

        select INIT_ID_SEQ.nextval
          into docRecordCategoryLinkID
          from dual;

        insert into DOC_RECORD_CATEGORY_LINK
                    (DOC_RECORD_CATEGORY_LINK_ID
                   , DOC_RECORD_CAT_LINK_TYPE_ID
                   , DOC_RECORD_CAT_FATHER_ID
                   , DOC_RECORD_CAT_DAUGHTER_ID
                   , C_RCO_LINK_TYPE
                   , C_RCO_LINK_CODE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (docRecordCategoryLinkID   -- DOC_RECORD_CATEGORY_LINK_ID
                   , docRecordCategoryLinkTypeID   -- DOC_RECORD_CAT_LINK_TYPE_ID
                   , aRecordCatFather   -- DOC_RECORD_CAT_FATHER_ID
                   , aRecordCatDaughter   -- DOC_RECORD_CAT_DAUGHTER_ID
                   , '1'   -- C_RCO_LINK_TYPE
                   , cRcoLinkCode   -- C_RCO_LINK_CODE
                   , sysdate   -- A_DATECRE
                   , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                    );
      end if;
    end if;

    return docRecordCategoryLinkID;
  end GetRecordCategLinkProject;

  /**
  * function GetRecordCategLinkTypeProject
  * Description
  *   Recherche du type de lien entre cat�gorie de dossier � partir du module Affaire
  * @created VJ 22.03.2005
  */
  function GetRecordCategLinkTypeProject(
    aProjectID    in GAL_PROJECT.GAL_PROJECT_ID%type default null
  , aSupplyTaskID in GAL_TASK.GAL_TASK_ID%type default null
  , aLaborTaskID  in GAL_TASK.GAL_TASK_ID%type default null
  , aBudgetID     in GAL_BUDGET.GAL_BUDGET_ID%type default null
  , aTaskLinkID   in GAL_TASK_LINK.GAL_TASK_LINK_ID%type default null
  , aDocumentID   in DOC_RECORD.DOC_RECORD_ID%type default null
  )
    return DOC_RECORD_CAT_LINK_TYPE.DOC_RECORD_CAT_LINK_TYPE_ID%type
  is
    rltDescr                    DOC_RECORD_CAT_LINK_TYPE.RLT_DESCR%type;
    rltDownwardSemantic         DOC_RECORD_CAT_LINK_TYPE.RLT_DOWNWARD_SEMANTIC%type;
    rltUpwardSemantic           DOC_RECORD_CAT_LINK_TYPE.RLT_UPWARD_SEMANTIC%type;
    docRecordCategoryLinkTypeID DOC_RECORD_CAT_LINK_TYPE.DOC_RECORD_CAT_LINK_TYPE_ID%type;
  begin
    if (   aProjectID is not null
        or aSupplyTaskID is not null
        or aLaborTaskID is not null
        or aTaskLinkID is not null
        or aBudgetID is not null
        or aDocumentID is not null
       ) then
      if aSupplyTaskID is not null then
        rltDescr             := 'Affaire - T�che d''approvisionnement';
        rltDownwardSemantic  := 'Contient';
        rltUpwardSemantic    := 'Est li� �';
      elsif aLaborTaskID is not null then
        rltDescr             := 'Affaire - T�che de main d''oeuvre';
        rltDownwardSemantic  := 'Contient';
        rltUpwardSemantic    := 'Est li� �';
      elsif aBudgetID is not null then
        rltDescr             := 'Affaire - Code de budget';
        rltDownwardSemantic  := 'Contient';
        rltUpwardSemantic    := 'Est li� �';
      elsif aTaskLinkID is not null then
        rltDescr             := 'Affaire - Op�ration externe';
        rltDownwardSemantic  := 'Contient';
        rltUpwardSemantic    := 'Est li� �';
      elsif aDocumentID is not null then
        rltDescr             := 'Commande - Affaire';
        rltDownwardSemantic  := 'Contient';
        rltUpwardSemantic    := 'Est li� �';
      elsif aProjectID is not null then
        rltDescr             := 'Non g�r�';
        rltDownwardSemantic  := 'Non g�r�';
        rltUpwardSemantic    := 'Non g�r�';
      end if;

      -- V�rifie l'existence d'un type de lien de cat�gorie de dossier en fonction des param�tres
      begin
        select DOC_RECORD_CAT_LINK_TYPE_ID
          into docRecordCategoryLinkTypeID
          from DOC_RECORD_CAT_LINK_TYPE
         where RLT_DESCR = rltDescr;
      exception
        when no_data_found then
          docRecordCategoryLinkTypeID  := null;
      end;

      -- Aucun lien entre categorie de dossier existant pour le type de dossier � cr�er. On cr�� le lien de cat�gorie
      if docRecordCategoryLinkTypeID is null then
        select INIT_ID_SEQ.nextval
          into docRecordCategoryLinkTypeID
          from dual;

        insert into DOC_RECORD_CAT_LINK_TYPE
                    (DOC_RECORD_CAT_LINK_TYPE_ID
                   , RLT_DESCR
                   , RLT_DOWNWARD_SEMANTIC
                   , RLT_UPWARD_SEMANTIC
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (docRecordCategoryLinkTypeID   -- DOC_RECORD_CAT_LINK_TYPE_ID
                   , rltDescr   -- RLT_DESCR
                   , rltDownwardSemantic   -- RLT_DOWNWARD_SEMANTIC
                   , rltUpwardSemantic   -- RLT_UPWARD_SEMANTIC
                   , sysdate   -- A_DATECRE
                   , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                    );
      end if;
    end if;

    return docRecordCategoryLinkTypeID;
  end GetRecordCategLinkTypeProject;
end DOC_RECORD_CATEGORY_FUNCTIONS;
