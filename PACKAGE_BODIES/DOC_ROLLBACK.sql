--------------------------------------------------------
--  DDL for Package Body DOC_ROLLBACK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_ROLLBACK" 
is
  /**
  * Description
  *    Recharge des quantités déchargés par le document spécifié
  */
  procedure reloadDischargedDocument(aDocumentId in number)
  is
    cursor crDischargedPosition(cDocumentId number)
    is
      select   DOC_POSITION_ID
          from DOC_POSITION
         where DOC_DOCUMENT_ID = cDocumentId
           and C_GAUGE_TYPE_POS not in('4', '5', '6')
      order by DOC_POSITION_ID;

    cursor crDischargedDetail(cPositionId number)
    is
      select   PDE.DOC_POSITION_ID
             , PDE.DOC_POSITION_DETAIL_ID
             , PDE.DOC_DOC_POSITION_DETAIL_ID
             , PDE.PDE_FINAL_QUANTITY
             , PDE.PDE_FINAL_QUANTITY_SU
             , PDE.PDE_BALANCE_QUANTITY_PARENT
          from DOC_POSITION_DETAIL PDE
         where PDE.DOC_POSITION_ID = cPositionId
           and PDE.DOC_DOC_POSITION_DETAIL_ID is not null
      order by nvl(PDE.DOC_DOC_POSITION_DETAIL_ID, 0)
             , nvl(PDE.PDE_BALANCE_PARENT, 0)
             , nvl(abs(PDE.PDE_BALANCE_QUANTITY_PARENT), 0);

    cursor crLinkedPositionDetail(cPositionID in number, cParentPositionDetailID in number)
    is
      select   PDE.DOC_POSITION_DETAIL_ID
             , PDE.PDE_BALANCE_QUANTITY_PARENT
             , PDE.DOC_DOC_POSITION_DETAIL_ID
             , PDE.DOC2_DOC_POSITION_DETAIL_ID
             , PDE.DOC_GAUGE_FLOW_ID
             , PDE.DOC_GAUGE_RECEIPT_ID
             , PDE.PDE_BALANCE_PARENT
             , PDE_FATHER.PDE_FINAL_QUANTITY
             , PDE_FATHER.PDE_BALANCE_QUANTITY
             , POS.POS_CONVERT_FACTOR
             , POS.POS_CONVERT_FACTOR2
             , POS.GCO_GOOD_ID
             , POS_FATHER.POS_CONVERT_FACTOR2 FATHER_CONVERT_FACTOR2
             , POS_FATHER.POS_CONVERT_FACTOR FATHER_CONVERT_FACTOR
             , GAU.C_ADMIN_DOMAIN
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_GAUGE GAU
             , DOC_POSITION_DETAIL PDE_FATHER
             , DOC_POSITION POS_FATHER
         where PDE.DOC_POSITION_ID = cPositionID
           and PDE.DOC_DOC_POSITION_DETAIL_ID = cParentPositionDetailID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and GAU.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
           and PDE_FATHER.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and POS_FATHER.DOC_POSITION_ID = PDE_FATHER.DOC_POSITION_ID
      order by nvl(abs(PDE.PDE_BALANCE_QUANTITY_PARENT), 0) desc
             , nvl(PDE.PDE_BALANCE_PARENT, 0) desc;

    tplLinkedPositionDetail  crLinkedPositionDetail%rowtype;
    numBalanceQuantityParent DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY_PARENT%type;
    parentDocumentID         DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    parentPositionID         DOC_POSITION.DOC_POSITION_ID%type;
    vBalanceQuantity         DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type;
    vPosBalanceQuantity      DOC_POSITION.POS_BALANCE_QUANTITY%type;
  begin
    for tplDischargedPosition in crDischargedPosition(aDocumentId) loop
      ---
      -- Recharge des détails pères
      --
      -- Il faut absolument que les détails de position soient rechargé dans un certain ordre pour que
      -- le méchanisme de mise à jour du père s'effectue correctement. Il faut toujours que le dernier
      -- détail à recharger soit le détail de "référence" (le détail qui contient toutes les informations liées
      -- à la décharge, soit : le flag soldé parent, la quantité soldée sur parent et le lien sur le père évidement).
      --
      for tplDischargedDetail in crDischargedDetail(tplDischargedPosition.DOC_POSITION_ID) loop
        -- Recherche si des détails avec un lien avec un père existent. C'est uniquement le détail qui possède la
        -- quantité soldée sur parent la plus grande en valeur absolue qui est traitée, donc qui effectue la mise à
        -- jour du détail parent (recharge). C'est toujours ce détail de position qui reçoit l'éventuelle quantité
        -- soldée sur parent de l'ensemble des détails de position d'un même père.
        open crLinkedPositionDetail(tplDischargedDetail.DOC_POSITION_ID, tplDischargedDetail.DOC_DOC_POSITION_DETAIL_ID);

        fetch crLinkedPositionDetail
         into tplLinkedPositionDetail;

        if crLinkedPositionDetail%found then
          ----
          -- Effectue la mise à jour éventuelle de la quantité solde du détail père et de la quantité soldée sur parent
          -- du détail fils de "référence" (qui contient les informations solder parent et quantité soldée sur parent).
          --
          numBalanceQuantityParent  := tplLinkedPositionDetail.PDE_BALANCE_QUANTITY_PARENT;

          -- Calcul de la quantité solde à recharger sur parent. Tient compte des facteurs de conversion différents.
          if tplLinkedPositionDetail.POS_CONVERT_FACTOR2 <> tplLinkedPositionDetail.POS_CONVERT_FACTOR then
            vBalanceQuantity  :=
                           tplDischargedDetail.PDE_FINAL_QUANTITY * tplLinkedPositionDetail.POS_CONVERT_FACTOR2 / tplLinkedPositionDetail.FATHER_CONVERT_FACTOR;
          elsif tplLinkedPositionDetail.FATHER_CONVERT_FACTOR <> tplLinkedPositionDetail.POS_CONVERT_FACTOR then
            vBalanceQuantity  := tplDischargedDetail.PDE_FINAL_QUANTITY_SU / tplLinkedPositionDetail.FATHER_CONVERT_FACTOR;
          else   -- cas normal
            vBalanceQuantity  := tplDischargedDetail.PDE_FINAL_QUANTITY;
          end if;

          -- On effectue la mise à jour du détail qui possède la quantité soldé sur parent uniquement si ce
          -- n'est pas le détail de référence qui est en cours de recharge.
          if (tplLinkedPositionDetail.DOC_POSITION_DETAIL_ID <> tplDischargedDetail.DOC_POSITION_DETAIL_ID) then
            -- Effectue l'éventuelle mise à jour de la quantité solde du détail père. Attention cette méthode
            -- tient compte du code reliquat.
            DOC_POSITION_DETAIL_FUNCTIONS.MajBalanceQtyDetailParent(tplDischargedDetail.DOC_DOC_POSITION_DETAIL_ID
                                                                  , 0
                                                                  , vBalanceQuantity
                                                                  , tplLinkedPositionDetail.PDE_BALANCE_PARENT
                                                                  , numBalanceQuantityParent
                                                                   );

            -- Mise a jour du détail trouvé avec la nouvelle quantité soldée sur parent.
            update DOC_POSITION_DETAIL
               set PDE_BALANCE_QUANTITY_PARENT = numBalanceQuantityParent
             where DOC_POSITION_DETAIL_ID = tplLinkedPositionDetail.DOC_POSITION_DETAIL_ID;
          else
            ---
            -- Recharge la quantité solde du père. Dans ce cas, nous sommes en train de traiter le détail de "référence".
            --
            numBalanceQuantityParent  := tplDischargedDetail.PDE_BALANCE_QUANTITY_PARENT;

            update    DOC_POSITION_DETAIL
                  set PDE_BALANCE_QUANTITY =
                        decode(sign(PDE_BASIS_QUANTITY)
                             , -1, greatest(least( (PDE_BALANCE_QUANTITY + vBalanceQuantity + numBalanceQuantityParent), 0), PDE_FINAL_QUANTITY)
                             , least(greatest( (PDE_BALANCE_QUANTITY + vBalanceQuantity + numBalanceQuantityParent), 0), PDE_FINAL_QUANTITY)
                              )
                    , A_DATEMOD = sysdate
                    , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                where DOC_POSITION_DETAIL_ID = tplDischargedDetail.DOC_DOC_POSITION_DETAIL_ID
            returning DOC_POSITION_ID
                 into parentPositionId;

            ----
            -- Recherche la nouvelle quantité solde à mettre à jour sur la position père.
            --
            select sum(PDE_BALANCE_QUANTITY)
              into vPosBalanceQuantity
              from DOC_POSITION_DETAIL PDE
             where PDE.DOC_POSITION_ID = parentPositionId;

            -- mise à jour de la quantité solde du parent
            -- et mise à jour de la quantité solde valeur et du status de la position parent
            update    DOC_POSITION parent
                  set POS_BALANCE_QUANTITY = vPosBalanceQuantity
                    , C_DOC_POS_STATUS = decode(vPosBalanceQuantity, 0, '04', parent.POS_FINAL_QUANTITY, '02', '03')
                    , A_DATEMOD = sysdate
                    , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                where parent.DOC_POSITION_ID = parentPositionId
                  and parent.GCO_GOOD_ID is not null
            returning DOC_DOCUMENT_ID
                 into parentDocumentId;

            -- Maj du status du document Parent
            DOC_PRC_DOCUMENT.UpdateDocumentStatus(parentDocumentId);
          end if;
        end if;

        close crLinkedPositionDetail;
      end loop;

      -- Supprimer les liens père/fils de la position courante
      update DOC_POSITION_DETAIL
         set DOC_DOC_POSITION_DETAIL_ID = null
           , DOC_GAUGE_RECEIPT_ID = null
           , PDE_BALANCE_QUANTITY_PARENT = 0
       where DOC_POSITION_ID = tplDischargedPosition.DOC_POSITION_ID;
    end loop;
  end reloadDischargedDocument;
end DOC_ROLLBACK;
