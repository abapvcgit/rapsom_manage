@AbapCatalog.viewEnhancementCategory: [#NONE]
@EndUserText.label: 'ValueHelp Product Name'
@AccessControl.authorizationCheck: #NOT_REQUIRED


@Search.searchable: true
/*+[hideWarning] { "IDS" : [ "CARDINALITY_CHECK", "KEY_CHECK" ]  } */
define view entity z_vh_PrdName
  as select from SEPM_I_Product
  association [1] to SEPM_I_ProductText_E as _ProdText on $projection.Product = _ProdText.Product

{
       @Search.defaultSearchElement: true
       @ObjectModel.text.element: ['ProductName']
  key  Product,
       @Semantics.text: true -- identifies the text field
       _ProdText.ProductName as ProductName,
       Currency,
       Price,
       ProductBaseUnit,
       ProductPictureURL,
       _ProdText
}
where
  _ProdText.Language = $session.system_language
