module PaginationHelper
  OVERFLOW = :overflow

  def pagination_visible_pages(current_page:, total_pages:)
    return [] if total_pages <= 1
    return (1..total_pages).to_a if total_pages <= 7

    visible = [1]

    if current_page <= 4
      visible += (2..5).to_a
      visible << OVERFLOW
      visible << total_pages
    elsif current_page >= total_pages - 3
      visible << OVERFLOW
      visible += ((total_pages - 4)..total_pages).to_a
    else
      visible << OVERFLOW
      visible << current_page - 1
      visible << current_page
      visible << current_page + 1
      visible << OVERFLOW
      visible << total_pages
    end

    visible
  end
end
