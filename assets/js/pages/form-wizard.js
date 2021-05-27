var Page = {
	createBasicWizard: function() {
		$('#basicwizard').bootstrapWizard({'tabClass': 'nav nav-tabs nav-justified'});
	},
	createProgressWizard: function(){
		$('#progresswizard').bootstrapWizard({onTabShow: function(tab, navigation, index) {
            var $total = navigation.find('li').length;
            var $current = index+1;
            var $percent = ($current/$total) * 100;
            $('#progresswizard').find('.progress').css({width:$percent+'%'});
        },
        'tabClass': 'nav nav-tabs nav-justified'});
	},
	createButtonWizard: function(){

  		$('#buttonwizard').bootstrapWizard({
  			'nextSelector': '.button-next',
  			'previousSelector': '.button-previous',
  			'firstSelector': '.button-first',
  			'lastSelector': '.button-last',
  			'tabClass': 'nav nav-tabs nav-justified'
  		});

	},
	init:function() {
		this.createBasicWizard();
		this.createProgressWizard();
		this.createButtonWizard();
	}
}