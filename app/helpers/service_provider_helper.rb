module ServiceProviderHelper
  def sp_logo_path(file_name)
    'https://raw.githubusercontent.com/18F/identity-idp/master/app/assets/images/sp-logos/' +
      file_name
  end
end
