--------------------------------------------------------
--  DDL for Package Body STM_INVENTORY_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_INVENTORY_FCT" 
is
  function get_nbr_job_details(pInventory_list_pos_id STM_INVENTORY_LIST_POS.STM_INVENTORY_LIST_POS_ID%type)
    return number
  is
    vNbr_of_job_detail number;
  begin
    vNbr_of_job_detail  := 0;

    select count(IJD.STM_INVENTORY_JOB_DETAIL_ID)
      into vNbr_of_job_detail
      from STM_INVENTORY_JOB_DETAIL IJD
     where IJD.STM_INVENTORY_LIST_POS_ID = pInventory_list_pos_id;

    return vNbr_of_job_detail;
  end get_nbr_job_details;

  function get_nbr_pos(pInventory_list_id STM_INVENTORY_LIST.STM_INVENTORY_LIST_ID%type)
    return number
  is
/* variables */
    vNbr_pos number;
  begin   /* get_nbr_pos */
    vNbr_pos  := 0;

    select count(ILP.STM_INVENTORY_LIST_POS_ID)
      into vNbr_pos
      from STM_INVENTORY_LIST_POS ILP
     where ILP.STM_INVENTORY_LIST_ID = pInventory_list_id
       and ILP.ILP_IS_VALIDATED = 0;

    return vNbr_pos;
  end get_nbr_pos;

  function get_nbr_zero_pos(pInventory_list_id STM_INVENTORY_LIST.STM_INVENTORY_LIST_ID%type)
    return number
  is
/* variables */
    vNbr_of_zero_pos number;
  begin   /* get_nbr_zero_pos */
    vNbr_of_zero_pos  := 0;

    select count(ILP.STM_INVENTORY_LIST_POS_ID)
      into vNbr_of_zero_pos
      from STM_INVENTORY_LIST_POS ILP
     where ILP.STM_INVENTORY_LIST_ID = pInventory_list_id
       and ILP.ILP_INVENTORY_QUANTITY = 0
       and ILP.ILP_IS_VALIDATED = 0;

    return vNbr_of_zero_pos;
  end get_nbr_zero_pos;

  function get_nbr_zero_pos_with_det(pInventory_list_id STM_INVENTORY_LIST.STM_INVENTORY_LIST_ID%type)
    return number
  is
    vNbr_of_zero_pos_with_det number;
  begin   /* get_nbr_zero_pos_with_det */
    vNbr_of_zero_pos_with_det  := 0;

    select count(ILP.STM_INVENTORY_LIST_POS_ID)
      into vNbr_of_zero_pos_with_det
      from STM_INVENTORY_LIST_POS ILP
     where ILP.STM_INVENTORY_LIST_ID = pInventory_list_id
       and ILP.ILP_INVENTORY_QUANTITY = 0
       and exists(select 1
                    from STM_INVENTORY_JOB_DETAIL IJD
                   where IJD.STM_INVENTORY_LIST_POS_ID = ILP.STM_INVENTORY_LIST_POS_ID);

    return vNbr_of_zero_pos_with_det;
  end get_nbr_zero_pos_with_det;

  function get_nbr_zero_pos_without_det(pInventory_list_id STM_INVENTORY_LIST.STM_INVENTORY_LIST_ID%type)
    return number
  is
    vNbr_of_zero_pos_without_det number;
  begin   /* get_nbr_zero_pos_without_det */
    vNbr_of_zero_pos_without_det  := 0;

    select count(ILP.STM_INVENTORY_LIST_POS_ID)
      into vNbr_of_zero_pos_without_det
      from STM_INVENTORY_LIST_POS ILP
     where ILP.STM_INVENTORY_LIST_ID = pInventory_list_id
       and ILP.ILP_INVENTORY_QUANTITY = 0
       and ILP.ILP_IS_VALIDATED = 0
       and not exists(select 1
                        from STM_INVENTORY_JOB_DETAIL IJD
                       where IJD.STM_INVENTORY_LIST_POS_ID = ILP.STM_INVENTORY_LIST_POS_ID);

    return vNbr_of_zero_pos_without_det;
  end get_nbr_zero_pos_without_det;
end STM_INVENTORY_FCT;
