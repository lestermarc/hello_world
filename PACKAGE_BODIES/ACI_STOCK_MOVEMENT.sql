--------------------------------------------------------
--  DDL for Package Body ACI_STOCK_MOVEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_STOCK_MOVEMENT" 
is
  /**
  * Description
  *   procedure principale a appeler depuis le trigger d'insertion des mouvements de stock
  *   elle appelle la procedure de creation d'entete et la procedure de creation des
  *   imputations
  **/
  procedure Write_StkMvt_Interface(
    stock_movement_id     in     number
  , movement_kind_id      in     number
  , movement_wording      in     varchar2
  , movement_date         in     date
  , movement_value        in     number
  , movement_qty          in     number
  , good_id               in     number
  , third_id              in     number
  , record_id             in     number
  , financial_charging    in out number
  , financial_value       in out number
  , division_account_id   in     number
  , financial_account_id  in     number
  , division_account_id2  in     number
  , financial_account_id2 in     number
  , cpn_account_id        in     number
  , cpn_account_id2       in     number
  , cda_account_id        in     number
  , cda_account_id2       in     number
  , pf_account_id         in     number
  , pf_account_id2        in     number
  , pj_account_id         in     number
  , pj_account_id2        in     number
  , AExtourneMvt          in     number
  , AAccountInfo          in out ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo
  , AAccountInfo2         in out ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo
  , AGapPurchasePrice     in     number default null
  )
  is
  begin
    ra('procedure ACI_STOCK_MOVEMENT.Write_StkMvt_Interface obsolete, use ACS_LIB_LOGISTIC_FINANCIAL.generatePermanentInventory instead.');
  end Write_StkMvt_Interface;

  /**
  * Description
  *    procedure de creation de l'entete du document d'interface comptable
  **/
  procedure Document_Interface(
    document_id             in number
  , document_number         in varchar2
  , aTransactionCatKey      in varchar2
  , aTransactionTypKey      in varchar2
  , job_type_s_catalogue_id in number
  , movement_date           in date
  , movement_value          in number
  , aStockMovementId        in number
  )
  is
  begin
    ra('procedure ACI_STOCK_MOVEMENT.Document_Interface obsolete');
  end Document_Interface;

  /**
  * Description
  *    procedure de creation des imputations d'interface comptable
  **/
  procedure Imputation_Interface(
    document_id           in     number
  , imp_descr             in     varchar2
  , movement_date         in     date
  , movement_value        in     number
  , division_account_id   in     number
  , financial_account_id  in     number
  , division_account_id2  in     number
  , financial_account_id2 in     number
  , cpn_account_id        in     number
  , cpn_account_id2       in     number
  , cda_account_id        in     number
  , cda_account_id2       in     number
  , pf_account_id         in     number
  , pf_account_id2        in     number
  , pj_account_id         in     number
  , pj_account_id2        in     number
  , good_id               in     number
  , third_id              in     number
  , record_id             in     number
  , input_movement        in     number
  , financial_imputation  in     number
  , anal_imputation       in     number
  , AExtourneMvt          in     number
  , AAccountInfo          in out ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo
  , AAccountInfo2         in out ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo
  , AGapPurchasePrice     in     number default null
  )
  is
  begin
    ra('procedure ACI_STOCK_MOVEMENT.Imputation_Interface obsolete');
  end Imputation_Interface;
end ACI_STOCK_MOVEMENT;
