--------------------------------------------------------
--  DDL for Package Body DOC_ROLLBACK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_ROLLBACK" 
is
  /**
  * Description
  *    Recharge des quantit�s d�charg�s par le document sp�cifi�
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
      -- Recharge des d�tails p�res
      --
      -- Il faut absolument que les d�tails de position soient recharg� dans un certain ordre pour que
      -- le m�chanisme de mise � jour du p�re s'effectue correctement. Il faut toujours que le dernier
      -- d�tail � recharger soit le d�tail de "r�f�rence" (le d�tail qui contient toutes les informations li�es
      -- � la d�charge, soit : le flag sold� parent, la quantit� sold�e sur parent et le lien sur le p�re �videment).
      --
      for tplDischargedDetail in crDischargedDetail(tplDischargedPosition.DOC_POSITION_ID) loop
        -- Recherche si des d�tails avec un lien avec un p�re existent. C'est uniquement le d�tail qui poss�de la
        -- quantit� sold�e sur parent la plus grande en valeur absolue qui est trait�e, donc qui effectue la mise �
        -- jour du d�tail parent (recharge). C'est toujours ce d�tail de position qui re�oit l'�ventuelle quantit�
        -- sold�e sur parent de l'ensemble des d�tails de position d'un m�me p�re.
        open crLinkedPositionDetail(tplDischargedDetail.DOC_POSITION_ID, tplDischargedDetail.DOC_DOC_POSITION_DETAIL_ID);

        fetch crLinkedPositionDetail
         into tplLinkedPositionDetail;

        if crLinkedPositionDetail%found then
          ----
          -- Effectue la mise � jour �ventuelle de la quantit� solde du d�tail p�re et de la quantit� sold�e sur parent
          -- du d�tail fils de "r�f�rence" (qui contient les informations solder parent et quantit� sold�e sur parent).
          --
          numBalanceQuantityParent  := tplLinkedPositionDetail.PDE_BALANCE_QUANTITY_PARENT;

          -- Calcul de la quantit� solde � recharger sur parent. Tient compte des facteurs de conversion diff�rents.
          if tplLinkedPositionDetail.POS_CONVERT_FACTOR2 <> tplLinkedPositionDetail.POS_CONVERT_FACTOR then
            vBalanceQuantity  :=
                           tplDischargedDetail.PDE_FINAL_QUANTITY * tplLinkedPositionDetail.POS_CONVERT_FACTOR2 / tplLinkedPositionDetail.FATHER_CONVERT_FACTOR;
          elsif tplLinkedPositionDetail.FATHER_CONVERT_FACTOR <> tplLinkedPositionDetail.POS_CONVERT_FACTOR then
            vBalanceQuantity  := tplDischargedDetail.PDE_FINAL_QUANTITY_SU / tplLinkedPositionDetail.FATHER_CONVERT_FACTOR;
          else   -- cas normal
            vBalanceQuantity  := tplDischargedDetail.PDE_FINAL_QUANTITY;
          end if;

          -- On effectue la mise � jour du d�tail qui poss�de la quantit� sold� sur parent uniquement si ce
          -- n'est pas le d�tail de r�f�rence qui est en cours de recharge.
          if (tplLinkedPositionDetail.DOC_POSITION_DETAIL_ID <> tplDischargedDetail.DOC_POSITION_DETAIL_ID) then
            -- Effectue l'�ventuelle mise � jour de la quantit� solde du d�tail p�re. Attention cette m�thode
            -- tient compte du code reliquat.
            DOC_POSITION_DETAIL_FUNCTIONS.MajBalanceQtyDetailParent(tplDischargedDetail.DOC_DOC_POSITION_DETAIL_ID
                                                                  , 0
                                                                  , vBalanceQuantity
                                                                  , tplLinkedPositionDetail.PDE_BALANCE_PARENT
                                                                  , numBalanceQuantityParent
                                                                   );

            -- Mise a jour du d�tail trouv� avec la nouvelle quantit� sold�e sur parent.
            update DOC_POSITION_DETAIL
               set PDE_BALANCE_QUANTITY_PARENT = numBalanceQuantityParent
             where DOC_POSITION_DETAIL_ID = tplLinkedPositionDetail.DOC_POSITION_DETAIL_ID;
          else
            ---
            -- Recharge la quantit� solde du p�re. Dans ce cas, nous sommes en train de traiter le d�tail de "r�f�rence".
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
            -- Recherche la nouvelle quantit� solde � mettre � jour sur la position p�re.
            --
            select sum(PDE_BALANCE_QUANTITY)
              into vPosBalanceQuantity
              from DOC_POSITION_DETAIL PDE
             where PDE.DOC_POSITION_ID = parentPositionId;

            -- mise � jour de la quantit� solde du parent
            -- et mise � jour de la quantit� solde valeur et du status de la position parent
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

      -- Supprimer les liens p�re/fils de la position courante
      update DOC_POSITION_DETAIL
         set DOC_DOC_POSITION_DETAIL_ID = null
           , DOC_GAUGE_RECEIPT_ID = null
           , PDE_BALANCE_QUANTITY_PARENT = 0
       where DOC_POSITION_ID = tplDischargedPosition.DOC_POSITION_ID;
    end loop;
  end reloadDischargedDocument;
end DOC_ROLLBACK;
