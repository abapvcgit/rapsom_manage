CLASS lhc_SalesOrder DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.


    METHODS setinitialstatus FOR DETERMINE ON SAVE
      IMPORTING keys FOR salesorder~setinitialstatus.
    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION salesorder~recalctotalprice.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR salesorder RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR salesorder RESULT result.
    METHODS validatepartner FOR VALIDATE ON SAVE
      IMPORTING keys FOR salesorder~validatepartner.
    METHODS validdeliverydate FOR VALIDATE ON SAVE
      IMPORTING keys FOR salesorder~validdeliverydate.
    METHODS setdelivered FOR MODIFY
      IMPORTING keys FOR ACTION salesorder~setdelivered RESULT result.
    METHODS setpaid FOR MODIFY
      IMPORTING keys FOR ACTION salesorder~setpaid RESULT result.
    METHODS createsobytemplate FOR MODIFY
      IMPORTING keys FOR ACTION salesorder~createsobytemplate.

ENDCLASS.

CLASS lhc_SalesOrder IMPLEMENTATION.




  METHOD setInitialStatus.


    " check if TravelID is already filled
    READ ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( Salesorderid ) WITH CORRESPONDING #( keys )
      RESULT DATA(orders).

    " remove lines where TravelID is already filled.
    DELETE orders WHERE Salesorderid IS NOT INITIAL.

    " anything left ?
    CHECK orders IS NOT INITIAL.

    " Select max travel ID
    SELECT SINGLE
        FROM  znwd_so_header
        FIELDS MAX( salesorderid ) AS orderId
        INTO @DATA(max_orderId).
    IF max_orderId IS INITIAL.
      max_orderId = '7000000000'.
    ENDIF.

    " Set the travel ID
    MODIFY ENTITIES OF z_i_soh IN LOCAL MODE
    ENTITY SalesOrder
      UPDATE
        FROM VALUE #( FOR order IN orders INDEX INTO i (
          %tky             = order-%tky
          Salesorderid     = max_orderId + i
          Overallstatus    = 'N'
          %control-Salesorderid = if_abap_behv=>mk-on
          %control-Overallstatus = if_abap_behv=>mk-on ) )
    REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.


  METHOD recalcTotalPrice.
    TYPES: BEGIN OF ty_amount_per_currencycode,
             netamount     TYPE /dmo/total_price,
             grossamount   TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA: amount_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.
    " Read all relevant travel instances.
    READ ENTITIES OF z_i_soh IN LOCAL MODE
         ENTITY SalesOrder
            FIELDS ( Netamount Currencycode Grossamount )
            WITH CORRESPONDING #( keys )
         RESULT DATA(orders).




    LOOP AT orders ASSIGNING FIELD-SYMBOL(<order>).
      " Set the start for the calculation by adding the booking fee.
*      amount_per_currencycode = VALUE #( ( netamount        = <order>-Netamount
*                                           grossamount      = <order>-Grossamount
*                                           currency_code = <order>-CurrencyCode ) ).

      " Read all associated bookings and add them to the total price.
      READ ENTITIES OF z_i_soh IN LOCAL MODE
        ENTITY SalesOrder BY \_Item
          FIELDS ( NetAmount CurrencyCode Grossamount )
        WITH VALUE #( ( %tky = <order>-%tky ) )
        RESULT DATA(items).

      LOOP AT items ASSIGNING FIELD-SYMBOL(<fs_item>) WHERE Prodid IS NOT INITIAL.

        <fs_item>-Grossamount = <fs_item>-NetAmount * <fs_item>-Quantity.
        COLLECT VALUE ty_amount_per_currencycode( netamount        = <fs_item>-NetAmount
                                                  currency_code    = <fs_item>-CurrencyCode
                                                  grossamount      = <fs_item>-Grossamount ) INTO amount_per_currencycode.

