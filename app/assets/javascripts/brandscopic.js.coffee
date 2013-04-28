jQuery ->
	$('input.datepicker').datepicker()
	$('input.timepicker').timepicker()
	$('.chosen-enabled').chosen()
	$("input:checkbox, input:radio, input:file").not('[data-no-uniform="true"],#uniform-is-ajax').uniform()


	$.validator.addMethod("oneupperletter",  (value, element) ->
		return this.optional(element) || /[A-Z]/.test(value);
	, "Should have at least one upper case letter");

	$.validator.addMethod("onedigit", (value, element) ->
		return this.optional(element) || /[0-9]/.test(value);
	, "Should have at least one digit");

# ---------- Additional functions for data table ----------
$.fn.dataTableExt.oApi.fnPagingInfo = ( oSettings ) ->
	return {
		"iStart":         oSettings._iDisplayStart,
		"iEnd":           oSettings.fnDisplayEnd(),
		"iLength":        oSettings._iDisplayLength,
		"iTotal":         oSettings.fnRecordsTotal(),
		"iFilteredTotal": oSettings.fnRecordsDisplay(),
		"iPage":          Math.ceil( oSettings._iDisplayStart / oSettings._iDisplayLength ),
		"iTotalPages":    Math.ceil( oSettings.fnRecordsDisplay() / oSettings._iDisplayLength )
	}

$.extend $.fn.dataTableExt.oPagination, {
	"bootstrap": {
		"fnInit": ( oSettings, nPaging, fnDraw ) ->
			oLang = oSettings.oLanguage.oPaginate;
			fnClickHandler = ( e ) ->
				e.preventDefault();
				if oSettings.oApi._fnPageChange(oSettings, e.data.action)
					fnDraw oSettings

			$(nPaging).addClass('pagination').append(
				'<ul>'+
					'<li class="prev disabled"><a href="#">&larr; '+oLang.sPrevious+'</a></li>'+
					'<li class="next disabled"><a href="#">'+oLang.sNext+' &rarr; </a></li>'+
				'</ul>'
			);
			els = $('a', nPaging);
			$(els[0]).bind( 'click.DT', { action: "previous" }, fnClickHandler );
			$(els[1]).bind( 'click.DT', { action: "next" }, fnClickHandler );
		,

		"fnUpdate": ( oSettings, fnDraw ) ->
			iListLength = 5
			oPaging = oSettings.oInstance.fnPagingInfo()
			an = oSettings.aanFeatures.p
			#i, j, sClass, iStart, iEnd, iHalf=Math.floor(iListLength/2)
			iHalf=Math.floor(iListLength/2)

			if oPaging.iTotalPages < iListLength
				iStart = 1
				iEnd = oPaging.iTotalPages
			else if oPaging.iPage <= iHalf
				iStart = 1
				iEnd = iListLength
			else if oPaging.iPage >= (oPaging.iTotalPages-iHalf)
				iStart = oPaging.iTotalPages - iListLength + 1
				iEnd = oPaging.iTotalPages
			else
				iStart = oPaging.iPage - iHalf + 1
				iEnd = iStart + iListLength - 1

			#for ( i=0, iLen=an.length ; i<iLen ; i++ ) {
			for i in [0..an.length-1]
				# remove the middle elements
				$('li:gt(0)', an[i]).filter(':not(:last)').remove()

				# add the new list items and their event handlers
				#for ( j=iStart ; j<=iEnd ; j++ ) {
				for j in [iStart..iEnd]
					sClass = if j is (oPaging.iPage+1) then 'class="active"' else ''
					$('<li '+sClass+'><a href="#">'+j+'</a></li>')
						.insertBefore($('li:last', an[i])[0])
						.bind 'click', (e) ->
							e.preventDefault();
							oSettings._iDisplayStart = (parseInt($('a', this).text(),10)-1) * oPaging.iLength;
							fnDraw( oSettings );

				# add / remove disabled classes from the static elements
				if oPaging.iPage is 0
					$('li:first', an[i]).addClass 'disabled'
				else
					$('li:first', an[i]).removeClass 'disabled'

				if oPaging.iPage is oPaging.iTotalPages-1 or oPaging.iTotalPages is 0
					$('li:last', an[i]).addClass 'disabled'
				else
					$('li:last', an[i]).removeClass 'disabled'

	}
}

$.extend $.fn.dataTableExt.oStdClasses, {
    "sWrapper": "dataTables_wrapper form-inline"
}


$.fn.dataTableExt.oApi.fnReloadAjax = ( oSettings, sNewSource, fnCallback, bStandingRedraw ) ->
    if sNewSource isnt undefined && sNewSource isnt null
        oSettings.sAjaxSource = sNewSource;

    # Server-side processing should just call fnDraw
    if oSettings.oFeatures.bServerSide
        this.fnDraw()
        return

    this.oApi._fnProcessingDisplay oSettings, true
    that = this
    iStart = oSettings._iDisplayStart
    aData = []

    this.oApi._fnServerParams oSettings, aData

    oSettings.fnServerData.call( oSettings.oInstance, oSettings.sAjaxSource, aData, (json) ->
        # Clear the old information from the table
        that.oApi._fnClearTable oSettings

        # Got the data - add it to the table
        aData =  if oSettings.sAjaxDataProp isnt ""  then that.oApi._fnGetObjectDataFn( oSettings.sAjaxDataProp )( json ) else json

        for i in [0..aData.length-1]
            that.oApi._fnAddData oSettings, aData[i]

        oSettings.aiDisplay = oSettings.aiDisplayMaster.slice()

        that.fnDraw()

        if bStandingRedraw is true
            oSettings._iDisplayStart = iStart
            that.oApi._fnCalculateEnd oSettings
            that.fnDraw false

        that.oApi._fnProcessingDisplay oSettings, false

        # Callback user function - for event handlers etc
        if typeof fnCallback is 'function' && fnCallback isnt null
            fnCallback oSettings
    , oSettings )
