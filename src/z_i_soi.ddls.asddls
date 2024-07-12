@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface - SalesOrder Item'
define view entity z_i_soi
  as select from znwd_so_item as Item
  association     to parent z_i_soh as _SalesOrder on $projection.Orderuuid = _SalesOrder.Orderuuid
  association [1] to z_vh_atp       as _Atp        on $projection.Available = _Atp.Atp
  association [1] to z_vh_PrdName   as _Pdesc      on $projection.Prodid = _Pdesc.Product
                                                 
{
  key itemuuid     as Itemuuid,
      orderuuid    as Orderuuid,
      itempos      as Itempos,
      @Consumption.valueHelpDefinition: [{ association: '_Pdesc'}]
      prodid       as Prodid,
      unitid       as Unitid,
      @Semantics.quantity.unitOfMeasure: 'Unitid'
      quantity     as Quantity,
      currencycode as Currencycode,
      @Semantics.amount.currencyCode: 'Currencycode'
      grossamount  as Grossamount,
      @Semantics.amount.currencyCode: 'Currencycode'
      netamount    as NetAmount,
      @Consumption.valueHelpDefinition: [{ association: '_Atp' }]
      available    as Available,
      @Semantics.systemDateTime.lastChangedAt: true
      lastchangeat as Lastchangeat,
      locallastchangedat as Locallastchangedat,
      _SalesOrder,
      _Atp,
      _Pdesc

}
