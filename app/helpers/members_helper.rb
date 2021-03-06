module MembersHelper
  def pretty_phone(number)
    link_to (number_to_phone number, :delimiter => "."), "tel:+1" + number
  end

  def table_order_link(text, order_key, order)
    if order.split(" ")[0] == order_key
      if order.include? "DESC"
        text += ' ' + image_tag('sort_up.gif', class: "order", alt: "&uarr;")
      else
        text += ' ' + image_tag('sort_down.gif', class: "order", alt: "&darr;")
      end
      return link_to(text.html_safe, { :order => order_key, :desc => (order.include?("DESC") ? "0" : "1") })
    else
      text += ' ' + image_tag('sort_none.gif', class: "order", alt: "&harr;")
      return link_to(text.html_safe, { :order => order_key, :desc => (order.include?("DESC") ? "1" : "0") })
    end
  end
end
