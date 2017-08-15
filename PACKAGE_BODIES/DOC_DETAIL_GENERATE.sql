--------------------------------------------------------
--  DDL for Package Body DOC_DETAIL_GENERATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DETAIL_GENERATE" 
is
  /**
  *  procedure GenerateDetail
  *  Description
  *    Méthode générale pour la création d'un ou plusieurs détail(s) de position
  */
  procedure GenerateDetail(
    aDetailID          in out DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aPositionID        in     DOC_POSITION_DETAIL.DOC_POSITION_ID%type
  , aPdeCreateMode     in     varchar2 default null
  , aPdeCreateType     in     varchar2 default null
  , aSrcPositionID     in     DOC_POSITION.DOC_POSITION_ID%type default null
  , aSrcDetailID       in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  , aTmpPdeID          in     DOC_TMP_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  , aQuantity          in     DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type default null
  , aQuantitySU        in     DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY_SU%type default null
  , aBalanceQty        in     DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type default null
  , aBasisDelay        in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type default null
  , aInterDelay        in     DOC_POSITION_DETAIL.PDE_INTERMEDIATE_DELAY%type default null
  , aFinalDelay        in     DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type default null
  , aLocationID        in     DOC_POSITION_DETAIL.STM_LOCATION_ID%type default null
  , aTraLocationID     in     DOC_POSITION_DETAIL.STM_STM_LOCATION_ID%type default null
  , aCharactValue_1    in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type default null
  , aCharactValue_2    in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_2%type default null
  , aCharactValue_3    in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_3%type default null
  , aCharactValue_4    in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_4%type default null
  , aCharactValue_5    in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_5%type default null
  , aInterfaceID       in     DOC_INTERFACE.DOC_INTERFACE_ID%type default null
  , aInterfacePosID    in     DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type default null
  , aInterfacePosNbr   in     DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type default null
  , aFalScheduleStepID in     DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type default null
  , aRecordID          in     DOC_POSITION_DETAIL.DOC_RECORD_ID%type default null
  , aLitigID           in     DOC_LITIG.DOC_LITIG_ID%type default null
  , aDebug             in     number default 1
  , aUserInitProc      in     varchar2 default null
  )
  is
    errorMsg varchar2(2000);
  begin
    GenerateDetail(aDetailID            => aDetailID
                 , aErrorMsg            => errorMsg
                 , aPositionID          => aPositionID
                 , aPdeCreateMode       => aPdeCreateMode
                 , aPdeCreateType       => aPdeCreateType
                 , aSrcPositionID       => aSrcPositionID
                 , aSrcDetailID         => aSrcDetailID
                 , aTmpPdeID            => aTmpPdeID
                 , aQuantity            => aQuantity
                 , aQuantitySU          => aQuantitySU
                 , aBalanceQty          => aBalanceQty
                 , aBasisDelay          => aBasisDelay
                 , aInterDelay          => aInterDelay
                 , aFinalDelay          => aFinalDelay
                 , aLocationID          => aLocationID
                 , aTraLocationID       => aTraLocationID
                 , aCharactValue_1      => aCharactValue_1
                 , aCharactValue_2      => aCharactValue_2
                 , aCharactValue_3      => aCharactValue_3
                 , aCharactValue_4      => aCharactValue_4
                 , aCharactValue_5      => aCharactValue_5
                 , aInterfaceID         => aInterfaceID
                 , aInterfacePosID      => aInterfacePosID
                 , aInterfacePosNbr     => aInterfacePosNbr
                 , aFalScheduleStepID   => aFalScheduleStepID
                 , aRecordID            => aRecordID
                 , aLitigID             => aLitigID
                 , aDebug               => aDebug
                 , aUserInitProc        => aUserInitProc
                  );
  end GenerateDetail;

  /**
  *  procedure GenerateDetail
  *  Description
  *    Méthode générale pour la création d'un ou plusieurs détail(s) de position
  */
  procedure GenerateDetail(
    aDetailID          in out DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aErrorMsg          out    varchar2
  , aPositionID        in     DOC_POSITION_DETAIL.DOC_POSITION_ID%type
  , aPdeCreateMode     in     varchar2 default null
  , aPdeCreateType     in     varchar2 default null
  , aSrcPositionID     in     DOC_POSITION.DOC_POSITION_ID%type default null
  , aSrcDetailID       in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  , aTmpPdeID          in     DOC_TMP_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  , aQuantity          in     DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type default null
  , aQuantitySU        in     DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY_SU%type default null
  , aBalanceQty        in     DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type default null
  , aBasisDelay        in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type default null
  , aInterDelay        in     DOC_POSITION_DETAIL.PDE_INTERMEDIATE_DELAY%type default null
  , aFinalDelay        in     DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type default null
  , aLocationID        in     DOC_POSITION_DETAIL.STM_LOCATION_ID%type default null
  , aTraLocationID     in     DOC_POSITION_DETAIL.STM_STM_LOCATION_ID%type default null
  , aCharactValue_1    in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type default null
  , aCharactValue_2    in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_2%type default null
  , aCharactValue_3    in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_3%type default null
  , aCharactValue_4    in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_4%type default null
  , aCharactValue_5    in     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_5%type default null
  , aInterfaceID       in     DOC_INTERFACE.DOC_INTERFACE_ID%type default null
  , aInterfacePosID    in     DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type default null
  , aInterfacePosNbr   in     DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type default null
  , aFalScheduleStepID in     DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type default null
  , aRecordID          in     DOC_POSITION_DETAIL.DOC_RECORD_ID%type default null
  , aLitigID           in     DOC_LITIG.DOC_LITIG_ID%type default null
  , aDebug             in     number default 1
  , aUserInitProc      in     varchar2 default null
  )
  is
    iIndex                      integer;
    vCode                       number(3);
    SrcPosConvertFactor         DOC_POSITION.POS_CONVERT_FACTOR%type;
    TgtPosConvertFactor         DOC_POSITION.POS_CONVERT_FACTOR%type;
    SrcGestDelay                integer;
    TgtPosValueQty              DOC_POSITION.POS_VALUE_QUANTITY%type;
    SrcDocumentID               DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    SrcPdeBalanceQty            DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type;
    SrcSumPdeBalQty             DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type;
    BalanceQuantityParentSource DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY_PARENT%type;
    BalanceQuantityParentTarget DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY_PARENT%type;
  begin
    -- Vérifier que l'utilisateur ne nous ai pas passé plus qu'un record dans la table de records
    if DOC_DETAIL_INITIALIZE.DetailsInfo.count > 1 then
      RAISE_APPLICATION_ERROR(-20000, PCS.PC_FUNCTIONS.TranslateWord('Initialisation de plusieurs détails - Cette fonctionnalité n''est pas supportée !') );
    end if;

    -- Récuperer l'indice du premier élement du tableau
    if DOC_DETAIL_INITIALIZE.DetailsInfo.count = 0 then
      -- L'utilisateur n'a pas initialisé le tableau
      iIndex                                                            := 1;
      -- En affectant une valeur à un champs quelconque du record on provoque la création du premier record
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_POSITION_DETAIL_ID  := null;
    else
      -- Reprend l'indice de l'utilisateur
      iIndex  := DOC_DETAIL_INITIALIZE.DetailsInfo.first;

      -- Réinitialise les données de la variable globale contenant les infos pour la création de la position
      if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).CLEAR_DETAIL_INFO = 1 then
        declare
          tmpDetailInfo DOC_DETAIL_INITIALIZE.TDetailInfo;
        begin
          DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex)  := tmpDetailInfo;
        end;
      end if;
    end if;

    -- Récupérer le variables passées en param par rapport au type de création
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).C_PDE_CREATE_MODE              := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).C_PDE_CREATE_MODE, aPdeCreateMode);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).CREATE_TYPE                    :=
                                                                              upper(nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).CREATE_TYPE, aPdeCreateType) );

    -- Code de création
    begin
      vCode  := to_number(nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).C_PDE_CREATE_MODE, '0') );
    exception
      when others then
        vCode  := 0;
    end;

    -- Création -> codes 100 ... 199
    if vCode between 100 and 199 then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).CREATE_TYPE  := 'INSERT';
    -- Copie -> codes 200 ... 299
    elsif vCode between 200 and 299 then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).CREATE_TYPE  := 'COPY';
    -- Décharge -> codes 300 ... 399
    elsif vCode between 300 and 399 then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).CREATE_TYPE  := 'DISCHARGE';
    end if;

    -- La copie/décharge directe du détail est interdite, on doit passer par la position
    if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).CREATE_TYPE = 'COPY' then
      RAISE_APPLICATION_ERROR(-20000, PCS.PC_FUNCTIONS.TranslateWord('Copie du détail - Cette fonctionnalité n''est pas supportée !') );
    elsif DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).CREATE_TYPE = 'DISCHARGE' then
      RAISE_APPLICATION_ERROR(-20000, PCS.PC_FUNCTIONS.TranslateWord('Décharge du détail - Cette fonctionnalité n''est pas supportée !') );
    end if;

    -- Récupérer le variables passées en param si on n'ont pas encore été
    -- initialisées avant l'appel de la procédure GenerateDetail
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_POSITION_DETAIL_ID         := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_POSITION_DETAIL_ID, aDetailID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_POSITION_ID                := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_POSITION_ID, aPositionID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).SOURCE_DOC_POSITION_ID         :=
                                                                           nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).SOURCE_DOC_POSITION_ID, aSrcPositionID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).SOURCE_DOC_POSITION_DETAIL_ID  :=
                                                                      nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).SOURCE_DOC_POSITION_DETAIL_ID, aSrcDetailID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_TMP_PDE_ID                 := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_TMP_PDE_ID, aTmpPdeID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_INTERFACE_POSITION_ID      :=
                                                                       nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_INTERFACE_POSITION_ID, aInterfacePosID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BASIS_QUANTITY             := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BASIS_QUANTITY, aQuantity);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BASIS_QUANTITY_SU          :=
                                                                               nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BASIS_QUANTITY_SU, aQuantitySU);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BALANCE_QUANTITY           := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BALANCE_QUANTITY, aBalanceQty);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BASIS_DELAY                := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BASIS_DELAY, aBasisDelay);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_INTERMEDIATE_DELAY         :=
                                                                              nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_INTERMEDIATE_DELAY, aInterDelay);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_FINAL_DELAY                := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_FINAL_DELAY, aFinalDelay);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).STM_LOCATION_ID                := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).STM_LOCATION_ID, aLocationID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).STM_STM_LOCATION_ID            :=
                                                                              nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).STM_STM_LOCATION_ID, aTraLocationID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_1   :=
                                                                    nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_1, aCharactValue_1);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_2   :=
                                                                    nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_2, aCharactValue_2);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_3   :=
                                                                    nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_3, aCharactValue_3);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_4   :=
                                                                    nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_4, aCharactValue_4);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_5   :=
                                                                    nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_5, aCharactValue_5);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).FAL_SCHEDULE_STEP_ID           :=
                                                                         nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).FAL_SCHEDULE_STEP_ID, aFalScheduleStepID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_RECORD_ID                  := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_RECORD_ID, aRecordID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_INTERFACE_ID               := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_INTERFACE_ID, aInterfaceID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_INTERFACE_POSITION_ID      :=
                                                                       nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_INTERFACE_POSITION_ID, aInterfacePosID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOP_POS_NUMBER                 := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOP_POS_NUMBER, aInterfacePosNbr);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_LITIG_ID                   := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_LITIG_ID, aLitigID);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).A_DEBUG                        := nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).A_DEBUG, aDebug);
    DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USER_INIT_PROCEDURE            :=
                                                                               nvl(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USER_INIT_PROCEDURE, aUserInitProc);

    -- Utilisation de la Qté passée en param si pas null
    if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BASIS_QUANTITY is not null then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USE_PDE_BASIS_QUANTITY  := 1;
    end if;

    -- Utilisation de la Qté solde passée en param si pas null
    if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BALANCE_QUANTITY is not null then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USE_PDE_BALANCE_QUANTITY  := 1;
    end if;

    -- Utilisation des délais passés en param si pas null
    if    (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_BASIS_DELAY is not null)
       or (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_INTERMEDIATE_DELAY is not null)
       or (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_FINAL_DELAY is not null) then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USE_DELAY  := 1;
    end if;

    -- Utilisation de l'emplacement passé en param si pas null
    if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).STM_LOCATION_ID is not null then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USE_STM_LOCATION_ID  := 1;
    end if;

    -- Utilisation de l'emplacement de transfert passé en param si pas null
    if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).STM_STM_LOCATION_ID is not null then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USE_STM_STM_LOCATION_ID  := 1;
    end if;

    -- Utilisation des valeurs de caractérisation passées en param si pas null
    if    (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_1 is not null)
       or (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_2 is not null)
       or (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_3 is not null)
       or (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_4 is not null)
       or (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).PDE_CHARACTERIZATION_VALUE_5 is not null) then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USE_CHARACTERIZATION_VALUES  := 1;
    end if;

    -- Utilisation dU Lien tâche passé en param si pas null
    if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).FAL_SCHEDULE_STEP_ID is not null then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USE_FAL_SCHEDULE_STEP_ID  := 1;
    end if;

    -- Utilisation du Dossier (Installation) passé en param si pas null
    if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_RECORD_ID is not null then
      DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USE_DOC_RECORD_ID  := 1;
    end if;

    -- Rechercher l'id du gabarit pour un éventuel appel d'une procédure indiv d'initialisation
    select DMT.DOC_GAUGE_ID
      into DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_GAUGE_ID
      from DOC_DOCUMENT DMT
         , DOC_POSITION POS
     where DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       and POS.DOC_POSITION_ID = aPositionID;

    -- Seule l'insertion est gérée au niveau du détail.
    -- Pour la copie/décharge, il faut passer par la position
    if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).CREATE_TYPE = 'INSERT' then
      -- Initialisation des données à inserer de la table de records TDetailInfo
      if    (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).C_PDE_CREATE_MODE is not null)
         or (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).USER_INIT_PROCEDURE is not null) then
        DOC_DETAIL_INITIALIZE.CallInitProc;
      end if;

      -- Contrôle et insertion
      if DOC_DETAIL_INITIALIZE.DetailsInfo.count > 0 then
        -- Contrôle des données
        declare
          vBinIndex binary_integer := DOC_DETAIL_INITIALIZE.DetailsInfo.first;
        begin
          loop
            exit when vBinIndex is null;
            ControlInitDetailData(DOC_DETAIL_INITIALIZE.DetailsInfo(vBinIndex) );

            -- Vérifier s'il ny a pas eu d'erreur lors de la vérification des données
            -- Arrêter l'execution de cette procédure si code d'erreur
            if DOC_DETAIL_INITIALIZE.DetailsInfo(vBinIndex).A_ERROR = 1 then
              aErrorMsg  := DOC_DETAIL_INITIALIZE.DetailsInfo(vBinIndex).A_ERROR_MESSAGE;

              if DOC_DETAIL_INITIALIZE.DetailsInfo(vBinIndex).A_DEBUG = 1 then
                raise_application_error(-20000, DOC_DETAIL_INITIALIZE.DetailsInfo(vBinIndex).A_ERROR_MESSAGE);
              else
                return;
              end if;
            end if;

            vBinIndex  := DOC_DETAIL_INITIALIZE.DetailsInfo.next(vBinIndex);
          end loop;
        end;

        -- Insertion des détails dans la table DOC_POSITION_DETAIL
        for iIndex in DOC_DETAIL_INITIALIZE.DetailsInfo.first .. DOC_DETAIL_INITIALIZE.DetailsInfo.last loop
          InsertDetail(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex) );
          -- Récupere l'ID du détail créé
          aDetailID  := DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_POSITION_DETAIL_ID;

          -- Si ce détail est issu de la création d'une position litige,
          -- màj du lien sur litige
          if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_LITIG_ID is not null then
            -- Màj du lien détail final sur le litige
            DOC_LITIG_FUNCTIONS.UpdateLitigFinalPdeID(aLitigID => DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_LITIG_ID, aDetailFinalID => aDetailID);
          end if;

          -- Si le produit fabriqué est renseigné
          --  ET que l'on est en Sous-traitance d'achat
          -- lancer le traitement de la création de l'OF
          if     (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).GCO_MANUFACTURED_GOOD_ID is not null)
             and (DOC_LIB_SUBCONTRACTP.IsGaugeSubcontractP(DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_GAUGE_ID) = 1)
             and (DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).FAL_LOT_ID is null) then
            declare
              lvDocLotType DOC_POSITION.C_DOC_LOT_TYPE%type;
              vLotId       FAL_LOT.FAL_LOT_ID%type;
              vError       varchar2(4000);
            begin
              -- Rechercher le type de Gestion de lot sur la position
              select nvl(max(C_DOC_LOT_TYPE), '-1')
                into lvDocLotType
                from DOC_POSITION
               where DOC_POSITION_ID = aPositionID;

              -- Création de l'OF s'il s'agit d'un lot de sous-traitance d'achat
              if lvDocLotType = '001' then
                -- Création de l'OF
                -- Le champ FAL_LOT_ID du détail est màj dans la méthode
                FAL_PRC_SUBCONTRACTP.GenerateBatch(iPositionDetailId   => aDetailID
                                                 , oLotId              => vLotId
                                                 , oError              => DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).A_ERROR_MESSAGE
                                                  );

                -- Erreur durant la création de l'OF
                if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).A_ERROR_MESSAGE is not null then
                  aErrorMsg  := DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).A_ERROR_MESSAGE;

                  if DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).A_DEBUG = 1 then
                    raise_application_error(-20000, DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).A_ERROR_MESSAGE);
                  else
                    return;
                  end if;
                else
                  -- Recalcul du prix de la position en fonction de la création du lot
                  DOC_POSITION_FUNCTIONS.ReinitPositionPrice(aPositionId => DOC_DETAIL_INITIALIZE.DetailsInfo(iIndex).DOC_POSITION_ID);
                end if;
              end if;
            end;
          end if;
        end loop;
      end if;
    end if;

    -- Effacer les données du record
    DOC_DETAIL_INITIALIZE.DetailsInfo.delete;
  exception
    when others then
      -- Effacer les données du record
      DOC_DETAIL_INITIALIZE.DetailsInfo.delete;
      PCS.RA(sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  end GenerateDetail;

  /**
  *  procedure ControlInitDetailData
  *  Description
  *    Contrôle les données et si besoin initialise avant l'insertion même dans la table DOC_POSITION_DETAIL
  */
  procedure ControlInitDetailData(aDetailInfo in out DOC_DETAIL_INITIALIZE.TDetailInfo)
  is
    cursor crPdeInfo(PositionID DOC_POSITION.DOC_POSITION_ID%type)
    is
      select POS.DOC_POSITION_ID
           , POS.POS_BASIS_QUANTITY
           , POS.POS_BASIS_QUANTITY_SU
           , POS.POS_NET_UNIT_VALUE
           , POS.POS_NET_VALUE_EXCL
           , POS.POS_UNIT_COST_PRICE
           , POS.POS_CONVERT_FACTOR
           , POS.C_GAUGE_TYPE_POS
           , POS.STM_MOVEMENT_KIND_ID
           , POS.GCO_GOOD_ID
           , POS.STM_STOCK_ID
           , POS.STM_STM_STOCK_ID
           , POS.STM_LOCATION_ID
           , POS.STM_STM_LOCATION_ID
           , POS.GCO_MANUFACTURED_GOOD_ID
           , POS.GCO_COMPL_DATA_ID
           , POS.FAL_LOT_ID
           , DMT.PAC_THIRD_ID
           , DMT.PAC_THIRD_ACI_ID
           , DMT.PAC_THIRD_DELIVERY_ID
           , DMT.PAC_THIRD_TARIFF_ID
           , DMT.PAC_THIRD_CDA_ID
           , DMT.PAC_THIRD_VAT_ID
           , DMT.DOC_DOCUMENT_ID
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , DMT.DMT_DATE_DOCUMENT
           , GAU.C_ADMIN_DOMAIN
           , GAU.DOC_GAUGE_ID
           , GAU.C_GAUGE_TYPE
           , GAS.GAS_BALANCE_STATUS
           , GAS.GAS_CHARACTERIZATION
           , GAS.GAS_ALL_CHARACTERIZATION
           , GAP.GAP_VALUE
           , GAP.GAP_STOCK_MVT
           , GAP.GAP_MVT_UTILITY
           , GAP.DIC_DELAY_UPDATE_TYPE_ID
           , GAP.GAP_DELAY
           , GAP.C_GAUGE_SHOW_DELAY
           , GAP.GAP_POS_DELAY
           , GAP.GAP_DELAY_COPY_PREV_POS
           , GAP.C_SQM_EVAL_TYPE
           , GAP.GAP_TRANSFERT_PROPRIETOR
           , nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) GOO_NUMBER_OF_DECIMAL
           , nvl(GCO_LIB_COMPL_DATA.GetCDADecimal(POS.GCO_GOOD_ID
                                                , case GAU.C_ADMIN_DOMAIN
                                                    when '1' then 'PURCHASE'
                                                    when '2' then 'SALE'
                                                    when '5' then 'PURCHASE'
                                                    else ''   -- Autres -> nombre de décimal du bien
                                                  end
                                                , DMT.PAC_THIRD_CDA_ID
                                                 )
               , 0
                ) CDA_DECIMAL
        from DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE_POSITION GAP
           , GCO_GOOD GOO
       where POS.DOC_POSITION_ID = PositionID
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+);

    tplPdeInfo           crPdeInfo%rowtype;
    vBasisDelayMW        varchar2(10);
    vInterDelayMW        varchar2(10);
    vFinalDelayMW        varchar2(10);
    vUnitPrice           DOC_POSITION.POS_NET_UNIT_VALUE%type;
    vMovementSort        STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    vCharacType1         GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    vCharacType2         GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    vCharacType3         GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    vCharacType4         GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    vCharacType5         GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    vChar1Value          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    vChar2Value          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_2%type;
    vChar3Value          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_3%type;
    vChar4Value          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_4%type;
    vChar5Value          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_5%type;
    vStmStmMvtKindID     STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    vDOC_DOC_POSITION_ID DOC_POSITION.DOC_POSITION_ID%type;
    vBasisQuantity       DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type;
    vForceDetailUnitQty  number(1)                                               default 0;
    vIndex               binary_integer;
  begin
    if aDetailInfo.DOC_POSITION_ID is null then
      -- Arrêter l'execution de cette procédure
      aDetailInfo.A_ERROR          := 1;
      aDetailInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création du détail - L''ID de la position est manquant !');
      return;
    end if;

    open crPdeInfo(aDetailInfo.DOC_POSITION_ID);

    fetch crPdeInfo
     into tplPdeInfo;

    close crPdeInfo;

    -- ID du détail
    if aDetailInfo.DOC_POSITION_DETAIL_ID is null then
      select INIT_ID_SEQ.nextval
        into aDetailInfo.DOC_POSITION_DETAIL_ID
        from dual;
    end if;

    -- ID document
    aDetailInfo.DOC_DOCUMENT_ID           := tplPdeInfo.DOC_DOCUMENT_ID;
    -- ID bien
    aDetailInfo.GCO_GOOD_ID               := tplPdeInfo.GCO_GOOD_ID;
    -- ID partenaire donneur d'ordre
    aDetailInfo.PAC_THIRD_ID              := tplPdeInfo.PAC_THIRD_ID;
    -- ID partenaire facturation
    aDetailInfo.PAC_THIRD_ACI_ID          := tplPdeInfo.PAC_THIRD_ACI_ID;
    -- ID partenaire livraison
    aDetailInfo.PAC_THIRD_DELIVERY_ID     := tplPdeInfo.PAC_THIRD_DELIVERY_ID;
    -- ID partenaire tarification
    aDetailInfo.PAC_THIRD_TARIFF_ID       := tplPdeInfo.PAC_THIRD_TARIFF_ID;
    -- ID gabarit
    aDetailInfo.DOC_GAUGE_ID              := tplPdeInfo.DOC_GAUGE_ID;
    -- Partenaire données compl.
    aDetailInfo.PAC_THIRD_CDA_ID          := tplPdeInfo.PAC_THIRD_CDA_ID;
    -- Partenaire TVA
    aDetailInfo.PAC_THIRD_VAT_ID          := tplPdeInfo.PAC_THIRD_VAT_ID;
    -- ID du produit fabriqué
    aDetailInfo.GCO_MANUFACTURED_GOOD_ID  := tplPdeInfo.GCO_MANUFACTURED_GOOD_ID;
    -- ID du lot de fabrication
    aDetailInfo.FAL_LOT_ID                := tplPdeInfo.FAL_LOT_ID;

    -- Ne pas effectuer les inits/contrôles pour les positions de type 4,5 et 6
    if to_number(tplPdeInfo.C_GAUGE_TYPE_POS) not in(4, 5, 6) then
      -- Recherche des ID de caractérisation
      if    (tplPdeInfo.GAS_CHARACTERIZATION = 1)
         or (tplPdeInfo.STM_MOVEMENT_KIND_ID is not null) then
        -- Recherche le genre de mouvement selon l'ID du type de mouvement
        if tplPdeInfo.STM_MOVEMENT_KIND_ID is not null then
          select max(C_MOVEMENT_SORT)
            into vMovementSort
            from STM_MOVEMENT_KIND
           where STM_MOVEMENT_KIND_ID = tplPdeInfo.STM_MOVEMENT_KIND_ID;
        else
          vMovementSort  := '';

          /* Gestion des caractérisations non morphologique dans les documents sans
             mouvements de stock. On recherche le type de mouvement en fonction du
             domaine. */
          if     (tplPdeInfo.GAS_ALL_CHARACTERIZATION = 1)
             and (PCS.PC_CONFIG.GetConfig('DOC_CHARACTERIZATION_MODE') = '1') then
            if tplPdeInfo.C_ADMIN_DOMAIN in('1', '5') then   /* Achat, Sous-Traitance */
              vMovementSort  := 'ENT';
            elsif tplPdeInfo.C_ADMIN_DOMAIN in('2', '7') then   /* Vente, SAV */
              vMovementSort  := 'SOR';
            end if;
          end if;
        end if;
      end if;

      -- Quantité en unité du document
      if     (aDetailInfo.USE_PDE_BASIS_QUANTITY = 0)
         and (nvl(aDetailInfo.PDE_BASIS_QUANTITY, 0) = 0)
         and (nvl(aDetailInfo.PDE_BASIS_QUANTITY_SU, 0) = 0) then
        -- Si aucune quantité n'est spécifiée, on utilise les quantités de la position.
        aDetailInfo.USE_PDE_BASIS_QUANTITY  := 1;
        aDetailInfo.PDE_BASIS_QUANTITY      := tplPdeInfo.POS_BASIS_QUANTITY;
        aDetailInfo.PDE_BASIS_QUANTITY_SU   := tplPdeInfo.POS_BASIS_QUANTITY_SU;
      elsif     (aDetailInfo.USE_PDE_BASIS_QUANTITY = 0)
            and (nvl(aDetailInfo.PDE_BASIS_QUANTITY_SU, 0) <> 0)
            and (nvl(aDetailInfo.PDE_BASIS_QUANTITY, 0) = 0) then
        -- Si uniquement la quantité en unité de stockage est spécifié, on recalcul la quantité en unité document à l'aide du facteur de conversion
        -- de la position.
        aDetailInfo.USE_PDE_BASIS_QUANTITY  := 1;
        -- Calcul la quantité en fonction de l'unité et la précision de la donnée complémentaire avec un arrondi supérieure.
        aDetailInfo.PDE_BASIS_QUANTITY      :=
                   ACS_FUNCTION.RoundNear(aDetailInfo.PDE_BASIS_QUANTITY_SU / tplPdeInfo.POS_CONVERT_FACTOR, 1 / power(10, nvl(tplPdeInfo.CDA_DECIMAL, 0) ), 1);
      elsif aDetailInfo.USE_PDE_BASIS_QUANTITY = 0 then
        -- Dans tous les autres cas, la quantité en unité de stockage est calculé en fonction du facteur de conversion de la position.
        aDetailInfo.USE_PDE_BASIS_QUANTITY  := 1;
        aDetailInfo.PDE_BASIS_QUANTITY      := tplPdeInfo.POS_BASIS_QUANTITY;
        -- Calcul la quantité en unité de stockage avec arrondi au plus près en fonction du nombre de décimales du bien.
        aDetailInfo.PDE_BASIS_QUANTITY_SU   := round(aDetailInfo.PDE_BASIS_QUANTITY * tplPdeInfo.POS_CONVERT_FACTOR, tplPdeInfo.GOO_NUMBER_OF_DECIMAL);
      else
        -- Calcul la quantité en unité de stockage avec arrondi au plus près en fonction du nombre de décimales du bien.
        aDetailInfo.PDE_BASIS_QUANTITY_SU  := round(aDetailInfo.PDE_BASIS_QUANTITY * tplPdeInfo.POS_CONVERT_FACTOR, tplPdeInfo.GOO_NUMBER_OF_DECIMAL);
      end if;

      -- Vérifier si le détail doit avoir une qté unitaire et que la qté passée en param est > 1
      if     (DOC_POSITION_DETAIL_FUNCTIONS.ForceDetailUnitQty(aDetailInfo.DOC_POSITION_ID) = 1)
         and (aDetailInfo.PDE_BASIS_QUANTITY > 1) then
        vForceDetailUnitQty                := 1;
        vBasisQuantity                     := aDetailInfo.PDE_BASIS_QUANTITY;
        aDetailInfo.PDE_BASIS_QUANTITY     := 1;
        aDetailInfo.PDE_BASIS_QUANTITY_SU  := 1;
      end if;

      -- Attribution
      if aDetailInfo.USE_FAL_NETWORK_LINK_ID = 0 then
        aDetailInfo.USE_FAL_NETWORK_LINK_ID  := 1;
        aDetailInfo.FAL_NETWORK_LINK_ID      := null;
      end if;

      -- Lien tâche
      if aDetailInfo.USE_FAL_SCHEDULE_STEP_ID = 0 then
        aDetailInfo.USE_FAL_SCHEDULE_STEP_ID  := 1;
        aDetailInfo.FAL_SCHEDULE_STEP_ID      := null;
      end if;

      -- Demandes d'Approvisionnement
      if aDetailInfo.USE_FAL_SUPPLY_REQUEST_ID = 0 then
        aDetailInfo.USE_FAL_SUPPLY_REQUEST_ID  := 1;
        aDetailInfo.FAL_SUPPLY_REQUEST_ID      := null;
      end if;

      -- Dossier (Installation)
      if aDetailInfo.USE_DOC_RECORD_ID = 0 then
        aDetailInfo.USE_DOC_RECORD_ID  := 1;
        aDetailInfo.DOC_RECORD_ID      := null;
      end if;

      -- Quantité soldée sur parent
      aDetailInfo.PDE_BALANCE_QUANTITY_PARENT   := 0;
      -- Quantités intermédiaire et finale
      aDetailInfo.PDE_INTERMEDIATE_QUANTITY     := aDetailInfo.PDE_BASIS_QUANTITY;
      aDetailInfo.PDE_FINAL_QUANTITY            := aDetailInfo.PDE_BASIS_QUANTITY;
      -- Quantités intermédiaire et finale en unité de stockage
      aDetailInfo.PDE_INTERMEDIATE_QUANTITY_SU  := aDetailInfo.PDE_BASIS_QUANTITY_SU;
      aDetailInfo.PDE_FINAL_QUANTITY_SU         := aDetailInfo.PDE_BASIS_QUANTITY_SU;

      -- Qté solde
      if aDetailInfo.USE_PDE_BALANCE_QUANTITY = 0 then
        aDetailInfo.USE_PDE_BALANCE_QUANTITY  := 1;

        -- Gabarit avec statut à solder
        if tplPdeInfo.GAS_BALANCE_STATUS = 1 then
          aDetailInfo.PDE_BALANCE_QUANTITY  := aDetailInfo.PDE_BASIS_QUANTITY;
        else
          aDetailInfo.PDE_BALANCE_QUANTITY  := 0;
        end if;
      end if;

      -- Quantité Mouvement
      if     (tplPdeInfo.STM_MOVEMENT_KIND_ID is not null)
         and (to_number(tplPdeInfo.C_GAUGE_TYPE_POS) in(1, 2, 3, 7, 8, 71, 81, 91, 101) ) then
        aDetailInfo.PDE_MOVEMENT_QUANTITY  := aDetailInfo.PDE_FINAL_QUANTITY_SU;
      else
        aDetailInfo.PDE_MOVEMENT_QUANTITY  := 0;
      end if;

      -- Valeur Mouvement
      if     (tplPdeInfo.STM_MOVEMENT_KIND_ID is not null)
         and (tplPdeInfo.GAP_STOCK_MVT = 1)
         and (to_number(tplPdeInfo.C_GAUGE_TYPE_POS) in(1, 2, 3, 7, 8, 71, 81, 91, 101) ) then
        -- Domaine Vente
        if (tplPdeInfo.C_ADMIN_DOMAIN = '2') then
          -- En vente, si installation init sur le détail reprendre le prix de revient de l'installation
          if (aDetailInfo.DOC_RECORD_ID is not null) then
            select nvl(RCO_COST_PRICE, tplPdeInfo.POS_UNIT_COST_PRICE) * aDetailInfo.PDE_FINAL_QUANTITY_SU
              into aDetailInfo.PDE_MOVEMENT_VALUE
              from DOC_RECORD
             where DOC_RECORD_ID = aDetailInfo.DOC_RECORD_ID;
          else
            aDetailInfo.PDE_MOVEMENT_VALUE  := tplPdeInfo.POS_UNIT_COST_PRICE * aDetailInfo.PDE_FINAL_QUANTITY_SU;
          end if;
        -- Domaine Stock
        elsif(tplPdeInfo.C_ADMIN_DOMAIN = '3') then
          aDetailInfo.PDE_MOVEMENT_VALUE  := tplPdeInfo.POS_UNIT_COST_PRICE * aDetailInfo.PDE_FINAL_QUANTITY_SU;
        else
          if aDetailInfo.PDE_FINAL_QUANTITY = 0 then
            vUnitPrice  := tplPdeInfo.POS_NET_UNIT_VALUE;
          else
            vUnitPrice  := tplPdeInfo.POS_NET_UNIT_VALUE * aDetailInfo.PDE_FINAL_QUANTITY_SU;
          end if;

          if tplPdeInfo.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId then
            aDetailInfo.PDE_MOVEMENT_VALUE  := vUnitPrice;
          else
            aDetailInfo.PDE_MOVEMENT_VALUE  :=
              ACS_FUNCTION.ConvertAmountForView(vUnitPrice
                                              , tplPdeInfo.ACS_FINANCIAL_CURRENCY_ID
                                              , ACS_FUNCTION.GetLocalCurrencyId
                                              , tplPdeInfo.DMT_DATE_DOCUMENT
                                              , tplPdeInfo.DMT_RATE_OF_EXCHANGE
                                              , tplPdeInfo.DMT_BASE_PRICE
                                              , 0
                                               );
          end if;
        end if;
      else
        aDetailInfo.PDE_MOVEMENT_VALUE  := 0;
      end if;

      -- Valeurs de caractérisation
      if    (tplPdeInfo.GAS_CHARACTERIZATION = 1)
         or (tplPdeInfo.STM_MOVEMENT_KIND_ID is not null) then
        -- Valeurs de caractérisation
        if aDetailInfo.USE_CHARACTERIZATION_VALUES = 0 then
          aDetailInfo.USE_CHARACTERIZATION_VALUES   := 1;
          aDetailInfo.PDE_CHARACTERIZATION_VALUE_1  := null;
          aDetailInfo.PDE_CHARACTERIZATION_VALUE_2  := null;
          aDetailInfo.PDE_CHARACTERIZATION_VALUE_3  := null;
          aDetailInfo.PDE_CHARACTERIZATION_VALUE_4  := null;
          aDetailInfo.PDE_CHARACTERIZATION_VALUE_5  := null;
        end if;

        -- Remplir les valeurs de caractérisations de type chronologique
        if (aDetailInfo.PDE_BASIS_QUANTITY <> 0) then
          -- recherche des id et des valeurs de caractérisations du nouveau détail de position
          DOC_POSITION_DETAIL_FUNCTIONS.GetDetailCharact(aGoodID        => tplPdeInfo.GCO_GOOD_ID
                                                       , aPositionID    => aDetailInfo.DOC_POSITION_ID
                                                       , aGasCharact    => tplPdeInfo.GAS_CHARACTERIZATION
                                                       , aMvtSort       => vMovementSort
                                                       , aAdminDomain   => tplPdeInfo.C_ADMIN_DOMAIN
                                                       , aChar1ID       => aDetailInfo.GCO_CHARACTERIZATION_ID
                                                       , aChar2ID       => aDetailInfo.GCO_GCO_CHARACTERIZATION_ID
                                                       , aChar3ID       => aDetailInfo.GCO2_GCO_CHARACTERIZATION_ID
                                                       , aChar4ID       => aDetailInfo.GCO3_GCO_CHARACTERIZATION_ID
                                                       , aChar5ID       => aDetailInfo.GCO4_GCO_CHARACTERIZATION_ID
                                                       , aChar1Value    => aDetailInfo.PDE_CHARACTERIZATION_VALUE_1
                                                       , aChar2Value    => aDetailInfo.PDE_CHARACTERIZATION_VALUE_2
                                                       , aChar3Value    => aDetailInfo.PDE_CHARACTERIZATION_VALUE_3
                                                       , aChar4Value    => aDetailInfo.PDE_CHARACTERIZATION_VALUE_4
                                                       , aChar5Value    => aDetailInfo.PDE_CHARACTERIZATION_VALUE_5
                                                       , aCharacType1   => vCharacType1
                                                       , aCharacType2   => vCharacType2
                                                       , aCharacType3   => vCharacType3
                                                       , aCharacType4   => vCharacType4
                                                       , aCharacType5   => vCharacType5
                                                        );
        end if;
      else
        -- Valeurs de caractérisation
        aDetailInfo.USE_CHARACTERIZATION_VALUES   := 1;
        aDetailInfo.PDE_CHARACTERIZATION_VALUE_1  := null;
        aDetailInfo.PDE_CHARACTERIZATION_VALUE_2  := null;
        aDetailInfo.PDE_CHARACTERIZATION_VALUE_3  := null;
        aDetailInfo.PDE_CHARACTERIZATION_VALUE_4  := null;
        aDetailInfo.PDE_CHARACTERIZATION_VALUE_5  := null;
      end if;

      -- Gestion des Délais
      if tplPdeInfo.GAP_DELAY = 1 then
        -- Si création de détail d'une position CPT, les délais doivent être les mêmes que ceux du détail de la pos PT
        select max(DOC_DOC_POSITION_ID)
          into vDOC_DOC_POSITION_ID
          from DOC_POSITION
         where DOC_POSITION_ID = aDetailInfo.DOC_POSITION_ID;

        -- Si création de détail d'une position CPT, les délais doivent être les mêmes que ceux du détail de la pos PT
        if vDOC_DOC_POSITION_ID is not null then
          select 1
               , PDE_PT.PDE_BASIS_DELAY
               , PDE_PT.PDE_INTERMEDIATE_DELAY
               , PDE_PT.PDE_FINAL_DELAY
            into aDetailInfo.USE_DELAY
               , aDetailInfo.PDE_BASIS_DELAY
               , aDetailInfo.PDE_INTERMEDIATE_DELAY
               , aDetailInfo.PDE_FINAL_DELAY
            from DOC_POSITION_DETAIL PDE_PT
           where PDE_PT.DOC_POSITION_ID = vDOC_DOC_POSITION_ID;
        else
          -- Délais passés en param par l'utilisateur = NON
          if aDetailInfo.USE_DELAY = 0 then
            -- Initialisation des 3 délais
            DOC_POSITION_DETAIL_FUNCTIONS.InitializePDEDelay(tplPdeInfo.C_GAUGE_SHOW_DELAY
                                                           , tplPdeInfo.GAP_POS_DELAY
                                                           , tplPdeInfo.GAP_DELAY_COPY_PREV_POS
                                                           , tplPdeInfo.PAC_THIRD_CDA_ID
                                                           , tplPdeInfo.GCO_GOOD_ID
                                                           , tplPdeInfo.STM_STOCK_ID
                                                           , tplPdeInfo.STM_STM_STOCK_ID
                                                           , tplPdeInfo.C_ADMIN_DOMAIN
                                                           , tplPdeInfo.C_GAUGE_TYPE
                                                           , tplPdeInfo.GAP_TRANSFERT_PROPRIETOR
                                                           , aDetailInfo.PDE_BASIS_DELAY
                                                           , aDetailInfo.PDE_INTERMEDIATE_DELAY
                                                           , aDetailInfo.PDE_FINAL_DELAY
                                                           , tplPdeInfo.GCO_COMPL_DATA_ID
                                                           , aDetailInfo.PDE_BASIS_QUANTITY
                                                           , aDetailInfo.FAL_SCHEDULE_STEP_ID
                                                            );
          -- Délais passés en param par l'utilisateur = OUI
          -- Effectuer une recherche/initialisation si au moins 1 délai est manquant
          elsif    (aDetailInfo.PDE_BASIS_DELAY is null)
                or (aDetailInfo.PDE_INTERMEDIATE_DELAY is null)
                or (aDetailInfo.PDE_FINAL_DELAY is null) then
            -- Pour l'initialisation des délais, l'utilisateur peut passer en param
            --   1 : Aucun délai
            --   2 : Délai de base uniquement
            --   3 : Délai final uniquement
            --   4 : Les 3 délais

            -- Recherche les délais s'ils n'ont pas été passés en param
            if aDetailInfo.PDE_BASIS_DELAY is not null then
              -- Recherche du délai intermédiaire et final
              DOC_POSITION_DETAIL_FUNCTIONS.GetPDEDelay(tplPdeInfo.C_GAUGE_SHOW_DELAY
                                                      , tplPdeInfo.GAP_POS_DELAY
                                                      , 'BASIS'
                                                      , 1
                                                      , tplPdeInfo.PAC_THIRD_CDA_ID
                                                      , tplPdeInfo.GCO_GOOD_ID
                                                      , tplPdeInfo.STM_STOCK_ID
                                                      , tplPdeInfo.STM_STM_STOCK_ID
                                                      , tplPdeInfo.C_ADMIN_DOMAIN
                                                      , tplPdeInfo.C_GAUGE_TYPE
                                                      , tplPdeInfo.GAP_TRANSFERT_PROPRIETOR
                                                      , vBasisDelayMW
                                                      , vInterDelayMW
                                                      , vFinalDelayMW
                                                      , aDetailInfo.PDE_BASIS_DELAY
                                                      , aDetailInfo.PDE_INTERMEDIATE_DELAY
                                                      , aDetailInfo.PDE_FINAL_DELAY
                                                      , tplPdeInfo.GCO_COMPL_DATA_ID
                                                      , aDetailInfo.PDE_BASIS_QUANTITY
                                                      , aDetailInfo.FAL_SCHEDULE_STEP_ID
                                                       );
            elsif aDetailInfo.PDE_FINAL_DELAY is not null then
              -- Recherche du délai de base et intermédiaire
              DOC_POSITION_DETAIL_FUNCTIONS.GetPDEDelay(tplPdeInfo.C_GAUGE_SHOW_DELAY
                                                      , tplPdeInfo.GAP_POS_DELAY
                                                      , 'FINAL'
                                                      , 0
                                                      , tplPdeInfo.PAC_THIRD_CDA_ID
                                                      , tplPdeInfo.GCO_GOOD_ID
                                                      , tplPdeInfo.STM_STOCK_ID
                                                      , tplPdeInfo.STM_STM_STOCK_ID
                                                      , tplPdeInfo.C_ADMIN_DOMAIN
                                                      , tplPdeInfo.C_GAUGE_TYPE
                                                      , tplPdeInfo.GAP_TRANSFERT_PROPRIETOR
                                                      , vBasisDelayMW
                                                      , vInterDelayMW
                                                      , vFinalDelayMW
                                                      , aDetailInfo.PDE_BASIS_DELAY
                                                      , aDetailInfo.PDE_INTERMEDIATE_DELAY
                                                      , aDetailInfo.PDE_FINAL_DELAY
                                                      , tplPdeInfo.GCO_COMPL_DATA_ID
                                                      , aDetailInfo.PDE_BASIS_QUANTITY
                                                      , aDetailInfo.FAL_SCHEDULE_STEP_ID
                                                       );
            else
              -- Initialisation des 3 délais
              DOC_POSITION_DETAIL_FUNCTIONS.InitializePDEDelay(tplPdeInfo.C_GAUGE_SHOW_DELAY
                                                             , tplPdeInfo.GAP_POS_DELAY
                                                             , tplPdeInfo.GAP_DELAY_COPY_PREV_POS
                                                             , tplPdeInfo.PAC_THIRD_CDA_ID
                                                             , tplPdeInfo.GCO_GOOD_ID
                                                             , tplPdeInfo.STM_STOCK_ID
                                                             , tplPdeInfo.STM_STM_STOCK_ID
                                                             , tplPdeInfo.C_ADMIN_DOMAIN
                                                             , tplPdeInfo.C_GAUGE_TYPE
                                                             , tplPdeInfo.GAP_TRANSFERT_PROPRIETOR
                                                             , aDetailInfo.PDE_BASIS_DELAY
                                                             , aDetailInfo.PDE_INTERMEDIATE_DELAY
                                                             , aDetailInfo.PDE_FINAL_DELAY
                                                             , tplPdeInfo.GCO_COMPL_DATA_ID
                                                             , aDetailInfo.PDE_BASIS_QUANTITY
                                                             , aDetailInfo.FAL_SCHEDULE_STEP_ID
                                                              );
            end if;
          end if;
        end if;
      else
        -- Les délais ne sont pas gérés
        aDetailInfo.USE_DELAY               := 1;
        aDetailInfo.PDE_BASIS_DELAY         := null;
        aDetailInfo.PDE_INTERMEDIATE_DELAY  := null;
        aDetailInfo.PDE_FINAL_DELAY         := null;
      end if;

      -- Délai accepté qualité
      if     tplPdeInfo.C_SQM_EVAL_TYPE = '1'
         and PCS.PC_CONFIG.GetConfig('SQM_QUALITY_MGM') = '1' then
        aDetailInfo.PDE_SQM_ACCEPTED_DELAY  := aDetailInfo.PDE_INTERMEDIATE_DELAY;
      else
        aDetailInfo.PDE_SQM_ACCEPTED_DELAY  := null;
      end if;

      -- Modification des délais
      if aDetailInfo.USE_DELAY_UPDATE = 0 then
        aDetailInfo.USE_DELAY_UPDATE          := 1;
        aDetailInfo.DIC_DELAY_UPDATE_TYPE_ID  := tplPdeInfo.DIC_DELAY_UPDATE_TYPE_ID;
        aDetailInfo.PDE_DELAY_UPDATE_TEXT     := null;
      end if;

      -- Emplacement de stock
      -- Si sur la position c le stock virtuel, alors pas d'emplacement sur le détail
      if (STM_FUNCTIONS.IsVirtualStock(tplPdeInfo.STM_STOCK_ID) = 1) then
        aDetailInfo.USE_STM_LOCATION_ID  := 1;
        aDetailInfo.STM_LOCATION_ID      := null;
      elsif aDetailInfo.USE_STM_LOCATION_ID = 0 then
        aDetailInfo.USE_STM_LOCATION_ID  := 1;
        aDetailInfo.STM_LOCATION_ID      := tplPdeInfo.STM_LOCATION_ID;
      else
        -- Position avec un mouvement
        if     (tplPdeInfo.STM_MOVEMENT_KIND_ID is not null)
           and (    aDetailInfo.STM_LOCATION_ID is null
                and (STM_FUNCTIONS.IsVirtualStock(tplPdeInfo.STM_STOCK_ID) = 0) ) then
          -- Arrêter l'execution de cette procédure
          aDetailInfo.A_ERROR          := 1;
          aDetailInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création du détail - L''emplacement n''a pas été pas renseigné !');
          return;
        end if;
      end if;

      -- Emplacement de transfert de stock
      -- Si sur la position c le stock virtuel, alors pas d'emplacement sur le détail
      if (STM_FUNCTIONS.IsVirtualStock(tplPdeInfo.STM_STM_STOCK_ID) = 1) then
        aDetailInfo.USE_STM_STM_LOCATION_ID  := 1;
        aDetailInfo.STM_STM_LOCATION_ID      := null;
      elsif aDetailInfo.USE_STM_STM_LOCATION_ID = 0 then
        aDetailInfo.USE_STM_STM_LOCATION_ID  := 1;
        aDetailInfo.STM_STM_LOCATION_ID      := tplPdeInfo.STM_STM_LOCATION_ID;
      else
        -- Position avec un mouvement
        if tplPdeInfo.STM_MOVEMENT_KIND_ID is not null then
          -- Vérifier si c'est un mouvement de transfert
          select decode(STM_STM_MOVEMENT_KIND_ID, 0, null, STM_STM_MOVEMENT_KIND_ID)
            into vStmStmMvtKindID
            from STM_MOVEMENT_KIND
           where STM_MOVEMENT_KIND_ID = tplPdeInfo.STM_MOVEMENT_KIND_ID;

          -- Si c'est un mouvement de transfert, vérifier que le stock et emplacement de transfert soient renseignés
          if     (vStmStmMvtKindID is not null)
             and (    aDetailInfo.STM_STM_LOCATION_ID is null
                  and (STM_FUNCTIONS.IsVirtualStock(tplPdeInfo.STM_STM_STOCK_ID) = 0) ) then
            -- Arrêter l'execution de cette procédure
            aDetailInfo.A_ERROR          := 1;
            aDetailInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création du détail - L''emplacement de transfert n''a pas été pas renseigné !');
            return;
          end if;
        else
          -- Pas de mouvement au niveau du gabarit position
          -- Le stock et l'emplacement de transfert ne doivent être renseignés
          -- que si le gabarit gère le stock propriétaire
          if tplPdeInfo.GAP_TRANSFERT_PROPRIETOR = 1 then
            -- Arrêter l'execution de cette procédure
            -- Si le stock ou l'emplacement de transfert ne sont pas renseignés
            if     aDetailInfo.STM_STM_LOCATION_ID is null
               and (STM_FUNCTIONS.IsVirtualStock(tplPdeInfo.STM_STM_STOCK_ID) = 0) then
              aDetailInfo.A_ERROR          := 1;
              aDetailInfo.A_ERROR_MESSAGE  := PCS.PC_FUNCTIONS.TranslateWord('Création du détail - L''emplacement de transfert n''a pas été pas renseigné !');
              return;
            end if;
          else
            -- Effacer l'emplacement de transfert
            aDetailInfo.USE_STM_STM_LOCATION_ID  := 1;
            aDetailInfo.STM_STM_LOCATION_ID      := null;
          end if;
        end if;
      end if;

      -- Dicos libres
      if aDetailInfo.USE_DIC_PDE_FREE_TABLE = 0 then
        aDetailInfo.USE_DIC_PDE_FREE_TABLE   := 1;
        aDetailInfo.DIC_PDE_FREE_TABLE_1_ID  := null;
        aDetailInfo.DIC_PDE_FREE_TABLE_2_ID  := null;
        aDetailInfo.DIC_PDE_FREE_TABLE_3_ID  := null;
      end if;

      -- Décimales libres
      if aDetailInfo.USE_PDE_DECIMAL = 0 then
        aDetailInfo.USE_PDE_DECIMAL  := 1;
        aDetailInfo.PDE_DECIMAL_1    := null;
        aDetailInfo.PDE_DECIMAL_2    := null;
        aDetailInfo.PDE_DECIMAL_3    := null;
      end if;

      -- Textes libres
      if aDetailInfo.USE_PDE_TEXT = 0 then
        aDetailInfo.USE_PDE_TEXT  := 1;
        aDetailInfo.PDE_TEXT_1    := null;
        aDetailInfo.PDE_TEXT_2    := null;
        aDetailInfo.PDE_TEXT_3    := null;
      end if;

      -- Dates libres
      if aDetailInfo.USE_PDE_DATE = 0 then
        aDetailInfo.USE_PDE_DATE  := 1;
        aDetailInfo.PDE_DATE_1    := null;
        aDetailInfo.PDE_DATE_2    := null;
        aDetailInfo.PDE_DATE_3    := null;
      end if;
    else
      -- position de type 4,5 et 6
      aDetailInfo.PDE_BASIS_QUANTITY            := 0;
      aDetailInfo.PDE_INTERMEDIATE_QUANTITY     := 0;
      aDetailInfo.PDE_FINAL_QUANTITY            := 0;
      aDetailInfo.PDE_BASIS_QUANTITY_SU         := 0;
      aDetailInfo.PDE_INTERMEDIATE_QUANTITY_SU  := 0;
      aDetailInfo.PDE_FINAL_QUANTITY_SU         := 0;
      aDetailInfo.PDE_BALANCE_QUANTITY          := 0;
      aDetailInfo.PDE_MOVEMENT_QUANTITY         := 0;
      aDetailInfo.PDE_MOVEMENT_VALUE            := 0;
      aDetailInfo.PDE_MOVEMENT_DATE             := null;
    end if;

    -- Initialise la date de création du détail si elle est nulle
    if aDetailInfo.A_DATECRE is null then
      aDetailInfo.A_DATECRE  := sysdate;
    end if;

    -- Initialise l'ID de création du détail s'il est nul
    if aDetailInfo.A_IDCRE is null then
      aDetailInfo.A_IDCRE  := PCS.PC_I_LIB_SESSION.GetUserIni;
    end if;

    -- Date de modification
    if aDetailInfo.USE_A_DATEMOD = 0 then
      aDetailInfo.USE_A_DATEMOD  := 1;
      aDetailInfo.A_DATEMOD      := null;
    end if;

    -- ID utilisateur de la modification
    if aDetailInfo.USE_A_IDMOD = 0 then
      aDetailInfo.USE_A_IDMOD  := 1;
      aDetailInfo.A_IDMOD      := null;
    end if;

    -- Niveau
    if aDetailInfo.USE_A_RECLEVEL = 0 then
      aDetailInfo.USE_A_RECLEVEL  := 1;
      aDetailInfo.A_RECLEVEL      := null;
    end if;

    -- Statut du tuple
    if aDetailInfo.USE_A_RECSTATUS = 0 then
      aDetailInfo.USE_A_RECSTATUS  := 1;
      aDetailInfo.A_RECSTATUS      := null;
    end if;

    -- Confirmation
    if aDetailInfo.USE_A_CONFIRM = 0 then
      aDetailInfo.USE_A_CONFIRM  := 1;
      aDetailInfo.A_CONFIRM      := 0;
    end if;

    -- Vérifier s'il y a l'obligation d'avoir la qté unitaire au niveau du détail
    -- si le bien a une caract. de type pièce et par rapport au type de mouvement
    if vForceDetailUnitQty = 1 then
      -- Sauvegarder les valeurs de caract. du détail en cours
      -- Effacer les valeurs pour les caractérisation de type 3 - Pièces
      select case
               when vCharacType1 = '3' then null
               else aDetailInfo.PDE_CHARACTERIZATION_VALUE_1
             end
           , case
               when vCharacType2 = '3' then null
               else aDetailInfo.PDE_CHARACTERIZATION_VALUE_2
             end
           , case
               when vCharacType3 = '3' then null
               else aDetailInfo.PDE_CHARACTERIZATION_VALUE_3
             end
           , case
               when vCharacType4 = '3' then null
               else aDetailInfo.PDE_CHARACTERIZATION_VALUE_4
             end
           , case
               when vCharacType5 = '3' then null
               else aDetailInfo.PDE_CHARACTERIZATION_VALUE_5
             end
        into vChar1Value
           , vChar2Value
           , vChar3Value
           , vChar4Value
           , vChar5Value
        from dual;

      -- Créer autant de détails que la qté du détail initial
      for vCpt in 1 .. vBasisQuantity - 1 loop
        vIndex                                                                  := DOC_DETAIL_INITIALIZE.DetailsInfo.count + 1;
        DOC_DETAIL_INITIALIZE.DetailsInfo(vIndex)                               := aDetailInfo;
        -- Initialiser les valeurs de caractérisation (sans les caract. de type 3 - Pièces)
        DOC_DETAIL_INITIALIZE.DetailsInfo(vIndex).PDE_CHARACTERIZATION_VALUE_1  := vChar1Value;
        DOC_DETAIL_INITIALIZE.DetailsInfo(vIndex).PDE_CHARACTERIZATION_VALUE_2  := vChar2Value;
        DOC_DETAIL_INITIALIZE.DetailsInfo(vIndex).PDE_CHARACTERIZATION_VALUE_3  := vChar3Value;
        DOC_DETAIL_INITIALIZE.DetailsInfo(vIndex).PDE_CHARACTERIZATION_VALUE_4  := vChar4Value;
        DOC_DETAIL_INITIALIZE.DetailsInfo(vIndex).PDE_CHARACTERIZATION_VALUE_5  := vChar5Value;

        -- Initialiser l'id du détail avec un nouvel id
        select INIT_ID_SEQ.nextval
          into DOC_DETAIL_INITIALIZE.DetailsInfo(vIndex).DOC_POSITION_DETAIL_ID
          from dual;
      end loop;
    end if;
  end ControlInitDetailData;

  /**
  *  procedure InsertDetail
  *  Description
  *    Insertion dans la table DOC_POSITION_DETAIL des données du record en param
  */
  procedure InsertDetail(aDetailInfo in DOC_DETAIL_INITIALIZE.TDetailInfo)
  is
  begin
    insert into DOC_POSITION_DETAIL
                (DOC_POSITION_DETAIL_ID
               , DOC_POSITION_ID
               , DOC_DOCUMENT_ID
               , PAC_THIRD_ID
               , PAC_THIRD_ACI_ID
               , PAC_THIRD_DELIVERY_ID
               , PAC_THIRD_TARIFF_ID
               , DOC_GAUGE_ID
               , DOC_GAUGE_FLOW_ID
               , DOC_DOC_POSITION_DETAIL_ID
               , DOC2_DOC_POSITION_DETAIL_ID
               , DOC_GAUGE_RECEIPT_ID
               , DOC_GAUGE_COPY_ID
               , GCO_GOOD_ID
               , FAL_NETWORK_LINK_ID
               , FAL_SCHEDULE_STEP_ID
               , FAL_SUPPLY_REQUEST_ID
               , DOC_RECORD_ID
               , CML_EVENTS_ID
               , PDE_BALANCE_QUANTITY_PARENT
               , PDE_BASIS_QUANTITY
               , PDE_INTERMEDIATE_QUANTITY
               , PDE_FINAL_QUANTITY
               , PDE_BASIS_QUANTITY_SU
               , PDE_INTERMEDIATE_QUANTITY_SU
               , PDE_FINAL_QUANTITY_SU
               , PDE_BALANCE_QUANTITY
               , PDE_MOVEMENT_QUANTITY
               , PDE_MOVEMENT_VALUE
               , PDE_MOVEMENT_DATE
               , PDE_BASIS_DELAY
               , PDE_INTERMEDIATE_DELAY
               , PDE_FINAL_DELAY
               , PDE_SQM_ACCEPTED_DELAY
               , DIC_DELAY_UPDATE_TYPE_ID
               , PDE_DELAY_UPDATE_TEXT
               , GCO_CHARACTERIZATION_ID
               , GCO_GCO_CHARACTERIZATION_ID
               , GCO2_GCO_CHARACTERIZATION_ID
               , GCO3_GCO_CHARACTERIZATION_ID
               , GCO4_GCO_CHARACTERIZATION_ID
               , PDE_CHARACTERIZATION_VALUE_1
               , PDE_CHARACTERIZATION_VALUE_2
               , PDE_CHARACTERIZATION_VALUE_3
               , PDE_CHARACTERIZATION_VALUE_4
               , PDE_CHARACTERIZATION_VALUE_5
               , STM_LOCATION_ID
               , STM_STM_LOCATION_ID
               , DIC_PDE_FREE_TABLE_1_ID
               , DIC_PDE_FREE_TABLE_2_ID
               , DIC_PDE_FREE_TABLE_3_ID
               , PDE_DECIMAL_1
               , PDE_DECIMAL_2
               , PDE_DECIMAL_3
               , PDE_TEXT_1
               , PDE_TEXT_2
               , PDE_TEXT_3
               , PDE_DATE_1
               , PDE_DATE_2
               , PDE_DATE_3
               , C_PDE_CREATE_MODE
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , PAC_THIRD_CDA_ID
               , PAC_THIRD_VAT_ID
               , PDE_ADDENDUM_QTY_BALANCED
               , PDE_ADDENDUM_SRC_PDE_ID
               , DOC_PDE_LITIG_ID
               , FAL_LOT_ID
               , GCO_MANUFACTURED_GOOD_ID
               , PDE_ST_PT_REJECT
               , PDE_ST_CPT_REJECT
                )
      select aDetailInfo.DOC_POSITION_DETAIL_ID
           , aDetailInfo.DOC_POSITION_ID
           , aDetailInfo.DOC_DOCUMENT_ID
           , aDetailInfo.PAC_THIRD_ID
           , aDetailInfo.PAC_THIRD_ACI_ID
           , aDetailInfo.PAC_THIRD_DELIVERY_ID
           , aDetailInfo.PAC_THIRD_TARIFF_ID
           , aDetailInfo.DOC_GAUGE_ID
           , aDetailInfo.DOC_GAUGE_FLOW_ID
           , aDetailInfo.DOC_DOC_POSITION_DETAIL_ID
           , aDetailInfo.DOC2_DOC_POSITION_DETAIL_ID
           , aDetailInfo.DOC_GAUGE_RECEIPT_ID
           , aDetailInfo.DOC_GAUGE_COPY_ID
           , aDetailInfo.GCO_GOOD_ID
           , aDetailInfo.FAL_NETWORK_LINK_ID
           , aDetailInfo.FAL_SCHEDULE_STEP_ID
           , aDetailInfo.FAL_SUPPLY_REQUEST_ID
           , aDetailInfo.DOC_RECORD_ID
           , aDetailInfo.CML_EVENTS_ID
           , aDetailInfo.PDE_BALANCE_QUANTITY_PARENT
           , aDetailInfo.PDE_BASIS_QUANTITY
           , aDetailInfo.PDE_INTERMEDIATE_QUANTITY
           , aDetailInfo.PDE_FINAL_QUANTITY
           , aDetailInfo.PDE_BASIS_QUANTITY_SU
           , aDetailInfo.PDE_INTERMEDIATE_QUANTITY_SU
           , aDetailInfo.PDE_FINAL_QUANTITY_SU
           , aDetailInfo.PDE_BALANCE_QUANTITY
           , aDetailInfo.PDE_MOVEMENT_QUANTITY
           , aDetailInfo.PDE_MOVEMENT_VALUE
           , aDetailInfo.PDE_MOVEMENT_DATE
           , trunc(aDetailInfo.PDE_BASIS_DELAY)
           , trunc(aDetailInfo.PDE_INTERMEDIATE_DELAY)
           , trunc(aDetailInfo.PDE_FINAL_DELAY)
           , trunc(aDetailInfo.PDE_SQM_ACCEPTED_DELAY)
           , aDetailInfo.DIC_DELAY_UPDATE_TYPE_ID
           , aDetailInfo.PDE_DELAY_UPDATE_TEXT
           , aDetailInfo.GCO_CHARACTERIZATION_ID
           , aDetailInfo.GCO_GCO_CHARACTERIZATION_ID
           , aDetailInfo.GCO2_GCO_CHARACTERIZATION_ID
           , aDetailInfo.GCO3_GCO_CHARACTERIZATION_ID
           , aDetailInfo.GCO4_GCO_CHARACTERIZATION_ID
           , aDetailInfo.PDE_CHARACTERIZATION_VALUE_1
           , aDetailInfo.PDE_CHARACTERIZATION_VALUE_2
           , aDetailInfo.PDE_CHARACTERIZATION_VALUE_3
           , aDetailInfo.PDE_CHARACTERIZATION_VALUE_4
           , aDetailInfo.PDE_CHARACTERIZATION_VALUE_5
           , aDetailInfo.STM_LOCATION_ID
           , aDetailInfo.STM_STM_LOCATION_ID
           , aDetailInfo.DIC_PDE_FREE_TABLE_1_ID
           , aDetailInfo.DIC_PDE_FREE_TABLE_2_ID
           , aDetailInfo.DIC_PDE_FREE_TABLE_3_ID
           , aDetailInfo.PDE_DECIMAL_1
           , aDetailInfo.PDE_DECIMAL_2
           , aDetailInfo.PDE_DECIMAL_3
           , aDetailInfo.PDE_TEXT_1
           , aDetailInfo.PDE_TEXT_2
           , aDetailInfo.PDE_TEXT_3
           , aDetailInfo.PDE_DATE_1
           , aDetailInfo.PDE_DATE_2
           , aDetailInfo.PDE_DATE_3
           , nvl(aDetailInfo.C_PDE_CREATE_MODE, case aDetailInfo.CREATE_TYPE
                   when 'INSERT' then '910'
                   when 'COPY' then '920'
                   when 'DISCHARGE' then '930'
                   else '999'
                 end) as C_PDE_CREATE_MODE
           , aDetailInfo.A_DATECRE
           , aDetailInfo.A_DATEMOD
           , aDetailInfo.A_IDCRE
           , aDetailInfo.A_IDMOD
           , aDetailInfo.A_RECLEVEL
           , aDetailInfo.A_RECSTATUS
           , aDetailInfo.A_CONFIRM
           , aDetailInfo.PAC_THIRD_CDA_ID
           , aDetailInfo.PAC_THIRD_VAT_ID
           , aDetailInfo.PDE_ADDENDUM_QTY_BALANCED
           , aDetailInfo.PDE_ADDENDUM_SRC_PDE_ID
           , aDetailInfo.DOC_PDE_LITIG_ID
           , aDetailInfo.FAL_LOT_ID
           , aDetailInfo.GCO_MANUFACTURED_GOOD_ID
           , decode(PCS.PC_CONFIG.GETCONFIG('FAL_SUBCONTRACT_REJECT'), '1', 0, '2', 1, 0)
           , decode(PCS.PC_CONFIG.GETCONFIG('FAL_SUBCONTRACT_REJECT'), '1', 1, '2', 0, 0)
        from dual;
  end InsertDetail;
end DOC_DETAIL_GENERATE;
