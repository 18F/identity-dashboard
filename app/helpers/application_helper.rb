module ApplicationHelper
  def classes(route, needed_classes='')
    current_page?(route) ? needed_classes + ' usa-current' : needed_classes
  end
end
