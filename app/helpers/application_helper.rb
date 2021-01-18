module ApplicationHelper
  def nav_selected(path)
    if params[:controller] == path
      'active'
    else
      ''
    end
  end
end
