module ApplicationHelper
  include Pagy::Frontend

  def nav_link(text, path, icon: nil)
    active = current_page?(path)
    css = active ? "bg-gray-50 text-blue-600" : "text-gray-700 hover:text-blue-600 hover:bg-gray-50"

    content_tag(:li) do
      link_to path, class: "group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold #{css}" do
        nav_icon(icon, active) + text
      end
    end
  end

  def nav_icon(name, active)
    color = active ? "text-blue-600" : "text-gray-400 group-hover:text-blue-600"

    icons = {
      "chart" => "M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z",
      "currency" => "M12 6v12m-3-2.818l.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
      "filter" => "M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917 1.096v1.044a2.25 2.25 0 01-.659 1.591l-5.432 5.432a2.25 2.25 0 00-.659 1.591v2.927a2.25 2.25 0 01-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 00-.659-1.591L3.659 7.409A2.25 2.25 0 013 5.818V4.774c0-.54.384-1.006.917-1.096A48.32 48.32 0 0112 3z",
      "building" => "M2.25 21h19.5M3.75 3v18m16.5-18v18M6.75 6h.008v.008H6.75V6zm0 3h.008v.008H6.75V9zm0 3h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm3-9h.008v.008H9.75V6zm0 3h.008v.008H9.75V9zm0 3h.008v.008H9.75V12zm0 3h.008v.008H9.75V15zm3-9h.008v.008h-.008V6zm0 3h.008v.008h-.008V9zm0 3h.008v.008h-.008V12zm3 0h.008v.008h-.008V12zm0 3h.008v.008h-.008V15zm0-6h.008v.008h-.008V9zm0-3h.008v.008h-.008V6z"
    }

    path_d = icons[name] || icons["chart"]
    content_tag(:svg, class: "h-5 w-5 shrink-0 #{color}", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor") do
      tag.path(d: path_d, stroke_linecap: "round", stroke_linejoin: "round")
    end
  end

  def currency(amount)
    number_to_currency(amount, unit: "€", format: "%n %u")
  end

  def percentage(value)
    "#{value}%"
  end
end
