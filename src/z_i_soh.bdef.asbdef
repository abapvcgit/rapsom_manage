managed; //implementation in class zbp_i_soh unique;
//strict ( 2 );
with draft;
define behavior for z_i_soh alias SalesOrder
implementation in class zbp_i_soh unique
persistent table znwd_so_header
draft table znwd_so_header_d
lock master total etag Lastchangedat
authorization master ( instance )
etag master Locallastchangedat
{
  create;
  update;
  delete ( features : instance );
  association _Item { create; with draft; }

  field ( numbering : managed, readonly ) Orderuuid;
  field ( readonly ) salesorderid, Overallstatus, Createdat, Createdby, Lastchangedat, Lastchangedby,
  Deliverystatus, Billingstatus, Grossamount, Netamount, Currencycode;
  field ( mandatory ) Deliverydate, Businesspartner;

  action ( features : instance ) SetDelivered result [1] $self;
  action ( features : instance ) SetPaid result [1] $self;
  factory action createSoByTemplate [1] ;
  internal action recalcTotalPrice;

  determination setInitialStatus on save { create; }

  validation ValidatePartner on save { field Businesspartner; create; }
  validation ValidDeliveryDate on save { field Deliverydate; create; }
  draft determine action Prepare
  {
    validation ValidatePartner;
    validation ValidDeliveryDate;
    validation Item~ValidateProdId;
    validation Item~ValidQuantity;
  }
  //  determination calculateTotalPrice on modify { field Grossamount, Netamount, Currencycode; }
  mapping for znwd_so_header corresponding;
}
define behavior for z_i_soi alias Item
implementation in class zbp_i_soi unique
persistent table znwd_so_item
draft table znwd_so_item_d
lock dependent by _SalesOrder
authorization dependent by _SalesOrder
etag master Locallastchangedat
{
  update;
  delete;
  association _SalesOrder { with draft; }

  field ( readonly ) Orderuuid;
  field ( numbering : managed, readonly ) Itemuuid;
  field ( readonly ) Itempos, NetAmount, Grossamount, Unitid;
  //  field ( readonly : update ) Prodid;
  field ( mandatory ) Quantity, Prodid;

  determination setInitialData on save { create; }
  determination setProdDat on modify { field Prodid; }
  determination calculateGrossamount on save { field Quantity, Prodid; }

  validation ValidateProdId on save { field Prodid; create; }
  validation ValidQuantity on save { field Quantity; create; update; }

  mapping for znwd_so_item corresponding;
}