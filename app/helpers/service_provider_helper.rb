module ServiceProviderHelper
  def sp_logo_path(file_name)
    file = file_name || 'generic.svg'
    'https://raw.githubusercontent.com/18F/identity-idp/master/app/assets/images/sp-logos/' +
      file
  end
end
