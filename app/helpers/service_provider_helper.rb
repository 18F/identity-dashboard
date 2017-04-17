module ServiceProviderHelper
  def sp_logo(file_name)
    file = file_name || 'generic.svg'
    if file.end_with?('.svg')
      link_to(file, sp_logo_preview_path(file))
    else
      image_tag(sp_logo_path(file))
    end
  end

  def sp_logo_path(file_name)
    file = file_name || 'generic.svg'
    'https://raw.githubusercontent.com/18F/identity-idp/master/app/assets/images/sp-logos/' +
      file
  end

  def sp_logo_preview_path(file_name)
    file = file_name || 'generic.svg'
    'https://github.com/18F/identity-idp/blob/master/app/assets/images/sp-logos/' +
      file
  end
end
