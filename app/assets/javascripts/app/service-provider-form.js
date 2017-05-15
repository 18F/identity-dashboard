$(function(){
  if(!$('.service-provider-form').length){
    return;
  }
  
  var toggle_form_fields = function(id_protocol){
    switch(id_protocol){
      case 'openid_connect':
        $('.saml-fields').hide();
        $('.oidc-fields').show();
        break;
      case 'saml':
        $('.saml-fields').show();
        $('.oidc-fields').hide();
        break;
      default:
        $('.saml-fields').show();
        $('.oidc-fields').show();
    }
  }

  var id_protocol = function(){
    return $('input[name="service_provider[identity_protocol]"]:checked').val();    
  }

  toggle_form_fields(id_protocol());
  
  $('input[name="service_provider[identity_protocol]"]').change(function(){
    toggle_form_fields(id_protocol());
  })
});