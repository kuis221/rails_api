(function ($) {
 
	$.fn.watchChanges = function () {
		return this.each(function () {
			if (!$.data(this, 'formHash')){
				$(this).saveChanges();
			}
		});
	};

	$.fn.saveChanges = function () {
		return this.each(function () {
			$.data(this, 'formHash', $(this).serialize());
		});
	};
 
	$.fn.hasChanged = function () {
		var hasChanged = false;
 
		this.each(function () {
			var formHash = $.data(this, 'formHash');
 
			if (formHash != null && formHash !== $(this).serialize()) {
				hasChanged = true;
				return false;
			}
		});
 
		return hasChanged;
	};
 
}).call(this, jQuery);