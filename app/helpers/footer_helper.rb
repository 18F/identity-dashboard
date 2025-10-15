# Helper for Footer partial view
module FooterHelper
  def rendered_layout
    return 'layouts/footer_signed_in' if user_signed_in?

    'layouts/footer_signed_out'
  end
end
