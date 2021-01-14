module SectionsHelper
  def section_link(section)
    link_to section.name, section_path(section)
  end
end
