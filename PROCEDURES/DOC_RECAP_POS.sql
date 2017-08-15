--------------------------------------------------------
--  DDL for Procedure DOC_RECAP_POS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "DOC_RECAP_POS" (DOCUMENT_ID NUMBER)
IS
/**
* Description
*    procedure de mise à jour des positions 'RECAP'
* @author X
* @param DOCUMENT_ID : id du document à mettre à jour.
*/

  -- Type de position
  gauge_type_pos doc_position.c_gauge_type_pos%type;
  --Id de la position
  position_id doc_position.doc_position_id%type;
  -- Variables de totalisation
  tot_basis_quantity doc_position.pos_basis_quantity%type;
  tot_intermediate_quantity doc_position.pos_intermediate_quantity%type;
  tot_final_quantity doc_position.pos_final_quantity%type;
  tot_discount_amount doc_position.pos_discount_amount%type;
  tot_charge_amount doc_position.pos_charge_amount%type;
  tot_vat_amount doc_position.pos_vat_amount%type;
  tot_gross_unit_value doc_position.pos_gross_unit_value%type;
  tot_net_unit_value doc_position.pos_net_unit_value%type;
  tot_gross_value doc_position.pos_gross_value%type;
  tot_net_value_excl doc_position.pos_net_value_excl%type;
  tot_net_value_incl doc_position.pos_net_value_incl%type;
  tot_net_weight doc_position.pos_net_weight%type;
  tot_gross_weight doc_position.pos_gross_weight%type;
  -- curseur sur les positions du document dans l'ordre des num¿ros de position
  CURSOR POSITION_CURSOR(doc_id NUMBER) IS
  SELECT DOC_POSITION_ID,
         C_GAUGE_TYPE_POS,
         POS_BASIS_QUANTITY,
         POS_INTERMEDIATE_QUANTITY,
         POS_FINAL_QUANTITY,
         POS_DISCOUNT_AMOUNT,
         POS_CHARGE_AMOUNT,
         POS_VAT_AMOUNT,
         POS_GROSS_UNIT_VALUE,
         POS_NET_UNIT_VALUE,
         POS_GROSS_VALUE,
         POS_NET_VALUE_EXCL,
         POS_NET_VALUE_INCL,
         POS_NET_WEIGHT,
         POS_GROSS_WEIGHT
  FROM DOC_POSITION
  WHERE DOC_DOCUMENT_ID = doc_id
  ORDER BY POS_NUMBER;
  POSITION_TUPLE POSITION_CURSOR%ROWTYPE;
BEGIN
  -- initialisation des compteurs de totalisation
  tot_basis_quantity        := 0;
  tot_intermediate_quantity := 0;
  tot_final_quantity        := 0;
  tot_discount_amount       := 0;
  tot_charge_amount         := 0;
  tot_vat_amount            := 0;
  tot_gross_unit_value      := 0;
  tot_net_unit_value        := 0;
  tot_gross_value           := 0;
  tot_net_value_excl        := 0;
  tot_net_value_incl        := 0;
  tot_net_weight            := 0;
  tot_gross_weight          := 0;
  -- ouverture du curseur
  OPEN POSITION_CURSOR(DOCUMENT_ID);

  -- premi¿re position
  FETCH POSITION_CURSOR INTO position_tuple;

  WHILE POSITION_CURSOR%FOUND LOOP

    -- si on est sur une posituion de r¿cap, on la met ¿ jour avec les totaux des lignes pr¿c¿dente
    IF position_tuple.c_gauge_type_pos = '6' THEN
       UPDATE DOC_POSITION SET
         POS_BASIS_QUANTITY        = tot_basis_quantity,
         POS_INTERMEDIATE_QUANTITY = tot_intermediate_quantity,
         POS_FINAL_QUANTITY        = tot_final_quantity,
         POS_DISCOUNT_AMOUNT       = tot_discount_amount,
         POS_CHARGE_AMOUNT         = tot_charge_amount,
         POS_VAT_AMOUNT            = tot_vat_amount,
         POS_GROSS_UNIT_VALUE      = tot_gross_unit_value,
         POS_NET_UNIT_VALUE        = tot_net_unit_value,
         POS_GROSS_VALUE           = tot_gross_value,
         POS_NET_VALUE_EXCL        = tot_net_value_excl,
         POS_NET_VALUE_INCL        = tot_net_value_incl,
         POS_NET_WEIGHT            = tot_net_weight,
         POS_GROSS_WEIGHT          = tot_gross_weight
       WHERE DOC_POSITION_ID = position_tuple.doc_position_id;
       -- remise à zéro des compteurs de totalisation
       tot_basis_quantity        := 0;
       tot_intermediate_quantity := 0;
       tot_final_quantity        := 0;
       tot_discount_amount       := 0;
       tot_charge_amount         := 0;
       tot_vat_amount            := 0;
       tot_gross_unit_value      := 0;
       tot_net_unit_value        := 0;
       tot_gross_value           := 0;
       tot_net_value_excl        := 0;
       tot_net_value_incl        := 0;
       tot_net_weight            := 0;
       tot_gross_weight          := 0;
    ELSE
      -- cumul des positions
      tot_basis_quantity        := tot_basis_quantity        + position_tuple.pos_basis_quantity;
      tot_intermediate_quantity := tot_intermediate_quantity + position_tuple.pos_intermediate_quantity;
      tot_final_quantity        := tot_final_quantity        + position_tuple.pos_final_quantity;
      tot_discount_amount       := tot_discount_amount       + position_tuple.pos_discount_amount;
      tot_charge_amount         := tot_charge_amount         + position_tuple.pos_charge_amount;
      tot_vat_amount            := tot_vat_amount            + position_tuple.pos_vat_amount;
      tot_gross_unit_value      := tot_gross_unit_value      + position_tuple.pos_gross_unit_value;
      tot_net_unit_value        := tot_net_unit_value        + position_tuple.pos_net_unit_value;
      tot_gross_value           := tot_gross_value           + position_tuple.pos_gross_value;
      tot_net_value_excl        := tot_net_value_excl        + position_tuple.pos_net_value_excl;
      tot_net_value_incl        := tot_net_value_incl        + position_tuple.pos_net_value_incl;
      tot_net_weight            := tot_net_weight            + position_tuple.pos_net_weight;
      tot_gross_weight          := tot_gross_weight          + position_tuple.pos_gross_weight;
    END IF;

    -- position suivante
    FETCH POSITION_CURSOR INTO position_tuple;

  END LOOP;

  -- fermeture du curseur des positions
  CLOSE POSITION_CURSOR;

END DOC_RECAP_POS;
