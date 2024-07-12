CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setInitialData FOR DETERMINE ON SAVE
      IMPORTING keys FOR Item~setInitialData.
    METHODS calculateGrossamount FOR DETERMINE ON SAVE
      IMPORTING keys FOR Item~calculateGrossamount.
    METHODS setProdDat FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Item~setProdDat.
    METHODS ValidateProdId FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~ValidateProdId.
    METHODS ValidQuantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~ValidQuantity.
ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD setInitialData.
    DATA max_item TYPE snwd_so_item_pos.


    READ ENTITIES OF z_i_soh IN LOCAL MODE
        ENTITY Item
          FIELDS (  Itempos )
          WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    READ ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY Item BY \_SalesOrder
        FROM CORRESPONDING #( items )
      LINK DATA(so_item_links).


    " Find max used BookingID in zall bookings of this travel
    READ TABLE items INTO DATA(item) INDEX 1.

    SELECT MAX( itempos )
    INTO max_item
    FROM znwd_so_item
    WHERE orderuuid EQ item-Orderuuid.

    " Provide a booking ID for all bookings that have none.
    LOOP AT items ASSIGNING FIELD-SYMBOL(<fs_item>)  WHERE Itempos IS INITIAL.
      max_item += 10.
      <fs_item>-Itempos = max_item.
*      APPEND VALUE #( %tky      = <fs_item>-%tky
*                      Itempos = max_item
*                    )  TO items.
    ENDLOOP.


    " Update the Booking ID of all relevant bookings
    MODIFY ENTITIES OF z_i_soh IN LOCAL MODE
    ENTITY Item
      UPDATE FIELDS ( Itempos ) WITH VALUE #( FOR itemx IN items
                      ( %tky    = itemx-%tky
                        Itempos = itemx-Itempos ) )
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).


  ENDMETHOD.


  METHOD setProdDat.


    READ ENTITIES OF z_i_soh IN LOCAL MODE
       ENTITY Item
         FIELDS (  Prodid )
         WITH CORRESPONDING #( keys )
     RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<fs_item>) WHERE Prodid is not INITIAL.
      SELECT SINGLE Currency , Price , ProductBaseUnit FROM  z_vh_PrdName
      INTO ( @<fs_item>-Currencycode, @<fs_item>-NetAmount, @<fs_item>-Unitid )
      WHERE Product = @<fs_item>-Prodid.
    ENDLOOP.
    MODIFY ENTITIES OF z_i_soh IN LOCAL MODE
    ENTITY Item
      UPDATE FIELDS ( Currencycode NetAmount Unitid ) WITH CORRESPONDING #( items )
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD calculateGrossamount.



    " Read all travels for the requested bookings.
    " If multiple bookings of the same travel are requested, the travel is returned only once.
    READ ENTITIES OF z_i_soh IN LOCAL MODE
    ENTITY Item BY \_SalesOrder
      FIELDS ( Orderuuid )
      WITH CORRESPONDING #( keys )
      RESULT DATA(orders)
      FAILED DATA(read_failed).

    " Trigger calculation of the total price
    MODIFY ENTITIES OF z_i_soh IN LOCAL MODE
    ENTITY SalesOrder
      EXECUTE recalcTotalPrice
      FROM CORRESPONDING #( orders )
    REPORTED DATA(execute_reported).

    reported = CORRESPONDING #( DEEP execute_reported ).

  ENDMETHOD.

  METHOD ValidateProdId.

    READ ENTITIES OF z_i_soh IN LOCAL MODE
        ENTITY Item
          FIELDS (  Prodid )
          WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    READ ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY Item BY \_SalesOrder
        FROM CORRESPONDING #( items )
      LINK DATA(so_item_links).

    DATA products TYPE SORTED TABLE OF z_vh_PrdName WITH UNIQUE KEY Product.

    " Optimization of DB select: extract distinct non-initial customer IDs
    products = CORRESPONDING #( items DISCARDING DUPLICATES MAPPING Product = Prodid EXCEPT * ).
    DELETE products WHERE Product IS INITIAL.
    IF products IS NOT INITIAL.
      " Check if customer ID exist
      SELECT FROM z_vh_PrdName FIELDS Product
        FOR ALL ENTRIES IN @products
        WHERE Product = @products-Product
        INTO TABLE @DATA(products_db).
    ENDIF.

    LOOP AT items INTO DATA(item)." WHERE Prodid IS NOT INITIAL.

      " Clear state messages that might exist
      APPEND VALUE #(  %tky        = item-%tky
                       %state_area = 'VALIDATE_PRODID' )
        TO reported-item.


      IF  NOT line_exists(  products_db[ Product = item-Prodid ] ).
        APPEND VALUE #(  %tky = item-%tky ) TO failed-item.
        APPEND VALUE #(  %tky        = item-%tky
                     %state_area = 'VALIDATE_PRODID'
                     %msg        = NEW zcm_som(
                                       severity   = if_abap_behv_message=>severity-error
                                       textid     = zcm_som=>prodid_unknown
                                       prodid     = item-Prodid )
                     %path           = VALUE #( SalesOrder-%tky = so_item_links[ KEY draft source-%tky = item-%tky ]-target-%tky )
                     %element-Prodid = if_abap_behv=>mk-on )
      TO reported-item.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD ValidQuantity.
    READ ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY Item
        FIELDS (  Quantity )
        WITH CORRESPONDING #( keys )
    RESULT DATA(items).

    READ ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY Item BY \_SalesOrder
        FROM CORRESPONDING #( items )
      LINK DATA(so_item_links).

    LOOP AT items INTO DATA(item) WHERE Prodid IS NOT INITIAL.

      " Clear state messages that might exist
      APPEND VALUE #(  %tky        = item-%tky
                       %state_area = 'VALIDATE_QUANTITY' )
        TO reported-item.


      IF  item-Quantity < 1 .
        APPEND VALUE #(  %tky = item-%tky ) TO failed-item.
        APPEND VALUE #(  %tky        = item-%tky
                     %state_area = 'VALIDATE_QUANTITY'
                     %msg        = NEW zcm_som(
                                       severity   = if_abap_behv_message=>severity-error
                                       textid     = zcm_som=>valid_quantity
                                       quantity   = item-Quantity )
                     %path           = VALUE #( SalesOrder-%tky = so_item_links[ KEY draft source-%tky = item-%tky ]-target-%tky )
                     %element-Quantity = if_abap_behv=>mk-on )
      TO reported-item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
