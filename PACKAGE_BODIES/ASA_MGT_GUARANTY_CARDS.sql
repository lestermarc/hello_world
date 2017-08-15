--------------------------------------------------------
--  DDL for Package Body ASA_MGT_GUARANTY_CARDS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_MGT_GUARANTY_CARDS" 
is

  /**
  * Description
  *    Code m�tier de l'insertion d'une carte de garantie
  */
  function insertGUARANTY_CARDS(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Initialisation de la ville et l'�tat lors de la saisie du code postal
    -- La mise � jour se fait uniquement quand il y a un seul r�sultat
    ASA_I_PRC_GUARANTY_CARDS.InitTownState(iot_crud_definition);

    -- Initialisation des valeurs AGC_FORMAT_CITY
    ASA_I_PRC_GUARANTY_CARDS.InitFormatCity(iot_crud_definition);

    /***********************************
    ** execution of CRUD instruction
    ***********************************/
    lResult := fwk_i_dml_table.CRUD(iot_crud_definition);

    -- retourne le rowid de l'enregistrement cr�� (obligatoire)
    return lResult;

  end insertGUARANTY_CARDS;



  /**
  * Description
  *    Code m�tier de la modification d'une carte de garantie
  */
  function updateGUARANTY_CARDS(iotGuarantyCards in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult      varchar2(40);
  begin
    -- Initialisation de la ville et l'�tat lors de la saisie du code postal
    -- La mise � jour se fait uniquement quand il y a un seul r�sultat
    ASA_I_PRC_GUARANTY_CARDS.InitTownState(iotGuarantyCards);

    -- Initialisation des valeurs AGC_FORMAT_CITY
    ASA_I_PRC_GUARANTY_CARDS.InitFormatCity(iotGuarantyCards);

    lResult  := FWK_I_DML_TABLE.CRUD(iotGuarantyCards);

    return lResult;
  end updateGUARANTY_CARDS;


end ASA_MGT_GUARANTY_CARDS;
