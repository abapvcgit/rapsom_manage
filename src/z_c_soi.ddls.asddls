@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption - SalesOrder Item'
@Metadata.allowExtensions: true
define view entity z_c_soi
  as projection on z_i_soi
{
  key Itemuuid,
      Orderuuid,
      Itempos,
      @ObjectModel.text.element: ['ProdName']
      Prodid,
      _Pdesc.ProductName       as ProdName,
      Unitid,
      @Semantics.quantity.unitOfMeasure: 'Unitid'
      Quantity,
      Currencycode,
      @Semantics.amount.currencyCode: 'Currencycode'
      Grossamount,
      @Semantics.amount.currencyCode: 'Currencycode'
      NetAmount,
      Available,
      @ObjectModel.text.element: ['AtpStatus']
      _Atp.ATPstatus           as AtpStatus,
      @Semantics.imageUrl: true
      _Pdesc.ProductPictureURL as ProdPicture,
      Lastchangeat,
      /* Associations */
      _Atp,
      _Pdesc,
      _SalesOrder : redirected to parent z_c_soh
}