*        APPEND VALUE #( %tky       = item-%tky
*                       Grossamount = item-Grossamount
*                      )  TO items.
      ENDLOOP.

      CLEAR: <order>-Netamount, <order>-Grossamount.
      LOOP AT amount_per_currencycode INTO DATA(single_amount_per_currencycode).
        " If needed do a Currency Conversion

        <order>-Netamount   += single_amount_per_currencycode-netamount.
        <order>-Grossamount += single_amount_per_currencycode-grossamount.
        <order>-Currencycode = single_amount_per_currencycode-currency_code.

      ENDLOOP.
    ENDLOOP.

    " write back the modified total_price of travels
    MODIFY ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY SalesOrder
        UPDATE FIELDS ( Netamount Grossamount Currencycode )
        WITH CORRESPONDING #( orders ).
    MODIFY ENTITIES OF z_i_soh IN LOCAL MODE
     ENTITY Item
       UPDATE FIELDS ( Netamount Grossamount Currencycode )
       WITH CORRESPONDING #( items ).

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.



  METHOD get_instance_features.
    " Read the travel status of the existing travels
    READ ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( Deliverystatus Billingstatus Overallstatus ) WITH CORRESPONDING #( keys )
      RESULT DATA(orders)
      FAILED failed.

    result =
      VALUE #(
        FOR order IN orders
          LET is_delivered =   COND #( WHEN order-Deliverystatus = 'D'
                                      THEN if_abap_behv=>fc-o-disabled
                                      ELSE if_abap_behv=>fc-o-enabled  )
              is_paid  =   COND #( WHEN order-Billingstatus = 'P'
                                      THEN if_abap_behv=>fc-o-disabled
                                      ELSE if_abap_behv=>fc-o-enabled )
              is_edit  = COND #( WHEN order-Overallstatus EQ 'C'
                                      THEN if_abap_behv=>fc-o-disabled
                                      ELSE if_abap_behv=>fc-o-enabled )
          IN
            ( %tky                 = order-%tky
              %action-SetDelivered = is_delivered
              %action-SetPaid      = is_paid
              %action-Edit         = is_edit
              %delete              = is_edit
             ) ).
  ENDMETHOD.

  METHOD ValidatePartner.

    " Read relevant travel instance data
    READ ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( Businesspartner ) WITH CORRESPONDING #( keys )
      RESULT DATA(orders).

    DATA partners TYPE SORTED TABLE OF SEPM_I_BusinessPartner WITH UNIQUE KEY BusinessPartner.

    " Optimization of DB select: extract distinct non-initial customer IDs
    partners = CORRESPONDING #( orders DISCARDING DUPLICATES MAPPING BusinessPartner = Businesspartner EXCEPT * ).
    DELETE partners WHERE BusinessPartner IS INITIAL.
    IF partners IS NOT INITIAL.
      " Check if customer ID exist
      SELECT FROM SEPM_I_BusinessPartner FIELDS BusinessPartner
        FOR ALL ENTRIES IN @partners
        WHERE BusinessPartner = @partners-BusinessPartner
        INTO TABLE @DATA(partners_db).
    ENDIF.
    " Raise msg for non existing and initial customerID
    LOOP AT orders INTO DATA(order).
      " Clear state messages that might exist
      APPEND VALUE #(  %tky        = order-%tky
                       %state_area = 'VALIDATE_PARTNER' )
        TO reported-salesorder.

      IF order-Businesspartner IS INITIAL OR NOT line_exists( partners_db[ BusinessPartner = order-Businesspartner ] ).
        APPEND VALUE #(  %tky = order-%tky ) TO failed-salesorder.

        APPEND VALUE #(  %tky        = order-%tky
                         %state_area = 'VALIDATE_PARTNER'
                         %msg        = NEW zcm_som(
                                           severity   = if_abap_behv_message=>severity-error
                                           textid     = zcm_som=>partner_unknown
                                           partner    = order-Businesspartner )
                         %element-Businesspartner = if_abap_behv=>mk-on )
          TO reported-salesorder.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD ValidDeliveryDate.
    DATA lv_timestamp TYPE timestampl.
    GET TIME STAMP FIELD lv_timestamp.


    " Read relevant travel instance data
    READ ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( Deliverydate ) WITH CORRESPONDING #( keys )
      RESULT DATA(orders).


    LOOP AT orders INTO DATA(order).
      " Clear state messages that might exist
      APPEND VALUE #(  %tky        = order-%tky
                       %state_area = 'VALIDATE_DATE' )
        TO reported-salesorder.

      IF order-Deliverydate < lv_timestamp.
        APPEND VALUE #(  %tky = order-%tky ) TO failed-salesorder.

        APPEND VALUE #(  %tky        = order-%tky
                         %state_area = 'VALIDATE_DATE'
                         %msg        = NEW zcm_som(
                                           severity     = if_abap_behv_message=>severity-error
                                           textid       = zcm_som=>delivery_date
                                           deliverydate = order-Deliverydate )
                         %element-Deliverydate = if_abap_behv=>mk-on )
          TO reported-salesorder.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD SetDelivered.

    " Fill the response table
    READ ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY SalesOrder
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(orders).

    LOOP AT orders ASSIGNING FIELD-SYMBOL(<fs_orders>).
      <fs_orders>-Deliverystatus = 'D'.
      IF <fs_orders>-Billingstatus EQ 'P'.
        <fs_orders>-Overallstatus = 'C'.
      ELSE.
        <fs_orders>-Overallstatus = 'P'.
      ENDIF.

      APPEND VALUE #(  %tky        = <fs_orders>-%tky
                       %state_area = 'SET_DELIVERED' )
        TO reported-salesorder.
      APPEND VALUE #(  %tky = <fs_orders>-%tky ) TO failed-salesorder.

      APPEND VALUE #(  %tky        = <fs_orders>-%tky
                       %state_area = 'SET_DELIVERED'
                       %msg        = NEW zcm_som(
                                         severity     = if_abap_behv_message=>severity-success
                                         textid       = zcm_som=>set_delivered
                                         salesorderid = <fs_orders>-Salesorderid )
                       %element-Deliverystatus = if_abap_behv=>mk-on )
        TO reported-salesorder.
    ENDLOOP.
    " Set the new overall status
    MODIFY ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY SalesOrder
         UPDATE
           FIELDS ( Deliverystatus Overallstatus )
           WITH CORRESPONDING #( orders )
      FAILED failed
      REPORTED reported.

    result = VALUE #( FOR order IN orders
                        ( %tky   = order-%tky
                          %param = order ) ).



  ENDMETHOD.

  METHOD SetPaid.
    " Fill the response table
    READ ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY SalesOrder
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(orders).

    LOOP AT orders ASSIGNING FIELD-SYMBOL(<fs_orders>).
      <fs_orders>-Billingstatus = 'P'.
      IF <fs_orders>-Deliverystatus EQ 'D'.
        <fs_orders>-Overallstatus = 'C'.
      ELSE.
        <fs_orders>-Overallstatus = 'P'.
      ENDIF.
      APPEND VALUE #(  %tky        = <fs_orders>-%tky
                       %state_area = 'SET_PAID' )
        TO reported-salesorder.
      APPEND VALUE #(  %tky = <fs_orders>-%tky ) TO failed-salesorder.

      APPEND VALUE #(  %tky        = <fs_orders>-%tky
                       %state_area = 'SET_PAID'
                       %msg        = NEW zcm_som(
                                         severity     = if_abap_behv_message=>severity-success
                                         textid       = zcm_som=>set_paid
                                         salesorderid = <fs_orders>-Salesorderid )
                       %element-Deliverystatus = if_abap_behv=>mk-on )
        TO reported-salesorder.
    ENDLOOP.
    " Set the new overall status
    MODIFY ENTITIES OF z_i_soh IN LOCAL MODE
      ENTITY SalesOrder
         UPDATE
           FIELDS ( Billingstatus Overallstatus )
           WITH CORRESPONDING #( orders )
      FAILED failed
      REPORTED reported.

    result = VALUE #( FOR order IN orders
                        ( %tky   = order-%tky
                          %param = order ) ).
  ENDMETHOD.

  METHOD createSoByTemplate.
    DATA : orders TYPE TABLE FOR CREATE z_i_soh,
           items  TYPE TABLE FOR CREATE z_i_soi.
    DATA(key_with_inital_cid) = keys[ %cid = '' ].
    ASSERT key_with_inital_cid IS INITIAL.

    READ ENTITIES OF z_i_soh IN LOCAL MODE
    ENTITY SalesOrder
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(orders_result)
    FAILED failed.

    READ ENTITIES OF z_i_soh IN LOCAL MODE
    ENTITY Item BY \_SalesOrder
    ALL FIELDS WITH CORRESPONDING #( orders_result )
    RESULT DATA(items_result)
    FAILED failed.


    LOOP AT orders_result ASSIGNING FIELD-SYMBOL(<orders>).
      "Fill travel container for creating new travel instance
      APPEND VALUE #( %cid     = keys[ KEY draft %tky = <orders>-%tky ]-%cid
                      %data    = CORRESPONDING #( <orders> EXCEPT Salesorderid ) )
        TO orders ASSIGNING FIELD-SYMBOL(<new_order>).
      "Fill %cid_ref of travel as instance identifier for cba booking
      APPEND VALUE #( %cid     = keys[ KEY draft %tky = <orders>-%tky ]-%cid )
        TO items ASSIGNING FIELD-SYMBOL(<items>).

       <orders>-Overallstatus = 'N'.
    ENDLOOP.


*    MODIFY ENTITIES OF z_i_soh IN LOCAL MODE
*    ENTITY SalesOrder
*    CREATE FIELDS (  )
  ENDMETHOD.

ENDCLASS.
